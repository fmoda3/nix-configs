#!/usr/bin/env python3
"""
Decision Critic - Structured decision criticism workflow.

Seven-step workflow:
  1-2: DECOMPOSITION - Extract structure, classify verifiability
  3-4: VERIFICATION - Generate questions, factored verification
  5-6: CHALLENGE - Contrarian perspective, alternative framing
  7:   SYNTHESIS - Verdict and recommendation

Research grounding:
  - Chain-of-Verification (Dhuliawala et al., 2023)
  - Self-Consistency (Wang et al., 2023)
"""

import argparse
import sys

from skills.lib.workflow.core import (
    Arg,
    StepDef,
    Workflow,
)
from skills.lib.workflow.ast import W, XMLRenderer, render, TextNode
from skills.lib.workflow.ast.nodes import (
    StepHeaderNode, CurrentActionNode, InvokeAfterNode,
)
from skills.lib.workflow.ast.renderer import (
    render_step_header, render_current_action, render_invoke_after,
)


STEPS = {
    1: {
        "title": "Extract Structure",
        "phase": "DECOMPOSITION",
        "actions": [
            "Extract and assign stable IDs (persist through ALL steps):",
            "",
            "CLAIMS [C1, C2, ...] - Factual assertions (3-7)",
            "  What facts/cause-effect relationships are assumed?",
            "",
            "ASSUMPTIONS [A1, A2, ...] - Unstated beliefs (2-5)",
            "  What is implied but not stated?",
            "",
            "CONSTRAINTS [K1, K2, ...] - Hard boundaries (1-4)",
            "  Technical/organizational limitations?",
            "",
            "JUDGMENTS [J1, J2, ...] - Subjective tradeoffs (1-3)",
            "  Where are values weighed against each other?",
            "",
            "FORMAT: C1: <claim> | A1: <assumption> | K1: <constraint>",
        ],
    },
    2: {
        "title": "Classify Verifiability",
        "phase": "DECOMPOSITION",
        "actions": [
            "Classify each item from Step 1:",
            "",
            "[V] VERIFIABLE - Can be checked against evidence",
            "[J] JUDGMENT - Subjective, no objective answer",
            "[C] CONSTRAINT - Given condition, accepted as fixed",
            "",
            "Edge case: prefer [V] over [J] over [C]",
            "",
            "FORMAT: C1 [V]: <claim> | A1 [J]: <assumption>",
            "COUNT: State how many [V] items need verification.",
        ],
    },
    3: {
        "title": "Generate Verification Questions",
        "phase": "VERIFICATION",
        "actions": [
            "For each [V] item, generate 1-3 verification questions:",
            "",
            "CRITERIA:",
            "  - Specific and independently answerable",
            "  - Designed to FALSIFY (not confirm)",
            "  - Each tests different aspect",
            "",
            "FORMAT:",
            "  C1 [V]: <claim>",
            "    Q1: <question>",
            "    Q2: <question>",
        ],
    },
    4: {
        "title": "Factored Verification",
        "phase": "VERIFICATION",
        "actions": [
            "Answer each question INDEPENDENTLY (most important step).",
            "",
            "EPISTEMIC BOUNDARY:",
            "  Use ONLY: established knowledge, stated constraints, logical inference",
            "  Do NOT: assume decision is correct/incorrect and work backward",
            "",
            "SEPARATE answer from implication:",
            "  Answer: factual response (evidence-based)",
            "  Implication: what this means for claim",
            "",
            "Mark each [V] item:",
            "  VERIFIED - answers consistent with claim",
            "  FAILED - answers reveal inconsistency/error",
            "  UNCERTAIN - insufficient evidence",
        ],
    },
    5: {
        "title": "Contrarian Perspective",
        "phase": "CHALLENGE",
        "actions": [
            "Generate the STRONGEST argument AGAINST the decision.",
            "",
            "Start from verification results:",
            "  FAILED = direct ammunition",
            "  UNCERTAIN = attack vectors",
            "",
            "Steel-man the opposition (best case, not strawman):",
            "  - What could go wrong?",
            "  - What alternatives dismissed too quickly?",
            "  - What second-order effects missed?",
            "",
            "OUTPUT:",
            "  CONTRARIAN POSITION: <one sentence>",
            "  ARGUMENT: <2-3 paragraphs>",
            "  KEY RISKS: <bullet list>",
        ],
    },
    6: {
        "title": "Alternative Framing",
        "phase": "CHALLENGE",
        "actions": [
            "Challenge the PROBLEM STATEMENT (not solution).",
            "",
            "Set aside proposed solution and ask:",
            "  - Is this the right problem or a symptom?",
            "  - What would a different stakeholder prioritize?",
            "  - What if constraints were negotiable?",
            "  - Is there a simpler formulation?",
            "",
            "OUTPUT:",
            "  ALTERNATIVE FRAMING: <one sentence>",
            "  WHAT THIS EMPHASIZES: <paragraph>",
            "  HIDDEN ASSUMPTIONS REVEALED: <list>",
            "  IMPLICATION FOR DECISION: <paragraph>",
        ],
    },
    7: {
        "title": "Synthesis and Verdict",
        "phase": "SYNTHESIS",
        "actions": [
            "VERDICT RUBRIC:",
            "",
            "ESCALATE when:",
            "  - Any FAILED on safety/security/compliance",
            "  - Any critical UNCERTAIN that cannot be cheaply verified",
            "  - Alternative framing reveals problem itself is wrong",
            "",
            "REVISE when:",
            "  - Any FAILED on core claim",
            "  - Multiple UNCERTAIN on feasibility/effort/impact",
            "  - Challenge phase revealed unaddressed gaps",
            "",
            "STAND when:",
            "  - No FAILED on core claims",
            "  - UNCERTAIN items explicitly acknowledged as accepted risks",
            "  - Challenges addressable within current approach",
            "",
            "OUTPUT:",
            "  VERDICT: STAND | REVISE | ESCALATE",
            "  VERIFICATION SUMMARY: (Verified/Failed/Uncertain lists)",
            "  CHALLENGE ASSESSMENT: (strongest challenge, response)",
            "  RECOMMENDATION: (specific next action)",
        ],
    },
}




# Workflow definition
WORKFLOW = Workflow(
    "decision-critic",
    StepDef(
        id="extract_structure",
        title="Extract Structure",
        actions=STEPS[1]["actions"],
    ),
    StepDef(
        id="classify_verifiability",
        title="Classify Verifiability",
        actions=STEPS[2]["actions"],
    ),
    StepDef(
        id="generate_questions",
        title="Generate Verification Questions",
        actions=STEPS[3]["actions"],
    ),
    StepDef(
        id="factored_verification",
        title="Factored Verification",
        actions=STEPS[4]["actions"],
    ),
    StepDef(
        id="contrarian_perspective",
        title="Contrarian Perspective",
        actions=STEPS[5]["actions"],
    ),
    StepDef(
        id="alternative_framing",
        title="Alternative Framing",
        actions=STEPS[6]["actions"],
    ),
    StepDef(
        id="synthesis",
        title="Synthesis and Verdict",
        actions=STEPS[7]["actions"],
    ),
    description="Structured decision criticism workflow",
    validate=False,
)


def main(
    step: int = None,
    decision: str | None = None,
):
    """Entry point with parameter annotations for testing framework.

    Note: Parameters have defaults because actual values come from argparse.
    The annotations are metadata for the testing framework.
    """
    parser = argparse.ArgumentParser(
        description="Decision Critic - Structured criticism workflow",
        epilog="Phases: decompose (1-2) -> verify (3-4) -> challenge (5-6) -> synthesize (7)",
    )
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument("--decision", type=str, help="Decision to critique (step 1)")

    args = parser.parse_args()

    if args.step < 1 or args.step > 7:
        sys.exit("Error: step must be 1-7")
    if args.step == 1 and not args.decision:
        sys.exit("Error: --decision required for step 1")

    # Map step number to step_id using workflow
    step_ids = list(WORKFLOW.steps.keys())
    step_id = step_ids[args.step - 1]
    step_def = WORKFLOW.steps[step_id]

    # Get next step info
    next_step_def = None
    if args.step < WORKFLOW.total_steps:
        next_step_id = step_ids[args.step]
        next_step_def = WORKFLOW.steps[next_step_id]

    # Add decision context to actions for step 1
    actions = step_def.actions[:]
    if args.step == 1 and args.decision:
        actions = [f"DECISION UNDER REVIEW: {args.decision}", ""] + actions

    # Build output using AST builder API
    parts = []

    # Step header
    parts.append(render_step_header(StepHeaderNode(
        title=f"DECISION CRITIC - {step_def.title}",
        script="decision_critic",
        step=str(args.step)
    )))
    parts.append("")

    # XML mandate for step 1
    if args.step == 1:
        parts.append("""<xml_format_mandate>
CRITICAL: All script outputs use XML format. You MUST:
1. Execute the action in <current_action>
2. When complete, invoke the exact command in <invoke_after>
3. DO NOT modify commands. DO NOT skip steps.
</xml_format_mandate>""")
        parts.append("")

    # Phase info
    if step_def.phase:
        parts.append(f"Phase: {step_def.phase}")
        parts.append("")

    # Current action
    parts.append(render_current_action(CurrentActionNode(actions)))
    parts.append("")

    # Next step info
    if next_step_def:
        next_cmd = (
            f'<invoke working-dir=".claude/skills/scripts" '
            f'cmd="python3 -m skills.decision_critic.decision_critic '
            f'--step {args.step + 1}" />'
        )
        parts.append(render_invoke_after(InvokeAfterNode(cmd=next_cmd)))
    elif args.step >= WORKFLOW.total_steps:
        parts.append("WORKFLOW COMPLETE - Present verdict to user.")

    print("\n".join(parts))


if __name__ == "__main__":
    main()
