# Principled Personas: Defining and Measuring the Intended Effects of Persona Prompting on Task Performance

- **arXiv ID**: 2508.19764
- **Authors**: Pedro Henrique Luz de Araujo, Paul Rottger, Dirk Hovy, Benjamin Roth
- **Affiliations**: University of Vienna, Bocconi University
- **Code**: https://github.com/peluz/principled-personas

## Abstract

Expert persona prompting -- assigning roles such as "expert in math" to language
models -- is widely used for task improvement. However, prior work shows mixed
results on its effectiveness, and does not consider when and why personas
_should_ improve performance. We analyze the literature on persona prompting for
task improvement and distill three desiderata: 1) performance advantage of
expert personas, 2) robustness to irrelevant persona attributes, and 3) fidelity
to persona attributes. We then evaluate 9 state-of-the-art LLMs across 27 tasks
with respect to these desiderata. We find that expert personas usually lead to
positive or non-significant performance changes. Surprisingly, models are highly
sensitive to _irrelevant_ persona details, with performance drops of almost 30
percentage points. In terms of fidelity, we find that while higher education,
specialization, and domain-relatedness can boost performance, their effects are
often inconsistent or negligible across tasks. We propose mitigation strategies
to improve robustness -- but find they only work for the largest, most capable
models. Our findings underscore the need for more careful persona design and for
evaluation schemes that reflect the intended effects of persona usage.

## Key Contributions

1. **Systematic literature review** of prior work using persona prompting for
   task improvement, identifying what kinds of personas are used and what types
   of tasks they target.

2. **Three desiderata for persona prompting** with corresponding metrics:
   - Expertise Advantage
   - Robustness to irrelevant attributes
   - Fidelity to relevant attributes

3. **Benchmark of 9 state-of-the-art open-weight LLMs** across 3 model families
   (Gemma-2, Llama-3, Qwen2.5) and size magnitudes, using 27 tasks covering
   factual QA, reasoning, and mathematics.

4. **Mitigation strategies** explicitly designed to enforce the desiderata,
   evaluated for effectiveness.

---

## 1. Introduction

Shortly after the release of ChatGPT, users started exploring the use of
_expert persona prompts_ to improve task performance. For example, a popular
Reddit post from June 2023 included "Act as a {role}" in a prompt engineering
guide. Since then, a large body of academic research has sought to evaluate the
impact of different personas on LLM task performance, often finding conflicting
results.

The focus of prior work has been almost entirely _descriptive_, measuring which
personas matter for which tasks and which models. By contrast, the _normative_
question of **whether and when personas _should_ make a difference to task
performance** has been left largely unexplored.

This is a missed opportunity because, from a model development perspective, it
is much more valuable to define what effects from persona prompting are
desirable or not, and to then compare these expectations to real model
behaviors. For example:

- Personas that specify _relevant domain expertise_ should, at a minimum, not
  have negative effects on task performance.
- Personas that are _irrelevant_ to the task (such as the persona's name) should
  not affect task performance at all.

Even state-of-the-art models like Llama-3.1-70B and Qwen2.5-72B are often not
robust to irrelevant persona attributes such as names and favorite colors.

---

## 2. Literature Review: Persona Prompting for Task Performance Improvement

### 2.1 Review Methodology

On October 17th 2024, the authors searched the ACL Anthology for papers
published in or after 2021 using the keywords "persona" and "role-play". This
resulted in 170 papers, of which 9 papers used personas explicitly to improve
task performance. Recursive examination of citations identified an additional 12
papers, for a total of 21 papers.

### 2.2 Review Findings

**Tasks**: Persona prompting is used across a wide range of tasks, from
closed-form tasks such as code generation, mathematical reasoning, and factual
QA, to more open-ended settings like research ideation and creative writing.

**Types of personas**: The types of personas used are diverse:

- Task-relevant attributes: occupation (medical doctor, software developer),
  domain expertise (LLM-generated domain expert, expert in computer science,
  information specialist)
- Unconventional or abstract personas: devil's advocate, inanimate objects
  (e.g., a coin for a coin-flipping task)
- Attributes with unclear relevance: persona names, age, education level

**Models**: The set of models used is quite restricted. 15 out of 21 papers
evaluate only OpenAI models -- often without specifying which one, referring
vaguely to ChatGPT or GPT-3.5.

**Methodological gaps**: Most prior work does not systematically differentiate
between relevant and irrelevant persona attributes. Issues include:

- Unequal comparisons (e.g., using a stronger model to process persona
  responses)
- Lack of no-persona controls
- Limited model diversity

### 2.3 Papers Using Persona Prompting for Task Improvement

| Paper                | Personas                                                | Dataset                                    |
| -------------------- | ------------------------------------------------------- | ------------------------------------------ |
| Lin et al. 2022      | Professor Smith                                         | TruthfulQA                                 |
| He et al. 2023       | Cause and effect analysts                               | WIKIWHY, e-CARE                            |
| Li et al. 2023       | Task-specific AI user/assistant                         | Machine-generated prompts                  |
| Salewski et al. 2023 | Neutral personas, task experts                          | MMLU                                       |
| Wang et al. 2023     | Information specialist                                  | CLEF TAR                                   |
| White et al. 2023    | Security expert                                         | Output customization                       |
| Xu et al. 2023       | In-context generated experts                            | Alpaca                                     |
| Chan et al. 2024     | Critic, psychologist, news author, general public       | FairEval, TopicalChat                      |
| Chen et al. 2024a    | Problem solving experts                                 | MMLU subsets                               |
| Chen et al. 2024b    | LLM-generated expert agents                             | FED, Commongen, MGSM, BIG-Bench, HumanEval |
| Dong et al. 2024     | Analyst, coder, tester                                  | MBPP, HumanEval, APPS, CoderEval           |
| Du et al. 2024       | Professor, doctor, mathematician                        | Arithmetic, GSM8K, MMLU, BIG-Bench         |
| Hong et al. 2024     | Software dev roles                                      | HumanEval, MBPP                            |
| Kong et al. 2024     | Occupations, objects (coin, recorder)                   | MultiArith, GSM8K, BIG-Bench subsets       |
| Kim et al. 2024      | Devil's advocate                                        | Summeval, TopicalChat                      |
| Qian et al. 2024     | Software dev roles                                      | SRDD                                       |
| Tang et al. 2024     | Medical professionals                                   | MedQA, MedMCQA, PubMedQA                   |
| Wang & Sap 2024      | LLM-generated personas (domain expert, target audience) | Trivia Creative Writing, BIG-Bench         |

---

## 3. Persona Prompting Desiderata and Metrics

### 3.1 Problem Setting

Let P be a set of personas, where each persona p in P can be assigned to a
language model. This set includes an empty persona (no-persona baseline). Given
a task T, performance is measured using a metric M(p, T) that measures the
correctness of responses under persona p.

Each persona p is characterized by attributes included in the persona prompt.
These attributes may be nominal (e.g., domain of expertise) or ordinal (e.g.,
level of education).

### 3.2 Desideratum 1: Expertise Advantage

> Personas that specify _task-aligned domain expertise_ should perform on par or
> better than a no-persona baseline.

**Rationale**: Prior work uses _expert_ personas to improve performance in tasks
such as reasoning, coding, and question answering. While ideally a model should
demonstrate task competence by default, expert personas _should not degrade_
task performance.

**Metric: Expertise Advantage**

```
Adv_M(exp_T, T) = M(exp_T, T) - M(baseline, T)
```

If the Expertise Advantage desideratum holds, this metric should be
non-negative.

### 3.3 Desideratum 2: Robustness

> Personas that specify _task-irrelevant attributes_ should not affect model
> performance.

**Rationale**: Some studies incorporate personas with names or other
non-task-related attributes (e.g., "Alice", "Gustavo") without systematically
evaluating whether these attributes affect outcomes. Even though these
attributes are unrelated to the task, they may introduce variance or spurious
effects.

**Irrelevant personas** have an attribute that is _irrelevant_ for a given task
and therefore should not influence model correctness. For example, the persona
"Gustavo" is irrelevant for math tasks, while "expert in math", "uneducated
person", and "expert in history" are relevant.

**Metric: Robustness**

Inspired by worst-group accuracy evaluation from the robustness literature:

```
Rob_M(I_T, T) = min_{p in I_T} Adv_M(p, T)
```

If the Robustness desideratum holds, this metric should be zero (irrelevant
personas do not affect model performance).

### 3.4 Desideratum 3: Fidelity

> Personas that specify _relevant attributes_, such as specialization or
> education level, should shape model performance in ways consistent with those
> attributes.

**Rationale**: Previous studies assume that models can adapt according to
persona attributes such as education level or professional expertise.

**Three attribute hierarchies for Fidelity**:

1. **Degree of Domain Match**:
   - In-domain expert (exp_T): expertise directly matches task domain
   - Related-domain expert (exp\_~T): expertise related but not exact match
   - Out-of-domain expert (exp_not-T): expertise neither matches nor relates

2. **Level of Specialization**:
   - Broad expert: e.g., "an expert in math"
   - Focused expert: e.g., "an expert in abstract algebra"
   - Niche expert: e.g., "an expert in groups and rings"

3. **Level of Education**: Ranging from uneducated to graduate-level

**Metric: Fidelity**

Kendall rank correlation coefficient tau between expected and observed
orderings:

```
Fid_M(P) = tau(O_attr(P), O_M(P))
```

If the Fidelity assumption holds, the metric should be positive. A value of 1
indicates perfect alignment, -1 indicates complete reversal, and values close to
0 suggest weak or no consistent relationship.

---

## 4. Experimental Setup

### 4.1 Models

9 instruction-tuned open-weight language models across 3 model families:

| Family  | Sizes                   |
| ------- | ----------------------- |
| Gemma-2 | 2B, 9B, 27B             |
| Llama-3 | 3.2-3B, 3.1-8B, 3.1-70B |
| Qwen2.5 | 3B, 7B, 72B             |

All models downloaded from official Hugging Face repos, using temperature of
zero for deterministic generation.

### 4.2 Datasets and Tasks

27 tasks from five datasets:

| Dataset    | Tasks                                                                           | Instances |
| ---------- | ------------------------------------------------------------------------------- | --------- |
| TruthfulQA | TruthfulQA                                                                      | 817       |
| GSM8K      | GSM8K                                                                           | 1,319     |
| MMLU-Pro   | Biology, Business, Chemistry, CS, Economics, Engineering, Health, History, Law, | 11,133    |
|            | Math, Other, Philosophy, Physics, Psychology                                    |           |
| BIG-Bench  | Knowledge conflicts, Logic grid puzzle, StrategyQA, Tracking shuffled objects   | 2,407     |
| MATH       | Algebra, Counting & probability, Geometry, Intermediate algebra, Number theory, | 5,000     |
|            | Prealgebra, Precalculus                                                         |           |
| **Total**  |                                                                                 | 21,575    |

### 4.3 Persona Sets

**For Expertise Advantage**:

- **Static experts**: Manually written to reflect expected domain knowledge
  (e.g., "expert in biology" for MMLU-Pro biology)
- **Dynamic experts**: Instance-specific, generated using Gemma-2-27B-it with
  three specialization levels (broad, focused, niche)

**For Robustness**:

- **Name personas**: 12 names from UniversalPersona dataset (culturally diverse,
  gender-balanced): Alexander, Victor, Muhammad, Kai, Amit, Gustavo, Anastasia,
  Isabelle, Fatima, Yumi, Aparna, Larissa
- **Color personas**: 6 colors: red, blue, green, yellow, black, white

**For Fidelity**:

- **Education level personas**: Uneducated, primary school, middle school, high
  school, college-level, graduate level
- **Out-of-domain experts**: 5 per dataset (e.g., for TruthfulQA: cryptography,
  marine biology, urban planning, chess, quantum mechanics)

---

## 5. Results

### 5.1 Expertise Advantage

**Finding**: In most tasks, expert personas (static or dynamic) have a positive
or non-significant effect on task performance. Models generally fulfill the
desideratum.

- Success rates (positive or non-significant) vary between 78% and 100%
- Llama-3.1-70B is particularly successful with dynamic personas: 100% success
  rates across all specialization levels, with 37% strict improvement when
  role-playing focused experts

**Caveat**: Expert personas can still negatively impact performance in a
non-negligible number of tasks. Gemma-2-27b has negative Expertise Advantage in
22% of tasks when role-playing niche experts.

### 5.2 Robustness

**Finding**: Irrelevant personas often have a significant effect on performance.
Models are often not successful in fulfilling the Robustness desideratum.

- Significant negative effects range from 14% (Qwen2.5-3B, color) to 59%
  (Llama-3.1-70B, color; Llama-3.1-8B, name) of tasks
- Surprisingly, irrelevant personas sometimes have a _positive_ effect (3-14% of
  tasks), meaning the default no-persona model performs worse than _all_
  irrelevant personas

### 5.3 Fidelity

**Education**: The biggest Llama-3 and Gemma-2 models are often faithful to
personas' education level, with success rates 51-88%. Smaller variants and all
Qwen models mostly have non-significant education Fidelity.

**Domain match**: Positive domain-match Fidelity is more frequent than negative,
but in most cases domain-match Fidelity is not significant. In-domain, related,
and out-of-domain experts often perform similarly.

**Specialization level**: Non-significant cases are most frequent, ranging from
74-88%.

### 5.4 Persona and Model Scale Effects

Mixed-effects regression analysis reveals:

**Persona type effects**:

- Dynamic expert personas produce significant gains, especially focused and
  niche experts
- Broad and static experts have positive but non-significant effects
- Irrelevant personas (names, colors) yield significant performance drops

**Persona attribute effects**:

All three ordinal attributes show significant positive correlations:

- Education level: +0.7 percentage points per level
- Domain match: +0.2 percentage points per level
- Specialization degree: +0.8 percentage points per level

**Model scale effects**:

- Scale has **no significant effect** on: Robustness, education Fidelity,
  specialization Fidelity, or static Expertise Advantage
- Scale **does improve**: domain match Fidelity and dynamic expert performance

**Takeaway**: Increasing model size alone is not a reliable strategy for
improving Robustness or certain Fidelity types, though larger models may better
adapt to contextually appropriate personas.

### 5.5 Cross-task Consistency

Effects are generally consistent across models, particularly within the same
family. For example:

- Expertise improves (or does not harm) history and contextual-parametric
  knowledge conflicts performance in all models
- Expertise harms (or does not improve) physics and engineering performance

---

## 6. Mitigation Strategies

### 6.1 Methodology

Three alternative prompting methods designed to guide model behavior more
directly than merely including a persona description:

**1. Instruction**: Explicitly formulates the desiderata as behavioral
constraints within the prompt:

```
{Persona description}. Your responses must adhere to the following constraints:
1. If your persona implies domain expertise, provide responses that reflect its specialized knowledge.
2. Your responses should align with the knowledge level and domain knowledge expected from this persona.
3. Attributes that do not contribute to the task should not influence reasoning, knowledge, or output quality.
{Task instruction and input}
```

**2. Refine**: Two-step approach:

1. Model produces baseline answer without any persona
2. Second prompt instructs model to revise response while adopting the persona

Hypothesis: Including the no-persona response will have an anchoring effect,
reducing the influence of irrelevant persona attributes.

**3. Refine + Instruction**: Combines both approaches -- two-step refinement
with explicit behavioral constraints.

### 6.2 Results

**Overall**: Mitigation strategies negatively impact Expertise Advantage and
Robustness for smaller models, increasing the number of tasks where experts and
irrelevant personas reduce performance.

**For largest models (Llama-3.1-70B, Qwen-2.5-72B)**:

- Mitigation strategies **preserve** Expertise Advantage
- Mitigation strategies **significantly improve** Robustness

**Fidelity**: No consistent improvement and often declines, even in the largest
models -- particularly under Refine and Refine+Instruction. This is attributed
to anchoring effects: conditioning on the no-persona response constrains the
model's ability to vary its behavior across personas.

**Takeaway**: Mitigation strategies reduce the performance of smaller models,
but they improve Robustness and preserve the Expertise Advantage of the largest
models. Refinement strategies limit Fidelity by constraining persona-driven
variation.

---

## 7. Conclusion

Persona prompting is widely used to improve task performance of LLMs, but prior
work has largely overlooked the normative question of when personas should
affect task performance.

**Key findings**:

1. Expert personas often helped or maintained performance, but occasionally
   harmed it
2. Irrelevant attributes like names or colors frequently degraded performance,
   even for the largest models
3. Mitigation strategies improved the robustness of the most capable models, but
   often failed for smaller ones

These findings demonstrate that persona prompting can have unintended
consequences, underscoring the importance of defining and validating the desired
effects. By formulating concrete desiderata and metrics, the authors provide a
framework for identifying and measuring such failure cases, supporting more
intentional and principled design of persona-related model behaviors.

---

## Limitations

**Focus on objective tasks**: Experiments limited to tasks with clear ground
truth. Personas are also widely used in open-ended settings (creative writing,
research ideation) where evaluation is more subjective.

**Single-persona setup**: Only one persona per instance considered, while some
prior work explores multi-agent or collaborative scenarios.

**Single-attribute personas**: Each persona includes only one attribute. Real-
world applications often combine multiple attributes.

---

## Prompt Templates

### Base Prompt

```
{Persona description (e.g., You are an expert in math)}.
{Task instruction and input}
```

### Instruction Prompt

```
{Persona description}. Your responses must adhere to the following constraints:
1. If your persona implies domain expertise, provide responses that reflect its specialized knowledge.
2. Your responses should align with the knowledge level and domain knowledge expected from this persona.
3. Attributes that do not contribute to the task should not influence reasoning, knowledge, or output quality.
{Task instruction and input}
```

### Refine Prompt

```
{Task instruction and input}
{Model response}
Now, refine your response while adopting the persona: {Persona description}. Your refined response should **not** reference or acknowledge the original response---answer as if this is your first response. Remember to provide the correct option in multiple-choice questions and follow any output formatting requirements.
```

### Instruction + Refine Prompt

```
{Task instruction and input}
{Model response}
Now, refine your response while adopting the persona: {Persona description}. Your revised response must adhere to these constraints:
1. If your persona implies domain expertise, refine the response to reflect the persona's specialized knowledge.
2. Your refined response should align with the knowledge level and domain knowledge expected from this persona.
3. Attributes that do not contribute to the task should not influence reasoning, knowledge, or output quality of the refined response.
4. Your refined response must adhere to all task-specific formatting requirements.
Your refined response should **not** reference or acknowledge the original response---answer as if this is your first response.
```

---

## Practical Implications for Prompt Engineering

1. **Expert personas are generally safe**: They usually provide positive or
   neutral effects, but be aware of occasional negative impacts

2. **Avoid irrelevant persona attributes**: Names, favorite colors, and other
   task-irrelevant details can significantly degrade performance (up to ~30
   percentage points)

3. **Scaling doesn't solve robustness**: Even the largest models (70B+) remain
   sensitive to irrelevant persona attributes

4. **Mitigation strategies work for large models only**: Explicit instructions
   about expected behavior help large models but hurt smaller ones

5. **Fidelity is inconsistent**: While models generally follow education and
   domain hierarchies, the effects are often negligible or task-dependent

6. **Test persona effects empirically**: Given the inconsistent results, always
   validate persona prompting on your specific task and model combination
