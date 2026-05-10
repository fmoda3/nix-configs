import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { formatCost, formatCount, formatDuration, getAccumulatedAgentMs, getAccumulatedApiMs } from "./format";
import { CATPPUCCIN, fg } from "./theme";
import type { FooterState, RateLimitState } from "./types";

function renderRateLimitSegment(rateLimits: RateLimitState): string | null {
  if (!rateLimits.provider || rateLimits.windows.length === 0) return null;

  const palette = [CATPPUCCIN.maroon, CATPPUCCIN.mauve, CATPPUCCIN.pink];
  const segments = rateLimits.windows.slice(0, 3).map((window, index) => {
    const color = palette[index] ?? CATPPUCCIN.maroon;
    const percent = `${Math.round(window.usedPercent)}%`;
    const reset = window.resetDescription ? ` ${window.resetDescription}` : "";
    return fg(color, ` ${window.label} ${percent}${reset}`);
  });

  return segments.join(fg(CATPPUCCIN.text, " | "));
}

export function renderLeft(
  state: FooterState,
  ctx: ExtensionContext,
  branchOverride: string | null,
  thinkingLevel: string | null,
): string {
  const parts: string[] = [];

  if (state.modelId) {
    parts.push(fg(CATPPUCCIN.blue, `󱜙 ${state.modelId}`));
  }

  if (thinkingLevel) {
    parts.push(fg(CATPPUCCIN.sky, `󰔛 ${thinkingLevel}`));
  }

  parts.push(fg(CATPPUCCIN.green, ` ${formatCost(state.totals.cost)}`));
  parts.push(
    `${fg(CATPPUCCIN.yellow, `󱩷 ${formatDuration(Date.now() - state.sessionStartMs)} 󰭖 ${formatDuration(getAccumulatedAgentMs(state))} 󱉊 ${formatDuration(getAccumulatedApiMs(state))}`)}`,
  );

  const usage = ctx.getContextUsage();
  const contextWindow = ctx.model?.contextWindow ?? 0;
  if (usage && contextWindow > 0) {
    const percent = Math.round((usage.tokens / contextWindow) * 100);
    parts.push(fg(CATPPUCCIN.peach, ` ${formatCount(usage.tokens)}/${formatCount(contextWindow)} (${percent}%)`));
  }

  const rateLimitSegment = renderRateLimitSegment(state.rateLimits);
  if (rateLimitSegment) {
    parts.push(rateLimitSegment);
  }

  if (state.repo.kind === "git") {
    const branch = branchOverride ?? state.repo.branch;
    if (branch) {
      parts.push(fg(CATPPUCCIN.flamingo, `󰘬 ${branch}`));
    }

    if (state.repo.worktreeName) {
      parts.push(fg(CATPPUCCIN.flamingo, `󱓊 ${state.repo.worktreeName}`));
    }

    if (state.repo.diff) {
      parts.push(`(${fg(CATPPUCCIN.green, ` ${state.repo.diff.added}`)} ${fg(CATPPUCCIN.red, ` ${state.repo.diff.removed}`)})`);
    }
  }

  return parts.join(fg(CATPPUCCIN.text, " | "));
}

export function renderRight(extensionStatuses: ReadonlyMap<string, string>): string {
  const statuses = Array.from(extensionStatuses.values()).filter((value) => value && value.trim().length > 0);
  if (statuses.length === 0) return "";
  return statuses.join(fg(CATPPUCCIN.text, " | "));
}
