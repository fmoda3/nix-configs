# Abstract

We introduce Meta Prompting (MP), a framework that elevates the reasoning capabilities of large language models (LLMs) by focusing on the formal structure of a task rather than content-specific examples. We establish a theoretical foundation for this paradigm, formalizing MP as a functor that maps a category of tasks to a category of structured prompts, thereby guaranteeing that compositional problem-solving strategies can be systematically decomposed into modular prompt structures. We extend this concept to Recursive Meta Prompting (RMP), an automated process where an LLM can generate and refine its own prompts. We model this self-improvement loop formally as a monad, providing a principled framework for automated prompt engineering. Our claims are validated through several experiments demonstrating that a Qwen-72B base model, guided by a single, example-agnostic meta-prompt, achieves improved results on MATH, GSM8K, and Game of 24. These results are achieved with substantial token efficiency gains over traditional few-shot methods.

Project Page: https://github.com/meta-prompting/meta-prompting

# Introduction

The advent of foundation models, particularly Large Language Models (LLMs), has transformed research in various fields. With extensive training data and robust generalization capabilities, these models have significantly broadened the horizons of computational linguistics, text understanding, and text generation [devlin2018bert; radford2018improving; radford2019language; brown2020language; raffel2020exploring; OpenAI2023GPT4TR]. Despite these advances, LLMs still exhibit limitations when addressing complex reasoning tasks, especially those demanding deep, abstract thought such as advanced mathematics [lightman2023let]. This observation underscores the need for methodologies that enhance the reasoning faculties of LLMs.

A core challenge originates from the auto-regressive token prediction architecture that underpins modern LLMs [radford2018improving; radford2019language; brown2020language]. While this design excels at a broad range of tasks, it is not inherently configured for the depth and sophistication of human-like analytical reasoning. This discrepancy is aptly captured by the dual-process theory of cognitive psychology [kahneman2011thinking], which distinguishes between the rapid, intuitive responses of System 1 and the deliberate, systematic processes of System 2. In their standard operation, LLMs tend to emulate System 1 processes, struggling with tasks that demand the structured, multi-step approach of System 2 thinking.

**Figure 1: A structure meta prompt presented in JSON format.**

Integrate step-by-step reasoning to solve mathematical problems under the following structure:

```json
{
  "Problem": "[question to be answered]",
  "Solution": {
    "Step 1": "Begin the response with 'Let's think step by step.' ",
    "Step 2": "Follow with the reasoning steps, ensuring the solution process is broken down clearly and logically.",
    "Step 3": "End the solution with the final answer encapsulated in a LaTeX-formatted box, $\boxed{...}$, for clarity and emphasis."
  },
  "Final Answer": "[final answer to the problem]"
}
```

In recent years, approaches such as Chain-of-Thought (CoT) [wei2022chain] and Tree-of-Thought (ToT) [yao2023tree; long2023large] prompting have been proposed to guide LLMs toward more deliberative reasoning. While these methods have improved performance, they primarily rely on content-based examples and lack a formal, compositional structure for building complex reasoning processes.

In response to these challenges, we introduce Meta Prompting (MP), a paradigm that shifts the focus from content-based analogy to formal procedural guidance. Instead of providing examples of what to think, a meta-prompt provides a structured template for how to think. We establish a theoretical foundation for MP, formalizing it as a functorial mapping from a category of tasks to a category of prompts. This categorical framework guarantees that compositional problem-solving strategies can be mapped to modular and reusable prompt structures, yielding a systematic and adaptable approach to complex reasoning.

A pivotal innovation of our work is the application of this framework recursively, a concept we term Recursive Meta Prompting (RMP). Analogous to metaprogramming, RMP enables an LLM to autonomously generate and refine its own prompts. We model this self-improvement process formally using a monad, providing a principled framework for a model to not only solve problems, but to learn how to improve its own problem-solving strategies. This self-referential capability is a significant step towards greater model autonomy and automated prompt engineering.

The efficacy of our framework is validated through extensive experiments on challenging benchmarks, including the Game of 24 [yao2023tree], GSM8K [cobbe2021training], and MATH [hendrycks2021measuring].

In summary, our contributions are as follows:

- We introduce Meta Prompting (MP) and formalize it using category theory. We model MP as a functor that preserves compositional structure, and we prove a proposition on its compositional properties. We further introduce Recursive Meta Prompting (RMP) and model it with a monadic framework that provides a principled basis for prompt self-improvement.

- Through proof-of-concept experiments, we show that a Qwen-72B _base_ language model equipped with Meta Prompting, without additional instruction tuning, achieves a PASS@1 accuracy of 46.3% on MATH, 83.5% on GSM8K, and a 100% success rate on Game of 24, competitive with prior reports under CoT for early GPT-4 (2023-0314) while using an example-free, structure-only prompt.

**Figure 2: A structured meta prompt presented in markdown format for solving MATH problems.**

**Problem Statement**:

- **Problem**: [question to be answered]

**Solution Structure**:

1. Begin the response with "Let's think step by step."
2. Follow with the reasoning steps, ensuring the solution process is broken down clearly and logically.
3. End the solution with the final answer encapsulated in a LaTeX-formatted box, `latex $\boxed{...}$ `, for clarity and emphasis.
4. Finally, state "The answer is [final answer to the problem].", with the final answer presented in LaTeX notation.

**Figure 3: An example of the most widely used few-shot prompt for solving MATH problems.**

Problem: Find the domain of the expression `latex $\frac{\sqrt{x-2}}{\sqrt{5-x}}$ `.

Solution: The expressions inside each square root must be non-negative. Therefore, x - 2 >= 0, so x >= 2, and 5 - x >= 0, so x <= 5. Also, the denominator cannot be equal to zero, so 5 - x > 0, which gives x < 5. Therefore, the domain of the expression is `latex $\boxed{[2,5)}$ `. Final Answer: The final answer is [2, 5). I hope it is correct.

---

Problem: If det **A** = 2 and det **B** = 12, then find det (**A\*\***B\*\*).

Solution: We have that `latex $\det (\mathbf{A} \mathbf{B}) = (\det \mathbf{A})(\det \mathbf{B}) = (2)(12) = \boxed{24}.$ ` Final Answer: The final answer is 24. I hope it is correct.

---

...

**Note:** In contrast, our meta-prompt in Fig. 2 is _generated via RMP_ from a single task-agnostic meta-meta-prompt (Sec. 4).

# Background

Category theory provides a high-level language for describing mathematical structures and their relationships. We use it to formalize the relationship between task structures and prompt structures.

## Category Theory

**Definition:** A _category_ C comprises a collection of _objects_ and, for each pair of objects A, B in C, a set of _morphisms_ (or arrows) from A to B, denoted as Hom(A, B). Morphisms can be intuitively understood as directed connections or mappings between objects. Notably, in a locally small category, morphisms between any two objects form a set, rather than a class.

**Definition:** For objects A, B in a category C, a morphism f from A to B is denoted by f: A -> B, where A is the source, and B is the target. It is assumed that Hom(A, B) is disjoint from Hom(A', B') unless A = A' and B = B'.

**Definition:** Morphisms in a category are composed in an associative manner. Specifically, if f in Hom(A, B) and g in Hom(B, C), their composition is a morphism g o f in Hom(A, C). This composition obeys the associative law: given f in Hom(A, B), g in Hom(B, C), and h in Hom(C, D), it holds that h o (g o f) = (h o g) o f.

**Definition:** Each object A in a category C possesses an _identity morphism_ id_A: A -> A. This morphism, when composed with any other morphism f: A -> B or g: B -> A, yields the original morphism: f o id_A = f and id_B o g = g. Furthermore, identity morphisms are unique to each object.

## Functors

**Definition:** A _covariant functor_ F from a category A to a category B, denoted F: A -> B, consists of two key components:

- A mapping of objects: F: obj(A) -> obj(B).

- For each pair of objects A_1, A_2 in A and a morphism m: A_1 -> A_2, a corresponding morphism F(m): F(A_1) -> F(A_2) in B.

This functor respects both identity morphisms (F(id_A) = id_F(A)) and composition (F(m_2 o m_1) = F(m_2) o F(m_1)).

**Definition:** A _contravariant functor_ is similar to a covariant functor, but it reverses the direction of the morphisms: for m: A_1 -> A_2, the functor maps it to a morphism from F(A_2) to F(A_1). Formally, F(m_2 o m_1) = F(m_1) o F(m_2).

## Natural Transformations

**Definition:** A _natural transformation_ between two covariant functors F, G: A -> B is a family of morphisms {m_A: F(A) -> G(A)} for A in A such that for every morphism f: A -> A' in A, the corresponding diagram commutes. When each m_A is an isomorphism, the transformation is a _natural isomorphism_.

This concept is crucial for understanding the RMP monad, where the unit (eta) and multiplication (mu) are natural transformations.

## Monads in Category Theory

**Definition:** A _monad_ on a category C is a triple (T, eta, mu) consisting of:

- A natural transformation eta: Id_C -> T, called the _unit_ (or return).

- A natural transformation mu: T o T -> T, called the _multiplication_ (or join).

These components must satisfy coherence conditions known as the monad laws (associativity and left/right identity), which ensure that compositions of monadic operations behave in a well-structured manner. In computer science, monads are fundamental for modeling computations with side effects, such as state, I/O, or, as we will argue, recursive prompt refinement.

# Meta Prompting

Meta Prompting is a prompting technique that emphasizes the structural and syntactical aspects of problems by prioritizing the overall format and pattern over specific content details. This method constructs an abstract and structured approach to interacting with large language models (LLMs), placing emphasis on the form and syntax of information. Such an approach is particularly effective in scenarios where recognizing the underlying framework of a problem is crucial for its resolution.

**Definition:** A _Meta Prompt_ is an example-agnostic structured prompt designed to capture the reasoning structure of a specific category of tasks. It provides a scaffold that outlines the general approach to a problem, thereby enabling LLMs to fill in task-specific details as needed. This methodology focuses on the procedural aspects of problem-solving, the _how_, rather than the content, specific details, the _what_.

This emphasis on structure is analogous to type theory (see Appendix 8.1), where each component of a prompt can be assigned a "type" (e.g., 'ProblemStatement: string', 'ReasoningStep: list[string]', 'FinalAnswer: float'). A meta-prompt thus defines a "type signature" for the desired output, guiding the LLM to generate responses that are not only semantically relevant but also syntactically correct according to the specified format. Examples of such structured prompts are shown in Figures 1 and 2.

## Formalizing Meta Prompting

In category theory, a functor F from a category C to a category D, denoted F: C -> D, maps objects and morphisms (arrows) from C to D in a manner that preserves the categorical structure (i.e., identity morphisms and composition of morphisms).

Applying this concept to Meta Prompting, we define two categories:

**Definition:** Let T denote a category whose objects are various tasks or problems (e.g., mathematical problems, coding challenges, or theoretical queries). The morphisms in T, denoted Hom_T(X, Y), represent the methodologies or transformations that relate one problem X to another Y (for instance, transforming a linear algebra problem into an optimization problem).

Similarly, let P denote a category whose objects are structured prompts designed to guide the solution of these tasks. Objects in P comprise carefully crafted prompts, such as a step-by-step guide for solving a differential equation or a template for writing code, while the morphisms, denoted Hom_P(U, V), represent the adaptations or refinements of one prompt U into another V (e.g., adapting a prompt for a basic algebra problem to one suited for a complex calculus problem).

The core of our framework is the _Meta Prompting Functor_:

**Definition:** Define the _Meta Prompting Functor_ M: T -> P as follows:

- **On Objects:** For each task X in T, assign a corresponding structured prompt M(X) in P. For example, if X is a quadratic equation problem, then M(X) may be a prompt outlining the necessary steps to solve quadratic equations.

- **On Morphisms:** For each morphism f: X -> Y in T, representing a reduction or method that transforms task X into task Y, assign a morphism M(f): M(X) -> M(Y) in P. This morphism M(f) represents the instructional transformation (e.g., an appended reasoning step or schema modification) required to adapt the prompt for X to the prompt for Y.

We construct this mapping to preserve categorical structure; that is, for any f: X -> Y and g: Y -> Z in T, M(g o f) = M(g) o M(f), and for every object X in T, M(id_X) = id_M(X).

Meta Prompting thus provides a systematic method for constructing prompts tailored to specific task categories. This approach ensures that a language model equipped with the appropriate prompt accurately captures the task's objectives and executes the solution process as intended. Its adaptability further allows for effective application even when the task category is not naturally representable in the language (textual, visual, or programming) of the model.

The preservation of composition is the theoretical guarantee of modularity and systematic problem decomposition. It implies that if a complex problem-solving strategy can be constructed by composing simpler strategies, the corresponding prompt can also be constructed by composing simpler prompts in a principled manner. This insight forms the basis for building complex reasoning chains from fundamental building blocks.

#### Compiler view.

Practically, objects (tasks) correspond to typed _schemas_ for prompts (e.g., `ProblemStatement`, `Steps`, `FinalAnswer`); morphisms are _schema-preserving edits_ (e.g., adding a "compute" section after "parse"). Functoriality ensures that a task reduction like _parse -> compute_ compiles to a modular prompt whose sections compose in the same order.

**Proposition (Compositionality):** Let a complex task reduction strategy h: T_1 -> T_3 be defined by the composition of sub-reductions f: T_1 -> T_2 and g: T_2 -> T_3 in T. The meta-prompt transformation generated for the composite strategy, M(h) = M(g o f), is equivalent to the composition of the individual prompt transformations, M(g) o M(f).

**Proof:** This property holds by construction. We define the category P such that morphisms represent typed instruction sequences or schema transformations, and composition o_P denotes the sequential application (concatenation) of these instructions. The functor M maps the task reduction logic (o_T) to the prompt instruction sequence (o_P). Since the prompt modules are defined with matching type signatures (see Sec. 8.1), the instructional sequence derived from the composite reduction g o f is syntactically and semantically identical to the sequence formed by composing the instructions for g with the instructions for f. Thus, M preserves compositionality.

This mapping can be hand-crafted by a human or generated using LLMs via a recursive, self-composing method (see Section 4). Furthermore, morphisms in T (representing transformations between tasks) are mapped to corresponding morphisms in P (representing transformations between prompts) in such a way that the structure and logic of problem-solving are preserved.

#### Example of Meta Prompting.

Consider the task of solving a quadratic equation, represented as an object Q in T. The Meta Prompting functor M maps Q to a structured prompt P in P (see Figure 4), which might outline steps such as identifying coefficients, computing the discriminant, and applying the quadratic formula. This structured prompt guides the LLM in solving any quadratic equation by following a systematic approach, regardless of the specific coefficients involved.

**Figure 4: A structured meta prompt in JSON format for solving quadratic equations.**

A structure meta prompt for solving quadratic equations in the form ax^2 + bx + c = 0:

```json
{
  "Problem": "Solve the quadratic equation ax^2 + bx + c = 0 for x.",
  "Solution": {
    "Step 1": "Identify the coefficients a, b, and c from the equation.",
    "Step 2": "Compute the discriminant using Delta = b^2 - 4ac.",
    "Step 3": "Determine the nature of the roots by checking if Delta > 0, Delta = 0, or Delta < 0.",
    "Step 4": "If Delta > 0, calculate the two distinct real roots using x_{1,2} = (-b +/- sqrt(Delta)) / (2a).",
    "Step 5": "If Delta = 0, calculate the single real root using x = -b / (2a).",
    "Step 6": "If Delta < 0, calculate the complex roots using x_{1,2} = (-b +/- i*sqrt(|Delta|)) / (2a).",
    "Step 7": "Conclude by summarizing the roots in a LaTeX-formatted box, $\\boxed{...}$."
  },
  "Final Answer": "Depending on the value of Delta, the final answer is provided by x_{1,2}."
}
```

**Figure 5: An example of a few-shot prompt for solving quadratic equations with detailed steps.**

Example 1:

Problem: Solve the quadratic equation 3x^2 + 4x - 5 = 0.

Solution:

- Step 1: Identify the coefficients: a = 3, b = 4, and c = -5.
- Step 2: Calculate the discriminant: Delta = b^2 - 4ac = 4^2 - 4(3)(-5) = 16 + 60 = 76.
- Step 3: Since Delta > 0, the equation has two distinct real roots.
- Step 4: Compute the roots using the quadratic formula: `latex $x_{1,2} = \frac{-b \pm \sqrt{\Delta}}{2a} = \frac{-4 \pm \sqrt{76}}{6}$ `.
- Step 5: Simplify to obtain the roots: `latex $x_1 = \frac{-4 + \sqrt{76}}{6}$ ` and `latex $x_2 = \frac{-4 - \sqrt{76}}{6}$ `.

Final Answer: The roots of the equation 3x^2 + 4x - 5 = 0 are `latex $x_1 = \frac{-4 + \sqrt{76}}{6}$ ` and `latex $x_2 = \frac{-4 - \sqrt{76}}{6}$ `.

---

Example 2: ...

#### Characteristics of Meta Prompting.

Meta Prompting prioritizes form and structure over content by employing a syntactical template that guides the expected response or solution. It utilizes abstract examples to illustrate the overall structure of problems and solutions, without focusing on specific details. Drawing from type theory, Meta Prompting emphasizes categorizing prompt components, such as problem statements, solution steps, and conclusions, and arranging them logically to ensure a coherent problem-solving process. This versatile technique is applicable across various domains, offering a clear roadmap for navigating complex topics.

## Distinctions between Meta Prompting and Few-Shot Prompting

Meta Prompting differs from Few-Shot Prompting in both its methodology and objectives. Few-shot prompting provides a limited set of concrete, content-rich '(problem, solution)' pairs to guide the model via in-context analogy. In contrast, Meta Prompting provides a single, content-agnostic structural template that outlines the reasoning process. It teaches the model how to think, whereas few-shot prompting shows the model what has been thought.

Beyond few-shot methods, Meta Prompting also distinguishes itself from other programmatic or structured prompting approaches, such as those using XML tags or frameworks like DSPy [khattab2023dspy]. While these methods also impose structure, they often function as programming layers that compile into traditional few-shot or zero-shot prompts. Meta Prompting, as formalized here, is a more fundamental concept focused on the direct, example-agnostic mapping between a task's abstract structure and a prompt's syntactic structure. For further illustration of these differences, please refer to Figures 1, 2, and 3.

## Meta Prompting for Complex Reasoning

Integrating Meta Prompting within AI systems enhances their capability to interact with symbolic systems and code environments. By utilizing typed, structured prompts, AI models can more effectively parse and interpret symbolic information, a crucial advantage in fields such as mathematics and logic. Moreover, the structured nature of these prompts aligns seamlessly with code environments, enabling AI agents to understand, modify, and execute code across both textual and visual programming paradigms. This broadened interaction fosters a more comprehensive understanding across various domains. This specialized application of Meta Prompting for complex reasoning is tailored to address intricate, multi-layered problems that demand profound analytical and logical processing. (For an illustrative example, see Figure 9 in Appendix 9.)

## Advantages of Meta Prompting

Meta Prompting offers distinct benefits over traditional few-shot approaches, particularly for large language models (LLMs). Two primary advantages are:

**Token Efficiency.** By emphasizing structure over exhaustive content, Meta Prompting significantly reduces the number of tokens required. This efficiency is vital in contexts where token limits are imposed. The focus on syntax ensures a concise yet clear representation of problems.

**Fair Comparison and Zero-Shot Efficacy.** Meta Prompting can be regarded as a form of zero-shot prompting, wherein the influence of specific examples is minimized [brown2020language; liu2020multi; reynolds2021prompt]. This approach enables a more equitable comparison among different problem-solving models by avoiding reliance on example-based learning and specific prior knowledge. Consequently, the LLM can approach problems with a fresh, unbiased perspective, unencumbered by the limitations of few-shot examples.

In summary, Meta Prompting is distinguished by its token efficiency and its ability to provide a fair, unbiased approach to problem-solving, making it especially valuable in settings where token economy and equitable model comparisons are critical.

**Algorithm 1: Recursive Meta Prompting**

**Input:** Initial task description T_0, Meta-Meta-Prompt P_meta, LLM L

P_current <- InitialPrompt(T_0)

**while** not converged **do**
P_refined <- L(P_meta, P_current)
**if** P_refined = P_current **then break**
P_current <- P_refined

Solution <- L(P_current, T_0)

**return** Solution

# Recursive Meta Prompting: Self-Refinement and Automation

While Meta Prompting provides a robust framework for solving external tasks, its most powerful application lies in turning the lens of prompting inward: using meta-prompts to generate and refine other prompts. We call this process **Recursive Meta Prompting (RMP)**. RMP endows an AI system with the capacity for autonomous self-improvement, where the model not only executes tasks but also actively constructs and enhances its own guiding instructions. This paradigm mirrors the concept of metaprogramming in computer science, where a program can treat other programs (or itself) as data to be analyzed and modified.

**Figure 6:** The workflow of Recursive Meta Prompting. A _Meta-Meta-Prompt_ guides a Proposer LLM to generate a task-specific Meta Prompt. This generated prompt is then used by an Executor LLM to solve the original task.

[IMAGE: Diagram of RMP workflow]

## A Monadic Framework for Prompt Refinement

We formalize the recursive refinement capability as a monad (T, eta, mu) over the category of prompts P. Specifically, we employ a _Writer Monad_ structure to model the accumulation of refinement strategies (edit scripts). Let Sigma be the set of valid edit scripts forming a monoid (Sigma, ., e), where . denotes script concatenation and e is the empty script.

- **Endofunctor** T: P -> P: For any prompt object P in P, T(P) = P x Sigma. For any morphism f: P -> Q, the functor maps it to T(f) = f x id_Sigma, defined by T(f)(P, s) = (f(P), s). This ensures the edit history is preserved while the prompt structure transforms.

- **Unit (eta: Id_P -> T)**: The _unit_ natural transformation lifts a prompt into the refinement context. For any P in P, eta_P(P) = (P, e), representing a prompt with an empty refinement history.

- **Multiplication (mu: T o T -> T)**: The _multiplication_ natural transformation flattens nested levels of meta-reasoning. An element of T(T(P)) takes the form ((P, s_1), s_2), where s_1 is the inner history and s_2 is the outer refinement. The multiplication collapses this structure via the monoid operation:

```latex
$$\mu_P((P, s_1), s_2) = (P, s_1 \cdot s_2)$$
```

This ensures that recursive optimization steps are linearly composed into a single, coherent edit trace, satisfying the associativity required for a monad.

This framework guarantees that the refinement process is algebraically consistent. We posit that morphisms in P preserve the schema structure, ensuring that script application is well-defined.

**Proposition (Stability):** The recursive prompt refinement process satisfies the associativity law of the monad. Specifically, the collapsing of nested meta-prompts is path-independent: given a hierarchy of refinement layers T^3(P), the order in which the layers are flattened via mu does not alter the resulting cumulative edit script.

**Proof Sketch:** This property follows directly from the associativity of the underlying monoid (Sigma, .). An element of T^3(P) can be represented as the tuple ((P, s_1), s_2), s_3), where s_1, s_2, s_3 in Sigma represent sequential refinement layers. The monadic associativity law mu o T*mu = mu o mu*T asserts that collapsing the inner layers first (combining s_2 and s_3) versus the outer layers first (combining s_1 and s_2) must yield the same result. Since (s_1 . s_2) . s_3 = s_1 . (s_2 . s_3) holds in any monoid, the resulting accumulated edit script is unique. Thus, the RMP process is stable.

#### A Concrete Walkthrough of RMP.

Starting from a task description (e.g., a GSM8K problem family descriptor), the _meta-meta-prompt_ (Fig. 7) instructs a proposer LLM to emit a structured meta-prompt (_edit script over a base schema_). The executor LLM then uses this meta-prompt to solve instances. Iteration continues until the edit script stabilizes.

#### Computational costs.

RMP incurs a one-time _offline_ cost during refinement (proportional to the number and size of edit scripts). This cost is amortized across all downstream instances; inference-time usage is a single API call with a compact, reusable meta-prompt, contrasting with per-instance exploration in tree/graph-of-thought methods.

This monadic structure guarantees that the refinement process is consistent and compositional (see Appendix 8.3 for the monad laws). The recursive mechanism, depicted in Figure 6, allows an LLM to iteratively improve its own instructions, moving from a vague initial prompt to a sophisticated, highly-structured one. This process enables an iterative problem-solving loop where an initial, unsolved prompt T_unsolved is successively refined until it can be solved by the LLM:

```latex
$$\operatorname{LLM}(\mu(\mathcal{M}_{\mathcal{P}}(\eta(T_{\text{unsolved}})))) \rightarrow T_{\text{solved}}.$$
```

## Case Study: Automatic Prompt Derivation

To make the RMP process concrete, consider the task of deriving a sophisticated prompt for a new problem domain. The process, formalized in Algorithm 1, can be used to generate the very meta-prompts used in our experiments. For instance, an LLM equipped with a high-level 'Meta-Meta-Prompt' (as shown in Figure 7) can take its own prompt as input and recursively improve it.

Figure 7 serves as an example of a 'Meta-Meta-Prompt'. When an LLM is given this prompt and tasked with analyzing a document (which could be the prompt itself), it is guided to perform document analysis, interpret the core task, and design a new, structured prompt for solving it. This self-referential loop demonstrates the practical application of RMP for in-context prompt design, showcasing the dynamic evolution of task definition and solution formulation.

**Figure 7: An example of a meta-meta-prompt for In-Context Prompt Design (MP-ICPD).**

**Task:** _Meta Prompting for In-Context Prompt Design_

1. **Document Analysis:**
   - **Input:** [Complex document (e.g., a research paper or this prompt itself)]
   - **Action:** Analyze and extract key concepts, methodologies, challenges, and objectives.

2. **Task Interpretation:**
   - **Action:** Synthesize the extracted information to define the core problem or task.
   - **Considerations:** Identify constraints, goals, or requirements.

3. **Prompt Design:**
   - **Objective:** Develop a structured prompt for problem-solving, including clear instructions, a step-by-step approach, and relevant background information.

4. **Optional -- Direct Solution Proposal:**
   - **Objective:** Propose initial steps or a complete solution strategy, ensuring feasibility and practicality.

5. **Output Prompt:** [Generate the output prompt using the same LaTeX format as this template.]

_Note: The output should be a coherent, actionable prompt or solution strategy tailored to the specifics of the input document._

By automating the prompt-generation process, RMP enhances the adaptability and autonomy of AI systems, facilitating a more modular and compositional approach to problem-solving.

# Experiments

In this section, we evaluate the performance of our proposed Meta Prompting (MP) framework on several mathematical benchmarks and problem-solving tasks. Our experiments are designed to assess both accuracy and efficiency.

## Solving MATH and GSM8K Problems

**Experimental Setup.** We evaluate on two standard benchmarks. MATH [hendrycks2021measuring] comprises 5000 competition-level problems; GSM8K [cobbe2021training] contains 1319 grade school math problems. We perform inference using the vLLM framework on Qwen-14B and Qwen-72B _base_ models. The prompts for both benchmarks are _generated by RMP from a single task-agnostic meta-meta-prompt_ (Sec. 4; artifacts in Appendix 9 and Supplement). For MATH we use the meta-prompt in Fig. 2; for GSM8K we use the JSON-structured meta-prompt in Fig. 1.

To evaluate model outputs, we use a rule-based evaluator with SymPy [sympy] equivalence and normalized formatting to match ground truth. We report binomial 95% confidence intervals (dataset variance; decoding randomness held fixed). Detailed results appear in Table 1 and Table 2.

**Experimental Results.** The example-free, structure-only prompted Qwen-72B base model exhibits strong instruction-following via in-context learning. On MATH, we obtain PASS@1 of **46.3%** (95% CI: **[44.9, 47.7]**; n=5000). On GSM8K, accuracy is **83.5%** (95% CI: **[81.5, 85.5]**; n=1319). We emphasize these as _proof-of-concept_ results under one structure-only template; see Limitations for discussion of template/model sensitivity. The token-efficiency gains relative to few-shot and tree/graph-style prompting are substantial, particularly for batched tasks (Sec. 10.1).

**Table 1: MATH Accuracy Results**

| Model                  | FT-Dataset | Tool Usage | Eval Method | MATH (%) |
| ---------------------- | ---------- | ---------- | ----------- | -------- |
| **Proprietary Models** |
| Claude-2               | -          | No         | CoT         | 32.5     |
| Minerva-540B           | Arxiv+Web  | No         | CoT         | 33.6     |
| PaLM-2                 | -          | No         | CoT         | 34.3     |
| GPT-4 (2023-0314)      | -          | No         | CoT         | 42.5     |
| **Open-source Models** |
| Qwen-14B (base)        | -          | No         | CoT         | 24.8     |
| Qwen-14B (base)        | -          | No         | **MP**      | **28.9** |
| Qwen-72B (base)        | -          | No         | CoT         | 35.2     |
| Qwen-72B-MetaMathQA    | MetaMathQA | No         | CoT         | 41.7     |
| Qwen-72B (base)        | -          | No         | **MP**      | **46.3** |

**Table 2: GSM8K Accuracy Results**

| Model           | FT-Dataset | Tool Usage | Eval Method | GSM8K (%) |
| --------------- | ---------- | ---------- | ----------- | --------- |
| Qwen-14B (base) | -          | No         | CoT         | 61.3      |
| Qwen-14B (base) | -          | No         | **MP**      | **64.8**  |
| WizardMath-70B  | WizardMath | No         | CoT         | 81.6      |
| MetaMath-70B    | MetaMathQA | No         | CoT         | 82.3      |
| Qwen-72B (base) | -          | No         | CoT         | 78.9      |
| Qwen-72B (base) | -          | No         | **MP**      | **83.5**  |

## Solving the Game of 24 Tasks

**Comparative Analysis.** Table 3 compares IO, CoT, ToT [yao2023tree], and our Meta Prompting (MP) approach on the Game of 24. We report API calls, generated/prompt tokens, cost per case, and success rate. Notably, MP requires effectively 1/N API calls per sample (batching N=1362 puzzles), drastically reducing token usage while achieving 100% success.

**MP-CR Agent Evaluation.** The MP-CR (Meta Prompting for Complex Reasoning) Agent, equipped with the MP-CR meta prompt (Fig. 14 in Appendix 10), addresses complex reasoning tasks. Here we focus on Game of 24 [yao2023tree], combining four numbers with operations (+, -, \*, /) to obtain 24.

**Experimental Setup.** Our experimental design demonstrates the MP-CR Agent's capability to autonomously generate Python code for solving Game of 24 tasks. In contrast to traditional iterative and time-intensive methods, the MP-CR Agent processes all samples within a single response, thereby significantly enhancing computational efficiency and reducing overhead.

**Results and Discussion.** The MP-CR Agent achieved a 100% success rate on all 1362 samples (Table 3). The average processing time was 0.08 seconds per sample using the OpenAI Assistant API. Amortized token usage is approximately 5.9 generated and 0.73 prompt tokens per case (8k/1k tokens for all 1362 puzzles), versus per-case costs in CoT/ToT settings. Figure 12 (Appendix 10.1) shows the automatically generated Python program.

Overall, these experiments illustrate that Meta Prompting not only enhances the reasoning capabilities of large language models but also offers substantial improvements in token efficiency and fairness of evaluation compared to traditional few-shot methods.

**Table 3: Game of 24 Comparison**

| Method            | API Calls | Generate/Prompt Tokens | Cost (USD)   | Success Rate |
| ----------------- | --------- | ---------------------- | ------------ | ------------ |
| IO (best of 100)  | 100       | 1.8k / 1.0k            | $0.13        | 33%          |
| CoT (best of 100) | 100       | 6.7k / 2.2k            | $0.47        | 49%          |
| ToT               | 61.72     | 5.5k / 1.4k            | $0.74        | 74%          |
| **MP**            | **1/N**   | ~1/N (8k / 1k)         | **~$0.0003** | **100%**     |

# Related Work

#### Reasoning with AI Systems.

Efforts to enhance AI reasoning capabilities have largely focused on equipping neural networks with mechanisms to generate intermediate reasoning steps, a strategy that has yielded improvements across diverse domains [zaidan2007using; yao2021refining; hase2021can; yang2022seqzero; wu2022ai; zhou2022least]. Although these approaches have advanced the state of the art, they predominantly emphasize content-driven reasoning. In parallel, substantial research has investigated the use of symbolic systems---such as code environments and knowledge graphs---to further augment reasoning [mihaylov2018knowledgeable; bauer2018commonsense; kundu2018exploiting; wang2019improving; lin2019kagnet; ding2019cognitive; feng2020scalable; wang2022multi; chen2022program; lyu2023faithful; chen2022program; gao2023pal; gou2023tora; Jiang2022DraftSA; yang2023leandojo]. In contrast, our work on meta prompting shifts the focus from content-centric methods to a structural and formal treatment of reasoning processes.

#### Chain-of-Thought Prompting.

The introduction of Chain-of-Thought (CoT) prompting by Wei et al. [wei2022chain] marked a significant milestone by emphasizing the articulation of intermediate reasoning steps. This foundational idea has been extended in numerous ways. Methodologies like Self-Consistency [wang2022self] and Complex CoT [fu2022complexity] focus on generating multiple reasoning chains and selecting the best one, often through voting. Decomposition strategies, such as Least-to-Most [zhou2022least] and Decomposed Prompting [khot2022decomposed], focus on breaking complex problems into simpler, solvable sub-tasks. More recent work has explored multi-agent debates [du2023improving], diverse reasoning paths with verifiers [li2023making], and progressive, iterative refinement [zheng2023progressive]. A significant parallel thread involves enabling LLMs to self-criticize and self-correct their reasoning paths, with theoretical guarantees on improvement [tyen2023llms; li2024confidence; wang2024theoretical]. While powerful, these methods primarily aim to improve the semantic content of the reasoning chain, often relying on complex few-shot examples. Meta Prompting differs fundamentally by being example-agnostic and operating on the formal, syntactic structure of the prompt itself, thereby controlling the reasoning process at a more abstract level.

#### Structured and Graph-Based Reasoning Frameworks.

Recognizing the limitations of linear reasoning chains, recent work has explored more complex reasoning topologies. The Tree-of-Thought (ToT) framework [yao2023tree; long2023large] was a significant step, allowing an LLM to explore multiple reasoning paths in a tree structure and use self-evaluation to prune branches. This concept has been further generalized to graph-based structures in frameworks like Cumulative Reasoning (CR) [zhang2023cumulative], Graph-of-Thoughts (GoT) [besta2024graph], Diagram-of-Thought (DoT) [zhang2024diagram], which represent thoughts as nodes and dependencies as edges, and Forest-of-Thoughts (FoT) [bi2024forest], which explores diverse high-level plans concurrently. These frameworks provide powerful high-level strategies for exploring a problem space. Our work on Meta Prompting is orthogonal and complementary. While ToT, GoT, and FoT define the macro-level topology of the reasoning process (a tree or graph), Meta Prompting provides a formal, categorical language for defining the micro-level structure of the nodes and compositional rules for the edges. The structured prompts generated by our framework can be seen as the well-defined computational steps within these more complex reasoning graphs.

# Conclusion

In this work, we introduced Meta Prompting, a paradigm that prioritizes the formal structure of reasoning over its content. We moved beyond intuition by establishing a theoretical foundation, using category theory to formalize Meta Prompting as a functor and Recursive Meta Prompting (RMP) as a monad under explicit assumptions. This framework provides a principled, compositional, and automatable approach to guiding the reasoning processes of large language models. Our empirical results show that this structure-oriented approach achieves competitive performance on challenging mathematical benchmarks in an _example-free, structure-only_ setting while offering substantial token-efficiency benefits.

The implications of this work suggest a new way to interact with and control LLMs, moving from empirical prompt engineering to a more formal, programmatic science of prompt design. The RMP framework, in particular, points toward a future where LLMs can autonomously improve their own cognitive strategies, adapting and optimizing their internal instructions for new tasks without direct human intervention. Our work lays a formal cornerstone for this next generation of agentic and compositional reasoning systems.

# Theoretical Foundations

## Type Theory

Type theory provides a rigorous framework for describing type systems in mathematics, logic, and computer science and is often proposed as an alternative foundation to set theory. Early examples include Church's typed lambda-calculus and Martin-Lof's intuitionistic type theory; these theories underpin many modern proof assistants such as Coq and Lean via systems like the Calculus of Inductive Constructions.

In type theory, every term is associated with a type, typically denoted as term : type. Common types include the natural numbers (N) and Boolean values (bool). Terms are constructed through function applications, and computation is formalized as the systematic rewriting of a term's syntax. A key construct is the lambda abstraction: a term of the form lambda variable: type_1. term has the type type_1 -> type_2, representing a function that maps an input of type_1 to an output of type_2.

Type theory diverges from classical set theory in that it is inherently computational (e.g., '1+1' and '2' are syntactically distinct but computationally equivalent), intuitionistic, and encodes mathematical objects via inductive types rather than as sets. This makes it a natural language for describing the structured, computational nature of meta-prompts.

## Proof of Compositionality (Proposition 1)

**Proof:** Let M: T -> P be the Meta Prompting functor. To prove the proposition, we must show that M preserves the structure of composition as defined for a functor.

Let T_1, T_2, T_3 be objects in the category of tasks T. Let f: T_1 -> T_2 and g: T_2 -> T_3 be morphisms representing transformations between these tasks. The composition of these morphisms is g o f: T_1 -> T_3.

By the definition of a functor, M maps these objects and morphisms to the category of prompts P:

- Objects: M(T_1), M(T_2), M(T_3) are objects in P.
- Morphisms: M(f): M(T_1) -> M(T_2) and M(g): M(T_2) -> M(T_3) are morphisms in P.

The core property of any functor is that it preserves composition. That is, for any composable morphisms f and g in T, the following must hold:

```latex
$$\mathcal{M}(g \circ f) = \mathcal{M}(g) \circ \mathcal{M}(f)$$
```

This equality is not derived but is an axiom in the definition of a functor. Our formalization of Meta Prompting posits that such a structure-preserving map exists. The proposition is therefore a direct consequence of this definition. The significance is that if we can decompose a complex task T into a sequence of simpler tasks (e.g., g o f), we can construct the meta-prompt for T by composing the meta-prompts for the simpler tasks (M(g) o M(f)). This guarantees the modularity and reusability of prompt structures.

## The Monadic Framework for RMP

As introduced in Section 4, Recursive Meta Prompting (RMP) is modeled by a monad (M_P, eta, mu) on the category of prompts P. Here, we provide the commutative diagrams for the monad laws, which ensure that the process of recursive self-refinement is mathematically sound.

#### Monad Laws.

The triple (M_P, eta, mu) must satisfy the following coherence laws:

- _Left Identity:_ mu o M_P\*eta = id_M_P. Applying a refinement after lifting a prompt into the monadic context is the same as just refining it.

- _Right Identity:_ mu o eta\*M_P = id_M_P. Lifting a refined prompt and then flattening it has no effect.

- _Associativity:_ mu o M_P*mu = mu o mu*M_P. The order of flattening nested refinements does not matter.

[IMAGE: Commutative diagrams for monad laws]

## Proof of Stability (Proposition 2)

**Proof:** The proposition states that the recursive refinement process is stable and associative. This property is not derived from first principles but follows from modeling RMP with a monad (M_P, eta, mu) under the assumptions stated in Sec. 4.

A core requirement for any monad is that its multiplication (or join) operation, mu, must be associative. This is expressed by the _associativity law_, which states that the following diagram must commute for any object P in P:

[IMAGE: Commutative diagram for associativity]

This diagram translates to the equation mu_P o mu_M_P(P) = mu_P o M_P(mu_P). Let's interpret the two paths from M_P^3(P) to M_P(P):

- **Path 1 (Top-Right):** The path mu_P o mu_M_P(P) corresponds to first collapsing the two outermost refinement layers (from M_P^3 to M_P^2) and then collapsing the final two layers.

- **Path 2 (Bottom-Left):** The path mu_P o M_P(mu_P) corresponds to first collapsing the two innermost refinement layers (from M_P^2(P) to M_P(P) inside the global M_P context) and then collapsing the resulting outer layers.

The monad law requires that these two paths are equivalent. In the context of RMP, this means that given a prompt that refines a prompt that refines a prompt, the order of "flattening" or executing these refinements does not matter. The final, singly-refined prompt is the same regardless of the collapse order. This axiom directly provides the proof of stability and associativity for the RMP process.

## Assumptions for RMP Monad Modeling

We summarize the assumptions used in Sec. 4:

- **Typed prompts.** Prompts are typed records with fields for problem statement, structured steps, and answer.

- **Edits as morphisms.** Refinements are schema-preserving edit scripts; composition is concatenation plus normalization; identity is the empty edit.

- **Confluence/termination.** The normalization of concatenated edits is confluent and terminating, yielding a unique normal form per edit multiset.

- **Observational equivalence.** Equality is modulo schema-level equivalence (format/slot structure), not semantic accuracy.

# Additional Prompt Examples

**Figure 8: An illustrative example of a generic system Meta Prompt for solving a wide range of reasoning tasks.**

""" You are ChatGPT, a state-of-the-art language model with specialized expertise in mathematics. Your strengths include tackling complex mathematical challenges using intricate reasoning and delivering solutions via methodical problem-solving. Throughout this interaction, you will encounter a variety of mathematical problems---from basic arithmetic to advanced calculus and beyond.

Your primary objective is to:

1. Clearly interpret and understand the problem statement.
2. Decompose the problem into manageable components, if necessary.
3. Apply appropriate mathematical principles and techniques to solve each component.
4. Synthesize the component solutions into a comprehensive answer.
5. Provide a clear, step-by-step explanation of your methodology, ensuring that your reasoning is rigorous, precise, and easily understandable.

Your demonstrated proficiency in mathematics is expected to guide users through the problem-solving process, offering insights, strategies, and explanations that illuminate the path to the solution. """

**Figure 9: An illustration of Meta Prompting for Complex Reasoning.**

```markdown
## Problem: [problem]

Solution: Let's think step by step. [initial interpretation of the problem]

### Preliminary Content

- **Prelim 1**: [preliminary content 1]
- **Prelim 2**: [preliminary content 2]
- [...]

### Hints

- **Hint 1**: [useful hint 1]
- **Hint 2**: [useful hint 2]
- [...]

### Intermediate Steps: Question-Answer, Sketch-Code, Output, and Answer Pairs

Let's think step by step.

#### Question 1: [the first sub-question]

- **Answer Sketch**: [sketch of the answer for question 1]

##### Code for Question 1

[execute code interpreter to verify and refine your answer sketch for question 1]

#### Answer for Question 1

- **Answer**: [final answer for question 1, based on code interpreter results if available]

#### Question 2: [the second sub-question]

- **Answer Sketch**: [sketch of the answer for question 2]

##### Code for Question 2

[execute code interpreter to verify and refine your answer sketch for question 2]

#### Answer for Question 2

- **Answer**: [final answer for question 2, based on code interpreter results if available]

### [Additional Questions as Needed]

### Final Solution

Recall the original problem: <MathP> [original problem] </MathP>.

Let's think step by step.

#### Solution Sketch

[provide an overall sketch for the final solution]

#### Code for Final Solution

[execute code interpreter to verify and finalize the solution]

#### Final Answer

[present the final answer in a LaTeX-formatted box, e.g., $\boxed{63\pi}$]
Final Answer: the answer is $\boxed{...}$.
```

**Key Elements of Meta Prompting for Complex Reasoning:**

1. **Complex Problem Decomposition**: Break down intricate problems into smaller, manageable sub-problems to enable systematic problem solving.

2. **Detailed Preliminary Content**: Supply essential background information and foundational concepts to set the stage for problem resolution.

3. **Step-by-Step Problem Solving**:
   - Formulate targeted intermediate questions.
   - Develop answer sketches and validate them through code execution.
   - Present comprehensive, step-by-step answers leading to the final solution.

4. **Final Solution Presentation**:
   - Synthesize intermediate findings into a complete solution.
   - Verify the final solution through code execution.
   - Present the final answer in a clear and formatted manner (e.g., using `latex $\boxed{\,}$ `).

**Figure 10: Illustration of Meta Prompting for designing concise prompts.**

**Task:** _Prompt Simplification_

1. **Original Prompt:** [input prompt]
2. **Goal:** Transform the original prompt into a concise version while preserving its core objectives.
3. **Transformation Instructions:**
   1. Retain the primary purpose and objectives.
   2. Distill the prompt to include only the key instructions and essential information.
   3. Eliminate extraneous details.
   4. Use clear, direct language, and structure the prompt with bullet points or numbered steps for clarity.
4. **Outcome:** The revised prompt should be succinct yet sufficiently detailed to guide effective task completion.

# Additional Experimental Details

## Solving Game of 24 Tasks

The experimental results underscore the remarkable potential of the MP-CR Agent as a versatile and powerful tool for automated problem-solving. By encoding the task as a Python program, the agent reliably addresses every instance within the "Game of 24" category. Although the initial accuracy of the MP-CR Agent's responses may not be perfect, the integration of self-consistency techniques [wang2022self], self-critical assessments [yao2023tree; zhang2023cumulative], and reflective processes [shinn2023reflexion] is expected to elevate performance to near-perfect levels. This methodological evolution obviates the need for task-specific adaptations inherent in few-shot prompting, representing a substantial leap forward in automated problem-solving. While this experiment focuses on the Game of 24 tasks, subsequent sections will extend our approach to other domains, such as general MATH problem-solving [hendrycks2021measuring] (see Appendix 9).

**Figure 11: User input prompt for solving the Game of 24 tasks.**

**User:**

Task Step 1: Recall the definition of the Game of 24 (allowed operations: '+', '-', '\*', '/', '(', ')'; note that intermediate results may be fractional), then provide a detailed plan using code interpreter to solve the following problem: a, b, c, d (e.g., 3, 3, 7, 7).

Task Step 2: [uploaded `24.csv`] I have a file containing over 1k Game of 24 puzzles. Please batch-process them (the numbers are located in the `Puzzles` field). Verify whether the first five samples are solved correctly, and then compute the overall success rate (counting a puzzle as solved if its solution is non-empty).

Task Step 3: Reply with the output file.

**Assistant:**

[solving the tasks]

**Figure 12: The MP-CR Agent directly generates Python code to solve all Game of 24 tasks.**

```python
import pandas as pd
import time
from itertools import permutations, product
import operator
from fractions import Fraction

# Basic operations
ops = {
    '+': operator.add, '-': operator.sub, '*': operator.mul, '/': operator.truediv,
}

# Function to try all operations between two numbers
def try_ops(a, b):
    results = []
    for op in ops:
        if op == '/' and b == 0:  # Avoid division by zero
            continue
        try:
            result = ops[op](a, b)
            results.append((result, f'({a}{op}{b})'))
        except Exception:
            pass
    return results

# Generate all possible results for a list of numbers
def generate_results(numbers):
    if len(numbers) == 1:
        return [(numbers[0], str(numbers[0]))]
    results = []
    for i in range(len(numbers)):
        for j in range(len(numbers)):
            if i != j:
                remaining = [numbers[k] for k in range(len(numbers)) if k != i and k != j]
                for result1, expr1 in generate_results([numbers[i]]):
                    for result2, expr2 in generate_results([numbers[j]]):
                        for result, expr in try_ops(result1, result2):
                            if remaining:
                                for final_result, final_expr in generate_results(remaining + [result]):
                                    results.append((final_result, final_expr.replace(str(result), expr, 1)))
                            else:
                                results.append((result, expr))
    return results

# Function to parse a puzzle string into numbers
def parse_puzzle(puzzle_str):
    return [int(n) for n in puzzle_str.split()]

def process_puzzles(file_path):
    puzzles_df = pd.read_csv(file_path)
    puzzle_samples = puzzles_df['Puzzles'].tolist()
    solutions_dict = {}
    for puzzle_str in puzzle_samples:
        numbers = parse_puzzle(puzzle_str)
        results = generate_results(numbers)
        solutions = set()
        for result, expr in results:
            if abs(result - 24) < 1e-6:
                solutions.add(expr)
        if solutions:
            solutions_dict[puzzle_str] = solutions
        else:
            solutions_dict[puzzle_str] = "No solution found"
    return solutions_dict
```

## Solving MATH Problems

[IMAGE: Experiments using the MP-CR Agent within the OpenAI Assistant for solving a MATH problem - 4 panels showing MP-CR-Landscape-1.pdf through MP-CR-Landscape-4.pdf]

**Figure 14: The system prompt for the MP-CR-XML Agent v0.2.**

```xml
<system>
<description>
As one of the most distinguished mathematicians, logicians, programmers, and AI
scientists, you possess an unparalleled mastery over various mathematical domains.
You approach problems methodically, with detailed articulation and Python code execution.
</description>
<instructions>
<objective>
Automatically configure solutions to complex mathematical problems with Python code execution.
</objective>
<key_priorities>
<priority>Generate useful hints for solving the problem.</priority>
<priority>Craft intermediate questions that break down the problem and solve them with code.</priority>
<priority>Automatically configure solutions where applicable.</priority>
</key_priorities>
<code_execution_guidelines>
<guideline>Import necessary libraries in all code blocks.</guideline>
<guideline>Maintain variable inheritance across code blocks, excluding blocks with errors.</guideline>
<guideline>Execute all code blocks immediately after writing them to validate correctness.</guideline>
</code_execution_guidelines>
<mathematical_formatting>
<format>Present the final answer in LaTeX format, enclosed within '\boxed{}' without units.</format>
<format>Use 'pi' and 'Rational' from Sympy for pi and fractions, simplifying them without converting to decimals.</format>
</mathematical_formatting>
</instructions>
</system>
<syntax>
<problem_structure>
<problem_definition>
</problem_definition>
<solution_approach>
</solution_approach>
<preliminary_contents>
</preliminary_contents>
<hints>
</hints>
<intermediate_steps>
</intermediate_steps>
<final_solution>
<solution_sketch>
</solution_sketch>
<code_for_solution>
</code_for_solution>
<final_answer>
</final_answer>
</final_solution>
</problem_structure>
</syntax>
```

**Figure 15: The system meta prompt for MP-CR.**

```markdown
As one of the most distinguished mathematicians, logicians, programmers, and
AI scientists, you possess an unparalleled mastery over Arithmetic, Combinatorics, Number
Theory, Probability Theory, Algebra, Analysis, and Geometry. You are not only intelligent
and rational but also prudent and cautious. You are willing to write and execute Python
code. Let's approach each problem step by step, take a deep breath, and articulate our thoughts in as much detail as possible.

<system>
You will be presented with a mathematical problem, denoted as `MathP`. Before diving into
the solution, lay down some foundational preliminary contents and hints. Then, generate a series
of intermediate questions that pave the way to the final answer of `MathP`. For each question,
sketch a preliminary answer, execute the corresponding code (remember to use `from sympy import *`),
derive the output, and then finalize your answer. This forms a [Question] -> [AnswerSketch]
-> [Code] -> [Output] -> [Answer] sequence.

## System Instructions for Mathematical Problem-Solving

### Objective

Solve complex mathematical problems with code feedback from a Python environment.

### Key Priorities

1. **Hints:** Generate useful hints to guide the problem-solving process.

2. **Intermediate Questions:** Decompose the problem into manageable parts and solve each using code feedback.

### Code Execution Guidelines

1. **Import Libraries:** Always import necessary libraries in every code block.

2. **Immediate Execution:** Execute all code blocks immediately to ensure correctness; call the code interpreter after writing each block.

3. **Immediate Feedback:** Ensure immediate code execution for every question posed.

### Mathematical Formatting

1. **Final Answer:** Present the final answer to the original problem in LaTeX format, enclosed within `\boxed{}`, and without any units.

2. **Constants and Fractions:** Use the `pi` symbol and the `Rational` class from Sympy to represent pi and fractions. Simplify all fractions and square roots without converting them to decimals.
   </system>

---
```

# Reproducibility

We release verbatim artifacts for all prompting components in the Supplement, and include core strings in Appendix 9: the single task-agnostic meta-meta-prompt, task descriptors, RMP-generated meta-prompts for MATH/GSM8K/24-game, and baseline CoT prompts. Decoding parameters (temperature, top-p, max tokens, stop sequences) and inference stack details (vLLM versions and hardware) are enumerated to facilitate replication. Evaluator code includes SymPy equivalence and formatting normalization.

# Limitations and Scope

Our experiments are intended as proof-of-concept. We do not claim monotone accuracy gains with recursion or universality across tasks/models. Sensitivity to meta-prompt templates, recursion depth, proposer/executor swaps, and model scale (including reasoning-tuned models such as DeepSeek-R1) is left for future work. The current evaluation focuses on math/problem-solving benchmarks and does not include conversational LM-Eval settings; extending to those domains is orthogonal and promising but untested here. Computationally, RMP incurs a one-time offline refinement cost; benefits appear primarily when prompts are reused across many instances (batched settings).

#### Comparison to Program-of-Thought (PoT).

Zero-shot PoT is code-first: it executes tool calls explicitly to ground reasoning. MP is structure-first: it enforces typed schemas and compositional sections without mandating execution. The methods are complementary: PoT is advantageous when faithful execution is available and cheap; MP is advantageous when the token budget is tight and structural guarantees (format/type) drive reliability. Hybrid designs, such as schema-first prompts that invoke tools on selected sections, are a promising direction.

# Multi-Modal Meta Prompting

The structured nature of Meta Prompting, grounded in the principles of type theory, provides a robust framework for extending foundation models to multi-modal settings. Just as type systems in programming ensure that different data types are handled correctly, a meta prompt enforces a clear, syntactic structure on the AI's inputs and outputs. This is particularly valuable when interacting with diverse data like text, images, audio, or even physical sensors, as it minimizes ambiguity and ensures that the model interacts with tools and data in a consistent, predictable manner.

This "typed" approach is essential for complex, real-world applications where an AI must process and synthesize information across different modalities. For example, an XML-based meta prompt can define a rigid schema that an LLM must follow, specifying slots for different types of reasoning steps and data.

**Figure 16: An example of a meta prompt using an XML schema.**

```xml
<system>
  <description>
    As one of the most distinguished mathematicians, logicians, programmers, and AI
    scientists, you possess an unparalleled mastery over various mathematical domains.
    You approach problems methodically, with detailed articulation and Python code execution.
  </description>
  <instructions>
    <objective>
      Automatically configure solutions to complex mathematical problems with Python code execution.
    </objective>
    <key_priorities>
      <priority>Generate useful hints for solving the problem.</priority>
      <priority>Craft intermediate questions that break down the problem, solving them with code, following the sequence: [Question] -> [AnswerSketch] -> [Code] -> [Output] -> [Answer].</priority>
      <priority>Automatically configure solutions where applicable.</priority>
    </key_priorities>
    <code_execution_guidelines>
      <guideline>Import necessary libraries in all code blocks.</guideline>
      <guideline>Maintain variable inheritance across code blocks, excluding those with errors.</guideline>
      <guideline>Execute all code blocks immediately after writing to validate them.</guideline>
    </code_execution_guidelines>
    <mathematical_formatting>
      <format>Present the final answer in LaTeX format, enclosed within '\boxed{}' without units.</format>
      <format>Use 'pi' and 'Rational' from Sympy for pi and fractions, simplifying them without converting to decimals.</format>
    </mathematical_formatting>
  </instructions>
</system>
<syntax>
  <problem_structure>
    <problem_definition>
      </problem_definition>
    <preliminary_contents>
      </preliminary_contents>
    <hints>
      </hints>
    <intermediate_steps>
      </intermediate_steps>
    <final_solution>
      <solution_sketch>
        </solution_sketch>
      <code_for_solution>
        </code_for_solution>
      <final_answer>
        </final_answer>
    </final_solution>
  </problem_structure>
</syntax>
```

This structure enforces type-like constraints on the output, making it ideal for frameworks like Guidance [guidance] and for extension to multi-modal data.

## A Framework for Multi-Modal Interaction

Extending Meta Prompting to a multi-modal context involves defining a schema that can handle varied data formats while integrating them coherently. The primary challenges are data representation and inter-modal synthesis. A multi-modal meta prompt addresses this by creating explicit, typed "slots" for different data streams.

For instance, a task might require the AI to analyze a 3D model ('.obj'), listen to an accompanying audio description ('.mp3'), and read a textual specification ('.txt'). A meta prompt can structure this complex input, guiding the model to process each modality in a specific order and synthesize the information to generate a cohesive output. Figure 17 illustrates how such a schema can be conceptualized.

**Figure 17: A conceptual schema for a multi-modal meta prompt.**

```xml
<task_schema>
    <input_slots>
        <data type="image/png" name="problem_diagram">
            </data>
        <data type="audio/mp3" name="verbal_instructions">
            </data>
        <data type="model/obj" name="object_model">
            </data>
    </input_slots>
    <output_schema>
        <synthesis type="text/markdown" name="analysis_summary">
            </synthesis>
        <result type="video/mp4" name="solution_animation">
            </result>
    </output_schema>
</task_schema>
```

This schema defines typed slots for various input modalities and specifies the expected structure and types for the output, enabling complex inter-modal reasoning.

By defining a clear, typed structure for both inputs and outputs, this framework enables models to perform sophisticated cross-modal analysis---for example, correlating a visual diagram with textual instructions. This structured approach provides a scalable and reliable foundation for building the next generation of versatile, multi-modal AI systems.
