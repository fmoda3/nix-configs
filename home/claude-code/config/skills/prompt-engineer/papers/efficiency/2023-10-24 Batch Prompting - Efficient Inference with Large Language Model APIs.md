# Batch Prompting: Efficient Inference with Large Language Model APIs

**Authors:** Zhoujun Cheng (Shanghai Jiao Tong University), Jungo Kasai (University of Washington), Tao Yu (University of Hong Kong)

**arXiv:** 2301.08721

## Abstract

Performing inference on large volumes of samples with large language models (LLMs) can be computationally and financially costly in industry and real-world use. We propose batch prompting, a simple yet effective prompting approach that enables the LLM to run inference in batches, instead of one sample at a time. Our method reduces both token and time costs while retaining downstream performance. We theoretically demonstrate that under a few-shot in-context learning setting, the inference costs decrease almost inverse linearly with the number of samples in each batch. We extensively validate the effectiveness of batch prompting on ten datasets across commonsense QA, arithmetic reasoning, and NLI/NLU: batch prompting significantly (up to 5x with six samples in batch) reduces the LLM (Codex) inference token and time costs while achieving better or comparable performance. For state-of-the-art Chat-based LLMs, e.g., GPT-3.5 and GPT-4, we show the benefits of batch prompting also hold. Further analysis shows that the number of samples in each batch and the complexity of tasks affect its performance. Moreover, batch prompting can be applied across different reasoning methods using LLMs. Our code can be found at the site <https://github.com/xlang-ai/batch-prompting>.

## Introduction

[IMAGE: figure1_overview.pdf - Illustration of batch prompting compared with standard prompting. Batch prompting groups multiple samples in one batch (b = 2 in the figure) and lets the LLM generate multiple responses (highlighted in yellow) for the batch in inference.]

Large language models (LLMs) have shown their strong capabilities under zero/few-shot settings with in-context learning [gpt3; codex; palm; ouyang2022training]. Much recent work has made progress in in-context learning by eliciting reasoning steps [cot; wang2022self; khot2022decomposed; cheng2022binding; yao2022react], selecting representative in-context exemplars [liu2022makes; su2022selective; Agrawal2022IncontextES], and designing prompt templates [jiang2020can; bach2022promptsource; arora2022ask].

Using LLMs can be costly in terms of token and time usage, especially when large volumes of LLM calls are needed, such as benchmarking a large dataset or addressing a high volume of customer inquiries for businesses. For example, the widely-adopted OpenAI API service of LLMs requires about $40 and 8 hours to perform inference on 10K samples using gpt-3.5-turbo; and the expense significantly escalates when using gpt-4, exceeding a substantial $600. If the rate limits of maximum API requests per minute are also considered, the costs will be even higher, preventing users from building massive LLM applications.

We propose batch prompting, a simple yet effective approach for prompting LLMs, which allows the model to perform inference on multiple samples at once, instead of one sample at a time. This reduces token and time costs while still retaining downstream performance, *without* any change in APIs. As shown in Figure 1, standard prompting generates a response (answer) to one sample at a time, which takes N inference runs of an LLM for a test set of size N. For our batch prompting, on the other hand, an LLM generates responses to b samples in a single inference run and only takes N/b runs for the same N samples.

We first demonstrate theoretically that under the few-shot in-context learning setting, most tokens consumed during the API call are the few-shot exemplars, and only a small portion of token budgets are used for the particular inference sample(s) (Section 2). Therefore, increasing b in batch prompting reduces the token and time costs in an inverse linear fashion. We extensively validate the effectiveness of batch prompting on diverse downstream datasets across commonsense QA, arithmetics, and NLI/NLU using Codex, a strong variant of GPT-3 finetuned on code data (Section 3). We also test batch prompting on the state-of-the-art GPT-3.5 and GPT-4 models. Batch prompting significantly decreases the tokens and run time of using LLMs while achieving comparable or even better performance on all ten datasets.

In further analysis (Section 4), we find the number of samples in batch and the complexity of tasks affect its performance. Moreover, we show that batch prompting works well across different reasoning methods (*e.g.*, end-to-end, Chain-of-Thought, and code generation), suggesting that batch prompting is an efficient drop-in substitute for conventional prompting.

## Approach

[IMAGE: figure2 - Token and time costs per sample on three datasets for illustrations (other datasets show similar trends). Batch prompting significantly lowers both token and time costs as the number of samples in each batch increases.]

We first introduce batch prompting, an efficient alternative to standard prompting. We then compare the token and time costs of batch and standard prompting, demonstrating the efficiency of our method.

### Problem Setup

The conventional paradigm (*i.e.*, standard prompting in Figure 1) to prompt LLMs for in-context learning is as follows: K in-context few-shot exemplars with both a context (*e.g.*, question) and an output (*e.g.*, answer) are selected to build the input prompt, *one* test sample with context only is appended at the end of the prompt, and the LLM is used to generate the response for the test sample.

In this paper, we focus on a realistic scenario with N test samples in total, which is common when benchmarking on a dataset or handling a large volume of customer requests. In this case, it takes N separate calls of the LLM inference under the standard prompting paradigm.

### Batch Prompting

Batch prompting enables the LLM to generate responses for multiple samples in one batch in a *single* inference run, so that it reduces the LLM inference time from N to N/b, where b is the number of samples in one batch. Specifically, as shown in Figure 1, our prompt groups the K in-context exemplars into K/b batches with b exemplars each as demonstrations. In every batch, demonstration contexts are arranged in a specific order at the beginning, with their corresponding outputs placed in the same order afterwards. Then, b test sample contexts are grouped together at the end of the input prompt. In this way, the LLM learns from the in-context demonstrations and generates corresponding responses for the entire batch of test samples. We add a position identifier "[index]" within each batch to 1) assist the LLM with identifying the order correspondence of input contexts and generated responses and 2) ease the process of parsing the generated responses.

### Token Cost

The costs of one LLM call scale linearly with the number of *tokens*, including both the input *prompt tokens* (few-shot and instruction) and *generated tokens* (according to, for example, OpenAI's pricing). **Most tokens are consumed by the prompt tokens in standard prompting** because the number of prompt tokens is usually far more than the number of generated tokens so that the LLM can better learn from in-context exemplar. Thus, the larger the portion of tokens spent on generated tokens, the more economical the total cost is.

We define *token efficiency* eta as the portion of tokens spent on generated tokens in one LLM call. For standard prompting and batch prompting (the instruction tokens are omitted if any for brevity):

```latex
$$\begin{equation}
    \begin{aligned}
        \eta_{standard} = \frac{1}{K + 1} \\
        \eta_{batch} = \frac{b}{K + b}
    \end{aligned}
\end{equation}$$
```

When K >> 1 and b < K, eta_batch scales almost inverse linearly with b, and thus increasing b of batch prompting can greatly reduce token costs.

### Time Cost

Intuitively, batch prompting reduces the inference time by decreasing the number of API calls from N to N/b. Considering the Transformer [vaswani2017attention] decoding time, the cost will increase with b in batch prompting due to the generation of longer responses compared to standard prompting. We give a detailed derivation from Transformer architecture perspective in Appendix 8.

However, as most end-users are accustomed to and only have access to LLM API services, this part of time cost is marginal (observed in main experiments), relative to the overhead of API call and request rate limits per minute set by a company, such as OpenAI. Besides, cases may occur when network connections are unstable or slow, and the users seek to finish a task with as few LLM calls as possible.

Therefore, in practice, reducing the number of calls from N to N/b with batch prompting can essentially lower the time costs. Note that when the API call overhead and rate limits are no longer the major bottlenecks of time costs in the future, then the increased decoding time to generate longer sequences discussed in Appendix 8 cannot be overlooked, and the time reduction of batch prompting will not be as pronounced.

Since LLM infrastructure/services can change over time, the token cost comparison is more reliable and durable to measure than time costs.

## Experiments

We extensively evaluate batch prompting across ten diverse datasets. Our results suggest that batch prompting can achieve at most 5x token and time efficiency (with six samples in batches) improvement with similar or even better downstream performance.

### Datasets

We evaluate batch prompting on ten datasets across commonsense question answering, arithmetic reasoning, and natural language understanding/inference: CommonsenseQA [commonsenseqa], StrategyQA [strategyqa], GSM8K [gsm8k], SVAMP [svamp], AQuA [aqua], AddSub [addsub], MultiArith [multiarith], RTE [rte], MNLI [mnli], and SST-5 [sst-5]. For CommonsenseQA, AQuA, AddSub, MultiArith, and RTE, we evaluate the whole dev/test sets. For the other five datasets, we evaluate the first 300 test samples considering the costs of LLM APIs.

### Experimental Setups

We evaluate OpenAI Codex (code-davinci-002) as the LLM in our main experiments across ten datasets. Codex was provided for free when the paper was written, but the token consumption reduction is the same as the other LLMs, ensuring that the token costs in experiments are general. We also test the batch prompting performance on other state-of-the-art LLMs, including GPT-3(text-davinci-003), GPT-3.5 (gpt-3.5-turbo), and GPT-4 (gpt-4). For GPT-4, we test the first 100 samples for each dataset, considering the budget. The decoding temperature is set as 0. For each dataset, we manually select 12-shot samples from the training set as in-context exemplars, with Chain-of-Thought [cot CoT] reasoning steps in the answers (in Section 4.4, other reasoning methods beyond CoT are discussed). We choose 12 exemplars because 12 is the least common multiple of 2,3,4,6, and thus it is easy to analyze the effects of grouping them into batches of 2,3,4,6 samples in our ablation studies. More experimental details and full results are listed in Appendix 9.

### Main Results

Figure 8 compares the token and time costs of standard and batch prompting. As shown, batch prompting substantially (up to 5x with 6 samples in each batch) reduces both the token and time costs of standard prompting with Codex. Further, the decrease of costs scales almost inverse linearly with the number of samples in each batch, verifying our analysis in Sections 2.3 and 2.4. Note the time costs include the API call overhead and rate limit blocks, which exist in the commonly-used OpenAI and other LLM services. For LLM services where these are not bottlenecks of time, the decoding time increase from larger b should not be overlooked as discussed in Section 2.4. As the LLM infrastructure can change anytime, the token efficiency improvement is easier to compare than time; the token reduction in Figure 8 should hold for any LLM over time.

Table 1 shows that batch prompting (with the best b, *i.e.*, the number of samples in each batch) performs comparably or even better than standard prompting over all ten datasets. We thus recommend that LLM users consider applying batch prompting to save money and time while maintaining good performance in realistic applications.

### Results across More LLMs

We experiment batch prompting with some other state-of-the-art LLMs, including GPT-3, GPT-3.5 (ChatGPT) and GPT-4.

Table 2 shows performance from these LLMs. All tested LLMs demonstrate capabilities similar to Codex: batch prompting retains downstream performance across datasets. Actually, batch prompting Chat-based models tend to gain performance improvements. We deduce the reason is that GPT-3.5 and GPT-4 accept a specific role of *system message* as instruction, which makes them better follow batch prompting instructions to input and output in batches. As discussed in Section 2, the token efficiency of batch prompting should hold for different LLMs, though the decrease in time may vary depending on the LLM inference implementation.

## Analysis

In this section, we assess factors influencing batch prompting performance and the tradeoff between costs and performance. We also demonstrate that batch prompting can be applied to various LLM prompting methods, such as end-to-end and code generation.

### Number of Batch Samples

[IMAGE: figure3_number_of_samples_in_batch.png - Accuracy over varying numbers of batch samples b on five datasets using batch prompting. The performance decreases with larger b.]

Figure 9 illustrates the impact of the number of samples per batch, b, on batch prompting performance. Performance typically decreases as b increases, with a significant drop at b=6 across four out of five datasets. However, the optimal performance isn't always at b=2. Selecting b=3 or b=4 often yields good performance while conserving more tokens and time. The time/token cost reductions diminish as b grows, suggesting b<6 (given 12 in-context examples in experiments) as a good balance between costs and performance.

### Selection of Batch Samples

Here we examine whether the selection of samples, *i.e.* how samples are grouped into batches, will affect the performance of batch prompting. We study two widely-adopted sample selection methods in in-context learning when grouping the test samples: grouping more similar [rubin2021learning; liu2022makes] and more diverse [su2022selective; Agrawal2022IncontextES] samples into batches. Specifically, given N test samples, to group similar ones, we use *k-means clustering* and post-process each cluster into equal size b by moving redundant samples to their closest groups with size <b. To group diverse ones, we apply the *vote-k* method [su2022selective] to iteratively select diverse and representative groups of samples.

As listed in Table 3, both similarity and diversity-based selections do not show improvements over random grouping. We suspect that the reason may be that both methods assume in-batch samples can benefit from previous similar or diverse samples, *i.e.*, samples in the front of the batch. However, these earlier samples without ground truth outputs may bring error propagation to the rest of the in-batch samples. Developing effective strategies for selecting samples for batch prompting could be a promising area for future research to further enhance the performance of batch prompting.

### Complexity of Tasks

[IMAGE: figure4_complexity_of_tasks.png - Accuracy on WikiTQ of various table input strategies and b (the number of samples in each batch). This studies how the input length affects batch prompting performance. b = 1 means standard prompting. Average input tokens per table are 24, 58, and 216 tokens. As the number of batch samples increases, batch prompting suffers in downstream performance.]

In Table 1, the steepest drop (from 46.1 to 42.1) occurs on AQuA dataset: an arithmetic reasoning task in a multi-choice QA format. One possible interpretation is that AQuA is more difficult than other datasets with the lowest absolute accuracy 46.1%, and thus LLMs are more likely to be disturbed when input contexts are grouped together.

We further study another task aspect that may affect performance: batch prompting tends to degrade performance more significantly with longer input contexts. We validate our assumption with WikiTQ [pasupat2015compositional], a challenging Table QA dataset. Tables contain longer input tokens for their multiple rows and columns. We experiment with increasing table input lengths: a simplified table schema (*i.e.*, column names without column types; avg. 24 tokens/table), a table schema (avg. 58 tokens/table), and a table schema with three table rows (avg. 216 tokens/table).

As shown in Figure 10, in standard prompting (b=1), inputting table schemas with three rows dominates QA performance. However, it also sees the steepest performance drop when b increases using batch prompting. The shorter the input contexts, the steadier the performance with batch prompting. This suggests that long task inputs are more likely to lead to confusion and performance drops when batch prompting is applied.

### Reasoning Methods

In our main experiments (Section 3), we used the Chain-of-Thought (CoT) for all ten datasets. Here we examine whether batch prompting is suitable for other common LLM reasoning methods. We experiment with two more reasoning methods: end-to-end (*i.e.*, directly prompt the LLM to output the answers without intermediate steps) and program-based, (*i.e.*, prompt the LLM to generate programs to answer the question). For the program-based methods, we adopt Binder [cheng2022binding] on WikiTQ and Program-of-Thought [chen2022program PoT] on GSM8K and SVAMP.

As seen in Table 4, both end-to-end and program-based methods can benefit from the efficiency of batch prompting while maintaining similar or even better performance on the task. This indicates batch prompting is a drop-in replacement that can be combined with various reasoning methods under diverse scenarios.

## Related Work

**Improve In-Context Learning.** The impressive capabilities of large language models [gpt3; codex; palm LLM] have sparked a surge of recent research aiming to enhance in-context learning (ICL) performance. Several works propose different reasoning methods to prompt LLMs [cot; zhou2022least; khot2022decomposed], showing great improvements over directly prompting LLMs to output answers. Other works [chen2022program; gao2022pal; cheng2022binding] generate programs to solve reasoning tasks. Another line of work [liu2022makes; su2022selective; Agrawal2022IncontextES] focuses on selecting better in-context exemplars. This work adds a new dimension to ICL for large-scale real-world applications: batch prompting to save budget and time while achieving good or even better performance.

**Efficient Language Generation.** Much recent work proposed methods for efficient language generation, including machine translation [Kasai2020ParallelMT; deepshallow; kasai2021t2r] and language modeling [katharopoulos-et-al-2020; peng2021rfa; peng2021abc], and model cascading [varshney2022model]. Many of them introduce alternative architectures to the standard transformer to achieve such efficiency gains, which makes them hard to apply or deploy to real-world scenarios. Our method is a simple yet effective alternative to recent prompting methods, and thus it is applicable to any off-the-shelf language model APIs, such as OpenAI, Google, Anthropic, or any other available private LLM APIs, *without* any additional training or customized model hosting.

## Limitation

Batch prompting has proven to be an efficient method for time and token reduction. Nonetheless, there are several critical considerations to keep in mind when implementing it across various scenarios. **First, to optimize its benefits, the length of the input prompt tokens should be (significantly) greater than that of the output tokens.** Thus, it might not be suitable for "heavy output" tasks like story generation. It is important to note that while our experiments are conducted with few-shot in-context learning, this method is also applicable to the instruction-following paradigm, either on its own or in combination, by simply substituting or adding the few-shot inputs with instructions. The only crucial factor is the length of the shared input tokens of inference samples. **Secondly, it is possible to observe performance declines.** Our experiments indicate that task complexity and lengthy input contexts can negatively impact performance. Although we have not identified a definitive guideline for predicting performance, we advise users to initiate testing with a smaller subset to gauge the effectiveness of batch prompting before implementing it on a larger scale.

## Conclusion

We present batch prompting, a new way to prompt LLMs that performs inference on samples in a batched fashion. With batch prompting, multiple samples can be handled in one API call so that the costs of tokens and time can be significantly reduced. Extensive experiments on ten datasets across commonsense QA, arithmetics, and NLI/NLU show that batch prompting can achieve better or similar performance compared to standard prompting, with much lower token and time costs. We hope batch prompting offers pragmatic value to efficient real-world LLM usage.

## Appendix A: Time Cost Analysis Regarding Transformer Architecture

In batch prompting, assume there are K in-context exemplars (C tokens per sample on average), b samples in a batch to be inference. Standard prompting is a special case where b=1. Since most current LLMs (*e.g.*, GPT-3, Codex, PaLM) are based on the Transformer decoder-only architecture, we focus on the time cost of the auto-regressive decoder.

The plain transformer time complexity for decoding one token is O(n^2 d), *i.e.*, the time for encoding the embeddings of input tokens, where n is the length of input tokens and d is the dimension of embeddings. With the caching of previous tokens, the time complexity to decode each of the rest tokens is O(nd). We omit d since it is a constant. Thus, the time of one inference to decode C*b tokens:

```latex
$$\begin{equation}
    \begin{aligned}
        T_{encode} &= (CK)^2\\
        T_{decode} &= (CK+1) + \dots (CK+Cb) \\
        T &= T_{encode} + T_{decode}
    \end{aligned}
\end{equation}$$
```

where T_encode is the time for encoding the input tokens in the decoder, and T_decode is the time for decoding the rest tokens. C can be seen as a constant. One inference time T regarding K and b is:

```latex
$$\begin{equation}
    \begin{aligned}
        T &= C^2K^2 + Cb\cdot CK + \frac{Cb(Cb+1)}{2} \\
          &= C^2(K^2+bK+\frac{b^2}{2}) + \frac{Cb}{2}
    \end{aligned}
\end{equation}$$
```

Thus, increasing b in batch prompting will also increase the time cost of one inference. The influence of b also increases with its value and is relatively marginal when b is small, especially when b << K, which is a common practice (b=1) in few-shot in-context learning.

We can see a few examples by setting K=12 (as in experiments), C=100 with varying b in Table 5 according to the equation above.

Though the numbers are not accurate considering the constant coefficients of Big O time complexity, we can learn the decoding time increase can not be overlooked as b becomes large. We do not emphasize this part in Section 2.4 because the overhead and rate limit blocking time of the OpenAI API make up the most proportion of time cost, and thus reducing the N times of API calls to N/b times almost inverse linearly reduce the time cost (see Figure 8).

However, if the overhead and rate limits are no longer the bottlenecks, *e.g.*, rate limits are strict for Codex (code-davinci-002), GPT-3.5 (gpt-3.5-turbo) and GPT-4 (gpt-4) but not a big issue to GPT-3 (text-davinci-003), then the decoding time increase will be non-negligible.

## Appendix B: More Experimental Results

We list results for all experiments (Tables 6-10). For the WikiTQ experiment with Binder, the LLM generation temperature is 0.4 following its paper. For the other experiments, the temperature is 0. For all experiments, top_p = 1, sampling_n = 1, logprobs = 1, and stop_tokens = \n\n. Five OpenAI keys are used as a polling pool on rotation to request the OpenAI API of Codex (the rate limit errors still occur in the experiments and are counted into time cost since it is a practical issue). If fewer OpenAI keys are used, there should be more rate limit errors because the request interval for one key will be shorter.

## Appendix C: Prompts

In this section, we list the prompt templates used for each dataset (Tables 11-19). We follow CoT [cot] to build the prompts of CommonsenseQA, StrategyQA, GSM8K, SVAMP, AQuA, AddSub, MutliArith. We follow Binder [cheng2022binding] and Program-of-Thought [chen2022program] to build the prompts of WikiTQ, GSM8K (program), and SVAMP (program). For RTE, MNLI, SST-5, we design the prompts ourselves using Chain-of-Thought. For prompts with fewer than 12 in-context exemplars, we manually add to 12 samples using samples from the training set. We show batch prompting prompts with b=4 as examples. For different b, we group the same 12 samples according to b. When using ChatGPT in Section 3.4, the prompt format differs from Codex and GPT-3 because its conversational capability. See Table 20.
