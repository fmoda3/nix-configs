# Intent Markers

Markers suppress QR checks for intentional code patterns.
\
## Format

`:MARKER: [what]; [why]`

- Semicolon separator REQUIRED
- `[what]` = specific pattern being marked
- `[why]` = rationale (invariant relied upon, safety guarantee, etc.)

## Markers

| Marker     | Purpose                          | Example                                              |
| ---------- | -------------------------------- | ---------------------------------------------------- |
| `:PERF:`   | Performance-critical intentional | `:PERF: unchecked bounds; loop invariant i<len`      |
| `:UNSAFE:` | Safety-critical intentional      | `:UNSAFE: raw pointer; caller ensures lifetime`      |
| `:SCHEMA:` | Data contract divergence         | `:SCHEMA: field unused; migration pending, rollback` |

## Validation

- Marker without semicolon or empty [why] = MARKER_INVALID (MUST)
- Valid marker = skip relevant checks for marked code
- Unmarked code = full scrutiny

## QR Behavior

QR scripts detect markers and:

1. Validate format (structural: has semicolon, non-empty why)
2. If valid: skip category checks for marked code
3. If invalid: report MARKER_INVALID (MUST severity)
