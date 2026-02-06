"""Workflow discovery via importlib scanning.

Pull-based discovery eliminates import-time side effects.
"""

from __future__ import annotations

import importlib.util
import pkgutil
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .core import Workflow


def discover_workflows(package: str) -> dict[str, "Workflow"]:
    """Discover workflows in package without executing module-level code.

    Uses importlib scanning to find WORKFLOW constants without triggering
    side effects. Enables isolated testing and avoids circular dependencies.

    Args:
        package: Package name (e.g., "skills")

    Returns:
        Dict mapping workflow name to Workflow object

    Raises:
        ImportError: If package not found or malformed skill module
    """
    workflows = {}
    errors = []

    # Import the package to get its path
    try:
        pkg = importlib.import_module(package)
    except ImportError as e:
        raise ImportError(f"Package '{package}' not found: {e}")

    if not hasattr(pkg, "__path__"):
        return workflows

    # Scan for skill modules
    for importer, modname, ispkg in pkgutil.walk_packages(
        path=pkg.__path__, prefix=f"{package}."
    ):
        # Skip lib/ and other framework directories (lib/ contains framework code, not skill workflows; including it would register infrastructure as skills)
        if ".lib." in modname or modname.endswith(".lib"):
            continue

        # Try to import and extract WORKFLOW constant
        try:
            module = importlib.import_module(modname)
            if hasattr(module, "WORKFLOW"):
                workflow = module.WORKFLOW
                # Set _module_path if not already set (frozen dataclass bypass)
                if workflow._module_path is None:
                    object.__setattr__(workflow, "_module_path", modname)
                workflows[workflow.name] = workflow
        except Exception as e:
            # Collect ALL exceptions during import (syntax, name, import errors).
            # Aggregation enables single error report listing all malformed modules.
            errors.append((modname, str(e)))

    # Aggregates all import errors into single comprehensive report
    # (prevents sequential fix-test cycles for multiple malformed modules).
    if errors:
        error_list = "\n".join(f"  - {mod}: {err}" for mod, err in errors)
        raise ImportError(
            f"Failed to discover workflows in {len(errors)} module(s):\n{error_list}"
        )

    return workflows
