# Abstract {#abstract .unnumbered}

Reasoning is critical for large language models (LLMs) to excel in a wide range of tasks. While methods like Chain-of-Thought (CoT) reasoning and enhance LLM performance by decomposing problems into intermediate steps, they also incur significant overhead in token usage, leading to increased costs. We find that the reasoning process of current LLMs is unnecessarily lengthy and it can be compressed by including a reasonable token budget in the prompt, but the choice of token budget plays a crucial role in the actual compression effectiveness. We then propose a token-budget-aware LLM reasoning framework that dynamically adjusts the number of reasoning tokens based on the reasoning complexity of each problem. Experiments show that our method effectively reduces token costs in CoT reasoning with only a slight performance reduction, offering a practical solution to balance efficiency and accuracy in LLM reasoning. Code: <https://github.com/GeniusHTX/TALE>[^1].

> _"It is not enough to have a good mind; the main thing is to use it well."_
>
> $-$ René Descartes

# Introduction {#sec:intro}

Reasoning plays a crucial role in enabling large language models (LLM) to perform effectively across a wide range of tasks [@zhou2022least; @hao2023reasoning; @2024-llmreasoner; @jin2024exploring; @wang2024mllm; @wang2025dump]. A variety of methods have been proposed to enhance the reasoning capabilities of large language models [@suzgun2022challenging; @wang2023plan; @feng2023alphazero; @xie2024monte]. Among these, Chain-of-Thought (CoT) [@2022-CoT] is the most representative and widely adopted approach. It enhances the reliability of the model's answers by guiding large language models with the prompt "Let's think step by step", encouraging them to decompose the problem into intermediate steps and solve each before arriving at the final answer. [\[fig:case_no_CoT\]](#fig:case_no_CoT){reference-type="ref+label" reference="fig:case_no_CoT"} and [\[fig:case_vanilla_CoT\]](#fig:case_vanilla_CoT){reference-type="ref+label" reference="fig:case_vanilla_CoT"} illustrate an intuitive example. Observe that without CoT, the LLM produces incorrect answers to the question. With a CoT-enhanced prompt, the LLM systematically breaks the question into multiple steps and reasons through each step sequentially. By addressing each step incrementally, the LLM eventually arrives at the correct answer. Recent reasoning models, such as OpenAI O1 [@o1] and DeepSeek R1 [@guo2025deepseek], integrate CoT into their design. Notably, these models can perform CoT reasoning even without explicit prompting.

[IMAGE: Examples of different problem solving paradigms]

Although reasoning enhancement approaches such as CoT impressively improve LLM performance, they produce substantial additional overhead, specifically in the form of the increased number of tokens produced [@2022-CoT; @feng2023alphazero; @yao2024tree; @jin2024impact]. As shown in [\[fig:case_vanilla_CoT\]](#fig:case_vanilla_CoT){reference-type="ref+label" reference="fig:case_vanilla_CoT"}, the answer to prompt with CoT has notably higher token costs due to the detailed intermediate reasoning steps included in the output. Such high token costs can lead to significant expenses, including increased computational resource usage and longer running times during the LLM inference, ultimately resulting in significant additional monetary and energy costs.

This raises an important question: _"Is the reasoning process of current LLMs unnecessarily lengthy, and how can it be compressed?"_ @2024-CCoT demonstrate that LLM has the potential to follow a length constraint in the prompt. Building on this, we find that _including a **token budget** (see [1](#tab:prompt_construction){reference-type="ref+label" reference="tab:prompt_construction"}) in the prompts is a promising approach to compressing the CoT reasoning tokens. However, the choice of token budget plays a crucial role in the actual compression effectiveness._ For example, [\[fig:case_budget_CoT\]](#fig:case_budget_CoT){reference-type="ref+label" reference="fig:case_budget_CoT"} illustrates that including a reasonable token budget (e.g., 50 tokens in this case) in the instructions reduces the token cost in the chain-of-thought (CoT) process from 258 output tokens to 86 output tokens, while still enabling the LLM to arrive at the correct answer. However, when the token budget is set to a different smaller value (e.g., 10 tokens), the output token reduction is less effective, resulting in 157 output tokens---nearly twice as many as with a 50-token budget. In other words, when the token budget is relatively small, LLMs often fail to follow the given token budget. In such cases, the actual token usage significantly exceeds the given budget---even much larger than the token costs with larger token budgets. We refer to this phenomenon as the "Token Elasticity" in the CoT process with token budgeting. To address this, the optimal token budget for a specific LLM and a particular question can be searched by gradually reducing the budget specified in the prompt, identifying the smallest token budget that achieves both the correct answer and the lowest actual token cost.

Based on the above observations and analysis, we propose a token-budget-aware LLM reasoning framework that dynamically adjusts the number of reasoning tokens based on the reasoning complexity of each problem. We call our method [TALE]{.smallcaps} ([T]{.underline}oken-Budget-[A]{.underline}ware [L]{.underline}LM r[E]{.underline}asoning), which includes two implementations: token budget estimation and prompting ([TALE]{.smallcaps}-EP) and token budget awareness internalization via post-training ([TALE]{.smallcaps}-PT). [TALE]{.smallcaps}-EP estimates a reasonable token budget for each problem using zero-shot prompting and incorporates it into the reasoning process, while [TALE]{.smallcaps}-PT internalizes token-budget awareness through post-training, enabling the LLM to generate more token-efficient responses without explicit token constraints in the prompt. We discuss both implementations in [5](#sec:meth){reference-type="ref+label" reference="sec:meth"}. Experiment results show that [TALE]{.smallcaps} significantly reduces token costs in LLM chain-of-thought (CoT) reasoning while largely maintaining answer correctness. On average, [TALE]{.smallcaps}-EP achieves a 67% reduction in token usage while maintaining accuracy with less than a 3% decrease. [TALE]{.smallcaps}-PT cuts token usage by around 50% compared to Vanilla CoT and achieves competitive performance.

# Related Work {#sec:related_work}

**LLM Reasoning.** Reasoning in LLMs has seen substantial advancements through techniques that generate intermediate steps, enabling more accurate and effective performance across diverse domains [@wu2022ai; @yang2022seqzero; @zhou2022least; @sun2024visual; @o1]. Various LLM reasoning techniques are proposed to improve the LLM performance. @chen2024language formulates reasoning as sampling from a latent distribution and optimizing it via variational approaches. @ho2022large utilizes LLM as reasoning teachers, improving the reasoning abilities of smaller models through knowledge distillation. Among them, Chain-of-Thought (CoT) prompting has emerged as a key technique for improving LLM reasoning by breaking problems into intermediate steps, enabling better performance on multiple tasks [@2022-CoT; @lyu2023faithful; @li2023making; @feng2024towards]. Extensions of CoT include self-consistency, which aggregates multiple reasoning paths to improve robustness [@wang2022self], and Tree-of-Thoughts, which explores reasoning steps in a tree-like structure for more complex tasks [@2024-ToT]. Reflexion introduces iterative refinement, where the model critiques and updates its intermediate steps [@shinn2024reflexion].

**Token Cost of LLM.** Although the above methods enhance reasoning accuracy, they often increase token usages, posing challenges to efficiency [@wang2024reasoning; @chiang2024over; @bhargava2023s]. Consequently, it is important to mitigate token consumption while maintaining the model performance. To address this issue, @li2021addressing introduces a multi-hop processing technique designed to filter out irrelevant reasoning. While effective, this approach is limited to traditional neural networks, such as PALM [@bi2020palm], and lacks adaptability to large language models (LLMs). @zheng2024response aims to improve LLM inference speed by predicting response lengths and applying a scheduling algorithm to enhance efficiency. However, it is constrained to scheduling level, and it does not reduce the actual token costs. @hao2024training reduces token usage by substituting decoded text tokens with continuous latent tokens. However, its application is currently restricted to small-scale, early language models like GPT-2 [@radford2019language]. Additionally, it significantly impacts reasoning accuracy, resulting in over a 20% relative accuracy reduction on benchmarks such as GSM8K [@2021-GSM8K].

# Token Redundancy in LLM Reasoning {#sec:token_redundancy}

**Token Budget.** Previous research [@2024-CCoT] demonstrates that LLM has the potential to follow a length constraint in the prompt. [1](#tab:prompt_construction){reference-type="ref+label" reference="tab:prompt_construction"} shows the difference between the vanilla CoT and the CoT with token budget. For instance, by including a token budget (50 tokens) within the prompt, as illustrated in [\[fig:case_budget_CoT\]](#fig:case_budget_CoT){reference-type="ref+label" reference="fig:case_budget_CoT"}, the LLM adjusts the length of its output (86 output tokens), trying to align with the specified budget. This indicates that LLMs have a certain capability in following prompts with an explicit token budget.

::: {#tab:prompt_construction}
Prompt method Content

---

        1-2 Vanilla CoT       Let's think step by step:

1-2 CoT with Token Budget Let's think step by step and use less than [budget]{style="color: red"} tokens:
1-2 Example Let's think step by step and use less than [50]{style="color: red"} tokens:

: Illustrations of the vanilla CoT prompt and the token-budget-aware prompt.
:::

[]{#tab:prompt_construction label="tab:prompt_construction"}

**Token Redundancy Phenomenon.** We find that providing a reasonable token budget can significantly reduce the token cost during reasoning. As shown in [\[fig:case_budget_CoT\]](#fig:case_budget_CoT){reference-type="ref+label" reference="fig:case_budget_CoT"}, including a token budget in the instructions reduces the token cost in the chain-of-thought (CoT) process by several times, but the LLM still gets the correct answer. Our results in [2](#fig:motivation_elastic_observation){reference-type="ref+label" reference="fig:motivation_elastic_observation"} and [\[tab:main_eval\]](#tab:main_eval){reference-type="ref+label" reference="tab:main_eval"} also confirm there are a large number of redundant tokens in the reasoning process of the state-of-the-art LLMs.

**Causes of Token Redundancy in LLM Reasoning.** A possible explanation for this token redundancy is that during the post-training phase, such as the RLHF process [@ouyang2022training], annotators might favor more detailed responses from LLMs, marking them as preferred. As a result, the model learns to associate longer, more detailed responses with alignment to human preferences and tends to produce such outputs during reasoning. However, in many scenarios, we primarily need LLMs to provide the correct answer and make accurate decisions, rather than elaborate extensively with detailed explanations. This motivates the need to eliminate redundant tokens in the LLM reasoning process in many cases.

# Searching Optimal Token Budget {#sec:observation}

As demonstrated in [1](#fig:case_study_cot){reference-type="ref+label" reference="fig:case_study_cot"}, different token budgets have different effects. Therefore, it is natural to investigate the following question: "_How to search the optimal token budget for a specific question and a particular LLM?_"

[IMAGE: Token elasticity phenomenon]

**Vanilla Method for Optimal Budget Search.** An intuitive method is finding the minimal needed tokens as the budget, ensuring that the LLM can still produce correct and accurate responses within this constraint.

::: {#tab:intuitive_monotonicity}
**Budget($*\beta^*$)** $2^{-2}$ $2^{-1}$ $1$ $2^{1}$ $2^{2}$

---

**Prediction** False False True True True

: An intuitive monotonic example. $\beta^*$ is the searched optimal budget. The budget row displays scaled budgets ranging from $2^{-2}$ to $2^{2} \cdot \beta^*$.
:::

[]{#tab:intuitive_monotonicity label="tab:intuitive_monotonicity"}

Before initiating the search process, we first apply the vanilla CoT to generate an answer for each question, as illustrated in [\[fig:case_vanilla_CoT\]](#fig:case_vanilla_CoT){reference-type="ref+label" reference="fig:case_vanilla_CoT"}. The number of tokens in the resulting answer is then calculated and designated as the right boundary for search, denoted by $right$. The function `isFeasible` is used to determine the feasibility of a budget. A budget is considered feasible here if the CoT prompt with that budget preserves the correctness of the answer. [\[alg:binary_search\]](#alg:binary_search){reference-type="ref+label" reference="alg:binary_search"} showcases the details. Given the feasibility function, large language model $\mathcal{M}$, question $\vx$ and label $y$ as the input, [\[alg:binary_search\]](#alg:binary_search){reference-type="ref+label" reference="alg:binary_search"} first calculates the right boundary of search (line 2). With $0$ as the left boundary, the current possible budget $\beta$ is computed as the midpoint of $0$ and $right$ (line 3). We use $\beta_0$ to record the previously searched budget (line 4). While the current $\beta$ is feasible, the algorithm updates $\beta$ by recalculating the midpoint (line 7) and adjusts the search bounds accordingly to narrow the range (line 9). Once the loop ends, the final budget $\beta$ is returned as the searched result (line 12). [\[alg:binary_search\]](#alg:binary_search){reference-type="ref+label" reference="alg:binary_search"} is designed to find the minimal budget efficiently. However, we observe that the minimal budget required to produce a correct answer is not necessarily the optimal budget. When the budget is unreasonably small, the actual token cost often exceeds that of cases where a larger budget is used.

[IMAGE: The effects of optimal searched budget]

**Observation of Token Elasticity.** During our minimal budget search process, we observe a "_token elasticity_" phenomenon as we approach the minimal budget. Specifically, as [\[alg:binary_search\]](#alg:binary_search){reference-type="ref+label" reference="alg:binary_search"} progresses, we aim to identify the minimal budget that still ensures the answer's correctness. However, we find that if the budget is reduced beyond a certain range, the token cost increases, indicating that further reductions in the budget lead to increasing token consumption. [2](#fig:motivation_elastic_observation){reference-type="ref+label" reference="fig:motivation_elastic_observation"} showcases the evidence. The x-axis represents the iterations of the budget binary search, with the budget values decreasing progressively. The y-axis in [\[fig:gpt4omini_token_cost\]](#fig:gpt4omini_token_cost){reference-type="ref+label" reference="fig:gpt4omini_token_cost"} and [\[fig:yilightning_token_cost\]](#fig:yilightning_token_cost){reference-type="ref+label" reference="fig:yilightning_token_cost"} show the corresponding token costs at each budget search iteration. [\[fig:one-budget\]](#fig:one-budget){reference-type="ref+label" reference="fig:one-budget"} also shows an example. As observed, when a small token budget (e.g., 10 tokens) is used, the real token cost is significantly higher compared to scenarios where a reasonable token budget is allocated (i.e., [\[fig:case_budget_CoT\]](#fig:case_budget_CoT){reference-type="ref+label" reference="fig:case_budget_CoT"}).

**Token Elasticity based Optimal Budget Search.** The token elasticity observation shows that while a minimal budget may keep the correctness of the answer, it does not necessarily minimize the token cost. [\[fig:one-budget\]](#fig:one-budget){reference-type="ref+label" reference="fig:one-budget"} and [\[fig:case_budget_CoT\]](#fig:case_budget_CoT){reference-type="ref+label" reference="fig:case_budget_CoT"} illustrate an intuitive example. To address this, we enhance [\[alg:binary_search\]](#alg:binary_search){reference-type="ref+label" reference="alg:binary_search"} by incorporating a greedy search strategy aimed at finding the optimal budget that simultaneously minimizes token cost and preserves answer correctness. Specifically, we introduce an additional constraint to the `isFeasible` condition. Beyond ensuring correctness, the updated budget must result in a lower token cost compared to the previously searched budget. [\[alg:greedy_feasibility\]](#alg:greedy_feasibility){reference-type="ref+label" reference="alg:greedy_feasibility"} outlines the feasibility function employed during the search process. Initially, the actual token cost is computed for both the current and previously evaluated budgets (line 2). Next, feasibility is assessed based on two criteria: the answer correctness and greedy token reduction (line 3). The search process is terminated if either condition fails.

# Methodology {#sec:meth}

## Overview

Based on the above analysis, we designed our method [TALE]{.smallcaps} for token-budget-aware reasoning in LLMs. Two solutions, i.e., estimation&prompting ([TALE]{.smallcaps}-EP, see [4](#fig:framework){reference-type="ref+label" reference="fig:framework"}) and post-training ([TALE]{.smallcaps}-PT, see [6](#fig:post_training){reference-type="ref+label" reference="fig:post_training"}), are proposed.

[IMAGE: The workflow of TALE-EP]

[IMAGE: The prompt for zero-shot budget estimation]

## Estimation and Prompting ([TALE]{.smallcaps}-EP) {#subsec:tale_estimation_prompting}

Our observations on token elasticity ([4](#sec:observation){reference-type="ref+label" reference="sec:observation"}) indicate that only a well-chosen budget within a reasonable range can effectively minimize token costs while preserving LLM performance. The optimal budget, found using [\[alg:binary_search\]](#alg:binary_search){reference-type="ref+label" reference="alg:binary_search"} and [\[alg:greedy_feasibility\]](#alg:greedy_feasibility){reference-type="ref+label" reference="alg:greedy_feasibility"}, lies within this range and achieves a satisfying trade-off between efficiency and performance. Building on this insight, we introduce a token budget aware reasoning method by zero-shot-based token budget estimation and prompting the reasoning LLM. [TALE]{.smallcaps}-EP leverages the reasoning capabilities of the LLM as an estimator. [4](#fig:framework){reference-type="ref+label" reference="fig:framework"} provides an overview of [TALE]{.smallcaps}-EP's workflow. The goal of [TALE]{.smallcaps}-EP is to construct a token-budget-aware prompt that maintains performance comparable to vanilla CoT while reducing token costs. To achieve this balance, [TALE]{.smallcaps}-EP follows a two-phase approach: budget estimation and prompt construction. Given a question, [TALE]{.smallcaps}-EP first estimates a reasonable token budget that closely aligns with the optimal searched budget. By default, we use the reasoning LLM itself with a zero-shot estimation prompt as the budget estimator. [5](#fig:zero_prompt){reference-type="ref+label" reference="fig:zero_prompt"} demonstrates the budget estimation prompt, . Using this estimate, it then crafts a token-budget-aware prompt and feeds it into the LLM to generate the final answer. [\[fig:intuitive_example_workflow_ep\]](#fig:intuitive_example_workflow_ep){reference-type="ref+label" reference="fig:intuitive_example_workflow_ep"} illustrates this process with a concrete example. The key intuition behind [TALE]{.smallcaps}-EP is inspired by human-like thinking. When solving a mathematical problem, a person may take time to compute the exact answer but can quickly estimate the effort required to solve it. For instance, when comparing a primary school arithmetic question to a college-level calculus problem, one may not immediately provide the solutions but can easily infer that the former takes only seconds while the latter requires significantly more time. [9.2](#subsec:rq2_budget_estimation){reference-type="ref+label" reference="subsec:rq2_budget_estimation"} evaluates the effectiveness of our budget estimation approach, demonstrating that the budgets estimated by advanced LLMs (e.g., GPT-4o-mini) are generally close to the optimal searched budget and deliver competitive performance.

## [TALE]{.smallcaps} Post-Training ([TALE]{.smallcaps}-PT) {#subsec:tale_post_training}

Another approach for obtaining an LLM with token-budget awareness is post-training it to incorporate this awareness into its inference process, enabling it to generate more token-efficient reasoning responses. Specifically, we post-train the LLM $\mathcal{M}_{\theta}$ to produce answers that adhere to the token budget. This process is divided into two key stages: target output generation and LLM post-training.

[IMAGE: The workflow of TALE-PT]

**Target Output Generation.** In the target output generation stage, we craft the target output $y_i$ by prompting $\mathcal{M}_{\theta}$ with a Chain-of-Thought (CoT) prompt that incorporates our searched optimal token budget. The prompt is formatted as follows:

::: center
`''Let's think step by step and use less than `$\beta_{i}^*$` tokens:''`
:::

where $\beta_{i}^*$ is the searched optimal budget for the given question $\vx_i$ (see search process in [\[alg:binary_search\]](#alg:binary_search){reference-type="ref+label" reference="alg:binary*search"} and [\[alg:greedy_feasibility\]](#alg:greedy_feasibility){reference-type="ref+label" reference="alg:greedy_feasibility"}). [\[fig:case_budget_CoT\]](#fig:case_budget_CoT){reference-type="ref+label" reference="fig:case_budget_CoT"} illustrates an example. The resulting LLM output, constrained by the token budget specified in the prompt, is taken as the crafted target output $y_i$. This target output not only leads to the correct answer but also has minimal actual output token cost among our token elasticity-based search process, as described in [4](#sec:observation){reference-type="ref+label" reference="sec:observation"}. In the LLM post-training stage, we train the LLM $\mathcal{M}*{\theta}$ using the crafted target outputs from the first stage. We introduce two ways to conduct the token-budget awareness internalization during post-training, i.e., SFT-based and DPO-based method. Details of the hype parameters are in [9.3](#subsec:details_implementation){reference-type="ref+label" reference="subsec:details_implementation"}.

**SFT-based Internalization.** To inject token-budget awareness into $\mathcal{M}_{\theta}$, we perform supervised fine-tuning with these target outputs. We post-train $\mathcal{M}_{\theta}$ to generate token-efficient outputs by minimizing the cross-entropy loss between the model's predictions and the target outputs. Given an input $\vx$ and a target output $y$ from the first stage (which reflects token-budget awareness), the cross-entropy loss is defined as: $$\begin{equation*}
    \mathcal{L}_{\text{CE}}(\theta) = - \frac{1}{N} \sum_{i=1}^{N} \sum_{t=1}^{T_i} \log \mathbb{P}(y_{i,t} | y_{i,<t}, \vx_i),
\end{equation*}$$ where $T_i$ means the length of the target sequence $y_i$ for the $i$-th training example, $y_{i,t}$ the target token at position $t$ of $y_i$, $y_{i,<t}$ means the sequence of tokens preceding the current token $y_{i,t}$, representing the context up to time step $t$ for the $i$-th sample. $\mathbb{P}(y_{i,t} | y_{i,<t}, x_i)$ represents the conditional probability predicted by the model $\mathcal{M}_{\theta}$ for the token $y_{i,t}$, given the input $\vx_i$ and the preceding tokens $y_{i,<t}$. The loss is based on the next token prediction. The goal is to adjust the model parameters $\theta$ such that it produces concise and accurate responses that adhere to the token budget constraint. This is achieved through gradient descent, forcing the model to internalize the compact reasoning patterns from the token-efficient target outputs.

**DPO-based Internalization.** Another way to incentivize $\mathcal{M}_{\theta}$ to learn the token-budget preference is applying the DPO algorithm [@2023-DPO] to post-train the model. DPO directly refines the policy through a classification objective, aligning the model's behavior with the desired preferences. The goal of DPO here is to refine $\mathcal{M}_{\theta}$ so it can accurately solve a given problem $\vx$ while adhering to an internalized token budget. We use the target outputs $y_i$ from the searched optimal budget as positive samples, while outputs $y_i'$ generated with the vanilla CoT prompt serve as negative samples. These positive-negative pairs are then used to create the pairwise preference data for DPO training. Given the crafted dataset $\mathcal{D}$ = $\{(\vx_i, y_i, y_i')\}_{i=1}^{N}$, the objective is to maximize the likelihood that the model ranks the positive samples higher than the negative ones. Formally, we aim to optimize the following objective: $$\begin{equation*}
\begin{aligned}
\mathcal{L}_{\mathrm{DPO}}(\theta)
&= -\frac{1}{N} \sum_{i=1}^{N} \log P_{\theta}(y_i \succ y_i'), \quad where\\
P_{\theta}(y_i \succ y_i')&=
    \frac{\exp\bigl(s(y_i, \mathbf{x}_i)\bigr)}
         {\exp\bigl(s(y_i, \mathbf{x}_i)\bigr)
          + \exp\bigl(s(y_i', \mathbf{x}_i)\bigr)}.
\end{aligned}
\end{equation*}$$

$P_{\theta}(y_i\succ y_i')$ is the preference function. Here, $s(y_i, \vx_i)$ is defined as $\sum_{t=1}^{T_i}\log \mathbb{P}(y_{i,t} | y_{i,<t}, \vx_i)$, and it represents the log-probability of the model generating $y_i$ for input $\vx_i$, which serves as the preference score assigned to $y_i$. This score measures how strongly the model favors that output. The objective ensures that the model prioritizes concise and token-efficient outputs while maintaining high-quality reasoning and correctness. During training, the LLM is encouraged to internalize the token budget constraint and adopt a more compact reasoning process guided by the target outputs generated in the first stage. This two-stage process effectively trains the LLM to produce concise yet accurate responses, striking a balance between reasoning quality and token efficiency during inference. More details are in [9.3](#subsec:details_implementation){reference-type="ref+label" reference="subsec:details_implementation"}.

# Evaluation {#sec:eval}

In this section, we provide the experiment results to evaluate the effectiveness of two versions of [TALE]{.smallcaps}, [TALE]{.smallcaps}-EP and [TALE]{.smallcaps}-PT.

## Experiment Setup {#subsec:experiment_setup}

**Datasets.** To evaluate the LLM performance, three most challenging mathematical datasets are taken into consideration: GSM8K [@2021-GSM8K], GSM8K-Zero [@chiang2024over], and MathBench [@2024-mathbench]. GSM8K-Zero, derived from the GSM8K dataset, specifically targets the analysis of over-reasoning and redundancy in LLM-generated outputs. In short, GSM8K-Zero is designed so that the answers are embedded within the questions themselves. LLMs can easily generate correct responses without complicated additional reasoning or redundant calculations.

**Models.** We conduct experiments on five state-of-the-art LLMs (i.e., GPT-4o [@gpt4o-2024], GPT-4o-mini [@gpt4o-mini2024], Yi-lightning [@2024-yi-lightning], o3-mini [@o3-mini]), and Lllama-3.1-8B-Instruct [@dubey2024llama].

**Metrics.** The target of [TALE]{.smallcaps} is to balance the LLM correctness performance and extra redundant token costs. Specifically, [TALE]{.smallcaps} seeks to minimize _Number of Output Tokens_ while maintaining comparable _Accuracy (Acc)_ simultaneously.

_Accuracy (Acc)._ This metric is calculated as the following: $Accuracy = \frac{1}{N}\sum_{i=1}^{N}{\mathbb{I}\{\mathcal{M}(\vx_i) = y_i\}}$, where $(\vx_i, y_i) \in \mathcal{X}$. $\vx_i$ is the math question from dataset $\mathcal{X}$ and $y_i$ the ground truth answer. $\mathcal{M}(\cdot)$ returns the answer for a given question. $\mathbb{I}\{\cdot\}$ represents an indicator function. This function evaluates whether the inside given condition holds. Specifically, it returns **1** if the condition is true and **0** if the condition is false. For a better evaluation, we format the LLM output by crafting an elaborate instruction detailed in [8](#fig:format_prompt){reference-type="ref+label" reference="fig:format_prompt"}.

_Number of Output Tokens._ We evaluate the token costs by calculating the average output token consumption for each specific task. The output token costs are measured as follows: $\textit{Number of Output Tokens} = \frac{1}{N}\sum_{i=1}^{N}{\mathbb{T}(\mathcal{M}(\vx_i))}$, where $\vx_i$ represents the given question, and $\mathbb{T}$ is a function that measures the number of tokens. Intuitively, the more output tokens, the higher the costs incurred by $\mathcal{M}$. To evaluate costs more precisely, we calculate the average expense per sample. The total token expense includes both input and output tokens used during the query process.

## Effectiveness of [TALE]{.smallcaps}-EP {#subsec:rq1_effectiveness}

[\[tab:main_eval\]](#tab:main_eval){reference-type="ref+label" reference="tab:main_eval"} compares [TALE]{.smallcaps}-EP with other prompt engineering methods across seven datasets, evaluating accuracy, output tokens, and expenses. Effective prompts should maximize accuracy while minimizing token usage and cost. Direct Answering is the most cost-efficient (14.57 tokens, 25.37 expense) but with low accuracy (52.31%). Vanilla CoT achieves the highest accuracy (83.75%) but at a high cost (461.25 tokens, 289.78 expense). [TALE]{.smallcaps}-EP balances performance and efficiency, achieving 81.03% accuracy while reducing token usage to 32% and expenses to 41% of Vanilla CoT. On GSM8K, it even surpasses Vanilla CoT with 84.46% accuracy. Note that expense is not directly proportional to output tokens because it also accounts for input and cached tokens. [TALE]{.smallcaps}-EP reduces token costs by 68.64% on average, offering a scalable, cost-effective solution for budget-constrained reasoning tasks.

To further evaluate the generalization of [TALE]{.smallcaps}-EP across different LLMs. We conduct experiments across Yi-lightning, GPT-4o-mini, GPT-4o and o3-mini on MathBench-College. [\[tab:generalization\]](#tab:generalization){reference-type="ref+label" reference="tab:generalization"} illustrates the results, showing [TALE]{.smallcaps}-EP's ability to reduce output tokens and expenses while maintaining competitive accuracy significantly. [TALE]{.smallcaps}-EP achieves substantial token savings, reducing output tokens by 64.63% on average, compared to Vanilla CoT. Expense reductions are equally notable, with costs decreasing by 45.30% on average. Despite these cost savings, [TALE]{.smallcaps}-EP maintains strong accuracy, achieving 76.67% on Yi-lightning, 70.00% on GPT-4o-mini, and 80.00% on GPT-4o, comparable to Vanilla CoT. These results highlight [TALE]{.smallcaps}-EP's effectiveness in balancing cost efficiency and reasoning performance across diverse LLM architectures. The observed accuracy drop is most significant for GPT-4o-mini. This could be attributed to its smaller number of parameters, which makes it more challenging to answer correctly within a limited response reasoning length.

## Effectiveness of [TALE]{.smallcaps}-PT {#subsec:effective_tale_pt}

[\[tab:internalization\]](#tab:internalization){reference-type="ref+label" reference="tab:internalization"} compares [TALE]{.smallcaps}-PT methods with Vanilla CoT and Direct Answering on GSM8K and GSM8K-Zero using Llama-3.1-8B-Instruct. For GSM8K, Direct Answering demonstrates the lowest token usage (38.54) but at the cost of significantly reduced accuracy (21.00%). In contrast, Vanilla CoT achieves much higher accuracy (77.56%) but incurs a significant increase in token cost (241.51). Note that on GSM8K-Zero, the accuracy of Vanilla CoT drops below Direct Answering. This drop can be attributed to overthinking, as GSM8K-Zero is simpler, with answers often implied directly within the question. In such cases, a long reasoning process can introduce unnecessary complexity, leading to reduced accuracy. Among the [TALE]{.smallcaps}-PT methods, [TALE]{.smallcaps}-PT-SFT achieves the best accuracy (78.57%, 78.43%) with reduced tokens, while [TALE]{.smallcaps}-PT-DPO balances accuracy (74.11%, 78.41%) and token efficiency, cutting token consumption by over 50% on GSM8K-Zero compared to Vanilla CoT.

# Conclusion

[]{#sec:conclusion label="sec:conclusion"} In this paper, we introduce [TALE]{.smallcaps}, a framework that reduces token redundancy in Chain-of-Thought (CoT) reasoning by incorporating token budget awareness. [TALE]{.smallcaps} dynamically adjusts the number of reasoning tokens based on the reasoning complexity of each problem, balancing token efficiency and answer correctness. Experiments show that [TALE]{.smallcaps} reduces output token usage and expense significantly with acceptable accuracy loss, outperforming Vanilla CoT in cost-effectiveness while generalizing well across various LLMs.

# Limitations {#sec:limitations}

The experiments of our proposed token-budget-aware reasoning framework currently focus on LLMs that process only text as input and output. While the results demonstrate significant improvements in efficiency and cost reduction, it does not account for models that have multimodal output content. Such as the models generate interleaved images and text as output. In future work, we will extend token-budget awareness to such LLMs with multimodal output by introducing modality-specific budget constraints and designing adaptive strategies to optimize token efficiency for different modality types, such as images and videos.

# Appendix {#sec:appendix}

[IMAGE: An intuitive example to illustrate the workflow of TALE-EP]

[IMAGE: The instruction prompt used to format the LLM output on multiple-choice questions]

## Definition of Ideal Budget Range {#subsec:problem_formulation}

**Ideal Budget Range.** Based on the observation of token elasticity, a token cost bottom range exists during searching for the optimal budget. In this range, the token costs approach the token cost lowest bound. Before or after the range, the token cost will increase. We define such a bottom range as "ideal budget range". It's worth noting that the budget continuously degrades during the search. Only the token cost rebounds. That's why we refer to this observation as token elasticity. To summarize, ideal budget range is an range that minimizes actual token consumption. Let $\boldsymbol{\beta} = \{\beta_1, \beta_2, ..., \beta_N\}$ denote all possible budgets that can maintain answer correctness. A rolling window $W \in \boldsymbol{\beta}$ is applied iteratively over $\boldsymbol{\beta}$. Let $k$ represent the range size, which is adaptively determined during our evaluation as $\frac{N}{3}$, where $N$ is the total number of possible budgets. A budget range is defined as: $$\begin{equation*}
\begin{aligned}
    W_k(i) = \{\boldsymbol{\beta}_j \mid i \leq j \leq i + k - 1\},
    \\
    1 \leq i \leq |\boldsymbol{\beta}| - k + 1
\end{aligned}
\end{equation*}$$ The ideal budget range $W^*$ is defined as: $$\begin{equation}
   W_k^* = \arg \min_i \left( \sum_{\beta_j \in W_k(i)} \mathbb{T}(\beta_j) \right),
    \label{eq:ideal_budget_interval}
\end{equation}$$ where $\mathbb{T}$ denote the actual token consumption for a given budget $\beta \in \boldsymbol{\beta}$. We aim to estimate a budget located in the ideal budget ranges without any search process. In that case, [TALE]{.smallcaps} obtains the ideal budget within acceptable sacrifice.

## Effectiveness of Budget Estimation. {#subsec:rq2_budget_estimation}

In this RQ, we evaluate the effectiveness of the budget estimation performance. An ideal estimated budget should be located around the optimal searched budget and in the bottom area of [2](#fig:motivation_elastic_observation){reference-type="ref+label" reference="fig:motivation*elastic_observation"}. We further define such an area as the ideal budget range and give the formalized definition in [9.1](#subsec:problem_formulation){reference-type="ref+label" reference="subsec:problem_formulation"}. A good budget should be located in the ideal budget range. Two metrics are taken into consideration: *in-range accuracy* and *out-of-range distance*. In-range accuracy determines whether the predicted budget $\hat{\beta}$ falls within the ideal budget range $W^{\*}*{k}$. Mathematically, it can be expressed as: $$\begin{equation*}
\mathbb{I}\{\hat{\beta} \in W_k^*\} =
\begin{cases}
1, & \text{if } \hat{\beta} \in W*k^*, \\
0, & \text{otherwise}.
\end{cases}
\end{equation*}$$ Out-of-range distance quantifies the distance between $\hat{\beta}$ and $W_k^*$ if the predicted budget $\beta^*$ falls outside the ideal budget range $W_k^*$. Let $dist(\hat{\beta}, W_k^*)$ represent the distance, defined as: $$\begin{equation*}
\text{dist}(\hat{\beta}, W_k^*) =
\begin{cases}
0, & \text{if } \hat{\beta} \in W_k^\*, \\
\min\limits*{\substack{\hat{\beta} \in W_k^_}} |\hat{\beta} - \beta|, & \text{if } \hat{\beta} \notin W_k^_.
\end{cases}
\end{equation\*}$$ Intuitively, a higher in-range accuracy and a lower out-range distance indicate a better estimated budget. During our evaluation, the in-range accuracy is 60.61%, and the out-of-range distance is 109.64. It indicates that more than two-thirds of estimated budgets are located in the ideal range. For those out-of-range samples, they have an offset of 109.64 tokens on average. [9](#fig:successful_fail_case_EP){reference-type="ref+label" reference="fig:successful_fail_case_EP"} illustrates the successful and failed estimated cases intuitively.

## Details of [TALE]{.smallcaps}'s Implementation {#subsec:details_implementation}

In this section, we introduce the hyper-parameters used for [TALE]{.smallcaps}-EP and [TALE]{.smallcaps}-PT.

### [TALE]{.smallcaps}-EP. {#tale-ep. .unnumbered}

[TALE]{.smallcaps}-EP uses a zero-shot mechanism to estimate the token budget and then prompts the LLM. The instruction prompts used during this process are shown in [7](#fig:intuitive_example_workflow){reference-type="ref+label" reference="fig:intuitive_example_workflow"}. To ensure output consistency, we set the temperature to 0.1 and limit the model to a single reasoning path. Additionally, the random seed is fixed at 1024.

### [TALE]{.smallcaps}-PT. {#tale-pt. .unnumbered}

[TALE]{.smallcaps}-PT includes two implementations: SFT and DPO. For parameter efficiency, both implementations adopt LoRA [@hu2021lora] for post-training, with rank set to 8 and lora alpha set to 32. For [TALE]{.smallcaps}-PT-SFT, we train for 3 epochs with a batch size of 16, a learning rate of 1e-4, and a weight decay of 0.01. For [TALE]{.smallcaps}-PT-DPO, we train for 2 epochs with a batch size of 16, a learning rate of 3e-5, and a weight decay of 0.001.

[IMAGE: Successful and failed estimated cases]

## Comparison of TALE-EP and TALE-PT. {#subsec:TALE-EP-TALE-PT}

::: {#tab:comparison_tale-ep_tale-pt}
+---------------+---------+-----------------+
| Metrics | TALE-EP | TALE-PT |
+:=============:+:=======:+:======:+:======:+
| 3-4 | | SFT | DPO |
+---------------+---------+--------+--------+
| ACC | 71.82 | 78.57 | 74.11 |
+---------------+---------+--------+--------+
| Output Tokens | 112.21 | 139.63 | 149.93 |
+---------------+---------+--------+--------+

: Comparison of TALE-EP and TALE-PT.
:::

[]{#tab:comparison_tale-ep_tale-pt label="tab:comparison_tale-ep_tale-pt"}

## Applicability of [TALE]{.smallcaps} on More Tasks. {#subsec:generalization_task}

::: {#tab:more_tasks}
+-------------+-----------------------+------------------------+
| Tasks | TALE-EP | Vanilla CoT |
+:============+:=====:+:=============:+:======:+:=============:+
| 2-3 (lr)4-5 | BLEU | Output Tokens | BLEU | Output Tokens |
+-------------+-------+---------------+--------+---------------+
| CS | 0.07 | 44.39 | 0.2 | 134.05 |
+-------------+-------+---------------+--------+---------------+
| ERG | 0.005 | 60.34 | 0.006 | 175.37 |
+-------------+-------+---------------+--------+---------------+
| CG | 0.24 | 171.08 | 0.267 | 461.77 |
+-------------+-------+---------------+--------+---------------+

: Generalization of [TALE]{.smallcaps} on more tasks. Three popular LLM generative tasks, Code Summarization [@husain2019codesearchnet](CS), Empathetic Response Generation [@rashkin2019towards](ERG), Code Generation [@austin2021program](CG), are taken into consideration. BLEU is taken as the metric to evaluate the performance. BLEU$\uparrow$. Output Tokens$\uparrow$.
:::

[]{#tab:more_tasks label="tab:more_tasks"}

## Formalizing the Budget Search. {#subsec:formalizing_budget_search}

## Efficiency of TALE-EP. {#subsec:efficiency_tale_ep}

## Effectiveness of Larger Token Budget. {#subsec:larger_budget}

::: {#tab:assumption_evidence}
**Budget($*\beta^*$)** $2^{-5}$ $2^{-4}$ $2^{-2}$ $2^{0}$

---

**ACC** 69.23 75.82 75.82 76.92
**Output Tokens** 222.69 222.42 244.61 653.53

: The empirical evidence for "implicit monotonicity assumption". $\bar{\beta}$ is the budget upper bound, which is the token cost of vanilla CoT. The budget row displays scaled budgets ranging from $2^{-2}$ to $2^{2} \cdot \beta^*$.
:::

[]{#tab:assumption_evidence label="tab:assumption_evidence"}

## Empirical Evidence for the "Implicit Monotonicity Assumption". {#subsec:assumption_evidence}

[^1]: Also available at <https://www.gitlink.org.cn/txhan/TALE>
