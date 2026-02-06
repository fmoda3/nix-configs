# Synthetic Prompting: Generating Chain-of-Thought Demonstrations for Large Language Models

**Authors:** Zhihong Shao, Yeyun Gong, Yelong Shen, Minlie Huang, Nan Duan, Weizhu Chen

**Affiliations:** Tsinghua University, Microsoft Research Asia, Microsoft

**arXiv:** 2302.00618

---

## Abstract

Large language models can perform various reasoning tasks by using chain-of-thought prompting, which guides them to find answers through step-by-step demonstrations. However, the quality of the prompts depends on the demonstrations given to the models, and creating many of them by hand is costly. We introduce Synthetic prompting, a method that leverages a few handcrafted examples to prompt the model to generate more examples by itself, and selects effective demonstrations to elicit better reasoning. Our method alternates between a backward and forward process to generate new examples. The backward process generates a question that match a sampled reasoning chain, so that the question is solvable and clear. The forward process produces a more detailed reasoning chain for the question, improving the quality of the example. We evaluate our method on numerical, symbolic, and algorithmic reasoning tasks, and show that it outperforms existing prompting techniques.

## Introduction

Few-shot demonstrations, i.e., examples of inputs and outputs for a task, can enable Large Language Models (LLMs) to perform various tasks without fine-tuning [Brown et al., 2020; Chung et al., 2022]. LLMs can further improve their performance by using chain-of-thought prompting, which provides intermediate reasoning steps for the task [Wei et al., 2022b; Kojima et al., 2022]. However, the LLMs' few-shot performance depends heavily on the quality of the demonstrations, especially for reasoning tasks that need complex and diverse reasoning patterns. Manually creating a large and diverse set of examples for demonstration selection is costly and tedious, while relying on a limited set of demonstrations may hamper the LLMs' generalization and adaptation to different test inputs.

In this paper, we propose a novel method, Synthetic prompting, that leverages the LLMs' own knowledge and generative power to augment a limited set of demonstrations with self-synthesized examples, and then uses the augmented set to elicit better reasoning in the LLMs. Specifically, given a few seed examples, each consisting of a question and a chain of reasoning steps, we prompt an LLM to generate more examples by alternating between two processes: (1) the backward process, where the LLM synthesizes a question based on a self-generated reasoning chain, which ensures that the question is answerable and well-defined; and (2) the forward process, where the LLM produces a reasoning chain for the synthesized question, which refines the reasoning chain to be more precise and consistent with the question. We repeat this process until we obtain enough synthetic examples. To select the most effective demonstrations from the augmented set, we propose a new selection scheme based on in-cluster complexity, which aims to maximize the diversity and informativeness of the demonstrations by clustering them and choosing the most complex one (the one with the longest reasoning chain) from each cluster. Finally, we prompt the LLM with the selected demonstrations to generate a reasoning chain for a test question and then use it to obtain the answer.

We evaluate our method on various reasoning tasks, including numerical reasoning, algorithmic reasoning, and symbolic reasoning. Following previous few-shot settings [Wang et al., 2022b; Suzgun et al., 2022], we demonstrate that our method can significantly improve the LLMs' performance, achieving up to 15.6% absolute gains over the state-of-the-art methods.

Our main contributions are:

- We introduce Synthetic prompting, a novel method that augments a limited set of demonstrations with self-synthesized examples by prompting an LLM, and leverages the augmented set to elicit better reasoning in the LLM.

- We propose an in-cluster complexity based scheme to select diverse and informative demonstrations from the augmented set for inference.

- We demonstrate the effectiveness of our method on three reasoning tasks, achieving significant improvements over previous methods.

## Related Work

### In-context few-shot learning

With large-scale unsupervised pre-training, LLMs [Brown et al., 2020; Chowdhery et al., 2022; Zhang et al., 2022a] can learn to perform tasks by mimicking in-context demonstrations [Shin et al., 2022]. To improve robustness to prompts, instruction tuning [Ouyang et al., 2022; Wei et al., 2022a; Sanh et al., 2022; Chung et al., 2022] has been proposed, which trains a language model on diverse tasks to generate desirable outputs that follow given instructions. With improved controllability, in-context learning-based applications flourish, including text generation [Yang et al., 2022; Gao et al., 2022a], dialogue generation [Thoppilan et al., 2022], and resource construction [West et al., 2022].

### Prompting techniques for reasoning

Instead of directly generating an answer, chain-of-thought prompting [Wei et al., 2022b] prompts LLMs to arrive at an answer after a step-by-step reasoning process, which largely improves performance on numerous reasoning tasks. Following work like least-to-most prompting [Zhou et al., 2022], self-ask [Press et al., 2022], and decomposed prompting [Khot et al., 2022] also shares the spirit of question decomposition, i.e., decomposing a complex question into a series of tractable sub-questions. All these methods produce natural language reasoning steps, which struggle with calculations and symbolic manipulations. Techniques like PaL prompting [Gao et al., 2022b] and program-of-thought prompting [Chen et al., 2022] propose to improve natural language reasoning with structured code, showing significant improvements on arithmetic, symbolic and algorithmic tasks.

Orthogonal to prompting workflows, there is also work that explores what make an effective demonstration. Metrics include (1) diversity, which selects complementary demonstrations so that models can fuse different reasoning [Li et al., 2022; Ye et al., 2022b] or be less biased by one type of reasoning [Zhang et al., 2022b]; (2) reasoning complexity, which selects demonstrations with the highest reasoning complexity, and has been found to work well on numerical reasoning empirically [Fu et al., 2022]; (3) similarity with a test input, which retrieves structurally [Drozdov et al., 2022] or semantically [Liu et al., 2022b] similar demonstrations. To ensure both diversity and informativeness of demonstrations, we propose a selection scheme based on in-cluster complexity to choose the most complex examples from example clusters. All these selection schemes assume access to a set of examples (whether annotated or not).

### Knowledge distillation from LLMs

Some researches distilled knowledge from LLMs into symbolic knowledge, e.g., structured commonsense knowledge [West et al., 2022] or task-specific examples [Liu et al., 2022a; Ye et al., 2022a; Huang et al., 2022]. These researches have at least one of the following characteristics: (1) assuming access to gold inputs from training sets without needing to generate them; (2) distilling knowledge based on collaboration between workers and AI; (3) using distilled knowledge for training. By contrast, we assume access to only a few gold examples, automatically synthesize more examples by prompting an LLM, and study whether synthesized examples can be leveraged to better elicit reasoning in the model itself, without further training.

[IMAGE: Figure 1 - prompts_for_synthesis.pdf - Example prompts and model completions in the backward process (left) and the forward process (right) of example synthesis. We show only one demonstration in each prompt for brevity. Self-Generated Reasoning Chain (in blue), Synthesized Question (in green), and Synthesized Reasoning Chain (in purple) are example completions. In the backward process, an LLM synthesizes a question conditioned on a topic word, a target reasoning complexity, and a generated reasoning chain. To better control the reasoning complexity, we number the reasoning steps, e.g., # 1 and # 2 on the left. In the forward process, the LLM synthesizes a more precise reasoning chain for the question produced in the backward process. The question produced in the backward process and the corresponding reasoning chain produced in the forward process constitute a synthetic example.]

## Synthetic Prompting

### Overview

To perform reasoning tasks with LLMs, given a few examples each consisting of a question and a reasoning chain, it is common to directly concatenate them into a prompt for inference. In this paper, we instead treat them as seed examples, and prompt an LLM to automatically synthesize more by repeating a backward-forward procedure; the backward process and the forward process produce a question and a corresponding reasoning chain, respectively. During inference, the LLM is prompted with self-synthesized demonstrations to better elicit reasoning in the model itself. Demonstrations are selected with a new scheme that ensures diversity and informativeness.

### Example Synthesis Phase

Using seed demonstrations, we automatically synthesize more examples by repeating a backward-forward process. Each synthetic example is a (question, reasoning chain) pair. In our main experiments, we use PaL-style reasoning, i.e., reasoning chains are snippets of code, and answers are obtained by executing the code.

#### Backward Process

In the backward process, an LLM is prompted to first generate a reasoning chain and then a question. The question, which is the output of the backward process, is synthesized conditioned on a given topic word, a target reasoning complexity, and the self-generated reasoning chain. Figure 1 (left) shows an example prompt for the backward process, which includes some demonstrations randomly sampled from the seed examples and the previously synthesized ones. The number of demonstrations is equal to the number of seed examples.

**Topic word** We assume that each reasoning question is related to a specific topic, and that different topics may require different types of reasoning. For example, questions about _tax_ may involve arithmetic operations, while questions about _speed_ may involve unit conversions. To ensure diversity of the synthesized questions, we prompt the model to generate a question for a given topic word, which is randomly sampled from a set of words. The word set is created by prompting the model to list single-token noun words, following some random noun words from the seed examples. The instruction for generating the word set is `List 50 noun words. Each word should contain one token only. Do not repeat words already listed.`, followed by no more than 10 words from the seed examples. We repeat this process until we have 1,000 different words, or reach 100 repetitions of prompting.

**Target complexity** We also want to control the complexity of the synthesized questions, as more complex examples may help the model learn better reasoning skills [Fu et al., 2022]. We define the complexity of a question as the number of reasoning steps required to answer it, where a step is a line of code separated by a line break. For example, the complexity of `Example 1` in Figure 1 (left) is 5, as it has 5 lines of code. The target complexity for generating a question is randomly sampled from a range that spans from the lowest complexity of the seed examples to the highest one plus `latex $c$ `.

**Self-generated reasoning chain** We prompt the model to generate a reasoning chain of the target complexity for the given topic, and then generate a question based on the reasoning chain. We find that this approach leads to more answerable and well-defined questions, compared to directly generating questions without a reasoning chain. To guide the model to follow the target complexity, we number each reasoning step in the demonstrations, e.g., `#1` and `#2` in Figure 1 (left). We filter out the questions that are duplicated, repeat at least one 5-gram, or do not mention the given topic word.

#### Forward Process

The forward process aims to generate a reasoning chain for the question synthesized in the backward process. Figure 1 (right) shows an example prompt for the forward process, which consists of the seed examples. Unlike chain-of-thought prompting, PaL prompting does not include the final answers in the prompt, as the answers can be obtained by executing the generated code, rather than extracted from the model output. We observe that the reasoning chain generated in the forward process is more relevant and precise than the one generated in the backward process, as it is directly conditioned on the question.

We also want to ensure that the model is confident about the answer produced by the reasoning chain. Following Huang et al. [2022], we measure the confidence of an answer by the proportion of sampled reasoning chains that lead to the same answer. For a question `latex $x$ `, we sample `latex $m$ ` reasoning chains and obtain their answers `latex $\{a_1, a_2, ..., a_m\}$ `. We then find the most consistent answer by majority voting: `latex $\hat{a} = \arg max_{a_i} \sum_{k=1}^m \mathbbm{1}(a_i=a_k)$ `. If more than `latex $m/2$ ` reasoning chains lead to `latex $\hat{a}$ `, we associate the shortest one with the synthesized question; otherwise, we discard the question, as the model fails to produce confident reasoning chains for it. Note that majority voting is only used for synthesizing examples, not for inference (Section 3.3). This is different from Wang et al. [2022a], who use majority voting for inference.

### Inference Phase

During inference, we select a subset of synthesized examples as demonstrations for the model. According to Fu et al. [2022], selecting demonstrations based on complexity can improve the performance of the model on reasoning tasks, compared to selecting them based on similarity. Moreover, selecting demonstrations based on similarity may introduce biases [Zhang et al., 2022b; Lyu et al., 2022] from the demonstrations, especially if they are incorrect. Furthermore, selecting demonstrations that are complementary to each other may help the model fuse knowledge from different types of reasoning [Ye et al., 2022b; Zhang et al., 2022b].

Therefore, we propose an in-cluster complexity based scheme to select demonstrations that are both complex and complementary. Specifically, we cluster the synthesized examples in a semantic embedding space, using Sentence-BERT [Reimers and Gurevych, 2019] as the encoder. The number of clusters is equal to the number of demonstrations used for inference. We then choose the most complex example from each cluster as the demonstration. The inference process is the same as previous work like PaL prompting, where the model completes a given prompt. The only difference is that the demonstrations in our prompts are synthesized from the seed examples, rather than fixed to them.

## Experiments

### Datasets

We experimented on seven datasets of different reasoning tasks.

**Numerical reasoning:**
(1) GSM8K [Cobbe et al., 2021] is a dataset of 1,319 diverse grade school math word problems, curated to evaluate multi-step mathematical reasoning abilities of LLMs. (2) GSM-Hard is a harder version of GSM8K, created by Gao et al. [2022b] via replacing numbers in the questions with larger ones, intended to evaluate whether LLMs can generalize to large numbers. (3) SVAMP [Patel et al., 2021] is a math word problem dataset with 1,000 questions for robustness evaluation. (4) ASDiv [Miao et al., 2020] consists of 2,000 diverse math word problems. (5) SingleOp [Koncel-Kedziorski et al., 2016] consists of 562 math word problems.

**Symbolic reasoning:**
The Colored Objects task from Big-Bench Hard [Suzgun et al., 2022], with 2,000 questions about position and color attributes of given objects.

**Algorithmic reasoning:**
The Repeat Copy task also comes from Big-Bench Hard, consisting of 32 test examples. A model should generate a sequence of words that meets requirements in a given instruction.

### Evaluation Settings

Both Suzgun et al. [2022] and Wang et al. [2022b] evaluated LLMs on benchmarks with numerous tasks under few-shot settings which have access to no more than 4 gold examples. Following these settings, we assumed access to 2 or 4 random examples from each dataset by default. For numerical reasoning tasks, we also experimented with the 8 examples that were manually crafted by Wei et al. [2022b] and were adopted by several following papers [Fu et al., 2022; Wang et al., 2022a; Gao et al., 2022b]. We also used the PaL-style reasoning chains annotated by Gao et al. [2022b].

Prompting baselines without synthesis use all provided gold examples to construct prompts for inference. Synthetic prompting and its variants synthesize examples using the provided examples, and select 8 synthetic demonstrations based on in-cluster complexity, unless stated otherwise.

Seed examples and synthetic prompts are provided in the Supplementary Materials.

### Baselines

**Direct Prompting** Direct prompting [Brown et al., 2020] prompts LLMs to directly generate answers with demonstrations of input-answer pairs.

**CoT Prompting** Chain-of-thought prompting [Wei et al., 2022b] is effective in eliciting reasoning in LLMs, which prompts LLMs to generate natural language reasoning steps followed by an answer.

**PaL Prompting** PaL prompting [Gao et al., 2022b], a variant of chain-of-thought prompting, improves reasoning with structured code. Figure 1 (right) provides two examples. It does not prompt LLMs to include final answers into completions; answers are obtained by executing the code. This prompting technique has achieved state-of-the-art results on numerous reasoning tasks.

**Vanilla Synthetic prompting** This is a variant of Synthetic prompting, which differs in that prompts used for question synthesis only consist of questions from seed examples. In other words, new questions are synthesized by mimicking seed questions, without any other condition.

### Implementation Details

We adopted PaL-style reasoning chains which are structured code with comments being natural language reasoning step. `text-davinci-003` version of InstructGPT [Ouyang et al., 2022] was used as our backend LLM for both synthesis and inference. We used top-p sampling [Holtzman et al., 2020] for synthesis with temperature set to 0.7, and used greedy decoding for inference with temperature set to 0. All numerical reasoning datasets share one set of seed examples either randomly sampled from GSM8K (when the number of seeds is 2 or 4) or from Wei et al. [2022b] (when the number of seeds is 8). For datasets of the other tasks, seeds were randomly sampled from their own datasets. We annotated seed examples with both CoT-style reasoning chains and PaL-style reasoning chains manually, following their annotation protocols. Annotations are provided in the Supplementary Materials. For each set of seed examples, we synthesized more examples by repeating backward-forward synthesis for 1,000 times. Target complexities range from the lowest complexity of seed examples to the highest one plus `latex $c$ `; `latex $c$ ` was set to 4 for numerical reasoning and 2 on the other datasets. In forward synthesis, the number of reasoning chains sampled for each question was 3. The encoder used for clustering was `all-mpnet-base-v2`.

### Main Results

Synthetic prompting consistently outperforms PaL prompting by up to absolute 15.6%, indicating that self-synthesized demonstrations can be leveraged to better elicit reasoning in the LLM itself, surpassing the performance of using seed demonstrations only.

Though vanilla Synthetic prompting also uses synthetic demonstrations, it fails to consistently improve over PaL prompting. On GSM8K and GSM-Hard which contain questions requiring complex deductions, vanilla Synthetic prompting can barely improve over PaL prompting, as it does not explicitly control the reasoning complexities of synthetic examples and tends to synthesize examples that are similar to seed examples in terms of complexities and informativeness. Notably, vanilla Synthetic prompting significantly underperforms PaL prompting on Repeat Copy with 2 seed examples. We found that 2 selected demonstrations have ill-formed questions, e.g., _Repeat the sentence "The sun is bright" five times, with a different emphasis on a different word each time_. This may be because questions are synthesized without explicit awareness of their reasoning chains. Section 4.6.1 shows the benefits of controlling question synthesis with various conditions.

We also observe that increasing the number of seed examples from 2 to 8 does not significantly improve performance, especially on GSM8K and Repeat Copy. Two possible reasons are as follows: (1) Example synthesis are biased by seed examples. With limited seeds, it is possible that synthesized examples are not diverse enough, and are still helpless on some portion of test questions. (2) Though our proposed demonstration selection scheme is effective (see analysis in Section 4.6.2), it is probably suboptimal, failing to make the best of synthesized examples.

### Ablation Studies

We mainly conducted ablation studies on GSM8K and the Colored Objects task.

#### Conditions Used for Question Synthesis

In backward synthesis, we ask the LLM to sample a question conditioned on a topic, a target complexity, and a sampled reasoning chain. To analyze the effect of each condition on question synthesis, we removed corresponding lines in the prompts. Notably, when removing the target complexity, number markers of reasoning steps are also removed. Removing any condition leads to degraded model performance on both GSM8K and Colored Objects.

We further investigated how different conditions affect the quality of synthetic examples, in terms of (1) **diversity**, measured by the maximum pair-wise cosine similarity between a synthetic example and the others on average, (2) **complexity**, measured by the average number of reasoning steps, (3) and **correctness**, measured by the portion of demonstrations used for inference that are correct. **Removing topic words** results in less diverse synthetic examples. Reasoning patterns of selected demonstrations are limited too; although all demonstrations are correct, 62.5% of questions revolve around _discount_ or _tax_. **Removing target complexities** produces much simpler synthetic examples. Synthesizing questions **without conditioned on reasoning chains** affects correctness negatively; 62.5% are flawed, 80% of which are unanswerable, e.g.,

_An image is represented by a 4x4 matrix of integers. Each cell of the matrix contains a single integer between 0 and 255. What is the average value of all the integers in the matrix?_.

Notably, though we also include target complexities into the prompts when synthesizing questions without conditioned on reasoning chains, the resulting questions tend to require less reasoning steps than Synthetic prompting, indicating that conditioning on numbered reasoning steps can control reasoning complexities better.

#### Schemes of Demonstration Selection

To make good use of synthesized examples, having an effective selection scheme matters. We evaluated the following 6 selection schemes. (1) **Random**: randomly selects demonstrations; (2) **Cluster Centroid**: selects the example closest to each cluster centroid; (3) **Similarity**: retrieves the most similar examples according to cosine similarity; (4) **In-Cluster Similarity**: select the most similar example from each cluster; (5) **Complexity**: selects the examples with the most reasoning steps; (6) **In-Cluster Complexity**: selects the most complex example from each cluster.

Though most selection schemes achieve better performance than PaL prompting, complexity-based selection schemes are the most effective on the two reasoning tasks, with some other schemes like Random lagging far behind. Our proposed In-Cluster Complexity outperforms Complexity, showing the benefits of using diverse and complex demonstrations.

#### Sensitivity to Seed Examples

[IMAGE: Figure 2 - sensitivity.pdf - Sensitivity analysis on GSM8K and Colored Objects. We experimented with another two random sets of seed examples of size 2 and 4 for each dataset.]

To investigate how sensitive Synthetic prompting is to seed examples, we repeated experiments on another two random sets of seed examples. Synthetic prompting consistently outperforms PaL prompting on different runs. However, we observed that seed examples with better PaL prompting performance does not necessarily lead to better Synthetic prompting performance.

### Comparison with Selecting from Training Examples

To measure the performance gap between using synthetic demonstrations and using gold demonstrations from a large set of carefully-curated examples, we selected 8 demonstrations from the training set of GSM8K with the two complexity-based selection schemes (i.e., Complexity and In-Cluster Complexity in Section 4.6.2), respectively. As the training examples were annotated with natural language reasoning chains (CoT-style reasoning), we measured the numbers of natural language reasoning steps as reasoning complexities for complexity-based selection, and manually annotated selected examples with PaL-style reasoning chains for PaL prompting. As the training examples of GSM8K are diverse, both Complexity and In-Cluster Complexity select diverse and informative demonstrations, and yield an accuracy of 77.0% on the test set of GSM8K, surpassing our accuracy of 75.3% by absolute 1.7%. As shown in the Supplementary Materials, compared with our synthetic demonstrations, the selected gold demonstrations are more logically complex with less straightforward reasoning, which may be more informative to LLMs.

Notably, using the 8 simple demonstrations from Wei et al. [2022b] that were manually crafted without prompt engineering results in an even lower accuracy of 71.8%. This indicates that demonstrations indeed matters. Under scenarios with access to only limited and possibly-simple examples, automatically synthesizing examples for selecting more effective demonstrations serves as a promising way to elicit better reasoning in LLMs.

### Quality Analysis of Synthetic Examples

To investigate the quality of synthesized examples, we conducted manual evaluation on GSM8K. We evaluated 25 random examples synthesized by Synthetic prompting and vanilla Synthetic prompting, respectively. Compared with vanilla Synthetic prompting, Synthetic prompting synthesizes questions of higher complexities (8.3 vs. 5.4) and also with lower error rate (8% vs. 24%).

We further analyze the quality of selected synthetic demonstrations. For Synthetic prompting, all selected demonstrations are correct, while its vanilla version has one unanswerable question and another one with wrong reasoning.

For vanilla Synthetic prompting, the first two questions are logically close to seed questions, and the third one is unanswerable. With Synthetic prompting, the LLM can synthesize on-topic questions requiring novel reasoning patterns, e.g., the second question about `office` requires geometric reasoning.

## Conclusion

We introduce Synthetic prompting, a novel technique for reasoning with large language models using few examples, that differs from previous work by using the models as generators of additional examples besides as consumers of in-context demonstrations. We show that by prompting a large language model to synthesize more examples, we can improve its reasoning performance on numerical, symbolic, and algorithmic tasks, compared to existing prompting methods such as chain-of-thought prompting and PaL prompting.
