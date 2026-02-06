# Persona is a Double-edged Sword: Mitigating the Negative Impact of Role-playing Prompts in Zero-shot Reasoning Tasks

- **arXiv**: 2408.08631
- **Submitted**: 2024-10-19
- **Authors**: Junseok Kim, Nakyeong Yang, Kyomin Jung
- **Affiliations**: Pohang University of Science and Technology, Seoul National University

## Abstract

Recent studies demonstrate that prompting a role-playing persona to an LLM improves reasoning capability. However, assigning an adequate persona is difficult since LLMs are extremely sensitive to assigned prompts; thus, inaccurately defined personas sometimes hinder LLMs and degrade their reasoning capabilities. In this paper, we first investigate the potential negative impact of injecting persona into language models. Furthermore, we propose a novel framework, Jekyll & Hyde, which ensembles the outcomes of both role-playing and neutral prompts to enhance the robustness of reasoning ability. Specifically, Jekyll & Hyde predicts an appropriate persona using an LLM when defining the role-playing prompt. Then, Jekyll & Hyde collects two potential solutions from role-playing and neutral prompts and selects a better solution using the LLM evaluator. The experimental analysis demonstrates that role-playing prompts sometimes distract LLMs, degrading their reasoning abilities in 7 out of 12 datasets in llama3. Meanwhile, Jekyll & Hyde improve reasoning capabilities by selecting better choices among the potential solutions on twelve widely-used natural language reasoning datasets. In addition, we reveal that assigning LLM-generated personas obtains more stable results than handcrafted personas.

## 1. Introduction

Recent studies have exhibited that assigning specific roles to prompts can activate the role-playing ability of Large Language Models (LLMs), improving their reasoning capabilities. Specifically, some studies have proposed utilizing a hand-crafted persona or analyzing various jobs and relationships to find the most optimal persona that enhances the model's reasoning ability.

**The Problem: Persona is a Double-edged Sword**

Despite the benefits of utilizing role-playing persona, persona prompting can sometimes confuse LLMs, causing them to provide incorrect solutions to reasoning problems. For example, given a mathematical problem related to civil engineering, using "Civil Engineer" as a persona can lead the LLM to derive the wrong answer -- even when it would answer correctly without any persona.

**Confusion Matrix Analysis**

Analysis on AQuA and Coin Flip datasets reveals the dual nature of persona prompting:

| Dataset   | Both Wrong | Persona Fixes | Persona Breaks | Both Correct |
| --------- | ---------- | ------------- | -------------- | ------------ |
| AQuA      | 33.07%     | 15.75%        | **13.78%**     | 37.40%       |
| Coin Flip | 4.60%      | 4.00%         | **18.00%**     | 73.40%       |

The "Persona Breaks" column shows cases where the model answered correctly without persona but incorrectly with persona -- a significant negative impact.

**Jekyll & Hyde Framework**

To address this limitation, the authors propose Jekyll & Hyde that ensembles the solutions of role-playing and neutral prompts to mitigate the negative impact of role-playing persona. The framework:

1. Uses an LLM-generated persona (more effective than handcrafted)
2. Collects solutions from both role-playing and neutral prompts
3. Uses an LLM evaluator to select the better solution
4. Employs a position bias mitigation method for robust evaluation

Key results:

- Jekyll & Hyde outperforms baselines by an average of 9.98% accuracy across twelve datasets when using GPT-4
- LLM-generated personas provide more stable results than handcrafted personas
- Using the same LLM for generating persona and solving questions improves performance

## 2. Related Works

### 2.1 Role-playing Abilities of LLMs

Large language models have demonstrated significant capability in personating various roles, showing the power of role-playing capabilities. Several studies have investigated the positive effect of role assignment:

- Zheng et al. dissected the impact of role assignment by assigning various types of persona, including job names and relationship keywords
- Kong et al. revealed the effect of using role-playing prompts by handcrafting specific prompt forms for 12 different reasoning datasets

These studies concluded that using a domain-specific persona related to the given question improves LLM performance.

### 2.2 Analysis on Role-playing Prompts

Despite improvements, several studies exhibit drawbacks caused by role assignment:

- Gupta et al. analyzed how assigning persona with social demographical details brings bias toward the LLM, significantly dropping performance on reasoning tasks
- Deshpande et al. investigated toxicity scores for personas combined with specific entities (age, sexual orientation, etc.) and found that using particular names and adding specific entities generates biased responses

## 3. Methods

Jekyll & Hyde consists of three different LLM modules: **Persona Generator**, **Solver**, and **Evaluator**.

The pipeline:

1. Persona Generator generates an appropriate persona based on a given question
2. Two different LLM Solvers (Persona Solver and Neutral Solver) execute simultaneously
3. Evaluator compares two solutions and derives the final prediction

### 3.1 Automatic Identification of Persona

The common practice of role-playing prompting prepends a persona role (e.g., "Mathematician") into the prompt. However:

- Persona often brings bias when the question is not strongly related to the role
- Prior studies manually assigned roles, making it labor-intensive

**Solution**: Use an LLM (Persona Generator) to automatically generate an appropriate persona using an instruction-following prompt.

**Persona Generator Template**:

```
SystemMessage:
You have a special ability in giving job recommendations that could
sufficiently solve the given problem.

HumanMessage:
This is the user's question: {input}

According to the question, recommend a job that can sufficiently solve
the user's question. Here are some rules you need to follow:

1. give a description of the job in JSON format with the following keys:
   - job: a specific job name

2. Do not give any reasons or preambles about your response

Output:
```

### 3.2 Generating Personated and Neutral Perspective Solutions

After identifying a proper persona, it is formatted as a role-playing prompt: "You are a $persona"

Two solvers are employed:

- **Persona Solver**: LLM that uses role-playing prompting with the generated persona
- **Neutral Solver**: LLM without persona prompting, directly inserting the query

This dual execution approach provides two different perspectives and derives two discriminative responses. If we can ideally choose the correct answer between the two responses, we can achieve better performance than using a single solver.

### 3.3 Aggregating Solutions of Two Solvers

Two solutions from Neutral Solver and Persona Solver are inserted into the evaluation prompt. Given a question q and two solutions (r_n, r_p):

```
v_{n,p} = argmax_v P(v | [iota; q; r_n; r_p])
```

Where:

- v in {"A", "B"} is a verdict text
- P is the Evaluator
- iota is an instruction, q is the question
- r_n and r_p are solutions from Neutral and Persona Solvers

The verdict indicates "A" if the first solution is better, "B" if the second is better.

**Evaluation Template**:

```
Please act as an impartial judge and evaluate the quality of the responses
provided by two AI assistants to the user question displayed below.

Your evaluation should ONLY consider correctness. You will be given
assistant A's answer, and assistant B's answer.

Your job is to evaluate which assistant's answer is better. You should
independently solve the user question step-by-step first.

Then compare both assistants' answers with your answer. Identify and
correct any mistakes.

Please note that:
1. Avoid any position biases and ensure that the order in which the
   responses were presented does not influence your decision.
2. Do not allow the length of the responses to influence your evaluation.
3. Do not favor certain names of the assistants. Be as objective as possible.
4. Give reason for your choice between two solutions.
5. You must output your final verdict by strictly following this format:
   "[[A]]" if assistant A is better, and "[[B]]" if assistant B is better

This is your user's question: {question}

assistant A's answer: {assistantA_answer}
assistant A's explanation: {assistantA_explanation}

assistant B's answer: {assistantB_answer}
assistant B's explanation: {assistantB_explanation}

Now, begin!
Final verdict:
```

### 3.4 Robust Evaluation via Consistency Verification

The Evaluator may be exposed to **position bias**, which degrades total performance. Position bias occurs due to the order of solutions.

**Mitigation approach**: Run the Evaluator twice with solutions in forward and reverse orders, yielding two verdicts v*{n,p} and v*{p,n}.

The process continues until:

1. Both verdicts match (v*{n,p} = v*{p,n}), OR
2. Maximum attempts k is reached

```
v_final = {
    v_{n,p}         if v_{n,p} = v_{p,n} and t < k
    "Can't answer"  if t >= k
}
```

If maximum attempts are exceeded, Jekyll & Hyde returns "Can't answer" since it's risky to narrow to one solution when the Evaluator is significantly exposed to position bias.

## 4. Experiments

### 4.1 Experimental Setup

**Datasets** (12 datasets across 4 categories):

| Category              | Datasets                                             |
| --------------------- | ---------------------------------------------------- |
| Arithmetic            | MultiArith, GSM8K, AddSub, AQUA-RAT, SingleEq, SVAMP |
| Commonsense Reasoning | CSQA, StrategyQA                                     |
| Symbolic Reasoning    | Last Letter Concatenation, Coin Flip                 |
| Other Tasks           | Date Understanding, Tracking Shuffled Objects        |

**Models**: GPT-4 (gpt-4-0613), GPT-3.5-turbo (gpt-3.5-turbo-0125), llama3 (8B)

**Configurations**:

- **Base**: Neutral solver only (no persona)
- **Persona**: Persona solver only (with persona)
- **Jekyll & Hyde**: Full framework

**Hyper-parameters**: max attempt k=5, temperature tau=0.7

### 4.2 Persona Does Not Always Improve Performance

Win rate analysis across categories shows that Persona does not always enhance reasoning ability. All categories contain datasets where Base outperforms Persona.

### 4.3 Main Results

**Arithmetic Datasets**:

| Model   | Method        | MultiArith | GSM8K     | AddSub    | AQuA      | SingleEq  | SVAMP     | Avg       |
| ------- | ------------- | ---------- | --------- | --------- | --------- | --------- | --------- | --------- |
| GPT-4   | Base          | **98.44**  | 92.97     | 97.13     | 68.24     | 98.56     | 91.00     | 91.06     |
| GPT-4   | Persona       | 97.78      | 94.06     | 97.55     | 74.80     | 98.56     | 90.90     | 92.28     |
| GPT-4   | Jekyll & Hyde | 98.00      | **95.27** | **97.72** | **76.90** | **98.95** | **92.03** | **93.15** |
| GPT-3.5 | Base          | 95.72      | 81.40     | 90.97     | 62.60     | 97.83     | 80.17     | 84.78     |
| GPT-3.5 | Persona       | 96.50      | 83.27     | **93.08** | 64.44     | 97.31     | 84.13     | 86.45     |
| GPT-3.5 | Jekyll & Hyde | **97.56**  | **85.01** | 92.91     | **67.98** | **98.03** | **84.77** | **87.71** |
| llama3  | Base          | **98.56**  | 78.59     | 87.76     | 47.38     | 94.23     | 82.30     | 81.47     |
| llama3  | Persona       | 97.22      | 81.05     | 87.17     | 52.23     | 91.27     | 84.97     | 82.32     |
| llama3  | Jekyll & Hyde | 98.17      | **83.02** | **89.03** | **54.07** | **94.62** | **86.50** | **84.23** |

**Other Datasets**:

| Model   | Method        | CSQA      | Strategy  | Letter    | Coin      | Date      | Object    | Avg       |
| ------- | ------------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- |
| GPT-4   | Base          | 79.91     | 76.42     | 19.80     | 66.93     | 79.22     | 45.96     | 61.37     |
| GPT-4   | Persona       | 80.89     | 75.71     | 92.80     | 75.93     | 78.41     | 58.76     | 77.08     |
| GPT-4   | Jekyll & Hyde | **81.11** | **77.00** | **93.00** | **80.27** | **82.38** | **61.69** | **79.24** |
| GPT-3.5 | Base          | 77.31     | 68.75     | 18.67     | 47.53     | 67.84     | 34.67     | 52.46     |
| GPT-3.5 | Persona       | 75.40     | 69.75     | 45.67     | 59.20     | 76.15     | 40.22     | 61.07     |
| GPT-3.5 | Jekyll & Hyde | **77.50** | **70.00** | **48.93** | **64.00** | **76.78** | **42.22** | **63.24** |
| llama3  | Base          | 74.50     | 69.21     | 86.40     | 95.80     | 77.42     | 44.76     | 74.68     |
| llama3  | Persona       | 72.29     | **71.21** | 86.07     | 95.33     | 74.44     | 47.60     | 74.49     |
| llama3  | Jekyll & Hyde | **74.97** | 70.54     | **86.47** | **98.67** | **79.04** | **48.58** | **76.38** |

### 4.4 Comparison with Self-Consistency

Simply increasing LLM executions does not match Jekyll & Hyde's effectiveness:

| Model | Dataset | Method           | Accuracy  | Avg LLM Runs |
| ----- | ------- | ---------------- | --------- | ------------ |
| GPT-4 | AQuA    | Base + voting    | 70.87     | 4            |
| GPT-4 | AQuA    | Persona + voting | 73.23     | 6            |
| GPT-4 | AQuA    | Jekyll & Hyde    | **76.90** | 3.81         |
| GPT-4 | Object  | Base + voting    | 46.00     | 5            |
| GPT-4 | Object  | Persona + voting | 59.20     | 6            |
| GPT-4 | Object  | Jekyll & Hyde    | **61.69** | 4.14         |

Jekyll & Hyde outperforms self-consistency methods with fewer LLM runs.

### 4.5 Automatic Persona Generation Ensures Robust Reasoning

Comparison of handcrafted vs. LLM-generated personas (using llama3-8B):

| Dataset | Method        | Avg Accuracy | Std Dev  |
| ------- | ------------- | ------------ | -------- |
| AQuA    | Handcrafted   | **51.71**    | 6.11     |
| AQuA    | LLM-generated | 50.66        | **2.08** |
| Object  | Handcrafted   | 44.31        | 8.02     |
| Object  | LLM-generated | **46.71**    | **3.06** |

LLM-generated personas provide more stable results with lower variance.

### 4.6 Same LLM for Generator and Solver Improves Performance

Using llama3-8B as persona generator with different solvers:

| Dataset | llama3-8B Solver | GPT-3.5 Solver | GPT-4 Solver |
| ------- | ---------------- | -------------- | ------------ |
| AQuA    | 53.15            | 52.36          | **53.54**    |
| AddSub  | **88.35**        | 81.77          | 82.53        |
| Coin    | **95.00**        | 90.20          | 92.80        |
| Date    | **74.80**        | 71.54          | 72.63        |
| Object  | 49.07            | 46.93          | **50.93**    |
| Average | **72.07**        | 68.56          | 70.49        |

Using the same LLM for both persona generation and solving yields optimal performance.

### 4.7 Position Bias Mitigation

Comparison with existing methods (Portia, MEC+BPC):

| Model  | Method                        | SingleEq  | Coin      |
| ------ | ----------------------------- | --------- | --------- |
| GPT-4  | Oracle Evaluator              | 99.41     | 88.80     |
| GPT-4  | Portia                        | 98.82     | 74.40     |
| GPT-4  | MEC+BPC                       | 98.43     | 74.00     |
| GPT-4  | Jekyll & Hyde (no mitigation) | 98.43     | 78.20     |
| GPT-4  | Jekyll & Hyde                 | **98.95** | **80.27** |
| llama3 | Oracle Evaluator              | 96.06     | 99.00     |
| llama3 | Portia                        | 93.31     | 96.40     |
| llama3 | MEC+BPC                       | 91.73     | 95.40     |
| llama3 | Jekyll & Hyde (no mitigation) | 94.29     | 97.00     |
| llama3 | Jekyll & Hyde                 | **94.62** | **98.67** |

Jekyll & Hyde's consistency verification outperforms existing bias mitigation methods.

### 4.8 Hyper-parameter Analysis

**Max Attempts (k)**: Performance increases with more attempts but saturates. k=5 balances performance and computational cost.

**Temperature (tau)**: tau=0.7 achieves optimal performance across most settings.

### 4.9 Qualitative Analysis

Example from AQuA dataset:

**Question**: Two ants are standing side-by-side. One ant, which is 4 inches tall, casts a shadow that is 10 inches long. The other ant is 6 inches tall. Compute the length of the shadow that the taller ant casts.

- **Neutral Solver** (no persona): Incorrectly answered C (42 inches)
- **Persona Solver** (Mathematician): Correctly answered D (15 inches)
- **Evaluator** verdict: Both forward and reverse order selected the Persona Solver's answer
- **Final answer**: D (correct)

Example from StrategyQA:

**Question**: Did anyone in the 1912 election take a majority of the popular vote?

- **Neutral Solver**: Correctly answered "no" (Wilson won plurality, not majority at 41.8%)
- **Persona Solver** (Historical Election Analyst): Incorrectly answered "yes"
- **Evaluator** verdict: Both orders selected Neutral Solver's answer
- **Final answer**: no (correct)

## 5. Conclusion

This paper proposes Jekyll & Hyde, a novel framework that solves reasoning problems by ensembling personated and neutral perspectives. Key findings:

1. Role-playing prompts can be a double-edged sword, degrading performance in many cases
2. Ensembling both perspectives mitigates this negative impact
3. LLM-generated personas are more robust than handcrafted ones
4. The consistency verification method effectively mitigates position bias

Evaluations across twelve representative reasoning benchmarks show that Jekyll & Hyde surpasses both persona-assigned and neutral-only approaches on most datasets.

## Limitations

1. **Computational cost**: Jekyll & Hyde requires at least two LLM executions per instance (though users can set k=2 and still outperform single-perspective LLMs)
2. **Upper bound**: Questions that both neutral and persona LLMs answer incorrectly cannot be corrected by Jekyll & Hyde

## Appendix

### A. Solver Mechanism

When running the LLM under zero-shot setting, responses are not fixed in format. The answer extraction follows Zero-Shot CoT technique:

1. Generate response from LLM based on role-playing prompting and question
2. Concatenate question, response, and answer trigger
3. Extract final answer from the response

**Answer Trigger Sentences**:

| Answer Format | Trigger                                       |
| ------------- | --------------------------------------------- |
| Arabic number | "Therefore, the answer (arabic numerals) is"  |
| Option (A-E)  | "Therefore, among A through E, the answer is" |
| Option (A-C)  | "Therefore, among A through C, the answer is" |
| Yes or no     | "Therefore, the answer (Yes or No) is"        |
| String        | "Therefore, the final answer is"              |

### B. Dataset Details

| Dataset            | Answer Format | N_q  | L_q  | License     |
| ------------------ | ------------- | ---- | ---- | ----------- |
| SingleEq           | Arabic number | 508  | 27.4 | No License  |
| AddSub             | Arabic number | 395  | 31.5 | Unspecified |
| MultiArith         | Arabic number | 600  | 31.8 | Unspecified |
| GSM8K              | Arabic number | 1319 | 46.9 | MIT License |
| AQUA               | Option (A-E)  | 254  | 51.9 | Apache-2.0  |
| SVAMP              | Arabic number | 1000 | 31.8 | MIT License |
| CommonsenseQA      | Option (A-E)  | 1221 | 27.8 | Unspecified |
| StrategyQA         | Yes or no     | 2290 | 9.6  | Apache-2.0  |
| Date Understanding | Option (A-F)  | 369  | 35.0 | Apache-2.0  |
| Object Tracking    | Option (A-C)  | 750  | 91.1 | Apache-2.0  |
| Last Letters       | String        | 500  | 15.0 | -           |
| Coin Flip          | Yes or no     | 500  | 37.0 | -           |

N_q = number of questions; L_q = average words per question

### C. Impact of Prompt Design

Different prompt designs for persona LLM:

| Form           | Prompt                                                                                                    | Persona Acc | Jekyll & Hyde Acc |
| -------------- | --------------------------------------------------------------------------------------------------------- | ----------- | ----------------- |
| Persona only   | "You are a [$persona$]"                                                                                   | **65.75**   | **69.68**         |
| Persona + task | "You are a [$persona$]. Your task is to solve the given math question and come up with a correct answer." | 62.99       | 68.11             |
| Task only      | "Your task is to solve the given math question and come up with a correct answer."                        | 65.35       | 68.90             |

Using only persona in the prompt achieves highest performance.

### D. Confusion Matrices for Other Datasets

| Dataset         | Both Wrong | Persona Fixes | Persona Breaks | Both Correct |
| --------------- | ---------- | ------------- | -------------- | ------------ |
| StrategyQA      | 19.39%     | 12.31%        | **10.31%**     | 57.99%       |
| Coin Flip       | 4.60%      | 4.00%         | **18.00%**     | 73.40%       |
| Object Tracking | 46.67%     | 18.13%        | **12.93%**     | 22.27%       |

### E. Full Position Bias Mitigation Results

| Model   | Method        | AddSub    | AQuA      | SingleEq  | SVAMP     | Coin      | Date      |
| ------- | ------------- | --------- | --------- | --------- | --------- | --------- | --------- |
| GPT-4   | Oracle        | 97.72     | 81.10     | 99.41     | 95.20     | 88.80     | 82.66     |
| GPT-4   | Portia        | 97.47     | 74.41     | 98.82     | 91.80     | 74.40     | 80.76     |
| GPT-4   | MEC+BPC       | 97.22     | 74.41     | 98.43     | 91.20     | 74.00     | 79.95     |
| GPT-4   | J&H (no mit.) | 97.72     | **78.35** | 98.43     | 92.20     | 78.20     | 80.22     |
| GPT-4   | J&H           | **97.72** | 77.56     | **99.02** | **92.60** | **79.80** | **81.57** |
| GPT-3.5 | Oracle        | 95.19     | 74.41     | 99.21     | 87.10     | 60.80     | 80.22     |
| GPT-3.5 | Portia        | 91.14     | 62.60     | 98.23     | 81.80     | 57.80     | 72.63     |
| GPT-3.5 | MEC+BPC       | 89.37     | 62.60     | 97.64     | 80.20     | 57.60     | **75.61** |
| GPT-3.5 | J&H (no mit.) | 92.15     | 62.60     | 97.83     | 82.50     | 56.60     | 72.63     |
| GPT-3.5 | J&H           | **93.16** | **64.17** | **98.23** | **83.00** | **59.60** | 72.63     |
| llama3  | Oracle        | 92.41     | 63.39     | 96.06     | 90.20     | 99.00     | 84.55     |
| llama3  | Portia        | 88.35     | 51.97     | 93.31     | 86.10     | 96.40     | 78.86     |
| llama3  | MEC+BPC       | 88.10     | **55.91** | 91.73     | 84.50     | 95.40     | **81.03** |
| llama3  | J&H (no mit.) | 90.38     | 51.18     | 94.29     | 86.10     | 97.00     | 79.95     |
| llama3  | J&H           | **91.14** | 53.54     | **95.67** | **86.80** | **98.40** | 79.95     |
