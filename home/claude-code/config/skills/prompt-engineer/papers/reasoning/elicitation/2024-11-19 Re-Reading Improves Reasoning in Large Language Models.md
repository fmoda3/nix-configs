# Abstract

To enhance the reasoning capabilities of off-the-shelf Large Language Models (LLMs), we introduce a simple, yet general and effective prompting method, Re2, i.e., **Re**-**Re**ading the question as input. Unlike most thought-eliciting prompting methods, such as Chain-of-Thought (CoT), which aim to elicit the reasoning process in the output, Re2 shifts the focus to the input by processing questions twice, thereby enhancing the understanding process. Consequently, Re2 demonstrates strong generality and compatibility with most thought-eliciting prompting methods, including CoT. Crucially, Re2 facilitates a "bidirectional" encoding in unidirectional decoder-only LLMs because the first pass could provide global information for the second pass. We begin with a preliminary empirical study as the foundation of Re2, illustrating its potential to enable "bidirectional" attention mechanisms. We then evaluate Re2 on extensive reasoning benchmarks across 14 datasets, spanning 112 experiments, to validate its effectiveness and generality. Our findings indicate that, with the exception of a few scenarios on vanilla ChatGPT, Re2 consistently enhances the reasoning performance of LLMs through a simple re-reading strategy. Further analyses reveal Re2's adaptability, showing how it can be effectively integrated with different LLMs, thought-eliciting prompting, and ensemble strategies.

# Introduction

In the ever-evolving landscape of artificial intelligence, large language models (LLMs) have emerged as a keystone of natural language understanding and generation [brown2020language; touvron2023llama; openai2023gpt; xu2024surveyknowledgedistillationlarge]. As LLMs have become more advanced, a key challenge has emerged: teaching them to reason effectively. The ability to reason well is a key aspect of human intelligence, allowing us to infer, deduce, and solve problems. In LLMs, this skill is crucial for improving their practical use. Despite their impressive abilities, LLMs often have difficulty with reasoning tasks [blair2023can; arkoudas2023gpt], urging researchers to explore more strategies to bolster reasoning ability [wei2022chain; gao2023pal; besta2023graph].

[IMAGE: figures/intro7.pdf - Example inputs of CoT prompting versus CoT prompting with Re2. In original CoT, every token in the question cannot see its later tokens since most LLMs are autoregressive models (the top figure). Re2 is a simple prompting method that repeats the question as input. LLMs with Re2 allows each token in the second pass, e.g. "tennis balls", to see its later tokens from the first pass, e.g. "How many ...", achieving an effect of a "bidirectional" understanding (the bottom figure).]

[IMAGE: figures/intro_attention4.pdf - Illustration of the attention distribution in LLaMA-2 by repeating the question as the input (a darker cell indicates higher attention). The region within the red dashed upper triangle demonstrates that every token in the second pass has obvious attention to its later tokens in the first pass. This suggests that re-reading in LLMs is promising for achieving a "bidirectional" understanding of the question.]

Existing research on reasoning has predominantly concentrated on designing diverse thought-eliciting prompting strategies to elicit reasoning processes in the output phase, such as Chain-of-Thought (CoT) [wei2022chain], Program-Aided Language Model (PAL) [gao2023pal], etc. [yao2023tree; besta2023graph; wang2023plan]. In contrast, scant attention has been paid to the understanding of the input phase. In fact, comprehension is the first step before solving the problem, which is crucially important. However, in the era of generative AI, most LLMs adopt the decoder-only LLMs with unidirectional attention, like GPT-3 [brown2020language] and LLaMA [touvron2023llama2]. This unidirectional attention limits every token's visibility to only previous tokens when encoding a question, potentially impairing the bidirectional understanding of each word in the question [DBLP:conf/acl/DuQLDQY022]. In Figure 1, the last sentence, *"How many ..."*, highlights the question's main focus, which is crucial for the understanding of the preceding words. However, LLMs cannot see the subsequent words when encoding a token due to their unidirectional vision.

Fortunately, many cognitive science studies have revealed that humans tend to re-read questions during learning and problem-solving to enhance the comprehension process [dowhower1987effects; dowhower1989repeated; ozek2006study]. The first reading provides an overall understanding, which benefits the second reading. Motivated by this, we also conduct a preliminary empirical study for LLaMA-2 [touvron2023llama2] by repeating the question two times as the input using the GSM8K dataset [cobbe2021training]. The attention heatmap in Figure 2 shows that the re-reading strategy allows LLaMA-2 to achieve a "bidirectional" understanding of the question, which is expected to further improve the reasoning performance.

Based on the observation and inspired by the human strategy of re-reading, we present a simple yet effective and general reasoning prompting strategy, Re2, i.e., **Re**-**Re**ading the question as input (see the illustration in Figure 1). While our Re2 is simple, it offers several advantages for LLMs' reasoning scenarios. (1) This approach mirrors the human strategy of problem-solving. LLMs with Re2 show potential for a "bidirectional" understanding of questions. (2) Repeating questions allows LLMs to allocate more computational resources to input encoding, similar to "horizontally" increasing the depth of neural networks. (3) Re2 emphasizes understanding during the input phase, making it orthogonal to and compatible with most thought-eliciting prompting methods that focus on the output phase, such as CoT and PAL.

To validate the efficacy and generality of Re2, we conducted extensive experiments spanning arithmetic, commonsense, and symbolic reasoning tasks across 14 datasets and 112 experiments. The results show that, with the exception of certain scenarios on vanilla ChatGPT, our Re2 with a simple re-reading strategy consistently enhances the reasoning performance of LLMs. Re2 exhibits versatility across various LLMs, such as Text-Davinci-003, ChatGPT, LLaMA-2-13B, and LLaMA-2-70B, spanning both instruction fine-tuning (IFT) and non-IFT models. We also explore Re2 in task settings of zero-shot and few-shot, thought-eliciting prompting methods, and the self-consistency setting, highlighting its generality.

# Methodology

## Vanilla Chain-of-Thought for Reasoning

We begin with a unified formulation to leverage LLMs with CoT prompting to solve reasoning tasks. In formal, given an input ```latex $x$ ``` and a target ```latex $y$ ```, a LLM ```latex $p$ ``` with CoT prompting can be formulated as

```latex
$$\begin{align}
&y \sim \sum\limits_{z\sim~p({\textnormal{z}}|C_x)} p({\textnormal{y}}|C_x,z) \cdot p(z|C_x), \notag \\
& \text{where } C_x = \mathop{\mathrm{c}}\nolimits^{\text{(cot)}}(x). \label{eq:cot}
\end{align}$$
```

In this formulation, ```latex $C_x$ ``` denotes the prompted input. ```latex $\mathop{\mathrm{c}}^{(\text{cot})}(\cdot)$ ``` represents the template with CoT prompting instructions, such as '*let's think step by step*'. ```latex ${\textnormal{z}}$ ``` stands for a latent variable of rationale, and ```latex $z$ ``` denotes a sampled rationale in natural language. Consequently, the LLMs can break down complex tasks into more manageable reasoning steps, treating each step as a component of the overall solution chain. We employ CoT as a baseline to solve reasoning tasks without compromising its generality. In addition to CoT, our proposed simple Re2 can serve as a "plug & play" module adaptable to most other prompting methods.

## Re-Reading (Re2) Improves Reasoning

Drawing inspiration from the human strategy of re-reading, we introduce this strategy for LLM reasoning, dubbed Re2, to enhance understanding in the input phase. With Re2, the prompting process can be readily rephrased as:

```latex
$$\begin{align}
\label{eq:re2}
&y \sim \sum_{z\sim~p({\textnormal{z}}|C_x)} p({\textnormal{y}}|C_x,z) \cdot p(z|C_x), \notag \\
& \text{where } C_x = \mathop{\mathrm{c}}\nolimits^{(\text{cot})}(\mathop{\mathrm{re2}}(x)).
\end{align}$$
```

In this formulation, ```latex $\mathop{\mathrm{re2}}(\cdot)$ ``` is the re-reading operation of the input. We don't seek complex adjustments for LLMs but aim for a general implementation of ```latex $\mathop{\mathrm{re2}}(x)$ ``` that is as simple as follows:

```
Q: {Input Query}
Read the question again: {Input Query}
# Thought-eliciting prompt (e.g., "Let's think step by step") #
```

where '{Input Query}' is a placeholder for the input query, ```latex $x$ ```. The left part of this prompting could incorporate other thought-eliciting prompts. Intuitively, Re2 offers two advantages to enhance the understanding process: (1) it allocates more computational resources to the input, and (2) it facilitates a "bidirectional" understanding of the question, where the first pass provides global information for the second pass.

## Generality of Re2

Due to Re2's simplicity and emphasis on the input phase, it can be seamlessly integrated with a wide range of LLMs and algorithms, including few-shot settings, self-consistency, various thought-eliciting prompting strategies, and more. We offer insights into the integration of Re2 with other thought-eliciting prompting strategies as an illustration.

Compared with those thought-eliciting prompting strategies that focus on the output phase, Re2 shifts the emphasis towards understanding the input. Therefore, Re2 exhibits significant compatibility with them, acting as a "plug & play" module. This synergy has the potential to further enhance the reasoning abilities of LLMs. With a specific thought-eliciting prompting, ```latex $\tau$ ```, designed to elicit thoughts from the LLMs, the equation is rewritten as:

```latex
$$\begin{align}
\label{eq:compat}
&y \sim \sum_{z\sim~p({\textnormal{z}}|C_x)} p({\textnormal{y}}|C_x,z) \cdot p(z|C_x), \notag \\
& \text{where } C_x = \mathop{\mathrm{c}}\nolimits^{(\tau)}(\mathop{\mathrm{re2}}(x)).
\end{align}$$
```

Here, ```latex $\tau$ ``` denotes various thought-eliciting promptings beyond CoT, such as Plan-and-Solve [wang2023plan], and Program-Aided Prompt [gao2023pal], etc. We also conducted lots of experiments to validate the generality of Re2.

# Experiments

## Benchmarks

We assess Re2 prompting across three key categories of reasoning benchmarks. Details of all datasets are shown in Appendix.

#### Arithmetic Reasoning

We consider the following seven arithmetic reasoning benchmarks: the GSM8K benchmark of math word problems [cobbe2021training], the SVAMP dataset of math word problems with varying structures [patel-etal-2021-nlp], the ASDiv dataset of diverse math word problems [miao-etal-2020-diverse], the AQuA dataset of algebraic word problems [ling-etal-2017-program], the AddSub [hosseini-etal-2014-learning] of math word problems on addition and subtraction for third to fifth grader, MultiArith [roy-roth-2015-solving] dataset of math problems with multiple steps, and the SingelEQ [roy-2016-reasoning] dataset of elementary math word problems with single operation.

#### Commonsense and Symbolic Reasoning

For commonsense reasoning, we use CSQA [talmor-etal-2019-commonsenseqa], StrategyQA [geva-etal-2021-aristotle], and the ARC [Clark2018ThinkYH]. CSQA dataset consists of questions that necessitate various commonsense knowledge. The StrategyQA dataset comprises questions that demand multi-step reasoning. The ARC dataset (denoted as ARC-t) is divided into two sets: a Challenge Set (denoted as ARC-c), containing questions that both retrieval-based and word co-occurrence algorithms answered incorrectly, and an Easy Set (denoted as ARC-e). We evaluate two symbolic reasoning tasks: date understanding [Suzgun2023bbh] and Coinflip [wei2022chain]. Date understanding is a subset of BigBench datasets [Suzgun2023bbh], which have posed challenges for previous fine-tuning efforts. Coinflip is a dataset of questions on whether a coin is still heads up after it is flipped or not based on steps given in the questions.

## Language Models and Implementations

**Baseline Prompting.** In our implementation, we rigorously evaluate the performance of our Re2 model on two baseline prompting methods: Vanilla and CoT. The Vanilla approach aligns with the standard prompting method outlined in [wei2022chain; zero_shot_cot], wherein no specific prompts are employed to elicit thoughts from LLMs. Conversely, the CoT method guides the model through a step-by-step thought process.

**Re2 Prompting.** We incorporate Re2 into these baseline methods to assess its impact, denoted as Vanilla+Re2 and CoT+Re2. To avoid the impact of randomness introduced by the demonstrations in a few-shot setting, we mainly assess our method in a zero-shot setting, following [Chen2023When; wang2023plan; du2023improving]. Additionally, for different tasks, we design answer-format instructions in prompts to regulate the format of the final answer, facilitating precise answer extraction. Detailed information regarding the baseline prompting, Re2 prompting, and answer-format instructions can be found in the Appendix.

**Implementations.** Our decoding strategy uses greedy decoding with a temperature setting of 0, thus leading to deterministic outputs. For these experiments, we employ two powerful backbones: ChatGPT (gpt-3.5-turbo-0613) [openai-chatgpt] and davinci-003 (text-davinci-003), across all prompting methods, including Vanilla, CoT, Vanilla+Re2, and CoT+Re2. We also test Re2 on more advanced GPT-4o-mini in Appendix.

## Evaluation Results

The results on arithmetic reasoning datasets and commonsense reasoning and symbolic reasoning show that in almost all scenarios, LLMs with Re2 achieve consistent improvements across both LLMs (davinci-003 and ChatGPT) and prompting methods (Vanilla and CoT). Specifically, davinci-003 with Vanilla+Re2 shows average improvements of 3.81, 2.51, and 1.85 in arithmetic, commonsense, and symbolic tasks, respectively. With CoT, davinci-003 generates intermediate reasoning steps, significantly enhancing the reasoning performance of LLMs. By applying Re2, davinci-003 with CoT+Re2 demonstrates further improvement, with average gains of 2.22, 1.23, and 5.25 in the same categories, respectively. These results indicate that Re2 can benefit LLMs in directly generating answers and improve the performance of CoT leading to correct answers.

When applied to ChatGPT, Re2 exhibits consistent improvement on most datasets, except for a slight drop in performance on a few datasets, e.g., AQUA and MultiArith, when using Vanilla+Re2. This exception could be due to ChatGPT's exposure to these datasets with CoT outputs during instruction fine-tuning (IFT) [Chen2023When]. On such datasets, ChatGPT with Vanilla still produces CoT-like output (see examples in Appendix) and even outperforms ChatGPT with CoT. Similar experimental results suggest that this occurs because ChatGPT may have been exposed to these task datasets containing CoT explanations without explicit prompting. Therefore, additional explicit instructions, like CoT or Re2, might disrupt this learned pattern in ChatGPT, possibly leading to decreased performance. Nonetheless, on some datasets like SVAMP, ASDIV, CSQA, and Date, Re2 still manages to improve the baseline Vanilla prompting. Moreover, in datasets where CoT prompting normally surpasses Vanilla prompting, such as GSM, StrategyQA, and Coin, Re2 significantly enhances Vanilla prompting (+4.63 on StrategyQA and +5.20 on the Coin dataset). Overall, our Re2 method still achieves improvements in 71% of the experiments on ChatGPT. More examples from the experiment results can be found in Appendix.

[IMAGE: figures/times_of_reading2.pdf - Evaluation results of the times of reading on GSM benchmark.]

## Discussions

#### Times of Question Reading

We delve deeper into the impact of the times of question re-reading on reasoning performance. Figure 3 illustrates how the performance of two distinct LLMs evolves concerning various times of question re-reading. An overarching pattern emerges across all models: performance improves until the number of re-reads reaches 2 or 3, after which it begins to decline with further increases in question re-reading times. The potential reasons for inferior performance when reading the question multiple times are two-fold: i) appropriate reading times increase LLMs' ability to generate correct answers. However, excessively repeating questions may serve as demonstrations, causing the LLMs to repeat the questions themselves (see Appendix for detailed analysis). and ii) repeating the question significantly increase the inconsistency of the LLMs between our inference and pretraining/alignment (intuitively in the learning corpora, we usually repeat a question twice). It's noteworthy that reading the question twice is optimal in most scenarios, which is why we refer to it as "re-reading" in our paper.

| **LLMs**    | **Methods**     | **GSM**   |
|:-----------:|:---------------:|:---------:|
| ChatGPT     | PS              | 75.59     |
|             | PS+Re2          | **76.27** |
|             | PAL             | 75.59     |
|             | PAL + Re2       | **79.38** |
| davinci-003 | PS              | 55.65     |
|             | PS+Re2          | **58.68** |
|             | PAL             | 68.61     |
|             | PAL + Re2       | **70.20** |

Table 1: Evaluation results of some thought-eliciting promptings beyond CoT with Re2.

#### Compatibility with Thought-Eliciting Prompt Strategies

Compared to previous methods attempting to elicit thoughts in the output from LLMs, our Re2 emphasizes the understanding of the input. Therefore, we are intrigued to explore whether Re2 is effective with various thought-eliciting prompting strategies other than CoT. To investigate this, we apply Re2 to two other recently introduced prompting methods, namely, Plan-and-Solve (PS) [wang2023plan] and Program-Aided Language models (PAL) [gao2023pal]. The former model devises a plan to divide the entire task into smaller subtasks, and then carries out the subtasks according to the plan, while the latter generates programs as the intermediate reasoning steps. We directly apply our Re2 to these two methods by making a simple alteration to the input by repeating the question. Table 1 presents the evaluation findings on the GSM benchmark. Our observations reveal a consistent trend, akin to what was observed with CoT prompting. These results suggest that the effectiveness of our Re2 generally extends across various prompting methodologies.

#### Compatibility with Few-Shot Prompting

It is noteworthy that our proposed re-reading mechanism is compatible with few-shot prompting. To demonstrate this compatibility, we conducted experiments on arithmetic reasoning tasks using the davinci-003 model, employing both Vanilla and CoT prompting methods. The few-shot prompting strategy and exemplars used align with those presented in [wei2022chain]. For both the Vanilla+Re2 and CoT+Re2 methods, we applied the re-reading mechanism to the exemplars as well. The results of these experiments show that the inclusion of the re-reading mechanism consistently enhances the performance of both prompting methods, mirroring our findings in the zero-shot setting.

#### Effect on Non-IFT Models

In our primary experiments, we employed the ChatGPT and davinci-003 models, which had undergone IFT training. These models, being aligned with human-like behavior, are better equipped to follow instructions effectively. Additionally, they may have been exposed to datasets with CoT prompting during their training, making the "re-reading" mechanism potentially more beneficial in recalling explanations. To gauge the broader applicability of our approach and to eliminate any IFT-related impacts, we conducted experiments on non-IFT pretrained models: Llama-2-13B and Llama-2-70B [touvron2023llama2]. Llama-2 is an open-source model pretrained on publicly available data without IFT or RLHF fine-tuning. We evaluated Llama-2 on arithmetic reasoning tasks under a zero-shot setting, following [zero_shot_cot]. The results clearly indicate that the re-reading mechanism consistently enhances the performance of both Vanilla and CoT prompting methods across most tasks when applied to Llama-2 models. This observation underscores the generality of our approach and dispels concerns about potential data leakage from IFT during training. This also underscores the versatility of Re2, which can be effectively employed across various model scales and types, regardless of whether they have undergone IFT training or are non-IFT LLM.

| **LLMs** | **Methods**          | **GSM**   | **SVAMP** |
|:--------:|:--------------------:|:---------:|:---------:|
| ChatGPT  | Vanilla              | 77.79     | 81.50     |
|          | Vanilla+SC           | 85.60     | 87.37     |
|          | Vanilla+Re2+SC       | **86.35** | **87.74** |
|          | CoT                  | 78.77     | 78.70     |
|          | CoT+SC               | 85.75     | 84.90     |
|          | CoT+Re2+SC           | **86.88** | **87.70** |

Table 2: Evaluation results of re-reading with self-consistency (t-test, p-value < 0.05).

#### Compatibility with Self-consistency

Existing research indicates that the chain-of-thought prompting approach can be enhanced by adopting the self-consistency method, which involves aggregating the majority final answer from multiple sampled generations. We are also intrigued by the potential for further enhancing the proposed re-reading mechanism using this method. Consequently, we conduct experiments testing the integration of Re2 with the self-consistency approach on the GSM benchmark by using ChatGPT. The temperature is set to 0.7. We report the results averaged over 10 runs, where we sampled 10 outputs independently from the LLMs in each run. Table 2 demonstrates that self-consistency significantly enhances the performance of both prompting methods. Despite self-consistency's aggregation of multiple answers, our re-reading mechanism still contributes to improvement on most scenarios, indicating its compatibility with the self-consistency approach.

[IMAGE: figures/gsm_complexity_accuracy_3_8_2.pdf - Left figure: model performance versus complexity of questions. X-axis means the complexity of questions and Y-axis refers to frequency. The gray hist means the number of total cases for each complexity. Right figure: n-gram recall between the generation and the input question. We take the question and generation as the reference and hypothesis respectively.]

#### Performance across Different Question Complexity

We further investigate the impact of input question complexity on the reasoning performance of both CoT and CoT+Re2 promptings using ChatGPT on GSM8K dataset, as shown in the left part of Figure 4. In accordance with [fu2022complexity], we measure question complexity by counting the reasoning steps present in the ground-truth explanations. Our findings reveal that the performance of all promptings generally diminishes as question complexity increases, suggesting that the current LLMs still struggle with handling intricate queries. Notably, the introduction of re-reading enhances performance on various complexities, including those slightly complex questions. This observation underscores the benefits of Re2 for improving reasoning capabilities over complex questions. To further validate the improved understanding ability, we calculate the coverage degree (n-gram recall) between the generations and the input questions, as illustrated in the right part of Figure 4. The results indicate that Re2 increases the n-gram (n=1,2,3,4) recall in the output explanations, underscoring how our method enhances the model's focus on the question during the reasoning process.

#### The Impact of Different Re-Reading Instructions

We further conduct experiments to examine the influence of Re2 within the context of CoT prompting. Specifically, we design various instructions for question re-reading using ChatGPT on GSM8K dataset. Instruction P1, which includes the phrase "Read the question again:", exhibits superior performance compared to directly repeating the question twice. These results suggest that providing more detailed re-reading instructions to the LLMs is advantageous. Subsequently, we explore the possibility of introducing re-reading for CoT instructions (i.e. repeating "Let's think step by step"). However, we observe that repeating the thinking process two times does not yield any discernible benefits. It's noteworthy that, in general, question re-reading consistently improves reasoning performance compared to the standard CoT prompting without question re-reading.

[IMAGE: figures/re2_comparison_2.pdf - Re2's impact on inference efficiency and GPU memory usage.]

#### Impact on Inference Efficiency and Memory Usage

Re2 doubles the question length in both zero- and few-shot settings, which may affect inference efficiency and memory usage. This section quantitatively explores that impact. We utilize Llama-2 7B with float16 precision and randomly sample 100 instances from the GSM8K dataset. We measure the average inference time and memory usage across four scenarios: Zero-shot, Zero-shot + CoT, Few-shot, and Few-shot + CoT. When applying Re2, the questions in the demonstrations are also repeated. All experiments are performed on 8x NVIDIA GeForce RTX 4090 GPUs, with results shown in Figure 5. The findings reveal that RE2 only marginally increases inference time and memory usage in both zero-shot and few-shot settings, even with longer inputs. This minimal impact is attributed to various optimization and inference acceleration techniques in current LLMs, such as grouped-query attention [touvron2023llama2], CUDA, and GPU-based computations. For instance, grouped-query attention is particularly advantageous for long inputs, significantly accelerating decoder inference. Likewise, CUDA and GPU-based computations are highly optimized for parallel processing, especially for matrix multiplications in LLMs [nvidia_cudaguide].

# Related Work

#### Reasoning with Large Language Models

LLMs represent a significant milestone in the journey towards artificial general intelligence (AGI) [openai2023gpt; touvron2023llama2]. Reasoning ability is particularly crucial on the way towards AGI, where artificial intelligence needs to act or think like human beings [Qiao2023ReasoningSurvey; Huang2023ReasoningSurvey]. In the literature on LLMs, performing reasoning tasks via interaction in natural language plays a significant role in evaluating an LLM, into which academia and industry have been dedicating many endeavors [Wei2022Emergent; Suzgun2022Challenging; Turpin2023Language]. In principle, most works for reasoning with large language models could fall into the paradigm of "Chain-of-Thought" [wei2022chain; zero_shot_cot], which assists LLMs in fulfilling complex reasoning tasks by generating intermediate steps explicitly. Therefore, most of the endeavors are dedicated to improving the basic principle by the following aspects: i) the structure of "chain", e.g., tree [yao2023tree], graph [Yao2023GoT]; ii) the modality of the chain, e.g., program [gao2023pal]; iii) the reliability of the chain, e.g., self-consistency [wang2022self], faithful [Lyu2023FaithfulCoT], retrieval-based verifying [He2023retrievalcot]; and iv) decomposition of the chain, e.g., least-to-most [zhou2023leastmost], decomposed [Radhakrishnan2023decomposed], plan-to-solve [wang2023plan]. In contrast, our simple re-reading strategy for LLMs is orthogonal to these improvements via a trade-off between the intermediate steps and the query itself. Besides, our re-reading strategy is complementary to many previous works by preventing the answer from being derived overwhelmingly from the CoT but overlooking the original query.

#### Re-reading Strategy in NLP

In deep learning, the success of performing text-understanding tasks [Song2018Joint; Luo2019Unsupervised; Yang2019Exploring; Lei2019HumanLike] depends on the heuristics of human reading strategy, e.g., pre-reading, re-reading and post-reading [saricoban2002reading; toprak2009three; pressley2012verbal; ozek2006study; dowhower1989repeated]. Specifically, many effective algorithms have been crafted around the idea of re-reading. Although deep architectures, from multi-layer Bi-LSTM [Huang2015BiLSTM] to Transformer-encoder [Vaswani2017Transformer], have their mechanisms that provide a form of "re-reading", the notion that simply processing an input once might not be sufficient for understanding or generating a complex output has been long-standing. Initially, [Sha2016Reread] and [Sha2017Repeat] found that repeated reading mechanisms do improve performance on some tasks, e.g., sentiment analysis, semantic relation classification, and event extraction. Then, [Liu2016Repeated] propose to mimic the repeated reading strategy and present neural networks with multi-level attention, which is proven effective in recognizing implicit discourse relations. Sequentially, [Zhu2018MultiGlance] propose a multi-glance mechanism, modeling the habit of reading behavior, which can benefit a wide range of tasks. [Luo2019HER] adopt a network to encode the gist of paragraphs for rough reading and a decision-making policy for careful reading, which can improve extractive summarization. More recently, [springer2024repetitionimproveslanguagemodel] have shown the effectiveness of repeating input to get bidirectional embeddings on text embedding tasks. Therefore, it is natural to introduce a re-reading strategy to LLMs' reasoning, since the Transformer-decoder architecture of LLMs with unidirectional attention mechanisms hinders the implicit bidirectional capability.

#### Knowledge Recall

From the perspective of information seeking, prompting LLMs can be seen as a sort of "knowledge recall" via a parametric fashion, where the prompt can be seen as a retrieval query. In contrast to conventional non-parametric retrieval -- vector database [Karpukhin2020DPR; Izacard2022Contriever] for example, the LLM as a neural knowledge model [Bosselut2019KnowModel; AlKhamissi2022LM] can easily generalize for huge knowledge coverage, contributing to its efficacy in broad applications. In the context of CoT reasoning, [Chen2023When] conjuncture that LLM can be exposed to certain CoTs during training and easily complete reasoning by knowledge recall. As such, it is natural to adapt the basic but prevalent query augmentation technique in the term-based retrieval domain [Dai2019BM25], which repeats the original query multiple times over the augmented part [Wang2023Q2D; Shen2023retriever], into prompting LLMs.

# Conclusion and Future Works

This paper introduces Re2, a simple and effective prompting method for LLM reasoning that improves performance by "re-reading" the question. By shifting focus to the input phase, Re2 operates independently from other thought-eliciting promptings. Moreover, it shows promise in fostering bidirectional comprehension of questions in decoder-only LLMs. Our comprehensive experiments cover a wide range of reasoning benchmarks, diverse LLM types, various task settings, and compatibility assessments with other prompting methods, validating the efficacy and versatility of Re2. Our findings encourage the research community to prioritize a deeper understanding of input questions, thereby complementing existing thought-eliciting prompting strategies. Future endeavors will aim to explore its versatility in additional contexts beyond reasoning, including multi-turn dialogue and multi-modal reasoning applications.

# Limitations

In this paper, we introduce a simple yet effective prompting method for enhancing reasoning in LLMs and conduct extensive experiments to validate its effectiveness. Despite our best efforts, there may be still some limitations that remain in our study. Our investigation primarily revolves around empirical studies with extensive experiments to validate Re2, similar to most works in prompting research [DBLP:journals/corr/abs-2304-09797; yin-etal-2023-exchange; gao2023pal]. Future efforts will include more theoretical analyses to provide a solid foundation. Additionally, Re2 marginally increases the input length, leading to a slight reduction in efficiency for longer questions during inference. Future work will explore more scenarios except reasoning, such as multi-turn dialogue and multi-modal reasoning.

# Ethics

We conducted experiments on seven mathematical reasoning benchmarks, comprising GSM8K [cobbe2021training], SVAMP [patel-etal-2021-nlp], ASDiv [miao-etal-2020-diverse], AQuA [ling-etal-2017-program], AddSub [hosseini-etal-2014-learning], MultiArith [roy-roth-2015-solving], SingelEQ [roy-2016-reasoning], three commonsense reasoning benchmarks (CSQA [talmor-etal-2019-commonsenseqa], StrategyQA [geva-etal-2021-aristotle], and ARC [Clark2018ThinkYH]), and two symbolic benchmarks (Date Understanding [Suzgun2023bbh] and Coinflip [wei2022chain]). Among these, GSM8K and SVAMP datasets utilize code under the MIT License, while AQuA, StrategyQA, Date Understanding, Coinflip utilize code under the Apache-2.0 license, and ARC utilizes code under CC-BY-SA-4.0. The licenses for the remaining datasets are unspecified.

The proposed prompts do not involve the collection or utilization of personal information pertaining to other individuals. Details regarding the prompts used in our experiments are provided in Appendix. Furthermore, it is ensured that the prompts utilized in this research do not pose any threat to the safety or well-being of others.

# Appendix: Datasets

Statistics and examples for the reasoning benchmarks are provided in the full paper.

# Appendix: Specific Prompting Methods

Detailed information regarding various promptings is shown in the full paper. The instructions of answer-format can also be found there.

# Appendix: GPT-4o-mini Experiments

LLMs are rapidly evolving, with more powerful models emerging frequently. To assess the effectiveness of Re2 on newer, more advanced models, we tested it on GPT-4o-mini, specifically the gpt-4o-mini-2024-07-18 version. The results demonstrate that Re2 continues to perform effectively on these more advanced LLMs.

# Appendix: Attention Analysis

[IMAGE: figures/attention.pdf - Attention visualization with and without Re2. (a) CoT prompting: there is only one pass for the question. (b) CoT+Re2 re-reads the question, including first pass and second pass. The row of matrix represents the query tokens and the column represents the key tokens.]

To gain deeper insights into how Re2 reshapes attention during inference, we visualize the attention distribution by computing the average attention weights across all heads and layers in Llama-2. The results reveal two key findings: (1) In the block of "Second pass" attending to the "First pass" as shown in (b) for CoT+Re2, we observe explicit attentions in the upper triangle. This observation indicates that tokens in the second question can focus on the tokens behind the corresponding positions in the first question. In this way, Re2 enables a "bidirectional" understanding of the question. Notably, with the inclusion of Re2, the generation process maintains a higher attention weight on the question tokens. By calculating the proportion of attention weights assigned to the question tokens during generation, we observe an increase from 0.32 to 0.40 with the utilization of Re2. This finding suggests that the re-reading mechanism enhances the model's focus on the question during the reasoning process.

# Appendix: Perplexity Analysis

[IMAGE: figures/ppl.pdf - The perplexity of generating the question or the ground-truth answer with increasing reading times.]

For the explanation about "overly repeating questions encourages LLMs to repeat the question rather than generate the answer", we conducted an experiment. This experiment aims to investigate the likelihood of generating questions versus generating ground-truth responses as reading times of the question increased. We pose two research questions: (1) Does the probability of generating the question as the output increase with more reading times? (2) Does the probability of generating the ground-truth response decrease with more reading times?

Specifically, for each question in the GSM8k dataset, we provide the LLM with the question with varying repetition times as input, and set the LLM's output as the question itself or its ground-truth response. We then calculate the perplexity of generating both the question and the ground-truth answer. Perplexity serves as an indicator reflecting the likelihood of generating a sequence, with lower perplexity indicating a higher likelihood. These experiments are conducted using the Llama 2.

The results reveal two key findings: (1) The perplexity of generating questions decreases with increasing reading times, suggesting that the LLM finds it easier to generate the question. (2) With the exception of when reading times = 2, the perplexity of generating the ground-truth response increases overall. This finding aligns with optimal performance observed when the question is read only twice. Moreover, as reading times increase, the LLM appears to be less inclined to generate the answer.

# Appendix: Case Study

We also conduct a case study to show the effectiveness of our proposed re-reading prompting over the chain-of-thought. We choose two examples from GSM, and the results generated by ChatGPT demonstrate that our method can better align the evidence in the question with the corresponding explanation hints. We can observe that CoT+Re2 tends to highlight the important evidences in the question before generating the explanation, for example, "*In the morning, she gives 15 cups of feed, and in the afternoon, she gives another 25. So ...*" and "*The bonus is worth half a month's salary, which is ...*". This observation is also consistent with the n-gram recall findings.

# Appendix: More Cases

Additional examples generated by ChatGPT with CoT and CoT+Re2 are provided in the full paper. We also provide several examples generated by davinci-003 and ChatGPT in the Vanilla prompting (e.g. no instruction). They show that ChatGPT with Vanilla directly generates answer in Coin Flip and Date Understanding dataset, but still generates CoT output in some other datasets.
