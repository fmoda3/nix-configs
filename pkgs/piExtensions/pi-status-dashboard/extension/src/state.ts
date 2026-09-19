import type { DashboardState } from "./types";

export function createInitialState(modelId: string | null, modelName: string | null = null): DashboardState {
  return {
    sessionStartMs: Date.now(),
    currentAgentStartMs: null,
    totalAgentMs: 0,
    modelId,
    modelName,
    repo: { kind: "no-git" },
    rateLimits: { provider: null, windows: [], lastRefreshMs: null },
    totals: {
      input: 0,
      output: 0,
      cacheRead: 0,
      cacheWrite: 0,
      cost: 0,
      latestCacheHitRate: null,
    },
  };
}
