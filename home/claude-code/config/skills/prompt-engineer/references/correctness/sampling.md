# Sampling and Aggregation Techniques

## Overview

Sampling and aggregation techniques improve LLM accuracy by generating multiple
reasoning paths or outputs and combining them through voting, ranking, or
synthesis. Use these techniques when: (1) a single model output is unreliable or
inconsistent, (2) the task admits multiple valid solution paths, (3) you need
higher confidence in answers, or (4) the problem requires exploration of
alternatives. These methods trade increased compute cost for improved accuracy
and are most valuable for complex reasoning tasks where correct solutions
converge despite diverse reasoning paths.

**Key insight:** Output-space sampling is the critical component for ensemble
performance—varying the input/prompt provides marginal additional benefit
compared to sampling diverse outputs. The mechanism: output sampling
marginalizes over latent reasoning paths, while input variation (prompt
rephrasing, example reordering) merely shifts the starting distribution without
expanding the reasoning path space proportionally. Experiments show
prompt-order and input-rationale ensembles underperform output sampling
regardless of how inputs vary. This means temperature-based sampling alone
captures most ensemble gains; prompt variation adds smaller incremental value.

---

## Techniques

### Self-Consistency

**Mechanism:** Sample multiple diverse reasoning paths via temperature-based
decoding, then select the most consistent final answer by majority vote.

**Triggers:**

- Complex reasoning admits multiple valid solution paths
- Arithmetic or mathematical problem solving
- Tasks where correct reasoning converges to same answer
- Model reasoning is partially reliable but inconsistent
- Answer must be from fixed answer set or easily parseable

**The process:**

```
1. Sample k reasoning paths at temperature > 0 (typically 5-40 paths)
2. Extract final answer from each path
3. Select answer with highest vote count
```

**Why this works:** Correct solutions are attractors—multiple valid reasoning
paths converge to the same answer, while errors scatter randomly. Sampling
marginalizes over the latent reasoning path variable.

**CORRECT:**
```
[Sample 40 CoT outputs at temp=0.7 for "If John has 3 apples and buys 2 more..."]
Answers: 5, 5, 5, 6, 5, 5, 4, 5, 5, 5... → Select "5" (majority)
```

**INCORRECT:**
```
[Use greedy decoding (temp=0) and take single answer]
Answer: 6 → No opportunity to correct via aggregation
```

Greedy decoding commits to a single reasoning path that may contain errors.
Self-consistency's value comes from path diversity.

**Tradeoffs:**

- Token overhead: 5-40x tokens (recommended 5-40 paths)
- API calls: k independent sampling calls
- Requirements: Few-shot CoT examples, temperature-based sampling enabled
- Gains: Substantial improvements on math word problems, commonsense reasoning

---

#### Universal Self-Consistency (USC)

**Mechanism:** Extends self-consistency to free-form outputs by using the LLM
itself to select the most consistent response among candidates, rather than
exact-match voting.

**Triggers:**

- Free-form generation (summarization, open-ended QA)
- Answer extraction via exact match is not feasible
- Output formats vary across samples (different phrasing, structure)
- Code generation without access to execution results

**The process:**

```
1. Sample k responses at temperature > 0
2. Concatenate all responses into a single prompt
3. Ask LLM: "Select the most consistent response among these candidates"
4. Return the selected response
```

**Why this works:** Assessing consistency among candidates is easier than
judging answer correctness. The LLM can recognize when multiple responses
converge on the same semantic content even with different surface forms.

**CORRECT:**
```
Question: "What are the main causes of the French Revolution?"

Sample 1: "Economic crisis, social inequality, and weak monarchy..."
Sample 2: "Financial troubles, class tensions, and ineffective king..."
Sample 3: "Debt problems, unfair taxation, and royal incompetence..."

USC prompt: "Given these 3 responses, select the most consistent one."
→ LLM selects based on semantic overlap of key themes
```

**INCORRECT:**
```
[Attempt exact-match voting on free-form responses]
Sample 1: "Economic crisis..." → unique string
Sample 2: "Financial troubles..." → unique string
Sample 3: "Debt problems..." → unique string
→ All answers get 1 vote each; no majority emerges
```

Standard self-consistency fails on free-form outputs because no two responses
match exactly, even when they're semantically equivalent.

**Tradeoffs:**

- Token overhead: k samples + 1 selection call (selection prompt can be long)
- Limitation: Number of samples bounded by context length
- Gains: Enables consistency-based selection for summarization, open-ended QA,
  code generation without execution

**Stacking note:** USC replaces the voting step in self-consistency; combine
with any technique that generates multiple outputs needing aggregation.

---

### Mixture of Reasoning Experts (MoRE)

**Mechanism:** Create specialized expert prompts for different reasoning types
(factual, math, multihop, commonsense), run all experts on each question, then
select the best answer based on inter-expert agreement.

**Triggers:**

- Unknown question type requiring generalization across reasoning domains
- Mixed-domain QA where single prompting strategy underperforms
- Need both accuracy and calibrated confidence for selective answering
- Interpretable routing decisions valuable for human verification

**The process:**

```
1. Create specialized prompts:
   - Factual: retrieval-augmented (append relevant passages)
   - Multihop: chain-of-thought with decomposition
   - Math: chain-of-thought with calculation steps
   - Commonsense: generated knowledge prompting

2. Run all experts on the question

3. Select answer based on:
   - Inter-expert agreement (how many experts converge)
   - Answer characteristics (length, overlap with question)
   - Expert-question type matching signals

4. Optionally abstain if confidence below threshold
```

**Why this works:** Specialized prompts excel at their target reasoning type but
fail on others. Agreement among differently-specialized experts provides a
strong correctness signal—if multiple reasoning approaches converge on the same
answer, confidence increases substantially.

**Critical insight:** Inter-expert agreement is more informative than individual
confidence scores. Without agreement features, calibration degrades below simple
probability-based baselines.

**CORRECT:**
```
Question: "How many planets are closer to the Sun than Earth?"

Factual Expert: "Mercury and Venus. Answer: 2"
Math Expert: "Earth is 3rd planet. 3-1=2. Answer: 2"
Multihop Expert: "Mercury is 1st, Venus is 2nd, Earth is 3rd. Answer: 2"
Commonsense Expert: "Mercury and Venus are inner planets. Answer: 2"

→ All 4 experts agree → High confidence → Select "2"
```

**INCORRECT:**
```
[Use single specialized prompt for all questions]

Math prompt on factual question: "Who wrote Hamlet?"
→ CoT reasoning inappropriate for retrieval task
→ Performance degrades significantly
```

Single specialized prompts sacrifice generalizability for targeted performance.

**Tradeoffs:**

- Token overhead: 4x baseline (run all four experts)
- Can reduce to question-only routing when compute-limited (weaker but faster)
- Requirements: Specialized prompts per reasoning type, selection mechanism
- Gains: Substantially outperforms any single expert on mixed-domain QA;
  improves human calibration when expert predictions are shown

**Stacking note:** Each expert can internally use self-consistency. MoRE
provides cross-expert diversity while SC provides within-expert diversity.

---

### Tree of Thoughts (ToT)

**Mechanism:** Explores multiple reasoning paths via tree search with LM-based
thought generation and self-evaluation; supports BFS/DFS with backtracking.

**Triggers:**

- Task requires exploration of multiple solution paths
- Initial decisions are pivotal and hard to reverse
- Task requires strategic lookahead or backtracking
- Left-to-right decoding fails frequently at early steps
- Creative tasks requiring high-level planning before execution

**The process:**

```
1. Decompose problem into thought steps
2. Generate k candidate thoughts at each step
3. Evaluate each thought's promise using LLM self-evaluation
4. Search (BFS keeps top-b; DFS explores until pruning)
5. Backtrack when paths are evaluated as unpromising
```

**Why this works:** Left-to-right decoding commits to early decisions that may
be suboptimal. Tree search allows exploration of alternatives and recovery from
mistakes via backtracking.

**CORRECT:**
```
Task: Game of 24 (combine 4 numbers to make 24)
Numbers: 4, 5, 6, 10

Step 1 candidates: "5+6=11", "4+5=9", "10-4=6"
Evaluate each → "5+6=11" looks promising
Step 2 from "5+6=11": "11+10=21", "11*4=44"...
Backtrack if stuck → try "10-4=6" path instead
```

**INCORRECT:**
```
[Greedy CoT without backtracking]
"First, 4+5=9. Then 9+6=15. Then 15+10=25. That's not 24..."
→ Committed to suboptimal first step, cannot recover
```

Without backtracking, early mistakes propagate through the entire solution.

**Tradeoffs:**

- Token overhead: 5-100x tokens vs CoT (depends on branching factor and depth)
- API calls: Adaptive (BFS keeps top-b states per step; DFS explores until
  pruning)
- Requirements: Few-shot examples for thought generation, search algorithm,
  state evaluation prompts
- Gains: Dramatically outperforms CoT on tasks requiring search and
  backtracking (puzzles, planning, creative writing)

---

### Diversity of Thought (Div-Se / IDiv-Se)

**Mechanism:** Solicit LLM to generate multiple high-level reasoning approaches,
augment few-shot examples per approach, ensemble across diverse prompts via
majority vote.

**Triggers:**

- Complex multi-step reasoning requiring diverse solution strategies
- Math problems solvable via multiple approaches (algebra, visualization,
  elimination)
- Problems where token-level diversity fails to ensure methodological diversity
- Tasks where baseline CoT and self-consistency plateau

**The process:**

```
Div-Se (separate calls):
1. Ask LLM to list k distinct solving approaches for the problem type
2. Create k prompts, each with examples demonstrating one approach
3. Run each prompt separately, collect answers
4. Majority vote across all answers

IDiv-Se (single call):
1. Instruct LLM to solve using multiple approaches in one response
2. Extract answer from each approach
3. Majority vote within the single response
```

**Why this works:** Temperature-based sampling varies token choices but not
reasoning methodology. Explicit approach variation ensures genuinely different
problem-solving strategies, catching errors that single-approach sampling
misses.

**CORRECT:**
```
Problem: "A store has a 20% off sale. If an item costs $80 after discount..."

Approach 1 (Algebra): Let x = original price. 0.8x = 80, so x = 100
Approach 2 (Reverse percentage): 80 ÷ 0.8 = 100
Approach 3 (Proportion): 80/x = 80/100, so x = 100

→ All approaches converge on $100
```

**INCORRECT:**
```
[Sample same algebraic approach 3 times at high temperature]
Sample 1: "0.8x = 80, x = 100"
Sample 2: "0.8x = 80, x = 100"
Sample 3: "0.8x = 80, x = 10" (arithmetic error)

→ Same methodology; no methodological diversity to catch the error pattern
```

Token-level diversity doesn't prevent systematic errors in a single approach.

**Tradeoffs:**

- Token overhead: Div-Se: 3-5x tokens (k separate calls); IDiv-Se: 1.5-2x tokens
  (single call)
- API calls: Div-Se: k calls (k=3 or 5); IDiv-Se: 1 call
- Requirements: LLM feedback for approach generation, few-shot example
  augmentation
- Gains: Strong improvements on math and planning tasks, especially where
  self-consistency plateaus

---

### Multi-Chain Reasoning (MCR)

**Mechanism:** LLM meta-reasons over multiple CoT chains to combine facts and
generate unified explanation rather than simple majority voting.

**Triggers:**

- Multi-hop questions requiring multiple reasoning steps
- Questions where individual CoT chains contain partial but incomplete
  information
- Tasks requiring fact composition across multiple reasoning paths
- Problems where majority voting fails due to large output space

**The process:**

```
1. Generate 1 greedy + 4 sampled CoT chains
2. Extract facts and reasoning from each chain
3. Feed all chains to meta-reasoner
4. Meta-reasoner synthesizes facts across chains into unified answer
```

**Why this works:** Individual chains may each capture different relevant facts.
Voting discards this complementary information. Meta-reasoning preserves and
combines partial insights from multiple chains.

**CORRECT:**
```
Question: "What award did the director of Jaws win for Schindler's List?"

Chain 1: "Jaws was directed by Steven Spielberg..."
Chain 2: "Schindler's List won Best Picture and Best Director..."
Chain 3: "Spielberg directed both films..."

Meta-reasoner: Combines Chain 1 (Spielberg directed Jaws) + Chain 2 (awards) + Chain 3 (same director)
→ "Steven Spielberg won Best Director for Schindler's List"
```

**INCORRECT:**
```
[Majority vote on multi-hop with large answer space]
Chain 1: "Best Director"
Chain 2: "Academy Award"
Chain 3: "Oscar for Best Picture"

→ No majority; voting fails to synthesize partial correct information
```

Voting treats chains as independent votes rather than complementary evidence.

**Tradeoffs:**

- Token overhead: 5x tokens (1 greedy + 4 sampled chains + meta-reasoner)
- API calls: 6 total calls (5 decomposition chains + 1 meta-reasoner)
- Requirements: Few-shot examples for decomposition and meta-reasoner, retrieval
  system
- Gains: Consistent improvements over self-consistency on multi-hop QA

---

### Complexity-Based Prompting

**Mechanism:** Select few-shot examples with more reasoning steps and vote among
complex generated chains over simple ones.

**Triggers:**

- Multi-step reasoning problems with intermediate steps
- Math word problems requiring sequential calculations
- Problems where reasoning complexity varies significantly
- When avoiding spurious reasoning shortcuts is critical

**The process:**

```
1. Annotate few-shot examples with detailed reasoning chains (~9 steps vs ~3)
2. Sample multiple reasoning chains from model
3. Count reasoning steps in each chain
4. Vote only among the top-K most complex chains
```

**Why this works:** Simple chains often take shortcuts that happen to reach
correct answers on easy examples but fail on harder problems. Complex chains
that show full work are more likely to generalize correctly.

**CORRECT:**
```
Problem: "John has 3 times as many apples as Mary. Mary has 4 apples..."

Complex chain (preferred):
"Mary has 4 apples. John has 3 times Mary's amount. 3 × 4 = 12. John has 12."

Simple chain (filtered out):
"3 × 4 = 12"

→ Vote among chains showing full reasoning
```

**INCORRECT:**
```
[Vote equally among all chains regardless of complexity]
Chain 1 (complex): "Mary=4, John=3×4=12" ✓
Chain 2 (simple): "3×4=12" ✓
Chain 3 (simple, wrong): "3+4=7" ✗

→ Simple chains may get correct answer by coincidence on easy problems
   but fail systematically on harder ones
```

Equal weighting allows shortcut chains to dilute the vote.

**Tradeoffs:**

- Token overhead: 3-4x tokens (complex prompts ~9 steps vs simple ~3 steps)
- API calls: 50 samples for voting, select top K=30-40 complex chains
- Requirements: Annotated reasoning chains for 8 few-shot examples, large model
  (>100B parameters)
- Gains: Consistent improvements on multi-step math problems

---

### Boosted Prompt Ensembles

**Mechanism:** Iteratively construct few-shot prompts by selecting hard examples
where current ensemble shows disagreement.

**Triggers:**

- Multi-step reasoning with current prompt showing high variance
- Small labeled dataset available (50-300 samples) for train-time boosting
- Initial prompt suboptimal or distribution shift between train and test
- Problems where single prompt fails systematically on specific subtypes

**The process:**

```
1. Start with initial prompt
2. Evaluate on training set
3. Select examples where ensemble disagrees (hard examples)
4. Add hard examples to create new prompt
5. Repeat, building ensemble of prompts
6. At inference, vote across all prompts
```

**Why this works:** Boosting focuses on examples the current ensemble gets
wrong, creating prompts that specialize in different failure modes. The ensemble
covers more of the problem space than any single prompt.

**CORRECT:**
```
Round 1: Initial prompt fails on fraction problems
Round 2: Add fraction examples → new prompt handles fractions
Round 3: Ensemble still fails on unit conversion
Round 4: Add unit conversion examples → new prompt handles units

Final ensemble: Vote across all specialized prompts
```

**INCORRECT:**
```
[Random selection of few-shot examples]
→ May repeatedly sample similar examples
→ No systematic coverage of failure modes
```

Random selection doesn't target the specific weaknesses of current prompts.

**Tradeoffs:**

- Token overhead: n × m tokens (e.g., 10 prompts × 10 samples = 100x baseline)
- API calls: n × m calls per test question
- Requirements: Small training set, chain-of-thought generation,
  self-consistency sampling
- Gains: Outperforms self-consistency on math reasoning

---

### Multi-Perspective Self-Consistency (MPSC)

**Mechanism:** Generate solutions, specifications, and test cases, then rank by
consistency using 3-partite graph optimization.

**Triggers:**

- Code generation tasks where single-attempt accuracy is insufficient
- Programming problems requiring multiple verification perspectives
- Tasks with executable test cases and verifiable specifications
- Scenarios where inter-consistency between code artifacts can be measured

**The process:**

```
1. Generate multiple solutions (code implementations)
2. Generate multiple specifications (docstrings, type signatures)
3. Generate multiple test cases
4. Build 3-partite graph: solution ↔ spec ↔ tests
5. Score solutions by consistency across all three perspectives
6. Select highest-consistency solution
```

**Why this works:** A correct solution should be consistent with good
specifications and pass valid test cases. Cross-perspective consistency filters
out solutions that only appear correct from one viewpoint.

**CORRECT:**
```
Problem: "Write a function to find the second largest number"

Solution A: def f(arr): return sorted(arr)[-2]
Spec A: "Returns second largest element"
Tests: [1,2,3]→2, [5,5,3]→5

→ Check: Does Solution A match Spec A? Pass tests?
→ Solutions consistent across all three perspectives rank higher
```

**INCORRECT:**
```
[Rank solutions by code probability only]
Solution A: High probability but buggy edge case handling
Solution B: Lower probability but handles edge cases

→ Probability alone doesn't capture correctness
```

Single-perspective ranking misses consistency signals from specifications and
tests.

**Tradeoffs:**

- Token overhead: ~3.5x tokens (200 solutions + 50 specs + 100 test cases)
- API calls: 350 independent calls per problem
- Requirements: Code execution environment, few-shot examples for each
  perspective
- Gains: Substantial improvements on code generation benchmarks

---

### PREFER (Prompt Ensemble Learning via Feedback-Reflect-Refine)

**Mechanism:** Iteratively generates diverse prompts via feedback on errors,
reflection, and refinement, then ensembles with adaptive weights.

**Triggers:**

- Task requires high accuracy and stability across diverse inputs
- Single prompts show high variance or hallucination issues
- Hard examples exist that individual prompts fail to solve
- Manual prompt engineering is too costly or suboptimal

**The process:**

```
1. Start with initial prompt
2. Evaluate on training examples
3. For errors: LLM reflects on why prompt failed
4. LLM refines prompt based on reflection
5. Repeat for k iterations
6. Ensemble all prompts with learned weights
```

**Why this works:** Error-driven refinement creates prompts specialized for
different failure modes. The reflection step provides signal about what's
missing in current prompts.

**CORRECT:**
```
Initial prompt: "Solve the math problem step by step"
Error: Fails on problems requiring unit conversion
Reflection: "Prompt doesn't emphasize checking units"
Refined: "Solve step by step. Pay attention to unit conversions."

→ Each refinement addresses specific failure mode
```

**INCORRECT:**
```
[Generate random prompt variations without error feedback]
Variation 1: "Solve carefully"
Variation 2: "Think step by step"
Variation 3: "Be precise"

→ No targeted improvement; variations don't address actual failures
```

Random variation doesn't systematically address weaknesses.

**Tradeoffs:**

- Token overhead: k iterations with k prompts: k × (2-5 iterations) × 2x tokens
- API calls: 2k calls for training, k calls for inference
- Requirements: Training dataset for error feedback, multiple boosting
  iterations
- Gains: Outperforms single prompts significantly; outperforms other automated
  prompt optimization methods

---

### Refined Answer Distributions (RAD)

**Mechanism:** Iteratively refine answer distributions by marginalizing over
previous answers, weighting refinements by estimated probability of each answer.

**Triggers:**

- Reasoning tasks where self-consistency plateaus after few samples
- Problems where providing hints helps LLMs verify/refine answers
- Multi-step reasoning requiring answer distribution refinement
- Tasks where probability flow into correct answer exceeds flow out

**The process:**

```
1. Initial sampling: Generate B1 answers (e.g., 5)
2. For each unique answer, generate B2 refinement samples conditioned on that answer
3. Weight refinements by original answer probability
4. Repeat for 2-3 iterations with increasing sample sizes
5. Select answer with highest refined probability
```

**Why this works:** Self-conditioning on candidate answers acts as a
verification step. Correct answers survive refinement while incorrect answers
"flow" toward correct ones when re-examined.

**CORRECT:**
```
Iteration 1: Answers = {42: 60%, 44: 30%, 40: 10%}
Iteration 2: Condition on each, re-sample
  - Given "42 might be right": 80% confirm 42
  - Given "44 might be right": 60% switch to 42
  - Given "40 might be right": 70% switch to 42
Refined: {42: 78%, 44: 15%, 40: 7%}
```

**INCORRECT:**
```
[Simple self-consistency without refinement]
Answers = {42: 60%, 44: 30%, 40: 10%}
→ Select 42, but confidence is limited by initial sampling
→ No verification step to strengthen or correct
```

Standard SC doesn't leverage the verification signal from conditional
re-sampling.

**Tradeoffs:**

- Token overhead: 2-3x tokens compared to CoT+SC
- API calls: 40 total samples across 2-3 iterations (e.g., B1=5, B2=15, B3=20)
- Requirements: Problem amenable to self-verification, structured iteration
  budget
- Gains: Outperforms self-consistency especially when SC plateaus

---

### Dipper (Diversity in Prompts for Producing Ensembles)

**Mechanism:** Optimizes a diverse set of prompts using embedding-based
diversity objectives, then ensembles outputs via majority voting.

**Triggers:**

- Small models need to match large model performance
- Zero-shot setting where few-shot examples unavailable
- Need performance boost without model training or fine-tuning
- Want systematic prompt diversity beyond manual variation

**The process:**

```
1. Generate candidate prompt variations
2. Embed prompts using sentence embeddings
3. Select prompts maximizing pairwise diversity
4. Run all selected prompts in parallel
5. Majority vote across outputs
```

**Why this works:** Embedding-based selection ensures prompts are semantically
diverse, not just lexically different. Diverse prompts induce different
reasoning patterns, improving ensemble coverage.

**CORRECT:**
```
Diversity-optimized prompts:
P1: "Solve this step by step"
P2: "Think like a math teacher explaining to a student"
P3: "Break the problem into smaller parts"

→ Embeddings show these are semantically distinct
→ Each may succeed where others fail
```

**INCORRECT:**
```
[Lexically different but semantically similar prompts]
P1: "Solve step by step"
P2: "Solve it step by step"
P3: "Step by step, solve this"

→ Nearly identical embeddings; no real diversity
→ Ensemble gains minimal
```

Lexical variation without semantic diversity doesn't improve coverage.

**Tradeoffs:**

- Token overhead: n times base cost where n is ensemble size (3-9 typical)
- API calls: n parallel calls per query
- Requirements: Parallel batch inference, prompt generation, sentence embedding
  for diversity optimization
- Gains: Ensemble of smaller models can match or exceed single larger model
  performance

---

### Self-ICL

**Mechanism:** LLM generates pseudo-inputs and pseudo-labels from test query,
then uses them as ICL demonstrations for zero-shot scenarios.

**Triggers:**

- No access to training dataset or demonstration pool
- End-user query without example corpus
- Zero-shot setting where few-shot would help
- Challenging unexpected tasks without existing demonstrations

**The process:**

```
1. Given test query, ask LLM to generate k similar questions
2. For each generated question, ask LLM to provide answer
3. Use generated (question, answer) pairs as few-shot demonstrations
4. Solve original query with synthetic demonstrations in context
```

**Why this works:** LLMs can generate plausible examples for most task types.
These synthetic demonstrations provide the formatting and reasoning patterns
that few-shot learning requires, even without real examples.

**CORRECT:**
```
Test query: "What is the capital of Kazakhstan?"

Step 1 - Generate similar questions:
  "What is the capital of France?"
  "What is the capital of Japan?"

Step 2 - Generate answers:
  "France → Paris"
  "Japan → Tokyo"

Step 3 - Use as demonstrations:
  "Q: What is the capital of France? A: Paris
   Q: What is the capital of Japan? A: Tokyo
   Q: What is the capital of Kazakhstan? A: [generate]"
```

**INCORRECT:**
```
[Zero-shot without demonstrations]
"What is the capital of Kazakhstan?"
→ May produce wrong format or hallucinated answer
→ No examples to anchor response format
```

Zero-shot lacks the formatting guidance that demonstrations provide.

**Tradeoffs:**

- Token overhead: 3-5x tokens
- API calls: k+2 calls (1 for pseudo-inputs, k for pseudo-labels, 1 for final)
- Requirements: Instruction-following model, zero-shot capability essential
- Gains: Comparable to real 3-shot ICL in many settings

---

### Jekyll & Hyde (Persona-Neutral Ensemble)

**Mechanism:** Ensemble role-playing and neutral perspectives, selecting better
solution via LLM evaluator with position bias mitigation.

**Triggers:**

- Role-playing prompts may introduce bias for the given question
- Uncertain whether persona assignment will help or hurt performance
- Task requires balancing domain expertise with general reasoning
- Need robustness against persona-induced confusion

**The process:**

```
1. Generate domain-relevant persona (e.g., "expert mathematician")
2. Solve problem with persona ("Jekyll" - role-playing)
3. Solve problem without persona ("Hyde" - neutral)
4. LLM evaluator compares both solutions
5. Position-swap verification to mitigate position bias
6. Select winner or flag for review if inconsistent
```

**Why this works:** Personas can help (domain expertise) or hurt (false
confidence, irrelevant context). Ensembling both perspectives with neutral
evaluation captures benefits while hedging against persona-induced errors.

**CORRECT:**
```
Problem: "Calculate compound interest..."

Jekyll (Accountant persona): "As an accountant, I'll use A = P(1+r)^t..."
Hyde (Neutral): "To solve this: A = P(1+r)^t..."

Evaluator: Both agree on formula and answer
→ High confidence in shared answer
```

**INCORRECT:**
```
[Always use persona without fallback]
Problem: "What's 2+2?"
Persona (Expert Physicist): "As a physicist, I must consider relativistic effects..."
→ Persona adds irrelevant complexity to simple problem
```

Blind persona application can introduce confusion on simple tasks.

**Tradeoffs:**

- Token overhead: 3-5x tokens (persona generator + dual solvers + evaluator)
- API calls: 3.81 avg calls (1 persona gen + 2 solvers + 1.81 evaluator)
- Requirements: LLM for persona generation, LLM for evaluation, consistency
  verification
- Gains: Consistent improvement over best single-perspective baseline

---

### Ordered Prompts (Entropy-Based Selection)

**Mechanism:** Rank few-shot example orderings using entropy metrics on
model-generated probing set to select performant permutations.

**Triggers:**

- Few-shot in-context learning with 3-8 examples where order matters
- High variance observed across different example orderings
- No labeled development set available for permutation selection
- True few-shot setting where additional annotated data is unavailable

**The process:**

```
1. Generate all permutations of few-shot examples (n! for n examples)
2. For each permutation, generate probing outputs on unlabeled questions
3. Compute entropy of output distribution for each permutation
4. Select permutation with lowest entropy (most consistent outputs)
5. Use selected ordering for inference
```

**Why this works:** Lower entropy indicates the model is more confident and
consistent. Permutations that produce scattered, high-entropy outputs are likely
confusing the model.

**CORRECT:**
```
Examples: A, B, C (3-shot)
Permutations: ABC, ACB, BAC, BCA, CAB, CBA

Test on probing set:
  ABC → Entropy 0.3 (consistent predictions)
  BAC → Entropy 0.8 (scattered predictions)
  ...

Select ABC for deployment
```

**INCORRECT:**
```
[Use arbitrary example ordering]
Random order: CAB
→ May happen to be worst permutation
→ High variance from ordering sensitivity goes unaddressed
```

Arbitrary ordering gambles on getting lucky with permutation.

**Tradeoffs:**

- Token overhead: n! permutations for probing (24x for 4-shot)
- API calls: n! calls for probing generation + n! calls for evaluation
- Requirements: Few-shot examples, generative model for probing set
- Gains: Substantial average improvement by reducing permutation variance

---

### PEDAL (Diverse Exemplars with Greedy Decoding)

**Mechanism:** Generate multiple greedy outputs using diverse exemplar sets,
then aggregate with LLM-based selection.

**Triggers:**

- Need better accuracy than greedy decoding with lower cost than
  self-consistency
- Math word problems or multiple-choice reasoning tasks
- Tasks where diverse exemplars can induce output variation
- Cost-sensitive deployments where output token count matters

**The process:**

```
1. Create k diverse exemplar sets (different few-shot examples)
2. Run greedy decoding (temp=0) with each exemplar set
3. Collect k deterministic outputs
4. Use LLM (or USC) to select best answer among the k outputs
```

**Why this works:** Greedy decoding is deterministic, so diversity must come
from input variation. Different exemplar sets prime different reasoning
patterns, achieving diversity without the token cost of temperature sampling.

**CORRECT:**
```
Exemplar Set 1: Easy arithmetic examples → Greedy output A
Exemplar Set 2: Word problem examples → Greedy output B
Exemplar Set 3: Multi-step examples → Greedy output C

LLM selector: "Which of A, B, C is most likely correct?"
→ Select best with minimal output tokens
```

**INCORRECT:**
```
[Self-consistency with high temperature]
40 samples at temp=0.7 → 40 long reasoning chains
→ High output token cost
→ PEDAL achieves similar gains with ~60-80% fewer output tokens
```

Temperature sampling multiplies output tokens; PEDAL uses input diversity
instead.

**Tradeoffs:**

- Token overhead: 1.5x input tokens, 0.4x output tokens vs Self-Consistency
- API calls: k+1 calls (k diverse prompts + 1 aggregation)
- Requirements: Few-shot examples, k diverse exemplar sets (typically 3-4)
- Gains: Accuracy improvement over greedy with substantially fewer output tokens

---

### Synthetic Prompting

**Mechanism:** LLM generates additional demonstrations via backward question
synthesis and forward reasoning refinement from seed examples.

**Triggers:**

- Only 2-4 seed examples available for complex reasoning tasks
- Need diverse demonstrations but manual annotation is costly
- Existing demonstrations are too simple for target task complexity
- Task requires complex multi-step reasoning chains

**The process:**

```
1. Backward synthesis: Generate questions that would lead to seed answers
2. Forward synthesis: Generate reasoning chains for new questions
3. Quality filter: Keep chains that reach correct answers
4. Cluster and select: Diverse subset of synthetic demonstrations
5. Use synthetic examples as few-shot demonstrations
```

**Why this works:** LLMs can generate plausible reasoning chains, and the
backward-forward process ensures question-answer coherence. Clustering maintains
diversity across the synthetic demonstration set.

**CORRECT:**
```
Seed: "Q: 2+3=? A: 5 (because 2+3=5)"

Backward: Generate "Q: What is 4+6?" from similar patterns
Forward: Generate "A: 10 (because 4+6=10)"
Filter: Verify 4+6 does equal 10

→ Use as additional demonstration
```

**INCORRECT:**
```
[Use only the 2-4 seed examples]
Limited examples → Limited reasoning pattern coverage
→ Model may not generalize to harder problems
```

Few seed examples constrain the diversity of reasoning patterns shown.

**Tradeoffs:**

- Token overhead: 1000x synthesis calls + 3x forward sampling per synthetic
  example
- API calls: 1000 backward + 1000 forward calls for synthesis; 1 inference call
- Requirements: 2-8 seed examples with reasoning chains, clustering for
  selection
- Gains: Substantial improvement over using seed examples alone

---

### Reprompting (Gibbs Sampling)

**Mechanism:** Iteratively samples and evolves CoT recipes through Gibbs
sampling with rejection to optimize few-shot prompts.

**Triggers:**

- Human-written CoT prompts unavailable or require costly engineering
- Need to optimize CoT prompts for specific model without human intervention
- Tasks requiring multi-step reasoning where initial zero-shot solutions vary
- Fair comparison needed across different LLMs with model-specific prompts

**The process:**

```
1. Initialize with zero-shot CoT solutions as "recipe" candidates
2. Sample one recipe element (example) to replace
3. Generate new candidate for that position
4. Accept/reject based on validation accuracy (Gibbs sampling)
5. Repeat for many iterations
6. Final recipe: optimized few-shot prompt
```

**Why this works:** Gibbs sampling explores the space of possible demonstration
sets while maintaining coherence. Rejection sampling ensures only improvements
are kept.

**CORRECT:**
```
Initial recipe: [ZeroShot_Ex1, ZeroShot_Ex2, ZeroShot_Ex3]
Iteration 1: Replace Ex2 with new candidate → Accuracy improved → Accept
Iteration 2: Replace Ex1 with new candidate → Accuracy dropped → Reject
...
Final: Optimized prompt outperforms human-written CoT
```

**INCORRECT:**
```
[Use human-written CoT prompts without optimization]
Human prompt: Generic examples from original paper
→ May not match target model's strengths
→ May not cover target task distribution
```

Generic prompts aren't optimized for specific model-task combinations.

**Tradeoffs:**

- Token overhead: 10000x+ tokens during training phase
- API calls: Up to 20000 iterative sampling calls
- Requirements: Training question-answer pairs, iterative sampling budget
- Gains: Substantially outperforms human-written CoT and other automated prompt
  methods

---

### Fairness-guided Few-shot Prompting

**Mechanism:** Select few-shot examples that minimize predictive bias by
maximizing entropy on content-free inputs.

**Triggers:**

- Few-shot prompting shows high variance across example selections
- Performance is sensitive to demonstration order
- Need to select optimal demonstrations without labeled dev set
- Classification tasks where bias can be measured

**The process:**

```
1. Create content-free test inputs (e.g., "N/A", empty strings)
2. For each candidate demonstration set:
   a. Run model on content-free inputs
   b. Compute entropy of output distribution
3. Select demonstration set with highest entropy on content-free inputs
4. Use selected demonstrations for inference
```

**Why this works:** High entropy on content-free inputs means the model isn't
biased toward any particular output. Biased prompts would produce low entropy
(strong preference for certain outputs even without meaningful input).

**CORRECT:**
```
Demo Set A → On "N/A" input: P(Yes)=0.5, P(No)=0.5 → High entropy
Demo Set B → On "N/A" input: P(Yes)=0.9, P(No)=0.1 → Low entropy (biased)

Select Demo Set A (unbiased)
```

**INCORRECT:**
```
[Select demonstrations by surface similarity to test query]
High similarity demos may share spurious features
→ Model learns shortcuts, not generalizable patterns
```

Similarity-based selection can amplify biases rather than reduce them.

**Tradeoffs:**

- Token overhead: Standard few-shot tokens (no overhead at inference)
- API calls: O(N) for T-fair, O(N²) for G-fair during search phase; 1 at
  inference
- Requirements: Pool of candidate demonstrations, content-free input
  construction
- Gains: Substantial improvement over random selection on classification tasks

---

## Decision Guidance

| Scenario                              | Recommended Technique          | Reason                                 |
| ------------------------------------- | ------------------------------ | -------------------------------------- |
| Math/arithmetic with fixed answers    | Self-Consistency               | Simple, effective, well-understood     |
| Free-form generation (summaries, QA)  | Universal Self-Consistency     | Extends SC beyond exact-match voting   |
| Multi-hop QA with partial info        | Multi-Chain Reasoning          | Synthesizes across incomplete chains   |
| Unknown question type                 | MoRE                           | Generalizes across reasoning domains   |
| Creative/planning requiring lookahead | Tree of Thoughts               | Enables backtracking and exploration   |
| Method diversity more than token div  | Diversity of Thought           | Explicitly varies reasoning approaches |
| Code generation with verification     | Multi-Perspective SC           | Leverages executable test cases        |
| Zero-shot without examples            | Self-ICL                       | Self-generates demonstrations          |
| Prompt optimization without training  | Reprompting                    | Automated CoT discovery                |
| Cost-sensitive deployment             | PEDAL or IDiv-Se               | Lower token overhead than SC           |
| Persona uncertainty                   | Jekyll & Hyde                  | Mitigates persona-induced bias         |
| Few-shot order sensitivity            | Ordered Prompts or Fairness-FP | Reduces permutation variance           |
| Self-consistency plateau              | Refined Answer Distributions   | Iterative distribution refinement      |
| Small model, need big model perf      | Dipper                         | Ensemble of diverse prompts            |

---

## Composability Notes

**Preparation technique:** Before applying sampling methods, demonstration
quality can be optimized by uncertainty-based selection: sample k answers per
candidate question, compute disagreement or entropy, and annotate the most
uncertain questions as demonstrations. This identifies questions where the
model needs guidance most, improving the base demonstrations that sampling
techniques operate over.

**Foundation techniques:**

- Self-Consistency builds on Chain-of-Thought and is composed into most other
  techniques
- Tree of Thoughts extends both CoT and Self-Consistency with search
- Universal Self-Consistency replaces voting step; compatible with any
  multi-sample technique

**Technique combinations:**

- Diversity of Thought + Self-Consistency: Use diverse approaches with sampling
  within each
- Tree of Thoughts + PREFER: Iteratively refine thought generation prompts
- Multi-Chain Reasoning + Complexity-Based: Prioritize complex chains in
  meta-reasoning
- Self-ICL + Self-Consistency: Sample multiple pseudo-demonstrations, then vote
- MoRE + Self-Consistency: Each expert can use SC internally for within-expert
  diversity
- USC + PEDAL: Use USC as the selection mechanism for PEDAL's diverse outputs

**Aggregation methods:**

- Voting: Self-Consistency, Diversity of Thought, Dipper, Complexity-Based
- LLM Selection: Universal Self-Consistency, PEDAL, Jekyll & Hyde
- Ranking: Ordered Prompts, Multi-Perspective SC
- Synthesis: Multi-Chain Reasoning, PREFER, RAD
- Expert Agreement: MoRE (inter-expert consistency)
- Search: Tree of Thoughts

**Anti-patterns:**

- Avoid combining techniques with conflicting context strategies (isolated vs
  accumulated)
- Memory-requiring techniques (ToT, Boosted Ensembles, Reprompting) have higher
  state management overhead
- Most techniques require few-shot examples; Self-ICL, Dipper, and USC work
  zero-shot
- Don't use MoRE when question type is known—use the appropriate specialized
  expert directly
- Don't apply USC to tasks where exact-match voting works—it adds unnecessary
  overhead
