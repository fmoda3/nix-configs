# Take a Step Back: Evoking Reasoning via Abstraction in Large Language Models

**Authors**: Huaixiu Steven Zheng, Swaroop Mishra, Xinyun Chen, Heng-Tze Cheng, Ed H. Chi, Quoc V Le, Denny Zhou

**Affiliation**: Google DeepMind

**arXiv**: 2310.06117

---

## Abstract

We present Step-Back Prompting, a simple prompting technique that enables LLMs to do abstractions to derive high-level concepts and first principles from instances containing specific details. Using the concepts and principles to guide reasoning, LLMs significantly improve their abilities in following a correct reasoning path towards the solution. We conduct experiments of Step-Back Prompting with PaLM-2L, GPT-4 and Llama2-70B models, and observe substantial performance gains on various challenging reasoning-intensive tasks including STEM, Knowledge QA, and Multi-Hop Reasoning. For instance, Step-Back Prompting improves PaLM-2L performance on MMLU (Physics and Chemistry) by 7% and 11% respectively, TimeQA by 27%, and MuSiQue by 7%.

*The purpose of abstraction is not to be vague, but to create a new semantic level in which one can be absolutely precise. -- Edsger W. Dijkstra*

---

## Introduction

The field of natural language processing (NLP) is witnessing a ground-breaking revolution because of the Transformer-based large language models (LLMs). Scaling up the model size and pre-training corpus has brought remarkable improvement in model capabilities and sample efficiency with insights from the scaling law, as well as emergent abilities such as multi-step reasoning and instruction following.

[IMAGE: Figure 1 - Strong Performance of Step-Back Prompting showing results across STEM, Knowledge QA and Multi-Hop Reasoning tasks]

Despite the great advancements, complex multi-step reasoning remains challenging for even the state-of-the-art LLMs. Process-supervision with step-by-step verification is a promising remedy to improve the correctness of intermediate reasoning steps. Techniques such as Chain-of-Thought were introduced to produce a coherent series of intermediate reasoning steps to increase the success rate of following the right decoding path. Inspired by the fact that when faced with challenging tasks humans often step back and do abstractions to arrive at high-level principles to guide the process, we propose Step-Back Prompting to ground reasoning on abstractions to reduce the chance of making errors in the intermediate reasoning steps.

[IMAGE: Figure 2 - Illustration of Step-Back Prompting with two steps of Abstraction and Reasoning guided by concepts and principles. Top: an example of MMLU high-school physics where the first principle of Ideal Gas Law is retrieved via abstraction. Bottom: an example from TimeQA where the high-level concept of education history is a result of the abstraction. Left: PaLM-2L fails to answer the original question. Chain-of-Thought prompting ran into errors during intermediate reasoning steps. Right: PaLM-2L successfully answers the question via Step-Back Prompting.]

Among many of the cognitive skills, abstraction is ubiquitous to humans' ability to process vast amounts of information and derive general principles. For example, Kepler compressed thousands of measurements into Kepler's three laws of planetary motion, which precisely describe the orbits of planets around the Sun. In critical decision-making, humans find abstraction to be helpful since it provides a broader view of the environment. This work explores how LLMs can tackle complex tasks involving many low-level details through a two-step process of abstraction-and-reasoning. The first step is to show LLMs how to step back through in-context learning -- prompting them to derive high-level abstractions such as concepts and principles for a specific example. The second step is to leverage the reasoning ability to reason on top of the high-level concepts and principles. We use few-shot exemplar demonstrations to execute Step-Back Prompting on LLMs.

We experiment across a range of tasks involving domain specific reasoning such as Physics and Chemistry, knowledge-intensive question answering requiring factual knowledge, multi-hop commonsense reasoning. We observe significant performance improvements (up to 27%) in PaLM-2L demonstrating the efficacy of Step-Back Prompting in tackling complex tasks, which are otherwise challenging due to the amount of details needed for reasoning. Some of the tasks are very challenging: both PaLM-2L and GPT-4 achieve only ~40% accuracy on TimeQA and MuSiQue. Chain-of-Thought prompting leads to a minor improvement on a few tasks, while Step-Back Prompting improves the performance of PaLM-2L across the board: 7% and 11% on MMLU Physics and Chemistry, 27% on TimeQA, and 7% on MuSiQue.

We conduct a variety of analyses and find that Step-Back Prompting leads to strong performance improvements (up to 36%) over chain-of-thought (CoT) prompting and "take-a-deep-breath" (TDB) prompting. We perform a qualitative evaluation where we find that Step-Back fixes a large portion of errors of the base model (up to ~40%) while introducing a small portion of new errors (max ~12%). We also conduct an error analysis and find that majority of the errors made by Step-Back Prompting is attributed to the intrinsic limitations of reasoning capabilities of LLMs while abstraction skills are relatively easy to demonstrate to LLMs, pointing out the direction for future improvements of methods alike Step-Back Prompting.

---

## Step-Back Prompting

Step-Back Prompting is motivated by the observation that many tasks contain a lot of details, and it is hard for LLMs to retrieve relevant facts to tackle the task. For a Physics question of "*What happens to the pressure, P, of an ideal gas if the temperature is increased by a factor of 2 and the volume is increased by a factor of 8?*", the LLM can deviate from the first principle of Ideal Gas Law when reasoning directly on the question. Similarly, a question of "*Estella Leopold went to which school between Aug 1954 and Nov 1954?*" is very hard to address directly given the detailed time range constraint. In both cases, asking a step-back question helps the model to solve the problem effectively.

We define a **step-back question** as a derived question from the original question at a higher level of abstraction. For instance, instead of directly asking "*which school Estella Leopold went to during a specific period*", a step-back question would ask about the "*education history*", which is a high-level concept encompasses the original question. Answering the step-back question of "*Estella Leopold's education history*" in this case will provide all the necessary information to reason about "*which school Estella Leopold went to during a specific period*". The premise is that the step-back question is typically much easier. Grounding the reasoning on top of such abstractions helps to avoid reasoning errors in the intermediate steps. In short, Step-Back Prompting consists two simple steps:

- **Abstraction**: Instead of addressing the question directly, we first prompt the LLM to ask a generic step-back question about a higher-level concept or principle, and retrieve relevant facts about the high-level concept or principle. The step-back question is unique for each task in order to retrieve the most relevant facts.

- **Reasoning**: Grounded on the facts regarding the high-level concept or principle, the LLM can reason about the solution to the original question. We term this as *Abstraction-grounded Reasoning*.

---

## Experimental Setup

### Tasks

We experiment with the following diverse tasks: (a) STEM, (b) Knowledge QA, and (c) Multi-Hop Reasoning.

- **STEM**: We evaluate MMLU and GSM8K for STEM tasks. MMLU contains a series of benchmarks across diverse domains to evaluate the model's language understanding. We consider the high school physics and chemistry portions of MMLU because of the deep reasoning involved.

- **Knowledge QA**: We consider TimeQA since it contains complex queries that require challenging time-sensitive knowledge. We also experiment with SituatedQA, another challenging open-retrieval QA dataset requiring the model to answer questions given temporal or geographical contexts.

- **Multi-Hop Reasoning**: We experiment with MuSiQue, a hard multihop reasoning dataset created via composable pairs of single-hop questions, and StrategyQA with open-domain questions that demand some strategy to solve.

### Models

We use the following state-of-the-art LLMs: instruction-tuned PaLM-2L, GPT-4, and Llama2-70B.

### Evaluation

Conventional evaluation metrics such as accuracy, F1 score have limitations specifically for evaluating the generations of state-of-the-art LLMs since these models often generate long-form answers which are hard to capture. We instead conduct an evaluation using the PaLM-2L model where we few-shot prompt the model to identify equivalence between target answers and the model predictions.

### Baseline Methods

- **PaLM-2L, PaLM-2L 1-shot**: PaLM-2L is either queried directly with the question or has a single demonstration exemplar of question-answer included in the prompt.

- **PaLM-2L + CoT, PaLM-2L + CoT 1-shot**: PaLM-2L model is queried with zero-shot CoT prompting: "*Let's think step by step*" is appended to the question. For 1-shot, One demonstration example of a question and answer pair is provided in the prompt, where the answer is in the style of CoT.

- **PaLM-2L + TDB**: Zero-shot prompting with "*Take a deep breath and work on this problem step-by-step.*" prepended to the question.

- **PaLM-2L + RAG**: For Knowledge QA and Multi-Hop Reasoning tasks, we use retrieval-augmented generation (RAG) where the retrieved passage is used as context by the LLM.

- **GPT-4 and Llama2-70B**: we run GPT-4 and Llama2-70B on MMLU tasks for all methods. In addition, we also run GPT-4 on all baselines for all tasks.

We do not use RAG for STEM tasks, because of the inherent reasoning nature of the tasks contrary to the other fact-seeking datasets. All inferences are done using greedy decoding.

---

## STEM

### Step-Back Prompting for STEM

Questions in the MMLU benchmarks require deeper reasoning. Furthermore, they also require understanding and application of formulae which are often physics and chemistry principles and concepts. In this case, we first demonstrate to the model abstraction skills in the form of concepts and first principles such as *Newton's first law of motion*, *Doppler effect*, and *Gibbs free energy* etc. The implicit step-back question here is "*what are the physics or chemistry principles and concepts involved in solving this task?*". We provide demonstrations to the model to recite the relevant principles for solving the task from its own knowledge.

### Results

**Table 1: Strong performance of Step-Back Prompting on MMLU tasks across three model families.**

| Method | MMLU Physics | MMLU Chemistry |
|--------|--------------|----------------|
| PaLM-2L | 66.4% (0.8%) | 70.9% (0.9%) |
| PaLM-2L 1-shot | 64% (1.6%) | 75.6% (0.4%) |
| PaLM-2L + CoT | 65% (2%) | 75.3% (1.5%) |
| PaLM-2L + CoT 1-shot | 61.5% (1.8%) | 76.6% (1%) |
| PaLM-2L + TDB | 65.7% (0.7%) | 73.8% (1.1%) |
| **PaLM-2L + Step-Back (ours)** | **73.2%** (1.9%) | **81.8%** (1.4%) |
| GPT-4 | 69.4% (2.0%) | 80.9% (0.7%) |
| GPT-4 1-shot | 78.4% (2.4%) | 80.5% (1.6%) |
| GPT-4 + CoT | 82.9% (0.5%) | 85.3% (1.0%) |
| GPT-4 + CoT 1-shot | 79.3% (1.0%) | 82.8% (0.5%) |
| GPT-4 + TDB | 74.4% (4.0%) | 81.5% (1.3%) |
| **GPT-4 + Step-Back (ours)** | **84.5%** (1.2%) | **85.6%** (1.4%) |
| Llama2-70B | 51.9% (3.6%) | 55.7% (2.1%) |
| Llama2-70B 1-shot | 57.3% (1.6%) | 58.5% (2.5%) |
| Llama2-70B + CoT | 59.3% (2.0%) | 64.1% (1.2%) |
| Llama2-70B + CoT 1-shot | 59.6% (2.0%) | **68.1%** (1.4%) |
| Llama2-70B + TDB | 60.4% (2.1%) | 63.6% (1.9%) |
| **Llama2-70B + Step-Back (ours)** | **64.8%** (1.5%) | 66.7% (1.6%) |

PaLM-2L baseline performance is 66.4% and 70.9% on Physics and Chemistry, respectively. We find that CoT and TDB zero-shot prompting do not significantly increase model performance, which could be due to the inherent difficulty and deep reasoning associated with these tasks. In contrast, Step-Back Prompting significantly improves model performance: +7% and +11% compared to PaLM-2L. Similarly, with GPT-4 and Llama2-70B models, Step-Back Prompting is very competitive among all the baseline methods we tested, showing that Step-Back Prompting is model-agnostic.

### Ablation and Analysis

**Few-shot Ablation**: Step-Back Prompting is robust to the number of few-shot exemplars of (question, principles) pairs used as demonstrations. Adding more demonstration examples beyond a single example does not lead to further improvements. This indicates that the task of retrieving the relevant principles and concepts is relatively easy through in-context learning and a single demonstration suffices. Therefore, we use a single exemplar for few-shot prompting throughout the paper except the ablation studies.

**Error Analysis**: Comparing the predictions of Step-Back Prompting to the baseline PaLM-2L model for MMLU high-school Physics: we find that Step-Back Prompting corrects 20.5% errors from the baseline while introducing 11.9% errors.

To further understand where the errors come from in Step-Back Prompting, we categorize them into 5 classes:

- **Principle Error**: The error happens at the step of Abstraction, where the first principles generated by models are wrong or incomplete.

- **Factual Error**: There is at least one factual error when the model recites its own factual knowledge

- **Math Error**: There is at least one math error in the intermediate steps when math calculations are involved in deriving the final answer.

- **Context Loss**: There is at least one error where the model response loses context from the question, and deviates from addressing the original question

- **Reasoning Error**: The model makes at least one error in the intermediate Reasoning steps before arriving at the final answer.

All five types of errors are happening during the Reasoning step except *Principle Error* which points to the failure of the Abstraction step. *Principle Error* comprises only a small fraction of the errors the model makes: more than 90% of the errors happen at the Reasoning step. Among the four error types during Reasoning, *Reasoning Error* and *Math Error* are the major error categories. This corroborates with the finding in the ablation study above that very few exemplars are needed to demonstrate to LLMs the Abstraction skill. Reasoning step is still the bottleneck of how well Step-Back Prompting can perform tasks such as MMLU requiring complex reasoning.

---

## Knowledge QA

We evaluate Step-Back Prompting on question-answering benchmarks requiring intensive factual knowledge.

### Step-Back Prompting for Knowledge QA

We evaluate Step-Back Prompting on TimeQA and SituatedQA in the Knowledge QA category. We first show the LLMs how to do Abstraction through in-context demonstrations. The step-back question "*What was Estella Leopold's education history*" is generated by the LLM through few-shot demonstrations. Given the knowledge-intensive nature of these queries, we use retrieval augmentation (RAG) in combination with Step-Back Prompting. The step-back question is used to retrieve relevant facts, which work as additional context to ground the final reasoning step.

### Results

**Table 2: Strong performance of Step-Back Prompting on Knowledge QA tasks.**

| Method | TimeQA | TQA Easy | TQA Hard | SituatedQA |
|--------|--------|----------|----------|------------|
| PaLM-2L | 41.5% | 42.6% | 40.4% | 54.3% (0.3%) |
| PaLM-2L 1-shot | 40.7% | 41.7% | 39.1% | 51.8% (0.6%) |
| PaLM-2L + CoT | 40.8% | 41.8% | 39.8% | 56.4% (0.2%) |
| PaLM-2L + CoT 1-shot | 38.1% | 39.3% | 36.8% | 54% (0.8%) |
| PaLM-2L + TDB | 40.9% | 42.6% | 39.1% | 54% (0.5%) |
| PaLM-2L + RAG | 57.4% | 67.8% | 46.8% | 59.3% (0.4%) |
| PaLM-2L + Step-Back (ours) | 66% | 70.4% | 61.6% | 57.5% (0.3%) |
| **PaLM-2L + Step-Back + RAG (ours)** | **68.7%** | **75.2%** | **62.3%** | 61% (0.4%) |
| GPT-4 | 45.6% | 48.9% | 42.6% | **63.2%** (0.4%) |

The baseline models of GPT-4 and PaLM-2L achieved 45.6% and 41.5%, highlighting the difficulty of the task. Applying either CoT or TDB zero-shot (and one-shot) prompting to the baseline model shows no improvement. In contrast, augmenting the baseline model by regular retrieval augmentation (RAG) improves the accuracy to 57.4%, highlighting the fact-intensive nature of the task. The result of Step-Back + RAG shows the effectiveness of going back to a high-level concept, which enables much more reliable retrieval augmentation: the accuracy on TimeQA achieves a remarkable 68.7%.

We segment TimeQA into the Easy and Hard difficulty levels. While RAG can improve the Easy accuracy from 42.6% to 67.8%, the improvement is much smaller on the Hard accuracy: 40.4% to 46.8%. This is where Step-Back Prompting shines by retrieving facts regarding high-level concepts to ground the final reasoning: Step-Back + RAG further improves the Hard accuracy to 62.3%, outperforming GPT-4's 42.6%. We hypothesize that facts regarding the high-level concepts (such as *education history*) are much more accessible than the low-level details.

### Ablation and Analysis

**Few-shot Ablation**: The performance of Step-Back Prompting on TimeQA is robust to the number of exemplars used in demonstration, highlighting again the sample efficiency of in-context learning Abstraction skills for models like PaLM-2L.

[IMAGE: Figure 3 - Ablation and error analysis of Step-Back Prompting on TimeQA. Left: ablation against the number of few-shot exemplars. Right: four classes of errors Step-Back makes with Reasoning and RAG being the dominant error sources.]

**Error Analysis**: The breakdown of all the remaining errors made by Step-Back Prompting on TimeQA shows:

- **StepBack**: The step-back question generated is not helpful in solving the task.

- **RAG**: RAG fails to retrieve relevant information despite that the step-back question is on target.

- **Scoring Error**: The evaluation by the judge model made a mistake.

- **Reasoning Error**: The retrieved context is relevant, but the model still fails to reason through the context to arrive at the right answer.

We find that the StepBack rarely fails. In contrast, we find more than half of the errors are due to reasoning errors. Additionally, 45% of errors are due to failure in retrieving the right information despite that Abstraction provided by step-back makes it a much easier task. This reflects the difficulty level of the TimeQA task.

---

## Multi-Hop Reasoning

We evaluate Step-Back Prompting on challenging Multi-Hop reasoning benchmark MuSiQue and StrategyQA.

**Table 3: Results of Step-Back Prompting on Multi-Hop Reasoning.**

| Method | MuSiQue | StrategyQA |
|--------|---------|------------|
| PaLM-2L | 35.5% (3%) | 82.8% (0.7%) |
| PaLM-2L 1-shot | 29.0% (0.5%) | 76.6% (0.5%) |
| PaLM-2L + CoT | 38.7% (3.2%) | 83.6% (0.4%) |
| PaLM-2L + CoT 1-shot | 38.5% (2.2%) | 76.8% (1.4%) |
| PaLM-2L + TDB | 39.0% (2.3%) | 82.7% (0.9%) |
| PaLM-2L + RAG | 39.6% (2.8%) | 84.2% (0.5%) |
| PaLM-2L + Step-Back (ours) | 42.6% (3.1%) | 82.7% (0.4%) |
| **PaLM-2L + Step-Back + RAG (ours)** | **42.8%** (2.0%) | **86.4%** (1%) |
| GPT-4 | 38.5% (0.2%) | 78.3% (1.1%) |

Baseline performance of PaLM-2L and GPT-4 are low (35.5% and 38.5% for PaLM-2L and GPT-4 respectively) in MuSiQue since it is a hard multihop reasoning benchmark. In contrast, StrategyQA has stronger baselines (82.8% and 78.3%) probably because it is a binary classification task. CoT and TDB improve model performance a bit in the case of MuSiQue (~3% and 3.5% respectively). Step-Back Prompting with the power of abstraction produces the best performance of all methods: 42.8% in MuSiQue and 86.4% in StrategyQA, significantly outperforming GPT-4 on both tasks.

---

## Discussion

Abstraction helps humans to solve complex tasks by removing irrelevant details and distilling high-level concepts and principles to guide the problem-solving process. Step-Back Prompting breaks complex tasks such as knowledge-intensive QA, multi-hop reasoning, and science questions into two separate steps of Abstraction and Reasoning. We demonstrate through empirical experiments that Abstraction is an easy skill for the LLMs such as PaLM-2L via sample-efficient in-context learning. Grounding on the high-level concepts and principles, LLMs can leverage their intrinsic Reasoning capabilities to derive the solution. This reduces the chance of reasoning failures in the intermediate steps and is shown to improve the performance on a wide range of complex reasoning tasks. Despite the success, through error analysis, we find that Reasoning is still one of the hardest skills for LLMs to acquire: it is still the dominant failure mode even after the large reduction of task complexity by Step-Back Prompting.

Nevertheless, Abstraction is neither necessary nor possible in all scenarios. For instance, the task can be as simple as *who was the president of the United States in 2000?*, in which case there is no such need to step back and ask a high-level question as the answer to such questions is readily available. Questions such as *what is the speed of light?* point to the first principles themselves. Doing Abstraction in this case would not make a difference either.

---

## Related Work

### Prompting

Few-shot prompting has significantly improved model performance across a range of tasks without requiring updating any model parameters. Step-Back Prompting is in the same category as the chain-of-thought prompting and scratchpad owing to its simplicity and generic nature. But our approach is focused on the key idea of abstraction which is inspired from the fact that taking a step back often helps humans in performing complex tasks. Our work is also related to the recitation-augmented language models; however in contrast to their work, we explicitly perform step-back and abstraction, with optional use of retrieval augmentation depending on the nature of the task at hand.

### Decomposition

Decomposing a task into simpler tasks and solving these tasks to complete the original task has been an effective way to improve model performance on complex tasks. Step-Back Prompting, in contrast, is on making the question more abstract and high-level, which is different from decomposition that is often a low-level breakdowns of the original question. For instance, a generic question for *which employer did Steve Jobs work for in 1990?* could be *what is the employment history of Steve Jobs?* While decomposition would lead to sub-questions such as *What was Steve Jobs doing in 1990?*, *Was Steve Jobs employed in 1990?* and *If Steve Jobs was employed, who was his employer?* Furthermore, abstract questions such as *what is the employment history of Steve Jobs?* are often generic in nature to have a many-to-one mapping since many questions can have the same abstract question. This is in contrast to decomposition where there is often a one-to-many mapping since there are multiple decomposed sub-problems necessary to solve a given question.

---

## Conclusion

We introduce Step-Back Prompting as a simple yet generic method to elicit deep reasoning via abstraction in large language models. Experimentation on LLMs across fact-seeking, commonsense reasoning and domain-specific reasoning benchmarks shows that Step-Back Prompting significantly improves model performance. We hypothesize that abstraction helps models to hallucinate less and reason better, probably reflecting the true nature of the model which are often hidden while responding to the original question without abstraction. We hope our work will inspire more human-inspired approaches to elicit the hidden potential of large language models.

---

## Appendix: GSM8K Results

**Table 4: Step-Back Prompting on GSM8K.**

| Method | GSM8K |
|--------|-------|
| PaLM-2L | 75.8% (0.2%) |
| **PaLM-2L 1-shot** | **84.5%** (0.4%) |
| **PaLM-2L + CoT** | **84.4%** (0.2%) |
| PaLM-2L + CoT 1-shot | 81% (0.2%) |
| PaLM-2L + TDB | 82.2% (0.2%) |
| PaLM-2L + DP | 82.2% (0.08%) |
| **PaLM-2L + Step-Back (ours)** | **84.3%** (0.2%) |

Step-Back Prompting achieved competitive performance together with zero-shot CoT and 1-shot standard prompting. We hypothesize that the simplicity of principles (e.g. addition, subtraction, etc.) in GSM8K makes it not absolutely necessary to retrieve the principles first before reasoning. Nonetheless, Step-Back Prompting is the most competitive among all the prompting methods tested.

---

## Appendix: TimeQA Error Analysis

Compared to the predictions of baseline PaLM-2L, Step-Back Prompting can fix 39.9% of the predictions where the baseline prediction is wrong, while causing 5.6% errors. Furthermore, Step-Back + RAG fixes 21.6% errors coming from RAG. The percentage of errors introduced by Step-Back Prompting to RAG is still relatively low (6.3%). This shows that Step-Back Prompting is helpful most of the time, signifying the need and effectiveness of doing Abstraction before directly addressing the original question.

[IMAGE: Figure 4 - Error Analysis of Step-Back Prompting on TimeQA showing Step-Back + RAG vs Baseline predictions and Step-Back RAG vs RAG predictions.]

---

## Appendix: StrategyQA Error Analysis

Compared to the baseline, Step-Back + RAG can turn 15.4% wrong predictions into correct predictions, while leading to 6.1% errors the other way around. Furthermore, Step-Back + RAG fixes 12.7% errors coming from RAG. The errors introduced to RAG by Step-Back are just 4.4%.

[IMAGE: Figure 5 - Error Analysis of Step-Back Prompting on StrategyQA.]

---

## Appendix: Dataset Details

**Table 5: Stats of the evaluation datasets used in this paper.**

| Domain | Dataset | Split | Number of Examples |
|--------|---------|-------|-------------------|
| STEM | MMLU high-school Physics | Test | 151 |
| STEM | MMLU high-school Chemistry | Test | 203 |
| STEM | GSM8K | Test | 1319 |
| Knowledge QA | TimeQA | Test | 5226 |
| Knowledge QA | TimeQA Easy | Test | 2613 |
| Knowledge QA | TimeQA Hard | Test | 2613 |
| Knowledge QA | SituatedQA | Test | 2901 |
| Multi-hop Reasoning | MuSiQue | Dev | 2417 |
| Multi-hop Reasoning | StrategyQA | Dev | 229 |

---

## Appendix: Evaluation Details

Given the model free-form outputs and the target label, we use one positive and one negative output as few-shot examples to demonstrate to the scoring model how to score the output. We parse out the "Yes" or "No" answer from the scoring model output as a TRUE or FALSE score of the model output.

We use PaLM-2L as the scoring model for evaluation with sampling temperature T=1, which gives highly-accurate evaluation. Out of 4 trials on 100 sampled test examples, the model scoring agrees with human ratings 97%, 98%, 99% and 99% of the time.

---

## Appendix: STEM Prompts

For MMLU high-school Physics and Chemistry, we first prompt the model to generate the first principles behind the question. Using the generated first principles, we further prompt the model to generate the final answer through few-shot demonstrations.

**MMLU Physics/Chemistry First-Principle Prompt:**

```
You are an expert at Physics/Chemistry. You are given a Physics/Chemistry problem.
Your task is to extract the Physics/Chemistry concepts and principles involved in
solving the problem. Here are a few examples:

Question: <Question Example1>
Principles Involved: <Principles Example1>
...
Question: <Question Example5>
Principles Involved: <Principles Example5>
Question: <Question>
Principles Involved:
```

**MMLU Physics/Chemistry Final Answer Prompt:**

```
You are an expert at Physics/Chemistry. You are given a Physics/Chemistry problem
and a set of principles involved in solving the problem. Solve the problem step by
step by following the principles. Here are a few examples:

Question: <Question Example1>
Principles: <Principles Example1>
Answer: <Answer Example1>
...
Question: <Question Example5>
Principles: <Principles Example5>
Answer: <Answer Example5>
Question: <Question>
Principles: <Principles>
Answer:
```

**Example MMLU Physics Demonstration:**

Question: A spherical conductor carries a net charge. How is this charge distributed on the sphere?
- 0) The charge is evenly distributed on the surface.
- 1) The charge resides on the surface only; the distribution of charge on the surface depends on what other charged objects are near the sphere.
- 2) The charge moves continually within the sphere.
- 3) The charge is distributed uniformly throughout the sphere.

Principles: Coulomb's Law: the force between two charged particles is proportional to the product of their charges and inversely proportional to the square of the distance between them, F = k * q1 * q2 / r, where F is the electric force, k is a constant, q1 and q2 are the charges the particles carry, and r is the distance between them.

Answer: Using the Principles of Coulomb's Law, we can solve the problem as following:

Step 1: Apply Coulomb's Law to find out how charges are distributed on the surface.
In the case of a spherical conductor, the charges on the surface will repel each other. The further apart the charges are, the less force they will exert on each other. Therefore, the charges will distribute themselves evenly on the surface of the sphere, as this is the configuration that minimizes the repulsive force between them.

Step 2: Apply Coulomb's Law to find out what happens if there are other charges present.
The distribution of charge on the surface may also be affected by the presence of other charged objects near the sphere. For example, if a negatively charged object is brought near a positively charged sphere, the negative charges on the sphere will be repelled and will move to the opposite side of the sphere. This will result in a non-uniform distribution of charge on the surface of the sphere.

Therefore, the correct answer is 1) The charge resides on the surface only; the distribution of charge on the surface depends on what other charged objects are near the sphere.

---

## Appendix: Example Wins from Step-Back Prompting

**TimeQA Examples:**

| Original Question | Original Answer [Incorrect] | Stepback Question | Final Answer [Correct] |
|-------------------|---------------------------|-------------------|----------------------|
| Carlos Ascues played for which team from 2013 to 2014? | Carlos Ascues played for Benfica from 2013 to 2014. | Which teams did Carlos Ascues play for? | From 2013 to 2014, Carlos Ascues played for the Greek team Panetolikos. |
| Seth Nana Twumasi played for which team between Jan 2011 and Feb 2011? | Seth Nana Twumasi played for the FC Honka team between Jan 2011 and Feb 2011. | Which teams did Seth Nana Twumasi play for? | Northampton. He was on a loan transfer from Peterborough. |
| What position did Carmel Hanna take in May 2002? | According to the article, Carmel Hanna was appointed as Minister of State for Children and the Family in May 2002. | What positions did Carmel Hanna hold? | From the context, we can see that Carmel Hanna was named minister of Employment and Learning (2001). We can then infer that she held the position of Minister for Employment and Learning in May 2002. |

**SituatedQA Examples:**

| Original Question | Original Answer [Incorrect] | Stepback Question | Final Answer [Correct] |
|-------------------|---------------------------|-------------------|----------------------|
| when was the last time miss texas won miss america as of November 29, 2010 | Laura Leigh Covington was the last Miss Texas to win the Miss America competition. This happened in 2000. | which years did miss texas win miss america | According to Wikipedia, the last time Miss Texas won Miss America was in 1975. |
| when is the last time congress passed a complete budget as of 2021 | The last time Congress passed a complete budget as of 2021 was on January 19, 2018. | what are the years that congress passed a complete budget as of 2021 | The last time Congress passed a complete budget as of 2021 was December 27, 2020, the Consolidated Appropriations Act, 2021. |
