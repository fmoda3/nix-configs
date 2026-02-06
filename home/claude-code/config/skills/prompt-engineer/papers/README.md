# Prompt Engineering Paper Taxonomy

This directory contains prompt engineering papers organized by the problem they solve, not how they execute. Each category answers "when I have problem X, use papers from Y."

## Why This Taxonomy

The original organization (single-turn, multi-turn, subagent) had 27-66% cross-category overlap because execution topology is orthogonal to problem type. A decomposition technique solves complexity whether it runs in one turn or many.

This problem-driven taxonomy reduces overlap to near-zero by classifying papers based on their primary intervention type from YAML metadata.

## Categories

### reasoning/ (41 papers, 32%)

**When to use:** Model fails to work through complex problems systematically -- skips steps, can't handle multi-hop questions, or doesn't show its work.

**Subcategories:**

- `decomposition/` (24 papers): Break problems into sub-problems
- `elicitation/` (17 papers): Draw out step-by-step reasoning

**Representative papers:**

- Least-to-Most Prompting -- Canonical decomposition; breaks complex problems into simpler sub-questions solved sequentially
- Large Language Models are Zero-Shot Reasoners -- Foundational elicitation; the original "Let's think step by step" paper
- Cumulative Reasoning -- Advanced decomposition with progressive knowledge building across reasoning steps

**Not for:**

- Model reasons correctly but gives wrong final answers -> use correctness/
- Output is too long, not reasoning quality -> use efficiency/
- Model lacks knowledge to reason with -> use context/

---

### correctness/ (38 papers, 29%)

**When to use:** Model produces errors, inconsistent answers, or unverified claims -- the reasoning may look fine but the output is unreliable.

**Subcategories:**

- `sampling/` (17 papers): Generate multiple candidates, aggregate via voting
- `verification/` (16 papers): Explicit checking steps that catch errors
- `refinement/` (5 papers): Feedback loops that incrementally improve output

**Representative papers:**

- Self-Consistency -- Canonical sampling; majority vote across multiple reasoning paths
- Chain-of-Verification -- Canonical verification; explicit fact-checking steps before final output
- Self-Refine -- Canonical refinement; iterative self-feedback and improvement loop

**Not for:**

- Model can't reason through the problem at all -> use reasoning/ first
- Errors are due to missing context/knowledge -> use context/
- Accuracy is acceptable but cost is too high -> use efficiency/

---

### context/ (21 papers, 16%)

**When to use:** Input context is too long, noisy, missing information, or poorly framed -- the model has capability but isn't using context effectively.

**Subcategories:**

- `reframing/` (18 papers): Restructure or filter context for better attention
- `augmentation/` (3 papers): Retrieve and inject missing information

**Representative papers:**

- Rephrase and Respond -- Canonical reframing; model rephrases ambiguous questions before answering
- System 2 Attention -- Advanced reframing; regenerate context to filter irrelevant information
- Generated Knowledge Prompting -- Canonical augmentation; generate missing background knowledge before reasoning

**Not for:**

- Context is fine but model reasons poorly -> use reasoning/
- Context is fine but output format is wrong -> use structure/
- Context is fine but output is too verbose -> use efficiency/

---

### efficiency/ (15 papers, 12%)

**When to use:** Inference is too slow, too expensive, or outputs are excessively verbose -- need to reduce token usage while maintaining acceptable quality.

**Representative papers:**

- Chain of Draft -- Aggressive compression; 80-92% token reduction vs standard CoT with minimal accuracy loss
- Concise Chain-of-Thought -- Moderate compression; balance between reasoning quality and output length
- Sketch-of-Thought -- Adaptive compression; cognitive-inspired sketching that adjusts verbosity to problem complexity

**Not for:**

- Accuracy is critical and cost is acceptable -> use correctness/
- Complex problems where full reasoning trace is needed -> use reasoning/
- Output format matters more than length -> use structure/

---

### structure/ (13 papers, 10%)

**When to use:** Need output in a specific format -- executable code, tables, JSON schemas, or other constrained structures.

**Representative papers:**

- Program of Thoughts -- Canonical code output; generate executable programs instead of natural language reasoning
- Table as Thought -- Tabular structure; organize reasoning in tables for complex multi-variable problems
- Meta Prompting -- Dynamic structure; model generates its own output format appropriate to the task

**Not for:**

- Problem is reasoning quality, not format -> use reasoning/
- Any format is acceptable and you want efficiency -> use efficiency/
- Need to verify correctness of structured output -> use correctness/

---

### references/ (1 paper)

**When to use:** Need survey papers, taxonomies, or meta-analyses rather than specific techniques.

**Note:** This is not a problem-solving category; it contains navigation aids for the taxonomy itself.

---

## Decision Tree for Classification

```
START: What is your PRIMARY problem?
|
+---> Is the problem with the INPUT (context issues)?
|     |
|     YES: Context is too long, noisy, missing info, or unclear
|     |    --> context/
|     |
|     NO: Problem is with the OUTPUT
|          |
|          V
|
+---> What aspect of the OUTPUT is problematic?
      |
      +---> "Model doesn't reason through the problem well"
      |     Model skips steps, can't decompose complexity, doesn't show work
      |     --> reasoning/
      |
      +---> "Model reasons but gives wrong or inconsistent answers"
      |     Steps look reasonable but conclusions are wrong or vary
      |     --> correctness/
      |
      +---> "Output is too long or inference too expensive"
      |     Need to reduce tokens, latency, or compute cost
      |     --> efficiency/
      |
      +---> "Need specific output format"
            Must produce code, tables, JSON, or other structured output
            --> structure/
```

## Classifying New Papers

### Step 1: Read the Paper's Core Mechanism

Look at the YAML file's `one_sentence_mechanism` field. This describes what the paper does.

### Step 2: Identify Primary Problem

Ask: What problem does this technique primarily solve?

- Model can't reason through complexity -> reasoning/
- Model gives wrong/inconsistent answers -> correctness/
- Context is too long/noisy/missing info -> context/
- Output too expensive or verbose -> efficiency/
- Need specific output format -> structure/

### Step 3: Check intervention.type Mapping

The `intervention.type` field in YAML files is the primary classification key:

| intervention.type      | Category                  |
| ---------------------- | ------------------------- |
| decomposition          | reasoning/decomposition/  |
| reasoning_elicitation  | reasoning/elicitation/    |
| sampling_aggregation   | correctness/sampling/     |
| verification           | correctness/verification/ |
| iterative_refinement   | correctness/refinement/   |
| perspective_framing    | context/reframing/        |
| retrieval_augmentation | context/augmentation/     |
| compression            | efficiency/               |
| output_constraint      | structure/                |
| routing                | references/               |

### Step 4: Apply Tie-Breaker Rules

When a problem spans multiple categories:

| Situation                 | Question to Ask                                  | Answer        |
| ------------------------- | ------------------------------------------------ | ------------- |
| reasoning vs correctness  | Does model show reasonable intermediate steps?   | YES->correct. |
| context vs reasoning      | Would model succeed with clearer/shorter prompt? | YES->context  |
| efficiency vs correctness | Is primary constraint cost/latency or accuracy?  | cost->effic.  |
| structure vs reasoning    | Would unstructured but correct output suffice?   | YES->reason.  |

### Step 5: Handle Uncertainty

If still unclear after tie-breakers:

1. Choose based on the primary mechanism described in `one_sentence_mechanism`
2. Add `also_useful_for` tag in YAML metadata for secondary classifications
3. Document the decision rationale in commit message

Example YAML metadata for multi-category papers:

```yaml
metadata:
  execution_complexity: single_call | multi_sample | adaptive_iterative
  integration_requirements: prompt_only | needs_orchestration | needs_human
  also_useful_for: [reasoning, correctness, context, efficiency, structure]
```

## Historical Context

This taxonomy replaces the original execution-topology organization (single-turn, multi-turn, subagent, agentic, hitl, compression) which had high cross-category overlap because execution topology is orthogonal to problem type.

The migration consolidated:

- 45 papers from single-turn/
- 43 papers from multi-turn/
- 21 papers from subagent/
- 5 papers from agentic/
- 3 papers from hitl/
- 13 papers from compression/

All 129 papers were reclassified by their `intervention.type` field into the 5 problem-driven categories above.
