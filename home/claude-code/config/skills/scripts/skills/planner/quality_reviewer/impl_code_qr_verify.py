#!/usr/bin/env python3
"""QR verification for impl-code phase.

Single-item verification mode for parallel QR dispatch.
Each verify agent receives --qr-item and validates ONE check.

Modes:
- --qr-item: Single item verification (for parallel dispatch)
- Default (legacy): Sequential 5-step full verification (deprecated)

For decomposition (generating items), see impl_code_qr_decompose.py.
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


PHASE = "impl-code"
WORKFLOW = "executor"


class ImplCodeVerify(VerifyBase):
    """QR verification for impl-code phase."""

    PHASE = "impl-code"

    def get_verification_guidance(self, item: dict, state_dir: str) -> list[str]:
        """Impl-code-specific verification instructions."""
        scope = item.get("scope", "*")
        check = item.get("check", "")

        guidance = []

        if scope == "*":
            guidance.extend([
                "MACRO CHECK - Verify across all implemented code:",
                "",
                f"  Read plan.json for acceptance criteria:",
                f"    cat {state_dir}/plan.json | jq '.milestones[].acceptance_criteria'",
                "",
                "  Read modified files from codebase.",
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
                "  Read the files associated with this milestone.",
                "",
            ])
        elif scope.startswith("file:"):
            file_path = scope.split(":", 1)[1]
            guidance.extend([
                f"FILE CHECK - Focus on {file_path}:",
                "",
                f"  Read the file content from codebase.",
                "",
            ])
        else:
            guidance.extend([
                f"SCOPED CHECK - Scope: {scope}",
                "",
                "  Read the relevant code from codebase.",
                "",
            ])

        # Add check-specific guidance
        if "factored" in check.lower() and "expect" in check.lower():
            guidance.extend([
                "FACTORED VERIFICATION - STEP 1 (Expectations):",
                "  Write down what you EXPECT to observe in code",
                "  BEFORE reading the actual implementation.",
                "  | Criterion | Expected Code Evidence |",
                "  | --------- | ---------------------- |",
                "  Fill this table FIRST, then proceed to observation step.",
                "",
            ])
        elif "factored" in check.lower() and "actually" in check.lower():
            guidance.extend([
                "FACTORED VERIFICATION - STEP 2 (Observations):",
                "  Document what the code ACTUALLY does",
                "  WITHOUT re-reading acceptance criteria.",
                "  | Function/Section | What It Actually Does |",
                "  | ---------------- | --------------------- |",
                "  Note behaviors, not what it should do.",
                "",
            ])
        elif "factored" in check.lower() and "compare" in check.lower():
            guidance.extend([
                "FACTORED VERIFICATION - STEP 3 (Comparison):",
                "  NOW compare your expectations vs observations.",
                "  | Criterion | Expected | Observed | Match? |",
                "  | --------- | -------- | -------- | ------ |",
                "  Report mismatches as FAIL.",
                "",
            ])
        elif "marker" in check.lower() or ":perf:" in check.lower() or ":unsafe:" in check.lower():
            guidance.extend([
                "INTENT MARKER VALIDATION:",
                "  Valid format: ':MARKER: [what]; [why]'",
                "  - Must have semicolon",
                "  - Must have non-empty why after semicolon",
                "  Invalid: ':PERF: faster' (no semicolon)",
                "  Valid: ':PERF: faster; reduces API calls by 50%'",
                "",
            ])
        elif "temporal" in check.lower():
            guidance.extend([
                "TEMPORAL CONTAMINATION CHECK:",
                "  Scan all code comments for:",
                "  - CHANGE_RELATIVE: 'Added', 'Replaced', 'Changed', 'Now uses'",
                "  - BASELINE_REFERENCE: 'instead of', 'previously', 'replaces'",
                "",
            ])
        elif "god function" in check.lower() or "nesting" in check.lower():
            guidance.extend([
                "STRUCTURAL CHECK:",
                "  - No functions >50 lines",
                "  - No nesting >3 levels",
                "  Count lines and nesting depth for flagged functions.",
                "",
            ])
        elif "duplicate" in check.lower():
            guidance.extend([
                "DUPLICATION CHECK:",
                "  Look for copy-pasted code blocks",
                "  or parallel functions doing similar things.",
                "",
            ])
        elif "code quality" in check.lower():
            guidance.extend([
                "CODE QUALITY CHECK:",
                "  Apply all 8 quality documents:",
                "  01-naming, 02-structure, 03-patterns, 04-repetition,",
                "  05-documentation, 06-module, 07-cross-file, 08-codebase",
                "",
            ])

        return guidance


def get_step_guidance(step: int, module_path: str = None, **kwargs) -> dict:
    """Gateway normalizes input and delegates to base class."""
    module_path = module_path or "skills.planner.quality_reviewer.impl_code_qr_verify"
    qr_item = kwargs.get("qr_item")
    state_dir = kwargs.get("state_dir", "")

    if qr_item:
        # Normalize to list (backwards compat if single string passed)
        items = qr_item if isinstance(qr_item, list) else [qr_item]
        kwargs["qr_item"] = items
        verifier = ImplCodeVerify()
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
        "QR-Impl-Code: Post-implementation code quality review workflow",
        extra_args=[
            (["--state-dir"], {"type": str, "help": "State directory path"}),
            (["--qr-item"], {"action": "append", "help": "Item ID (repeatable)"}),
        ],
    )
