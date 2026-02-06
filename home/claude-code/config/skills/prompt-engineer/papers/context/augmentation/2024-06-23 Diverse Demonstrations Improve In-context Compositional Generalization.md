# Abstract

In-context learning has shown great success in i.i.d semantic parsing splits, where the training and test sets are drawn from the same distribution. In this setup, models are typically prompted with demonstrations that are _similar_ to the input utterance. However, in the setup of compositional generalization, where models are tested on outputs with structures that are absent from the training set, selecting similar demonstrations is insufficient, as often no example will be similar enough to the input. In this work, we propose a method to select _diverse_ demonstrations that aims to collectively _cover_ all of the structures required in the output program, in order to encourage the model to generalize to new structures from these demonstrations. We empirically show that combining diverse demonstrations with in-context learning substantially improves performance across three compositional generalization semantic parsing datasets in the pure in-context learning setup and when combined with finetuning.

Code: https://github.com/itayle/diverse-demonstrations

# Introduction

Despite strong performance of pretrained language models (LMs) across many tasks, they have been shown to struggle in a compositional generalization setting [pmlr-v80-lake18a; Furrer2020CompositionalGI; shaw-etal-2021-compositional], when tested on their ability to process and generate novel combinations of previously observed elements. For example, a model might fail to interpret the request _"Book a meeting with Jake's supervisor"_ even when _"Book a meeting with Jake"_ and _"Who is Jake's supervisor?"_ were observed during training. In semantic parsing, the task of mapping natural language utterances to formal queries, such generalization is important (especially in a real-world setting), since models are required to interpret new combinations that are not covered by the annotated training data [herzig-berant-2019-dont; yin-etal-2021-compositional].

[IMAGE: Figure 1 - Compositional generalization setup: (a) Selecting demonstrations by considering only similarity to the input yields repetitive demonstrations that do not cover the structures in the target program. (b) However, choosing diverse demonstrations enables better coverage and leads to a correct prediction.]

[IMAGE: Figure 2 - Overview of our framework. Given an utterance, we construct a prompt by selecting a set of diverse demonstrations. Feeding the prompt to the model yields the predicted target. Optionally, models can be finetuned (FT setup). In the bottom left corner, we see how Cover-LS selects diverse examples: predicting and covering local structures, thereby enabling the selection of complementary examples.]

Recently, large LMs have shown impressive performance on downstream tasks by conditioning on a text-based prompt that contains a few training examples. This type of few-shot inference is known as _in-context learning_ (ICL, [Brown2020LanguageMA]). A core component of in-context learning is the set of examples in the prompt, often termed task _demonstrations_. With the right demonstrations, ICL can be an effective approach to improving LMs' compositional generalization abilities [qiu-etal-2022-evaluating].

Selecting a relevant set of demonstrations is crucial for generalization. However, most past work only considered the relevance of each example _in isolation_, ignoring the quality of the entire set of examples [liu-etal-2022-makes]. For instance, a retriever can be used to select the examples most similar to the input [rubin-etal-2022-learning]. A set of demonstrations that are all highly relevant but highly similar to one another may not be as effective as a more **_diverse_** set. In compositional splits, where no single demonstration is sufficiently similar to the input, choosing diverse demonstrations can be especially beneficial since it leads to better coverage of structures in the target program.

In this paper, we study how to leverage ICL to improve compositional generalization for semantic parsing, by optimizing the entire set of demonstrations and increasing the diversity of examples in this set. We investigate two approaches for increasing diversity: (a) a _coverage-based_ approach, where we define a set of elements conditioned on the input utterance, and select examples that cover those elements (e.g., covering potential sub-structures in the output program), and (b) a second approach, where we select a subset of examples that are most dissimilar from one another, such that diversity is independent of the input utterance. Empirically, we find that coverage-based diversity results in better performance.

Our method can be used in the "pure" in-context learning setup without finetuning, which leverages the ability of large LMs, such as Codex [Chen2021EvaluatingLL], to generalize from the selected diverse demonstrations. Furthermore, it can be combined with finetuning by training a model with demonstrations as part of the input. This can be viewed as meta-learning, where the model learns to use demonstrations during training and build new structures based on them during inference [Finn2017ModelAgnosticMF; Lake2019CompositionalGT; conklin-etal-2021-meta; min-etal-2022-metaicl; chen-etal-2022-meta]. It can, however, lead to an over-reliance on demonstrations, especially in compositional splits. We address this by using "noisy" demonstrations during training.

We empirically test our method on three compositional generalization semantic parsing datasets. We show that diverse demonstrations, both with and without finetuning, improve performance by up to 23 absolute points (e.g., 50.3 -> 73.5 on SMCalFlow-CS) compared to a baseline that retrieves demonstrations according to similarity alone, and lead to state-of-the-art results in multiple compositional setups. Finally, we show that our method reduces the number of demonstrations needed for generalization and improves test performance on hard examples.

# Diversity for Compositional Generalization

In semantic parsing, we define compositional splits of datasets as splits where train and test programs do not overlap [finegan-dollak-etal-2018-improving]. Recent work has shown that increasing the number of different program structures a model sees during training improves performance on compositional splits. This can be done by augmenting the training set [qiu-etal-2022-improving] or through efficient sampling of diverse examples [oren-etal-2021-finding; bogin-etal-2022-unobserved; gupta-etal-2022-structurally]. While past work focused on increasing structure diversity in the _training set_, we focus on diversity in the _demonstration set_ within an ICL setup.

Increasing diversity is important as we want the demonstrations to _cover_ all structures of the expected output program. In the few-shot setting, where the model is unfamiliar with the formal language of the output programs, increasing coverage also improves generalization simply since otherwise the model will be unaware of the required program symbols (predicates and logical operators). However, selecting demonstrations that cover larger _structures_ (sub-trees of the program tree) are potentially more beneficial, for two reasons: (1) it reduces the amount of new structures that the model needs to produce, making demonstration fusion easier, and (2) it exposes the model to structure compositions in different contexts, providing the model with valuable information about how structures can be composed in the data.

# Diverse Demonstrations Selection

### Problem setup

Given a training set `latex $\mathcal{T}=\{(x_i,y_i)\}_{i=1}^n$ ` containing utterance-program pairs and a test utterance `latex $x_{\small\text{test}}$ `, our objective is to select a subset of training examples `latex $\mathcal{D}=\{(x_j,y_j)\}_{j=1}^k\subset\mathcal{T}$ `, where `latex $k \ll n$ `, termed demonstrations. Those demonstrations are then formatted as a text-based prompt P. When feeding the concatenation of the prompt and the test utterance `latex $([P;x_{\small\text{test}}])$ ` to the model, the desired output is `latex $y_{\small\text{test}}$ `.

### Overview

Figure 2 provides an overview of our framework for obtaining and leveraging diverse demonstrations for better compositional generalization. Given an input utterance, `latex $x_{\small\text{test}}$ `, we propose two approaches for selecting demonstrations. In the first (Section 3.1), we optimize _coverage_: we define a set of elements that we want our demonstrations to cover (either structures in the program or utterance words), and then iteratively select examples that contain these elements. The second approach (Section 3.2) increases diversity by selecting a subset of examples with minimal similarity. Figure 2 shows an example of the former approach (_Cover-LS_), where we predict and then attempt to cover _local structures_ (LS), i.e., sub-trees of the output program. Local structures were shown to be key for compositional generalization.

Having selected demonstrations, we use them to construct a prompt (Section 3.3). We show that our method can be combined with finetuning to meta-train the model to learn in-context (Section 3.4).

## Coverage-based Selection

Recent work has shown, in the context of finetuning semantic parsers, that models fail to generalize to programs with local structures that were not observed at training time, where local structures of a program are defined to be a set of its sub-trees. Inspired by this observation, we propose **Cover-LS**, an algorithm that given the test utterance `latex $x_{\small\text{test}}$ `, attempts to choose examples that collectively cover as many local structures as possible from the set `latex $\mathcal{S}_{{y}_{\small\text{test}}}$ ` of local structures of the program `latex $y_{\small\text{test}}$ `. Since we have no access to `latex $y_{\small\text{test}}$ ` at test time, we predict what local structures are likely using an auxiliary model, assuming that predicting local structures is _easier_ than predicting the entire program. Then, we iteratively select examples that cover the predicted local structures.

### Local structures definition

We follow the definition of prior work, and given a program y, convert it to its abstract syntax tree, where each tree node is a program symbol and parent-child edges connect functions to their arguments. In addition, we add "sibling" edges between consecutive arguments. The local structures, `latex $\mathcal{S}_{{y}_{\small\text{test}}}$ `, are a subset of all of the connected sub-graphs in the abstract syntax tree (e.g., `state`->`next_to_2` and `most`->`state`->`loc_1` in Figure 2). Unlike prior work, we consider local structures with any number of nodes. In addition, we anonymize programs by replacing values such as strings and numbers with constants (`string` and `number`), since such values are usually not relevant for program coverage.

### Predicting local structures

As mentioned, we assume predicting local structures is easier than predicting an entire program. Thus, we train an auxiliary model by finetuning T5 [Raffel2020ExploringTL] on the training set in the standard manner, training it to output anonymized programs given input utterances with no demonstrations. Then, for each test utterance, `latex $x_{\small\text{test}}$ `, we use beam search to output B candidate programs `latex $\{\tilde{y}_b\}_{b=1}^B$ ` and define the set of local structures as `latex $\mathcal{S}_{\tilde{y}_{\small\text{test}}}=\bigcup_{b=1}^B \mathcal{S}_{\tilde{y}_b}$ `.

### Covering local structures

Our goal is to choose a set of demonstrations, `latex $\mathcal{D}$ `, that covers the local structures in `latex $\mathcal{S}_{\tilde{y}_{\small\text{test}}}$ `. Choosing an example for each local structure is infeasible due to prompt length limitations, and thus we propose Algorithm 1, whose goal is to choose a small set of demonstrations that are (a) similar to the test utterance `latex $x_{\small\text{test}}$ ` and (b) cover as many local structures in `latex $\mathcal{S}_{\tilde{y}_{\small\text{test}}}$ ` as possible.

**Algorithm 1: Cover-LS**

```
Input: Training set T, test utterance x_test, retriever R,
       predicted local structures S, number of demonstrations k
Output: Set of demonstrations D

D = empty set
Sort S from largest to smallest
while |D| < k do
    S_uncovered = S
    for each s in S_uncovered do
        Retrieve with R an example e in T that contains s
        Add e to D
        Remove from S_uncovered LSs that appear in e
        Remove from T all examples with same anonymized program as e
    end for
end while
return D
```

We sort the LSs based on their size (number of nodes) in descending order. By first selecting training examples with programs that contain _larger_ LSs from `latex $\mathcal{S}_{\tilde{y}_{\small\text{test}}}$ `, we are more likely to include training examples similar to the test utterance, which should improve few-shot performance. Then, we iterate over all LSs, and for each local structure s we _retrieve_ the most similar training example that contains s, and add it to D. We then update the pool of LSs such that it will include only LSs that are not yet covered. To further encourage diversity, we remove from our example pool all examples that share the same template (program after anonymization) as the chosen examples. We keep choosing examples until reaching the desired amount of demonstrations, which might result in choosing more than one example for each local structure.

We assume access to a retriever that takes as input an utterance and returns similar training examples, from which we filter only examples that contain the desired structure. A variety of retrievers can be used, such as BM25 [Robertson2009ThePR] or SBERT [reimers-gurevych-2019-sentence].

We observe that in our setup, the running time of Cover-LS is negligible compared to the decoding time of the LMs.

### Utterance coverage

We propose a simpler variant that does not require predicting a set of local structures with an auxiliary model. This variant, termed **Cover-Utt**, uses the same coverage-oriented algorithm, but covers _words_ in the input utterance, rather than predicted local structures. This is beneficial when the quality of the auxiliary model, and consequently predicted LSs, is low.

## Diversity without Coverage

The primary challenge with coverage-based approaches is identifying the elements that need to be covered. An alternative approach is to define diversity more explicitly and select a subset of demonstrations that are dissimilar from one another (while being relevant for the input utterance).

A natural approach for choosing a subset of high-quality and diverse demonstrations from the training set is Determinantal Point Process (DPP) [Kulesza2012DeterminantalPP], a probabilistic model that defines a probability distribution over subsets of items, giving high probability to subsets that contain _relevant_ and _diverse_ items. DPP requires a _relevance score_ for each item and a _similarity score_ between pairs of items. In our case, we define the relevance of a demonstration through its _retriever score_ for the input test utterance. To compute the similarity between demonstration pairs, we first extract LSs and compute tf-idf vectors for each demonstration. The similarity of each pair is then the cosine similarity between their tf-idf vectors.

## Prompt Construction

We order the chosen demonstrations according to their retriever score with respect to the input utterance in ascending order, in accordance to common practices [liu-etal-2022-makes]. When finetuning the model (Section 3.4), demonstrations are shuffled. Demonstrations are formatted to a prompt according to the format in Appendix, concatenated with the test utterance, and fed to the model.

## Finetuning with Prompts

Despite the success of "pure" in-context learning, where model parameters are frozen, it has been by and large restricted to very large LMs. Conversely, finetuning requires more training data, but performs well even with smaller models. In-context learning can be easily integrated with finetuning by training a model with demonstrations as part of the input. This paradigm can be considered as meta-learning, where the model learns how to use demonstrations during training [min-etal-2022-metaicl].

**Table 1: Dataset Examples**

| Dataset             | Example                                                                                                                                                                                                                                                                                                                                       |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SMCalFlow-CS        | Utterance: _Set up a meeting with my team and David Lax's reportees._                                                                                                                                                                                                                                                                         |
|                     | Program: `(Yield :output (CreateCommitEventWrapper :event (CreatePreflightEventWrapper :constraint (Constraint[Event] :attendees (AttendeeListHasPeople :people (FindReports :recipient (Execute :intension (refer (extensionConstraint (RecipientWithNameLike :constraint (Constraint[Recipient]) :name # (PersonName "David Lax"))))))))))` |
| SMCalFlow-CS Simple | Utterance: _Create a new meeting on Friday called Work on Project._                                                                                                                                                                                                                                                                           |
|                     | Program: `CreateEvent (AND (has_subject ("Work on Project"), starts_at (NextDOW ("Friday"))))`                                                                                                                                                                                                                                                |
| GeoQuery (natural)  | Utterance: _what is the longest river that flows through texas_                                                                                                                                                                                                                                                                               |
|                     | Program: `largest_one (population_1 (state (traverse_1 (riverid ("mississippi")))))`                                                                                                                                                                                                                                                          |
| COVR-10 (synthetic) | Utterance: _What is the color of the square on a dog?_                                                                                                                                                                                                                                                                                        |
|                     | Program: `query_attr[color] (filter (square, find (dog)))`                                                                                                                                                                                                                                                                                    |

When meta-learning is used in the i.i.d. setup, where the training and test examples are drawn from the same distribution, one can use the same procedure to select demonstrations at both training time and test time. However, in a compositional generalization setup, this does not work: at training time, the model will observe demonstrations that are similar to the target output and will learn to heavily rely on demonstrations and copy large chunks of them. Thus, the model will not learn to compose demonstration parts and will struggle with examples drawn from a different distribution.

To address this phenomenon, which we term _over-copying_, past work [pasupat-etal-2021-controllable; zemlyanskiy-etal-2022-generate] used _sampling_ to add noise to the demonstrations. Here, we also reduce the similarity of demonstrations to the input utterance, but with a simpler approach. Recall that our Cover-LS algorithm picks similar examples by (a) finding demonstrations that share _large_ LSs with the predicted program, and (b) using a retriever to find the most similar examples among these. To address over-copying, we modify this: at training time, we only consider LSs of size 1, i.e., program symbols, and for each such LS we randomly choose an example that contains this symbol rather than use a powerful retriever.

# Experiments

We present our experimental setup and results on different compositional semantic parsing tasks, with finetuning (FT) and without (NoFT).

**Table 2: NoFT Results (Codex)**

|                            | GeoQuery |          |          |          | SMCalFlow-CS |          |          |          |          | COVR-10  |
| -------------------------- | -------- | -------- | -------- | -------- | ------------ | -------- | -------- | -------- | -------- | -------- |
|                            | i.i.d.   | Templ.   | TMCD     | Len.     | i.i.d.       | 0-C      | 8-C      | 16-C     | 32-C     |          |
| T5 (finetuned w/o prompts) | 90.3     | 85.9     | 75.4     | 36.0     | 88.5         | 0.0      | 34.5     | 39.0     | 50.0     | 21.5     |
| Random                     | 53.7     | 49.7     | 42.0     | 30.7     | 43.0         | 1.3      | 0.3      | 0.7      | 2.0      | 69.4     |
| Top-K                      | 86.3     | 78.0     | 71.8     | 64.3     | 81.7         | 17.0     | 34.0     | 35.7     | 50.3     | 61.8     |
| Cover-Utt (ours)           | **89.0** | 82.1     | 77.8     | 73.7     | 83.3         | **35.3** | 51.0     | 51.3     | 69.7     | **78.1** |
| DPP (ours)                 | 87.0     | 81.2     | 77.8     | **74.3** | 79.3         | 34.7     | 44.0     | 50.0     | 59.7     | 62.7     |
| Cover-LS (ours)            | 88.7     | **85.3** | **79.4** | 72.7     | **86.0**     | 0.3      | **53.3** | **58.3** | **73.5** | 64.4     |
| Top-K (Oracle)             | 86.3     | 74.5     | 76.2     | 55.7     | 85.0         | 0.0      | 33.0     | 54.0     | 59.6     | 35.4     |
| Cover-LS (Oracle)          | 86.3     | 81.2     | 82.8     | 74.0     | 84.3         | 40.7     | 77.3     | 73.5     | 75.3     | 83.2     |

## Datasets

We evaluate our methods on three datasets.

### SMCalFlow-CS

This is a few-shot compositional generalization dataset proposed by Yin et al. derived from SMCalFlow [andreas-etal-2020-task]. It contains single-turn natural sentences involving two domains (organization structure and event creation), each having its own set of program symbols. The test set of the compositional splits contains only cross-domain examples, where both domains appear. We show results for a few-shot setting (split k-C, where k in {8,16,32}) where the training set includes only k cross-domain examples, and a zero-shot setting (split 0-C). We also evaluate on an i.i.d. split where the test set contains only single-domain examples. Prior studies on the dataset employed LISP and LISPRESS program formats, resulting in v1 and v2 versions, respectively. We default to using v1, unless otherwise specified.

For our FT experiments, we use **SMCalFlow-CS Simple**, which contains the same utterances as SMCalFlow-CS, but with programs that use a simplified syntax. We opt for this version because programs are much shorter, leading to a smaller memory footprint and accelerating training and inference.

### GeoQuery

[Zelle1996LearningTP; Tang2001UsingMC] contains 880 natural language questions about US geography. We use the standard (i.i.d.) and compositional splits created by Shaw et al.: (1) template split, where target programs are anonymized into templates and then the templates are randomly split between training and test sets [finegan-dollak-etal-2018-improving]; (2) TMCD split, which makes the distributions of compounds in training and test sets as divergent as possible [keysers2020measuring]; and (3) length split, where test sequences are longer than training ones. Similar to prior work, we average results across three TMCD and template splits to reduce variance caused by the small dataset size.

### COVR-10

COVR [bogin-etal-2022-unobserved] is a synthetic dataset based on a variable-free functional language. COVR-10 contains 10 compositional grammar splits, in which each test set includes programs featuring a particular set of local structures not observed at training time. Results are averaged across the 10 splits.

## Experimental setup

### Models

We use Codex (code-davinci-002) [Chen2021EvaluatingLL; Ouyang2022TrainingLM] for all NoFT experiments, and T5-large [Raffel2020ExploringTL] for FT experiments. T5-large is used to predict LSs in both the NoFT and FT setups.

### Evaluation

Like prior work, we use exact match accuracy as the main metric for evaluation. Results are averaged over 3 random seeds unless stated otherwise. In the FT setup, we use the entire test set for evaluation. In the NoFT setup, we use 100 test examples due to rate limits of the Codex inference API (and another 100 development examples for hyperparameter tuning).

### Prompt

We use a prompt size of k=24 for NoFT experiments and k=3 for FT experiments, unless stated otherwise. A prompt is truncated when its length exceeds the model's context length (excluding the tokens reserved for generation). In FT experiments, we included only the programs in our demonstrations and discarded their utterances, due to limitations of memory and sequence length (preliminary experiments with utterances showed this does not affect accuracy).

### Retrievers

In NoFT setup, we use BM25 over lower-cased utterance words. In FT setup, we use BM25 over predicted program symbols in `latex $\mathcal{S}_{\tilde{y}_{\small\text{test}}}$ ` (predicted using T5). In Cover-LS experiments we use a random retriever at training time to avoid over-copying. We analyze other possible retriever choices in Section 4.6.

### Hyperparameter tuning and model selection

We train two types of models in this work: (a) models for predicting LSs, and (b) models finetuned with prompts. For both cases, we use the development set whenever it is available for model selection, otherwise, we use the last checkpoint. Similarly, we use the development set to tune the number of beam candidates B when predicting local structures, and if there is no development set, we set B=1.

### Local structure size

In some experiments, we limit the maximum size of local structures (the number of nodes they contain). A subscript notation (Cover-LS_d or DPP_d) indicates a limit up to size d.

## Baselines

### Finetuning without prompts

Vanilla-finetuned T5 model which is trained without demonstrations, similar to the one used to predict LSs (Section 3.1), except that it is trained on non-anonymized programs.

### Top-K

We construct the prompt with the top-k examples that are most similar to `latex $x_{\small\textrm{test}}$ ` according to the retriever score.

### Random

We construct a prompt by randomly sampling k training examples without repetition.

We also conduct oracle experiments, where at test time we have access to `latex $y_{\small\text{test}}$ ` both for retrieval and LS coverage. The retriever takes as input the gold program and scores demonstrations using BM25 over the gold program symbols. In oracle Cover-LS, we cover local structures from `latex $\mathcal{S}_{{y}_{\small\text{test}}}$ ` without predicting them with a model.

## Main Results

### NoFT

We observe (Table 2) that all methods for increasing diversity (Cover-Utt, DPP and Cover-LS) outperform Top-K, which selects similar demonstrations without accounting for diversity, in 7 out of 8 compositional splits. In fact, all non-oracle diversity methods outperform an _oracle_ Top-K in 7 out of 8 compositional splits, suggesting that retrieval methods that only consider similarity are sub-optimal even in an oracle setup. Similarly, all diversity methods improve performance compared to a finetuned T5 model in all compositional splits except GeoQuery's template splits. Furthermore, sampling random examples (Random baseline) results in poor performance in GeoQuery and SMCalFlow-CS, but achieves high accuracy in COVR-10, beating all methods except Cover-Utt. This can be explained by the synthetic nature and small vocabulary of COVR-10.

Comparing diversity methods, Cover-LS and Cover-Utt are better than DPP in 7 out of 10 splits, showing that covering the target input/program goes beyond simply picking diverse examples. Cover-Utt, which covers utterance words, works surprisingly well considering its simplicity. Coverage-based methods also outperform Top-K in i.i.d splits. One noticeable failure of Cover-LS is the 0-C split, where it fails to generalize, due to the poor T5 performance on this split (T5 baseline gets 0 accuracy). This emphasizes that if one cannot reasonably predict LSs, then covering input words is a viable alternative. Lastly, oracle methods outperform their non-oracle counterparts in most settings, but not always. This occurs because our oracle method, which has access to the gold program, does not guarantee the selection of the optimal set of demonstrations, a phenomenon also observed in prior work.

[IMAGE: Figure 3 - Comparing model accuracy (NoFT setup) based on the number of demonstrations, with multiple methods for selecting demonstrations.]

Table 3 shows accuracy on the entire test set (NoFT setup). Since the underlying models differ substantially, a fair comparison to previous work is impossible. Nevertheless, a comparison still provides a high-level overview for the state of these tasks. Results show that using Codex with Cover-LS outperforms a T5 finetuned with augmentation [qiu-etal-2022-improving] in 4 compositional splits out of 6 (TMCD, Length, 8-C and 32-C), and outperforms non-finetuned PaLM 540B, where demonstrations are selected using BM25, in all splits.

#### Number of demonstrations (NoFT)

We examine how performance is affected by the number of demonstrations in Figure 3. Cover-LS outperforms Top-K by a large margin across all prompt sizes. Moreover, Cover-LS requires just four demonstrations in order to obtain roughly the same results as Top-K with 24 demonstrations. The gap between Cover-LS and Cover-Utt or Cover-LS_1 shows the importance of covering structures rather than just program symbols or utterance words, especially for small demonstration sets.

**Table 4: FT Results (T5-large)**

| Training Method      | Test Method       | GeoQuery |          |          |          | SMCalFlow-CS Simple |          |          |          | COVR-10  |
| -------------------- | ----------------- | -------- | -------- | -------- | -------- | ------------------- | -------- | -------- | -------- | -------- |
|                      |                   | i.i.d.   | Templ.   | TMCD     | Len.     | i.i.d.              | 8-C      | 16-C     | 32-C     |          |
| T5 (FT, w/o prompts) | -                 | 92.5     | 83.8     | 73.5     | 37.2     | 83.7                | 9.7      | 37.5     | 59.4     | 19.4     |
| Random               | Random            | **93.2** | 85.0     | 76.8     | 39.8     | 83.5                | 28.3     | 46.4     | 58.0     | 23.2     |
| Random               | Top-K             | 93.0     | 84.6     | 75.9     | 39.8     | 83.4                | 24.4     | 40.6     | 54.8     | 22.8     |
| Top-K                | Top-K             | 90.7     | 54.7     | 57.4     | 20.8     | 83.2                | 8.8      | 22.1     | 46.1     | 19.6     |
| Cover-LS_1           | Cover-LS_1        | 92.9     | 85.3     | 76.6     | 41.9     | 83.9                | **31.0** | **51.3** | **62.6** | **29.8** |
| Cover-LS_1           | Cover-LS          | 93.1     | **85.9** | **77.6** | **42.7** | **84.1**            | 30.5     | 50.6     | 61.5     | 28.6     |
| Cover-LS_2           | Cover-LS          | 92.6     | 84.9     | 75.6     | 39.8     | 83.7                | 28.8     | 46.3     | 60.5     | 28.8     |
| Cover-LS             | Cover-LS          | 91.8     | 80.7     | 69.4     | 37.7     | 82.9                | 21.2     | 34.1     | 53.8     | 13.6     |
| Cover-LS_1           | Cover-LS (Oracle) | 93.7     | 87.7     | 79.8     | 48.9     | 87.4                | 48.0     | 64.1     | 73.5     | 41.1     |

### FT

Finetuning results are shown in Table 4, where we detail separately the method used for demonstration selection at both training time and test time, as those may diverge to avoid over-copying.

First, using random demonstrations at test time, without controlling for diversity or using any retriever, is better compared to using no demonstrations at all. Our main method constructs prompts with Cover-LS at test time, but during training, prompts are retrieved with Cover-LS_1, that only covers program symbols, but not local structures, to avoid over-copying (see Section 3.4). This combination leads to higher performance in all compositional splits compared to baselines that use Top-K or random sampling. Interestingly, using Top-K at both training time and test time yields low accuracy in compositional splits, but high results in i.i.d. splits. This corroborates our assumption that diversity is needed in compositional setups. Finally, A variant of our method, where Cover-LS_1 is used both during training and test time, is comparable to our main method across all splits.

We observe that limiting coverage at training time to program symbols is crucial: accuracy drops in all splits if we limit Cover-LS to structures up to size 2 (Cover-LS_2) instead of 1, or if we have no such limitation at all. The oracle Cover-LS outperforms all non-oracle models (unlike in NoFT, where this is not always the case).

## Analysis

[IMAGE: Figure 4 - Properties of test example groups, where grouping is based on NoFT prediction outcome: (1) Top-K succeeds; (2) Cover-LS succeeds; (3) only Cover-LS succeeds; and (4) both fail.]

### Stratified analysis

Our main results show that Cover-LS outperforms Top-K in most compositional splits. But what examples does it perform better on? We analyze properties of test example groups, where grouping is based on NoFT prediction outcome: (1) Top-K succeeds; (2) Cover-LS succeeds; (3) only Cover-LS succeeds; and (4) both fail. For each group we estimate difficulty by measuring the average accuracy achieved by a T5 model (finetuned without prompts), and also compute the percentage of examples that have an _unobserved local structure_ (ULS) with respect to the training set. This measure is central to determining whether generalization to a test instance is hard, as shown in prior work.

We see (Figure 4) that as the group index increases, T5 accuracy decreases and ULS rate increases. This finding confirms the claim that a test instance containing an ULS is hard. Examining groups 1 and 3, we observe that the group for which Cover-LS performs better than Top-K, is also tougher for T5 and has more ULS. Both methods fail on examples with low T5 accuracy and high ULS scores (group 4). This is also evidence that T5 and Codex agree on the difficulty of examples, despite their different training and inference schemes.

### Prompt metrics

We analyze the characteristics of prompts constructed with different demonstration selection methods. Symbol Coverage shows the average fraction of symbols in `latex $y_{\small\text{test}}$ ` that are covered by the demonstration set, and similarly LS Coverage the fraction of covered LSs. While symbol coverage is generally high across all methods when using 24 demonstrations, LS coverage is significantly higher in Cover-LS, suggesting that only covering relevant symbols in prompts isn't as efficient as covering LSs. Utterance Similarity measures average cosine similarity between SBERT embeddings of the test utterance and prompt utterances, which is highest for Top-K as expected. To approximate diversity between demonstrations, we calculate the average number of unique LSs in demonstrations, and observe it is substantially higher in Cover-LS and DPP compared to Top-K. This implies structural coverage and diversity are more important than input similarity in compositional splits.

### Robustness to retrieval methods

To assess our method's robustness, we test how sensitive it is to the chosen retriever in the NoFT setup. First, we use our default retrievers, which are BM25 over utterance words (BM25-Utterance), and BM25 over predicted program symbols (BM25-Predicted). We add a random retriever that is identical to the Random baseline introduced in Section 4.3 when combined with Top-K. We also evaluate the SBERT retriever [reimers-gurevych-2019-sentence], which encodes input utterances and measures the cosine similarity between pairs of encodings. As seen in Figure 5, Cover-LS outperforms Top-K in all settings by a significant margin. Moreover, while BM25-Utterance performs best, variance across retrievers is low for Cover-LS, but higher for Top-K.

# Related Work

### Example selection

One of the central issues in in-context learning is the selection of examples, which can either be based on parameter-free retrievers [wang-etal-2022-training; zemlyanskiy-etal-2022-generate] or neural-based retrievers [pasupat-etal-2021-controllable; liu-etal-2022-makes; rubin-etal-2022-learning]. These studies consider each example separately, which often leads to a lack of coverage and diversity.

Our approach is similar to the retrieval procedure in Zemlyanskiy et al., which makes a preliminary prediction and retrieves demonstrations with similar programs. However, while they use classic tf-idf with predicted tokens, we use predicted local structures and aim to cover them.

Some studies encourage diverse example selection regardless of prompting. To address multi-answer retrieval, Nandigam et al. employ DPP, and Min et al. autoregressively select instances based on previous selections. Other works include Su et al., which selects instances with varying confidence scores for annotation and (concurrent work) Ye et al. who propose a maximum marginal relevance-based selection strategy.

### In-context learning for compositional generalization

There have been previous attempts to address compositional generalization problems using LLMs equipped with demonstrations. When selecting demonstrations, some also consider target coverage or structure similarity, but only in oracle setups [hosseini-etal-2022-compositional; qiu-etal-2022-evaluating]. Drozdov et al. try to cover the syntactic parse tree constituents with demonstrations but rely heavily on manually-picked examples.

[IMAGE: Figure 5 - Comparing model accuracy across different retrievers, with demonstrations selected using Top-K or Cover-LS.]

# Conclusion

In this paper, we studied how to leverage ICL to improve compositional generalization in semantic parsing, by increasing diversity among demonstrations. We found that choosing demonstrations that cover the structures required in the output program substantially improves performance across three compositional semantic parsing datasets in the pure in-context learning setup and when combined with finetuning. We further demonstrated that by aiming for structural coverage, we can reduce the number of demonstrations needed for generalization, and improve test performance on hard examples. Our approach can be applied to a wide range of NLP tasks where demonstrations should cover complementary aspects of the task, and we hope it will encourage further exploration of our method to improve generalization across diverse applications.

# Limitations

### Demonstration selection methods

We assume that diversity can be obtained by choosing demonstrations with different program structures. This is based on previous work that demonstrated the importance of diversifying program structures in semantic parsing tasks [oren-etal-2021-finding; bogin-etal-2022-unobserved; gupta-etal-2022-structurally]. We also try to diversify utterance words or program symbols but do not consider more complex utterance features that could be applied to a wider range of language understanding tasks.

We also assume that recall matters more than precision when designing Cover-LS algorithm. That means we aim to choose a set of demonstrations that covers every predicted local structure in `latex $\mathcal{S}_{\tilde{y}_{\small\text{test}}}$ `, since it has the potential to be a correct one. We do not predict whether a specific structure should be covered. Furthermore, our approach for increasing gold structure coverage by using additional beam candidates could be improved by employing search methods specifically targeted for diversity [meister-etal-2021-determinantal; narayan-etal-2022-well].

### Retrievers

We used different retrievers for NoFT and FT setups based on the retriever that worked best on the development set. Future research should be conducted to understand why different retrievers are preferred in different setups. A potential method could be to consider both input utterances and programs for retrieval.

# Appendix: Additional Analysis

### Error analysis

We analyze errors (NoFT setup). Inspired by the metrics in prior work, we automatically compute statistics for the following cases when the prediction is wrong: (1) Syntax Errors, when the model produces a program with invalid parentheses; (2) Over-Copying, when the entire prediction has the same anonymized form as one of the demonstrations; (3) OOV (out-of-vocabulary) Hallucination, where the anonymized predicted program contains a symbol missing from the gold program or any prompt demonstration; and (4) Missing Symbol(s), where the predicted program is missing at least one symbol.

The distribution of errors is similar across demonstration selection methods. Syntax errors are rare in both datasets. Many predictions are over-copied, especially in SMCalFlow-CS, but when diversity is increased with DPP, this number decreases significantly. Surprisingly, despite having a smaller vocabulary, GeoQuery has more out-of-vocabulary hallucinations. Almost all incorrect predictions have a missing symbol, but Top-K predictions are especially prone to this type of error.

# Appendix: Local Structures

We follow the definition of local structures from prior work, which were defined for structures of sizes 2-4, and extend them to local structures of any size. Given a program y, we parse it into a tree `latex $T=(\mathcal{V},\mathcal{E})$ `, such that each node `latex $v \in \mathcal{V}$ ` is labeled by the program symbol (function or value) that it represents in y (or a special symbol for the root node), and the set of edges `latex $\mathcal{E}=\{(p,c)\}$ ` expresses **parent-child** relations between the nodes.

We capture sibling relations by defining a graph based on the tree T that contains an edge set `latex $\mathcal{E}_{\text{sib}}$ ` of **sibling** edges: `latex $G=(\mathcal{V},\mathcal{E} \cup \mathcal{E}_{\text{sib}})$ `. Specifically, for each parent node p, the program y induces an order over the children of p: `latex $(c^p_1, ..., c^p_{N_p})$ `, where `latex $N_p$ ` is the number of children. We then define `latex $\mathcal{E}_{\text{sib}}=\bigcup_p\{c_i^p, c_{i+1}^p\}_{i=1}^{N_p}$ `, that is, all _consecutive_ siblings will be connected by edges.

We define a local structure of size n as the subset `latex $G_{LS}$ ` of all connected sub-graphs of size n in G such that for every pair (x, y) of nodes in `latex $G_{LS}$ ` it holds that `latex $(x, y) \in \mathcal{E}_{\text{sib}}$ ` iff x and y are both leaves in `latex $G_{LS}$ `. That is, informally, the relations between nodes in the sub-graph include parent-child and siblings, but not e.g. cousins or uncles. All program symbols are local structures of size 1.

**Table: Local Structure Examples for SMCalFlow-CS Simple**

| Dataset            | SMCalFlow-CS Simple                                                                   |
| ------------------ | ------------------------------------------------------------------------------------- |
| Utterance          | _Create a new meeting on Friday called Work on Project._                              |
| Program            | `CreateEvent (AND (has_subject ("Work on Project"), starts_at (NextDOW ("Friday"))))` |
| Anonymized Program | `CreateEvent (AND (has_subject (string), starts_at (NextDOW (string))))`              |

| Size | Local structures                                                                                                                                                                                                |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | `CreateEvent`, `AND`, `has_subject`, `string`, `starts_at`, `NextDOW`                                                                                                                                           |
| 2    | `<root>->CreateEvent`, `CreateEvent->AND`, `AND->has_subject`, `AND->starts_at`, `has_subject<->starts_at`, `has_subject->string`, `starts_at->NextDOW`, `NextDOW->string`                                      |
| 3    | `<root>->CreateEvent->AND`, `CreateEvent->AND->has_subject`, `CreateEvent->AND->starts_at`, `AND->has_subject<->starts_at`, `AND->has_subject->string`, `AND->starts_at->NextDOW`, `starts_at->NextDOW->string` |
| ...  | ...                                                                                                                                                                                                             |
| 6    | `<root>->CreateEvent->AND->starts_at->NextDOW->string`                                                                                                                                                          |

## Fixes for Local Structure Extraction

We try to fix syntax errors in the predictions made using the auxiliary model to enable parsing them to ASTs and extraction of LSs. We add or remove closing parentheses based on the number of missing or redundant parentheses at the end of the program.

# Appendix: Dataset Details

**Table: Dataset Sizes**

| Dataset             | Split      | Train | Development | Test |
| ------------------- | ---------- | ----- | ----------- | ---- |
| GeoQuery            | Standard   | 600   | -           | 280  |
|                     | Template1  | 438   | 110         | 332  |
|                     | Template2  | 439   | 110         | 331  |
|                     | Template3  | 440   | 110         | 330  |
|                     | TMCD1      | 440   | 110         | 330  |
|                     | TMCD2      | 440   | 110         | 330  |
|                     | TMCD3      | 440   | 110         | 330  |
|                     | Length     | 440   | 110         | 330  |
| SMCalFlow-CS v1     | 8-S        | 25412 | 662         | 662  |
|                     | 0-C        | 25404 | 662         | 663  |
|                     | 8-C        | 25412 | 662         | 663  |
|                     | 16-C       | 25420 | 662         | 663  |
|                     | 32-C       | 25436 | 662         | 663  |
| SMCalFlow-CS v2     | 8-S        | 20965 | 360         | 360  |
|                     | 0-C        | 20957 | 360         | 360  |
|                     | 8-C        | 20965 | 360         | 360  |
|                     | 16-C       | 20973 | 360         | 360  |
|                     | 32-C       | 20989 | 360         | 360  |
| SMCalFlow-CS Simple | 8-S        | 25402 | 662         | 662  |
|                     | 8-C        | 25402 | 662         | 663  |
|                     | 16-C       | 25410 | 662         | 663  |
|                     | 32-C       | 25426 | 662         | 662  |
| COVR-10             | Each split | 3000  | -           | 500  |

We used publicly available datasets from previous peer-reviewed studies. Those datasets do not contain any information that uniquely identifies individual people or offensive content. The COVR-10 dataset is completely synthetic. The GeoQuery dataset contains only basic information about U.S. geography. SMCalflow-CS contains crowd-sourced queries collected in a simulated environment.

# Appendix: Prompt Format and Examples

We add special prefixes "source:" and "target:" for retrieved source-target pairs and separate them with break lines.

# Appendix: DPP Details

DPPs are probabilistic models that are effective at modeling a distribution on all the subsets of the ground set `latex $\mathcal{T}$ ` jointly considering the quality and diversity. A subset `latex $\mathcal{D}$ ` is drawn according to the probability distribution `latex $\mathcal{P}$ `:

```latex
$$\mathcal{P}(\mathcal{D} \subset \mathcal{T}; L) \propto \det(L_\mathcal{D})$$
```

Where `latex $L \in \mathbb{R}^{n \times n}$ ` is a PSD matrix and `latex $L_\mathcal{D}$ ` is the submatrix of L indexed by items in `latex $\mathcal{D}$ `. L matrix takes into account the quality of each training example and its similarity to other training examples through:

```latex
$$L_{ij}=q_i \phi_i^\top \phi_j q_j$$
```

with `latex $q \in \mathbb{R}^{n}$ ` being normalized retriever scores that model the quality of each example; and `latex $\{\phi_i\}_{i=1}^n$ ` denoting normalized tf-idf vectors over LSs, which model the different aspects that are contained within each training example. The dot product of those vectors is used to model the similarity between two train examples.

`latex $\log \ \det(L_\mathcal{D})$ ` is a submodular function which satisfies the diminishing marginal returns property. Therefore, we can find a subset of training examples `latex $\mathcal{D} \subset \mathcal{T}, |\mathcal{D}|=k$ ` that maximizes it in a feasible manner using a greedy optimizer. Specifically, we used the Naive Greedy optimizer. We used scikit-learn for calculating tf-idf vectors.

# Appendix: Finetuning Details

We provide implementation details for finetuning experiments (we use the same configuration for all FT experiments and training of the auxiliary model). We finetune the T5-large model (770 million parameters) with the AdamW optimizer [Loshchilov2017DecoupledWD] and a learning rate of 1e-5. We use a polynomial decay learning rate with an ending rate of 1e-6, and 100 warmup steps. We train for 250/50/70 epochs and evaluate on the validation set every 3/5/10 epochs for Geo/SMCalFlow (both versions)/COVR respectively. We use batches of size 8 for all datasets (and gradient accumulation in case batch cannot fit in memory). We used a single GPU for each T5-large finetuning experiment: Nvidia GeForce RTX 3090 when training on GeoQuery and COVR-10, and A100 (80GB) for SMCalFlow-CS and SMCalFlow-CS Simple. GeoQuery experiments with prompts trained for an average of 2 hours, COVR for 8 hours, and SMCalFlow-CS Simple for 41 hours.

We use the AllenNLP library [gardner-etal-2018-allennlp] for training and evaluation. We use Rank-BM25 as a BM25 implementation.

# Appendix: NoFT Details

All NoFT experiments were conducted using the OpenAI inference API with the sampling temperature set to 0. Our setup requires a single API call per test instance. The total number of API calls is estimated at 160K.
