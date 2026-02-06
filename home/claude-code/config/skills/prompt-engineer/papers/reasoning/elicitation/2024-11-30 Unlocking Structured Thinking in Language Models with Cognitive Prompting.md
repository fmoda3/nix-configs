# Abstract

We propose cognitive prompting as a novel approach to guide problem-solving in large language models (LLMs) through structured, human-like cognitive operations, such as goal clarification, decomposition, filtering, abstraction, and pattern recognition. By employing systematic, step-by-step reasoning, cognitive prompting enables LLMs to tackle complex, multi-step tasks more efficiently. We introduce three variants: a deterministic sequence of cognitive operations, a self-adaptive variant in which the LLM dynamically selects the sequence of cognitive operations, and a hybrid variant that uses generated correct solutions as few-shot chain-of-thought prompts. Experiments with LLaMA, Gemma 2, and Qwen models in each two sizes on the arithmetic reasoning benchmark GSM8K demonstrate that cognitive prompting significantly improves performance compared to standard question answering.

# Introduction

Recent advancements in AI, particularly in LLMs, have significantly improved tasks such as text summarization, code generation, and question answering. However, LLMs still face challenges with multi-step reasoning compared to human cognition.

This paper introduces cognitive prompting (CP), a method designed to enhance LLM problem-solving by emulating human cognitive operations (COPs) through structured steps such as goal clarification, decomposition, and pattern recognition (see Figure 1). Inspired by cognitive psychology, CP aims to bridge the gap between human reasoning and AI, improving performance in domains such as mathematics, logic, and decision-making. Our experiments with LLaMA, Gemma 2, and Qwen models, each in two different sizes, on the GSM8K dataset [gsm8k], demonstrate significant performance gains, particularly with the hybrid of self-adaptive and few-shot chain-of-thought (CoT) variant.

The structure of the paper is as follows: Section 2 reviews related work; Section 3 introduces the concept of CP; Section 4 describes three CP variants; Section 5 presents experimental results on the impact of CP on arithmetic reasoning tasks; and Section 6 concludes the paper.

# Related Work

Zero-shot prompting generates responses without providing specific examples, while few-shot prompting [brown2020language] improves performance by including task-specific examples. CoT prompting [wei2022chain] further enhances reasoning by breaking complex problems into sequential steps, enabling the model to process each stage independently. Tree of Thoughts (ToT) prompting [tree] expands this approach by exploring multiple reasoning paths simultaneously, making it well-suited for intricate decision-making scenarios. ReAct [yao2022react] integrates logical reasoning with real-time decision-making, offering enhanced adaptability in dynamic and interactive environments. Prompt Breeder [promptbreeder2022] employs evolutionary computation to iteratively optimize prompts for improved results. Automated Prompt Engineering (APE) [ape] and Optimization by PROmpting (OPRO) [opro] take prompting refinement further by automating the design process. These methods often outperform manually crafted prompts by leveraging optimization algorithms to fine-tune instructions for optimal model performance.

# Cognitive Prompting

CP structures problem-solving into a sequence of COPs, enabling LLMs to address complex tasks across domains like mathematics, logic, and decision-making. Drawing from cognitive psychology, CP breaks problems into stages that mimic human task refinement, enhancing clarity, interpretability, and adaptability. Unlike methods such as CoT [wei2022chain], CP provides multi-dimensional depth without manual solution design.

[IMAGE: cp.pdf - Left: General CP, Right: CP adapted to arithmetical reasoning.]

CP can be formalized as an optimization problem. Given a set of COPs `latex $C = \{c_1, c_2, \dots, c_n\}$ ` and a sequence `latex $S = \{s_1, s_2, \dots, s_k\}$ ` of `latex $k$ ` operations from `latex $C$ `, the goal is to find `latex $S^*$ ` that maximizes task performance `latex $S^* = \arg \max_{S \subseteq C} f(S)$ ` subject to constraints like `latex $|S| = k$ `, `latex $s_1 = \text{goal clarification}$ `, and `latex $s_k = \text{integration}$ `. Here, `latex $f(S)$ ` measures performance (e.g., accuracy or coherence).

#### Cognitive Operations.

This paper focuses on eight key COPs.

- _Goal Clarification._ This operation aligns the model's reasoning with the desired outcome and minimizes distractions. All subsequent operations are guided by this goal.

- _Decomposition:_ Break the problem `latex $P$ ` into smaller sub-problems, `latex $P_1, P_2, \dots, P_n$ `. This incremental approach is particularly useful for complex, multi-step problems, such as mathematical proofs or logical reasoning. Decomposition isolates critical components for systematic problem-solving.

- _Filtering:_ Select the most relevant information from the problem set, `latex $I_{\text{rel}} \subseteq I$ `. Filtering ensures the model concentrates on key details, excluding irrelevant data. By narrowing its focus, the model achieves greater accuracy and efficiency in problem-solving.

- _Reorganization:_ Rearrange data or variables to reveal patterns or simplify the problem structure. Reorganization helps the model uncover underlying relationships, making complex data more interpretable, and is particularly effective for algebraic manipulation or logical structuring.

- _Pattern Recognition:_ Identify recurring patterns or relationships, `latex $\mathcal{P}$ `, that connect the problem to known solutions. Recognizing patterns accelerates problem-solving by allowing the model to apply established strategies. This enhances predictive accuracy and facilitates generalization.

- _Abstraction:_ Extract broader principles from the identified patterns, `latex $\mathcal{P}$ `, for application across different problems. Abstraction helps the model transcend specific details and focus on core concepts, enabling flexible problem-solving.

- _Generalization:_ Apply the abstracted principles to solve broader problems or similar contexts. Generalization ensures that solutions are scalable and adaptable to related tasks, enhancing the model's reasoning robustness and versatility.

- _Integration:_ Synthesize the individual solutions, `latex $Q_i$ `, into a cohesive final answer, `latex $Q$ `, ensuring all sub-problems are resolved and producing a unified and consistent solution.

#### Domain-specific COPs.

Adapting COPs to specific domains ensures that the reasoning process remains relevant and effective for each task. For arithmetic reasoning, these general COPs are adapted as follows (see Figure 1, right).

# Cognitive Prompting Variants

CP comes in three variants. _Deterministic cognitive prompting (D-CP)_ follows a fixed manual designed sequence of cognitive operations, providing structure but less adaptability. We optimized the sequence of COPs in preliminary experiments. _Self-adaptive cognitive prompting (SA-CP)_ allows the model to self-select the next COP based on the task's needs, i.e., the LLM decides on its own, which COP to choose next. A prompt incorporating the following command enables self-adaptive prompting:

    For each step, choose and apply the most suitable cognitive operation
    from the list below and provide a concise explanation of your reasoning
    before moving on to the next step.

This flexibility enhances problem-solving and produces more interpretable reasoning, but is based on the model's own ability to structure reasoning. _Hybrid cognitive prompting (H-CP)_ uses a brief LLM-generated summary of successful problem solutions previously generated with CP and adds all `latex $k$ ` summaries to the CP instruction in a few-shot CoT fashion. This variant is based on the idea two combine structured thinking with successfully solved examples, a problem-solving strategy we believe also human reasoning often follows.

# Arithmetic Reasoning

#### Benchmark.

We evaluate the performance of CP using Meta's LLaMA 3.1 (8B and 70B), Google's Gemma 2 (9B and 27B), and Alibaba's Qwen 2.5 (7B and 32B) models on the GSM8K dataset [gsm8k], a widely used benchmark for math problem-solving. GSM8K consists of 7,000 training and 1,500 test high-quality, grade-school math word problems, designed to assess the reasoning and mathematical capabilities of LLMs. Since CP does not require training, we exclusively evaluate performance on the test set.

#### Mid-Size Models.

Figure 2 presents the experimental results, comparing standard zero-shot prompting with D-CP, SA-CP, and H-CP (based on the self-adaptive prompt) for the mid-size model variants, i.e., LLaMA 8B, Gemma 9B, and Qwen 7B. CP variants consistently outperform zero-shot prompting across all models, demonstrating significant improvements.

[IMAGE: Figure 2 - Solve rates of CP strategies using mid-size models on GSM8k (3 repetitions).]

#### Large Models.

Figure 3 compares all variants across large models, including LLaMA 70B, Gemma 27B, and Qwen 32B, highlighting consistent improvements with CP. Notably, H-CP demonstrates a significant performance advantage, achieving an impressive 95% solve rate on the LLaMA 70B model. While Qwen 32B delivers excellent results even with zero-shot prompting, its performance is further enhanced by CP, particularly with the hybrid CP variant.

[IMAGE: Figure 3 - Solve rates of CP strategies using large models on GSM8k (3 repetitions).]

[IMAGE: SA-COPs.pdf - Most frequent COP sequences chosen by SA-CP]

Figure 4 shows the most frequent COP sequences (Goal clarification (GC), decomposition (DC), pattern recognition (PR), generalization (GN), reorganization (RE)) that have automatically been chosen by SA-CP on LLaMA 70B. GC-DC-PR is the most frequent sequence, indicating its fundamental role. Shorter sequences dominate, while longer, more complex sequences are used less often. We observed similar results for the other LLMs.

# Conclusions

CP models human reasoning as a sequence of COPs delivered through structured prompts, fostering structured thinking through general or domain-specific COPs. Unlike example-based approaches like CoT, CP emphasizes high-level reasoning, making it highly adaptable across diverse tasks. Our experiments show that self-adaptive CP significantly boosts LLM performance on complex tasks, such as GSM8K math problems, with notable improvements for mid-size and larger models, though the proportional gain is greater for mid-size models. Additionally, the hybrid approach combining CoT few-shot prompting and CP delivers the best overall results across all experiments.

Our future work will focus on extending CP to additional domains and models, such as legal reasoning and strategic planning, to further validate its robustness in specialized tasks.
