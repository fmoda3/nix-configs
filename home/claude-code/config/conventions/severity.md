# QR Severity Taxonomy

## Severity Levels (MoSCoW)

| Level  | Meaning                  | Progressive De-Escalation |
| ------ | ------------------------ | ------------------------- |
| MUST   | Unrecoverable if missed  | All iterations            |
| SHOULD | Maintainability debt     | Iterations 1-4            |
| COULD  | Auto-fixable, low impact | Iterations 1-3            |

## Categories by Recoverability

### KNOWLEDGE (MUST)

Knowledge loss is permanent. These ALWAYS block.

| Category               | Detection                                   |
| ---------------------- | ------------------------------------------- |
| DECISION_LOG_MISSING   | Non-trivial choice without logged rationale |
| POLICY_UNJUSTIFIED     | Policy default without Tier 1 backing       |
| IK_TRANSFER_FAILURE    | Invisible knowledge not at BEST location    |
| TEMPORAL_CONTAMINATION | Change-relative language in comments        |
| BASELINE_REFERENCE     | Comment references removed/replaced code    |
| ASSUMPTION_UNVALIDATED | Architectural assumption without citation   |
| LLM_COMPREHENSION_RISK | Pattern that would confuse future LLM       |
| MARKER_INVALID         | Intent marker without valid explanation     |

### STRUCTURE (SHOULD)

Maintainability debt. Compounds but detectable later.

| Category                    | Detection                                    |
| --------------------------- | -------------------------------------------- |
| GOD_OBJECT                  | >15 methods OR >10 deps OR mixed concerns    |
| GOD_FUNCTION                | >50 lines OR mixed abstraction OR >3 nesting |
| DUPLICATE_LOGIC             | Copy-pasted blocks, parallel functions       |
| INCONSISTENT_ERROR_HANDLING | Mixed exceptions/codes in same module        |
| CONVENTION_VIOLATION        | Violates documented project convention       |
| TESTING_STRATEGY_VIOLATION  | Tests don't follow confirmed strategy        |

### DIAGRAM (MUST for semantic, COULD for format)

Diagram graph integrity. Semantic issues block; format issues warn.

| Category             | Severity | Detection                                  |
| -------------------- | -------- | ------------------------------------------ |
| ORPHAN_NODE          | MUST     | Node with zero edges                       |
| INVALID_EDGE_REF     | MUST     | Edge source/target references missing node |
| INVALID_SCOPE_REF    | MUST     | Scope references non-existent milestone    |
| DIAGRAM_WIDTH_EXCEED | COULD    | ASCII render line > 80 chars               |
| UNCLOSED_BOX         | COULD    | Box corners misaligned in ASCII render     |

### COSMETIC (COULD)

Auto-fixable, minimal impact.

| Category            | Detection                                                  |
| ------------------- | ---------------------------------------------------------- |
| DEAD_CODE           | Unused functions, impossible branches                      |
| FORMATTER_FIXABLE   | Style issues fixable by formatter/linter                   |
| MINOR_INCONSISTENCY | Non-conformance with no documented rule                    |
| TOOLCHAIN_CATCHABLE | Error in planned code that compiler/linter/interpreter     |
|                     | would flag, where intended correct code is obvious from    |
|                     | context (typos, missing imports, non-exhaustive match).    |
|                     | NOT: errors revealing plan-level misunderstanding -- those |
|                     | are ASSUMPTION_UNVALIDATED (MUST)                          |

## IK Proximity Rule

Invisible knowledge must be at BEST location: "as close as possible to where
relevant, but not more"

| Knowledge Type | Best Location                           |
| -------------- | --------------------------------------- |
| Accepted risks | :TODO: comment at flagged code location |
| Architecture   | README.md in SAME directory             |
| Tradeoffs      | Code comment where decision shows       |
| Invariants     | Code comment at enforcement point       |

Wrong location = IK_TRANSFER_FAILURE (MUST)
