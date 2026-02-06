# Abstract

GPT-3 [brown2020language] has attracted lots of attention due to its superior performance across a wide range of NLP tasks, especially with its powerful and versatile in-context few-shot learning ability. Despite its success, we found that the empirical results of GPT-3 depend heavily on the choice of in-context examples. In this work, we investigate whether there are more effective strategies for judiciously selecting in-context examples (relative to random sampling) that better leverage GPT-3's few-shot capabilities. Inspired by the recent success of leveraging a retrieval module to augment large-scale neural network models, we propose to retrieve examples that are semantically-similar to a test sample to formulate its corresponding prompt. Intuitively, the in-context examples selected with such a strategy may serve as more informative inputs to unleash GPT-3's extensive knowledge. We evaluate the proposed approach on several natural language understanding and generation benchmarks, where the retrieval-based prompt selection approach consistently outperforms the random baseline. Moreover, it is observed that the sentence encoders fine-tuned on task-related datasets yield even more helpful retrieval results. Notably, significant gains are observed on tasks such as table-to-text generation (41.9% on the ToTTo dataset) and open-domain question answering (45.5% on the NQ dataset). We hope our investigation could help understand the behaviors of GPT-3 and large-scale pre-trained LMs in general and enhance their few-shot capabilities.

# Introduction

GPT-3 [brown2020language] is a new breakthrough in NLP research. Previously, NLP models are pre-trained on large quantities of data and fine-tuned on a specific task and dataset. What sets GPT-3 apart from other pre-trained language models is its impressive "in-context" few-shot learning ability. Provided with a few in-context examples, GPT-3 is able to generalize to unseen cases without further fine-tuning. This opens up many new technological possibilities that are previously considered unique to human. For example, NLP systems can be developed to expand emails, extract entities from text, generate code based on natural language instructions with a few demonstration examples.

Despite its powerful and versatile in-context learning ability, GPT-3 has some practical challenges/ambiguities. The original paper [brown2020language] utilizes task-relevant examples that are randomly sampled from the training set to construct the context. In practice, we observe that the performance of GPT-3 tends to fluctuate with different choices of in-context examples. As shown in Table 1, the variance of the empirical results with distinct in-context examples can be significant. The results are highly sensitive to the examples. Our work aims to carefully examine this issue to gain a deeper understanding on how to better select in-context examples to unleash GPT-3's few-shot capabilities and further improve its performance.

**Table 1: Results of GPT-3 on the task of sentiment analysis on the SST-2 dataset. Five different in-context examples are randomly selected from the training set. We observe different contexts induce different accuracies on the test set.**

| Trial | 1 | 2 | 3 | 4 | 5 |
|-------|------|------|------|------|------|
| Accuracy | 94.6 | 95.0 | 95.8 | 93.9 | 86.9 |

A brute-force approach would be to perform combinatorial search over the entire dataset. Unfortunately, this strategy is computationally expensive and thus impractical in many cases. To this end, we investigate the influences of employing different in-context examples on the empirical results. Interestingly, we found that the in-context examples that are closer to the test sample in the embedding space consistently give rise to stronger performance (relative to the farther ones). Inspired by this observation and the recent success of retrieval-augmented models [hashimoto2018retrieve], we propose to utilize nearest neighbors of a given test sample (among all the training instances available) as the corresponding in-context examples. The retrieved examples, along with the test sample, are provided to GPT-3 for the final prediction.

To verify the effectiveness of the proposed method, we evaluate it on several natural language understanding and generation tasks, including sentiment analysis, table-to-text generation and open-domain question answering. It is observed that the retrieval-based in-context examples unleash the few-shot capabilities of GPT-3 much more effectively than a random sampling baseline. Even with a smaller number of in-context examples, the proposed strategy empowers GPT-3 to achieve stronger performance. Moreover, we find that the specific sentence encoders employed for the retrieval procedure play a critical role. Thus, an extensive exploration regarding different pre-trained encoders is conducted, and it is shown that encoders fine-tuned on natural language matching tasks serve as more effective in-context examples selector on the QA task. Detailed analysis and case study further validate the effectiveness of proposed methods. In summary, our contributions in this paper are as follows:

1. To the best of our knowledge, we take a first step towards understanding the sensitivity of GPT-3's few-shot capabilities with respect to the selection of in-context examples;

2. To alleviate the sensitivity issue, an additional retrieval module is introduced to find semantically-similar in-context examples of a test instance to construct its corresponding input, which greatly outperforms the baseline based on random sampled examples;

3. Fine-tuning the retrieval model on task-related dataset(s) leads to even stronger empirical results with GPT-3;

4. The performance of GPT-3 improves as the number of examples available for retrieval increases.

# Method

## GPT-3 for In-Context Learning

The in-context learning scenario of GPT-3 can be regarded as a conditional text generation problem. Concretely, the probability of generating a target y is conditioned on the context C, which includes k examples, and the source x. Therefore, the prediction y corresponding to the source x can be expressed as:

```latex
$$p_{\text{LM}}(y|C, x) = \prod_{t=1}^T p(y_t|C, x, y_{<t})$$
```

where LM denotes the parameters of the language model, and ```latex $C=\{x_1, y_1, x_2, y_2, ..., x_k, y_k\}$ ``` is a context string. In GPT-3, the C is created by concatenating k training instances along with their corresponding labels. As shown in Figure 1, GPT-3 is asked to translate "mountain" to its German version based on the three examples given as part of the input.

[IMAGE: Figure 1 - In-context learning diagram showing how three in-context examples and the test prompt are concatenated as a single string input for GPT-3, with a special character "\n" inserted between two adjacent examples. GPT-3 keeps generating tokens until there is a special character "\n".]

For GPT-3, this generation process is implemented through a giant transformer-based model architecture [vaswani2017attention; brown2020language]. Given the large size of the GPT-3 model, it would be very computationally-involved to fine-tune it on task-specific samples. Thus, GPT-3 is typically leveraged in a in-context learning manner as described above. It has been shown that GPT-3 has powerful few-shot capabilities, where it can perform quite well with only a small number of demonstrations provided. Unfortunately, as shown in Table 1, the results of GPT tends to fluctuate significantly with different in-context examples chosen. Here we aim to alleviate this issue via judicious in-context examples selection.

[IMAGE: Figure 2 - kNN workflow showing in-context example selection for GPT-3. White dots: unused training samples; grey dots: randomly sampled training samples; red dots: training samples selected by the k-nearest neighbors algorithm in the embedding space of a sentence encoder.]

## The Impact of In-Context Examples

Given the observation that the empirical results of GPT-3 are sensitive to the chosen in-context examples, we look at the role of in-context examples from an empirical perspective. Previous retrieve-and-edit literatures usually retrieve prototypes that are close to the test source x in some embedding space. These examples and the test source x often share semantic or lexical similarities. This hints on how we may select in-context examples for GPT-3.

To this end, we examine the impact of the distance between in-context example and the test sample on GPT-3's performance. Concretely, a comparison is made on the the Natural Questions (NQ) dataset between two in-context example selection strategies. Given each test example, the first method utilizes the 10 farthest training instances to construct the context provided to GPT-3, while the second employs the 10 closest neighbors. We use the CLS embeddings of a pre-trained RoBERTa-large model as the sentence representations to measure the proximity of two sentences (using the Euclidean distance).

**Table 2: Comparison of the EM score on the closest 10 neighbors and farthest 10 neighbors on a subset of 100 test samples of the NQ dataset.**

| Method | Closest | Farthest |
|--------|---------|----------|
| Accuracy | **46.0** | 31.0 |

For evaluation, 100 test questions are randomly sampled and the average Exact Match (EM) scores with the two distinct strategies are reported in Table 2. It can be observed that the nearest neighbors, as the in-context examples, give rise to much better results relative to the farthest ones. Moreover, the pre-trained RoBERTa model serves as effective sentence embeddings for the retrieval procedure.

## kNN-augmented In-Context Example Selection

Based on the findings above, we propose KATE (kNN-Augmented in-conText Example selection), a strategy to select good in-context examples for in-context learning. The process is visualized in Figure 2. Specifically, we first use a certain sentence encoder to convert sources in both the training set and test set to vector representations. For online prediction, we can convert the training set first and encode each test source on the fly. Then, for each test source x, we retrieve its nearest k neighbors ```latex $x_1, x_2, ..., x_k$ ``` from the training set (according to the distances in the sentence encoder's embedding space). Given some pre-defined similarity measure d such as the cosine similarity, the neighbors are ordered in such a way that ```latex $d(x_i, x) \leq d(x_j, x)$ ``` when i < j.

**Algorithm 1: kNN In-context Example Selection**

**Given:** test prompt ```latex $\mathbf{x}_{\text{test}}$ ```, training set ```latex $\mathcal{D}_T=\{\mathbf{x}_i, \mathbf{y}_i\}_{i=1}^N$ ```, sentence encoder ```latex $\mu_{\theta}(\cdot)$ ```, and number of in-context examples k (hyperparameter).

1. ```latex $\mathbf{v}_{\text{test}} = \mu_{\theta}(\mathbf{x}_{\text{test}})$ ```
2. For each ```latex $\mathbf{x}_i \in \mathcal{D}_T$ ```:
   - ```latex $\mathbf{v}_i = \mu_{\theta}(\mathbf{x}_i)$ ```
   - ```latex $\mathbf{s}_i = -\lVert \mathbf{v}_{\text{test}} - \mathbf{v}_i \rVert_2$ ``` (or ```latex $\frac{\mathbf{v}_{\text{test}} \cdot \mathbf{v}_i}{\lVert \mathbf{v}_{\text{test}} \rVert_2 \lVert \mathbf{v}_i \rVert_2}$ ```)
3. Select largest k similarities ```latex $\mathbf{s}_i$ ```'s (in descending order) with indices ```latex $\{\sigma(1), ..., \sigma(k)\}$ ```
4. ```latex $C = [\mathbf{x}_{\sigma(1)}; \mathbf{y}_{\sigma(1)}; ...; \mathbf{x}_{\sigma(k)}; \mathbf{y}_{\sigma(k)}]$ ```
5. ```latex $\hat{\mathbf{y}}_{\text{test}} = \text{GPT-}3 ([C; \mathbf{x}_{\text{test}}])$ ```

Afterwards, the k sources are concatenated with their corresponding targets to form the context ```latex $C=\{x_1, y_1, x_2, y_2, ..., x_k, y_k\}$ ```, which is further sent to GPT-3 along with the test input. Note that different numbers of in-context examples can be employed here, and we conduct ablation study on its impact in a later section.

### Choices of Retrieval Module

A core step for our context selection approach is mapping sentences into a latent semantic space, leaving a question as what sentence encoders we should choose. We compared among existing pre-trained text encoders and found them sufficient to retrieve semantically similar sentences. The sentence encoders can be divided into two categories.

The first category includes most generally pre-trained sentence encoders such as a pre-trained BERT, RoBERTa, or XLNet models. These models have been trained on large quantities of unsupervised tasks and achieved good performance on many natural language tasks. The corresponding embeddings contain rich semantic information from the original sentences.

The second category includes sentence encoders fine-tuned on specific tasks or datasets. For example, a sentence encoder trained on the STS benchmark dataset should be able to assess similarities among different questions better than a generally pre-trained sentence encoder. [reimers2019sentence; reimers2020making] have shown that these fine-tuned encoders have achieved great performance on tasks such as sentence clustering, paraphrase mining, and information retrieval.

# Experimental Setup

**Table 3: Data split for different datasets. In-context examples are selected from the training set. Because ToTTo and TriviaQA require submitting to their leaderboards, the evaluation is done on the dev sets. For all other datasets, the evaluation is done on the test sets.**

| Dataset | Train | Dev | Test |
|---------|-------|-----|------|
| SST-2 | 67k | 872 | 1.8k |
| IMDB | 25k | - | 25k |
| ToTTo | 120k | 7.7k | 7.7k |
| NQ | 79k | 8.8k | 3.6k |
| WQ | 3.4k | 361 | 2k |
| TriviaQA | 78.8k | 8.8k | 11.3k |

We apply the kNN in-context selection method to the following three tasks: sentiment classification, table-to-text generation, and question answering (QA). Datasets and the common data split setups are shown in Table 3. In terms of the hyper-parameters in the GPT-3 API, we set the temperature to 0. We let GPT-3 keep generating tokens until there is a special token "\n".

## Sentence Embeddings for Retrieval

To retrieve semantically-similar training instances, we consider two types of sentence embeddings.

- The original pre-trained RoBERTa-large model [liu2019roberta], which is abbreviated as ```latex $\text{KATE}_{\text{roberta}}$ ```;

- The RoBERTa-large model fine-tuned on task-related datasets: (i) fine-tuned on the SNLI and MultiNLI dataset (```latex $\text{KATE}_{\text{nli}}$ ```); (ii) first fine-tuned on the SNLI and MultiNLI dataset and then on the STS-B dataset (```latex $\text{KATE}_{\text{nli+sts-b}}$ ```).

Notably, all the sentence encoders share the same the architecture, where the only differences are the specific datasets used for fine-tuning. Euclidean distance is used for the ```latex $\text{KATE}_{\text{roberta}}$ ``` case, while cosine similarity is employed for ```latex $\text{KATE}_{\text{nli}}$ ``` and ```latex $\text{KATE}_{\text{nli+sts-b}}$ ```.

### Sentiment Analysis

For sentiment classification, we select in-context examples under the transfer setting, where one dataset is treated as the training set and the evaluation is made on another dataset. This transfer setting is designed to simulate a real-world scenario where we would like to leverage an existing labeled dataset for a unlabeled one (of a similar task).

Specifically, we select in-context examples from the SST-2 training set [socher2013recursive; wang2018glue] and ask GPT-3 to make predictions on the IMDB test set [maas2011learning]. To explore whether a sentence encoder fine-tuned on a similar task would benefit KATE's performance, we also employ a pre-trained RoBERTa-large model fine-tuned on the SST-2 training set (dubbed as ```latex $\text{KATE}_{\text{sst-2}}$ ```). The performance is measured by the accuracy over the entire IMDB test set. The number of in-context examples is chosen to be 3 since adding more examples does not further improve the performance.

### Table-to-Text Generation

Given a Wikipedia table and a set of highlighted cells, this task focuses on producing human-readable texts as descriptions. ToTTo [parikh2020totto] is utilized for evaluation due to its popularity. We use BLEU [papineni2002bleu] and PARENT [dhingra2019handling] metrics for evaluation. The ToTTo code base contains both evaluation and preprocessing scripts. Due to the input length limit of GPT-3 (currently the token limit is 2048), we add an extra preprocessing step by deleting the closing angle brackets such as </cell> and </table> to save some space. The number of in-context examples is set as 2.

### Question Answering

Given a factual question, the model is asked to generate the correct answer. Following prior studies, we use the Exact Match (EM) score to measure the performance of GPT-3 on open-domain QA tasks. The EM score is defined as the proportion of the number of predicted answers being exactly the same as (one of) the ground-truth answer(s). The matching is performed after string normalization, which includes article and punctuation removal. We conduct experiments on three open-domain QA benchmarks: Natural Questions (NQ) [kwiatkowski2019natural], Web Questions (WQ) [berant2013semantic], and Trivia Question Answering (TriviaQA) [joshi2017triviaqa]. For this task, we pick the nearest 64 neighbors as the in-context examples for NQ and WQ and nearest 10 neighbors for TriviaQA (The retrieved 64 examples could not fit into 2048 token limit for TriviaQA. For fair comparison, we set the number of in-context examples to be 10 for TriviaQA for both the baseline and KATE method). The evaluation is done on the test sets of NQ and WQ and the dev set of TriviaQA.

## Baseline Methods

### Random Sampling

For each test sentence, we randomly select in-context examples from the training set. We refer to this method as *Random* in the experimental results. To have a fair comparison with KATE, the number of in-context examples in this random baseline is the same as KATE to ensure fair comparison. On the test set, the random baseline is repeated for five times to obtain the average score and corresponding standard deviation.

### k-Nearest Neighbor

Additionally, to investigate whether the retrieval module is complementary to GPT-3's few-shot learning ability, we further consider a k-nearest neighbor baseline. Specifically, for text generation tasks, the target ```latex $y_1$ ``` associated with the first retrieved example is considered as the predicted target for the test sample. As to the sentiment analysis and QA tasks, the top k retrieved examples ```latex $\{y_1, ..., y_k\}$ ``` are utilized, where the final prediction is determined by majority voting among the k examples' targets. If there is a tie case, we take the target of the example that is most similar to the test sentence as the prediction. To ensure fair comparison, we compare the baseline kNN and KATE under the same embedding space of a pre-trained RoBERTa-large model. This baseline is abbreviated as ```latex $k\text{NN}_{\text{roberta}}$ ```.

# Experimental Results

## Sentiment Analysis

**Table 4: Accuracy of sentiment prediction for GPT-3 on IMDB with different choices of in-context examples. In-context examples are from the SST-2 dataset.**

| Method | Accuracy |
|--------|----------|
| Random | 87.95 +/- 2.74 |
| kNN_roberta | 50.20 |
| KATE_roberta | 91.99 |
| KATE_nli | 90.40 |
| KATE_nli+sts-b | 90.20 |
| KATE_sst-2 | **93.43** |

We first evaluate KATE on the sentiment analysis task. The results are shown in Table 4. It can be observed that KATE consistently produces better performance relative to the random selection baseline. Notably, there is no variance with the obtained results since the same set of retrieved in-context examples are employed. For the KATE method, when a pre-trained sentence encoder is fine-tuned on NLI or NLI+STS-B datasets, the performance slightly decreases. Since the objectives of the IMDB dataset and the NLI+STS-B datasets are different, this shows that fine-tuning on a dissimilar task can hurt KATE's performance. Moreover, ```latex $\text{KATE}_{\text{nli+sts-b}}$ ``` performs worse than ```latex $\text{KATE}_{\text{nli}}$ ``` because the sentence encoder has been further fine-tuned on the STS-B dataset. In contrast, ```latex $\text{KATE}_{\text{sst-2}}$ ``` obtains the best accuracy, showing that fine-tuning on a similar task can benefit KATE's performance. To verify that the gains are not merely from the retrieval step, we further compare ```latex $\text{KATE}_{\text{roberta}}$ ``` with the ```latex $k\text{NN}_{\text{roberta}}$ ```. It turns out that the performance of the ```latex $k\text{NN}_{\text{roberta}}$ ``` method is similar to random guessing. This observation is consistent when one neighbor or three neighbors are retrieved. Notably, with the embeddings of the RoBERTa-large model fine-tuned on the SST-2 dataset, the accuracy of ```latex $k\text{NN}_{\text{sst-2}}$ ``` is 92.46, which is lower than that obtained with ```latex $\text{KATE}_{\text{sst-2}}$ ```. These results suggest that the GPT-3 model is critical to the final results, and the retrieval module is complementary to GPT-3's few-shot capabilities.

## Table-to-text Generation

**Table 5: Table-to-text generation results on the ToTTo dev dataset.**

| Method | Overall BLEU | Overall PARENT | Overlap BLEU | Overlap PARENT | Nonoverlap BLEU | Nonoverlap PARENT |
|--------|--------------|----------------|--------------|----------------|-----------------|-------------------|
| Random | 28.4 +/- 2.1 | 39.3 +/- 2.6 | 31.2 +/- 2.5 | 41.8 +/- 3.0 | 25.6 +/- 1.8 | 37.0 +/- 2.3 |
| kNN_roberta | 14.1 | 12.6 | 20.1 | 17.9 | 8.0 | 7.52 |
| KATE_roberta | **40.3** | **49.7** | **47.8** | **55.0** | **32.9** | **44.6** |
| KATE_nli | 39.1 | 48.5 | 46.5 | 53.7 | 31.9 | 43.6 |
| KATE_nli+sts-b | 38.1 | 47.2 | 45.2 | 52.2 | 31.1 | 42.4 |

We utilize the ToTTo dataset to evaluate KATE on the table-to-text generation task. The results are shown in Table 5. The KATE method gives rise to considerable gains over the random baseline, according to both the BLEU and PARENT scores. On a finer scale, the evaluation can be done on the overlap subset and the nonoverlap subset. The overlap dev subset shares a significant number of header names with the training set, while the nonoverlap one does not share any header names. It can be observed that the KATE method improves the results on both the overlap and the nonoverlap subsets, meaning that the retrieval module is helpful for both situations where the test set follows the distribution of the training set and where the test set is out of distribution of the training set. Similar to sentiment analysis, there is a slight drop in performance from ```latex $\text{KATE}_{\text{roberta}}$ ``` to ```latex $\text{KATE}_{\text{nli}}$ ``` and ```latex $\text{KATE}_{\text{nli+sts-b}}$ ```. This is due to the difference between the objectives of the ToTTo dataset and NLI+STS-B datasets. The drop from ```latex $\text{KATE}_{\text{nli}}$ ``` to ```latex $\text{KATE}_{\text{nli+sts-b}}$ ``` further validates the idea that fine-tuning on a dissimilar task can hurt KATE's performance. For the kNN baseline, it performs much worse than the random selection method and the KATE method, again suggesting that the retrieval process and GPT-3 work together collaboratively to achieve better results.

To understand how the retrieval mechanism helps GPT-3's predictions, we conduct a case study on the retrieved examples. By retrieving relevant examples from the training set, KATE provides useful detailed information within the table, *e.g.*, the number of points, rebounds, and assists, to GPT-3 for more accurate description. On the other hand, the random selection method has the issue of hallucination, where the generated sequences contain information (*i.e.*, "senior year" and "University of Texas") not present in the table.

## Question Answering

**Table 6: QA results on various datasets. (*) On TriviaQA, we used 10 examples. On NQ and WQ, we used 64 examples.**

| Method | NQ | WQ | TriviaQA* |
|--------|----|----|-----------|
| RAG (Open-Domain) | 44.5 | 45.5 | 68.0 |
| T5+SSM (Closed-Book) | 36.6 | 44.7 | 60.5 |
| T5 (Closed-Book) | 34.5 | 37.4 | 50.1 |
| GPT-3 (64 examples) | 29.9 | 41.5 | - |
| **Ours** | | | |
| Random | 28.6 +/- 0.3 | 41.0 +/- 0.5 | 59.2 +/- 0.4 |
| kNN_roberta | 24.0 | 23.9 | 26.2 |
| KATE_roberta | 40.0 | 47.7 | 57.5 |
| KATE_nli | 40.8 | **50.6** | 60.9 |
| KATE_nli+sts-b | **41.6** | 50.2 | **62.4** |

[IMAGE: Figure 3 - Ablation studies. Left: Effect of number of in-context examples for GPT-3 for different selection methods. Right: Effect of the size of training set for retrieval on KATE. Two representative sentence encoders are used in the ablation study.]

We also evaluate KATE on the open-domain QA tasks, as shown in Table 6. For the QA tasks, we compare with some state-of-the-art methods such as RAG [lewis2020retrieval] and T5 [raffel2019exploring]. Both methods require fine-tuning on the specific datasets. The KATE method again improves GPT-3's few-shot prediction accuracies substantially across various benchmarks. It is worth noting that the fine-tuned transformer models serve as better sentence encoders for retrieval purpose (compared with the RoBERTa-large model without fine-tuning). ```latex $\text{KATE}_{\text{nli}}$ ``` and ```latex $\text{KATE}_{\text{nli+sts-b}}$ ``` improve upon ```latex $\text{KATE}_{\text{roberta}}$ ``` because this time fine-tuning on NLI or STS-B datasets is helpful for retrieving semantically similar questions from the QA datasets. Moreover, on the NQ and TriviaQA datasets, further fine-tuning on the STS-B dataset improves KATE's results. We also try reducing the number of in-context examples to be as small as five for both the random and KATE methods, where KATE outperforms the baseline as well. Therefore, the advantage of KATE over the random baseline holds for both small and large numbers of in-context examples. We evaluate the other baseline ```latex $k\text{NN}_{\text{roberta}}$ ``` by using the top-1 nearest neighbor. We also explore using 64 nearest neighbors (10 for TriviaQA) to determine the answer (by majority voting). The EM score tends to be similar to retrieving the top-1 nearest neighbor. These kNN baseline results again suggest that the retrieval module and GPT-3 work together to achieve better performance.

To investigate why the retrieval examples are helpful, we further present a case study. For the first and second cases, the random baseline provides wrong answers because GPT-3 is unable to recall the exact detail. However, the in-context examples selected by KATE contain the correct details, which facilitates GPT-3 to answer the questions. For the third test question, the random baseline leads GPT-3 to misinterpret the question as asking for a specific location. In contrast, KATE selects similar questions which ask for the origins of objects. Using these in-context examples, GPT-3 is able to interpret and answer the question correctly.

# Analysis and Ablation Study

## Number of In-context Examples

We first investigate the impact of the number of in-context examples on KATE's performance. Concretely, on the NQ dataset, we choose the number of in-context examples to be 5, 10, 20, 35, and 64, and ```latex $\text{KATE}_{\text{nli+sts-b}}$ ``` is compared with the random baseline and ```latex $\text{KATE}_{\text{roberta}}$ ``` across different settings. As shown in the left plot of Figure 3, both KATE and the random baseline benefit from utilizing more in-context examples. However, KATE consistently outperforms the random selection method, even when the number of in-context examples is as few as 5. This result is interesting because in practice, employing less in-context leads to more efficient inference with GPT-3.

## Size of Training Set for Retrieval

We further examine how the size of the training set may influence the KATE method. On the NQ dataset, we create new subsets from the original training set, with sizes of 1k, 2k, 5k, 10k, 30k, and 70k, respectively. In-context examples are retrieved from these subsets instead of the original training set. The number of nearest neighbors is set to 64. We compare ```latex $\text{KATE}_{\text{nli+sts-b}}$ ``` with the random selection method and ```latex $\text{KATE}_{\text{roberta}}$ ```, and the results are shown in the right plot of Figure 3. For ```latex $\text{KATE}_{\text{roberta}}$ ``` and ```latex $\text{KATE}_{\text{nli+sts-b}}$ ```, as the size of the training set for retrieval increases, the EM scores also increase. In contrast, the result of the random sampling baseline does not change much. Intuitively, as the training size gets larger, it is more likely for KATE to retrieve relevant in-context examples to help GPT-3 answer a question correctly. The retrieved in-context examples could provide critical detailed information to GPT-3, thus helping GPT-3 to better answer the questions.

**Table 7: Ablation study on the effect of in-context example orders for GPT-3 on the NQ dataset using KATE_nli+sts-b. For the default order, the example A is to the left of example B if A is closer to the test prompt x than B in the embedding space. For the reverse order, the example A is to the right of example B.**

| Trial | 1 | 2 | 3 | Default | Reverse |
|-------|------|------|------|---------|---------|
| EM Score | 42.0 | 42.5 | 42.0 | 41.6 | 42.8 |

## Order of In-context Examples

Moreover, we explore how the order of in-context examples may affect KATE's results. Under the standard setting, the retrieved in-context examples are ordered such that ```latex $d(x_i, x) \leq d(x_j, x)$ ``` whenever i < j. Here, we randomly permute the order of in-context examples in the NQ dataset for the proposed ```latex $\text{KATE}_{\text{nli+sts-b}}$ ``` method, and conduct the experiments for 3 different orders. Additionally, we explore the reverse order where ```latex $d(x_i, x) \leq d(x_j, x)$ ``` whenever i < j. The results are presented in Table 7. On this particular NQ dataset, the reverse order performs the best. One possible explanation is that since tokens next to each other have similar positional embeddings, putting the most similar sentences close to the test example may be helpful for GPT-3 to leverage the corresponding information. However, we also did the experiments on the WQ and TriviaQA and find that the default order performs slightly better than the reverse order. Hence, the choice of orders is data-dependent. Additionally, it can be observed that the variation among the NQ results tends to be quite small (compared with the difference between the random baseline and KATE), indicating that the example order does not have a significant impact on KATE's performance.

# Related Work

### Pre-trained Language Models

NLP systems have made tremendous progress by pre-training models on unlabeled text. For text classification tasks, notable models include BERT [devlin2018bert], RoBERTa [liu2019roberta], and XLNet [yang2019xlnet]. For text generation tasks, notable models include BART [lewis2019bart], T5 [raffel2019exploring], mT5 [xue2020mt5], XLM [lample2019cross], GPT [radford2018improving], and GPT-2 [radford2019language]. These models encapsulate rich information to facilitate a wide range of downstream tasks ranging from natural language understanding to generation. These models can be adapted to many different tasks via fine-tuning. GPT-3 [brown2020language], however, can be adapted to many downstream tasks without fine-tuning. Given just a few in-context examples, GPT-3 is able to quickly pick up patterns and produce answers analogously both in terms of the answer style and content. Thus, GPT-3 may be considered as a pattern recognizer to perform in-context learning. People have just started trying to understand GPT-3 from different perspectives. As mentioned in the introduction, [hendrycks2020measuring] studies which categories of questions GPT-3 is more capable of answering. Our work focuses on how to choose good in-context examples.

### Retrieval-based Text Generation

There is a long history of applying information retrieval in text generation [sumita1991experiments]. It is very related to the exemplar-based learning [jakel2008generalization; ziyadi2020example]. The central idea is to treat retrieved samples as exemplars/prototypes and perform some editings on them. Some representative applications in the field of deep learning include machine translation [gu2018search], sentiment transfer [li2018delete; guu2018generating], QA [karpukhin2020dense; mao2020generation], dialogue generation [yan2016learning; cai2018skeleton; song2016two; pandey2018exemplar; weston2018retrieve; wu2019response], text summarization [cao2017faithful; peng2019text], data-to-text generation [peng2019text], and text-to-code generation [hashimoto2018retrieve]. However, all these retrieve-and-edit frameworks require their decoders to be trained from scratch. This makes the editor network task- and data-specific. In contrast, GPT-3 in one perspective can be regarded naturally as a universal editor, adaptive to a wide range of tasks. Our work uniquely examines how to maximize the advantage of using GPT-3 without fine-tuning. For example, the more semantically similar context we provide to GPT-3, the better results the model can generate. Other editors or generators do not have this ability.

### Improve NLP Systems with kNN

A recent line of work tries to incorporate nonparametric methods to improve a given model's performance. These methods first access the test sample's hidden representation and look for the nearest neighbors of this test sample in the database. Once the nearest neighbors are found, their labels are used to augment the model's prediction. For example, the newly introduced kNN-LM [khandelwal2019generalization], kNN-MT [khandelwal2020nearest], and BERT-kNN [kassner2020bert] generate the next token by retrieving the nearest k neighbors from the datastore. Another related work is kNN classification model [rajani2020explaining], where they use kNN as backoff when the confidence is low from the fine-tuned classification model. There are two key differences between our work and other approaches. First, other approaches modifies the model's next token distribution using the nearest k neighbors. However, we only changes the conditional text using the nearest k neighbors. Second, other approaches can access the model's parameters and embeddings which we do not have access to. Instead, we use some other independently pre-trained models to get the sentence embeddings to retrieve nearest k neighbors.

# Conclusion

This work presented a first step towards investigating the sensitivity of GPT-3 to in-context examples. To this end, we proposed KATE, a non-parametric selection approach that retrieves in-context examples according to their semantic similarity to the test samples. On several natural language understanding and generation tasks, the proposed method improves GPT-3's performance, over the random sampling baseline, by a significant margin. Moreover, we found that fine-tuning the sentence embeddings for retrieval on task-related datasets gave rise to further empirical gains. Detailed ablation studies were conducted to explore the robustness of KATE to different hyperparameters, such as the number of in-context examples, examples' order, *etc*. We hope this work could provide insights for better understanding the behaviors of GPT-3 and represents a helpful step towards further improving its few-shot capabilities.
