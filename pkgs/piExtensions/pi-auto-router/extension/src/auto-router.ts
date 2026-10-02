/**
 * Auto-routing virtual models — `anthropic/auto-claude` and `openai-codex/auto-gpt`.
 *
 * Selecting one of these models *is* the opt-in to routing: there is no
 * setting, no family option and no picker. Each registers a pi virtual model
 * (see pi's docs/virtual-models.md) whose `route()` picks a physical model on
 * the matching ladder for every request. Each is listed under the provider
 * that serves its ladder, so pi offers it exactly when you are signed in there.
 *
 * On the first user prompt of a branch, the prompt is classified with a small
 * fast model into a difficulty level, the level is resolved to its fixed
 * `(model, effort)` rung on the family's Pareto-frontier ladder
 * (src/router/ladder.ts), and the level is stored as router
 * state on the branch. Every later request on that branch reuses it, so the
 * classifier runs once per branch and the prompt cache stays warm. Tool
 * follow-ups and retries stick to the model that handled the turn.
 *
 * The auto models' thinking level is an offset on the classified level —
 * `medium` routes as classified, `high` one level up, `minimal` two down — and
 * is re-applied on every user prompt, so changing it mid-session moves the next
 * prompt along the ladder without re-classifying.
 *
 * Every routing event is recorded in the conversation as an `auto-router.route` custom
 * session entry (src/router/entry.ts): "assessing", then "routed" or "skipped"
 * on classification, and "rerouted" when a later prompt moves. Entries persist
 * on the branch and render after a resume, but never reach the model.
 *
 * This file is the imperative shell: it owns the classifier call, the spend
 * confirmation and pi wiring. Every decision is made by pure functions in
 * src/router/ — route planning, ladder resolution, response validation, copy.
 *
 * Design constraints worth knowing before changing this:
 *
 *   - Suggestions are applied without a picker, because the user opted in by
 *     selecting an auto model and there is no "keep current" for a virtual
 *     model. The one exception is spend: the `hard` and `extreme` levels still
 *     ask — whether the classifier or an effort offset put the route there —
 *     and declining routes to `complex` (`premiumDecision`). Each answer is
 *     remembered on the branch, so a session is asked once, not every prompt.
 *     Without a UI to ask on, the cheaper route is taken.
 *   - A classifier failure routes to the default level and stores no state, so
 *     the next user prompt tries again. A classifier outage must never cost the
 *     user their prompt.
 *   - A ladder that resolves to nothing throws: pi turns that into an error
 *     response naming the cause, which is better than a silent wrong model.
 */

import type { ExtensionAPI, ExtensionContext, ModelRoute, ModelRouteRequest } from "@earendil-works/pi-coding-agent";
import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import type { Api, Model } from "@earendil-works/pi-ai";
import { availableModels, runClassifier } from "./router/classifier-call.ts";
import { ROUTE_ENTRY_TYPE, toEntry } from "./router/entry.ts";
import { findReferences } from "./router/references.ts";
import { isReroute, type RoutingEvent } from "./router/event.ts";
import {
  clampEffort,
  costMultiple,
  resolveLevel,
  rungFor,
  supportedEfforts,
} from "./router/ladder.ts";
import {
  VIRTUAL_EFFORTS,
  contextExcerpt,
  effortOffset,
  fallbackLevel,
  hasNewContext,
  lastUserText,
  parseRouterState,
  planLevel,
  planRoute,
  scoutLevel,
  shiftLevel,
  type LevelOutcome,
} from "./router/plan.ts";
import { confirmPrompt, ladderUnavailable } from "./router/present.ts";
import { renderRouteEntry } from "./router/render.ts";
import type {
  AutoModel,
  Effort,
  Family,
  Level,
  ResolvedTarget,
  RouteExplanation,
  RoutedState,
  RouterState,
  ScoutingState,
  Suggestion,
} from "./router/types.ts";
import { AUTO_MODELS, isScouting } from "./router/types.ts";


/** A level resolved to a concrete physical model and a clamped effort. */
interface ResolvedRoute {
  readonly target: ResolvedTarget;
  readonly effort: Effort;
  readonly model: Model<Api>;
}

export function registerAutoRouter(pi: ExtensionAPI) {
  /**
   * Record a routing event in the conversation: a custom session entry,
   * persisted on the branch and never sent to the model. Best-effort — the
   * record must never cost the user their turn.
   */
  const emit = (event: RoutingEvent) => {
    try {
      pi.appendEntry(ROUTE_ENTRY_TYPE, toEntry(event));
    } catch {
      // Intentionally ignored: the record is informational.
    }
  };

  pi.registerEntryRenderer(ROUTE_ENTRY_TYPE, (entry, _options, theme) => renderRouteEntry(entry.data, theme));

  // ─── Routing ────────────────────────────────────────────────────────────────

  /**
   * Resolve a level to its rung's physical model and effort.
   *
   * Throws when the ladder resolves nothing at all: pi turns a throwing
   * `route()` into an error response, and the message names the likely cause
   * (not signed in to the ladder's provider).
   */
  const resolveRoute = (ctx: ExtensionContext, family: Family, level: Level): ResolvedRoute => {
    const target = resolveLevel(level, family, availableModels(ctx, family));
    const model = target && ctx.modelRegistry.find(target.provider, target.modelId);
    if (!target || !model) throw new Error(ladderUnavailable(family));
    // Clamp before anything is shown or recorded. Every rung's effort is
    // declared by its model today, but pi clamps silently when the request is
    // sent, so a catalog change would otherwise leave the routing record
    // promising a level the request never ran at.
    const effort = clampEffort(target.effort, supportedEfforts(effortsFor(model)));
    return { target, effort, model };
  };

  const toModelRoute = (resolved: ResolvedRoute, state?: RouterState): ModelRoute<RouterState> => ({
    model: resolved.model,
    thinkingLevel: resolved.effort,
    ...(state ? { state } : {}),
  });

  /**
   * Carry out `planLevel`: show the spend confirmation if it asks, then resolve
   * the outcome to a physical model. The decision itself is pure (src/router/plan.ts).
   */
  const routeLevel = async (
    family: Family,
    ctx: ExtensionContext,
    state: RoutedState,
    selectedEffort: string,
  ): Promise<LevelOutcome & { chosen: ResolvedRoute }> => {
    const step = planLevel({
      state,
      selectedEffort,
      resolve: (level) => resolveRoute(ctx, family, level).target.level,
      canAsk: ctx.hasUI,
    });
    let outcome: LevelOutcome;
    if (step.kind === "ask") {
      const premium = resolveRoute(ctx, family, step.level);
      const fallback = resolveRoute(ctx, family, step.fallback);
      const prompt = confirmPrompt(premium.target, premium.effort, costMultiple(family, step.level), fallback)!;
      outcome = step.answer(await ctx.ui.confirm(prompt.title, prompt.message));
    } else {
      outcome = step.outcome;
    }
    return { ...outcome, chosen: resolveRoute(ctx, family, outcome.level) };
  };

  /** The explanation the routing record renders. */
  const explain = (
    routed: { chosen: ResolvedRoute; requested: Level; declined: boolean },
    classified: Level,
    selectedEffort: string,
  ): RouteExplanation => ({
    label: routed.chosen.target.label,
    level: routed.chosen.target.level,
    effort: routed.chosen.effort,
    classified,
    requested: routed.requested,
    offset: effortOffset(selectedEffort),
    selectedEffort,
    declined: routed.declined,
  });

  /** The fallback route: `moderate` shifted by effort, never premium. */
  const fallbackRoute = (ctx: ExtensionContext, family: Family, selectedEffort: string) =>
    resolveRoute(ctx, family, fallbackLevel(effortOffset(selectedEffort)));

  /**
   * Classify and route: the first user prompt of a branch, a new prompt on a
   * scouting branch, or — `withContext` — a scouting branch's deferred
   * classification, made with what the agent has read since the prompt.
   */
  const classifyAndRoute = async (
    auto: AutoModel,
    request: ModelRouteRequest<RouterState>,
    ctx: ExtensionContext,
    withContext: boolean,
    scouting: ScoutingState | undefined,
  ): Promise<ModelRoute<RouterState>> => {
    const { family, ref: virtualModel } = auto;
    const selectedEffort = String(request.thinkingLevel);
    const offset = effortOffset(selectedEffort);
    const prompt = lastUserText(request.messages);
    if (prompt.trim() === "") return toModelRoute(fallbackRoute(ctx, family, selectedEffort));
    const context = withContext ? contextExcerpt(request.messages) : undefined;

    /** Route to the scout rung while the agent reads what the prompt points to. */
    const scout = (why: { scoutTrigger: "reference"; references: readonly string[] } | { scoutTrigger: "classifier"; suggestion: Suggestion }) => {
      const resolved = resolveRoute(ctx, family, scoutLevel(offset));
      emit({
        virtualModel,
        ...why,
        kind: "scouting",
        route: {
          label: resolved.target.label,
          level: resolved.target.level,
          effort: resolved.effort,
          // The scout rung is not a classification, so nothing to adjust from.
          classified: resolved.target.level,
          requested: resolved.target.level,
          offset,
          selectedEffort,
          declined: false,
        },
      });
      const state: ScoutingState = { phase: "scouting" };
      return toModelRoute(resolved, state);
    };

    // The prompt names what defines its task — a document, URL, ticket or
    // issue. Read it first; the one classification comes after, with it. No
    // classifier call here: the pattern is deterministic where the
    // classifier's own flag was not (src/router/references.ts).
    if (!withContext) {
      const references = findReferences(prompt);
      if (references.length > 0) return scout({ scoutTrigger: "reference", references });
    }

    // Shown in the conversation rather than on pi's working loader, so the
    // record of the session says a classification happened here, not only its
    // outcome. The outcome follows as its own entry.
    emit({ virtualModel, kind: "assessing", withContext });
    const outcome = await runClassifier(ctx, prompt, family, request.signal, context);

    if (!outcome.ok) {
      const fallback = fallbackRoute(ctx, family, selectedEffort);
      emit({
        virtualModel,
        kind: "skipped",
        failure: outcome.failure,
        cancelled: request.signal?.aborted === true,
        fallback: { label: fallback.target.label, effort: fallback.effort },
      });
      // A failed first classification stores nothing, so the next user prompt
      // tries again. A failed deferred one marks the scouting branch stalled,
      // so the rest of this turn does not retry on every tool round; the next
      // user prompt still classifies afresh.
      return toModelRoute(fallback, withContext && scouting ? { ...scouting, stalled: true } : undefined);
    }

    const { suggestion } = outcome;

    // The classifier says the prompt only points at its scope, in a way no
    // pattern caught ("the ticket we discussed"). Once context has been read,
    // its answer is taken as final whatever `needs_context` says.
    if (suggestion.needsContext && !withContext) {
      return scout({ scoutTrigger: "classifier", suggestion });
    }

    const routed = await routeLevel(family, ctx, { level: suggestion.level }, selectedEffort);
    emit({
      virtualModel,
      kind: "routed",
      deferred: withContext,
      suggestion,
      route: explain(routed, suggestion.level, selectedEffort),
    });
    // The classified level is stored, not the shifted one: the offset is
    // re-applied from whatever effort is selected on each later prompt.
    return toModelRoute(routed.chosen, routed.state);
  };

  /**
   * A later prompt on a branch that already has a level. Usually a no-op
   * re-resolution; when the user has changed effort it moves along the ladder,
   * possibly into a premium level that needs confirming.
   */
  const routeFromState = async (
    auto: AutoModel,
    request: ModelRouteRequest<RouterState>,
    ctx: ExtensionContext,
    state: RoutedState,
  ): Promise<ModelRoute<RouterState>> => {
    const { family } = auto;
    const selectedEffort = String(request.thinkingLevel);
    const routed = await routeLevel(family, ctx, state, selectedEffort);
    const previous = request.previous;
    if (
      isReroute({
        previous: previous && { modelId: previous.model.id, effort: previous.thinkingLevel },
        chosen: { modelId: routed.chosen.model.id, effort: routed.chosen.effort },
        premiumPrompted: routed.premiumPrompted,
      })
    ) {
      emit({ virtualModel: auto.ref, kind: "rerouted", route: explain(routed, state.level, selectedEffort) });
    }
    return toModelRoute(routed.chosen, routed.state === state ? undefined : routed.state);
  };

  const route = async (
    auto: AutoModel,
    request: ModelRouteRequest<RouterState>,
    ctx: ExtensionContext,
  ): Promise<ModelRoute<RouterState>> => {
    const { family } = auto;
    const state = parseRouterState(request.state);
    const scouting = state && isScouting(state) ? state : undefined;
    const offset = effortOffset(String(request.thinkingLevel));
    const plan = planRoute({
      reason: request.reason,
      previous: request.previous,
      failed: request.failed,
      state,
      hasNewContext: hasNewContext(request.messages),
    });
    switch (plan.kind) {
      case "sticky":
        // Same model, same level: keeps the prompt cache and thinking
        // signatures valid across tool follow-ups and retries. A changed effort
        // takes effect on the next user prompt, not mid-turn.
        // pi records the level on every agent-loop response; when one has none
        // (a legacy or unmanaged response), fall back to the branch's rung
        // effort, clamped to the sticky model like every other route — it may
        // be a substitute or a model from before the auto model was selected.
        return {
          model: plan.choice.model,
          thinkingLevel:
            plan.choice.thinkingLevel ??
            clampEffort(
              rungFor(
                family,
                !state ? fallbackLevel(offset) : isScouting(state) ? scoutLevel(offset) : shiftLevel(state.level, offset),
              ).effort,
              supportedEfforts(effortsFor(plan.choice.model)),
            ),
        };
      case "state":
        return routeFromState(auto, request, ctx, plan.state);
      case "default":
        return toModelRoute(fallbackRoute(ctx, family, String(request.thinkingLevel)));
      case "scout":
        return toModelRoute(resolveRoute(ctx, family, scoutLevel(offset)));
      case "classify":
        return classifyAndRoute(auto, request, ctx, plan.withContext, scouting);
    }
  };

  for (const auto of AUTO_MODELS) {
    pi.registerVirtualModel<RouterState>({
      // Listed under the provider that serves its ladder, so pi offers it
      // exactly when that provider has credentials.
      provider: auto.provider,
      id: auto.id,
      name: auto.name,
      // The thinking level offsets the classified level: medium routes as
      // classified, each step either side moves one level (src/router/plan.ts).
      thinkingLevels: VIRTUAL_EFFORTS,
      route: (request, ctx) => route(auto, request, ctx),
    });
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * The effort levels a model declares support for, as raw strings.
 *
 * Delegates to pi-ai's `getSupportedThinkingLevels` so the router's idea of
 * "supported" cannot drift from pi's.
 */
function effortsFor(model: Model<Api>): readonly string[] {
  try {
    return getSupportedThinkingLevels(model);
  } catch {
    return [];
  }
}
