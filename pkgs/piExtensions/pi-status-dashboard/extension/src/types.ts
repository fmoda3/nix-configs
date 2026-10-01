export type SupportedUsageProvider = "anthropic" | "codex";

export type DiffStats = {
  added: number;
  removed: number;
};

export type RateLimitWindow = {
  label: string;
  usedPercent: number;
  resetDescription?: string;
};

export type RateLimitState = {
  provider: SupportedUsageProvider | null;
  windows: RateLimitWindow[];
  lastRefreshMs: number | null;
};

export type RepoState =
  | {
      kind: "git";
      branch: string | null;
      worktreeName: string | null;
      diff: DiffStats | null;
    }
  | {
      kind: "no-git";
    };

export type RoutedModel = {
  provider: string;
  modelId: string;
  /** Display name, when the catalog knows the model. */
  modelName: string | null;
  thinkingLevel: string | null;
};

export type DashboardState = {
  sessionStartMs: number;
  currentAgentStartMs: number | null;
  totalAgentMs: number;
  modelId: string | null;
  modelName: string | null;
  /**
   * The physical model behind a virtual selection (e.g. `toast/auto-*`), from
   * the latest response on the branch. null when the selection is a physical
   * model, or before a virtual model has answered.
   */
  routed: RoutedModel | null;
  repo: RepoState;
  rateLimits: RateLimitState;
  totals: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
    cost: number;
    latestCacheHitRate: number | null;
  };
};

export type Panel = {
  title: string;
  topRight?: string;
  lines: string[];
};
