# Abstract

Recent advances in large language models (LLMs), such as OpenAI-o1 and DeepSeek-R1, have demonstrated the effectiveness of test-time scaling, where extended reasoning processes substantially enhance model performance. Despite this, current models are constrained by limitations in handling long texts and reinforcement learning (RL) training efficiency. To address these issues, we propose a simple yet effective test-time scaling approach---**Multi-round Thinking**. This method iteratively refines model reasoning by leveraging previous answers as prompts for subsequent rounds. Extensive experiments across multiple models, including QwQ-32B and DeepSeek-R1, consistently show performance improvements on various benchmarks such as AIME 2024, MATH-500, GPQA-diamond, and LiveCodeBench. For instance, the accuracy of QwQ-32B improved from 80.3% (Round 1) to 82.1% (Round 2) on the AIME 2024 dataset, while DeepSeek-R1 showed a similar increase from 79.7% to 82.0%. These results confirm that **Multi-round Thinking** is a broadly applicable, straightforward approach to achieving stable enhancements in model performance, underscoring its potential for future developments in test-time scaling techniques.

The key prompt:

> _Original question prompt_
> The assistant's previous answer is: \<answer\> _last round answer_ \</answer\>, and please re-answer.

[IMAGE: Benchmark performance of QwQ-32B using Multi-round Thinking (round_performance_qwq_32b.png)]

[IMAGE: Benchmark performance of DeepSeek-R1 using Multi-round Thinking (round_performance_R1.png)]

# Introduction

Inference test-time compute [yang2025thinkingoptimalscalingtesttimecompute; wu2025inferencescalinglawsempirical] refers to the computational resources utilized by large language models (LLMs) during the generation of prompt responses, distinct from the training compute used for model creation and refinement. Leveraging step-by-step reasoning has shown substantial improvements in solving complex tasks by explicitly providing models with intermediate reasoning steps [lightman2023letsverifystepstep; wei2023chainofthoughtpromptingelicitsreasoning], significantly enhancing accuracy.

In recent years, the performance improvements of language models have largely depended on massive-scale self-supervised pre-training [kaplan2020scalinglawsneurallanguage; hoffmann2022trainingcomputeoptimallargelanguage], scaling up training-time compute. However, as advancements in training-time scaling slow, increasing attention is turning towards scaling up test-time compute [muennighoff2025s1simpletesttimescaling; chen2025reasoningerasurveylong]. OpenAI [OpenAI2024] pioneered this approach with their o1 series models [openai2024openaio1card] using large-scale reinforcement learning (RL).

DeepSeek further advanced test-time scaling by introducing the DeepSeek-R1 [deepseekai2025deepseekr1incentivizingreasoningcapability], successfully achieving performance comparable to OpenAI's o1 series. Prior approaches in inference test-time compute have included majority voting methods and external reward-based best-of-N strategies [levi2024simplemodelinferencescaling; diao2024activepromptingchainofthoughtlarge]. Unlike repetitive sampling, sequential expansion approaches enable models to iteratively refine attempts based on prior outcomes. Many researchers have attempted to replicate or extend their methods, employing Monte Carlo Tree Search (MCTS) [zhou2024languageagenttreesearch; choi2023kctsknowledgeconstrainedtreesearch], multi-agent approaches [qin2024o1replicationjourneystrategic; li2025searcho1agenticsearchenhancedlarge], some work based on Process Reward Model(PRM) [wang2024mathshepherdverifyreinforcellms; lightman2023letsverifystepstep].

Despite these successes, existing methods exhibit critical limitations. PRM face challenges such as defining fine-grained reasoning steps clearly, verifying intermediate reasoning correctness, and mitigating reward hacking [amodei2016concreteproblemsaisafety; langosco2023goalmisgeneralizationdeepreinforcement], making automated labeling challenging and manual labeling impractical for scaling. Similarly, MCTS methods encounter difficulties due to vast search spaces, often causing models to become trapped in local optima, and depend heavily on sophisticated scoring models that are challenging to train [deepseekai2025deepseekr1incentivizingreasoningcapability].

Addressing these issues, DeepSeek introduced a rule-based reward system combined with large-scale reinforcement learning (RL), enabling clearer guidance and promoting model self-reflection and deeper reasoning [deepseekai2025deepseekr1incentivizingreasoningcapability]. However, consistently identifying optimal reasoning paths remains challenging.

Inspired by human cognitive behaviors, we propose a novel test-time scaling strategy named **Multi-round Thinking**. This method allows the model to iteratively reconsider previous answers independently, using only the final answer from previous rounds as input prompts, discarding prior reasoning steps. This approach parallels human cognitive processes, breaking cognitive inertia and enabling the model to correct entrenched reasoning errors.

Our experimental results demonstrate the effectiveness of this intuitive approach. For example, using the DeepSeek-R1 model [deepseekai2025deepseekr1incentivizingreasoningcapability], performance improvements were observed across multiple benchmarks: on AIME 2024 [maa_aime_2024], pass@1 increased from 79.7% (Round 1) to 82.0% (Round 2); on GPQA-Diamond [rein2023gpqagraduatelevelgoogleproofqa], it rose from 74.0% to 74.8%; and on LiveCodeBench [jain2024livecodebench], performance improved from 65.3% to 67.1%. These findings underscore the substantial potential of iterative thinking for further exploiting the benefits of test-time scaling.

# Approach

We introduce a novel **Multi-round Thinking** approach designed to significantly enhance reasoning capabilities in large language models (LLMs). In contrast to traditional single-step reasoning methods, our approach iteratively refines answers through multiple rounds of inference. Each round takes the answer from the previous iteration (without intermediate reasoning steps) as part of a new input prompt, encouraging independent reconsideration and correction. This iterative process helps models avoid cognitive inertia, analogous to human strategies in overcoming entrenched errors in reasoning.

The Multi-round Thinking methodology operates explicitly as follows:

Given an original user prompt `latex $P_{user}$ `, the inference and refinement process proceeds iteratively:

**Initial Round (Round 1):** The language model receives the initial prompt and generates the first round of reasoning and final answer:

```latex
$$M(P_{user}) \rightarrow \{Thinking_{1}, Answer_{1}\}$$
```

**Subsequent Rounds (Round `latex $n$ `, `latex $n \geq 2$ `):** In each subsequent inference round, intermediate reasoning traces (`latex $Thinking_{n-1}$ `) from the previous iteration are discarded, retaining only the final answer (`latex $Answer_{n-1}$ `). The prompt for the next round is constructed by concatenating the original user prompt and the previously obtained answer:

```latex
$$P_{n} = P_{user} \oplus Answer_{n-1}$$
```

The model independently reevaluates the newly formed prompt and produces an updated reasoning trace and refined answer:

```latex
$$M(P_{n}) \rightarrow \{Thinking_{n}, Answer_{n}\}$$
```

This iterative refinement cycle can be formally represented as follows:

```latex
$$\begin{align}
&P_{1} = P_{user}, \quad M(P_{1}) \rightarrow \{Thinking_{1}, Answer_{1}\} \\
&P_{2} = P_{user} \oplus Answer_{1}, \quad M(P_{2}) \rightarrow \{Thinking_{2}, Answer_{2}\} \\
&P_{3} = P_{user} \oplus Answer_{2}, \quad M(P_{3}) \rightarrow \{Thinking_{3}, Answer_{3}\} \\
&\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad \vdots \\
&P_{n} = P_{user} \oplus Answer_{n-1}, \quad M(P_{n}) \rightarrow \{Thinking_{n}, Answer_{n}\}
\end{align}$$
```

In these equations, `latex $\oplus$ ` denotes the textual concatenation operation used to form the iterative prompts. Through this repeated refinement procedure, the model is encouraged to reconsider previous conclusions independently, effectively minimizing cognitive inertia and systematically improving the quality of reasoning outcomes.

Specifically, for a given question prompt `latex $P$ `, we first use a reasoning model to answer the question, producing a thought process `latex $T$ ` and an answer `latex $A$ `. Then, we concatenate the original question prompt `latex $P$ ` and the answer `latex $A$ ` using the following prompt:

> _Original question prompt_
> The assistant's previous answer is: \<answer\> _last round answer_ \</answer\>, and please re-answer.

We then send this prompt to the large model again to generate a new answer. Using this method, we can obtain multi-turn responses.

# Experiments

## Evaluation

### Benchmark

We evaluated the reasoning ability of the model using LiveCodeBench [jain2024livecodebench], GPQA-Diamond [rein2023gpqagraduatelevelgoogleproofqa], AIME 2024 [maa_aime_2024], and MATH-500 [lightman2023letsverifystepstep]. These benchmarks span multiple fields and difficulty levels, enabling a thorough assessment of the model's reasoning performance across diverse scenarios.

### Evaluation Methodology

We standardized the evaluation conditions by setting the maximum generation length at 32,768 tokens. For benchmarks requiring stochastic sampling, we uniformly set the temperature to 0.6 and the top-p value to 0.95. Specifically, for AIME 2024 [maa_aime_2024], we generated 32 samples per query to calculate pass@1 accuracy. For LiveCodeBench [jain2024livecodebench] and GPQA-Diamond [rein2023gpqagraduatelevelgoogleproofqa], we generated 8 samples per query to estimate pass@1. For MATH-500 [lightman2023letsverifystepstep], we generated 4 responses per query, also to estimate pass@1 accuracy. The primary evaluation metric adopted was the global average accuracy across all benchmarks.

## Results and Analysis

### Overall Results of Multi-round Thinking

Experimental results comparing initial (Round 1) and Multi-round Thinking (Round 2) performance are summarized in Table 1.

Experimental results consistently show that our proposed Multi-round Thinking method effectively enhances reasoning performance across diverse benchmarks. As detailed in Table 1, each evaluated model showed notable improvement when transitioning from Round 1 to Round 2 reasoning.

Specifically, for the Deepseek-R1 model, accuracy improved from 79.7% to 82.0% on the AIME 2024 benchmark, remained consistently high at 97.6% on MATH-500, increased from 74.0% to 74.8% on GPQA-Diamond, and improved from 65.3% to 67.1% on LiveCodeBench.

For the QwQ-32B model [qwq32b], notable gains were achieved, with accuracy rising from 80.3% to 82.1% on AIME 2024 [maa_aime_2024], 97.2% to 97.8% on MATH-500, 63.0% to 64.7% on GPQA-Diamond, and 65.9% to 67.2% on LiveCodeBench.

Further, we evaluated our self-trained AM-Distill-Qwen-32B model, a 32B model built upon the Qwen2.5-32B [qwen2.5] architecture and trained using distilled data from the DeepSeek-R1 model (refer to [AM-DeepSeek-R1-Distilled-1.4M] for distillation details). Experimental results demonstrated robust performance improvements with Multi-round Thinking: accuracy increased from 72.8% to 76.7% on AIME 2024, from 96.2% to 97.2% on MATH-500, from 62.3% to 62.8% on GPQA-Diamond, and from 58.3% to 60.2% on LiveCodeBench.

Building upon this, we further examine the performance trajectory of QwQ-32B across four rounds of iterative thinking, as visualized in Figure 1. The model exhibits a clear and steady upward trend across all benchmarks.

From Round 1 to Round 4, QwQ-32B's performance on AIME 2024 improves from 80.3% to 83.1%, indicating enhanced capability in competition-level mathematical reasoning. On the MATH-500 dataset, performance remains consistently high, fluctuating slightly within the 97.2%--97.8% range.

Substantial gains are observed on reasoning-heavy benchmarks like GPQA-Diamond, where accuracy increases from 65.9% to 68.1% over four rounds. Similarly, LiveCodeBench scores rise from 63.0% to 65.9%, reflecting a notable enhancement in code understanding and generation tasks.

These empirical results highlight the consistent advantage provided by the Multi-round Thinking methodology, underscoring its efficacy in iteratively refining reasoning processes, correcting earlier mistakes, and substantially boosting model performance across challenging reasoning tasks.

In summary, our results strongly indicate that Multi-round Thinking consistently improves the reasoning performance of LLMs across various tasks. Particularly notable is its effectiveness on tasks demanding complex, iterative reasoning such as mathematics competitions and coding benchmarks. Moreover, the incremental and sustained improvements observed over multiple rounds underscore the robustness of this simple yet effective test-time scaling strategy. These findings suggest that Multi-round Thinking offers an efficient pathway to enhance model accuracy without additional training overhead, thus highlighting its practical value for real-world deployment and opening promising avenues for future research in test-time scaling methods.

### Analysis of Word Frequency Changes

To better understand how the model's reasoning behavior evolves through multi-round thinking, we conduct a lexical analysis focusing on four discourse markers: but, wait, maybe, and therefore. These words serve as linguistic signals for hesitation (but, wait, maybe) or decisiveness (therefore), and tracking their usage reveals insights into the model's confidence and reasoning dynamics.

[IMAGE: Overall change in word frequency across all AIME 2024 examples (word_frequence_all.png)]

[IMAGE: Changes in average word frequency across different reasoning trajectories. Each subplot shows the average frequency of four indicative words -- but, wait, maybe, and therefore -- in Round 1 vs. Round 2, grouped by response type: I-C (Incorrect -> Correct), I-I (Incorrect -> Incorrect), C-C (Correct -> Correct), and C-I (Correct -> Incorrect) (word_frequence_merge.png)]

Figure 3 presents the overall average usage frequency of these keywords across all AIME 2024 test samples. From Round 1 to Round 2, we observe consistent declines in the frequency of hesitation-related words. Specifically, but decreases from 68.3 to 44.8, wait from 67.9 to 51.0, and maybe from 23.7 to 15.8. Even therefore, although a more conclusive word, experiences a drop from 43.8 to 29.5, but the relative reduction is smaller. This suggests that, overall, the model adopts more concise and assertive phrasing in Round 2 responses.

To analyze this shift in greater detail, Figure 4 breaks down average keyword usage by answer trajectory: Incorrect->Correct (I-C), Incorrect->Incorrect (I-I), Correct->Correct (C-C), and Correct->Incorrect (C-I). In most groups, there is a significant drop in but, wait, and maybe from Round 1 to Round 2, reinforcing the observation that models tend to suppress uncertain or self-interruptive phrasing after one round of reflection. For example, in the I-I group, but drops from 145.2 to 106.8 and wait from 131.4 to 110.8, indicating that even when the model fails in both rounds, it still shifts toward more direct expression.

Interestingly, in the I-C group where the model corrects its earlier error, we observe an increase in the use of wait and therefore. This suggests a more thoughtful and deliberate step-by-step reanalysis process. The rise in therefore (from 63.7 to 66.0) also reflects the model's increased confidence in arriving at the correct conclusion.

Together, these patterns suggest that multi-round thinking helps the model become more confident, fluent, and decisive in its responses---reducing hedging and strengthening clarity.

### Analysis of Response Length

We analyzed the generation lengths of the model across different inference rounds.

As the number of inference rounds increases, the generation length tends to decrease. Moreover, there is a correlation between performance improvement and the reduction in generation length---the greater the performance gain, the more significant the reduction. For example, from Round 1 to Round 2, the average score improves by 1.4 points while the average generation length decreases by 2749.1 tokens; from Round 2 to Round 3, there is minimal improvement in performance, while the average generation length decreases by only 675.9 tokens.

[IMAGE: Changes in response length across reasoning rounds on the AIME 2024 dataset (QwQ-32B model). Labels represent the correctness trajectory from Round 1 to Round 2: "C" = Correct, "I" = Incorrect. For example, "C-I" indicates responses that were correct initially but became incorrect in the next round (answer_length_variation.png)]

As shown in Figure 5, we analyzed the changes in response lengths for the same questions across different inference rounds. We found that when the model answered correctly in the previous round but incorrectly in the current round, the inference length increased significantly. This trend is consistent with the word frequency analysis in Figure 3, where the frequency of the word "wait" rises notably, suggesting increased uncertainty in the model's reasoning. In contrast, when the model answers correctly in both the previous and current rounds, it becomes more confident, leading to a substantial reduction in inference length.

## A Preliminary Experiment with Supervised Fine-tuning (SFT)

To further enhance the robustness of Multi-round Thinking, we explored combining it with supervised fine-tuning (SFT). The key idea was to reduce error propagation from earlier reasoning rounds by explicitly training the model to rectify previously incorrect answers.

Specifically, our supervised fine-tuning process involved the following steps:

- **Data selection**: We selected challenging mathematical and programming tasks from open datasets, ensuring each could be independently verified.

- **Data generation**: We employed the DeepSeek-R1 model iteratively on these tasks using Multi-round Thinking until a correct answer was verified, forming a dataset of approximately 100,000 examples.

- **Model training**: This dataset was used to fine-tune our AM-32B model in an initial round of supervised training.

After SFT, we conducted further experiments based on the AM-32B Round2 reasoning outputs. While this preliminary fine-tuning did not lead to performance improvements in our current evaluation (see Table 3), it opens up promising directions for future research in leveraging high-quality reasoning data to enhance Multi-round Thinking.

# Discussion and Conclusion

In this study, we proposed Multi-round Thinking, a straightforward yet effective test-time scaling strategy designed to enhance the reasoning capabilities of large language models (LLMs). Inspired by human cognitive processes, this iterative approach allows models to refine their reasoning by independently reconsidering their previous answers, significantly mitigating cognitive inertia and correcting initial reasoning errors. Our extensive experiments demonstrated consistent and substantial improvements across challenging benchmarks, including AIME 2024, GPQA-Diamond, MATH-500, and LiveCodeBench. For instance, accuracy improved by more than 2 percentage points on complex mathematical competition tasks, underscoring the broad applicability and practical value of this approach.

Further analysis revealed that multi-round reasoning not only improved accuracy but also made the models' reasoning more concise and confident. Specifically, we observed a reduction in uncertainty markers (such as "but", "wait", and "maybe") and shorter responses, reflecting increased model clarity and decisiveness in reasoning. These linguistic insights indicate that iterative thinking aligns closely with human cognitive patterns, enhancing the transparency and interpretability of LLM behaviors.

While preliminary experiments integrating supervised fine-tuning (SFT) did not immediately yield additional improvements, they highlighted crucial considerations for future research---particularly regarding the quality of training data and fine-tuning strategies tailored explicitly for iterative reasoning. Exploring these directions further promises significant theoretical and practical benefits, potentially unlocking even greater reasoning capabilities in LLMs.

In practical product applications, adopting a "think twice" approach can conveniently incorporate the first-round response as part of the thinking process itself, effectively realizing performance gains. However, this inevitably introduces additional waiting time during the thinking phase.

In summary, Multi-round Thinking represents a practical, efficient, and universally applicable method for improving LLM reasoning without additional training overhead. This research opens valuable pathways for future exploration and offers immediate utility for both academia and industry in the ongoing quest for more robust, reliable, and explainable AI reasoning.

# Example

[IMAGE: Illustration of the "Think Twice" Strategy in Multi-round Reasoning (20250325-232442.jpeg)]

The model first provides an incorrect answer by following its initial reasoning chain. Upon invoking the "Think Twice" mechanism, it is explicitly prompted to reassess its prior response. The model then revisits its reasoning, identifies the over-simplified solution space, and produces a corrected answer with a significantly expanded and accurate enumeration. This process highlights the effectiveness of forcing self-reflection to catch subtle counting mistakes.
