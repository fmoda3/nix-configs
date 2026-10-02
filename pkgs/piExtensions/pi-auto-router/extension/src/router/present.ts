/**
 * FUNCTIONAL CORE — no I/O.
 *
 * User-facing text for the auto virtual models: how a route was
 * adjusted, the spend confirmation, and classification failures. The routing
 * record in the conversation (src/router/entry.ts) is built from these.
 *
 * Returned as data rather than shown here so the dialogs stay in the shell and
 * the wording stays testable.
 */

import type { ClassifyFailure, Effort, Family, ResolvedTarget, RouteExplanation } from "./types.ts";
import { isPremiumLevel, providerFor } from "./types.ts";

function effortLabel(effort: Effort): string {
  return effort === "off" ? "no thinking" : `${effort} thinking`;
}

/** "claude-sonnet-4-5 · medium thinking" */
export function describeRoute(target: ResolvedTarget, effort: Effort): string {
  return `${target.label} · ${effortLabel(effort)}`;
}

/** "+1 for high effort", "−2 for minimal effort", or "" when effort did not move it. */
function describeOffset(offset: number, selectedEffort: string): string {
  if (offset === 0) return "";
  return `${offset > 0 ? "+" : "−"}${Math.abs(offset)} for ${selectedEffort} effort`;
}

/** Lines explaining how the route differs from what the classifier chose. */
export function adjustments(route: RouteExplanation): string[] {
  const lines: string[] = [];
  const offset = describeOffset(route.offset, route.selectedEffort);
  if (offset !== "" && route.requested !== route.classified) {
    lines.push(`(classified ${route.classified}; ${offset} → ${route.requested})`);
  }
  if (route.declined) {
    lines.push(`(${route.requested} not approved; using the ${route.level} route)`);
  } else if (route.level !== route.requested) {
    lines.push(`(the ${route.requested} route's model is not available here; using the ${route.level} route)`);
  }
  return lines;
}

/**
 * Confirmation copy for an expensive route.
 *
 * `undefined` means no confirmation is required, which keeps the "does this
 * need a second step" rule in one place. `costMultiple` is the route's cost per
 * task relative to a `moderate` one, so the user agrees to a number rather than
 * to "premium". `declined` names the route taken on "no", because with a
 * virtual model there is no "keep current": declining has to route somewhere,
 * and the user should know where before answering.
 */
export function confirmPrompt(
  target: ResolvedTarget,
  effort: Effort,
  costMultiple: number,
  declined: { readonly target: ResolvedTarget; readonly effort: Effort },
): { readonly title: string; readonly message: string } | undefined {
  if (!isPremiumLevel(target.level)) return undefined;
  return {
    title: `Use ${describeRoute(target, effort)}?`,
    message:
      `The ${target.level} route costs about ${costMultiple}× a moderate one per task. ` +
      `Route this session to ${describeRoute(target, effort)}? ` +
      `Declining routes to ${describeRoute(declined.target, declined.effort)} instead.`,
  };
}

/**
 * A one-line, length-capped rendering of a raw model reply for display.
 *
 * Newlines are collapsed because the reply is shown inside the routing record: a
 * markdown report pasted verbatim would flood the pane and bury the message.
 */
export function previewRaw(raw: string, limit = 300): string {
  const flat = raw.replace(/\s+/g, " ").trim();
  return flat.length <= limit ? flat : `${flat.slice(0, limit)}…`;
}

/**
 * Why nothing on a family's ladder can be used — the message for both a
 * classifier with no model to run on and a route with no model to go to.
 *
 * It carries the cause rather than a bare statement, because the obvious
 * reading of it is wrong: every rung of a ladder is served by one provider
 * (`anthropic` or `openai-codex`), so they all disappear whenever that provider
 * has no credential. Without the hint it reads as a router bug or a ladder gap.
 */
export function ladderUnavailable(family: Family): string {
  const provider = providerFor(family);
  return `no ${family} model available — the ${family} ladder is served by the ${provider} provider; sign in with "/login ${provider}"`;
}

/** User-facing text for a classification failure. */
export function describeFailure(failure: ClassifyFailure): string {
  switch (failure.kind) {
    case "no-classifier-model":
      return ladderUnavailable(failure.family);
    case "no-tool-call":
      // The reply is the diagnosis, so it is shown inline.
      return `classifier did not call the tool (stopReason: ${failure.stopReason})\n  reply: ${previewRaw(failure.raw)}`;
    case "invalid-fields":
      return `classifier returned unusable fields: ${failure.detail}`;
    case "provider-error":
      return `classifier call failed: ${failure.message}`;
    case "timeout":
      return `classifier timed out after ${failure.ms}ms`;
  }
}
