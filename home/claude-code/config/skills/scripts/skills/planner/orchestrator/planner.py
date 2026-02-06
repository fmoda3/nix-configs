#!/usr/bin/env python3
"""
Interactive Sequential Planner - Orchestrator with parallel QR verification.

14-step planning workflow per INTENT.md:

Flow:
  1. plan-init (orchestrator captures context categories)
  2. context-verify (orchestrator self-checks handover completeness)
  3. plan-design-work (architect sub-agent)
  4. plan-design-qr-decompose -> 5. verify(N) -> 6. route
  7. plan-code-work (developer)
  8. plan-code-qr-decompose -> 9. verify(N) -> 10. route
  11. plan-docs-work (technical-writer)
  12. plan-docs-qr-decompose -> 13. verify(N) -> 14. route -> Plan Approved

QR Block Pattern (4 steps per phase):
  N   work        1 agent (architect/dev/TW)    Modified plan.json
  N+1 decompose   1 agent (QR)                  qr-{phase}.json
  N+2 verify      N agents (parallel, expanded) Each: PASS or FAIL
  N+3 route       0 agents (orchestrator)       Loop to N or proceed to N+4
"""

import argparse
import sys
import tempfile
from datetime import datetime

from skills.lib.workflow.types import AgentRole, Dispatch
from skills.lib.workflow.constants import (
    SUB_AGENT_QUESTION_FORMAT,
    QUESTION_RELAY_HANDLER,
)
from skills.lib.workflow.ast import (
    W, XMLRenderer, render, TextNode,
)
from skills.lib.workflow.prompts import subagent_dispatch
from skills.planner.shared.qr.types import QRState, QRStatus, LoopState
from skills.planner.shared.gates import build_gate_output, GateResult
from skills.planner.shared.qr.cli import add_qr_args
from skills.planner.shared.qr.utils import qr_file_exists, increment_qr_iteration
from skills.planner.shared.resources import get_mode_script_path, PlannerResourceProvider
from skills.planner.shared.builders import (
    build_xml_format_mandate,
    build_output_efficiency,
    build_task_prompt_guidance,
)
from skills.planner.shared.constraints import (
    build_orchestrator_constraint,
    build_step_header,
    build_state_banner,
)
from skills.lib.workflow.ast.nodes import Document


MODULE_PATH = "skills.planner.orchestrator.planner"


def _translate_plan(state_dir: str) -> str | None:
    """Mechanical translation: plan.json -> plan.md.

    Returns path to plan.md on success, None on failure.

    Why non-fatal: plan.json is the source of truth (the IR).
    plan.md is a convenience rendering. If translation fails,
    the workflow should still complete -- QR already approved
    the plan.json content.
    """
    from pathlib import Path
    from skills.planner.cli.plan_commands import PlanContext, _translate

    try:
        plan_md = str(Path(state_dir) / "plan.md")
        ctx = PlanContext(state_dir=Path(state_dir))
        _translate(ctx, plan_md)
        return plan_md
    except Exception as e:
        import sys
        print(f"Warning: plan.md translation failed: {e}", file=sys.stderr)
        return None

_provider = PlannerResourceProvider()

QUESTION_RELAY_INSTRUCTION = SUB_AGENT_QUESTION_FORMAT

def get_plan_format() -> str:
    """Read the plan format template from resources."""
    return _provider.get_resource("plan-format.md")


def _build_fix_mode_output(title, agent, agent_role, script, mode_total_steps, qr, ctx):
    """Build output for execute step in fix mode."""
    state_dir = ctx["state_dir"]

    action_children = []

    action_children.append(build_state_banner("PLAN-FIX", qr.iteration, "fix"))
    action_children.append(TextNode(""))
    action_children.append(TextNode("FIX MODE: QR found issues."))
    action_children.append(TextNode(""))

    action_children.append(build_orchestrator_constraint(extended=True))
    action_children.append(TextNode(""))

    mode_script = get_mode_script_path(script)
    invoke_cmd = f"python3 -m {mode_script} --step 1 --state-dir {state_dir}"

    dispatch_prompt = subagent_dispatch(
        agent_type=agent,
        command=invoke_cmd,
    )
    action_children.append(TextNode(dispatch_prompt))
    action_children.append(TextNode(""))
    action_children.append(TextNode(f"{agent.title()} reads QR report and fixes issues."))
    action_children.append(TextNode("After fixes complete, re-run QR for fresh verification."))

    next_step = ctx["step"] + 1
    next_cmd = f"python3 -m {MODULE_PATH} --step {next_step} --state-dir {state_dir}"

    return {
        "title": f"{title} - Fix Mode",
        "actions": action_children,
        "next": next_cmd,
    }


# =============================================================================
# Step Pattern Functions
# =============================================================================

def init_step(title, actions):
    """Step 1: creates state_dir, writes plan.json skeleton."""
    def handler(ctx):
        import json
        from pathlib import Path

        state_dir = tempfile.mkdtemp(prefix="planner-")

        plan_skeleton = {
            "schema_version": 2,
            "overview": {"problem": "", "approach": ""},
            "planning_context": {
                "decisions": [],
                "rejected_alternatives": [],
                "constraints": [],
                "risks": [],
            },
            "invisible_knowledge": {
                "system": "",
                "invariants": [],
                "tradeoffs": [],
            },
            "milestones": [],
            "waves": [],
        }
        plan_path = Path(state_dir) / "plan.json"
        plan_path.write_text(json.dumps(plan_skeleton, indent=2))

        print(f"STATE_DIR={state_dir}")

        return {
            "title": title,
            "actions": actions,
            "next": f"python3 -m {MODULE_PATH} --step 2 --state-dir {state_dir}",
        }

    return handler


def verify_step(title, actions):
    """Step 2: context verification."""
    def handler(ctx):
        from skills.planner.shared.resources import validate_state_dir_requirement

        state_dir = ctx["state_dir"]

        validate_state_dir_requirement(2, state_dir)

        return {
            "title": title,
            "actions": actions,
            "next": f"python3 -m {MODULE_PATH} --step 3 --state-dir {state_dir}",
        }

    return handler


def execute_dispatch_step(title, agent, agent_role, script, mode_total_steps, post_dispatch=None, phase=None):
    """Steps 3, 7, 11: work execution dispatch."""
    def handler(ctx):
        from skills.planner.shared.resources import validate_state_dir_requirement

        state_dir = ctx["state_dir"]
        qr = ctx["qr"]
        step = ctx["step"]

        validate_state_dir_requirement(step, state_dir)

        if qr.state == LoopState.RETRY:
            return _build_fix_mode_output(title, agent, agent_role, script, mode_total_steps, qr, ctx)

        action_children = []

        action_children.append(build_orchestrator_constraint(extended=True))
        action_children.append(TextNode(""))

        mode_script = get_mode_script_path(script)
        invoke_cmd = f"python3 -m {mode_script} --step 1 --state-dir {state_dir}"

        dispatch_prompt = subagent_dispatch(
            agent_type=agent,
            command=invoke_cmd,
        )
        action_children.append(TextNode(dispatch_prompt))
        action_children.append(TextNode(""))

        if post_dispatch:
            action_children.extend([TextNode(a) for a in post_dispatch])

        next_step = step + 1
        next_cmd = f"python3 -m {MODULE_PATH} --step {next_step} --state-dir {state_dir}"

        return {
            "title": title,
            "actions": action_children,
            "next": next_cmd,
        }

    handler.phase = phase
    return handler


def qr_decompose_step(title, phase, script, model=None):
    """Steps 4, 8, 12: QR decomposition dispatch.

    Dispatches single QR agent to decompose artifact into verification items.
    Agent outputs qr-{phase}.json.

    Decompose runs exactly once per phase. If qr-{phase}.json already exists,
    decomposition is skipped and flow proceeds directly to verify step.
    """
    def handler(ctx):
        state_dir = ctx["state_dir"]
        qr = ctx["qr"]
        step = ctx["step"]

        if qr_file_exists(state_dir, phase):
            verify_step = step + 1
            return {
                "title": f"{title} - Skipped (items already defined)",
                "actions": [
                    TextNode(f"QR items for {phase} already defined."),
                    TextNode("Proceeding to verification of existing items."),
                ],
                "next": f"python3 -m {MODULE_PATH} --step {verify_step} --state-dir {state_dir}",
            }

        action_children = []

        qr_name = f"QR-{phase.upper()}-DECOMPOSE"
        action_children.append(build_state_banner(qr_name, qr.iteration, "decompose"))
        action_children.append(TextNode(""))

        action_children.append(build_orchestrator_constraint(extended=True))
        action_children.append(TextNode(""))

        mode_script = get_mode_script_path(script)
        invoke_cmd = f"python3 -m {mode_script} --step 1 --state-dir {state_dir}"

        dispatch_prompt = subagent_dispatch(
            agent_type="quality-reviewer",
            command=invoke_cmd,
            model=model,
        )
        action_children.append(TextNode(dispatch_prompt))
        action_children.append(TextNode(""))

        action_children.append(TextNode("Expected output: qr-{phase}.json written to STATE_DIR"))
        action_children.append(TextNode("Orchestrator generates verification dispatch from this file."))

        next_step = step + 1
        next_cmd = f"python3 -m {MODULE_PATH} --step {next_step} --state-dir {state_dir}"

        return {
            "title": title,
            "actions": action_children,
            "next": next_cmd,
        }

    handler.phase = phase
    return handler


def _format_qr_item_flags(item_ids: list[str]) -> str:
    """Format item IDs as repeated --qr-item flags."""
    return " ".join(f"--qr-item {id}" for id in item_ids)


def qr_verify_step(title, phase):
    """Steps 5, 9, 13: Parallel QR verification with group-aware dispatch.

    Reads qr-{phase}.json and generates expanded dispatch.
    Decompose agent outputs item data. Orchestrator transforms this data
    into TemplateDispatchNode format. LLM sees ready-to-execute agent
    blocks, not substitution instructions.

    Uses repeated --qr-item flags (argparse action="append") instead of
    comma-separated --qr-items to avoid parsing ambiguity.
    """
    def handler(ctx):
        from skills.planner.shared.qr.utils import load_qr_state, query_items, by_status, by_blocking_severity
        from skills.planner.shared.qr.phases import get_phase_config
        from skills.lib.workflow.ast import TemplateDispatchNode, render_template_dispatch

        state_dir = ctx["state_dir"]
        step = ctx["step"]
        qr = ctx["qr"]

        qr_state = load_qr_state(state_dir, phase)
        if not qr_state or "items" not in qr_state:
            return {"error": f"qr-{phase}.json not found or malformed in {state_dir}"}

        if qr.state == LoopState.RETRY:
            increment_qr_iteration(state_dir, phase)

        # Dispatch only items at blocking severity for current iteration.
        # Below-threshold items (e.g., COULD on iteration 3) remain FAIL
        # in state but skip re-verification (reduces LLM token usage).
        iteration = qr_state.get("iteration", 1)
        items = query_items(qr_state, by_status("TODO", "FAIL"), by_blocking_severity(iteration))
        if not items:
            next_step = step + 1
            return {
                "title": title,
                "actions": [TextNode("All items already verified. Proceeding with pass.")],
                "if_pass": f"python3 -m {MODULE_PATH} --step {next_step} --state-dir {state_dir} --qr-status pass",
                "if_fail": f"python3 -m {MODULE_PATH} --step {next_step} --state-dir {state_dir} --qr-status pass",
            }

        config = get_phase_config(phase)
        verify_script = config["verify_script"]

        # Group items by group_id for batch verification.
        # Ungrouped items become singletons (group_id = item id). Singletons are
        # valid outcome when items don't share semantic relationships. See plan
        # sections 3.12 (affinity grouping allows singletons) and 3.13 (validation
        # accepts singletons as genuinely independent).
        groups = {}
        for item in items:
            gid = item.get("group_id") or item["id"]
            groups.setdefault(gid, []).append(item)

        targets = tuple(
            {
                "group_id": gid,
                "item_ids": ",".join(i["id"] for i in group_items),  # Display only
                "qr_item_flags": _format_qr_item_flags([i["id"] for i in group_items]),  # Command args
                "item_count": str(len(group_items)),
                "checks_summary": "; ".join(i.get("check", "")[:40] for i in group_items[:3]),
            }
            for gid, group_items in groups.items()
        )

        template = f"""Verify QR group: $group_id ($item_count items)
Items: $item_ids
Checks: $checks_summary

Start: python3 -m {verify_script} --step 1 --state-dir {state_dir} $qr_item_flags"""

        command = f"python3 -m {verify_script} --step 1 --state-dir {state_dir} $qr_item_flags"

        node = TemplateDispatchNode(
            agent_type="quality-reviewer",
            template=template,
            targets=targets,
            command=command,
            instruction=f"Verify {len(groups)} groups ({len(items)} items) in parallel.",
        )

        dispatch_xml = render_template_dispatch(node)

        action_children = [
            TextNode(f"VERIFY: {len(items)} items"),
            TextNode(""),
            TextNode(dispatch_xml),
            TextNode(""),
            TextNode(f"Dispatch ALL {len(items)} agents in parallel. Wait for ALL results."),
            TextNode("  - ALL pass -> --qr-status pass"),
            TextNode("  - ANY fail -> --qr-status fail"),
            TextNode(""),
            TextNode("These are the blocking items for this iteration."),
            TextNode("Every dispatched item must be verified. No exceptions."),
        ]

        next_step = step + 1
        base_cmd = f"python3 -m {MODULE_PATH} --step {next_step} --state-dir {state_dir}"

        return {
            "title": title,
            "actions": action_children,
            "if_pass": f"{base_cmd} --qr-status pass",
            "if_fail": f"{base_cmd} --qr-status fail",
        }

    handler.phase = phase
    return handler


def qr_route_step(title, phase, work_step, pass_step, pass_message, fix_target=None):
    """Steps 6, 10, 14: Route based on aggregated QR results.

    PASS: delete qr file, proceed to pass_step
    FAIL: loop to work_step (fix mode detected via qr-{phase}.json inspection)
    """
    def handler(ctx):
        qr = ctx["qr"]
        state_dir = ctx.get("state_dir", "")
        step = ctx["step"]

        return build_gate_output(
            module_path=MODULE_PATH,
            script_name="planner",
            qr_name=title,
            qr=qr,
            step=step,
            work_step=work_step,
            pass_step=pass_step,
            pass_message=pass_message,
            fix_target=fix_target,
            state_dir=state_dir,
        )

    handler.phase = phase
    return handler


# =============================================================================
# Step Definitions (1-14)
# =============================================================================

STEPS = {
    1: init_step(
        title="plan-init",
        actions=[
            "CONTEXT CAPTURE: Structure these categories from conversation:",
            "",
            "1. TASK_SPEC: what the plan is ABOUT, not how to write the plan (orchestration)",
            "   - SUBJECT: the user's underlying goal (what they want to accomplish)",
            "   - EXCLUDE: output instructions ('write to file X', 'create a plan for')",
            "   - CORRECT: 'OAuth-based authorization for the REST API'",
            "   - WRONG: 'Write plan to plans/foo-plan.md'",
            "   - Then: scope (directories/modules), out-of-scope",
            "2. CONSTRAINTS: MUST/SHOULD/MUST-NOT with sources -- or 'none confirmed'",
            "3. ENTRY_POINTS: file:function + why relevant -- or 'greenfield'",
            "4. REJECTED_ALTERNATIVES: what dismissed + why -- or 'none discussed'",
            "5. CURRENT_UNDERSTANDING: how system works; for bugs: symptom + reproduction",
            "6. ASSUMPTIONS: unverified inferences with confidence H/M/L -- or 'none'",
            "7. INVISIBLE_KNOWLEDGE: design rationale, invariants, accepted tradeoffs",
            "8. REFERENCE_DOCS: paths to project docs sub-agents should read (doc/*.md, specs/*) -- or 'none'",
            "",
            "FORMAT: High signal-to-noise. File refs over content. No ASCII diagrams.",
            "",
            "Mentally organize this context; you will write it to context.json in step 2.",
        ],
    ),
    2: verify_step(
        title="context-verify",
        actions=[
            "CONTEXT PERSISTENCE: Write context to STATE_DIR/context.json",
            "",
            "JSON SCHEMA:",
            "{",
            '  "task_spec": ["subject (not orchestration)", "scope: dir/module", "out-of-scope: X"],',
            '  "constraints": ["MUST: X", "SHOULD: Y"] or ["none confirmed"],',
            '  "entry_points": ["file:function - why relevant"] or ["greenfield"],',
            '  "rejected_alternatives": ["alternative - why dismissed"] or ["none discussed"],',
            '  "current_understanding": ["how system works", "bug: symptom + repro"],',
            '  "assumptions": ["inference (H/M/L confidence)"] or ["none"],',
            '  "invisible_knowledge": ["design rationale", "invariants", "tradeoffs"],',
            '  "reference_docs": ["doc/spec.md - what it specifies"] or ["none"]',
            "}",
            "",
            "ACTION: Use Write tool to create STATE_DIR/context.json with populated values.",
            "",
            "SELF-VERIFICATION (all must pass before proceeding to step 3):",
            "[ ] 1. Subject (what plan is ABOUT) statable in one sentence",
            "[ ] 2. At least one out-of-scope item explicit",
            "[ ] 3. At least one constraint OR explicit 'none confirmed'",
            "[ ] 4. Entry points identified OR 'greenfield'",
            "[ ] 5. Someone unfamiliar would understand why we're building this",
            "[ ] 6. Reference documentation paths captured or explicit 'none'",
            "",
            "IF ANY CHECK FAILS: gather missing context via AskUserQuestion or exploration.",
        ],
    ),
    # Plan-design phase (steps 3-6)
    3: execute_dispatch_step(
        title="plan-design-work",
        agent="architect",
        agent_role="architect",
        script="architect/plan_design.py",
        mode_total_steps=6,
        phase="plan-design",
        post_dispatch=[
            QUESTION_RELAY_HANDLER,
        ],
    ),
    4: qr_decompose_step(
        title="plan-design-qr-decompose",
        phase="plan-design",
        script="quality_reviewer/plan_design_qr_decompose.py",
        model="opus",
    ),
    5: qr_verify_step(
        title="plan-design-qr-verify",
        phase="plan-design",
    ),
    6: qr_route_step(
        title="plan-design-qr-route",
        phase="plan-design",
        work_step=3,
        pass_step=7,
        pass_message="Proceed to step 7 (plan-code-work).",
    ),
    # Plan-code phase (steps 7-10)
    7: execute_dispatch_step(
        title="plan-code-work",
        agent="developer",
        agent_role="developer",
        script="developer/plan_code.py",
        mode_total_steps=4,
        phase="plan-code",
        post_dispatch=[
            QUESTION_RELAY_HANDLER,
        ],
    ),
    8: qr_decompose_step(
        title="plan-code-qr-decompose",
        phase="plan-code",
        script="quality_reviewer/plan_code_qr_decompose.py",
        model="opus",
    ),
    9: qr_verify_step(
        title="plan-code-qr-verify",
        phase="plan-code",
    ),
    10: qr_route_step(
        title="plan-code-qr-route",
        phase="plan-code",
        work_step=7,
        pass_step=11,
        pass_message="Proceed to step 11 (plan-docs-work).",
        fix_target=AgentRole.DEVELOPER,
    ),
    # Plan-docs phase (steps 11-14)
    11: execute_dispatch_step(
        title="plan-docs-work",
        agent="technical-writer",
        agent_role="tw",
        script="technical_writer/plan_docs.py",
        mode_total_steps=6,
        phase="plan-docs",
        post_dispatch=[
            QUESTION_RELAY_HANDLER,
        ],
    ),
    12: qr_decompose_step(
        title="plan-docs-qr-decompose",
        phase="plan-docs",
        script="quality_reviewer/plan_docs_qr_decompose.py",
        model="opus",
    ),
    13: qr_verify_step(
        title="plan-docs-qr-verify",
        phase="plan-docs",
    ),
    14: qr_route_step(
        title="plan-docs-qr-route",
        phase="plan-docs",
        work_step=11,
        pass_step=None,
        pass_message="PLAN APPROVED. Ready for execution.",
        fix_target=AgentRole.TECHNICAL_WRITER,
    ),
}


def get_step_guidance(step: int, qr_status, state_dir) -> dict | str:
    """Returns guidance for a step.

    Iteration and fix mode derived from qr-{phase}.json file state.
    Phase derived from handler attribute set by step factory.
    """
    from skills.planner.shared.qr.utils import get_qr_iteration, has_qr_failures

    handler = STEPS.get(step)
    if not handler:
        return {"error": f"Invalid step {step}"}

    # Phase stored as handler attribute by step factory.
    # None for non-QR steps (1, 2).
    phase = getattr(handler, 'phase', None)
    iteration = get_qr_iteration(state_dir, phase) if state_dir and phase else 1

    status = QRStatus(qr_status) if qr_status else None
    is_fix_mode = state_dir and phase and has_qr_failures(state_dir, phase)
    state = LoopState.RETRY if is_fix_mode else LoopState.INITIAL
    qr = QRState(iteration=iteration, state=state, status=status)

    ctx = {
        "step": step,
        "qr": qr,
        "state_dir": state_dir,
    }

    return handler(ctx)


def format_output(step: int, qr_status, state_dir) -> str | GateResult:
    """Format output for display using XML format."""
    from skills.planner.shared.constants import PLANNER_TOTAL_STEPS

    guidance = get_step_guidance(step, qr_status, state_dir=state_dir)

    # Why passthrough: gate steps return GateResult. main() dispatches
    # on type -- str flows through unchanged, GateResult triggers
    # translate logic.
    if isinstance(guidance, GateResult):
        return guidance

    if isinstance(guidance, str):
        return guidance

    if "error" in guidance:
        return f"Error: {guidance['error']}"

    nodes = []

    nodes.append(build_step_header(guidance["title"], "planner", step))
    nodes.append(TextNode(""))

    if step == 1:
        nodes.append(build_xml_format_mandate())
        nodes.append(TextNode(""))
        nodes.append(build_output_efficiency())
        nodes.append(TextNode(""))

    next_cmd = guidance.get("next")
    if_pass = guidance.get("if_pass")
    if_fail = guidance.get("if_fail")

    if next_cmd or (if_pass and if_fail):
        nodes.append(TextNode("<workflow>"))

    actions = guidance["actions"]
    action_children = []
    for action in actions:
        if isinstance(action, str):
            action_children.append(TextNode(action))
        else:
            action_children.append(action)
    nodes.append(W.el("current_action", *action_children).node())
    nodes.append(TextNode(""))

    if if_pass and if_fail:
        from skills.lib.workflow.ast.nodes import ElementNode

        if_pass_node = ElementNode("if_pass", {}, [TextNode(if_pass)])
        if_fail_node = ElementNode("if_fail", {}, [TextNode(if_fail)])
        nodes.append(W.el("invoke_after", if_pass_node, if_fail_node).node())
        nodes.append(TextNode(""))
        nodes.append(
            W.el(
                "next",
                TextNode("After current_action completes, execute invoke_after."),
                TextNode(f"Re-read now: if_pass -> {if_pass}"),
                TextNode(f"            if_fail -> {if_fail}"),
                required="true",
            ).node()
        )
        nodes.append(TextNode("</workflow>"))
    elif next_cmd:
        nodes.append(W.el("invoke_after", TextNode(next_cmd)).node())
        nodes.append(TextNode(""))
        nodes.append(
            W.el(
                "next",
                TextNode("After current_action completes, execute invoke_after."),
                TextNode(f"Re-read now: {next_cmd}"),
                required="true",
            ).node()
        )
        nodes.append(TextNode("</workflow>"))

    doc = Document(children=nodes)
    return render(doc, XMLRenderer())


def main():
    """CLI entry point for planner orchestration."""
    parser = argparse.ArgumentParser(
        description="Interactive Sequential Planner (14-step orchestration workflow)",
        epilog="Step 1: init | Step 2: context-verify | Steps 3-14: work + QR phases",
    )

    parser.add_argument("--step", type=int, required=True)
    parser.add_argument("--state-dir", type=str, default=None, help="State directory path (for retry mode)")
    add_qr_args(parser)

    args = parser.parse_args()

    from skills.planner.shared.constants import PLANNER_GATE_STEPS, PLANNER_TOTAL_STEPS

    if args.step < 1:
        sys.exit("Error: step must be >= 1")

    # Validate state before running step (skip for step 1 which creates state)
    if args.step > 1 and args.state_dir:
        from skills.planner.shared.schema import validate_state, SchemaValidationError
        try:
            validate_state(args.state_dir)
        except SchemaValidationError as e:
            sys.exit(f"Schema validation failed: {e}")

    # Route steps require --qr-status; provide helpful output if missing
    if args.step in PLANNER_GATE_STEPS and not args.qr_status:
        gate_names = {6: "plan-design-qr-route", 10: "plan-code-qr-route", 14: "plan-docs-qr-route"}
        print(f"PLANNER - Step {args.step}/{PLANNER_TOTAL_STEPS}: {gate_names[args.step]}")
        print()
        print("This is a route step. Re-invoke with --qr-status pass or --qr-status fail")
        print("based on the aggregated QR output from the previous step.")
        sys.exit(0)

    result = format_output(args.step, args.qr_status, state_dir=args.state_dir)

    if isinstance(result, GateResult):
        # Why translate on terminal_pass: plan.json is the IR (modified by
        # QR fix cycles). plan.md is a rendered view. Terminal gate approval
        # signals plan.json is stable -- safe to regenerate the markdown.
        print(result.output)
        if result.terminal_pass and args.state_dir:
            plan_path = _translate_plan(args.state_dir)
            if plan_path:
                print(f"\nPlan rendered to: {plan_path}")
                print("Copy this file to the user's requested output path.")
    else:
        print(result)


if __name__ == "__main__":
    main()
