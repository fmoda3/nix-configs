# Claude Prompt Engineering: Structure Techniques

**Source:** Anthropic Documentation (docs.anthropic.com)

---

## XML Tag Patterns

XML tags serve three functions in Claude prompts: separation, reference, and
instruction.

### Separation

Prevent Claude from conflating instructions with data by wrapping user content:

```xml
<data>{{RAW_INPUT}}</data>
<instructions>Analyze the data above...</instructions>
```

### Reference

Name tags descriptively, then reference them in natural language:

```xml
Using the contract in <contract> tags, identify indemnification clauses.
<contract>{{CONTRACT_TEXT}}</contract>
```

### Instruction-as-Tag

The tag name itself commands action (progressive disclosure pattern):

```xml
<prioritize_security_over_convenience>
When trade-offs arise between security and UX, choose security.
Document the trade-off in comments.
</prioritize_security_over_convenience>
```

Tag name states the rule; contents elaborate.

---

## Prefill Technique

Prefill the assistant response to bypass preamble and enforce structure:

```
User: Classify this feedback: {{TEXT}}
Assistant: {"sentiment":"
```

Claude continues from the prefill, maintaining the JSON structure. This
eliminates "Here's my analysis:" preambles and forces immediate structured
output.

**Use cases:**

- Force JSON/XML output without preamble
- Start enumerated lists mid-flow
- Continue partial code blocks
- Enforce specific response formats

---

## Specificity Over Abstraction

Concrete parameters outperform vague guidance:

| Vague                           | Concrete                                                  |
| ------------------------------- | --------------------------------------------------------- |
| "use clear variable names"      | "use snake_case, 2-4 words, noun for data, verb for functions" |
| "be concise"                    | "max 3 sentences per explanation, no preamble"            |
| "handle errors appropriately"   | "on error: log to stderr, return null, never throw"       |

Quantify constraints whenever possible: word counts, format specifications,
explicit behavioral rules.

---

## Contrastive Format Rules

Show what NOT to do before what TO do:

```xml
<formatting_rules>
WRONG: "Here's what I found:" followed by unstructured prose
RIGHT: Structured output matching the requested schema, no preamble

WRONG: {"items": ["thing 1", "thing 2"]} with made-up data
RIGHT: {"items": []} when no items found -- empty, not fabricated
</formatting_rules>
```

This leverages contrastive learning: invalid demonstrations alongside valid ones
improve output accuracy.
