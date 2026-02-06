# Abstract

Despite demonstrating emergent reasoning abilities, Large Language Models (LLMS) often lose track of complex, multi-step reasoning. Existing studies show that providing guidance via decomposing the original question into multiple subproblems elicits more robustness in LLM reasoning -- a decomposer generates the subproblems, and a solver solves each of these subproblems. However, these techniques fail to accommodate coordination between the decomposer and the solver modules (either in a single model or different specialized ones) -- the decomposer does not keep track of the ability of the solver to follow the decomposed reasoning. In this paper, we propose LM^2 to address these challenges. LM^2 modularizes the decomposition, solution, and verification into three different language models. The decomposer module identifies the key concepts necessary to solve the problem and generates step-by-step subquestions according to the reasoning requirement. The solver model generates the solution to the subproblems that are then checked by the verifier module; depending upon the feedback from the verifier, the reasoning context is constructed using the subproblems and the solutions. These models are trained to coordinate using policy learning. Exhaustive experimentation suggests the superiority of LM^2 over existing methods on in- and out-domain reasoning problems, outperforming the best baselines by 8.1% on MATH, 7.71% on JEEBench, and 9.7% on MedQA problems (code available at https://github.com/LCS2-IIITD/Language_Model_Multiplex).

# Introduction

Recent trends in solving complex reasoning tasks using Large Language Models (LLMs) typically follow two different dominant approaches: (i) well-curated prompting techniques [PHP; yao2024tree] on LLMs of exorbitant size like GPT-4 [openai2023gpt4], or (ii) finetuning a relatively smaller LLM using domain-focused data [shao2024deepseekmath; toshniwal2024openmathinstruct; dutta2024frugal]. Methods from the former category heavily rely on the proprietary LLM being used and are prone to fail absolutely when employed with less powerful models. The latter category, though cost-effective compared to humongous LLMs, often loses in generalizability due to a narrow training domain.

**The chronicle of decomposed reasoning.** A number of recent literature has pointed out that LLMs tend to perform better on complex reasoning tasks when the problem is decomposed into step-by-step subproblems [least-to-most; DSP; juneja-etal-2023-small]. Earlier techniques demonstrated the superiority by providing the model with examples containing the original problem decomposed into multiple sub-problems along with their answers [least-to-most]. However, Juneja et al. [juneja-etal-2023-small] illustrated that decoupling the decomposer from the solver by finetuning a separate decomposer language model (LM) to coordinate with a larger solver LM is beneficial to simply prompting a single monolithic LM to decompose and solve. Echoing their findings, Wu et al. [wu2024divideorconquer] also found that distilling decomposition abilities from a larger LM to a smaller LM is much more generalizable compared to decomposing the solver abilities directly.

[IMAGE: The inference procedure of LM^2 on a question from the MATH dataset. A question (in blue) is provided to the Solver LM that produces an incorrect answer (in red). The question is then provided to the Decomposer LM that generates the concepts and step-by-step subquestions (in lilac). Each subquestion is answered by the Solver LM, and the sub-answer is verified by a Verifier LM. If the Verifier LM approves the sub-answer, that subquestion-subanswer pair is added to the context of reasoning steps; otherwise, a new subquestion is generated. The question, concepts, subquestions, and subanswers are provided in context to the Decomposer LM to generate the next subquestion. Finally, the question, concepts, subquestions, and subanswers are provided to the Solver LM to generate the final answer (in green). (ACL_TC.pdf)]

**Our contributions.** However, a major bottleneck in existing methods of decomposer finetuning is the lack of tightness between the decomposer-solver interactions. Typically, the decomposition is done in a memoryless manner, with or without the solver's initial response; no strategy is employed to track whether the solver can follow the decomposed chain of reasoning. Towards this very end, we propose a novel multi-LLM coordination framework, **L**anguage **M**odel **M**ultiplex (LM^2). LM^2 is built upon three separate LMs, each dedicated to three different components of complex multistep reasoning -- a **solver** LM is responsible for answering questions; a **verifier** LM provides feedback on the correctness of the output from the solver, and a **decomposer** LM identifies the basic concepts required to solve the problem and generates step-by-step subproblems by decomposing the original question (see Figure 1 for a working example). Unlike prior approaches, the decomposer in LM^2 generates each subproblem depending on the solver's answers to prior subproblems, along with the verifier's feedback on those answers. Furthermore, the decomposer generates the conceptual requirements to solve the problem, which further streamlines the solver LM. Irrespective of the complexity of the underlying reasoning, the world knowledge required to answer any question is typically better preserved in larger, proprietary LMs. Considering this, we use GPT-3.5 (text-davinci-003) as the solver without finetuning. For both the decomposer and verifier, we implement parameter-efficient fine-tuning [LoRA] of LLaMA-2 (13 billion parameters) separately. First, these models are finetuned separately towards the tasks of decomposition and verification using datasets annotated by GPT-4. The decomposer is then taught to coordinate with the solver and the verifier models in a policy learning setup. LM^2 achieves promising performance across a diverse set of reasoning tasks. On the MATH dataset of mathematical reasoning, LM^2 outperforms the best decomposer-tuning baseline by a staggering margin 8.1% of absolute accuracy on average. Although LM^2 uses the training split of the MATH dataset for tuning the decomposer and the solver, it seamlessly generalizes to out-of-distribution tasks in MedQA and JEEBench, outperforming the best competitive baseline with 9.7% and 7.71% difference on absolute accuracy respectively.

Beyond the discourse of overall numbers, we perform in-depth ablation analyses to identify the roles of each component of the model. We observe that (i) the verifier LM and concept generated by the decomposer LM play a crucial role in generalizing out-of-distribution reasoning tasks like MedQA, JEEBench Chemistry, etc.; (ii) finetuning the decomposer is crucial for better concept identification -- finetuned LLaMA-2 7B generates more effective conceptual requirements compared to even GPT-4; (iii) even while not using all the modular components of LM^2, the prompt template of structured reasoning boosts the performance of GPT-4.

# Related Work

The efficacy of explicitly generating intermediate reasoning steps over direct generation of the required answer was first demonstrated by Nye et al. [nye2021scratchpad]. Chain-of-thought prompting [CoT] generalized the scratchpad learning of Nye et al. into an in-context learning regime using LLMs. Chain-of-thought and its successors [chen2022program; yao2024tree] typically let the decomposition of a composite, multi-step reasoning problem remain implicit in the LLM.

Zhou et al. [least-to-most] demonstrated that instead, an explicit call to the LLM to generate multiple smaller problems that are steps to answer the original query achieves more robust reasoning. Their proposed method, Least-to-Most prompting, uses these simpler subproblems and their answers as the context to solve the original problem. Similarly, Khot et al. [khot2023decomposed] proposed a prompting-based problem decomposition approach where the LLM is asked to decompose a complex task using few-shot examples. However, this still burdens a single language model in handling both decomposition and solution. Juneja et al. [juneja-etal-2023-small] circumvented this challenge by distilling the decomposition abilities into a relatively smaller language model. Their proposed method, DaSLaM, utilizes two separate language models that coordinate with each other to solve complex reasoning problems. Their findings suggest that finetuning the decomposer is more generalizable than finetuning the solver model. This has been further supported by Wu et al. [wu2024divideorconquer] recently. Tarasov and Shridhar [tarasov2024distilling] explored the distillation of decomposition abilities via offline reinforcement learning. Khattab et al. [DSP] proposed a programmatic retrieval augmentation framework, namely Demonstrate-Search-Predict (DSP), for knowledge-intensive generation tasks. DSP relies on the coordination between a generative LM and a retrieval model through sophisticated programs. Recent attempts have been made to incorporate dense verifiers (typically, a finetuned, bidirectional language model acting as a classifier) aiding a generative model towards robust, verifiable problem solving and text generation [cobbe2021training; sun2023towards]. Different techniques for verification of LM-generated outputs have been proposed subsequently, such as self-verification [weng2023large], majority voting [li2023making], etc.

# Methodology

Our proposed method, LM^2, is built upon the coordination of multiple LMs to perform reasoning in a modular fashion. However, such coordination is not implicit in the pertaining stage of a model; instead, we seek to inculcate this ability via finetuning (parts of) the LM multiplex. To this end, LM^2 is built upon three functional components: a (preferably larger) solver model, a decomposer model, and a verifier model.

For fine-grained control over the function of the different components of LM^2, we make use of a structured, step-by-step input-output framework (see Figure 1). The role of each of the modules in LM^2 is described as follows.

## Decomposer

The decomposer LM guides the solver LM to solve a multi-step reasoning question in two ways. First, it provides the solver model with a set of concepts required to solve the problem. Second, it tells the solver LM what is the next sub-question required to solve given the previous sub-questions and their answers. More specifically, the decomposer LM is a function that can be defined as `latex $D(q, \{s_i, sa_i\}, c): Q \times S \times SA \rightarrow \{S, C\}$ `, where `latex $q$ ` represents the initial question to be solved, `latex $\{s_i, sa_i\}$ ` denotes the set of previous sub-questions (`latex $s_i$ `) and their corresponding answers (`latex $sa_i$ `), and (`latex $c$ `) signifies whether the function needs to predict the concept or the next sub-question. `latex $Q$ ` is the space of all the questions, `latex $S$ ` is the space of all sub-questions, `latex $SA$ ` is the space of all sub-answers, and `latex $C$ ` is the space of all concepts.

**Supervised finetuning.** The decomposer training is performed in two stages similar to [juneja-etal-2023-small]. The first stage is supervised finetuning, where the language model is finetuned on a dataset prepared using GPT-4. To create the dataset, we provided GPT-4 with a question and its gold reasoning. It was then asked to first generate all the concepts required to solve the question, followed by sub-questions and sub-answers. Only the questions that were answered correctly were included in the dataset. Each sample in the dataset can be expressed as a tuple `latex $\{Q, c, \{s_i, sa_i\}_{i=1}^n, s_{n+1}\}$ `, where `latex $s_{n+1}$ ` is the next sub-question given the previous sub-questions and answers. The decomposer was then finetuned on the standard language modelling objective.

**Policy optimization.** With the supervised finetuning step, the decomposer LM is conditioned to respond to reasoning problems with concepts and decomposed subquestions. However, it is still not able to take the feedback from the solver and the verifier models into account. To this end, we utilize Proximal Policy Optimization [ppo] with the decomposer as the policy and the solver and the verifier model as a black-box environment. Precisely, we compute different types of rewards utilizing the feedback from the verifier model that takes the solver model's response into account at each step and provides the decomposer with necessary refinement signals.

## Verifier

Given the complexity of multistep reasoning, we need the verifier to be able to provide nuanced feedback to the decomposer on the possible mistakes made by the solver; a binary correct/incorrect message as employed by prior works with verifiers [li2023making; weng2023large] will limit the decomposer model's scope of vision. For fine-grained control, the verifier is finetuned on a supervised dataset containing a question, an answer with an error made in the correct answer, a classification for the type of error, and an explanation for the classification. The verifier classifies the given input into nine classes as follows: (1) Conceptual mistakes, (2) Computational mistakes, (3) Procedural mistakes, (4) Misunderstood question, (5) Mistake in the first step, (6) Mistake in first half, (7) Mistake in second half, (8) Mistake in last step, and (9) No mistake. The dataset was produced using GPT-4, asking it to generate an explanation for the classification given the correct solution, wrong solution and the classification. The verifier is finetuned to generate the explanation and the classification (see Section 3.3 for examples of each type of error message and explanation).

## Training with Decomposer Feedback

The training dataset curated for the decomposer LM consists of only the correct answers; hence, the decomposer is blind to the possible errors that the language model can make. In order to make the decomposer generate meaningful questions, we further finetune the decomposer while working in synergy with the solver language model using Policy gradient methods.

**Environment.** The environment consists of a black-box solver model `latex $\Theta$ `. The model `latex $\Theta$ ` generates an answer to the current question given the concepts and previous questions and their answers.

**Policy, action and state space.** The decomposer language model `latex $\phi$ ` comprises the policy network. A state `latex $s$ ` in the state space `latex $S$ ` is defined by the concatenation of the initial state `latex $s_0$ ` and all the actions taken from the initial state to the current state. The initial state `latex $s_0$ ` is defined as the initial question `latex $Q$ `. The action space is defined as the token space of the language model `latex $\phi$ `. Hence, a state `latex $s_n$ ` can be represented as `latex $(s_0, \{a_i\}_{i=1}^n)$ `, where `latex $a_i$ ` is the action taken at the `latex $i_{th}$ ` time step.

**Reward function.** The reward is based on the feedback given by the verifier at each sub-question produced by the decomposer. The reward structure is intuitively designed to impose penalties for errors occurring in earlier sub-questions relative to those occurring in later ones. This is because fixing an early mistake can significantly increase the chances of the question being correct. Further, the policy is penalised more for conceptual and procedural mistakes as compared to computational mistakes. We construct the reward function for the `latex $k^{th}$ ` sub-question as follows:

```latex
$$R = \gamma^{k} \sum_{i=1}^{9}{r_i}$$
```

where `latex $\gamma<1$ ` is the discount factor responsible for imposing more penalties on the earlier generations. `latex $r_i$ ` are the rewards for individual feedback given by the verifier as defined below (for each type of reward, we provide an example question asked by the decomposer, an erroneous answer to that question by the solver, type of error identified and the explanation generated by the verifier in red textboxes).

_Conceptual correctness reward_ is defined as:

```latex
$$r_1 = -0.15 I[V(s_k, sa_k)=1]$$
```

where `latex $I$ ` is the indicator function, `latex $V$ ` is the verifier that takes in input the `latex $k^{th}$ ` sub-question (`latex $s_k$ `) and its answer produced by the solver (`latex $sa_k$ `) and outputs the category of mistake. This reward accounts for any mistake made by the solver in understanding or while applying a concept incorrectly.

> **Example (Conceptual Mistake):**
> **Q:** What is `latex $a$ `, `latex $b$ `, `latex $c$ ` in terms of common difference `latex $d$ `?
> **A:** Since `latex $a$ `, `latex $b$ `, and `latex $c$ ` form an arithmetic sequence, we can express `latex $c$ ` in terms of `latex $a$ ` as `latex $c = a + d$ `, where `latex $d$ ` is the common difference.
> **Verifier:** Conceptual Mistakes: The student misunderstood the concept of finding the possible values of the common difference in an arithmetic sequence to form a triangle with a given perimeter.

_Computational correctness reward_ is defined as:

```latex
$$r_2 = -0.05 I[V(s_k, sa_k)=2]$$
```

This reward accounts for cases where the model has made any mistakes in calculation or formula application. These kinds of mistakes are weighted less compared to all other types because an external tool can be easily used for these mechanical tasks.

> **Example (Computational Mistake):**
> **Q:** What is the value of `latex $a+c$ `?
> **A:** Since we are given that `latex $a$ `, `latex $b$ `, and `latex $c$ ` form an arithmetic sequence, we can express `latex $b$ ` as the average of `latex $a$ ` and `latex $c$ `. This gives us `latex $b = \frac{a + c}{2}$ `. The perimeter of the triangle is given by `latex $P = a + b + c = a + \frac{a + c}{2} + c = \frac{3a + 3c}{2}$ `. We are given that the perimeter is 60 units, so we have `latex $60 = \frac{3a + 3c}{2}$ `. Solving for `latex $a + c$ `, we get `latex $a + c = 20$ `.
> **Verifier:** Calculation Mistakes: The model has made a calculation mistake while calculating the value of `latex $a+c$ `. `latex $a+c$ ` should be 40.

_Procedural correctness reward_ is defined as:

```latex
$$r_3 = -0.15 I[V(s_k, sa_k)=3]$$
```

This encompasses any mistake made by the model while following a step-by-step procedure whose information is already given in-context while solving the problem.

> **Example (Procedural Mistake):**
> **Q:** What are the possible values of `latex $a,d$ `?
> **A:** Substituting this into the equation `latex $a + c = 20$ `, we get `latex $a + (a + d) = 20$ `, which simplifies to `latex $2a + d = 20 - a$ `. Since the side lengths must be integers, `latex $a$ ` and `latex $d$ ` must be integers. We can then try different values of `latex $a$ ` and `latex $d$ ` that satisfy the equation `latex $2a + d = 20 - a$ `. After trying different values, we find that the only solution that gives integer side lengths is `latex $a = 10$ ` and `latex $d = 20$ `.
> **Verifier:** Procedural Mistakes: The student made a mistake in the procedure of solving the problem by not accurately finding the possible values of the common difference.

_Question understanding reward_ is defined as:

```latex
$$r_4 = -0.2 I[V(s_k, sa_k)=4]$$
```

This reward accounts for the cases when the model has made a mistake in understanding the sub-question. Either it has not answered the quantity asked in the sub-question. This gives a signal that the sub-question was either incoherent with the previous questions or was too complex for the model to answer. This kind of mistake is important to address and, hence, is given a higher weight.

> **Example (Question Understanding Mistake):**
> **Q:** How many distinct values of `latex $a,b,c$ ` are possible?
> **A:** This gives us the side lengths of the triangle as `latex $a = 10$ `, `latex $b = 15$ `, and `latex $c = 30$ `.
> **Verifier:** Mistakes Understanding Question: The model has made a mistake by not giving the number of distinct values.

**Reward based on place of mistake.** As discussed above, later mistakes are penalised less than the earlier ones. Hence, if a mistake is made in the first step, it is given a reward of `latex $-0.2$ `. If the model makes a mistake in the first half of the sub-answer, it is given a reward of `latex $-0.12$ `. For a mistake in the last half of the sub-answer, it is given a reward of `latex $-0.08$ `. If the mistake is made in the last step, it is given a reward of `latex $-0.05$ `.

**No-mistake reward** is the case when the model has not made any mistake in answering the sub-question and is given a positive reward of `latex $+1$ `.

## Inference

During the inference, the decomposer, solver, and verifier models work together to answer a given question (see working example in Figure 1). During the inference, the decomposer first produces a list of concepts required to solve the question. Then, given the question and concepts as context, the decomposer produces a sub-question. The sub-question is answered by the solver. Now, given the sub-question and sub-answer, the verifier provides feedback in the form of a multi-class classification into the above-described classes of mistakes. If the feedback provided by the verifier consists of either a conceptual mistake, procedural mistake, mistake in understanding or mistake in the first step, we again generate the sub-question.

# Experiments

For all the experiments, LM^2 uses the OpenAI text-davinci-003 model (hereafter mentioned as GPT-3.5) as the solver and LLaMA-2 13B [llama] as the base models for the decomposer and the verifier.

## Training data curation

For the first stage of finetuning of the decomposer LM, we curated a dataset of 15,396 question, concept, sub-question, sub-answer tuples. The questions were taken from the train split of the MATH dataset [MATH]. For verifier LM finetuning, a dataset of 3,674 question-answer-classification tuples was generated. Details of the prompts used for each of these steps are provided in the Appendix.

## Training details

We finetune LLaMA2-13B for both the decomposer and verifier. We train for 8 epochs with a batch size of 128, learning rate 2e-5, warmup steps of 100, a LoRA r value of 4, LoRA Alpha of 16 and dropout of 0.05. The models were trained in 8-bit quantization on an 80G A100 GPU.

For the second stage of fine-tuning, we finetuned the last 3 layers of LoRA adapters, using a batch size of 16, gradient accumulation steps=4, init kl coef=0.01, target=4. For inference, we used a temperature of 0 in all experiments for consistency of results with a max output length of 2000.

## Evaluation

We evaluate our method on hard reasoning datasets that require multi-step reasoning. These datasets include MATH [MATH] (test split), JEEBench [jeebench], and MedQA [medqa] (English questions). The MATH dataset contains math questions from challenging math competitions, since it was also used for training, this shows our performance on in-domain questions. Next, we evaluate on the out-of-distribution datasets like JEEBench which contains PCM questions extracted from the JEE Advanced exam and MedQA which contains open-domain questions from professional medical board exams. We only evaluate questions in the English language.

## Baseline Details

We compare LM^2 with five existing methods: Chain-of-thought prompting (**CoT**) [CoT], Least-to-most prompting (**L2M**) [least-to-most], Progressive Hint Prompting (**PHP**) [PHP], Demonstrate-Search-Predict (**DSP**) [DSP], and **DaSLaM** [juneja-etal-2023-small]. The original setting of PHP requires an 8-shot prompting; however, since all other methods including LM^2 predict in the zero-shot setting, we use PHP in 1-shot for a fairer comparison.

## Ablation Study

In our investigation, we perform five types of ablation studies aimed at comprehensively understanding the significance of each component within the LM^2 pipeline.

We start with investigating the relevance of the verifier by conducting an experiment where we remove it entirely (LM^2\V). Here, we accept each question generated by the decomposer during the inference process without any verification. Then, we explore the role of concepts within the pipeline. Here, we alter the approach by instructing the decomposer to directly generate sub-questions, without providing the concepts to the Solver LM during the answer generation phase (LM^2\C). Following this, we investigate the incremental gains achieved through the second stage of finetuning via policy learning. To accomplish this, we analyze the performance of the decomposer checkpoint after the initial stage of fine-tuning, referred to as (LM^2\RL).

To assess the impact of different types of rewards provided, we partition the rewards into two distinct categories: i) based on the type of mistake, which encompasses conceptual, computational, procedural, and question understanding correctness, and ii) based on the position of mistake. Subsequently, we come up with two ablation variants, finetuned using each category of rewards: LM^2-Type and LM^2-Position.

**Table 1: Performance comparison of LM^2 with the baselines on MATH and MedQA datasets using GPT-3.5 as the solver LM.**

| Dataset | CoT  | L2M   | PHP   | DSP  | DaSLaM | LM^2     |
| ------- | ---- | ----- | ----- | ---- | ------ | -------- |
| PnC     | 16.4 | 16.0  | 10.2  | 16.2 | 21.4   | **30.0** |
| NT      | 14.4 | 11.0  | 9.8   | 20.3 | 26.1   | **41.0** |
| ALG     | 27.6 | 22.4  | 24.0  | 15.3 | 33.4   | **34.0** |
| I-ALG   | 16.4 | 16.8  | 10.0  | 17.0 | 24.8   | **27.8** |
| Calc.   | 14.0 | 14.58 | 14.28 | 18.8 | 18.2   | **34.0** |
| P-ALG   | 32.3 | 28.0  | 26.5  | 28.0 | 44.0   | **47.0** |
| Geom.   | 14.2 | 12.5  | 14.0  | 5.2  | 21.4   | **32.0** |
| MedQA   | 50.3 | 49.8  | 47.5  | 52.3 | 50.1   | **57.1** |

**Table 2: Performance of LM^2 on JEEBench Dataset along with baselines and ablation variants.**

| Method        | Phy. MCQ | Math. MCQ | Phy. Multi. | Math. Multi. | Phy. Num. | Math. Num. | Phy. Int. | Math. Int. | Chem. Int. | Chem. Num. | Chem. Multi. | Chem. MCQ |
| ------------- | -------- | --------- | ----------- | ------------ | --------- | ---------- | --------- | ---------- | ---------- | ---------- | ------------ | --------- |
| CoT           | 33.33    | 21.9      | 6.25        | 12.0         | 3.03      | 1.69       | 12.5      | 10.8       | 17.3       | 11.6       | 11.6         | 40.0      |
| PHP           | 22.22    | 17.07     | 6.25        | 7.59         | 3.03      | 1.69       | 0\*       | 4.0        | 11.7       | 9.7        | 12.2         | 37.5      |
| L2M           | 22.22    | 21.9      | 6.25        | 12.5         | 3.03      | 3.38       | 10.0      | 10.8       | 13.0       | 9.7        | 10.0         | 20.0      |
| DaSLaM        | 55.5     | 29.5      | 18.7        | 16.0         | 6.06      | 10.1       | 15.7      | 11.7       | 14.2       | 9.2        | 11.6         | 14.6      |
| GPT4          | **55.5** | **34.1**  | **27.5**    | **21.5**     | 15.1      | 11.8       | **22.7**  | **24.3**   | 17.9       | **25.5**   | **48.3**     | **60.0**  |
| LM^2          | 51.85    | 30.18     | 26.8        | 16.4         | **15.15** | **13.1**   | 16.2      | 13.5       | **26.0**   | 23.2       | 26.6         | 53.3      |
| LM^2\V        | 37.03    | 24.52     | 14.6        | 11.7         | 12.2      | 11.4       | 11.4      | 11.7       | 17.3       | 16.2       | 13.3         | 30.0      |
| LM^2\C        | 29.62    | 20.75     | 14.6        | 9.4          | 9.09      | 10.8       | 9.0       | 8.1        | 17.3       | 11.6       | 13.3         | 16.6      |
| GPT4-C        | 29.62    | 28.3      | 14.6        | 11.5         | 15.15     | 11.4       | 9.0       | 11.4       | 21.7       | 23.2       | 33.33        | 30.0      |
| LM^2\RL       | 33.33    | 21.9      | 18.7        | 12.7         | 12.2      | 10.1       | 10.0      | 8.1        | 17.3       | 12.4       | 13.3         | 27.3      |
| LM^2-Type     | 46.1     | 28.0      | 20.3        | 14.0         | 13.4      | 11.4       | 15.0      | 13.5       | 24.0       | 23.2       | 23.6         | 45.4      |
| LM^2-Position | 38.4     | 24.52     | 16.0        | 12.9         | 12.2      | 11.4       | 15.0      | 10.8       | 24.0       | 20.6       | 20.3         | 33.0      |
| GPT35-SP      | 33.3     | 29.2      | 7.5         | 12.6         | 9.0       | 8.4        | 12.5      | 8.0        | 17.6       | 9.2        | 12.2         | 41.6      |
| GPT4-SP       | 61.1     | 36.5      | 30.0        | 26.5         | 30.0      | 14.2       | 43.75     | 32.0       | 17.6       | 36.5       | 49.1         | 66.6      |

_Top third: best and second best methods highlighted. LM^2 generally outperforms all existing prompting techniques with GPT-3.5 on different topics and different types of questions. In 3/12 cases, LM^2 outperforms GPT-4. Middle third: large drop in performance with each ablation variant, pointing towards efficient integration of modules. Bottom third: Performance of structured answer generation without decomposer and verifier._

# Results

We summarize the performance of LM^2 along with the baseline methods on the MATH and MedQA datasets in Table 1 and on the JEEBench dataset in Table 2. Across all the datasets, LM^2 improves upon existing methods (using GPT-3.5 solver) by a huge margin. It demonstrates an average 8% improvement on the MATH dataset and an average 2.5% improvement on the JEEBench dataset as compared to the best-performing baseline DaSLaM.

**Can it improve on out-of-domain tasks?** In both DaSLaM and LM^2, the solver model is kept frozen with the hope of retaining generalizability. However, the decomposer model in both methods (and the verifier in LM^2) are finetuned using mathematical reasoning problems. This raises the question of the generalizability of these finetuned components over problems other than mathematical reasoning. One of the most significant challenges with DaSLaM is that it is not able to perform well on out-of-domain tasks like JEEBench Chemistry. We find that our method can surpass this limitation as can be seen in Tables 1 (MedQA) and 2 (JEEBench Chemistry). While DaSLaM degrades the performance over CoT on MedQA, LM^2 achieves an absolute accuracy gain of 6.8 percentage points.

**How important is the verifier?** Next, we seek to investigate the relative importance of each component in our pipeline. We observe that the accuracy decreases substantially upon removing the verifier model (LM^2\V in the middle third of Table 2). We can see that there is a drop of 13.0% in Chemistry versus 10.08% in Physics and 3.4% in Math subsets. The relative drop in accuracy with the ablation of the verifier is sharper with multi-answer, numeric, and integer answer questions. This makes sense given the computational reasoning requirement is higher in these problems and the verifier plays a crucial role in guiding the decomposer and the solver along the correct reasoning path.

[IMAGE: Comparison of token generation cost. We depict the average number of tokens generated by the solver model using different methods to solve the given question averaged over 50 questions from the JEEBench dataset. (token_consumption_comparison.pdf)]

[IMAGE: Comparison of GPT-4, DaSLaM and LM^2 on an example from MATH dataset. (Example.pdf)]

**How important are the concepts?** As can be seen from Table 2, removing concepts decreases the accuracy of Physics subset by 11.6%, Maths subset by 6.03%, and Chemistry subset by 17.5%. This shows that concepts also play a very important role in improving the performance on out-of-domain datasets like Physics and Chemistry. Typically, LM^2\C fares worse than the rest of the ablation variants, demonstrating that the concepts are the most important component in LM^2.

**GPT-4 as concept generator?** We also check how our decomposer compares to GPT-4 while generating concepts. To compare this, we prompt GPT-4 to generate concepts given the question. We observe that there is an average decrease of 9.13% when generating concepts using GPT-4 when compared to the Decomposer model, indicating the higher quality of concepts generated as a result of feedback-based fine-tuning.

**What is the effect of feedback-based finetuning?** The effect of feedback-based fine-tuning is evident when comparing the performance of the decomposer without the second stage of fine-tuning alongside the verifier to that of LM^2. On average, we observe a notable decrease of 9.6% in performance when the second stage of fine-tuning is omitted. This finding highlights the significance of fine-tuning as a crucial step in optimizing model performance. However, the importance of concepts and the verifier appears to outweigh that of fine-tuning. This suggests that while fine-tuning contributes to improved model performance, the incorporation of concepts and a verifier into the model architecture yields more substantial enhancements.

**How does the structured answering template contribute?** Recall that in LM^2, we introduce a novel, structured answering template for controllable coordination between the three models. It is imperative to investigate the role of such a template alone behind the performance boost. We make use of the template with two different solver models, GPT-3.5 and GPT-4. As we can see in the bottom third of Table 2 (coined as modelname-SP), both models improve upon their base performance with our structured template. However, the stronger GPT-4 model is able to utilize the template much more efficiently, with an average gain of 7.8% across the JEEBench problems. Typically, improvement on Physics problems is higher than the Math problems, indicating that language models are not very good at retrieving physics concepts and solving the problem when using chain-of-thought prompting. It should noted that while the structured answering template alone is a powerful boost, it is much weaker alone without the complete coordination in LM^2.

**Does guided reasoning help limit token usage?** An important challenge with iteratively interacting with an LLM is the increased token usage that will translate to expenses in either computational or monetary terms. In Figure 2, we plot the average token usage (per problem) incurred by the solver model (GPT-3.5) while using LM^2 and DaSLaM against that of base chain-of-thought generation. Note that we only show the token usage corresponding to the modified responses while using LM^2 and DaSLaM. Both these methods originally use base CoT to generate the initial response and therefore, their total token usage will always be higher than that of CoT. However, the added structure and guided reasoning significantly reduce the token usage in the modified response. LM^2 prevails in this aspect too. A major reason behind this is the step-by-step synergy between the decomposer, the solver, and the verifier in LM^2. Since the decomposer generates the subquestion depending upon the response from the solver to the previous subquestion, the chances of redundant generation decrease, as opposed to DaSLaM where the subquestions are generated all at once.

**Example analysis.** To further understand the nuances of LM^2, we perform an analysis of the generated output on an example from the MATH dataset (see Figure 3). We compare between LM^2, DaSLaM and GPT-4 with CoT. As we can see, GPT-4 makes an incorrect interpretation of the question itself. It assumes that the total journey after delay takes 10 hours, leading to an incorrect choice of option. The subquestions produced by DaSLaM do not adhere to the order of reasoning required to solve the problem and generate redundant questions. It starts with asking _What is the total distance to be covered?_ However, in the second question, it asks for the speed of the train which is already given in the question itself. The 3rd subquestion generated by DaSLaM is actually the original question, and the solver makes a numerical mistake by simplifying the fraction `latex $\frac{\frac{3d}{4}}{75}$ ` to `latex $\frac{d}{300}$ ` instead of `latex $\frac{d}{100}$ `. Without a verifier, this erroneous response is integrated into the reasoning context of the solver. In the next questions, the same problem is asked to be solved and the solver continues to make incorrect responses. With LM^2, we observe a much more well-defined, crisp line of questioning by the decomposer model; the solver is able to reach the correct answer option without regenerating the same information or drawing incorrect subanswers.

# Conclusion

In this paper, we present LM^2, a cooperative cohort of generative language models working together to solve complex reasoning problems. LM^2 utilizes a frozen solver model that is guided to solve reasoning problems by incrementally answering questions framed by a decomposer model and checked by the verifier model that is trained to coordinate with each other. We find that LM^2 proves its supremacy over existing methods over a variety of reasoning tasks, both in-domain and out-domain. We find that despite being trained using mathematical reasoning examples, our proposed structured response scheme along with the fine-grained verification strategy plays a crucial role in generalizing LM^2 to heavily out-of-distribution tasks like medical question answering and chemistry.

**Limitations.** Despite promising results, LM^2 bears some inherent limitations. Compared to purely prompting-based methods, it requires a certain computational overhead for the two-staged training. With proprietary LLM-based solvers, LM^2 incurs extra token usage over single-pass solutions like chain-of-thought. Implicit limitations of the solver model, like lack of length generalization, arbitrary digit manipulation, etc. are expected to be inherited in LM^2 as well. A possible future work can be towards incorporating deterministic solvers and tools into the multiplex.
