# Behavior-Equivalent Token: Single-Token Replacement for Long Prompts in LLMs

- **arXiv ID**: 2511.23271
- **Title**: Behavior-Equivalent Token: Single-Token Replacement for Long Prompts in LLMs
- **Authors**: Jiancheng Dong, Pengyue Jia, Jingyu Peng, Maolin Wang, Yuhao Wang, Lixin Su, Xin Sun, Shuaiqiang Wang, Dawei Yin, Xiangyu Zhao
- **Affiliations**: City University of Hong Kong, Baidu Inc.
- **Year**: 2025

## Abstract

Carefully engineered system prompts play a critical role in guiding the behavior of LLM agents, but their considerable length introduces significant drawbacks, including increased inference latency, higher computational cost, and reduced effective context length. This raises the question of whether such lengthy prompts can be replaced by a drastically reduced number of tokens while preserving their behavioral effect on downstream tasks.

The paper proposes a lightweight three-stage training framework that learns a single prompt-specific Behavior-Equivalent token (`[BE]`). The framework first trains `[BE]` to encode the natural-language content of the original system prompt via reconstruction, and then distills the prompt's downstream behavior into this single token. Importantly, the method requires no access to model internals, no auxiliary compression models, and no labeled responses. Empirical evaluations on three datasets show that a single `[BE]` token achieves up to a 3000x reduction in prompt length, while retaining about 98% of the downstream performance of the original system prompts.

## Key Contributions

1. **Behavior-Equivalent Token**: A single learned token can replace prompts of up to 3,000 tokens while preserving over 98% of the original behavioral effect.

2. **Efficient Training Framework**: A self-contained training framework that distills the `[BE]` token directly from the target LLM using only unlabeled queries, requiring no external models, data annotations, or additional inference passes.

3. **Superior Performance**: Extensive experiments on three benchmarks show the method significantly outperforms existing prompt compression techniques in both compression ratio and downstream performance.

## Method

### Overview

The goal is to compress a long prompt P into a single Behavior-Equivalent token `[BE]`, which occupies only one position in the context window yet elicits responses indistinguishable from those produced by the full prompt. The method introduces two learnable tokens and uses a three-stage training procedure.

### Stage 0: Pre-training [AE] as a Reconstruction Trigger

First, train a universal Auto-Encoder token `[AE]`, which enables the fixed LLM to reconstruct the preceding text. For any given text sequence X = (x_1, ..., x_n), provide the model with input [X, `[AE]`] and train it to reconstruct X autoregressively.

The loss function:

```
L_AE = -sum_{i=1}^{n} log P(x_i | x_{1:n}, [AE], x_{1:i-1})
```

Only the embedding e_AE is optimized; all model parameters remain fixed. This yields a general-purpose trigger that prompts the LLM to reconstruct preceding text.

### Stage 1: Compressing Prompt into [BE]

With the universal trigger e_AE from Stage 0, learn a prompt-specific embedding e_BE for the target prompt P = (s_1, ..., s_m). Train the model to reconstruct P when conditioned on the sequence [`[BE]`, `[AE]`]:

```
L_recon = -sum_{j=1}^{m} log P(s_j | [BE], [AE], s_{<j})
```

The model parameters and e_AE are held fixed; only e_BE is updated. This forces `[BE]` to encode all information necessary to regenerate P.

### Stage 2: Behavior Alignment via Knowledge Distillation

To ensure that replacing P with `[BE]` yields the same conditional output distribution for downstream queries, use knowledge distillation. The same LLM conditioned on the full prompt serves as the **teacher**, and the LLM conditioned on `[BE]` serves as the **student**.

For any unlabeled user query q, the teacher model first generates a response autoregressively: A = (a_1, ..., a_T) ~ M(. | [P, q]). Then minimize the KL divergence between teacher and student distributions:

```
L_KD = (1/T') sum_{t=1}^{T'} KL(softmax(z^T_t/tau) || softmax(z^S_t/tau))
```

where z^T_t and z^S_t are teacher and student logits respectively, and tau is the distillation temperature.

### Combined Objective

The total loss combines reconstruction and knowledge distillation:

```
L_total = (1-lambda) * L_recon + lambda * L_KD
```

where lambda is in [0, 1].

### Inference

At deployment, simply prepend the learned `[BE]` token to any user query q, forming the input [`[BE]`, q]. The `[AE]` token is training-only and not used at inference.

## Experimental Results

### Datasets

- **RoleLLM**: 95 diverse character profiles with lengthy system prompts specifying persona and style
- **GSM8K**: Math word problems, used for training queries in knowledge distillation
- **Harry Potter Dialogue (HPD)**: Supplementary evaluation for role-playing, assessing stylistic preservation

### Models Evaluated

- Llama-3.2-1B-Instruct
- Llama-3.2-3B-Instruct
- Llama-3.1-8B-Instruct
- Qwen3-4B-Instruct-2507

### Main Results

The `[BE]` token achieves approximately 98% of the full-prompt performance on average across tasks and models:

| Model        | RoleLLM (Ours/Full) | GSM8K (Ours/Full) |
| ------------ | ------------------- | ----------------- |
| Llama-3.2-1B | 97.29%              | 99.13%            |
| Llama-3.2-3B | 102.93%             | 100.20%           |
| Llama-3.1-8B | 92.15%              | 99.72%            |
| Qwen3-4B     | 98.38%              | 101.19%           |

### Comparison with Baselines

- **Memory Token**: Fails to properly encode semantic information, leading to poor downstream performance
- **Soft Prompts**: Exhibit inconsistent performance due to sensitivity to random initialization
- **`[BE]` Token**: Achieves near-full-prompt performance with 3000x compression

### Ablation Studies

Key findings from ablation:

1. **Reconstruction without `[AE]` may harm performance**: Memory-token style reconstruction can be detrimental.

2. **KD provides richer learning signal than Prompt Tuning**: Matching the teacher's behavior is a more faithful compression target than optimizing task loss alone.

3. **Combination of AE-assisted reconstruction and KD is most effective**: Using `[AE]` as a reconstruction trigger prevents `[BE]` from collapsing into a brittle memory token.

### Comparison with PCC (State-of-the-Art)

On GSM8K with varying few-shot examples:

| Method                    | Context | Compression Rate | Accuracy |
| ------------------------- | ------- | ---------------- | -------- |
| Reference (8-shot)        | --      | --               | 80.56    |
| PCC (8-shot)              | 4x      | 4x               | 63.76    |
| **`[BE]` token** (8-shot) | ~1500x  | ~1500x           | 79.05    |

### Efficiency Gains

TTFT (Time-to-First-Token) reductions on single A100 GPU:

- **RoleLLM** (337-token prompt): 9-23% reduction across models
- **GSM8K** (1,584-token prompt): 28-59% reduction across models

## Key Design Insights

### Why Reconstruction Alone Fails

Memory tokens that directly trigger verbatim reconstruction tend to function as rote triggers and do not transfer information to downstream tasks. Many distinct memory embeddings can reconstruct the same prompt while residing in disparate regions of embedding space.

### Why Prompt Tuning Alone Fails

Prompt tuning is notoriously unstable and often fails to capture complex instructions embedded in long system prompts. It readily latches onto artifacts, causing malformed outputs or template regurgitation.

### The Role of [AE]

By assigning the universal task of triggering reconstruction to `[AE]`, the method enables `[BE]` to specialize entirely in encoding the target prompt's content. This prevents `[BE]` from collapsing into a brittle memory token.

### The Role of KD

Knowledge distillation anchors the `[BE]` token to the teacher's end-task distributions, ensuring that it encodes the usable control signal of the prompt, not just its surface text.

### Loss Weight Balance

Over-emphasizing reconstruction (lambda -> 0) steers the embedding toward a memory-token-like local optimum. Performance is consistently strong for lambda >= 0.5. A higher lambda correctly prioritizes the KD task, while reconstruction loss serves as a crucial regularizer.

### Self-Generated vs Gold Answers

Distilling from self-generated teacher responses generally outperforms using gold answers because the distribution of the teacher's self-generated outputs is more intrinsically familiar to the LLM's own architecture.

## Limitations

1. **Single-turn only**: Evaluation restricted to single-turn interactions; multi-turn dialogue settings not considered.

2. **Offline benchmarks**: No production-scale A/B tests; systematic online evaluation left to future work.

## Implementation Details

### Pre-training [AE]

- Corpus: ~1GB mixed corpus (Cosmopedia-WikiHow, PwC dataset, GSM8K)
- Training: 2 epochs with AdamW, learning rate 1e-3, batch size 4, 8 gradient accumulation steps
- Configuration held constant across all backbone models

### Training [BE]

- KD weight lambda = 0.9
- Distillation temperature tau = 2
- Precision: bfloat16
- Attention: FlashAttention v2.7.4

## References

Key related works:

- Kuratov et al. (2025): Cramming 1568 Tokens into a Single Vector
- Dai et al. (2025): Pretraining Context Compressor (PCC)
- Lester et al. (2021): Power of Scale for Parameter-Efficient Prompt Tuning
- Ge et al. (2024): In-context Autoencoder for Context Compression
- Kim & Rush (2016): Sequence-Level Knowledge Distillation
