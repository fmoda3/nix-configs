# Abstract

Methods such as chain-of-thought prompting and self-consistency have pushed the frontier of language model reasoning performance with no additional training. To further improve performance, we propose a prompt ensembling method for large language models, which uses a small dataset to construct a set of few shot prompts that together comprise a "boosted prompt ensemble". The few shot examples for each prompt are chosen in a stepwise fashion to be "hard" examples on which the previous step's ensemble is uncertain. We show that this outperforms single-prompt output-space ensembles and bagged prompt-space ensembles on the GSM8k and AQuA datasets, among others. We propose both train-time and test-time versions of boosted prompting that use different levels of available annotation and conduct a detailed empirical study of our algorithm.

[IMAGE: Conceptual Diagram of Boosted Prompting. In this diagram (data crafted for illustrative purposes), we see the intuition of boosted prompting in a simplified 2D space. The original prompt consists of example problems and generalizes to parts of the target problem space, but fails in others. Our algorithm selects the "Hard" examples -- overall incorrect examples for which the model generated at least one correct solution (out of several generations combined via self-consistency). The Hard examples are used to form a new few-shot prompt, which is added to the ensemble, increasing overall coverage of the problem space. When applied at train time, the Hard examples typically lie outside the model's solution frontier, as depicted, since ground truth labels are available. When no labels are available, the model uses its own generated labels and Hard examples are restricted to labels with sufficient confidence.]

# Introduction

When prompted with a few examples of a target behavior, Large Language Models (LLMs) are able to solve an impressive array of tasks, often with superhuman performance [brown2020language; srivastava2022beyond]. When the examples include reasoning steps leading to the answer (a "chain of thought"), e.g., for multi-step math problems, LLMs demonstrate similar step-by-step reasoning during inference, which greatly improves their accuracy [nye2021show; wei2022chain]. Combined with output space ensembling, where several chains of thought are generated for a single prompt, this achieves strong performance on a wide array of tasks [wang2022self].

The strong baseline performance of LLMs in the few shot setting allows them to be used not only for immediate performance on downstream tasks, but also to generate relevant, high quality datasets on which the LLMs themselves can be further trained or finetuned [zelikman2022star; huang2022large; bai2022constitutional]. In both cases, we seek the highest possible few shot performance from the base foundation model [li2022advance; wang2022rationale]. One way to do this is to carefully select the initial few shot samples (and chain of thought, where applicable) for each target task. This "prompt engineering" can entail substantial manual effort for each individual task, and there is uncertainty about how choices impact performance [zhou2022large]. For example, one recent work recommends prompts with the "longest questions" and most "complex reasoning" [fu2022complexity] while another suggests "only considering shorter questions with shorter rationales" [zhang2022automatic].

To improve baseline performance and reduce the manual effort involved in constructing few shot samples, we propose a new technique, "boosted prompting," which leverages a small dataset to construct a set of few shot prompts that progressively solve more of the problems. Boosted prompting, inspired by classical boosting algorithms [freund1999short], is a stagewise ensemble method that iteratively adds to a set of prompts so as to improve performance on problems just outside the frontier of what the model can currently solve [baranes2013active]. See Figure 1 for a conceptual illustration. The final output of our algorithm is an accumulated set of LLM prompts with representation throughout the difficult parts of the problem space. We propose both train-time (inductive) and test-time (transductive) versions of our algorithm. We show that the former can improve performance with as few as 100 labeled training examples, and find some evidence that the latter allows the LLM to adapt to changes in the problem distribution. The contributions of our work include:

1. A algorithm that constructs a boosted ensemble of few shot prompts in a stagewise iterative process. It is complementary to prior techniques for improving reasoning performance.

2. Our proposed algorithm obtains strong results on AQUA, GSM8K, and other challenging datasets, outperforming the strong baseline performance of single prompt output space ensembles [wang2022self] and bagged ensembles [li2022advance].

3. A detailed empirical study that investigates different annotation settings and design choices.

# Prior Work

**Large Language Models** Large, transformer-based language models (LLMs) have proven to be extremely capable few shot learners in a wide variety of different contexts [vaswani2017attention; brown2020language]. Their general purpose nature has created something of a "paradigm shift" in the AI landscape, whereby many downstream tasks requiring language will make use of an LLM as a foundation model, either directly or by finetuning [bommasani2021opportunities]. Our work considers one approach to improving baseline, untuned LLM performance, which builds on and is complementary to a number of recent techniques.

**Chain of Thought** Wei et al. [wei2022chain] show that prompting LLMs with intermediary reasoning steps, called _chain of thought_ (CoT) prompting, can significantly increase the ability of the LLM to perform complexity reasoning tasks. Wang et al. [wang2022self] further improve reasoning performance by introducing self-consistency (SC), which replaces the standard greedy decoding of the LLM output with a stochastic output space ensemble that marginalizes over multiple reasoning paths by sampling with positive temperature (e.g., T=0.7) and choosing the final prediction p\* with highest agreement:

```latex
$$p^* = {\arg\max}_p {\sum}_i \mathbb{I}(p_i = p)$$
```

This exploits the fact that diverse reasoning paths that lead to the same answer are more likely to be correct. Our work builds on self-consistency by using the agreement among reasoning paths to determine the set of "Hard" problems and, for the test-time version of our algorithm, the set of LLM generated answers that are likely to be correct. This latter usage is similar to that of Huang et al. [huang2022large], who show that by finetuning LLMs on self generated answers with "high agreement," large language models can self improve.

**Automatic Prompt Engineering** It has been observed that language model performance can be sensitive to the chosen prompt [zhao2021calibrate], which has led to in-depth studies of prompting methodology [liu2023pre; wang2022towards] and the development of several approaches to automatic prompt generation [shin2020autoprompt; gao2020making]. While some of these approaches are gradient-based [li2021prefix; qin2021learning], requiring access to the model gradients, others are based on sampling [zhou2022large] or elicited via a prompt-based algorithm [li2022self]. For purposes of collecting chain of thought annotations, a handful of past works have considered self-generating the chain of thought [zhang2022automatic; huang2022large] and possibly validating them using the ground truth answers [zelikman2022star]. We draw inspiration from these works and use model generated chains of thought when forming boosted prompts.

**Example Selection** Few shot performance can be improved by retrieving relevant examples from a large dataset [liu2021makes; rubin2021learning], which may itself by generated by the language model via a carefully guided process [li2022self]. For chain of thought prompting, it has been observed that relevance and coherence (ordering of reasoning steps) are important for performance [wang2022self] and further, that choosing examples that require more reasoning steps can improve performance [fu2022complexity]. In our work we use disagreement among ensemble members both as a proxy for example informativeness and, for the test-time version of our algorithm, as a measure of confidence in the correctness of the model's prediction.

**Ensemble Methods** Ensembles reliably improve performance in a number of contexts [lakshminarayanan2017simple; ganaie2022ensemble], including language modeling [wang2022rationale]. Boosting [freund1999short] iteratively constructs an ensemble to optimize performance on difficult examples, and can be understood as a form of curriculum learning [bengio2009curriculum]. We adapt boosting to the prompt-based LLM setting by forming a new prompt of "Hard" examples at each iteration.

In a concurrent work, Hou et al. [hou2022promptboosting] also adapt boosted ensembles to LLM classifiers. Their work focuses on a different setting than ours, in which classification is done via single tokens, as opposed to a solution following a chain of thought. Rather than choose the prompt examples so as to improve performance, Hou et al. choose random examples for each prompt, but change the weighting of the training examples as in classical boosting when optimizing a "verbalizer" that maps model outputs to classes.

# Boosted Prompt Ensembles

Our goal is to construct a set of few shot prompts for a pretrained language model that work well together as an ensemble, in the sense that their combined predictions do better than the predictions of a single prompt output space ensemble [wang2022self] or a multi-prompt bagged ensemble [wang2022rationale; li2022advance].

To do this, we adopt a stagewise approach inspired by classical boosting algorithms that iteratively adds an informative prompt to an existing set of prompts. At each iteration, a new informative prompt is added, thereby expanding the range of problems that the current ensemble solves.

As a proxy for informativeness, we propose to use the agreement between several solutions sampled from the model. If all solutions agree, the model already knows how to solve the given sample, and it is not particularly informative. On the other hand, if there is disagreement amongst the model's solutions, then we assume that the model is unsure about the example, and that including a correct solution for the example in a few shot prompt would be informative.

How we determine correctness depends on the setting, and leads to two different instances of our algorithm: train-time boosting, for the case where there is a small labeled training set or some human-in-the-loop supervision available, and test-time boosting, for the case where no supervision is available and the model must rely solely on its own predictions. Both are summarized in Algorithm 1 (the difference being whether the optional argument answers A is provided).

The output of our train-time algorithm is a set of prompts, which are then applied to the test set. The output of our test-time algorithm is a set of prompts together with a set of test predictions.

## Algorithm 1: Boosted Prompting

**BoostedPrompting(T, p, m, n, [A]):**

- preds <- {q:[] for q in T}
- prompts <- {p}
- For k = 1 to n:
  - For q in T:
    - preds[q].append([LLM(p,q) for _ in range(m)])
  - p <- NewPrompt(T, preds, [answers A])
  - prompts.add(p)
- Return prompts, preds

**NewPrompt(T, preds, [A]):**

- (train-time boosting) C <- [q for q in T if A[q] in preds[q]]
- (test-time boosting) C <- [q for q in T if there is "sufficient agreement" for the majority prediction in preds[q]]
- C <- choose 8 of the questions for which the majority prediction in preds[q] has _minimal_ agreement
- p <- for each question q in C choose one CoT from preds[q] that led to the answer/prediction
- Return p

**Train-time Boosting** In this case, we assume access to a small labeled dataset, D_Train = (T, A) = (q_i, a_i) for i=1 to N, where a_i are final answer labels (we do not require chain of thought annotations, as we generate the chain of thought using the model). We also assume there is an initial prompt p_0, which may either contain manually annotated examples or be generated with zero shot chain of thought [kojima2022large; zhang2022automatic].

Our algorithm is applied for n iterations, starting with the initial prompt set {p*0}. At the kth iteration we aim to create a new prompt which generalizes to a region of the target problem space to which our previous prompt set {p_0 ... p*{k-1}} performs poorly. To do this, we first sample a set of m candidate reasoning paths and answers for each problem in D_Train using the most recent prompt, and append the m reasoning paths to the m(k-1) reasoning paths that have already been sampled by the boosted ensemble.

Then, motivated by curriculum learning, we form a new prompt by selecting correct reasoning paths from those problems of intermediate difficulty, where the current boosted ensemble only sometimes gets the correct answer. Specifically, we sort the problems where at least one reasoning path led to the correct answer by the number of correct reasoning paths, and select (problem, correct reasoning path) pairs from amongst the hardest problems. Following Fu et al.'s [fu2022complexity] discovery that longer reasoning paths improve in-context reasoning performance, for each hard problem chosen, we choose from the reasoning paths that led to a correct answer by using a complexity heuristic, measured by the number of sentences in reasoning path. Concatenating this set of (problem, correct reasoning path) pairs forms a new prompt, which we use for the next iteration of the algorithm, until we have a set of n prompts comprising a boosted ensemble.

To perform inference at test time, we use our language model to generate m chain of thought answers for each of the n prompts in our boosted ensemble, and take a majority vote over the nm predictions. Intuitively, each prompt in {p*0, ..., p*{n-1}} covers a part of the target problem space. Those that do not cover the target problem space in which the test question resides will lead the language model to fail at answering correctly in likely different ways, while prompts covering the target problem space in which the test question resides will likely answer correctly. We study the effect of varying n and m under a fixed computational budget in the experiments.

**Test-time Boosting** In the absence of training labels, our algorithm can be adapted to the transductive (where the entire unlabeled test set is available; see Algorithm 1) and online (where test problems come one at a time; see Algorithm 2 in Appendix) settings. We call this "test-time boosting". In this case, we substitute ground truth answer labels with model predictions, using a similar motivation as Huang et al. [huang2022large], whereby predictions with "sufficient agreement" are treated as correct. The definition of sufficient agreement is a hyperparameter. In our experiments, we consider sufficient agreement to be achieved for question q with most common prediction p\* if the agreement ratio is higher than some sufficient agreement hyperparameter Delta.

The algorithm is otherwise the same as the train-time algorithm. Note that since agreement is also used to determine problem difficulty for prompt generation, a natural tension arises, and test-time boosting chooses easier samples than the train-time version. For this reason, one would not generally expect test-time boosting to perform as well as train-time boosting.

Test-time boosting has one notable advantage over train-time boosting: in case of distribution shift between train and test sets, test-time boosting has an opportunity to adapt to out-of-distribution problems by including them in its prompt set. In theory, this allows it to do a form of online "prompt space exploration", whereby the boosted prompt adapts to the current problem distribution. Our experiments find some evidence of this possibility, but we leave a thorough investigation to future work.

# Experiments

We evaluate the supervised ("train time boosting") and self-supervised / transductive ("test time boosting") versions of our algorithm on a selection of more difficult reasoning benchmarks with varying amounts of annotation. Boosted prompting outperforms baselines on all five datasets we evaluated in our experiments.

Our experiments seek to answer the following questions:

- Do boosted prompt ensembles offer a performance advantage over single prompt and bagged prompt ensembles?
- How does our method's performance vary with the amount of annotation available?
- How sensitive is boosting to the initial prompt?
- How does varying the number of ensemble members / samples per ensemble member impact results?
- How does the level of "sufficient agreement" for determining correctness impact test-time boosting?
- Can we further improve performance by applying weights to the ensemble members?
- Does choosing from the most complex generated chains of thought aid performance?
- Does the choice of LLM model impact the relative performance of boosted prompting?

**Model** Our primary experiments are carried out with the `code-davinci-002` ("Codex") model via the OpenAI API [chen2021evaluating]. As demonstrated by other papers [wang2022rationale; fu2022complexity], performance trends between methods are consistent across models of similar sizes, and Codex is the highest performing model on our tested datasets, outperforming the larger PaLM-540B [chowdhery2022palm]. We thank OpenAI for free access to this model as part of their beta program but note that, unfortunately, it has been discontinued. We also verify that our results generalize to other models (`text-davinci` and `gpt-3.5-turbo`). We describe our implementation details and link to our code in the appendix.

**Datasets** We consider the following datasets:

- **AQUA** (Algebra QA with Rationales), a dataset of roughly 100,000 algebraic word problems and 254 test questions, which is sometimes referred to as the MATHQA dataset due to a follow-up work [ling2017program; amini2019mathqa]. We randomly sample 200 training problems for our labeled training set.

- **GSM8K** (Grade School Math 8k), a dataset of 1319 mathematical word problems curated by human problem writers [cobbe2021training]. We randomly sample 200 training problems for our labeled training set.

- **MMLU570**, a stratified subsample of the Massive Multitask Language Understanding (MMLU) dataset with 570 multiple choice questions composed of 10 questions sampled from each of the 57 MMLU subjects [hendrycks2020measuring]. We use the 285 (5x57) sample dev set for our labeled training set.

- **CMATH420**, a stratified subsample of the challenging Competition Math dataset with 12 test samples from each of the 35 subject-level pairs [hendrycksmath2021]. We use 71 Level 1 Prealgebra problems from the training set (all such problems that meet our subsampling criteria) for our labeled training set.

- **SVAMP** (Simple Variations on Arithmetic Math word Problems), a set of 1000 algebraic word problems designed to test different aspects of reasoning [patel2021nlp]. We do not have a labeled training set and do not do train-time boosting for this dataset.

**Baselines** Our main baseline is self-consistency (SC) [wang2022self], which uses a single prompt and creates an ensemble in output space, by taking the plurality of n positive temperature generations.

For alternative annotation settings (see next Section), we combine self-consistency with various approaches to choosing the few-shot prompt, including as baselines: **(a)** self-consistency with auto CoT [zhang2022automatic], which bootstraps the model's own zero-shot CoT to form a few-shot prompt, **(b)** self-consistency with complexity prompting [fu2022complexity], which chooses the few shot examples to use a maximal number of reasoning steps, and **(c)** self-consistency with bagged prompts [li2022advance], which chooses several few shot prompts at random. The self-consistency authors also considered bagged and random prompt order ensembles, but found that neither had a noticeable effect on results relative to single-prompt output-space ensembles (self-consistency) [wang2022rationale].

To ensure a fair comparison, we re-implement each baseline in our codebase, which uses slightly different formatting and answer and prediction extraction for GSM8K (see Appendix for details). In our implementation, we also extend all baselines to use 100-path self-consistency. For the baselines that reported results with self-consistency, we report both the results from the original works as well as those from our implementation.

## Results

The main results are reported in Table 1, grouped by the type of annotation used by the method. As self-consistency introduces some stochasticity in small datasets, we average results over several seeds for both our method and our implementations of the baselines (see table caption). All of our main results consider 100 ensemble generations sampled at temperature T = 0.7, which comes out to 100 single prompt samples for self-consistency, and for bagging and boosting, 10 samples from each of 10 prompts.

**Do boosted prompt ensembles offer a performance advantage over single prompt and bagged ensembles?**

Yes, in all cases, when a small training dataset (50-300 samples) is available, we find that boosting is superior to randomly bagging few shot examples as well as to single-prompt self-consistency. The difference to the latter can be quite large if the initial prompt is suboptimal, as observed in case of AQUA, where train time boosting obtains 63.5% as compared to the 57% obtained by single prompt self-consistency.

**How does our method's performance vary with the amount of annotation available?**

We consider four levels of annotation:

- Small training set (50-300 samples) with ground truth labels. See "Datasets" above for details.
- A few shot CoT prompt of <= 8 examples. In this case, we use the prompts from past work where available, or make our own. See Appendix for exact prompts.
- No relevant annotation (zero shot). Following Zhang et al. [zhang2022automatic], we assume access to the entire test set (transductive setting) when forming predictions, but note that boosted prompting could also be applied online. We use the Auto CoT method [zhang2022automatic] to form a few shot prompt by applying zero shot CoT [kojima2022large] to a sample from the test set. This approach has been validated by Huang et al. [huang2022large], so we do not also consider a direct zero shot + SC baseline.
- A pseudo-adversarial case, where the same nonsense two shot prompt is provided for all datasets.

We also list four baselines that require a larger training set or targeted manual annotation. The Minerva [lewkowycz2022solving] and LMSI [huang2022large] baselines finetune PALM 540B [chowdhery2022palm]. PALM has worse baseline performance than Codex, which explains why unfinetuned boosted prompting outperforms these finetuned baselines. Our method is compatible with finetuning (see `gpt-3.5-turbo` results below), and could be used together with LMSI to further improve their self-annotations.

At each level of annotation considered, boosted prompting improves performance over the corresponding self-consistency baseline. We see that boosted prompting is able to take advantage of the small training set when it is available, with the train-time version generally outperforming the test-time version. The one exception is on CMATH420, where the training set is quite small (71) and there is significant distributional shift between train and test. This provides some support for the hypothesis that test-time boosting can do online "prompt space exploration", although we leave a thorough investigation of this to future work.

**How sensitive is boosting to the initial prompt?**

From Table 1, we notice that as the quality of the prompt deteriorates, from the original, manually annotated few shot setting, to the zero shot setting, to the nonsense setting, so too does the performance of boosted prompting. This is understandable, because boosted prompting uses the model to provide self supervised chains of thought for all subsequent ensemble members and a worse initial prompt means worse self supervision. The performance of the original prompt is also a direct factor since we keep the original prompt as one of the ten ensemble members.

**How does varying the number of ensemble members / samples per ensemble member impact results?**

In Table 2, we report results on AQUA where we vary the number of prompts generated and reasoning paths we take from each prompt such that the total computational budget is fixed. We found the impact to be relatively small: all settings outperform bagging and self-consistency baselines.

| n x m | 10x10 | 20x5 | 33x3 | 50x2 |
| ----- | ----- | ---- | ---- | ---- |
| AQUA  | 63.4  | 62.8 | 62.2 | 61.6 |

**Table 2: Boosted Ensemble Composition.** Varying the ensemble composition has only minor performance impact.

[IMAGE: Suitable Agreement for Test-Time Boosting. The level of suitable agreement required for model generated answers to be deemed "correct", for purposes of new prompt formation, can greatly reduce the performance of test-time boosting if it is too low. In our main results we use a relatively high value of 0.8 for multiple choice datasets (AQUA and MMLU570) and a value of 0.7 for open-ended datasets. We used one seed on AQUA to study the effect of this hyperparameter.]

**How does the level of "sufficient agreement" for determining correctness impact test-time boosting?**

In the absence of training labels, our algorithm substitutes ground truth answer labels with model predictions, using a similar motivation as Huang et al. [huang2022large], whereby predictions with "sufficient agreement" are treated as correct. There is an inherent tradeoff: setting sufficient agreement higher means the predictions are more likely correct, but the selected problems may be less useful as a prompt, since the model already knows how to solve these problems. Figure 2 shows the AQUA performance and average prompt accuracy as we vary the minimum agreement hyperparameter, which indicates the threshold at which we consider model generated answers to be correct. Setting minimum agreement too low greatly reduces average prompt accuracy, since we might form prompts by choosing questions and answers pairs the model believes to be correct but are in fact not. This can then lead to a decrease in test-time performance, as the boosted prompts may contain more incorrect examples.

**Can we further improve performance by applying weights to the ensemble members?**

Classical boosting applies weights to the ensemble members [freund1999short]. Though lacking in mathematical motivation, we consider applying weights to boosted prompt ensembles via the K-class Adaboost formula from Hastie et al. [hastie2009multi]:

```latex
$$w_i = \log\left[({1 - \textrm{err}_i})/{\textrm{err}_i}\right] + \log(K-1)$$
```

except that we replace log(K-1) with a non-negative parametric offset that we optimize over using the training set. The results are shown in Table 3. We find the overall results unremarkable and reminiscent of the weighting results of Wang et al. [wang2022self], who found that weighted voting provided little advantage over a simple average.

| Dataset  | Unweighted | Weighted |
| -------- | ---------- | -------- |
| GSM8K    | 85.2       | 85.5     |
| AQUA     | 63.4       | 63.8     |
| MMLU570  | 71.2       | 70.8     |
| CMATH420 | 38.7       | 38.2     |

**Table 3: Weighted Boosting.** 3 seeds each. Applying weights to the boosted ensemble has only minor performance impact.

**Does choosing from the most complex generated chains of thought aid performance?**

When forming boosted prompts, the CoT is chosen from the several model samples that led to the correct (or majority) answer. Following Fu et al. [fu2022complexity], we sample from amongst the 5 most complex, which we determine by the combined number of "\n" and ". " substrings. Table 4 suggests that this choice improves performance.

| Setting           | Complex CoT | Random CoT |
| ----------------- | ----------- | ---------- |
| AQUA (train-time) | 63.4        | 62.1       |
| AQUA (test-time)  | 61.7        | 60.8       |

**Table 4: Choosing Complex vs Random CoTs.** Sampling randomly from model-generated CoTs (1 seed), instead of sampling from amongst the most complex CoTs (3 seeds), performs slightly worse, but still better than baselines.

**How does the choice of base LLM model impact relative performance?**

Table 5 contains the results of a subset of the experiments from Table 1 on three other models: `text-curie-001`, which is smaller than `code-davinci-002`; `text-davinci-003` model, which is the same size; and `gpt-3.5-turbo`, which is an effective model of unknown size that has been finetuned on related data. We see that boosted prompting is similarly effective for stronger `davinci` and `gpt-3.5` models, but not for the weaker `curie` model. We hypothesize this is because a minimal level of accuracy is needed to self-generate the boosted prompts (see Figure 2, which shows a nearly 1:1 correlation between average prompt accuracy and AQUA performance).

## t-SNE visualization

[IMAGE: t-SNE Visualization of embeddings on (question, reasoning) tuples on GSM8K dataset. The embeddings of the test set are scattered as faded blue dots. The prompts are shown with stars. The black stars are the initial prompt, and the next four prompts are shown in red, orange, yellow, and white, respectively. Although the initial prompt is biased toward the upper left side, later prompts explore the space, so that the ensemble has good coverage overall.]

In Figure 3, we show a visualization of the first five boosted prompts found by our train-time algorithm on the 1319 question GSM8K test set. We used OpenAI's `text-embedding-ada-002` model to generate 1536-dimensional embeddings for (question, reasoning) tuples on the test set and the prompts (from the training set) found by our algorithm. After applying t-SNE, we see that the coverage of boosted prompt set grows to cover the space.

# Conclusion

In this paper, we adapted classical boosting to the language model setting and proposed a few shot boosted prompt ensembling algorithm. On several reasoning benchmarks, we showed that boosted prompt ensembles outperform single prompt and bagged ensembles, especially when the initial prompt is suboptimal.

We proposed two variants of the algorithm, a train-time algorithm that uses training labels to select Hard problems and a test-time version that substitutes labels with model predictions. We hypothesized that our test-time boosting algorithm can function as a form of self-guided curriculum and perform test-time adaptation via online prompt space exploration. Though we provided some empirical evidence of this, we leave a thorough investigation of this to future work. We observed in our experiments that the performance of test-time boosting is strongly correlated with prompt accuracy. To further improve the effectiveness of test-time boosting and allow for prompt space exploration, future work may consider better options for verifying prompt accuracy, such as the use of a verifier [cobbe2021training; li2022advance], or debate [irving2018ai].

# Appendix: Implementation Details

We use certain functions from the existing implementations of Kojima et al. [kojima2022large] (available at https://github.com/kojima-takeshi188/zero_shot_cot) and Wang et al. [wang2022self] (available via their ICLR supplement), but largely build out our own implementation, which we have made available at https://github.com/awwang10/llmpromptboosting.

Our results on GSM8K differ slightly from past work due to a minor change in answer/prediction extraction and formatting:

- **GSM8K**: We apply the answer cleansing function to the answers, whereas past work applied it only to the prediction. We did this after noticing that sometimes answer cleansing on the prediction would change what should have been a correct answer (e.g., "200,000") to a different format (e.g., "200000") after which it was counted as incorrect. This change improves results by 0.6-0.9%.

We use 100-shot self-consistency for all implementations. As we noticed some variance, especially in AQUA results (due to a relatively small test set of 254 samples), we ran multiple seeds of the main results and baselines.

To choose which questions to use for bagged prompts, we sample randomly with replacement from the training set.

To choose which questions to use for boosted prompts, we sort the "suitable" question/answer pairs in ascending order of agreement with respect to the desired answer (the correct answer for the train-time algorithm, or the majority answer for the test-time algorithm), and sample 8 questions from the 24 suitable question/answer pairs with lowest agreement. "Suitable" is defined as having at least 1 correct generation for the train-time algorithm, and having at least "minimum agreement" agreement with respect to the predicted answer at test-time. Our test-time boosting uses a minimum agreement of 0.7 for open-ended datasets (GSM8K, CMATH420, SVAMP), and a slightly higher minimum agreement of 0.8 for multiple choice datasets (AQUA, MMLU570) because the answer distribution has lower entropy.

Having selected which questions and answers to use for our boosted (or bagged) prompts, we select the chain of thought from the model-generated chains of thought by sampling it randomly from the 5 most complex chain of thoughts that led to the desired answer. For this purpose, complexity was measured as:

```python
len(cot.replace('\n','. ').split('. '))
```

To reduce computational complexity at test-time, we move all predictions that have met the bar for "suitable agreement" to a "solved set", and consider their predictions final. We only continue to generate predictions with newer prompts on the remaining unsolved questions. When doing test-time boosting on GSM8K with a suitable agreement parameter of 0.7, the unsolved set is only 280 samples of the original 1319.

# Appendix: Online Boosted Prompting

We can run Boosted Prompting online by adding to our set of prompts whenever a new diverse prompt becomes available. For the first few questions, there will only be one prompt, and Boosted Prompting will be identical to Self Consistency. Once a few questions have been answered with sufficient agreement, a new prompt can be added to the ensemble and applied going forward.

## Algorithm 2: Online Boosted Prompting

**OnlineBoostedPrompting(T, prompts, N, pastp):**

- preds <- {q: pastp[q] for q in T} # [] if q is new
- n, m <- len(prompts), N/m
- For q in T:
  - For p in prompts:
    - preds[q].append([LLM(p,q)])
  - p <- NewPromptOnline(T, preds) # returns None if no new prompt
  - If p is not None:
    - prompts.add(p)
    - n, m <- len(prompts), N/m
- Return prompts, preds

**NewPromptOnline(T, preds):**

- C <- [q for q in T if there is "sufficient agreement" for the majority prediction in preds[q]]
- C <- choose 8 of the questions for which the majority prediction in preds[q] has _minimal_ agreement, if cannot, return None
- p <- for each question q in C choose one CoT from preds[q] that led to the answer/prediction
- Return p

# Appendix: Further Results

## Qualitative example difficulty

We investigate whether a measure of example difficulty can be identified via our ensemble of prompts and multiple generations for each prompt on AQUA. At test-time, we compute the empirical distribution over answer choices from running ten rounds of our algorithm (with ten generated responses at each iteration). Responses with no answers are removed. We then sorted the problems by the probability assigned to the option the model is most confident and report the 5 most extreme probabilities and their corresponding questions.

**Table 5: Test questions where the model is least confident.** Questions tend to be more challenging, ambiguous, or contain spelling errors. Max probability is computed by the empirical distribution from running ten rounds of our algorithm.

| Question                                                                                                                                                                                                                                                                                            | Max Probability |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| Of the three-digit integers greater than 700, how many have two digits T that are equal to each other and the remaining digit different from the other two?                                                                                                                                         | 0.255           |
| What annual payment dischargea debit of Rs.12900, due in 4yrs.At 5% rate?                                                                                                                                                                                                                           | 0.255           |
| 81,162,49,98,25,50,55                                                                                                                                                                                                                                                                               | 0.255           |
| Two dice are thrown together. What is the probability that the sum of the number on the two faces is divided by 4 or 6                                                                                                                                                                              | 0.258           |
| The Coen family consists of a father, a mother, two children and a dog. A photographer is about to take the family's picture. How many different arrangements (of standing in a row) does the photographer have, if it is known that the father insists of standing by his woman, as the song says? | 0.260           |

**Table 6: Test questions where the model is most confident.**

| Question                                                                                                                                                      | Max Probability |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| 200 + 8 x 4 = ?                                                                                                                                               | 0.917           |
| The price of a book is increased from $300 to $330. What is the % of increase in its price?                                                                   | 0.919           |
| What is the product of all the prime factors of 13?                                                                                                           | 0.930           |
| Two brother X and Y appeared for an exam. The probability of selection of X is 1/5 and that of B is 2/3. Find the probability that both of them are selected. | 0.969           |
| A man buys an article for $100 and sells it for $110. Find the gain percent?                                                                                  | 0.970           |

## t-SNE Visualization on AQUA

[IMAGE: Visualization of prompt embeddings on (question, reasoning) tuples on AQUA. The darker shades of blue indicate prompts generated at later iterations. Our boosting algorithm generates prompts which cover locations adjacent to incorrect answers.]

In Figure 4, we show a visualization of the prompts found by our algorithm on the 200 question AQUA training set. We used OpenAI's "text-embedding-ada-002" to generate 1536-dimensional embeddings for (question, reasoning) tuples on the training set and the prompts found by our algorithm. After applying t-SNE, we see that the boosted prompts achieve coverage over the space and are typically found near incorrect questions.
