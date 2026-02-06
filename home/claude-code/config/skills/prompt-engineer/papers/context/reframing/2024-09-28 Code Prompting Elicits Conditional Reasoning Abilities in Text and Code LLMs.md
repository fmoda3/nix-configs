# Code Prompting Elicits Conditional Reasoning Abilities in Text+Code LLMs

- **arXiv**: 2401.10065
- **Date**: 2024-01-18
- **Authors**: Haritz Puerto, Martin Tutek, Somak Aditya, Xiaodan Zhu, Iryna Gurevych
- **Affiliations**: TU Darmstadt, Hessian Center for AI, Technion-IIT, IIT Kharagpur, Queen's University

## Abstract

Reasoning is a fundamental component of language understanding. Recent prompting techniques, such as chain of thought, have consistently improved LLMs' performance on various reasoning tasks. Nevertheless, there is still little understanding of what triggers reasoning abilities in LLMs in the inference stage.

This paper investigates the effect of the **input representation** on the reasoning abilities of LLMs. The authors hypothesize that representing natural language tasks as code can enhance specific reasoning abilities such as entity tracking or logical reasoning. To study this, they propose **code prompting**, a methodology operationalized as a chain of prompts that transforms a natural language problem into code and directly prompts the LLM using the generated code without resorting to external code execution.

Key findings:

- Code prompting exhibits a high-performance boost for multiple LLMs (up to 22.52 percentage points on GPT 3.5, 7.75 on Mixtral, and 16.78 on Mistral) across multiple conditional reasoning datasets
- The code formatting of the input problem is essential for performance improvement
- Code representation improves sample efficiency of in-context learning
- Code representation facilitates state tracking of entities

## Core Insight

The central hypothesis is that the input representation plays a pivotal role in eliciting capabilities encoded within LLMs. Given that LLMs trained on text and code exhibit superior reasoning abilities, the authors conjecture that a code representation of a natural language problem may trigger these reasoning abilities.

More formally: given a natural language problem p, does there exist some representation space S with a transformation function f such that prompting an LLM with f(p) yields better results than prompting with p directly?

The authors fix S to the programming language space and define **code prompts** as prompts that model a natural language problem with code.

## Method: Code Prompting

Code prompting is a chain of prompts that:

1. **Transforms** natural language text into code
2. **Uses** this code to prompt the LLM to generate an answer in natural language

Key characteristics:

- The code follows the original NL text as closely as possible
- Uses simple structured code containing the logical structure needed to solve the problem
- Original NL text is preserved as code comments
- Creates variables for key entities in the question and documents
- Uses `if` blocks for each conditional statement
- **Critically**: The code is NOT executed -- there is no program state. The LLM simply reads the code and generates a natural language answer.

### Example Transformation

A natural language problem about visa eligibility with conditional statements like "If you are married and your spouse passed away, you are eligible for X" becomes:

```python
# If you are married and your spouse passed away, you are eligible for X
married = unknown
spouse_passed_away = unknown
if married and spouse_passed_away:
    eligible_for_x = true
```

## Experimental Setup

### Task

Traditional question-answering: input is a question and document, output is a span, yes, or no. All methods use chain-of-thought prompting.

### Datasets

1. **ConditionalQA (CondQA)**: Scenario-based QA dataset
2. **BoardgameQA (BGQA)**: Boardgame-based QA with conflicting rules, with subsets BGQA-1, BGQA-2, BGQA-3 (number indicates reasoning hops)
3. **ShARC**: Conversational QA with natural language rules (modified to standalone QA)

### Models

Text+code LLMs only (not code-only or text-only):

- GPT 3.5 (gpt-35-turbo)
- Mixtral 8x7B
- Mistral 7B

Rationale: Text+code LLMs can process both representations interchangeably, eliminating confounding effects of fine-tuning.

## Main Results

| Model   | Prompt | CondQA    | ShARC     | BGQA-1    | BGQA-2    | BGQA-3    | Avg Gain |
| ------- | ------ | --------- | --------- | --------- | --------- | --------- | -------- |
| GPT 3.5 | Text   | 58.70     | **62.95** | 51.15     | 37.42     | 27.77     |          |
| GPT 3.5 | Code   | **60.60** | 54.98     | **58.67** | **55.56** | **50.29** | +8.42    |
| Mixtral | Text   | **48.17** | 53.77     | **56.38** | 39.64     | 30.15     |          |
| Mixtral | Code   | 44.73     | **59.06** | 53.33     | **47.39** | **44.72** | +4.22    |
| Mistral | Text   | **35.74** | 43.60     | 47.40     | 48.78     | 47.86     |          |
| Mistral | Code   | 33.28     | **49.92** | **53.80** | **51.27** | **48.79** | +2.74    |

Key observations:

- Code prompts outperform text prompts in 11 out of 15 test cases
- Code prompts consistently surpass text prompts on BGQA-2 and BGQA-3 (most reasoning-intensive datasets)
- When text prompts win, average gain is only 4.23 points
- When code prompts win, average gain is 8.53 points

## Analysis: Why Does Code Prompting Work?

### 1. Code Syntax Elicits Reasoning (Not Just Text Simplification)

Two ablation experiments:

**I. Atomic Statements**: Transform each NL sentence into simplified atomic statements (like defining variables, but in NL)

**II. Back-Translated Code**: Transform code prompts back into NL while preserving the logical structure

Results (performance gap vs code prompts):

| Dataset | Atomic Statements | Back-Translated Code |
| ------- | ----------------- | -------------------- |
| CondQA  | -2.66             | -4.72                |
| BGQA-1  | -4.37             | -1.43                |
| BGQA-2  | -8.72             | -5.39                |
| BGQA-3  | -19.26            | -3.68                |

**Conclusion**: Neither approach matches code prompting. The code syntax itself contributes to performance improvement beyond mere simplification.

### 2. Code Semantics Matter

Three perturbation experiments:

1. **Anonymous Code**: Anonymize variables and functions
2. **Random Code**: Add irrelevant code
3. **Remove Comments**: Remove NL text from code comments

Results (performance drop vs code prompts):

| Perturbation | CondQA-YN | BGQA-1 | BGQA-2 | BGQA-3 |
| ------------ | --------- | ------ | ------ | ------ |
| Anonymous    | -2.90     | -6.60  | -4.80  | -4.00  |
| Random       | -2.67     | -7.40  | -9.20  | -9.80  |
| No Comments  | -14.02    | -16.70 | -16.20 | -5.20  |

**Key insight**: Removing NL text from comments causes the largest drop. The combination of code that represents the original NL instance AND the NL text together unlock LLM potential.

### 3. Code Prompts Are More Sample-Efficient

When comparing performance across different numbers of demonstrations:

- With 1 demo per class: largest performance gap (code >> text)
- Gap decreases with more demonstrations
- Code prompts with 1 demo outperform text prompts with 3 demos

### 4. Code Prompts Improve Variable/State Tracking

The authors hypothesize that training on code improves ability to track distant co-references (variables defined hundreds of lines earlier), which is crucial for multi-hop reasoning.

Experiment: After each reasoning step, probe the model about the state of key entities/variables.

Memory error rates (percentage of incorrect state tracking):

| Dataset | Text (Correct Ans) | Code (Correct Ans) | Text (Incorrect Ans) | Code (Incorrect Ans) |
| ------- | ------------------ | ------------------ | -------------------- | -------------------- |
| CondQA  | 71.08              | **4.39**           | 60.79                | **11.39**            |
| BGQA-1  | 39.33              | **8.84**           | 51.65                | **22.12**            |
| BGQA-2  | 44.79              | **15.04**          | 52.54                | **24.75**            |
| BGQA-3  | 54.01              | **14.21**          | 52.13                | **16.98**            |

**Dramatic finding**: Text prompts make 30-66% more memory errors than code prompts across all datasets. Code representation fundamentally improves the model's ability to track entity states.

## Human Evaluation of Generated Code

Analysis of code generation quality across 10 random samples per dataset:

- **BGQA**: Perfect translations in all cases across all models
- **ShARC**: GPT 3.5 achieved 9/10 perfect, Mixtral 7/10, Mistral 6/10
- **CondQA**: GPT 3.5 achieved 8/10, Mixtral 6/10, Mistral 4/10

Common errors: missing conditional statements, no question variable, wrong value assignments. However, original semantics remain preserved through code comments even in imperfect translations.

## Key Takeaways for Prompt Engineering

1. **Input representation matters**: The same semantic content in code format elicits stronger reasoning than natural language format

2. **Code syntax is the key ingredient**: Neither atomic statements nor back-translated code match the performance of actual code

3. **Preserve natural language as comments**: The NL text in comments is essential -- removing it causes the largest performance drop

4. **Code semantics must align with NL**: Anonymous or random code hurts performance; the code must faithfully represent the NL problem

5. **Best for reasoning-intensive tasks**: The advantage is most pronounced on tasks requiring multiple reasoning hops (BGQA-2, BGQA-3)

6. **More sample-efficient**: Code prompts require fewer demonstrations to achieve the same performance as text prompts

7. **Improves state tracking**: The fundamental mechanism appears to be improved ability to track variable/entity states across reasoning steps

## Practical Guidelines

When to use code prompting:

- Tasks requiring conditional reasoning
- Multi-hop reasoning problems
- Entity state tracking scenarios
- When you have limited demonstrations (sample efficiency benefit)

How to structure code prompts:

- Use simple, readable code (Python-like)
- Create variables for key entities
- Use `if` blocks for conditional statements
- Keep original NL text as code comments
- Variable names should be meaningful (not anonymous)
- Code logic must faithfully represent NL semantics

## Limitations

- Requires an intermediate transformation step (though this could be done by a smaller model)
- Only tested on English datasets
- Only text+code LLMs benefit (not pure text or pure code LLMs)
- Analysis ablations only performed on GPT 3.5

## Citation

```bibtex
@inproceedings{puerto2024code,
  title={Code Prompting Elicits Conditional Reasoning Abilities in Text+Code LLMs},
  author={Puerto, Haritz and Tutek, Martin and Aditya, Somak and Zhu, Xiaodan and Gurevych, Iryna},
  booktitle={Proceedings of the 2024 Conference on Empirical Methods in Natural Language Processing},
  year={2024}
}
```
