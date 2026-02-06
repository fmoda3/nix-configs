# QR (Quality Review)

## Overview

Quality Review modules perform validation with severity-based blocking thresholds. Each module validates specific aspects of plans or implementations at designated workflow gates.

## Modules

**plan_completeness.py**: Validates plan structure, milestone definitions, and acceptance criteria completeness.

**plan_code.py**: Reviews code diffs for correctness, edge cases, and implementation quality.

**plan_docs.py**: Verifies documentation completeness, clarity, and alignment with implementation.

**post_impl_code.py**: Post-implementation code validation against plan specifications.

**post_impl_doc.py**: Post-implementation documentation review for accuracy and completeness.

**reconciliation.py**: Verifies plan matches implementation, ensures all milestones delivered.

## QA State Tracking Integration

QR gates now integrate with QA state tracking for structured verification. QA decomposition applies plan-and-solve methodology to quality verification by breaking monolithic reviews into parallelizable checklist items.

### Philosophy: Minimal State, Dumb Main Agent, Just-In-Time Prompting

**Minimal State Files**: Store ONLY authoritative data -- item statuses (TODO/PASS/FAIL). Sub-agents compute status overview on-demand when THEY need it. No derived values stored.

**Dumb Main Agent**: Main agent dispatches and routes. It needs ONE bit: PASS or FAIL. The LLM reads responses naturally and follows instructions. No parsing logic required in main agent.

**Just-In-Time Prompting**: Executor sub-agent (fixer) invokes script and sees prompts about what failed. Main agent never sees these details. Details are injected only when needed, only to the agent that needs them.

### Why Main Agent Doesn't Parse

The LLM reads sub-agent responses and follows instructions naturally. No JSON parsing, no status extraction logic. Sub-agents return text responses with embedded instructions like "PASS: continue to next phase" or "FAIL: invoke fixer with items [...]". Main agent reads and follows.

This eliminates an entire class of bugs: parsing errors, schema mismatches, JSON escaping issues. The LLM's natural language understanding handles all response interpretation.

### Why Status Overview is Sub-Agent Only

The executor needs to see "5 items: 3 PASS, 2 FAIL" to decide what to fix. The main agent doesn't. The main agent only needs to know: did verification pass or fail?

Status overview is computed on-demand by the executor when it runs. It's not stored in qr-{phase}.json because it's derived data. Storing it would violate the minimal state principle and create consistency risks (what if counts don't match items?).

### Response Formats

**DECOMPOSE Mode**: Returns QA item IDs and instructions for verification.

```
DECOMPOSE COMPLETE

Items created: 7
- plan-001: Verify milestone definitions (scope: *)
- plan-002: Check acceptance criteria (scope: milestone:M1)
- plan-003: Validate diff syntax (scope: file:planner/qa/verify.py)
...

NEXT: Invoke verifiers for each item.
```

**VERIFY Mode**: Returns PASS/FAIL verdict.

```
VERIFICATION COMPLETE

Status: PASS
Items: 7 total, 7 PASS, 0 FAIL

NEXT: Continue to next phase.
```

or

```
VERIFICATION COMPLETE

Status: FAIL
Items: 7 total, 5 PASS, 2 FAIL
Failed items:
- plan-002: Acceptance criteria missing for M1
- plan-005: Diff has merge conflict markers

NEXT: Invoke fixer with failed items.
```

**FIX_GUIDANCE Mode**: Returns specific instructions for fixing failures.

```
FIX GUIDANCE

Item plan-002: Acceptance criteria missing for M1
Scope: milestone:M1
Fix: Add acceptance criteria to milestone M1 definition. Include:
  - Success conditions
  - Verification steps
  - Exit criteria

Item plan-005: Diff has merge conflict markers
Scope: file:planner/qa/verify.py:45-52
Fix: Remove conflict markers (<<<<<<, ======, >>>>>>) and resolve merge conflicts.
```

### Three Modes

**DECOMPOSE**: Break artifact into verifiable QA items. Sub-agent reads artifact, identifies quality dimensions, emits items with id/scope/check/status/finding fields. Items start with status=TODO.

**VERIFY**: Execute verification for each item. Macro items (scope=`*`) run sequentially, micro items (scope=specific path) run in parallel. Each verifier updates item status to PASS/FAIL with finding explanation.

**FIX_GUIDANCE**: Generate specific fix instructions for failed items. Sub-agent reads failed items and produces actionable instructions for each failure.

### State File Schema (qr-{phase}.json)

```json
{
  "schema_version": "1.0",
  "phase": "plan-structure",
  "items": [
    {
      "id": "plan-001",
      "scope": "*",
      "check": "Verify milestone definitions are complete with acceptance criteria",
      "status": "PASS",
      "finding": null
    },
    {
      "id": "plan-002",
      "scope": "milestone:M1",
      "check": "Validate acceptance criteria for milestone M1",
      "status": "FAIL",
      "finding": "Acceptance criteria missing. Need success conditions and verification steps."
    },
    {
      "id": "plan-003",
      "scope": "file:planner/qa/verify.py",
      "check": "Check diff syntax and formatting",
      "status": "TODO",
      "finding": null
    }
  ]
}
```

**schema_version**: Version identifier for qr-{phase}.json format (currently "1.0").

**phase**: Verification phase -- one of `plan-structure`, `plan-code`, `plan-docs`, `impl-code`, `impl-docs`.

**items**: Array of QA items with exactly 5 fields each:

- **id**: Correlation key for parallel dispatch (pattern: `{phase}-{seq:03d}`)
- **scope**: Content target AND parallelization hint (`*` for macro, specific path for micro)
- **check**: Freeform verification instruction
- **status**: One of TODO/PASS/FAIL
- **finding**: Explanation when not PASS (null for TODO/PASS)

### Main Agent Flow (Dumb Router)

```
User request
     |
     v
Step 1: plan-init
Create state directory
     |
     v
Step 2: plan-structure-execute
Main agent dispatches planner sub-agent
     |
     v
Step 3: plan-structure-qr
Main agent invokes QA decompose
     |
     v
Decompose sub-agent returns: "Items created: 7"
     |
     v
Main agent reads response, sees "NEXT: Invoke verifiers"
     |
     v
Main agent invokes verify (macro items sequential, micro parallel)
     |
     v
Verify sub-agent returns: "Status: FAIL, 2 failed items"
     |
     v
Step 4: plan-structure-qr-gate
Main agent reads response, sees "NEXT: Invoke fixer"
     |
     v
Step 2 (with --qr-fail): plan-structure-execute
Main agent invokes fixer
     |
     v
Fixer returns: "Fixes applied"
     |
     v
Main agent loops back to Step 3: plan-structure-qr
```

No status checking, no JSON parsing. Main agent reads text and follows instructions.

### Executor Flow (Just-In-Time Prompting)

```
Executor invoked by main agent
     |
     v
Read qr-{phase}.json from STATE_DIR
     |
     v
Compute status overview (3 PASS, 2 FAIL)
     |
     v
Generate prompts with failure details:
  - "Item plan-002 failed: Acceptance criteria missing"
  - "Item plan-005 failed: Diff has conflict markers"
     |
     v
Execute fixes
     |
     v
Update qr-{phase}.json with new statuses
     |
     v
Return response: "Status: PASS, all items fixed"
```

Status overview computed on-demand. Not stored in qr-{phase}.json. Main agent never sees it.

### Why JSON

**Consistency**: JSON is universal. Every language, every tool. YAML requires pyyaml dependency and has indentation gotchas.

**Avoid pyyaml dependency**: One less package to install, one less version conflict risk.

**Simplicity**: JSON schema is unambiguous. YAML has multiple syntaxes for the same structure (flow vs block, quoted vs unquoted).

**Tooling**: Every editor has JSON validation built-in. JSON Schema validators are ubiquitous.

**LLM-friendly**: Modern LLMs handle JSON natively. ChatML and Claude both have JSON mode. No escaping issues for simple structures like QA items.

## QR Iteration Blocking

Severity thresholds vary by iteration depth to prevent infinite retry loops:

| Iteration | Block Severities      | Rationale                                |
| --------- | --------------------- | ---------------------------------------- |
| 1-2       | All (MUST/SHOULD/MAY) | High failure rate, force immediate fixes |
| 3-4       | MUST/SHOULD           | Address nuanced issues                   |
| 5+        | MUST only             | Prevent infinite retry loops             |

## LoopState Tracking

QR gates use LoopState enum to track iteration progression:

- **INITIAL**: First review attempt
- **RETRY**: Fixing issues from previous iteration
- **COMPLETE**: Passed review

State transitions:

```
INITIAL -> (QRStatus.PASS) -> COMPLETE [terminal]
INITIAL -> (QRStatus.NEEDS_CHANGES) -> RETRY -> (iteration++) -> RETRY -> ...
```

## Integration with QA Workflow

QR gates invoke QA decomposition before performing reviews:

1. QR gate triggered (e.g., plan_completeness)
2. Invoke qa/decompose.py to generate verification items
3. Spawn verifiers (parallel for micro, sequential for macro)
4. Aggregate results into qr-{phase}.json
5. Route on aggregation result:
   - PASS: proceed to next workflow step
   - FAIL: invoke fixer, loop back to verification

This integration provides structured, parallelizable verification with explicit failure tracking and automated retry logic.
