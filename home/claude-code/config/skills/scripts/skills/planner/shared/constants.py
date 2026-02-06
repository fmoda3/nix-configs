"""Workflow step configuration constants.

WHY: Total step counts were hardcoded in multiple locations:
- STEPS dicts (implicit via key count)
- STEP_HANDLERS range() calls
- Final step fallback logic (magic number 6)

Centralizing these constants prevents drift and makes
workflow structure explicit.
"""

# Planner orchestrator workflow (14 steps with parallel QR)
PLANNER_TOTAL_STEPS = 14
PLANNER_GATE_STEPS = frozenset({6, 10, 14})  # QR route steps (gates)

# Executor orchestrator workflow (10 steps with parallel QR)
EXECUTOR_TOTAL_STEPS = 10
EXECUTOR_GATE_STEPS = frozenset({5, 9})

# Sub-workflow step counts
PLAN_DESIGN_TOTAL_STEPS = 6
PLAN_CODE_TOTAL_STEPS = 4
PLAN_DOCS_TOTAL_STEPS = 6
EXEC_IMPLEMENT_TOTAL_STEPS = 4
EXEC_DOCS_TOTAL_STEPS = 6

# QR workflow step counts (for QR modules)
QR_PLAN_DESIGN_TOTAL_STEPS = 7
QR_PLAN_CODE_TOTAL_STEPS = 8
QR_PLAN_DOCS_TOTAL_STEPS = 6
QR_IMPL_CODE_TOTAL_STEPS = 5
QR_IMPL_DOCS_TOTAL_STEPS = 4


def validate_step_count(steps_dict: dict, expected_total: int, workflow_name: str) -> None:
    """Validate that STEPS dict matches expected total.

    WHY: Step count constants can diverge from actual handler counts.
    If a developer adds step 12, they must remember to update the constant.
    This validation enforces consistency at module load time.

    Call at module load: validate_step_count(STEPS, PLANNER_TOTAL_STEPS, 'planner')
    """
    actual = len(steps_dict)
    if actual != expected_total:
        raise ValueError(f"{workflow_name}: STEPS has {actual} entries but {expected_total} expected")
