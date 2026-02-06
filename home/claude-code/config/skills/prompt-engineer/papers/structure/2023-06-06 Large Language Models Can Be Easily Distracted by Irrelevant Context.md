# Large Language Models Can Be Easily Distracted by Irrelevant Context

**Authors:** Freda Shi, Xinyun Chen, Kanishka Misra, Nathan Scales, David Dohan, Ed Chi, Nathanael Scharli, Denny Zhou

**Affiliations:** Google DeepMind, Toyota Technological Institute at Chicago, Purdue University

**arXiv:** 2302.00093

---

## Abstract

Large language models have achieved impressive performance on various natural language processing tasks. However, so far they have been evaluated primarily on benchmarks where all information in the input context is relevant for solving the task. In this work, we investigate the *distractibility* of large language models, i.e., how the model problem-solving accuracy can be influenced by irrelevant context. In particular, we introduce Grade-School Math with Irrelevant Context (GSM-IC), an arithmetic reasoning dataset with irrelevant information in the problem description. We use this benchmark to measure the distractibility of cutting-edge prompting techniques for large language models, and find that the model performance is dramatically decreased when irrelevant information is included. We also identify several approaches for mitigating this deficiency, such as decoding with self-consistency and adding to the prompt an instruction that tells the language model to ignore the irrelevant information.

Dataset is available at https://github.com/google-research-datasets/GSM-IC.

## Introduction

Prompting large language models performs decently well in a variety of domains [brown2020language; chowdhery2022palm *inter alia*]. However, for most of theses evaluation benchmarks, all the information provided in the problem description is relevant to the problem solution, as the problems in exams. This is different from real-world situations, where problems usually come with several pieces of contextually related information, which may or may not be relevant to the problems that we want to solve. We have to identify what information is actually necessary during solving those problems. Studies in psychology have shown that irrelevant information may significantly decrease some children and even adults problem-solving accuracy [hoyer1979effects; pasolunghi1999working; marzocchi2002disturbing *inter alia*].

In this work, we study the *distractibility* of large language models for various prompting techniques; i.e., how is large language model prompting affected by irrelevant context, and what strategies can be used to improve performance? To measure distractibility, we construct the GSM-IC dataset, a grade-school math problem dataset derived from GSM8K [cobbe2021training] and introduce two different metrics. In contrast to prior work that derives benchmark variations by substituting sentences of the base problems with variations [patel2021nlp; kumar2021adversarial *inter alia*], we keep the base problem description and add to it one irrelevant sentence, while making sure that it does not affect the solution of the problem.

We use Codex (`code-davinci-002`) and GPT-3.5 (`text-davinci-003`) in the GPT3 model family to evaluate state-of-the-art prompting techniques on GSM-IC, including chain-of-thought prompting [CoT; wei2022chain], zero-shot chain-of-thought prompting [0-CoT; kojima2022large], least-to-most-prompting [LtM; zhou2022least], and prompting with programs [Program; chowdhery2022palm]. We find that their performance on GSM-IC greatly decreases compared to the original GSM8K (without irrelevant context). We then investigate several approaches to mitigate this weakness, including self-consistency [wang2022self] and adding irrelevant information to the exemplars in the prompt. In addition to demonstrating how to handle irrelevant information via exemplars, we also investigate the usage of task-specific instructions [wei2021finetuned; sanh2021multitask; ouyang2022training; suzgun2022challenging; chung2022scaling], where we prepend an instruction sentence *"feel free to ignore irrelevant information in the problem description"* to the exemplars. We summarize our key findings below:

1. All investigated prompting techniques are sensitive to irrelevant information in the problem description. In particular, among the original problems that can be solved by baseline prompts with greedy decoding, no more than 18% of them can be consistently solved for all types of irrelevant information, showing that the large language model is easily distracted and produces inconsistent predictions when adding a small amount of irrelevant information to the problem description.

2. Self-consistency improves the performance of all prompting techniques on GSM-IC. In particular, the recall rate of the correct answer for GSM-IC is as high as 99.7% with 20 samples per problem, i.e., at least one of the 20 solutions result in the correct final answer, which means that using multiple samples allows the model to almost always retrieve the correct answer.

3. Adding irrelevant information to the exemplars shown in the prompt consistently boosts the performance, and the same holds for adding an instruction to ignore irrelevant context. This suggests that language models are---to some extent---able to learn to ignore irrelevant information by following examples or instructions.

4. We identify different factors of the irrelevant information that affect the model's sensitivity to irrelevant context. Our breakdown analysis shows that varying the numbers in the irrelevant information does not notably change the model performance, while the degree of lexical overlap with the original problem description matters.

Filtering out irrelevant information is essential for handling real-world tasks. Our evaluation indicates that despite the strong performance on challenging reasoning problems, state-of-the-art language models still have fundamental weaknesses in context understanding and identifying the relevant information from the input. Our findings suggest that in order to gain a more holistic understanding of the reasoning capability of language models, future work should also consider the model sensitivity to irrelevant context, in addition to solving more challenging problems.

## Related Work

**Few-shot prompting.** Few-shot prompting [brown2020language; chowdhery2022palm *inter alia*] has been significantly boosted with various techniques, including generating intermediate steps [ling-etal-2017-program; cobbe2021training; nye2021show; wei2022chain; suzgun2022challenging; shi2022language *inter alia*], problem decomposition [zhou2022least; drozdov2022compositional; dohan2022language; khot2022decomposed; press2022measuring *inter alia*], generating programs [austin2021program; chowdhery2022palm; gao2022pal; chen2022program *inter alia*], marginalizing intermediate steps that share the same result [wang2022self; shi2022natural], and ensemble [wang2022rationale; drozdov2022compositional]. In addition, kojima2022large demonstrate that appropriate hint in prompts also leads to decent performance, even without any exemplar. In this work, we examine these cutting-edge prompting techniques [wei2022chain; zhou2022least; kojima2022large; wang2022self] on our benchmark, and demonstrate that they are sensitive to irrelevant input context.

**Natural language benchmarks with input perturbations.** There has been a long line of work on adding input perturbations for natural language tasks, including model-agnostic input transformations [liang2022holistic; ravichander2022condaqa *inter alia*] and adversarial example generation against individual models [jia2017adversarial; shi2018learning; morris2020textattack; wang2021adversarial]. In particular, prior work has constructed arithmetic reasoning benchmarks through paraphrasing or rewriting sentences in the base problems from clean datasets [patel2021nlp; kumar2021adversarial]. Meanwhile, liang2022holistic evaluate various large language models under several metrics, including accuracy, robustness, fairness, etc. Specifically, the input transformations in their robustness evaluation include semantics-preserving and semantics-altering perturbations, such as injecting typos and modifying sentences to change the ground-truth classification labels. In contrast the above work where the meaning of problem descriptions may be changed with perturbations, we keep all sentences in the original problem description, and introduce an irrelevant sentence that is ensured not to affect the standard answer.

**Natural language benchmarks with irrelevant input context.** jia2017adversarial have shown that neural question answering systems are largely affected by adversarial distracting sentences, whereas follow up work [khashabi-etal-2017-learning; ni-etal-2019-learning] proposes learning strategies that mitigate the problem. Similar issues have been found for general-purpose pretrained language models, on the tasks of factual reasoning [kassner-schutze-2020-negated; pandia-ettinger-2021-sorting; misra2022comps; li2022large], code generation [jones2022capturing], and syntactic generalization [chaves-richter-2021-look]. In particular, li2022large evaluated T5 [raffel2020exploring] and PaLM [chowdhery2022palm] with few-shot prompts, and proposed knowledge-aware finetuning that finetunes the model on problems with counterfactual and irrelevant context, which strengthens the model robustness to noisy context. In our evaluation, we show that without training or finetuning, adding irrelevant context into demonstrations in the prompt also mitigates the distractibility of the underlying language model and significantly improves the model performance on our GSM-IC benchmark.

There exist some logical reasoning benchmarks that contain irrelevant content in task descriptions [weston2015towards; sinha-etal-2019-clutrr; clark2021transformers; han2022folio; tafjord2020proofwriter *inter alia*]. However, previous work largely focuses on designing models that require extra training, and prompting alone still hardly achieves the same level of performance as finetuned models for these tasks [han2022folio; creswell2022selection]. In our work, we focus on arithmetic reasoning, where prompting techniques have achieved the state-of-the-art results, e.g., on GSM8K, while we show that adding a single irrelevant sentence into the problem description significantly degrades the performance.

**Prompting with noisy ground truth.** A line of work studies the model performance with incorrect prompting exemplars, i.e., the example problems are paired with wrong answers [min2022rethinking; kim2022ground]. In addition, prior work has investigated the model sensitivity to other parts of the prompt, such as instruction tuning with misleading and irrelevant instructions [webson2021prompt] and wrong reasoning steps in the examples [madaan2022text; wang2022towards]. In particular, madaan2022text conclude that the correctness of numbers and equations in chain-of-thought prompts does not play a key role in model performance, but using wrong entities and removing either equations or text explanation in the reasoning steps drastically hamper the performance. Different from this line of work, we always include correct answers to example problems in the prompt, and ensure that the irrelevant context added to the problem description does not change the ground truth answer. We show that the model performance significantly drops when presented with irrelevant context in problem descriptions, and different distributions of numbers and entities in the irrelevant context also lead to different levels of performance degradation.

## The GSM-IC Dataset

In this section, we introduce the creation process of the GSM-IC dataset (Section 3.1) and the evaluation metrics (Section 3.2).

### Dataset Creation

We randomly choose 1,000 problems from the GSM8K training set as a development set. To construct our base dataset, we then choose 100 problems from this development set that can be correctly solved by at least one of the prompting techniques mentioned in this paper; that is, our base dataset is an "easy" subset of GSM8K. Each base problem requires two to seven reasoning steps to solve. Among the 100 base problems, 60 of them can be solved with two reasoning steps. The full dataset statistics can be found in Appendix A.

We then generate the examples of our new dataset by adding to each base problem one sentence containing irrelevant information. We use a template-based method to generate these sentences, which can be characterized by the following three factors:

- **Topic of the inserted sentence.** We write templates for both in-topic and off-topic sentences. In-topic sentences are closely related to the topic of the original problem, whereas off-topic sentences are about a different topic.

- **Role name overlap**. Most sentence templates contain some role name blanks, which can be filled with names that may or may not overlap with the role names that occur in the problem. For blank fillers that have overlap with original role names, we: (1) randomly pick a role name `A` from the original problem description and (2) create the blank fillers with template such as `A's father` and `A's sister`.

- **Range of numbers**. Since we focus on arithmetic reasoning, most sentence templates also contain a number blank. We can choose to fill in the number blank with a number of similar or different magnitude to those in the original problem description. Concretely, for a number ```latex $a$ ```, if there exists a number ```latex $b$ ``` in the original problem description or solution such that ```latex $\frac{1}{10} \leq \frac{a}{b} \leq 10$ ```, we consider ```latex $a$ ``` as an in-range number, and otherwise an out-of-range number. Since the standard answer to GSM8K problems are all positive integers, we only consider positive integers as the number blank fillers.

We manually verify that (1) all the generated sentences are acceptable in English and that (2) adding them does not affect the standard solution of the base problem. Because the above factors are orthogonal, we generate for each base example a set of derived examples with different factor combinations. The full GSM-IC benchmark consists of 58,052 examples. More details about the dataset creation process can be found in Appendix A.

### Evaluation Metrics

For a problem ```latex $p$ ```, we denote its standard solution by ```latex $s(p)$ ```, and the solution of method ```latex $\mathcal{M}$ ``` by ```latex $\mathcal{M}(p)$ ```. To evaluate the distractibility of ```latex $\mathcal{M}$ ```, we consider the following two metrics:

- **Micro accuracy** ```latex $\textit{Acc}_\textit{micro}(\mathcal{M}; \mathcal{P})$ ``` is the average accuracy of method ```latex $\mathcal{M}$ ``` over all the test problems ```latex $\mathcal{P}$ ```.

```latex
$$\textit{Acc}_\textit{micro}(\mathcal{M}; \mathcal{P}) =
    \frac{
        \sum_{p \in \mathcal{P}}
            \mathbbm{1}\left[
                \mathcal{M}(p) = s(p)
            \right]
    }{
        |\mathcal{P}|
    }$$
```

This means that the micro accuracy weighs all the individual test problems equally.

- **Macro accuracy** ```latex $\textit{Acc}_\textit{macro}(\mathcal{M}; \mathcal{B})$ ``` is the average accuracy of method ```latex $\mathcal{M}$ ``` over classes of test problems, where each class ```latex $\mathcal{P}(b)$ ``` consists of the set of test examples derived from the base example ```latex $b \in \mathcal{B}$ ```. We define ```latex $\mathcal{M}$ ```'s prediction for a class ```latex $\mathcal{P}(b)$ ``` to be correct if and only if ```latex $\mathcal{M}$ ```'s prediction for all problems in this class are correct.

```latex
$$\textit{Acc}_\textit{macro}(\mathcal{M}; \mathcal{B}) =
    \frac{
        \sum_{b\in \mathcal{B}}
            \mathbbm{1}\left[
                \bigwedge_{p\in \mathcal{P}(b)}\left[
                    \mathcal{M}(p) = s(p)
                \right]
            \right]
    }{
        |\mathcal{B}|
    }$$
```

This means that the macro accuracy is the fraction of base problems that can be consistently solved no matter what irrelevant sentence is being added.

- **Normalized accuracy** measures how a method is affected by the distractors, considering its accuracy on base problems. For a micro or macro accuracy ```latex $a_\mathcal{M}$ ``` achieved by method ```latex $\mathcal{M}$ ```, we calculate its corresponding normalized accuracy by:

```latex
$$\textit{norm}(a_\mathcal{M}; \mathcal{M}) = \frac{a_\mathcal{M}}{n_\mathcal{M}}$$
```

where ```latex $n_\mathcal{M}$ ``` denotes the base problem accuracy of method ```latex $\mathcal{M}$ ```.

## Investigated Solutions

In the following section, we review the investigated prompting techniques (Section 4.1), present the formats of our prompts (Section 4.2), and introduce instructed prompting (Section 4.3).

### Base Techniques

**Chain-of-thought prompting [CoT; wei2022chain]** is a prompting technique that guides the language models to solve a problem in a step-by-step manner. By presenting exemplars that solve the corresponding problems with intermediate reasoning steps in the prompts, CoT significantly improves the reasoning performance over direct answer prediction without such intermediate reasoning steps.

**Zero-shot chain-of-thought prompting [0-CoT; kojima2022large]** is a variation of CoT where the prompt does not contain any exemplar. Instead, the model is prompted directly with the problem of interest followed by the instruction "*Let's think step by step:*".

**Least-to-most prompting [LtM; zhou2022least]** teaches language models to (1) break down a problem into subproblems, and (2) solve those subproblems sequentially using CoT. The final answer is that to the last subproblem.

**Program prompts [Program; chowdhery2022palm]** represent the arithmetic reasoning process as a program. Following prior work on solving GSM8K problems with code [chowdhery2022palm; gao2022pal; chen2022program], we include a Python program as the problem solution in the prompt, and execute the generated Python code using an external Python interpreter to obtain the final answer.

**Self-consistency** [SC; wang2022self; shi2022natural] may further boost the reasoning performance by marginalizing over intermediate reasoning steps that share the same final result. In practice, SC can be implemented by (1) sampling several solutions from the large language model and (2) taking the majority vote. Note that SC is orthogonal to above techniques, and can be combined with any of them.

### Prompt Design

We present some example prompts used in our experiments. For few-shot prompting techniques (i.e., CoT, LtM and Program), the input prompt includes exemplar problems and their solutions before the problem of interest. In order to keep simplicity and avoid over-fitting in prompt engineering, we follow zhou2022least on exemplar creation; that is, we only use one simple exemplar for our main experiments. This exemplar is either based on the [Original Problem] or the [Problem with Irrelevant Context], which allows us to investigate the effect of irrelevant information in the prompt exemplar. For 0-CoT, we adhere to kojima2022large and directly present the problem of interest followed by "*A: Let's think step by step:*".

### Instructed Prompting

In addition to presenting irrelevant information in the exemplars, we also investigate whether natural language instructions help language models ignore irrelevant context and become less distracted. Extending the line of work [suzgun2022challenging; sanh2021multitask; ouyang2022training] that includes a general task description before exemplars, we add the sentence *"Solve grade school math problems. Feel free to ignore irrelevant information given in the questions."* before our exemplars in the prompt, which explicitly *instructs* the language model to ignore irrelevant information in the problem description.

## Experiments

Being mindful of the experiment costs, we uniformly sample 4,000 examples from the GSM-IC dataset (denoted by GSM-IC-4K) for evaluation and analysis purposes throughout this paper. Unless otherwise specified, we mainly use `code-davinci-002` in our experiments, and we also evaluate `text-davinci-003` which is a model trained with RLHF to better follow instructions [ouyang2022training]. For experiments without self-consistency decoding, we use greedy decoding (i.e., temperature ```latex $\tau=0$ ```); for self-consistency experiments that require multiple samples for a problem, we sample 20 responses with temperature ```latex $\tau=0.7$ ``` following wang2022self.

### Main Results on GSM-IC

We compare the performance of different prompting techniques on GSM-IC-4K, in terms of both micro and macro accuracies, as well as their corresponding normalized accuracies. Overall, we observe significant performance drop for both models with all prompting techniques. The drop on macro accuracy is especially large, showing that fewer than 30% of the base problems are consistently solved after adding distractors. Comparing the results of two models, `text-davinci-003` achieves better normalized micro accuracy than `code-davinci-002`, though its macro accuracy is mostly worse. One common error type is wrongly using the number in the irrelevant sentence, as shown in the LtM prediction and other examples in Appendix B. Even if the model does not directly use the irrelevant number for numerical calculation, the presence of the irrelevant sentence in the reasoning steps alone can still cause a wrong prediction, as shown in the CoT prediction.

**LtM is generally the most robust technique to irrelevant context.** In terms of micro accuracy, LtM outperforms all other prompting methods across models. Using `code-davinci-002`, LtM achieves about double macro accuracy of CoT. Interestingly, with `text-davinci-003`, despite that LtM outperforms CoT on the micro accuracy, its macro accuracy is lower. Specifically, `text-davinci-003` is highly susceptible to irrelevant context with role overlap; e.g., such irrelevant sentences decrease the macro accuracy to 0 on problems with more than 2 reasoning steps.

**Selecting exemplars with distractors mitigates the distractibility.** For few-shot prompts, we find that using exemplars with distractors (i.e., including problems with irrelevant context) consistently outperforms using the original exemplars without distractors across prompting techniques. While prior work has shown that training and fine-tuning with different types of problems improves model robustness [li2022large], our results show that prompting with exemplars that demonstrate how to ignore irrelevant context also results in significant robustness improvement. We further show that using exemplars with distractors does not cause a performance drop on the original GSM8K dataset, indicating that such a prompt design can be beneficial in achieving better accuracy and robustness simultaneously.

**Self-consistency significantly reduces the distractibility.** Taking the majority vote from 20 samples, SC improves the overall micro accuracy by more than 11 percentage points. This means that in addition to improving model performance on clean arithmetic reasoning tasks [wang2022self], SC also substantially reduces the distractibility of large language models to irrelevant context. The gain on micro accuracy is notably large on 0-CoT (35.5 percentage points). Furthermore, the correct answer for 99.7% of the problems is in the 20 sampled answers for both CoT and LtM. Even for 0-CoT, the recall of correct solutions within 20 samples is 96.5%. Despite these improvements, the best macro accuracy among all prompting techniques is only 45%, suggesting that for more than half of the base problems, SC fails to prevent the model from being distracted by different variants of irrelevant information. These results imply that a better algorithm may be developed to further reduce the distractibility based on a few sampled solutions.

### Break-Down Analysis

#### Factors of the Irrelevant Context

We analyze the performance of CoT, LtM and Program with respect to the considered factors (Section 3.1) of the irrelevant sentences. For both models, we find that (1) in-topic sentences with (2) role name overlap and (3) in-range numbers are generally more challenging. For LtM, the latter two factors do not have a large effect on the micro accuracy. The difference is more significant for the macro accuracy and, as an anomaly, using distractors with in-range numbers turns out to be less challenging than out-of-range numbers when using irrelevant context in the exemplar. Again, with `code-davinci-002`, LtM outperforms CoT and Program on all investigated sub-categories. On the other hand, using `text-davinci-003`, LtM outperforms CoT in terms of the micro accuracy, but the macro accuracy is much lower on all sub-categories.

#### Break-Down Accuracies w.r.t. Number of Steps

We analyze the break-down accuracies for problems with respect to the reasoning steps. While we see a significant drop for CoT and Program on problems that require four or more steps in the reasoning process, the performance of LtM is fairly consistent across difficulty. In addition to the advantage of LtM on clean problems for complicated reasoning [zhou2022least], our results show that LtM is also less sensitive to irrelevant context for complicated problems that require more steps to solve.

### Instructed Prompting Improves Robustness to Irrelevant Context

We have shown that using exemplars with distractors improves robustness to irrelevant context. We also compare the performance of instructed prompting and that of the prompts without instructions. Adding instructions to CoT, LtM, and Program consistently improves their performance. Surprisingly, instructed prompting with original exemplars reaches comparable or even better performance than uninstructed prompting that uses exemplars with distractors for both CoT and LtM. Note that adding the instruction *"Solve grade school math problems."* alone does not significantly improve the performance, and it is the instruction *"Feel free to ignore irrelevant information given in the questions."* that makes the difference. Similar to the instruction *"Let's think step by step."* employed by 0-CoT, this shows that language models are---to some extent---able to follow natural language instructions in a way that dramatically changes their problem solving behavior, suggesting that such instructions may be useful for guiding the behavior of language models on more tasks.

On the original GSM8K development set [cobbe2021training; zhou2022least], we do not observe a drop in accuracy when using exemplars with irrelevant information, adding natural language instructions, or both. The same holds for SVAMP [patel2021nlp], an arithmetic reasoning benchmark constructed by applying different types of variations to math problems from existing clean datasets, e.g., changing sentence structures, asking different questions with the same information, etc. This is impressive because the results on GSM-IC show that prompt exemplars with irrelevant information and instructed prompting both improve robustness. For the Program prompt, we find that using exemplars with distractors even increases performance on SVAMP.

### Complicated Prompts May Hurt the Robustness to Irrelevant Context

We compare our 1-exemplar CoT prompt to a 4-exemplar prompt [Appendix D of zhou2022least], which is reported as the best-performing CoT prompt on GSM8K, on GSM-IC. Note that the 1-exemplar CoT prompt only includes a problem with a 2-step solution, while the 4-exemplar prompt includes problems that require more reasoning steps. While the 4-exemplar prompt leads to better performance on the original GSM8K development set, the 4-exemplar prompt is surprisingly more susceptible to the distraction provided by the irrelevant context. In particular, the 4-exemplar prompt is consistently worse than the 1-exemplar prompt on problems with more than 2 intermediate steps. Even for 2-step prompts, the accuracy improvement from adding more exemplars is almost negligible when using instructions (79.0 vs 79.2). Overall, this finding indicates that adding more exemplars can make the prompt less robust as it leads to some overfitting.

### Extension to DROP

In addition to GSM-IC, we extend our evaluation to the DROP dataset [dua2019drop], where the task is to answer a question according to a long passage that naturally contains irrelevant context. We show an example about football games:

**Example (DROP dataset):**

**Paragraph:** The Seahawks played the San Francisco 49ers. In the first quarter, the Hawks RB Julius Jones got a 27-yard TD run, along with DT Craig Terrill returning a fumble 9 yards for a touchdown. In the third quarter, the 49ers almost rallied as RB H. J. Torres made a 12-yard TD pass to Lucas Nelly, along with Mare kicking a 32-yard field goal. In the final quarter, Julius Jones got another 11-yard TD.

**Question:** How many yards do the shortest touchdown run and the longest touchdown pass combine for?

**LtM solution:** To answer the question "How many yards do the shortest touchdown run and the longest touchdown pass combine for?", we need to know: "How many yards was the shortest touchdown run?", "How many yards was the longest touchdown pass?".

Q: How many yards was the shortest touchdown run?
A: All the touchdown runs are: a 27-yard touchdown run, a 9-yard touchdown run, a 11-yard touchdown run. The smallest number between 27, 9, 11 is 9. The shortest touchdown run was 9 yards. The answer is 9.

Q: How many yards was the longest touchdown pass?
A: All the touchdown passes are: a 12-yard touchdown pass. The longest touchdown pass was 12 yards. The answer is 12.

Q: How many yards do the shortest touchdown run and the longest touchdown pass combine for?
A: We know that the shortest touchdown run was 9-yard. We also know that the longest touchdown pass was 12-yard. 9 + 12 = 21. The answer is 21.

We use the CoT and LtM prompts in [zhou2022least] as the baselines, and we evaluate the prompt variants with the instruction *"Solve following questions. Feel free to ignore irrelevant information given in the questions."* added before the exemplars. Note that by adding a problem reduction step in the exemplar solution, the least-to-most prompt implicitly leads the model to come up with relevant subproblems to solve the given problem. Again, we observe that the instruction consistently improves the performance of both CoT and LtM prompting.

## Conclusion and Discussion

In this work, we introduce GSM-IC, a dataset that supports comprehensive study of the distractibility of large language models when performing arithmetic reasoning in presence of irrelevant contexts. We examine a variety of prompting techniques on GSM-IC, and demonstrate that they are all sensitive to the irrelevant information in the problems. Among the studied techniques, self-consistency [wang2022self] leads to a substantial improvement in robustness to irrelevant context across the board, and presenting example problems with irrelevant context in the prompt also consistently improves the performance. Similarly, we find that simply adding an instruction to ignore irrelevant information brings notable performance gains on our benchmark.

Despite the improvement achieved by these methods, the fundamental issue remains: a single piece of irrelevant information can distract the models and substantially degrade their performance, even on problems whose clean versions they correctly solve. We encourage researchers to also prioritize improving on this fundamental limitation when developing new training and prompting techniques. We leave further investigation on the distractibility for other tasks and different language models for future work.

## Appendix A: GSM-IC Details

Each of the 100 base problem require two to seven steps to solve.

[IMAGE: Base problem distribution of GSM-IC with respect to the number of reasoning steps in the ground truth problem solution (n-steps.pdf)]

Starting from the base problems, we follow the protocols below to create GSM-IC (Section 3.1).

1. **Irrelevant sentence template**.

   a. For in-topic sentences, we manually write templates within the topic that is close to the original problem description. We are particularly careful about the shareable stuff, for example, money is sometimes considered shareable between family members. In such cases, we make sure that the added do not change the amount of shareable stuff to ensure that the final standard answer is not affected.

   b. For off-topic sentences, we use general templates for all problems unless some of them can be considered as in-topic sentences for some problems---for example, the sentence "*The height of {role} is {number} feet.*" is considered as an in-topic sentence for problems about heights of people.

   **Off-topic sentence templates for GSM-IC:**
   - The shoe size of `[ROLE]` is `[NUMBER]`.
   - `[ROLE]` is `[NUMBER]` years old.
   - The height of `[ROLE]` is `[NUMBER]` feet.
   - `[ROLE]` bought `[NUMBER]` tomatoes from the grocery store.
   - `[ROLE]` has read `[NUMBER]` books in the past year.

   c. We make sure that all sentences derived by each template are grammatical English sentences.

   d. We write four in-topic and choose four off-topic distractor sentence templates for each problem.

2. **Blank fillers: role names**.

   a. We randomly choose a role name `X`, and use `X's father`, `X's mother`, `X's brother`, `X's sister` and `X's neighbor` as the overlapped role names.

   b. We choose from the name set `{Ada, David, Emma, Jack, John, Mary, Max, Tom}` for non-overlapped role names.

   c. We write five names that have overlap with the original character, and five names that do not have overlap for each problem.

3. **Blank fillers: numbers**.

   a. For in-range numbers, we randomly sample positive integers in the range of ```latex $[\frac{\ell}{10}, 10r]$ ```, where ```latex $\ell$ ``` and ```latex $r$ ``` denote the smallest and the largest number that appear in the problem description and standard solution, respectively.

   b. For out-of-range numbers, we choose from the range of ```latex $[2, +\infty) \backslash [\frac{\ell}{10}, 10r]$ ```. For very few problems that ```latex $\ell$ ``` is relatively large (i.e., ```latex $\ell > 10^5$ ```) where we choose out-of-range numbers from the range of ```latex $[2, \frac{\ell}{10}]$ ```; for other problems we choose out-of-range numbers ```latex $n = a\times 10^b$ ``` from the range ```latex $[10r, \infty)$ ```, where ```latex $a$ ``` and ```latex $b$ ``` are both non-negative integers.

   c. We write four in-range numbers and four out-of-range numbers for each problem.

4. Finally, if adding the irrelevant sentence causes ambiguity, we fix the question to ensure that the standard solution to the generated problem remain the same as the base problem.

   **Example of ambiguity:**

   | **Original Problem** | Kim plants 80 cherry pits. 25% of them sprout and Kim sells 6 of the saplings. How many cherry saplings does she have left? |
   |---------------------|-----------------------------------------------------------------------------------------------------------------------------|
   | **Added Sentence** | Kim's mother plants 20 more potatoes. |
   | **Ambiguous Problem** | Kim plants 80 cherry pits. 25% of them sprout and Kim sells 6 of the saplings. Kim's mother plants 20 more potatoes. How many cherry saplings does she have left? |
   | **Fixed Problem** | Kim plants 80 cherry pits. 25% of them sprout and Kim sells 6 of the saplings. Kim's mother plants 20 more potatoes. How many cherry saplings does Kim have left? |

   After adding the sentence, it is unclear whether "she" refers to Kim or Kim's mother. To ensure that the standard answer is unchanged, we modify the final question to make it clear and faithful to the original problem.

## Appendix B: Sample Predictions on GSM-IC

**Example 1:**

| **Method** | **Original GSM8K Problem** | **Modified Problem (w/ Irrelevant Sentence)** |
|------------|---------------------------|-----------------------------------------------|
| | Jessica is six years older than Claire. In two years, Claire will be 20 years old. How old is Jessica now? | Jessica is six years older than Claire. In two years, Claire will be 20 years old. Twenty years ago, the age of Claire's father is 3 times of Jessica's age. How old is Jessica now? |
| **CoT** | In two years, Claire will be 20 years old. So, Claire is 18 years old now. Jessica is six years older than Claire, so Jessica is 18 + 6 = 24 years old now. The answer is 24. | Jessica is six years older than Claire, so Jessica is 20 - 6 = 14 years old. Twenty years ago, the age of Claire's father is 3 times of Jessica's age, so 20 years ago, the age of Claire's father is 3 * 14 = 42 years old. The answer is 14. |
| **LtM** | Let's break down this problem: 1. How old is Claire now? 2. How old is Jessica now? 1. In two years, Claire will be 20 years old. So Claire is 20 - 2 = 18 years old now. 2. Jessica is six years older than Claire. So Jessica is 18 + 6 = 24 years old now. The answer is 24. | Let's break down this problem: 1. How old is Claire now? 2. How old is Jessica now? 1. In two years, Claire will be 20 years old. So Claire is 18 years old now. 2. Twenty years ago, the age of Claire's father is 3 times of Jessica's age. So 20 years ago, Claire's father is 3 * Jessica's age... So Jessica is 2 years old now. The answer is 2. |
| **Program** | Claire_age = 20 - 2; Jessica_age = Claire_age + 6; print(Jessica_age) | Claire_age = 20 - 2; Jessica_age = Claire_age - 6; Claire_father_age = 3 * Jessica_age; print(Jessica_age) |

**Example 2:**

| **Method** | **Original GSM8K Problem** | **Modified Problem (w/ Irrelevant Sentence)** |
|------------|---------------------------|-----------------------------------------------|
| | Lucy has $65 in the bank. She made a $15 deposit and then followed by a $4 withdrawal. What is Lucy's bank balance? | Lucy has $65 in the bank. She made a $15 deposit and then followed by a $4 withdrawal. Lucy's mother's monthly rent is $10. What is Lucy's bank balance? |
| **CoT** | Lucy has $65 in the bank. She made a $15 deposit, so she has $65 + $15 = $80. She then made a $4 withdrawal, so she has $80 - $4 = $76. The answer is $76. | Lucy has $65 in the bank. She made a $15 deposit and then followed by a $4 withdrawal. Lucy's mother's monthly rent is $10. Lucy's bank balance is $65 + $15 - $4 - $10 = $66. The answer is $66. |
| **LtM** | Let's break down this problem: 1. How much money did Lucy deposit? 2. How much money did Lucy withdraw? 3. How much money does Lucy have in the bank? 1. Lucy deposited $15. 2. Lucy withdrew $4. 3. Lucy has $65 + $15 - $4 = $76 in the bank. The answer is $76. | Let's break down this problem: 1. How much money did Lucy deposit? 2. How much money did Lucy withdraw? 3. How much money does Lucy have in the bank? 1. Lucy deposited $15. 2. Lucy withdrew $4. 3. Lucy has $65 + $15 - $4 - $10 = $66 in the bank. The answer is $66. |
| **Program** | Lucy_balance = 65; Lucy_balance = Lucy_balance + 15; Lucy_balance = Lucy_balance - 4; print(Lucy_balance) | Lucy_bank = 65; Lucy_bank = Lucy_bank + 15; Lucy_bank = Lucy_bank - 4; Lucy_bank = Lucy_bank - 10; print(Lucy_bank) |

## Appendix C: Full prompts in experiments

**Prompts without instruction:**

| **Method** | **Example** | **Prompt** |
|------------|-------------|------------|
| **CoT** | Original | Q: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together? A: Anna has 2 more apples than Elsa, so Anna has 2 + 5 = 7 apples. Elsa and Anna have 5 + 7 = 12 apples together. The answer is 12. Q: [Problem of Interest] A: |
| **CoT** | Distractor | Q: Elsa has 5 apples. Anna has 2 more apples than Elsa. Liz has 4 peaches. How many apples do they have together? A: Anna has 2 more apples than Elsa, so Anna has 2 + 5 = 7 apples. Elsa and Anna have 5 + 7 = 12 apples together. The answer is 12. Q: [Problem of Interest] A: |
| **LtM** | Original | Q: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together? A: Let's break down this problem: 1. How many apples does Anna have? 2. How many apples do Elsa and Anna have together? 1. Anna has 2 more apples than Elsa. So Anna has 2 + 5 = 7 apples. 2. Elsa and Anna have 5 + 7 = 12 apples together. Q: [Problem of Interest] A: Let's break down this problem: |
| **LtM** | Distractor | Q: Elsa has 5 apples. Anna has 2 more apples than Elsa. Liz has 4 peaches. How many apples do they have together? A: Let's break down this problem: 1. How many apples does Anna have? 2. How many apples do Elsa and Anna have together? 1. Anna has 2 more apples than Elsa. So Anna has 2 + 5 = 7 apples. 2. Elsa and Anna have 5 + 7 = 12 apples together. Q: [Problem of Interest] A: Let's break down this problem: |
| **0-CoT** | N/A | Q: [Problem of Interest] A: Let's think step by step: |
| **Program** | Original | Q: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together? A: Let's solve the problem by a Python program: Elsa_apples = 5; Anna_apples = 2 + Elsa_apples; Elsa_Anna_apples = Elsa_apples + Anna_apples; print(Elsa_Anna_apples) Q: [Problem of Interest] A: Let's solve the problem by a Python program: |
| **Program** | Distractor | Q: Elsa has 5 apples. Anna has 2 more apples than Elsa. Liz has 4 peaches. How many apples do they have together? A: Let's solve the problem by a Python program: Elsa_apples = 5; Anna_apples = 2 + Elsa_apples; Elsa_Anna_apples = Elsa_apples + Anna_apples; print(Elsa_Anna_apples) Q: [Problem of Interest] A: Let's solve the problem by a Python program: |

**Prompts with instruction:**

All prompts above with the prefix: *"Solve grade school math problems. Feel free to ignore irrelevant information given in the questions."*

For 0-CoT with instruction: *"Solve grade school math problems. Feel free to ignore irrelevant information given in the questions. Q: [Problem of Interest] A: Let's think step by step:"*

The placeholder [Problem of Interest] is substituted for each problem at the test time.
