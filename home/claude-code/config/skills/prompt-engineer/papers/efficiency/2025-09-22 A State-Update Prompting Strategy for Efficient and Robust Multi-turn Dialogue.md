# Abstract

Large Language Models (LLMs) struggle with information forgetting and inefficiency in long-horizon, multi-turn dialogues. To address this, we propose a training-free prompt engineering method, the State-Update Multi-turn Dialogue Strategy. It utilizes "State Reconstruction" and "History Remind" mechanisms to effectively manage dialogue history. Our strategy shows strong performance across multiple multi-hop QA datasets. For instance, on the HotpotQA dataset, it improves the core information filtering score by 32.6%, leading to a 14.1% increase in the downstream QA score, while also reducing inference time by 73.1% and token consumption by 59.4%. Ablation studies confirm the pivotal roles of both components. Our work offers an effective solution for optimizing LLMs in long-range interactions, providing new insights for developing more robust Agents.

**Keywords:** Information Filtering, Multi-turn Dialogue, LLMs, Forgetting Phenomenon, Prompt Engineering

# Introduction

Large Language Models (LLMs) have demonstrated remarkable, human-like capabilities across a vast spectrum of tasks [radford2019language-models][brown_language_2020][ouyang_training_2022], from complex reasoning to fluent text generation. Efforts to advance LLMs and address their inherent flaws, such as hallucination, have pursued several key strategies. Prompt engineering techniques, exemplified by Chain-of-Thought (CoT) [wei_chain--thought_2022], aim to refine a model's internal reasoning by promoting step-by-step deliberation. Concurrently, methods like Retrieval-Augmented Generation (RAG) [ragforknoledge-intrnsivetasks][gao2024retrievalaugmentedgenerationlargelanguage] and tool-using [toolformer][yao2023react] enhance factual accuracy by integrating external knowledge from databases and search engines [jin2025searchr1]. Although these approaches differ, they share a critical prerequisite: efficient information filtering. Whether processing complex internal thought processes or large volumes of external documents, an LLM's ability to distill relevant information is paramount for effective downstream reasoning. This dependency has established information filtering as a central bottleneck for developing more capable and reliable LLM systems.

To tackle this filtering challenge, information can be presented to an LLM through two primary interaction paradigms: _single-turn input_, where all information is contained within a single prompt, preserving complete information presentation and internal relationships; and _multi-turn input_, where information is segmented into multiple subsets and progressively input through multiple dialogue turns, allowing the model to focus on shorter contexts with potentially greater reasoning space. However, existing multi-turn dialogue mechanisms exhibit notable limitations, a concern that has been echoed in recent research. demonstrated that LLMs suffer significant performance degradation in multi-turn conversations, with models literally "getting lost" as dialogue progresses [laban2025llmslostmultiturnconversation]. This aligns with our observations that multi-turn interactions, while theoretically offering advantages in context management, face fundamental challenges in practice. First, models demonstrate significantly better comprehension of recently input information compared to earlier inputs, exhibiting a "forgetting phenomenon" [liu-etal-2024-lost]. Second, LLMs struggle to effectively integrate information across different turns for holistic reasoning.

To empirically validate these hypotheses, we designed two targeted experiments using the HotpotQA benchmark [yang-etal-2018-hotpotqa]. First, we investigated the impact of dialogue length on performance. We segmented the 10 provided paragraphs into varying numbers of conversational turns (`latex $N=1, 5, 10$ `) and tasked the model with filtering key information at each step. As shown in Figure 1, F1 scores consistently decrease as the number of turns increases. Notably, this performance degradation is more pronounced in larger models, suggesting that while scaling enhances single-turn comprehension, it does not resolve the challenge of retaining historical context in multi-turn dialogues. Furthermore, to diagnose the cause of this degradation, we examined the impact of information position. We systematically varied the placement of crucial paragraphs, comparing scenarios where they appeared in the first versus the last turn. The results, presented in Figure 2, show that placing key information in the final turn yields significantly higher performance. This finding provides strong evidence for a pronounced recency bias, or "forgetting phenomenon," where the model fails to effectively utilize information from earlier turns.

[IMAGE: Performance degradation with increasing dialogue turns - model_performance_comparison.pdf]

[IMAGE: Impact of information position on comprehension - position_effect_comparison.pdf]

**Figure 1-2:** Experimental validation results. In (a), F1 scores decrease as the number of turns increases, with larger models showing more pronounced degradation on HotpotQA dataset. In (b), models demonstrate better performance when key information is placed in later turns.

To address these limitations, we propose a training-free prompt engineering approach called the **State-Update Multi-turn Dialogue Strategy**. This strategy comprises three core technical components: (1) _State Reconstruction_, where each dialogue turn does not retain complete dialogue history but reconstructs the dialogue state to reduce token consumption; (2) _History Reminder_, which explicitly reminds the model of previously identified key information through a "Previously selected" mechanism; and (3) _XML Structured Output_, using `<info>` tags to ensure result parsability and consistency. Through this design, the strategy improves information filtering performance while significantly reducing token consumption, effectively addressing the problems of insufficient information utilization and forgetting phenomena in traditional multi-turn dialogues.

The main contributions of this work can be summarized as follows:

- We systematically identify and quantitatively analyze core challenges in LLM multi-turn dialogues, including insufficient cross-turn information utilization, inadequate reasoning coherence, and attention bias toward recent inputs.

- We propose a simple yet effective state-update multi-turn dialogue strategy that improves model performance while significantly reducing token consumption, offering dual advantages in both time and space efficiency.

- Through comprehensive experimental validation, we demonstrate the effectiveness of our method and elaborate on its potential applications in agent systems and RAG technologies, providing new research directions for related fields.

# Related Work

A central strategy for improving the performance of LLMs is to equip them with high-quality context. Current research has largely proceeded along two lines of inquiry. The first centers on incorporating external knowledge, epitomized by frameworks such as Retrieval-Augmented Generation (RAG) [ragforknoledge-intrnsivetasks][gao2024retrievalaugmentedgenerationlargelanguage] and Tool-using [toolformer][yao2023react][jin2025searchr1]. These methods provide models with the factual grounding necessary for generating responses by interfacing with external knowledge bases or search engines, primarily tackling the challenge of knowledge acquisition and injection. However, such methods face challenges, including the retrieval of irrelevant information [yue2025inference-rag][zhao2022densetextretrievalbased] and the failure to supply sufficiently useful context [jiang-etal-2023-active-rag][jin2025longcontext]. The efficacy of tool-use, in particular, is highly dependent on the quality of the retrieved information.

In this work, we explore a complementary avenue: the dynamic management and efficient utilization of the model's internal information flow. When multi-turn dialogue is required, the most common strategy is linear history concatenation [sordoni_neural_2015-conversation][brown_language_2020][ouyang_training_2022][touvron2023llama2openfoundation], a process illustrated in Figure 4. However, this approach has been demonstrated to lead to the "Lost in the Middle" phenomenon---a tendency for models to over-rely on information at the extremities of the context while neglecting the intermediate parts, which compromises conversational coherence. Consequently, our work is focused on optimizing LLM performance in multi-turn dialogue settings.

# Method

[IMAGE: Traditional multi-turn dialogue strategy baseline approach - illustrate.pdf]

**Figure 4:** Traditional multi-turn dialogue strategy baseline approach.

[IMAGE: Overview of proposed State-Update Multi-turn Dialogue Strategy framework - overview.pdf]

**Figure 5:** Overview of our proposed State-Update Multi-turn Dialogue Strategy framework with three core components: State Reconstruction, History Reminder, and XML Structured Output.

[IMAGE: Performance Analysis - performance_analysis.pdf]

[IMAGE: Impact of Model Scaling - model_scaling_performance.pdf]

**Figure 6-7:** Comprehensive performance evaluation. (a) F1 Score comparison of our method against the baseline on three multi-turn QA datasets (HotpotQA, QASC, and 2WikiMultiHopQA) with varying conversation lengths (`latex $N = 1, 5, 10$ `). Our state-update strategy consistently and significantly outperforms the baseline, especially in longer dialogues (`latex $N > 1$ `), demonstrating its robustness against the degradation of long-context information. (b) An analysis of performance as a function of model scale, comparing our method with the baseline across different model sizes and N values.

To address the challenges of positional bias and information degradation in traditional multi-turn dialogues, we propose a training-free prompt engineering approach named the **State-Update Multi-turn Dialogue Strategy**. This strategy replaces the conventional method of linearly appending conversation history by reconstructing the dialogue state at each turn. This allows for the reliable accumulation of information while maintaining an efficient, fixed-size context window. The implementation of this strategy relies on a meticulously designed prompt architecture:

A unified system prompt is employed across all turns to establish two core tasks for the model: (1) **Structured Output**: The model is required to encapsulate all supporting sentences within XML tags (<info>) to ensure reliable and parsable outputs. (2) **Cumulative Principle**: The model is instructed that each response must contain **all** supporting sentences found in previous turns as well as the current one.

The conversation proceeds as follows:

- **First Turn (Initialization):** The user provides the question and the initial text passage to start the identification process.

- **Subsequent Turns (`latex $k \geq 2$ `, State Update):** The dialogue state is reconstructed. The user input includes the new text passage, supplemented by the supporting sentences extracted from the previous turn, which serve as an "explicit history reminder."

The core mechanism of this flow is that after each turn, we parse the model's output within the <info> tags and use it as the content for the "Previously selected" field in the subsequent turn. This design offers two significant advantages:

- **Efficiency Enhancement:** Compared to linear history concatenation, the state reconstruction approach significantly reduces the number of input tokens per turn, thereby lowering computational costs and inference latency.

- **Mitigation of Forgetting:** By re-injecting key historical information as an explicit reminder, the strategy compels the model to attend to and integrate the entire context.

# Experiments

## Experimental Setup

**Datasets.** We evaluate our method on three public benchmarks: _HotpotQA_, _2WikiMultiHopQA_, and _QASC_. _HotpotQA_ and _2WikiMultiHopQA_ [xanh2020_2wikimultihop] are multi-hop QA datasets that require reasoning over contexts containing distractor information. For _QASC_ [Khot2019QASC], a non-reasoning QA dataset, we construct a similar multi-turn format by randomly sampling sentences to form the context, mirroring the setup of the other datasets.

**Models.** All experiments are conducted on the Qwen2.5-Instruct series of models [qwen2025qwen25technicalreport], using a consistent decoding temperature of 0.8 and default values for other key hyperparameters.

**Baseline.** We compare against the standard multi-turn conversation strategy as our baseline. In this approach, the model context for each turn is formed by concatenating the current input with the entire preceding conversation history.

**Metrics.** We employ two metrics to assess the quality of the extracted supporting sentences: **Word F1 Score**, a token-overlap-based metric, and an **LLM-based Score** (Info Score and QA Score) evaluated by Gemini 2.5 pro [comanici2025gemini25pushingfrontier] to capture semantic quality.

## Results and Analysis

Our State-Update strategy significantly outperforms the baseline in mitigating catastrophic forgetting during long-turn dialogues. As illustrated in Figure 6, the baseline's performance degrades sharply as the conversation progresses, whereas our method maintains a robust performance trend. At `latex $N=10$ ` turns, our approach achieves an average Word F1 improvement of approximately 10% and an Info Score increase of over 1.5 points, demonstrating its ability to effectively integrate historical information and alleviate the model's forgetting problem.

Furthermore, our strategy offers substantial computational efficiency. As detailed in Table 1, in conversations of `latex $N=5$ ` turns, our method reduces total token consumption by **59.4%** and inference time by **73.1%**. This gain stems from its ability to avoid re-processing the entire conversation history at each turn, establishing it as a highly efficient and practical solution.

To validate the robustness and generalizability of our method, we evaluated its performance across diverse datasets and model scales. Our approach consistently outperforms the baseline on all three datasets, including _HotpotQA_, _2WikiMultopQA_, and _QASC_ (Figure 6). Moreover, this advantage holds across model sizes ranging from 3B to 14B parameters (Figure 7), underscoring that our strategy is a **fundamental improvement** over simple history concatenation, rather than an artifact of a specific experimental setup.

Crucially, the enhanced information filtering directly translates to superior performance on downstream tasks. As shown in Table 1, the context distilled by our method enables the model to achieve a **14.1%** higher score on the final question-answering task compared to the baseline. This confirms that the preserved dialogue state is not only compact and efficient but also highly valuable for complex reasoning, firmly establishing its **significant practical impact**.

## Ablation Study

To validate the architectural design of our method, we conducted an ablation study (Table 1) on its two core components: State Reconstruction (SR) and History Reminder (HR). Removing the SR module (`w/o SR`) caused efficiency to plummet to near-baseline levels, confirming its primary role in context compression. Conversely, removing the HR module (`w/o HR`) led to a catastrophic performance drop, with the Info Score falling from 6.91 to 3.74 and the QA Score from 7.22 to 4.68. This result strongly validates that HR is the cornerstone for cross-turn reasoning and contextual understanding. The study confirms that both components are indispensable, with SR ensuring efficiency and HR driving performance.

# Conclusion

We introduce a novel, training-free State-Updating Multi-turn Dialogue Strategy that leverages a state reconstruction and a history-aware reminding mechanism. Our approach not only significantly enhances performance on information filtering and downstream question-answering tasks by 14.1% but also drastically reduces computational overhead, achieving a 73.1% reduction in inference time and a 59.4% decrease in token consumption. This research confirms that actively and explicitly managing dialogue state is a more efficient interaction paradigm compared to conventional history concatenation methods, offering crucial insights for building more robust memory modules for intelligent agents. As a future direction, we propose exploring how to better manage context input through prompt engineering to make better use of LLMs.
