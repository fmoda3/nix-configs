"""Shared W.el()-based builders for planner XML output.

All builders return ElementNode instances for composition via W.el().
"""

from skills.lib.workflow.ast import W, XMLRenderer, render
from skills.lib.workflow.ast.nodes import ElementNode, TextNode



def build_forbidden_block(*items: str) -> ElementNode:
    """Build forbidden element with items."""
    children = [TextNode(item) for item in items]
    return W.el("forbidden", *children).node()


def build_xml_format_mandate() -> ElementNode:
    """Build xml_format_mandate element."""
    return W.el(
        "xml_format_mandate",
        TextNode("CRITICAL: All script outputs use XML format. You MUST:"),
        TextNode(""),
        TextNode("1. Execute the action in <current_action>"),
        TextNode("2. When complete, invoke the exact command in <invoke_after>"),
        TextNode("3. The <next> block re-states the command -- execute it"),
        TextNode("4. For branching <invoke_after>, choose based on outcome:"),
        TextNode("   - <if_pass>: Use when action succeeded / QR returned PASS"),
        TextNode("   - <if_fail>: Use when action failed / QR returned ISSUES"),
        TextNode(""),
        TextNode("DO NOT modify commands. DO NOT skip steps. DO NOT interpret."),
    ).node()


def build_output_efficiency() -> ElementNode:
    """Build output_efficiency element."""
    return W.el(
        "output_efficiency",
        TextNode("Keep each thinking step to 5 words max. Use notation:"),
        TextNode("  -> for implies"),
        TextNode("  | for alternatives"),
        TextNode("  ; for sequence"),
        TextNode(""),
        TextNode('Example: "QR failed -> route step 8 | iteration++"'),
    ).node()


def build_task_prompt_guidance() -> ElementNode:
    """Build task prompt construction guidance for orchestrator dispatch.

    CRITICAL: For script-mode dispatches, the orchestrator must NOT inject
    any context. The script provides all instructions. Orchestrator passes
    only the invoke command.
    """
    return W.el(
        "task_prompt_rules",
        TextNode("SCRIPT-MODE DISPATCH RULES:"),
        TextNode(""),
        TextNode("Your Task prompt contains ONLY the exact <invoke> command."),
        TextNode(""),
        TextNode("FORBIDDEN in Task prompt:"),
        TextNode("  - Task descriptions or summaries"),
        TextNode("  - Goals or objectives"),
        TextNode("  - Context from conversation"),
        TextNode("  - Explanations of what the sub-agent should do"),
        TextNode("  - Environment variables or STATE_DIR values"),
        TextNode(""),
        TextNode("The script tells the sub-agent what to do. You just invoke it."),
    ).node()



def build_gate_result_node(passed: bool) -> ElementNode:
    """Build gate result element node.

    WHY: Iteration count hidden from LLM output (ceiling numbers enable rationalization).
    """
    if passed:
        return W.el("gate_result", TextNode("GATE PASSED"), status="pass").node()
    return W.el("gate_result", TextNode("GATE FAILED"), status="fail").node()


def build_pedantic_enforcement() -> ElementNode:
    """Build pedantic_enforcement element.

    WHY: Absolute language ("ALL issues") eliminates classification as ignorable.
    """
    return W.el(
        "pedantic_enforcement",
        TextNode("QR exists to catch problems BEFORE they reach production."),
        TextNode("ALL issues must be fixed before proceeding."),
    ).node()


