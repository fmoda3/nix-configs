/**
 * FUNCTIONAL CORE — no I/O.
 *
 * One routing event per thing that happened to a branch's route. The shell
 * produces an event and `toEntry` (src/router/entry.ts) turns it into the
 * routing record kept in the conversation.
 */

import type { AutoModelRef, ClassifyFailure, Effort, RouteExplanation, Suggestion } from "./types.ts";

export type RoutingEvent =
  /**
   * The classifier started: on the first prompt of a branch, or — `withContext`
   * — again once a scouting branch's agent has read something.
   */
  | { readonly virtualModel: AutoModelRef; readonly kind: "assessing"; readonly withContext: boolean }
  /**
   * The prompt only pointed at its scope, so the branch is scouting: routed to
   * the scout rung until the agent has read the material, then re-assessed.
   * Either the prompt names what to read (`references`, found by pattern, no
   * classifier call) or the classifier flagged it (`suggestion`).
   */
  | ({ readonly virtualModel: AutoModelRef; readonly kind: "scouting"; readonly route: RouteExplanation } & (
      | { readonly scoutTrigger: "reference"; readonly references: readonly string[] }
      | { readonly scoutTrigger: "classifier"; readonly suggestion: Suggestion }
    ))
  /** A classification was applied. */
  | {
      readonly virtualModel: AutoModelRef;
      readonly kind: "routed";
      /** Classified after scouting, with what the agent had read. */
      readonly deferred: boolean;
      readonly suggestion: Suggestion;
      readonly route: RouteExplanation;
    }
  /**
   * A later prompt was routed differently, or put through the spend
   * confirmation, because the selected effort changed.
   */
  | { readonly virtualModel: AutoModelRef; readonly kind: "rerouted"; readonly route: RouteExplanation }
  /** Classification failed or was cancelled; the fallback (if any) was used. */
  | {
      readonly virtualModel: AutoModelRef;
      readonly kind: "skipped";
      readonly failure: ClassifyFailure;
      readonly cancelled: boolean;
      /** The route used instead; absent when the request was cancelled. */
      readonly fallback?: { readonly label: string; readonly effort: Effort };
    };

/**
 * Whether a later prompt's routing is worth recording: it moved to a different
 * model or effort, or it asked the spend confirmation. An unchanged route is
 * the common case and stays silent.
 */
export function isReroute(input: {
  readonly previous: { readonly modelId: string; readonly effort: string | undefined } | undefined;
  readonly chosen: { readonly modelId: string; readonly effort: string };
  readonly premiumPrompted: boolean;
}): boolean {
  if (input.premiumPrompted) return true;
  const { previous, chosen } = input;
  if (!previous) return false;
  return previous.modelId !== chosen.modelId || (previous.effort ?? chosen.effort) !== chosen.effort;
}
