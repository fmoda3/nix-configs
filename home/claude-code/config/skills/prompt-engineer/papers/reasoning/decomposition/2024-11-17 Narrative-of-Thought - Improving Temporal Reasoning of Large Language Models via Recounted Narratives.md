# Abstract

Reasoning about time and temporal relations is an integral aspect of human cognition, essential for perceiving the world and navigating our experiences. Though large language models (LLMs) have demonstrated impressive performance in many reasoning tasks, temporal reasoning remains challenging due to its intrinsic complexity. In this work, we first study an essential task of temporal reasoning---temporal graph generation, to unveil LLMs' inherent, global reasoning capabilities. We show that this task presents great challenges even for the most powerful LLMs, such as GPT-3.5/4. We also notice a significant performance gap by small models (`latex $<10B$ `) that lag behind LLMs by `latex $50\%$ `. Next, we study how to close this gap with a budget constraint, e.g., not using model finetuning. We propose a new prompting technique tailored for temporal reasoning, Narrative-of-Thought (NoT), that first converts the events set to a Python class, then prompts a small model to generate a temporally grounded narrative, guiding the final generation of a temporal graph. Extensive experiments showcase the efficacy of NoT in improving various metrics. Notably, NoT attains the highest F1 on the Schema-11 evaluation set, while securing an overall F1 on par with GPT-3.5. NoT also achieves the best structural similarity across the board, even compared with GPT-3.5/4.

# Introduction

[IMAGE: Task overview of temporal graph generation (TGG), where the input is a goal and a set of unordered events. In this work, to better unleash the pre-training power of LLMs trained with a mixture of text and code, we cast TGG as a code completion task.]

Temporal reasoning is essential for humans to perceive the world, understand daily communications, and interpret the temporal aspects of experiences [journals/cacm/Allen83; journals/jacm/NebelB95]. The recent advent of large language models (LLMs) has garnered substantial attention to their impressive performance in various reasoning tasks, such as arithmetic reasoning [gsm8k; zhong2024achieving] and commonsense reasoning [talmor-etal-2019-commonsenseqa; palm2]. Nonetheless, few LLMs exist to handle temporal reasoning well [time_benchmark1; time_benchmark2; chan-etal-2024-exploring], due to the task's inherent complexity, mingled with implicit logical inference and the necessity for profound world knowledge.

To gain deeper insights, the research community mainly focuses on two ends along the spectrum: either a simple relation extraction task that orders a pair of events [uzzaman-etal-2013-semeval; yuan-etal-2023-zero], or a perplexing commonsense understanding task demanding multifaceted reasoning skills beyond the mere temporal aspect [journals/corr/abs-2308-00002; tan-etal-2023-towards; Xiong-LTR]. Worse still, the former is limited to a _local_ scope spanning two adjacent sentences only and fails to account for the significance of _global_ temporal relations, leading to overly optimistic results [restructured; time_benchmark1]. Therefore, neither setup provides a clear understanding of LLMs' true temporal reasoning abilities.

In this work, we aim to unveil the **inherent, global temporal reasoning capabilities of LLMs**, evaluating them in isolation _free from confounding factors_, and addressing the limitations of previous studies which only focused on local contexts. We first introduce a task of **temporal graph generation (TGG)**: Given a high-level goal `latex $\mathcal{T}$ ` (e.g., business change) and a set of events `latex $\mathcal{V}$ `, the objective is to produce a temporal graph `latex $\mathcal{G(V, E)}$ ` where a directed edge in `latex $\mathcal{E}$ ` reveals the temporal order between events. Though this specific notion of TGG is new, many of its applications are not. In this work, we specifically study TGG in order to evaluate and improve the temporal reasoning capability, since TGG is deemed a major bottleneck when LLMs perform temporal reasoning. With TGG, we put forth the first research question.

**RQ1: What is the temporal reasoning capability of popular LLMs?** Prior work [time_benchmark1; time_benchmark2] shows a huge gap between AI systems and human performance on various temporal understanding tasks. Additionally, there is a notable performance disparity between proprietary LLMs (e.g., GPT-4) and open-weights LLMs, particularly those with fewer than 10 billion parameters (henceforth, small LLMs). Our study on temporal reasoning reveals a similar trend and identifies the existence of both gaps. This further highlights the importance of an in-depth investigation of TGG, since the performance of downstream tasks (e.g., temporal commonsense understanding) is positively correlated with the inherent, global temporal reasoning capability. Observing the model deficiencies, we are motivated to _fill the gap between open-weights, small LLMs and proprietary large models_. This is due to the fact that open-weights LLMs are generally more accessible, reproducible, and cost-effective to use [chatgpt-oneyear; ethicalGPT]. In pursuit of this goal, we present the second research question.

**RQ2: With a budget constraint (e.g., not allowing further training), how can small LLMs catch up with large models like GPT-3.5/4?** Given the constraint that no training will be used, we propose Narrative-of-Thought (NoT), a special prompting technique tailored for temporal reasoning. This method capitalizes on the recent success of the Chain-of-Thought (CoT) technique [Wei0SBIXCLZ22; KojimaGRMI22], found effective in solving complex reasoning tasks. To approach TGG, NoT produces a final temporal graph via first generating a _temporally grounded narrative_ then sorting the input events topologically in reference to the recounted narrative. Inspired by madaan-etal-2022-language [PoT; PAL], NoT also features structural representations by converting the input-output mapping to a Python class, and instructing the generation in code space. We further improve NoT by introducing high-quality reference narratives as part of few-shot demonstrations.

Extensive experiments across three evaluation benchmarks of diverse genres reveal six interesting findings: 1) small LLMs _struggle with temporal reasoning_ even with few-shot examples; 2) _CoT is also ineffective at temporal reasoning_, in line with existing finding [time_benchmark2]; 3) _GPT-4 sometimes falls off the throne due to alignment_, when answering sensitive queries; 4) NoT is a powerful tool to assist small LLMs to catch up with or even _surpass GPT-3.5_, and presents strong compatibility with various base LLMs; 5) _the temporally grounded narratives are significant in improving LLMs' temporal reasoning process_; 6) _AI systems are far from mastering temporal reasoning_, trailing the human baseline by 30 F1 points.

We also analyze the impact of shot numbers and perform a holistic evaluation of reference narratives in few-shot examples. 5-shot is found to be the sweet spot for temporal reasoning, after which the performance plateaus, likely due to long-context challenge. We identify three key characteristics of reference narratives for them to avail small LLMs most: conciseness, simplicity, and factuality.

# Related Work

## Temporal Reasoning

This work is deeply rooted in a long-standing yet still challenging NLP domain---temporal reasoning [journals/cacm/Allen83; journals/jacm/NebelB95], which involves extraction, representation and reasoning with time and events [Sanampudi2010TemporalRI]. Depending on the cognitive complexity, temporal reasoning in NLP is studied at three levels: temporal expression detection, temporal relation extraction, and temporal graph generation. The simplest **temporal expression detection** task is to identify phrases in the text that convey temporal information [Setzer01; mani-etal-2001-guidelines; PustejovskyCISGSKR03], commonly known as TimeX. Further, under-specified TimeX is typically converted to explicit expressions (e.g., "summer 2024") through a process called time expression normalization [verhagen-etal-2010-semeval].

Explicit TimeX is often absent in text, and events usually carry implicit temporal information. To bridge the gap, TempEval [Verhagen2009TheTC; uzzaman-etal-2013-semeval] is curated to support the study of **temporal relation extraction**, which aims to detect the temporal relation between two _events_ in a document. The most common benchmarks, TB-dense [chambers-etal-2014-dense] and MATRES [ning-etal-2018-multi], have witnessed the technique evolution from LSTM [dligach-etal-2017-neural] and GNN-augmented BERT [mathur-etal-2021-timers; wang-etal-2022-dct], to LLMs prompting [yuan-etal-2023-zero]. Yet, these benchmarks are limited by their _locality assumption_, where only pairs of events within a two-sentence window are annotated. Even in this simplified scenario of temporal relation extraction, ChatGPT perform poorly, trailing supervised systems by over 30% [chan-etal-2024-exploring].

The most challenging task, **contextualized temporal graph extraction**, is defined as, given a document, generating a corresponding event-level temporal graph [uzzaman-etal-2013-semeval; madaan-yang-2021-neural]. This task addresses the limitation of locality by priming models to comprehend the entire article and infer relationships even between distant events. Yet, this area is largely under-investigated, partly due to the scarcity of available datasets. A similar task is **script learning** [regneri-etal-2010-learning; modi-etal-2016-inscript; sakaguchi-etal-2021-proscript-partially], which targets inducing a stereotypical progression of _complex_ events [script_def], represented as a temporal graph of more _atomic_ events. This task is usually approached by first extracting information snippets from a given document to build an instance graph, and then expanding the graph to generate a schematic graph using GNN [li-etal-2021-future; jin-etal-2022-event] or LLM prompting [dror-etal-2023-zero]. Given the remarkable similarities between these two tasks, we instead study a temporal reasoning task formulation that is _fundamental_ to both, i.e., **temporal graph generation**. It differs from prior work in at least two dimensions: (1) a limited-context setting, where only abstract event descriptions are available, and (2) only a few training samples at hand, rendering fine-tuning techniques inapplicable. This motivates a _training-free assessment_ of LLMs' _inherent, global_ temporal reasoning capability.

[IMAGE: Overview of Narrative-of-Thought (NoT), a prompting technique tailored for temporal reasoning. NoT improves the temporal graph by recounting a temporally grounded narrative. Also shown are comparisons with existing methods.]

## Chain-of-Thought and its Variants

Despite the strong problem-solving capability in the general domain [WeiTBRZBYBZMCHVLDF22], LLMs struggle to address more complex reasoning tasks, such as commonsense understanding and arithmetic reasoning [patel-etal-2021-nlp; TalmorYBBGCB21; huang-chang-2023-towards]. Wei0SBIXCLZ22 first introduce the concept _Chain-of-Thought (CoT)_ by decomposing multi-step problems into intermediate steps. KojimaGRMI22 further adds a phrase _"Let's think step by step"_ to perform zero-shot CoT. These studies underpin the CoT technique in enhancing LLMs' capability for complex reasoning.

Down the line, sophisticated prompting schemes are devised through _structuralization_. One approach is to extend the linear chain structure to Tree-of-Thoughts [yao2023tree] and Graph-of-Thoughts [besta2024got], enabling expanded exploration space. The huge search space, however, results in a computational resource dilemma. On top of that, leveraging the deterministic execution to narrow the discrepancy between reasoning and final answer, PoT [PoT], PAL [PAL] and Faithful CoT [lyu-etal-2023-faithful] introduce programming languages to describe the reasoning process structurally. These methods are designed exclusively for solving mathematical reasoning and symbolic reasoning, where the reasoning process and computation can be decoupled. In contrast, for temporal reasoning, the reasoning process and the temporal sorting step are intrinsically interleaved. In fact, time_benchmark2 has attempted to apply CoT but proved unsuccessful.

Moreover, existing methods are mostly applied to generate intermediate rationales for _simple, atomic outputs_, usually in the format of multi-choice options [mihaylov-etal-2018-suit; talmor-etal-2019-commonsenseqa; logicalQA], a number [gsm8k; math], or yes/no options [commonsenseqa2; WeiTBRZBYBZMCHVLDF22]. Our work draws a clear distinction where our focus is on **structural output generation**, augmented with producing a rationale in the form of a compelling and pertinent narrative.

# Method: Narrative-of-Thought

Figure 2 provides an overview of the proposed Narrative-of-Thought (NoT) method, and draws a comparison against common prompting techniques. Overall, given a scenario and a set of events, NoT first converts the input into a Python class, then guides LLMs to produce a temporally grounded narrative by arranging events in the correct temporal order, leveraging LLMs' intrinsic temporal knowledge. Based on the _recounted_ temporal relations articulated in the narrative, LLMs are instructed to sort events into a temporal graph. This section will discuss major components in detail: (1) structural representation, (2) NoT prompting template, and (3) narrative-aware demonstrations.

#### Structural Representation.

Following prior work [madaan-etal-2022-language; PoT; PAL], we cast temporal reasoning as a code completion task. This design decision is motivated by the unordered nature of both event sets and temporal relation sets, making a structural representation the optimal choice. wang-etal-2023-code4struct also shows that combining structural event representations with LLMs trained with a mixture of text and code can unleash the full pretraining power. We extend this framing to handle cross-event structures. Specifically, a temporal graph is commonly presented in DOT format [madaan-yang-2021-neural; sakaguchi-etal-2021-proscript-partially], the appearance of which lends itself naturally to the usage of coding format. Furthermore, code execution follows a clear, step-by-step logical flow, mirroring the process of reasoning. Bringing these aspects together results in an alignment between temporal graphs and code structure, facilitating the temporal reasoning process. Our further study on this phenomenon also reveals a strong positive correlation between coding capabilities and temporal reasoning.

Concretely, each scenario is represented as a Python class. Each class encapsulates events as functions, where the function name is in the form of "step[A-Z]" such as "stepX", and the function body indicates the event description. The temporal graph is represented as a collection of pairwise temporal relations, enclosed within the return statement of "get_relation()" function, marked by "TODO" for LLMs to implement.

#### Narrative-of-Thought (NoT).

At inference time, NoT first prompts LLMs to produce a temporally grounded narrative using _Narrative Prompt_. Drawing on the generated narrative, LLMs proceed and complete generation in response to _Temporal Graph Prompt_. The entire generation process is in an end-to-end manner, ensuring that LLMs explicitly leverage the temporal relations articulated in the narrative to assist the generation of the final temporal graph.

**Narrative Prompt:**

```
# Let's think of a narrative to link aforementioned events in the correct temporal order.

def get_narrative(self):

# TODO
```

**Temporal Graph Prompt:**

```
def get_relations(self):

# TODO

# END
```

Overall, NoT narrows the gap between pre-training and inference by allowing the LLM to unfold the narrative knowledge seen during pre-training. Concretely, our approach leverages LLMs' inherent strengths in _generating_ and _comprehending_ text for narrative and temporal graph generation, respectively. In contrast, directly mapping abstract events to a temporal graph is less effective, as such examples are rarely encountered during pre-training. Practically, generated narratives create imagined experiences to navigate, and reify implicit timelines, assisting reasoning over a series of events even without explicit timestamps provided in the text, which are crucial for tasks requiring temporal reasoning. By reading the _recounted_ narrative, it becomes easier for the LLMs to construct an implicit timeline to guide event sorting, significantly reducing the reasoning complexity compared to generating temporal graphs from scratch (i.e., using abstract events alone).

Our NoT draws a clear distinction from the CoT prompting and its variants in four aspects. First, for CoT, a final answer cannot be easily extracted unless a post-hoc script is designed [KojimaGRMI22; self-consistency; stepback], which can be sometimes error-prone, while the output of NoT is easy to obtain by parsing the `get_relations()` function. Second, NoT produces final outputs in the structural space, while existing methods solely produce _simple, atomic outputs_ as discussed previously. Third, NoT produces final temporal graphs cost-effectively without external tools in an end-to-end fashion, unlike pipeline approaches which face error propagation and over-sampling issues [dror-etal-2023-zero]. Lastly, the generated rationales by CoTs are not necessarily grounded in real-world experience. In contrast, generated narratives by NoT are steered to be more _temporally grounded_, creating an imagined experience for LLMs to navigate, which is proved effective.

#### Narrative-aware Demonstrations.

Existing studies [gpt3; WeiTBRZBYBZMCHVLDF22] have demonstrated that in-context demonstrations play a critical role in guiding LLMs to produce meaningful outputs. NoT is no exception, as even GPT-3.5 struggles with temporal reasoning in a zero-shot setting. Thus, few-shot examples are provided by default. For NoT to succeed, high-quality and relevant rehearsed narratives, termed _reference narratives_, need to be created and embedded in these demonstrations.

Capitalizing on the recent success of using LLMs to generate demonstrations [generate-then-read; self-demonstration], we prompt GPT-3.5/4 to produce reference narratives. Concretely, for each demonstration, abstracted as `latex $\mathcal{G(V, E)}$ `, we feed both `latex $\mathcal{V}$ ` and `latex $\mathcal{E}$ ` into GPT-3.5/4, using our designed reference narrative generation templates, dubbed _meta prompts_. In total, we create 4 types of meta prompts covering diverse genres like news and children's stories. Additionally, when feeding `latex $\mathcal{G(V, E)}$ ` into GPT-3.5/4, we use two _input formats_ to define a Python class (_alphabetical_ like "stepX" vs. descriptive like "pushPedal").

# Experiment

In this work, we focus on **Temporal Graph Generation (TGG)**, an essential task of temporal reasoning. Here, we discuss datasets, experimental setup, baselines, and evaluation metrics.

## Dataset

In line with the literature, we use **ProScript** [sakaguchi-etal-2021-proscript-partially] as the major benchmark, where a temporal script is represented as a directed acyclic graph, which were collected from a diverse range of sources including ROCStories [mostafazadeh-etal-2016-corpus], Descript [wanzare-etal-2016-crowdsourced], and Virtual home [PuigRBLWF018]. We also adopt two other datasets to enrich the evaluated genres and domains, and make necessary changes for the TGG task: 1) **Schema-11** evaluation set [dror-etal-2023-zero], which contains human-curated event schemas for 11 newsworthy topics, such as _armed robbery_ and _business change_; and 2) **WikiHow Script** corpus [lyu-etal-2021-goal], a collection of multilingual how-to articles depicting necessary steps performed in sequence to achieve a high-level goal, covering a wide range of daily activities.

## Setup

As our goal is to study the capability and generalizability of existing LLMs, and our NoT without any fine-tuning, we assume no access to large-scale training sets except for few-shot demonstrations. Therefore, all experiments are conducted in a 5-shot setting. We consider three base models to spotlight the compatibility and versatility of NoT. We include very recent, strong LLMs, showing promising results on various reasoning tasks and code completion tasks, Mistral-7B [mistral], Gemma-7B [gemma], and Llama3-8B [llama3modelcard]. For all base models, we use their instruction-fine-tuned versions for experiments.

We represent the event set as a suite of Python methods, by serializing the unordered event set. For each scenario, we randomly shuffle the input Python methods three times, and apply models to each shuffle with greedy decoding at inference. For NoT, we use _Simple Report_-style narratives by GPT-4, which are generated by following instructions to produce concise reports based on provided event descriptions and relations.

## Baselines

To showcase the effectiveness of NoT, for each base model we compare with standard structural prompting and structuralized chain-of-thought prompting. We also remove reference narratives in demonstrations to highlight the importance of narrative-aware few-shot demonstrations. We include a random baseline, where events are naively connected to form a _linear_ temporal chain based on the order they appear in the input. We also experiment with two strong proprietary models, GPT-3.5 and GPT-4 [gpt-4] to help gauge the gap between AI systems and human-level performance.

## Evaluation Metrics

We denote the ground-truth and generated temporal graphs as `latex $\mathcal{G(V,E)}$ ` and `latex ${\hat{\mathcal{G}}(\mathcal{V},\hat{\mathcal{E}})}$ `, respectively. we compare both semantic and structural similarities between `latex $\mathcal{G}$ ` and `latex $\hat{\mathcal{G}}$ `, following prior work [sakaguchi-etal-2021-proscript-partially; madaan-etal-2022-language]. To evaluate semantic similarity, we report _precision (P)_ and _recall (R)_, defined as below, as well as _F1_.

```latex
$$\mathrm{Precision} = \frac{|\mathcal{E} \cap \hat{\mathcal{E}}|}{|\hat{\mathcal{E}}|}  \;\;\; \mathrm{Recall} = \frac{|\mathcal{E} \cap \hat{\mathcal{E}}|}{|\mathcal{E}|}$$
```

To assess structural similarities, we consider:

- _Graph Edit Distance_ [*GED*; Abu-AishehRRM15] calculates the minimum number of edits (node/edge removal/additions) to transform `latex $\hat{\mathcal{G}}$ ` to a graph isomorphic to `latex $\mathcal{G}$ `.

- _Graph Statistics_: fraction of the number of edges between `latex $\hat{\mathcal{G}}$ ` and `latex $\mathcal{G}$ ` (`latex $\frac{|\hat{\mathcal{E}}|}{|\mathcal{E}|}$ `); the number of connected components in `latex $\hat{\mathcal{G}}$ `, denoted as `latex $k(\mathcal{G})$ `. The goal is to bring both statistics closer to 1, additionally ensuring `latex $k(\mathcal{G})$ ` is at least 1.

We further calculate _Pair-wise Consistency_ between `latex $\hat{\mathcal{G}}_i$ ` and `latex $\hat{\mathcal{G}}_j$ `, where we compare generated graphs, based on two randomly shuffled inputs, and compute the proportion of common temporal links produced in both graphs, i.e., `latex $\frac{|\hat{\mathcal{E}}_i \cap \hat{\mathcal{E}}_j|}{|\hat{\mathcal{E}}_i \cup \hat{\mathcal{E}}_j|}$ `.

# Results and Analyses

## Main Results

Below are the major findings.

1. _With the few-shot setup, small LLMs are dramatically underperforming, reaching barely 50% of GPT-4's capabilities._ The three base models, whether using standard prompting or CoT, consistently under-perform GPT-4 and attain 40% to 60% of its average F1 scores. Among them, Mistral-7B achieves the highest F1 scores, while Llama3-8B produces temporal graphs most similar to the ground truth, as measured by GED.

2. _Unlike many other reasoning tasks, CoT does not always work for temporal reasoning and sometimes degrades performance._ Unlike mathematical or logical reasoning [Wei0SBIXCLZ22], CoT prompting does not necessarily enhance model performance on temporal reasoning tasks. Across all three base models, there is a notable degradation in F1 and GED scores with CoT, except for Llama3's F1 scores. This is not TGG-specific, but rather a common pattern across various temporal understanding tasks [time_benchmark2], highlighting the need for specialized approaches to temporal reasoning.

3. _GPT-4 is not always the champion, owing to the added safety layer._ GPT-4 implements safety measures through human-preference alignment [gpt-4], which enhances model safety by prompting more cautious responses, potentially leading to performance drop [alignment-1; alignment-2]. Especially on **Schema-11**, GPT-4 refrains from providing answers to sensitive scenarios like "bombing attacks", and thus fails to produce a valid temporal graph.

4. _With NoT, small LLMs can perform comparably to GPT-3.5, or even take the lead._ When equipped with NoT, the overall semantic correctness (F1) and structural similarity (GED) of the generated temporal graphs are significantly enhanced, regardless of which base LLM is used. The average improvement of F1 over naively prompting the base model is between 16% to 71%. As the power of the base LLM grows, NoT demonstrates greater consistency in its outputs. Notably, with Llama3-8B, the strongest base LLM, NoT achieves an F1 score that is comparable to GPT-3.5 (42.2 vs. 45.7), and even outperforms GPT-3.5/4 on GED. These results demonstrate the potential of applying NoT in a wide range of temporal understanding tasks in future research.

5. _Recounting temporally grounded narrative is a prerequisite for LLMs to generate temporal graphs accurately._ Without high-quality reference narratives, LLMs struggle to generate temporally grounded narratives, leading to a detrimental impact on NoT-augmented Gemma-7B (e.g., a 0.7 F1 drop and a 0.67 GED increase).

6. _LLMs, including the powerful GPT-4, lag far behind human-level performance in temporal reasoning._ The SOTA F1 score (by GPT-4) on ProScript is 63.9, whereas the human baseline F1 is 89.3 [sakaguchi-etal-2021-proscript-partially]. While NoT has notably narrowed the gap between small and large LLMs, AI models have not mastered temporal reasoning yet, and further research efforts are needed for LLMs to match human performance.

#### Comparison with fine-tuned LLMs.

To evaluate the performance gap between the NoT prompting technique and the computational-intense fine-tuning (FT) approach, we conduct a side experiment on the ProScript dataset. Specifically, each instruction-tuned base LLM is fine-tuned on the ProScript training set, utilizing LoRA [lora] and mixed-precision training. We follow the same setting where each training example is prepended with 5-shot demonstrations. While significant performance disparities between NoT and FT are observed across the board, the narrowing gap suggests the growing potential of NoT as the underlying LLM continues to evolve. Moreover, fine-tuned small LLMs consistently outperform the few-shot GPT-4, which is the best-performing generalist model on the ProScript dataset. This underscores the continued efficacy of FT in building specialized models, even in the era of LLMs.

## Further Studies on NoT

We conduct ablation studies using Llama3-8B, to explore the effect of the few-shot demonstrations and the recounted reference narratives.

#### Does the number of shots matter?

Figure 3 illustrates how F1 scores change with the number of shots in demonstrations. As can be seen, GPT-3.5 and NoT show resilience to changes in shot numbers after an initial sharp increase. The performance nearly stabilizes in the range of 5-10 shots, though a slight drop is observed later, presumably due to insufficient capability of long-context comprehension [long-context-1; long-context-2]. Of particular interest is the performance of NoT with 3 shots on Schema-11, outperforming the best variant of GPT-3.5 (F1 of 63.5 vs. 62.8). This further illustrates NoT's potential of boosting small LLMs in the long run. It is also noticeable that F1 scores of the standard prompting technique have a V-shape between 1-shot and 5-shot, highlighting its sensitiveness to in-context demonstrations.

We also display the GED scores in relation to number of shots. We observe similar instability in the standard prompting technique, along with the performance plateau after 5 shots.

[IMAGE: F1 scores on ProScript and Schema-11 in relation to the number of shots in demonstrations. We identify the instability in the standard prompting, and the performance plateau after 5 shots.]

#### What characteristics define effective reference narratives?

Given that reference narratives in NoT are machine-generated, we aim to explore what qualities matter most for the TGG task. Here, the three variables influencing reference narratives are: (1) narrative generation model (GPT-3.5 vs. GPT-4), (2) input format (alphabetical vs. descriptive), and (3) 4 meta prompt types (varying degrees of factuality and readability).

Figure 4 shows results of F1 and GED with varying meta prompts. Surprisingly, the choice of the generator does not significantly impact the graph quality, with average F1 scores of 36.4 for GPT-3.5 and 37.0 for GPT-4, and GED scores of 1.90 vs. 1.94. Similarly, there is no significant difference between alphabetical and descriptive input formats. The most _impactful_ factor is the meta prompt type. Grouping performance bars by prompt type reveals a clear variance in model performance. Among the first three groups, _Simple English_ narratives, i.e., good for 10-year-olds, stand out. This suggests that narratives should be simple and concise, as verbose ones are less effective. We find that _News Report_ narratives prioritize procedural and factual content, minimizing distractions like descriptive settings or figurative language that can often be found in both fiction or non-fiction stories. We thus combine _Simple English_ and _News Report_ to leverage their strengths, dubbed _Simple Report_. In summary, we identify three key characteristics for quality reference narratives: _conciseness_, _simplicity_ and _factuality_.

[IMAGE: F1 scores on ProScript and Schema-11 with different meta prompts. Average performance grouped by prompt type is also shown. Notably, using a Simple Report-style, GPT-4 generated narratives lead to the best score due to its conciseness, simplicity and factuality, which are essential qualities for a high-quality reference narrative.]

#### How faithful is the temporal graph to intermediate narratives?

Here, we look into whether NoT-augmented LLMs are **self-faithful**, i.e., whether the narrative and the temporal graph **align** in terms of the temporal order of events. Higher self-faithfulness is crucial and desired, as misalignment would diminish the effort of generating a temporally grounded narrative.

Motivated by the recent success of using LLMs as judges [llm-as-judge; Zhang2024ULTRAUL], we employ GPT-4 to assess the self-faithfulness of 600 randomly sampled outputs by NoT-augmented Llama3-8B. We prompt GPT-4 to perform a 5-way assessment and provide judgment rationales. Additionally, GPT-4 is instructed to count the temporal links in the temporal graphs and identify aligned temporal links for a sanity check. This helps humans capture the failure modes and make necessary interventions. Based on automated responses and on-demand human inspections, we find a medium-to-high alignment of 72.8%.

# Conclusion

In this paper, we assess the inherent, global temporal reasoning capabilities of LLMs, by studying the core challenge of temporal reasoning---temporal graph generation (TGG). To this end, we propose Narrative-of-Thought (NoT), a novel prompting technique tailored for temporal reasoning. Concretely, with few-show narrative-aware demonstrations as references, NoT prompts LLMs to first generate a temporally grounded narrative and then sort the input events topologically into a temporal graph, by manipulating the generation in code space. Extensive experiments showcase NoT's effectiveness, demonstrated by its superior performance over GPT-3.5 on multiple metrics, as well as the compatibility of NoT with various LLMs.

# Limitations

#### Evaluation benchmarks.

In this work, we have included three evaluation benchmarks, aiming to cover a diverse array of genres and domains. Yet, these three benchmarks cannot comprehensively represent the entire spectrum. For example, healthcare and biomedical [bio-temporal] domains offer great opportunities to study temporal graph generation as well. In future research, we plan to extend NoT to more applications, and examine its true generalizability in the wild.

#### Human baseline comparison.

The last finding we deliver in the main results might not hold for all benchmarks, as the human baseline comparison was conducted solely on the ProScript dataset. We will continue the endeavor of seeking participants to perform human evaluations on the other two datasets to enhance the credibility of our claim.

#### Scaling effect.

While we recognize the value of investigating models of different sizes to explore the scaling effect of NoT, we did not pursue this for two reasons. First, one primary goal is to enable small LLMs (<10B parameters) to match the performance of larger ones like GPT-3.5/4 (RQ2). Second, among the three base models selected in this work, the open-weight Mistral only has a 7B version; while Gemma does have 2B and 7B versions, preliminary results showed that the 2B version yielded subpar performance (e.g., poor instruction-following, outputs are simply concatenations of events in the input order). As for LLAMA3 (8B vs. 70B), we couldn't produce results for 70B due to computational constraints.

#### GPU resources.

The base LLMs used in this work are of 7 to 8 billions parameters. It is thus more time-consuming than traditionally small models like BERT [devlin-etal-2019-bert] at inference time, which in turn results in a higher carbon footprint. Specifically, we run each base LLM on 1 single NVIDIA A40 or NVIDIA L40 with significant CPU and memory resources. The combined inference time for each LLM on the three benchmarks ranges from 10 to 20 hours, depending on the configurations.

# Appendix

## Additional Implementation Details

#### Few-shot Demonstration Selection.

To construct the demonstration bank, we select 15 examples from the training set of ProScript, following MadaanTGHGW0DPY23. We do so because we expect to include non-linear temporal graph examples in our demonstrations, for which only ProScript can fulfill the requirement. Then, we use the same demonstrations as few-shot examples for experiments, regardless of the evaluation benchmark.

#### Model Cards.

In this work, we have experimented with 3 base LLMs. Below lists the exact Huggingface model cards used in this work.

- Gemma-7B: `google/gemma-7b-it`
- Mistral-7B: `mistralai/Mistral-7B-Instruct-v0.2`
- Llama3-8B: `meta-llama/Meta-Llama-3-8B-Instruct`

## Dataset Processing

This section documents the processing steps performed on Schema-11 and WikiHow Script to cater for the temporal reasoning task of our interest. We do not use any Python packages for dataset processing. Meanwhile, based on our inspection, we do not spot any offensive content in these three datasets.

#### Schema-11.

In their original annotations, an event node is marked in arg0-trigger-arg1 format, and we manually convert it to a natural sentence. We specifically adopt annotations under _schemas_dan_d_ directory.

#### WikiHow Script corpus.

The original dataset features multilingualism, while we only take their English portion for this study. Then, We only keep ordered how-to articles where steps are presented in chronological order. Lastly, we cap the maximum number of steps at 20, which reduces the corpus size from 3,3035 to 2,077.

## Complete Examples

Using the same example as in Figure 1 and Figure 2, we show the complete examples (including generations by one base LLM, Llama3-8B) of Standard Prompting, CoT and NoT. The output of Standard Prompting is completely wrong and fails to capture any correct temporal relation. Worse still, it even forms a loop. For the output of CoT, at least, it gets one temporal relation correct. However, the generated rationales are verbose, not to-the-point, and the mixture of natural language and programming language in the output might confuse the generation process as well. In contrast, the generated temporal graph by NoT captures most of the right temporal relations, yielding a high F1 score of 80 points, and a very low GED, which is just 1.

[IMAGE: Input for Standard Prompting with 1-shot demonstration]

[IMAGE: Input for NoT with 1-shot demonstration including a high-quality reference narrative]

[IMAGE: Output by Standard Prompting]

[IMAGE: Output by CoT]

[IMAGE: Output by NoT]

## Meta Prompt

This section discusses the major components of a meta prompt, used to generate reference narratives. A meta prompt consists of two parts: input (in Python programming language) and instruction (above and below the input). The input contains both `latex $\mathcal{V}$ ` (event set) and `latex $\mathcal{E}$ ` (temporal relation set), and the goal is to prompt LLMs to generate a high-quality _reference narrative_. The input has two formats: **alphabetical** format where the function header is represented in the same fashion as in Figure 2, and **descriptive** where the function header is the camel-cased version of the complete event description. The instruction part specifies how LLMs are supposed to carry out the narrative generation, reflecting different types and genres. Specifically, we designed four different instructions: _News Report_, _Simple English_, _Role Play_ and _Simple Report_, which is essentially a seamless combination of _News Report_ and _Simple English_.

[IMAGE: GED scores on ProScript (top) and Schema-11 (bottom) in relation to the number of shots in demonstrations]

[IMAGE: GED scores on ProScript (top) and Schema-11 (bottom) with different meta prompts]

[IMAGE: Meta prompt used to generate reference narrative, where the input format alphabetical and the meta prompt type is Simple Report]

[IMAGE: Meta prompt used to generate reference narrative, where the input format descriptive and the meta prompt type is News Report]

## Correlation Analysis

We start our empirical analysis by presenting performances on well-regarded coding benchmarks, HumanEval and MBPP, of the three selected base LLMs included in this work. Based on these results, the ranking is Mistral (1) < Gemma (2) < LLAMA3 (3), with the numbers in parentheses indicating their relative scores in this comparison.

Second, regarding instruction-following capability in code completion, we evaluated how well the models adhered to provided instructions (i.e., implementing the return statement of "get_relations(self)"). As can be seen, Mistral produces perfect outputs, while Gemma and LLAMA3 generate the entire class despite being explicitly instructed not to do so. Additionally, Gemma includes a lead phrase, which is also discouraged in the instruction. Therefore, the empirical ranking is Gemma (1) < LLAMA3 (2) < Mistral (3).

Combining these assessments, the overall ranking for code completion capability is Gemma (3) < Mistral (4) < LLAMA3 (5). This exactly aligns with their performance on our TGG task, suggesting a **strong positive correlation** between coding capabilities and temporal reasoning.

## Faithfulness Checking Details

GPT-4 performs a 5-way assessment: yes, largely yes, ambivalent, largely no, and no, where yes means exact alignment while no means no alignment at all. With the counting puzzle as a sanity check, we find that GPT-4 does not count the number of temporal links wrong at all. We thus rely on the returned value of _correct temporal links_ as a means to determine the failure mode. Before human inspection, the distribution among yes/largely yes/largely no/no is 243/190/32/135, where GPT-4 does not output "ambivalent".

#### Faithfulness Checking Manual Inspection.

We notice that there are 39 cases where the value of correct temporal links is 0, and 5 cases where GPT-4 refuses to produce a value. Thus, we manually look into these 44 cases. Among these 44 cases, we correct 4 of them. In one case, GPT-4's rationale is "Additionally, all other links, despite being in the correct order, are rendered incorrect due to the initial incorrect link." and GPT-4 marks 0 correct temporal links. However, as GPT-4 has discovered, all except for one link are actually correct, so we change the label from "no" to "yes". There are three cases where GPT-4 is not judging the faithfulness but instead the _correctness_. As we have noted in the main content, faithfulness is not the same as correctness. For example, one rationale is "Given the fundamental logical error in the sequence of dialing and answering, all links are considered incorrect in the context of real-world logic, despite matching the narrative's order" where the narrative mistakenly says "dialing the phone" happens after "answer the phone", so GPT-4 marks "no". Yet, as GPT-4 has also discovered that the temporal graph actually perfectly matches the generated narrative, we thus correct the label from "no" to yes. The aforementioned two cases are the ones where GPT-4 got stuck in this assessment task.

After human inspection, the final adjudicated distribution is 247/190/32/131. This leads to an alignment level of 72.8% where we consider both "yes" and "largely yes" as entailing _alignment_.
