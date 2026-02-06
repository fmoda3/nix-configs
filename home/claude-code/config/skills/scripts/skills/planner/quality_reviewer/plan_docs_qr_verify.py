#!/usr/bin/env python3
"""QR verification for plan-docs phase.

Single-item verification mode for parallel QR dispatch.
Each verify agent receives --qr-item and validates ONE check.

Scope: Documentation quality only -- verifying that planning knowledge is
captured in documentation fields. This is NOT code review.

In scope:
- Invisible knowledge coverage (decisions documented somewhere)
- Temporal contamination in documentation strings
- WHY-not-WHAT quality in comments
- Structural completeness of documentation{} fields
- decision_ref validity

Out of scope (verified in plan-code phase):
- Code correctness (compilation, exports, types)
- Diff format validity
- Whether planned files exist on disk

For decomposition (generating items), see plan_docs_qr_decompose.py.
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


PHASE = "plan-docs"
WORKFLOW = "planner"


class PlanDocsVerify(VerifyBase):
    """QR verification for plan-docs phase."""

    PHASE = "plan-docs"

    def get_verification_guidance(self, item: dict, state_dir: str) -> list[str]:
        """Plan-docs-specific verification instructions."""
        scope = item.get("scope", "*")
        check = item.get("check", "")

        guidance = [
            "SCOPE CONSTRAINT: Verify doc_diff content ONLY.",
            "  - Review doc_diff fields, NOT diff fields",
            "  - diff field is OUT OF SCOPE (verified in plan-code)",
            "  - Verify against plan.json content, NOT filesystem",
            "",
            "EXTRACT doc_diffs:",
            f"  cat {state_dir}/plan.json | jq '[.milestones[].code_changes[] | {{id, file, doc_diff}}]'",
            "",
        ]

        if scope == "*":
            guidance.extend([
                "MACRO CHECK - Verify doc_diff across entire plan.json:",
                "",
                f"  Extract all doc_diffs:",
                f"    cat {state_dir}/plan.json | jq '[.milestones[].code_changes[] | {{id, file, diff: (.diff != \"\"), doc_diff: (.doc_diff != \"\")}}]'",
                "",
            ])
        elif scope.startswith("decision:"):
            dl_id = scope.split(":")[1]
            guidance.extend([
                f"DECISION COVERAGE CHECK - Focus on {dl_id}:",
                "",
                f"  Extract decision:",
                f"    cat {state_dir}/plan.json | jq '.planning_context.decisions[] | select(.id == \"{dl_id}\")'",
                "",
                f"  Verify this decision is referenced in at least one doc_diff:",
                f"    cat {state_dir}/plan.json | jq '.milestones[].code_changes[].doc_diff' | grep -i '{dl_id}'",
                "",
                "  Decision references should appear as: (ref: DL-XXX) or (DL-XXX)",
                "",
            ])
        elif scope.startswith("change:"):
            cc_id = scope.split(":")[1]
            guidance.extend([
                f"CODE_CHANGE DOC_DIFF CHECK - Focus on {cc_id}:",
                "",
                f"  Extract code_change:",
                f"    cat {state_dir}/plan.json | jq '.milestones[].code_changes[] | select(.id == \"{cc_id}\")'",
                "",
                "  Verify:",
                "  - If diff is non-empty, doc_diff should be non-empty",
                "  - doc_diff should be valid unified diff format",
                "  - No temporal contamination in doc_diff additions",
                "",
            ])
        elif scope.startswith("milestone:"):
            ms_id = scope.split(":")[1]
            guidance.extend([
                f"MILESTONE DOC_DIFF CHECK - Focus on {ms_id}:",
                "",
                f"  Extract milestone code_changes with doc_diff status:",
                f"    cat {state_dir}/plan.json | jq '.milestones[] | select(.id == \"{ms_id}\") | .code_changes[] | {{id, file, has_diff: (.diff != \"\"), has_doc_diff: (.doc_diff != \"\")}}'",
                "",
                "  Verify each code_change with diff has doc_diff.",
                "",
            ])
        else:
            # Generic scope -- still constrain to plan.json
            guidance.extend([
                f"SCOPED CHECK - Scope: {scope}",
                "",
                f"  Extract doc_diffs:",
                f"    cat {state_dir}/plan.json | jq '[.milestones[].code_changes[] | {{id, file, doc_diff}}]'",
                "",
                "  Find the relevant doc_diff and verify.",
                "",
            ])

        # Add check-specific guidance
        if "temporal" in check.lower():
            guidance.extend([
                "TEMPORAL CONTAMINATION CHECK in doc_diff:",
                "  Scan doc_diff additions (lines starting with +) for:",
                "  - CHANGE_RELATIVE: 'Added', 'Replaced', 'Changed', 'Now uses'",
                "  - BASELINE_REFERENCE: 'instead of', 'previously', 'replaces'",
                "  - LOCATION_DIRECTIVE: 'After X', 'Before Y', 'Insert'",
                "  - PLANNING_ARTIFACT: 'TODO', 'Will', 'Planned'",
                "  - INTENT_LEAKAGE: 'intentionally', 'deliberately', 'chose'",
                "",
            ])
        elif "baseline" in check.lower():
            guidance.extend([
                "BASELINE REFERENCE CHECK in doc_diff:",
                "  Look for references to removed/replaced code in doc_diff additions:",
                "  - 'Previously', 'Instead of', 'Replaces', 'Used to'",
                "  - 'Before this change', 'Old approach', 'Former'",
                "  Documentation should stand alone without knowing prior state.",
                "",
            ])
        elif "code_without_docs" in check.lower() or "missing doc_diff" in check.lower():
            guidance.extend([
                "CODE WITHOUT DOCS CHECK:",
                "  Verify code_changes with non-empty diff have non-empty doc_diff:",
                f"    cat {state_dir}/plan.json | jq '.milestones[].code_changes[] | select(.diff != \"\" and .doc_diff == \"\") | .id'",
                "",
                "  If any IDs returned, those code_changes need doc_diff.",
                "",
            ])
        elif "invalid" in check.lower() and "diff" in check.lower():
            guidance.extend([
                "INVALID DIFF FORMAT CHECK:",
                "  doc_diff must be valid unified diff format:",
                "  - Should start with '---', '@@', or 'diff'",
                "  - Should have proper hunk headers",
                "  - Lines should start with +, -, or space (context)",
                "",
            ])
        elif "decision" in check.lower() and ("coverage" in check.lower() or "uncovered" in check.lower()):
            guidance.extend([
                "DECISION COVERAGE CHECK:",
                "  Each decision in planning_context.decisions[] should appear",
                "  in at least one doc_diff as (ref: DL-XXX) or (DL-XXX).",
                "",
                "  List all decisions:",
                f"    cat {state_dir}/plan.json | jq '.planning_context.decisions[].id'",
                "",
                "  Search doc_diffs for references:",
                f"    cat {state_dir}/plan.json | jq '.milestones[].code_changes[].doc_diff' | grep -o 'DL-[0-9]\\+' | sort -u",
                "",
            ])
        elif "why" in check.lower() and "what" in check.lower():
            guidance.extend([
                "WHY-NOT-WHAT VERIFICATION in doc_diff:",
                "  Comments in doc_diff additions should explain reasoning, not describe code.",
                "  BAD: '// Added a new function' (describes action)",
                "  GOOD: '// Mutex serializes cache access' (explains purpose)",
                "",
            ])
        elif "docstring" in check.lower():
            guidance.extend([
                "MISSING DOCSTRING CHECK:",
                "  For functions added/modified in diff, verify doc_diff",
                "  includes docstring additions.",
                "",
                "  Look for function definitions in diff, then verify doc_diff",
                "  has corresponding documentation comments.",
                "",
            ])
        elif "coverage" in check.lower() or "captured" in check.lower():
            guidance.extend([
                "DECISION COVERAGE CHECK:",
                "  Verify planning knowledge appears in doc_diff fields:",
                "  - Each decision in planning_context.decisions[] should have a",
                "    corresponding reference in at least one doc_diff",
                "  - Reference format: (ref: DL-XXX) or (DL-XXX)",
                "",
                "  Search doc_diffs for decision refs:",
                f"    cat {state_dir}/plan.json | jq '.milestones[].code_changes[].doc_diff' | grep -o 'DL-[0-9]\\+' | sort -u",
                "",
            ])

        return guidance


def get_step_guidance(step: int, module_path: str = None, **kwargs) -> dict:
    """Gateway normalizes input and delegates to base class."""
    module_path = module_path or "skills.planner.quality_reviewer.plan_docs_qr_verify"
    qr_item = kwargs.get("qr_item")
    state_dir = kwargs.get("state_dir", "")

    if qr_item:
        # Normalize to list (backwards compat if single string passed)
        items = qr_item if isinstance(qr_item, list) else [qr_item]
        kwargs["qr_item"] = items
        verifier = PlanDocsVerify()
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
        "QR-Plan-Docs: Documentation quality validation workflow",
        extra_args=[
            (["--state-dir"], {"type": str, "help": "State directory path"}),
            (["--qr-item"], {"action": "append", "help": "Item ID (repeatable)"}),
        ],
    )
