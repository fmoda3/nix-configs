#!/usr/bin/env python3
"""QR verification for plan-design phase.

Single-item verification mode for parallel QR dispatch.
Each verify agent receives --qr-item and validates ONE check.

Modes:
- --qr-item: Single item verification (for parallel dispatch)
- Default (legacy): Sequential 7-step full verification (deprecated)

For decomposition (generating items), see plan_design_qr_decompose.py.
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


PHASE = "plan-design"
WORKFLOW = "planner"


class PlanDesignVerify(VerifyBase):
    """QR verification for plan-design phase."""

    PHASE = "plan-design"

    def get_verification_guidance(self, item: dict, state_dir: str) -> list[str]:
        """Plan-design-specific verification instructions."""
        scope = item.get("scope", "*")
        check = item.get("check", "")

        guidance = []

        if scope == "*":
            # Macro check
            guidance.extend([
                "MACRO CHECK - Verify across entire plan.json:",
                "",
                "  Read plan.json:",
                f"    cat {state_dir}/plan.json | jq '.'",
                "",
            ])
        elif scope.startswith("milestone:"):
            milestone_id = scope.split(":")[1]
            guidance.extend([
                f"MILESTONE CHECK - Focus on {milestone_id}:",
                "",
                f"  Read milestone:",
                f"    cat {state_dir}/plan.json | jq '.milestones[] | select(.id == \"{milestone_id}\")'",
                "",
            ])
        elif scope.startswith("code_intent:"):
            intent_id = scope.split(":")[1]
            guidance.extend([
                f"CODE INTENT CHECK - Focus on {intent_id}:",
                "",
                f"  Read intent (find containing milestone first):",
                f"    cat {state_dir}/plan.json | jq '.milestones[].code_intents[] | select(.id == \"{intent_id}\")'",
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
        if "decision_log" in check.lower() or "decision log" in check.lower():
            guidance.extend([
                "DECISION LOG VERIFICATION:",
                "  - Each entry should have multi-step reasoning",
                "  - BAD: 'Polling | Webhooks unreliable'",
                "  - GOOD: 'Polling | 30% webhook failure -> need fallback anyway'",
                "",
            ])
        elif "policy" in check.lower():
            guidance.extend([
                "POLICY DEFAULT VERIFICATION:",
                "  - Policy defaults affect user/org (lifecycle, capacity, failure handling)",
                "  - Must have Tier 1 (user-specified) backing in decision_log",
                "  - Technical defaults can use Tier 2-3 backing",
                "",
            ])
        elif "code_intent" in check.lower():
            guidance.extend([
                "CODE INTENT VERIFICATION:",
                "  - Each implementation milestone needs code_intents",
                "  - Each code_intent needs file path and behavior",
                "  - decision_refs should point to valid decision_log entries",
                "",
            ])

        return guidance


def get_step_guidance(step: int, module_path: str = None, **kwargs) -> dict:
    """Gateway normalizes input and delegates to base class."""
    module_path = module_path or "skills.planner.quality_reviewer.plan_design_qr_verify"
    qr_item = kwargs.get("qr_item")
    state_dir = kwargs.get("state_dir", "")

    if qr_item:
        # Normalize to list (backwards compat if single string passed)
        items = qr_item if isinstance(qr_item, list) else [qr_item]
        kwargs["qr_item"] = items
        verifier = PlanDesignVerify()
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
        "QR-Plan-Design: Plan completeness validation workflow",
        extra_args=[
            (["--state-dir"], {"type": str, "help": "State directory path"}),
            (["--qr-item"], {"action": "append", "help": "Item ID (repeatable)"}),
        ],
    )
