# Abstract

Large Language Models (LLMs), particularly smaller variants, still struggle with complex reasoning tasks. While inference-time prompting can guide reasoning, existing methods often rely on sequential queries. Ensemble approaches offer a promising path to performance gains, especially given recent batch inference speed-ups. This work introduces Dipper, a novel, training-free framework that transforms a single LLM into an effective inference-time ensemble. By feeding the model an optimized and diverse set of prompts in parallel, Dipper elicits varied reasoning paths, leading to performance gains. We empirically demonstrate significant improvements on reasoning benchmarks, such as MATH, where a Dipper ensemble of three Qwen2-MATH-1.5B instances (via parallel prompting of a single model) outperforms a larger 7B model.

# Introduction

Despite remarkable advancements, Large Language Models (LLMs), particularly smaller models that are often constrained by resource limitations (e.g., GPU memory), continue to struggle with complex reasoning tasks [huangReasoningLargeLanguage2023]. While inference-time methods offers a promising approach for enhancing LLM performance, especially for these smaller models [snellScalingLLMTestTime2024], existing methods like Chain-of-Thought (CoT) and Reflexion often rely on _sequential_ LLM queries, thereby incurring additional latency costs [qiaoReasoningLanguageModel2023; zhengProgressiveHintPromptingImproves2023; yaoTreeThoughtsDeliberate2023].

Ensemble methods, which involve the use of multiple constituent models in _parallel_, have been shown to improve models' performance and robustness in classical machine-learning settings [ganaieEnsembleDeepLearning2022a] and are promising approaches to achieve better inference-time performance, although less well-studied in the LLM setting. The prospects of applying such methods to LLMs are increasingly attractive, given recent developments that have enabled significant speed-ups in parallel, LLM batch inference. These include methods to efficiently handle key-value cache memory [kwonEfficientMemoryManagement2023] and prompt caching to efficiently reuse common prompts for multiple queries [zhuEfficientPromptCaching2024; gimPromptCacheModular2024], enabling sub-linear (in the number of queries) costs for batch inference. However, a key challenge for successful ensembles is the **diversity** among their constituents [kroghNeuralNetworkEnsembles1994; zaidiNeuralEnsembleSearch2020]. This principle extends to LLM ensembles, where achieving meaningful diversity from a single base model remains a central challenge.

Current approaches injecting such diversity, such as using heterogeneous model types (i.e., different LLMs) [jiangLLMBlenderEnsemblingLarge2023; huangEnsembleLearningHeterogeneous2024], are often impractical due to memory constraints or use preferences for a single model type. Alternatively, methods like self-consistency, which rely on stochastic sampling from the same prompt [wang2023selfconsistency], typically yield limited diversity, thereby capping potential performance gains. We identify an influential yet overlooked source of diversity: **system prompts**. LLMs can generate varied reasoning pathways and outputs for the same task when guided by different instructional prompts [kojimaLargeLanguageModels2023]. This observation motivates our central research question: _How can we systematically leverage prompt diversity to construct high-performing LLM ensembles from a single base model efficiently, without model retraining?_

To address this, we introduce Dipper, a novel, training-free LLM ensemble framework that constructs an LLM ensemble by feeding a single base LLM an optimized, diverse set of reasoning prompts in parallel. This approach harnesses the parallel processing capabilities of modern LLM inference systems to achieve significant performance improvements in reasoning tasks, particularly for resource-constrained models. Dipper is notably simple, resource-efficient, and readily applicable to any black-box LLM via API access. Our key contributions are summarized as follows:

- We propose Dipper, a novel framework for constructing inference-time ensembles from a single LLM using diverse reasoning prompts, adaptable to any (including black-box) LLM, and detail its core design principles (Sec. 4).

- We develop a training-free, theory-inspired prompt diversity measure that, when used with our framework, can be efficiently optimized to maximize ensemble performance (Sec. 4.3).

- We empirically demonstrate that our framework produces significant performance gains on math reasoning tasks (MATH, GSM8K, and MMLU-STEM), where our ensemble consisting of just a few small models (e.g., three Qwen2-MATH-1.5B) can outperform a larger model (e.g., Qwen2-MATH-7B) (Sec. 5).

# Background and related works

#### LLMs and prompts.

Consider an LLM $M$ which can be viewed as a black box that encodes conditional probability distribution of text responses $y$ over any text input $q$ and prompt $w$, from which we can sample response $\hat{y}$, i.e.

```latex
$$\hat{y} \sim M(q,w) = p_M(y|q,w).$$
```

In practice, $w$ can be reasoning prompts that instruct LLMs to reason about $q$, e.g., "Let's think step by step" in CoT [weiChainofThoughtPromptingElicits2023]. These prompts aim to influence the final LLM response, potentially by inducing additional LLM output (e.g., reasoning steps), and have been shown to yield performance boosts.

#### Prompt optimization.

To alleviate manual effort of prompt engineering, prompt optimization [zhou2023large; lin2023use; yang2024large; hu2024localized] works aim to automatically search for optimal prompts to maximize an LLM's performance on specific tasks. However, such works have mainly focused on finding the best prompt for a single LLM, leaving the potential of optimizing prompts for LLM ensembles underexplored. In contrast, our work proposes a broader, novel framework for designing inference-time LLM ensembles with diverse prompts, and can incorporate existing prompt optimization methods. For example, we showed that an optimized prompt (e.g., "self-reflection" [shinn2024reflexion]) can be combined with our framework.

#### LLM ensembles.

Ensemble methods, which combine multiple models to achieve superior performance and robustness [ganaieEnsembleDeepLearning2022a], have seen limited application in the LLM domain. Prior LLM ensemble works have focused on heterogeneous ensembles that combine outputs from different LLM architectures or API providers [jiangLLMBlenderEnsemblingLarge2023], multi-agent LLM settings that focus on interactions among agents [duImprovingFactualityReasoning2023; liuDynamicLLMAgentNetwork2023; chenAgentVerseFacilitatingMultiAgent2023], or homogeneous self-ensembles that generate multiple responses from a single LLM using stochastic sampling [wang2023selfconsistency].

However, to the best of our knowledge, we are not aware of any work that has proposed forming and optimizing homogeneous LLM ensembles where their _diversity is injected through varying reasoning prompts_ to constituents with the same underlying LLM model. Our work's focus on such an approach exploits LLMs' unique capabilities of generating diverse output given only changes to their prompts, allowing for a simple but effective method to achieve significant training-free boosts to LLM reasoning performance using inference-time compute, especially given recent developments in LLM batch inference methods [kwonEfficientMemoryManagement2023; zhuEfficientPromptCaching2024; gimPromptCacheModular2024].

# Problem formulation

Consider a task $\mathcal{T}$ with instances described as tuples $t\coloneq (q_t,c^{*}_t)$, where $q_t$ is a text query and $c^{*}_t$ is the corresponding solution. We denote the response from a single LLM $M$ as $\hat{y} \coloneq \{\hat{r},\hat{c}\}$ which consists of its reasoning $\hat{r}$ and final answer $\hat{c}$. We evaluate the performance of the model with a specific prompt $w$, denoted as $M(\cdot,w)$, on the task by computing its expected accuracy over the set of task instances $\mathcal{T}$, i.e., $F(M(\cdot, w);\mathcal{T}) \coloneq \mathbf{E}_{t \sim \mathcal{T}} [\mathbb{I}\{\hat{c}_t= c^{*}_t\} ]$, which in practice is computed over a representative test set.

We denote a homogeneous LLM ensemble as $\mathcal{E}(\cdot\,; M,n, \phi)$, consisting of $n$ instances of the same model $M$ and in general has an adjustable inference-time design parameter $\phi$. The ensemble produces a final answer when provided a task query, i.e., $\mathcal{E}(q_t;M,n,\phi) \rightarrow \hat{c}_t$, and we can evaluate its performance based on its expected accuracy:

```latex
$$F(\mathcal{E},\mathcal{T}) = \mathbf{E}_{t \sim \mathcal{T}} [\mathbb{I}\{\mathcal{E}(q_t;M,n,\phi) = c^{*}_t\} ].$$
```

Our objective is to design an ensemble framework with an appropriate design parameter $\phi$ such that given fixed $M$, $n$ and a small labeled development set, we can efficiently maximize the objective by optimizing for $\phi$ to produce the best performing ensemble without additional training.

# Method

A key driver of the ensemble's performance is the diversity present among the constituents in the ensemble. Intuitively, a group where every member thinks the same way as each other is likely to result in less robust reasoning and decision-making (e.g. "groupthink") compared to a group consisting of members with diverse thinking styles. Similarly, having an ensemble of LLM instances where _all constituents are identical_ may be expected to yield less performance advantage compared to a diversified ensemble. In our setting where only a single LLM model is available, self-ensembles [wang2023selfconsistency] are examples of the former, as the constituents rely on LLM sampling stochasticity to generate potentially diverse responses, but will nonetheless still be sampling from the same distribution and hence face limited diversity. Our framework for LLM ensembles, Dipper, efficiently introduces such diversity at inference time even when only one LLM model is available, through the use of high fidelity, diverse prompts.

In this section, we first provide an overview of our framework Dipper, before elaborating on the various components.

## Overview of the Dipper framework

Drawing inspiration from how using different prompts $w$ would result in varying response distributions given the same model $M$, our Dipper framework has the set of prompts $\{w_i\}_{i=1}^n$ fed into the ensemble of $n$ LLM instances as the key ensemble design parameter $\phi$.

Dipper consists of the following three components:

1.  **Prompt Generator.** First, an LLM generates a large candidate pool of prompts (denoted as $\mathcal{W}$), which can be based on some description of the task and in-context prompt examples that we think may be effective, if such prior knowledge is available. The goal is for the prompts to invoke various types of reasoning pathways when addressing queries, hence injecting diversity into the ensemble.

2.  **Prompt Selector.** Drawing parallel to data/prompt selection [wu2024prompt; wang2025nice; chen2025duet; pinnacle; pied], we select a subset of $n$ prompts $\{w_i \in \mathcal{W}\}_{i=1}^n$ from the candidate pool of prompts $\mathcal{W}$, where the selection is optimized based on a diversity metric that acts as an approximation of the relative performance of each subset.

3.  **Response Aggregator.** Finally, the responses from the $n$ constituent LLMs are aggregated through a response aggregator operation $\mathcal{A}$ to produce a single final response for the ensemble.

Putting everything together, our Dipper framework characterizes an ensemble of size $n$ via $\mathcal{E}(q_t;M,n,\{w_i\}_{i=1}^n) \coloneq \mathcal{A}(\{M(q_t,w_i)\}_{i=1}^n) \rightarrow \hat{c}_t$, where the subset of prompts $\{w_i\}_{i=1}^n$ is chosen from a candidate pool $\mathcal{W}$ to optimize the expected ensemble performance $F(\mathcal{E},\mathcal{T})$ for a target task $\mathcal{T}$. We now describe each component in detail.

## Prompt Generator

The first component plays the important role of generating a large pool of candidate prompts with the following desiderata:

1.  **Fidelity.** Each prompt should be able to influence the LLM into applying a certain type of reasoning approach to the task without significantly degrading the task performance.

2.  **Diversity.** The prompts should differ sufficiently to elicit various reasoning pathways and provide a diverse selection pool for the subsequent component.

We first show that LLMs are capable of generating prompts that meet these desiderata, via the most direct way of prompting it to generate a pool of candidate prompts while providing it with exemplars illustrating different reasoning prompts. To do so, we considered a list of 7 reasoning prompts inspired by existing works [wangSelfConsistencyImprovesChain2023; deng2023rephrase; yao2022react] on prompting methods to boost reasoning capabilities. Given these prompts as exemplars, we used GPT-4o to further generate a set of 200 different candidate prompts that each represent a different reasoning approach (details in Appx. 7.1).

[IMAGE: The accuracy distribution of 200 candidate prompts on MATH with Qwen2-MATH-1.5B.]

Figure 1 shows the distribution of average accuracy over a sampled test set of MATH [hendrycks2021measuring] questions for each prompt, when used with the Qwen2-MATH-1.5B model. Note that the distribution of accuracy is largely higher than that of the base model without prompts, and similar to the accuracies achieved by the reasoning prompt exemplars, demonstrating the fidelity requirement. Qualitatively, we see that the prompts are also relatively diverse -- they generally specify certain reasoning approaches inspired by various subject domains (see Appx. 9.6). We will quantify this diversity in Sec. 4.3 with our proposed metric.

Note that when generating the prompts, we did not pass any task description to the LLM prompt generator. We did so as the reasoning prompts can be task-agnostic. In practice, the candidate pool of reasoning prompts need not be generated on-the-fly, but can be drawn from a shared pool prepared beforehand by a more powerful LLM, to be used by ensembles consisting of much smaller LLMs, as we demonstrated. The actual selection of relevant prompts from this larger pool can then be done by the prompt selector component, which we will describe next in Sec. 4.3.

## Prompt Selector

With our framework, the optimization problem reduces to an optimization to choose the best subset of prompts $\{w_i\}_{i=1}^n$ from the set of candidate prompts $\mathcal{W}$:

```latex
$$\mathop{\mathrm{arg\,max}}_{\{w_i \in \mathcal{W}\}_{i=1}^n} F(\mathcal{E}(q_t;M,n,\{w_i\}_{i=1}^n), \mathcal{T}).$$
```

Unfortunately, directly optimizing this objective is a combinatorial problem that is very challenging, even if a development/validation set is available for the task of interest. For example, selecting 5 prompts from a candidate pool of 200 prompts involves searching over ${200 \choose 5} \approx 2.5 \times 10^9$ candidates. Instead, we note that the best ensemble composition requires a balance of the two desiderata: fidelity and diversity. Hence, we propose optimizing this objective by considering how to prioritize the prompts that have the best predicted performance on the task $\mathcal{T}$, while maximizing the diversity of the selected set of prompts. Our method draws inspiration from past works on determinantal point processes (DPP) [kuleszaDeterminantalPointProcesses2012; lau2025uncertainty], which consider similarity kernels comprising separate quality and diversity terms that match our requirements.

#### Prompt fidelity.

First, we can approximate the predicted performance of each prompt by its average performance on a task development set $\mathcal{T}_d$. Note that as inference using these various prompts on a small development set can be done in parallel, this process can in practice be significantly sped up by existing batch inference techniques such as those employed by vLLM [kwonEfficientMemoryManagement2023].

Specifically, for a candidate pool of prompts $\mathcal{W}$ and development set $\mathcal{T}_d$, we can define a prompt fidelity mapping $u:\mathcal{W}\rightarrow [0,1]$:

```latex
$$u(w) \coloneq F(M(\cdot,w),\mathcal{T}_d),$$
```

where $M(\cdot,w)$ is the LLM model conditioned by prompt $w\in \mathcal{W}$, and $F$ the expected accuracy defined in Sec. 3. In practice, for a candidate pool of size $n$, $u(w)$ can be represented as an $n \times 1$ column vector, with the elements representing each prompt's expected accuracy.

#### Semantic entropy.

Then, we measure prompt diversity by considering how different the semantic meanings of the $n$ role prompts are from each other. We represent each prompt's semantic meaning with a mapping $R$ from its text representation $w$ into a normalized continuous vector $s\in \mathbb{R}^{p}$ in a $p$-dimensional semantic embedding space $\mathcal{S}$ through a sentence embedding model $M_s$ [reimers-2019-sentence-bert], i.e., $R(w)\coloneq M_s(w)$. This mapping can be represented as an $n\times p$ prompt embedding matrix $R = [s_1,\cdots,s_n]$ where $s$ is a $1\times p$ row vector representing each prompt.

To quantify prompt diversity of a given set of prompts, we propose to compute the volume enclosed by the selected prompts in semantic space. Intuitively, for $n$ fixed prompts, more diverse prompts point to more varied directions in semantic space, and enclose a larger volume. Specifically, we note that from basic geometry, the determinant of a Gram matrix is the squared volume of the parallelepiped spanned by the embedding vectors. Hence, we define the semantic volume metric $V$ as:

```latex
$$V\coloneq \log \det (RR^T),$$
```

where we take the logarithm (for numerical stability) of the Gram matrix determinant. Sec. 9.5 shows how sets of prompts that are qualitatively observed to be more diverse have larger quantitative semantic volume.

#### Fidelity-adjusted semantic volume (FASV).

To incorporate the prompts' expected accuracy information, we can compute the performance-adjusted prompt embedding matrix:

```latex
$$\Tilde{R}\coloneq \exp({\frac{\alpha}{2} \mathop{\mathrm{diag}}(u)})R,$$
```

where $\mathop{\mathrm{diag}}(u)$ is the diagonal matrix with its $i^\text{th}$ diagonal element being the corresponding element $u_i$. This essentially scales each row $s_i$ in $R$ by an exponential factor based on its corresponding predicted accuracy, $\exp({\frac{\alpha}{2} u_i})$, where $\alpha$ is a scalar hyperparameter influencing the balance between diversity and expected performance. Intuitively, prompts with higher expected accuracy would then be able to support larger semantic volume and hence be prioritized for inclusion into the ensemble. The adjusted embedding matrix can then be used to compute the semantic volume, which simplifies to:

```latex
$$\tilde{V} = \log \det (\tilde{R}\tilde{R}^T) = V+ \alpha \|u\|_{1},$$
```

providing an interpretable expression illustrating the balance between the diversity (i.e., the semantic volume metric) and fidelity desiderata (i.e., the L1 norm of the prompt fidelity metric) that needs to be optimized for the ensemble. Derivation details are in Appendix 8, and we provide empirical analysis of the effectiveness of this combined metric in Sec. 5.3.

#### Algorithm: Greedy Prompt Selection

**Input:** LLM model $M$, Initial candidate prompt set $\bar{\mathcal{W}}$, Semantic embedding model $M_s$, Development set $\mathcal{T}_d$, Ensemble size $n$, Fidelity-diversity hyperparam $\alpha$

**Output:** Ensemble prompt set $\mathcal{Z}$

1. Initialize $\mathcal{Z} \gets \{\ \}$
2. Compute fidelity scores $\bar{u}(w) \gets [F(M(\cdot,w_i),\mathcal{T}_d) \text{ for } w_i \in \bar{\mathcal{W}}]$
3. Select best prompt: $\mathcal{Z} \gets \mathcal{Z} \cup \arg\max_{w} \bar{u}(w)$
4. Update candidate set: $\mathcal{W}\gets \bar{\mathcal{W}} \setminus \arg\max_{w} \bar{u}(w)$
5. For each remaining prompt to select:
   - For each candidate $w_k$ in $\mathcal{W}$:
     - Form potential set $\mathcal{P} \gets \mathcal{Z} \cup w_k$
     - Compute fidelity $u(w) \gets [F(M(\cdot,w_i),\mathcal{T}_d) \text{ for } w_i \in \mathcal{P}]$
     - Compute embeddings $R(w) \gets [M_s(w_i) \text{ for } w_i \in \mathcal{P}]$
     - Compute FASV: $\Tilde{V}_{w_k} \gets \log \det (RR^T) + \alpha \|u\|_{1}$
   - Select prompt maximizing FASV: $\mathcal{Z} \gets \mathcal{Z} \cup \arg\max_{w} \Tilde{\mathcal{V}}(w)$
   - Update candidate set: $\mathcal{W}\gets \mathcal{W}\setminus \arg\max_{w} \Tilde{\mathcal{V}}(w)$
6. Return $\mathcal{Z}$

#### Optimization of semantic entropy.

We can now recast the objective as an optimization of the fidelity-adjusted semantic volume metric $\tilde{V}$ evaluated over the set of candidate prompts. Note that instead of the expected ensemble performance $F(\mathcal{E})$, which is an objective that can only be optimized by blackbox optimization methods like Bayesian Optimization [BObook; qbo; readme], our metric $\tilde{V}$ can be efficiently approximated by well-established heuristics.

Specifically, as the semantic volume metric is submodular, we can optimize for the best subset of roles by incrementally building the subset with a greedy approach up to the desired size $n$ and still be guaranteed a good approximation [submodular]. This is an important advantage that allows us an efficient and theoretically-inspired approach to obtain the best ensemble prompts. Our proposed algorithm is outlined above.

## Response Aggregator

Given the responses from the various LLMs of constituents, the aggregation method determines how much information from the constituents is used to derive the final output of the ensemble. We consider the two most popular approaches:

#### Majority voting (MV)

It involves extracting the final answer $\hat{c}$ from each LLM response $\hat{y}=\{\hat{r},\hat{c}\}$, and selecting the answer that has been proposed the most number of times. This approach does not evaluate the quality of reasoning $\hat{r}$ output produced by each LLM, but is easily implementable.

#### Best-of-N

An external reward model is implemented to evaluate the response $\hat{y}$ of each agent, and the response with the highest score is selected as the final response. This approach does not leverage consensus among constituents but could be effective in identifying the correct responses that would be only covered by a few agents.

# Experiments

**Experimental set-up.** We empirically evaluate our framework on mathematically reasoning tasks with the MATH [hendrycks2021measuring], GSM8K, and MMLU-STEM datasets. We implement our framework using the GPT-4o as our prompt generator and Qwen2-MATH-1.5B as the constituent model in the ensemble, where the ensemble constituents are run in parallel using vLLM [kwonEfficientMemoryManagement2023] for fast batch inference. Further details (Appx. 7) and additional results (Appx. 9) are in the Appendix.

#### Baselines.

We evaluate our Dipper framework by comparing it against the "Self-ensemble" method, which lacks prompt diversity but incorporates diversity through repeated response sampling [wang2023selfconsistency], along with the single model performance as a reference. We also include two other implementation variants of Dipper in our analysis, beyond the implementation based on semantic volume, "Dipper (FASV)":

1.  **Random+.** Here we randomly sample prompts from the candidate pool based on a probability distribution proportional to their predicted accuracy, i.e., $p(w) \propto u(w)$. This aims to achieve diversity through the sampling process while prioritizing prompts with higher predicted accuracy.

2.  **Top-n.** Here we greedily select the top $n$ prompts which are ranked based on their predicted accuracy $u(w)$. It assumes that the diversity of prompts introduced by our prompt generation process is sufficient and hence does not explicitly optimize for ensemble diversity during the prompt selection phase.

[IMAGE: Comparison of different ensembles of 7 reasoning prompts on MATH.]

[IMAGE: Accuracy vs. average number of unique answers using different numbers of prompts in ensembles.]

## Ensembles with fixed prompt methods

To motivate our Dipper framework and demonstrate the importance of prompt diversity, we first consider a fixed set of seven distinct reasoning prompts inspired by existing works [wangSelfConsistencyImprovesChain2023; deng2023rephrase; yao2022react] (details in Appx. 7.1). With a fixed ensemble size of seven, Figure 2 shows that an ensemble using these seven different prompts (57.31%) outperforms both a baseline self-ensemble without prompt variation (55.76%) and the average performance (56.55%) of seven self-ensembles, each using only one of the distinct prompts.

In addition, we evaluated the impact of prompt diversity by constructing ensembles with varying numbers of unique prompts (from one to seven) drawn from this set, while maintaining an ensemble size of seven. When fewer than seven unique prompts were used, responses were randomly sampled to meet the ensemble size. The result in Figure 3 indicates that increasing the number of unique prompts generally leads to higher accuracy and reduced variance. This suggests that prompt diversity within an ensemble can enhance performance and consistency, particularly when the performances of prompts are unknown before the final evaluation.

[IMAGE: Comparison of different ensemble methods on MATH for the LLaMA3.2B model.]

## Ensembles with optimized prompt diversity

Next, we consider our full Dipper framework. We first generate a pool of prompt candidates ($|\mathcal{W}|=200$) using the 7 reasoning prompts in the previous section as in-context exemplars (details in Appx. 7.1) and then perform prompt fidelity-diversity optimization (Sec. 4.3) to select the best ensemble prompts. As shown in Figure 4, our full Dipper implementation with FASV achieves the highest accuracy compared to the self-ensemble baseline and all other Dipper variants across various ensemble sizes. Dipper also significantly outperforms the single LLM. For example, Dipper with $n=9$ has close to a 10%-pt increase (~20% accuracy gain) compared to the single LLM baseline. In fact, our ensemble that consists of just 3 Qwen2-MATH-1.5B models already (slightly) outperforms the next model size class, the Qwen2-MATH-7B model. Note also that the performance gain of Dipper over the self-consistency baseline is about as large as the gain from moving up one model class (from the 1.5B to 7B model). We see similar results on MATH with the general model LLaMA3.2B, where Dipper(FASV) is shown consistently effective. Refer to Appendix 9 for more results for other datasets (e.g., GSM8K, MMLU-STEM, BIG-Bench) and models.

## Fidelity-diversity optimization

To further understand the mechanisms behind Dipper's performance gains, we analyze the predictive power of our fidelity-adjusted semantic volume metric (which we denote as $V$ in this section for notational simplicity) on the final ensemble performance on the test set $F(\mathcal{E})$. We quantify this by computing the Spearman correlation between $V$ and $F(\mathcal{E})$: the higher the Spearman correlation, the better our optimization of the ensemble prompts via $V$ will lead to higher ensemble test performance. Figure 5 shows the Spearman correlation of $V$ and $F(\mathcal{E})$ for the MATH dataset experiment, with different fidelity-diversity hyperparameter $\alpha$ values. We can observe two key insights.

[IMAGE: Spearman correlation between V and test performance F(E) on the MATH under different fidelity-diversity hyperparameter alpha.]

[IMAGE: The scatter plot showing correlation between V and F(E) for different prompt candidates.]

First, there is a relatively strong positive correlation between $V$ and $F(\mathcal{E})$, going as high as $0.8$ for some values of $\alpha$. This corroborates our main results where our Dipper method that explicitly optimizes for $V$ outperforms other baselines and achieves higher $F(\mathcal{E})$.

Second, there is a U-shape trend between the Spearman correlation and hyperparameter value $\alpha$, where the correlation increases as $\alpha$ increases from 0, but decreases after a certain point. This trend demonstrates the need of taking into account both fidelity and diversity when optimizing for the set of ensemble prompts, as we discussed in Sec. 4.3. On the one hand, $\alpha=0$ corresponds to the case where we focus solely on diversity and ignore the fidelity or individual predicted performance of prompts ($u(w)$) -- this may select a set of diverse prompts, but potentially some irrelevant or poor performing prompts. However, if we emphasize fidelity too much and disregard diversity, we may end up selecting very similar prompts resulting in less ensemble performance gains. At the extreme, choosing large $\alpha$ reduces to the Top-n baseline implementation, which has poorer performance than Dipper that optimizes for semantic volume. In practice, just like other machine learning hyperparameters, we could inform the choice of $\alpha$ with the development set, if available.

## Prompt candidate matters

We then analyze how the candidate pool diversity introduced by Prompt Generator contributes to our framework. Out of the original candidate set $\mathcal{W}$ (Candidate set 2), we obtained another set by selecting one cluster after performing k-means clustering over $\mathcal{W}$ with $k=4$ ($\mathcal{W}'$, Candidate set 1). We then randomly select ensembles of size $n=5$, and plot their respective $V$ and $F(\mathcal{E})$ in Figure 6. We can see that ensembles from $\mathcal{W}'$ have much lower accuracy and semantic volume compared to those from $\mathcal{W}$, illustrating the importance of the candidate pool diversity from the Prompt Generator.

## Dipper combined with other prompting methods like Reflexion

In addition, we also show that our ensemble framework Dipper is **orthogonal** to other established prompting techniques (e.g. CoT and Reflexion [shinn2024reflexion]), allowing it to stack and bring greater performance. To demonstrate this, we first use Dipper to select 5 agents and query each agent with questions from the MATH dataset. Their initial responses will then be self-reflected according to the method proposed in Reflexion [shinn2024reflexion], before being aggregated into the final answer with MV. We found that combining self-reflection with Dipper achieves a performance gain of $8\%$ (from an accuracy of $57\%$ to $65\%$), demonstrating that Dipper has the potential to be extended further or combined with other methods.

[IMAGE: Comparison of Dipper and self-ensemble baseline on MATH using LLaMA-3B and Best-of-N aggregation.]

## Generalization to Best-of-N aggregation

Finally, we study the effects of using the Best-of-N aggregation for our response aggregator component, showing that Dipper can work well with external reward models. We use an existing reward model, "Qwen2.5-Math-RM-72B" to assess the quality of the generated responses and select the final response, using the LLaMA-3B model and Best-of-N aggregation in our Dipper framework. As seen in Figure 7, the Dipper variants significantly beats the self-ensemble baseline when Best-of-N is used. In this scenario, the performance among the Dipper variants are closer since Best-of-N considers each constituent individually rather than jointly (like in MV) to produce the final answer, though our full Dipper implementation still consistently performs the best. We also see that Dipper can stack with benefits from a strong verifier model, given its performance gains compared to the result where no verifier model is available.

# Conclusion

In this work, we have proposed a novel framework, Dipper, where a single LLM model type is fed an optimized, diverse set of reasoning prompts in parallel, effectively producing an ensemble at inference time to achieve performance improvement in reasoning tasks. Our empirical findings have demonstrated the effectiveness of various Dipper implementations in improving inference performance for a variety of reasoning tasks, which may inspire future works to investigate additional optimization methods for prompt-based inference-time ensembles to further improve performance gains.

# Limitations

Our framework Dipper focuses on developing inference-time ensembles where each constituent is based on the same base model -- this caters to the most common and straightforward scenario where users are using a single LLM model and can apply Dipper to further boost its reasoning performance at inference time without additional training. However, when users may wish to use heterogeneous models, Dipper currently does not take into account such model diversity, which we believe may enable further performance boosts if properly optimized. We leave it to future works to potentially build on Dipper to extend it beyond its current limitations in this regard.

# Detailed Experimental Setting

The huggingface model path for the primary model we used is "Qwen/Qwen2-Math-1.5B-Instruct" and the sentence transformer's model path is 'all-MiniLM-L6-v2'. We use the default generation parameters for Qwen2-Math-1.5B-Instruct: the temperature is set to 0.7, the top probability used for filtering is set to 0.8, and the repetition penalty is set to 1.05. We also set the max tokens to be generated to 512.

## Fixed 7 prompts and Prompt Generation

We consider 7 prompts inspired by existing works and list them in Table 1 below.

| **Prompt**                                                                                      |
| ----------------------------------------------------------------------------------------------- |
| Let's think step-by-step to find the answer.                                                    |
| Reflect on the question carefully before answering.                                             |
| Rephrase the question in your own words before responding.                                      |
| Actively reason through the question and answer each part systematically.                       |
| Answer this question as a scientist would.                                                      |
| Eliminate the obviously incorrect answers first and then choose the most likely correct answer. |
| Analyze the context of the question and use relevant information to derive the answer.          |

**Table 1:** The table of 7 basic reasoning prompts inspired by existing works.

We use the prompt template in Table 2 to generate 200 diverse prompts.

| **Prompt Generation Template**                                                                                                                                                                                         |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Here are some instruction examples:                                                                                                                                                                                    |
| [7 reasoning prompts]                                                                                                                                                                                                  |
| Study the above examples and brainstorm 200 similar instructions with detailed descriptions of different reasoning behaviors that are helpful for reasoning. Those 200 proposed instructions should be diverse enough. |

**Table 2:** The prompt template for generating more reasoning prompts based on the 7 prompts.

## Evaluation

We primarily consider three datasets in our paper. For MATH, we randomly sample 10% test samples from each category in its official test split and form a fixed subset of size 500. We then uniformly randomly sample 20 samples from this subset to create a validation dataset and use the rest 480 samples as the hold-out test dataset. For GSM8K and MMLU-STEM, we use their official split of test data and uniformly randomly sample 20 samples to form a validation dataset for each task, and use the rest samples as the hold-out test data.

In the inference evaluation, we use 4-shot exemplars for MATH, 8-shot for GSM8K, and 5-shot for MMLU-STEM. Those exemplars are adopted from the evaluation setting in Qwen2-MATH [qwen2math] and fixed for all questions and all methods.

# Fidelity-adjusted semantic volume metric

In this section, we provide the explicit derivation of how our fidelity-adjusted semantic volume metric can be simplified to a weighted sum of two terms representing the diversity and fidelity desiderata, which clearly illustrates the balance between the two desiderata during the optimization process.

```latex
$$\begin{align}
    \tilde{V} =& \log \det (\tilde{R}\tilde{R}^T) \\
    =& \log \det \left(\exp({\frac{\alpha}{2} \mathop{\mathrm{diag}}(u)})R \right ) \left(\exp({\frac{\alpha}{2} \mathop{\mathrm{diag}}(u)})R \right )^T \\
    =& \log \left [ \det \left(\exp({\frac{\alpha}{2} \mathop{\mathrm{diag}}(u)})\right) \det \left(R R^T\right) \det \left(\exp({\frac{\alpha}{2} \mathop{\mathrm{diag}}(u)})^T \right) \right ] \\
    =& \log \det (RR^T) + 2 \log \det \left(\exp({\frac{\alpha}{2} \mathop{\mathrm{diag}}(u)}\right) \\
    =& V+ 2 \log \prod_i \exp({\frac{\alpha}{2} u_i}) \\
    =& V+ \alpha \|u\|_{1}
\end{align}$$
```

The derivation uses the identity $\det(AB)=\det(A)\det(B)$, the identity $\log(AB)=\log(A)+\log(B)$, and the definition of semantic volume. The final step notes that $\sum_i u_i = \| u \|_1$ since $u \geq 0$.

# Additional Results

## Results on General-Purpose Model

To show our method Dipper also generalizes to a general-purpose model (e.g., LLaMA), we evaluate its performance using LLaMA3.2-3B-it model on MATH and MMLU-STEM. The results demonstrate that our full Dipper implementation consistently outperforms the self-ensemble baseline and other Dipper variants across datasets.

[IMAGE: Comparison of different ensemble methods on MMLU-STEM for the LLaMA3.2-3B-it model.]

To demonstrate the generalization of our method Dipper to more recent models, we compare its variants against the baseline method on the new Qwen3-0.6B and Qwen3-1.7B models. The results suggest that our method Dipper still has the same performance advantage on recent LLMs.

| Method         | n=3       | n=5       | n=7       | n=9       |
| -------------- | --------- | --------- | --------- | --------- |
| Self-ensemble  | 42.18     | 44.33     | 45.12     | 45.43     |
| Dipper (Rand+) | 42.18     | 45.03     | 46.31     | 46.98     |
| Dipper (Top-n) | **42.98** | 44.65     | 45.91     | 47.80     |
| Dipper (FASV)  | **42.98** | **44.86** | **46.54** | **49.26** |

**Table 3:** Comparison of different ensemble methods on MATH for Qwen3-0.6B

| Method         | n=3       | n=5       | n=7       | n=9       |
| -------------- | --------- | --------- | --------- | --------- |
| Self-ensemble  | 47.38     | 49.54     | 51.07     | 51.70     |
| Dipper (Rand+) | 50.29     | 51.93     | 52.94     | 53.50     |
| Dipper (Top-n) | 51.36     | **53.25** | 53.04     | 53.04     |
| Dipper (FASV)  | **51.57** | 52.62     | **53.25** | **54.51** |

**Table 4:** Comparison of different ensemble methods on MATH for Qwen3-1.7B

## Results on more datasets for the Qwen2-MATH-1.5B model

Apart from the MATH dataset, we also evaluate the performance of Dipper using the Qwen2-MATH-1.5B model on MMLU-STEM and GSM8K. The results again demonstrate that our full Dipper implementation can consistently outperform the self-ensemble baseline and achieve superior or comparable results against the other Dipper variants. The performance gains in GSM8K is more limited compared to the gains in experiments for other datasets as it is an easier dataset where the base model can already achieve high accuracy. As can be seen across all our experimental results, our full Dipper implementation comprising the theoretically-inspired semantic volume diversity optimization component achieves the most consistent performance, unlike some of the other variants.

[IMAGE: Comparison of different ensemble methods on GSM8K. Dipper still outperforms the self-ensemble baseline, although gains are not as obvious as in other benchmarks as it is an easier task where the base model can already perform well.]

## Results beyond Reasoning Tasks

To investigate the effectiveness of Dipper extending to non-reasoning tasks, we have conducted additional experiments on three challenging BIG-Bench tasks following the Instruction Induction setting from Zhou et al. As per our framework, our prompt generator first generates instruction candidates based on 5 randomly sampled demonstrations in the form of input-output pairs, before our prompt selector optimizes for the ensemble prompt composition. Our FASV variant consistently outperforms others, especially over the self-ensemble baseline and when the ensemble size becomes larger. This indicates that Dipper has a potential to be deployed as a general inference framework for improved performance.

## More Results on Prompt Diversity

We also show that a strong Spearman correlation between $V$ and $F(\mathcal{E})$ exists for different datasets (e.g., GSM8K). The results demonstrate a consistent Spearman correlation between the semantic diversity $V$ and accuracy $F(\mathcal{E})$ exists. Besides, choosing different fidelity-diversity hyperparameters $\alpha$ may give different results when optimizing for the diversity.

[IMAGE: Scatter plot showing the Spearman correlation between V and F(E) on GSM8K with 2 different alpha values.]

## Illustration of Semantic Volume

We illustrate our semantic column metric $V$ here by comparing the semantic volume of (1) a set of 5 prompts generated by just paraphrasing a single original prompt, and (2) a set of 5 prompts randomly selected from the diverse candidate pool $\mathcal{W}$. The comparison shows how sets of prompts that are qualitatively observed to be more diverse have larger quantitative semantic volume.

## Generated prompts based on 7 prompts

Below we provide some examples of the generated prompts from GPT-4o based on the 7 prompts.

| **Prompt**                                                                                                                                               |
| -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Break Down the Problem**: Divide the question into smaller, manageable parts and tackle each part individually before synthesizing the overall answer. |
| **Apply Mathematical Logic**: Use mathematical principles and logic to solve the problem, even if it's not a math question.                              |
| **Use Analogies**: Relate the question to a familiar concept or situation to better understand and solve it.                                             |
| **Consider the Opposite**: Think about what the answer would be if the opposite were true, to gain a different perspective.                              |
| **Consider Cause and Effect**: Identify potential causes and their effects to understand the question better.                                            |

**Table 5:** Examples of reasoning prompts generated based on 7 basic prompts.
