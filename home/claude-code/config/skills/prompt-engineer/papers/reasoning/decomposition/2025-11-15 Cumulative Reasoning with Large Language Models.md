# Abstract

Recent advancements in large language models (LLMs) have shown remarkable progress, yet their ability to solve complex problems remains limited. In this work, we introduce Cumulative Reasoning (CR), a structured framework that enhances LLM problem-solving by emulating human-like iterative and cumulative thought processes. CR orchestrates LLMs in three distinct roles: Proposer, Verifier(s), and Reporter, to systematically decompose tasks, generate and validate intermediate reasoning steps, and compose them into a solution by building a dynamic Directed Acyclic Graph (DAG) of verified propositions. This approach substantially enhances problem-solving capabilities. We demonstrate CR's advantage through several complex reasoning tasks: it outperforms existing methods in logical inference tasks with up to a 9.3% improvement, achieving 98.04% accuracy on the curated FOLIO wiki dataset. In the Game of 24, it achieves 98% accuracy, marking a 24% improvement over previous methods. In solving MATH problems, CR achieves a 4.2% increase from previous methods and a 43% relative improvement in the most challenging level 5 problems. When incorporating a code environment with CR, we further harness LLMs' reasoning capabilities and outperform the Program of Thought (PoT) method by 38.8%.

Project Page: https://github.com/iiis-ai/cumulative-reasoning

# Introduction

Large language models (LLMs) have exhibited remarkable progress across a wide range of applications [devlin2018bert; radford2018improving; radford2019language; brown2020language; raffel2020exploring; OpenAI2023GPT4TR]. Despite these advancements, LLMs continue to encounter significant challenges when tasked with solving problems that require intricate, multi-step reasoning and robust logical inference. For example, empirical studies have shown that LLMs often struggle to generate correct solutions for high school mathematics problems [lightman2023let], highlighting a persistent gap between intuitive language generation and rigorous problem-solving.

Inspired by Kahneman's dual-process theory [kahneman2011thinking], which distinguishes between rapid, intuitive processing (System 1) and slower, deliberative reasoning (System 2), it becomes evident that current LLMs primarily operate in a System 1 mode. This limitation restricts their capacity to engage in the systematic, stepwise reasoning necessary for complex tasks.

Recent developments such as Chain-of-Thought (CoT) prompting [wei2022chain] and Tree-of-Thought (ToT) methodologies [yao2023tree; long2023large] have made significant strides by guiding LLMs through sequential and hierarchical reasoning processes. However, these approaches often lack robust mechanisms for dynamically storing, verifying, and cumulatively leveraging all validated intermediate results in a flexible manner, a critical aspect of human cognition that enables error-checking, iterative refinement, and the construction of complex arguments.

In this work, we introduce Cumulative Reasoning (CR), a reasoning method that characterizes a more holistic representation of the thinking process. CR orchestrates a symphony of three LLM roles: the proposer, verifier(s), and reporter, to iteratively propose, validate, and compile reasoning steps into a comprehensive solution. This decomposition and composition strategy effectively transforms complex, multifaceted problems into a series of manageable tasks, substantially enhancing the problem-solving capabilities of LLMs. CR's contributions include its structured, synergistic orchestration of these roles and its dynamic construction and utilization of a Directed Acyclic Graph (DAG) of validated reasoning steps. This cumulative DAG allows CR to build upon a growing, verified knowledge base specific to the problem instance, facilitating more flexible, robust, and complex reasoning pathways. Our evaluation spans three distinct areas:

1.  Logical inference tasks: our method demonstrates superior performance on datasets like FOLIO wiki and AutoTNLI, with improvements of up to 9.3% and an outstanding 98.04% accuracy on a curated version of the FOLIO dataset.

2.  The Game of 24: we achieved 98% accuracy, marking a 24% improvement over the existing state-of-the-art method ToT [yao2023tree] while using only about 25% visited states.

3.  Solving MATH problems: our method establishes new benchmarks with a margin of 4.2% over previous methods [fu2022complexity; zheng2023progressive] without external tools. Noteworthy, our method achieves notable 43% relative improvements on the hardest level 5 problems (22.4% -> 32.1%). Moreover, by integrating CR with a Python code environment---absent external aids like retrieval systems, we achieve a 72.2% accuracy on the MATH dataset, outperforming previous methods such as PoT [chen2022program] and PAL [gao2023pal] with 38.8% relative improvement and demonstrating the adaptability and robustness of CR across various complex tasks.

# Background

In this section, we review the formal foundations of logic that underpin our approach and present an illustrative example adapted from the FOLIO dataset [han2022folio].

## Logic

Propositional logic is the most basic formal system in logic. It is built from atomic propositions (e.g., `latex $p$ `, `latex $q$ `, `latex $r$ `) and logical connectives such as conjunction (`latex $\wedge$ `), disjunction (`latex $\vee$ `), implication (`latex $\Rightarrow$ `), and negation (`latex $\neg$ `). In this setting, the truth values are denoted by the constants `latex $1$ ` (true) and `latex $0$ ` (false). Fundamental laws of propositional logic include:

```latex
$$x \wedge x = x,\quad x \vee x = x,\quad 1 \wedge x = x,\quad 0 \vee x = x,$$
```

along with the absorption law:

```latex
$$x \wedge (y \vee x) = x = (x \wedge y) \vee x,$$
```

and the distributive laws:

```latex
$$x \wedge (y \vee z) = (x \wedge y) \vee (x \wedge z),\quad x \vee (y \wedge z) = (x \vee y) \wedge (x \vee z).$$
```

In any Boolean algebra, every element `latex $x$ ` has a complement `latex $\neg x$ `, which satisfies:

```latex
$$x \wedge \neg x = 0,\quad x \vee \neg x = 1,\quad \neg\neg x = x.$$
```

Extending this framework, _first-order logic (FOL)_ introduces quantifiers to reason about collections of objects. Universal quantification (`latex $\forall$ `) and existential quantification (`latex $\exists$ `) allow statements such as

```latex
$$\forall x\, \bigl(\text{Dog}(x) \Rightarrow \text{Animal}(x)\bigr),$$
```

which reads as "for every `latex $x$ `, if `latex $x$ ` is a dog, then `latex $x$ ` is an animal." In contrast, _higher-order logic (HOL)_ permits quantification over functions and predicates, greatly increasing expressiveness. For a detailed treatment of HOL, please refer to Appendix 9.1.

## Illustrative Example

To illustrate these concepts, consider an example adapted from the FOLIO dataset, where only natural language statements (without explicit logical formulas) are provided as context.

[IMAGE: wrapfigure r0.55]

The premises are as follows:

1.  All monkeys are mammals: `latex $\forall x\, (\text{Monkey}(x) \Rightarrow \text{Mammal}(x)).$ `

2.  Every animal is either a monkey or a bird: `latex $\forall x\, (\text{Animal}(x) \Rightarrow (\text{Monkey}(x) \vee \text{Bird}(x))).$ `

3.  All birds can fly: `latex $\forall x\, (\text{Bird}(x) \Rightarrow \text{Fly}(x)).$ `

4.  Anything that can fly has wings: `latex $\forall x\, (\text{Fly}(x) \Rightarrow \text{Wings}(x)).$ `

5.  Rock is not a mammal but is an animal: `latex $\neg \text{Mammal}(\text{Rock}) \land \text{Animal}(\text{Rock}).$ `

The question is: _Does Rock have wings?_

A rigorous derivation proceeds as follows:

1.  The contrapositive of (1) gives:

```latex
$$\forall x\, (\neg \text{Mammal}(x) \Rightarrow \neg \text{Monkey}(x)).$$
```

2.  Combining (a) with (5) implies that Rock is not a monkey while still being an animal.

3.  Premise (2) then entails that Rock must be either a monkey or a bird.

4.  Since Rock is not a monkey (by step (b)), it follows that Rock is a bird.

5.  From (3) and the conclusion that Rock is a bird, we deduce that Rock can fly.

6.  Finally, applying (4) to the fact that Rock can fly, we conclude that Rock has wings.

Although the derivation appears as a linear sequence of steps from (a) to (f), its underlying structure is more naturally modeled as a directed acyclic graph (DAG), where each edge represents an individual inference. This DAG structure better captures the cumulative and interdependent nature of the reasoning process.

# Cumulative Reasoning

In this section, we introduce our method, Cumulative Reasoning (CR), a structured framework that leverages a collaborative process among specialized Large Language Models (LLMs) to address complex problem-solving tasks. Unlike conventional methods that generate a linear chain of thought, CR decomposes a problem into manageable sub-tasks and incrementally builds a solution by cumulatively accumulating and verifying intermediate reasoning steps.

This approach is inspired by human cognitive processes that involve iterative refinement and building upon established knowledge, as well as principles from intuitionistic logic and mathematical constructivism which emphasize the constructive nature of proofs built from validated steps [troelstra1973metamathematical]. CR aims to operationalizes these principles for LLM-based reasoning.

CR orchestrates three distinct roles:

1.  **Proposer:** Generates candidate reasoning steps based on the current context, thereby initiating each cycle of reasoning.

2.  **Verifier(s):** Critically assess and validate the proposer's suggestions. The Verifier's conceptual role is to ensure logical soundness. In practice, this can be implemented by another LLM instance (acting as a self-critique mechanism) or, ideally, by more formal methods such as symbolic reasoning systems (e.g., a theorem prover) or an integrated code environment (e.g., a Python interpreter for mathematical or arithmetical validation). Only verified steps are added to the DAG.

3.  **Reporter:** Monitors the evolving state of accumulated reasoning and determines the optimal moment to conclude the process, outputting the definitive solution once sufficient validated information has been gathered.

[IMAGE: Figure 1 - Overview of the Cumulative Reasoning (CR) process applied to a problem with three premises. The diagram illustrates a potential path; in general, new propositions (nodes in the DAG) can be derived by conditioning on any combination of previously validated propositions. The Reporter synthesizes the final answer from the constructed DAG.]

As the figure illustrates, CR iteratively refines a solution by progressively integrating validated propositions into the reasoning DAG. While all roles can be instantiated by the same underlying LLM distinguished by role-specific prompts (see Appendix 12 for detailed examples of prompts and role interactions), the Verifier can also be an external tool. This division of labor aims to overcome limitations of monolithic LLM outputs, where generation and verification are conflated. The specific contribution of each role is crucial: the Proposer explores, the Verifier ensures reliability, and the Reporter synthesizes, all operating on the shared, growing DAG of verified knowledge.

The constructive approach of CR, by building a solution from verified steps, dynamically adjusts the reasoning trajectory. This iterative accumulation and validation of knowledge within the DAG mirrors the nuanced nature of human problem-solving and enhances the robustness of LLMs in complex tasks.

## Comparison with CoT and ToT

While CR shares the goal of improving multi-step reasoning with Chain-of-Thought (CoT) [wei2022chain] and Tree-of-Thought (ToT) [yao2023tree; long2023large] methodologies, its mechanism is distinct. Figure 5 offers a conceptual comparison.

CoT generates a linear sequence of reasoning steps. This approach can be prone to error propagation, as an incorrect intermediate step can derail the entire subsequent chain. It also lacks an explicit mechanism for exploring alternative paths or systematically verifying intermediate conclusions.

ToT extends CoT by exploring multiple reasoning paths in a tree structure, allowing for backtracking and heuristics to guide the search (e.g., breadth-first or depth-first search up to certain limits). While ToT introduces verification or voting at different steps, it typically explores distinct branches which might be pruned, and may not explicitly accumulate all verified knowledge from diverse branches into a single, reusable structure for subsequent reasoning.

CR, in contrast, dynamically constructs a Directed Acyclic Graph (DAG) of all historically validated reasoning steps. This DAG structure allows CR to (i) leverage a more comprehensive and interconnected context of verified information, as new propositions can be derived from any combination of existing validated nodes, not just a linear predecessor or a limited set of ancestors in a tree; (ii) systematically integrate verified knowledge, reducing redundancy and preventing re-exploration of invalid paths due to the Verifier's role. This cumulative and validated knowledge base addresses common issues like error propagation in CoT and potentially fragmented knowledge exploration in ToT.

The explicit Proposer-Verifier-Reporter roles in CR further contribute to a more robust process. This structured decomposition allows for specialized handling of generation, validation, and synthesis, which we hypothesize is more effective than a single model attempting all simultaneously. While conditioning on an increasing number of validated nodes in the DAG can increase contextual complexity, it also provides a richer foundation for subsequent reasoning steps, a trade-off that CR manages through its iterative process.

Other related frameworks like Graph-of-Thought (GoT) [besta2024graph] also explore graph-based reasoning structures. CR offers a specific instantiation where its defined roles iteratively build a Directed Acyclic Graph (DAG). This DAG is crucial: its inherently acyclic structure, combined with CR's focus on cumulative validation at each step, prevents logical loops and ensures consistent forward progression in the deductive process, thereby avoiding reasoning dead ends. We delve deeper into comparisons with other advanced reasoning frameworks in Section 5.

[IMAGE: Figure 5 - Conceptual comparison between CoT-SC (Self-Consistency on multiple CoT chains), ToT (Tree of Thoughts exploring multiple paths), and CR (Cumulative Reasoning building a DAG of verified steps). CoT-SC generates multiple independent chains and selects the best. ToT explores a tree, potentially pruning branches. CR iteratively builds a DAG, accumulating all verified intermediate steps (green nodes) and using them as context for subsequent reasoning, while invalid steps (red nodes) are discarded by the Verifier.]

#### Detailed Comparison of CoT, ToT, and CR.

To elucidate the advantages of CR over alternative methods, consider a simplified two-stage reasoning process (which can naturally be extended to multiple stages). For clarity, we assume that whenever a verifier is employed, its accuracy is near-perfect, a condition that can be achieved using symbolic verifier environments (e.g., a Python code interpreter or Lean). We further assume that a unique correct reasoning path exists for the problem. Under these conditions, we define the _arrival probability_ as follows. It's important to note that these assumptions, are simplifications for this theoretical illustration and may not hold in all practical scenarios.

**Definition:** For a given algorithm, the _arrival probability_ is defined as the probability of reaching the correct conclusion from the initial state. Let `latex $P_{\text{CoT}}$ ` denote the arrival probability for CoT, and `latex $P_{\text{CoT-SC}}$ ` that for multiple independent CoT trials (self-consistency). Similarly, denote the arrival probability of ToT as

```latex
$$P_{\text{ToT}} = p_{1_{\text{ToT}}} \, p_{2_{\text{ToT}}},$$
```

and that of CR as

```latex
$$P_{\text{CR}} = p_{1_{\text{CR}}} \, p_{2_{\text{CR}}},$$
```

where `latex $p_{1}$ ` represents the probability of obtaining the first reasoning step correctly and `latex $p_{2}$ ` represents the probability of obtaining the second step correctly, conditioned on the first step being correct.

Since both ToT and CR incorporate verifiers that immediately discard erroneous paths (see Figure 5), it follows that

```latex
$$P_{\text{CoT}} \leq p_{1_{\text{ToT}}} \, p_{2_{\text{ToT}}},$$
```

because CoT, without intermediate verification, is more likely to proceed along an invalid branch.

Note that denoting the arrival probabilities for CR simply as `latex $p_{1_{\text{CR}}}$ ` or `latex $p_{2_{\text{CR}}}$ ` is imprecise since CR maintains a history of visited (and validated) states within its DAG. Instead, we write `latex $p_{1_{\text{CR}}|(\mathcal{H})}$ ` and `latex $p_{2_{\text{CR}}|(\mathcal{H}')}$ ` to indicate the probability conditioned on the accumulated history of validated states `latex $\mathcal{H}$ ` (premises for the first step, premises and validated stage-1 nodes for the second). We make the following assumption, motivated by the intuition that a richer set of verified, relevant information should improve the likelihood of deriving the next correct step, an idea supported by findings in related self-correction and refinement literature [madaan2023self; shinn2023reflexion]:

**Assumption:** Given the near-perfect verifier, it holds that for generating a correct step:

```latex
$$p_{1_{\text{ToT}}} \leq p_{1_{\text{CR}}|(\cdot)}, \quad p_{2_{\text{ToT}}} \leq p_{2_{\text{CR}}|(\cdot)},$$
```

and the conditioned probabilities monotonically increase as additional nodes are incorporated:

```latex
$$p_{1_{\text{ToT}}} \leq p_{1_{\text{CR}}|(\text{premises})} \leq p_{2_{\text{CR}}|(\text{premises}, \text{stage-1 node}_1)} \leq p_{2_{\text{CR}}|(\text{premises}, \text{stage-1 node}_1, \ldots, \text{node}_n)},$$
```

```latex
$$p_{2_{\text{ToT}}} \leq p_{2_{\text{CR}}|(\text{premises}, \text{stage-1 nodes})} \leq \cdots \leq p_{2_{\text{CR}}|(\text{premises}, \text{stage-1 nodes}, \text{stage-2 nodes})}.$$
```

This assumption posits that CR, by conditioning on a potentially larger set of verified intermediate results from its DAG, is at least as likely, and potentially more likely, to generate the next correct step compared to ToT (which might condition on a more limited history from a single path in its tree). The monotonicity suggests that adding more correct, verified knowledge does not harm the probability of the next step. While LLM behavior can be unpredictable and refinements are not always monotonically beneficial due to issues like hallucination, the presence of a strong verifier in this idealized model helps mitigate such effects for this analysis.

The following lemma will be useful for subsequent comparisons.

**Lemma 1:** For any positive integer `latex $n$ ` and any probabilities `latex $p_1, p_2 \in [0,1]$ `, the following inequality holds:

```latex
$$1 - \bigl(1 - p_1 \cdot p_2\bigr)^n \leq \Bigl[1 - \bigl(1 - p_1\bigr)^n\Bigr] \cdot \Bigl[1 - \bigl(1 - p_2\bigr)^n\Bigr].$$
```

Please refer to Appendix 7 for the proof.

**Theorem 1:** Assume that CoT-SC is executed with `latex $n$ ` independent trials, while both ToT and CR explore with a maximum breadth of `latex $n$ `. Under the above Assumption, the following inequality holds:

```latex
$$P_{\text{CoT-SC}} \leq P_{\text{ToT}} \leq P_{\text{CR}}.$$
```

To further illustrate the advantages of CR, we conducted a conceptual experiment on the Game of 24. In this experiment, the solution process is divided into two stages. The first stage involves randomly selecting two numbers from the four given inputs to produce a new number, and the second stage employs the remaining three numbers to form an expression that evaluates to 24. We denote the success rates of the first and second stages as `latex $p_1$ ` and `latex $p_2$ `, respectively, and let `latex $p$ ` represent the success rate when solving the Game of 24 directly with the four numbers. The results, summarized in Table 1, indicate that decomposing the problem into sequential steps with intermediate verification significantly improves the overall accuracy.

**Table 1: Conceptual experiment results on the Game of 24.** The puzzles selected have unique solution paths to facilitate evaluation. Each case was repeated 1000 times.

| Puzzle        | p (%) | p1 (%) | p2 (%) | p1\*p2 (%) |
| ------------- | ----- | ------ | ------ | ---------- |
| 2, 7, 12, 13  | 3.0   | 62.3   | 8.0    | 5.0 (+2.0) |
| 6, 11, 12, 13 | 0.0   | 64.8   | 8.0    | 5.2 (+5.2) |
| 8, 8, 10, 12  | 1.8   | 6.9    | 63.9   | 4.4 (+2.6) |

CR's strategy of decomposing problems, meticulously verifying intermediate reasoning steps, and dynamically accumulating validated propositions within a DAG structure offers several advantages. It provides a more robust framework than linear CoT by incorporating verification. Compared to tree-based methods like ToT, CR's cumulative use of all validated knowledge offers a richer contextual basis for subsequent reasoning. These structural and procedural distinctions, grounded in its Proposer-Verifier-Reporter architecture, contribute to CR's strong performance, as suggested by both this illustrative theoretical comparison and the empirical results presented in Section 4. The key insight is that the structured accumulation and reuse of verified knowledge within a flexible DAG enhances complex reasoning.

# Experiments

Our experiments are conducted using the Microsoft Guidance library [guidance], which seamlessly integrates generation, prompting, and logical control within language model frameworks. We evaluate our method using the following LLMs: GPT-3.5-turbo, GPT-4, LLaMA-13B, and LLaMA-65B. In our implementation of Cumulative Reasoning (CR), the roles of Proposer, Verifier(s), and Reporter are instantiated using the same underlying LLM but distinguished by role-specific few-shot prompts. This design both broadens the applicability of our approach and simplifies its deployment. Throughout the experiments, we denote by `latex $n$ ` the number of intermediate propositions generated and by `latex $k$ ` the number of majority voting iterations. For decoding, we set the temperature to `latex $t=0.1$ ` by default and `latex $t=0.7$ ` for majority voting. Note that GPT-3.5-turbo and GPT-4 are accessed via OpenAI's chat-format APIs.

## FOLIO Wiki

The FOLIO dataset [han2022folio] is a collection of first-order logical inference problems expressed in natural language. Each problem is labeled as "True", "False", or "Unknown." Figure 6 in Appendix 10 presents an example problem along with solutions generated by both a Chain-of-Thought (CoT) approach and our CR method.

We observe that while the CoT reasoning process may generate useful intermediate steps, it often loses trajectory and fails to reach the correct conclusion. By contrast, CR initially produces two valuable propositions and subsequently leverages them to solve the problem accurately.

The FOLIO dataset is a composite of 1435 examples, of which 52.5% of these instances have been crafted based on knowledge from randomly selected Wikipedia pages. This approach guarantees the infusion of abundant linguistic variations and a rich vocabulary within the corpus. The residual 47.5% of the examples have been constructed in a hybrid style, based on various complex logical templates. Acknowledging that contemporary LLMs are pre-trained on a considerable volume of human-written corpus, we direct our experiments towards those examples derived from Wikipedia, hereby referred to as FOLIO-wiki. Once a handful of examples are moved aside for few-shot prompts and those examples without source labels for validations are excluded, we are left with a testable collection of 534 examples.

Table 2 reports the performance of different methods evaluated on the FOLIO-wiki dataset. The results demonstrate that CR consistently outperforms Direct prompting, CoT, and CoT with Self-Consistency (CoT-SC), with improvements of up to 8.62%. Notably, when paired with GPT-4, CR achieves an accuracy of 87.45%, compared to 85.02% for GPT-4 with CoT-SC.

## FOLIO Wiki Curated

A detailed review of the FOLIO-wiki dataset revealed several problematic instances, including: 1) Missing or contradictory common knowledge; 2) Overly ambiguous problems that do not yield unequivocal answers; 3) Inherent inconsistencies within the premises; 4) Vague statements or typographical errors; 5) Incorrect answer annotations.

After removing 74 such problematic instances, the curated set comprises 460 examples (see Appendix 11.2 for detailed examples). As shown in Table 3, when applied to this refined dataset, GPT-4 paired with CR achieves an accuracy of 98.04% (error rate: 1.96%), nearly doubling the effectiveness of GPT-4 with CoT-SC.

## AutoTNLI

**Experimental Setting.** The AutoTNLI dataset [kumar-etal-2022-autotnli] extends the INFOTABS dataset [vivek-etal-2020-infotabs] to construct a challenging Tabular Natural Language Inference task. This dataset contains 1,478,662 table-hypothesis pairs labeled as either "Entail" or "Neutral." In our adaptation, we treat the tabular data as premises in a manner analogous to the FOLIO dataset. Due to the dataset's large scale, we limit our evaluation to the first 1,000 table-hypothesis pairs and compare the performance of LLaMA-13B and LLaMA-65B using Direct, CoT, CoT-SC, and our CR method.

**Evaluation Results.** Table 4 shows that CR significantly outperforms the alternative prompting strategies. In particular, LLaMA-65B with CR achieves a 12.8% accuracy improvement over CoT-SC, demonstrating CR's superior ability to capture structural and linguistic nuances in logical inference.

**More Experiments and Ablation Studies.** Regarding the computational complexity of different methods, Table 5 and Table 6 (please refer to Appendix 8) demonstrate the superiority of CR over CoT, CoT-SC, and ToT on several logical inference tasks, including the LogiQA [liu2020logiqa] and ProofWriter [tafjord2020proofwriter] datasets. In addition, Table 2 presents ablation studies on the FOLIO wiki dataset using the GPT-3.5-turbo model, quantifying the impact of individual components---such as the verifier and the premises random choice mechanism---on CR's performance.

**Table 2: Ablation studies on FOLIO wiki dataset using GPT-3.5-turbo model.**

| Model         | Method                                                             | Acc. (%)               |
| ------------- | ------------------------------------------------------------------ | ---------------------- |
| -             | [Random]                                                           | 33.33                  |
| GPT-3.5-turbo | Direct                                                             | 62.92                  |
| GPT-3.5-turbo | CoT                                                                | 64.61 (+1.69)          |
| GPT-3.5-turbo | CoT-SC (k = 16)                                                    | 63.33 (+0.41)          |
| GPT-3.5-turbo | **CR** (**ours**, n = 2)                                           | **73.03** (**+10.11**) |
| GPT-3.5-turbo | **CR** (**ours**, n = 2, w/o Verifier)                             | 64.23 (+1.31)          |
| GPT-3.5-turbo | **CR** (**ours**, n = 2, w/o premises random choice)               | 68.73 (+5.81)          |
| GPT-3.5-turbo | **CR** (**ours**, n = 2, w/o Verifier, w/o premises random choice) | 67.23 (+4.31)          |

**Table 3: Experimental results on the AutoTNLI and Game of 24 datasets.**

| Model     | Method        | Acc. (%)         |
| --------- | ------------- | ---------------- |
| -         | [Random]      | 50.00            |
| LLaMA-13B | Direct        | 52.6             |
| LLaMA-13B | CoT           | 54.1 (+1.5)      |
| LLaMA-13B | CoT-SC (k=16) | 52.1 (-0.5)      |
| LLaMA-13B | **CR** (n=4)  | **57.0** (+5.4)  |
| LLaMA-65B | Direct        | 59.7             |
| LLaMA-65B | CoT           | 63.2 (+3.5)      |
| LLaMA-65B | CoT-SC (k=16) | 61.7 (+2.0)      |
| LLaMA-65B | **CR** (n=4)  | **72.5** (+12.8) |

## Game of 24

The Game of 24 is a numerical puzzle in which players must combine four given integers using basic arithmetic operations (addition, subtraction, multiplication, and division) to yield 24. A puzzle is considered successfully solved if the resulting equation is valid and each input number is used exactly once.

**Experimental Setup.** We evaluate a set of 100 puzzles curated by ToT [yao2023tree]. Our primary metrics are accuracy and the average number of visited states during the search. In our CR algorithm, a set of reachable states, `latex $S$ `, is maintained. The process begins with the initial state `latex $s$ ` (the four input numbers without operations), and at each iteration a state `latex $u\in S$ ` is selected. The Proposer chooses two numbers from `latex $u$ ` and applies a basic operation to generate a new state `latex $v$ `. After the Verifier confirms the validity of the operation, `latex $v$ ` is added to `latex $S$ `. When a state representing a valid solution (i.e., an equation that evaluates to 24) is reached, the Reporter traces back the derivation and outputs the solution. The process terminates either when a solution is reported or when the iteration count exceeds a predefined limit (`latex $L=50$ `). We run multiple parallel branches (with breadth `latex $b$ ` ranging from 1 to 5) to account for variability in the search.

**Results.** As summarized in Table 4, CR substantially outperforms ToT by achieving up to 98% accuracy (a 24% improvement over ToT's 74%) while exploring significantly fewer states.

**Comparison with ToT.** In the specific context of the Game of 24, the methodologies of Cumulative Reasoning (CR) and Tree of Thoughts (ToT) share similarities yet diverge significantly in their approach to state generation and exploration. A fundamental difference lies in how each iteration processes: CR is designed to introduce a single new state at each step, focusing on a step-by-step progression towards the solution. Conversely, ToT is characterized by its generation of multiple candidate states during each iteration, employing a filtration mechanism to narrow down the feasible states. This operational distinction suggests that ToT engages in a broader exploration of potential, including invalid, states, compared to the more streamlined approach of CR.

Furthermore, ToT relies on a pre-defined search structure, utilizing a constant width and depth within its search tree. This rigid framework contrasts with CR's more dynamic strategy, where the language model (LLM) itself influences the depth of the search, adapting the exploration breadth as needed across different stages of the problem-solving process. Such flexibility in CR not only optimizes the search path but also tailors the exploration to the complexity and requirements of each specific problem, potentially enhancing efficiency and efficacy in reaching the correct solution.

## Solving MATH Problems

The MATH dataset [hendrycks2021measuring] provides a comprehensive benchmark for mathematical reasoning across diverse subdomains such as Algebra and Geometry. We compare Complex CoT and our CR method, both with and without Progressive-Hint Prompting (PHP) [zheng2023progressive]. Our reproduction follows the evaluation protocol of lightman2023let, using an 8-shot prompting strategy on a 500-example subset that spans all difficulty levels (Levels 1--5).

**Results without Code Environment.** Table 5 shows that CR outperforms Complex CoT by 5.4% in overall accuracy when using a 4-shot strategy. In particular, CR yields substantial gains in Number Theory, Probability, PreAlgebra, and Algebra. Table 6 further demonstrates that at Level 5, the most challenging subset, CR achieves a 9.7% improvement, corresponding to a 43% relative gain over Complex CoT without PHP. The "Iters" column in Table 5 indicates the average number of LLM interactions, providing insight into the computational effort. CR demonstrates competitive iteration counts while achieving higher accuracy.

**With a Code Environment.** In addition to the experiments above, we extend CR by incorporating a Python code environment to emulate a semi-symbolic reasoning system. In this configuration, no external aids (such as memory modules, web Browse, or retrieval systems) are employed. Instead, the Python interpreter serves as a highly reliable and efficient **Verifier**, executing and validating arithmetic or symbolic expressions generated by the LLM Proposer. This setup allows the Proposer to generate hypotheses and mathematical expressions, which are then rigorously verified through code execution before being added to the CR's knowledge DAG. This highlights CR's flexibility in integrating different types of verifiers.

Tables 7 and 8 compare our approach with state-of-the-art methods such as PAL [gao2023pal] and ToRA [gou2023tora]. CR with code achieves an overall accuracy of 72.2% on the MATH dataset, reflecting a 38.9% relative improvement over PAL and an 18.8% improvement over ToRA. Furthermore, on the hardest Level 5 problems, CR with code exhibits a 66.8% relative improvement over PAL and a 12.8% improvement over ToRA.

# Related Work

#### Reasoning with Large Language Models (LLMs).

The quest to imbue LLMs with robust reasoning capabilities has spurred extensive research. Early approaches focused on generating intermediate steps [zaidan2007using; yao2021refining; hase2021can; yang2022seqzero; wu2022ai; zhou2022least]. Morishita et al. enhance language models' reasoning by utilizing a synthetic corpus based on formal logic theory. Uesato et al. [lightman2023let] compare process-based and outcome-based approaches in solving mathematical reasoning tasks. Further, a considerable breadth of research focuses on augmenting reasoning through symbolic systems, such as code environments, knowledge graphs, and formal theorem provers, showcasing the utility of hybrid approaches in complex reasoning tasks [mihaylov2018knowledgeable; bauer2018commonsense; kundu2018exploiting; wang2019improving; lin2019kagnet; ding2019cognitive; feng2020scalable; nye2021show; wang2022multi; chen2022program; lyu2023faithful; chen2022program; gao2023pal; gou2023tora; li2023chain; Jiang2022DraftSA; yang2023leandojo].

#### Chain-of-Thought (CoT) Prompting.

Initiated by Wei et al., the CoT reasoning paradigm underscores the value of multi-step logical pathways in deriving conclusive answers. Building on this, Wang et al. introduce self-consistency as an advanced decoding strategy, aiming to refine the basic greedy decoding used in CoT. Zhou et al. (Least-to-Most) and Khot et al. (Decomposed Prompting) further dissect complex tasks into manageable sub-tasks. Creswell et al. enhance reasoning quality via beam search. Fu et al. (Complex CoT) advocate for more complex few-shot prompts. Creswell et al. explore the enhancement of reasoning quality through a beam search across reasoning traces, while Fu et al. argue for increasing the complexity within few-shot prompts to improve performance. Recent developments include Li et al.'s DIVERSE, which investigates various reasoning paths for the same question and employs a verifier for accuracy through weighted voting. Du et al. present a multi-agent debate approach with multiple LLMs. Yao et al.'s Tree-of-Thought (ToT) framework introduces deliberation in decision-making by considering multiple reasoning paths. Zheng et al. propose an iterative approach, using previous responses as contextual clues in subsequent iterations. Feng et al. highlight the theoretical and practical implications of CoT for solving complex real-world tasks, including dynamic programming. Recently, there have also been many works on the self-criticizing process [tyen2023llms; li2024confidence; zhang2024small; lin2024criticbench; wang2024theoretical], showing that language models can have self-correction capabilities with theoretical guarantees.

#### Advanced Reasoning Frameworks.

Yao et al. [long2023large]'s Tree-of-Thought (ToT) framework allows LLMs to explore multiple reasoning paths and self-evaluate choices. As discussed in Section 3.1, CR differs from ToT by its cumulative DAG construction and distinct Proposer-Verifier-Reporter roles, fostering a more integrated use of all validated knowledge. Graph-of-Thoughts (GoT) frameworks [besta2024graph] also leverage graph structures for reasoning, representing thoughts as nodes and dependencies as edges. CR offers a specific operationalization of graph-based reasoning with its iterative, role-based DAG construction and explicit verification at each step. Forest of Thought (FoT) methodologies [bi2024forest] may explore multiple diverse reasoning trees or high-level plans concurrently. CR, while capable of exploring branches (e.g., parameter `latex $b$ ` in Game of 24), primarily focuses on the meticulous, cumulative construction of a single, coherent reasoning DAG.

#### Self-Critique and Iterative Refinement.

CR's Verifier role aligns with and extends self-critique concepts [madaan2023self; shinn2023reflexion; tyen2023llms; hosseini2024v; li2024confidence; lin2024criticbench; wang2024theoretical; zhang2024small]. While many self-critique methods refine a single reasoning trace or select among alternatives (e.g., Reflexion [shinn2023reflexion], Self-Refine [madaan2023self]), CR uses verification to build a persistent, growing DAG of validated knowledge that informs all subsequent reasoning steps. This iterative accumulation and reuse of verified steps is a key distinction. Zheng et al. (Progressive-Hint Prompting) also uses an iterative approach with previous responses as context, which CR incorporates in its MATH experiments.

Recent advancements focus on more nuanced verifiers and verification frameworks. For example, Li et al.'s DIVERSE employs a verifier for accuracy through weighted voting over various reasoning paths; in contrast, CR's verification is more deeply integrated into the step-by-step construction of the reasoning DAG. Hosseini et al. propose V\*, which improves LLM's reasoning by training a verifier on both correct and incorrect solutions generated during self-improvement, which then helps select the best answer from multiple candidates at inference time. More recent approaches, such as Li et al. (PANEL), investigate detailed, stepwise natural language self-critique providing linguistic feedback, while Ma et al. (General-Reasoner) introduce a generative model-based verifier. While CR's current Verifier often makes binary (valid/invalid) decisions or relies on external tools like code interpreters, future work could integrate such richer feedback mechanisms into the Verifier role.

# Conclusion

In this work, we introduce Cumulative Reasoning (CR), an approach leveraging LLMs in a structured, iterative process that mirrors human cognitive strategies. By orchestrating the roles of proposer, verifier(s), and reporter, CR not only decomposes complex problems into manageable tasks but also effectively recomposes the validated steps into comprehensive solutions. This methodology has demonstrated superior performance across various domains, including logical inference, the Game of 24, and MATH problems, showcasing the versatility and potential of CR in advancing the capabilities of LLMs in complex problem-solving scenarios.

# Proofs of Theorems

#### Proof of Lemma 1.

**Proof.**

```latex
$$\begin{align*}
&\qquad \qquad 1 - (1 - p_1 \cdot p_2)^n \leq (1 - (1 - p_1)^n) \cdot (1 - (1 - p_2)^n) \\
&\Leftrightarrow 1 - (1 - p_1 \cdot p_2)^n \leq 1 - (1 - p_1)^n - (1 - p_2)^n + (1 - p_1)^n \cdot (1 - p_2)^n \\
&\Leftrightarrow (1 - p_1)^n + (1 - p_2)^n \leq (1 - p_1 \cdot p_2)^n + (1 - p_1)^n \cdot (1 - p_2)^n\\
&\Leftrightarrow (1 - p_1)^n + (1 - p_2)^n \leq (1 - p_1 \cdot p_2)^n + (1 - p_1 - p_2 + p_1 \cdot p_2)^n
\end{align*}$$
```

Notice that

```latex
$$(1 - p_1 \cdot p_2) + (1 - p_1 - p_2 + p_1 \cdot p_2) \equiv (1 - p_2) + (1 - p_2) \equiv 2 - p_1 - p_2,$$
```

WLOG, let `latex $p_1 \geq p_2$ `, then

```latex
$$(1 - p_1 - p_2 + p_1 \cdot p_2) \leq (1 - p_1 ) \leq (1- p_2) \leq (1 - p_1 \cdot p_2).$$
```

From the monotonicity of function `latex $x^n + (2 - p_1 - p_2 - x)^n$ ` in the interval `latex $(-\infty, \frac{2 - p_1 - p_2}{2}]$ ` and the interval `latex $[\frac{2 - p_1 - p_2}{2}, +\infty)$ ` respectively, and the symmetry of `latex $\{(1 - p_1 - p_2 + p_1 \cdot p_2), (1 - p_1 \cdot p_2)\}$ ` and the symmetry of `latex $\{(1 - p_1), (1 - p_2)\}$ ` correspond to `latex $y = \frac{2 - p_1 - p_2}{2}$ `, we conclude the proof. QED

#### Proof of Theorem 1.

**Proof.**

```latex
$$P_{\text{CoT-SC}} \leq 1 - (1 - p_{\text{CoT}})^n \leq 1 - (1 - p_1 \cdot p_2)^n,$$
```

```latex
$$P_{\text{ToT}} = (1 - (1- p_1)^n) \cdot (1 - (1 - p_2)^n),$$
```

Combined with Lemma 1, now we have

```latex
$$P_{\text{CoT-SC}} \leq P_{\text{ToT}}.$$
```

From the Assumption, we have

```latex
$$P_{\text{ToT}} \leq (1 - (1 - p_{1_{\text{CR}} | (\text{premises})})^n) \cdot (1 - (1 - p_{2_{\text{CR} | (\text{premises, stage-1 nodes})}})^n) \leq P_{\text{CR}}.$$
```

Finally, we conclude that

```latex
$$P_{\text{CoT-SC}} \leq P_{\text{ToT}} \leq P_{\text{CR}}.$$
```

QED

# More on Experiments

## More Experimental Results

**Table: Comparison of results on LogiQA dataset.**

| Method | Acc.       | # Visited States |
| ------ | ---------- | ---------------- |
| Direct | 31.69%     | 1                |
| CoT    | 38.55%     | 1                |
| CoT-SC | 40.43%     | **16**           |
| ToT    | 43.02%     | 19.87            |
| CR     | **45.25%** | 17               |

**Table: Comparison of results on ProofWriter dataset.**

| Method   | Acc.       | # Visited States |
| -------- | ---------- | ---------------- |
| Standard | 46.83%     | 1                |
| CoT      | 67.41%     | 1                |
| CoT-SC   | 69.33%     | **16**           |
| ToT      | 70.33%     | 24.57            |
| CR       | **71.67%** | 16.76            |

**Table: Comparison of results on FOLIO (validation set) dataset.**

| Method   | Acc.       | # Visited States |
| -------- | ---------- | ---------------- |
| Standard | 60.29%     | 1                |
| CoT      | 67.65%     | 1                |
| CoT-SC   | 68.14%     | 16               |
| ToT      | **69.12%** | 19.12            |
| CR       | **69.11%** | **15.87**        |

**Table: Comparison of results on LD dataset.**

| Method   | Acc.       | # Visited States |
| -------- | ---------- | ---------------- |
| Standard | 71.33%     | 1                |
| CoT      | 73.33%     | 1                |
| CoT-SC   | 74.67%     | **16**           |
| ToT      | 76.83%     | 21.83            |
| CR       | **78.33%** | 16.98            |

For a fair comparison of different methods on the LogiQA, ProofWriter, FOLIO (validation set), and LD datasets, we report the third-party reproduced results by Sun et al. For details on the implementation of these experiments, please refer to their work.

## Computational Considerations

The structured approach of CR, involving distinct Proposer, Verifier, and Reporter roles, and iterative DAG construction, may entail different computational overhead compared to simpler methods like CoT or even ToT, depending on the configuration.

If all roles are LLM-based, CR can involve more LLM calls per problem than a single CoT pass. For instance, each reasoning cycle might involve a Proposer call and a Verifier call. However, this is a deliberate design choice aiming for higher accuracy. The number of iterations is managed by the Reporter or a predefined limit. As shown in our experiments (e.g., "Iters" in Table 5 for MATH problems, and "#Visited States" in Table 4 for Game of 24, and additional data in Appendix 8 such as Tables 5 and 6), CR often achieves superior accuracy. For example, in the Game of 24 (Table 4), CR (b=5) achieved 98% accuracy with only 14.86 visited states, while ToT (b=5) achieved 74% with 61.72 states. This suggests that while individual steps in CR might be more involved due to verification, the overall search can be more efficient by avoiding unproductive paths.

A significant aspect of CR's flexibility is the Verifier [hosseini2024v]. When an LLM is used as a Verifier (as in some of our FOLIO experiments), it adds to the LLM call count. However, as demonstrated in our MATH experiments with a code environment (Section 4.5), the Verifier can be a non-LLM tool (e.g., a Python interpreter). Such symbolic verifiers are typically much faster and cheaper than LLM calls, significantly reducing the overhead of the verification step while increasing its reliability.

CR's approach of conditioning on previously validated steps in the DAG means the context provided to the Proposer can grow. While this provides richer information, it can also increase the token count for LLM calls. Future work could explore optimizing these dependencies, for instance, by selecting only the most relevant prior steps to manage context size without sacrificing much of the benefit of cumulative knowledge.

CR trades potentially increased computational steps (especially if LLM verifiers are used) for significant gains in accuracy and robustness, particularly on complex tasks. Its efficiency in terms of exploring fewer states to reach a correct solution, as seen in several benchmarks, suggests that it offers a favorable balance, making it suitable for scenarios where high performance is critical, potentially being more effective than exhaustive search or very wide ToT explorations for achieving similar results. The architecture uses the same underlying LLM for all roles (distinguished by prompts), avoiding the need to load multiple large models. We believe CR is particularly well-suited for test-time scaling where achieving the best possible answer justifies the additional computational steps.

# More on Logic

**Limitations of First-Order Logic Systems.** It is not surprising that the labels verified by FOL are still not satisfying. There are several limitations inside the FOL systems:

1. Limitations of Expressiveness [lowenheim1967possibilities]: FOL even lacks the expressive power to capture some properties of the real numbers. For example, properties involving uncountably many real numbers often cannot be expressed in FOL. In addition, properties requiring quantification over sets of real numbers or functions from real numbers to real numbers cannot be naturally represented in FOL.

2. Translation Misalignment: Risk of semantic discrepancies during translation, rendering resolutions ineffective. For instance, translating statements as `latex $\forall \text{Bird}(x) \Rightarrow \text{CanFly}(x)$ ` and `latex $\forall x (\text{Fly}(x) \Rightarrow \text{Wings}(x))$ ` may cause a misalignment between "CanFly" and "Fly", leading to flawed conclusions. It often fails to capture the full richness and ambiguity of natural language and lacks basic common knowledge [gamut1990logic].

3. Undecidability: The general problem of determining the truth of a statement in FOL is undecidable [turing1936computable; chimakonam2012proof] (deeply connected to the halting problem), constraining its applicability for automated reasoning in complex tasks.

## Illustrative example on higher-order logic

Here we present a refined example derived from the FraCas dataset to illustrate higher-order logic inference. It is noteworthy that the FraCas dataset [cooper1996using] is dedicated to the realm of higher-order logic inference. This characterization also applies to a majority of the Natural Language Inference (NLI) datasets [kumar-etal-2022-autotnli], which encompass their internal syntax, semantics, and logic. The intricate linguistic components such as quantifiers, plurals, adjectives, comparatives, verbs, attitudes, and so on, can be formalized with Combinatory Categorial Grammar (CCG) along with the formal compositional semantics [mineshima2015higher].

Higher-order logic (HOL) has the following distinctive characteristics as opposed to FOL [mineshima2015higher]:

**Quantification over Functions**: Higher-order logic (HOL) allows for lambda expressions, such as `latex $\lambda y. \text{report\_attribute}(y, \text{report})$ `, whereby functions themselves become the subject of quantification. An illustration of this is found in the expression "a representative who reads this report." Here, quantification spans the predicates representing both the representative and the reading of the report, a phenomenon captured as a higher-order function. Unlike HOL, FOL is incapable of extending quantification to functions or predicates.

**Generalized Quantifiers**: The introduction of generalized quantifiers, such as "most," serves as another demarcation line between HOL and FOL. These quantifiers are capable of accepting predicates as arguments, enabling the representation of relations between sets, a feat that transcends the expressive capacity of FOL.

**Modal Operators**: Employing modal operators like "might" signifies a transition towards HOL. These operators, applicable to propositions, give rise to multifaceted expressions that defy easy reduction to the confines of FOL.

**Attitude Verbs and Veridical Predicates**: The integration of attitude verbs, such as "believe," and veridical predicates like "manage," injects an additional layer of complexity necessitating the use of HOL. These linguistic constructs can engage with propositions as arguments, interacting with the truth values of those propositions in subtle ways that demand reasoning extending beyond the capabilities of FOL.

Previously we have discussed the limitations of FOL systems, what about HOL systems? Crafting HOL programs that are solvable by symbolic systems is a daunting task, even for experts. It is also challenging for LLMs to write these intricate programs effectively. Using formal theorem provers based on higher-order (categorical) logic and (dependent) type theory ups the ante, making it even harder. However, CR solves these problems pretty well without resorting to and being restricted to symbolic systems, just like the way humans think.

# Appendix for Examples

[IMAGE: Figure 6 - Example from the FOLIO dataset. The left panel shows a problem along with its premises, while the subsequent panels display reasoning by CoT and CR respectively. CR leverages intermediate propositions to yield the correct prediction.]

[IMAGE: Figure 7 - An example from the Game of 24 dataset.]

[IMAGE: Figure 8 - An example from the MATH dataset.]

[IMAGE: Figure 9 - Solutions for the example presented in Figure 8 from the MATH dataset, generated by CoT and CR. CoT will generate the answer directly through a chain of thought. By contrast, CR will first generate a few hints, then several simple and foundational questions, and then answer them by self, and finally conclude with the help of the generated hints and question-answer pairs.]

# More on Datasets

## More FOLIO Examples

[IMAGE: More FOLIO examples - multiple figures]

## Curating FOLIO wiki dataset

1.  Missing common knowledge or contradictory to common knowledge; (9 in total, Example ID No. 34, 62, 162, 167, 228, 268, 526, 677, 679)

2.  Overly ambiguous problems failing to provide unequivocal answers; (37 in total, Example ID No. 141, 215, 216, 223, 252, 261, 298, 321, 330, 396, 402, 409, 411, 431, 432, 456, 457, 482, 483, 496, 563, 572, 599, 624, 629, 641, 654, 660, 673, 682, 698, 750)

3.  Inherent inconsistencies presented within the premises; (2 in total, Example ID No. 640, 643)

4.  Vague premises or typographical errors; (2 in total, Example ID No. 314, 315)

5.  Incorrect answers. (24 in total, Example ID No. 9, 46, 52, 84, 100, 144, 273, 276, 299, 310, 322, 345, 367, 437, 452, 453, 464, 557, 573, 578, 605, 632, 671, 715)

[IMAGE: Figure 10 - Example 679 from the FOLIO wiki dataset, the origin label provided by the FOL system is not correct, so we choose to curate this dataset, removing these examples with wrong labels.]

## More examples on problems excluded from FOLIO wiki curated

#### Type 1 Error: Missing common knowledge or contradictory to common knowledge

[IMAGE: Type 1 error examples]

#### Type 2 Error: Overly ambiguous problems failing to provide unequivocal answers

[IMAGE: Type 2 error examples]

#### Type 3 Error: Inherent inconsistencies presented within the premises

[IMAGE: Type 3 error examples]

#### Type 4 Error: Vague premises or typographical errors

[IMAGE: Type 4 error examples]

#### Type 5 Error: Incorrect answers

[IMAGE: Type 5 error examples]

# Appendix for Prompts

The design of few-shot prompts is critical to guiding the behavior of each LLM role within CR. We crafted these prompts intending to encapsulate the essence of each role:

- The Proposer prompt encourages the generation of plausible next steps or hypotheses.

- The Verifier prompt focuses on assessing the validity of these propositions.

- The Reporter prompt aims at determining the sufficiency of information for concluding the reasoning process.

There have been several works [reynolds2021prompt; zhang2024meta; zhou2024self] showing that zero-shot meta-prompts can also work well, which minimizes the bias introduced in the few-shot examples.

[IMAGE: Figure 11 - Prompt template for CR Proposer on logical inference tasks.]

[IMAGE: Figure 12 - Prompt template for CR Verifier on logical inference tasks.]

[IMAGE: Figure 13 - Prompt template for CR Reporter on logical inference tasks.]

[IMAGE: Figure 14 - Prompt template for CR Proposer on Game of 24.]

[IMAGE: Figure 15 - Prompt template for CR Verifier (a) on Game of 24.]

[IMAGE: Figure 16 - Prompt template for CR Verifier (b) on Game of 24.]

[IMAGE: Figure 17 - Prompt template for CR Reporter on Game of 24.]

[IMAGE: Figure 18 - Meta Prompt for CR with code environment on solving MATH problems.]
