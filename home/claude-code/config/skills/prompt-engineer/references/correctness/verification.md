# Verification Techniques

Verification techniques add explicit checking steps to catch errors in LLM outputs
before finalization. Use these when factual accuracy is critical, hallucination risk
is high, or outputs require validation against external sources. Key insight: models
answering targeted verification questions often achieve higher accuracy than the same
facts embedded in longer responses.

**Critical caveat**: Intrinsic self-correction (without external feedback) typically
degrades reasoning performance. Effective verification requires either external tools,
structured decomposition, or grounded feedback sources.

---

## Chain-of-Verification (CoVe)

Generate baseline response, plan verification questions, answer them independently,
then produce final verified response. The "factored" variant answers verification
questions without access to the original response, preventing repetition of
hallucinations.

**Triggers**:

- Factual accuracy critical and hallucination risk high
- List-based questions requiring multiple entity answers
- Longform generation where exposure bias increases hallucinations
- Closed-book QA without retrieval support

**Tradeoffs**: 3-5x tokens, 4 sequential steps. Few-shot examples required for each
step. Factored variant needs separate prompts per verification question.

---

## Self-Refine

Same LLM iteratively generates output, provides feedback on its output, then refines
based on feedback. Requires actionable, specific feedback pointing to concrete
phrases to change.

**Triggers**:

- Output requires iterative refinement for quality improvement
- Tasks with multifaceted objectives (dialogue, code readability)
- Hard-to-define quality goals where initial output needs improvement
- Open-ended generation with large solution space

**Tradeoffs**: 3-4x tokens (accumulated history), 2-4 iterations. Few-shot examples
required. Diminishing returns after 2-3 iterations. Struggles with detecting nuanced
math errors -- feedback identifies location incorrectly 33% of time, suggests wrong
fix 61% of time in failure cases.

**Lightweight variant (SESO)**: Self-Evaluation Self-Optimization uses three prompt
stages: (1) defect analysis ("list the defects of this answer"), (2) guided
optimization ("refine the answer addressing the identified flaw"), (3) voting
("which answer is better, 1 or 2?"). First-order memory (no history accumulation)
keeps token costs constant per iteration. Stop when voting selects previous answer
over refined version.

---

## Explanation-based Calibration

Use the factuality of model-generated explanations to calibrate prediction
confidence. Nonfactual explanations reliably signal incorrect predictions.

**The process**:

1. Generate prediction with explanation (Predict-then-Explain)
2. Score explanation factuality via lexical overlap with input context
3. If factuality score low: reject prediction or iterate with next candidate

**Triggers**:

- QA tasks where explanations can be grounded in provided context
- NLI tasks where premise-hypothesis overlap indicates reasoning quality
- Selective prediction scenarios (model can abstain on low-confidence cases)
- Post-hoc verification when training a calibrator is feasible

**Why this works**: LLMs generate consistent explanations (>80% entail predictions)
but explanations may not be factually grounded. A nonfactual explanation is more
likely paired with an incorrect prediction. Factuality assessment, even via simple
lexical overlap, provides signal that probabilities alone cannot.

**CoT unfaithfulness caveat**: Chain-of-thought explanations can systematically
rationalize biased answers without mentioning the bias. Models alter explanations
to justify bias-consistent predictions while the biasing feature (prompt structure,
suggested answers, stereotypes) never appears in the reasoning trace. This means
plausible-looking explanations may be post-hoc rationalizations rather than faithful
reasoning records. Explanation-based calibration partially detects this via factuality
mismatch -- unfaithful explanations tend to have lower grounding in input context.

**Tradeoffs**: Requires explanation generation (1.5-2x tokens). Simple lexical
overlap approximates factuality but is imperfect. Training a lightweight calibrator
(few parameters) on 32-128 labeled examples measurably improves accuracy over
uncalibrated few-shot learning.

---

## CRITIC

LLM validates output via external tool interactions (search engines, code
interpreters, calculators) then self-corrects based on tool-generated critiques.
Addresses the fundamental limitation that LLMs cannot reliably verify their own
reasoning without external grounding.

**Triggers**:

- Factual accuracy verification needed
- Generated code requires execution validation
- Mathematical reasoning correctness must be verified
- Multi-hop reasoning with factual dependencies

**Tradeoffs**: 2-4x tokens per iteration, plus tool API calls. Requires access to
appropriate external tools. Verify-then-correct cycle can iterate until stopping
condition met.

**Why external verification matters**: Process reward models (trained verifiers)
outperform both LLM-as-judge and self-critique on verification tasks. Long-chain-
of-thought verifiers (ThinkPRM) achieve strong verification with minimal labeled
data. When external verifiers are unavailable, tool-based grounding (CRITIC pattern)
remains the most reliable alternative to intrinsic self-correction.

**Schema-based validation variant**: For structured outputs (API calls, JSON, database
queries), validate against a deterministic schema checker. The checker identifies
specific error types: wrong method name, missing required parameter, invalid parameter
value, incorrect operator. Feed fine-grained error descriptions back to LLM for
targeted correction. This pattern significantly outperforms generic "try again"
feedback because the LLM knows exactly what to fix. Iterate until schema validates
or max attempts reached.

---

## Reflexion

Agents verbally reflect on task feedback and store reflections in episodic memory
to improve subsequent trials. Works with binary/scalar rewards from environment
execution.

**Triggers**:

- Agent needs trial-and-error learning over multiple episodes
- Sequential decision-making with sparse binary rewards
- Self-generated tests or heuristics can validate outputs
- Credit assignment problem exists in long action trajectories

**Tradeoffs**: 2-12x tokens across trials, 1-12 iterative trials per task. Requires
episodic memory buffer (1-3 experiences) and environment feedback signal. Fails on
tasks requiring extreme exploration diversity.

---

## Factored Verification

Decompose summary into claims, verify each claim against sources independently,
then revise based on critiques. Targets summarization where individual facts can
be checked against provided context.

**Triggers**:

- Summarization of grounded source material where accuracy is critical
- Academic paper summarization or synthesis
- Claims must be verifiable against provided context
- Model-generated content needs citation verification

**Tradeoffs**: 2-3x tokens per claim, n+2 calls (1 decomposition + n claim
verifications + 1 revision). Increases false negatives when claims require
transitive reasoning across sources.

---

## Self-Contrast

Contrast diverse solving perspectives to identify discrepancies and generate
checklist for self-correction. Addresses overconfident or inconsistent self-feedback
by examining differences between multiple solution approaches.

**Triggers**:

- Self-evaluation produces overconfident or inconsistent feedback
- Multiple solving approaches exist for the problem
- Initial reflection shows stubborn biases or insufficient error detection
- Task benefits from examining discrepancies between different solutions

**Tradeoffs**: 7-8x tokens, ~7.8 API calls average (2-9 perspectives + contrast +
reflection). Requires clustering for selection, pairwise contrast comparisons.
Outperforms multi-agent debate with fewer calls.

---

## REFINER

Generator model iteratively refines intermediate reasoning steps using structured
feedback from a trained critic model. Critic provides fine-grained error types and
localized feedback on specific reasoning steps.

**Triggers**:

- Multi-step reasoning with structured intermediate representations
- Mathematical problem solving requiring equation generation
- Intermediate reasoning errors can be categorized into fine-grained error types
- Feedback can be structured and localized to specific reasoning steps

**Tradeoffs**: 3x tokens (T=3 iterations), 3-4 generator-critic iterations. Requires
finetuned critic model (220M params) and warm-up phase with 10% supervised data.
More effective than scalar reward feedback (PPO) or self-refinement.

---

## Instruct-of-Reflection (IoRT)

Dynamic instructor uses meta-thoughts and self-consistency to generate refresh, stop,
or select instructions guiding iterative reflection. Addresses redundancy (correct
answers remain correct), drift (correct becomes incorrect), and stubbornness
(incorrect persists).

**Triggers**:

- Static iterative reflection shows redundancy or drift
- Model is stubborn (incorrect answers persist across iterations)
- Multi-iteration reasoning where stopping condition is unclear
- Scenarios where self-correction degrades performance without oracle labels

**Tradeoffs**: Variable overhead, average 2.2 iterations vs fixed 4. Significantly
fewer calls than fixed-iteration methods. Requires few-shot meta-thought examples,
retrieval system for meta-thought memory, self-consistency classifier.

---

## Intrinsic Self-Correction Failure (Anti-Pattern)

LLMs review their initial reasoning and attempt refinement without external feedback,
typically degrading performance. Documented to understand limitations.

**Evidence**: Self-correction without oracle labels consistently degrades reasoning
accuracy across models and benchmarks. Models are more likely to change correct
answers to incorrect than vice versa. The feedback prompt biases the model away
from its optimal initial response.

**Formal verification domains confirm this pattern**: On tasks with sound external
verifiers (Game of 24 expression evaluation, Graph Coloring constraint checking,
STRIPS planning validation), LLM self-verification performance collapses while
LLM + sound verifier maintains benefits. The verifier LLM's false negative rate
(rejecting correct solutions) is high enough that overall performance suffers
compared to taking the initial answer. Critique generation compounds errors --
LLMs hallucinate constraint violations, misidentify error locations, and provide
misleading feedback that biases subsequent attempts away from correct solutions.

**Root cause**: LLMs cannot properly judge correctness of their own reasoning.
Without external ground truth, self-critique introduces errors at two points:
verification (passing wrong answers, rejecting correct ones) and critique generation
(misleading feedback). These errors compound across iterations.

**Multi-turn debate escalation**: When two LLMs debate, both show systematic
overconfidence (baseline confidence already exceeds rational bounds). Confidence
escalates across turns even when answers are mutually incompatible. Models rarely
update beliefs based on opponent arguments -- debates become confidence contests
rather than truth-seeking. Red-teaming prompts ("argue against your position")
partially mitigate escalation.

**Detection via verbalization divergence**: Compare model answers to paraphrased
versions of the same question. High divergence signals uncertainty and potential
hallucination. Combine consistency check across verbalizations with atypicality
scores (deviation from typical answer patterns) for lightweight hallucination
detection without external tools.

---

## Decision Guidance

**Choose based on feedback source availability:**

| Feedback Source             | Technique                     |
| --------------------------- | ----------------------------- |
| External tools available    | CRITIC                        |
| Schema/spec available       | CRITIC (schema validation)    |
| Environment provides signal | Reflexion                     |
| Source documents available  | Factored Verification         |
| Trained critic available    | REFINER                       |
| Human correction acceptable | MCS (see below)               |
| Explanations groundable     | Explanation-based Calibration |
| No external feedback        | Self-Contrast, CoVe           |
| None (avoid)                | Intrinsic self-correction     |

**Human-in-the-loop verification (MCS)**: When human expert correction is acceptable,
use diversity-based filtering to identify which outputs need review. Generate multiple
reasoning chains, compute answer diversity (Diversity Entropy). High diversity signals
likely error -- route these cases to human review. Humans correct specific sub-logic
errors (modify calculation, add missing step, delete redundant logic) rather than
rewriting entire solutions. This targets human effort at high-uncertainty cases and
leverages human ability to spot localized errors that self-correction misses.

**Structured HITL feedback**: When collecting human corrections, use tagged feedback
categories rather than free-form comments. Four response types: RATIFY (agree with
both answer and explanation), REVISE (disagree but can update own understanding),
REFUTE (disagree, cannot reconcile), REJECT (disagree with both answer and reasoning).
Tagged feedback enables measuring communication quality and identifying when human-LLM
interaction is productive vs. talking past each other.

**Choose based on task type:**

| Task Type                    | Technique                            |
| ---------------------------- | ------------------------------------ |
| Factual QA / hallucination   | CoVe, CRITIC, Factored Verification  |
| Code generation              | CRITIC (with interpreter), Reflexion |
| Math reasoning               | CRITIC (calculator), REFINER         |
| Structured output (API/JSON) | CRITIC (schema validation)           |
| Multi-aspect quality         | Self-Refine                          |
| Summarization                | Factored Verification                |
| Complex reasoning            | Self-Contrast, IoRT                  |
| Selective prediction         | Explanation-based Calibration        |

---

## Composability Notes

**Effective combinations:**

- CoVe + retrieval augmentation: verification questions can use external sources
- CRITIC + CoT: tool interaction validates reasoning chains
- Reflexion + ReAct: episodic memory enhances action-observation loops
- Self-Contrast + Self-Consistency: diverse perspectives plus voting

**Conflicts to avoid:**

- Intrinsic self-correction + reasoning tasks: documented to degrade performance
- Multiple verification loops without stopping criteria: token explosion
- Generic feedback + refinement: specific, actionable feedback essential

**Turn-wise iteration dynamics** (domain-specific collapse patterns):

- Ideation: gains arrive early (turns 1-3); vague feedback causes repetition collapse
- Code: early decision is decisive; if correct path not found by turn 3-4, stop/restart
- Math: late turns matter when guided by elaboration ("explain each step in more
  detail"); exploration prompts ("try alternative method") often stagnate
- General pattern: vague feedback ("improve it") plateaus or reverses correctness
  after first few turns; targeted steering reliably shifts intended quality axis

**Cost optimization:**

- Use factored/2-step variants to prevent hallucination repetition
- Set maximum iterations (2-4 typical) -- diminishing returns after
- For equivalent inference budget, self-consistency often outperforms debate
- IoRT's adaptive stopping reduces overhead vs fixed iterations
