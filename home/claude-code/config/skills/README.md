# Skills Architecture

Script-based agent workflows with shared orchestration framework.

## File Organization: The "Book" Pattern

Skill files read top-to-bottom like a book. Dependencies are defined before use. The ordering principle: **a reader should never need to scroll up to understand what they're reading.**

### Section Order

Files use a fixed section sequence. Group by type, not by step. Within each type-group, order by workflow step. Omit sections with no content.

```python
# ============================================================================
# SHARED PROMPTS
# ============================================================================
# Prompts used by 2+ workflow steps. If large, extract to prompts/shared.py

# ============================================================================
# CONFIGURATION
# ============================================================================
# Constants, temperatures, thresholds

# ============================================================================
# SYSTEM PROMPTS
# ============================================================================

# ============================================================================
# MESSAGE TEMPLATES
# ============================================================================
# Step-delimited subsections (see below)

# ============================================================================
# PARSING FUNCTIONS
# ============================================================================

# ============================================================================
# MESSAGE BUILDERS
# ============================================================================
# Functions that compose templates into complete messages

# ============================================================================
# [DOMAIN] LOGIC
# ============================================================================
# Domain-specific (utility) functions

# ============================================================================
# WORKFLOW
# ============================================================================
# Entry points: run_discovery(), run_ideation(), etc.
```

Rationale: functions often reference prompts from multiple steps. Grouping by type avoids forward references within function sections.

### Step-Delimited MESSAGE TEMPLATES

Within MESSAGE TEMPLATES, use step dividers to organize chronologically:

```python
# ============================================================================
# MESSAGE TEMPLATES
# ============================================================================

# --- STEP 1: SCOPE -----------------------------------------------------------

SCOPE_INSTRUCTIONS = """..."""

# --- STEP 2: SURVEY ----------------------------------------------------------

SURVEY_DISPATCH_CONTEXT = """\
Analysis goals from SCOPE step:
- User intent and what they want to understand
- Identified focus areas"""

SURVEY_DISPATCH_AGENTS = [
    "[Exploration focus 1: e.g., 'Explore authentication flow']",
    "[Exploration focus 2: e.g., 'Explore database schema']",
]

SURVEY_DISPATCH_GUIDANCE = """\
DISPATCH GUIDANCE:
...
ADVANCE: After results received, re-invoke with --confidence low."""

SURVEY_LOW_INSTRUCTIONS = """..."""
SURVEY_MEDIUM_INSTRUCTIONS = """..."""

# --- STEP 3: DEEPEN ----------------------------------------------------------

DEEPEN_DISPATCH_CONTEXT = SURVEY_DISPATCH_CONTEXT  # reuse if identical
DEEPEN_LOW_INSTRUCTIONS = """..."""

# --- STEP 4: SYNTHESIZE ------------------------------------------------------

SYNTHESIZE_EXPLORING_INSTRUCTIONS = """..."""
```

Step divider format: `# --- STEP N: PHASE_NAME ` followed by dashes to column 76.

Within a step section, order constants by execution flow. Dispatch-related constants (context, agents, guidance) come before instruction constants.

### Dispatch Prompts: Templates vs Builders

Dispatch prompts combine static templates with dynamic composition. Split them:

**Static parts -> MESSAGE TEMPLATES** (constants):

```python
# --- STEP 2: SURVEY ----------------------------------------------------------

SURVEY_DISPATCH_CONTEXT = """\
Analysis goals from SCOPE step:
- User intent and what they want to understand
- Identified focus areas (architecture, components, flows, etc.)"""

SURVEY_DISPATCH_AGENTS = [
    "[Exploration focus 1: e.g., 'Explore authentication flow']",
    "[Exploration focus 2: e.g., 'Explore database schema']",
]

SURVEY_DISPATCH_GUIDANCE = """\
DISPATCH GUIDANCE:

Single codebase, focused scope:
  - One Explore agent with specific focus

Large/broad scope:
  - Multiple parallel Explore agents by boundary

WAIT for Explore results before re-invoking this step.

ADVANCE: After results received, re-invoke with --confidence low."""
```

**Composition -> MESSAGE BUILDERS** (functions that call `roster_dispatch()` etc.):

```python
# ============================================================================
# MESSAGE BUILDERS
# ============================================================================

def build_survey_exploring_body() -> str:
    """Build SURVEY exploring instructions with dispatch."""
    dispatch_text = roster_dispatch(
        agent_type="Explore",
        agents=SURVEY_DISPATCH_AGENTS,
        command="Use Task tool with subagent_type='Explore'",
        shared_context=SURVEY_DISPATCH_CONTEXT,
        model="haiku",
    )
    return f"DISPATCH Explore agent(s):\n\n{dispatch_text}\n\n{SURVEY_DISPATCH_GUIDANCE}"
```

This separation ensures:

1. Prompt text is visible at the constant definition (no tracing into functions)
2. Builders reference only constants defined above (chronological ordering)
3. Changes to dispatch parameters don't require modifying prompt text

### Naming Convention

```
[PHASE]_[TYPE]
```

PHASE is the workflow phase: `SCOPE`, `SURVEY`, `DEEPEN`, `SYNTHESIZE`, `DISCOVERY`, `IDEATION`.
TYPE is its role: `INSTRUCTIONS`, `DISPATCH_CONTEXT`, `DISPATCH_AGENTS`, `DISPATCH_GUIDANCE`, `FORMAT`, `FEEDBACK`.

Confidence variants use suffixes: `_LOW`, `_MEDIUM`, `_HIGH`, `_EXPLORING`, `_CERTAIN`.

Examples:

```python
EVALUATION_CRITERIA              # shared (used by 2+ steps)
SCOPE_INSTRUCTIONS               # step 1
SURVEY_DISPATCH_CONTEXT          # step 2, dispatch context
SURVEY_DISPATCH_AGENTS           # step 2, dispatch agent list
SURVEY_LOW_INSTRUCTIONS          # step 2, low confidence variant
DEEPEN_HIGH_INSTRUCTIONS         # step 3, high confidence variant
SYNTHESIZE_FORMAT                # step 4, output format
```

### Placement Rule

> A prompt belongs in the earliest section where it is used.

- Used in Steps 2, 4, 6? -> SHARED PROMPTS section
- Used only in Step 3? -> Step 3 position in MESSAGE TEMPLATES
- Used in Steps 3 and 4 only? -> Step 3 position (consecutive use doesn't require SHARED)

### Visual Formatting

Section headers (76 equals signs):

```python
# ============================================================================
# SECTION NAME
# ============================================================================
```

Step dividers within MESSAGE TEMPLATES (76 chars total):

```python
# --- STEP N: PHASE_NAME ------------------------------------------------------
```

Blank line before and after section headers. No blank line required around step dividers.

## How Skills Build Step Bodies

No "action factories". No inversion of control. Just strings.

### Pattern 1: Static Steps (deepthink)

```python
STEPS = {
    1: {
        "title": "Context Clarification",
        "body": """\
You are an expert analytical reasoner...
...""",
    },
    2: {
        "title": "Abstraction",
        "body": """\
Before diving into specifics, step back...
...""",
    },
}

def get_step_output(step: int) -> str:
    info = STEPS[step]
    body = f"{info['title']}\n{'=' * len(info['title'])}\n\n{info['body']}"
    next_cmd = f"python3 -m skills.deepthink.think --step {step + 1}" if step < 14 else ""
    return format_step(body, next_cmd)
```

### Pattern 2: Parameterized Steps (codebase-analysis)

Templates and builders are separated. Templates are constants defined in MESSAGE TEMPLATES (step-delimited). Builders compose templates into complete messages.

```python
# ============================================================================
# MESSAGE TEMPLATES
# ============================================================================

# --- STEP 2: SURVEY ----------------------------------------------------------

SURVEY_DISPATCH_CONTEXT = """\
Analysis goals from SCOPE step:
- User intent and what they want to understand"""

SURVEY_DISPATCH_AGENTS = [
    "[Exploration focus 1: e.g., 'Explore authentication flow']",
    "[Exploration focus 2: e.g., 'Explore database schema']",
]

SURVEY_DISPATCH_GUIDANCE = """\
DISPATCH GUIDANCE:
...
ADVANCE: After results received, re-invoke with --confidence low."""

SURVEY_LOW_INSTRUCTIONS = """\
EXTRACT findings from Explore output:
..."""

# ============================================================================
# MESSAGE BUILDERS
# ============================================================================

def build_survey_exploring_body() -> str:
    dispatch_text = roster_dispatch(
        agent_type="Explore",
        agents=SURVEY_DISPATCH_AGENTS,
        command="Use Task tool with subagent_type='Explore'",
        shared_context=SURVEY_DISPATCH_CONTEXT,
        model="haiku",
    )
    return f"DISPATCH Explore agent(s):\n\n{dispatch_text}\n\n{SURVEY_DISPATCH_GUIDANCE}"

def get_survey_body(confidence: str) -> str:
    if confidence == "exploring":
        return build_survey_exploring_body()
    elif confidence == "low":
        return f"SURVEY - Low Confidence\n\n{SURVEY_LOW_INSTRUCTIONS}"
    # ...

def format_output(step: int, confidence: str) -> str:
    bodies = {1: get_scope_body, 2: get_survey_body, ...}
    body = bodies[step](confidence)
    next_cmd = build_next_command(step, confidence)
    return format_step(body, next_cmd)
```

### Pattern 3: Dispatch Steps (planner orchestrator)

```python
from skills.lib.workflow.prompts import format_step, subagent_dispatch
from skills.planner.prompts.constants import ORCHESTRATOR_CONSTRAINT

def format_dispatch_step(agent_type: str, invoke_cmd: str, state_dir: str) -> str:
    dispatch = subagent_dispatch(agent_type=agent_type, command=invoke_cmd)

    body = f"""\
{ORCHESTRATOR_CONSTRAINT}

{dispatch}"""

    next_step_cmd = f"python3 -m skills.planner.orchestrator.planner --step N --state-dir {state_dir}"
    return format_step(body, next_step_cmd)
```

### Pattern 4: File Injection (prompt-engineer)

```python
from skills.lib.workflow.prompts import format_step, format_file_content

def format_technique_step(categories: list[str]) -> str:
    file_blocks = []
    for cat in categories:
        path = CATEGORY_TO_FILE[cat]
        content = (REFS_DIR / path).read_text()
        file_blocks.append(format_file_content(f"references/{path}", content))

    body = f"""\
TECHNIQUE REFERENCES
The following files have been loaded based on your category selection:

{chr(10).join(file_blocks)}

TASK: Apply techniques from these references to the target prompt.
..."""

    return format_step(body, "python3 -m skills.prompt_engineer.optimize --step 5")
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

**Ordering constraint (book pattern)**: Dynamic formatter functions that call MESSAGE BUILDERS must appear AFTER MESSAGE BUILDERS. The DYNAMIC*STEPS dictionary must appear AFTER all `\_format_step*\*` functions it references.

Use this pattern when:

- Many steps share the same structure (title + constant body)
- Few steps need parameters for title or body construction
- Parameters are uniform across all dynamic steps

Benefits:

- Compact representation for static steps (one line per step)
- Clear, readable functions for dynamic steps
- Single dispatch point in `format_output()`
- Follows "book pattern" (all references resolve to definitions above)

### Anti-Pattern: Action Factories

```python
# BAD - unnecessary indirection
def technique_review_actions(for_ecosystem=False):
    base = ["For each technique...", "1. QUOTE the trigger", ...]
    if for_ecosystem:
        base.append("Note techniques across prompts")
    return base
```

Replace with:

```python
# GOOD - text at call site
TECHNIQUE_REVIEW = """\
For each technique in the Technique Selection Guide:
1. QUOTE the trigger condition from the table
2. QUOTE text from the target prompt that matches
3. Verdict: APPLICABLE or NOT APPLICABLE"""

TECHNIQUE_REVIEW_ECOSYSTEM = TECHNIQUE_REVIEW + """
Note techniques that apply to multiple prompts."""

# Usage: just reference the constant
body = f"...\n{TECHNIQUE_REVIEW_ECOSYSTEM}\n..."
```

Functions that return prompt fragments are only justified when there's complex conditional logic (multiple if/else branches). Even then, they live in the skill, not the shared lib.

## Shared Library

Location: `skills/lib/workflow/prompts/`

Only abstractions used by 3+ skills with identical semantics:

```
prompts/
    __init__.py         # re-exports
    subagent.py         # dispatch templates
    step.py             # format_step()
    file_content.py     # format_file_content()
```

### subagent.py

Three dispatch patterns for spawning sub-agents via the Task tool:

- `subagent_dispatch(agent_type, command, prompt="", model=None)` -- single sequential dispatch
- `template_dispatch(agent_type, template, targets, command, ...)` -- parallel SIMD (same template, N targets with $var substitution)
- `roster_dispatch(agent_type, agents, command, shared_context="", ...)` -- parallel MIMD (shared context + unique tasks)

Building blocks (also exported):

- `task_tool_instruction(agent_type, model)` -- how to use Task tool
- `sub_agent_invoke(cmd)` -- command the spawned agent runs
- `parallel_constraint(count)` -- MANDATORY_PARALLEL enforcement

### step.py

```python
def format_step(body: str, next_cmd: str = "") -> str:
    """Assemble a complete workflow step.

    Args:
        body: The prompt content (free-form text)
        next_cmd: Command to run next (empty string for final step)

    Returns:
        Complete step output as plain text
    """
```

### file_content.py

```python
def format_file_content(path: str, content: str) -> str:
    """Embed file content in a prompt.

    Uses 4-backtick fence to handle content containing triple-backticks.
    """
```

## Two Invoke Concepts

The codebase has two distinct "invoke" situations:

**Sub-agent invoke** (`sub_agent_invoke()` in subagent.py): Appears INSIDE a dispatch prompt. Tells the SPAWNED agent what command to run after it's created.

**Parent invoke_after** (in `format_step()`): Appears AFTER the body as the step's terminal directive. Tells the CURRENT agent what to run next.

A dispatch step has BOTH:

- The body contains a dispatch prompt with the sub-agent's invoke command
- The step ends with the parent's invoke_after for what happens after the sub-agent returns

## Core Abstraction: The Step

Every workflow step has the same fundamental structure:

```
[body]

[invoke_after]
```

That's it. Two parts:

1. **body**: The actual prompt content. Free-form text.
2. **invoke_after**: The command the LLM should run next. Optional (empty for final steps).
