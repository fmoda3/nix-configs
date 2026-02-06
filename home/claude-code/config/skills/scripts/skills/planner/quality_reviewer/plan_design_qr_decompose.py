#!/usr/bin/env python3
"""QR decomposition for plan-design phase.

Scope: Plan structure and decision quality.
  - Decision log completeness (all non-obvious elements documented)
  - Policy default verification (user-specified backing required)
  - Milestone structure (code_intents present)
  - Reference integrity (decision_refs valid)
NOT code correctness or documentation quality.

Severity categories (per conventions/severity.md):
  MUST: DIAGRAM categories + KNOWLEDGE subset
    - ORPHAN_NODE, INVALID_EDGE_REF, INVALID_SCOPE_REF
    - DECISION_LOG_MISSING, POLICY_UNJUSTIFIED
  SHOULD: Plan structure gaps
  COULD: Cosmetic plan issues
"""

from skills.planner.quality_reviewer.prompts.decompose import dispatch_step


PHASE = "plan-design"


STEP_1_ABSORB = """\
Read plan.json from STATE_DIR:
  cat $STATE_DIR/plan.json | jq '.'

SCOPE: Plan structure and decision quality.

Focus on:
  - planning_context.decisions (completeness, reasoning quality)
  - planning_context.constraints (all documented?)
  - planning_context.risks (identified and addressed?)
  - milestones[].code_intents (structure present?)
  - invisible_knowledge (captured?)

OUT OF SCOPE (verified in later phases):
  - Code correctness (plan-code phase)
  - Documentation quality (plan-docs phase)"""


STEP_2_CONCERNS = """\
Brainstorm concerns specific to PLAN STRUCTURE:
  - Missing decisions (non-obvious choices not logged)
  - Policy defaults without user backing
  - Orphan milestones (no code_intents)
  - Invalid references (decision_refs point nowhere)
  - Reasoning chains too shallow
  - Risks identified but not addressed

DO NOT brainstorm code or documentation concerns (out of scope)."""


STEP_3_ENUMERATION = """\
For plan-design, enumerate PLAN STRUCTURE ARTIFACTS:

DECISIONS:
  - Each decision in planning_context.decisions (ID, decision text)
  - Has reasoning? Multi-step chain?

CONSTRAINTS:
  - Each constraint in planning_context.constraints (ID, type)
  - User-specified or inferred?

RISKS:
  - Each risk in planning_context.risks (ID, risk text)
  - Has mitigation?

MILESTONES:
  - Each milestone (ID, name, count of code_intents)
  - Each code_intent with decision_refs (ID, which decisions referenced)

INVISIBLE KNOWLEDGE:
  - system, invariants[], tradeoffs[] content"""


STEP_5_GENERATE = """\
SEVERITY ASSIGNMENT (per conventions/severity.md, plan-design scope):

  MUST (blocks all iterations):
    - DIAGRAM categories:
      * ORPHAN_NODE: node with zero edges
      * INVALID_EDGE_REF: edge references missing node
      * INVALID_SCOPE_REF: scope references non-existent milestone
    - KNOWLEDGE subset:
      * DECISION_LOG_MISSING: non-trivial choice without logged rationale
      * POLICY_UNJUSTIFIED: policy default without Tier 1 backing
      * ASSUMPTION_UNVALIDATED: architectural assumption without citation

  SHOULD (iterations 1-4):
    - Shallow reasoning chains (premise without implication)
    - Missing risk mitigations
    - Incomplete constraint documentation

  COULD (iterations 1-3):
    - Cosmetic plan formatting
    - Minor inconsistencies in naming"""


COMPONENT_EXAMPLES = """\
  - A milestone
  - A major decision
  - A constraint category"""


CONCERN_EXAMPLES = """\
  - Reasoning chain quality
  - Reference integrity
  - Risk coverage"""


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
    module_path = module_path or "skills.planner.quality_reviewer.plan_design_qr_decompose"
    state_dir = kwargs.get("state_dir", "")
    return dispatch_step(step, PHASE, module_path, PHASE_PROMPTS, GROUPING_CONFIG, state_dir)


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main

    mode_main(
        __file__,
        get_step_guidance,
        "QR-Plan-Design-Decompose: Generate verification items for plan completeness",
        extra_args=[
            (["--state-dir"], {"type": str, "required": True, "help": "State directory path"}),
        ],
    )
