#!/usr/bin/env python3
"""QR decomposition for plan-docs phase.

Scope: Documentation quality only.
  - COVERAGE: decisions/IK documented somewhere
  - QUALITY: temporal-free, WHY-not-WHAT
NOT code correctness (plan-code's job).

Severity categories (per conventions/severity.md):
  MUST: KNOWLEDGE categories only (TW can fix documentation issues)
    - DECISION_LOG_MISSING, IK_TRANSFER_FAILURE
    - TEMPORAL_CONTAMINATION, BASELINE_REFERENCE
  SHOULD: Documentation structure gaps
  COULD: Minor formatting inconsistencies

WHY KNOWLEDGE-only: TW agent cannot fix code correctness issues.
Applying STRUCTURE categories generates unfixable items, causing QR loops.
"""

from skills.planner.quality_reviewer.prompts.decompose import dispatch_step


PHASE = "plan-docs"


# =============================================================================
# PHASE-SPECIFIC PROMPTS (visible at module level for debugging)
# =============================================================================

STEP_1_ABSORB = """\
Read plan.json from STATE_DIR:
  cat $STATE_DIR/plan.json | jq '.'

SCOPE: Documentation quality only. You verify doc_diff fields.

WHAT YOU REVIEW:
  - milestones[].code_changes[].doc_diff -- documentation overlay diffs
  - Temporal contamination in doc_diff content
  - WHY-not-WHAT quality in added comments
  - Decision coverage (DL-XXX references)

WHAT YOU DO NOT REVIEW:
  - milestones[].code_changes[].diff -- code logic (plan-code's job)
  - Code correctness, compilation, types
  - Whether code implementation is correct

EXTRACT doc_diffs for review:
  cat $STATE_DIR/plan.json | jq '[.milestones[].code_changes[] | select(.doc_diff != "") | {id, file, doc_diff}]'

OUT OF SCOPE:
  - diff field content (plan-code phase)
  - Code correctness"""


STEP_2_CONCERNS = """\
Brainstorm concerns specific to DOC_DIFF QUALITY:
  - Code changes missing doc_diff (diff present but doc_diff empty)
  - Temporal contamination in doc_diff content
  - Missing WHY-not-WHAT (comments describe code, not explain reasoning)
  - Incomplete decision coverage (DL-XXX not referenced in any doc_diff)
  - Invalid diff format (doc_diff not valid unified diff)

DO NOT brainstorm code correctness concerns (out of scope for this phase).
DO NOT review diff field content (plan-code's job)."""


STEP_3_ENUMERATION = """\
For plan-docs, enumerate DOC_DIFF content only:

ARTIFACTS TO VERIFY:
  - Each code_change with non-empty doc_diff:
    * Diff format validity (unified diff syntax)
    * Temporal contamination (change-relative language)
    * WHY-not-WHAT (comments explain reasoning)
    * Decision references (DL-XXX present)

  - Each code_change with diff but NO doc_diff:
    * Flag as MUST: documentation required

COVERAGE CHECK:
  - List all DL-XXX IDs from planning_context.decisions
  - Verify each appears in at least one doc_diff
  - Missing coverage: MUST severity

DO NOT enumerate:
  - diff field content (plan-code's job)
  - Code correctness"""


STEP_5_GENERATE = """\
SEVERITY ASSIGNMENT for plan-docs (doc_diff focused):

  MUST (blocks all iterations):
    - CODE_WITHOUT_DOCS: code_change has diff but no doc_diff
    - DECISION_UNCOVERED: DL-XXX not in any doc_diff
    - INVALID_DIFF_FORMAT: doc_diff not valid unified diff
    - TEMPORAL_CONTAMINATION: change-relative language in doc_diff

  SHOULD (iterations 1-4):
    - WHY_NOT_WHAT: doc_diff comment describes code, not reasoning
    - MISSING_DOCSTRING: function in diff lacks docstring in doc_diff

  COULD (iterations 1-3):
    - FORMATTING: minor diff formatting issues

DO NOT generate items about:
  - diff field content (plan-code's job)
  - Code logic correctness"""


COMPONENT_EXAMPLES = """\
  - A code_change's doc_diff field
  - A decision log entry (for coverage)"""


CONCERN_EXAMPLES = """\
  - Missing doc_diff for code_change with diff
  - Temporal contamination in doc_diff
  - Decision coverage gaps"""


# =============================================================================
# CONFIGURATION FOR DISPATCH
# =============================================================================

PHASE_PROMPTS = {
    1: STEP_1_ABSORB,
    2: STEP_2_CONCERNS,
    3: STEP_3_ENUMERATION,
    5: STEP_5_GENERATE,
}

GROUPING_CONFIG = {
    "component_examples": COMPONENT_EXAMPLES,
    "concern_examples": CONCERN_EXAMPLES,
}


# =============================================================================
# ENTRY POINT
# =============================================================================

def get_step_guidance(step: int, module_path: str = None, **kwargs) -> dict:
    """Entry point for workflow execution.

    Called by mode_main() in cli.py. Delegates to shared dispatch_step()
    with phase-specific prompts and grouping config.
    """
    module_path = module_path or "skills.planner.quality_reviewer.plan_docs_qr_decompose"
    state_dir = kwargs.get("state_dir", "")
    return dispatch_step(step, PHASE, module_path, PHASE_PROMPTS, GROUPING_CONFIG, state_dir)


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main

    mode_main(
        __file__,
        get_step_guidance,
        "QR-Plan-Docs-Decompose: Generate verification items for documentation completeness",
        extra_args=[
            (["--state-dir"], {"type": str, "required": True, "help": "State directory path"}),
        ],
    )
