#!/usr/bin/env python3
"""
DeepThink Skill - Structured reasoning for open-ended analytical questions.

Fourteen-step workflow (1-14):
  1. Context Clarification  - Remove bias from input (S2A)
  2. Abstraction            - Domain, first principles, key concepts
  3. Characterization       - Question type, answer structure, mode determination
  4. Analogical Recall      - Direct/cross-domain analogies, anti-patterns
  5. Planning               - Sub-questions, success criteria
  6. Sub-Agent Design       - Generate sub-agent task definitions (Full only)
  7. Design Critique        - Coverage, overlap, appropriateness (Full only)
  8. Design Revision        - Revise based on critique (Full only)
  9. Dispatch               - Launch sub-agents in parallel (Full only)
  10. Quality Gate          - Filter low-quality outputs (Full only)
  11. Aggregation           - Agreement/disagreement maps (Full only)
  12. Initial Synthesis     - First-pass integration
  13. Iterative Refinement  - Verification loop until confident
  14. Formatting & Output   - Format and present final answer

Two modes: Full (all steps) and Quick (skips 6-11).
"""

import argparse
import sys

from skills.lib.workflow.prompts import format_step, roster_dispatch


# ============================================================================
# SHARED PROMPTS
# ============================================================================

DISPATCH_CONTEXT = """\
Each sub-agent receives:
- CLARIFIED QUESTION from Step 1
- DOMAIN and FIRST PRINCIPLES from Step 2
- QUESTION TYPE and EVALUATION CRITERIA from Step 3
- KEY ANALOGIES from Step 4
- Their specific task definition from Step 8

AGENT PROMPT STRUCTURE (use for each agent's Task tool prompt):

Explore this question from the assigned perspective.

CLARIFIED QUESTION: [from Step 1]
DOMAIN: [from Step 2]
FIRST PRINCIPLES: [from Step 2]
QUESTION TYPE: [from Step 3]
EVALUATION CRITERIA: [from Step 3]
KEY ANALOGIES: [from Step 4]

YOUR TASK:
- Name: [agent name from Step 8]
- Strategy: [strategy from Step 8]
- Task: [task description from Step 8]
- Sub-Questions: [assigned questions from Step 8]"""

DISPATCH_AGENTS = [
    "[Agent 1: Fill from FINAL SUB-AGENT DEFINITIONS in Step 8]",
    "[Agent 2: Fill from FINAL SUB-AGENT DEFINITIONS in Step 8]",
    "[Agent N: Fill from FINAL SUB-AGENT DEFINITIONS in Step 8]",
]


# ============================================================================
# CONFIGURATION
# ============================================================================

MODULE_PATH = "skills.deepthink.think"
SUBAGENT_MODULE_PATH = "skills.deepthink.subagent"
MAX_ITERATIONS = 5


# ============================================================================
# MESSAGE TEMPLATES
# ============================================================================

# --- STEP 1: CONTEXT_CLARIFICATION ------------------------------------------

CONTEXT_CLARIFICATION_INSTRUCTIONS = """\
You are an expert analytical reasoner tasked with systematic deep analysis.

PART 0 - CONTEXT SUFFICIENCY:
  Before analyzing, assess whether you have sufficient context:

  A. EXISTING CONTEXT: What relevant information is already in this conversation?
     (prior codebase analysis, problem discoveries, architecture understanding)

  B. SUFFICIENCY JUDGMENT: For this question, is existing context:
     - SUFFICIENT: Can reason directly from available information
     - PARTIAL: Have some context but need targeted exploration
     - INSUFFICIENT: Need exploration before meaningful reasoning

  C. IF NOT SUFFICIENT: Before proceeding to Part A, explore:
     - Use Read/Glob/Grep tools to gather necessary context
     - Focus on specific files/patterns relevant to the question
     - Stop exploring when you have enough to reason -- avoid over-exploration
     - Document what you found in a brief EXPLORATION SUMMARY

  If context is SUFFICIENT, proceed directly to Part A.

Extract objective, relevant content from the user's question.

Read the question again before proceeding.

Separate it from framing, opinion, or irrelevant information.

PART A - CLARIFIED QUESTION:
  Restate the core question in neutral, objective terms.
  Remove leading language, embedded opinions, or assumptions.
  If multiple sub-questions exist, list them clearly.

PART B - EXTRACTED CONTEXT:
  List factual context from input relevant to answering.
  Exclude opinions, preferences, or irrelevant details.

PART C - NOTED BIASES:
  Identify framing effects, leading language, or embedded assumptions.
  Note these so subsequent steps can guard against them.
  If none detected, state 'No significant biases detected.'

OUTPUT FORMAT:
```
CLARIFIED QUESTION:
[neutral restatement]

EXTRACTED CONTEXT:
- [fact 1]
- [fact 2]

NOTED BIASES:
- [bias 1] or 'No significant biases detected.'
```

The CLARIFIED QUESTION will be used as the working question for all subsequent steps."""

# --- STEP 2: ABSTRACTION ----------------------------------------------------

ABSTRACTION_INSTRUCTIONS = """\
Before diving into specifics, step back and identify high-level context.
Work through this thoroughly. Avoid shortcuts. Show reasoning step by step.

PART A - DOMAIN:
  What field or domain does this question primarily belong to?
  Are there adjacent domains that might offer relevant perspectives?

PART B - FIRST PRINCIPLES:
  What fundamental principles should guide any answer?
  What would an expert consider non-negotiable constraints or truths?

PART C - KEY CONCEPTS:
  What core concepts must be understood to answer well?
  Define any terms that might be ambiguous or contested.

PART D - WHAT MAKES THIS HARD:
  Why isn't the answer obvious? What makes this genuinely difficult?
  Is it contested? Under-specified? Trade-off-laden? Novel?

OUTPUT FORMAT:
```
DOMAIN: [primary domain]
ADJACENT DOMAINS: [list]

FIRST PRINCIPLES:
- [principle 1]
- [principle 2]

KEY CONCEPTS:
- [concept]: [definition if ambiguous]

DIFFICULTY ANALYSIS:
[why this is hard]

ASSUMPTIONS:
- [statement] | TYPE: [BLOCKING/MATERIAL/DEFAULT] | VERIFIED: [yes/no/needs-user]
```

PART E - ASSUMPTIONS:
  Identify assumptions about problem scope, interpretation, or constraints.
  For EACH assumption:

  1. STATEMENT: What is being assumed
  2. TYPE: Classify using this decision tree:
     - Is analysis MEANINGLESS without resolving this? -> BLOCKING
     - Would the CONCLUSION change significantly if wrong? -> MATERIAL
     - Is this a REASONABLE DEFAULT most users would accept? -> DEFAULT

  3. VERIFICATION: Can tools confirm this?
     If verifiable: Use Read/Glob/Grep NOW. Document result.
     If not verifiable: Note 'needs user input'

  <assumption_examples>
  BLOCKING: 'Which codebase?' (cannot proceed without answer)
  MATERIAL: 'Assuming Python 3.9+' (affects implementation choices)
  DEFAULT:  'Standard library conventions' (reasonable, override later)
  </assumption_examples>

  <blocking_action>
  If ANY assumption is BLOCKING and unverifiable:
  Use AskUserQuestion IMMEDIATELY with:
    - question: Clear question about the blocking assumption
    - header: Short label (max 12 chars)
    - options: 2-4 choices (likely default first with '(Recommended)')
  DO NOT proceed to Step 3 until resolved.
  </blocking_action>

  Accumulate MATERIAL assumptions for checkpoint in Step 5.
  State DEFAULT assumptions explicitly but proceed."""

# --- STEP 3: CHARACTERIZATION -----------------------------------------------

CHARACTERIZATION_INSTRUCTIONS = """\
Classify this question to determine appropriate analysis approach.

PART A - QUESTION TYPE:
  Classify as one of:
  - TAXONOMY/CLASSIFICATION: Seeking a way to organize or categorize
  - TRADE-OFF ANALYSIS: Seeking to understand competing concerns
  - DEFINITIONAL: Seeking to clarify meaning or boundaries
  - EVALUATIVE: Seeking judgment on quality, correctness, fitness
  - EXPLORATORY: Seeking to understand a space of possibilities

PART B - ANSWER STRUCTURE:
  Based on question type, what structure should the final answer take?
  (e.g., 'proposed taxonomy with rationale' or 'decision framework')

PART C - EVALUATION CRITERIA:
  How should we judge whether an answer is good?
  What distinguishes excellent from mediocre?
  List 3-5 specific criteria.

PART D - MODE DETERMINATION:
  Should this use FULL mode (with sub-agents) or QUICK mode (direct synthesis)?

  Use QUICK mode if ALL true:
  - Relatively narrow scope
  - Single analytical perspective likely sufficient
  - No significant trade-offs between competing values
  - High confidence in what a good answer looks like

  Otherwise, use FULL mode.

OUTPUT FORMAT:
```
QUESTION TYPE: [type]

ANSWER STRUCTURE: [description]

EVALUATION CRITERIA:
1. [criterion 1]
2. [criterion 2]
...

MODE: [FULL | QUICK]
RATIONALE: [why this mode]
```"""

# --- STEP 4: ANALOGICAL_RECALL ----------------------------------------------

ANALOGICAL_RECALL_INSTRUCTIONS = """\
Recall similar problems that might inform this analysis.
Work through thoroughly. Consider multiple analogies before selecting.

PART A - DIRECT ANALOGIES:
  What similar problems in the same domain have been addressed?
  How were they approached? What worked and what didn't?

PART B - CROSS-DOMAIN ANALOGIES:
  What problems in OTHER domains share structural similarity?
  What can we learn from how those were solved?

PART C - ANTI-PATTERNS:
  What are known bad approaches to problems like this?
  What mistakes do people commonly make?

PART D - ANALOGICAL INSIGHTS:
  What specific insights from these analogies should inform our approach?
  Which analogies are most relevant and why?

OUTPUT FORMAT:
```
DIRECT ANALOGIES:
- [analogy 1]: [lesson]

CROSS-DOMAIN ANALOGIES:
- [domain]: [problem]: [insight]

ANTI-PATTERNS:
- [bad approach]: [why it fails]

KEY INSIGHTS:
- [insight to apply]
```"""

# --- STEP 5: PLANNING -------------------------------------------------------

PLANNING_INSTRUCTIONS = """\
Devise a plan for analyzing this question.

PART A - SUB-QUESTIONS:
  Break into sub-questions that collectively address the main question.
  Each sub-question should be:
  - Specific enough to analyze
  - Distinct from other sub-questions
  - Necessary (not just nice-to-have)

PART B - SUCCESS CRITERIA:
  What would a successful analysis look like?
  How will we know when we've done enough exploration?

PART C - SYNTHESIS CRITERIA:
  When multiple perspectives provide different answers, how resolve?
  What principles should guide synthesis?

PART D - ANTICIPATED CHALLENGES:
  What aspects will be hardest to address?
  Where do you expect disagreement or uncertainty?

OUTPUT FORMAT:
```
SUB-QUESTIONS:
1. [question 1]
2. [question 2]
...

SUCCESS CRITERIA:
- [criterion]

SYNTHESIS CRITERIA:
- [principle for resolving disagreement]

ANTICIPATED CHALLENGES:
- [challenge]

ASSUMPTION CHECKPOINT:
Verified: [tool-confirmed assumptions]
User-confirmed: [AskUserQuestion responses]
Defaults: [stated assumptions, no explicit confirmation]
```

PART E - ASSUMPTION CHECKPOINT:
  Before analysis, resolve accumulated assumptions from Steps 1-5.

  VERIFICATION PASS:
  For each MATERIAL assumption:
  1. Attempt tool-based verification:
     - Codebase: Glob/Grep/Read for evidence
     - Documentation: README, config files, existing implementations
     - Conversation: Re-scan for user statements that resolve it
  2. Document: ASSUMPTION | METHOD | RESULT (verified/refuted/inconclusive)

  <verification_example>
  ASSUMPTION: 'Target is Python 3.9+'
  METHOD: Read pyproject.toml
  RESULT: Verified - python = '^3.9'
  </verification_example>

  UNRESOLVED MATERIAL ASSUMPTIONS:
  If MATERIAL assumptions remain unverified after tool verification:

  <material_batch_action>
  Batch into AskUserQuestion (max 4 questions):
    questions: [
      {
        question: 'What is [specific assumption]?',
        header: '[short label]',
        options: [
          {label: '[default] (Recommended)', description: '[why reasonable]'},
          {label: '[alternative]', description: '[when to choose]'}
        ],
        multiSelect: false
      }
    ]
  Wait for response before proceeding.
  If >4 unresolved: prioritize by impact, carry rest as stated defaults.
  </material_batch_action>

  CARRYING FORWARD:
  List all assumptions entering analysis phase:
  - VERIFIED: [tool-confirmed]
  - USER-CONFIRMED: [from AskUserQuestion]
  - DEFAULTS: [stated, no explicit confirmation needed]"""

# --- STEP 6: SUBAGENT_DESIGN ------------------------------------------------

SUBAGENT_DESIGN_INSTRUCTIONS = """\
Design sub-agents to explore this question from different angles.

HOW SUB-AGENTS WORK:
  - All launch simultaneously (parallel execution)
  - Each receives the same inputs: original question + shared context
  - Each produces independent output returned to you for aggregation
  - Sub-agents cannot see or build on each other's work

Your task: design WHAT each sub-agent analyzes, knowing they work in isolation.

You have complete freedom in how you divide the analytical work.

DIVISION STRATEGIES:

You may divide analytical work using any of these (or combinations):

  By Perspective/Lens
    Different epistemological viewpoints examining the same problem.
    A skeptic examines assuming the obvious answer is wrong;
    an optimist examines assuming success is achievable.

  By Role/Stakeholder
    Who has skin in the game? Different priorities and constraints.

  By Dimension/Facet
    Multiple orthogonal aspects that can be analyzed independently.

  By Methodology/Approach
    Different analytical frameworks applied to the same question.

  By Scope/Scale
    Micro, meso, macro. Problems look different at different scales.

  By Time Horizon
    Short-term vs long-term. Tactical vs strategic.

  By Hypothesis
    Assign sub-agents to steelman competing hypotheses.

  By Facet
    Identify independent aspects analyzable without depending on
    each other's conclusions.

You may combine strategies.

For each sub-agent, specify:
  1. NAME: Short descriptive name
  2. DIVISION STRATEGY: Which strategy this represents
  3. TASK DESCRIPTION: What specifically to analyze
  4. ASSIGNED SUB-QUESTIONS: Which sub-questions to address
  5. UNIQUE VALUE: Why this will produce insights others won't

OUTPUT FORMAT:
```
SUB-AGENT 1:
- Name: [name]
- Strategy: [strategy]
- Task: [description]
- Sub-Questions: [list]
- Unique Value: [why this matters]

SUB-AGENT 2:
[etc.]

DIVISION RATIONALE:
[why this particular division]
```"""

# --- STEP 7: DESIGN_CRITIQUE ------------------------------------------------

DESIGN_CRITIQUE_INSTRUCTIONS = """\
Critically evaluate the sub-agent design from Step 6.

PART A - COVERAGE:
  Do sub-agents collectively cover all sub-questions from Step 5?
  Are there important angles NO sub-agent will address?
  List any gaps.

PART B - OVERLAP:
  Do any sub-agents duplicate work unnecessarily?
  Is there productive tension vs wasteful redundancy?
  List any problematic overlaps.

PART C - APPROPRIATENESS:
  Is division strategy well-suited to this question?
  Would a different strategy yield better insights?
  Are task descriptions clear enough to execute?

PART D - BALANCE:
  Are some sub-agents given much harder tasks than others?
  Is there risk one sub-agent will dominate synthesis?

PART E - SPECIFIC ISSUES:
  List specific problems with individual sub-agent definitions.
  For each issue, be specific about what's wrong.

Be genuinely critical. Goal is to improve, not approve.

OUTPUT FORMAT:
```
COVERAGE:
- Gaps: [list or 'none']

OVERLAP:
- Issues: [list or 'none']

APPROPRIATENESS:
- Assessment: [evaluation]

BALANCE:
- Assessment: [evaluation]

SPECIFIC ISSUES:
- [issue 1]
- [issue 2]
```"""

# --- STEP 8: DESIGN_REVISION ------------------------------------------------

DESIGN_REVISION_INSTRUCTIONS = """\
Revise sub-agent design based on critique from Step 7.

For each issue identified, either:
  1. Revise the design to address it, OR
  2. Explain why the issue should not be addressed

OUTPUT FORMAT:
```
REVISIONS MADE:
- [change]: [which critique point it addresses]

ISSUES NOT ADDRESSED:
- [critique point]: [why not addressing]

FINAL SUB-AGENT DEFINITIONS:

SUB-AGENT 1:
- Name: [name]
- Strategy: [strategy]
- Task: [description]
- Sub-Questions: [list]
- Unique Value: [why this matters]

[etc.]
```

These definitions will be used to dispatch sub-agents in Step 9."""

# --- STEP 9: DISPATCH -------------------------------------------------------
# Uses DISPATCH_CONTEXT and DISPATCH_AGENTS from SHARED PROMPTS section

# --- STEP 10: QUALITY_GATE --------------------------------------------------

QUALITY_GATE_INSTRUCTIONS = """\
Review each sub-agent's output. Assess whether to include in aggregation.

For each sub-agent output, assess:
  1. COHERENCE: Is reasoning internally consistent?
  2. RELEVANCE: Does it actually address its assigned task?
  3. SUBSTANTIVENESS: Genuine insights, not just surface observations?
  4. FAILURE MODE COMPLETENESS: Did it identify meaningful weaknesses?

RATING SCALE:
  - PASS: Include fully in aggregation
  - PARTIAL: Include with noted reservations
  - FAIL: Exclude from aggregation (with explanation)

OUTPUT FORMAT:
```
SUB-AGENT 1 ([name]):
- Coherence: [assessment]
- Relevance: [assessment]
- Substantiveness: [assessment]
- Failure Modes: [assessment]
- RATING: [PASS/PARTIAL/FAIL]
- Notes: [observations]

[repeat for each]

SUMMARY:
- Passing: [list]
- Partial: [list]
- Failed: [list]
- Coverage assessment: [are critical angles missing due to failures?]
```"""

# --- STEP 11: AGGREGATION ---------------------------------------------------

AGGREGATION_INSTRUCTIONS = """\
Organize findings from all sub-agents that passed quality gate.

PART A - AGREEMENT MAP:
  What do multiple sub-agents agree on?
  List points of convergence with which sub-agents support each.

PART B - DISAGREEMENT MAP:
  Where do sub-agents disagree?
  For each: point of contention, competing positions, reasoning.

PART B2 - CONFLICT RESOLUTION (for synthesis):
  For each disagreement, note which position has:
  - More sub-agent support (majority)
  - Stronger evidence grounding
  - Better alignment with first principles from Step 2
  Flag unresolvable conflicts explicitly.

PART C - UNIQUE CONTRIBUTIONS:
  What valuable insights appeared in only ONE sub-agent?
  Why might others have missed this?

PART D - INTERMEDIATE INSIGHTS:
  Review reasoning chains of ALL sub-agents (including PARTIAL).
  Extract intermediate observations valuable independent of conclusions.
  These inform synthesis even if overall analysis not adopted.

PART E - FAILURE MODE CATALOG:
  Aggregate all anticipated failure modes identified by sub-agents.
  Group by theme.

PART F - SUB-QUESTION COVERAGE:
  For each sub-question from Step 5, summarize responses.
  Flag any with weak or no coverage.

Preserve all disagreements exactly as found. Record positions without evaluation.
This step is purely organizational.

OUTPUT FORMAT:
```
AGREEMENT MAP:
- [point]: supported by [sub-agents]

DISAGREEMENT MAP:
- [contention]: [position A] vs [position B]

UNIQUE CONTRIBUTIONS:
- [sub-agent]: [insight]

INTERMEDIATE INSIGHTS:
- [insight from reasoning, not conclusion]

FAILURE MODE CATALOG:
- [theme]: [modes]

SUB-QUESTION COVERAGE:
- Q1: [coverage summary]
```"""

# --- STEP 12: INITIAL_SYNTHESIS ---------------------------------------------

SYNTHESIS_FULL_INSTRUCTIONS = """\
Integrate aggregated findings into a coherent response.
Hint: Prioritize aspects matching the EVALUATION CRITERIA from Step 3.
Work through thoroughly. Avoid shortcuts. Show reasoning step by step.

SYNTHESIS GUIDELINES:
  1. Use evaluation criteria from Step 3 to guide integration
  2. Resolve disagreements using synthesis criteria from Step 5
  3. Draw on intermediate insights from Step 11, not just conclusions
  4. Acknowledge where genuine uncertainty remains
  5. Do not artificially harmonize positions that genuinely conflict

PART A - CORE ANSWER:
  What is your integrated response to the original question?
  Structure appropriately for the question type from Step 3.

PART B - KEY TRADE-OFFS:
  What trade-offs are inherent in this answer?
  What did you prioritize, and what did you deprioritize?

PART C - DISSENTING VIEWS:
  Where did you override a sub-agent's position?
  Why not adopted, and what would change your mind?

PART D - EVIDENCE GROUNDING:
  For each major claim, cite the evidence source:
  - From Step 2 (first principles)
  - From Step 4 (analogies)
  - From Step 11 (sub-agent findings or intermediate insights)
  Claims without grounding: flag as UNGROUNDED.

PART E - ACKNOWLEDGED LIMITATIONS:
  What aspects does this synthesis NOT address well?
  What additional information would strengthen the analysis?

PART F - CONFIDENCE MARKERS:
  Mark claims as:
  - HIGH: Strong agreement, multiple sources
  - MEDIUM: Reasonable but contested or single source
  - LOW: Speculative or limited evidence

OUTPUT FORMAT:
```
CORE ANSWER:
[structured response]

KEY TRADE-OFFS:
- Prioritized: [X] over [Y] because [reason]

DISSENTING VIEWS:
- [sub-agent]: [position not adopted]: [why]

EVIDENCE GROUNDING:
- [claim]: [source]
- UNGROUNDED: [list any ungrounded claims]

LIMITATIONS:
- [limitation]

CONFIDENCE: [overall assessment]
```

This synthesis will be evaluated in Step 13. Expect to refine it."""

SYNTHESIS_QUICK_INSTRUCTIONS = """\
Based on abstraction (Step 2) and analogies (Step 4), synthesize response.
Hint: Prioritize aspects matching the EVALUATION CRITERIA from Step 3.
Work through thoroughly. Avoid shortcuts. Show reasoning step by step.

PART A - CORE ANSWER:
  What is your response to the original question?
  Ground in first principles from Step 2 and analogies from Step 4.

PART B - EVIDENCE GROUNDING:
  For each major claim, cite source:
  - First principles (Step 2)
  - Analogical reasoning (Step 4)
  - Domain knowledge
  Claims without grounding: flag as UNGROUNDED.

PART C - ACKNOWLEDGED LIMITATIONS:
  What aspects does this NOT address well?
  Where might alternative perspectives yield different conclusions?

PART D - CONFIDENCE MARKERS:
  Mark claims as HIGH, MEDIUM, or LOW confidence with brief justification.

OUTPUT FORMAT:
```
CORE ANSWER:
[structured response]

EVIDENCE GROUNDING:
- [claim]: [source]
- UNGROUNDED: [list any]

LIMITATIONS:
- [limitation]

CONFIDENCE: [overall assessment]
```

This synthesis will be evaluated in Step 13."""

# --- STEP 13: ITERATIVE_REFINEMENT ------------------------------------------

REFINEMENT_INSTRUCTIONS = """\
ITERATION {iteration} OF {max_iter}

RULE 0 (MANDATORY): Follow the invoke_after command. Do NOT skip
to step 14 unless confidence is CERTAIN or this is iteration 5.

Critically evaluate the current synthesis.
Work through thoroughly -- avoid quick 'looks good' assessments.

PART A - VERIFICATION QUESTION GENERATION:
  Generate 3-5 verification questions that would test correctness.
  Use OPEN questions ('What is X?', 'Where does Y occur?'), not yes/no.
  Yes/no questions bias toward agreement regardless of correctness.
  Focus on:
  - Claims marked LOW or MEDIUM confidence
  - Any UNGROUNDED claims from Step 12
  - Potential blind spots
  - Failure modes that could invalidate key proposals
  - Edge cases the synthesis might not handle

PART B - INDEPENDENT VERIFICATION:
  For each verification question, answer based ONLY on:
  - First principles from Step 2
  - Analogies from Step 4
  - Aggregated evidence from Step 11 (if Full mode)

  CRITICAL: Do NOT look at the synthesis while answering.
  Answer based on evidence, not what the synthesis claims.

  EXPLORATION OPTION:
  If a verification question cannot be answered with existing evidence:
  - Use Read/Glob/Grep to find concrete evidence in the codebase
  - This is especially valuable for UNGROUNDED claims from Step 12
  - Keep exploration bounded -- answer the specific question, then stop
  - Update answer with exploration findings and cite sources

PART C - DISCREPANCY IDENTIFICATION:
  Compare verification answers against current synthesis.
  Where do they differ?
  List each discrepancy.

PART D - ACTIONABLE FEEDBACK:
  For each discrepancy or issue, provide feedback.

  Each piece of feedback MUST include all three elements:
    1. ELEMENT: Name the specific claim, section, or aspect
    2. PROBLEM: State precisely what is wrong or unsupported
    3. ACTION: Propose a concrete fix or revision

  Feedback missing any element should be discarded as too vague.

  GOOD: 'ELEMENT: claim X. PROBLEM: contradicts evidence Y. ACTION: qualify with Z.'
  BAD: 'The analysis could be stronger.' (no specific element/problem/action)

PART E - SYNTHESIS UPDATE:
  Review feedback from ALL previous iterations (if any).
  Based on actionable feedback, revise the synthesis.
  Avoid repeating mistakes identified in prior iterations.
  For each revision, note which feedback item it addresses.

PART F - CONFIDENCE ASSESSMENT:
  After revisions, assess confidence:
  - EXPLORING: Still developing understanding
  - LOW: Significant gaps or unresolved issues
  - MEDIUM: Reasonable answer but some uncertainty
  - HIGH: Strong answer, minor refinements possible
  - CERTAIN: As good as it can get with available information

  Provide specific justification for confidence level.

<iteration_gate>
CRITICAL: You MUST follow the invoke_after command exactly.

EXIT CONDITIONS (both required to proceed to step 14):
  1. Confidence = CERTAIN, OR
  2. This is iteration 5 (final iteration)

If NEITHER condition is met, STOP.
Do NOT proceed to step 14. Continue to the next iteration.
</iteration_gate>

OUTPUT FORMAT:
```
VERIFICATION QUESTIONS:
1. [question]

INDEPENDENT ANSWERS:
1. [answer without looking at synthesis]

DISCREPANCIES:
- [where synthesis differs from verification]

ACTIONABLE FEEDBACK:
- ELEMENT: [what]. PROBLEM: [why wrong]. ACTION: [fix]

REVISED SYNTHESIS:
[updated synthesis]

CONFIDENCE: [level]
JUSTIFICATION: [why this level]
```"""

# --- STEP 14: FORMATTING_OUTPUT ---------------------------------------------

FORMATTING_INSTRUCTIONS = """\
Refinement complete. Confidence: {confidence}.

Present the final answer to the user.

FORMATTING REQUIREMENTS:
  - Lead with the direct answer to the original question
  - Use the answer structure determined in Step 3
  - Integrate key trade-offs naturally into the explanation
  - Note limitations only where they materially affect the answer
  - Omit workflow artifacts (step references, sub-agent names, etc.)

CONFIDENCE: {confidence_guidance}

OUTPUT: Clean prose response directly addressing the user's question.
        No meta-commentary about the analysis process."""


# ============================================================================
# MESSAGE BUILDERS
# ============================================================================


def build_dispatch_body() -> str:
    """Build DISPATCH instructions with roster_dispatch()."""
    invoke_cmd = f'python3 -m {SUBAGENT_MODULE_PATH} --step 1'

    dispatch_text = roster_dispatch(
        agent_type="general-purpose",
        agents=DISPATCH_AGENTS,
        command=invoke_cmd,
        shared_context=DISPATCH_CONTEXT,
        model="sonnet",
        instruction="Launch ALL sub-agents from FINAL SUB-AGENT DEFINITIONS (Step 8). Use a SINGLE message with multiple Task tool calls.",
    )

    return dispatch_text


# ============================================================================
# STEP DEFINITIONS
# ============================================================================

# Static steps: (title, instructions) tuples for steps with constant content
STATIC_STEPS = {
    1: ("Context Clarification", CONTEXT_CLARIFICATION_INSTRUCTIONS),
    2: ("Abstraction", ABSTRACTION_INSTRUCTIONS),
    3: ("Characterization", CHARACTERIZATION_INSTRUCTIONS),
    4: ("Analogical Recall", ANALOGICAL_RECALL_INSTRUCTIONS),
    5: ("Planning", PLANNING_INSTRUCTIONS),
    6: ("Sub-Agent Design", SUBAGENT_DESIGN_INSTRUCTIONS),
    7: ("Design Critique", DESIGN_CRITIQUE_INSTRUCTIONS),
    8: ("Design Revision", DESIGN_REVISION_INSTRUCTIONS),
    10: ("Quality Gate", QUALITY_GATE_INSTRUCTIONS),
    11: ("Aggregation", AGGREGATION_INSTRUCTIONS),
}


def _format_step_9(mode: str, confidence: str, iteration: int) -> tuple[str, str]:
    """Step 9: Dispatch - builds dispatch body via roster_dispatch()."""
    return ("Dispatch", build_dispatch_body())


def _format_step_12(mode: str, confidence: str, iteration: int) -> tuple[str, str]:
    """Step 12: Initial Synthesis - selects instructions based on mode."""
    body = SYNTHESIS_FULL_INSTRUCTIONS if mode == "full" else SYNTHESIS_QUICK_INSTRUCTIONS
    return ("Initial Synthesis", body)


def _format_step_13(mode: str, confidence: str, iteration: int) -> tuple[str, str]:
    """Step 13: Iterative Refinement - parameterized title and body."""
    suffix = " -> Complete" if confidence == "certain" or iteration >= MAX_ITERATIONS else ""
    title = f"Iterative Refinement (Iteration {iteration}){suffix}"
    body = REFINEMENT_INSTRUCTIONS.format(iteration=iteration, max_iter=MAX_ITERATIONS)
    return (title, body)


def _format_step_14(mode: str, confidence: str, iteration: int) -> tuple[str, str]:
    """Step 14: Formatting & Output - parameterized with confidence guidance."""
    confidence_upper = confidence.upper()
    if confidence == "certain":
        guidance = "HIGH\n  Present with authority. Hedging language unnecessary."
    else:
        guidance = f"{confidence_upper}\n  Flag specific claims with lower confidence.\n  Indicate what additional information would strengthen the analysis."
    body = FORMATTING_INSTRUCTIONS.format(confidence=confidence_upper, confidence_guidance=guidance)
    return ("Formatting & Output", body)


# Dynamic steps: functions that compute (title, instructions) based on parameters
# Functions must be defined BEFORE this dictionary (book pattern)
DYNAMIC_STEPS = {
    9: _format_step_9,
    12: _format_step_12,
    13: _format_step_13,
    14: _format_step_14,
}


def build_next_command(step: int, mode: str, confidence: str, iteration: int) -> str | None:
    """Build invoke command for next step."""
    base = f'python3 -m {MODULE_PATH}'

    if step == 1:
        return f'{base} --step 2'
    elif step == 2:
        return f'{base} --step 3'
    elif step == 3:
        return f'{base} --step 4'
    elif step == 4:
        return f'{base} --step 5'
    elif step == 5:
        return f'If FULL: {base} --step 6 --mode full\nIf QUICK: {base} --step 12 --mode quick'
    elif step == 6:
        return f'{base} --step 7 --mode {mode}'
    elif step == 7:
        return f'{base} --step 8 --mode {mode}'
    elif step == 8:
        return f'{base} --step 9 --mode {mode}'
    elif step == 9:
        return f'{base} --step 10 --mode {mode}'
    elif step == 10:
        return f'{base} --step 11 --mode {mode}'
    elif step == 11:
        return f'{base} --step 12 --mode {mode}'
    elif step == 12:
        return f'{base} --step 13 --confidence <your_confidence> --iteration 1 --mode {mode}'
    elif step == 13:
        if confidence == "certain" or iteration >= MAX_ITERATIONS:
            return f'{base} --step 14 --confidence {confidence} --mode {mode}'
        else:
            return f'{base} --step 13 --confidence <your_confidence> --iteration {iteration + 1} --mode {mode}'
    elif step == 14:
        return None

    return None


# ============================================================================
# OUTPUT FORMATTING
# ============================================================================


def format_output(step: int, mode: str, confidence: str, iteration: int) -> str:
    """Format output for the given step.

    Uses callable dispatch: static steps lookup (title, instructions) from
    STATIC_STEPS dict; dynamic steps call formatter functions from DYNAMIC_STEPS.
    """
    if step in STATIC_STEPS:
        title, instructions = STATIC_STEPS[step]
    elif step in DYNAMIC_STEPS:
        formatter = DYNAMIC_STEPS[step]
        title, instructions = formatter(mode, confidence, iteration)
    else:
        return f"ERROR: Invalid step {step}"

    next_cmd = build_next_command(step, mode, confidence, iteration)
    return format_step(instructions, next_cmd or "", title=f"DEEPTHINK - {title}")


# ============================================================================
# ENTRY POINT
# ============================================================================


def main():
    """Entry point for deepthink workflow."""
    parser = argparse.ArgumentParser(
        description="DeepThink - Structured reasoning for open-ended analytical questions",
        epilog="Steps: 1-14 (Full mode) or 1-5,12-14 (Quick mode)",
    )
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument(
        "--confidence",
        type=str,
        choices=["exploring", "low", "medium", "high", "certain"],
        default="exploring",
        help="Confidence level (for Step 13)",
    )
    parser.add_argument(
        "--iteration",
        type=int,
        default=1,
        help="Current iteration within Step 13 (1-5)",
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["quick", "full"],
        default="full",
        help="Analysis mode (set in Step 3)",
    )
    args = parser.parse_args()

    if args.step < 1 or args.step > 14:
        sys.exit("ERROR: --step must be 1-14")

    print(format_output(args.step, args.mode, args.confidence, args.iteration))


if __name__ == "__main__":
    main()
