# Skeleton-of-Thought: Prompting LLMs for Efficient Parallel Generation

- **arXiv**: [2307.15337](https://arxiv.org/abs/2307.15337)
- **Published**: 2024-03-02 (ICLR 2024)
- **Authors**: Xuefei Ning, Zinan Lin, Zixuan Zhou, Zifu Wang, Huazhong Yang, Yu Wang
- **Affiliations**: Tsinghua University, Microsoft Research, KU Leuven, Infinigence-AI
- **Website**: https://sites.google.com/view/sot-llm
- **Code**: https://github.com/imagination-research/sot

---

## Abstract

This work aims at decreasing the end-to-end generation latency of large language models (LLMs). One of the major causes of the high generation latency is the sequential decoding approach adopted by almost all state-of-the-art LLMs. In this work, motivated by the thinking and writing process of humans, we propose **Skeleton-of-Thought (SoT)**, which first guides LLMs to generate the _skeleton_ of the answer, and then conducts parallel API calls or batched decoding to complete the contents of each skeleton point _in parallel_. Not only does SoT provide considerable speed-ups across 12 LLMs, but it can also potentially improve the answer quality on several question categories. SoT is an initial attempt at data-centric optimization for inference efficiency, and showcases the potential of eliciting high-quality answers by explicitly planning the answer structure in language.

---

## 1. Introduction

Large language models (LLMs) have shown exceptional performance in natural language processing and chatbot systems. However, the inference process of state-of-the-art LLMs is slow, hindering their interactive use. For example, it takes 22 seconds for Claude and 43 seconds for Vicuna-33B V1.3 (running locally on one NVIDIA A100 GPU) to answer certain questions.

### Three Major Causes of Slow LLM Inference

1. **Large model size**: Requires large amounts of memory, memory access, and computation. For example, FP16 weights of 175B GPT-3 take 350GB memory, requiring at least 5x80GB A100 GPUs.

2. **Attention operation**: I/O bounded with quadratic memory and computation complexity in sequence length.

3. **Sequential decoding**: Generates tokens one by one, preventing parallelization and introducing significant inference latency.

### The Core Insight

Humans do _not_ always think about questions and write answers in a sequential fashion. For many question types, we first derive the _skeleton_ according to some protocols and strategies, and then add evidence and details to explain each point. This is especially the case on occasions like offering consultancy, taking tests, writing papers, etc.

### Skeleton-of-Thought (SoT) Approach

SoT guides the LLM to:

1. Derive a skeleton first by itself
2. Complete each point _in parallel_ to achieve speed-up

SoT can be utilized to accelerate both:

- Open-source models with batched decoding
- API-based models with parallel API calls

### Key Results

- Up to **2.39x speed-up** across 12 LLMs tested
- Can also **improve answer quality** in many cases
- Novel "data-level" pathway for inference efficiency

---

## 2. Skeleton-of-Thought (SoT) Method

### 2.1 Overview

The core idea is to guide the LLM itself to give a skeleton first and then write the overall answer parallelly instead of sequentially.

### 2.2 Two-Stage Process

#### Stage 1: Skeleton Stage

SoT assembles a **skeleton request** using the skeleton prompt template with the question as parameter. The skeleton prompt template is written to guide the LLM to output a concise skeleton of the answer. Then, the B points are extracted from the skeleton response.

**Skeleton Prompt Template (Zero-Shot)**:

```
You're an organizer responsible for only giving the skeleton (not the full
content) for answering the question. Provide the skeleton in a list of points
(numbered 1., 2., 3., etc.) to answer the question. Instead of writing a full
sentence, each skeleton point should be very short with only 3~5 words.
Generally, the skeleton should have 3~10 points. Now, please provide the
skeleton for the following question.

{question}

Skeleton:
1.
```

**Skeleton Prompt Template (Two-Shot, for most models)**:

```
You're an organizer responsible for only giving the skeleton (not the full
content) for answering the question. Provide the skeleton in a list of points
(numbered 1., 2., 3., etc.) to answer the question. Instead of writing a full
sentence, each skeleton point should be very short with only 3~5 words.
Generally, the skeleton should have 3~10 points.

Question:
What are the typical types of Chinese dishes?
Skeleton:
1. Dumplings.
2. Noodles.
3. Dim Sum.
4. Hot Pot.
5. Wonton.
6. Ma Po Tofu.
7. Char Siu.
8. Fried Rice.

Question:
What are some practical tips for individuals to reduce their carbon emissions?
Skeleton:
1. Energy conservation.
2. Efficient transportation.
3. Home energy efficiency.
4. Reduce water consumption.
5. Sustainable diet.
6. Sustainable travel.

Now, please provide the skeleton for the following question.
{question}
Skeleton:
1.
```

#### Stage 2: Point-Expanding Stage

Based on the skeleton, the LLM expands on each point in parallel.

**Point-Expanding Prompt Template**:

```
You're responsible for continuing the writing of one and only one point in
the overall answer to the following question.

{question}

The skeleton of the answer is

{skeleton}

Continue and only continue the writing of point {point index}. Write it
**very shortly** in 1~2 sentence and do not continue with other points!

{point index}. {point skeleton}
```

### 2.3 Parallel Point Expanding

#### For API-Based Models

Issue multiple parallel API calls to get end-to-end latency gain at the cost of increased number of API requests and tokens.

#### For Open-Source Models

Process point-expanding requests as a batch (paddings added to the left of requests).

**Why batched decoding achieves speed-up**:

- A typical LLM generative process consists of:
  1. **Prefilling phase**: Prompt is parsed to generate KV cache
  2. **Decoding phase**: Tokens generated one by one sequentially

- The decoding phase:
  - Accounts for majority of end-to-end latency (especially for long responses)
  - Is bottlenecked by weight loading, not activation loading or computation
  - Running with increased batch sizes does not increase per-token latency much

- Therefore, SoT allows decoding roughly Bx more tokens within the same amount of time if B points are decoded in parallel.

---

## 3. SoT Evaluation

### 3.1 Datasets

- **Vicuna-80**: 80 questions spanning 9 categories (coding, math, writing, roleplay, etc.)
- **WizardLM**: 218 questions spanning more categories and diverse difficulties

### 3.2 Models Tested

**Open-Source Models** (9 models):

- LLaMA2-Chat-7B, LLaMA2-Chat-13B
- Vicuna-7B V1.1, Vicuna-7B V1.3, Vicuna-13B V1.3, Vicuna-33B V1.3
- OpenChat-13B, StableVicuna-13B, UltraLM-13B

**API-Based Models** (3 models):

- Claude, ChatGPT-3.5, GPT-4

### 3.3 Efficiency Results

#### Speed-ups by Model

- SoT obtains **>2x speed-up** on 8 out of 12 models (up to 2.39x)
- Key factors affecting speed-up:
  - Number of points B (ranges from <6 to ~9 across models)
  - Point-expanding response length (API models follow instructions better)
  - Length balance between point responses

#### Speed-ups by Question Category

- SoT can obtain speed-ups for all question categories
- For categories where SoT provides high-quality answers (knowledge, generic, common-sense, roleplay, counterfactual): **1.89x to 2.33x speed-up**

### 3.4 Answer Quality Results

Two LLM-based evaluation frameworks used:

- **FastChat**: One metric for general answer quality
- **LLMZoo**: Five detailed metrics (coherence, diversity, immersion, integrity, relevance)

**Key findings**:

- SoT is not worse than baseline in around **60%** of cases
- Win rates are close to lose rates overall
- SoT answers maintain good quality compared to normal generation

#### Quality by Question Category

**Categories where SoT performs well** (high net win rates):

- Generic
- Common-sense
- Knowledge
- Roleplay
- Counterfactual

**Categories where SoT performs poorly** (low net win rates):

- Writing
- Fermi
- Math
- Coding

**Key insight**: SoT performs well when the question can be answered in several points whose details can be expanded independently. It is fundamentally challenging for questions requiring step-by-step thinking where later steps require details from earlier steps.

#### Quality by Metric

**Metrics where SoT improves answers**:

- **Diversity**: Skeleton stage explicitly requires LLMs to discuss from multiple aspects
- **Relevance**: Points are proposed around the question; LLMs required to discuss only these points

**Metrics where SoT may hurt answers**:

- **Coherence**: List format not suitable for all questions (e.g., emails, passages)
- **Immersion**: Breaking answers into lists makes them less in-character

---

## 4. SoT with Router (SoT-R): Adaptive Triggering

### 4.1 Motivation

SoT is not suitable for questions requiring step-by-step reasoning. To push practical adoption, a **router** module decides if SoT should be applied for the user request.

### 4.2 Prompting Router

Directly ask an LLM (GPT-4) if the question is suitable for SoT:

```
Question: {question}

How would you like to answer the question?
A. Organize the answer as a list of points or perspectives (in the format of
   1., 2., 3., etc.), and the points or perspectives can be answered
   independently without referring to the contents of the previous points.
B. Organize the answer as a list of points or perspectives (in the format of
   1., 2., 3., etc.), and the contents of later points or perspectives cannot
   be answered independently without referring to the contents of the
   previous ones.
C. Do not organize the answer as a list of points or perspectives.

Just say A, B, or C. Do not explain. Do not provide an answer to the question.
```

If answer is "A", use SoT. Otherwise (B or C), use normal decoding.

### 4.3 Trained Router

Fine-tune a small **RoBERTa model** (120M parameters) as a binary classifier:

- Label 1 (positive): Question suitable for SoT
- Label 0 (negative): Normal generation more suitable

**Training details**:

- Training data: LIMA dataset (1,030 Q&As)
- Optimizer: AdamW with weight decay 0.01
- Learning rate: Warm-up to 5e-5, then linear decay
- Epochs: 2, Batch size: 32
- Loss: Tversky loss (alpha=0.7, beta=0.3) + label smoothing (epsilon=0.2)
- Training time: ~2 minutes on NVIDIA A100

### 4.4 SoT-R Evaluation Results

**Efficiency**:

- SoT-R obtains lower speed-ups than SoT (expected, since SoT not triggered for some questions)
- Still provides >1x speed-ups for most models
- Router latency overhead is small (~0.04s for trained router)

**Quality**:

- SoT-R significantly improves answer quality on unsuitable questions (coding, math, writing, fermi) by falling back to normal decoding
- Maintains quality improvements on suitable questions
- Trained router performs similar to or better than prompting router
- Sometimes even surpasses human router decisions

---

## 5. Analysis and Insights

### 5.1 Why SoT Reduces Latency for Local Models

**GPU utilization analysis** (on NVIDIA A100):

- Prefilling phase: ~43 TFLOPS (13.8% utilization)
- Decoding phase: ~0.31 TFLOPS (0.1% utilization)

The huge gap arises because all LLM weights need to be loaded onto GPU chip at least once for decoding each token, making decoding heavily I/O-bound.

**Key observation**: As batch size B increases:

- Latency of decoding one token per sequence stays roughly the same
- GPU utilization increases almost linearly
- For answer of length N split into B segments: roughly Bx decoding speed-up possible

**Memory overhead**: Peak memory overhead grows slowly as batch size increases (<1.11x in all experiments).

### 5.2 Answer Quality Patterns

#### Models with Low SoT Net Win Rates

**Type 1 (Weak models - OpenChat-13B, Vicuna-7B V1.1, LLaMA2-Chat-13B)**:

- Cannot follow SoT prompts precisely
- Skeleton may contain undesired contents
- Sometimes write nothing in point-expanding stage when details needed

**Type 2 (Strong models - Claude)**:

- Their normal answers already have good quality, making it hard for SoT to beat them

#### Models with High SoT Net Win Rates

Models between the two extremes (Vicuna-13B V1.3, StableVicuna-13B, UltraLM-13B):

- Good enough to understand SoT prompts
- Normal generation has larger room for improvement

#### Question Categories Analysis

**Math questions** (low win rate):

- Require step-by-step thinking
- Without knowing previous steps, hard to derive following steps
- Strong models can get skeleton correct but fail at independent point expansion
- Weak models struggle to even get skeleton correct

**Fermi questions** (low win rate):

- Similar to math -- require step-by-step assumptions and calculations
- Later steps may unknowingly contradict earlier assumptions

**Coding questions** (low win rate):

- Solutions usually have strong dependencies between lines
- Without knowing previously defined variables/imports, hard to implement subsequent code
- Interesting: SoT could help larger tasks with multiple modules (functions, classes)

**Writing questions** (low win rate):

- Usually require coherent passage without embedded skeleton points
- Current SoT pipeline concatenates skeleton points as part of answer

**High win rate categories** (counterfactual, knowledge, common-sense, generic, roleplay):

- Ideal answer covers several relatively _independent_ points
- Skeleton before details leads to more comprehensive discussions
- List format makes answers easier to read

### 5.3 Interesting Emergent Behavior

Some models automatically fall back to sequential generation by outputting complete answer in skeleton stage, skipping point-expanding. This happens on both weak and strong models and suggests a promising direction for making SoT a general framework.

---

## 6. Overhead Analysis

### 6.1 Prefilling Token Overhead

SoT significantly increases prefilling tokens (multiple point-expanding requests):

| Model   | Normal | SoT Stage 1 | SoT Stage 2 | Ratio (SoT/Normal) |
| ------- | ------ | ----------- | ----------- | ------------------ |
| Claude  | 10.33  | 155.33      | 730.91      | 85.79              |
| ChatGPT | 10.21  | 136.33      | 480.95      | 60.46              |
| GPT-4   | 10.21  | 72.44       | 838.26      | 89.20              |

For open-source models with a common-prefix prefilling trick, ratio is ~30-39x.

### 6.2 Future Overhead Reduction

Possible approaches:

1. Reuse KV cache from Stage 1 during Stage 2
2. Use shorter prompts as LLM capabilities evolve
3. Prompt compression techniques

---

## 7. Related Work

### 7.1 Efficient LLM Methods

**Model-level optimization**:

- Mixture-of-experts, low-complexity attention, multi-query attention
- Quantization, weight/activation sparsification
- _Require fine-tuning; SoT is data-level, no model changes needed_

**System-level optimization**:

- Computational graph optimization (FlashAttention)
- Assignment/scheduling optimization
- Batching/caching for serving
- _Focus on throughput; SoT trades throughput for latency_

**Decoding optimization**:

- Speculative decoding: Use smaller models for candidate generation, LLM for verification
- Non-autoregressive generation: Parallel sampling with modified models
- _SoT is different: prompts LLM itself to plan content permitting parallel generation_

### 7.2 Prompting Methods

Prior prompting work focuses on answer quality (CoT, ToT, ReAct, etc.).
_SoT is a first attempt at exploiting prompting power for efficiency_.

### 7.3 Hierarchical Text Generation

Prior work uses hierarchical architectures for coherence/relevance.
_SoT exploits emerging planning/instruction-following abilities of LLMs for efficiency with explicit, free-form planning_.

---

## 8. Limitations and Future Work

### 8.1 Answer Quality Evaluation

- Limited prompt set
- Potential bias of GPT-4 judges
- Inherent difficulty of evaluating LLM generations
- No human evaluation (easy to tell SoT vs normal due to distinctive pattern)

### 8.2 Eliciting LLM Abilities

SoT is part of broader trend (CoT, ToT, ReAct) affirming that _explicitly articulating thought process can elicit high-quality answers_.

**Future directions**:

- **Graph-of-Thoughts**: Organize points with dependency edges; decode each point conditioned on ancestor contents
- **Dynamic Graph-of-Thoughts**: High-level thought structure adjusted dynamically by LLMs
- Self-improvement through SoT fine-tuning

### 8.3 Efficiency in Different Scenarios

**Unsaturated concurrent queries**:

- SoT effectively reduces latency and enhances GPU utilization
- Use cases: Edge-side single-user apps, underutilized centralized services

**Saturated concurrent queries**:

- SoT still useful for quality improvement
- Computation overhead from SoT becomes more relevant

**API costs**:

- Increased prefilling tokens may lead to higher costs
- Prompt tuning for shorter SoT prompts could help

### 8.4 Data-Centric Efficiency Optimization

SoT is first attempt at data-centric techniques for inference efficiency. As LLM capabilities and LLM-generated data grow, such techniques could become more important.

**Challenges**:

- Acceleration ratio depends on prompt, model, and question
- Less predictable/controllable than model/system-level techniques

---

## 9. Key Takeaways

1. **Novel paradigm**: SoT introduces "content co-organization for efficiency" -- a data-level approach to LLM efficiency without model/system changes

2. **Significant speed-ups**: Up to 2.39x acceleration across 12 models tested

3. **Quality preservation**: Maintains or even improves answer quality for suitable question types

4. **Selective triggering**: SoT-R with router enables practical deployment by falling back to normal generation when SoT is unsuitable

5. **Human-inspired**: Based on how humans organize thoughts before writing, breaking complex questions into independent points

6. **Synergy with other techniques**: SoT can harness throughput-oriented system optimizations to help with latency

7. **Foundation for future work**: Graph-of-Thoughts, dynamic thought structures, and data-centric efficiency optimization

---

## 10. Prompt Templates Summary

### Skeleton Prompt (Zero-Shot)

```
You're an organizer responsible for only giving the skeleton (not the full
content) for answering the question. Provide the skeleton in a list of points
(numbered 1., 2., 3., etc.) to answer the question. Instead of writing a full
sentence, each skeleton point should be very short with only 3~5 words.
Generally, the skeleton should have 3~10 points.

Now, please provide the skeleton for the following question.
{question}
Skeleton:
1.
```

### Point-Expanding Prompt

```
You're responsible for continuing the writing of one and only one point in
the overall answer to the following question.

{question}

The skeleton of the answer is

{skeleton}

Continue and only continue the writing of point {point index}. Write it
**very shortly** in 1~2 sentence and do not continue with other points!

{point index}. {point skeleton}
```

### Router Prompt

```
Question: {question}

How would you like to answer the question?
A. Organize the answer as a list of points or perspectives (in the format of
   1., 2., 3., etc.), and the points or perspectives can be answered
   independently without referring to the contents of the previous points.
B. Organize the answer as a list of points or perspectives (in the format of
   1., 2., 3., etc.), and the contents of later points or perspectives cannot
   be answered independently without referring to the contents of the
   previous ones.
C. Do not organize the answer as a list of points or perspectives.

Just say A, B, or C. Do not explain. Do not provide an answer to the question.
```

---

## Citation

```bibtex
@inproceedings{ning2024skeleton,
  title={Skeleton-of-Thought: Prompting LLMs for Efficient Parallel Generation},
  author={Ning, Xuefei and Lin, Zinan and Zhou, Zixuan and Wang, Zifu and Yang, Huazhong and Wang, Yu},
  booktitle={ICLR},
  year={2024}
}
```
