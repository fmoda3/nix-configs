import type { DashboardState } from "./types";

export function createInitialState(modelId: string | null): DashboardState {
  return {
    sessionStartMs: Date.now(),
    currentAgentStartMs: null,
    currentApiStartMs: null,
    totalAgentMs: 0,
    totalApiMs: 0,
    modelId,
    repo: { kind: "no-git" },
    rateLimits: { provider: null, windows: [], lastRefreshMs: null },
    totals: { input: 0, output: 0, cost: 0 },
  };
}
