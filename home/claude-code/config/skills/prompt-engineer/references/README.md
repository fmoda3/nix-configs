# Reference Selection Guide

These reference documents contain research-backed prompt engineering techniques
organized by problem type. Each file synthesizes findings from multiple papers
into actionable guidance.

## Decision Tree

```
What is your PRIMARY problem?
|
+-> INPUT issues (context too long/noisy/missing)?
|   YES -> context/reframing.md or context/augmentation.md
|
+-> OUTPUT issues:
    |
    +-> Model can't reason through problem -> reasoning/*.md
    +-> Model reasons but wrong answers   -> correctness/*.md
    +-> Output too verbose/expensive      -> efficiency.md
    +-> Need specific format              -> structure.md
```

## Navigation Anti-patterns

Avoid reading these directly:

- `papers/**/*.md` - Source paper summaries, too granular for optimization workflow
- `papers/**/*.yaml` - Paper metadata, not actionable guidance
- `papers/**/*.pdf` - Original papers, not consumable

The reference files here synthesize those papers into actionable techniques.

## Usage in Prompt Optimization Workflow

The optimize.py script selects references based on diagnosed problem:

1. **Triage** determines scope (single-prompt, ecosystem, greenfield, problem)
2. **Assess/Diagnose** identifies the specific failure mode
3. **Plan/Design** reads relevant references based on failure mode:
   - Reasoning failures -> reasoning/\*.md
   - Consistency failures -> correctness/\*.md
   - Context issues -> context/\*.md
   - Verbosity issues -> efficiency.md
   - Format issues -> structure.md
