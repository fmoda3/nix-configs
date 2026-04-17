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

export type FooterState = {
  sessionStartMs: number;
  currentAgentStartMs: number | null;
  currentApiStartMs: number | null;
  totalAgentMs: number;
  totalApiMs: number;
  modelId: string | null;
  repo: RepoState;
  rateLimits: RateLimitState;
  totals: {
    input: number;
    output: number;
    cost: number;
  };
};
