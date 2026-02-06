# Decomposition Techniques

## Overview

Decomposition techniques break complex problems into simpler sub-problems that
models can solve more reliably. Use decomposition when:

- Multi-step reasoning exceeds model capability in a single pass
- Test problems are harder or longer than training exemplars (easy-to-hard
  generalization)
- Problems have natural hierarchical or sequential structure
- Intermediate results need to be verified before proceeding
- Different sub-tasks require specialized handling or external tools

The core tradeoff: decomposition increases API calls and token usage but enables
solving problems that would otherwise fail, provides interpretable reasoning
traces, and allows modular debugging of sub-components.

**Meta-principle:** Prefer deeper decomposition chains when uncertain. Longer
reasoning chains correlate with more robust multi-step reasoning—when selecting
examples or sampling solutions, favor complexity over brevity.

---

## Techniques

### Least-to-Most Prompting

**Mechanism:** Decompose complex problems into simpler subproblems, then
sequentially solve them using previous answers accumulated in context.

**Triggers:**

- Test problems harder than exemplars (easy-to-hard generalization)
- Compositional generalization with systematic combination
- Multi-step problems where subproblems build on prior solutions
- Length generalization beyond training examples

**Tradeoffs:** 2-3x tokens (decomposition + sequential solving). k+1 API calls
(1 decomposition + k subproblems). Requires few-shot examples for both
decomposition and subproblem solving. Domain-specific decomposition prompts do
not generalize well across domains.

---

### Decomposed Prompting (DecomP)

**Mechanism:** Decompose complex tasks into simpler sub-tasks delegated to
specialized prompts in a shared library, with hierarchical or recursive
decomposition possible.

**Triggers:**

- Individual reasoning steps hard to learn in monolithic prompt
- Sub-components need specialized knowledge or capabilities
- Multi-hop reasoning requiring retrieval or external tools
- Need to swap sub-task implementations without changing overall system
- Isolated debugging of sub-components would improve accuracy

**Tradeoffs:** Variable token overhead depending on decomposition depth.
Multiple adaptive calls — 1 decomposer + k sub-task handlers per step. Requires
upfront task decomposition design. Enables modular optimization and tool
integration at cost of increased latency.

---

### ADAPT (As-Needed Decomposition)

**Mechanism:** Recursively decompose tasks only when executor fails, adapting
decomposition depth to task complexity dynamically.

**Triggers:**

- Multi-step tasks with unpredictable sub-task complexity
- Navigation or exploration in unknown environments
- Compositional tasks where some sub-tasks harder than others
- Tasks requiring both high-level planning and low-level execution
- Interactive decision-making with long action trajectories

**Tradeoffs:** Adaptive 2-4x tokens depending on task complexity. 1 to d_max
recursive levels of planner + executor calls. Requires environment interaction
capabilities and self-evaluation in executor. Only decomposes when needed,
avoiding redundant re-execution. Planner and executor can use different LLMs—use
cheaper model for planning, more capable model for execution.

#### DEPS Pattern (Describe-Explain-Plan-Select)

For agent planning scenarios, extend ADAPT with four-stage decomposition:
Describe the current situation → Explain relevant domain knowledge → Plan
candidate actions → Select the best action. This separates situation
understanding from knowledge retrieval from planning from selection, reducing
error propagation across stages.

---

### Tree of Thoughts (ToT)

**Mechanism:** Maintain tree of intermediate thoughts, explore multiple
reasoning paths via search (BFS/DFS) with LM-based evaluation and backtracking.

**Triggers:**

- Task requires exploration or strategic lookahead
- Initial decisions play pivotal role in solution quality
- Problem involves search through combinatorial space
- Multiple valid reasoning paths exist requiring evaluation
- Need backtracking when reasoning hits dead ends

**Tradeoffs:** 5-100x tokens vs CoT depending on search depth/breadth. Adaptive
API calls based on search algorithm — typically 10-100+ calls. Requires few-shot
examples for thought generation plus state evaluation prompts. Not needed for
tasks where LM already excels via simpler methods.

---

### Selection-Inference

**Mechanism:** Alternate between selecting relevant facts from context and
making single-step inferences to build causal reasoning chains. The selection
module is constrained to context facts only—this prevents fabrication by
ensuring all selected premises exist in the provided context.

**Triggers:**

- Multi-step logical reasoning with 2+ inference steps
- Context contains both relevant and irrelevant facts
- Deductive/inductive reasoning requiring step-by-step justification
- Tasks requiring causal, interpretable reasoning traces
- Vanilla LLMs struggle with multi-hop reasoning

**Tradeoffs:** N x 2 steps tokens where N is reasoning depth. 2N API calls
(selection + inference per step). Requires few-shot examples for both selection
and inference modules. Fixed halting depth must be predetermined.

#### Logic-of-Thought (LoT)

For tasks requiring formal logical reasoning, extend Selection-Inference with
logic augmentation: Extract logical propositions from the problem → Extend via
logical rules using symbolic solver (e.g., Python) → Translate expanded logic
back to natural language. The augmented prompt contains deduced logical
information that would otherwise be lost during reasoning. LoT is orthogonal to
CoT/ToT—use as a preprocessing step before applying other decomposition
techniques.

---

### R³ Prompting (Review, Rephrase, Resolve)

**Mechanism:** Three-stage denoising for reasoning under noisy contexts: Review
extracts key sentences from the problem, Rephrase converts extracted information
to a variable-centric form, Resolve performs reasoning on the cleaned
representation.

**Triggers:**

- Input context contains irrelevant or distracting information
- Model accuracy degrades as noise or context length increases
- Multi-step reasoning where distractor filtering is critical
- Problems where relevant facts are buried in verbose descriptions

**Tradeoffs:** 3x tokens (review + rephrase + resolve). 3 API calls sequentially.
Maintains stable accuracy even as noise increases. Requires few-shot examples
demonstrating the three-stage pattern.

---

### Thread of Thought (ThoT)

**Mechanism:** Two-step reasoning for chaotic contexts: first "walk through this
context in manageable parts step by step, summarizing and analyzing as we go,"
then extract the answer from the accumulated summaries.

**Triggers:**

- Input contains chaotic, unstructured, or interleaved information
- Multiple conversation threads or topics mixed together
- Long contexts where relevant information is scattered
- Retrieval-augmented scenarios with multiple retrieved passages

**Tradeoffs:** 2x tokens (context walk-through + answer extraction). 2 API calls.
Segments and summarizes incrementally rather than reasoning over full context at
once. Works well in zero-shot scenarios without domain-specific examples.

---

### Narrative-of-Thought (NoT)

**Mechanism:** For temporal reasoning, transform events into structured form,
generate a temporally grounded narrative, then parse the narrative into a
temporal graph for answer extraction.

**Triggers:**

- Questions requiring temporal ordering of events
- Problems involving time expressions, durations, or sequences
- Contexts with multiple events and temporal relationships
- Tasks where temporal graph structure aids reasoning

**Tradeoffs:** 3x tokens (structure + narrative + parse). 3 API calls. Leverages
LLM's strong narrative generation capabilities to order events coherently.
Specialized technique—use only for temporal reasoning tasks.

---

### Plan-and-Solve Prompting

**Mechanism:** Replace "Let's think step by step" with explicit plan-devising
and plan-execution instructions to reduce missing steps.

**Triggers:**

- Multi-step reasoning with calculation errors
- Complex tasks prone to missing intermediate steps
- Problems requiring explicit variable extraction
- Arithmetic word problems requiring step-by-step planning
- Zero-shot scenarios where manual examples unavailable

**The trigger phrase:** "Let's first understand the problem and devise a plan to
solve the problem. Then, let's carry out the plan and solve the problem step by
step."

**PS+ variant:** Add "extract relevant variables and their corresponding
numerals" and "calculate intermediate results (pay attention to calculation and
commonsense)" for additional precision on arithmetic problems.

**Tradeoffs:** 2x tokens. 2 API calls (reasoning generation + answer
extraction). Zero-shot approach eliminates need for manual few-shot examples.
Does not address semantic misunderstanding errors.

#### Problem Elaboration Prompting (PEP)

Before Plan-and-Solve reasoning, decompose the problem into segments and
elucidate each segment. This prevents hasty reasoning by ensuring all conditions
are processed in correct order. PEP acts as a preprocessing step that improves
subsequent Plan-and-Solve or CoT reasoning. Particularly effective for
ill-formed problems with distracting information.

#### Multi-Stage Prompting (Generate-then-Use)

For tasks requiring intermediate knowledge construction, use two stages: First
prompt generates intermediate artifact (knowledge, plan, elaboration), second
prompt uses artifact plus original context for final generation. Separates
knowledge construction from knowledge application.

---

### PEARL (Plan, Execute, and Revise with Long Documents)

**Mechanism:** Three-stage decomposition for long document reasoning: Action
mining discovers task-specific operations from training questions, Plan
generation creates executable action sequences with variable binding, Plan
execution runs actions over the document.

**Triggers:**

- Long document question answering (narratives, legal, technical docs)
- Tasks requiring multiple operations over document content
- Questions involving entity tracking across document sections
- Problems where action sequences can be learned from examples

**Tradeoffs:** 3x tokens (mine + plan + execute). 3+ API calls depending on plan
length. Variable binding enables composition across steps. Requires upfront
action mining from training data.

---

### Self-Ask

**Mechanism:** Model explicitly generates and answers follow-up sub-questions
before answering the main compositional question.

**Triggers:**

- Multi-hop questions requiring composition of separately-known facts
- Model knows sub-facts but fails to compose them
- Compositional reasoning where intermediate steps need external verification
- Tasks requiring explicit sub-question formulation for tool integration

**Critical insight:** The compositionality gap (model knows facts individually
but fails to compose them) does not shrink with model scale. Decomposition
remains necessary even for larger models—this is not a capability that emerges
with scale.

**Tradeoffs:** 2-3x tokens vs direct prompting, 30% fewer than least-to-most. 1
call for self-ask alone, 1+k calls with search (k=number of follow-ups).
Requires few-shot examples demonstrating self-questioning pattern. May generate
unnecessary decomposition for simple queries.

---

### Successive Prompting

**Mechanism:** Iteratively decompose complex questions into simple QA pairs,
solve each, and repeat until final answer is reached.

**Triggers:**

- Complex multi-step questions requiring latent decisions
- Questions involving multiple arithmetic operations
- Compositional reading comprehension with sequential reasoning
- Problems where intermediate QA pairs can be explicitly articulated

**Tradeoffs:** k iterations where k is decomposition depth (typically 2-10x
tokens). 2k API calls per question (k QD + k QA calls). Requires decomposition
examples and separate QD/QA indices. Fine-tuning the QA module improves answer
quality for complex multi-hop questions by enabling iterative refinement.

---

### Branch-Solve-Merge (BSM)

**Mechanism:** Decompose tasks into parallel sub-tasks via branching, solve each
independently, then merge solutions into final output.

**Triggers:**

- Multi-faceted tasks requiring evaluation against multiple criteria
- Constrained generation with multiple constraints to satisfy
- Evaluation of long-form responses to arbitrary questions
- Problems where parallel sub-task decomposition more natural than sequential
- LLM evaluation tasks exhibiting position bias, length bias, or
  self-enhancement bias—BSM mitigates these by evaluating aspects independently

**Tradeoffs:** 3-7x tokens depending on branching factor. k+2 API calls (1
branch + k solve + 1 merge), where k typically 2-5. Zero-shot prompts for
branch/solve/merge modules. Parallel decomposition enables better performance
than sequential approaches.

---

### Divide-and-Conquer Prompting

**Mechanism:** Divide input into parallel sub-inputs, solve independently, then
merge results without sequential dependency.

**Triggers:**

- Long sequences with repetitive sub-tasks (e.g., large integer arithmetic)
- Deceptive/misleading content requiring independent verification
- Task decomposable into parallel homogeneous sub-tasks without dependencies
- Sub-problems can be computed without knowing other sub-answers
- Long document analysis where segments can be verified independently

**Key question:** Can each sub-answer be computed independently, without
requiring results from other sub-problems? If yes, use Divide-and-Conquer. If
sub-problems have sequential dependencies, use Least-to-Most instead.

**Tradeoffs:** k+2 API calls (decompose + k sub-tasks + merge). Recursive for
multi-level decomposition. Requires three distinct prompts: decomposition,
sub-task tackling, solution merge. Not suitable for sequential tasks with
dependent sub-steps.

---

### Skeleton-of-Thought

**Mechanism:** Generate answer skeleton first, then expand each point in
parallel via batched decoding or parallel API calls.

**Triggers:**

- Question answerable as list of independent points
- Answer covers multiple perspectives expandable separately
- Generic questions about types, tips, categories, or aspects
- Knowledge/commonsense questions with multiple facets
- Latency reduction critical for user experience

**Tradeoffs:** 30-90x prefilling tokens (batched decoding reuses common prefix).
1 + k parallel calls (skeleton + k point expansions). Achieves 2-2.39x speedup.
Fails on step-by-step reasoning where later steps depend on earlier step details
(math, coding).

---

### Cumulative Reasoning

**Mechanism:** Orchestrate Proposer, Verifier, and Reporter roles to build DAG
of verified reasoning steps iteratively.

**Triggers:**

- Multi-step reasoning requiring verified intermediate steps
- Logical inference problems with multiple premises
- Complex mathematical problems with cumulative derivations
- Tasks where error propagation must be prevented
- Problems requiring systematic exploration of validated knowledge

**Tradeoffs:** 2-3x tokens per iteration cycle. n iterations with Proposer +
Verifier + Reporter calls. Requires few-shot examples for role prompts and DAG
state management. More efficient than ToT for verified reasoning (achieves
comparable accuracy with fewer explored states).

---

### LM² (Language Model Society)

**Mechanism:** Coordinate three specialized LLM roles: Decomposer generates
subproblems and relevant concepts, Solver answers each subproblem, Verifier
validates answers before they enter the reasoning context. Verifier feedback
prevents error propagation through subsequent steps.

**Triggers:**

- Complex reasoning where error propagation is the primary failure mode
- Multi-step problems where intermediate answers need validation
- Tasks benefiting from separation of decomposition, solving, and verification
- Problems requiring concept extraction alongside decomposition

**Tradeoffs:** 3x tokens per reasoning cycle. Multiple calls per step
(decompose + solve + verify). Verifier catches errors before they contaminate
subsequent reasoning. Roles can use different models or prompts optimized for
each function.

---

## Decision Guidance

**Start simple:** Use Plan-and-Solve or Self-Ask for zero-shot scenarios where
you lack few-shot examples.

**Sequential dependencies:** Use Least-to-Most or Successive Prompting when
later subproblems depend on earlier solutions.

**Parallel sub-tasks:** Use Branch-Solve-Merge or Divide-and-Conquer when
sub-problems are independent and can be solved simultaneously.

**Uncertain complexity:** Use ADAPT when task difficulty is unpredictable and
you want decomposition only when needed.

**Search required:** Use Tree of Thoughts when exploration, backtracking, or
strategic lookahead is essential.

**Tool integration:** Use Decomposed Prompting when sub-tasks require external
APIs, retrieval, or specialized handling.

**Verification critical:** Use Selection-Inference, Cumulative Reasoning, or LM²
when intermediate steps need explicit validation.

**Noisy contexts:** Use R³ Prompting or Thread of Thought when input contains
distracting or chaotic information.

**Long documents:** Use PEARL when reasoning over lengthy narratives or
technical documents with multiple operations.

**Temporal reasoning:** Use Narrative-of-Thought when questions involve event
ordering or temporal relationships.

---

## Composability Notes

**Layer techniques:** Decomposition composes well with:

- Self-consistency voting on sub-problem solutions
- Verification steps at each decomposition level
- Retrieval augmentation for knowledge-intensive sub-tasks

**Conflicts:**

- Skeleton-of-Thought conflicts with CoT/ToT/Least-to-Most (parallel vs
  sequential reasoning)
- Divide-and-Conquer conflicts with CoT/Least-to-Most (independent vs dependent
  sub-steps)

**Common patterns:**

- Decomposition + Self-Consistency: Apply voting to each sub-problem
- Decomposition + Verification: Check intermediate results before proceeding
- Decomposition + Tool Use: Route sub-tasks to appropriate handlers
- Recursive decomposition: Apply same technique to sub-problems that remain too
  complex

### Complexity-Based Selection

When selecting decomposition examples or sampling multiple solutions, prefer
complexity: longer reasoning chains in prompts elicit more robust multi-step
reasoning. When voting among multiple solution chains, weight votes from more
complex chains higher—complexity correlates with reasoning robustness.

### Human-in-the-Loop Checkpoint Patterns

For agentic systems with human oversight (e.g., Claude Code with human query
capability), structure decomposition with approval gates:

- Place human checkpoints after planning stages, before irreversible execution
- Structure each stage to produce human-reviewable artifacts
- Human edits become additional context for re-generation of subsequent stages
- Checkpoint at points where domain expertise enriches context

This pattern enables meaningful human oversight without blocking every action—
humans review plans and artifacts rather than individual steps.

### Preprocessing Combinations

Several techniques function as preprocessing steps that improve subsequent
decomposition:

- Problem Elaboration Prompting → Plan-and-Solve
- Logic-of-Thought → Selection-Inference or CoT
- R³ Prompting → any downstream technique
- Thread of Thought → any downstream technique

Apply preprocessing when input quality is the bottleneck, then decompose.
