# Abstract

While the recent Chain-of-Thought (CoT) technique enhances the reasoning ability of large language models (LLMs) with the theory of mind, it might still struggle in handling logical reasoning that relies much on symbolic expressions and rigid deducing rules. To strengthen the logical reasoning capability of LLMs, we propose a novel Symbolic Chain-of-Thought, namely **SymbCoT**, a fully LLM-based framework that integrates symbolic expressions and logic rules with CoT prompting. Technically, building upon an LLM, SymbCoT 1) first translates the natural language context into the symbolic format, and then 2) derives a step-by-step plan to solve the problem with symbolic logical rules, 3) followed by a verifier to check the translation and reasoning chain. Via thorough evaluations on 5 standard datasets with both First-Order Logic and Constraint Optimization symbolic expressions, SymbCoT shows striking improvements over the CoT method consistently, meanwhile refreshing the current state-of-the-art performances. We further demonstrate that our system advances in more faithful, flexible, and explainable logical reasoning. To our knowledge, this is the first to combine symbolic expressions and rules into CoT for logical reasoning with LLMs. Code is open at <https://github.com/Aiden0526/SymbCoT>.

[IMAGE: An illustrative example of logical reasoning via Chain-of-Thought and our proposed Symbolic CoT (SymbCoT).]

# Introduction

Achieving human-like logical reasoning capabilities is crucial for realizing AGI, which plays a pivotal role in enabling intelligent systems to engage in problem-solving, decision-making, and critical thinking. Recently, LLMs [gpt3; palm] have demonstrated unprecedented capabilities in semantic understanding, casting a beacon of hope toward achieving AGI. Further enhancing LLMs to achieve human-level reasoning abilities, particularly in logical reasoning, is of paramount importance. Logical reasoning [logic-reasoning1] stands out as a quintessential form of reasoning that, unlike other types, is crucial and challenging. It epitomizes a cognitive process characterized by rigorous evidence evaluation, argument construction, and logical deduction [logic-reasoning2]. The latest trend is integrating LLMs with symbolic solvers to enhance their performance [linc; pan-etal-2023-logic]. Unfortunately, these efforts have been limited to using LLMs merely as text-to-symbolic translators, with the core reasoning still reliant on traditional external reasoners [prover9]. Such an approach, first, does not intrinsically strengthen LLMs' capability in logical reasoning. Besides, over-reliance on external symbolic solvers often results in inflexibility, information omission, and unexplainability.

[IMAGE: Overview of the workflow in our proposed symbolic CoT framework.]

On another note, the concept of CoT [cot] has been introduced to mimic human thinking processes by encouraging LLMs to explicitly consider intermediate steps during problem-solving and to provide rationales for decisions, thereby enhancing the reliability of the reasoning process. CoT has been successfully integrated into a wide array of tasks [auto-cot; implicit_cot; multitool-cot], significantly improving LLMs' reasoning capabilities, sometimes even matching human performance in certain scenarios [human-performance]. There is growing interest in applying CoT for logical reasoning [logic-reasoning], and developing advanced strategies such as self-consistency [CoT-SC] and Tree-of-Thought [ToT] for enhancement. However, applying basic CoT directly to logical reasoning is inherently limited, due to the abstractive nature of language expression. Logical reasoning demands rigorous logical calculations, heavily relying on both symbolic expressions and rigid deducing rules to represent the internal structure of problems. Plain texts often fall short of supporting such precise logic, especially in scenarios that demand strict logical representation. For instance, when tackling a logical reasoning problem, utilizing symbolic representations like First-Order Logic (FOL) is more representative and precise than fully natural language rationales in CoT, enabling strict logical reasoning through clear inference rules.

To address these challenges, we introduce a novel Symbolic CoT (namely **SymbCoT**) for logical reasoning. Unlike existing state-of-the-art (SoTA) LLM-based symbolic reasoning systems [linc; pan-etal-2023-logic], SymbCoT is entirely facilitated by LLMs without relying on any external reasoners/tools, i.e., encompassing both the initial translation and subsequent reasoning phases. Technically, SymbCoT comprises four main modules: _Translator_, _Planner_, _Solver_, and _Verifier_. Notably, SymbCoT is characterized by the following three core aspects:

- SymbCoT integrates symbolic expressions into CoT to describe intermediate reasoning processes, facilitating more precise logical calculations. However, relying solely on symbolic representation still has its limitations, as it often fails to capture certain content, such as implicit intentions or crucial contextual information embedded within questions. Yet LLMs excel at interpreting such nuanced information and contexts. Thus, we consider a combination of symbolic and natural language expressions to leverage the mutual strengths of both: freely expressed implicit intents and contextual information in natural language and rigorous expression in symbolic forms.

- Unlike the straightforward prompting of "_thinking step by step_" in vanilla CoT, SymbCoT considers a _plan-then-solve_ architecture. This involves decomposing the original complex problem into a series of smaller, more manageable sub-problems, which are then addressed one by one. This way, the entire reasoning process becomes more trackable, enabling a clearer and more structured approach to problem-solving.

- Furthermore, we devise a retrospective verification mechanism. At both the translation and subsequent problem-solving stages, we retrospectively validate the correctness of each step's outcome, by tracing back to the original given condition. This verification process ensures the accuracy and reliability of the operations performed during the reasoning process.

In experiments, we test SymbCoT with symbolic expressions of FOL and Constraint Optimization (CO) on five logical reasoning datasets using both GPT-3.5 and GPT-4. Results demonstrate that SymbCoT significantly enhances the reasoning capabilities of vanilla CoT, outperforming current SoTA solutions clearly. We further demonstrate that the more complex the logical reasoning task, the more pronounced the improvement of SymbCoT over vanilla CoT, further with the verification mechanism ensuring the faithfulness of the reasoning process. Our in-depth analysis reveals that fully LLM-based logical reasoning can offer better symbolic syntax robustness, human-readable explanations, and fuller utilization of information.

In summary, our technical contributions are:

- proposing a fully LLM-based logical reasoning framework based on CoT, demonstrating that LLMs can achieve robust logical reasoning capabilities without external reasoning tools. Compared to existing SoTA solutions relying on external resolvers, SymbCoT offers better robustness against translation errors and more human-understandable explanations.

- innovatively integrating the strengths of symbolic forms and natural language expressions, enabling precise reasoning calculations while fully interpreting implicit information and capturing rich contexts.

- introducing a plan-then-solve architecture for CoT reasoning, along with a retrospective verification mechanism, enhancing the faithfulness of the reasoning process.

# Related work

Recent achievements in reasoning research powered by LLMs have shown promising results [logic-reasoning; human-performance], bringing LLMs closer to human-level reasoning capabilities due to their profound semantic understanding [wu2023next; FeiMatchStruICML22]. Among these, the CoT series methodology [cot] has garnered increasing attention for its emulation of human discrete chain reasoning. By considering more intermediate steps and the rationales behind decision-making, CoT has significantly enhanced overall reasoning performance on many downstream applications [implicit_cot; fei2024video]. Subsequent technologies have introduced more advanced reasoning frameworks, incorporating mechanisms such as self-consistency and non-linear, multidimensional topological structures, e.g., Tree-of-Thought [ToT], Graph-of-Thought [got; zheng2024reverse], and other variants [auto-cot; plan-and-solve].

However, research has also highlighted limitations within CoT due to its reliance on natural language rationales, which may not always be advantageous in certain scenarios. Studies have found that representing CoT's intermediate steps in a structured manner, reflecting the task's intrinsic structure, can bolster reasoning capabilities for specific tasks [code-prompting; mathprompter]. For instance, using pseudo-code to describe intermediate reasoning processes has been shown to enhance outcomes in code generation tasks [SCoT], while adopting mathematical equations for CoT's steps has proven beneficial in solving mathematical problems [mathprompter]. Focusing on logical reasoning, it becomes evident that solely using natural language formats for intermediate reasoning steps inevitably leads to significant information loss, especially when tackling complex logical reasoning jobs. This paper, therefore, proposes a symbolic-oriented CoT approach tailored for logical reasoning.

Logical reasoning [logic-reasoning1], a paramount aspect of the reasoning domain, demands models that can precisely grasp and manipulate complex logical structures. Previous works have explored rule-based [prover9] and neural-based solving [neural-logic2; neural-logic] methods for interpreting symbolic representations. The latest trend involves integrating LLMs into the symbolic reasoning process [llm_symbolic_generation; llm_symbolic_math]. For example, Logic-LM [pan-etal-2023-logic] and LINC [linc] consider using LLMs as translators to convert natural language into symbolic syntax such as FOL, which is then processed by external reasoning tools to enhance reasoning performance. These approaches maintain that LLMs cannot parse symbolic expressions as reliably as external rule-based reasoners.

Nonetheless, merely utilizing LLMs as translators does not inherently enhance their logical reasoning capabilities. This work pioneers the development of the first symbolic CoT specifically designed for logical reasoning, fully utilizing LLMs. In contrast to approaches like Logic-LM and LINC, our method demonstrates several advancements: First, external reasoners require strict formatting, where any translation error by LLMs can lead to failure in parsing and reasoning. Our reasoning steps, facilitated by the LLM, exhibit greater robustness against syntax errors. Second, the entire reasoning process is conducted by the LLM, providing rationales that ensure a more human-friendly explanation throughout. Third, we propose a blend of symbolic forms and natural language expressions within the logical reasoning process, achieving precise reasoning calculations while fully interpreting implicit information inherent in natural language. Finally, we introduce a plan-then-solve CoT reasoning architecture and a verification mechanism, ensuring the faithfulness of the reasoning process.

# SymbCoT for Symbolic Reasoning

## Task Definition

The logical reasoning is defined as: formally, given a set of premises `latex $P = \{p_1, p_2, \ldots, p_n\}$ `, where each `latex $p_i$ ` represents a logical statement, we aim to derive a conclusion regarding a given statement `latex $S$ `. The objective is to determine whether `latex $S$ ` is true (`latex $T$ `), false (`latex $F$ `), or unknown (`latex $U$ `) based on the logical inferences drawn from the premises.

**Example:**

<Premises> (P)
A hawk never lands. Some birds are hawks.

<Statement> (S)
All birds land.

<Answer>
False.

## Modules

Our SymbCoT system is fully supported by LLMs and comprises four distinct modules: **Translator**, **Planner**, **Solver**, and **Verifier**, whose roles are elaborated as follows.

#### Translator

converts the premises and a question statement from natural language to a symbolic format. This process prepares the input in a way that aligns with the structured requirements of subsequent reasoning processes, ensuring that the reasoning problems are represented in a format conducive to logical analysis.

#### Planner

breaks down the raw problem into smaller sub-problems, which develop a detailed, step-by-step plan that connects the given premises to the question statement in both natural language and symbolic form. This blueprint guides the structured reasoning process by outlining a logical sequence of steps.

#### Solver

is tasked with deriving the answer through a sequential logical inference process given the premises and question statement, along with a meticulously crafted plan. The Solver module emphasizes the importance of basing logical deductions on symbolic inference rules. For instance, the LLM is explicitly instructed to apply logical deduction techniques adhering to FOL such as Modus Tollens [modus], e.g., If `latex $\neg B$ `, and `latex $(A \to B)$ `, then `latex $\neg A$ `. This ensures that each step in the reasoning process is grounded in established logical frameworks, to draw accurate and reliable conclusions.

#### Verifier

serves two functions in our framework. First, it validates the correctness of symbolic translations by prompting the LLM to ascertain their semantic equivalence to the corresponding natural language. If discrepancies are identified, the language model refines the symbolic translation based on the original natural language to ensure semantic consistency. Second, it verifies the output of the Solver containing step-by-step logical reasoning with the final answer. During this verification process, the Verifier scrutinizes each logic deduction made, to ensure they strictly comply with the principles of formal logic. If invalid logic is found, the Verifier refines the reasoning steps according to the correct logic to arrive at a new answer. These ensure both the fidelity and reliability of symbolic translations and logical reasoning soundness.

## Reasoning Steps

We now walk through the SymbCoT reasoning steps with detailed examples.

#### Step 1: Translating natural language context into symbolic.

Given the original set of premises `latex $P = \{p_1, p_2, \ldots, p_n\}$ ` and the question statement `latex $S$ `, the Translator will first interpret them into the corresponding symbolic format, denoted as `latex $P' = \{p'_1, p'_2, \ldots, p'_n\}$ ` and `latex $S'$ `. We concatenate the natural language and symbolic expression `latex $P$ ` and `latex $P'$ ` as `latex $P_c$ `, `latex $S$ ` and `latex $S'$ ` as `latex $S_c$ `, i.e., hybrid format expressions for the future steps of reasoning.

**Input:**
Please parse the context and question into First-Order Logic formulas.

<Premises> (P)
If a cartoon character is yellow, it is from the Simpsons.
If a cartoon character is from Simpsons, then it is loved by children.
(... More premises ...)

<Statement> (S)
Ben is ugly or yellow.

**Output:**
<Premises> (P')
`latex $\forall x \, (Yellow(x) \rightarrow Simpsons(x))$ `
`latex $\forall x \, (Simpsons(x) \rightarrow Loved(x))$ `
(... More premises ...)

<Statement> (S')
`latex $(Yellow(ben) \lor Ugly(ben))$ `

#### Step 2: Deriving plan based on the natural and symbolic context.

At this stage, the Planner module, utilizing `latex $P_c$ ` and `latex $S_c$ `, constructs a plan comprising intermediate steps `latex $I = \{i_1, i_2, \ldots, i_m\}$ `. These steps form logical inferences sequentially bridging the premises `latex $P_c$ ` towards the question statement `latex $S_c$ `.

**Input:**
Please derive a step-by-step plan using the First-Order Logic rule for determining the conclusion based on the context.

<Premises> (P_c)
If a cartoon character is yellow, it is from the Simpsons ::: `latex $\forall x \, (Yellow(x) \rightarrow Simpsons(x))$ `
If a carton character is from Simpsons, then it is loved by children: `latex $\forall x \, (Simpsons(x) \rightarrow Loved(x))$ `
(... More premises ...)

<Statement> (S_c)
Ben is ugly or yellow ::: `latex $(Yellow(ben) \lor Ugly(ben))$ `

**Output:**
<Plan> (I)
1: Identify the relevant premise of Ben.
2: Identify the relevant premise of yellow and ugly.
(... More plan ...)

#### Step 3: Solving the problem given context and plan.

Here, the Solver operates on the premises `latex $P_c$ `, the question statement `latex $S_c$ `, and the plan `latex $I$ `, by systematically applying logic rules. It iteratively selects pertinent premises and infers new insights through a sequence of reasoning steps, represented as `latex $D = \{d_1, d_2, \ldots, d_l\}$ `. Here, each `latex $d_k$ ` signifies an insight inferred from the relevant premises during the iteration process, contributing to the elucidation of `latex $S_c$ `. This iterative methodology leads to a conclusive determination `latex $C$ `, assigning the statement `latex $S_c$ ` as true (`latex $T$ `), false (`latex $F$ `), or uncertain (`latex $U$ `).

**Input:**
Please solve the question based on First-Order Logic rules such as Modus Ponens...

<Premises> (P_c)
If a cartoon character is yellow, it is from the Simpsons: `latex $\forall x \, (Yellow(x) \rightarrow Simpsons(x))$ `
If a carton character is from Simpsons, then it is loved by children: `latex $\forall x \, (Simpsons(x) \rightarrow Loved(x))$ `
(... More premises ...)

<Statement> (S_c)
Ben is ugly or yellow ::: `latex $(Yellow(ben) \lor Ugly(ben))$ `

<Plan> (I)
1: Identify the relevant premise of Ben.
2: Identify the relevant premise of yellow and ugly.
(... More plan ...)

**Output:**
<Reasoning Steps> (D)
Step 1: Yellow(ben) -> Simpsons(ben) by Modus Ponens from premise 1.
Step 2: Simpsons(ben) -> Loved(ben) by Modus Ponens from premise 2.
(... More steps ...)

<Conclusion> (C)
Thus, we can conclude that `latex $(Yellow(ben) \lor Ugly(ben))$ ` is false by contradiction.

#### Step 4: Verifying the translation and solving process.

Now based on the concatenated inputs `latex $P_c$ ` and `latex $S_c$ ` from Step 1, and the reasoning chain `latex $D$ ` and derived conclusion `latex $C$ ` from Step 3, the Verifier conducts two ways of verification process. First, it checks whether the symbolic language is correctly translated based on the original natural language context, represented as `latex $V_{\text{trans}} = \text{Verify}(P \rightarrow P', S \rightarrow S')$ `. If any incorrect translation is found, the Verifier will undertake refinements to produce a revised translation of the premises and statement, denoted as `latex $P'_{\text{refined}}$ ` and `latex $S'_{\text{refined}}$ `. Second, it will check whether the inference `latex $D$ ` adheres to valid logical rules. If any logical fallacy is detected, the Verifier will conduct a refined derivation `latex $D_{\text{refined}}$ ` using the corrected logic rules. Consequently, these refinements lead to the generation of a refined answer, represented as `latex $C_{\text{refined}}$ `. Upon successful verification as `latex $V_{\text{validity}}(D/D_{\text{refined}})$ `, the Verifier produces a verified answer `latex $C_{\text{verified}}$ `.

**Input:**
Please verify: 1) the symbolic context is consistent with the natural language; 2) the solving step is logically valid.

<Premises> (P_c)
If a cartoon character is yellow, it is from the Simpsons: `latex $\forall x \, (Yellow(x) \rightarrow Simpsons(x))$ `
If a carton character is from Simpsons, then it is loved by children: `latex $\forall x \, (Simpsons(x) \rightarrow Loved(x))$ `
(... More premises ...)

<Statement> (S_c)
Ben is ugly or yellow ::: `latex $(Yellow(ben) \lor Ugly(ben))$ `

<Reasoning Steps> (D)
Step 1: Yellow(ben) -> Simpsons(ben) by Modus Ponens from premise 1.
Step 2: Simpsons(ben) -> Loved(ben) by Modus Ponens from premise 2.
(... More steps ...)

<Conclusion> (C)
Thus, we can conclude that `latex $(Yellow(ben) \lor Ugly(ben))$ ` is false by contradiction.

**Output:**
<Translation Verification> (P/P'\_refined) and (S/S'\_refined)

1. Verify context consistency: "If a cartoon character is yellow, it is from the Simpsons" is semantically consistent with "`latex $\forall x \, (Yellow(x) \rightarrow Simpsons(x))$ `"
   (... More translation verification ...)

<Logic Verification> (D/D_refined) 2. Verify solving logic step by step: Step 1 correctly implement Modus Ponens using premise 1; Step 2 correctly implement Modus Ponens using premise 2;
(... More logic verification ...)

<Conclusion Verification> (C_verified/C_refined)
Thus, the solving process is logically valid. The answer is verified to be false.

# Experiments

## Settings

#### Model.

Following prior work of Logic-LM [pan-etal-2023-logic], we assess the baselines and our method using GPT-3.5 [DBLP:conf/nips/Ouyang0JAWMZASR22] and GPT-4 [gpt4], ensuring a fair comparison with identical model parameters.

#### Dataset.

Five standard datasets are employed, including PrOntoQA [DBLP:conf/iclr/Saparov023], ProofWriter [proofwriter], FOLIO [folio], LogicalDeduction [DBLP:journals/corr/abs-2206-04615], and AR-LSAT [ar]. Each of them takes different symbolic representations and introduces its own set of challenges in the topic of logical reasoning. The primary metric for evaluation is accuracy, measuring the multiple-choice correctness of the questions.

#### Symbolic Structure.

In datasets PrOntoQA, ProofWriter, and FOLIO, we use FOL as symbolic structure. To test the generalizability of our framework among different symbolic structures, we further consider the CO symbolic expression in datasets LogicalDeduction and AR-LSAT.

**Table 1: Performance on symbolic reasoning with First-Order Logical representation (GPT-3.5-turbo)**

| Method      | ProntoQA  | ProofWriter | FOLIO     | Avg       |
| ----------- | --------- | ----------- | --------- | --------- |
| Naive       | 47.40     | 35.50       | 45.09     | 42.66     |
| CoT         | 67.80     | 49.17       | 57.35     | 58.11     |
| Logic-LM    | 61.00     | 58.33       | **62.74** | 60.69     |
| **SymbCoT** | **75.80** | **59.03**   | 57.84     | **64.22** |
|             | (+8.00)   | (+0.70)     | (-4.90)   | (+3.53)   |

**Table 1 (continued): Performance on symbolic reasoning with First-Order Logical representation (GPT-4)**

| Method      | ProntoQA  | ProofWriter | FOLIO     | Avg       |
| ----------- | --------- | ----------- | --------- | --------- |
| Naive       | 77.40     | 52.67       | 69.11     | 66.39     |
| CoT         | 98.79     | 68.11       | 70.58     | 79.16     |
| CoT-SC      | -         | 69.33       | 68.14     | -         |
| ToT         | -         | 70.33       | 69.12     | -         |
| CR          | -         | 71.67       | 69.11     | -         |
| DetermLR    | -         | 79.17       | 75.45     | -         |
| Logic-LM    | 83.20     | 79.66       | 78.92     | 80.59     |
| **SymbCoT** | **99.60** | **82.50**   | **83.33** | **88.47** |
|             | (+0.81)   | (+2.84)     | (+4.41)   | (+7.88)   |

**Table 2: Results (using GPT-4) on symbolic reasoning with Constraint Optimization representation**

| Method      | LogicalDeduction | AR-LSAT   | Avg       |
| ----------- | ---------------- | --------- | --------- |
| Naive       | 71.33            | 33.33     | 52.33     |
| CoT         | 75.25            | 35.06     | 55.14     |
| CoT-SC      | 74.67            | -         | -         |
| ToT         | 76.83            | -         | -         |
| CR          | 78.33            | -         | -         |
| DetermLR    | 85.00            | -         | -         |
| Logic-LM    | 87.63            | 43.04     | 65.34     |
| **SymbCoT** | **93.00**        | **43.91** | **68.46** |
|             | (+5.37)          | (+0.87)   | (+3.12)   |

#### Baseline.

We compare with a range of established baselines. Those based on GPT-3.5 are: 1) Naive Prompting; 2) CoT [cot]; 3) Logic-LM [pan-etal-2023-logic]. On GPT-4, apart from the above baselines, we further include more systems: 4) CoT-SC [CoT-SC]; 5) ToT [ToT]; 6) Cumulative Reasoning [CR]; 7) DetermLR [DetermLR].

## Main Result

Our method significantly outperforms Naive, CoT, and Logic-LM baselines, with gains of 21.56%, 6.11%, 3.53% on GPT-3.5, and 22.08%, 9.31% and 7.88% on GPT-4, respectively. We notice the only exception is on the FOLIO dataset with GPT-3.5, failing to surpass Logic-LM. The underperformance points to challenges in non-linear reasoning, reflecting the inherent challenge for LLMs. But, our approach notably surpasses all baselines across both datasets with GPT-4, especially outperforming Logic-LM by an average of 7.88%, which demonstrates significant improvements in complex reasoning tasks. Our approach surpasses both CoT and Logic-LM by 13.32% and 3.12%, respectively on CO symbolic expression, again demonstrating its general versatility in different symbolic reasoning expressions.

[IMAGE: Ablation study. Since the Solver is dependent on the Planner, they have to be ablated simultaneously.]

## Model Ablation

To ascertain the individual impact of each module within our framework, we perform an ablation study. The patterns reveal that the contributions to the overall efficacy of our method vary across modules on GPT-4. Notably, the Planner and Solver components are identified as the most influential, enhancing performance by an average of 10.4%, followed by the Translator module, which facilitates a secondary improvement of 6.3%. The finding highlights the efficacy of our proposed _plan-then-solve_ design for conquering the raw questions by dividing them into smaller ones. Additionally, the use of symbolic representation and rules shows significant reasoning enhancement.

[IMAGE: The effect of reasoning depth with GPT-4 on ProofWriter. The red dual-head arrow indicates our improvements over vanilla CoT.]

[IMAGE: Execution rate between Logic-LM and Ours.]

# Analysis and Discussion

We now delve into our system further and try to explore _why_ it advances.

## Performance on Complex Reasoning

In our direct comparison of overall performance, we have demonstrated that our approach surpasses the baseline, particularly noting a significant enhancement in the performance of the CoT. Now, we delve deeper into analyzing the performance of different methods across varying levels of reasoning depth. Intuitively, a greater depth indicates more complex problems. As the depth increases, the improvement over CoT becomes more pronounced, suggesting that our advantage lies in tackling more challenging issues. Moreover, even at a reasoning depth of 5, our method continues to achieve the best performance.

## Robustness to Symbolic Syntax Error

We conduct a comparative analysis of our fully LLM-based reasoner against methods that rely on external resolvers, such as Logic-LM, specifically focusing on the success rate of executing symbolic expression syntax. Notably, our method achieves a remarkable execution success rate of up to 100%. This represents a significant improvement over Logic-LM by an average of 17.7% percentage points. Our approach notably enhances the execution rate on the AR-LSAT. It boosts the success rate by 67.4% from Logic-LM, where LLMs are more prone to translating syntax errors. Remarkably, our method consistently executes with 100% success, showcasing remarkable robustness against syntax errors.

[IMAGE: The left pie shows the error proportion from the external solver due to 1) Information Loss (IL), 2) Information Error (IE), and Others. The bar chart consists of two parts. The left bar shows the false rate from the external solver made by IL/IE adding up to 100%. The right bar shows the reduced false rates via our method.]

[IMAGE: The proportion of faithful, unfaithful, and false answers. Faithful/unfaithful denotes whether the predicted correct answer is derived from valid and reasonable logical reasoning.]

## Benefit of Hybrid Expression of Symbolic And Natural Language

LLM's translations from natural to symbolic language sometimes omit crucial information or introduce inaccuracies, leading to flawed symbolic representations. Our analysis examines errors in cases wrongfully categorized as 'unknown' by external solvers on FOLIO. We identify that 55.6% of these errors were due to information loss (IL, 40.7%)---where essential details are missed---and information error (IE, 14.8%)---where translations are incorrect. Implementing our methodology reduces these errors by 73.3%, with significant declines in IL and IE by 53.8% and 19.5%, respectively. This demonstrates the effectiveness of our LLM-based symbolic reasoning approach, which cross-references both symbolic and natural language data to rectify translation errors and bolster logical reasoning.

[IMAGE: The Improvement from GPT-3.5 to GPT-4.]

## Reasoning Faithfulness

Often, LLMs may deliver correct answers through flawed reasoning, essentially reaching the right conclusion by luck. Thus, we further assess the faithfulness of reasoning in the CoT, our SymbCoT, and SymbCoT without a Verifier on the FOLIO dataset. We define an instance as 'faithful' if both the answer and the process are correct and logical; 'unfaithful' if the answer is correct but the process is not; and 'false' if the answer itself is incorrect. To verify the logical validity of the reasoning process when the answer is correct, we employed manual evaluation. This assessment is carried out by five computer science graduate students with adequate training, and the logical propriety of a process for a given example was determined based on the majority's opinion. We can see that within the CoT, 6% of correct answers resulted from flawed reasoning, achieved serendipitously rather than through correct logical steps. In SymbCoT without a Verifier, the rate of such unfaithful reasoning dropped to 2%. Integrating a Verifier, we eliminated unfaithful reasoning entirely, showcasing that our approach ensures credible, symbolic-based reasoning and reduces reliance on chance. This highlights the effectiveness of our methodology in enhancing the faithfulness of the reasoning process, with the Verifier serving to verify and refine reasoning steps.

## Impact of Using Different LLMs

Our comparison of GPT-3.5 and GPT-4 on three FOL datasets shows the most performance boost (24.3%) with our method upon upgrading models. This underscores the synergy between our approach and more advanced models. In contrast, methods like Logic-LM, which rely on external rule-based solvers, exhibit the least improvements with stronger models due to their dependence on LLMs for translation rather than reasoning. Thus, although translation quality may improve, reasoning capabilities remain unchanged as it is capped by external solvers. Our fully LLM-based method shows significant improvements compared to external solver-based approaches as model capabilities increase, indicating a promising advancement path in line with LLMs' evolution.

## Error analysis

The error analysis reveals that for an LLM to accurately complete a reasoning task, it requires two key capabilities: 1) The basic planning ability to identify the correct reasoning path, and 2) Upon identifying the reasoning path, ensure that each step of the reasoning is based on valid logic. The development of SymbCoT primarily enhances the second capability. However, the first capability, planning, is equally crucial in problem-solving. Consider a scenario where the model fails to identify the correct path; in such instances, there wouldn't even be an opportunity for logical errors to occur, which our method aims to address. Yet, our approach does not enhance the model's planning capabilities, as these are inherently reliant on the LLM itself. Therefore, the LLM needs to meet this reasoning baseline for SymbCoT to be effective.

## Case Study

Finally, we showcase two instances to demonstrate in detail the advantages of our method.

#### CoT makes logical fallacy.

Our comparison with CoT reveals its susceptibility to logical fallacies, making invalid deductions like affirming the consequent, while our method effectively prevents such errors.

1. **Premise 1:** There was one six-way tie on the leaderboard and one person in the six-way tie was from Belgium.

2. **Premise 2:** Descampe is from Belgium and is on the leaderboard of the 1992 du Maurier Classic.

3. **Question Statement:** Descampe is in the six-way tie in the leaderboard of the 1992 du Maurier Classic. (Ground Truth: Unknown)

4. **GPT-4 Incorrect CoT:** The context states that there was one six-way tie on the leaderboard and one person in the six-way tie was from Belgium. Descampe is from Belgium and is on the leaderboard of the 1992 du Maurier Classic. Therefore, it can be inferred that Descampe is in the six-way tie in the leaderboard of the 1992 du Maurier Classic.

5. **Ours:** From the step from `latex $\exists x (\text{Tie}(x, \text{sixWay}) \land \text{From}(x, \text{Belgium}))$ ` to Tie(Descampe, sixWay) requires a premise directly stating Descampe's involvement in the six-way tie, which is absent such as Tie(Descampe, sixWay). However, this information is not given. Thus, the truth of the statement "Tie(Descampe, sixWay)" remains unknown.

#### External solver fails due to information loss.

Using external solvers like Prover9 for FOL entails translation risks, potentially missing key predicates and reducing accuracy. Our LLM-based approach mitigates this by leveraging its natural language comprehension to better capture the context's intricacies.

1. **Premise 1:** `latex $\forall x (\text{Book}(x)\rightarrow\text{Contains}(x,\text{knowledge}))$ ` ::: Books contain tons of knowledge.

2. **Premise 2:** `latex $\forall x \forall y (\text{Person}(x) \land \text{Reads}(x,y)\rightarrow\text{Gains}(x,\text{knowledge}))$ ` ::: When a person reads a book, that person gains knowledge.

3. **Premise 3:** `latex $\forall x (\text{Person}(x) \land \text{Gains}(x,\text{knowledge})\rightarrow\text{Smarter}(x))$ ` ::: If a person gains knowledge, they become smarter.

4. **Premise 4:** `latex $\text{Reads}(\text{harry},\text{walden})$ ` ::: Harry read the book "Walden" by Henry Thoreau.

5. **Question Statement:** Smarter(harry) ::: Harry is smarter than before. (Ground Truth: True)

6. **Prover9:** Uncertain

7. **Ours:** Since Walden is a book, and according to the premise `latex $\forall x (\text{Book}(x)\rightarrow\text{Contains}(x, \text{knowledge}))$ `, it follows that `latex $\text{Book}(\text{walden}) \rightarrow \text{Contains}(\text{walden}, \text{knowledge})$ `. And Harry reads Walden, which leads to gaining knowledge, as described by the premise `latex $\forall x \forall y (\text{Person}(x) \land \text{Reads}(x, y)\rightarrow\text{Gains}(x, \text{knowledge}))$ `, thus `latex $\text{Reads}(\text{harry}, \text{walden})\rightarrow\text{Gains}(\text{harry}, \text{knowledge})$ `. Furthermore, anyone who gains knowledge is considered smarter, as per the premise `latex $\forall x (\text{Person}(x) \land \text{Gains}(x, \text{knowledge})\rightarrow\text{Smarter}(x))$ `, implying that `latex $\text{Gains}(\text{harry}, \text{knowledge})\rightarrow\text{Smarter}(\text{harry})$ `.

8. Thus, Smarter(Harry) is true.

# Conclusion

This study presents the Symbolic Chain-of-Thought (SymbCoT) framework, which innovatively integrates symbolic expressions and logical rules with CoT prompting to improve the logical reasoning abilities of LLMs. Specifically, based on the backbone LLM, SymbCoT translates the natural language context into the symbolic format and then derives a step-by-step plan to solve the logical reasoning problem with symbolic logical rules, followed by a verifier to check the translation and reasoning chain. Experimental results on 5 standard benchmarks with both FOL and CO symbolic expressions show that SymbCoT strikingly enhances the vanilla CoT on logical reasoning.

# Limitations

Our paper has the following potential limitations. Firstly, we only evaluate two symbolic structures in our framework. Despite substantiating the significant potential of First-Order Logic and Constraint Optimization in augmenting the logical reasoning capabilities of LLMs, it is imperative to conduct further assessments on additional symbolic languages to ensure a comprehensive evaluation. Secondly, the implementation of our framework is associated with considerable expenses. This financial implication is attributed to the methodology of incorporating symbolic rules, which inherently involves an extended reasoning chain and, consequently, the generation of an increased number of tokens by the model. This escalation in token generation necessitates additional expenditures related to API usage or the allocation of computational resources.

# Future Direction

Combining SymbCoT with an external solver presents a promising avenue for enhancing our reasoning system. SymbCoT's main limitation is sometimes failing to identify the correct reasoning path, while external solvers often struggle with information loss or translation errors. SymbCoT excels at addressing information loss and correcting errors, while the exhaustive, broad-spectrum search nature of the external solver is more effective in identifying reasoning paths. Therefore, these methods possess the potential for synergy.

Future work will focus on developing a framework that integrates SymbCoT with an external solver, leveraging their complementary strengths. We aim to optimize their interaction to improve overall performance, conducting experiments to validate and refine this hybrid approach.
