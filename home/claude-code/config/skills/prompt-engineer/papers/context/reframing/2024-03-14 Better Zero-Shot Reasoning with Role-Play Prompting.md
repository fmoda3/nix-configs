# Better Zero-Shot Reasoning with Role-Play Prompting

**Authors:** Aobo Kong, Shiwan Zhao, Hao Chen, Qicheng Li, Yong Qin, Ruiqi Sun, Xin Zhou, Enzhi Wang, Xiaohang Dong

**Affiliations:** Nankai University, Independent Researcher, Lenovo Research

**arXiv:** 2308.07702

---

# Abstract

Modern large language models (LLMs) exhibit a remarkable capacity for role-playing, enabling them to embody not only human characters but also non-human entities. This versatility allows them to simulate complex human-like interactions and behaviors within various contexts, as well as to emulate specific objects or systems. While these capabilities have enhanced user engagement and introduced novel modes of interaction, the influence of role-playing on LLMs' reasoning abilities remains underexplored. In this study, we introduce a strategically designed role-play prompting methodology and assess its performance under the zero-shot setting across twelve diverse reasoning benchmarks. Our empirical results illustrate that role-play prompting consistently surpasses the standard zero-shot approach across most datasets. Notably, in experiments conducted using ChatGPT, accuracy on AQuA rises from 53.5% to 63.8%, and on Last Letter from 23.8% to 84.2%. Upon further comparison with the Zero-Shot-CoT technique, which prompts the model to "think step by step", our study demonstrates that role-play prompting acts as a more effective trigger for the CoT process. This highlights its potential to augment the reasoning capabilities of LLMs. We release our code at this [url](https://github.com/NKU-HLT/Role-Play-Prompting).

# Introduction

[IMAGE: Examples of ChatGPT with (a) zero-shot and (b) role-play prompting. The role-play prompts are highlighted.]

Recent years have witnessed a paradigm shift in natural language processing, largely driven by large language models (LLMs) such as GPT-3 [NEURIPS2020_1457c0d6], PaLM [chowdhery2022palm], and Llama [touvron2023llama]. By pretraining on vast textual corpora, these models have attained an impressive capacity for language understanding and generation, empowering them to address a variety of downstream tasks through prompting, thus bypassing the necessity for task-specific fine-tuning. Amidst the surge of prompt techniques, role-play [summarization] and chain-of-thought prompting [chain; zero_shot_cot] have garnered particular interest.

Modern LLMs, with their advanced role-playing capabilities, have significantly enriched user experiences and forged new modes of interaction. They can convincingly mimic various personas, ranging from fictional characters to historical and contemporary figures. The assigned role provides context about the LLM's identity and background. By adopting the persona, the LLM can generate more natural, in-character responses tailored to that role. Recognizing this potential, companies like Character.AI have developed dialogue agents portraying diverse figures. Beyond conversational applications, role-playing also boosts LLM performance on certain NLP tasks. For instance, when cast as a judge with a distinctive role, LLMs can effectively evaluate the quality of text summarization [summarization]. More unconventionally, ChatGPT demonstrates competency in processing Linux commands when prompted as a Linux terminal. Despite these advancements, analyzing the influence of role-playing on core LLM reasoning abilities warrants further investigation.

While the role-playing abilities of LLMs have expanded the horizon of human-computer interaction, the push to amplify the reasoning prowess of these models has led to the development of techniques like Chain-of-Thought (CoT) Prompting. CoT prompting was proposed by Wei et al. [chain] and involves providing reasoning steps in few-shot examples. By stimulating step-by-step reasoning, CoT prompting has markedly improved LLM reasoning abilities. Numerous subsequent studies [selfcon; zero_shot_cot; leasttomost] have built upon this approach. Inspired by the success of role-playing on many downstream tasks, we explore whether role-playing can similarly boost LLM reasoning performance. For example, could assigning ChatGPT the role of a math teacher enhance its ability to solve math problems? In this work, we introduce a zero-shot role-play prompting methodology based on a two-stage framework. During the first stage, we utilize the LLM to construct task-specific role-play prompts. In the second stage, responses are elicited for each reasoning query, guided by the previously constructed task-specific role-play prompts. We focus our study on conversational LLMs, evaluating our approach on 12 reasoning benchmarks using ChatGPT. Our results demonstrate consistent improvements over the zero-shot baseline on the majority of datasets, confirming the efficacy of role-play prompting. We further assess other conversational LLMs like Vicuna [vicuna2023] and Llama 2-Chat [llama-2], observing comparable gains.

Furthermore, we compare our method to the Zero-Shot-CoT technique [zero_shot_cot], which explicitly triggers CoT by appending *"Let's think step by step"* to questions. Modern conversational LLMs such as ChatGPT have undergone extensive supervised fine-tuning, enabling them to generate CoT for certain topics without the need for an explicit trigger. In tasks where the model struggles to generate CoT spontaneously, such as Last Letter, both our approach and Zero-Shot-CoT can stimulate CoT from scratch. However, for tasks where CoT already occurs, such as arithmetic, both our approach and Zero-Shot-CoT reinforce the step-by-step reasoning process, but Zero-Shot-CoT demonstrates no significant effect, whereas our approach leads to better performance. Hence, we posit that role-play prompting is an implicit CoT trigger and can generate a more effective CoT in some fields compared with Zero-Shot-CoT.

To the best of our knowledge, this work represents the first systematic investigation of role-play prompting for reasoning tasks. Despite the transformative effects of role-playing on LLM behavior, sparse academic research has explored this phenomenon. We believe our study serves as an inaugural step to catalyze more extensive exploration into this promising research direction.

Our main contributions are three-fold:

- We propose a novel role-play prompting methodology based on a two-stage framework to enhance the zero-shot reasoning capabilities of LLMs. To our knowledge, we are the first to improve LLM's reasoning abilities with role-play prompting.

- We thoroughly evaluate our method on 12 reasoning benchmarks, substantiating the efficacy of role-play prompting and providing insights into the prompt design.

- Based on our empirical results, we conclude that role-play prompting can serve as an effective implicit CoT trigger, explaining its enhancements in reasoning capabilities.

# Related Work

## Role-Playing Abilities of LLMs

The exceptional role-playing capabilities of large language models (LLMs) have recently garnered significant attention. LLMs have demonstrated remarkable versatility in seamlessly playing varied roles, whether as a well-informed, personalized travel advisor or a virtual Linux terminal. Numerous companies, such as Character.AI, have capitalized on this adept role-playing by launching commercial dialogue agents that take on diverse personas. While role-playing enables innovative avenues for user interaction, it has also been exploited to bypass certain restrictions imposed on LLMs, as evidenced by the infamous "grandma exploit". In this exploit, users prompted inappropriate responses from LLMs by casting it into the role of a deceased grandmother.

Despite the surging interest in LLMs, scholarly investigation into their role-playing capacities has been limited thus far. Han et al. [han-etal-2022-meet] build engaging conversation models based on role-playing. Wu et al. [summarization] propose an LLM-based summarization evaluation framework, utilizing role-playing to enable more comprehensive and human-like assessment. Shanahan et al. [shanahan2023role] propose that dialogue agents built on LLMs could serve as role simulators, and use role-play conversations to analyze the human-like capabilities of LLMs with the aim of refuting anthropomorphism. Our work is the first to apply the role-playing abilities of LLMs to reasoning tasks. We hope that our work will encourage more exploration related to role-playing with LLMs.

## Reasoning Abilities of LLMs

Initially, LLMs were deemed deficient in reasoning abilities due to their subpar performance in areas such as arithmetic, and common sense reasoning [NEURIPS2020_1457c0d6; rae2021scaling]. However, Wei et al. [chain] propose chain-of-thought prompting, where reasoning steps are provided in few-shot exemplars, leading to a substantial enhancement in reasoning capabilities of LLMs. We divide the follow-up work based on chain-of-thought into two categories, few-shot and zero-shot, and introduce them respectively.

### Few-shot

Self-consistency [selfcon] samples diverse reasoning paths instead of the naive greedy decoding and then selects the most consistent answer by majority vote. DIVERSE [diverse] adopts various few-shot exemplars to enhance the diversity in reasoning paths obtained by self-consistency. Least-to-most prompting [leasttomost] breaks down a complex problem into a series of simpler subproblems and then solves them in sequence. Self-refine [selfrefine] generates an output through chain-of-thought, and then utilizes the same LLM to improve the initial output through iterative feedback and refinement. Active prompting [activeprompt] borrows from active learning to select the most uncertain questions as few-shot exemplars. Tree-of-Thought [tot] represents possible reasoning paths as a tree structure and utilizes search algorithms like DFS or BFS to explore the correct reasoning branch.

### Zero-shot

Zero-Shot-CoT [zero_shot_cot] simply adds "Let's think step by step" after the question to stimulate chain-of-thought output in LLMs. Auto-CoT [auto_cot] and COSP [COSP] automatically build few-shot exemplars by selecting questions based on certain principles and obtaining their answers through Zero-Shot-CoT. Plan-and-Solve prompting [plan-and-solve] divides the original task into multiple sub-tasks and solves them sequentially under the zero-shot setting. In this paper, we propose a simple yet effective zero-shot approach based on role-play prompting with no need of constructing few-shot exemplars. Our approach outperforms Zero-Shot-CoT on most benchmarks and can serve as a new baseline for reasoning tasks.

# Role-Play Prompting

[IMAGE: The two-stage framework of our proposed role-play prompting. The role-play prompts are highlighted.]

[IMAGE: An illustration of the two-stage role-play prompting procedure, exemplified with the commonsense reasoning task. In stage 1, multiple role-feedback prompts are sampled. In stage 2, the optimal role-feedback prompt (underlined in blue) is selected for answer generation.]

The conventional practice of role-play prompting involves simply concatenating the role assignment with the reasoning question into a single prompt to query the LLM, forming a single-turn interaction. To further immerse the LLM within the designated role and potentially enhance its efficacy, we propose transitioning from this single-turn interaction to a two-round dialogue process. Specifically, the first dialogue round allows the model to elaborate on its assigned role, thereby deepening its framing and persona. The subsequent round then elicits the model's response to the posited reasoning query within that predefined role.

In the two-round dialogue process, the initial role elaboration of the model is instrumental for subsequent reasoning efficacy. Given the uncontrolled quality of this initial response, we sample multiple responses during the first round and pinpoint the optimal one to fix for all questions. By securing this optimal first-round response, we concatenate both the input and output of the first-round interaction with the reasoning question to produce a single prompt, facilitating tailored responses. This also offers the advantage of invoking the model's API a singular time per instance. In summary, our role-play prompting approach follows a two-stage process: first constructing an optimal role-immersion interaction per task, then eliciting responses to each reasoning question grounded in that established role.

## Prompt Construction

During the first stage, we formulate two prompts for each reasoning task:

- **Role-Setting Prompt:** This user-designed prompt delineates the specific role the LLM is expected to undertake throughout the dialogue, tailored to the task at hand.

- **Role-Feedback Prompt:** Intended as the model's acknowledgment to the role-setting prompt, this prompt aims to further anchor the model within the stipulated role. It is derived by sampling the model's responses.

In designing the role-setting prompt, it's imperative to select roles that naturally present a distinct advantage for the specific task at hand. Further enriching the prompt with additional descriptions that underscore this advantage often leads to improved results. Once the role-setting prompt has been articulated, it is presented to the LLM, which produces multiple sampled responses. From these, we choose the most representative and immersive reply that captures the essence of the intended role as the final role-feedback prompt. A comprehensive discussion on the nuances of the prompt design will be presented in Section 4.4.

## Question Answering

In the second stage, each question of the task, in conjunction with the role-setting and role-feedback prompts, is utilized as input to the model's API. This methodology facilitates answer generation with just a single API invocation. For clarity, we provide a code example of making an API call in Appendix 6.1.

# Experiments

## Tasks and Datasets

In line with prior research on the reasoning capabilities of LLMs [chain; zero_shot_cot], we evaluate our approach across 12 datasets spanning 4 categories: (1) arithmetic, including MultiArith [multiarith], GSM8K [gsm8k], AddSub [addsub], AQUA-RAT [aqua], SingleEq [singleeq], and SVAMP [svamp]; (2) commonsense reasoning, including CSQA [csqa] and StrategyQA [strategy]; (3) symbolic reasoning, including Last Letter Concatenation and Coin Flip [chain]; (4) other, including Date Understanding and Tracking Shuffled Objects from BIG-bench [srivastava2022beyond]. More details can be found in Appendix 8.

## Experimental Setup

### Model

We use ChatGPT (gpt-3.5-turbo-0613), the current strongest conversational model in addition to GPT-4, to conduct experiments.

### Prompt

Our approach involves the design of a role-setting prompt and a role-feedback prompt for a given task. The arithmetic task consists of six datasets, all utilizing the same prompts. Similarly, the common sense reasoning task comprises two datasets, also employing the same prompts. For other tasks, the prompts used are detailed in Table 1.

### Baselines

We choose the standard zero-shot prompting, Zero-Shot-CoT [zero_shot_cot], and Few-Shot-CoT [chain] as baselines. Following previous work [zero_shot_cot; auto_cot], we use greedy decoding for all the experiments by setting the temperature to ```latex $0$ ```, making the results deterministic. See more details in Appendix 6.3.

## Results and Analysis

Comprehensive evaluation results are presented in Table 2. The evaluation metric is accuracy.

### Comparison with Standard Zero-Shot

As shown in Table 2, our role-play prompting approach demonstrates superior performance, outperforming the zero-shot baseline in **10 out of 12** datasets, and achieving on par performance in the remaining 2 datasets (SingleEq and MultiArith). Considering the relative simplicity of the SingleEq and MultiArith datasets, it is plausible that the model's performance has approached a saturation point (exceed 97%), thereby presenting a significant challenge for our method to further enhance accuracy at such an elevated level. While achieving on par performance in these specific datasets, it is crucial to highlight the competitive nature of role-play prompting across a diverse array of more complex datasets. This strongly demonstrates the effectiveness of role-play prompting in an extensive range of application scenarios.

### Comparison with Zero-Shot-CoT

Zero-Shot-CoT appends *"Let's think step by step"* to the question to stimulate the chain of thought (CoT) in LLMs, making it a simple yet effective method to enhance the reasoning ability of LLMs. However, different from the earlier instructed LLMs [hlrf], the current conversational LLMs have undergone extensive supervised fine-tuning, which enables them to spontaneously generate CoT in some fields under the zero-shot setting. In this context, we conduct a comparative analysis of our role-play prompting approach with Zero-Shot-CoT. The experimental results, along with the model's ability to spontaneously generate CoT are presented in Table 2. Note that the direct output of answers or a slight reasoning process is not considered CoT. Overall, our approach outperforms Zero-Shot-CoT on **9 out of 12** datasets. In tasks (Letter, Coin, Object) where ChatGPT struggles to generate CoT spontaneously, both of them gain huge improvements. Through the case study, we find that role-play prompting also stimulates CoT in the model just like Zero-Shot-CoT. In more tasks where CoT already occurs, both our approach and Zero-Shot-CoT reinforce the step-by-step reasoning process. However, Zero-Shot-CoT demonstrates no significant effect while role-play prompting leads to better results. Therefore, we posit that role-play prompting serves as an implicit CoT trigger and can generate a more effective CoT.

### Comparison with Few-Shot-CoT

Though our role-play prompting approach is completely zero-shot, the improvement it brings is nearly on par with Few-Shot-CoT, even surpassing Few-Shot-CoT on **6 out of 12** datasets.

Following previous work [zero_shot_cot; plan-and-solve], we combine our approach and baselines with Self-Consistency to further prove the efficacy of role-play prompting. Related results and discussions are provided in Appendix 7.2.

## Impact of Prompt Design

[IMAGE: Accuracy comparison of Role-Play Prompting across different sizes of Llama 2-Chat models.]

### Prompt Structure

To determine the optimal prompt structure, we select AQuA dataset and assign the model the role of a math teacher. We then conduct ablation studies on this setup to systematically assess the impact of different design choices. We hypothesize that prompts which immerse the model deeper in its role will improve performance. Consequently, we design four groups of prompts with progressively increasing levels of immersion. Prompt 1 and 2 are designed as single-round dialogues, where we directly attach the question to the prompt and input it into the model to obtain the answer. Prompt 1 solely contains the role to be played, and it already achieves the result surpassing the zero-shot baseline. For Prompt 2, we further enhance immersion by adding complementary descriptions of the role and specifying relevant roles for the user. This enhancement further improve the performance. Prompt 3 and 4 are both designed as two-round dialogues, as described in the previous section. By allowing the model to respond to the given role setting, the immersion is further enhanced, leading to the best performance. We conduct the same experiments on Letter and Coin datasets, yielding consistent findings (see more details in Appendix 7.3). Therefore, we recommend using the two-round prompt structure with complementary descriptions to maximize the model's immersion, thereby unlocking the full reasoning potential of role-play prompting.

### Role Selection

To assess the impact of role selection, we test on the AQuA and SVAMP arithmetic datasets using two-round dialogue prompts. We design 8 varied roles, categorized as advantaged, irrelevant, or disadvantaged based on whether each role holds an advantage in the given task. Consistent with intuition, advantaged roles (1,2) undoubtedly achieve the best results, followed by irrelevant roles (3-6) (surprisingly, most of them outperform the zero-shot baseline even though they have no advantage on arithmetic tasks), and disadvantaged roles (7,8) achieve the worst results, underperforming the zero-shot baseline. Therefore, we recommend choosing a role that holds an advantage in the given task for role-play prompting.

## Experiments on More LLMs

To assess the generalization of our role-play prompting approach, we conduct additional experiments using several open-source conversational LLMs, including Llama 2-Chat [llama-2] and Vicuna [vicuna2023], on various datasets such as GSM8K, MultiArith, SVAMP, CSQA, and Letter. The prompts and the decoding strategy used are consistent with the previous ChatGPT experiments. The results indicate that role-play prompting also exceeds the zero-shot baseline in open-source conversational LLMs, demonstrating the good generalization ability of role-play prompting.

Furthermore, we examine the impact of model scale by testing the Llama 2-Chat series (7B, 13B, 70B) on GSM8K, MultiArith, and Letter datasets. All three model sizes achieve improved performance from role-play prompting. The consistent benefits across 7B to 70B parameters indicate efficacy independent of scale, within this range.

# Conclusion

In this paper, we have proposed a novel zero-shot role-play prompting methodology consisting of a two-stage framework, aimed at enhancing the reasoning capabilities of LLMs. Extensive evaluations across twelve widely-used benchmarks reveal that our approach outperforms both the standard zero-shot baseline and Zero-Shot-CoT on most of the datasets. These results highlight the potential of role-play prompting as an implicit and effective CoT trigger, leading to enhanced reasoning outcomes. Overall, this work lays the initial groundwork to motivate deeper investigation into the intersection of role-playing and reasoning within the LLM community, a promising research direction for developing reasoning skills.

# Limitations

The core of our role-play prompting approach lies in the design of the role-setting and role-feedback prompts. While we have manually designed and sampled some prompts, yielding superior results compared to the zero-shot baseline, this process is time-consuming and may not always guarantee optimal results. To address this limitation, future research could focus on enabling LLMs to autonomously choose appropriate roles and design prompts based on the given question. This approach could further extend the application of role-play prompting to a broader range of domains beyond reasoning.

# Appendix: Implementation Details

## Code for Calling ChatGPT's API

To help understand our approach of role-play prompting, we provide a code example of making an API call as follows:

```python
# A code example of making an API call
prompt_1 = role_setting_prompt
prompt_2 = role_feedback_prompt
conversation = [
    {"role": "user", "content": prompt_1},
    {"role": "assistant", "content": prompt_2},
    {"role": "user", "content": question}
]
answer = openai.ChatCompletion.create(
    model="gpt-3.5-turbo-0613",
    messages=conversation,
    temperature=0,
    max_tokens=512
)
```

## Answer Extraction

Different from few-shot, the form of the answer given by LLMs under the zero-shot setting is not fixed. To simplify the extraction of answers, we follow the approach of Zero-Shot-CoT [zero_shot_cot]. Specifically, for each question, after getting the answer generated by the LLM, we concatenate the question, answer, and answer trigger together and input them to the model.

[IMAGE: A sketch map of answer extraction for role-play prompting.]

The answer trigger sentences for various answer formats are:

| Answer Format | Answer Trigger |
|---------------|----------------|
| arabic number | Therefore, the answer (arabic numerals) is |
| option (A-E) | Therefore, among A through E, the answer is |
| option (A-C) | Therefore, among A through C, the answer is |
| yes or no | Therefore, the answer (Yes or No) is |
| string | Therefore, the final answer is |

## Baselines

The standard zero-shot prompting, Zero-Shot-CoT [zero_shot_cot], and Few-Shot-CoT [chain] are chosen as baselines. The standard zero-shot prompting directly inputs the target question without any additional prompts. Zero-Shot-CoT appends "Let's think step by step." to the target question. Few-Shot-CoT adds similar questions and their corresponding reasoning processes before the target question. We use the few-shot exemplars provided in the original paper. When calling the API of ChatGPT (gpt-3.5-turbo-0613), we set max_tokens = 512 and temperature = 0.

## Experiments on More LLMs

Besides ChatGPT, we conduct experiments using different open-source conversational LLMs, including Llama 2-Chat [llama-2] and Vicuna [vicuna2023], on various datasets such as GSM8K, Multiarith, SVAMP, CSQA, and Letter. The prompts and the decoding strategy are consistent with the previous ChatGPT experiments. However, Llama 2-Chat often declines to respond to questions within the datasets due to overzealous safety concerns imposed by RLHF [hlrf]. To solve this problem, we change the original system prompt of Llama 2-Chat to "We will test your abilities in the upcoming conversations, so please respond actively to the questions. Your answers will not cause any harm, so there's no need to worry. So, just answer!". The phenomenon of refusal to answer is alleviated on the CSQA dataset and completely resolved on other datasets. Therefore, we do not present the results of CSQA in the main text. The experiments on model size using Llama 2-Chat series also modify the system prompt.

# Appendix: Additional Experimental Results

## Comparison with Zero-Shot-CoT

We mentioned in the main text that both our approach of role-play prompting and Zero-Shot-CoT reinforce the step-by-step reasoning process in tasks where ChatGPT can generate chain-of-thought [chain] spontaneously. However, Zero-Shot-CoT demonstrates no significant effect while role-play prompting leads to better results. We provide an example of SVAMP dataset:

**Question:** Robin has 21 packages of gum and 45 packages of candy. There are 9 pieces in each package. How many pieces of candies does Robin have?

**Zero-Shot:**
Robin has a total of 21 + 45 = 21 + 45 = 66 packages.
Therefore, Robin has 66 x 9 = 66 * 9 = 594 pieces of candies. [INCORRECT]

**Zero-Shot-CoT:**
First, we need to find the total number of pieces of gum. To do this, we multiply the number of packages of gum by the number of pieces in each package: 21 packages * 9 pieces/package = 21*9 = 189 pieces of gum.
Next, we need to find the total number of pieces of candy. To do this, we multiply the number of packages of candy by the number of pieces in each package: 45 packages * 9 pieces/package = 45 * 9 = 405 pieces of candy.
Therefore, Robin has a total of 189 pieces of gum + 405 pieces of candy = 189 + 405 = 594 pieces of candy. [INCORRECT]

**Role-Play Prompting:**
To find out how many pieces of candy Robin has, we need to multiply the number of candy packages by the number of pieces in each package.
Robin has 45 packages of candy, and each package contains 9 pieces. So, we can calculate the total number of candy pieces as follows:
45 packages * 9 pieces per package = 405 pieces of candy.
Therefore, Robin has 405 pieces of candy. [CORRECT]

## Combination with Self-Consistency

Different from the naive greedy decoding, Self-Consistency (SC) [selfcon] samples diverse reasoning paths and selects the most consistent answer by majority vote. We combine our approach and baselines with SC across multiple datasets, including AQuA, CSQA, Letter, Object, and Coin (N = 10 and temperature = 0.7). With SC, role-play prompting still consistently outperforms zero-shot baseline, further proving the efficacy of our approach.

## Ablation Study on Letter, Coin Datasets

Besides AQuA, we also conduct experiments on Letter and Coin datasets to explore the optimal prompt structure of role-play prompting. Consistent with the main text, we design 4 groups of prompts with progressively increasing levels of immersion. The results also demonstrate the effectiveness of the two-round prompt structure with complementary descriptions which enhance the model's immersion.

## Exploration of Prompt Length Impact

From the results in the ablation studies, the improvement in accuracy may be attributed to the increase in prompt length. Therefore, we conduct additional experiments on Letter dataset. We replace the role-feedback prompt with generic responses of varying lengths that lack immersion.

Immersion of Prompt 1-4 all increase due to 2-round interaction so they surpass Prompt 0. And Prompt 1 outperforms Prompt 2-4 with longer lengths but lacking immersion. The results demonstrate that the improvement in performance is attributed to stronger immersion, rather than the increase in prompt length.

## Detailed Results of Model Scale Study

We examine the impact of model scale by testing the Llama 2-Chat series (7B, 13B, 70B) on GSM8K, MultiArith, and Letter datasets. The detailed experiment results (7B / 13B / 70B):

| Method | GSM8K | MultiArith | Letter |
|--------|-------|------------|--------|
| Zero-Shot | 24.0 / 37.1 / 53.9 | 63.5 / 75.3 / 86.0 | 0 / 9.8 / 18.8 |
| Role-Play Prompting | 29.4 / 40.7 / 58.9 | 75.7 / 79.8 / 90.2 | 0 / 17.6 / 25.8 |

# Appendix: Dataset Details

We briefly introduce 12 datasets spanning four categories below.

### Arithmetic

We use the following six datasets: MultiArith, GSM8K, AddSub, AQUA-RAT, SingleEq, and SVAMP. All questions in these datasets contain a scenario and require reasoning based on mathematical knowledge.

### Commonsense Reasoning

We utilize CSQA and StrategyQA. Both of them require reasoning based on prior common sense.

### Symbolic Reasoning

We employ Last Letter Concatenation and Coin Flip. Last Letter Concatenation requires concatenating the last letter of given words in order. Coin Flip gives a sequence of operations to flip a coin and asks for the final orientation of the coin. These two datasets are proposed by Wei et al. [chain] but they are not available. Kojima et al. [zero_shot_cot] have followed the approach of Wei et al. [chain] to create and release the datasets. We utilize this version for our experiments.

### Other Reasoning Tasks

We use Date Understanding and Tracking Shuffled Objects from BIG-bench. Date Understanding involves date calculations. Tracking Shuffled Objects gives a sequence of object exchange operations, asking for the final ownership of objects.

# Appendix: Prompts for Role Selection Study

To investigate the role selection's impact on role-play prompting, we design 8 different roles for our study:

1. **Advantaged roles:** Math teacher, Mathematician (best performance)
2. **Irrelevant roles:** Travel advisor, Chef, Musician, Writer (most still outperform zero-shot baseline)
3. **Disadvantaged roles:** Student who struggles with math, Person who dislikes numbers (worst performance, below zero-shot baseline)
