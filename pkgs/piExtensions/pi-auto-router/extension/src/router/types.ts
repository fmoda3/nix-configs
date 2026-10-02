/**
 * Domain types for the model/effort router.
 *
 * The router backs the `anthropic/auto-claude` and `openai-codex/auto-gpt`
 * virtual models.
 * It classifies the first user prompt on a session branch into a difficulty
 * **level**, which names one fixed `(model, effort)` rung on the family's
 * Pareto frontier (src/router/ladder.ts), and routes the rest
 * of the branch there.
 *
 * Model and effort are deliberately not chosen independently. A bigger model at
 * low effort is often both smarter and cheaper than a smaller one at high
 * effort, so most `(model, effort)` pairs are never worth paying for. The
 * classifier picks how hard the work is; the ladder already knows the cheapest
 * pair that handles that difficulty.
 *
 * Everything here is data only — no I/O, no pi imports. The shapes are chosen
 * so invalid states cannot be represented:
 *
 *   - `Level` is a closed union, so a classifier hallucinating "super-max"
 *     fails validation at the boundary rather than reaching a model.
 *   - `ClassifyOutcome` is a sum type: a suggestion either exists with a
 *     rationale, or it does not exist with a reason.
 *   - `RouterState` is the only thing persisted between requests, and it is
 *     re-validated at the boundary because it is read back from session files.
 */

// ─── The axis the router sets ─────────────────────────────────────────────────

/**
 * How demanding the request is. Each level maps to exactly one rung per family.
 *
 * Ordered cheapest-first. That ordering is load-bearing: the degradation walk,
 * the premium gate and the ladder's frontier property all depend on it.
 */
export type Level = "trivial" | "simple" | "moderate" | "complex" | "hard" | "extreme";

export const LEVELS: readonly Level[] = ["trivial", "simple", "moderate", "complex", "hard", "extreme"];

/**
 * Levels whose cost warrants an explicit acknowledgement before being applied.
 *
 * `hard` and `extreme` cost 2.6–4.5× a `moderate` route per task on both
 * ladders. The classifier may suggest them, because refusing would make it
 * useless for the work that genuinely needs them, but spending that much must
 * not happen without the user saying so.
 */
export function isPremiumLevel(level: Level): boolean {
  return level === "hard" || level === "extreme";
}

/**
 * Where a declined premium route goes: the most capable level that needs no
 * confirmation. There is no "keep current" for a virtual model.
 */
export const DECLINED_LEVEL: Level = "complex";

/**
 * Thinking effort. The full set pi supports, matching pi-ai's
 * `ModelThinkingLevel` exactly. Ordered cheapest-first.
 *
 * Each rung fixes one effort, but support is per-model: `xhigh` and `max` exist
 * only when a model's `thinkingLevelMap` declares them, and a model can disable
 * `off`. A rung's effort is therefore still clamped against the model before it
 * is applied — see `supportedEfforts` — so a catalog change cannot make the
 * routing record promise a level the request never ran at.
 */
export type Effort = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

export const EFFORTS: readonly Effort[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];

/** LLM family used for both the classifier call and the suggested ladder. */
export type Family = "claude" | "gpt";

/**
 * The virtual models, one per ladder.
 *
 * Each is listed under the provider that serves every rung of its ladder, so
 * pi offers it exactly when that provider has credentials (pi's
 * docs/virtual-models.md): `auto-claude` once you are signed in to
 * `anthropic`, `auto-gpt` once you are signed in to `openai-codex`. The router
 * only ever dispatches to — and classifies on — models of that same provider,
 * so a prompt never leaves the vendor the user picked.
 *
 * `ref` is the full `provider/id` pi selects them by, spelled out so it can be
 * a closed union: routing entries read back from session files are validated
 * against it. It must equal `${provider}/${id}`.
 */
export const AUTO_MODELS = [
  { ref: "anthropic/auto-claude", provider: "anthropic", id: "auto-claude", name: "Auto (Claude)", family: "claude" },
  { ref: "openai-codex/auto-gpt", provider: "openai-codex", id: "auto-gpt", name: "Auto (GPT)", family: "gpt" },
] as const satisfies readonly { ref: string; provider: string; id: string; name: string; family: Family }[];

export type AutoModel = (typeof AUTO_MODELS)[number];

/** `anthropic/auto-claude` | `openai-codex/auto-gpt`. */
export type AutoModelRef = AutoModel["ref"];

/** The provider that serves a family's ladder. */
export function providerFor(family: Family): string {
  return AUTO_MODELS.find((auto) => auto.family === family)!.provider;
}

// ─── Classifier output ────────────────────────────────────────────────────────

/** A validated classifier result. */
export interface Suggestion {
  readonly level: Level;
  /**
   * The request's scope depends on material it only points to (a ticket, an
   * issue, a URL, a file), so the level is a guess to re-assess once the agent
   * has read it (deferred classification, src/router/plan.ts).
   */
  readonly needsContext: boolean;
  /**
   * One-sentence justification shown to the user. This is the whole point of
   * the feature: without a rationale the user has no basis to decide whether
   * to trust the classifier over their own intuition.
   */
  readonly rationale: string;
}

/**
 * Why no suggestion was produced. Each case is user-visible, because a router
 * that silently does nothing is indistinguishable from a broken router.
 */
export type ClassifyFailure =
  | { readonly kind: "no-classifier-model"; readonly family: Family }
  /**
   * The provider did not return the forced tool call.
   *
   * The classification is obtained as a schema-enforced tool call, so there is no
   * second format to fall back to — this is the honest terminal state. `raw`
   * carries whatever text did come back, because that text is the entire
   * diagnosis.
   */
  | { readonly kind: "no-tool-call"; readonly raw: string; readonly stopReason: string }
  | { readonly kind: "invalid-fields"; readonly detail: string }
  | { readonly kind: "provider-error"; readonly message: string }
  | { readonly kind: "timeout"; readonly ms: number };

export type ClassifyOutcome =
  | { readonly ok: true; readonly suggestion: Suggestion }
  | { readonly ok: false; readonly failure: ClassifyFailure };

// ─── Routing decision ────────────────────────────────────────────────────────

/**
 * One rung of a family's ladder: a fixed model and effort, with the benchmark
 * point that put it on the frontier.
 */
export interface Rung {
  /** Normalized model id, e.g. "claude-opus-5-5" (see `normalizeModelId`). */
  readonly model: string;
  readonly effort: Effort;
  /**
   * Artificial Analysis Intelligence Index v4.3.2 score and cost per index task
   * (USD, list price incl. cache) for this pair: the evidence that put it on the
   * frontier. At runtime it is read for one thing, the cost multiple stated in
   * the spend confirmation (`costMultiple`).
   */
  readonly benchmark: { readonly index: number; readonly costPerTask: number };
}

/** A level resolved against the models actually available to this session. */
export interface ResolvedTarget {
  /** The level actually resolved, which differs from the request on substitution. */
  readonly level: Level;
  readonly provider: string;
  readonly modelId: string;
  /** Display label, e.g. "claude-opus-5-5". */
  readonly label: string;
  /** The rung's effort, before clamping to the model. */
  readonly effort: Effort;
}

/**
 * How one request was routed, and what moved it away from the classifier's
 * choice. The single description of a route shared by the routing record
 * (src/router/entry.ts) and the adjustment text — and, as the
 * record's data, persisted in session files, so it holds display labels only,
 * never provider ids.
 */
export interface RouteExplanation {
  /** Display label of the physical model, e.g. "Claude Opus 5.5". */
  readonly label: string;
  /** The level actually routed to, after the offset, substitution and any decline. */
  readonly level: Level;
  /** Effort actually applied (after clamping to the model). */
  readonly effort: Effort;
  /** The level the classifier chose, before the effort offset. */
  readonly classified: Level;
  /** The level after the offset, before any substitution or decline. */
  readonly requested: Level;
  readonly offset: number;
  /** The auto model's selected thinking level. */
  readonly selectedEffort: string;
  /** The spend confirmation was declined (or could not be asked). */
  readonly declined: boolean;
}

/**
 * Router state persisted on the session branch by pi (see docs/virtual-models.md).
 *
 * Two phases:
 *
 *   - `RoutedState`: the branch has a level. The usual case.
 *   - `ScoutingState`: the first prompt only pointed at its scope (a ticket, an
 *     issue, a URL, a file), so classification is deferred until the agent has
 *     read it. Requests go to a scout rung meanwhile.
 *
 * The family is not stored: pi keys state by virtual model, so `auto-claude` and
 * `auto-gpt` never see each other's state. State from the tier × effort router
 * (`{ tier, effort }`) fails validation and simply re-classifies.
 */
export type RouterState = RoutedState | ScoutingState;

/**
 * `level` is the level the classifier chose, *before* the effort offset: the
 * offset is applied on every request from the thinking level selected at the
 * time, so changing effort mid-session moves the route without re-classifying.
 * The level — not a model id — is stored, so resolution keeps working if the
 * catalog loses the exact model mid-session.
 *
 * `approved` and `declined` remember the spend confirmation, so a premium route
 * is asked about once per branch rather than on every prompt. Each holds the
 * highest premium level the user answered for; a route above it asks again.
 */
export interface RoutedState {
  readonly level: Level;
  readonly approved?: Level;
  readonly declined?: Level;
}

/**
 * Classification deferred until the agent has read the material the prompt
 * points to.
 *
 * `stalled` is set when the deferred classification itself failed: the rest of that turn stays put rather than re-trying on every tool
 * round, and the next user prompt classifies again.
 */
export interface ScoutingState {
  readonly phase: "scouting";
  readonly stalled?: boolean;
}

export function isScouting(state: RouterState): state is ScoutingState {
  return "phase" in state && state.phase === "scouting";
}
