# Abstract

Self-consistency with chain-of-thought prompting (CoT) has demonstrated remarkable performance gains on various challenging tasks, by utilizing multiple reasoning paths sampled from large language models (LLMs). However, self-consistency relies on the answer extraction process to aggregate multiple solutions, which is not applicable to free-form answers. In this work, we propose Universal Self-Consistency (USC), which leverages LLMs themselves to select the most consistent answer among multiple candidates. We evaluate USC on a variety of benchmarks, including mathematical reasoning, code generation, long-context summarization, and open-ended question answering. On open-ended generation tasks where the original self-consistency method is not applicable, USC effectively utilizes multiple samples and improves the performance. For mathematical reasoning, USC matches the standard self-consistency performance without requiring the answer formats to be similar. Finally, without access to execution results, USC also matches the execution-based voting performance on code generation.

# Introduction

Large language models (LLMs) have accomplished significant breakthroughs in a wide variety of domains, including mathematical reasoning [cobbe2021training; wei2022chain; lewkowycz2022solving], code generation [chen2021evaluating; austin2021program; li2022competition], and other text generation tasks [bubeck2023sparks; anil2023palm; touvron2023llama]. Despite the rapid progress, the LLM-generated responses are still prone to errors when they get long. A long line of efforts have been devoted to improve the output quality by sampling multiple model responses and then selecting the final output based on certain criteria. For example, prior works have trained neural networks to rerank model outputs [cobbe2021training; li2023making; ni2023lever; yin2019reranking; zeng2022n], and more recent works investigate using LLMs to score the responses [fu2023gptscore; liu2023geval; wang2023chatgpt].

In this work, we consider the _consistency_ among model responses as the criterion to select the model output, a generic metric that has enabled huge performance leaps in reasoning [wang2022self] and code generation [li2022competition; shi-etal-2022-natural]. In particular, self-consistency [wang2022self] with chain-of-thought prompting [wei2022chain] boosts the performance on various benchmarks, by marginalizing latent reasoning paths through sampling which leads to select the final answer as the most common one. However, self-consistency can only be applied to tasks where the final answer can be aggregated via exact match, e.g., a single number for math problems.

To address this major limitation of self-consistency, we propose Universal Self-Consistency (USC) to support various applications, especially free-form generation tasks. Specifically, given multiple candidate responses, USC simply calls the LLM to select the most consistent response among them as the final output. Thus, USC eliminates the need of designing an answer extraction process, and is applicable to tasks with free-form answers. Although prior works have revealed weaknesses of LLMs for response selection, such as position bias [wang2023large; zheng2023large] and incorrectly judging the answer correctness [huang2023large; gou2023critic], intuitively, assessing the consistency among candidate answers is easier than measuring and comparing the answer quality.

We evaluate universal self-consistency on a wide range of tasks, including mathematical reasoning, code generation, long-context summarization, and open-ended question answering. On GSM8K [cobbe2021training] and MATH [hendrycks2021measuring] benchmarks for math problem solving, USC generally matches the performance of the standard self-consistency. On programming tasks including text-to-SQL generation [li2023can] and Python code generation [yin-etal-2023-natural], USC matches the performance of execution-based consistency [li2022competition; shi-etal-2022-natural], while USC does not require execution results to aggregate over candidate programs. Finally, USC also improves the performance for open-ended question answering [lin2021truthfulqa] and long-context summarization [huang2021efficient; chen2022summscreen], where the standard self-consistency is not applicable. In addition to the performance gain, our evaluation also demonstrates that USC outputs highly match those of the standard self-consistency when the comparison is applicable, while it is robust to the ordering of candidate responses.

# Background: Self-Consistency

Self-consistency [wang2022self] augments chain-of-thought prompting [wei2022chain] by sampling multiple reasoning chains and then taking a majority vote on the final answer set. The intuition is that sometimes the greedily decoded reasoning process might not be the optimal one, hence it makes more sense to sample a diverse set of reasoning chains, and if some of them lead to the same answer, then we have a higher confidence that this consistent answer is the correct one. It has been shown that self-consistency improves the greedy chain-of-thought prompting by a large margin on a wide set of reasoning tasks.

Besides question answering tasks, consistency-based answer selection has also been applied to code generation [shi-etal-2022-natural; li2022competition; chen2019execution], which requires code execution. Specifically, we first execute all predicted programs on the given inputs, then programs with the same execution outputs are clustered together, assuming that they are semantically equivalent. Finally, we select the program belonging to the largest cluster as the final prediction. When the program inputs given in the task description are insufficient to distinguish between different predictions, this execution-based code selection is also often accompanied with a test case generation process to better examine the consistency [li2022competition; chen2022codet; huang2023enhancing].

Despite the remarkable improvement, self-consistency is only applicable to problems with a unique and closed-form answer, e.g., when the final answer consists of a single number, because a majority vote needs to be taken over the final answer set. This significant requirement poses a challenge for tasks that require open-ended generations, such as summarization, creative writing, and open-ended question answering.

# Universal Self-Consistency

[IMAGE: Overview of the Universal Self-Consistency workflow (figs/usc.png)]

[IMAGE: Examples of Universal Self-Consistency for answer selection from responses of diverse formats: (a) mathematical reasoning; and (b) open-ended question answering. Note that for the given open-ended question, the final answer is an entity list, where no two responses share the same predictions. Still, the LLM correctly selects the response where the individual entities in the predicted list appear most frequently in the candidate responses.]

We present the overall workflow of universal self-consistency (USC), which utilizes LLMs to enable self-consistency for a wide variety of tasks, especially free-form text generation. First, we sample multiple responses with the large language model. Afterward, to select one model response as the final answer, we concatenate all responses together, and then construct a prompt with an instruction asking the language model to select the most consistent response. In this way, USC obviates the necessity of counting the exact answer frequency as in the standard self-consistency, and relies on the LLM's own ability to measure the consistency among different responses. Although prior works show that LLMs sometimes have trouble evaluating the prediction correctness [huang2023large; gou2023critic], especially for reasoning problems, empirically we observe that LLMs are generally able to examine the response consistency across multiple tasks.

Consistency assessment with LLMs offers more flexibility for free-form generation. The example tasks demonstrate where different consistency criteria are beneficial for response selection. Specifically, different model responses for a math problem show that output formats are diverse and thus makes it challenging for rule-based methods to extract answers. Nonetheless, assuming that the final answers are correctly extracted, the consistency criterion still follows the standard self-consistency on mathematical reasoning, which is based on the exact match of the final answers represented as single numerical values. On the other hand, for an example question where the final answer is an entity list, despite that there is no response that is consistent with others based on the exact match, the LLM selects the response where each of the predicted entities appears most frequently among the candidate outputs. We further show that LLM can also examine the consistency among responses beyond the question answering tasks, including code generation without access to the execution outputs, and long-context summarization.

# Experiments

## Evaluation Setup

#### Benchmarks

We evaluate USC on the following variety of tasks:

- _Mathematical reasoning benchmarks_, including GSM8K [cobbe2021training], a dataset of 8,500 grade school math word problems, and MATH [hendrycks2021measuring], a dataset of 12,500 challenging mathematics problems from high school competitions.

- _Code generation benchmarks_, including BIRD-SQL dataset [li2023can] for text-to-SQL generation, and ARCADE dataset [yin-etal-2023-natural] for Python code generation in data science notebooks.

- _Long-context summarization_, including the GovReport and SummScreen benchmarks from ZeroSCROLLS [shaham2023zeroscrolls]. In GovReport [huang2021efficient], each input is a document containing ~7,900 words on average, and the reference output is an expert-written executive summary with ~500 words. In SummScreen [chen2022summscreen], every input is a transcript of a TV show episode with ~5,600 words, and each reference output is a ~100 words human-written recap of the episode. We follow [shaham2023zeroscrolls] and measure ROUGE 1, ROUGE 2, and ROUGE-Lsum which measure n-gram overlap with the reference summary, and we also measure BERTScore F1 [zhang2019bertscore].

- _TruthfulQA [lin2021truthfulqa] benchmark_ for open-ended question answering, which contains 817 questions to test model's ability in generating truthful answers. To evaluate the answer's quality, we use the GPT-judge and GPT-info, which are GPT-3 models fine-tuned on human feedback data, provided by [lin2021truthfulqa]. GPT-judge model outputs a binary rating for truthfulness, and GPT-info model outputs a binary rating for informativeness. It is shown that the GPT-3 models have higher accuracy in predicting human judgement than the automatic metrics ROUGE, BLEU, BLEURT.

#### Decoding schemes

We compare USC to the following decoding schemes:

- _Greedy decoding_ generates a single answer with the temperature 0.

- _Random_ selects one answer randomly from multiple samples with temperature > 0.

- _SC_ [wang2022self] is the standard self-consistency decoding with answer extraction. We evaluate SC whenever applicable; for example, on reasoning benchmarks where the final answers can be compared through exact match.

To enable a fair comparison, for sampling schemes (i.e., except greedy decoding), we always select the final answer from the same set of initial model responses. For code generation, we compare our approach to execution-based self-consistency [shi-etal-2022-natural; li2022competition; chen2019execution], where we select the code with the most common execution result. Both USC and execution-based self-consistency first filter out syntactically invalid candidate programs, and then perform the voting over the remaining ones. For ARCADE benchmark, we also evaluate a variant of the execution-based self-consistency with fuzzy matching as described in [yin-etal-2023-natural], which implements a set of heuristics to determine whether the execution outputs of two programs are equivalent when they are not exact match.

#### Implementation details

We conduct experiments using instruction-tuned `PaLM 2-L` [anil2023palm] and `gpt-3.5-turbo` models. Unless otherwise specified, the LLM generates 8 initial samples for both SC and USC. For mathematical reasoning, summarization and the ARCADE benchmark for Python code generation, the initial samples are generated with zero-shot prompting, thus the output formats are diverse. For BIRD-SQL, we used the 1-shot chain-of-thought prompt in [li2023can], which improves the performance. We also utilized a one-shot prompt for TruthfulQA to improve the quality of candidate responses. We set the temperature to be 0.6 for `PaLM 2-L`, and 1.0 for `gpt-3.5-turbo`.

## Main Results

#### Mathematical reasoning

For mathematical reasoning benchmarks, we compare USC against the standard self-consistency. For the standard self-consistency, we employ a regular expression matching to extract the final answer on GSM8K, and re-use the answer parsing code from [zheng2023progressive] for MATH. Overall, USC consistently improves over the greedy decoding and random selection, and the performance is generally comparable to the standard self-consistency, which USC does not need answer parsing to perform the voting.

#### Code generation

Results on BIRD-SQL and ARCADE show that besides the execution accuracy, we follow [li2023can] to also evaluate the valid efficiency score, which measures the efficiency of the generated SQL queries. We show that USC matches the execution-based self-consistency performance on both benchmarks, while USC does not utilize code execution to perform the voting.

#### Summarization

Since the generated summaries are in free-form, the standard self-consistency is not applicable. In GovReport, USC consistently improves over the baselines across all metrics. We further show that asking the model to choose the _most detailed_ summary results in more performance gain.

#### TruthfulQA

Results on TruthfulQA show that SC is not directly applicable because the generated answers are in free-form. Comparing with greedy decoding and random selection, USC-based answers have the highest truthfulness with both `PaLM 2-L` and `gpt-3.5-turbo`. For informativeness which is considered as a secondary objective, USC-based answers have the highest score on `PaLM 2-L` and the second highest score (0.1 lower than the highest) on `gpt-3.5-turbo`. Considering that GPT-judge and GPT-info models have generally 90-95% validation accuracy on rating prediction [lin2021truthfulqa], the 0.1 difference is not considered significant.

**Table 1: Accuracy on mathematical reasoning benchmarks. USC and SC consistently improve over the greedy decoding and random selection. USC performance is generally comparable to SC.**

| Model         | Approach          | GSM8K    | MATH     |
| ------------- | ----------------- | -------- | -------- |
| PaLM 2-L      | Greedy decoding   | 85.7     | 30.8     |
| PaLM 2-L      | Random            | 82.9     | 28.0     |
| PaLM 2-L      | SC [wang2022self] | **90.4** | **37.9** |
| PaLM 2-L      | USC               | 90.2     | 37.4     |
| gpt-3.5-turbo | Greedy decoding   | 73.4     | 33.2     |
| gpt-3.5-turbo | Random            | 68.5     | 26.3     |
| gpt-3.5-turbo | SC                | **78.5** | 38.0     |
| gpt-3.5-turbo | USC               | 77.8     | **38.1** |

**Table 2: Accuracy on code generation benchmarks with gpt-3.5-turbo.**

| Dataset  | Approach               | Execution Accuracy | Valid Efficiency Score |
| -------- | ---------------------- | ------------------ | ---------------------- |
| BIRD-SQL | Greedy decoding        | 42.4               | 44.4                   |
| BIRD-SQL | Random                 | 41.9               | 44.0                   |
| BIRD-SQL | SC-Exec                | **45.6**           | 48.1                   |
| BIRD-SQL | USC                    | 45.5               | **48.8**               |
| ARCADE   | Greedy decoding        | 26.0               | N/A                    |
| ARCADE   | Random                 | 26.8               | N/A                    |
| ARCADE   | SC-Exec (strict match) | 29.8               | N/A                    |
| ARCADE   | SC-Exec (fuzzy match)  | **30.3**           | N/A                    |
| ARCADE   | USC                    | 30.1               | N/A                    |

**Table 3: Results on long-context summarization benchmarks with PaLM 2-L. Since the outputs are in free-form, the standard self-consistency is not applicable. USC consistently improves over the baselines on summary quality.**

| Dataset    | Approach        | ROUGE-1  | ROUGE-2  | ROUGE-Lsum | BERTScore |
| ---------- | --------------- | -------- | -------- | ---------- | --------- |
| GovReport  | Greedy decoding | 38.8     | 16.9     | 33.8       | 62.7      |
| GovReport  | Random          | 38.5     | 16.9     | 33.6       | 62.6      |
| GovReport  | USC             | **40.2** | **17.4** | **35.1**   | **62.8**  |
| SummScreen | Greedy decoding | 30.6     | 7.5      | 19.1       | **58.7**  |
| SummScreen | Random          | 30.2     | 7.3      | 19.0       | 58.6      |
| SummScreen | USC             | **31.7** | **7.8**  | **19.8**   | 58.3      |

**Table 4: Accuracy on the TruthfulQA benchmark. Since the answer is in free-form, the standard self-consistency is not applicable. USC overall has the highest truthfulness and informativeness over the baselines.**

| Model         | Approach        | GPT-judge | GPT-info |
| ------------- | --------------- | --------- | -------- |
| PaLM 2-L      | Greedy decoding | 62.1      | 95.1     |
| PaLM 2-L      | Random          | 62.9      | 94.6     |
| PaLM 2-L      | USC             | **67.7**  | **99.0** |
| gpt-3.5-turbo | Greedy decoding | 79.8      | **99.7** |
| gpt-3.5-turbo | Random          | 80.6      | 99.3     |
| gpt-3.5-turbo | USC             | **82.5**  | 99.6     |

## Ablations

#### Effect of response ordering

Prior works have shown that large language models can be affected by the order of candidate responses when used to evaluate their quality [wang2023large; zheng2023large]. We examine the effect of response ordering by performing USC with 5 different random orders when concatenating all responses, and calculate the mean and standard deviation of the task results. We observe that the overall model performance remains similar with different response orders, suggesting the effect of response order is minimal.

**Table 5: Effect of response ordering on mathematical reasoning with PaLM 2-L.**

| Dataset | Acc          |
| ------- | ------------ |
| GSM8K   | 89.7 +/- 0.3 |
| MATH    | 37.3 +/- 0.2 |

**Table 6: Effect of response ordering on summarization with PaLM 2-L.**

| Dataset    | ROUGE-1      | ROUGE-Lsum   |
| ---------- | ------------ | ------------ |
| SummScreen | 31.6 +/- 0.3 | 19.5 +/- 0.2 |
| GovReport  | 40.0 +/- 0.1 | 34.9 +/- 0.2 |

**Table 7: Effect of response ordering on TruthfulQA with PaLM 2-L.**

| Metric    | TruthfulQA   |
| --------- | ------------ |
| GPT-judge | 68.3 +/- 0.6 |
| GPT-info  | 99.0 +/- 0.1 |

#### Different number of responses

Next, we examine the effect of using different numbers of responses in USC. USC consistently benefits from more samples on TruthFulQA and BIRD-SQL. However, USC does not further improve the performance on SummScreen after 5 samples, and the accuracy on GSM8K decreases with 16 samples. This can be due to the weakness in long-context understanding when the prompt contains more candidate responses, and the imperfect counting ability of LLMs. Nevertheless, we consider utilizing a few samples (e.g., 8) a sweet spot to balance the task accuracy and compute cost, in which case USC reliably improves the performance across the board. We further compare the predictions from USC and SC to understand how using more candidate responses affects the results.

#### Criteria for response selection

One advantage of USC is its generality: the same criteria can be applied to various tasks, without any task-specific knowledge. Nonetheless, a minor task-specific adaptation of the response selection instruction can further boost USC over the generic prompts. For example, asking the LLM to choose the most _detailed_ response (rather than the most _consistent_ one) results in gains of about 2 ROUGE-1 and ROUGE-Lsum points.

**Table 8: Ablation on the response selection criterion on long-context summarization benchmarks with PaLM 2-L.**

| Dataset    | Approach             | ROUGE-1  | ROUGE-2  | ROUGE-Lsum | BERTScore |
| ---------- | -------------------- | -------- | -------- | ---------- | --------- |
| GovReport  | USC                  | 40.2     | 17.4     | 35.1       | 62.8      |
| GovReport  | USC -- most detailed | **42.4** | **18.2** | **36.9**   | **63.2**  |
| SummScreen | USC                  | 31.7     | 7.8      | 19.8       | **58.3**  |
| SummScreen | USC -- most detailed | **33.0** | **7.9**  | **22.0**   | **58.3**  |

## Discussion: How well does USC match SC selection?

[IMAGE: Comparison of selections made by USC versus SC with PaLM 2-L. k denotes the number of candidate responses for selection. "Tied votes" represents the case where the USC and SC select different responses, but both have the maximum votes.]

[IMAGE: Accuracy distribution when USC selection doesn't match SC.]

We have demonstrated that on tasks where the standard self-consistency is applicable, USC and SC achieve comparable overall performance with 8 samples; however, USC fails to further improve the GSM8K performance with 16 samples. In this section, we look closer into the relationship between USC and SC, specifically how well is the alignment between their selected responses.

A breakdown analysis of USC predictions on mathematical reasoning benchmarks with 8 and 16 candidate responses shows the following observations:

- The voting ties constitute a notable portion to the selection differences between USC and SC, especially with 8 candidate responses. Specifically, among all responses with the maximum votes, SC always selects the one with the smallest index, while USC can pick up alternative ones based on the response format.

- The match ratio between USC and SC consistently surpasses their own task accuracies, which shows that the consistency criterion is easier to measure than the answer correctness.

- Shifting from 8 to 16 samples, the USC-SC match ratio reduces, suggesting that USC behaves as an imperfect approximation of SC. However, the difference in response selection does not always lead to the performance decrease, as USC sometimes selects the correct response when SC fails.

# Limitations and Future Work

Despite that USC supports open-ended generation tasks and generally achieves comparable performance in those domains where the standard self-consistency can be applied, our current USC implementation has its own limitations compared to the extraction-based self-consistency approach.

First, while self-consistency can be applied to an arbitrary number of samples as long as the final answers can be extracted, the number of samples supported by USC is bounded by the context length of the underlying LLM. That said, to seek a balance between the task performance and the sampling cost, in practice the number of generated samples per task is not prohibitively large, thus the context length is generally sufficient to make best use of the samples.

Second, the voting mechanism in self-consistency inherently offers a measure of confidence or uncertainty for each response [wang2022self]. However, universal self-consistency has not yet been developed to include the confidence estimation. We consider developing a calibration mechanism for USC as future work, where we can leverage the LLM to perform output clustering and pairwise self-consistency.

Also, USC requires an additional LLM query by design, which incurs additional inference costs. Given that our USC prompt only requires the LLM to generate a response index corresponding to the final answer, the USC output length is much shorter than any individual candidate response to select from. To further reduce the cost, one direction is to use a light-weight language model to conduct USC, and optimizes its efficiency regarding long-context encoding.

Finally, one common limitation of both the standard self-consistency and USC is about the consistency-based selection criterion. Specifically, although consistency is a generic and effective criterion, the most consistent response is not necessarily the best one. We observe that there is still a notable gap to oracle scores where we assume the access to an oracle reranker that always selects the best response. We demonstrate that we can design task-specific criteria to further improve the performance, and we consider refining the USC framework to further close the gap to the oracle performance as future work.

# Conclusion

In this work, we presented Universal Self-Consistency (USC), which extends the standard self-consistency to support free-form generation tasks. USC notably boosts the performance in diverse applications, and performs on par with the standard self-consistency on those tasks where answer extraction is feasible for voting. Besides addressing the limitations discussed above, we also consider mitigating the position bias and improving long-context understanding of LLMs as important future work that can further enhance the effectiveness and robustness of the USC scheme.
