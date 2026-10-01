import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { DashboardState } from "./types";

/**
 * The `api` of a virtual model (e.g. `toast/auto-claude`) that routes each
 * request to a physical model. pi does not export its constant, so it is
 * mirrored here.
 */
export const VIRTUAL_MODEL_API = "pi-virtual";

type ResponseModel = { provider: string; modelId: string; thinkingLevel: string | null };

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

export function sumSessionUsage(ctx: ExtensionContext): DashboardState["totals"] {
  const totals: DashboardState["totals"] = {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    cost: 0,
    latestCacheHitRate: null,
  };

  const addUsage = (usage: AssistantMessage["usage"] | undefined) => {
    if (!usage) return;
    totals.input += usage.input ?? 0;
    totals.output += usage.output ?? 0;
    totals.cacheRead += usage.cacheRead ?? 0;
    totals.cacheWrite += usage.cacheWrite ?? 0;
    totals.cost += usage.cost?.total ?? 0;
  };

  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "message" && entry.message.role === "assistant") {
      const usage = (entry.message as AssistantMessage).usage;
      addUsage(usage);

      const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
      totals.latestCacheHitRate = promptTokens > 0 ? (usage.cacheRead / promptTokens) * 100 : null;
    } else if (entry.type === "message" && entry.message.role === "toolResult") {
      addUsage(entry.message.usage);
    } else if ((entry.type === "branch_summary" || entry.type === "compaction") && entry.usage) {
      addUsage(entry.usage);
    }
  }

  return totals;
}

/** Whether a model is a virtual selection that routes to physical models. */
export function isVirtualSelection(model: { api?: unknown } | undefined): boolean {
  return model !== undefined && String(model.api) === VIRTUAL_MODEL_API;
}

/**
 * The physical model and level of the latest successful response on a branch.
 *
 * Failed and aborted responses are skipped, as pi does: a failed routing
 * attempt records the virtual model, which is not what answered.
 */
export function latestResponseModel(entries: readonly { type: string; message?: unknown }[]): ResponseModel | null {
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index];
    if (entry.type !== "message") continue;
    const model = responseModel(entry.message);
    if (model) return model;
  }
  return null;
}

/**
 * The physical model and level of one assistant message, or null when it is not
 * a usable response: not an assistant message, failed or aborted, or a failed
 * routing attempt that still names the virtual model.
 *
 * Used directly on `message_start`/`message_end` events, because pi hands those
 * to extensions *before* the message is saved to the session — reading the
 * branch there sees the previous response, one behind.
 */
export function responseModel(message: unknown): ResponseModel | null {
  const assistant = message as Partial<AssistantMessage> | undefined;
  if (assistant?.role !== "assistant") return null;
  if (assistant.stopReason === "error" || assistant.stopReason === "aborted") return null;
  if (String(assistant.api) === VIRTUAL_MODEL_API || !assistant.provider || !assistant.model) return null;
  return { provider: assistant.provider, modelId: assistant.model, thinkingLevel: assistant.thinkingLevel ?? null };
}

/**
 * Combine a newly seen route with the one shown.
 *
 * pi only attaches `thinkingLevel` to a *finished* assistant message, so the
 * partial message at `message_start` has none. When the model is unchanged,
 * keep the effort already known; when the model changed, the old effort is not
 * this model's, so show none until the response finishes.
 */
export function mergeRoute<R extends ResponseModel>(shown: R | null, next: R): R {
  if (next.thinkingLevel !== null || !shown) return next;
  return shown.provider === next.provider && shown.modelId === next.modelId
    ? { ...next, thinkingLevel: shown.thinkingLevel }
    : next;
}

export function getAccumulatedAgentMs(state: DashboardState): number {
  const current = state.currentAgentStartMs ? Date.now() - state.currentAgentStartMs : 0;
  return state.totalAgentMs + current;
}
