"""CLI package for plan.json and QR state manipulation.

Provides structured commands for LLM agents to modify plan.json
and qr-{phase}.json with validation. Asymmetric design: flexible
reads (cat/jq), constrained writes (validated CLI commands).

Modules:
  plan: plan.json manipulation (milestones, intents, changes, docs)
  qr: qr-{phase}.json atomic updates (for parallel verify agents)

Note: plan module is invoked via `python3 -m skills.planner.cli.plan`,
not imported. Eager import here would cause RuntimeWarning during -m execution.
"""

from . import qr

__all__ = ["qr"]
