#!/usr/bin/env python3
"""
DeepThink Sub-Agent Workflow - Perspective-specific analysis.

Eight-step workflow:
  1. Context Grounding   - Re-read context, step-back to principles
  2. Analogical Generation - Self-generate relevant examples
  3. Planning            - Explicit analysis plan before execution
  4. Analysis            - Execute plan with evidence grounding
  5. Self-Verification   - Factored verification of claims
  6. Perspective Contrast - Steel-man opposing view
  7. Failure Modes       - Actionable failure analysis
  8. Output Synthesis    - Structured output for parent aggregation
"""

import argparse
import sys

from skills.lib.workflow.prompts import format_step


# ============================================================================
# CONFIGURATION
# ============================================================================

MODULE_PATH = "skills.deepthink.subagent"


# ============================================================================
# MESSAGE TEMPLATES
# ============================================================================

# --- STEP 1: CONTEXT_GROUNDING -----------------------------------------------

CONTEXT_GROUNDING_INSTRUCTIONS = """\
Before beginning analysis, ground yourself in the shared context.

PART A - RE-READ SHARED CONTEXT:
  Read the shared context again. Restate each element:
  - CLARIFIED QUESTION: [restate in your own words]
  - DOMAIN: [from shared context]
  - FIRST PRINCIPLES: [list from shared context]
  - QUESTION TYPE: [from shared context]
  - EVALUATION CRITERIA: [from shared context]
  - KEY ANALOGIES: [from shared context]

PART B - STEP BACK (perspective-specific):
  From YOUR assigned perspective, which 2-3 first principles
  are MOST relevant? Why do these matter more than others
  for your analytical lens?

PART C - TASK UNDERSTANDING:
  Review your task definition:
  - Name: [from dispatch]
  - Strategy: [from dispatch]
  - Task: [from dispatch]
  - Sub-Questions: [from dispatch]
  - Unique Value: [from dispatch]

  Restate your task in your own words.
  What unique contribution will you provide that others won't?

OUTPUT FORMAT:
```
RESTATED CONTEXT:
- Question: [your restatement]
- Domain: [domain]
- Key principles for MY perspective: [2-3 most relevant]

MY TASK:
[restatement in own words]

MY UNIQUE CONTRIBUTION:
[what I will provide that others likely won't]
```"""

# --- STEP 2: ANALOGICAL_GENERATION -------------------------------------------

ANALOGICAL_GENERATION_INSTRUCTIONS = """\
Before analyzing, recall relevant precedents from YOUR analytical lens.

Generate 2-3 examples of similar problems approached from your
perspective. These should be:
  - Relevant to the current question
  - Distinct from each other
  - Drawn from your assigned domain/perspective

For each example:
  - Describe the problem briefly
  - Explain how it was approached from your perspective
  - State what insight transfers to the current question

If the shared context already contains highly relevant analogies,
you may reference those and add 1-2 perspective-specific ones.

OUTPUT FORMAT:
```
SELF-GENERATED ANALOGIES:

1. [Problem]: [brief description]
   Approach: [how your perspective handled it]
   Transfer: [what applies to current question]

2. [Problem]: [brief description]
   Approach: [how addressed]
   Transfer: [applicable insight]
```"""

# --- STEP 3: PLANNING --------------------------------------------------------

PLANNING_INSTRUCTIONS = """\
Before analyzing, devise a plan for approaching this from your
perspective.

Let's first understand the problem and devise a plan to solve it.
Then we will carry out the plan step by step.

PART A - APPROACH OUTLINE:
  What specific aspects will you examine?
  In what order should they be addressed?
  What intermediate conclusions do you need to reach?

PART B - EVIDENCE SOURCES:
  What evidence will you draw on?
  - First principles from Step 1
  - Analogies from Step 2
  - Domain knowledge
  - Assigned sub-questions

PART C - SUCCESS CRITERIA:
  What would a complete analysis from your perspective include?
  How will you know when you've done enough?

OUTPUT FORMAT:
```
ANALYSIS PLAN:
1. [First aspect to examine]
2. [Second aspect]
3. [Third aspect]
...

EVIDENCE I WILL USE:
- [source 1]
- [source 2]

SUCCESS CRITERIA:
- [criterion 1]
- [criterion 2]
```"""

# --- STEP 4: ANALYSIS --------------------------------------------------------

ANALYSIS_INSTRUCTIONS = """\
Execute your analysis plan from Step 3.
Work through each aspect step by step.

EXPLORATION OPTION:
  If your analysis requires concrete evidence not in the shared context:
  - Use Read/Glob/Grep to examine specific files or patterns
  - Keep exploration targeted -- only what your perspective needs
  - Cite evidence from exploration with file:line references
  If shared context is sufficient, proceed without exploration.

REQUIREMENTS:
  - Follow your plan systematically
  - Ground each claim in evidence (cite source)
  - Mark confidence on each major claim: HIGH / MEDIUM / LOW
  - Address your assigned sub-questions explicitly

CONFIDENCE MARKERS:
  - HIGH: Strong reasoning, multiple sources, well-supported
  - MEDIUM: Reasonable but could be contested, single source
  - LOW: Speculative, limited evidence, tentative

EVIDENCE GROUNDING:
  For each major claim, cite source:
  - (FP): First principle from shared context
  - (AN): Analogy from Step 2
  - (DK): Domain knowledge
  - (UN): Ungrounded - flag explicitly

OUTPUT FORMAT:
```
ANALYSIS:

[Aspect 1 from plan]
[Your reasoning] (source) [CONFIDENCE]

[Aspect 2 from plan]
[Your reasoning] (source) [CONFIDENCE]

...

PROPOSALS/POSITIONS:

1. [Proposal] [HIGH/MEDIUM/LOW]
   Reasoning: [why]
   Evidence: [sources]

2. [Proposal] [CONFIDENCE]
   Reasoning: [why]
   Evidence: [sources]

SUB-QUESTION RESPONSES:
- [Q1]: [response] [CONFIDENCE]
- [Q2]: [response] [CONFIDENCE]
```"""

# --- STEP 5: SELF_VERIFICATION -----------------------------------------------

SELF_VERIFICATION_INSTRUCTIONS = """\
Verify your analysis through independent questioning.

PART A - VERIFICATION QUESTIONS:
  Generate 3-5 questions that would test your key claims.

  Use OPEN questions (What is...? Where does...? How would...?)
  NOT yes/no questions.
  Yes/no questions bias toward agreement regardless of correctness.

  Focus on:
  - Claims marked MEDIUM or LOW confidence
  - Claims critical to your main conclusions
  - Assumptions that could be wrong

PART B - INDEPENDENT ANSWERS:
  For each question, answer based ONLY on:
  - First principles from shared context
  - Your analogies from Step 2
  - Domain knowledge

  CRITICAL: Do NOT look at your Step 4 analysis while answering.
  Answer based on evidence, not what your analysis claims.

PART C - DISCREPANCY CHECK:
  Compare verification answers against your Step 4 analysis.
  Where do they differ? List each discrepancy.
  For significant discrepancies, note how to resolve.

OUTPUT FORMAT:
```
VERIFICATION QUESTIONS:
1. [open question about key claim]
2. [open question]
3. [open question]

INDEPENDENT ANSWERS (without consulting analysis):
1. [answer]
2. [answer]
3. [answer]

DISCREPANCIES:
- [claim from analysis] vs [verification answer]: [resolution]
- Or: 'No significant discrepancies found'

ANALYSIS UPDATES (if any):
- [what to revise based on verification]
```"""

# --- STEP 6: PERSPECTIVE_CONTRAST --------------------------------------------

PERSPECTIVE_CONTRAST_INSTRUCTIONS = """\
Before finalizing, consider the strongest opposing perspective.

PART A - OPPOSING POSITION:
  What is the strongest argument AGAINST your main conclusions?
  Steel-man this position - make it as compelling as possible.
  Who would hold this view and why?

PART B - CONFLICT ANALYSIS:
  Where specifically does the opposing view conflict with yours?
  What evidence does the opposition have that you lack?
  What evidence do you have that they would dismiss?

PART C - WHAT WOULD CHANGE YOUR MIND:
  What specific evidence or argument would cause you to revise?
  What assumptions are you making that could be wrong?

This step strengthens your analysis by pre-emptively addressing
the strongest counterarguments. If you cannot articulate a strong
opposing view, your confidence should increase.

OUTPUT FORMAT:
```
STRONGEST COUNTER-POSITION:
[Steel-manned opposing view - make it compelling]

WHO HOLDS THIS VIEW:
[type of person/perspective that would argue this]

KEY CONFLICTS:
- My position: [X] vs Opposition: [Y]
- My position: [A] vs Opposition: [B]

WHAT WOULD CHANGE MY CONCLUSION:
- [specific evidence that would cause revision]
- [assumption that if wrong would change conclusion]
```"""

# --- STEP 7: FAILURE_MODES ---------------------------------------------------

FAILURE_MODES_INSTRUCTIONS = """\
For each proposal from your analysis, provide actionable failure modes.

Each failure mode MUST include all three elements:
  1. ELEMENT: The specific proposal or claim
  2. PROBLEM: What could go wrong or be invalid
  3. ACTION: What would mitigate this risk or test this assumption

Feedback missing any element is too vague to be useful.

GOOD: 'ELEMENT: Claim X. PROBLEM: Assumes Y which may not hold.
       ACTION: Verify Y by checking Z.'
BAD:  'This proposal has risks.' (no specific element/problem/action)

This step is CRITICAL.
Analysis without actionable failure modes is incomplete.
The quality gate will filter outputs without meaningful failure modes.

OUTPUT FORMAT:
```
FAILURE MODES:

For Proposal 1 ([name]):
- ELEMENT: [specific claim]
  PROBLEM: [what could go wrong]
  ACTION: [mitigation or test]

- ELEMENT: [another aspect]
  PROBLEM: [risk]
  ACTION: [mitigation]

For Proposal 2 ([name]):
- ELEMENT: [claim]
  PROBLEM: [risk]
  ACTION: [mitigation]

[etc.]
```"""

# --- STEP 8: OUTPUT_SYNTHESIS ------------------------------------------------

OUTPUT_SYNTHESIS_INSTRUCTIONS = """\
Synthesize your analysis into structured output for aggregation.

The parent workflow will extract specific sections from your output.
Use the EXACT format below for clean parsing.

OUTPUT FORMAT:
```
## Core Findings

Confidence: [HIGH|MEDIUM|LOW]

[Your main conclusions from this perspective - 2-3 sentences]

## Proposals

1. [Proposal] [HIGH/MEDIUM/LOW]
   Evidence: [key supporting reasoning]

2. [Proposal] [CONFIDENCE]
   Evidence: [key supporting reasoning]

## Sub-Question Responses

Q: [assigned sub-question 1]
A: [your response]

Q: [assigned sub-question 2]
A: [your response]

## Evidence Chains

[Key reasoning chains that led to your conclusions]
[Include intermediate insights even if conclusions changed]
[These are valuable for synthesis even if final conclusion differs]

## Failure Modes

Proposal 1:
- ELEMENT: [x] | PROBLEM: [y] | ACTION: [z]

Proposal 2:
- ELEMENT: [x] | PROBLEM: [y] | ACTION: [z]

## Perspective Gaps

[What your perspective likely misses or undervalues]
[What other sub-agents should cover]
[Where to weight your analysis less]

## Opposing View

[Steel-manned counter-position from Step 6]
[What would change your conclusion]
```

This completes your sub-agent analysis.
Your output will be collected for aggregation and synthesis."""


# ============================================================================
# MESSAGE BUILDERS
# ============================================================================

def build_next_command(step: int) -> str | None:
    """Build invoke command for next step."""
    if step >= 8:
        return None
    return f"python3 -m {MODULE_PATH} --step {step + 1}"


STEP_TITLES = {
    1: "Context Grounding",
    2: "Analogical Generation",
    3: "Planning",
    4: "Analysis",
    5: "Self-Verification",
    6: "Perspective Contrast",
    7: "Failure Modes",
    8: "Output Synthesis",
}

STEP_INSTRUCTIONS = {
    1: CONTEXT_GROUNDING_INSTRUCTIONS,
    2: ANALOGICAL_GENERATION_INSTRUCTIONS,
    3: PLANNING_INSTRUCTIONS,
    4: ANALYSIS_INSTRUCTIONS,
    5: SELF_VERIFICATION_INSTRUCTIONS,
    6: PERSPECTIVE_CONTRAST_INSTRUCTIONS,
    7: FAILURE_MODES_INSTRUCTIONS,
    8: OUTPUT_SYNTHESIS_INSTRUCTIONS,
}


def format_output(step: int) -> str:
    """Format output for given step."""
    if step not in STEP_TITLES:
        raise ValueError(f"Invalid step: {step}")

    title = STEP_TITLES[step]
    instructions = STEP_INSTRUCTIONS[step]
    next_cmd = build_next_command(step)
    return format_step(instructions, next_cmd or "", title=f"DEEPTHINK SUB-AGENT - {title}")


def main():
    parser = argparse.ArgumentParser(
        description="DeepThink Sub-Agent - Perspective-specific analysis workflow",
        epilog="Steps: 1-8 (grounding -> analogies -> planning -> analysis -> "
        "verification -> contrast -> failure modes -> synthesis)",
    )
    parser.add_argument("--step", type=int, required=True)
    args = parser.parse_args()

    if args.step < 1 or args.step > 8:
        sys.exit("ERROR: --step must be 1-8")

    print(format_output(args.step))


if __name__ == "__main__":
    main()
