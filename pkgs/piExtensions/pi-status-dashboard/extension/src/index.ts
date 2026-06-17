import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { watch, type FSWatcher } from "node:fs";
import { dirname, join } from "node:path";
import { sumAssistantUsage } from "./format";
import { fetchRateLimitsForProvider, detectUsageProvider, RATE_LIMIT_REFRESH_MS } from "./provider-usage";
import { renderDashboard } from "./render";
import { loadRepoState } from "./repo";
import { createInitialState } from "./state";
import type { DashboardState } from "./types";

const WIDGET_ID = "pi-status-dashboard";
const CLOCK_REFRESH_MS = 1000;
const GIT_REFRESH_DEBOUNCE_MS = 150;

export default function (pi: ExtensionAPI) {
  let enabled = true;
  let state: DashboardState = createInitialState(null);
  let requestRender: (() => void) | undefined;
  let rateLimitRefreshTimer: ReturnType<typeof setInterval> | undefined;
  let clockRefreshTimer: ReturnType<typeof setInterval> | undefined;
  let gitRefreshTimer: ReturnType<typeof setTimeout> | undefined;
  let gitWatchers: FSWatcher[] = [];
  let rateLimitRefreshInFlight = false;
  let lastContext: ExtensionContext | undefined;
  let getExtensionStatuses: (() => ReadonlyMap<string, string>) | undefined;

  const rerender = () => requestRender?.();

  const stopGitWatchers = () => {
    for (const watcher of gitWatchers) watcher.close();
    gitWatchers = [];

    if (gitRefreshTimer) {
      clearTimeout(gitRefreshTimer);
      gitRefreshTimer = undefined;
    }
  };

  const stopTimers = () => {
    if (clockRefreshTimer) {
      clearInterval(clockRefreshTimer);
      clockRefreshTimer = undefined;
    }
    if (rateLimitRefreshTimer) {
      clearInterval(rateLimitRefreshTimer);
      rateLimitRefreshTimer = undefined;
    }
    stopGitWatchers();
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

  const scheduleGitRefresh = (ctx: ExtensionContext) => {
    if (gitRefreshTimer) clearTimeout(gitRefreshTimer);

    gitRefreshTimer = setTimeout(async () => {
      lastContext = ctx;
      await refreshRepo(ctx);
      await startGitWatchers(ctx);
      rerender();
    }, GIT_REFRESH_DEBOUNCE_MS);
  };

  const watchGitPath = (path: string, ctx: ExtensionContext, recursive = false) => {
    try {
      const watcher = watch(path, { recursive }, () => scheduleGitRefresh(ctx));
      watcher.on("error", () => {
        gitWatchers = gitWatchers.filter((candidate) => candidate !== watcher);
        watcher.close();
      });
      gitWatchers.push(watcher);
    } catch {
      // Git metadata paths vary across normal repos, worktrees, and packed refs.
      // Missing or unsupported watch targets should not break the dashboard.
    }
  };

  const loadAbsoluteGitPath = async (ctx: ExtensionContext, key: "--absolute-git-dir" | "--git-common-dir") => {
    const result = await pi.exec("git", ["rev-parse", "--path-format=absolute", key], {
      cwd: ctx.cwd,
      timeout: 5000,
    });
    if (result.code !== 0) return null;

    const path = result.stdout.trim();
    return path.length > 0 ? path : null;
  };

  const startGitWatchers = async (ctx: ExtensionContext) => {
    stopGitWatchers();

    const gitDir = await loadAbsoluteGitPath(ctx, "--absolute-git-dir");
    if (!gitDir) return;

    const commonDir = (await loadAbsoluteGitPath(ctx, "--git-common-dir")) ?? gitDir;

    // Watch directories as well as individual files. Git often rewrites files
    // like HEAD via atomic rename, which can invalidate file-level watchers
    // after the first branch switch on some platforms.
    watchGitPath(gitDir, ctx);
    if (commonDir !== gitDir) watchGitPath(commonDir, ctx);
    watchGitPath(join(gitDir, "HEAD"), ctx);
    watchGitPath(join(gitDir, "index"), ctx);
    watchGitPath(join(gitDir, "packed-refs"), ctx);
    watchGitPath(join(gitDir, "logs"), ctx);
    watchGitPath(join(gitDir, "logs", "HEAD"), ctx);
    watchGitPath(join(commonDir, "packed-refs"), ctx);
    watchGitPath(join(commonDir, "refs"), ctx, true);
    watchGitPath(join(commonDir, "refs", "heads"), ctx, true);

    const branchResult = await pi.exec("git", ["symbolic-ref", "--quiet", "--short", "HEAD"], {
      cwd: ctx.cwd,
      timeout: 5000,
    });
    const branch = branchResult.code === 0 ? branchResult.stdout.trim() : "";
    if (branch) {
      const branchRef = join(commonDir, "refs", "heads", ...branch.split("/"));
      watchGitPath(branchRef, ctx);
      watchGitPath(dirname(branchRef), ctx);
    }
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
      if (enabled) {
        await refreshRepo(ctx);
        await startGitWatchers(ctx);
      }
      rerender();
      ctx.ui.notify(`status dashboard ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    lastContext = ctx;
    state = createInitialState(ctx.model?.id ?? null, ctx.model?.name ?? null);
    refreshUsage(ctx);

    installWidget(ctx);
    await refreshRepo(ctx);
    await startGitWatchers(ctx);
    await refreshRateLimits(ctx, true);
    rerender();
  });

  pi.on("model_select", async (event, ctx) => {
    lastContext = ctx;
    state = {
      ...state,
      modelId: event.model.id,
      modelName: event.model.name ?? null,
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
