# Fairness-guided Few-shot Prompting for Large Language Models

**arXiv:** 2303.13217

**Authors:** Huan Ma, Changqing Zhang, Yatao Bian, Lemao Liu, Zhirui Zhang, Peilin Zhao, Shu Zhang, Huazhu Fu, Qinghua Hu, Bingzhe Wu

**Affiliations:** AI Lab, Tencent; Tianjin University; A\*STAR Singapore

**Year:** 2023

---

## Abstract

Large language models have demonstrated surprising ability to perform in-context learning, i.e., these models can be directly applied to solve numerous downstream tasks by conditioning on a prompt constructed by a few input-output examples. However, prior research has shown that in-context learning can suffer from high instability due to variations in training examples, example order, and prompt formats. Therefore, the construction of an appropriate prompt is essential for improving the performance of in-context learning.

In this paper, we revisit this problem from the view of predictive bias. Specifically, we introduce a metric to evaluate the predictive bias of a fixed prompt against labels or a given attributes. Then we empirically show that prompts with higher bias always lead to unsatisfactory predictive quality. Based on this observation, we propose a novel search strategy based on the greedy search to identify the near-optimal prompt for improving the performance of in-context learning.

We perform comprehensive experiments with state-of-the-art mainstream models such as GPT-3 on various downstream tasks. Our results indicate that our method can enhance the model's in-context learning performance in an effective and interpretable manner.

---

## 1. Introduction

Large language models (LLMs), such as GPT-3 and BLOOM, have demonstrated remarkable ability in performing in-context learning (ICL) on downstream tasks. ICL refers to the process of conditioning an LLM to solve various downstream tasks using prompts constructed from a few demonstration input-output pairs (i.e., few-shot prompting). Despite its impressive performance, prior research has shown that ICL suffers from high instability due to variations in the choice of in-context demonstrations, demonstration order, and prompt formats. Therefore, constructing an appropriate prompt has been identified as a critical factor for improving the performance of ICL.

Previous research studies this problem typically from two directions:

1. **Prompt tuning in the embedding space** -- injecting task-specific embeddings into hidden layers and tuning them using gradient-based optimization. However, these methods require modifying the original inference process of the model, which is impractical for black-box LM services such as GPT-3 and ChatGPT. Furthermore, prompt tuning introduces additional computational and storage costs.

2. **Prompt searching in the text space** -- optimizing prompting via searching approximate demonstration samples and ordering in the original text space. Methods construct prompts from either "global" or "local" views:
   - **Global-view methods**: optimize different elements of the prompt as a whole (e.g., diversity of demonstrations, ordering of demonstrations)
   - **Local-view methods**: optimize each individual demonstration using heuristic selection criteria (e.g., KATE)

### Limitations of Existing Methods

1. Most current research focuses on searching prompts along a single dimension (example selection or order). The overall influence of various dimensions on performance remains unclear.
2. Methods are typically based on heuristic criteria, with a gap between them and actual performance. A unified view explaining how these methods work is needed.
3. Existing methods optimize prompts globally or locally, which may lead to suboptimal performance.

### Our Approach

We revisit this problem from the perspective of **predictive bias**. We find a key insight that the quality of a given prompt depends on its inherent bias. Based on this insight, we propose a surrogate metric based on predictive bias for evaluating the quality of prompts. This metric allows us to evaluate a prompt in a single forward process without an additional development set.

Specifically, we apply a given prompt to a "content-free" input and expect the model to output a uniform predictive distribution (a content-free input contains no useful information). We employ the uniformity of the predictive distribution to characterize the bias of a given prompt.

### Contributions

- We introduce using predictive bias to assess the quality of a given prompt in an efficient and development-set-independent way
- Based on this idea, we propose two efficient and effective strategies: **T-fair-Prompting** and **G-fair-Prompting**
- The effectiveness of these strategies is validated on various LLMs ranging from GPT-series models to LLaMA family. Consistent relative improvements of over 10% have been observed over different downstream tasks

### Relation to Calibration-before-use

Our paper shares a similar metric with calibration-before-use to assess the predictive bias of a given prompt. However, the prior approach aims to use this metric to calibrate the output, which can still be easily affected by the quality of the used prompt. In contrast, our research aims to find a near-optimal prompt in the original space to improve the model's performance, without requiring any post-adjustment to the output.

---

## 2. Related Work

### In-context Learning

Previous research has demonstrated that Large Language Models can complete tasks with zero- or few-shot learning using in-context learning. LLMs perform well with an appropriate prompt. However, recent works have shown that the performance of LLMs is affected by the prompt used. Therefore, determining the optimal prompt is a crucial and fundamental research area.

### Original Space Searching

A more intuitive approach for determining the best prompt is to search in the original space by selecting or reordering the prompt sentences entered by users:

**Global view:**

- **Enumerate**: naive strategy examining all candidates (complexity: sum of C(n,k) \* k!)
- **Diversity-guided**: selecting diverse demonstrations based on error clustering
- **Order optimization**: finding best sequence yielding most diverse predictions on probing set

**Local view:**

- **Uncertainty reduction**: selecting demonstrations according to LLM uncertainty
- **KATE (similarity-based)**: selecting closest training examples in embedding space
- **Filtering**: removing irrelevant context that can distract LLMs

Most current methods focus solely on a singular factor's influence on performance, utilizing heuristic metrics. The method proposed in this paper offers a metric to select context demonstrations from the perspective of predictive bias, which naturally facilitates a transition from local to global view.

---

## 3. Revisiting the Sensitivity across Demonstrations

### 3.1 Notations

Consider a training set consisting of N samples S = {(x_i, y_i)}^N, where x_i is the sentence and y_i in Y is the label.

A template Gamma() transforms sentences and labels into natural language space (prompt construction). For example, from AGNews dataset:

- x_i = "Cubans Risking Life for Lure of America."
- y_i = "World"
- Gamma(x_i, y_i) = "Article: Cubans Risking Life for Lure of America. Answer: World"

Demonstrations are concatenated to form a prompt rho:

```
rho = Gamma(x_1, y_1) + ... + Gamma(x_n, y_n)
```

At test time, append prompt rho with tau = "Article: <test sentence>. Answer: " and feed to LLM M. The predicted class is:

```
y_hat = argmax_{y in Y} p_hat(y | rho + tau)
```

where the probability is normalized to fit the task.

### 3.2 Stability of Few-shot Prompting

The few-shot prompting technique is highly susceptible to:

- Selection of demonstrations
- Order of demonstrations

Experiments show significant variability in accuracy across:

- Different demonstration selections (even with random order sampling)
- Different permutations of fixed demonstrations

While post-calibration contributes to mitigating instability, the model remains sensitive even after calibration. This underscores the importance of meticulous demonstration selection.

### 3.3 Predictive Bias of ICL

The performance of ICL is significantly impacted by various factors. Devising an efficient method for constructing an appropriate prompt with near-optimal performance is crucial for deploying LLMs.

We investigate this through the lens of **predictive bias** -- the discrepancy between targeted classes.

**Fairness Metric Definition:**

We construct a training-set-independent metric:

1. Merge the provided prompt with a "semantic-free" test sample (e.g., "[N/A]", denoted by eta)
2. Obtain the LLM's predictive distribution for this sample
3. Ideally, the distribution should closely resemble uniform (since test sample lacks semantic information)

We employ entropy as a measure of predictive bias:

```
fair(rho) = -sum_{y in Y} p(y | rho + eta) * log(p(y | rho + eta))
```

**Key Finding:** Through comprehensive experiments enumerating all possible combinations and permutations of demonstrations, we observe a **strong correlation between the model's performance and fairness score** (i.e., fairer prompts yield better performance). The "Oracle" representing optimal average performance consistently correlates with higher fairness.

This observation prompts us to enhance ICL performance by identifying the fairest prompt.

---

## 4. Fairest Prompt Search

Given the observation that fairer prompts yield better performance, we propose two strategies for finding the most fair prompt.

### Challenge

Discovering the fairest demonstration combination is formidable given the existence of sum\_{k=1}^N C(N,k) \* k! distinct candidates. As training set size increases, this becomes intractable.

### 4.1 T-fair-Prompting (Top-k Fair Prompting)

**Central idea:** The fairest prompt usually consists of demonstration samples with reduced individual biases.

**Two-stage process:**

1. Assess prediction bias when prompt is formulated using individual demonstrations
2. Select top-k fairest demonstrations to prompt the LLM

**Note:** Fairer demonstrations are likely situated towards the end of the sequence, as generation is more influenced by proximate demonstrations.

**Complexity:** O(N)

**Algorithm:**

```
Given: training set S, pretrained LLM M, template Gamma, context-free input eta
Initialize prompt rho
For each (x_i, y_i) in S:
    Inference p_hat = {p(y | Gamma(x_i, y_i) + eta) | y in Y} via M
    Calculate fair(Gamma(x_i, y_i))
Sort fairness scores in descending order
For d in 1, ..., k:
    Insert the d-th most fair demonstration at head of rho
Return rho
```

**Limitation:** Heavily reliant on chosen value of k and addresses issue through purely local perspective, neglecting global considerations.

### 4.2 G-fair-Prompting (Greedy Fair Prompting)

**Central idea:** Follow standard greedy search procedure, making locally optimal choices at each stage that achieve the highest fairness score.

**Key properties:**

- Operates from local to global perspective
- Early stages: individual sample bias considered
- Later stages: focus on reducing global predictive bias
- Balances search quality with worst-case time complexity

**Complexity:** O(N^2)

**Algorithm:**

```
Given: training set S, pretrained LLM M, template Gamma, context-free input eta
Initialize prompt rho
While S is not null:
    For each (x_i, y_i) in S:
        rho_tmp = Gamma(x_i, y_i) + rho
        Inference p_hat = {p(y | rho_tmp + eta) | y in Y} via M
        Calculate fair(rho_tmp)
    Insert demonstration that improves fairness best
    Remove it from S
    Stop when fairness can't be improved
Return rho
```

**Selection criterion at each step:**

```
argmax_{x_i in S'} fair(Gamma(x_i, y_i) + rho)
subject to: fair(Gamma(x_i, y_i) + rho) > fair(rho)
```

---

## 5. Experiments

### 5.1 Experimental Setup

**Models:**

- BLOOM (176B)
- LLaMA (7B, 13B, 33B, 65B)
- GPT2-XL (1.5B)

**Datasets:**

| Corpus | Task          | Classes | Domain          |
| ------ | ------------- | ------- | --------------- |
| SST-2  | sentiment     | 2       | movie reviews   |
| TREC   | QA/QC         | 6       | open domain     |
| AGNews | topic         | 4       | news            |
| CoLA   | acceptability | 2       | misc.           |
| RTE    | NLI           | 2       | news, Wikipedia |

### 5.2 Results

**Comparison methods:**

- Random: average accuracy for enumerating all situations
- Diversity: demonstrations selected according to diversity
- Similarity: demonstrations selected according to similarity (requires searching for every test example)

**Key findings:**

#### G-fair-Prompting reaches close approximation of enumeration

Most prompts searched by G-fair-Prompting achieved top 20% ranking. On BLOOM (176B), it almost found the most fair prompt.

#### G-fair-Prompting outperforms T-fair-Prompting

Although T-fair-Prompting achieves better performance compared with random selection, G-fair-Prompting consistently outperforms it. Top-2 significantly outperforms Top-4 in most cases (over 5%), indicating that the number of demonstrations selected is crucial.

#### Compared with SOTA methods

- G-fair-Prompting outperforms most SOTA methods in most situations
- Improvements of over 10% observed on TREC dataset
- Similarity-guided method achieved best performance on topic classification (AGNews) by searching unique prompt for every test example based on embedding distance
- However, similarity-guided strategy exhibits lower performance than random selection in QC and acceptability tasks

#### Comparison with Calibration Method

- When the selected prompt is of poor quality, performance remains inadequate even after calibration
- G-fair-Prompting can outperform random selection with calibration in most situations
- Post-calibration can harm model performance in many scenarios, so directly manipulating model probability should be reconsidered

### Results Table (Selected)

| Model        | Dataset | Random | Diversity | Similarity | Top-2 | Top-4 | Greedy   |
| ------------ | ------- | ------ | --------- | ---------- | ----- | ----- | -------- |
| BLOOM (176B) | SST2    | 92.7   | **95.0**  | 94.0       | 94.6  | 93.8  | 91.2     |
| BLOOM (176B) | AGNews  | 73.9   | 70.2      | 74.8       | 75.4  | 74.8  | **79.6** |
| BLOOM (176B) | TREC    | 47.9   | 46.0      | 31.4       | 55.4  | 39.2  | **66.8** |
| LLaMA (65B)  | TREC    | 63.6   | 65.2      | 64.0       | 65.8  | 57.4  | **74.0** |
| LLaMA (65B)  | CoLA    | 66.2   | 62.6      | 59.2       | 67.6  | 62.6  | **72.0** |

---

## 6. Additional Analysis

### Accuracy Varies with Demonstrations

**Example amount:** Erasing some demonstrations can result in better performance. Sometimes LLMs achieve best accuracy with only a few demonstrations remaining, highlighting the importance of considering appropriate number of demonstrations.

**Example order:** Different permutations of demonstrations can result in vastly different outcomes.

**Example selection:** Which demonstrations are selected influences the model extremely.

### Relationship between with- and without-calibration

If prompts with better performance before calibration are positively correlated with performance after calibration (Pearson correlation coefficient > 0), then finding a prompt with high accuracy before calibration yields higher likelihood of achieving higher accuracy after calibration.

Findings:

- Majority of Pearson correlation coefficients were positive
- Larger models show stronger correlation between with/without calibration performance
- Pearson correlation coefficient increases from 0 to 0.7 as model size increases

**Theorem:** Suppose performance with- and without-calibration is positively correlated. If E(acc_selected_w/o) > E(acc_random_w/o), then E(acc_selected_with) > E(acc_random_with).

---

## 7. Conclusion

In this paper, we revisit the sensitivity of large language models across prompts and analyze the issue from a predictive bias perspective. We employ a "content-free" strategy as a metric termed fairness to evaluate the predictive bias of a fixed prompt and show that model's performance is highly consistent with fairness. We propose two strategies to search for the most fair prompt in the original space. We conduct extensive experiments on current famous LLMs and validate the effectiveness of the proposed strategies. In addition to fairness adopted in this paper, there would be more metrics for prompt searching in the future for different scenarios.

---

## Key Takeaways for Prompt Engineering

1. **Predictive bias correlates with performance:** Prompts that produce more uniform (fair) predictions on content-free inputs tend to yield better task performance.

2. **Use fairness as a proxy metric:** Instead of requiring labeled development sets, evaluate prompts by measuring entropy of predictions on semantic-free inputs like "[N/A]".

3. **Local-to-global search works:** Starting with individually fair demonstrations and iteratively building up (G-fair-Prompting) finds near-optimal prompts efficiently.

4. **Number of demonstrations matters:** More is not always better. Fewer, well-chosen demonstrations can outperform many poorly chosen ones.

5. **Order affects outcomes:** Even with the same demonstrations, different orderings significantly impact results.

6. **Greedy beats top-k:** G-fair-Prompting with O(N^2) complexity consistently outperforms simpler T-fair-Prompting with O(N) complexity.

7. **Better prompts improve calibration:** Finding better prompts before calibration leads to better post-calibration results.

---

## References

- Brown et al. (2020). Language Models are Few-Shot Learners. NeurIPS.
- Zhao et al. (2021). Calibrate Before Use: Improving Few-Shot Performance of Language Models. ICML.
- Lu et al. (2021). Fantastically Ordered Prompts and Where to Find Them: Overcoming Few-Shot Prompt Order Sensitivity. ACL.
- Liu et al. (2021). What Makes Good In-Context Examples for GPT-3?
- Zhang et al. (2022). Automatic Chain of Thought Prompting in Large Language Models.
- Touvron et al. (2023). LLaMA: Open and Efficient Foundation Language Models.
