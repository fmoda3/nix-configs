#!/usr/bin/env python3
"""
QR Reconciliation - Step-based workflow for quality-reviewer agent.

Determines if a milestone's acceptance criteria are already satisfied in the
current codebase. Supports resumable plan execution by detecting prior work.

Sub-agents invoke this script immediately upon receiving their prompt.
The script provides step-by-step guidance; the agent follows exactly.
"""

STEPS = {
    1: {
        "title": "Task Description",
    },
    2: {
        "title": "Extract Acceptance Criteria",
    },
    3: {
        "title": "Verify Against Codebase",
    },
    4: {
        "title": "Write Report and Return Result",
    },
}


def step_1_handler(step_info, total_steps, module_path, **kwargs):
    milestone = kwargs.get("milestone", "N")
    return {
        "title": step_info["title"],
        "actions": [
            f"TASK: Determine if Milestone {milestone}'s acceptance criteria are",
            "already satisfied in the current codebase.",
            "",
            "PURPOSE:",
            "  - Support resumable plan execution",
            "  - Detect prior work that matches requirements",
            "  - Enable skipping already-completed milestones",
            "",
            "SCOPE:",
            "  - This is NOT a full quality review",
            "  - Focus ONLY on: Are the requirements met?",
            "  - Full category-based review happens at post-implementation",
            "",
            "CONTEXT:",
            "  Plan file: (from your prompt)",
            f"  Milestone: {milestone}",
            "",
            "KEY DISTINCTION:",
            "  Validate REQUIREMENTS, not code presence.",
            "  - Code may exist but not meet criteria (done wrong)",
            "  - Criteria may be met by different code than planned (done differently but correctly)",
        ],
        "next": f"python3 -m {module_path} --step 2 --milestone {milestone}",
    }


def step_2_handler(step_info, total_steps, module_path, **kwargs):
    milestone = kwargs.get("milestone", "N")
    return {
        "title": step_info["title"],
        "actions": [
            f"READ Milestone {milestone} from the plan file.",
            "",
            "EXTRACT acceptance criteria into a checklist:",
            "",
            "```",
            f"MILESTONE {milestone} ACCEPTANCE CRITERIA:",
            "  1. [First criterion from plan]",
            "  2. [Second criterion from plan]",
            "  3. [Third criterion from plan]",
            "  ... (list ALL criteria)",
            "```",
            "",
            "WRITE this checklist before proceeding.",
            "Do NOT evaluate yet -- extraction only at this step.",
            "",
            "NOTE: If milestone has no explicit acceptance criteria,",
            "infer testable criteria from the milestone description.",
        ],
        "next": f"python3 -m {module_path} --step 3 --milestone {milestone}",
    }


def step_3_handler(step_info, total_steps, module_path, **kwargs):
    milestone = kwargs.get("milestone", "N")
    open_question_guidance = """<open_question_guidance>
PRINCIPLE: Ask open questions to avoid confirmation bias.

BAD (closed):  "Is the threshold 3?" -> biases toward yes/no
GOOD (open):   "What is the retry threshold?" -> requires finding actual value

BAD (leading): "Does it use mutex as expected?" -> assumes mutex exists
GOOD (neutral): "What synchronization primitive is used?" -> discovers reality
</open_question_guidance>"""
    return {
        "title": step_info["title"],
        "actions": [
            "FACTORED VERIFICATION (check criteria against actual code):",
            "",
            open_question_guidance,
            "",
            "For EACH criterion from Step 2:",
            "",
            "  1. STATE what you expect to find:",
            "     'Criterion: [X]'",
            "     'Expected: [specific code/behavior/file to find]'",
            "",
            "  2. SEARCH the codebase:",
            "     - Use Grep to find relevant code",
            "     - Use Read to examine candidate files",
            "     - Check if behavior matches criterion",
            "",
            "  3. RECORD finding:",
            "     'Found: [file:line] or NOT FOUND'",
            "     'Status: MET | NOT_MET'",
            "",
            "IMPORTANT:",
            "  - Verify behavior, not just code existence",
            "  - Code may exist but not satisfy the criterion",
            "  - Different implementation can satisfy same requirement",
        ],
        "next": f"python3 -m {module_path} --step 4 --milestone {milestone}",
    }


def step_4_handler(step_info, total_steps, module_path, **kwargs):
    milestone = kwargs.get("milestone", "N")
    return {
        "title": step_info["title"],
        "actions": [
            "TOKEN OPTIMIZATION: Write full report to file, return minimal output.",
            "",
            "WHY: Main agent only needs PASS/FAIL to route. Full report goes to",
            "file. Executor reads file directly. Saves ~95% tokens in main agent.",
            "",
            "STEPS:",
            "1. Create temp dir: Use Python's tempfile.mkdtemp(prefix='qr-report-')",
            "2. Write full findings (format below) to: {tmpdir}/qr.md",
            "3. Return to orchestrator:",
            "   - If SATISFIED: Return exactly 'RESULT: PASS'",
            "   - If NOT_SATISFIED or PARTIALLY_SATISFIED: Return exactly:",
            "       RESULT: FAIL",
            "       PATH: {tmpdir}/qr.md",
            "",
            "FULL REPORT FORMAT (write to file, NOT to output):",
            "",
            "```",
            f"## RECONCILIATION: Milestone {milestone}",
            "",
            "**Status**: SATISFIED | NOT_SATISFIED | PARTIALLY_SATISFIED",
            "",
            "### Acceptance Criteria Check",
            "",
            "| Criterion | Status | Evidence |",
            "|-----------|--------|----------|",
            "| [criterion from plan] | MET / NOT_MET | [file:line or 'not found'] |",
            "| [criterion from plan] | MET / NOT_MET | [file:line or 'not found'] |",
            "",
            "### Summary",
            "[If PARTIALLY_SATISFIED: list what's done and what's missing]",
            "[If NOT_SATISFIED: brief note on what needs to be implemented]",
            "```",
            "",
            "STATUS DEFINITIONS:",
            "  SATISFIED: ALL criteria MET -> RESULT: PASS (skip execution)",
            "  NOT_SATISFIED: NO criteria MET -> RESULT: FAIL (execute fully)",
            "  PARTIALLY_SATISFIED: SOME criteria MET -> RESULT: FAIL (execute missing)",
        ],
        "next": "",
    }


STEP_HANDLERS = {
    1: step_1_handler,
    2: step_2_handler,
    3: step_3_handler,
    4: step_4_handler,
}


def get_step_guidance(step: int, module_path: str = None, **kwargs) -> dict:
    """Return guidance for the given step.

    Args:
        step: Current step number (1-indexed)
        module_path: Module path for -m invocation
        **kwargs: Additional context (milestone number)
    """
    total_steps = len(STEPS)
    milestone = kwargs.get("milestone", "N")

    step_info = STEPS.get(step, {})
    handler = STEP_HANDLERS.get(step)

    if step >= total_steps:
        handler = STEP_HANDLERS.get(4)
        step_info = STEPS.get(4, {})

    if handler:
        return handler(step_info, total_steps=total_steps, module_path=module_path, **kwargs)

    return {"title": "Unknown", "actions": ["Check step number"], "next": ""}


if __name__ == "__main__":
    from skills.lib.workflow.cli import mode_main
    mode_main(
        __file__,
        get_step_guidance,
        "QR Reconciliation - Verify if milestone work is complete",
        extra_args=[
            (["--milestone"], {"type": int, "required": True, "help": "Milestone number to reconcile"})
        ]
    )
