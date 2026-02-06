#!/usr/bin/env python3
"""Impl code execution - wave-aware implementation workflow.

4-step workflow for developer sub-agent:
  1. Implementation Planning (wave analysis from plan)
  2. Execute Current Wave (dispatch developer agents in parallel)
  3. Verify Wave (run tests, verify completion)
  4. Wave Iteration (next wave or return to orchestrator)

This is the EXECUTE script for first-time implementation.
For QR fix mode, see exec_implement_qr_fix.py.
Router (exec_implement.py) dispatches to appropriate script.
"""

from skills.lib.workflow.ast import W, XMLRenderer, render


STEPS = {
    1: "Implementation Planning",
    2: "Execute Current Wave",
    3: "Verify Wave",
    4: "Wave Iteration",
}


def get_step_guidance(
    step: int, module_path: str = None, **kwargs) -> dict:
    """Return guidance for the given step."""
    MODULE_PATH = module_path or "skills.planner.developer.exec_implement_execute"
    state_dir = kwargs.get("state_dir", "")
    state_dir_arg = f" --state-dir {state_dir}" if state_dir else ""

    if step == 1:
        banner = render(
            W.el("state_banner", checkpoint="IMPLEMENTATION", iteration="1", mode="work").build(),
            XMLRenderer()
        )
        return {
            "title": STEPS[1],
            "actions": [
                banner,
                "",
                "TASK: Execute milestones from approved plan using wave-aware dispatch.",
                "",
                "WAVE-AWARE EXECUTION:",
                "  - Milestones within same wave: dispatch in PARALLEL",
                "    (Multiple Task calls in single response)",
                "  - Waves execute SEQUENTIALLY",
                "    (Wait for wave N to complete before starting wave N+1)",
                "",
                "Use waves identified in executor step 1.",
                "",
                "FOR EACH WAVE:",
                "  1. Dispatch developer agents for ALL milestones in wave",
                "  2. Each prompt must include:",
                "     - Plan file path",
                "     - Milestone number and name",
                "     - Files to create/modify",
                "     - Acceptance criteria",
                "  3. Wait for ALL agents in wave to complete",
                "  4. Run tests: pytest / tsc / go test -race",
                "  5. Proceed to next wave",
            ],
            "next": f"python3 -m {MODULE_PATH} --step 2{state_dir_arg}",
        }

    elif step == 2:
        return {
            "title": STEPS[2],
            "actions": [
                "Execute current wave milestones.",
                "",
                "Dispatch developer agent for each milestone in wave.",
                "Use wave-aware parallel dispatch:",
                "  - Multiple milestones in same wave = multiple Task calls in ONE message",
                "  - Wait for all to complete",
                "",
                "Each developer prompt includes:",
                "  - PLAN_FILE: path to the executed plan",
                "  - MILESTONE: specific milestone to implement",
                "  - FILES: exact paths to create/modify",
                "  - ACCEPTANCE: criteria from plan",
            ],
            "next": f"python3 -m {MODULE_PATH} --step 3{state_dir_arg}",
        }

    elif step == 3:
        return {
            "title": STEPS[3],
            "actions": [
                "Verify wave completion.",
                "",
                "1. Check all agents in wave completed",
                "2. Run tests:",
                "   pytest / tsc / go test -race",
                "3. Pass criteria: 100% tests pass, zero warnings",
                "",
                "If tests fail:",
                "  - Clear problem + solution: Task(developer) immediately",
                "  - Difficult/unclear: Task(debugger) to diagnose first",
                "  - Uncertain: AskUserQuestion with options",
            ],
            "next": f"python3 -m {MODULE_PATH} --step 4{state_dir_arg}",
        }

    elif step == 4:
        return {
            "title": STEPS[4],
            "actions": [
                "Wave iteration check.",
                "",
                "If more waves remain:",
                "  - Update wave index",
                "  - Return to step 2 to execute next wave",
                "",
                "If all waves complete:",
                "  Your complete response must be exactly: PASS",
                "  Do not add summaries, explanations, or any other text.",
            ],
            "next": "",
        }

    return {"error": f"Invalid step {step}"}


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main

    mode_main(
        __file__,
        get_step_guidance,
        "Exec-Implement-Execute: Wave-aware implementation workflow",
        extra_args=[
            (["--state-dir"], {"type": str, "help": "State directory path"}),
        ],
    )
