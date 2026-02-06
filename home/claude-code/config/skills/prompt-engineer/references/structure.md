# Output Structure Techniques

Structured output techniques constrain LLM responses into predictable formats
(tables, code, JSON, XML) to improve reasoning accuracy, enable programmatic
verification, and facilitate downstream processing. Use these techniques when
free-form text produces inconsistent results, when outputs require machine
parsing, or when complex reasoning benefits from explicit step organization.

---

## Tabular Chain of Thought (Tab-CoT)

**Mechanism:** Replace "let's think step by step" with a table header prompt
like `|step|subquestion|process|result|` to organize reasoning in 2D grid
format.

**When to use:**

- Multi-step arithmetic or symbolic reasoning
- Problems requiring both vertical (step progression) and horizontal (within-step
  detail) reasoning
- Zero-shot settings where explicit structure improves accuracy

**Implementation:**

- Use pipe-delimited markdown table format: `|step|subquestion|process|result|`
- Each row = one reasoning step; columns capture sub-question, process, answer
- Follow with answer extraction prompt: "the answer is"
- Works best with code-trained models (Codex-style) due to table familiarity

**Tradeoffs:**

- (+) ~2% average accuracy gain over vanilla CoT on arithmetic tasks
- (+) More concise output (28 words vs 140 for equivalent reasoning)
- (+) Task-specific columns can dramatically boost domain performance (e.g.,
  Last Letter task: 25.2% -> 72.8% with `|step|word|last letter|answer|`)
- (+) Self-consistency across 3 different schemas yields 68.2% avg (vs 62.6%
  single best)
- (-) Requires models pre-trained on tabular data
- (-) Less effective on commonsense reasoning without fixed answer patterns

---

## Program of Thoughts (PoT)

**Mechanism:** Generate Python code with semantically meaningful variable names
instead of natural language reasoning; delegate computation to interpreter.

**When to use:**

- Numerical reasoning with large numbers or high-precision floats
- Problems requiring iteration, symbolic math, or equation solving
- Tasks where LLM arithmetic errors are a primary failure mode

**Implementation:**

- Prompt model to generate executable Python (import sympy for equations)
- Use semantic variable names: `interest_rate`, `sum_in_two_years`
- Execute generated code; answer = final variable value
- For complex problems, combine with CoT: PoT computes, CoT interprets

**Tradeoffs:**

- (+) ~12% average accuracy gain over CoT (8% on math word problems, 15% on
  financial QA)
- (+) Eliminates arithmetic errors on iterative problems (50+ steps)
- (+) Symbolic solver handles polynomial/differential equations
- (+) Semantic binding is critical: removing meaningful variable names drops
  GSM8K accuracy from 71.6% to 60.2%
- (-) Requires code execution environment (security considerations)
- (-) Value grounding errors (47% of failures) harder to detect than logic errors

---

## Table as Thought

**Mechanism:** Structure reasoning within a tabular schema where rows =
sequential steps and columns = constraints/context; iteratively populate until
verification passes.

**When to use:**

- Constraint-satisfaction planning (scheduling, travel planning)
- Tasks requiring explicit constraint tracking across steps
- Problems where schema design can capture domain logic

**Implementation:**

- Schema Development: LLM designs table headers capturing problem constraints
- Table Construction: Iteratively populate rows (max 10 iterations)
- Verification: Check completeness (all constraints satisfied) and correctness
- Auto-Check: Structured format enables programmatic constraint validation

**Tradeoffs:**

- (+) 5-10% improvement on calendar scheduling over CoT
- (+) Enables external verification without LLM (auto-check constraints)
- (+) Multi-row schemas outperform single-row on capable models (GPT-4o)
- (-) Schema design is hard; LLM-generated schemas often suboptimal for complex
  tasks
- (-) Simpler models perform worse with complex schemas (GPT-4o-mini)
- (-) Requires structured output API support (OpenAI Structured Outputs)

---

## Meta Prompting

**Mechanism:** Provide structure-only templates (JSON/XML/Markdown schemas) that
define HOW to think rather than content examples showing WHAT to think.

**When to use:**

- Token-constrained settings where few-shot examples are expensive
- Fair model comparison without example selection bias
- Tasks with well-defined procedural structure (math proofs, code generation)

**Implementation:**

- Define typed schema: `{"Problem": "[question]", "Solution": {"Step 1": "...",
"Step 2": "..."}}`
- Use XML or Markdown delimiters for section boundaries
- Recursive Meta Prompting: LLM generates/refines its own meta-prompts
- Combine with output primers: end prompt with start of expected response

**Tradeoffs:**

- (+) 46% MATH accuracy with Qwen-72B base (competitive with GPT-4 CoT)
- (+) Dramatic token efficiency on batchable tasks: ~1/N API calls when N tasks
  share structure (e.g., Game of 24 with N=1362 puzzles)
- (+) Example-agnostic: no cherry-picked demonstrations
- (-) Requires careful schema design; wrong structure hurts more than helps
- (-) Less effective than few-shot when task semantics are ambiguous

---

## Prefill Technique

**Mechanism:** Prefill the assistant response with the start of the expected
output format to bypass preamble and enforce structure.

**When to use:**

- Need strict JSON/XML output without "Here's my analysis:" preamble
- Forcing enumerated lists to start mid-flow
- Continuing partial code blocks
- Ensuring immediate structured output

**Implementation:**

```
User: Classify this feedback: {{TEXT}}
Assistant: {"sentiment":"
```

Claude continues from the prefill, maintaining the JSON structure. The model
has no opportunity to add preamble because the response is already started.

- Works with any format: JSON, XML, Markdown, code blocks
- Combine with output primers (ending prompt with expected output start)
- For multi-field JSON, prefill first key: `{"field_1":"`

**Tradeoffs:**

- (+) Eliminates preamble tokens entirely
- (+) Forces consistent format without explicit instruction
- (+) Works with any model supporting assistant prefill (Claude, GPT-4)
- (-) Requires API-level access to prefill (not available in all interfaces)
- (-) Model may struggle if prefill conflicts with natural response

---

## Agent-Computer Interface (ACI) Design

**Mechanism:** Design LLM-facing interfaces with simple commands, consistent
feedback formats, and guardrails to prevent cascading errors.

**When to use:**

- Multi-turn agentic tasks (code editing, file navigation)
- Environments where standard CLI tools produce verbose/inconsistent output
- Tasks requiring iterative editing with feedback

**Implementation:**

- Simple commands: `edit <start> <end> <replacement>` vs complex sed syntax
- Concise feedback: Show only relevant lines with line numbers, omit noise
- Guardrails: Syntax linter rejects invalid edits before applying
- Context management: Collapse old observations to single-line summaries

**Tradeoffs:**

- (+) 64% relative improvement over shell-only on SWE-bench
- (+) Linting guardrails help recovery from edit errors (51.7% of trajectories
  have 1+ failed edits; agents recover 90.5% of the time on first attempt)
- (+) Consistent output format reduces parsing failures
- (-) Interface must be co-designed with task; not general-purpose
- (-) Some guardrails (e.g., lint rejection) force specific edit orderings

---

## Contextual Calibration

**Mechanism:** Estimate and correct model bias toward certain outputs by testing
with content-free inputs (e.g., "N/A") and applying inverse calibration.

**When to use:**

- Few-shot classification with imbalanced examples
- Tasks where example ordering affects predictions (recency bias)
- Label names with different pre-training frequencies (common token bias)

**Implementation:**

- Get p_cf = model probability on content-free input ("N/A", empty string,
  "[MASK]")
- Set W = diag(p_cf)^-1, apply to all predictions: q = softmax(W \* p)
- Average across multiple content-free inputs for robustness
- Apply per-prompt (calibration is contextual to example selection/order)

**Tradeoffs:**

- (+) Up to 30% absolute accuracy improvement on GPT-3
- (+) Reduces variance across prompt formats and example orderings
- (+) Zero additional training data required
- (-) Only addresses distribution shift, not reasoning quality
- (-) Less effective on generation tasks than classification

---

## Prompt Format Sensitivity

**Mechanism:** Understand that output format specifications (JSON, XML, YAML)
and minor perturbations (whitespace, greetings) measurably change predictions.

**When to use:**

- Choosing output format for data labeling pipelines
- Debugging inconsistent model behavior
- Establishing robust prompt templates

**Implementation:**

- No specified format often yields highest accuracy (ChatGPT)
- JSON format works best for code-trained models (Llama)
- Avoid XML for general LLMs: causes 5-10% accuracy drops on larger models
- Exception: Claude-specific XML patterns work well when used for structure:
  - Separation: `<data>{{INPUT}}</data>` prevents instruction/data conflation
  - Reference: Name tags descriptively, reference in prose
  - Instruction-as-tag: `<prioritize_security>...</prioritize_security>`
- Ensemble via majority vote across formats for robustness
- Avoid: jailbreak patterns (even on innocuous tasks), unnecessary tokens

**Tradeoffs:**

- (+) Awareness prevents accidental accuracy loss from format choice
- (+) Ensemble across formats yields best aggregate accuracy
- (-) No single format dominates across all models/tasks
- (-) API-enforced JSON (ChatGPT) underperforms plain JSON prompt

---

## Instructed Prompting for Noise Handling

**Mechanism:** Explicitly instruct model to ignore irrelevant context: "Feel
free to ignore irrelevant information given in the questions."

**When to use:**

- Problems with distracting information in context
- Real-world inputs that naturally contain noise
- Tasks where model incorrectly incorporates irrelevant numbers/entities

**Implementation:**

- Prepend task instruction: "Solve grade school math problems. Feel free to
  ignore irrelevant information."
- Optionally include exemplars with irrelevant context (shows how to ignore)
- Combine with self-consistency (sample multiple paths, majority vote)

**Tradeoffs:**

- (+) Significant accuracy recovery on GSM-IC (problems with distractors)
- (+) No accuracy drop on clean datasets when instruction is present
- (+) Works for both CoT and Least-to-Most prompting
- (-) Does not fully solve distractibility (fundamental limitation remains)
- (-) More exemplars can actually hurt robustness on complex tasks

---

## Directional Stimulus Prompting

**Mechanism:** Train small policy model to generate instance-specific hints
(keywords, dialogue acts, trigger phrases) that guide the LLM.

**When to use:**

- Supervised tasks where reference outputs provide training signal
- Dialogue systems requiring consistent intent/act alignment
- When you have labeled data but cannot fine-tune the main LLM

**Implementation:**

- Policy model (T5/Flan-T5) generates stimulus per input
- Stimulus types: keywords for summarization, dialogue acts for TOD, CoT
  triggers for reasoning
- Train via supervised fine-tuning, then RL with task reward (ROUGE, accuracy)
- Append stimulus to LLM prompt as hints

**Tradeoffs:**

- (+) 41% improvement on MultiWOZ with only 80 labeled dialogues
- (+) Instance-specific guidance outperforms task-level prompts
- (+) RL refinement finds stimuli better than supervised pseudo-labels
- (-) Requires training separate policy model per task
- (-) BLEU may not improve even when task success improves

---

## Decision Guidance: Choosing Techniques

**By problem type:**

- Arithmetic/symbolic reasoning -> PoT (delegate computation)
- Multi-step with intermediate structure -> Tab-CoT or Table as Thought
- Classification with format requirement -> Test formats; prefer JSON or none
- Noisy/distractor-filled context -> Instructed prompting + self-consistency
- Few-shot instability -> Contextual calibration
- Agentic/iterative tasks -> ACI design principles

**By constraint:**

- Token-limited -> Meta Prompting (structure-only, no examples)
- No code execution -> Tab-CoT or Table as Thought
- Need programmatic verification -> Table as Thought (auto-check) or PoT
- Labeled data available -> Directional Stimulus Prompting
- Must eliminate preamble -> Prefill technique

**Composability:**

- Tab-CoT + Self-consistency: Sample multiple table schemas, majority vote
- PoT + CoT: PoT computes intermediate, CoT interprets for final answer
- Meta Prompting + PoT: Structured schema that specifies code generation slots
- Table as Thought + Auto-check: Schema enables external constraint validation
- Any technique + Contextual Calibration: Apply calibration as post-processing
- Prefill + Any format technique: Prefill enforces format, technique structures content

---

## Sources

- Anthropic Prompt Engineering: docs.anthropic.com (Prefill, XML patterns)
- Tab-CoT: Jin & Lu (2023), arXiv:2305.17812
- PoT: Chen et al. (2023), arXiv:2211.12588
- Table as Thought: (2025), arXiv
- Meta Prompting: (2025), arXiv
- SWE-agent (ACI): Yang et al. (2024), arXiv
- Contextual Calibration: Zhao et al. (2021), arXiv
- Prompt Sensitivity: Salinas & Morstatter (2024), ACL
- GSM-IC (Distractibility): Shi et al. (2023), arXiv:2302.00093
- Directional Stimulus: Li et al. (2023), arXiv
- Principled Instructions: Bsharat et al. (2024), arXiv
