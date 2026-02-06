# PEARL: Prompting Large Language Models to Plan and Execute Actions Over Long Documents

- **arXiv**: [2305.14564](https://arxiv.org/abs/2305.14564)
- **Date**: 2023-05-23
- **Authors**: Simeng Sun, Yang Liu, Shuohang Wang, Chenguang Zhu, Mohit Iyyer
- **Affiliations**: University of Massachusetts Amherst, Microsoft Research
- **Code**: https://github.com/SimengSun/pearl

## Abstract

Strategies such as chain-of-thought prompting improve the performance of large language models (LLMs) on complex reasoning tasks by decomposing input examples into intermediate steps. However, it remains unclear how to apply such methods to reason over long input documents, in which both the decomposition and the output of each intermediate step are non-trivial to obtain. This work proposes PEARL, a prompting framework to improve reasoning over long documents, which consists of three stages: action mining, plan formulation, and plan execution. Given a question about a long document, PEARL decomposes the question into a sequence of actions (e.g., SUMMARIZE, FIND_EVENT, FIND_RELATION) and then executes them over the document to obtain the answer. Each stage of PEARL is implemented via zero-shot or few-shot prompting of LLMs (GPT-4) with minimal human input. Evaluated on a challenging subset of the QuALITY dataset containing questions that require complex reasoning over long narrative texts, PEARL outperforms zero-shot and chain-of-thought prompting. Ablation experiments show that each stage of PEARL is critical to its performance.

## Problem Statement

Complex reasoning over long documents requires:

1. Forming high-level abstractions of the text (plots, themes in narratives)
2. Conducting various inferences on those abstractions
3. Gathering, evaluating, and synthesizing information across the document

Chain-of-Thought prompting is not well-suited for long documents because:

- Decomposition of the original question is non-trivial
- Intermediate outputs of each step are difficult to obtain
- Few-shot examples cannot fit in context alongside long documents

## PEARL Framework

PEARL combines **P**lanning and **E**xecutable **A**ctions for **R**easoning over **L**ong documents.

### Three Stages

```
[Training Questions] --> Action Mining --> [Action Set]
                                               |
                                               v
[Test Question] ---------> Plan Generation --> [Plan]
                                               |
                                               v
[Long Document] ---------> Plan Execution --> [Answer]
```

### Stage 1: Action Mining

**Goal**: Learn dataset-specific actions from training questions without human-designed toolboxes.

**Process**:

1. Start with 7 manually created seed actions as demonstrations
2. For each training question, prompt LLM to generate task-specific actions
3. Reduce actions from ~407 to 81 via LLM-based simplification and abstraction

**Seed Actions**:

```
CONCAT(S1, S2, ...)    - Concatenate inputs
EXTRACT(CTX, X)        - Extract exact wording from context
FIND_X(CTX, X)         - Find and summarize relevant information
FIND_REASON(CTX, X)    - Find cause or reason of X
FIND_MORAL(CTX)        - Find intended lesson or moral
SUMMARIZE(CTX)         - General summary
SUMMARIZE_X(CTX, X)    - Summary about X
```

**Example Mined Action**:

```
ANALYZE(CTX, X, Y)  # Analyze the relationship, attitude, or feelings
                    # between X and Y given the input context CTX
```

**Action Mining Prompt Template**:

```
[Actions]
- CONCAT(S1, S2, ...) : Concatenate the input S1, S2, ...
- EXTRACT(CTX, X) : Extract the exact wording that X is referring to from input CTX.
- FIND_X(CTX, X): Find and summarize all relevant information about X in the input CTX.
[... more seed actions ...]

[Instructions]
Suppose you are given a question about an article as well as a list of actions
that you can execute to solve the question. You can imagine the actions as
functions in a program, where you have input arguments and output. The output
of an action can be fed as input to another action.

[Rules]
1. The present sequence should be minimal, i.e., no unnecessary actions.
2. The sequence of actions should be specific and cover every detail about the question.
3. The sequence of actions should use as many existing actions as possible.
4. New actions should be maximally reusable and generalizable.
5. The arguments should cover all the details of the given question.

[Question]
{Question}

[Answer Format]
My new actions (if any):
- my_new_action_1(arguments) : [one-sentence explanation]

My sequence of actions:
1. output_1 = action_1(arguments) : [one-sentence explanation]
2. output_2 = action_2(arguments) : [one-sentence explanation]
```

### Stage 2: Plan Generation

**Goal**: Generate an executable plan for a given question using mined actions.

**Key Design Choices**:

- Plan is formatted as a simple program
- Output variables can serve as arguments to future actions (enables composition)
- Document is NOT shown during plan generation (saves context for few-shot examples)
- Model-generated plans are self-refined before use as demonstrations

**Plan Format**:

```
output = ACTION(arg1, arg2, ...)
```

Arguments can be:

1. The input document (CTX)
2. A string literal
3. An output variable from previous steps

**Example Plan**:

```
Question: "How do Ross and Mehta view Brown's acquisition of the magazine?"

New actions:
- FIND_OPINION(CTX, X, Y) : Find the opinion of X about Y given the input CTX

1. ross = FIND_CHARACTER(CTX, "Ross") : Identify who Ross is
2. mehta = FIND_CHARACTER(CTX, "Mehta") : Identify who Mehta is
3. brown = FIND_CHARACTER(CTX, "Brown") : Identify who Brown is
4. magazine_acquisition = FIND_EVENT(CTX, "Brown's acquisition of the magazine")
5. ross_opinion = FIND_OPINION(CTX, ross, magazine_acquisition)
6. mehta_opinion = FIND_OPINION(CTX, mehta, magazine_acquisition)
7. ans = CONCAT(ross_opinion, mehta_opinion)
```

### Stage 3: Plan Execution

**Goal**: Execute the plan step-by-step over the long document.

**Key Design Choices**:

- Only stage that includes the full document
- Zero-shot execution (document is too long for few-shot)
- Each step fills a template with outputs from previous stages

**Execution Prompt Template**:

```
Article
{Long document}
End of Article
---
Please read the above text first, and then follow the instructions below.

[Instructions]
{Action definition, e.g., FIND_EMOTION(CTX, X, Y) # Find the emotion...}

{Current step, e.g., kolin_opinion = FIND_EMOTION(CTX, kolin, "becoming a tree")}

{Value assignment of input arguments from previous steps}
X = "In the story, Kolin is a steward from..."
Y = "becoming a tree"

[Answer]
{Brief description of current step}
```

### Self-Correction and Self-Refinement

1. **Self-correction**: Parser validates plan syntax; invalid plans are sent back to LLM with error messages
2. **Self-refinement**: Model-generated plans are validated by executing and evaluating the answer; rejected plans are refined before use as few-shot examples

## Evaluation Setup

### Dataset: QuALITY Subset

- **Task**: Generative QA (not multiple-choice) over long narratives
- **Evaluation**: Map generated answer to multiple-choice option via LLM
- **Data splits**:
  - **Long**: 330 dev + 368 train examples (human-annotated as requiring long context)
  - **Short**: 302 dev examples (control set requiring short context)

### Answer Mapping Validation

Human annotators agreed with ~83% of GPT-4 mappings (kappa = 0.677). Disagreements typically occur when answers could map to multiple options or none.

## Results

### Main Results

| Method              | Long     | Short    | All      | p-value |
| ------------------- | -------- | -------- | -------- | ------- |
| GPT-3.5 zero-shot   | 45.5     | 56.3     | 48.8     | 0.000   |
| GPT-4 zero-shot     | 64.3     | **79.1** | 68.8     | -       |
| GPT-4 zero-shot CoT | 65.9     | 77.2     | 69.3     | 0.766   |
| GPT-4 PEARL         | **70.9** | 77.8     | **73.0** | 0.005   |

### Ablation Results

| Ablation            | Long | Short | All  |
| ------------------- | ---- | ----- | ---- |
| PEARL (full)        | 70.9 | 77.8  | 73.0 |
| w/o plan execution  | 67.3 | 77.2  | 70.3 |
| w/o self-refinement | 67.0 | 78.8  | 70.6 |

### Key Findings

1. **PEARL improves long-context QA**: 70.9% vs 64.3% baseline (6.6 point gain)
2. **Largest gains on hardest questions**: 72.4% vs 61.9% for longest-context questions
3. **Number of actions matters**: ~81 actions optimal; 1 action drops to 64%, 140 actions degrades performance
4. **Execution is necessary**: Removing execution loses ~3 points
5. **Self-refinement critical**: Without it, ~3 point drop

### Accuracy by Reasoning Type

| Reasoning Type | PEARL | Zero-shot | Significant?     |
| -------------- | ----- | --------- | ---------------- |
| Why/reason     | 79%   | 71%       | Yes (p<0.005)    |
| Person         | 75%   | 66%       | Yes (p<0.005)    |
| Not/except     | 70%   | 53%       | Yes (p<0.005)    |
| Description    | 73%   | 73%       | No               |
| Numeric        | 67%   | 78%       | No (PEARL worse) |

## Plan Statistics

- Average plan length: ~4 actions
- Unique actions per plan: ~3.4
- Most frequent actions:
  1. CONCAT (for aggregation)
  2. FIND_CHARACTER
  3. COMPARE
  4. FIND_EMOTION

## Error Analysis

From 40 incorrect PEARL answers:

| Error Type                      | %     | Description                                      |
| ------------------------------- | ----- | ------------------------------------------------ |
| True Negative (Execution Error) | 55%   | Plan correct but execution produced wrong output |
| True Negative (Plan Error)      | 17.5% | Plan itself has critical issues                  |
| Other                           | 15%   | Answer depends on options or lacks detail        |
| False Negative                  | 12.5% | Correct answer mapped to wrong option            |

**Example Execution Error**:

- Question: "How many adult characters have speaking roles?"
- PEARL found 3 characters instead of 2 (hallucinated an extra name)

**Example Plan Error**:

- Question: "Does the tone of the passage shift at all?"
- Plan only compared initial and final tone, missing intermediate changes

## Human Evaluation of Plans

- 97% of plans rated as correct (assuming error-free execution)
- Main issues identified:
  - Unnecessary steps (10% of plans)
  - Steps that could be merged
  - Missing critical information
  - Plans needing slight edits

## Comparison to Related Work

| Method             | Explicit Plan | Iterative | No External Tools | Long Documents |
| ------------------ | ------------- | --------- | ----------------- | -------------- |
| Chain-of-Thought   | No            | No        | Yes               | No             |
| Program-of-Thought | No            | No        | No                | No             |
| Self-Ask           | No            | Yes       | No                | No             |
| Toolformer         | No            | No        | No                | No             |
| ReAct              | No            | Yes       | No                | No             |
| Plan-and-Solve     | Yes           | No        | Yes               | No             |
| **PEARL**          | **Yes**       | **Yes**   | **Yes**           | **Yes**        |

## Mined Actions (Subset)

```
ANALYZE(CTX, X, Y)           - Analyze relationship/attitude/feelings between X and Y
COMPARE(CTX, X, Y, Z)        - Compare X and Y in context of Z
COMPREHEND(CTX, X)           - Detailed comprehension of X
CONCAT(S1, S2, ...)          - Concatenate strings
DEFINE(CTX, X)               - Definition of X
DESCRIBE(CTX, X, Y)          - Description of X in terms of Y
EVALUATE(CTX, X, Y)          - Evaluate aspects of X in relation to Y
FIND_BEHAVIOR_REASON(CTX, X) - Find reason behind behavior X
FIND_CHARACTER(CTX, X)       - Find character traits and changes of X
FIND_EMOTION(CTX, X, Y)      - Find emotion X feels towards Y
FIND_EVENT(CTX, X)           - Find event involving X
FIND_RELATION(CTX, X, Y)     - Find relation between X and Y
FIND_REASON(CTX, X)          - Find cause of X
INFER(CTX, X)                - Infer information about X
INTERPRET(CTX, X)            - Interpret meaning/symbolism of X
SUMMARIZE(CTX)               - General summary
SUMMARIZE_X(CTX, X)          - Summary about X
```

## Advantages of PEARL

1. **Comprehensive understanding**: Zero-shot prompting focuses on local context; PEARL considers the full document
2. **Detailed answers**: Multiple passes produce more thorough responses
3. **Domain adaptability**: Action mining from training data scales to different domains

## Limitations

1. Susceptible to hallucinations (like other prompting methods)
2. More time-consuming and costly (~4.4x more tokens, ~1.3x more generation)
3. May over-complicate simple questions
4. Bounded by LLM context window size

## Key Takeaways for Prompt Engineering

1. **Decomposition enables long-context reasoning**: Breaking questions into executable plans helps overcome CoT limitations for long documents
2. **Data-driven action discovery**: Mining actions from training data reduces manual engineering and enables domain adaptation
3. **Separate planning from execution**: Not showing the document during planning allows few-shot examples while keeping execution zero-shot
4. **Variable binding enables composition**: Using output variables as inputs to subsequent actions creates flexible reasoning chains
5. **Self-refinement improves quality**: Validating and refining model-generated demonstrations significantly boosts performance
6. **Optimal action granularity matters**: Too few actions limit expressiveness; too many make selection difficult
