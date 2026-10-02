/**
 * FUNCTIONAL CORE — no I/O.
 *
 * Builds the classifier prompt and validates its response.
 *
 * The LLM call itself lives in the shell (classifier-call.ts); this module only
 * turns a prompt into request text and untrusted response text into a
 * `ClassifyOutcome`. That split is what makes the interesting part — "do we
 * correctly reject a malformed classification?" — unit-testable without a
 * network or a model.
 *
 * Validation is deliberately strict. A classifier that returns
 * `{"level":"medium"}` (not a level) or omits a rationale must fail loudly rather
 * than be coerced into a plausible-looking default, because a silently wrong
 * route is worse than no route: it trains the user to distrust the router
 * without telling them why.
 */

import type { ClassifyOutcome, Level } from "./types.ts";
import { LEVELS } from "./types.ts";
import { normalizeModelId } from "./ladder.ts";
import { StringEnum, Type } from "@earendil-works/pi-ai";

/**
 * The classifier tool — the mechanism that actually makes classification
 * reliable, after two failed attempts at asking politely:
 *
 *   1. "Reply with ONLY a JSON object" — the model returned a markdown report
 *      (`# Classification\n\n**Category:** ...`), stopReason "stop".
 *   2. Prefilling `{"tier": "` — valid JSON, but the model invented its own
 *      vocabulary: `{"tier": "read-only", "reasoning": "..."}` — value outside
 *      the enum, wrong key name, a required field missing entirely.
 *
 * Both failures share one cause: the schema lived in prose, so adherence was the
 * model's choice. Declared as a tool, the schema is enforced by the provider
 * during decoding — `"read-only"` is not a value the API can emit, because it is
 * not in the enum. Measured 12/12 across claude-haiku-4-5 and claude-sonnet-5,
 * including the exact prompt that failed twice.
 *
 * `StringEnum` rather than a plain string is the load-bearing detail: it emits a
 * real JSON-schema `enum`, which is what constrains sampling.
 *
 * There is one axis, `level`. The classifier used to choose a tier and an effort
 * independently, which let it pick pairs no one should pay for (a mid-size model
 * at maximum effort costs more than a large one at medium, and scores lower).
 * The ladder now owns the model/effort pairing; the classifier only judges how
 * demanding the request is.
 */
export const CLASSIFIER_TOOL = {
  name: "route_request",
  description: "Report how demanding this request is.",
  parameters: Type.Object({
    level: StringEnum([...LEVELS] as [Level, ...Level[]], {
      description:
        "trivial: lookups, explanations, one-line edits. simple: small, well-specified changes with an obvious approach. moderate: normal feature work, multi-file changes, ordinary debugging. complex: cross-cutting changes, unfamiliar code, non-obvious debugging. hard: subtle correctness, concurrency or security work, architecture; costs several times moderate. extreme: reserve for work that would plausibly defeat hard.",
    }),
    rationale: Type.String({
      description:
        "One sentence, max 200 chars, naming the specific signal in the request that drove the choice so a developer can judge whether to override it. Do not restate the request.",
    }),
    needs_context: Type.Boolean({
      description:
        "true when the request's scope is defined by material it only points to and does not include — a ticket or issue key, a URL, a file or document it names. false when the request describes its task itself (reading code does not count), or a <context> block is present.",
    }),
  }),
} as const;

/** Hard cap on rationale length, so the routing record stays readable. */
const MAX_RATIONALE_CHARS = 240;

/**
 * Prompt text is truncated before classification. The first ~2k characters
 * carry the intent; sending a 200-line paste to the classifier would cost more
 * than the routing decision saves.
 */
export const MAX_CLASSIFIED_PROMPT_CHARS = 2000;

export function truncatePrompt(text: string, limit = MAX_CLASSIFIED_PROMPT_CHARS): string {
  const trimmed = text.trim();
  return trimmed.length <= limit ? trimmed : `${trimmed.slice(0, limit)}\n[...truncated]`;
}

// ─── Prompt construction ──────────────────────────────────────────────────────

export const CLASSIFIER_SYSTEM_PROMPT = `You are a routing classifier for a coding agent. You do not answer the user's request. You choose how much capability the request needs.

Report your decision by calling the route_request tool. Do not reply with prose.

Choose the least demanding level that will plausibly succeed. Each step up costs more; the cheaper levels are real models that handle their work well, not weak fallbacks.

Level guidance:
- "trivial": lookups, explaining code, renames, formatting, running a known command, one-line edits. Summarising a document is trivial; checking it against the code is not (see below).
- "simple": small, well-specified changes with an obvious approach — a single function, a test for existing behaviour, a config change.
- "moderate": normal feature work, multi-file changes, debugging with a clear reproduction, writing tests. The default for ordinary engineering work.
- "complex": cross-cutting changes, unfamiliar or sprawling code, debugging without a clear reproduction, real design trade-offs.
- "hard": reserve this. It costs several times "moderate". Subtle correctness or concurrency bugs, security-sensitive work, architecture decisions, or anything where a mistake is expensive and hard to detect. If "complex" would plausibly succeed, choose "complex".
- "extreme": reserve this. It costs several times "hard". Only for a problem that has already resisted a competent attempt, or one needing very long chains of dependent reasoning across a large body of code. If "hard" would plausibly succeed, choose "hard".

Audits:
- Checking material against the code — "see what's left to implement in X", "which items in X are done", "does the code match the spec" — is an audit, not a lookup: every item has to be looked for in the code. Choose at least "simple", and "moderate" or more when the material lists many items or spans several areas.

Context:
- Set needs_context to true when you cannot judge the scope because the request only points at it: "implement PROJ-1234", "fix the issue at <url>", "do what docs/plan.md says". Still choose the level you would guess; the request will be re-assessed after the agent has read the material.
- Set needs_context to false when the request is self-contained, or when a reference is incidental ("follow the style in README.md").
- The codebase itself never counts: the agent always reads code. A request that describes its task in its own words ("there's a race in the settlement job; fix it") is self-contained even though the code must be read.
- If a <context> block follows the request, it is material the agent has already read for this request. Judge the level from the request and that material together, and set needs_context to false.

The rationale must state the specific signal in the request that drove the choice, so a developer can judge whether to override you. Do not restate the request. If you chose "hard" or "extreme", the rationale must say what makes the level below insufficient.`;

/**
 * The classifier's user message: the request, and — for a deferred
 * classification — an excerpt of what the agent has read since (see
 * `contextExcerpt`, src/router/plan.ts).
 */
export function buildClassifierPrompt(userPrompt: string, context?: string): string {
  const request = `Classify this request:\n\n<request>\n${truncatePrompt(userPrompt)}\n</request>`;
  return context === undefined || context.trim() === "" ? request : `${request}\n\n<context>\n${context}\n</context>`;
}

/**
 * Options that force the classifier tool.
 *
 * An *offered* tool is one more thing the model can decline, which is the exact
 * failure mode being fixed, so it is forced. Anthropic takes `{type:"tool",name}`;
 * the Codex Responses api takes only `"required"` (the classifier's tool is the
 * only one sent, so that forces it).
 */
export function toolChoiceFor(api: string): Record<string, unknown> {
  if (api === "anthropic-messages") return { toolChoice: { type: "tool", name: CLASSIFIER_TOOL.name } };
  if (api === "openai-codex-responses") return { toolChoice: "required" };
  return {};
}

/**
 * Models that reject a forced tool choice outright.
 *
 * Claude Opus 5.5 always reasons (adaptive thinking is on for every request), and
 * Anthropic does not allow forcing a tool while thinking: the request fails with
 * `tool_choice: type "tool" and "any" are not supported for this model`. Opus 5.5
 * is the Claude classifier's fallback when Haiku is unavailable, so forcing there
 * would fail every classification. Offered the tool instead, it called it 72/72 times.
 * Normalized ids, matched exactly.
 */
const REJECTS_FORCED_TOOL_CHOICE = new Set(["claude-opus-5-5"]);

export function rejectsForcedToolChoice(model: { readonly id: string }): boolean {
  return REJECTS_FORCED_TOOL_CHOICE.has(normalizeModelId(model.id));
}

/**
 * Reply budget. A forced tool call is ~75 tokens, so 512 is ample headroom (an
 * early 200-token cap cut replies off mid-structure). Without forcing, a model
 * that always thinks reasons before the call, so it gets room for that; unused
 * budget costs nothing.
 */
const MAX_TOKENS_FORCED = 512;
const MAX_TOKENS_UNFORCED = 2048;

/**
 * How the classifier request is shaped for a given model.
 *
 * No reasoning option is sent. On `anthropic-messages` that means thinking is
 * off; on `openai-codex-responses` pi then sends the model's `off` effort
 * (`none` for GPT-6 Luna and Sol), which is what a fast classification wants.
 * `temperature` is never sent either: the 5.x Claude models reject it.
 */
export function classifierOptions(model: { readonly api: string; readonly id: string }): Record<string, unknown> {
  const forced = !rejectsForcedToolChoice(model);
  return { maxTokens: forced ? MAX_TOKENS_FORCED : MAX_TOKENS_UNFORCED, ...(forced ? toolChoiceFor(model.api) : {}) };
}

// ─── Response validation ───────────────────────────────────────────────

/**
 * Validate tool-call arguments into a `Suggestion`.
 *
 * Validated despite provider-side enforcement, because arguments arrive typed as
 * `Record<string, any>` and enforcement strength varies by provider. This is the
 * only way a classification enters the router.
 */
export function parseToolArguments(args: Record<string, unknown>): ClassifyOutcome {
  return validateFields(args, "tool call");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isLevel(value: unknown): value is Level {
  return typeof value === "string" && (LEVELS as readonly string[]).includes(value);
}

/** Collapse whitespace and clamp length; rationale is rendered on one line. */
export function normalizeRationale(text: string): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length <= MAX_RATIONALE_CHARS ? flat : `${flat.slice(0, MAX_RATIONALE_CHARS - 1)}…`;
}

/**
 * Validate an already-parsed field bag into a `Suggestion`.
 *
 * `source` is only used to make the failure message say where the bad fields
 * came from.
 */
function validateFields(parsed: unknown, source: string): ClassifyOutcome {
  if (!isRecord(parsed)) {
    return { ok: false, failure: { kind: "invalid-fields", detail: `${source} was not an object` } };
  }
  if (!isLevel(parsed.level)) {
    return {
      ok: false,
      failure: {
        kind: "invalid-fields",
        detail: `level must be one of ${LEVELS.join("|")}, got ${JSON.stringify(parsed.level)}`,
      },
    };
  }
  const rationale = typeof parsed.rationale === "string" ? normalizeRationale(parsed.rationale) : "";
  return {
    ok: true,
    suggestion: {
      level: parsed.level,
      // Missing or malformed means "no": the cost of a wrong "no" is today's
      // behaviour (route from the prompt alone), while a wrong "yes" would
      // spend a scouting turn for nothing.
      needsContext: parsed.needs_context === true,
      // An empty rationale is tolerated rather than fatal: the route is still
      // valid, the user just gets less to go on.
      rationale: rationale === "" ? "(no rationale returned)" : rationale,
    },
  };
}
