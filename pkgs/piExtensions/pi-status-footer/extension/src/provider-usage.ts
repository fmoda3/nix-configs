import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { formatReset } from "./format";
import type { RateLimitWindow, SupportedUsageProvider } from "./types";

export const RATE_LIMIT_REFRESH_MS = 60_000;
const FETCH_TIMEOUT_MS = 10_000;

type ModelLike = { provider?: string; id?: string } | null | undefined;

type CodexRateWindow = {
  reset_at?: number;
  limit_window_seconds?: number;
  used_percent?: number;
};

type CodexRateLimit = {
  primary_window?: CodexRateWindow;
  secondary_window?: CodexRateWindow;
};

type CodexAdditionalRateLimit = {
  limit_name?: string;
  metered_feature?: string;
  rate_limit?: CodexRateLimit;
};

export function detectUsageProvider(model: ModelLike): SupportedUsageProvider | null {
  const providerValue = model?.provider?.toLowerCase() ?? "";
  const idValue = model?.id?.toLowerCase() ?? "";

  const isAnthropic = providerValue.includes("anthropic") || idValue.includes("claude");
  if (isAnthropic) return "anthropic";

  const isCodex =
    providerValue.includes("openai-codex") ||
    providerValue.includes("codex") ||
    (providerValue.includes("openai") && idValue.includes("codex"));
  if (isCodex) return "codex";

  return null;
}

function createTimeoutSignal(timeoutMs: number): { signal: AbortSignal; clear: () => void } {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  return {
    signal: controller.signal,
    clear: () => clearTimeout(timeoutId),
  };
}

function safeReadJson(path: string): any | undefined {
  try {
    if (!existsSync(path)) return undefined;
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return undefined;
  }
}

function loadClaudeToken(): string | undefined {
  const envToken = process.env.ANTHROPIC_OAUTH_TOKEN?.trim();
  if (envToken) return envToken;

  const piAuth = safeReadJson(join(homedir(), ".pi", "agent", "auth.json"));
  if (typeof piAuth?.anthropic?.access === "string" && piAuth.anthropic.access.trim()) {
    return piAuth.anthropic.access.trim();
  }

  try {
    const keychainData = execFileSync("security", ["find-generic-password", "-s", "Claude Code-credentials", "-w"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    if (!keychainData) return undefined;
    const parsed = JSON.parse(keychainData);
    const scopes = parsed?.claudeAiOauth?.scopes ?? [];
    if (Array.isArray(scopes) && scopes.includes("user:profile") && typeof parsed?.claudeAiOauth?.accessToken === "string") {
      return parsed.claudeAiOauth.accessToken;
    }
  } catch {
    // ignore
  }

  return undefined;
}

function loadCodexCredentials(): { accessToken?: string; accountId?: string } {
  const envAccessToken = (
    process.env.OPENAI_CODEX_OAUTH_TOKEN ||
    process.env.OPENAI_CODEX_ACCESS_TOKEN ||
    process.env.CODEX_OAUTH_TOKEN ||
    process.env.CODEX_ACCESS_TOKEN
  )?.trim();
  const envAccountId = (process.env.OPENAI_CODEX_ACCOUNT_ID || process.env.CHATGPT_ACCOUNT_ID)?.trim();
  if (envAccessToken) return { accessToken: envAccessToken, accountId: envAccountId || undefined };

  const piAuth = safeReadJson(join(homedir(), ".pi", "agent", "auth.json"));
  if (typeof piAuth?.["openai-codex"]?.access === "string" && piAuth["openai-codex"].access.trim()) {
    return {
      accessToken: piAuth["openai-codex"].access.trim(),
      accountId: typeof piAuth["openai-codex"].accountId === "string" ? piAuth["openai-codex"].accountId : undefined,
    };
  }

  const codexAuth = safeReadJson(join(process.env.CODEX_HOME || join(homedir(), ".codex"), "auth.json"));
  if (typeof codexAuth?.OPENAI_API_KEY === "string" && codexAuth.OPENAI_API_KEY.trim()) {
    return { accessToken: codexAuth.OPENAI_API_KEY.trim() };
  }
  if (typeof codexAuth?.tokens?.access_token === "string" && codexAuth.tokens.access_token.trim()) {
    return {
      accessToken: codexAuth.tokens.access_token.trim(),
      accountId: typeof codexAuth?.tokens?.account_id === "string" ? codexAuth.tokens.account_id : undefined,
    };
  }

  return {};
}

async function fetchAnthropicRateLimits(): Promise<RateLimitWindow[]> {
  const token = loadClaudeToken();
  if (!token) return [];

  const { signal, clear } = createTimeoutSignal(FETCH_TIMEOUT_MS);
  try {
    const response = await fetch("https://api.anthropic.com/api/oauth/usage", {
      headers: {
        Authorization: `Bearer ${token}`,
        "anthropic-beta": "oauth-2025-04-20",
      },
      signal,
    });
    clear();
    if (!response.ok) return [];

    const data = (await response.json()) as {
      five_hour?: { utilization?: number; resets_at?: string };
      seven_day?: { utilization?: number; resets_at?: string };
    };

    const windows: RateLimitWindow[] = [];

    if (typeof data.five_hour?.utilization === "number") {
      const resetAt = data.five_hour.resets_at ? new Date(data.five_hour.resets_at) : undefined;
      windows.push({
        label: "5h",
        usedPercent: data.five_hour.utilization,
        resetDescription: resetAt ? formatReset(resetAt) : undefined,
      });
    }

    if (typeof data.seven_day?.utilization === "number") {
      const resetAt = data.seven_day.resets_at ? new Date(data.seven_day.resets_at) : undefined;
      windows.push({
        label: "7d",
        usedPercent: data.seven_day.utilization,
        resetDescription: resetAt ? formatReset(resetAt) : undefined,
      });
    }

    return windows;
  } catch {
    clear();
    return [];
  }
}

function getCodexWindowLabel(windowSeconds?: number, fallbackWindowSeconds?: number): string {
  const safeWindowSeconds =
    typeof windowSeconds === "number" && windowSeconds > 0
      ? windowSeconds
      : typeof fallbackWindowSeconds === "number" && fallbackWindowSeconds > 0
        ? fallbackWindowSeconds
        : 0;

  if (!safeWindowSeconds) return "0h";

  const windowHours = Math.round(safeWindowSeconds / 3600);
  if (windowHours >= 144) return "Week";
  if (windowHours >= 24) return "Day";
  return `${windowHours}h`;
}

function pushCodexWindow(windows: RateLimitWindow[], prefix: string | undefined, window: CodexRateWindow | undefined, fallbackWindowSeconds?: number): void {
  if (!window) return;
  const resetDate = typeof window.reset_at === "number" ? new Date(window.reset_at * 1000) : undefined;
  const label = getCodexWindowLabel(window.limit_window_seconds, fallbackWindowSeconds);
  windows.push({
    label: prefix ? `${prefix} ${label}` : label,
    usedPercent: window.used_percent || 0,
    resetDescription: resetDate ? formatReset(resetDate) : undefined,
  });
}

function addCodexRateWindows(windows: RateLimitWindow[], rateLimit: CodexRateLimit | undefined, prefix?: string): void {
  pushCodexWindow(windows, prefix, rateLimit?.primary_window, 10800);
  pushCodexWindow(windows, prefix, rateLimit?.secondary_window, 86400);
}

async function fetchCodexRateLimits(): Promise<RateLimitWindow[]> {
  const { accessToken, accountId } = loadCodexCredentials();
  if (!accessToken) return [];

  const { signal, clear } = createTimeoutSignal(FETCH_TIMEOUT_MS);
  try {
    const headers: Record<string, string> = {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    };
    if (accountId) headers["ChatGPT-Account-Id"] = accountId;

    const response = await fetch("https://chatgpt.com/backend-api/wham/usage", {
      headers,
      signal,
    });
    clear();
    if (!response.ok) return [];

    const data = (await response.json()) as {
      rate_limit?: CodexRateLimit;
      additional_rate_limits?: CodexAdditionalRateLimit[];
    };

    const windows: RateLimitWindow[] = [];
    addCodexRateWindows(windows, data.rate_limit);

    if (Array.isArray(data.additional_rate_limits)) {
      for (const entry of data.additional_rate_limits) {
        if (!entry || typeof entry !== "object") continue;
        const prefix =
          typeof entry.limit_name === "string" && entry.limit_name.trim().length > 0
            ? entry.limit_name.trim()
            : typeof entry.metered_feature === "string" && entry.metered_feature.trim().length > 0
              ? entry.metered_feature.trim()
              : "Additional";
        addCodexRateWindows(windows, entry.rate_limit, prefix);
      }
    }

    return windows;
  } catch {
    clear();
    return [];
  }
}

export async function fetchRateLimitsForProvider(provider: SupportedUsageProvider): Promise<RateLimitWindow[]> {
  switch (provider) {
    case "anthropic":
      return fetchAnthropicRateLimits();
    case "codex":
      return fetchCodexRateLimits();
  }
}
