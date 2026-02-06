# Abstract

Task-oriented dialog (TOD) systems facilitate users in accomplishing complex, multi-turn tasks through natural language. While instruction-tuned large language models (LLMs) have demonstrated strong performance on a range of single-turn NLP tasks, they often struggle with reliable multi-turn task completion in TOD settings, particularly when generating API calls required to interact with external systems. To address this, we introduce RealTOD, a novel framework that improves LLM-based TOD systems through (_1_) prompt chaining and (_2_) fine-grained feedback. Prompt chaining enables zero-shot generalization to new domains by automatically synthesizing a schema-aligned in-context example for the target task. Fine-grained feedback verifies each generated API call against the domain schema, identifies specific errors, and provides targeted correction prompts. To evaluate task completion reliability, we introduce full API Call Accuracy as a robust metric, along with detailed sub-metrics to capture common failure modes. We conduct extensive experiments on the SGD and BiTOD benchmarks using four LLMs. RealTOD improves Full API accuracy, surpassing state-of-the-art AutoTOD by 37.10% on SGD and supervised learning-based baseline SimpleTOD by 10.32% on BiTOD. Human evaluations further confirm that LLMs integrated with RealTOD achieve superior task completion, fluency, and informativeness compared to existing methods.

# Introduction

[IMAGE: Overview of RealTOD: Prompt chaining circumvents the need for human-curated dialog for each task, and fine-grained feedback loop from the API parser significantly improves task completion rates.]

Task-oriented dialog (TOD) systems enable users to accomplish tasks, such as booking flights, making restaurant reservations, and managing appointments, through multi-turn, natural language interactions [he-etal-2022-space]. To successfully complete tasks, these systems must understand user intent, retrieve task-specific information from both user and external systems, and generate coherent responses to guide the user toward task completion (e.g., successful reservation). However, traditional TOD systems require extensive domain-specific fine-tuning using manually annotated datasets [xu2024rethinking; Mi_Wang_Li_2022], making them laborious and expensive to scale across domains.

Recent advances in large language models (LLMs) [Radford2019LanguageMA; brown2020language; Chung2022; shu2024rewritelm] have significantly improved performance across a wide range of single-turn natural language processing (NLP) tasks, such as text classification [sun-etal-2023-text; wang2023large; zhang2024pushing], summarization [Pu2023SummarizationI; zhang-etal-2024-benchmarking; van2023clinical], and machine translation [cui-etal-2025-multilingual; wang-etal-2023-document-level; gain2025bridging]. In addition to these single-step tasks, LLMs have also shown strong capabilities in multi-turn, open-domain dialog settings [Thoppilan2022LaMDALM; naveed2023comprehensive; dubey2024llama; achiam2023gpt], where coherent response generation given dialog context is critical.

Motivated by these advances, recent work has explored leveraging off-the-shelf LLMs for zero-shot TOD settings [xu2024rethinking]. These models can generate fluent and contextually appropriate responses, and with careful prompting, can even be controlled to follow task schemas. However, despite their promise, LLMs often struggle with reliable task completion, particularly when generating API calls required to interact with external systems. Common issues include hallucinated API results, incorrect method names, missing required parameters, and invalid slot-value pairs [10.5555/3666122.3666499; jain2024mitigating; song2025callnavi], all of which can lead to execution failures and incomplete tasks. These issues reveal a critical gap between LLMs' natural language fluency and their ability to execute tasks reliably in multi-turn dialogs, presenting a major barrier to their practical deployment.

To address these issues, we propose RealTOD, a novel framework that enhances LLM-based TOD systems through (_i_) prompt chaining and (_ii_) fine-grained feedback. LLMs' performance on single-turn NLP tasks has been shown to improve significantly when provided with in-context examples [liu-etal-2022-makes; dong-etal-2024-survey; agarwal2024manyshot]. However, applying this strategy in TOD settings presents a practical challenge: acquiring multi-turn dialogs that are both realistic and schema-compliant for each target domain or task is labor-intensive and does not scale. RealTOD addresses this challenge through prompt chaining, which automatically transforms dialogs from a source domain into in-context demonstrations that align with the schema of an unseen target domain. This approach substantially improves zero-shot generalization to unseen tasks in unseen domains without requiring hand-crafted example dialogs for each task. In TOD systems, successful task completion often hinges on generating a correct API call that invokes the correct method and includes all required parameters with valid slot-value pairs. Even small errors in API calls can result in execution failures, ultimately preventing task completion. To mitigate this, RealTOD incorporates a fine-grained feedback mechanism that verifies each generated API call against the target domain specification, identifies specific errors, and provides targeted correction prompts. This iterative process significantly improves the reliability of API calls and, in turn, the overall task completion rate.

In addition to improving task completion in TOD systems, we introduce a rigorous evaluation metric for measuring task success. Existing metrics focus on n-gram-based similarity metrics [papineni-etal-2002-bleu; lin-2004-rouge], which do not reflect whether a task has been successfully executed. To better align evaluation with practical deployment needs, we adopt full API Call Accuracy as our primary metric. An API call is counted as correct only if the method name, parameter names, associated parameter values, and operator match the reference. We further decompose this metric into fine-grained sub-metrics, Method Name Accuracy, Parameter Name Accuracy, Parameter Value Accuracy, and Operator Accuracy, to diagnose specific failure modes. This evaluation setup captures end-to-end task completion reliability. On the other hand, we evaluate the quality of natural language responses using BERTScore [zhang2019bertscore], which assesses semantic similarity between generated and reference responses via contextual embeddings. We also measure diversity [nekvinda-dusek-2021-shades] of the generated text, providing a more robust evaluation than traditional n-gram-based metrics.

We evaluate RealTOD on two benchmark datasets, SGD [rastogi2020towards] and BiTOD [lin2021bitod], using four LLMs: two proprietary models (GPT-4o and Claude) and two open-source models (DeepSeek and LLaMA). Our results show that RealTOD significantly improves API accuracy across all models and datasets. On SGD, it surpasses AutoTOD [xu2024rethinking] by 37.10% in full API accuracy, while on BiTOD, it outperforms supervised fine-tuned SimpleTOD [hosseini2020simple] by 10.32%. Human evaluations confirm that LLMs integrated with RealTOD generate more fluent, informative, and effective task completions than baseline models. Our ablation study demonstrates that both prompt chaining and fine-grained feedback contribute to improved multi-turn dialog quality and reliable task completion.

# Related Works

**Fine-Tuned Task-Oriented Dialog Systems.** TOD systems are typically classified into pipeline-based and end-to-end approaches. Pipeline-based methods [WILLIAMS2007393; lee-2013-structured; LEE2009466; peng-etal-2020-shot; chen-etal-2019-semantically] decompose the system into modular components -- natural language understanding, dialog state tracking, policy learning, and natural language generation -- allowing independent optimization of each module. In contrast, end-to-end approaches [hosseini2020simple; madotto-etal-2018-mem2seq; su-etal-2022-multi; mosharrof2023zero; SiddiqueTOD; lei-etal-2018-sequicity; lin-etal-2020-mintl; imrattanatrai-fukuda-2023-end] generate responses directly, bypassing these modules. A major drawback of these fine-tuned methods is their reliance on high-quality labeled data, which can be a significant limitation.

**LLM-Powered Systems.** The rise of LLMs has led to the development of various intelligent systems, which can be broadly categorized into three classes. The first class includes Web Agents, which facilitate online interactions for information retrieval and task execution [yao2023react; kim-etal-2024-prospector; ma2023laser; fereidouni-etal-2024-grounded; NEURIPS2022_82ad13ec; sridhar2023hierarchical; furuta2024multimodal]. The second class consists of Mobile Agents, which focus on optimizing LLM-based decision-making for performing diverse tasks on mobile applications [bai2024digirl; lee2023explore; AutoDroid; wen2023droidbot; wang2024mobile; wang2024mobilev2]. The third and most relevant class to our work is LLM-powered TOD Systems [chung-etal-2023-instructtods; Mi_Wang_Li_2022; gao-etal-2023-adaptive; hudecek-dusek-2023-large; UnravelingChatGPT]. Specifically, AutoTOD [xu2024rethinking] shares similarities with our approach; however, AutoTOD does not account for the possibility of LLMs making errors in generating API calls and lacks proper evaluation of API accuracy.

**User Simulators.** One of the earliest data-driven user simulators is [EckertUser], where user actions are generated probabilistically based on system actions. Additionally, there have been many advancements in data-driven user simulation. For instance, transformer-based architectures have been leveraged for domain-independent simulation [lin-etal-2021-domain; lin-etal-2022-gentus] with GPT-based models integrating goal state tracking [liu-etal-2022-generative]. Reinforcement learning has also been applied to fine-tune generative simulators [tseng-etal-2021-transferable; cheng-etal-2022-multiwoz]. More recently, in-context learning with LLMs has enabled user simulation without fine-tuning, [terragni2023context; davidson2023user]. Similar to [lin-etal-2021-domain; lin-etal-2022-gentus; liu-etal-2022-generative], our user simulator employs transformer architectures.

# Proposed Framework: RealTOD

We introduce RealTOD, a task-completion-centric, TOD framework that eliminates the need for fine-tuning while seamlessly scaling to new domains. While recent LLM-based TOD systems can generate fluent and contextually appropriate responses, they often fail to execute tasks reliably, particularly when producing API calls needed to interact with external systems. To address this, RealTOD introduces two key innovations: (_1_) prompt chaining, which first transforms a source-domain dialog into a schema-aligned demonstration for a new target task, and then uses the generated dialog as an in-context example, eliminating the need for hand-crafted demonstrations, to enable zero-shot generalization to the target domain on-the-fly; and (_2_) fine-grained feedback, which verifies each generated API call against the domain schema, identifies specific errors, and provides targeted correction prompts to improve task execution reliability.

## Problem Formulation

We formulate multi-turn task completion as a conditional sequence generation problem, where the LLM produces natural language responses or API calls to help users achieve their goals across relevant domains. Each API call includes the method name, a dictionary of parameter names, and their corresponding values.

Formally, a domain `latex $d_x \in D$ ` is characterized by a domain schema, which consists of a set of user intents `latex $\mathcal{I}_{d_x}$ `. An intent represents a specific goal the user aims to achieve through the multi-turn conversation. For example, in the "Flights" domain, an intent might be "Book a Flight". Each intent `latex $i \in \mathcal{I}_{d_x}$ ` is associated with a set of slots `latex $\mathcal{S}_i$ `, where each slot `latex $s$ ` captures relevant constraints to fulfilling the intent. For example, the intent of "Book a Flight" may involve slots such as "departure city" and "destination city". We define a slot `latex $s$ ` as a tuple: `latex $$s = (\texttt{name}(s), \texttt{is\_required}(s), \texttt{values}(s))$$ ` where `latex $\texttt{name}(.)$ ` specifies the slot's name (e.g., "departure city"), `latex $\texttt{is\_required}(.)$ ` is a boolean flag indicating whether the slot is mandatory, and `latex $\texttt{values}(.)$ ` specifies a predefined set of possible values for categorical slots (e.g., "business class", "economy class" in the "Flights" domain). If the slot accepts free-form inputs, this field remains empty. For brevity, we will refer to the name of a slot `latex $\texttt{name}(s)$ ` as `latex $s_m$ `. Formally, the schema for a domain `latex $d_x$ ` is represented as: `latex $$\Sigma_{d_x} = (d_x, \mathcal{I}_{d_x}, \{ \mathcal{S}_i \mid i \in \mathcal{I}_{d_x} \}).$$ `

In addition to generating natural language responses, the model may need to retrieve information from external systems or execute actions via API calls to accurately fulfill a user's goal. Each API call corresponds to a specific intent in a domain and a set of specified constraints, represented as slot-value pairs. Formally, an API call `latex $a_n$ ` is defined as: `latex $a_n = \texttt{API}(\texttt{method} = i,  \texttt{parameters} = \{(s_m , v), (\cdots) \mid s_m \in \mathcal{S}_i\}),$ ` where `latex $i$ ` is the intent, `latex $s_m$ ` is the slot name, and `latex $v$ ` is its assigned value. For instance, in the "Flights" domain, an API call for booking a flight may look like: `latex $\texttt{API}(\texttt{method} = \text{``Book\_a\_Flight''}, \texttt{parameters} =\{ (\text{``departure\_city''}, \text{``New York''}), (\text{``destination''},\\ \text{``London''}), (\cdots) \}).$ `

A dialog session in a domain `latex $d_x$ ` consists of a sequence of user utterances and system responses across multiple turns. We define a session `latex $\mathcal{T}_{d_x}$ ` of up to `latex $T$ ` turns as: `latex $$\mathcal{T}_{d_x} = \bigl((u_1, r_1), (u_2, r_2), \dots, (u_T, r_T)\bigr)$$ ` where `latex $u_t$ ` is the user's utterance at turn `latex $t$ `, `latex $r_t$ ` is the system's response at turn `latex $t$ `, which can either be a natural language reply or an API call, depending on the current task context. The dialog history up to turn `latex $t$ `, denoted as `latex $H_t$ `, consists of all previous exchanges up to and including the current user utterance: `latex $H_t = \{(u_1, r_1), (u_2, r_2), \dots, (u_{t-1}, r_{t-1}), u_t\}.$ `

## Prompt Chaining

In-context examples have been shown to substantially improve LLM performance in a wide range of single-turn NLP tasks [liu-etal-2022-makes; dong-etal-2024-survey; agarwal2024manyshot]. However, their potential in multi-turn, schema-constrained dialog tasks, such as those in TOD systems, remains under-explored. Unlike single-step tasks, TOD requires models to track dialog history, collect slot values across multiple turns, and conform to structured API schemas. Manually creating such in-context examples for every target domain is labor-intensive and hinders scalability. To address this, RealTOD introduces a two-stage prompt chaining mechanism that enables zero-shot generalization to new domains without requiring any hand-crafted dialogs. Specifically, RealTOD employs a two-stage prompt chaining mechanism, which consists of two sequential prompting phases: (_i_) example dialog generation that transforms an example dialog from a source domain into a target domain while maintaining task-specific consistency; and (_ii_) task adaptation that leverages the generated example dialog for in-context learning in the target domain.

**Example Dialog Generation.** The first phase constructs an example dialog in the target domain by leveraging the schema mapping between the source domain and target domain. Formally, the inputs to LLM in this phase include the source domain schema `latex $\Sigma_{d_x}$ `, an example dialog `latex $\mathcal{T}_{d_x}$ ` in the source domain, an instruction prompt `latex $P_1$ ` specifying the transformation process, and the target domain schema `latex $\Sigma_{d_y}$ `. The output is a new example dialog `latex $\mathcal{T}_{d_y}$ ` that aligns with the intents `latex $\mathcal{I}_{d_x}$ ` and associated slots `latex $\mathcal{S}_{i_x}$ ` in the target domain `latex $d_y$ `.

**Task Adaptation.** Once the example dialog `latex $\mathcal{T}_{d_y}$ ` in target domain `latex $d_y$ ` is generated, the second phase leverages this as an in-context learning example to enhance the model's adaptation in the target domain. At each dialog turn `latex $t$ `, the inputs to the LLM include the target domain schema `latex $\Sigma_{d_y}$ `, the generated example dialog `latex $\mathcal{T}_{d_y}$ `, the dialog history up to turn `latex $t$ ` (denoted as `latex $H_t$ `), and an instruction prompt `latex $P_2$ ` that guides the response generation process.

The LLM then produces the system response `latex $r_t$ `, which can be either a natural language reply or an API call, depending on the current task context. Since a single dialog may span multiple domains, we can denote the set of target domains involved in a dialog session as `latex $\{d_1, d_2, \dots, d_m\} \subseteq D$ `, and extend to the formulation to condition on all relevant domain schemas `latex $\{\Sigma_{d_j}\}_{j=1}^{m}$ `.

**Instruction Prompts.** The prompt `latex $P_1$ ` begins with a task description on generating a dialog from a schema, then presents domain_X's schema and its sample conversation. It instructs the LLM to analyze this structure, apply it to domain_Y, and generate a corresponding conversation. (For the full prompt `latex $P_1$ `, see Appendix.) The instruction prompt `latex $P_2$ ` consists of two main parts: a task description and general guidelines. It directs the system to collect required slot values before API calls and use search results for accurate responses. The guidelines emphasize limiting slot requests per turn and confirming user inputs before invoking the API call. (For the full prompt `latex $P_2$ `, see Appendix.)

## Fine-Grained Feedback

In TOD systems, successful task completion often depends on generating precise API calls that invoke the correct method and include all required parameters with well-formed slot-value pairs. However, LLMs, despite their fluency, operate in a free-form text generation mode and must reason over a long dialog history, while adhering to rigid schema constraints. This often results in API calls that are incomplete, inconsistent, or even invalid, issues that cannot be reliably prevented through prompting alone. To minimize these errors and ensure successful task execution, RealTOD integrates a fine-grained feedback mechanism via a generic API parser. Given a domain schema `latex $\Sigma_{d_x}$ ` and an API call `latex $a$ `, the parser verifies the correctness of the request before execution. If the API call conforms to the schema, it is passed for execution; otherwise, the parser provides fine-grained feedback to the LLM for correction. The verification process identifies three types of errors: (_i_) incorrect method name, where the API method does not match any intent `latex $i \not\in \mathcal{I}_d$ `; (_ii_) incorrect slot name, where a provided slot is not defined in the schema `latex $s_m \not\in \mathcal{S}_i$ ` for the given intent; and (_iii_) missing required slots, where required slots `latex $s_m$ ` with `latex $\texttt{is\_required}(s_m) = \text{True}$ ` are absent in the API parameters. Upon detecting an error, the parser returns fine-grained feedback specifying the issue, allowing the LLM to correct its response.

# User Simulator

Evaluating a TOD system ideally requires interactions with real users to assess its effectiveness in goal-oriented scenarios. However, deploying and managing real-user evaluations is expensive and time-consuming. To overcome this challenge, we develop a goal-driven user simulator that can interact with TOD systems in a controlled and scalable manner. An effective user simulator must first accurately convey its needs by specifying the required slot values (e.g., 'departure city') before optionally requesting information (e.g., the flight's arrival time) from the TOD system. To construct such a simulator, we utilize dialog data `latex $\mathcal{T}_{d_x}$ ` consisting of user goals, expressed through API calls `latex $A = [a_1, a_2, \dots, a_n]$ `, and the request slots `latex $R =  [s_1, s_2, \dots, s_m]$ ` that the user should request. To train the user simulator, we optimize an instruction-finetuned model as: `latex $$\mathcal{L} = - \sum_{k=1}^{|u_t|} \log p(w_k \mid w_{<k}, H_t, A, R),$$ ` where `latex $w_k$ ` denotes the `latex $k$ `-th token in the user utterance `latex $u_t$ ` at turn `latex $t$ `, and `latex $w_{<k}$ ` represents all preceding tokens in the same utterance. The simulator learns to express user goals in natural language by answering requested slots from the TOD system, and requests additional information from the TOD system, conditioned on the set of API calls `latex $A$ `, request slots `latex $R$ `, and dialog context `latex $H_t$ `. To conduct an interactive session between a trained user simulator and the TOD system, the simulator initiates the conversation by retrieving the first user goal `latex $a_1$ ` from `latex $A$ ` and associated request slot `latex $s_1$ ` from `latex $R$ `. This process continues iteratively until all user goals in A and their associated request slots in R have been processed.

# Experiments

## Datasets

We conduct our experiments using two datasets: the Schema-Guided dialog (SGD) dataset [rastogi2020towards] and the Bilingual Task-Oriented dialog (BiToD) dataset [lin2021bitod]. Since BiToD includes dialogs in both Chinese and English, we retain only the English dialogs for our analysis. Both datasets provide domain-specific schemas along with corresponding dialog conversations, which are essential for baseline models. A comparative summary of key statistics for both datasets is presented in Table 1.

| Statistic                       | SGD    | BiTOD |
| ------------------------------- | ------ | ----- |
| Total Dialogs                   | 4,201  | 352   |
| Total Dialogs (Single-domain)   | 1,331  | 111   |
| Total Dialogs (Multi-domain)    | 2,870  | 241   |
| Total API Calls                 | 13,239 | 1,005 |
| Total API Calls (Single-domain) | 2,188  | 127   |
| Total API Calls (Multi-domain)  | 11,051 | 878   |
| Total Turns                     | 89,428 | 6,979 |
| Total User Req. Slots           | 8,271  | 500   |
| Avg. API calls per dialog       | 3.15   | 2.85  |
| Avg. API calls (Single-domain)  | 1.64   | 1.14  |
| Avg. API calls (Multi-domain)   | 3.85   | 3.64  |
| Avg. turns per dialog           | 21.28  | 19.82 |
| Avg. User Req. Slots            | 1.96   | 1.42  |
| Avg. parameters per API call    | 2.96   | 3.51  |
| Total Unique API methods        | 34     | 7     |
| Total Unique API parameters     | 88     | 20    |

Table: Test Dataset Statistics for SGD and BiTOD.

## Experimental Setup

We integrated four LLMs in RealTOD: two open-source models, DeepSeek-V3 [liu2024deepseek] and Llama-3.3-70B-Instruct [dubey2024llama], and two proprietary models, GPT-4o [achiam2023gpt] and Claude 3.5 Sonnet [anthropic2023claude]. For GPT-4o, we accessed the model via the official OpenAI API, while Claude 3.5 Sonnet was queried using the official Anthropic API.

We fine-tune Flan-T5 model [Chung2022] to act as a user simulator for each dataset. Specifically, we use the "google/flan-t5-base" model, consisting of 250 million parameters. During fine-tuning, we set the warm-up steps to 100 and applied early stopping with patience of three. The models were trained for 10 epochs.

## Evaluation Metrics

To comprehensively evaluate the performance of RealTOD and baseline models, we assess the following: (_i_) Dialog-Level System Response, (_ii_) Dialog-Level Language Diversity, (_iii_) API Call, and (_iv_) Dialog Success Rate.

**Dialog-Level System Response.** To assess the quality of the responses generated by RealTOD, we removed all user responses produced by our user simulator, retaining only system responses. We then concatenated all system turns into a single text containing only system-generated outputs. The same process was applied to the ground truth dialog, keeping and concatenating only the system turns. Finally, we evaluated system response quality at the dialog level by comparing the generated responses to the ground truth using BERTScore [zhang2019bertscore], a metric that measures semantic similarity between texts. Furthermore, we utilize "microsoft/mpnet-base" as the foundational model for computing BERTScore.

**Dialog-Level Language Diversity.** To assess the lexical diversity of the system responses, we compute Shannon Entropy (SE) and Bigram Conditional Entropy (CE) over the system turns [terragni2023context; xu2024rethinking]. Following the same preprocessing steps as in the previous section, we remove all user turns and concatenate only the system responses for each dialog. The SE and CE are then computed at the dialog level to quantify the diversity and richness of the language used by the model.

**API Calls.** To evaluate the quality of API Calls, we first extract the key-value pairs `latex $(name(s_k),v_k)_{k=1}^n$ `, along with method name `latex $i$ ` from the generated API call using regular expressions. _Method Accuracy_ evaluates whether the generated API call uses the correct method name, assessed using exact matching. _Parameter Name Accuracy_ determines whether all ground truth key names are included in the generated API call, using fuzzy matching. _Parameter Value Accuracy_ verifies if the value associated with a correctly predicted key matches the ground truth, also using fuzzy matching. Notably, this metric is computed only when the corresponding _Parameter Name_ is correctly predicted. _Operator Accuracy_ applies specifically to the BiToD dataset, as only this dataset includes API calls with operators (e.g., "at_least", "one_of"). We assess this using fuzzy matching. _Full API Accuracy_ measures whether the entire API call -- including the method, parameter, values, and, for BiToD, the operator -- matches the ground truth.

**Dialog Success Rate.** This metric measures the percentage of dialogs in which all API calls achieve 100% _Full API Accuracy_. In other words, it represents the proportion of dialogs where every generated API call matches the ground truth, ensuring complete correctness throughout the dialog.

## Baseline Methods

We compare RealTOD against several strong baselines.

**SyncTOD** [saley-etal-2024-synergizing] improves in-context learning for LLM-powered task-oriented dialog systems by using an auxiliary model to predict hints about the expected response, which guide the selection of proper in-context exemplars.

**AutoTOD** [xu2024rethinking] is a zero-shot task-oriented dialog agent that eliminates traditional modules, relying only on instruction-following LLMs like GPT-4. It requires no task-specific training and autonomously decides actions, queries APIs, and generates responses.

**ZS-TOD** [mosharrof2023zero] is a zero-shot task-oriented dialog system that generalizes to unseen domains using domain schemas instead of memorizing task-specific patterns. It replaces full dialog history with a concise summary, reducing context complexity.

**Q-TOD** [tian-etal-2022-q] is a query-driven task-oriented dialog system that employs a Transformer to generate natural language queries from the dialog context for retrieving relevant knowledge, which is then used to generate system responses.

**SOLOIST** [peng2021soloist] is a Transformer-based task-oriented dialog system that unifies multiple dialog modules into a single pre-trained model. It leverages transfer learning and machine teaching, allowing adaptation to new tasks with minimal labeled data.

**SimpleTOD** [hosseini2020simple] treats task-oriented dialog as a single sequence generation problem, using a causal language model to predict dialog state, actions, and responses auto regressively.

# Results and Analysis

Here, we focus on the accuracy of API calls generated by the dialog system and the overall quality of system responses at the dialog level. A fine-grained evaluation metric for system responses is provided in Appendix. For details on user simulator performance, see Appendix.

## Evaluating the Quality of API Calls

Table presents the API call accuracy results on both the SGD and BiToD datasets.

**Comparing RealTOD Performance to Baselines.** A key observation is that across both datasets, nearly all variants of RealTOD outperform the baseline models across all evaluation metrics, including Method Accuracy, Param Names Accuracy, Param Values Accuracy, Operator Accuracy (for BiToD), and Full API Accuracy. Notably, when focusing on Full API Accuracy, we see substantial gains of RealTOD over baselines. For instance, Claude surpasses AutoTOD, the strongest baseline, by 37.10% in Full API Accuracy on the SGD dataset. Similarly, on BiToD, GPT-4o outperforms SimpleTOD, the best baseline model, by 10.32%, highlighting the robustness of our approach. Moreover, to view the dialogs generated by RealTOD, please refer to Appendix.

**Open-Source vs. Proprietary Models.** A notable trend in Table is the consistent superiority of proprietary models (GPT-4o, Claude) over open-source counterparts (DeepSeek, Llama) in terms of Full API Accuracy across both datasets. For instance, on the SGD dataset, Claude outperforms DeepSeek by 20.60%, while on BiTOD, GPT-4o achieves a 31.96% higher Full API Accuracy than Llama. These results underscore the performance gap between proprietary and open-source LLMs.

**Model-Specific Observations.** Interestingly, when comparing Llama and DeepSeek in the Table, their relative performance depends on the dataset. While Llama yields higher accuracies in most metrics on SGD, the trend reverses in BiToD, where DeepSeek significantly outperforms Llama on almost all metrics. We attribute this to DeepSeek's closer alignment with Chinese data, which proves advantageous for BiToD's English subset that still contains Chinese references (e.g., restaurant names). This shows that LLM performance in TOD tasks depends on alignment with the dataset's language and domain.

**Comparison Between Metrics.** Across both datasets, we observe that all models, including baselines and RealTOD, tend to perform better on Method Accuracy and Parameter Names Accuracy than on Parameter Values Accuracy and Operator Accuracy. This suggests that identifying the correct method or parameter name from the domain schema is generally easier than generating the appropriate value or selecting the correct operator.

## Evaluating the Quality of System Responses

So far, we have evaluated the dialog systems primarily based on their ability to generate accurate API calls. However, assessing the overall performance of the dialog systems also requires analyzing the quality of their natural language responses. To this end, we refer to Table. This table shows that SyncTOD consistently outperforms other methods in terms of BERTScore (F1) across both the SGD and BiTOD datasets. This is expected, as SyncTOD is designed to produce responses that closely align with the style of the source dataset. Following SyncTOD, the supervised models rank second in BERTScore (F1), which is again unsurprising given that they are trained to mimic the language patterns found in the training data.

However, a high BERTScore does not necessarily indicate that a model generates high-quality responses. It primarily reflects surface-level similarity to reference responses. Therefore, to evaluate the richness of the generated text, we also consider diversity metrics. As shown in Table, RealTOD clearly excels in this regard, achieving the highest scores in both Shannon Entropy (SE) and Bigram Conditional Entropy (CE). This suggests that while RealTOD's responses may be slightly less similar to the reference responses (as reflected by its lower BERTScores), they are more varied and diverse. Such diversity is a valuable trait in dialog systems, as it helps prevent repetitive or overly generic replies.

## Ablation Study

To assess the effectiveness of our proposed components, Fine-Grained Feedback and Prompt Chaining, we conducted an ablation study using 100 dialog conversations sampled from the SGD dataset (50 from multi-domain and 50 from single-domain). We evaluated all four variants of RealTOD (GPT-4o, Claude, Llama, and DeepSeek) under four different settings: one without either of the components, one with Fine-Grained Feedback only, one with Prompt Chaining only, and one with both components. Moreover, we used the Full API Accuracy as our comparison metric. This experimental design allowed us to isolate the impact of each component and determine their individual and combined contributions to performance. The results are provided in the Table. As it can be seen in Table, adding Fine-Grained Feedback alone leads to moderate improvements, indicating its role in refining APIs. Prompt Chaining, on the other hand, provides a more substantial boost. The combination of both components yields the highest accuracy, demonstrating their complementary nature.

[IMAGE: Human Evaluation Results on SGD and BiTOD. Evaluators rated generated conversations from 1 to 5 based on three aspects: informativeness, fluency, and task completion.]

## Human Evaluation

We conducted a human evaluation using Amazon Mechanical Turk to assess the performance of our models. As baselines, we selected SOLOIST and AutoTOD, based on their good performance in Table, and compared them against all four variants of RealTOD. For our evaluation, we sampled 100 dialogs from the test sets of our chosen datasets (SGD and BiToD), with 50 each from single and multi-domain tasks. We asked the human evaluators to rate the generated conversations on a scale of 1 to 5 across three key aspects: _Informativeness_, _Fluency_, and _Task Completion Rate_. Figure shows the human evaluation results, where all four variants of RealTOD outperformed the baseline models (SOLOIST and AutoToD), supporting the reliability of our evaluation metrics.

[IMAGE: Dialog success rate declines as the number of API calls increases across models on the SGD and BiTOD datasets. This trend underscores the challenge of error propagation in LLM-powered TOD systems, where early mistakes adversely affect later interactions.]

## Dialog Success Rate

To rigorously assess the quality of the generated dialogs, we conducted an experiment to measure the dialog success rate as the number of API calls within a dialog increases. As shown in Figure, all variants of RealTOD exhibit a declining trend in dialog success rate as the number of API calls increases. This trend is consistent across both the SGD and BiTOD datasets. The primary reason for this decline is the interdependence of API calls. For example, when a user books a restaurant at a particular destination, the same location is often referenced for booking a taxi or later searching for nearby hotels. Any errors in earlier API calls can propagate, making subsequent calls more prone to failure. The Figure highlights a limitation of LLM-powered TOD systems, suggesting that they are still far from achieving perfect performance. Further research is needed to enhance their ability to handle these scenarios more effectively.

# Conclusion

We presented RealTOD, a task-completion-centric framework for TOD systems that eliminates the need for domain-specific fine-tuning and enables reliable performance across diverse domains. Our work tackles a fundamental limitation of current LLM-based TOD systems: their inability to consistently complete tasks due to unreliable API call generation, despite their fluency in natural language responses. RealTOD introduces three key innovations: (_1_) a prompt chaining mechanism that enables zero-shot generalization to new tasks and domains by automatically generating schema-aligned in-context demonstrations; (_2_) a fine-grained feedback loop that verifies each API call against the domain schema and provides targeted prompts to guide correction, significantly improving task execution reliability; and (_3_) a task-centric evaluation metric that goes beyond traditional n-gram-based metrics by precisely assessing task completion through full API call accuracy and detailed error breakdowns. Through comprehensive experiments across two benchmark datasets and four LLMs, we demonstrate that RealTOD achieves substantial gains in task success rates, setting a new standard for LLM-based TOD systems. Beyond these performance improvements, our analysis reveals persistent challenges in dialog-based task completion, including domain coverage errors in multi-domain settings, failures in long-horizon planning across turns, and misalignment when integrating external search results, highlighting directions for future research.

# Inform Accuracy

**Inform Accuracy Metric.** To evaluate how effectively RealTOD informs the user about the requested slots, we implemented a regex-based system. First, we identify the slots requested by the user and extract their corresponding values from the search results. Then, we use regex matching to determine whether the system's subsequent responses include those extracted values. If a system turn contains the requested slot values, we consider the system to have successfully provided the required information.

**Analysis on Inform Accuracy Results.** As expected, Table shows that LLM-powered models perform strongly on the Inform Accuracy metric. On the SGD dataset, our method RealTOD-GPT-4o achieves the highest Inform Accuracy across the Single, Multi, and Both domain settings, with RealTOD-DeepSeek ranking second. On the BiToD dataset, however, AutoTOD outperforms all other models. These results reinforce that LLMs, especially when supported by a dedicated system architecture such as RealTOD, are highly effective at accurately providing requested slot values.

# Limitations

We restricted our experiments to four popular LLMs (GPT-4o, Claude 3.5 Sonnet, DeepSeek-V3, and Llama-3.3-70B-Instruct) due to time and computational constraints. Given the rapid pace of model development (systems such as DeepSeek R1 [guo2025deepseek], OpenAI o3-mini [o3], and Qwen-2.5 Max [qwen2024max], it remains an open question how RealTOD would perform with these newer LLMs.

Moreover, while the user simulators fine-tuned in this study perform reasonably well, they are not perfect and may occasionally struggle to respond accurately to RealTOD. Further details on their performance can be found in the next Appendix.

# User Simulator Performance

To evaluate the performance of our user simulator, we computed BERTScore on user turns (BERTScore User) and on the concatenation of both user and system turns (BERTScore Overall). As shown in Table, most BERTScores fall within the range of approximately 0.6 to 0.7, showing that the simulated user responses maintain a reasonable level of similarity to the reference.

# Example Dialog Responses

Tables present an example of a multi-domain conversation where our User Simulator interacts with different variants of RealTOD (Claude, GPT-4o, DeepSeek, and Llama) to check the weather, schedule a property visit, and reserve a car. Additionally, Tables showcase examples generated by the two baseline models SOLOIST and ZS-TOD. Both of these models struggle with task completion; SOLOIST, on the second turn, missed the API call. The same thing happened when ZS-TOD completely forgot to make the API call when handling a car reservation, ultimately failing to provide the requested information.

# Instruction Prompt Template P1

**Task Description:**

Your task is to generate a dialog conversation between a User and a System based on a given domain schema. I will provide a **Schema** for **{domain_X}**, which defines the structure and relevant entities, along with a corresponding dialog conversation for reference. Your goal is to analyze the relationship between the dialog and the schema and then generate a coherent and contextually appropriate dialog conversation for **{domain_Y}** while maintaining consistency with its schema.

Here is a **Schema** for the **{domain_X}**

**service_name:** **{domain_X}**

**Intents**

**intent_no.**

**name**: IntentName

**is_transactional**: True/False

**required_slots**: required slot 1, required slot 2, required slot 3, ...

**optional_slots**: optional slot 2, optional slot 2, optional slot 3, ...

**Slots**

**slot_name**: slot name 1, slot name 2, slot name 3, ...

**possible_values**: value 1, value 2, value 3, ...

_end of schema for {domain_X}_

A sample **<< Dialog Conversation >>** between a System and a User will be fetched.

Now, understand the above conversation structure between a User and a System. You will be given a new **Schema** for **{domain_Y}**. You have to generate a full-fledged conversation for the new domain that will be structured like the example above.

Here is a **Schema** for the **{domain_Y}**

**service_name:** **{domain_Y}**

**Intents**

**intent_no.**

**name**: IntentName

**is_transactional**: True/False

**required_slots**: required slot 1, required slot 2, required slot 3, ...

**optional_slots**: optional slot 2, optional slot 2, optional slot 3, ...

**Slots**

**slot_name**: slot name 1, slot name 2, slot name 3, ...

**possible_values**: value 1, value 2, value 3, ...

_end of schema for {domain_Y}_

Based on the above instructions and example conversation from the domain_X, learn how to generate the full conversation for the new domain_Y domain.

_End of Instructions._

# Instruction Prompt Template P2

**Task Description:**

Think of yourself as an expert chat assistant specialized in the **{domain_name}** domain. Your task is to generate the most natural and helpful responses for a given task-oriented dialog context. I will provide **Schema** for **{domain_name}**, one sample conversation between a System and a User, optionally, search results from the database. Understand the dialog relation to **Schema**. You can request slot values from the User to fulfill the User's current **intent**. Remember that required **slots** are more important than optional **slots**. When making **API** calls, use column names from the **Schema** as parameters. Match the required and optional **slots** with the column names and use them in **API** calls. Before making the call, ensure you've gathered all required **slots** from the User. You can skip unnecessary parameters.

Here is a **Schema** for the **{domain_name}**

**service_name:** **{domain_name}**

**Intents**

**intent_no.**

**name**: IntentName

**is_transactional**: True/False

**required_slots**: required slot 1, required slot 2, required slot 3, ...

**optional_slots**: optional slot 2, optional slot 2, optional slot 3, ...

**Slots**

**slot_name**: slot name 1, slot name 2, slot name 3, ...

**possible_values**: value 1, value 2, value 3, ...

_end of schema_

A sample **<< Dialog Conversation >>** between a System and a User will be fetched.

Understand the above structure of conversation between a User and a System. Learn how to interact with the User and generate the most human-like conversational response to the User's **intent**. You may need to make **API** Calls and use the **API** Call results. Based on the above instructions and examples from the **{domain_name}** domain, learn how to interact with a User to generate the most human-like conversational response to the User's current **intent**.

_End of Instructions._

Here are a few general **Guidelines** to follow:

- Please avoid asking for too many **slots** in one turn; ideally, ask one slot at a time.

- Don't overwhelm the User with too many questions or choices in one turn.

- Confirm the slot values with the User before finalizing the **API** Call.

- Follow the structure of **API** Call from the above example whenever you are making an **API** Call.

- If you're unsure about something, it's always better to ask or confirm with the User.

- Do not provide all the information in the search results to the User. Provide details only if the User requests them.

- If you feel the User is confused, guide the User with relevant suggestions and ensure it is relevant to their current **intent**.

- You generate only one system response at a time and do not produce search results yourself; search results will be provided to you.

**Conversation history:** << conversation history >> up to turn t will be fetched

# User Study Instructions

## Disclaimers of any risks to participants or annotators

There are no significant risks associated with participating in this study. However, annotators may experience mild fatigue or cognitive strain due to prolonged reading and evaluation of multiple conversations. If you feel discomfort or fatigue, please take breaks as needed.

## Instructions for Human Study Participants

Your task is to evaluate model-generated responses in multi-turn, task-oriented conversations based on the following criteria:

1. Fluency

2. Informativeness

3. Task Completion

## Task Overview

- You will be presented with multiple conversations, where a user interacts with a model to complete a task (e.g., booking a flight).

- Your job is to rate each model response independently using a 1-5 scale based on the provided criteria.

- This study is blind -- you will not know which model produced which response.

## How to Rate Responses

You will assign a score for each response based on the following:

### 1. Fluency

Measures whether the response is grammatically correct, well-structured, and natural to read.

- 1 = Unnatural, grammatically incorrect, or hard to read.

- 5 = Perfectly fluent, natural, and error-free.

**Example (Good Fluency)**

> User: I need to book a flight to New York next Monday.
> Model: Sure! What time would you like to depart?

**Example (Poor Fluency)**

> User: I need to book a flight to New York next Monday.
> Model: Sure! You next Monday flight want time what?

### 2. Informativeness

Measures whether the response provides useful and relevant information to advance the task.

- 1 = Vague, incorrect, or unhelpful.

- 5 = Precise, relevant, and useful.

**Example (Good Informativeness)**

> User: Can you recommend a vegetarian restaurant nearby?
> Model: Yes! Green Leaf Cafe is a highly rated vegetarian restaurant.

**Example (Low Informativeness)**

> User: Can you recommend a vegetarian restaurant nearby?
> Model: There are many restaurants in your area.

### 3. Task Completion

Measures whether the response successfully progresses or completes the task in the conversation.

- 1 = Fails to address the request.

- 5 = Fully completes the task.

**Example (Good Task Completion)**

> User: I'd like to book a table for two at an Italian restaurant at 7 PM today.
> Model: I found a reservation at Bella Italia for 7 PM. Would you like me to reserve it for 2 people at 7 PM today?

**Example (Failed Task Completion)**

> User: I'd like to book a table for two at an Italian restaurant at 7 PM.
> Model: There are Italian restaurants in your area.

## Additional Guidelines

- Be objective -- rate based on quality, not personal preference.

- If a response is unclear or ambiguous, leave a comment.

- Do not try to guess which model produced the response.

## Study Duration & Submission

- The study will take approximately 10 minutes to complete.

- Once you have evaluated all responses, submit your ratings.
