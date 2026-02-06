#!/usr/bin/env python3
"""
Prompt Engineer Skill - Scope-adaptive prompt optimization workflow.

Architecture:
  - Four Workflow instances (one per scope)
  - Shared action factories for reusable fragments
  - Entry point dispatches to appropriate workflow

Scopes:
  - single-prompt: One prompt file, general optimization
  - ecosystem: Multiple related prompts that interact
  - greenfield: No existing prompt, designing from requirements
  - problem: Existing prompt(s) with specific issue to fix

Research grounding:
  - Self-Refine (Madaan 2023): Separate feedback from refinement
  - CoVe (Dhuliawala 2023): Factored verification with OPEN questions
"""

import argparse
import sys
from typing import Annotated

from skills.lib.workflow.core import (
    Arg,
    StepDef,
    Workflow,
)
from skills.lib.workflow.ast import W, XMLRenderer, render, FileContentNode
from skills.lib.workflow.ast.nodes import (
    TextNode, StepHeaderNode, CurrentActionNode, InvokeAfterNode,
)
from skills.lib.workflow.ast.renderer import (
    render_step_header, render_current_action, render_invoke_after,
)
from pathlib import Path


# =============================================================================
# Category Constants and Loader Function
# =============================================================================

CATEGORY_TO_FILE = {
    "efficiency": "efficiency.md",
    "structure": "structure.md",
    "context/reframing": "context/reframing.md",
    "context/augmentation": "context/augmentation.md",
    "reasoning/decomposition": "reasoning/decomposition.md",
    "reasoning/elicitation": "reasoning/elicitation.md",
    "correctness/sampling": "correctness/sampling.md",
    "correctness/verification": "correctness/verification.md",
    "correctness/refinement": "correctness/refinement.md",
}


def get_references_dir() -> Path:
    """Return path to prompt-engineer/references/ directory.

    Path calculation:
      scripts/skills/prompt_engineer/optimize.py  (this file)
      scripts/skills/prompt_engineer/             parent
      scripts/skills/                             parent.parent
      scripts/                                    parent.parent.parent
      Then traverse to sibling: prompt-engineer/references/
    """
    script_dir = Path(__file__).parent
    return script_dir.parent.parent.parent / "prompt-engineer" / "references"


def load_category_files(categories: list[str]) -> list[FileContentNode]:
    """Load reference files for selected categories.

    Args:
        categories: List of category names (e.g., ['efficiency', 'reasoning/decomposition'])

    Returns:
        List of FileContentNode with loaded content

    Exits with error if category unknown or file missing.
    """
    refs_dir = get_references_dir()
    nodes = []

    for cat in categories:
        if cat not in CATEGORY_TO_FILE:
            valid = ", ".join(sorted(CATEGORY_TO_FILE.keys()))
            sys.exit(f"ERROR: Unknown category '{cat}'. Valid: {valid}")

        rel_path = CATEGORY_TO_FILE[cat]
        full_path = refs_dir / rel_path

        if not full_path.exists():
            sys.exit(f"ERROR: Reference file not found: {full_path}")

        content = full_path.read_text()
        display_path = f"references/{rel_path}"
        nodes.append(FileContentNode(path=display_path, content=content))

    return nodes


# =============================================================================
# Action Factory Functions
# =============================================================================


def technique_review_actions(for_ecosystem: bool = False) -> list[str]:
    """Systematic technique review - shared across scopes in Plan step."""
    base = [
        "SYSTEMATIC TECHNIQUE REVIEW:",
        "  For each technique in the Technique Selection Guide:",
        "  1. QUOTE the trigger condition from the table",
        "  2. QUOTE text from the target prompt that matches (or state 'No match')",
        "  3. Verdict: APPLICABLE (with both quotes) or NOT APPLICABLE",
        "  - Pay attention to 'Any task' triggers (foundational techniques)",
    ]
    if for_ecosystem:
        base.append("  - Note techniques that apply to multiple prompts")
    return base


def change_format_actions(entity: str = "CHANGE") -> list[str]:
    """Change format template - entity is CHANGE, FIX, or SECTION."""
    lines = [
        f"Format each {entity.lower()}:",
        f"  === {entity} N: [title] ===",
        "  Line: [numbers]",
        '  Technique: [name] | Trigger: "[quoted]" | Effect: [quoted]',
        "  BEFORE: [original]",
        "  AFTER: [modified]",
    ]
    if entity == "CHANGE":
        lines.append("  TRADEOFF: [downside or None]")
    return lines


def change_presentation_actions() -> list[str]:
    """Change presentation format for Execute steps - shows before/after for each change."""
    return [
        "PRESENT CHANGES MADE:",
        "",
        "For EACH change applied, show:",
        "  === CHANGE N: [title] ===",
        "  Location: [file:lines]",
        "  BEFORE:",
        "  ```",
        "  [original text]",
        "  ```",
        "  AFTER:",
        "  ```",
        "  [modified text]",
        "  ```",
        "",
        "Then present the complete modified prompt(s).",
    ]


def anti_pattern_audit_actions(
    target: str = "modified prompt",
    context: str | None = None,
) -> list[str]:
    """Anti-pattern audit - used in Execute step."""
    base = [
        f"ANTI-PATTERN FINAL AUDIT against {target}:",
        "",
        "Check each anti-pattern from the reference (including but not limited to):",
        "  [ ] Hedging Spiral: Does it encourage hesitation?",
        "  [ ] Everything-Is-Critical: Are emphasis markers overused?",
        "  [ ] Implicit Category Trap: Are categories explicit?",
        "  [ ] Negative Instruction Trap: Are directives affirmative?",
        "  [ ] (other anti-patterns from reference as applicable)",
    ]
    if context in ("SKILL", "SUB-AGENT", "COMPONENT"):
        base.extend([
            "",
            "CONTEXT-SPECIFIC (non-STANDALONE):",
            "  [ ] Context Mismatch: Does it have <system> or identity setup?",
            "      If YES -> FAIL: Remove wrapper/identity.",
        ])
    return base


def integration_check_actions(checks: list[str]) -> list[str]:
    """Integration checks wrapper."""
    return ["INTEGRATION CHECKS (verify at minimum):"] + [f"  - {c}" for c in checks]


def ecosystem_relationship_table() -> list[str]:
    """Ecosystem-only: map cross-prompt relationships."""
    return [
        "Create interaction table:",
        "  | Prompt | File:Lines | Receives From | Sends To | Shared Terms |",
        "  |--------|------------|---------------|----------|--------------|",
        "",
        "For each prompt, identify (at minimum):",
        "  - Input sources (which prompts/systems feed it)",
        "  - Output consumers (which prompts/systems consume its output)",
        "  - Terminology that MUST be consistent across prompts",
    ]


def context_gathering_actions() -> list[str]:
    """Context gathering for technique selection.

    Produces structured output that category_selection_actions references.
    Prompts for user confirmation when genuinely uncertain.
    """
    return [
        "",
        "CONTEXT GATHERING (before category selection):",
        "",
        "First, gather context from available sources:",
        "  - Files already read in this conversation",
        "  - Prior analysis or problem descriptions",
        "  - Standard patterns you recognize",
        "",
        "FOR MULTIPLE RELATED PROMPTS:",
        "  <system_goal>",
        "    What is the HIGH-LEVEL goal of this prompt system?",
        "    What end-to-end workflow do these prompts enable?",
        "  </system_goal>",
        "  Then for EACH prompt, derive its purpose FROM the system goal.",
        "",
        "FOR A SINGLE PROMPT:",
        "  <prompt_purpose>",
        "    What problem does this prompt solve?",
        "    What inputs/outputs define its contract?",
        "    What does success look like?",
        "  </prompt_purpose>",
        "",
        "<observed_issues>",
        "  Map current/anticipated issues to categories:",
        "  - Reasoning: [skips steps, wrong decomposition, no visible trace]",
        "  - Consistency: [different outputs each run]",
        "  - Accuracy: [wrong facts, hallucinations]",
        "  - Context: [ignores input, distracted by noise]",
        "  - Format: [wrong structure, unparseable]",
        "  State 'None observed' for categories without issues.",
        "</observed_issues>",
        "",
        "WHEN TO ASK FOR CLARIFICATION:",
        "  - If the high-level goal is unclear from available context",
        "  - If you're uncertain which issues are actually occurring",
        "  - If success criteria are ambiguous",
        "  Use AskUserQuestion when genuinely uncertain -- not for standard patterns.",
        "  Better to confirm than to optimize the wrong thing.",
    ]


def understand_actions_ecosystem() -> list[str]:
    """Semantic understanding phase for ecosystem scope."""
    return [
        "ARTICULATE semantic understanding before optimization.",
        "",
        "<system_understanding>",
        "  What is this workflow accomplishing end-to-end?",
        "  What enters the system? What does it produce?",
        "  What invariants must be maintained across components?",
        "</system_understanding>",
        "",
        "<prompt_understanding>",
        "  For EACH prompt, answer:",
        "  - What does this prompt ACCOMPLISH (purpose, not description)?",
        "  - Why is it positioned HERE in the sequence?",
        "  - What would BREAK if this prompt were removed?",
        "</prompt_understanding>",
        "",
        "<handoff_understanding>",
        "  For EACH delegation (A -> B), answer:",
        "  - What is B's BOUNDED responsibility? (specific task, not 'help')",
        "  - What is the MINIMUM information B needs to accomplish that?",
        "  - What does B ALREADY KNOW from its own context?",
        "  - What must NOT cross this boundary? Why?",
        "    (orchestrator internals, workflow steps, other components' state)",
        "</handoff_understanding>",
        "",
        "INVERT THE DEFAULT QUESTION:",
        "  Ask 'what is the MINIMUM B needs?' not 'what might help B?'",
        "",
        "CONTRASTIVE EXAMPLES:",
        "",
        "<example type='CORRECT'>",
        "  SKILL.md: 'Invoke the script. The script IS the workflow.'",
        "  WHY: Main agent delegates completely. No internals exposed.",
        "</example>",
        "<example type='INCORRECT'>",
        "  SKILL.md: 'Invoke the script. It has 6 steps: 1. Triage...'",
        "  WHY: Main agent doesn't need workflow internals.",
        "</example>",
        "",
        "<example type='CORRECT'>",
        "  Sub-agent: 'Execute step 1. <invoke cmd=\"...--step 1\" />'",
        "  WHY: Sub-agent needs only its step instructions.",
        "</example>",
        "<example type='INCORRECT'>",
        "  Sub-agent: 'Execute step 1. There are 8 steps: 1. Context...'",
        "  WHY: Sub-agent discovers workflow during execution. Overview is noise.",
        "</example>",
        *context_gathering_actions(),
    ]


def verify_understanding_actions() -> list[str]:
    """Counterfactual verification of understanding claims."""
    return [
        "TEST understanding with counterfactual questions (OPEN, not yes/no).",
        "",
        "For EACH handoff (A -> B):",
        "  Q: DESCRIBE what could be REMOVED from this handoff without breaking B.",
        "  A: [list specific items currently included but not necessary]",
        "",
        "  Q: EXPLAIN what would fail and HOW if we added orchestrator internals",
        "     (workflow steps, state, other components) to this handoff.",
        "  A: [describe mechanism: confusion, coupling, scope creep, etc.]",
        "",
        "For the ECOSYSTEM:",
        "  Q: If component X were removed, WHICH components break and WHY?",
        "  A: [trace dependencies based on your understanding]",
        "",
        "CONSISTENCY CHECK:",
        "  Compare answers to <handoff_understanding>.",
        "  Revise understanding if inconsistent.",
    ]


def understand_actions_simple() -> list[str]:
    """Semantic understanding for single-prompt/problem scopes."""
    return [
        "ARTICULATE what this prompt accomplishes:",
        "",
        "<purpose>",
        "  What is the high-level goal of this prompt?",
        "  What inputs does it expect?",
        "  What outputs should it produce?",
        "  What does SUCCESS look like?",
        "</purpose>",
        "",
        "<boundaries>",
        "  If this prompt delegates to sub-agents or other components:",
        "  - What is each recipient's bounded responsibility?",
        "  - What is the MINIMUM each recipient needs?",
        "  - What should NOT be passed to recipients? Why?",
        "  If no delegation exists, state: 'No delegation boundaries.'",
        "</boundaries>",
        *context_gathering_actions(),
    ]


def compression_guide_framing() -> list[str]:
    """Framing for how to interpret the compression guide.

    The compression guide operates at the OUTPUT level -- it contains techniques
    to embed in prompts that cause the target LLM to produce fewer tokens.
    Without this framing, LLMs pattern-match compression techniques to whatever
    text is salient, often applying them incorrectly to code structure or
    prompt text itself.
    """
    return [
        "",
        "CRITICAL - How to interpret the compression guide:",
        "  The compression guide reduces OUTPUT tokens from the TARGET LLM --",
        "  the LLM that will eventually READ the prompt you're optimizing,",
        "  NOT the LLM (you) currently doing the optimization.",
        "",
        "  These are techniques to EMBED in prompts. When the guide says",
        "  'keep each step to 5 words', that instruction goes INTO the prompt",
        "  you're creating, so the target LLM responds concisely.",
        "",
        "  FORBIDDEN:",
        "    - Refactoring code structure (extracting to variables, consolidating",
        "      templates). Source code structure does NOT affect token count.",
        "    - Shortening the prompt text itself unless user explicitly requests.",
        "",
        "  CORRECT: Look for opportunities to add output-controlling instructions",
        "  like response format constraints, per-step word limits, or MARP patterns.",
        "",
    ]


def handoff_minimalism_test() -> list[str]:
    """Test for handoff minimalism in PLAN phase."""
    return [
        "  - For each handoff: is it MINIMAL?",
        "    REJECT changes that add information the receiver doesn't need.",
        "    REJECT changes that leak orchestrator internals.",
        "",
        "  HANDOFF MINIMALISM TEST for each proposed change:",
        "    Ask: 'Would the receiver need to change if this internal changed?'",
        "    NO -> creates coupling without benefit -> EXCLUDE",
        "    YES -> necessary information -> INCLUDE",
    ]


def category_selection_actions() -> list[str]:
    """Instructions for LLM to select technique categories.

    This function is called when the LLM needs to choose which reference
    files to inject. The output format (SELECTED: x,y,z) is designed to
    be easily copied into the --categories argument.

    Framing inverts the burden: exclusions require justification, not inclusions.
    Minimum 3 categories prevents narrow selection bias.
    """
    return [
        "SELECT TECHNIQUE CATEGORIES based on your context gathering.",
        "",
        "Use your <system_goal> or <prompt_purpose> and <observed_issues>",
        "to inform selection. The issue-to-category mapping:",
        "  - Reasoning issues -> reasoning/decomposition, reasoning/elicitation",
        "  - Consistency issues -> correctness/sampling",
        "  - Accuracy issues -> correctness/verification, correctness/refinement",
        "  - Context issues -> context/reframing, context/augmentation",
        "  - Format issues -> structure",
        "",
        "If you have unresolved uncertainty about the goal or issues,",
        "use AskUserQuestion before proceeding.",
        "",
        "Available categories:",
        "",
        "  MANDATORY:",
        "    efficiency -- Output compression (applies to ALL prompts)",
        "",
        "  INCLUDE ALL THAT APPLY (minimum 3 total):",
        "",
        "    Reasoning quality:",
        "      reasoning/decomposition -- Multi-step, compositional problems",
        "      reasoning/elicitation -- Model skips steps, no visible trace",
        "",
        "    Output correctness:",
        "      correctness/sampling -- Inconsistent outputs across runs",
        "      correctness/verification -- Factual errors, hallucination",
        "      correctness/refinement -- Benefits from iteration",
        "",
        "    Input/context:",
        "      context/reframing -- Poorly framed, ambiguous instructions",
        "      context/augmentation -- Missing domain knowledge",
        "",
        "    Output format:",
        "      structure -- Needs specific format (code, JSON, tables)",
        "",
        "SELECTION RULES:",
        "  1. Start with efficiency (mandatory)",
        "  2. For EACH category, ask: 'Could this help?' not 'Is this the main problem?'",
        "  3. Minimum 3 categories total (more is fine)",
        "  4. Justify exclusions, not inclusions",
        "",
        "SELF-REFINEMENT:",
        "  For EACH category you DID NOT select:",
        "    - State the category",
        "    - Quote evidence from the prompt that this category cannot help",
        "  If you cannot quote evidence, include the category.",
        "",
        "OUTPUT FORMAT:",
        "  SELECTED: efficiency,reasoning/decomposition,correctness/verification,...",
        "  EXCLUDED with evidence:",
        "    - context/augmentation: '[quoted text]' shows complete domain context",
        "    - structure: '[quoted text]' shows free-form output is acceptable",
    ]


def technique_audit_actions() -> list[str]:
    """Instructions for systematic technique evaluation.

    This function is called after reference files are injected. The tabular
    format forces the LLM to evaluate ALL techniques, not just familiar ones.
    """
    return [
        "TECHNIQUE AUDIT TABLE (MANDATORY):",
        "",
        "For EVERY technique in EVERY injected reference file, create:",
        "",
        "| Technique | Source File | Trigger Condition | Applicable? | Evidence |",
        "|-----------|-------------|-------------------|-------------|----------|",
        "",
        "Rules:",
        "  - List ALL techniques from ALL injected files (no skipping)",
        "  - Quote the trigger condition from the reference",
        "  - If Applicable=YES: quote evidence from target prompt",
        "  - If Applicable=NO: state why trigger doesn't match",
        "",
        "This ensures systematic evaluation, not salience-driven selection.",
    ]




# =============================================================================
# Workflow Definitions
# =============================================================================

# Shared steps
STEP_TRIAGE = StepDef(
    id="triage",
    title="Triage",
    actions=[
        "EXAMINE the input, request, AND any relevant prior conversation:",
        "  - Problem descriptions stated earlier",
        "  - Analysis or diagnosis already performed",
        "  - User preferences or constraints mentioned",
        "",
        "  FILES PROVIDED:",
        "    - None: likely GREENFIELD",
        "    - Single file with prompt: likely SINGLE-PROMPT",
        "    - Multiple related files: likely ECOSYSTEM",
        "",
        "  REQUEST TYPE:",
        "    - General optimization ('improve this'): SINGLE-PROMPT or ECOSYSTEM",
        "    - Specific problem ('fix X', 'it does Y wrong'): PROBLEM",
        "    - Design request ('I want X to do Y'): GREENFIELD",
        "",
        "DETERMINE SCOPE (use boundary tests as guidance):",
        "  SINGLE-PROMPT: One file + 'improve/optimize' request",
        "    Boundary: If 2+ files interact -> ECOSYSTEM",
        "  ECOSYSTEM: Multiple files with shared terminology or data flow",
        "    Boundary: If no interaction between files -> multiple SINGLE-PROMPT",
        "  GREENFIELD: No existing prompt + 'create/design/build' request",
        "    Boundary: If modifying existing -> SINGLE-PROMPT or PROBLEM",
        "  PROBLEM: Existing prompt + specific failure described",
        "    Boundary: If no specific failure -> SINGLE-PROMPT or ECOSYSTEM",
        "  (boundaries are heuristics; use judgment for edge cases)",
        "",
        "OUTPUT:",
        "  SCOPE: [single-prompt | ecosystem | greenfield | problem]",
        "  RATIONALE: [why this scope fits]",
    ],
)

STEP_REFINE = StepDef(
    id="refine",
    title="Refine",
    actions=[
        "VERIFY each proposed technique (factored verification):",
        "",
        "  For each technique you claimed APPLICABLE:",
        "  1. Close your proposal. Answer from reference ONLY:",
        "     Q: 'What is the EXACT trigger condition for [technique]?'",
        "  2. Close the reference. Answer from target prompt ONLY:",
        "     Q: 'What text appears at line [N]?'",
        "  3. Compare: Does quoted text match quoted trigger?",
        "",
        "  Cross-check: CLAIMED vs VERIFIED",
        "    CONSISTENT -> keep",
        "    INCONSISTENT -> revise or remove",
        "",
        "SPOT-CHECK dismissed techniques:",
        "  Pick 3 marked NOT APPLICABLE",
        "  Verify triggers truly don't match",
        "",
        "UPDATE proposals based on verification.",
        "",
        "META-CONSTRAINT VERIFICATION:",
        "  For EACH proposed change:",
        "  Q: Does this change modify PROMPT TEXT STRUCTURE or add OUTPUT INSTRUCTIONS?",
        "  A: [Classify: quote the change and state which]",
        "",
        "  PROMPT TEXT STRUCTURE changes include:",
        "    - Shortening/compressing existing prompt text",
        "    - Removing sections or examples from prompt",
        "    - Refactoring code structure (extracting to variables, etc.)",
        "",
        "  OUTPUT INSTRUCTIONS changes include:",
        "    - Adding response format constraints",
        "    - Adding per-step word limits",
        "    - Adding output structure requirements",
        "",
        "  If ANY changes modify prompt text structure:",
        "    -> VIOLATION of meta-constraint",
        "    -> REMOVE these changes",
        "    -> REVISE to add output instructions instead",
        "",
        "CONTEXT-CORRECTNESS VERIFICATION (for greenfield/problem scopes):",
        "  If execution context was identified (STANDALONE/SKILL/SUB-AGENT/COMPONENT):",
        "",
        "  Q: What is the execution context for this prompt?",
        "  A: [answer from Step 2/Assess]",
        "",
        "  Q: Does the draft contain <system> wrapper or identity setup?",
        "  A: [quote from draft or 'None']",
        "",
        "  Q: Should this execution context have <system>/identity?",
        "  A: STANDALONE -> yes. SKILL/SUB-AGENT/COMPONENT -> no.",
        "",
        "  If INCONSISTENT: flag for revision before Approve step.",
    ],
)

STEP_APPROVE = StepDef(
    id="approve",
    title="Approve",
    actions=[
        "Present using this format:",
        "",
        "PROPOSED CHANGES",
        "================",
        "",
        "| # | Location | Opportunity | Technique | Risk |",
        "|---|----------|-------------|-----------|------|",
        "",
        "Then each change in detail",
        "",
        "VERIFICATION SUMMARY:",
        "  - Changes verified: N",
        "  - Changes revised: M",
        "  - Changes removed: K",
        "",
        "ANTI-PATTERNS CHECKED:",
        "  From Anti-Patterns section of each reference read:",
        "  - List each by name",
        "  - For each: [OK] or [FOUND: description]",
        "",
        "",
        "CRITICAL: STOP. Do NOT proceed to Execute step.",
        "Wait for explicit user approval before continuing.",
    ],
)


# Single-prompt workflow
WORKFLOW_SINGLE = Workflow(
    "prompt-engineer-single",
    STEP_TRIAGE,
    StepDef(
        id="assess",
        title="Assess",
        actions=[
            "PRIOR CONTEXT: Incorporate any relevant analysis, problem descriptions,",
            "or preferences from earlier in this conversation.",
            "",
            "READ the prompt file. Classify complexity:",
            "  SIMPLE: <20 lines, single purpose, no conditionals",
            "  COMPLEX: multiple sections, conditionals, tool orchestration",
            "",
            "Document OPERATING CONTEXT:",
            "  - Interaction: single-shot or conversational?",
            "  - Agent type: tool-use, coding, analysis, general?",
            "  - Failure modes: what goes wrong when this fails?",
        ],
    ),
    StepDef(
        id="understand",
        title="Understand",
        actions=understand_actions_simple(),
    ),
    StepDef(
        id="plan",
        title="Plan",
        actions=[
            "BLIND identification of opportunities (quote line evidence):",
            "  List as 'Lines X-Y: [issue]'",
            "",
            *technique_review_actions(),
            "",
            *change_format_actions("CHANGE"),
            "",
            "Include TECHNIQUE DISPOSITION summary.",
        ],
    ),
    STEP_REFINE,
    STEP_APPROVE,
    StepDef(
        id="execute",
        title="Execute",
        actions=[
            "Apply each approved change to the prompt file.",
            "",
            *integration_check_actions([
                "Cross-section references correct?",
                "Terminology consistent?",
                "Priority markers not overused? (max 2-3 CRITICAL/NEVER)",
            ]),
            "",
            *anti_pattern_audit_actions("modified prompt"),
            "",
            *change_presentation_actions(),
        ],
    ),
    description="Optimize a single prompt file",
    validate=False,
)


# Ecosystem workflow
WORKFLOW_ECOSYSTEM = Workflow(
    "prompt-engineer-ecosystem",
    STEP_TRIAGE,
    StepDef(
        id="assess",
        title="Assess",
        actions=[
            "PRIOR CONTEXT: Incorporate any relevant analysis, problem descriptions,",
            "or preferences from earlier in this conversation.",
            "",
            "READ all prompt-containing files in scope.",
            "",
            "MAP the ecosystem:",
            "  - List each prompt with location (file:lines)",
            "  - Identify relationships: orchestrator, subagent, shared-context",
            "  - Note terminology that should be consistent across prompts",
            "",
            *ecosystem_relationship_table(),
            "",
            "For EACH prompt, document:",
            "  - Purpose and role in the ecosystem",
            "  - What it receives from / passes to other prompts",
            "  - Complexity classification",
        ],
    ),
    StepDef(
        id="understand",
        title="Understand",
        actions=understand_actions_ecosystem(),
    ),
    StepDef(
        id="verify_understanding",
        title="Verify Understanding",
        actions=verify_understanding_actions(),
    ),
    StepDef(
        id="plan",
        title="Plan",
        actions=[
            "FOR EACH PROMPT - identify opportunities:",
            "  List as 'File:Lines X-Y: [issue]'",
            "",
            "FOR THE ECOSYSTEM - identify cross-prompt issues:",
            "  Using your interaction table AND your <handoff_understanding>:",
            "  - For each Shared Term: check consistency across listed prompts",
            "  - For each Receives From/Sends To pair: check handoff clarity",
            *handoff_minimalism_test(),
            "  - Conflicting instructions",
            "  - Redundant specifications",
            "  List as 'ECOSYSTEM: [issue across File1, File2]'",
            "",
            *technique_review_actions(for_ecosystem=True),
            "",
            *change_format_actions("CHANGE"),
            "Note which changes affect single file vs multiple.",
        ],
    ),
    STEP_REFINE,
    STEP_APPROVE,
    StepDef(
        id="execute",
        title="Execute",
        actions=[
            "Apply changes to each file.",
            "",
            "ECOSYSTEM INTEGRATION CHECKS:",
            "  - Terminology aligned across all files?",
            "  - Handoffs clear and consistent?",
            "  - No conflicting instructions introduced?",
            "",
            *anti_pattern_audit_actions("ALL modified prompts"),
            "",
            *change_presentation_actions(),
        ],
    ),
    description="Optimize multiple related prompts",
    validate=False,
)


# Greenfield workflow
WORKFLOW_GREENFIELD = Workflow(
    "prompt-engineer-greenfield",
    STEP_TRIAGE,
    StepDef(
        id="assess",
        title="Assess Requirements",
        actions=[
            "PRIOR CONTEXT: Incorporate any relevant analysis, problem descriptions,",
            "or preferences from earlier in this conversation.",
            "",
            "UNDERSTAND requirements (core questions, not exhaustive):",
            "  - What task should the prompt accomplish?",
            "  - What inputs will it receive?",
            "  - What outputs should it produce?",
            "  - What constraints exist? (length, format, tone)",
            "",
            "DETERMINE execution context (CRITICAL - affects scaffold):",
            "  STANDALONE: Full system prompt with complete control",
            "    -> Prompt IS the system message, can define identity/role",
            "  SKILL: Injected into existing agent (e.g., Claude Code skill)",
            "    -> NO <system> wrapper, NO identity setup, task-focused",
            "  SUB-AGENT: Task instruction passed to delegated agent",
            "    -> Bounded task description, minimal context, NO workflow overview",
            "  COMPONENT: Fragment composing with other prompts",
            "    -> Interface-focused, expects external orchestration",
            "",
            "  Ask user if unclear. State context with rationale.",
            "",
            "INFER architecture (single-turn vs multi-turn):",
            "  SINGLE-TURN when: discrete task, one input -> one output",
            "  MULTI-TURN when: refinement loops, verification, context accumulation",
            "",
            "  NEVER suggest subagents or HITL unless user explicitly requests.",
            "  State architecture choice with rationale.",
            "",
            "IDENTIFY edge cases (examples to consider):",
            "  - What happens with ambiguous input?",
            "  - What errors are expected?",
            "  - What should NOT happen?",
        ],
    ),
    StepDef(
        id="understand",
        title="Understand",
        actions=[
            "ARTICULATE semantic understanding of what you're building:",
            "",
            "<purpose>",
            "  What is the high-level goal of this prompt?",
            "  What inputs does it expect?",
            "  What outputs should it produce?",
            "  What does SUCCESS look like?",
            "</purpose>",
            "",
            "<boundaries>",
            "  If this prompt will delegate to sub-agents or components:",
            "  - What is each recipient's bounded responsibility?",
            "  - What is the MINIMUM each recipient needs?",
            "  - What should NOT be passed to recipients? Why?",
            "  If no delegation planned, state: 'No delegation boundaries.'",
            "</boundaries>",
            "",
            "CONTEXT MISMATCH ANTI-PATTERN (review before Design):",
            "",
            "<example type='INCORRECT'>",
            "  Context: SKILL (Claude Code)",
            "  Output: <system>You are a helpful assistant that...</system>",
            "  WHY WRONG: Skills are injected into existing conversation.",
            "             The agent already has identity. Adding <system> is nonsensical.",
            "</example>",
            "<example type='CORRECT'>",
            "  Context: SKILL (Claude Code)",
            "  Output: 'When user requests X, invoke script Y. The script handles Z.'",
            "  WHY RIGHT: Task-focused, no identity, assumes existing agent context.",
            "</example>",
            "",
            "<example type='INCORRECT'>",
            "  Context: SUB-AGENT",
            "  Output: 'You are part of a 6-step workflow. Step 1 does A, step 2...'",
            "  WHY WRONG: Sub-agent needs only its task. Workflow overview is noise.",
            "</example>",
            "<example type='CORRECT'>",
            "  Context: SUB-AGENT",
            "  Output: 'Search for files matching pattern X. Return paths and sizes.'",
            "  WHY RIGHT: Bounded task, minimal context, clear output contract.",
            "</example>",
        ],
    ),
    StepDef(
        id="design",
        title="Design",
        actions=[
            "SELECT applicable techniques for the design:",
            "  Based on requirements, architecture, and EXECUTION CONTEXT from Step 2",
            "",
            "SCAFFOLD based on execution context:",
            "",
            "  IF STANDALONE:",
            "    - Identity/role establishment (<system>You are...)",
            "    - Task description",
            "    - Input handling",
            "    - Output format",
            "    - Constraints and rules",
            "",
            "  IF SKILL (injected into existing agent):",
            "    - Invocation trigger (when to activate)",
            "    - Task instructions (imperative, action-focused)",
            "    - Input/output contract",
            "    - Constraints specific to this skill",
            "    ASSUME: Agent already has identity. Write task-focused instructions only.",
            "",
            "  IF SUB-AGENT (delegated task):",
            "    - Bounded task description",
            "    - Required inputs/outputs",
            "    - Success criteria",
            "    ASSUME: Sub-agent discovers context during execution. Write bounded task only.",
            "",
            "  IF COMPONENT (composable fragment):",
            "    - Interface specification",
            "    - Expected inputs from upstream",
            "    - Outputs for downstream",
            "    ASSUME: External orchestrator provides context. Write interface only.",
            "",
            "For each section, match techniques:",
            "  === SECTION: [name] ===",
            '  Technique: [name] | Trigger: "[quoted]"',
            "  DRAFT: [proposed content]",
            "  RATIONALE: [why this technique here]",
            "",
            "CONTEXT-CORRECTNESS CHECK (before drafting):",
            "",
            "<example context='SKILL' type='INCORRECT'>",
            "  <system>You are a helpful code review assistant...</system>",
            "  WHY WRONG: Skills inject into existing agent. Agent has identity.",
            "</example>",
            "<example context='SKILL' type='CORRECT'>",
            "  When user requests code review, analyze the diff and provide feedback.",
            "  Focus on: correctness, style, potential bugs.",
            "  WHY RIGHT: Task-focused. No identity. Imperative instructions.",
            "</example>",
            "",
            "<example context='SUB-AGENT' type='INCORRECT'>",
            "  You are step 3 of a 6-step workflow. Steps 1-2 have gathered context...",
            "  WHY WRONG: Sub-agent needs only its task. Workflow is orchestrator's concern.",
            "</example>",
            "<example context='SUB-AGENT' type='CORRECT'>",
            "  Search for files matching pattern. Return paths and sizes.",
            "  WHY RIGHT: Bounded task. Clear contract. No workflow knowledge.",
            "</example>",
            "",
            "WRITE complete prompt draft.",
        ],
    ),
    STEP_REFINE,
    STEP_APPROVE,
    StepDef(
        id="execute",
        title="Create",
        actions=[
            "CREATE the prompt file(s).",
            "",
            *integration_check_actions([
                "All requirements addressed?",
                "Edge cases handled?",
                "Structure follows chosen architecture?",
            ]),
            "",
            *anti_pattern_audit_actions("created prompt"),
            "",
            *change_presentation_actions(),
        ],
    ),
    description="Design a new prompt from requirements",
    validate=False,
)


# Problem workflow
WORKFLOW_PROBLEM = Workflow(
    "prompt-engineer-problem",
    STEP_TRIAGE,
    StepDef(
        id="assess",
        title="Diagnose",
        actions=[
            "PRIOR CONTEXT: Incorporate any relevant analysis, problem descriptions,",
            "or preferences from earlier in this conversation.",
            "",
            "UNDERSTAND the problem:",
            "  - What is the observed behavior?",
            "  - What is the expected behavior?",
            "  - When does it occur? (always / sometimes / conditions)",
            "",
            "READ relevant prompt(s) if they exist.",
            "",
            "CLASSIFY the problem (primary categories):",
            "  PROMPTING: Can be addressed by technique application",
            "  CAPABILITY: Model fundamentally cannot do this",
            "  ARCHITECTURE: Needs structural change, not technique",
            "  EXTERNAL: Problem is in surrounding code, not prompt",
            "  (problem may span multiple categories)",
            "",
            "If NOT a prompting issue: state clearly and STOP.",
            "If prompting issue: identify lines that may contribute.",
        ],
    ),
    StepDef(
        id="understand",
        title="Understand",
        actions=understand_actions_simple(),
    ),
    StepDef(
        id="plan",
        title="Target Fix",
        actions=[
            "REVERSE LOOKUP - which techniques address this problem class?",
            "  Review Technique Selection Guide for matching triggers",
            "",
            "For each candidate technique:",
            "  - QUOTE trigger condition",
            "  - Explain how problem matches trigger",
            "  - Propose specific change",
            "",
            *change_format_actions("FIX"),
            "  Expected effect: [how this fixes the problem]",
        ],
    ),
    STEP_REFINE,
    STEP_APPROVE,
    StepDef(
        id="execute",
        title="Apply Fix",
        actions=[
            "Apply targeted fix to the prompt.",
            "",
            "VERIFY the fix addresses the stated problem:",
            "  - Does the change match the diagnosed cause?",
            "  - Could it introduce new issues?",
            "",
            *change_presentation_actions(),
        ],
    ),
    description="Fix a specific issue in existing prompt(s)",
    validate=False,
)


# Root workflow for triage entry point
# Uses a modified triage step that terminates instead of continuing to "assess"
STEP_TRIAGE_ROOT = StepDef(
    id="triage",
    title="Triage",
    actions=STEP_TRIAGE.actions,
)

WORKFLOW_ROOT = Workflow(
    "prompt-engineer",
    STEP_TRIAGE_ROOT,
    description="Scope-adaptive prompt optimization (triage entry point)",
    validate=False,
)



# Scope mapping
SCOPES = {
    "single-prompt": WORKFLOW_SINGLE,
    "ecosystem": WORKFLOW_ECOSYSTEM,
    "greenfield": WORKFLOW_GREENFIELD,
    "problem": WORKFLOW_PROBLEM,
}


def format_prompt_engineer_output(
    step, total, scope, step_def, read_section, next_command,
    is_step_one=False,
    file_nodes: list[FileContentNode] | None = None,
    additional_actions: list[str] | None = None,
):
    """Format output using AST builder API.

    Args:
        step: Current step number
        total: Total steps in workflow
        scope: Workflow scope (single-prompt, ecosystem, etc.)
        step_def: StepDef with actions for this step
        read_section: Prose instructions for reading references (legacy mode)
        next_command: Command for next step invocation
        is_step_one: Whether this is step 1 (triage)
        file_nodes: FileContentNodes to inject (new mode, replaces read_section)
        additional_actions: Extra actions to append (category selection or audit)
    """
    parts = []
    title = f"PROMPT ENGINEER - {step_def.title}"
    step_header_node = StepHeaderNode(
        title=title,
        script="prompt_engineer",
        step=str(step),
        total=str(total)
    )
    parts.append(render_step_header(step_header_node))
    parts.append("")

    if scope:
        parts.append(f"Scope: {scope.upper()}")
        parts.append("")

    if is_step_one:
        parts.append("""<xml_format_mandate>
CRITICAL: All script outputs use XML format. You MUST:
1. Execute the action in <current_action>
2. When complete, invoke the exact command in <invoke_after>
3. DO NOT modify commands. DO NOT skip steps.
</xml_format_mandate>""")
        parts.append("")

    if read_section:
        read_nodes = [TextNode(line) for line in read_section]
        parts.append(render(W.el("read_section", *read_nodes).build(), XMLRenderer()))
        parts.append("")

    if file_nodes:
        parts.append("<technique_references>")
        parts.append("The following reference files have been injected based on your category selection:")
        parts.append("")
        renderer = XMLRenderer()
        for node in file_nodes:
            parts.append(renderer.render_file_content(node))
            parts.append("")
        parts.append("</technique_references>")
        parts.append("")

    all_actions = list(step_def.actions)
    if additional_actions:
        all_actions.extend(additional_actions)

    parts.append(render_current_action(CurrentActionNode(all_actions)))
    parts.append("")

    if next_command:
        parts.append(render_invoke_after(InvokeAfterNode(cmd=next_command)))
    else:
        parts.append("WORKFLOW COMPLETE - Present results to user.")

    return "\n".join(parts)


# =============================================================================
# CLI Entry Point
# =============================================================================


def main(
    step: int = None,
    scope: str | None = None,
):
    """CLI entry point. Args come from argparse, not these defaults."""
    parser = argparse.ArgumentParser(
        description="Prompt Engineer - Scope-adaptive optimization workflow",
        epilog="Step 1: triage. Steps 2+: scope-specific workflow.",
    )
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument(
        "--scope",
        choices=list(SCOPES.keys()),
        default=None,
        help="Required for steps 2+. Run step 1 first to determine scope.",
    )
    parser.add_argument(
        "--categories",
        type=str,
        default=None,
        help="Comma-separated technique categories to inject",
    )
    args = parser.parse_args()

    if args.step < 1:
        sys.exit("ERROR: --step must be >= 1")

    file_nodes = None
    cat_list = None
    if args.categories:
        cat_list = [c.strip() for c in args.categories.split(",") if c.strip()]
        file_nodes = load_category_files(cat_list)

    # Step 1 is triage (no scope yet)
    if args.step == 1:
        workflow = WORKFLOW_SINGLE
        step_def = STEP_TRIAGE
        total = 6
        next_cmd = "python3 -m skills.prompt_engineer.optimize --step 2 --scope <determined-scope>"
        output = format_prompt_engineer_output(
            args.step, total, None, step_def, None, next_cmd, is_step_one=True
        )
        print(output)
        return

    # Steps 2+ require scope
    if args.scope is None:
        sys.exit(
            "ERROR: --scope required for steps 2+. Run step 1 first to determine scope."
        )

    workflow = SCOPES[args.scope]
    total = workflow.total_steps

    if args.step > total:
        sys.exit(
            f"ERROR: Step {args.step} exceeds total ({total}) for scope '{args.scope}'"
        )

    # Map step number to step_id
    step_ids = list(workflow.steps.keys())
    step_id = step_ids[args.step - 1]
    step_def = workflow.steps[step_id]

    # Get next step info
    next_step_def = None
    if args.step < total:
        next_step_id = step_ids[args.step]
        next_step_def = workflow.steps[next_step_id]

    # Inject READ section at plan/design steps
    # References are organized by PROBLEM TYPE, not execution topology.
    # Decision tree: INPUT issues -> context/*.md
    #                OUTPUT issues -> reasoning/*.md, correctness/*.md, efficiency.md, structure.md
    read_specs = {
        "single-prompt": (4, [
            "READ BASED ON DIAGNOSED PROBLEM:",
            "",
            "All references are in the `references/` subdirectory of the prompt-engineer",
            "skill directory. NOTE: *NOT* the prompt_engineer scripts directory, but the",
            "prompt-engineer skill directory, which also contains the SKILL.md file.",
            "",
            "ALWAYS read: references/efficiency.md",
            "  -> Output compression techniques apply to all prompts",
            "",
            "THEN select based on problem type identified in Assess:",
            "",
            "  Model can't reason through problem?",
            "    -> references/reasoning/decomposition.md (multi-step complexity)",
            "    -> references/reasoning/elicitation.md (skips steps, no trace)",
            "",
            "  Model reasons but gives wrong answers?",
            "    -> references/correctness/sampling.md (inconsistent outputs)",
            "    -> references/correctness/verification.md (factual errors)",
            "    -> references/correctness/refinement.md (needs iteration)",
            "",
            "  Context issues (noisy, missing info)?",
            "    -> references/context/reframing.md (poorly framed)",
            "    -> references/context/augmentation.md (missing knowledge)",
            "",
            "  Need specific output format?",
            "    -> references/structure.md (code, JSON, tables)",
            "",
            "Extract: Technique Selection Guide from each reference read.",
            "For each technique: note Trigger Condition and Tradeoffs.",
            "",
            "NEVER read papers/**/* - use references/ only.",
        ]),
        "ecosystem": (5, [
            "READ BASED ON DIAGNOSED PROBLEMS:",
            "",
            "All references are in the `references/` subdirectory of the prompt-engineer",
            "skill directory. NOTE: *NOT* the prompt_engineer scripts directory, but the",
            "prompt-engineer skill directory, which also contains the SKILL.md file.",
            "",
            "ALWAYS read: references/efficiency.md",
            "  -> Output compression techniques apply to all prompts",
            "",
            "FOR EACH PROMPT, select based on its diagnosed problem:",
            "",
            "  Model can't reason through problem?",
            "    -> references/reasoning/decomposition.md",
            "    -> references/reasoning/elicitation.md",
            "",
            "  Model reasons but wrong answers?",
            "    -> references/correctness/sampling.md",
            "    -> references/correctness/verification.md",
            "    -> references/correctness/refinement.md",
            "",
            "  Context issues?",
            "    -> references/context/reframing.md",
            "    -> references/context/augmentation.md",
            "",
            "  Need specific format?",
            "    -> references/structure.md",
            "",
            "Extract: Technique Selection Guide from each reference.",
            "Note which techniques apply to multiple prompts in ecosystem.",
            "",
            "NEVER read papers/**/* - use references/ only.",
        ]),
        "greenfield": (4, [
            "READ BASED ON REQUIREMENTS:",
            "",
            "All references are in the `references/` subdirectory of the prompt-engineer",
            "skill directory. NOTE: *NOT* the prompt_engineer scripts directory, but the",
            "prompt-engineer skill directory, which also contains the SKILL.md file.",
            "",
            "ALWAYS read: references/efficiency.md",
            "  -> Output compression techniques apply to all prompts",
            "",
            "SELECT based on task requirements from Assess:",
            "",
            "  Task requires multi-step reasoning?",
            "    -> references/reasoning/decomposition.md",
            "    -> references/reasoning/elicitation.md",
            "",
            "  Task needs high accuracy/consistency?",
            "    -> references/correctness/sampling.md",
            "    -> references/correctness/verification.md",
            "",
            "  Task involves long/noisy context?",
            "    -> references/context/reframing.md",
            "    -> references/context/augmentation.md",
            "",
            "  Task needs structured output?",
            "    -> references/structure.md",
            "",
            "Extract: Technique Selection Guide from each reference.",
            "Match techniques to requirements and execution context.",
            "",
            "NEVER read papers/**/* - use references/ only.",
        ]),
        "problem": (4, [
            "READ BASED ON DIAGNOSED FAILURE:",
            "",
            "All references are in the `references/` subdirectory of the prompt-engineer",
            "skill directory. NOTE: *NOT* the prompt_engineer scripts directory, but the",
            "prompt-engineer skill directory, which also contains the SKILL.md file.",
            "",
            "ALWAYS read: references/efficiency.md",
            "  -> Output compression often relevant to problem fixes",
            "",
            "SELECT based on problem class from Diagnose step:",
            "",
            "  Reasoning failures (skips steps, wrong decomposition)?",
            "    -> references/reasoning/decomposition.md",
            "    -> references/reasoning/elicitation.md",
            "",
            "  Consistency failures (different answers each time)?",
            "    -> references/correctness/sampling.md",
            "",
            "  Accuracy failures (wrong facts, hallucinations)?",
            "    -> references/correctness/verification.md",
            "",
            "  Quality failures (output needs polish)?",
            "    -> references/correctness/refinement.md",
            "",
            "  Context failures (ignores info, distracted)?",
            "    -> references/context/reframing.md",
            "",
            "  Format failures (wrong structure)?",
            "    -> references/structure.md",
            "",
            "Focus on techniques matching the specific failure mode.",
            "",
            "NEVER read papers/**/* - use references/ only.",
        ]),
    }

    read_section = None
    additional_actions = None

    if args.scope in read_specs:
        read_step, read_refs = read_specs[args.scope]

        if args.step == read_step - 1 and not cat_list:
            additional_actions = category_selection_actions()

        if args.step == read_step:
            if file_nodes:
                additional_actions = technique_audit_actions()
            else:
                read_section = read_refs

    # Next step or completion
    next_command = None
    if args.step < total:
        next_step = args.step + 1
        base_cmd = f"python3 -m skills.prompt_engineer.optimize --step {next_step} --scope {args.scope}"

        if args.scope in read_specs:
            read_step, _ = read_specs[args.scope]
            if args.step == read_step - 1 and not cat_list:
                base_cmd += " --categories <SELECTED_CATEGORIES>"
            elif args.categories:
                base_cmd += f" --categories {args.categories}"

        next_command = base_cmd

    output = format_prompt_engineer_output(
        args.step, total, args.scope, step_def, read_section, next_command,
        file_nodes=file_nodes,
        additional_actions=additional_actions,
    )
    print(output)


if __name__ == "__main__":
    main()
