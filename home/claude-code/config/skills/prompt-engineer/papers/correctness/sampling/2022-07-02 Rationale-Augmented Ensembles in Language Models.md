# Abstract

Recent research has shown that _rationales_, or step-by-step chains of thought, can be used to improve performance in multi-step reasoning tasks. We reconsider rationale-augmented prompting for few-shot in-context learning, where (input -> output) prompts are expanded to (input, _rationale_ -> output) prompts. For rationale-augmented prompting we demonstrate how existing approaches, which rely on manual prompt engineering, are subject to sub-optimal rationales that may harm performance. To mitigate this brittleness, we propose a unified framework of _rationale-augmented ensembles_, where we identify _rationale sampling_ in the _output_ space as the key component to robustly improve performance. This framework is general and can easily be extended to common natural language processing tasks, even those that do not traditionally leverage intermediate steps, such as question answering, word sense disambiguation, and sentiment analysis. We demonstrate that rationale-augmented ensembles achieve more accurate and interpretable results than existing prompting approaches---including standard prompting without rationales and rationale-based chain-of-thought prompting---while simultaneously improving interpretability of model predictions through the associated rationales.

# Introduction

Recent progress on improving few-shot in-context learning in pretrained large language models has been achieved by expanding prompt exemplars with rationales, delivering successes in a variety of natural language reasoning tasks [wei2022chain; palm; explanation_deepmind; selection_inference; step_by_step; maieutic_prompting]. These prompting-based approaches typically adopt manually-written rationales and therefore rely on the quality of prompt engineering, which usually does not ensure optimal rationales are provided for a given task. Previous work has also shown that "rationales" can be useful for _supervised learning_ in natural language tasks when added in the training data [zaidan-etal-2007-using; ling-etal-2017-program; cobbe2021training; star], but it remains unclear whether such rationales can be reliably useful in few-shot in-context learning [ye2022unreliability].

In this paper, we investigate the role of _rationales_ in few-shot in-context learning by conducting a systematic study over a wide range of NLP tasks. In particular, we seek to answer the following questions: (1) Why do rationales sometimes hurt task performance in few-shot learning? and (2) How can one reliably leverage rationales in few-shot learning for general natural language tasks?

Below we show that, when shifting from the simpler paradigm of (input -> output) prompts to expanded (input, _rationale_ -> output) prompts, there is indeed a large variance in final task performance for few-shot in-context learning. We identify the primary source of sensitivity as the _sub-optimality_ of the rationales used for prompting. To overcome such sub-optimality, we develop a unified framework of **rationale-augmented ensembles**, where the idea is to aggregate over multiple rationales generated from the language model to reduce the brittleness of the results. Ensemble aggregation can be achieved in a few different ways depending on how randomness over the rationales is introduced in the input or the output space, including (1) self-consistency, where existing work [self_consistency] has shown that task performance can be improved by sampling multiple language model outputs for ensembling, (2) prompt-order ensembling, where previous work [Lu2021FantasticallyOP; pmlr-v139-zhao21c] has shown that task performance is sensitive to the order of the exemplars in the prompts, and (3) input-rationale ensembling, where human-written rationales can be replaced by model-generated rationales, leveraging the ability of language models to generate high-quality explanations [wiegreffe2021reframing]. Figure 1 provides an overview of rationale-augmented ensembling approaches.

[IMAGE: Figure 1 - An overview of different ways of composing rationale-augmented ensembles, depending on how the randomness of rationales is introduced. Here q, a, r correspond to question, answer, and rationale, respectively. Rationales are human-written unless specified as model-generated.]

A key finding of this study is that _rationale sampling_ in the _output_ space is a central aspect of rationale-augmented ensembles contributing to their success. That is, regardless of how the input or the prompt vary, task performance is best improved when sufficient diversity is introduced by sampling rationales from the language model's decoder. We also find that rationale-augmented ensembles reliably outperform existing rationale-based few-shot and zero-shot prompting methods [wei2022chain; step_by_step] across a variety of natural language processing tasks. Moreover, in cases where human-written rationales hurt task performance due to the sub-optimality of the rationales, rationale-augmented ensembling is able to fill the gap and reliably outperform standard few-shot prompting [brown2020language] on most tasks.

Perhaps surprisingly, we also find that the proposed framework can be used to improve few-shot learning in common natural language processing tasks, even including tasks where explicit intermediate steps might not be necessary, such as question answering [BoolQ; clark2019boolq], word sense disambiguation [WiC; pilehvar-camacho-collados-2019-wic], sentiment analysis [SST-2; socher-etal-2013-recursive], and paraphrase identification [QQP; WinNT]. We conjecture that, in principle, any natural language processing task can be usefully augmented with "rationales" that represent the thought processes needed to achieve accurate and interpretable results in few-shot in-context learning.

Existing work on interpretability usually focuses on improving the explanation of model predictions via supervised learning, which requires large amounts of human labeled explanations to be collected [zaidan-etal-2007-using; esnli; rajani-etal-2019-explain; wt5], while remaining agnostic to improving final task performance. In contrast, we show that the framework proposed in this paper can leverage very few human-written rationales (as `latex $K$ `-shot exemplars where `latex $K$ ` is usually very small, e.g., 3 to 6) and still generate ensembles that can improve task performance significantly. The proposed framework does not require additional fine-tuning [thoppilan2022lamda; star], verifiers [cobbe2021training], calibrators [ye2022unreliability], or any use of an auxiliary dataset [star; better_reasoner], making it applicable to any off-the-shelf large language model. As a general approach to obtaining more accurate and more interpretable natural language understanding, rationale-augmented ensembles also provide more accurate assessments of the performance gains contributed by rationales in few-shot in-context learning.

# Rationale-Augmented Ensembles in Language Models

We investigate the role of rationales in few-shot in-context learning, first interrogating the sensitivity of final performance to rationale quality, then developing a unified perspective on rationale-augmented ensembles that seek to reduce sensitivity and improve final performance.

## Optimality of the rationales in few-shot learning

Given that rationale-augmented prompting has been shown to exhibit variable performance [wei2022chain; ye2022unreliability], we first investigate the sensitivity of task performance to rationale quality across a range of natural language tasks, including e-SNLI [esnli], BoolQ [clark2019boolq], WiC [pilehvar-camacho-collados-2019-wic], and SST-2 [socher-etal-2013-recursive], finding that human-generated rationales can indeed be sub-optimal.

For each task, we choose `latex $K$ ` (4 to 6) exemplars from the training set, manually produce a set of rationales for each exemplar, then use these as seeds to generate additional rationales from the language model: we leave one question from the exemplars out, and use the rest of the exemplars with human-written rationales as prompts, then we can sample from the language model's decoder to obtain a large number of generated rationales for this question. (Specifically, we sample 1,024 rationales for each exemplar and only keep those where the final answer is consistent with the ground truth answer.) Each new prompt is then composed as follows: for each of the `latex $K$ ` exemplars, we replace its human-written rationale with a random sample from the generated rationales, while keeping the rationales of the other `latex $K-1$ ` exemplars fixed. We repeat this for every exemplar and report the final task performance using the new prompts in Figure 2 (denoted as sampled-r-`latex $k$ ` if the `latex $k$ `-th rationale is replaced).

[IMAGE: Figure 2 - The performance varies depending on which rationales are used in the prompts for few-shot in-context learning. The exemplars in the prompts are exactly the same, only the rationales differ. The performance is evaluated with accuracy on the greedy decoded output using PaLM-540B.]

First, one can observe that compared with standard few-shot prompting ("no-rationale"), the addition of human-written rationales does not always yield better performances. Moreover, the performance induced by sampled-rationales exhibits substantial variance, implying that the quality of the rationales in the prompts has a significant effect on final performance. Often the sampled rationales exhibit better performance than the human-written ones, indicating that manually provided rationales can be far from "optimal" in terms of task performance. Table 1 shows examples of human-written rationales and two model-generated rationales for the same question, demonstrating that the model is able to generate diverse but reasonable rationales using its pre-trained knowledge.

**Table 1: Examples of human-written rationale and model-generated rationales from PaLM-540B, representing multiple ways to reason about the same question.**

| Task   | Question                                                                                                                                  | Human-written rationale                                                                             | Model-generated rationales                                                                                                                                          |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| e-SNLI | Premise: "Children smiling and waving at camera." Based on this premise, can we conclude the hypothesis "The kids are frowning." is true? | One cannot be smiling and frowning at the same time.                                                | "Smiling and waving is not frowning." / "'Smiling' and 'frowning' are opposites."                                                                                   |
| BoolQ  | can you use oyster card at epsom station?                                                                                                 | Epsom railway station serves the town of Epsom in Surrey and is not in the London Oyster card zone. | "Epsom Station is not currently a part of the Oyster Card Network." / "'Oyster card' is a pre-pay card for public transport in London. Epsom Station is in Surrey." |
| WiC    | Approach a task. To approach the city. Q: Is the word "approach" used in the same way in the two sentences above?                         | The first "approach" means "deal with", the second "approach" means "come near".                    | "1) To tackle or deal with a task. 2) To come near." / "'To approach the city' means 'to get close to the city'. 'Approach a task' means 'to deal with a task'."    |
| QQP    | Is the following question "What can one do after MBBS?" the same as "What do i do after my MBBS?"                                         | Both are asking what can a person do after MBBS.                                                    | "'One' means the same as 'I'." / "'What can one do' and 'what do I do' mean the same thing in the context of the question."                                         |
| SST-2  | What is the sentiment of the following sentence? "contains no wit, only labored gags"                                                     | "contains no wit" is clearly a negative sentiment.                                                  | "'no wit' and 'labored gags' both mean negative sentiments." / "'no wit' indicates something negative and 'only labored gags' is also negative."                    |

### Simply including a rationale does not always improve task performance

From Figure 2 one can also see that, due to the sub-optimality of the rationales used, task performance can degrade when rationales are added to prompts in few-shot in-context learning. For example, on e-SNLI, WiC and SST-2, the performance achieved by written-rationales is significantly worse than standard few-shot prompting without rationales, consistent with the findings in [ye2022unreliability].

## Rationale-augmented ensembles

Given that determining "optimal" rationales for few-shot in-context learning is difficult (a line of existing work uses a train/validation set to determine the optimal prompts, either discrete or continuous, e.g., [lester-etal-2021-power; gao-etal-2021-making]. Such a setting is closer to fine-tuning rather than few-shot learning, due to the use of an additional dataset for performance validation), it is natural to consider the use of **rationale-augmented ensembles** that can automatically aggregate across diverse rationales to overcome the brittleness of performance to sub-optimal human-written rationales.

**Table 2: Methods for generating rationale-augmented ensembles in language models.**

| Rationale-augmented ensembles                                    | Input/Prompt | Output         |
| ---------------------------------------------------------------- | ------------ | -------------- |
| Self-consistency [self_consistency]                              | fixed        | sampled        |
| Prompt-order ensemble [Lu2021FantasticallyOP; pmlr-v139-zhao21c] | shuffled     | greedy/sampled |
| Input-rationale ensemble, adapted from [wiegreffe2021reframing]  | sampled      | greedy/sampled |

We define a rationale-augmented ensemble as introducing an additional latent variable (the "rationales") that can be sampled and ultimately marginalized out (see Figure 1 for examples). Depending on the stage where the sampling occurs, the approaches to rationale ensembling can be categorized as follows (summarized in Table 2):

- Self-consistency [self_consistency], where the input/prompt is fixed, and multiple rationales are sampled from the language model's decoder.

- Prompt-order ensemble: Given that task performance has been observed to be sensitive to prompt ordering [Lu2021FantasticallyOP; pmlr-v139-zhao21c], the order of exemplars in prompts can be permuted to elicit multiple rationales in the decoder.

- Input-rationale ensemble: Leveraging the ability of large language models to generate high-quality explanations [wiegreffe2021reframing], model-generated rationales can replace human-written rationales in the input prompts (e.g., via the process described in Section 2.1), which can then be used to elicit multiple rationales in the decoder.

For each of these ensembling approaches, the model couples the generation of rationales and answers before taking a majority vote (more precisely, a plurality vote) to produce the final ensemble answer. For both prompt-order ensembling and input-rationale ensembling, since the randomness is introduced in the _input_ space, one can either decode an output greedily with a rationale, or sample an output with a rationale in the _output_ space for each new prompt. Interestingly, below we find that _rationale sampling_ in the _output_ space is the most important component in the overall rationale-augmented ensemble framework. In particular, regardless of how the input/prompt varies, sampling in the output space is the key to achieving better task performance across a variety of natural language processing tasks. With this key component, we find that rationale-ensembling can significantly improve results over both standard prompting [brown2020language] and rationale-based prompting [wei2022chain; step_by_step] on common NLP tasks; the framework also provides rationales at no additional cost that can be used to better interpret model predictions.

# Experiments

We conducted a series of experiments to compare the performance of rationale-augmented ensembles against existing approaches, across a variety of natural language processing tasks. Overall, the results demonstrate that rationale-augmented ensembles can robustly improve task performance across alternative language models and model scales.

## Experiment setup

### Tasks and datasets

We considered a set of natural language tasks from GLUE [wang-etal-2018-glue], SuperGLUE [superglue], and other natural language processing benchmarks. These tasks can be categorized as follows (we use the test split for all tasks if the test split is available and has labels for evaluation, otherwise we use the dev split. Specifically, test split: ANLI, e-SNLI, OpenBookQA, ARC; dev/validation split: MNLI, RTE, BoolQ, Hotpot-QA, WiC, SST-2, QQP. In addition, some of the datasets are too large to run large language models on, so we used the first 1,000 data points for HotpotQA, e-SNLI, MNLI, and QQP for evaluation.):

- **Question Answering**: For question answering, we include BoolQ [clark2019boolq], HotpotQA [yang-etal-2018-hotpotqa], and OpenBookQA [openbookqa].

- **Natural Language Inference**: For these tasks, we include ANLI [nie-etal-2020-adversarial] with the three subsets (R1, R2, R3), e-SNLI [esnli], MNLI (matched/mis-matched) [mnli], and RTE [dagan2005pascal; bar2006second; giampiccolo2007third; bentivogli2009fifth].

- **Word Sense Disambiguation**: Here we use Word-in-Context [WiC; pilehvar-camacho-collados-2019-wic].

- **Sentiment Analysis**: we use the Stanford Sentiment Treebank v2 [SST-2; socher-etal-2013-recursive].

- **Paraphrase Identification**: Here we use Quora Question Pairs [QQP; WinNT].

- **Reasoning**. For reasoning tasks, we consider the AI2 Reasoning Challenge (ARC) [Clark2018ThinkYH] for open-domain question answering with commonsense reasoning, as well as the grade-school math problems [GSM8K; cobbe2021training] for arithmetic reasoning.

### Language models and prompts

To investigate whether rationale-augmented ensembles can robustly improve performance across language models, we evaluated the framework with two dense left-to-right, decoder-only transformer language models with varying scale: (1) PaLM-540B, a language model with 540-billion parameters [palm] and (2) the public GPT-3 model with 175-billion parameters [brown2020language; instructGPT].

All experiments are conducted in the few-shot setting except the zero-shot CoT baseline [step_by_step], without any fine-tuning. For each task, we randomly choose `latex $K$ ` examples from the training set as `latex $K$ `-shot prompts, while maintaining a balanced label distribution and manually providing a set of rationales as the initial prompts. We use the exact same exemplars in the few-shot prompts for all baselines and rationale-augmented ensembles. For standard few-shot prompting we omit the rationales.

### Parameter settings

Across all tasks, each rationale-augmented ensemble is generated by ensembling `latex $m=40$ ` outputs from the language model. For sampling in the language model, we use temperature sampling [ACKLEY1985147; ficler-goldberg-2017-controlling] with temperature `latex $T=0.7$ `. The maximum number of decoded steps is set to 128 in every case, except for GSM8K where we use 256 to accommodate longer rationales needed to express extended reasoning chains.

## Results

The results for the PaLM-540B model are shown in Table 3, Table 4 and Table 6, and give a comparison to two baseline approaches: (1) standard few-shot prompting without rationales [brown2020language], and (2) rationale-based prompting, including few-shot chain-of-thought (CoT) prompting [wei2022chain], and zero-shot CoT [step_by_step] where the model is prompted with "Let's think step by step" to generate initial rationales then prompted with "Therefore, the answer is" to obtain the final answer. (We have found the zero-shot CoT approach yields slightly less controlled responses compared to few-shot based approaches, i.e., the model is less likely to generate a desired fixed answer like "yes/no", "(a)-(e)" even when we add guided prompts like "The answer (yes or no) is", "among options (a) through (e)".)

For each of the rationale-augmented ensembles, we specify the inputs as "fixed", "shuffled" (for prompt-order ensemble), or "sampled" (for input-rationale ensemble); and the outputs as "greedy" or "sampled" depending on whether we decode the outputs greedily or sample the outputs from the language model's decoder. Based on the results shown in the tables, a few key observations follow:

- For each rationale-augmented ensemble strategy, the "output-sampled" version yields better final performance than the "output-greedy" version for almost every task. This remains true regardless of whether randomness is introduced in the input space (i.e., whether the exemplars are shuffled in a prompt-order ensemble, or whether rationales in the exemplars are sampled in an input-rationale ensemble). Although self-consistency has an "output-sampled" only version, given that the input/prompt is fixed, it also achieves comparable performance to the "output-sampled" versions of the other ensembling approaches. These findings indicate that _rationale sampling_ in the _output_ space is the critical component for improving task performance, more so than the specific ensembling method used.

- The "output-sampled" version of each rationale-ensembling method almost always improves performance over standard prompting [brown2020language] without rationales, as well as rationale-based few-shot and zero-shot prompting [wei2022chain; step_by_step]. There are a few exceptions, including MNLI-m/mm, SST-2, and QQP, from GLUE [wang-etal-2018-glue], where standard-prompting still exhibits the best performance. We conjecture that the questions and answers in these tasks already appear frequently in the pre-training corpus, which allows simple memorization to perform well, whereas forcing the model to additionally provide rationales slightly degrades performance.

- Simply adding rationales as in [wei2022chain; step_by_step] can sometimes degrade task performance compared to standard prompting (also observed in [ye2022unreliability]), but rationale-augmented ensembling reliably boosts performance beyond both rationale-based and standard prompting in most tasks. This finding suggests that rationale-augmented ensembles provide a reliable approach to improving the final task performance of **rationale-based few-shot in-context learning**. Interpretability of model predictions is also enhanced by the presence of generated rationales in the model outputs.

**Table 3: Performance comparison over natural language inference tasks, on PaLM-540B.**

| Method                              | Input    | Output  | ANLI R1 / R2 / R3              | e-SNLI   | RTE      | MNLI-m/mm           |
| ----------------------------------- | -------- | ------- | ------------------------------ | -------- | -------- | ------------------- |
| Zero-shot CoT [step_by_step]        | fixed    | greedy  | 49.7 / 45.1 / 44.8             | 70.4     | 72.2     | 60.0 / 62.2         |
| Standard-prompting (no-rationale)   | fixed    | greedy  | 69.1 / 55.8 / 55.8             | 85.8     | 84.8     | **82.7** / **81.5** |
| CoT-prompting [wei2022chain]        | fixed    | greedy  | 68.8 / 58.9 / 60.6             | 81.0     | 79.1     | 72.0 / 74.0         |
| Prompt-order ensemble               | shuffled | greedy  | 72.0 / 60.7 / 61.3             | 84.2     | 78.0     | 74.5 / 75.7         |
| Prompt-order ensemble               | shuffled | sampled | **78.7** / **64.9** / **66.0** | **89.0** | **84.8** | 80.3 / 81.2         |
| Input-rationale ensemble            | sampled  | greedy  | 70.1 / 60.1 / 61.1             | 87.1     | 79.1     | 73.4 / 75.9         |
| Input-rationale ensemble            | sampled  | sampled | **78.3** / **64.5** / **64.3** | **88.8** | **85.2** | 78.8 / 81.0         |
| Self-consistency [self_consistency] | fixed    | sampled | **78.5** / **64.5** / **63.4** | **88.4** | **86.3** | 79.5 / 80.5         |

We explain these experiments in more detail. Table 3 shows the results obtained across a range of natural language inference tasks. One can see that the three rationale-augmented ensembling strategies ("output-sampled") all achieve significantly higher accuracy than chain-of-thought prompting with human-written rationales [wei2022chain]. On e-SNLI, RTE, and MNLI, the chain-of-thought approach produces worse performance than standard prompting, while rationale-augmented ensembling is able to boost the performance significantly, outperforming chain-of-thought prompting in every case, and outperforming standard prompting in all cases except MNLI.

**Table 4: Performance comparison over question answering tasks on PaLM-540B.**

| Method                              | Input    | Output  | BoolQ (q only) | BoolQ (w/ passage) | HotpotQA (q only, EM/F1) | OpenBookQA (q only) |
| ----------------------------------- | -------- | ------- | -------------- | ------------------ | ------------------------ | ------------------- |
| Zero-shot CoT [step_by_step]        | fixed    | greedy  | 55.4           | 71.7               | 17.1 / 23.0              | 67.6                |
| Standard-prompting (no-rationale)   | fixed    | greedy  | 71.3           | 89.7               | 27.1 / 36.8              | 84.4                |
| CoT-prompting [wei2022chain]        | fixed    | greedy  | 74.2           | 85.4               | 28.9 / 39.8              | 86.4                |
| Prompt-order ensemble               | shuffled | greedy  | 73.3           | 87.4               | 30.3 / 41.3              | 87.6                |
| Prompt-order ensemble               | shuffled | sampled | **78.0**       | **91.0**           | **34.7** / **45.4**      | **91.0**            |
| Input-rationale ensemble            | sampled  | greedy  | 75.0           | 86.5               | 30.9 / 41.7              | 87.4                |
| Input-rationale ensemble            | sampled  | sampled | **78.6**       | **90.9**           | **32.4 / 43.7**          | **90.0**            |
| Self-consistency [self_consistency] | fixed    | sampled | **78.4**       | **90.6**           | **33.8 / 44.6**          | **90.0**            |

Similarly, Table 4 shows the results obtained in four question answering tasks. For BoolQ, we conducted an evaluation in both the closed-book setting (the model is given a question only, without providing a relevant passage), as well as the setting where both the question and a relevant passage are provided. In both settings, rationale-augmented ensembling ("output-sampled") outperforms standard and chain-of-thought prompting. For HotpotQA, we conducted the evaluation in the closed-book setting, where rationale-augmented ensembling achieves a higher EM and F1 score compared to both baselines. An important question for open-domain question answering in the closed-book setting is how to utilize a language model to retrieve relevant knowledge and compose the final answer [roberts-etal-2020-much]. Our results show that rationale-augmented ensembling is an effective technique for encouraging a language model to retrieve _multiple_ relevant facts for a given question. To illustrate this phenomenon, Table 5 demonstrates some of the retrieved facts used to yield final answers.

**Table 5: Examples of how the language model retrieves multiple relevant facts and composes rationales for open-domain question-answering in the closed-book setting.**

| Task / Question                                                                                                                               | Golden passage                                                                                                                                                                                                                         | Retrieved facts and composed rationales (closed-book)                                                                                                                                                                                                                                                                                                                                                          |
| --------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [BoolQ] can u drive in canada with us license (answer: yes)                                                                                   | Persons driving into Canada must have their vehicle's registration document and proof of insurance.                                                                                                                                    | "Yes, you can drive in Canada with a U.S. licence. You need to have a signed letter from your car rental company." / "49 U.S. states and 6 Canadian provinces have a reciprocal agreement for the recognition of driver licensing. As long as you have a valid U.S. driver's license, you may drive in Canada. The answer is yes."                                                                             |
| [HotpotQA] What government position was held by the woman who portrayed Corliss Archer in the film Kiss and Tell? (answer: Chief of Protocol) | Kiss and Tell is... starring then 17-year-old Shirley Temple as Corliss Archer. / Shirley Temple Black... was named United States ambassador to Ghana and to Czechoslovakia and also served as Chief of Protocol of the United States. | "Shirley Temple Black played Corliss Archer in Kiss and Tell. Black was the United States Ambassador to Ghana and Czechoslovakia. The answer is Ambassador." / "Corliss Archer was a fictional character. Actress Shirley Temple portrayed Corliss Archer in the film Kiss and Tell. In 1967, Shirley Temple became the first female Chief of Protocol in the United States. The answer is Chief of Protocol." |

**Table 6: Performance comparison over other common NLP tasks, on PaLM-540B.**

| Method                              | Input    | Output  | WiC             | SST-2    | QQP      | ARC-e    | ARC-c    | GSM8K    |
| ----------------------------------- | -------- | ------- | --------------- | -------- | -------- | -------- | -------- | -------- |
| Zero-shot CoT [step_by_step]        | fixed    | greedy  | 54.1            | 76.8     | 55.8     | 87.0     | 79.6     | 43.0     |
| Standard-prompting (no-rationale)   | fixed    | greedy  | 67.6            | **94.6** | **84.1** | 95.9     | 87.1     | 17.9     |
| CoT-prompting [wei2022chain]        | fixed    | greedy  | 65.2            | 87.8     | 75.6     | 95.3     | 85.2     | 56.5     |
| Prompt-order ensemble               | shuffled | greedy  | 62.1            | 88.1     | 76.6     | 94.5     | 85.6     | 59.6     |
| Prompt-order ensemble               | shuffled | sampled | 62.5            | 91.2     | 80.9     | **96.4** | **88.5** | **75.4** |
| Input-rationale ensemble            | sampled  | greedy  | 66.5 / **72.1** | 92.3     | 76.6     | 95.5     | 86.6     | 58.9     |
| Input-rationale ensemble            | sampled  | sampled | 65.2 / **70.8** | 93.1     | 81.2     | **96.7** | **88.6** | **73.8** |
| Self-consistency [self_consistency] | fixed    | sampled | 66.9            | 91.1     | 78.9     | **96.4** | **88.7** | **74.4** |

Finally, Table 6 provides results for other common natural language processing tasks. Interestingly, for tasks that do not require explicit intermediate steps, such as SST-2 and QQP, adding manual rationales to prompts can degrade performance significantly. Yet, in these cases, rationale-augmented ensembles ("output-sampled") are able to significantly close the gap. For WiC, ARC-easy/challenge and GSM8K, rationale-augmented ensembling outperforms both standard and chain-of-thought prompting by a large margin. Here, for WiC, we evaluated an alternative variant of the input-rationale ensemble: instead of replacing one rationale in each prompt, we replace every original rationales by a generated one in each prompt. This variant generally yields similar or slightly worse performance compared to replacing one rationale at a time, but on the WiC task we observed a performance improvement (70.8% versus 65.2% when only one rationale is replaced), which indicates that this task might require greater rationale diversity to support strong task performance.

## Results on GPT-3

To control for the effects of the language model and aid reproducibility, we repeat the above studies with the publicly available GPT-3 model [brown2020language; instructGPT]. Once again, we find similar outcomes where rationale-augmented ensembling robustly improves performance across natural language tasks. Here we use the code-davinci-002 engine [chen2021evaluating], which has been observed to yield slightly better performance than text-davinci-002. The results of this study are given in Table 7, showing that rationale-augmented ensembles with GPT-3 obtain similar improvements to those obtained with PaLM-540B above. Once again, human-written rationales in few-shot learning can sometimes degrade performance compared to standard prompting (e.g., on RTE, OpenBookQA, WiC, ARC-challenge), while rationale-augmented ensembling with sampling in the output space ("output-sampled") reliably improves performance over both baselines. Similarly, for WiC, introducing greater diversity in sampled rationales improves performance (67.6%) compared to sampling a single rationale for each prompt (57.4%). These results reinforce the finding that the improvements are robust to the specific language model, provided it is of sufficient size/quality.

**Table 7: Performance comparison on GPT-3 (code-davinci-002 engine).**

| Method                              | Input    | Output  | RTE      | BoolQ    | OpenBookQA | WiC             | ARC-c    |
| ----------------------------------- | -------- | ------- | -------- | -------- | ---------- | --------------- | -------- |
| Standard-prompting (no-rationale)   | fixed    | greedy  | 85.2     | 69.9     | 81.4       | 65.5            | 85.9     |
| CoT-prompting [wei2022chain]        | fixed    | greedy  | 84.1     | 73.5     | 80.4       | 55.5            | 83.6     |
| Prompt-order ensemble               | shuffled | greedy  | 83.0     | 74.2     | 83.4       | 56.4            | 84.0     |
| Prompt-order ensemble               | shuffled | sampled | **88.8** | **78.5** | **87.8**   | 56.7            | **88.2** |
| Input-rationale ensemble            | sampled  | greedy  | 85.2     | 75.0     | 85.4       | 57.1 / **68.0** | 84.7     |
| Input-rationale ensemble            | sampled  | sampled | **87.4** | **78.4** | **87.0**   | 57.4 / **67.6** | **87.6** |
| Self-consistency [self_consistency] | fixed    | sampled | 85.6     | **78.2** | **88.4**   | 55.6            | **87.5** |

## Additional Studies

### Effect of K in K-shot in-context learning

In Table 8, we provide an ablation study that examines the effect of choosing different `latex $K$ ` in `latex $K$ `-shot in-context learning. While increasing the number of exemplars `latex $K$ ` generally improves performance, rationale-augmented ensembling robustly improves performance over standard and chain-of-thought prompting for all values of `latex $K$ `.

**Table 8: Performance comparison on ANLI-R1 using PaLM-540B, with (1) varying K (3, 6, 9) in K-shot learning; and (2) using different templates/verbalizers (T-1, T-2, T-3), fixing K=6.**

| Method                              | Input    | Output  | 3-shot | 6-shot/T-1 | 9-shot | T-2  | T-3  |
| ----------------------------------- | -------- | ------- | ------ | ---------- | ------ | ---- | ---- |
| Standard-prompting (no-rationale)   | fixed    | greedy  | 67.9   | 69.1       | 69.3   | 66.1 | 66.4 |
| CoT-prompting [wei2022chain]        | fixed    | greedy  | 71.6   | 68.8       | 72.2   | 67.9 | 68.3 |
| Prompt-order ensemble               | shuffled | sampled | 76.0   | 78.7       | 80.1   | 78.4 | 75.6 |
| Input-rationale ensemble            | sampled  | sampled | 76.1   | 78.3       | 78.4   | 77.8 | 76.0 |
| Self-consistency [self_consistency] | fixed    | sampled | 77.9   | 78.5       | 78.7   | 76.6 | 76.9 |

### Effect of templates and verbalizers

We also investigate whether rationale-augmented ensembling is robust to different templates or verbalizers, since previous work has shown that templates or verbalizers can have a significant effect on final performance [bach2022promptsource]. Here we choose three alternative templates from PromptSource (https://github.com/bigscience-workshop/promptsource) for the NLI task, as follows:

- Template-1: _Premise: {premise}" Based on this premise, can we conclude the hypothesis "{hypothesis}" ... is true? options_

- Template-2: _"{premise}" Does it follow that "{hypothesis}"? options_

- Template-3: _Suppose "{premise}" Can we infer that "{hypothesis}"? options_

The results in Table 8 reveal that, although different templates can induce variable performance, rationale-augmented ensembling outperforms standard and chain-of-thought prompting under all three templates.

### Effect of using existing explanations vs newly-written ones in the prompts

To control for the bias of manually written rationales, we also investigate performance on the e-SNLI dataset using crowd-sourced rationales [esnli]. As shown in Table 3, the improvement of rationale-augmented ensemble appears to be stable regardless of whether the rationales are crowd-sourced or author-supplied.

Note that in this paper, we focus on the role of "rationales", and conduct the studies in a manner that fixes other factors that might affect task performance. Due to the large performance variance across alternative set-ups, it is clear that a rigorous evaluation of few-shot in-context learning requires the specification of all these factors, including (1) the exact prompts used, including the specific exemplars, templates/verbalizers, instructions, or rationales/explanations used; and (2) the exact prompt order and the number of exemplars `latex $K$ ` used.

# Related work

### Rationalization and interpretability in NLP

One relevant line of work tries to improve rationalization and interpretability in natural language processing models, for example, by extracting rationales using task-specific approaches [xu-etal-2021-exploiting-reasoning; Asai2020Learning; DBLP:journals/corr/abs-1910-02610]. In the supervised learning setting, one typically fine-tunes a model using human-annotated rationales as training data [zaidan-etal-2007-using; ling-etal-2017-program; wt5; cobbe2021training]. [star] propose to use prompting to augment a training dataset with rationales, then fine-tune a language model using this dataset to further improve reasoning ability. [better_reasoner] propose to sample "diverse" prompts from the training set augmented by rationales, plus an additional voting verifier to improve model performance on reasoning tasks. However, the use of an additional training set is closer to the fine-tuning setting rather than the few-shot setting. Compared to these approaches, rationale-augmented ensembles focus more on the few-shot setting, where there is no additional training or fine-tuning, hence no human annotation nor training/development datasets are required.

Recent work has also considered _prompting_ language models with human-written rationales to further improve performance, such as [wei2022chain; step_by_step; self_consistency; maieutic_prompting]. [explanation_deepmind] show that hand-tuned explanations can improve task performance substantially. By contrast, rationale-augmented ensembling requires no hand-tuning on rationales. Instead, we leverage the language model to automatically sample rationales to overcome the sub-optimality of manually provided rationales.

### Prompt optimization and ensembles in language models

Previous work has shown that the prompt order [Lu2021FantasticallyOP], how each task is verbalized [bach2022promptsource], and the distribution of labels in the prompts [pmlr-v139-zhao21c] can all affect final task performance. In this paper, we find that, when shifting from the paradigm of (input -> output) pairs to (input, _rationale_ -> output) pairs, there is also a large variance in the final task performance when the _rationales_ used in the prompts differ. Recent work has also proposed ways to further improve a model's reasoning ability under specific constraints. For example, when the final label is binary, [maieutic_prompting] induce a tree of explanations, then use an SAT solver and an NLI verifier to infer the satisfiability of each explanation. For commonsense reasoning tasks, [liu-etal-2022-generated] generate relevant knowledge as additional inputs to the model, to improve the performance. Another line of work proposes to better retrieve prompts closer to the target question to further improve task performance [liu-etal-2022-makes; learning_to_retrieve].

### Learn to execute programs with intermediate computations

Although much of the work on rationales has come from the natural language processing literature, there has been growing interest in similar mechanisms in the area of program synthesis. [scratchpad] use pretrained language models to execute a program by predicting the intermediate states of a program behaviour line-by-line. This work shows that eliciting step-by-step reasoning described by a formal language can dramatically improve the execution prediction accuracy. Other recent work [pi2022reasoning] pre-trains language models as program executors and shows that this can improve reasoning task performance.

# Conclusion

In this paper, we have presented a unified framework for rationale-augmented ensembles, and found that rationale sampling in the output space is a key component for achieving improved performance in natural language processing tasks. By sampling diverse rationales and ensembling the results, we have shown that rational-ensembling methods in the proposed framework can reliably outperform standard prompting and rationale-based few-shot prompting, across a wide range of natural language tasks and alternative language models. Overall, rationale-augmented ensembling appears to be a reliable way to shift from the paradigm of (input -> output) pairs to (input, _rationale_ -> output) pairs to achieve more accurate and interpretable natural language processing.

Although the proposed framework mitigates sensitivity to human-written rationales, some human-written seed rationales are still required, which could still bias generation of output rationales. We have observed that patterns expressed in the written rationales can affect a model's generated rationales. For example, if all seed rationales are written in a similar style, like "The first...the second...", subsequently generated rationales will tend to follow the same pattern. Therefore, some diversity in seed rationales still appears to be important for inducing sufficient diversity in generated rationales.

Overall, through this study, we hope to motivate more research on understanding how language models respond differently to variations in few-shot exemplars, which can lead to the development of more robust and autonomous approaches for generating effective prompts for a given target task.
