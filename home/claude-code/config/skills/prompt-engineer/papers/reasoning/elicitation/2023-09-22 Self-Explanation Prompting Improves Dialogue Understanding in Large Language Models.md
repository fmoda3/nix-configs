# Introduction

Recent advancements in large language models (LLMs) have achieved great success in various NLP tasks. [gpt3; llama2; chowdhery2022palm]. However, the vast model parameters pose challenges in downstream fine-tuning. To circumvent these challenges, diverse zero-shot prompting strategies have been researched to enhance LLM performance [gpt3; liu2021makes; sorensen2022information]. _In-context learning_ emerges as a viable alternative to fine-tuning, leveraging examples to augment language processing abilities. To elicit the reasoning ability of LLMs, Chain-of-Thought has been seamlessly integrated within the prompting framework, showing remarkable performance in tasks requiring complex reasoning [cot; cot_arithmetic; cot_comonsense]. Stemming from CoT prompting, numerous studies have delved into refining CoT via prompt design modifications [li2022advance; fu2022complexity; zhang2022automatic] and optimizing reasoning paths [self; wang2022rationale; zelikman2022star]. In contrast, to reduce dependency on human demonstrations, the Zero-shot CoT [zero-shot_cot] employs the post-append instruction, 'Let's think step by step,' urging Large Language Models (LLMs) to derive the stages of reasoning sequentially and automatically.

[IMAGE: running_example.pdf - The input example for the reasoning task and the task-oriented dialogue is structured into two components: Context and Question.]

|       **Task**       | **Dataset** |        | **Context** |          |                  | **Focus on** |
| :------------------: | :---------: | :----: | :---------: | :------: | :--------------: | :----------: |
|      Reasoning       | MultiArith  |  16.6  |    Short    | Internal | Chain-of-Thought |  Reasoning   |
|                      |    GSM8K    |  33.6  |             |          |  Plan-and-Solve  |     Step     |
| Dialog Understanding |     SGD     | 940.9  |    Long     | External | Self-Explanation |   Context    |
|                      |  MultiWOZ   | 1229.7 |             |          |                  |              |

Despite the effectiveness of CoT prompting, most existing prompting methods focus on eliciting the reasoning ability inherent in large language models. However, these techniques might fall short when applied to tasks that require contextual comprehension rather than reasoning steps. Specifically, dialogue-based tasks [lin2022duplex; hu2022unimse; li2023unisa] serve as typical examples that require strong comprehension ability rather than reasoning ability. The task-oriented dialogue (TOD) [he2022space; he2022unified; he2022galaxy] is one of the most representative tasks that facilitates users in executing various activities, including but not limited to hotel and restaurant reservations, by engaging in multi-turn dialogues [gao2023unsupervised; qian2023empathetic; yu2023speech]. An illustrative example of both the reasoning task and the TOD can be seen in Figure 1. Contrary to the reasoning task, which typically consists of concise context, the TOD mostly involves multi-turn dialogues with long contexts. Not only do these tasks differ in terms of context length, but they also exhibit variations across numerous other dimensions. For instance, as delineated in Table 1, the reasoning task predominantly emphasizes intricate problem-solving steps that entail extensive computations and conversions. This underscores the model's inherent ability to reason. Consequently, the scope of searching for an answer predominantly resides within the model.

However, when performing dialogue-based tasks, success depends on a strong understanding of the context in continuous conversational exchanges rather than complex reasoning. TOD tasks mainly obtain information directly from the existing context, making the search space for answers strongly related to external contexts. The different emphases of the two tasks resulted in the underperformance of CoT prompts in dialogue contexts. Judging from the results of existing evaluation studies [gasic; 24; multitask], the current LLMs with unoptimized prompting perform significantly worse than specialized small models on some dialogue-based tasks. [text_sql] have reformulated the dialogue state tracking task into a few-shot text-to-SQL paradigm, utilizing the robust code capabilities of Codex. While this represents an intriguing approach for training dialogue exemplars, the text-to-SQL may not be universally applicable, particularly in procedural TOD tasks such as next-action prediction. Additionally, the example retriever needs to be retrained for each new dataset, which imposes limitations on this approach.

To address the above issues, we explore several ways to enhance the comprehension capabilities of LLMs by mimicking the way humans solve conversational problems [chi1989self]. We introduce the "Self-Explanation" prompt strategy, requiring the model to explain every utterance in the dialogue first and then complete the task based on the generated explanation. Despite its simplicity, the proposed method enhances the performance of contextual comprehension of LLMs in various dialogue-centric tasks. More importantly, our prompt is task-agnostic and can be easily applied to a variety of problems involving multi-turn dialogue. We evaluate the proposed method across six dialogue-centric datasets. The results show that our prompt consistently surpasses other zero-shot prompts and is on par with or surpasses few-shot prompts. In summary, our contributions include:

- We conduct a comprehensive comparison between reasoning tasks and dialogue understanding tasks, identifying the limitations of current prompting methods.

- We propose a simple yet effective prompting strategy, Self-Explanation, that significantly enhances the dialogue comprehension capacities of large language models.

- Extensive experiments on six dialogue-based datasets have demonstrated that the proposed method surpasses existing prompting approaches in performance.

[IMAGE: main_figure.pdf - Example inputs and outputs of GPT-3 with No explanation ahead (upper) and Explain before answer (lower). Explanation greatly improves the understanding of the dialogue.]

# Method

## Formalization

The problem can be divided into two components: the context, denoted as `latex $\mathcal{C}$ `, and the question, represented by `latex $\mathcal{Q}$ `. The context, `latex $\mathcal{C}$ `, provides a descriptive framework that outlines the problem setting and background. For reasoning tasks, this context delineates a specific situation. An example of this can be observed in Figure 1, where `latex $\mathcal{C}$ ` contains the activities of James. Meanwhile, in the context of TOD tasks, `latex $\mathcal{C}$ ` typically captures a multi-turn dialogue between two interlocutors.

Contrastingly, the question component, `latex $\mathcal{Q}$ `, zeroes in on a specific inquiry related to `latex $\mathcal{C}$ `. In the realm of reasoning tasks, `latex $\mathcal{Q}$ ` typically solicits a value derived from multi-step computations. This implies that the solution isn't readily available within `latex $\mathcal{C}$ `. To illustrate, refer to Figure 1 where `latex $\mathcal{Q}$ ` probes for the aggregate distance James covers in a week. Addressing this necessitates discerning the frequency of James' sprints per week and the distance of each sprint. Subsequent multiplication of these two quantities yields the desired result.

On the other hand, in a TOD task, the nature of `latex $\mathcal{Q}$ ` is more straightforward, often inquiring about the existence of specific information. Using Figure 1 as a reference, the question might pertain to the scheduled departure time of a reserved train or the type of cuisine a user seeks. Responses to these types of inquiries are readily extractable from `latex $\mathcal{C}$ `, obviating the need for additional computation.

## Self-Explanation

Humans often find it challenging to respond to questions grounded in extensive new information. One strategy that has been empirically shown to enhance comprehension of new material is self-explanation. The concept of self-explanation, originating from psychological research [chi1989self], involves learners generating explanations for themselves while processing unfamiliar content. Notably, this study demonstrated that learners engaging in self-explanation were better able to grasp core concepts and principles than their counterparts who did not employ this strategy.

Drawing inspiration from human cognitive processes and this psychological paradigm, we introduce the Self-Explanation prompting method, a zero-shot prompting technique designed to enhance multi-turn dialogue comprehension. Within the process, models initially provide explanations for each utterance in a multi-turn dialogue. Subsequently, these models execute the specified task, relying on their previously generated explanations. In the process of articulation, the large language models (LLMs) have the capacity to transform low-level natural language inputs into more abstract, high-level constructs, such as the intent or action of the speaker.

The framework is structured without the need for demonstration examples. Following the problem formalization in section 2.1, we organise the inputs using the template "`latex $\mathcal{C}$ `:[C]. `latex $\mathcal{Q}$ `:[Q]. `latex $\mathcal{A}$ `:[A]", wherein [C] and [Q] represents the input slot designated for the context and question, respectively. As for the last part, [A] is populated by manually-curated instructions prompting the model to elucidate. Central to our method is the instruction: _"Provide explanations for each utterance and then respond based on these explanations."_ For the decoding strategy, we opt for the straightforward greedy decoding method, though beam search decoding could be employed to produce a broader range of explanations.

|                      |     TOD      |    ERC    |    RS     |
| :------------------: | :----------: | :-------: | :-------: | :-------: | :-------: | :-------: |
|        Method        | MutliWoz 2.1 |  STARv2   |    SGD    | SpokenWoz |   MELD    |  MuTual   |
|       Vanilla        |    35.93     |   51.88   |   18.96   |   13.75   |   59.14   |   68.97   |
|  Vanilla + 4-shots   |    41.60     |   52.93   |   17.34   |   14.13   |   55.09   | **72.51** |
|   Chain-of-Thought   |    27.64     |   51.85   |   19.69   |   13.26   |   61.48   |   70.61   |
|    Plan-and-Solve    |    39.19     |   56.74   |   21.11   |   14.50   |   58.38   |   69.77   |
| **Self-Explanation** |  **44.44**   | **63.66** | **21.81** | **14.89** | **61.71** |   71.58   |
|   Fine-tuned SOTA    |    50.97     |   70.27   |   25.75   |   25.94   |   63.51   |   91.87   |

# Experiments

## Experimental Setup

### Datasets and task

We evaluate our self-explanation on six datasets from three categories of dialogue understanding tasks: Task-oriented dialogue (TOD), Emotion Recognition in Conversations (ERC) task and Response Selection (RS) task. For TOD task, the datasets can be divided into two types based on the dialogue schema: Procedural and Declarative [schema_cate]. A dialogue schema in the context of task-oriented dialogue is a structured representation of the conversation flow or some key entities (also known as 'slots') that need to be captured. The Procedural schema, derived from the STAR dataset [star], represents a dialogue domain as a directed graph similar to a flowchart. It consists of nodes representing user utterances, system responses, or backend service calls. The main task of the procedural schema is to strictly follow the task flow. For Procedural schema, we choose STARv2 [starv2] dataset.

**STARv2** dataset, which is an upgraded version of STAR [star] with new ground truth belief state and new natural language action descriptions. STAR is a schema-guided task-oriented dialogue dataset consisting of 24 tasks across 13 domains. We evaluate the next action prediction task, which is to predict the next system action conditioned on the dialogue history and take the weighted F-1 score as the metric.

The Declarative format, based on the Schema-Guided Dialogue (SGD) dataset [sgd] and MultiWOZ dataset [multiwoz], aims to capture the slots defined in dataset ontology. For the declarative format schema, we select MultiWOZ 2.1, SGD, and SpokenWOZ [spokenwoz] dataset and evaluate the dialogue state tracking task, using Joint Goal Accuracy (JGA) as the metric.

**MultiWOZ2.1** is a fully-labeled collection of human-human written conversations spanning multiple domains and topics. It contains 7 domains, 35 slots, and over 10k dialogues.

**SGD** is another declarative format dataset containing over 16k multi-domain conversations spanning 16 domains with more slots and possible values compared to MultiWOZ.

**SpokenWOZ** is a new multi-modal spoken TOD dataset containing 8 domains, 5.7k dialogues, and 35 slots. It introduces the unique challenges in spoken conversation.

Besides the task-oriented dialogue, we also choose two datasets: **MELD** [meld] and **MuTual** [mutual] from the Emotion Recognition in Conversations (ERC) task and response selection task, respectively. MELD contains over 10k utterances from the TV series Friends, and each utterance is annotated with emotion and sentiment labels. MuTual consists of 8k manually annotated dialogues based on Chinese students English listening comprehension exams.

| Method      | Prompt                                                                                                                                                             | MultiWOZ 2.1(JGA) |
| :---------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------: |
| Vanilla     | Answer the questions based on the above dialogue                                                                                                                   |       35.93       |
| Understand  | Before you answer, **first understand the dialogue**, then answer the questions based on your understanding and original dialogue                                  |       36.52       |
| Summary     | Before you answer, **first summarize the dialogue**, then answer the questions based on your summary and original dialogue                                         |       40.98       |
| Explanation | Before you answer, first analyze the dialogue utterance by utterance, **give every utterance an explanation**. Then answer the questions based on your explanation |       44.44       |

### Baselines

We compare our proposed zero-shot Explanation with two types of prompt baselines: Zero-shot baselines and Few-shot. For zero-shot baselines, we include zero-shot-CoT [zero-shot_cot] and Plan-and-Solve Prompting [plan-and-solve]. The former appends "Let's think step by step" to the prompt. The latter extends the zero-shot-CoT with plan ahead, and then carry out the plan. Besides the zero-shot baselines, we also evaluate the In-Context learning prompt performance on TOD task. Considering the sample of TOD task consists of a multi-turn dialogue and the slot list, we only use 4 examples as for not exceed the context window size. As for example selection, we randomly selected 4 examples with the same domain as the test sample.

## Main Results

Table 2 presents the performance of our method compared to baseline approaches across six distinct datasets. In the zero-shot scenario, our technique consistently surpasses the baselines on all evaluation datasets, irrespective of their differences. While CoT prompting does not enhance performance on TOD tasks, our method notably excels by an impressive 12% margin on the STARv2 dataset.

This significant improvement underscores the effectiveness of self-explanation prompting. The task format aligns well with this prompting approach, leading to detailed sentence-by-sentence explanations. These explanations play a pivotal role in comprehending the dialogue flow and adhering to the given schema. The enhanced performances on MultiWOZ, SGD, and SpokenWOZ further affirm that the dialogue state tracking task greatly benefits from self-explanation prompts. By providing explanations for each utterance, the likelihood of overlooking dialogue states is diminished. In addition to the task-oriented dialogue tasks, we assessed the impact of self-explanation prompting on both the ERC and RS tasks. However, the gains here were relatively modest in comparison to the TOD tasks. Given that our explanations are rooted in semantic interpretations, they may not be as beneficial for tasks centered on emotion recognition.

Compared to the few-shot baseline, our zero-shot prompting either outperforms or matches performance across all six datasets. This underscores the argument that a comprehensive understanding of dialogue is more critical than merely having a set of examples. The efficacy of in-context learning is largely attributed to its input-label pairing formats, its access to the label space, and the modification of the input distribution. For tasks within the domain of TOD, the input usually consists of multi-turn dialogues encompassing various topics, necessitating a profound understanding of the dialogue's entirety. The intricate nature of TOD tasks demands a high level of comprehension, which mere exposure to a few examples fails to deliver.

## Analysis

### Effect of Explanation

To assess the impact of self-explanation on dialogue comprehension, we carried out a comparative study using the MultiWOZ dataset, testing four distinct prompting methods. The results of these tests can be found in Table 3.

In the **Vanilla** method, no additional instruction is given before the model provides its response. In the **Understand** method, the model is simply prompted with "Understand the dialogue first" prior to answering. However, there's no specified format for the intermediate comprehension. With the **Summary** method, the model is prompted to first summarize the dialogue. It then bases its answer on both the summary and the original dialogue.

Our observations revealed that when comparing the self-explanation method with Vanilla, there was a notable decline in performance. This suggests that pre-processing or understanding the dialogue is essential for optimal performance. Merely prompting the model to understand the dialogue without detailed instruction also resulted in reduced performance. This demonstrates the importance of precise comprehension guidelines. Without them, LLMs tend to produce explanations for their answers as opposed to comprehending the dialogue. Providing detailed comprehension instructions is less ambiguous than allowing the model to self-navigate. The Summary method explicitly directs the model to use the summary as a means of comprehension, subsequently answering based on that summary. This approach enhanced performance by approximately 5% JGA in comparison to the Vanilla method. However, summarizing is a broad-strokes approach and might overlook finer details essential for the TOD task.

Drawing from psychological research, specifically [chi1989self], it's evident that not all explanations confer the same benefits. Factors like content, quality, and depth of explanations are paramount. Our refined method, the **self-explanation** prompting, instructs the model to generate sequential explanations, promoting deeper dialogue understanding.

| Error Type              | Dialogue                                                                                                                                       |           Explanation            |                                Vanilla                                |
| :---------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------: | :-------------------------------------------------------------------: |
| Time involved           | I need to **get to** Michaelhouse cafe **by 12:45**.                                                                                           |       taxi-arriveby: 12:45       |                    taxi-leaveat: 12:45 (incorrect)                    |
| Missing info.           | I am **leaving Cambridge** at 12:00 on Sunday, can you please tell me the travel time on that ride?                                            |    train-departure: cambridge    |                   train-departure: None (incorrect)                   |
| Task unclear understand | Please help me find the **attraction downing college**. Yes, it's on Regent Street **in the centre of town**. Would you like the phone number? | attraction-name: downing college | attraction-name: downing college, attraction-area: centre (incorrect) |

### Case Study

To have a straightforward understanding of how explanation affects task completion, We manually checked all the cases of MultiWOZ dataset that were correctly answered by self-explanation but incorrectly answered by Vanilla and picked several typical errors. As shown in Table 4.

Generally, there are three main types of errors: time involved, missing information, and unclear task understanding. For the first error type, the model usually gets confused with departure time and arrival time. In the case of time-involved errors, the user needs a taxi that arrives by 12:45. While the model output of the vanilla prompting assigns 12:45 to the time of taxi departure.

The second error type, missing information error, mostly happens in the dialogue, which has a high number of turns. The large amount of dialogue information may distract the model from correctly capturing all the information needed to complete the task. As the case of this error shows, the user expresses the place, time, and date of departure in one sentence. The model output of vanilla prompting misses the place of departure, while the output of self-explanation prompting correctly captures all the information about the user request.

The last error type is a task-specific error. In the dialogue state track task, the dialogue state should include the information that the user requested and exclude the system provides. In the case of the final type of error, the user explicitly requests an attraction called Downing College, and the system provides some relevant information about this attraction. The model output of self-explanation prompting correctly distinguishes the information the user requested and the system provided. While the model output of Vanilla prompting mistakenly includes the system information in the dialogue state.

### Connection with CoT Prompting

We have explored self-explanation prompting as a simple way to enhance the understanding of multi-turn dialogue in large language models. In this section, we'll connect the dots between self-explanation prompting and CoT prompting.

From a macro perspective, OpenAI's documentation indicates that giving models a moment to "think" is beneficial. Analogous to human cognition, hastily jumping to conclusions often leads to mistakes. CoT prompting, which requires a systematic rationale before presenting an answer, effectively grants models this "thinking" time. Similarly, our self-explanation prompting offers models a moment of reflection, but it steers them to interpret the intricate context, `latex $\mathcal{C}$ `, as opposed to breaking down the answer's rationale.

From a micro perspective, CoT prompting guides the model toward a solution by narrowing the scope of potential answers. In tasks requiring reasoning, the solution isn't straightforwardly derived from the context `latex $\mathcal{C}$ `. The response involves extensive calculations and transformations, heavily drawing on the model's innate reasoning faculties. This suggests the solution space is largely tethered to the model's capabilities. The logical progression elicited by CoT prompting either constrains or directs this solution space.

Conversely, in the TOD task, the query `latex $\mathcal{Q}$ ` typically seeks details readily found in `latex $\mathcal{C}$ `. Unlike reasoning assignments, these questions don't demand intricate computations. As such, the solution space primarily lies within `latex $\mathcal{C}$ `. The enhanced dialogue comprehension, courtesy of our self-explanation prompting, offers an alternative approach to narrowing down this solution space.

# Related work

**Prompting Methods:** The exploration of prompting methods for machine learning models has been vast. One of the conventional methods is in-context learning (ICL), as highlighted by GPT-3 [gpt3]. In ICL, multiple demonstrations are provided before a test sample, and the model's performance significantly hinges on these demonstrations [zhao2021calibrate; lu2021fantastically].

Some researchers, such as those in [liu2021makes], endeavor to retrieve examples semantically similar to a test query sample, utilizing metrics like the L2 distance or cosine-similarity distance derived from sentence embeddings. In addition to these distance metrics, the concept of mutual information emerges as a potent example selection criterion [sorensen2022information]. Here, the goal is to select a template that optimizes the mutual information between the input and the model's output. Taking this further, several studies, such as [rubin2021learning], have shifted towards a supervised approach, training models to pick the most relevant demonstrations from a pool of candidates.

**Reasoning Strategies:** Beyond merely selecting examples, their arrangement or ordering can significantly influence a model's performance. Enter the Chain-of-Thought (CoT) strategy [cot], a pioneering prompting approach designed to enhance the performance of large language models (LLMs) on intricate reasoning tasks. Unlike ICL, which relies on prepending input-output pairs, CoT integrates a sequence of intermediate reasoning steps into the demonstration, thereby amplifying the reasoning capabilities of LLMs.

Recognizing the importance of diverse reasoning paths, the self-consistency strategy [self] was introduced. It first creates multiple reasoning paths rather than just the most likely one and subsequently selects the most coherent answer by considering all the generated paths. Further automation in this domain is achieved with zero-shot CoT [zero-shot_cot]. Instead of relying on human-annotated reasoning sequences, this method induces the model to generate reasoning steps by simply prompting it to 'think step by step'.

# Conclusion

In this paper, we find that CoT prompting is suboptimal for multi-turn dialogue tasks that require strong comprehension abilities. To enhance the comprehension of LLM, we propose a new zero-shot prompting strategy called self-explanation prompting, which guides the LLM to first understand the multi-turn dialogue by explaining every utterance and then completing the task based on dialogue with its explanation. Extensive experiments show that explanation prompting can boost the LLMs contextual understanding of multi-turn dialogue and significantly outperform or perform on par with the previous zero-shot and few-shot baselines.
