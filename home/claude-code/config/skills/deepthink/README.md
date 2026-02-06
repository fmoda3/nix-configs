# DeepThink

Structured multi-step reasoning for open-ended analytical questions. Handles
questions where the answer structure is itself unknown: taxonomy design,
conceptual analysis, trade-off exploration, definitional questions.

## When to Use

Use this when the question resists predefined frameworks:

- "What's the correct way to classify X?"
- "What makes a good Y?"
- "How should I balance A versus B?"
- "What does Z actually mean in our context?"

Do NOT use for:

- Problems with verifiable answers (math, coding with test cases)
- Problems requiring external data retrieval
- Known problem types (use problem-analysis)

## Workflow Phases

Two modes: Full (14 steps) and Quick (8 steps, bypasses sub-agents).

| Phase                 | Steps | Purpose                                  |
| --------------------- | ----- | ---------------------------------------- |
| Input Processing      | 1     | Remove bias from input (S2A)             |
| Problem Understanding | 2-4   | Abstraction, characterization, analogies |
| Planning              | 5     | Sub-questions, success criteria          |
| Sub-Agent Design      | 6-8   | Design, critique, revise (Full only)     |
| Divergent Exploration | 9-11  | Dispatch, gate, aggregate (Full only)    |
| Convergent Synthesis  | 12    | Initial synthesis                        |
| Iterative Refinement  | 13    | Verification loop until confident        |
| Formatting & Output   | 14    | Format and present final answer          |

Step 3 determines mode. Quick mode jumps from step 5 directly to step 12.

## Invisible Knowledge

### Why Context Clarification First

LLM soft attention assigns probability to irrelevant context, causing factual
errors and sycophancy. Regenerating the input to extract only relevant,
unbiased portions prevents framing effects from contaminating downstream
reasoning.

### Why Abstraction Before Reasoning

Prompting for high-level concepts and first principles before addressing
specifics improves performance 7-27%. Abstraction moves UP to principles rather
than DOWN to subtasks -- distinct from decomposition.

### Why Self-Generated Analogies

Prompting to recall similar problems from training accesses parametric knowledge
that isn't retrieved without explicit prompting. Works better than providing
fixed examples because analogies are problem-specific.

### Why Factored Verification

LLMs that view their own synthesis when verifying tend to justify existing
conclusions rather than check them. Generating verification questions, then
answering them WITHOUT viewing the synthesis, produces accurate verification.
Short-form questions are more accurately answered than long-form queries.

### Why Actionable Feedback

Generic feedback ("could be stronger") fails to improve output. Feedback must
specify: ELEMENT (what), PROBLEM (why wrong), ACTION (how to fix). Changing from
actionable to generic drops performance 43.2 -> 31.2.

### Why Intermediate Insight Extraction

Multiple reasoning chains contain valuable intermediate steps even when final
conclusions are wrong. Extracting evidence from ALL chains, not just majority,
produces better synthesis than pure voting.

### Why Self-Critique Before Dispatch

Sub-agent design benefits from explicit critique. Coverage gaps, unnecessary
overlap, and inappropriate divisions are caught before expensive parallel
execution.

### Why Confidence Thresholds Not Self-Report

LLMs have no calibrated introspective access to their own certainty. Asking "how
confident are you?" produces unreliable answers. Confidence must be derived from
factual criteria about the analysis, not introspection.

### Why Iteration Cap

Analytical questions could theoretically continue forever. The cap (5
iterations) forces eventual termination while allowing sufficient depth. Balance
between shallow analysis and indefinite loops.

## Academic Grounding (Condensed)

| Pattern                  | Source                           | Key Insight                              |
| ------------------------ | -------------------------------- | ---------------------------------------- |
| Context Clarification    | S2A (Weston & Sukhbaatar, 2023)  | Regenerate input sans bias               |
| Step-Back Abstraction    | Zheng et al., ICLR 2024          | Principles before specifics: +7-27%      |
| Explicit Planning        | Plan-and-Solve (Wang, ACL 2023)  | Missing-step errors: 12% -> 3%           |
| Self-Generated Exemplars | Analogical (Yasunaga, ICLR 2024) | Own analogies beat provided examples     |
| Metacognitive Stages     | Wang & Zhao, NAACL 2024          | Five-stage evaluation: +26.9%            |
| Anti-Pattern Generation  | Contrastive CoT (Chia, 2023)     | Knowing what NOT to do: +10-16pts        |
| Parallel Perspectives    | Multi-Agent Debate (Du, ICML 24) | Diverse viewpoints beat single-agent     |
| Generate-Critique-Revise | Self-Refine (Madaan, NeurIPS 23) | Actionable feedback: +5-40%              |
| Factored Verification    | Chain-of-Verification (Meta, 23) | Independent verification: 17% -> 70%     |
| Complex Reasoning        | Complexity-Based (Fu, ICLR 2023) | More steps = better: +5.3-18%            |
| Intermediate Extraction  | MCR (Yoran, 2024)                | All chains have value, not just majority |

## Output Formats

Final output adapts to question type (determined in Step 3):

- **Taxonomy**: Structure + rationale + edge cases + alternatives rejected
- **Trade-off**: Dimensions + balance point + shift conditions + framework
- **Definitional**: Definition + boundaries + adjacent concepts + misunderstandings
- **Evaluative**: Criteria + assessment + confidence + change conditions
- **Exploratory**: Landscape + framework + promising directions + gaps

## Implementation Notes

The workflow uses `skills.lib.workflow.formatters.text` for output formatting.
Step 5 generates different invoke_after based on mode (quick vs full). Step 13
uses `--iteration` parameter computed by the script, with MAX_ITERATIONS=5
hardcoded.
