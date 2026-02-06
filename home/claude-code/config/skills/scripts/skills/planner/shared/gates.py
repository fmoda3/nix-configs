"""Unified gate output builder for planner and executor workflows.

Design rationale:
- Single implementation eliminates ~150 lines of duplicated gate logic
- Both planner.py and executor.py call this with their MODULE_PATH
- Parameters passed directly, no GateConfig indirection needed
- Uses deferred rendering pattern from constraints.py

Why gates.py instead of adding to constraints.py:
- constraints.py builds individual constraint ElementNodes
- gates.py builds complete gate step output (header, result, actions, invoke_after)
- gates.py depends on constraints.py builders, not the reverse
- Separation keeps each file focused on one abstraction level
"""

from dataclasses import dataclass

from skills.lib.workflow.ast import W, render, XMLRenderer
from skills.lib.workflow.ast.nodes import Document, TextNode
from skills.planner.shared.constraints import build_step_header
from skills.planner.shared.builders import (
    build_gate_result_node,
    build_forbidden_block,
    build_pedantic_enforcement,
)
from skills.planner.shared.qr.types import QRState, AgentRole


@dataclass
class GateResult:
    """Return type for build_gate_output.

    Why dataclass over plain str: callers (planner main()) distinguish
    terminal passes (workflow done, run translate) from non-terminal
    passes (proceed to next phase). A plain string loses this semantic.
    terminal_pass carries pass_step=None without requiring callers to
    re-derive it.
    """
    output: str
    terminal_pass: bool


def build_gate_output(
    module_path: str,
    script_name: str,
    qr_name: str,
    qr: QRState,
    step: int,
    work_step: int,
    pass_step: int | None,
    pass_message: str,
    fix_target: AgentRole | None,
    state_dir: str) -> GateResult:
    """Build complete gate step output for QR gates.

    Gates are decision points after QR sub-agent returns. They route to either:
    - pass_step: QR passed, proceed to next workflow phase
    - work_step: QR failed, loop back to fix issues

    Why unified builder:
    planner.py and executor.py have identical gate logic except for:
    - module_path: Which module to invoke for next step
    - script_name: Attribution in step_header ("planner" or "executor")
    Unifying eliminates ~150 lines of duplication.

    Why parameters instead of GateConfig:
    GateConfig was unnecessary indirection - the config was unpacked immediately
    in format_gate(). Direct parameters are clearer and match planner.py's
    qr_gate_step() closure pattern.

    Args:
        module_path: Full module path for invoke_after (e.g., "skills.planner.orchestrator.executor")
        script_name: Script attribution for step_header ("planner" or "executor")
        qr_name: Gate title (e.g., "Code QR", "plan-design QR")
        qr: Current QR state with passed flag and iteration count
        step: Current step number
        work_step: Step to return to on failure (fix loop)
        pass_step: Step to proceed to on success (None if terminal)
        pass_message: Success message shown to LLM
        fix_target: AgentRole to dispatch for fixes (developer, technical_writer, etc.)
        state_dir: State directory path for fix loop

    Returns:
        GateResult with rendered output and terminal_pass flag.
    """
    from skills.planner.shared.constants import PLANNER_TOTAL_STEPS, EXECUTOR_TOTAL_STEPS

    total_steps = PLANNER_TOTAL_STEPS if script_name == "planner" else EXECUTOR_TOTAL_STEPS
    nodes = []

    # Step header with gate title
    nodes.append(build_step_header(f"{qr_name} Gate", script_name, step))
    nodes.append(TextNode(""))

    # Gate result banner (PASS/FAIL)
    # WHY: Signature (passed only) omits iteration params to hide ceiling from LLM
    nodes.append(build_gate_result_node(passed=qr.passed))
    nodes.append(TextNode(""))

    # Build action content based on pass/fail
    action_children = []

    if qr.passed:
        # Pass gates forbid LLM from asking permission because workflows are
        # deterministic and all steps mandatory. Without this, Claude tends to
        # offer alternatives or seek confirmation, breaking automation.
        action_children.append(TextNode(pass_message))
        action_children.append(TextNode(""))
        action_children.append(build_forbidden_block(
            "Asking the user whether to proceed - the workflow is deterministic",
            "Offering alternatives to the next step - all steps are mandatory",
            "Interpreting 'proceed' as optional - EXECUTE immediately",
        ))
    else:
        action_children.append(build_pedantic_enforcement())
        action_children.append(TextNode(""))

        # Next action guidance
        target_name = fix_target.value if fix_target else "developer"
        action_children.append(TextNode("NEXT ACTION:"))
        action_children.append(TextNode("  Invoke the command in <invoke_after> below."))
        action_children.append(TextNode(f"  The next step will dispatch {target_name} with fix guidance."))
        action_children.append(TextNode(""))

        # WHY: Explicitly prohibits observed LLM failure mode (rationalizing skip via "diminishing returns")
        action_children.append(build_forbidden_block(
            "Fixing issues directly from this gate step",
            "Spawning agents directly from this gate step",
            "Using Edit/Write tools yourself",
            "Proceeding without invoking the next step",
            "Interpreting 'minor issues' as skippable",
            "Claiming 'diminishing returns' or 'comprehensive enough'",
            "Proceeding to next phase without QR PASS",
        ))

    # Workflow wrapper with actions
    nodes.append(TextNode("<workflow>"))
    nodes.append(W.el("current_action", *action_children).node())
    nodes.append(TextNode(""))

    # Three routing cases:
    # 1. Terminal pass (pass_step is None, qr passed): workflow complete
    # 2. Non-terminal pass (pass_step set, qr passed): proceed to pass_step
    # 3. Fail: loop back to work_step
    terminal_pass = qr.passed and pass_step is None

    if terminal_pass:
        # Why no invoke_after: terminal gate completes the workflow.
        # No subsequent step exists.
        nodes.append(TextNode("</workflow>"))
        doc = Document(children=nodes)
        return GateResult(output=render(doc, XMLRenderer()), terminal_pass=True)

    # Non-terminal: build invoke_after command
    if qr.passed:
        next_cmd = f"python3 -m {module_path} --step {pass_step}"
        if state_dir:
            next_cmd += f" --state-dir {state_dir}"
    else:
        next_cmd = f"python3 -m {module_path} --step {work_step} --state-dir {state_dir}"

    nodes.append(W.el("invoke_after", TextNode(next_cmd)).node())
    nodes.append(TextNode(""))
    nodes.append(W.el("next",
        TextNode("After current_action completes, execute invoke_after."),
        TextNode(f"Re-read now: {next_cmd}"),
        required="true"
    ).node())
    nodes.append(TextNode("</workflow>"))

    doc = Document(children=nodes)
    return GateResult(output=render(doc, XMLRenderer()), terminal_pass=False)
