# Abstract

Large language models (LLMs) are documented to struggle in settings that require complex reasoning. Nevertheless, instructing the model to break down the problem into smaller reasoning steps, or ensembling various generations through modifying decoding steps boosts performance. However, these methods assume that the input prompt is fixed and expect the decoding strategies to introduce the diversity needed for ensembling. In this work, we discuss how one can create and leverage variations of the input prompt as a means of _diversity of thought_. We propose a method that automatically improves prompt diversity by soliciting feedback from the LLM to ideate approaches that are apt for the problem. We then ensemble the diverse prompts in our method Div-Se (DIVerse reasoning path Self-Ensemble) across multiple inference calls, or use diverse approaches within a single inference call; we call the latter IDiv-Se (In-call DIVerse reasoning path Self-Ensemble). Apart from our approaches outperforming prior work, Div-Se (in particular) advances state-of-the-art performance on the challenging planning and graph coloring benchmarks. Our results improve the Pareto frontier of the accuracy-cost trade-off.

# Introduction

[IMAGE: cost_vs_accuracy_besa_feedback.pdf - Diversity of Thought enhances the inference cost vs. accuracy trade-off. Comparison of DIV-SE and IDIV-SE with SC and CoT across three benchmarks. The x-axis indicates the total inference cost on the benchmark using the given method, while the y-axis represents the LLM's performance. The few-shot-CoT setting is represented by filled gray dots, while the zero-shot-CoT setting is indicated by unfilled dots. Notice that for a fixed cost, our approaches always give better performance.]

Large language models (LLMs) exhibit state-of-the-art performance across a myriad of tasks, but their effectiveness is strongly influenced by prompt design [anil2023palm; openai2023gpt4; nori2023can]. For complex reasoning tasks, the right prompt can enable LLMs to capitalize on task structure [Guidance:2024:Online], such as by facilitating memory (by externalizing thought processes), or through tractable problem decomposition [zhou2024self]. However, existing prompt design either relies on iterative trial-and-error [white2023prompt], or is expensive [lester2021power].

Previous works identified two simple, yet general prompting principles to enable complex reasoning: (i) Chain-of-Thought (CoT) prompting, and (ii) ensembling multiple solutions from diverse decoding paths. CoT prompting [wei2022chain] improves performance by guiding the LLM to follow step-by-step reasoning. Self-consistency (SC) [wang2023selfconsistency] instead increases the stochasticity by modifying the decoding process and obtaining multiple completions, which are then ensembled.

However, combining the two principles raises limitations. First, inference is significantly more expensive due to numerous runs, each generating long completions with many reasoning steps. Next, it may be impermissible to modify the decoding process in some settings, such as commercial deployments. Finally, stochasticity-based methods do not directly guide the diversity at the level of thought or method, but rather at the token level. This poses limitations because linguistic token diversity does not always ensure diverse and independent solution approaches.

In this paper, we explore how to explicitly promote the _diversity of thought_ while mitigating the aforementioned issues. Prior work by Li et al. [li2023making] highlights the importance of prompt diversity, but their notion of diversity is captured through variety in the few-shot examples provided with the prompt; ours focuses on the reasoning approach. We first solicit the LLM to produce multiple-high-level reasoning approaches for problem-solving (e.g., `method of elimination, visualization techniques` etc. for math reasoning problems). We then leverage GPT-4 to augment few-shot examples used in prior work [wei2022chain] into the corresponding approaches, whenever applicable.

We propose Div-Se (DIVerse reasoning path Self-Ensemble) to extract and aggregate responses (via majority vote) across multiple inference calls. Since distinct approaches introduce diversity at the "thought" level, our methodology results in improved ensemble accuracy. In Fig. 1, we show that it yields more accurate results across multiple reasoning benchmarks at a fixed inference cost, without modifying the decoding procedure. For instance, in the Blocksworld 4/5 task [valmeekam2022large], Div-Se improves the performance by 29.6 percentage points (p.p). However, this method still leverages multiple inference calls, which could be costly.

To reduce inference costs, we build on the observation that the approaches are often mutually independent, and can be combined in a _single prompt_ to solicit multiple solutions [cheng2023batch]. Based on this premise, we propose IDiv-Se (In-call DIVerse reasoning path Self-Ensemble), which combines all approaches within the same prompt and aggregates all resulting outputs to leverage diversity with a reduced cost. Fig. 1 demonstrates that this method obtains comparable accuracy to Div-Se and better performance than prior work with lower inference costs.

We push the pareto frontier of the cost-accuracy trade-off of prompting strategies across multiple reasoning tasks, outperforming both CoT and SC prompting on both GPT-3.5 and GPT-4. This is evident from Fig. 1 for the AQuA-RAT [ling-etal-2017-program], planning [valmeekam2023planning], and graph coloring [stechly2023gpt4] benchmarks, where there is a performance improvement of 16.52, 29.6, and 82.5 p.p respectively. These improvements, some of which are state-of-the-art, show the potential of thought diversity to extract complex reasoning abilities from LLMs that were impossible to leverage otherwise. We will open source our code upon publication to encourage further research.

# Diversity through LLM Interactions

First, we introduce terms and notations that we use throughout the paper. We use upper case for sets, lower case for variables, and `latex $[n] = \{1, \cdots, n\}$ `.

These are reasoning strategies for problem solving, denoted with the variable `latex $a$ `. For example, for the GSM8K [cobbe2021training], a benchmark of grade-school math problems, some of the (generated) approaches can include `latex $a_1=$ `"using visualizations", `latex $a_2=$ `"working backwards", `latex $a_3=$ `"using direct calculation", and `latex $a_4=$ `"method of elimination".

In addition to specifying "how" to solve a reasoning problem, specifying a persona can also influence how the LLM behaves [salewski2023context]. We denote this with the variable `latex $p$ ` e.g., `latex $p_1=$ `"Thinking like Alan Turing", `latex $p_2=$ `"Thinking like Math Professor" for the GSM8K task. Note that both approaches and personas are dependent on the reasoning problem.

## Using the LLM as a guide

Proposed method for creating prompts, which we term _DiversePrompting_ is presented in Algorithm 1. Below, we will describe each step in more detail. At a high-level, we solicit feedback from the LLM on how to solve tasks.

Note that LLMs trained on internet-scale data encode a significant knowledge from multiple domains [liang2022holistic; bubeck2023sparks]. While LLMs may not be perfect at solving reasoning tasks, we hypothesize that they are helpful in providing high-quality intermediate feedback.

To extract approaches, we utilize the following methodology: (i) Randomly picking a question from the reasoning dataset `latex $D$ ` we want to evaluate; and (ii) Creating an instruction prompt where we ask the LLM to generate the names of `latex $b \in [1,5]$ ` _approaches_ to solve the aforementioned question conforming to a predefined template (for easier post-processing). Refer to Figure 2 for an example of the prompt used.

We extract the part of the response that is compliant with the template and store it. We repeat this process `latex $c$ ` times (obtaining of `latex $c \cdot b$ ` candidate approaches), and pick the `latex $n$ ` most frequent approaches to store in set `latex $A$ `. This process is abstracted as method `det_approaches(.)`.

One can repeat the above process used to extract relevant personas for a given reasoning task. However, we followed a simpler route and asked the model directly for relevant personas for a given task and then included them in the set of `latex $m$ ` candidate personas `latex $P$ ` used. This is abstracted as method `det_personas(.)`. Note that no persona (`latex $\phi$ `) is also part of the persona set.

The choice of persona and approaches introduces a principled way to promote diversity.

If the set of personas is `latex $P$ `, and the set of approaches is `latex $A$ `, the Cartesian product of `latex $P$ ` and `latex $A$ ` yields the total number of prompts. In practice, for each combination (denoted by `latex $s_i$ `) of persona and approach, we evaluate the prompt formed using the composition on a small validation set `latex $V$ ` and choose the best performing "size" elements on the given task.

Once the (subset of) approach and persona pairs are fixed, we ask the LLM to augment existing few-shot examples (denoted `latex $F=\{f_1, \cdots\}$ `) with the given set of approaches. Specifically, we take the few-shot examples provided by Wei et al. [wei2022chain], and ask the LLM to solve them in the style of a chosen approach and persona pair (Fig. 6); we term the output _augmented few-shot examples_. This is abstracted in method `augment(.)`, where `latex $\tilde{T}_{i,j}$ ` is the set of augmented few-shot examples corresponding to the approach and persona pair from `latex ${s}_i$ ` and example `latex $f_j$ `. An example is visualized in the bottom left of Fig. 2, where the prompt contains different approaches for solving a math problem.

## Designing the Prompts

We create prompts for our approach using the best approach and persona pairs identified in step 3, and augmented few-shot examples from step 4 as shown in Fig. 2 and 3.

We now describe two techniques to generate prompts with the augmented demonstrations (`latex ${T}$ `) that have been accumulated.

We first propose Div-Se (DIVerse reasoning path Self-Ensemble), a method to execute the diverse set of approaches in different inference calls and aggregate their solutions. Apart from the question to be solved and the augmented few-shot examples, the final prompt contains a persona, approach, and additional instructions. One example is visualized in Fig. 3 (please refer to appendix for more examples of prompts: Fig. 7 through 14). _Diversity is ensured through running inference with multiple prompts, each with a different approach and persona pairs and augmented few-shot examples._ However, since the approaches are executed separately, generating a solution (via aggregation of multiple responses) requires multiple inference calls, which can be costly.

To further reduce the inference costs while promoting diversity, we propose IDiv-Se (In-call DIVerse reasoning path Self-Ensemble). In IDiv-Se, _the final prompt is a composition of all approach and persona pairs and corresponding augmented few-shot examples, and the question to be solved_. An example is presented in Fig. 2 (bottom left). More examples of prompts are presented in the appendix in Fig. 7 through 14. This noticeably decreases the number of calls to be made, since all few-shot examples are presented within the same prompt. We note that there might be error propagation due to the autoregressive nature of models. We evaluate this in detail in Section 4.3.

Crucially, DiversePrompting finds approaches that are _general and reusable_ across similar reasoning problems. We reused the strategies identified for solving AQuA-RAT and Planning benchmark respectively in the MATH (counting and probability) and Graph Coloring benchmarks. This also reduces the cost of repeated evaluation on a separate evaluation set.

We aggregate the responses via majority vote for both prompting strategies. Other aggregation strategies can also be leveraged, such as utilizing the LLM itself to aggregate responses or weighted aggregation. In Section 4.4, we consider an aggregation strategy proposed by Yoran et al. [yoran2023answering] and describe how compatible it is with our prompting approaches.

# Experiments

We consider the following reasoning benchmarks.

[IMAGE: cost_vs_accuracy_gsm_cqa_besa_feedback.pdf - Diversity of Thought enhances the inference cost and accuracy trade-off. Comparison of Div-Se and IDiv-Se with SC and CoT across three benchmarks. The x-axis indicates the total cost of running inference with the LLM on the benchmark using the given method, while the y-axis represents the LLM's performance. The FS-CoT setting is represented by filled gray dots, while the ZS-CoT setting is indicated by unfilled dots. Notice that for Blocksworld 3, despite being in the ZS-CoT setting, our approaches are more performant than the SC-s (FS-CoT) baseline.]

**Math Reasoning:** We use: (i) AQuA-RAT [ling-etal-2017-program], a suite of algebraic word problems, (ii) GSM8K [cobbe2021training], a benchmark of grade-school math problems described in natural language (involving elementary arithmetic operations), and (iii) MATH (Counting and Probability) [hendrycks2021measuring], a collection of math problems from which we choose only counting and probability as these are not covered by GSM8K and AQuA-RAT. For all datasets, we use the `test` split for evaluation, containing 254, 1319, and 474 questions respectively.

**Planning:** We use the Blocksworld Planning benchmark proposed in Valmeekam et al. [valmeekam2022large; valmeekam2023planning]. The benchmark has two datasets: one involves 3 blocks (Blocksworld 3, 100 instances), while the other dataset involves 4 or 5 blocks (Blocksworld 4/5, 500 instances).

**Constraint Satisfaction:** We use the Graph coloring benchmark [stechly2023gpt4] containing 100 examples to test reasoning for constraint satisfaction. **Common Sense:** We use CommonsenseQA [talmor-etal-2019-commonsenseqa] which consists of generic multiple-choice questions elicited for testing common sense reasoning. We use the `validation` split containing 1,221 questions.

We evaluate our proposed methods on both GPT-3.5 Turbo [chatgpt] and GPT-4 [gpt4]. We also conduct an additional evaluation on LLaMA-2 70B [touvron2023llama2] to explore the performance of our technique on open-source LLMs. For the latter, we use `meta-llama/Llama-2-70b-chat-hf` through the Transformers library [wolf2019huggingface].

We consider Chain-of-Thought (CoT) [wei2022chain] and Self-Consistency (SC) [wang2023selfconsistency] as our baselines. For CoT, we consider two settings: zero-shot (ZS) CoT [kojima2022large] (i.e., "Think step by step" is added to the prompt), and few-shot (FS) CoT (i.e., CoT with demonstrations). In our SC runs, we set the temperature `latex $T=0.7$ ` without top-`latex $k$ ` truncation and sample up to `latex $s \in [1,10]$ ` outputs (denoted SC-`latex $s$ `). For all other approaches, we set `latex $T=0$ `. We use ensembles of size 5 in IDiv-Se and Div-Se for GSM8K and AQuA-RAT. For the planning, Graph Coloring, and CommonsenseQA benchmarks, we use a size of 3.

We measure the accuracy on the task, and the generation inference cost. To measure the cost, we assume 1000 tokens are about 750 words. For GPT-4 (8K) the input and output prices used to estimate inference cost are \$0.03/1k tokens and \$0.06/1k tokens, respectively. For GPT 3.5 Turbo (16K), the input and output prices used in the cost estimation are \$0.003/1k (tokens) and \$0.004/1k (tokens) respectively.

**Key findings include:** Across most benchmarks we consider, our techniques provide substantial performance gains (e.g., 16.52, 82.5, and 14.3 p.p improvements for AQuA-RAT, Graph Coloring, and MATH respectively). They are also Pareto optimal (in terms of the utility vs. cost trade-off). For the challenging planning benchmark (Blocksworld 4/5), our techniques improve accuracy by 29.6 p.p achieving _state-of-the-art_ performance. Using GPT-4 for Blocksworld 3, our approach (in the ZS-CoT setting) is substantially more effective than SC-10 (in the FS-CoT setting) at 4x lower cost (Figure 2 (center figure)).

Since prompts are chained together in IDiv-Se, error propagation is possible. Our evaluation on AQuA-RAT in Section 4.3 suggests that even though error propagation is estimated as less than 6.5% for both models, these rates are comparable to differences in performance between Div-Se and IDiv-Se. When combined with aggregation approaches that are capable of reasoning across the diverse generations [yoran2023answering], we observe additional performance gains as shown in Section 4.4. For the AQuA-RAT benchmark for instance, we see an accuracy of 67.7% for GPT-3.5 (3.23 p.p improvement to majority voting).

# Results

## Main Results

We present the summary of results in Table 1 and 2. Detailed results are available in Appendix 10. These also cover results on the impact of ensemble size in Appendix 11.

**Table 1: Performance on Graph Coloring and Blocksworld planning for GPT-4 in the ZS-CoT setting. Comparison of Div-Se and IDiv-Se with SC and CoT.**

| Method  | Graph Coloring | BW 3      | BW 4/5    |
| ------- | -------------- | --------- | --------- |
| CoT     | 15.0           | 70.00     | 40.00     |
| SC-3    | 18.0           | 66.00     | 38.20     |
| SC-5    | 20.0           | 70.00     | 38.40     |
| SC-7    | 22.0           | 72.00     | 40.00     |
| SC-10   | 23.0           | 73.00     | 41.20     |
| IDiv-Se | 74.00          | 82.00     | 57.00     |
| Div-Se  | **97.00**      | **94.00** | **69.60** |

**Table 2: Performance on AQuA-RAT, MATH (Counting and Probability), and CommonsenseQA for GPT-3.5 Turbo and GPT-4 in the ZS-CoT and few-shot-CoT settings respectively.**

| Setting    | Method  | AQuA      | MATH      | CQA       |
| ---------- | ------- | --------- | --------- | --------- |
| GPT-3.5 ZS | CoT     | 59.00     | 31.90     | 71.40     |
|            | SC-3    | 61.40     | 32.07     | 72.00     |
|            | SC-5    | 63.37     | 38.19     | 72.80     |
|            | IDiv-Se | 62.60     | 42.50     | 74.00     |
|            | Div-Se  | **72.83** | **44.94** | **74.50** |
| GPT-3.5 FS | CoT     | 57.48     | 30.38     | 79.4      |
|            | IDiv-Se | 64.57     | 44.10     | 80.00     |
|            | Div-Se  | **72.84** | **52.22** | **80.40** |
| GPT-4 ZS   | CoT     | 70.47     | 62.24     | 81.60     |
|            | IDiv-Se | 71.65     | 72.00     | **82.50** |
|            | Div-Se  | **80.31** | **79.11** | 81.70     |
| GPT-4 FS   | CoT     | 71.90     | 66.46     | 87.70     |
|            | IDiv-Se | 79.90     | 72.00     | **89.00** |
|            | Div-Se  | **84.25** | **80.76** | 88.00     |

### Arithmetic reasoning via AQuA-RAT

In Table 2, we observe that Div-Se achieves an accuracy increase of 9.84 and 14.6 p.p in the FS-CoT (baseline accuracy of 71.9%) and ZS-CoT (baseline of 70.47%) settings, respectively. While the gains from IDiv-Se are nominal in ZS-CoT, it achieves a boost of 7.7 p.p for FS-CoT.

In Table 2, we see that Div-Se yields a gain of 14.23 and 16.52 p.p in the FS-CoT (baseline of 57.48%) and ZS-CoT (baseline of 59%) settings, respectively. Within the FS-CoT setting, IDiv-Se gets an absolute increase of 7 p.p.

Note that Fig. 1 also displays the total inference cost. Both IDiv-Se and Div-Se are _Pareto optimal_, indicating their capacity to achieve a higher accuracy while maintaining low costs.

### Counting and probabilistic reasoning via MATH

From Table 2, we see that Div-Se achieves an accuracy increase of 14.3 and 16.87 p.p in the FS-CoT (baseline of 66.46%) and ZS-CoT (baseline of 62.24%) settings, respectively. On the other hand, IDiv-Se achieves a boost of 5.54 and 9.76 p.p in the FS-CoT and ZS-CoT settings, respectively, over the baseline.

From Table 2, we see that Div-Se yields a gain of 21.84 and 13.04 p.p in the FS-CoT (baseline of 30.38%) and ZS-CoT (baseline of 31.90%) settings, respectively. Likewise IDiv-Se achieves a boost of 13.72 and 10.60 p.p in the FS-CoT and ZS-CoT settings, respectively.

### Planning via Blocksworld

The benchmark provides both natural language and Planning Definition and Domain Language prompts [mcdermott1998pddl]. We use natural language prompts in all the experiments. For the baseline runs, we introduce minor alterations to the prompt originally proposed by Valmeekam et al. [valmeekam2023planning]. These changes involve incorporating an explicit directive to prevent under-block movement and resolving minor language ambiguities we observed to be problematic during initial investigation. Furthermore, we reposition the initial condition and goal state information to the beginning of the prompt. The modified improved prompt is presented in Fig. 7.

We aggregate the plans through majority voting and utilize string matching for comparing the plans. As a result, we optimize the plan by eliminating the redundant "no-op" steps.

We note that GPT-4 performs slightly better in a ZS setting, and use this to run all experiments. From Fig. 1, we observe that for Blocksworld 3, ZS-CoT records an accuracy of 70%, while SC-10 reaches an accuracy level of 73%. IDiv-Se enhances the absolute accuracy by 12 p.p above the ZS-CoT baseline, while Div-Se produces an impressive _state-of-the-art_ accuracy of 94%. An analysis of the six unsuccessful instances suggests the capacity for further performance improvement by increasing the size of the ensemble, as already two out of five current approaches generate accurate plans. For the Blocksworld 4/5 case, the ZS-CoT accuracy is 40%, while SC-10 has an accuracy of 41.2%. Here, IDiv-Se results in an absolute gain of 17 p.p above the ZS-CoT baseline, and Div-Se too enhances performance, leading to 69.6%. As outlined in Fig. 1 and 2, both IDiv-Se and Div-Se achieve _Pareto optimality_.

The baseline performance on Blocksworld 3 is 6%, and on Blocksworld 4/5 is 0.6%. We do not see any additional improvement using both IDiv-Se and Div-Se. Qualitatively, we observe that during plan generation, GPT-3.5 fails to follow the restrictions provided as part of the problem instructions too often, leading to either infeasible or incorrect plans. This shows instruction following capabilities are crucial to the success of the methods proposed here.

### Constraint Satisfaction via Graph Coloring

There may exist numerous non-optimal yet valid colorings for a given graph. Since exact string matching is not usable for identifying the majority solution from the ensembles of IDiv-Se and Div-Se, we employ the external, sound verifier [stechly2023gpt4] to pick the correct solution.

From Fig. 1, it is observed that ZS-CoT achieves an accuracy of 15%, whereas SC-10 attains an accuracy level of 23%. IDiv-Se improves the absolute accuracy by 59 p.p above the ZS-CoT baseline. Remarkably, Div-Se delivers a _state-of-the-art_ accuracy of 97%. Given that GPT-4's performance plateaus in the ZS setting, we chose to omit conducting the few-shot experiments.

Methods in this work often demonstrate state-of-the-art performance on reasoning tasks. This is most significant in the planning and constraint satisfaction benchmarks, where the corresponding authors claimed immense difficulty for existing LLMs. Our work shows that status-quo prompt design approaches including chain of thought are too generic for these problems, and prompt customization (via DiversePrompting) can yield substantial gains by guiding the chain of thought to the general nature of the problem.

## Open Source Models

Due to the limited computational budget, we only performed experiments with the AQuA-RAT benchmark. Please refer to Appendix 9 for further details. Table 3 demonstrates the results for LLaMA-2 70B with 8-bit quantization. Div-Se and IDiv-Se demonstrate an improvement of over 10 p.p over the baseline in the FS-CoT settings. However, the gain in the ZS-CoT setting has been negligible. We hypothesize that this is partly due to model's lack of capabilities to both follow instructions and the mentioned approach in the absence of examples.

**Table 3: Results on AQuA-RAT and LLaMA-2 70B.**

| Prompting Strategy | ZS-CoT (%) | FS-CoT (%) |
| ------------------ | ---------- | ---------- |
| CoT                | 31.32      | 29.1       |
| IDiv-Se            | 27.00      | 39.7       |
| Div-Se             | **32.00**  | **39.9**   |

## Errors & Prompt Utility

Due to the autoregressive nature of LLM decoding, early incorrect answers in IDiv-Se may get propagated to the latter ones. To quantify this, we select examples where the solution is incorrect and all five approaches produce the same erroneous answer. We focus only on these cases to see if e.g., a wrong conclusion in the initial approaches leaks into the following ones. Next, we attempt the last two approaches again in a separate session: if the LLM generates the same outcomes as in the original session (i.e., IDiv-Se setup) within 3 attempts, we consider it as no error propagation. However, if it does not produce the same answer within the 3 attempts, we interpret this as a case of error propagation since the change in answer could be attributed to the initial approaches with wrong answers in the chain. We measure this phenomenon on AQuA-RAT (FS-CoT) on both GPT-4 and GPT-3.5. We find that GPT-4 and GPT-3.5 have error propagation rates of 6.2% and 5.5% respectively, which are comparable to performance differences between Div-Se and IDiv-Se, _making error propagation one of the main explanatory hypotheses for the differences between the two methods_. Reducing these error rates remains a challenging problem given the autoregressive nature of current LLMs.

**Table 4: Prompt Utility - Individual approaches and personas improve over ZS-CoT baseline.**

| Dataset, Model         | Persona, Approach                                 | Accuracy (%)       |
| ---------------------- | ------------------------------------------------- | ------------------ |
| AQuA-RAT, GPT-3.5      | (empty), Think step by step                       | 57.48              |
|                        | (empty), Using Algebra                            | 60.24 **(+2.76)**  |
|                        | Thinking like Alan Turing, (empty)                | 61.81 **(+4.33)**  |
|                        | Dr. Patel: A renowned mathematician, (empty)      | **65.75 (+8.27)**  |
| Blocksworld 4/5, GPT-4 | (empty), State tracking prompt                    | 42.00              |
|                        | (empty), Finite State Machine                     | 55.80 **(+13.80)** |
|                        | Alan Turing, Action Rationale                     | 57.80 **(+15.80)** |
|                        | Alan Turing, Progressive Block Placement Approach | **58.80 (+16.80)** |

The diverse approaches and personas we utilize not only enhance the performance in IDiv-Se and IDiv-Se, but are also independently superior to ZS-CoT. Table 4 highlights this effect, which showcases the importance of conditioning the model for solutions via DiversePrompting.

## Alternative Aggregation Strategies

**Table 5: Alternative aggregation strategies. Observe that, for the AQuA-RAT benchmark (FS-CoT), IDiv-Se produces more accurate results only with GPT-3.5.**

| Method          | GPT-4 (%) | GPT-3.5 (%) |
| --------------- | --------- | ----------- |
| Majority Voting | **79.90** | 64.47       |
| Meta Reasoning  | 79.24     | **67.70**   |

Our aggregation thus far relies on majority voting. Alternatively, we can also utilize the meta reasoning technique proposed by Yoran et al. [yoran2023answering] to accumulate the results and exploit the rich information present in the reasoning steps. To this end, we store the responses generated by IDiv-Se, and request the model to meta reason over them in a different prompt and session. Table 5 suggests that the proposed reasoning paths contain rich information that is effectively exploited by the meta reasoning aggregation. Future post-hoc techniques may consider to learn the accuracy of the diverse prompting approaches, and weigh them accordingly. Nevertheless, the fact that techniques presented here provide visible improvements even with simple approaches like majority voting, demonstrates their added value independently from different aggregation algorithms.

# Related Work

Pryzant et al. [pryzant2023automatic] models the prompts as optimizable discrete variables, and minimizes the loss of the reasoning task. Jones et al. [jones2023automatically] optimize over the prompt space, but to identify failure modes. However, optimization-based approaches often require the task to have a differentiable loss function, which is a strong condition. In our work, we utilize feedback from the LLM (not through gradients) during prompt design. Similarly to Cheng et al. [cheng2023batch], IDiv-Se batches the responses for multiple queries within a prompt.

Wang et al. [wang2023selfconsistency] replace the naive greedy decoding by sampling a diverse set of reasoning paths (e.g., through temperature sampling), and then selects the most consistent answer. Chen et al. [chen2022program] express the reasoning process as a program, which is then delegated to an external tool. In our work, we neither change the decoding process nor assume the existence of trusted tools. This makes our solution directly applicable to black-box models.

Brown et al. [brown2020language] note that demonstrations to prompts, encoded as input-output pairs, produce drastic performance increase in larger LLMs. Wei et al. [wei2022chain] encourage internal dialogue by forcing the LLM to generate a sequence of intermediate steps for reasoning problems. This improves reasoning performance on larger LLMs [nye2021show; chung2022scaling; kojima2022large]. Zhou et al. [zhou2022least] automatically break a complex problem into simpler sub-problems and then solve them in sequence. Across all these techniques, the common practice is to keep the prompts fixed, but aggregate responses across multiple trials by varying the temperature. In our work, we vary the input prompt itself. A work that is similar in spirit is that of Yoran et al. [yoran2023answering], which instead of aggregating the response of multiple reasoning paths, forces the model to reason across them before aggregation. Another relevant work is that of Li et al. [li2023making], which shows the importance of prompt diversity. However, they rely on selecting few-shot demonstrations from a hold-out set (which defines diversity in their method), without explicitly stating reasoning pathways.

# Conclusions

In this work, we promoted diversity of thought as a principled prompting strategy and proposed methodologies that leverage the LLM as a guide to design a diverse set of approaches to solve complex reasoning tasks. Extracting solution approaches from LLMs themselves becomes a discovery mechanism that seeds and conditions generative solutions. Reported results on a variety of tasks confirm that there is a large space for improvement in complex reasoning by uncovering the necessary skills and knowledge from LLMs through targeted and diverse prompting methods. These results demonstrated how promoting diversity can improve the Pareto frontier of accuracy-cost trade-off for current LLMs and yield _state-of-the-art_ solutions for planning and mathematical reasoning tasks. We hope that future work will expand these results to complex tasks from other real-world applications.

# Limitations

Our study mainly experimented with GPT-3.5 and GPT-4 models because of their instruction-following capabilities. While current open-source models have shown remarkable improvements to this end, they are still not able to reliably follow instructions relevant to complex reasoning tasks (e.g. state tracking, plan validity, constraint satisfaction). We hope that progress in the field will enable further experimentation in this direction.

In addition, we also observe that error propagation during autoregressive generation may sometimes negatively impact the performance of IDiv-Se, where all approaches are executed in order within the same prompt. Some of this could be addressed by explicitly instructing the model to forget about the previous solution but ultimately as long as previous generation history remains in context and short-term memory, error propagation risks may still need to be tracked and measured.

# Appendix

# Prompt used for DiversePrompting

Our diverse prompting strategy for IDiv-Se and Div-Se is showcased in Fig. 2 and Fig. 3 respectively. The instrumental prompt template that determines our approaches is presented in Fig. 2.

# Model Details

## Open-Source Models

We perform the Llama-2 70B experiments with a single 80GB A100 GPU. To fit the 70B model to a single A100, we use 8-bit precision through `bitsandbytes` [dettmers2022llm; dettmers2022optimizers]. Further, Dettmers et al. [dettmers2022llm] reports no performance drop with this quantization method.

As the system prompt, we use `You are a helpful, respectful and honest assistant.` We perform inference with greedy decoding, having temperature `latex $T = 0$ `.

# Additional Results

In this section, we provide additional results on CommonsenseQA and GSM8K benchmarks.

## Common sense via CommonsenseQA

Table 2 presents the results of the experiments. Overall, the improvements in accuracy are relatively modest. This is likely because answering questions in CommonsenseQA does not demand as much reasoning and thought diversity as is required in some other benchmarks. In addition, the dataset also contains a number of ambiguous questions, which if read verbatim may have many plausible answers but the ground truth contains only one answer.

## Arithmetic reasoning via GSM8K

**GPT-4 Results:** As shown in Fig. 4, accuracy on GSM8K have nearly plateaued, with the ZS-CoT and FS-CoT baselines achieving accuracies of 94% and 95% respectively. IDiv-Se does not produce any significant gains in either setting. On the other hand, Div-Se reaches accuracy of 96.3% in both FS-CoT and ZS-CoT settings, providing a modest improvement.

**GPT-3.5 Results:** Here, the gains are more substantial. Compared to the ZS-CoT baseline of 76.11%, IDiv-Se provides an improvement of 5.31 p.p. Div-Se goes a step further, enhancing the accuracy by 10.39 p.p. In the FS-CoT setting, Div-Se posts an accuracy improvement of 7.68 p.p (with a baseline accuracy of 81.4%).

Fig. 2 (rightmost) presents the cost vs. accuracy trade-offs between IDiv-Se, Div-Se, and SC. While the performance of SC does improve with the expansion of reasoning paths, both IDiv-Se and Div-Se offer better trade-offs.

# Evaluating Ensemble Sizes

Figure 4 depicts the average accuracy of different ensemble sizes on GSM8K for both ZS-CoT and FS-CoT settings, utilizing GPT-4 and GPT-3.5. Similarly, Figure 5 demonstrates the average accuracy of various ensemble sizes on AquA for both ZS-CoT and FS-CoT settings, using GPT-4 and GPT-3.5. It is noteworthy that in both AQuA and GSM8K, even an ensemble of size three yields significant performance improvements over the baseline, which we attribute to the high diversity and independence of reasoning paths.

# Prompt Templates

The following section provides a comprehensive visual representation of the prompts used in our study. These prompts, depicted in Figures 7 through 14, were used in different settings and for the planning, AQuA, and graph coloring benchmarks, and incorporate various personas and approaches.

Figure 7 illustrates the prompt used in the baseline run, Figure 8 demonstrates the prompt employed when applying a Finite State Machine approach, Figure 9 depicts the prompt used when incorporating the persona of Alan Turing and an Action Rationale approach, and lastly, Figure 10 shows the prompt used when applying the persona of Alan Turing and the Progressive Block Placement approach in the zero-shot setting for the planning benchmark.

Figure 11 illustrates the algebraic approach, while Figure 12 and Figure 13 demonstrate the prompts incorporating the personas of Alan Turing and Dr. Patel, a renowned mathematician, respectively, in the few-shot-CoT setting for the AQuA benchmark.

In Figure 14 we present the IDiv-Se prompt used in the zero-shot setting for the graph coloring benchmark.

[IMAGE: system_diagram_2.pdf - Div-Se prompting.]

[IMAGE: gsm_turbo_gpt_4.pdf - Average accuracy for different ensemble sizes on GSM8K for ZS-CoT and FS-CoT settings on GPT-4 and GPT-3.5. Note that all graphs are zoomed in.]

[IMAGE: aqua_turbo_gpt_4.pdf - Average accuracy for different ensemble sizes on AQUA-RAT for ZS-CoT and FS-CoT settings on GPT-4 and GPT-3.5. Note that all graphs are zoomed in.]

## Augmentation of Few-shot Examples (Algorithm 1, Step 4)

**Input Prompt:**

Solve the problem accurately using {approach name}.

Question: John found that the average of 15 numbers is 40. If 10 is added to each number then the mean of the numbers
Answer Choices: (A) 50 (B) 45 (C) 65 (D) 78 (E) 64
A: If 10 is added to each number, then the mean of the numbers also increases by 10. So the new mean would be 50. The answer is (A).

Approach <using {approach name}>:

**Augmented Few-shot Examples:**

**Approach <using visualization>:**
To solve this problem using visualization, let's consider the given information and the effect of adding 10 to each number on the average.

1. The average of 15 numbers is 40. This means that the sum of these 15 numbers is 15 \* 40 = 600.
2. Now, we add 10 to each number. Since there are 15 numbers, the total added is 15 \* 10 = 150.
3. The new sum of the 15 numbers is 600 + 150 = 750.
4. To find the new average, we divide the new sum by the number of values, which is 750 / 15 = 50. So, the mean of the numbers after adding 10 to each number is 50. The answer is: (A) 50

**Approach <using logical reasoning>:**
We know that adding the same constant to each number in a set will increase the average by that constant. In this case, we are adding 10 to each number, so the average will increase by 10. New average = 40 + 10 = 50 The answer is: (A) 50

**Approach <using elimination strategy>:**
We know that adding 10 to each number will increase the average by 10. So, we're looking for an answer choice that is 10 more than the original average of 40.
(A) 50 is 10 more than 40.
(B) 45 is only 5 more than 40.
(C) 65 is 25 more than 40.
(D) 78 is 38 more than 40.
(E) 64 is 24 more than 40.
Only (A) 50 is exactly 10 more than the original average of 40, so that's the correct answer. The other choices can be eliminated because they are not 10 more than the original average.

**Approach <using algebra>:**
Let's denote the sum of the 15 numbers as S. Since the average of the 15 numbers is 40, we can write the equation: S / 15 = 40 S = 40 _ 15 = 600 Now, we add 10 to each number, so the new sum is S + 15 _ 10 = 600 + 150 = 750. The new average is: New average = 750 / 15 = 50 The answer is: (A) 50

## Planning Baseline Prompt (Zero-shot)

I am playing with a set of blocks where I need to arrange the blocks into stacks.

[STATEMENT]
As initial conditions I have that, the orange block is clear, the hand is empty, the blue block is on top of the red block, the orange block is on top of the blue block and the red block is on the table. My goal is to have that the red block on top of the blue block and the orange block on top of the red block.

Here are the actions I can do:
Pick up a block from the table
Unstack a block from on top of another block
Put down a block on the table
Stack a block on top of another block

I have the following restrictions on my actions:
I can only pick up or unstack one block at a time.
I can only pick up or unstack a block if my hand is empty.
I can only pick up a block if the block is on the table and the block is clear. A block is clear if the block has no other blocks on top of it and if the block is not picked up.
I can only unstack a block from on top of another block if the block I am unstacking was really on top of the other block.
I can only unstack a block from on top of another block if the block I am unstacking is clear.
Once I pick up or unstack a block, I am holding the block.
I can only put down a block that I am holding.
I can only stack a block on top and not under of another block if I am holding the block being stacked.
I can only stack a block on top and not under of another block if the block onto which I am stacking the block is clear.
Once I put down or stack a block, my hand becomes empty.
Once you stack a block on top of a second block, the second block is no longer clear.

What is the plan to achieve my goal? Just give the actions in the plan.

[PLAN]

## Planning with Finite State Machine Approach (Zero-shot)

You are playing with a set of blocks where you need to arrange the blocks into stacks. What is the plan to achieve the goal?

<Initial State> : As initial conditions you have that, the orange block is clear, the hand is empty, the blue block is on top of the red block, the orange block is on top of the blue block and the red block is on the table.
<Goal State> : Your goal is to have that the red block on top of the blue block and the orange block on top of the red block.

Here are the actions you can do:
-Pick up a block from the table
-Unstack a block from on top of another block
-Put down a block on the table
-Stack a block on top of another block

Rules:

1. You can only pick up or unstack one block at a time.
2. You can only pick up or unstack a block if your hand is empty.
3. You can only pick up a block if the block is on the table and the block is clear. A block is clear if the block has no other blocks on top of it and if the block is not picked up.
4. You can only unstack a block from on top of another block if the block you are unstacking was really on top of the other block.
5. You can only unstack a block from on top of another block if the block you are unstacking is clear.
6. Once you pick up or unstack a block, you are holding the block.
7. You can only put down a block that you are holding.
8. You can only stack a block on top and not under of another block if you are holding the block being stacked.
9. You can only stack a block on top and not under of another block if the block onto which you are stacking the block is clear.
10. Once you put down or stack a block, your hand becomes empty.
11. Once you stack a block on top of a second block, the second block is no longer clear.

Using a finite state machine and a search algorithm what is the plan to achieve the goal? You can model each state of the blocks configuration on the table and the hand as a state. For each action step check that the step follows the rules and that the step brings you closer to the goal. After each action describe the state of the table and hand. Always check whether the final state satisfies the goal mentioned. <Goal State> : Your goal is to have that the red block on top of the blue block and the orange block on top of the red block.

[PLAN]

## Planning with Alan Turing Persona and Action Rationale (Zero-shot)

You are playing with a set of blocks where you need to arrange the blocks into stacks.

<Initial State> : As initial conditions you have that, the orange block is clear, the hand is empty, the blue block is on top of the red block, the orange block is on top of the blue block and the red block is on the table.

<Goal State> : Your goal is to have that the red block on top of the blue block and the orange block on top of the red block.

Here are the actions you can do:
-Pick up a block from the table
-Unstack a block from on top of another block
-Put down a block on the table
-Stack a block on top of another block

Rules:

1. You can only pick up or unstack one block at a time.
2. You can only pick up or unstack a block if your hand is empty.
3. You can only pick up a block if the block is on the table and the block is clear. A block is clear if the block has no other blocks on top of it and if the block is not picked up.
4. You can only unstack a block from on top of another block if the block you are unstacking was really on top of the other block.
5. You can only unstack a block from on top of another block if the block you are unstacking is clear.
6. Once you pick up or unstack a block, you are holding the block.
7. You can only put down a block that you are holding.
8. You can only stack a block on top and not under of another block if you are holding the block being stacked.
9. You can only stack a block on top and not under of another block if the block onto which you are stacking the block is clear.
10. Once you put down or stack a block, your hand becomes empty.
11. Once you stack a block on top of a second block, the second block is no longer clear.

Thinking like Alan Turing starting from the <Initial State> build a plan to get to the <Goal State>. For each action step carefully check that the step follows the rules. <Goal State> : Your goal is to have that the red block on top of the blue block and the orange block on top of the red block.

output format for each step until you reach the goal state:
<state> : <state>
<action> : < action to be performed in this step >
<assess the action> : < are we building the stack bottom up, check carefully>

## Planning with Alan Turing Persona and Progressive Block Placement (Zero-shot)

You are playing with a set of blocks where you need to arrange the blocks into stacks.

<Initial State> : As initial conditions you have that, the orange block is clear, the hand is empty, the blue block is on top of the red block, the orange block is on top of the blue block and the red block is on the table.
<Goal State> : Your goal is to have that the red block on top of the blue block and the orange block on top of the red block.

Here are the actions you can do:
-Pick up a block from the table
-Unstack a block from on top of another block
-Put down a block on the table
-Stack a block on top of another block

Rules:

1. You can only pick up or unstack one block at a time.
2. You can only pick up or unstack a block if your hand is empty.
3. You can only pick up a block if the block is on the table and the block is clear. A block is clear if the block has no other blocks on top of it and if the block is not picked up.
4. You can only unstack a block from on top of another block if the block you are unstacking was really on top of the other block.
5. You can only unstack a block from on top of another block if the block you are unstacking is clear.
6. Once you pick up or unstack a block, you are holding the block.
7. You can only put down a block that you are holding.
8. You can only stack a block on top and not under of another block if you are holding the block being stacked.
9. You can only stack a block on top and not under of another block if the block onto which you are stacking the block is clear.
10. Once you put down or stack a block, your hand becomes empty.
11. Once you stack a block on top of a second block, the second block is no longer clear.

Thinking like Alan Turing, starting from the <Initial State> build a plan to get to the <Goal State> . For each action step carefully check that the step follows the rules. Divide the task into smaller steps, starting with placing the bottom block first, followed by the middle blocks, and finally the top block. <Goal State> : Your goal is to have that the red block on top of the blue block and the orange block on top of the red block.

[PLAN]

## AQuA Few-shot-CoT with Algebraic Approach

As a math professor, you will solve the given problem accurately '<using algebra>'. If there is no exact match choose the closest option.

Question: John found that the average of 15 numbers is 40. If 10 is added to each number then the mean of the numbers
Answer Choices: (A) 50 (B) 45 (C) 65 (D) 78 (E) 64
Approach: <using algebra>
Let's denote the sum of the 15 numbers as S. Since the average of the 15 numbers is 40, we can write the equation: S / 15 = 40 S = 40 _ 15 = 600 Now, we add 10 to each number, so the new sum is S + 15 _ 10 = 600 + 150 = 750. The new average is: New average = 750 / 15 = 50
The answer is: (A) 50

Question: If a / b = 3/4 and 8a + 5b = 22,then find the value of a.
Answer Choices: (A) 1/2 (B) 3/2 (C) 5/2 (D) 4/2 (E) 7/2
Approach: <using algebra>
To solve the given problem, we can use substitution. Since a / b = 3/4, we can write that as: a = 3b/4 Now, substitute this expression for a into the second equation: 8(3b/4) + 5b = 22 Simplify and solve for b: 6b + 5b = 22 11b = 22 b = 2 Now that we have the value of b, we can find the value of a: a = 3b/4 a = 3(2)/4 a = 6/4 a = 3/2 So, the value of a is (B) 3/2.
The answer is: (B) 3/2

Question: A person is traveling at 20 km/hr and reached his destiny in 2.5 hr then find the distance?
Answer Choices: (a) 53 km (b) 55 km (c) 52 km (d) 60 km (e) 50 km
Approach: <using algebra>
Using the formula distance = speed x time, we can calculate the distance as follows: Distance = 20 km/hr x 2.5 hr = 50 km So, the closest answer choice is (e) 50 km.
The answer is: (e) 50 km

Question: How many keystrokes are needed to type the numbers from 1 to 500?
Answer Choices: (a) 1156 (b) 1392 (c) 1480 (d) 1562 (e) 1788
Approach: <using algebra>
Let's break down the number of keystrokes needed into groups based on the number of digits: One-digit numbers (1-9): There are 9 one-digit numbers, so we need 9 keystrokes. Two-digit numbers (10-99): There are 90 two-digit numbers, each requiring 2 keystrokes, so we need 90 _ 2 = 180 keystrokes. Three-digit numbers (100-500): There are 401 three-digit numbers (500 - 100 + 1), each requiring 3 keystrokes, so we need 401 _ 3 = 1203 keystrokes. Now let's add up the keystrokes from all groups: 9 + 180 + 1203 = 1392. Therefore, the closest option is (b) 1392.
The answer is: (b) 1392

## AQuA Few-shot-CoT with Alan Turing Persona

Think like Alan Turing and solve the problem. If there is no exact match choose the closest option.

Question: John found that the average of 15 numbers is 40. If 10 is added to each number then the mean of the numbers
Answer Choices: (A) 50 (B) 45 (C) 65 (D) 78 (E) 64
Approach : <think like Alan Turing>
Let's analyze the problem step by step: The average of 15 numbers is 40. So, the sum of these 15 numbers is 15 _ 40 = 600. 10 is added to each number. Now, since there are 15 numbers, the total increase in the sum will be 15 _ 10 = 150. The new sum of these 15 numbers will be 600 + 150 = 750. To find the new mean, divide the new sum by the total number of values, which is 15. New mean = 750 / 15 = 50. Therefore, the closest option to the new mean is (A) 50.
The answer is: (A) 50

Question: If a / b = 3/4 and 8a + 5b = 22,then find the value of a.
Answer Choices: (A) 1/2 (B) 3/2 (C) 5/2 (D) 4/2 (E) 7/2
Approach : <think like Alan Turing>
Let us analyze the given information and solve the problem step by step. We are given that a / b = 3/4, which can be written as a = (3/4) _ b. We are also given the equation 8a + 5b = 22. Substitute the value of a from step 1 into the equation from step 2: 8 _ (3/4) _ b + 5b = 22 Simplify the equation: 6b + 5b = 22 Combine the terms and solve for b: 11b = 22 b = 2 Now that we have the value of b, let's find the value of a using the equation from step 1: a = (3/4) _ b a = (3/4) \* 2 Simplify to find the value of a: a = 3/2 Thus, the value of a is 3/2, which corresponds to answer choice (B).
The answer is: (B)

Question: A person is traveling at 20 km/hr and reached his destiny in 2.5 hr then find the distance?
Answer Choices: (a) 53 km (b) 55 km (c) 52 km (d) 60 km (e) 50 km
Approach : <think like Alan Turing>
To find the distance, we can use the formula: distance = speed x time. In this case, the speed is 20 km/hr and the time is 2.5 hours. Distance = 20 km/hr x 2.5 hr = 50 km So, the closest option is (e) 50 km.
The answer is: (e) 50 km

Question: How many keystrokes are needed to type the numbers from 1 to 500?
Answer Choices: (a) 1156 (b) 1392 (c) 1480 (d) 1562 (e) 1788
Approach : <think like Alan Turing>
To determine the number of keystrokes needed to type the numbers from 1 to 500, let's break it down by digit count: One-digit numbers (1-9): There are 9 one-digit numbers, each requiring 1 keystroke. Total: 9 keystrokes. Two-digit numbers (10-99): There are 90 two-digit numbers, each requiring 2 keystrokes. Total: 90 _ 2 = 180 keystrokes. Three-digit numbers (100-500): There are 401 three-digit numbers, each requiring 3 keystrokes. Total: 401 _ 3 = 1203 keystrokes. Adding the keystrokes for each group, we get: 9 + 180 + 1203 = 1392 keystrokes. Thus, the closest option is (b) 1392
The answer is: (b) 1392

## AQuA Few-shot-CoT with Dr. Patel Persona

Think like Dr. Patel, the mathematician who specializes in algebra and solve the problem. If there is no exact match choose the closest option.

Question: John found that the average of 15 numbers is 40. If 10 is added to each number then the mean of the numbers
Answer Choices: (A) 50 (B) 45 (C) 65 (D) 78 (E) 64
Approach : <think like Dr. Patel>
Let's consider the problem step by step. John found that the average of 15 numbers is 40. To find the sum of these 15 numbers, we can use the formula: Sum = Average x Number of elements Sum = 40 x 15 Sum = 600 Now, 10 is added to each of the 15 numbers. So, we can find the new sum by adding 10 x 15 = 150 to the original sum: New Sum = 600 + 150 New Sum = 750 To find the new average (mean), we can use the formula: New Average = New Sum / Number of elements New Average = 750 / 15 New Average = 50
The answer is: (A) 50

Question: If a / b = 3/4 and 8a + 5b = 22,then find the value of a.
Answer Choices: (A) 1/2 (B) 3/2 (C) 5/2 (D) 4/2 (E) 7/2
Approach : <think like Dr. Patel>
To solve this problem, first we can rewrite the equation a / b = 3/4 as a = (3/4)b. Now we can substitute this expression for a into the second equation: 8a + 5b = 22. Substitute a with (3/4)b: 8(3/4)b + 5b = 22 Simplify the equation: 6b + 5b = 22 Combine the terms: 11b = 22 Now, divide both sides by 11: b = 2 Now that we have the value of b, we can find the value of a using the equation a = (3/4)b: a = (3/4)(2) a = 3/2 The value of a is 3/2. So, the correct answer is (B) 3/2.
The answer is: (B) 3/2

Question: A person is traveling at 20 km/hr and reached his destiny in 2.5 hr then find the distance?
Answer Choices: (a) 53 km (b) 55 km (c) 52 km (d) 60 km (e) 50 km
Approach : <think like Dr. Patel>
To find the distance, we can use the formula: Distance = Speed x Time Here, the speed is given as 20 km/hr and the time taken is 2.5 hours. So, we can plug these values into the formula: Distance = 20 km/hr x 2.5 hr Distance = 50 km
The answer is: (e) 50 km

Question: How many keystrokes are needed to type the numbers from 1 to 500?
Answer Choices: (a) 1156 (b) 1392 (c) 1480 (d) 1562 (e) 1788
Approach : <think like Dr. Patel>
To determine the number of keystrokes needed to type the numbers from 1 to 500, let's break down the problem by analyzing the number of digits in each range: For numbers 1-9, there are 9 numbers with 1 digit each, requiring 9 keystrokes. For numbers 10-99, there are 90 numbers with 2 digits each, requiring 90 _ 2 = 180 keystrokes. For numbers 100-499, there are 400 numbers with 3 digits each, requiring 400 _ 3 = 1200 keystrokes. For the number 500, it has 3 digits, requiring 3 keystrokes. Now, we can sum up the keystrokes for each range: 9 (for 1-9) + 180 (for 10-99) + 1200 (for 100-499) + 3 (for 500) = 1392 keystrokes.
The answer is: (b) 1392

## Graph Coloring Prompt (Zero-shot with Programming Approach)

As a math professor, use 3 distinct approaches and without using built-in algorithms, write python programs to color the following graph, described as a set of edges, such that no two vertices on the same edge share a color.

You may use at most 3 colors.
Vertex 0 is connected to vertex 7.
Vertex 0 is connected to vertex 8.
Vertex 0 is connected to vertex 9.
Vertex 0 is connected to vertex 11.
Vertex 1 is connected to vertex 13.
Vertex 2 is connected to vertex 9.
Vertex 3 is connected to vertex 8.
Vertex 3 is connected to vertex 11.
Vertex 3 is connected to vertex 12.
Vertex 4 is connected to vertex 12.
Vertex 5 is connected to vertex 11.
Vertex 6 is connected to vertex 9.
Vertex 7 is connected to vertex 10.
Vertex 7 is connected to vertex 13.
Vertex 9 is connected to vertex 11.
Vertex 10 is connected to vertex 13.
Vertex 11 is connected to vertex 13.
There are a total of 14 vertices. Please label every vertex, even if it is disconnected from the rest of the graph. Please provide each vertex's color. Do not skip any vertices. Each color must be provided on a new line in the response and should be formatted as "VERTEX NUMBER: VERTEX COLOR ASSIGNMENT (Color n)".

Output format:
Approach 1 <name of the approach> : < python program from scratch to color the given graph accurately >
Approach 2 <name of the approach> : < python program from scratch to color the given graph accurately>
Approach 3 <name of the approach> : < python program from scratch to color the given graph accurately>

---

**Notes:**

- In practice, we set c=100, b=5, n in {3, 5}, and |V| < 20.
- For a given reasoning task, we perform this process once (for GPT-3.5 Turbo), and re-use our selection across all LLMs we evaluate.
- Token pricing information: https://openai.com/pricing
