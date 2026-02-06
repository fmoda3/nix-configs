"""CLI utilities for workflow scripts.

Handles argument parsing and mode script entry points.
"""

import argparse
from pathlib import Path
from typing import Callable

from .ast import W, XMLRenderer, render, TextNode
from .ast.nodes import StepHeaderNode, CurrentActionNode, InvokeAfterNode
from .ast.renderer import (
    render_step_header, render_current_action, render_invoke_after,
)
from .types import UserInputResponse


def _compute_module_path(script_file: str) -> str:
    """Compute module path from script file path.

    Args:
        script_file: Absolute path to script (e.g., ~/.claude/skills/scripts/skills/planner/qr/plan_completeness.py)

    Returns:
        Module path for -m invocation (e.g., skills.planner.qr.plan_completeness)
    """
    path = Path(script_file).resolve()
    parts = path.parts
    # Find 'scripts' in path and extract module path after it
    if "scripts" in parts:
        scripts_idx = parts.index("scripts")
        if scripts_idx + 1 < len(parts):
            module_parts = list(parts[scripts_idx + 1:])
            module_parts[-1] = module_parts[-1].removesuffix(".py")
            return ".".join(module_parts)
    # Fallback: just use filename
    return path.stem


def add_standard_args(parser: argparse.ArgumentParser) -> None:
    """Add standard workflow arguments."""
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument("--qr-iteration", type=int, default=1)
    parser.add_argument("--qr-fail", type=str, default=None)
    parser.add_argument(
        "--user-answer-id",
        type=str,
        help="Question ID that was answered"
    )
    parser.add_argument(
        "--user-answer-value",
        type=str,
        help="User's selected option or custom text"
    )


def get_user_answer(args) -> UserInputResponse | None:
    """Extract user answer from parsed args."""
    if args.user_answer_id and args.user_answer_value:
        return UserInputResponse(
            question_id=args.user_answer_id,
            selected=args.user_answer_value,
        )
    return None


def mode_main(
    script_file: str,
    get_step_guidance: Callable[..., dict],
    description: str,
    extra_args: list[tuple[list, dict]] = None,
):
    """Standard entry point for mode scripts.

    Args:
        script_file: Pass __file__ from the calling script
        get_step_guidance: Function that returns guidance dict for each step
        description: Script description for --help
        extra_args: Additional arguments beyond standard QR args
    """
    script_name = Path(script_file).stem
    module_path = _compute_module_path(script_file)

    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--step", type=int, required=True)
    parser.add_argument("--qr-iteration", type=int, default=1)
    parser.add_argument("--qr-fail", type=str, default=None)
    for args, kwargs in (extra_args or []):
        parser.add_argument(*args, **kwargs)
    parsed = parser.parse_args()

    guidance = get_step_guidance(
        parsed.step, module_path,
        **{k: v for k, v in vars(parsed).items()
           if k not in ('step',)}
    )

    # Handle both dict and dataclass (GuidanceResult) returns
    # Scripts use different patterns - some return dicts, others return GuidanceResult
    if hasattr(guidance, '__dataclass_fields__'):
        # GuidanceResult dataclass - convert to dict
        guidance_dict = {
            "title": guidance.title,
            "actions": guidance.actions,
            "next": guidance.next_command,
        }
    else:
        # Already a dict
        guidance_dict = guidance

    # Build step output using AST builder
    parts = []
    # step_header omits total attribute: cosmetic display ('step X of Y') never parsed
    # by consumers. Omission eliminates workflow parameter coupling in mode_main().
    parts.append(render_step_header(StepHeaderNode(
        title=guidance_dict["title"],
        script=script_name,
        step=str(parsed.step)
    )))
    if parsed.step == 1:
        parts.append("")
        parts.append("<xml_format_mandate>")
        parts.append("  All workflow output MUST be well-formed XML.")
        parts.append("  Use CDATA for code: <![CDATA[...]]>")
        parts.append("</xml_format_mandate>")
        parts.append("")
        parts.append("<thinking_efficiency>")
        parts.append("Max 5 words per step. Symbolic notation preferred.")
        parts.append('Good: "Patterns needed -> grep auth -> found 3"')
        parts.append('Bad: "For the patterns we need, let me search for auth..."')
        parts.append("</thinking_efficiency>")
    parts.append("")
    parts.append(render_current_action(CurrentActionNode(guidance_dict["actions"])))
    if guidance_dict.get("next"):
        parts.append("")
        parts.append(render_invoke_after(InvokeAfterNode(cmd=guidance_dict["next"])))
    print("\n".join(parts))
