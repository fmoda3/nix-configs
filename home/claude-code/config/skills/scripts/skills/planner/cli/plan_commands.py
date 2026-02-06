"""Plan manipulation commands as plain functions.

Each public function with 'ctx' as first param is auto-discovered as RPC method.
Function names use underscores, converted to hyphens for method names.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from ..shared.schema import Plan


def _get_schema():
    """Lazy import to avoid circular deps."""
    from ..shared.schema import (
        Plan, Overview, Milestone, CodeIntent, CodeChange, Decision,
        Documentation, Docstring, FunctionBlock, InlineComment, ReadmeEntry,
        DiagramGraph, DiagramNode, DiagramEdge, validate_state,
    )
    return {
        'Plan': Plan, 'Overview': Overview, 'Milestone': Milestone,
        'CodeIntent': CodeIntent, 'CodeChange': CodeChange, 'Decision': Decision,
        'Documentation': Documentation, 'Docstring': Docstring,
        'FunctionBlock': FunctionBlock, 'InlineComment': InlineComment, 'ReadmeEntry': ReadmeEntry,
        'DiagramGraph': DiagramGraph, 'DiagramNode': DiagramNode,
        'DiagramEdge': DiagramEdge, 'validate_state': validate_state,
    }


@dataclass
class PlanContext:
    """Context passed to all plan commands."""
    state_dir: Path

    def plan_path(self) -> Path:
        return self.state_dir / "plan.json"

    def load_plan(self) -> "Plan":
        schema = _get_schema()
        path = self.plan_path()
        if not path.exists():
            raise FileNotFoundError(f"plan.json not found at {path}")
        data = json.loads(path.read_text())
        return schema['Plan'].model_validate(data)

    def save_plan(self, plan: "Plan") -> None:
        schema = _get_schema()
        path = self.plan_path()
        tmp_path = path.with_suffix(".tmp")
        tmp_path.write_text(plan.model_dump_json(indent=2))
        tmp_path.rename(path)
        schema['validate_state'](str(self.state_dir))


def _parse_csv(value: str | None) -> list[str]:
    """Parse comma-separated string to list."""
    if not value:
        return []
    return [v.strip() for v in value.split(",") if v.strip()]


def _check_version(entity, provided: int | None, entity_id: str) -> None:
    """CAS version check. Raises if mismatch."""
    if provided is None:
        return
    current = getattr(entity, 'version', 1)
    if provided != current:
        raise ValueError(
            f"Version mismatch for {entity_id}: provided {provided}, current {current}. "
            f"Re-read entity and retry with --version {current}"
        )


def _bump_version(entity) -> None:
    """Increment entity version."""
    if hasattr(entity, 'version'):
        entity.version += 1


# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

def init(ctx: PlanContext, task: str, title: str = "Untitled Plan") -> dict:
    """Initialize new plan.json with task description."""
    schema = _get_schema()
    path = ctx.plan_path()

    if path.exists():
        raise FileExistsError(f"plan.json already exists at {path}")

    plan = schema['Plan'](overview=schema['Overview'](problem=task, approach=""))
    ctx.save_plan(plan)

    return {"id": plan.plan_id, "version": 1, "operation": "created"}


# -----------------------------------------------------------------------------
# Architect Phase
# -----------------------------------------------------------------------------

def set_milestone(ctx: PlanContext, name: str = None, id: str = None,
                  version: int = None, files: str = None, flags: str = None,
                  requirements: str = None, acceptance_criteria: str = None,
                  tests: str = None) -> dict:
    """Create or update milestone."""
    schema = _get_schema()
    plan = ctx.load_plan()

    files_list = _parse_csv(files)
    flags_list = _parse_csv(flags)
    requirements_list = _parse_csv(requirements)
    acceptance_list = _parse_csv(acceptance_criteria)
    tests_list = _parse_csv(tests)

    if id:
        # UPDATE
        ms = plan.get_milestone(id)
        if not ms:
            ids = [m.id for m in plan.milestones]
            raise ValueError(f"Milestone {id} not found. Valid: {ids}")

        _check_version(ms, version, id)

        if name:
            ms.name = name
        if files_list:
            ms.files = files_list
        if flags_list:
            ms.flags = flags_list
        if requirements_list:
            ms.requirements = requirements_list
        if acceptance_list:
            ms.acceptance_criteria = acceptance_list
        if tests_list:
            ms.tests = tests_list

        _bump_version(ms)
        ctx.save_plan(plan)
        return {"id": ms.id, "version": ms.version, "operation": "updated"}
    else:
        # CREATE
        if version is not None:
            raise ValueError("--version only valid for updates (when --id provided)")
        if not name:
            raise ValueError("--name required for create")

        num = len(plan.milestones) + 1
        mid = f"M-{num:03d}"

        ms = schema['Milestone'](
            id=mid, version=1, number=num, name=name,
            files=files_list, flags=flags_list, requirements=requirements_list,
            acceptance_criteria=acceptance_list, tests=tests_list,
        )
        plan.milestones.append(ms)
        ctx.save_plan(plan)
        return {"id": mid, "version": 1, "operation": "created"}


def set_intent(ctx: PlanContext, milestone: str, file: str = None,
               behavior: str = None, id: str = None, version: int = None,
               function: str = None, decision_refs: str = None) -> dict:
    """Create or update code intent."""
    schema = _get_schema()
    plan = ctx.load_plan()

    ms = plan.get_milestone(milestone)
    if not ms:
        ids = [m.id for m in plan.milestones]
        raise ValueError(f"Milestone {milestone} not found. Valid: {ids}")

    refs_list = _parse_csv(decision_refs)
    for ref in refs_list:
        if not plan.get_decision(ref):
            raise ValueError(f"Decision {ref} not found")

    if id:
        # UPDATE
        _, ci = plan.get_intent(id)
        if not ci:
            all_intents = [c.id for m in plan.milestones for c in m.code_intents]
            raise ValueError(f"Intent {id} not found. Valid: {all_intents}")

        _check_version(ci, version, id)

        if file:
            ci.file = file
        if function is not None:
            ci.function = function if function else None
        if behavior:
            ci.behavior = behavior
        if refs_list:
            ci.decision_refs = refs_list

        _bump_version(ci)
        ctx.save_plan(plan)
        return {"id": ci.id, "version": ci.version, "operation": "updated"}
    else:
        # CREATE
        if version is not None:
            raise ValueError("--version only valid for updates")
        if not file or not behavior:
            raise ValueError("--file and --behavior required for create")

        num = len(ms.code_intents) + 1
        cid = f"CI-{ms.id}-{num:03d}"

        ci = schema['CodeIntent'](
            id=cid, version=1, file=file, function=function,
            behavior=behavior, decision_refs=refs_list,
        )
        ms.code_intents.append(ci)
        ctx.save_plan(plan)
        return {"id": cid, "version": 1, "operation": "created"}


def set_decision(ctx: PlanContext, decision: str = None, reasoning: str = None,
                 id: str = None, version: int = None) -> dict:
    """Create or update decision."""
    schema = _get_schema()
    plan = ctx.load_plan()

    if id:
        # UPDATE
        dl = plan.get_decision(id)
        if not dl:
            dids = [d.id for d in plan.planning_context.decisions]
            raise ValueError(f"Decision {id} not found. Valid: {dids}")

        _check_version(dl, version, id)

        if decision:
            dl.decision = decision
        if reasoning:
            dl.reasoning = reasoning

        _bump_version(dl)
        ctx.save_plan(plan)
        return {"id": dl.id, "version": dl.version, "operation": "updated"}
    else:
        # CREATE
        if version is not None:
            raise ValueError("--version only valid for updates")
        if not decision or not reasoning:
            raise ValueError("--decision and --reasoning required for create")

        num = len(plan.planning_context.decisions) + 1
        did = f"DL-{num:03d}"

        dl = schema['Decision'](id=did, version=1, decision=decision, reasoning=reasoning)
        plan.planning_context.decisions.append(dl)
        ctx.save_plan(plan)
        return {"id": did, "version": 1, "operation": "created"}


def set_diagram(ctx: PlanContext, type: str, scope: str, title: str,
                id: str = None) -> dict:
    """Create or update diagram graph."""
    schema = _get_schema()
    plan = ctx.load_plan()

    if id:
        dg = next((d for d in plan.diagram_graphs if d.id == id), None)
        if not dg:
            raise ValueError(f"Diagram {id} not found")
        dg.type = type
        dg.scope = scope
        dg.title = title
        operation = "updated"
    else:
        next_num = len(plan.diagram_graphs) + 1
        new_id = f"DIAG-{next_num:03d}"
        dg = schema['DiagramGraph'](id=new_id, type=type, scope=scope, title=title)
        plan.diagram_graphs.append(dg)
        id = new_id
        operation = "created"

    ctx.save_plan(plan)
    return {"id": id, "version": 1, "operation": operation}


def add_diagram_node(ctx: PlanContext, diagram: str, node_id: str, label: str,
                     type: str = None) -> dict:
    """Add node to diagram."""
    schema = _get_schema()
    plan = ctx.load_plan()

    dg = next((d for d in plan.diagram_graphs if d.id == diagram), None)
    if not dg:
        raise ValueError(f"Diagram {diagram} not found")

    if any(n.id == node_id for n in dg.nodes):
        raise ValueError(f"Node {node_id} already exists in {diagram}")

    node = schema['DiagramNode'](id=node_id, label=label, type=type)
    dg.nodes.append(node)
    ctx.save_plan(plan)

    return {"id": node_id, "diagram": diagram, "operation": "created"}


def add_diagram_edge(ctx: PlanContext, diagram: str, source: str, target: str,
                     label: str, protocol: str = None) -> dict:
    """Add edge to diagram."""
    schema = _get_schema()
    plan = ctx.load_plan()

    dg = next((d for d in plan.diagram_graphs if d.id == diagram), None)
    if not dg:
        raise ValueError(f"Diagram {diagram} not found")

    edge = schema['DiagramEdge'](source=source, target=target, label=label, protocol=protocol)
    dg.edges.append(edge)

    errors = plan.validate_diagram_edges(diagram)
    if errors:
        dg.edges.pop()
        raise ValueError(errors[0])

    ctx.save_plan(plan)
    return {"source": source, "target": target, "diagram": diagram, "operation": "created"}


# -----------------------------------------------------------------------------
# Developer Phase
# -----------------------------------------------------------------------------

def set_change(ctx: PlanContext, milestone: str, file: str = None,
               diff: str = None, id: str = None, version: int = None,
               intent_ref: str = None, comments: str = None) -> dict:
    """Create or update code change."""
    schema = _get_schema()
    plan = ctx.load_plan()

    ms = plan.get_milestone(milestone)
    if not ms:
        ids = [m.id for m in plan.milestones]
        raise ValueError(f"Milestone {milestone} not found. Valid: {ids}")

    if intent_ref:
        _, ci = plan.get_intent(intent_ref)
        if not ci:
            all_intents = [c.id for m in plan.milestones for c in m.code_intents]
            raise ValueError(f"Intent {intent_ref} not found. Valid: {all_intents}")

    if id:
        # UPDATE
        _, cc = plan.get_change(id)
        if not cc:
            all_changes = [c.id for m in plan.milestones for c in m.code_changes]
            raise ValueError(f"Change {id} not found. Valid: {all_changes}")

        _check_version(cc, version, id)

        if intent_ref is not None:
            cc.intent_ref = intent_ref if intent_ref else None
        if file:
            cc.file = file
        if diff:
            cc.diff = diff
        if comments is not None:
            cc.comments = comments

        _bump_version(cc)
        ctx.save_plan(plan)
        return {"id": cc.id, "version": cc.version, "operation": "updated"}
    else:
        # CREATE
        if version is not None:
            raise ValueError("--version only valid for updates")
        if not file or not diff:
            raise ValueError("--file and --diff required for create")

        num = len(ms.code_changes) + 1
        ccid = f"CC-{ms.id}-{num:03d}"

        cc = schema['CodeChange'](
            id=ccid, version=1, intent_ref=intent_ref,
            file=file, diff=diff, comments=comments or "",
        )
        ms.code_changes.append(cc)

        errors = plan.validate_refs()
        if errors:
            raise ValueError("\n".join(errors))

        ctx.save_plan(plan)
        return {"id": ccid, "version": 1, "operation": "created"}


# -----------------------------------------------------------------------------
# TW Phase
# -----------------------------------------------------------------------------

def set_doc(ctx: PlanContext, milestone: str, type: str, content_file: str,
            function: str = None, location: str = None,
            decision_ref: str = None, source: str = None) -> dict:
    """Create documentation entry."""
    schema = _get_schema()
    plan = ctx.load_plan()

    ms = plan.get_milestone(milestone)
    if not ms:
        ids = [m.id for m in plan.milestones]
        raise ValueError(f"Milestone {milestone} not found. Valid: {ids}")

    content_path = Path(content_file)
    if not content_path.exists():
        raise FileNotFoundError(f"Content file not found: {content_file}")

    content = content_path.read_text().strip()

    if type == "module":
        ms.documentation.module_comment = content
    elif type == "docstring":
        if not function:
            raise ValueError("--function required for docstring type")
        ms.documentation.docstrings.append(
            schema['Docstring'](function=function, docstring=content)
        )
    elif type == "function_block":
        if not function:
            raise ValueError("--function required for function_block type")
        if decision_ref and not plan.get_decision(decision_ref):
            dids = [d.id for d in plan.planning_context.decisions]
            raise ValueError(f"Decision {decision_ref} not found. Valid: {dids}")
        ms.documentation.function_blocks.append(
            schema['FunctionBlock'](
                function=function, comment=content,
                decision_ref=decision_ref, source=source,
            )
        )
    elif type == "inline":
        if not location:
            raise ValueError("--location required for inline type")
        if decision_ref and not plan.get_decision(decision_ref):
            dids = [d.id for d in plan.planning_context.decisions]
            raise ValueError(f"Decision {decision_ref} not found. Valid: {dids}")
        ms.documentation.inline_comments.append(
            schema['InlineComment'](location=location, comment=content, decision_ref=decision_ref, source=source)
        )
    else:
        raise ValueError(f"Unknown doc type: {type}")

    ctx.save_plan(plan)
    return {"milestone": milestone, "type": type, "operation": "created"}


def set_readme(ctx: PlanContext, path: str, content_file: str) -> dict:
    """Create or update plan-level README entry."""
    schema = _get_schema()
    plan = ctx.load_plan()

    content_path = Path(content_file)
    if not content_path.exists():
        raise FileNotFoundError(f"Content file not found: {content_file}")

    content = content_path.read_text().strip()

    # Upsert: one README per directory path
    for i, entry in enumerate(plan.readme_entries):
        if entry.path == path:
            plan.readme_entries[i] = schema['ReadmeEntry'](path=path, content=content)
            ctx.save_plan(plan)
            return {"path": path, "operation": "updated"}

    plan.readme_entries.append(
        schema['ReadmeEntry'](path=path, content=content)
    )
    ctx.save_plan(plan)
    return {"path": path, "operation": "created"}


def set_diagram_render(ctx: PlanContext, diagram: str, content_file: str) -> dict:
    """Set ASCII render for diagram."""
    plan = ctx.load_plan()

    dg = next((d for d in plan.diagram_graphs if d.id == diagram), None)
    if not dg:
        raise ValueError(f"Diagram {diagram} not found")

    content_path = Path(content_file)
    if not content_path.exists():
        raise FileNotFoundError(f"Content file not found: {content_file}")

    dg.ascii_render = content_path.read_text()
    ctx.save_plan(plan)

    return {"diagram": diagram, "operation": "updated"}


def set_doc_diff(ctx: PlanContext, change: str, version: int,
                 content_file: str) -> dict:
    """Set documentation diff for an existing code change."""
    plan = ctx.load_plan()

    _, cc = plan.get_change(change)
    if not cc:
        all_changes = [c.id for m in plan.milestones for c in m.code_changes]
        raise ValueError(f"Change {change} not found. Valid: {all_changes}")

    _check_version(cc, version, change)

    content_path = Path(content_file)
    if not content_path.exists():
        raise FileNotFoundError(f"Content file not found: {content_file}")

    cc.doc_diff = content_path.read_text()
    _bump_version(cc)
    ctx.save_plan(plan)

    return {"id": cc.id, "version": cc.version, "operation": "updated"}


def create_doc_change(ctx: PlanContext, milestone: str, file: str,
                      content_file: str) -> dict:
    """Create a documentation-only change."""
    schema = _get_schema()
    plan = ctx.load_plan()

    ms = plan.get_milestone(milestone)
    if not ms:
        ids = [m.id for m in plan.milestones]
        raise ValueError(f"Milestone {milestone} not found. Valid: {ids}")

    content_path = Path(content_file)
    if not content_path.exists():
        raise FileNotFoundError(f"Content file not found: {content_file}")

    num = len(ms.code_changes) + 1
    ccid = f"CC-{ms.id}-{num:03d}"

    cc = schema['CodeChange'](
        id=ccid, version=1, intent_ref=None,
        file=file, diff="", doc_diff=content_path.read_text(), comments="",
    )
    ms.code_changes.append(cc)
    ctx.save_plan(plan)

    return {"id": ccid, "version": 1, "operation": "created"}


def _translate(ctx: PlanContext, output: str) -> dict:
    """Translate plan.json to Markdown. Internal only -- not exposed via CLI."""
    from .plan import translate_to_markdown

    plan = ctx.load_plan()
    md = translate_to_markdown(plan)
    Path(output).write_text(md)

    return {"output": output, "operation": "created"}


# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

def validate(ctx: PlanContext, phase: str) -> dict:
    """Validate plan.json for a specific phase."""
    plan = ctx.load_plan()

    errors = []
    errors.extend(plan.validate_refs())
    errors.extend(plan.validate_completeness(phase))

    if errors:
        raise ValueError("Validation errors:\n" + "\n".join(errors))

    return {"phase": phase, "status": "passed"}


# -----------------------------------------------------------------------------
# List Helpers (read-only)
# -----------------------------------------------------------------------------

def list_milestones(ctx: PlanContext) -> list[dict]:
    """List all milestones."""
    plan = ctx.load_plan()
    return [
        {"id": ms.id, "version": ms.version, "name": ms.name}
        for ms in plan.milestones
    ]


def list_intents(ctx: PlanContext, milestone_id: str) -> list[dict]:
    """List intents in milestone."""
    plan = ctx.load_plan()

    ms = plan.get_milestone(milestone_id)
    if not ms:
        ids = [m.id for m in plan.milestones]
        raise ValueError(f"Milestone {milestone_id} not found. Valid: {ids}")

    return [
        {"id": ci.id, "version": ci.version, "file": ci.file, "behavior": ci.behavior[:50]}
        for ci in ms.code_intents
    ]


def list_changes(ctx: PlanContext, milestone_id: str) -> list[dict]:
    """List changes in milestone."""
    plan = ctx.load_plan()

    ms = plan.get_milestone(milestone_id)
    if not ms:
        ids = [m.id for m in plan.milestones]
        raise ValueError(f"Milestone {milestone_id} not found. Valid: {ids}")

    return [
        {"id": cc.id, "version": cc.version, "intent_ref": cc.intent_ref, "file": cc.file}
        for cc in ms.code_changes
    ]


def list_decisions(ctx: PlanContext) -> list[dict]:
    """List all decisions."""
    plan = ctx.load_plan()
    return [
        {"id": dl.id, "version": dl.version, "decision": dl.decision[:50]}
        for dl in plan.planning_context.decisions
    ]
