#!/usr/bin/env python3
"""
Problem Analysis Skill - Root cause identification workflow.

Five-phase workflow:
  1. Gate        - Validate input, establish single testable problem
  2. Hypothesize - Generate testable candidate explanations
  3. Investigate - Iterative evidence gathering (up to 5 iterations)
  4. Formulate   - Synthesize findings into validated root cause
  5. Output      - Produce structured report for downstream consumption

This skill identifies root causes, NOT solutions. It ends when the root cause
is identified with supporting evidence. Solution discovery is downstream.
"""

import argparse
import sys

from skills.lib.workflow.core import StepDef, Workflow
from skills.lib.workflow.ast import W, XMLRenderer, render, TextNode
from skills.lib.workflow.ast.nodes import (
    StepHeaderNode, CurrentActionNode, InvokeAfterNode,
)
from skills.lib.workflow.ast.renderer import (
    render_step_header, render_current_action, render_invoke_after,
)


# Maximum iterations for Phase 3 investigation loop
MAX_ITERATIONS = 5

MODULE_PATH = "skills.problem_analysis.analyze"


# XML format mandate for step 1
XML_FORMAT_MANDATE = """<xml_format_mandate>
CRITICAL: All script outputs use XML format. You MUST:

1. Execute the action in <current_action>
2. When complete, invoke the exact command in <invoke_after>
3. The <next> block re-states the command -- execute it
4. For branching <invoke_after>, choose based on outcome:
   - <if_pass>: Use when action succeeded / QR returned PASS
   - <if_fail>: Use when action failed / QR returned ISSUES

DO NOT modify commands. DO NOT skip steps. DO NOT interpret.
</xml_format_mandate>"""


PHASES = {
    1: {
        "title": "Gate",
        "brief": "Validate input, establish single testable problem",
        "actions": [
            "CHECK FOR MULTIPLE PROBLEMS:",
            "  Scan input for signs of multiple distinct issues:",
            "  - Multiple symptoms described ('X AND Y')",
            "  - Problems in unrelated components",
            "  - Symptoms with independent causes",
            "",
            "  If multiple problems -> STOP. Use AskUserQuestion to ask user",
            "  to isolate ONE problem. Do not proceed until single problem.",
            "",
            "CHECK FOR SUFFICIENT INFORMATION:",
            "  A problem statement must include:",
            "  - What component or behavior is affected",
            "  - What the expected behavior is",
            "  - What the actual observed behavior is",
            "",
            "  If missing or vague -> Use AskUserQuestion to clarify.",
            "",
            "RESTATE THE PROBLEM:",
            "  Reframe in observable terms:",
            "  'When [conditions], [component] exhibits [observed behavior]",
            "   instead of [expected behavior]'",
            "",
            "SEPARATE KNOWN FROM ASSUMED:",
            "  KNOWN: From user report or visible context",
            "  ASSUMED: Things investigation must verify",
            "",
            "OUTPUT FORMAT:",
            "```",
            "VALIDATION: [PASS / BLOCKED: reason]",
            "",
            "REFINED PROBLEM STATEMENT:",
            "When [conditions], [component] exhibits [observed behavior]",
            "instead of [expected behavior]",
            "",
            "KNOWN FACTS:",
            "- [fact 1]",
            "- [fact 2]",
            "",
            "ASSUMPTIONS TO VERIFY:",
            "- [assumption 1]",
            "- [assumption 2]",
            "```",
        ],
    },
    2: {
        "title": "Hypothesize",
        "brief": "Generate testable candidate explanations",
        "actions": [
            "GENERATE 2-4 DISTINCT HYPOTHESES:",
            "  Each hypothesis must:",
            "  - Differ on mechanism or location (not just phrasing)",
            "  - Be framed as a CONDITION THAT EXISTS, not an absence",
            "  - Predict something examinable (where to look, what to find)",
            "",
            "FRAMING RULES (critical):",
            "  WRONG: 'The validation is missing'",
            "  RIGHT: 'User input reaches the database query without sanitization'",
            "",
            "  WRONG: 'There's no error handling'",
            "  RIGHT: 'Exceptions in the payment callback propagate uncaught,",
            "          terminating the request without rollback'",
            "",
            "RANK BY PLAUSIBILITY:",
            "  Order hypotheses by likelihood given available context.",
            "  This guides investigation order but doesn't preclude alternatives.",
            "",
            "OUTPUT FORMAT:",
            "```",
            "HYPOTHESES:",
            "",
            "H1 (highest priority): [name]",
            "    Mechanism: [how this would cause the symptom]",
            "    Testable by: [what to examine, what you'd expect to find]",
            "",
            "H2: [name]",
            "    Mechanism: [how this would cause the symptom]",
            "    Testable by: [what to examine, what you'd expect to find]",
            "",
            "[H3, H4 if generated]",
            "",
            "INVESTIGATION PLAN:",
            "Will examine H1 first because [reason], then H2 if H1 doesn't hold.",
            "```",
        ],
    },
    3: {
        "title": "Investigate",
        "brief": "Gather evidence to evaluate hypotheses",
        "actions": [
            "SELECT what to examine:",
            "  - Highest-priority OPEN hypothesis, OR",
            "  - Deepen a SUPPORTED hypothesis (ask 'why does this exist?'), OR",
            "  - Examine an unexplored aspect of the problem",
            "",
            "EXAMINE specific code, configuration, or documentation.",
            "  Note exact files and line numbers. This creates an audit trail.",
            "",
            "ASSESS findings:",
            "  Does evidence SUPPORT, CONTRADICT, or NEITHER?",
            "  Be specific: 'Line 47 of auth.py contains X which would cause Y'",
            "  Not: 'This looks problematic'",
            "",
            "UPDATE hypothesis status:",
            "  - SUPPORTED: Evidence confirms this hypothesis",
            "  - CONTRADICTED: Evidence rules this out",
            "  - OPEN: Not yet examined or inconclusive",
            "",
            "ANSWER READINESS QUESTIONS:",
            "",
            "Q1 EVIDENCE: Can you cite specific code/config/docs supporting root cause?",
            "   [YES / PARTIAL / NO]",
            "",
            "Q2 ALTERNATIVES: Did you examine evidence for at least one alternative?",
            "   [YES / PARTIAL / NO]",
            "",
            "Q3 EXPLANATION: Does root cause fully explain the symptom?",
            "   [YES / PARTIAL / NO]",
            "",
            "Q4 FRAMING: Is root cause a positive condition (not absence)?",
            "   [YES / NO]",
            "",
            "COMPUTE CONFIDENCE:",
            "  - 4 points = HIGH (ready to proceed)",
            "  - 3-3.5 = MEDIUM",
            "  - 2-2.5 = LOW",
            "  - <2 = INSUFFICIENT (keep investigating)",
            "",
            "OUTPUT FORMAT:",
            "```",
            "ITERATION FINDINGS:",
            "",
            "Examined: [which hypothesis or aspect]",
            "Evidence sought: [what you looked for]",
            "Evidence found: [what you found, with file:line references]",
            "Assessment: [SUPPORTS / CONTRADICTS / INCONCLUSIVE] because [reason]",
            "",
            "HYPOTHESIS STATUS:",
            "- H1: [SUPPORTED / CONTRADICTED / OPEN] - [brief reason]",
            "- H2: [SUPPORTED / CONTRADICTED / OPEN] - [brief reason]",
            "",
            "READINESS CHECK:",
            "- Q1 Evidence: [YES/PARTIAL/NO]",
            "- Q2 Alternatives: [YES/PARTIAL/NO]",
            "- Q3 Explanation: [YES/PARTIAL/NO]",
            "- Q4 Framing: [YES/NO]",
            "",
            "CONFIDENCE: [exploring/low/medium/high]",
            "```",
        ],
    },
    4: {
        "title": "Formulate",
        "brief": "Synthesize findings into validated root cause statement",
        "actions": [
            "STATE THE ROOT CAUSE:",
            "  Template: 'The system exhibits [symptom] because [condition exists]'",
            "",
            "  The condition must be:",
            "  - Specific enough to locate (points to code/config)",
            "  - General enough to allow multiple remediation approaches",
            "",
            "TRACE THE CAUSAL CHAIN:",
            "  [root cause] -> [intermediate] -> [intermediate] -> [symptom]",
            "  Each link should follow logically. Note any gaps as uncertainties.",
            "",
            "VALIDATE FRAMING (critical):",
            "",
            "  CHECK 1 - Positive framing:",
            "  Does root cause contain 'lack of', 'missing', 'no X', 'doesn't have'?",
            "  If YES -> REFRAME before proceeding.",
            "",
            "  WRONG: 'The system lacks input validation'",
            "  RIGHT: 'User input flows directly to SQL query without sanitization'",
            "",
            "  CHECK 2 - Solution independence:",
            "  Does root cause implicitly prescribe exactly one solution?",
            "  If YES -> REFRAME to be more general.",
            "",
            "  WRONG: 'The retry count is set to 0' (prescribes: set it higher)",
            "  RIGHT: 'Failed API calls terminate immediately without retry,",
            "          causing transient failures to surface as errors'",
            "",
            "DOCUMENT UNCERTAINTIES:",
            "  What wasn't verified? What would require runtime info to confirm?",
            "",
            "OUTPUT FORMAT:",
            "```",
            "ROOT CAUSE:",
            "[validated statement - must pass both framing checks]",
            "",
            "CAUSAL CHAIN:",
            "[root cause]",
            "  -> [intermediate 1]",
            "  -> [intermediate 2]",
            "  -> [observed symptom]",
            "",
            "FRAMING VALIDATION:",
            "- Positive framing (no absences): [PASS/FAIL - if fail, show reframed]",
            "- Solution independence: [PASS/FAIL - if fail, show reframed]",
            "",
            "REMAINING UNCERTAINTIES:",
            "- [what wasn't verified]",
            "- [what assumptions remain]",
            "```",
        ],
    },
    5: {
        "title": "Output",
        "brief": "Produce structured report for downstream consumption",
        "actions": [
            "Compile final analysis report using all findings from previous phases.",
            "",
            "OUTPUT FORMAT:",
            "```",
            "================================================================================",
            "                         PROBLEM ANALYSIS REPORT",
            "================================================================================",
            "",
            "ORIGINAL PROBLEM:",
            "[verbatim from user]",
            "",
            "REFINED PROBLEM:",
            "[observable-framed version from Phase 1]",
            "",
            "--------------------------------------------------------------------------------",
            "",
            "ROOT CAUSE:",
            "[validated statement from Phase 4]",
            "",
            "CAUSAL CHAIN:",
            "[root cause]",
            "  -> [intermediate cause 1]",
            "  -> [intermediate cause 2]",
            "  -> [observed symptom]",
            "",
            "--------------------------------------------------------------------------------",
            "",
            "SUPPORTING EVIDENCE:",
            "- [file:line] -- [what it shows]",
            "- [file:line] -- [what it shows]",
            "",
            "--------------------------------------------------------------------------------",
            "",
            "CONFIDENCE: [HIGH / MEDIUM / LOW / INSUFFICIENT]",
            "",
            "  Evidence (specific citations exist):      [YES / PARTIAL / NO]",
            "  Alternatives (others considered):         [YES / PARTIAL / NO]",
            "  Explanation (fully accounts for symptom): [YES / PARTIAL / NO]",
            "  Framing (positive, solution-independent): [YES / NO]",
            "",
            "--------------------------------------------------------------------------------",
            "",
            "REMAINING UNCERTAINTIES:",
            "- [what wasn't verified]",
            "- [what assumptions remain]",
            "",
            "--------------------------------------------------------------------------------",
            "",
            "INVESTIGATION LOG:",
            "[Include key findings from each Phase 3 iteration]",
            "",
            "================================================================================",
            "```",
            "",
            "This completes the problem analysis. The root cause and supporting",
            "evidence can now be used as input for solution discovery.",
        ],
    },
}


def get_phase_3_completion_message(confidence: str, iteration: int) -> list[str]:
    """Generate completion message for Phase 3 when exiting the loop."""
    if confidence == "high":
        return [
            "Investigation reached HIGH confidence. Proceeding to root cause formulation.",
            "",
            "Review accumulated findings from iterations above, then proceed.",
        ]
    else:
        return [
            f"Investigation reached iteration cap ({MAX_ITERATIONS}).",
            f"Proceeding with current findings. Final confidence: {confidence}",
            "",
            "Review accumulated findings from iterations above, then proceed.",
        ]


# Workflow definition (metadata only, execution via CLI)
WORKFLOW = Workflow(
    "problem-analysis",
    StepDef(id="gate", title="Gate", actions=PHASES[1]["actions"]),
    StepDef(id="hypothesize", title="Hypothesize", actions=PHASES[2]["actions"]),
    StepDef(id="investigate", title="Investigate", actions=PHASES[3]["actions"]),
    StepDef(id="formulate", title="Formulate", actions=PHASES[4]["actions"]),
    StepDef(id="output", title="Output", actions=PHASES[5]["actions"]),
    description="Root cause identification workflow",
    validate=False,
)


# =============================================================================
# Output Formatting
# =============================================================================


def format_output(step: int, confidence: str, iteration: int) -> str:
    """Format output for display using XML building blocks."""
    phase = PHASES.get(step)
    if not phase:
        return f"ERROR: Invalid step {step}"

    parts = []

    # Special handling for Phase 3 (Investigate) with iteration logic
    if step == 3:
        # Check exit conditions
        if confidence == "high" or iteration >= MAX_ITERATIONS:
            # Exit loop - advance to formulate
            actions = get_phase_3_completion_message(confidence, iteration)
            title = f"PROBLEM ANALYSIS - {phase['title']} Complete"

            parts.append(render_step_header(StepHeaderNode(
                title=title,
                script="problem-analysis",
                step=str(step)
            )))
            parts.append("")

            parts.append(render_current_action(CurrentActionNode(actions)))
            parts.append("")

            next_cmd = f'python3 -m {MODULE_PATH} --step 4 '
            parts.append(render_invoke_after(InvokeAfterNode(cmd=next_cmd)))

            return "\n".join(parts)

        # Continue investigation - emit iteration prompt
        title = f"PROBLEM ANALYSIS - {phase['title']} (Iteration {iteration} of {MAX_ITERATIONS})"

        parts.append(render_step_header(StepHeaderNode(
            title=title,
            script="problem-analysis",
            step=str(step)
        )))
        parts.append("")

        parts.append(render_current_action(CurrentActionNode(phase["actions"])))
        parts.append("")

        next_iteration = iteration + 1
        next_cmd = f'python3 -m {MODULE_PATH} --step 3  --confidence {{exploring|low|medium|high|certain}} --iteration {next_iteration}'
        parts.append(render_invoke_after(InvokeAfterNode(cmd=next_cmd)))

        return "\n".join(parts)

    # Standard phases (1, 2, 4, 5)
    title = f"PROBLEM ANALYSIS - {phase['title']}"

    parts.append(render_step_header(StepHeaderNode(
        title=title,
        script="problem-analysis",
        step=str(step)
    )))
    parts.append("")

    # XML mandate on step 1
    if step == 1:
        parts.append(XML_FORMAT_MANDATE)
        parts.append("")

    parts.append(render_current_action(CurrentActionNode(phase["actions"])))
    parts.append("")

    # Invoke after
    next_step = step + 1
    if next_step <= WORKFLOW.total_steps:
        next_cmd = f'python3 -m {MODULE_PATH} --step {next_step} '
        parts.append(render_invoke_after(InvokeAfterNode(cmd=next_cmd)))
    else:
        parts.append("WORKFLOW COMPLETE - Present final report to user.")

    return "\n".join(parts)


# =============================================================================
# CLI Entry Point
# =============================================================================


def main(
    step: int = None,
    confidence: str | None = None,
    iteration: int | None = None,
):
    """Entry point with parameter annotations for testing framework.

    Note: Parameters have defaults because actual values come from argparse.
    The annotations are metadata for the testing framework.
    """
    parser = argparse.ArgumentParser(
        description="Problem Analysis - Root cause identification workflow",
        epilog="Phases: gate (1) -> hypothesize (2) -> investigate (3) -> formulate (4) -> output (5)",
    )
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument(
        "--confidence",
        type=str,
        choices=["exploring", "low", "medium", "high"],
        default="exploring",
        help="Confidence level from previous iteration (Phase 3 only)",
    )
    parser.add_argument(
        "--iteration",
        type=int,
        default=1,
        help="Current iteration within Phase 3 (1-5)",
    )
    args = parser.parse_args()

    if args.step < 1:
        sys.exit("ERROR: --step must be >= 1")
    if args.step > WORKFLOW.total_steps:
        sys.exit(f"ERROR: --step cannot exceed {WORKFLOW.total_steps}")

    print(format_output(args.step, args.confidence, args.iteration))


if __name__ == "__main__":
    main()
