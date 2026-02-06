# Program of Thoughts Prompting: Disentangling Computation from Reasoning for Numerical Reasoning Tasks

**Authors:** Wenhu Chen, Xueguang Ma, Xinyi Wang, William W. Cohen

**Affiliations:** University of Waterloo, Vector Institute, University of California Santa Barbara, Google Research

**arXiv:** 2211.12588

---

# Abstract

Recently, there has been significant progress in teaching language models to perform step-by-step reasoning to solve complex numerical reasoning tasks. Chain-of-thoughts prompting (CoT) is the state-of-art method for many of these tasks. CoT uses language models to produce text describing reasoning, and computation, and finally the answer to a question. Here we propose 'Program of Thoughts' (PoT), which uses language models (mainly Codex) to generate text and programming language statements, and finally an answer. In PoT, the computation can be delegated to a program interpreter, which is used to execute the generated program, thus decoupling complex computation from reasoning and language understanding. We evaluate PoT on five math word problem datasets and three financial-QA datasets in both few-shot and zero-shot settings. We find that PoT has an average performance gain over CoT of around 12% across all datasets. By combining PoT with self-consistency decoding, we can achieve extremely strong performance on all the math datasets and financial datasets. All of our data and code will be released.

# Introduction

Numerical reasoning is a long-standing task in artificial intelligence. A surge of datasets has been proposed recently to benchmark deep-learning models' capabilities to perform numerical/arithmetic reasoning. Some widely used benchmarks are based on Math word problems (MWP) [cobbe2021training; patel-etal-2021-nlp; lu2022dynamic; ling2017program], where systems are supposed to answer math questions expressed with natural text. Besides MWP, some datasets also consider financial problems [chen2021finqa; chen2022convfinqa; zhu2021tat], where systems need to answer math-driven financial questions.

[IMAGE: Comparison between Chain of Thoughts and Program of Thoughts - figures/intro.001.pdf]

Prior work [ling2017program; cobbe2021training] has studied how to train models from scratch or fine-tune models to generate intermediate steps to derive the final answer. Such methods are data-intensive, requiring a significant number of training examples with expert-annotated steps. Recently, [nye2021show] have discovered that the large language models (LLMs) [brown2020language; chen2021evaluating; chowdhery2022palm] can be prompted with a few input-output exemplars to solve these tasks without any training or fine-tuning. In particular, when prompted with a few examples containing inputs, natural language 'rationales', and outputs, LLMs can imitate the demonstrations to both generate rationales and answer these questions. Such a prompting method is latter extended as 'Chain of Thoughts (CoT)' [wei2022chain], and it is able to achieve state-of-the-art performance on a wide spectrum of textual and numerical reasoning datasets.

CoT uses LLMs for both reasoning and computation, i.e. the language model not only needs to generate the mathematical expressions but also needs to perform the computation in each step. We argue that language models are not ideal for actually solving these mathematical expressions, because: 1) LLMs are very prone to arithmetic calculation errors, especially when dealing with large numbers; 2) LLMs cannot solve complex mathematical expressions like polynomial equations or even differential equations; 3) LLMs are highly inefficient at expressing iteration, especially when the number of iteration steps is large.

In order to solve these issues, we propose program-of-thoughts (PoT) prompting, which will delegate computation steps to an external language interpreter. In PoT, LMs can express reasoning steps as Python programs, and the computation can be accomplished by a Python interpreter. We depict the difference between CoT and PoT in Figure 1. In the upper example, for CoT the iteration runs for 50 times, which leads to extremely low accuracy; in the lower example, CoT cannot solve the cubic equation with language models and outputs a wrong answer. In contrast, in the upper example, PoT can express the iteration process with a few lines of code, which can be executed on a Python interpreter to derive an accurate answer; and in the lower example, PoT can convert the problem into a program that relies on 'SymPy' library in Python to solve the complex equation.

We evaluate PoT prompting across five MWP datasets, GSM8K, AQuA, SVAMP, TabMWP, MultiArith; and three financial datasets, FinQA, ConvFinQA, and TATQA. These datasets cover various input formats including text, tables, and conversation. We give an overview of the results in Figure 2. Under both few-shot and zero-shot settings, PoT outperforms CoT significantly across all the evaluated datasets. Under the few-shot setting, the average gain over CoT is around 8% for the MWP datasets and 15% for the financial datasets. Under the zero-shot setting, the average gain over CoT is around 12% for the MWP datasets. PoT combined with self-consistency (SC) also outperforms CoT+SC [wang2022self] by an average of 10% across all datasets. Our PoT+SC achieves the best-known results on all the evaluated MWP datasets and near best-known results on the financial datasets (excluding GPT-4 [gpt4]). Finally, we conduct comprehensive ablation studies to understand the different components of PoT.

[IMAGE: Few-shot (upper), Few-shot + SC (middle) and Zero-Shot (lower) Performance overview of Codex PoT and Codex CoT across different datasets]

# Program of Thoughts

## Preliminaries

In-context learning has been described in [brown2020language; chen2021evaluating; chowdhery2022palm; rae2021scaling]. Compared with fine-tuning, in-context learning (1) only takes a few annotations/demonstrations as a prompt, and (2) performs inference without training the model parameters. With in-context learning, LLMs receive the input-output exemplars as the prefix, followed by an input problem, and generate outputs imitating the exemplars. More recently, 'chain of thoughts prompting' [wei2022chain] has been proposed as a specific type of in-context learning where the exemplar's output contains the 'thought process' or rationale instead of just an output. This approach has been shown to elicit LLMs' strong reasoning capabilities on various kinds of tasks.

## Program of Thoughts

Besides natural language, programs can also be used to express our thought processes. By using semantically meaningful variable names, a program can also be a natural representation to convey human thoughts. For example, in the lower example in Figure 1, we first create an unknown variable named `interest_rate`. Then we bind 'summation in two years with ... interest rate' to the variable `sum_in_two_years_with_XXX_interest` and write down the equation expressing their mathematical relations with `interest_rate`. These equations are packaged into the 'solve' function provided by 'SymPy'. The program is executed with Python to solve the equations to derive the answer variable `interest_rate`.

Unlike CoT, PoT relegates some computation to an external process (a Python interpreter). The LLMs are only responsible for expressing the 'reasoning process' in the programming language. In contrast, CoT aims to use LLMs to perform both reasoning and computation. We argue that such an approach is more expressive and accurate in terms of numerical reasoning.

The 'program of thoughts' is different from generating equations directly, where the generation target would be ```latex $solve(20000 * (1 + x)^3 - 2000 - x * 20000 * 3 - 1000, x)$ ```. As observed by [wei2022chain] for CoT, directly generating such equations is challenging for LLMs. PoT differs from equation generation in two aspects: (1) PoT breaks down the equation into a multi-step 'thought' process, and (2) PoT binds semantic meanings to variables to help ground the model in language. We found that this sort of 'thoughtful' process can elicit language models' reasoning capabilities and generate more accurate programs. We provide a detailed comparison in the experimental section.

We show the proposed PoT prompting method in Figure 3 under the few-shot and zero-shot settings. Under the few-shot setting, a few exemplars of (question, 'program of thoughts') pairs will be prefixed as demonstrations to teach the LLM how to generate 'thoughtful' programs. Under the zero-shot setting, the prompt only contains an instruction without any exemplar demonstration. Unlike zero-shot CoT [kojima2022large], which requires an extra step to extract the answer from the 'chain of thoughts', zero-shot PoT can return the answer straightforwardly without extra steps.

[IMAGE: Left: Few-shot PoT prompting, Right: Zero-shot PoT prompting - figures/model.001.jpeg]

In zero-shot PoT, a caveat is that LLM can fall back to generating a reasoning chain in comments rather than in the program. Therefore, we propose to suppress '#' token logits to encourage it to generate programs.

## PoT as an Intermediate Step

For certain problems requiring additional textual reasoning, we propose to utilize PoT to tackle the computation part. The program generated by PoT can be executed to provide intermediate result, which is further combined with the question to derive the final answer with CoT. We depict the whole process in Figure 8.

During demonstration, we present LLMs with examples to teach it predict whether to an additional CoT reasoning needs to be used. If LLM outputs 'keep prompting' in the end, we will adopt the execution results from PoT as input to further prompt LLMs to derive the answer through CoT.

[IMAGE: PoT combined with CoT for multi-stage reasoning - figures/chainer.001.jpeg]

For instance, in the left example in Figure 3, the program will be executed to return a float number 'ans=2.05', which means that after 2.05 hours the two trains will meet. However, directly adding 2.05 to 11 AM does not make sense because 2.05 hour needs to be translated to minutes to obtain the standard HH:MM time format to make it aligned with provided option in the multi-choice questions. Please note that this prompting strategy is only needed for the AQuA because the other datasets can all be solved by PoT-only prompting.

# Experiments

## Experimental Setup

### Datasets

We summarize our evaluated datasets in Table 1. We use the test set for all the evaluated datasets except TATQA. These datasets are highly heterogeneous in terms of their input formats. We conduct comprehensive experiments on this broad spectrum of datasets to show the generalizability and applicability of PoT prompting.

| Dataset | Split | Example | Domain | Input | Output |
|---------|-------|---------|--------|-------|--------|
| GSM8K [cobbe2021training] | Test | 1318 | MWP | Question | Number |
| AQuA [ling2017program] | Test | 253 | MWP | Question | Option |
| SVAMP [patel-etal-2021-nlp] | Test | 1000 | MWP | Question | Number |
| MultiArith [roy2015solving] | Test | 600 | MWP | Question | Number |
| TabMWP [lu2022dynamic] | Test | 7861 | MWP | Table + Question | Number + Text |
| FinQA [chen2021finqa] | Test | 1147 | Finance | Table + Text + Question | Number + Binary |
| ConvFinQA [chen2022convfinqa] | Test | 421 | Finance | Table + Text + Conversation | Number + Binary |
| TATQA [zhu2021tat] | Dev | 1668 | Finance | Table + Text + Question | Number + Text |

To incorporate the diverse inputs, we propose to linearize these inputs in the prompt. For table inputs, we adopt the same strategy as [chen2022large] to linearize a table into a text string. The columns of the table are separated by '|' and the rows are separated by '\n'. If a table cell is empty, it is filled by '-'. For text+table hybrid inputs, we separate tables and text with '\n'. For conversational history, we also separate conversation turns by '\n'. The prompt is constructed by the concatenation of task instruction, text, linearized table, and question. For conversational question answering, we simply concatenate all the dialog history in the prompt.

### Implementation Details

We mainly use the OpenAI Codex (code-davinci-002) API for our experiments. We also tested GPT-3 (text-davinci-002), ChatGPT (gpt-turbo-3.5), CodeGen [nijkamp2022codegen] (codegen-16B-multi and codegen-16B-mono), CodeT5+ [wang2023codet5+] and Xgen for ablation experiments. We use Python 3.8 with the SymPy library to execute the generated program. For the few-shot setting, we use 4-8 shots for all the datasets, based on their difficulty. For simple datasets like FinQA [chen2021finqa], we tend to use fewer shots, while for more challenging datasets like AQuA [ling2017program] and TATQA [zhu2021tat], we use 8 shots to cover more diverse problems. The examples are taken from the training set. We generally write prompts for 10-20 examples and then tune the exemplar selection on a small validation set to choose the best 4-8 shots for the full set evaluation.

To elicit the LLM's capability to perform multi-step reasoning, we found a prompt to encourage LLMs to generate reasonable programs without demonstration. The detailed prompt is shown in Figure 3. However, a caveat is that LLM can fall back to generating a reasoning chain in comments rather than in the program. Therefore, we suppress the '#' token logits by a small bias to decrease its probability to avoid such cases. In our preliminary study, we found that -2 as the bias can achieve the best result. We found that this simple strategy can greatly improve our performance.

### Metrics

We adopt exact match scores as our evaluation metrics for GSM8K, SVAMP, and MultiArith datasets. We will round the predicted number to a specific precision and then compare it with the reference number. For the AQuA dataset, we use PoT to compute the intermediate answer and then prompt the LLM again to output the closest option to measure the accuracy. For TabMWP, ConvFinQA, and TATQA datasets, we use the official evaluation scripts provided on Github. For FinQA, we relax the evaluation for CoT because LLMs cannot perform the computation precisely (especially with high-precision floats and large numbers), so we adopt 'math.isclose' with relative tolerance of 0.001 to compare answers.

### Baselines

We report results for three different models including Codex [chen2021evaluating], GPT-3 [brown2020language], PaLM [chowdhery2022palm] and LaMDA [thoppilan2022lamda]. We consider two types of prediction strategies including direct answer output and chain of thought to derive the answer. Since PaLM API is not public, we only list PaLM results reported from previous work [wei2022chain; wang2022self]. We also leverage an external calculator as suggested in [wei2022chain] for all the equations generated by CoT, which is denoted as CoT + calc. Besides greedy decoding, we use self-consistency [wang2022self] with CoT, taking the majority vote over 40 different completions as the prediction.

## Main Results

### Few-shot Results

We give our few-shot results in Table 2. On MWP datasets, PoT with greedy decoding improves on GSM8K/AQuA/TabMWP by more than 8%. On SVAMP, the improvement is 4% mainly due to its simplicity. For financial QA datasets, PoT improves over CoT by roughly 20% on FinQA/ConvFinQA and 8% on TATQA. The larger improvements in FinQA and ConvFinQA are mainly due to miscalculations on LLMs for large numbers (e.g. in the millions). CoT adopts LLMs to perform the computation, which is highly prone to miscalculation errors, while PoT adopts a highly precise external computer to solve the problem. As an ablation, we also compare with CoT+calc, which leverages an external calculator to correct the calculation results in the generated 'chain of thoughts'. The experiments show that adding an external calculator only shows mild improvement over CoT on MWP datasets, much behind PoT. The main reason for poor performance of 'calculator' is due to its rigid post-processing step, which can lead to low recall in terms of calibrating the calculation results.

### Few-shot + Self-Consistency Results

We leverage self-consistency (SC) decoding to understand the upper bound of our method. This sampling-based decoding algorithm can greatly reduce randomness in the generation procedure and boosts performance. Specifically, we set a temperature of 0.4 and K=40 throughout our experiments. According to Table 2, we found that PoT + SC still outperforms CoT + SC on MWP datasets with notable margins. On financial datasets, we observe that self-consistency decoding is less impactful for both PoT and CoT. Similarly, PoT + SC outperforms CoT + SC by roughly 20% on FinQA/ConvFinQA and 7% on TATQA.

### Zero-shot Results

We also evaluate the zero-shot performance of PoT and compare with [kojima2022large] in Table 3. As can be seen, zero-shot PoT significantly outperforms zero-shot CoT across all the MWP datasets evaluated. Compared to few-shot prompting, zero-shot PoT outperforms zero-shot CoT [kojima2022large] by an even larger margin. On the evaluated datasets, PoT's outperforms CoT by an average of 12%. On TabMWP, zero-shot PoT is even higher than few-shot CoT. These results show the great potential to directly generalize to many unseen numerical tasks even without any dataset-specific exemplars.

## Ablation Studies

We performed multiple ablation studies under the few-shot setting to understand the importance of different factors in PoT including the backbone models, prompt engineering, etc.

### Backend Ablation

To understand PoT's performance on different backbone models, we compare the performance of text-davinci-002, code-davinci-002, gpt-3.5-turbo, codegen-16B-mono, codegen-16B-multi, CodeT5+ and XGen. We choose three representative datasets GSM8K, SVAMP, and FinQA to analyze the results. We show our experimental results in Table 4. As can be seen, gpt-3.5-turbo can achieve the highest score to outperform codex (code-davinci-002) by a remarkable margin. In contrast, text-davinci-002 is weaker than code-davinci-002, which is mainly because the following text-based instruction tuning undermines the models' capabilities to generate code. A concerning fact we found is that the open source model like codegen [nijkamp2022codegen] is significantly behind across different benchmarks. We conjecture that such a huge gap could be attributed to non-sufficient pre-training and model size.

| Model | #Params | GSM8K | SVAMP |
|-------|---------|-------|-------|
| code-davinci-002 | 175B | 71.6 | 85.2 |
| text-davinci-002 | 175B | 60.4 | 80.1 |
| gpt-3.5-turbo | - | 76.3 | 88.2 |
| codegen-16B-multi | 16B | 8.2 | 29.2 |
| codegen-16B-mono | 16B | 12.7 | 41.1 |
| codeT5+ | 16B | 12.5 | 38.5 |
| xgen | 7B | 11.0 | 40.6 |

**Table 4:** PoT prompting performance with different backend model.

### Sensitivity to Exemplars

[IMAGE: Exemplar sensitivity analysis for GSM8K and FinQA, where v1, v2 and v3 are three versions of k-shot demonstration sampled from the pool]

To better understand how sensitive PoT is w.r.t different exemplars, we conduct a sensitivity analysis. Specifically, we wrote 20 total exemplars. For k-shot learning, we randomly sample k = (2, 4, 6, 8) out of the 20 exemplars three times as v1, v2, and v3. We will use these randomly sampled exemplars as demonstrations for PoT. We summarize our sensitivity analysis in Figure 5. First of all, we found that increasing the number of shots helps more for GSM8K than FinQA. This is mainly due to the diversity of questions in GSM8K. By adding more exemplars, the language models can better generalize to diverse questions. Another observation is that when given fewer exemplars, PoT's performance variance is larger. When K=2, the performance variance can be as large as 7% for both datasets. With more exemplars, the performance becomes more stable.

### Comparison with PaL

We also compare PoT with another more recent related approach like PaL [gao2022pal]. According to Table 5, we found that our method is in general better than PaL, especially on SVAMP and ASDIV. Our results are 6% higher than their prompting method.

| Model | GSM8K | GSM8K-Hard | SVAMP | ASDIV | ADDSUB | MULTIARITH |
|-------|-------|------------|-------|-------|--------|------------|
| PaL | **72.0** | 61.2 | 79.4 | 79.6 | **92.5** | 99.2 |
| PoT | 71.6 | **61.8** | **85.2** | **85.2** | 92.2 | **99.5** |

**Table 5:** Comparison of PoT against contemporary work PaL [gao2022pal].

### Semantic Binding and Multi-Step Reasoning

The two core properties of 'program of thoughts' are: (1) multiple steps: breaking down the thought process into the step-by-step program, (2) semantic binding: associating semantic meaning to the variable names. To better understand how these two properties contribute, we compared with two variants. One variant is to remove the semantic binding and simply use a,b,c as the variable names. The other variant is to directly predict the final mathematical equation to compute the results. We show our findings in Table 6. As can be seen, removing the binding will in general hurt the model's performance. On more complex questions involving more variables like GSM8K, the performance drop is larger. Similarly, prompting LLMs to directly generate the target equations is also very challenging. Breaking down the target equation into multiple reasoning steps helps boost performance.

| Method | GSM8K | SVAMP | FinQA |
|--------|-------|-------|-------|
| PoT | 71.6 | 85.2 | 64.5 |
| PoT - Binding | 60.2 | 83.8 | 61.6 |
| PoT - MultiStep | 45.8 | 81.9 | 58.9 |

**Table 6:** Comparison between PoT and equation generation on three different datasets.

### Breakdown Analysis

We perform further analysis to determine which kinds of problems CoT and PoT differ most in performance. We use AQuA [ling2017program] as our testbed for this. Specifically, we manually classify the questions in AQuA into several categories including geometry, polynomial, symbolic, arithmetic, combinatorics, linear equation, iterative and probability. We show the accuracy for each subcategory in Figure 6. The major categories are (1) linear equations, (2) arithmetic, (3) combinatorics, (4) probability, and (5) iterative. The largest improvements of PoT are in the categories 'linear/polynomial equation', 'iterative', 'symbolic', and 'combinatorics'. These questions require more complex arithmetic or symbolic skills to solve. In contrast, on 'arithmetic', 'probability', and 'geometric' questions, PoT and CoT perform similarly. Such observation reflects our assumption that 'program' is more effective on more challenging problems.

[IMAGE: PoT and CoT's breakdown accuracy across different types of questions]

### Error Analysis

[IMAGE: Error cases on TAT-QA dev set using PoT-greedy method - figures/error-analysis.png]

We considered two types of errors: (1) value grounding error, and (2) logic generation error. The first type indicates that the model fails to assign correct values to the variables relevant to the question. The second type indicates that the model fails to generate the correct computation process to answer the question based on the defined variables. Figure 7 shows an example of each type of error. In the upper example, the model fetches the value of the variables incorrectly while the computation logic is correct. In the lower example, the model grounded relevant variables correctly but fails to generate proper computation logic to answer the question. We manually examined the errors made in the TAT-QA results. Among the 198 failure cases of numerical reasoning questions with the PoT (greedy) method, 47% have value grounding errors and 33% have logic errors. In 15% both types of errors occurred and in 5% we believe the answer is actually correct. We found that the majority of the errors are value grounding errors, which is also common for other methods such as CoT.

# Related Work

## Mathematical Reasoning in NLP

Mathematical reasoning skills are essential for general-purpose intelligent systems, which have attracted a significant amount of attention from the community. Earlier, there have been studies in understanding NLP models' capabilities to solve arithmetic/algebraic questions [hosseini2014learning; koncel2015parsing; roy2015solving; ling2017program; roy2018mapping]. Recently, more challenging datasets [dua2019drop; saxton2019analysing; miao2020diverse; amini2019mathqa; hendrycks2021measuring; patel-etal-2021-nlp] have been proposed to increase the difficulty, diversity or even adversarial robustness. LiLA [Mishra2022Lila] proposes to assemble a large set of mathematical datasets into a unified dataset. LiLA also annotates Python programs as the generation target for solving mathematical problems. However, LiLA [Mishra2022Lila] is mostly focused on dataset unification. Our work aims to understand how to generate 'thoughtful programs' to best elicit LLM's reasoning capability. Besides, we also investigate how to solve math problems without any exemplars. [austin2021program] propose to evaluate LLMs' capabilities to synthesize code on two curated datasets MBPP and MathQA-Python.

## In-context Learning with LLMs

GPT-3 [brown2020language] demonstrated a strong capability to perform few-shot predictions, where the model is given a description of the task in natural language with few examples. Scaling model size, data, and computing are crucial to enable this learning ability. Recently, [rae2021scaling; smith2022using; chowdhery2022palm; du2022glam] have proposed to train different types of LLMs with different training recipes. The capability to follow few-shot exemplars to solve unseen tasks is not existent on smaller LMs, but only emerge as the model scales up [kaplan2020scaling]. Recently, there have been several works [xie2021explanation; min2022rethinking] aiming to understand how and why in-context learning works. Another concurrent work similar to ours is BINDER [cheng2022binding], which applies Codex to synthesize 'soft' SQL queries to answer questions from tables.

## Chain of Reasoning with LLMs

Although LLMs have demonstrated remarkable success across a range of NLP tasks, their ability to reason is often seen as a limitation. Recently, CoT [wei2022chain; kojima2022large; wang2022self] was proposed to enable LLM's capability to perform reasoning tasks by demonstrating 'natural language rationales'. [suzgun2022challenging] have shown that CoT can already surpass human performance on challenging BIG-Bench tasks. Later on, several other works [drozdov2022compositional; zhou2022least; nye2021show] also propose different approaches to utilize LLMs to solve reasoning tasks by allowing intermediate steps. ReAct [yao2022react] propose to leverage external tools like search engine to enhance the LLM reasoning skills. Our method can be seen as augmenting CoT with external tools (Python) to enable robust numerical reasoning. Another contemporary work [gao2022pal] was proposed at the same time as ours to adopt hybrid text/code reasoning to address math questions.

## Discussion about Contemporary Work

Recently, there has been several follow-up work on top of PoT including self-critic [gou2023critic], self-eval [xie2023decomposition], plan-and-solve [wang2023plan]. These methods propose to enhance LLMs' capabilities to solve math problems with PoT. self-critic [gou2023critic] and self-eval [xie2021explanation] both adopt self-evaluation to enhance the robustness of the generated program. plan-and-solve [wang2023plan] instead adopt more detailed planning instruction to help LLMs create a high-level reasoning plan. These methods all prove to bring decent improvements over PoT on different math reasoning datasets.

Another line of work related to ours is Tool-use in transformer models [schick2023toolformer; paranjape2023art]. These work propose to adopt different tools to help the language models ground on external world. These work generalizes our Python program into more general API calls to include search engine, string extraction, etc. By generalization, LLMs can unlock its capabilities to solve more complex reasoning and grounding problems in real-world scenarios.

# Discussion

In this work, we have verified that our prompting methods can work efficiently on numerical reasoning tasks like math or finance problem solving. We also study how to combine PoT with CoT to combine the merits of both prompting approaches. We believe PoT is suitable for problems which require highly symbolic reasoning skills. For semantic reasoning tasks like commonsense reasoning (StrategyQA), we conjecture that PoT is not the best option. In contrast, CoT can solve more broader reasoning tasks.

# Conclusions

In this work, we investigate how to disentangle computation from reasoning in solving numerical problems. By 'program of thoughts' prompting, we are able to elicit LLMs' abilities to generate accurate programs to express complex reasoning procedure, while also allows computation to be separately handled by an external program interpreter. This approach is able to boost the performance of LLMs on several math datasets significantly. We believe our work can inspire more work to combine symbolic execution with LLMs to achieve better performance on other symbolic reasoning tasks.

# Limitations

Our work aims at combining LLM with symbolic execution to solve challenging math problems. PoT would require execution of 'generated code' from LLMs, which could contain certain dangerous or risky code snippets like 'import os; os.rmdir()', etc. We have blocked the LLM from importing any additional modules and restrict it to using the pre-defined modules. Such brutal-force blocking works reasonable for math QA, however, for other unknown symbolic tasks, it might hurt the PoT's generalization. Another limitation is that PoT still struggles with AQuA dataset with complex algebraic questions with only 58% accuracy. It's mainly due to the diversity questions in AQuA, which the demonstration cannot possibly cover. Therefore, the future research should discuss how to further prompt LLMs to generate code for highly diversified Math questions.

# Appendix

## PoT as intermediate step

We demonstrate the workflow in Figure 8.

[IMAGE: We adopt PoT to prompt language models to first generate an intermediate answer and then continue to prompt large models to generate the final answer - figures/chainer.001.jpeg]

We write the pseudo code as follows:

```python
# Function PoT(Input) -> Output
# Input: question
# Ouptut: program
# Function Prompt(Input) -> Output
# Input: question + intermediate
# Ouptut: answer
program = PoT(question)
exec(program)
if isintance(ans, dict):
    ans = list(x.items()).pop(0)
    extra = 'according to the program: '
    extra += ans[0] + ' = ' + ans[1]
    pred = Prompt(question + extra)
else:
    pred = ans
return pred
```

PoT as intermediate step is able to address more complex questions which require both symbolic and commonsense reasoning.

## Exemplars for Prompting

To enable better reproducibility, we also put our prompts and exemplars for GSM8K dataset and AQuA dataset in the following pages.

---

**Notes:**
- Assuming each addition is correct with 90% chance, after 50 additions, the likelihood of a correct output is less than 1%.
- OpenAI Codex API: https://openai.com/blog/openai-codex/
- XGen: https://blog.salesforceairesearch.com/xgen/
- SymPy library: https://www.sympy.org/en/index.html
