#!/usr/bin/env python3
"""QR verification for plan-code phase.

Single-item verification mode for parallel QR dispatch.
Each verify agent receives --qr-item and validates ONE check.

Modes:
- --qr-item: Single item verification (for parallel dispatch)
- Default (legacy): Sequential 8-step full verification (deprecated)

For decomposition (generating items), see plan_code_qr_decompose.py.
"""

from skills.planner.shared.qr.types import QRState, LoopState
from skills.lib.workflow.ast import W, XMLRenderer, render
from skills.planner.shared.qr.utils import (
    get_qr_iteration,
    has_qr_failures,
    format_qr_result,
)
from skills.planner.shared.schema import get_qa_state_schema_example
from .qr_verify_base import VerifyBase


PHASE = "plan-code"
WORKFLOW = "planner"


class PlanCodeVerify(VerifyBase):
    """QR verification for plan-code phase."""

    PHASE = "plan-code"

    def get_verification_guidance(self, item: dict, state_dir: str) -> list[str]:
        """Plan-code-specific verification instructions."""
        scope = item.get("scope", "*")
        check = item.get("check", "")

        guidance = []

        if scope == "*":
            # Macro check
            guidance.extend([
                "MACRO CHECK - Verify across entire plan.json:",
                "",
                f"  Read plan.json:",
                f"    cat {state_dir}/plan.json | jq '.'",
                "",
            ])
        elif scope.startswith("code_change:"):
            cc_id = scope.split(":")[1]
            guidance.extend([
                f"CODE CHANGE CHECK - Focus on {cc_id}:",
                "",
                f"  Extract code_change:",
                f"    cat {state_dir}/plan.json | jq '.milestones[].code_changes[] | select(.id == \"{cc_id}\")'",
                "",
                f"  Read the target file from codebase to verify context lines.",
                "",
            ])
        elif scope.startswith("milestone:"):
            ms_id = scope.split(":")[1]
            guidance.extend([
                f"MILESTONE CHECK - Focus on {ms_id}:",
                "",
                f"  Extract milestone:",
                f"    cat {state_dir}/plan.json | jq '.milestones[] | select(.id == \"{ms_id}\")'",
                "",
            ])
        else:
            guidance.extend([
                f"SCOPED CHECK - Scope: {scope}",
                "",
                "  Read the relevant section from plan.json.",
                "",
            ])

        # Add check-specific guidance
        if "context lines" in check.lower() or "context line" in check.lower():
            guidance.extend([
                "CONTEXT LINE VERIFICATION:",
                "  1. Extract diff content from code_change",
                "  2. Identify context lines (lines starting with ' ')",
                "  3. Read actual file from codebase",
                "  4. Search for exact pattern match",
                "  - PASS: Context patterns found in file",
                "  - FAIL: Patterns not found (context drift)",
                "",
            ])
        elif "diff format" in check.lower() or "rule 0" in check.lower():
            guidance.extend([
                "DIFF FORMAT VERIFICATION:",
                "  RULE 0: File path must be exact (--- a/path, +++ b/path)",
                "  RULE 1: Context lines must exist in actual file",
                "  RULE 2: Function context in @@ header must be accurate",
                "  - Check: --- a/ and +++ b/ headers present and valid",
                "  - Check: @@ line has valid line numbers",
                "  - Check: +/- prefixes used correctly",
                "",
            ])
        elif "intent" in check.lower() and "ref" in check.lower():
            guidance.extend([
                "INTENT LINKAGE VERIFICATION:",
                "  - Each code_change.intent_ref must point to valid code_intent.id",
                "  - Each code_intent should have matching code_change",
                "  - No orphaned changes (intent_ref pointing to nonexistent intent)",
                "",
            ])
        elif "decision_ref" in check.lower():
            guidance.extend([
                "DECISION REF VERIFICATION:",
                "  - Each decision_ref (DL-XXX) must exist in planning_context.decisions",
                "  - Extract decision_refs from code_changes[].comments",
                "  - Verify each one exists",
                "",
            ])
        elif "temporal" in check.lower():
            guidance.extend([
                "TEMPORAL CONTAMINATION CHECK:",
                "  Scan all why_comments for:",
                "  - CHANGE_RELATIVE: 'Added', 'Replaced', 'Changed', 'Now uses'",
                "  - BASELINE_REFERENCE: 'instead of', 'previously', 'replaces'",
                "  - LOCATION_DIRECTIVE: 'After X', 'Before Y', 'Insert'",
                "  - PLANNING_ARTIFACT: 'TODO', 'Will', 'Planned'",
                "",
            ])
        elif "why" in check.lower() and "what" in check.lower():
            guidance.extend([
                "WHY-NOT-WHAT VERIFICATION:",
                "  Comments should explain reasoning, not describe code.",
                "  BAD: 'Added a new function' (describes action)",
                "  GOOD: 'Mutex serializes cache access' (explains purpose)",
                "",
            ])

        return guidance


def get_step_guidance(step: int, module_path: str = None, **kwargs) -> dict:
    """Gateway normalizes input and delegates to base class."""
    module_path = module_path or "skills.planner.quality_reviewer.plan_code_qr_verify"
    qr_item = kwargs.get("qr_item")
    state_dir = kwargs.get("state_dir", "")

    if qr_item:
        # Normalize to list (backwards compat if single string passed)
        items = qr_item if isinstance(qr_item, list) else [qr_item]
        kwargs["qr_item"] = items
        verifier = PlanCodeVerify()
        return verifier.get_step_guidance(step, module_path, **kwargs)

    return {
        "title": "Error: No Items",
        "actions": ["--qr-item required. Use: --qr-item a --qr-item b"],
        "next": "",
    }


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main
    mode_main(
        __file__,
        get_step_guidance,
        "QR-Plan-Code: Code change validation workflow",
        extra_args=[
            (["--state-dir"], {"type": str, "help": "State directory path"}),
            (["--qr-item"], {"action": "append", "help": "Item ID (repeatable)"}),
        ],
    )
