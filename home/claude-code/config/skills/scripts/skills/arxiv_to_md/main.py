#!/usr/bin/env python3
"""arxiv-to-md orchestrator: Parse input, dispatch sub-agents, rename outputs.

Two invocation modes:
  MODE 1: Direct conversion (default)
    - User provides arXiv IDs directly or via discovery
    - Orchestrator constructs filename from paper title + date

  MODE 2: PDF folder sync
    - User specifies source PDF folder + destination markdown folder
    - Orchestrator matches PDFs to existing .md files, identifies gaps
    - Destination filename derived from PDF filename

3-step workflow:
  1. Discover/Parse - Detect mode, find arXiv IDs, dispatch sub-agents
  2. Wait          - Wait for all sub-agents to complete
  3. Finalize      - Copy outputs to target location (filename construction varies by mode)
"""

import argparse
import sys

from skills.lib.workflow.core import (
    StepDef,
    Workflow,
)
from skills.lib.workflow.ast import W, XMLRenderer, render
from skills.lib.workflow.ast.nodes import (
    TextNode, StepHeaderNode, CurrentActionNode, InvokeAfterNode,
)
from skills.lib.workflow.ast.renderer import (
    render_step_header, render_current_action, render_invoke_after,
)
from skills.lib.workflow.ast import (
    TemplateDispatchNode, render_template_dispatch,
)


MODULE_PATH = "skills.arxiv_to_md.main"
SUBAGENT_MODULE = "skills.arxiv_to_md.sub_agent"






# Step definitions
STEP_DISCOVER = StepDef(
    id="discover",
    title="Discover and Dispatch",
    actions=[
        "MODE DETECTION:",
        "Determine which mode based on user input:",
        "",
        "MODE 1 (default): Direct conversion",
        "  Trigger: User provides arXiv IDs directly, or asks to convert papers",
        "  Filename: Orchestrator constructs from paper title + date",
        "",
        "MODE 2: PDF folder sync",
        "  Trigger: User specifies source PDF folder AND destination markdown folder",
        "  Filename: Derived from PDF filename (orchestrator provides to sub-agent)",
        "",
        "=" * 60,
        "",
        "MODE 1 DISCOVERY:",
        "Before asking the user for arXiv IDs, check for:",
        "  - CLAUDE.md in current directory (may list arXiv IDs)",
        "  - README.md or similar docs with arXiv links/IDs",
        "  - .bib files with arXiv entries",
        "If IDs found, confirm with user: 'Found arXiv ID(s) X, Y. Convert these?'",
        "",
        "PARSE USER INPUT:",
        "If user provides input directly, parse for arXiv IDs:",
        "  - Format: YYMM.NNNNN (e.g., 2503.05179)",
        "  - Or full URL: https://arxiv.org/abs/YYMM.NNNNN",
        "  - May be multiple IDs (comma-separated, space-separated, or multiple URLs)",
        "",
        "MODE 1 DISPATCH:",
        "PLACEHOLDER_MODE1_DISPATCH",
        "",
        "=" * 60,
        "",
        "MODE 2 DISCOVERY (PDF folder sync):",
        "",
        "FORBIDDEN - NEVER read PDF files. Resolve arXiv IDs by searching online for paper title.",
        "",
        "CRITICAL - CHECK EXISTING FILES FIRST:",
        "",
        "Most files WILL already exist. Skipping is the common case.",
        "Before dispatching ANY sub-agent, check if output already exists.",
        "",
        "If a PDF already has a matching .md file, STOP. Do NOT dispatch.",
        "Skip that PDF entirely.",
        "",
        "FILE NAMING CONVENTION:",
        "  PDFs:     YYYY-MM-DD <title>.pdf",
        "  Markdown: YYYY-MM-DD <title>.md",
        "  Example:  2025-01-08 Pruning the Unsurprising.pdf",
        "",
        "1. SCAN DESTINATION FOLDER for existing markdown FIRST:",
        "   - List all *.md files in destination folder",
        "",
        "2. SCAN SOURCE FOLDER for PDFs:",
        "   - List all *.pdf files in source folder",
        "   - Extract base filename (without .pdf extension)",
        "",
        "3. For EACH PDF, check if matching .md exists:",
        "   Matching logic: same YYYY-MM-DD prefix + similar title",
        "   - '2025-01-08 Pruning the Unsurprising.pdf' matches '2025-01-08 Pruning the Unsurprising.md'",
        "   If match exists -> SKIP this PDF (do not dispatch)",
        "",
        "4. RESOLVE ARXIV IDs from unmatched PDFs:",
        "   - Extract paper title from PDF filename (after YYYY-MM-DD prefix)",
        "   - Use WebSearch to find arXiv ID for that paper title",
        "   - DO NOT read the PDF file",
        "",
        "5. DETERMINE DESTINATION FILENAMES:",
        "   For each unmatched PDF with resolved arXiv ID:",
        "   - dest_file = '<dest_folder>/<pdf_basename>.md'",
        "   - Example: source/2025-01-08 Pruning the Unsurprising.pdf",
        "             -> dest/2025-01-08 Pruning the Unsurprising.md",
        "",
        "MODE 2 DISPATCH:",
        "PLACEHOLDER_MODE2_DISPATCH",
    ],
)

STEP_WAIT = StepDef(
    id="wait",
    title="Wait for Completion",
    actions=[
        "WAIT for all sub-agents to complete.",
        "",
        "Collect results from each sub-agent:",
        "",
        "MODE 1 response format:",
        "  - FILE: <path>   -> successful conversion",
        "    TITLE: <title> -> paper title (for filename)",
        "    DATE: <date>   -> submission date YYYY-MM-DD (for filename)",
        "  - FAIL: <reason> -> conversion failed",
        "",
        "MODE 2 response format:",
        "  - FILE: <path>   -> successful conversion (no TITLE/DATE)",
        "    dest_file: already known from dispatch",
        "  - FAIL: <reason> -> conversion failed",
        "",
        "Build results summary:",
        "```",
        "mode: 1 or 2",
        "results:",
        "  - arxiv_id: 2503.05179",
        "    status: success",
        "    temp_path: /tmp/arxiv_2503.05179/cleaned.md",
        "    title: 'Pruning the Unsurprising'  # MODE 1 only",
        "    date: 2025-03-08                   # MODE 1 only",
        "    dest_file: /path/to/dest.md       # MODE 2 only",
        "  - arxiv_id: 2401.12345",
        "    status: failed",
        "    reason: PDF-only submission",
        "```",
    ],
)

STEP_FINALIZE = StepDef(
    id="finalize",
    title="Finalize",
    actions=[
        "For each SUCCESSFUL conversion:",
        "",
        "MODE 1 (dest_file NOT provided - construct filename from metadata):",
        "",
        "1. CONSTRUCT FILENAME from metadata:",
        "",
        "   Format: YYYY-MM-DD Title - Subtitle.md",
        "",
        "   Transformation steps:",
        "   a) Start with DATE from sub-agent (already YYYY-MM-DD)",
        "   b) Take TITLE from sub-agent",
        "   c) Replace ? ; : with ' - ' (space-dash-space)",
        "      'Foo: Bar Baz' -> 'Foo - Bar Baz'",
        "      'What? Why; How:' -> 'What - Why - How -'",
        "   d) Remove characters unsafe for filenames: / \\ < > | \" *",
        "   e) Collapse multiple spaces to single space",
        "   f) Trim leading/trailing whitespace",
        "   g) Concatenate: '<date> <title>.md'",
        "",
        "   Example:",
        "     title: 'Pruning the Unsurprising: Efficient LLM Reasoning via First-Token Surprisal'",
        "     date: 2026-01-08",
        "     result: '2026-01-08 Pruning the Unsurprising - Efficient LLM Reasoning via First-Token Surprisal.md'",
        "",
        "   FALLBACK: If title/date missing, use <arxiv_id>.md",
        "",
        "2. Copy the cleaned.md to target:",
        "   ```bash",
        "   cp /tmp/arxiv_<id>/cleaned.md './<constructed_filename>'",
        "   ```",
        "   Note: Quote the filename - it contains spaces.",
        "",
        "=" * 60,
        "",
        "MODE 2 (dest_file WAS provided - copy to pre-determined destination):",
        "",
        "1. Copy the cleaned.md to dest_file:",
        "   ```bash",
        "   cp /tmp/arxiv_<id>/cleaned.md '<dest_file>'",
        "   ```",
        "",
        "   The dest_file was determined in step 1 and passed to sub-agent.",
        "   No filename construction needed.",
        "",
        "=" * 60,
        "",
        "VERIFICATION (both modes):",
        "  - Use Read tool to confirm file exists and has content",
        "",
        "PRESENT FINAL SUMMARY to user:",
        "```",
        "Processed M PDFs: N converted, K skipped (already exist), F failed",
        "",
        "Skipped (already exist):",
        "  2025-01-08 Pruning the Unsurprising -> already exists",
        "",
        "Converted:",
        "  [OK] 2025-01-10 New Paper Title -> ./2025-01-10 New Paper Title.md",
        "",
        "Failed:",
        "  [FAIL] 2024-12-15 Some Paper -> PDF-only submission (no TeX source)",
        "```",
    ],
)

# Workflow definition
WORKFLOW = Workflow(
    "arxiv-to-md",
    STEP_DISCOVER,
    STEP_WAIT,
    STEP_FINALIZE,
    description="Convert arXiv papers to LLM-consumable markdown",
    validate=False,
)


def format_output(step: int, step_def: StepDef, is_step_one: bool = False) -> str:
    """Format output using AST builder API."""
    parts = []

    # Step header
    title = f"ARXIV-TO-MD - {step_def.title}"
    parts.append(render_step_header(StepHeaderNode(
        title=title,
        script="arxiv_to_md",
        step=str(step),
    )))
    parts.append("")

    # XML format mandate on first step
    if is_step_one:
        parts.append("""<xml_format_mandate>
CRITICAL: All script outputs use XML format. You MUST:
1. Execute the action in <current_action>
2. When complete, invoke the exact command in <invoke_after>
3. DO NOT skip steps.
</xml_format_mandate>""")
        parts.append("")

    # Current action (with dispatch node substitution)
    actions = []
    for action in step_def.actions:
        if action == "PLACEHOLDER_MODE1_DISPATCH":
            mode1_template = """Convert this arXiv paper to markdown.

arXiv ID: $ARXIV_ID

Start: <invoke working-dir=".claude/skills/scripts" cmd="python3 -m skills.arxiv_to_md.sub_agent --step 1 --arxiv-id $ARXIV_ID" />

<expected_output>
Sub-agent responds with ONLY:

On success:
FILE: <path-to-markdown>
TITLE: <paper title>
DATE: <YYYY-MM-DD>

On failure:
FAIL: <reason>
</expected_output>"""
            mode1_node = TemplateDispatchNode(
                agent_type="general-purpose",
                template=mode1_template,
                targets=({"ARXIV_ID": "EXAMPLE"},),
                command=f'python3 -m {SUBAGENT_MODULE} --step 1 --arxiv-id $ARXIV_ID',
                model="opus",
                instruction="Launch one sub-agent per arXiv ID.\nUse a SINGLE message with multiple Task tool calls.\n\nThese markdown files become the scientific basis for downstream work.\nCost of error amplifies: subpar markdown -> subpar knowledge."
            )
            actions.append(render_template_dispatch(mode1_node))
        elif action == "PLACEHOLDER_MODE2_DISPATCH":
            mode2_template = """Convert this arXiv paper to markdown.

arXiv ID: $ARXIV_ID
Destination: $DEST_FILE

Start: <invoke working-dir=".claude/skills/scripts" cmd="python3 -m skills.arxiv_to_md.sub_agent --step 1 --arxiv-id $ARXIV_ID --dest-file '$DEST_FILE'" />

<expected_output>
Sub-agent responds with ONLY:

On success:
FILE: <path-to-markdown>

On failure:
FAIL: <reason>
</expected_output>"""
            mode2_node = TemplateDispatchNode(
                agent_type="general-purpose",
                template=mode2_template,
                targets=({"ARXIV_ID": "EXAMPLE", "DEST_FILE": "EXAMPLE"},),
                command=f'python3 -m {SUBAGENT_MODULE} --step 1 --arxiv-id $ARXIV_ID --dest-file \'$DEST_FILE\'',
                model="opus",
                instruction="Launch one sub-agent per arXiv ID.\nUse a SINGLE message with multiple Task tool calls.\n\nThese markdown files become the scientific basis for downstream work.\nCost of error amplifies: subpar markdown -> subpar knowledge."
            )
            actions.append(render_template_dispatch(mode2_node))
        else:
            actions.append(action)

    parts.append(render_current_action(CurrentActionNode(actions)))
    parts.append("")

    # Next step or completion
    total_steps = 3
    if step < total_steps:
        next_step = step + 1
        next_cmd = f'python3 -m {MODULE_PATH} --step {next_step}'
        parts.append(render_invoke_after(InvokeAfterNode(cmd=next_cmd)))
    else:
        parts.append("WORKFLOW COMPLETE - Present results to user.")

    return "\n".join(parts)


def main():
    parser = argparse.ArgumentParser(
        description="arxiv-to-md orchestrator",
        epilog="Steps: discover (1) -> wait (2) -> finalize (3)",
    )
    parser.add_argument("--step", type=int, required=True, help="Current step (1-3)")
    args = parser.parse_args()

    total = WORKFLOW.total_steps

    if args.step < 1 or args.step > total:
        sys.exit(f"ERROR: --step must be 1-{total}, got {args.step}")

    # Map step number to step definition
    step_ids = list(WORKFLOW.steps.keys())
    step_id = step_ids[args.step - 1]
    step_def = WORKFLOW.steps[step_id]

    output = format_output(args.step, step_def, is_step_one=(args.step == 1))
    print(output)


if __name__ == "__main__":
    main()
