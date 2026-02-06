"""Domain types for workflow orchestration.

Explicit, composable abstractions over stringly-typed dicts and parameter groups.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Callable, Literal, Protocol, TypeAlias


class ResourceProvider(Protocol):
    """Protocol for accessing workflow resources without circular imports.

    QR/TW/Dev modules receive ResourceProvider instead of importing
    skills.planner.shared.resources directly. This breaks 3-layer coupling
    (modules import from both lib/workflow and planner/shared).

    Protocol in types.py enables mock implementations for isolated unit testing
    without circular dependency chains.
    """

    def get_resource(self, name: str) -> str:
        """Retrieve resource content by name.

        Args:
            name: Resource filename (e.g., "plan-format.md")

        Returns:
            Resource file content as string

        Raises:
            FileNotFoundError: Resource not found in conventions directory
        """
        ...

    def get_step_guidance(self, **kwargs) -> dict:
        """Get step-specific guidance for workflow execution.

        Placeholder for future per-step metadata (guidance varies by step).
        Current QR/TW modules read full conventions files, not step-specific
        guidance. Returns empty dict until use case emerges.

        Avoids speculative design while maintaining protocol compatibility.
        """
        ...


class AgentRole(Enum):
    """Agent types for sub-agent dispatch."""

    QUALITY_REVIEWER = "quality-reviewer"
    DEVELOPER = "developer"
    TECHNICAL_WRITER = "technical-writer"
    EXPLORE = "explore"
    GENERAL_PURPOSE = "general-purpose"
    ARCHITECT = "architect"


class Confidence(Enum):
    """Confidence levels for iterative workflows."""

    EXPLORING = "exploring"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CERTAIN = "certain"


# =============================================================================
# Code Quality Document Types
# =============================================================================


class Phase(Enum):
    """Workflow phases that consume code quality documents.

    Each phase evaluates code from a different perspective:
    - DESIGN_REVIEW: Evaluating Code Intent before code exists
    - DIFF_REVIEW: Evaluating proposed code changes
    - CODEBASE_REVIEW: Evaluating implemented code post-implementation
    - REFACTOR_DESIGN: Evaluating architecture/intent quality of existing code
    - REFACTOR_CODE: Evaluating implementation quality of existing code
    """

    DESIGN_REVIEW = "design_review"
    DIFF_REVIEW = "diff_review"
    CODEBASE_REVIEW = "codebase_review"
    REFACTOR_DESIGN = "refactor_design"
    REFACTOR_CODE = "refactor_code"


class Mode(Enum):
    """Evaluation mode for code quality checks.

    - DESIGN: Evaluate architecture, boundaries, responsibilities, intent
    - CODE: Evaluate implementation, patterns, idioms, structure
    """

    DESIGN = "design"
    CODE = "code"


PHASE_TO_MODE: dict[Phase, Mode] = {
    Phase.DESIGN_REVIEW: Mode.DESIGN,
    Phase.DIFF_REVIEW: Mode.CODE,
    Phase.CODEBASE_REVIEW: Mode.CODE,
    Phase.REFACTOR_DESIGN: Mode.DESIGN,
    Phase.REFACTOR_CODE: Mode.CODE,
}
"""Derive evaluation mode from workflow phase.

Design Review and Refactor Design use design mode (architecture/intent focus).
All other phases use code mode (implementation focus).
"""


@dataclass
class LinearRouting:
    """Linear routing - proceed to step+1."""
    pass


@dataclass
class BranchRouting:
    """Conditional routing based on QR result."""

    if_pass: int
    if_fail: int


@dataclass
class TerminalRouting:
    """Terminal routing - no continuation."""
    pass


Routing = LinearRouting | BranchRouting | TerminalRouting


# =============================================================================
# Command Routing (for invoke_after)
# =============================================================================


@dataclass
class FlatCommand:
    """Single command routing (non-branching steps)."""

    command: str


@dataclass
class BranchCommand:
    """Conditional routing based on QR result (branching steps)."""

    if_pass: str
    if_fail: str


NextCommand = FlatCommand | BranchCommand | None
"""Union type for step routing.

- FlatCommand: Non-branching step, single next command
- BranchCommand: QR step, branches on pass/fail
- None: Terminal step, no invoke_after
"""


@dataclass
class Dispatch:
    """Sub-agent dispatch configuration."""

    agent: AgentRole
    script: str
    context_vars: dict[str, str] = field(default_factory=dict)
    free_form: bool = False


# =============================================================================
# Step Handler Pattern
# =============================================================================


@dataclass
class StepGuidance:
    """Return type for step handlers.

    Replaces dict returns with explicit structure.
    """

    title: str
    actions: list[str]
    next_hint: str = ""
    # Additional fields can be added without breaking existing handlers


# Type alias for step handler functions
# Handlers receive step context and return guidance
StepHandler: TypeAlias = Callable[..., dict | StepGuidance]
"""Step handler function signature.

Args:
    step: Current step number
    module_path: Module path for invocation
    **kwargs: Additional context (qr_iteration, qr_fail, etc.)

Returns:
    Dict or StepGuidance with title, actions, next hint
"""


# =============================================================================
# Domain Types for Test Generation
# =============================================================================


# Domain types implement __iter__ for use with itertools.product to generate
# Cartesian products. frozen=True enables hashability for pytest param caching.
@dataclass(frozen=True)
class BoundedInt:
    """Integer domain with inclusive bounds [lo, hi]."""

    lo: int
    hi: int

    def __post_init__(self):
        # Enforce lo <= hi: prevents empty ranges that would silently skip test cases
        if self.lo > self.hi:
            raise ValueError(f"BoundedInt: lo ({self.lo}) must be <= hi ({self.hi})")

    def __iter__(self):
        """Yield all integers in [lo, hi] inclusive."""
        return iter(range(self.lo, self.hi + 1))


# =============================================================================
# Question Relay Types
# =============================================================================


@dataclass(frozen=True)
class QuestionOption:
    """Single option for a user input question."""
    label: str
    description: str


@dataclass(frozen=True)
class UserInputResponse:
    """User's answer passed back to resumed sub-agent."""
    question_id: str
    selected: str


