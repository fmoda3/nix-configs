# Abstract

Large language models (LLMs) still grapple with complex tasks like mathematical reasoning. Despite significant efforts invested in improving prefix prompts or reasoning process, the crucial role of problem context might have been neglected. Accurate recognition of inputs is fundamental for solving mathematical tasks, as ill-formed problems could potentially mislead LLM's reasoning. In this study, we propose a new approach named Problem Elaboration Prompting (PEP) to enhance the mathematical capacities of LLMs. Specifically, PEP decomposes and elucidates the problem context before reasoning, therefore enhancing the context modeling and parsing efficiency. Experiments across datasets and models demonstrate promising performances: (1) PEP demonstrates an overall enhancement in various mathematical tasks. For instance, with the GPT-3.5 model, PEP exhibits improvements of 9.93% and 8.80% on GSM8k through greedy decoding and self-consistency, respectively. (2) PEP can be easily implemented and integrated with other prompting methods. (3) PEP shows particular strength in handling distraction problems.

[IMAGE: Figure 1 - We proposed Problem Elaboration Prompting (PEP) for enhancing problem context, thereby improving subsequent reasoning. As depicted in the example, PEP decouples spurious relationships and refines statements, preventing downstream distraction errors.]

# Introduction

Recent large language models (LLMs), such as the GPT-3 model family with 175 billion parameters [brown2020language *inter alia*], have demonstrated remarkable performance across various NLP tasks. Chain-of-thought (CoT) prompting [wei2022chain; kojima2022large] successfully elicits reasoning behavior and emergent abilities [Wei2022EmergentAO] by explicitly guiding the model to generate intermediate rationales step by step, further promoting the development of artificial general intelligence (AGI). Despite the success, performing multi-hop and compositional reasoning for complex tasks like mathematical solving can still face challenges [Hendrycks2021MeasuringMP; Lewkowycz2022SolvingQR], even when the required knowledge is limited to the scope of primary school [Cobbe2021TrainingVT].

[IMAGE: Figure 2 - An overview of the proposed PEP and other problem-related methods. Rather than creating sub-questions or plans to guide subsequent reasoning, PEP focuses on clarifying and enriching the problem context, i.e., PEP can be integrated with these methods.]

One area of research aims to improve the quality of reasoning outputs through diverse rationale decoding strategies [Wang2022SelfConsistencyIC; Suzgun2022FollowTW] and iteration-based answer refinement [Saunders2022SelfcritiquingMF; Kim2023LanguageMC; Zheng2023ProgressiveHintPI]. Considering the sensitivity of the model to inputs [lu2022fantastically; Wang2022TowardsUC; Shi2023LargeLM], another area of research focuses on augmenting the robustness of prefix-prompts [Fu2022ComplexityBasedPF; Wang2022RationaleAugmentedEI; Shao2023SyntheticPG]. However, the role of problem has been overlooked.

Most studies assume that the provided information is concise and relevant, while in real-world situations, the inputs could be ill-formed. For instance, LMs can be easily distracted by irrelevant context [Shi2023LargeLM] and often struggle to capture intricate implied implicatures [Ruis2022LargeLM; Chan2023ChatGPTEO]. Besides, even when the problem is well-formed, it may still be complex and unsuitable for the LM's comprehension. For instance, although the language model can be knowledgeable, it may encounter difficulties in identifying what knowledge are required to answer the question [Bian2023ChatGPTIA] or correctly integrating intermediate rationales to generate the overall solution [Press2022MeasuringAN].

Several works have noticed the crucial role of problem, suggesting pre-processing before reasoning. Least-to-Most (L2M) [Zhou2022LeasttoMostPE] proposes to decompose the final asked question into simpler sub-questions, Plan-and-Solve (PaS) [Wang2023PlanandSolvePI] requires a preliminary global plan, while Self-ask [Press2022MeasuringAN] suggests a dynamic asking strategy before each step of generating rationales. However, these methods primarily focus on decomposing questions or creating guidance, without understanding or discernment of the problem itself. Therefore, they could also potentially be misled by ill-formed problems.

In this study, we introduce a new method named **P**roblem **E**laboration **P**rompting (PEP), which involves decomposing and elucidating the problem context prior to reasoning. Our method aims to clarify the problem description and enhance the context modeling, rather than creating specific guidance. We illustrated an overview of PEP in Figure 2, along with a comparison with other problem-related prompting methods. Specifically, PEP adopts a human-like thought process that emphasizes the importance of thoroughly comprehending the problem's conditions and requirements before engaging in reasoning: _look before you leap_. PEP is also inspired by previous researches on semantic parsing, which suggest parsing the given problem into specific representations, such as Python code or condensed symbols [Gao2022PALPL; Chen2022ProgramOT; Hu2023ChainofSymbolPE], to facilitate subsequent reasoning.

We conduct evaluations of the proposed approach on four mathematical datasets and additionally investigate its performance in addressing the distraction problems [Shi2023LargeLM]. Both zero-shot and few-shot PEPs demonstrate an overall enhancement across datasets, models and answer types, employing greedy decoding and self-consistency settings. For instance, with GPT-3.5, we observed an improvement of 9.93% and 8.80% on GSM8k [Cobbe2021TrainingVT] with greedy decoding and self-consistency, separately. When using ChatGPT, PEP achieves SOTAs with 98.23% on SingleEq [KoncelKedziorski2015ParsingAW], and 88.7% on SVAMP [Patel2021AreNM].

In summary, our contributions are listed below:

1. We propose a new method, Problem Elaboration Prompting (PEP), for enhancing LLM's reasoning. It is easy to implement and integrate other prompting methods.

2. We evaluate PEP through extensive experiments using both open-source LMs and GPT model family, exploring the role of problem context for reasoning.

3. We demonstrate PEP is effective in mitigating the distraction problem, indicating the promising prospect in dealing with ill-formed problems of other types.

# Related Works

## Emergent Abilities and Prompting

With the large-scale unsupervised pre-training technique, LLMs [brown2020language; Chowdhery2022PaLMSL; touvron2023llama *inter alia*] can perform new tasks conditioning on few in-context inputs via mimicking the format of demonstrations [webson2022prompt; Min2022RethinkingTR; Pan2023WhatIL]. Instruction tuning further improves the generalization of prompts via training a language model to follow the general instructions rather than specific examples [Wei2021FinetunedLM; Ouyang2022TrainingLM; Chung2022ScalingIL].

Instead of directly generating the final answer, chain-of-thought prompting (CoT) methods [wei2022chain; Creswell2022SelectionInferenceEL; Jung2022MaieuticPL] suggest guiding LLMs to reach the final answer through a step-by-step process, eliciting the emergent reasoning ability [Wei2022EmergentAO; Chan2022DataDP; Prystawski2023WhyTS]. Zelikman2022STaRBR also proposed to use prompts to augment the trainset with rationales. However, such methods typically necessitate an LLM larger than 100B [wei2022chain], making it difficult to directly apply on small models [zhang2023multimodal].

## Improving CoT Reasoning

Various techniques have been proposed to improve the standard CoT [Wang2022SelfConsistencyIC; Suzgun2022FollowTW; Saunders2022SelfcritiquingMF; Gao2022PALPL; Kim2023LanguageMC; Yao2023TreeOT], most with a particular focus on controlling the decoding process and validating intermediate answers. Significant efforts have also been made to improve the prompts selection and ensemble [Fu2022ComplexityBasedPF; Lu2022DynamicPL; Zhou2022LargeLM; Shao2023SyntheticPG], to enhance the generation robustness. Besides, increasing the diversity of prompts, questions, or rationales shows notable advantages for the reasoning [Zhang2022AutomaticCO; Wang2022RationaleAugmentedEI].

PEP shares similarity with the study conducted by Lampinen2022CanLM, which explores the impact of explanations in context. However, it focus on the post-answer explanation, while we focus on elaborating the problem. PEP can also be regarded as a type of LLM-based agent system, sharing the concepts of analysis and decomposition [Shinn2023ReflexionLA; GenerativeAgents; Voyager]. While they primarily focus on observing environment and reflecting the feedback [Zheng2023ProgressiveHintPI; creator; mathchat; selfcheck], PEP focuses on comprehending and parsing the context.

# Problem Elaboration Prompting

A beneficial cognitive paradigm of humanity is the ability of thoughtful contemplation, as exemplified by a common figurative: _look before you leap_. In this work, we propose to simulate such a thinking process by prompting the model to elaborate on the problem before generating or reasoning. It is crucial for the LLM to ensure it has a thorough understanding of the problem space, encompassing the given conditions and the asked question, avoiding a hasty generation and exploration within the answer space.

**Example: Hasty Reasoning vs PEP**

**Q**: Brian's friend Bobby has 5 fewer than 3 times as many video games as Brian does. If Brian has 20 video games but lost 5 right before the comparison was made, how many does Bobby have?

**Standard CoT:**
**A**: Three times as many video games as Brian has is 3\*20=60 video games. Five fewer than 3 times as many video games as Brian has is 60-5=55 video games.
Final answer: 55. **(Wrong: ignore the precondition placed at end.)**

**PEP + CoT**
(+**Elaboration**):
Segment 1: Bobby has 5 fewer than 3 times as many video games as Brian does. Rephrased: Bobby's number of video games is 3 times Brian's number minus 5. Equation: B = 3B - 5
Segment 2: Brian has 20 video games. Equation: B = 20
Segment 3: Brian lost 5 video games right before the comparison was made. Equation: B = 20 - 5
**A**: Using segment 2's equation, we know that Brian has 20 video games. Using segment 3's equation, we know that Brian lost 5 video games, leaving him with 15 video games. We can substitute this value into segment 1's equation and solve for Bobby's number of video games. B = 3(15) - 5, B = 40.
Final answer: 40. (**Correct: process conditions in suitable order.**)

Recognizing the problem is imperative for reasoning. As illustrated, CoT wrongly engages in hasty reasoning, neglecting the prerequisite conditions placed afterwards. Meanwhile, PEP utilizes conditions in the correct order.

## Method Formulation

Given the problem context denoted by `latex $P=(X,y_0)\in D$ `, where `latex $X = \{x_1, x_2, \cdots,x_i\}$ ` represent the statements and `latex $y_0$ ` represents the asked question, prompting methods attempt to leverage the strength of LLMs to solve the task by generating rationale `latex $y_i = f_M(X,y_0;p_t,\hat{P}_k|y_{<i})$ ` step by step until reaching the final answer `latex $y_t$ `. Specifically, `latex $p_t$ ` denotes zero-shot instructions and `latex $\hat{P}_k$ ` indicate `latex $k$ ` concatenated exemplars `latex $(\hat{X}_k,\hat{y}_{k,0})$ `. Note that such prompting methods do not modify the LLM `latex $M$ `.

In the PEP-aid language model, we suggest to pre-process the given problem `latex $P$ ` by decomposing and elucidating the context into smaller and more concise segments to enhance LLMs' comprehension: `latex $P'=(\{x_1', x_2', \cdots,x_m'\},y_0')= f_M(X,y_0;p_e)$ `, where `latex $m\geq i$ ` and `latex $p_e$ ` is a specific instruction. Then, the LLM can continue its reasoning by `latex $y_i = f_M(X,y_0;p_t,\hat{P}_k|P',y_{<i})$ ` until reaching `latex $y_t$ `. Thus, PEP can be easily combined with previous prompting methods.

## Designing Principles

The design principle of problem elaboration in this study consists of two aspects: (i) **decomposing**: breaking down the original sentences into distinct segments to disentangle complex or intertwined concepts; (ii) **elucidating**: providing explanations or rephrasing the segments in a manner that is more conducive to the model's understanding.

The concept of _decomposition_ is widely spread in many previous works. Except for introduced problem-related methods, recent community adopts a decomposition approach in different fields to apply LMs to solve complex problems [wei2022chain; Khot2022DecomposedPA; Liang2023EncouragingDT; Hong2023MetaGPTMP], bridging the compositionality gap of powerful LMs [Press2022MeasuringAN]. In contrast, PEP takes a different approach by breaking down the entire problem into simpler segments, rather than creating sub-questions or decomposing the reasoning process. It focuses on organizing and clarifying the existing information from the problem.

Meanwhile, it could be beneficial to elucidate the segments following decomposition, as it elicits the model to organize existing information in a comprehensive view of the problem and recognize the underlying implicatures of the question. Moreover, it introduces diversity into the context, which has been demonstrated to enhance reasoning [Zhang2022AutomaticCO; Wang2022RationaleAugmentedEI], thereby mitigating the risk of relying on specific words or descriptions as shortcuts. A break-down analysis of our designed principles is presented in Section 4.4.

## Prompts Generation

Since the elaboration can be diverse, We evaluate and select the instruction of zero-shot PEP based on a subset of GSM8k-train of 200 points (see Section 6). The selected instruction is "_Decompose the given question into smaller segments, elucidating each segment as you rephrase it._" We further adopt the exemplars from [Zhou2022LeasttoMostPE] and adjusted them for different methods for fairness. All instructions and exemplars can be found in the appendix.

To investigate the behavior of PEP, we randomly selected 200 instances from the experiments with a manual categorization. PEP primarily utilizes question-answer pairs, declarative sentences, and interrogative sentences to review and examine the problem context. There are around 10.5% of instances that can be mixed with sub-questions, planning instructions, or intertwined rationales. We find it primarily occurs when the questions themselves contain instructions or options.

# Experiment

## Setup

#### Datasets.

We evaluate PEP on four elementary datasets, with a focus on mathematical reasoning: (1) **SingleEq** [KoncelKedziorski2015ParsingAW], (2) **GSM8k** [Cobbe2021TrainingVT], (3) **SVAMP** [Patel2021AreNM], (4) **AQuA** [Ling2017ProgramIB]. Furthermore, we investigate the distraction problem using GSMIC [Shi2023LargeLM]: we randomly sampled 500 examples separately for 2-step problems and m-step problems, denoted by (5) **GSMIC-1k**.

#### Baselines & Prompts.

We evaluate PEP with two elementary answer types: (1) Chain-of-Thoughts (**CoT**) [kojima2022large] for textual reasoning, and (2) Program-of-Thoughts (**PoT**) [Chen2022ProgramOT] for code-based reasoning. Three problem-related methods are compared to PEP: (3) Least-to-Most (**L2M**) [Zhou2022LeasttoMostPE], (4) Plan-and-Solve (**PaS**) [Wang2023PlanandSolvePI] and (5) **Self-ask** [Press2022MeasuringAN]. To investigate the distraction problem, we also adopt (6) **Irr-Inst.** suggested by Shi2023LargeLM. All instructions and exemplars can be found in the appendix.

#### Language Models & Decoding

We conduct our main experiments on four open-source LMs (1) two `LLama2` models [Touvron2023Llama2O] and (2) two `Mistral` models [Jiang2023Mistral7; Jiang2024MixtralOE]. We also employ two GPT models (3) "`text-davinci-003`" (`davinci`) and (4) recent released "`gpt-3.5-turbo-0125`" (`turbo`) [brown2020language; ouyang2022training; OpenAI2023GPT4TR]. We evaluate the performance with both greedy decoding and self-consistency decoding (SC) [Wang2022SelfConsistencyIC] to ensure the reproducibility of experiments.

## Main Results

The main results are presented in Tables showing proposed PEP's performances on various LMs, answer types and decoding strategies. We only test PoT on two GPT models, as its templates might not be designed for these smaller LMs. Considering the token cost, we validate the self-consistency CoT on two GPT models. The comparison and integration with other problem-related methods are shown using greedy decoding and `turbo-0125`, while verifying two different few-shots settings.

#### PEP performs well in a variety of situations.

Overall, PEP outperforms the standard CoT in most cases, with the exception of `Mistral-7B`, but demonstrating improvements for `Mistral-8x7B`. The performance in PoT and self-consistency settings further validates PEP's effectiveness and adaptability. The enhancement in PoT could be attributed to PEP simplifying parsing difficulties, thereby facilitating code generation [Jiang2023SelfplanningCG]. It is also noteworthy that PEP performs remarkably well on `davinci`, achieving improvements of 9.93% and 8.80% in greedy search and self-consistency, respectively.

#### PEP can be effectively integrated with other prompting methods.

Unlike the mentioned problem-related methods, PEP aims to enhance the original problem, making it compatible for integration. As shown, incorporating PEP improves the performance of these problem-related methods in both k=1 and k=4 few-shot settings, while the combination with the standard CoT also ranks highly in performance. Besides, we observed Self-ask underperforms when k=1. It's likely because one example might fail to elicit the dynamic QA process and LMs could abruptly terminate after generating follow-up questions.

## Distraction Problem

One particular challenge of ill-formed problems is known as _distraction problem_ [Shi2023LargeLM]: irrelevant sentences can distract LMs to generate errors. These sentences can be completely irrelevant or relevant to the problem but should have no impact on inference. We tested PEP using a subset of GSMIC [Shi2023LargeLM]. Two metrics are utilized: (1) _micro accuracy_: averaged accuracy per example, and (2) _macro accuracy_: averaged accuracy per base problem. _Norm_ is the accuracy normalized by scores on base problems, measuring how a method is affected by the distractors.

#### PEP effectively mitigates the distraction problems.

As shown, PEP surpasses CoT and L2M of both zero-shot and one-shot settings, in micro- and macro- metrics, indicating superior performance in addressing such ill-formed issues. Beyond overall accuracy, PEP also exhibits enhanced robustness as evidenced by norm accuracy. From the macro perspective, the improvements and stability of PEP are also remarkable.

#### PEP performs well when prompted with prior knowledge.

When the model is consciously prompted to ignore irrelevant content for the given problem, referred to as Irr-Inst. [Shi2023LargeLM], we observed significant improvements in CoT, L2M and PEP. Despite this, PEP still outperforms the 0-CoT and 1-L2M by achieving larger improvements for most cases. PEP particularly excels in 2-step problems and norm accuracies. However, its performance on macro accuracies is inferior, potentially due to a conflict between `Irr-Inst.` and the one-shot exemplar.

[IMAGE: Figure 3 - Breakdown accuracies w.r.t. irrelevant sentence factors (T: Topic, RO: Role Overlap, NR: Num. Range). Lower accuracy suggests the model is more sensitive to that factor.]

## Ablation Study

#### Breakdown analysis of distracting factors.

We evaluated the performance of CoT, L2M and PEP under various distracting factors. PEP significantly outperforms the basic baselines on almost all factors, both in micro and macro accuracies, indicating its potential benefits for downstream reasoning by aiding in problem context recognition and parsing. When prompted by the `Irr-inst.`, PEP shows consistent improvements for most cases, except for 1-CoT. Overall, PEP demonstrates better improvements in handling out-of-distribution distraction factors, specifically (1) off-topic sentences, (2) non-overlapping role names, and (3) out-of-range numbers. The impact of these factors is more pronounced on the macro- than the micro- metric.

#### Break-down analysis of PEP components.

We verify two components in PEP: (1) Dec: decomposing only, and (2) Elu: elucidating only, and (3) EtD: elucidating first then decomposing. As shown, both Dec and Elu are required for PEP, with performance varying across datasets. On GSM8k and SVAMP, Dec even outperforms PEP, while Elu is more effective on GSMIC. Besides, EtD consistently performed worse, suggesting that the coordination and operating order of components are also crucial for PEP.

## Error Analysis

We present two error cases. PEP may ignore the potential implicatures of original sentence, resulting in ambiguity of rephrasing. It may also focus too much on the local clause and neglect the nested logical structure and temporal relations for given statements.

Besides, PEP might break the continuous context, thus changing the implicit meanings. The focus on localities might also constrain required associative thinking. In addition, except increasing the cost of context length, PEP may also be inefficient for very long descriptions. For certain forms of data, such as short but challenging questions, structured data in table, it could be difficult to elaborate.

# Conclusion

In this study, we proposed a novel method, Problem Elaboration Prompting (PEP), to improve the inference capabilities of LLMs. PEP offers several advantages: 1) PEP outperforms baselines across mathematical datasets, decoding strategies, and answer types; 2) PEP does not necessitate the complex creation of plans or sub-questions, but just echoes and enriches the problem context in one pass. It is also compatible with most prompting methods that enhance prefix-prompts or rationales; 3) PEP helps mitigate the distraction issue, indicating its potential in tackling other types of ill-formed problems.

# Appendix: Experiment Details

#### Prompt Design and Selection.

We randomly sampled 200 points from GSM8k dataset for prompt selections. The alternatives are generated by communicating with ChatGPT. We test the original zero-shot instruction and the standard CoT used in our experiments. Then, we test four brief prompts and one particularly detailed prompt. An interesting phenomenon is that the overly detailed prompt (P5) resulted in a significant decrease.

#### Model Usage.

We used `turbo-0301`, an early version of ChatGPT, for instruction selection and type analysis in PEP. Given the possibility that OpenAI may restrict access to early models, we tested PEP on four open-source models, `text-davinci-003` and the recently released `turbo-0125`, as well to validate the generalization of the instructions. We utilized both `Llamma` models and `Mistral-7B` with bfloat16. Due to cost constraints, we loaded `Mistral-8x7B` in 4 bits.

# Appendix: All used instructions and exemplars

## Zero-shot prompts

To ensure fairness and clarity of semantics when combining multiple instructions, we use "Let's solve the question step by step" as the zero-shot CoT instead of "Let's think step by step.". The used prompts are list as follow:

```
CoT = "Let's solve the problem step by step. {IRR_Inst}{FORMAT_Inst}\nQuestion: {qst}"

PEP = "Decompose the given question into smaller segments, elucidating each segment as you rephrase it. Then, solve the problem step by step. {IRR_Inst}{FORMAT_Inst}\nQuestion: {qst}"

IRR_Inst = "Feel free to ignore irrelevant information given in the questions."
```

## Extract the answers

In order to extract results better, we add a standardized output instruction after each prompt during generation, namely:

(1) for free-answered questions, we use:

```
FORMAT_Inst = "End the solution in the format: 'Final answer: \boxed{X}', where X is arabic numerals or 'N\A' if the problem is unsolvable."
```

(2) for questions with options, we use:

```
FORMAT_Inst = "End the solution in the format: 'Final answer: \boxed{X}', where X is the choice."
```

Finally, we use a one-shot exemplars to extract the answers from generations by `turbo-0125`. For those unrecognized solutions, we extract the answers manually.

```
Extract_Template = "Given the textual solution or code execution solution, output the numeric answer that can be converted into float value of the problem. If the solution does not yield a result, output 'unsolved'. Only output the numeric value or 'unsolved'.

### Example:
Solution: The total amount of money Janet makes from selling eggs at the farmers' market per day is 21 - 4 = 17 eggs x $2 = $34.
Therefore, the final answer is: Janet makes $34 per day at the farmers' market.
Answer: $34
Result: 34
###
Original Problem: {qst}
Solution: {sol}
Result:"
```

## Few-shot exemplars

In this section, we enumerate all the exemplars used. They are directly adopted for CoT and L2M from [Zhou2022LeasttoMostPE], which are specifically designed for GSM8k. For PEP, PaS, and Self-ask, we re-generate the exemplars using GPT-4 for proper modifications.

In practice, the one-shot setting uniformly employs the first exemplar, while the four-shot utilizes all examples. When integrating PEP with other problem-related methods, we simply append the corresponding elaboration part of PEP to the original question of other examples, before any other generations. When employing `IRR-Inst`, we position it at the beginning.

The overall template structure is as follows, using the one-shot L2M+PEP+IRR_inst as an example for illustration:

```
"Solve grade school math problems. Feel free to ignore irrelevant information given in the questions.
Question: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together?
Problem Elaboration:
Segment 1: Elsa has 5 apples.
Segment 2: Anna has 2 more apples than Elsa.
Segment 3: How many apples do they have together?
Rephrased question: If Elsa has 5 apples and Anna has 2 more apples than Elsa, how many apples do they have together?

Answer: Let's break down this rephrased problem: 1. How many apples does Anna have? 2. How many apples do Elsa and Anna have together?
1. Anna has 2 more apples than Elsa. So Anna has 2 + 5 = 7 apples.
2. Elsa and Anna have 5 + 7 = 12 apples together.

Question: {qst}
Problem Elaboration:"
```

### exemplars for CoT

```
Question: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together?
Answer: Anna has 2 more apples than Elsa, so Anna has 2 + 5 = 7 apples. Elsa and Anna have 5 + 7 = 12 apples together. The answer is 12.

Question: Four years ago, Kody was only half as old as Mohamed. If Mohamed is currently twice 30 years old, how old is Kody?
Answer: We were told that Mohamed is currently twice 30 years old, so he is currently 30 * 2 = 60 years old. That means that four years ago he must have been 60 - 4 = 56 years old. Four years ago, Kody was half as old as Mohamed, so Kody must have been 56 / 2 = 28 years old then. Since Kody was 28 years old four years ago, she must now be 28 + 4 = 32 years old. The answer is 32.

Question: Carla bought 2 bags of mini peanut butter cups on clearance. Each bag was $6.00 but was 75% off. How much did she spend on 2 bags of candy?
Answer: Each bag was $6.00 but was 75% off. So each bag cost $6.00 * (1 - 0.75) = $6.00 * 0.25 = $1.50. Carla bought 2 bags. So she spent $1.50 * 2 = $3.00. The answer is 3.

Question: If Pam is currently twice as young as Rena is, and in 10 years Rena will be 5 years older than her, how old is Pam now?
Answer: Since Rena will be 5 years older than Pam in 10 years, she must be 5 years older than Pam now as well. If Pam is currently twice as young as Rena, that means that Rena is currently twice as old as Pam is. So if P stands for Pam's age now and R stands for Rena's age now, then we know that R = 2 * P And since Rena is 5 years older than Pam now, we know that R = P + 5. By substitution, we have P + 5 = 2 * P, which means that P = 5. The answer is 5.
```

### exemplars for PEP

```
Question: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together?
Problem Elaboration:
Segment 1: Elsa has 5 apples. This segment tells us the number of apples Elsa has.
Segment 2: Anna has 2 more apples than Elsa. This segment tells us that Anna has more apples than Elsa, specifically 2 more.
Segment 3: How many apples do they have together? This segment is asking us to find the total number of apples both Elsa and Anna have combined.
Solution:
Step 1: Determine the number of apples Elsa has. Elsa has 5 apples.
Step 2: Determine the number of apples Anna has. Anna has 2 more apples than Elsa, so she has 5 + 2 = 7 apples.
Step 3: Determine the total number of apples they have together. Together, Elsa and Anna have 5 + 7 = 12 apples. The answer is 12.

Question: Four years ago, Kody was only half as old as Mohamed. If Mohamed is currently twice 30 years old, how old is Kody?
Problem Elaboration:
Segment 1: Four years ago, Kody was only half as old as Mohamed. This means that the age difference between Kody and Mohamed is constant and it is the same four years ago as it is now.
Segment 2: If Mohamed is currently twice 30 years old. This means that Mohamed's current age is 60 years old.
Solution:
Step 1: Determine Mohamed's age four years ago. If Mohamed is currently 60 years old, then four years ago he was 60 - 4 = 56 years old.
Step 2: Determine Kody's age four years ago. Since Kody was half as old as Mohamed four years ago, then Kody was 56 / 2 = 28 years old four years ago.
Step 3: Determine Kody's current age. If Kody was 28 years old four years ago, then Kody is currently 28 + 4 = 32 years old. The answer is 32.

Question: Carla bought 2 bags of mini peanut butter cups on clearance. Each bag was $6.00 but was 75% off. How much did she spend on 2 bags of candy?
Problem Elaboration:
Segment 1: Identify the original price of the bags of candy. The original price of each bag of candy is $6.00.
Segment 2: Determine the discount on each bag. The bags are 75% off.
Segment 3: Calculate the discounted price of each bag. To find the discounted price, we need to calculate 75% of $6.00.
Segment 4: Determine the total cost for 2 bags. Once we have the discounted price of one bag, we multiply it by 2 to find the total cost for 2 bags.
Solution: Step 1: The original price of each bag is $6.00. Step 2: The discount on each bag is 75%. Step 3: To calculate 75% of $6.00, we multiply 6 by 0.75, which equals $4.50. This means that $4.50 is the amount of the discount. Step 4: To find the discounted price of each bag, we subtract the discount from the original price. So, $6.00 - $4.50 = $1.50. Each bag costs $1.50 after the discount. Step 5: To find the total cost for 2 bags, we multiply the discounted price by 2. So, $1.50 * 2 = $3.00. The answer is 3.

Question: If Pam is currently twice as young as Rena is, and in 10 years Rena will be 5 years older than her, how old is Pam now?
Problem Elaboration:
Segment 1: Pam is currently twice as young as Rena is. This means that Pam's current age is half of Rena's current age.
Segment 2: In 10 years, Rena will be 5 years older than Pam. This means that if we add 10 years to both Pam's and Rena's current ages, the difference between their ages will be 5 years.
Solution:
Step 1: Let's denote Rena's current age as R and Pam's current age as P. From the first segment, we know that P = R/2.
Step 2: From the second segment, we know that R + 10 = P + 10 + 5. We can simplify this to R = P + 5.
Step 3: Now we can substitute P from the first equation into the second equation. So, R = R/2 + 5.
Step 4: To solve for R, we multiply both sides of the equation by 2 to get rid of the fraction. This gives us 2R = R + 10.
Step 5: Subtract R from both sides to get R = 10. So, Rena is currently 10 years old.
Step 6: Substitute R = 10 into the first equation to find P. This gives us P = 10/2 = 5. So, Pam is currently 5 years old. The answer is 5.
```

### exemplars for L2M

```
Question: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together?
Answer: Let's break down this problem: 1. How many apples does Anna have? 2. How many apples do Elsa and Anna have together?
1. Anna has 2 more apples than Elsa. So Anna has 2 + 5 = 7 apples.
2. Elsa and Anna have 5 + 7 = 12 apples together. The answer is 12.

Question: Four years ago, Kody was only half as old as Mohamed. If Mohamed is currently twice 30 years old, how old is Kody?
Answer: Let's break down this problem: 1. How old was Mohamed four years ago? 2. How old is Kody?
1. We were told that Mohamed is currently twice 30 years old, so he is currently 30 * 2 = 60 years old. That means that four years ago he must have been 60 - 4 = 56 years old.
2. Four years ago, Kody was half as old as Mohamed, so Kody must have been 56 / 2 = 28 years old then. Since Kody was 28 years old four years ago, she must now be 28 + 4 = 32 years old. The answer is 32.

Question: Carla bought 2 bags of mini peanut butter cups on clearance. Each bag was $6.00 but was 75% off. How much did she spend on 2 bags of candy?
Answer: Let's break down this problem: 1. How much did she spend on 2 bags of candy?
1. Each bag was $6.00 but was 75% off. So each bag cost $6.00 * (1 - 0.75) = $6.00 * 0.25 = $1.50. Carla bought 2 bags. So she spent $1.50 * 2 = $3.00. The answer is 3.

Question: If Pam is currently twice as young as Rena is, and in 10 years Rena will be 5 years older than her, how old is Pam now?
Answer: Let's break down this problem: 1. How much older is Rena than Pam currently? 2. How old is Pam now?
1. Since Rena will be 5 years older than Pam in 10 years, she must be 5 years older than Pam now as well.
2. If Pam is currently twice as young as Rena, that means that Rena is currently twice as old as Pam is. So if P stands for Pam's age now and R stands for Rena's age now, then we know that R = 2 * P And since Rena is 5 years older than Pam now, we know that R = P + 5. By substitution, we have P + 5 = 2 * P, which means that P = 5. The answer is 5.
```

### exemplars for Self-ask

```
Question: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together?
Are follow up questions needed here: Yes.
Follow up: How many apples does Anna have?
Intermediate answer: Anna has 5 + 2 = 7 apples.
Follow up: How many apples do Elsa and Anna have together?
Intermediate answer: Elsa and Anna have 5 + 7 = 12 apples together. The answer is 12.

Question: Four years ago, Kody was only half as old as Mohamed. If Mohamed is currently twice 30 years old, how old is Kody?
Are follow up questions needed here: Yes.
Follow up: How old is Mohamed currently?
Intermediate answer: Mohamed is 30 * 2 = 60 years old. Follow up: How old was Kody four years ago?
Intermediate answer: Kody was (60 - 4) / 2 = 28 years old four years ago.
So the final answer is: Kody is 28 + 4 = 32 years old. The answer is 32.

Question: Carla bought 2 bags of mini peanut butter cups on clearance. Each bag was $6.00 but was 75% off. How much did she spend on 2 bags of candy?
Are follow up questions needed here: Yes.
Follow up: How much was the discount for each bag?
Intermediate answer: The discount for each bag is $6.00 * 75% = $4.50.
Follow up: How much did Carla pay for each bag after the discount?
Intermediate answer: Carla paid $6.00 - $4.50 = $1.50 for each bag.
So the final answer is: Carla spent $1.50 * 2 = $3.00 on 2 bags of candy. The answer is 3.00.

Question: If Pam is currently twice as young as Rena is, and in 10 years Rena will be 5 years older than her, how old is Pam now?
Are follow up questions needed here: Yes.
Follow up: What about Rena and Pam's current ages?
Intermediate answer: It tells us that Rena's age is twice Pam's age. So if P stands for Pam's age now and R for Rena's age now, then R = 2 * P. And since Rena is 5 years older than Pam now, we have R = P + 5.
Follow up: What is Pam's age now?
Final answer: By substituting P + 5 in place of R in equation R = 2 * P, we get P + 5 = 2 * P, which simplifies to P = 5. So, Pam is 5 years old. The answer is 5.
```

It's worth noting that the template recommended in self-ask [Press2022MeasuringAN] actually ends with "Are follow up questions needed here:", but we found it always generates a "Yes" or "No" and then stops, especially in one-shot setting. Therefore, we made above adjustments.

### exemplars of PaS

```
Question: Elsa has 5 apples. Anna has 2 more apples than Elsa. How many apples do they have together?
Plan:
Step 1: Find out how many apples Anna has.
Step 2: Add the number of apples Elsa has to the number of apples Anna has to find the total number of apples they have together.
Solution:
Step 1: Anna has 5 + 2 = 7 apples.
Step 2: Together, Elsa and Anna have 5 (Elsa's apples) + 7 (Anna's apples) = 12 apples. So, Elsa and Anna have 12 apples together. The answer is 12.

Question: Four years ago, Kody was only half as old as Mohamed. If Mohamed is currently twice 30 years old, how old is Kody?
Plan:
Step 1: Find out how old Mohamed is currently.
Step 2: Find out how old Mohamed was four years ago.
Step 3: Since Kody was half as old as Mohamed four years ago, find out Kody's age four years ago.
Step 4: Add four years to Kody's age to find out his current age.
Solution:
Step 1: Mohamed is currently 2 * 30 = 60 years old.
Step 2: Four years ago, Mohamed was 60 - 4 = 56 years old.
Step 3: Four years ago, Kody was 56 / 2 = 28 years old. Step 4: Currently, Kody is 28 + 4 = 32 years old. So, Kody is 32 years old. The answer is 32.

Question: Carla bought 2 bags of mini peanut butter cups on clearance. Each bag was $6.00 but was 75% off. How much did she spend on 2 bags of candy?
Plan:
Step 1: Find out how much discount Carla got on each bag.
Step 2: Subtract the discount from the original price to find out the price Carla paid for each bag. Step 3: Multiply the price Carla paid for each bag by the number of bags she bought to find out how much she spent in total.
Solution:
Step 1: The discount on each bag is 75/100 * $6.00 = $4.50.
Step 2: The price Carla paid for each bag is $6.00 - $4.50 = $1.50.
Step 3: Carla spent $1.50 * 2 = $3.00 on 2 bags of candy. So, Carla spent $3.00 on 2 bags of candy. The answer is 3.00.

Question: If Pam is currently twice as young as Rena is, and in 10 years Rena will be 5 years older than her, how old is Pam now?
Plan:
Step 1: Set up an equation based on the information that Rena's age is twice Pam's age.
Step 2: Set up another equation based on the information that Rena is 5 years older than Pam.
Step 3: Substitute the second equation into the first to solve for Pam's age.
Solution:
Step 1: If P stands for Pam's age now and R for Rena's age now, then R = 2 * P.
Step 2: And since Rena is 5 years older than Pam now, we have R = P + 5.
Step 3: By substituting P + 5 in place of R in equation R = 2 * P, we get P + 5 = 2 * P, which simplifies to P = 5. So, Pam is 5 years old. The answer is 5.
```

## Implementation of PoT

We implement PoT using the following template. For PEP, we insert null into {ela}. For the PoT+PEP, we first use zero-shot PEP to generate the content for the Elaboration part, and then insert it into {ela}.

```
PoT_zeroshot_temp = "# Question: {qst}
{ela}

# Answer the question by implementing a solution() function.
# Generate the code only.
# Let's write a Python program step by step, and then return the answer
# Firstly, we need write the solution() starting with defining variable:"
```

# Appendix: Example Input and Output Pairs

We provide more error cases. As shown, LLMs could also make mistakes during elaboration, misleading the following reasoning. PEP may break down the continuous context, thus changing the implicit implicatures. Besides, PEP may focus too much on the locality of sentences, constraining the associative thinking of CoT.
