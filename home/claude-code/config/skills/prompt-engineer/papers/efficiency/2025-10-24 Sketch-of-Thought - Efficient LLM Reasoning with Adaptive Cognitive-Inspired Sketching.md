# Abstract {#abstract .unnumbered}

Recent advances in large language models (LLMs) have enabled strong reasoning capabilities through Chain-of-Thought (CoT) prompting, which elicits step-by-step problem solving, but often at the cost of excessive verbosity in intermediate outputs, leading to increased computational overhead. We propose _Sketch-of-Thought_ (SoT), a prompting framework that integrates cognitively inspired reasoning paradigms with linguistic constraints to reduce token usage while preserving reasoning accuracy. SoT is designed as a flexible, modular approach and is instantiated with three paradigms---_Conceptual Chaining_, _Chunked Symbolism_, and _Expert Lexicons_---each tailored to distinct reasoning tasks and selected dynamically at test-time by a lightweight routing model. Across 18 reasoning datasets spanning multiple domains, languages, and modalities, SoT achieves token reductions of up to 84% with minimal accuracy loss. In tasks such as mathematical and multi-hop reasoning, it even improves accuracy while shortening outputs.

# Introduction {#sec:introduction}

<figure id="fig:SoT_Example" data-latex-placement="t">
[IMAGE: _figures/primary_comparison.pdf]
<figcaption>A comparison of accuracy and token usage in Chain-of-Thought (CoT) <span class="citation" data-cites="cot"></span> and the proposed Sketch-of-Thought (SoT). Average scores for model performance across 18 datasets. Shaded region represents more efficient reasoning.</figcaption>
</figure>

Large language models (LLMs) have become central to a wide range of complex reasoning tasks across diverse domains, such as mathematics, science, and commonsense inference [@bubeck2023sparks; @llmsurvey2024]. Even without dedicated training for reasoning, these models often exhibit emergent capabilities when prompted to decompose problems into intermediate steps [@cot]. Chain-of-Thought (CoT) prompting [@cot] exemplifies this approach by encouraging step-by-step natural language reasoning, which has been shown to significantly improve performance on tasks such as logical inference and numerical problem solving [@sprague2024cotsurvey].

Despite its benefits, CoT often produces verbose outputs that dramatically increase token usage and computational overhead, making it less suitable for latency- or budget-constrained deployment scenarios [@ccot-45; @arora2025training]. More sophisticated strategies, such as Self-Consistency [@self-consistency], Tree-of-Thoughts [@tot], and Graph-of-Thoughts [@got], further expand the reasoning process via structured exploration, but tend to exacerbate inefficiencies in token usage.

To tackle these limitations, we introduce _Sketch-of-Thought_ (SoT), a prompting framework that rethinks how language models externalize reasoning. Inspired by cognitive science, particularly the use of symbolic _sketches_ as efficient mental intermediaries [@sketchesofthought], SoT guides models to produce concise, structured reasoning steps that capture essential logic while avoiding full-sentence elaboration. These representations are analogous to mathematical notation or expert shorthand, preserving semantic fidelity while minimizing redundancy.

To implement this framework, we define three cognitively motivated reasoning paradigms: _Conceptual Chaining_, based on associative memory; _Chunked Symbolism_, grounded in working memory theory; and _Expert Lexicons_, inspired by domain-specific schemas used by specialists. Each paradigm is designed for a distinct class of reasoning tasks and is implemented using training-free prompts. To support adaptive paradigm selection, we incorporate a lightweight routing model that analyzes query structure to determine the most suitable reasoning style at inference time.

We extensively evaluate SoT on 18 reasoning datasets spanning mathematical, commonsense, logical, multi-hop, scientific, and medical domains. Experimental results show that SoT reduces output token usage by up to 84% compared to traditional CoT prompting, with no significant loss in accuracy---and even improving performance in some domains. Additional multilingual and multimodal evaluations demonstrate SoT's ability to generalize across both languages and input modalities.

Our key contributions are as follows:

- We introduce _Sketch-of-Thought_ (SoT), a prompting framework that leverages cognitively inspired reasoning paradigms to produce concise and structured model outputs.

- We present a lightweight routing model that dynamically selects the optimal reasoning paradigm based on the input query's structure and semantics.

- On a battery of tests, we show that SoT significantly reduces token usage while maintaining or improving accuracy across diverse datasets, models, languages, and modalities.

<figure id="fig:sot-sot-flow" data-latex-placement="!">
[IMAGE: _figures/comparison_examples.pdf]
<figcaption><strong>Illustration of reasoning workflows</strong>, including the input format, intermediate reasoning structure, and output style, across four prompting methods: Chain-of-Thought (CoT) <span class="citation" data-cites="cot"></span>, Constrained CoT (CCoT) <span class="citation" data-cites="ccot-45"></span>, Chain-of-Draft (CoD) <span class="citation" data-cites="cod"></span>, and Sketch-of-Thought (SoT). While CoT produces verbose natural language traces, CCoT and CoD apply explicit constraints on reasoning length. SoT introduces paradigm-guided sketching, yielding more compact yet structured intermediate steps via dynamic routing.</figcaption>
</figure>

# Method {#sec:sot}

This section outlines the technical implementation of _Sketch-of-Thought_ (SoT), a framework designed to improve the efficiency of reasoning in large language models while preserving performance. The end-to-end framework is illustrated in Figure [2](#fig:sot-sot-flow){reference-type="ref" reference="fig:sot-sot-flow"}.

## Preliminary

We first provide a brief overview of large language models (LLMs) and their application to reasoning.

#### Large Language Models

Large language models (LLMs) are trained on massive text corpora to predict the next token in a sequence. Formally, an LLM with parameters $\theta$ receives an input token sequence $x$ and produces an output sequence $y$, denoted as follows: $y = \text{LLM}_\theta(x)$. While LLMs exhibit strong performance across a variety of domains, their computational cost increases with the number of tokens processed and generated, making efficiency a critical concern.

#### Reasoning via Prompting

Recent LLMs exhibit emergent reasoning capabilities---the ability to solve multi-step problems without task-specific training---when guided by carefully designed prompts. Letting $P$ denote a prompt with instructions, exemplars, and the input query $q$, the process can be formalized as $r = \text{LLM}_\theta(P(q))$, where $r$ includes both the reasoning trace $[s_1, s_2, \ldots, s_m]$ and final answer $a$, as follows: $r = [s_1, s_2, \ldots, s_m, a]$. Chain-of-Thought (CoT) [@cot] encourages decomposition into natural language steps.

:::: center
::: promptbox
Q: If a train travels 60 miles per hour for 3 hours, how far does it go?\
A: \<think\> 1. I understand we need to find the total distance traveled by: A train moving at 60 miles per hour for a duration of 3 hours.\
2. To calculate the distance, I'll use the formula:\
Distance = Speed × Time\
Distance = 60 miles/hour × 3 hours\
3. Now I'll perform the calculation:\
Distance = 60 × 3 = 180 miles\
4. Verification:\
This makes sense because the train moves 60 miles each hour. After 3 hours, it will have covered 3 times that distance. \</think\>\
Answer: 180 miles
:::
::::

More advanced variants, for example, Tree-of-Thoughts and Graph-of-Thoughts [@tot; @got], extend this idea by exploring alternative structural formulations. Despite their stylistic differences (leading to performance gains), all CoT-style prompting methods share a common limitation: increased token usage and reduced efficiency, when compared to standard direct-answer prompting [@arora2025training].

## Sketch-of-Thought (SoT) {#sec:paradigms}

Sketch-of-Thought (SoT) mitigates reasoning inefficiency by restructuring how models express intermediate steps. Unlike prior methods that reduce prompt length via input compression [@jiang2023llmlingua; @huang2024fewer], SoT compresses the reasoning process using cognitively inspired prompts that elicit concise, structured steps.

Formally, we define different paradigm-specific prompt templates $P_{\text{SoT}}$, which steer the model to produce sketched reasoning: $[\hat{s}_1, \hat{s}_2, \ldots, \hat{s}_m, a] = \text{LLM}_\theta(P_{\text{SoT}}(q))$, where each $\hat{s}_i$ conveys the same logical content as $s_i$ (from CoT, for example), but using significantly fewer tokens, i.e., $|\hat{s}| < |s|$. These prompts enforce both linguistic constraints and cognitive structuring tailored to the task type.

As an initial realization of SoT, we create three reasoning paradigms inspired by cognitive science, each designed to align with distinct patterns found across a range of reasoning tasks.

#### Conceptual Chaining.

Rooted in cognitive science principles of how humans connect and retrieve related information, this paradigm creates concise logical sequences between key concepts. It draws from episodic buffer integration [@baddeley_episodic_2000], the cognitive mechanism that temporarily holds and links information from different sources, and associative memory networks [@anderson_spreading_1983], which describe how activating one concept automatically triggers related concepts in our minds (like how thinking of \"rain\" might immediately evoke \"umbrella\"). _Conceptual Chaining_ extracts essential terms and presents reasoning as direct step-by-step pathways with minimal text.

:::: center
::: promptbox
Q: What is the name of the currency used in Seoul?\
A: \<think\> #Seoul → #South Korea → Won \</think\>\
Answer: Korean Won
:::
::::

_Conceptual Chaining_ is particularly effective for commonsense, multi-hop, logical, and scientific reasoning tasks, where establishing structured relationships between ideas is critical.

#### Chunked Symbolism.

Based on working memory chunking theory [@miller_magical_1956], this paradigm organizes numerical and symbolic reasoning into compact, structured steps. This seminal cognitive science research showed that humans can only hold about 7$\pm$`<!-- -->`{=html}2 (i.e., 5 to 9) distinct items in working memory at once, but we overcome this limitation by \"chunking\" related information into meaningful units---like remembering phone numbers as area code, prefix, and line number instead of 10 separate digits. _Chunked Symbolism_ applies this principle by condensing mathematical reasoning into dense symbolic representations that pack more information into fewer tokens. It systematically extracts variables and performs operations while eliminating verbose explanations, using symbolic variables to transform natural language into a structured shorthand that preserves logical flow.

:::: center
::: promptbox
Q: A car accelerates at 2.5 m/s\^2 for 10 seconds. If its initial velocity was 15 m/s, what is its final velocity?\
A: \<think\> a = 2.5 m/s\^2, t = 10 s, vi = 15 m/s vf = 15 + (2.5 × 10), vf = 40 m/s \</think\>\
Answer: 40 m/s
:::
::::

_Chunked Symbolism_ excels in mathematical and arithmetic reasoning problems, where symbolic notation naturally compresses complex concepts.

#### Expert Lexicons.

Inspired by expert schema research [@chi_categorization_1981], this paradigm leverages domain-specific shorthand and specialized notation to condense reasoning. This research demonstrated that experts in any field organize knowledge differently than novices---they develop mental frameworks (schemas) that allow them to quickly recognize patterns and use specialized terminology to communicate efficiently with peers. For example, a physician can convey complex medical conditions with a few acronyms that would require paragraphs of explanation for non-specialists. _Expert Lexicons_ mimics this cognitive efficiency by employing domain-specific abbreviations, notation, and symbols that pack multiple concepts into single tokens. The example below demonstrates how domain-specialized reasoning can be compressed into concise notation while preserving the critical logical connections.

:::: center
::: promptbox
Q: A patient with STEMI is given MONA therapy. They are allergic to aspirin. Are they at risk with this treatment?\
A: \<think\> STEMI → ST-Elevation MI, MONA → Morphine, O2, Nitrates, Aspirin, so Aspirin $\in$ MONA \</think\>\
Answer: Yes
:::
::::

_Expert Lexicons_ is particularly suited for technical disciplines, specialized reasoning tasks, and scenarios, where domain expertise enables significant information compression.

## Adaptive Paradigm Selection {#sec:paradigm_selection}

While manual selection among three paradigms is possible for each query based on heuristic rules, such an approach is impractical at scale. Instead, we introduce a lightweight routing model that selects the paradigm dynamically based on semantic and structural features of the input query.

Given a query $q$, the routing process is denoted as follows: $P_{\text{SoT}} = \texttt{ROUTER}(q)$, where $P_{\text{SoT}}$ refers to the selected paradigm's prompt-exemplar pair and $\texttt{ROUTER}$ denotes the router model. We use DistilBERT [@distilbert] as the base model due to its strong performance-efficiency trade-off and minimal inference overhead (see Appendix  [9.1](#sub:router_architecture_ablation){reference-type="ref" reference="sub:router_architecture_ablation"}).

#### Router Training

We train the router model using $14{,}200$ machine-labeled examples drawn from the training splits of the datasets outlined in Section [3.1](#sec:datasets){reference-type="ref" reference="sec:datasets"}. Each sample is labeled using GPT-4o [@openai2024gpt4ocard], guided by a classification prompt derived from the paradigm definitions in Section [2.2](#sec:paradigms){reference-type="ref" reference="sec:paradigms"}. We provide this classification prompt in Appendix [8.6](#sub:classification_prompt){reference-type="ref" reference="sub:classification_prompt"}. Additionally, we evaluate GPT-4o's paradigm labeling performance in Appendix [9.2](#sub:gpt4o_human_evaluation){reference-type="ref" reference="sub:gpt4o_human_evaluation"}.

To avoid overwhelming the router with irrelevant input, we replace any long or non-textual context (e.g., images or documents) with a special placeholder token (e.g., `[CONTEXT HERE]`). This ensures that the model focuses solely on the question itself, which typically contains sufficient cues for determining the appropriate reasoning style.

# Experimental Setup {#sec:experiments}

## Datasets {#sec:datasets}

To ensure a comprehensive evaluation, we validate Sketch-of-Thought (SoT) across 15 datasets spanning six categories of reasoning, following the taxonomy introduced by @reasoning_task_types. The datasets are as follows: **Mathematical Reasoning** includes GSM8K, SVAMP, AQUA-RAT, and DROP [@ds_gsm8k; @ds_svamp; @ds_aqua_rat; @ds_drop]; **Commonsense Reasoning** includes CommonsenseQA, OpenbookQA, and StrategyQA [@ds_commonsenseqa; @ds_openbookqa; @ds_strategyqa]; **Logical Reasoning** includes LogiQA and ReClor [@ds_logiqa; @ds_reclor]; **Multi-Hop Reasoning** includes HotPotQA and MuSiQue-Ans [@ds_hotpotqa; @ds_musique_ans]; **Scientific Reasoning** includes QASC and Worldtree [@ds_qasc; @ds_worldtree]; and **Medical Reasoning** includes PubMedQA and MedQA [@ds_pubmedqa; @ds_medqa].

Beyond English textual reasoning, we include two additional evaluation tracks: a multilingual experiment using MMLU and its professionally translated variant MMMLU [@ds_mmlu], and a multimodal experiment using GQA [@ds_gqa] and the image-based subset of ScienceQA [@ds_scienceqa]. Further details regarding the datasets are provided in Appendix [7.1](#ap_datasets){reference-type="ref" reference="ap_datasets"}.

## Baselines

We mainly compare SoT against three established prompting-based reasoning strategies. Chain-of-Thought (CoT) [@cot] elicits step-by-step natural language reasoning. Constrained CoT (CCoT) [@ccot-45] introduces a global verbosity constraint, limiting the total reasoning chain to a fixed number of words---in our case, 45 words (CCoT-45). Chain-of-Draft (CoD) [@cod] adopts a similar compression strategy but imposes constraints at the step level, requiring each intermediate step be no longer than five words.

## Implementation Details {#sub:implementation_details}

A diverse set of instruction-tuned LLMs is selected, spanning both open-weight and proprietary offerings. These include Qwen-2.5 in 7B, 14B, and 32B variants [@qwen2.5], LLaMA-3.1-8B [@llama-3.1], LLaMA-3.2-11B [@llama-3.2], GPT-4o [@openai2024gpt4ocard], and Claude Sonnet 3.5 [@claude-3.5]. For experiments involving multimodal inputs, we use Qwen-2.5-VL-7B [@qwen2.5-VL], which supports visual input processing. Unless otherwise specified, Qwen-2.5-32B serves as the default model for all other experiments. We use a temperature value of 0.5 for all models to balance output stability and diversity. For open-source models, inference is accelerated using FlashAttention2 [@flashattention2]. We sample 150 questions from each dataset for the sake of computational costs, and report the averaged performance over three independent runs per question. For the router model, we fine-tune DistilBERT with cross-entropy loss over 5 epochs, using a batch size of 64 and a learning rate of $2\text{e}^{-5}$. During inference, the router processes the core input query. Following previous work, we use few-shot prompting to illustrate the required reasoning style, with exemplars being generated by prompting Qwen-2.5-32B with the method-specific prompt and selecting high-quality outputs. Further information regarding prompts and exemplars can be found in Appendix [8](#sec:appendix_prompts){reference-type="ref" reference="sec:appendix_prompts"}.

## Evaluation Protocol {#sub:evaluation_protocol}

We evaluate using two primary metrics: accuracy and output token count. For multiple-choice, yes/no, or numeric tasks, accuracy is computed via exact match with the ground truth. For open-ended generation, we follow the LLM-as-a-judge paradigm [@geval], using GPT-4o [@openai2024gpt4ocard] to assess correctness. Answers are extracted according to the output format (see Appendix [8.2](#sub:output_format){reference-type="ref" reference="sub:output_format"}). We analyze efficiency through the total number of generated tokens in the intermediate reasoning.

# Results and Discussion {#sec:results}

## Overall Performance

As shown in Table [\[tab:primary_res\]](#tab:primary_res){reference-type="ref" reference="tab:primary_res"}, Sketch-of-Thought (SoT) consistently reduces output token count while minimizing the impact on reasoning accuracy across all evaluated models. On average, SoT achieves a token reduction of over 74% relative to CoT, with accuracy deviations typically within 1%. These trends hold across both open-weight models and proprietary models, confirming SoT's generalizability across architectures and model families. SoT also demonstrates strong stability across reasoning tasks, consistently balancing token reduction with minimal accuracy variance, unlike other baselines which exhibit greater fluctuations. Notably, across all runs, we found that SoT consistently reduces token usage while having a statistically insignificant impact on accuracy ($p<0.05$).

## Model-wise Trends

Performance gains with SoT are especially notable in the Qwen family of models. On Qwen-2.5-32B, SoT achieves 82.30% accuracy---slightly above CoT's 82.24%---while reducing output token count by 74.36%. Similar patterns hold at the 14B and 7B scales, where SoT maintains accuracy within 1% of CoT while reducing output length by over 70%. On GPT-4o, SoT achieves 84.55% accuracy---just 0.09% below CoT---while reducing token usage by 76%. Claude Sonnet 3.5 shows similar behavior, with SoT reaching 84.50% accuracy versus CoT's 85.01%, alongside a 68% reduction in tokens. Results on LLaMA-3.1 and 3.2 indicate stronger compression (up to 78%) but slightly wider accuracy gaps (up to 3%). These findings confirm that SoT performs reliably across model families, consistently achieving strong token reductions with minimal accuracy degradation.

## Paradigm-Task Performance

Task-level results indicate that SoT's effectiveness is most pronounced in reasoning settings with inherently compressible logic. In mathematical tasks, SoT closely matches the performance of CoT in the majority of settings. For example, in the Qwen-2.5-32B setting, SoT achieves 86.94% accuracy compared to 84.17% for CoT, while reducing average output length from 222 to 88 tokens. These gains are attributable to the effectiveness of the _Chunked Symbolism_ paradigm in representing arithmetic reasoning concisely, which is the dominant paradigm for this category of reasoning (see Appendix [9.3](#sub:paradigm_distribution){reference-type="ref" reference="sub:paradigm_distribution"}).

In commonsense and multi-hop reasoning, SoT maintains strong performance while achieving substantial compression. In the Qwen-2.5-32B setting, SoT reaches 92.00% accuracy on commonsense tasks using just 34 tokens on average, compared to 91.48% at 177 tokens under CoT. These improvements are driven by the _Conceptual Chaining_ paradigm, which is the prevailing strategy for these reasoning categories and effectively captures structured relationships between ideas.

Domain-specialized tasks, such as PubMedQA and QASC, show more variability in accuracy across models, reflecting the inherent complexity of technical reasoning. Nevertheless, the _Expert Lexicons_ paradigm remains effective at compressing domain-specific reasoning, often using half as many tokens as CoT while preserving competitive accuracy. Across all categories, SoT maintains competitive performance with far shorter outputs than CoT, underscoring its adaptive nature.

Further discussion on paradigm distribution across datasets can be found in Appendix [9](#sec:paradigm_assignments){reference-type="ref" reference="sec:paradigm_assignments"}.

## Token-Constrained Alternatives

Compared to other compression-focused prompting strategies such as Chain-of-Draft (CoD) and Constrained CoT (CCoT), SoT provides a more favorable trade-off between brevity and performance. Although CoD yields the most aggressive reductions in output length, it suffers notable accuracy degradation---for example, a 6.2% decline on GPT-4o despite a 75% token reduction. CCoT offers more balanced results, but still lags behind SoT in both efficiency and generalization across reasoning types. Although cases exist where these methods perform better in either accuracy or token reduction, there is no such case where these methods outperform SoT in both. In all observed settings, SoT achieves similar or better accuracy than these methods alongside competitive token reduction.

## Ensemble Reasoning Methods {#sub:extended_approaches}

To examine SoT's compatibility with ensemble-style reasoning methods, we integrate it into three established frameworks. Self-Consistency [@self-consistency] aggregates multiple reasoning paths by majority voting to improve answer stability. Self-Refine [@self-refine] enables iterative refinement of reasoning traces through reflection-based prompting. Multi-Agent Debate [@multi-agent] simulates deliberation among independent agents, each producing a rationale before converging on a final answer. In each case, we follow the original methodology but substitute SoT in place of CoT as the core reasoning strategy. Further implementation details, including prompts and hyperparameters, are provided in Appendix [10](#sec:appendix_results){reference-type="ref" reference="sec:appendix_results"}.

Table [\[tab:extended_approaches\]](#tab:extended_approaches){reference-type="ref" reference="tab:extended_approaches"} reports results from integrating SoT into three ensemble reasoning frameworks. In all cases, SoT improves performance relative to CoT, while substantially reducing output length. For instance, in the Self-Refine setting, SoT improves accuracy by 0.27% while generating 60% fewer tokens per response. In the Multi-Agent Debate framework, SoT yields a 0.57% accuracy increase alongside a 69% token reduction. These results indicate that SoT can be effectively substituted into more complex, multi-pass prompting pipelines, retaining its advantages in both efficiency and output quality.

## Multilingual Reasoning

To evaluate SoT's performance in non-English settings, we conduct a multilingual evaluation using Korean, Italian, and German subsets of MMMLU [@ds_mmlu]. For each language, we select the same set of 500 questions from each language and generate three responses, for an effective sample size of 1,500. To maintain consistent paradigm selection across languages, each non-English query is paired with its English counterpart and routed using the same routing model. The selected paradigm prompt and associated exemplars are then translated into the target language using GPT-4o [@openai2024gpt4ocard], preserving both semantic fidelity and structural constraints.

As summarized in Table [\[tab:language_results\]](#tab:language_results){reference-type="ref" reference="tab:language_results"}, SoT reduces output length by over 80% in all three languages while incurring a modest decrease in accuracy, ranging from -0.33% to -1.33%. These findings suggest that the sketching paradigms underlying SoT generalize across linguistic structures and preserve core reasoning logic beyond English.

## Multimodal Reasoning

To assess SoT's extensibility to multimodal scenarios, we evaluate its performance using Qwen-2.5-VL-7B [@qwen2.5-VL] on 500 multiple-choice samples from both GQA [@ds_gqa] and the image-based subset of ScienceQA [@ds_scienceqa]. Each sample is run three times for an effective sample size of 1,500. As in the unimodal setting, paradigm selection is handled by the router model. Images and supplementary materials are replaced with a placeholder token during routing (see Section [2.3](#sec:paradigm_selection){reference-type="ref" reference="sec:paradigm_selection"}), allowing the router to focus on the question text. We reuse the same text-only exemplars from the primary experiments.

Results from multimodal evaluations are shown in Table [\[tab:multimodal_results\]](#tab:multimodal_results){reference-type="ref" reference="tab:multimodal_results"}. On ScienceQA, SoT reduces output length by 80% while outperforming CoT by 6.60%. On GQA, however, we observed a 2.50% reduction in accuracy when using SoT while reducing output length by 75%. The accuracy degradation in GQA likely reflects the difficulty of applying abstract sketching methods to tasks requiring fine-grained visual grounding. Another possible explanation is that the text-only exemplars, while effective in general, may not sufficiently prime the model for vision-intensive reasoning.

<figure id="fig:router_confusion_appendix" data-latex-placement="t">
[IMAGE: _figures/router_model_ablation.pdf]
<figcaption>Confusion matrix illustrating the performance of the router model in selecting among the three SoT paradigms. Predictions are compared against GPT-4o-assigned ground truth labels.</figcaption>
</figure>

## Analysis on Routing {#sub:routing_analysis}

To investigate the efficacy of our router model for paradigm assignment, we evaluate its ability to select appropriate reasoning paradigms across the 2,250 samples used in our primary experiments (see Section [3.1](#sec:datasets){reference-type="ref" reference="sec:datasets"}). Ground-truth labels are produced by GPT-4o using the same labeling protocol as during training (see Section [2.3](#sec:paradigm_selection){reference-type="ref" reference="sec:paradigm_selection"}). As shown in Figure [3](#fig:router_confusion_appendix){reference-type="ref" reference="fig:router_confusion_appendix"}, the model achieves 96.4% overall accuracy, with high recall for the two most common paradigms, _Conceptual Chaining_ (0.964) and _Chunked Symbolism_ (0.975). Recall for _Expert Lexicons_ is slightly lower at 0.907, largely due to class imbalance. However, this asymmetry is expected as _Expert Lexicons_ is intentionally applied more conservatively given its specialized nature, and the router defaults to general paradigms in ambiguous cases to reduce risk of misapplication.

## Paradigm-Task Alignment {#sub:paradigm_task_alignment}

To test if there is a significant difference between the performance of each paradigm in their respective tasks, we benchmark the performance of all three paradigms on datasets across different reasoning tasks. For any given dataset, we define the dominant paradigm as the paradigm which is assigned to the majority of samples. For example, from the paradigm definitions outlined in Section [2.2](#sec:paradigms){reference-type="ref" reference="sec:paradigms"}, we can assume that the expected-dominant paradigm of GSM8K is _Chunked Symbolism_. In Appendix [9.3](#sub:paradigm_distribution){reference-type="ref" reference="sub:paradigm_distribution"}, we conduct an analysis of the expected versus actual dominant paradigms across all datasets to validate the router's overall performance. In all cases the expected-dominant paradigm aligns with the actual-dominant paradigm.

However, this analysis of paradigm routing says nothing of the accuracy on these tasks. For this, we select one representative dataset per paradigm using the previously-mentioned dominant-paradigm distribution in Table [\[tab:paradigm_alignment_reasoning_type\]](#tab:paradigm_alignment_reasoning_type){reference-type="ref" reference="tab:paradigm_alignment_reasoning_type"}. We then run inference on these datasets using all paradigms and compare their performance in Table [\[tab:paradigm_performance_dominant\]](#tab:paradigm_performance_dominant){reference-type="ref" reference="tab:paradigm_performance_dominant"}. Our findings indicate that, for all examined datasets, the expected-dominant paradigm outperforms all others in terms of task accuracy. Notably, a paradigm being dominant does not mean it will have the lowest token usage. For example, in medical reasoning, _Expert Lexicons_ has the highest accuracy with 85.70% and, while _Chunked Symbolism_ has the lowest token usage, its accuracy is far lower at 73.10%. These results demonstrate that different reasoning paradigms yield different performance levels depending on the task, and that selecting the optimal paradigm is critical for maximizing accuracy.

# Related Work {#sec:related}

#### Token-Efficient Reasoning

A growing body of work targets the reduction of output length during language model reasoning. Concise Chain-of-Thought [@renze2024ccot] and Constrained CoT  [@ccot-45] apply fixed constraints on the number of steps or words in the reasoning trace. SCOTT [@wang2023scott] uses a two-stage summarization pipeline that compresses verbose CoT outputs into shorter versions. While these methods reduce token usage, they rely on surface heuristics or summary-based rewriting, often reducing clarity. As an orthogonal direction, Coconut [@hao2024traininglargelanguagemodels] bypasses token-based reasoning by operating entirely in the latent vector space, though this requires additional training procedures, making it inapplicable to frozen LLMs. In contrast, SoT rewrites reasoning steps using compact representations, yielding outputs that are both concise and interpretable.

#### Structured Reasoning Strategies

Other approaches enhance reasoning by restructuring the generation process itself. Tree-of-Thoughts [@tot] and Graph-of-Thoughts [@got] treat reasoning as a search over intermediate steps, producing graph-structured outputs. Self-Consistency [@self-consistency] improves stability by sampling multiple reasoning paths and selecting the majority answer. While these methods improve accuracy on certain tasks, they often incur significant increases in compute overhead. In contrast, SoT leverages a standard prompting interface to restructure internal reasoning, achieving efficiency gains without increasing inference complexity.

#### Prompt Compression and Adaptive Inference

Several techniques improve efficiency through prompt compression or selective computation. Chain-of-Draft (CoD) [@cod] uses densely packed natural language reasoning to reduce length, but this often comes at the cost of clarity and yields large performance drops on more complex reasoning tasks. CoT-Influx [@huang2024fewer] and LLMLingua [@jiang2023llmlingua] prune or compress input exemplars to reduce prompt length. Cascaded inference [@yue2024cascades] and compute-adaptive methods [@arora2025training] dynamically route examples to high-cost inference pipelines only when necessary. SoT differs by addressing compression as a representational design challenge: instead of relying on pruning or selection, it restructures how reasoning is expressed, guided by task-specific cognitive principles.

# Conclusion {#sec:conclusion}

We present Sketch-of-Thought (SoT), a prompting framework that reduces token usage in language model reasoning by up to 84%, preserving accuracy in most tasks and incurring only minor trade-offs in others. SoT leverages cognitively inspired paradigms to generate compact yet semantically faithful reasoning traces, offering a practical alternative to verbose prompting. Extensive experiments across 18 reasoning datasets, multiple languages, and multimodal tasks demonstrate SoT's broad applicability. Its compatibility with ensemble prompting strategies further reinforces its practical utility, particularly in resource-constrained settings. By reframing efficiency as a reasoning design challenge rather than a surface-level compression problem, SoT opens new directions for scalable, cognitively informed prompting.

# Limitations and Future Work {#sec:limitations .unnumbered}

Sketch-of-Thought (SoT) is designed for interpretable, efficient reasoning, and while our current approach performs well on a variety of tasks, there exist several interesting directions for future work.

Following prior work, our use of fixed exemplars per paradigm---intentionally chosen to preserve stylistic consistency and interpretability---may limit adaptability to subtle variations within a task type. Alternatively, a retrieval system could dynamically pull in-context exemplars from a larger pool based on the reasoning paradigm and question characteristics. These strategies could help to improve SoT's flexibility across subtly different queries but also disparate tasks and domains.

Also, while we focused this work on evaluating cognitively grounded, prompt-based three paradigms, the framework is not limited to the three we present here. Future work may incorporate additional reasoning paradigms to better adapt SoT to downstream tasks such as code generation. These can be integrated by adding new paradigms, updating the sketching pool, and retraining the routing module accordingly.

Lastly, while our current multilingual experiments already demonstrate SoT's stability across widely-spoken languages, evaluating its impact in low-resource languages is an exciting direction for future work.

# Ethics Statement {#ethics-statement .unnumbered}

This work builds on widely used public datasets and large language models (LLMs). All datasets used in our experiments are publicly available and cited accordingly. Where applicable, we follow dataset authors' intended uses and licensing terms. All models are used in accordance with their respective licenses.

While Sketch-of-Thought (SoT) improves the efficiency of model reasoning, we acknowledge that compressing intermediate outputs may affect interpretability in certain high-stakes settings. We encourage caution when applying SoT in domains such as healthcare or legal analysis, where full transparency of reasoning steps may be essential.

Further, our router model was trained using annotations generated via GPT-4o, and as such may reflect biases present in the underlying model. We recommend further evaluation before deploying SoT in sensitive or high-stakes settings.
