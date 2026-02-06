"""Unified file I/O with contextual error handling."""
import sys
from pathlib import Path


def read_text_or_exit(path: Path, context: str) -> str:
    """Read file contents or exit with contextual error message.

    Args:
        path: Path to file to read
        context: Context string for error message (e.g., "loading convention")

    Returns:
        File contents as string

    Exits:
        With contextual error message if file not found or permission denied
    """
    try:
        return path.read_text()
    except FileNotFoundError:
        sys.exit(f"ERROR: {context}: file not found: {path}")
    except PermissionError:
        sys.exit(f"ERROR: {context}: permission denied: {path}")
