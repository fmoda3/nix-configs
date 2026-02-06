# Complexity-Based Prompting for Multi-Step Reasoning

**Authors:** Yao Fu (University of Edinburgh), Hao Peng, Ashish Sabharwal, Peter Clark, Tushar Khot (Allen Institute for AI)

**arXiv:** 2210.00720

---

## Abstract

We study the task of prompting large-scale language models to perform multi-step reasoning. Existing work shows that when prompted with a chain of thoughts (CoT), sequences of short sentences describing intermediate reasoning steps towards a final answer, large language models can generate new reasoning chains and predict answers for new inputs. A central question is which reasoning examples make the most effective prompts. In this work, we propose complexity-based prompting, a simple and effective example selection scheme for multi-step reasoning. We show that prompts with higher _reasoning complexity_, i.e., chains with more reasoning steps, achieve substantially better performance on multi-step reasoning tasks over strong baselines. We further extend our complexity-based criteria from prompting (selecting inputs) to decoding (selecting outputs), where we sample multiple reasoning chains from the model, then choose the majority of generated answers from complex reasoning chains (over simple chains). When used to prompt GPT-3 and Codex, our approach substantially improves multi-step reasoning accuracy and achieves new state-of-the-art (SOTA) performance on three math benchmarks (GSM8K, MultiArith, and MathQA) and two BigBenchHard tasks (Date Understanding and Penguins), with an average +5.3 and up to +18 accuracy improvements. Compared with existing example selection schemes like manual tuning or retrieval-based selection, selection based on reasoning complexity is intuitive, easy to implement, and annotation-efficient. Further results demonstrate the robustness of performance gains from complex prompts under format perturbation and distribution shift.

## 1. Introduction

We consider the problem of prompting large language models for multi-step reasoning. Recent breakthroughs [wei2022chain; wang2022self] show that language models, when large enough (>100B parameters), exhibit the emergent ability [wei2022emergent] of performing complex multi-step reasoning when provided with only a few reasoning examples. In the regime of large models, prompting achieves comparable or even better performance than full training set finetuning while being substantially more sample-efficient [wei2022chain; kojima2022large; lewkowycz2022solving]. In particular, Wei et al. [wei2022chain] show that chain-of-thoughts (CoT) prompts, sequences of short sentences describing intermediate reasoning steps towards final answers, can elicit strong reasoning capabilities from large language models for complex tasks such as math problems.

[IMAGE: Figure 1 - Method overview. A: Chain of thoughts (in blue) are intermediate reasoning steps towards a final answer. The input of CoT prompting is a stack of few (often 8) CoT cases before a test question. Then the language model will continue generating an output CoT for the test question. B: Chains of harder reasoning complexity are chains with more reasoning steps (9 steps in this case, v.s. only 2 steps in subfigure A). C: During decoding, we sample N reasoning chains from the language model (N=5 here), and take the majority answer over the K (K=3 here) most complex generated chains.]

This work studies _example selection_ in chain-of-thoughts multi-step reasoning. Example selection is a central problem in the prompting literature [liu-etal-2022-makes; rubin-etal-2022-learning; su2022selective; lazaridou2022internet]. It asks what instances make the best prompts for solving the tasks of interest. For CoT prompting, example selection is further related to annotation efficiency, as CoT requires manually-annotated reasoning chains. For datasets where reasoning annotations are easy to obtain, one may want to know which annotated chains make the best prompt; if the annotations are hard to obtain, one may identify the best cases to annotate, rather than annotating the entire dataset.

We propose _complexity-based prompting_, a new example selection scheme for chain-of-thoughts multi-step reasoning. Existing sample selection methods are usually based on manual tries [wei2022chain], heuristic rules [wallace-etal-2019-universal], optimization and search [shin-etal-2020-autoprompt], or retrieval from a large training set [rubin-etal-2022-learning]. Different from these schemes, complexity-based prompting chooses examples with complex reasoning chains, i.e., chains with more reasoning steps, as the prompt. Figure 1A shows a simple example with 2 reasoning steps, versus the example in subfigure B is a complex case with 9 reasoning steps. As we will show in the experiments (Section 4.2), the reasoning performance of GPT-3 175B [brown2020gpt3] clearly improves with the increased input prompt complexity, where complex prompts achieve better performance than simple prompts.

We further extend the complexity-based selection criteria from the input space (the prompts) to the output space (reasoning chains generated by the language model). Our extension is based on the idea of self-consistency [wang2022self; wang2022rationale], where they sample multiple reasoning chains (instead of using greedy decoding) from the model that lead to possibly different answers, then choose the majority of the generated answers. Here we propose _complexity-based consistency_, where instead of taking a majority vote among all generated chains, we _vote over the top K complex chains_, as shown in Figure 1C. In Section 4.2, we will show that complexity-based consistency leads to further performance gains, on top of the existing gain from complexity-based prompting.

Putting everything together, our methods achieve new state of the art performance on three math benchmarks (GSM8K, MultiArith, and MathQA) and two BigBenchHard tasks (Date Understanding and Penguins) with substantial performance gains over Wei et al. [wei2022chain]. We show that, compared with existing sample selection schemes, complexity-based prompting achieves better performance in most cases (see Section 4.2). Furthermore, performance gains from complex samples are consistent in different prompt distributions (in-distribution, transfer, and noisily-labeled, see Section 4.2) and are also consistent with regard to alternative proxies for complexity (e.g., question or formula lengths, see Section 4.3) when the dataset does not contain annotated reasoning chains. A careful analysis shows that the number of reasoning steps is the most prominent factor, over confounders like prompt lengths or the number of input cases (Section 4.3). We hope this work will open new research possibilities in in-context learning, large language models, and multi-step reasoning.

## 2. Related Work

**Emergent Abilities and Multi-Step Reasoning.** With the recent trend in scaling language models [brown2020gpt3; chowdhery2022palm], a central question is what _unique_ abilities emerge as models become large [kaplan2020scaling; wei2022emergent]. Generally, the ability to follow the format of given prompts (typically few-shot) thus solving the corresponding tasks (also referred as in-context learning), is something that large language models are particularly skilled at [shin-etal-2020-autoprompt; liu2021pre]. Among the wide language understanding task spectrum, we are particularly interested in multi-step reasoning because of its two uniqueness: (1) multi-step reasoning is a task where large models substantially outperform smaller models [wei2022chain], versus performance gains on tasks like sentiment classification can be very limited with large models [shin-etal-2020-autoprompt]; (2) multi-step reasoning is where few-shot prompting starts to outperform full training set fine-tuning, even when fine-tuning is conducted on the same large model [lewkowycz2022solving]. This work takes an important step forward in multi-step reasoning by showing the critical role of prompt complexity.

**Chain-of-Thoughts Reasoning.** A prominent work demonstrating the multi-step reasoning of language models is chain-of-thoughts prompting (Figure 1A), proposed by Wei et al. [wei2022chain]. They show that the reasoning ability can _only_ be elicited by chain of thoughts, but not standard prompting where an answer directly follows a question without intermediate reasoning steps. Further works show that CoT can be improved by self-consistency [wang2022self], pretraining the model with latex-formated data [lewkowycz2022solving], context selection [creswell2022selection], or even adding certain magic phrases like "Let's think step by step" [kojima2022large]. The original CoT paper [wei2022chain] uses 8 manually written examples as the prompt, which are reused by most follow-up works. Our work sits in the context of CoT reasoning, and propose a new complexity-based prompt selection that substantially outperforms the original CoT.

**Example Selection for Prompting.** Designing prompts can be challenging due to the instability, as multiple works have shown the performance is sensitive to prompt, task, dataset, and model changes [pmlr-v139-zhao21c; lu2022fantastically; su2022selective]. Despite works on automatic prompt searching (which is more suitable for smaller models, e.g., [shin-etal-2020-autoprompt; li2021prefix]), currently, prompt engineering for large models is (still) a community-wide collective trial and error effort (there is even a prompt marketplace named [promptmarket]). The difficulty is that _it is extremely hard to extract generalizable regularity from empirical observations that can form effective selection criteria_. One notable exception is similarity-based prompt selection, which retrieves the most similar training instances as the prompt for a given test case [rubin-etal-2022-learning]. Yet for CoT prompting, retrieving different prompts for different test cases requires reasoning chain annotations for the whole training set, which compromises the advantage of being few-shot. Given this background, our core contribution is identifying complexity as an effective and robust selection criterion and in many cases, it outperforms existing prompt selection schemes while being annotation-efficient.

**Relation to Classical Semantic Parsing.** The procedure of chain of thoughts prompting is conceptually similar to classical semantic parsing where one generates a logical form then executes it upon a knowledge base to reach a final answer [liang2016learning; cheng2019semanticparsing]. The practice of sampling then voting is also similar to marginalizing out semantic parses [yin-etal-2018-structvae]. There are further works linking the relationship between in-context learning and classical Bayesian inference [wei2021pretrained; xie2022an]. From our perspective, we tend to view chain-of-thoughts as flexible, language model styled "logical forms" which are "executed" by the language model itself. We leave further study on connecting classical parsing and CoT to future work.

## 3. Complexity-based Prompting

We study multi-step reasoning tasks, and use math word problems, mathematical problems expressed in natural language, as our testbed. This task, as is measured by solve rate (accuracy), is to predict the answer (typically a number) of a given math word problem via intermediate steps. We follow the chain-of-thoughts prompting framework and compare all prompting schemes using GPT-3 `text-davinci-002` and Codex `code-davinci-002`. An example problem, as well as the chain-of-thoughts workflow, is shown in Figure 1A. The input is a stack of a few (often 8) CoT cases followed by a test question, then the language model continues generating an output CoT for the test question. Our goal is to improve the reasoning accuracy by identifying and exploiting more effective input and output reasoning chains.

### 3.1 Selecting Complex Samples as Prompts

Our method is to simply choose complex prompts over simple ones. We hypothesize that language models' reasoning performance will increase if we use complex instances as in-context "training example," as they intuitively subsume simpler instances [richardson2022pushing]. We define complex instances as instances with more reasoning steps (Figure 1B), as the name "multi-step reasoning" indicates. Note that using reasoning steps as the notion of complexity is also the practice of previous works like [sugawara-etal-2018-makes; lai-etal-2021-machine]. We further define a step as a line, separated by the linebreak "`\n`".

There are two aspects that need more discussion:

**(1) The notion of complexity.** There are other complexity indicators than number of steps, such as questions lengths or the length of the underlying formula for solving a given problem. We will show that the trend that better performance comes with more complex prompts is _consistent across various complexity indicators, such as question lengths and formula lengths_. Consequently, for datasets that do not have annotated reasoning chains, we can use questions lengths to identify complex instances, then only annotate the identified few-shot instances, thus reducing the annotation cost.

**(2) Confounders of number of steps.** The increase in performance with more complex examples in the prompt could be explained by correlated factors like the increase in the total number of reasoning steps in the prompts or just the increased length of the prompt. To account for this, we evaluate prompts with simpler examples but the same number of reasoning steps (e.g. 24 cases with 3 steps vs. 8 cases with 9 steps, both of 72 steps in total). We also consider prompts of the longest lengths (but not most steps). We show that _the number of steps per example_ is the most prominent source of performance gains over confounders.

### 3.2 Complexity-Based Consistency

Complexity-based prompting can be further enhanced with a new output selection method following the same intuition, which we present in this section. Existing evidence shows that the expressive neural models can take _shortcuts_ during reasoning, relying on spurious correlations that inevitably exist in the training data [mudrakarta-etal-2018-model; sugawara-etal-2018-makes; lai-etal-2021-machine]. This often leads to suboptimal generalization to unseen data. To alleviate this issue, we explicitly promote outputs with more complex reasoning chains at inference time.

Specifically, our method follows the self-consistency practice in Wang et al. [wang2022self], which samples N reasoning chains for a test question. Different reasoning chains may lead to different answers, and Wang et al. take the majority answer as the prediction. In our case, instead of voting among all N chains, we only vote among top K (K <= N) complex (more steps) reasoning chains, as shown in Figure 1C. We dub our method _Complexity-based Consistency_. Note that when K = N we recover the original self-consistency method.

In our experiments, we set N to 50, and observe that the optimal K is always smaller than N (typically 30-40). This provides clear evidence that voting among more complex reasoning chains generalizes better than voting among all. We also show that if we do the opposite and vote among answers produced by K simplest reasoning chains, the accuracy is always worse than voting among all. This further validates that complex chains, not simple chains, should be considered more during decoding.

## 4. Experiments

We first discuss our experimental settings in Section 4.1. In Sections 4.2 and 4.3, we present the following results:

1. Our method substantially outperforms the original CoT [wei2022chain]. It establishes new state-of-the-art results on three math reasoning datasets (GSM8K [cobbe2021training]; MultiArith [roy-roth-2015-solving]; MathQA [amini-etal-2019-mathqa]), a temporal reasoning task (Date Understanding [suzgun2022challenging]), and the referential game task (Penguins [suzgun2022challenging]). On StrategyQA [geva2021did], a commonsense reasoning dataset, our approach matches the existing state-of-the-art performance.

2. Performance gains from complex prompts are consistent: no matter what large model we use (GPT-3 or Codex), what distribution the prompt come from (in-distribution, noisy distribution, and distribution shift), or whether there exists prompt format perturbation or confounders, complex prompts consistently outperform simpler prompts.

3. Compared with other example selection schemes (random, heuristic and retrieval), complexity-based example selection often achieves the best or competitive results with minimal annotation budget.

### 4.1 Experimental Settings

**Datasets.** We use three math word problems datasets (GSM8K, MultiArith, and MathQA) and three non-math reasoning (StrategyQA, Date Understanding, and Penguins) as our testbed. We choose GSM8K and MultiArith also because they are the datasets used by prior work on CoTs [wei2022chain; wang2022self; kojima2022large], allowing fair comparison to existing methods. MathQA's annotation are much noisier than others, and we use it to evaluate the robustness of our approach. There are 1.3K test instances in GSM8K, 600 in MultiArith, and 600 in MathQA. For each dataset, we randomly draw 200 instances from the training data to create a validation split. The cost of prompting GPT-3 is proportional to the size of test set.

For the non-math datasets, StrategyQA is a multi-step commonsense reasoning task with 800 test instances. Date Understanding is a temporal reasoning task with 250 test instances. Penguins is a referential game (a referential game asks questions referring to different objects, e.g., is penguin A older than penguin B and C) with 146 test instances. Both Date Understanding and Penguins are subsets of the BigBench Hard datasets (datasets that previously fine-tuning struggles with, see [suzgun2022challenging]).

**Language Models.** We consider two paradigms: fine-tuning and prompting. For fine-tuning, we report the existing SOTA performance: a fine-tuned GPT3 with a verifier [cobbe2021training] on GSM8K, a relevance and LCA operation classifier [roy-roth-2015-solving] on MultiArith and a customized sequence to sequence model [amini-etal-2019-mathqa] on MathQA.

For prompting, we consider the following language models:

1. LaMDA [thoppilan2022lamda], a 137B model used as the baseline in Wei et al. [wei2022chain]
2. PaLM [chowdhery2022palm], the primary 540B model used in the CoT papers
3. Minerva [lewkowycz2022solving], a 540B large model that trains on LaTeX data; it achieves SOTA performance in math reasoning on GSM8K
4. GPT-3 175B (text-davinci-002 from [brown2020gpt3])
5. Codex (code-davinci-002 from [chen2021evaluating], also 175B)

We further consider the DiVeRSe [li2022advance] method which equips an additional trained verified to GPT-3/Codex and is the previous SOTA on GSM8K. Our experiments are mostly conducted on GPT-3 and Codex because they are the accessible to the public thus more reproducable. LaMDA, PaLM and Minerva are not accessible to the public, and their numbers are from their corresponding papers.

**Prompts and Hyperparameters.** The training sets of GSM8K and MathQA contain human annotated reasoning chains, within which we search for complex prompts. MultiArith does not have annotated reasoning chains, so we consider two strategies:

1. _In-distribution annotation_, which uses question lengths as an alternative proxy for complexity, then manually annotates reasoning chains for complex questions
2. _Prompts transfer_ from GSM8K training data

All prompts for math datasets contain 8 cases (a case = a question + a chain of thoughts + an answer). For non-math datasets, since they do not have annotated reasoning chain, we again, use question length as the complexity proxy and manually annotates reasoning chains for complex questions. Following Kojima et al. [kojima2022large], we add "Let's think step by step" before the reasoning chains for all prompting schemes to improve the performance.

### 4.2 Main Results

**Overall Test Performance on Math Datasets**

Table 1 shows the overall performance of models. We consider two decoding strategies: (1) greedy decoding and (2) majority vote (Section 3.2).

| Model                             | Method             | #Params | GSM8K           | MultiArith      | MathQA           |
| --------------------------------- | ------------------ | ------- | --------------- | --------------- | ---------------- |
| Previous finetuning SOTA          | -                  | <=175B  | 57.0            | 60.5            | 37.4             |
| **Greedy Decoding**               |
| LaMDA                             | -                  | 137B    | 17.1            | 51.8            | -                |
| PaLM                              | -                  | 540B    | 58.1            | 94.7            | -                |
| Minerva                           | -                  | 540B    | 58.8            | -               | -                |
| Text-davinci-002                  | Handcrafted CoT    | 175B    | 48.1            | 90.8            | 30.1             |
| Text-davinci-002                  | Random CoT         | 175B    | 49.7            | 89.5            | 34.8             |
| Text-davinci-002                  | **Complex CoT**    | 175B    | **55.4 (+7.3)** | **94.2 (+3.4)** | **36.0 (+5.9)**  |
| Code-davinci-002                  | Handcrafted CoT    | 175B    | 61.0            | 95.8            | 29.3             |
| Code-davinci-002                  | Random CoT         | 175B    | 60.4            | 97.3            | 40.5             |
| Code-davinci-002                  | **Complex CoT**    | 175B    | **66.6 (+5.6)** | **95.8 (+0.0)** | **47.3 (+18.0)** |
| **Voting among multiple outputs** |
| LaMDA                             | -                  | 137B    | 27.7            | 75.7            | -                |
| DiVeRSe                           | -                  | 175B    | 82.3            | 99.8            | -                |
| PaLM                              | -                  | 540B    | 74.4            | 99.3            | -                |
| Minerva                           | -                  | 540B    | 78.5            | -               | -                |
| Text-davinci-002                  | Handcrafted CoT    | 175B    | 64.0            | 98.2            | 43.8             |
| Text-davinci-002                  | Random CoT         | 175B    | 62.0            | 95.2            | 48.5             |
| Text-davinci-002                  | Complex CoT        | 175B    | 71.5            | 97.3            | 49.5             |
| Text-davinci-002                  | **+ Vote Complex** | 175B    | **72.6 (+8.6)** | **98.7 (+0.5)** | **50.2 (+6.4)**  |
| Code-davinci-002                  | Handcrafted CoT    | 175B    | 74.6            | 99.7            | 55.0             |
| Code-davinci-002                  | Random CoT         | 175B    | 77.3            | 99.3            | 58.2             |
| Code-davinci-002                  | Complex CoT        | 175B    | 82.6            | 99.7            | 58.6             |
| Code-davinci-002                  | **+ Vote Complex** | 175B    | **82.9 (+8.3)** | **99.8 (+0.1)** | **60.0 (+5.0)**  |

Note that PaLM and Minerva are more than three times larger than GPT-3 and Codex, the model we use to evaluate our method, and Minerva is additionally pretrained on latex data. Therefore, they are by no means comparable to the methods based on GPT-3 or Codex. We nevertheless outperform all of them.

We consider three prompting schemes:

1. _Handcrafted CoT_ constructed originally by Wei et al. [wei2022chain] then reused in following-up works [wang2022self; kojima2022large; wang2022rationale]
2. _Random CoT_: randomly drawing samples from the training set. GSM8K and MathQA training data have reasoning chain annotations, so we directly use them. MultiArith does not have reasoning annotations, so we randomly sample eight training cases then annotate the chains manually
3. _Complex CoT_. For GSM8K and MathQA, we choose eight training cases with the most numbers of reasoning steps; For MultiArith, we use the question length as the proxy for complexity, and manually annotate reasoning chains for the eight training cases with the longest questions

Complex prompt selection results in substantially more reasoning steps: it averages 9.0 steps on GSM8K, while the handcrafted and random schemes yield 3.4 and 2.8 steps respectively. The trends are similar on the other two datasets. The handcrafted prompts uses the same fixed prompt for all three datasets but the cases within the prompt does not come from any of the datasets (so they are in a sense, out of distribution). Complex prompts and random prompts all come from their corresponding training sets (so these two are in a sense, in-distribution).

As Table 1 shows, our method achieves substantially better performance than the baselines. Besides, our proposal of voting among complex chains outperforms voting among all. Furthermore, our performance using GPT-3 is close to PaLM and Minerva, two language models that are more than three times larger than GPT-3 and are not publicly accessible. These results directly demonstrate the effectiveness of our methods.

**Consistent Performance Improvements on Different Reasoning Tasks**

Table 2 shows that the advantage of complex prompts holds for different types of reasoning tasks.

| Model            | Prompt      | #Params | StrategyQA       | Date Understanding | Penguins        |
| ---------------- | ----------- | ------- | ---------------- | ------------------ | --------------- |
| PaLM             | Handcrafted | 540B    | 77.8             | 79.2               | 65.1            |
| Text-davinci-002 | Handcrafted | 175B    | 66.9             | 82.8               | 76.7            |
| Text-davinci-002 | Simple      | 175B    | 71.1             | 76.4               | 61.0            |
| Text-davinci-002 | Complex     | 175B    | **77.0 (+10.1)** | 82.4 (-0.4)        | 79.5 (+2.8)     |
| Code-davinci-002 | Handcrafted | 175B    | 73.1             | 86.0               | 78.1            |
| Code-davinci-002 | Simple      | 175B    | 74.4             | 83.2               | 69.8            |
| Code-davinci-002 | Complex     | 175B    | 73.9 (+0.8)      | **86.8 (+3.6)**    | **80.8 (+2.7)** |

When prompted with complex examples, GPT-3/Codex achieves new SOTA performance on Date Understanding and Penguins datasets where complex prompts consistently improves performance over simpler prompts.

**Performance Improvements Breakdown**

Table 3 shows the breakdown of GSM8K validation set performance improvements on various design choices.

| Greedy Decoding                | Acc.        | Majority Vote                                                  | Acc.        |
| ------------------------------ | ----------- | -------------------------------------------------------------- | ----------- |
| CoT Original                   | 43.5        | CoT Original                                                   | 55.5        |
| Add "Let's think step by step" | 48.5 (+5.0) | Add "Let's think step by step" and change "Q: " to "Question:" | 61.0 (+5.5) |
| Use complex prompt             | 54.0 (+5.5) | Use complex prompt                                             | 67.0 (+6.0) |
| Change "Q: " to "Question: "   | 58.0 (+4.0) | Voting within complex sample                                   | 71.0 (+4.0) |

While techniques like adding "Let's think step by step" [kojima2022large] improves the accuracy, the performance gains can be primarily attributed to complexity-based prompting, validating the effectiveness of our methods.

**Consistent Performance Improvements in Different Prompt Distributions**

[IMAGE: Figure 2 - Validation set performance. X-axis means reasoning steps and y-axis means accuracy. More reasoning steps in prompts overall achieve higher accuracy when prompts are in-distribution (left), noisily labeled (middle), and out of distribution (right).]

We investigate the performance of our complexity-based prompting when the prompts are: (1) from clean in-distribution training set (GSM8K); (2) from noisy annotation (MathQA); (3) are transferred from another dataset (MultiArith). Here as MultiArith does not have annotated reasoning chains, and their questions are similar to the ones in GSM8K; we use (transfer) prompts from GSM8K for MultiArith. Figure 2 shows that in general, more complex prompts achieve better performance, and this trend is consistent in all the three settings, except for one particular case on MultiArith.

**Comparison to other Example Selection Schemes**

Table 4: Comparison of example selection schemes on validation sets.

| Method            | #Annotations                | GSM8K    | MultiArith | MathQA   |
| ----------------- | --------------------------- | -------- | ---------- | -------- |
| Random            | Few-shot (8)                | 52.5     | 86.5       | 33.0     |
| Centroid          | Few-shot (8)                | 52.0     | 92.0       | 32.0     |
| Retrieval         | Full training set (>=10000) | 56.0     | 88.0       | **69.5** |
| Complexity (ours) | Few-shot (8)                | **58.5** | **93.0**   | 42.5     |

As we view the reasoning complexity as the basis of a new example selection scheme, we compare it with existing selection schemes. We consider:

1. _Random_ selection
2. _Centroid_, where we select examples whose question embeddings (produced by a pretrained sentence encoder [reimers2019sentence]) are the closest to the embeddings of all other questions, i.e., questions at the center part of the dataset. The intuition is that centroid examples may be the most typical or representative cases of a dataset
3. _Retrieval_, where we retrieve questions from a training set whose embeddings are closest test question measured in Euclidean distance

Notably, there are important differences between retrieval and other methods: retrieval uses different prompts for different test cases, while other methods use fixed prompts for all. Therefore, the annotation cost of retrieval scales with the size of the test set, and is usually about the full-training-set-sized annotation (more than 10K cases), while others only require few-shot annotation (in our cases, only 8 examples).

As shown in Table 4, complexity-based selection outperforms all other methods on GSM8K and MultiArith. On MathQA, although retrieval-based selection outperforms complexity-based selection, it has two importance restrictions that we do not have: (1) as mentioned, retrieval requires substantially more CoT annotation, while we only requires few-shot; (2) the performance of retrieval is critically determined by how similar the test cases and the training questions are to each other, and the similarity may not always hold. So in general, complexity-based prompting has the advantage of good performance while being annotation efficient.

**Direction of Generalization**

[IMAGE: Figure 3 - X-axis means reasoning steps of dev set cases and y-axis frequency. The direction of generalization on the two datasets is intriguing and show different patterns: on GSM8K, simple prompts perform better for simple cases (<=3 steps) while complex prompts perform better for complex cases; on MathQA, simple prompts do not have advantages for simple case and complex prompts seem to perform better on most of the groups.]

Intuitively, one may attribute the improvements of complexity-based prompting to accuracy gains on complex test cases. Yet interestingly, our analysis suggests the opposite. Figure 3 compares the validation set accuracy of complex and simple prompts, varying the number of reasoning steps in the _gold annotation_. We observe a clear trend on both GSM8K and MathQA: complex prompts perform on par with simple prompts on _hard_ cases, while achieving more clear gains on cases with fewer number of reasoning steps. This finding suggests that complexity-based prompting generalizes to simpler test cases. We conjecture that this is because the reasoning capabilities elicited by complex prompts may cover simple questions better. Further investigation into the underlying mechanism is definitely interesting, and is left to future work.

**Performance on Small Models**

Table 5: Performance on smaller models.

| Method      | MultiArith (text-curie-001 6.7B) | MultiArith (Flan-T5 11B) | GSM8K (Flan-T5 11B) |
| ----------- | -------------------------------- | ------------------------ | ------------------- |
| Handcrafted | 3.8                              | 51.5                     | 19.5                |
| Random      | 2.0                              | 53.3                     | 21.0                |
| Complex     | 3.3                              | 51.3                     | 21.0                |
| Delta       | -0.5                             | -0.2                     | +1.5                |

Does smaller models also enjoy the performance gain from complex prompts? Unfortunately, this seems to be not the case. As is shown in Table 5, complex prompts cannot induce meaningful performance gain over the original or random prompts. This indicates that, like the chain-of-thoughts prompting itself, _complexity-based prompting is also an emergent ability_ that exist only when the model scale is large enough.

### 4.3 Analysis

In this section, we develop in-depth analysis supporting our claims. All experiments in this section are performed on validation sets. We first show that the performance improvements with more reasoning complexity is consistent in terms of: (1) different proxies for complexity and (2) different step formatting. Then we show that the number of reasoning step is the most prominent factor for performance improvements over its confounders. Finally, we strengthen our conclusion of complexity-based consistency, and show that the optimal performance is always achieved by majority voting over complex chains, not simple chains.

**Alternative Proxies for Complexity**

Complexity-based prompting is equally applicable when the data does not come with reasoning chain annotations, as we have already shown that selecting cases with longest questions also improves performance (Section 4.2).

Table 6: Alternative complexity proxies.

| Complexity Level | Q Len. | GSM8K    | F Len. | MathQA   |
| ---------------- | ------ | -------- | ------ | -------- |
| Simple           | 70     | 49.0     | 7.5    | 37.5     |
| Mid              | 226    | 51.0     | 55     | 33.5     |
| Complex          | 815    | **52.5** | 165    | **43.5** |

In Table 6, we confirm that in addition to number of steps, either using questions length or formula length as the measure of complexity, the optimal performance is achieved with complex prompts. These results mean that the effectiveness of complex prompts are consistent with regard to the notion of complexity.

**Sensitivity Analysis on Step Format**

A common concern with prompting is that the performance can be sensitive to the format of the input [shin-etal-2020-autoprompt; liu-etal-2022-makes] and may change with input perturbations. Here we study one important perturbation: the splitter of steps, which is an existing concern of CoT-styled prompting in [ronggpt32022; akyurek2022gpt3addition].

Table 7: Step format sensitivity analysis.

| Dataset        | Linebreak "\n" | Period "." | Explicit "step i" | Semicolon ";" |
| -------------- | -------------- | ---------- | ----------------- | ------------- |
| GSM8K-Complex  | **58.5**       | 54.5       | 52.0              | 54.0          |
| GSM8K-Simple   | 43.0           | 40.5       | 42.0              | 41.0          |
| MathQA-Complex | **42.5**       | 39.0       | 36.0              | 39.5          |
| MathQA-Simple  | 34.0           | 34.5       | 33.5              | 37.0          |

As alternatives to the linebreak "\n" we use, we consider two more types of splitters: (1) explicit phrases "step i" (2) two punctuation marks, period "." and semicolon ";". The performance is shown in Table 7. Although these perturbations do have an influence on the performance, complex prompts consistently lead to better performance with regard to different step formatting.

**Output Step Distribution**

[IMAGE: Figure 5 - Output step distribution. X-axis means reasoning steps and y-axis means frequency. As a sanity check, complex prompts indeed induce complex outputs than simple prompts.]

As a sanity check, in Figure 5, we show that complex prompts induce complex reasoning than simple prompts (Codex outputs on GSM8K and MathQA). This means that complex prompts are indeed discouraging the model from taking easier reasoning path, thus potentially avoiding shortcuts.

**Confounder Analysis**

[IMAGE: Figure 4 - Relationship between confounders.]

All experiments so far keeps the number of instance to be 8 in all prompts. Yet when choosing complex examples with more reasoning steps, we observe that the following factors are correlated:

Table 8: Confounder analysis.

| _More number of simple cases_ vs. _less but complex cases_ | GSM8K |          | MathQA |          |
| ---------------------------------------------------------- | ----- | -------- | ------ | -------- |
| Total reasoning step                                       | 72    | 72       | 45     | 45       |
| Number of cases in prompt                                  | 24    | 8        | 19     | 8        |
| Per-case reasoning step                                    | 3     | 9        | 2.25   | 5.625    |
| Accuracy                                                   | 51    | **58.5** | 37.5   | **42.5** |

| _Most number of reasoning steps_ vs. _longest prompt_ | GSM8K |          | MathQA |          |
| ----------------------------------------------------- | ----- | -------- | ------ | -------- |
| Number of cases in prompt                             | 8     | 8        | 8      | 8        |
| Length of prompt                                      | 12.6k | 8.4k     | 7.6k   | 4.9k     |
| Number of total reasoning step                        | 59    | 72       | 32     | 45       |
| Per-step length                                       | 112   | 74       | 137    | 52       |
| Accuracy                                              | 57    | **58.5** | 31     | **42.5** |

| _Shorter per-step length_ vs. _Longer per-step length_ | GSM8K |          | MathQA |          |
| ------------------------------------------------------ | ----- | -------- | ------ | -------- |
| Number of total reasoning step                         | 72    | 72       | 45     | 45       |
| Number of cases in prompt                              | 8     | 8        | 8      | 8        |
| Per-step length                                        | 36    | 74       | 37     | 52       |
| Accuracy                                               | 51.0  | **58.5** | 30.5   | **42.5** |

From the accuracy results we can see that:

1. Keeping full number of reasoning steps the same, using more number of simple cases does not outperform less number of complex cases
2. Longest prompts does not outperform complex prompts
3. Yet we do need a moderate per-step length because keeping total number of step 72, moderate per-step length prompts outperforms shorter per-step length prompts

This means that despite the existence of confounders, the number of reasoning steps per example is the most prominent factor for performance gain given moderate per-step length.

**Voting among Complex Chains Outperforms Voting among All**

[IMAGE: Figure 6 - Majority voting over top K complex/simple generated samples. The optimal performance is achieved on selecting complex samples over simple samples.]

Now we analyze the properties of complexity-based consistency, which generalizes the reasoning complexity selection criteria from the input space (prompts) to the output space (sampled solutions from the language model). Complexity-based consistency first sample N reasoning chains from the model, then take the majority answer voted from the top K complex chains. Here we set N=50, and control K=10, 20, 30, 40, 50. Note that when K=50 we recover the original self-consistency (no complexity-based selection).

As a further comparison, we consider the other way around: instead of voting over top K complex samples, we vote over top K simple samples. As is shown in Figure 6, we see:

1. Voting over simple samples always _underperform_ full sample, indicating this is not a correct direction for performance
2. Both datasets achieve the best performance on some K\* < N with complex voting

These results again validate the choice of complex samples.

## 5. Conclusion

This paper proposes a new complexity-based instance selection scheme for prompting language models to perform multi-step reasoning. In addition to substantial performance improvements on math word reasoning tasks, our methods exhibit multiple advantages such as being intuitive, annotation-efficient, and robustly effective in different in-context learning settings. We hope this work will open new research possibilities in prompting, language models, and multi-step reasoning.
