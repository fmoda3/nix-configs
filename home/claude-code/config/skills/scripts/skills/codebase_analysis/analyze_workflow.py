#!/usr/bin/env python3
"""
Codebase Analysis Skill - Understanding-focused comprehension workflow.

Four-phase workflow:
  1. SCOPE      - Define understanding goals (single pass)
  2. SURVEY     - Initial exploration via Explore agents (single pass)
  3. DEEPEN     - Targeted deep-dives with confidence iteration (1-4 iterations)
  4. SYNTHESIZE - Structured summary output (single pass)

Only DEEPEN iterates based on confidence. Other steps execute once and advance.
"""

import argparse
import sys

from skills.lib.workflow.core import StepDef, Workflow
from skills.lib.workflow.prompts import format_step, template_dispatch


# ============================================================================
# SHARED PROMPTS
# ============================================================================

DISPATCH_CONTEXT = """\
Analysis goals from SCOPE step:
- User intent and what they want to understand
- Identified focus areas (architecture, components, flows, etc.)
- Defined objectives (1-3 specific goals)"""


# ============================================================================
# CONFIGURATION
# ============================================================================

MODULE_PATH = "skills.codebase_analysis.analyze_workflow"
EXPLORE_MODULE_PATH = "skills.codebase_analysis.explore"
MAX_DEEPEN_ITERATIONS = 4


# ============================================================================
# MESSAGE TEMPLATES
# ============================================================================

# --- STEP 1: SCOPE -----------------------------------------------------------

SCOPE_INSTRUCTIONS = """\
PARSE user intent:
  - What codebase(s) are we analyzing?
  - What is the user trying to understand?
  - Are there specific areas of interest mentioned?

IDENTIFY focus areas:
  - Architecture/structure understanding
  - Specific component/feature deep-dive
  - Technology stack assessment
  - Integration patterns
  - Data flows

DEFINE goals (1-3 specific objectives):
  - 'Understand how [system X] processes [Y]'
  - 'Map dependencies between [A] and [B]'
  - 'Document data flow from [input] to [output]'

DO NOT seek user confirmation. Goals are internal guidance.

ADVANCE: When goals defined, proceed to SURVEY."""

# --- STEP 2: SURVEY ----------------------------------------------------------

SURVEY_INSTRUCTIONS = """\
DISPATCH Explore agent(s) to map the codebase landscape.

{dispatch}

DISPATCH GUIDANCE:

Single codebase, focused scope:
  - One Explore agent with specific focus

Large/broad scope:
  - Multiple parallel Explore agents by boundary
  - Example: frontend agent + backend agent + data agent

Multiple repositories:
  - One Explore agent per repository

WAIT for Explore results.

PROCESS findings:

STRUCTURE:
  - Directory organization
  - File patterns
  - Module boundaries

PATTERNS:
  - Architectural style (layered, microservices, monolithic)
  - Code organization patterns
  - Naming conventions

FLOWS:
  - Entry points
  - Request/data flow paths
  - Integration patterns

DECISIONS:
  - Technology choices
  - Framework usage
  - Dependencies

ADVANCE: When exploration complete, proceed to DEEPEN."""

# --- STEP 3: DEEPEN ----------------------------------------------------------

DEEPEN_INSTRUCTIONS = """\
DEEPEN understanding through direct exploration.

DO NOT dispatch agents. Use Read, Glob, Grep tools directly.

IDENTIFY areas needing deep understanding:

Prioritize by:
  - COMPLEXITY: Non-obvious behavior, intricate logic
  - NOVELTY: Unfamiliar patterns, unique approaches
  - CENTRALITY: Core to user's goals

SELECT 1-3 targets for this iteration:
  - Specific component/module
  - Particular data flow
  - Integration mechanism
  - Implementation pattern

EXPLORE each target:
  - Read key files directly
  - Trace execution paths
  - Understand data transformations
  - Map dependencies

EXTRACT understanding:
  - How does this component work?
  - What are the key mechanisms?
  - How does it integrate with other parts?

ASSESS confidence:
  - CERTAIN: Goals fully understood, ready for synthesis
  - HIGH: Strong understanding, minor gaps acceptable
  - MEDIUM: Reasonable understanding, some questions remain
  - LOW: Significant gaps, need more exploration
  - EXPLORING: Just starting, identifying targets

ADVANCE:
  - confidence == certain: Proceed to SYNTHESIZE
  - confidence != certain AND iteration < {max_iter}: Continue DEEPEN
  - iteration >= {max_iter}: Force proceed to SYNTHESIZE"""

# --- STEP 4: SYNTHESIZE ------------------------------------------------------

SYNTHESIZE_INSTRUCTIONS = """\
OUTPUT structured summary:

# Codebase Understanding Summary

## Structure
[Directory organization, module boundaries, component relationships]

## Patterns
[Architectural patterns, design patterns, code organization]

## Flows
[Request flows, data flows, integration patterns]

## Decisions
[Technology choices, framework selections, architectural decisions]

## Context
[Purpose, constraints, trade-offs, evolution]

Ensure:
  - Summary addresses user's original intent
  - All sections present with concrete findings
  - Framing is understanding-focused (not auditing)
  - Facts and observations (not judgments)"""


# ============================================================================
# MESSAGE BUILDERS
# ============================================================================


def build_survey_body() -> str:
    """Build SURVEY instructions with template for Explore agent dispatch.

    Orchestrator receives template (not rendered dispatch). At runtime, orchestrator:
    1. Analyzes codebase structure (SCOPE)
    2. Generates 2-5 focus areas
    3. Expands template for each focus area
    4. Dispatches agents in parallel with actual script invocation
    """
    dispatch_template = f"""\
DISPATCH EXPLORE AGENTS
=======================

Based on your SCOPE analysis, determine 2-5 focus areas to explore.

For EACH focus area, use Task tool with:
  - subagent_type: general-purpose
  - model: haiku
  - prompt: Include the focus area and invoke command below

PROMPT TEMPLATE (expand for each focus area):
```
Explore '$FOCUS' in the codebase. Use understanding goals from shared context.

{DISPATCH_CONTEXT}

FIRST ACTION REQUIRED: Run this command via Bash tool before any other response.
Do NOT skip. Do NOT produce analysis first. Execute this command IMMEDIATELY.

Working directory: .claude/skills/scripts
Command: python3 -m {EXPLORE_MODULE_PATH} --step 1
```

Note: The focus area ('$FOCUS') is in the prompt text above, NOT passed as a CLI arg.
The subagent script emits guidance that refers to "your focus area" -- the agent
knows what it is from its launching prompt context.

PARALLEL EXECUTION (MANDATORY):
  You MUST dispatch ALL agents in ONE assistant message.
  FORBIDDEN: Waiting for any agent before dispatching the next.

EXAMPLE FOCUS AREAS:
  - "authentication and session management"
  - "database access patterns"
  - "API request routing"
  - "error handling"

Generate focus areas based on:
  1. User's stated understanding goals (from SCOPE)
  2. Codebase structure (from initial observation)
  3. Coverage of different system aspects"""

    return SURVEY_INSTRUCTIONS.format(dispatch=dispatch_template)


def build_deepen_body(iteration: int) -> str:
    """Build DEEPEN instructions with iteration context."""
    return DEEPEN_INSTRUCTIONS.format(max_iter=MAX_DEEPEN_ITERATIONS)


def build_next_command(step: int, confidence: str, iteration: int) -> str | None:
    """Build the invoke command for the next step."""
    base_cmd = f'python3 -m {MODULE_PATH}'

    if step == 1:  # SCOPE -> SURVEY
        return f'{base_cmd} --step 2'

    elif step == 2:  # SURVEY -> DEEPEN
        return f'{base_cmd} --step 3 --iteration 1 --confidence exploring'

    elif step == 3:  # DEEPEN
        if confidence == "certain" or iteration >= MAX_DEEPEN_ITERATIONS:
            return f'{base_cmd} --step 4'
        else:
            return f'{base_cmd} --step 3 --iteration {iteration + 1} --confidence {{exploring|low|medium|high|certain}}'

    elif step == 4:  # SYNTHESIZE -> complete
        return None

    return None


def format_output(step: int, confidence: str, iteration: int) -> str:
    """Format output for the given step."""
    base_cmd = f'python3 -m {MODULE_PATH}'

    if step == 1:
        body = f"CODEBASE ANALYSIS - Define understanding goals\n{'=' * 50}\n\n{SCOPE_INSTRUCTIONS}"
        next_cmd = build_next_command(step, confidence, iteration)

    elif step == 2:
        body = f"CODEBASE ANALYSIS - Initial exploration\n{'=' * 50}\n\n{build_survey_body()}"
        next_cmd = build_next_command(step, confidence, iteration)

    elif step == 3:
        if confidence == "certain":
            title = "Understanding complete"
            instructions = "Deep understanding achieved.\n\nPROCEED to SYNTHESIZE step."
        elif iteration >= MAX_DEEPEN_ITERATIONS:
            title = f"Max iterations reached ({iteration}/{MAX_DEEPEN_ITERATIONS})"
            instructions = "Maximum DEEPEN iterations reached.\n\nFORCE transition to SYNTHESIZE."
        else:
            title = f"Targeted deep-dive (iteration {iteration}/{MAX_DEEPEN_ITERATIONS})"
            instructions = build_deepen_body(iteration)

        body = f"CODEBASE ANALYSIS - {title}\n{'=' * 50}\n\n{instructions}"
        next_cmd = build_next_command(step, confidence, iteration)

    elif step == 4:
        body = f"CODEBASE ANALYSIS - Output summary\n{'=' * 50}\n\n{SYNTHESIZE_INSTRUCTIONS}"
        next_cmd = None

    else:
        return f"ERROR: Invalid step {step}"

    return format_step(body, next_cmd or "")


# ============================================================================
# WORKFLOW
# ============================================================================

WORKFLOW = Workflow(
    "codebase-analysis",
    StepDef(id="scope", title="SCOPE - Define understanding goals", actions=[SCOPE_INSTRUCTIONS]),
    StepDef(id="survey", title="SURVEY - Initial exploration", actions=[SURVEY_INSTRUCTIONS]),
    StepDef(id="deepen", title="DEEPEN - Targeted deep-dives", actions=[DEEPEN_INSTRUCTIONS]),
    StepDef(id="synthesize", title="SYNTHESIZE - Structured summary output", actions=[SYNTHESIZE_INSTRUCTIONS]),
    description="Understanding-focused codebase comprehension workflow",
    validate=False,
)


def main():
    parser = argparse.ArgumentParser(
        description="Codebase Analysis - Understanding-focused comprehension workflow",
        epilog="Phases: SCOPE (1) -> SURVEY (2) -> DEEPEN (3) -> SYNTHESIZE (4)",
    )
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument(
        "--confidence",
        type=str,
        choices=["exploring", "low", "medium", "high", "certain"],
        default="exploring",
        help="Current confidence level (DEEPEN step only)",
    )
    parser.add_argument(
        "--iteration",
        type=int,
        default=1,
        help="Iteration count (DEEPEN step only, max 4)",
    )
    args = parser.parse_args()

    if args.step < 1:
        sys.exit("ERROR: --step must be >= 1")
    if args.step > WORKFLOW.total_steps:
        sys.exit(f"ERROR: --step cannot exceed {WORKFLOW.total_steps}")
    if args.iteration < 1:
        sys.exit("ERROR: --iteration must be >= 1")

    print(format_output(args.step, args.confidence, args.iteration))


if __name__ == "__main__":
    main()
