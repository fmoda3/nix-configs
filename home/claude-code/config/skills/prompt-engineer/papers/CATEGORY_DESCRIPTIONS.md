# Prompt Engineering Paper Category Descriptions

This document provides operational descriptions for classifying papers into the taxonomy. Each category includes five facets to enable precise classification by research assistants unfamiliar with prompt engineering.

---

## 1. reasoning/ (Problem Decomposition and Reasoning Traces)

### PROBLEM ADDRESSED

**Observable symptoms:**

- Model provides direct answer without showing intermediate steps
- Model fails on multi-hop questions requiring connected reasoning
- Model cannot solve problems harder than those shown in examples
- Model skips logical steps or makes unexplained leaps
- Model performs poorly on compositional or sequential tasks

**When you observe:** "The model isn't thinking through the problem systematically."

### INCLUDES

Papers that teach models **HOW to reason** through complex problems:

**Technique types:**

- **Decomposition**: Break complex problems into simpler sub-problems solved sequentially
- **Elicitation**: Draw out step-by-step reasoning through prompting

**Canonical examples:**

- Least-to-Most Prompting (decomposition): Breaks problems into sub-questions answered in sequence
- Large Language Models are Zero-Shot Reasoners (elicitation): Uses "Let's think step by step" to elicit reasoning
- Tree of Thoughts (decomposition): Explores multiple reasoning paths through tree search
- Chain-of-Thought Prompting (elicitation): Few-shot examples showing step-by-step reasoning

**Intervention mechanism:** Modifies prompts or orchestration to improve the reasoning process itself.

### EXCLUDES

**Does NOT include:**

- Model shows reasonable steps but gives wrong final answer -> **correctness/** (verification/sampling/refinement)
- Output reasoning is too long/verbose -> **efficiency/** (compression)
- Model lacks domain knowledge to reason with -> **context/augmentation** (retrieval)
- Need specific output format (code/JSON/tables) -> **structure/** (output constraints)

**Tie-breaker:** If model shows reasonable intermediate steps, problem is correctness not reasoning.

### USE WHEN

Apply reasoning techniques when:

- Model capability exists but isn't being utilized (it CAN reason but DOESN'T)
- Problems require multi-step or compositional thinking
- Model needs guidance on problem-solving approach
- Task complexity exceeds single-step inference
- You need interpretable reasoning traces

**Primary goal:** Improve reasoning process quality and problem decomposition.

### DO NOT USE WHEN

Avoid reasoning techniques if:

- Model already produces reasonable reasoning steps (use **correctness/** to verify instead)
- Problem is single-step and doesn't require decomposition
- Model fundamentally lacks knowledge required (add **context/augmentation** first)
- Reasoning quality is acceptable but output is too expensive (use **efficiency/** instead)
- Issue is output format compliance not reasoning quality (use **structure/** instead)

**Contraindication:** Don't layer reasoning techniques on top of each other without testing -- complexity compounds.

---

### 1a. reasoning/decomposition/

**PROBLEM ADDRESSED:** Model cannot break down complex problems into manageable sub-problems.

**INCLUDES:**

- Papers that split problems into sub-questions or stages
- Sequential problem-solving where answers build on previous steps
- Examples: Least-to-Most Prompting, Plan-and-Solve, Successive Prompting

**EXCLUDES:** Papers that elicit reasoning without explicit decomposition -> reasoning/elicitation

**USE WHEN:** Problems have natural sub-structure or require solving easier problems first.

**DO NOT USE WHEN:** Problem doesn't decompose naturally or model handles complexity in single pass.

---

### 1b. reasoning/elicitation/

**PROBLEM ADDRESSED:** Model doesn't show its reasoning work, jumps to conclusions.

**INCLUDES:**

- Papers that prompt models to articulate step-by-step thinking
- Techniques that draw out implicit reasoning processes
- Examples: Zero-Shot Reasoners ("Let's think step by step"), Chain-of-Thought Prompting

**EXCLUDES:** Papers that decompose into sub-problems -> reasoning/decomposition

**USE WHEN:** Model has reasoning capability but doesn't naturally show its work.

**DO NOT USE WHEN:** Model already produces detailed reasoning or problem requires decomposition not elicitation.

---

## 2. correctness/ (Error Detection and Answer Verification)

### PROBLEM ADDRESSED

**Observable symptoms:**

- Model gives different answers to the same question across runs
- Reasoning looks plausible but conclusions are factually wrong
- Model makes unverified claims or hallucinates facts
- Final answer is incorrect despite reasonable-looking intermediate steps
- Model performance is inconsistent or unreliable

**When you observe:** "The model reasons but gives wrong or inconsistent answers."

### INCLUDES

Papers that **verify, check, or improve** outputs AFTER reasoning occurs:

**Technique types:**

- **Sampling**: Generate multiple reasoning paths, aggregate via voting/selection
- **Verification**: Explicit checking steps that catch errors before final output
- **Refinement**: Feedback loops that iteratively improve answers

**Canonical examples:**

- Self-Consistency (sampling): Samples multiple reasoning paths, majority vote on answers
- Chain-of-Verification (verification): Generates verification questions to catch hallucinations
- Self-Refine (refinement): Iterative self-feedback loop improves output quality

**Intervention mechanism:** Adds error-detection or answer-improvement steps after initial generation.

### EXCLUDES

**Does NOT include:**

- Model can't reason through problem at all -> **reasoning/** (decomposition/elicitation) FIRST
- Errors due to missing context or knowledge -> **context/** (reframing/augmentation)
- Accuracy acceptable but cost too high -> **efficiency/** (compression)
- Format compliance matters more than correctness -> **structure/** (output constraints)

**Tie-breaker:** If model doesn't show reasonable intermediate steps, fix reasoning before correctness.

### USE WHEN

Apply correctness techniques when:

- Model demonstrates reasoning capability but makes errors
- Consistency across runs is important
- Stakes are high and errors are costly
- Model tends to hallucinate or make unverified claims
- You can afford multiple samples or verification passes

**Primary goal:** Catch and fix errors in otherwise reasonable outputs.

### DO NOT USE WHEN

Avoid correctness techniques if:

- Model fundamentally can't reason through the problem (fix **reasoning/** first)
- Errors stem from missing information (add **context/** first)
- Single fast answer is more important than accuracy (use **efficiency/** instead)
- Budget doesn't allow multiple samples or verification passes
- Errors are rare and cost of verification exceeds cost of errors

**Contraindication:** Sampling/verification adds latency and cost -- ensure accuracy gains justify overhead.

---

### 2a. correctness/sampling/

**PROBLEM ADDRESSED:** Model gives inconsistent answers across different runs.

**INCLUDES:**

- Papers that generate multiple candidates and aggregate (voting, selection, ranking)
- Examples: Self-Consistency, Self-ICL, multiple reasoning paths

**EXCLUDES:** Papers that verify single output -> correctness/verification; Papers that refine iteratively -> correctness/refinement

**USE WHEN:** Problem admits multiple reasoning paths leading to same answer; Can afford multiple samples.

**DO NOT USE WHEN:** Problem has limited valid reasoning approaches or sampling budget is constrained.

---

### 2b. correctness/verification/

**PROBLEM ADDRESSED:** Model makes unverified claims or hallucinations.

**INCLUDES:**

- Papers that add explicit checking, validation, or fact-verification steps
- Examples: Chain-of-Verification, Self-Verification

**EXCLUDES:** Papers that sample multiple outputs -> correctness/sampling; Papers that refine iteratively -> correctness/refinement

**USE WHEN:** Model tends to hallucinate; Need high-confidence outputs; Can afford verification overhead.

**DO NOT USE WHEN:** Errors are rare; Verification cost exceeds error cost; Domain lacks verification sources.

---

### 2c. correctness/refinement/

**PROBLEM ADDRESSED:** Initial output quality is poor but improvable through feedback.

**INCLUDES:**

- Papers that iteratively improve outputs through self-feedback or critic models
- Examples: Self-Refine, Iterative Refinement, Feedback loops

**EXCLUDES:** Papers that sample multiple independent outputs -> correctness/sampling; Papers that verify without refinement -> correctness/verification

**USE WHEN:** Quality improves with iteration; Can afford multiple generation passes; Feedback signal is available.

**DO NOT USE WHEN:** First output is usually correct; Iteration doesn't improve quality; Budget constrains multiple passes.

---

## 3. context/ (Input Reframing and Knowledge Augmentation)

### PROBLEM ADDRESSED

**Observable symptoms:**

- Performance degrades with longer context (lost in the middle)
- Model ignores relevant information present in prompt
- Model misinterprets ambiguous or unclear questions
- Model lacks domain-specific knowledge to reason effectively
- Context is noisy with irrelevant information

**When you observe:** "The model has capability but isn't using the context well, or context is missing information."

### INCLUDES

Papers that improve INPUT quality before reasoning:

**Technique types:**

- **Reframing**: Restructure, rephrase, or filter context for better attention
- **Augmentation**: Retrieve or generate missing information

**Canonical examples:**

- Rephrase and Respond (reframing): Model rephrases ambiguous questions before answering
- System 2 Attention (reframing): Regenerates context to filter irrelevant information
- Generated Knowledge Prompting (augmentation): Generates missing background knowledge first
- Rethinking Demonstrations (reframing): Shows format and label space matter more than exact mappings

**Intervention mechanism:** Modifies input prompts or adds missing information before main reasoning.

### EXCLUDES

**Does NOT include:**

- Context is fine but model reasons poorly -> **reasoning/** (decomposition/elicitation)
- Context is fine but output format is wrong -> **structure/** (output constraints)
- Context is fine but output is too verbose -> **efficiency/** (compression)
- Context is fine but answer is incorrect -> **correctness/** (sampling/verification/refinement)

**Tie-breaker:** If model would succeed with clearer/shorter prompt, problem is context not reasoning.

### USE WHEN

Apply context techniques when:

- Context length causes attention/memory issues
- Question is ambiguous or poorly specified
- Model lacks domain knowledge for reasoning
- Context contains significant noise or irrelevant information
- Few-shot examples don't match test distribution

**Primary goal:** Improve input quality so model can apply its capabilities effectively.

### DO NOT USE WHEN

Avoid context techniques if:

- Context is already clear and concise (problem is elsewhere)
- Model fails even with perfect context (fix **reasoning/** or **correctness/**)
- Context length is acceptable and attention is working
- Adding information increases noise rather than signal
- Issue is output characteristics not input quality

**Contraindication:** Don't add context augmentation if model already has sufficient information -- increases cost without benefit.

---

### 3a. context/reframing/

**PROBLEM ADDRESSED:** Context is present but poorly structured or noisy.

**INCLUDES:**

- Papers that rephrase questions, filter noise, or restructure prompts
- Examples: Rephrase and Respond, System 2 Attention, Rethinking Demonstrations

**EXCLUDES:** Papers that retrieve/generate missing information -> context/augmentation

**USE WHEN:** Context exists but model doesn't attend to relevant parts; Question is ambiguous.

**DO NOT USE WHEN:** Context genuinely lacks information needed for task.

---

### 3b. context/augmentation/

**PROBLEM ADDRESSED:** Model lacks knowledge or information to complete task.

**INCLUDES:**

- Papers that retrieve external knowledge or generate missing information
- Examples: Generated Knowledge Prompting, RAG-style retrieval augmentation

**EXCLUDES:** Papers that restructure existing context -> context/reframing

**USE WHEN:** Model needs information not present in prompt; Task requires domain knowledge.

**DO NOT USE WHEN:** All necessary information is already in context; Adding information introduces noise.

---

## 4. efficiency/ (Reducing Token Usage, Latency, and Cost)

### PROBLEM ADDRESSED

**Observable symptoms:**

- Model outputs are excessively long or verbose for task requirements
- Inference latency is too high for interactive applications
- Token costs exceed budget while maintaining acceptable accuracy
- Response time is unpredictable due to variable output length
- Reasoning traces obscure key information with unnecessary detail

**When you observe:** "The model works but is too slow, expensive, or verbose."

### INCLUDES

Papers where **PRIMARY goal is reducing tokens, latency, or cost**:

**Technique types:**

- **Compression**: Reduce reasoning length while maintaining quality
- **Batching**: Process multiple queries together to amortize cost
- **Early stopping**: Terminate generation when answer is found

**Canonical examples:**

- Chain of Draft (compression): 80-92% token reduction vs standard CoT with minimal accuracy loss
- Concise Chain-of-Thought (compression): Balance reasoning quality with output length
- Sketch-of-Thought (compression): Adaptive compression adjusting verbosity to problem complexity
- Batch Prompting (batching): Process multiple questions in single API call

**Intervention mechanism:** Reduces computational cost as primary objective, accuracy as constraint.

### EXCLUDES

**Does NOT include:**

- Accuracy is critical and cost is acceptable -> **correctness/** (sampling/verification/refinement)
- Complex problems where full reasoning trace needed -> **reasoning/** (decomposition/elicitation)
- Output format matters more than length -> **structure/** (output constraints)
- Problem is reasoning quality not output length -> **reasoning/**

**Tie-breaker:** If primary constraint is cost/latency rather than accuracy, it's efficiency.

### USE WHEN

Apply efficiency techniques when:

- Accuracy is acceptable but cost/latency is not
- Operating under budget or latency constraints
- Scaling to high query volumes
- Reasoning verbosity obscures rather than clarifies
- Users need fast responses more than detailed explanations

**Primary goal:** Minimize computational cost while maintaining acceptable quality threshold.

### DO NOT USE WHEN

Avoid efficiency techniques if:

- Accuracy is paramount and budget allows full reasoning
- Complex problems require detailed reasoning traces
- Users need/expect detailed explanations
- Compression degrades quality below acceptable threshold
- Cost/latency is already acceptable

**Contraindication:** Don't compress reasoning on hard problems where abbreviated thinking causes errors -- accuracy loss exceeds cost savings.

---

## 5. structure/ (Output Format Constraints)

### PROBLEM ADDRESSED

**Observable symptoms:**

- Need executable code rather than natural language explanations
- Downstream systems require JSON/XML schema compliance
- Must produce tabular data for databases or spreadsheets
- Output parser fails because format is inconsistent
- Integration requires specific structured output

**When you observe:** "The model's answer is fine but needs specific format (code, tables, JSON, etc.)."

### INCLUDES

Papers where **PRIMARY goal is constraining output format**:

**Technique types:**

- **Code generation**: Output executable programs instead of natural language
- **Tabular**: Organize reasoning or output in table structures
- **Schema compliance**: Force JSON/XML schema adherence

**Canonical examples:**

- Program of Thoughts (code): Generate Python programs instead of natural language reasoning
- Tab-CoT (tables): Organize step-by-step reasoning in 2D table format
- Meta Prompting (dynamic structure): Model generates appropriate output format for task

**Intervention mechanism:** Constrains output to specific structured format for integration or executability.

### EXCLUDES

**Does NOT include:**

- Problem is reasoning quality not format -> **reasoning/** (decomposition/elicitation)
- Any format acceptable and want efficiency -> **efficiency/** (compression)
- Need to verify correctness of structured output -> **correctness/** (verification)
- Structure is means to reasoning, not end goal -> **reasoning/** (e.g., table to organize thoughts)

**Tie-breaker:** If unstructured but correct output would suffice, problem isn't structure.

### USE WHEN

Apply structure techniques when:

- Downstream systems require specific formats
- Output must be machine-executable (code)
- Integration depends on schema compliance
- Format consistency matters for parsing/processing
- Domain naturally uses structured representations

**Primary goal:** Ensure output format meets integration or executability requirements.

### DO NOT USE WHEN

Avoid structure techniques if:

- Any reasonable format is acceptable (overhead not justified)
- Format constraint degrades reasoning quality
- Natural language output is preferred for human consumption
- Structure doesn't solve underlying reasoning problem
- Parsing flexibility can handle format variations

**Contraindication:** Don't force structure if it fights against natural reasoning process -- may degrade both reasoning quality and format compliance.

---

## 6. references/ (Navigation and Meta-Analysis)

### PROBLEM ADDRESSED

**Observable symptoms:**

- Need survey papers or taxonomies rather than specific techniques
- Looking for meta-analysis across multiple prompting methods
- Searching for navigation aids within the taxonomy

**When you observe:** "I need orientation within the taxonomy, not a specific technique."

### INCLUDES

- Survey papers reviewing multiple prompt engineering techniques
- Taxonomies and classification frameworks
- Meta-analyses comparing technique families
- Navigation aids for the taxonomy itself

### EXCLUDES

All problem-solving categories -> **reasoning/**, **correctness/**, **context/**, **efficiency/**, **structure/**

### USE WHEN

Looking for overview, comparison, or navigation rather than specific technique to apply.

### DO NOT USE WHEN

Need specific technique to solve a problem (use appropriate problem-solving category instead).

---

## Classification Workflow

### Step 1: Identify Primary Problem

Read paper abstract and ask: **What problem does this primarily solve?**

Map symptoms to category:

- **INPUT issues** (context too long/noisy/missing) -> context/
- **Can't reason through problem** (skips steps, can't decompose) -> reasoning/
- **Reasons but wrong/inconsistent answers** (errors, hallucinations) -> correctness/
- **Too expensive/slow/verbose** (cost, latency, length) -> efficiency/
- **Need specific output format** (code, JSON, tables) -> structure/

### Step 2: Check Inclusion Criteria

Does paper match 2+ examples in mechanism or evaluation from chosen category?

- YES: Category is likely correct
- NO: Reconsider or check tie-breakers

### Step 3: Apply Tie-Breakers (if multiple categories fit)

| Confusion                 | Question                                         | Answer                      |
| ------------------------- | ------------------------------------------------ | --------------------------- |
| reasoning vs correctness  | Does model show reasonable intermediate steps?   | YES -> correctness/         |
| context vs reasoning      | Would model succeed with clearer/shorter prompt? | YES -> context/             |
| efficiency vs correctness | Is primary constraint cost/latency or accuracy?  | cost/latency -> efficiency/ |
| structure vs reasoning    | Would unstructured but correct output suffice?   | YES -> reasoning/           |

### Step 4: Check Exclusion Criteria

Review DO NOT USE WHEN section. If contraindications apply, follow redirection to alternative category.

### Step 5: Classify Subcategory

Within category, identify specific mechanism:

- **reasoning/**: decomposition vs elicitation
- **correctness/**: sampling vs verification vs refinement
- **context/**: reframing vs augmentation

### Step 6: Handle Uncertainty

If still unclear:

1. Classify by paper's stated main contribution in abstract
2. Add `also_useful_for` secondary tag if genuinely multi-purpose
3. Document decision rationale

---

## Gap Identification

To identify **coverage gaps** in the taxonomy:

1. **Collect problem symptoms** from failed model behaviors in target domain
2. **Map symptoms to categories** using PROBLEM ADDRESSED sections
3. **Identify unmapped symptoms** that don't fit any category
4. **Cluster unmapped symptoms** to identify patterns
5. **Evaluate gap significance**: Do >10 papers or common problems fall in gap?
6. **Consider**: Is this a new category or a subcategory of existing one?

**Example:**

- Symptom: "Model generates unsafe or biased content"
- Not mapped: Not reasoning, correctness, context, efficiency, or structure problem
- Pattern: Safety/alignment concerns
- Significance: If common enough, might warrant new category

---

## Maintenance Guidelines

**Annual review:**

- Update canonical paper examples if better exemplars emerge
- Check if tie-breaker rules are frequently invoked (>20% suggests category boundaries need refinement)
- Identify papers in "emerging" patterns that suggest new categories
- Review exclusion criteria for coupling issues

**When to split category:**

- Subcategory grows to >30 papers and has distinct problem symptoms
- Tie-breakers are frequently needed within category

**When to merge categories:**

- Combined total <10 papers
- Symptoms are rarely distinguished in practice
- Most papers legitimately span both categories

---

## Template Metadata

**Version:** 1.0
**Created:** 2026-01-25
**Based on:** 129 papers across 5 problem-driven categories
**Inspired by:** DSM-5 diagnostic criteria, IPC patent classification, ACM Computing Classification System
**Validated:** Against decision tree and tie-breaker rules in papers/README.md
