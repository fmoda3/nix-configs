# arxiv-to-md

Convert arXiv papers (TeX source) to clean, LLM-consumable markdown.

## Architecture

```
main.py (orchestrator)          sub_agent.py (worker)
=======================         =====================
Step 1: Discover/Dispatch  ---> Step 1: Fetch
Step 2: Wait                    Step 2: Preprocess
Step 3: Finalize           <--- Step 3: Convert
                                Step 4: Clean
                                Step 5: Verify
                                Step 6: Validate -> FILE: or FAIL:
```

The orchestrator ALWAYS dispatches to sub-agents, even for a single paper. This
keeps the architecture uniform and allows parallel processing when multiple
papers are requested.

## Usage

Single paper:

```
Convert arxiv.org/abs/2503.05179 to markdown
```

Multiple papers:

```
Convert these papers to markdown: 2503.05179, 2401.12345, 2312.09876
```

## Prerequisites

- pandoc binary installed (`brew install pandoc` or equivalent)

## Invisible Knowledge

**Why always dispatch (even for single paper):**

Previous design conditionally dispatched only for multiple papers. This created
two code paths and made the orchestrator logic complex. Always dispatching:

1. Keeps orchestrator simple (no conditional branching)
2. Ensures sub-agent is always tested
3. Makes parallel processing automatic when scaling

**Why step 1 discovers from folder metadata:**

Users often invoke this skill from a directory containing paper-related files
(PDFs, .bib files, READMEs with arXiv links). Discovering IDs from context
reduces friction and avoids user having to manually extract IDs they've already
referenced elsewhere.

**Handoff minimalism:**

Sub-agent receives ONLY: arxiv_id. It doesn't know:

- How many papers are being processed
- What the orchestrator will do with the output
- Where the final file will be placed

This keeps sub-agent focused and prevents coupling.
