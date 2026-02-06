"""Temporal contamination detection criteria.

WHY: Detection questions were duplicated in two places:
- plan_docs_qr.py:158-164 (XML format for QR agent)
- plan_docs.py:203-209 (prose format for TW agent)

Both need the same criteria but different formats. This module
defines the criteria once and provides formatters for each use case.
"""

from dataclasses import dataclass

@dataclass
class DetectionQuestion:
    id: str
    text: str
    signals: list[str]
    action: str  # DELETE, TRANSFORM, EXTRACT

# WHY these 5 specific detection questions:
# These represent the exhaustive taxonomy of temporal contamination patterns.
# Each question targets a distinct failure mode:
#
# 1. CHANGE_RELATIVE: "Added X" -> Assumes reader knows previous state
#    Comments survive across refactors; "added" becomes meaningless
#
# 2. BASELINE_REFERENCE: "Instead of X" -> Compares to deleted code
#    Baseline code is gone; comparison is permanently broken
#
# 3. LOCATION_DIRECTIVE: "After line 50" -> Encodes diff application instructions
#    Line numbers change; developer can't follow stale directions
#
# 4. PLANNING_ARTIFACT: "TODO: implement" -> Future intent leaks into present code
#    Code is either done or not; "will implement" contradicts existence
#
# 5. INTENT_LEAKAGE: "Chose X deliberately" -> Documents decision process, not result
#    Future reader needs justification, not author's mental state
#
# WHY actions are prescriptive:
# - DELETE: Information is redundant with code/diff
# - TRANSFORM: Information is valuable but phrasing is temporal
# - EXTRACT: Temporal wrapper around timeless technical fact
TEMPORAL_DETECTION_QUESTIONS = [
    DetectionQuestion(
        id="CHANGE_RELATIVE",
        text="Does it describe an action taken?",
        signals=["Added", "Replaced", "Now uses"],
        action="TRANSFORM to timeless present"
    ),
    DetectionQuestion(
        id="BASELINE_REFERENCE",
        text="Does it compare to removed code?",
        signals=["Instead of", "Previously", "Replaces"],
        action="TRANSFORM to timeless present"
    ),
    DetectionQuestion(
        id="LOCATION_DIRECTIVE",
        text="Does it describe WHERE to put code?",
        signals=["After", "Before", "Insert"],
        action="DELETE (diff encodes location)"
    ),
    DetectionQuestion(
        id="PLANNING_ARTIFACT",
        text="Does it describe future intent?",
        signals=["TODO", "Will", "Planned"],
        action="DELETE or REFRAME as current constraint"
    ),
    DetectionQuestion(
        id="INTENT_LEAKAGE",
        text="Does it describe author's choice?",
        signals=["intentionally", "deliberately", "chose"],
        action="EXTRACT technical justification"
    ),
]

def format_as_xml() -> str:
    """Format detection questions as XML for QR agents."""
    lines = ['<detection_questions category="temporal-contamination">']
    for q in TEMPORAL_DETECTION_QUESTIONS:
        signals = ", ".join(f"'{s}'" for s in q.signals)
        lines.append(f'  <question id="{q.id}" text="{q.text} Signal: {signals}" />')
    lines.append('</detection_questions>')
    return "\n".join(lines)

def format_as_prose() -> str:
    """Format detection questions as prose for TW agents."""
    lines = ["For EACH comment, evaluate against 5 detection questions:"]
    for i, q in enumerate(TEMPORAL_DETECTION_QUESTIONS, 1):
        lines.append(f"  {i}. {q.text} ({q.id.lower().replace('_', ' ')})")
    return "\n".join(lines)

def format_actions() -> str:
    """Format recommended actions for each detection type."""
    lines = []
    for q in TEMPORAL_DETECTION_QUESTIONS:
        lines.append(f"  - {q.id}: {q.action}")
    return "\n".join(lines)
