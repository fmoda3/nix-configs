# Getting MoRE out of Mixture of Language Model Reasoning Experts

- **arXiv**: [2305.14628](https://arxiv.org/abs/2305.14628)
- **Authors**: Chenglei Si, Weijia Shi, Chen Zhao, Luke Zettlemoyer, Jordan Boyd-Graber
- **Affiliations**: University of Maryland, University of Washington, NYU Shanghai, Stanford University
- **Venue**: EMNLP 2023
- **Code**: https://github.com/NoviScl/MoRE

## Abstract

While recent large language models (LLMs) improve on various question answering (QA) datasets, it remains difficult for a single model to generalize across question types that require distinct reasoning abilities. We provide empirical evidence that state-of-the-art LLMs suffer from poor generalizability on reasoning types beyond those seen in the prompt. To remedy this, we propose a Mixture-of-Reasoning-Experts (MoRE) framework that ensembles diverse specialized language models. We specialize the backbone language model with prompts optimized for different reasoning categories, including factual, multihop, mathematical, and commonsense reasoning. Our key insight is to leverage agreement among the specialized experts to select the best answer for each question, or to abstain from answering. This gives MoRE higher accuracy than any single specialized model on a collection of 12 QA datasets from four reasoning types. Beyond generalizability, the interpretable design of MoRE improves selective question answering results compared to baselines without incorporating inter-expert agreement. This framework is also more interpretable and useful to human consumers of QA outputs. Our human study confirms that presenting expert predictions and the answer selection process helps annotators more accurately calibrate when to trust the system's output.

## Problem Statement

The paper addresses two key challenges in question answering systems:

1. **Generalizability**: A QA system should handle any type of question with different reasoning challenges
2. **Selective Prediction**: The system should abstain from answering when its final answer is likely to be wrong

Current LLMs specialized with prompting techniques excel at their targeted reasoning types but suffer performance degradation on other reasoning types. For example, a math expert with Chain-of-Thought prompting performs well on math questions but poorly on factual QA.

## Mixture-of-Reasoning-Experts (MoRE) Framework

### Specialized Reasoning Experts

MoRE creates four specialized expert models via different prompting strategies on the Codex backbone:

1. **Factual Expert** - Retrieval-augmented prompting
   - Retrieves top 10 relevant passages from Wikipedia using Contriever
   - Appends retrieved passages to the prompt before the question

2. **Multihop Expert** - Chain-of-Thought (CoT) prompting
   - Manually-written rationales after each demo question
   - Elicits multi-step reasoning process

3. **Math Expert** - CoT prompting
   - Uses explanations from GSM8K after each demo question
   - Elicits mathematical reasoning steps

4. **Commonsense Expert** - Generated knowledge prompting
   - Generates 10 fact pieces related to each question using Codex
   - Appends generated knowledge to the prompt

### Ensembling via Answer Selection

A random forest classifier scores each candidate answer based on:

**Feature Categories**:

- **Expert Type**: One-hot four-dimensional vector
- **Question Characteristics**: Question word, length, number of numerical values
- **Answer Characteristics**:
  - Probability of generated output (normalized by length)
  - Answer length
  - Overlap between question and predicted answer
  - Number of numerical values in answer
  - Overlap between answer and retrieved/generated passages
  - Length of CoT rationales
  - Overlap between questions/answers and rationales
- **Inter-Expert Agreement** (novel contribution):
  - Frequency of predicted answer among all four experts
  - Token overlap among experts' outputs

**Training**:

- 100 examples per QA dataset (1200 total)
- Binary classification: predict whether expert prediction is correct
- Inference: select answer with highest score; abstain if score below threshold

### Few-Shot Alternative

For data-limited scenarios, directly prompt Codex with 14 demo examples showing:

- Question
- Predictions from four experts
- Best answer among them

## Experimental Setup

### Datasets (12 total across 4 reasoning types)

**Factual Reasoning**:

- Natural Questions (NQ)
- TriviaQA
- SQuAD

**Multihop Reasoning**:

- HotpotQA
- BeerQA (3+ hops subset)
- MuSiQue

**Mathematical Reasoning**:

- GSM8K
- SVAMP
- MultiArith

**Commonsense Reasoning**:

- CommonsenseQA (CSQA)
- CSQA2.0
- QASC

400 questions randomly sampled from each test set. Metric: Exact Match (EM).

## Key Results

### Specialization Causes Loss of Generalizability

| Expert Type | In-Domain Performance               | Out-of-Domain            |
| ----------- | ----------------------------------- | ------------------------ |
| Factual     | Excels on NQ, TriviaQA, SQuAD       | Poor on math/commonsense |
| Math        | 61.8% on GSM8K, 92.2% on MultiArith | Poor on factual QA       |
| Multihop    | Best on BeerQA3+, MuSiQue           | Variable elsewhere       |
| Commonsense | Best on CSQA, CSQA2.0, QASC         | Moderate elsewhere       |

### MoRE Improves Generalizability

| Method                           | Macro-Average Accuracy |
| -------------------------------- | ---------------------- |
| Best Single Expert (Commonsense) | 49.6                   |
| Majority Vote                    | 43.6                   |
| MaxProb                          | 49.7                   |
| MoRE - Codex Router              | 51.4                   |
| **MoRE - RF Router**             | **57.6**               |
| Oracle Ensemble (upper bound)    | 69.9                   |

MoRE with random forest selector beats the best single expert by 8 points in macro-average accuracy.

### Question-Only Routing

When routing based only on question features (no expert predictions):

- MoRE Question-Only: 50.2 macro-average
- Still beats single-expert baselines but lags behind full MoRE (57.6)
- Useful when compute budget limits running all four experts

## Selective Question Answering

### Automatic Abstention

MoRE's inter-expert agreement features significantly improve calibration for selective QA:

| Method              | AUC (lower better) | Cov@80%  | Cov@90%  | ER       |
| ------------------- | ------------------ | -------- | -------- | -------- |
| MaxProb             | 34.8               | 32.4     | 12.4     | 17.5     |
| RF w/o Agreement    | 36.0               | 26.6     | 12.8     | 22.9     |
| **MoRE Calibrator** | **28.3**           | **45.9** | **34.3** | **33.4** |

Key finding: The RF calibrator without inter-expert agreement features performs worse than MaxProb on AUC, highlighting that agreement features are the critical component.

### Human Abstention Study

20 annotators from Prolific, each annotating 20 questions:

| Condition | Decision Acc | ER       | Accept Correct | Reject Wrong | Time/20Qs    |
| --------- | ------------ | -------- | -------------- | ------------ | ------------ |
| Baseline  | 57.0%        | 9.5      | 75.0%          | 36.8%        | 15.0 min     |
| **MoRE**  | **67.5%**    | **19.5** | **89.4%**      | **43.8%**    | **13.2 min** |

Key findings:

- Showing expert predictions and scores improves human accuracy by 10.5%
- MoRE condition is actually faster (less cognitive load)
- Humans rely on both expert-question type matching and inter-expert agreement
- Human ER (19.5) exceeds automatic calibrator ER (11.3) in MoRE condition

## Key Insights for Prompt Engineering

### 1. Specialization vs Generalization Trade-off

Specialized prompting dramatically improves targeted reasoning but harms other reasoning types. This suggests:

- Use specialized prompts only when question type is known
- For unknown question types, consider ensemble approaches

### 2. Inter-Expert Agreement as a Correctness Signal

Agreement among multiple experts with different specializations provides strong signal for:

- Answer selection (choosing which expert to trust)
- Confidence calibration (knowing when to abstain)
- Human trust calibration (helping users assess reliability)

### 3. Feature-Based Routing Outperforms LLM-Based Routing

Random forest classifier (57.6) significantly outperforms Codex-based answer selection (51.4), suggesting:

- Explicit features capture routing decisions better than prompting
- Hand-designed features leveraging domain knowledge remain valuable

### 4. Agreement Features Critical for Calibration

Without inter-expert agreement features, the RF calibrator performs worse than simple MaxProb baseline:

- Agreement is more informative than individual confidence scores
- Multiple perspectives catch errors that single-model confidence misses

### 5. Interpretability Enables Human-AI Collaboration

Showing the MoRE decision process to humans:

- Improves their ability to spot errors
- Decreases time needed for verification
- Enables humans to apply background knowledge the system lacks

## Limitations

1. **Model Coverage**: Only tested on Codex; needs verification on other LLMs
2. **Reasoning Type Coverage**: Four types may not cover all real-world question types
3. **Beyond QA**: Framework is specific to QA; extending to general language generation remains future work

## Relation to Sampling Methods

MoRE can be viewed as a structured form of sampling where:

- Each expert represents a different "reasoning mode"
- The ensemble aggregates diverse reasoning perspectives
- Agreement among experts indicates higher confidence

This differs from temperature-based sampling or self-consistency in that:

- Diversity comes from different prompting strategies, not random sampling
- Each sample has semantic meaning (reasoning specialization)
- Disagreement is informative about question difficulty and ambiguity

## References

Key related works:

- Self-Consistency (Wang et al., 2022): Sample multiple answers via high temperature, select by majority vote
- Selective QA (Kamath et al., 2020): Train calibrators for abstention decisions
- Generated Knowledge Prompting (Liu et al., 2021): Generate relevant facts before answering
- Chain-of-Thought (Wei et al., 2022): Elicit step-by-step reasoning
