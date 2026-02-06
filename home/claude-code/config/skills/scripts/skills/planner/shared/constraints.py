"""Reusable constraint element builders for planner orchestration.

Design rationale:
- Functions return ElementNode, not rendered strings
- This enables AST composition before final rendering
- Deferred rendering allows future AST transformations
- Consolidates 9 duplicated constraint blocks into 2 function calls

Why constraints.py instead of extending builders.py:
builders.py contains generic element builders (forbidden blocks, severity filters).
constraints.py contains orchestrator-specific prompt construction. Separation
prevents builders.py from accumulating orchestration-specific knowledge.
"""

from skills.lib.workflow.ast.nodes import ElementNode, TextNode, StepHeaderNode
from skills.lib.workflow.ast import W
from skills.planner.shared.qr.constants import QR_ITERATION_LIMIT


def build_orchestrator_constraint(extended: bool = False) -> ElementNode:
    """Build orchestrator constraint element.

    Two variants exist in the codebase:
    - Compact (3 lines): Used in executor.py fix/gate steps
    - Extended (8 lines): Used in planner.py dispatch steps

    The 'extended' parameter controls which variant is returned.

    Why two variants:
    - Executor fix/gate steps need only core delegation rules because
      the LLM is routing a single PASS/FAIL decision with predefined paths.
    - Planner dispatch steps need thinking guidance because the LLM must
      analyze complex task context and construct detailed sub-agent prompts.

    Args:
        extended: True for dispatch steps (planner.py), False for
                 fix/gate steps (executor.py). Default False because
                 executor.py has 7 usages vs planner.py's 2.

    Returns:
        ElementNode ready for AST composition. Caller renders at boundary.
    """
    children = [
        TextNode("You are the ORCHESTRATOR. You delegate, you never implement."),
        TextNode("Your agents are highly capable. Trust them with ANY issue."),
        TextNode("PROHIBITED: Edit, Write tools. REQUIRED: Task tool dispatch."),
    ]

    if extended:
        # Extended variant adds cognitive load management for complex dispatch.
        # Without this guidance, the orchestrator tends to over-analyze before
        # dispatching, wasting context on internal reasoning.
        children.extend([
            TextNode(""),
            TextNode("THINKING EFFICIENCY: Before dispatch, max 5 words internal reasoning."),
            TextNode('Example thinking: "step 7 -> developer dispatch -> invoke"'),
            TextNode(""),
            TextNode("SCRIPT-MODE DISPATCH: Pass ONLY the <invoke> command and <context> var values."),
            TextNode("DO NOT add task descriptions, goals, or any other text."),
            TextNode("The script provides all instructions to the sub-agent."),
        ])

    return W.el("orchestrator_constraint", *children).node()


def build_step_header(title: str, script: str, step: int) -> StepHeaderNode:
    """Build step header element.

    Step headers provide context for the LLM about where it is in the workflow.
    The attributes (script, step) are metadata for logging/debugging
    but are primarily visual markers.

    Why title is text content, not attribute:
    Title is the primary information the LLM consumes - it appears as the
    element's visible text. Attributes are for machine processing and don't
    render as prominently in the LLM's view of the XML.

    Args:
        title: Human-readable step title (e.g., "Implementation")
        script: Script name for attribution ("planner" or "executor")
        step: Current step number (1-indexed)

    Returns:
        StepHeaderNode with title and metadata.
    """
    return StepHeaderNode(title=title, script=script, step=step)


def build_state_banner(checkpoint: str, iteration: int, mode: str) -> ElementNode:
    """Build state banner element for QR fix loops.

    State banners appear at the top of fix mode outputs to give the LLM
    immediate context about the current state. The iteration count helps
    track progress toward QR_ITERATION_LIMIT.

    Mode values have distinct semantics:
    - "fix": LLM has context from previous QR failure, targets specific issues
    - "fresh_review": No prior context, LLM performs initial comprehensive review
    This distinction prevents fix-mode tunnel vision on early iterations.

    Args:
        checkpoint: Banner label (e.g., "IMPLEMENTATION FIX", "CODE QR")
        iteration: Current QR iteration (1-indexed)
        mode: "fix" when addressing failures, "fresh_review" for new review

    Returns:
        ElementNode with state metadata as attributes.
    """
    return W.el(
        "state_banner",
        checkpoint=checkpoint,
        iteration=str(iteration),
        mode=mode
    ).node()
