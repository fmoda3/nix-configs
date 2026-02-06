# Planner

LLM-generated plans have gaps. I have seen missing error handling, vague
acceptance criteria, specs that nobody can implement. I built this skill with
two workflows -- planning and execution -- connected by quality gates that catch
these problems early.

**Authoritative specification**: See INTENT.md for complete design rationale, invariants, and state file schemas. This README provides operational overview; INTENT.md is the source of truth for architectural decisions.

## Planning Workflow

```
  Planning ----+
      |        |
      v        |
     QR -------+  [fail: restart planning]
      |
      v
     TW -------+
      |        |
      v        |
   QR-Docs ----+  [fail: restart TW]
      |
      v
   APPROVED
```

| Step                    | Actions                                                                    |
| ----------------------- | -------------------------------------------------------------------------- |
| Context & Scope         | Confirm path, define scope, identify approaches, list constraints          |
| Decision & Architecture | Evaluate approaches, select with reasoning, diagram, break into milestones |
| Refinement              | Document risks, add uncertainty flags, specify paths and criteria          |
| Final Verification      | Verify completeness, check specs, write to file                            |
| QR-Completeness         | Verify Decision Log complete, policy defaults confirmed, plan structure    |
| QR-Code                 | Read codebase, verify diff context, apply RULE 0/1/2 to proposed code      |
| Technical Writer        | Scrub temporal comments, add WHY comments, enrich rationale                |
| QR-Docs                 | Verify no temporal contamination, comments explain WHY not WHAT            |

So, why all the feedback loops? QR-Completeness and QR-Code run before TW to
catch structural issues early. QR-Docs runs after TW to validate documentation
quality. Doc issues restart only TW; structure issues restart planning. The loop
runs until both pass.

## Execution Workflow

```
  Plan --> Milestones --> QR --> Docs --> Retrospective
               ^          |
               +- [fail] -+

  * Reconciliation phase precedes Milestones when resuming partial work
```

After planning completes and context clears (`/clear`), execution proceeds:

| Step                   | Purpose                                                         |
| ---------------------- | --------------------------------------------------------------- |
| Execution Planning     | Analyze plan, detect reconciliation signals, output strategy    |
| Reconciliation         | (conditional) Validate existing code against plan               |
| Milestone Execution    | Delegate to agents, run tests; repeat until all complete        |
| Post-Implementation QR | Quality review of implemented code                              |
| Issue Resolution       | (conditional) Present issues, collect decisions, delegate fixes |
| Documentation          | Technical writer updates CLAUDE.md/README.md                    |
| Retrospective          | Present execution summary                                       |

I designed the coordinator to never write code directly -- it delegates to
developers. Separating coordination from implementation produces cleaner
results. The coordinator:

- Parallelizes independent work across up to 4 developers per milestone
- Runs quality review after all milestones complete
- Loops through issue resolution until QR passes
- Invokes technical writer only after QR passes

**Reconciliation** handles resume scenarios. When the user request contains
signals like "already implemented", "resume", or "partially complete", the
workflow validates existing code against plan requirements before executing
remaining milestones. Building on unverified code means rework.

**Issue Resolution** presents each QR finding individually with options (Fix /
Skip / Alternative). Fixes delegate to developers or technical writers, then QR
runs again. This cycle repeats until QR passes.

## Invisible Knowledge

### Why session.yaml was removed

Initial design included session.yaml to track workflow state across invocations. Removed because context.json already captures task and architecture decisions -- the critical state that sub-agents need. Session-level tracking (current step, timestamps) belongs in the orchestrator's context window, not persisted state. Adding a separate file created redundancy without value.

### Why 6-field decision schema

Early design used 11 fields per decision (id, question, status, raised_at, decided_at, decided_by, answer, rationale, options, blocking, superseded_by). Reduced to 6 fields (id, question, status, decided_by, answer, rationale) because:

- raised_at/decided_at: Timestamps added noise without improving decision reasoning
- options: Better captured in findings.json during EXPLORING phase
- blocking: Implicit in status=READY with orchestrator waiting for user input
- superseded_by: Trackable via status=SUPERSEDED + new decision with same question

Simpler schema means less for LLMs to get wrong when writing decisions.

### Why per-phase qr-<phase>.json instead of single qa.json

Separate qr-<phase>.json files (qr-plan-structure.json, qr-plan-code.json, qr-plan-docs.json, qr-impl-code.json, qr-impl-docs.json) prevent cross-phase contamination. With a single qa.json:

- Plan QR items mix with implementation QR items (confusing for fixers)
- Verification scope unclear (which phase is this item checking?)
- Cannot isolate QR results per phase (plan QR should be independent from implementation QR)

Per-phase files allow independent verification cycles with clear boundaries. Each file is deleted when its phase passes QR gate.

## Plan Schema

Key fields in plan.json:

- milestones[].documentation.function_blocks[] (Tier 2 function-level rationale)
- milestones[].documentation.inline_comments[] (Tier 1 WHY comments)
- readme_entries[] (cross-cutting architecture spanning milestones)
