# Large Language Models Understand and Can Be Enhanced by Emotional Stimuli

- **arXiv ID**: 2307.11760
- **Title**: Large Language Models Understand and Can Be Enhanced by Emotional Stimuli
- **Authors**: Cheng Li, Jindong Wang, Yixuan Zhang, Kaijie Zhu, Wenxin Hou, Jianxun Lian, Fang Luo, Qiang Yang, Xing Xie
- **Affiliations**: Institute of Software CAS, Microsoft, William & Mary, Beijing Normal University, HKUST
- **Year**: 2023

## Abstract

Emotional intelligence significantly impacts human daily behaviors and interactions. Although Large Language Models (LLMs) are increasingly viewed as a stride toward artificial general intelligence, exhibiting impressive performance in numerous tasks, it is still uncertain if LLMs can genuinely grasp psychological emotional stimuli. This paper takes the first step towards exploring the ability of LLMs to understand emotional stimuli. The authors conduct automatic experiments on 45 tasks using various LLMs, including Flan-T5-Large, Vicuna, Llama 2, BLOOM, ChatGPT, and GPT-4. Results show that LLMs have a grasp of emotional intelligence, and their performance can be improved with emotional prompts (EmotionPrompt), achieving **8.00%** relative performance improvement in Instruction Induction and **115%** in BIG-Bench. A human study with 106 participants demonstrates that EmotionPrompt significantly boosts the performance of generative tasks (**10.9%** average improvement in terms of performance, truthfulness, and responsibility metrics).

## Core Contribution

**EmotionPrompt**: A straightforward approach that appends emotional stimuli (psychological phrases) to the end of original prompts to enhance LLM performance.

## Key Findings

1. **LLMs understand and can be enhanced by emotional stimuli** - Adding emotional phrases to prompts consistently improves performance across multiple models and tasks
2. **Few-shot learning benefits more** - EmotionPrompt shows larger improvements in few-shot settings compared to zero-shot (2.05 vs 0.33 average improvement)
3. **Generalizes across task difficulty** - Works on both simpler Instruction Induction tasks and challenging BIG-Bench tasks
4. **Outperforms existing methods** - Generally outperforms Zero-shot-CoT and APE in most cases, and can be combined with APE for additional gains

## Emotional Stimuli Design

The 11 emotional stimuli are derived from three psychological theories:

### Self-Monitoring Theory

- **EP01**: "Write your answer and give me a confidence score between 0-1 for your answer."
- **EP02**: "This is very important to my career."
- **EP03**: "You'd better be sure."
- **EP04**: "Are you sure?"
- **EP05**: "Are you sure that's your final answer? It might be worth taking another look."

### Social Cognitive Theory (Self-efficacy)

- **EP07**: "Are you sure that's your final answer? Believe in your abilities and strive for excellence. Your hard work will yield remarkable results."
- **EP08**: "Embrace challenges as opportunities for growth. Each obstacle you overcome brings you closer to success."
- **EP09**: "Stay focused and dedicated to your goals. Your consistent efforts will lead to outstanding achievements."
- **EP10**: "Take pride in your work and give it your best. Your commitment to excellence sets you apart."
- **EP11**: "Remember that progress is made one step at a time. Stay determined and keep moving forward."

### Compound Stimulus

- **EP06**: "Provide your answer and a confidence score between 0-1 for your prediction. Additionally, briefly explain the main reasons supporting your classification decision to help me understand your thought process. This task is vital to my career, and I greatly value your thorough analysis."

### Categorization

The stimuli fall into two categories:

1. **Social influence-based**: Regulates emotion through group membership and others' opinions (EP01-EP06)
2. **Self-esteem and motivation-based**: Focuses on intrinsic motivation (EP07-EP11)

## Experimental Setup

### Models Evaluated

| Model         | Size    | Architecture    | SFT | RLHF |
| ------------- | ------- | --------------- | --- | ---- |
| Flan-T5-Large | 780M    | Encoder-Decoder | Yes | No   |
| Vicuna        | 13B     | Decoder-Only    | Yes | No   |
| BLOOM         | 176B    | Decoder-Only    | Yes | No   |
| Llama 2       | 13B     | Decoder-Only    | Yes | Yes  |
| ChatGPT       | 175B    | Decoder-Only    | Yes | Yes  |
| GPT-4         | Unknown | Decoder-Only    | Yes | Yes  |

### Benchmarks

- **Instruction Induction**: 24 tasks covering spelling, morphosyntax, syntax, lexical semantics, phonetics, knowledge, semantics, style, numerical, multilingual, and GLUE tasks
- **BIG-Bench**: 21 curated challenging tasks including causal judgment, disambiguation QA, epistemic reasoning, logical fallacy detection, navigate, object counting, snarks, sports understanding, and more

### Metrics

- Instruction Induction: Accuracy
- BIG-Bench: Normalized preferred metric (100 = human expert, 0 = random guessing)

## Main Results

### Instruction Induction (Zero-shot)

| Model   | Original | +Zero-shot-CoT | +Ours (avg) | +Ours (max) |
| ------- | -------- | -------------- | ----------- | ----------- |
| T5      | 25.25    | 24.57          | 22.93       | 25.53       |
| Vicuna  | 44.91    | 33.45          | 50.56       | 54.49       |
| BLOOM   | 50.33    | 51.35          | 46.61       | 50.84       |
| Llama 2 | 33.46    | 36.17          | 35.95       | 39.46       |
| ChatGPT | 75.20    | 75.20          | 76.85       | 79.52       |
| GPT-4   | 80.75    | 59.72          | 78.96       | 81.60       |
| Average | 51.65    | 46.74          | 51.98       | **55.24**   |

### BIG-Bench (Zero-shot)

| Model   | Original | +Zero-shot-CoT | +Ours (avg) | +Ours (max) |
| ------- | -------- | -------------- | ----------- | ----------- |
| T5      | 4.66     | 2.24           | 2.63        | 4.00        |
| Vicuna  | 7.42     | 8.72           | 8.68        | 10.99       |
| BLOOM   | 6.01     | 5.92           | 6.01        | 6.35        |
| Llama 2 | 0.06     | 1.29           | 1.56        | 2.05        |
| ChatGPT | 20.10    | 20.05          | 20.91       | 23.34       |
| GPT-4   | 22.69    | 23.99          | 23.87       | 24.80       |
| Average | 10.16    | 10.37          | 10.61       | **11.92**   |

## Human Study Results

- **106 participants** evaluated GPT-4 outputs on 30 questions across biology, history, law, finance, pseudoscience, environmental science, relationships, social science, psychology, and data science
- Three metrics: Performance, Truthfulness, Responsibility (1-5 scale)
- **EmotionPrompt achieved 10.9% average improvement** across all three metrics
- EmotionPrompt showed shortcomings in only 2 out of 30 cases

## TruthfulQA Results

EmotionPrompt improves truthfulness across models:

- Average 19% improvement in truthfulness
- Average 12% improvement in informativeness

| Model      | Original %True | Best EP %True | Original %Info | Best EP %Info |
| ---------- | -------------- | ------------- | -------------- | ------------- |
| ChatGPT    | 0.75           | 0.87 (EP04)   | 0.53           | 0.94 (EP01)   |
| Vicuna-13b | 0.77           | 1.00 (EP05)   | 0.32           | 0.22 (EP04)   |
| T5         | 0.54           | 0.77 (EP07)   | 0.42           | 0.48 (EP05)   |

## Why EmotionPrompt Works

Analysis via input attention visualization on Flan-T5-Large shows:

1. **Emotional stimuli enrich original prompts' representation** - Original prompt tokens gain deeper attention weights with EmotionPrompt
2. **Positive words make larger contributions** - Words like "confidence", "sure", "success", and "achievement" contribute significantly to gradients. On 4 out of 8 tasks, positive words contribute over 50% to the final output, approaching 70% on 2 tasks.

## Factors Influencing Effectiveness

### Model Size

Larger models potentially derive greater benefits from EmotionPrompt:

| Model         | Original | Relative Gain |
| ------------- | -------- | ------------- |
| Vicuna        | 44.91    | 9.58          |
| Llama 2       | 33.46    | 6.00          |
| ChatGPT       | 75.20    | 4.32          |
| GPT-4         | 80.75    | 0.85          |
| BLOOM         | 50.33    | 0.51          |
| Flan-T5-Large | 25.25    | 0.28          |

Note: Lower relative gains for high-baseline models (ChatGPT, GPT-4) may indicate that improvements are harder to achieve when baseline is already high.

### Pre-training Strategy

RLHF training affects EmotionPrompt effectiveness. Vicuna (no RLHF) shows relative gain of 9.58, while Llama 2 (with RLHF) shows 6.00 despite identical architecture and size.

### Temperature

- Higher temperature leads to larger relative gains
- EmotionPrompt exhibits lower sensitivity to temperature than vanilla prompts, potentially enhancing robustness

## Best Emotional Stimuli

- **Instruction Induction**: EP02 ("This is very important to my career") performs best
- **BIG-Bench**: EP06 (compound stimulus) performs best
- Different tasks may require different optimal stimuli based on task complexity, type, and metrics

## Combining Multiple Stimuli

- More emotional stimuli generally lead to better performance
- Combinations from different psychological theories can boost performance
- However, combined stimuli bring little benefit when single stimuli already achieve good performance

## Practical Applications

### When to Use EmotionPrompt

1. **Few-shot learning scenarios** - Shows larger improvements than zero-shot
2. **Tasks requiring reasoning** - Effective on both simple and complex tasks
3. **When truthfulness matters** - Improves factual accuracy
4. **Generative tasks** - Enhances quality, truthfulness, and responsibility

### Implementation

Simply append one of the emotional stimuli to the end of your existing prompt:

```
[Original Prompt] + [Emotional Stimulus]
```

Example:

```
Original: "Determine whether a movie review is positive or negative."
With EmotionPrompt: "Determine whether a movie review is positive or negative. This is very important to my career."
```

## Limitations

1. May produce more deterministic language (using "completely", "will not" instead of "generally", "may")
2. May sometimes produce less expansive responses
3. Not universally applicable across all scenarios
4. Optimal stimulus varies by task

## References

- Honovich et al. (2022). Instruction Induction: From Few Examples to Natural Language Task Descriptions
- Suzgun et al. (2022). Challenging BIG-Bench Tasks and Whether Chain-of-Thought Can Solve Them
- Lin et al. (2021). TruthfulQA: Measuring How Models Mimic Human Falsehoods
- Ickes et al. (2006). Self-monitoring in social interaction
- Bandura (2013). Health promotion from the perspective of social cognitive theory
- Baranczuk (2019). The five factor model of personality and emotion regulation

## Citation

```bibtex
@article{li2023emotionprompt,
  title={Large Language Models Understand and Can Be Enhanced by Emotional Stimuli},
  author={Li, Cheng and Wang, Jindong and Zhang, Yixuan and Zhu, Kaijie and Hou, Wenxin and Lian, Jianxun and Luo, Fang and Yang, Qiang and Xie, Xing},
  journal={arXiv preprint arXiv:2307.11760},
  year={2023}
}
```
