/**
 * FUNCTIONAL CORE — no I/O.
 *
 * The rung ladders: for each family, one fixed `(model, effort)` pair per
 * difficulty level, chosen from the Pareto frontier of capability against cost
 * per task on the Artificial Analysis Intelligence Index v4.3.2 — and their
 * resolution against the models actually available in this session.
 *
 * The classifier only ever emits a `Level`. Turning that into a model and an
 * effort is a separate, testable step because the two concerns change at
 * different rates: the level vocabulary is stable, while the frontier shifts
 * every time a model ships.
 *
 * Resolution rules:
 *   - Each rung pins a normalized model id; matching is anchored equality on
 *     the normalized catalogue id (see `normalizeModelId`), so dated ids
 *     resolve without an exact catalog pin.
 *   - A level whose model is unavailable degrades to another level — cheaper
 *     levels first — taking *that* level's rung, model and effort together. A
 *     rung is a pair; its effort is never grafted onto a different model.
 */

import type { Effort, Family, Level, ResolvedTarget, Rung } from "./types.ts";
import { EFFORTS, LEVELS } from "./types.ts";

/** The minimum a candidate model must look like to be matched. */
export interface AvailableModel {
  readonly provider: string;
  readonly id: string;
  /** Optional friendlier name; falls back to `id`. */
  readonly name?: string;
}

/**
 * The Claude ladder: Haiku 5.5 at the bottom, then Opus 5.5 from `medium` up.
 *
 * Haiku 5.5 took over the bottom of the frontier: every effort from `low` (29,
 * $0.02) to `max` (43, $0.21) is on it, and it dominates both former bottom
 * rungs — Haiku 4.5 (16.9, $0.28) at every effort, and Opus 5.5 `low` (42.3,
 * $0.55) by Haiku `max`, with Haiku `xhigh` 1.3 points behind at under a
 * quarter of the cost. From there Opus 5.5 `medium` to `max` is the frontier;
 * Fable 5.1 and Sonnet 5 stay dominated at every effort.
 *
 * Sonnet 5.5 is on the frontier only at `high` (46.8, $0.88), in the gap
 * between Haiku `max` and Opus `medium`, and about a point below the line
 * joining them; it gets no level, since that would mean dropping Opus `max` or
 * weakening `moderate`. Every other Sonnet 5.5 effort is beaten by a cheaper,
 * higher Haiku 5.5 or Opus 5.5 one. Haiku's provisional costs are what make
 * this close: re-check when AA prices the 100k step.
 *
 * `trivial` is Haiku `medium` (+5 over `low` for three cents), `simple` is
 * `xhigh` rather than `max`: +2 points for 1.8x the tokens, and every extra
 * token makes a request likelier to cross the 100k input step where Haiku 5.5
 * bills the whole request at 5x. AA's Haiku 5.5 costs are provisional and do
 * not yet include that step.
 *
 * Haiku 5.5 is also the Claude classifier (the `trivial` rung). Sent with no
 * reasoning option, pi-ai's anthropic-messages api turns its adaptive thinking
 * off (`thinking: {type: "disabled"}`), so the classifier tool can still be
 * forced.
 */
const CLAUDE_RUNGS: Readonly<Record<Level, Rung>> = {
  trivial: { model: "claude-haiku-5-5", effort: "medium", benchmark: { index: 34, costPerTask: 0.05 } },
  simple: { model: "claude-haiku-5-5", effort: "xhigh", benchmark: { index: 41, costPerTask: 0.12 } },
  moderate: { model: "claude-opus-5-5", effort: "medium", benchmark: { index: 51.2, costPerTask: 1.34 } },
  complex: { model: "claude-opus-5-5", effort: "high", benchmark: { index: 53.6, costPerTask: 1.82 } },
  hard: { model: "claude-opus-5-5", effort: "xhigh", benchmark: { index: 56.0, costPerTask: 3.46 } },
  extreme: { model: "claude-opus-5-5", effort: "max", benchmark: { index: 57.6, costPerTask: 5.98 } },
};

/**
 * The GPT ladder: Luna at the bottom, GPT-6.1 Sol through the middle, Astra on top.
 *
 * GPT-6.1 Sol pushed the GPT-6 frontier out at every effort: Sol 6.1 `medium`
 * beats every GPT-6 Sol point and Astra `low`; `high` beats Astra `medium`;
 * `xhigh` matches Astra `high` (index and Terminal-Bench 4.0) at under a
 * quarter of the cost. What survives around it is Luna `low`→`max` below and
 * Astra `xhigh` above (the best GPT Terminal-Bench score, 59.6%). Sol 6.1 `max`
 * is skipped: +0.8 index for 1.8× the cost of `xhigh`, and AA's Coding Agent
 * Index has `xhigh` 3 points ahead of it. Sol 6.1 `low` (42, $0.13) is on the
 * frontier but `simple` stays on Luna `max` at half the cost.
 *
 * The `openai-codex` provider declares `max` for every GPT-6 model, and pi
 * sends it as `reasoning.effort`, so every rung's effort reaches the model.
 */
const GPT_RUNGS: Readonly<Record<Level, Rung>> = {
  trivial: { model: "gpt-6-luna", effort: "medium", benchmark: { index: 29.5, costPerTask: 0.018 } },
  simple: { model: "gpt-6-luna", effort: "max", benchmark: { index: 37.3, costPerTask: 0.068 } },
  moderate: { model: "gpt-6.1-sol", effort: "medium", benchmark: { index: 48, costPerTask: 0.21 } },
  complex: { model: "gpt-6.1-sol", effort: "high", benchmark: { index: 50, costPerTask: 0.32 } },
  hard: { model: "gpt-6.1-sol", effort: "xhigh", benchmark: { index: 51, costPerTask: 0.39 } },
  extreme: { model: "gpt-6-astra", effort: "xhigh", benchmark: { index: 52.4, costPerTask: 2.31 } },
};

/** A family's rungs, one per level. */
export function laddersFor(family: Family): Readonly<Record<Level, Rung>> {
  return family === "gpt" ? GPT_RUNGS : CLAUDE_RUNGS;
}

export function rungFor(family: Family, level: Level): Rung {
  return laddersFor(family)[level];
}

/**
 * How many times a `moderate` route's cost per task a level costs, rounded to
 * one decimal. Stated in the spend confirmation, so the user is agreeing to a
 * number rather than to "premium".
 */
export function costMultiple(family: Family, level: Level): number {
  const ladder = laddersFor(family);
  return Math.round((ladder[level].benchmark.costPerTask / ladder.moderate.benchmark.costPerTask) * 10) / 10;
}

/**
 * Reduce a catalogue id to the bare model name: lower-cased, without the date
 * suffix Anthropic puts on pinned snapshots.
 *
 *   claude-haiku-4-5-20251001  ->  claude-haiku-4-5
 *   gpt-5.6-sol                ->  gpt-5.6-sol
 *
 * This is the single definition of "same model", used for both matching and
 * display, so the two cannot drift apart.
 */
export function normalizeModelId(id: string): string {
  return id.toLowerCase().replace(/-\d{8}$/, "");
}

/**
 * Is this model the pinned model?
 *
 * Anchored equality on the normalized id, not a substring test. Substring
 * matching made `claude-fable-5` satisfy a `claude-fable-5-1` pin, and would
 * equally accept `claude-opus-50` for a `claude-opus-5` pin — so a pin was not
 * really a pin. Requiring equality means a new version, major or minor, stops
 * resolving and gets bumped deliberately instead of being adopted silently
 * mid-session.
 */
function matches(model: AvailableModel, candidate: string): boolean {
  return normalizeModelId(model.id) === candidate.toLowerCase();
}

/**
 * Human-readable name for the routing record and diagnostics.
 *
 * Prefers an explicit catalogue name, else the normalized id.
 */
export function displayLabel(model: AvailableModel): string {
  if (model.name && model.name.trim() !== "") return model.name;
  return normalizeModelId(model.id);
}

function toTarget(level: Level, rung: Rung, model: AvailableModel): ResolvedTarget {
  return { level, provider: model.provider, modelId: model.id, label: displayLabel(model), effort: rung.effort };
}

/** Resolve one level, without the degradation fallback. */
export function resolveLevelStrict(
  level: Level,
  family: Family,
  available: readonly AvailableModel[],
): ResolvedTarget | undefined {
  const rung = rungFor(family, level);
  const hit = available.find((model) => matches(model, rung.model));
  return hit ? toTarget(level, rung, hit) : undefined;
}

/**
 * Resolve a level, degrading to another level that does resolve.
 *
 * **Cheaper levels are exhausted before any pricier one is considered**, so a
 * missing model can never make a route cost more than the one requested unless
 * nothing cheaper exists at all. The resolved target reports the level actually
 * used, so the routing record can be honest that it substituted.
 *
 * Returns undefined only when no rung for the family matches anything available,
 * which is the signal that the ladder is unreachable (not signed in).
 */
export function resolveLevel(
  level: Level,
  family: Family,
  available: readonly AvailableModel[],
): ResolvedTarget | undefined {
  for (const step of degradationOrder(level)) {
    const found = resolveLevelStrict(step, family, available);
    if (found) return found;
  }
  return undefined;
}

/**
 * The levels to try, in order: the requested one, then every cheaper level from
 * nearest down, then every pricier level from nearest up.
 */
export function degradationOrder(level: Level): readonly Level[] {
  const index = LEVELS.indexOf(level);
  return [level, ...LEVELS.slice(0, index).reverse(), ...LEVELS.slice(index + 1)];
}

// ─── The classifier's model ───────────────────────────────────────────────────

/** Where a classification runs. */
export interface ClassifierTarget {
  readonly provider: string;
  readonly modelId: string;
  readonly label: string;
}

/**
 * The model that runs the classifier: the family's `trivial` rung (Haiku 5.5
 * for Claude, GPT-6 Luna for GPT), degrading cheaper-first like any other
 * level — so a classifier call can never land on an expensive model and cost
 * more than the turn it is trying to optimise.
 *
 * Each family classifies on its own provider. A shared classifier would mean a
 * prompt typed into `openai-codex/auto-gpt` is sent to Anthropic (or the other
 * way round), and would need both logins to work.
 */
export function resolveClassifierModel(family: Family, available: readonly AvailableModel[]): ClassifierTarget | undefined {
  const rung = resolveLevel("trivial", family, available);
  return rung && { provider: rung.provider, modelId: rung.modelId, label: rung.label };
}

// ─── Effort capability ────────────────────────────────────────────────────

/**
 * The effort levels a model actually supports.
 *
 * This is not cosmetic. Support genuinely varies across the catalogue:
 *
 *   claude-haiku-5-5    off, low → max      (`minimal` disabled)
 *   claude-opus-5-5     low → max           (`off` and `minimal` disabled)
 *   gpt-6-luna          off → max
 *   gpt-6.1-sol         minimal → max       (`off` is explicitly disabled)
 *   gpt-6-astra         minimal → max       (`off` is explicitly disabled)
 *
 * Applying an unsupported level is worse than merely useless: pi's
 * `clampThinkingLevel` silently walks the request to the nearest supported
 * level, so the routing record would promise one level while the request ran at
 * another. Clamping up front keeps the announced and applied levels identical. Every
 * rung's effort is declared by its model today, so this is a safety net.
 *
 * `levels` is the model's declared support (pi-ai's `getSupportedThinkingLevels`
 * output); it is passed in rather than computed here to keep this module free of
 * pi-ai imports and trivially testable.
 */
export function supportedEfforts(levels: readonly string[]): readonly Effort[] {
  const declared = new Set(levels);
  const usable = EFFORTS.filter((effort) => declared.has(effort));
  // A non-reasoning model reports only ["off"], and a model whose declaration we
  // cannot read at all should still be routable: fall back to the one level
  // every model can honour rather than offering an empty list.
  return usable.length > 0 ? usable : ["off"];
}

/**
 * Coerce a requested effort onto the nearest level a model supports.
 *
 * Mirrors pi-ai's clamp direction deliberately — prefer stepping *up* to the
 * next supported level, then fall back to stepping down — so that what the
 * router displays is what pi will actually apply. Diverging here would
 * reintroduce exactly the silent mismatch this function exists to prevent.
 */
export function clampEffort(requested: Effort, supported: readonly Effort[]): Effort {
  if (supported.includes(requested)) return requested;
  const index = EFFORTS.indexOf(requested);
  for (let i = index + 1; i < EFFORTS.length; i++) {
    const candidate = EFFORTS[i];
    if (supported.includes(candidate)) return candidate;
  }
  for (let i = index - 1; i >= 0; i--) {
    const candidate = EFFORTS[i];
    if (supported.includes(candidate)) return candidate;
  }
  return supported[0] ?? "off";
}
