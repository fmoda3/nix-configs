/**
 * SHELL — the classifier's model call.
 *
 * Runs one classification as a side-channel request: the provider's `stream`
 * directly, with no session history, no tools but the classifier's own, and no
 * effect on the context window. Everything it decides is pure and lives
 * elsewhere — which model (`resolveClassifierModel`, src/router/ladder.ts), how
 * the request is shaped (`classifierOptions`, src/router/classify.ts), and what
 * counts as a valid reply (`parseToolArguments`). This module only makes the
 * call, enforces the time budget, and logs replies that failed.
 */

import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { contentText } from "@earendil-works/pi-ai";
import type { Tool, ToolCall } from "@earendil-works/pi-ai";
import {
  buildClassifierPrompt,
  CLASSIFIER_SYSTEM_PROMPT,
  CLASSIFIER_TOOL,
  classifierOptions,
  parseToolArguments,
} from "./classify.ts";
import { resolveClassifierModel, type AvailableModel } from "./ladder.ts";
import type { ClassifyOutcome, Family } from "./types.ts";
import { providerFor } from "./types.ts";

/** pi's api id for virtual models (VIRTUAL_MODEL_API, not exported by pi). */
const VIRTUAL_MODEL_API = "pi-virtual";

/**
 * Budget for the classifier round-trip. Past this, routing is not worth the
 * wait. Falls through to the default route.
 *
 * 10s rather than 6s: GPT-6 Luna's latency has a tail (occasional calls well
 * past 6s), which cut off a noticeable share of auto-gpt classifications.
 * Haiku stays around 1.5s, so the longer budget only costs anything when the
 * classifier is already slow. Paid at most once per session, before the first
 * token.
 */
export const CLASSIFY_TIMEOUT_MS = 10_000;

/**
 * Physical models a family's router may dispatch to: every authenticated model
 * of the family's provider (`anthropic` or `openai-codex`).
 *
 * Restricted to that one provider so the same model id served elsewhere is
 * never picked instead, and the prompt
 * never leaves the vendor the user selected.
 *
 * The session's `enabledModels` scope is deliberately not consulted: it
 * controls what the user cycles between, and a user who scoped down to
 * `anthropic/auto-claude` still expects it to reach the rungs behind it.
 */
export function availableModels(ctx: ExtensionContext, family: Family): readonly AvailableModel[] {
  const provider = providerFor(family);
  return ctx.modelRegistry
    .getAvailable()
    .filter((model) => model.provider === provider && String(model.api) !== VIRTUAL_MODEL_API)
    .map((model) => ({ provider: model.provider, id: model.id, name: model.name }));
}


/**
 * Run the classifier and return a validated outcome.
 *
 * Calls the provider's `stream` directly: this must not touch session history
 * or the context window. It is a side-channel question about the prompt, not
 * a turn in the conversation.
 *
 * The classification is obtained as a **forced tool call**, which is what makes
 * it reliable: a schema described in prose is a suggestion, a tool schema is
 * enforced by the provider during decoding. See CLASSIFIER_TOOL.
 */
export const runClassifier = async (
  ctx: ExtensionContext,
  prompt: string,
  family: Family,
  signal?: AbortSignal,
  /** What the agent has read since the prompt, for a deferred classification. */
  context?: string,
): Promise<ClassifyOutcome> => {
  const available = availableModels(ctx, family);
  const classifierTarget = resolveClassifierModel(family, available);
  if (!classifierTarget) return { ok: false, failure: { kind: "no-classifier-model", family } };

  const model = ctx.modelRegistry.find(classifierTarget.provider, classifierTarget.modelId);
  if (!model) return { ok: false, failure: { kind: "no-classifier-model", family } };

  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), CLASSIFY_TIMEOUT_MS);
  // The user pressing Esc aborts the request being routed; the classifier
  // call is part of that request, so it goes down with it.
  const cancel = () => abort.abort();
  signal?.addEventListener("abort", cancel, { once: true });

  try {
    const stream = ctx.modelRegistry.stream(
      model,
      {
        systemPrompt: CLASSIFIER_SYSTEM_PROMPT,
        messages: [{ role: "user", content: buildClassifierPrompt(prompt, context), timestamp: Date.now() }],
        tools: [CLASSIFIER_TOOL as unknown as Tool],
      },
      {
        // Force the tool rather than offering it: an optional tool is another
        // thing the model may decline, which is the failure mode being fixed.
        // Models that reject forcing (Opus 5.5) are offered it instead.
        ...classifierOptions({ ...model, api: String(model.api) }),
        // `temperature` and reasoning are deliberately not set (see
        // `classifierOptions`).
        signal: abort.signal,
      } as Parameters<typeof ctx.modelRegistry.stream>[2],
    );

    const message = await stream.result();
    if (message.stopReason === "error" || message.stopReason === "aborted") {
      return abort.signal.aborted
        ? { ok: false, failure: { kind: "timeout", ms: CLASSIFY_TIMEOUT_MS } }
        : { ok: false, failure: { kind: "provider-error", message: message.errorMessage ?? "unknown error" } };
    }

    // Preferred path: the schema-enforced tool call.
    const call = message.content.find(
      (part): part is ToolCall => part.type === "toolCall" && part.name === CLASSIFIER_TOOL.name,
    );
    if (call) return parseToolArguments(call.arguments);

    // No tool call came back. There is no second format to try: the schema is
    // enforced through the tool, so this is terminal. The reply is surfaced
    // because it is the whole diagnosis.
    const text = contentText(message.content);
    return { ok: false, failure: { kind: "no-tool-call", raw: text.slice(0, 400), stopReason: String(message.stopReason) } };
  } catch (error) {
    if (abort.signal.aborted) {
      return { ok: false, failure: { kind: "timeout", ms: CLASSIFY_TIMEOUT_MS } };
    }
    return { ok: false, failure: { kind: "provider-error", message: error instanceof Error ? error.message : String(error) } };
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener("abort", cancel);
  }
};
