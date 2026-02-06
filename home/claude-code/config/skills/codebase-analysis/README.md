# Analyze

Before you plan anything non-trivial, you need to actually understand the
codebase. Not impressions -- evidence. The analyze skill forces systematic
investigation with structured phases and explicit evidence requirements.

| Phase                  | Actions                                                                        |
| ---------------------- | ------------------------------------------------------------------------------ |
| Exploration            | Delegate to Explore agent; process structure, tech stack, patterns             |
| Focus Selection        | Classify areas (architecture, performance, security, quality); assign P1/P2/P3 |
| Investigation Planning | Commit to specific files and questions; create accountability contract         |
| Deep Analysis          | Progressive investigation; document with file:line + quoted code               |
| Verification           | Audit completeness; ensure all commitments addressed                           |
| Synthesis              | Consolidate by severity; provide prioritized recommendations                   |

## When to Use

Four scenarios where this matters:

- **Unfamiliar codebase** -- You cannot plan what you do not understand. Period.
- **Security review** -- Vulnerability assessment requires systematic coverage,
  not "I looked around and it seems fine."
- **Performance analysis** -- Before optimization, know where time actually
  goes, not where you assume it goes.
- **Architecture evaluation** -- Major refactors deserve evidence-backed
  understanding, not vibes.

## When to Skip

Not everything needs this level of rigor:

- You already understand the codebase well
- Simple bug fix with obvious scope
- User has provided comprehensive context

The astute reader will notice all three skip conditions share a trait: you
already have the evidence. The skill exists for when you do not.

## Example Usage

```
Use your analyze skill to understand this codebase.
Focus on security and architecture before we plan the authentication refactor.
```

The skill outputs findings organized by severity (CRITICAL/HIGH/MEDIUM/LOW),
each with file:line references and quoted code. This feeds directly into
planning -- you have evidence-backed understanding before proposing changes.
