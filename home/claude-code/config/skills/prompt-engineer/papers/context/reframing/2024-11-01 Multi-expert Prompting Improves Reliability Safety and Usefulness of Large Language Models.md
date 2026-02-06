# Abstract

We present Multi-expert Prompting, a novel enhancement of ExpertPrompting [xu2023expertprompting], designed to improve the large language model (LLM) generation. Specifically, it guides an LLM to fulfill an input instruction by simulating multiple experts, aggregating their responses, and selecting the best among individual and aggregated responses. This process is performed in a single chain of thoughts through our seven carefully designed subtasks derived from the Nominal Group Technique [gallagher1993nominal], a well-established decision-making framework. Our evaluations demonstrate that Multi-expert Prompting significantly outperforms ExpertPrompting and comparable baselines in enhancing the truthfulness, factuality, informativeness, and usefulness of responses while reducing toxicity and hurtfulness. It further achieves state-of-the-art truthfulness by outperforming the best baseline by `latex $8.69\%$ ` with ChatGPT. Multi-expert Prompting is efficient, explainable, and highly adaptable to diverse scenarios, eliminating the need for manual prompt construction.

# Introduction

Pre-trained large language models (LLMs) [radford2019language; gpt3; Chowdhery2022PaLMSL; openai2022chatgpt; Touvron2023LLaMAOA] acquire extensive knowledge during training, demonstrating exceptional abilities as general-purpose problem solvers. As they have made increasing impacts on human life, it is essential to ensure these systems align with human intentions by improving their reliability, safety, and usefulness to meet users' expectations [wang2023aligning].

Among the alignment methods, recent studies [li2023camel; Park2023GenerativeAI; do2023choire; wang2023rolellm] highlight that LLMs can mimic expected behaviors of specific agents when cast with sufficient descriptions. This leads to better generation outcomes and enhances user interactions. Notably, xu2023expertprompting introduce ExpertPrompting directing LLMs to answer questions as generated experts. This strategy further proves its effectiveness when ExpertLLaMA trained on its data achieves 96% of the ChatGPT's capability.

[IMAGE: An overview of Multi-expert Prompting with an ExpertQA example. ExpertPrompting provides a one-sided view, concluding "unethical" while Multi-expert Prompting encompasses multiple viewpoints leading to a comprehensively multifaceted answer.]

However, _is relying on a single expert LLM sufficient for diverse user queries?_ Our answer is no. Single expert frameworks like ExpertPrompting fall short of open-ended instructions with multiple valid perspectives. For instance, in response to the question "Is it ethical to eat meat?" in Figure 1, ExpertPrompting casts the LLM as an Ethicist offering a simplistic answer, labeling it as unethical. This approach introduces bias and a dismissive attitude towards other perspectives, such as those of non-vegetarians. Ideally, responses to such questions should encompass various other viewpoints addressing multiple dimensions of the issue, such as nutritional and environmental aspects. This highlights that _a single expert can introduce biases and limit the depth needed for considering varied perspectives in addressing open-ended instructions_.

Inspired by the above observation, we present a novel and efficient extension of ExpertPrompting named Multi-expert Prompting, which addresses the need for multiple perspectives. It involves two main steps (Figure 2). First, given an input instruction, Multi-expert Prompting instructs an LLM to generate n expert identities with their concise, one-sentence role descriptions tailored to the instruction in a zero-shot prompting style. Unlike ExpertPrompting [xu2023expertprompting], which relies on generating detailed role descriptions by few-shot hand-crafted demonstrations, our approach does not require demonstrations and is more versatile as detailed descriptions are unnecessary (Section 6.1). Multi-expert Prompting then casts the LLM as distinct experts, each responding to the instruction independently. Second, it chooses a single best response by aggregating the individual responses and evaluating it together with individual ones through a novel, seven-subtask method in a single chain of thought [wei2022chain] following Nominal Group Technique (NGT; gallagher1993nominal).

Multi-expert Prompting is related to recent efforts in reasoning over multi-agent responses, such as Multi-agent Debate [liang2023encouraging] and Universal Self-consistency (USC) [chen2023universal]. It distinguishes itself by aggregating expert responses in a single turn without iterative refinement. Moreover, its response aggregation is based on the human-designed NGT framework, contrasting with the LLM-generated plans in AutoGen [Wu2023AutoGenEN] and AutoAgents [chen2023autoagents]. Finally, it differs from MetaGPT [hong2023metagptmetaprogrammingmultiagent] by employing diverse domain experts to address questions in parallel, instead of in sequence.

Multi-expert Prompting is the first to tackle the challenge of aggregating multi-agent long-form responses in a single turn based on well-studied perspectives from management sciences. It significantly outperforms baselines in improving the truthfulness, factuality, toxicity, hurtfulness, informativeness, and usefulness of LLMs by leveraging only three experts, achieving state-of-the-art truthfulness. In addition, it is highly adaptable, explainable, and beneficial for open-ended tasks where diverse expert opinions are valued.

[IMAGE: Overview of Multi-expert Prompting: (1) Experts & responses generation and (2) Aggregating expert responses. Given an input instruction, the first step targets generating expert identities that best fulfill the instruction and expert responses, while the second step focuses on aggregating and selecting the best from individual and combined expert responses.]

# Background

We introduce ExpertPrompting [xu2023expertprompting] and the Nominal Group Technique (NGT) [gallagher1993nominal], both serving as foundational elements for Multi-expert Prompting.

#### ExpertPrompting [xu2023expertprompting].

ExpertPrompting is a prompting technique designed to enhance the responses of an LLM by leveraging the model's capability to answer as experts. Given an input instruction, it begins by prompting the LLM to generate a paragraph-long expert identity that best fulfills the instruction through carefully crafted few-shot demonstrations. Then, it directs the LLM to respond as the generated expert. However, it can bias the model's response toward the generated expert --- a critical weakness (Figure 1).

#### Nominal Group Technique (NGT) [gallagher1993nominal].

The NGT is a structured decision-making process that aids teams in identifying problems and generating solutions. It effectively organizes group ideas, combining individual judgments, particularly useful in scenarios marked by uncertainty or disagreement. Widely utilized in business and government, NGT typically involves 4 steps:

**NGT 1. Idea generation.** Each team member independently writes down their ideas.

**NGT 2. Round-robin idea recording.** Ideas are shared in a round-robin fashion and recorded for all to see without discussion and elaboration.

**NGT 3. Discussion of the list of ideas.** The participants discuss each idea on the list so that they are clear about the meaning of the ideas.

**NGT 4. Voting.** Members identify key ideas, rank-order preferences (optional), record votes (agreements, conflicts), and discuss the voting.

# Multi-expert Prompting

In deployment, when presented with an input instruction I, an LLM M is expected to generate a response A while ensuring informativeness, usefulness, truthfulness, non-toxicity, factuality, and non-hurtfulness. Multi-expert Prompting is designed for this goal and consists of two steps: **(1) Experts & responses generation** and **(2) Expert responses aggregation**. In the first step, M is instructed to generate n experts `latex $\{(E_1, D_1),...,(E_n, D_n)\}$ ` with `latex $E_i$ ` as the i-th expert identity and `latex $D_i$ ` as its description. It is then executed n times as each expert to respond to I, offering n long-form expert responses, denoted as `latex $\{A_1,\dots,A_n\}$ `. In the second step, M combines `latex $\{A_1,\dots,A_n\}$ ` into `latex $A_{comb}$ ` and selects the best among `latex $A_i$ ` and `latex $A_{comb}$ ` as A. The steps' details are below, and our detailed prompts and cost analysis are provided in Section 11. Let us denote `latex ${G}_\mathcal{M}: \mathcal{V}^* \to \mathcal{V}^*$ ` be the generation function of M where V is the model vocabulary.

## 1st Step: Experts & Responses Generation

Motivated by NGT 1 and 2, this step aims to simulate M as multiple experts to generate expert answers independently. Given I, we first instruct M to generate a list of n experts capable of answering I thoroughly. Each i-th expert is a tuple of `latex $(E_i, D_i)$ ` where `latex $E_i$ ` is the expert's identity and `latex $D_i$ ` is a one-sentence description of its expertise and responsibilities. Formally:

```latex
$$\{(E_1, D_1),\dots,(E_n, D_n)\} := {G}_\mathcal{M}([I_E, I])$$
```

where `latex $I_E$ ` is the (expert, responsibility) pair generation instruction. We enforce three constraints on generating experts in Equation 1 which are specified in `latex $I_E$ `: the experts should be diverse, `latex $E_i$ ` is a general expert, and `latex $D_i$ ` is its short clarification. For the first constraint, we promote diversity among experts to cultivate a range of perspectives, enhancing the quality of the final response, as noted by schulz2000biased. Regarding the final constraint, `latex $D_i$ ` is designed to be more versatile than the detailed descriptions used in ExpertPrompting [xu2023expertprompting], which relies on hand-crafted few-shot demonstrations, which we find unnecessary (Section 6.1).

For each expert, we ask the LLM M to generate a long-form answer A:

```latex
$$A_i := {G}_\mathcal{M}([I, E_i, D_i])$$
```

Both equations are efficiently performed under the zero-shot setting.

## 2nd Step: Expert Responses Aggregation

Aggregating long-form expert responses `latex $\{a_1,...,a_n\}$ ` into a final one is challenging, even for humans. Motivated by NGT and prior studies [wei2022chain; khot2023decomposed], we argue that every expert should contribute to the final response. Thus, we decompose the task into seven well-designed subtasks aiming to identify commonalities, necessitate the consolidation of information, and resolve conflicts via majority voting. We weight all the experts equally to prevent _blind trust in expert opinions_, minimizing the group's vulnerability to biases [onkal2009relative]. Specifically, M efficiently fulfills these subtasks in _a single zero-shot chain of thoughts_ [kojima2022large].

**Subtask 1 (S1): Generating agreed viewpoints.** This subtask aims to establish a consensus among experts' answers, inspired by NGT 4. Specifically, the LLM generates viewpoints that more than half of the experts agree on. These are reliable and identified earliest to confirm widely accepted information, providing a foundation for next steps.

**Subtask 2 (S2): Generating conflicted viewpoints.** Given the diverse backgrounds of multiple experts, conflicts are inevitable. Identifying conflicted viewpoints is crucial to resolving the conflicts. Hence, the LLM lists the conflicted viewpoints with specified expert identities in detail for the subsequent resolution.

**Subtask 3 (S3): Resolving the conflicts in S2.** Resolving the above conflicts is critical for correction purposes and reducing experts' biases, following NGT 4. We instruct the LLM to address the disagreements using its knowledge by reviewing the agreed viewpoints in S1 to judge conflicted viewpoints carefully.

**Subtask 4 (S4): Generating isolated viewpoints.** Viewpoints that are not identified by S1 and S3, and are unique from each response, are now generated. These unique perspectives can provide valuable information without being conflicted among experts. They are crucial to ensure a diverse, comprehensive, and insightful response.

**Subtask 5 (S5): Collecting S1, S3, S4 viewpoints.** The LLM collects the viewpoints obtained from S1, S2, and S4 which appear in the final aggregated response. This step ensures transparency and explainability of the arguments included in the final response.

**Subtask 6 (S6): Generating the aggregated response.** The LLM composes a comprehensive response by integrating the viewpoints gathered from S5 as the experts' aggregated response.

**Subtask 7 (S7): Select the best among the aggregated and individual expert responses.** The aggregated response in S6 may not be optimal. If a majority of experts provide poor answers, the aggregated answer may suffer. Thus, this step is designed to choose the best among individual expert answers and the aggregated one, focusing on factual accuracy and usefulness. Importantly, this step does not generate a new answer, nor does it reveal evaluation metrics; it simply selects the most factual and useful response for all tasks.

In summary, Multi-expert Prompting composes a response by merging common, resolved-conflict, and unique viewpoints, following the NGT model. It further selects the best response from individual experts and the merged response, crucial for avoiding poor merged outcomes. Our human evaluation shows that the zero-shot performance of benchmarked LLMs is good enough. However, for more complex aggregations requiring specific formats, we recommend one-/few-shot prompting.

# Evaluation

We show that Multi-expert Prompting greatly improves reliability and safety (Section 4.1) and the informativeness and usefulness (Section 4.2) over the baselines.

#### Baselines.

We compare Multi-expert Prompting with six strong baselines: **(B1) Zero-shot**; **(B2) Zero-shot-CoT** [kojima2022large]; **(B3) Self-refine** [madaan2023selfrefine] which interactively utilizes LLMs to feedback and refine the response; **(B4) Universal Self-consistency** [chen2023universal] which prompts LLMs to generate multiple responses and selects the most consistent; **(B5) Multi-agent Debate** [liang2023encouraging] which simulates two agents with opposing perspectives engaging in several rounds of debate to refine the response; and the aforementioned **(B6) ExpertPrompting** [xu2023expertprompting].

Furthermore, three Multi-expert Prompting variants are also assessed where our first step (Section 3.1) is altered: **(B7) Fixed Temp. + Our Aggregation** uses a single temperature to sample n responses; **(B8) Var Temp. + Our Aggregation** samples n responses by n varying temperatures; **(B9) ExpertPrompting + Our Aggregation** generates n responses with one expert identity found by ExpertPrompting. Our experiments are conducted on two strong open- and closed-source LLMs: **ChatGPT** (gpt-3.5-turbo-0613) [openai2022chatgpt] and **Mistral** (-7B-it v0.2) [jiang2023mistral]. Details are provided in Section 10.

#### Metrics.

We evaluate the methods on six criteria for long-form generation tasks: **(C1) Truthfulness** measuring how models imitate human falsehoods; **(C2) Factuality** verifying the factuality; **(C3) Toxicity** assessing the toxicity biases; **(C4) Hurtfulness** examining the hurtfulness; **(C5) Informativeness** concerning the details, in-depth insights, multiple perspectives, and supporting evidence provided; **(C6) Usefulness** verifying the effectiveness in expressing the ideas and conveying the information.

## Multi-expert Prompting Improves Reliability and Safety

#### Setup.

We evaluate the (C1) Truthfulness on **TruthfulQA-Generation** [lin-etal-2022-truthfulqa], (C2) Factuality on **FactualityPrompt** [lee2022factuality], (C3) Toxicity on **BOLD** [bold_2021], and (C4) Hurtfulness on **HONEST** [nozza-etal-2021-honest]. We record the **True percentage** (by using fine-tuned ChatGPT judge) for TruthfulQA, **Hallucinated NE Error** Factual/Non-factual for FactualityPrompt, **Toxicity percentage** for BOLD and **HurtLex** for Queer/Nonqueer HONEST, following HuggingFace Evaluate [von-werra-etal-2022-evaluate]. We discuss more benchmark details in Section 13.

#### Results.

Table 1 presents our main experimental results, revealing four key findings. First, Multi-expert Prompting substantially improves truthfulness, outperforming the best baselines (B3 for Mistral and B6 for ChatGPT) by `latex $5.27\%$ ` and `latex $8.69\%$ ` with Mistral and ChatGPT, respectively. It achieves a new state-of-the-art on TruthfulQA-Generation with ChatGPT, surpassing the current SOTA of `latex $87.97\%$ ` [li2023inferencetime]. We explain the significant truthfulness improvement with the democratic theory [cunningham2002theories]: aggregated output moderated by multiple experts positively contributes to higher truthfulness. Second, by incorporating diverse expert perspectives, Multi-expert Prompting corrects experts' biases, eliminates harmful elements, significantly enhances factuality, completely eliminates toxic content, and reduces hurtfulness. Third, compared to B7--9, which use different strategies for generating multiple responses, Multi-expert Prompting consistently achieves superior results, indicating the effectiveness of our first step. Fourth, any form of multiple expert prompting exhibit comparable or better results over ExpertPrompting and Zero-shot baselines alone, affirming the importance of aggregation in our second step.

## Multi-expert Prompting Enhances Informativeness and Usefulness

#### Setup.

We evaluate (C5) Informativeness and (C6) Usefulness of Multi-expert Prompting in open-ended scenarios where no ground-truth answers exist and multiple long-form responses are correct. We collect all open-ended questions from **ExpertQA** [malaviya23expertqa] consisting of 528 questions in 32 topics. Metrics C5 and C6 are computed automatically via the **Win/Draw/Lose comparison** between Multi-expert Prompting and other baselines by ChatGPT, found to be an effective evaluator [wang-etal-2023-chatgpt]. We include the evaluation prompts in Section 12.

#### Results.

[IMAGE: (C5) Informativeness and (C6) Usefulness comparisons between Multi-expert Prompting and baselines on ExpertQA dataset.]

Figure 3 illustrates our informativeness and usefulness evaluation results. We observe that Multi-expert Prompting generates significantly more informative (75% win on average) and useful (76.5%) responses, compared to the baselines. For both models, it gains the least informativeness win over ExpertPrompting ((1) and (2) in Figure 3) and usefulness over USC and ExpertPrompting ((3) and (4)). This is because, for certain questions, the perspective of a single expert is sufficiently accurate, as illustrated in (e.g., Appx.-Figure 18). Additionally, we conduct a human investigation of ChatGPT's evaluation comparing Multi-expert Prompting and ExpertPrompting. Our investigation indicates a high agreement rate of 93% between the annotator and ChatGPT on average over two metrics, confirming its reliable evaluation.

# Human Evaluation and Analyses

Human evaluation is essential for assessing the subtask performance of models in Multi-expert Prompting, as no automated metrics exist for this purpose. We conduct human evaluation to validate its two steps: 1st Step: Experts & response generation (Section 3.1); 2nd Step: Aggregating expert responses (Section 3.2) with n=3 experts. We randomly select 100 samples generated by ChatGPT and Mistral from each of TruthfulQA, BOLD, and ExpertQA representing all our tasks. Three excellent undergraduates who are native English speakers are hired to rate the generation of the two steps through two metrics on a scale of 1--3: **(M1) Expert Generation Satisfaction** for our first step measures whether the three generated experts are diverse and helpful, and **(M2) Aggregation Satisfaction** for the second step assesses how well the models perform the seven subtasks in Section 3.2. The grading policies are in Section 14.

We discuss our findings here while examples supporting our arguments are provided in Section 15. Overall, Mistral excels in both steps, while ChatGPT exhibits a notable deficiency in the initial stage of generating experts. Specifically, Mistral outperforms ChatGPT significantly in expert generation. Among the three experts generated by ChatGPT, we observe a 27% incidence where one expert proves less helpful (e.g., Appx.-Figure 20) and an 11% occurrence where two experts are less helpful (e.g., Appx.-Figure 21), on average. On the flip side, ChatGPT marginally outperforms Mistral in executing our 7 subtasks. Within the 7 subtasks, both models demonstrate proficiency in subtasks S1 and S5-S7. Although both occasionally misinterpret divergent viewpoints (S2) (e.g., Appx.-Figure 22), they excel in resolving these discrepancies (S3). Additionally, both models face challenges in extracting unique viewpoints (S4), likely due to the task's inherent complexity. Lastly, our annotators achieve a commendable agreement `latex $\alpha = 0.73$ `.

## Analyses

We now present our core methodological analyses, covering ablation studies, the impact of the number of experts, and the ratio of best response to be the combined one. We supplement fine-grained analyses, distribution of generated experts, and the performance of Multi-expert Prompting in reasoning tasks in Section 9.

#### Ablations studies.

The ablation study for the 1st Step of Multi-expert Prompting corresponds to the baseline (B7) explored in Section 4. Subsequently, we investigate the ablation of subtasks in its 2nd Step. Specifically, we examine the skipping of S1, S2, S3, S4, and S7 (Section 3.2). Subtasks S5 and S6, categorized as bridging subtasks, do not undergo ablation. We compare Multi-expert Prompting with **(B10) Naive Agg.**, where LLMs naively aggregate expert responses via "Please combine responses into a final one" before selecting the best one. We further enhance the (B10), termed **(B11) Enhanced Naive Agg.** by instructing the model to ensure that the aggregated response is truthful, factual, less toxic, and less hurtful on the TruthfulQA, FactualityPrompt, BOLD, and HONEST benchmarks.

Table 2 shows that skipping S1 and S4 impairs performance the most, underscoring the importance of common and unique viewpoints. S2 and S3 also significantly contribute to performance, highlighting the importance of conflict resolution. S7 contributes marginally, indicating high-quality aggregated responses. B10 and B11 perform notably worse than Multi-expert Prompting, confirming the effectiveness of its second step.

#### Number of experts.

We explore the impact of the number of experts in Multi-expert Prompting performance. Table 3 presents ChatGPT results using Multi-expert Prompting with varying expert counts. We observe that 3 experts yield the best truthful, factual, least harmful results, while >=2 experts significantly decreases toxicity. This mirrors reality where excessive expert input may divert humans from obtaining the most truthful and factual output. Meanwhile, utilizing numerous safe responses from safety fine-tuned models like ChatGPT can minimize toxicity details in the output.

#### Ratios of the best response selected to be the aggregated response.

To assess the quality of the aggregated responses, we record the proportion of test samples where the aggregated response is selected by models over individual expert responses in Table 4. Notably, both models consistently favor the combined response in over 90% of cases, highlighting their superior quality over experts' ones.

# Discussion

We discuss the underlying reasons for Multi-expert Prompting's effectiveness and address its design choices.

## Why does Multi-expert Prompting Work?

#### Short versus long expert description.

We investigate why a one-sentence description for an expert identity is effective, compared to a paragraph-long description as used in ExpertPrompting [xu2023expertprompting]. After generating experts with Multi-expert Prompting, we randomly select one expert identity and compare the impact of its one-sentence description to its paragraph-long counterpart generated through ExpertPrompting. The results, shown in Table 5 indicate that the performance difference between the two methods is negligible, suggesting that long-form descriptions are unnecessary.

#### Aggregated response versus expert response: Why is Multi-expert Prompting better than the baselines?

[IMAGE: A TruthfulQA example where Multi-expert Prompting provides the correct answer, while the majority of experts answer incorrectly according to the ground-truth. This demonstrates its advantage in considering not only common but also unique expert viewpoints.]

The aggregated response of Multi-expert Prompting offers several advantages over individual expert responses (Section 3.2) by considering not only common viewpoints but also resolved-conflict and unique viewpoints. To illustrate this, we examine a TruthfulQA case [lin-etal-2022-truthfulqa] in Figure 4. In this scenario, both the "Superstition expert" and the "Folklore historian" provide plausible answers that are, however, incorrect when compared to the ground truth. By contrast, Multi-expert Prompting excels by integrating not only common perspectives, such as "bad luck" (which is incorrect according to the ground truth) but also unique expert insights. Crucially, the "Animal behaviorist" asserts that superstition "has no real impact", which Multi-expert Prompting incorporates, resulting in a comprehensive and accurate answer. Finally, in this case, both USC and Multi-agent Debate conclude that it brings "bad luck", while only Multi-expert Prompting arrives at the correct answer.

## Directly Asking LLMs to be Truthful, Factual, less Toxic, less Hurtful

[IMAGE: Comparison between Multi-expert Prompting, the baseline, and the baseline with constraints.]

We investigate if directly instructing LLMs to be factual and useful during generation improves performance, potentially altering Multi-expert Prompting. Our findings confirm that this approach enhances the baseline prompting technique. However, it still falls significantly short of Multi-expert Prompting's performance.

Specifically, we compare Multi-expert Prompting with six variants of Zero-shot CoT [kojima2022large] by adding more constraints: we directly instruct the LLMs to be more truthful on TruthfulQA, more factual on FactualityPrompt, less toxic on BOLD, less hurtful on HONEST, and more informative and useful on ExpertQA. We utilize both Mistral and ChatGPT, averaging their performance and plotting in Figure 5, with the numerical details provided in Appx.-Table 6. We observe that incorporating more constraints significantly reduces toxicity and hurtfulness while slightly improving truthfulness. However, adding constraints still lags significantly behind Multi-expert Prompting.

## Are Informativeness and Usefulness the Results of Output Longiness?

To inspect whether the high (C5) Informativeness and (C6) Usefulness scores achieved by Multi-expert Prompting are due to the lengthy responses, we record the average #tokens in responses generated on ExpertQA presented in Table 7. Our answer is no: longer responses do not necessarily equate to being more informative or useful. _(1) For ChatGPT_, Zero-shot CoT and Multi-expert Prompting generate answers with similar lengths (60.97 and 62.15). However, Zero-shot CoT's (C5) and (C6) scores were significantly lower compared to Multi-expert Prompting, indicating that longer answers do not necessarily equate to being more informative and useful. _(2) For Mistral_, Multi-expert Prompting has a significantly higher number of tokens compared with other baselines. Therefore, we compare it with Zero-shot CoT, Self-refine, and ExpertPrompting where we explicitly require the LLMs to output responses having 170 tokens. The results are in Figure 6. Multi-expert Prompting outperforms Zero-shot CoT, Self-refine, and Zero-shot prompting on (C5), with ExpertPrompting slightly ahead. However, on (C6), Multi-expert Prompting surpasses all baselines. These verify that longer answers do not always lead to more informative or useful.

[IMAGE: Informativeness and usefulness comparison results between Multi-expert Prompting and other baselines with Mistral on ExpertQA dataset when we explicitly ask the model to generate responses having 170 tokens.]

# Related Work

#### Multi-agent systems.

Multi-agent systems [shoham2008multiagent] have a long development history. A notable early example is the Mixture-of-Experts (MoE) [jacobs1991adaptive], which has influenced the design of modular language models such as Gshard [lepikhin2020gshard], DEMIX [gururangan2022demix] and MoRE [si-etal-2023-getting]. Recent advancements in large language models (LLMs) have spurred the development of prominent LLM-driven multi-agent systems, such as Multi-agent Debate [liang2023encouraging], AutoGen [Wu2023AutoGenEN], AutoAgents [chen2023autoagents], MetaGPT [hong2023metagptmetaprogrammingmultiagent], and MATRIX [xu2024matrixmultiagenttrajectorygeneration]. Key design choices in these systems include the communication protocols among agents and the methods integrating their responses for decision-making. Multi-expert Prompting distinguishes itself as an LLM-based multi-agent framework by employing the Nominal Group Technique (NGT), a structured and reliable human-designed decision-making process, to aggregate expert agents' responses. In addition, Multi-expert Prompting's response aggregation method is related to Self-consistency [wang2022self], Universal Self-consistency [chen2023universal], and Automatic Model Selection [zhao-etal-2023-automatic]. However, it selects the best response from both the individual experts' responses and their combination, rather than simply choosing among the experts' responses.

#### Role-playing with LLMs.

Recent advancements have significantly enhanced capabilities in LLMs, which are crucial for developing role-playing agents. These agents are designed to simulate general or specific personas via training or input contexts [deshpande-etal-2023-toxicity; do2023choire; wang2023rolellm; xu2024character; wu-etal-2024-role]. Multi-expert Prompting leverages the role-playing capabilities of LLMs to simulate multiple experts responding to input instructions.

# Conclusion

We introduce Multi-expert Prompting, an efficient method that simulates multiple experts within an LLM and aggregates their responses to improve generation. Drawing inspiration from the Nominal Group Technique, this approach pioneers in aggregating lengthy responses in LLM-powered multi-agent systems by well-studied human-design decision-making frameworks in a single turn. Multi-expert Prompting is efficient, interpretable, and generalizable, possessing great potential for applications. In future, we plan to further generalize it to enhance group decision-making AI.

# Limitations

Our method can undoubtedly be easily generalized to other long-form generation tasks. However, for short-form answering tasks such as True/False or short-form numerical reasoning tasks, its aggregation method may be unnecessary because the 7 subtasks are validly applicable to viewpoints. As such, to apply Multi-expert Prompting, we suggest the audiences generate reasoning thoughts together with the short-form answers via Chain-of-Thought [wei2022chain; kojima2022large] or other similar techniques.

In addition, Multi-expert Prompting requires the LLMs to have a good instruction-following capability to perform role-playing and to solve our subtasks, and we use placeholder format to wrap the final selection answer [long2024llms]. We anticipate that these limitations are going to be overcome by recent and future state-of-the-art LLMs as LLMs are increasingly evolving in role-playing scenarios [lu-etal-2024-large; wang2023rolellm; tseng2024talespersonallmssurvey] and instruction-following capabilities [qin-etal-2024-infobench].

Moreover, all expert opinions in Multi-expert Prompting are treated equally using the Nominal Group Technique, which may not reflect real-world scenarios accurately. Exploring methods for weighted aggregation of viewpoints is necessary to address this limitation effectively.

Finally, Multi-expert Prompting can suffer from LLMs hallucinating expert identities and engaging in role-playing, especially in specific domains where the models are poorly trained. This issue can significantly impact the response quality of the multi-expert system and is particularly problematic in multi-agent systems [yoffe2024debuncmitigatinghallucinationslarge]. However, employing weighted aggregated viewpoints presents a promising solution to this problem. Moreover, advancements in role-playing LLMs [lu-etal-2024-large; wang-etal-2022-n24news] suggest that LLMs are becoming increasingly less prone to hallucination in role-playing scenarios.

# Ethical Considerations

Generating experts and casting LLMs as them can handle diverse user instructions powerfully, but there's a risk of misuse and bias in certain situations. Ethical concerns arise when our method is applied to enable unethical actions or perpetuate biased scenarios.

#### Bias Amplification and Fairness.

The diversity of the generated experts is not fully controlled due to the models' inherent knowledge, we have taken steps to enhance expert diversity generation by explicitly instructing the LLMs to produce diverse expert identities. Casting large language models (LLMs) as experts risks reinforcing existing biases, creating echo chambers, and amplifying unethical perspectives [del2016echo]. To counter this, Multi-expert Prompting addresses the problem by equally combining perspectives from multiple experts, avoiding reliance on a single viewpoint, and minimizing the risk of reinforcing polarized or undesirable views. Our expert response aggregation process is designed to also minimize potential biases. The seven subtasks require the model to identify agreed-upon and conflicting viewpoints and then reconcile these differences. This systematic approach ensures viewpoint revisions only, without regenerating or refining viewpoints in a way that might favor specific perspectives and amplify biases [xu-etal-2024-pride].

#### Human Evaluation.

Through human evaluations, our proposed method does not generate any discriminatory or insulting responses. We meticulously validate each step of Multi-expert Prompting through manual labor, employing annotators who are compensated at an hourly rate of $15, exceeding the local statutory minimum wage. This proactive approach ensures ethical standards in our human evaluations, minimizing the likelihood of significant ethical concerns.

# Supplementary Analysis

## Fine-grained Analyses

#### TruthfulQA.

[IMAGE: TruthfulQA fine-grained result by Categories in ChatGPT and Mistral]

The fine-grained results on TruthfulQA are presented in Figure 7. For the ChatGPT, Multi-expert Prompting performs better than ExpertPrompting in 22/38 topics, with the most significant improvements observed in `Indexical Error: Identity` with 33.33% absolute improvement, `History` with 29.17% improvement, `Misquotations` with 25.00% improvement, and `Science` with 22.22% improvement. ExpertPrompting, on the other hand, excels in `Misinformation` with 8.33%, `Misinformation` with 7.14%, `Nutrition` with 6.25%, and `Superstitions` with 4.55% better than Multi-expert. For the Mistral, Multi-expert Prompting also outperforms ExpertPrompting in 25/38 topics. However, ExpertPrompting surpasses Multi-expert Prompting in `Politics` and `Indexical Error: Identity`, as well as `Fiction`. In most cases, incorporating multiple perspectives from different experts can provide diverse viewpoints and aid in verifying information, thus leading to better performance with multi-expert prompting. However, in situations where misinformation is prevalent, differences in information from multiple experts could result in confusion and erroneous conclusions.

#### FactualityPrompt.

The fine-grained results on FactualityPrompt are shown in Figure 8. Specifically, with ChatGPT, Multi-expert Prompting surpasses ExpertPrompting in factual prompts and significantly improves in nonfactual prompts. In factual prompts, Multi-expert performs with 0.94% absolute improvement and 16.58% relative improvement compared to ExpertPrompting. In nonfactual prompts, Multi-expert performs with 6.44% absolute improvement and 48.87% relative improvement compared to ExpertPrompting. With Mistral, Multi-expert Prompting substantially improves in factual prompts by 28.65% and slightly improves in nonfactual prompts by 4.07%. This proves the capacity for tolerance and resilience to information. In the case of misinformation, Multi-expert Prompting has greater verifiability regarding the information, thus leading to better results.

#### BOLD.

For BOLD (Figure 8), Multi-expert Prompting shows improvements in both `American_actors` and `American_actresses` categories with the toxicity decreased by 90.51% and 95.63% respectively. The combination of different answers from experts helps the model to verify toxicity, thus output a less toxic response.

[IMAGE: FactualityPrompt Average Hallucination NER Ratio by Categories fine-grained result in ChatGPT and Mistral (1), BOLD ChatGPT Toxicity Scores fine-grained result (2), HONEST ChatGPT Honest Scores by Category fine-grained result (3). Lower is better.]

#### HONEST.

For HONEST (Figure 8), ChatGPT with Multi-expert Prompting gathers opinions from different experts and generates a final answer by synthesizing multiple perspectives and tends to excel in 6/8 categories, most significantly in `queer_gender` and `nonqueer_gender` with 40% and 80% less harmful respectively compared to ExpertPrompting. In more general categories, like `queer` and `nonqueer` categories, the complexity and diversity of opinions among experts may lead to challenges for multi-expert prompting, leading to worse results with 56% and 60% worse compared to ExpertPrompting.

## Distribution of Generated Experts

The distribution of the generated data is detailed in Figure 9, which provides an overview of the frequency of experts being generated in step 1.

[IMAGE: Distribution of Experts generated by our first step, using (a) TruthfulQA, (b) FactualityPrompt, (c) BOLD and (d) HONEST benchmark, in ChatGPT.]

#### TruthfulQA.

The most popular experts being generated by the model are _Historian_ with 25%, _Psychologist_ with 13.9%, _Economist_ with 9.3% and _Nutritionist_ with 8.3%. The variety of experts in different fields guarantees a diverse range of information from various perspectives. _Historian_ is the most generated experts due to the nature of the benchmark, focusing on answering information that requires historical context.

#### FactualityPrompt.

The most prominent expert categories reflect a strong emphasis on the entertainment industry. The most popular experts being generated by the model are _Entertainment Journalist_ with 22.8%, _Biographer_ with 14.2%, _Film Critic_ with 12% and _Film Historian_ with 11.1%.

#### BOLD Toxicity.

The most frequently generated experts are _Biographer_ with 28.8%, _Entertainment Journalist_ with 22%, _Film Historian_ 21.2%. With the categories focus on American Actors and Actresses, these experts are the most suitable to generate comprehensive and informative answers in the topic.

#### HONEST.

In the top generated experts, _Psychologist_ leads with 19.2%, _Sociologist_ with 18.9%, _Clinical Psychologist_ with 14.5%. These experts exhibit significant expertise in human behavior and understanding, making them well-equipped to provide comprehensive answers. With the dataset emphasizing on _queer_ and _nonqueer_ categories, this highlights the models' ability to generated suitable experts, ensuring a thorough and inclusive analysis of the topic.

## Asking Self-refine to provide feedback and refine the answer to be more factually correct and useful

We further investigate the performance of Self-refine baseline, which involves directly asking the model to provide feedback and refine its answer by including the instruction "The answer needs to be more factually correct and useful". Our results, summarized in Table 8, indicate that by incorporating additional feedback, Self-refine approach performs on par across four benchmarks with Mistral and shows improvement in all benchmarks when using ChatGPT, with the most significant improvement observed in BOLD Toxicity, where Self-refine reaches Multi-expert Prompting's score. However, it still falls significantly short of Multi-expert Prompting's performance in other benchmarks.

## Multi-expert Prompting in Reasoning Tasks

#### Experimental Setup.

We compare Multi-expert Prompting with (B1) Zero-shot, (B2) Zero-shot-CoT [kojima2022large], (B3) Self-refine [madaan2023selfrefine], (B4) ExpertPrompting [xu2023expertprompting], and (B8) Zero-shot-CoT-Self-Consistency [wang2022self] on 6 MCQ reasoning tasks: OpenBookQA [mihaylov-etal-2018-suit], ARC-Challenge [clark2018think], and 8 MMLU college tasks: `college_computer_science`, `college_mathematics`, `college_medicine`, `college_physics`, `computer_security`, `formal_logic`, `econometrics`, `electrical_engineering` [hendrycks2020measuring]. The performance of models is measured by Accuracy, following the prior works above.

#### Results.

Results in Table 9 reveal shortcomings of ExpertPrompting for most reasoning datasets and MMLU topics, with notable drops compared to baselines. This highlights two key limitations: (1) relying on a single expert is insufficient, and (2) current LLMs struggle as distinguished experts. Multi-expert Prompting overcomes these limitations by integrating multiple experts' perspectives, outperforming ExpertPrompting significantly across all datasets and MMLU topics. Notably, Multi-expert Prompting achieves comparable results with Zero-shot-CoT and Zero-shot-CoT-SC in reasoning tasks, even surpassing them on `college_physics`, showcasing the advantage of leveraging multiple experts' views.

# Supplementary Documents of Baselines and Models

## Prompting Baseline

#### (B1) Zero-shot Prompting.

Zero-shot prompting is a fundamental and straightforward technique in prompting methods. It involves instructing the model to provide direct answers, making it a widely adopted and user-friendly baseline.

```
{question}.
```

#### (B2) Zero-shot Chain-of-Thought (CoT) [kojima2022large; wei2022chain].

CoT prompting guides the model to break down complex tasks into intermediate steps, demonstrating its versatility and efficiency in managing various reasoning tasks.

```
Question: {question}
Let's think step by step.

Output in the following format:

Explanation:

Final answer:
```

#### (B3) Self-Refine [wang2022self].

Self-refine sharpens responses by instructing the model to iteratively feedback and modify answers based on that feedback, progressively improving its performance over time in reasoning tasks.

We prompt the LLM to obtain the initial answer. The LLM is asked to provide feedback on the answer. The feedback and initial answer are then used as input to generate the revised answer. We choose 2 as the number of revision iterations to ensure that the number of LLM calls is equal to Multi-expert prompting in a 3-expert case.

1. Get initial response

```
{question}.
```

2. Get feedback to the response

```
You are given a question and an answer for that question. Analyze the question and the answer and provide some feedback of the answer to the question. Don't change the answer, just provide feedback.

Question: {question}

Answer: {answer}
Feedback:
```

3. Get refined response

```
You are given a question, an answer to that question and a feedback to the answer. Based on the feedback, refine your answer and generate the final answer.
Question: {question}
Answer: {answer}
Feedback: {feedback}
Final_answer:
```

#### (B4) Universal Self-consistency

[chen2023universal] Universal Self-consistency leverages LLM to select the most consistent answer among candidate answers. We adopt prompt from the Zero-shot in Appendix B1 to generate candidate answers and use the prompt template described in [chen2023universal] for selecting the most consistent answer.

#### (B5) Multi-agent Debate

[liang2023encouraging] Multi-agent Debates simulate the environment where multiple agents express their arguments and a judge observes the debating process to generate the final answer. We adopt the framework and prompt template as describe in [liang2023encouraging] for our task.

#### (B6) ExpertPrompting [xu2023expertprompting].

ExpertPrompting directs the model to act as a distinguished expert by synthesizing a detailed expert identity via few-shot prompting with hand-crafted demonstrations and instructing the model to perform a specific task accordingly.

1. Generate Expert identity and description

```
For each question, write a high-quality description about the most capable and suitable agent (role) to answer the question. In second person perspective.

For example:
[Question]: {Demonstration 1 Question}
[Agent Description]: {Demonstration 1 Answer}

[Question]: {Demonstration 2 Question}
[Agent Description]: {Demonstration 2 Answer}

[Question]: {Demonstration 3 Question}
[Agent Description]: {Demonstration 3 Answer}

[Question]: {Question}
[Agent Description]:
```

2. Get Expert answer

```
{expert_identity}

Now given the above identity background, please answer the following question:
{question}
```

#### (B7) Fixed Temperature Zero-shot Result + Our Aggregation.

In this baseline, we examine the result by prompting the model to generate n answers by a fixed temperature in zero-shot setting and use our aggregation technique to combine the results. This baseline is necessary to benchmark the effectiveness of the diverse expert roles in our technique compared to no role assigned. The prompt we use for answer generation is adopted from Zero-shot template in Appendix B1 and aggregation prompt is adopted from Multi-expert Prompting, presented in Section 11.5.

#### (B8) Variable Temperature Zero-shot Result + Our Aggregation.

This baseline is the same as (B5), except we use n different temperatures (for the case n=3, we use 0, 0.4, 0.8) to sample n answers. The prompt we use for answer generation is adopted from Zero-shot template in Appendix B1 and aggregation prompt is adopted from Multi-expert Prompting, presented in Section 11.5.

#### (B9) ExpertPrompting Result + Our Aggregation.

We use ExpertPrompting to sample n experts' answers. One of the crucial differences between our method and ExpertPrompting is that our method samples n different experts while ExpertPrompting samples 1 expert for 3 answers most of the time due to its expert generation step being few-shot generation without explicitly requiring multiple experts. As such, it falls significantly compared to our method, see Table 1. The prompt we use for Expert identity generation and answer is adopted from ExpertPrompting in Appendix B1 and aggregation prompt is adopted from Multi-expert Prompting, presented in Section 11.5.

## Model Hyperparameters

#### ChatGPT.

ChatGPT is called via OpenAI API with the mode _gpt-3.5-turbo-0613_. For temperature, we use a consistent temperature setting of 0.0 for all baselines and intermediate steps. In the case of the baseline (B7) where variable temperature is required, we use temperatures of {0.0, 0.4, 0.8} for the three answers generated from Zero-shot prompting. We use Sampling [holtzman2019curious] as our decoding strategy. The context window size is set to 1024 for all the steps.

#### Mistral.

We call the pretrained model _Mistral-7B-Instruct-v0.2_ from MistralAI available in HuggingFace. For all Mistral experiments, we use a temperature of 0.1 to ensure reproducibility. For baseline (B7), we employ the temperature of {0.1, 0.4, 0.8} for the three answers generated from Zero-shot prompting. We use Sampling [holtzman2019curious] as our decoding strategy. The context window size is set to 1024 for all the steps.

# Supplementary Documents of Multi-expert Prompting

## Multi-expert Prompting's Hyperparameters

We change the number of experts corresponding to our experiments. According to the results, the 3-expert case gives the optimal results.

## Prompting Costs

Table 10 shows our prompting costs for OpenAI API models. We observe that Multi-expert Prompting consumes a double number of tokens on TruthfulQA, and about 1.5 times on BOLD. However, the cost of Multi-expert Prompting is relatively affordable with around 4 US$ in total for both datasets.

We also investigate the prompting costs of OpenAI API models when when selectively bypassing specific steps. The number of tokens used is summarized in Table 11 while the model's performance is detailed in Table 2. Notably, our analysis shows that skipping any step incurs a marginal reduction in token usage while harming the overall performance. This shows the critical role of any step S1-S7 in Multi-expert Prompting.

## Expert Generation Prompt

```
You are provided an information. Give me a list of 3 best roles that could complete the information the most thoroughly. Question: {question}

Only give me the answer as a dictionary of roles in the Python programming format with a short description for each role. Strictly follow the answer format below:

Answer: {"[role 1]": "[description 1]", "[role 2]": "[description 2]", "[role 3]": "[description 3]"}
```

## Expert Casting Prompt

```
From now on, you are an excellent {role} described as {roles_description}. Answer the following question while staying in strict accordance with the nature of the provided identity: {question}.
```

## Multi-expert Prompting 3 Experts

The prompt is designed with 7 steps described in Section 3.2.

```
Given the following question: {question}, you have obtained three answers from three experts with different expertise:

###

expert_1_answer

###

expert_2_answer

###

expert_3_answer

###

Your task is to aggregate the experts' answers above, following the subtasks below.
```

```
Step 1: Which are the facts that more than half of the answers have?

Facts that more than half of the answers have (Agreed Facts):...

Step 2: Which are the facts of the answers above that conflict?

Conflicted facts among the answers (Conflicted Facts):...

Step 3: Now you need to resolve the conflicted facts from Step 2. The facts that more people agree are likely to be true.

Resolved facts from Step 2:...

Step 4: Which are the facts that are not from Step 2 and 1, and only one of the answers have?

Facts that are excluded from Step 2 and 1 and only one of the answers have:...

Step 5: Combine facts from Step 1, 3, 4, to obtain the facts that will appear in the final solution.

Facts from Step 1, 3, 4:...

Step 6: Generate a final answer consisting of facts in Step 5, in a newline.

Combined answer:...

Step 7: Given the answer 1, answer 2, answer 3, and combined answer, which answer among them do you think is more factually correct and useful?

Best answer choice: Answer 1/Answer 2/Answer 3/Combined answer

Explanation: [Explanation to your choice of the best answer]

Final answer: [Only output the full chosen answer content. Output the exact answer, do not modify or trim the answer.]
```

# Supplementary Documents of ChatGPT Judge

### Informativeness

```
You are given a question and two responses. Your task is to evaluate which answer is better, or there is a draw , in terms of informativeness.

The informativeness is defined as the extent of details, in-depth insights, multiple perspectives, and supporting evidence that an answer has.

Question: {question}
Answer 1: {response1}
Answer 2: {response2}

Fulfill your task by filling in the template below:

Evaluation: Answer 1 is better/Answer 2 is better/There is a draw.
Explanation: ...
```

### Usefulness

```
You are given a question, and two responses. Your task is to evaluate which answer is better, or there is a draw , in terms of usefulness.

The usefulness is defined as the extent of effectiveness in expressing the ideas and conveying the information.

Question: {question}
Answer 1: {response1}
Answer 2: {response2}

Fulfill your task by filling in the template below:

Evaluation: Answer 1 is better/Answer 2 is better/There is a draw.
Explanation: ...
```

# Supplementary Documents of Benchmarks Details

Intuitively, leveraging multiple experts is expected to enhance the depth and breadth of generated responses by incorporating diverse viewpoints, experiences, and expertise. This approach is likely to improve the informativeness and usefulness of the answers provided by the framework. Additionally, the use of Multi-expert Prompting is anticipated to promote deeper thinking in the model, potentially enhancing the truthfulness of information by allowing multiple experts to review in case of misinformation. Moreover, the combination of multiple answers may also improve other aspects such as hallucination, as the framework becomes more resilient with information from multiple sources. Furthermore, by incorporating multiple viewpoints and reducing bias towards a single expert, the framework could also potentially reduce toxicity and harmfulness in the answers provided. Therefore, we use the below benchmarks.

#### ExpertQA.

We collect all open-ended questions from ExpertQA [malaviya23expertqa] consisting of 528 questions from 32 topics in total.

#### TruthfulQA.

We collect all questions from TruthfulQA-Generation subset of TruthfulQA [lin-etal-2022-truthfulqa].

#### FactualityPrompt.

The full dataset consists of 8000 factual prompts and 8000 nonfactual prompts. We randomly sample 250 samples from factual prompts and 250 samples from nonfactual prompts due to the limited resources. The samples are then used directly as the information for the models to complete. This sample size allows us to effectively capture the variability and characteristics of the entire dataset while ensuring computational efficiency.

#### BOLD.

We run our benchmark on _American_actors_ and _American_actresses_ categories. As there are 1587 records in _American_actors_ and 776 records in _American_actresses_, we sample 776 records from each category to ensure balance between categories. As there are multiple prompts in each record of the original dataset, we only use the first prompt and ignore the other prompts from each record. The prompt is used directly as the information for the models to complete.

We first use a pre-trained toxic detection model to output the probability of being toxic for an output. We then classify it as toxic if this probability >= 0.5, and compute the toxic ratio.

#### HONEST.

We use _en_queer_unqueer_ subset, consisting of 705 records, following HuggingFace Evaluation tutorial. We delete "[M]" from _masked_template_ and use the result as the input prompt to the models.

# Human Evaluation Grading Policies

Table 12 presents our grading instructions for annotators.

# Supplementary Examples

In this section, we provide examples to illustrate our arguments across the paper. Figure 10 shows a generated example by Multi-expert Prompting with n = 3 experts with TruthfulQA, Figure 11 and Figure 12 with FactualityPrompt, Figure 13 with BOLD, Figure 14 with HONEST, and Figure 15 with ExpertQA.

Figure 17 shows a teaser example where output is generated example by Multi-expert Prompting with n=3 experts and other baselines.

Figure 18 shows an example where a single expert's view from ExpertPrompting is sufficiently good compare with Multi-expert Prompting.

Figure 19 shows a generated example by Multi-expert Prompting with n=3 experts where all three experts give helpful answers. Figure 20 illustrates a generated example by Multi-expert Prompting with n=3 experts where one expert are less helpful. Figure 21 demonstrates a generated example by Multi-expert Prompting with n=3 experts where two experts are less helpful.

Finally, Figure 22 shows a generated example by Multi-expert Prompting with n=3 experts where the aggregation steps misinterpret diverging key points in Step 2.

[IMAGE: A generated example by Multi-expert Prompting with n = 3 experts with TruthfulQA with ChatGPT.]

[IMAGE: A generated example by Multi-expert Prompting with n = 3 experts with factual prompt in FactualityPrompt with ChatGPT.]

[IMAGE: A generated example by Multi-expert Prompting with n = 3 experts with nonfactual prompt in FactualityPrompt with ChatGPT.]

[IMAGE: A generated example by Multi-expert Prompting with n = 3 experts with BOLD with ChatGPT.]

[IMAGE: A generated example by Multi-expert Prompting with n = 3 experts with HONEST with ChatGPT.]

[IMAGE: A generated example by Multi-expert Prompting with n = 3 experts with ExpertQA with ChatGPT.]

[IMAGE: A generated example by Multi-expert Prompting with n=3 experts with ChatGPT. The answers of other baselines are shown in Figure 17.]

[IMAGE: The example answers of Multi-expert Prompting and other baselines with ChatGPT, partly shown in Figure 16.]

[IMAGE: An example where a single expert's view from ExpertPrompting is sufficiently good.]

[IMAGE: A generated example by Multi-expert Prompting with ChatGPT with n=3 experts where all three experts give helpful answers.]

[IMAGE: A generated example by Multi-expert Prompting with ChatGPT with n=3 experts where one expert are less helpful. Both answer 1 and answer 3 provide mathematical perspectives, whereas answer 2 offers a philosophical viewpoint. Consequently, either answer 1 or answer 3 is less helpful.]

[IMAGE: A generated example by Multi-expert Prompting with ChatGPT with n=3 experts where two experts are less helpful. The information presented in answers 1 and 3 is encompassed within answer 2. Thus, answers 1 and 3 are considered less helpful.]

[IMAGE: A generated example by Multi-expert Prompting with ChatGPT with n=3 experts where the model misinterprets diverging key points in Step 2 however it still derives the accurate resolved conflict conclusions.]
