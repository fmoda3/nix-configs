# Abstract {#abstract .unnumbered}

Language models (LMs) have recently shown remarkable performance on reasoning tasks by explicitly generating intermediate inferences, e.g., chain-of-thought prompting. However, these intermediate inference steps may be inappropriate deductions from the initial context and lead to incorrect final predictions. Here we introduce REFINER, a framework for finetuning LMs to explicitly generate intermediate reasoning steps while interacting with a critic model that provides automated feedback on the reasoning. Specifically, the critic provides structured feedback that the reasoning LM uses to iteratively improve its intermediate arguments. Empirical evaluations of REFINER on three diverse reasoning tasks show significant improvements over baseline LMs of comparable scale. Furthermore, when using GPT-3.5 or ChatGPT as the reasoner, the trained critic significantly improves reasoning without finetuning the reasoner. Finally, our critic model is trained without expensive human-in-the-loop data but can be substituted with humans at inference time.

# Introduction {#sec:introduction}

Large language models (LLMs) have made significant strides in natural language processing (NLP) tasks [NEURIPS2020_1457c0d6]. Recent work has shown that explicitly generating intermediate steps during reasoning tasks significantly improves a model's performance and interpretability [shwartz-etal-2020-unsupervised; paul-frank-2021-coins; marasovic-etal-2022-shot; lampinen2022tell; wei2022chain]. Producing such intermediate representations provides insight into the model's predictions and allows humans to inspect the model's reasoning process. However, these intermediate representations[^1] can be unreliable [ye2022the] and result in poor performance on downstream reasoning tasks. Most importantly, it is unclear how to meaningfully refine the intermediate representations to further improve the final performance.

<figure id="fig:model_example" data-latex-placement="t">
[IMAGE: motivational_example.pdf]
<figcaption><strong>REFINER example.</strong> The critic model provides the generator model with feedback on its reasoning errors after evaluating the generated intermediate steps. The feedback, alongside the original question and previous intermediate equation, are fed back to the generator model.</figcaption>
</figure>

The standard practice for correcting reasoning errors is to annotate new data and either retrain or finetune the model [feng-etal-2021-survey; hedderich-etal-2021-survey]. However, fixing such errors by finetuning with more data is not only data- and resource-intensive but can also be insufficient to generalize well in complex reasoning tasks [Ward2022ArgumentativeRL]. Other works have explored improving models using feedback by providing a scalar reward [ziegler2019finetuning; martin-etal-2022-learning] or directly revealing the correct missing answer [mehta-goldwasser-2019-improving; elgohary-etal-2021-nl; tandon-etal-2022-learning]. However, in natural language reasoning tasks, defining a reward that captures different fine-grained reasoning error types (_e.g.,_ semantic consistency, logical, etc.) remains an open challenge [anonymous2023roscoe]. Additionally, such a reward provides a relatively sparse training signal.

In this work, we instead provide fine-grained and structured feedback on reasoning errors. We present REFINER, a novel interaction-based framework that allows a generator LM to iteratively use fine-grained feedback and refine its reasoning. The interaction happens between two models: a _generator_, which learns to solve the task by first generating the intermediate reasoning steps, and a _critic_, which provides structured feedback to the generator about errors in the intermediate steps.

To provide fine-grained feedback about reasoning errors, we develop a scheme to independently train the critic model on automatically constructed feedback data. More specifically, we create pairs of incorrect intermediate representations and structured[^2] feedback on their fine-grained reasoning errors. Then, we use this data to train the critic to provide fine-grained feedback on erroneous intermediate reasoning steps. Finally, the critic interacts with the generator LM, offering feedback both during the training of the generator and during inference.

Figure [1](#fig:model_example){reference-type="ref" reference="fig:model*example"} illustrates an example of our REFINER framework where, given a math word problem, the generator generates an equation as an intermediate representation. The critic identifies the errors in the equation and provides semi-structured textual feedback (\_e.g.,* \"`the operator in` `$\#0$` `is incorrect`\") to the generator. By interacting with the critic, REFINER enables the generator to reason over the semi-structured feedback and _refine_ its generation.

**Contributions.** (i) We propose REFINER, a framework that refines LMs reasoning capabilities through feedback. Our work investigates how interacting with fine-grained reasoning feedback on intermediate reasoning steps impacts the performance of LMs on reasoning tasks. We evaluate REFINER on three natural language reasoning tasks: math word problems, synthetic natural language reasoning, and moral action generation. REFINER demonstrates significant performance gains across different LM architectures with different scales. Across different reasoning tasks, REFINER outperforms comparably-sized strong fine-tuned LM baselines (by +13.1, +3.2, +15 pts., respectively). (ii) We empirically demonstrate that for math word problems and synthetic natural language reasoning, our trained critic models alone are beneficial for improving intermediate representations as they help GPT-`$3.5$` significantly increase its performance in a few-shot setting (by +3.5, +6.8 pts., respectively). We also demonstrate that providing structured feedback on fine-grained errors can benefit more than scalar value feedback for moral action generation and math word problem tasks. Our critic model acts as a 'reasoning refinement tool' for LLMs. (iii) We show that REFINER can substantially outperform other refinement methods that use feedback from large LMs, such as self-refine. (iv) Our analyses illustrate that (a) improving the intermediate representation generation improves the performance on the reasoning tasks, and (b) training a generator with an imperfect (noisy) critic is still beneficial. Our code is made publicly available [^3].

# Related Work

**Intermediate Representations.** While state-of-the-art LMs achieve incredible performances in a wide range of tasks, they have difficulty with many reasoning tasks [wang2022consistency], especially ones with multiple constraints or sub-problems or requiring specialized knowledge [austin2021programsynth] -- such as mathematical problem solving [ling-etal-2017-program; andor-etal-2019-giving; ran-etal-2019-numnet; geva-etal-2020-injecting; piekos-etal-2021-measuring; cobbe2021verifiers; kim-etal-2022-ept].

For these tasks, both intermediate representations and rationales have been shown to be beneficial in learning mathematical skills [piekos-etal-2021-measuring], intermediate program execution computations [nye2021scratchpads], or general reasoning outputs [wei2022chain; golovneva2022roscoe].

Our work builds upon the observation that generating intermediate steps are valuable but distinguishes itself in several key aspects. Firstly, instead of prompting a large model, we finetune smaller models to learn to generate intermediate steps. Secondly, our framework can accommodate tasks that do not necessarily have unique closed-form correct answer, such as the _Moral Norm_ task (see §[3](#sec:model){reference-type="ref" reference="sec:model"}). Finally, our framework is trained with a critic providing feedback, improving the model's reasoning process and teaching it how to leverage feedback.

**Natural Language Feedback.** Recent work has explored giving models richer and more complex feedback through the use of natural language [ziegler2019finetuning; nguyen2021interactive; scheurer2022nlfeedback], used for aligning LLMs' output with users' preferences [christiano2017deepRL; ziegler2019finetuning; saunders2022selfcritiquing; scheurer2022nlfeedback; bai2022constitutional], or to directly improve the model's performance in its current task [weston2016dialog; rupprecht2018guide; elgohary-etal-2020-speak; austin2021programsynth; madaan2023selfrefine]. This training depends on human-created feedback, generated in large quantities [bai2022constitutional], which takes up considerable resources. Though an external feedback provider can guide models to correct answers and reasoning [austin2021programsynth], demonstrably better than they can themselves [saunders2022selfcritiquing], feedback has rarely been used in this way -- and automated critics for reasoning tasks have proved to be difficult [scheurer2022nlfeedback; wang2022consistency; huang2022selfimprove].

Recently, @welleck2022generating introduced a secondary model, the corrector, which improves the initial proposition of a generation model, by learning the kind of mistakes made by the generator and how to fix them. In this work, we also use a secondary model, a critic, but apply it quite differently as we integrate it into an interaction loop with the generator model during training. We further differ from previous works as we provide feedback at the intermediate reasoning steps of the model and not at the final output. The feedback is thus closer to the source of mistakes and guides the model's reasoning toward the correct answer. Additionally, intermediate steps are often structured , allowing the critic to provide precise feedback.

# REFINER {#sec:model}

**Problem Formulation.** In this paper, we view _natural language reasoning_ (NLR) as an autoregressive generation task where, given input context `$x$`, a model needs to generate `$y$`, such that `$y$` satisfies the constraints of the task. Usually, to generate correct or plausible `$y$`, the model needs to make the correct inference `$z$` as intermediate steps.[^4] We decompose NLR tasks as follows: `$p(y|x) = p(y|x,z) p(z|x)$`. In practice, one can compute each conditional using an LM that includes its conditioning variables as a part of its input.

Before continuing with the model description, we describe three NLR tasks where we conduct our study and their respective intermediate representation `$z$`. We deliberately chose these three tasks since they broadly cover two types of reasoning: (i) logical reasoning and (ii) normative reasoning. They are exemplified in Appx  Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error_overview"} and detailed below.

**Math word problem (MWP)**, where given a word problem `$x$` consisting of a context and question, the goal is to map `$x$` to a valid mathematical expression `$z$` (the intermediate representation) and then to a solution `$y$`. This task requires the model to perform deduction using mathematical reasoning.\
**Synthetic natural language reasoning (sNLR)**, where given a reasoning scenario `$x$` consisting of `$5$` synthetic rules and a fact, the model needs to deduce a conclusion `$y$`. This task requires the model to perform deductive reasoning and generate intermediate steps `$z$` and the conclusion `$y$` using closed-world rules and facts.\
**Moral norm and action generation for moral stories (MS)**, where given a context `$x$` consisting of a _situation_, an _intention_, and an _immoral action_, the model needs to generate the moral norm `${z}$` and the moral action `${y}$`. Moral actions are encouraged by the moral norm. This task requires the model to perform abductive reasoning to generate moral norms and deductive reasoning for moral action.

We propose to solve these tasks by forcing the model to generate intermediate hypotheses (`$z$`) and improving them via structured feedback. We introduce an interactive framework, REFINER, made of two separate models: (a) a [critic]{.smallcaps} model (§[3.1](#sec_3.1:critic_model){reference-type="ref" reference="sec_3.1:critic_model"}) trained to provide structured feedback on intermediate reasoning steps and (b) a [generator]{.smallcaps} model trained to solve the reasoning task by first generating intermediate reasoning steps (§[3.2](#sec:3.2_generator){reference-type="ref" reference="sec:3.2_generator"}). The core idea of REFINER is to exploit the interaction between the generator model and the critic model, where the generator's intermediate reasoning steps are improved via structured feedback from the critic.

REFINER presents several important properties. First, the generator is trained to incorporate and leverage feedback, which helps it converge towards better reasoning during training and makes it capable of integrating feedback at test time, whether from a trained critic or a human (see §[5](#sec:result){reference-type="ref" reference="sec:result"}). Second, the trained critic can be useful on its own; we demonstrate that a generalist LLM like GPT-`$3.5$` can significantly benefit from interacting with our trained critic on the reasoning tasks we consider (see §[5](#sec:result){reference-type="ref" reference="sec:result"}). Finally, having two separate models allows us to easily measure the benefits of feedback during training and/or during inference (see §[6](#sec:analysis){reference-type="ref" reference="sec:analysis"}).

## CRITIC Model {#sec_3.1:critic_model}

The role of the critic is to provide feedback on the intermediate hypotheses produced by the generator model. One way to evaluate the quality of the hypothesis and produce feedback on the hypothesis `$z$`, would be to compare it against a gold hypothesis `$z^*$`. Previous works employed automatic metrics like BLEU, ROUGE, etc., as value functions [wu-etal-2018-study; Ramamurthy2022IsRL]. However, these scalar value functions are not suitable for natural language reasoning tasks because (i) it is unclear how to define a scalar value function that can encapsulate fine-grained reasoning errors [anonymous2023roscoe] and (ii) during inference, these functions require access to the gold hypothesis (which is unavailable in practice). Therefore, we train a critic model and endow it with the ability to evaluate the hypothesis in a fine-grained manner and provide structured feedback.

**Feedback Data Generation.** To train the critic, we have to create example pairs of implausible hypotheses and their corresponding feedback with fine-grained reasoning errors. Inspired by and , we first define fine-grained reasoning error types for each reasoning task (see Table [\[tab:define_error_feedbacks\]](#tab:define_error_feedbacks){reference-type="ref" reference="tab:define*error_feedbacks"}). For MWP, an equation can be incorrect due to: (i) the operands or operators in the equations being incorrect and/or (ii) one or more operators missing. For sNLR, an inference rule can be incorrect because it is (i) logically invalid and/or (ii) missing reasoning rules (\_failing to connect the correct facts with correct rules or missing implicit knowledge*). For MS, a moral norm can be incorrect due to (i) contradiction and/or (ii) semantic misalignment.

[]{#tab:define_error_feedbacks label="tab:define_error_feedbacks"}

Based on these error types, we propose two strategies to create the feedback data: (i) **Rule-based perturbation** strategy: we perturb the plausible hypotheses (`$z$`) in the training data and collect a pool of data `$D$` (`$x$`: input, `$z$`: plausible hypothesis, `$z'$`: implausible hypothesis). We perturb by omitting, replacing or adding some tokens or some rules from the plausible hypothesis to create an implausible hypothesis automatically (details in Appendix [13.1](#sec:perturbation_gen){reference-type="ref" reference="sec:perturbation_gen"}). (ii) **Synthetic Generation** strategy: we prompted OpenAI's GPT-`$3.5$` to generate implausible hypotheses based on the error types automatically. We used a few-shot setting where we varied the instruction, the number of demonstrations, and the formatting of the demonstrations (details in Appendix [13.2](#sec:synthetic_gen){reference-type="ref" reference="sec:synthetic_gen"}).

Since our perturbations and automatic implausible hypotheses are based on logic and reasoning errors, we create structured feedback `$f$` for every example (`$x, z, z'$`) by stating the error type that occurs in `$z'$` but not in `$z$` (see Table [\[tab:define_error_feedbacks\]](#tab:define_error_feedbacks){reference-type="ref" reference="tab:define*error_feedbacks"}). The basic structure of feedback `$f$` for these tasks is `$\langle$`\_error type, position (optional), hint (optional)*`$\rangle$`, where position denotes the error position in the implausible hypothesis (see Table [\[tab:define_error_feedbacks\]](#tab:define_error_feedbacks){reference-type="ref" reference="tab:define_error_feedbacks"}). Despite the simplicity of the strategy we used for our tasks, this approach is easily generalisable to other reasoning tasks.

False For MWP and sNLR problems, the underlying reasoning requires symbolic systems with closed-world rules. Hence, we consider a simple rule-based method to automatically generate the pairs of errors and their corresponding structured feedback by considering the error types and position of the errors (see Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error_overview"} and Table [\[tab:define_error_feedbacks\]](#tab:define_error_feedbacks){reference-type="ref" reference="tab:define_error_feedbacks"}).

In the moral norm generation task, we consider two kinds of fine-grained errors: _logical contradiction_ and _semantic misalignment_ (incoherent, uninformative). Moral norms are people's subjective judgments about the character and actions mentioned in the context. Each moral norm is a combination of two components (implicit structure): a moral judgment `[You shouldn’t]` and an action `[criticize your family’s religion]`. Firstly, to create _logical contradictions_, we use the concept of deontic logic from @kiehne-emnlp-2022 and derive new norms contrary to those of Moral Stories. Hence, we replace the correct moral judgments in the plausible hypothesis with inverse judgments. For example, replacing `[You shouldn’t]` from the plausible hypothesis to `[It’s good]`, as depicted in Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error*overview"}. To scale such inverse norms (\_implausible hypothesis*), we paraphrase them by substituting the adjectives with synonyms from WordNet. Secondly, to create _semantic misalignments_, we must collect implausible hypotheses that are either misaligned with the plausible hypothesis or incomplete in nature. To create them, we replace the correct action (verb phrase) from the plausible hypothesis with random verb phrases selected from the context of the plausible hypothesis.

<figure id="fig:refiner_model" data-latex-placement="t">
[IMAGE: clue_model.pdf]
<figcaption>Overview of REFINER interaction loop. Left side: Training the critic model. Right side: In each iteration, the generator generates multiple hypotheses. The critic randomly selects one hypothesis and provides feedback based on reasoning errors.</figcaption>
</figure>

We also replace the correct judgment with random judgments to scale the number of implausible hypotheses per example. Finally, as feedback `$f$`, we provide `$<$`_error type, hint_`$>$`. For non-monotonic reasoning tasks like norm and action generation, the critic should be able to provide hints that align the generator model's objective to the reasoning task. Hence, as a _hint_, we provide verb phrases from the norms. Since the critic provides textual feedback to the generator, we convert the structured feedback into natural language feedback [^5]. Formally, we create a data pool `$D = \{x, z, z', f\}$` to train a critic model.

**Training the critic model.** We train a supervised [critic]{.smallcaps} model (`$\pi_{\beta}$`) with the context (`$x$`) and (plausible or implausible) hypothesis (`$z$` or `$z'$`) as input and the textual feedback as output. We update the [critic]{.smallcaps} with the cross-entropy loss: `$L(\beta) = -\log p_{\beta}(f(u)|x, u)$` where `$u \in z, z'$`. The trained critic is only used during inference. The oracle critic is used while training the generator.

## GENERATOR Model {#sec:3.2_generator}

This section presents a generator model that iteratively learns to interact with the [critic]{.smallcaps} model.

**Warm-up.** Given a context `$x$` the generator model (`$\pi_{\theta}$`) is trained to generate plausible hypotheses. The warm-up phase is critical to ensure that, when the critic comes in the loop, the generator does not produce random answers likely to be bad, given the size of the output space. As such, we use a small supervised dataset (10% training data) to fine-tune the model on the NLR task of interest. After the warm-up phase, we use the additional feedback `$f$` from the critic model and learn `$\pi_{\theta}(z|x, z', f)$`.

**Exploration.** At each iteration (`$t$`), the generator model generates multiple hypotheses (`$z^k$`) using nucleus sampling. The critic model randomly selects one hypothesis and provides feedback on that hypothesis. The exploration step aims at increasing the output variance such that the generator receives a wide range of feedback during training.

**Learning.** We update the [generator]{.smallcaps} model using the following cross-entropy loss: `$L(\theta) = -\sum_{t=1}^{T}\log p_{\theta}(z_t| x, z_t', f_t(z'))$` where `$T$` = total number of iterations. Since the feedback contains the error types and hints, which are (latent) fine-grained and logical, it should allow the model to learn and update its generation by addressing the reasoning errors mentioned in the feedback.

**Inference.** We use the trained critic along with the trained generator to generate a trajectory `$z_0, z_1, . . . , z_T$` and stop when either `$f(z_t)$` is generated by the generator or _"No hint"_ is generated by the critic. We also experimented with _chain of thought_ prompting, where the generator generates a trajectory `$z_0y_0, z_1y_1, . . . , z_Ty_T$` and stops when the critic generates _"No hint"_. False

:::: algorithm
::: algorithmic
Initialize `$answers  \gets$` empty list Initialize (reward) `$r_i \gets 0$`, `$p_i \gets 1$` Initialize (hint) `$h_0, \hat{y}_{i,0} \gets No, []$`

`$answers$`.append(`$\hat{y}$`) break `$answers$`.append(`$\hat{y}$`) `$answers$`
:::
::::

# Experimental Setup

**Datasets.** We evaluate REFINER on three diverse tasks (examples in Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error*overview"}). We briefly describe the datasets used for each task below. \_Math Word Problem* (MWP): We train our models on MAWPs [koncel-kedziorski-etal-2016-mawps] dataset and evaluated our models on a challenging dataset SVAMP [patel-etal-2021-nlp]. We evaluate our model on both the equation generation (`$z$`) and answer prediction (`$y$`) tasks. Similar to @ling-etal-2017-program [amini-etal-2019-mathqa] for equation generation, we replace the numeric values with variable names, for example, `$\texttt{number0}$`, `$\texttt{number1}$`, etc. Further, we also evaluated on GSM8K [cobbe2021gsm8k] dataset which consists of 8.5K high-quality linguistically diverse grade school math word problems. For _Synthetic Natural Language Reasoning_ (sNLR), we use the dataset from @liang2022holistic with the difficulty level as hard. We evaluate our model on both inference rule generation (`$z$`) and consequent generation (`$y$`). For _Moral Story_ (MS), we use a dataset from [emelin-etal-2021-moral], where we evaluate our model on moral norm `${z}$` and the moral action `${y}$` generation.

**Training Details.** For each task, we train a UnifiedQa-[T5]{.smallcaps}-base model (UQA-base) [khashabi-etal-2020-unifiedqa] as a critic (§[3.1](#sec_3.1:critic_model){reference-type="ref" reference="sec_3.1:critic_model"}). For exploration (§[3.2](#sec:3.2_generator){reference-type="ref" reference="sec:3.2_generator"}), we use nucleus sampling with `$p = 0.5$`. We select the hyper-parameters by the validation loss: for both the generator and critic model, we use the Adam optimizer with a learning rate of `$1e^{-4}$`. Each model is trained for `$20$` epochs with early stopping based on validation loss. We trained all models on one A100 GPU. We run our models with `$3$` random seeds and report the average results. For the human study, we selected outputs from the best models (baselines and our model) according to automatic metrics. We train models with `$T=3$` iterations.

At inference time, we use greedy decoding for the generator and critic model with `$T=1$` for the automatic critic and `$T=3$` for the oracle critic. On the MWP and sNLR tasks, we use the exact match (EM) metric for intermediate steps (equation generation and inference rules) and accuracy (Acc) for the final answers. For MS, we conduct a manual evaluation study to assess the relevance of norms and moral actions[^6]. Further evaluation details are provided in Appendix [14](#sec:Appendix_E){reference-type="ref" reference="sec:Appendix_E"}. To train the critic model, we used the feedback data generated using the rule-based perturbation strategy (see §[3.1](#sec_3.1:critic_model){reference-type="ref" reference="sec_3.1:critic_model"}).

**Baselines.** We compare our method with three different LMs as generator models: UQA-base, UQA-large (supervised setting), GPT-`$3.5$`-`text-DaVinci-003` and ChatGPT (few-shot setting). We also compare REFINER to _Proximal Policy Optimization_ (PPO) RL-based method [Schulman2017ProximalPO]. We use the implementation of PPO from [Ramamurthy2022IsRL]. For GPT-`$3.5$`, we provide `$2$` for demonstrations per class. We also experimented with _chain of thought_ (COT) prompting [wei2022chain] where the model is prompted first to generate the intermediate steps (`$z$`) and then the final answer (`$y$`). Note that the sNLR task is a synthetic task where the model needs to perform either one-hop or two-hop reasoning. @10.5555/3491440.3491977 showed that fine-tuning large language models (`$354$`M parameter size) could achieve (99% accuracy) high performance. Hence, we only compare our REFINER model with the UQA-base model (`$220$`M) (see Table [\[tab:results_snlr\]](#tab:results_snlr){reference-type="ref" reference="tab:results_snlr"}). Since human annotation is expensive, we focus on comparing against the most meaningful baseline: UQA-large for MS task (see Table [\[tab:results_mng\]](#tab:results_mng){reference-type="ref" reference="tab:results_mng"}). It is important to highlight that our proposed framework is general, and one can use any other LMs as [generator]{.smallcaps} or [critic]{.smallcaps}.

# Results {#sec:result}

We evaluate our model on two aspects (i) performance on intermediate steps and (ii) performance on the final answer prediction. Tables [\[tab:results_mwp\]](#tab:results_mwp){reference-type="ref" reference="tab:results_mwp"}, [\[tab:results_snlr\]](#tab:results_snlr){reference-type="ref" reference="tab:results_snlr"}, and [\[tab:results_mng\]](#tab:results_mng){reference-type="ref" reference="tab:results_mng"} show the performance comparisons.

**Performance on Intermediate Steps.** Table [\[tab:results_mwp\]](#tab:results_mwp){reference-type="ref" reference="tab:results_mwp"} reports the performance of the MWP task. We explored two different scenarios: (i) where the model [only generates the equations]{style="background-color: NextBlue"} (`$z$`) with variable names replacing the numeric values, and (ii) where the model generates [both the equations and the final answers]{style="background-color: Nextblush"} together. We observe for both scenarios that REFINER significantly outperforms baseline models with comparable sizes. Notably, UQA-base benefits most (`$+13.1$` EM) when adding a critic in the loop. We observe that GPT-`$3.5$` significantly benefits from the REFINER trained critic. Since LLMs like GPT-`$3.5$` (`$175$`B parameters) are expensive to finetune, the improvement in equation generation of `$+3.2$` EM without any modification is important. Interestingly, we observe that GPT-`$3.5$` + COT manages to have significantly higher accuracy in answer `$y$` than in equation `$z$` (see Table [\[tab:results_mwp\]](#tab:results_mwp){reference-type="ref" reference="tab:results_mwp"}). This result is similar to the observation made by @ye2022the and suggests that the intermediate equations can be unreliable. Finally, REFINER could even outperform PPO, which uses BLEU-score as a reward function. This suggests that semi-structured fine-grained textual feedback is more beneficial than value-based (where values are from automatic metrics) reward feedback. Note that this result may vary when these models are optimized directly with complex human values, as shown in @10.5555/3495724.3495977. Qualitatively, REFINER can correct incorrect equations through structured feedback, fixing the operators within a multistep solution (see Fig. [8](#fig:example_multistep){reference-type="ref" reference="fig:example_multistep"}).

For sNLR, similar to @liang2022holistic, we observe that GPT-3.5 performs poorly (see Table [\[tab:results_snlr\]](#tab:results_snlr){reference-type="ref" reference="tab:results_snlr"}). REFINER improves `$+2.9$`, and `$+6.8$` EM scores over UQA-base, and GPT-`$3.5$`, respectively. Contrary to the MWP, the final answer `$y$` is not a symbolic execution away from the intermediate step `$z$`, but we still observe that REFINER focuses on improving the intermediate step `$z$`, resulting in significant improvements in the answer `$y$` prediction. Again, we observe that REFINER with a UQA-base can outperform few-shot prompted GPT-`$3.5$`. Thus, our critic can identify the fine-grained reasoning errors and help improve the performance on inference rules generation.

For MS, we assess the generation quality with three human judges who indicate whether the generated norms and moral actions are relevant to the given moral story. Table [\[tab:results_mng\]](#tab:results_mng){reference-type="ref" reference="tab:results*mng"} summarises human evaluation results on `$100$` moral story examples randomly sampled from the MS test dataset. More specifically, we report evaluation breakdown for both norm and moral action by the number of instances that are either \_Irrelevant*, _Unsure_ or _Relevant_ along with Krippendorf's `$\alpha$` [krippendorff] agreement scores. The results show an improvement of `$20$` points, increasing the relevance over a strong UQA-large baseline. Hence, this suggests that a specialized critic model with `$3$` times fewer parameters than the generator can improve the performance on generating reasoning steps.

**Performance on Final Answer Prediction.** We observe that REFINER outperforms the strong LM baselines by `$+3.5,+3.2,+15$` points for MWP, sNLR, and MS, respectively. These results support our hypothesis that generating better intermediate steps can result in better answer prediction. Notably, on the sNLR task, for GPT-`$3.5$`, we observe that by adding a critic, there is an improvement of +`$6.8$` in inference step generation; however, only `$+1.5$` in the consequent prediction. This result indicates that LLMs may either not use these intermediate steps to perform the deduction or fail to perform deduction.

::: {#tab:sota_results}
+:---------------------------+:--------:+:--------:+:--------:+:--------:+
| **Generator Model** | **SVAMP** | **GSM8K** |
+----------------------------+----------+----------+----------+----------+
| | GPT-3.5 | ChatGPT | GPT-3.5 | ChatGPT |
+----------------------------+----------+----------+----------+----------+
| CoT | 67.1 | 68.2 | 63.5 | 74.1 |
+----------------------------+----------+----------+----------+----------+
| Self-reflection | 67.2 | 68.4 | 63.1 | 74.6 |
+----------------------------+----------+----------+----------+----------+
| Self-refine | 67.6 | 68.2 | 63.8 | 74.7 |
+----------------------------+----------+----------+----------+----------+
| REFINER | **70.6** | **71.4** | **66.2** | **75.9** |
+----------------------------+----------+----------+----------+----------+
| ReACT | 67.3 | 68.4 | 64.7 | 75.5 |
+----------------------------+----------+----------+----------+----------+
| ReACT + REFINER | **70.6** | **71.9** | **67.8** | **77.4** |
+----------------------------+----------+----------+----------+----------+
| Self-consistency | 69.5 | 70.4 | 65.5 | 76.1 |
+----------------------------+----------+----------+----------+----------+
| Self-consistency + REFINER | **72.1** | **72.5** | **67.2** | **78.1** |
+----------------------------+----------+----------+----------+----------+

: **Comparison with different refinement methods** on SVAMP and GSM8K datasets. Averaged accuracy over three runs on the test sets is reported (p\<0.05).
:::

**Comparing REFINER with other refinement methods.** In Table [1](#tab:sota_results){reference-type="ref" reference="tab:sota*results"}, we compare REFINER with two other recent refinement methods: Self-refine [madaan2023selfrefine] and Self-reflection [shinn2023reflexion] method on the SVAMP and GSM8K datasets. Both these baseline methods use LLMs to generate automatic feedback. Similar to @madaan2023selfrefine, we observe that self-refine has minor improvement for MWP tasks. On the contrary, we find that REFINER significantly improves the performance of GPT-3.5 and ChatGPT by +`$3.3$` and +`$2.2$` on SVAMP and GSM8K datasets, respectively. This highlights the benefit of training a \_specialised critic* that is grounded to the task. It can make LLMs more accurate than feedback from a general-purpose model (GPT-`$3.5$` or ChatGPT). In Appendix §[\[sec:compare_trained_training_free\]](#sec:compare_trained_training_free){reference-type="ref" reference="sec:compare*trained_training_free"}, we have provided more details about the quality of feedback generated using our trained critic and GPT-`$3.5$` (see Table [4](#tab:trained_critic){reference-type="ref" reference="tab:trained_critic"}). Further, we assess the performance of REFINER in improving the CoT generated by two recent methods: Self-Consistency [wang2023selfconsistency] and ReACT method [yao2023react]. We observe that REFINER can improve self-consistency and ReACT by +`$2.02$` and +`$2.9$`. This demonstrates that a trained critic can be used as a \_tool* and can bring performance gains to different methods out-of-the-box (more details in Appendix §[8.2](#sec:react){reference-type="ref" reference="sec:react"}).

::: {#tab:ablation}
**Model** **Eq. (`$z$`)**

---

REFINER`$_{base}$` + critic data`$_{rule-based}$` 47.2
REFINER`$_{base}$` - critic`$_{inference}$` 39.8
REFINER`$_{base}$` - critic`$_{inference}$` - exp 37.4
REFINER`$_{base}$` - critic`$_{training}$` 34.1
REFINER`$_{base}$` + critic data`$_{synthetic}$` 44.1
REFINER`$_{base}$` + critic`$_{Oracle}$` 66.0

: **Ablation Result** on MWP task; Comparing model without critic during inference, and without the exploration (exp) phase during training. We report the exact match scores of the generated equation, comparable to Table [\[tab:results_mwp\]](#tab:results_mwp){reference-type="ref" reference="tab:results_mwp"}.
:::

**Ablation.** To obtain better insight into the contributions of the individual components of our models, we perform an ablation study (Table [2](#tab:ablation){reference-type="ref" reference="tab:ablation"}). We observe that there is a considerable drop in performance from `$47.2$` to `$39.8$` when we do not use the critic model during inference. Hence, this result indicates that our generator model can leverage the feedback from the critic at inference time. Further, we find that the exploration step improves the performance `$+3.3$` over the baseline model. This result supports our hypothesis that the exploration step increases the output variance and gives the generator model the opportunity to learn over a wide range of feedback. We compared the performance with the critic model trained on two different training data (see §[3.1](#sec_3.1:critic_model){reference-type="ref" reference="sec_3.1:critic_model"}). We find that the critic trained on small automatically generated data using GPT-3.5 works better than without the critic in the loop. This result motivates researchers to use this method to generate negative samples to train their critic or preference learning model. Finally, we also observe that if the critic was perfect (Oracle), then REFINER can significantly improve the performance by fixing the mistakes generated by the generator model. This result indicates that REFINER can be seen as a framework that allows AI-AI and human-AI interaction.

# Analysis {#sec:analysis}

<figure id="fig:error_analysis" data-latex-placement="t">
[IMAGE: define_error_feedbacks.pdf]
<figcaption><strong>Error analysis.</strong> Number of errors made by baseline UQA-large and REFINER on 100 instances sampled randomly from test sets of both datasets. Errors are categorized according to Table <a href="#tab:define_error_feedbacks" data-reference-type="ref" data-reference="tab:define_error_feedbacks">[tab:define_error_feedbacks]</a>).</figcaption>
</figure>

**Error Analysis.**[]{#sec:6.1*quantitative_analysis label="sec:6.1_quantitative_analysis"} In order to get more insight into the performance of our method, we conduct a fine-grained error analysis on the MWP and MS datasets (Fig. [3](#fig:error_analysis){reference-type="ref" reference="fig:error_analysis"}). We note that the most frequent errors are \_Incorrect Numbers* for MWP and _Semantic Misalignment_ for MS. An intuitive reason can be that for the MWP task, the models are sensitive to the numbers order as argued in [patel-etal-2021-nlp]. For MS, generating norms grounded in the context is challenging. Our analyses show a clear trend that REFINER is able to considerably reduce the errors for both datasets. This indicates that our trained critic model could identify fine-grained reasoning errors during inference.

**Noise Sensitivity.** To further understand the behaviour of the REFINER framework, we run variations with noisy critics for the MWP task. We replace the oracle critic used during training with a noisy critic in (Fig. [4](#fig:noisy_analysis){reference-type="ref" reference="fig:noisy_analysis"} (a)) to inspect how training with an imperfect critic impacts the generator. We also use a noisy critic at inference while keep the oracle critic during training (in Fig. [4](#fig:noisy_analysis){reference-type="ref" reference="fig:noisy_analysis"} (b)). The noisy critics are generated by random perturbations of the oracle critic; for a noise-level `$\epsilon$`, the oracle feedback is replaced by random feedback with probability `$\epsilon$`.

Fig. [4](#fig:noisy_analysis){reference-type="ref" reference="fig:noisy_analysis"} (a) shows that when training with a very noisy critic (`$>75\%$` noise), the generator LM learns to ignore the critic, as there is no difference between using the trained critic or the oracle during inference. Interestingly, training with a bit of noise (`$<50\%$`) does not seem to harm the model, as performances are not statistically different than training with the oracle (noise of `$0\%$`). Fig. [4](#fig:noisy_analysis){reference-type="ref" reference="fig:noisy_analysis"} (b) depicts the quality of the critic used at inference time has a huge impact. Having oracle provide feedback is by far the best scenario. Already with `$25\%$` noise, the critic makes the generator perform worse than using our trained critic (REFINER). With more than `$50\%$` noise, the critic significantly harms the generator. The generator, trained with an oracle critic, has learned to trust the critic and expects useful feedback.

<figure id="fig:noisy_analysis" data-latex-placement="t">
[IMAGE: noisy_critics.pdf]
<figcaption><strong>Noisy-critics analysis</strong>. In plot (a), we vary the noise level of the critic used during training (<span class="math inline">0</span> noise corresponds to oracle) and compare the resulting models when using the oracle and the training automatic critic during inference. In plot (b), we train with the oracle critic but vary the noise level of the critic used during inference.</figcaption>
</figure>

**Qualitative Analysis.** To explain the findings in §[\[sec:6.1_quantitative_analysis\]](#sec:6.1_quantitative_analysis){reference-type="ref" reference="sec:6.1*quantitative_analysis"}, we further manually analyze 100 instances for the MWP task. We observe two different scenarios when REFINER failed to fix the outputs generated by [generator]{.smallcaps} model: (a) when the [critic]{.smallcaps} model provides a \_correct* feedback; however, the [generator]{.smallcaps} model still generates _incorrect_ equation, and (b) the [critic]{.smallcaps} model provides an _incomplete_ or _partially correct_ feedback. The former case indicates that either the [generator]{.smallcaps} model makes mistakes in following the instruction from the [critic]{.smallcaps} or the feedback from the critic can be ambiguous. For example, in Appx Fig. [5](#fig:qualitative_analysis){reference-type="ref" reference="fig:qualitative_analysis"}, (b) we observe the case when the critic is correct, but the feedback could result in an incorrect equation. The latter case indicates that our trained critic model generates incorrect feedback, which can result in incorrect or partially correct equations. We also observe that our [critic]{.smallcaps} model failed to generate correct feedback when the [generator]{.smallcaps} model generates incorrect equations with multiple mistakes.

::: {#tab:trained_critic}
**Task** **UQA (220M)** **UQA (770M)** **GPT-3 (175B)**

---

MWP 69.5 +/- 2.6 73.4 +/- 3.7 63.5 +/- 5.6  
 sNLR 95.5 +/- 1.4 98 +/- 2.2 34.5 +/- 2.4  
 MN 77.4 +/-2.5 80 +/- 4.5 76.4 +/-3.5

: **Comparing the performance of different critic models**. Exact-match score is reported.
:::

**Quality of the feedback.**[]{#sec:compare_trained_training_free label="sec:compare_trained_training_free"} To better understand the difference in the quality of the feedback, we compare our trained critic model with GPT-3.5. We assess the quality of the feedback on 500 instances per task and report the exact match scores in Table [4](#tab:trained_critic){reference-type="ref" reference="tab:trained_critic"}. Please note that we include instances where the critic feedback should say the solution is correct and hence generate 'No'. For GPT-3.5, we have provided (two) few-shot examples per type of error and two examples with 'No' as feedback. Our results show that trained critic (UQA) can comprehensively outperform GPT-3.5. We observe that GPT-3.5 performs well in identifying when the answer is correct. However, it makes errors when asked to generate meaningful semi-structured feedback for incorrect reasoning steps.

# Conclusion

In this paper, we propose REFINER, a framework to improve the reasoning abilities of LMs through an iterative feedback loop between two models, a _generator_ and a _critic_. Our evaluation of this framework on three reasoning tasks showed structured and fine-grained feedback on intermediate reasoning errors results in significant performance gains, surpassing scalar value feedback. Our trained critic model alone, even when noisy, can improve intermediate representations of LMs, showing that REFINER can significantly boost LMs' performance on reasoning tasks. Our REFINER framework is very general and, in principle, might be applied to steer language models in performing different reasoning tasks. More specifically, the _critic_ model can be seen as a tool for LLMs to refine their generation quality.

# Limitations {#limitations .unnumbered}

Our REFINER framework could not be comprehensively evaluated on all applicable downstream reasoning tasks due to their sheer number. While deliberately distinct, we focused on only three different reasoning tasks in order to study how natural language reasoning feedback can impact downstream tasks. We believe this represents an initial but important step towards exploring automated natural language feedback on intermediate representations. In addition, the critic we presented here is specific for each task, while the ideal critic would be a general one, capable of providing feedback on a wide range of reasoning tasks. Similarly, we considered fine-grained reasoning errors specific to each reasoning task. Recent work has mentioned several other fine-grained reasoning errors [anonymous2023roscoe], which can't be fully covered by the reasoning tasks we considered. Generalizing both the critic and fine-grained error types emerges as both the main limitations of this paper and the directions of future work. Finally, with LLMs being deployed more and more for real-life applications (medical domain, making important decisions), we believe it is crucial to develop expert models and automatic feedback mechanisms to inspect model generations and improve them. LLMs are impressive and work well on several NLP tasks, but they are not expert systems. Our work aims to address this gap by showing that adding interventions/feedback from critics (specialised finetuned critics) can help the LLM model to be more accurate---additionally, making the whole process more transparent.

# Ethical Considerations {#ethical-considerations .unnumbered}

In this paper, we experiment with existing datasets which are, to the best of our knowledge, adequately cited. Our proposed framework REFINER is designed to improve the reasoning abilities of LMs. These LMs have been shown to encode biases about race, gender, and many other demographic attributes [ethical-social-risks], [sheng-etal-2020-towards]. Since our framework does not offer a way to mitigate these biases, models improved using this framework could still reflect the same harmful behaviours normally exhibited by these models. We recommend anyone deploying our model _off-the-shelf_ should first check whether the model is harmful towards any protected group, and appropriate mitigation should be taken. In addition, our MS task is based on a dataset of situations, intentions, and actions that heavily skew towards Western culture and social norms [emelin-etal-2021-moral]. Consequently, our human evaluation on the MS task was done with AMT workers based in the US who were paid adequately for the average time it took to solve the task.

# Additional Results

## More details about the quality of the feedback

Please note we also include instances where the critic feedback should say the solution is correct and hence generate 'No'. Our exact match metric is not order-sensitive. We extract the sentences and match them individually to the oracle answers. Since we focused only on the semi-structured critic feedback, automatic evaluation can already capture (measure effectively) the quality of the feedback.

## Details about ReACT and Self-consistency and Self-Correct {#sec:react}

The ReACT method consists of the reason model (Reason-Only) LLM (GPT-3.5), which generates a single thought at each step, and the Action model LLM (another GPT-3.5) does the calculation and generates the intermediate outputs (observations). We propose to refine the intermediate steps generated by the above steps and report the results below. Please note ReAct is approx **3-4** times more expensive than GPT-3.5 + CoT. In our experiments, we assumed `$3$` reasoning steps for ReACT and a sample size of `$5$` for self-consistency to be more cost-effective. Interestingly, we observe that ReACT perform similarly to CoT for the SVAMP dataset. One intuitive reason is that the SVAMP dataset contains questions which require one or two-hop reasoning only. We find that REFINER performs (+2.2) better than Self-correct [welleck2023generating] on the GSM8K dataset, indicating the importance of correcting the intermediate steps can lead to better performance. Please note that we have used GPT-Neo as the generator model and the Unified QA T5-base model as the critic model, consistent with the Self-correct paper by Welleck et al. (2022).

## More results on SVAMP dataset

In the MWP, for the answer prediction task, we compare REFINER with the previously reported baselines from @jie-etal-2022-learning including Graph2Tree [zhang-etal-2020-graph-tree] that uses quantity relations using GCN; GTS [Xie2019AGT] which is a sequence-to-tree model that mainly uses a tree-based decoder with GRU; and DeductReasoner [jie-etal-2022-learning] which uses bottom-up DAG-structured decoding. Results of this comparison can be found in Table [\[tab:results_extra\]](#tab:results_extra){reference-type="ref" reference="tab:results_extra"}. For the sNLR task, we also experiment with a critic model trained on 50% of its original training data and we still observe a performance improvement over the baseline as can be seen in Table [9](#tab:50_snr_results){reference-type="ref" reference="tab:50_snr_results"}.

::: {#tab:trained_critic}
**Model** **Accuracy**

---

GPT-Neo (1.3B) 8.5
GPT-Neo + Self-Correct 21.2
GPT-Neo + REFINER 23.4 +/- 0.3

: **Comparing** REFINER with self-correct on GSM8K dataset
:::

# REFINER Framework {#sec:appendix_framework}

Alg. [\[alg:training_refiner\]](#alg:training_refiner){reference-type="ref" reference="alg:training*refiner"} and Alg. [\[alg:inference_refiner\]](#alg:inference_refiner){reference-type="ref" reference="alg:inference_refiner"} outline the training and inference algorithms for REFINER. We train a supervised [critic]{.smallcaps} model (`$\pi*{\beta}$`) with the context (`$x$`) and (plausible or implausible) hypothesis (`$z$` or `$z'$`) as input and the textual feedback as output. Given a context `$x$` the generator model (`$\pi\_{\theta}$`) is trained to generate plausible hypotheses.

:::: algorithm
::: algorithmic
Initialize (feedback) `$f_0 \gets No$` += `$-\log p(z_i|c_i, f_{t-1}, \hat{z}_{i,t-1})$`
:::

[]{#alg:training_refiner label="alg:training_refiner"}
::::

:::: algorithm
::: algorithmic
Initialize `$answers  \gets$` empty list Initialize (reward) `$r_i \gets 0$`, `$p_i \gets 1$` Initialize (hint) `$h_0, \hat{y}_{i,0} \gets No, []$`

`$answers$`.append(`$\hat{y}$`) break `$answers$`.append(`$\hat{y}$`) `$answers$`
:::

[]{#alg:inference_refiner label="alg:inference_refiner"}
::::

# Datasets and Models

In Table [5](#tab:data_stat){reference-type="ref" reference="tab:data_stat"} and Table [\[tab:dataset_details\]](#tab:dataset_details){reference-type="ref" reference="tab:dataset_details"}, we report the data statistics and dataset details. In Table [6](#tab:model_stat){reference-type="ref" reference="tab:model_stat"}, we report the details of the used models. Our research is conducted solely on datasets that are in the English language.

::: {#tab:data_stat}
**Task** **Train** **Dev** **Test**

---

MWP 3,138 -- 1000
sNLR 1000 5000 5000
MS 10000 1000 1000
GSM8k -- -- 1319

: Dataset Statistics: nb. of instances.
:::

::: {#tab:model_stat}
**Model** **Parameter Size**

---

UQA-base 220M
REFINER`$_{base}$` 440M
UQA-large 770M
REFINER`$_{large}$` 990M
GPT3.5 175B

: Model Sizes.
:::

::: table\*
**Dataset/Tools** **Citation** **Link** **License**

---

SVAMP @patel-etal-2021-nlp <https://github.com/arkilpatel/SVAMP> MIT License
GSM8k @cobbe2021gsm8k <https://github.com/openai/grade-school-math> MIT License
sNLR @liang2022holistic <https://github.com/stanford-crfm/helm> Apache License
Moral Norm @emelin-etal-2021-moral <https://github.com/demelin/moral_stories> MIT License
HuggingFace @wolf-etal-2020-transformers <https://github.com/huggingface/transformers> Apache License
:::

<figure id="fig:qualitative_analysis" data-latex-placement="t">
[IMAGE: qualitative_analysis.pdf]
<figcaption><strong>Examples.</strong> REFINER on MWP task. There are different scenarios are highlighted in the figure, where (a) the <span class="smallcaps">critic</span> model provides correct feedback, <span class="smallcaps">generator</span> model utilizes the feedback and fixes the incorrect equation, (b) the <span class="smallcaps">critic</span> model provides a <em>correct</em> feedback however, <span class="smallcaps">generator</span> model fails to fix the <em>incorrect</em> equation, and (c) the <span class="smallcaps">critic</span> model provides an <em>incomplete</em> feedback <span class="smallcaps">generator</span> model partially fixes the incorrect equation.</figcaption>
</figure>

::: {#tab:results_mwp_app}
**Model** **Eq. (`$z$`)** **Ans. (`${y}$`)**

---

UQA-large 46.7 --
UQA-large + PPO --
REFINER`$_{large}$` **53.8** --
REFINER`$_{large}$` + Oracle (T=3) --
GPT-`$3.5$` + CoT 59.3  
 GPT-`$3.5$` + CoT + REFINER`$_{critic}$` 62.3 **66.4**
GPT-`$3.5^\star$` + CoT 64.1  
 GPT-`$3.5^\star$` + CoT + REFINER`$_{critic}$` **67.3** **70.6**

: Results on MWP. Eq.: Equation, Ans. Answer. Comparison of REFINER with baselines on the SVAMP dataset. GPT-`$3.5$`: code-DaVinci-002, GPT-`$3.5^\star$`: text-DaVinci-002 For models other than GPT3.5, the answer can be obtained via symbolic execution of the equation and is thus a function of the validity of the equation. For GPT3.5, the model is few-shot prompted to either generate the equation with variable names `$z$`, or generate the answer `$y$`.
:::

false

::: {#tab:results}
**Model** **EM** **Acc**

---

**SVAMP** - Equation Generation  
 REFINER`$_{base}$` - critic`$_{inference}$` 39.8 --
REFINER`$_{base}$` - critic`$_{inference}$` - exp 37.4 --
REFINER`$_{base}$` - critic`$_{training}$` 34.1 --
REFINER`$_{large}$` - critic`$_{inference}$` 48.44 --
REFINER`$_{large}$` - critic`$_{inference}$` - exp 45.55 --
**SNR**  
 REFINER`$_{base}$` - critic`$_{inference}$` 92.92 97.32
REFINER`$_{base}$` - critic`$_{inference}$` - exp  
 **Moral Norm**

: **Ablation Result.** exp: Exploration
:::

::: {#tab:50_snr_results}
**Model** **IR** **C**

---

**50% training data**  
 T5-base 84.28 `$\pm$` 0.5 88.86
REFINER`$_{base}$` **88.26 `$\pm$` 0.8** **94.26**
REFINER`$_{base}$` + Oracle 91.11 `$\pm$` 05 97.28

: Results on SNR dataset. IR: Inference Rules, C: Consequent
:::

false

::: {#tab:results}
**Model** **Scenario 1** **Scenario 2**

---

**Few-Shot Setting**  
 GPT-3 + COT 20.9 17.8
GPT-3 + COT + TAC **30.3** **26.8**

: Analysis on SNR dataset. IR: Inference Rules, C: Consequent
:::

<figure id="fig:error_overview" data-latex-placement="t">
[IMAGE: figure_3_two_examples.pdf]
<figcaption><strong>Feedback Data Generation</strong>. The top row illustrates an example from the sNLR task, where the error types are <em>logically invalid</em>, <em>missing links</em>, and <em>missing implicit knowledge steps</em>. The bottom row illustrates an example from moral norm generation, where the error types are <em>contradiction</em> and <em>semantic misalignment</em>. We perturbed used the plausible intermediate steps to implausible.</figcaption>
</figure>

# Training Details {#sec:training_details}

#### Training Details.

For each task, we train a UnifiedQa-[T5]{.smallcaps}-base model (UQA-base) [khashabi-etal-2020-unifiedqa] as a critic (§[3.1](#sec_3.1:critic_model){reference-type="ref" reference="sec_3.1:critic_model"}). Further evaluation details are provided in Appendix [14](#sec:Appendix_E){reference-type="ref" reference="sec:Appendix_E"}. For exploration (§[3.2](#sec:3.2_generator){reference-type="ref" reference="sec:3.2_generator"}), we use nucleus sampling with `$p = 0.5$`. We select the hyper-parameters by the validation loss: for both the generator and critic model, we use the Adam optimizer with a learning rate of `$1e^{-4}$`. Each model is trained for `$20$` epochs with early stopping based on validation loss. We trained all models on one A100 GPU. We run our models with `$3$` random seeds and report the average results. We perform a binomial sign test. We find that p-values are always \<0.05 when we compare REFINER with all the baselines (GPT-3.5, Self-refine, Self-reflection), suggesting our results are not random and significant. For the human study, we selected outputs from the best models (baselines and our model) according to automatic metrics. We train models with `$T=3$` iterations. We trained the critic model for 8 hours and trained the generator model for 12 hours.

At inference time, we use greedy decoding for the generator and critic model with `$T=1$` for the automatic critic and `$T=3$` for the oracle critic. We evaluate our methods using the metrics presented in the original papers that proposed the tasks. On the MWP and sNLR tasks, we use the exact match (EM) metric for intermediate steps (equation generation and inference rules) and accuracy (Acc) for the final answers. For MS, we conduct a manual evaluation study to assess the relevance of norms and moral actions.[^7]

# Qualitative Examples

Figure [8](#fig:example_multistep){reference-type="ref" reference="fig:example_multistep"} and [\[table:moral-stories-gen\]](#table:moral-stories-gen){reference-type="ref" reference="table:moral-stories-gen"} depict a qualitative example of REFINER where REFINER could correct incorrect equations through structured feedback, fixing the operators within a multistep solution. Table [\[table:moral-stories-gen\]](#table:moral-stories-gen){reference-type="ref" reference="table:moral-stories-gen"} shows some qualitatively improved examples for MS. False

<figure id="fig:error_overview_all" data-latex-placement="t">
[IMAGE: appendix_feedback.pdf]
<figcaption>An overview of the three tasks tackled in this paper, with examples of both valid and invalid intermediate reasoning steps, as well as their corresponding fine-grained error types. Notice the <strong>Missing Steps</strong> error type, in the second task, actually encompasses two error types: reasoning misalignment, derived from not considering the <code>or</code> operation, and lack of implicit knowledge, where implicit knowledge is needed to match the existing rules.</figcaption>
</figure>

<figure id="fig:example_multistep" data-latex-placement="t">
[IMAGE: multi-step_example.pdf]
<figcaption>REFINER on MWP. The generator’s output improves step-wise.</figcaption>
</figure>

::: table\*
:::

# Feedback Data Generation {#sec:feedback_gen}

## Rule-based Perturbation {#sec:perturbation_gen}

Based on these error types, we perturb the plausible hypotheses (`$z$`) in the training data and collect a pool of data `$D$` (`$x$`: input, `$z$`: plausible hypothesis, `$z'$`: implausible hypothesis). We perturb by omitting, replacing or adding some tokens or some rules from the plausible hypothesis to automatically create an implausible hypothesis. For example, in Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error*overview"}, for sNLR we omit a few inference steps from the correct hypothesis \"`#0: viridian is green, #1: rose is green`\" and create an incorrect (incomplete) hypothesis (see Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error_overview"}). Since our perturbations are based on logic and reasoning errors, we create structured feedback `$f$` for every example (`$x, z, z'$`) by stating the error type that occurs in `$z'$` but not in `$z$` (see Table [\[tab:define_error_feedbacks\]](#tab:define_error_feedbacks){reference-type="ref" reference="tab:define_error_feedbacks"}). The basic structure of feedback `$f$` for these tasks is `$\langle$`\_error type, position (optional), hint (optional)*`$\rangle$`, where position denotes the error position in the implausible hypothesis (see Appx Table [\[tab:define_error_feedbacks\]](#tab:define_error_feedbacks){reference-type="ref" reference="tab:define*error_feedbacks"}). For example, in the previous scenario, we create feedback "\_Missing link between fact and rules*". Despite the simplicity of the strategy we used for our tasks, this approach is easily generalisable to other reasoning tasks.

For MWP and sNLR problems, the underlying reasoning requires symbolic systems with closed-world rules. Hence, we consider a simple rule-based method to automatically generate the pairs of errors and their corresponding structured feedback by considering the error types and position of the errors (see Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error_overview"} and Table [\[tab:define_error_feedbacks\]](#tab:define_error_feedbacks){reference-type="ref" reference="tab:define_error_feedbacks"}).

In the moral norm generation task, we consider two kinds of fine-grained errors: _logical contradiction_ and _semantic misalignment_ (incoherent, uninformative). Moral norms are people's subjective judgments about the character and actions mentioned in the context. Each moral norm is a combination of two components (implicit structure): a moral judgment `[You shouldn’t]` and an action `[criticize your family’s religion]`. Firstly, to create _logical contradictions_, we use the concept of deontic logic from @kiehne-emnlp-2022 and derive new norms contrary to those of Moral Stories. Hence, we replace the correct moral judgments in the plausible hypothesis with inverse judgments. For example, replacing `[You shouldn’t]` from the plausible hypothesis to `[It’s good]`, as depicted in Fig. [6](#fig:error_overview){reference-type="ref" reference="fig:error*overview"}. To scale such inverse norms (\_implausible hypothesis*), we paraphrase them by substituting the adjectives with synonyms from WordNet. Secondly, to create _semantic misalignments_, we must collect implausible hypotheses that are either misaligned with the plausible hypothesis or incomplete in nature. To create them, we replace the correct action (verb phrase) from the plausible hypothesis with random verb phrases selected from the context of the plausible hypothesis.

## Synthetic Feedback Generation {#sec:synthetic_gen}

We used a few-shot setting where we varied the instruction, the number of demonstrations, and the formatting of the demonstrations. Since data generation with GPT-`$3.5$` is expensive, we generated `$30$`K, `$20$`K, and `$30$`K implausible hypotheses for MWP, sNLR and MS tasks, respectively.

::: table\*

---

**Situation:** Jim was in class when his classmate answered one of the teacher's questions wrong.
**Intention:** Jim wants his classmate was wrong.
**Moral Action:** Jim tells his classmate the right answer and offers to help him after school.
**Immoral Action:** Jim starts to laugh at his classmate and tells him he for not knowing the answer.
**Plausible Hypothesis:**  
 **Contradictory Hypothesis:**  
 **Implausible Hypothesis 1:**  
 **Implausible Hypothesis 2:**

**Situation:** Jenny has been going out with a guy for a while, but she feels it isn't working out.
**Intention:** Jenny wants
**Moral Action:** Jenny meets the guy and gently says that she wants to end the relationship.
**Immoral Action:** Jenny the guy that informs him that the relationship is over.
**Plausible Hypothesis:**  
 **Contradictory Hypothesis:**  
 **Implausible Hypothesis 1:**  
 **Implausible Hypothesis 2:**

**Situation:** Paula is leaving home and notices that the dog's water bowl is empty.
**Intention:** Paula wants
**Moral Action:** Paula fills the bowl with water before leaving dog alone in the house.
**Immoral Action:** Paula decides to fill the bowl when she gets home and leaves the dog with no water.
**Plausible Hypothesis:**  
 **Contradictory Hypothesis:**  
 **Implausible Hypothesis 1:**  
 **Implausible Hypothesis 2:**

---

:::

::: table\*

---

**Situation:** Jeff has not been happy in his relationship with his girlfriend Jenny for a long time.
**Intention:** Jeff wants to break up with Jenny.
**Moral Action:** Jeff goes to Jenny's house and tells her that he wants to break up with her.
**Immoral Action:** Jeff sends Jenny a text message telling her that he's breaking up with her.
**UQA-T5-large Output:**

**REFINER Output:**

**Situation:** Jack and his friends are playing in his backyard on a sunny day.
**Intention:** Jack wants to have fun with his friends.
**Moral Action:** Jack sets up an inflatable pool and swims in the pool with his friends.
**Immoral Action:** Jack tosses a ball around with his friends, and he accidentally hit a window of his neighbor.
**UQA-T5-large Output:**

**REFINER Output:**

**Situation:** Jack was invited to a party, but he has the flu.
**Intention:** Jack wants to attend the party and have fun.
**Moral Action:** Jack stays home, but Skypes in to the party to socialize.
**Immoral Action:** Jack goes to the party even though he is sick.
**UQA-T5-large Output:**

**REFINER Output:**

---

. []{#table:moral-stories-gen label="table:moral-stories-gen"}
:::

false Example where GPT-3 output were correct for incorrect reasons: \"actor_input\": \"\<\|SIT\|\> Jake is out with his friends at the club for the night. \<\|INT\|\> Jake wants to get drunk. \<\|I_ACT\|\> Jake gets super drunk and gets mad at someone for standing next to him he then starts to fight with him and punches him. \<\|NRM\|\>\", \"actor_output\": \"It's mean to pick fights with people at clubs. \<\|M_ACT\|\> Jake gets drunk and has fun hanging out with his friends.\", \"generated_moral_action_gpt-3\": \"Jake gets drunk and has a good time with his friends.\", \"generated_moral_action_gpt-3_critic\": \"Jake gets drunk and has a good time with his friends.\", \"generated_norm_gpt-3\": \"It is good to be a good friend.\", \"generated_norm_gpt-3_critic\": \"It's good to not get into fights.\", \"hint\": \"not getting into fights.\" ,

Example where test our critic was good but GPt-3 didn't picked up! \"actor_input\": \"\<\|SIT\|\> Tyrone is starting a fitness routine and is looking for ways to build muscle in a short time. \<\|INT\|\> Tyrone wants to do all he can to build muscle. \<\|I_ACT\|\> Tyrone starts taking anabolic steroids and eating a lot to promote lots of muscle growth. \<\|NRM\|\>\", \"actor_output\": \"Slow and steady wins the race. \<\|M_ACT\|\> Tyrone follows a strict diet and has help from a personal trainer to meet his goals.\", \"generated_moral_action_gpt-3\": \"Tyrone starts taking protein supplements and eating a lot to promote muscle growth.\", \"generated_moral_action_gpt-3_critic\": \"Tyrone starts taking protein supplements and eating a lot to promote muscle growth.\", \"generated_norm_gpt-3\": \"It is good to be healthy.\", \"generated_norm_gpt-3_critic\": \"It's good to be healthy.\", \"hint\": \"not taking anabolic steroids.\" ,

# Human Evaluation on Moral Stories {#sec:Appendix_E}

As part of the human evaluation of model generations on MS, we asked Amazon MTurk (AMT) annotators to judge the relevancy of the generated norm and the moral action based on a Likert scale, with 1 = _strongly disagree_, 2 = _disagree_, 3 = _unsure_, 4 = _agree_, and 5 = _strongly agree_. Ratings were subsequently aggregated, with scores `$\geq$` 4 deemed to be _Relevant_ and with scores, `$\leq$` 2 deemed to be _Irrelevant_ while ratings with score 3 (_Unsure_) left as is. More specifically, we asked three different human judges to evaluate each example. We performed majority voting over answers with the rating _Unsure_ assigned to those examples with no clear majority winner. In Figures [9](#fig:norm-evaluation){reference-type="ref" reference="fig:norm-evaluation"} and [10](#fig:moral-action-evaluation){reference-type="ref" reference="fig:moral-action-evaluation"}, we report a complete breakdown of evaluation results for both norm and moral action. We also report agreement scores computed according to Krippendorff's `$\alpha$` [krippendorff] in Table [\[tab:results_mng\]](#tab:results_mng){reference-type="ref" reference="tab:results_mng"}. The low and moderate `$\alpha$` values indicate that judging the plausibility of moral norms and actions is a challenging task. In Figures [11](#fig:mturk-norm-task){reference-type="ref" reference="fig:mturk-norm-task"}-[19](#fig:mturk-policy){reference-type="ref" reference="fig:mturk-policy"}, we provide excerpts of HIT instructions given to AMT workers during moral norm and action evaluation. Each task was supplemented by an Acceptance and Privacy Policy (Figure [19](#fig:mturk-policy){reference-type="ref" reference="fig:mturk-policy"}) that explains participation and data collection terms. All workers were based in US and paid \$0.10 per task which took around 5 minutes to complete on average.

[IMAGE: Human Evaluation of Moral Norm on 100 test samples.]{#fig:norm-evaluation width="0.6\\paperwidth"}

[IMAGE: Human Evaluation of Moral Action on 100 test samples.]{#fig:moral-action-evaluation width="0.6\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Norm Evaluation Task]{#fig:mturk-norm-task width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Moral Action Evaluation Task]{#fig:mturk-ma-task width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Norm Evaluation Task instructions]{#fig:mturk-norm-instructions width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Norm Evaluation Task Dos and Don'ts]{#fig:mturk-norm-do-dont width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Norm Evaluation Task examples]{#fig:mturk-norm-examples width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Moral Action Evaluation Task instructions]{#fig:mturk-ma-instructions width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Moral Action Evaluation Task Dos and Don'ts]{#fig:mturk-ma-do-dont width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Moral Action Evaluation Task examples]{#fig:mturk-ma-examples width="0.7\\paperwidth"}

[IMAGE: Excerpt from AMT HIT instructions: Acceptance and Privacy Policy]{#fig:mturk-policy width="0.7\\paperwidth"}

[^1]:
    In a reasoning task, the intermediate representations can be viewed as inference rules, explanations or reasoning steps.\
    \* Work done at EPFL

[^2]: Note that we transform the structured feedback into semi-structured textual feedback using templates.

[^3]: <https://github.com/debjitpaul/refiner>

[^4]: We use "inference steps/representations" and "hypothesis" interchangeably.

[^5]: Further details about feedback are provided in Appx.[13](#sec:feedback_gen){reference-type="ref" reference="sec:feedback_gen"}.

[^6]: Since the automatic scores such as BLUE, ROUGE, etc. only account for word level similarity between gold norms or actions and generate norms or actions.

[^7]: Since the automatic scores such as BLUE, ROUGE, etc. only account for word level similarity between gold norms or actions and generate norms or actions.
