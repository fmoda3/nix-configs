# papers/

Source papers organized by problem type (what they solve, not how they execute).

## Files

| File             | What                    | When to read                    |
| ---------------- | ----------------------- | ------------------------------- |
| `README.md`      | Taxonomy and navigation | Classifying papers, finding fit |
| `.gitattributes` | LFS config              | Never                           |

## Subdirectories

| Directory      | What                                         | When to read                              |
| -------------- | -------------------------------------------- | ----------------------------------------- |
| `reasoning/`   | Problem decomposition and reasoning traces   | Model can't handle complexity             |
| `correctness/` | Sampling, verification, refinement           | Model gives wrong or inconsistent answers |
| `context/`     | Reframing and augmentation                   | Context is noisy or missing information   |
| `efficiency/`  | Reduce token usage, latency, cost            | Output too verbose, inference too slow    |
| `structure/`   | Constrain output format (code, JSON, tables) | Need specific output format               |
