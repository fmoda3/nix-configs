"""CLI utilities for QR workflows.

Moved from lib/workflow/cli.py to planner/shared/qr/cli.py.

Note: --qr-iteration and --qr-fail removed. Iteration is stored in
qr-{phase}.json; fix mode detected by file state inspection.
"""

import argparse


def add_qr_args(parser: argparse.ArgumentParser) -> None:
    """Add standard QR verification arguments to argument parser.

    Used by orchestrator scripts (planner.py, executor.py, wave-executor.py)
    to ensure consistent QR-related CLI flags.
    """
    parser.add_argument("--qr-status", type=str, choices=["pass", "fail"],
                        help="QR result for gate steps")
    parser.add_argument("--qr-item", type=str,
                        help="Single item ID for verification")
    parser.add_argument("--mode", type=str,
                        choices=["decompose", "verify", "fix-guidance"],
                        help="QR workflow mode")
