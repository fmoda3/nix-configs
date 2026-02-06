"""Workflow orchestration framework for skills.

Public API for workflow types, formatters, registration, and testing.
"""

from .core import Arg, StepDef, Workflow
from .discovery import discover_workflows
from .types import (
    AgentRole,
    BranchRouting,
    Confidence,
    Dispatch,
    LinearRouting,
    Mode,
    Phase,
    PHASE_TO_MODE,
    Routing,
    TerminalRouting,
)

__all__ = [
    # Core types
    "Workflow",
    "StepDef",
    "Arg",
    "discover_workflows",
    # Domain types
    "AgentRole",
    "Confidence",
    "LinearRouting",
    "BranchRouting",
    "TerminalRouting",
    "Routing",
    "Dispatch",
    # Code quality document types
    "Phase",
    "Mode",
    "PHASE_TO_MODE",
]
