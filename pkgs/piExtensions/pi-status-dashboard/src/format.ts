import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { DashboardState } from "./types";

export function formatCount(value: number): string {
  if (value < 1_000) return `${value}`;
  if (value < 10_000) return `${(value / 1_000).toFixed(1)}k`;
  if (value < 1_000_000) return `${Math.round(value / 1_000)}k`;
  if (value < 10_000_000) return `${(value / 1_000_000).toFixed(2)}M`;
  return `${(value / 1_000_000).toFixed(1)}M`;
}

export function formatCost(value: number): string {
  return `$${value.toFixed(2)}`;
}

export function formatDuration(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  if (hours > 0) return `${hours}h ${minutes}m ${seconds}s`;
  if (minutes > 0) return `${minutes}m ${seconds}s`;
  return `${seconds}s`;
}

export function formatReset(date: Date): string {
  const diffMs = date.getTime() - Date.now();
  if (diffMs < 0) return "now";

  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 60) return `${diffMins}m`;

  const hours = Math.floor(diffMins / 60);
  const mins = diffMins % 60;
  if (hours < 24) return mins > 0 ? `${hours}h${mins}m` : `${hours}h`;

  const days = Math.floor(hours / 24);
  const remHours = hours % 24;
  return remHours > 0 ? `${days}d${remHours}h` : `${days}d`;
}

export function sumAssistantUsage(ctx: ExtensionContext): DashboardState["totals"] {
  let input = 0;
  let output = 0;
  let cost = 0;

  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "message" || entry.message.role !== "assistant") continue;

    const message = entry.message as AssistantMessage;
    input += message.usage?.input ?? 0;
    output += message.usage?.output ?? 0;
    cost += message.usage?.cost?.total ?? 0;
  }

  return { input, output, cost };
}

export function getAccumulatedAgentMs(state: DashboardState): number {
  const current = state.currentAgentStartMs ? Date.now() - state.currentAgentStartMs : 0;
  return state.totalAgentMs + current;
}

export function getAccumulatedApiMs(state: DashboardState): number {
  const current = state.currentApiStartMs ? Date.now() - state.currentApiStartMs : 0;
  return state.totalApiMs + current;
}
