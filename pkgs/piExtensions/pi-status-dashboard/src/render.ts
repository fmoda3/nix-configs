import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { formatCost, formatCount, formatDuration, getAccumulatedApiMs } from "./format";
import { CATPPUCCIN, fg } from "./theme";
import type { DashboardState, Panel } from "./types";

const PANEL_GAP = 1;
const MIN_PANEL_INNER_WIDTH = 14;
const PANEL_PADDING = 1;

function plain(text: string): string {
  return fg(CATPPUCCIN.text, text);
}

function label(text: string): string {
  return fg(CATPPUCCIN.subtext0, text);
}

function value(color: string, text: string): string {
  return fg(color, text);
}

function formatPanelRows(rows: Array<{ key: string; value: string }>): string[] {
  const keyWidth = rows.reduce((max, row) => Math.max(max, visibleWidth(row.key)), 0);
  return rows.map(({ key, value }) => {
    const padding = " ".repeat(Math.max(0, keyWidth - visibleWidth(key)));
    return `${label(key)}${padding} ${border("│")} ${value}`;
  });
}

function makeBar(percent: number): string {
  const normalized = Math.max(0, Math.min(100, percent));
  const filled = Math.round(normalized / 20);
  return `${"█".repeat(filled)}${"░".repeat(5 - filled)}`;
}

function usageColor(percent: number): string {
  if (percent >= 90) return CATPPUCCIN.red;
  if (percent >= 75) return CATPPUCCIN.peach;
  if (percent >= 50) return CATPPUCCIN.yellow;
  return CATPPUCCIN.green;
}

function buildModelPanel(state: DashboardState, thinkingLevel: string | null): Panel {
  return {
    title: "MODEL",
    lines: formatPanelRows([
      { key: "model", value: value(CATPPUCCIN.blue, state.modelId ?? "n/a") },
      { key: "thinking", value: value(CATPPUCCIN.sky, thinkingLevel ?? "default") },
    ]),
  };
}

function buildUsagePanel(state: DashboardState, ctx: ExtensionContext): Panel {
  const tokenSummary = `${value(CATPPUCCIN.lavender, `↑${formatCount(state.totals.input)}`)} ${value(CATPPUCCIN.lavender, `↓${formatCount(state.totals.output)}`)}`;
  const rows: Array<{ key: string; value: string }> = [
    { key: "cost", value: value(CATPPUCCIN.green, formatCost(state.totals.cost)) },
  ];

  const usage = ctx.getContextUsage();
  const contextWindow = ctx.model?.contextWindow ?? 0;
  if (usage && contextWindow > 0) {
    const percent = Math.round((usage.tokens / contextWindow) * 100);
    rows.push({
      key: "context",
      value: `${value(usageColor(percent), `${percent}%`)} ${value(usageColor(percent), makeBar(percent))} ${plain(`${formatCount(usage.tokens)}/${formatCount(contextWindow)}`)}`,
    });
  } else {
    rows.push({ key: "context", value: plain("n/a") });
  }

  return { title: "USAGE", topRight: tokenSummary, lines: formatPanelRows(rows) };
}

function buildRuntimePanel(state: DashboardState): Panel {
  return {
    title: "RUNTIME",
    lines: formatPanelRows([
      { key: "session", value: value(CATPPUCCIN.yellow, formatDuration(Date.now() - state.sessionStartMs)) },
      { key: "api", value: value(CATPPUCCIN.yellow, formatDuration(getAccumulatedApiMs(state))) },
    ]),
  };
}

function buildRateLimitPanel(state: DashboardState): Panel | null {
  if (!state.rateLimits.provider) {
    return null;
  }

  const rows: Array<{ key: string; value: string }> = [];
  if (state.rateLimits.windows.length === 0) {
    rows.push({ key: "windows", value: plain("no data") });
  } else {
    for (const window of state.rateLimits.windows.slice(0, 4)) {
      const percent = Math.round(window.usedPercent);
      const reset = window.resetDescription ? ` • ${window.resetDescription}` : "";
      rows.push({
        key: window.label,
        value: `${value(usageColor(percent), `${percent}%`)} ${value(usageColor(percent), makeBar(percent))}${plain(reset)}`,
      });
    }
  }

  return {
    title: "RATE LIMITS",
    topRight: value(CATPPUCCIN.mauve, state.rateLimits.provider),
    lines: formatPanelRows(rows),
  };
}

function buildExtensionStatusPanel(extensionStatuses: readonly string[]): Panel | null {
  const statuses = extensionStatuses.map((status) => status.trim()).filter((status) => status.length > 0);
  if (statuses.length === 0) return null;

  return {
    title: "EXTENSIONS",
    lines: statuses.map((status) => plain(status)),
  };
}

function buildGitPanel(state: DashboardState): Panel {
  if (state.repo.kind !== "git") {
    return {
      title: "GIT",
      lines: formatPanelRows([{ key: "repo", value: plain("not a git worktree") }]),
    };
  }

  const diffSummary = state.repo.diff
    ? `${value(CATPPUCCIN.green, `+${state.repo.diff.added}`)} ${value(CATPPUCCIN.red, `-${state.repo.diff.removed}`)}`
    : undefined;

  const rows: Array<{ key: string; value: string }> = [
    { key: "branch", value: value(CATPPUCCIN.flamingo, state.repo.branch ?? "detached") },
    { key: "worktree", value: value(CATPPUCCIN.flamingo, state.repo.worktreeName ?? "N/A") },
  ];

  return { title: "GIT", topRight: diffSummary, lines: formatPanelRows(rows) };
}

function getDesiredPanelWidth(panel: Panel, maxWidth: number): number {
  const widestLine = panel.lines.reduce((max, line) => Math.max(max, visibleWidth(line)), 0);
  const titleWidth = visibleWidth(` ${panel.title} `);
  const topRightWidth = panel.topRight ? visibleWidth(` ${panel.topRight} `) : 0;
  const headerWidth = panel.topRight ? titleWidth + topRightWidth + 1 : titleWidth;
  const innerWidth = Math.max(MIN_PANEL_INNER_WIDTH, widestLine + PANEL_PADDING * 2, headerWidth);
  return Math.min(maxWidth, innerWidth + 2);
}

function border(text: string): string {
  return fg(CATPPUCCIN.subtext0, text);
}

function buildTopBorder(panel: Panel, innerWidth: number): string {
  const leftTitle = value(CATPPUCCIN.sapphire, ` ${panel.title} `);
  if (!panel.topRight) {
    const fill = Math.max(0, innerWidth - visibleWidth(` ${panel.title} `));
    return `${border("╭")}${leftTitle}${border("─".repeat(fill))}${border("╮")}`;
  }

  const rightTitle = `${plain(" ")}${panel.topRight}${plain(" ")}`;
  const fill = Math.max(1, innerWidth - visibleWidth(` ${panel.title} `) - visibleWidth(rightTitle));
  return `${border("╭")}${leftTitle}${border("─".repeat(fill))}${rightTitle}${border("╮")}`;
}

function drawPanel(panel: Panel, targetWidth: number): string[] {
  const innerWidth = Math.max(MIN_PANEL_INNER_WIDTH, targetWidth - 2);
  const top = buildTopBorder(panel, innerWidth);
  const bottom = `${border("╰")}${border("─".repeat(innerWidth))}${border("╯")}`;

  const body = panel.lines.map((line) => {
    const truncated = truncateToWidth(line, innerWidth - PANEL_PADDING * 2);
    const content = `${" ".repeat(PANEL_PADDING)}${truncated}${" ".repeat(Math.max(0, innerWidth - PANEL_PADDING * 2 - visibleWidth(truncated)))}${" ".repeat(PANEL_PADDING)}`;
    return `${border("│")}${content}${border("│")}`;
  });

  return [top, ...body, bottom];
}

function padPanelLine(line: string, width: number): string {
  const extra = Math.max(0, width - visibleWidth(line));
  return line + " ".repeat(extra);
}

function maxLineWidth(lines: string[]): number {
  return lines.reduce((max, line) => Math.max(max, visibleWidth(line)), 0);
}

function stackPanels(width: number, renderedPanels: string[][]): string[] {
  const lines: string[] = [];
  for (const panelLines of renderedPanels) {
    if (lines.length > 0) lines.push("");
    for (const line of panelLines) {
      lines.push(truncateToWidth(line, width));
    }
  }
  return lines;
}

function combineRow(renderedPanels: string[][]): string[] {
  const widths = renderedPanels.map((lines) => maxLineWidth(lines));
  const height = Math.max(...renderedPanels.map((lines) => lines.length));
  const rowLines: string[] = [];

  for (let index = 0; index < height; index += 1) {
    const parts = renderedPanels.map((lines, panelIndex) => {
      const panelWidth = widths[panelIndex] ?? 0;
      const line = lines[index] ?? " ".repeat(panelWidth);
      return padPanelLine(line, panelWidth);
    });
    rowLines.push(parts.join(" ".repeat(PANEL_GAP)).replace(/\s+$/u, ""));
  }

  return rowLines;
}

function packRows(width: number, renderedPanels: string[][]): string[] {
  const rows: string[] = [];
  let currentRow: string[][] = [];
  let currentWidth = 0;

  for (const panelLines of renderedPanels) {
    const panelWidth = maxLineWidth(panelLines);
    const nextWidth = currentRow.length === 0 ? panelWidth : currentWidth + PANEL_GAP + panelWidth;

    if (currentRow.length > 0 && nextWidth > width) {
      rows.push(...combineRow(currentRow));
      currentRow = [panelLines];
      currentWidth = panelWidth;
      continue;
    }

    currentRow.push(panelLines);
    currentWidth = nextWidth;
  }

  if (currentRow.length > 0) {
    rows.push(...combineRow(currentRow));
  }

  return rows;
}

export function renderDashboard(
  state: DashboardState,
  ctx: ExtensionContext,
  thinkingLevel: string | null,
  extensionStatuses: readonly string[],
  width: number,
): string[] {
  const panels = [
    buildModelPanel(state, thinkingLevel),
    buildUsagePanel(state, ctx),
    buildRuntimePanel(state),
    buildRateLimitPanel(state),
    buildGitPanel(state),
    buildExtensionStatusPanel(extensionStatuses),
  ].filter((panel): panel is Panel => panel !== null);

  const maxPanelWidth = Math.max(MIN_PANEL_INNER_WIDTH + 2, width);
  const renderedPanels = panels.map((panel) => drawPanel(panel, getDesiredPanelWidth(panel, maxPanelWidth)));

  const widestPanel = renderedPanels.reduce((max, panelLines) => Math.max(max, maxLineWidth(panelLines)), 0);
  if (widestPanel >= width) {
    return stackPanels(width, renderedPanels);
  }

  return packRows(width, renderedPanels);
}
