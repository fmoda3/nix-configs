"""Step assembly for workflow prompts.

format_step() is the sole assembler. invoke_after logic is internal.
"""

from pathlib import Path

# SKILLS_DIR calculation matches subagent.py pattern: both modules are in
# skills/lib/workflow/prompts/, so .parent.parent.parent.parent.parent
# traverses: prompts/ -> workflow/ -> lib/ -> skills/ -> scripts/
SKILLS_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent


def format_step(body: str, next_cmd: str = "", title: str = "") -> str:
    """Assemble complete workflow step: title + body + invoke directive.

    Args:
        body: Free-form prompt content (no wrapper needed)
        next_cmd: Command for next step (empty string signals completion)
        title: Optional title rendered as "TITLE\\n======\\n\\n" header

    Returns:
        Complete step output as plain text
    """
    if title:
        header = f"{title}\n{'=' * len(title)}\n\n"
        body = header + body

    if next_cmd:
        # Working directory is explicit because CLI execution context varies.
        # Command is literal shell invocation for next step.
        invoke = (
            f"NEXT STEP:\n"
            f"    Working directory: {SKILLS_DIR}\n"
            f"    Command: {next_cmd}\n\n"
            f"Execute this command now."
        )
        return f"{body}\n\n{invoke}"

    else:
        return f"{body}\n\nWORKFLOW COMPLETE - Return the output from the step above. Do not summarize."
