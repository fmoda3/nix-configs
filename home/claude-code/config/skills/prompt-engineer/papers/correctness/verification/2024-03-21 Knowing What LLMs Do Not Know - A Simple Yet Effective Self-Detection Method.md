# Knowing What LLMs DO NOT Know: A Simple Yet Effective Self-Detection Method

**arXiv:** 2310.17918
**Submitted:** 2024-03-21
**Authors:** Yukun Zhao, Lingyong Yan, Weiwei Sun, Guoliang Xing, Chong Meng, Shuaiqiang Wang, Zhicong Cheng, Zhaochun Ren, Dawei Yin
**Affiliations:** Shandong University, Baidu Inc., Leiden University

## Abstract

Large Language Models (LLMs) have shown great potential in Natural Language Processing (NLP) tasks. However, recent literature reveals that LLMs hallucinate intermittently, which impedes their reliability for further utilization. In this paper, we propose a novel self-detection method to detect which questions an LLM does not know. Our proposal is empirical and applicable for continually upgrading LLMs compared with state-of-the-art methods. Specifically, we examine the divergence of the LLM's behaviors on different verbalizations for a question and examine the atypicality of the verbalized input. We combine the two components to identify whether the model generates a non-factual response to the question. The above components can be accomplished by utilizing the LLM itself without referring to any other external resources. We conduct comprehensive experiments and demonstrate the effectiveness of our method for recently released LLMs involving Llama 2, Vicuna, ChatGPT, and GPT-4 across factoid question-answering, arithmetic reasoning, and commonsense reasoning tasks.

## 1. Introduction

With the significant improvements in large language models (LLMs) such as PaLM, ChatGPT, GPT-4, LLAMA 2, and Vicuna, LLMs have been applied in various natural language tasks. Unfortunately, LLMs still produce unexpected falsehoods, i.e., they are unaware of what they do not know and generate responses indiscriminately. These intermittent errors can severely hinder the LLMs' reliability in practice, which makes detecting what they do not know an important research problem.

### Motivating Example

Consider this knowledge quiz about the lyricist of "Kadam Kadam Badhaye Ja Khushi ke Geet Gaye Ja":

| Q1                                                                                            | Q2                                                                                         |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Who has written the lyrics to patriotic song "kadam kadam badhaye ja khushi ke geet gaye ja"? | Who is the lyricist of the patriotic song "Kadam Kadam Badhaye Ja Khushi ke Geet Gaye Ja"? |
| R1: The lyrics were written by **Shri Ravi Shankar Sharma** (incorrect)                       | R2: The lyricist is **Shri Pyarelal Santoshi** (incorrect)                                 |

**Correct Answer: Vanshidhar Shukla**

The model produces completely different (and wrong) responses to semantically equivalent questions.

### Two Paradigms for Detection

There are two main paradigms to detect non-factuality:

1. **Calibration-based methods**: Calibrate the model confidence to better detect falsehoods. These methods train auxiliary calibrators or improve calibration through fine-tuning.

2. **Self-detection methods**: Directly leverage the LLMs themselves to detect whether they hallucinate. Examples include prompting LLMs to predict confidence scores, utilizing token probabilities, or sampling answers with high temperature and examining self-consistency.

However, the performance of existing self-detection methods is limited as LLMs tend to be overconfident about their own outputs, and these methods become less effective after models are trained to be more aligned.

### Key Insight

A model is expected to provide correct and consistent answers regardless of how questions are verbalized. Therefore, if it responds drastically differently to different verbalizations, we consider the model does not know the question.

### Our Approach

We propose a novel self-detection method that includes:

1. Examining the divergence of the LLM's behaviors on different verbalized questions
2. Examining whether the verbalization of the question is typical in the LLM

### Contributions

- We show existing LLMs intermittently retain the verbalization-sensitive problem, generating drastically contradicting responses to semantically equivalent questions verbalized differently
- We introduce a self-detection suite that relies solely on an LLM itself, enabling lightweight detection of whether an LLM is unknown for a question
- We probe what an LLM knows and does not know, showing a correlation between the unknown to the popularity, the reasoning steps, and the formulations

## 2. Related Work

### Model Calibration

Calibration is a well-studied topic in traditional neural networks, aiming to provide a confidence score that aligns well with the true correctness likelihood. Studies show BERT, DistilBERT, T5, BART, GPT-2, and GPT-3.5 are not well-calibrated on language tasks.

Post-hoc methods like temperature scaling and feature-based fitting on development sets are widely used. Fine-tuning approaches have been explored for BERT, RoBERTa, T5, and Alpaca. However, calibration tuned for specific tasks makes it challenging to generalize on out-of-distribution data.

### Hallucination Detection

Recent work shows that LLMs may produce hallucinated contents, i.e., non-factual responses. Several approaches exist:

- Using LLMs to evaluate sampled answers (limited by overconfidence)
- Utilizing confidence scores like token probability
- Examining self-consistency among randomly sampled answers
- Cross-checking with verifier LLMs

Our proposal is self-detection without referring to any other LLMs or external resources.

## 3. Inconsistency and Atypicality in LLMs

We attribute the non-factuality of an LLM to the generative characteristics which sample the most possible tokens sequentially. Even if the LLM does not know the exact knowledge related to the question or does not understand the question, it still generates plausible responses.

Consequently, if an LLM returns contradicting responses to semantically equivalent questions, the LLM does not know the knowledge for the question. Besides, if the textual verbalization of a question is not representative in the LLM, i.e., atypical, it would be hard to understand resulting in a lower-quality response.

Our approach:

1. Examine the divergence between responses R = {r_1, ..., r_n} to a question set Q = {q_1, ..., q_n}, where any two questions q_i and q_j are semantically equivalent
2. Examine whether the verbalized question q is representative in the LLM using the atypicality A(q) of the input

## 4. Self-Detecting What LLMs Do Not Know

Our framework includes consistency-based detection and verbalization-based detection.

### 4.1 Consistency-based Detection

Given a question, we first diversify it to several questions, then examine the consistency among generated responses.

#### 4.1.1 Diversifying Question Verbalizations

We diversify question q to several textual verbalizations Q(q) = {q_1, ..., q_n} that express the same meaning.

**Model-based Generation**: For open QA questions, we exploit an LLM itself to generate paraphrased questions through the prompt:

> Given the following question [QUESTION], paraphrase it to have different words and expressions but is semantically equivalent.

After obtaining paraphrased questions, we filter out unsatisfied ones by prompting the language model to detect whether two questions are semantically equivalent.

**Rule-based Generation**: For commonsense reasoning and arithmetic reasoning questions, we use expert-defined rules:

- For commonsense reasoning: exchange the order of choices
- For arithmetic reasoning: substitute person names with new names

#### 4.1.2 Calculating Consistency Score

We examine consistency among generated responses R(q) = {r_1, ..., r_n} according to diversified questions Q(q) = {q_1, ..., q_n}. We employ greedy decoding to avoid unexpected randomness.

**Consistency Determination**: We examine whether any two answers are consistent I(r_i, r_j) in {0, 1}.

- For fixed format answers (multiple-choice): extract final answer using regular expressions and check exact match
- For free-form answers: use the LLM itself to detect inconsistency:

> Determine whether the answer 'A1' is 'Contradicted' or 'Same' with the answer 'A2' for the question 'Q'. Check whether the two answers exactly describe the same thing such as the same entity, digit, or arithmetical results.

**Consistency Calculation**: A common way of calculating the consistency score:

```
Consistency(R(q)) = (1/(n-1)) * sum_{r_i, r_i != r} I(r_i, r)
```

where r is the response for the original question q.

**Entropy-Based Detection**: We further compute divergence of the response distribution. We group responses into clusters and obtain a cluster distribution Omega = {omega_1, ..., omega_k}.

**Clustering Algorithm:**

```
Input: R(q), {I(r_i, r_j)}
Output: Omega = {omega_1, ..., omega_k}
Initialization: omega_1 = {r_o}, where r_o is randomly sampled from R(q)

For all r_j in R(q), r_j != r_o:
    Clustered = False
    For all omega_l in Omega:
        Randomly draw response r_i from omega_l
        If I(r_j, r_i) == 1:
            omega_l <- omega_l + r_i, Clustered = True
            Break
    If Clustered == False:
        omega_new = {r_j}, Omega <- Omega + omega_new
```

After clustering, calculate entropy:

```
Entropy(R(q)) = sum_l (N(omega_l)/n) * log(N(omega_l)/n)
```

where N(omega_l) is the number of responses in cluster omega_l. Higher entropy indicates greater randomness, corresponding to lower probability of correct answers.

### 4.2 Verbalization-based Detection

We compute the atypicality of the input. Current LLMs are autoregressive models that compute a marginal distribution P(x). We compute the negative log-likelihood of the verbalized input as the atypicality indicator:

```
A(q) = -log P(q) = -sum_t^T log P(x_t | X_{<t})
```

where x*t and X*{<t} indicate a token and a token set in question q. We add a normalized score A(q)/N(q), where N(q) is the number of tokens.

A higher value of A(q) indicates that the verbalization is more atypical for the language model.

Finally, we combine the two components to predict the final confidence score that the LLM does not know the question.

## 5. Experiments

### 5.1 Experimental Settings

**Datasets:**

- Factoid question answering: FaVIQ, ComQA
- Arithmetic reasoning: GSM-8K, SVAMP
- Commonsense reasoning: ARC-Challenge, CommonsenseQA

**Models:** ChatGPT (gpt-3.5-turbo), GPT-4, Vicuna-13B, Llama2-13B

**Evaluation Metrics:** PR AUC to measure whether predicting score correlates with nonfactual response.

**Baselines:**

1. TokenProbs: average of token probabilities as confidence score
2. Perplexity: reciprocal of normalized language model probability
3. ConsistAnswers: consistency of sampled answers using high temperature (0.7)
4. SelfCheckGPT: combines BERTScore and token-level probability

**Implementation:**

- Temperature 1.0 for paraphrasing (10 rephrasings per question)
- Temperature 0.0 for answer generation (greedy decoding)
- XGBoost to fit features: Consistency(R(q)), Entropy(R(q)), A(q), A(q)/N(q)

### 5.2 Overall Performance

**PR-AUC Results:**

| Method                          | ARC       | CSQA      | GSM-8K    | SVAMP     | FaVIQ     | ComQA     |
| ------------------------------- | --------- | --------- | --------- | --------- | --------- | --------- |
| **ChatGPT**                     |           |           |           |           |           |           |
| Random                          | 10.78     | 22.49     | 11.77     | 17.94     | 45.96     | 27.05     |
| ConsistAnswers                  | 14.24     | 25.96     | 52.71     | **30.50** | 57.09     | 31.76     |
| SelfCheckGPT                    | 23.60     | 39.38     | 21.14     | 25.68     | 52.26     | 39.56     |
| SelfDetection (w/o Atypicality) | **40.86** | **40.23** | **56.29** | 28.18     | **59.65** | **42.86** |
| **GPT-4**                       |           |           |           |           |           |           |
| Random                          | 6.29      | 9.71      | 6.91      | 7.13      | 37.67     | 23.02     |
| ConsistAnswers                  | 27.44     | 35.47     | 22.39     | **25.99** | 51.30     | 37.34     |
| SelfCheckGPT                    | 21.15     | 39.26     | 12.99     | 22.87     | 46.66     | 46.31     |
| SelfDetection (w/o Atypicality) | **36.45** | **42.71** | **36.83** | 24.78     | **56.26** | **58.95** |
| **Vicuna-13B**                  |           |           |           |           |           |           |
| Random                          | 35.45     | 51.15     | 35.94     | 54.92     | 31.56     | 35.32     |
| TokenProbs                      | 40.66     | 52.39     | 39.03     | 60.00     | 34.39     | 59.18     |
| Perplexity                      | 41.27     | 52.01     | 37.63     | 61.60     | 36.43     | 59.58     |
| ConsistAnswers                  | 42.69     | 54.13     | 43.97     | 63.28     | 24.44     | 50.84     |
| SelfCheckGPT                    | 40.43     | 54.52     | 36.49     | 60.35     | 18.81     | 26.52     |
| SelfDetection                   | **54.55** | **62.93** | **53.31** | **71.19** | **39.45** | **66.97** |
| **Llama2-13B**                  |           |           |           |           |           |           |
| Random                          | 64.27     | 58.93     | 34.25     | 57.43     | 31.44     | 37.27     |
| TokenProbs                      | 64.10     | 62.92     | 35.12     | 55.73     | 33.21     | 43.84     |
| Perplexity                      | 64.08     | 62.88     | 35.18     | 55.87     | 33.53     | 44.70     |
| ConsistAnswers                  | 71.17     | 61.79     | 47.43     | 63.84     | **59.16** | **65.34** |
| SelfCheckGPT                    | 69.59     | 60.95     | 33.77     | 59.79     | 40.69     | 41.23     |
| SelfDetection                   | **77.73** | **71.95** | **50.38** | **70.33** | 39.83     | 52.36     |

Self-detection mostly achieves best performance across datasets, validating effectiveness on different LLMs. Significant improvements shown for commonsense reasoning (ARC, CommonsenseQA).

### 5.3 Ablation Study

Performance drops when removing either atypicality or consistency, indicating effectiveness of each component. Performance drops greater when removing consistency compared to atypicality, revealing divergence between answers is more crucial.

Linear combination of components shows comparable performance to XGBoost-fitted version, indicating combination method is not vital.

### 5.4 Unknown Questions Study

Analysis of ChatGPT's unknown vs known questions:

**Knowledge Popularity**: LLM is prone to be ignorant of atypical knowledge.

| Question Type | Google Results | Bing Results |
| ------------- | -------------- | ------------ |
| Unknown       | 7,497k         | 1,255k       |
| Known         | 10,929k        | 2,647k       |

Unknown questions have significantly lower search results, suggesting LLM has poorer memorization of unpopular knowledge.

**Reasoning Steps**: Questions requiring more reasoning steps or containing different arithmetic operations simultaneously lead to confusion. Example:

> Tom's restaurant gets 6 reservations a night. They normally order 2 meals that cost $5 each and a $5 bottle of wine. How much do they make a week if they are open 2 days a week?

The model needs to calculate cost of reservation first, then cost per night and week.

**Distracting Formulations**: Built-in distracting elements cause unexpected errors.

| Question Type | Vicuna-13B NLL | Llama2-13B NLL |
| ------------- | -------------- | -------------- |
| Unknown       | 228.4          | 202.4          |
| Known         | 204.0          | 185.1          |

Unknown questions correlate with higher atypicality scores.

### 5.5 Impact of Diversified Questions

Testing with 10, 20, and 30 paraphrased questions shows slight improvement with more questions. Some unknown questions may be answered coincidentally correctly with fewer questions. For confident questions, model answers consistently even with more questions.

## 6. Conclusion

We propose a simple yet effective method to self-detect whether an LLM generates non-factual responses, without referring to external resources. Experiments on ChatGPT, GPT-4, Vicuna, and Llama 2 across three task types demonstrate effectiveness.

Key findings:

- The two proposed components can be combined with existing methods
- Question types LLMs struggle with include low popularity and distracting formulations
- Method is applicable for continually upgrading LLMs

## Limitations

- Diversity of verbalizations is constrained by LLM's abilities
- Cannot detect cases where model generates consistently but incorrectly (false negatives)
- Additional verifier LLMs or external knowledge could improve detection

## Appendix

### Prompts

**Paraphrase Instruction:**

> Given a question, paraphrase it to have different words and expressions but have the same meaning as the original question. Please note that you should not answer the question, but rather provide a re-phrased question.

**Filter Wrong Paraphrases:**

> Determine whether the paraphrased question describes the same thing as the original question, and give "Contradicted" if they are not the same otherwise give "Same" as the result.

### Unknown Question Ratios by Model

| Dataset | ChatGPT | GPT-4 | Vicuna | Llama 2 |
| ------- | ------- | ----- | ------ | ------- |
| ARC     | 0.10    | 0.05  | 0.57   | 0.36    |
| CSQA    | 0.19    | 0.13  | 0.47   | 0.34    |
| GSM8k   | 0.11    | 0.05  | 0.64   | 0.65    |
| SVAMP   | 0.15    | 0.07  | 0.44   | 0.43    |
| FaVIQ   | 0.43    | 0.32  | 0.67   | 0.67    |
| ComQA   | 0.30    | 0.27  | 0.44   | 0.42    |

GPT-4 performs best, followed by ChatGPT. Vicuna-13B and Llama2-13B perform similarly.

### Component Evaluation

**Paraphrase Precision:**

- Commonsense reasoning: 100% (option exchange only)
- Arithmetic reasoning: 99% (subject name exchange)
- OpenQA: 93-95% depending on model

**Clustering Precision:**

- Commonsense reasoning: 100%
- OpenQA: 81-90%
- Arithmetic reasoning: 88-93%

### Costs (USD per question)

| Method                  | QA      | CSQA   | Arithmetic |
| ----------------------- | ------- | ------ | ---------- |
| **ChatGPT**             |         |        |            |
| TokenProbs/Perplexity   | 0.00008 | 0.0002 | 0.00006    |
| SelfCheckGPT/ConsistAns | 0.002   | 0.004  | 0.0006     |
| SelfDetection           | 0.004   | 0.004  | 0.0006     |
| **GPT-4**               |         |        |            |
| TokenProbs/Perplexity   | 0.0024  | 0.0068 | 0.0014     |
| SelfCheckGPT/ConsistAns | 0.046   | 0.105  | 0.014      |
| SelfDetection           | 0.092   | 0.106  | 0.014      |

## References

Code available at: https://github.com/yukunZhao/Self-DETECTION
