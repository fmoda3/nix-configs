# Self-Consistency Improves Chain of Thought Reasoning in Language Models

## Abstract

Chain-of-thought prompting combined with pre-trained large language models has achieved encouraging results on complex reasoning tasks. In this paper, we propose a new decoding strategy, _self-consistency_, to replace the naive greedy decoding used in chain-of-thought prompting. It first samples a diverse set of reasoning paths instead of only taking the greedy one, and then selects the most consistent answer by marginalizing out the sampled reasoning paths. Self-consistency leverages the intuition that a complex reasoning problem typically admits multiple different ways of thinking leading to its unique correct answer. Our extensive empirical evaluation shows that self-consistency boosts the performance of chain-of-thought prompting with a striking margin on a range of popular arithmetic and commonsense reasoning benchmarks, including GSM8K (+17.9%), SVAMP (+11.0%), AQuA (+12.2%), StrategyQA (+6.4%) and ARC-challenge (+3.9%).

## Introduction

Although language models have demonstrated remarkable success across a range of NLP tasks, their ability to demonstrate reasoning is often seen as a limitation, which cannot be overcome solely by increasing model scale [rae2021scaling; bigbench *inter alia*]. In an effort to address this shortcoming, Wei et al. have proposed _chain-of-thought prompting_, where a language model is prompted to generate a series of short sentences that mimic the reasoning process a person might employ in solving a task. For example, given the question _"If there are 3 cars in the parking lot and 2 more cars arrive, how many cars are in the parking lot?"_, instead of directly responding with _"5"_, a language model would be prompted to respond with the entire chain-of-thought: _"There are 3 cars in the parking lot already. 2 more arrive. Now there are 3 + 2 = 5 cars. The answer is 5."_. It has been observed that chain-of-thought prompting significantly improves model performance across a variety of multi-step reasoning tasks [wei2022chain].

In this paper, we introduce a novel decoding strategy called _self-consistency_ to replace the greedy decoding strategy used in chain-of-thought prompting [wei2022chain], that further improves language models' reasoning performance by a significant margin. Self-consistency leverages the intuition that complex reasoning tasks typically admit multiple reasoning paths that reach a correct answer [stanovich2000individual]. The more that deliberate thinking and analysis is required for a problem [evans2010intuition], the greater the diversity of reasoning paths that can recover the answer.

[IMAGE: figures/self_consistency_fig.pdf - The self-consistency method contains three steps: (1) prompt a language model using chain-of-thought (CoT) prompting; (2) replace the "greedy decode" in CoT prompting by sampling from the language model's decoder to generate a diverse set of reasoning paths; and (3) marginalize out the reasoning paths and aggregate by choosing the most consistent answer in the final answer set.]

Self-consistency is far simpler than prior approaches that either train an additional verifier [cobbe2021training] or train a re-ranker given additional human annotations to improve generation quality [thoppilan2022lamda]. Instead, self-consistency is entirely _unsupervised_, works off-the-shelf with pre-trained language models, requires no additional human annotation, and avoids any additional training, auxiliary models or fine-tuning. Self-consistency also differs from a typical ensemble approach where multiple models are trained and the outputs from each model are aggregated, it acts more like a "self-ensemble" that works on top of a _single_ language model.

We evaluate self-consistency on a wide range of arithmetic and commonsense reasoning tasks over four language models with varying scales: the public UL2-20B [ul2] and GPT-3-175B [brown2020language], and two densely-activated decoder-only language models: LaMDA-137B [thoppilan2022lamda] and PaLM-540B [palm]. On all four language models, self-consistency improves over chain-of-thought prompting by a striking margin across all tasks. In particular, when used with PaLM-540B or GPT-3, self-consistency achieves new state-of-the-art levels of performance across arithmetic reasoning tasks, including GSM8K [cobbe2021training] (+17.9% absolute accuracy gains), SVAMP [patel-etal-2021-nlp] (+11.0%), AQuA [ling-etal-2017-program] (+12.2%), and across commonsense reasoning tasks such as StrategyQA [geva-etal-2021-aristotle] (+6.4%) and ARC-challenge [Clark2018ThinkYH] (+3.9%). In additional experiments, we show self-consistency can robustly boost performance on NLP tasks where adding a chain-of-thought might hurt performance compared to standard prompting [ye2022unreliability]. We also show self-consistency significantly outperforms sample-and-rank, beam search, ensemble-based approaches, and is robust to sampling strategies and imperfect prompts.

## Self-Consistency over Diverse Reasoning Paths

A salient aspect of humanity is that people think differently. It is natural to suppose that in tasks requiring deliberate thinking, there are likely several ways to attack the problem. We propose that such a process can be simulated in language models via sampling from the language model's decoder. For instance, as shown in Figure 1, a model can generate several plausible responses to a math question that all arrive at the same correct answer (Outputs 1 and 3). Since language models are not perfect reasoners, the model might also produce an incorrect reasoning path or make a mistake in one of the reasoning steps (e.g., in Output 2), but such solutions are less likely to arrive at the _same_ answer. That is, we hypothesize that correct reasoning processes, even if they are diverse, tend to have greater agreement in their final answer than incorrect processes.

We leverage this intuition by proposing the following _self-consistency_ method. First, a language model is prompted with a set of manually written chain-of-thought exemplars [wei2022chain]. Next, we sample a set of candidate outputs from the language model's decoder, generating a diverse set of candidate reasoning paths. Self-consistency is compatible with most existing sampling algorithms, including temperature sampling [ACKLEY1985147; ficler-goldberg-2017-controlling], top-k sampling [fan-etal-2018-hierarchical; holtzman-etal-2018-learning; Radford2019LanguageMA], and nucleus sampling [nucleus_sampling]. Finally, we aggregate the answers by marginalizing out the sampled reasoning paths and choosing the answer that is the most consistent among the generated answers.

In more detail, assume the generated answers `latex $\mathbf{a}_i$ ` are from a fixed answer set, `latex $\mathbf{a}_i\in \mathbb{A}$ `, where `latex $i=1, \ldots, m$ ` indexes the `latex $m$ ` candidate outputs sampled from the decoder. Given a prompt and a question, self-consistency introduces an additional latent variable `latex $\mathbf{r}_i$ `, which is a sequence of tokens representing the reasoning path in the `latex $i$ `-th output, then couples the generation of `latex $(\mathbf{r}_i, \mathbf{a}_i)$ ` where `latex $\mathbf{r}_i\rightarrow \mathbf{a}_i$ `, i.e., generating a reasoning path `latex $\mathbf{r}_i$ ` is optional and only used to reach the final answer `latex $\mathbf{a}_i$ `. As an example, consider Output 3 from Figure 1: the first few sentences "_She eats 3 for breakfast ... So she has 9 eggs _ $2 = $18.*" constitutes ```latex $\mathbf{r}_i$ `, while the answer *18* from the last sentence, "*The answer is $18*", is parsed as `latex $\mathbf{a}_i$ `. After sampling multiple `latex $(\mathbf{r}_i, \mathbf{a}_i)$ `from the model's decoder, self-consistency applies a marginalization over`latex $\mathbf{r}_i$ `by taking a majority vote over`latex $\mathbf{a}_i$ `, i.e., `latex $\mathop{\mathrm{arg\,max}}_a\sum\nolimits_{i=1}^m \mathbbm{1} (\mathbf{a}_i = a)$ ```, or as we defined as the most "consistent" answer among the final answer set.

In Table 1, we show the test accuracy over a set of reasoning tasks by using different answer aggregation strategies. In addition to majority vote, one can also weight each `latex $(\mathbf{r}_i, \mathbf{a}_i)$ ` by `latex $P(\mathbf{r}_i, \mathbf{a}_i \mid \text{prompt}, \text{question})$ ` when aggregating the answers. Note to compute `latex $P(\mathbf{r}_i, \mathbf{a}_i \mid \text{prompt}, \text{question})$ `, we can either take the unnormalized probability of the model generating `latex $(\mathbf{r}_i, \mathbf{a}_i)$ ` given `latex $(\text{prompt}, \text{question})$ `, or we can normalize the conditional probability by the output length [brown2020language], i.e.,

```latex
$$P(\mathbf{r}_i, \mathbf{a}_i \mid \text{prompt}, \text{question}) = \exp^{\frac{1}{K}\sum_{k=1}^K {\log P(t_k \mid \text{prompt}, \text{question}, t_1, \ldots, t_{k-1})}}$$
```

where `latex $\log P(t_k \mid \text{prompt}, \text{question}, t_1, \ldots, t_{k-1})$ ` is the log probability of generating the `latex $k$ `-th token `latex $t_k$ ` in `latex $(\mathbf{r}_i, \mathbf{a}_i)$ ` conditioned on the previous tokens, and `latex $K$ ` is the total number of tokens in `latex $(\mathbf{r}_i, \mathbf{a}_i)$ `. In Table 1, we show that taking the "unweighted sum", i.e., taking a majority vote directly over `latex $\mathbf{a}_i$ ` yields a very similar accuracy as aggregating using the "normalized weighted sum". We took a closer look at the model's output probabilities and found this is because for each `latex $(\mathbf{r}_i, \mathbf{a}_i)$ `, the normalized conditional probabilities `latex $P(\mathbf{r}_i, \mathbf{a}_i \mid \text{prompt}, \text{question})$ ` are quite close to each other, i.e., the language model regards those generations as "similarly likely". Additionally, when aggregating the answers, the results in Table 1 show that the "normalized" weighted sum yields a much higher accuracy compared to its unnormalized counterpart. For completeness, in Table 1 we also report the results by taking a "weighted average", i.e., each `latex $a$ ` gets a score of its weighted sum divided by `latex $\sum\nolimits_{i=1}^m \mathbbm{1} (\mathbf{a}_i = a)$ `, which results in a much worse performance.

**Table 1: Accuracy comparison of different answer aggregation strategies on PaLM-540B.**

|                                | GSM8K | MultiArith | AQuA | SVAMP | CSQA | ARC-c |
| ------------------------------ | ----- | ---------- | ---- | ----- | ---- | ----- |
| Greedy decode                  | 56.5  | 94.7       | 35.8 | 79.0  | 79.0 | 85.2  |
| Weighted avg (unnormalized)    | 56.3  | 90.5       | 35.8 | 73.0  | 74.8 | 82.3  |
| Weighted avg (normalized)      | 22.1  | 59.7       | 15.7 | 40.5  | 52.1 | 51.7  |
| Weighted sum (unnormalized)    | 59.9  | 92.2       | 38.2 | 76.2  | 76.2 | 83.5  |
| Weighted sum (normalized)      | 74.1  | 99.3       | 48.0 | 86.8  | 80.7 | 88.7  |
| Unweighted sum (majority vote) | 74.4  | 99.3       | 48.3 | 86.6  | 80.7 | 88.7  |

Self-consistency explores an interesting space between open-ended text generation and optimal text generation with a fixed answer. Reasoning tasks typically have fixed answers, which is why researchers have generally considered greedy decoding approaches [Radford2019LanguageMA; wei2022chain; palm]. However, we have found that even when the desired answer is fixed, introducing diversity in the reasoning processes can be highly beneficial; therefore we leverage sampling, as commonly used for open-ended text generation [Radford2019LanguageMA; brown2020language; thoppilan2022lamda], to achieve this goal. One should note that self-consistency can be applied only to problems where the final answer is from a fixed answer set, but in principle this approach can be extended to open-text generation problems if a good metric of consistency can be defined between multiple generations, e.g., whether two answers agree or contradict each other.

## Experiments

We conducted a series of experiments to compare the proposed self-consistency method with existing approaches on a range of reasoning benchmarks. We find that self-consistency robustly improves reasoning accuracy for every language model considered, spanning a wide range of model scales.

### Experiment setup

#### Tasks and datasets

We evaluate self-consistency on the following reasoning benchmarks.

- **Arithmetic reasoning**. For these tasks, we used the Math Word Problem Repository [koncel-kedziorski-etal-2016-mawps], including AddSub [hosseini-etal-2014-learning], MultiArith [roy-roth-2015-solving], and ASDiv [miao-etal-2020-diverse]. We also included AQUA-RAT [ling-etal-2017-program], a recently published benchmark of grade-school-math problems [GSM8K; cobbe2021training], and a challenge dataset over math word problems [SVAMP; patel-etal-2021-nlp].

- **Commonsense reasoning**. For these tasks, we used CommonsenseQA [talmor-etal-2019-commonsenseqa], StrategyQA [geva-etal-2021-aristotle], and the AI2 Reasoning Challenge (ARC) [Clark2018ThinkYH].

- **Symbolic Reasoning**. We evaluate two symbolic reasoning tasks: last letter concatenation (e.g., the input is "Elon Musk" and the output should be "nk"), and Coinflip (e.g., a coin is heads-up, after a few flips is the coin still heads-up?) from [wei2022chain].

#### Language models and prompts

We evaluate self-consistency over four transformer-based language models with varying scales:

- UL2 [ul2] is an encoder-decoder model trained on a mixture of denoisers with 20-billion parameters. UL2 is completely open-sourced and has similar or better performance than GPT-3 on zero-shot SuperGLUE, with only 20B parameters and thus is more compute-friendly;

- GPT-3 [brown2020language] with 175-billion parameters. We use two public engines _code-davinci-001_ and _code-davinci-002_ from the Codex series [chen2021evaluating] to aid reproducibility;

- LaMDA-137B [thoppilan2022lamda] is a dense left-to-right, decoder-only language model with 137-billion parameters, pre-trained on a mixture of web documents, dialog data and Wikipedia;

- PaLM-540B [palm] is a dense left-to-right, decoder-only language model with 540-billion parameters, pre-trained on a high quality corpus of 780 billion tokens with filtered webpages, books, Wikipedia, news articles, source code, and social media conversations.

We perform all experiments in the few-shot setting, without training or fine-tuning the language models. For a fair comparison we use the same prompts as in Wei et al.: for all arithmetic reasoning tasks we use the same set of 8 manually written exemplars; for each commonsense reasoning task, 4-7 exemplars are randomly chosen from the training set with manually composed chain-of-thought prompts. Full details on the prompts used are given in Appendix.

#### Sampling scheme

To sample diverse reasoning paths, we followed similar settings to those suggested in Radford et al. for open-text generation. In particular, for UL2-20B and LaMDA-137B we applied temperature sampling with T=0.5 and truncated at the top-k (k=40) tokens with the highest probability, for PaLM-540B we applied T=0.7, k=40, and for GPT-3 we use T=0.7 without top-k truncation. We provide an ablation study in Section 3.5 to show that self-consistency is generally robust to sampling strategies and parameters.

### Main Results

We report the results of self-consistency averaged over 10 runs, where we sampled 40 outputs independently from the decoder in each run. The baseline we compare to is chain-of-thought prompting with greedy decoding [wei2022chain], referred to as **CoT-prompting**, which has been previously used for decoding in large language models [palm].

#### Arithmetic Reasoning

The results are shown in Table 2. Self-consistency improves the arithmetic reasoning performance over **all four language models** significantly over chain-of-thought prompting. More surprisingly, the gains become more significant when the language model's scale increases, e.g., we see +3%-6% absolute accuracy improvement over UL2-20B but +9%-23% for LaMDA-137B and GPT-3. For larger models that already achieve high accuracy on most tasks (e.g., GPT-3 and PaLM-540B), self-consistency still contributes significant additional gains with +12%-18% absolute accuracy on tasks like AQuA and GSM8K, and +7%-11% on SVAMP and ASDiv. With self-consistency, we achieve new state-of-the-art results on almost all tasks: despite the fact that self-consistency is unsupervised and task-agnostic, these results compare favorably to existing approaches that require task-specific training, or fine-tuning with thousands of examples (e.g., on GSM8K).

**Table 2: Arithmetic Reasoning Results**

| Model                    | Method           | AddSub       | MultiArith       | ASDiv           | AQuA             | SVAMP            | GSM8K            |
| ------------------------ | ---------------- | ------------ | ---------------- | --------------- | ---------------- | ---------------- | ---------------- |
| -                        | Previous SoTA    | **94.9**     | 60.5             | 75.3            | 37.9             | 57.4             | 35/55            |
| UL2-20B                  | CoT-prompting    | 18.2         | 10.7             | 16.9            | 23.6             | 12.6             | 4.1              |
| UL2-20B                  | Self-consistency | 24.8 (+6.6)  | 15.0 (+4.3)      | 21.5 (+4.6)     | 26.9 (+3.3)      | 19.4 (+6.8)      | 7.3 (+3.2)       |
| LaMDA-137B               | CoT-prompting    | 52.9         | 51.8             | 49.0            | 17.7             | 38.9             | 17.1             |
| LaMDA-137B               | Self-consistency | 63.5 (+10.6) | 75.7 (+23.9)     | 58.2 (+9.2)     | 26.8 (+9.1)      | 53.3 (+14.4)     | 27.7 (+10.6)     |
| PaLM-540B                | CoT-prompting    | 91.9         | 94.7             | 74.0            | 35.8             | 79.0             | 56.5             |
| PaLM-540B                | Self-consistency | 93.7 (+1.8)  | 99.3 (+4.6)      | 81.9 (+7.9)     | 48.3 (+12.5)     | 86.6 (+7.6)      | 74.4 (+17.9)     |
| GPT-3 (code-davinci-001) | CoT-prompting    | 57.2         | 59.5             | 52.7            | 18.9             | 39.8             | 14.6             |
| GPT-3 (code-davinci-001) | Self-consistency | 67.8 (+10.6) | 82.7 (+23.2)     | 61.9 (+9.2)     | 25.6 (+6.7)      | 54.5 (+14.7)     | 23.4 (+8.8)      |
| GPT-3 (code-davinci-002) | CoT-prompting    | 89.4         | 96.2             | 80.1            | 39.8             | 75.8             | 60.1             |
| GPT-3 (code-davinci-002) | Self-consistency | 91.6 (+2.2)  | **100.0** (+3.8) | **87.8** (+7.6) | **52.0** (+12.2) | **86.8** (+11.0) | **78.0** (+17.9) |

#### Commonsense and Symbolic Reasoning

Table 3 shows the results on commonsense and symbolic reasoning tasks. Similarly, self-consistency yields large gains across all four language models, and obtained SoTA results on 5 out of 6 tasks. For symbolic reasoning, we test the out-of-distribution (OOD) setting where the input prompt contains examples of 2-letters or 2-flips but we test examples of 4-letters and 4-flips (this setting is more challenging as PaLM-540B or GPT-3 can already achieve perfect in-distribution accuracy). In this challenging OOD setting, the gain of self-consistency is still quite significant compared to CoT-prompting with sufficient model sizes.

**Table 3: Commonsense and Symbolic Reasoning Results**

| Model                    | Method           | CSQA        | StrategyQA      | ARC-e           | ARC-c           | Letter (4)      | Coinflip (4)    |
| ------------------------ | ---------------- | ----------- | --------------- | --------------- | --------------- | --------------- | --------------- |
| -                        | Previous SoTA    | **91.2**    | 73.9            | 86.4            | 75.0            | N/A             | N/A             |
| UL2-20B                  | CoT-prompting    | 51.4        | 53.3            | 61.6            | 42.9            | 0.0             | 50.4            |
| UL2-20B                  | Self-consistency | 55.7 (+4.3) | 54.9 (+1.6)     | 69.8 (+8.2)     | 49.5 (+6.8)     | 0.0 (+0.0)      | 50.5 (+0.1)     |
| LaMDA-137B               | CoT-prompting    | 57.9        | 65.4            | 75.3            | 55.1            | 8.2             | 72.4            |
| LaMDA-137B               | Self-consistency | 63.1 (+5.2) | 67.8 (+2.4)     | 79.3 (+4.0)     | 59.8 (+4.7)     | 8.2 (+0.0)      | 73.5 (+1.1)     |
| PaLM-540B                | CoT-prompting    | 79.0        | 75.3            | 95.3            | 85.2            | 65.8            | 88.2            |
| PaLM-540B                | Self-consistency | 80.7 (+1.7) | **81.6** (+6.3) | **96.4** (+1.1) | **88.7** (+3.5) | 70.8 (+5.0)     | 91.2 (+3.0)     |
| GPT-3 (code-davinci-001) | CoT-prompting    | 46.6        | 56.7            | 63.1            | 43.1            | 7.8             | 71.4            |
| GPT-3 (code-davinci-001) | Self-consistency | 54.9 (+8.3) | 61.7 (+5.0)     | 72.1 (+9.0)     | 53.7 (+10.6)    | 10.0 (+2.2)     | 75.9 (+4.5)     |
| GPT-3 (code-davinci-002) | CoT-prompting    | 79.0        | 73.4            | 94.0            | 83.6            | 70.4            | 99.0            |
| GPT-3 (code-davinci-002) | Self-consistency | 81.5 (+2.5) | 79.8 (+6.4)     | 96.0 (+2.0)     | 87.5 (+3.9)     | **73.4** (+3.0) | **99.5** (+0.5) |

To show the effect of the number of sampled reasoning paths, we plot the accuracy (mean and standard deviation over 10 runs) with respect to varying numbers of sampled paths (1, 5, 10, 20, 40) in Figure 2. The results show that sampling a higher number (e.g., 40) of reasoning paths leads to a consistently better performance, further emphasizing the importance of introducing diversity in the reasoning paths.

[IMAGE: Figure 2 - Self-consistency (blue) significantly improves accuracy over CoT-prompting with greedy decoding (orange) across arithmetic and commonsense reasoning tasks, over LaMDA-137B. Sampling a higher number of diverse reasoning paths consistently improves reasoning accuracy.]

**Table 4: Example reasoning paths from GSM8K and StrategyQA**

|                    | GSM8K                                                                                                                                                                                                                                                                                                                                     | StrategyQA                                                                                                                                                                                    |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Question**       | _Henry made two stops during his 60-mile bike trip. He first stopped after 20 miles. His second stop was 15 miles before the end of the trip. How many miles did he travel between his first and second stops?_                                                                                                                           | _Yes or no: Is Albany, Georgia the most populous US Albany?_                                                                                                                                  |
| **Greedy Decode**  | He traveled 60 miles in total. He stopped after 20 miles, so he traveled 60 - 20 = 40 miles between the first and second stops. The answer is 40. [INCORRECT]                                                                                                                                                                             | Albany, Georgia is the most populous US Albany. Thus, the answer is yes. [INCORRECT]                                                                                                          |
| **Sampled Path 1** | Henry travelled a total of 60 miles. His first stop was 20 miles in, and his second stop was 15 miles before the end. So between his first and second stops he travelled 60 - 20 - 15 = 25 miles. The answer is 25. [CORRECT]                                                                                                             | The most populous US Albany is Albany, New York. Thus, Albany, Georgia is not the most populous US Albany. So the answer is no. [CORRECT]                                                     |
| **Sampled Path 2** | He made two stops during a 60-mile trip. The first was 20 miles into the trip. The second was 15 miles before the end of the trip. This means the second stop was 60 - 15 = 45 miles into the trip. Since he made the stops in order, the second stop must have been 45 - 20 = 25 miles after the first stop. The answer is 25. [CORRECT] | Albany, Georgia has a population of about 88,000. Albany, New York has a population of about 95,000. Thus, Albany, Georgia is not the most populous US Albany. So the answer is no. [CORRECT] |

### Self-Consistency Helps When Chain-of-Thought Hurts Performance

Ye and Durrett show that sometimes chain-of-thought prompting could hurt performance compared to standard prompting in few-shot in-context learning. Here we perform a study using self-consistency to see if it can help fill in the gap, over a set of common NLP tasks, including (1) Closed-Book Question Answering: BoolQ [clark2019boolq], HotpotQA [yang-etal-2018-hotpotqa], and (2) Natural Language Inference: e-SNLI [esnli], ANLI [nie-etal-2020-adversarial] and RTE [dagan2005pascal; bar2006second; giampiccolo2007third; bentivogli2009fifth].

The results over PaLM-540B are shown in Table 5. For some tasks (e.g., ANLI-R1, e-SNLI, RTE), adding chain-of-thought does hurt performance compared to standard prompting [brown2020language], but self-consistency is able to robustly boost the performance and outperform standard prompting, making it a reliable way to add rationales in few-shot in-context learning for common NLP tasks.

**Table 5: Compare Standard/CoT prompting with self-consistency on common NLP tasks.**

|                                   | ANLI R1 / R2 / R3              | e-SNLI   | RTE      | BoolQ    | HotpotQA (EM/F1) |
| --------------------------------- | ------------------------------ | -------- | -------- | -------- | ---------------- |
| Standard-prompting (no-rationale) | 69.1 / 55.8 / 55.8             | 85.8     | 84.8     | 71.3     | 27.1 / 36.8      |
| CoT-prompting [wei2022chain]      | 68.8 / 58.9 / 60.6             | 81.0     | 79.1     | 74.2     | 28.9 / 39.8      |
| Self-consistency                  | **78.5** / **64.5** / **63.4** | **88.4** | **86.3** | **78.4** | **33.8 / 44.6**  |

### Compare to other existing approaches

We conduct a set of additional studies and show that self-consistency significantly outperforms existing methods including sample-and-rank, beam search, and ensemble-based approaches.

#### Comparison to Sample-and-Rank

One commonly used approach to improve generation quality is sample-and-rank, where multiple sequences are sampled from the decoder and then ranked according to each sequence's log probability [adiwardana2020humanlike]. We compare self-consistency with sample-and-rank on GPT-3 _code-davinci-001_, by sampling the same number of sequences from the decoder as self-consistency and taking the final answer from the top-ranked sequence. The results are shown in Figure 3. While sample-and-rank does improve the accuracy with additionally sampled sequences and ranking, the gain is much smaller compared to self-consistency.

[IMAGE: Figure 3 - Self-consistency significantly outperforms sample-and-rank with the same # of samples.]

#### Comparison to Beam Search

In Table 6, we compare self-consistency with beam search decoding on the UL2-20B model. For a fair comparison we report the accuracy under the same number of beams and reasoning paths. On both tasks self-consistency outperforms beam search significantly. Note self-consistency can also adopt beam search to decode each reasoning path (results are shown as "Self-consistency using beam search"), but its performance is worse compared to self-consistency with sampling. The reason is that beam search yields a lower diversity in the outputs, while in self-consistency the diversity of the reasoning paths is the key to a better performance.

**Table 6: Compare self-consistency with beam search decoding on the UL2-20B model.**

| Task       | Method                             | 1    | 5        | 10       | 20       | 40       |
| ---------- | ---------------------------------- | ---- | -------- | -------- | -------- | -------- |
| AQuA       | Beam search decoding (top beam)    | 23.6 | 19.3     | 16.1     | 15.0     | 10.2     |
| AQuA       | Self-consistency using beam search | 23.6 | 19.8     | 21.2     | 24.6     | 24.2     |
| AQuA       | Self-consistency using sampling    | 19.7 | **24.9** | **25.3** | **26.7** | **26.9** |
| MultiArith | Beam search decoding (top beam)    | 10.7 | 12.0     | 11.3     | 11.0     | 10.5     |
| MultiArith | Self-consistency using beam search | 10.7 | 11.8     | 11.4     | 12.3     | 10.8     |
| MultiArith | Self-consistency using sampling    | 9.5  | 11.3     | **12.3** | **13.7** | **14.7** |

#### Comparison to Ensemble-based Approaches

We further compare self-consistency to ensemble-based methods for few-shot learning. In particular, we consider ensembling by: (1) prompt order permutation: we randomly permute the exemplars in the prompt 40 times to mitigate model's sensitivity to prompt order [pmlr-v139-zhao21c; Lu2021FantasticallyOP]; and (2) multiple sets of prompts [gao-etal-2021-making]: we manually write 3 different sets of prompts. We took majority vote of the answers from greedy decoding in both approaches as an ensemble. Table 7 shows that compared to self-consistency, existing ensemble-based approaches achieve a much smaller gain. In addition, note that self-consistency is different from a typical model-ensemble approach, where _multiple_ models are trained and their outputs are aggregated. Self-consistency acts more like a "self-ensemble" on top of a _single_ language model. We additionally show the results of ensembling multiple models in Appendix where the model-ensembles perform much worse compared to self-consistency.

**Table 7: Self-consistency outperforms prompt-order and multi-prompt ensembles on LaMDA-137B.**

|                                     | GSM8K    | MultiArith | SVAMP    | ARC-e    | ARC-c    |
| ----------------------------------- | -------- | ---------- | -------- | -------- | -------- |
| CoT [wei2022chain]                  | 17.1     | 51.8       | 38.9     | 75.3     | 55.1     |
| Ensemble (3 sets of prompts)        | 18.6     | 57.1       | 42.1     | 76.6     | 57.0     |
| Ensemble (40 prompt permutations)   | 19.2     | 60.9       | 42.7     | 76.9     | 57.0     |
| Self-Consistency (40 sampled paths) | **27.7** | **75.7**   | **53.3** | **79.3** | **59.8** |

### Additional Studies

We conducted a number of additional experiments to analyze different aspects of the self-consistency method, including its robustness to sampling strategies and parameters, and how it works with imperfect prompts and non-natural-language reasoning paths.

#### Self-Consistency is Robust to Sampling Strategies and Scaling

We show self-consistency is robust to sampling strategies and parameters, by varying T in temperature sampling [ACKLEY1985147; ficler-goldberg-2017-controlling], k in top-k sampling [fan-etal-2018-hierarchical; holtzman-etal-2018-learning; Radford2019LanguageMA], and p in nucleus sampling [nucleus_sampling], over PaLM-540B in Figure 4 (left). Figure 4 (right) shows that self-consistency robustly improves performance across all scales for the LaMDA-137B model series. The gain is relatively lower for smaller models due to certain abilities (e.g., arithmetic) only emerge when the model reaches a sufficient scale [brown2020language].

[IMAGE: Figure 4 - GSM8K accuracy. (Left) Self-consistency is robust to various sampling strategies and parameters. (Right) Self-consistency improves performance across language model scales.]

#### Self-Consistency Improves Robustness to Imperfect Prompts

For few-shot learning with manually constructed prompts, human annotators sometimes make minor mistakes when creating the prompts. We further study if self-consistency can help improve a language model's robustness to imperfect prompts. We show the results in Table 8: while imperfect prompts decrease accuracy with greedy decoding (17.1 -> 14.9), self-consistency can fill in the gaps and robustly improve the results.

Additionally, we found that the consistency (in terms of % of decodes agreeing with the final aggregated answer) is highly correlated with accuracy (Figure 5, over GSM8K). This suggests that one can use self-consistency to provide an _uncertainty estimate_ of the model in its generated solutions. In other words, one can use low consistency as an indicator that the model has low confidence; i.e., self-consistency confers some ability for the model to "know when it doesn't know".

**Table 8: Self-consistency works under imperfect prompts, equation prompts and zero-shot chain-of-thought for GSM8K.**

| Model      | Prompt Type                            | Accuracy |
| ---------- | -------------------------------------- | -------- |
| LaMDA-137B | Prompt with correct chain-of-thought   | 17.1     |
| LaMDA-137B | Prompt with imperfect chain-of-thought | 14.9     |
| LaMDA-137B | + Self-consistency (40 paths)          | **23.4** |
| LaMDA-137B | Prompt with equations                  | 5.0      |
| LaMDA-137B | + Self-consistency (40 paths)          | **6.5**  |
| PaLM-540B  | Zero-shot CoT [zero_shot_cot]          | 43.0     |
| PaLM-540B  | + Self-consistency (40 paths)          | **69.2** |

[IMAGE: Figure 5 - Consistency is highly correlated with accuracy on GSM8K.]

#### Self-Consistency Works for Non-Natural-Language Reasoning Paths and Zero-shot CoT

We also tested the generality of the self-consistency concept to alternative forms of intermediate reasoning like equations (e.g., from "_There are 3 cars in the parking lot already. 2 more arrive. Now there are 3 + 2 = 5 cars._" to "_3 + 2 = 5_"). The results are shown in Table 8 ("Prompt with equations"): self-consistency still improves accuracy by generating intermediate equations; however, compared to generating natural language reasoning paths, the gain is smaller since the equations are much shorter and less opportunity remains for generating diversity in the decoding process. In addition, we tested self-consistency with zero-shot chain-of-thought [zero_shot_cot] and show that self-consistency works for zero-shot CoT as well and improves the results significantly (+26.2%) in Table 8.

## Related work

#### Reasoning in language models

Language models are known to struggle in Type 2 tasks, such as arithmetic, logical and commonsense reasoning [evans2010intuition]. Previous work has primarily focused on _specialized_ approaches for improving reasoning [andor-etal-2019-giving; ran-etal-2019-numnet; geva-etal-2020-injecting; piekos-etal-2021-measuring]. Compared to prior work, self-consistency is applicable to a wide range of reasoning tasks without any additional supervision or fine-tuning, while still substantially improving the performance of the chain-of-thought prompting approach proposed in Wei et al.

#### Sampling and re-ranking in language models

Multiple decoding strategies for language models have been proposed in the literature, e.g., temperature sampling [ACKLEY1985147; ficler-goldberg-2017-controlling], top-k sampling [fan-etal-2018-hierarchical; holtzman-etal-2018-learning; Radford2019LanguageMA], nucleus sampling [nucleus_sampling], minimum Bayes risk decoding [eikema-aziz-2020-map; shi-etal-2022-natural], and typical decoding [meister2022typical]. Other work has sought to explicitly promote diversity in the decoding process [Batra2012; DBLP:journals/corr/LiMJ16; diverse_beam].

Re-ranking is another common approach to improve generation quality in language models [adiwardana2020humanlike; shen-etal-2021-generate-rank]. Thoppilan et al. collect additional human annotations to train a re-ranker for response filtering. Cobbe et al. train a "verifier" to re-rank generated solutions, which substantially improves the solve rate on math tasks compared to just fine-tuning the language model. Elazar et al. improve the consistency of factual knowledge extraction by extending pre-training with an additional consistency loss. All these methods require either training an additional re-ranker or collecting additional human annotation, while self-consistency requires no additional training, fine-tuning, nor extra data collection.

#### Extract reasoning paths

Some previous work has considered task-specific approaches for identifying reasoning paths, such as constructing semantic graphs [xu-etal-2021-exploiting-reasoning], learning an RNN to retrieve reasoning paths over the Wikipedia graph [Asai2020Learning], fine-tuning with human annotated reasoning paths on math problems [cobbe2021training], or training an extractor with heuristic-based pseudo reasoning paths [DBLP:journals/corr/abs-1910-02610]. More recently, the importance of diversity in the reasoning processes has been noticed, but only leveraged via task-specific training, either through an additional QA model over extracted reasoning paths [DBLP:journals/corr/abs-1910-02610], or by the introduction of latent variables in a commonsense knowledge graph [yu2022diversifying]. Compared to these approaches, self-consistency is far simpler and requires no additional training. The approach we propose simply couples the generation of reasoning paths and a final answer by sampling from the decoder, using aggregation to recover the most consistent answer without additional modules.

#### Consistency in language models

Some prior work has shown that language models can suffer from inconsistency in conversation [adiwardana2020humanlike], explanation generation [camburu-etal-2020-make], and factual knowledge extraction [elazar-etal-2021-measuring]. Welleck et al. use "consistency" to refer to generating an infinite-length sequence in recurrent language models. Nye et al. improve the logical consistency of samples from a System 1 model by adding a System 2-inspired logical reasoning module. In this paper we focus on a slightly different notion of "consistency", i.e., utilizing answer consistency among diverse reasoning paths to improve accuracy.

## Conclusion and Discussion

We introduced a simple yet effective method called self-consistency, and observed that it significantly improves accuracy in a range of arithmetic and commonsense reasoning tasks, across four large language models with varying scales. Beyond accuracy gains, self-consistency is also useful for collecting rationales when performing reasoning tasks with language models, and for providing uncertainty estimates and improved calibration of language model outputs.

One limitation of self-consistency is that it incurs more computation cost. In practice people can try a small number of paths (e.g., 5 or 10) as a starting point to realize most of the gains while not incurring too much cost, as in most cases the performance saturates quickly (Figure 2). As part of future work, one could use self-consistency to generate better supervised data to fine-tune the model, such that the model can give more accurate predictions in a single inference run after fine-tuning. In addition, we observed that language models can sometimes generate incorrect or nonsensical reasoning paths (e.g., the StrategyQA example in Table 4, the two population numbers are not exactly correct), and further work is needed to better ground models' rationale generations.

## Appendix

### Additional Experiment Results

#### Robustness to Sampling Strategies and Parameters

In Figure 6 we ablate the results with respect to different sampling strategies and parameters by varying T in temperature sampling and k in Top-k sampling, on LaMDA-137B. We show that self-consistency is robust to various sampling strategies and parameters.

[IMAGE: Figure 6 - GSM8K accuracy over LaMDA-137B. Self-consistency works under various sampling strategies and sampling parameters.]

In Figure 7 and Figure 8, we show the results of self-consistency compared with greedy decoding a single path over LaMDA-137B and PaLM-540B, respectively. Self-consistency improves over greedy decode by a quite significant margin on both models, on top of high accuracy already achieved by scaling up model sizes.

[IMAGE: Figure 7 - Self-consistency (blue) significantly improves accuracy across various arithmetic and commonsense reasoning tasks, over LaMDA-137B. Sampling a higher number of diverse reasoning paths consistently improves reasoning accuracy.]

[IMAGE: Figure 8 - Self-consistency (blue) significantly improves accuracy across various arithmetic and commonsense reasoning tasks, over PaLM-540B. Sampling a higher number of diverse reasoning paths consistently helps reasoning accuracy.]

We further show additional sampled reasoning paths from the LaMDA-137B model in Table 9, and sampled reasoning paths from the PaLM-540B model in Table 10. We see that the diversity in the additionally sampled reasoning paths indeed helps the model arrive at a more correct final answer after aggregation.

#### Robustness to different sets of prompts

In Table 11, we further show that self-consistency is quite robust to different sets of input prompts. We manually wrote 3 different sets of chain-of-thought as prompts to the model. Across all sets of prompts, self-consistency yields consistent gains over the original CoT approach.

**Table 11: GSM8K accuracy over PaLM-540B. The results show robustness of self-consistency with respect to different prompts in the input.**

|                    | Prompt set 1 (used in the main text) | Prompt set 2 | Prompt set 3 |
| ------------------ | ------------------------------------ | ------------ | ------------ |
| CoT [wei2022chain] | 56.5                                 | 54.6         | 54.0         |
| Self-consistency   | 74.4 (+17.9)                         | 72.1 (+17.5) | 70.4 (+16.4) |

#### Compared to model ensembles

Additionally, we provide results of directly ensembling the outputs from **multiple language models**. The results are shown in Table 12, by greedily decoding sequences from 3 language models and taking the majority vote (averaged over 10 runs). Note this is a typical ensemble approach (averaging over the predictions over multiple models) and it achieves a performance significantly worse than self-consistency (self-consistency over PaLM-540B gets an accuracy of 74.4%), as lower-capacity models drag down the performance of higher-capacity models. In addition, this approach is limited in two ways: 1) It requires multiple models for an ensemble which might not always be available, while self-consistency only requires one single model to "self-ensemble"; 2) If one of the models is much weaker, it can actually hurt the final performance.

**Table 12: Comparison of GSM8K accuracy over multiple-model ensembles.**

| Type               | Method                                                  | GSM8K accuracy |
| ------------------ | ------------------------------------------------------- | -------------- |
| Single model       | PaLM-540B, greedy / self-consistency                    | 56.5 / 74.4    |
| Ensemble of models | LaMDA-137B + PaLM-540B                                  | 36.9           |
| Ensemble of models | PaLM-540B + GPT-3 (code-davinci-001, 175B)              | 36.6           |
| Ensemble of models | LaMDA-137B + GPT-3 (code-davinci-001, 175B)             | 16.0           |
| Ensemble of models | LaMDA-137B + PaLM-540B + GPT-3 (code-davinci-001, 175B) | 33.3           |

#### Combining self-consistency with other ensembling strategies

Self-consistency is completely compatible with other ensemble strategies, although the gains achieved by self-consistency are significantly higher than other ensemble strategies (and can "override" the performance gains achieved by other ensemble strategies). We further performed experiments and include the results in Table 13 (for a fair comparison, we use 40 sets of prompts, or 40 prompt permutations to compare with self-consistency with 40 paths, all experiments are based on PaLM-540B).

**Table 13: Combining self-consistency with other ensembling strategies.**

| Method                                             | GSM8K accuracy |
| -------------------------------------------------- | -------------- |
| Different sets of prompts (x40)                    | 58.9           |
| Prompt-permutation (x40)                           | 59.6           |
| Self-consistency (x40)                             | 74.4           |
| Self-consistency + different sets of prompts (x40) | 75.4           |
| Self-consistency + prompt-permutation (x40)        | 73.8           |

### Details on Resources and Inference

For all four language models we perform prompting-based inference only. For UL2 we use TPU v3 (2x2 configuration, 4 chips, 8 cores). For GPT-3 models the experiments are done through the public API. For LaMDA-137B we use TPU v3 (8x8 configuration, 64 chips, 128 cores). For PaLM-540B we use TPU v4 (4x4x12 configuration, 192 chips, 384 cores). Most inference jobs take 1 to 4 hours (over about 1,000 examples) for each task on UL2 and LaMDA-137B, and about 2 to 12 hours on PaLM-540B. Some tasks (e.g., commonsense reasoning) take longer but do not exceed 2 days for each task.

For GPT-3 models, we use 128 max tokens for all methods, without frequency penalty or presence penalty. For all models, we take the generated outputs until the start of the next "Q:" to parse the final answers, consistent with our prompting format.

### Full Sets of Prompts

We list the full details of the prompts used for two newly-introduced datasets, AQUA-RAT [ling-etal-2017-program] and AI2 Reasoning Challenge (ARC) [Clark2018ThinkYH], where we manually composed the example chain-of-thought in this paper.

**Table 14: Few-shot exemplars for AQUA-RAT.**

**Q:** John found that the average of 15 numbers is 40. If 10 is added to each number then the mean of the numbers is? Answer Choices: (a) 50 (b) 45 (c) 65 (d) 78 (e) 64
**A:** If 10 is added to each number, then the mean of the numbers also increases by 10. So the new mean would be 50. The answer is (a).

**Q:** If a / b = 3/4 and 8a + 5b = 22, then find the value of a. Answer Choices: (a) 1/2 (b) 3/2 (c) 5/2 (d) 4/2 (e) 7/2
**A:** If a / b = 3/4, then b = 4a / 3. So 8a + 5(4a / 3) = 22. This simplifies to 8a + 20a / 3 = 22, which means 44a / 3 = 22. So a is equal to 3/2. The answer is (b).

**Q:** A person is traveling at 20 km/hr and reached his destiny in 2.5 hr then find the distance? Answer Choices: (a) 53 km (b) 55 km (c) 52 km (d) 60 km (e) 50 km
**A:** The distance that the person traveled would have been 20 km/hr \* 2.5 hrs = 50 km. The answer is (e).

**Q:** How many keystrokes are needed to type the numbers from 1 to 500? Answer Choices: (a) 1156 (b) 1392 (c) 1480 (d) 1562 (e) 1788
**A:** There are 9 one-digit numbers from 1 to 9. There are 90 two-digit numbers from 10 to 99. There are 401 three-digit numbers from 100 to 500. 9 + 90(2) + 401(3) = 1392. The answer is (b).

**Table 15: Few-shot exemplars for ARC easy/challenge.**

**Q:** George wants to warm his hands quickly by rubbing them. Which skin surface will produce the most heat? (a) dry palms. (b) wet palms. (c) palms covered with oil. (d) palms covered with lotion.
**A:** Dry surfaces will more likely cause more friction via rubbing than other smoother surfaces, hence dry palms will produce the most heat. The answer is (a).

**Q:** Which factor will most likely cause a person to develop a fever? (a) a leg muscle relaxing after exercise. (b) a bacterial population in the bloodstream. (c) several viral particles on the skin. (d) carbohydrates being digested in the stomach.
**A:** Option (b), bacterial population is the most likely cause for a person developing fever. The answer is (b).

**Q:** Which change in the state of water particles causes the particles to become arranged in a fixed position? (a) boiling. (b) melting. (c) freezing. (d) evaporating.
**A:** When water is freezed, the particles are arranged in a fixed position; the particles are still moving for all other options. The answer is (c).

**Q:** When a switch is used in an electrical circuit, the switch can (a) cause the charge to build. (b) increase and decrease the voltage. (c) cause the current to change direction. (d) stop and start the flow of current.
**A:** The function of a switch is to start and stop the flow of a current. The answer is (d).

**Table 16: Few-shot exemplars for all arithmetic reasoning tasks.**

**Q:** There are 15 trees in the grove. Grove workers will plant trees in the grove today. After they are done, there will be 21 trees. How many trees did the grove workers plant today?
**A:** We start with 15 trees. Later we have 21 trees. The difference must be the number of trees they planted. So, they must have planted 21 - 15 = 6 trees. The answer is 6.

**Q:** If there are 3 cars in the parking lot and 2 more cars arrive, how many cars are in the parking lot?
**A:** There are 3 cars in the parking lot already. 2 more arrive. Now there are 3 + 2 = 5 cars. The answer is 5.

**Q:** Leah had 32 chocolates and her sister had 42. If they ate 35, how many pieces do they have left in total?
**A:** Leah had 32 chocolates and Leah's sister had 42. That means there were originally 32 + 42 = 74 chocolates. 35 have been eaten. So in total they still have 74 - 35 = 39 chocolates. The answer is 39.

**Q:** Jason had 20 lollipops. He gave Denny some lollipops. Now Jason has 12 lollipops. How many lollipops did Jason give to Denny?
**A:** Jason had 20 lollipops. Since he only has 12 now, he must have given the rest to Denny. The number of lollipops he has given to Denny must have been 20 - 12 = 8 lollipops. The answer is 8.

**Q:** Shawn has five toys. For Christmas, he got two toys each from his mom and dad. How many toys does he have now?
**A:** He has 5 toys. He got 2 from mom, so after that he has 5 + 2 = 7 toys. Then he got 2 more from dad, so in total he has 7 + 2 = 9 toys. The answer is 9.

**Q:** There were nine computers in the server room. Five more computers were installed each day, from monday to thursday. How many computers are now in the server room?
**A:** There are 4 days from monday to thursday. 5 computers were added each day. That means in total 4 \* 5 = 20 computers were added. There were 9 computers in the beginning, so now there are 9 + 20 = 29 computers. The answer is 29.

**Q:** Michael had 58 golf balls. On tuesday, he lost 23 golf balls. On wednesday, he lost 2 more. How many golf balls did he have at the end of wednesday?
**A:** Michael initially had 58 balls. He lost 23 on Tuesday, so after that he has 58 - 23 = 35 balls. On Wednesday he lost 2 more so now he has 35 - 2 = 33 balls. The answer is 33.

**Q:** Olivia has $23. She bought five bagels for $3 each. How much money does she have left?
**A:** She bought 5 bagels for $3 each. This means she spent 5 \* $3 = $15 on the bagels. She had $23 in beginning, so now she has $23 - $15 = $8. The answer is 8.

**Table 17: Few-shot exemplars for HotpotQA (closed-book setting).**

**Q:** Which magazine was started first Arthur's Magazine or First for Women?
**A:** Arthur's Magazine started in 1844. First for Women started in 1989. So Arthur's Magazine was started first. The answer is Arthur's Magazine.

**Q:** The Oberoi family is part of a hotel company that has a head office in what city?
**A:** The Oberoi family is part of the hotel company called The Oberoi Group. The Oberoi Group has its head office in Delhi. The answer is Delhi.

**Q:** What nationality was James Henry Miller's wife?
**A:** James Henry Miller's wife is June Miller. June Miller is an American. The answer is American.

**Q:** The Dutch-Belgian television series that "House of Anubis" was based on first aired in what year?
**A:** "House of Anubis" is based on the Dutch-Belgian television series Het Huis Anubis. Het Huis Anubis is first aired in September 2006. The answer is 2006.

**Table 18: Few-shot exemplars for ANLI.**

Premise: "Conceptually cream skimming has two basic dimensions - product and geography."
Based on this premise, can we conclude the hypothesis "Product and geography are what make cream skimming work." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** Based on "cream skimming has two basic dimensions" we can't infer that these two dimensions are what make cream skimming work. The answer is it is not possible to tell.

Premise: "One of our member will carry out your instructions minutely."
Based on this premise, can we conclude the hypothesis "A member of my team will execute your orders with immense precision." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** "one of" means the same as "a member of", "carry out" means the same as "execute", and "minutely" means the same as "immense precision". The answer is yes.

Premise: "Fun for adults and children."
Based on this premise, can we conclude the hypothesis "Fun for only children." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** "adults and children" contradicts "only children". The answer is no.

Premise: "He turned and smiled at Vrenna."
Based on this premise, can we conclude the hypothesis "He smiled at Vrenna who was walking slowly behind him with her mother." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** the premise does not say anything about "Vrenna was walking". The answer is it is not possible to tell.

Premise: "well you see that on television also"
Based on this premise, can we conclude the hypothesis "You can see that on television, as well." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** "also" and "as well" mean the same thing. The answer is yes.

Premise: "Vrenna and I both fought him and he nearly took us."
Based on this premise, can we conclude the hypothesis "Neither Vrenna nor myself have ever fought him." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** "Vrenna and I both" contradicts "neither Vrenna nor myself". The answer is no.

**Table 19: Few-shot exemplars for e-SNLI (the rationales are crowd-sourced annotations from the original dataset).**

Premise: "A person on a horse jumps over a broken down airplane."
Based on this premise, can we conclude the hypothesis "A person is training his horse for a competition." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** The person is not necessarily training his horse. The answer is it is not possible to tell.

Premise: "A person on a horse jumps over a broken down airplane."
Based on this premise, can we conclude the hypothesis "A person is at a diner, ordering an omelette." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** One jumping horse cannot be in a diner ordering food. The answer is no.

Premise: "A person on a horse jumps over a broken down airplane."
Based on this premise, can we conclude the hypothesis "A person is outdoors, on a horse." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** A broken down airplane is outdoors. The answer is yes.

Premise: "Children smiling and waving at camera."
Based on this premise, can we conclude the hypothesis "They are smiling at their parents." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** Just because they are smiling and waving at a camera does not imply their parents or anyone is anyone behind it. The answer is it is not possible to tell.

Premise: "Children smiling and waving at camera."
Based on this premise, can we conclude the hypothesis "The kids are frowning." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** One cannot be smiling and frowning at the same time. The answer is no.

Premise: "Children smiling and waving at camera."
Based on this premise, can we conclude the hypothesis "There are children present." is true?
OPTIONS: - yes - no - it is not possible to tell
**A:** The children must be present to see them smiling and waving. The answer is yes.

**Table 20: Few-shot exemplars for RTE.**

Premise: "No Weapons of Mass Destruction Found in Iraq Yet."
Based on this premise, can we conclude the hypothesis "Weapons of Mass Destruction Found in Iraq." is true?
**A:** "No Weapons of Mass Destruction Found" contradicts "Weapons of Mass Destruction Found". The answer is no.

Premise: "A place of sorrow, after Pope John Paul II died, became a place of celebration, as Roman Catholic faithful gathered in downtown Chicago to mark the installation of new Pope Benedict XVI."
Based on this premise, can we conclude the hypothesis "Pope Benedict XVI is the new leader of the Roman Catholic Church." is true?
**A:** "installation of new Pope Benedict XVI." means "Pope Benedict XVI is the new leader". The answer is yes.

Premise: "A man is due in court later charged with the murder 26 years ago of a teenager whose case was the first to be featured on BBC One's Crimewatch. Colette Aram, 16, was walking to her boyfriend's house in Keyworth, Nottinghamshire, on 30 October 1983 when she disappeared. Her body was later found in a field close to her home. Paul Stewart Hutchinson, 50, has been charged with murder and is due before Nottingham magistrates later."
Based on this premise, can we conclude the hypothesis "Paul Stewart Hutchinson is accused of having stabbed a girl." is true?
**A:** The premise does not say Paul Stewart Hutchinson "stabbed" this girl. The answer is no.

Premise: "Herceptin was already approved to treat the sickest breast cancer patients, and the company said, Monday, it will discuss with federal regulators the possibility of prescribing the drug for more breast cancer patients."
Based on this premise, can we conclude the hypothesis "Herceptin can be used to treat breast cancer." is true?
**A:** "Herceptin was approved to treat breast cancer" implies that "Herceptin can be used to treat breast cancer". The answer is yes.

**Table 21: Few-shot exemplars for BoolQ (closed-book setting).**

**Q:** does system of a down have 2 singers?
**A:** System of a Down currently consists of Serj Tankian, Daron Malakian, Shavo Odadjian and John Dolmayan. Serj and Daron do vocals, so the band does have two singers. The answer is yes.

**Q:** do iran and afghanistan speak the same language?
**A:** Iran and Afghanistan both speak the Indo-European language Persian. The answer is yes.

**Q:** is a cello and a bass the same thing?
**A:** The cello is played sitting down with the instrument between the knees, whereas the double bass is played standing or sitting on a stool. The answer is no.

**Q:** can you use oyster card at epsom station?
**A:** Epsom railway station serves the town of Epsom in Surrey and is not in the London Oyster card zone. The answer is no.

---

**Footnotes:**

1. The parser is task dependent. For arithmetic reasoning, we parse the first numerical part as the final answer after the model generates "The answer is ". For commonsense reasoning, we parse the full string answer as the final answer after the model generates "The answer is ". Most generated outputs have a consistent format of "{Reasoning paths}. The answer is X." if we prompt the language model in this format.

2. This also means that the language model is not well calibrated and thus cannot distinguish well between correct solutions and wrong solutions, which also explains why additional re-rankers were trained to better judge the quality of the solutions in previous work [cobbe2021training; thoppilan2022lamda].

3. By default we use the test split for all datasets if the labels are available for evaluation. For CommonsenseQA we use the dev split; for StrategyQA we use the question-only set from BIG-bench.

4. Model checkpoints at https://github.com/google-research/google-research/tree/master/ul2.

5. Public API available at https://openai.com/api/.

6. Self-consistency is robust to different sets of prompts and we provide a study in Appendix.

7. The standard deviation of self-consistency is <=0.5 for all tasks and is thus omitted in the table.

8. Self-consistency is compatible with both ensemble approaches and we show the results in Appendix.

9. We use the same prompts as before, but swap all the numbers in the reasoning paths with random numbers except the final answer.

10. https://beta.openai.com/docs/api-reference/making-requests
