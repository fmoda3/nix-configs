# code-quality/

Code quality checks for LLM-assisted development, organized by cognitive mode.

## Files

| File                               | What                                               | When to read                                                     |
| ---------------------------------- | -------------------------------------------------- | ---------------------------------------------------------------- |
| `README.md`                        | Format rationale, integration, invisible knowledge | Understanding document format, modifying categories              |
| `01-naming-and-types.md`           | Names and types expressing intent                  | Understanding naming, domain modeling, type design               |
| `02-structure-and-composition.md`  | Code structure and composition                     | Understanding function composition, control flow, error handling |
| `03-patterns-and-idioms.md`        | Idiomatic patterns                                 | Understanding expression patterns, modern idioms, dead code      |
| `04-repetition-and-consistency.md` | DRY and consistency                                | Understanding duplication, validation, business rules            |
| `05-documentation-and-tests.md`    | Documentation and tests                            | Understanding docs, tests, schema coherence                      |
| `06-module-and-dependencies.md`    | Module boundaries                                  | Understanding module structure, architecture                     |
| `07-cross-file-consistency.md`     | Cross-file consistency                             | Understanding interface, naming, error consistency               |
| `08-codebase-patterns.md`          | Codebase-wide patterns                             | Understanding comprehension, abstraction opportunities           |

## Applicability Quick Reference

| Document                      | Design Review | Diff Review | Codebase Review | Refactor Design | Refactor Code |
| ----------------------------- | :-----------: | :---------: | :-------------: | :-------------: | :-----------: |
| 01-naming-and-types           |      Yes      |     Yes     |       Yes       |       Yes       |      Yes      |
| 02-structure-and-composition  |      Yes      |     Yes     |       Yes       |       Yes       |      Yes      |
| 03-patterns-and-idioms        |      No       |     Yes     |       Yes       |       No        |      Yes      |
| 04-repetition-and-consistency |      No       |     Yes     |       Yes       |       No        |      Yes      |
| 05-documentation-and-tests    |      No       |     Yes     |       Yes       |       No        |      Yes      |
| 06-module-and-dependencies    |      Yes      |     No      |       Yes       |       Yes       |      Yes      |
| 07-cross-file-consistency     |      Yes      |     No      |       Yes       |       Yes       |      Yes      |
| 08-codebase-patterns          |      No       |     No      |       Yes       |       No        |      Yes      |
