# Logic-of-Thought: Injecting Logic into Contexts for Full Reasoning in Large Language Models

- **arXiv**: [2409.17539](https://arxiv.org/abs/2409.17539)
- **Authors**: Tongxuan Liu, Wenjiang Xu, Weizhe Huang, Yuting Zeng, Jiaxing Wang, Xingyu Wang, Hailong Yang, Jing Li
- **Affiliations**: University of Science and Technology of China, Beihang University, Institute of Automation Chinese Academy of Sciences, JD.com
- **Code**: https://github.com/HEA1OR/lot

## Abstract

Large Language Models (LLMs) have demonstrated remarkable capabilities across various tasks but their performance in complex logical reasoning tasks remains unsatisfactory. Although some prompting methods, such as Chain-of-Thought, can improve the reasoning ability of LLMs to some extent, they suffer from an unfaithful issue where derived conclusions may not align with the generated reasoning chain. To address this issue, some studies employ the approach of propositional logic to further enhance logical reasoning abilities of LLMs. However, the potential omissions in the extraction of logical expressions in these methods can cause information loss in the logical reasoning process, thereby generating incorrect results. To this end, we propose Logic-of-Thought (LoT) prompting which employs propositional logic to generate expanded logical information descriptions and utilizes them as an additional augmentation to original contexts, thereby ensuring information completeness and enhancing logical reasoning ability. LoT is orthogonal to existing prompting methods and can be seamlessly integrated with them. Extensive experiments demonstrate that LoT boosts the performance of various prompting methods with a striking margin across five logical reasoning tasks. In particular, LoT enhances Chain-of-Thought's performance on the ReClor dataset by +4.35%, improves Chain-of-Thought with Self-Consistency's performance on the RuleTaker dataset by +3.52%, and boosts performance of Tree-of-Thoughts on the ProofWriter dataset by +8%.

## 1. Introduction

In recent years, Large Language Models (LLMs) have demonstrated excellent capabilities across various NLP tasks. However, even the most advanced LLMs exhibit limited performance in mathematics and complex logical reasoning tasks. Chain-of-Thought (CoT) prompting has emerged as a promising approach to improve logical reasoning capabilities, which enhances reasoning abilities by adding intermediate steps in the reasoning process.

Subsequent research has sought to simulate human reasoning processes by expanding the Chain-of-Thought into more complex reasoning topology. For example, Tree-of-Thoughts (ToT) extends into a tree-like reasoning topology, exploring more reasoning branches at each step and supporting backtracking. STaR and Chain-of-Thought with Self-Consistency (CoT-SC) generate multiple chains of thought or reasoning paths, selecting the most optimized and consistent answers from these. However, LLMs occasionally exhibit unfaithful reasoning, wherein the derived conclusions do not adhere to the previously generated reasoning chain.

To tackle the challenge of the unfaithfulness in the reasoning process, researchers have proposed many neuro-symbolic methods that integrate LLMs with symbolic reasoning, such as Faithful Chain-of-Thought, LINC, Logic-LM and SatLM. These methods follow a similar process: Initially, the problem and objectives are translated into symbolic expressions. Subsequently, symbolic results are derived through external tools such as symbolic solvers. Finally, it's optional to explain symbolic results using LLMs or interpreters. However, these existing neuro-symbolic methods inevitably suffer from the issue of information loss, which results from omissions in the extraction of logical expressions and directly leads to incorrect intermediate reasoning processes.

For example, in the extraction process of logical expressions in LINC, two key pieces of hidden information "Harry is a person" and "Walden is a book" are lost, which makes it impossible for the symbolic solver Prover9 to obtain the correct reasoning result.

To address the issue of information loss, in this paper, we propose a novel zero-shot prompting method named Logic-of-Thought (LoT). Specifically, LoT first extracts propositions and logical expressions from the input context, expands these logical expressions according to logical reasoning laws, and converts the deduced logical expressions back into natural language form. Then LoT considers these extended logical descriptions as additional logical augmentation for LLMs and concatenates it with the original context, which not only encourages LLMs to utilize these new deduced logical information when answering the original question but also ensures information completeness through preserving full original contexts for LLMs reasoning, thereby enhancing logical reasoning ability.

Additionally, the LoT prompting approach is compatible and orthogonal to existing prompting methods, enabling seamless integration of these methods. To validate the effectiveness of LoT, we conduct extensive experiments to evaluate its capability in boosting various prompting methods such as CoT, SC, CoT-SC and ToT across five logical reasoning datasets. Experimental results demonstrate that LoT prompting can seamlessly integrate with existing prompting methods and significantly boost their performance in logical reasoning.

### Main Contributions

1. We propose a novel prompting method Logic-of-Thought (LoT) to address the issue of information loss in existing neuro-symbolic methods by generating logical proposition descriptions as augmentations for original prompts.

2. We integrate LoT with a variety of distinct prompting techniques, including Chain-of-Thought (CoT), Self-Consistency (SC), Chain-of-Thought with Self-Consistency (CoT-SC), Tree-of-Thoughts (ToT), by leveraging the orthogonal capabilities of LoT.

3. We conduct extensive experiments to evaluate the effectiveness of LoT in enhancing the capabilities of different prompting techniques across diverse logical reasoning tasks. The results demonstrate the significant effectiveness of LoT in boosting the performance of various prompting methods.

## 2. Preliminary

As this study focuses on logical reasoning tasks, we first provide some definitions and symbols about the propositional logic system, which will be used throughout the paper.

- **Propositions** are defined as declarative sentences that have clear truth-value characteristic and cannot be simultaneously true and false. In this context, propositions are considered fundamental elements of logical expressions. We use standard uppercase letters such as A, B, C to symbolize specific propositions, exemplified by statements like "you have keyboarding skills", and lowercase letters such as p, q, r to refer to any proposition.

- **Connectives** are defined as operators on propositions, which can operate on a single proposition or link propositions together to form a new logical expression. In this study, we mainly focus on three connectives: NOT, IMPLIES and AND. Herein, negative NOT denotes the negation operation for a specific logical symbol (e.g., NOT p). Implication IMPLIES signifies a sufficient condition or causal relationship between two propositions (e.g., p IMPLIES q). Conjunction AND also operates on two propositions, which represents that the entire expression is true only if both propositions are true (e.g., p AND q).

- **Logical reasoning laws** are defined as the deducing relation between two logical expressions. In this study, we utilize three basic logical reasoning laws: the Double Negation Law (NOT NOT p <=> p), the Contraposition Law ((p IMPLIES q) <=> (NOT q IMPLIES NOT p)), and the Transitive Law ((p IMPLIES q) AND (q IMPLIES r) => (p IMPLIES r)), which all align with human intuition and are fundamental and widely used in propositional logic.

Although the presented logic system setting is straightforward, our paper primarily concentrates on introducing a new prompting paradigm to address information loss in existing neuro-symbolic methods. Moreover, notable enhancements have already been achieved within this setting. Therefore, we leave the exploration of incorporating more diverse connectives and laws in our method to future work.

## 3. Methodology

### Overview

LoT consists of three phases:

1. **Logic Extraction phase**: propositions and logical relations are extracted from the input context using LLMs to output logical expressions
2. **Logic Extension phase**: the logical expressions are expanded through Python-implemented logical rules
3. **Logic Translation phase**: the expanded logical expressions are translated into natural language descriptions of logical information through LLMs

Then, the logical information is incorporated into the input prompt, forming a comprehensive and novel input prompt for LLMs.

### Logic Extraction

In the Logic Extraction phase, we use LLMs to extract formal logic expressions from the input context through two stages:

1. First, we instruct LLMs to select sentences containing conditional reasoning relationships from the input context to generate collection of sentences with logical relationships
2. Subsequently, we use LLMs to extract the set of propositional symbols P and the set of logical expressions E from the collection

During the process of Logic Extraction, LLMs identify propositions with similar meanings and represent them using identical propositional symbols. Furthermore, LLMs analyze the logical relationships between propositions from their natural language descriptions, ultimately deriving the logical expressions. For propositions expressing opposite meanings, the negation is added. When there is a conditional relationship between two propositions, the implication is used to connect their corresponding propositional symbols. We also incorporate well-designed hints about logical relationships into the prompt, such as phrases like "if...then..." or "...causes..." to further guide LLMs in analyzing logical connections and minimize errors.

For example, LLMs extract the same meaning description "be able to use a computer" from two different sentences, symbolized as B. Then, through analyzing its logical relationship with other propositions, LLMs apply NOT to B and another proposition A and add IMPLIES between them, which results in a new logical expression NOT A IMPLIES NOT B.

### Logic Extension

During the Logic Extension phase, we apply logical reasoning laws to the collection of logical expressions from the Logic Extraction phase. These logical expressions can be further expanded using a Python program to implement logical deduction.

For example, the extracted logical expressions NOT A IMPLIES NOT B and NOT B IMPLIES NOT C serve as inputs for our logical deduction program. Through expansion based on Transitive Law and Contraposition Law, we finally obtain the new expression C IMPLIES A, which will be used in the next phase.

### Logic Translation

During the Logic Translation phase, we use LLMs to translate the generated extended logical expressions into natural language descriptions. Subsequently, we combine the natural language descriptions of propositional symbols according to the extended logical expressions to form a new part of the original input prompt. Through this approach, we inject the deduced logical information as additional augmentation into the original prompt, thus avoiding information loss.

For example, by associating C with its description "be able to write your essays using a word processing program", A with its description "have keyboarding skills", and IMPLIES with the logical description "if...then...", we can translate the aforementioned logical expression C IMPLIES A back to its natural language description and add it to original prompts as new input prompts.

## 4. Experiments

### Datasets

In the experiment, we employ five logical reasoning datasets:

1. **ReClor**: collected from standardized test logical reasoning questions, including the Law School Admission Test (LSAT) and the Graduate Management Admission Test (GMAT)
2. **LogiQA**: derived from expert-written questions for testing human logical reasoning
3. **RuleTaker**: automatically generated via programming, utilizing connectives including AND, NOT, and IMPLIES
4. **ProofWriter**: comprises numerous small rulebases composed of facts and rules
5. **FOLIO**: characterized by its human annotations and first-order logic annotations

### Baselines

We consider 5 widely used prompting methods and 2 neuro-symbolic methods for comparison:

**Prompting methods:**

1. Direct prompting: directly input the question
2. Self-Consistency (SC): employs majority voting to aggregate responses from multiple Direct prompting
3. CoT: utilizes a progressive thinking approach for reasoning
4. CoT-SC: applies majority voting to aggregate multiple CoT
5. ToT: models the reasoning process as a thought search tree

**Neuro-symbolic methods:**

- SatLM: leverages automated theorem provers to assist LLMs in reasoning
- LINC: uses LLMs as semantic parser to translate premises and conclusions into first-order logic expressions

### Experiment Setup

**Main experiments:** Main experiments employ four prompting methods including Direct, CoT, SC, CoT-SC and combination of these prompting methods with LoT using GPT-3.5-turbo-0125 and GPT-4-0613 across five datasets. We utilize the zero-shot setting for all methods.

- For ReClor: selected all 46 data entries in the test set pertaining to the implication section
- For ProofWriter: selected all 985 test data points conforming to the Closed-World Assumption (CWA) with depth 5
- For RuleTaker: selected all 967 test data points conforming to CWA with depth 5
- For LogiQA: selected a combined set of 1302 Chinese and English test data points
- For FOLIO: selected 135 test data entries conforming to CWA

### Main Results

Key observations from the experimental results:

1. **Combining LoT with existing prompting methods achieves best performance**: LoT+CoT-SC(5) outperforms all other methods across all five datasets with GPT-3.5-turbo-0125 and four datasets with GPT-4-0613.

2. **LoT enhances performance in most experiments**: Among total 40 comparisons (including four baseline prompting methods across five datasets with two LLMs), LoT significantly enhances the performance of baseline prompting methods in 37 instances.

3. **Minor decline on LogiQA with GPT-4**: Upon utilizing GPT-4 on the LogiQA dataset, LoT+CoT and LoT+CoT-SC marginally trailed behind CoT and CoT-SC, recording a decline of 0.57% and 1.38% respectively. The primary factor is the deviation in extracting logical information during the Logic Extraction phase.

4. **LoT standalone achieves strong results**: LoT achieves significant enhancements in the accuracy of Direct across all datasets and outperforms CoT in eight out of ten sets of comparative data, providing compelling evidence that standalone LoT can achieve or even exceed the logical reasoning capability exhibited by CoT.

#### Results Table (GPT-3.5-turbo-0125)

| Method          | ReClor            | LogiQA            | RuleTaker         | ProofWriter       | FOLIO             |
| --------------- | ----------------- | ----------------- | ----------------- | ----------------- | ----------------- |
| Direct          | 46.20             | 36.44             | 51.89             | 52.87             | 68.89             |
| LoT             | 56.02 (+9.82)     | 36.85 (+0.41)     | 59.44 (+7.55)     | 59.35 (+6.48)     | 76.00 (+7.11)     |
| CoT             | 52.17             | 39.75             | 60.56             | 61.02             | 81.19             |
| LoT + CoT       | 56.52 (+4.35)     | 41.20 (+1.45)     | 62.46 (+1.90)     | 63.35 (+2.33)     | 78.96 (-2.23)     |
| SC(5)           | 56.52             | 37.10             | 52.43             | 53.91             | 70.37             |
| LoT + SC(5)     | 58.70 (+2.18)     | 37.48 (+0.38)     | 59.98 (+7.55)     | 60.51 (+6.60)     | 77.04 (+6.67)     |
| CoT-SC(5)       | 58.70             | 41.86             | 61.63             | 62.54             | 81.48             |
| LoT + CoT-SC(5) | **60.87** (+2.17) | **42.63** (+0.77) | **65.15** (+3.52) | **65.89** (+3.35) | **81.48** (+0.00) |

#### Results Table (GPT-4-0613)

| Method          | ReClor            | LogiQA        | RuleTaker         | ProofWriter       | FOLIO             |
| --------------- | ----------------- | ------------- | ----------------- | ----------------- | ----------------- |
| Direct          | 72.17             | 59.22         | 64.30             | 63.74             | 82.96             |
| LoT             | 77.98 (+5.81)     | 60.11 (+0.89) | 64.65 (+0.35)     | 65.58 (+1.84)     | 83.55 (+0.59)     |
| CoT             | 77.39             | 58.97         | 68.69             | 69.83             | 85.33             |
| LoT + CoT       | 79.13 (+1.74)     | 58.40 (-0.57) | 69.02 (+0.33)     | 70.56 (+0.73)     | 85.48 (+0.15)     |
| SC(5)           | 73.91             | 59.98         | 64.32             | 64.16             | 82.96             |
| LoT + SC(5)     | 80.43 (+6.52)     | 60.75 (+0.77) | 64.53 (+0.21)     | 65.99 (+1.83)     | 82.96 (+0.00)     |
| CoT-SC(5)       | 80.43             | **61.67**     | 69.49             | 70.56             | 86.67             |
| LoT + CoT-SC(5) | **82.61** (+2.18) | 60.29 (-1.38) | **70.73** (+1.24) | **71.98** (+1.42) | **88.15** (+1.48) |

### Comparison with Neuro-symbolic Methods

**LoT vs SatLM (ReClor dataset):**

- LoT significantly outperforms SatLM in terms of accuracy on the Reclor dataset
- LoT obtains notable improvements across various prompting methods: Direct (+1.74%), CoT (+2.18%), and SC (+6.52%)

**LoT vs LINC (FOLIO dataset):**

| Method | GPT-3.5-turbo-0125 | GPT-4-0613 |
| ------ | ------------------ | ---------- |
| Direct | 68.89              | 82.96      |
| LINC   | 45.19              | 55.56      |
| LoT    | **76.00**          | **83.55**  |

SatLM and LINC exhibit poor performance compared to Direct prompting. This aligns with the motivation that these neuro-symbolic methods are more likely to encounter the issue of information loss when extracting logical symbolic expressions, compromising their overall performance.

**Case Study:**
SatLM induces information mistakes and loss during logical extraction. For example, SatLM erroneously employs "abilities" to represent "can", leading to semantic errors in constraints. Additionally, SatLM confuses "has a sense of self" with "has a sense of the minds of others" and only utilizes "possesses" to represent them together.

In contrast to SatLM, LoT successfully extracts logical proposition descriptions and symbolizes them. An interesting finding: when directly examining the extracted logical expressions, a small mistake in A -> B results in an incorrect A -> C. However, when translating the deduced logical expressions into natural language, LLMs recognize the subordinate relationship and correct this error, resulting in correct augmentation to prompts. This reflects that LoT fully leverages the LLM's understanding of natural language descriptions, enabling it to correct errors from earlier phases.

### In-depth Analysis of ToT with LoT

Under the complex reasoning scenario with deduction depth of 5 in the ProofWriter dataset:

- Direct achieves performance similar to random guessing (50%)
- ToT accuracy is +19% higher than Direct, reaching 70%
- **LoT+ToT reaches +8% increase in accuracy compared to ToT (78%)**

Analysis of indices within ToT:

| Method  | Total States (TS)  | Successful States (SS) | Full Reasoning (FR %) |
| ------- | ------------------ | ---------------------- | --------------------- |
| ToT     | 18.70              | 7.70                   | 90                    |
| LoT+ToT | **19.10** (+2.14%) | **8.09** (+5.06%)      | **92** (+2%)          |

- LoT facilitates an expanded exploration scope for ToT (+2.14% increase in overall states)
- LoT improves the full reasoning of ToT by +2%
- LoT+ToT exhibits a +5.06% increase in successful states, indicating LoT can significantly enhance the effectiveness of ToT's explored states

### Ablation Study

**Impact of logical reasoning laws (FOLIO dataset with GPT-4-0613):**

| Method                            | FOLIO     |
| --------------------------------- | --------- |
| LoT                               | **76.00** |
| w/o Contraposition Law            | 72.22     |
| w/o Half of Generated Description | 72.96     |

Either variant reduces additional logical information generated by LoT, ultimately leading to a decrease in accuracy. This underscores the effectiveness of the logical information deduced by LoT.

**Impact of Logic Extension phase (LogiQA and RuleTaker with GPT-3.5-turbo-0125):**

| Method            | LogiQA    | RuleTaker |
| ----------------- | --------- | --------- |
| Direct            | 36.44     | 51.89     |
| LoT               | **36.85** | **59.44** |
| LoT w/o Extension | 36.79     | 59.05     |

Removing the Logic Extension leads to a drop in LoT's accuracy, though it still outperforms the Direct approach. This highlights:

1. The necessity of first extracting and analyzing logical relationships before allowing the LLM to directly address the problem
2. The effectiveness of leveraging logical reasoning laws to extend the extracted logical expressions and enhance the injected logical information

## 5. Related Work

### Prompting Methods for LLMs Reasoning

Numerous studies are dedicated to exploring enhancements in LLMs reasoning through prompting methods. CoT, which breaks down a multi-step reasoning problem into multiple intermediate steps to gradually generate answers, has significantly improved logical reasoning, mathematical logic, and interpretability.

CoT-SC further generates multiple thought chains, and the final answer is obtained through majority voting. Least-To-Most deconstructs a problem into multiple sub-questions, addressing them step by step, with the answer to the previous sub-question serving as the input for the next. Similar decomposition methods of sub-problems include Lambada and Divide-and-Conquer. Some work employs a process-supervised method, providing feedback on the intermediate reasoning process to enhance logical reasoning capabilities. Various strategies are used to select optimal candidates from multiple chains of thought. ToT and GoT achieve logical branching and the aggregation of multiple thoughts by utilizing more complex reasoning topology.

However, these prompting methods occasionally exhibit unfaithful reasoning and lack in-depth exploration of logical information in logical reasoning tasks.

### Neuro-symbolic Methods

The neuro-symbolic methods, which combine LLMs with symbolic reasoning, are considered an effective approach to address the issue of unfaithful reasoning and enhance the logical reasoning ability of LLMs.

- **LReasoner**: proposes a framework for context extension that expands the logical information contained in the context by applying logical reasoning laws
- **Logic-LM**: initially utilizes LLMs to transform natural language problems into symbolic formulas, then uses a symbolic solver to reason about the formalized problems with a self-refinement module
- **SatLM**: utilizes LLMs to generate declarative task specifications rather than imperative programs, and leverages automated theorem solver to derive final answers
- **LINC**: considers LLMs as a semantic parser, translating premises and conclusions from natural language into first-order logic expressions, which are then offloaded to an external theorem solver

However, these neuro-symbolic methods rely entirely on symbolic solvers, which inherently leads to information loss in extracting logical expressions and limits their accuracy.

## 6. Conclusion

In this paper, we introduce a zero-shot prompting approach Logic-of-Thought (LoT), designed to address the challenge of information loss inherent in existing neuro-symbolic methods. LoT leverages propositional logic to derive expanded logical information from input context, which serves as a supplementary augmentation to the original prompts, and can enhance logical reasoning capabilities of LLMs. LoT exhibits compatibility with widely used prompting techniques. In the experiments, we demonstrate that LoT significantly boosts the performance of various existing prompting methods across multiple logical reasoning datasets and can be seamlessly integrated with them.

## 7. Limitations

Although our proposed LoT has achieved excellent performance in various logical reasoning tasks, there are still some limitations:

1. **Limited connectives and logical reasoning laws**: Current LoT supports a limited set of connectives and logical reasoning laws. More connectives and logical reasoning laws in LoT means more complex prompt design in the Logic Extraction and Logic Translation phase, and increased difficulty in logical deducing in the Logic Extension phase. In the future, additional connectives and logical reasoning laws could be included to further enhance the logical reasoning capabilities.

2. **Hallucination issues**: Although LoT preserves original question structures and utilizes extra deduced logical information as additional augmentation to mitigate information loss issue, hallucination issues inherent in LLMs can still lead to some failure in the Logic Extraction phase, such as repetition of expressions, omission of logical relationships, and deviations in logical propositions and expressions.

## Appendix

### A. Comparative Study of States in ToT and LoT+ToT

Analysis of an illustrative example comparing the exploration of states when utilizing ToT and LoT+ToT shows that in LoT+ToT, LoT generates the logical description "If things are rough, then things are round", from which ToT further generates 4 successful states. The corresponding premises are:

1. "If Charlie is round, then Charlie is young and nice"
2. "Charlie is not young"
3. "If Charlie is quiet and round, then Charlie is young"
4. "If Charlie is round and rough, then Charlie is white"

Subsequently, the generated information by the LoT and ToT serves as an enhancement to the input prompt, enabling LLMs to produce correct results. Compared to using ToT alone, the logical description generated by LoT enables ToT to generate an additional four successful states, which leads to the correct results. This indicates that LoT enhances the total number of states as well as the number of successful states, thereby expanding the reasoning space and improving the accuracy of ToT reasoning.

### B. An Error Case of LoT

When LoT selects sentences with logical relationships, there can be biases in the information extracted by LLMs. Sentences like "Today is Easter, but Cindy's hair is still braided", "Cindy's hair is braided, which means it must be a special occasion", and "If it's a holiday, Cindy will most likely have her hair braided" can all exhibit inaccuracies. Subsequently, extracted logical expressions exhibit errors. These accumulated errors result in erroneous generated logical descriptions and incorrect final outcomes.

### C. An Example of Overlap Capabilities between CoT and LoT

The following example illustrates the overlap in capabilities between CoT and LoT:

**Context:**

1. Books contain tons of knowledge.
2. When a person reads a book, that person gains knowledge.
3. If a person gains knowledge, they become smarter.
4. Harry read the book "Walden" by Henry Thoreau.

**Question:** Whether this inference is correct: Harry is smarter than before.

**LoT approach:**

- Logic Extraction:
  - Sentences 2 and 3 contain logical relationships
  - A: a person reads a book, B: person gains knowledge, C: become smarter
  - A -> B, B -> C
- Logic Extension: A -> C
- Logic Translation: "If a person reads a book, that person become smarter."
- Extended context adds this as sentence 5
- LLM Answer: Correct

**CoT approach:**

- "Let's think step by step: Given that Harry read the book 'Walden' by Henry Thoreau, it can be concluded that he gained knowledge from reading the book. Therefore, based on the context provided, it is reasonable to conclude that Harry is smarter than before."
- LLM Answer: Correct

Both CoT and LoT handle this problem by linking conditional statements and reasoning step by step, indicating that CoT and LoT sometimes have overlapping capabilities.

### D. In-depth Analysis of LoT

LoT comprises three phases: Logical Extraction, Logical Expansion, and Logical Translation. Statistical comparison of experimental outcomes of Direct and LoT using GPT-3.5-turbo-0125 on the FOLIO dataset:

- 40% of samples encountered errors during the logical extraction phase
- No errors were recorded during logical expansion
- 5.18% of samples experienced errors in the logical translation stage
- Overall, 42.22% of samples exhibited at least one error across the three steps

**Impact of Logical Extraction phase:**

| Direct -> LoT         | Right Extraction (%) | Wrong Extraction (%) | Sum (%) |
| --------------------- | -------------------- | -------------------- | ------- |
| Answer Right -> Wrong | 5.19                 | 6.67                 | 11.85   |
| Answer Wrong -> Right | 8.15                 | 10.37                | 18.52   |
| Answer Right -> Right | 38.51                | 19.26                | 57.78   |
| Answer Wrong -> Wrong | 8.15                 | 3.70                 | 11.85   |
| SUM                   | 60.00                | 40.00                | 100.00  |

**Impact of Logical Translation phase:**

| Direct -> LoT         | Right Translation (%) | Wrong Translation (%) | Sum (%) |
| --------------------- | --------------------- | --------------------- | ------- |
| Answer Right -> Wrong | 11.11                 | 0.74                  | 11.85   |
| Answer Wrong -> Right | 16.30                 | 2.22                  | 18.52   |
| Answer Right -> Right | 56.30                 | 1.48                  | 57.78   |
| Answer Wrong -> Wrong | 11.11                 | 0.74                  | 11.85   |
| Sum                   | 94.82                 | 5.18                  | 100.00  |

### E. Full Set of Prompts

#### Logic Extraction Prompt (ReClor and LogiQA)

```
Please use uppercase English letters such as A, B, C, etc. to identify all possible propositions. Do not include negative tones such as "not" in the propositions. For example, if the sentence is "It is not bored," you should use "A: bored" to represent it.

Next, for each proposition, use the symbol to represent its negative form. For example, the negative form of proposition A can be expressed as A.

Now, please carefully analyze the context and find causal relationship between propositions seriously. A causal expression is only established when the context directly supports this relationship. Use arrows (->) to indicate causal relationships, for example, "If A, then B", "B if A" and "A causes B" etc. can be represented as A->B.

Finally, output propositions and causal expressions.
```

#### Logic Extraction Prompt (RuleTaker, ProofWriter and FOLIO)

```
Please use uppercase English letters such as A, B, C, etc. to identify all possible propositions. Do not include negative tones such as "not" in the propositions. For example, if the sentence is "It is not bored," you should use "A: bored" to represent it.

Next, for each proposition, use the symbol to represent its negative form. For example, the negative form of proposition A can be expressed as NOT A.

Now, please carefully analyze the context and find causal relationship between propositions. A causal expression is only established when the context directly supports this relationship. Use arrows (->) to indicate causal relationships, for example, "If A, then B", "B if A" and "A causes B" etc. can be represented as A->B.

Finally, output propositions and causal expressions.
```

#### Logic Translation Prompt (All Datasets)

```
Please use the provided propositions to translate each expression into a complete sentence.

NOT A represents the negation of proposition A, the arrow (->) represents the causal relationship, and A->B represents if A, then B.

Only output the sentences in a paragraph!
```

## References

- Achiam et al. (2023). GPT-4 technical report. arXiv:2303.08774
- Anil et al. (2023). PaLM 2 technical report. arXiv:2305.10403
- Arkoudas (2023). GPT-4 Can't Reason. arXiv:2308.03762
- Bao et al. (2024). LLMs with Chain-of-Thought Are Non-Causal Reasoners. arXiv:2402.16048
- Besta et al. (2024). Graph of thoughts: Solving elaborate problems with large language models. AAAI
- Clark et al. (2021). Transformers as soft reasoners over language. IJCAI
- Han et al. (2022). FOLIO: Natural language reasoning with first-order logic. arXiv:2209.00840
- Kazemi et al. (2022). Lambada: Backward chaining for automated reasoning in natural language. arXiv:2212.13894
- Kojima et al. (2022). Large language models are zero-shot reasoners. NeurIPS
- Lanham et al. (2023). Measuring faithfulness in chain-of-thought reasoning. arXiv:2307.13702
- Lightman et al. (2023). Let's Verify Step by Step. arXiv:2305.20050
- Liu et al. (2020). LogiQA: A challenge dataset for machine reading comprehension with logical reasoning. arXiv:2007.08124
- Liu et al. (2023). Evaluating the logical reasoning ability of ChatGPT and GPT-4. arXiv:2304.03439
- Lyu et al. (2023). Faithful chain-of-thought reasoning. arXiv:2301.13379
- Nye et al. (2021). Show your work: Scratchpads for intermediate computation with language models. arXiv:2112.00114
- Olausson et al. (2023). LINC: A neurosymbolic approach for logical reasoning. arXiv:2310.15164
- Pan et al. (2023). Logic-LM: Empowering Large Language Models with Symbolic Solvers. EMNLP
- Tafjord et al. (2021). ProofWriter: Generating Implications, Proofs, and Abductive Statements. ACL Findings
- Touvron et al. (2023). Llama 2: Open foundation and fine-tuned chat models. arXiv:2307.09288
- Turpin et al. (2024). Language models don't always say what they think: unfaithful explanations in chain-of-thought prompting. NeurIPS
- Wang et al. (2022). Self-Consistency Improves Chain of Thought Reasoning in Language Models. ICLR
- Wang et al. (2022). Logic-Driven Context Extension and Data Augmentation for Logical Reasoning of Text. ACL Findings
- Wei et al. (2022). Chain-of-thought prompting elicits reasoning in large language models. NeurIPS
- Yao et al. (2024). Tree of thoughts: Deliberate problem solving with large language models. NeurIPS
- Ye et al. (2024). SatLM: Satisfiability-aided language models using declarative prompting. NeurIPS
- Yu et al. (2020). ReClor: A reading comprehension dataset requiring logical reasoning. arXiv:2002.04326
- Zelikman et al. (2022). STaR: Bootstrapping reasoning with reasoning. NeurIPS
- Zhang et al. (2024). Cumulative Reasoning with Large Language Models. arXiv:2308.04371
- Zhang et al. (2024). Guiding Large Language Models with Divide-and-Conquer Program. arXiv:2402.05359
- Zhou et al. (2022). Least-to-most prompting enables complex reasoning in large language models. arXiv:2205.10625
