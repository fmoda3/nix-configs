"""Extract content from machine-parseable code quality documents.

Code quality documents use HTML comments for metadata and XML tags for mode-specific
content. This module provides stdlib-only parsing for phase-aware content extraction.
"""

from dataclasses import dataclass
from pathlib import Path
import re

from .types import Phase, Mode, PHASE_TO_MODE


@dataclass
class ExtractedContent:
    """Extracted content from a code quality document.

    Attributes:
        primer: Content between document title and first mode tag
        mode_guidance: Mode-specific guidance from <design-mode> or <code-mode>
        categories: List of (name, content) tuples for numbered categories
    """
    primer: str
    mode_guidance: str
    categories: list[tuple[str, str]]


def extract_content(doc_path: Path, phase: Phase) -> ExtractedContent | None:
    """Extract phase-appropriate content from code quality document.

    Args:
        doc_path: Path to markdown document
        phase: Workflow phase (determines mode and applicability)

    Returns:
        ExtractedContent if document applies to phase, None otherwise
    """
    if not doc_path.exists():
        return None

    content = doc_path.read_text()

    applicable = _extract_applicable_phases(content)
    if phase.value not in applicable:
        return None

    mode = PHASE_TO_MODE[phase]

    primer = _extract_primer(content)
    mode_guidance = _extract_mode_content(content, mode)
    categories = _extract_categories(content)

    return ExtractedContent(
        primer=primer,
        mode_guidance=mode_guidance,
        categories=categories
    )


def _extract_applicable_phases(content: str) -> list[str]:
    """Parse HTML comment for applicable phases.

    Expected format: <!-- applicable_phases: phase1, phase2, ... -->

    Args:
        content: Full document content

    Returns:
        List of phase names (empty if comment not found)
    """
    match = re.search(r'<!--\s*applicable_phases:\s*([^-]+?)\s*-->', content)
    if not match:
        return []

    phases_str = match.group(1)
    return [p.strip() for p in phases_str.split(',')]


def _extract_primer(content: str) -> str:
    """Extract content between title and first mode tag.

    Primer includes: core question, what to look for, threshold.
    Ends at first <design-mode> or <code-mode> tag.

    Args:
        content: Full document content

    Returns:
        Primer text (empty string if not found)
    """
    lines = content.split('\n')

    start_idx = None
    for i, line in enumerate(lines):
        if line.startswith('# '):
            start_idx = i
            break

    if start_idx is None:
        return ""

    end_idx = len(lines)
    for i in range(start_idx + 1, len(lines)):
        if '<design-mode>' in lines[i] or '<code-mode>' in lines[i]:
            end_idx = i
            break

    return '\n'.join(lines[start_idx:end_idx]).strip()


def _extract_mode_content(content: str, mode: Mode) -> str:
    """Extract content from mode-specific XML tag.

    Uses str.partition() for stdlib-only extraction.

    Args:
        content: Full document content
        mode: Mode.DESIGN or Mode.CODE

    Returns:
        Content inside mode tag (empty string if tag not found)
    """
    tag = f"<{mode.value}-mode>"
    close_tag = f"</{mode.value}-mode>"

    _, sep, after = content.partition(tag)
    if not sep:
        return ""

    inner, sep, _ = after.partition(close_tag)
    if not sep:
        return ""

    return inner.strip()


def _extract_categories(content: str) -> list[tuple[str, str]]:
    """Extract numbered categories from document.

    Categories are headings like: ## N. Category Name
    Content extends until next ## heading or end of document.

    Args:
        content: Full document content

    Returns:
        List of (category_name, category_content) tuples
    """
    lines = content.split('\n')
    categories = []
    current_cat = None
    current_content = []

    for line in lines:
        match = re.match(r'^## \d+\. (.+)$', line)
        if match:
            if current_cat:
                categories.append((current_cat, '\n'.join(current_content).strip()))
            current_cat = match.group(1)
            current_content = [line]
        elif current_cat:
            current_content.append(line)

    if current_cat:
        categories.append((current_cat, '\n'.join(current_content).strip()))

    return categories
