# Abstract

We introduce Reprompting, an iterative sampling algorithm that automatically learns the Chain-of-Thought (CoT) recipes for a given task without human intervention. Through Gibbs sampling, Reprompting infers the CoT recipes that work consistently well for a set of training samples by iteratively sampling new recipes using previously sampled recipes as parent prompts to solve other training problems. We conduct extensive experiments on 20 challenging reasoning tasks. Results show that Reprompting outperforms human-written CoT prompts substantially by +9.4 points on average. It also achieves consistently better performance than the state-of-the-art prompt optimization and decoding algorithms.

# Introduction

Few-shot prompting with large language models (LLMs) has revolutionized the landscape of natural language processing. Given natural language instructions and a few demonstrations as in-context examples, LLMs can quickly adapt to new tasks, approaching or even surpassing the performance of models fine-tuned on larger datasets on a wide range of tasks [gpt3]. However, such prompting techniques fall short on tasks that require multi-step reasoning and constraint propagation [wei2022chain], such as _logical deduction_ in the Big-Bench Hard benchmark [suzgun2022challenging]. To address these limitations, prior works proposed to teach LLMs to reason step by step like humans by prompting them with chain-of-thought (CoT) reasoning steps for a few example problems [wei2022chain]. Despite the improved performance, such a method requires human experts with not only the task knowledge but also an understanding of how prompting works to craft the CoT prompt for each task [zamfirescupereira2023why], which limits the scalability and generalizability of the method. Furthermore, a problem can be reasoned in many different ways, and some of them may work well on some LLMs but not on others. To fairly compare the performance of various LLMs on each task, we need to find the CoT prompt that works best for each model in a feasible way, which remains a challenge.

In this paper, we propose _Reprompting_, an iterative sampling algorithm that **automatically** finds effective CoT prompt for each model given a few question-answer pairs without human intervention. Specifically, the algorithm aims to infer a set of CoT recipes that perform consistently well as in-context examples for a set of training problems. We frame it as a problem of sampling from a joint distribution of CoT recipes given the training question-answer pairs, which is infeasible to characterize directly but can be approached using Gibbs sampling -- we initially sample a set of recipes through zero-shot prompting, expand the set with new recipes sampled iteratively by using previously sampled recipes as parent prompts to solve a different training problem, and weed out the least-fit recipes that lead to wrong answers. Thus, the algorithm will eventually converge to a set of recipes that share similar chains of thought for effectively solving the training problems. These CoT recipes optimized on the training set then serve as effective CoT prompts for solving unseen test problems.

We evaluate _Reprompting_ on 20 tasks from three reasoning benchmarks including Big-Bench Hard (BBH) [suzgun2022challenging], GSM8K [cobbe2021gsm8k] and MATH [hendrycks2021math] using ChatGPT [openai2023gpt4] and InstructGPT [ouyang2022training] as LLMs. Compared with human-written CoT prompts, _Reprompting_ achieves +9.4 higher accuracy on average. It also consistently outperforms self-consistency decoding [wang2022self], Auto-CoT [zhang2022automatic] and Automatic Prompt Optimization [pryzant2023automatic] by 11--33 points on average. Furthermore, _Reprompting_ facilitates model combination by using different LLMs for initializing and sampling new recipes. Empirically, leveraging ChatGPT to sample initial recipes for InstructGPT brings up to +71 point improvements over using InstructGPT alone and even outperforms ChatGPT alone on certain tasks. Lastly, our results confirm that the CoT recipes that work well on one model may work poorly on another, even when the latter may approach the best performance using prompts optimized for itself. These findings emphasize the need to optimize the prompt for each model for fair comparisons.

# _Reprompting_: Prompt Inference Through Gibbs Sampling

## In-Context Learning

**In-context learning** has become the cornerstone of evaluating large language models (LLMs) [gpt3; srivastava2022beyond]. To facilitate this evaluation approach, data is provided for a large number of different tasks, with each task consisting of dozens or, more often, hundreds of instances with varying problem setup and question texts `latex $x_i$ ` and their corresponding text answers `latex $y_i$ `, where `latex $i\in [1..N]$ ` and `latex $N$ ` is the number of problem instances for the task. Formally, in-context learning infers the answer for a given test question `latex $x$ ` by prompting an LLM with a set of demonstration examples `latex $\{x_i,y_i\}_{i=1}^K$ `:

```latex
$$\begin{equation}
    \hat{y} \sim p_{LLM}(y | \{x_i,y_i\}_{i=1}^K, x)
\end{equation}$$
```

The performance of in-context learning can be significantly enhanced by incorporating auxiliary knowledge or human-written instructions in a prompt [shwartz-etal-2020-unsupervised; zelikman2022star; nye2021show], particularly in the form of Chain-of-Thought (CoT) reasoning [wei2022chain; wang2022self; zhou2022least; creswell2022selection; wang2022rationale; liu-etal-2022-multi; kojima2022large; li2022advance].

[IMAGE: An example that ChatGPT can propose various different solutions to the same problem in zero-shot - figures/logical_deduction_chatgpt_zeroshot.png]

In-context learning with CoT [wei2022chain] can be seen in a similar light, statistically. In addition to the question-answer pairs `latex $\{x_i, y_i\}$ `, the CoT prompt also contains worked out step-by-step reasoning "recipes" `latex $z_i$ ` in text, which are inserted between the question and answer: `latex $\{x_i, z_i, y_i\}$ `. These recipes can play two roles. First, they further explain the intent of the question `latex $x_i$ `, as a small collection of question-answer pairs alone may be insufficient to disambiguate among different patterns an LLM might detect. The second role is more important: it provides step-by-step guidance on one problem and thus teaches an LLM to solve similar problems following the same routine as it continues the text conditioned on the previous tokens. In the extreme, with prompts that strictly regiment self-attention, GPT models can be turned into Turing Machines to execute standard computer algorithms [jojic2023gptTM]. In practice, the CoT prompts commonly used in prior work fall somewhere between colloquial explanations and regimented recipes. Formally, **in-context learning with CoT** infers the answer for a given test question `latex $x$ ` by prompting an LLM with an optional instruction message `latex $m$ ` and a set of demonstration examples with step-by-step solutions `latex $\{x_i, z_i, y_i\}_{i=1}^K$ `:

```latex
$$\begin{equation}
    \hat{z}, \hat{y} \sim p_{LLM}(z, y | \{x_i, z_i, y_i\}_{i=1}^K, x, m)
\label{eq:in_context_assumption}
\end{equation}$$
```

Here, `latex $m$ ` is a textual message that instructs the model to generate the step-by-step solution `latex $z_j$ ` before the answer text `latex $y_j$ ` and the specific format to present the answer. It can be task-specific or generic, as in the case of our experiments. Such an instruction message can trigger instruction-tuned LLMs to generate step-by-step solutions given `latex $[x_j, m]$ ` alone without any demonstration examples (i.e. `latex $K = 0$ `), as illustrated in Figure 1. These solutions follow varying styles and often lead to incorrect answers. However, we argue that good recipes for solving the set of problems on a given task can evolve from these zero-shot solutions. In the next section, we introduce _Reprompting_, an iterative sampling algorithm that automatically produces the CoT recipes for a given set of problems without human intervention.

## Prompt Inference Through Gibbs Sampling

We introduce the _Reprompting_ algorithm, which aims to find a set of CoT recipes `latex $z_i$ ` that work **consistently** well as few-shot in-context examples for a dataset `latex $\{x_i,y_i\}_{i=1}^N$ `. Specifically, we formulate it as the problem of sampling from a joint distribution:

```latex
$$\begin{equation}
    p(z_1, z_2,...z_N| \{x_i,y_i\}_{i=1}^N, m)
\label{eq:joint_distribution}
\end{equation}$$
```

such that `latex $z_{1...N}$ ` are generalized enough so that given any test question `latex $x$ `, the distribution over `latex $z$ ` and `latex $y$ ` is approximately invariant to the choice of the `latex $K$ `-shot CoT recipes:

```latex
$$\begin{equation}
\begin{split}
    & p_{LLM}(z, y | \{x_i, z_i, y_i\}_{i=1}^N, x, m) \\
    \approx& p_{LLM}(z, y | \{x_i, z_i, y_i\}_{i \in S}, x, m), \, \quad \forall S \subset [1,N], |S| = K
\end{split}
\label{eq:reprompting_approximation}
\end{equation}$$
```

Without characterizing the joint distribution, we can use Gibbs sampling [Geman1984StochasticRG] to generate such samples `latex $\{z_1, z_2,...z_N\}$ ` by first sampling `latex $\{z_1, z_2,...z_N\}$ ` independently from the distributions `latex $p(z_j | x_j, y_j)$ `, and then iteratively drawing samples from the conditional distributions `latex $p(z_j | z_1,...,z_{j-1},z_{j+1},...z_N, \{x_i,y_i\}_{i=1}^N, m)$ `. Based on the property of the joint distribution, we have the following approximation:

```latex
$$\begin{equation}
\begin{split}
    &p(z_j | z_1,...,z_{j-1},z_{j+1},...z_N, \{x_i,y_i\}_{i=1}^N, m) \\
    =& p_{LLM}(z_j | \{x_i, z_i, y_i\}_{i \neq j}, x_j, y_j, m) \\
    \propto& p_{LLM}(z_j, y_j | \{x_i, z_i, y_i\}_{i \neq j}, x_j, m) \\
    \approx& p_{LLM}(z_j, y_j | \{x_i, z_i, y_i\}_{i \in S_j}, x_j, m), \, \\
    &\forall S_j \subset [1,N]\backslash \{j\}, |S_j| = K
\end{split}
\end{equation}$$
```

Thus, we can sample `latex $z_j$ ` by randomly picking `latex $K$ ` data points (excluding `latex $j$ `) and then sampling `latex $z_j$ ` with weights proportional to the conditional probability:

```latex
$$\begin{equation}
\begin{split}
    &p_{LLM}(z_j, y_j | \{x_i, z_i, y_i\}_{i \in S_j}, x_j, m) \\
    =& p_{LLM}(z_j | \{x_i, z_i, y_i\}_{i \in S_j}, x_j, m) \\
    &\cdot p_{LLM}(y_j | \{x_i, z_i, y_i\}_{i \in S_j}, x_j, m, z_j)
\end{split}
\end{equation}$$
```

One way to approximate it is to sample several `latex $\hat{z}_j$ ` from the LLM conditioned on `latex $\{x_i, z_i, y_i\}_{i \in S_j}$ `, `latex $x_j$ ` and `latex $m$ `, compute the weight for each `latex $\hat{z}_j$ ` using the model's probability of the correct answer `latex $y_j$ ` conditioned on `latex $\{x_i, z_i, y_i\}_{i \in S_j}$ `, `latex $x_j$ `, `latex $m$ ` and `latex $\hat{z}_j$ `, and sample a `latex $z_j$ ` from `latex $\{\hat{z}_j\}$ ` based on the weights. In practice, however, the model likelihood of a given text may be inaccessible. Thus, we approximate it using rejection sampling -- we sample `latex $z_j$ ` by sampling `latex $\hat{z}_j$ ` and `latex $\hat{y}_j$ ` from `latex $p_{LLM}(z, y | \{x_i, z_i, y_i\}_{i \in S_j}, x_j, m)$ ` and then reject `latex $\hat{z}_j$ ` with a probability of `latex $p_{rej}$ ` if `latex $\hat{y}_j \neq y_j$ `. Otherwise, we accept `latex $\hat{z}_j$ ` and update the sample. Algorithm 1 shows the complete _Reprompting_ algorithm consisting of the initialization and iterative sampling steps. Note that we set the rejection probability `latex $p_{rej}$ ` in a way that allows solutions that lead to incorrect answers to be kept occasionally, as these solutions may still contain useful segments that evolve into good recipes through _Reprompting_.

**Algorithm: Reprompting**

- **Initialization:** Sample initial recipes through zero-shot prompting
- **Sampling:** Iteratively sample new recipes using Gibbs sampling with rejection

Based on the properties of Gibbs sampling [casella1992explaining; roberts1994simple], the algorithm should converge to the point where the probability `latex $p_{LLM}(z_j, y_j | \{x_i, z_i, y_i\}_{i \in S_j}, x_j, m)$ ` is high and agnostic to the choice of `latex $S_j$ `, which leads to a set of `latex $\{z_j\}$ ` that work well as a prompt for solving similar problems in a separate test set.

The algorithm can also be viewed as a variant of evolutionary algorithms: 1) First, we generate the initial population of individuals (where each individual is a CoT recipe given a problem). 2) Next, we repeat the following regeneration steps iteratively: 2a) we first evaluate the fitness of each CoT recipe by comparing the answer that follows the recipe with the correct answer and weed out the least-fit recipes; 2b) we then breed new individuals through crossover and mutation by randomly selecting K recipes from the population as parent recipes, which are then used to prompt the LLM to generate recipes for a new problem. By repeating the 2a and 2b steps, initial recipes can be recombined (Figure 4) and evolve into better recipes (Figure 3) through iterations. And eventually, the fittest recipes (i.e. ones that can be followed to solve similar problems) will survive.

During testing, we select `latex $K$ ` tuples `latex $\{x_i, z_i, y_i\}$ ` from the inferred `latex $\{z_j\}$ ` based on the training accuracy when using each tuple individually in a prompt.

# Experimental Setup

We evaluate the _Reprompting_ algorithm against various baselines including zero-shot, few-shot, Chain-of-Thought (CoT), Chain-of-Thought combined with self-consistency decoding [wang2022self], Auto-CoT [zhang2022automatic] and Automatic Prompt Optimization [pryzant2023automatic] on 20 challenging reasoning tasks, including 12 challenging tasks in the Big-Bench Hard (BBH) benchmark [suzgun2022challenging], GSM8K [cobbe2021gsm8k] and MATH [hendrycks2021math]. We choose both tasks that have been shown to benefit substantially from human-written CoT recipes, such as Logical Deduction, Geometric Shapes, Temporal Sequences, GSM8K and MATH, and tasks on which CoT does not improve much or does not improve consistently over zero-shot prompting, such as Formal Fallacies, Movie Recommendation and Word Sorting.

## _Reprompting_ Setup

For each task, we randomly select 20 training examples from the Big-Bench dataset excluding the test examples in the BBH benchmark. We experiment with having `latex $k \in \{1, 3\}$ ` clones of the same training example in the set `latex $\{x_i,y_i\}_{i=1}^N$ ` to allow for more diverse recipe samples (so the number of recipes we need to sample from the joint distribution is `latex $N = 20*k$ `) and choose `latex $k$ ` that obtains the highest training accuracy. We set the number of examples in the prompt by `latex $K = 5$ `. We run _Reprompting_ for a maximum of `latex $M = 20,000$ ` iterations. We allow for early stopping if the average training accuracy stops increasing for `latex $1,000$ ` iterations. For the rejection probability, we experiment with `latex $p_{rej} \in \{0.95, 0.99\}$ ` and choose `latex $p_{rej} = 0.99$ ` as it leads to higher training accuracy on various tasks.

## Baselines

#### Prompting Baselines

For **zero-shot prompting**, we only include the test question `latex $x_i$ ` and the special message `latex $m$ ` in the prompt, which triggers the model to generate a step-by-step solution prior to the answer text. For **few-shot prompting**, we randomly select 20 training examples in the same way as in _Reprompting_ and concatenate these examples in the form of question-answer pairs in the prompt, followed by the test question. For **CoT prompting**, we use the human-written CoT prompts from Suzgun et al. For **CoT with self-consistency decoding**, we use the same CoT prompts and follow Wang et al. by sampling 10 reasoning paths per question and taking the majority vote on the answer. For both approaches, we randomly select 20 training examples in the same way as in _Reprompting_.

#### Prompt Optimization Baselines

We also compare _Reprompting_ with two previous state-of-the-art prompt optimization algorithms, including **Auto-CoT** [zhang2022automatic] and **APO** [pryzant2023automatic]. For **Auto-CoT**, since the original Auto-CoT algorithm differs from our setting as it focuses on the unsupervised setting without exploiting any labeled examples, we adapt the algorithm to our few-shot setting where it follows the original algorithm to generate diverse CoT recipes through zero-shot prompting but selects the demonstration examples based on the training accuracy when used individually in a prompt. We also evaluate **APO**, a recently proposed nonparametric prompt optimization algorithm that uses LLMs to generate "textual gradient" -- criticism of the current prompt -- based on training samples and edit the prompt accordingly. The algorithm has been shown to outperform other prompt optimization methods, such as TEMPERA [zhang2023tempera], Automatic Prompt Engineering [zhou2023large], and AutoGPT.

## Large Language Models (LLMs)

We experiment with two powerful LLMs including ChatGPT (gpt-3.5-turbo; [openai2023gpt4]) and InstructGPT (text-davinci-003; [ouyang2022training]). We also experiment with a combo model for _Reprompting_ where we use ChatGPT as `latex $LLM_1$ ` for initialization and InstructGPT as `latex $LLM_2$ ` for sampling. For both LLMs, we set the maximum number of output tokens to 500, `latex $top\_p = 0.5$ `, zero frequency and presence penalty. Additionally, we include "END" as the stop word. We set the temperature to 1.0 for _Reprompting_ and `latex $0.0$ ` for testing.

## Evaluation Protocol

We extract the final answer from the model output by extracting the text between "<answer>" and "</answer>", except for the CoT baseline where we extract the final answer in the same way as in Suzgun et al. We measure accuracy based on exact match by comparing the extracted answer with the ground truth.

# Results

## Main Results

**Table 1: Performance on Additional Tasks**

|             | ZS   | FS   | CoT      | _Reprompting_ |
| ----------- | ---- | ---- | -------- | ------------- |
| **BBH**     |      |      |          |               |
| Date        | 63.6 | 46.4 | **76.8** | 76.4          |
| Formal      | 49.2 | 53.6 | 48.4     | **56.8**      |
| Movie       | 59.2 | 72.4 | 25.6     | **78.4**      |
| ColoredObj  | 66.8 | 48.8 | **76.0** | 74.0          |
| Ruin        | 53.2 | 66.8 | 60.8     | **74.8**      |
| Salient     | 43.2 | 53.2 | 32.8     | **54.8**      |
| WordSort    | 58.0 | 72.0 | 46.0     | **73.2**      |
| **GSM8K**   | 45.6 | 26.5 | 75.6     | **79.5**      |
| **MATH**    |      |      |          |               |
| Algebra     | 37.6 | 23.7 | 52.0     | **53.1**      |
| Counting    | 17.1 | 19.8 | 26.6     | **32.3**      |
| Geometry    | 12.4 | 16.2 | 28.5     | **29.2**      |
| IntAlgebra  | 9.4  | 12.1 | **18.0** | 16.8          |
| Number      | 20.8 | 17.1 | 32.9     | **33.3**      |
| Prealgebra  | 31.4 | 33.2 | **54.0** | 43.8          |
| Precalculus | 7.4  | 18.4 | 19.0     | **19.3**      |
| **Average** | 38.3 | 38.7 | 44.9     | **53.0**      |

Performance of ChatGPT using _Reprompting_ versus _ZS_ (zero-shot), _FS_ (few-shot), and _CoT_ prompting methods on seven additional tasks from Big-Bench Hard (BBH), GSM8K, and MATH.

**Table 2: Ablation Study**

|             | p_rej=0 | p_rej=1  | NoRec | Orig.    |
| ----------- | ------- | -------- | ----- | -------- |
| Logical     | 56.3    | 61.9     | 54.7  | **66.3** |
| ObjectCount | 52.0    | **97.2** | 95.6  | **97.2** |
| Temporal    | 74.8    | 74.4     | 90.4  | **93.2** |
| **Average** | 61.0    | 77.8     | 80.2  | **85.6** |

Ablation study on rejection sampling (including no rejection (p_rej=0) and always rejecting (p_rej=1)) and recombination (_NoRec_ represents _Reprompting_ without recombination of previously sampled recipes) on Logical Deduction, Object Counting, and Temporal Sequences from Big-Bench Hard (BBH). The _Orig._ column represents the standard _Reprompting_ algorithm without ablation.

**Table 3: Cross-Model Testing**

| Tasks       | InsGPT     | ChatGPT    |
| ----------- | ---------- | ---------- |
| Logical     | 65.9       | **66.3\*** |
| Geometric   | 53.6       | **72.8\*** |
| ObjectCount | **99.6\*** | 96.8       |
| Penguins    | 82.2       | **85.6\*** |
| Temporal    | **99.2\*** | 81.6       |

Testing the best performing CoT prompt learned on ChatGPT, InstructGPT or InstructGPT+ChatGPT through _Reprompting_ on both ChatGPT and InstructGPT. The superscript * denotes the model used as LLM_2 in *Reprompting\*.

We first compare the performance of _Reprompting_ with all the baselines on five BBH tasks. Results confirm the previous finding that few-shot in-context prompting improves the performance over zero-shot [gpt3] and that CoT prompting outperforms both zero-shot and few-shot prompting by a large margin. However, human-written CoT prompting requires costly prompt engineering, as not all CoT recipes work equally well on LLMs [madaan2022; jojic2023gptTM]. Crucially, we show that using _Reprompting_, LLMs can achieve better performance compared to the existing CoT prompts, but without requiring any human guidance on how to solve problems step by step. Specifically, comparing the performance of ChatGPT using _Reprompting_ versus the best human-written CoT prompts from Suzgun et al., _Reprompting_ achieves consistently higher scores on all tasks.

Next, we compare _Reprompting_ with self-consistency (SC) decoding [wang2022self]. CoT+SC improves over CoT on two of the five tasks, but the improvements are not consistent. By contrast, _Reprompting_ consistently outperforms CoT+SC by 2--26 points on all five tasks.

Additionally, we compare _Reprompting_ with existing prompt optimization algorithms. APO improves over zero-shot prompting on three out of five tasks but underperforms it on the two tasks where the model needs to search through a wide range of strategies to find effective solutions. By contrast, _Reprompting_ consistently outperforms zero-shot and CoT prompting, and improves over APO by 20--43 points on all five tasks. When compared against Auto-CoT [zhang2022automatic], _Reprompting_ also archives higher accuracy by +11 points on average. In summary, _Reprompting_ outperforms strong decoding and prompt optimization baselines by 11--33 points on average.

Comparing the performance of _Reprompting_ on different LLMs, we observe that InstructGPT underperforms ChatGPT on most tasks. However, we show that by using ChatGPT just as the initialization model `latex $LLM_1$ ` to bootstrap InstructGPT as `latex $LLM_2$ ` in _Reprompting_, we can improve performance over InstructGPT alone by 5--71 points and achieve competitive or even better performance than ChatGPT alone on two of the five tasks. We show in the Appendix why that is: while InstructGPT can follow a given recipe and even be used for recombining and evolving them, it is less capable of generating diverse initial solutions in a zero-shot manner. However, through _Reprompting_, we can use ChatGPT to "teach" InstructGPT diverse strategies for solving the training problems, which are then recombined and evolved by InstructGPT into better CoT prompts for itself.

Furthermore, Table 1 shows the performance of _Reprompting_ against zero-shot, few-shot and CoT prompting (all using ChatGPT) on the remaining 15 tasks. _Reprompting_ still outperforms zero-shot and few-shot prompting consistently and substantially by 14-15 points on average. Compared with CoT, _Reprompting_ achieves better performance on 11 out of 15 tasks. On average, _Reprompting_ outperforms CoT by +8.2 points. Interestingly, on tasks where CoT even underperforms zero-shot prompting, such as Movie Recommendation, Salient Translation Error Detection, and Word Sorting, _Reprompting_ still improves over zero-shot prompting by large margins. This suggests that not all CoT recipes improve model performance, and some may even lead to degradation. This further emphasizes the need for algorithms like _Reprompting_ for discovering and optimizing the CoT prompt to best exploit and compare LLMs.

Overall, these findings highlight the potential of _Reprompting_ as a powerful method for automating CoT prompting on a wide range of tasks.

[IMAGE: Learning curves of the Reprompting algorithm using InstructGPT, ChatGPT, and the combo ChatGPT+InstructGPT models on the Logical Deduction task - figures/logical_deduction_*_gibbs_k5.pdf]

## Quantitative Analysis

#### Ablation Study

We conduct an ablation study on the rejection sampling and recombination process. Results in Table 2 show that, without rejection sampling, the test performance degrades substantially by 25 point on average. Always rejecting solutions that lead to incorrect answers also causes a degradation of 8 point. Additionally, not allowing multiple solutions to be recombined when sampling new solutions at the iterative sampling stage also hurts performance.

[IMAGE: An example of how the CoT recipes evolve through Reprompting - figures/logical_deduction_chatgpt_reprompt.png]

[IMAGE: Examples of how fragments from different recipes in a prompt can be (re)combined into a better recipe to solve a new problem through Reprompting - figures/object_counting_chatgpt_reprompt_combine*.png]

#### Do the generated CoT recipes generalize across models?

We test the best-performing CoT recipes optimized with InstructGPT, ChatGPT, or InstructGPT+ChatGPT through _Reprompting_ on both InstructGPT and ChatGPT. As shown in Table 3, the CoT recipes optimized for one model may not work as well for other models. Specifically, we observe that on tasks such as _Logical Deduction_ and _Object Counting_, the best CoT recipes achieve similar performance on both InstructGPT and ChatGPT. However, on _Geometric Shapes_ and _Temporal Sequences_, the best CoT prompts optimized for `latex $LLM_2$ ` work well on `latex $LLM_2$ `, but poorly with the other LLM -- using them on the other LLM leads to 18--19 points lower accuracy than testing with `latex $LLM_2$ ` (see examples in Figure 6). On such tasks, using the prompt optimized for the testing LLM improves accuracy by 11--12 points over the same testing LLM with prompt optimized for other LLMs. These results suggest that, to make a fair comparison between different LLMs, one needs to optimize the CoT prompt for each model.

#### _Reprompting_ improves CoT recipes over iterations.

In Figure 2, we plot the average training accuracy (averaged over iterations up to the current iteration) over training iterations on _Logical Deduction_. For all three model variants, the initial training accuracy is relatively low, but it gradually increases (with occasional fluctuations) over iterations until convergence. This is the result of evolution and recombination of the recipes associated with training examples.

#### Compute and Resources

We use the OpenAI APIs for all our experiments. Running _Reprompting_ costs around $80 (in US dollars) on gpt-3.5-turbo and $800 on text-davinci-003 based on the standard pricing, while being exempted from any human cost. By contrast, CoT prompting requires manual prompt construction and engineering, which costs not only human labor (including the cost for humans to get familiar with the task itself and how LLM prompting works, write down various CoT solutions for each problem, test and optimize the solutions on the LLM) but also LLM queries, but these costs are typically neglected in previous works. In addition, previous works typically compare different LLMs using the same CoT prompt. While this strategy avoids additional costs for customizing CoT prompt for each LLM (even with _Reprompting_, one can also save the cost by running it with ChatGPT and using the inferred CoT prompt on other LLMs), it risks making unfair comparisons as we have shown in Table 3 that the CoT prompt that works well on one model may be sub-optimal for another.

## Qualitative Analysis

We observe that **even model outputs containing errors and unreasonable deductions can evolve into a high-quality recipe through _Reprompting_.** This is illustrated by the _Logical Deduction_ example in Figure 3, when `latex $K=1$ `, where the model initially generates a recipe that is erroneous and contains illogical deductions. However, when this recipe is used as the new prompt for solving a similar problem, the model is able to exploit parts of the recipe and propose an alternative way to continue reasoning. Although the subsequent recipe still contains errors, it aids the model in correctly solving other problems when incorporated into a prompt. As a result, such recipes will be populated on other training samples, while the recipes that lead to low accuracy will eventually die out.

#### _Reprompting_ combines fragments from different recipes into a better one.

_Reprompting_ benefits from having multiple examples in the prompt, which allows the model to integrate various segments from different prompt recipes into a new recipe. As illustrated by the _Object Counting_ examples in Figure 4, the model can combine large segments of reasoning steps, as well as small segments that address distinct cases to solve a more complex problem. The resulting prompts sometimes, but not always, share similarities with the human-written prompts (See the Appendix).

# Related Work

#### In-Context Learning

is an emergent ability of LLMs as they scale up in model sizes and training data, where an LLMs can learn to perform a task from a few examples in the context (which is also referred to as few-shot prompting) [gpt3]. It has been shown to achieve promising few-shot and even zero-shot performance on various natural language processing [gpt3; schick2020exploiting; perez2021true] and program synthesis [austin2021program] tasks.

#### Reasoning via Chain-of-Thought Prompting

Chain-of-Thought (CoT) prompting is a technique that enables LLMs to perform complex reasoning tasks by prompting them with a few examples with step-by-step solutions [wei2022chain; suzgun2022challenging]. CoT prompting has been shown to improve performance on various reasoning tasks, such as arithmetic reasoning [wei2022chain; zhou2022least], symbolic reasoning [wei2022chain; zhou2022least], multi-hop question answering [press2022measuring; arora2022ask], and natural language inference [wang2022self]. However, designing effective CoT prompts requires human experts with an understanding of both the task and the prompting technique [zamfirescupereira2023why], which limits the scalability and generalizability of CoT prompting.

Several works have attempted to **automate the process of CoT prompt discovery**. Zhang et al. proposed Auto-CoT, which uses LLMs to generate CoT solutions for diverse training questions in zero-shot and integrates the generated CoT solutions in the prompt for solving test questions. This method differs from _Reprompting_ in that: 1) it focuses on the unsupervised setting and exploits a large set of example questions without annotated answers, and 2) it relies more heavily on the correctness of the zero-shot recipes as it does not have any iterative algorithm (as in _Reprompting_) to further improve the recipes. In our experiments, we adapted Auto-CoT to the few-shot setting and showed that _Reprompting_ outperforms the few-shot version of Auto-CoT.

Deng et al. [zhang2023tempera] proposed to train an additional policy model to find the best prompt through reinforcement learning, but their approaches are limited to prompt optimization within a relatively small search space (i.e. it is restricted to the prompts that are either extremely short or within a small edit distance from an initial prompt). Zhou et al. proposed a method for automatically generating, scoring and selecting effective instruction messages `latex $m$ ` for zero-shot chain-of-thought reasoning, which is orthogonal and can be potentially combined with our algorithm. Paranjape et al. introduced a framework that automatically retrieves demonstrations of related tasks from a task library and generates CoT solutions for the new task. However, this framework still requires collective human efforts to write demonstrations for a diverse set of tasks in the task library. In contrast, our _Reprompting_ algorithm enables LLMs to solve complex reasoning tasks without any human guidance. Additionally, Yoran et al. proposed a multi-chain reasoning (MCR) method that prompts LLMs to combine pieces of information from multiple chains of thought to predict the final answer, which differs from our method in two ways: first, MCR combines multiple CoT solutions to the same question at test time, while _Reprompting_ combines CoT solutions generated for different training questions before testing; second, MCR combines solutions only once, whereas _Reprompting_ iteratively samples new solutions and recombines them. As a result, _Reprompting_ generates effective CoT recipes from only a few training examples, resulting in improved test performance without slowing down test inference.

# Conclusion

We introduce _Reprompting_, an automated prompt inference algorithm which, without human effort, discovers effective chain-of-thought (CoT) prompts for each task given a few question-answer pairs. Experiments on 20 challenging reasoning tasks show that _Reprompting_ achieves +9.4 higher accuracy than human-written CoT on average. It also outperforms self-consistency decoding and the state-of-the-art prompt optimization algorithms by 11--33 points on average. Our results also suggest that LLM comparisons can be highly sensitive to the choice of CoT prompts, further emphasizing the need for automatic prompt discovery and optimization using algorithms such as _Reprompting_.

# Impact Statement

This paper presents work whose goal is to advance the field of Machine Learning. There are many potential societal consequences of our work, none which we feel must be specifically highlighted here.

# Additional Illustrations

#### On sensitivity to initialization

We have shown that _Reprompting_ can be sensitive to initial recipe generation. Armed with the optimal prompts discovered with ChatGPT+InstructGPT through _Reprompting_, InstructGPT can reach test accuracy equalling or besting ChatGPT on most challenging reasoning tasks. However, on some tasks, such prompts could not be discovered using InstructGPT itself as the initialization model `latex $LLM_1$ `. Figure 5 points to a likely explanation: ChatGPT can generate a wider range of useful recipes, and whether these initial recipes lead to the correct solution or not, InstructGPT can follow them and, through _Reprompting_, refine and correct them iteratively. Thus, as we have shown in our experiments, with a diverse pool of initial recipes, LLMs that may appear inferior based on their zero-shot performance may end up performing just as well or better than LLMs whose zero-shot performance is more encouraging. It would be interesting to see if _Reprompting_ can use a mixture of LLMs in initialization to perform even better, or if humans can be put back into the loop to provide some initial recipes or some generic instructions on how to generate such recipes.

#### On transferability of discovered recipes

The fact that `latex $LLM_1$ ` (ChatGPT) can point `latex $LLM_2$ ` (InstructGPT) in the right directions for prompt discovery does not mean that the discovered prompts, having been optimized for training performance on `latex $LLM_2$ `, will perform well when used to prompt `latex $LLM_1$ `. In fact, Table 3 indicates that the discovered CoT recipes that work for one model may not necessarily work for other models. For example, in the case of _Temporal Sequences_, the best performance is achieved with a prompt trained with InstructGPT (after initialization with ChatGPT as `latex $LLM_1$ `). But when using that prompt on ChatGPT, the test performance is by 18% lower. Figure 6 illustrates how ChatGPT and InstructGPT follow the same CoT prompt differently. Following the prompt recipes, the time intervals that need to be reasoned over are sorted, and among the sorted list, the missing interval was inserted as the possible interval when the person in question could have performed an activity. InstructGPT follows this procedure with accuracy over 99%, but ChatGPT sometimes skips the crucial line (for this recipe) with the missing interval within the timeline and therefore obtains suboptimal test accuracy. However, the best performance of ChatGPT (using the CoT prompt optimized for itself through _Reprompting_) is only slightly lower than that of the ChatGPT+InstructGPT combination.

These results suggest that, for a fair comparison between different LLMs, one needs to optimize the CoT prompt for each LLM using prompt optimization algorithms such as _Reprompting_.

[IMAGE: Comparing the CoT recipes inferred through Reprompting using InstructGPT alone versus ChatGPT (for initialization) + InstructGPT (for sampling) - figures/logical_deduction_ChatGPT+InstructGPT.png]

[IMAGE: An example on Temporal Sequences (BBH) where ChatGPT underperforms InstructGPT using the same CoT prompt optimized for InstructGPT via Reprompting - figures/temporal_sequences_InstructGPT_vs_ChatGPT.png]

[IMAGE: Examples of the best-performing CoT recipes inferred via Reprompting on Logical Deduction, Geometric Shapes, Object Counting, Penguins in a Table, and Temporal Sequences - figures/reprompt_CoT_*.png]

#### How do the model-generated CoT recipes differ from human-written ones?

In the paper, We evaluated the performance of the CoT prompt discovered through _Reprompting_ and contrasted it with human-written ones. As illustrated by the example recipes in Figure 7, the automatically discovered CoT recipes share some similarities to human-written ones on some tasks (such as _Logical Deduction_), but differs on other tasks. For instance, on _Object Counting_, the CoT generated using _Reprompting_ computes the total number of objects by incrementing the count one by one (e.g. adding `latex $4$ ` to the count `latex $5$ ` by "$[6, 7, 8, 9]$"), while in the human written recipe, it computes the addition through an arithmetic formula at the end.
