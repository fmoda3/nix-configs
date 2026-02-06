#!/usr/bin/env python3
"""
Leon Writing Style - Multi-turn prompt injection for style compliance.

Grounded in:
- Plan-and-Solve (Wang et al., 2023) - classification before writing
- Step-Back Prompting (Zheng et al., 2023) - principle retrieval before drafting
- RE2 Re-Reading (Xu et al., 2023) - re-read before verification
- Chain-of-Verification (Dhuliawala et al., 2023) - factored style checking
- Factor+Revise (Dhuliawala et al., 2023) - explicit cross-check before refinement
- Self-Refine (Madaan et al., 2023) - iterative improvement with contrastive feedback
- Metacognitive Prompting (Wang & Zhao, 2024) - confidence assessment
"""

import argparse
import sys
from pathlib import Path

from skills.lib.workflow.core import (
    StepDef,
    Workflow,
    Arg,
)
from skills.lib.workflow.ast import W, XMLRenderer, render
from skills.lib.workflow.ast.nodes import (
    TextNode, StepHeaderNode, CurrentActionNode, InvokeAfterNode,
)
from skills.lib.workflow.ast.renderer import (
    render_step_header, render_current_action, render_invoke_after,
)


TOTAL_STEPS = 9  # Number of steps in workflow


def get_phase_name(step: int) -> str:
    """Return the phase name for a given step number."""
    if step <= 2:
        return "UNDERSTANDING"
    elif step == 3:
        return "DRAFTING"
    elif step <= 7:
        return "VERIFICATION"
    else:
        return "REFINEMENT"


def load_resource_section(section: str) -> str:
    """Load a specific section from the style guide resource."""
    import sys

    resource_path = Path(__file__).parent.parent / "resources" / "writing-style.md"
    if not resource_path.exists():
        sys.exit(f"ERROR: writing style resource not found: {resource_path}")

    content = resource_path.read_text()

    section_markers = {
        "core_voice": ("## Core Voice Characteristics", "## Priority Rules"),
        "priority_rules": ("## Priority Rules", "## Content-Type Classification"),
        "content_types": ("## Content-Type Classification", "## Key Patterns Summary"),
        "key_patterns": ("## Key Patterns Summary", "## Sentence Patterns"),
        "sentence_patterns": ("## Sentence Patterns", "## Transition Words"),
        "transitions": ("## Transition Words", "## Structure Pattern"),
        "structure": ("## Structure Pattern", "## Diagrams"),
        "ai_tells": ("## AI Tells to Avoid", "## Contrastive Examples"),
        "contrastive_examples": ("## Contrastive Examples", "## Edge Cases"),
    }

    if section not in section_markers:
        return ""

    start_marker, end_marker = section_markers[section]

    start_idx = content.find(start_marker)
    if start_idx == -1:
        return ""
    end_idx = content.find(end_marker, start_idx) if end_marker else len(content)
    if end_idx == -1:
        end_idx = len(content)
    return content[start_idx:end_idx].strip()


# Structured history template for context accumulation
HISTORY_TEMPLATE = """
CONTEXT ACCUMULATION: Your --thoughts MUST include:

  ## Classification (from Step 1)
  | Section | Content Type | Voice |

  ## Purpose (from Step 2)
  Core message: [one sentence]
  Reference register: [philosophical / pop culture / technical / none]

  ## Violations (from Steps 4-6)
  | Location | Pattern | Quoted Text | Confidence |

  ## Positive Markers (from Step 5)
  | Category | Count | Examples |
  Verdict: PASS/FAIL (found N, required M)

  ## Structural Metrics (from Step 4)
  Paragraph range: X-Y sentences
  Sentence length mix: X% short, Y% medium, Z% long
  Opener type: grounded / meta-commentary

  ## Refinements (from Step 8+)
  | Original | Revised |
"""


# Step data definitions
STEPS = {
    1: {
        "step_title": "Content Classification",
        "actions": [
            "Before writing, classify your content. Voice rules depend on this.",
            "",
            "<content_types>",
            "NARRATIVE - Tell a story, share experience, explain motivation",
            "  Voice: First-person ('I found', 'I chose', 'my advice')",
            "  Use for: Introductions, rationale, design decisions, opinions",
            "",
            "INSTRUCTIONAL - Teach how to do something",
            "  Voice: Imperative ('Run the command', 'Configure the setting')",
            "  Use for: Usage guides, tutorials, step-by-step procedures",
            "",
            "REFERENCE - Document facts, APIs, specifications",
            "  Voice: Third-person declarative ('The function accepts...')",
            "  Use for: API docs, parameter tables, specifications",
            "",
            "HYBRID - Mixed content (most technical writing)",
            "  Voice: Shifts by section purpose",
            "  Use for: READMEs, blog posts, technical articles",
            "</content_types>",
            "",
            "<classification_output>",
            "Map your content to types:",
            "",
            "  | Section/Topic | Content Type | Voice |",
            "  |---------------|--------------|-------|",
            "  | Introduction  | narrative    | first-person |",
            "  | Usage         | instructional| imperative |",
            "  | ...           | ...          | ... |",
            "",
            "This table guides voice selection in later steps.",
            "</classification_output>",
        ],
        "next_desc": "Define purpose and audience.",
    },
    2: {
        "step_title": "Purpose & Audience",
        "actions": [
            "Define the content's purpose and target audience.",
            "",
            "<audience_analysis>",
            "WHO is the reader?",
            "  - Technical level: expert / intermediate / beginner",
            "  - What do they already know?",
            "  - What confusion might they bring?",
            "</audience_analysis>",
            "",
            "<purpose_analysis>",
            "WHY does this content exist?",
            "  - What should change after reading? (knowledge, action, belief)",
            "  - What is the SINGLE most important message?",
            "  - What action should the reader take?",
            "",
            "Leon's writing always has a clear throughline.",
            "If you cannot state the core message in one sentence, clarify before drafting.",
            "</purpose_analysis>",
            "",
            "<hook_draft>",
            "Draft your opening hook now:",
            "  - State the problem and why it matters",
            "  - Use first-person if narrative ('I was writing an application that...')",
            "  - Be specific, not abstract (name projects, technologies, constraints)",
            "</hook_draft>",
            "",
            "<reference_register>",
            "OPTIONAL: Will this document use quotes, anecdotes, or cultural references?",
            "",
            "  If YES, choose ONE register and commit:",
            "    - Philosophical (Seneca, military history, wisdom traditions)",
            "    - Pop culture (TV, films, memes, irreverent commentary)",
            "    - Technical (papers, specifications, industry sources)",
            "",
            "  If NO, proceed without references. This is a valid choice.",
            "",
            "  CRITICAL: Do not mix registers. Pick one or none.",
            "</reference_register>",
            "",
            HISTORY_TEMPLATE,
        ],
        "next_desc": "Draft with style rules.",
    },
    3: {
        "step_title": "Draft with Style Rules",
        "actions": [
            "<step_back_principles>",
            "Before writing, answer these questions:",
            "",
            "  1. What makes Leon's voice distinctive from generic technical writing?",
            "     (First-person authority, specific examples, definitive conclusions)",
            "",
            "  2. What is the ONE thing that would make this sound AI-generated?",
            "     (Tricolons, dead metaphors, hollow emphasis, balanced structure)",
            "",
            "Keep these answers in mind as you draft.",
            "</step_back_principles>",
            "",
            "<stakes>",
            "This content represents Leon's public voice. Quality matters.",
            "Readers will judge Leon's expertise by this writing.",
            "</stakes>",
            "",
            "<core_voice>",
            "CONFIDENT AUTHORITY:",
            "  State conclusions first, then support.",
            "  NOT: 'This might be problematic'",
            "  YES: 'This is the wrong approach.'",
            "",
            "FIRST-PERSON FOR NARRATIVE:",
            "  'I found', 'my advice', 'I would recommend'",
            "  Exception: Instructions use imperative, reference uses third-person",
            "",
            "SARDONIC WHEN WARRANTED:",
            "  'of course!', 'Sigh.', 'I almost cannot believe I'm reading this.'",
            "  Express genuine frustration at poor engineering decisions.",
            "",
            "PRAGMATIC, NOT THEORETICAL:",
            "  Ground in real code, real projects, real consequences.",
            "  Name specific projects, people, technologies.",
            "</core_voice>",
            "",
            "<structure_pattern>",
            "1. HOOK - state the problem and why it matters",
            "2. CONTEXT - background needed to understand",
            "3. TECHNICAL DEEP DIVE - code examples, step-by-step",
            "4. ANALYSIS - options and trade-offs",
            "5. RECOMMENDATION - definitive advice",
            "6. IMPLICATIONS (optional) - broader meaning",
            "</structure_pattern>",
            "",
            "<transitions>",
            "Use: 'So, ...', 'However, ...', 'Now, ...', 'As such, ...'",
            "Signature: 'The astute reader will notice...', 'Once again, ...'",
            "Avoid: 'Moving on to...', 'In conclusion...', 'Let's explore...'",
            "</transitions>",
            "",
            "Write your draft now. Verification follows in the next steps.",
            "",
            HISTORY_TEMPLATE,
        ],
        "next_desc": "Check for AI tells.",
    },
    4: {
        "step_title": "AI Tells Detection",
        "actions": [
            "<re_read_examples>",
            "Before detecting AI tells, read the contrastive examples again.",
            "Open and read: resources/ai-tells-examples.md",
            "These examples show exactly what patterns to catch.",
            "With these examples fresh in mind, proceed to detection.",
            "</re_read_examples>",
            "",
            "<re_read>",
            "Read your draft again, slowly, sentence by sentence.",
            "Then check for AI-generated patterns.",
            "</re_read>",
            "",
            "VERIFICATION METHOD: Extract first, then judge.",
            "For each pattern: (1) extract candidates, (2) assess each.",
            "",
            "<pattern_1_tricolons>",
            "TRICOLONS / RHYTHMIC PARALLELISM",
            "",
            "  EXTRACT: List all sentences with 3+ comma-separated elements",
            "  or parallel phrase structures.",
            "",
            "  JUDGE each: Does it have manufactured symmetry?",
            "    WRONG: 'Clear context, focused execution, reliable results.'",
            "    RIGHT: 'The same agents run at every stage. Standards don't change.'",
            "",
            "  For each violation, record:",
            "    | Quote | Confidence (HIGH/MED/LOW) |",
            "</pattern_1_tricolons>",
            "",
            "<pattern_2_contrarian>",
            "CONTRARIAN OPENERS / RHETORICAL REFRAMING",
            "",
            "  EXTRACT: List all sentences with contrastive structure:",
            "    - 'X isn't Y -- it's Z'",
            "    - 'X is not Y -- it's Z'",
            "    - 'This is not X' followed by counter-statement",
            "    - 'not X but Y' / 'not X -- Y'",
            "    - Any sentence negating X then asserting Y as replacement",
            "",
            "  JUDGE each: Is it a rhetorical reframe that adds no information?",
            "    WRONG: 'Review isn't a gate you pass once -- it's continuous.'",
            "    WRONG: 'This is not overhead -- it catches mistakes.'",
            "    WRONG: 'It's not about X -- it's about Y.'",
            "    RIGHT: 'I run every plan through review before execution starts.'",
            "    RIGHT: State what happens without the rhetorical negation.",
            "",
            "  For each violation, record:",
            "    | Quote | Confidence (HIGH/MED/LOW) |",
            "</pattern_2_contrarian>",
            "",
            "<pattern_3_metaphors>",
            "DEAD METAPHORS",
            "",
            "  EXTRACT: List all figurative language (metaphors, analogies).",
            "",
            "  JUDGE each: Is it a cliche that has lost vividness?",
            "",
            "  WRONG (by category -- if it appears in business writing, it's dead):",
            "    FOUNDATION: 'flawed foundation', 'unknown foundation', 'solid foundation',",
            "                'building blocks', 'cornerstone', 'pillars'",
            "    JOURNEY:    'ever-evolving landscape', 'roadmap', 'path forward',",
            "                'on the same page', 'moving forward'",
            "    BUILDING:   'framework', 'architecture', 'construct', 'scaffold'",
            "    NATURE:     'ecosystem', 'organic', 'root cause', 'cultivate'",
            "    MACHINE:    'leverage', 'drive', 'fuel', 'mechanism'",
            "",
            "  RIGHT: Use concrete consequences instead:",
            "    'all need to be thrown away'",
            "    'invalidates half of them'",
            "    'you're building on code you haven't verified'",
            "",
            "  For each violation, record:",
            "    | Quote | Category | Confidence (HIGH/MED/LOW) |",
            "</pattern_3_metaphors>",
            "",
            "<pattern_4_emphasis>",
            "HOLLOW EMPHASIS",
            "",
            "  EXTRACT: List all sentences containing 'important', 'critical',",
            "  'worth noting', 'key', 'crucial', 'essential'.",
            "",
            "  JUDGE each: Does it announce importance instead of showing it?",
            "    WRONG: 'This is important.'",
            "    RIGHT: 'Without this, X happens.' (shows consequence)",
            "",
            "  For each violation, record:",
            "    | Quote | Confidence (HIGH/MED/LOW) |",
            "</pattern_4_emphasis>",
            "",
            "<pattern_5_callbacks>",
            "EXPLICIT CALLBACKS",
            "",
            "  EXTRACT: List all phrases with 'just like', 'as mentioned',",
            "  'as we saw', 'similar to above'.",
            "",
            "  JUDGE each: Does it over-explain a connection?",
            "    WRONG: 'just like during planning'",
            "    RIGHT: State the fact and move on.",
            "",
            "  For each violation, record:",
            "    | Quote | Confidence (HIGH/MED/LOW) |",
            "</pattern_5_callbacks>",
            "",
            "<pattern_6_formula>",
            "FORMULA FOLLOWING",
            "",
            "  EXTRACT: What is the structure of each paragraph?",
            "  (e.g., Statement -> Explanation -> Consequence)",
            "",
            "  JUDGE: Are all paragraphs structured identically?",
            "  Leon's writing varies. Some points just get stated.",
            "",
            "  Note if rhythm feels artificial: YES/NO + explanation.",
            "</pattern_6_formula>",
            "",
            "<pattern_7_mixed_register>",
            "MIXED REGISTER (if references are used)",
            "",
            "  EXTRACT: List all quotes, cultural references, and anecdotes.",
            "  Note the register of each:",
            "    - Philosophical (Seneca, Marcus Aurelius, military history)",
            "    - Pop culture (TV shows, films, memes)",
            "    - Technical (papers, specifications)",
            "",
            "  JUDGE: Is more than one register used?",
            "    WRONG: Seneca quote + Silicon Valley reference",
            "    RIGHT: All references from one register, or no references",
            "",
            "  For each register clash, record:",
            "    | Quote 1 | Register 1 | Quote 2 | Register 2 | Confidence |",
            "</pattern_7_mixed_register>",
            "",
            "<pattern_8_euphemism>",
            "EUPHEMISTIC ORGANIZATIONAL LANGUAGE",
            "",
            "  EXTRACT: List phrases containing:",
            "    - 'alignment', 'transition', 'challenges'",
            "    - 'not the ideal fit', 'opportunities for growth'",
            "    - 'stakeholder concerns', 'performance gaps'",
            "",
            "  JUDGE: Does each hide a simpler, plainer meaning?",
            "    WRONG: 'necessitating a transition' = firing",
            "    WRONG: 'alignment challenges' = wrong hire",
            "    RIGHT: State the plain meaning directly",
            "",
            "  For each euphemism, record:",
            "    | Euphemism | Plain Meaning | Confidence |",
            "</pattern_8_euphemism>",
            "",
            "<pattern_9_structural_variance>",
            "STRUCTURAL MONOTONY",
            "",
            "  EXTRACT: Count sentences per paragraph",
            "    | Para # | Sentence Count |",
            "    | 1      | ?              |",
            "    | 2      | ?              |",
            "    | ...    | ...            |",
            "",
            "  JUDGE: What is the variance?",
            "    - Narrow (all 2-4 sentences): FLAG as monotonous",
            "    - Wide (includes 1-sentence AND 5+ sentence): PASS",
            "",
            "  REQUIRED: At least one paragraph that breaks the pattern",
            "    - One-liner (<= 1 sentence): 'That's the core idea.'",
            "    - Long block (>= 5 sentences): deep technical dive",
            "",
            "  If no variance, record:",
            "    | Issue | Range | Confidence |",
            "    | Structural monotony | 2-4 sentences | HIGH |",
            "</pattern_9_structural_variance>",
            "",
            "<pattern_10_grounded_openers>",
            "META-COMMENTARY VS GROUNDED OPENERS",
            "",
            "  EXTRACT: First sentence of each major section/the document",
            "    | Section | First Sentence |",
            "",
            "  JUDGE each: Is it grounded or meta-commentary?",
            "",
            "  META-COMMENTARY (FLAG):",
            "    - 'Here is how this looks...'",
            "    - 'This section explains...'",
            "    - 'The following is an example of...'",
            "    - 'Let me show you...'",
            "    - 'In this article, we will...'",
            "  Pattern: Describes the text rather than the subject",
            "",
            "  GROUNDED (PASS):",
            "    - 'I was writing an application that uses cryptographic...'",
            "    - 'The codebase had a homegrown Log() method...'",
            "    - 'Last month, we hit a production issue where...'",
            "  Pattern: Immediately names project, technology, or problem",
            "",
            "  For each meta-commentary opener, record:",
            "    | Section | Quote | Confidence |",
            "</pattern_10_grounded_openers>",
            "",
            "<pattern_11_sentence_rhythm>",
            "SENTENCE RHYTHM VARIANCE",
            "",
            "  EXTRACT: Categorize sentences by word count",
            "    SHORT (<8 words): punchy emphasis",
            "      - 'That's not a good sign.'",
            "      - 'Sigh.'",
            "      - 'This is wrong.'",
            "    MEDIUM (8-20 words): standard prose",
            "    LONG (>20 words): complex technical explanations",
            "",
            "  COUNT per category:",
            "    | Category | Count | Example Quote |",
            "    | Short    | ?     | '...'         |",
            "    | Medium   | ?     | '...'         |",
            "    | Long     | ?     | '...'         |",
            "",
            "  JUDGE: Is there variety?",
            "    FLAG if: 90%+ sentences in single category (typically medium)",
            "    PASS if: Mix includes at least one SHORT and one LONG",
            "",
            "  BONUS CHECK: Questions and exclamations",
            "    EXTRACT: Any sentences ending in ? or !",
            "    For narrative content: at least one question adds engagement",
            "      - 'So how do we fix this?'",
            "      - 'Victory!'",
            "",
            "  If no variance, record:",
            "    | Issue | Breakdown | Confidence |",
            "    | Uniform rhythm | 95% medium | HIGH |",
            "</pattern_11_sentence_rhythm>",
            "",
            "<pattern_12_repetition>",
            "REPEATED PHRASES / UNINTENTIONAL SELF-CALLBACKS",
            "",
            "  EXTRACT: Identify phrases (5+ words) appearing multiple times.",
            "  Also check for semantic repetition (same idea, different words).",
            "",
            "  JUDGE each: Is repetition intentional emphasis or unintentional callback?",
            "    WRONG: 'catches mistakes before they become code' in intro AND later section",
            "    WRONG: Same benefit stated twice in different sections",
            "    RIGHT: Intentional refrain with clear rhetorical purpose",
            "",
            "  The principle: If you stated it once clearly, trust the reader.",
            "",
            "  For each unintentional repetition, record:",
            "    | Quote | Locations | Confidence (HIGH/MED/LOW) |",
            "</pattern_12_repetition>",
            "",
            "<pattern_13_overjustification>",
            "OVER-JUSTIFICATION / DEFENSIVE CLAUSES",
            "",
            "  EXTRACT: List sentences with:",
            "    - Em-dash followed by explanatory 'why this matters' clause",
            "    - Parenthetical adding justification",
            "    - 'because' clause that anticipates unstated objection",
            "",
            "  JUDGE each: Is the clause defending against anticipated 'so what?'",
            "    WRONG: 'catches the drift -- the kind nobody notices until...'",
            "    WRONG: 'Building on unknown foundation means rework when assumptions prove wrong.'",
            "    WRONG: 'This prevents issues (which can be very costly later).'",
            "    RIGHT: 'catches most problems before they compound.'",
            "    RIGHT: 'Building on unverified code means rework.'",
            "",
            "  The principle: State and move on. If the reader doesn't see the value, they'll ask.",
            "",
            "  For each violation, record:",
            "    | Quote | Defensive Clause | Confidence (HIGH/MED/LOW) |",
            "</pattern_13_overjustification>",
            "",
            "OUTPUT: Violation table with quoted text and confidence per pattern.",
            "",
            HISTORY_TEMPLATE,
        ],
        "next_desc": "Check for positive voice markers.",
    },
    5: {
        "step_title": "Positive Voice Marker Check",
        "actions": [
            "<positive_markers>",
            "VERIFICATION METHOD: Extract first, then assess sufficiency.",
            "The skill checks for ABSENCE of bad patterns (Steps 4).",
            "This step checks for PRESENCE of Leon's signature voice.",
            "",
            "CATEGORY 1: SIGNATURE TRANSITIONS",
            "  EXTRACT: Sentences opening with:",
            "    - 'So,' or 'So '",
            "    - 'Now,' or 'Now '",
            "    - 'However,'",
            "    - 'As such,'",
            "  COUNT: How many found? Quote each.",
            "",
            "CATEGORY 2: QUESTION-ANSWER PATTERNS",
            "  EXTRACT: Any 'X? Well,' or 'X? Y:' constructions",
            "    - 'How do we fix this? Well:'",
            "    - 'So what does this mean? Simple:'",
            "  COUNT: How many found? Quote each.",
            "",
            "CATEGORY 3: PARENTHETICAL ASIDES",
            "  EXTRACT: Text within parentheses that adds context",
            "    - '(or at least, that's what it has come to be)'",
            "    - '(otherwise X will fail)'",
            "  COUNT: How many found? Quote each.",
            "",
            "CATEGORY 4: SARDONIC MARKERS",
            "  EXTRACT: Expressions of genuine frustration or irony",
            "    - 'Sigh.'",
            "    - 'of course!'",
            "    - 'I almost cannot believe...'",
            "  COUNT: How many found? Quote each.",
            "",
            "CATEGORY 5: SIGNATURE PHRASES",
            "  EXTRACT: Leon's distinctive expressions",
            "    - 'The astute reader will notice...'",
            "    - 'Once again, ...'",
            "  COUNT: How many found? Quote each.",
            "</positive_markers>",
            "",
            "<sufficiency_check>",
            "THRESHOLDS (for narrative content only):",
            "  - Content <300 words: at least 1 marker from any category",
            "  - Content 300-800 words: at least 2 markers",
            "  - Content >800 words: at least 3 markers",
            "",
            "EXEMPT: Instructional and reference sections (per Step 1 classification)",
            "",
            "TALLY:",
            "  | Category | Count | Examples |",
            "  |----------|-------|----------|",
            "  | Transitions | ? | '...' |",
            "  | Question-Answer | ? | '...' |",
            "  | Parentheticals | ? | '...' |",
            "  | Sardonic | ? | '...' |",
            "  | Signature | ? | '...' |",
            "  | TOTAL | ? | |",
            "",
            "VERDICT:",
            "  PASS: Meets threshold for content length",
            "  FAIL: Below threshold - record as HIGH priority violation",
            "",
            "If FAIL, record:",
            "  | Issue | Found | Required | Priority |",
            "  | Missing voice markers | N | M | HIGH |",
            "</sufficiency_check>",
            "",
            HISTORY_TEMPLATE,
        ],
        "next_desc": "Verify voice-content alignment.",
    },
    6: {
        "step_title": "Voice-Content Alignment",
        "actions": [
            "<re_read>",
            "Read your draft again with your Step 1 classification table visible.",
            "For each section, verify voice matches content type.",
            "</re_read>",
            "",
            "VERIFICATION METHOD: Extract voice markers, then compare to expected.",
            "",
            "<narrative_check>",
            "FOR EACH NARRATIVE SECTION:",
            "",
            "  EXTRACT: What pronouns appear? Quote first 3 sentences.",
            "  EXTRACT: What verb forms? (active: 'I built' vs passive: 'was built')",
            "  EXTRACT: What hedging words? ('might', 'could', 'may', 'perhaps')",
            "",
            "  EXPECTED: First-person, active voice, definitive statements.",
            "    RIGHT: 'I built this because...'",
            "    WRONG: 'The tool was created to...'",
            "",
            "  VIOLATIONS: | Section | Quote | Issue | Confidence |",
            "</narrative_check>",
            "",
            "<instructional_check>",
            "FOR EACH INSTRUCTIONAL SECTION:",
            "",
            "  EXTRACT: What verb forms open each instruction?",
            "  EXTRACT: Any first-person pronouns? Quote them.",
            "",
            "  EXPECTED: Imperative verbs, no first-person.",
            "    RIGHT: 'Pass the --strict flag for full validation.'",
            "    WRONG: 'I pass the --strict flag when I want full validation.'",
            "",
            "  VIOLATIONS: | Section | Quote | Issue | Confidence |",
            "</instructional_check>",
            "",
            "<reference_check>",
            "FOR EACH REFERENCE SECTION:",
            "",
            "  EXTRACT: What subjects appear? ('The function', 'It', 'I')",
            "  EXTRACT: Any opinion language? ('best', 'should', 'recommended')",
            "",
            "  EXPECTED: Third-person declarative, factual.",
            "    RIGHT: 'The function accepts three parameters...'",
            "    WRONG: 'I accept three parameters...'",
            "",
            "  VIOLATIONS: | Section | Quote | Issue | Confidence |",
            "</reference_check>",
            "",
            "<hybrid_boundary_check>",
            "FOR HYBRID CONTENT:",
            "",
            "  EXTRACT: Where do section boundaries occur?",
            "  At each boundary, what voice is used before/after?",
            "",
            "  EXPECTED: Clean voice shifts at section boundaries.",
            "  COMMON FAILURE: First-person bleeding into usage instructions.",
            "",
            "  VIOLATIONS: | Boundary | Before Voice | After Voice | Issue |",
            "</hybrid_boundary_check>",
            "",
            "OUTPUT: Section-by-section compliance with violations table.",
            "",
            HISTORY_TEMPLATE,
        ],
        "next_desc": "Consolidate violations for refinement.",
    },
    7: {
        "step_title": "Cross-Check Consolidation",
        "actions": [
            "Consolidate ALL violations from Steps 4-6 before refinement.",
            "Include both negative pattern violations AND missing positive markers.",
            "",
            "<consolidation>",
            "Create a single violation table:",
            "",
            "  | # | Location | Pattern | Quoted Text | Confidence | Priority |",
            "  |---|----------|---------|-------------|------------|----------|",
            "  | 1 | Para 2   | Tricolon| '...'       | HIGH       | Fix first|",
            "  | 2 | Intro    | Passive | '...'       | HIGH       | Fix first|",
            "  | 3 | Global   | Missing markers | 0 found, 2 required | HIGH | Fix first|",
            "  | 4 | Opener   | Meta-commentary | 'Here is how...' | HIGH | Fix first|",
            "  | 5 | Usage    | 1st-person| '...'     | MED        | Fix after|",
            "",
            "PRIORITY RULES:",
            "  - Missing voice markers: Fix first (most impactful)",
            "  - Meta-commentary openers: Fix first (immediate AI tell)",
            "  - HIGH confidence violations: Fix before MED/LOW",
            "  - Voice mismatches: Fix before minor style issues",
            "  - Structural monotony: Fix by varying paragraph lengths",
            "</consolidation>",
            "",
            "<cross_check>",
            "Review the consolidated list:",
            "",
            "  1. Are any violations duplicates? (Same text, different patterns)",
            "     -> Merge into single entry, note both patterns.",
            "",
            "  2. Do any violations conflict? (Fixing one creates another)",
            "     -> Note the conflict, decide which takes precedence.",
            "",
            "  3. Are any LOW confidence violations actually false positives?",
            "     -> Re-examine the quote. Remove if not a real violation.",
            "",
            "  4. Are any sections violation-free? (Confirm explicitly)",
            "     -> Note: 'Section X: No violations found.'",
            "</cross_check>",
            "",
            "<refinement_plan>",
            "Create a refinement order:",
            "",
            "  Fix #1: [violation] -> [planned fix approach]",
            "  Fix #2: [violation] -> [planned fix approach]",
            "  ...",
            "",
            "This plan guides the next step.",
            "</refinement_plan>",
            "",
            HISTORY_TEMPLATE,
        ],
        "next_desc": "Apply refinements.",
    },
    8: {
        "step_title": "Self-Refine",
        "actions": [
            "Apply refinements from your Step 7 plan.",
            "",
            "<refinement_process>",
            "FOR EACH VIOLATION in priority order:",
            "  1. Quote the original text",
            "  2. State the pattern violated",
            "  3. Write the revised text",
            "  4. Verify the fix doesn't introduce new violations",
            "</refinement_process>",
            "",
            "<tricolon_fix>",
            "TRICOLON FIX:",
            "  Break artificial symmetry. Vary sentence length.",
            "  BEFORE: 'Clear context, focused execution, reliable results.'",
            "  AFTER:  'The same agents run at every stage. Standards don't change.'",
            "</tricolon_fix>",
            "",
            "<metaphor_fix>",
            "METAPHOR FIX:",
            "  Replace with concrete consequences.",
            "  BEFORE: 'built on a flawed foundation'",
            "  AFTER:  'all need to be thrown away'",
            "</metaphor_fix>",
            "",
            "<emphasis_fix>",
            "EMPHASIS FIX:",
            "  Delete the announcement, show the consequence.",
            "  BEFORE: 'This is important. You don't want X.'",
            "  AFTER:  'Without this, X happens. The LLM starts...'",
            "</emphasis_fix>",
            "",
            "<voice_fix>",
            "VOICE FIX:",
            "  Match voice to section purpose.",
            "  Narrative: 'I built this because...'",
            "  Instructional: 'Run with --verbose to...'",
            "  Reference: 'The function accepts...'",
            "</voice_fix>",
            "",
            "<rhythm_fix>",
            "RHYTHM FIX:",
            "  Vary paragraph structure. Not every point needs explanation.",
            "  Some things just get stated. Some get questions.",
            "  'So how do we fix this? Well, easy:'",
            "</rhythm_fix>",
            "",
            "<marker_fix>",
            "MISSING VOICE MARKERS FIX:",
            "  Add signature transitions at natural pivot points.",
            "  BEFORE: 'The analysis showed three options.'",
            "  AFTER:  'So, the analysis showed three options.'",
            "",
            "  Add question-answer at decision points.",
            "  BEFORE: 'We chose option A.'",
            "  AFTER:  'Which option? We chose A.'",
            "",
            "  Add parenthetical context where useful.",
            "  BEFORE: 'This fails silently.'",
            "  AFTER:  'This fails silently (no error message, just wrong data).'",
            "</marker_fix>",
            "",
            "<opener_fix>",
            "META-COMMENTARY OPENER FIX:",
            "  Replace meta-commentary with grounded specifics.",
            "  BEFORE: 'Here is how this looks on a real task.'",
            "  AFTER:  'Last month I needed to migrate a legacy C# service.'",
            "",
            "  Name the project, technology, or constraint immediately.",
            "  BEFORE: 'The following example demonstrates the workflow.'",
            "  AFTER:  'The codebase had 31 Log() call sites and no rotation.'",
            "</opener_fix>",
            "",
            "<variance_fix>",
            "STRUCTURAL MONOTONY FIX:",
            "  Add one-liner paragraphs for punch.",
            "  BEFORE: [3 sentences] [3 sentences] [3 sentences]",
            "  AFTER:  [3 sentences] [1 sentence punch] [5 sentence deep-dive]",
            "",
            "  Combine related short paragraphs into one longer block.",
            "  Or break up a medium paragraph with a standalone statement.",
            "  'That's the core problem.'",
            "</variance_fix>",
            "",
            "<refinement_log>",
            "Record each change:",
            "",
            "  | # | Original | Revised | Pattern Fixed |",
            "  |---|----------|---------|---------------|",
            "",
            "This log goes in your --thoughts for the next step.",
            "</refinement_log>",
            "",
            "OUTPUT: Revised draft with refinement log.",
            "",
            HISTORY_TEMPLATE,
        ],
        "next_desc": "Final quality check.",
    },
    9: {
        "step_title": "Final Quality Check",
        "actions": [
            "FINAL VERIFICATION before completion.",
            "",
            "<stopping_criteria>",
            "STOP (workflow complete) when ALL are true:",
            "  - Zero HIGH-confidence violations remain",
            "  - Voice matches content type for every section",
            "  - No tricolons, dead metaphors, or hollow emphasis",
            "  - Positive marker threshold met (Step 5 verdict: PASS)",
            "  - Grounded opener (no meta-commentary)",
            "  - Structural variance present",
            "",
            "CONTINUE (increase total_steps) if ANY are true:",
            "  - Any HIGH-confidence violation remains",
            "  - Voice mismatch in any section",
            "  - Positive markers below threshold",
            "  - Meta-commentary opener still present",
            "  - Rhythm still feels formulaic",
            "</stopping_criteria>",
            "",
            "<final_checklist>",
            "AI TELLS ABSENT (must all be true):",
            "  [x] No tricolons or rhythmic parallelism",
            "  [x] No contrarian openers ('X isn't Y -- it's Z')",
            "  [x] No dead metaphors (flawed foundation, landscape, etc.)",
            "  [x] No hollow emphasis ('This is important')",
            "  [x] No explicit callbacks ('just like', 'as mentioned')",
            "  [x] No mixed register (if references used, all from one category)",
            "  [x] No euphemistic organizational language",
            "  [x] No meta-commentary openers ('Here is how...', 'This section...')",
            "",
            "LEON'S VOICE PRESENT (must all be true for narrative content):",
            "  [x] At least one signature transition ('So,', 'Now,', 'However,')",
            "  [x] At least one short punchy sentence (<8 words)",
            "  [x] Structural variance (not all paragraphs 2-4 sentences)",
            "  [x] Grounded opener (names project/technology/problem, not meta)",
            "  [x] Mix of sentence lengths (short + medium + long)",
            "  [x] At least one question or parenthetical aside",
            "",
            "VOICE (must all be true):",
            "  [x] Narrative sections use first-person",
            "  [x] Instructional sections use imperative",
            "  [x] Reference sections use third-person",
            "  [x] Voice shifts cleanly at section boundaries",
            "  [x] Uncomfortable truths stated plainly, not hedged",
            "",
            "STRUCTURE (must all be true):",
            "  [x] Conclusions stated first, then supported",
            "  [x] Specific examples, not abstract descriptions",
            "  [x] Natural transitions ('So,', 'However,', 'Now,')",
            "  [x] No 'In conclusion' or 'Moving on to'",
            "  [x] Hook states problem and why it matters",
            "</final_checklist>",
            "",
            "If any checkbox would be [ ] instead of [x]: increase total_steps.",
            "",
            "Otherwise: draft complete. Deliver final content.",
        ],
        "next_desc": "WORKFLOW COMPLETE - deliver final content.",
    },
}


# Handler functions
def handle_step_1(next_step: int | None) -> dict:
    """Content Classification."""
    step_data = STEPS[1]
    return {
        "phase": "UNDERSTANDING",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }


def handle_step_2(next_step: int | None) -> dict:
    """Purpose & Audience."""
    step_data = STEPS[2]
    return {
        "phase": "UNDERSTANDING",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }


def handle_step_3(next_step: int | None) -> dict:
    """Draft with Style Rules."""
    step_data = STEPS[3]
    return {
        "phase": "DRAFTING",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }


def handle_step_4(next_step: int | None) -> dict:
    """AI Tells Detection."""
    step_data = STEPS[4]
    return {
        "phase": "VERIFICATION",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }
def handle_step_5(next_step: int | None) -> dict:
    """Positive Voice Marker Check."""
    step_data = STEPS[5]
    return {
        "phase": "VERIFICATION",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }


def handle_step_6(next_step: int | None) -> dict:
    """Voice-Content Alignment."""
    step_data = STEPS[6]
    return {
        "phase": "VERIFICATION",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }


def handle_step_7(next_step: int | None) -> dict:
    """Cross-Check Consolidation."""
    step_data = STEPS[7]
    return {
        "phase": "VERIFICATION",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }


def handle_step_8(next_step: int | None) -> dict:
    """Self-Refine."""
    step_data = STEPS[8]
    return {
        "phase": "REFINEMENT",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": f"Step {next_step}: {step_data['next_desc']}" if next_step else "COMPLETE",
    }


def handle_step_9(next_step: int | None) -> dict:
    """Final Quality Check."""
    step_data = STEPS[9]
    return {
        "phase": "REFINEMENT",
        "step_title": step_data["step_title"],
        "actions": step_data["actions"],
        "next": step_data["next_desc"],
    }


def handle_additional_refinement(next_step: int | None) -> dict:
    """Additional Refinement beyond step 9."""
    return {
        "phase": "REFINEMENT",
        "step_title": "Additional Refinement",
        "actions": [
            "Continue addressing remaining issues.",
            "",
            "<additional_refinement>",
            "Review your --thoughts for outstanding violations.",
            "Apply refinement rules from Step 8.",
            "",
            "Focus on HIGH-confidence violations first.",
            "When all HIGH-confidence violations are addressed,",
            "this becomes your final step.",
            "</additional_refinement>",
            "",
            HISTORY_TEMPLATE,
        ],
        "next": f"Step {next_step} if HIGH violations remain, or complete if clean." if next_step else "COMPLETE",
    }


# Dispatch table
STEP_HANDLERS = {
    1: handle_step_1,
    2: handle_step_2,
    3: handle_step_3,
    4: handle_step_4,
    5: handle_step_5,
    6: handle_step_6,
    7: handle_step_7,
    8: handle_step_8,
    9: handle_step_9,
}


def get_step_guidance(step: int) -> dict:
    """Return step-specific guidance and actions."""
    is_complete = step >= TOTAL_STEPS
    next_step = step + 1 if step < TOTAL_STEPS else None

    # Dispatch to appropriate handler
    if step in STEP_HANDLERS:
        return STEP_HANDLERS[step](next_step)
    elif step > 9:
        return handle_additional_refinement(next_step)
    else:
        # Fallback for unexpected step numbers
        return {
            "phase": "UNKNOWN",
            "step_title": "Unknown Step",
            "actions": ["ERROR: Invalid step number."],
            "next": "COMPLETE",
        }


def format_output(step: int, guidance: dict, thoughts: str) -> str:
    """Format output using AST builder API."""
    parts = []
    is_complete = step >= WORKFLOW.total_steps

    title = f"WRITING STYLE - {guidance['phase']} - {guidance['step_title']}"
    parts.append(render_step_header(StepHeaderNode(
        title=title,
        script="leon_writing_style",
        step=str(step),
    )))
    parts.append("")

    if step == 1:
        parts.append("""<xml_format_mandate>
CRITICAL: All script outputs use XML format. You MUST:
1. Execute the action in <current_action>
2. When complete, invoke the exact command in <invoke_after>
3. DO NOT modify commands. DO NOT skip steps.
</xml_format_mandate>""")
        parts.append("")

    if thoughts:
        parts.append(render(W.el("accumulated_thoughts", TextNode(thoughts)).build(), XMLRenderer()))
        parts.append("")

    parts.append(render_current_action(CurrentActionNode(guidance["actions"])))
    parts.append("")

    next_text = guidance.get("next", "")
    if is_complete or "COMPLETE" in next_text.upper():
        parts.append("WORKFLOW COMPLETE - Deliver final content.")
    else:
        next_cmd = f'python3 -m skills.leon_writing_style.writing_style --step-number {step + 1} --thoughts \\"<accumulated>\\"'
        parts.append(render_invoke_after(InvokeAfterNode(cmd=next_cmd)))

    return "\n".join(parts)




# Workflow definition with 9 core steps
WORKFLOW = Workflow(
    "leon-writing-style",
    StepDef(
        id="classification",
        title="Content Classification",
        actions=[
            "Before writing, classify your content. Voice rules depend on this.",
            "",
            "<content_types>",
            "NARRATIVE - Tell a story, share experience, explain motivation",
            "  Voice: First-person ('I found', 'I chose', 'my advice')",
            "  Use for: Introductions, rationale, design decisions, opinions",
            "",
            "INSTRUCTIONAL - Teach how to do something",
            "  Voice: Imperative ('Run the command', 'Configure the setting')",
            "  Use for: Usage guides, tutorials, step-by-step procedures",
            "",
            "REFERENCE - Document facts, APIs, specifications",
            "  Voice: Third-person declarative ('The function accepts...')",
            "  Use for: API docs, parameter tables, specifications",
            "",
            "HYBRID - Mixed content (most technical writing)",
            "  Voice: Shifts by section purpose",
            "  Use for: READMEs, blog posts, technical articles",
            "</content_types>",
            "",
            "<classification_output>",
            "Map your content to types:",
            "",
            "  | Section/Topic | Content Type | Voice |",
            "  |---------------|--------------|-------|",
            "  | Introduction  | narrative    | first-person |",
            "  | Usage         | instructional| imperative |",
            "  | ...           | ...          | ... |",
            "",
            "This table guides voice selection in later steps.",
            "</classification_output>",
        ],
    ),
    StepDef(
        id="purpose_audience",
        title="Purpose & Audience",
        actions=get_step_guidance(2)["actions"],
    ),
    StepDef(
        id="drafting",
        title="Draft with Style Rules",
        actions=get_step_guidance(3)["actions"],
    ),
    StepDef(
        id="ai_tells_detection",
        title="AI Tells Detection",
        actions=get_step_guidance(4)["actions"],
    ),
    StepDef(
        id="positive_markers",
        title="Positive Voice Marker Check",
        actions=get_step_guidance(5)["actions"],
    ),
    StepDef(
        id="voice_alignment",
        title="Voice-Content Alignment",
        actions=get_step_guidance(6)["actions"],
    ),
    StepDef(
        id="consolidation",
        title="Cross-Check Consolidation",
        actions=get_step_guidance(7)["actions"],
    ),
    StepDef(
        id="refinement",
        title="Self-Refine",
        actions=get_step_guidance(8)["actions"],
    ),
    StepDef(
        id="final_check",
        title="Final Quality Check",
        actions=get_step_guidance(9)["actions"],
    ),
    description="Multi-turn style compliance workflow",
    validate=False,
)


def main(
    step: int = None):
    """Entry point with parameter annotations for testing framework.

    Note: Uses --step-number for backward compatibility with original interface.
    Parameters have defaults because actual values come from argparse.
    The annotations are metadata for the testing framework.
    """
    parser = argparse.ArgumentParser(
        description="Leon Writing Style - Multi-turn style compliance workflow",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="",
    )

    parser.add_argument(
        "--step",
        "--step-number",
        dest="step_number",
        type=int,
        required=True,
        help="Current step number (starts at 1)",
    )
    parser.add_argument(
        "--thoughts",
        type=str,
        default="",
        help="Your thinking, draft content, classification, and findings",
    )

    args = parser.parse_args()

    if args.step_number < 1:
        print("ERROR: step-number must be >= 1", file=sys.stderr)
        sys.exit(1)

    guidance = get_step_guidance(args.step_number)
    print(format_output(args.step_number, guidance, args.thoughts))


if __name__ == "__main__":
    main()
