# Abstract

Modern systems for multi-hop question answering (QA) typically break questions into a sequence of reasoning steps, termed _chain-of-thought_ (CoT), before arriving at a final answer. Often, multiple chains are sampled and aggregated through a voting mechanism over the final answers, but the intermediate steps themselves are discarded. While such approaches improve performance, they do not consider the relations between intermediate steps across chains and do not provide a unified explanation for the predicted answer. We introduce Multi-Chain Reasoning (MCR), an approach which prompts large language models to _meta-reason_ over multiple chains of thought, rather than aggregate their answers. MCR examines different reasoning chains, mixes information between them and selects the most relevant facts in generating an explanation and predicting the answer. MCR outperforms strong baselines on 7 multi-hop QA datasets. Moreover, our analysis reveals that MCR explanations exhibit high quality, enabling humans to verify its answers.

# Introduction {#sec:introduction}

[IMAGE: fig_1.pdf]

<figcaption>An example from StrategyQA, showing the output of Multi-Chain Reasoning versus Self-Consistency. MCR uses reasoning chains as its <em>context</em> for QA. SC solely relies on the chains’ answers.</figcaption>

[IMAGE: fig_system_overview.pdf]

<figcaption>An overview of MCR, given a question from the Fermi dataset. Steps 1-2 generate multiple reasoning chains by conditioning the generation of intermediate questions and answers on retrieved evidence sentences. In step 3, the <em>meta-reasoner</em> generates the final answer, given multiple reasoning chains from the previous steps.</figcaption>

In chain-of-thought (CoT) prompting, a large language model [NEURIPS2020_1457c0d6; Chowdhery2022PaLMSL; Kadavath2022LanguageM; Touvron2023LLaMAOA] is prompted to generate its answer following a step-by-step explanation [Wei2022ChainOT; nye2022show]. CoT prompting has been shown to dramatically improve performance on reasoning-heavy tasks [kojima2022large; Zhou2022LeasttoMostPE]. Furthermore, @wang2023selfconsistency showed that sampling _multiple_ chains of thought and returning their majority output further improves accuracy, a method which they term _self-consistency_ (SC).

While SC leads to performance gains, it also has several shortcomings. First, when the space of possible outputs is large [kalyan-etal-2021-much], each reasoning chain may lead to a different output, in which case no significant majority will be formed. Second, focusing exclusively on the final output discards relevant information that is present in the intermediate reasoning steps. Consider answering the question _"Did Brad Peyton need to know about seismology?"_ (Fig. 1). Reasoning chain #1 leads to an incorrect answer (_"No"_), but its steps provide useful information. For example, the intermediate question, and following answer, on _"What is seismology?"_ constitute an important fact that is absent from the other two chains. Last, using SC jointly with chain-of-thought prompting reduces interpretability, as there is no single reasoning chain that can be considered as an explanation.

In this work, we propose _Multi-Chain Reasoning_ (MCR), where we prompt a large language model (LLM) to _meta-reason_ across multiple reasoning chains and produce a final answer, alongside an explanation. Unlike prior work, sampled reasoning chains are used _not_ for their predictions (as in SC) but as a means to _collect pieces of evidence_ from multiple chains. Fig. 1 illustrates MCR compared to SC. While both methods rely on sampling multiple reasoning chains, SC returns the majority answer, _"No"_ (grey box, bottom right). By contrast, MCR concatenates the intermediate steps from each chain (blue boxes, top left) into a unified context, which is passed, along with the original question, to a _meta-reasoner_ model. The meta-reasoner is a separate LLM, prompted to meta-reason on multiple reasoning chains and produce a final answer along with an explanation (pink box, bottom left). By reasoning on multiple reasoning chains, MCR is able to mitigate the aforementioned drawbacks -- it combines facts from multiple chains to produce the correct final answer, with an explanation of the answer's validity.

MCR has three main components (§3). To generate reasoning chains we use two components, a _decomposition_ model and a _retriever_ which jointly generate the chain (Fig. 2), similar to prior work [press2023measuring; trivedi2022interleaving]. These chains are then concatenated into a unified _multi-chain context_ which is fed to the aforementioned meta-reasoner. Fig. 1 highlights the ability of the meta-reasoner to combine facts from different reasoning chains (intermediate answers in pink). The output explanation combines facts from each of the three chains: (1) _"Seismology is the study of earthquakes"_; (2) _"San Andreas is a film\..."_; (3) _"Brad Peyton is a film director, writer\..."_. SC (in grey) errs due to only using the answers, while the meta-reasoner reads entire reasoning chains, and is able to correctly answer the question.

We evaluate MCR on a wide range of challenging multi-hop question answering (QA) datasets, in an open-domain setting. The datasets can be categorized into two types of tasks: _implicit reasoning_ tasks, where reasoning steps are implicit given the question text and need to be inferred using a strategy [tafjord-etal-2019-quartz; geva-etal-2021-aristotle; kalyan-etal-2021-much]; _explicit reasoning_ tasks, where a single reasoning strategy exists and can be directly inferred given the language of the question [yang2018hotpotqa; welbl2018constructing; press2023measuring; Aly2021FEVEROUSFE]. As our baselines, we compare MCR to SC, as well as to variants of Self-Ask [press2023measuring] and CoT augmented with retrieval, following @trivedi2022interleaving. Our results show MCR consistently outperforms all other baselines, in particular, beating SC by up to 5.7%, while using the same reasoning chains (§4).

We analyze the qualities of MCR in §5, by manually scoring its generated explanations and estimating their accuracy. Our analysis shows that MCR generates high quality explanations for over 82% of examples, while fewer than 3% are unhelpful. To conclude, our main contributions are:

- We introduce the MCR method for meta-reasoning on multiple chains-of-thought.

- We show that MCR outperforms all baselines, including self-consistency, on all 7 multi-hop open-domain QA benchmarks.

- We analyze MCR for its explanation quality and its multi-chain reasoning capabilities.

Our data and codebase are publicly available.[^1]

# Background {#sec:background}

Recently, there has been a surge of interest in answering multi-hop questions through few-shot prompting of LLMs [Wei2022ChainOT; nye2022show; yao2022react]. The majority of these works follow a common standard: First, given a question, plan a step-by-step reasoning chain to derive the answer and solve all intermediate steps, aided by a retriever to minimize model hallucination [khot2023decomposed; press2023measuring; yao2022react; lazaridou2023internetaugmented; trivedi2022interleaving; Khattab2022DemonstrateSearchPredictCR]. Then, incorporate multiple reasoning chains with answers to derive the final answer [wang2023selfconsistency; Li2022OnTA]. In our work, we follow this template and focus on the latter part. However, our _meta-reasoning_ approach differs from prior work by reasoning on multiple reasoning chains. Namely, we use multiple chains to collect relevant evidence for question answering.

[IMAGE: fig_decomp_retrieve.pdf]
_Figure: Interleaving decomposition and retrieval steps._

# Method {#sec:method}

We present a method for answering questions by meta-reasoning on multiple reasoning chains. Our focus is on open-domain QA, where the input is a question $q$, and the evidence to answer it is found in one or more sentences in a corpus $C$. When answering $q$ requires multiple reasoning steps, it can be expressed by a _reasoning chain_, denoted by $r$. The reasoning chain is a list of one or more intermediate question-evidence-answer triples $(q_i, e_i, a_i)$. Evidence $e_i \in C$ is a sentence that is relevant to answering the intermediate question $q_i$.

Fig. 2 describes our approach when answering _"How many ants would fit into The Shard?"_. First, we use a prompted LLM to generate multiple reasoning chains, $r^{(1)},...,r^{(k)}$ (steps 1-2). Each $r^{(j)}$ is generated by interleaving generated intermediate questions with retrieved contexts (§3.1). Our main contribution is step 3: We introduce a second LLM that is prompted to _meta-reason_ on multiple reasoning chains, collecting evidence facts as its explanation and generating the final answer (§3.2).

## Generating Reasoning Chains {#sec:method_decomp_retrieve}

Given a question $q$, we generate its reasoning chain using: (1) a decomposition model, and (2) a retriever component. Our reasoning chain generation process is largely based on prior work [press2023measuring; trivedi2022interleaving], discussed in §2. Fig. 3 describes the interleaving of decomposition and retrieval. At each step, the decomposition model generates an intermediate question $q_i$, based on the original question $q$ and the previous reasoning steps. Then, the retriever uses $q_i$ to retrieve relevant evidence $e_i \in C$. We feed $e_i$ and $q_i$ to the decomposition model (along with the previous steps) to generate intermediate answer $a_i$. During answer generation, we prepend intermediate evidence sentences to the beginning of the chain rather than interleaving them, as it improves the accuracy for all baselines. For decomposition prompts, see §12.

## Reasoning over Reasoning Chains {#sec:method_entail}

The meta-reasoner module is the core contribution of MCR. Instead of sampling multiple chains for their predicted _answers_ [wang2023selfconsistency], we utilize them for _context generation_. This context is fed to a prompted LLM to _read_ the generated chains and _reason_ over them to return the answer.

In §3.1, we defined a reasoning chain as a list of $(q_i, e_i, a_i)$ triples. We first sample multiple chains and use all of their intermediate question-answer pairs $(q_i, a_i)$ as our _multi-chain context_ (a variant using question-evidence pairs $(q_i, e_i)$ is described in §10.4). Fig. 2 presents the multi-chain context of the three sampled chains (lower pink box). Next, the multi-chain context and the original question are input to the meta-reasoner. This model is an LLM, few-shot prompted for QA over a multi-chain context. Fig. 4 presents one exemplar from the meta-reasoner prompt for the [Feverous] dataset (full prompts in §12). We instruct the LLM to _"answer the question step-by-step"_ given its multi-chain context, where each line describes a $(q_i, a_i)$ pair from one of the sampled chains. Next, we append the question and a step-by-step reasoning chain followed by the final answer. This last chain serves as the explanation for solving the question. The meta-reasoner is prompted with 6-10 exemplars, based on the dataset (§4.1).

Providing the meta-reasoner with multiple chains allows it to combine and aggregate facts across chains. Moreover, the model needs to extract the most relevant facts in the chains to serve as its explanation. This enables MCR to be both more accurate and more interpretable than past multi-chain approaches (as we analyze in §5).

# Experiments {#sec:experiments}

We compare MCR to existing methods on 7 multi-hop QA benchmarks. These cover a wide range of reasoning skills, including commonsense, composition, comparison and fact verification. MCR consistently outperforms existing approaches on all benchmarks, when experimenting with two different LLMs and retrievers. Our setting is described in §4.1 and we discuss our main results in §4.2.

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given a question and a context, answer the question step-by-step. If you are unsure, answer Unknown.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;"><strong>Context:</strong></td>
</tr>
<tr>
<td style="text-align: left;">Who is Robert Broderip? Robert Broderip was an English organist and composer.</td>
</tr>
<tr>
<td style="text-align: left;">Where did Robert Broderip live all his life? Robert Broderip lived in Bristol all his life.</td>
</tr>
<tr>
<td style="text-align: left;">When did Robert Broderip live? Robert Broderip lived during the 19th century.</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">Where did Robert Broderip live? Broderip lived in Bristol.</td>
</tr>
<tr>
<td style="text-align: left;">During what part of the nineteenth century did Robert Broderip write music? Robert Broderip wrote music during the latter part of the eighteenth century.</td>
</tr>
<tr>
<td style="text-align: left;"><strong>Question:</strong> Is it true that Robert Broderip lived in London all his life and wrote a considerable quantity of music during the earlier part of the nineteenth century?</td>
</tr>
<tr>
<td style="text-align: left;"><strong>Answer:</strong> Robert Broderip lived in Bristol all his life, not in London. <strong>So the answer is:</strong> No.</td>
</tr>
</tbody>
</table>
*Figure: An exemplar from the meta-reasoner prompt.*

## Experimental Setting {#sec:experimentalsetting}

### Datasets {#sec:datasets}

As our focus is on multi-hop questions (in an open-domain setting), all datasets require _multiple_ reasoning steps. Following prior work [Khattab2022DemonstrateSearchPredictCR; trivedi2022interleaving] and to limit the cost of model API calls, we evaluate on 500-1000 random examples from the development set of each dataset.[^2] We also evaluate on the official test sets of [StrategyQA] and [Fermi], as they target implicit reasoning, have multiple valid strategies, and their test set evaluation cost is reasonable. For all datasets, we make sure that no evaluation questions appear in any of our prompts. Tab. 1 has example questions from each dataset. Our multi-hop QA benchmarks can be categorized based on their required reasoning skills:

- **Implicit Reasoning:** Questions that entail implicit reasoning steps [geva-etal-2021-aristotle]. The reasoning steps for solving it cannot be explicitly derived from the language of the question and require commonsense or arithmetic reasoning. Such questions may have multiple valid reasoning chains. We evaluate on: [StrategyQA] [geva-etal-2021-aristotle], [Fermi] [kalyan-etal-2021-much] and [Quartz] [tafjord-etal-2019-quartz].

- **Explicit Reasoning:** Multi-hop questions where the reasoning steps are explicitly expressed in the language of the question (composition, comparison). These include [HotpotQA] [yang2018hotpotqa], [2WikiMQA] [welbl2018constructing] and [Bamboogle] [press2023measuring]. We also evaluate on [Feverous] [Aly2021FEVEROUSFE], a fact verification dataset where claims require verifying multiple facts, and evidence may be either in sentences, tables or both.

For evaluation, we use F$_1$ to compare predicted and gold answers for all explicit reasoning datasets and exact-match for the binary-choice datasets. In [Fermi], we use the official order-of-magnitude evaluation by @kalyan-etal-2021-much. We provide additional technical details on evaluation in §9.

**Dataset** **Example**

---

[StrategyQA] (implicit) Can Arnold Schwarzenegger deadlift an adult Black rhinoceros?
[Fermi] (implicit) How many high fives has LeBron James given/received?
[Quartz] (implicit) Jeff drained his rice field in the wintertime. The field likely will produce \_\_ crops when he uses it. A. more B. less
[HotpotQA] (explicit) What city did the musician whose debut album shares its title with the 1959 Alfred Hitchcock film hail from?
[2WikiMQA] (explicit) Where was the place of death of Isabella of Bourbon's father?
[Bamboogle] (explicit) What is the maximum airspeed (in km/h) of the third fastest bird?
[Feverous] (explicit) Is it true that Robert Broderip lived in London all his life and wrote a considerable quantity of music during the earlier part of the nineteenth century?

: The multi-hop QA datasets in our experiments.

           Dataset            Reasoning   Examples              Oracle                       SA                 SC$@3$               SC$@5$                SCR                    MCR

---

[StrategyQA] 1,000 94.4$\pm$0.1   69.3$\pm$0.3   71.5$\pm$0.8   72.2$\pm$0.8   70.0$\pm$0.6   **73.6$\pm$0.7**
     [Fermi]      implicit      286      65.1$\pm$0.8   38.3$\pm$0.7   38.4$\pm$0.7   38.3$\pm$0.8   38.1$\pm$0.8   **38.9$\pm$0.8**
     [Quartz]                   374      94.1$\pm$0.5   78.3$\pm$0.4   78.2$\pm$0.7   77.6$\pm$0.5   80.7$\pm$0.1   **81.6$\pm$1.3**
    [HotpotQA]                  500      68.0$\pm$0.4   50.2$\pm$0.3   50.5$\pm$0.8   51.3$\pm$0.2   56.4$\pm$0.4   **57.0$\pm$0.8**
    [2WikiMQA]    explicit      500      77.5$\pm$0.8   63.8$\pm$0.1   64.5$\pm$0.8   65.4$\pm$0.6   67.2$\pm$0.2   **67.9$\pm$0.4**
   [Bamboogle]                  120      77.3$\pm$0.5   64.6$\pm$0.6   64.6$\pm$0.4   65.0$\pm$1.5   64.7$\pm$0.4   **66.5$\pm$1.7**
    [Feverous]                  500      88.0$\pm$0.4   66.0$\pm$1.0   67.8$\pm$0.2   67.9$\pm$0.6   65.1$\pm$0.4   **69.4$\pm$1.0\*\*

### Models {#sec:models}

Our main models and baselines are all retrieval-augmented instances of `code-davinci-002`, prompted with in-context learning exemplars [NEURIPS2020_1457c0d6]. In §4.3, we include additional experiments with the open-source `Vicuna-13B` [vicuna2023] LLM. Prompt exemplars are formatted as described in §3.2. The number of exemplars varies from 6-12 between datasets. Decomposition prompt exemplars are based on random examples from the train and development sets, coupled with their gold reasoning chain. For the meta-reasoner exemplars, we use reasoning chains sampled from the decomposition model as the multi-chain context. We ensure that the answer can be inferred using the sampled chains and add an explanation before the final answer, as shown in Fig. 4. For the binary-choice datasets, [StrategyQA], [Quartz], and [Feverous], the prompt contains an equal number of exemplars from each label. For additional details regarding the full prompts, length statistics and robustness to a different choice of prompts, please refer to §12.

#### Meta-Reasoner

We experiment with two variants of the meta-reasoner to measure the effect of reasoning on more than a single chain.

- **MCR:** The meta-reasoner is given five reasoning chains as its multi-chain context (§3.2). We decode one chain with greedy decoding, and sample another four reasoning chains with temperature $t=0.7$.[^3] This enables the meta-reasoner to review different pieces of evidence when answering the full question (§5).

- **SCR:** Single-Chain Reasoning (SCR) serves as an ablation for the effect of the multi-chain context. In SCR, the meta-reasoner is given the same prompt as MCR aside from having only the greedy-decoded chain in its context. This disentangles the effect of using multiple chains from the effect of having an LLM that is separate from the decomposition model to generate the final answer.

#### Baselines

We evaluate the following baselines:

- **SA:** Self-Ask [press2023measuring] returns the answer of a single reasoning chain, that was generated with greedy decoding.

- **SC:** Self-Consistency serves as a baseline which incorporates multiple reasoning chains [wang2023selfconsistency]. It returns the majority answer based on multiple chains sampled from the decomposition model. We experiment with variants of 3, 5 and 15 sampled chains (SC$@3$, SC$@5$ and SC$@15$), in line with prior work [wang2023selfconsistency; Khattab2022DemonstrateSearchPredictCR; sun2022recitation]. As in MCR, we use the chain generated with greedy decoding along with additional chains sampled with $t=0.7$.

#### Retrieval

Similar to @press2023measuring [lazaridou2023internetaugmented; Paranjape2023ARTAM], our models and baselines use a retriever based on Google Search, via the SerpAPI service.[^4] However, we also include results using an open-source retriever [khattab2020colbert] in §4.3. As most of our datasets contain evidence from Wikipedia (§4.1.1), we consider it as our retrieval corpus. Therefore, we format search queries as "`en.wikipedia.org `$q_i$", with the Wikipedia domain preceding the intermediate question. We return the top-1 evidence retrieved by Google. Retrieved evidence may be either sentences or parsed lists. Following @trivedi2022interleaving, we also retrieve evidence for the original question $q$. Last, all retrieved evidence sentences are prepended to the decomposition (§3.1). Additional implementation details about our retrieval and MCR are described in §10.1 and §10.2.

## Main Results {#sec:results}

Next, we report our evaluation results. Overall, MCR outperforms our baselines on all 7 datasets.

#### MCR Performance

Tab. [\[tab:dev_set_results\]](#tab:dev_set_results) presents the results for all 7 multi-hop datasets (evaluation described in §4.1.1). We evaluate both SC$@5$ and MCR using five reasoning chains. In addition, we list an _oracle score_ which uses the best answer out of all five chains. MCR outperforms all baselines on all of the benchmarks, beating SC$@5$ on [StrategyQA] (+1.4%), [Fermi] (+0.6%), [Quartz] (+4.0%), [HotpotQA] (+5.7%), [2WikiMQA] (+2.5%), [Bamboogle] (+1.5%) and [Feverous] (+1.5%).

#### Adding Reasoning Chains

We measure the gains of MCR and SC when adding reasoning chains. As extending MCR is bounded by context length,[^5] we follow a straightforward approach and perform self-consistency on three MCR runs. We compare this model, MCR$+$SC$@3$, which used 15 reasoning chains (5 for each MCR run), to SC$@15$. Tab. 2 shows that MCR$+$SC$@3$ consistently outperforms SC$@15$. Furthermore, though MCR uses only 5 reasoning chains, it beats SC$@15$ on all datasets, save [StrategyQA]. Fig. 5 plots, for each dataset, the effect that adding more reasoning chains has on meta-reasoning performance. It presents the results with 1 chain (SCR), 5 chains (MCR) and 15 reasoning chains (MCR$+$SC$@3$).

           Dataset            SC$@15$   MCR   MCR$+$SC$@3$

---

[StrategyQA] 74.6 73.6 **76.4**  
 [Fermi] 38.6 38.9 **39.2**  
 [Quartz] 78.3 81.6 **82.6**  
 [HotpotQA] 54.1 57.0 **59.2**  
 [2WikiMQA] 65.8 67.9 **68.6**  
 [Bamboogle] 65.6 **66.5** 66.3  
 [Feverous] 68.6 69.4 **71.5**

: Running SC and MCR on 15 reasoning chains.

[IMAGE: mcr_num_chains_plot.pdf]

<figcaption><span id="fig:mcr_num_chains_plot" data-label="fig:mcr_num_chains_plot"></span>Per-dataset performance as a function of the number of reasoning chains used by MCR (1, 5, 15).</figcaption>

#### Test Set Results

We evaluate our models on the official test sets of [StrategyQA][^6] and [Fermi], which include 490 and 558 examples respectively. The results in Tab. 3 show that on [StrategyQA] MCR consistently beats SC, when using the same number of reasoning chains. In [Fermi], both methods perform similarly.

Model \# chains [StrategyQA] [Fermi]

---

SC$@5$ 5 71.4 **39.8**
MCR 5 **72.5** 39.7
SC$@15$ 15 74.1 39.7
MCR$+$SC$@3$ 15 **75.3** **40.1**

: Test set results for [StrategyQA] and [Fermi].

#### Recent Approaches

Previously, we established the advantages of meta-reasoning over multiple reasoning chains. While an apples-to-apples comparison with other recent approaches is impossible due to fundamental differences in the experimental setup (see §10.3), it serves as a rough measuring stick for the robustness of MCR across different tasks. In §10.3, Tab. [\[tab:past_work\]](#tab:past_work) we compare MCR to five recent CoT-based approaches for multi-hop QA. MCR performance is comparable with the best results on all datasets (shared between these works), showcasing its robustness.

## Open-source Models {#sec:colbert_vicuna}

To further examine MCR's performance (§4.2) and for better reproducibility, we experiment with an additional open-source retriever and LLM. As our retriever, we use ColBERTv2 [santhanam-etal-2022-colbertv2] over the 2018 Wikipedia dump from @karpukhin-etal-2020-dense. In addition to `code-davinci-002`, we experiment with `Vicuna-13B` [vicuna2023], a 13-billion parameters model shown to outperform LLMs like LLaMA and Alpaca [Touvron2023LLaMAOA; alpaca]. We use the same prompts as in `code-davinci-002`, trimmed to fit a 2,048 tokens context length.

We report the full results of the open-source ColBERTv2 retriever with `code-davinci-002` and `Vicuna-13B` in Tab. [\[tab:vicuna_colbert_results_appendix\]](#tab:vicuna_colbert_results_appendix). In addition, we provide results of open-source models when reasoning over 15 reasoning chains in Tab. [\[tab:mte-sc_colbert_appendix\]](#tab:mte-sc_colbert_appendix). For `code-davinci-002`, substituting Google Search with ColBERTv2 exhibits the same trend as in Tab. [\[tab:dev_set_results\]](#tab:dev_set_results), albeit a slight decrease in performance. MCR outperforms all other baselines, beating SC$@5$ on [StrategyQA] (+2.3%), [Fermi] (+3.4%), [Quartz] (+3.9%), [HotpotQA] (+3.5%), [2WikiMQA] (+1.2%), [Bamboogle] (+3.6%) and [Feverous] (+1.4%). Unsurprisingly, results sharply decrease when evaluating the smaller `Vicuna-13B` with ColBERTv2. The comparison between MCR and SCR suggests that reasoning over multiple chains is a challenge for the weaker `Vicuna-13B` model. For example, it generates open-ended answers such as _"Unknown"_ or _"It depends"_ for over $24\%$ of the questions in [StrategyQA]. This suggests that meta-reasoning over multiple chains has greater gains (compared to SCR) when both the decomposition model and meta-reasoner are larger LLMs.

However, even on `Vicuna-13B`, MCR still outperforms all baselines on 5 datasets and beats SC$@5$ on all 7 of them: [StrategyQA] (+0.5%), [Fermi] (+4.6%), [Quartz] (+3.6%), [HotpotQA] (+6.5%), [2WikiMQA] (+0.3%), [Bamboogle] (+3.0%) and [Feverous] (+1.3%). When evaluating with 15 reasoning chains, in Tab. [\[tab:mte-sc_colbert_appendix\]](#tab:mte-sc_colbert_appendix), MCR$+$SC$@3$ continually beats SC$@15$.

           Dataset                  Model                     Oracle                       SA                 SC$@3$               SC$@5$                  SCR                      MCR

---

[StrategyQA] `code-davinci-002` 94.5$\pm$0.7   67.1$\pm$0.6   69.9$\pm$0.1   70.8$\pm$0.6     67.8$\pm$0.5     **73.1$\pm$2.1**
     [Fermi]      `code-davinci-002`   64.3$\pm$0.7   33.2$\pm$0.3   33.2$\pm$0.4   33.1$\pm$0.4     33.9$\pm$0.6     **36.5$\pm$2.1**
     [Quartz]     `code-davinci-002`   93.9$\pm$0.6   77.1$\pm$0.6   75.6$\pm$0.7   76.0$\pm$1.5     79.3$\pm$0.3     **79.9$\pm$1.2**
    [HotpotQA]    `code-davinci-002`   67.7$\pm$0.7   50.7$\pm$0.3   51.5$\pm$0.6   52.5$\pm$0.1     55.3$\pm$0.2     **56.0$\pm$1.1**
    [2WikiMQA]    `code-davinci-002`   68.3$\pm$0.4   52.4$\pm$0.1   51.1$\pm$0.2   52.7$\pm$0.4     53.7$\pm$0.3     **53.9$\pm$0.3**
   [Bamboogle]    `code-davinci-002`   56.4$\pm$1.2   45.9$\pm$1.1   47.2$\pm$1.4   47.0$\pm$0.7     47.1$\pm$1.0     **50.6$\pm$1.3**
    [Feverous]    `code-davinci-002`   84.1$\pm$0.7   61.2$\pm$0.4   62.9$\pm$0.6   63.1$\pm$1.0     60.9$\pm$0.3     **64.5$\pm$0.8**
   [StrategyQA]      `Vicuna-13B`      82.4$\pm$0.2   59.7$\pm$0.1   61.4$\pm$0.5   62.2$\pm$0.8   **63.7$\pm$0.0**     62.7$\pm$0.1
     [Fermi]         `Vicuna-13B`      45.7$\pm$1.0   19.1$\pm$0.2   19.1$\pm$0.3   18.8$\pm$0.3     21.5$\pm$0.0     **23.4$\pm$0.4**
     [Quartz]        `Vicuna-13B`      89.6$\pm$1.6   61.1$\pm$0.1   59.8$\pm$2.3   61.4$\pm$1.6     63.9$\pm$0.0     **65.0$\pm$0.3**
    [HotpotQA]       `Vicuna-13B`      52.7$\pm$0.5   34.8$\pm$0.0   35.8$\pm$0.2   37.1$\pm$0.4     43.4$\pm$0.0     **43.6$\pm$1.6**
    [2WikiMQA]       `Vicuna-13B`      52.2$\pm$0.3   32.2$\pm$0.4   33.8$\pm$0.6   34.0$\pm$1.0   **35.1$\pm$0.0**     34.3$\pm$0.4
   [Bamboogle]       `Vicuna-13B`      42.3$\pm$1.6   30.7$\pm$0.0   30.4$\pm$0.6   31.4$\pm$0.6     31.3$\pm$0.0     **34.4$\pm$1.3**
    [Feverous]       `Vicuna-13B`      88.7$\pm$0.2   61.5$\pm$0.6   61.0$\pm$0.6   61.0$\pm$0.8     60.6$\pm$0.0     **62.3$\pm$1.2\*\*

           Dataset                  Model          SC$@15$   MCR$+$SC$@3$      Model       SC$@15$   MCR$+$SC$@3$

---

[StrategyQA] `code-davinci-002` 72.6 **75.6** `Vicuna-13B` 62.3 **63.7**
[Fermi] `code-davinci-002` 34.0 **36.3** `Vicuna-13B` 18.8 **23.2**
[Quartz] `code-davinci-002` 76.5 **80.7** `Vicuna-13B` 60.1 **64.3**
[HotpotQA] `code-davinci-002` 54.3 **56.8** `Vicuna-13B` 37.8 **44.8**
[2WikiMQA] `code-davinci-002` 52.5 **54.0** `Vicuna-13B` 35.5 **35.6**
[Bamboogle] `code-davinci-002` 48.9 **51.8** `Vicuna-13B` 31.8 **35.1**
[Feverous] `code-davinci-002` 62.7 **66.2** `Vicuna-13B` 61.1 **64.0**

# Analysis {#sec:analysis}

Next, we measure the importance of incorporating multiple reasoning chains in MCR and qualitatively assess its output.

#### When are Multiple Chains Helpful?

In §4.2 we observed that MCR consistently outperforms single-chain reasoning (SCR). We wish to prove that this advantage lies in cases where the meta-reasoner uses additional chains. To this end, we sort examples based on the similarity of their greedy-decoded chain to the MCR explanation (details in §11.1). Lower similarity indicates less reliance of MCR on the greedy chain. Fig. 6 presents an example where the MCR explanation (pink box) includes relevant facts from a chain other than the greedy one (additional examples in §11.2). Results in Fig. 7 empirically demonstrate that on [StrategyQA], MCR gains over SCR are highest when MCR explanations are less similar to the greedy chain. We observe this trend in all datasets (§11.1), serving as further evidence for MCR's strengths.

[IMAGE: mcr_vs_scr.pdf]
_Figure: An example from StrategyQA where the greedy chain is insufficient to answer the question. MCR beats SCR by having access to multiple chains._

[IMAGE: sim_to_greedy_strategyqa_1.9.pdf]
_Figure: MCR and SCR accuracy on StrategyQA, categorized by the similarity of the greedy chain to the MCR explanation. When MCR uses a chain other than the greedy one (lower similarity), it outperforms SCR._

#### Combining Reasoning Chains

In addition to choosing between reasoning chains, an interesting property of the meta-reasoner is that it can _combine_ facts from different chains. We estimate the prevalence of this phenomenon on the implicit datasets, [StrategyQA] and [Fermi], which are more challenging. Given an example, we automatically check if its meta-reasoner explanation is the result of combining chains. We examine if one of the output sentences appears in exactly one chain, while another sentence is absent from that chain and is part of a different chain. We consider sentences as similar if their ROUGE-1 precision is above 0.8, and distinct if it is below 0.2. Overall, in 20% of [StrategyQA] examples and 25% of [Fermi], the MCR explanation results from combining reasoning chains. From a manual analysis of 50 such examples for each dataset, we observe that these multi-chain explanations are better than any individual reasoning chain in $10\%$ of cases (see examples in §11.2, Fig. 10). For the remaining $90\%$, the reasoning expressed in the resulting combination is a paraphrase of an individual chain.

#### Explanation Quality

The meta-reasoner is prompted to generate an explanation alongside the final answer (§3.2). Inspired by past work [pruthi2021evaluating], we test the quality of the MCR explanations. Four of the authors manually reviewed 600 random examples, 100 per dataset (sans [Feverous] §10.2) and scored their meta-reasoner explanations. Each explanation is scored as either 1 (irrelevant), 2 (partially relevant) or 3 (highly relevant), based on its relevance to answering the question. We find the explanation is highly relevant in 82% of the cases (87% excluding [Fermi], which is the most challenging), and is irrelevant in less than 3%.

Next, we evaluate the _faithfulness_ of explanations [jacovi-goldberg-2020-towards], namely, whether a person provided only with the question and MCR explanation would answer the same as the model. Our focus was on examples with quality explanations (score 3), since they are answerable given the explanation. We answered each question based on the model's explanation. In 90% of cases (95% excluding [Fermi]), the MCR predictions matched our own, highlighting the faithfulness of its explanations. We attribute part of the gap between human and MCR predictions to implicit reasoning tasks, where humans lead by five points, on average. For the full results, see §11.3.

#### Error Analysis

We manually analyzed 700 errors by MCR (100 per dataset). We consider the following categories: _Valid_ predictions where the generated answer is accurate or the original question is ambiguous; _Decomposition_ errors where no chain has the necessary reasoning steps to answer the question; _Retrieval_ errors where the retrieved contexts were irrelevant, leading the model to hallucinate; _Explanation_ errors where MCR generates a wrong explanation while a correct one is present in the multi-chain context; _Answer_ errors are when the MCR explanation is correct, but the answer is not; _Contradicting_ facts are cases where MCR errs due to contrasting statements appearing in the multi-chain context.

Tab. 4 lists the prevalence of the error categories per dataset. In four datasets, over 20% of errors appear to be valid predictions, labeled as incorrect due to ambiguous questions, outdated answers or dataset errors. Decomposition is a challenge in the implicit datasets, [StrategyQA] and [Fermi], with more than 24% of errors. Comparing errors on different reasoning datasets (excluding valid examples): Explanation and Answer errors are 50% on implicit reasoning datasets compared to 23% on explicit reasoning ones; Retrieval errors are more prevalent in explicit reasoning tasks with 66% of errors being due to Retrieval or Contradicting facts, compared to 30% in implicit datasets. Additional technical details on our analysis are in §11.4.

           Dataset            Va.   De.   Re.   Co.   Ex.   An.

---

[StrategyQA] 20% 24% 8% 15% 20% 17%
[Fermi] 6% 39% 20% 4% 17% 23%
[Quartz] 14% 6% 13% 19% 11% 40%
[HotpotQA] 33% 24% 24% 11% 11% 5%
[2WikiMQA] 39% 4% 35% 12% 8% 6%
[Bamboogle] 26% 8% 32% 24% 13% 0%
[Feverous] 7% 14% 34% 23% 20% 6%

: Error classes per dataset: Valid (Va.), Decomposition (De.), Retrieval (Re.), Contradicting facts (Co.), Explanation (Ex.) and Answer (An.). We allow multiple error categories per example.

# Related Work {#sec:related_work}

For a thorough survey on LLM reasoning see @lu2022survey [huang2022reasoning; qiao2022reasoning]. A slew of recent works have focused on eliciting multi-step reasoning in LLMs, including scratchpads [nye2022show], chain-of-thought prompting [Wei2022ChainOT; Zhou2022LeasttoMostPE], learned verifiers [cobbe2021training], selection-inference [Creswell2022SelectionInferenceEL] and bootstrapping [zelikman2022star].

Self-consistency [wang2023selfconsistency; Fu2022ComplexityBasedPF] selects the majority answer across multiple chains, outperforming learned verifiers and "sample-and-rank" approaches [adiwardana2020humanlike; DeFreitas2020TowardsAH]. further improve SC by increasing chains' diversity and introducing a trained verifier. @tafjord2022entailer over-samples chains and verifies them using a natural language inference model on intermediate steps, while re-rank chains based on intermediate retrieved evidence. In addition, meta-reasoning is closely tied to _self-reflection_ in LLMs, which is becoming increasingly important in using the LLM to review multiple strategies [yao2023tree; shinn2023reflexion; madaan2023selfrefine].

Recent works proposed revising LLM-generated texts by using retrieved sentences [gao2022rarr] or model-generated feedback [madaan2023selfrefine; chen2023teaching; paul2023refiner]. MCR similarly reviews LLM-generated reasoning chains however, its focus is meta-reasoning on _multiple_ chains.

Significant QA research has been dedicated to reasoning over multiple facts retrieved from an underlying corpus. Such tasks include multi-step questions that require explicit reasoning [talmor2018web; welbl2018constructing; wolfson2020break; trivedi2021musique], implicit reasoning [geva-etal-2021-aristotle] and multi-modal capabilities [talmor2021multimodalqa].

Recent works also target retrieval-augmented LLMs, prompted to solve open-domain questions [lazaridou2023internetaugmented; Khattab2022DemonstrateSearchPredictCR; trivedi2022interleaving; ram2023ralm; yoran2023making].

# Conclusion

This work introduces MCR for meta-reasoning over multiple reasoning chains. We evaluate MCR on 7 datasets for multi-hop QA that require both implicit and explicit reasoning in an open-domain setting and show that it outperforms previous approaches on all evaluation benchmarks.

# Limitations {#sec:limitations}

In this work we introduce a meta-reasoner model to reason over multiple reasoning chains. While we opt for a prompted LLM as our meta-reasoner, we do not experiment with a fine-tuned meta-reasoning model. For the meta-reasoner context, we experiment with variants which include either generated QA pairs or retrieved evidence sentences. We leave further improvements to the meta-reasoner context as future work. Due to the inference costs of current state-of-the-art LLMs we evaluate on the `code-davinci-002` model, similar to prior work [trivedi2022interleaving; wang2023selfconsistency]. However, to improve the reproducibility of our work we also provide results with an open-source LLM [vicuna2023] and retriever [khattab2020colbert].

# Evaluation {#sec:evaluation_appendix}

## Generating Unknown as the Answer {#sec:evaluation_abstain}

As we prompt LLMs to generate answers, a potential outcome is for the model to _abstain_ from answering the question, by generating _Unknown_ as its answer. Additional cases are when the model generates an end-of-sequence token without any final answer. In the binary-choice datasets, [StrategyQA], [Quartz] and [Feverous], we assign a score of 0.5 to such examples, thereby simulating a random guess. When submitting predictions to the [StrategyQA] test set, we identify cases of model abstains or null predictions beforehand. For these examples, we assign a label of either _Yes_ or _No_ at random. In datasets with open-ended answers, we assign a score of 0 when the predicted answer is either _Unknown_ or null. To make Self-Ask a stronger baseline, when the greedy decoded chain has a null answer, we randomly choose a prediction from one of the other chains. For SC, we do not consider predictions from chains where answers are _Unknown_ or null.

## [Fermi] {#sec:fermi_appendix}

The [Fermi] dataset requires approximating numeric answers for open-ended questions. Example questions are shown in Tab. 1 and Fig. 2. When providing a [Fermi] question to our models and baselines we also add the gold answers measure units (e.g. meters, cubes, litres, etc.). While this additional input helps the model, we note that we provide it to all our baselines for a fair comparison with MCR. Nevertheless, even when given the gold units, predicting the final answers to [Fermi] problems remains highly challenging.

# Models {#sec:appendix_models}

## Retrieval {#sec:retrieval}

For our retrieval, we use the Google Search Engine, via SerpAPI, and return the top-1 retrieved result as an evidence snippet. Snippets can include answer-boxes and tables.[^7] We prepend the page title to the beginning of the snippet, as shown in Fig. 8.

[IMAGE: snippet_example_2.0.png]

<figcaption>Example for a retrieved evidence snippet for one of the intermediate questions from Fig. <a href="#fig:multi_chain_example" data-reference-type="ref" data-reference="fig:multi_chain_example">1</a>.</figcaption>

Model Ret. LLM \# Chains [StrgyQA] [HotpotQA] [2WikiMQA]

---

CoT [wang2023selfconsistency] no `code-davinci-002` 1 73.4 39.8 \-
CoT$+$SC$@40$ [wang2023selfconsistency] no `code-davinci-002` 40 79.8 44.6 \-
Self-Ask [press2023measuring] yes `text-davinci-002` 1 \- \- 52.6
DSP [Khattab2022DemonstrateSearchPredictCR] yes `text-davinci-002` 20 \- 62.9 \-
IR-CoT [trivedi2022interleaving] yes `code-davinci-002` 1 \- 61.2 65.2
Self-Ask (ours) yes `code-davinci-002` 1 69.3 50.2 63.8
MCR yes `code-davinci-002` 5 73.6 (+4.3) 57.0 (+6.8) 67.9 (+4.1)
MCR$+$SC$@3$ yes `code-davinci-002` 15 76.4 (+7.1) 59.2 (+9.0) 68.6 (+4.8)

## Implementation Details {#sec:hps}

We describe the design choices made in our MCR model, such as preforming retrieval on the original question and a variant of the meta-reasoner prompt for [Feverous]. Due to cost limitations, we evaluate our design choices at a smaller scale and avoid running an exhaustive grid search.

#### Retrieving the Original Question

We follow past work [trivedi2022interleaving] by incorporating retrieved evidence for the original question in addition to evidence retrieved for the intermediate steps (§3.1). This has a positive or negligible effect on most datasets however, it dramatically decreases the results of all models on the [Fermi] task. Results drop for SA (38.3$\pm$0.7 to 34.7$\pm$0.5), SC (38.3$\pm$0.8 to 34.4$\pm$0.3), SCR (38.1$\pm$0.8 to 34.4$\pm$0.8) and MCR (38.9$\pm$0.8 to 37.0$\pm$0.7). Therefore, our models are run without original question retrieval when evaluated on [Fermi]. Interestingly, while all models perform roughly the same without original question retrieval, MCR appears better by 2 points when evidence for the original question is used. We hypothesize that it might be due to MCR being somewhat more robust to the addition of irrelevant evidence.

#### [Feverous] Meta-Reasoner Prompt

As described in §3.2, the meta-reasoner generates an explanation which precedes the final answer. [Feverous] is distinct from all other datasets as it require verification of multiple facts in order to verify or disprove a complex statement. When a statement is false, we list one or more of its false intermediate facts along with its correction. For example, in Fig. 4 we list that Robert Broderip lived in Bristol, not London. When prompting the meta-reasoner to list both true and false intermediate facts, we observed a decrease in performance for both MCR (69.4$\pm$1.0 to 66.4$\pm$0.7) and SCR (65.1$\pm$0.4 to 62.9$\pm$0.3). We hypothesize that repeating multiple true facts excessively prompts the model to predict the label "Yes" in cases where most (but not all) of the intermediate facts are correct.

## Empirical Comparison to Recent Approaches {#sec:recent_approaches_comparison}

In Tab. [\[tab:past_work\]](#tab:past_work), we compare MCR to recent CoT-based approaches for multi-hop reasoning. An apples-to-apples comparison is not possible, as these methods do not evaluate on all 7 of our datasets and use varying samples of 500-1,000 dev examples for their evaluation. Moreover, different methods use different retrieval corpora, hyperparameters, prompts and LLMs. Nevertheless, we argue that a direct comparison serves as a measuring stick for MCR's robustness across multiple datasets, compared to similar solutions.

Evaluation differences include the retrieval corpora, as both IR-CoT and DSP use the official Wikipedia dump provided with the [HotpotQA] dataset [yang2018hotpotqa]. Our retrieved evidence are from an updated version of Wikipedia, via Google Search. Since certain facts may change over time, this could potentially explain the high percentage of MCR predictions labeled as valid in our error analysis (§5).

We emphasize that our focus is on highlighting the potential of reasoning on reasoning chains. MCR is a method aimed at improving models which generate reasoning chains. Compared to SC, we observe that MCR further boosts the underlying SA model. While task-specific improvements are possible, they are orthogonal to our work.

## Reasoning on Retrieved Evidence {#sec:ent_contexts}

The meta-reasoner answers questions given a multi-chain context of _question-answer_ ($q_i$, $a_i$) pairs, extracted from multiple reasoning chains (§3.2). We experiment with an alternative multi-chain context, comprised of _questions_ and retrieved _evidence_ ($q_i$, $e_i$) (§3.1). This setting resembles past work [trivedi2022interleaving] however, our sentences are intermediate evidence from _multiple_ reasoning chains, not just the greedy-decoded chain. We compare these variants, MCR-Ev and SCR-Ev, to MCR and SCR that reason on QA pairs. Tab. [\[tab:entailment_on_contexts\]](#tab:entailment_on_contexts) shows that meta-reasoning on retrieved evidence is less effective. The gap is more evident in implicit reasoning tasks, perhaps due to retrieved evidence being less relevant on average. Example prompts for MCR-Ev and SCR-Ev are listed in §12.

           Dataset                  SCR-Ev                  SCR                     MCR-Ev                    MCR

---

[StrategyQA] 69.1$\pm$0.4   **70.0$\pm$0.6**     73.2$\pm$0.6     **73.6$\pm$0.7**
     [Fermi]      34.1$\pm$0.6   **38.1$\pm$0.8**     33.9$\pm$0.3     **38.9$\pm$0.8**
     [Quartz]     76.1$\pm$0.2   **80.7$\pm$0.1**     76.2$\pm$1.9     **81.6$\pm$1.3**
    [HotpotQA]    53.5$\pm$0.1   **56.4$\pm$0.4**   **58.2$\pm$1.0**     57.0$\pm$0.8
    [2WikiMQA]    66.2$\pm$0.2   **67.2$\pm$0.2**     67.1$\pm$0.9     **67.9$\pm$0.4**
   [Bamboogle]    64.1$\pm$0.0   **64.7$\pm$0.4**   **67.4$\pm$2.3**     66.5$\pm$1.7
    [Feverous]    64.0$\pm$0.5   **65.1$\pm$0.4**     62.5$\pm$0.5     **69.4$\pm$1.0\*\*

# Analysis {#sec:appendix_analysis}

## When are Multiple Chains Helpful? {#sec:appendix_multiple_chains}

In §5, we have shown that the advantage of MCR over SCR lies in examples where the meta-reasoner uses chains other than the one generated through greedy decoding. In Fig. 9 we provide the results for all other datasets, in addition to the [StrategyQA] results in Fig. 7. The similar trend among all datasets is that in examples with lower similarity to the greedy chain, MCR gains over SCR are higher.

The similarity between the meta-reasoner explanation and the greedy decoded reasoning chain is defined as follows: We calculate the ROUGE-1-precision [lin-2004-rouge] between the explanation and the chain. Low, Medium, and High are based on thresholds of $\frac{1}{3}$, $\frac{2}{3}$, and $1$ respectively, with the Identical category indicating an exact match.

[IMAGE: mte_vs_ste_example_all_datasets_2.1.pdf]

<figcaption>MCR and SCR accuracy on Fermi, Quartz, 2WikiMQA, Bamboogle, HotpotQA, and Feverous, on examples categorized by their MCR explanation’s similarity to the greedy chain. MCR performs similarly to SCR when similarity is high, and outperfoms SCR when similarity is lower. Error bars indicate standard deviation, which tends to be high when the number of examples in the bin is small. For Feverous we display the variant where MCR has to repeat all relevant facts (§<a href="#sec:hps" data-reference-type="ref" data-reference="sec:hps">10.2</a>), to make sure the MCR explanation is not empty.</figcaption>

## Combining Reasoning Chains {#sec:combining_chains}

Fig. 10 provides additional examples for combining facts between multiple reasoning chains.

[IMAGE: trace_mixing_examples_1.1.png]
_Figure: Examples for combining facts from multiple reasoning chains._

## Explanation Quality Analysis {#sec:explanation_quality_analysis}

We provide additional details on the annotation for the scoring meta-reasoner explanations. The annotation was performed by 4 graduate students that are authors of this paper. The annotators were presented with a question and an explanation, and asked to perform two tasks: (a) score the explanation for its quality and (b) answer the question based on the meta-reasoner explanation. We provide the full instructions shown to the annotators in Fig. 11 and the full results in Tab. [\[tab:quality_analysis\]](#tab:quality_analysis).

[IMAGE: explanation_quality_instructions_1.2.png]
_Figure: The annotation instructions for the MCR explanation quality analysis._

**dataset** Reasoning **%3** **%2** **%1** **Sim_predictions** **Human_acc** **MCR_acc**

---

[StrategyQA] 79 18 3 89.9 77.2 72.2
[Fermi] implicit 60 32 8 76.0 47.8 40.7
[Quartz] 91 7 2 98.9 87.9 86.8
[HotpotQA] 77 21 2 95.4 49.2 49.2
[2WikiMQA] explicit 97 2 1 94.9 69.6 69.2
[Bamboogle] 90 9 1 98.2 71.5 71.4
Average implicit 76.7 19.0 4.3 88.3 71.0 66.6
Average explicit 88.0 10.7 1.3 96.2 63.4 63.3
Average 82.3 14.8 2.8 92.2 67.2 64.9

## Error Analysis {#sec:error_analysis}

We provide additional details regarding our error analysis (§5). In less than 5%, we encountered grammatically bad questions which we were unable to comprehend and were therefor discarded from our analysis. For example the [HotpotQA] question: "What does the goddess associated with the goddess Frigg consists of what tales?"

The input to our meta-reasoner model is a context comprised of $(q_i, a_i)$ pairs, generated by the decomposition model. As the decomposition model is an LLM that is conditioned on retrieved evidence (and prior decomposition steps) it may hallucinate false intermediate answers. In cases of such hallucinations we distinguish between two error types, based on the relevant component. First, _Retrieval errors_ are cases where no relevant information was retrieved, leading to the decomposition model hallucinating an incorrect $a_i$, passed on to the meta-reasoner's context. Second, we treat cases where relevant evidence was retrieved, but the decomposition model ignored it and hallucinated an incorrect $a_i$ as _Decomposition errors_.

Errors stemming from _Contradicting Facts_, are cases where the meta-reasoner context contains two contradicting facts, one accurate while the other was hallucinated by the decomposition model. For example, Fig. 12 displays an example where the context has contradicting facts on who was the father of Eliezer Ben-Yehuda. When the meta-reasoner has contradicting facts, it is expected to select the correct fact, based on the knowledge encoded in its parameters. Addressing such errors in future work could rely on refining generated text with methods such as RARR [gao2022rarr].

As our error classes mainly match the MCR components, this error breakdown could potentially help to guide future improvements.

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given a question and a context, answer the question step-by-step. If you are unsure, answer Unknown.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;"><strong>Context:</strong></td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of modern Hebrew? The father of modern Hebrew is Eliezer Ben-Yehuda.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of Eliezer Ben-Yehuda? The father of Eliezer Ben-Yehuda is Abraham.</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of modern Hebrew? The father of modern Hebrew is Eliezer Ben-Yehuda.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of Eliezer Ben-Yehuda? Eliezer Ben-Yehuda’s father is Yehuda Leib.</td>
</tr>
<tr>
<td style="text-align: left;"><strong>Question:</strong> Who is the father of the father of modern Hebrew?</td>
</tr>
<tr>
<td style="text-align: left;"><strong>Answer:</strong> The father of modern Hebrew is Eliezer Ben-Yehuda. The father of Eliezer Ben-Yehuda is Abraham. <strong>So the answer is:</strong> Abraham.</td>
</tr>
<tr>
<td style="text-align: left;"><strong>Gold answer is:</strong> <em>Yehuda Leib</em></td>
</tr>
</tbody>
</table>
<figcaption>Example a <em>Contradicting Facts</em> error. When generating the explanation, the meta-reasoner has to rely on knowledge encoded in its parameters to decide between multiple contradicting facts in its context on who was the father of Eliezer Ben-Yehuda.</figcaption>

# Prompts {#sec:appendix_prompts}

## Prompt Details {#sec:appendix_prompts_details}

We provide example prompts for our models for one explicit dataset ([2WikiMQA], decomposition: Fig. 13, MCR/SCR: Fig. 15, MCR-Ev/SCR-Ev: Fig. 17) and one implicit dataset ([StrategyQA], decomposition: Fig. 14, MCR/SCR: Fig. 16, MCR-Ev/SCR-Ev:Fig. 18). All of our prompts will be released along with our codebase. We use random examples and spend minimal effort on prompt engineering. The number of exemplars varies slightly between dataset and model, with the exact numbers listed in Tab. [\[tab:num_examplars\]](#tab:num_examplars).

           Dataset            SA   SCR   MCR   SCR-Ev   MCR-Ev

---

[StrategyQA] 10 6 6 6 6  
 [Fermi] 6 6 6 6 6  
 [Quartz] 6 8 8 8 8  
 [HotpotQA] 12 10 10 10 10  
 [2WikiMQA] 6 6 6 6 6  
 [Bamboogle] 6 6 6 6 6  
 [Feverous] 10 10 10 10 10

## Prompt Statistics {#sec:appendix_prompts_stats}

In Tab. [\[tab:prompt_len_stats\]](#tab:prompt_len_stats) we provide statistics of the sequence lengths for all of our models, which include all the decomposition prompts, output decomposition sequences, retrieved evidence and the meta-reasoning prompts. The statistics are for our decomposition model (used by all of our baselines), as well as for the meta-reasoning prompts (used by SCR and MCR). Note that generating a single reasoning chain requires multiple LLM calls, one for each decomposition step. Therefore, a single decomposition generation is generally longer than applying one additional meta-reasoning step.

Results are averaged over multiple runs, corresponding to the results in Tab. [\[tab:dev_set_results\]](#tab:dev_set_results). Sequence lengths in Tab. [\[tab:prompt_len_stats\]](#tab:prompt_len_stats) correspond to the number of tokens provided by the `code-davinci-002` tokenizer.

           Dataset             Dec.     Dec. steps    Dec. out.    Ret. len.    Meta-reason   SCR   MCR

---

[StrategyQA] 2,242 2.9±0.6 103.3± 48.0 190.6±66.7 1,652 1,749.0± 52.0 2,032.9±110.7
[Fermi] 1,442 2.3±0.9 91.4±31.9 165.8±78.9 1,681 1,765.5±25.5 1,984.1±79.6
[Quartz] 839 1.2±0.5 55.2±20.6 92.7±28.7 2,129 2,202.4±19.8 2,343.6±48.3
[HotpotQA] 2,508 1.7±0.7 86.1±91.9 153.0±84.1 2,380 2,460.3±28.1 2,666.2±90.0
[2WikiMQA] 1,920 2.4±0.8 92.7±30.5 201.3±59.3 2,029 2,116.4±25.6 2,363.0±104.6
[Bamboogle] 1,342 2.0±0.3 74.3±37.5 204.5±72.1 966 1,035.1±12.9 1,223.1±50.2
[Feverous] 3,741 2.9±0.9 118.2±36.4 197.1±69.2 2,826 2,956.8±38.1 3,276.8±123.1
Average 2,004.9 2.2±0.6 88.7±18.7 172.1±37.0 1,951.9 2,040.8±563.1 2,270.0±587.7

## Robustness to Choice of Prompt {#sec:appendix_prompts_sensitivity}

We empirically measure our method's sensitivity to the prompt of choice. To this end, we randomly sampled new exemplars for both our decomposition and meta-reasoning prompts for [StrategyQA] and [HotpotQA]. When using different random exemplars, we observe that MCR still outperforms all baselines. Even though decomposition performance (SA) is more affected by the set of exemplars, the performance trend remains the same, with MCR being on top. Tab. [\[tab:prompt_sensitivity\]](#tab:prompt_sensitivity) lists the experiment results, evaluated on 500 examples from each dataset. We also provide the original prompt results in parenthesis (averaged over 3 runs).

           Dataset            Examples              SA                        SC$@5$                        SCR                           MCR

---

[StrategyQA] 500 66.6 (69.3$\pm$0.3)   71.0 (72.2$\pm$0.8)   68.2 (70.0$\pm$0.6)   **72.0 (73.6$\pm$0.7)**        
    [HotpotQA]      500      54.3 (50.2$\pm$0.3)   56.2 (51.3$\pm$0.2)   57.1 (56.4$\pm$0.4)   **59.3 (57.0$\pm$0.8)\*\*

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given the following question, answer it by providing follow up questions and intermediate answers. If no follow up questions are necessary, answer the question directly. You are also provided with the most relevant google snippet for each intermediate question.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context1: Xawery Żuławski: Polish-Russian War (Wojna polsko-ruska) is a 2009 Polish film directed by Xawery Żuławski based on the novel Polish-Russian War under the white-red flag by Dorota Masłowska. So the answer is Xawery Żuławski.</td>
</tr>
<tr>
<td style="text-align: left;">Context2: Xawery Żuławski: Xawery Żuławski ; National Film School in Łódź · 1995–present · Maria Strzelecka · 2.</td>
</tr>
<tr>
<td style="text-align: left;">Question: Who is the mother of the director of film Polish-Russian War (Film)?</td>
</tr>
<tr>
<td style="text-align: left;">Are follow up questions needed here: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Who is the director of the film Polish-Russian War (Film)?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The director of the film Polish-Russian War is Xawery Żuławski.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Who is the mother of Xawery Żuławski?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The mother of Xawery Żuławski is Małgorzata Braunek.</td>
</tr>
<tr>
<td style="text-align: left;">So the final answer is: Rick Scott Małgorzata Braunek.</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context1: John, Count Palatine of Neumarkt: John (Johann von Pfalz-Neumarkt; 1383 – 14 March 1443) was the Count Palatine of Neumarkt from 1410 to his death. The son of Rupert III of the Palatinate, he married Catherine of Pomerania in 1407.</td>
</tr>
<tr>
<td style="text-align: left;">Context2: John, Count Palatine of Neumarkt: John (Johann von Pfalz-Neumarkt; 1383 – 14 March 1443) was the Count Palatine of Neumarkt from 1410 to his death. The son of Rupert III of the Palatinate, he married Catherine of Pomerania in 1407.</td>
</tr>
<tr>
<td style="text-align: left;">Question: Who is Catherine Of Pomerania, Countess Palatine Of Neumarkt’s father-in-law?</td>
</tr>
<tr>
<td style="text-align: left;">Are follow up questions needed here: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Who is the husband of Catherine of Pomerania, Countess Palatine of Neumarkt?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The husband of Catherine of Pomerania, Countess Palatine of Neumarkt is John, Count Palatine of Neumarkt.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Who is the father of John, Count Palatine of Neumarkt?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The father of John, Count Palatine of Neumarkt is Rupert III of the Palatinate.</td>
</tr>
<tr>
<td style="text-align: left;">So the final answer is: Rupert III of the Palatinate.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context1: Crimen a las tres: Crimen a las tres is a 1935 Argentine crime film directed and written by Luis Saslavsky. Crimen a las tres. Directed by, Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">Context2: Elio Petri: The Working Class Goes to Heaven (Italian: La classe operaia va in paradiso), released in the US as Lulu the Tool, is a 1971 political drama film directed by Elio Petri. So the answer is Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;">Context3: March 20, 1995: Luis Saslavsky (April 21, 1903 – March 20, 1995) was an Argentine film director, screenwriter and film producer, and one of the influential directors in the Cinema of Argentina of the classic era. So the answer is March 20, 1995.</td>
</tr>
<tr>
<td style="text-align: left;">Context4: Elio Petri: Final years. In 1981, Petri visited Geneva to direct Arthur Millerś new play The American Clock, with Marcello Mastroianni playing the lead role. Petri died of cancer on 10 November 1982. He was 53 years old.</td>
</tr>
<tr>
<td style="text-align: left;">Question: Which film has the director died first, Crimen A Las Tres or The Working Class Goes To Heaven?</td>
</tr>
<tr>
<td style="text-align: left;">Are follow up questions needed here: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Who is the director of Crimen a las tres?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The director of Crimen a las tres is Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Who is the director of The Working Class Goes to Heaven?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The director of The Working Class Goes to Heaven is Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: When did Luis Saslavsky die?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: Luis Saslavsky died on March 20, 1995.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: When did Elio Petri die?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: Elio Petri died on 10 November 1982.</td>
</tr>
<tr>
<td style="text-align: left;">So the final answer is: The Working Class Goes to Heaven.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
</tbody>
</table>
*Figure: Instruction and exemplars for the 2WikiMQA decomposition prompt.*

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given the following question, answer it by providing follow up questions and intermediate answers. For each follow up question, you are given a context which is the top returned google snippet for the question from Wikipedia. If no follow up questions are necessary, answer the question directly.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context1: Frost: Frost is a thin layer of ice on a solid surface, which forms from water vapor in an above-freezing atmosphere coming in contact with a solid surface whose ...</td>
</tr>
<tr>
<td style="text-align: left;">Context2: Graduation: Graduation is the awarding of a diploma to a student by an educational institution. It may also refer to the ceremony that is associated with it.</td>
</tr>
<tr>
<td style="text-align: left;">Context3: Winter: Winter ; Astronomical season, 22 December – 21 March ; Meteorological season, 1 December – 28/29 February ; Solar (Celtic) season, 1 November – 31 January.</td>
</tr>
<tr>
<td style="text-align: left;">Question: Is it common to see frost during some college commencements?</td>
</tr>
<tr>
<td style="text-align: left;">Are follow up questions needed here: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: What seasons can you expect to see frost?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: Frost is common during the winter.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: When is college commencement?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: College commencement ceremonies often happen during the months of December, May, June.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Do any of the months December, May, June occur during the Winter?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: December is in the winter.</td>
</tr>
<tr>
<td style="text-align: left;">So the final answer is: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context1: Last rites: The last rites, also known as the Commendation of the Dying, are the last prayers and ministrations given to an individual of Christian faith, when possible, shortly before death. They may be administered to those awaiting execution, mortally injured, or terminally ill.</td>
</tr>
<tr>
<td style="text-align: left;">Context2: Richard Dawkins: Dawkins is an outspoken atheist and a supporter of various atheist, secular, and humanist organisations, including Humanists UK and the Brights movement. Dawkins suggests that atheists should be proud, not apologetic, stressing that atheism is evidence of a healthy, independent mind.</td>
</tr>
<tr>
<td style="text-align: left;">Context3: Prayer in the Catholic Church: In the Catholic Church, prayer is "the raising of oneś mind and heart to God or the requesting of good things from God." It is an act of the moral virtue ...</td>
</tr>
<tr>
<td style="text-align: left;">Question: Would Richard Dawkins hypothetically refuse an offering of the Last rites?</td>
</tr>
<tr>
<td style="text-align: left;">Are follow up questions needed here: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: What are the last Rites?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The Last rites, in Catholicism, are the last prayers and ministrations given to an individual of the faith, when possible, shortly before death.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: What are Richard Dawkins religious beliefs?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: Richard Dawkins is known as an outspoken atheist, well known for his criticism of creationism and intelligent design.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Would an atheist participate in Catholics prayers?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: It is unlikely that an atheist would participate in Catholics prayers.</td>
</tr>
<tr>
<td style="text-align: left;">So the final answer is: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context1: number 1: Hydrogen is the chemical element with the symbol H and atomic number 1. Hydrogen is the lightest element. So the answer is number 1.</td>
</tr>
<tr>
<td style="text-align: left;">Context2: Spice Girls - Simple English Wikipedia, the free encyclopedia: The group has five members. Each member uses a nickname initially given to them: Melanie Chisholm ("Sporty Spice"), Emma Bunton ("Baby Spice"), Melanie Brown ("Scary Spice"), Victoria Beckham (née Adams) ("Posh Spice"), and Geri Halliwell ("Ginger Spice") .</td>
</tr>
<tr>
<td style="text-align: left;">Context3: Square number: In mathematics, a square number or perfect square is an integer that is the square of an integer; in other words, it is the product of some integer with ...</td>
</tr>
<tr>
<td style="text-align: left;">Question: Hydrogen’s atomic number squared exceeds number of Spice Girls?</td>
</tr>
<tr>
<td style="text-align: left;">Are follow up questions needed here: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: What is the atomic number of hydrogen?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: Hydrogen has an atomic number of 1.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: How many people are in the Spice Girls band?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The Spice Girls has 5 members.</td>
</tr>
<tr>
<td style="text-align: left;">Follow up: Is the square of 1 greater than 5?</td>
</tr>
<tr>
<td style="text-align: left;">Intermediate answer: The square of 1 is 1 which is less than 5.</td>
</tr>
<tr>
<td style="text-align: left;">So the final answer is: No.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
</tbody>
</table>
*Figure: Instruction and exemplars for the StrategyQA decomposition prompt.*

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given a question and a context, answer the question and explain why. If you are unsure, answer Unknown.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">Who is the wife of Douglas Leiterman? The wife of Douglas Leiterman is Beryl Fox.</td>
</tr>
<tr>
<td style="text-align: left;">Where was Beryl Fox born? Beryl Fox was born in Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">When and where was Mary born? Mary was born in c. 18 BC or September 8 (21), 16 BC Herodian Kingdom of Judea.</td>
</tr>
<tr>
<td style="text-align: left;">Where was Beryl Fox born? Beryl Fox was born in Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the wife of Douglas Leiterman? The wife of Douglas Leiterman is Mary.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the wife of Douglas Leiterman? The wife of Douglas Leiterman is Beryl Fox.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Where was the wife of Douglas Leiterman born?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">The wife of Douglas Leiterman is Beryl Fox. Beryl Fox was born in Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">Who is Beatrice of Aragon’s father? The father of Beatrice of Aragon is King Ferdinand I of Naples.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of Rupert III, Elector Palatine? The father of Rupert III, Elector Palatine is Rupert II, Elector Palatine.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the husband of Catherine of Pomerania? The husband of Catherine of Pomerania is John II, Count Palatine of Neumarkt.</td>
</tr>
<tr>
<td style="text-align: left;">Who is Catherine Of Pomerania, Countess Palatine Of Neumarkt’s husband? The husband of Catherine Of Pomerania, Countess Palatine Of Neumarkt is John I, Count Palatine of Neumarkt.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of John II, Count of Holstein-Rendsburg? The father of John II, Count of Holstein-Rendsburg is Henry II, Count of Holstein-Rendsburg.</td>
</tr>
<tr>
<td style="text-align: left;">Who is Catherine Of Pomerania, Countess Palatine Of Neumarkt’s husband? The husband of Catherine Of Pomerania, Countess Palatine Of Neumarkt is John II, Count of Holstein-Rendsburg.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of John I, Count Palatine of Neumarkt? The father of John I, Count Palatine of Neumarkt is Rupert III, Elector Palatine.</td>
</tr>
<tr>
<td style="text-align: left;">Who are the parents of Rupert III, Elector Palatine? The parents of Rupert III, Elector Palatine are Rupert II, Elector Palatine and Beatrice of Aragon.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the father of John II, Count Palatine of Neumarkt? The father of John II, Count Palatine of Neumarkt is Rupert III, Elector Palatine.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Who is Catherine Of Pomerania, Countess Palatine Of Neumarkt’s father-in-law?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">The husband of Catherine Of Pomerania, Countess Palatine Of Neumarkt is John I, Count Palatine of Neumarkt. The father of John I, Count Palatine of Neumarkt is Rupert III, Elector Palatine.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: Rupert III, Elector Palatine.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">When did Elio Petri die? Elio Petri died on 10 November 1982.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of The Working Class Goes to Heaven? The director of The Working Class Goes to Heaven is Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of Crimen A Las Tres? The director of Crimen A Las Tres is Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of Crimen A Las Tres? The director of Crimen A Las Tres is Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">When did Luis Saslavsky die? Luis Saslavsky died on March 20, 1995.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of Crimen A Las Tres? The director of Crimen A Las Tres is Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">When did Elio Petri die? Elio Petri died on 10 November 1982.</td>
</tr>
<tr>
<td style="text-align: left;">When did Luis Saslavsky die? Luis Saslavsky died on March 20, 1995.</td>
</tr>
<tr>
<td style="text-align: left;">When did Luis Saslavsky die? Luis Saslavsky died on March 20, 1995.</td>
</tr>
<tr>
<td style="text-align: left;">When did Elio Petri die? Elio Petri died on 10 November 1982.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of The Working Class Goes to Heaven? The director of The Working Class Goes to Heaven is Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of The Working Class Goes to Heaven? The director of The Working Class Goes to Heaven is Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Which film has the director died first, Crimen A Las Tres or The Working Class Goes To Heaven?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">The director of Crimen A Las Tres is Luis Saslavsky. The director of The Working Class Goes to Heaven is Elio Petri. Luis Saslavsky died on March 20, 1995. Elio Petri died on 10 November 1982.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: The Working Class Goes To Heaven.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
</tbody>
</table>
*Figure: Instruction and exemplars for the 2WikiMQA meta-reasoner prompt.*

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given a question and a context, provide a Yes or No answer and explain why. If you are unsure, answer Unknown.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">What type of animal is a jellyfish? A jellyfish is a type of invertebrate.</td>
</tr>
<tr>
<td style="text-align: left;">Do jellyfish have arteries? No, jellyfish do not have arteries. They have a type of nervous system called a nerve net.</td>
</tr>
<tr>
<td style="text-align: left;">What is atherosclerosis? Atherosclerosis is a disease where plaque builds up in the arteries.</td>
</tr>
<tr>
<td style="text-align: left;">Do jellyfish have arteries? Jellyfish do not have a circulatory system and therefore do not have arteries.</td>
</tr>
<tr>
<td style="text-align: left;">So jellyfish don’t have atherosclerosis because they don’t have arteries? Yes, that is correct.</td>
</tr>
<tr>
<td style="text-align: left;">What is atherosclerosis? Atherosclerosis is a type of heart disease.</td>
</tr>
<tr>
<td style="text-align: left;">Is an invertebrate susceptible to atherosclerosis? No, invertebrates are not susceptible to atherosclerosis.</td>
</tr>
<tr>
<td style="text-align: left;">What is atherosclerosis? Atherosclerosis is a disease in which plaque builds up on the walls of the arteries.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Is a jellyfish safe from atherosclerosis?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">Jellyfish do not have a circulatory system and therefore do not have arteries. Atherosclerosis is a disease in which plaque builds up on the walls of the arteries.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">What is tonsure? Tonsure is the practice of cutting or shaving the hair from the scalp, as a sign of religious devotion or humility.</td>
</tr>
<tr>
<td style="text-align: left;">What is Christopher Hitchens’ religious affiliation? Christopher Hitchens was an atheist.</td>
</tr>
<tr>
<td style="text-align: left;">What is tonsure? Tonsure is a practice of cutting or shaving the hair from the scalp.</td>
</tr>
<tr>
<td style="text-align: left;">Would Christopher Hitchens be likely to do something as a sign of religious devotion? No.</td>
</tr>
<tr>
<td style="text-align: left;">Would Christopher Hitchens be religious? Christopher Hitchens was an atheist.</td>
</tr>
<tr>
<td style="text-align: left;">Is an atheist likely to engage in religious practices? No, an atheist is not likely to engage in religious practices.</td>
</tr>
<tr>
<td style="text-align: left;">What is tonsure? Tonsure is the practice of cutting or shaving the hair from the scalp, as a sign of religious devotion or humility.</td>
</tr>
<tr>
<td style="text-align: left;">What is Christopher Hitchens’ religious affiliation? Christopher Hitchens was an atheist.</td>
</tr>
<tr>
<td style="text-align: left;">Do atheists usually engage in tonsure? No, atheists do not usually engage in tonsure as it is a religious practice.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Would Christopher Hitchens be very unlikely to engage in tonsure?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">Tonsure is the practice of cutting or shaving the hair from the scalp, as a sign of religious devotion or humility. Christopher Hitchens was an atheist. An atheist is not likely to engage in religious practices.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">What is the evidence that Neanderthals used arithmetic? There is no direct evidence that Neanderthals used arithmetic, but indirect evidence suggests that they may have had some understanding of basic mathematical concepts.</td>
</tr>
<tr>
<td style="text-align: left;">What is the earliest evidence of arithmetic? The earliest evidence of arithmetic dates back to the ancient Sumerians, who lived in what is now modern-day Iraq.</td>
</tr>
<tr>
<td style="text-align: left;">Did Neanderthals live before the ancient Sumerians? Yes.</td>
</tr>
<tr>
<td style="text-align: left;">What is arithmetic? Arithmetic is the branch of mathematics that deals with the properties and manipulation of numbers.</td>
</tr>
<tr>
<td style="text-align: left;">Is there any reason to believe that Neanderthals could not have used arithmetic? There is no reason to believe that Neanderthals could not have used arithmetic.</td>
</tr>
<tr>
<td style="text-align: left;">Do we have any evidence that Neanderthals could manipulate numbers? We have no evidence that Neanderthals could manipulate numbers.</td>
</tr>
<tr>
<td style="text-align: left;">What is arithmetic? Arithmetic is the branch of mathematics that deals with the properties and manipulation of numbers.</td>
</tr>
<tr>
<td style="text-align: left;">What is arithmetic? Arithmetic is the branch of mathematics that deals with the addition, subtraction, multiplication, and division of whole numbers and with the manipulation of fractions and decimals.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Did Neanderthals use arithmetic?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">There is no evidence that Neanderthals used arithmetic. The earliest evidence of arithmetic dates back to the ancient Sumerians who lived after the Neanderthals.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: No.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
</tbody>
</table>
*Figure: Instruction and exemplars for the StrategyQA meta-reasoner prompt.*

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given a question and a context, answer the question and explain why. If you are unsure, answer Unknown.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">Who is the wife of Douglas Leiterman? | Douglas Leiterman (1927 – 19 December 2012) was a Canadian television producer.: [[D́ouglas Leiterman]́, [Śpouse,́ B́eryl Fox]́]</td>
</tr>
<tr>
<td style="text-align: left;">Where was Beryl Fox born? | Winnipeg, Manitoba: Fox was born in 1931 in Winnipeg, Manitoba. So the answer is Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">Who is Douglas Leiterman’s wife? | Douglas Leiterman (1927 – 19 December 2012) was a Canadian television producer.: [[D́ouglas Leiterman]́, [Ḱnown for,́ T́his Hour Has Seven Days]́, [Śpouse,́ B́eryl Fox]́]</td>
</tr>
<tr>
<td style="text-align: left;">Where was Beryl Fox born? | Winnipeg, Manitoba: Fox was born in 1931 in Winnipeg, Manitoba. So the answer is Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the wife of Douglas Leiterman? | Douglas Leiterman (1927 – 19 December 2012) was a Canadian television producer.: [[D́ouglas Leiterman]́, [Śpouse,́ B́eryl Fox]́]</td>
</tr>
<tr>
<td style="text-align: left;">When and where was Mary born? | Mary was born in c. 18 BC or September 8 (21), 16 BC Herodian Kingdom of Judea.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Where was the wife of Douglas Leiterman born?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">The wife of Douglas Leiterman is Beryl Fox. Beryl Fox was born in Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: Winnipeg, Manitoba.</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of Crimen A Las Tres? | Crimen a las tres: Crimen a las tres is a 1935 Argentine crime film directed and written by Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of The Working Class Goes to Heaven? | The Working Class Goes to Heaven: The Working Class Goes to Heaven (Italian: La classe operaia va in paradiso), released in the US as Lulu the Tool, is a 1971 political drama film directed by Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;">When did Luis Saslavsky die? | Luis Saslavsky: Luis Saslavsky (April 21, 1903 – March 20, 1995) was an Argentine film director, screenwriter and film producer, and one of the influential directors in the Cinema of Argentina of the classic era.</td>
</tr>
<tr>
<td style="text-align: left;">When did Elio Petri die? | Elio Petri: Petri died of cancer on 10 November 1982. He was 53 years old.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of Crimen A Las Tres? | Crimen a las tres: Crimen a las tres is a 1935 Argentine crime film directed and written by Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of The Working Class Goes to Heaven? | The Working Class Goes to Heaven: The Working Class Goes to Heaven (Italian: La classe operaia va in paradiso), released in the US as Lulu the Tool, is a 1971 political drama film directed by Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;">When did Luis Saslavsky die? | Luis Saslavsky: Luis Saslavsky (April 21, 1903 – March 20, 1995) was an Argentine film director, screenwriter and film producer, and one of the influential directors in the Cinema of Argentina of the classic era.</td>
</tr>
<tr>
<td style="text-align: left;">When did Elio Petri die? | Elio Petri: Petri died of cancer on 10 November 1982. He was 53 years old.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of Crimen A Las Tres? | Crimen a las tres: Crimen a las tres is a 1935 Argentine crime film directed and written by Luis Saslavsky.</td>
</tr>
<tr>
<td style="text-align: left;">When did Luis Saslavsky die? | Luis Saslavsky: Luis Saslavsky (April 21, 1903 – March 20, 1995) was an Argentine film director, screenwriter and film producer, and one of the influential directors in the Cinema of Argentina of the classic era.</td>
</tr>
<tr>
<td style="text-align: left;">Who is the director of The Working Class Goes to Heaven? | The Working Class Goes to Heaven: The Working Class Goes to Heaven (Italian: La classe operaia va in paradiso), released in the US as Lulu the Tool, is a 1971 political drama film directed by Elio Petri.</td>
</tr>
<tr>
<td style="text-align: left;">When did Elio Petri die? | Elio Petri: Petri died of cancer on 10 November 1982. He was 53 years old.</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Which film has the director died first, Crimen A Las Tres or The Working Class Goes To Heaven?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">The director of Crimen A Las Tres is Luis Saslavsky. The director of The Working Class Goes to Heaven is Elio Petri. Luis Saslavsky died on March 20, 1995. Elio Petri died on 10 November 1982.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: The Working Class Goes To Heaven.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
</tbody>
</table>
*Figure: Instruction and exemplars for the 2WikiMQA meta-reasoner prompt for MCR-Ev and SCR-Ev reasoning over retrieved evidence.*

<table style="width:97%;">
<colgroup>
<col style="width: 97%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong><em>Given a question and a context, answer the question step-by-step. If you are unsure, answer Unknown.</em></strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">What is atherosclerosis? | Atherosclerosis: Atherosclerosis is a pattern of the disease arteriosclerosis in which the wall of the artery develops abnormalities, called lesions. These lesions may lead to narrowing due to the buildup of atheromatous plaque. At onset there are usually no symptoms, but if they develop, symptoms generally begin around middle age.</td>
</tr>
<tr>
<td style="text-align: left;">What type of animal is a jellyfish? | Jellyfish - Simple English Wikipedia, the free encyclopedia: Jellyfish are animals of the phylum Cnidaria. They are a monophyletic clade, the Medusozoa. Most of them live in the oceans, in salt water, where they eat small sea animals like plankton and little fish, and float in the sea.</td>
</tr>
<tr>
<td style="text-align: left;">Is an invertebrate susceptible to atherosclerosis? | Atherosclerosis: Atherosclerosis is a pattern of the disease arteriosclerosis in which the wall of the artery develops abnormalities, called lesions.</td>
</tr>
<tr>
<td style="text-align: left;">What is atherosclerosis? | Atherosclerosis: Atherosclerosis is a pattern of the disease arteriosclerosis in which the wall of the artery develops abnormalities, called lesions. These lesions may lead to narrowing due to the buildup of atheromatous plaque. At onset there are usually no symptoms, but if they develop, symptoms generally begin around middle age.</td>
</tr>
<tr>
<td style="text-align: left;">Do jellyfish have arteries? | Jellyfish: Jellyfish are mainly free-swimming marine animals with umbrella-shaped bells and trailing tentacles, although a few are anchored to the seabed by stalks rather</td>
</tr>
<tr>
<td style="text-align: left;">What is atherosclerosis? | Atherosclerosis: Atherosclerosis is a pattern of the disease arteriosclerosis in which the wall of the artery develops abnormalities, called lesions. These lesions may lead to narrowing due to the buildup of atheromatous plaque. At onset there are usually no symptoms, but if they develop, symptoms generally begin around middle age.</td>
</tr>
<tr>
<td style="text-align: left;">Do jellyfish have arteries? | Jellyfish: Jellyfish are mainly free-swimming marine animals with umbrella-shaped bells and trailing tentacles, although a few are anchored to the seabed by stalks rather</td>
</tr>
<tr>
<td style="text-align: left;">So jellyfish don’t have atherosclerosis because they don’t have arteries? | Jellyfish: A free-swimming marine coelenterate that is the sexually reproducing form of a hydrozoan or scyphozoan and has a nearly transparent saucer-shaped body and</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Is a jellyfish safe from atherosclerosis?</td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">Jellyfish do not have a circulatory system and therefore do not have arteries. Atherosclerosis is a disease in which plaque builds up on the walls of the arteries.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: Yes.</td>
</tr>
<tr>
<td style="text-align: left;">...</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
<tr>
<td style="text-align: left;">Context:</td>
</tr>
<tr>
<td style="text-align: left;">What is arithmetic? | Arithmetic: Arithmetic is an elementary part of mathematics that consists of the study of the properties of the traditional operations on numbers—addition, subtraction, multiplication, division, exponentiation, and extraction of roots.</td>
</tr>
<tr>
<td style="text-align: left;">What is the evidence that Neanderthals used arithmetic? | Neanderthal: In 2012, British-American geneticist Graham Coop hypothesised that they instead found evidence of a different archaic human species interbreeding with modern</td>
</tr>
<tr>
<td style="text-align: left;">Is there any reason to believe that Neanderthals could not have used arithmetic? | Neanderthal: A large part of the controversy stems from the vagueness of the term "species", as it is generally used to distinguish two genetically isolated populations, but</td>
</tr>
<tr>
<td style="text-align: left;">What is arithmetic? | Arithmetic: Arithmetic is an elementary part of mathematics that consists of the study of the properties of the traditional operations on numbers—addition, subtraction, multiplication, division, exponentiation, and extraction of roots.</td>
</tr>
<tr>
<td style="text-align: left;">Do we have any evidence that Neanderthals could manipulate numbers? | Neanderthal: Neanderthals also written as Neandertals, are an extinct species or subspecies of archaic humans who lived in Eurasia until about 40,000 years ago.</td>
</tr>
<tr>
<td style="text-align: left;">What is arithmetic? | Neanderthal: Neanderthals also written as Neandertals, are an extinct species or subspecies of archaic humans who lived in Eurasia until about 40,000 years ago.</td>
</tr>
<tr>
<td style="text-align: left;">What is the earliest evidence of arithmetic? | Mathematics: It is in Babylonian mathematics that elementary arithmetic (addition, subtraction, multiplication, and division) first appear in the archaeological record. The Babylonians also possessed a place-value system and used a sexagesimal numeral system which is still in use today for measuring angles and time.</td>
</tr>
<tr>
<td style="text-align: left;">Did Neanderthals live before the ancient Babylonians? | Neanderthal: Neanderthals also written as Neandertals, are an extinct species or subspecies of archaic humans who lived in Eurasia until about 40,000 years ago. Pre- and early Neanderthals, living before the Eemian interglacial</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Question:</td>
</tr>
<tr>
<td style="text-align: left;">Did Neanderthals use arithmetic?</td>
</tr>
<tr>
<td style="text-align: left;"></td>
</tr>
<tr>
<td style="text-align: left;">Answer:</td>
</tr>
<tr>
<td style="text-align: left;">There is no evidence that Neanderthals used arithmetic. The earliest evidence of arithmetic dates back to the ancient Babylonians who lived after the Neanderthals.</td>
</tr>
<tr>
<td style="text-align: left;">So the answer is: No.</td>
</tr>
<tr>
<td style="text-align: left;">#</td>
</tr>
</tbody>
</table>
*Figure: Instruction and exemplars for the StrategyQA prompt for MCR-Ev and SCR-Ev reasoning over retrieved evidence.*

[^1]: <https://github.com/oriyor/reasoning-on-cots>

[^2]: We use the entire development set for [Quartz] and [Bamboogle], since they include less than 500 examples. For [Fermi] we use all 286 "Real Fermi Problems" in its train and development sets. Exact numbers are listed in Tab. [\[tab:dev_set_results\]](#tab:dev_set_results).

[^3]: Like @wang2023selfconsistency, we observe that greedy-decoded chains have higher accuracy compared to the other chains.

[^4]: <https://serpapi.com/>

[^5]: `code-davinci-002` context is capped at 8,001 tokens.

[^6]: <https://leaderboard.allenai.org/strategyqa>

[^7]: https://serpapi.com/organic-results
