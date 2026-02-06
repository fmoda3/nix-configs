"""Shared utilities for planner scripts.

Workflow types and formatters live in skills.lib.workflow.
This module contains planner-specific resource utilities.

QR Gate Pattern for Verification Loops:
  Every QR step is followed by a GATE step that:
  1. Takes --qr-status=pass|fail as input
  2. Outputs the EXACT next command to invoke
  3. Leaves no room for interpretation

  Work steps detect fix mode via qr-{phase}.json file state inspection.

This pattern is applied consistently across:
  - planner.py (steps 5-12: sequential QR with gates)
  - executor.py (step 4-5: holistic QR with gate)
  - wave-executor.py (steps 2-3: batch QR with gate)
"""

# Re-export from resources
from .resources import (
    get_resource,
    get_mode_script_path,
    get_exhaustiveness_prompt,
)

# Re-export from domain (planner-specific guidance types)
from .domain import (
    GuidanceResult,
    FlatCommand,
    BranchCommand,
    NextCommand,
)

# Re-export from routing
from .routing import (
    WORK_PHASES,
    detect_qr_state,
    route_work_phase,
    get_work_phase_config,
    get_all_work_phases,
)

__all__ = [
    # Resources
    "get_resource",
    "get_mode_script_path",
    "get_exhaustiveness_prompt",
    # Domain types (planner-specific)
    "GuidanceResult",
    "FlatCommand",
    "BranchCommand",
    "NextCommand",
    # Routing
    "WORK_PHASES",
    "detect_qr_state",
    "route_work_phase",
    "get_work_phase_config",
    "get_all_work_phases",
]
