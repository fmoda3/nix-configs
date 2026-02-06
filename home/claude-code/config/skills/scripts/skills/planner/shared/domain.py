"""Domain types for the planner skill.

Planner-specific types that extend the shared workflow types.
Command routing types (FlatCommand, BranchCommand, NextCommand) are
re-exported from skills.lib.workflow.types for backwards compatibility.
"""

from dataclasses import dataclass
from enum import Enum

# Re-export command routing types from lib (backwards compatibility)
from skills.lib.workflow.types import (
    FlatCommand,
    BranchCommand,
    NextCommand,
)


# =============================================================================
# Step Guidance
# =============================================================================


@dataclass
class GuidanceResult:
    """Step guidance returned by get_*_guidance functions.

    Replaces stringly-typed dicts with explicit structure.

    Attributes:
        title: Step title for display
        actions: List of action strings (may include XML blocks)
        next_command: Routing command for invoke_after
    """

    title: str
    actions: list[str]
    next_command: NextCommand = None


# =============================================================================
# QR Severity and Categories
# =============================================================================


class Severity(Enum):
    MUST = "MUST"       # Unrecoverable if missed
    SHOULD = "SHOULD"   # Maintainability debt
    COULD = "COULD"     # Auto-fixable


class IssueCategory(Enum):
    """Issue categories for QR findings.

    Severity mappings are defined in CATEGORY_SEVERITY dict below.
    Do not add severity comments here - they drift from the actual mapping.
    """
    DECISION_LOG_MISSING = "DECISION_LOG_MISSING"
    POLICY_UNJUSTIFIED = "POLICY_UNJUSTIFIED"
    IK_TRANSFER_FAILURE = "IK_TRANSFER_FAILURE"
    TEMPORAL_CONTAMINATION = "TEMPORAL_CONTAMINATION"
    BASELINE_REFERENCE = "BASELINE_REFERENCE"
    ASSUMPTION_UNVALIDATED = "ASSUMPTION_UNVALIDATED"
    LLM_COMPREHENSION_RISK = "LLM_COMPREHENSION_RISK"
    MARKER_INVALID = "MARKER_INVALID"

    GOD_OBJECT = "GOD_OBJECT"
    GOD_FUNCTION = "GOD_FUNCTION"
    DUPLICATE_LOGIC = "DUPLICATE_LOGIC"
    INCONSISTENT_ERROR_HANDLING = "INCONSISTENT_ERROR_HANDLING"
    CONVENTION_VIOLATION = "CONVENTION_VIOLATION"
    TESTING_STRATEGY_VIOLATION = "TESTING_STRATEGY_VIOLATION"

    DEAD_CODE = "DEAD_CODE"
    FORMATTER_FIXABLE = "FORMATTER_FIXABLE"
    MINOR_INCONSISTENCY = "MINOR_INCONSISTENCY"

    ORPHANED_CHANGE = "ORPHANED_CHANGE"
    MISSING_CHANGE = "MISSING_CHANGE"
    INTENT_MISMATCH = "INTENT_MISMATCH"
    DECISION_REF_BROKEN = "DECISION_REF_BROKEN"

    TRANSLATION_OMISSION = "TRANSLATION_OMISSION"
    TRANSLATION_ADDITION = "TRANSLATION_ADDITION"
    TRANSLATION_MISMATCH = "TRANSLATION_MISMATCH"

    DOCSTRING_MISSING = "DOCSTRING_MISSING"
    MODULE_COMMENT_MISSING = "MODULE_COMMENT_MISSING"


CATEGORY_SEVERITY: dict[IssueCategory, Severity] = {
    # KNOWLEDGE -> MUST
    IssueCategory.DECISION_LOG_MISSING: Severity.MUST,
    IssueCategory.POLICY_UNJUSTIFIED: Severity.MUST,
    IssueCategory.IK_TRANSFER_FAILURE: Severity.MUST,
    IssueCategory.TEMPORAL_CONTAMINATION: Severity.MUST,
    IssueCategory.BASELINE_REFERENCE: Severity.MUST,
    IssueCategory.ASSUMPTION_UNVALIDATED: Severity.MUST,
    IssueCategory.LLM_COMPREHENSION_RISK: Severity.MUST,
    IssueCategory.MARKER_INVALID: Severity.MUST,
    # STRUCTURE -> SHOULD
    IssueCategory.GOD_OBJECT: Severity.SHOULD,
    IssueCategory.GOD_FUNCTION: Severity.SHOULD,
    IssueCategory.DUPLICATE_LOGIC: Severity.SHOULD,
    IssueCategory.INCONSISTENT_ERROR_HANDLING: Severity.SHOULD,
    IssueCategory.CONVENTION_VIOLATION: Severity.SHOULD,
    IssueCategory.TESTING_STRATEGY_VIOLATION: Severity.SHOULD,
    # COSMETIC -> COULD
    IssueCategory.DEAD_CODE: Severity.COULD,
    IssueCategory.FORMATTER_FIXABLE: Severity.COULD,
    IssueCategory.MINOR_INCONSISTENCY: Severity.COULD,
    # JSON-IR STRUCTURE -> MUST
    IssueCategory.ORPHANED_CHANGE: Severity.MUST,
    IssueCategory.MISSING_CHANGE: Severity.MUST,
    IssueCategory.INTENT_MISMATCH: Severity.MUST,
    IssueCategory.DECISION_REF_BROKEN: Severity.MUST,
    # TRANSLATION -> MUST
    IssueCategory.TRANSLATION_OMISSION: Severity.MUST,
    IssueCategory.TRANSLATION_ADDITION: Severity.MUST,
    IssueCategory.TRANSLATION_MISMATCH: Severity.MUST,
    # DOCUMENTATION -> SHOULD
    IssueCategory.DOCSTRING_MISSING: Severity.SHOULD,
    IssueCategory.MODULE_COMMENT_MISSING: Severity.SHOULD,
}


def _validate_category_severity_mapping():
    """Ensure all categories have severity mappings.

    WHY validate at import time instead of runtime:
    - Configuration bugs should fail fast (don't wait for specific issue type)
    - Import-time validation runs during tests, catches drift before production
    - Module load failure is obvious; missing severity at runtime is silent degradation

    WHY this prevents drift:
    - New IssueCategory enum value -> immediate ValueError if no severity
    - Forces developer to consciously choose severity (MUST/SHOULD/COULD)
    - Prevents copy-paste bugs (adding category, forgetting severity mapping)

    WHAT BREAKS if removed:
    - New category without severity -> QR agent doesn't know blocking behavior
    - get_severity() returns None -> Iteration escalation logic breaks
    """
    unmapped = set(IssueCategory) - set(CATEGORY_SEVERITY.keys())
    if unmapped:
        raise ValueError(f"Categories missing severity mapping: {unmapped}")


# Run at import time
_validate_category_severity_mapping()
