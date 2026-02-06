# Plan-and-Solve Prompting: Improving Zero-Shot Chain-of-Thought Reasoning by Large Language Models

**Authors:** Lei Wang, Wanyu Xu, Yihuai Lan, Zhiqiang Hu, Yunshi Lan, Roy Ka-Wei Lee, Ee-Peng Lim

**Affiliations:** Singapore Management University, Southwest Jiaotong University, Singapore University of Technology and Design, East China Normal University

**arXiv:** 2305.04091

---

# Abstract

Large language models (LLMs) have recently been shown to deliver impressive performance in various NLP tasks. To tackle multi-step reasoning tasks, few-shot chain-of-thought (CoT) prompting includes a few manually crafted step-by-step reasoning demonstrations which enable LLMs to explicitly generate reasoning steps and improve their reasoning task accuracy. To eliminate the manual effort, Zero-shot-CoT concatenates the target problem statement with "*Let's think step by step*" as an input prompt to LLMs. Despite the success of Zero-shot-CoT, it still suffers from three pitfalls: calculation errors, missing-step errors, and semantic misunderstanding errors. To address the missing-step errors, we propose Plan-and-Solve (PS) Prompting. It consists of two components: first, devising a plan to divide the entire task into smaller subtasks, and then carrying out the subtasks according to the plan. To address the calculation errors and improve the quality of generated reasoning steps, we extend PS prompting with more detailed instructions and derive PS+ prompting. We evaluate our proposed prompting strategy on ten datasets across three reasoning problems. The experimental results over GPT-3 show that our proposed zero-shot prompting consistently outperforms Zero-shot-CoT across all datasets by a large margin, is comparable to or exceeds Zero-shot-Program-of-Thought Prompting, and has comparable performance with 8-shot CoT prompting on the math reasoning problem. The code can be found at https://github.com/AGI-Edgerunners/Plan-and-Solve-Prompting.

# Introduction

[IMAGE: figures/intro_bar.pdf - Error analysis of 46 GSM8K problems with incorrect answers returned by Zero-shot-CoT using GPT-3 LLM. Following Wei et al. and Wang et al., we assign "Calculation Error" (7%), "Step Missing Error" (12%), or "Semantic misunderstanding Error" (27%) to each incorrect answer.]

Large language models (LLMs) [brown2020language; thoppilan2022lamda; palm] have recently proven highly effective in various NLP tasks. Unlike the previous pre-trained language models (PTMs) [bert; liu2019roberta], these LLMs are typically provided as a service, with no access to model parameters due to commercial considerations and potential risks of misuse [sun2022blackbox]. Thus, it is challenging to fine-tune LLMs for downstream tasks [he2021towards_finetuning; houlsby2019parameter_finetuning; bert]. Instead, we leverage LLMs to solve complex reasoning problems by eliciting their strong reasoning abilities over their embedded knowledge using instructions (or trigger sentences). So far, LLMs have shown impressive abilities to solve new reasoning problems by simply conditioning them on a few illustrative examples (i.e., few-shot learning) or a prompt to solve new problems without illustrative examples (i.e., zero-shot learning).

To tackle multi-step complex reasoning tasks using LLMs, Wei et al. propose few-shot chain-of-thought (CoT) prompting, which enables LLMs to explicitly generate the intermediate reasoning steps before predicting the final answer with a few manual step-by-step reasoning demonstration examples. In Kojima et al., Zero-shot CoT eliminates the need for manually crafted examples in prompts by appending "*Let's think step by step*" to the target problem fed to LLMs such as GPT-3. This simple prompting strategy surprisingly enables LLMs to yield performance similar to few-shot CoT prompting.

[IMAGE: figures/ACL2023-math-cot.jpg - Example inputs and outputs of GPT-3 with (a) Zero-shot-CoT prompting, (b) Plan-and-Solve (PS) prompting, and (c) answer extraction prompting. While Zero-shot-CoT encourages LLMs to generate multi-step reasoning with "Let's think step by step", it may still generate wrong reasoning steps when the problem is complex. Unlike Zero-shot-CoT, PS prompting first asks LLMs to devise a plan to solve the problem by generating a step-by-step plan and carrying out the plan to find the answer.]

Despite the remarkable success of Zero-shot-CoT in solving multi-step reasoning tasks, its results on a sample of 100 arithmetic test examples still point to three pitfalls: (i) Calculation errors (in 7% of test examples): These are errors in the calculation leading to wrong answers; (ii) Missing Step errors (in 12% of test examples): These occur when some intermediate reasoning step(s) is missed-out especially when there are many steps involved; (iii) Semantic misunderstanding (in 27% of test examples): There are other errors in semantic understanding of the problem and coherence of reasoning steps likely to be caused by the insufficient capability of LLMs.

To address the issue of Zero-shot-CoT caused by missing reasoning steps, we propose Plan-and-Solve (PS) Prompting. It consists of two components: first, devising a plan to divide the entire task into smaller subtasks, and then carrying out the subtasks according to the plan. In our experiments, we simply replace "*Let's think step by step*" of Zero-shot-CoT with "*Let's first understand the problem and devise a plan to solve the problem. Then, let's carry out the plan and solve the problem step by step*".

To address the calculation errors of Zero-shot-CoT and improve the quality of generated reasoning steps, we add more detailed instructions to PS prompting. Specifically, we extend it with "*extract relevant variables and their corresponding numerals*" and "*calculate intermediate results (pay attention to calculation and commonsense)*" instructions. This prompting variant is called the PS+ prompting strategy. Despite its simplicity, PS+ strategy greatly improves the quality of the generated reasoning process. Moreover, this prompting strategy can be easily customized to solve a variety of problems other than math reasoning, such as commonsense and symbolic reasoning problems.

[IMAGE: figures/ACL2023-math-cot-2.jpg - Example inputs and outputs of GPT-3 with (a) Plan-and-Solve (PS) Prompting and (b) Plan-and-Solve prompting with more detailed instructions (PS+ prompting). PS+ prompting greatly improves the quality of the generated reasoning process.]

We evaluate our proposed prompting on six math reasoning datasets, including AQuA [aqua], GSM8K [gsm8k], MultiArith, AddSub, SingleEq, and SVAMP [svamp], two commonsense reasoning datasets (CommonsenseQA [commonsenseqa] and StrategyQA [strategyqa]), and two symbolic reasoning datasets (Last Letter and Coin Flip [cot_wei]). The results of our experiments with GPT-3 show that our proposed Zero-shot-PS+ prompting consistently outperforms Zero-shot-CoT across all reasoning problems and datasets by a large margin, and is comparable to or exceeds Zero-shot-Program-of-Thought (PoT) Prompting [chen2022program]. Furthermore, although PS+ prompting does not require manual demonstration examples, it has a performance similar to an 8-shot CoT prompting in arithmetic reasoning.

Overall, our results suggest that (a) Zero-shot PS prompting is capable of generating a higher-quality reasoning process than Zero-shot-CoT prompting, as the PS prompts provide more detailed instructions guiding the LLMs to perform correct reasoning tasks; (b) Zero-shot PS+ prompting outperforms Few-shot manual-CoT prompting on some datasets, indicating that in some instances it has the potential to outperform manual Few-shot CoT prompting, which hopefully will spark further development of new CoT prompting approaches to elicit reasoning in LLMs.

# Plan-and-Solve Prompting

## Overview

We introduce PS prompting, a new zero-shot CoT prompting method, which enables LLMs to explicitly devise a plan for solving a given problem and generate the intermediate reasoning process before predicting the final answer for the input problem. As opposed to prior few-shot CoT approaches where step-by-step few-shot demonstration examples are included in the prompt, the zero-shot PS prompting method does not require demonstration examples, and its prompt covers the problem itself and a simple trigger sentence. Similar to Zero-shot-CoT, Zero-shot PS prompting consists of two steps. In step 1, the prompt first makes an inference using the proposed prompting template to generate the reasoning process and the answer to a problem. In step 2, it extracts the answer for evaluation by using the answer extraction prompting, such as "Therefore, the answer (arabic numerals) is".

## Step 1: Prompting for Reasoning Generation

To solve the input problem while avoiding errors resulting from incorrect calculation and missing reasoning steps, this step aims to construct templates to meet the following two criteria:

- The templates should elicit LLMs to determine subtasks and accomplish the subtasks.
- The templates should guide LLMs to pay more attention to calculations and intermediate results and to ensure that they are correctly performed as much as possible.

To meet the first criterion, we follow Zero-shot-CoT and first convert the input data example into a prompt with a simple template "Q: `[X]`. A: `[T]`". Specifically, the input slot `[X]` contains the input problem statement and a hand-crafted instruction is specified in the input slot `[T]` to trigger LLMs to generate a reasoning process that includes a plan and steps to complete the plan. In Zero-shot-CoT, the instruction in the input slot `[T]` includes the trigger instruction '*Let's think step by step*'. Our Zero-shot PS prompting method instead includes the instructions "*devise a plan*" and "*carry out the plan*". Thus, the prompt would be "Q: `[X]`. A: *Let's first understand the problem and devise a plan to solve the problem. Then, let's carry out the plan and solve the problem step by step*."

We then pass the above prompt to the LLM which subsequently outputs a reasoning process. In accordance with Zero-shot-CoT, our method uses the greedy decoding strategy (1 output chain) for generating output by default.

To meet the second criterion, we extend the plan-based trigger sentence with more detailed instructions. Specifically, "*pay attention to calculation*" is added to the trigger sentence to request the LLMs to perform calculations as accurately as possible. To reduce errors resulting from missing necessary reasoning steps, we include "*extract relevant variables and their corresponding numerals*" to explicitly instruct the LLMs not to ignore relevant information in the input problem statement. We hypothesize that if the LLMs leave out the relevant and important variables, it is more likely to miss out relevant reasoning steps. Correlation analysis of generated content of variable and the missing reasoning step errors empirically supports this hypothesis (correlation value is less than 0). Additionally, we add "*calculate intermediate results*" to the prompt to enhance LLM's ability to generate relevant and important reasoning steps. At the end of Step 1, LLM generates the reasoning text which includes the answer. For example, the generated reasoning text includes "*Combined weight of Grace and Alex = 125 + 498 = 623 pounds*". The strategy of adding specific descriptions to the trigger sentence represents a new way to improve zero-shot performance on complex reasoning.

## Step 2: Prompting for Answer Extraction

Similar to Zero-shot-CoT, we devise another prompt in Step 2 to get the LLM to extract the final numerical answer from the reasoning text generated in Step 1. This prompt includes the answer extraction instruction appended to the first prompt followed by the LLM generated reasoning text. This way, LLM is expected to return the final answer in the desired form.

Based on the example, the prompt used in Step 2 will include "*Q: Grace weighs 125 pounds ... Variables: Grace: 125 pounds ... Answer: Combined weight of Grace and Alex = 125 + 498 = 623 pounds. Therefore, the answer (arabic numerals) is*". For this example, the final answer returned by LLM is "*623*".

# Experimental Setup

## Benchmarks

The proposed method is evaluated on the ten benchmark datasets from three categories of reasoning problems:

**Arithmetic Reasoning:**
1. GSM8K [gsm8k] - high quality linguistically diverse grade school math word problems created by human problem writers
2. SVAMP [svamp] - one-unknown arithmetic word problems for up-to-4 grade level students
3. MultiArith [mutli_arith] - math word problems requiring multiple reasoning steps and operations
4. AddSub [addsub] - addition and subtraction arithmetic word problems
5. AQUA [aqua] - algebraic word problems with natural language rationales
6. SingleEq [singleeq] - single-equation grade-school algebra word problems

**Commonsense Reasoning:**
7. CSQA [commonsenseqa] - multiple-choice questions requiring different types of commonsense knowledge
8. StrategyQA [strategyqa] - questions requiring multi-step reasoning where reasoning steps must be inferred

**Symbolic Reasoning:**
9. Last Letter Concatenation [cot_wei] - questions requiring last letters of words in a name to be concatenated (e.g., "James Brown" -> "sn")
10. Coin Flip [cot_wei] - questions on whether a coin is still heads up after flipping/not flipping based on steps

## Zero-shot and Few-shot Baselines

We compare our proposed zero-shot PS and PS+ prompting methods with three types of prompting baselines:

1. **Zero-shot baselines.** We include zero-shot-CoT [kojima2022large] and zero-shot-PoT [chen2022program]. The former appends "Let's think step by step" to the prompt without any demonstration examples. The latter uses LLM (mainly OpenAI Codex) to generate a Python program and then derive an answer by executing the generated program on a Python interpreter.

2. **Few-shot with manual demonstrations.** Manual-CoT [cot_wei] creates eight hand-crafted examples as demonstrations.

3. **Few-shot with automatic demonstrations.** Auto-CoT [zhang2022automatic] automatically selected examples by clustering with diversity and generates reasoning chains using zero-shot-CoT to construct demonstrations.

## Implementations

Following Auto-CoT [zhang2022automatic], we use the public GPT-3 [brown2020language] (175B) as the backbone language model. Since `text-davinci-003` is an upgraded version of `text-davinci-002`, which can produce higher-quality writing, accommodate more complex instructions, and perform better at longer-form content generation, we report the results using `text-davinci-003` engine for GPT-3 in the main paper. We set the temperature to 0 (argmax sampling) throughout our experiments for the greedy decoding strategy. We also include two few-shot baselines, Manual-CoT and Auto-CoT, we use 8 demonstration examples for MultiArith, GSM8K, AddSub, SingleEq, and SVAMP, 4 examples for AQuA and Last Letters, 7 examples for CSQA, and 6 examples for StrategyQA as suggested in the original papers. Evaluation metrics wise, we follow Manual-CoT [cot_wei] and report the accuracy of all methods across datasets.

# Experimental Results

## Main Results

### Arithmetic Reasoning

In the zero-shot setting, our PS+ prompting (i.e., PS prompting with more detailed instructions) consistently outperforms Zero-shot-CoT across all arithmetic reasoning datasets by a large margin. Specifically, PS+ prompting improves the accuracy over Zero-shot CoT by at least 5% for all datasets except GSM8K which sees a 2.9% improvement. The exception could be due to GSM8K being a more challenging dataset from the linguistics complexity aspect. PS prompting also outperforms Zero-shot-CoT across all datasets, and enjoys 2.5% higher average accuracy than that of Zero-shot CoT.

Compared with another competitive Zero-shot baseline, PoT, the performance of PS(+) and PS promptings are still impressive. PS+ prompting outperforms PoT on five out of six arithmetic datasets. PS prompting also outperforms PoT on three arithmetic datasets. The results suggest that adding more detailed instructions to the prompt can effectively elicit higher-quality reasoning steps from LLMs.

Compared with the few-shot methods, Manual CoT and Auto-CoT, PS+ prompting yields an average accuracy (76.7%) slightly lower than Manual-CoT (77.6%) but higher than Auto-CoT (75.9%). While this is an unfair comparison, this result indicates that zero-shot prompting can outperform few-shot CoT prompting, which hopefully will spark further development of new ways with a less manual effort to effectively elicit reasoning in LLMs.

### Commonsense Reasoning

Results on commonsense reasoning datasets: CommonsenseQA and StrategyQA. We only include our better zero-shot PS+ prompting strategy in this comparison. Zero-shot PoT is excluded as it does not work on this problem. While PS+ prompting underperforms Few-Shot-CoT(Manual) on this problem, it consistently outperforms Zero-shot-CoT on CommonsenseQA (71.9% vs. 65.2%) and StrategyQA (65.4% vs. 63.8%) datasets.

### Symbolic Reasoning

On symbolic reasoning datasets: Last Letters and Coin Flip. Zero-shot PoT is again excluded as it is not designed for the problem. On Last Letters, our Zero-shot PS+ prompting (75.2%) outperforms Manual-CoT (70.6%) and Zero-shot-CoT (65.2%). On Coin Flip, Zero-shot PS+ prompting (99.6%) is slightly worse than Manual-CoT (100.0%) but outperforms Zero-shot-CoT by a good margin (96.8%).

## Analysis

### Results of Prompting with Self-Consistency

Self-consistency [wang2022self_consistency] (SC) is proposed to reduce randomness in LLM's output by generating N reasoning results and determining the final answer by majority voting. With SC, the methods' results are usually expected to be consistent and better. We evaluate Zero-shot PS+ prompting with SC on GSM8K and SVAMP datasets. We set the temperature to 0.7 and N to 10 for experiments with SC.

[IMAGE: figures/self-consistency.pdf - Results of methods with and without self-consistency (SC) on GSM8K and SVAMP.]

PS+ prompting with SC (73.7% and 84.4%) substantially outperforms that without SC (58.7% and 75.7%) on GSM8K and SVAMP, respectively. The former also consistently outperforms Zero-shot-CoT with SC (70.7% and 81.7%) on GSM8K and SVAMP, respectively, although Zero-shot CoT also enjoys improvement with the self consistency approach.

### Effect of Prompts

A comparison of the performance of 6 different input prompts shows that Prompts 1 and 2 are used in Zero-shot CoT and Zero-shot PoT respectively. The rest are variations of prompts used in Step 1 of the Zero-shot PS+ prompting strategies with greedy decoding. We observe that Prompt 3 with variables and numeral extraction performs worse than Prompt 1 of Zero-shot-CoT. The reason is that Prompt 3 doesn't include instructions for devising and completing a plan. However, the other prompts of Zero-shot-PS+ perform well as we add more instructions about intermediate results calculation, plan design, and implementation. The above results conclude that LLMs are capable of generating high-quality reasoning text when the prompts include more detailed instructions to guide the LLMs.

### Error Analysis

To qualitatively evaluate the impact of the Zero-shot-PS+ prompting on calculation errors and reasoning steps missing errors, we examine the distribution of errors on the GSM8K dataset. We first randomly sample 100 problems from GSM8K, generate the reasoning text, and extract answers using Zero-Shot-CoT, Zero-shot-PS, and Zero-shot-PS+ prompting strategies. Zero-Shot-CoT generated incorrect final answers for 46 of the problems, 43 for Zero-shot-PS, and 39 for Zero-shot-PS+.

The analysis results show that PS+ prompting achieves the least calculation (5%) and missing-step (7%) errors, and semantic understanding errors comparable to Zero-shot-CoT. Zero-shot-PS has slightly more errors but is still better than Zero-shot-CoT. Their plan-and-solve prompts thus effectively guide the LLMs to generate clear and complete reasoning steps. Moreover, the additional detailed instructions in PS+ prompting (i.e., "*extract relevant variables and their corresponding numerals*" and "*calculate intermediate variables*") enable the LLMs to generate high-quality reasoning steps leading to fewer calculation errors.

### Correlation Analysis of Generated Reasoning and Error Types

To obtain deeper insight into the impact of PS+ prompting on error types, we examine the correlation between the sub-parts of the generated reasoning and error types. Specifically, we analyze the existence of variable definition, reasoning plan, and solution in the generated reasoning text and correlate them with the three error types.

[IMAGE: figures/plan_cons_cor.pdf - Correlation analysis of generated reasoning and error types of randomly sampled 100 data examples from GSM8K for Zero-shot-PS+.]

It is observed that both variable definition and plan existences have a negative correlation with calculation errors and missing-reasoning-step errors. The Zero-shot-PS+ prompt can further improve the performance of LLMs on mathematical reasoning problems by reducing calculation errors and missing-reasoning-step errors.

### Exploring the Presence of Plans in PS Predictions

To ascertain the presence of a plan in each prediction made by PS, we conducted a random sampling of 100 data examples and examined their corresponding predictions. Our analysis reveals that 90 of the 100 predictions indeed incorporated a plan. This observation indicates the emergence of strong planning abilities in recent LLMs such as GPT-3.5 and GPT-4.

# Related Work

## Reasoning in NLP

It is well known that complex reasoning problems are challenging for NLP models, and such problems include mathematical reasoning [gsm8k; svamp; aqua; mawps] (requiring the ability to understand mathematical concepts, calculation, and multi-step reasoning), commonsense reasoning [commonsenseqa; strategyqa] (requiring the ability to make judgments based on commonsense knowledge), and logical reasoning [cot_wei] (requiring the ability to manipulate symbols by applying formal logical rules).

Before the advent of Large Language models (LLMs), Talmor et al. trained the NLP model using explanations generated by the fine-tuned GPT model and found that the trained model yields better performance on commonsense QA problems. Hendrycks et al. attempted to fine-tune pretrained language models with labeled rationale, but found out that these fine-tuned models could not easily generate high-quality reasoning steps.

Recent work by Wei et al. showed that LLMs demonstrates strong reasoning ability when scaled up to tens of billions of parameters, such as GPT-3 [brown2020language] and PaLM [palm]. These LLMs with a few demonstration exemplars can yield impressive performance across different NLP tasks. However, these models still perform poorly in problems that require multi-step reasoning. This may be due to the fact that the few exemplars provided are insufficient to unlock the LLMs' capabilities.

## Prompting Methods

To exploit the reasoning ability in LLMs, Wei et al. propose Chain-of-Thought prompting, appending multiple reasoning steps before the answer to the input question. With this simple few-shot prompting strategy, LLMs are able to perform much better in complex reasoning problems.

Subsequently, many works [wang2022towards; suzgun2022challenging; shaikh2022second_ana; saparov2022language_ana] propose to further improve CoT prompting in different aspects, including:
- **Prompt format:** Chen et al. introduced PoT prompting to use LLMs with code pre-training to write a program as a rationale for disentangling computation from reasoning
- **Prompt selection:** Lu et al.
- **Prompt ensemble:** [wang2022self_consistency; li2022advance; self_verification; fu2022complexity]
- **Problem decomposition:** [zhou2022least_to_most; khot2022decomposed; dua2022successive; press2022measuring]
- **Planning:** [Yao2022ReActSR; huang2022language; wang2023describe; liu2023llm+; Sun2023PEARLPL; Yao2023TreeOT]

To do away with manual effort, Kojima et al. proposed Zero-shot-CoT to elicit reasoning step generation without exemplars.

To leverage the benefit of demonstration examples and minimize manual effort, Zhang et al. designed Auto-CoT. It first automatically obtains k examples by clustering the given dataset. It then follows Zero-shot-CoT to generate rationales for the selected examples. Finally, demonstration examples are constructed by adding the generated rationales to selected examples as CoT prompts.

Our work is different from the above works by focusing on eliciting multi-step reasoning by LLMs in a zero-shot approach. We ask LLMs to write a plan to decompose a complex reasoning task into multiple reasoning steps. Furthermore, we introduce detailed instructions to the prompt to avoid obvious errors in the reasoning steps.

# Conclusion

In this paper, we find that Zero-shot-CoT still suffers from three pitfalls: calculation errors, missing-reasoning-step errors, and semantic understanding errors. To address these issues, we introduce plan-and-solve prompting strategies (PS and PS+ prompting). They are new zero-shot prompting methods that guide LLMs to devise a plan that divides the entire task into smaller subtasks and then carries out the subtasks according to the plan.

Evaluation on ten datasets across three types of reasoning problems shows PS+ prompting outperforms the previous zero-shot baselines and performs on par with few-shot CoT prompting on multiple arithmetic reasoning datasets.

Overall, our results suggest that:
- (a) Zero-shot PS+ prompting can generate a high-quality reasoning process than Zero-shot-CoT prompting since the PS prompts can provide more detailed instructions guiding the LLMs to perform correct reasoning
- (b) Zero-shot PS+ prompting has the potential to outperform manual Few-shot CoT prompting, which hopefully will spark further development of new CoT prompting approaches to elicit reasoning in LLMs

Moreover, PS(+) prompting is a general idea that can be used for non-reasoning tasks, and refining the plan is also an interesting idea. We leave them for future work.

# Limitations

There are two limitations to this work:

1. **Prompt design effort:** It takes effort to design the prompt to guide the LLMs to generate correct reasoning steps. The GPT-3 models are sensitive to the expressions in prompts. Thus we need to carefully design the prompts.

2. **Semantic misunderstanding errors:** The proposed plan-and-solve prompting can help address the calculation errors and missing-reasoning-step errors, but the semantic misunderstanding errors still remain. We will explore how to address semantic misunderstanding errors by prompting instead of upgrading LLMs in the future.

# Ethics

We experiment on six math reasoning datasets, including AQuA, GSM8K, MultiArith, AddSub, SingleEq, and SVAMP, two commonsense reasoning tasks (CommonsenseQA and StrategyQA), and two symbolic tasks (Last Letter and Coin Flip), where GSM8K and SVAMP use the MIT License code, AQUA and StrategyQA use the Apache-2.0 code, the remaining datasets are unspecified.

The proposed prompts do not collect and use personal information about other individuals. The prompts we used are listed in Appendix. The prompts in this work do not contain any words that discriminate against any individual or group. In this work, prompts would not negatively impact other people's safety.

# Appendix

This section includes two parts: (1) Results of all prompts we have tried; (2) Example texts generated by Zero-shot-PS+. Unless otherwise mentioned, we use GPT3 (text-davinci-003) model.

## Results of All Trigger Sentences

Tables 7 to 16 list the results of all prompts we have tried for each dataset.

## Example Outputs by Zero-shot-PS+

Tables 17 to 25 list example outputs generated by Zero-shot-PS+ for each dataset.
