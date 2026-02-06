"""Single source of truth for QR phase configurations.

Definition locality: understanding a phase's configuration requires
reading only THIS file. Scripts import from here instead of duplicating
phase-specific knowledge across 4+ files per phase.

This works by:
1. QR_PHASES dict defines all phase configurations
2. get_phase_config() provides single entry point
3. Scripts import from here, not from each other
4. Changes to phase config require editing only THIS file

Invariants:
- Each phase has exactly one entry in QR_PHASES
- Step numbers match orchestrator STEPS dict
- Script paths are valid Python module paths
- Artifact paths are relative to state_dir
"""

from __future__ import annotations


# Phase configuration registry - ALL phase definitions in ONE place
#
# Keys: phase name as used in qr-{phase}.json filename
# Values: dict with:
#   workflow: "planner" or "executor"
#   work_step: orchestrator step that dispatches work agent
#   decompose_step: orchestrator step that dispatches QR decompose
#   verify_step: orchestrator step that dispatches parallel verify agents
#   route_step: orchestrator step that routes based on QR result
#   artifact: primary artifact being reviewed (relative to state_dir)
#   decompose_script: Python module for decomposition
#   verify_script: Python module for single-item verification
#   decompose_steps: number of steps in decompose script
#   verify_steps: number of steps in verify script

QR_PHASES: dict[str, dict] = {
    "plan-design": {
        "workflow": "planner",
        "work_step": 3,
        "decompose_step": 4,
        "verify_step": 5,
        "route_step": 6,
        "artifact": "plan.json",
        "decompose_script": "skills.planner.quality_reviewer.plan_design_qr_decompose",
        "verify_script": "skills.planner.quality_reviewer.plan_design_qr_verify",
        "decompose_steps": 13,
        "verify_steps": 3,
    },
    "plan-code": {
        "workflow": "planner",
        "work_step": 7,
        "decompose_step": 8,
        "verify_step": 9,
        "route_step": 10,
        "artifact": "plan.json",
        "decompose_script": "skills.planner.quality_reviewer.plan_code_qr_decompose",
        "verify_script": "skills.planner.quality_reviewer.plan_code_qr_verify",
        "decompose_steps": 13,
        "verify_steps": 3,
    },
    "plan-docs": {
        "workflow": "planner",
        "work_step": 11,
        "decompose_step": 12,
        "verify_step": 13,
        "route_step": 14,
        "artifact": "plan.json",
        "decompose_script": "skills.planner.quality_reviewer.plan_docs_qr_decompose",
        "verify_script": "skills.planner.quality_reviewer.plan_docs_qr_verify",
        "decompose_steps": 13,
        "verify_steps": 3,
    },
    "impl-code": {
        "workflow": "executor",
        "work_step": 2,
        "decompose_step": 3,
        "verify_step": 4,
        "route_step": 5,
        "artifact": "plan.json",
        "decompose_script": "skills.planner.quality_reviewer.impl_code_qr_decompose",
        "verify_script": "skills.planner.quality_reviewer.impl_code_qr_verify",
        "decompose_steps": 13,
        "verify_steps": 3,
    },
    "impl-docs": {
        "workflow": "executor",
        "work_step": 6,
        "decompose_step": 7,
        "verify_step": 8,
        "route_step": 9,
        "artifact": "plan.json",
        "decompose_script": "skills.planner.quality_reviewer.impl_docs_qr_decompose",
        "verify_script": "skills.planner.quality_reviewer.impl_docs_qr_verify",
        "decompose_steps": 13,
        "verify_steps": 3,
    },
}


def get_phase_config(phase: str) -> dict:
    """Single entry point for phase configuration.

    Understanding a phase's configuration requires reading only THIS file.
    Scripts import from here instead of hardcoding phase-specific values.

    Args:
        phase: Phase name (e.g., "plan-design", "impl-code")

    Returns:
        Phase configuration dict

    Raises:
        ValueError: If phase is unknown
    """
    if phase not in QR_PHASES:
        valid = ", ".join(sorted(QR_PHASES.keys()))
        raise ValueError(f"Unknown QR phase: {phase}. Valid phases: {valid}")
    return QR_PHASES[phase]


def get_all_phases() -> list[str]:
    """Return list of all phase names."""
    return list(QR_PHASES.keys())


def get_phases_for_workflow(workflow: str) -> list[str]:
    """Return phases belonging to a specific workflow.

    Args:
        workflow: "planner" or "executor"

    Returns:
        List of phase names for that workflow
    """
    return [
        phase for phase, config in QR_PHASES.items()
        if config["workflow"] == workflow
    ]


def get_orchestrator_module(phase: str) -> str:
    """Get orchestrator module path for a phase.

    Args:
        phase: Phase name

    Returns:
        Python module path for the orchestrator
    """
    config = get_phase_config(phase)
    workflow = config["workflow"]
    return f"skills.planner.orchestrator.{workflow}"


def get_route_step_info(phase: str) -> tuple[int, str, int]:
    """Get routing info for returning to orchestrator after QR.

    Replaces QR_ROUTING constant lookup with phase-based derivation.

    Args:
        phase: Phase name

    Returns:
        (route_step, module_path, total_steps)
    """
    config = get_phase_config(phase)
    workflow = config["workflow"]
    module_path = f"skills.planner.orchestrator.{workflow}"

    # Total steps depends on workflow
    if workflow == "planner":
        total_steps = 14
    else:  # executor
        total_steps = 10

    return (config["route_step"], module_path, total_steps)
