# Unified Demonstration Retriever for In-Context Learning

## Abstract

In-context learning is a new learning paradigm where a language model conditions on a few input-output pairs (demonstrations) and a test input, and directly outputs the prediction. It has been shown highly dependent on the provided demonstrations and thus promotes the research of demonstration retrieval: given a test input, relevant examples are retrieved from the training set to serve as informative demonstrations for in-context learning. While previous works focus on training task-specific retrievers for several tasks separately, these methods are often hard to transfer and scale on various tasks, and separately trained retrievers incur a lot of parameter storage and deployment cost. In this paper, we propose **Unified Demonstration Retriever (UDR)**, a single model to retrieve demonstrations for a wide range of tasks. To train UDR, we cast various tasks' training signals into a unified list-wise ranking formulation by language model's feedback. Then we propose a multi-task list-wise ranking training framework, with an iterative mining strategy to find high-quality candidates, which can help UDR fully incorporate various tasks' signals. Experiments on 30+ tasks across 13 task families and multiple data domains show that UDR significantly outperforms baselines. Further analyses show the effectiveness of each proposed component and UDR's strong ability in various scenarios including different LMs (1.3B ~ 175B), unseen datasets, varying demonstration quantities, etc.

## Introduction

Large language models have shown an impressive _in-context learning_ ability for various Natural Language Processing (NLP) tasks [gpt3; icl_survey]. In-context learning (ICL) is a recent learning paradigm where a language model (LM) learns a task by observing a few input-output pairs (demonstrations) and directly output the prediction of the given test input. Thus ICL can unify a wide range of NLP tasks through one language model's inference without parameter updates, which makes it a promising alternative to supervised fine-tuning [bert].

However, it has been shown that ICL's performance highly depends on the provided demonstrations [what_is_good_example_for_gpt3; active_select_for_icl; supporting_examples]. This promotes the research of demonstration retrieval for in-context learning [what_is_good_example_for_gpt3; epr; cross_lingual_icl_for_text_sql]: As shown in Figure 1, given a test input, relevant examples are retrieved from an annotated training set, to serve as informative demonstrations for ICL.

[IMAGE: Demonstration retrieval: Given a test input x_test, relevant demonstrations are retrieved from the training set. Then the inference LM takes demonstrations and x_test as input and generates the output.]

There are about two lines of methods to retrieve demonstrations. One is to leverage off-the-shelf retrievers, e.g., BM25 [bm25] or Sentence-BERT [sentence_bert]. They can retrieve demonstrations that are textually or semantically similar to the test input and achieve empirical improvements. Thanks to their versatility, they can serve for extensive NLP tasks, but they are heuristic and sub-optimal since they are not guided by task supervision. Another line is to train a task-specific retriever by a specially designed task signal. [cbr] train the retriever for knowledge-based question answering, based on the logic form's surface similarity. [ic_dst] explore ICL on dialogue state tracking and design the similarity between dialogue's states as the retriever's training signal. [epr] and [cross_lingual_icl_for_text_sql] leverage the LM's feedback to train demonstration retrievers for semantic parsing in English and cross-lingual scenarios, respectively. These task-specialized retrievers show better performance than the former, but they still face two challenges: 1. these explorations are limited to a small range of tasks and demonstrated separately on each task, e.g., semantic parsing or dialogue state tracking, which restricts systematic and compatible research on demonstration retrieval for ICL while ICL is a unified framework for extensive tasks. 2. it is costly for these methods to transfer and scale on various tasks and the reason is two-fold: (i) they need to design a specialized training signal for each task. (ii) the number of retrievers will scale up with increasing tasks, which results in massive parameter storage and deployment costs.

To address these limitations, we explore learning various tasks' demonstration retrieval in a unified formulation and propose **Unified Demonstration Retriever (UDR)**, a single multi-task model for demonstration retrieval of a wide range of tasks. To train UDR, we cast various tasks' training signals into a unified list-wise ranking formulation. For a training example from task T, we select a list of candidate examples from T's training set and rank them by LM's feedback. Then we propose a multi-task list-wise ranking training framework, with an iterative mining strategy to find high-quality candidates. Specifically, we iteratively train the retriever to rank candidates and use itself to find high-quality positive candidates and hard negatives. Compared with the representative method for demonstration retrieval, EPR [epr], which trains the retriever by the binary label from LM's feedback and selects candidates in a manually limited range, our training framework can explore the entire dataset to get high-quality candidates and help UDR fully incorporate the LM's feedback through list-wise ranking training.

Experiments on 30+ tasks across 13 task families and multiple data domains show that UDR significantly outperforms baselines and further analyses show the effectiveness of each proposed component and UDR's strong ability under various scenarios including different LMs (1.3B ~ 175B), unseen datasets, varying demonstrations quantities, etc. We release the code and model checkpoint at https://github.com/KaiLv69/UDR.

## Unified Demonstration Retriever

Provided a language model G, a training set D_train and a test case x_test, demonstration retrieval aims to retrieve x_test's relevant demonstrations from D_train to help LM G decode the target output. Previous works [cbr; epr; cross_lingual_icl_for_text_sql] propose task-specialized methods for several tasks separately, but they are hard to transfer and scale on various tasks. In this work, we focus on learning various tasks' demonstration retrieval in a unified formulation and propose UDR, a single model for demonstration retrieval of a wide range of tasks, as shown in Figure 2. We introduce its architecture, training, and inference as follows.

### Bi-encoder with Task Instruction

UDR is based on the prevailing bi-encoder architecture, dense passage retriever (DPR) [dpr], which encodes the query example and candidate examples separately and then calculates their similarity. To distinguish examples from different tasks, UDR encodes the example together with its task instruction, which is a short piece of text related to the task objective. Taking CNN/DailyMail [data_cnn_dm] as an example, its task instruction can be "Summarize the text". Given an example query x and a candidate demonstration z={x',y'} from task T_i, UDR uses the query encoder E_q and demonstration encoder E_d to encode them respectively and calculates their similarity as:

```latex
$$\operatorname{sim}(x,z) = E_{q}(I_{i} \oplus x)^\top E_{d}(I_{i} \oplus z)$$
```

where I_i is T_i's task instruction and the concatenation symbol joins them. E_q and E_d are two multi-layer Transformer [transformer] encoders with "CLS" pooling and can be initialized with pre-trained models [bert].

Thus, we can not only get task-specific features by specifying the task instruction, but also retain the uniformity and parameter efficiency of ICL.

[IMAGE: Illustration of UDR's inference for various tasks: Given a test input and its task's instruction, UDR can retrieve informative demonstrations from the corresponding datasets for ICL, where arrows and lines with various colors indicate corresponding tasks' pipelines, respectively.]

### Learning from LM Feedback

To train the demonstration retriever, previous works [cbr; epr; ic_dst] design task-specific training signals for several tasks separately, which makes their methods hard to transfer and scale on various tasks, and hinders systematic and compatible research on demonstration retrieval. For UDR's training, we propose to cast various tasks' training signals into a unified list-wise ranking formulation. Then we introduce a multi-task list-wise ranking training framework, where we iteratively let the retriever itself to mine high-quality candidates and learn to rank them in turn, across various tasks, shown in Algorithm 1. We introduce the list-wise ranking training and iterative mining strategy as follows.

#### Ranking Candidates by LM

Given a training example (x,y) and its candidates Z={z_i} for i=1 to l, we first rank these candidates as:

```latex
$$r(z_j) = rank(s(z_j)|\{s(z_i)\}_{i=1}^l)$$
$$s_{gen}(z_j) = p_G(y \mid z_j, x)$$
$$s_{cls}(z_j) = \frac{p_G(y \mid z_j, x)}{\sum_{y'\in Y}p_G(y' \mid z_j, x)}$$
```

where s(z_j)=s_gen(z_j) for generation tasks and s(z_j)=s_cls(z_j) for classification and multi-choice tasks. p_G is the LM G's conditional likelihood. Y is the label space or choices of the classification or multi-choice task, respectively. For simplicity, we omit special tokens and classification tasks' verbalizers in the equations above.

First we use G to score each candidate [epr] and calculate s(z_j) as the ground truth y's likelihood conditioned on the candidates z_j and the query input x. s(z_j) indicates the importance of z_j for G to encode x and generate the ground truth y. Then we rank Z according to {s(z_i)} for i=1 to l. The more important z_j is for x, the higher z_j's rank will be. Thus we unify various tasks' training signals into the same list-wise ranking formulation using LM's feedback, instead of designing task-specific objectives [cbr; ic_dst].

#### Loss Function

With these candidates' ranks from G's feedback, we propose to use the following loss function to inject the ranking signal into the retriever E, inspired by LambdaRank [lambdarank]:

```latex
$$\mathcal{L}_{rank} = \sum_{z_i,z_j\in Z} w * \log(1+e^{\operatorname{sim}(x,z_j) - \operatorname{sim}(x,z_i)})$$
```

where `latex $w=\operatorname{max}(0,\frac{1}{r(z_i)}-\frac{1}{r(z_j)})$ `.

For those z_i and z_j where r(z_i) < r(z_j), L_rank will draw sim(x,z_i) up and optimize the retriever towards sim(x,z_i) > sim(x,z_j). Additionally, w adjusts the weight for each pair of demonstrations and inject list-wise ranking information into L_rank. When z_i has a much higher rank than z_j, e.g, r(z_i)=1 and r(z_j)=10, w will be a high weight and strongly draw sim(x,z_i) up from sim(x,z_j). Since we optimize the retriever on demonstration pairs under different w, L_rank can help UDR fully incorporate candidates' listwise ranking signals from G's feedback for various tasks and learn to retrieve those helpful demonstrations.

To fully leverage the computation of the same batch, we also use the in-batch negative loss as:

```latex
$$\mathcal{L}_{ib} = -\log\frac{e^{\operatorname{sim}(x,z^*)}}{\sum_{z \in \mathbb{Z}}e^{\operatorname{sim}(x,z)}}$$
```

where z\* is the rank-1 candidate of x and Z is all candidates (x's or not x's) in the batch. Each batch is sampled from the same task, and to alleviate the bias towards high-resource tasks, we sample each task according to the multinomial distribution with probabilities {p(T_i)} for i=1 to T as:

```latex
$$p(\mathcal{T}_i) = \frac{q_i^{\alpha}}{\sum_{j=1}^T q_j^{\alpha}} \ \ \textrm{with} \ \ q_i=\frac{|\mathcal{D}^{\mathcal{T}_i}|}{\sum_{j=1}^T |\mathcal{D}^{\mathcal{T}_j}|}$$
```

where D^T_i is the ith task's dataset. alpha is a pre-defined hyper-parameter and we follow [DBLP:conf/nips/ConneauL19] to set alpha as 0.5.

The overall loss function of UDR is the integration of these two losses as follows:

```latex
$$\mathcal{L} = \lambda * \mathcal{L}_{rank} + (1-\lambda) * \mathcal{L}_{ib}$$
```

where lambda is a pre-defined hyper-parameter.

#### Iterative Candidate Mining

The selection of candidates can be a key factor for retriever's training [dpr; ance]. It is desirable for UDR to take the entire training set as candidates to provide abundant ranking signals. However, it is infeasible since scoring all pairs of training examples is quadratic in |D| and costly. Previous work [epr] selects those examples which have textually similar targets with x's as candidates. However, it may bias the retriever to learn among candidates with highly similar targets. Meanwhile, it can probably miss important demonstrations. For instance, if an example z contains relevant logic with the query x but has a dissimilar target with x's, the valuable z will not be selected as candidate to provide signal for the retriever. So, we propose an iterative mining strategy to select candidates by the retriever itself. Specifically, we iteratively train the retriever and use it to select candidates in turn. At each iteration, we update each training example's candidates as:

```latex
$$Z^* = \text{top-}K_{z\in \mathcal{D}} \operatorname{sim}(x,z)$$
```

where D is the task's entire training set.

Then we will use LM G to score and rank Z*. The new candidates in Z* can be divided into two categories. If a new candidate z has a low score, it means that we find a hard-negative candidate that can provide crucial negative signal for the retriever. If the score of z is high and even higher than all old candidates, it means that we find a valuable positive candidate that can help the retriever learn to find informative demonstrations. Thus, with iterative mining, we can explore the entire dataset, find high-quality candidates and improve training progressively. Before the first iteration, the retriever is untrained, so we initialize candidates based on surface similarity, inspired by [epr].

For computational efficiency, we first update candidates and score Z* at each iteration, and then randomly sample l of Z* and rank them at each training step. In summary, Algorithm 1 shows the UDR's overall training procedure.

**Algorithm 1: UDR Training**

- Input: Bi-encoder E_q and E_d, language model G, Training sets of T tasks {D^T_i} for i=1 to T
- Initialize the bi-encoder
- Initialize candidates of each training example
- Score initialized candidates by G
- For each iteration:
  - Sample a batch of examples
  - For each example, sample l examples z_1 to z_l from its candidates and rank them by G's score
  - Update the bi-encoder's parameters by L
  - Update candidates by new E_q and E_d
  - Score new candidates by G

### Inference

After training, we encode each task T_i's training set using E_d(p_i + .). At the test stage, given a task T_i's input, x_test, we use E_q(p_i + .) to compute its encoding and then use FAISS [faiss] to search over T_i's training set to find the most relevant demonstrations, ascendingly sorted by sim(x_test, .), D=(z_1,z_2,...,z_L). For generation tasks, the number of final demonstrations, L, is determined by the LM G's maximal input length C. Specifically, the sum of |z_i| for i=1 to L plus |x_test| plus |y| is at most C, where |y| is the pre-defined maximal length of the generated target. For classification and multi-choice tasks, we observe that increasing L brings negligible performance improvement and thus we set L to a small value, 8. We conduct further analysis of the number of demonstrations in section 3.3.5. Finally, we use greedy decoding to get the result of G([z_1;z_2;...;z_L;x_test]). Notice that here D is ascendingly sorted by sim(x_test, .) unless otherwise specified. Our analysis in section 3.3.4 shows that different orderings lead to similar performance. Thus we use the same ordering strategy with EPR [epr] for fair comparison.

## Experiment

### Experimental Settings

#### Dataset

We train UDR on a wide range of NLP tasks, consisting of about 40 tasks across 13 task families and multiple data domains, including: **Sentiment Classification**: SST-2, SST-5 [data_sst2_and_sst5], Amazon [data_amazon], Yelp [data_yelp_agnews_yahoo], MR [data_mr] and CR [data_Cr]; **Topic Classification**: AGNews, Yahoo [data_yelp_agnews_yahoo], TREC [data_trec] and DBPeida [data_dbpedia]; **Multi Choice**: COPA [data_copa], Cosmos QA [data_cosmos], Commonsense Validation and Explanation (ComE and ComV) [data_come_comv]; **NLI**: MNLI [data_mnli], SNLI [data_snli] and RTE [data_rte]; **Subjectivity Classification**: Subj [data_subj]; **Linguistic Acceptability**: COLA; **Semantic Parsing**: BREAK [data_break], MTOP [data_mtop] and SMCalFlow [data_SMCalFlow]; **Text Summarization**: CNN/DailyMail [data_cnn_dm], PubMed [data_pubmed] and Reddit [data_reddit]; **Commonsense Generation**: CommonGen [data_common_gen]; **Story Generation**: Roc Story and Ending Generation [data_roc]; **Code Summarization**: Go, Python, Java and PHP [data_codexglue]; **Text Simplification**: WikiAuto + Turk/ASSET [data_wiki_auto]; **Data to Text**: DART [data_dart] and E2E [data_e2e]. These tasks' input/output, statistics, split and evaluation metrics are in Appendix 7.

#### Implementation Details

We follow EPR [epr] to use GPT-Neo-2.7B [gpt_neo] as the scoring LM and the inference LM for most experiments in the paper unless otherwise specified. We also explore UDR's transferability across different inference LMs in section 3.3.2. Following EPR [epr], we initialize E_q and E_d as two separate "BERT-base-uncased" encoders [bert]. We list the overall hyper-parameters and implementation details in Appendix 8. On each task, we use one specific template for scoring and inference (see Appendix 7). We evaluate UDR's performance when inference templates are different with the scoring template in Appendix 9, and the results show that UDR has stable performance across varying inference templates, which reflects UDR's generality.

#### Model Comparison

With the same inference LM, GPT-Neo-2.7B, we compare UDR with previous methods for demonstration retrieval by the downstream ICL performance, including: **1. Random**: We randomly sample demonstrations from the corresponding task's training set. **2. BM25** [bm25]: A prevailing sparse retriever. For each test input x_test, we use BM25 to retrieve examples with the most similar input. **3. SBERT** [sentencebert]: We use the Sentence-BERT as the dense demonstration retriever. Specifically, we follow [epr] to take "paraphrase-mpnet-base-v2" to encode the test input x_test and training set's inputs, and retrieve the examples with the most similar input as demonstrations. **4. Instructor** [instructor]: Instructor is a recently proposed competitive text embedding model trained on 330 tasks with instructions. By providing the specialized instruction, it can serve for demonstration retrieval. For fair comparison, we conduct experiments on its released base-size model. **5. DR-Target**: This baseline is inspired by previous works on generation tasks like dialogue state tracking, question answering and code generation [ic_dst; cbr; reliable_code_generation], which design the task-specific target's similarity and use examples with similar targets to train the retriever. Here we use BM25 as the similarity function for each task's target output. Specifically, we use BM25 to find positive pairs with similar targets and use DPR [dpr] for training. **6. EPR** [epr]: EPR is a recently proposed representative method for training demonstration retriever. It uses the language model to assign candidate examples with positive and negative labels and thus trains a task-specific demonstration retriever by DPR. For fair comparison, we train EPR on each task using the same hyper-parameters of UDR. Specially, we discuss EPR's candidate quantity in Appendix 8.

Except that the performance of Random, BM25, SBERT and EPR on semantic parsing is from the previous paper [epr], other results are from our implementation since they are not explored previously.

### Main Results

We show the performance comparison of classification tasks and generation tasks in Tables 1 and 2, respectively.

**Table 1: Classification Tasks Results**

| Method     | SST-2    | SST-5    | Amazon   | Yelp     | MR       | CR       | AGNews   | TREC     | DBPedia  | Yahoo    |
| ---------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| Random     | 57.7     | 28.2     | 23.9     | 25.3     | 56.0     | 52.4     | 74.2     | 42.6     | 73.7     | 39.1     |
| BM25       | 74.1     | 38.3     | 31.6     | 36.9     | 71.4     | 57.2     | 88.4     | 89.4     | 97.2     | 62.5     |
| SBERT      | 84.3     | 40.0     | 33.4     | 36.0     | 79.0     | 61.3     | 88.3     | 89.4     | 96.7     | 58.4     |
| Instructor | 83.7     | 42.4     | 42.4     | 46.6     | 78.5     | 64.1     | 89.6     | 91.2     | 97.7     | 67.2     |
| EPR        | 87.9     | 46.9     | 49.1     | 49.6     | 80.6     | 65.7     | 89.9     | 95.2     | 98.1     | 66.1     |
| UDR        | **92.4** | **50.5** | **54.9** | **61.7** | **85.2** | **82.6** | **91.5** | **96.6** | **98.7** | **67.5** |

| Method     | COPA     | Cosmos QA | ComE     | ComV     | MNLI     | SNLI     | RTE      | Subj     | COLA     | Avg      |
| ---------- | -------- | --------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| Random     | 71.6     | 26.2      | 41.4     | 50.5     | 34.1     | 33.0     | 55.6     | 60.0     | 52.8     | 47.3     |
| BM25       | 71.2     | 27.1      | 41.4     | 50.9     | 35.3     | 41.5     | 50.5     | 78.8     | 53.3     | 57.7     |
| SBERT      | 72.4     | 27.3      | 41.1     | 50.3     | 38.0     | 42.0     | 49.8     | 88.7     | 56.3     | 61.6     |
| Instructor | 71.6     | 27.1      | 41.9     | 49.9     | 41.3     | 46.7     | 52.7     | 84.3     | 56.0     | 63.2     |
| EPR        | **73.2** | 28.4      | 43.0     | 50.4     | 54.3     | 74.0     | 55.6     | 92.1     | 70.3     | 68.8     |
| UDR        | 72.8     | **29.9**  | **45.6** | **63.9** | **73.8** | **83.6** | **65.3** | **95.0** | **78.9** | **73.2** |

**Table 2: Generation Tasks Results**

| Method     | BREAK    | MTOP     | SMCalFlow | CNN/DM   | PubMed   | Reddit   | CommonGen | Roc Story | Roc Ending |
| ---------- | -------- | -------- | --------- | -------- | -------- | -------- | --------- | --------- | ---------- |
| Random     | 1.9      | 6.6      | 8.7       | 20.8     | 23.6     | 15.6     | 21.1      | 9.3       | 13.4       |
| BM25       | 26.0     | 52.9     | 46.1      | 18.6     | 24.5     | 15.3     | 26.0      | 12.3      | 19.2       |
| SBERT      | 22.4     | 48.6     | 43.1      | 19.2     | 25.2     | 15.4     | 25.7      | 12.2      | 19.1       |
| Instructor | 22.7     | 50.5     | 46.3      | 19.0     | 24.8     | 15.3     | 26.5      | 12.4      | 21.8       |
| DR-Target  | 22.1     | 49.6     | 41.6      | 19.4     | 24.6     | 16.0     | 24.5      | 11.9      | 20.1       |
| EPR        | 31.9     | 64.4     | 54.3      | 20.3     | 24.8     | 15.5     | 25.3      | 12.9      | 21.2       |
| UDR        | **35.2** | **66.8** | **60.4**  | **21.2** | **26.1** | **16.2** | **27.1**  | **17.6**  | **24.7**   |

| Method     | Go       | Python   | Java     | PHP      | WikiAuto | Turk     | ASSET    | DART     | E2E      | Avg      |
| ---------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| Random     | 27.3     | 7.9      | 6.7      | 18.9     | 8.3      | 28.0     | 24.8     | 20.4     | 21.9     | 15.8     |
| BM25       | 30.4     | 9.7      | 11.7     | 23.6     | 10.2     | 29.1     | 26.6     | 28.4     | 29.2     | 24.2     |
| SBERT      | 28.3     | 13.7     | 15.1     | 22.0     | 9.5      | 29.1     | 26.7     | 27.9     | 24.2     | 23.7     |
| Instructor | 29.9     | 11.5     | 13.1     | 24.0     | 11.3     | 29.0     | 26.3     | 28.7     | 22.4     | 24.2     |
| DR-Target  | 28.1     | 12.2     | 13.0     | 24.2     | 10.8     | 29.4     | 26.7     | 30.1     | 24.7     | 23.8     |
| EPR        | **30.5** | 17.4     | 17.4     | 30.2     | 13.3     | 30.8     | 27.6     | 31.8     | 29.3     | 27.7     |
| UDR        | 29.4     | **22.3** | **25.2** | **33.2** | **19.5** | **32.9** | **32.1** | **34.5** | **32.6** | **30.9** |

We can see that UDR outperforms baselines significantly on most tasks, which shows UDR's best overall demonstration retrieval ability on a wide range of NLP tasks. Specially, compared with DR-Target and EPR, UDR has better overall performance and this shows the effectiveness of our unification of various tasks' training signals. Meanwhile, compared with Instructor [instructor], the text embedding model trained on 330 tasks' text pairs, UDR has an improvement of 10 and 6.7 points for classification and generation tasks respectively with less training data. This straightly demonstrates that our proposed training framework can help UDR incorporate LM's feedback through a unified ranking formulation and better retrieve informative demonstrations.

Additionally, we find the random baseline shows the worst performance on most tasks and this reflects the necessity to retrieve high-quality relevant demonstrations. Meanwhile, EPR and UDR have better performance than other methods, which reflects the importance of LM's feedback. Among these datasets, we notice a different trend on text summarization datasets like CNN/DailyMail and Reddit, on which these methods have similar performance. We conjecture that the LM can already have the knowledge of summarization since there are a lot of "[Article, TL;DR, Abstract]" texts in its pre-training corpus [gpt2], thus random demonstrations can well activate LM's summarization ability without example-specific information.

### Analysis

#### Ablation Study

To evaluate the effect of UDR's each component, we conduct ablation study on SMCalFlow, SST-2 and Java code summarization, shown in Table 3.

**Table 3: Ablation study of UDR's each component**

|                   | SMCalFlow | SST-2 | Java | Avg  |
| ----------------- | --------- | ----- | ---- | ---- |
| UDR               | 60.8      | 91.3  | 23.2 | 58.4 |
| - w/o Task Prompt | 60.1      | 90.8  | 21.9 | 57.6 |
| - w/o MultiTask   | 60.9      | 91    | 22.9 | 58.3 |
| - w/o Rank Loss   | 56.7      | 89.2  | 21.1 | 55.7 |
| - w/o Self-Guided | 59.5      | 90.2  | 19.7 | 56.5 |

When removing list-wise ranking training, we use EPR's training strategy [epr]. We can see that removing task instructions cause slight performance degradation, which indicates that they can help UDR distinguish examples from various tasks and thus get better task-specific features. Meanwhile, we can see that UDR has a slightly better performance than the single-task counterpart on SST-2 and Java. We suppose that is because there are several relevant tasks in UDR's training tasks and our multi-task ranking unification can help UDR fully share these tasks' knowledge. The performance of single-task UDR still outperforms EPR significantly and this straightly reflects that our training components, i.e., list-wise ranking formulation and iterative candidate mining strategy, can 1. help UDR better incorporate LM's feedback than EPR 2. serve as a competitive universal training method for a task-specific retriever. Removing list-wise ranking training and iterative candidate mining both cause performance degradation, which straightly indicates their effectiveness.

#### Transferability across Different LMs

In this section, we evaluate UDR's transferability across different inference LMs on SMCalFlow and E2E. Specifically, we compare BM25, EPR and UDR on inference LMs with different sizes, including: GPT-Neo-1.3B [gpt_neo], GPT-J (6B) [gpt_j], Code-Davinci-002 (175B) [codex] and Text-Davinci-003 (175B) [gpt3; instruct_gpt] and we show the result in Table 4.

**Table 4: Results on 1000 randomly sampled test examples across different inference LMs**

| Dataset          | SMCalFlow |      |      | E2E  |      |      |
| ---------------- | --------- | ---- | ---- | ---- | ---- | ---- |
| LMs / Methods    | BM25      | EPR  | UDR  | BM25 | EPR  | UDR  |
| Text-Davinci-003 | 55.0      | 58.9 | 64.7 | 31.3 | 31.5 | 34.3 |
| Code-Davinci-002 | 50.9      | 55.2 | 62.9 | 23.5 | 24.4 | 26.4 |
| GPT-J            | 49.0      | 55.9 | 64.0 | 33.3 | 33.7 | 35.0 |
| GPT-Neo-1.3B     | 44.8      | 52.9 | 59.5 | 29.9 | 29.7 | 31.9 |
| GPT-Neo-2.7B     | 46.5      | 53.7 | 62.2 | 29.2 | 29.1 | 32.6 |

When comparing UDR with baselines, the trends are similar with using GPT-Neo-2.7B (the scoring LM) as inference LM. UDR outperforms BM25 and EPR significantly and it shows UDR's strong transferability across different inference LMs. Meanwhile, we find that UDR with larger inference LM can improve performance such as Text-Davinci-003 on SMCalFlow and GPT-J on E2E, which shows UDR's potential utility in the future where more competitive large-scale LM is built. When we demonstrate the example-specific demonstration transferability across different inference LMs in this paper, [supporting_examples] show that task-level demonstrations also exhibit such transferability. We leave the analysis of the transferablity of ICL's demonstrations across different LMs as future work.

#### Performance on Unseen Datasets

In this section we explore UDR's zero-shot transferability and evaluate it on unseen datasets including: 1. Twitter sentiment classification [data_twitter_sentiment] 2. question-answering NLI (QNLI) [data_glue] 3. Ruby and JavaScript code summarization [data_codexglue]. These domains or programming languages (Twitter, NLI on QA, Ruby and Javascript) are never seen during UDR's training and thus can straightly reflect UDR's zero-shot transferability. We compare UDR with two powerful universal retrievers, BM25 and SBERT, and show the result in Table 5.

**Table 5: The performance of UDR on unseen datasets**

|       | Twitter | QNLI | Ruby | JavaScript |
| ----- | ------- | ---- | ---- | ---------- |
| BM25  | 50.0    | 54.1 | 9.2  | 12.7       |
| SBERT | 51.6    | 53.7 | 8.7  | 15.9       |
| UDR   | 56.8    | 74.4 | 19.6 | 21.6       |

We can see UDR significantly outperforms BM25 and SBERT on these unseen datasets by about 10 points on average, which shows that the learned ranking knowledge inside UDR can be well transferred and generalized to unseen datasets.

#### The Order of Demonstrations

Previous work [icl_ordering] has revealed that ICL is sensitive to demonstrations' order when using random examples. Specifically, the same randomly sampled demonstrations with different orders can lead to the performance between random guess and near state-of-the-art. Here we explore the effect of ordering on example-specific demonstrations retrieved by UDR. We compare 3 demonstrations' orders: 1. random, for this setting, we run experiments with 10 different random seeds and report the best and worst performance. 2. descending sorted by UDR's score, i.e, the demonstration which has the highest similarity with x_test is put at the beginning of LM's input. 3. ascending sorted by UDR's score, opposite to "2". The result is shown in Table 6.

**Table 6: The effect of different demonstration orders**

|                      | SST-2 | TREC | Reddit | CommonGen |
| -------------------- | ----- | ---- | ------ | --------- |
| Random-Order (Best)  | 92.5  | 96.6 | 16.8   | 27.5      |
| Random-Order (Worst) | 92.0  | 96.2 | 16.2   | 26.6      |
| Descending-Order     | 92.2  | 96.6 | 16.2   | 27.0      |
| Ascending-Order      | 92.4  | 96.6 | 16.3   | 27.3      |

We observe a different phenomenon from that in previous work [icl_ordering]. In general, The performance of UDR's demonstrations with different orders is more stable than previously investigated random examples. Across these tasks, different orders' performance gap is within 1 point, and it is far less than the performance fluctuation of up to tens points when using random examples [icl_ordering]. This indicates that high-quality demonstrations are less sensitive to the ordering and stabilize in-context learning, which is consistent with the analysis in previous work [sensitivity_and_accuracy; supporting_examples].

#### The Impact of Demonstration Quantity

We compare UDR with BM25 and EPR under different amounts of demonstrations on two classification tasks: Yelp and RTE, and two generation tasks: WikiAuto and Java code summarization. We show results in Figure 3.

[IMAGE: The effect of demonstration quantity.]

We can see that UDR outperforms baselines consistently across varying amounts of demonstrations. Meanwhile, we can draw two conclusions from the results: 1. The number of demonstrations has a greater impact on generation tasks than classification tasks. Specifically, as the number of demonstrations increases, generation tasks' performance gets significant improvements while classification tasks' has slight or no improvements. 2. The quality of demonstrations can be more important than their quantity. In detail, UDR with the quota of 2 demonstrations still outperforms BM25 and EPR with 8 demonstrations. This also reflects the strong demonstration retrieval ability of UDR. [mot] observe the similar trends in the CoT-retrieval scenario, indicating that the relevance of the used reasoning paths is more important than their quantity.

## Related Work

In this section, we introduce previous demonstration retrievers for in-context learning, and explain the difference between UDR and them. In general, there are two kinds of demonstration retrievers for ICL. One is to leverage off-the-shelf retrievers. For example, [what_is_good_example_for_gpt3] propose to use a fine-tuned BERT to encode examples and use a KNN-based method to retrieve semantically similar demonstrations to improve ICL. [icl_mt] use BM25 to retrieve demonstrations for machine translation. Compared with them, UDR incorporates various tasks' supervision by unified LM's feedback and thus can better retrieve informative demonstrations. Another approach is to train a task-specific retriever by a designed task-specific signal. [cbr] explore demonstration retrieval for knowledge-based question answering and define the F1 score of logic forms as soft-label to train the retriever. [reliable_code_generation] train a demonstration retriever for code generation, based on the edit distance of abstract syntax trees. [ic_dst] define the similarity between dialogue states, and use it to train a demonstration retriever for dialogue state tracking. [epr] propose Efficient Prompt Retriever (EPR) for semantic parsing, which is to use the language model to score examples, assign positive and negative labels for them and use DPR [dpr] to train a demonstration retriever. [cross_lingual_icl_for_text_sql] explore demonstration retrieval for cross-lingual semantic parsing using a similar example scoring method with EPR. These task-specific methods serve for each task separately and are hard to transfer and scale on various tasks. For other tasks, it requires to redesign the similarity function or training signal. Compared with them, we introduce a unified training framework based on list-wise ranking and propose a single multi-task retriever UDR to serve for a wide range of tasks. Compared with EPR, besides UDR's versatility on various tasks, UDR can incorporate LM's feedback by ranking-based training in a more fine-grained way and receive more crucial candidates' signals by the iterative mining strategy. [sentence_embedding_by_gpt3] propose CLAIF to enhance the sentence embedder by the gigantic language model's feedback. Specifically, they use GPT-3 [gpt3] to generate the data of sentence pairs and then score them by the output of GPT-3, which depends on the strong natural language understanding ability of GPT-3. Different from them, we leverage the conditional probability to measure the helpfulness of an example, which only needs a small language model, and is more efficient and environmental-friendly. Recently, [mot] propose MoT (Memory-of-Thought) to let the LLM self-improve in two stages: 1. Before test stage, the LLM generate reasoning paths and answers on an unlabeled dataset for itself, 2. At test stage, the LLM retrieves relevant reasoning paths (memory) to help itself answer the given test question. While MoT focuses on the scenario with unlabeled dataset and uses the LLM for retrieval, we train a small retriever by a LM's feedback from tasks' supervision and thus the proposed method is more lightweight. We leave demonstration retrieval with reasoning paths or unlabeled datasets as future work.

## Conclusion

In this paper, we propose UDR, a single multi-task model for a wide range of tasks' demonstration retrieval. To train UDR, we cast various tasks' training into a unified list-wise ranking formulation by language model's feedback, and propose a multi-task list-wise ranking training framework, with an iterative mining strategy to find high-quality candidates. Experiments on 30+ tasks show that UDR significantly outperforms baselines. Further analyses show the effectiveness of each proposed component and UDR's strong ability in various scenarios including different LMs (1.3B ~ 175B), unseen datasets, varying demonstration quantities, etc.

## Limitations

We illustrate this paper's limitations from the following three aspects:

1. Limited by the computational resources, we only train UDR from the initialization of "BERT base uncased" following EPR [epr]. We regard explorations based on other competitive pre-trained models like RoBERTa [roberta] and DeBERTa [deberta] as future work.

2. Most of current dense demonstration retrievers, including UDR, are black-box models. Although they lead to significantly better performance than BM25, how they find informative demonstrations is still unknown. Therefore, a better understanding of the principle of informative demonstration's retrieval or an interpretable and transparent demonstration retriever may be the next stage of improving demonstration retrieval. [knn_prompting] propose a more explainable method, beyond-context learning, which first uses the language model to get training data's next word probability distribution, then assigns test instances with labels of their nearest neighbors with similar next word's probability distribution. We leave demonstration retrieval with better explainability as future work.

3. In the training stage we use LM to score candidates separately but in the inference stage LM is provided with a sequence of demonstrations. Although experimental results demonstrate UDR's effectiveness, we think it is a promising direction to model the dependence between different demonstrations and leave it to future work.

## Appendix A: Task Overview

The tasks used in UDR training span 13 task families:

**Task Family Overview**

| Task Family               | Task             | Input                            | Output                 |
| ------------------------- | ---------------- | -------------------------------- | ---------------------- |
| Sentiment Classification  | SST-2            | Short Movie Review               | Sentiment Label        |
|                           | SST-5            | Short Movie Review               | Sentiment Label        |
|                           | Amazon           | Amazon Product Review            | Sentiment Label        |
|                           | Yelp             | Yelp Review                      | Sentiment Label        |
|                           | MR               | Movie Review                     | Sentiment Label        |
|                           | CR               | Electronics Review               | Sentiment Label        |
| Topic Classification      | AGNews           | News Article                     | Topic Label            |
|                           | TREC             | Question                         | Topic Label            |
|                           | DBPedia          | Wikipedia Text                   | Topic Label            |
|                           | Yahoo            | Question-answer Pair             | Topic Label            |
| Multi-Choice              | COPA             | Causal Reasoning Question        | Effect/Cause           |
|                           | Cosmos QA        | Causal Reasoning Question        | Effect/Cause           |
|                           | ComV             | Commonsense Hypotheses           | Wrong Hypothesis       |
|                           | ComE             | Wrong Hypothesis                 | Explanation            |
| NLI                       | MNLI             | Image-caption Sentence Pair      | Entailment Label       |
|                           | SNLI             | Cross-genre Sentence Pair        | Entailment Label       |
|                           | RTE              | Wikipedia/News Sentence Pair     | Entailment Label       |
| Subjective Classification | Subj             | Movie Review                     | Subjectivity           |
| Linguistic Acceptability  | COLA             | Linguistics Publication Sentence | Grammatical Label      |
| Semantic Parsing          | BREAK            | Question                         | Question Decomposition |
|                           | MTOP             | User Utterance                   | TOP Representation     |
|                           | SMCalFlow        | User Utterance                   | Dataflow Program       |
| Text Summarization        | CNN/DailyMail    | News Article                     | Highlights             |
|                           | PubMed           | Scientific Paper's Introduction  | Abstract               |
|                           | Reddit           | Reddit Post                      | Summary                |
| Commonsense Generation    | CommonGen        | Concepts                         | Coherent Sentence      |
| Story Generation          | Roc Story        | Head of Story                    | Remaining Story        |
|                           | Roc Story Ending | Four-sentence Story              | Story Ending           |
| Code Summarization        | Go               | Go Code                          | Documentation          |
|                           | Python           | Python Code                      | Documentation          |
|                           | Java             | Java Code                        | Documentation          |
|                           | PHP              | PHP Code                         | Documentation          |
| Text Simplification       | WikiAuto         | Wikipedia Sentence               | Simplified Sentence    |
|                           | WikiAuto-Turk    | Wikipedia Sentence               | Simplified Sentence    |
|                           | WikiAuto-ASSET   | Wikipedia Sentence               | Simplified Sentence    |
| Data to Text              | DART             | Triple Set                       | Text                   |
|                           | E2E              | Key-value Pairs                  | Text                   |

## Appendix B: Implementation Details and Hyper-Parameters

We follow [epr] to use GPT-Neo-2.7B [gpt_neo] as the scoring LM and the inference LM for most experiments in the paper unless otherwise specified. Following EPR [epr] and DPR [dpr], we initialize E_q and E_d as two separate "BERT base uncased" encoders [bert]. Thus the total number of parameters of UDR is about 220M. We use 8 NVIDIA A100s-80GB to train UDR for up to 30 epochs before iteratively mining candidates. And then we train UDR for 10 epochs at each iteration. The whole training pipeline including scoring candidates takes about 8 days. In the pilot experiment, we select the number of training epochs through the average performance on validation set on single-task SST-2, TREC, MTOP, Java code summarization, WikiAuto and DART. We set the number of iterations as 3. We follow EPR [epr] to set learning rate and batch size as 1e-4 and 128 and we use AdamW [adamw] as the optimizer.

**Hyper-parameters**

| Parameter                   | Value |
| --------------------------- | ----- |
| Optimizer                   | AdamW |
| Warmup Steps                | 500   |
| Learning Rate               | 1e-4  |
| Batch Size                  | 128   |
| Loss Weight (lambda)        | 0.8   |
| Iteration Number            | 3     |
| Scoring Candidates Num (K)  | 50    |
| Training Candidates Num (l) | 8     |

On each task, we use one specific template for scoring and inference. For fair comparison, we train DR-Target, EPR and UDR under the same hyper-parameter and report their average performance under three random seeds.

**The initialization of UDR's candidates**: For classification and multi-choice tasks, we initialize candidates as those examples that have similar input with x by BM25. For generation tasks, similarly, we initialize candidates as those of similar targets with x's, inspired by previous work [epr].

**The Quantity of EPR's Candidates**: Since UDR's training needs to score iteratively mined candidates and thus has to score more candidates than EPR, we also run experiments on EPR with the same candidate quantities of UDR. But we find increasing the candidates of EPR instead slightly hurts its overall performance, which is consistent with its original paper [epr]. Thus for EPR, we use the same number of candidates as its original paper.

## Appendix C: Performance across varying inference templates

For UDR, we use one specific template when scoring candidates and here we evaluate UDR's transferability across different inference templates on MR, Yahoo and Subj.

**Table: UDR's performance under different inference templates**

| Template          | MR   | Yahoo | Subj |
| ----------------- | ---- | ----- | ---- |
| Original Template | 85.2 | 67.5  | 95.0 |
| Template 1        | 85.1 | 67.8  | 94.8 |
| Template 2        | 85.7 | 67.1  | 94.8 |
| Template 3        | 85.4 | 67.2  | 95.2 |

We can see that the performance gap across various inference templates is smaller than 1 point and this reflects UDR's stability and transferability across different inference templates.

## Appendix D: Potential Risk

Previous works have shown Large language models can have various kinds of bias [language_model_bias]. Since UDR is trained from the feedback of large language models, it can also contain such bias.
