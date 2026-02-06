# Code Quality Guidelines

Prompts for LLM agents detecting code smells. Organized by cognitive mode:

| File                               | Cognitive Mode                       | Categories |
| ---------------------------------- | ------------------------------------ | ---------- |
| `01-naming-and-types.md`           | "Do names and types express intent?" | 5          |
| `02-structure-and-composition.md`  | "Is this well-structured?"           | 5          |
| `03-patterns-and-idioms.md`        | "Is this idiomatic?"                 | 5          |
| `04-repetition-and-consistency.md` | "Is this DRY and consistent?"        | 5          |
| `05-documentation-and-tests.md`    | "Is this documented and tested?"     | 4          |
| `06-module-and-dependencies.md`    | "Are boundaries clean?"              | 2          |
| `07-cross-file-consistency.md`     | "Is this consistent across files?"   | 4          |
| `08-codebase-patterns.md`          | "What patterns are emerging?"        | 3          |

## Applicability Matrix

| Group                       | Design Review | Diff Review | Codebase Review | Refactor Design | Refactor Code |
| --------------------------- | :-----------: | :---------: | :-------------: | :-------------: | :-----------: |
| 01 Naming & Types           |      Yes      |     Yes     |       Yes       |       Yes       |      Yes      |
| 02 Structure & Composition  |      Yes      |     Yes     |       Yes       |       Yes       |      Yes      |
| 03 Patterns & Idioms        |      No       |     Yes     |       Yes       |       No        |      Yes      |
| 04 Repetition & Consistency |      No       |     Yes     |       Yes       |       No        |      Yes      |
| 05 Documentation & Tests    |      No       |     Yes     |       Yes       |       No        |      Yes      |
| 06 Module & Dependencies    |      Yes      |     No      |       Yes       |       Yes       |      Yes      |
| 07 Cross-file Consistency   |      Yes      |     No      |       Yes       |       Yes       |      Yes      |
| 08 Codebase Patterns        |      No       |     No      |       Yes       |       No        |      Yes      |

**Phase definitions**:

- **Design Review**: Evaluating Code Intent before diffs exist
- **Diff Review**: Evaluating proposed code changes in plan
- **Codebase Review**: Evaluating code after implementation
- **Refactor Design**: Analyzing architecture/intent quality in existing code
- **Refactor Code**: Analyzing implementation quality in existing code

## Format Rationale

Each document has a primer followed by numbered categories:

```markdown
# [Group Name]

[PRIMER: 2-3 paragraphs grounding the cognitive mode]

## Applicability

[Table showing which phases this document applies to]

## Evaluation Modes

<design-mode>...</design-mode>
<code-mode>...</code-mode>

---

## 1. Category Name

<principle>
Abstract rule unifying all examples. Stated first to prime generalization.
</principle>

Detect: Detection question framing the evaluation lens.

<grep-hints>
Terms that sometimes indicate issues (starting points, not definitive):
`pattern1`, `pattern2`
</grep-hints>

<violations>
Illustrative patterns (not exhaustive) -- similar violations exist:

[severity] Category label

- Example with "e.g." prefix
- Open-ended: "Any X that causes Y"
  </violations>

<exceptions>
Boundary cases with principle-based test.
</exceptions>

<threshold>
Severity bar for flagging.
</threshold>
```

### Why This Works

| Feature                           | Mechanism                                               |
| --------------------------------- | ------------------------------------------------------- |
| Primer first                      | Establishes cognitive mode before categories            |
| `<principle>` first per category  | Primacy effect -- early content shapes interpretation   |
| "starting points, not definitive" | Hedging breaks literal anchoring                        |
| "e.g.," prefix                    | Signals exemplification vs enumeration                  |
| Open-ended escape hatch           | Keeps violation list unbounded                          |
| XML semantic markers              | Structure for LLM; transparent to line-range extraction |

## Integration

Skills extract sections by line range (regex: `^## \d+\. (.+)$`). Content within sections is free-form -- parser extracts raw text, LLM interprets structure.

### Skill Prompt Additions

Wrap extracted blocks with:

```
<interpretation>
Examples illustrate a PRINCIPLE, not exhaustive checklist.
Detect ANY violation of the principle, including unlisted patterns.
</interpretation>
```

Add analogical prompting after block:

```
GENERALIZATION:
Before searching, identify 2-3 OTHER patterns violating the SAME principle.
Search for BOTH listed exemplars AND self-generated patterns.
```

This triggers domain-specific recall, enabling transfer beyond listed examples.

---

## Invisible Knowledge: Design Decisions

### Why 8 Documents?

These documents are organized by **cognitive mode** -- what the evaluator is
looking at and how they reason about it. This enables:

1. **Focused agents**: Refactor agents receive ONE category from a document.
   The document primer establishes cognitive mode; the category provides focus.

2. **Comprehensive QR**: QR agents receive an ENTIRE document. All categories
   in a document use the same cognitive mode, so checking multiple categories
   in one pass is efficient.

3. **Progressive disclosure**: Python scripts inject role/context first, then
   the document primer grounds the cognitive mode, then categories provide
   specifics.

### Why Split Categories?

Three categories (Zombie Code, Naming Consistency, Error Pattern Consistency)
have both file-scope and codebase-scope variants. These are split because:

- **File-scope**: Checkable on individual diffs. Used by Diff Review.
- **Codebase-scope**: Requires full codebase view. Used by Codebase Review/Refactor.

Asking a Diff Review agent to find codebase-wide issues is impossible; asking a
Refactor agent to ignore codebase-wide patterns wastes its capabilities.

Split assignments:

| Category                  | File Scope                                        | Codebase Scope                               |
| ------------------------- | ------------------------------------------------- | -------------------------------------------- |
| Zombie Code               | Group 03 (commented blocks, unreachable branches) | Group 08 (0-reference exports, dead modules) |
| Naming Consistency        | Group 01 (same file, different names)             | Group 07 (cross-module drift)                |
| Error Pattern Consistency | Group 04 (within-class inconsistency)             | Group 07 (cross-abstraction-level)           |

### Design vs Code Facets

Each document has two evaluation modes:

- **Design-mode**: For evaluating Code Intent at Design Review. Checks whether
  the proposed design exhibits the smell, based on description alone.

- **Code-mode**: For evaluating actual code at Diff Review, Codebase Review,
  or Refactor. Checks whether the implementation exhibits the smell.

Groups 03, 05 have no design facet (require actual code). Groups 01, 02, 06, 07
have both facets. Groups 04, 08 have partial design facets.

### Which Agents Use Which Documents?

| Phase           | Documents      | Mode   | Agent Model                                  |
| --------------- | -------------- | ------ | -------------------------------------------- |
| Design Review   | 01, 02, 06, 07 | design | 4 parallel QR agents (one per doc)           |
| Diff Review     | 01-05          | code   | 5 parallel QR agents (one per doc)           |
| Codebase Review | 01-08          | code   | 8 parallel QR agents (one per doc)           |
| Refactor Design | 01, 02, 06, 07 | design | N parallel Explore agents (one per category) |
| Refactor Code   | 01-08          | code   | N parallel Explore agents (one per category) |

Each QR agent receives ONE full document and checks all categories within it.
Each Refactor agent receives ONE category (random sampling from documents).

### Machine-Parseable Metadata

Each document contains applicability metadata in an HTML comment at line 1:

```markdown
<!-- applicable_phases: design_review, diff_review, codebase_review, refactor_design, refactor_code -->
```

This approach was chosen for several reasons:

1. **No external dependencies**: HTML comments can be parsed with stdlib regex,
   avoiding dependencies on YAML/TOML parsers or frontmatter libraries.

2. **Invisible to readers**: The metadata doesn't clutter the visible document
   structure, keeping the primer as the first visible content.

3. **Single source of truth**: The evaluation mode (design vs code) is derived
   from the phase. If a phase maps to design mode, the extraction function
   uses `<design-mode>` content; if it maps to code mode, it uses `<code-mode>`
   content.

The extraction function (`lib/workflow/quality_docs.py`) works as follows:

```python
def extract_content(doc_path: Path, phase: Phase) -> ExtractedContent | None:
    """Extract phase-appropriate content from code quality document.

    Returns None if document doesn't apply to this phase.
    Returns ExtractedContent with primer, mode guidance, and categories otherwise.
    """
    content = doc_path.read_text()

    # Parse applicability from HTML comment
    phases = _extract_applicable_phases(content)
    if phase.value not in phases:
        return None

    # Derive mode from phase
    mode = PHASE_TO_MODE[phase]

    # Extract sections
    primer = _extract_primer(content)
    mode_guidance = _extract_mode_content(content, mode)
    categories = _extract_categories(content)

    return ExtractedContent(primer, mode_guidance, categories)
```

The `PHASE_TO_MODE` mapping ensures mode is always derived consistently:

```python
PHASE_TO_MODE = {
    Phase.DESIGN_REVIEW: Mode.DESIGN,
    Phase.DIFF_REVIEW: Mode.CODE,
    Phase.CODEBASE_REVIEW: Mode.CODE,
    Phase.REFACTOR_DESIGN: Mode.DESIGN,
    Phase.REFACTOR_CODE: Mode.CODE,
}
```

This design makes it impossible for mode and phase to become inconsistent,
since mode is computed from phase rather than stored separately.
