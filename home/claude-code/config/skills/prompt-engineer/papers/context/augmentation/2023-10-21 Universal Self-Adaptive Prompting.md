# Abstract

A hallmark of modern large language models (LLMs) is their impressive general zero-shot and few-shot abilities, often elicited through in-context learning (ICL) via prompting. However, while highly coveted and being the most general, zero-shot performances in LLMs are still typically weaker due to the lack of guidance and the difficulty of applying existing automatic prompt design methods in general tasks when ground-truth labels are unavailable. In this study, we address this by presenting Universal Self-Adaptive Prompting (USP), an automatic prompt design approach specifically tailored for zero-shot learning (while compatible with few-shot). Requiring only a small amount of _unlabeled_ data and an inference-only LLM, USP is highly versatile: to achieve universal prompting, USP categorizes a possible NLP task into one of the three possible task types and then uses a corresponding selector to select the most suitable queries and zero-shot model-generated responses as _pseudo_-demonstrations, thereby generalizing ICL to the zero-shot setup in a fully automated way. We evaluate USP with PaLM and PaLM 2 models and demonstrate performances that are considerably stronger than standard zero-shot baselines and often comparable to or even superior to few-shot baselines across more than 40 natural language understanding, natural language generation, and reasoning tasks.

# Introduction

The recent advancements in large language models (LLMs) are among the most astonishing breakthroughs in artificial intelligence. The modern, massive attention-based [vaswani2017attention] LLMs not only surpass human and previous models in specific natural language processing tasks, but they have also demonstrated impressive general capabilities [bubeck2023sparks]. Indeed, thanks to both the scaling of LLM sizes and advances in training and fine-tuning techniques [brown2020language; sanh2021multitask; weifinetuned], one of the most prominent and impressive abilities of modern LLMs is their _zero-shot_ generalizability handling diverse and sophisticated tasks, even if the models have not been explicitly trained on them. Beyond zero-shot abilities, when a few demonstrations are available, the _few-shot_ capabilities can take advantage of the information in them with _in-context learning_ (ICL) [brown2020language], leading to further improvements.

[IMAGE: Figure 1 - teaser.pdf - USP improves over standard zero-shot prompting across more than 40 Classification (CLS), Short-form Generation (SFG) and Long-form Generation (LFG) tasks in PaLM-62B, PaLM-540B and PaLM 2 models.]

Such few-shot capabilities are often observed to improve as the LLMs scale [brown2020language; wei2023larger]. Along with careful prompting, in many cases, LLMs can perform similarly to, or even better than, fine-tuning, even though the latter is both more computationally expensive (due to gradient back-propagation) and more data-intensive. As such, in many scenarios, prompt-based learning has drastically reduced the barrier to the use of even the most massive LLMs.

[IMAGE: Figure 2 - overview.png - Overview of (a) zero-shot setup, (b) few-shot setup with in-context learning, (c) Consistency-based Self-Adaptive Prompting and (d) Universal Self-Adaptive Prompting (USP). The queries without demos with which LLMs are directly prompted (zero-shot, or Stage 1 in COSP and USP) are marked in red arrows, and the queries prepended with either the handcrafted demos (few-shot) or model-generated pseudo-demos (Stage 2 in COSP and USP) are marked in blue arrows.]

Notwithstanding the breakthroughs, many open questions remain. While the zero-shot performances of LLMs are highly valued and widely used as a key yardstick of LLM capabilities [chowdhery2022palm; tay2022ul2], LLMs still often show weaker performances and/or larger performance fluctuations in the zero-shot setting because of the lack of guidance or readily-available template solutions. While many automatic prompting methods have been proposed (refer to Section 4 for details), few existing works target the zero-shot setup, and heuristic manual prompt design is still often heavily relied upon [reynolds2021prompt; mishra-etal-2022-reframing].

On the other hand, even though the ICL paradigm has reduced the cost of data collection and labeling considerably, given that modern LLMs are typically used for an extremely diverse set of tasks, obtaining even a small number of labeled examples per task can easily become expensive for many tasks. Furthermore, in some tasks, obtaining even a few examples might require a non-trivial amount of human effort (e.g., summarization of long articles, translation of low-resource languages, and/or domain-specific question answering requiring research or expertise), or simply impossible for novel tasks that are only revealed at test time.

To address this, we introduce USP (Universal Self-Adaptive Prompting) that specifically pushes the state-of-the-art with ICL in zero-shot settings (while remaining compatible with few-shot) via _pseudo_-demonstrations (pseudo-demos) constructed from _unlabeled_ queries and _model-generated_ outputs. USP works with fully black-box, inference-only LLMs, and the use of pseudo-demos ensures that USP may operate entirely in the _transductive zero-shot_ setup [xian2017zero] using only unlabeled data. This makes USP extremely versatile, as unlabeled data is typically readily available via, e.g., continuous, on-the-fly collections of user queries. Unlike alternative methods often requiring task knowledge beforehand (e.g., class names), USP requires only the task type information to select an appropriate confidence-quantifying metric (e.g., natural language understanding (NLU) or generation (NLG) -- these need to be known anyway), while still remaining capable of using additional information like class names if they are indeed available (Section 3.3). This enables USP to work in arbitrary, potentially novel tasks at test time and/or tasks that simply cannot be cast as classification problems (e.g., open-domain QA and other generative tasks). USP is inspired by recent works leveraging confident predictions for model self-improvements on chain-of-thought tasks [wang2022self; huang2022large; wan2023better] but inherits the benefits of these works and generalize them considerably in terms of the scope of applicability. To achieve this, we derive various criteria capable of selecting high-quality pseudo-demos in the absence of any ground-truth labels. To summarize:

1. We propose USP, a versatile and _black-box_ automatic prompting method that can be _zero-shot_ using only unlabelled data.

2. To achieve this, we select _pseudo-demos_ from model-generated outputs via 3 carefully designed scoring functions suitable for different task types.

3. As shown in Fig. 1, we show USP realizes large performance gains over more than 40 NLU, NLG and reasoning tasks with PaLM & PaLM 2 models.

# Preliminaries

#### In-context Learning (ICL).

ICL enables LLMs to perform few-shot learning by processing several labeled, exemplary queries similar to the test queries we are interested in solving as _demonstrations_, or _demos_ in the prompts [brown2020language; dong2022survey; logan-iv-etal-2022-cutting] (Fig. 2b). Formally, denoting a test query as $x$ and if we have $k$ pairs of related concatenated queries and labels $s^{(i)} = \texttt{Concat}(x^{(i)},y^{(i)}) \, \forall \, i \in \{1, ...,k\}$ serving as demos, we augment the test query by prepending the demos (and instructions, if any) to it:

```latex
$$C(x) = \texttt{Concat}(s^{(1)},...,s^{(k)},x).$$
```

ICL is achieved by obtaining the prediction $\hat{y}$ by querying $C(x)$ instead of just $x$. In our zero-shot setup, _none_ of the ground-truth labels (i.e., the $y$s) are available, and we propose to use the LLM predictions themselves as _pseudo_-demos. Thus, our _zero-shot_ ICL instead has the form of:

```latex
$$\hat{C}(x) = \texttt{Concat}(\hat{s}^{(1)}, ..., \hat{s}^{(k)}, x),$$
```

where $\hat{s}_i = \texttt{Concat}(x^{(i)}, \hat{y}^{(i)})$, and the ultimate objective of USP is to generate and identify the most suitable set of such pseudo-demos.

#### Self-consistency.

For LLMs, Wang et al. [wang2022self] introduce _self-consistency_ (SC) for chain-of-thought (CoT) reasoning tasks [wei2022chain] as an effective approximation of the model confidence -- SC decodes each test query multiple times using a non-zero temperature (we use a temperature of 0.7 following previous works) to introduce stochasticity. The _majority_ of the predictions are then chosen as the final predictions.

#### COSP.

Inspired by Wang et al. [wang2022self] and entropy minimization [grandvalet2004semi], Wan et al. [wan2023better] propose _Consistency-based Self-Adaptive Prompting_ (COSP) to improve zero-shot CoT reasoning. COSP is the most influential prior work to us: as shown in Fig. 2c, COSP uses a two-stage approach. In Stage 1, COSP performs zero-shot inference with multiple decoding paths in a similar manner to SC and then computes the normalized entropy to quantify model confidence via discrepancy in predictions from the same query on different decoding paths. COSP then ranks the Stage 1 outputs based on the entropy (and other metrics such as diversity and repetition) and selects the confident outputs as the pseudo-demos. In Stage 2, these pseudo-demos are prepended to the test queries in a manner similar to few-shot ICL, and the final predictions are given by the majority vote over outputs in both stages.

# Universal Self-Adaptive Prompting

## Motivation and Challenges of USP

Inspired by the success of COSP, we argue that the principle of confidence-based prompting should be _universally_ applicable to _all_ tasks, rather than being exclusive to a narrow set of reasoning tasks COSP considered; this forms the motivation and the goal of this paper. However, a number of limitations and challenges prohibit a trivial generalization: first, a universal prompting strategy needs to accommodate numerous, vastly diverse tasks that vary significantly in terms of objective, prompting, evaluation, and, unsurprisingly, confidence/uncertainty quantification. As a result, SC and the techniques developed by Wan et al. [wan2023better] may be sub-optimal or even inapplicable for other task types: for instance, many problems are cast as classification where the output well-calibrated logits are useful for uncertainty quantification, but such information is not used in the original formulation of COSP. Also, the notion of majority voting crucial to COSP and SC may not even exist for creative and generative tasks with many plausible solutions.

## Overview of USP

To address the challenges, we present USP (Fig. 2d and Algorithm 1). USP shares some high-level similarities to the COSP formulation: USP also adopts a two-staged approach where in Stage 1, the LLMs are prompted in a zero-shot manner to generate a collection of candidate responses from which a few _model-generated_ pseudo-demos are selected; in Stage 2, USP prepends these pseudo-demos to the test queries in a few-shot manner and prompts the LLM again to obtain the final predictions. However, we highlight a few key design decisions, in particular those differing from COSP, that effectively overcome the aforementioned challenges and enable USP to generalize:

**Algorithm 1: Universal Self-Adaptive Prompting (USP)**

**Input**: Test set with size $N$: $\mathcal{T} = \{x^{(i)}\}_{i=1}^N$, unlabeled set for demo generation with size $N_u$: $\mathcal{D} = \{d^{(j)}\}_{j=1}^{N_u}$ (can be same as or a subset of $\mathcal{T}$, or a different but related set of unlabeled queries), Pool of generated responses $\mathcal{P} \leftarrow \emptyset$, Task type $t \in$ {CLS, SFG, LFG} (Section 3.3).

**Output**: Predictions $\{\hat{y}^{(i)}\}_{i=1}^N$.

**[Stage 1]** Query the LLM with $d^{(j)}$ under the zero-shot setup to obtain a _single_ prediction $\hat{z}^{(j)}$ (_if_ $t$=CLS), or query $m$ times with non-zero temperature to obtain $m$ predictions $\{ \hat{z}^{(j)}_k \}_{k=1}^m$ (_otherwise_).

Add eligible candidate pseudo-demos $\{p_j\}_{j=1}^{N_u}$ (from concatenating $d^{(j)}$ and $\hat{z}^{(j)}$) to $\mathcal{P}$.

Build the pseudo-demo set $\mathcal{S} = \{s_1, .., s_K\}$ (with $|\mathcal{S}|=K$) from $\mathcal{P}$ with one of the selectors in Section 3.3 depending on $t$.

**[Stage 2]** Concatenate the $\mathcal{S}$ to $x^{(i)}$ and query again (with greedy decoding for generative (SFG/LFG) tasks) to obtain the final LLM prediction $\hat{y}^{(i)}$.

**1.** _Task-specific pseudo-demo selector._ The pseudo-demo selector, which selects the most suitable query-response pair from the zero-shot outputs, is central to USP. With reference to Fig. 2c and 2d, whereas COSP only uses the consistency-based selector and hence is only applicable to a limited number of tasks, USP instead uses a _task-type specific_ selector that is key for its versatility -- we explain this in detail in Section 3.3.

**2.** _Separating test set and the demo-generating dataset._ Instead of expecting the _full_ test set $\mathcal{T}$ in Stage 1, USP expects a general unlabeled dataset $\mathcal{D}$, which can be the full test set $\mathcal{T}$, a subset of it, a different unlabelled set, or possibly even a model-generated dataset like Schick and Schutze [schick2021generating] (although we always use a subset of $\mathcal{D}$ for simplicity in this work). Its sole purpose is to generate the pseudo-demos, enabling USP to work even if $\mathcal{T}$ is not known a-priori in its entirety. Indeed, as we will show in Section 5, USP is capable of generating high-quality pseudo-demos with _only 64 unlabeled samples_ per dataset. This makes USP more _sample efficient_, due to the smaller number of unlabeled samples required, and more _computationally efficient_, as the algorithm only needs to iterate through $\mathcal{D}$, which can be modestly sized, in Stage 1.

**3.** _Dropping reliance on majority vote._ The use of majority vote (as shown in Fig. 2c) is crucial for COSP, but as discussed, the procedure is also computationally expensive and inapplicable when the majority itself is ill-defined. To address this, by default, USP instead only decodes _once_ in Stage 2 with _greedy decoding_ (i.e., temperature $=0$) and uses the maximum likelihood estimated (MLE) outputs as the final predictions. It is worth noting that USP remains compatible with majority voting over multiple decoding (if it can be used) for further performance improvements, but no longer _depends on_ these to function.

## Task-specific Selector

The objective of the _selector_ (Step 7 in Algorithm 1) is **1)** to build a pool of candidate pseudo-demos $\mathcal{P}$, whose elements $p^{(j)}$ are formed concatenating dataset queries $\{ {d}^{(j)} \}_{j=1}^{N_u}$ and their zero-shot LLM predictions $\{ \hat{z}^{(j)} \}_{j=1}^{N_u}$ and **2)** to select $\mathcal{S}$, a subset of $K$ pseudo-demos from $\mathcal{P}$ to be prepended to the test queries. We use a function $\mathcal{F}:\mathcal{P}\rightarrow\mathbb{R}$ (the design of $\mathcal{F}$ is explained later in this section) to "score" each candidate. We select the first pseudo-demo in $\mathcal{S}$ by finding the maximizer of $\mathcal{F}(\cdot)$ in $\mathcal{P}$. For each of the subsequent pseudo-demos $k \in \{2, ..., K\}$, we instead repeatedly find the maximizer of $\mathcal{F}(\cdot)$ with a diversity-promoting term to penalize candidates that are too similar to _any_ of the pseudo-demos already selected and add to $\mathcal{S}$:

```latex
$$s_k = \mathop{\arg\max}_{p \in \mathcal{P} \backslash \mathcal{S}_{1:k-1}} \mathcal{F}(p) - \lambda \max_{k'=1}^{k-1} \Big( S_c \big( \phi(p),  \phi (s_{k'} ) \big) \Big),$$
```

where we follow Wan et al. [wan2023better] to set $\lambda$, the trade-off parameter, to 0.2 in all experiments without further tuning and use $z$-score standardization for the two terms over $\mathcal{P}$ to ensure they are of a comparable magnitude; $S_c(\cdot, \cdot)$ denotes the cosine similarity and $\phi(\cdot)$ is the sentence-level embedding given by an auxiliary model, as in COSP. The design of $\mathcal{F}(\cdot)$, therefore, encodes our preference on which pseudo-demos should be prepended to the test queries for ICL. To achieve _universal_ prompting, we categorize a possible task into one of the three generic types (see Task Categorization table). We use this categorization to design task-specific scoring functions $\mathcal{F}(\cdot)$ below, and empirically validate the effectiveness of these designs in Section 5.

**Task Categorization:**

- **CLS (Classification)**: Small, known label space; select from few options (e.g., sentiment analysis, NLI)
- **SFG (Short-form Generation)**: Many possible responses, one/few correct; short outputs (e.g., QA, arithmetic)
- **LFG (Long-form Generation)**: Many plausible responses; longer outputs (e.g., summarization, translation)

#### Classification (CLS).

We first consider problems that feature the selection of a single correct answer from a few possible options -- we use the descriptor CLS for "classification", as the label space $\mathcal{C}$ in this case is small and known, and the task is to pick the most probable class $\mathcal{C}$: $\hat{z}^{(j)} = \arg\max_{c \in \mathcal{C}} \mathbb{P}(c|d^{(j)})$. Since the logits are available in this case, we do _not_ need self-consistency to estimate the prediction confidence, although we may still choose to use a self-consistency-based confidence metric if, the model would be poorly calibrated with logits, or self-consistency would be preferable due to other reasons (e.g., when CoT prompting is used and generating diverse reasoning paths via multiple-path decoding is beneficial -- see the next paragraph on SFG for details). Instead, for $p^{(j)} = \texttt{Concat}(d^{(j)}, \hat{z}^{(j)}) \in \mathcal{P}$, we simply query the LLM once and use the negative entropy of the distribution over $\mathcal{C}$ as the function $\mathcal{F}$ for the CLS case:

```latex
$$\mathcal{F}_{\texttt{CLS}}(p^{(j)}|d^{(j)}) := \sum_{c \in \mathcal{C}} \tilde{\mathbb{P}}(c|d^{(j)})\log \tilde{\mathbb{P}}(c|d^{(j)}),$$
```

where $\tilde{\mathbb{P}}(c|d^{(j)})$ is the normalized probability with $\sum_{c\in\mathcal{C}}\tilde{\mathbb{P}}(c|d^{(j)})=1$ -- it is worth noting that orthogonally, an improved uncertainty metric like the _semantic uncertainty_ [kuhn2023semantic] may be used instead, although we do not consider these in the present work. We further use the knowledge of $\mathcal{C}$ to ensure good coverage of the label space, which has been shown to be important for a strong ICL performance [min-etal-2022-rethinking]. Specifically, to build $\mathcal{S}$, instead of simply generating $K$ pseudo-demos from $\mathcal{P}$, we generate ${K}/{|\mathcal{C}|}$ pseudo-demos _for each_ $c \in \mathcal{C}$ _from a subset_ $\mathcal{P}_c \subset \mathcal{P}$ where:

```latex
$$\mathcal{P}_{c} = \Big\{p^{(j)} \in \mathcal{P} \text{ if }  \hat{z}^{(j)} = c \, \forall j \in \{1, ..., N_u\} \Big\}.$$
```

This is because LLMs can be more confident in some classes, and simply choosing the most confident predictions overall as pseudo-demos may lead to bias towards these classes; we mitigate this to ensure that the selected pseudo-demos $K$ feature each class approximately uniformly. Note that it is possible that $K$ < $|\mathcal{C}|$ or $\mathrm{mod}(K, |\mathcal{C}|) \neq 0$. In these cases, we generate $\lceil \frac{K}{|\mathcal{C}|} \rceil$ pseudo-demos _per class_ and prepend each test query $x^{(i)} \in \mathcal{T}$ with $K$ randomly sampled pseudo-demos to ensure fairness _in expectation_ over $\mathcal{T}$. Lastly, it is possible that some classes are never predicted in $\mathcal{D}$, e.g., an over-confident model may never predict the "_not sure_" option in inference tasks. As a result, the set $\mathcal{P}_c$ is empty for these unpredicted classes. To nevertheless generate the most plausible pseudo-demos for them, for an unpredicted class $c_u$, we pick the top queries in $\mathcal{D}$ with the highest model-assigned probability in $c_u$:

```latex
$$\mathrm{Top}\frac{K}{|\mathcal{C}|}_{d^{(j)} \in \mathcal{D}}\Big( \mathbb{P}(c=c_u|d^{(j)})\Big),$$
```

noting that the indexing is over the unlabeled dataset $\mathcal{D}$. These queries are then concatenated with class label $c_u$ to form the pseudo-demos for these unpredicted classes.

#### Short-form Generation (SFG).

We use descriptor SFG (for _Short-form Generation_) to denote the class of generation problems typically with many possible responses but only one to a few correct responses, and examples include _Question Answering_. Alternatively, as we discussed in the previous paragraph, we may use the SFG formulation for CLS tasks if we use the text-to-text formulation like T5 [raffel2020exploring], have no access or prefer not to rely on logits, or as discussed when self-consistency-style multiple decoding is preferable. Unlike the CLS case, we assume access to only the model outputs $\hat{z}^{(j)}$ but not the logit distribution. This covers the case covered in COSP (problems such as arithmetic reasoning considered in COSP fall into this category), and thus we may use the _normalized entropy_ in Wan et al. [wan2023better] to gauge the model confidence, except that for non-CoT prompted tasks, we skip the rationale generation step and prompt for answers directly. Specifically, for each $d^{(j)} \in \mathcal{D}$, we query the LLM $m$ repetitions, under temperature sampling to obtain $m$ predictions $\{\hat{z}_{\ell}^{(j)}\}_{\ell=1}^m$. While only the _majority_ predictions of each query are added to $\mathcal{P} := \Big\{ \texttt{Maj}\big(\{ \hat{z}^{(j)}_{\ell}\}_{\ell=1}^m \big) \Big\}_{j=1}^{N_u}$, we use all $m$ predictions to score the model confidence for each $p^{(j)} \in \mathcal{P}$:

```latex
$$\mathcal{F}_{\texttt{SFG}}\big(p^{(j)} \big\vert \{\hat{z}_{\ell}^{(j)}\}_{\ell=1}^m\big) := -\frac{\sum_{\alpha=1}^{{\mu}} \mathrm{\tilde{\mathbb{P}}}(\hat{z}^{(j)}_{\alpha}) \log  \mathrm{\tilde{\mathbb{P}}}(\hat{z}^{(j)}_{\alpha}) }{\log m},$$
```

where $\mu \leq m$ is the number of _unique_ answers and $\tilde{\mathbb{P}}(\hat{z}^{(j)}_{\alpha})$ is the empirical frequency of an _unique_ answer $\hat{z}^{(j)}_{\alpha}$ in all $m$ predictions for $d^{(j)}$.

#### Long-form Generation (LFG)

The final category, LFG for _Long-form Generation_, features NLG tasks with longer responses and many plausible responses with typical examples being summarization and translation. As discussed, the SFG scoring function does not effectively approximate confidence/uncertainty in this case, as decoding the same query with temperature sampling $m$ times is unlikely to yield identical responses in terms of surface texts due to the length of generation, _even for the confident predictions_. On the other hand, it would also be challenging to apply logit-based modeling in the face of the high-dimensional joint probabilities & the presence of sequential relationships amongst the generated tokens. To measure confidence in this case, we first follow the SFG case by querying each $d^{(j)} \in \mathcal{D}$ for $m$ repetitions $\{\hat{z}_{\ell}^{(j)}\}_{\ell=1}^m$. Instead of using the SFG scoring function, we compute the _average pairwise_ ROUGE score between all pairs of the $m$ responses:

```latex
$$\mathcal{F}_{\texttt{LFG}}\big( p^{(j)} \big\vert \{\hat{z}_{\ell}^{(j)}\}_{\ell=1}^m\big) := \frac{2 \sum_{\substack{\ell=1, \ell'=1 \\ \ell'\neq\ell}}^m \texttt{ROUGE}(\hat{z}_{\ell}^{(j)}, \hat{z}_{\ell'}^{(j)})}{m(m-1)},$$
```

where another overlap metric, such as the pairwise BLEU [shen2019mixture] or the sentence-level embedding cosine similarity from an auxiliary model, may be used instead. Another challenge for LFG tasks is that unlike SFG where $\mathcal{P}$ can be simply built from majority predictions for each query $d^{(j)} \in \mathcal{D}$, "majority" is no longer well-defined. We thus use $\mathcal{F}_{\texttt{LFG}}$ to rank the confidence of the queries in $\mathcal{D}$ & determine which _queries_ to be used in $\mathcal{S}$ _only_. For the _response_ part of the pseudo-demos, we decode the LLM again _with argmax_ _decoding_ to obtain the MLE predictions on the selected queries to build $\mathcal{S}$. Lastly, given that zero-shot text generation is purely driven by prompting and instructions, we observe that the LLMs sometimes generate extremely confident text completions instead of actually completing the instructed tasks (e.g., summarization); selecting these outputs as pseudo-demos, as we investigate in Section 5, can significantly degrade performance. Given that these outputs often feature an abnormally high $\mathcal{F}_{\texttt{LFG}}$ score, we apply a simple but canonical outlier filtering technique to remove queries with score > upper quartile + 1.5 x interquartile range (IQR) [tukey1977exploratory].

## Cost Analysis

Computing the USP scores itself is cheap, and the cost is thus bottlenecked by the amount of processing from the LLM side. In particular, the additional costs are:

- _Stage 1_: with $|\mathcal{D}|$ unlabeled samples, we require $|\mathcal{D}|$ additional model queries for the CLS task and 64$m$ (we use $m$ = 6) for SFG and LFG tasks -- it is worth noting that we can also use batching to parallelize this step. The column $|\mathcal{D}|/|\mathcal{T}|$ represents the fraction of the unlabeled samples to the size of the entire test set, the additional cost is always negligible compared to the cost we need to incur anyway by iterating over the test set, except for some very small-scale toy tasks with small test tasks.

- _Stage 2_: This stage is completely identical to standard few-shot in-context learning.

Thus, compared to standard zero-shot learning, USP requires the additional Stage 1, which typically only adds a small amount of cost, as discussed above. In Stage 2, the LLM needs to process a longer context due to the use of pseudo-demos for in-context learning. However, this is due to the use of in-context learning and is not an additional cost uniquely attributable to USP -- it is true for all other methods relying on ICL. Compared to few-shot learning, the only additional overhead is the use of Stage 1, but crucially, no labeled data is required at any point in time.

# Related Works

Besides those covered in Section 2, here we discuss other related works in zero-shot automatic prompting. We include an additional literature review in the Appendix.

AutoCoT [zhang2022automatic] also uses model-generated output as pseudo-demos but differs in the selection procedure -- it computes a sentence embedding of available queries and uses clustering to select the centroid queries as pseudo-demos. This process, unlike USP, is purely based on the query (dis)similarity rather than the output quality, and the quality of the selected pseudo-demos is thus, in expectation, the same as the average model performance -- we empirically compare against a generalized version of it in Section 5, which is originally designed for reasoning tasks only (hence the name).

Another method, Z-ICL [lyu2022z], generates pseudo-demos with synonyms of random class names. It, however, by assuming label knowledge, is limited to a subset of CLS tasks where it is reasonable to do label synonym replacement. For example, while it is reasonable to replace simple sentiment-describing labels like "good" or "bad", the same may not be possible for factual labels or when labels are beyond single words (e.g., the race{h,m} examples shown in the prompt tables). Randomly selecting labels also only generates correct demos with a probability of $\frac{1}{|\mathcal{C}|}$ -- given the recent discovery that modern LLMs genuinely learn from the demos and can be sensitive to their correctness [wei2023larger], providing mostly wrong demos is sub-optimal. To represent this class of methods, we compare against a _Random demo_ baseline in our experiments (see Section 5 for details).

# Experiments

#### Setup.

On PaLM-540B and PaLM-62B [chowdhery2022palm], we consider a wide variety of CLS, SFG and LFG tasks, and the readers are referred to Appendix 8 for more details. We also experiment on the state-of-the-art PaLM 2-M [anil2023palm] model and test it on BIG-bench Hard (BBH) tasks, a suite of challenging tasks often requiring complicated reasoning, logic, or manipulations where previous models underperform humans [suzgun2022challenging]. We compare USP against (i) standard zero-shot prompting (except for BBH tasks where we use standard zero-shot-_CoT_ prompting [kojima2022large] (_0-shot_); (ii) an adapted version of AutoCoT [zhang2022automatic] for general NLP tasks (_AutoCoT_); (iii) _Random demo_, where we follow all of the USP procedure except we randomly sample $K$ demos from $\mathcal{P}$ -- this serves both as an ablation baseline to USP and as a generalization for methods like Z-ICL described in Section 4 which only work for CLS tasks, except that _Random demo_ is arguably stronger as it samples from the _model predictions_ rather than _possible classes_, the former of which is more likely to yield correct pseudo-demos as long as the LLM is better than random guessing in zero shot; (iv) standard few-shot with golden demonstrations (_$k$-shot_ where $k$ depends on tasks; see explanation in result tables). For a fair comparison, _AutoCoT_, _Random demo_ and USP all generate $k$ pseudo-demos per sample from 64 randomly sampled, unlabelled test queries per task (i.e., $\mathcal{D}$ in Section 3.3). We include all other implementation details in Appendix 9.

[IMAGE: Figure 3 - ulm24b_bbh.png - Accuracy on BIG-Bench Hard tasks with PaLM 2-M (each line represents a task of the suite). The gain/loss of USP over standard 0-shot is shown in percentages. Note that 3 (pseudo-)demos are generated per query. Human refers to average human performance.]

[IMAGE: Figure 4 - USP score vs ground-truth performance correlation plots - USP picks confident predictions that are more likely better. Ground-truth performance metrics in the Stage 1 unlabelled samples against USP scores in selected tasks with PaLM-540B.]

#### Discussion of main results.

We show the results of CLS, SFG and LFG tasks with PaLM-540B in the result tables, and BBH results on PaLM 2-M are shown in Fig. 3 (examples of the generated pseudo-demos in representative tasks are shown in the Appendix and PaLM-62B results are shown in Appendix 10.1). We find that USP greatly improves upon standard zero-shot prompting without any pseudo-demos, outperforms other zero-shot methods using pseudo-demos, and is often competitive to or better than few-shot prompting, all achieved with only 64 unlabeled samples per task. Generally, we find the gain margin to be larger in generative tasks and in larger and/or more advanced models. We hypothesize that 1) LLMs benefit more on guidance from the demonstration in generative tasks, which essentially feature unbounded action spaces, whereas in CLS, the LLM only needs to select a response out of a few; 2) larger models and/or those trained with more advanced techniques (e.g., instruction fine-tuning) have stronger ICL capabilities to take advantage of the demos of better quality.

#### Few-shot USP.

On the BBH tasks on PaLM 2, we also test a _few-shot_ variant of USP (termed USPfs) to generate additional pseudo-demos on top of scarce, manual demos. We show the results in Fig. 9 in Appendix 10, and USPfs outperforms both the zero-shot USP reported in Fig. 3 and standard 1-shot, thereby highlighting the generality of USP.

#### _How_ does USP work?

To analyze how the USP procedure (Section 3.3) improves performance, we plot the USP scores against the _ground-truth performance_ (accuracy, EM or ROUGE) of the queries in unlabeled datasets $\mathcal{D}$ (with $|\mathcal{D}| = 64$) in Fig. 4 (additional results are reported in Appendix 10), and we observe that across task types and difficulty levels (as measured by the average performance marked by the gray dashed lines in Fig. 4), the USP scores are generally well-correlated with the ground-truth performance, which also validates the finding that LLMs "mostly know what they know" [kadavath2022language]. The recent findings that larger LLMs genuinely learn information from in-context examples (instead of simply following a prompt format) and thus benefit more from correct examples [wei2023larger] are consistent with the results of USP, which, as we show, is more likely to generate correct/high-quality pseudo-demos. Interestingly, a concurrent work [margatina2023active] also shows that _even when golden labeled examples are available_, better in-context examples still tend to exhibit low uncertainty and diversity.

#### _When_ does USP work better?

[IMAGE: Figure 5 - Gain from USP is larger with higher zero-shot uncertainty. Relative gain of Stage 2 over Stage 1 accuracy/EM against average USP score.]

While USP improves generally, there are cases where USP underperforms standard zero-shot -- this seemingly counter-intuitive phenomenon is not unique to USP and is common even for few-shot learning with golden examples from both our results and previous works [brown2020language; chowdhery2022palm]. Nonetheless, understanding _when_ it happens for specific tasks can be crucial for users' decision-making. As shown in Fig. 5, we find the _average Stage 1 USP score across $\mathcal{D}$_ to be a good _zero-shot_ indicator of the extent of improvement from USP. An intuitive explanation is the average USP score quantifies the general uncertainty the model has about the task (and potentially the task difficulty): with a high average USP score, the model is already confident under zero-shot, and the benefits from ICL are lower (and sometimes may even worsen performance). On the other hand, a low average USP score suggests high model uncertainty and larger potential gains from additional guidance.

# Conclusion

We propose USP, a versatile, _zero-shot_ automatic prompting technique applicable to a wide range of NLU, NLG, and reasoning tasks. We show large improvement over standard zero-shot prompting and other baselines in over 40 tasks with 3 LLMs.

# Limitations

We believe that the room for future improvements is ample:

First, the present work specifically targets in-context demonstrations, a sub-component of the overall prompt, and it does not attempt to optimize the other components; a future work would be relaxing this restriction and combining USP with orthogonal techniques (e.g., calibration methods [zhao2021calibrate; han2022prototypical; zhou2023batch] and black-box methods targeting other parts of the overall prompt [deng-etal-2022-rlprompt; zhou2023survival]) for improved flexibility.

Second, while our method is general in terms of the _tasks_, it might be more demanding on the _model capabilities_: for the USP score to function as intended, we implicitly demand the model to generate well-calibrated outputs in terms of uncertainty, and the ICL formulation also requires strong in-context learning abilities, both of which have been shown to correlate strongly with model sizes [kadavath2022language; wei2022emergent]. Third, the present work only considers tasks with natural language outputs. Given the ever-improving capabilities of LLMs, it would also be interesting to apply the idea in more novel setups, including but not limited to planning (where LLMs act as autonomous, environment-interacting agents) and multi-modal settings beyond pure NLP problems.

Lastly, we note that especially for the generative tasks (SFG and LFG), in many cases USP greatly improves the zero-shot performance but does not always completely close the gap compared to the few-shot baseline using golden examples. There are also cases where USP does not meaningfully improve over zero-shot baselines. While we provide a brief analysis in Section 5 to investigate when that happens, it would also be helpful to investigate whether there are potential remedies, especially given that, as discussed, such occasional performance deterioration even occurs with few-shot prompting with golden demonstrations. We defer thorough investigations to future work.

# Appendix: Additional Related Works

In this section, we discuss additional prior works that are related to USP in various aspects.

#### Bootstrapping LLM knowledge.

The promising abilities of LLMs have led to efforts to improve them with their own outputs: Meng et al. [meng-etal-2020-text] use class names only and self-training to improve text classification; Zelikman et al. [zelikman2022star] bootstrap reasoning from LLMs, from a few labeled data; Huang et al. [huang2022large] use self-consistency to generate a large number of reasoning traces and fine-tune on them; Zhou et al. [zhou2022large] use LLMs themselves to automatically program prompts; Wang et al. [wang2022self] and Honovich et al. [honovich2022unnatural] use LLMs to generate large instruction datasets for downstream tasks. Collectively, while conceptually related to our work, these previous works deal with a fundamentally different problem, require a more computationally intensive learning procedure (e.g., fine-tuning), or are not fully zero-shot.

#### Prompt automation & ICL.

Numerous methods have been proposed to automate prompt design -- USP also endeavors to achieve so by focusing on ICL, a specific component of the prompt. _Soft prompting_ methods optimize the embedding space of the LLMs [li-liang-2021-prefix; lester-etal-2021-power inter alia] but require gradient access & propagation through massive LLMs and a considerable amount of training data. Recently, various _hard prompting_ methods, which search for actual discrete tokens using discrete optimization [shin-etal-2020-autoprompt; prasad2022grips; wen2023hard], reinforcement learning [deng-etal-2022-rlprompt; zhang2023tempera] and gradient estimation [diao2022black] have been proposed. While the discrete prompts are more interpretable and (in some cases) compatible with black-box, inference-only LLMs, to our knowledge, none works in the zero-shot setup and tasks beyond CLS problems (with our definition in Section 3.3) are scarcely investigated. Furthermore, unlike USP, these methods also often require hundreds if not thousands of LLM queries before converging to good prompts. As for ICL, most methods focus on retrieving the best in-context examples from a pool of _golden examples_ instead of zero-shot [rubin-etal-2022-learning; liu-etal-2022-makes]; an exception is AutoCoT which we discuss in Section 4. Additionally, several other prompting approaches like NPPrompt [zhao2022pre] & Null Prompt [logan-iv-etal-2022-cutting] are also proposed, but these methods again only work for CLS tasks and are orthogonal to USP since they target other aspects of prompting other than the in-context examples.

# Appendix: Datasets and Models

## Datasets

On PaLM-62B and PaLM-540B, we consider the following datasets:

**CLS tasks**: commonsense reasoning: boolq, copa, winogrande, ARC easy and challenge (arc_e, arc_c), wsc; reading comprehension: raceh, racem; cloze completion: storycloze, natural language inference (NLI): anli-r{1,2,3}, rte, wic.

**SFG tasks**: open-domain QA: web_questions, natural_questions and triviaqa_wiki; reading comprehension QA: squad; word prediction: lambada.

**LFG tasks**: two summarization tasks: xsum and wikilingua (en -- _English only_).

On PaLM 2 models, we use the BIG-Bench Hard dataset consisting of 23 sub-tasks. The tasks, in alphabetical order, are:

1. Boolean Expressions
2. Causal Judgment
3. Date Understanding
4. Disambiguation QA
5. Dyck Languages
6. Formal Fallacies Syllogisms Negation
7. Geometric Shapes
8. Hyperbaton (Adjective Ordering)
9. Logical Deduction
10. Movie Recommendation
11. Multi-Step Arithmetic
12. Navigate
13. Object Counting
14. Penguins in a Table
15. Reasoning about Colored Objects
16. Ruin Names
17. Salient Translation Error Detection
18. Snarks
19. Sports Understanding
20. Temporal Sequences
21. Tracking Shuffled Objects
22. Web of Lies
23. Word Sorting

All tasks are converted to SFG format, and the test set of each task consists of 250 test queries.

## Models

We conduct experiments on two PaLM model variants -- one with 540 billion parameters (PaLM-540B) and one with 62 billion parameters (PaLM-62B). PaLM is a transformer-based LLM "pre-trained on a high-quality corpus of 780 billion tokens that comprise various natural language tasks and use cases. This dataset includes filtered webpages, books, Wikipedia articles, news articles, source code obtained from open source repositories on GitHub, and social media conversations" [chowdhery2022palm]. For the pretraining procedure, PaLM was trained over two TPU v4 Pods with 3072 TPU v4 chips. In all experiments, we use the quantized PaLM checkpoints (in int8 precision) for inference only without further pretraining or finetuning.

We also experiment on PaLM 2-M, a variant of the PaLM 2 models [anil2023palm]. PaLM 2, a Transformer-based model trained on UL2-like objectives [tay2022ul2], is the successor of PaLM that features stronger multilingual and reasoning abilities.

# Appendix: Implementation Details

## Prompt Templates

We largely adopt the prompt format used in GPT-3 [brown2020language] where possible.

#### BBH tasks.

For experiments using few-shot prompting templates (including few-shot, USP, AutoCoT, and Random demo when the pseudo-demos are acquired), we use the following prompt format to obtain _both_ the rationales and the final answers in one prompting step.

```
// Demos or pseudo-demos
Q: [QUERY].
A: Let's think step by step. [RATIONALE]. So the answer is [ANS].

...

// Test query
Q: [QUERY].
A: Let's think step by step.
```

For zero-shot experiments (including standard zero-shot, USP, AutoCoT, and Random demo in the stage of acquiring pseudo-demos), we use the following prompt format proposed in Kojima et al. [kojima2022large] to obtain the rationales and answers in two separate steps:

```
Q: [QUERY].
A: Let's think step by step.
```

After the rationales are obtained, the LLM is prompted again to obtain the final answer.

```
Q: [QUERY].
A: Let's think step by step. [RATIONALE].
So the answer is
```

## Additional Experimental Details

#### USP.

USP uses an auxiliary language model for computing the similarity term in the diversity objective. We use Sentence-T5-large [ni-etal-2022-sentence] for all our experiments. We use a maximum decoding step of 128 tokens for all experiments. For summarization tasks, we apply an additional filtering rule to retain answers whose number of words is between 5 and 90 (to prune out overly short and overly long summaries, which are obviously sub-optimal). For all tasks, we use the following stop tokens as marks for truncation (words after any stop tokens, including the stop tokens themselves, are truncated): "Q:, A:, \n\n" and other special tokens used in PaLM to signal the end of the response. Additionally, we also apply several additional post-processing steps for the generative tasks, in USP and all other baseline methods:

1. lambada: retain the first output word.
2. squad: remove punctuation marks, remove article words (a, an, the), and retain the portion of the outputs before any newline (\n).
3. web_questions & natural_questions: replace all punctuation marks with a white space, remove article words (a, an, the) and retain the portion of the outputs before any newline (\n).
4. LFG (summarization): since we used the prefix "Article: " at the start of each article to be summarized, we also add "Article: " to the list of stop tokens in addition to the general ones described above.

#### Baselines.

We use the same filtering rule for the baseline methods as USP. _Random demo_ baseline uses an identical procedure to USP, with the sole exception that it does not rely on the scoring functions in Section 3.3 to select the set of pseudo-demos but rather, _for each test query_ $\mathcal{T} = \{x^{(i)}\}_{i=1}^N$, it samples $K$ pseudo-demos randomly from all Stage 1 responses (note that for CLS tasks, it will also follow the procedures described in Section 3.3 to ensure fair allocation of pseudo-demos across classes). For AutoCoT, we adapt from the official implementation with a few key modifications: (i) following COSP, we also replace the SentenceBERT [reimers-gurevych-2019-sentence] with SentenceT5, a more powerful sentence-level Transformer, for fair comparison against USP; (ii) given that AutoCoT is originally designed for chain-of-thought (CoT) tasks only, we also make necessary modifications such that it is compatible with the general setup. The changes are, in fact, minimal -- we only replace the original filtering rules in CoT with the ones we described above for USP. For the few-shot baseline, we closely follow existing works [brown2020language; chowdhery2022palm] to sample $K$ demonstrations from the training split of each dataset considered, which are prepended to the test queries; we perform sampling for each test query, and thus the choice and order of the demonstrations, in general, differ from one query to another. We use the identical postprocessing rules as USP mentioned in the previous paragraph for the baselines.

# Appendix: Additional Experiments

## PaLM-62B Results

PaLM-62B results are shown in the supplementary tables.

## Few-shot USP

Instead of using zero labeled samples (0-shot) or 3 labeled samples (3-shot, or few-shot), we use 1 labeled sample per query, and use USP to generate 2 further pseudo-demos (we name this variant **USPfs** where _fs_ stands for "few-shot") -- this is to emulate the setup where scarce labeled data are available and it is desirable to use USP to augment the set of golden demonstrations.

We find that while using 3 golden examples is still the best, USPfs outperforms both standard 1-shot and USP without using any labeled example, and it also closes roughly half of the gap between 1-shot and 3-shot -- this suggests that USP routine continues to be effective in few-shot setup, and thus can also be suitable for the setups less strict than zero-shot, but where obtaining many human-labeled demonstrations is still expensive or otherwise challenging.

## Additional Comparison Between USP Scores and Ground-truth Quality

Complementary to Fig. 4, additional plots show the same relation for other tasks considered in PaLM-540B, and the aggregated results (across CLS tasks). These give further evidence that USP heuristic described in Section 3.3 selects higher quality demonstrations in comparison to the average model performance.

## Examples of Selected Pseudo-demos

Examples of generated pseudo-demos from USP on representative tasks (PaLM-540B and PaLM 2-M) demonstrate that the method successfully selects high-quality, correct examples in most cases across different task types including storycloze, anlir3, natural_questions, triviaqa_wiki, wikilingua, boolean_expressions, object_counting, tracking_shuffled_objects, disambiguation_qa, movie_review, and snarks.
