/**
 * FUNCTIONAL CORE — no I/O, no TUI.
 *
 * The routing record kept in the conversation: one `auto-router.route` custom session
 * entry per routing event, so anyone reading the session — live, after a
 * resume, or on another branch — can see how the model changed and why.
 *
 * Custom entries are persisted on the session branch but never sent to the
 * model (pi's session-format.md), so the record costs no context. It is written
 * once and rendered from its data alone, so it looks the same live and after a
 * resume. Entries are read back from session files, so `parseRouteEntry`
 * validates them like any other untrusted input; a malformed entry renders
 * nothing rather than throwing.
 *
 * Kinds:
 *   assessing  the classifier is running (first prompt of a branch, or again
 *              once a scouting branch has read its context)
 *   scouting   the prompt only pointed at its scope; reading it first
 *   routed     the classification was applied
 *   rerouted   a later prompt moved along the ladder (effort changed)
 *   skipped    classification failed or was cancelled; the fallback was used
 */

import type { AutoModelRef, Effort, Level, RouteExplanation } from "./types.ts";
import { AUTO_MODELS, EFFORTS, LEVELS } from "./types.ts";
import { adjustments, describeFailure } from "./present.ts";
import type { RoutingEvent } from "./event.ts";

/** `customType` of the entries. Namespaced so no other extension's entries collide. */
export const ROUTE_ENTRY_TYPE = "auto-router.route";

export type RouteEntry =
  | { readonly v: 1; readonly kind: "assessing"; readonly virtualModel: AutoModelRef; readonly withContext?: true }
  | {
      readonly v: 1;
      readonly kind: "scouting";
      readonly virtualModel: AutoModelRef;
      readonly route: RouteExplanation;
      /** The classifier's reason, when it flagged the prompt. */
      readonly rationale?: string;
      /** What the prompt names, when a reference triggered scouting. */
      readonly references?: readonly string[];
    }
  | {
      readonly v: 1;
      readonly kind: "routed";
      readonly virtualModel: AutoModelRef;
      readonly route: RouteExplanation;
      readonly rationale: string;
      readonly afterContext?: true;
    }
  | { readonly v: 1; readonly kind: "rerouted"; readonly virtualModel: AutoModelRef; readonly route: RouteExplanation }
  | {
      readonly v: 1;
      readonly kind: "skipped";
      readonly virtualModel: AutoModelRef;
      /** Why, in user terms (describeFailure output, or "cancelled"). */
      readonly reason: string;
      /** The fallback used instead, absent when the request was cancelled. */
      readonly fallback?: { readonly label: string; readonly effort: Effort };
    };

// ─── Construction ─────────────────────────────────────────────────────────────

export const assessingEntry = (virtualModel: AutoModelRef, withContext = false): RouteEntry => ({
  v: 1,
  kind: "assessing",
  virtualModel,
  ...(withContext ? { withContext: true as const } : {}),
});

export const scoutingEntry = (
  virtualModel: AutoModelRef,
  route: RouteExplanation,
  why: { readonly rationale: string } | { readonly references: readonly string[] },
): RouteEntry => ({ v: 1, kind: "scouting", virtualModel, route, ...why });

export const routedEntry = (
  virtualModel: AutoModelRef,
  route: RouteExplanation,
  rationale: string,
  afterContext = false,
): RouteEntry => ({
  v: 1,
  kind: "routed",
  virtualModel,
  route,
  rationale,
  ...(afterContext ? { afterContext: true as const } : {}),
});

export const reroutedEntry = (virtualModel: AutoModelRef, route: RouteExplanation): RouteEntry => ({
  v: 1,
  kind: "rerouted",
  virtualModel,
  route,
});

export const skippedEntry = (
  virtualModel: AutoModelRef,
  reason: string,
  fallback?: { readonly label: string; readonly effort: Effort },
): RouteEntry => ({ v: 1, kind: "skipped", virtualModel, reason, ...(fallback ? { fallback } : {}) });

/** The routing record for an event. */
export function toEntry(event: RoutingEvent): RouteEntry {
  switch (event.kind) {
    case "assessing":
      return assessingEntry(event.virtualModel, event.withContext);
    case "scouting":
      return scoutingEntry(
        event.virtualModel,
        event.route,
        event.scoutTrigger === "reference" ? { references: event.references } : { rationale: event.suggestion.rationale },
      );
    case "routed":
      return routedEntry(event.virtualModel, event.route, event.suggestion.rationale, event.deferred);
    case "rerouted":
      return reroutedEntry(event.virtualModel, event.route);
    case "skipped": {
      // A cancelled request is not a classifier failure; say only that.
      if (event.cancelled) return skippedEntry(event.virtualModel, "cancelled");
      const fallback = event.fallback && { label: event.fallback.label, effort: event.fallback.effort };
      return skippedEntry(event.virtualModel, describeFailure(event.failure), fallback);
    }
  }
}

// ─── Parsing (boundary) ───────────────────────────────────────────────────────

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);
const isLevel = (value: unknown): value is Level => LEVELS.some((level) => level === value);
const isEffort = (value: unknown): value is Effort => EFFORTS.some((effort) => effort === value);
const isRef = (value: unknown): value is AutoModelRef => AUTO_MODELS.some((auto) => auto.ref === value);
const isString = (value: unknown): value is string => typeof value === "string";

function parseRoute(value: unknown): RouteExplanation | undefined {
  if (!isRecord(value)) return undefined;
  const { label, level, effort, classified, requested, offset, selectedEffort, declined } = value;
  if (!isString(label) || !isLevel(level) || !isEffort(effort)) return undefined;
  if (!isLevel(classified) || !isLevel(requested)) return undefined;
  if (typeof offset !== "number" || !isString(selectedEffort) || typeof declined !== "boolean") return undefined;
  return { label, level, effort, classified, requested, offset, selectedEffort, declined };
}

/** Narrow entry data read back from a session file. */
export function parseRouteEntry(value: unknown): RouteEntry | undefined {
  if (!isRecord(value) || value.v !== 1 || !isRef(value.virtualModel)) return undefined;
  const virtualModel = value.virtualModel;
  switch (value.kind) {
    case "assessing":
      return assessingEntry(virtualModel, value.withContext === true);
    case "scouting": {
      const route = parseRoute(value.route);
      if (!route) return undefined;
      if (isString(value.rationale)) return scoutingEntry(virtualModel, route, { rationale: value.rationale });
      if (Array.isArray(value.references) && value.references.every(isString)) {
        return scoutingEntry(virtualModel, route, { references: value.references });
      }
      return undefined;
    }
    case "routed": {
      const route = parseRoute(value.route);
      return route && isString(value.rationale) ? routedEntry(virtualModel, route, value.rationale, value.afterContext === true) : undefined;
    }
    case "rerouted": {
      const route = parseRoute(value.route);
      return route ? { v: 1, kind: "rerouted", virtualModel, route } : undefined;
    }
    case "skipped": {
      if (!isString(value.reason)) return undefined;
      const fallback = value.fallback;
      const parsed =
        isRecord(fallback) && isString(fallback.label) && isEffort(fallback.effort)
          ? { label: fallback.label, effort: fallback.effort }
          : undefined;
      return skippedEntry(virtualModel, value.reason, parsed);
    }
    default:
      return undefined;
  }
}

// ─── Presentation ─────────────────────────────────────────────────────────────

/** How a block is styled: the headline's tone, and detail lines under it. */
export interface EntryView {
  /** "Auto (Claude)" — which auto model this is about. */
  readonly label: string;
  readonly tone: "pending" | "routed" | "skipped";
  readonly headline: string;
  readonly details: readonly string[];
}

const effortText = (effort: Effort) => (effort === "off" ? "no thinking" : `${effort} thinking`);
const describe = (route: { readonly label: string; readonly effort: Effort }) => `${route.label} · ${effortText(route.effort)}`;

export function entryView(entry: RouteEntry): EntryView {
  const label = AUTO_MODELS.find((auto) => auto.ref === entry.virtualModel)?.name ?? entry.virtualModel;
  switch (entry.kind) {
    case "assessing":
      return {
        label,
        tone: "pending",
        headline: entry.withContext ? "⋯ Assessing route with what was read…" : "⋯ Assessing route…",
        details: [],
      };
    case "scouting":
      return {
        label,
        tone: "pending",
        headline: `Reading context first: routed to ${describe(entry.route)} (${entry.route.level})`,
        details: [
          entry.references
            ? `The request names ${entry.references.join(", ")}; classifying once it has been read.`
            : `Why: ${entry.rationale}`,
          "(the request points to material it doesn't include; re-assessed once it has been read)",
        ],
      };
    case "routed":
      return {
        label,
        tone: "routed",
        headline: `Routed to ${describe(entry.route)} (${entry.route.level})`,
        details: [
          `Why: ${entry.rationale}`,
          ...(entry.afterContext ? ["(classified after reading the context)"] : []),
          ...adjustments(entry.route),
        ],
      };
    case "rerouted":
      return {
        label,
        tone: "routed",
        headline: `Effort ${entry.route.selectedEffort}: routed to ${describe(entry.route)} (${entry.route.level})`,
        details: adjustments(entry.route),
      };
    case "skipped":
      return {
        label,
        tone: "skipped",
        headline: `Route suggestion skipped — ${entry.reason}`,
        details: entry.fallback ? [`Using ${describe(entry.fallback)}`] : [],
      };
  }
}
