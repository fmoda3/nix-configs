#!/usr/bin/env python3
"""arxiv-to-md sub-agent: Convert a single arXiv paper to markdown.

Arguments:
  --arxiv-id   Required. The arXiv ID to convert (YYMM.NNNNN format).
  --dest-file  Optional. When provided by orchestrator, skip metadata extraction.
               The orchestrator has already determined the destination filename.

6-step workflow:
  1. Fetch     - Download and extract arXiv source; extract metadata if --dest-file not provided
  2. Preprocess - Expand inputs, normalize encoding
  3. Convert   - TeX to markdown via pandoc
  4. Clean     - Inventory sections, remove unwanted
  5. Verify    - Factored verification: source vs output
  6. Validate  - Check output quality, return FILE: (+ TITLE/DATE if no --dest-file) or FAIL:
"""

import argparse
import sys

from skills.lib.workflow.ast import W, XMLRenderer, render
from skills.lib.workflow.ast.nodes import (
    TextNode, StepHeaderNode, CurrentActionNode, InvokeAfterNode,
)
from skills.lib.workflow.ast.renderer import (
    render_step_header, render_current_action, render_invoke_after,
)


MODULE_PATH = "skills.arxiv_to_md.sub_agent"


PHASES = {
    1: {
        "title": "Fetch",
        "brief": "Download and extract arXiv source",
        "actions": [
            "Create working directory and download source:",
            "  mkdir -p /tmp/arxiv_<id>",
            "  curl -L https://arxiv.org/e-print/<id> -o /tmp/arxiv_<id>/source.tar.gz",
            "",
            "Extract the tarball:",
            "  cd /tmp/arxiv_<id> && tar -xzf source.tar.gz",
            "",
            "Find the main .tex file:",
            "  - Use Glob tool to find *.tex files",
            "  - Use Read tool to identify which contains \\documentclass",
            "  - Common names: main.tex, paper.tex, <arxiv_id>.tex",
            "",
            "IF NO .tex FILES FOUND (PDF-only submission):",
            "  Try older versions - TeX source may exist in earlier revisions.",
            "  arXiv IDs support version suffix: <id>v1, <id>v2, etc.",
            "",
            "  1. Check https://arxiv.org/abs/<id> to find available versions",
            "  2. Try downloading older versions in reverse order:",
            "     curl -L https://arxiv.org/e-print/<id>v<N-1> -o source.tar.gz",
            "  3. Stop when you find a version with .tex source",
            "  4. If no version has TeX source, respond: FAIL: PDF-only submission",
            "",
            "EXTRACT PAPER METADATA (only when --dest-file NOT provided):",
            "",
            "IF --dest-file was NOT provided:",
            "  1. TITLE - Extract from the main .tex file:",
            "     - Look for \\title{...} command",
            "     - May span multiple lines: \\title{First Line",
            "         Second Line}",
            "     - Strip LaTeX commands (\\textbf, \\emph, etc.)",
            "     - Collapse whitespace to single spaces",
            "     - Handle subtitles: if title contains ':' keep it",
            "",
            "  2. DATE - Fetch submission date from arXiv abstract page:",
            "     - Use WebFetch on https://arxiv.org/abs/<id>",
            "     - Find the first submission date (not revision date)",
            "     - Format: look for 'Submitted' or '[v1]' date",
            "     - Convert to YYYY-MM-DD format",
            "",
            "IF --dest-file WAS provided:",
            "  Skip metadata extraction - orchestrator already determined filename.",
            "",
            "OUTPUT:",
            "```",
            "source_dir: /tmp/arxiv_<id>",
            "main_tex: <filename>.tex",
            "version: <vN if not latest>",
            "paper_title: <extracted title>      # only if --dest-file not provided",
            "submission_date: YYYY-MM-DD         # only if --dest-file not provided",
            "```",
        ],
    },
    2: {
        "title": "Preprocess",
        "brief": "Expand inputs, normalize encoding",
        "actions": [
            "Run TeX preprocessing via Bash tool:",
            "",
            "```bash",
            "python3 << 'EOF'",
            "import sys",
            "sys.path.insert(0, '/Users/lmergen/.claude/skills/scripts')",
            "from skills.arxiv_to_md.tex_utils import preprocess_tex",
            "",
            "result = preprocess_tex('<source_dir>/<main_tex>')",
            "print(f'Preprocessed: {result}')",
            "EOF",
            "```",
            "",
            "This:",
            "  - Expands \\input{} and \\include{} statements recursively",
            "  - Inlines .bbl bibliography file (if present) for citation resolution",
            "  - Normalizes encoding to UTF-8",
            "",
            "OUTPUT:",
            "```",
            "preprocessed: <source_dir>/preprocessed.tex",
            "```",
        ],
    },
    3: {
        "title": "Convert",
        "brief": "TeX to markdown via pandoc",
        "actions": [
            "Run conversion via Bash tool:",
            "",
            "```bash",
            "pandoc <source_dir>/preprocessed.tex -f latex -t markdown --wrap=none -o <source_dir>/raw.md",
            "```",
            "",
            "Math formulas ($...$ and $$...$$) are preserved automatically.",
            "",
            "OUTPUT:",
            "```",
            "raw_md: <source_dir>/raw.md",
            "```",
        ],
    },
    4: {
        "title": "Clean",
        "brief": "Inventory sections, remove unwanted",
        "actions": [
            "Use the Read tool on <source_dir>/raw.md.",
            "",
            "INVENTORY - Extract all section headings from raw.md:",
            "  List every heading (# through ####) in document order.",
            "  Tag each as:",
            "    [REMOVE] - References, Bibliography, Acknowledgments, Acknowledgements",
            "    [KEEP]   - Everything else",
            "",
            "THEN perform cleaning:",
            "",
            "REMOVE these sections:",
            "  - References / Bibliography",
            "    (heading + all content until next heading or EOF)",
            "  - Acknowledgements / Acknowledgments",
            "    (heading + all content until next heading or EOF)",
            "",
            "REPLACE image references with placeholders:",
            "  - ![alt](path) patterns -> [IMAGE: alt or filename]",
            "  - Preserve figure captions in placeholder text",
            "",
            "PRESERVE everything else:",
            "  - Abstract, Introduction, Methods, Results, Conclusion, Discussion",
            "  - All math formulas ($ and $$ delimiters)",
            "  - Tables with their content and formatting",
            "  - Inline citations [1], [2], etc.",
            "",
            "WRAP remnant LaTeX for LLM comprehension:",
            "  - Any unconverted LaTeX (tables, environments) -> wrap in ```latex blocks",
            "  - Mathematical equations ($...$, $$...$$) -> wrap in ```latex blocks",
            "  - This hints to LLMs how to interpret the content",
            "  Example:",
            "    Before: The loss is $L = \\sum_i (y_i - \\hat{y}_i)^2$",
            "    After:  The loss is ```latex $L = \\sum_i (y_i - \\hat{y}_i)^2$ ```",
            "",
            "CONVERT pandoc citation markers:",
            "  - [@key] patterns -> [key] (strip the @ symbol)",
            "  - [@key1; @key2] -> [key1; key2]",
            "  - This removes pandoc-specific syntax while preserving citation intent",
            "",
            "Use the Write tool to save to <source_dir>/cleaned.md.",
            "",
            "OUTPUT:",
            "```",
            "sections_inventory:",
            "  - [KEEP] Abstract",
            "  - [KEEP] Introduction",
            "  - [KEEP] Methods",
            "  - ... (all sections in order)",
            "  - [REMOVE] Acknowledgments",
            "  - [REMOVE] References",
            "",
            "cleaned_md: <source_dir>/cleaned.md",
            "sections_removed: [list of heading names]",
            "images_replaced: <count>",
            "```",
        ],
    },
    5: {
        "title": "Verify Completeness",
        "brief": "Factored verification: source vs output",
        "actions": [
            "FACTORED VERIFICATION (source-based checking)",
            "",
            "For EACH [KEEP] section from step 4 inventory:",
            "  1. Open-ended verification question (NOT yes/no):",
            "     'What content appears under [Section Name] in cleaned.md?'",
            "  2. Compare against raw.md (use Read tool on both files):",
            "     - Does the section exist in cleaned.md?",
            "     - Is the content substantively present?",
            "     - Any unexpected truncation?",
            "",
            "CRITICAL: Verify against raw.md, NOT from memory.",
            "(Factored verification prevents hallucination transfer)",
            "",
            "OUTPUT:",
            "```",
            "verification_results:",
            "  - Abstract: [PRESENT] first paragraph matches",
            "  - Introduction: [PRESENT] N paragraphs preserved",
            "  - Methods: [PRESENT] N subsections intact",
            "  - ... (each [KEEP] section)",
            "",
            "content_delta:",
            "  raw_word_count: N",
            "  cleaned_word_count: M",
            "  ratio: M/N (expect 0.70-0.95)",
            "",
            "COMPLETENESS: [PASS | FAIL: <missing sections>]",
            "```",
            "",
            "If FAIL: Report missing sections and STOP.",
        ],
    },
    6: {
        "title": "Validate and Report",
        "brief": "Check output quality, return result",
        "actions": [
            "Use the Read tool on <source_dir>/cleaned.md.",
            "",
            "Validate:",
            "  1. Markdown structure intact (headings render properly)",
            "  2. Math delimiters balanced ($ and $$ counts should be even)",
            "  3. Section count matches inventory [KEEP] count",
            "  4. No raw LaTeX commands visible (\\section, \\begin, etc.)",
            "  5. Word count sanity (from step 5):",
            "     - ratio < 0.70: content may be missing",
            "     - ratio > 0.95: removal may have failed",
            "",
            "TERMINAL OUTPUT (respond with ONLY one of these):",
            "",
            "If validation PASSED:",
            "  FILE: <source_dir>/cleaned.md",
            "  IF --dest-file was NOT provided:",
            "    TITLE: <paper_title from step 1>",
            "    DATE: <submission_date from step 1>",
            "",
            "If validation FAILED:",
            "  FAIL: <concise reason>",
            "",
            "The orchestrator parses this response.",
            "Include TITLE and DATE only when --dest-file was NOT provided.",
        ],
    },
}


def main():
    parser = argparse.ArgumentParser(
        description="arxiv-to-md sub-agent: single paper conversion",
        epilog="Steps: fetch (1) -> preprocess (2) -> convert (3) -> clean (4) -> verify (5) -> validate (6)",
    )
    parser.add_argument("--step", type=int, required=True, help="Current step (1-6)")
    parser.add_argument("--arxiv-id", type=str, required=True, help="arXiv ID to convert")
    parser.add_argument(
        "--dest-file",
        type=str,
        help="Destination filename (when orchestrator determines it). Skips metadata extraction.",
    )
    args = parser.parse_args()

    if args.step < 1 or args.step > 6:
        sys.exit(f"ERROR: --step must be 1-6, got {args.step}")

    phase = PHASES[args.step]
    actions = list(phase["actions"])

    # Prepend context on step 1
    if args.step == 1:
        context_lines = [f"arXiv ID: {args.arxiv_id}"]
        if args.dest_file:
            context_lines.append(f"Destination: {args.dest_file}")
        context_lines.append("")
        actions = context_lines + actions

    # Build next invoke command
    next_step = args.step + 1
    if next_step <= 6:
        cmd_parts = [
            "python3 -m", MODULE_PATH,
            f"--step {next_step}",
            f"--arxiv-id {args.arxiv_id}"
        ]
        if args.dest_file:
            cmd_parts.append(f"--dest-file {args.dest_file}")
        cmd_str = " ".join(cmd_parts)
        next_cmd = cmd_str
    else:
        next_cmd = None  # Terminal step

    # Build output
    parts = []

    # Step header
    title = f"ARXIV-TO-MD SUB-AGENT - {phase['title']}"
    parts.append(render_step_header(StepHeaderNode(
        title=title,
        script="arxiv_to_md_sub_agent",
        step=str(args.step)
    )))
    parts.append("")

    # Current action
    parts.append(render_current_action(CurrentActionNode(actions)))
    parts.append("")

    # Next step or completion
    if next_cmd:
        parts.append(render_invoke_after(InvokeAfterNode(cmd=next_cmd)))
    else:
        parts.append("SUB-AGENT COMPLETE - Return result to orchestrator.")

    output = "\n".join(parts)
    print(output)


if __name__ == "__main__":
    main()
