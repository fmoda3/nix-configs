# Workflow Framework

## Overview

Framework for skill registration and testing. Skills are defined using the `Workflow` class with `StepDef` instances - a data-driven approach where transitions are explicit data structures.

## Architecture

```
Skills Layer (12 modules)
       |
       v
   Workflow API (Workflow/StepDef/Outcome)
       |
       v
Discovery Layer (importlib scanning)
       |
       v
Core Framework (types, registry, ResourceProvider)
       |
       v
CLI / Test Harness
```

### Data Flow

```
CLI invocation
      |
      v
discover_workflows() -> scan skills/ -> build registry
      |
      v
Workflow.run(step_id) -> STEPS[step_id].handler(context)
      |
      v
StepOutput (title, actions, next_command)
```

Discovery uses importlib scanning to find workflows without executing module-level code. This pull-based approach eliminates import-time side effects and enables isolated testing.

## Core Types

### Outcome Enum

Separates "what outcome?" from "where next?" to make transition graphs introspectable as data:

```python
class Outcome(str, Enum):
    OK = "ok"           # Success, proceed to next
    FAIL = "fail"       # Failure, may trigger error handling
    SKIP = "skip"       # Skip branch (used for mode branching)
    ITERATE = "iterate" # Continue loop (used for confidence progression)
    DEFAULT = "_default" # Fallback if specific outcome not mapped
```

**Why not booleans?** Booleans force transitions into code logic. Outcomes make the transition graph data that can be validated, visualized, and reasoned about.

**Example**: Without Outcome, mode branching requires:

```python
if mode == "quick":
    return "step_11"  # Implicit meaning
else:
    return "step_5"   # What does this mean? Success? Skip?
```

With Outcome:

```python
def step_planning(ctx):
    if ctx.workflow_params["mode"] == "quick":
        return Outcome.SKIP, {}  # Explicit: skipping this branch
    return Outcome.OK, {}        # Explicit: proceeding normally

StepDef(id="planning", next={
    Outcome.OK: "subagent_design",      # Full mode path
    Outcome.SKIP: "initial_synthesis",  # Quick mode path
})
```

The transition graph is now visible in the StepDef, not buried in handler logic.

### StepContext

Runtime state container passed to handlers, enabling stateful iteration:

```python
@dataclass
class StepContext:
    step_id: str                         # Current step identifier
    workflow_params: dict[str, Any]      # Immutable workflow parameters (--mode, --decision)
    step_state: dict[str, Any]           # Mutable state (iteration count, confidence level)
```

**Why separate params and state?**

- `workflow_params`: Set at workflow start, never change (e.g., mode, input paths)
- `step_state`: Updated by handlers, carries iteration state between steps

**Example - Confidence-driven iteration**:

```python
def step_investigate(ctx: StepContext) -> tuple[Outcome, dict]:
    iteration = ctx.step_state.get("iteration", 1)
    confidence = ctx.workflow_params.get("confidence", "exploring")

    if confidence == "high":
        return Outcome.OK, {"confidence": confidence}
    elif iteration >= MAX_ITERATIONS:
        return Outcome.OK, {"confidence": "capped"}
    else:
        return Outcome.ITERATE, {"iteration": iteration + 1}

StepDef(id="investigate", handler=step_investigate,
        next={Outcome.OK: "formulate", Outcome.ITERATE: "investigate"})
```

### Handler Signature

Handlers process step logic and return next outcome:

```python
def handler(ctx: StepContext) -> tuple[Outcome, dict]:
    # Access workflow parameters (immutable)
    mode = ctx.workflow_params.get("mode", "full")

    # Access step state (from previous iterations)
    iteration = ctx.step_state.get("iteration", 1)

    # Perform step logic...

    # Return outcome and updated state
    return Outcome.OK, {"iteration": iteration + 1}
```

**Why return state dict?** Handlers are pure functions. Returning state rather than mutating context makes flow explicit and testable.

**Output-only steps**: Steps that just print instructions can use a no-op handler:

```python
def step_handler(ctx: StepContext) -> tuple[Outcome, dict]:
    return Outcome.OK, {}
```

### Arg (Parameter Metadata)

Annotates handler parameters for testing:

```python
@dataclass(frozen=True)
class Arg:
    description: str = ""
    default: Any = inspect.Parameter.empty
    min: int | float | None = None
    max: int | float | None = None
    choices: tuple[str, ...] | None = None
    required: bool = False
```

**Usage**:

```python
from typing import Annotated

def step_handler(
    ctx: StepContext,
    mode: Annotated[str, Arg(description="Workflow mode", choices=("quick", "full"))] = "full"
) -> tuple[Outcome, dict]:
    ...
```

The `Arg` metadata is extracted during workflow validation for testing.

### Dispatch vs Callable Handlers

**Callable handler**: Inline Python function (most common)

```python
def step_analyze(ctx: StepContext) -> tuple[Outcome, dict]:
    # Analysis logic here
    return Outcome.OK, {}

StepDef(id="analyze", handler=step_analyze, ...)
```

**Dispatch handler**: Delegates to sub-agent script (for QR gates, parallel agents)

```python
from skills.lib.workflow.types import Dispatch, AgentRole

StepDef(
    id="qr_completeness",
    handler=Dispatch(
        agent=AgentRole.QUALITY_REVIEWER,
        script="skills.planner.qr.plan_completeness",
    ),
    next={Outcome.OK: "implementation", Outcome.FAIL: "revise_plan"}
)
```

The `Dispatch` handler tells the orchestrator to:

1. Launch the specified agent with the script
2. Wait for completion
3. Map the agent's result to an Outcome

**When to use Dispatch?**

- QR gates (quality reviewer checks)
- Parallel sub-agent execution
- Complex sub-workflows that need separate scripts

## Workflow Validation

`Workflow.__init__` performs 5 validation checks:

1. **Entry point exists**: The `entry_point` step ID must be in the workflow
2. **All transition targets exist**: Every target in `next` dicts must be a valid step ID or `None` (terminal)
3. **At least one terminal step**: At least one step must have `None` in its `next` dict
4. **All steps reachable**: Every step must be reachable from the entry point (detects orphaned steps)
5. **Parameter extraction**: Extract `Arg` metadata from handler signatures for testing

These checks run at registration time, catching errors early.

## Workflow Example

```python
from skills.lib.workflow import discover_workflows
from skills.lib.workflow.core import (
    Workflow, StepDef, StepContext, Outcome, Arg
)

def step_handler(ctx: StepContext) -> tuple[Outcome, dict]:
    return Outcome.OK, {}

WORKFLOW = Workflow(
    "decision-critic",
    StepDef(
        id="extract_structure",
        title="Extract Structure",
        actions=[...],
        handler=step_handler,
        next={Outcome.OK: "classify_verifiability"},
    ),
    StepDef(
        id="classify_verifiability",
        title="Classify Verifiability",
        actions=[...],
        handler=step_handler,
        next={Outcome.OK: "generate_questions"},
    ),
    # ... remaining steps
    description="Structured decision criticism workflow",
)

# Workflow discovery happens via discover_workflows('skills')
# No registration needed - WORKFLOW constant is read directly
# Pull-based discovery eliminates import-time side effects (Milestone 1)
```

Benefits of this architecture:

- Steps and transitions together in data structure
- Transitions explicit and validatable
- Workflow structure introspectable and validatable
- Transition graph introspectable

## Invariants

- **INVARIANT 1**: Every skill entry point defines exactly ONE Workflow
- **INVARIANT 2**: discover_workflows() finds all Workflows without import errors
- **INVARIANT 3**: Dispatcher routing produces same output as old if-step chains
- **INVARIANT 4**: ResourceProvider protocol supports all 5 access patterns (conventions, file I/O, resources, Workflow objects, step data)
- **INVARIANT 5**: QR iteration blocking severities: iter 1-2 block all; iter 3-4 block MUST/SHOULD; iter 5+ block MUST only

## Design Decisions

**Why separate Workflow and StepDef?** Workflows are collections; steps are atomic units. Separation allows validation at workflow level (reachability, terminals) while keeping step definitions focused.

**Why frozen dataclasses?** Workflows and StepDefs are immutable specifications. Frozen dataclasses prevent accidental mutation and make them safe to share across threads.

**Why handler callables instead of strings?** Type safety, IDE support, and easier refactoring. Handlers are first-class functions, not magic strings.

**Separate CLI entry points**: Running modules as `__main__` causes module identity issues (imported by `__init__.py` vs executed as `__main__`). Separate CLI entry points avoid this.

## Tradeoffs

**Idiomatic API vs Minimal**: Higher refactoring scope for consistent architecture across all skills. The think.py pattern proves Workflow/StepDef API works; extending it creates consistency without inventing new abstractions.

**Centralized enums vs Local**: One more place to update for discoverability and shared understanding. Enums (LoopState, DocumentAvailability) make state machines explicit and enable property-based testing.

**Clean break vs Dual-path**: Simpler implementation at cost of no migration period. Refactoring scope is internal (no external callers) so clean break reduces total work and eliminates transition bugs.

## Common Patterns

### Pattern 1: Linear Workflow

```python
WORKFLOW = Workflow(
    "skill-name",
    StepDef(id="step1", title="...", actions=[...],
            handler=step_handler, next={Outcome.OK: "step2"}),
    StepDef(id="step2", title="...", actions=[...],
            handler=step_handler, next={Outcome.OK: "step3"}),
    StepDef(id="step3", title="...", actions=[...],
            next={Outcome.OK: None}),  # terminal
)
```

### Pattern 2: Confidence-Driven Iteration

```python
def step_investigate(ctx: StepContext) -> tuple[Outcome, dict]:
    iteration = ctx.step_state.get("iteration", 1)
    confidence = ctx.workflow_params.get("confidence", "exploring")

    if confidence == "high":
        return Outcome.OK, {"confidence": confidence}
    elif iteration >= MAX_ITERATIONS:
        return Outcome.OK, {"confidence": "capped"}
    else:
        return Outcome.ITERATE, {"iteration": iteration + 1}

StepDef(id="investigate", handler=step_investigate,
        next={
            Outcome.OK: "formulate",       # exit loop
            Outcome.ITERATE: "investigate"  # continue loop
        })
```

### Pattern 3: Mode Branching

```python
def step_planning(ctx: StepContext) -> tuple[Outcome, dict]:
    mode = ctx.workflow_params.get("mode", "full")
    if mode == "quick":
        return Outcome.SKIP, {}
    return Outcome.OK, {}

StepDef(id="planning", handler=step_planning,
        next={
            Outcome.OK: "subagent_design",      # full mode
            Outcome.SKIP: "initial_synthesis",  # quick mode
        })
```

### Pattern 4: QR Gate

```python
from skills.lib.workflow.types import Dispatch, AgentRole

StepDef(
    id="qr_completeness",
    title="QR: Plan Completeness",
    actions=[...],
    handler=Dispatch(
        agent=AgentRole.QUALITY_REVIEWER,
        script="skills.planner.qr.plan_completeness",
    ),
    next={
        Outcome.OK: "implementation",   # QRStatus.PASS -> Outcome.OK
        Outcome.FAIL: "revise_plan",    # QRStatus.FAIL -> Outcome.FAIL
    },
)
```

### Pattern 5: Hybrid Static/Dynamic Steps (deepthink)

Workflows with mostly static steps and few parameterized steps benefit from a hybrid approach:

```python
# ============================================================================
# MESSAGE BUILDERS
# ============================================================================

def build_dispatch_body() -> str:
    """Builder functions that dynamic formatters may call."""
    # ... implementation
    return dispatch_text


# ============================================================================
# STEP DEFINITIONS
# ============================================================================

# Static steps: (title, instructions) tuples
STATIC_STEPS = {
    1: ("Context Clarification", CONTEXT_CLARIFICATION_INSTRUCTIONS),
    2: ("Abstraction", ABSTRACTION_INSTRUCTIONS),
    # ... more static steps
}


# Dynamic formatter functions - defined BEFORE DYNAMIC_STEPS dict
def _format_step_9(mode: str, confidence: str, iteration: int) -> tuple[str, str]:
    """Dynamic step that calls a builder function."""
    return ("Dispatch", build_dispatch_body())


def _format_step_13(mode: str, confidence: str, iteration: int) -> tuple[str, str]:
    """Dynamic step with parameterized title and body."""
    suffix = " -> Complete" if confidence == "certain" else ""
    title = f"Iterative Refinement (Iteration {iteration}){suffix}"
    body = INSTRUCTIONS.format(iteration=iteration, max_iter=MAX_ITERATIONS)
    return (title, body)


# Dynamic steps dict - references functions defined above
DYNAMIC_STEPS = {
    9: _format_step_9,
    13: _format_step_13,
}


# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

def format_output(step: int, mode: str, confidence: str, iteration: int) -> str:
    """Callable dispatch: static lookup or dynamic function call."""
    if step in STATIC_STEPS:
        title, instructions = STATIC_STEPS[step]
    elif step in DYNAMIC_STEPS:
        title, instructions = DYNAMIC_STEPS[step](mode, confidence, iteration)
    else:
        return f"ERROR: Invalid step {step}"

    next_cmd = build_next_command(step, mode, confidence, iteration)
    return format_step(instructions, next_cmd or "", title=f"WORKFLOW - {title}")
```

**Ordering constraint (book pattern)**: Dynamic formatter functions that call MESSAGE BUILDERS must appear AFTER MESSAGE BUILDERS. The DYNAMIC_STEPS dictionary must appear AFTER all `_format_step_*` functions it references.

Use this pattern when:

- Many steps share the same structure (title + constant body)
- Few steps need parameters for title or body construction
- Parameters are uniform across all dynamic steps

Benefits:

- Compact representation for static steps (one line per step)
- Clear, readable functions for dynamic steps
- Single dispatch point in `format_output()`
- Follows "book pattern" (all references resolve to definitions above)

## Question Relay Protocol

Sub-agents can request user clarification via the main agent. The protocol is
pure prompt coordination -- no Python interception.

### Design Decisions

**Task Reinvocation (not Resume)**: When a sub-agent yields with questions,
the orchestrator REINVOKES it fresh (new Task, no resume parameter) after
getting user answers. The sub-agent saves state to plan.json before yielding,
then reads it back after reinvocation. This was chosen over resume because:

- Resume semantics are unreliable (0 tokens, 0 tool uses failures)
- State file reading is explicit and auditable
- Clean slate avoids stale context issues
- Sub-agent scripts can detect continuation (plan.json exists)

**Questions-only output**: When a sub-agent needs clarification, it emits ONLY
the `<needs_user_input>` XML block. Nothing else. This makes detection
unambiguous -- no heuristic parsing of natural language.

**Explicit XML markers**: We use structured XML tags rather than detecting
question marks in prose. This prevents false positives from rhetorical questions
in analysis output.

**Max 3 questions, 2-3 options**: Constraints match AskUserQuestion tool schema.
Batching reduces round-trips. Options should be distinct and actionable.

**State saving before yield**: Sub-agents MUST save all progress to plan.json
before emitting `<needs_user_input>`. The reinvoked instance reads this state.

### Flow

1. Sub-agent saves current state to plan.json
2. Sub-agent emits `<needs_user_input>` XML as entire response
3. Main agent extracts questions, calls AskUserQuestion
4. Main agent REINVOKES sub-agent fresh with answers and STATE_DIR
5. New sub-agent instance reads plan.json, continues from saved state

### Constants

| Constant                    | Purpose                                  |
| --------------------------- | ---------------------------------------- |
| `SUB_AGENT_QUESTION_FORMAT` | Tells sub-agent how to emit questions    |
| `QUESTION_RELAY_HANDLER`    | Tells main agent how to detect and relay |

### Integration

For dispatch steps that support question relay:

```python
from skills.lib.workflow.constants import QUESTION_RELAY_HANDLER

# In format_output or step handler for dispatch steps:
if step_info.get("supports_questions"):
    actions.append(QUESTION_RELAY_HANDLER)
```

For sub-agent scripts that may ask questions:

```python
from skills.lib.workflow.constants import SUB_AGENT_QUESTION_FORMAT

# In step 1 guidance:
actions.append(SUB_AGENT_QUESTION_FORMAT)
```

## Invariants

- Every skill module appears in `SKILL_MODULES` in `tests/conftest.py`
- Workflow validation must pass (entry point exists, all transitions valid, at least one terminal, all steps reachable)
- Handler signatures must match `(ctx: StepContext) -> tuple[Outcome, dict]` or be a `Dispatch` instance
- `next` dict keys must be `Outcome` enum values
- `next` dict values must be valid step IDs or `None` (terminal)

## Exhaustive Testing Framework

Exhaustive testing framework generates all valid parameter combinations for workflow steps, using typed domain abstractions to represent parameter spaces.

### Architecture

```
Workflow AST          Domain Types           Test Generation
     |                     |                       |
     v                     v                       v
+----------+        +-------------+         +--------------+
| Workflow |  --->  | BoundedInt  |  --->   | generate_    |
| _params  |        | ChoiceSet   |         | test_inputs  |
| _step_   |        | Constant    |         +--------------+
|  order   |        +-------------+                |
+----------+                                       v
                                           +-------------+
                                           | pytest      |
                                           | parametrize |
                                           +-------------+
```

### Why This Structure

Domain types separate from generation logic:

- Domains are reusable (could drive fuzzing, documentation)
- Generation logic depends on workflow structure, not domain semantics
- Test file adds pytest-specific concerns

### Data Flow

1. Import skills -> Workflow objects registered
2. extract_schema(workflow) -> {step: {param: Domain}}
3. generate_inputs(workflow) -> Iterator[dict] (Cartesian product)
4. pytest.parametrize -> test cases with IDs
5. run_skill_invocation(workflow, params) -> subprocess exit code

### Key Design Decisions

**Exhaustive vs sampling**: Domains are small (5 iterations x 5 confidences x 2 modes = ~300-500 total). Exhaustive enumeration is tractable and provides complete coverage. Sampling would miss edge combinations.

**Hardcoded mode-gating**: Only deepthink has mode parameter (quick mode skips steps 6-11). Introspection complexity not justified for single case. Explicit hardcoding is clearer and maintainable.

**Iteration detection**: Step.next dict contains Outcome.ITERATE for self-looping steps. Direct check without heuristics works for all current and future iterating workflows.

**Step-index mapping**: \_params keyed by step_id (string) not step number. \_step_order provides authoritative index for CLI invocation.

### Invariants

- Each test case must have unique ID (workflow-step-params combo)
- Conditional params only apply to applicable steps (iteration only at iterating steps)
- Mode-gated steps skipped when mode value gates them out
- step param always present (1 to total_steps)
- total_steps always matches workflow.total_steps
- Workflow.\_step_order must provide authoritative step index mapping: len(\_step_order) == total_steps and indices correspond to CLI --step values

### Domain Types

Located in types.py:

**BoundedInt**: Integer domain with inclusive bounds [lo, hi]

```python
list(BoundedInt(1, 5))  # [1, 2, 3, 4, 5]
```

**ChoiceSet**: Discrete choice domain

```python
list(ChoiceSet(("full", "quick")))  # ["full", "quick"]
```

**Constant**: Single-value domain

```python
list(Constant(42))  # [42]
```

All implement **iter** for use with itertools.product. frozen=True enables hashability for pytest param caching.

## Testing

All tests use pytest. Run from `skills/scripts/`:

```bash
# Run all tests
pytest tests/ -v

# Test specific workflow
pytest tests/ -k deepthink -v

# Test categories
pytest tests/test_workflow_import.py -v     # Import tests
pytest tests/test_workflow_structure.py -v  # Structure validation
pytest tests/test_workflow_steps.py -v      # Step invocability (exhaustive)
pytest tests/test_domain_types.py -v        # Domain type unit tests
```
