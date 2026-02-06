# Abstract

Self-reflection for Large Language Models (LLMs) has gained significant attention. Existing approaches involve models iterating and improving their previous responses based on LLMs' internal reflection ability or external feedback. However, recent research has raised doubts about whether intrinsic self-correction without external feedback may even degrade performance. Based on our empirical evidence, we find that current static reflection methods may lead to redundant, drift, and stubborn issues. To mitigate this, we introduce **I**nstruct-**o**f-**R**eflec**t**ion (**IoRT**), a novel and general reflection framework that leverages dynamic-meta instruction to enhance the iterative reflection capability of LLMs. Specifically, we propose the instructor driven by the meta-thoughts and self-consistency classifier, generates various instructions, including refresh, stop, and select, to guide the next reflection iteration. Our experiments demonstrate that IoRT achieves an average improvement of 10.1% over established baselines in mathematical and commonsense reasoning tasks, highlighting its efficacy and applicability. Our code is available at <https://github.com/llp635/IoRT>.

# Introduction

Large language models (LLMs) [touvron2023llama; achiam2023gpt; anil2023palm; TheC3] have demonstrated remarkable capabilities across various natural language processing tasks [bai2022training; wei2022emergent; chu2023survey], particularly when leveraging a range of prompting strategies such as Chain-of-Thought [wei2022chain] which improve the reasoning ability of LLMs without increasing model parameters [rae2021scaling; srivastava2023beyond; yin-etal-2023-exchange]. Inspired by how humans iteratively refine their written text [10.5555/3666122.3668141], the concept of "self-correction" [welleck2023generating] has been proposed and garnered extensive attention where LLMs first generate an initial response, then gather feedback to refine previous responses [ganguli2023capacity; xi2023self; paul2024refiner]. However, recent studies [huanglarge; zhang-etal-2024-self-contrast] raise two doubts about the self-correction capabilities of LLMs: First, [kim2024language; shinn2023reflexion] use oracle labels regarding the answer correctness to guide the self-correction process. However, in practice, the availability of oracle labels seems counter-intuitive because there seems to be little reason to deploy LLMs for problem solving if the ground truth is already known. Second, without any external or human feedback, the performance after LLMs' intrinsic self-correction even deteriorates.

[IMAGE: Prior reflection research is primarily based on static iterative strategies, which face issues of redundancy, drift, and stubborn. (Figure 1)]

Our research also focuses on the reflective capabilities of LLMs. Unlike previous studies that primarily investigate performance changes in intrinsic reflection, we explore whether the performance of LLMs in reflection deteriorates when external feedback is available. Therefore, in our exploration experiments, we evaluate the performance of CRITIC [gou2024critic], which leverages the results of tool interactions as external feedback, enabling a systematic investigation of how this feedback impacts the performance of reflection. Our findings (Section 3.1) indicate that neither intrinsic self-correction nor CRITIC performs satisfactorily. To investigate the reasons behind that, we comprehensively analyze the performance across multiple iterations of reflection, which is different from prior research focusing on a single reflection. Figure 1 shows that the i_th reflection is derived from the (i-1)\_th response, this static iterative reflection leads to three issues: 1) **Redundant** (correct -> correct): Although it does not alter accuracy in iterations, it does increase overhead. 2) **Drift** (correct -> **incorrect**): Self-correction is highly random, undermining both accuracy and reliability. 3) **Stubborn** (**incorrect** -> **incorrect**): LLMs consistently persist in errors, failing to properly identify and correct potential mistakes. Additionally, we found that the prevalence of these three issues varies across different LLMs and tasks.

As a remedy to these challenges, we propose Instruct of Reflection (IoRT), an efficient and dynamic iterative reflection framework designed to continuously optimize the reflection process. The framework including three stages: (i) meta-thinker generates meta-thoughts, (ii) refreshing to generate an initial response, and reflector to self-reflect based on feedback. (iii) instruct the iteration. Notably, aiming to mitigate redundant, drift, and stubborn issues, in the third stage, the instructor, augmented by meta-thought and driven by the self-consistency classifier, generates refresh, stop, or select instructions to direct the next reflection iteration. Specifically, when the Instructor determines that both responses have correctly addressed the problem, it generates a stop instruction to promptly halt the reflection process, effectively reducing redundancy. If the instructor assesses that both answers are incorrect, it generates a refresh instruction, helping the LLMs prevent stubbornness. In cases where answers are inconsistent, the instructor selects the more optimal response as the output of the current iteration and the foundation for the next reflection, thereby reducing drift and improving performance accuracy.

We evaluate the performance of IoRT across various LLMs and two distinct tasks: mathematical reasoning and commonsense reasoning. The result demonstrates that IoRT outperforms baselines on established strong baselines, underscoring the critical role of the instructor in augmenting the iterative reflection capabilities of LLMs. Our main contributions can be summarized as follows:

- Our exploration experiments reveal that LLMs struggle to correct previous errors. The static iterative reflection suffers from redundant, drift, and stubborn, which may increase overhead or even deteriorate performance.

- We propose Instruct-of-Reflection (IoRT), a dynamic iterative reflection framework that integrates abstract reasoning into the reflection process, adaptively generating different instruction to regulate the reflection process.

- Experimental results on three datasets and five different LLMs underscore the efficacy, overhead efficiency, and generality of IoRT. Additionally, without relying on any oracle labels, IoRT demonstrates its practicality.

# Related Works

## Prompt-based Reasoning

To exploit the reasoning ability in LLMs, [wei2022chain] proposes Chain-of-Thought (CoT) prompting which guides the model to generate a series of text describing reasoning steps before reaching the final answer. Subsequently, [chen2022program] introduces Program-of-Thoughts (PoT) prompting which uses llms to generate programming language statements. In recent years, the self-correction capabilities of LLMs have garnered significant attention, with LLMs expected to iteratively improve their previous responses based on feedback [bai2022constitutionalaiharmlessnessai]. Existing studies on self-correction can be categorized into two types based on the feedback source: external feedback and internal feedback [pan2024automatically]. Internal feedback relies on the model's inherent knowledge and parameters, while external feedback involves inputs from humans, other models [wang2023shepherd; paul-etal-2024-refiner], or external tools and knowledge sources [chenteaching; olausson2023demystifying; gao2023rarr]. We comprehensively evaluate the performance of CRITIC [gou2024critic], which leverages specialized tools, such as code executors, to evaluate and reflect on the external feedback obtained through its interactions with these tools. However, recent studies [huanglarge; stechly2023gpt; valmeekam2023can; zhang-etal-2024-self-contrast] cast doubt on the ability of LLMs to correct previous responses based solely on their inherent reflection capacity. Additionally, research on reflection with external feedback [10.5555/3666122.3667845; shinn2023reflexion] have been doubted on using oracle labels which are are often unavailable in practice to determine when to stop the self-correction loop during the reflection. The improvements vanish when the reflection no longer relies on oracle labels [huanglarge]. Apart from these studies questioning the use of oracle in self-reflection during the iterative reflection process, we also observe that improvements in [gou2024critic] stem from using oracle labels to correct only the incorrect samples during evaluation. Unlike previous findings, we observe that both intrinsic self-correction and external feedback can lead to a deterioration in performance after reflection. Additionally, our proposed Instruct of Reflection Tool (IoRT) diverges from existing reflection methods by emphasizing continuous performance optimization through diverse instructional guidance. We design the instructor to guide the next reflection iteration without relying on oracle labels.

## Abstract Reasoning

Instead of addressing the problems directly, abstract reasoning relies on higher-level thoughts to guide thinking [zhengtake], making it essential for sophisticated cognitive processing in artificial intelligence systems [lake2017building; chollet2019measure; qiuphenomenal]. For example, consider the question "What are the roots of a quadratic equation?" Abstract reasoning involves extracting the fundamental principle of "the quadratic equation root formula" and applying this principle to this specific question. [zhengtake] uses the concepts and principles to guide reasoning by taking a step back. [fu2024hint] guides the model to generate hints such as specific knowledge or key ideas. [xiong2024meaningful] designs a preliminary study to quantify and delve into the abstract reasoning abilities of LLMs. [yang2024buffer] adapts by refining or retrieving high-level thought templates to instantiate specific reasoning structures. In our research, we build on [fu2024hint] to generate meta-thoughts, thereby enhancing the abstract reasoning abilities of the reflective instructor. In contrast to the above works, which obtain an initial response through abstract reasoning, we incorporate abstract reasoning into the reflection process by designing the instructor within our framework.

# Empirical Evidence for Iterative Reflection

[IMAGE: Compare the performance changes of self-correct and CRITIC during iterative reflection across two datasets, evaluating with and without Oracle. (Figure 2)]

Prior research primarily focuses on performance changes in a single reflection, which fails to fully capture the potential of reflection for long-term improvements. To gain deeper insights into how reflection can gradually refine answers, We comprehensively evaluate the performance changes of self-correct and CRITIC [gou2024critic] across multiple reflection iterations [huanglarge].

## Performance of Iterative Reflection

We systematically evaluate the performance of self-correct (w/o external feedback) and CRITIC (w/ tool interactions as an available external feedback) across multiple iterative reflections on the GSM8K and SVAMP datasets with GPT-3.5. Additionally, we simulate an evaluation method (w/ oracle) that relies on oracle labels, focusing only on corrections from incorrect to correct answers in each iteration, while disregarding instances where correct answers are modified into incorrect ones.

In Figure 2, evaluating reflection using oracle labels, the accuracy of both self-correct and CRITIC improves steadily with each iteration. In contrast, without oracle labels, the performance is unstable and even deteriorate, regardless of the availability of external feedback. For instance, on GSM8K and SVAMP, the performances of self-correct and CRITIC drop by up to -2.4% and -3.0%, respectively. Notably, compared to self-correct, the performance is more reliable with CRITIC.

## Further Performance Analysis

Why does performance degrade after reflection? To investigate this question, we further conduct the following analysis:

**Step 1**: We classify all samples in GSM8K into four categories based on the correctness before and after reflection. Then analyze the performance changes in each iteration using self-correct and CRITIC on GPT-3.5. **Step 2**: We classify all samples into four categories based on the consistency and correctness of the answers throughout all iterations: 1) _Redundant Iteration_ means the answers consistently remain correct. 2) _Invalid Consistent Iteration_ insists on a consistent wrong answer. 3) _Drift Iteration_ generates both incorrect and correct during the iterative reflection. 4) _Invalid Inconsistent Iteration_ continuous changes occur in iterations without ever converging to the correct solution. The detailed results are as follows:

[IMAGE: Analyze the different types of iteration of CRITIC on GSM8K. (Figure 3)]

**Reflection can not only be beneficial but also detrimental.** As shown in Table 3, for both self-correct and CRITIC, the proportion of correct -> **incorrect** is often comparable to or even exceeds that of **incorrect** -> correct, which explains the performance degradation after reflection. Notably, CRITIC demonstrates a lower ratio of correct -> **incorrect** compared to self-correct, suggesting that external feedback promotes the stability of the reflection.

**Models of different sizes yield varying reflection performance.** In Figure 3, significant differences in reflection performance are observed across various LLMs. For instance, GPT-4 shows a 94.3% share of stable iterations, while 89% of LLaMA-2 7B's iterations are unstable. It implies that larger models like GPT-4, benefiting from vast training data and substantial computational resources [ouyang2022training; chowdhery2023palm; chung2024scaling], exhibit more stable performance compared to smaller models.

**Various reflective iterations correspond to different limitations.** As shown in Figure 1, LLMs often perform the i_th reflection based on the (i-1)\_th response, and this static iterative reflection highlights the following three limitations: I. _Redundant Iteration -> Redundant_: Although redundant iterations do not affect accuracy, they contribute to unnecessary costs and delays. II. _Drift Iteration -> Drift_: Especially, correct -> **incorrect** indicates that LLMs often exhibit a high degree of uncertainty, leading to reflection drift and a decline in accuracy. III. _Invalid iteration -> Stubborn_: LLMs are too stubborn to recognize and correct mistakes. Our method effectively addresses these three issues, achieving optimization of accuracy and efficiency in reflection during iterations.

[IMAGE: IoRT comprises three steps: (1) generate meta-thoughts, (2) refresh and self-reflect, and (3) instruct the iteration. Repeat steps 8 to 14 after each iteration until the instructor signals to stop or the maximum iterations N is reached. (Figure 4)]

# Instruct-of-Reflection (IoRT)

Prior sections illustrate the challenges LLMs encounter in static iterative reflection such as redundancy, drift and stubborn. How to precisely identify effective reflections while mitigating the impact of harmful or redundant reflections? As a remedy, we innovatively propose Instruct-of-Reflection (IoRT), a novel framework that implements dynamic-meta instruction for the iterative reflection process. We can get an overview of the IoRT framework in Figure 4. Specifically, IoRT involves three main steps: generate meta-thoughts, refresh and self-reflect, and instruct the iteration. As the core module, the instructor is augmented by meta-thoughts and driven by self-consistency classifier, generating instructions including refresh, stop, and select, directing the next reflection iteration.

## Generate Meta Thoughts

Human often summarize and abstract higher-level ideas when solving problems [yang2024buffer]. Inspired by Hint-before-Solving Prompting (HSP) [fu2024hint] and Meta-Reasoning [zeng2024mrgsm8kmetareasoningbenchmarklarge], we propose meta-thinker which enables LLMs to explicitly generate meta-thoughts through a few-shot learning for problem solving. Meta-thoughts are high-level knowledge based on abstract reasoning, encompassing analytical methods and fundamental overall strategies. They enhance the instructor's role as a teacher by providing a comprehensive overview of the reflection process. For instance, for the question "Can a honey bee sting a human more than once?", since the bee's stinger is closely related to its ability to sting, the meta-thought for this question primarily focuses on the basic principle of the "changes in the stinger". The meta memory module stores meta-thoughts, distilled from various tasks, recorded in the form of `latex $\mathcal{E} = \{(q_i, m_i)\}$ `, expressing them as a pair relationship `latex $e_i$ = ($q_i$, $m_i$) `, where `latex $q_i$ ` represents the question statement and `latex $m_i$ ` represents the meta-thought associated with solving question `latex $q_i$ `.

Specifically, meta-thoughts construction includes 4 steps. **Initialization**: for each dataset, we randomly select k questions and manually define their meta-thoughts as shown in Table [table:dataset] to initialize the meta-thought module. **Retrieval**: For the input question x, meta-thinker retrieves the k most relevant prompt examples by applying the cosine similarity function `latex $S(q_i, x)$ ` to calculate the embedding similarity between the questions `latex $q_i$ ` and x, the top k questions and their corresponding meta-thoughts set are identified:

```latex
$$\{e^{1}_{\text{sim}}, e^{2}_{\text{sim}}, \dots, e^{k}_{\text{sim}}\} = \underset{q_i \in M}{\text{argmax}} \, S(q_i, x)$$
```

```latex
$$S(q_i, x) = \frac{\mathbf{q_i} \cdot \mathbf{x}}{\|\mathbf{q_i}\| \|\mathbf{x}\|}$$
```

**Generation**: Based on these k similar questions and their corresponding meta-thoughts, meta-thinker employs a model `latex $f(\cdot)$ ` to generate meta-thought `latex $m_x$ ` for the question x through few-shot learning, which can be expressed as:

```latex
$$m_x = f\left(e^{1}_{\text{sim}}, e^{2}_{\text{sim}}, \dots, e^{k}_{\text{sim}}, x\right)$$
```

**Updating**: The new meta-thought `latex $m_x$ ` not only enhances the instructor's abstract reasoning capabilities but also facilitates the updating of the meta-memory module, which continuously evolves by accumulating meta-thoughts for problem solving, thereby enabling more efficient and intelligent reasoning. In this context, the update of `latex $\mathcal{E}$ ` can be formulated as:

```latex
$$\mathcal{E} \leftarrow \mathcal{E} \cup \{(x, m_x)\}$$
```

## Refresh and Self-Reflect

In the refresh process, given a black-box LLM `latex $g(\cdot)$ ` and a question x, the LLM utilizes its few-shot contextual learning ability to generate an initial output response `latex $R^{0}_{o}$ `. In the i*th iteration, we extracted the basic answer ```latex $A^{i}*{b}$ `from the basic response`latex $R^{i}_{b}$ `. The specifics of answer extraction from the response are elaborated in Appendix 8. The reflector assesses the quality of `latex $R^{i}_{b}$ `using evaluation metrics such as plausibility and correctness, and provides feedback accordingly. Based on the input question x, the basic response`latex $R^{i}_{b}$ `, the basic answer `latex $A^{i}_{b}$ `and the evaluation feedback`latex $f_i$ `, a reflective response `latex $R^{i}_{r}$ ``` is generated as follows:

```latex
$$R^{i}_{r} = g(x, R^{i}_{b},A^{i}_{b}, f_i)$$
```

## Instruct the Iteration

As analyzed in (Section 3), the answers after reflection may improve, degrade, or remain unchanged. Therefore, we design the instructor to manage the reflection process, ensuring stable performance improvement throughout the iterative reflection.

**Meta-Thought Augment Instructor** We incorporate the meta-thought `latex $m_x$ ` into the instructor's prompt. During decision-making, the instructor treats the meta-thought as a critical evaluation criterion. By emphasizing abstract reasoning, the meta-thought elevates the LLMs from simply solving problems to instructing the process. This approach enables a more holistic evaluation of responses during each iteration, ensuring that the instructor's decisions not only satisfy problem-specific requirements but also undergo rigorous analysis.

**Self-Consistency Classifier** Does not use any LLM, self-consistency classifier determines consistency by comparing whether the basic answer `latex $A^{i}_{b}$ ` and the reflective answer `latex $A^{i}_{r}$ ` are equal. We implement a self-consistency classifier to evaluate the quality of responses, providing feedback to the instructor to guide decision-making. Based on the following three scenarios, the instructor generates a select, stop or refresh instruction:

- **Select Instruction** If `latex $A^{i}_{b} \neq A^{i}_{r}$ `, it suggests that at least one of the responses is incorrect. The instructor carefully evaluates both `latex $R^{i}_{b}$ ` and `latex $R^{i}_{r}$ ` based on the meta-thought `latex $m_x$ `, and then selects the better response from them as `latex $R^{i}_{o}$ ` represented as the output for the i*th iteration. Concurrently, ```latex $R^{i+1}*{b}$ `is updated to`latex $R^{i}_{o}$ ```, represented as:

  ```latex
  $$R^{i}_{o} = \text{Instructor}(R^{i}_{b}, A^{i}_{b}, R^{i}_{r}, A^{i}_{r}, m_x, x)$$
  ```

  If `latex $A^{i}_{\text{b}}=A^{i}_{r}$ `, it indicates that the reflection did not change the output, we designate `latex $R^{i}_{b}$ ` as the output for the i*th iteration ```latex $R^{i}*{o}$ `. The Instructor will evaluates both `latex $R^{i}_{b}$ `and`latex $R^{i}_{r}$ ``` to determine whether to issue a stop or refresh instruction:

- **Stop Instruction** If the Instructor deems both `latex $R^{i}_{b}$ ` and `latex $R^{i}_{r}$ ` reasonable for solving the problem, a stop instruction is issued, and the iteration concludes at the i_th round. In our experiments, we set the maximum number of iterations to N. To ensure comprehensive evaluation, all subsequent iterations are set equal to the response from the i_th iteration, represented as:

  ```latex
  $$R^{N}_{o}, R^{(N-1)}_{o}, \ldots, R^{(i+1)}_{o} \!= R^{i}_{o}$$
  ```

- **Refresh Instruction** If `latex $R^{i}_{b}$ ` and `latex $R^{i}_{r}$ ` fail to resolve the problem, in the (i+1)_th iteration, a black-box LLM `latex $g(\cdot)$ ` will generate a new response to update ```latex $R^{(i+1)}_{r}$ `. `latex $R^{(i+1)}_{b}$ `is set equal to`latex $R^{i}_{b}$ `. IoRT will then compare `latex $R^{(i+1)}_{b}$ `and`latex $R^{(i+1)}_{r}$ ``` once again. Such invalid iterations can trap the model in a resource-intensive loop. By refreshing, we break this deadlock and introduce new ideas, enabling the model to generate more effective solutions.

# Experiments

## Experimental Setup

**Benchmark** We evaluated our method in two reasoning scenarios: mathematical reasoning and commonsense reasoning. Specifically, for commonsense reasoning, we use the StrategyQA [geva-etal-2021-aristotle], while for mathematical reasoning, we use GSM8K [cobbe2021training] and SVAMP [patel-etal-2021-nlp]. These three datasets are widely adopted in existing research, serving as standard benchmarks for evaluating reasoning capabilities.

**Baselines** We compare IoRT with the following strong baselines: 1. Chain-of-Thought prompting (CoT) [wei2022chain]; 2. Self-Consistency (SC) [wangself]; 3. Plan-and-Solve Prompting (PS) [wang-etal-2023-plan]; 4. Multi-Agent Debate [du2023improving; liang2023encouraging]; 5. Self-Contrast [zhang-etal-2024-self-contrast]; 6. Program-of-thought (PoT) [chen2022program]; 7. Hint-before-Solving Prompting [fu2024hint]; 8. Self-Reflection [shinn2023reflexion]; 9. Self-Correcting with Tool-Interactive Critiquing (CRITIC) [gou2024critic]. For simplicity in notation, we use "CoT-SC(8)" and "PoT-SC(8)" to denote the approach that retrieves eight CoT or PoT reasoning chains to make majority vote.

**Implementation Details** In Figure 4, we use the GPT-3.5-Turbo-0613, GPT-4-0613, and Llama2-Chat models at three parameter scales (7B, 13B, and 70B) for black-box LLM and the reflector. Throughout the experiment, GPT-3.5-Turbo-0613 serves as both the meta-thinker and the instructor. We uniformly set the temperature to 0.3 and the maximum number of iterations to 4. To ensure the reliability of the results, we conduct five rounds of experiments for each dataset and report the average scores as the final evaluation results. For evaluation metrics, we report accuracy. To evaluate the computational cost, we also report the average number of API/LLM calls (#Calls Avgs.) [zhang-etal-2024-self-contrast] across three datasets, as well as the average number of tokens consumed per question (#Tokens Num.) for commonsense reasoning tasks.

## Main Results

**Mathematical Reasoning.** According to the results presented in Table [tab:2], IoRT demonstrates superior performance improvement compared to the current strong baselines. Our method achieves an average improvement of f approximately +4.4% compared to PoT. In contrast, CRITIC, which also generate initial responses based on PoT, results in performance decreases of -2.6%. Besides, compared to the text describing reasoning baselines such as CoT, our method also achieve significant improvements of +8.9%. It is worth noting that IoRT achieves an average performance improvement of +2.4% compared to PoT+HSP directly incorporating abstract reasoning to generate an initial response. This indicates that integrating meta-thought into the instructor optimizes reflecting continuously. Moreover, IoRT reduces average call overhead by approximately 27.6% compared to iterative reflection, demonstrating that our approach effectively balances accuracy and call overhead. Although self-contrast outperforms our method on GSM8K with Llama2_7B and on SVAMP with GPT-3.5, this improvement comes at the cost of increased call overheads. Specifically, self-contrast incurs 7.0% higher overhead compared to IoRT.

**Commonsense Reasoning.** Table [tab:3] compares the performance of IoRT on commonsense reasoning tasks. We observe that IoRT outperforms the baseline across all models on StrategyQA. Specifically, our method gains +5.2% performance increase over CoT, whereas self-reflection results in a decrease of -6.0%. IoRT also achieves an average performance improvement of 2.1% compared to CoT+HSP on StrategyQA, demonstrating the efficacy of incorporating meta-thought into the reflection process. Additionally, with a token consumption of 3877, IoRT significantly reduces overhead compared to high-cost methods like self-reflection (5944) and CoT-SC(8) (4145) while maintaining competitive reasoning performance.

## Ablation Study

We perform an ablation study to assess the impact of each steps on model performance:

- IoRT\*: This setting indicates the result of the i*th iteration ```latex $R^{i}*{o}$ `is modified as`latex $R^{i}_{r}$ ```.

- IoRT(w/o SC): It indicates that regardless of whether the responses `latex $R^{i}_{b}$ ` and `latex $R^{i}_{r}$ ` are consistent, the instructor only selects until reaches the maximum number of iterations N.

- IoRT (w/o MT): It implies that meta-thoughts are not provided and instructor relies solely on its own capacity to generate instructions.

As shown in Table 1, we find that modules and settings of IoRT positively impact accuracy and efficiency improvements.

**Select instruction effectively mitigates drift in reflections.** IoRT\* exhibits a performance decrease of -4.4% compared to IoRT, emphasizing that LLMs frequently struggle with generation stability during reflection. Thus, selecting instruction is essential for successful iterative reflection.

**Self-consistency has minimal impact on accuracy but significantly improves efficiency.** IoRT(w/o SC) results in no clear change(-0.51%) in accuracy compared to IoRT, indicating that the instructor enables accurately identifying the better response during the iterations. However, in the experiment, IoRT (w/o SC) requires four iterations to stop, while the average number of iterations for IoRT is just 2.2, indicating that self-consistency can reduce overhead.

**Meta-thought enhances the reasoning capabilities of the Instructor.** IoRT (w/o MT) shows a -2.1% decline compared to IoRT but still achieves a +2.9% improvement over the initial response. This highlights the positive impact of our dynamic iterative framework on reflection, with meta-thoughts further enhancing the instructor's ability to accurately identify correct reflections.

# Discussions

[IMAGE: Left: Comparison of the average number of API/LLM calls across various datasets on IoRT. Right: The performance of GPT and Llama-2 models on GSM8K with IoRT. (Figure 5)]

**Performance Analysis.** In Section 3, our experiments indicate that the performance of CRITIC even deteriorates. In Figure 5 (right), IoRT achieves stable improvements across different LLMs. This is because CRITIC follows a static reflection pipeline: initial response -> evaluation -> revision. In contrast, IoRT adopts a dynamic iterative pipeline: initial response -> evaluation -> revision -> instruction. By comparing Table 3 and Table 2, we observe that with each iteration of IoRT, the occurrences of correct -> **incorrect** and **incorrect** -> **incorrect** cases significantly reduced. The results indicate that IoRT can identify correct in drifting iterations through select instructions, or generate a refresh instruction to promptly terminate stubborn iterations, effectively ensuring stable improvement and optimization.

**Overheads and Manual Efforts Analysis.** In Figure 5 (left), we investigate the average number of API/LLM calls across various datasets on IoRT. In our experiments, we set the maximum number of iterations to 4. Self-reflection and IoRT (w/o SC) were configured with a fixed number of iterations, leading to 9 and 14 call overheads, respectively. Compared to self-reflection and IoRT (w/o SC), IoRT achieves substantial improvements, reducing call overheads by more than 18.8% and 47.9%, respectively. Rather than simply halting reflection after the maximum number of iterations, IoRT integrates self-consistency checks and meta-thoughts, enabling the identification of correct responses and the generation of stop instructions to timely halt iterations, significantly reducing redundancy and overhead. Moreover, our method defines only three roles: meta-thinker, reflector, and instructor, which is considerably fewer than multi-agent debate. This simplification eases the manual effort required for pre-configuring agent roles.

**Model Generality and Differences.** As shown in Table [tab:2], compared to CoT-SC(8), IoRT achieves significant performance improvements of 2.5% on GPT-3.5, 1.9% on GPT-4, 2.3% on Llama2_7B, 3.3% on Llama2_13B, and 5.8% on Llama2_70B, with an average improvement across the three datasets, indicating that IoRT demonstrates robust generality across both commercial LLMs (GPT) and open-source models (Llama-2). Moreover, these results indicate that IoRT often achieves more significant improvements with smaller-scale models, indicating its effectiveness in optimizing the performance of models with fewer parameters. This could be because larger-scale models produce more stable outputs, while smaller-scale models are more likely to generate varied responses through reflection, resulting in greater diversity in their outputs. In prior studies relying on static reflection methods, performance becomes unstable due to the influence of such diversity, and the ratio of correct -> **incorrect** can lead to performance degradation. However, IoRT can quickly capture correct answers from diverse outputs, leading to notable performance improvements. The key difference enabling this is the select instruction in IoRT, which is unaffected by correct -> **incorrect** and ensures stable performance improvement due to incorrect -> **correct**. Notably, Llama2_70B demonstrates a greater ability to generate accurate responses through reflection compared to Llama2_7B and Llama2_13B. With the smaller parameter sizes, Llama2_7B and Llama2_13B struggle to produce correct answers, leading to more frequent invalid and inconsistent iterations.

Analysis of Figure 5 (left) shows differences in call overheads for IoRT across various models. GPT averages 1.9 fewer LLM calls than Llama2, possibly because larger-scale models tend to produce more redundant iterations, so they often stop early with self-consistency checks. In contrast, smaller-scale models have less stable outputs, resulting in more iterations.

# Conclusion

We conducted a comprehensive analysis of the iterative reflection performance of LLMs. The empirical evidence suggests that the performances of these reflection methods are unsatisfactory, primarily due to the limitations of static iterative reflection, which leads to redundant, drift, and stubborn issues. To mitigate this, we propose Instruct-of-Reflection (IoRT), a dynamic iterative reflection framework that integrates abstract reasoning into the reflection, generating adaptive instruction to regulate the iterative reflection. Experimental results demonstrate that IoRT surpasses a series of strong baselines and reduces overhead across a variety of scenarios and with different LLMs.

# Appendix A: Datasets and Evaluation Metrics

**Datasets** Table [table:dataset] presents detailed information about the datasets used in our experiments, including the data source, total number of test samples, task type, answer type, and the number of samples used to generate meta-thoughts, initial responses and reflection prompts.

**Evaluation Metrics** Accuracy is used as the evaluation metric in our experiments. we use various methods to generate responses and exact answers in different tasks. For StrategyQA, we utilize Chain of Thought (CoT) to produce the response, then use regular expressions to extract the option following the phrase "so the answer is" and check if the extracted option matches the correct answer. For GSM8K and SVAMP, we employ the Program of Thought (PoT) to generate code for problem solving, which is then executed using a code executor to obtain the results. If the code contains errors, the program will raise an error and we define the results as None. Finally, we utilize the accuracy based on whether the results match the standard answers.

# Appendix B: Complementary Experiments Results

**Table: Performance of IoRT with GPT-3.5 during iterations on GSM8K**

| Iteration | correct->correct | correct->incorrect | incorrect->correct | incorrect->incorrect |
| --------- | ---------------- | ------------------ | ------------------ | -------------------- |
| 0->1      | 76.6%            | 1.7%               | 5.9%               | 15.8%                |
| 1->2      | 80.7%            | 1.8%               | 3.5%               | 14.0%                |
| 2->3      | 82.7%            | 1.5%               | 1.7%               | 14.1%                |
| 3->4      | 83.3%            | 1.1%               | 1.3%               | 14.3%                |

**Table: Performance of self-correct and CRITIC with GPT-3.5 during iterations on GSM8K**

| Method       | Iteration | correct->correct | correct->incorrect | incorrect->correct | incorrect->incorrect |
| ------------ | --------- | ---------------- | ------------------ | ------------------ | -------------------- |
| Self-correct | 0->1      | 71.2%            | 7.1%               | 5.1%               | 16.6%                |
| Self-correct | 1->2      | 71.8%            | 4.5%               | 4.9%               | 18.8%                |
| Self-correct | 2->3      | 72.3%            | 4.4%               | 3.0%               | 20.3%                |
| Self-correct | 3->4      | 73.0%            | 2.3%               | 2.8%               | 21.9%                |
| CRITIC       | 0->1      | 71.0%            | 7.3%               | 4.9%               | 16.8%                |
| CRITIC       | 1->2      | 73.3%            | 2.6%               | 4.5%               | 19.6%                |
| CRITIC       | 2->3      | 74.3%            | 3.5%               | 2.5%               | 19.7%                |
| CRITIC       | 3->4      | 75.4%            | 1.4%               | 1.9%               | 21.3%                |

**Table: Dataset Statistics**

| Dataset    | Num.  | Domain                 | Ans Type | # Meta | # Refresh | # Reflect |
| ---------- | ----- | ---------------------- | -------- | ------ | --------- | --------- |
| GSM8K      | 1,319 | Mathematical Reasoning | Number   | 8      | 8         | 4         |
| SVAMP      | 1,000 | Mathematical Reasoning | Number   | 8      | 8         | 4         |
| StrategyQA | 2,290 | Commonsense Reasoning  | T/F      | 6      | 5         | 3         |

# Appendix C: Case Study

To better understand the IoRT working mechanism, we analyze cases in different scenarios.

## Case 1: Stop Instruction Example (StrategyQA)

**Question:** Would a veteran of the Phillippine-American War come home craving SPAM?

**Generate Meta-thoughts:** Research when SPAM was introduced to the market and compare that to the timeline of the Philippine-American War to assess the likelihood of a veteran having access to or knowledge of SPAM upon returning home.

**Initial Response:** Let's think step by step. The Philippine-American War occurred between 1899 and 1902, and SPAM was introduced in 1937. There was no direct relationship between these two events, so it's unlikely that a veteran of the Philippine-American War would come home craving SPAM. So the answer is: false.

**Extract the Answer:** False (correct) CoT 0

**Self-Reflect:** What's the problem with the above answer? 1. Plausibility: The answer logically explains the lack of a direct relationship between the Philippine-American War and the introduction of SPAM in 1937, which makes it unlikely for a veteran of the war to come home craving SPAM. The reasoning is sound and aligns with historical timelines. 2. Truthfulness: The information provided is accurate. The timeline of the events mentioned is correct, and there is indeed no direct connection between the Philippine-American War and the introduction of SPAM in 1937.

Here's the better answer: Let's think step by step. The Philippine-American War took place between 1899 and 1902, while SPAM was introduced in 1937, which means there is no direct correlation between the two events. Therefore, it is unlikely that a veteran of the Philippine-American War would come home craving SPAM. So the answer is: false.

**Extract the Answer:** False (correct) CoT 1

**Instruct the Iteration (Stop):** Both COTs provided accurate and logical reasoning based on the question and meta thought provided. They correctly assessed the timeline of the events and concluded that there was no direct correlation between the Philippine-American War and the introduction of SPAM, making it unlikely for a veteran of that war to come home craving SPAM. Therefore, there is no need to regenerate a new answer as the current responses are appropriate. Decision: Stop iteration.

## Case 2: Select Instruction Example (StrategyQA)

**Question:** Can you buy a fair trade laptop?

**Generate Meta-thoughts:** Research the availability of fair trade electronics and the criteria for a product to be certified as fair trade. Consider the supply chains involved in laptop production and whether any companies offer laptops that meet fair trade standards.

**Initial Response:** Let's think step by step. Fair trade principles are typically associated with agricultural or manufactured goods where workers are paid fair wages and operate in safe conditions. While there aren't fair trade-certified laptops per se, some companies may adhere to fair trade practices in the production of their electronics to ensure fair pay and safe working conditions for workers involved in their supply chain. However, it's less common in the electronics industry compared to agricultural products. So the answer is: true.

**Extract the Answer:** True (incorrect) CoT 0

**Self-Reflect:** What's the problem with the above answer? 1. Plausibility: The answer provides a reasonable explanation of fair trade principles and their application in the electronics industry. However, it does not definitively state whether fair trade laptops are available for purchase, leaving room for interpretation. 2. Truthfulness: The information provided is accurate in explaining fair trade practices and their common association with agricultural products. While fair trade-certified laptops may not be prevalent, some companies do indeed prioritize fair trade principles in their electronics production to ensure ethical practices.

Here's the better answer: Fair trade-certified laptops are not commonly available in the market due to the focus of fair trade principles on agricultural and manufactured goods. While some electronics companies may adhere to fair trade practices in their supply chain, specifically for components like minerals or labor conditions, the concept of fair trade laptops as a distinct certification is not widespread. So the answer is: false.

**Extract the Answer:** False (correct) CoT 1

**Instruct the Iteration (Select):** COT 1 provides a more accurate and precise response by directly addressing the question of fair trade-certified laptops and their availability in the market. It aligns closely with the meta thought provided and offers a clear 'false' conclusion based on the information presented. Better COT after comparison: COT 1

## Case 3: Refresh Instruction Example (StrategyQA)

**Question:** Is a doctorate required to teach at a SUNY School?

**Generate Meta-thoughts:** Research the general requirements for faculty positions at State University of New York (SUNY) schools and the typical educational qualifications expected for teaching at the college level, particularly in the subject area of interest.

**Initial Response:** Let's think step by step. SUNY schools are part of the State University of New York system. Each SUNY school may have different requirements for their faculty positions, but generally, a doctorate is a common requirement for teaching at the university level. So the answer is: true.

**Extract the Answer:** True (incorrect) CoT 0

**Self-Reflect:** What's the problem with the above answer? 1. Plausibility: The answer logically addresses the question by explaining that while specific SUNY schools may have varying requirements, having a doctorate is generally a common requirement for teaching at the university level. This explanation aligns with the common standards in academia. 2. Truthfulness: The information provided is accurate. While there may be exceptions based on specific disciplines or positions within SUNY schools, having a doctorate is indeed a common requirement for teaching at the university level, including SUNY schools.

Here's the better answer: Generally, having a doctorate is a common requirement for teaching at the university level, including SUNY schools. So the answer is: true.

**Extract the Answer:** True (incorrect) CoT 1

**Instruct the Iteration (Refresh):** Both COTs provide similar answers stating that a doctorate is generally required to teach at a SUNY school. However, the answers lack depth in addressing the specific requirements for faculty positions at SUNY schools and the educational qualifications expected for teaching at the college level. To improve the response, a more detailed analysis based on the meta thought provided is necessary. Decision: Refreshing the response.

**Refresh:** A doctorate is not always required to teach at a SUNY (State University of New York) school. While many professors at SUNY schools hold doctorate degrees, some instructors may have a master's degree or other qualifications depending on the specific requirements of the position and the subject being taught. So the answer is: false.

**Extract the Answer:** False (correct) CoT 2

**Instruct the Iteration (Select):** Based on the question and meta-thought provided, COT 2 provides a more nuanced and accurate answer by considering the variability in educational qualifications for teaching at SUNY schools, which aligns better with the research and understanding of the requirements for faculty positions at SUNY schools. Better COT after comparison: COT 2

## Case 4: Mathematical Reasoning - Stop Instruction (GSM8K)

**Question:** A candle melts by 2 centimeters every hour that it burns. How many centimeters shorter will a candle be after burning from 1:00 PM to 5:00 PM?

**Generate Meta-thoughts:** To determine how many centimeters shorter the candle will be after burning for a certain number of hours, you need to calculate the total time the candle burns and then multiply that by the rate at which the candle melts per hour.

**Initial Response:**

```
burning_hours = 5 - 1
melt_rate = 2
answer = burning_hours * melt_rate
```

**Extract the Answer:** 8.0 (correct) Code 0

**Self-Reflect:** What's the problem with the above code? 1. The output of 8.0 seems reasonable, as the candle would be 8 centimeters shorter after burning from 1:00 PM to 5:00 PM. 2. Let's check the code: The code calculates the total burning hours and the melting rate per hour correctly, and then calculates the total length the candle would be shorter by multiplying the burning hours with the melting rate per hour. Overall, the code correctly calculates the length the candle would be shorter after burning from 1:00 PM to 5:00 PM.

**Extract the Answer:** 8.0 (correct) Code 1

**Instruct the Iteration (Stop):** Both code snippets correctly calculate the number of centimeters the candle will be shorter after burning for the specified hours. The calculations are consistent with the hint provided, and the outputs match the expected result. There is no need to regenerate a new answer as the current solution is clear, logical, and directly addresses the question. Decision: stop iteration.

## Case 5: Mathematical Reasoning - Select Instruction (GSM8K)

**Question:** Gloria is shoe shopping when she comes across a pair of boots that fit her shoe budget. However, she has to choose between the boots and two pairs of high heels that together cost five dollars less than the boots. If one pair of heels costs $33 and the other costs twice as much, how many dollars are the boots?

**Generate Meta-thoughts:** To determine the cost of the boots, you need to calculate the total cost of the two pairs of high heels and then add five dollars to that amount.

**Initial Response:**

```
heels_1 = 33
heels_2 = 2 * heels_1
total_heels = heels_1 + heels_2
difference = 5
boots = total_heels - difference
answer = boots
```

**Extract the Answer:** 94.0 (incorrect) Code 0

**Self-Reflect:** What's the problem with the above answer? The code calculates the total cost of the two pairs of high heels, that's correct. However, the final calculation subtracts the difference instead of adding it.

**Here's a better code:**

```
heels_1 = 33
heels_2 = 2 * heels_1
total_heels = heels_1 + heels_2
boots = total_heels + 5
answer = boots
```

**Extract the Answer:** 104.0 (correct) Code 1

**Instruct the Iteration (Select):** Code 1 is more aligned with the hint provided as it correctly adds 5 dollars to the total cost of the two pairs of high heels to calculate the cost of the boots. This approach is consistent with the problem description and the meta thought given. Better Code after comparison: Code 1

## Case 6: Mathematical Reasoning - Refresh Instruction (GSM8K)

**Question:** Vincent can buy flowers in packages of 3 for $2.50 or in packages of 2 for $1. How much money does he save by buying 18 flowers at the better price?

**Generate Meta-thoughts:** To determine the savings Vincent can achieve by buying flowers at the better price, you need to calculate the cost per flower for each package option and then multiply the cost of the cheaper option by the total number of flowers to find the total cost.

**Initial Response:**

```
num_flowers = 18
price_3_flowers = 2.5
price_2_flowers = 1
total_price_3_flowers = (num_flowers // 3) * price_3_flowers
remaining_flowers = num_flowers % 3
total_price_2_flowers = (remaining_flowers // 2) * price_2_flowers
answer = (num_flowers * price_2_flowers) - (total_price_3_flowers + total_price_2_flowers)
```

**Extract the Answer:** 3.0 (incorrect) Code 0

**Self-Reflect:** The code calculates the total cost of buying flowers in packages of 3 and packages of 2, but the logic for calculating savings is incorrect.

**Extract the Answer:** 3.0 (incorrect) Code 1

**Instruct the Iteration (Refresh):** The error lies in both code segments not correctly implementing the meta-thought's guidance to compare the total costs of each purchasing option, ultimately resulting in incorrect calculations of Vincent's savings. Decision: Refreshing the response.

**Refresh:**

```
num_flowers = 18
price_3_flowers = 2.5
price_2_flowers = 1
cost_using_3_flower_packages = (num_flowers / 3) * price_3_flowers
cost_using_2_flower_packages = (num_flowers / 2) * price_2_flowers
money_saved = cost_using_2_flower_packages - cost_using_3_flower_packages
answer = money_saved
```

**Extract the Answer:** 6.0 (correct) Code 2

**Instruct the Iteration (Select):** COT 2 aligns better with the meta-thought of accurately calculating total costs for each buying strategy. Code 2 indicates a greater benefit from selecting the optimal option, ensuring Vincent maximizes his savings on flowers. Better Code after comparison: Code 2
