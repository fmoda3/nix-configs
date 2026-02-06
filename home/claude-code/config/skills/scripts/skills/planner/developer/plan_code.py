#!/usr/bin/env python3
"""Plan Code - Router script that dispatches to execute or fix.

This is a THIN router. The routing logic lives in shared/routing.py.
This file specifies only: which phase key to use.

Dispatches to:
- plan_code_execute.py: First-time code filling (4 steps)
- plan_code_qr_fix.py: Post-QR fix workflow (3 steps)

Selection based on QR state detection:
- No qr-plan-code.json or no FAIL items -> execute
- FAIL items present -> qr_fix
"""

from skills.planner.shared.routing import route_work_phase
from skills.planner.shared.resources import STATE_DIR_ARG_REQUIRED
from skills.planner.shared.qr.utils import has_qr_failures, get_qr_iteration


PHASE_KEY = "plan-code"


def get_step_guidance(
    step: int, module_path: str = None, **kwargs) -> dict:
    """Router: dispatch to execute or fix based on state.

    Routing logic lives in shared/routing.py (ONE place).
    This file specifies only: which phase key to use.
    """
    if step != 1:
        return {"error": "Router only handles step 1. Subsequent steps handled by dispatched script."}

    state_dir = kwargs.get("state_dir")
    if not state_dir:
        return {"error": "--state-dir required"}

    # Check fix mode via file state inspection
    if has_qr_failures(state_dir, PHASE_KEY):
        iteration = get_qr_iteration(state_dir, PHASE_KEY)
        target = "skills.planner.developer.plan_code_qr_fix"
        return {
            "title": "Plan Code - Routing to Fix Mode",
            "actions": [
                f"QR failures detected (iteration {iteration})",
                "Dispatching to FIX workflow.",
            ],
            "dispatch_to": target,
            "next": f"python3 -m {target} --step 1 --state-dir {state_dir}",
        }

    # Use routing module for state-based detection
    result = route_work_phase(state_dir, PHASE_KEY)

    if result["has_failures"]:
        iteration = get_qr_iteration(state_dir, PHASE_KEY)
        return {
            "title": "Plan Code - Routing to Fix Mode",
            "actions": [
                f"QR state detected: {result['failed_count']} failed items (iteration {iteration})",
                "Dispatching to FIX workflow.",
            ],
            "dispatch_to": result["target_module"],
            "next": f"python3 -m {result['target_module']} --step 1 --state-dir {state_dir}",
        }
    else:
        return {
            "title": "Plan Code - Routing to Execute Mode",
            "actions": [
                "First-time execution or no QR failures.",
                "Dispatching to EXECUTE workflow.",
            ],
            "dispatch_to": result["target_module"],
            "next": f"python3 -m {result['target_module']} --step 1 --state-dir {state_dir}",
        }


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main

    mode_main(
        __file__,
        get_step_guidance,
        "Plan-Code: Router for developer workflows",
        extra_args=[
            STATE_DIR_ARG_REQUIRED,
        ],
    )
