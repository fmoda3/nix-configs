"""Shared output formatting for state mutation CLIs.

Both plan.py and qr.py need consistent structured output after mutations.
This module provides the canonical entity result format specified in INTENT.md.
"""

from __future__ import annotations

from dataclasses import dataclass
import sys


@dataclass
class EntityResult:
    """Result of entity operation for structured output."""
    id: str
    version: int
    operation: str  # "created" | "updated"


def print_entity_result(r: EntityResult) -> None:
    """Print structured success output with ID and version.

    Format matches INTENT.md specification for CLI success output.
    """
    print(f"""<entity_result>
  <id>{r.id}</id>
  <version>{r.version}</version>
  <operation>{r.operation}</operation>
</entity_result>""")


class VersionMismatchError(Exception):
    """Raised when CAS version check fails.

    Used by plan.py for optimistic locking. qr.py doesn't need CAS
    because file locking handles concurrency and status transitions
    are constrained.
    """
    def __init__(self, entity_id: str, expected: int, actual: int, current_json: str):
        self.entity_id = entity_id
        self.expected = expected
        self.actual = actual
        self.current_json = current_json


def exit_with_version_error(err: VersionMismatchError) -> None:
    """Print version mismatch and exit process.

    Provides agent with latest state so it can integrate changes and retry.
    Name indicates process termination (vs pure print_* functions).
    """
    print(f"""<version_mismatch_error>
  <entity_id>{err.entity_id}</entity_id>
  <provided_version>{err.expected}</provided_version>
  <current_version>{err.actual}</current_version>
  <current_entity>
{err.current_json}
  </current_entity>
  <action>Integrate your changes into the current entity above and retry with --version {err.actual}</action>
</version_mismatch_error>""")
    sys.exit(1)
