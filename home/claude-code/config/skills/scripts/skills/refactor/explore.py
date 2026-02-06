#!/usr/bin/env python3
"""
Refactor Explore - Category-specific exploration for code smell detection.

Five-step workflow per category:
  1. Domain Context    - Identify project language/frameworks/structure
  2. Principle Extract - Step-back to extract principle + generate violation patterns
  3. Pattern Generate  - Translate abstract hints to project-specific grep patterns
  4. Search            - Execute patterns, document findings
  5. Synthesis         - Format findings with severity assessment
"""

import argparse
import shlex
import sys
from pathlib import Path

from skills.lib.workflow.ast import (
    W, XMLRenderer, render, TextNode,
    StepHeaderNode, CurrentActionNode, InvokeAfterNode,
    render_step_header, render_current_action, render_invoke_after,
)
from skills.lib.workflow.types import FlatCommand


MODULE_PATH = "skills.refactor.explore"
TOTAL_STEPS = 5

# Path to conventions/code-quality/ directory
CONVENTIONS_DIR = (
    Path(__file__).resolve().parent.parent.parent.parent.parent
    / "conventions"
    / "code-quality"
)


# =============================================================================
# Category Loader
# =============================================================================


def load_category_block(category_ref: str, mode: str = "code") -> str:
    """Load category text block from file:start-end reference.

    Args:
        category_ref: File reference (file:start-end)
        mode: "design" or "code" - extracts mode-specific guidance

    Returns:
        Category content with mode-specific guidance extracted
    """
    file_part, line_range = category_ref.split(":")
    start, end = map(int, line_range.split("-"))

    from skills.lib.io import read_text_or_exit

    path = CONVENTIONS_DIR / file_part
    content = read_text_or_exit(path, "loading category file")
    lines = content.splitlines()
    category_block = "\n".join(lines[start - 1 : end])

    mode_tag = f"<{mode}-mode>"
    close_tag = f"</{mode}-mode>"

    if mode_tag in category_block:
        _, sep, after = category_block.partition(mode_tag)
        if sep:
            inner, sep, _ = after.partition(close_tag)
            if sep:
                category_block = category_block.replace(f"{mode_tag}{inner}{close_tag}", inner.strip())

    for tag in ["<design-mode>", "</design-mode>", "<code-mode>", "</code-mode>"]:
        category_block = category_block.replace(tag, "")

    return category_block


# =============================================================================
# XML Formatters
# =============================================================================


def format_next_step(step: int, category_ref: str, mode: str = "code", scope: str | None = None) -> str:
    """Format the invoke-after block for next step."""
    scope_arg = f" --scope {shlex.quote(scope)}" if scope else ""
    cmd = f"python3 -m {MODULE_PATH} --step {step} --category {category_ref} --mode {mode}{scope_arg}"
    return render_invoke_after(InvokeAfterNode(cmd=cmd))


# =============================================================================
# Step 1: Domain Context
# =============================================================================


def format_step_1(category_ref: str, mode: str = "code", scope: str | None = None) -> str:
    """Step 1: Identify project domain context."""
    scope_display = f"SCOPE: {scope}" if scope else "SCOPE: Entire codebase"
    actions = [
        "DOMAIN CONTEXT ANALYSIS:",
        "",
        scope_display,
        "",
        "Before detecting smells, understand the project's technical context.",
        "This enables translating abstract patterns to project-specific ones.",
        "",
        "IDENTIFY (brief exploration, ~30 seconds):",
        "",
        "  1. LANGUAGE: Primary programming language(s)",
        "     Check: file extensions, shebang lines",
        "",
        "  2. FRAMEWORKS: Key frameworks/libraries",
        "     Check: package.json, requirements.txt, go.mod, Cargo.toml, pom.xml",
        "     Note: major frameworks (React, Django, Spring, etc.)",
        "",
        "  3. CONVENTIONS: Naming patterns used in this codebase",
        "     Check: a few source files for naming style",
        "     Note: camelCase vs snake_case, common suffixes (Service, Handler, etc.)",
        "",
        "OUTPUT (required):",
        '<domain_context>',
        '  <language>primary language</language>',
        '  <frameworks>framework1, framework2</frameworks>',
        '  <conventions>naming patterns observed</conventions>',
        '</domain_context>',
        "",
        "Keep this brief. Accuracy matters more than completeness.",
    ]

    parts = [
        render_step_header(StepHeaderNode(title="Domain Context", script="explore", step=1, category=category_ref, mode=mode)),
        "",
        render(W.el("xml_mandate").build(), XMLRenderer()),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        format_next_step(2, category_ref, mode, scope),
    ]
    return "\n".join(parts)


# =============================================================================
# Step 2: Principle + Violation Patterns
# =============================================================================


def format_step_2(category_ref: str, mode: str = "code", scope: str | None = None) -> str:
    """Step 2: Extract principle and generate violation patterns."""
    category_block = load_category_block(category_ref, mode)

    mode_description = "architecture/intent" if mode == "design" else "implementation"

    actions = [
        "<interpretation>",
        "The violations listed below are ILLUSTRATIVE PATTERNS, not an exhaustive checklist.",
        "Detect ANY code violating the underlying <principle>, including unlisted patterns.",
        "</interpretation>",
        "",
        f"MODE: {mode} ({mode_description})",
        "",
        "<smell_category>",
        category_block,
        "</smell_category>",
        "",
        "STEP-BACK: PRINCIPLE EXTRACTION",
        "",
        "Read the category definition. Extract:",
        "  - The PRINCIPLE (the 'why' that unifies all violations)",
        "  - The detection question (what to ask about each code fragment)",
        "  - The severity threshold (when to flag)",
        "",
        "ANALOGICAL GENERATION - VIOLATION PATTERNS:",
        "",
        "Using your domain context from Step 1, identify 2-3 ADDITIONAL violation patterns",
        "that would violate the SAME principle in THIS project's domain:",
        "",
        "  - What does this smell look like in [your language/framework]?",
        "  - What project-specific idioms might violate this principle?",
        "  - What framework-specific anti-patterns apply?",
        "",
        "If no additional patterns emerge, proceed with listed ones.",
        "",
        "OUTPUT (required):",
        '<principle_analysis>',
        '  <principle>the core principle in one sentence</principle>',
        '  <detection_question>what to ask about each code fragment</detection_question>',
        '  <threshold>when to flag vs ignore</threshold>',
        '  <violation_patterns>',
        '    <pattern source="listed">pattern from category definition</pattern>',
        '    <pattern source="generated">project-specific pattern you identified</pattern>',
        '    <!-- include all patterns: listed + generated -->',
        '  </violation_patterns>',
        '</principle_analysis>',
    ]

    parts = [
        render_step_header(StepHeaderNode(title="Principle + Violations", script="explore", step=2, category=category_ref, mode=mode)),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        format_next_step(3, category_ref, mode, scope),
    ]
    return "\n".join(parts)


# =============================================================================
# Step 3: Search Pattern Generation
# =============================================================================


def format_step_3(category_ref: str, mode: str = "code", scope: str | None = None) -> str:
    """Step 3: Generate project-specific grep patterns."""
    actions = [
        "SEARCH PATTERN GENERATION:",
        "",
        "The <grep-hints> in the category definition are ABSTRACT EXEMPLARS.",
        "They represent what to look for in a generic codebase.",
        "",
        "TRANSLATE to this project's domain:",
        "",
        "For EACH violation pattern (from Step 2), generate grep-able patterns:",
        "",
        "  - What would 'Manager' look like here? (Service, Repository, Store, Handler...)",
        "  - What naming conventions does this project use?",
        "  - What are the framework-specific equivalents?",
        "",
        "Examples of translation:",
        "  Abstract: 'Manager, Handler, Utils'",
        "  Python/Flask: 'Service, Repository, Blueprint, helpers'",
        "  Go: 'Handler, Store, Controller, util'",
        "  React: 'Container, Provider, HOC, utils'",
        "",
        "OUTPUT (required):",
        '<search_patterns>',
        '  <pattern reason="why this indicates the smell">regex_or_literal</pattern>',
        '  <pattern reason="...">...</pattern>',
        '  <!-- 5-10 patterns, project-specific -->',
        '</search_patterns>',
        "",
        "These patterns will be used for Grep in Step 4.",
    ]

    parts = [
        render_step_header(StepHeaderNode(title="Pattern Generation", script="explore", step=3, category=category_ref, mode=mode)),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        format_next_step(4, category_ref, mode, scope),
    ]
    return "\n".join(parts)


# =============================================================================
# Step 4: Search
# =============================================================================


def format_step_4(category_ref: str, mode: str = "code", scope: str | None = None) -> str:
    """Step 4: Execute search and document findings.

    If scope is provided, all Glob/Grep operations should be constrained
    to that path to prevent findings from unrelated parts of the codebase.
    """
    # Build scope constraint instructions if scope provided
    if scope:
        scope_constraint = [
            "SCOPE CONSTRAINT:",
            f"  You are searching within: {scope}",
            f'  - Glob patterns: Use "{scope}/**/*.py" instead of "**/*.py"',
            f'  - Grep paths: Pass "{scope}" as the path argument',
            "  - Do NOT search outside this scope",
            "",
        ]
    else:
        scope_constraint = [
            "SCOPE: Entire codebase (no constraint)",
            "",
        ]

    actions = [
        "SEARCH EXECUTION:",
        "",
        *scope_constraint,
        "Using the patterns from Step 3, search the codebase:",
        "",
        "  1. Use Glob to find relevant files in scope",
        "  2. Use Grep with each pattern from <search_patterns>",
        "  3. Use Read to examine suspicious matches",
        "  4. Apply the detection question from Step 2 to each match",
        "",
        "CROSS-FILE ANALYSIS:",
        "",
        "  5. After finding an issue, Grep for similar patterns in OTHER files",
        "  6. Note when patterns appear in 3+ locations (abstraction candidates)",
        "",
        # WHY occurrence counting is mandatory at Step 4 rather than optional or deferred:
        #
        # The explore agent has just executed search patterns and has Grep results in context.
        # At this point, re-running the same pattern with output_mode="count" is trivial.
        # Deferring to later steps would require:
        #   - Storing patterns for later replay (fragile - patterns evolve during exploration)
        #   - Re-executing searches (wasteful - same I/O cost paid twice)
        #   - Estimating counts from grep output (inaccurate - misses pagination)
        #
        # By capturing NOW, we have:
        #   - Zero marginal search cost (pattern already validated)
        #   - Exact counts (not estimates)
        #   - Verification commands that reproduce the search context
        #
        # WHY verification_cmd is required alongside count:
        #
        # A count like "47 occurrences" is unverifiable without the pattern that produced it.
        # Storing the grep pattern makes evidence falsifiable:
        #   - Reviewers can independently verify: grep -r "pattern" path/ | wc -l
        #   - Future scans can detect count drift (codebase evolution)
        #   - Work items can include reproducible scope claims
        #
        # The alternative (storing counts without patterns) creates uncheckable assertions.
        "OCCURRENCE COUNTING (MANDATORY):",
        "",
        "  For EACH potential finding, run a count query:",
        '    Grep with output_mode="count" to get total occurrences',
        "",
        "  Record:",
        '    - exact_count: Number returned by Grep count',
        '    - verification_cmd: The grep pattern used (for independent verification)',
        "",
        "CALIBRATION:",
        "",
        "  - Finding zero issues is a valid outcome. Do not force findings.",
        "  - Flag only when evidence is clear. Ambiguous cases are not findings.",
        "  - Apply the <threshold> from Step 2 - if exception applies, don't flag.",
        "",
        "OUTPUT (required):",
        '<findings>',
        '  <finding location="file:line-range">',
        '    <evidence lines="N">quoted code (2-5 lines, preserve indentation)</evidence>',
        '    <issue>what violates the principle</issue>',
        '    <occurrences count="N" verification="grep pattern to reproduce">',
        '      file2:line, file3:line OR "unique - single occurrence"',
        '    </occurrences>',
        '    <impact>what breaks/degrades if unfixed (one sentence)</impact>',
        '  </finding>',
        '  <!-- repeat for each finding -->',
        '</findings>',
        "",
        "Document findings. Do NOT propose solutions yet.",
    ]

    parts = [
        render_step_header(StepHeaderNode(title="Search", script="explore", step=4, category=category_ref, mode=mode)),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        format_next_step(5, category_ref, mode, scope),
    ]
    return "\n".join(parts)


# =============================================================================
# Step 5: Synthesis
# =============================================================================


def format_step_5(category_ref: str, mode: str = "code", scope: str | None = None) -> str:
    """Step 5: Synthesize findings into smell report."""
    actions = [
        "SYNTHESIZE findings from Step 4 into final report.",
        "",
        "OUTPUT FORMAT (strict):",
        "",
        # WHY token budget increased from 50 to 100 tokens per finding:
        #
        # Minimum viable evidence requires:
        #   - Code snippet (2-5 lines): 45-75 tokens with indentation
        #   - Impact statement: 25-40 tokens for "Blocks X because Y"
        #   - Occurrences metadata: 15-25 tokens (count + verification)
        #   Total: 85-140 tokens for complete evidence
        #
        # At 50 tokens, agents were forced to choose between:
        #   - Code OR impact (incomplete evidence)
        #   - Truncated code (not compilable/verifiable)
        #   - Generic impact (not specific to this codebase)
        #
        # 100 tokens is the minimum that fits all 4 evidence components without truncation.
        #
        # WHY max 8 findings instead of unlimited with 50-token budget:
        #
        # Previous model: 500 tokens / 50 per finding = 10 findings (but all truncated)
        # New model: 1200 tokens / 100 per finding = 12 findings (but capped at 8)
        #
        # The 8-finding cap forces prioritization BEFORE writing:
        #   - Agents must rank by severity, not report exhaustively
        #   - Cross-file evidence gets priority (more impactful than single-file)
        #   - Low-severity findings get filtered at source, not downstream
        #
        # This is better than post-hoc filtering because:
        #   - Agents have full search context (Cluster step does not)
        #   - Severity judgment happens closest to the code
        #   - Token budget concentrates on high-value findings
        "TOKEN BUDGET (ENFORCED):",
        "  - Total return: MAX 1200 tokens",
        "  - Finding count limit: MAX 8 findings",
        "  - Per finding: MIN 100 tokens (evidence must be verifiable)",
        "  - Budget breakdown: 75 tokens code (5 lines) + 40 impact + 25 occurrence = 140 typical",
        "  - If > 8 findings, keep highest severity with cross-file evidence priority",
        "  - If budget pressure, prefer 3-line code snippets over dropping findings",
        "",
        # WHY impact tag requires "Blocks/Degrades/Risks" structure:
        #
        # Without structure, agents produce:
        #   - Restatements: "This is inconsistent" (not an impact)
        #   - Vague claims: "Could cause issues" (what issues?)
        #   - Implementation details: "Should use HashMap" (not WHY)
        #
        # The 3-verb taxonomy forces causal reasoning:
        #   - "Blocks X" -> identifies a concrete capability gap
        #   - "Degrades X" -> quantifies a performance/quality cost
        #   - "Risks X" -> names a failure mode
        #
        # This makes impact falsifiable: reviewers can verify whether X is actually affected.
        '<smell_report category="$CATEGORY_NAME" mode="$MODE" severity="high|medium|low|none" count="N">',
        '  <finding location="file:line-range" severity="high|medium|low">',
        '    <evidence lines="N">',
        '      quoted code (2-5 lines, preserve exact indentation)',
        '    </evidence>',
        '    <issue>what is wrong (one sentence, be specific)</issue>',
        '    <impact>',
        '      WHY fix this? One of:',
        '      - "Blocks X" (prevents something)',
        '      - "Degrades X" (makes something worse)',
        '      - "Risks X" (could cause harm)',
        '    </impact>',
        '    <occurrences count="N" verification="grep -r PATTERN path/">',
        '      Codebase-wide count. Verification command must reproduce the count.',
        '    </occurrences>',
        '  </finding>',
        '  <!-- repeat for each finding -->',
        '</smell_report>',
        "",
        "EVIDENCE REQUIREMENTS (findings without these are INVALID):",
        "  1. <evidence> must quote actual code, not describe it",
        "  2. <impact> must state consequence, not just restate the issue",
        "  3. <occurrences> count must come from actual Grep, not estimation",
        "  4. verification attribute must be executable command",
        "",
        "SEVERITY LEVELS:",
        "  HIGH: Blocks maintainability, affects multiple areas",
        "  MEDIUM: Causes friction, localized impact",
        "  LOW: Minor annoyance, cosmetic",
        "  NONE: No issues found (empty findings)",
        "",
        "Extract $CATEGORY_NAME from the ## heading in the category block.",
        f'Use MODE: {mode}',
        "",
        "OUTPUT your smell_report now.",
    ]

    parts = [
        render_step_header(StepHeaderNode(title="Synthesis", script="explore", step=5, category=category_ref, mode=mode)),
        "",
        render_current_action(CurrentActionNode(actions)),
        "",
        "COMPLETE - Return smell_report to orchestrator.",
    ]
    return "\n".join(parts)


# =============================================================================
# Output Router
# =============================================================================


def format_output(step: int, category_ref: str, mode: str = "code", scope: str | None = None) -> str:
    """Route to appropriate step formatter."""
    formatters = {
        1: format_step_1,
        2: format_step_2,
        3: format_step_3,
        4: format_step_4,
        5: format_step_5,
    }
    formatter = formatters.get(step)
    if not formatter:
        sys.exit(f"ERROR: Unknown step {step}")
    return formatter(category_ref, mode, scope)


# =============================================================================
# Main
# =============================================================================


def main():
    parser = argparse.ArgumentParser(
        description="Refactor Explore - Category-specific code smell detection",
        epilog=f"Steps: context -> principle -> patterns -> search -> synthesis ({TOTAL_STEPS} total)",
    )
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument(
        "--category",
        type=str,
        required=True,
        help="Category reference as file:startline-endline (e.g., 01-naming-and-types.md:5-13)",
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["design", "code"],
        default="code",
        help="Evaluation mode: design (architecture/intent) or code (implementation)",
    )
    parser.add_argument(
        "--scope",
        type=str,
        default=None,
        help="Filesystem scope constraint for Glob/Grep operations (e.g., 'src/planner/')",
    )

    args = parser.parse_args()

    if args.step < 1:
        sys.exit("ERROR: --step must be >= 1")
    if args.step > 5:
        sys.exit(f"ERROR: --step cannot exceed 5")

    if ":" not in args.category or "-" not in args.category.split(":")[1]:
        sys.exit("ERROR: --category must be in format file.md:start-end")

    print(format_output(args.step, args.category, args.mode, args.scope))


if __name__ == "__main__":
    main()
