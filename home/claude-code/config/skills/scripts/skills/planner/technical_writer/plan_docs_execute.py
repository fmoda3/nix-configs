#!/usr/bin/env python3
"""Plan docs execution - first-time documentation workflow.

6-step workflow for technical-writer sub-agent:
  1. Task Description (context display, doc_diff architecture)
  2. Extract Planning Context (decision log, constraints, risks)
  3. Analyze Code Changes (identify documentation needs per code_change)
  4. Generate Documentation Diffs (create doc_diff for each code_change)
  5. Standalone Documentation (READMEs as doc-only code_changes)
  6. Final Validation (validate plan.json completeness)

Scope: Documentation quality only -- adding doc_diff overlays to code_changes.
This phase does NOT modify code logic.

In scope:
- doc_diff generation: unified diffs adding documentation to code_change results
- Invisible knowledge coverage: decisions -> doc_diff comments
- Temporal contamination removal from doc_diff content
- WHY-not-WHAT quality in documentation additions
- README creation as doc-only code_changes (empty diff, populated doc_diff)

Out of scope (handled by Developer in plan-code phase):
- Code correctness, compilation, types
- diff field content
- Logic changes

This is the EXECUTE script for first-time documentation.
For QR fix mode, see plan_docs_qr_fix.py.
Router (plan_docs.py) dispatches to appropriate script.
"""

from skills.lib.workflow.ast import W, XMLRenderer, render, TextNode
from skills.lib.conventions import get_convention
from skills.planner.shared.resources import (
    STATE_DIR_ARG_REQUIRED,
    get_context_path,
    render_context_file,
    validate_state_dir_requirement,
)
from skills.planner.shared.temporal_detection import format_as_prose, format_actions


STEPS = {
    1: "Task Description",
    2: "Extract Planning Context",
    3: "Analyze Code Changes",
    4: "Generate Documentation Diffs",
    5: "Standalone Documentation",
    6: "Final Validation",
}


def get_step_guidance(
    step: int, module_path: str = None, **kwargs) -> dict:
    """Return guidance for the given step."""
    MODULE_PATH = module_path or "skills.planner.technical_writer.plan_docs_execute"
    state_dir = kwargs.get("state_dir", "")

    if step == 1:
        validate_state_dir_requirement(step, state_dir)
        context_file = get_context_path(state_dir) if state_dir else None
        context_display = render_context_file(context_file) if context_file else ""
        banner = render(
            W.el("state_banner", checkpoint="TW-PLAN-SCRUB", iteration="1", mode="work").build(),
            XMLRenderer()
        )

        actions = []
        if context_display:
            actions.extend([
                "PLANNING CONTEXT (from orchestrator):",
                "",
                context_display,
                "",
            ])
        actions.extend([
            banner,
            "",
            "TYPE: PLAN_DOCS (JSON-IR with doc_diff overlay)",
            "",
            "TASK: Add documentation diffs to code_changes.",
            "",
            "DOC_DIFF ARCHITECTURE:",
            "  Developer populates code_changes[].diff with code.",
            "  Your job: populate code_changes[].doc_diff with documentation diffs.",
            "  doc_diff is a unified diff that adds documentation to the resulting file state.",
            "  Use CLI commands - DO NOT edit plan.json directly.",
            "",
            "WORKFLOW:",
            "  Steps 1-2: Extract planning context",
            "  Steps 3-4: Generate doc_diff for each code_change",
            "  Steps 5-6: Standalone documentation and validation",
            "",
            "CLI COMMANDS:",
            "",
            "  # Set doc_diff for existing code_change:",
            "  python3 -m skills.planner.cli.plan --state-dir $STATE_DIR set-doc-diff \\",
            "    --change CC-M-001-001 --version 1 --content-file /tmp/doc.diff",
            "",
            "  # Create documentation-only change (README, etc.):",
            "  python3 -m skills.planner.cli.plan --state-dir $STATE_DIR create-doc-change \\",
            "    --milestone M-001 --file path/README.md --content-file /tmp/readme.diff",
            "",
            "BATCH MODE:",
            "  python3 -m skills.planner.cli.plan --state-dir $STATE_DIR batch '[",
            "    {\"method\": \"set-doc-diff\", \"params\": {\"change\": \"CC-M-001-001\", \"version\": 1, \"content_file\": \"/tmp/d1.diff\"}, \"id\": 1},",
            "    {\"method\": \"create-doc-change\", \"params\": {\"milestone\": \"M-001\", \"file\": \"README.md\", \"content_file\": \"/tmp/r.diff\"}, \"id\": 2}",
            "  ]'",
            "",
            "Read plan.json now. Identify:",
            "  - planning_context.decisions entries",
            "  - milestones with code_changes (each needs doc_diff)",
            "  - invisible_knowledge section",
        ])

        return {
            "title": STEPS[1],
            "actions": actions,
            "next": f"python3 -m {MODULE_PATH} --step 2 --state-dir {state_dir}",
        }

    elif step == 2:
        state_dir_arg = f" --state-dir {state_dir}" if state_dir else ""
        return {
            "title": STEPS[2],
            "actions": [
                "EXTRACT from plan.json planning_context:",
                "",
                "Read plan.json and extract:",
                "  cat $STATE_DIR/plan.json | jq '.planning_context'",
                "",
                "1. DECISION LOG entries:",
                "   - WHY each architectural choice was made",
                "   - What alternatives were rejected and why",
                "   - Specific values and their sensitivity analysis",
                "",
                "2. CONSTRAINTS that shaped the design:",
                "   - Technical limitations",
                "   - Compatibility requirements",
                "   - Performance targets",
                "",
                "3. KNOWN RISKS and mitigations:",
                "   - What could go wrong",
                "   - How the design addresses each risk",
                "",
                "List decision IDs for reference:",
                "  python3 -m skills.planner.cli.plan list-decisions",
                "",
                "Write out your CONTEXT SUMMARY before proceeding:",
                "  CONTEXT SUMMARY:",
                "  - Key decisions: [list from decision_log with IDs]",
                "  - Rejected alternatives: [list with reasons]",
                "  - Constraints: [list]",
                "  - Risks addressed: [list]",
                "",
                "These decision IDs are your SOURCE for WHY comments.",
                "Comments you add MUST reference these decision_refs.",
            ],
            "next": f"python3 -m {MODULE_PATH} --step 3{state_dir_arg}",
        }

    elif step == 3:
        state_dir_arg = f" --state-dir {state_dir}" if state_dir else ""
        return {
            "title": STEPS[3],
            "actions": [
                "ANALYZE each code_change to determine documentation needs:",
                "",
                "For each code_change in plan.json:",
                "  1. READ the diff field to understand WHAT code is changing",
                "  2. IDENTIFY documentation needs:",
                "     - Module comment (new files)",
                "     - Function docstrings (all functions in diff)",
                "     - Function blocks (Tier 2: WHY for complex functions)",
                "     - Inline comments (Tier 1: WHY for non-obvious lines)",
                "",
                "  3. CROSS-REFERENCE with planning_context.decisions[]",
                "     - Each decision should appear in at least one doc_diff",
                "     - Reference format: (ref: DL-XXX) or (DL-XXX)",
                "",
                "  4. LIST documentation needed per code_change:",
                "     CC-M-001-001: module comment, 2 docstrings, 1 inline (DL-002)",
                "     CC-M-002-001: 3 docstrings, 1 function block (DL-010)",
                "",
                "This analysis drives Step 4.",
            ],
            "next": f"python3 -m {MODULE_PATH} --step 4{state_dir_arg}",
        }

    elif step == 4:
        state_dir_arg = f" --state-dir {state_dir}" if state_dir else ""
        return {
            "title": STEPS[4],
            "actions": [
                "GENERATE doc_diff for each code_change:",
                "",
                "doc_diff is a unified diff that ONLY adds documentation.",
                "It applies AFTER the code diff, to the resulting file state.",
                "",
                "EXAMPLE - Adding docstring to function in diff:",
                "```diff",
                "--- a/internal/rules/engine.go",
                "+++ b/internal/rules/engine.go",
                "@@ -13,6 +13,10 @@ func NewEngine() *Engine {",
                " }",
                " ",
                "+// CompileRules validates and compiles rules into evaluation-ready form.",
                "+// Iterates over rules calling Compile for each, as Compile takes",
                "+// singular *types.Rule. (ref: DL-010)",
                "+//",
                " func (e *Engine) CompileRules(rules []types.Rule) ([]*CompiledRule, error) {",
                "```",
                "",
                "WRITE doc_diff to temp file and apply:",
                "  cat > /tmp/doc.diff << 'EOF'",
                "  --- a/path/to/file.go",
                "  +++ b/path/to/file.go",
                "  @@ -NN,M +NN,M @@",
                "  +// Documentation here",
                "   existing_line",
                "  EOF",
                "",
                "  python3 -m skills.planner.cli.plan --state-dir $STATE_DIR set-doc-diff \\",
                "    --change CC-M-001-001 --version 1 --content-file /tmp/doc.diff",
                "",
                "TEMPORAL CONTAMINATION CHECK before writing:",
                "  - BAD: 'Added to support...', 'Now uses...', 'Changed from...'",
                "  - GOOD: Timeless present tense describing what IS",
            ],
            "next": f"python3 -m {MODULE_PATH} --step 5{state_dir_arg}",
        }

    elif step == 5:
        state_dir_arg = f" --state-dir {state_dir}" if state_dir else ""
        return {
            "title": STEPS[5],
            "actions": [
                "CREATE documentation-only changes (READMEs, etc.):",
                "",
                "READMEs are code_changes with empty diff and populated doc_diff.",
                "",
                "EXAMPLE - Creating new README:",
                "```diff",
                "--- /dev/null",
                "+++ b/internal/rules/README.md",
                "@@ -0,0 +1,15 @@",
                "+# internal/rules",
                "+",
                "+Rule compilation and evaluation engine.",
                "+",
                "+## Architecture",
                "+",
                "+Engine delegates to compile.Compile and evaluate.Evaluate.",
                "+Provides dependency injection boundary for service layer.",
                "+",
                "+## Invariants",
                "+",
                "+- CompileRules iterates, calling Compile for each rule",
                "+- No caching at engine level (caller handles per-request caching)",
                "```",
                "",
                "CREATE via CLI:",
                "  cat > /tmp/readme.diff << 'EOF'",
                "  --- /dev/null",
                "  +++ b/internal/rules/README.md",
                "  @@ -0,0 +1,N @@",
                "  +# Content here...",
                "  EOF",
                "",
                "  python3 -m skills.planner.cli.plan --state-dir $STATE_DIR create-doc-change \\",
                "    --milestone M-002 --file internal/rules/README.md \\",
                "    --content-file /tmp/readme.diff",
                "",
                "CONTENT TEST: 'Could a developer learn this by reading source files?'",
                "  - If YES: skip (redundant)",
                "  - If NO: include (invisible knowledge)",
            ],
            "next": f"python3 -m {MODULE_PATH} --step 6{state_dir_arg}",
        }

    elif step == 6:
        return {
            "title": STEPS[6],
            "actions": [
                "FINAL VALIDATION",
                "",
                "Run validation:",
                f"  python3 -m skills.planner.cli.plan validate --phase plan-docs --state-dir {state_dir}",
                "",
                "VERIFY each code_change:",
                "  [ ] Has doc_diff if it has diff (code changes need documentation)",
                "  [ ] doc_diff is valid unified diff format",
                "  [ ] No temporal contamination in doc_diff additions",
                "  [ ] Decision references (DL-XXX) present where applicable",
                "",
                "When complete, output: PASS",
            ],
            "next": "",
        }

    return {"error": f"Invalid step {step}"}


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main

    mode_main(
        __file__,
        get_step_guidance,
        "Plan-Docs-Execute: Technical writer documentation workflow",
        extra_args=[STATE_DIR_ARG_REQUIRED],
    )
