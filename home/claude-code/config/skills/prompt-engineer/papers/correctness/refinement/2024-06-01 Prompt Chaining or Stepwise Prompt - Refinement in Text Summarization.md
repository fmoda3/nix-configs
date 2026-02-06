# Abstract

Large language models (LLMs) have demonstrated the capacity to improve summary quality by mirroring a human-like iterative process of critique and refinement starting from the initial draft. Two strategies are designed to perform this iterative process: _Prompt Chaining_ and _Stepwise Prompt_. Prompt chaining orchestrates the drafting, critiquing, and refining phases through a series of three discrete prompts, while Stepwise prompt integrates these phases within a single prompt. However, the relative effectiveness of the two methods has not been extensively studied. This paper is dedicated to examining and comparing these two methods in the context of text summarization to ascertain which method stands out as the most effective. Experimental results show that the prompt chaining method can produce a more favorable outcome. This might be because stepwise prompt might produce a simulated refinement process according to our various experiments. Since refinement is adaptable to diverse tasks, our conclusions have the potential to be extrapolated to other applications, thereby offering insights that may contribute to the broader development of LLMs.

# Introduction

Large language models (LLMs) can enhance the summary via iterative refinement [zhang-etal-2023-summit]. This is motivated by how humans refine their written text. The main idea contains three sequential steps: (1) **Drafting**: LLMs generate an initial summary; (2) **Critiquing**: LLMs provide critical feedback and helpful suggestions for its output; (3) **Refining**: LLMs use the feedback to refine the initial summary.

More generally, this refinement can be applied to various text generation tasks to improve the outcomes [madaan2023self; gou2023critic; selfee2023; akyurek-etal-2023-rl4f]. Moreover, the improved outcomes can also help train a more helpful and harmless model [huang2022large; bai2022constitutional; OpenAI_GPT4_2023; scheurer2023training]. Implementing this refinement process can be approached in two distinct methods: _Prompt Chaining_ and _Stepwise Prompt_. Prompt chaining undertakes drafting, critiquing, and refining phases through a sequence of three discrete prompts. It means that LLMs will run three times. Although LLMs can concentrate on solving one particular problem without being overwhelmed by the complexity of the multiple tasks, it is trivial and troublesome for humans to provide three comprehensive prompts. Conversely, stepwise prompt completes these three phases within a single generation. Stepwise prompt only needs a simple prompt to contain three sequential steps, but it is challenging for LLMs to generate a long and complex output. Currently, the effectiveness of these two methods remains underexplored in any text generation task.

In this short paper, we compare prompt chaining and stepwise prompt to find the better method for refinement in text summarization. Specifically, we conduct experiments on the dataset **InstruSum** [liu2023benchmarking] introduced to evaluate the capabilities of LLMs. It involves instruction controllable text summarization, which summarizes the article based on the specific requirement. We evaluate the quality of initial summaries, critiques, refined summaries to show the effect of prompt chaining and stepwise prompt. Experimental results indicate that the prompt chaining is better than stepwise prompt. Moreover, various experiments imply that **stepwise prompt might produce a simulated refinement process**, where LLMs intentionally produce errors only to subsequently correct them. Intuitively, this conclusion will work on other domains and further facilitate future research.

[IMAGE: prompts_vs.pdf - Prompt Chaining v.s. Stepwise Prompt]

# Related Works

Recent work has proved that refinement can significantly improve LLMs performance. Self-Refine [madaan2023self] uses LLMs for drafting outcomes, providing feedback, and refining initial generation. In a series of 7 varied tasks, ranging from dialogue response to mathematical reasoning, outputs created using the Self-Refine method are favored over those produced through one-step generation with the same LLM, as judged by human evaluators and automated metrics. Critic [gou2023critic] proposes to leverage external tools to critique generated text and refine the initial generation via evaluation feedback. SelFee [selfee2023] collects generations, feedback, and revised generations to finetune LLaMA models [touvron2023llama]. Akyurek et al. [akyurek-etal-2023-rl4f] propose to train a better critique model to help repair the model outputs. Zhang et al. [zhang-etal-2023-summit] introduce a refinement paradigm to enhance the faithfulness and controllability in text summarization. Moreover, the refined outcomes can also help train a more helpful and harmless model [huang2022large; bai2022constitutional; OpenAI_GPT4_2023; scheurer2023training].

# Prompts

Figure 1 illustrates the prompts of prompt chaining and stepwise prompt within the context of instruction controllable text summarization. Prompt chaining requires a human to segment the refinement process into three steps. Each step leverages the output from the preceding one. In contrast, stepwise prompt specifies the same three steps to be executed within a single operation. Therefore, they can generate the equivalent results, including: (1) **Draft Summary** is the initially generated summary. (2) **Critique** is the critical comment and the helpful suggestion. (3) **Refined Summary** stems from refining the draft summary based on the critique. Correspondingly, these outcomes are obtained from each step in prompt chaining or the sequential items in the prompt chaining outcome.

**Table: Summarization Benchmark Results**

| Models                  | Overall Win | Overall Tie | Overall Lose | Missing Win | Missing Tie | Missing Lose | Irrelevant Win | Irrelevant Tie | Irrelevant Lose | Length |
| ----------------------- | ----------- | ----------- | ------------ | ----------- | ----------- | ------------ | -------------- | -------------- | --------------- | ------ |
| Mixtral-stepwise-draft  | 12          | 29          | 59           | 13          | 35          | 52           | 8              | 33             | 59              | 111.19 |
| Mixtral-chaining-draft  | 18          | 27          | 55           | 19          | 41          | 40           | 11             | 46             | 43              | 119.63 |
| Mixtral-stepwise-refine | 19          | 25          | 56           | 20          | 30          | 50           | 11             | 29             | 60              | 124.35 |
| Mixtral-chaining-refine | 27          | 21          | 52           | 31          | 29          | 40           | 14             | 48             | 38              | 127.3  |
| gpt-3.5-stepwise-draft  | 10          | 14          | 76           | 8           | 30          | 62           | 5              | 37             | 58              | 86.58  |
| gpt-3.5-chaining-draft  | 12          | 22          | 66           | 13          | 28          | 59           | 7              | 37             | 56              | 94.76  |
| gpt-3.5-stepwise-refine | 12          | 13          | 75           | 14          | 17          | 69           | 2              | 27             | 71              | 85.79  |
| gpt-3.5-chaining-refine | 21          | 17          | 62           | 14          | 24          | 62           | 11             | 38             | 51              | 97.24  |
| gpt-4-stepwise-draft    | 34          | 40          | 26           | 27          | 53          | 20           | 16             | 60             | 24              | 125.73 |
| gpt-4-stepwise-refine   | 53          | 29          | 18           | 42          | 49          | 9            | 12             | 57             | 31              | 145.85 |
| gpt-4-chaining-refine   | **77**      | 14          | 9            | **57**      | 38          | 5            | **19**         | 39             | 42              | 174.35 |

# Experiments and Results

## Dataset

We conduct experiments on the dataset **InstruSum** [liu2023benchmarking], which is produced to evaluate the capabilities of LLMs to summarize the article based on the specific requirement. InstruSum contains 100 article-requirement pairs in total. The articles contain around 1000-1200 words, stemming from the BBC news website. Requirements for a summary are designed to reflect diverse information needs that readers may have at different stages of their reading journey. These requirements include (a) Informational requirement, which supplies pertinent details about the topic or subject being discussed within the articles; (b) Formatting requirement, which enhances the summary's structure, such as incorporating bullet lists, to improve its readability and facilitate quicker comprehension; (c) Meta requirement, which reflects a high-level overview of the article.

# Models and Metrics

Refinement can be powered by various LLMs. In this paper, we choose the newest versions of GPT-3.5 (`gpt-3.5-turbo-0125`) and GPT-4 (`gpt-4-0125-preview`) models from OpenAI to draft, critique, and refine the outcomes due to their strong instruction-following capabilities. We also explore the performance of a strong open-source LLM (Mixtral 8x7B [jiang2024mixtral]).

We use the LLMCompare as our evaluation protocol, which compares two candidate outputs and then selects the better one [zheng2023judging; wang2023pandalm]. This is because LLMCompare coupled with GPT-4 is the best evaluation protocol, as mentioned in [liu2023benchmarking]. The evaluation prompts are shown in Appendix.

We evaluate the generated summaries from the three quality dimensions as introduced in [liu2023benchmarking]: (1) **Overall Quality** measures the overall excellence of the summary following the summary requirements. (2) **Missing Information** assesses whether the summary omits any essential article details pertinent to the summary requirements. (3) **Irrelevant Information** examines whether the summary contains extraneous information that falls outside the scope of the summary requirements.

## Exp I: Summarization Benchmark

#### Setup

Consistent with the settings employed in previous research on automatic LLM benchmarking [dubois2023alpacafarm; zheng2023judging], we use GPT-4 (`gpt-4-0125-preview`) one-step outcomes as the baseline. We assess the performance of various methods through direct comparison with the baseline GPT-4 results. To mitigate the potential positional bias, the summary pairs are randomly shuffled before the evaluation. We perform the LLMCompare prompts via `gpt-4-0125-preview`.

#### Results

The table above shows the automatic benchmarking results. More win times or less lose times mean a stronger performance. Generally, the draft summary is enhanced via refinement, regardless of the methods used. Notably, the performance of `gpt-3.5-stepwise-refine` (and `Mixtral-stepwise-refine`) is comparable to that of `gpt-3.5-chaining-draft` (and `Mixtral-stepwise-draft`). It indicates that stepwise prompt might lead to a simulated refinement process in which LLMs intentionally produce errors only to subsequently correct them.

**Q1: Which is the better method of prompt chaining and stepwise prompt?**

Prompt chaining achieves the highest win times (77 out of 100), considerably outshining stepwise prompt in producing higher-quality summaries. Moreover, prompt chaining coupled with a better backbone model can lead to better performance by comparing the outcomes of GPT 3.5 and GPT-4.

**Q2: How does prompt chaining or stepwise prompt affect the initial outcome?**

Notably, summaries initially drafted using stepwise prompt frequently fall short in quality. This may be due to the anticipation that its outputs will subsequently undergo critique and refinement, potentially influencing the initial drafting process.

[IMAGE: Win rates of refined results from prompt chaining over stepwise prompt. The left-hand models are used to evaluate the refined outcome.]

## Exp II: Robustness

#### Setup

Based on the understanding that different models used for LLMCompare evaluation can yield varied results as indicated by [liu2023benchmarking], we employ two iterations of the GPT-4 model, `gpt-4-1106-preview` and `gpt-4-0125-preview`, to validate the stability and robustness of prompt chaining's superiority over stepwise prompt. We do not use the GPT-3.5 models for powering LLMCompare evaluations due to their observed lower consistency with human evaluators. Lastly, `average` reports the mean value of the two scores.

#### Results

Figure 2 shows the win rates between prompt chaining and stepwise prompt through refined results. The higher win rates of Overall suggest that prompt chaining more effectively adheres to the established summary requirements.

**Q3: Does prompt chaining stably outperform stepwise prompt?**

We observe that prompt chaining beats stepwise prompt in both Overall and Missing evaluation across different evaluation models. Meanwhile, prompt chaining exhibits comparable performance to stepwise prompt in Irrelevant. It can confirm the reliability of our conclusion that prompt chaining stably outperforms stepwise prompt.

**Table: Human Evaluation Results**

| Models  | Overall Win | Overall Tie | Overall Lose | Missing Win | Missing Tie | Missing Lose | Irrelevant Win | Irrelevant Tie | Irrelevant Lose |
| ------- | ----------- | ----------- | ------------ | ----------- | ----------- | ------------ | -------------- | -------------- | --------------- |
| GPT 3.5 | 16          | 5           | 9            | 15          | 7           | 8            | 6              | 20             | 4               |
| GPT 4   | 14          | 8           | 8            | 13          | 10          | 7            | 9              | 14             | 7               |
| Mixtral | 11          | 16          | 3            | 7           | 22          | 1            | 6              | 19             | 5               |

# Exp III: Human Evaluation

#### Setup

We engaged two postgraduate students to conduct human evaluation, wherein they compared the refined outcomes of Prompt Chaining against those of the Stepwise Prompt. If Prompt Chaining outperforms Stepwise Prompt, it is notated as a "Win". For this human evaluation, we randomly selected 30% data from InstruSum dataset. Similar to the automated evaluation, we also use "overall", "missing", "irrelevant" as the evaluation metrics.

#### Results

The table above presents the quality of critique. A higher score means a better performance. The "win" times significantly exceed the "lose" times. It indicates that prompt chaining outperforms stepwise prompt. This conclusion is consistent with GPT-4 automated evaluation. Additionally, we observe that there are fewer "lose" times when we apply the more advanced model, GPT-4. It may imply that Prompt Chaining significantly outperforms Stepwise Prompt when using advanced models.

# Exp IV: Critique Evaluation

#### Setup

We use MetaCritique [sun2024critique] powered by `gpt-4-0613` to evaluate the quality of critiques, which are the intermediate outputs of prompt chaining and stepwise prompt. MetaCritique involves three metrics: (1) **Precision** gauges the factuality of the critique; (2) **Recall** measures the comprehensiveness of the critique; (3) **F1 Score** harmonizes the precision score and recall score. We do not assess GPT-4 critiques, as MetaCritique uses GPT-4 outcomes as references.

#### Results

Table 1 presents the quality of critique. A higher score means a better performance.

**Q4: How does prompt chaining or stepwise prompt affect the critique generation?**

Stepwise prompt can generate high-quality critiques that are both more factual and comprehensive. However, in terms of F1 score, prompt chaining achieves only half of that of stepwise prompt, despite the superior performance in refined summaries. These results imply that stepwise prompt produces a simulated refinement process.

**Table 1: MetaCritique Scores**

| Models           | Precision | Recall | F1 Score |
| ---------------- | --------- | ------ | -------- |
| gpt-3.5-stepwise | 78.91     | 43.29  | 52.48    |
| gpt-3.5-chaining | 40.21     | 25.62  | 24.79    |

# Conclusion

LLMs can enhance summaries by emulating the human-like process of critique and refinement of their initial drafts. This paper explores two distinct strategies for implementing this process: _Prompt Chaining_ and _Stepwise Prompt_. We conduct rigorous experiments in the context of text summarization. Our findings indicate that prompt chaining garners a superior performance. Besides, the results imply that stepwise prompt might produce a simulated refinement process. Given that such refinement can be adapted to various tasks, our insights could extend beyond text summarization, potentially advancing the progress of LLMs.

# Limitations

Refinement can be applied to various natural language processing (NLP) tasks. However, this paper only compares prompt chaining and stepwise prompt in the scope of text summarization. Future research is warranted to validate the effectiveness of these strategies on an expansive range of NLP tasks, thereby enhancing the generalizability of our findings and their potential utility across the field.

# Ethical Considerations

Our experimental data stems from InstruSum, which is well-established and publicly available. Dataset construction and annotation are consistent with the intellectual property and privacy rights of the original authors. This work complies with the ACL Ethics Policy.

# Appendix: Prompts

We elaborate on the prompts for GPT-4 evaluation for LLMCompare Overall, LLMCompare Missing, and LLMCompare Irrelevant.

## LLMCompare Overall Prompt

**SYSTEM MESSAGE:**

You are a helpful assistant designed to output JSON.

In this task, you will be provided with a news article, a specific summary requirement, and two summaries. The summaries are crafted to meet a specific summary requirement. Note that there may be identical summaries.

Your task is to compare the overall quality of these two summaries concerning the summary requirement and pick the one that is better (there can be a tie).

First you will give an explanation of your decision then you will provide your decision in the format of 1 or 2 or tie.

Please refer to the example below for the format of your response.

Example Response:

```json
{
  "explanation": "Your explanation here",
  "decision": "1 or 2 or tie"
}
```

**USER MESSAGE:**

```
<article>
{article}

<requirement>
{requirement}

<summary 1>
{summary 1}

<summary 2>
{summary 2}
```

## LLMCompare Missing Prompt

**SYSTEM MESSAGE:**

You are a helpful assistant designed to output JSON.

In this task, you will be provided with a news article, a specific summary requirement, and two summaries. The summaries are crafted to meet a specific summary requirement. Note that there may be identical summaries.

Your task is to compare the quality of these two summaries concerning whether they omit any crucial information from the article with respect to the summary requirement and pick the one that is better (there can be a tie). Crucial information refers to key details or facts that are essential to understanding the article and meeting the summary requirement.

First you will give an explanation of your decision then you will provide your decision in the format of 1 or 2 or tie.

Please refer to the example below for the format of your response.

Example Response:

```json
{
  "explanation": "Your explanation here",
  "decision": "1 or 2 or tie"
}
```

**USER MESSAGE:**

```
<article>
{article}

<requirement>
{requirement}

<summary 1>
{summary 1}

<summary 2>
{summary 2}
```

## LLMCompare Irrelevant Prompt

**SYSTEM MESSAGE:**

You are a helpful assistant designed to output JSON.

In this task, you will be provided with a news article, a specific summary requirement, and two summaries. The summaries are crafted to meet a specific summary requirement. Note that there may be identical summaries.

Your task is to compare the quality of these two summaries concerning whether they include any information that is not relevant to the summary requirement and pick the one that is better (there can be a tie). First you will give an explanation of your decision then you will provide your decision in the format of 1 or 2 or tie.

Please refer to the example below for the format of your response.

Example Response:

```json
{
  "explanation": "Your explanation here",
  "decision": "1 or 2 or tie"
}
```

**USER MESSAGE:**

```
<article>
{article}

<requirement>
{requirement}

<summary 1>
{summary 1}

<summary 2>
{summary 2}
```

---

**Notes:**

- Prompt chaining is introduced at https://www.promptingguide.ai/techniques/prompt_chaining
- Stepwise prompt is similar to specifying the steps required to complete a task at https://platform.openai.com/docs/guides/prompt-engineering/tactic-specify-the-steps-required-to-complete-a-task
- Dataset source: https://www.bbc.com/news
- OpenAI models documentation: https://platform.openai.com/docs/models
- ACL Ethics Policy: https://www.aclweb.org/portal/content/acl-code-ethics
