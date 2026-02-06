"""Data-driven workflow architecture.

Simplified Workflow/StepDef architecture for workflow introspection and
validation. The execution engine (Workflow.run()) was removed because skills
use CLI-based step invocation via format_output() functions.

What remains:
- StepDef: Step metadata (id, title, actions)
- Workflow: Collection of steps with validation
- Arg: Parameter metadata for CLI arguments
"""

from __future__ import annotations

import inspect
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class Arg:
    """Parameter metadata for workflow CLI arguments."""

    description: str = ""
    default: Any = inspect.Parameter.empty
    min: int | float | None = None
    max: int | float | None = None
    choices: tuple[str, ...] | None = None
    required: bool = False


@dataclass(frozen=True)
class StepDef:
    """Step definition for workflow introspection."""

    id: str
    title: str
    actions: list[str]


class Workflow:
    """Workflow definition for introspection and validation."""

    _module_path: str | None = None

    def __init__(
        self,
        name: str,
        *steps: StepDef,
        entry_point: str | None = None,
        description: str = "",
        validate: bool = True,
    ):
        ids = [s.id for s in steps]
        if dupes := [x for x in ids if ids.count(x) > 1]:
            raise ValueError(f"Duplicate step IDs: {set(dupes)}")

        self.name = name
        self.description = description
        self.steps = {s.id: s for s in steps}
        self._step_order = [s.id for s in steps]
        self.entry_point = entry_point or steps[0].id

        if validate:
            self._validate()

    def _validate(self):
        """Validate workflow structure."""
        if self.entry_point not in self.steps:
            raise ValueError(f"entry_point '{self.entry_point}' not in steps")

    @property
    def total_steps(self) -> int:
        return len(self.steps)
