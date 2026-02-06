"""QR domain types.

Moved from lib/workflow/types.py to planner/shared/qr/types.py.
"""

from dataclasses import dataclass, field
from enum import Enum

from skills.lib.workflow.types import AgentRole


class QRStatus(Enum):
    """Quality Review result status."""

    PASS = "pass"
    FAIL = "fail"

    def __bool__(self) -> bool:
        """Allow if qr_status: checks (PASS is truthy, FAIL is falsy for gating)."""
        return self == QRStatus.PASS


class QAItemStatus(Enum):
    """QA checklist item status."""

    TODO = "TODO"
    PASS = "PASS"
    FAIL = "FAIL"


@dataclass
class QAItem:
    """Single QA checklist item.

    Tracks verification tasks across decomposition iterations with scope
    (macro vs micro), check description, status, and findings.
    """

    id: str
    scope: str
    check: str
    status: QAItemStatus
    version: int = 1
    finding: str | None = None
    parent_id: str | None = None
    group_id: str | None = None


class LoopState(Enum):
    """Explicit state machine for QR iteration loops.

    QRState tracks loop progression through three phases: INITIAL (first review),
    RETRY (fixing issues from previous iteration), COMPLETE (passed review).

    Enum makes state transitions explicit (qr.transition(status)) and enables
    property-based testing of invariants (INITIAL.iteration == 1, RETRY implies
    previous failure).
    """

    INITIAL = "initial"
    RETRY = "retry"
    COMPLETE = "complete"


@dataclass
class QRState:
    """Quality Review loop state machine.

    Tracks progression through QR gates using explicit state enum. The state
    machine has three phases: INITIAL (first review attempt), RETRY (fixing
    issues from previous iteration), and COMPLETE (passed review).

    Attributes:
        iteration: Current loop count (increments on each retry)
        state: Current phase in the review cycle
        status: QR result (PASS/FAIL) from most recent review
    """

    iteration: int = 1
    state: LoopState = LoopState.INITIAL
    status: QRStatus | None = None

    @property
    def failed(self) -> bool:
        """Check if state indicates retry.

        Backward compatibility property for call sites checking retry state.
        Provides compatibility bridge during migration.
        """
        return self.state == LoopState.RETRY

    @property
    def passed(self) -> bool:
        """Check if QR passed."""
        return self.status == QRStatus.PASS

    def transition(self, status: QRStatus) -> None:
        """Transition state based on QR result.

        State machine transitions:
        - PASS -> COMPLETE (terminal state)
        - FAIL -> RETRY (increments iteration counter)

        Iteration counter tracks retry depth for severity threshold decisions.
        """
        if status == QRStatus.PASS:
            self.state = LoopState.COMPLETE
        else:
            self.state = LoopState.RETRY
            self.iteration += 1


@dataclass
class GateConfig:
    """Configuration for a QR gate step."""

    qr_name: str
    work_step: int
    pass_step: int | None
    pass_message: str
    fix_target: AgentRole | None = None


@dataclass
class Step:
    """Step configuration for workflow.

    DEPRECATED: Use StepDef from lib.workflow.core for new skills.
    """

    title: str
    actions: list[str]
    routing: object = field(default_factory=lambda: None)
    dispatch: object | None = None
    gate: GateConfig | None = None
    phase: str | None = None
