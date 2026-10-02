/**
 * FUNCTIONAL CORE — no I/O.
 *
 * Explicit references in a prompt to material that defines its task: a
 * document, a URL, a ticket, an issue. A prompt that names one scouts first
 * (read it, then classify with it) without asking the classifier, because the
 * classifier's `needs_context` flag proved unreliable on exactly these prompts:
 * Haiku flagged "look at .pi/feature-ideas.md and see what's left to implement"
 * one time in three. A pattern is deterministic — the same prompt always
 * behaves the same — and a false positive only costs one scouting step.
 *
 * Deliberately conservative about what counts:
 *
 *   - Documents by extension (`.md`, `.txt`, `.pdf`, …), not code files. A
 *     request that names `src/auth.ts` describes its own task; reading code is
 *     the agent's normal work, not context the router waits for.
 *   - Ticket keys like `PROJ-1234`, excluding common non-ticket tokens that
 *     share the shape (`UTF-8`, `SHA-256`, `GPT-6`, …).
 *   - Issue and PR references only when unambiguous: `org/repo#812`, or
 *     `#812` right after "issue", "PR" or "pull request".
 *   - Any http(s) URL.
 *
 * The references are for the conversation record only.
 */

/** Extensions of documents that define work, as opposed to code the agent edits. */
const DOCUMENT_EXTENSIONS = ["md", "mdx", "markdown", "txt", "rst", "adoc", "org", "pdf", "log", "html", "htm"];

/** Tokens shaped like ticket keys that are not tickets. */
const NOT_TICKETS = new Set([
  "UTF", "ISO", "SHA", "MD", "AES", "RSA", "HTTP", "TLS", "SSL", "IPV", "UTC", "GMT", "GPT", "COVID",
  "CVE", "RFC", "ECMA", "ES", "IEEE", "ASCII", "BASE", "INT", "UINT", "FLOAT", "X", "H", "P",
]);

const URL = /\bhttps?:\/\/[^\s<>()"'`]+/g;
const TICKET = /\b([A-Z][A-Z0-9]{1,9})-(\d+)\b/g;
const REPO_ISSUE = /\b[\w.-]+\/[\w.-]+#\d+\b/g;
const WORDED_ISSUE = /\b(?:issue|pr|pull request)\s+#(\d+)\b/gi;
const DOCUMENT = new RegExp(String.raw`(?:^|[\s(\["'\`@])((?:[\w.~-]*\/)*[\w.-]*\.(?:${DOCUMENT_EXTENSIONS.join("|")}))(?=$|[\s)\]"'\`,;:!?])`, "gi");

/** Trailing punctuation a sentence adds after a URL. */
const trimUrl = (url: string) => url.replace(/[.,;:!?]+$/, "");

/**
 * The references a prompt makes, in order of appearance, deduplicated. Empty
 * when the prompt is self-contained.
 */
export function findReferences(prompt: string): readonly string[] {
  const found: { index: number; text: string }[] = [];
  const urls: { start: number; end: number }[] = [];
  for (const match of prompt.matchAll(URL)) {
    const text = trimUrl(match[0]);
    found.push({ index: match.index, text });
    urls.push({ start: match.index, end: match.index + match[0].length });
  }
  // Paths inside a URL are part of the URL, not a separate document reference.
  const insideUrl = (index: number) => urls.some((url) => index >= url.start && index < url.end);

  for (const match of prompt.matchAll(TICKET)) {
    if (insideUrl(match.index) || NOT_TICKETS.has(match[1])) continue;
    found.push({ index: match.index, text: match[0] });
  }
  for (const match of prompt.matchAll(REPO_ISSUE)) {
    if (!insideUrl(match.index)) found.push({ index: match.index, text: match[0] });
  }
  for (const match of prompt.matchAll(WORDED_ISSUE)) found.push({ index: match.index, text: `#${match[1]}` });
  for (const match of prompt.matchAll(DOCUMENT)) {
    const start = match.index + match[0].indexOf(match[1]);
    if (!insideUrl(start)) found.push({ index: start, text: match[1] });
  }

  const seen = new Set<string>();
  return found
    .sort((a, b) => a.index - b.index)
    .map((reference) => reference.text)
    .filter((text) => (seen.has(text) ? false : (seen.add(text), true)));
}
