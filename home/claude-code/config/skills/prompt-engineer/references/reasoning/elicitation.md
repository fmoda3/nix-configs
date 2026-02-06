# Reasoning Elicitation Techniques

## Overview

Reasoning elicitation techniques prompt LLMs to generate explicit reasoning traces
before producing answers. Use these techniques when models skip steps, produce
incorrect answers on multi-step problems, or fail to show their work. The core
insight: CoT-style prompting helps primarily on mathematical and symbolic
reasoning tasks. Meta-analysis confirms substantial gains on tasks involving
equations, formal logic, and multi-step arithmetic—questions containing "=" signs
are strong indicators that CoT will help. For non-symbolic tasks (commonsense
reasoning, factual QA), gains are minimal and CoT can even hurt performance.
Apply selectively based on task type.

---

## Techniques

### Zero-Shot Chain of Thought

**Mechanism:** Appending "Let's think step by step" before answer extraction
elicits step-by-step reasoning without examples.

**Triggers:**

- Multi-step arithmetic or symbolic reasoning problems
- Tasks requiring complex logical deduction across multiple steps
- Problems where standard zero-shot prompting produces flat scaling curves
- System-2 reasoning tasks requiring slow, deliberate thinking

**Tradeoffs:** 2x tokens, 2 calls (reasoning extraction + answer extraction).
Requires large-scale LLM (100B+ parameters). Underperforms Few-shot-CoT but
vastly outperforms standard zero-shot baselines. MultiArith 17.7% -> 78.7%,
GSM8K 10.4% -> 40.7%.

---

### Chain-of-Thought (Meta-Analysis)

**Mechanism:** Instructs model to generate step-by-step reasoning traces before
answering, effective primarily for mathematical and symbolic tasks.

**Triggers:**

- Problem requires mathematical computation or symbolic manipulation
- Task involves formal logic or algorithmic reasoning
- Question contains equations or numeric operations (presence of = sign)
- Multi-step symbolic execution needed (tracking intermediate values)
- Problem can be grounded in well-defined formal systems

**Tradeoffs:** 2-5x tokens, 1 call. Minimal benefit on non-symbolic tasks
(commonsense, factual QA) -- can underperform direct answering. 95% of MMLU
gains come from questions containing "=" sign. Use tool-augmented approaches
(PAL, SatLM) for better symbolic execution.

---

### Re-Reading (Re2)

**Mechanism:** Repeat the input question twice to enable bidirectional
understanding in decoder-only models.

**Triggers:**

- Complex multi-step reasoning requiring deep comprehension
- Questions where later context clarifies earlier tokens
- Arithmetic and symbolic reasoning tasks
- Problems where bidirectional understanding aids comprehension
- Tasks benefiting from more computational resources on input encoding

**Tradeoffs:** 2x input tokens, 1 call. Minimal inference time increase due to
GPU optimizations. Performance degrades beyond 2-3 repetitions. Composable with
other techniques. Consistent improvements across 112 experiments in original
study.

---

### Question Analysis Prompting (QAP)

**Mechanism:** Prompt LLM to explain the question in n words before solving to
maximize understanding.

**Triggers:**

- Multi-step arithmetic or algebraic reasoning problems
- SAT-level math problems requiring sophisticated problem-solving
- Hard problems where baseline prompting fails
- Tasks where understanding the question is critical to solution

**Tradeoffs:** 1.5-3x tokens (scales with n: 25-200 words), 1 call. Parameter
tuning required -- QAP150 best for algebra, QAP25 best for commonsense.
Over-explanation hurts simple questions. Best on hard problems: AQuA 52.8% ->
59.4%, SAT Math 70.9% -> 78.6%.

---

### Step-Back Prompting

**Mechanism:** Generate high-level step-back question before reasoning to
retrieve abstract concepts and principles that guide solution.

**Triggers:**

- Complex multi-step reasoning with many low-level details
- Domain-specific problems requiring first principles or concepts
- Knowledge-intensive QA with temporal or contextual constraints
- Multi-hop reasoning requiring bridging concepts
- Questions where direct reasoning risks losing context in intermediate steps

**Tradeoffs:** 2x tokens, 2 sequential calls. Few-shot examples needed for
abstraction step. Abstraction skill sample-efficient (1-shot sufficient). Fixes
20-40% baseline errors while introducing 5-12% new errors. +7% MMLU Physics,
+11% Chemistry, +27% TimeQA.

---

### Hint-before-Solving Prompting (HSP)

**Mechanism:** Prompt LLM to generate hints (knowledge or key ideas) before
generating solution with reasoning steps.

**Triggers:**

- LLM possesses relevant knowledge but fails to apply it accurately
- Complex reasoning requiring activation of specific encoded knowledge
- Multi-step mathematical problems (GSM8K, MATH, MultiArith, AQuA)
- Commonsense reasoning tasks (StrategyQA, Date Understanding)
- Problems requiring recall of specific concepts or formulas

**Tradeoffs:** 1.2-1.5x tokens. HSP: 1 call, HSP2: 2 calls (hint, then
solution). Few-shot examples with hint demonstrations required. Llama2-70B-Chat
+9.7% average. HSP2 with GPT-4 hints: Llama2-7B +12.8% average.

---

### Analogical Prompting

**Mechanism:** Prompt LLM to self-generate relevant problem-solution exemplars
before solving the target problem.

**Triggers:**

- Task requires diverse reasoning approaches (algebra, geometry, probability)
- Test problems span multiple subtypes within a domain
- Labeled exemplars unavailable or costly to obtain
- Need problem-specific guidance rather than generic instructions
- Complex reasoning tasks like competitive programming

**Tradeoffs:** 3-5x tokens (generates K=3-5 exemplars with solutions), 1 call.
Requires stronger/larger-scale LLMs for quality exemplar generation. Explicit
diversity instruction needed. Outperforms 0-shot CoT and manual few-shot CoT by
avg +4%. Eliminates manual labeling and retrieval infrastructure.

---

### Contrastive Chain-of-Thought

**Mechanism:** Provides both valid and invalid reasoning demonstrations to guide
step-by-step reasoning while reducing mistakes.

**Triggers:**

- Complex reasoning where intermediate steps are not well-defined
- Tasks where mistake reduction is critical for trustworthiness
- Situations where error propagation through reasoning steps is a concern
- When model needs guidance on both correct steps and common faults to avoid

**Tradeoffs:** 2x tokens (doubles demonstration examples with negative cases), 1
call. Few-shot examples with valid CoT required. Automatic construction from
existing rationales requires no additional annotation. +9.8 points on GSM-8K,
+16.0 points on Bamboogle vs conventional CoT. Compatible with self-consistency.

---

### Metacognitive Prompting

**Mechanism:** Guides LLMs through five-stage self-reflection: understand,
judge, critique, decide, and assess confidence.

**Triggers:**

- Task requires deep semantic understanding and contextual interpretation
- Natural language understanding tasks with nuanced meanings
- Domain-specific tasks requiring specialized terminology comprehension
- Question paraphrase detection, entailment, word sense disambiguation
- Biomedical or legal text understanding tasks
- Tasks requiring confidence estimation alongside prediction

**Tradeoffs:** 5x tokens, 1 call. Five-stage structured prompt template
required. Manual prompt engineering per task type. Overthinking errors on simple
tasks. Zero-shot: 4.8-6.4% improvement over CoT. EUR-LEX shows 15.0-26.9%
improvement.

---

### Self-Explanation Prompting

**Mechanism:** Prompt model to explain each dialogue utterance sequentially
before answering to enhance contextual comprehension.

**Triggers:**

- Multi-turn dialogue understanding required
- Long conversational contexts with information spread across turns
- Task-oriented dialogue tasks (dialogue state tracking, next action prediction)
- Information extraction from extended dialogue history
- Time-related confusions (departure vs arrival times) in dialogue

**Tradeoffs:** 2-3x tokens, 1 call. Zero-shot, no demonstrations required. Less
effective for emotion recognition and complex multi-step reasoning. +12.8% JGA
on MultiWOZ vs vanilla. Outperforms 4-shot in-context learning while being
zero-shot.

---

### Cognitive Prompting

**Mechanism:** Guide LLM problem-solving through structured cognitive operations
like goal clarification, decomposition, filtering, and pattern recognition.

**Triggers:**

- Multi-step reasoning problems requiring structured breakdown
- Complex mathematical word problems
- Tasks requiring goal clarification before execution
- Problems benefiting from pattern recognition and abstraction
- Decision-making scenarios requiring systematic cognitive operations

**Tradeoffs:** 2-3x tokens, 1 call per problem. Hybrid variant requires few-shot
examples from successful solutions. More complex than CoT. Greater proportional
gain for mid-size models. 95% solve rate on LLaMA 70B with H-CP variant on
GSM8K.

---

### Symbolic Chain-of-Thought

**Mechanism:** Translates natural language to symbolic format, plans steps,
solves with logic rules, verifies translation and reasoning.

**Triggers:**

- Logical reasoning problems requiring symbolic expressions (FOL, constraint
  optimization)
- Multi-step deductive reasoning with explicit logical rules (modus ponens,
  modus tollens)
- Tasks where natural language CoT produces logical fallacies
- Complex logical reasoning requiring rigid deducing rules
- Problems where external symbolic solvers fail due to translation errors

**Tradeoffs:** 4x tokens, 4 sequential calls (Translator, Planner, Solver,
Verifier). Symbolic logic knowledge required. Requires baseline planning
capability. 100% symbolic syntax execution success vs Logic-LM failures. GPT-4:
+7.88% over Logic-LM on FOL tasks.

---

### Thought Propagation

**Mechanism:** Solves analogous problems and propagates their solutions/plans to
refine the input problem solution.

**Triggers:**

- Multi-step problems where intermediate errors accumulate
- Optimization problems requiring search over large solution spaces
- Tasks where similar problem patterns can provide reusable insights
- Long-trial planning tasks requiring knowledge-intensive plans
- Problems where reasoning from scratch consistently fails

**Tradeoffs:** Similar to ToT for 1-layer, 2-3x for 2-layer TP. k+1 analogous
problems solved plus aggregation (typically 2-5 analogous problems). Compatible
base method required (IO, CoT, ToT, ReAct). Token overhead increases
exponentially with layer depth, diminishing returns beyond 2 layers. 12-15%
improvement over baselines.

---

### Socratic Method Prompting

**Mechanism:** Multi-turn dialogue using definition, elenchus, dialectic,
maieutics, and counterfactual reasoning to elicit reasoning traces and verify
outputs.

**Triggers:**

- Critical reading or evaluation of arguments required
- Need to verify credibility of information sources
- Exploring counterarguments or alternative perspectives
- Creative writing requiring guided exploration of "what if" scenarios
- Complex reasoning requiring clarification of definitions and terms
- Cross-examination of claims and supporting evidence needed

**Tradeoffs:** 3-10x tokens depending on depth, 5-15+ sequential calls for full
CRIT template. Higher latency but significantly improved accuracy and
credibility assessment. Multi-turn only, not single-turn applicable.

---

### Proactive Chain-of-Thought

**Mechanism:** Augments LLMs with goal planning via descriptive reasoning chains
before action selection in proactive dialogues.

**Triggers:**

- Dialogue system needs to ask clarification questions for ambiguous queries
- System must proactively guide conversation toward designated target topic
- Non-collaborative dialogue where system and user have conflicting goals
- Dialogue requires strategic planning and goal-directed initiative

**Tradeoffs:** 2-3x tokens, 1 call per turn with extended generation. Few-shot
examples required. Falls short on domain-specific problems requiring specialized
knowledge and strategic optimization. Multi-turn dialogue only.

---

### AlignedCoT (Native-Style Demonstration Generation)

**Mechanism:** Generate few-shot demonstrations by probing the LLM's own zero-shot
reasoning style, then refining and formatting those outputs to create "native-style"
exemplars that match how the model naturally reasons.

**The process:**
```
Step 1 (Probe): For each example in your few-shot prompt, query the LLM in
        zero-shot mode using "Let's think step by step" to generate its
        native reasoning style.

Step 2 (Refine): Check each generated CoT against ground truth. If errors exist,
        identify the first error, correct it, then prompt the LLM to complete
        the reasoning from that corrected point forward.

Step 3 (Format): Unify the format of all generated CoTs (standardize answer
        format, step numbering, solution structure).

Step 4 (Use): Replace human-crafted demonstrations with these native-style
        CoTs in your few-shot prompt.
```

**Why this works:** LLMs perform better when prompted with demonstrations matching
their own generation style rather than imitating human-written examples. Native-style
CoTs reduce the style gap between training and inference, requiring less
generalization capability from the model.

**Triggers:**

- Few-shot CoT underperforming expectations despite correct exemplars
- Model appears to mechanically copy demonstration format without genuine reasoning
- Task requires diverse reasoning approaches where manual exemplar crafting is costly
- Need to bootstrap better demonstrations without human annotation effort

**Tradeoffs:** Initial setup requires n zero-shot queries plus refinement iterations
(one per error in generated CoTs). Once created, native-style demonstrations are
reusable. Single call at inference time. Refinement step requires ground truth
answers for verification.

**CORRECT:**
```
# Generate native-style demonstration
User: [Question from training set]
Assistant: Let's think step by step.
[LLM generates its natural reasoning style]
[Human verifies: if error at step 3, correct step 3, re-prompt to continue]
[Final native-style CoT used as demonstration]
```

**INCORRECT:**
```
# Using raw human-written demonstrations
User: [Question]
Here's how to solve it: First, identify the variables. Second, set up equations.
Third, solve algebraically. The answer is X.
[LLM copies this rigid format without engaging its own reasoning]
```

The human-written style forces imitation rather than genuine reasoning activation.

**Stacking note:** AlignedCoT produces demonstrations for use with standard few-shot
CoT. Compatible with self-consistency (sample multiple outputs). Can be combined
with retrieval-augmented generation by aligning retrieved exemplars to native style.

---

### Instance-Adaptive Prompting (IAP)

**Mechanism:** Select the optimal zero-shot CoT prompt for each instance by analyzing
information flow saliency between question, prompt, and rationale rather than using
a single task-level prompt for all problems.

**The process:**
```
Given: A pool of candidate prompts (e.g., "Let's think step by step",
       "Take a deep breath and work on this step by step", etc.)

For each test instance:
  1. Compute saliency scores measuring information flow:
     - Question → Prompt (does prompt absorb question semantics?)
     - Question → Rationale (does rationale attend to question?)
     - Prompt → Rationale (does rationale follow prompt guidance?)

  2. Select prompt using one of two strategies:
     - Sequential Substitution (IAP-ss): Test prompts in order until one
       exceeds saliency thresholds, then use that prompt's answer.
     - Majority Vote (IAP-mv): Compute scores for all prompts, select top-k
       by combined saliency, take majority vote among their answers.
```

**Why this works:** Task-level optimal prompts can fail on individual instances
where a different prompt would succeed. Good reasoning requires: (1) the prompt
absorbs semantic information from the question, then (2) the rationale gathers
information from both the question directly and via the prompt. Saliency analysis
detects when this information flow is adequate.

**Triggers:**

- Zero-shot CoT shows high variance across similar problems
- Some instances consistently fail with "best" task-level prompt
- Need to maximize per-instance accuracy without fine-tuning
- Computational budget allows evaluating multiple prompt candidates

**Tradeoffs:** IAP-ss: 1-N calls depending on when threshold met (efficient early
termination). IAP-mv: N calls for N candidate prompts (more robust but higher cost).
Requires implementation of saliency score computation (attention weight analysis).
Most beneficial for smaller/mid-size models where prompt sensitivity is higher.

**CORRECT:**
```
# Instance-adaptive selection
Question: "A train travels 60 mph for 2 hours. How far does it go?"

Prompt candidates evaluated:
- "Let's think step by step" → saliency: Q→P=0.72, Q→R=0.81 ✓ (exceeds threshold)
[Use this prompt, return answer: 120 miles]
```

**INCORRECT:**
```
# Fixed task-level prompt for all instances
Always use "Let's think step by step" regardless of instance characteristics.
[Some instances fail because this prompt doesn't activate appropriate reasoning
for their specific structure]
```

Using a single prompt ignores instance-level variation in what triggers good reasoning.

**Stacking note:** IAP operates at the prompt selection layer, compatible with any
base zero-shot CoT technique. Can be combined with self-consistency by applying
IAP selection first, then sampling multiple outputs from the chosen prompt.

---

## Decision Guidance

1. **First, identify task type:**
   - Mathematical/symbolic reasoning -> CoT techniques highly effective
   - Commonsense/factual QA -> CoT provides minimal benefit, often skip
   - Dialogue understanding -> Self-Explanation or Proactive CoT
   - Knowledge-intensive QA -> Step-Back Prompting

2. **Check for symbolic indicators:**
   - Equations, "=" signs, numeric operations -> use CoT
   - Formal logic requirements -> Symbolic CoT
   - No formal system -> consider skipping CoT entirely

3. **Consider model capability:**
   - Large models (100B+) -> Zero-shot CoT viable
   - Mid-size models -> Cognitive Prompting, few-shot techniques
   - Small models -> HSP2 with stronger model hints

4. **Evaluate cost constraints:**
   - Single call needed -> Re2, QAP, Contrastive CoT
   - Multiple calls acceptable -> Step-Back, Symbolic CoT, Socratic
   - Minimal overhead -> Re2 (2x input only)

5. **Optimize prompt selection:**
   - High variance across instances -> IAP (instance-adaptive selection)
   - Few-shot demos underperforming -> AlignedCoT (native-style generation)
   - Fixed prompt works well -> Use standard zero-shot or few-shot CoT

---

## Composability Notes

**Orthogonal combinations (additive benefits):**

- Re2 + CoT: Re-reading composes with any reasoning technique
- Contrastive CoT + Self-consistency: Further gains from sampling
- HSP + CoT: Hint generation before standard CoT
- Step-Back + CoT: Abstraction then detailed reasoning
- AlignedCoT + Self-consistency: Native-style demos with multiple sampling
- IAP + Self-consistency: Instance-adaptive selection then multiple samples

**Conflicts/redundancy:**

- Self-Explanation conflicts with standard CoT (different output structure)
- Multiple elicitation techniques in sequence: diminishing returns
- Symbolic CoT vs natural language CoT: choose one based on task
- AlignedCoT vs manual few-shot: use one or the other, not both

**Build-on relationships:**

- Contrastive CoT builds on CoT (adds negative examples)
- Step-Back builds on CoT (adds abstraction layer)
- Thought Propagation works with IO, CoT, ToT, or ReAct as base method
- Cognitive Prompting extends CoT with structured operations
- AlignedCoT produces demonstrations for few-shot CoT
- IAP selects prompts for any zero-shot CoT variant

---

## Cautionary Notes

**CoT Bias and Toxicity:** Zero-shot CoT increases bias and toxicity on
socially-sensitive contexts. Tasks involving stereotypes, marginalized groups,
or ethical considerations should AVOID CoT prompting. Effect worsens with model
scale but improves with RLHF alignment.

**When NOT to use CoT:**

- Single-step problems (no multi-step reasoning needed)
- Commonsense questions (minimal to no improvement)
- Smaller models (<100B parameters for zero-shot)
- Socially-sensitive topics (amplifies bias)
- Time-critical applications (latency overhead)
