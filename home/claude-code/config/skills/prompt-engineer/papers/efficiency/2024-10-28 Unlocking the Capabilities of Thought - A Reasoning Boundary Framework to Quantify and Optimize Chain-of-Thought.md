# Abstract {#abstract .unnumbered}

Chain-of-Thought (CoT) reasoning has emerged as a promising approach for enhancing the performance of large language models (LLMs) on complex reasoning tasks. Recently, a series of studies attempt to explain the mechanisms underlying CoT, aiming to deepen the understanding of its efficacy. Nevertheless, the existing research faces two major challenges: (1) _a lack of quantitative metrics to assess CoT capabilities_ and (2) _a dearth of guidance on optimizing CoT performance_. Motivated by this, in this work, we introduce a novel reasoning boundary framework (`RBF`) to address these challenges. To solve the lack of quantification, we first define a reasoning boundary (RB) to quantify the upper-bound of CoT and establish a combination law for RB, enabling a practical quantitative approach applicable to various real-world CoT tasks. To address the lack of optimization, we propose three categories of RBs. We further optimize these categories with combination laws focused on RB promotion and reasoning path optimization for CoT improvement. Through extensive experiments on 27 models and 5 tasks, the study validates the existence and rationality of the proposed framework. Furthermore, it explains the effectiveness of 10 CoT strategies and guides optimization from two perspectives. We hope this work can provide a comprehensive understanding of the boundaries and optimization strategies for reasoning in LLMs. Our code and data are available at <https://github.com/LightChen233/reasoning-boundary>.

# Introduction

In recent years, Large Language Models (LLMs) have demonstrated increasing capabilities and applications across various tasks [@zhao2023survey; @chang2023survey; @pan2023preliminary; @qin2024large]. Notably, advanced LLMs, such as GPT [@brown2020language; @openai2022gpt35; @openai2023gpt4], PaLM [@anil2023palm] and LlaMa [@touvron2023llama; @touvron2023llama2; @touvron2023llama3] series have demonstrated emergent capabilities, particularly like Chain-of-Thought (CoT) [@nye2022show; @wei2022chain]. This methodology enables models to verbalize step-by-step reasoning, thereby enhancing prediction accuracy by basing decisions on the logical rationale [@wei2022chain; @kojima2022large; @hu2023tree; @qin2023cross; @zhuang2023through; @chen-etal-2024-m3cot].

Recently, some research in the literature has begun to investigate the mechanism of CoT to enhance the understanding of its operational nature. To this end, @madaan-etal-2023-makes and @wang-etal-2023-towards first give a qualitative boundary conclusion through a large number of experiments on the natural language planning capability: The CoT is limited by the reasoning logic in the context demonstrations. @bi2024program investigate these boundaries on the code planning capability, by training LLMs on CoT samples of varying difficulties. It demonstrates LLMs are unable to learn or effectively manage tasks that exceed a certain complexity upper-bound. To delve deeper into potential constraints of CoT, @feng2024towards develop a theoretical framework on the single-step calculation capability, suggesting that there is an upper-bound of model performance dependent on the length of input in single-step reasoning processes. Although existing research has made some progress, where the boundaries of CoT lie and how these boundaries affect the performance of CoT are still unresolved questions. Specifically, the existing work still faces two major challenges:

- **Lacking quantification metrics for CoT:** Current research primarily relies on qualitative assessments of CoT performance, which leads to the absence of quantitative metrics. It hinders the ability to objectively compare different CoT approaches and establish a definitive upper-bound for CoT capabilities.

- **Lacking optimization guidance for CoT:** While current research prioritizes understanding the mechanisms underlying CoT reasoning, there is a dearth of guidance on optimizing CoT performance. This gap hinders the transformation of CoT research into actionable strategies for enhancing model capabilities.

Motivated by this, in this work, we introduce a reasoning boundary framework (`RBF`) to thoroughly examine and optimize the boundaries of current LLMs. Specifically, to address the quantification challenge, we propose a new concept, named reasoning boundary (RB) to quantify the upper-bound on task-specific reasoning complexity within a model. Furthermore, to explore more practical scenarios, we present the combination law of RBs to generalize the RB for quantification in more real and complex scenarios. To address the CoT optimization challenge, we propose and analyze three reasoning boundary intervals, guiding optimization through improved RB and optimized reasoning paths based on the combination law, which achieves state-of-the-art performance in our proposed benchmark. We extensively validate the efficacy of our framework across 27 models and 5 tasks: arithmetic computing, mathematical reasoning, multi-hop question answering, and multilingual mathematical reasoning.

Our main contributions are as follows:

- To the best of our knowledge, this is the first work to propose a reasoning boundary framework (`RBF`) to quantify the upper-bound of CoT. Furthermore, we establish the combination law of RB as the weighted harmonic mean of fundamental RBs to address practical CoT tasks.

- To solve the lack of CoT optimization, we define three categories of RBs. Based on the combination law and the nature of these RBs, we effectively improve the existing CoT strategies by RB promotion and reasoning path optimization.

- We validate the existence and rationality of our framework on 27 models and 5 CoT tasks. Furthermore, we explain the optimal performance from two optimization perspectives in numerous CoT strategies. We consider both optimal perspectives and propose a minimum acceptable reasoning path (MARP) prompting to achieve state-of-the-art performance.

# Quantification Methodology

<figure id="fig:intro" data-latex-placement="t">
<embed src="figure/intro.pdf" style="width:99.0%" />
<figcaption>Overview of the introduced concepts. </figcaption>
</figure>

## Reasoning Boundary

[]{#sec:definition label="sec:definition"} In order to quantify the capacity for complex reasoning in LLMs, we introduce an upper-bound concept termed reasoning boundary (RB), which formally defines the degree of ease that an LLM can handle within a specific reasoning process. In simpler terms, as shown in Figure [1](#fig:intro){reference-type="ref" reference="fig:intro"} (a), RB reflects the limit beyond which a model's accuracy significantly degrades. Mathematically, RB is defined for a model $m$ and a task $t$ as the maximum of problem difficulty $d$ at which the model's accuracy reaches a predefined threshold $K_1$: $$\begin{equation}
    \label{eq:max_available}
\mathcal{B}_{Acc=K_1}(t|m) = \sup_{d} \{ d | Acc(t|d, m) = K_1 \},
\end{equation}$$ where $Acc(t|d, m)$ represents the accuracy of the model's accuracy on task $t$ with difficulty $d$. Difficulty can be measured by factors like the number of reasoning steps or computational complexity. For brevity, we denote RB as $\mathcal{B}(t|m)$ in subsequent sections.

::: takeaways
**Conclusion:** The reasoning boundary for a model is defined by its ability to achieve a specific accuracy for a given task difficulty.
:::

## Combination Law of Reasoning Boundary

In practical scenarios, models often require the integration of multiple capabilities to address a single task effectively. To quantify how a large language model can be boosted by the cooperation of multiple capabilities through the CoT mechanism, we introduce the "_Combination Law of RB_", giving a concrete formula of the upper-bound of the CoT. The law estimates the unified reasoning boundary $\mathcal{B}_{\text{Acc}=K_1}(t_1, t_2, \dots, t_n|m)$ for $n$ tasks within a model $m$, which is formulated as: $$\begin{equation}
    \mathcal{B}_{\text{Acc}=K_1}(t_1, t_2, \dots, t_n|m) \approx \frac{1}{(n-1)\sum^{n}_{i=1}\frac{N_{i}}{\mathcal{B}_{\text{Acc}=K_1}(t_i|m)-b_i }}, \label{eq:combine-law}
\end{equation}$$ where $\mathcal{B}_{\text{Acc}=K_1}(t_i|m)$ denotes the reasoning boundary of model $m$ for task $t_i$. $N_{i}$, and $b_i$ are scaling factors, which are only affected by the related task. As shown in Figure [1](#fig:intro){reference-type="ref" reference="fig:intro"} (b), Equation [\[eq:combine-law\]](#eq:combine-law){reference-type="eqref" reference="eq:combine-law"} provides a mathematical formula to estimate the combined RBs from the independent ones, enabling deeper insights into model behavior for intricate tasks. See Appendix [9.1](#append:proof){reference-type="ref" reference="append:proof"} for detailed mathematical analysis.

Furthermore, the combination law for reasoning boundary demonstrates favorable theoretical properties, with broad applicability across diverse scenarios and flexibility in accommodating various boundary segmentation methods. For detailed practical application, please refer to Appendix [9.2](#append:tutorial){reference-type="ref" reference="append:tutorial"}.

::: takeaways
**Conclusion:** The combination law of reasoning boundary satisfies the weighted harmonic average of each basic reasoning boundary.
:::

## Categories of Reasoning Boundary

[]{#sec:types label="sec:types"} Furthermore, in order to guide the optimization of CoT and more convenient expression, as shown in Figure [1](#fig:intro){reference-type="ref" reference="fig:intro"} (c), we define the following three categories of RBs based on their empirical accuracy:

**Completely Feasible Reasoning Boundary:** We define that the part with an accuracy greater than 90% is a completely feasible reasoning boundary ($\texttt{CFRB}{}=\mathcal{B}_{\text{Acc}\ge90\%}(t_1, t_2, \dots, t_n|m)$), which means that LLMs can effectively grasp the performance of this part.

**Completely Infeasible Reasoning Boundary:** We believe that the part with an accuracy less than 10% is a completely infeasible reasoning boundary ($\texttt{CIRB}{}=\mathcal{B}_{\text{Acc}\le 10\%}(t_1, t_2, \dots, t_n|m)$), which means that the model can never effectively grasp the performance of this part.

**Partially Feasible Reasoning Boundary:** We define the RB in the rest part except `CFRB` and `CIRB` as a partially feasible reasoning boundary ($\texttt{PFRB}{}=\mathcal{B}_{10\%<\text{Acc}<90\%}(t_1, t_2, \dots, t_n|m)$), which requires the model to repeat thinking or more clear information to solve the problem.

We analyze the nature of these three categories of RB in detail (in Section [\[sec:nature\]](#sec:nature){reference-type="ref" reference="sec:nature"}), and further utilize the combination law to optimize these three reasoning boundaries (in Section [5](#sec:optimization){reference-type="ref" reference="sec:optimization"}), so as to provide effective suggestions and guidance to support future CoT optimization.

# Experimental Setup

[]{#sec:setting label="sec:setting"}

#### Benchmark Settings

To assess the reasoning boundaries of LLMs, we require a dataset rich in RB. This necessitates tasks with evenly distributed complexities and reasoning steps that challenge the models' upper-bounds. To meet these requirements, we introduce [BigGSM]{.smallcaps}, a new dataset offering greater calculation complexity and longer reasoning chains. The detailed construction process for [BigGSM]{.smallcaps} is provided in Appendix [9.3](#append:data-cons){reference-type="ref" reference="append:data-cons"}.

#### Model Settings

Except for model expansion experiments, all experiments are conducted on GPT-3.5-Turbo. Following the setting of @wei2022chain, in our CoT experiment, all multi-step reasoning tasks utilize three manually constructed demonstrations. In addition, for all the experiments, top-p is selected from $\{0.95, 1\}$. Temperature is selected from $[0,1]$ and serves as the main error variable.

# Empirical Analysis of Reasoning Boundary {#sec:experiment-rg}

## Existence Verification for Reasoning Boundary

In this study, we investigate the hypothesis that an LLM exhibits varying levels of reasoning boundary across various tasks. To this end, we will verify whether the model has widespread reasoning boundary in various tasks in the following three tasks:

<figure id="fig:atom-rg" data-latex-placement="t">
<embed src="figure/atom-rg.pdf" style="width:99.0%" />
<figcaption>Existence Verification for Reasoning Boundary.</figcaption>
</figure>

#### Basic Arithmetic Calculation

First, to investigate the existence of RB, we first examine basic arithmetic operations (including addition, subtraction, multiplication, and division). As illustrated in Figure [2](#fig:atom-rg){reference-type="ref" reference="fig:atom-rg"} (a), the results reveal significant performance variations across three distinct regions. For multiplication, accuracy surpasses 90% for results up to $2.2e5$. Conversely, accuracy falls below 10% for products exceeding $2e6$. Similar presences of varying RBs are observed for other operations, which verifies the existence of reasoning boundary in basic arithmetic calculation tasks. Further results and implementation details are provided in Appendix [9.4](#append:arithmetic){reference-type="ref" reference="append:arithmetic"}.

#### Nature Language Planning

We further investigate RB in natural language planning tasks for mathematical reasoning. We prompt the model to generate plans and assess their accuracy through manual evaluation. There is a strong correlation between the number of reasoning steps and LLMs' performance in Figure [2](#fig:atom-rg){reference-type="ref" reference="fig:atom-rg"} (b). When the model meets the question with fewer than 2 reasoning steps, accuracy surpasses 90%. Conversely, when reasoning steps exceed 4, accuracy falls below 10%. This finding suggests that there are also three different RB categories in natural language planning tasks.

#### Code Planning

For further extensive exploration, we further prompt LLMs by PAL [@pmlr-v202-gao23f] to generate code-format plans and evaluate them by manual annotation. As shown in Figure [2](#fig:atom-rg){reference-type="ref" reference="fig:atom-rg"} (c), the code planning task is similar to natural language planning, which is also an obvious division and different categories of RBs. Notably, since code planning utilizes code for clearer logic and reduced expression complexity, its planning accuracy surpasses that of natural language planning.

## Combination Law Verification on Different Tasks

#### Combination Law in Complex Arithmetic Calculation

Building on the proof of Equation [\[eq:combine-proof\]](#eq:combine-proof){reference-type="eqref" reference="eq:combine-proof"}, we hypothesize that the combination law for RB in the complex arithmetic calculation is the harmonic average of the arithmetic calculation RB and calculation planning RB. To verify this, we designed an experiment focusing on formulas containing addition, subtraction, and multiplication, like "$(1+2)*3-4$". Since addition and subtraction complexities are assumed to be around $1e{15}$ (as shown in Figure [10](#fig:atom-rg-2){reference-type="ref" reference="fig:atom-rg-2"}), the arithmetic calculation RB primarily depends on the multiplication RB and calculation planning RB. Therefore, as shown in Figure [3](#fig:cot-ag){reference-type="ref" reference="fig:cot-ag"} (a), there are two obvious RB lines, namely $\mathcal{B}_{Acc=90\%}$ and $\mathcal{B}_{Acc=10\%}$, which are completely consistent with the combination law of these basic RB based on the Equation [\[eq:combine-law\]](#eq:combine-law){reference-type="eqref" reference="eq:combine-law"}. Besides, these two lines also clearly divide the RBs into three categories.

#### Combination Law in Mathematical Reasoning

<figure id="fig:cot-ag" data-latex-placement="t">
<embed src="figure/cot-rg.pdf" style="width:98.0%" />
<figcaption> Combination law verification of RB on different tasks. More verification results on other tasks are shown in Figure <a href="#fig:med-prob" data-reference-type="ref" data-reference="fig:med-prob">[fig:med-prob]</a>. </figcaption>
</figure>

Inspired by @tan2023causal [@xiao2024theory], we posit that the natural language mathematical CoT task is determined by two sub-tasks: step planning task and step calculation task for global logic planning and local mathematical calculation. Furthermore, each model output step requires a single basic operation, resulting in a step calculation boundary close to the maximum number of multiplications, denoted by $\mathcal{B}(c) \approx \mathcal{B}(m)$. Formally, with step planning RB denoted by ($\mathcal{B}(p)$) and the step calculation RB by ($\mathcal{B}(c)$), then the combined RB satisfies the following law: $$\begin{equation}
    \mathcal{B}^{\texttt{CoT}}(c, p) = \frac{1}{\frac{N_{1}}{(\mathcal{B}(c)-b_1)} + \frac{N_{2}}{(\mathcal{B}(p)-b_2)}}.
    \label{eq:cot}
\end{equation}$$ As illustrated in Figure [3](#fig:cot-ag){reference-type="ref" reference="fig:cot-ag"} (b), the actual performance distribution of RB (including $\mathcal{B}_{Acc=90\%}$ and $\mathcal{B}_{Acc=10\%}$) in natural language mathematical reasoning task fully aligns with the proposed combination law in Equation [\[eq:cot\]](#eq:cot){reference-type="eqref" reference="eq:cot"}. Additionally, there are also obviously three RBs in Figure [3](#fig:cot-ag){reference-type="ref" reference="fig:cot-ag"} (b).

#### Combination Law in Multi-hop Reasoning

Beyond the realm of mathematics, we further extend our exploration of the combination law to the field of multi-hop question answering. Specifically, we validate our law on HotpotQA [@yang2018hotpotqa], where we define the reasoning boundary as the combination of global hop-planning RB and local knowledge entity reasoning RB. As shown in Figure [3](#fig:cot-ag){reference-type="ref" reference="fig:cot-ag"} (c), $\mathcal{B}_{Acc=90\%}$ and $\mathcal{B}_{Acc=10\%}$ also satisfy the weighted harmonic mean of these two sub-reasoning boundaries. It is also proved that, in addition to math-related tasks, multi-hop question answering also satisfies our proposed combined law and also exhibits three distinct RBs. We will describe in detail how to calculate the combination law on multi-hop reasoning in Appendix [9.5](#append:hotpotqa){reference-type="ref" reference="append:hotpotqa"}.

## Nature Analysis for different Reasoning Boundary

[]{#sec:nature label="sec:nature"} According to the definition of different RBs, we have divided the problem into three parts for LLMs. In this section, we will verify whether the defined RB adheres to the intrinsic nature of the model itself. We will discuss the natures of these RBs in detail:

**`CFRB` means complete mastery of the model even without demonstration.** According to the definition, we assume that a question within `CFRB` implies a comprehensive understanding of the associated issue for a certain LLM. To verify this, following @zhang2022automatic and @wei2022chain, we formulate a mathematical request and generate chain-of-thought rationale and answer through zero-shot prompting without any demonstration. As shown in Figure [4](#fig:nature){reference-type="ref" reference="fig:nature"} (a), it still achieves 29.2% improvement in `CFRB` on generating the correct rationale compared to other RBs. This also proves that the model can indeed master tasks well on the questions in `CFRB`.

<figure id="fig:nature" data-latex-placement="t">
<embed src="figure/CFRG-nature.pdf" style="width:99.0%" />
<figcaption> Nature analysis at different reasoning boundaries. </figcaption>
</figure>

**`PFRB` means moderate confidence in its solution and needs consensus building process.** To gauge the level of performance and confidence, we draw parallels to human decision-making, where moderate confidence often necessitates multiple times of consensus building. Inspired by this, we investigate it on `Self-Consistency` [@wang2022self], which integrates results from various reasoning answers to reach a conclusive answer. Figure [4](#fig:nature){reference-type="ref" reference="fig:nature"} (b) demonstrates that as the integration of reasoning paths increases, the accuracy improves significantly within `PFRB` compared with other RBs. This suggests that within `PFRB`, the LLM exhibits moderate confidence in solving problems, which needs multiple consensus building.

**`CIRB` exhibits poor reasoning performance even with consensus building.** As illustrated in Figure [4](#fig:nature){reference-type="ref" reference="fig:nature"} (a), questions in `CIRB` display extremely low accuracy (around 9.5%). And the model shows consistently poor performance and no improvement on `Self-consistency` in this boundary in Figure [4](#fig:nature){reference-type="ref" reference="fig:nature"}. It signifies that the model exhibits poor reasoning performance.

**LLM has self-awareness of its own RBs.** In parallel, a natural question arises: _Is the model capable of discerning its inherent RBs?_ To investigate this, we employ the `Synthetic-CoT` [@shao2023synthetic] to prompt LLM to generate CoT data. As depicted in Figure [4](#fig:nature){reference-type="ref" reference="fig:nature"} (c), the results demonstrated that there are over 65% of generated samples within `CFRB`, which achieves a much higher percentage and performance than other RBs. This suggests that LLMs possess an intrinsic understanding of their RBs and constraints to generate the task they grasp, indicative of a potential for self-assessment.

::: takeaways
**Takeaways:** (1) Reasoning boundary (RB) and the combination law of RB are both widespread across a series of tasks. (2) Different categories of RB can reflect the corresponding performance, and the model can also have a self-understanding of its own RB.
:::

# RB-based CoT Optimization {#sec:optimization}

## How can we improve CoT by optimizing RB?

Based on our framework, the reasoning boundary limits the performance of the model. The simplest approach to improve CoT is to optimize the step calculation RB $\mathcal{B}(c)$ to promote the value of RB. Specifically, Tool-Usage [@paranjape2023art] and Program-of-Thought (PoT) [@chen2024beyond] have shown significant success in CoT optimization. We explain the rationale behind their effectiveness, why PoT consistently outperforms direct Tool Usage [@yao2023react; @chen2023program], and take them as examples to demonstrate how to improve CoT by promoting RB.

**Tool Usage can boost the value of RB for an LLM.** When the model uses tools [@paranjape2023art], we can simply think that the model can perform calculations with infinite precision, so that the RB of mathematical calculations tends to infinity, viz $\mathcal{B}(c) \rightarrow +\infty$. It is obvious that the combined RB of the model can be calculated as: $$\begin{equation}
    \mathcal{B}^{\texttt{Tool}}(c, p) = \lim\limits_{\mathcal{B}(c) \rightarrow +\infty}\frac{1}{\frac{N_{1}}{(\mathcal{B}(c)-b_1)} + \frac{N_{2}}{(\mathcal{B}(p)-b_2)}} = \frac{\mathcal{B}(p)-b_2}{N_{2}}. \label{eq:tool-usage}
\end{equation}$$ Easy to get, $\mathcal{B}^{\texttt{Tool}}(c, p) > \mathcal{B}^{\texttt{CoT}}(c, p)$, this shows that Tool Usage can improve the boundary of reasoning. This explains why Tool Usage can have better performance than vanilla CoT (as shown in Table [\[exp:main-exp\]](#exp:main-exp){reference-type="ref" reference="exp:main-exp"}). Furthermore, as shown in Figure [5](#fig:upperbound){reference-type="ref" reference="fig:upperbound"}, the distribution of theoretical RB and the actual one almost perfectly coincide. This also demonstrates the reliability and applicability of our theory.

**Program-of-Thought can further enhance the value of LLM's RB.** Equation [\[eq:tool-usage\]](#eq:tool-usage){reference-type="eqref" reference="eq:tool-usage"} reveals that an LLM's RB hinges entirely on its planning capability. Since natural language can be verbose, it hinders the planning capability of LLM [@pmlr-v202-gao23f; @hu2023code; @puerto2024code; @chen2024beyond]. `PoT` [@chen2023program] offers a clearer representation of logic using code, allowing for clearer planning (as shown in Figure [2](#fig:atom-rg){reference-type="ref" reference="fig:atom-rg"} (b, c)). This leads to finer-grained planning reasoning $\mathcal{B}^{*}(p) > \mathcal{B}(p)$. Then the PoT reasoning boundary $\mathcal{B}^{\texttt{PoT}}(c,p)>\mathcal{B}^{\texttt{Tool}}(c,p)$, aligning with the observed performance gains of `PoT` over `Tool Usage` (see Table [\[exp:main-exp\]](#exp:main-exp){reference-type="ref" reference="exp:main-exp"}). Furthermore, Figure [5](#fig:upperbound){reference-type="ref" reference="fig:upperbound"} visually demonstrates that PoT's theoretical and practical reasoning boundaries consistently outperform `Tool Usage`. This reinforces the theoretical advantage of PoT and its empirical effectiveness.

<figure id="fig:upperbound" data-latex-placement="t">
<div class="minipage">
<div class="adjustbox">
<p><span>width=0.99</span></p>
<table>
<thead>
<tr>
<th style="text-align: left;">Model</th>
<th colspan="3" style="text-align: center;"><span class="smallcaps">BigGSM</span></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;"><span>2-4</span></td>
<td style="text-align: center;">Acc. (<span class="math inline">↑</span>)</td>
<td style="text-align: center;">Input Token (<span class="math inline">↓</span>)</td>
<td style="text-align: center;">Output Token (<span class="math inline">↓</span>)</td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT</code></td>
<td style="text-align: center;">57.00 <span class="math inline"><sub>±0.93</sub></span></td>
<td style="text-align: center;">780.43</td>
<td style="text-align: center;">96.76 <span class="math inline"><sub>±3.22</sub></span></td>
</tr>
<tr>
<td style="text-align: left;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr>
<td style="text-align: left;"><code>Tool Usage</code></td>
<td style="text-align: center;">71.64 <span class="math inline"><sub>±0.66</sub></span></td>
<td style="text-align: center;">688.43</td>
<td style="text-align: center;">129.53 <span class="math inline"><sub>±3.82</sub></span></td>
</tr>
<tr>
<td style="text-align: left;"><code>PoT</code></td>
<td style="text-align: center;">78.25 <span class="math inline"><sub>±1.09</sub></span></td>
<td style="text-align: center;">657.43</td>
<td style="text-align: center;">78.25 <span class="math inline"><sub>±1.09</sub></span></td>
</tr>
<tr>
<td style="text-align: left;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr>
<td style="text-align: left;"><code>Least-to-most</code></td>
<td style="text-align: center;">58.25 <span class="math inline"><sub>±3.28</sub></span></td>
<td style="text-align: center;">679.59</td>
<td style="text-align: center;">176.09 <span class="math inline"><sub>±15.22</sub></span></td>
</tr>
<tr>
<td style="text-align: left;"><code>Complex-CoT</code></td>
<td style="text-align: center;">59.78 <span class="math inline"><sub>±0.60</sub></span></td>
<td style="text-align: center;">1111.43</td>
<td style="text-align: center;">131.82 <span class="math inline"><sub>±1.91</sub></span></td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT+MARP</code></td>
<td style="text-align: center;">64.37 <span class="math inline"><sub>±2.24</sub></span></td>
<td style="text-align: center;">614.43</td>
<td style="text-align: center;">95.12 <span class="math inline"><sub>±0.77</sub></span></td>
</tr>
<tr>
<td style="text-align: left;"><code>PoT+MARP</code></td>
<td style="text-align: center;"><strong>80.55</strong> <span class="math inline"><sub>±2.40</sub></span></td>
<td style="text-align: center;"><strong>576.43</strong></td>
<td style="text-align: center;"><strong>76.34</strong> <span class="math inline"><sub>±2.84</sub></span></td>
</tr>
</tbody>
</table>
</div>
<p><span id="exp:main-exp" data-label="exp:main-exp"></span></p>
</div>
<div class="minipage">
<p><embed src="figure/upperbound.pdf" style="width:99.0%" /> <span id="fig:upperbound" data-label="fig:upperbound"></span></p>
</div>
</figure>

## How can we improve CoT based on a certain RB?

Enhancing RB is crucial for optimizing CoT, but requires changes to the model or its reasoning architecture to be effective. Therefore, we need to consider how to optimize the reasoning path so that the difficulty satisfies the RB ($d^{*}=\mathcal{B}_{Acc=K_1}$) instead of the original RB ($d=\mathcal{B}_{Acc=K_2}$), where $K_2<K_1$. According to Equation [\[eq:cot\]](#eq:cot){reference-type="eqref" reference="eq:cot"}, $\mathcal{B}$ is affected by both arithmetical RB and planning RB. Given $\mathcal{B}$, we consider optimizing reasoning ability from the following two strategies as examples [^2]:

**Complex CoT (`CCoT`):** By increasing the boundary of planning to reduce the pressure of single-step calculation, reduce the arithmetical RB, and then get smaller $d$; However, it introduces more planning steps, which adds the planning pressure. As shown in Figure [\[fig:complex-cot-1\]](#fig:complex-cot-1){reference-type="ref" reference="fig:complex-cot-1"}, the model performance first increases and then decreases with the increasing number of `CCoT` steps.

**Least-to-Most (`LtM`):** By dividing multiple sub-questions to reduce the pressure of local planning within a sub-question, reduce the boundary of local planning, and then get smaller $d$. However, even though it can release local planning pressure (as demonstrated in Figure [6](#fig:least-to-most-number){reference-type="ref" reference="fig:least-to-most-number"}), this approach simultaneously intensifies global planning pressure by generating an excessive number of sub-questions (as depicted in Figure [12](#fig:least-to-most){reference-type="ref" reference="fig:least-to-most"}).

::: limitation

#### Limitation:

\(1\) `CCoT` needs to keep balance in the number of reasoning steps and calculation pressure. (2) Although the pressure of local planning has been reduced, `LtM` has not effectively reduced the pressure of global planning, nor the pressure of optimization calculations.
:::

<figure id="fig:least-to-most-number" data-latex-placement="h">
<div class="minipage">
<embed src="figure/complex-cot.pdf" style="width:99.0%" />
<p><span id="fig:complex-cot-1" data-label="fig:complex-cot-1"></span></p>
</div>
<div class="minipage">
<embed src="figure/least-to-most-number.pdf" style="width:99.0%" />
<p><span id="fig:least-to-most-number" data-label="fig:least-to-most-number"></span></p>
</div>
</figure>

<figure id="fig:correlation" data-latex-placement="b">
<p><embed src="figure/relationship.pdf" style="width:99.0%" /> <span id="fig:correlation" data-label="fig:correlation"></span></p>
</figure>

#### Minimum acceptable reasoning paths prompting can further achieve better CoT within a specific RB.

To address the aforementioned two issues, we proposed Minimum Acceptable Reasoning Paths (MARP). Our first objective is to alleviate the computational burden of the model. We achieve this by introducing instructions that set an upper limit on its single-step computational capacity, thereby optimizing the boundary of its computational reasoning. Secondly, we aim to enhance the model's acceptability. Within the calculation and planning boundary, we increase the amount of computation performed in each step in demonstrations as much as possible while simultaneously reducing the number of global planning steps, which effectively mitigates planning pressure. As shown in Table [\[exp:main-exp\]](#exp:main-exp){reference-type="ref" reference="exp:main-exp"}, MARP demonstrably improves model performance and effectively reduces the token consumption. By maximizing operations per step, MARP leads to a more streamlined and efficient problem-solving process. Detailed descriptions of this strategy are shown in Appendix [9.7.3](#append:heuristic-baselines){reference-type="ref" reference="append:heuristic-baselines"}.

::: takeaways
**Takeaways:** (1) Tool-Usage and PoT can be utilized to optimize CoT by the calculation and planning reasoning boundary optimization. (2) `MARP` can well lessen planning and calculation pressure by problem optimization in certain RB (3) Users can effectively optimize CoT performance by optimizing the reasoning boundary and the problem.
:::

<figure id="fig:mgsm" data-latex-placement="t">
<div class="minipage">
<p><embed src="figure/scaling-law.pdf" style="width:99.0%" /> <span id="fig:scaling" data-label="fig:scaling"></span></p>
</div>
<div class="minipage">
<embed src="figure/mgsm.pdf" style="width:99.0%" />
<p><span id="fig:mgsm" data-label="fig:mgsm"></span></p>
</div>
</figure>

# Expansion Verification & Exploration

**RB can be extended to various models.** To extend our mechanism's applicability, we verify the mechanism on 25 diverse models (details in Table [\[exp:model\]](#exp:model){reference-type="ref" reference="exp:model"}). As shown in Figure [7](#fig:correlation){reference-type="ref" reference="fig:correlation"} (a), we observe a positive correlation between reasoning boundary and model accuracy on mathematical benchmarks. Moreover, the models that use mathematical data such as MathInstruct for SFT, often have interesting outliers that are different from the general LLMs' area, but they also satisfy a positive correlation with our RBs (as shown in Figure [7](#fig:correlation){reference-type="ref" reference="fig:correlation"} (b)), which helps determine if the model underwent mathematically targeted training.

However, as shown in Figure [7](#fig:correlation){reference-type="ref" reference="fig:correlation"} (c), we find some interesting phenomena. For example, the main difference between the current open-source model and the closed-source model is still `CFRB`. Except for the closed source model, the `CFRB` of all models is 0. It shows the potential and the direction of the model optimization. Furthermore, a scaling law of RB can also emerge (as shown in Figure [\[fig:scaling\]](#fig:scaling){reference-type="ref" reference="fig:scaling"}): reasoning boundary increased with model parameter count and data quality.

**RB can be extended to more tasks.** To assess the RB in more tasks, we evaluate them on a multilingual mathematical reasoning task. Inspired by @qin2024multilingual, we hypothesize that multilingual RB, assessed through direct answer accuracy across different languages, mathematical computation RB, represented by the maximum product result, and reasoning planning RB, indicated by the planning steps, are orthogonal dimensions of performance. We propose that these RBs can be effectively combined using a weighted harmonic mean. As illustrated in Figure [8](#fig:mgsm){reference-type="ref" reference="fig:mgsm"} confirms that the combined RB maintains the expected three different RBs. Detailed implementation description is shown in Appendix [9.9](#append:mgsm){reference-type="ref" reference="append:mgsm"}.

# Related Work

In this section, we review recent literature related to Chain-of-Thought (CoT) prompting, focusing on theoretical and empirical investigations. @madaan-etal-2023-makes [@wang-etal-2023-towards; @saparov2023language; @he2023solving; @zhang2024pattern; @wang2024rethinking] and @prystawski2024think qualitatively show that the LLMs learn the reasoning chain based on the demonstrations in the context. Besides, @lampinen-etal-2022-language and @tan-2023-causal find a causal link between generated intermediate steps and the final answers during a series of qualitative experiments. @wang2023large [@hanna2024does] and @dutta2024think study neural substructure within the LLMs, embodying CoT reasoning from a white-box mechanism perspective, demonstrating that LLMs deploy multiple parallel answer generation paths internally.

Recently, a large amount of work has demonstrated the upper-bounds and limitations of LLM in various CoT tasks [@qin2023cross; @imani2023mathprompter; @huang2024far; @sprague2024musr]. @bi2024program investigate these bounds on planning capability in code generation by training LLM on CoT samples of varying difficulties. Their findings suggest that LLMs have a limited capacity to learn or manage tasks exceeding a certain complexity threshold. Further understanding of the CoT upper-bound, @merrill2023expressive [@li2023chain] and @feng2024towards analyze single-step arithmetic capability, which suggests an upper bound on model performance related to input length in single-step reasoning processes.

Despite advancements in CoT explanation for LLMs, significant challenges remain, including the absence of quantifiable metrics for CoT's upper-bounds and the deficiency in optimization guidelines. To tackle this, we propose a reasoning boundaries framework (`RBF`) to systematically quantify and optimize various CoT approaches. This framework offers a transferable and user-friendly methodology to enhance model performance from a mechanistic perspective. We anticipate that it will furnish systematic insights for ongoing research and inform future developments in the field.

<figure id="fig:model_compare" data-latex-placement="t">
<embed src="figure/cot-rg-model-1.pdf" style="width:99.0%" />
</figure>

# Discussion

[]{#sec:discussion label="sec:discussion"}

#### Discussion on the Boundaries Improvements

Furthermore, in order to better understand the best existing LLMs, we utilize `RBF` to test the current most advanced GPT-series models. As shown in Figure [9](#fig:model_compare){reference-type="ref" reference="fig:model_compare"}, all reasoning boundaries improve a lot compared to the last version which also achieves performance enhancement. Notably, the `CFRB` increases slightly compared with the improvement of `CIRB` between GPT-3.5 and GPT-4o. But o1 significantly improves the `CFRB`. Furthermore, as shown in Figure [11](#fig:cot-rg-model-2){reference-type="ref" reference="fig:cot-rg-model-2"} in Appendix, o1 shows extremely significant improvements on `CFRB`, which is almost three times of other models. We attribute it to the fact that the advanced Reinforce-Learning and Inference Scaling strategies play a key role in improving this part of the ability compared with the normal improvements in `CFRB`, which might trigger more in-depth research.

#### Broader impacts.

Our framework is the first work to quantify the reasoning upper-bound of LLMs. This enables the explanation for a huge part of the valid CoT framework. We hope that our work can provide new insights and more systematic guidance for future interpretability analysis of CoT. For social impact, this work may have a certain impact on the controllable and explainable AGI.

#### Limitations & Future.

Due to the cost and time constraints, this work does not discuss the complex relationships such as causal conditions among the basic RBs. In addition, evaluating the robustness and applicability of CoT reasoning boundaries-related techniques in dynamic scenarios will be crucial for future research.

# Conclusion

This study introduces a novel reasoning boundaries framework (`RBF`) to quantify and optimize the limitations of LLMs in CoT tasks. Specifically, we propose the concept of reasoning boundaries (RBs) and the combination law of RBs in more complex scenarios for quantitative metrics. We further introduce three categories of RB for CoT optimizations. The framework is validated through extensive experiments across 27 models and 5 tasks. Furthermore, we improve the CoT in both RB and question optimization perspectives to achieve state-of-the-art performance in [BigGSM]{.smallcaps}. We hope that this framework paves the way for further research on understanding and enhancing LLMs' reasoning capabilities.

# Acknowledgments {#acknowledgments .unnumbered}

This work was supported by the National Natural Science Foundation of China (NSFC) via grant 62236004, 62441603, 62476073 and 62306342. This work was also sponsored by the Excellent Young Scientists Fund in Hunan Province (2024JJ4070), the Science and Technology Innovation Program of Hunan Province under Grant 2024RC3024, and the CCF-Zhipu.AI Large Model Innovation Fund.

# Appendix {#appendix .unnumbered}

## Mathematical Analysis & Proof {#append:proof}

### Definitions & Assumptions

In order to further quantify and analyze the combination law of RB, we will make the following definitions and assumptions about the properties of RB:

::: {#def:rg-inf .definition}
**Definition 1**. _If a basic RB in the combined RB takes infinity, then the combined RB only depends on the remaining basic RBs._
:::

That is, the model is no longer limited by a certain ability when solving tasks, and only needs to focus on other ability shortcomings. Formally, combination law satisfies that[^3]: $$\begin{align}
    \mathcal{B}(t_1, t_2, \dots, t_n|m)\! &=\! \mathcal{B}(+\infty, t_2, \dots, t_n|m)\! +\! \mathcal{B}(t_1, +\infty, \dots, t_n|m)\! +\! \cdots \!+\! \mathcal{B}(t_1, t_2, \dots, +\infty|m) \\
    &= \mathcal{B}(t_2, t_3 \dots, t_n|m)\! +\! \mathcal{B}(t_1, t_3, \dots, t_n|m)\! +\! \cdots\! + \!\mathcal{B}(t_1, t_2, \dots, t_{n-1}|m) \\
    & = (n-1)\sum^{n}_{i=1} \mathcal{B}(+\infty,\dots, +\infty,t_i,+\infty,\dots,+\infty|m)\label{eq:proof-0}
\end{align}$$

::: {#def:all-inf .definition}
**Definition 2**. _If all basic RBs are infinite, it means that the model is omnipotent, and the combined RB is also infinite._
:::

Formally, the combination law satisfies that: $$\begin{equation}
    \mathcal{B}(+\infty, +\infty, \dots, +\infty|m) = +\infty
\end{equation}$$

::: {#asp:1 .assumption}
**Assumption 3**. _The combination law function is continuously differentiable everywhere._
:::

::: {#asp:1 .assumption}
**Assumption 4**. _All basic reasoning boundary for combined reasoning boundary are mutually independent._
:::

### The Proof of Combination Law

Based on the above definitions and assumptions, we need to prove that the combination law is a combined RB and is the weighted harmonic average of two basic RBs.

**_Proof._** Since Taylor expansion cannot be performed on infinity and the function needs to converge, we set $t_i = \frac{1}{x_i}+b_i$ and $\frac{1}{\mathcal{B}(t_1, t_2, \dots, t_n|m)} = \mathcal{B}^{*}(x_1, x_2, \dots, x_n|m)$. Then following Equation [\[eq:proof-0\]](#eq:proof-0){reference-type="eqref" reference="eq:proof-0"}, we can get the $\mathcal{B}^{*}(x_1, x_2, \dots, x_n|m)$ as: $$\begin{equation}
    \mathcal{B}^{*}(x_1, x_2, \dots, x_n|m) = (n-1)\sum^{n}_{i=1} \mathcal{B}^{*}(0,\dots, x_i,\dots,0|m).
\end{equation}$$

According to the Taylor expansion formula, we expand this formula at $x_i \rightarrow k_i$, we can get: $$\begin{align}
    \mathcal{B}^{*}(x_1, x_2, \dots, x_n|m)&=(n-1)\sum^{n}_{i=1}\sum_{j=1}^{+\infty}N_{ij}(x_{i}-k_{i})^{j}\\
    &=(n-1)\sum^{n}_{i=1}N_{i1} (x_{i}-k_{i}) + \mathcal{O}(x_i) \\
    & \approx (n-1)\sum^{n}_{i=1}N_{i1} (x_{i}-k_{i}),
\end{align}$$ where $N_{i1}=\frac{\partial \mathcal{B}^{*}(x_1, x_2, \dots, x_n|m)}{\partial x_i}$. Then the original formula is expressed as: $$\begin{equation}
    \mathcal{B}(t_1, t_2, \dots, t_n|m) \approx \frac{1}{(n-1)\sum^{n}_{i=1}\frac{N_{i1}}{t_i-b_i}-k_i} \label{eq:combine-proof}
\end{equation}$$ Given the minimal change in the derivative within the observable range, $N_{i1}$ is treated as a constant $N_{i}$ in this task for simplicity. Experimental results show that, if sub-RBs are separated independently, $k_i$ is typically 0. Since $t_i$ cannot be directly quantified, we use basic form of $\mathcal{B}(t_i|m)$ as its quantized substitute, thus simplifying the combination law as: $$\begin{equation}
    \mathcal{B}(t_1, t_2, \dots, t_n|m) \approx \frac{1}{(n-1)\sum^{n}_{i=1}\frac{N_{i}}{\mathcal{B}(t_i|m)-b_i}} \label{eq:combine-final}
\end{equation}$$

### Calculation of RB in Practical Process

::: wrapfigure
r0.38 [IMAGE: image]{width="36%"}
:::

To determine the constants, we first fit parameters to a model using a development dataset (or 20% of the test dataset if the development dataset is not available). This fitting process yields the corresponding constants. For a given task and prompt strategy, these constants remain fixed. Additionally, once the combination law constants are established, different reasoning boundaries are determined through a binary search on performance in a standard setting (3-shot CoT). For instance, we use binary search to identify a reasoning boundary that ensures the accuracy of all problems below that boundary approaches 90%, achieving $\mathcal{B}_{Acc=90\%}$. For one model, one task, and one prompt type, the reasoning boundary remains fixed. Zero-shot and few-shot settings share the same set of reasoning boundaries.

## The Application Tutorial of Reasoning Boundary {#append:tutorial}

From a practical standpoint, our mechanism framework exhibits universal adaptability, making it suitable for application in a wide range of scenarios. When confronted with a new problem context, the framework enables a systematic approach to problem-solving. A key feature of the framework is its reliance on the weighted harmonic mean, which imparts advantageous mathematical properties to its structure. Specifically, the framework operates effectively if the reasoning process can be segmented into relatively independent boundaries. This segmentation allows the framework to be fully leveraged in addressing diverse problems.

#### Reasoning Boundary Application.

In the case of a vertical domain problem based on CoT reasoning, the process can be divided into two key boundary levels: task planning and domain-specific reasoning. These can be modeled as follows: $$\begin{equation}
    \mathcal{B} = \frac{1}{\frac{1}{\mathcal{B}_p}+\frac{1}{\mathcal{B}_v} + k_1},
\end{equation}$$ where: $\mathcal{B}_p$ represents the task planning boundary, $\mathcal{B}_v$ represents the vertical domain boundary, and $k_1$ is a constant reflecting the degree of boundary independence.

#### Reasoning Boundary Definition & Segmentation.

Neglecting any of these boundaries only results in an increase in $k$, but keeping the overall efficiency of the framework. If the reasoning boundary is well-defined and independent, the value of $k$ approaches zero, showcasing the effectiveness of our mechanism framework.

#### Further Reasoning Boundary Segmentation.

Further refinement of the vertical domain boundary, $\mathcal{B}_v$, into $\mathcal{B}_{v1}$ and $\mathcal{B}_{v2}$ is straightforward. No additional complexity is introduced, as the following relationship holds: $$\begin{equation}
    \mathcal{B}_v = \frac{1}{\frac{1}{\mathcal{B}_{v1}}+\frac{1}{\mathcal{B}_{v2}} + k_2}.
\end{equation}$$ Thus, the overall boundary equation can be extended to: $$\begin{equation}
    \mathcal{B} = \frac{1}{\frac{1}{\mathcal{B}_p}+\frac{1}{\mathcal{B}_{v1}}+\frac{1}{\mathcal{B}_{v2}} + k_1 + k_2}.
\end{equation}$$ This formulation allows for flexible and systematic boundary division at multiple levels, enhancing the framework's practical utility across various problem domains.

#### Challenging Reasoning Boundary Measurement.

In addition, we propose an alternative method to measure the reasoning boundaries. This approach allows the model to provide direct answers without relying on CoT reasoning steps. By doing so, the model's reasoning process for a specific task depends solely on a single reasoning boundary, which can be represented as follows: $$\begin{equation}
    \mathcal{B} = \frac{1}{\frac{1}{\mathcal{B}_1} + k_1}.
\end{equation}$$ For instance, in the MGSM task, assessing multilingual reasoning boundary is particularly challenging. To address this, we directly evaluate the model's performance using a direct prompting strategy without CoT outputs and use this performance to define the multilingual reasoning boundary, which in turn helps determine the corresponding normalization constant. Subsequently, we apply multilingual CoT reasoning to the MGSM task to calculate the combined boundary using the framework's combination law. This approach provides a more generalized solution and may be more adaptable to specific needs.

## Details of Dataset {#append:data-cons}

### Dataset Construction

To adequately assess the reasoning boundary of LLMs, it is essential to develop a dataset that encompasses a range of complexities and reasoning boundaries. To address these challenges, we propose a novel approach to constructing a mathematical reasoning dataset using manual synthesis and annotation which finally leads to the [BigGSM]{.smallcaps} benchmark. Specifically, our proposed method involves the manual synthesis and annotation of a mathematical reasoning dataset. The construction process includes the following steps:

#### Step 1: Domain Template Generation

Initially, we employ a prompt-driven LLM (GPT-4) to generate complex scenarios necessitating multi-step calculations. This process also yields initial example templates. Specifically, the prompt given to the large model is as follows:

::: prompt
Generate a scenario-related template involving multiple mathematical steps to solve a real-world problem. Ensure the scenario requires the application of different mathematical concepts. Please use \"\[VAR\]\" as a variable to mark the template of the question.
:::

#### Step 2: Natural Language Template Creation

Recognizing that LLMs can produce errors and logical inconsistencies, we refine these initial templates to improve their accuracy and add mathematical calculations. To facilitate the generation of extended sequences, we decompose the templates into smaller, loopable segments that incrementally meet the multi-step reasoning demands.

#### Step 3: Domain Template Augmentation

To address the limited diversity in individual samples and provide a broader evaluation of LLMs' mathematical abilities, we use an LLM (GPT-4) to generate at least three alternative augmented templates for each original template and step. The generation prompt we use is as follows:

::: prompt
Create three alternative versions of the following template that introduce different complexities or variables, ensuring each version demands an equivalent level of reasoning.
:::

#### Step 4: Numeric Filling

Once all templates are prepared, we aim to test the upper-bound of the LLMs' computational reasoning boundary by introducing numerical values ranging from 1 to 1e5 in multiplication tasks. This step is designed to thoroughly assess the models' performance across a spectrum of numerical challenges.

#### Step 5: Manual Annotation

To ensure the quality and logical coherence of our synthetic samples, we manually review them to correct any errors introduced during the automated generation process. Finally, we hired three experts to mark whether the samples in the data set were correct. Only for those samples where more than two experts agreed did we retain the corresponding samples. The Cohen's kappa value marked by the experts was 0.97, which indicates the perfect agreement.

### Dataset Analysis

Our dataset comprises 610 test samples, which is extensive when compared to the GSM8K dataset. It features a broader range of procedural steps, varying from 1 to 16 steps. Additionally, our dataset encompasses a wider spectrum of computational efforts, ranging from 6 to 3e5.

## The Implementation Details of Basic Arithmetic Calculation {#append:arithmetic}

<figure id="fig:atom-rg-2" data-latex-placement="t">
<embed src="figure/atom-rg-2.pdf" style="width:98.0%" />
<figcaption> Existence verification for reasoning boundaries on basic arithmetic calculation tasks, including division, addition, and subtraction operations. </figcaption>
</figure>

<figure id="fig:cot-rg-model-2" data-latex-placement="t">
<embed src="figure/cot-rg-model-2.pdf" style="width:76.0%" />
<figcaption> Correlation between the values of RB for different models and performance on real benchmarks. </figcaption>
</figure>

### Data Construction {#append:arithmetic-data}

This section outlines the process used to construct datasets for examining the existence of reasoning boundaries (RB) in basic arithmetic calculations. Initially, we identify the operations for investigation, namely addition, subtraction, multiplication, and division. We then determine the range of integer operands ($x$ and $y$), starting from 1 to $1e{10}$, subsequently extending to $1e{20}$. A random number generator is employed to produce independent and unbiased pairs of $x$ and $y$ within the specified range. For each pair, we compute the expected correct outcome of the chosen operation using standard arithmetic procedures. In addition, in order to ensure that decimals do not affect the computational complexity, we restrict our analysis to integer operands and outcomes to control for complexity and randomly generate numerical values of $x$ and $y$.

### Prompt Construction

The prompt configuration in our study involves inputting the structured data into a computational model to analyze the arithmetic accuracy. The following prompting is used for LLMs' input:

::: prompt
Please calculate the formula given below:

$x$ $\mathbf{op}$ $y$=
:::

where $\mathbf{op}$ denotes the arithmetic operation (selected from addition, subtraction, multiplication, division). And $x$ and $y$ values are generated from Section [9.4.1](#append:arithmetic-data){reference-type="ref" reference="append:arithmetic-data"}. The final experimental results are shown in Figure [10](#fig:atom-rg-2){reference-type="ref" reference="fig:atom-rg-2"}.

## The Implementation Details of Multi-hop Reasoning {#append:hotpotqa}

We propose that the natural language multi-hop CoT task comprises two sub-tasks: multi-hop planning and knowledge step reasoning for multi-hop question answering. To address the challenge of measuring knowledge difficulty, we utilize a NER model[^4] to identify the number of knowledge entities in each hop, thus marking the knowledge step reasoning RB in the single-step task. Formally, let $\mathcal{B}(h)$ represent the RB of multi-hop planning and $\mathcal{B}(e)$ denote the RB of knowledge step reasoning. The combined RB satisfies the following combination law: $$\begin{equation}
    \mathcal{B}^{\texttt{CoT}}(e, h) = \frac{1}{\frac{N_{1}}{(\mathcal{B}(e)-b_1)} + \frac{N_{2}}{(\mathcal{B}(h)-b_2)}}.
    \label{eq:multi-hop}
\end{equation}$$

## Analysis for Complex-CoT and Least-to-Most within Reasoning Path Optimization Perspective {#append:analysis}

#### Complex CoT Prompting can achieve better CoT within a specific RB by simplifying the calculation reasoning step.

We believe that Complex CoT optimizes the performance of the model by allowing the model to reach its computational limit as much as possible in single-step reasoning. Therefore, the combined RB for Complex-CoT can be expressed as: $$\begin{equation}
    \mathcal{B}^{\texttt{Complex}}(p, c) = \lim\limits_{\mathcal{B}(c) \rightarrow \mathcal{B}_{\text{Acc}=100\%}(c)}\frac{1}{\frac{N_{1}}{(\mathcal{B}(c)-b_1)} + \frac{N_{2}}{(\mathcal{B}'(p)-b_2)}}
\end{equation}$$

Assuming the premises of RB remain unchanged (${\mathcal{B}}^{\texttt{Complex}}(p, c)=\mathcal{B}^{\texttt{CoT}}(p, c)$), it can obviously yield the solution $\mathcal{B}'(p)>\mathcal{B}(p)$. Therefore, the model can accept more steps of reasoning boundary, that is, if the planning difficulty $d_p$ is less than reasoning capability $\mathcal{B}'(p)$, the accuracy is higher. In order to analyze this problem, we adopted a meta-analysis method. We count the performance of the work of @jin2024impact [@fu2023complexitybased] using Complex CoT. The relationship between the performance label and the number of steps is shown in Figure [\[fig:complex-cot-1\]](#fig:complex-cot-1){reference-type="ref" reference="fig:complex-cot-1"} (left). For most multi-step reasoning tasks, generally speaking, within a certain range, as the number of steps increases, the computational pressure of the model is relieved and the performance is improved, which is consistent with the theory and exploration of @feng2024towards [@wang2023all; @valmeekam2023planning].

However, We can also clearly recognize the flaws of Complex CoT. Once the difficulty of planning $d_p$ (that is, the number of planning steps) is greater than $\mathcal{B}'(p)$, it exceeds the capabilities of the model and the performance will decline. We can observe that for single-step calculation reasoning, as shown in Figure [\[fig:complex-cot-1\]](#fig:complex-cot-1){reference-type="ref" reference="fig:complex-cot-1"} (right), the performance of using Complex CoT will gradually decrease. The rest of mathematical reasoning will also decrease when the number of steps is greater than a certain threshold. This phenomenon can also be explained by our combination law. While the amount of calculation is reduced, the number of reasoning steps is also increasing. If the acceptable number of reasoning steps is exceeded, the reasoning boundary is exceeded, and the model performance will decline, which demonstrates that it is necessary to keep a balance between the number of reasoning steps and computational pressure (see Appendix [9.7](#append:least-to-most){reference-type="ref" reference="append:least-to-most"} for detailed meta-analysis process).

::: limitation

#### Limitation:

Need to keep balance in the number of reasoning steps and calculation pressure.
:::

<figure id="fig:least-to-most" data-latex-placement="t">
<embed src="figure/least-to-most.pdf" style="width:98.0%" />
<figcaption> Analysis of output results for Least-to-Most Prompting. </figcaption>
</figure>

#### Least-to-Most Prompting can achieve better CoT within a specific RB by simplifying the planning reasoning paths.

Least-to-most prompting structures problem-solving hierarchically, by breaking questions into smaller sub-questions and further solving them one-by-one. Accordingly, the Least-to-most RB can be divided into three sub-RBs, namely, the problem decomposition RB $\mathcal{B}(d)$, the problem planning RB $\mathcal{B}(p)$, and the single-step calculation RB $\mathcal{B}(c)$. Therefore, the combined RB for least-to-most can be expressed as: $$\begin{equation}
    \mathcal{B}^{\texttt{LtM}}(d, p, c) = \frac{1}{\frac{2N_{1}}{(\mathcal{B}'(c)-b_1)} + \frac{2N_{2}}{(\mathcal{B}(p)-b_2)} + \frac{2N_{3}}{(\mathcal{B}(d)-b_3)}}.
\end{equation}$$ Ideally, if the problem decomposition ability of the model is excellent ($\mathcal{B}(d)\rightarrow +\infty$), it can decompose the problem into sub-problems that can be solved in one step every time $\mathcal{B}(c) \rightarrow 1$, therefore the least-to-most RB can be expressed as: $$\begin{equation}
    \hat{\mathcal{B}}^{\texttt{LtM}}(d, p, c) = \lim\limits_{\mathcal{B}(c) \rightarrow 1, \mathcal{B}(d)\rightarrow +\infty}\mathcal{B}^{\texttt{LtM}}(d, p, c) = \frac{\mathcal{B}'(c)-b_2}{N_{1}(\mathcal{B}'(c)-b_2)-N_{2}}, \label{eq:LtM}
\end{equation}$$

Assuming the premises of RB remain unchanged ($\hat{\mathcal{B}}^{\texttt{LtM}}(d, p, c)=\mathcal{B}^{\texttt{CoT}}(p, c)$), it can obviously yield the solution $\mathcal{B}'(c)>\mathcal{B}(c)$. On the contrary, the model can accept larger difficulty $d$, which also shows that using least-to-most prompting can effectively increase the maximum of acceptable calculation RB under a given RB (as shown in Figure [6](#fig:least-to-most-number){reference-type="ref" reference="fig:least-to-most-number"}), thereby improving model performance. As shown in Table [\[exp:main-exp\]](#exp:main-exp){reference-type="ref" reference="exp:main-exp"}, we find that LLM can be optimized by Least-to-most from vanilla CoT.

However, the performance improvement of the model is not significant, which we attribute to the fact that the current model cannot push its performance to the ideal limit. As shown in Figure [12](#fig:least-to-most){reference-type="ref" reference="fig:least-to-most"} (a), the reasoning boundary of the model cannot make each reasoning step completely tend to 1, which also leads to the difference in reasoning performance in Figure [12](#fig:least-to-most){reference-type="ref" reference="fig:least-to-most"} (b). In the meantime, the model's ability to divide problems is also limited. What's more, as shown in Figure [12](#fig:least-to-most){reference-type="ref" reference="fig:least-to-most"} (c), in around 90% of cases, the model will only divide less than 6 problems, which also limits the performance.

::: limitation

#### Limitation:

Although the pressure of local planning has been reduced, it has not actually effectively reduced the pressure of global planning, nor the pressure of optimization calculations.
:::

<figure id="fig:complex-cot" data-latex-placement="t">
<embed src="figure/complex-cot-all.pdf" style="width:92.0%" />
<figcaption> The effectiveness on average step length in demonstrations for CoT performance. </figcaption>
</figure>

## The Meta-Analysis for Complex-CoT Prompting {#append:least-to-most}

In order to discuss the advantages and limitations of Complex-CoT, we conduct two detailed meta-analyses through two distinct perspectives. The first one assesses the influence of the reasoning steps demonstrated in In-Context Learning (ICL) across various tasks, while the second evaluates the effects of employing a fixed number of reasoning steps in ICL on questions with different reasoning steps. These meta-analyses aim to compare the efficacy of these methods against prior studies systematically. Specifically, we conducted a systematic search for relevant studies addressing the same problem tackled by @jin2024impact [@fu2023complexitybased; @shum2023automatic; @sun2023enhancing], and @jiang2023resprompt. We ensured that retrieved studies were pertinent, focusing on studies that addressed the same problem and used similar evaluation metrics.

### The effectiveness of step length in demonstrations

From each selected study, including @jin2024impact and @fu2023complexitybased, we evaluate the performance using Complex CoT. The relationship between performance and the number of Complex CoT's steps is shown in Figure [13](#fig:complex-cot){reference-type="ref" reference="fig:complex-cot"}. For most multi-step reasoning tasks, as the number of steps increases within a certain range, the computational load decreases, and performance improves.

However, as described in Appendix [9.6](#append:analysis){reference-type="ref" reference="append:analysis"}, the flaws of Complex CoT are apparent. When the difficulty of planning ($d_p$), defined as the number of planning steps, exceeds $\mathcal{B}'(p)$, the model's capabilities are surpassed, leading to a performance decline. This is evident in single-step calculation reasoning, as shown in Figure [13](#fig:complex-cot){reference-type="ref" reference="fig:complex-cot"} (c, e), where performance using Complex CoT gradually decreases. Similarly, for other mathematical reasoning tasks, performance decreases when the number of steps exceeds a certain threshold. This phenomenon aligns with our combination law: while reducing the amount of calculation, the number of reasoning steps increases. Exceeding the acceptable number of reasoning steps surpasses the reasoning boundary, causing a decline in model performance. Therefore, maintaining a balance between the number of reasoning steps and computational pressure is crucial.

### The effectiveness on step length in golden samples

Furthermore, to gain a nuanced understanding of the impact of Complex CoT when the number of steps exceeds the golden step number, we conduct further meta-analysis from @fu2023complexitybased [@shum2023automatic; @sun2023enhancing; @jiang2023resprompt]. Specifically, as illustrated in Figure [14](#fig:complex-cot-2){reference-type="ref" reference="fig:complex-cot-2"} (a, b), our analysis reveals that for problems of low complexity and with smaller golden step numbers, Complex CoT tends to underperform compared to Vanilla CoT. Notably, it is only when the reasoning steps exceed two that Complex CoT outperforms Vanilla CoT. This suggests that Complex CoT effectively optimizes single-step computations and enhances model performance for complex problems. However, it increases the cognitive load for simple problems, resulting in a performance decline.

Interestingly, this phenomenon is also observed with the simpler Vanilla CoT, as shown in Figure [14](#fig:complex-cot-2){reference-type="ref" reference="fig:complex-cot-2"} (c). The model achieves significant performance gains only when the number of reasoning steps aligns with the target output steps. If the complexity of the planned steps exceeds the necessary reasoning boundary, or if there is no effective optimization for reasoning boundary, the performance deteriorates.

<figure id="fig:complex-cot-2" data-latex-placement="t">
<embed src="figure/complex-cot-all-2.pdf" style="width:92.0%" />
<figcaption> The effectiveness of step length in golden samples with a fixed step length in demonstrations for CoT performance. </figcaption>
</figure>

<figure id="fig:marp-cot" data-latex-placement="t">
<embed src="figure/marp-cot.pdf" style="width:92.0%" />
<figcaption> Minimum acceptable reasoning path prompting for natural language chain-of-thought. All examples given in the context transform from <span class="citation" data-cites="wei2022chain"></span>. </figcaption>
</figure>

<figure id="exp:additional-exp" data-latex-placement="t">
<div class="minipage">
<div class="adjustbox">
<p><span>width=0.99</span></p>
<table>
<thead>
<tr>
<th style="text-align: left;">Model</th>
<th style="text-align: center;">Acc. (<span class="math inline">↑</span>)</th>
<th style="text-align: center;">Input Token (<span class="math inline">↓</span>)</th>
<th style="text-align: center;">Output Token (<span class="math inline">↓</span>)</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT</code></td>
<td style="text-align: center;">289.50</td>
<td style="text-align: center;">67.27</td>
<td style="text-align: center;">26.50</td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT+MARP</code></td>
<td style="text-align: center;">309.51</td>
<td style="text-align: center;">68.39</td>
<td style="text-align: center;">28.73</td>
</tr>
<tr>
<td style="text-align: left;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT</code></td>
<td style="text-align: center;">636.11</td>
<td style="text-align: center;">249.78</td>
<td style="text-align: center;">48.9</td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT-MRP</code></td>
<td style="text-align: center;">476.11</td>
<td style="text-align: center;">86.52</td>
<td style="text-align: center;">69.41</td>
</tr>
<tr>
<td style="text-align: left;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT</code></td>
<td style="text-align: center;">1046.28</td>
<td style="text-align: center;">225.35</td>
<td style="text-align: center;">63.90</td>
</tr>
<tr>
<td style="text-align: left;"><code>CoT+MARP</code></td>
<td style="text-align: center;">649.28</td>
<td style="text-align: center;">167.40</td>
<td style="text-align: center;">74.09</td>
</tr>
</tbody>
</table>
</div>
<p><span id="exp:additional-exp" data-label="exp:additional-exp"></span></p>
</div>
</figure>

### The Implementation Details of Minimum Acceptable Reasoning Paths {#append:heuristic-baselines}

To address the two aforementioned limitations, we propose Minimum Acceptable Reasoning Paths (MARP). Firstly, to reduce the model's computational load, we introduce instructions that limit its single-step computing power, thereby optimizing its reasoning boundary. Secondly, to enhance the model's acceptability, we increase the computation amount per step within this boundary and reduce the number of global planning steps, thus alleviating planning pressure.

To control variables effectively, we make only the simplest modifications to the prompt to achieve the desired CoT optimization.

#### Minimum Reasoning Path Prompting

To alleviate the cognitive load associated with planning, it is essential to have the model respond to the question as succinctly as possible. This approach ensures that the focus remains on providing a short, clear and direct reasoning path. The following prompt is designed to achieve this objective:

::: prompt
You need to perform multi-step reasoning, with each step carrying out as many basic operations as possible.
:::

#### Acceptable Reasoning Prompting

To effectively utilize the model, it is crucial to define the upper-bound of reasoning boundary. This ensures that the complexity of the reasoning process is manageable and within acceptable bounds. The specific prompt to achieve this is as follows:

::: prompt
Remember, you can only complete tasks that contain up to 5 basic operations per step, and multiplication operations must be less than 1.5e5. The upper limit of the multiplication operations decreases as the number of operations per step increases.
:::

This prompt is designed to set clear boundaries for the model's operations, thereby optimizing its performance and accuracy.

Furthermore, it is necessary to enhance the demonstration within the corresponding in-context learning framework to meet the specific needs of our Model-Agnostic Reasoning Protocol (MARP). This involves refining the examples and instructions provided to ensure they align perfectly with the MARP requirements. Figures [15](#fig:marp-cot){reference-type="ref" reference="fig:marp-cot"} and Figure [17](#fig:marp-pot){reference-type="ref" reference="fig:marp-pot"} illustrate our MARP prompt, showcasing how to structure the demonstrations to facilitate effective learning and reasoning in natural language CoT and program-of-thought setting. By adhering to these guidelines, we can ensure that the model operates efficiently and produces reliable results.

In summary, setting precise boundaries for reasoning boundary and optimizing in-context learning demonstrations are essential steps in enhancing the model's performance. By following the specified prompt and refining the MARP examples, we can achieve a high level of accuracy and efficiency in the model's reasoning processes.

<figure id="fig:marp-pot" data-latex-placement="t">
<embed src="figure/marp-cot.pdf" style="width:92.0%" />
<figcaption> Minimum acceptable reasoning path prompting for program-of-thought. All examples given in the context transform from <span class="citation" data-cites="wei2022chain"></span>. </figcaption>
</figure>

## The Implementation Details in various LLMs {#append:model}

We employ 25 commonly used models to evaluate the extensibility of our framework to a broader range of models. The specific models are listed in Table [\[exp:model\]](#exp:model){reference-type="ref" reference="exp:model"}. For each model, we utilize the chat/instruct version whenever available to maximize their ability to follow instructions. Additionally, we deploy all models on the vLLM [@kwon2023efficient] framework to ensure a fair comparison. Except for model OpenMath-series [@toshniwal2024openmathinstruct] which does not conform to the vLLM format, all other models are deployed on vLLM for testing. All experiments on open-source models were conducted on two A100 80G. Following the setting of @wei2022chain, in our CoT experiment, all multi-step reasoning tasks are with three manually constructed demonstrations. In addition, for all the experiments, our top-p is selected from $\{0.95, 1\}$, and temperature is selected from $[0,1]$.

In addition, the only difference in the prompt is that we use different dialogue delimiters to make it conform to the format of the LLM instruction fine-tuning, thereby avoiding the bias caused by the gap between training and inference.

:::: table\*
::: adjustbox
width=0.86

Model Base Model Parameters (B)

---

LLaMA [@touvron2023llama] \- 7, 13, 33, 65
LLaMA-2 [@touvron2023llama2] \- 7, 13, 70
LLaMA-3 [@touvron2023llama3] \- 8, 70
Code-LLaMA [@roziere2023code] LLaMA-2 [@touvron2023llama2] 7, 13, 34, 70
Mistral [@jiang2023mistral] \- 7

Gemini-1.0-Pro [@team2023gemini] \- \-
GPT3.5-Turbo [@openai2022gpt35] \- \-
Claude-3-Haiku [@anthropic2024claude3] \- \-
Claude-3-Sonnet [@anthropic2024claude3] \- \-
Claude-3-Opus [@anthropic2024claude3] \- \-
GPT4 [@openai2023gpt4] \- \-

MAmmoTH [@yue2023mammoth] LLaMA-2 [@touvron2023llama2] 7,13
MAmmoTH [@yue2023mammoth] Mistral [@jiang2023mistral] 7
OpenMATH-Instruct [@toshniwal2024openmathinstruct] LLaMA-2 [@touvron2023llama2] 70
OpenMATH-Instruct [@toshniwal2024openmathinstruct] Mistral [@jiang2023mistral] 7
:::
::::

## The Implementation of Combination Law in MGSM {#append:mgsm}

Inspired by @qin2023cross and @huang2023not, we propose that the multilingual mathematical CoT task comprises three sub-tasks: step planning, step calculation, and multi-modal expression. We evaluate the model's mathematical expression ability in different languages based on its zero-shot direct performance on MGSM, as reported by @qin2023cross. For relevant parameter calculations, please see the "Challenging Reasoning Boundary Measurement" part of Appendix [9.2](#append:tutorial){reference-type="ref" reference="append:tutorial"}. Formally, let step planning RB be denoted by $\mathcal{B}(  p)$, step calculation RB by $\mathcal{B}(c)$, and multilingual expression RB by $\mathcal{B}(l)$. The combined RB satisfies the following law: $$\begin{equation}
    \mathcal{B}^{\texttt{CoT}}(c, p, l) = \frac{1}{\frac{2N_{1}}{(\mathcal{B}(c)-b_1)} + \frac{2N_{2}}{(\mathcal{B}(p)-b_2)} + \frac{2N_{3}}{(\mathcal{B}(l)-b_3)}}.
    \label{eq:mgsm}
\end{equation}$$ As shown in Figure [8](#fig:mgsm){reference-type="ref" reference="fig:mgsm"}, the performance distribution of RB (including $\mathcal{B}_{Acc=90\%}$ and $\mathcal{B}_{Acc=10\%}$) in the multilingual mathematical reasoning task aligns with the proposed combination law in Equation [\[eq:mgsm\]](#eq:mgsm){reference-type="eqref" reference="eq:mgsm"}. Moreover, three distinct RBs are evident in Figure [8](#fig:mgsm){reference-type="ref" reference="fig:mgsm"}.

## Ethical Considerations {#append:ethical}

#### Data Access.

Our data is adapted from GSM8K [@cobbe2021training] and supplemented with manually created samples. GSM8K is an open-source dataset available for academic research.

#### Dataset Collection Process.

We began with an introductory task interview using 50 example questions, compensating participants \$20 each to familiarize themselves with the task. During the annotation process, annotators were paid \$15 per hour, totaling approximately 60 hours of work.

#### The Rest of Data Annotation Process.

For the remaining data annotation, we hired a graduate student with CET-6 proficiency in Chinese and English and strong mathematical knowledge. The student was compensated \$15 per hour, which is above the local average salary. The instructions for annotation are as follows:

::: prompt
  \
You need to annotate the generated number of steps, maximum computation amount, correctness of the generation steps, correctness of the calculations, and correctness of the model output:

- **Number of generated steps:** This refers to how many reasoning steps the model generated.

- **Maximum computation amount:** This indicates the largest product of operations in the model's reasoning steps.

- **Correctness of generation steps:** This assesses the accuracy of the model's planning. If all steps and operators are planned correctly, and the operand values are logically correct, it is considered correct, regardless of calculation accuracy.

- **Correctness of calculations:** This considers only whether the calculations are correct, ignoring planning factors.

- **Correctness of the output:** This checks whether the model's final answer is correct.

 
:::

# NeurIPS Paper Checklist {#neurips-paper-checklist .unnumbered}

1.  **Claims**

2.  Question: Do the main claims made in the abstract and introduction accurately reflect the paper's contributions and scope?

3.  Answer:

4.  Justification: As shown in lines 5-18 of the Abstract and 59-69 of the Introduction, we present our main claims and outline the paper's contributions and scope.

5.  Guidelines:
    - The answer NA means that the abstract and introduction do not include the claims made in the paper.

    - The abstract and/or introduction should clearly state the claims made, including the contributions made in the paper and important assumptions and limitations. A No or NA answer to this question will not be perceived well by the reviewers.

    - The claims made should match theoretical and experimental results, and reflect how much the results can be expected to generalize to other settings.

    - It is fine to include aspirational goals as motivation as long as it is clear that these goals are not attained by the paper.

6.  **Limitations**

7.  Question: Does the paper discuss the limitations of the work performed by the authors?

8.  Answer:

9.  Justification: We have discussed the limitations of our work in Section [\[sec:discussion\]](#sec:discussion){reference-type="ref" reference="sec:discussion"}.

10. Guidelines:
    - The answer NA means that the paper has no limitation while the answer No means that the paper has limitations, but those are not discussed in the paper.

    - The authors are encouraged to create a separate \"Limitations\" section in their paper.

    - The paper should point out any strong assumptions and how robust the results are to violations of these assumptions (e.g., independence assumptions, noiseless settings, model well-specification, asymptotic approximations only holding locally). The authors should reflect on how these assumptions might be violated in practice and what the implications would be.

    - The authors should reflect on the scope of the claims made, e.g., if the approach was only tested on a few datasets or with a few runs. In general, empirical results often depend on implicit assumptions, which should be articulated.

    - The authors should reflect on the factors that influence the performance of the approach. For example, a facial recognition algorithm may perform poorly when image resolution is low or images are taken in low lighting. Or a speech-to-text system might not be used reliably to provide closed captions for online lectures because it fails to handle technical jargon.

    - The authors should discuss the computational efficiency of the proposed algorithms and how they scale with dataset size.

    - If applicable, the authors should discuss possible limitations of their approach to address problems of privacy and fairness.

    - While the authors might fear that complete honesty about limitations might be used by reviewers as grounds for rejection, a worse outcome might be that reviewers discover limitations that aren't acknowledged in the paper. The authors should use their best judgment and recognize that individual actions in favor of transparency play an important role in developing norms that preserve the integrity of the community. Reviewers will be specifically instructed to not penalize honesty concerning limitations.

11. **Theory Assumptions and Proofs**

12. Question: For each theoretical result, does the paper provide the full set of assumptions and a complete (and correct) proof?

13. Answer:

14. Justification: Our work is not strictly a purely theoretical work, we provide more of an empirical formula. In addition, we analyze the source of our empirical formula in Appendix [9.6](#append:analysis){reference-type="ref" reference="append:analysis"} and provide the corresponding assumption and proof.

15. Guidelines:
    - The answer NA means that the paper does not include theoretical results.

    - All the theorems, formulas, and proofs in the paper should be numbered and cross-referenced.

    - All assumptions should be clearly stated or referenced in the statement of any theorems.

    - The proofs can either appear in the main paper or the supplemental material, but if they appear in the supplemental material, the authors are encouraged to provide a short proof sketch to provide intuition.

    - Inversely, any informal proof provided in the core of the paper should be complemented by formal proofs provided in appendix or supplemental material.

    - Theorems and Lemmas that the proof relies upon should be properly referenced.

16. **Experimental Result Reproducibility**

17. Question: Does the paper fully disclose all the information needed to reproduce the main experimental results of the paper to the extent that it affects the main claims and/or conclusions of the paper (regardless of whether the code and data are provided or not)?

18. Answer:

19. Justification: As shown in Appendix [9.3](#append:data-cons){reference-type="ref" reference="append:data-cons"} to Appendix [9.9](#append:mgsm){reference-type="ref" reference="append:mgsm"}, we have provided detailed descriptions and analyses of the experimental setups for all our investigations.

20. Guidelines:
    - The answer NA means that the paper does not include experiments.

    - If the paper includes experiments, a No answer to this question will not be perceived well by the reviewers: Making the paper reproducible is important, regardless of whether the code and data are provided or not.

    - If the contribution is a dataset and/or model, the authors should describe the steps taken to make their results reproducible or verifiable.

    - Depending on the contribution, reproducibility can be accomplished in various ways. For example, if the contribution is a novel architecture, describing the architecture fully might suffice, or if the contribution is a specific model and empirical evaluation, it may be necessary to either make it possible for others to replicate the model with the same dataset, or provide access to the model. In general. releasing code and data is often one good way to accomplish this, but reproducibility can also be provided via detailed instructions for how to replicate the results, access to a hosted model (e.g., in the case of a large language model), releasing of a model checkpoint, or other means that are appropriate to the research performed.

    - While NeurIPS does not require releasing code, the conference does require all submissions to provide some reasonable avenue for reproducibility, which may depend on the nature of the contribution. For example
      1.  If the contribution is primarily a new algorithm, the paper should make it clear how to reproduce that algorithm.

      2.  If the contribution is primarily a new model architecture, the paper should describe the architecture clearly and fully.

      3.  If the contribution is a new model (e.g., a large language model), then there should either be a way to access this model for reproducing the results or a way to reproduce the model (e.g., with an open-source dataset or instructions for how to construct the dataset).

      4.  We recognize that reproducibility may be tricky in some cases, in which case authors are welcome to describe the particular way they provide for reproducibility. In the case of closed-source models, it may be that access to the model is limited in some way (e.g., to registered users), but it should be possible for other researchers to have some path to reproducing or verifying the results.

21. **Open access to data and code**

22. Question: Does the paper provide open access to the data and code, with sufficient instructions to faithfully reproduce the main experimental results, as described in supplemental material?

23. Answer:

24. Justification: We will release our code in the official version of the subsequent paper to provide reproduction and provide more help to the future community.

25. Guidelines:
    - The answer NA means that paper does not include experiments requiring code.

    - Please see the NeurIPS code and data submission guidelines (<https://nips.cc/public/guides/CodeSubmissionPolicy>) for more details.

    - While we encourage the release of code and data, we understand that this might not be possible, so "No" is an acceptable answer. Papers cannot be rejected simply for not including code, unless this is central to the contribution (e.g., for a new open-source benchmark).

    - The instructions should contain the exact command and environment needed to run to reproduce the results. See the NeurIPS code and data submission guidelines (<https://nips.cc/public/guides/CodeSubmissionPolicy>) for more details.

    - The authors should provide instructions on data access and preparation, including how to access the raw data, preprocessed data, intermediate data, and generated data, etc.

    - The authors should provide scripts to reproduce all experimental results for the new proposed method and baselines. If only a subset of experiments are reproducible, they should state which ones are omitted from the script and why.

    - At submission time, to preserve anonymity, the authors should release anonymized versions (if applicable).

    - Providing as much information as possible in supplemental material (appended to the paper) is recommended, but including URLs to data and code is permitted.

26. **Experimental Setting/Details**

27. Question: Does the paper specify all the training and test details (e.g., data splits, hyperparameters, how they were chosen, type of optimizer, etc.) necessary to understand the results?

28. Answer:

29. Justification: As shown in Section [9.3](#append:data-cons){reference-type="ref" reference="append:data-cons"} to Section [9.8](#append:model){reference-type="ref" reference="append:model"}, we have provided detailed descriptions and analyses of the experimental setups for all our investigations.

30. Guidelines:
    - The answer NA means that the paper does not include experiments.

    - The experimental setting should be presented in the core of the paper to a level of detail that is necessary to appreciate the results and make sense of them.

    - The full details can be provided either with the code, in appendix, or as supplemental material.

31. **Experiment Statistical Significance**

32. Question: Does the paper report error bars suitably and correctly defined or other appropriate information about the statistical significance of the experiments?

33. Answer:

34. Justification: We report error bars in Table [\[exp:main-exp\]](#exp:main-exp){reference-type="ref" reference="exp:main-exp"} and Figure [4](#fig:nature){reference-type="ref" reference="fig:nature"}, and explain the error variables in Section [\[sec:setting\]](#sec:setting){reference-type="ref" reference="sec:setting"}. However, error bars are not reported for all tasks because it would be too expensive for human annotation and computational resource consumption.

35. Guidelines:
    - The answer NA means that the paper does not include experiments.

    - The authors should answer \"Yes\" if the results are accompanied by error bars, confidence intervals, or statistical significance tests, at least for the experiments that support the main claims of the paper.

    - The factors of variability that the error bars are capturing should be clearly stated (for example, train/test split, initialization, random drawing of some parameter, or overall run with given experimental conditions).

    - The method for calculating the error bars should be explained (closed form formula, call to a library function, bootstrap, etc.)

    - The assumptions made should be given (e.g., Normally distributed errors).

    - It should be clear whether the error bar is the standard deviation or the standard error of the mean.

    - It is OK to report 1-sigma error bars, but one should state it. The authors should preferably report a 2-sigma error bar than state that they have a 96% CI, if the hypothesis of Normality of errors is not verified.

    - For asymmetric distributions, the authors should be careful not to show in tables or figures symmetric error bars that would yield results that are out of range (e.g. negative error rates).

    - If error bars are reported in tables or plots, The authors should explain in the text how they were calculated and reference the corresponding figures or tables in the text.

36. **Experiments Compute Resources**

37. Question: For each experiment, does the paper provide sufficient information on the computer resources (type of compute workers, memory, time of execution) needed to reproduce the experiments?

38. Answer:

39. Justification: As shown in Section [\[sec:setting\]](#sec:setting){reference-type="ref" reference="sec:setting"} and Appendix [9.8](#append:model){reference-type="ref" reference="append:model"}, we provide detailed model compute resources under different settings.

40. Guidelines:
    - The answer NA means that the paper does not include experiments.

    - The paper should indicate the type of compute workers CPU or GPU, internal cluster, or cloud provider, including relevant memory and storage.

    - The paper should provide the amount of compute required for each of the individual experimental runs as well as estimate the total compute.

    - The paper should disclose whether the full research project required more compute than the experiments reported in the paper (e.g., preliminary or failed experiments that didn't make it into the paper).

41. **Code Of Ethics**

42. Question: Does the research conducted in the paper conform, in every respect, with the NeurIPS Code of Ethics <https://neurips.cc/public/EthicsGuidelines>?

43. Answer:

44. Justification: We are convinced that we comply with NeurIPS Code of Ethics.

45. Guidelines:
    - The answer NA means that the authors have not reviewed the NeurIPS Code of Ethics.

    - If the authors answer No, they should explain the special circumstances that require a deviation from the Code of Ethics.

    - The authors should make sure to preserve anonymity (e.g., if there is a special consideration due to laws or regulations in their jurisdiction).

46. **Broader Impacts**

47. Question: Does the paper discuss both potential positive societal impacts and negative societal impacts of the work performed?

48. Answer:

49. Justification: We have discussed the broader impacts of our work in Section [\[sec:discussion\]](#sec:discussion){reference-type="ref" reference="sec:discussion"}. In addition, since our work is more like providing an empirical formula and has no additional social harmfulness, we do not discuss this part.

50. Guidelines:
    - The answer NA means that there is no societal impact of the work performed.

    - If the authors answer NA or No, they should explain why their work has no societal impact or why the paper does not address societal impact.

    - Examples of negative societal impacts include potential malicious or unintended uses (e.g., disinformation, generating fake profiles, surveillance), fairness considerations (e.g., deployment of technologies that could make decisions that unfairly impact specific groups), privacy considerations, and security considerations.

    - The conference expects that many papers will be foundational research and not tied to particular applications, let alone deployments. However, if there is a direct path to any negative applications, the authors should point it out. For example, it is legitimate to point out that an improvement in the quality of generative models could be used to generate deepfakes for disinformation. On the other hand, it is not needed to point out that a generic algorithm for optimizing neural networks could enable people to train models that generate Deepfakes faster.

    - The authors should consider possible harms that could arise when the technology is being used as intended and functioning correctly, harms that could arise when the technology is being used as intended but gives incorrect results, and harms following from (intentional or unintentional) misuse of the technology.

    - If there are negative societal impacts, the authors could also discuss possible mitigation strategies (e.g., gated release of models, providing defenses in addition to attacks, mechanisms for monitoring misuse, mechanisms to monitor how a system learns from feedback over time, improving the efficiency and accessibility of ML).

51. **Safeguards**

52. Question: Does the paper describe safeguards that have been put in place for responsible release of data or models that have a high risk for misuse (e.g., pretrained language models, image generators, or scraped datasets)?

53. Answer:

54. Justification: The paper poses no such risks.

55. Guidelines:
    - The answer NA means that the paper poses no such risks.

    - Released models that have a high risk for misuse or dual-use should be released with necessary safeguards to allow for controlled use of the model, for example by requiring that users adhere to usage guidelines or restrictions to access the model or implementing safety filters.

    - Datasets that have been scraped from the Internet could pose safety risks. The authors should describe how they avoided releasing unsafe images.

    - We recognize that providing effective safeguards is challenging, and many papers do not require this, but we encourage authors to take this into account and make a best faith effort.

56. **Licenses for existing assets**

57. Question: Are the creators or original owners of assets (e.g., code, data, models), used in the paper, properly credited and are the license and terms of use explicitly mentioned and properly respected?

58. Answer:

59. Justification: The paper does not use existing assets.

60. Guidelines:
    - The answer NA means that the paper does not use existing assets.

    - The authors should cite the original paper that produced the code package or dataset.

    - The authors should state which version of the asset is used and, if possible, include a URL.

    - The name of the license (e.g., CC-BY 4.0) should be included for each asset.

    - For scraped data from a particular source (e.g., website), the copyright and terms of service of that source should be provided.

    - If assets are released, the license, copyright information, and terms of use in the package should be provided. For popular datasets, [paperswithcode.com/datasets](paperswithcode.com/datasets){.uri} has curated licenses for some datasets. Their licensing guide can help determine the license of a dataset.

    - For existing datasets that are re-packaged, both the original license and the license of the derived asset (if it has changed) should be provided.

    - If this information is not available online, the authors are encouraged to reach out to the asset's creators.

61. **New Assets**

62. Question: Are new assets introduced in the paper well documented and is the documentation provided alongside the assets?

63. Answer:

64. Justification: The paper does not release new assets.

65. Guidelines:
    - The answer NA means that the paper does not release new assets.

    - Researchers should communicate the details of the dataset/code/model as part of their submissions via structured templates. This includes details about training, license, limitations, etc.

    - The paper should discuss whether and how consent was obtained from people whose asset is used.

    - At submission time, remember to anonymize your assets (if applicable). You can either create an anonymized URL or include an anonymized zip file.

66. **Crowdsourcing and Research with Human Subjects**

67. Question: For crowdsourcing experiments and research with human subjects, does the paper include the full text of instructions given to participants and screenshots, if applicable, as well as details about compensation (if any)?

68. Answer:

69. Justification: As shown in Section [9.10](#append:ethical){reference-type="ref" reference="append:ethical"}, We describe and analyze the details and ethical considerations of our crowdsourcing in detail.

70. Guidelines:
    - The answer NA means that the paper does not involve crowdsourcing nor research with human subjects.

    - Including this information in the supplemental material is fine, but if the main contribution of the paper involves human subjects, then as much detail as possible should be included in the main paper.

    - According to the NeurIPS Code of Ethics, workers involved in data collection, curation, or other labor should be paid at least the minimum wage in the country of the data collector.

71. **Institutional Review Board (IRB) Approvals or Equivalent for Research with Human Subjects**

72. Question: Does the paper describe potential risks incurred by study participants, whether such risks were disclosed to the subjects, and whether Institutional Review Board (IRB) approvals (or an equivalent approval/review based on the requirements of your country or institution) were obtained?

73. Answer:

74. Justification: Since our region and institution are not required to provide IRB approval, we do not describe this section. We are convinced that our work complies with the NeurIPS Code of Ethics and the guidelines.

75. Guidelines:
    - The answer NA means that the paper does not involve crowdsourcing nor research with human subjects.

    - Depending on the country in which research is conducted, IRB approval (or equivalent) may be required for any human subjects research. If you obtained IRB approval, you should clearly state this in the paper.

    - We recognize that the procedures for this may vary significantly between institutions and locations, and we expect authors to adhere to the NeurIPS Code of Ethics and the guidelines for their institution.

    - For initial submissions, do not include any information that would break anonymity (if applicable), such as the institution conducting the review.

[^1]: Corresponding Author

[^2]: See detailed analysis for these two strategies in Appendix [9.6](#append:analysis){reference-type="ref" reference="append:analysis"}.

[^3]: The basic form $\mathcal{B}(t_i|m)$ and the combined form $\mathcal{B}(+\infty, \dots, +\infty, t_i, +\infty, \dots, +\infty|m)$ are not completely equivalent.

[^4]: https://huggingface.co/dslim/bert-base-NER
