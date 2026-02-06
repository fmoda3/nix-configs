# Abstract

Foundation models, such as Large language Models (LLMs), have attracted significant amount of interest due to their large number of applications. However, when handling tasks involving repetitive sub-tasks and/or deceptive contents, such as arithmetic calculation and article-level fake news detection, simple instructional prompts suffer from inaccurate responses. Existing works show that more complicated prompting strategies, such as Chain-of-Thoughts and Least-to-Most, can unlock LLM's powerful capacity in diverse areas. Recent researches reveal that simple divide-and-conquer prompting strategy, i.e. simply dividing the input sequence to multiple sub-inputs, can also substantially improve LLM's performance in some specific tasks such as misinformation detection. In this paper, we aim at examining the utility of divide-and-conquer prompting strategy and answer on which kind of tasks this strategy gets advantages. Specifically, we provide a theoretic analysis to divide-and-conquer prompting strategy and help us identify the specific tasks where DaC prompting can bring performance boost with theoretic guarantee. We then present two cases (**large integer arithmetic and fact verification**) where experimental results aligns with our theoretic analysis.

# Introduction

Large language models (LLM) based on the Transformer architecture have led to major breakthroughs in natural language processing and other related fields in artificial intelligence [brown2020language; radford2019language; touvron2023llama]. State-of-the-art general-purpose language models have demonstrated remarkable advancements in various domains, including question answering, graph learning, reading comprehension, text generation, and machine translation [chen2023exploring; tan2023evaluation; hendy2023good; mao2023gpteval; zong2023solving]. These developments paves the way towards general-purpose problem solvers [bubeck2023sparks].

However, as pointed out in [wei2022chain], significant challenges arise when scale-up models are applied to tasks involved with long solution paths, such as those requiring mathematical or knowledge reasoning. A series theoretic works attribute this challenge to **Parallelism Tradeoff** [merrill-sabharwal-2023-parallelism], a fundamental limitation of Transformers. Specifically, unlike Recurrent Neural Network whose computational depth is linear to the input sequence length (i.e., the depth is `latex $O(n)$ `, where `latex $n$ ` is the input sequence length), Transformer does not contain any recurrent structure. Such design, while achieving superior parallelizability than RNN, makes Transformers suffer from limited expressive power. Merrill and Sabharwal proved that the expressive power of fixed-depth log-precision Transformer, which is very close to the most commonly applied Transformer architecture for LLMs, is bounded by constant-depth logspace-uniform threshold circuits. Thus, they fail to accurately tackle the tasks requiring long solution paths.

[IMAGE: Example_toy.pdf - An illustrative example of hallucination detection with entangled problem solving (i.e., directly forward all inputs into the LLM) and divide-and-conquer problem solving (i.e., divide the problem inputs to parallel sub-tasks and tackle them parallelly). The sentence marked with red back font in the material is the evidence that contradict with the first claim in summary (marked with red font).]

To address this challenge, carefully designed prompting strategies have been developed to tackle tasks that requires stronger expressive power [feng2023towards]. A series of works focus on prompting the LLM with instructions or context samples to output the intermediate steps that derive the final answer in an autoregressive manner, such as Chain-of-Thoughts (CoT) [wei2022chain; wang2022self; zhou2022least; chen2023hallucination]. Some works further apply programs to guide LLM to strictly follow designated reasoning steps [yao2023tree]. Theoretically, these prompting strategies convert the role of Transformer from the complete problem solver to a sub-problem solver in a dynamic programming or tree searching algorithm [merrill2023expresssive]. In this way, these prompting strategies expand the expressive power of the LLMs and successfully improve the reasoning and searching of LLMs [feng2023towards].

In contrast to such methods that apply instruction, context sample or program to decompose the whole reasoning process to multiple intermediate steps, in some tasks, researchers report that LLM's performance can also be boosted by simply **dividing the input sequences to multiple sub-inputs** and then merge the responses from LLMs on all sub-inputs. For example, Cui et al. propose that in automated evaluation, LLM's performance can be further boosted by first dividing the input text to sentences and then evaluating them one by one. Intuitively, this paradigm benefits the tasks in a way similar to human brains, especially when the tasks are too hard or too complex. For example, when reviewing a long academic paper, some reviewers produce low-quality reviews [garcia2021quality; tennant2020limitations; cortes2021inconsistency] containing hallucination-like **intermediate errors**, such as pointing out some 'missing baselines' that have already been sufficiently discussed by authors. To avoid such mistakes, experienced reviewers usually think slowly [kahneman2011thinking] to follow a **Divide-and-Conquer** paradigm to handle this task. Specifically, they decompose the paper review as examinations of multiple central opinions and then retrieve corpus to verify them respectively.

However, unlike Chain-of-Thoughts whose advance in expressive power is supported by theoretic analysis [feng2023towards], the performance boost from Divide-and-Conquer paradigm is lack of rigorous theoretic support. As a result, we are not aware of the conditions under which the Divide-and-Conquer paradigm can acquire more accurate answers. To tackle this challenge, in this paper, we aim at understanding the utility of DaC prompting. More specifically, we attempt to answer the following two research questions:

1. **RQ1: Compared to straightforward instructional prompting, does DaC have theoretically guaranteed advantages similar as CoT and its variants?**

2. **RQ2: Compared CoT and its variants, what utility and limitations does DaC have?**

To answer these questions, we first provide a theoretic paradigm that can help us analyze how divide-and-conquer strategy expand the expressive power of fixed-depth log-precision Transformer on a given task. In this way, we provide a framework that can provide theoretic guarantee to DaC paradigm in various tasks. In this way, we present some conditions under which DaC have advantages compared to other prompting strategies. We then empirically evaluate DaC prompting and representative baselines on tasks that satisfy the proposed conditions and are challenging to existing prompting strategies even on state-of-the-art LLMs: Large Integer Multiplication, Hallucination Detection, Article-level Fact Verification [cheng-zhang-2023-analyzing; li2023halueval; wadden-etal-2020-fact; hu2023bad; wu2023ragtruth]. These tasks either require very long reasoning paths (e.g. large integer multiplication) or contain deceptive contents (e.g. hallucination detection and fact verification), making existing methods like Chain-of-Thought prompting prone to intermediate errors. Our experimental results show that the proposed method outperforms the baselines on all three tasks, which supports our theoretic analysis.

[IMAGE: Thoughts.jpg - The comparison between DaC and the existing methods for prompting. The ellipse marks represent sub-tasks, the right-angled rectangles represent sub-task solutions, and the rounded rectangles represent intermediate steps that entangle sub-task and sub-solutions. The different shades in Tree of Thoughts (subfigure D) indicate the rates of different search directions. In CoT (Chain-of-Thoughts), CoT-SC and ToT, the Large Language Models must simultaneously generating and resolving sub-tasks. Least-to-Most (also Decomposed Prompting) disentangle sub-task generation and resolution. However, its sub-task resolution and resolution assembly process are intertwined as it sequentially attach new sub-tasks onto the previous resolution. Different from them, DaC totally disentangle the sub-task generation, sub-task resolution, and resolution assembly process.]

# Related Work

## Expressive Power of Transformer

As discussed in previous works [merrill-sabharwal-2023-parallelism; feng2023towards], the expressive power of fixed-length log-precision transformers, which are widely applied in modern Pre-trained Large Language Models, is actually much more limited than people's expects. Merrill and Sabharwal give a theoretic proof that the expressive power of fixed-length log-precision transformers is upper-bounded with `latex ${\sf TC^0}$ `. Feng et al. further extend their analysis to explain that a lot of common problems exceed the expressive power of fixed-length log-precision transformers. Such results explains why the powerful LLM may make some ridiculous mistakes and how CoT improve the performance.

## Prompting Strategies of LLM

In this sub-section, we introduce the existing prompting and discuss their limitations and drawbacks. Following the notations in [yao2023tree], we denote the Large Language Models with parameter `latex $\theta$ ` as `latex $p_\theta$ ` and use lower case letters `latex $x,y,z$ ` to denote input sequence, result, and intermediate steps, respectively.

**Input-Output (IO) Prompting** is the standard prompting strategy that attach input `latex $x$ ` with instructions and/or few-shot in-context-learning examples to acquire a prompt, denoted as `latex ${\sf prompt}(x)$ ` [yao2023tree]. The LLM takes `latex ${\sf prompt}(x)$ ` as input and predict result, i.e. `latex $y \sim p_\theta(y|{\sf prompt}(x))$ `.

**Chain-of-Thought (CoT) Prompting** [wei2022chain] aims at simulating human's thinking process that handles complicated task (e.g. combinational reasoning and mathematical calculation) in a step-by-step manner. More specifically, the LLM is guided to output a series of intermediate steps `latex $z_1,z_2,...,z_n$ ` (also known as _thoughts_) autoregressively, i.e. `latex $z_i\sim p_\theta(z_i|{\sf prompt}(x),z_1,...,z_{i-1})$ `. Then the LLM output the prediction of result `latex $y$ ` based on the _thoughts_, i.e. `latex $y\sim p_\theta(z_i|{\sf prompt}(x),z_1,...,z_n)$ `.

**Exploration-of-Thought (EoT) Prompting** and **Program-guided Prompting** are two variants of CoT. EoT includes a series of CoT's variants, such as Self-consistency with CoT (CoT-SC) prompting [wang2022self] and Tree-of-Thoughts (ToT) prompting [yao2023tree], which aim at addressing the limitation of CoT in exploration. Their common central idea is to generate multiple chains of thought through sampling or proposing prompting and then ensemble them to acquire a final prediction. Program-guided Prompting aims at controlling the LLM's generation process with symbolic programs or pre-defined procedure [zhu2022solving; jung2022maieutic; zhou2022least; khot2022decomposed; creswell2022faithful; gao2023pal]. Among them, the Least-to-Most (LtM) Prompting [zhou2022least] and Decomposed Prompting [khot2022decomposed] are close to this work. They are the earliest attempts that explicitly prompt the LLM to decompose the task as a series of sub-tasks and sequentially tackle them. LtM prompt a LLM to iteratively raise sub-tasks and sequentially solve them to acquire the final resolution. Decomposed Prompting can regarded as a upgraded version of LtM. It introduces special notations into the prompt to represent program states and thus can call itself (i.e., recursion) or other modules (i.e., hierarchical decomposition), endowing it stronger expressive power. Such design increased the compositional generalization ability of LLMs in different areas, such as symbolic manipulation and multi-hop QA [khot2022decomposed].

The aforementioned CoT and EoT families incorporate LLM with stronger expressive power than IO prompting. However, a critical issue of them is that, they could miss or ignore some important intermediate steps or contents [liu2023trustworthy]. This problem is even worse when we are handling tasks involved with long input (e.g. long documents and large numbers). Typical examples include large number arithmetic calculation and fact verification in long documents. Compared to them, Least-to-Most prompting and Decomposed Prompting introduce explicit task decomposition to enumerate sub-tasks. However, their task decomposers are based on multi-round conversation or question-answering, which navigate the LLM through the deceptive content's flow sequentially, and propagate the hallucination/deception in the contexts [dziri2024faith; yang2023can], leading to decreased performance.

# Preliminary of Divide-and-Conquer Prompting

In this section, we summarize and formalize **Divide-and-Conquer prompting strategy**. Divide-and-Conquer prompting strategy consists of three distinct stages: task decomposition stage, sub-task resolution stage, solution merge stage. In task decomposition stage, the LLM is prompted to explicitly decompose the task as a series of parallel homogeneous sub-tasks with smaller problem sizes (e.g. divide a long paragraph to sentences). Such design avoids the multi-round conversation or question-answering in LtM and Decomposed Prompting, making the model less prone to deception. After that, in sub-task resolution stage, the LLM is prompted to provide the solutions for every sub-task. Finally, in the solution merge stage, the LLM is prompted to assembly the solutions of subtasks and acquire the final answer. To tackle tasks of different sizes, Divide-and-Conquer prompting strategy can be divided to two variants: Single-Level DaC Solver and Multi-Level DaC Solver.

**Algorithm 1: Single-Level Divide-and-Conquer Solver T(S,a,t,L,f)**

```
REQUIRE: Input Sequence S, Prompt m (for solution merge), Prompt t (for sub-task tackling), Prompt d (for task decomposition), LLM L
ENSURE: Results of the task on input sequence S
1. {S_1,S_2,...,S_k} <- L(d,S)
2. Result <- empty
3. FOR i=1,2,...,k
4.   Result <- Result + [SEP] + L(t,S_i)
5. ENDFOR
6. Return L(m,Result)
```

Single-level Divide-and-Conquer Solver decomposes the task in one call to the LLM, which expands the original task as a tree of one level. The advantage of this variant is its simplicity and efficiency. However, when the original input is too long, single-level Divide-and-Conquer Solver may acquire sub-tasks with large problem sizes that will still trigger intermediate errors. In such a case, following [khot2022decomposed], we can recursively expand the task as a multi-level tree. More specifically, we repeat the aforementioned steps to further divide the sub-tasks hierarchically until they are easy enough to be handled by the LLM. This can be done through a recursion program as presented in Algorithm 2.

**Algorithm 2: Multi-Level Divide-and-Conquer Solver Recursion T(S,m,t,d,f,n,L)**

```
REQUIRE: Input Sequence S, Problem Size Metric Function f(.) (a function that measure the problem size), hyper-parameter w, Prompt m (for merge), Prompt t (for sub-task tackling), Prompt d (for task decomposition), Large Language Model L
ENSURE: Results of the task on input sequence S
1. S_1,S_2,...,S_k <- L(d,S)
2. Result <- empty
3. FOR i=1,2,...,k
4.   IF f(S_i) > w THEN
5.     Result <- Result + [SEP] + T(S_i, m,t,d,f,w,L)
6.   ELSE
7.     Result <- Result + [SEP] + L(t,S_i)
8.   ENDIF
9. ENDFOR
10. Return L(m,Result)
```

# Main Theoretic Results

In this section, we provide theoretic analysis to the utility and limitations of the Divide-and-Conquer prompting. In the first subsection, we provide a comparison of IO prompting (common fixed-length instructional prompting) and DaC prompting in expressive power perspective. This part answers the first research question: the expressive power of IO prompting is a subset of DaC prompting. In the second subsection, we provide a comparison between Chain-of-Thoughts and DaC prompting in expressive power. Our comparison suggests that, although the expressive power of DaC prompting is a subset of Chain-of-Thoughts, for tasks satisfying specific conditions, DaC prompting can solve the problem with lower average context window length when decoding the tokens. Such property is empirically proved to be helpful for reducing the intermediate error and thus boost the performance.

## Divide-and-Conquer vs. IO Prompting

We show that the expressive power of Divide-and-Conquer is stronger than IO Prompting:

**Theorem 1.** _We denote the set of problems that a fixed-precision transformer with fixed-length IO prompting can tackle as S(IO). Similarly, we denote the set of problems that a fixed-precision transformer with DaC prompting can tackle as S(DaC). Then we have the following results:_

```latex
$$S(IO) \subset {\sf TC^0} \subseteq {\sf NC^1} \subseteq S(DaC)$$
```

**Proof Sketch:** The conclusion that `latex $S(IO) \subset {\sf TC^0}$ ` is a corollary of the main results in [chiang2023tighter]. In this paper, we mainly focus on proving `latex ${\sf NC^1} \subseteq S(DaC)$ `. Specifically, we exploit 2-color Binary Subtree Isomorphism (2-BSI) problem for the proof. In [jenner2003completeness], 2-BSI problem is proved to be an `latex ${\sf NC^1}$ `-complete problem. Its definition is:

**Definition 1.** **\*2-color Binary Subtree Isomorphism problem** is that, given a pattern 2-color binary tree `latex $t_p$ ` and a base 2-color binary tree `latex $t_b$ `, a solver is required to judge whether the pattern tree is isomorphic to a sub-tree of `latex $t_b$ `\*

In [jenner2003completeness], the authors pointed out that the encoding of the problem will influence the hardness of the problem. In this paper, we focus on pointer list encoding of 2-BSI. Detailed information about the pointer list encoding of 2-BSI can be found in Appendix. For pointer list encoding of 2-BSI, we have the following theorem:

**Theorem 2.** _There exists a log-precision transformer with fixed depth L and hidden dimension d that can solve the 2-BSI of any size with fixed-length prompt m (for merge), t (for sub-task tackling) and d (for task decomposition)._

**Proof Sketch:** The detailed proof is provided in the Appendix. Here we give a brief flow of the proof. To prove this theorem, we first show an algorithm that can solve the problem with divide-and-conquer strategy. Then we prove that there exists a log-precision transformer with fixed depth L and hidden dimension d that can express the modules in the algorithms with different but fixed-length prompts. In this way, we can prove the theorem.

With the above theorem, we can prove that `latex ${\sf NC^1} \subseteq S(DaC)$ `, which finishes the proof. With this theoretic results, we can answer the **RQ 1**:

_Compared to IO prompting, DaC have theoretically guaranteed advantages in expressive power._

## DaC vs. CoT

In this section, we compare Divide-and-Conquer with Chain-of-Thoughts in order to understand the utility and limitation of DaC prompting. The limitation of DaC prompting is that its expressive power is a subset of CoT prompting:

**Proposition 3.** _We denote the set of problems that a fixed-precision transformer with DaC prompting can tackle as S(DaC). Similarly, we denote the set of problems that a fixed-precision transformer with CoT prompting can tackle as S(CoT) Then we have the following results:_

```latex
$$S(DaC)\subseteq S(CoT)$$
```

_Proof._ The proof of this proposition is very straightforward. For any problem that DaC can solve, we can concatenate all outputs of LLM in dividing, tackling and merging as a sequence. Then we can prompt LLM with CoT to output this sequence. Thus, the problem set that DaC can resolve is a subset of CoT.

The limitation revealed by the above theorem shows that compared to CoT, the appliance scope of Divide-and-Conquer is limited. However, by analyzing the average decoding context window size, we show that on specific tasks, divide and conquer can reduce the problem complexity:

**Definition 2.** **\*Decoding Context Window Size:** In auto-regressive decoding, each token is decoded from a window that covers all previous tokens. We denote the length of the window as the Decoding Context Window Size of the token.\*

**Proposition 4.** _Suppose that a task contains k sub-tasks, each of which does not rely on the answers of other sub-tasks. We define such sub-tasks as **parallel sub-tasks**. If an LLM tackle these sub-tasks sequentially with CoT, then the average decoding context window size of the sub-tasks' resolution will be_ `latex $C+\frac{\sum_{i=1}^kr_i-1}{2}$ `_, where_ `latex $r_i$ ` _is the length of the response to the i-th sub-task and C is the length of input context. If we tackle them parallely with DaC, then the average decoding context window size of the sub-tasks' resolution will be_ `latex $C+\sum_{i=1}^k\frac{(r_i-1)^2}{2\sum_{j=1}^kr_j}<C+\frac{\sum_{i=1}^kr_i-1}{2}$ `_._

The above proposition shows that when task contains a large amount of **parallel sub-tasks**, DaC is more helpful for reducing the average decoding context window size than CoT. Existing works have empirically showed that long decoding context window will propagate intermediate errors and thus increase the probability of generating hallucination [yang2023can]. Thus, we can acquire a conclusion that DaC is competitive on tasks that contain a large amount of **parallel sub-tasks** and are bothered by intermediate errors and hallucination. With these theoretic results, we can answer the **RQ 2**:

_Compared to CoT and its variants, DaC prompting's expressive power is weaker. However, on tasks containing a large amount of **parallel sub-tasks**, DaC is more helpful._

## Advantages of DaC

The above analysis answer the two research questions that we proposed. By summarizing these two answers, we can acquire the two conditions such that when a task simultaneously satisfied both conditions, DaC bring performance boost:

- **Condition 1:** _the task is harder than S(IO), such as_ `latex ${\sf TC^0}$ `_-complete problems and_ `latex ${\sf NC^1}$ `_-complete problems._

- **Condition 2:** _the task contains a large amount of parallel sub-tasks and is bothered by hallucinations or intermediate errors._

In Table 1, we present some sample tasks that satisfied the conditions. Also, we list some tasks that typically do not satisfy the conditions. This is helpful for guiding prompt engineering.

**Table 1: Example tasks that satisfy and do not satisfy the conditions**

| Applicable Tasks       | Non-Applicable Tasks |
| ---------------------- | -------------------- |
| Integer Multiplication | Integer Addition     |
| Fact Verification      | Multi-round QA       |
| Consistency Evaluation | Planning             |

# Experiments

## Case 1: Long Integer Arithmetic

In this case, we consider two tasks in long integer arithmetic: **Multiplication**, which satisfy the conditions we proposed, and **Addition**, which does not satisfy the first condition (Multiplication is a `latex ${\sf TC^0}$ `-complete problem and can be divided to multiple parallel sub-tasks, while Addition is in S(IO) [barcelo2023logical]). Our experiment results will show that DaC prompting bring performance boost on multiplication and does not bring boost on integer addition.

[IMAGE: edit_distance_mul.pdf - Edit distance of DaC and baseline prompting strategies on GPT-3.5 and GPT-4 for Multiplication.]

[IMAGE: edit_distance_add.pdf - Edit distance of DaC and baseline prompting strategies on GPT-3.5 and GPT-4 for Addition.]

**Table 2: Performance of different prompting methods on HaluEval dataset**

| Strategies         | GPT-3.5-Turbo F1 | GPT-3.5-Turbo Acc | GPT-3.5-Turbo Prec | GPT-3.5-Turbo Recall | GPT-4 F1  | GPT-4 Acc | GPT-4 Prec | GPT-4 Recall |
| ------------------ | ---------------- | ----------------- | ------------------ | -------------------- | --------- | --------- | ---------- | ------------ |
| IO-prompting       | 61.69            | 61.27             | 62.11              | 61.28                | 64.07     | 72.66     | **93.41**  | 48.76        |
| Chain-of-Thoughts  | 46.85            | 64.26             | **91.36**          | 31.50                | 71.05     | 76.10     | 90.08      | 58.66        |
| CoT-SC             | 47.70            | 64.25             | 88.83              | 32.60                | 71.39     | 76.36     | 90.41      | 58.98        |
| Tree-of-Thoughts   | 70.40            | 59.91             | 55.83              | **95.34**            | 69.41     | 71.73     | 75.53      | 64.28        |
| Least-to-Most      | 56.43            | 64.91             | 74.42              | 45.44                | 72.51     | 77.11     | 90.74      | 60.38        |
| Divide-and-Conquer | **74.84**        | **75.55**         | 77.41              | 72.03                | **76.92** | **78.99** | 85.36      | **70.01**    |

**Setup of baselines and DaC:** In this task, our baselines include IO prompting, Chain of Thought (CoT), CoT-SC, Least-to-Most (LtM), and Decomposed Prompting (DeP). Tree-of-Thoughts is not applicable. This is because that multiplication is deterministic calculation without requiring search in a tree. For DaC, we apply Multi-Level Divide-and-Conquer program-guided solver.

**Results:** Experimental results are shown in Figures 3 and 4. As we can see, for integer addition which does not satisfy our proposed conditions, the performance of DaC, CoT and its variants does not significantly outperform IO prompting for both ChatGPT-3.5 and 4. However, for integer multiplication which satisfy our proposed conditions, under all settings, our proposed prompting strategy outperform all the baselines. This phenomenon indicate that our proposed conditions are useful for recognizing the tasks where DaC is more powerful.

## Case 2: Fact Verification of Long Text

In the previous section, we show that for arithmetic tasks, our proposed conditions are discerning to the tasks where divide-and-conquer has advantages. In this section, we further present our conditions can be applied to natural language tasks. Specifically, we present the performance of baselines and Divide-and-Conquer on fact verification of long text. In this task, the LLM is required to whether a long corpus is aligned with base knowledge. This task **satisfied the proposed two conditions**. For the first condition, we can reduce a 2-BTI problem to fact verification by describing the two trees with natural language. In this way, we can convert the trees to two paragraphs and what we need to do is to ask the LLM to judge whether the two paragraphs are aligned or not. For the second condition, since we are tackling long text, then each sentence can be regarded as parallel sub-tasks. We select two benchmarks of fact verification: **Fact-Verification for Hallucination Detection** and **Fact-Verification for Misinformation Detection**

### Hallucination Detection

Although Large Language Models have achieved impressive performance on various NLP tasks, they are bothered by hallucination problem [manakul2023selfcheckgpt], especially when the generated content or the input context is too long for the user to have a thoroughly review [zhang2023siren]. In this paper, we focus on evaluating the performance of different strategies in guiding LLM to recognize inconsistency between given context and model response with hallucination.

**Table 3: Performance of different prompting methods on SciFact dataset**

| Strategies         | GPT-3.5-Turbo F1 | GPT-3.5-Turbo G-M | GPT-3.5-Turbo Prec | GPT-3.5-Turbo Recall | GPT-4 F1  | GPT-4 G-M | GPT-4 Prec | GPT-4 Recall |
| ------------------ | ---------------- | ----------------- | ------------------ | -------------------- | --------- | --------- | ---------- | ------------ |
| Io-Prompting       | 72.12            | 72.77             | 83.22              | 63.64                | 69.15     | 71.77     | 94.44      | 54.55        |
| Chain-of-Thoughts  | 56.09            | 60.64             | 90.48              | 40.64                | 74.03     | 75.79     | 94.21      | 60.96        |
| CoT-SC             | 56.83            | 61.44             | **91.67**          | 41.18                | 70.09     | 73.45     | **100.0**  | 53.95        |
| Tree-of-Thoughts   | 69.91            | 73.30             | 53.74              | **100.0**            | 77.34     | 78.00     | 88.89      | 68.45        |
| Least-to-Most      | 54.08            | 54.15             | 51.46              | 56.99                | 73.56     | 74.25     | 85.21      | 64.71        |
| Divide-and-Conquer | **76.88**        | **77.13**         | 83.65              | 71.12                | **81.11** | **81.24** | 76.67      | **86.10**    |

**Task Setup:** We use the HaluEval-Summary dataset. It is one of the three datasets in HaluEval benchmark for hallucination detection, which contains the hallucination generated by ChatGPT-3.5. HaluEval-Summary have the longest context and generated contents among all three tasks in this benchmark [li2023halueval]. Thus, detecting hallucination on this dataset requires repeatedly verify each sentence in the response, making standard prompting strategies acquire the worst accuracy across all three tasks. We report the Accuracy, F1 score (the hallucination pairs are positive samples), Precision and Recall.

**Setup of baselines, ablation variants and DaC:** In this task, our baselines include IO prompting, Chain of Thought, CoT-SC, Tree-of-Thoughts Least-to-Most, and Decomposed Prompting. In this task, the sub-tasks are verifying fragments of the summary, which are homogeneous and do not require recursion. In such a setting, Decomposed Prompting is equivalent to LtM. For this task, we apply single level Divide-and-Conquer solver to decompose the summary to multiple sentences, handle them separately and then merge the conclusions of all sentences.

**Results:** Experimental results are shown in Table 2. For both GPT-3.5 and GPT-4, our proposed prompting strategy outperform the baselines, presenting the advantage of DaC. More specifically, compared to IO-prompting, DaC achieved better performance in general, indicating the advantage brought by stronger expressive power. Meanwhile, compared to CoT and CoT-SC results, DaC clearly achieved much better recall. Tree-of-Thoughts, benefited by its searching ability, acquired significantly better recall score compared to other baselines. However, its significantly lower precision substantially harm its overall performance and leads to accuracy that is even worse than standard IO-prompting. In contrary, DaC carefully checked all sentences, locate the one containing factual error and merge the answers.

### Misinformation Detection

The increasing abuse of misinformation toward manipulating public opinions on social media has been observed in different areas, such as healthcare (e.g. the recent COVID-19 pandemic) [sharma2020coronavirus; sharma2022covid]. This threat is increasingly serious due to LLM's capacity in content generation [li2023you; weidinger2021ethical; zhang2022counterfactual]. This challenge raise the importance of fact-verification, which aims at judging the authenticity of an article based on a collection of evidence from verified source [whitehouse2022evaluation; zhang2023towards]. In this experiment, we present that DaC can outperform other baselines in fact-verification involved with news article.

**Task Setup:** In this experiment, we mainly adopt SciFact dataset [wadden-etal-2020-fact]. In SciFact dataset, each sample is a pair of news and evidence, where the evidence is the abstract of a peer-reviewed paper and the news is a sentence of claim. To better simulate the real-world scenario where news on social media usually appears as an paragraph of post, following Chen and Shu, we generate a dataset of paragraph-level misinformation based on SciFact dataset. Specifically, for a given claim, we apply ChatGPT-4 to extend the claim as an article based on the evidence. For this task, similar as hallucination detection, we apply single level Divide-and-Conquer solver to decompose the news article to multiple sentences, handle them separately and then merge the conclusions of all sentences. Also, the baselines in this experiments are the same as Hallucination Detection. The evaluation metrics includes F1 score, G-Mean score (geometric mean of precision and recall), Precision and Recall. We do not apply accuracy as the positive and negative classes are not balanced.

**Results:** Experimental results are shown in Table 3. Notably, GPT-3.5 incorporated with our proposed prompting strategy even outperform the performance of GPT-4 incorporated with IO-prompting, Least-to-Most, CoT and CoT-SC, which have significantly lower recall scores, indicating their proneness to deception. Only Tree-of-Thoughts, which is benefited by its advantage in exploring various options, acquired the best results among all baselines, but is still defeated by DaC. Moreover, as we can see, for GPT-4 the performance of CoT-SC is even worse than CoT, which is supposed to be a specific case of CoT-SC without exploration. These results suggests that, when facing deceptive contents generated on purpose, existing works' improvement may not be robust.

# Conclusions

In this paper, we analyze the utility and limitations of divide-and-conquer prompting strategy. We first provide theoretic analysis to Divide-and-Conquer prompting and compare it with representative prompting strategies. Based on these theoretic results, we summarize two conditions under which a task is suitable for Divide-and-Conquer prompting. After that we present empirical results that validated our theoretic analysis.

# Appendix

## Discussions and Limitations

In summary, the proposed method has following advantages:

**Comparison with IO-Prompting: Superiority in Expressive Power** As we proved in Section 4, Compared to IO-prompting, DaC has stronger expressive power and thus can solve harder problems.

**Comparison with CoT and EoT: Disentangling the task decomposition and task resolution** Compared to the prompting family of CoT and EoT, DaC explicitly separate the task decomposition stage and task resolution stage. Therefore, we can acquire explicit decomposed sub-task rather than intermediate thoughts proposed during decoding. Consequently, we can explicitly enumerate all sub-tasks output by the decomposition module and avoid the model from missing important sub-tasks.

**Comparison with LtM and Decomposed Prompting: Parallel Sub-task Handler and Sequential Sub-task Handler** Similar as DaC, some program-guided prompting like LtM and Decomposed Prompting also explicitly separate the task decomposition stage and task resolution stage. However, they are mainly designed for multi-step reasoning for complex tasks. Thus, they sequentially tackle the sub-tasks and assembly the resolutions. As a result, they tend to follow the flow of the deceptive contents, leading to proneness to deceptive content.

Although DaC surpasses the baselines on the proposed tasks, it still has some **limitations**. The first issue is that the appliance scope of DaC is still limited. More specifically, CoT, EoT, LtM and DaC are based on different algorithmic paradigms, learning to different Appliance Scopes. As pointed out by Feng et al., CoT and LtM can be considered as a neural **dynamic programming** algorithm. Thus, CoT is more suitable for tasks that can be bridged to dynamic programming, such as multi-step question answering. Differently, EoT is based on **exploration and search**, which is more suitable for planning and search, such as Game of 24 [yao2023tree]. DaC is based on **Divide-and-Conquer algorithm**. Thus, it is more suitable for tasks that can be decomposed to a series sub-tasks that are disjoint or only slightly overlapped. Our future work will focus on further expand the appliance scope of DaC to more areas like question answering.

## Proof to Theorem 4.2

Before providing the proof, we first formally define how to organize the inputs (i.e., two 2-color trees) as a sequence. We assume that we acquire two trees `latex $t_p$ ` of size `latex $n$ ` and `latex $t_b$ ` of size `latex $m$ `. They are organized as two sequences of nodes with a random order. Each node has three variables: color, left child index, and right child index. If any child is null, then the index is filled with 0. Then we can organize them as two sequences `latex ${\bf X}_p\in \mathbb{R}^{n\times3}$ ` and `latex ${\bf X}_b\in \mathbb{R}^{n'\times3}$ `, where each item in the sequence is a vector of 3 dimensions. The first dimension is the index of the left child, the second dimension is the index of the right child, the third dimension is the color indicator (0 or 1). In addition, we have a root vector `latex ${\bf r}$ ` with three dimensions. The first dimension is the index of the root node of `latex $t_p$ ` (i.e., pointing to the root node of `latex $t_p$ `) and the second is the index of the root node of `latex $t_b$ ` (i.e., pointing to the root node of `latex $t_b$ `). The third dimension of `latex ${\bf r}$ ` is filled with 0 to make it have same dimension as the items in `latex ${\bf X}_p$ ` and `latex ${\bf X}_b$ `. This expression of trees is also called as pointer list encoding according to [jenner2003completeness]. Note that in the following proof, we assume that all indices start from 1. Thus 0 is regarded as a NULL pointer.

Following the proof flow we provided in Sec. 4.2, we first provide the following divide-and-conquer algorithm that can solve the above problem:

**Algorithm 3: Recursion Divide-and-Conquer Algorithm for 2-BSI BSI(r,X_p,X_b,m,t,d,f,w)**

```
REQUIRE: Inputs r, X_p, X_b, problem size metric function f(.), hyper-parameter w, merge function m, sub-task tackling function t, task decomposition function d
ENSURE: A 0-1 indicator vector v: if there exists a subtree with node i as root that is isomorphic with pattern tree t_p defined with inputs r,X_p,X_b, then the v[i] is 1. Otherwise, v[i] is 0.
1. r_l, r_r <- d(r,X_p,X_b)
2. FOR i in {l,r}
3.   IF f(r_i,X_p,X_b) > w THEN
4.     v_i <- BSI(r_i,X_p,X_b,m,t,d,f,w)
5.   ELSE
6.     v_i <- t(r_i,X_p,X_b)
7.   ENDIF
8. ENDFOR
9. Return m(r,X_p,X_b,v_l,v_r)
```

The algorithm described above is a typical divide-and-conquer algorithm for solving rooted tree isomorphism. Its justification can be found in many textbooks introducing algorithms, such as _Introduction to Algorithms_ [cormen2022introduction]. Here we provide the detailed definition and implementation of problem size metric `latex $f(\cdot)$ `, hyper-parameter `latex $w$ `, merge function `latex $m()$ `, sub-task tackling function `latex $t(\cdot)$ `, task decomposition function `latex $d(\cdot)$ `:

- `latex $w=1$ `, and `latex $f({\bf r},{\bf X}_p,{\bf X}_b)$ ` is defined as the depth of the pattern tree `latex $t_p$ ` indicated with root vector `latex ${\bf r}$ `. Although precisely calculating `latex $f({\bf r},{\bf X}_p,{\bf X}_b)$ ` is of `latex $O(n)$ `, judging whether `latex $f({\bf r},{\bf X}_p,{\bf X}_b)>1$ ` only require us to check whether the root node has child. If not, then return False.

- `latex $d({\bf r},{\bf X}_p,{\bf X}_b) = {\bf r}_l, {\bf r}_r$ ` returns two new root vectors `latex ${\bf r}_l, {\bf r}_r$ `. Both `latex $r_l, r_r$ ` have the same second and third dimension as `latex ${\bf r}$ `. The `latex ${\bf r}_l$ `'s first dimension is updated to be the index of the left child of the root node that `latex ${\bf r}$ ` points to. The `latex ${\bf r}_r$ `'s first dimension is updated to be the index of the right child of the root node that `latex ${\bf r}$ ` points to.

- `latex $t({\bf r},{\bf X}_p,{\bf X}_b) = {\bf v}$ ` returns a 0-1 indicator vector `latex ${\bf v}\in \mathbb{R}^m$ ` with the same length of the base tree size. If there exists a subtree with node i as root that is isomorphic with pattern tree `latex $t_p$ ` defined with inputs `latex ${\bf r},{\bf X}_p,{\bf X}_b$ `, then the `latex ${\bf v}[i]$ ` is 1. Otherwise, `latex ${\bf v}[i]$ ` is 0. When the pattern tree's depth is not higher than 1 (i.e., 1-node tree), `latex $t({\bf r},{\bf X}_p,{\bf X}_b)$ ` is equivalent to output a 0-1 vector indicating the nodes in the base tree that have the same color of the root node of pattern tree.

- `latex $m({\bf r},{\bf X}_p,{\bf X}_b,{\bf v}_l,{\bf v}_l) = {\bf v}$ ` merge the results `latex ${\bf v}_l,{\bf v}_l$ ` to acquire a 0-1 indicator vector `latex ${\bf v}\in \mathbb{R}^m$ ` with the same length of the base tree size. If there exists a subtree with node i as root that is isomorphic with pattern tree `latex $t_p$ ` defined with inputs `latex ${\bf r},{\bf X}_p,{\bf X}_b$ `, then the `latex ${\bf v}[i]$ ` is 1. Otherwise, `latex ${\bf v}[i]$ ` is 0. This function can be implemented by checking whether the pattern root's children have a perfect match with each node's children. Since each node has at most two children, checking the perfect match can be done in constant time.

**Lemma 5.** _Any fixed-size logic circuit that only contains multi-fan-in AND gates, multi-fan-in OR gates, NOT gates and has no recurrent structure can be precisely simulated by a multi-layer perceptron (MLP) with ReLU activation function and a width of_ `latex $O(|Input|+|Circuit|)$ ` _and a depth of_ `latex $O(|Circuit|)$ `_, where_ `latex $|Input|$ ` _denotes the size of input and_ `latex $|Circuit|$ ` _denotes the number of gates in the circuit._

_Proof._ Assume that we are given a series of input pins with logic variable of 0 or 1, organized as a 0-1 vector `latex ${\bf x}\in\mathbb{R}^h$ `. We first prove that all gates can be simulated by a two-layer perceptron. Then we can serialize all gates in the circuits and stack their corresponding 2-layer simulators accordingly to acquire a MLP simulator. An AND gate that take `latex ${\bf x}$ ` as input can be simulated as:

```latex
$$\text{AND}({\bf x}) = \sigma(w_A{\bf x}-h+1)$$
```

where `latex $\sigma$ ` is the ReLU activation function, and `latex $w_A$ ` is a weight vector with all dimensions equal to 1. If some dimensions of `latex ${\bf x}$ ` are not the input of the gate, we can set the corresponding dimensions in the weight vector as 0 and adjust the `latex $h$ ` as the input pin number. Similarly, an OR gate that take `latex ${\bf x}$ ` as input can be simulated as:

```latex
$$\text{OR}({\bf x}) = 1-\sigma(w_O{\bf x}+h+1)$$
```

where `latex $\sigma$ ` is the ReLU activation function, and `latex $w_O$ ` is a weight vector with all dimensions equal to -1. A NOT gate is different, since it only takes one input pin. In such a case, we denote the index of the input pin as `latex $i$ `, then we can simulate a NOT gate as:

```latex
$$\text{NOT}({\bf x}) = \sigma(w_N{\bf x}+1)$$
```

where `latex $w_N$ ` is a weight vector whose `latex $i$ `-th dimension equals to -1 and all other dimensions equal to 0.

**Theorem 6.** _There exists a log-precision transformer with fixed depth and hidden dimension that can solve the 2-BSI of any size with fixed-length prompt m (for merge), t (for sub-task tackling) and d (for task decomposition)._

_Proof._ We prove this theorem by constructing a Transformer that can tackle this problem. The detailed construction involves organizing inputs into a feature sequence and constructing a 2-layer transformer with specific attention head configurations. The transformer uses positional embeddings and multi-head attention to retrieve features based on specific conditions, followed by MLPs that simulate the logical circuits for the divide-and-conquer algorithm components.

## Justification to Proposition 4

Suppose that the LLM is auto-regressively decoding `latex $n$ ` tokens from an input context window with length of `latex $C$ `. Then the decoding window of the `latex $i$ `-th token is `latex $C+i-1$ `. Thus, the average window size will be:

```latex
$$\frac{\sum_{i=1}^n (C+i-1)}{n} = \frac{C+n-1}{2}$$
```

Thus, when we sequentially decode all the sub-task resolutions, the total length of the decoded sequence will be `latex $\sum_{i=1}^kr_i$ `. Thus the average window size will be:

```latex
$$C+\frac{\sum_{i=1}^kr_i-1}{2}$$
```

Meanwhile, when we apply Divide-and-Conquer, we parallely decode each sub-task's resolution. Thus, for each sub-task, total window size will be `latex $C\sum_{j=1}^kr_j+\sum_{i=1}^k\frac{(r_i-1)r_i}{2}$ `. Thus the average window size will be `latex $C+\sum_{i=1}^k\frac{(r_i-1)r_i}{2\sum_{j=1}^kr_j}$ `. Meanwhile, with Jensen inequality, we have:

```latex
$$\sum_{i=1}^k(r_i-1)r_i<\sum_{i=1}^k(r_i-0.5)^2\leq (\sum_{i=1}^k(r_i-0.5))^2\leq (\sum_{i=1}^kr_i-0.5k)^2$$
```

Thus, when `latex $k\geq2$ `, we have:

```latex
$$\sum_{i=1}^k(r_i-1)r_i< (\sum_{i=1}^kr_i-1)^2$$
```

Thus, we have:

```latex
$$C+\sum_{i=1}^k\frac{(r_i-1)^2}{2\sum_{j=1}^kr_j}<C+\frac{\sum_{i=1}^kr_i-1}{2}$$
```

## Prompting Details of DaC

**Multiplication of Long Integers:** Suppose we have two `latex $2n$ `-digit numbers `latex $AB$ ` and `latex $CD$ `, where `latex $A,B,C,D$ ` are all `latex $n$ `-digit numbers. Then we can break `latex $AB\times CD$ ` as `latex $(A\times C\times 10^{2n})+(A\times D\times 10^n)+(B\times C\times 10^n)+(B\times D)$ `, where the calculation in each bracket pair is disjoint with others bracket pairs. We only need to compute the results of multiplication in each bracket pair parallelly and then merge all of them with addition:

_Decomposer Prompt d_: Please split the string a from the middle as two separated strings. The lengths of the two separated strings should be as close as possible. Please only return the two strings separated by a comma and do not return anything else.

_Sub-task Tackling Prompt t_: (1)Please compute a\*b. (2) Please only return the final results and do not return anything else (ensure disentangled-sub-process principle).

_Merge Prompt m_: Please compute x=a*10^{2n}+b*10^{n} and y=c\*10^{n}+d. Based on the above calculation, please compute x+y carefully step by step.

**Hallucination Detection in Long Context**: We divide the summary to sentences. After that, we parallely verify the sentences. Finally, we merge the verification to each sentence:

_Decomposer Prompt d_: Please help me segment the following paragraph as sentences. The separated sentence should be output as: #Statement 1#: ...#Statement 2#: ...Do not say anything else. Just return the statements in the given format. Paragraph

_Sub-task Tackling Prompt t_: I want you to act as a factual contradiction checker. You are given a set of statements and a document. Among the statements, there might be one or more statement that contains contradictions with the document. Please find the problematic statement if it exist by analyzing the statements one by one. For each statement, please make a choice:

- A: The statement is totally aligned with the document for sure.
- B: The statement contradicts with the document.

_Merge Prompt m_: Based on the above analysis, please tell me, does any statement above contain contradiction with the document?.

**Fact-Verification for Misinformation Detection**: Similar as hallucination detection, we divide the summary to sentences. After that, we parallely verify the sentences. Finally, we merge the verification to each sentence. Thus, our decomposer prompt and sub-task tackling prompt are the same as hallucination detection. The only difference is the merge prompt.

_Merge Prompt m_: If we connect the above statements to be a news article, based on the above analyzation, please answer me: Is there any contradiction between the document and the article?

[IMAGE: DeC.pdf - Comparison of Least-to-Most (LtM) Prompting and Decomposed Prompting (DeP).]

## Decomposed Prompting and Least to Most

Least-to-Most (LtM) Prompting [zhou2022least] and Decomposed Prompting [khot2022decomposed] are two similar works to our work. They both propose to explicitly prompt the LLM to decompose the task as a series of sub-tasks and sequentially tackle them. Decomposed Prompting can regarded as a upgraded version of LtM. It introduces special notations into the prompt to represent program states so that when sequentially tackling the sub-tasks, it can call heterogeneous modules to tackle them. Such design enable the LLM to call external programs (e.g., retrieval documents on WikiPedia and program based calculator) and/or itself (i.e., recursion). Such design endows it stronger expressive power and increases the compositional generalization ability of LLMs in different areas, such as symbolic manipulation and multi-hop QA [khot2022decomposed]. Also, it endows LLM the ability to do open-domain QA by retrieving from external knowledge base.

## Typical Tasks that Satisfy and Dissatisfy the Proposed Conditions

To better assist the prompt engineering on different tasks, we list the typical tasks that satisfy and dissatisfy the proposed conditions. In common tasks, the following tasks satisfy the proposed conditions. For such tasks, searching good decomposition prompt for DaC is likely to be helpful for the performance:

1. **Multiplication**
2. **Fact Verification on Long Text**
3. **Auto Evaluation on Long Text**
4. **Article-level Summary**

The following tasks typically do not satisfy the proposed conditions. For such tasks, searching good decomposition prompt for DaC is not very likely to be helpful for the performance:

1. **Addition**: It is too simple and violate the condition 1
2. **Division**: It does not contain parallel sub-tasks, thus violate condition 2
3. **Multi-Round Question-Answering**: It is a typical sequential task, thus violate condition 2
4. **Planning**: It is a typical sequential task, thus violate condition 2

## More Discussions on Sequential Sub-task Tackling and Parallel Sub-task Tackling

[IMAGE: Example_more2.pdf - Toy example of Sequential Sub-task Tackling and Parallel Sub-task Tackling in long integer multiplication]

[IMAGE: Example_more1.pdf - Toy example of Sequential Sub-task Tackling and Parallel Sub-task Tackling in hallucination detection]

Sequential Sub-task Tackling and Parallel Sub-task Tackling are two different paradigm in decomposing complex tasks as sub-task to tackle. The first one decompose a complex tasks as a series of sub-tasks. In this series, each sub-task relies on the previous one's output as input or context. The second one decompose a complex tasks as a set of sub-tasks, each of which does not rely on others. Two examples for multiplication and hallucination detection are provided in the figures above.
