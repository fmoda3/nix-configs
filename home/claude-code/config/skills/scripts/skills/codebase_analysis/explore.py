#!/usr/bin/env python3
"""
Codebase Analysis Explore - Focus-area exploration for codebase understanding.

Four-step workflow:
  1. ORIENT   - Identify entry points for focus area
  2. MAP      - Build structural understanding
  3. EXTRACT  - Capture specific knowledge
  4. REPORT   - Synthesize into structured output

Note: The focus area is NOT a CLI argument. The orchestrator provides focus
in the subagent's launching prompt. This script emits guidance that refers
to "the focus area" -- the agent knows what it is from its prompt context.
"""

import argparse
import sys

from skills.lib.workflow.ast import (
    render_step_header, render_current_action, render_invoke_after,
    StepHeaderNode, CurrentActionNode, InvokeAfterNode,
)


MODULE_PATH = "skills.codebase_analysis.explore"
TOTAL_STEPS = 4


def format_step_1() -> str:
    """Step 1: Identify entry points for focus area.

    Focus area is known from orchestrator's launching prompt -- not a parameter.
    """
    actions = [
        "ORIENT - Identify entry points for your focus area.",
        "",
        "Your focus area was specified in your launching prompt.",
        "",
        "ACTIONS:",
        "  1. Glob for patterns matching focus area keywords",
        "  2. Identify 3-8 candidate files as entry points",
        "  3. Note language/framework indicators",
        "",
        "EDGE CASE: If glob returns 0 matches, output empty <entry_points/> and proceed.",
        "",
        "OUTPUT FORMAT:",
        "<orientation>",
        "  <focus>[your focus area]</focus>",
        "  <entry_points>",
        '    <file path="src/auth/login.py" relevance="main entry"/>',
        "    <!-- 3-8 files, or empty if no matches -->",
        "  </entry_points>",
        '  <scope_estimate files="N"/>',
        "</orientation>",
    ]

    parts = [
        render_step_header(StepHeaderNode(
            title="ORIENT", script="explore", step=1
        )),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        render_invoke_after(InvokeAfterNode(
            cmd=f"python3 -m {MODULE_PATH} --step 2"
        )),
    ]
    return "\n".join(parts)


def format_step_2() -> str:
    """Step 2: Build structural understanding."""
    actions = [
        "MAP - Build structural understanding from entry points.",
        "",
        "INPUT: Use <entry_points> from Step 1.",
        "",
        "ACTIONS:",
        "  1. Read key files identified in ORIENT",
        "  2. Trace imports, calls, data flow",
        "  3. Build component inventory",
        "  4. Identify relationships between components",
        "",
        "OUTPUT FORMAT:",
        "<structure_map>",
        "  <components>",
        '    <component name="LoginHandler" file="..." role="entry point"/>',
        "  </components>",
        "  <relationships>",
        '    <flow from="LoginHandler" to="TokenService" type="calls"/>',
        "  </relationships>",
        "  <patterns>",
        '    <pattern name="Repository" occurrences="3"/>',
        "  </patterns>",
        "</structure_map>",
    ]

    parts = [
        render_step_header(StepHeaderNode(
            title="MAP", script="explore", step=2
        )),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        render_invoke_after(InvokeAfterNode(
            cmd=f"python3 -m {MODULE_PATH} --step 3"
        )),
    ]
    return "\n".join(parts)


def format_step_3() -> str:
    """Step 3: Capture specific knowledge."""
    actions = [
        "EXTRACT - Capture specific knowledge from structure map.",
        "",
        "INPUT: Use <structure_map> from Step 2.",
        "",
        "ACTIONS:",
        "  For each key component, answer:",
        "  - HOW does this work? (mechanism)",
        "  - WHY this approach? (design decision)",
        "",
        "  Also identify:",
        "  - Unclear areas needing further exploration",
        "  - Edge cases or non-obvious behavior",
        "",
        "OUTPUT FORMAT:",
        "<extracted_knowledge>",
        '  <mechanism component="TokenService">',
        "    <how>JWT-based with RSA signing, 1hr expiry</how>",
        "    <why>Stateless auth for horizontal scaling</why>",
        "  </mechanism>",
        '  <decision rationale="security">Refresh tokens stored in Redis</decision>',
        "  <unclear>Token revocation mechanism not evident</unclear>",
        "</extracted_knowledge>",
    ]

    parts = [
        render_step_header(StepHeaderNode(
            title="EXTRACT", script="explore", step=3
        )),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        render_invoke_after(InvokeAfterNode(
            cmd=f"python3 -m {MODULE_PATH} --step 4"
        )),
    ]
    return "\n".join(parts)


def format_step_4() -> str:
    """Step 4: Synthesize into structured report.

    Output Schema Reference (matches orchestrator SYNTHESIZE):
    - <structure>  -> ## Structure
    - <patterns>   -> ## Patterns
    - <flows>      -> ## Flows
    - <decisions>  -> ## Decisions
    - <gaps>       -> DEEPEN iteration targeting

    See Design Rationale section for full schema mapping table.
    """
    actions = [
        "REPORT - Synthesize findings into structured summary.",
        "",
        "INPUT: All prior step outputs (orientation, structure_map, extracted_knowledge).",
        "",
        "OUTPUT FORMAT (REQUIRED - all sections must be present):",
        '<exploration_report focus="[your focus area]">',
        "  <summary>1-2 sentence overview</summary>",
        "  <structure>",
        "    Key components and their roles",
        '    OR "No clear component structure identified"',
        "  </structure>",
        "  <patterns>",
        "    Observed architectural/code patterns",
        '    OR "No significant patterns observed"',
        "  </patterns>",
        "  <flows>",
        "    Data/request flow through the system",
        '    OR "Data flow not traced"',
        "  </flows>",
        "  <decisions>",
        "    Technology/design choices with rationale",
        '    OR "No explicit design decisions found"',
        "  </decisions>",
        "  <gaps>",
        "    Areas that remain unclear",
        '    OR "Focus area may not exist in codebase"',
        "  </gaps>",
        "</exploration_report>",
        "",
        "COMPLETE - Return exploration_report to orchestrator.",
    ]

    parts = [
        render_step_header(StepHeaderNode(
            title="REPORT", script="explore", step=4
        )),
        "",
        render_current_action(CurrentActionNode(actions)),
    ]
    return "\n".join(parts)


def format_output(step: int) -> str:
    """Route to appropriate step formatter."""
    formatters = {
        1: format_step_1,
        2: format_step_2,
        3: format_step_3,
        4: format_step_4,
    }
    formatter = formatters.get(step)
    if not formatter:
        sys.exit(f"ERROR: Unknown step {step}")
    return formatter()


def main():
    parser = argparse.ArgumentParser(
        description="Codebase Analysis Explore - Focus-area exploration",
    )
    parser.add_argument("--step", type=int, required=True)
    args = parser.parse_args()

    if args.step < 1 or args.step > TOTAL_STEPS:
        sys.exit(f"ERROR: --step must be 1-{TOTAL_STEPS}")

    print(format_output(args.step))


if __name__ == "__main__":
    main()
