# Planner Skill Design Intent

Authoritative design specification for the planner skill. This document governs WHY the system works the way it does. Implementation MUST conform to this spec.

## Philosophy

Three principles govern this design:

**RESOLVE AMBIGUITY EARLY**: Business decisions happen in planning phase, BEFORE code is written. Execution is mechanical. Questions about requirements, architecture, or approach get answered during planning, not discovered during implementation.

**CAPTURE INVISIBLE KNOWLEDGE**: Decisions, rationale, and context are captured in state files so any agent can understand WHY, not just WHAT. When a sub-agent picks up work, it reads state files and has full context. No information lives only in conversation history.

**QUALITY OVER SPEED**: LLMs make mistakes. Multiple QR gates with iteration loops catch errors before they propagate. This skill explicitly trades execution time for correctness.

## State Files

All state mutation (except initial context capture) happens via Python scripts. The orchestrator dispatches sub-agents; sub-agents invoke scripts; scripts emit prompts; LLM performs work and writes state.

### context.json

Created by orchestrator in step 2 (context-verify). Persists user-provided planning context for sub-agent handover.

```json
{
  "task_spec": ["goal sentence", "scope: dir/module", "out-of-scope: X"],
  "constraints": ["MUST: X", "SHOULD: Y"],
  "entry_points": ["file:function - why relevant"],
  "rejected_alternatives": ["alternative - why dismissed"],
  "current_understanding": ["how system works", "bug: symptom + repro"],
  "assumptions": ["inference (H/M/L confidence)"],
  "invisible_knowledge": ["design rationale", "invariants", "tradeoffs"],
  "user_quotes": ["verbatim quote with context"],
  "reference_docs": ["doc/spec.md - what it specifies"]
}
```

All fields are string arrays. Empty arrays are acceptable; omitting fields is not.

**QR workflow access**: context.json is available to all QR sub-agents (decompose, verify, fix) as read-only reference for semantic validation against original user requirements. This enables QR agents to verify not just structural correctness but also alignment with user intent.

### plan.json

Primary state file. Created in step 1 (plan-init) as skeleton. Mutated through planning phases.

**No schema versioning**: State files (context.json, plan.json, qr-\*.json) are ephemeral, created and consumed within a single planning session. Schema versioning adds complexity without benefit for short-lived artifacts. Pydantic v2 models in `shared/schema.py`.

```
Plan
  overview
    problem: string       -- what we're solving
    approach: string      -- how we're solving it

  planning_context
    decisions: Decision[]
      id: "DL-001"
      decision: string
      reasoning: string   -- logical chain using -> notation
                          -- e.g. "high call volume -> bcrypt too slow -> use HMAC-SHA256"

    rejected_alternatives: RejectedAlternative[]
      alternative: string
      reason: string
      decision_ref: "DL-XXX"

    constraints: string[] -- free-form, e.g. "MUST: support Python 3.9+ (user-specified)"

    risks: Risk[]
      risk: string
      mitigation: string
      anchor: string | null       -- "file:L###-L###" if location-specific
      decision_ref: "DL-XXX" | null

  invisible_knowledge
    system: string        -- architecture, data flow, structure rationale as prose
    invariants: string[]  -- must-preserve properties
    tradeoffs: string[]   -- known compromises

  diagram_graphs: DiagramGraph[]   -- populated by Architect (IR), rendered by TW
    id: "DIAG-001"
    type: "architecture" | "state" | "sequence" | "dataflow"
    scope: string         -- "overview" | "invisible_knowledge" | "milestone:M-XXX"
    title: string
    nodes: DiagramNode[]
      id: string          -- "node-001"
      label: string       -- free-form, e.g. "gRPC Server"
      type: string | null -- free-form, e.g. "service", "database", "queue"
    edges: DiagramEdge[]
      source: string      -- node id (validated: must exist)
      target: string      -- node id (validated: must exist)
      label: string       -- free-form, e.g. "validates", "sends", "reads"
      protocol: string | null  -- free-form, e.g. "gRPC", "HTTP"
    ascii_render: string | null  -- populated by TW, null until rendered

  milestones: Milestone[]
    id: "M-001"
    name: string
    files: string[]
    requirements: string[]
    acceptance_criteria: string[]
    tests: string[]       -- free-form entries, e.g.:
                          -- "file:tests/test_auth.py"
                          -- "scenario:EDGE empty token returns 401"
                          -- "skip:no integration environment"

    code_intents: CodeIntent[]  -- populated by Architect
      id: "CI-001"
      file: string
      behavior: string    -- what the code should do, includes function/params
      decision_refs: string[]

    code_changes: CodeChange[]  -- populated by Developer, amended by TW
      intent_ref: "CI-XXX" | null  -- null for cross-cutting docs (README.md)
      file: string
      diff: string                 -- unified diff, includes all documentation
      comments: string             -- change-level context, may reference decisions

    is_documentation_only: bool
    delegated_to: string | null

  waves: Wave[]
    id: "W-001"
    milestones: string[]  -- M-XXX refs
```

Waves execute in array order. All milestones in W-001 complete before W-002 begins. Milestones within a wave may execute in parallel.

Cross-reference validation: `Plan.validate_refs()` checks:

- `code_changes.intent_ref` -> `code_intents.id` (within same milestone, when not null)
- `code_intents.decision_refs` -> `decisions.id`
- `rejected_alternatives.decision_ref` -> `decisions.id`
- `risks.decision_ref` -> `decisions.id`
- `diagram_graphs.edges.source` -> `diagram_graphs.nodes.id` (within same diagram)
- `diagram_graphs.edges.target` -> `diagram_graphs.nodes.id` (within same diagram)
- `diagram_graphs.scope` -> `milestones.id` (when scope is `milestone:M-XXX`)

### qr-{phase}.json

Ephemeral QR state. Created during QR decomposition. Deleted after phase passes. Five phases: plan-design, plan-code, plan-docs, impl-code, impl-docs.

```json
{
  "phase": "plan-design",
  "iteration": 1,
  "items": [
    {
      "id": "qa-001",
      "scope": "*",
      "check": "Description of what to verify",
      "status": "TODO",
      "finding": null
    }
  ]
}
```

**Top-level fields:**

- phase: Which QR phase this file tracks
- iteration: Current QR loop count (1 = first attempt, 2+ = retry after failures)

**Item fields:**

- id: Unique identifier within phase (qa-001, qa-002, ...)
- scope: Free-form location specifier (see Scope Philosophy below)
- check: Actionable verification instruction
- status: "TODO" | "PASS" | "FAIL"
- finding: null or explanation string (required when FAIL)

The number of items in the array is adaptive -- determined by content complexity, not preset ranges. Simple phases may have fewer items; complex phases with many architectural concerns may have more.

#### Iteration as Single Source of Truth

The `iteration` field tracks QR loop count within the file itself. This is the authoritative source for iteration state -- no CLI flags track iteration.

**Decompose step behavior:**

Decomposition runs exactly ONCE per QR phase. The first invocation generates all QR items; subsequent iterations skip decomposition and re-verify existing items.

1. Check if qr-{phase}.json exists
2. If exists: SKIP decomposition, proceed directly to verify step
3. If absent: run 8-step decomposition, create file with iteration: 1
4. Output next step command

WHY single decomposition per phase:
Decomposition defines verification target. Regenerating items on each
iteration creates moving target: new items introduce new failures
unrelated to original issues, preventing convergence. Fix-verify loop
requires stable item set to terminate.

WHY file existence check, not iteration check:
Existence signals "decomposition complete"; iteration signals "verification
cycle count". Checking iteration would couple decomposition to verification
progress (wrong abstraction).

**Iteration semantics:**

The iteration counter tracks verification cycles, not decomposition cycles:

- iteration=1: first verification after initial decomposition
- iteration=2+: re-verification after fixes (incremented by verify step on RETRY)

Manual re-decomposition: Delete qr-{phase}.json to force fresh decomposition.

**Why file-based iteration:**

- Decompose script determines iteration programmatically from file state
- Gate/route steps need only invoke work step with --state-dir (no iteration arg)
- Single source of truth eliminates state drift between CLI args and file contents
- Aligns with "state detection over flags" invariant

#### QR File Path is Computable

The path to qr-{phase}.json is always `{state_dir}/qr-{phase}.json`. Scripts compute this from --state-dir and phase name; no CLI flag passes the path explicitly.

**Router detection logic:**

```python
def detect_fix_mode(state_dir: str, phase: str) -> tuple[bool, int]:
    """Check if QR file exists with failures. Return (is_fix_mode, iteration)."""
    qr_path = Path(state_dir) / f"qr-{phase}.json"
    if not qr_path.exists():
        return False, 1
    qr_state = json.loads(qr_path.read_text())
    has_failures = any(item.get("status") == "FAIL" for item in qr_state.get("items", []))
    iteration = qr_state.get("iteration", 1)
    return has_failures, iteration
```

**Implication for gate routing:**

Gate steps loop back to work steps with only --state-dir. The work step's router inspects qr-{phase}.json to determine whether to dispatch execute or fix workflow. This eliminates orchestrator responsibility for tracking failure state.

#### Scope Philosophy

QA items fall into two categories:

1. **Scoped checks**: Apply to specific code locations (files, functions, line ranges)
2. **Global checks**: Apply across the entire artifact (quality aspects, consistency rules)

Rather than separate fields for file, line, component, quality_aspect, etc., a single free-form `scope` field handles all cases. The LLM fills it with whatever granularity is appropriate:

| Scope Value                | Meaning                                |
| -------------------------- | -------------------------------------- |
| `*`                        | Global check -- applies everywhere     |
| `file:src/auth.py`         | Entire file                            |
| `file:src/auth.py:L10-L50` | Specific line range                    |
| `function:validate_token`  | Named function (any file)              |
| `component:auth-flow`      | Architectural component spanning files |

This trusts the LLM's prose comprehension. The decompose agent writes scopes that match how humans describe locations. The verify agent reads the scope and knows where to look. No rigid taxonomy needed.

**Prompt generation**: Scripts emit scope values verbatim to verification prompts. Example prompt fragment: "Verify the following in scope `{scope}`: {check}"

#### QR State Mutation (cli/qr.py)

After decomposition creates the initial qr-{phase}.json file, all subsequent mutations go through the QR CLI script. Agents do not modify the JSON file directly -- they invoke the script to update item status.

**CLI interface:**

```
python3 -m skills.planner.cli.qr --state-dir <dir> --qr-phase <phase> update-item <id> --status <status> [--finding <text>]

Arguments:
  --state-dir    State directory containing qr-{phase}.json (required)
  --qr-phase     One of: plan-design, plan-code, plan-docs, impl-code, impl-docs (required)
  --status       PASS or FAIL (required)
  --finding      Explanation text (required when FAIL, forbidden when PASS)
```

**Example invocations:**

```bash
# Verify agent marks item as PASS
python3 -m skills.planner.cli.qr --state-dir /tmp/state --qr-phase plan-design \
    update-item qa-001 --status PASS

# Verify agent marks item as FAIL
python3 -m skills.planner.cli.qr --state-dir /tmp/state --qr-phase plan-design \
    update-item qa-003 --status FAIL --finding "Missing null check in validate_token()"
```

**Status semantics:**

- Items without explicit status are interpreted as TODO (initial state after decomposition)
- TODO means "not yet verified" -- the decompose agent creates items, verify agents evaluate them
- PASS means "verification passed" -- item is immutable, further updates raise an error
- FAIL means "verification failed" -- finding explains why, item can transition to PASS after fix

**Valid state transitions:**

```
TODO -> PASS         (verification passes on first attempt)
TODO -> FAIL         (verification fails)
FAIL -> PASS         (re-verification passes after fix)
FAIL -> FAIL         (re-verification fails again, finding may update)
PASS -> *            (ERROR: item is immutable once passed)
```

**Why script-mediated mutation:**

Parallel verify agents update the same qr-{phase}.json file simultaneously. Direct JSON writes cause race conditions (read-modify-write without locking = lost updates). The CLI script uses file locking (fcntl.flock) and atomic writes (tmp + rename) to serialize concurrent updates safely.

**Implementation reuse:**

The script reuses helpers from `shared/qr/utils.py`:

- `load_qr_state(state_dir, phase)` -- load and parse qr-{phase}.json
- `get_qr_item(qr_state, item_id)` -- find item by ID
- `get_qr_iteration(state_dir, phase)` -- get current iteration (1 if file absent)
- `has_qr_failures(state_dir, phase)` -- check if file exists with FAIL items

The CLI script adds atomic save with locking (not in utils.py because only the CLI needs it). Router scripts use `has_qr_failures()` to detect fix mode without loading full state.

#### Plan State Mutation (cli/plan.py)

Plan.json entities are mutated through the plan CLI script with Compare-And-Swap (CAS) versioning. Agents do not modify plan.json directly -- they invoke set-X commands that enforce version consistency.

**CAS Versioning Model:**

Each versionable entity has a `version: int` field starting at 1. Updates require providing the current version; the script rejects mismatches.

- Creates: `--id` omitted, `--version` omitted -> auto-generate ID, version=1
- Updates: `--id` provided, `--version` required -> validate version matches, increment on success

**Why CAS:**

1. **Race condition prevention**: Multiple agents cannot blindly overwrite each other's changes
2. **Forced read-before-write**: Agents must read current state to obtain version number
3. **Conflict detection**: Stale reads surface immediately as version mismatches

**CLI interface:**

```
python3 -m skills.planner.cli.plan --state-dir <dir> set-intent \
    --milestone M-001 --file path.py --behavior "description"    # create

python3 -m skills.planner.cli.plan --state-dir <dir> set-intent \
    --id CI-M-001-001 --version 1 --behavior "updated"           # update
```

**Version mismatch output:**

On version mismatch, the CLI prints the full current entity JSON and retry instructions. This ensures the agent always has the latest state on failure:

```xml
<version_mismatch_error>
  <entity_id>CI-M-001-001</entity_id>
  <provided_version>1</provided_version>
  <current_version>2</current_version>
  <current_entity>
    {"id": "CI-M-001-001", "version": 2, "file": "...", ...}
  </current_entity>
  <action>Integrate your changes into the current entity above and retry with --version 2</action>
</version_mismatch_error>
```

**Success output:**

On success, the CLI prints the entity ID and new version:

```xml
<entity_result>
  <id>CI-M-001-001</id>
  <version>2</version>
  <operation>updated</operation>
</entity_result>
```

**Unified set-X commands:**

| Command            | Entity        | Role      |
| ------------------ | ------------- | --------- |
| set-milestone      | Milestone     | architect |
| set-intent         | CodeIntent    | architect |
| set-decision       | Decision      | architect |
| set-diagram        | DiagramGraph  | architect |
| add-diagram-node   | DiagramNode   | architect |
| add-diagram-edge   | DiagramEdge   | architect |
| set-change         | CodeChange    | developer |
| set-doc            | Documentation | tw        |
| set-diagram-render | DiagramGraph  | tw        |

The legacy add-X and update-X commands have been removed. All mutation uses set-X with CAS versioning.

## Documentation Model

Documentation falls into two categories based on scope:

### Code-Local Documentation

Documentation that lives in source files. Delivered via diff amendment by Technical Writer.

| Tier           | What                                      | Where       | Example                                                |
| -------------- | ----------------------------------------- | ----------- | ------------------------------------------------------ |
| Module comment | File-level: what's in here                | Top of file | `# auth.py -- Token validation and session management` |
| Docstring      | Function-level: what it does, when to use | On function | `def validate(token): """Validate JWT..."""`           |
| Inline comment | Logic explanation: algorithms, decisions  | Above code  | `# xxhash for speed; collisions acceptable (DL-003)`   |

TW amends Developer's diffs to add these. The diff IS the documentation delivery mechanism.

### Cross-Cutting Documentation

Documentation spanning multiple files/components. Created as separate code_changes with `intent_ref: null`.

| Type      | What                                    | Handling                            |
| --------- | --------------------------------------- | ----------------------------------- |
| README.md | Design decisions, architecture overview | code_change with `intent_ref: null` |

Example:

```json
{
  "intent_ref": null,
  "file": "src/auth/README.md",
  "diff": "--- /dev/null\n+++ b/src/auth/README.md\n...",
  "comments": "Cross-cutting auth design decisions"
}
```

README.md files don't implement code behavior, so `intent_ref` is null. They're still code_changes because they're file modifications tracked in the plan.

## Diagram Model

Diagrams serve as the primary entry point for humans to understand what a plan implements. A well-crafted diagram answers "what does this do?" in under 10 seconds.

### Diagram Types

| Type         | When to Use                                    | Structure                       |
| ------------ | ---------------------------------------------- | ------------------------------- |
| architecture | Services, APIs, SDKs, component boundaries     | Boxes with directional arrows   |
| state        | Explicit state machines, protocol lifecycles   | Named states with labeled edges |
| sequence     | Multi-party request/response, time-ordered     | Vertical timeline, horiz arrows |
| dataflow     | ETL pipelines, streaming, data transformations | Left-to-right flow with stages  |

Default to `architecture`. Use others only when the plan explicitly involves state machines, multi-party protocols, or data pipelines.

### Diagram Scope

Scope determines where the diagram appears in rendered output:

| Scope                 | Renders In             | Purpose                                |
| --------------------- | ---------------------- | -------------------------------------- |
| `overview`            | After Overview section | "Hero" diagram -- first visual context |
| `invisible_knowledge` | Invisible Knowledge    | Architectural mental model for LLMs    |
| `milestone:M-XXX`     | Top of milestone       | What this specific milestone adds      |

Multiple diagrams per scope are allowed. First diagram in list with matching scope is primary.

### Two-Phase Workflow

Diagrams use a graph IR (intermediate representation) to separate correctness from rendering:

**Phase 1 -- Architect (plan-design-work):**

- Creates diagram_graphs with nodes and edges
- Validates semantic correctness: no orphan nodes, valid edge references
- Leaves ascii_render as null

**Phase 2 -- Technical Writer (plan-docs-work):**

- Renders each diagram_graph to ASCII
- Populates ascii_render field
- Validates format: width, box alignment

This separation ensures the Architect focuses on WHAT to communicate (graph structure) while the TW focuses on HOW to communicate (visual rendering).

### ASCII Conventions

Diagrams render as fixed-width ASCII for universal portability (cat, vim, git diff, terminal):

```
+------------------+     +------------------+
| Component A      | --> | Component B      |
| (description)    |     | (description)    |
+------------------+     +------------------+
        |
        v
+------------------+
| Component C      |
+------------------+
```

Syntax:

- Box corners: `+`
- Horizontal edges: `-`
- Vertical edges: `|`
- Arrows: `v`, `^`, `<`, `>`, `-->`, `<--`
- Edge labels: inline on arrow or parenthetical

Target width: 80 chars max. Diagrams wider than terminal wrap and lose value.

### Skip Criteria

Not all plans need diagrams. Skip diagram generation if:

- Pure refactoring (no new components)
- Single-file changes
- Documentation-only milestones
- Overview lacks structural keywords (services, layers, flow, protocol)

When skipping, diagram_graphs remains empty. This is valid state.

### Documentation Workflow

**Developer (plan-code-work)**: Creates code_changes implementing code_intents. May include obvious comments.

**TW (plan-docs-work)**:

1. Amends each code_change diff to add module comments, docstrings, inline comments
2. Creates new code_changes for README.md files (`intent_ref: null`)

The `comments` field on code_changes is for change-level context that doesn't belong in the code itself. May reference decisions inline: "Uses xxhash for speed (DL-003)".

## Mutation Ownership

| File                | Step | Agent            | Mutation                                                                    |
| ------------------- | ---- | ---------------- | --------------------------------------------------------------------------- |
| plan.json           | 1    | orchestrator     | Create skeleton                                                             |
| context.json        | 2    | orchestrator     | Create and freeze                                                           |
| plan.json           | 3    | architect        | Add overview, milestones, code_intents, decisions, diagram_graphs (IR)      |
| qr-plan-design.json | 4    | quality-reviewer | Create items with status: TODO                                              |
| qr-plan-design.json | 5    | quality-reviewer | Update individual item status to PASS/FAIL                                  |
| plan.json           | 7    | developer        | Add code_changes                                                            |
| qr-plan-code.json   | 8    | quality-reviewer | Create items with status: TODO                                              |
| qr-plan-code.json   | 9    | quality-reviewer | Update individual item status to PASS/FAIL                                  |
| plan.json           | 11   | technical-writer | Amend code_changes diffs with documentation, render diagram_graphs to ASCII |
| qr-plan-docs.json   | 12   | quality-reviewer | Create items with status: TODO                                              |
| qr-plan-docs.json   | 13   | quality-reviewer | Update individual item status to PASS/FAIL                                  |
| qr-plan-design.json | 6    | orchestrator     | Delete file (all PASS)                                                      |
| qr-plan-code.json   | 10   | orchestrator     | Delete file (all PASS)                                                      |
| qr-plan-docs.json   | 14   | orchestrator     | Delete file (all PASS)                                                      |
| qr-impl-code.json   | E3   | quality-reviewer | Create items with status: TODO                                              |
| qr-impl-code.json   | E4   | quality-reviewer | Update individual item status to PASS/FAIL                                  |
| qr-impl-code.json   | E5   | orchestrator     | Delete file (all PASS)                                                      |
| qr-impl-docs.json   | E7   | quality-reviewer | Create items with status: TODO                                              |
| qr-impl-docs.json   | E8   | quality-reviewer | Update individual item status to PASS/FAIL                                  |
| qr-impl-docs.json   | E9   | orchestrator     | Delete file (all PASS)                                                      |

## Workflows

### Planning Workflow (orchestrator/planner.py)

14 steps. Transforms user request into executable plan (the IR).

Each QR-able phase follows a 4-step block pattern:

- Work step (1 sub-agent): Execute or fix based on state detection. Sub-agent validates written state before returning.
- QR decompose (1 sub-agent): Create verification items. Sub-agent validates qr-{phase}.json before returning.
- QR verify (N sub-agents): Parallel item verification via batched dispatch.
- QR route (orchestrator): Aggregate results, loop or proceed.

```
Step 1: plan-init
  Action: Create state_dir, write plan.json skeleton
  Next: Step 2

Step 2: context-verify
  Action: Capture context into context.json, self-verify completeness
  Checklist: goal statable in one sentence, at least one out-of-scope item,
             at least one constraint (or explicit "none"), entry points identified
  Next: Step 3

Step 3: plan-design-work
  Agent: architect
  Script: architect/plan_design.py (router)
  Routing: If qr-plan-design.json has FAIL items -> architect/plan_design_qr_fix.py
           Otherwise -> architect/plan_design_execute.py
  Output: plan.json with overview, milestones, code_intents, decisions, diagram_graphs (IR only)
  Validation: Sub-agent validates plan.json against schema before returning
  Next: Step 4

Step 4: plan-design-qr-decompose
  Agent: quality-reviewer
  Script: quality_reviewer/plan_design_qr_decompose.py
  Output: qr-plan-design.json with items (status: TODO)
  Output: parallel_dispatch block listing all --qr-item IDs
  Next: Step 5

Step 5: plan-design-qr-verify
  Agent: quality-reviewer (N parallel instances)
  Script: quality_reviewer/plan_design_qr_verify.py --qr-items {ids}
  Input: Orchestrator script parses parallel_dispatch from step 4, batches items by group
  Output: Each agent verifies its batch, updates items in qr-plan-design.json to PASS/FAIL
  Next: Step 6

Step 6: plan-design-qr-route
  Action: Orchestrator script determines routing from qr-plan-design.json
  Route: All PASS -> delete qr file, proceed to Step 7
         Any FAIL -> loop to Step 3 (router will dispatch to qr_fix)

Step 7: plan-code-work
  Agent: developer
  Script: developer/plan_code.py (router)
  Routing: If qr-plan-code.json has FAIL items -> developer/plan_code_qr_fix.py
           Otherwise -> developer/plan_code_execute.py
  Output: code_changes[] added to milestones
  Next: Step 8

Step 8: plan-code-qr-decompose
  Agent: quality-reviewer
  Script: quality_reviewer/plan_code_qr_decompose.py
  Output: qr-plan-code.json with items (status: TODO)
  Output: parallel_dispatch block listing all --qr-item IDs
  Next: Step 9

Step 9: plan-code-qr-verify
  Agent: quality-reviewer (N parallel instances)
  Script: quality_reviewer/plan_code_qr_verify.py --qr-item {id}
  Output: Each agent updates one item in qr-plan-code.json to PASS/FAIL
  Next: Step 10

Step 10: plan-code-qr-route
  Route: All PASS -> delete qr file, proceed to Step 11
         Any FAIL -> loop to Step 7

Step 11: plan-docs-work
  Agent: technical-writer
  Script: technical_writer/plan_docs.py (router)
  Routing: If qr-plan-docs.json has FAIL items -> technical_writer/plan_docs_qr_fix.py
           Otherwise -> technical_writer/plan_docs_execute.py
  Output: code_changes diffs amended with documentation; README.md changes added;
          diagram_graphs.ascii_render populated for each diagram
  Next: Step 12

Step 12: plan-docs-qr-decompose
  Agent: quality-reviewer
  Script: quality_reviewer/plan_docs_qr_decompose.py
  Output: qr-plan-docs.json with items (status: TODO)
  Output: parallel_dispatch block listing all --qr-item IDs
  Next: Step 13

Step 13: plan-docs-qr-verify
  Agent: quality-reviewer (N parallel instances)
  Script: quality_reviewer/plan_docs_qr_verify.py --qr-item {id}
  Output: Each agent updates one item in qr-plan-docs.json to PASS/FAIL
  Next: Step 14

Step 14: plan-docs-qr-route
  Route: All PASS -> delete qr file, PLAN APPROVED
         Any FAIL -> loop to Step 11
```

### Execution Workflow (orchestrator/executor.py)

10 steps. Implements the approved plan.

```
Step 1: exec-init
  Action: Analyze plan, build wave dependency graph

Step 2: impl-code-work
  Agent: developer (up to 4 parallel per wave)
  Script: developer/exec_implement.py (router)
  Routing: If qr-impl-code.json has FAIL items -> developer/exec_implement_qr_fix.py
           Otherwise -> developer/exec_implement_execute.py
  Output: Code changes applied to files
  Next: Step 3

Step 3: impl-code-qr-decompose
  Agent: quality-reviewer
  Script: quality_reviewer/impl_code_qr_decompose.py
  Output: qr-impl-code.json with items (status: TODO)
  Output: parallel_dispatch block listing all --qr-item IDs
  Next: Step 4

Step 4: impl-code-qr-verify
  Agent: quality-reviewer (N parallel instances)
  Script: quality_reviewer/impl_code_qr_verify.py --qr-item {id}
  Output: Each agent updates one item in qr-impl-code.json to PASS/FAIL
  Next: Step 5

Step 5: impl-code-qr-route
  Route: All PASS -> delete qr file, proceed to Step 6
         Any FAIL -> loop to Step 2

Step 6: impl-docs-work
  Agent: technical-writer
  Script: technical_writer/exec_docs.py (router)
  Routing: If qr-impl-docs.json has FAIL items -> technical_writer/exec_docs_qr_fix.py
           Otherwise -> technical_writer/exec_docs_execute.py
  Output: Documentation written to files
  Next: Step 7

Step 7: impl-docs-qr-decompose
  Agent: quality-reviewer
  Script: quality_reviewer/impl_docs_qr_decompose.py
  Output: qr-impl-docs.json with items (status: TODO)
  Output: parallel_dispatch block listing all --qr-item IDs
  Next: Step 8

Step 8: impl-docs-qr-verify
  Agent: quality-reviewer (N parallel instances)
  Script: quality_reviewer/impl_docs_qr_verify.py --qr-item {id}
  Output: Each agent updates one item in qr-impl-docs.json to PASS/FAIL
  Next: Step 9

Step 9: impl-docs-qr-route
  Route: All PASS -> delete qr file, proceed to Step 10
         Any FAIL -> loop to Step 6

Step 10: wave-next
  Action: Advance to next wave, repeat Steps 2-9 for each wave
  Route: More waves -> loop to Step 2
         All waves complete -> EXECUTION COMPLETE
```

## Script Organization

Scripts follow router-dispatch pattern. Each QR-able phase has:

- Router script: Detects state, dispatches to appropriate workflow
- Execute script: First-time execution workflow
- QR fix script: Post-QR failure fix workflow
- QR decompose script: Creates verification items
- QR verify script: Verifies single item (called with --qr-item)

```
skills/planner/
  orchestrator/
    planner.py       -- 14-step planning workflow
    executor.py      -- 12-step execution workflow
  architect/
    plan_design.py            -- router (detects state, dispatches)
    plan_design_execute.py    -- first execution (6 steps)
    plan_design_qr_fix.py     -- post-QR fix workflow
  developer/
    plan_code.py              -- router
    plan_code_execute.py      -- first execution (4 steps)
    plan_code_qr_fix.py       -- post-QR fix workflow
    exec_implement.py         -- router
    exec_implement_execute.py -- implementation (4 steps)
    exec_implement_qr_fix.py  -- post-QR fix workflow
  technical_writer/
    plan_docs.py              -- router
    plan_docs_execute.py      -- first execution (6 steps)
    plan_docs_qr_fix.py       -- post-QR fix workflow
    exec_docs.py              -- router
    exec_docs_execute.py      -- impl-docs (6 steps)
    exec_docs_qr_fix.py       -- post-QR fix workflow
  quality_reviewer/
    plan_design_qr_decompose.py -- decomposition workflow
    plan_design_qr_verify.py    -- single-item verification
    plan_code_qr_decompose.py   -- decomposition workflow
    plan_code_qr_verify.py      -- single-item verification
    plan_docs_qr_decompose.py   -- decomposition workflow
    plan_docs_qr_verify.py      -- single-item verification
    impl_code_qr_decompose.py   -- decomposition workflow
    impl_code_qr_verify.py      -- single-item verification
    impl_docs_qr_decompose.py   -- decomposition workflow
    impl_docs_qr_verify.py      -- single-item verification
  shared/
    schema.py         -- Pydantic v2 schemas (context, plan, qr), validation
    resources.py      -- Path helpers, resource provider
    constraints.py    -- Constraint builders
    gates.py          -- Gate output builder
    qr/               -- QR subsystem utilities
      utils.py        -- QR state loading, item extraction
```

## CLI Interface

All scripts accept a common set of arguments. QR-related state is file-based, not CLI-based.

**Universal arguments (all scripts):**

| Argument      | Required | Description                     |
| ------------- | -------- | ------------------------------- |
| `--step`      | Yes      | Current step number (1-indexed) |
| `--state-dir` | Yes\*    | Path to state directory         |

\*Step 1 of orchestrators creates state_dir; subsequent steps require it.

**QR verify arguments:**

| Argument     | Required | Description                                     |
| ------------ | -------- | ----------------------------------------------- |
| `--qr-item`  | Yes\*    | Single item ID to verify (e.g., qa-001)         |
| `--qr-items` | Yes\*    | Comma-separated item IDs for batch verification |

\*One of --qr-item or --qr-items required. Batch verification (--qr-items) groups semantically related items for a single agent, enabling parallel dispatch where each agent handles one batch.

**Gate step arguments:**

| Argument      | Required | Description                                          |
| ------------- | -------- | ---------------------------------------------------- |
| `--qr-status` | Yes      | Aggregated verdict from verify agents: "pass"/"fail" |

**Explicitly forbidden arguments:**

| Argument         | Why forbidden                                      |
| ---------------- | -------------------------------------------------- |
| `--qr-fail`      | QR file path is computable from state_dir + phase  |
| `--qr-iteration` | Iteration is stored in qr-{phase}.json, not passed |

The orchestrator never passes failure paths or iteration counts. Routers and fix scripts read this information from qr-{phase}.json directly.

## Invariants

**Sub-agents cannot launch sub-agents**. Only orchestrator dispatches. Maintains audit trail, prevents hidden dependencies.

**Sub-agents cannot invoke AskUserQuestion**. Sub-agents that need user input yield with `<needs_user_input>` XML. Orchestrator relays question, then reinvokes sub-agent fresh with answer. Sub-agents cannot be resumed; they must be reinvoked with context restored from state files.

**Orchestrator LLM never reads/writes state files**. The orchestrator LLM agent must not use Read(), Write(), or Edit() tools on state files (plan.json, context.json, qr-{phase}.json). Context flows through dispatch prompts. State files are sub-agent territory.

Note: The orchestrator Python script (planner.py, executor.py) may read state files internally for reliable orchestration -- e.g., `load_qr_state()` to determine which QR items remain for dispatch. This is implementation machinery invisible to the LLM. The invariant applies to the LLM agent, not the Python code that generates prompts.

**Orchestrator is a dumb dispatcher**. The orchestrator routes based on status flags (pass/fail) and step numbers. It never makes quality judgments ("the plan looks comprehensive"), never decides to "proceed anyway" when protocol requires iteration, and never skips steps based on subjective assessment. If a sub-agent returns invalid output or the workflow requires iteration, the orchestrator follows the protocol mechanically.

**Sub-agent self-validation**. Every sub-agent that writes to state files (plan.json, qr-{phase}.json) must validate the written file before returning to orchestrator. The final step of any state-mutating workflow:

1. Loads the file just written
2. Validates against Pydantic schema via `validate_state()`
3. If invalid: fixes in-place, re-validates, loops until valid
4. If valid: formats final output and returns

The orchestrator must never see schema validation errors. Philosophy: detect problems IMMEDIATELY after they happen, at the source. Validation failures are sub-agent bugs to be fixed before handoff, not orchestrator concerns.

This applies to both execute and fix workflows. After the architect writes plan.json, it validates. After the QR fix agent updates plan.json, it validates. The orchestrator receives only valid state.

**User authority is absolute**. Agent findings may be wrong. User decisions override everything.

**Always run scripts**. Every step invokes a Python script. No free-form execution. Scripts emit prompts; LLM performs work. Router scripts dispatch to workflow scripts; this is still script-based execution.

**Router dispatch at step 1 only**. Router scripts detect state (qr-{phase}.json existence and contents) at step 1 and dispatch to the appropriate workflow script. Subsequent steps within a workflow script MUST NOT dispatch to other scripts.

**State detection over flags**. Work scripts detect their mode from state file presence, not from CLI flags. If qr-{phase}.json exists and has FAIL items, the router dispatches to the fix workflow. Orchestrator dispatches to the same step number regardless of mode.

**No distributed QR state**. All QR state lives in qr-{phase}.json. CLI flags for QR fail path (--qr-fail) and iteration count (--qr-iteration) MUST NOT exist. The decompose step reads/increments iteration from file; routers compute qr file path from state_dir + phase. Only --qr-status (orchestrator's aggregated verdict) and --qr-item (verify agent's assigned item) are valid QR-related CLI args.

**Adaptive item generation**. Decomposition creates as many items as the content requires. No fixed counts or caps. The 8-step workflow naturally terminates when structural enumeration is exhausted and coverage is validated. Item count varies by plan complexity.

**QR decompose output contract**. Decompose scripts MUST output a `<parallel_dispatch>` block that orchestrator parses to launch N verify agents. Dispatch blocks are generated via the AST module at `lib/workflow/ast/` using three node types:

- `SubagentDispatchNode`: Single agent dispatch (sequential workflows)
- `TemplateDispatchNode`: Parallel dispatch with parameterized template (SIMD pattern)
- `RosterDispatchNode`: Parallel dispatch with unique prompts (MIMD pattern)

Rendered format:

```xml
<parallel_dispatch agent="quality-reviewer" count="N">
  <groups>
    <group id="component-auth" items="qa-001,qa-002,qa-003">Auth component checks</group>
    <group id="umbrella" items="qa-010,qa-011">Cross-cutting checks</group>
  </groups>
  <template>
    <invoke cmd="python3 -m skills.planner.quality_reviewer.{phase}_qr_verify --step 1 --state-dir {state_dir} --qr-items $GROUP_ITEMS" />
  </template>
</parallel_dispatch>
```

**QR file lifecycle**. qr-{phase}.json is created by decompose step, updated by verify agents, deleted by route step on PASS. The file's existence signals "QR in progress"; its absence signals "no QR done yet" or "QR passed and cleaned up".

**QR iteration limit**. Maximum 5 iterations per QR phase. All severity levels block on all iterations.

## QR Workflow

Each QR block consists of 4 orchestrator steps:

**Decompose step (1 sub-agent):**

```
python3 -m skills.planner.quality_reviewer.<phase>_qr_decompose --step 1 --state-dir {state_dir}
```

Sub-agent explores the artifact being reviewed using an 8-step cognitive workflow, generates verification items adaptively (quantity determined by content, not preset bounds), writes qr-{phase}.json with all items status: TODO. Outputs parallel_dispatch block for orchestrator to parse.

### 8-Step Decomposition Workflow

The decomposition follows a top-down-then-bottom-up approach to generate verification items. Holistic brainstorming captures cross-cutting concerns that structural enumeration misses (overall approach validity, implicit requirements, integration risks). Structural enumeration then serves as completeness validation, not the generative source.

**Step 1: Absorb Context**
Read plan.json and context.json. Summarize understanding in 2-3 sentences. Establishes what the plan accomplishes and what success looks like for this phase. No items generated yet.

**Step 2: Holistic Concerns (Top-Down)**
Brainstorm freely: "If reviewing this phase output, what would I check?" Captures high-level validity, cross-cutting patterns, quality aspects, and risks. Output is an unfiltered bulleted list of concerns. This step identifies what structural enumeration cannot see.

**Step 3: Structural Enumeration (Bottom-Up)**
List what EXISTS in the plan for this phase. Phase-specific: decisions/constraints/risks for plan-design, code_changes for plan-code, acceptance_criteria for impl-code. Output is a structured enumeration with IDs and counts. This becomes the completeness checklist in Step 7.

**Step 4: Gap Analysis**
Compare Step 2 concerns vs Step 3 elements. Identify which concerns need umbrella items (cross-cutting), which map to specific elements, which elements need targeted items, and gaps in both directions.

**Step 5: Generate Initial Items**
Create items using the umbrella + specific pattern. Critical concerns get BOTH a broad catch-all item (scope: "\*") AND specific targeted items (scope: element reference). This intentional overlap ensures outliers are caught by umbrellas while known-critical aspects get explicit verification. Overlapping coverage is acceptable; gaps are not. No fixed item counts -- generate what the content requires.

**Step 6: Atomicity Check**
Review each item: tests exactly one thing? An item is ATOMIC if pass/fail is unambiguous and it cannot be "half passed". Non-atomic items are acceptable as umbrellas if they catch outliers.

Split criteria: Only split if the item is BOTH non-atomic AND critical. Critical determination:

- Related to MUST-severity concerns: knowledge loss, production reliability
- Architectural decisions in planning_context
- Cross-cutting error handling or security
- Public API contract changes

Non-critical concerns (internal implementation details, formatting, optimizations) remain as umbrellas for broader coverage.

When splitting: create specific items AND keep the umbrella.

**Step 7: Coverage Validation**
Use Step 3 enumeration as checklist. For each element: at least one covering item? For each concern: at least one addressing item? If uncertain, ADD an item. Overlap is preferred over gaps.

**Step 8: Finalize and Write**
Write qr-{phase}.json with final items. Output parallel_dispatch block. Item count is whatever emerged from the process -- no targets, no caps. Content determines quantity.

### Adaptive Item Generation

The workflow produces variable item counts based on plan complexity. Simple phases with few decisions and straightforward code_changes yield fewer items. Complex phases with many architectural decisions, cross-cutting concerns, and intricate code patterns yield more items.

The 8-step workflow provides natural termination without artificial bounds:

- Step 3 bounds items to what actually exists in the plan
- Step 7 terminates when the checklist is complete
- Umbrella items cover multiple concerns without 1:1 expansion

More items with overlap is preferred over fewer items with gaps.

**Verify step (N sub-agents, parallel):**

```
python3 -m skills.planner.quality_reviewer.<phase>_qr_verify --step 1 --state-dir {state_dir} --qr-items qa-001,qa-002
```

Each sub-agent receives a batch of semantically related items to verify. Items are grouped by the decompose step (e.g., by component, by concern, or parent-child relationships). The agent reads the qr file, verifies each assigned item, and updates status to PASS or FAIL with finding.

**Output contract**: Verify agents MUST conclude with exactly one of:

- `PASS` -- item verified successfully
- `FAIL: <reason>` -- item failed verification, reason required

Orchestrator parses this via LLM comprehension, not programmatically. Malformed output is treated as FAIL.

**Route step (orchestrator only):**

The orchestrator script (not the LLM) reads qr-{phase}.json after all verify agents complete, using helper functions to check for remaining failures:

```python
def get_pending_qr_items(state_dir: str, phase: str) -> list[str]:
    """Return item IDs that need processing (status TODO or FAIL)."""
```

The script determines the routing and generates the appropriate prompt for the LLM. The LLM sees only the routing decision, not the file contents.

If no failures: delete qr file, proceed to next block.
If failures exist: loop back to work step. The work step's router will detect qr-{phase}.json with FAIL items and dispatch to the fix workflow.

**Fix workflow (via router):**

When orchestrator loops back to work step (e.g., step 3), the router script:

1. Checks for qr-{phase}.json
2. If exists with FAIL items -> dispatch to {phase}\_qr_fix.py
3. Fix script loads failed items, guides agent to fix issues
4. Agent validates state file after fixes (same self-validation requirement as execute workflow)
5. After fixes and validation, workflow continues to decompose step (fresh QR)

## Context Handover

Context is lost when orchestrator launches a sub-agent. The dispatch prompt must include all necessary context. Sub-agent reads state files for full detail.

Context categories for dispatch:

- Task Specification: what we're building, scope, out-of-scope
- Constraints: MUST/SHOULD/MUST-NOT
- Entry Points: where to start exploring
- Rejected Alternatives: what was dismissed and why
- Assumptions: inferences not verified
- Invisible Knowledge: rationale, invariants, tradeoffs
- User Quotes: verbatim user statements, especially corrections

Handover prompts should be concise. Initial handover (step 2->3) includes full detail. Subsequent handovers can be terse since sub-agents read state files.

**CLI mutation commands in prompts**: Sub-agents that mutate state files must have the relevant CLI commands surfaced in their prompts. The agent cannot use tools it doesn't know about. Scripts emit CLI usage examples as part of the prompt:

| Sub-agent | CLI commands to surface                                                |
| --------- | ---------------------------------------------------------------------- |
| architect | `cli.plan set-milestone`, `set-intent`, `set-decision`, `set-diagram`, |
|           | `add-diagram-node`, `add-diagram-edge`                                 |
| developer | `cli.plan set-change`                                                  |
| tw        | `cli.plan set-doc`, `set-diagram-render`                               |
| qr-verify | `cli.qr update-item`                                                   |

Example prompt fragment for architect:

```
State Mutation:
  python3 -m skills.planner.cli.plan --state-dir {state_dir} set-intent \
      --milestone M-001 --file path.py --behavior "description"
```

## Question Relay

When sub-agent needs user input:

1. Sub-agent saves state to plan.json
2. Sub-agent emits `<needs_user_input>` XML and stops
3. Orchestrator detects XML, extracts questions
4. Orchestrator calls AskUserQuestion
5. User responds
6. Orchestrator reinvokes sub-agent fresh with accumulated Q&A history in an extra prompt field
7. New sub-agent reads plan.json, continues with user's answers

On reinvocation, answers are provided in a `<user_response>` block:

```xml
<user_response>
  <answer header="Auth">JWT with refresh tokens</answer>
  <answer header="Scope">Not in initial implementation</answer>
</user_response>
```

Sub-agents cannot be resumed. They must be reinvoked fresh with explicit state file reading.
