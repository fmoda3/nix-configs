import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { sumAssistantUsage } from "./format";
import { fetchRateLimitsForProvider, detectUsageProvider, RATE_LIMIT_REFRESH_MS } from "./provider-usage";
import { loadRepoState } from "./repo";
import { renderLeft, renderRight } from "./render";
import { createInitialState } from "./state";
import type { FooterState } from "./types";

export default function (pi: ExtensionAPI) {
  let state: FooterState = createInitialState(null);
  let requestRender: (() => void) | undefined;
  let rateLimitRefreshTimer: ReturnType<typeof setInterval> | undefined;
  let rateLimitRefreshInFlight = false;
  let lastContext: ExtensionContext | undefined;

  const rerender = () => requestRender?.();

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

  const installFooter = (ctx: ExtensionContext) => {
    if (rateLimitRefreshTimer) clearInterval(rateLimitRefreshTimer);

    ctx.ui.setFooter((tui, _theme, footerData) => {
      requestRender = () => tui.requestRender();

      const branchUnsubscribe = footerData.onBranchChange(() => tui.requestRender());
      const clockInterval = setInterval(() => tui.requestRender(), 1000);
      rateLimitRefreshTimer = setInterval(() => {
        if (lastContext) void refreshRateLimits(lastContext, false);
      }, RATE_LIMIT_REFRESH_MS);

      return {
        dispose() {
          branchUnsubscribe();
          clearInterval(clockInterval);
          if (rateLimitRefreshTimer) {
            clearInterval(rateLimitRefreshTimer);
            rateLimitRefreshTimer = undefined;
          }
          if (requestRender) requestRender = undefined;
        },
        invalidate() {},
        render(width: number): string[] {
          const left = renderLeft(state, ctx, footerData.getGitBranch(), pi.getThinkingLevel());
          const right = renderRight(footerData.getExtensionStatuses());
          const padWidth = right ? Math.max(1, width - visibleWidth(left) - visibleWidth(right)) : 0;
          const line = truncateToWidth(left + (right ? " ".repeat(padWidth) + right : ""), width);
          return [line];
        },
      };
    });
  };

  pi.on("session_start", async (_event, ctx) => {
    lastContext = ctx;
    state = createInitialState(ctx.model?.id ?? null);
    state = {
      ...state,
      totals: sumAssistantUsage(ctx),
    };

    installFooter(ctx);
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
    if (rateLimitRefreshTimer) {
      clearInterval(rateLimitRefreshTimer);
      rateLimitRefreshTimer = undefined;
    }
  });
}
