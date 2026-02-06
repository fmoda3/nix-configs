# Context Augmentation: Research-Backed Techniques

Context augmentation addresses the problem of missing or insufficient information
in prompts. When models lack the knowledge or examples needed to reason
correctly, augmentation techniques retrieve, generate, or select additional
context to bridge the gap.

**Meta-principle**: The right examples teach the model what to do; the wrong
examples (or random examples) teach nothing -- or worse, mislead. Selection
strategy matters more than selection quantity.

**Prerequisite**: Basic understanding of in-context learning (few-shot prompting).

---

## Technique Selection Guide

| Domain | Technique | Trigger Condition | Stacks With | Conflicts With | Cost/Tradeoff |
|--------|-----------|-------------------|-------------|----------------|---------------|
| Example Retrieval | KATE | Few-shot variance, similar examples exist | Generated Knowledge, Cover-LS | - | O(n) index storage |
| Example Retrieval | UDR | Multi-task deployment, avoid per-task training | KATE patterns | Per-task retrievers | One-time training cost |
| Knowledge Generation | Generated Knowledge | Missing commonsense, no knowledge base | KATE, fine-tuning | - | M×(knowledge+question) tokens |
| Example Selection | Cover-LS | Compositional generalization, structured output | KATE (as retriever) | Pure similarity retrieval | Auxiliary model required |
| Example Selection | LENS | Need stable demos across inputs, high variance | - | Per-input retrieval | Upfront search cost |
| Example Selection | USP | No labeled data, only unlabeled queries | - | Labeled example methods | Multiple decoding passes |

---

## Quick Reference: Key Principles

1. **KATE for Similarity Retrieval** -- When test inputs have semantically similar training examples, retrieve nearest neighbors to reduce few-shot variance

2. **UDR for Multi-Task Deployment** -- A single retriever trained on LM feedback generalizes across 30+ task types without per-task training

3. **Generated Knowledge for Missing Facts** -- When the model lacks domain knowledge, generate background knowledge and prepend to questions

4. **Cover-LS for Compositional Generalization** -- Select demonstrations that collectively cover output structures, not just input similarity

5. **Cover-Utt as Simpler Fallback** -- When structure prediction fails, cover input words instead of output structures

6. **LENS for Task-Level Selection** -- Find fixed "support examples" that work across all test inputs, not per-input retrieval

7. **USP for Zero-Shot Settings** -- Use model's own confident predictions as pseudo-demonstrations when no labels exist

8. **Encoder Choice Matters for KATE** -- Base encoders use Euclidean distance; fine-tuned encoders (NLI, STS) use cosine similarity

9. **Training-Time Noise Prevents Over-Copying** -- When fine-tuning with demonstrations, use simpler/noisier demos at train time than test time

10. **Quality Over Quantity** -- Few well-selected examples often outperform many random examples

---

## KATE: Similarity-Based Example Selection

Retrieve in-context examples semantically similar to the test input using
k-nearest neighbors in embedding space.

**When to use:**

- Few-shot performance varies wildly across runs
- Random example selection produces inconsistent results
- Test inputs have semantically similar examples in the training pool

**The process:**

```
1. Encode all training examples using sentence encoder
2. At inference, encode test input with same encoder
3. Retrieve k nearest neighbors from training set
4. Concatenate retrieved examples as demonstrations
5. Append test input and generate
```

**Why this works**: Semantically similar examples provide more relevant
context than random samples. The model sees input-output patterns that
closely match the test case, reducing the inferential leap required.
Similar examples also tend to share vocabulary and structure, making
pattern transfer more direct.

**Implementation details:**

- Base encoder (RoBERTa-large): Use Euclidean distance for retrieval
- Fine-tuned encoders (KATE_nli, KATE_nli+sts-b): Use cosine similarity
- Fine-tuning on task-related data (NLI, STS, or the task itself) improves retrieval quality
- Ordering is data-dependent: default places closest example last (nearest test input), but some datasets benefit from reverse order

**Critical insight**: Performance improves as the training set available for
retrieval grows larger. More candidates means higher probability of finding
truly relevant examples.

**CORRECT:**
```
# Sentiment analysis with KATE
Training pool: 10,000 labeled reviews
Test input: "The cinematography was breathtaking but the plot dragged."

Retrieved (k=3, by similarity):
1. "Beautiful visuals couldn't save the weak storyline." -> Negative
2. "Stunning camera work, disappointing narrative." -> Negative
3. "Gorgeous shots throughout, though pacing suffered." -> Mixed

# Model sees structurally similar "visual praise + narrative criticism" pattern
```

**INCORRECT:**
```
# Random selection ignores input structure
Test input: "The cinematography was breathtaking but the plot dragged."

Random examples:
1. "Best comedy I've seen all year!" -> Positive
2. "Waste of money, don't bother." -> Negative
3. "The sequel improves on everything." -> Positive

# No structural similarity to test input's "X was good but Y was bad" pattern
```

Random selection provides no signal about how to handle mixed-sentiment
inputs with contrasting clauses.

**Tradeoffs:**

- Token overhead: k examples × average example length
- Requires embedding index over training set (O(n) storage)
- Fine-tuned encoders improve results but add training cost
- Fails when no similar examples exist (compositional splits)

---

### UDR: Unified Demonstration Retriever

A single multi-task model trained to retrieve demonstrations across 30+ task
types. Uses LM feedback to learn what makes demonstrations helpful, then
generalizes across tasks without per-task training.

**When to use:**

- Deploying demonstration retrieval across many tasks
- Want to avoid training separate retrievers per task
- Need zero-shot transfer to new/unseen tasks
- Storage/deployment cost of multiple retrievers is prohibitive

**The process:**

```
1. Training (one-time):
   a. For each task, retrieve candidates from training set
   b. Score candidates by LM's conditional probability on ground truth
   c. Rank candidates using scores
   d. Train bi-encoder with list-wise ranking loss
   e. Iterate: use trained retriever to mine better candidates

2. Inference:
   a. Encode test input with task instruction prefix
   b. Retrieve nearest demonstrations from task's training set
   c. Concatenate and generate
```

**Why this works**: Different tasks share common patterns of what makes
demonstrations helpful -- examples that increase LM's probability of
generating correct outputs. By training on LM feedback across many tasks,
the retriever learns these cross-task patterns. The task instruction prefix
enables task-specific features without separate models.

**Implementation details:**

- Architecture: Bi-encoder with two BERT-base encoders (query and demonstration)
- Loss: LambdaRank-inspired list-wise ranking loss + in-batch negative loss
- Task instruction: Prepend task description (e.g., "Summarize the text") to both query and candidates
- Iterative mining: 3 iterations of candidate refinement using the retriever itself
- Task balancing: Multinomial sampling with α=0.5 prevents high-resource task dominance

**Critical insight**: Retrieval quality transfers across inference LMs of
vastly different sizes (1.3B to 175B parameters). Train once, deploy anywhere.

**CORRECT:**
```
# Multi-task deployment with UDR
Tasks: sentiment analysis, summarization, QA, NLI

Single UDR model retrieves demonstrations for all tasks
Each task uses its own instruction prefix:
- "Classify the sentiment:"
- "Summarize the text:"
- "Answer the question:"
- "Determine entailment:"

# One model, one index per task, unified retrieval logic
```

**INCORRECT:**
```
# Separate retrievers per task
Tasks: sentiment analysis, summarization, QA, NLI

Train KATE_sentiment, KATE_summarization, KATE_qa, KATE_nli
Maintain 4 separate models
4x storage, 4x deployment complexity
Each requires task-specific training data and tuning

# Scales poorly with task count
```

Separate retrievers multiply storage and maintenance burden linearly with
task count.

**Tradeoffs:**

- Training cost: Requires LM scoring across all tasks (one-time)
- Slightly lower than task-specific retriever on individual tasks
- Strong zero-shot transfer to unseen tasks
- Works across inference LMs of different sizes

---

## Generated Knowledge Prompting

Generate background knowledge from a language model, then prepend it to the
question before inference. The knowledge transforms implicit reasoning into
explicit deduction.

**When to use:**

- Model lacks domain knowledge for commonsense reasoning
- No appropriate knowledge base exists for retrieval
- Questions require implicit world knowledge

**The process:**

```
1. Write 5 question-knowledge demonstration pairs
   (Question + helpful knowledge, NOT question + answer)

2. For new question:
   a. Prompt knowledge generator with demos + question
   b. Sample M=20 knowledge statements (nucleus p=0.5)

3. For each knowledge statement:
   a. Prepend to original question
   b. Query inference model
   c. Record answer confidence

4. Select answer with highest confidence across all attempts
```

**Why this works**: The model may "know" relevant facts but fail to retrieve
them when answering directly. Generated knowledge makes implicit knowledge
explicit, transforming commonsense reasoning into supported deduction. The
knowledge statement provides the missing premise that connects question to
answer.

**Critical insight**: A model can benefit from knowledge it generates itself.
Self-amplification works because generation and inference are separate
processes -- the knowledge statement provides scaffolding that the inference
pass can leverage.

**CORRECT:**
```
# Knowledge demonstration (teaches format, not answer)
Question: "How many wings does a penguin have?"
Knowledge: "Birds have two wings. Penguins are a type of bird."

# NOT this (gives away answer):
Question: "How many wings does a penguin have?"
Knowledge: "Penguins have two wings."
```

**INCORRECT:**
```
# Demonstrations that directly answer
Question: "How many wings does a penguin have?"
Knowledge: "Penguins have two wings."

Question: "What color is grass?"
Knowledge: "Grass is green."

# Model learns to generate direct answers, not supporting knowledge
# Defeats the purpose of separating knowledge from inference
```

Demonstrations should show helpful background knowledge, not restatements
of the answer. The goal is to teach the model to generate premises, not
conclusions.

**Tradeoffs:**

- Token overhead: M statements × (knowledge length + question length) per inference
- API cost: Separate generation call + M inference calls
- Quality degrades with smaller knowledge generators (needs 6.7B+ parameters)
- Knowledge can be wrong -- evaluation found ~17% non-factual statements
- Self-amplification: Works even when generator = inference model

---

## Diverse Demonstrations (Cover-LS)

Select demonstrations that collectively cover the structural elements (local
structures) needed in the output, rather than maximizing similarity to input.

**When to use:**

- Compositional generalization: test outputs combine structures not seen together in training
- Similarity-based retrieval returns repetitive, structurally-similar examples
- Structured output tasks (semantic parsing, code generation)

**The process:**

```
1. Train auxiliary model to predict output structures from input
2. For test input, generate beam of candidate outputs
3. Extract local structures (sub-trees) from all candidates
4. Sort structures by size (largest first)
5. For each structure:
   a. Find training example containing that structure
   b. Add to demonstration set
   c. Mark all structures in that example as covered
6. Continue until k demonstrations selected
```

**Why this works**: Compositional generalization requires combining known
structures in new ways. If demonstrations only show structures similar to
each other, the model has no template for novel combinations. Covering
diverse structures provides the building blocks; the model learns to
compose them. Local structures (sub-trees of the output program) are the
atomic units of composition.

**Local structure definition**: Given an output program parsed as a tree,
local structures are connected sub-graphs including parent-child edges and
sibling edges (between consecutive arguments). This captures both
hierarchical and sequential relationships.

**Implementation details:**

- Auxiliary model: T5 fine-tuned to predict anonymized programs
- Beam size B: Use multiple beam candidates to increase structure coverage
- Retriever: BM25 or SBERT to select among examples containing target structure
- Diversity: Remove examples with same template after selection

**Critical insight -- over-copying prevention**: When fine-tuning with
demonstrations, the model learns to copy from similar demonstrations rather
than compose. Mitigation: at training time, use only size-1 local structures
(individual symbols) and random retrieval. At test time, use full Cover-LS.
This asymmetry forces the model to learn composition, not copying.

**CORRECT:**
```
# Semantic parsing with structure coverage
Test: "Find meetings with my team and David's reportees"
Predicted structures: [CreateEvent, AttendeeList, FindReports, ...]

Demonstration 1: covers [CreateEvent, AttendeeList]
"Set up a meeting with Alice and Bob"

Demonstration 2: covers [FindReports]
"Who reports to Sarah?"

Demonstration 3: covers [Constraint, RecipientWithNameLike]
"Find emails from people named Chen"

# Each demo contributes different structures; together they cover the output
```

**INCORRECT:**
```
# Similarity-based retrieval (KATE)
Test: "Find meetings with my team and David's reportees"

Demo 1: "Find meetings with my team" -> similar but missing FindReports
Demo 2: "Find meetings with the sales team" -> nearly identical structure
Demo 3: "Show meetings with my direct reports" -> still missing FindReports

# All demos have similar structure; none covers FindReports
# Model has no template for the novel structure combination
```

Similarity retrieval finds examples that look like the input but may all
share the same structural gaps.

**Cover-Utt fallback**: When structure prediction fails (auxiliary model
produces no correct structures), cover input words instead of output
structures. Less effective but requires no auxiliary model.

**Tradeoffs:**

- Complexity: Requires auxiliary model for structure prediction
- Token overhead: Similar to KATE (k demonstrations)
- Fails when auxiliary model cannot predict any correct structures
- Demo efficiency: 4 Cover-LS demonstrations can match 24 similarity-based

---

## LENS: Support Example Selection

Select task-representative "support examples" via a two-stage filter-then-search
process. Unlike KATE (which retrieves test-specific examples), LENS finds
examples that characterize the task itself and work across all test inputs.

**When to use:**

- Need stable, reusable demonstrations across many test inputs
- Task-level example selection preferred over test-specific retrieval
- Previous coreset selection methods (gradient-based) underperform for ICL
- Random example selection causes high variance

**The process:**

```
Stage 1: Filter (reduce candidates)
  1. For each training example e, compute InfoScore:
     I(e) = Σ c(e, e') for all e' in score set
     where c(e, e') = p(y'|x,y,x') - p(y'|x')
  2. Progressive filtering: iteratively expand score set, filter low-scoring
  3. Retain top m candidates (typically 500)

Stage 2: Search (find best permutation)
  1. Initialize beam of k example permutations
  2. For each iteration:
     a. Substitute: replace random example with diverse high-InfoScore candidate
     b. Shuffle: try different orderings
     c. Evaluate on validation set
     d. Keep top-B permutations
  3. Return best permutation as support examples
```

**Why this works**: InfoScore measures how much an example helps the model
predict correctly on other examples. High-InfoScore examples carry more
task signal. The diversity term prevents selecting redundant examples that
provide overlapping information. The result is a compact set that
characterizes the task.

**InfoScore formula**: c(e, e') = p_G(y'|x,y,x') - p_G(y'|x')

This is the probability gain from conditioning on example e when predicting
e'. Positive values mean e helps; the sum over all e' measures e's overall
contribution to the task.

**Progressive filtering**: Computing InfoScore over the full training set
is O(n²). Progressive filtering achieves O(n log n) by iteratively expanding
the score set while shrinking candidates -- promising examples get more
computation, poor examples are filtered early.

**Critical insight**: Support examples are significantly less sensitive to
ordering than randomly selected examples. Random examples can swing from
near-random to near-optimal with different orderings; support examples
remain stable.

**CORRECT:**
```
# Task-level support examples for sentiment analysis
LENS selection (one-time):
  Filter: 67,000 training examples -> 500 candidates
  Search: Find 8-example permutation maximizing validation accuracy

Support examples (fixed, reused):
1. "Absolutely loved it, best film of the year!" -> Positive
2. "Waste of time, don't bother." -> Negative
3. "It was okay, nothing special." -> Neutral
... (5 more)

# Same 8 examples used for ALL test inputs
# No per-input retrieval at inference time
```

**INCORRECT:**
```
# Using LENS examples but re-retrieving per input
Test input 1: retrieve similar examples from LENS candidates
Test input 2: retrieve different similar examples

# Defeats the purpose -- LENS finds task-representative examples
# that work universally, not input-specific examples
```

LENS examples are designed to characterize the task, not match specific
inputs. Per-input retrieval undermines the stability benefit.

**Tradeoffs:**

- Requires validation set for search stage (small sample suffices)
- Higher upfront cost than KATE, but amortized over many test inputs
- Support examples transfer well across LMs of different sizes
- Ground truth labels matter for support examples (unlike random examples)

---

## USP: Zero-Shot Pseudo-Demonstrations

When no labeled examples exist, use the model's own confident predictions as
pseudo-demonstrations. Select high-confidence model outputs from unlabeled
data to construct ICL examples without any ground truth labels.

**When to use:**

- No labeled training examples available for the task
- Transductive zero-shot setting with unlabeled test queries
- Novel tasks revealed only at test time
- Obtaining even a few labels requires significant human effort

**The process:**

```
1. Categorize task type:
   - CLS: known small label space (classification)
   - SFG: many possible responses, few correct (short-form generation)
   - LFG: many plausible responses, longer outputs (long-form generation)

2. Stage 1 -- Score unlabeled samples:
   CLS: Query once, use negative entropy of logits
        F_CLS = Σ p(c|x) log p(c|x) over classes c

   SFG: Query M times with temperature, use normalized entropy
        F_SFG = -[Σ freq(answer) log freq(answer)] / log M

   LFG: Query M times, use average pairwise ROUGE
        F_LFG = (2/M(M-1)) Σ ROUGE(response_i, response_j)
        Filter outliers: remove if score > Q3 + 1.5×IQR

3. Stage 2 -- Select pseudo-demonstrations:
   - Rank by confidence score
   - Select K candidates with diversity penalty
   - For CLS: ensure K/|C| examples per class for balance
   - Prepend to test queries (greedy decoding)
```

**Why this works**: Confident predictions are more likely to be correct.
By selecting high-confidence outputs as pseudo-demonstrations, USP creates
a self-consistent set of examples that guide the model toward similar
confident behavior on test inputs. The model essentially teaches itself
the task format and expected outputs.

**Implementation details:**

- Unlabeled sample requirement: 64 samples typically sufficient
- CLS class balancing: Generate K/|C| pseudo-demos per class to prevent bias toward confident classes
- LFG outlier filtering: Extremely high confidence often indicates task misunderstanding (e.g., generating text completion instead of summary); filter using IQR
- Greedy decoding in Stage 2: Temperature=0 for final predictions

**Critical insight**: Average Stage 1 confidence predicts improvement magnitude.
High average confidence means the model is already certain -- less room for
USP to help. Low average confidence indicates uncertainty where pseudo-demos
provide more value.

**CORRECT:**
```
# Zero-shot classification with USP
Task: Sentiment (Positive/Negative/Neutral)
Unlabeled queries: 64 samples

Stage 1 scores (negative entropy):
  "Great product!" -> 0.92 (confident Positive)
  "Terrible service" -> 0.88 (confident Negative)
  "It arrived on time" -> 0.31 (uncertain)

Selected pseudo-demos (top by confidence, class-balanced):
  2 Positive, 2 Negative, 2 Neutral (if K=6)

# Model sees confident examples of each class
```

**INCORRECT:**
```
# Selecting pseudo-demos by confidence only (no class balance)
Top 6 by confidence:
  "Great product!" -> Positive
  "Amazing quality!" -> Positive
  "Best purchase ever!" -> Positive
  "Love it!" -> Positive
  "Excellent value!" -> Positive
  "Terrible service" -> Negative

# 5 Positive, 1 Negative, 0 Neutral
# Model biased toward Positive predictions
```

Without class balancing, confident classes dominate pseudo-demos and bias
subsequent predictions.

**Tradeoffs:**

- Only requires 64 unlabeled samples
- CLS selector uses logits (single query); SFG/LFG require M decoding passes
- Larger/better-calibrated models yield higher quality pseudo-demos
- Gains larger on generative tasks than classification

---

## Selection Decision Tree

```
START: Do you have labeled training examples?
  |
  NO --> Do you have unlabeled queries?
  |        |
  |        YES --> USP (pseudo-demonstrations)
  |        |
  |        NO --> Do you need world knowledge?
  |                 |
  |                 YES --> Generated Knowledge Prompting
  |                 |
  |                 NO --> Cannot augment (need some data)
  |
  YES --> Do you need same demos for all inputs?
           |
           YES --> LENS (support examples)
           |
           NO --> Deploying across many tasks?
                   |
                   YES --> UDR (unified retriever)
                   |
                   NO --> Does task require novel structure composition?
                           |
                           YES --> Can you train auxiliary model?
                           |        |
                           |        YES --> Cover-LS
                           |        |
                           |        NO --> Cover-Utt or KATE
                           |
                           NO --> KATE (similarity retrieval)
```

---

## Composition Table

| Technique | Composes Well With | Conflicts With |
|-----------|-------------------|----------------|
| KATE | Generated Knowledge, Cover-LS (as retriever) | - |
| UDR | Same patterns as KATE | Per-task retrievers (redundant) |
| Generated Knowledge | KATE, fine-tuning | - |
| Cover-LS | KATE/BM25 (as retriever), fine-tuning | Pure similarity retrieval |
| LENS | - | Per-input retrieval (defeats purpose) |
| USP | Can bootstrap LENS | Labeled example methods |

**Common composition patterns:**

1. **KATE + Generated Knowledge**: Prepend generated knowledge, then retrieved examples, then test input

2. **Cover-LS + KATE**: Use KATE/SBERT as the retriever component within Cover-LS for selecting among structure-matching examples

3. **USP → LENS**: Start with USP pseudo-demos, collect labels over time, transition to LENS for better quality

4. **Cover-LS + Fine-tuning**: Use Cover-LS_1 (symbol coverage only) with random retrieval at training time; full Cover-LS at test time

---

## Anti-Patterns

### The Similar-Examples Trap

**Anti-pattern**: Retrieving examples by similarity alone when the task
requires compositional generalization.

```
# PROBLEMATIC
Task: Semantic parsing with novel structure combinations
Retrieval: KATE finds 8 most similar examples

Result: All examples share similar structure
Test case requires novel combination not demonstrated
Model fails to compose structures it hasn't seen together
```

Similarity-based retrieval returns structurally redundant examples. For
compositional tasks, use Cover-LS to ensure structural diversity.

```
# BETTER
Task: Semantic parsing with novel structure combinations
Retrieval: Cover-LS selects examples covering needed structures

Result: Examples demonstrate different structures
Test case can be composed from demonstrated parts
```

### The Over-Copying Trap

**Anti-pattern**: Fine-tuning with high-quality demonstrations causes model
to copy from demos rather than compose.

```
# PROBLEMATIC
Training: Use Cover-LS with BM25 retrieval at training time
          Demonstrations are highly similar to training targets

Result: Model learns to copy large chunks from similar demos
        Fails when test demos don't contain exact patterns needed
```

The model over-relies on demonstration similarity because training always
provided near-perfect matches.

```
# BETTER
Training: Use Cover-LS_1 (symbol-only coverage) with random retrieval
          Demonstrations are noisier, less similar to targets

Inference: Use full Cover-LS with BM25 retrieval

Result: Model learns to compose from imperfect demos
        Generalizes better to novel test cases
```

### The Random-Selection Trap

**Anti-pattern**: Using random example selection when systematic selection
is feasible.

```
# PROBLEMATIC
Task: Classification with 67k training examples
Selection: Random 8 examples per inference

Result: High variance across runs
        Some random sets mislead model
        Inconsistent production behavior
```

Random selection provides no guarantee of quality or coverage.

```
# BETTER
Task: Classification with 67k training examples
Selection: LENS finds 8 support examples (one-time)
           OR KATE retrieves per-input (if input-specific matters)

Result: Stable performance
        Examples selected to maximize task signal
```
