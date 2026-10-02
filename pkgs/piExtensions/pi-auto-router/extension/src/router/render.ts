/**
 * The routing record's look in the transcript: thin TUI code over the pure
 * view in src/router/entry.ts, like src/footer/render.ts is for the footer.
 */

import type { Theme } from "@earendil-works/pi-coding-agent";
import { Box, Text, type Component } from "@earendil-works/pi-tui";
import { entryView, parseRouteEntry } from "./entry.ts";

/**
 * Draw a routing record as a block in the transcript.
 *
 * Styled like pi's own custom messages (label + body on the custom-message
 * background) so it reads as a system note rather than something the model or
 * the user said. Renders nothing for data that does not validate: a record
 * written by another version must not break the transcript.
 */
export function renderRouteEntry(data: unknown, theme: Theme): Component | undefined {
  const entry = parseRouteEntry(data);
  if (!entry) return undefined;
  const view = entryView(entry);
  const headline =
    view.tone === "pending" ? theme.fg("muted", view.headline) : view.tone === "skipped" ? theme.fg("warning", view.headline) : theme.fg("accent", view.headline);
  const box = new Box(1, 0, (text) => theme.bg("customMessageBg", text));
  box.addChild(new Text(`${theme.fg("customMessageLabel", theme.bold(`[${view.label}]`))} ${headline}`, 0, 0));
  for (const line of view.details) box.addChild(new Text(theme.fg("dim", line), 0, 0));
  return box;
}

