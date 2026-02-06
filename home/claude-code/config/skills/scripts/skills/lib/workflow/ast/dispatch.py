"""Dispatch node types for subagent orchestration.

Three dispatch patterns formalized as AST nodes:

SubagentDispatchNode: Single agent dispatch
    Sequential workflows (planner -> developer -> QR -> TW).
    Most workflows use this pattern.

    Example:
        node = SubagentDispatchNode(
            agent_type="general-purpose",
            command='python3 -m skills.dev --step 1',
        )

TemplateDispatchNode: Parallel dispatch with parameterized template
    Same prompt structure applied to N targets (SIMD pattern).
    Template and command use $var syntax via string.Template.
    Example: refactor (N categories)

    Example:
        node = TemplateDispatchNode(
            agent_type="general-purpose",
            template="Explore $category_name in $mode mode...",
            targets=(
                {"category_name": "Naming", "mode": "design"},
                {"category_name": "Structure", "mode": "code"},
            ),
            command='python3 -m skills.explore --category $category_name --mode $mode',
            model="haiku",
        )
        # Renderer expands to 2 agents with $var substituted per-target

RosterDispatchNode: Parallel dispatch with unique prompts
    Each agent has a fundamentally different task (MIMD pattern).
    Shared context + unique prompts, fixed command.
    Examples: deepthink (dynamically designed tasks), codebase-analysis

    Example:
        node = RosterDispatchNode(
            agent_type="general-purpose",
            shared_context="Question: How should we design X?\\nDomain: ...",
            agents=(
                "Analyze from skeptic perspective: assume obvious answer is wrong",
                "Analyze from optimist perspective: assume success is achievable",
                "Analyze from pragmatist perspective: focus on implementation",
            ),
            command='python3 -m skills.subagent --step 1',
            model="sonnet",
        )
        # Each agent receives shared_context + unique prompt

Design rationale:
    Why 3 node types instead of 1 with discriminator field?
    Separate types make illegal states unrepresentable at construction time.
    No Optional fields with mutual exclusivity validation needed.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class SubagentDispatchNode:
    """Single subagent dispatch.

    Use for sequential single-agent workflows (planner -> developer -> QR).
    The orchestrator controls sequencing; each dispatch launches one agent.
    """
    agent_type: str              # "general-purpose", "Explore", etc.
    command: str                 # invoke command for step 1
    prompt: str = ""             # optional context; empty = no <prompt> element
    model: str | None = None     # "haiku", "sonnet", "opus"


@dataclass(frozen=True)
class TemplateDispatchNode:
    """Parallel dispatch: parameterized template applied to targets.

    Use when all agents run the same prompt structure with different parameters.
    Analogous to SIMD: Single Instruction (template), Multiple Data (targets).

    Template and command use $var syntax, substituted per-target
    using string.Template.substitute(). The renderer expands N prompts,
    so the LLM sees final prompts rather than substitution instructions.
    """
    agent_type: str
    template: str                      # prompt with $var placeholders
    targets: tuple[dict[str, str], ...]  # variable bindings per target (tuple for frozen)
    command: str                       # command with $var placeholders
    model: str | None = None
    instruction: str | None = None     # optional instruction text


@dataclass(frozen=True)
class RosterDispatchNode:
    """Parallel dispatch: shared context + unique prompts.

    Use when each agent has a fundamentally different task that cannot be
    parameterized from a common template. Analogous to MIMD: Multiple
    Instructions (unique prompts), Multiple Data (shared context applied differently).

    Each agent receives shared_context + their unique prompt string.
    Command is fixed because prompt differentiation is sufficient.
    """
    agent_type: str
    shared_context: str
    agents: tuple[str, ...]            # unique prompt per agent (tuple for frozen)
    command: str                       # fixed: same for all agents
    model: str | None = None
    instruction: str | None = None     # optional instruction text


__all__ = [
    "SubagentDispatchNode",
    "TemplateDispatchNode",
    "RosterDispatchNode",
]
