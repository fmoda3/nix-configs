/**
 * FUNCTIONAL CORE — no I/O.
 *
 * Decides, for one request made with an auto virtual model, *how* the
 * physical model is chosen: which plan applies, how the selected thinking level
 * shifts the classified level, and whether the result needs the spend
 * confirmation. The shell (src/auto-router.ts) carries the plan out: it
 * resolves levels against the catalog, runs the classifier, and asks.
 *
 * The rules exist to keep prompt caches and thinking signatures valid (see
 * pi's docs/virtual-models.md):
 *
 *   - A retry stays on the model that failed; a tool follow-up stays on the
 *     model that handled the turn. Switching mid-turn would throw the cache away.
 *   - Once a branch has router state, every user prompt reuses it. The
 *     classifier runs once per branch, not once per prompt.
 *   - Only a user prompt on a branch with no state is classified — unless the
 *     prompt only pointed at its scope (a ticket, a URL, a file): then the
 *     branch scouts on a mid rung and classifies again once the agent has read
 *     something (`planScouting`).
 *   - The virtual model's thinking level is an offset on the classified level,
 *     re-applied on every routed request, so turning effort up mid-session moves
 *     the next prompt up the ladder without a second classifier call.
 */

import type { Message } from "@earendil-works/pi-ai";
import type { Effort, Level, RoutedState, RouterState } from "./types.ts";
import { DECLINED_LEVEL, LEVELS, isPremiumLevel, isScouting } from "./types.ts";

/**
 * The subset of pi's `ModelRouteRequest` the planner looks at.
 *
 * Generic over the physical-choice shape so the planner can hand pi's own
 * `previous`/`failed` objects straight back without importing pi's types or
 * re-looking the model up.
 */
export interface PlanInput<C> {
  readonly reason: "user" | "continuation" | "retry" | "direct";
  /** Physical model + level of the latest successful response. */
  readonly previous?: C;
  /** For retries: the physical model + level that just failed. */
  readonly failed?: C;
  readonly state: RouterState | undefined;
  /**
   * Tool results have arrived since the latest user message — the agent has
   * read something. What a scouting branch waits for (see `hasNewContext`).
   */
  readonly hasNewContext: boolean;
}

export type RoutePlan<C> =
  /** Reuse a physical model exactly as it was used before. */
  | { readonly kind: "sticky"; readonly choice: C }
  /** Resolve a level already decided for this branch. */
  | { readonly kind: "state"; readonly state: RoutedState }
  /**
   * Classify and store the result as state. `withContext` adds what the agent
   * has read since the prompt — the deferred classification of a scouting
   * branch.
   */
  | { readonly kind: "classify"; readonly withContext: boolean }
  /** Keep scouting on the scout rung until there is context to classify with. */
  | { readonly kind: "scout" }
  /** Nothing to go on and nothing to classify: use the default route. */
  | { readonly kind: "default" };

/**
 * Where a request goes when there is no decision and none can be made: the
 * `moderate` rung — Opus 5.5 at medium (Anthropic's own default) or Sol at high.
 * Also where a failed classification lands, so a classifier outage costs the
 * user a routing decision, never their prompt.
 */
export const DEFAULT_ROUTE: RoutedState = { level: "moderate" };

/**
 * Where a scouting branch runs while the agent reads the material the prompt
 * points to: the `simple` rung (Opus 5.5 · low, Luna · max). Reading a ticket or
 * a file needs competent tool use, not depth; the real level comes after.
 */
export const SCOUT_LEVEL: Level = "simple";

export function planRoute<C>(input: PlanInput<C>): RoutePlan<C> {
  const { state } = input;
  if (state && isScouting(state)) return planScouting(input, state);
  switch (input.reason) {
    case "retry":
      // `failed` is absent when routing itself failed; then there is nothing to
      // stick to, and the request is planned as if it were fresh.
      if (input.failed) return { kind: "sticky", choice: input.failed };
      return state ? { kind: "state", state } : { kind: "classify", withContext: false };
    case "continuation":
      if (input.previous) return { kind: "sticky", choice: input.previous };
      return state ? { kind: "state", state } : { kind: "classify", withContext: false };
    case "user":
      return state ? { kind: "state", state } : { kind: "classify", withContext: false };
    case "direct":
      // Compaction summaries and extension calls. pi never passes state here
      // (docs/virtual-models.md), so stick to whatever answered last; a direct
      // call before any response gets the default rather than a classifier
      // round-trip for a side request.
      return input.previous ? { kind: "sticky", choice: input.previous } : { kind: "default" };
  }
}

/**
 * A scouting branch: the prompt only pointed at its scope, so it runs on the
 * scout rung until the agent has read something, then classifies again with
 * what was read. That switch happens mid-turn, at the first request after tool
 * results, and costs one prompt-cache miss — the same trade pi's jev-router
 * example makes.
 */
function planScouting<C>(input: PlanInput<C>, state: { readonly stalled?: boolean }): RoutePlan<C> {
  switch (input.reason) {
    case "retry":
      if (input.failed) return { kind: "sticky", choice: input.failed };
      return { kind: "scout" };
    case "continuation":
      // The agent has read something: classify with it. A stalled attempt
      // (the deferred classification failed) does not retry every tool round.
      if (input.hasNewContext && !state.stalled) return { kind: "classify", withContext: true };
      return input.previous ? { kind: "sticky", choice: input.previous } : { kind: "scout" };
    case "user":
      // A new user message — often the answer to a clarifying question — can
      // define the scope by itself. Classify it afresh; if it still only points
      // elsewhere, the branch keeps scouting.
      return { kind: "classify", withContext: false };
    case "direct":
      return input.previous ? { kind: "sticky", choice: input.previous } : { kind: "scout" };
  }
}

/** Whether any tool results have arrived since the latest user message. */
export function hasNewContext(messages: readonly Message[]): boolean {
  for (let index = messages.length - 1; index >= 0; index--) {
    const role = messages[index].role;
    if (role === "user") return false;
    if (role === "toolResult") return true;
  }
  return false;
}

/**
 * What the agent has read since the latest user message, for the classifier:
 * each tool result's text, labelled with the tool, capped per result and in
 * total so a large file or page cannot turn a cheap classification into an
 * expensive one.
 */
export const MAX_CONTEXT_PER_RESULT = 3000;
export const MAX_CONTEXT_TOTAL = 8000;

export function contextExcerpt(
  messages: readonly Message[],
  limits: { readonly perResult: number; readonly total: number } = { perResult: MAX_CONTEXT_PER_RESULT, total: MAX_CONTEXT_TOTAL },
): string {
  let start = messages.length;
  for (let index = messages.length - 1; index >= 0; index--) {
    if (messages[index].role === "user") break;
    start = index;
  }
  const parts: string[] = [];
  let used = 0;
  for (const message of messages.slice(start)) {
    if (message.role !== "toolResult") continue;
    const text = message.content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("\n").trim();
    if (text === "") continue;
    const clipped = text.length <= limits.perResult ? text : `${text.slice(0, limits.perResult)}\n[...truncated]`;
    const part = `[${message.toolName}]\n${clipped}`;
    if (used + part.length > limits.total) {
      const room = limits.total - used;
      if (room > 200) parts.push(`${part.slice(0, room)}\n[...truncated]`);
      break;
    }
    parts.push(part);
    used += part.length;
  }
  return parts.join("\n\n");
}

// ─── Effort offset ────────────────────────────────────────────────────────────

/**
 * The thinking levels the auto models offer, and what each does to the route.
 *
 * The level is read as "how much more (or less) than the router would choose":
 * `medium` routes exactly as classified; each step either side moves one level
 * along the ladder. `off` and `max` are not offered — "no thinking" is never on
 * the frontier, and the top of the ladder is already reachable at `xhigh`.
 */
export const EFFORT_OFFSETS = {
  minimal: -2,
  low: -1,
  medium: 0,
  high: 1,
  xhigh: 2,
} as const satisfies Partial<Record<Effort, number>>;

export type VirtualEffort = keyof typeof EFFORT_OFFSETS;

export const VIRTUAL_EFFORTS: readonly VirtualEffort[] = ["minimal", "low", "medium", "high", "xhigh"];

/**
 * The offset for a selected thinking level. Anything unoffered (pi clamps the
 * selection to the offered levels, but a session file can hold anything) means
 * no offset, i.e. route as classified.
 */
export function effortOffset(level: string | undefined): number {
  return level !== undefined && level in EFFORT_OFFSETS ? EFFORT_OFFSETS[level as VirtualEffort] : 0;
}

/** Move a level along the ladder, clamped to its ends. */
export function shiftLevel(level: Level, offset: number): Level {
  const index = LEVELS.indexOf(level) + offset;
  return LEVELS[Math.max(0, Math.min(LEVELS.length - 1, index))];
}

/**
 * The route used when there is nothing to classify, or classification failed:
 * `moderate`, shifted by effort, but never into a premium level. A fallback
 * must not be what triggers a spend confirmation — nothing was judged to need it.
 */
export function fallbackLevel(offset: number): Level {
  return cappedShift(DEFAULT_ROUTE.level, offset);
}

/** The scout rung's level, shifted by effort like the fallback and likewise never premium. */
export function scoutLevel(offset: number): Level {
  return cappedShift(SCOUT_LEVEL, offset);
}

function cappedShift(level: Level, offset: number): Level {
  const shifted = shiftLevel(level, offset);
  return isPremiumLevel(shifted) ? DECLINED_LEVEL : shifted;
}

// ─── Spend confirmation ───────────────────────────────────────────────────────

const rank = (level: Level) => LEVELS.indexOf(level);

export type PremiumDecision =
  /** Route to this level without asking. */
  | { readonly kind: "route"; readonly level: Level }
  /** Already declined at or above this level on this branch: take the fallback silently. */
  | { readonly kind: "declined"; readonly level: Level }
  /** Ask; on "no", route to `fallback`. */
  | { readonly kind: "confirm"; readonly level: Level; readonly fallback: Level };

/**
 * Whether routing to `level` needs the spend confirmation on this branch.
 *
 * A premium level is asked about once: an approval covers that level and
 * everything below it, and a decline covers the same, so a session is not asked
 * on every prompt. A route *above* what was answered — the user turned effort
 * up again — asks again, because it is a new, bigger expense.
 *
 * Declining routes to the highest level already approved below the request,
 * else `complex`: there is no "keep current" for a virtual model, so declining
 * has to mean "the same, but cheaper".
 */
export function premiumDecision(level: Level, state: Pick<RoutedState, "approved" | "declined"> | undefined): PremiumDecision {
  if (!isPremiumLevel(level)) return { kind: "route", level };
  const approved = state?.approved;
  if (approved !== undefined && rank(level) <= rank(approved)) return { kind: "route", level };
  const fallback = approved !== undefined && rank(approved) < rank(level) ? approved : DECLINED_LEVEL;
  const declined = state?.declined;
  if (declined !== undefined && rank(level) <= rank(declined)) return { kind: "declined", level: fallback };
  return { kind: "confirm", level, fallback };
}

/** Record the answer to a confirmation for `level`. */
export function recordAnswer(state: RoutedState, level: Level, approved: boolean): RoutedState {
  return approved ? { ...state, approved: level } : { ...state, declined: level };
}

// ─── Routing a level ──────────────────────────────────────────────────────────

/** The result of routing a stored level, before it is resolved to a model. */
export interface LevelOutcome {
  /** Level to resolve and route to. */
  readonly level: Level;
  /** After the effort offset, before substitution or decline. */
  readonly requested: Level;
  readonly declined: boolean;
  readonly premiumPrompted: boolean;
  /** Router state after this decision: the same object when nothing changed. */
  readonly state: RoutedState;
}

export type LevelStep =
  | { readonly kind: "done"; readonly outcome: LevelOutcome }
  /** Ask the spend confirmation for `level`; `answer` gives the outcome for each reply. */
  | {
      readonly kind: "ask";
      readonly level: Level;
      readonly fallback: Level;
      readonly answer: (approved: boolean) => LevelOutcome;
    };

/**
 * Route a classified level: apply the effort offset, see what it resolves to,
 * and decide whether the spend confirmation is needed.
 *
 * The whole decision, so the shell only shows a dialog when told to. Shared by
 * the first prompt of a branch (just classified) and every later prompt (level
 * from state), because the offset — and so the need to confirm — can change
 * between prompts when the user changes effort.
 *
 * `resolve` maps a level to the level that actually resolves in this session
 * (a missing model substitutes cheaper-first). The gate applies to the
 * resolved level, so a substitution down from `hard` does not ask about a route
 * it is not taking. Without a UI (`canAsk` false) there is nobody to ask: the
 * cheaper route is taken, and no decline is recorded for a question never put.
 */
export function planLevel(input: {
  readonly state: RoutedState;
  readonly selectedEffort: string;
  readonly resolve: (level: Level) => Level;
  readonly canAsk: boolean;
}): LevelStep {
  const { state } = input;
  const requested = shiftLevel(state.level, effortOffset(input.selectedEffort));
  const resolvedLevel = input.resolve(requested);
  const base = { requested, premiumPrompted: false, state };
  const decision = premiumDecision(resolvedLevel, state);
  switch (decision.kind) {
    case "route":
      return { kind: "done", outcome: { ...base, level: resolvedLevel, declined: false } };
    case "declined":
      return { kind: "done", outcome: { ...base, level: decision.level, declined: true } };
    case "confirm":
      if (!input.canAsk) return { kind: "done", outcome: { ...base, level: decision.fallback, declined: true } };
      return {
        kind: "ask",
        level: resolvedLevel,
        fallback: decision.fallback,
        answer: (approved) => ({
          ...base,
          level: approved ? resolvedLevel : decision.fallback,
          declined: !approved,
          premiumPrompted: true,
          state: recordAnswer(state, resolvedLevel, approved),
        }),
      };
  }
}

/**
 * Narrow router state read back from a session file.
 *
 * pi stores whatever `route()` returned, so this is untrusted input: a session
 * written by another version of this extension, or edited by hand, must not reach the
 * ladder as an unknown level. Anything unrecognised — including the tier × effort
 * router's `{ tier, effort }` — means "no state", which simply re-classifies.
 */
export function parseRouterState(value: unknown): RouterState | undefined {
  if (typeof value !== "object" || value === null) return undefined;
  const record = value as Record<string, unknown>;
  const asLevel = (candidate: unknown) => LEVELS.find((level) => level === candidate);
  if (record.phase === "scouting") {
    return { phase: "scouting", ...(record.stalled === true ? { stalled: true } : {}) };
  }
  const level = asLevel(record.level);
  if (!level) return undefined;
  // Optional answers are dropped individually when malformed: losing one only
  // means being asked again, which is safe.
  const approved = asLevel(record.approved);
  const declined = asLevel(record.declined);
  return { level, ...(approved ? { approved } : {}), ...(declined ? { declined } : {}) };
}

/**
 * The text of the latest user message — what the classifier judges.
 *
 * pi hands the router post-expansion messages, so a `/skill:` prompt arrives as
 * the skill's text. `truncatePrompt` keeps that bounded.
 */
export function lastUserText(messages: readonly Message[]): string {
  for (let index = messages.length - 1; index >= 0; index--) {
    const message = messages[index];
    if (message.role !== "user") continue;
    const content = message.content;
    if (typeof content === "string") return content;
    return content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("\n");
  }
  return "";
}
