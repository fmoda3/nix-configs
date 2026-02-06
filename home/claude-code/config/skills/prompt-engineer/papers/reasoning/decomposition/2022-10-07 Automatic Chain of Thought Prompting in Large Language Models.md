# Automatic Chain of Thought Prompting in Large Language Models

**Authors:** Zhuosheng Zhang (Shanghai Jiao Tong University), Aston Zhang, Mu Li, Alex Smola (Amazon Web Services)

**arXiv:** 2210.03493

---

## Abstract

Large language models (LLMs) can perform complex reasoning by generating intermediate reasoning steps. Providing these steps for prompting demonstrations is called chain-of-thought (CoT) prompting. CoT prompting has two major paradigms. One leverages a simple prompt like "Let's think step by step" to facilitate step-by-step thinking before answering a question. The other uses a few manual demonstrations one by one, each composed of a question and a reasoning chain that leads to an answer. The superior performance of the second paradigm hinges on the hand-crafting of task-specific demonstrations one by one. We show that such manual efforts may be eliminated by leveraging LLMs with the "Let's think step by step" prompt to generate reasoning chains for demonstrations one by one, i.e., *let's think not just step by step, but also one by one*. However, these generated chains often come with mistakes. To mitigate the effect of such mistakes, we find that diversity matters for automatically constructing demonstrations. We propose an automatic CoT prompting method: Auto-CoT. It samples questions with diversity and generates reasoning chains to construct demonstrations. On ten public benchmark reasoning tasks with GPT-3, Auto-CoT consistently matches or exceeds the performance of the CoT paradigm that requires manual designs of demonstrations. Code is available at https://github.com/amazon-research/auto-cot

---

## 1. Introduction

Large language models (LLMs) [brown2020language; lamda; gopher; palm] have performed impressively on complex reasoning tasks by decomposing the multi-step problems into intermediate steps before producing the answer. This reasoning process is elicited by a very recent technique: chain-of-thought (CoT) prompting [cot_wei].

[IMAGE: fig_example.pdf - Zero-Shot-CoT (using the "Let's think step by step" prompt) and Manual-CoT (using manually designed demonstrations one by one) with example inputs and outputs of an LLM.]

CoT prompting can be categorized into two major paradigms. One adds a single prompt like "Let's think step by step" after the test question to facilitate the reasoning chains in LLMs [kojima2022large]. Since this prompting paradigm is task-agnostic and does not need input-output demonstrations, it is called **Zero-Shot-CoT**. With Zero-Shot-CoT, LLMs have shown to be decent zero-shot reasoners. The other paradigm is few-shot prompting with manual reasoning demonstrations one by one [cot_wei]. Each *demonstration* has a question and a reasoning chain. A *reasoning chain* is composed of a *rationale* (a series of intermediate reasoning steps) and an expected answer. With all the demonstrations being manually designed, this paradigm is referred to as **Manual-CoT**.

In practice, Manual-CoT has obtained stronger performance than Zero-Shot-CoT [cot_wei; kojima2022large]. However, this superior performance hinges on the hand-drafting of effective demonstrations. Specifically, the hand-drafting involves nontrivial efforts in designs of both questions and their reasoning chains for demonstrations. Moreover, human efforts for designing task-specific demonstrations are even more: different tasks, such as arithmetic [multiarith] and commonsense reasoning [commonsenseqa], require different ways of demonstrations.

To eliminate such manual designs, we advocate another **Auto-CoT** paradigm to automatically construct demonstrations with questions and reasoning chains. Specifically, Auto-CoT leverages LLMs with the "Let's think step by step" prompt to generate reasoning chains for demonstrations one by one, i.e., *let's think not just step by step, but also one by one*. However, we find that this challenge cannot be effectively addressed by simple solutions. For example, given a test question of a dataset, retrieving semantically similar questions and invoking Zero-Shot-CoT to generate reasoning chains will fail. Although LLMs are decent zero-shot reasoners, they are not perfect: Zero-Shot-CoT can still make mistakes in reasoning chains.

To mitigate the effect of reasoning chain mistakes from Zero-Shot-CoT, our analysis shows that diversity of demonstration questions is the key. Based on this insight, we propose an Auto-CoT method to automatically construct demonstrations. Auto-CoT consists of two main steps. First, partition questions of a given dataset into a few clusters. Second, select a representative question from each cluster and generate its reasoning chain using Zero-Shot-CoT with simple heuristics.

We evaluate Auto-CoT on ten benchmark reasoning tasks including: (i) arithmetic reasoning (MultiArith [multiarith], GSM8K [gsm8k], AQUA-RAT [aqua], SVAMP [svamp]); (ii) commonsense reasoning (CSQA [commonsenseqa], StrategyQA [strategyqa]); (iii) symbolic reasoning (Last Letter Concatenation, Coin Flip) [cot_wei]. Experimental results show that with GPT-3, Auto-CoT consistently matches or exceeds the performance of Manual-CoT that requires manual designs. This indicates that LLMs can perform CoT reasoning by automatically constructing demonstrations.

---

## 2. Related Work

This section reviews two lines of research that form the basis of this work: chain-of-thought (CoT) prompting for multi-step reasoning and in-context learning for inducing LLMs to learn from demonstrations.

### 2.1 Chain-of-thought Prompting

CoT prompting is a gradient-free technique of inducing LLMs to produce intermediate reasoning steps that lead to the final answer. [cot_wei] formally studied the topic of CoT prompting in language models. This technique elicits LLMs to generate a coherent series of intermediate reasoning steps that lead to the final answer to a question. Studies have shown that LLMs can perform CoT reasoning with zero-shot prompting (Zero-Shot-CoT) [kojima2022large] or manually written few-shot demonstrations (Manual-CoT) [cot_wei].

**Zero-Shot-CoT.** [kojima2022large] showed that LLMs are decent zero-shot reasoners whose generated rationales have already reflected the CoT reasoning. This finding inspires our work to leverage the self-generated rationales for demonstrations. Generating rationales by LLMs was shown to be practical in a recent work [zelikman2022star]. In their work, an LLM is prompted to generate rationales and those rationales that lead to the correct answer are selected. The selection requires a training dataset of questions with annotated answers. In contrast, our work considers a more challenging scenario where only a set of test questions are given (without a training dataset), following CoT prompting studies by [cot_wei] and [kojima2022large].

**Manual-CoT.** Manual-CoT achieves stronger performance by eliciting the CoT reasoning ability with effective manual demonstrations. The demonstrations for the reasoning process are manually designed. However, the human efforts in designs of both questions and their reasoning chains are nontrivial. Instead of addressing this limitation, recent studies mainly focus on hand-crafting more complex demonstrations or leveraging ensemble-like methods. One trend is problem decomposition. In least-to-most prompting [zhou2022least], complex problems are reduced to sub-problems, and then the sub-problems are solved sequentially. The other trend is to vote over multiple reasoning paths for a test question. [cot_wei_sc] introduced a self-consistency decoding strategy to sample multiple outputs of LLMs and then took a majority over the final answers. [wang2022rationale] and [li2022advance] introduced randomness in the input space to produce more diverse outputs for voting. They used manually-designed demonstrations as the seed set and generated additional rationales: leave one question from the seed set and use the remaining demonstrations to generate rationales for this question by the LLM. Unlike the aforementioned research lines that rely on manually-designed demonstrations, our work intends to eliminate manual designs with competitive performance.

### 2.2 In-Context Learning

CoT prompting is closely related to in-context learning (ICL) [Radford2019LanguageMA; brown2020language]. ICL enables LLMs to perform a target task by feeding a few prompted examples as part of the input. Without gradient update, ICL allows a single model to perform various tasks universally. There are various research lines to improve the performance of ICL: (i) retrieving related demonstrations to the test instance where the popular practice is dynamically retrieving related training examples for a given test input [rubin2021learning; Su2022SelectiveAM]; (ii) augmenting with fine-grained information, such as incorporating task instruction [mishra2022cross; wei2022finetuned; sanh2022multitask]; (iii) manipulating output probabilities of LLMs instead of directly computing the likelihood of target labels [holtzman2021surface; zhao2021calibrate; min2022noisy].

Despite the success of ICL, studies [liu2022makes; lu2022fantastically] have shown that the strength of ICL may vary widely depending on the choice of in-context demonstrations [liu2022few]. In detail, the formatting of the prompt, such as wording or order of demonstrations, may lead to performance fluctuations [webson2021prompt; zhao2021calibrate]. A recent work [min2022rethinking] even questioned the necessity of ground-truth input-output mapping: using incorrect labels in the examples only marginally lowers the performance. However, the existing analysis of ICL is mainly based on standard classification and multi-choice datasets that only have simple <input->output> mappings. We discover that those findings may not be applicable to the CoT prompting scenario with more complex <input->rationale->output> mappings. For example, mistakes in either the <input->rationale> mapping or the <rationale->output> mapping will lead to a dramatic performance drop.

---

## 3. Challenge of Auto-CoT

As just discussed, the performance of ICL hinges on hand-crafted demonstrations. As reported in Manual-CoT [cot_wei], using demonstrations written by different annotators brings up to 28.2% accuracy disparity in a symbolic reasoning task, while changing the order of demonstrations results in less than 2% changes in most tasks. This suggests that the key challenge of Auto-CoT lies in automatically constructing demonstrations with *good* questions and their reasoning chains.

Recall that Manual-CoT hand-crafts a few (e.g., 8) questions in demonstrations. With similarity-based retrieval methods being widely adopted for prompting LLMs [rubin2021learning; Su2022SelectiveAM], a promising candidate solution is to sample demonstration questions using similarity-based retrieval. We follow the more challenging assumption in CoT studies [cot_wei; kojima2022large] that only a set of test questions are given (without a training dataset). Following [liu2022makes], we use Sentence-BERT [reimers-2019-sentence-bert] to encode questions. For each question ```latex $q^\text{test}$ ``` in a test dataset, we sample demonstration questions ```latex $q^\text{demo}_i$ ``` (```latex $i = 1, \ldots, k$ ```) from the rest of the questions. We design a **Retrieval-Q-CoT** method to retrieve the top-k (e.g., k=8) similar questions based on cosine similarity. To compare with this similarity-based method, we also test a relatively more diversity-based method: **Random-Q-CoT**, which randomly samples k other test questions for each test question.

**Table: Accuracy (%) of different sampling methods**

| Method | MultiArith | GSM8K | AQuA |
|--------|------------|-------|------|
| Zero-Shot-CoT | 78.7 | 40.7 | 33.5 |
| Manual-CoT | **91.7** | 46.9 | 35.8 |
| Random-Q-CoT | 86.2 | 47.6 | 36.2 |
| Retrieval-Q-CoT | 82.8 | **48.0** | **39.7** |

Both Retrieval-Q-CoT and Random-Q-CoT invoke Zero-Shot-CoT [kojima2022large] to generate the reasoning chain ```latex $c^\text{demo}_i$ ``` (rationale and answer) for each sampled question ```latex $q^\text{demo}_i$ ```, as LLMs are decent zero-shot reasoners [kojima2022large]. We use GPT-3 [brown2020language] with 175B parameters (text-davinci-002) for the LLM unless otherwise stated.

To our surprise, Retrieval-Q-CoT underperforms Random-Q-CoT on the arithmetic dataset MultiArith [multiarith]. Note that the retrieval methods were originally proposed in tasks with *annotated* labels [rubin2021learning; Su2022SelectiveAM], however, invoking Zero-Shot-CoT does not guarantee entirely correct reasoning chains. Thus, we hypothesize that the inferior performance of Retrieval-Q-CoT is caused by incorrect reasoning chains by Zero-Shot-CoT.

Although human annotations are useful, such manual efforts are nontrivial. However, automatically generating reasoning chains via Zero-Shot-CoT underperforms Manual-CoT, especially when the challenge of question sampling is not addressed. To design more effective Auto-CoT, we need to understand its challenge better.

### 3.1 Retrieval-Q-CoT Fails due to Misleading by Similarity

Since Retrieval-Q-CoT uses a few prompting demonstrations like in Manual-CoT, Retrieval-Q-CoT is expected to perform competitively as well. However, reasoning chains (both rationales and answers) in Retrieval-Q-CoT are generated by Zero-Shot-CoT: they may have mistakes that lead to wrong answers. Let us simply call demonstrations with wrong answers as *wrong demonstrations*. Intuitively, after *similar* questions to a test question are retrieved, wrong demonstrations caused by Zero-Shot-CoT may mislead the same LLM to reason similarly with a wrong answer (e.g., replicating mistakes) for the test question. We refer to this phenomenon as *misleading by similarity*. We will investigate whether misleading by similarity contributes to the inferior performance of Retrieval-Q-CoT.

To begin with, we invoke Zero-Shot-CoT on all the 600 questions from the MultiArith dataset. Among them, we collect those 128 questions (denoted as ```latex $\mathcal{Q}$ ```) where Zero-Shot-CoT generates wrong answers (error rate: 21.3% = 128/600). As we mentioned, with extra demonstrations, Retrieval-Q-CoT and Random-Q-CoT are expected to perform more competitively than Zero-Shot-CoT. Among ```latex $\mathcal{Q}$ ``` where Zero-Shot-CoT fails, we call those where Retrieval-Q-CoT or Random-Q-CoT still fail as their *unresolved questions*. We divide the number of unresolved questions by 128 (number of questions in ```latex $\mathcal{Q}$ ```) to calculate the *unresolving rate*. A higher unresolving rate means that a method more likely still makes mistakes like Zero-Shot-CoT.

**Unresolving Rate:**
- Retrieval-Q-CoT: 46.9%
- Random-Q-CoT: 25.8%

It indicates that with similar questions being sampled for test questions, Retrieval-Q-CoT is negatively affected by misleading by similarity.

**Case Study - Retrieval-Q-CoT vs Random-Q-CoT:**

*Retrieval-Q-CoT Example:*
- Q: A chef needs to cook 9 potatoes. He has already cooked 7. If each potato takes 3 minutes to cook, how long will it take him to cook **the rest**?
- A: Let's think step by step. The chef has already cooked 7 potatoes. That means it has taken him 7 * 3 minutes to cook those 7 potatoes. That means it will take him 3 more minutes to cook each of the remaining 2 potatoes. That means it will take him a total of 7 * 3 + 2 * 3 = 21 minutes to cook all 9 potatoes. The answer is 21. [WRONG]

*Random-Q-CoT Example:*
- Q: Wendy uploaded 79 pictures to Facebook. She put 44 pics into one album and put the rest into 5 different albums. How many pictures were in each album?
- A: Let's think step by step. Wendy uploaded 79 pictures to Facebook. She put 44 pictures into one album. That means she put the rest of the pictures into 5 different albums. That means each album would have (79-44)/5 = 15 pictures in each album. The answer is 15. [CORRECT]

In the left part, the retrieved demonstration questions are similar to the test question and ask "how long will it take him to cook the rest?" The reasoning chains generated by Zero-Shot-CoT produce answers regarding "the total of" instead of "the rest". Following the demonstrations, Retrieval-Q-CoT also fails by misunderstanding the meaning of "the rest". In contrast, Random-Q-CoT correctly understands "the rest" better without making similar mistakes in the demonstrations, thanks to relatively more diverse (random) demonstrations.

### 3.2 Errors Frequently Fall into the Same Cluster

Motivated by the observations above, we use k-means to partition all the 600 test questions into k=8 clusters, where each cluster contains similar questions. We use Sentence-BERT [reimers-2019-sentence-bert] to encode questions and apply k-means for clustering. With these clusters and reasoning chains generated by Zero-Shot-CoT, now we are curious if certain clusters contain questions where Zero-Shot-CoT frequently fails. Thus, we calculate the error rate (questions with wrong Zero-Shot-CoT answers / total questions) for each cluster.

**Error Rate by Cluster (MultiArith):**
- Cluster 1: 9%
- Cluster 2: 52%
- Cluster 3: 16%
- Cluster 4: 13%
- Cluster 5: 16%
- Cluster 6: 22%
- Cluster 7: 29%
- Cluster 8: 22%

There exists a cluster (Cluster 2) with frequent Zero-Shot-CoT errors (52.3%). The phenomenon could be generic as Zero-Shot-CoT may lack some skills to solve some common problems in target tasks. For convenience of descriptions, let us call the cluster with the highest error rate as the *frequent-error cluster*. Therefore, the imperfect nature of generated reasoning chains in a zero-shot fashion poses risks of retrieving multiple similar questions inside a frequent-error cluster by using similarity-based methods. For the test question in the frequent-error cluster, Retrieval-Q-CoT more easily constructs demonstrations with multiple similar mistakes.

### 3.3 Diversity May Mitigate Misleading by Similarity

The analysis so far compellingly shows that LLMs are still not *perfect* zero-shot reasoners; thus, we aim to mitigate the effect of their Zero-Shot-CoT errors, especially to mitigate misleading by similarity in the design of Auto-CoT.

Presenting a small portion of mistakes (e.g., 1 or 2 wrong demonstrations out of 8) would not harm the overall reasoning performance for test questions. Suppose that questions of all the wrong demonstrations fall into the same frequent-error cluster; then sampling one question from every different cluster will lead to a higher than 7/8=87.5% chance to construct all the 8 correct demonstrations. Since different clusters reflect diverse semantics of the questions, this clustering-based sampling method can be considered as diversity-based, which is in sharp contrast to similarity-based Retrieval-Q-CoT. On one hand, sampling questions with diversity may mitigate the effect of misleading by similarity. On the other hand, if we took each demonstration as a kind of skill, diverse demonstrations seem to cover more alternative skills for solving target questions: even though there still exists a small portion (e.g., 1/8) of mistakes in the demonstrations, the performance will not be negatively affected.

Nevertheless, the clustering-based sampling method may still construct a small portion of wrong demonstrations, such as from questions in the frequent-error cluster. Some of these wrong demonstrations may be eliminated with heuristics. For example, wrong demonstrations often come with long questions and long rationales. Using simple and generic heuristics, such as only considering shorter questions with shorter rationales, further helps mitigate the effect of imperfect Zero-Shot-CoT capabilities.

---

## 4. Auto-CoT: Automatic Chain-of-Thought Prompting

Based on the observations and considerations in Section 3, we propose an **Auto-CoT** method to construct demonstrations with questions and reasoning chains automatically. Auto-CoT consists of two main stages: (i) question clustering: partition questions of a given dataset into a few clusters; (ii) demonstration sampling: select a representative question from each cluster and generate its reasoning chain using Zero-Shot-CoT with simple heuristics.

[IMAGE: fig_model.pdf - Overview of the Auto-CoT method. Different from Manual-CoT, demonstrations (on the right) are automatically constructed one by one (total: k) using an LLM with the "Let's think step by step" prompt.]

### 4.1 Question Clustering

Since diversity-based clustering may mitigate misleading by similarity, we perform cluster analysis for a given set of questions ```latex $\mathcal{Q}$ ```. We first compute a vector representation for each question in ```latex $\mathcal{Q}$ ``` by Sentence-BERT [reimers-2019-sentence-bert]. The contextualized vectors are averaged to form a fix-sized question representation. Then, the question representations are processed by the k-means clustering algorithm to produce k clusters of questions. For questions in each cluster i, sort them into a list ```latex $\mathbf{q}^{(i)} = [q_1^{(i)}, q_2^{(i)}, \ldots]$ ``` in the ascending order of the distance to the center of cluster i.

**Algorithm 1: Cluster**
- **Require:** A set of questions ```latex $\mathcal{Q}$ ``` and the number of demonstrations k
- **Ensure:** Sorted questions ```latex $\mathbf{q}^{(i)} = [q_1^{(i)}, q_2^{(i)}, \ldots]$ ``` for each cluster i (i = 1, ..., k)
1. For each question q in ```latex $\mathcal{Q}$ ```: Encode q by Sentence-BERT
2. Cluster all the encoded question representations into k clusters
3. For each cluster i = 1, ..., k: Sort questions in ascending order of distance to cluster center
4. Return sorted questions for each cluster

### 4.2 Demonstration Sampling

In the second stage, we need to generate reasoning chains for those sampled questions and then sample demonstrations that satisfy our selection criteria.

More concretely, we construct a demonstration ```latex $d^{(i)}$ ``` (concatenation of a question, a rationale, and an answer) for each cluster i (i=1,..., k). For cluster i, we iterate over questions in the sorted list ```latex $\mathbf{q}^{(i)}$ ``` (obtained by Algorithm 1) until satisfying our selection criteria. In other words, a question that is closer to the center of cluster i is considered earlier. Say that the j-th closest question ```latex $q_j^{(i)}$ ``` is being considered. A prompted input is formulated as: [Q: ```latex $q_j^{(i)}$ ```. A: [P]], where [P] is a single prompt "Let's think step to step". This formed input is fed into an LLM using Zero-Shot-CoT [kojima2022large] to output the reasoning chain consisting of the rationale ```latex $r_j^{(i)}$ ``` and the extracted answer ```latex $a_j^{(i)}$ ```. Then, a candidate demonstration ```latex $d_j^{(i)}$ ``` for the i-th cluster is constructed by concatenating the question, rationale, and answer.

Similar to the criteria of the hand-crafting demonstrations in [cot_wei], our selection criteria follow simple heuristics to encourage sampling simpler questions and rationales: set the selected demonstration ```latex $d^{(i)}$ ``` as ```latex $d_j^{(i)}$ ``` if it has a question with no more than 60 tokens and a rationale with no more than 5 reasoning steps. Because Zero-Shot-CoT often uses "\n" for separating the reasoning steps, the rule can be easily implemented by counting the "\n" tokens in the generated rationales.

**Algorithm 2: Construct**
- **Require:** Sorted questions for each cluster, empty demonstration list d
- **Ensure:** Demonstration list ```latex $\mathbf{d} = [d^{(1)}, \ldots, d^{(k)}]$ ```
1. For each cluster i = 1, ..., k:
   - For each question in sorted list:
     - Generate rationale and answer using Zero-Shot-CoT
     - If question and rationale satisfy selection criteria:
       - Add demonstration to d
       - break
2. Return d

After demonstration sampling for all the k clusters, there will be k constructed demonstrations. The constructed demonstrations are used to augment a test question ```latex $q^{\text{test}}$ ``` for in-context learning. Specifically, the input is the concatenation of all the demonstrations followed by [Q: ```latex $q^{\text{test}}$ ```. A: [P]]. This input is fed to LLMs to obtain the reasoning chain with the answer in the end for ```latex $q^{\text{test}}$ ```.

---

## 5. Experiments

We briefly describe the experimental setup and present main experimental results.

### 5.1 Experimental setup

**Tasks and Datasets.** Our method is evaluated on ten benchmark datasets from three categories of reasoning tasks: (i) arithmetic reasoning (MultiArith [multiarith], GSM8K [gsm8k], AddSub [addsub], AQUA-RAT [aqua], SingleEq [koncel2015parsing], SVAMP [svamp]); (ii) commonsense reasoning (CSQA [commonsenseqa], StrategyQA [strategyqa]); (iii) symbolic reasoning (Last Letter Concatenation, Coin Flip) [cot_wei].

**Implementation.** We use the public GPT-3 [brown2020language] of the text-davinci-002 version with 175B parameters for the LLM [instructgpt] unless otherwise stated. We select this LLM because it has the strongest CoT reasoning performance among public LLMs. We also evaluate the Codex model [chen2021evaluating] (code-davinci-002) as the LLM. Following [cot_wei], the number of demonstrations k is 8 except for AQuA and Letter (4), CSQA (7), and StrategyQA (6).

**Baselines.** We compare our methods with four baseline methods: Zero-Shot [kojima2022large], Zero-Shot-CoT [kojima2022large], Few-Shot [cot_wei], and Manual-CoT [cot_wei]. The Zero-Shot baseline concatenates a test question with the prompt "The answer is" as the LLM input. The Few-Shot baseline has the same LLM input as Manual-CoT except for removed rationales from all the demonstrations.

### 5.2 Main Results: Accuracy on Ten Datasets

**Table: Accuracy on ten datasets from three categories of reasoning tasks**

| Model | MultiArith | GSM8K | AddSub | AQuA | SingleEq | SVAMP | CSQA | Strategy | Letter | Coin |
|-------|------------|-------|--------|------|----------|-------|------|----------|--------|------|
| Zero-Shot | 22.7 | 12.5 | 77.0 | 22.4 | 78.7 | 58.8 | 72.6 | 54.3 | 0.2 | 53.8 |
| Zero-Shot-CoT | 78.7 | 40.7 | 74.7 | 33.5 | 78.7 | 63.7 | 64.6 | 54.8 | 57.6 | 91.4 |
| Few-Shot | 33.8 | 15.6 | 83.3 | 24.8 | 82.7 | 65.7 | **79.5** | **65.9** | 0.2 | 57.2 |
| Manual-CoT | 91.7 | 46.9 | 81.3 | 35.8 | 86.6 | 68.9 | 73.5 | 65.4 | 59.0 | 97.2 |
| Auto-CoT | **92.0** | **47.9** | **84.8** | **36.5** | **87.0** | **69.5** | 74.4 | 65.4 | **59.7** | **99.9** |

The Zero-Shot and Zero-Shot-CoT results are taken from [kojima2022large], the Few-Shot and Manual-CoT results are taken from [cot_wei], and the Auto-CoT results are averaged over three random runs. Overall, Auto-CoT consistently matches or exceeds the performance of the CoT paradigm that requires manual designs of demonstrations. Due to the cost of manual designs, Manual-CoT may design the same demonstrations for multiple datasets (e.g., 5/6 of the arithmetic datasets). In contrast, Auto-CoT is more flexible and task-adaptive: every single dataset gets its own demonstrations that are automatically constructed.

### 5.3 Visualization of Question Clustering

[IMAGE: fig_vis.pdf - Question clustering on ten datasets of reasoning tasks. Stars denote cluster centers.]

The visualization indicates that there exist generic patterns, where different patterns may be characterized by questions from different clusters.

### 5.4 General Effectiveness Using the Codex LLM

**Table: Accuracy using the Codex LLM**

| Method | MultiArith | GSM8K | AddSub |
|--------|------------|-------|--------|
| Zero-Shot-CoT | 64.8 | 31.8 | 65.6 |
| Manual-CoT | **96.8** | 59.4 | 84.6 |
| Auto-CoT | 93.2 | **62.8** | **91.9** |

To evaluate the general effectiveness of Auto-CoT using different LLMs, here we change the LLM to the Codex model [chen2021evaluating]. The Codex LLM leads to performance improvement for Manual-CoT when compared with GPT-3 (text-davinci-002). Nonetheless, using the Codex LLM, the overall performance of Auto-CoT is still competitive compared to Manual-CoT, providing additional empirical evidence for the effectiveness of Auto-CoT.

### 5.5 Effect of Wrong Demonstrations

To see if diversity mitigates this effect, we design an In-Cluster Sampling baseline that constructs demonstrations by randomly sampling questions from the same cluster that contains a test question.

**Effect of wrong demonstrations on MultiArith:**
- At 12.5% wrong demonstrations: In-Cluster Sampling 91.2%, Auto-CoT 93.7%
- At 25.0% wrong demonstrations: In-Cluster Sampling 88.0%, Auto-CoT 93.3%
- At 37.5% wrong demonstrations: In-Cluster Sampling 83.5%, Auto-CoT 89.8%
- At 50.0% wrong demonstrations: In-Cluster Sampling 80.5%, Auto-CoT 90.2%

Compared with In-Cluster Sampling, Auto-CoT (using diversity-based clustering) is less affected by wrong demonstrations: its performance still does not degrade significantly even when presented with 50% wrong demonstrations.

### 5.6 More Challenging Streaming Setting

CoT studies commonly assume that a full dataset with test questions is given [cot_wei; kojima2022large]. Based on the given dataset, Auto-CoT samples questions to construct the demonstrations. Nonetheless, now we consider a more challenging *streaming setting* where a small batch of test questions (say m questions) arrive at a time like in data streams.

To address this challenge, we extend Auto-CoT to a bootstrapping version Auto-CoT*:
1. Initialize an empty set M_0
2. When batch 1 of questions arrive, invoke Zero-Shot-CoT (no clustering due to small m) for each question to obtain its reasoning chain. Add question-chain pairs to M_0 and call the new set M_1
3. When batch b (b>1) of questions arrive, construct demonstrations with existing questions and reasoning chains in M_{b-1} (like Auto-CoT) and use the demonstrations for in-context reasoning. Add question-chain pairs to M_{b-1} and call the new set M_b.

As expected, for batch 1, Auto-CoT* and Zero-Shot-CoT obtain equal accuracy. From batch 2, Auto-CoT* performs comparably with Manual-CoT. This result indicates that our method is still effective in the more challenging streaming setting.

---

## 6. Conclusion

LLMs have shown reasoning capabilities with CoT prompting. The superior performance of Manual-CoT hinges on the hand-crafting of demonstrations. To eliminate such manual designs, we proposed Auto-CoT to automatically construct demonstrations. It samples questions with diversity and generates reasoning chains to construct demonstrations. Experimental results on ten public benchmark reasoning datasets showed that with GPT-3, Auto-CoT consistently matches or exceeds the performance of the CoT paradigm that requires manual designs of demonstrations.

---

## Appendix A: Extended Analysis for the Challenge of Auto-CoT

### A.1 Impact of Demonstration Elements

A demonstration is a triple composed by <question, rationale, answer>. We shuffle either of the demonstration components to see how the performance changes.

**Table: Impact of different components in the demonstrations**

| Method | Accuracy |
|--------|----------|
| Manual-CoT | 91.7 |
| Shuffle Questions | 73.8 |
| Shuffle Rationales | 43.8 |
| Shuffle Answers | 17.0 |

According to the results, shuffling questions has the least performance reduction (91.7% -> 73.8%). A possible reason for the decent performance is that the model may capture the rationale-answer mapping patterns. The pattern is expected to reflect how the intermediate reasoning steps can lead to the final answer. This finding shows that it is possible to leverage the generated rationales by Zero-Shot-CoT because those rationales are often logically correct even though they may lead to wrong answers [kojima2022large].

In contrast, shuffling either rationales or answers reduces the accuracy significantly (91.7% -> 43.8%/17.0%). The observation indicates that the rationale-answer consistency is critical. This kind of mismatch actually happens in Zero-Shot-CoT. Using such demonstrations might teach the model illusion---predicting answers without basis.

### A.2 Observation of Frequent-Error Clusters

To verify if Zero-Shot-CoT fails at similar problems, we cluster the questions into a few clusters and calculate the error rate of the answers to the questions in each cluster. The mistakes tend to gather in one or more clusters across different datasets. We observe a similar phenomenon when the cluster number changes. The phenomenon has shown to be generic that Zero-Shot-CoT may lack some skills to solve some common problems in target tasks. We call the cluster with the highest error rate as a frequent-error cluster. Therefore, the imperfect nature of generated reasoning chains poses risks of retrieving a set of similar questions inside the frequent-error cluster for similarity-based retrieval.

---

## Appendix B: Experimental Details

### B.1 Tasks and Datasets

Our method is evaluated on ten benchmark datasets that cover arithmetic reasoning, commonsense reasoning, and symbolic reasoning tasks.

**Table: Dataset Description**

| Dataset | Number of samples | Average words | Answer Format | License |
|---------|-------------------|---------------|---------------|---------|
| MultiArith | 600 | 31.8 | Number | Unspecified |
| AddSub | 395 | 31.5 | Number | Unspecified |
| GSM8K | 1319 | 46.9 | Number | MIT License |
| AQUA | 254 | 51.9 | Multiple choice | Apache-2.0 |
| SingleEq | 508 | 27.4 | Number | No License |
| SVAMP | 1000 | 31.8 | Number | MIT License |
| CSQA | 1221 | 27.8 | Multiple choice | Unspecified |
| StrategyQA | 2290 | 9.6 | Yes or No | Apache-2.0 |
| Last Letters | 500 | 15.0 | String | Unspecified |
| Coin Flip | 500 | 37.0 | Yes or No | Unspecified |

**Arithmetic Reasoning.** For arithmetic reasoning, we consider the following six datasets: (i) MultiArith [multiarith], (ii) GSM8K [gsm8k], (iii) AddSub [addsub], (iv) AQUA [aqua], (v) SingleEq [koncel2015parsing], and (vi) SVAMP [svamp]. The first three are from the classic Math World Problem Repository [mawps], and the last three are from more recent benchmarks.

**Commonsense Reasoning.** For commonsense reasoning, we use (i) CommonsenseQA (CSQA) [commonsenseqa] and (ii) StrategyQA [strategyqa]. CommonsenseQA asks questions with complex semantics that often require reasoning based on prior knowledge. StrategyQA requires models to infer an implicit multi-hop reasoning to answer questions.

**Symbolic Reasoning.** For symbolic reasoning, we use (i) Last Letter Concatenation [cot_wei] and (ii) Coin Flip tasks [cot_wei]. Last letter Concatenation requires the model to concatenate the last letters of each word. The goal of Coin Flip is to answer whether a coin is still heads up after people either flip or do not flip the coin.

### B.2 Implementation Details

We use GPT-3 [brown2020language] of the text-davinci-002 version with 175B parameters for the LLM [instructgpt] unless otherwise stated. We select the model because it is public and is widely used to assess the ability of CoT reasoning in LLMs. The model is accessed via the OpenAI API. Experiments are run between July-2022 and September-2022 by using OpenAI API. Greedy decoding is used to generate the output. We set max_tokens = 256 and temperature = 0. Following [cot_wei], the number of demonstrations k used for in-context learning is 8 in most tasks, except for 4 in AQuA and Last Letter Concatenation, 7 in CSQA, and 6 in StrategyQA.

---

## Appendix C: Analysis

### C.1 Comparisons of Criteria for Sorting Questions

We compare different ways of sorting questions in each cluster, including: (i) minimal distance to the cluster center (In-Cluster Min Dist, as adopted in Auto-CoT), (ii) maximal distance to the cluster center (In-Cluster Max Dist), and (iii) random sampling inside the cluster (In-Cluster Random). To alleviate the influence of wrong demonstrations, we only sample the demonstrations with correct answers for this analysis.

**Table: Influence of demonstration sampling**

| Method | MultiArith |
|--------|------------|
| Auto-CoT | 93.7 |
| In-Cluster Min Dist | 93.7 |
| In-Cluster Random | 89.2 |
| In-Cluster Max Dist | 88.7 |

Comparing the results, we see that the demonstrations are generally better if they are closer to the cluster center.

### C.2 Effectiveness of the Simple Heuristics

In Section 4, we apply simple heuristics to encourage the model to use simple and accurate demonstrations. Similar to the criteria of the hand-crafting demonstrations in [cot_wei], our selection criteria follow simple heuristics to encourage sampling simpler questions and rationales: set the selected demonstration if it has a question with no more than 60 tokens and a rationale with no more than 5 reasoning steps. For arithmetic reasoning tasks except for AQuA (because it is a multiple-choice problem), we require that the answer is not empty and appears in the rationale to mitigate the risk of rationale-answer mismatches.

**Table: Average mistakes in three runs of demonstration construction**

| | MultiArith | AddSub | GSM8K | AQuA | SingleEq | SVAMP | CSQA | Strategy | Letter | Coin |
|-|------------|--------|-------|------|----------|-------|------|----------|--------|------|
| Num. of Demos | 8 | 8 | 8 | 4 | 8 | 8 | 7 | 6 | 4 | 8 |
| Simple heuristics | 0.3 | 1.7 | 1.7 | 1 | 1 | 0.7 | 2.7 | 2.3 | 0 | 0 |
| w/o heuristics | 1.3 | 5 | 3 | 2.7 | 2 | 3.3 | 3.3 | 2.3 | 3 | 1 |

We run the demonstration construction process three times before and after using simple heuristics to quantify its effect. The simple heuristics reduce the average number of wrong rationales in constructing demonstrations. Our method can keep the error rate below 20% in most tasks (7/10).

---

## Appendix D: Automatically Constructed Demonstrations

### D.1 MultiArith

**Q:** For Halloween Katie and her sister combined the candy they received. Katie had 8 pieces of candy while her sister had 23. If they ate 8 pieces the first night, how many pieces do they have left?

**A:** Let's think step by step. Katie and her sister have a total of 8 + 23 = 31 pieces of candy. If they eat 8 pieces the first night, they have 31 - 8 = 23 pieces left. The answer is 23.

**Q:** A pet store had 78 puppies. In one day they sold 30 of them and put the rest into cages with 8 in each cage. How many cages did they use?

**A:** Let's think step by step. There are 78 puppies. 30 are sold, so that means there are 48 left. 48 divided by 8 is 6, so that means there are 6 cages with 8 puppies in each. The answer is 6.

**Q:** A waiter had 14 customers to wait on. If 3 customers left and he got another 39 customers, how many customers would he have?

**A:** Let's think step by step. The waiter had 14 customers to wait on. If 3 customers left, that means he would have 11 customers left. If he got another 39 customers, that means he would have 50 customers in total. The answer is 50.

**Q:** Bianca was organizing her book case making sure each of the shelves had exactly 8 books on it. If she had 5 shelves of mystery books and 4 shelves of picture books, how many books did she have total?

**A:** Let's think step by step. There are 5 shelves of mystery books. Each shelf has 8 books. So that's 40 mystery books. There are 4 shelves of picture books. Each shelf has 8 books. So that's 32 picture books. 40 + 32 = 72 books. The answer is 72.

**Q:** Wendy uploaded 45 pictures to Facebook. She put 27 pics into one album and put the rest into 9 different albums. How many pictures were in each album?

**A:** Let's think step by step. First, we know that Wendy uploaded 45 pictures in total. Second, we know that Wendy put 27 pictures into one album. That means that Wendy put the remaining 18 pictures into 9 different albums. That means that each album would have 2 pictures. The answer is 2.

**Q:** A trivia team had 7 members total, but during a game 2 members didn't show up. If each member that did show up scored 4 points, how many points were scored total?

**A:** Let's think step by step. There were 7 members on the team, but 2 members didn't show up. That means that there were 5 members that did show up. Each member that showed up scored 4 points. So if 5 members each scored 4 points, then the total number of points scored would be 5*4=20. The answer is 20.

**Q:** Mike made 69 dollars mowing lawns over the summer. If he spent 24 dollars buying new mower blades, how many 5 dollar games could he buy with the money he had left?

**A:** Let's think step by step. Mike made $69 from mowing lawns. He spent $24 on new mower blades. That means he has $45 left. Each game costs $5, so he could buy 9 games. The answer is 9.

**Q:** The school cafeteria ordered 8 red apples and 43 green apples for students lunches. But, if only 42 students wanted fruit, how many extra did the cafeteria end up with?

**A:** Let's think step by step. The school cafeteria ordered 8 red apples and 43 green apples for students lunches. This means that they ordered a total of 51 apples. But, if only 42 students wanted fruit, This means that the school cafeteria would have 9 apples leftover. The answer is 9.

### D.2 GSM8K

**Q:** Two trains leave San Rafael at the same time. They begin traveling westward, both traveling for 80 miles. The next day, they travel northwards, covering 150 miles. What's the distance covered by each train in the two days?

**A:** Let's think step by step. On the first day, both trains travel 80 miles. So the first train covers 80 miles, and the second train covers 80 miles. On the second day, both trains travel 150 miles. So the first train covers 150 miles, and the second train covers 150 miles. In total, the first train covers 230 miles, and the second train covers 230 miles. The answer is 230.

**Q:** A tank of water has a depth of 17 feet on Monday. On Tuesday, the tank had 7 feet more water. On Wednesday, the depth of the water is two thirds of what it was on Tuesday. What is the tank's water depth on Wednesday?

**A:** Let's think step by step. On Monday, the depth was 17 feet. On Tuesday, the depth was 7 feet more than on Monday, so the depth was 24 feet. On Wednesday, the depth was two thirds of what it was on Tuesday, so the depth was 16 feet. The answer is 16.

**Q:** While at the dollar store, Sloane counts 100 customers entering the store. The next day, she counts 50 more customers than the first day. If the total number of customers by the third day was 500, how many customers did she count on the third day?

**A:** Let's think step by step. On the first day, Sloane counted 100 customers. On the second day, she counted 50 more customers than she did on the first day. So, she counted 150 customers on the second day. On the third day, she counted 500 customers. Therefore, on the third day, Sloane counted 500 customers. The answer is 500.

### D.3 StrategyQA

**Q:** Would a vegetarian be able to eat something at Chick-fil-A?

**A:** Let's think step by step. Chick-fil-A is a restaurant chain that specializes in chicken sandwiches. So right off the bat, we can say that a vegetarian probably wouldn't be able to find a sandwich that they could eat. However, Chick-fil-A does offer salads and sides that a vegetarian could eat. The answer is yes.

**Q:** Can Justin Timberlake ride Shipwreck Falls at Six Flags?

**A:** Let's think step by step. First, let's consider the height requirement for Shipwreck Falls, which is 48 inches. Next, we'll look up Justin Timberlake's height. According to various sources, Timberlake is between 5'8" and 5'11". Finally, we'll compare Timberlake's height to the height requirement for Shipwreck Falls. Since Timberlake is taller than 48 inches, he would be able to ride Shipwreck Falls. The answer is yes.

**Q:** Would a snake have reasons to fear a honey badger?

**A:** Let's think step by step. A snake's main method of attack is to coil around an animal and constrict it until it suffocates. This would be difficult to do to a honey badger, which has thick skin and is very agile. In addition, honey badgers are known to be very aggressive, and they have sharp claws and teeth that could do a lot of damage to a snake. So, it is reasonable to say that a snake would have reasons to fear a honey badger. The answer is yes.

### D.4 Last Letter Concatenation

**Q:** Take the last letters of each words in "Lesley Luna Nadia Adriana" and concatenate them.

**A:** Let's think step by step. The last letter of "Lesley" is "y". The last letter of "Luna" is "a". The last letter of "Nadia" is "a". The last letter of "Adriana" is "a". So the final answer is "yaaa". The answer is yaaa.

**Q:** Take the last letters of each words in "Alfonso Collin Amado Dick" and concatenate them.

**A:** Let's think step by step. The last letter of "Alfonso" is "o". The last letter of "Collin" is "n". The last letter of "Amado" is "o". The last letter of "Dick" is "k". So the final answer would be "onok". The answer is onok.

### D.5 Coin Flip

**Q:** A coin is heads up. Shari flips the coin. Bella flips the coin. Liza does not flip the coin. Maira does not flip the coin. Is the coin still heads up? Note that "flip" here means "reverse".

**A:** Let's think step by step. Shari flips the coin. The coin is now tails up. Bella flips the coin. The coin is now heads up. Liza does not flip the coin. The coin is still heads up. Maira does not flip the coin. The coin is still heads up. The answer is yes.

**Q:** A coin is heads up. Joyce flips the coin. Leroy flips the coin. Alyssa does not flip the coin. Maggie does not flip the coin. Is the coin still heads up? Note that "flip" here means "reverse".

**A:** Let's think step by step. Joyce flips the coin, so now it is tails up. Leroy flips the coin, so now it is heads up again. Alyssa does not flip the coin, so it remains tails up. Maggie does not flip the coin, so it remains heads up. So the final answer is yes, the coin is still heads up. The answer is yes.
