import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { sumAssistantUsage } from "./format";
import { fetchRateLimitsForProvider, detectUsageProvider, RATE_LIMIT_REFRESH_MS } from "./provider-usage";
import { renderDashboard } from "./render";
import { loadRepoState } from "./repo";
import { createInitialState } from "./state";
import type { DashboardState } from "./types";

const WIDGET_ID = "pi-status-dashboard";
const CLOCK_REFRESH_MS = 1000;

export default function (pi: ExtensionAPI) {
  let enabled = true;
  let state: DashboardState = createInitialState(null);
  let requestRender: (() => void) | undefined;
  let rateLimitRefreshTimer: ReturnType<typeof setInterval> | undefined;
  let clockRefreshTimer: ReturnType<typeof setInterval> | undefined;
  let rateLimitRefreshInFlight = false;
  let lastContext: ExtensionContext | undefined;
  let getExtensionStatuses: (() => ReadonlyMap<string, string>) | undefined;

  const rerender = () => requestRender?.();

  const stopTimers = () => {
    if (clockRefreshTimer) {
      clearInterval(clockRefreshTimer);
      clockRefreshTimer = undefined;
    }
    if (rateLimitRefreshTimer) {
      clearInterval(rateLimitRefreshTimer);
      rateLimitRefreshTimer = undefined;
    }
  };

  const installWidget = (ctx: ExtensionContext) => {
    if (!enabled) {
      ctx.ui.setWidget(WIDGET_ID, undefined);
      ctx.ui.setFooter(undefined);
      requestRender = undefined;
      stopTimers();
      return;
    }

    ctx.ui.setFooter((_tui, _theme, footerData) => {
      getExtensionStatuses = () => footerData.getExtensionStatuses();
      return {
        dispose() {
          getExtensionStatuses = undefined;
        },
        invalidate() {},
        render(): string[] {
          return [];
        },
      };
    });

    ctx.ui.setWidget(
      WIDGET_ID,
      (tui) => {
        requestRender = () => tui.requestRender();
        return {
          invalidate() {},
          render(width: number): string[] {
            const activeContext = lastContext ?? ctx;
            const extensionStatuses = Array.from(getExtensionStatuses?.().values() ?? []).filter(
              (status) => status && status.trim().length > 0,
            );
            return renderDashboard(state, activeContext, pi.getThinkingLevel(), extensionStatuses, width);
          },
        };
      },
      { placement: "belowEditor" },
    );

    stopTimers();
    clockRefreshTimer = setInterval(() => rerender(), CLOCK_REFRESH_MS);
    rateLimitRefreshTimer = setInterval(() => {
      if (lastContext) void refreshRateLimits(lastContext, false);
    }, RATE_LIMIT_REFRESH_MS);
  };

  const refreshUsage = (ctx: ExtensionContext) => {
    state = {
      ...state,
      totals: sumAssistantUsage(ctx),
    };
  };

  const refreshRepo = async (ctx: ExtensionContext) => {
    state = {
      ...state,
      repo: await loadRepoState(pi, ctx.cwd),
    };
  };

  const refreshRateLimits = async (ctx: ExtensionContext, force = false) => {
    const provider = detectUsageProvider(ctx.model);

    if (!provider) {
      state = {
        ...state,
        rateLimits: { provider: null, windows: [], lastRefreshMs: null },
      };
      rerender();
      return;
    }

    if (
      !force &&
      state.rateLimits.provider === provider &&
      state.rateLimits.lastRefreshMs &&
      Date.now() - state.rateLimits.lastRefreshMs < RATE_LIMIT_REFRESH_MS
    ) {
      return;
    }

    if (rateLimitRefreshInFlight) return;
    rateLimitRefreshInFlight = true;

    try {
      const windows = await fetchRateLimitsForProvider(provider);
      state = {
        ...state,
        rateLimits: {
          provider,
          windows,
          lastRefreshMs: Date.now(),
        },
      };
      rerender();
    } finally {
      rateLimitRefreshInFlight = false;
    }
  };

  pi.registerCommand("status-dashboard", {
    description: "Toggle the status dashboard widget (usage: /status-dashboard [on|off])",
    handler: async (args, ctx) => {
      const normalized = args.trim().toLowerCase();
      if (normalized === "on") enabled = true;
      else if (normalized === "off") enabled = false;
      else enabled = !enabled;

      installWidget(ctx);
      rerender();
      ctx.ui.notify(`status dashboard ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    lastContext = ctx;
    state = createInitialState(ctx.model?.id ?? null);
    refreshUsage(ctx);

    installWidget(ctx);
    await refreshRepo(ctx);
    await refreshRateLimits(ctx, true);
    rerender();
  });

  pi.on("model_select", async (event, ctx) => {
    lastContext = ctx;
    state = {
      ...state,
      modelId: event.model.id,
    };
    await refreshRateLimits(ctx, true);
    rerender();
  });

  pi.on("agent_start", async (_event, ctx) => {
    lastContext = ctx;
    state = {
      ...state,
      currentAgentStartMs: Date.now(),
    };
    rerender();
  });

  pi.on("agent_end", async (_event, ctx) => {
    lastContext = ctx;
    const elapsed = state.currentAgentStartMs ? Date.now() - state.currentAgentStartMs : 0;
    state = {
      ...state,
      currentAgentStartMs: null,
      totalAgentMs: state.totalAgentMs + elapsed,
    };
    rerender();
  });

  pi.on("before_provider_request", async (_event, ctx) => {
    lastContext = ctx;
    state = {
      ...state,
      currentApiStartMs: Date.now(),
    };
    rerender();
  });

  pi.on("after_provider_response", async (_event, ctx) => {
    lastContext = ctx;
    const elapsed = state.currentApiStartMs ? Date.now() - state.currentApiStartMs : 0;
    state = {
      ...state,
      currentApiStartMs: null,
      totalApiMs: state.totalApiMs + elapsed,
    };
    rerender();
  });

  pi.on("message_end", async (event, ctx) => {
    lastContext = ctx;
    if (event.message.role !== "assistant") return;
    refreshUsage(ctx);
    rerender();
  });

  pi.on("tool_execution_end", async (event, ctx) => {
    lastContext = ctx;
    if (!["edit", "write"].includes(event.toolName)) return;
    await refreshRepo(ctx);
    rerender();
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    stopTimers();
    requestRender = undefined;
    ctx.ui.setWidget(WIDGET_ID, undefined);
  });
}
