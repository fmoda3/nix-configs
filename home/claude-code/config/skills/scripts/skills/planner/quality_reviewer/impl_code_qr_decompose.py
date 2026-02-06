#!/usr/bin/env python3
"""QR decomposition for impl-code phase.

Scope: Implemented code quality.
  - Acceptance criteria verification (expectations vs observations)
  - Cross-cutting concerns (shared state, error propagation)
  - Code quality (all 8 quality documents)
  - Intent marker validation
NOT plan structure or documentation (verified in earlier phases).

Severity categories: Same as plan-code (Dev can fix code issues).
"""

from skills.planner.quality_reviewer.prompts.decompose import dispatch_step


PHASE = "impl-code"


STEP_1_ABSORB = """\
Read plan.json from STATE_DIR:
  cat $STATE_DIR/plan.json | jq '.'

Also read MODIFIED_FILES from codebase (paths from milestones).

SCOPE: Implemented code quality.

Focus on:
  - milestones[].acceptance_criteria (expectations)
  - Actual implemented code in modified files (observations)
  - Code quality (structure, patterns, documentation)
  - Intent markers in implemented code

OUT OF SCOPE:
  - Plan structure (already verified in plan-design)
  - Documentation files (impl-docs phase)"""


STEP_2_CONCERNS = """\
Brainstorm concerns specific to IMPLEMENTED CODE:
  - Acceptance criteria not met
  - Cross-cutting concerns broken (error handling, logging)
  - Code quality violations (god objects, god functions)
  - Missing or invalid intent markers
  - Implementation drift from plan

DO NOT brainstorm plan structure or documentation concerns."""


STEP_3_ENUMERATION = """\
For impl-code, enumerate IMPLEMENTATION ARTIFACTS:

ACCEPTANCE CRITERIA:
  - Each milestone with acceptance_criteria (ID, criteria count)
  - Each criterion (ID, expectation text)

FILES:
  - Files modified per milestone (path list)
  - Actual file content (read from codebase)

CROSS-CUTTING:
  - Error handling patterns used
  - Logging patterns used
  - Shared state access patterns

CODE QUALITY:
  - Function sizes (line counts)
  - Nesting depths
  - Dependency counts"""


STEP_5_GENERATE = """\
SEVERITY ASSIGNMENT (per conventions/severity.md, impl-code scope):

  MUST (blocks all iterations):
    - Acceptance criterion not met
    - MARKER_INVALID: intent marker without valid explanation

  SHOULD (iterations 1-4) - STRUCTURE categories:
    - GOD_OBJECT: >15 methods OR >10 deps
    - GOD_FUNCTION: >50 lines OR >3 nesting
    - CONVENTION_VIOLATION: violates documented project convention
    - INCONSISTENT_ERROR_HANDLING: mixed exceptions/codes

  COULD (iterations 1-3) - COSMETIC:
    - DEAD_CODE: unused functions, impossible branches
    - FORMATTER_FIXABLE: style issues"""


COMPONENT_EXAMPLES = """\
  - A modified file
  - A milestone's implementation
  - A cross-cutting concern pattern"""


CONCERN_EXAMPLES = """\
  - Acceptance criteria compliance
  - Error handling consistency
  - Code structure quality"""


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


def get_step_guidance(step: int, module_path: str = None, **kwargs) -> dict:
    module_path = module_path or "skills.planner.quality_reviewer.impl_code_qr_decompose"
    state_dir = kwargs.get("state_dir", "")
    return dispatch_step(step, PHASE, module_path, PHASE_PROMPTS, GROUPING_CONFIG, state_dir)


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main

    mode_main(
        __file__,
        get_step_guidance,
        "QR-Impl-Code-Decompose: Generate verification items for implemented code",
        extra_args=[
            (["--state-dir"], {"type": str, "required": True, "help": "State directory path"}),
        ],
    )
