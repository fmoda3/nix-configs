import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { isVirtualSelection, latestResponseModel, mergeRoute, responseModel, sumSessionUsage } from "./format";
import { fetchRateLimitsForProvider, detectUsageProvider, RATE_LIMIT_REFRESH_MS } from "./provider-usage";
import { renderDashboard } from "./render";
import { loadRepoState } from "./repo";
import { createInitialState } from "./state";
import type { DashboardState, RoutedModel } from "./types";

const CLOCK_REFRESH_MS = 1000;

export default function (pi: ExtensionAPI) {
  let enabled = true;
  let state: DashboardState = createInitialState(null);
  let requestRender: (() => void) | undefined;
  let rateLimitRefreshTimer: ReturnType<typeof setInterval> | undefined;
  let clockRefreshTimer: ReturnType<typeof setInterval> | undefined;
  let rateLimitRefreshInFlight = false;
  let lastContext: ExtensionContext | undefined;

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

  const installDashboard = (ctx: ExtensionContext) => {
    if (!enabled) {
      ctx.ui.setFooter(undefined);
      requestRender = undefined;
      stopTimers();
      return;
    }

    ctx.ui.setFooter((tui, _theme, footerData) => {
      requestRender = () => tui.requestRender();

      // Prime Pi's internal branch cache so onBranchChange can compare future
      // filesystem updates against the current branch. The dashboard keeps its
      // richer repo state separately because it also displays worktree/diff info.
      footerData.getGitBranch();

      const unsubscribeBranchChange = footerData.onBranchChange(() => {
        lastContext = ctx;
        void refreshRepo(ctx).then(() => {
          tui.requestRender();
        });
      });

      return {
        dispose() {
          unsubscribeBranchChange();
          requestRender = undefined;
        },
        invalidate() {},
        render(width: number): string[] {
          const activeContext = lastContext ?? ctx;
          const extensionStatuses = Array.from(footerData.getExtensionStatuses().values()).filter(
            (status) => status && status.trim().length > 0,
          );
          return renderDashboard(state, activeContext, pi.getThinkingLevel(), extensionStatuses, width);
        },
      };
    });

    stopTimers();
    clockRefreshTimer = setInterval(() => rerender(), CLOCK_REFRESH_MS);
    rateLimitRefreshTimer = setInterval(() => {
      if (lastContext) void refreshRateLimits(lastContext, false);
    }, RATE_LIMIT_REFRESH_MS);
  };

  const refreshUsage = (ctx: ExtensionContext) => {
    state = {
      ...state,
      totals: sumSessionUsage(ctx),
      routed: routedModel(ctx, ctx.model),
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
    description: "Toggle the status dashboard footer (usage: /status-dashboard [on|off])",
    handler: async (args, ctx) => {
      const normalized = args.trim().toLowerCase();
      if (normalized === "on") enabled = true;
      else if (normalized === "off") enabled = false;
      else enabled = !enabled;

      installDashboard(ctx);
      if (enabled) {
        await refreshRepo(ctx);
      }
      rerender();
      ctx.ui.notify(`status dashboard ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    lastContext = ctx;
    state = createInitialState(ctx.model?.id ?? null, ctx.model?.name ?? null);
    refreshUsage(ctx);

    installDashboard(ctx);
    await refreshRepo(ctx);
    await refreshRateLimits(ctx, true);
    rerender();
  });

  pi.on("model_select", async (event, ctx) => {
    lastContext = ctx;
    state = {
      ...state,
      modelId: event.model.id,
      modelName: event.model.name ?? null,
      routed: routedModel(ctx, event.model),
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
    // By now every message of the run is saved, so this picks up the final
    // response, which `message_end` (fired before saving) cannot see.
    refreshUsage(ctx);
    rerender();
  });

  // A virtual selection's routed model is shown as soon as the routed response
  // starts streaming, taken from the message itself: the session does not
  // contain it yet, so reading the branch here would show the previous route.
  pi.on("message_start", async (event, ctx) => {
    lastContext = ctx;
    const routed = routedFromMessage(ctx, event.message);
    if (!routed) return;
    state = { ...state, routed: mergeRoute(state.routed, routed) };
    rerender();
  });

  pi.on("message_end", async (event, ctx) => {
    lastContext = ctx;
    refreshUsage(ctx);
    // pi emits message_end before saving the message, so the branch read above
    // is one response behind; the message on the event is the current one.
    const routed = routedFromMessage(ctx, event.message);
    if (routed) state = { ...state, routed: mergeRoute(state.routed, routed) };
    rerender();
  });

  pi.on("session_compact", async (_event, ctx) => {
    lastContext = ctx;
    refreshUsage(ctx);
    rerender();
  });

  pi.on("session_tree", async (_event, ctx) => {
    lastContext = ctx;
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
    ctx.ui.setFooter(undefined);
  });
}

/**
 * What a virtual selection was last routed to on this branch, or null for a
 * physical selection. Best-effort: an unreadable session just shows the
 * selection alone.
 */
function routedModel(ctx: ExtensionContext, selection: { api?: unknown } | undefined): RoutedModel | null {
  if (!isVirtualSelection(selection)) return null;
  try {
    return withName(ctx, latestResponseModel(ctx.sessionManager.getBranch()));
  } catch {
    return null;
  }
}

/** The routed model named by one assistant message, when the selection is virtual. */
function routedFromMessage(ctx: ExtensionContext, message: unknown): RoutedModel | null {
  if (!isVirtualSelection(ctx.model)) return null;
  return withName(ctx, responseModel(message));
}

function withName(
  ctx: ExtensionContext,
  latest: { provider: string; modelId: string; thinkingLevel: string | null } | null,
): RoutedModel | null {
  if (!latest) return null;
  const name = ctx.modelRegistry.find(latest.provider, latest.modelId)?.name;
  return { ...latest, modelName: name && name.trim() !== "" ? name : null };
}
