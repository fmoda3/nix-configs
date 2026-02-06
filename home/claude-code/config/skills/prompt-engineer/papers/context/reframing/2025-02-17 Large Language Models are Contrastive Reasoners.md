# Abstract {#abstract .unnumbered}

Prompting methods play a crucial role in enhancing the capabilities of pre-trained large language models (LLMs). We explore how contrastive prompting (CP) significantly improves the ability of large language models to perform complex reasoning. We demonstrate that LLMs are decent contrastive reasoners by simply adding "Let's give a correct and a wrong answer." before LLMs provide answers. Experiments on various large language models show that zero-shot contrastive prompting improves the performance of standard zero-shot prompting on a range of arithmetic, commonsense, and symbolic reasoning tasks without any hand-crafted few-shot examples, such as increasing the accuracy on GSM8K from `$35.9\%$` to `$88.8\%$` and AQUA-RAT from `$41.3\%$` to `$62.2\%$` with the state-of-the-art GPT-4 model. Our method not only surpasses zero-shot CoT and few-shot CoT in most arithmetic and commonsense reasoning tasks but also can seamlessly integrate with existing prompting methods, resulting in improved or comparable results when compared to state-of-the-art methods. Our code is available at the following GitHub repository: <https://github.com/yao8839836/cp>.

# Introduction

Recent studies [zhao2023survey; @brown2020language; @openai2023gpt4] have shown that large language models (LLMs) exhibit impressive performance across a wide range of tasks. In particular, the chain-of-thought (CoT) prompting technique has demonstrated the capability of LLMs to handle complex tasks, including math problem solving, by guiding them to generate intermediate reasoning steps [wei2022chain; @kojima2022large; @zhang2023automatic]. These studies spotlight the significance of developing efficient techniques to direct LLMs in their reasoning processes [liu2023pre; @amatriain2024prompt; @chia2023contrastive; @yasunaga2023large].

Nevertheless, the current chain-of-thought (CoT) paradigm encounters two main challenges: offering _correct_ guidance or examples of reasoning and reducing the reliance on manual labeling. In particular, Zero-shot-CoT [kojima2022large] provides general reasoning guidance by providing instructions like "Think step by step.", but the generated reasoning steps may not be correct and adequate for tasks such as commonsense question-answering (Table [\[table:five_runs\]](#table:five_runs){reference-type="ref" reference="table:five_runs"} and [\[tab:answer_extract_csqa_208st\]](#tab:answer_extract_csqa_208st){reference-type="ref" reference="tab:answer_extract_csqa_208st"}). On the other hand, Few-shot-CoT [wei2022chain] offers more detailed guidance but necessitates labeled examples of the reasoning process, which can be expensive to obtain for each task. This raises an important research question: Is it possible to generate a more accurate reasoning process without relying on human labeling?

In this work, we introduce **contrastive prompting**, a novel prompting approach that automatically directs the reasoning process of large language models. Our inspiration stems from how humans can learn from both their correct and incorrect actions [roediger2009getting]. For instance, when confronted with a math problem (as in Figure [1](#fig:zero_shot_cp){reference-type="ref" reference="fig:zero_shot_cp"}), people may ask \"How can we prevent mistakes in each step?\" By identifying the steps that are prone to mistakes on their own, they can enhance their ability to avoid mistakes and provide accurate solutions. Our idea is to prompt LLMs to emulate this reasoning process, enabling them to effectively solve new problems.

[IMAGE: fig:zero_shot_cp - Example inputs and outputs of GPT-4 with (a) standard Zero-shot, and (b) ours (Zero-shot-CP). In con...]

Specifically, when presented with a problem to solve, we instruct LLMs to generate both correct and incorrect answers within the given context. To achieve this, we provide prompts such as \"Let's give a correct and a wrong answer.\" Following this, we verify and confirm the correct answer. Our proposed approach offers multiple advantages. It not only generates incorrect answers autonomously but also places a greater emphasis on ensuring the accuracy of the answers. This eliminates the need for manually labeling reasoning examples for each task and problem, effectively addressing the challenges faced by CoT.

We evaluate the proposed approach across various reasoning-intensive tasks, including arithmetic reasoning, commonsense reasoning, symbolic reasoning, and other logical reasoning tasks. We employ two state-of-the-art base LLMs GPT-3.5 and GPT-4 [openai2023gpt4] and four popular open source LLMs. The experimental findings demonstrate significant improvements in scores compared to the zero-shot baseline across all datasets. Moreover, our method not only surpasses Zero-shot-CoT and Few-shot-CoT in most arithmetic and commonsense reasoning tasks but also achieves better results when combined with zero-shot or few-shot CoT, approaching or even surpassing the performance of existing state-of-the-art methods. These results indicate the effectiveness of generating incorrect answers for individual problems to guide the reasoning process of LLMs.

[IMAGE: fig:2steps - The complete process of Zero-shot-CP involves two steps: Firstly, we utilize the initial "reasoning"...]

# Related Works {#related_work}

#### Large language models and prompting

Recently, LLMs [zhao2023survey] like ChatGPT and GPT-4 [openai2023gpt4] have gained significant attention. Researchers find that scaling pre-trained language models often leads to an improved model capacity on downstream tasks. These large-sized models show different behaviors from smaller models and display surprising abilities in solving a series of complex tasks.

Prompt engineering is an emerging field dedicated to the development and optimization of prompts, enabling efficient utilization of LLMs across diverse applications and research domains [amatriain2024prompt; @sahoo2024systematic]. Zero-shot prompting involves querying the LLM without any examples while few-shot prompting provides models with a few input-output examples [brown2020language]. Chain-of-thought (CoT) [wei2022chain; @kojima2022large] prompting enables complex reasoning capabilities through intermediate reasoning steps. Despite its success, Few-shot-CoT [wei2022chain] needs human-labeled reasoning steps for each example, while Zero-shot-CoT [kojima2022large] may generate incorrect reasoning steps (especially for commonsense and arithmetic reasoning). Several X-of-thought approaches [yao2024tree; @yao2023beyond; @gao2023pal; @chen2022program] extend CoT on reasoning tasks, where X can be a tree, a graph, or a program. Auto-CoT [zhang2023automatic] improves Zero-shot-CoT by providing similar questions as few-shot examples for the target question. Self-consistency [wang2022self] sample multiple, diverse reasoning paths through Few-shot-CoT, and use the generations to select the most consistent answer. Analogical prompting [yasunaga2023large] leverages LLMs to automatically generate relevant few-shot examples for each question. In contrast to these works, our method emphasizes eliciting self-awareness in LLMs regarding potential errors and actively avoiding them.

#### Learning from Negative Examples

Contrastive learning, a widely adopted technique in deep learning, aims to enhance the quality of learned representations by training models to differentiate between \"positive\" and \"negative\" samples [jaiswal2020survey]. In the LLMs area, reinforcement learning from human feedback (RLHF) [ouyang2022training] and direct preference optimization (DPO) [rafailov2024direct] fine-tune LLMs with relative human judgments of response quality. Self-reflection [shinn2024reflexion; @kim2024language; @madaan2024self; @zhang2024context] incorporates \"critic\" or review steps to identify errors made by the LLM itself and improve upon them. However, it is important to note that the initial output of the LLM may not contain any errors, and there is a potential risk of the model reinforcing its own errors if it inaccurately evaluates the quality of its responses or generates invalid principles. The closest work to ours is the Contrastive CoT [chia2023contrastive] that extends Few-shot-CoT by creating wrong reasoning processes from annotated correct reasoning steps. The main distinction is that the erroneous answers generated by Contrastive CoT still require human-annotated examples, and the random reordering of entities during the reasoning process may not align with the patterns of errors made by LLMs themselves. On the contrary, our approach enables LLMs to generate erroneous answers on their own, which aligns better with their intrinsic knowledge. It does not require human annotation.

# Contrastive Prompting {#method}

We propose Contrastive Prompting (CP), a template-based prompting approach for contrastive reasoning. Our method can seamlessly integrate with any prompting technique by incorporating a trigger sentence before the LLM provides answers. In the following, we first illustrate our method using Zero-shot-CP as an example, which only uses the original question without supporting examples. Next, we will discuss how to combine our method with other prompting techniques.

## Two-stage prompting

Although Zero-shot-CP is straightforward in concept, it utilizes prompting twice to extract both reasoning and answer, as illustrated in Figure [2](#fig:2steps){reference-type="ref" reference="fig:2steps"}.

#### 1st prompt: reasoning extraction

In this step we begin by transforming the input question `$\mathbf{x}$` into a prompt `$\mathbf{x'}$` using a simple template "Q: \[X\]. A: \[T\]". Here \[X\] represents the input slot for `$\mathbf{x}$` and \[T\] represents a slot for a manually crafted trigger sentence `$\mathbf{t}$` that would extract the reasoning process to answer the question `$\mathbf{x}$`. For instance, if we use "Let's give a correct and a wrong answer." as a trigger sentence, the prompt `$\mathbf{x'}$` would be "Q: \[X\]. A: Let's give a correct and a wrong answer.". Additional trigger examples can be found in Table [\[table:templates\]](#table:templates){reference-type="ref" reference="table:templates"}. Prompted text `$\mathbf{x'}$` is then inputted into a LLM, which generates the subsequent sentence `$\mathbf{z}$`.

#### 2nd prompt: answer extraction

In the second step, we utilize the generated sentence `$\mathbf{z}$` in conjunction with the prompted sentence `$\mathbf{x'}$` to extract the ultimate answer from the LLM. To provide a more specific explanation, we combine three elements by concatenating them as \"\[X'\] \[Z\] \[A\]\". Here, \[X'\] represents the 1st prompt `$\mathbf{x'}$`, \[Z\] represents the sentence `$\mathbf{z}$` generated in the first step, and \[A\] represents a trigger sentence used to extract the answer. The prompt for this step is self-augmented, meaning that it includes the sentence `$\mathbf{z}$` generated by the same LLM. During the experiment, we employed slightly different answer triggers based on the format of the answer. Please refer to Appendix [7.2](#appendix:answer_extract){reference-type="ref" reference="appendix:answer_extract"} for the answer trigger sentences we used in each task. Subsequently, the prompted text is inputted into the LLM to generate sentences `$\mathbf{y}$` and extract the final answer.

## Integrating with other prompting methods

We can easily integrate our CP with any advanced prompting methods. We name the combined method X-CP, where X can be Zero-shot-CoT, Few-shot-CoT, or any other method. X-CP also has two steps: reasoning extraction and answer extraction. For Zero-shot-CoT-CP, the only distinction is we replace the trigger sentence "Let's give a correct and a wrong answer." with "Let's think step by step and give both a correct answer and a wrong answer.". For Few-shot-CoT-CP, the distinction is that `$k$` few-shot examples with reasoning steps are added before "Q: \[X\]. A: Let's give a correct and a wrong answer.", the resulting prompt `$\mathbf{x'}$` will be "Q: \[`$X_1$`\] A: \[`$Z_1$`\]. The answer is \[`$Y_1$`\]. Q: \[`$X_2$`\] A: \[`$Z_2$`\]. The answer is \[`$Y_2$`\]. \... Q: \[`$X_k$`\] A: \[`$Z_k$`\]. The answer is \[`$Y_k$`\]. Q: \[X\]. A: Let's give a correct and a wrong answer.", where `$X_i$`, `$Z_i$` and `$Y_i$` are the question, reasoning steps and the final answer for each example `$i$`.

# Experiment {#exp}

## Settings

#### Datasets

We evaluate the effectiveness of our proposal on 12 datasets encompassing four categories of reasoning tasks: arithmetic (SingleEq, AddSub, MultiArith, AQUA-RAT, GSM8K, SVAMP), commonsense (CommonsenseQA, StrategyQA), symbolic (Last Letter Concatenation, Coin Flip), and other logical reasoning tasks (Date Understanding, Tracking Shuffled Objects). The detailed description of each dataset can be found in [kojima2022large]. We use the few-shot examples with reasoning steps provided by [wei2022chain].

#### Baselines

We conducted a comprehensive comparison of our CP method with various types of prompting techniques. These include simple zero-shot methods such as Zero-shot and Zero-shot-CoT [kojima2022large], Few-shot and Few-shot-CoT [wei2022chain], X-of-thought approaches like Tree of Thoughts (ToT) [yao2024tree], Graph of Thoughts (GoT) [yao2023beyond], Program-aided Language models (PAL) [gao2023pal], and Program of thoughts prompting (PoT) [chen2022program]. Additionally, we compared our method with other prompting techniques such as Analogical prompting (Self-generated Exemplars) [yasunaga2023large] and Self-consistency (SC) [wang2022self]. Furthermore, we evaluated the effectiveness of self-reflection methods, including Recursive Criticism and Improvement (RCI) [kim2024language], Self-Refine [madaan2024self] and Learning Principles from Mistakes (LEAP) [zhang2024context], as well as the closest related work, Contrastive CoT [chia2023contrastive]. We also experimented with running CP using Self-consistency (SC). Specifically, we set the temperature parameter of LLMs to 0.7 and sampled 10 correct and incorrect answers. Then, we selected the answer that appeared most frequently among the 10 correct answers as the final answer.

#### Models

We use GPT-4 and GPT-3.5-Turbo (0613) as our base models (accessed between Feb 22nd--May 22nd 2024) for main experiments. We also tested our CP on various open LLMs: LLaMA3-8B, LLaMA3-70B [touvron2023llama], ChatGLM3-6B [du2022glm] and Qwen1.5-72B-Chat [qwen]. All generations (except experiments with Self-consistency) are done by greedy decoding (i.e., sampling with zero temperature) as in the original CoT work [wei2022chain]. For GPT models, we use Azure OpenAI services. For open LLMs except ChatGLM3-6B, we use LlamaAPI . For ChatGLM3-6B, we downloaded the model and performed the inference on a Linux server with an A100 GPU.

#### Answer filtering

We follow Zero-shot-CoT [kojima2022large] work and use its original implementation to pick up the final answers.

MultiArith GSM8K StrategyQA AddSub SVAMP CommonsenseQA

---

Zero-shot 60.97 14.39 65.02 82.78 69.74 71.33
Zero-shot-CoT 94.87 **75.56** 60.74 86.16 81.78 68.96
Zero-shot-CP **95.13** 73.22 **67.39** **90.46** **83.08** **73.81**

## Results

#### Zero-shot Results

Table [\[table:five_runs\]](#table:five_runs){reference-type="ref" reference="table:five_runs"} presents the accuracy scores achieved by our Zero-shot-CP, standard zero-shot prompting (Zero-shot) and Zero-shot-CoT across five datasets. We ran all methods five times using GPT-3.5-Turbo and report the average scores. We found that the differences in each run were minimal. Zero-shot-CP consistently outperformed Zero-shot-CoT and Zero-shot across most (4 out of 5) datasets.

Table [\[table:main_results_zero\]](#table:main_results_zero){reference-type="ref" reference="table:main_results_zero"} in Appendix [8](#appendix:extra_results){reference-type="ref" reference="appendix:extra_results"} presents more comprehensive results. Notably, Zero-shot-CP demonstrates significant improvements over Zero-shot on all 12 datasets across various tasks using GPT-3.5-Turbo. For instance, Zero-shot-CP achieves score gains ranging from `$14.3\%$` to `$73.2\%$` on GSM8K, from `$61.2\%$` to `$95.2\%$` on MultiArith and from `$4.2\%$` to `$41.8\%$` on Last Letter Concatenation. Moreover, Zero-shot-CP outperforms Zero-shot on the majority (9 out of 12) of datasets when using GPT-4, with improvements ranging from `$35.9\%$` to `$88.8\%$` on GSM8K and from `$41.3\%$` to `$62.2\%$` on AQUA-RAT. These results indicate that eliciting self-awareness in LLMs to compare incorrect and correct answers can help prevent incorrect responses.

Zero-shot-CP outperforms Zero-shot-CoT in the majority (4 out of 6) of arithmetic reasoning tasks, suggesting that the self-awareness of LLMs regarding incorrect answers may be more crucial than their self-awareness regarding steps in mathematical reasoning. Furthermore, in commonsense reasoning tasks, Zero-shot-CP consistently outperforms Zero-shot (2 out of 2), while Zero-shot-CoT exhibits inferior results. This is likely because commonsense reasoning tasks require fewer steps, making awareness of individual pieces of commonsense knowledge more crucial. However, Zero-shot-CP performs worse than Zero-shot-CoT in symbolic reasoning and other reasoning tasks, indicating that for tasks like Coin Flip and Shuffled Objects, the steps involved are more crucial. Moreover, breaking down the reasoning process into individual steps makes it less likely for LLMs to make mistakes in these tasks, as the action space is very limited. Nevertheless, by combining Zero-shot-CP and Zero-shot-CoT, Zero-shot-CoT-CP achieves better results in most tasks (see Table  [\[table:main_results_baselines\]](#table:main_results_baselines){reference-type="ref" reference="table:main_results_baselines"}).

Table [\[table:results_openllm\]](#table:results_openllm){reference-type="ref" reference="table:results_openllm"} in Appendix [8](#appendix:extra_results){reference-type="ref" reference="appendix:extra_results"} presents the results of using various open-source LLMs: LLaMA3-8B, LLaMA3-70B, ChatGLM3-6B, and Qwen1.5-72B-Chat as base models. The results demonstrate that Zero-shot-CP not only performs well with state-of-the-art GPT models, but also exhibits significant improvements across multiple sizes of open-source models.

+:--------------+:----------------------------------------------------------------------------------------------------------------+
| Question | Q: Danny collects bottle caps and wrappers. He found 46 wrappers and 50 bottle caps at the park. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      Now he has 21 bottle caps and 52 wrappers in his collection. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      How many more bottle caps than wrappers did danny find at the park? |
+---------------+-----------------------------------------------------------------------------------------------------------------+
| Zero-shot | A: The answer (arabic numerals) is -4. Danny found 50 bottle caps and 46 wrappers at the park, |
| +-----------------------------------------------------------------------------------------------------------------+
| |      so he found 4 more bottle caps than wrappers. |
+---------------+-----------------------------------------------------------------------------------------------------------------+
| Zero-shot-CoT | A: Let's think step by step. First, we need to find out how many bottle caps and wrappers |
| +-----------------------------------------------------------------------------------------------------------------+
| |      Danny had before he found the new ones at the park. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      We know that after finding the new ones, he has 50 bottle caps and 52 wrappers. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      Before finding the new ones, he had 21 bottle caps and 46 wrappers. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      So, the number of bottle caps he found at the park is 50 (total now) - 21 (total before) = 29 bottle caps. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      The number of wrappers he found at the park is 52 (total now) - 46 (total before) = 6 wrappers. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      Therefore, Danny found 29 - 6 = 23 more bottle caps than wrappers at the park. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      Therefore, the answer (arabic numerals) is 23 |
+---------------+-----------------------------------------------------------------------------------------------------------------+
| Zero-shot-CP | A: Let's give a correct and a wrong answer. **Correct Answer**: Danny found 50 bottle caps and 46 wrappers |
| +-----------------------------------------------------------------------------------------------------------------+
| |      at the park. So, he found 50 - 46 = 4 more bottle caps than wrappers at the park. |
| +-----------------------------------------------------------------------------------------------------------------+
| | |
| +-----------------------------------------------------------------------------------------------------------------+
| |      **Incorrect Answer**: Danny found 50 bottle caps and 46 wrappers at the park. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      So, he found 46 - 50 = -4 more bottle caps than wrappers at the park. |
| +-----------------------------------------------------------------------------------------------------------------+
| |      Therefore, the **correct** answer (arabic numerals) is 4 |
+---------------+-----------------------------------------------------------------------------------------------------------------+
| Ground Truth |      4 |
+---------------+-----------------------------------------------------------------------------------------------------------------+

#### Qualitative Analysis

Table [\[tab:answer_extract_svamp_42st\]](#tab:answer_extract_svamp_42st){reference-type="ref" reference="tab:answer_extract_svamp_42st"} and Table [\[tab:answer_extract_csqa_208st\]](#tab:answer_extract_csqa_208st){reference-type="ref" reference="tab:answer_extract_csqa_208st"} in Appendix  [8](#appendix:extra_results){reference-type="ref" reference="appendix:extra_results"} illustrates examples from SVAMP and CommonsenseQA. For the example from the arithmetic reasoning task SVAMP, we found that the reasoning process of zero-shot is correct, but it produces an incorrect answer \"-4\". Zero-shot-CoT is disrupted by irrelevant information, resulting in incorrect reasoning processes and answers being generated. Zero-shot-CP, on the other hand, is not disrupted and provides both the correct answer and explanation. We can see that the \"wrong answer\" \"-4\" from Zero-shot-CP is a real mistake made by Zero-shot. For the example from the common sense reasoning task CommonsenseQA, contrastive prompting is able to recognize the word \"work\" in the question and provide the correct answer, while Zero-shot and Zero-shot-CoT cannot.

In Appendix [8](#appendix:extra_results){reference-type="ref" reference="appendix:extra_results"}, we present responses generated by Zero-shot-CP for each dataset. Figure [5](#fig:example_addsub){reference-type="ref" reference="fig:example_addsub"}--[16](#fig:example_svamp){reference-type="ref" reference="fig:example_svamp"} gives both a positive example and a negative example of Zero-shot-CP on each dataset. From positive examples, we found that Zero-shot-CP can generate \"wrong\" answers that are indeed incorrect in most cases (11/12), except for Tracking Shuffled Object (Figure [13](#fig:example_object){reference-type="ref" reference="fig:example_object"}). Incorrect answers are generated by intentionally calculating inaccurately (Figure [12](#fig:example_multiarith){reference-type="ref" reference="fig:example_multiarith"}), disregarding important details (Figure [10](#fig:example_gsm8k){reference-type="ref" reference="fig:example_gsm8k"}), searching for descriptions that are not present in the question (Figure [9](#fig:example_csqa){reference-type="ref" reference="fig:example_csqa"}), or deliberately providing explanations that contradict common sense (Figure [15](#fig:example_strategyqa){reference-type="ref" reference="fig:example_strategyqa"}). From negative examples, We found that the \"wrong answers\" provided by Zero-shot-CP can actually be valid answers (Figure [6](#fig:example_aqua){reference-type="ref" reference="fig:example_aqua"}, [7](#fig:example_date){reference-type="ref" reference="fig:example_date"}, [8](#fig:example_coinflip){reference-type="ref" reference="fig:example_coinflip"}, [12](#fig:example_multiarith){reference-type="ref" reference="fig:example_multiarith"}, [14](#fig:example_singleeq){reference-type="ref" reference="fig:example_singleeq"} and [15](#fig:example_strategyqa){reference-type="ref" reference="fig:example_strategyqa"}). In some other negative examples, both the \"correct answers\" and \"incorrect answers\" provided by Zero-shot-CP are inconsistent with the ground truth (Figure [5](#fig:example_addsub){reference-type="ref" reference="fig:example_addsub"}, [9](#fig:example_csqa){reference-type="ref" reference="fig:example_csqa"}, [10](#fig:example_gsm8k){reference-type="ref" reference="fig:example_gsm8k"}, [11](#fig:example_lastletter){reference-type="ref" reference="fig:example_lastletter"} and [16](#fig:example_svamp){reference-type="ref" reference="fig:example_svamp"}). From the figures, we found that Zero-shot-CP also outputs reasoning steps in the process of generating correct and incorrect answers, especially for arithmetic reasoning tasks. Furthermore, we manually annotated 10 solved problems and 10 unsolved problems of Zero-shot-CP for each of the 12 datasets. Table [\[table:240_examples\]](#table:240_examples){reference-type="ref" reference="table:240_examples"} provides the categorization and counts of these 120 solved problems and 120 unsolved problems. We found that for the solved problems, the majority (112/120) of the given \"wrong\" answers were indeed incorrect. For the unsolved problems, the majority (91/120) of both the \"correct\" and \"wrong\" answers were incorrect, with a portion (23/120) of the \"wrong\" answers actually being the ground truth. This situation typically occurs in yes or no questions.

+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| GPT-4 | AQUA | GSM8K | AddSub | MultiArith |
+:============================================================================+:======================:+:======================:+:======================:+:======================:+
| Let's give a correct and a wrong answer. | 62.2 | 88.8 | [**91.6**]{.underline} | [**97.8**]{.underline} |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Let's first give a wrong answer, then give the correct answer. | 69.3 | 86.1 | 90.9 | 95.0 |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Let's first give the correct answer, then give a wrong answer. | 58.7 | **89.7** | 91.6 | 95.0 |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Let's give a correct and an incorrect answer. | 66.5 | 88.7 | 91.6 | 97.7 |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Please give a correct and a wrong answer. | 57.5 | 82.0 | 88.9 | 94.0 |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Let's give a correct answer. | [**71.7**]{.underline} | 75.9 | 89.4 | 97.0 |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Let's think step by step and give both a correct answer and a wrong answer. | **71.3** | 89.5 | **91.4** | 97.2 |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Let's give a correct and a wrong answer. Let's also think | 52.8 | 88.9 | 89.4 | 96.7 |
+-----------------------------------------------------------------------------+ | | | |
| step by step for the correct and the wrong answer. | | | | |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+
| Let's think step by step. (Zero-shot-CoT) | 70.1 | [**90.9**]{.underline} | 89.6 | **97.7** |
+-----------------------------------------------------------------------------+------------------------+------------------------+------------------------+------------------------+

MultiArith GSM8K StrategyQA AQUA SVAMP

---

Zero-shot 61.2 14.3 65.0 29.9 69.7
Zero-shot-CoT 94.8 75.1 60.9 55.9 81.9
Zero-shot-CoT + SC 96.8 **80.7** 61.6 **66.1** 85.6
Zero-shot-CP 95.2 73.2 67.3 40.2 83.2
Zero-shot-CP + SC **98.3** 80.3 **67.9** 48.4 **87.6**
Zero-shot-CoT-CP 96.2 73.5 66.7 60.6 85.9
Few-shot 87.3 58.2 56.7 37.4 78.2
Few-shot-CoT 98.0 71.1 62.2 55.5 81.0
Few-shot-CoT + SC 98.7 76.0 63.5 59.4 83.5
Few-shot-CoT-CP 97.5 72.7 68.7 52.0 82.2
Few-shot-CoT (GPT-4) 98.3 89.5 **79.1** 58.7 83.3
Few-shot-CoT-CP (GPT-4) **98.7** 90.3 78.2 66.9 91.8
Few-shot-CoT-CP (GPT-4) + SC 97.5 [**91.9**]{.underline} 78.8 [**70.9**]{.underline} [**93.1**]{.underline}
Contrastive CoT [chia2023contrastive] -- 79.0 66.2 57.5 81.6
Self-consistency (Code-davinci-002) [wang2022self] [**100.0**]{.underline} 78.0 79.8 52.0 86.8
PAL (Codex) [gao2023pal] 99.2 80.4 -- -- 79.4
Zero-shot-PoT (Codex) [chen2022program] 92.2 57.0 -- 43.9 70.8
Few-shot-PoT (Codex) [chen2022program] -- 71.6 -- 54.1 85.2
Few-shot-PoT-SC (Codex) [chen2022program] -- 80.0 -- **58.6** **89.1**
ToT (GPT-4) [yao2024tree] -- **90.0** [**83.0**]{.underline} -- --
GoT (T5-large) [yao2023beyond] -- 82.2 -- -- --
Self-generated Exemplars [yasunaga2023large] -- 77.8 -- -- --
Self-Refine [madaan2024self] -- 75.1 -- -- --
LEAP [zhang2024context] -- 77.4 -- -- --
Zero-Shot-CoT + RCI  [kim2024language] 97.2 86.2 -- -- 85.8
Few-Shot-CoT + RCI  [kim2024language] 99.2 84.3 -- -- 87.4

#### The impact of prompt selection on Zero-shot-CP

We explore different contrastive prompts and their combination with Zero-shot-CoT. Table [\[table:templates\]](#table:templates){reference-type="ref" reference="table:templates"} outlines performance using 9 different templates with two classes. The first category is related to correct and wrong answers. We found \"Let's give a correct and a wrong answer.\" achieves the best results in general. \"Let's first give a wrong answer, then give the correct answer.\" performs well on AQUA-RAT but it performs worse on other datasets. \"Let's first give the correct answer, then give a wrong answer.\" generally performs well on the four datasets, meaning that providing the correct answer first and then the incorrect answer generally leads to better results. The trigger word \"incorrect\" performs similarly to \"wrong\", and the trigger word \"Please\" performs much worse than \"Let's\". This is likely because, in the pre-training and fine-tuning data, there are slightly fewer occurrences of \"incorrect\" compared to \"wrong\" in samples related to correct and incorrect answers, and \"Please\" is rarely present as this type of data is generally not dialogue data. \"Let's give a correct answer.\" performs well on the multiple-choice question dataset AQUA-RAT, but the performances on other three mathematical reasoning tasks are not satisfactory. This indicates that, for multiple-choice questions, only providing a correct answer is equivalent to eliminating several incorrect answers. However, for questions without options, outputting an incorrect answer is helpful.

Table [\[table:results_correct_only\]](#table:results_correct_only){reference-type="ref" reference="table:results_correct_only"} in Appendix [8](#appendix:extra_results){reference-type="ref" reference="appendix:extra_results"} gives more comparative results between \"Let's give a correct and a wrong answer.\" and \"Let's give a correct answer.\" We find that, except for multiple-choice reasoning tasks, providing a wrong answer is more effective than only giving the correct answer. We also printed the token output probabilities for different prompts. As shown in Figure [4](#fig:token_prob){reference-type="ref" reference="fig:token_prob"} in Appendix [8](#appendix:extra_results){reference-type="ref" reference="appendix:extra_results"}, we find that adding prompts to generate incorrect answers changes the output probability distribution, Zero-shot-CP makes GPT-4 more confident in the ground truth answer.

The second type of template in Table [\[table:templates\]](#table:templates){reference-type="ref" reference="table:templates"} connects to Zero-shot-CoT, and we found that starting with the steps performs better than starting with the correct and wrong answers. Overall, it appears that Zero-shot-CoT-CP (\"Let's think step by step and give both a correct answer and a wrong answer.\") performs the best.

#### The impact of number of wrong answers on Zero-shot-CP

We explored the impact of the number of incorrect answers on accuracy. We vary the number of wrong answers from `$0$` to `$4$`, where `$0$` means standard zero-shot prompting. For `$k = 1,2,3,4$`, we use the template \"Let's give a correct and `$k'$` wrong answer(s).\", where `$k'$` can be \"a\", \"two\", \"three\" and \"four\". Figure [3](#fig:num_wrong){reference-type="ref" reference="fig:num_wrong"} plots the results. We found that providing 1-2 incorrect answers yielded the best results in general. The only exception is on AQUA-RAT, where providing more incorrect answers resulted in higher accuracy. This is because the task involves a multiple-choice question with five options, and excluding more incorrect answers makes the LLMs more certain about the correct answer. For math reasoning tasks with an infinite number of answers, providing just one incorrect answer seems to be sufficient.

[IMAGE: fig:num_wrong - Accuracy scores by varying the number of wrong answers. We test GPT-4 and GPT-3.5-Turbo on (a) AQUA-...]

#### Comparison with other baselines

Table [\[table:main_results_baselines\]](#table:main_results_baselines){reference-type="ref" reference="table:main_results_baselines"} compares the performances on four mathematical reasoning datasets (MultiArith, GSM8K, AQUA-RAT and SVAMP) and one common sense reasoning dataset (StrategyQA) across CP and baselines. We find that Zero-shot-CP not only outperforms Few-shot, but also achieves comparable or even superior results to Few-shot-CoT. For instance, on GSM8K, the absolute accuracy has improved by `$2.1\%$`, and on StrategyQA, the absolute accuracy has improved by `$5.1\%$`. This suggests that in certain cases, the provided examples and reasoning steps may not be as effective as directly triggering the LLM's self-awareness of errors. By combining CP and Few-shot-CoT, we can achieve even better results. Furthermore, if we utilize the GPT-4 model, we can attain performance that is comparable to or even superior to the current state-of-the-art methods. For example, in AQUA, SVAMP, and GSM8K, we have achieved higher accuracy scores compared to recently published results. When running CP with Self-consistency (SC), the scores can be further improved in both zero-shot and few-shot settings.

For a more in-depth performance analysis, we note that X-of-thought methods can improve the effectiveness of Few-shot-CoT, indicating that trees, graphs, and code indeed provide richer information and greater flexibility compared to simple chains of thought. Among them, the results reported by the ToT work seem to be more prominent. By sampling multiple reasoning paths and selecting the most consistent answer, Self-consistency (SC) demonstrates excellent performance in mathematical and commonsense reasoning tasks. It can also be effectively combined with other methods such as PoT. Self-generated Exemplars also show better performance than CoT, indicating that allowing the LLM to recall relevant questions and answer them before responding to the original question is helpful. The performance of Self-reflection methods, such as Self-Refine and LEAP, is similar to that of Self-generated Exemplars. RCI performs even better, primarily due to its direct combination with the CoT method. Compared to these methods, our approach is simpler and can also yield comparable results. Compared to the most relevant method Contrastive CoT, our Zero-shot-CP performs better on the StrategyQA and SVAMP datasets. Zero-shot-CoT-CP performs better on AQUA-RAT. However, on GSM8K, Contrastive CoT performs better, indicating that generating incorrect answers by swapping the order of entities is useful for this task.

The main reasons why CP works well are fourfold: 1) the pre-training data of LLMs contains many correct and incorrect answers to different types of questions. For instance, many web pages and books in Appendix [7.3](#appendix:pretrain_data_examples){reference-type="ref" reference="appendix:pretrain_data_examples"} provide correct and incorrect answers to math reasoning and common sense reasoning questions. Answers to questions on social media platforms like Reddit, Quora, and Zhihu can be voted on by others through "upvotes" or "downvotes". Highly upvoted answers are more likely to be correct answers while others may be incorrect. Pre-training LLMs with massive text containing these correct and wrong answers can encode general patterns (token probability) of these answers in LLM parameters. When prompted with contrastive prompts, LLMs can leverage these patterns to generate both a correct and a wrong answer. The \"correct\" answer is more likely to align with ground truth, as the model has learned to eliminate possible wrong answers. 2) Instruction tuning unlocks the abilities of LLMs to give correct and incorrect answers by fine-tuning on various natural language processing tasks including reasoning tasks [wei2021finetuned]. 3) RLHF fine-tunes LLMs using human feedback data, which offers relative judgments on the quality of answers. This feedback is valuable for enhancing the LLMs' capability to distinguish between correct and incorrect answers. 4) In CP, correct and wrong answers are returned by the LLM in a single output. The correct answers are generally distinct from the incorrect ones (as shown in Figure [5](#fig:example_addsub){reference-type="ref" reference="fig:example_addsub"}--[16](#fig:example_svamp){reference-type="ref" reference="fig:example_svamp"}), thereby excluding the (mostly indeed) incorrect answers and reducing the probability of the correct answers being wrong. Before outputting the two answers, the LLM engages in \"contrastive thinking\" to determine which answer is correct and which is incorrect.

# Conclusion

We propose CP, a template-based prompting approach for contrastive reasoning. Quantitative and qualitative results indicate that Zero-Shot-CP shows significant improvements across various reasoning tasks. Our method can seamlessly integrate with any prompting technique by incorporating a trigger sentence before the LLM provides answers. CP not only outperforms Zero-shot-CoT and Few-shot-CoT in most arithmetic and commonsense reasoning tasks, but also achieves comparable or even superior results when compared to state-of-the-art methods.

# Limitations {#limit}

Our work has some limitations and there is room for further exploration and improvement. Firstly, we have not yet validated the effectiveness of CP on smaller models such as Gemma-2B and Qwen1.5-0.5B. Secondly, we can further explore the combination of contrastive prompting with other prompting methods, such as X-of-thought approaches. Lastly, exploring the impact of contrastive prompting on LLM parameters and visualizing it would be an interesting future direction.

# Details of Experimental Setup {#appendix:settings}

## Code, Prompts, Logs

All code is available at <https://github.com/yao8839836/cp>.

All prompts are available at <https://github.com/yao8839836/cp/blob/master/main.py>.

Our experimental logs are available at <https://github.com/yao8839836/cp/tree/master/log>.

## Prompts For Answer Extraction {#appendix:answer_extract}

Table [\[tab:answer_extract\]](#tab:answer_extract){reference-type="ref" reference="tab:answer_extract"} summarizes the answer extraction prompt for each task used for the CP experiments.

## Pre-training data examples {#appendix:pretrain_data_examples}

For instance, many web pages and books provide correct and incorrect answers to math reasoning   and common sense reasoning    questions.

# Additional Experimental Results {#appendix:extra_results}

In this section, we provide a summary of additional example texts generated by Zero-shot-CP. GPT-3.5-Turbo is used as the model if not specified. Table [\[tab:answer_extract_csqa_208st\]](#tab:answer_extract_csqa_208st){reference-type="ref" reference="tab:answer_extract_csqa_208st"} illustrates example outputs of zero-shot prompting methods from CommonsenseQA. Figure [5](#fig:example_addsub){reference-type="ref" reference="fig:example_addsub"}--[16](#fig:example_svamp){reference-type="ref" reference="fig:example_svamp"} show a positive example and a negative example of Zero-shot-CP on each dataset. \"GT\" in the figures means \"Ground Truth\".

The 240 examples, along with our annotations, can be accessed at the following link: <https://anonymous.4open.science/r/cp-712E/results/zero_shot_cp_gpt4_240_examples_labeled.txt>.

Table [\[table:main_results_zero\]](#table:main_results_zero){reference-type="ref" reference="table:main_results_zero"} presents the comparison of Zero-shot-CP with Zero-shot and Zero-shot-CoT on all 12 datasets using GPT-3.5-Turbo and GPT-4.

Table [\[tab:answer_extract_csqa_208st\]](#tab:answer_extract_csqa_208st){reference-type="ref" reference="tab:answer_extract_csqa_208st"} presents an example question from CommonsenseQA and responses from different methods.

Table [\[table:results_openllm\]](#table:results_openllm){reference-type="ref" reference="table:results_openllm"} presents the results of using various open-source LLMs: LLaMA3-8B, LLaMA3-70B, ChatGLM3-6B, and Qwen1.5-72B-Chat as base models.

Table [\[table:results_correct_only\]](#table:results_correct_only){reference-type="ref" reference="table:results_correct_only"} presents the comparison of the results using \"Let's give a correct and a wrong answer.\" and \"Let's give a correct answer.\" prompts.

Table [\[table:240_examples\]](#table:240_examples){reference-type="ref" reference="table:240_examples"} provides the categorization and counts of these 120 solved problems and 120 unsolved problems.

In Figure [4](#fig:token_prob){reference-type="ref" reference="fig:token_prob"}, we printed the token output probabilities for different prompts. We provide an example in StrategyQA.

+---------------+-----------------------------------------------------------------------------------------------------------------------+
| | Arithmetic |
+:==============+:==================+:==================+:==================+:==================+:==================+:==================+
| 2-7 Method | SingleEq | AddSub | MultiArith | GSM8K | AQUA | SVAMP |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| Zero-shot | 90.6/81.7 | **92.4**/82.8 | 96.5/61.2 | 35.9/14.3 | 41.3/29.9 | 86.4/69.7 |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| Zero-shot-CoT | 91.7/91.1 | 89.6/86.6 | 97.7/94.8 | **90.9**/**75.1** | **70.1**/**55.9** | 90.4/81.9 |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| Zero-shot-CP | **91.7**/**91.7** | 91.6/**90.6** | **97.8**/**95.2** | 88.8/73.2 | 62.2/40.2 | **91.5**/**83.2** |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| | Common Sense | Other Reasoning Tasks | Symbolic Reasoning |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| 2-7 | Common | Strategy | Date | Shuffled | Last Letter | Coin Flip |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| | SenseQA | QA | Understand | Objects | (4 words) | (4 times) |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| Zero-shot | 82.9/71.3 | 64.8/65.0 | 73.2/40.4 | 40.7/33.9 | 5.0/4.2 | 36.6/49.6 |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| Zero-shot-CoT | 78.3/67.8 | 69.8/60.9 | **79.4**/**62.1** | **93.1**/**73.1** | **90.2**/**88.0** | **98.6**/**94.0** |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+
| Zero-shot-CP | **83.5**/**73.9** | **73.4**/**67.3** | 71.5/51.8 | 44.4/51.5 | 23.4/41.8 | 33.2/56.8 |
+---------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+

+:--------------+:--------------------------------------------------------------------------------------------------------------------+
| Question | Q: A bald eagle is likely to be found on what kind of work? |
| +---------------------------------------------------------------------------------------------------------------------+
| |      Answer Choices: (A) rural area (B) book (C) canada (D) painting (E) aviary |
+---------------+---------------------------------------------------------------------------------------------------------------------+
| Zero-shot | A: Among A through E, the answer is (E) aviary. However, it should be noted that |
| +---------------------------------------------------------------------------------------------------------------------+
| |      bald eagles can also be found in rural areas (A), in Canada (C), and depicted in books (B) and paintings (D). |
| +---------------------------------------------------------------------------------------------------------------------+
| |      The question seems to be asking where a bald eagle is likely to be found physically, and an aviary is a place |
| +---------------------------------------------------------------------------------------------------------------------+
| |      where birds are kept. |
+---------------+---------------------------------------------------------------------------------------------------------------------+
| Zero-shot-CoT | A: Let's think step by step. A bald eagle is a bird, so it could be found in an aviary (E), which is a place where |
| +---------------------------------------------------------------------------------------------------------------------+
| |      birds are kept. It could also be found in a rural area (A), as these birds often live in areas with less human |
| +---------------------------------------------------------------------------------------------------------------------+
| |      activity. A bald eagle could be depicted in a book (B) or a painting (D), as it is a popular symbol in various |
| +---------------------------------------------------------------------------------------------------------------------+
| |      cultures, especially in the United States. Lastly, bald eagles are also found in Canada (C), as their habitat |
| +---------------------------------------------------------------------------------------------------------------------+
| |      ranges across most of North America. Therefore, all of the options could be correct depending on the |
| +---------------------------------------------------------------------------------------------------------------------+
| |      context of the question. |
| +---------------------------------------------------------------------------------------------------------------------+
| |      Therefore, among A through E, the answer is (A) rural area, (B) book, (C) Canada, (D) painting, (E) aviary. |
+---------------+---------------------------------------------------------------------------------------------------------------------+
| Zero-shot-CP | A: Let's give a correct and a wrong answer. **Correct Answer**: (D) painting |
| +---------------------------------------------------------------------------------------------------------------------+
| | |
| +---------------------------------------------------------------------------------------------------------------------+
| |      **Wrong Answer**: (A) rural area |
| +---------------------------------------------------------------------------------------------------------------------+
| |      Therefore, among A through E, the correct answer is (D) painting |
+---------------+---------------------------------------------------------------------------------------------------------------------+
| Ground Truth |      D |
+---------------+---------------------------------------------------------------------------------------------------------------------+

No Task CP answer extraction prompts

---

1 SingleEq Therefore, the correct answer (arabic numerals) is
2 AddSub Therefore, the correct answer (arabic numerals) is
3 MultiArith Therefore, the correct answer (arabic numerals) is
4 GSM8K Therefore, the correct answer (arabic numerals) is
5 AQUA-RAT Therefore, among A through E, the correct answer is
6 SVAMP Therefore, the correct answer (arabic numerals) is
7 CommonsenseQA Therefore, among A through E, the correct answer is
8 StrategyQA Therefore, the correct answer (Yes or No) is
9 Date Understanding Therefore, among A through F, the correct answer is
10 Shuffled Objects Therefore, among A through C, the correct answer is
11 Last Letters Therefore, the correct answer is
12 Coin Flip Therefore, the correct answer (Yes or No) is

MultiArith GSM8K StrategyQA AQUA SVAMP

---

_LLaMA3-8B_  
 Zero-shot 31.0 38.1 -- -- 52.8
Zero-shot-CP **57.3** **54.9** -- -- **61.4**
_LLaMA3-70B_  
 Zero-shot 86.5 63.7 54.5 38.2 --
Zero-shot-CP **97.0** **66.1** **57.5** **62.2** --
_ChatGLM3-6B_  
 Zero-shot 5.3 4.3 -- -- --
Zero-shot-CP **67.0** **40.0** -- -- --
_Qwen1.5-72B-Chat_  
 Zero-shot 54.7 19.3 71.2 31.1 65.2
Zero-shot-CP **75.5** **52.1** **73.5** **45.3** **77.4**

CommonsenseQA StrategyQA

---

_GPT-3.5-Turbo_  
 Let's give a correct answer. 73.1 64.4
Let's give a correct and a wrong answer. **73.9** **67.3**
_GPT-4_  
 Let's give a correct answer. 82.3 71.8
Let's give a correct and a wrong answer. **83.5** **73.4**

**Category** **\# Examples**

---

The given \"correct\" answer is the GT, and the given \"wrong\" answer is indeed incorrect. 112
The given \"correct\" answer is the GT, and the given \"wrong\" answer is also the GT. 4
The given \"correct\" answer is the GT, no \"wrong\" answer is given. 4
The given \"correct\" answer is incorrect, and the given \"wrong\" answer is the GT. 23
The given \"correct\" answer is incorrect, and the given \"wrong\" answer is also incorrect. 91
The given \"correct\" answer is incorrect, no \"wrong\" answer is given. 6

[IMAGE: fig:token_prob - By setting the logprobs (log probabilities) parameter of the OpenAI API (using GPT-4), we printed th...]

[IMAGE: fig:example_addsub - Example outputs by Zero-shot-CP for AddSub.]

[IMAGE: fig:example_aqua - Example outputs by Zero-shot-CP for AQUA-ART.]

[IMAGE: fig:example_date - Example outputs by Zero-shot-CP for Date Understanding.]

[IMAGE: fig:example_coinflip - Example outputs by Zero-shot-CP for Coin Flip.]

[IMAGE: fig:example_csqa - Example outputs by Zero-shot-CP for CommonsenseQA.]

[IMAGE: fig:example_gsm8k - Example outputs by Zero-shot-CP for GSM8K.]

[IMAGE: fig:example_lastletter - Example outputs by Zero-shot-CP for Last Letter Concatenation.]

[IMAGE: fig:example_multiarith - Example outputs by Zero-shot-CP for MultiArith.]

[IMAGE: fig:example_object - Example outputs by Zero-shot-CP for Tracking Shuffled Object.]

[IMAGE: fig:example_singleeq - Example outputs by Zero-shot-CP for SingleEq.]

[IMAGE: fig:example_strategyqa - Example outputs by Zero-shot-CP for StrategyQA.]

[IMAGE: fig:example_svamp - Example outputs by Zero-shot-CP for SVAMP.]

: The datasets are available at <https://github.com/kojima-takeshi188/zero_shot_cot/tree/main/dataset>.

: <https://docs.llama-api.com/quickstart>

: <https://prek-math-te.stanford.edu/operations/analyzing-thinking-underlying-wrong-answers>

: <https://mathmistakes.org/category/elementary-school/>

: <https://www.gutenberg.org/ebooks/38769>

: <https://www.proprofs.com/quiz-school/story.php?title=common-sense-quiz_1>

: <https://www.wikihow.com/Common-Sense-Quiz>
