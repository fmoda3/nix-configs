"""Shared utilities for QR decomposition scripts.

Mechanical utilities and truly-generic prompts (identical across all 5 phases).
Phase-SPECIFIC cognitive prompts (steps 1-3, 5) belong in per-phase scripts.

WHY "truly-generic": GAP_ANALYSIS_PROMPT, ATOMICITY_RULES, COVERAGE_VALIDATION_PROMPT
apply identical logic regardless of phase. Phase-specific prompts (what to absorb,
what concerns to brainstorm, what severity categories) differ fundamentally per phase.

WHY functions not class: Composition without coupling. Each phase script imports
only required utilities. No forced inheritance hierarchy.

CRITICAL INVARIANT - Phase-Severity Alignment:
Each phase uses severity categories matching agent capabilities:
  - plan-docs: KNOWLEDGE categories only (TW cannot fix code issues)
  - plan-code: STRUCTURE + COSMETIC (Dev can fix code)
  - plan-design: DIAGRAM + subset of KNOWLEDGE
Violating this causes unrecoverable QR loops.

ORCHESTRATOR CONTRACT:
All decompose scripts MUST implement get_step_guidance(step, module_path, **kwargs)
returning {title: str, actions: list[str], next: str}.
Called via: python3 -m {module_path} --step N --state-dir {dir}
"""

import json
from pathlib import Path

from skills.planner.shared.qr.utils import load_qr_state
from skills.planner.shared.resources import get_context_path, render_context_file
from skills.lib.workflow.ast import W, render, XMLRenderer, TextNode


# =============================================================================
# UTILITIES (mechanical operations)
# =============================================================================

def render_item_list(items: list[dict], label: str = "ungrouped_items") -> str:
    """Render item list as XML for LLM parsing.

    WHY XML: LLMs parse structured XML more reliably than free-form text.
    Each item becomes an <item> element with id/scope attributes.
    """
    if not items:
        return f"<{label} count=\"0\" />"

    item_nodes = [
        W.el("item", TextNode(i.get('check', '')[:80]),
             id=i['id'], scope=i.get('scope', '*')).node()
        for i in items
    ]
    list_node = W.el(label, *item_nodes, count=str(len(items))).build()
    return render(list_node, XMLRenderer())


def load_ungrouped_todo_items(state_dir: str, phase: str) -> list[dict]:
    """Load items with status='TODO' and no group_id assigned.

    WHY filter: Grouping operates only on unassigned TODO items.
    Completed or already-grouped items retain their state.
    """
    qr_state = load_qr_state(state_dir, phase)
    if not qr_state:
        return []
    return [i for i in qr_state.get("items", [])
            if i.get("group_id") is None and i.get("status") == "TODO"]


def format_assign_cmd(state_dir: str, phase: str, prefix: str) -> str:
    """Format CLI command template for group assignment.

    WHY CLI: Group assignments use the qr CLI tool for state mutation.
    """
    return f"""OUTPUT:
  python3 -m skills.planner.cli.qr --state-dir {state_dir} --qr-phase {phase} \\
    assign-group <item_id> --group-id {prefix}<name>"""


def write_qr_state(state_dir: str, phase: str, items: list[dict]) -> None:
    """Write qr-{phase}.json with iteration=1.

    WHY iteration=1: Decompose runs once per phase (enforced by orchestrator skip logic).
    Iteration counter tracks verification cycles, not decompose invocations.
    """
    qr_state = {"phase": phase, "iteration": 1, "items": items}
    Path(state_dir, f"qr-{phase}.json").write_text(json.dumps(qr_state, indent=2))


# =============================================================================
# SHARED PROMPTS (truly identical across all 5 phases)
# =============================================================================

GAP_ANALYSIS_PROMPT = """\
COMPARE Step 2 (holistic concerns) vs Step 3 (structural elements):

For each CONCERN from Step 2:
  - Is it addressed by verifying specific elements from Step 3?
  - Or is it cross-cutting (spans multiple elements)?
  - Or is it about something MISSING from the plan?

For each ELEMENT from Step 3:
  - Is there a concern from Step 2 that covers it?
  - If not, what verification does this element need?

OUTPUT:
  - Concerns needing UMBRELLA items (cross-cutting)
  - Concerns mapping to SPECIFIC elements
  - Elements needing their own verification items
  - GAPS: things neither approach caught"""


ATOMICITY_RULES = """\
REVIEW each item for atomicity.

An item is ATOMIC if:
  - It tests exactly ONE thing
  - Pass/fail is unambiguous
  - It cannot be 'half passed'

NON-ATOMIC signals:
  - Contains 'and' joining distinct concerns
  - Contains 'all/each/every' over unbounded collection
  - Failure could mean multiple different problems

DECISION RULE (based on severity):
  - If non-atomic AND severity=MUST: SPLIT into specifics, KEEP umbrella
  - If non-atomic AND severity=SHOULD/COULD: KEEP as umbrella (broader coverage)

WHY severity determines splitting:
  MUST items block all iterations -- specific diagnostics justify the cost
  SHOULD/COULD items have lower stakes -- umbrella catches suffice

WHEN SPLITTING:
  - Original item becomes PARENT (keep id, e.g., qa-002)
  - New items become CHILDREN (suffixed, e.g., qa-002a, qa-002b)
  - Each child MUST have parent_id field set to parent's id
  - Children inherit parent's severity

OUTPUT: Revised item list with atomicity notes."""


COVERAGE_VALIDATION_PROMPT = """\
FINAL CHECK using Step 3 enumeration as checklist:

For EACH element enumerated in Step 3:
  [ ] At least one item would catch issues with this element

For EACH concern from Step 2:
  [ ] At least one item addresses this concern

If any unchecked: ADD items.

PREFERENCE: If uncertain whether coverage is adequate, ADD an item.
Overlapping coverage is acceptable. Gaps are not.

OUTPUT: Final item list ready for finalization."""


FINALIZE_PROMPT = """\
WRITE qr-{phase}.json to STATE_DIR:

{{
  "phase": "{phase}",
  "iteration": 1,
  "items": [/* your items from Step 7 */]
}}

Item count: whatever the content requires. No fixed caps.

After writing, proceed to grouping phase."""


# =============================================================================
# STEP DISPATCH HELPER (eliminates duplicate control flow)
# =============================================================================

def dispatch_step(
    step: int,
    phase: str,
    module_path: str,
    phase_prompts: dict[int, str],
    grouping_config: dict,
    state_dir: str = "",
) -> dict:
    """Route step to appropriate handler.

    WHY this function: Eliminates duplicate if-elif control flow across 5 phase scripts.
    Each script provides phase-specific content (phase_prompts, grouping_config),
    this function handles the common routing logic.

    Args:
        step: Current step number (1-13)
        phase: Phase name (plan-docs, plan-code, etc.)
        module_path: Module path for next step command
        phase_prompts: Dict mapping step numbers to phase-specific prompt strings
                      Required keys: 1, 2, 3, 5
        grouping_config: Dict with component_examples and concern_examples strings
        state_dir: State directory path

    Returns:
        Dict with title, actions, next keys
    """
    state_dir_arg = f" --state-dir {state_dir}" if state_dir else ""
    next_cmd = lambda s: f"python3 -m {module_path} --step {s}{state_dir_arg}"

    # Step 1: Absorb context (phase-specific)
    if step == 1:
        context_display = render_context_file(get_context_path(state_dir)) if state_dir else ""
        return {
            "title": f"QR Decomposition Step 1: Absorb Context ({phase})",
            "actions": [
                f"PHASE: {phase}",
                "",
                phase_prompts[1],
                "",
                "PLANNING CONTEXT:",
                context_display,
                "",
                "TASK: Read and understand. Summarize in 2-3 sentences:",
                "  - What is this plan trying to accomplish?",
                "  - What does success look like for this phase?",
                "",
                "DO NOT generate items yet. Understanding first.",
            ],
            "next": next_cmd(2),
        }

    # Step 2: Holistic concerns (phase-specific)
    elif step == 2:
        return {
            "title": f"QR Decomposition Step 2: Holistic Concerns ({phase})",
            "actions": [
                "THINKING TOP-DOWN: If reviewing this phase output, what would you check?",
                "",
                phase_prompts[2],
                "",
                "OUTPUT: Bulleted list of concerns.",
                "  - Quantity over quality at this step",
                "  - No filtering yet - capture everything",
                "",
                "These concerns will drive umbrella items in Step 5.",
            ],
            "next": next_cmd(3),
        }

    # Step 3: Structural enumeration (phase-specific)
    elif step == 3:
        return {
            "title": f"QR Decomposition Step 3: Structural Enumeration ({phase})",
            "actions": [
                "THINKING BOTTOM-UP: What EXISTS in the plan for this phase?",
                "",
                phase_prompts[3],
                "",
                "OUTPUT: Structured list of plan elements.",
                "  - Use IDs where available (DL-001, M-001, CC-001)",
                "  - Note counts (e.g., '3 decisions, 5 milestones')",
                "",
                "This enumeration becomes a completeness checklist in Step 7.",
            ],
            "next": next_cmd(4),
        }

    # Step 4: Gap analysis (shared)
    elif step == 4:
        return {
            "title": f"QR Decomposition Step 4: Gap Analysis ({phase})",
            "actions": [GAP_ANALYSIS_PROMPT],
            "next": next_cmd(5),
        }

    # Step 5: Generate items (phase-specific severity)
    elif step == 5:
        return {
            "title": f"QR Decomposition Step 5: Generate Items ({phase})",
            "actions": [
                "CREATE verification items using the UMBRELLA + SPECIFIC pattern:",
                "",
                "WHY THIS PATTERN: Overlapping coverage catches outliers that specific",
                "items miss. This intentional redundancy is a feature, not waste.",
                "",
                "UMBRELLA ITEMS (scope: '*'):",
                "  - One per cross-cutting concern from Step 4",
                "  - Broad enough to catch outliers",
                "",
                "SPECIFIC ITEMS (scope: element reference):",
                "  - One per element needing verification",
                "  - Targeted at specific element",
                "",
                "CRITICAL CONCERNS get BOTH umbrella AND specific items.",
                "",
                "FORMAT each item:",
                '  {"id": "qa-NNN", "scope": "...", "check": "...", "status": "TODO", "severity": "..."}',
                "",
                phase_prompts[5],  # Phase-specific severity guidance
                "",
                "NO FIXED COUNT - generate what the content requires.",
            ],
            "next": next_cmd(6),
        }

    # Step 6: Atomicity check (shared)
    elif step == 6:
        return {
            "title": f"QR Decomposition Step 6: Atomicity Check ({phase})",
            "actions": [ATOMICITY_RULES],
            "next": next_cmd(7),
        }

    # Step 7: Coverage validation (shared)
    elif step == 7:
        return {
            "title": f"QR Decomposition Step 7: Coverage Validation ({phase})",
            "actions": [COVERAGE_VALIDATION_PROMPT],
            "next": next_cmd(8),
        }

    # Step 8: Finalize (shared with phase substitution)
    elif step == 8:
        return {
            "title": f"QR Decomposition Step 8: Finalize ({phase})",
            "actions": [FINALIZE_PROMPT.format(phase=phase)],
            "next": next_cmd(9),
        }

    # Steps 9-13: Grouping (delegated to grouping functions)
    elif step == 9:
        return step_9_structural_grouping(state_dir, phase, module_path)
    elif step == 10:
        return step_10_component_grouping(
            state_dir, phase, module_path,
            grouping_config["component_examples"]
        )
    elif step == 11:
        return step_11_concern_grouping(
            state_dir, phase, module_path,
            grouping_config["concern_examples"]
        )
    elif step == 12:
        return step_12_affinity_grouping(state_dir, phase, module_path)
    elif step == 13:
        return step_13_final_validation(state_dir, phase, module_path)

    return {"error": f"Unknown step {step}"}


# =============================================================================
# GROUPING STEP BUILDERS (steps 9-13)
# =============================================================================

def step_9_structural_grouping(state_dir: str, phase: str, module_path: str) -> dict:
    """Step 9: Automatic structural grouping (deterministic rules).

    Applies deterministic rules without LLM judgment:
    1. Parent-child: Items with parent_id inherit parent's group
    2. Umbrella batching: scope='*' items get group_id='umbrella'

    WHY deterministic: These groupings follow mechanical rules, no interpretation needed.
    """
    qr_state = load_qr_state(state_dir, phase)
    items = qr_state.get("items", []) if qr_state else []

    todo_items = [i for i in items if i.get("status") == "TODO"]
    item_ids = {i["id"] for i in items}

    # Identify parent-child relationships
    children = [i for i in todo_items if i.get("parent_id")]
    orphans = [i for i in children if i.get("parent_id") not in item_ids]
    valid_children = [i for i in children if i.get("parent_id") in item_ids]
    parents = {i["id"]: i for i in todo_items
               if any(c.get("parent_id") == i["id"] for c in valid_children)}
    umbrellas = [i for i in todo_items
                 if i.get("scope") == "*" and not i.get("parent_id") and not i.get("group_id")]

    # Orphans block workflow - data corruption must not propagate
    if orphans:
        return {
            "title": f"QR Decomposition Step 9: Structural Grouping ({phase})",
            "actions": [
                "BLOCKING ERROR: Orphan items detected",
                "",
                f"Found {len(orphans)} orphan items (parent_id references missing parent):",
                f"  {[i['id'] for i in orphans]}",
                "",
                "These items have parent_id but parent does not exist.",
                "Return to Step 6 and fix atomicity splits to ensure parent items exist.",
                "",
                "WORKFLOW HALTED - fix parent_id references before continuing.",
            ],
            "next": "",  # Terminal error
        }

    return {
        "title": f"QR Decomposition Step 9: Structural Grouping ({phase})",
        "actions": [
            "AUTOMATIC GROUPING (deterministic rules, TODO items only):",
            "",
            f"Found {len(parents)} parent items with children",
            f"Found {len(valid_children)} child items with valid parent_id",
            f"Found {len(umbrellas)} umbrella items (scope='*')",
            "",
            "1. PARENT-CHILD RESOLUTION:",
            "   For each item with valid parent_id:",
            "   - Set parent.group_id = parent-{parent.id} (anchor the group)",
            "   - Set child.group_id = parent-{parent.id} (join parent's group)",
            "",
            "2. UMBRELLA BATCHING:",
            "   For items with scope='*' and no parent_id:",
            "   - Set group_id = 'umbrella'",
            "",
            f"Execute via CLI:",
            f"  python3 -m skills.planner.cli.qr --state-dir {state_dir} --qr-phase {phase} \\",
            "    assign-group <item_id> --group-id <group_id>",
        ],
        "next": f"python3 -m {module_path} --step 10 --state-dir {state_dir}",
    }


def step_10_component_grouping(
    state_dir: str, phase: str, module_path: str, component_examples: str
) -> dict:
    """Step 10: Component-based grouping.

    Groups items verifying different aspects of the same structural element.

    WHY component_examples parameter: Examples are DISPLAY HINTS for the LLM,
    not algorithm inputs. They help the LLM understand what constitutes a
    "component" for this specific phase without affecting grouping behavior.
    """
    ungrouped = load_ungrouped_todo_items(state_dir, phase)
    item_list_xml = render_item_list(ungrouped, "ungrouped_items")

    return {
        "title": f"QR Decomposition Step 10: Component Grouping ({phase})",
        "actions": [
            "GROUP BY STRUCTURAL COMPONENTS",
            "",
            "A 'component' is a discrete structural element:",
            component_examples,
            "",
            item_list_xml,
            "",
            "TASK:",
            "1. Identify components that multiple items verify aspects of",
            "2. Create group_id with 'component-' prefix (e.g., 'component-milestone-m001')",
            "3. Only group if items GENUINELY share structural element",
            "4. Items not clearly belonging: SKIP for later phases",
            "",
            "PRIORITY: If item could be component OR concern, prefer component.",
            "",
            "SELF-VERIFICATION:",
            "  - Would verifying together provide shared context benefit?",
            "  - Are these truly about the SAME structural element?",
            "  - If uncertain, do NOT group.",
            "",
            format_assign_cmd(state_dir, phase, "component-"),
            "",
            f"If no component groups: # No component groups. {len(ungrouped)} items to Phase 2.",
        ],
        "next": f"python3 -m {module_path} --step 11 --state-dir {state_dir}",
    }


def step_11_concern_grouping(
    state_dir: str, phase: str, module_path: str, concern_examples: str
) -> dict:
    """Step 11: Concern-based grouping.

    Groups items verifying the same quality dimension across different elements.

    WHY concern_examples parameter: Examples are DISPLAY HINTS for the LLM,
    not algorithm inputs. They help the LLM understand what constitutes a
    "concern" for this specific phase without affecting grouping behavior.
    """
    ungrouped = load_ungrouped_todo_items(state_dir, phase)
    item_list_xml = render_item_list(ungrouped, "ungrouped_items")

    return {
        "title": f"QR Decomposition Step 11: Concern Grouping ({phase})",
        "actions": [
            "GROUP BY QUALITY CONCERNS",
            "",
            "A 'concern' is a cross-cutting quality dimension:",
            concern_examples,
            "",
            item_list_xml,
            "",
            "TASK:",
            "1. Identify concerns that span multiple elements",
            "2. Create group_id with 'concern-' prefix (e.g., 'concern-error-handling')",
            "3. Only group if items verify SAME quality dimension",
            "4. Items not clearly sharing concern: SKIP for affinity phase",
            "",
            "SELF-VERIFICATION:",
            "  - Do these check the same KIND of quality?",
            "  - Would a single agent have useful context overlap?",
            "",
            format_assign_cmd(state_dir, phase, "concern-"),
        ],
        "next": f"python3 -m {module_path} --step 12 --state-dir {state_dir}",
    }


def step_12_affinity_grouping(state_dir: str, phase: str, module_path: str) -> dict:
    """Step 12: Affinity grouping for remaining items.

    Groups items by semantic similarity when they don't fit component/concern patterns.
    """
    ungrouped = load_ungrouped_todo_items(state_dir, phase)
    item_list_xml = render_item_list(ungrouped, "ungrouped_items")

    return {
        "title": f"QR Decomposition Step 12: Affinity Grouping ({phase})",
        "actions": [
            "GROUP BY SEMANTIC AFFINITY",
            "",
            "For items that don't fit component/concern patterns:",
            "  - Similar verification complexity",
            "  - Related subject matter",
            "  - Shared verification context",
            "",
            item_list_xml,
            "",
            "TASK:",
            "1. Identify natural clusters by semantic similarity",
            "2. Create group_id with 'affinity-' prefix (e.g., 'affinity-validation-checks')",
            "3. Avoid large catch-all groups",
            "4. Singletons are acceptable for truly independent items",
            "",
            format_assign_cmd(state_dir, phase, "affinity-"),
            "",
            "Remaining ungrouped items become singletons.",
        ],
        "next": f"python3 -m {module_path} --step 13 --state-dir {state_dir}",
    }


def step_13_final_validation(state_dir: str, phase: str, module_path: str) -> dict:
    """Step 13: Final validation of groupings.

    Validates grouping quality and outputs summary for parent agent visibility.
    """
    qr_state = load_qr_state(state_dir, phase)
    items = qr_state.get("items", []) if qr_state else []

    groups = {}
    singletons = []
    for item in items:
        gid = item.get("group_id")
        if gid:
            groups.setdefault(gid, []).append(item["id"])
        else:
            singletons.append(item["id"])

    group_summary = "\n".join([
        f"  {gid}: {len(ids)} items"
        for gid, ids in sorted(groups.items())
    ]) if groups else "  (no groups)"

    return {
        "title": f"QR Decomposition Step 13: Final Validation ({phase})",
        "actions": [
            "FINAL GROUPING VALIDATION",
            "",
            f"SUMMARY: {len(groups)} groups, {len(singletons)} singletons",
            "",
            "Groups:",
            group_summary,
            "",
            f"Singletons: {len(singletons)} items",
            "",
            "VALIDATION:",
            "[ ] All group_ids follow namespace convention:",
            "    - 'umbrella' for scope='*' items",
            "    - 'parent-{id}' for parent-child groups",
            "    - 'component-*' for Step 10 groups",
            "    - 'concern-*' for Step 11 groups",
            "    - 'affinity-*' for Step 12 groups",
            "[ ] Large groups (>10 items) reviewed for forced grouping",
            "[ ] Singletons are genuinely independent",
            "[ ] Parent-child items share same parent-{id} group",
            "[ ] No orphan items (parent_id referencing missing parent)",
            "",
            "AFTER VALIDATION, output: PASS",
        ],
        "next": "",  # Terminal step
    }
