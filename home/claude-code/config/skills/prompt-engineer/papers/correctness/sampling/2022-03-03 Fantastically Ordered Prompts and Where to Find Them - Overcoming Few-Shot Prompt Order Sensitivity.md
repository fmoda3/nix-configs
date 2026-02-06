# Fantastically Ordered Prompts and Where to Find Them: Overcoming Few-Shot Prompt Order Sensitivity

arXiv:2104.08786

Authors: Yao Lu, Max Bartolo, Alastair Moore, Sebastian Riedel, Pontus Stenetorp

Affiliations: University College London, Mishcon de Reya LLP

## Abstract

When primed with only a handful of training samples, very large, pretrained
language models such as GPT-3 have shown competitive results when compared to
fully-supervised, fine-tuned, large, pretrained language models. We demonstrate
that the order in which the samples are provided can make the difference
between near state-of-the-art and random guess performance: essentially some
permutations are "fantastic" and some not. We analyse this phenomenon in
detail, establishing that: it is present across model sizes (even for the
largest current models), it is not related to a specific subset of samples, and
that a given good permutation for one model is not transferable to another.
While one could use a development set to determine which permutations are
performant, this would deviate from the true few-shot setting as it requires
additional annotated data. Instead, we use the generative nature of language
models to construct an artificial development set and based on entropy
statistics of the candidate permutations on this set, we identify performant
prompts. Our method yields a 13% relative improvement for GPT-family models
across eleven different established text classification tasks.

## 1. Introduction

Large pretrained language models (PLMs) have shown remarkable performance when
conditioned with an appropriate textual context. For example, when conditioned
on a long document and a "TL;DR:" token, they can generate a summary of said
document, and when provided a partial question ("The theory of relativity was
developed by \_\_"), they can generate the correct answer. Perhaps most
strikingly, when primed with a context consisting of very few training
examples, they produce text classification results that can match those of
fully supervised models. This type of few shot setting is commonly referred to
as "In-context Learning".

A core component of in-context learning is the text-based prompt that serves as
the context. Composing a prompt requires: (i) text linearisation using a
template; and (ii) training sample concatenation. It has been established that
the structure of the template has a large impact on performance. However, to
the best of our knowledge, no work has studied the effect of the sample
ordering on In-context Learning performance.

Perhaps counter-intuitively, we find that the right sample order can make as
much of a difference as the right template. Some permutations have comparable
performance (over 85% accuracy) to supervised training for sentiment
classification, while others perform close to random (around 50%). This order
sensitivity is universal across models, and although increasing the model size
somewhat addresses it, the problem is still present for some text
classification tasks for models with billions of parameters.

In our analysis, we find no common denominator between performant sample orders
and that they are not transferable across different model sizes and tasks.
Instead, we use the generative nature of language models to construct an
unlabelled artificial development set and refer to it as a _probing set_. As
the probing set is unlabelled, we use the predicted label distribution
statistics and propose entropy-based metrics to measure the quality of
candidate prompts. Experimental results show that we can achieve on average 13%
relative improvement across eleven different established text classification
tasks across all different sizes (four orders of magnitude) of PLMs.

### Contributions

1. We study order sensitivity for In-context Learning, which we show is crucial
   for the success of pretrained language models for few-shot learning.
2. We propose a simple, generation-based probing method to identify performant
   prompts without requiring additional data.
3. Our probing method is universally applicable and effective across different
   sizes of pretrained language models and for different types of datasets --
   achieving on average a 13% relative improvement over a wide range of tasks.

## 2. Order Sensitivity and Prompt Design

### Prompt Construction Example

| Stage         | Example                                                                                                                                                                                                    |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Training set  | (the greatest musicians, 1), (redundant concept, 0)                                                                                                                                                        |
| Linearization | Review: the greatest musicians. Sentiment: positive; Review: redundant concept. Sentiment: negative                                                                                                        |
| Concatenation | Review: the greatest musicians. Sentiment: positive. Review: redundant concept. Sentiment: negative OR Review: redundant concept. Sentiment: negative. Review: the greatest musicians. Sentiment: positive |

### Although beneficial, increasing model size does not guarantee low variance

We evaluate the order permutations for four different sizes of GPT-2
(0.1B--1.5B) and GPT-3 (2.7B--175B). Models can obtain remarkable few-shot
performance. The GPT2-XL (1.5B) model can even surpass 90% accuracy given just
four samples. This result is comparable to those of supervised models trained
on more than 60,000 samples. However, the performance variation of different
permutations remain a big issue, especially for "smaller" models. The same
model can exhibit nearly perfect behaviour given one sample order, but then
fall back to be on par with a random baseline for another. While increasing the
model size (by a few order of magnitudes) can sometimes alleviate the issue, it
still cannot resolve it entirely. In contrast, different initialisations of
supervised fine-tuning approaches typically result in less than 1% standard
deviation for their test set performance.

### Adding training samples does not significantly reduce variance

Increasing the number of training samples leads to increases in performance.
However, a high level of variance remains, even with a large number of samples
and can even increase. Based on this, we draw the conclusion that order
sensitivity is likely to be a fundamental issue of In-context Learning
regardless of the number of training samples.

### Performant prompts are not transferable across models

A specific permutation's performance may drop from 88.7% to 51.6% by changing
the underlying model from GPT2-XL (1.5B) to GPT2-Large (0.8B). This suggests
that a particular permutation working well for one model does not imply that it
will provide good results for another model.

The behaviour of permutations is seemingly random even across different sizes
of the same model. For example, the 175B and 2.7B model only has a correlation
of 0.05, meaning a good permutation for the 2.7B model is in no way guaranteed
to also yield good performance for the 175B model.

### Performant label orderings are not consistent across models

In addition to training example ordering, we also explore label ordering for
training prompts. We use all patterns of the above-mentioned full permutations
-- six different label patterns (NNPP, NPNP, NPPN, PNNP, PNPN, PPNN, where P/N
respectively denotes positive/negative). The behaviour of label orderings is
once again seemingly random across different sizes of the same model. It is
thus not possible to identify a label ordering that is performant across
different models.

### Degenerate behaviour of bad prompts

Error analysis across performant and non-performant prompts shows that the
majority of failing prompts suffer from highly unbalanced predicted label
distributions. An intuitive way to address this would be by calibrating the
output distribution. However, although calibration leads to much higher
performance, the variance remains high.

## 3. Methodology

The challenge is to select prompt orders automatically and without the need for
additional labels (e.g., a development set).

We approach this by:

1. For a randomly-selected set of training samples, we use every possible
   ordering permutation of this set as candidates
2. Constructing a _probing set_ by querying the language model using all
   candidate prompts as context
3. Use this probing set to identify the best ordering by ranking them using a
   probing metric

### Sampling from the Language Model to Construct a Probing Set

We propose a simple methodology to automatically construct a "probing set", by
directly sampling from the language model itself. This approach makes it
possible to generate probing sets automatically, without access to any
additional data.

Given a set of training samples S = {(x_i, y_i)}, i = 1, ..., n, where x_i and
y_i denote the sentence and label of the i-th training sample. We then define a
transformation T, mapping each sample into natural language space, such that
t_i = T(x_i, y_i). In this work, we use a simple transformation function T such
that T(x_i, y_i) = "input:" x_i "type:" y_i.

We then define a full permutation function group of n training samples, F =
{f_m}, m = 1, ..., n!, where each function f_m takes S' as input and outputs
c_m: the concatenation of a unique permutation. Sampling four training samples
at random gives up to 24 possible ordering permutations of the transformed
samples.

For each prompt candidate c_m, we then sample from the language model to obtain
the probing sequence g_m ~ P(. | c_m; theta), where theta denotes the
parameters of the pretrained language model. We stop decoding upon generating
the special end-of-sentence token defined by a template, or reach the
generation length limit.

We run this sampling process for all possible prompt ordering permutations and
extract probing samples from them. Then gather extracted samples together to
form the probing set D = T^-1(g_1) + ... + T^-1(g_n!). Although the probing set
contains predicted label for each sentence, there is no guarantee on the
validity of these labels. Therefore, we discard them from the probing set as we
are only interested in sampling probes from the language model corresponding to
the input distribution.

### Probing Metrics

Once we have constructed a probing set for a given set of samples, we can use
that probing set to identify the best possible prompt ordering.

#### Global Entropy (GlobalE)

The motivation behind GlobalE is to identify prompts of specific sample
orderings that avoid the issue of extremely unbalanced predictions.

We compute the predicted label y_hat_i for data point (x'\_i, y'\_i) under
context c_m as follows:

```
y_hat_{i,m} = argmax_{v in V} P(v | c_m + T(x'_i); theta)
```

For each label v in V (where V denotes the target label set), we compute the
label probability over the probing set as:

```
p^v_m = sum_i I(y_hat_{i,m} = v) / |D|
```

We then use the predicted category label entropy as the GlobalE score:

```
GlobalE_m = sum_{v in V} -p^v_m * log(p^v_m)
```

#### Local Entropy (LocalE)

The motivation behind LocalE is that if a model is overly confident for all
probing inputs, then it is likely that the model is not behaving as desired. At
the very least, it is poorly calibrated, which could also be an indication of a
poor capability to appropriately differentiate between classes.

We calculate the prediction probability of a data point over the target labels
v in V under context c_m:

```
p^v_{i,m} = P_{(x'_i, y'_i) ~ D}(v | c_m + T(x'_i); theta), v in V
```

We then calculate the average prediction entropy per data point as the LocalE
score:

```
LocalE_m = sum_i sum_{v in V} -p^v_{i,m} * log(p^v_{i,m}) / |D|
```

## 4. Experimental Setup

### Models

- GPT-2: 0.1B, 0.3B, 0.8B, and 1.5B parameters
- GPT-3: 2.7B and 175B parameters

Due to limited context window size (up to 1024 word-pieces for the GPT-2 series
of models), we use a 4-shot setting for all datasets except AGNews and DBPedia.

For probing set generation:

- Maximum generation length: 128
- Sampling temperature: 2
- Block n-gram repetitions to encourage diverse generation

We use 24 different permutations for each set of randomly selected training
samples and use 5 different sets (except for GPT-3 175B where we only use 2
sets with 12 different permutations due to high monetary cost).

For performant prompt selection, we rank candidate prompts using the LocalE and
GlobalE probing metrics over the automatically generated probing set. We select
top k = 4 samples ranked by highest entropy values.

### Evaluation Datasets

| Dataset | # of Classes | Avg. Len. | Balanced |
| ------- | ------------ | --------- | -------- |
| SST-2   | 2            | 12.4      | Yes      |
| SST-5   | 5            | 23.1      | No       |
| MR      | 2            | 25.7      | Yes      |
| CR      | 2            | 22.1      | Yes      |
| MPQA    | 2            | 3.9       | Yes      |
| Subj    | 2            | 28.9      | Yes      |
| TREC    | 6            | 11.6      | No       |
| AGNews  | 4            | 53.8      | Yes      |
| DBPedia | 14           | 65.5      | Yes      |
| CB      | 3            | 69.7/8.4  | No       |
| RTE     | 2            | 55.3/11.9 | Yes      |

## 5. Results

### Main Results Summary

GlobalE achieves, on average, a 13% relative improvement across eleven
different sentence classification tasks compared to prompts that do not use
probing. LocalE provides results slightly inferior to GlobalE, with an average
9.6% relative improvement over the baseline model. Selected performant prompts
also demonstrate considerably lower variance than using all candidate prompts.

### Key Findings

**Entropy-based probing is effective regardless of model size**: The method
provides improvements across all model sizes tested, from 0.1B to 175B
parameters.

**Ranking using Entropy-based probing is robust**: Visualising the average
performance when varying K for the top K prompt selection shows negative slopes
for all datasets, indicating effective ranking of performant prompts.

**Entropy-based probing is effective across templates**: Testing with four
different templates for SST-2 shows consistent improvements, indicating the
method is not sensitive to specific templates.

**Performant permutation selection is a safe option**: For models with high
prompt variance, the method shows up to 30% relative improvement. For tasks
with low initial variance, the method does not negatively impact performance.

**Sentence-pair tasks remain challenging for smaller models**: For CB and RTE
datasets, GPT-2 model performance is not significantly different from random
baseline. However, prompt selection can considerably improve performance at
larger model sizes (particularly GPT-3 175B).

### Comparison with Validation Set Splitting

Splitting the 4-shot training samples in half to form a validation set
consistently outperforms baseline, but both entropy-based probing methods
provide better performance across all model sizes.

| Model      | Baseline       | LocalE            | GlobalE           | Split Training Set |
| ---------- | -------------- | ----------------- | ----------------- | ------------------ |
| GPT-2 0.1B | 58.9 (sd 7.8)  | **65.2** (sd 3.9) | 63.8 (sd 5.8)     | 62.8 (sd 5.3)      |
| GPT-2 0.3B | 61.0 (sd 13.2) | 75.3 (sd 4.6)     | **78.7** (sd 5.2) | 64.2 (sd 6.1)      |
| GPT-2 0.8B | 74.5 (sd 10.3) | 81.1 (sd 5.5)     | **84.8** (sd 4.1) | 75.1 (sd 6.8)      |
| GPT-2 1.5B | 66.8 (sd 10.8) | 76.7 (sd 8.2)     | **81.8** (sd 3.9) | 71.4 (sd 7.8)      |

## 6. Related Work

### Unified Interface Design for NLP

Most previous work focuses on shared-parameters models, pretrain on some tasks,
then fine-tune for different tasks (ELMo, BERT, etc.). GPT-2 shows that
appending trigger tokens (e.g., "TL;DR") at the end of language model input can
cause language models to behave like summarisation models. GPT-3 shows that
task-agnostic, few-shot performance can be improved by scaling up language
models.

### Prompt Design for PLMs

The core challenge of prompt design is to convert training data (if it exists)
into a text sequence. Most work on prompt design focuses on how to make prompts
more compatible with language models:

- Human-designed natural language sentences for token prediction
- Automatic template construction using cloze-style tasks
- External language model-generated templates
- Gradient-guided search for templates that maximise performance
- Mining-based methods for diverse templates

### Order Sensitivity of Prompt Design

Finetuning-based approaches are not as order sensitive as In-context Learning.
Using a standard-size training set, nearest neighbour search can retrieve the
most relevant training samples for a specific test sample. After retrieving
them, the order in which they are provided in the prompt has little to no
effect on performance. However, this work differs in not using a standard-size
training set and comes to the opposite conclusion.

### True Few-shot Learning

Evaluating few-shot capability of LMs when a held-out validation set is not
available suggests that previous work overestimates the few-shot ability of LMs
in this (true few-shot learning) setting. This work uses the generative nature
of language models to construct a probing set without relying on held-out
examples.

## 7. Conclusion

Few-shot prompts suffer from order sensitivity, in that for the same prompt the
order in which samples are provided can make the difference between
state-of-the-art and random performance. This is present across tasks, model
sizes, prompt templates, samples, and number of training samples.

To alleviate this problem, a novel probing method exploits the generative
nature of language models to construct an artificial development set.
Performant permutations are identified using entropy-based statistics over this
set, leading to an average 13% improvement across eleven text classification
tasks.

## Appendix

### Prompt Templates and Label Mappings

| Dataset | Prompt Template                                          | Label Mapping                                              |
| ------- | -------------------------------------------------------- | ---------------------------------------------------------- |
| SST-2   | Review: {text} Sentiment: {label}                        | positive/negative                                          |
| SST-5   | Review: {text} Sentiment: {label}                        | terrible/bad/okay/good/great                               |
| MR      | Review: {text} Sentiment: {label}                        | negative/positive                                          |
| CR      | Review: {text} Sentiment: {label}                        | negative/positive                                          |
| MPQA    | Review: {text} Sentiment: {label}                        | negative/positive                                          |
| Subj    | Input: {text} Type: {label}                              | subjective/objective                                       |
| TREC    | Question: {text} Type: {label}                           | description/entity/expression/human/location/number        |
| AGNews  | input: {text} type: {label}                              | world/sports/business/technology                           |
| DBPedia | input: {text} type: {label}                              | company/school/artist/athlete/politics/transportation/etc. |
| CB      | premise: {text1} hypothesis: {text2} prediction: {label} | true/false/neither                                         |
| RTE     | premise: {text1} hypothesis: {text2} prediction: {label} | True/False                                                 |

### Notation Reference

| Notation     | Description                                       | Example                                |
| ------------ | ------------------------------------------------- | -------------------------------------- |
| x            | sentence                                          | nice movie                             |
| y            | label                                             | positive                               |
| T(x)         | template-based transformation without label       | Review: nice movie                     |
| T(x,y)       | template-based transformation                     | Review: nice movie Sentiment: positive |
| T^-1(T(x,y)) | extract (sentence, label) pair from text sequence | (nice movie, positive)                 |
