# Abstract

Chain-of-thought (CoT) via prompting is the de facto method for eliciting reasoning capabilities from large language models (LLMs). But for what kinds of tasks is this extra "thinking" really helpful? To analyze this, we conducted a quantitative meta-analysis covering over 100 papers using CoT and ran our own evaluations of 20 datasets across 14 models. Our results show that CoT gives strong performance benefits primarily on tasks involving math or logic, with much smaller gains on other types of tasks. On MMLU, directly generating the answer without CoT leads to almost identical accuracy as CoT *unless* the question or model's response contains an equals sign, indicating symbolic operations and reasoning. Following this finding, we analyze the behavior of CoT on these problems by separating planning and execution and comparing against tool-augmented LLMs. Much of CoT's gain comes from improving symbolic execution, but it underperforms relative to using a symbolic solver. Our results indicate that CoT can be applied selectively, maintaining performance while saving inference costs. Furthermore, they suggest a need to move beyond prompt-based CoT to new paradigms that better leverage intermediate computation across the whole range of LLM applications [^1] .

\[Figure omitted\]

# Introduction

Chain-of-thought (CoT) [scratchpads; @cot] has become a widely used prompting technique for eliciting reasoning from language models. CoT can provide human-readable explanations of how problems are solved [yejin_machines_rationales; @measuring_faithfulness], but most frequently it is invoked to improve an LLM's ability to answer complex questions via intermediate computation [two2tango; @toward_understanding_cot; @faithandfate]. Current post-training schemes for LLMs heavily infuse CoT capabilities into models: systems like ChatGPT or Llama 3.1 default to CoT when given reasoning problems [gpt4; @llama3_1].

CoT has seen widespread usage, but it is most heavily explored in the domain of mathematical reasoning [zhou2023leasttomost; @fu2023complexitybased; @llms_as_compilers; @xu2024rereading; @rstar]. In fact, many "reasoning" methods for LLMs are evaluated *only* in the math domain; for instance, @verifystepbystep frame their paper as "complex multi-step reasoning" and Mixtral-Large2's release [^2] cited effort "enhancing the model's reasoning capabilities", but performance is only reported on GSM8K and MATH. CoT is reported to be effective across a wide range of studies, but many of these studies focus on a narrow slice of the task space. In areas beyond math, results show that CoT is not as useful [llms_cant_plan] or can even hurt performance [wang2024mmlupro].

In this work, we aim to evaluate where prompt-based CoT helps and why. We begin with a systematic meta-analysis of recent literature that reports performance of CoT versus direct answering (DA). We then augment this picture by conducting experiments on 20 datasets and 14 contemporary LLMs across zero-shot and few-shot prompt settings. **Finding 1: CoT only helps substantially on problems requiring mathematical, logical, or algorithmic reasoning.** Figure [\[fig:fig1\]](#fig:fig1) shows this holds both across the literature and our own experiments. We find only a few cases of large gain in other kinds of tasks, and many of these outliers feature some component of symbolic reasoning. For instance, on MMLU [mmlu] and MMLU Pro [wang2024mmlupro], we analyze the improvements from CoT and find that CoT *only* gives benefit on math slices of the dataset. **As much as 95% of the total performance gain from CoT on MMLU is attributed to questions containing "=" in the question or generated output.** For non-math questions, we find no features to indicate when CoT will help.

How can we better understand *why* CoT improves on these questions and only these questions? The math and formal logical reasoning datasets we consider can be broken down into two stages of processing: a planning step (e.g., parsing a problem into equations) and an execution step (building intermediate outputs and working towards a solution) [satlm; @Wang2023PlanandSolvePI; @sun-etal-2024-pearl]. **Finding 2: CoT primarily helps with the execution step that performs computation and symbolic manipulation, but falls short of what LLMs with tool augmentation can do.** We find that LMs prompted with CoT can generate executable formal solution plans and execute those plans better than direct answering. But using LMs to generate a solution plan and then using an external symbolic solver to solve the plan outperforms using CoT for both steps for these tasks.

These results paint a picture that CoT's utility is often circumscribed by tool augmentation: on problems where CoT helps, we already have more powerful tools than CoT that we can employ, and on "soft reasoning" problems like commonsense where no tools exist, we see limited benefit from CoT. This characterization has two major implications. First, CoT is unnecessary for many problems where it is widely employed: there exist more efficient prompting strategies that yield similar performance for much lower inference cost. Second, we see a critical need to move beyond prompt-based CoT to more sophisticated approaches based on search, interacting agents, or models more heavily fine-tuned for CoT. Future work can explore how intermediate computation can be better used to solve challenging problems outside of the math and symbolic reasoning domains.

# Background: Chain-of-thought

The tasks we consider in this work consist of a question $\mathbf{q} \in \Sigma^*$ for a vocabulary $\Sigma$ and an answer $a \in \mathcal{L}(\mathbf{q})$ for a label set $\mathcal{L}(\mathbf{q})$. $\mathcal{L}(\mathbf{q})$ can consist of a data type like boolean or integer, classification labels, or problem-dependent labels like names of entities from $\mathbf{q}$. One exception that we still explore is BiGGen Bench [kim2024biggen], which instead relies on an LLM-as-a-judge [dubois2023alpacafarm; @llmasjudge_mtbench] to provide a label for generated long-form responses.

#### Prompting and chain-of-thought for reasoning

A large language model places distributions over strings $p(\mathbf{y}) = \prod_{i=1}^n p_\mathrm{LM}(y_i)$ where $\mathbf{y} \in \Sigma^*$. In practice, we can interpret these as conditional distributions $p(\mathbf{y} \mid \mathbf{x})$ where $\mathbf{x}$ is a user's prompt. Typical invocation of an LLM involves forming a prompt $\mathcal{I}(\mathbf{q})$ that wraps the question with additional instruction, then drawing a sample response $\tilde{\mathbf{y}} \sim p(\mathbf{y} \mid \mathcal{I}(\mathbf{q}))$, and finally returning $a = \mathrm{extract}(\tilde{\mathbf{y}})$ using some kind of answer extractor.

For the tasks we consider in this work, the output $\tilde{\mathbf{y}}$ can take one of two forms. A **direct answer** only contains a string realization of $a$; e.g., $\mathbf{y} = (\mathrm{\_185}, \mathrm{4})$ which is detokenized as the answer $a=1854$. A **chain of thought** is a longer sequence $\mathbf{y}$ including other tokens beyond the answer, e.g., $\mathbf{y} = (\mathrm{\_185}, \mathrm{6}, \mathrm{\_minus}, \mathrm{\_2}, \mathrm{\_equals}, \mathrm{\_185}, \mathrm{4})$. In both cases, the $\mathrm{extract}$ function must parse and detokenize the output; in CoT, there is some extra work to spot where the answer is placed.

Our prompts can explicitly encourage use of direct answer or chain of thought as strategies, which we denote as $\mathcal{I}_\mathrm{da}$ and $\mathcal{I}_\mathrm{cot}$. For eliciting CoT, this includes strategies like telling a model to "*think step by step*" [kojima]. For directly answering a question, a prompt may say "*immediately generate the answer*". We track the average location of the answer in the generated output for both CoT and direct prompts in Appendix [13.3](#sec:ans_ext_and_avg_span_appendix) to ensure that direct answer prompts give the answer early in the output. We also ensure that $\mathrm{extract}$ can parse answers from the generated output for each model, prompt, and dataset combination used in our experiments, tailoring the $\mathrm{extract}$ function as needed to ensure low unparseable rates for each model and task.[^3] All prompts and outputs per dataset per model have been uploaded to Huggingface and we include examples of some of our prompts in the Appendix [17](#sec:example_prompts_and_response). We also experiment with few-shot CoT prompts, which we find perform similarly to zero-shot prompts; details about these are given in Appendix [12](#sec:few_shot_results).

#### Symbolic reasoning

Of key importance to this work is whether problems feature symbolic reasoning or not. We consider a problem to be **symbolic** if it can be grounded in a *natural, well agreed-upon* formal system. "$12 \times 4$" is an example of a symbolic problem, which can be grounded in mathematics. Other systems include first-order logic [PrOntoQA; @contexthub_ref] or planning languages [Liu2023LLMPEL; @rao_valmeekam2023on]. Formally, for symbolic problems, we define a function $f$ that acts as a map that produces some symbolic expression $\mathcal{S} = f(\mathbf{q})$ from the question. $\mathcal{S}$ can be used as input for a solver to derive an answer, $\hat{a} = \mathrm{solve}(\mathcal{S})$.

Conversely, a problem like *where on a river can you hold a cup upright to catch water on a sunny day?* from CommonsenseQA [commonsenseqa] is **non-symbolic** by our definition. While this problem could be formalized with some kind of predicate logic [zhou-etal-2022-learning-decompose; @quan-etal-2024-enhancing; @Zhou2024ConceptualAU] or grounded in some kind of physical simulation [hao-etal-2023-reasoning; @Wong2023FromWM], there is not a natural nor well agreed-upon framework for solving it.

We view non-symbolic to symbolic reasoning as a spectrum. MuSR [sprague2024musr] is a "semisymbolic" dataset in that it does contain an underlying formal system (e.g., for its murder mysteries portion, the notion that $\mathrm{motive}(X) \wedge \mathrm{means}(X) \wedge \mathrm{opportunity}(X) \implies \mathrm{murderer}(X)$), but also involves substantial commonsense reasoning that does not map onto a formal system. In these cases, we can still form $\mathcal{S} = f(\mathbf{q})$, but $f$ must rely heavily on a language model and instantiate new information for $\mathcal{S}$ that is not directly represented in $\mathbf{q}$.

#### Central claim

Figure [\[fig:fig1\]](#fig:fig1) shows that there are a large number of positive results on CoT reported in the literature. Informally, we believe many readers of the literature to hold the following view: ***$\mathcal{I}_\mathrm{cot}$ will outperform $\mathcal{I}_\mathrm{da}$ on nearly all reasoning problems, whether those problems involve symbolic or non-symbolic reasoning.*** Our evidence does *not* support this conjecture. We will show that this performance boost is strongest for symbolic and semi-symbolic tasks, while giving little to no improvement (or even hurting performance) on non-symbolic tasks.

# Results from the Literature

#### Criteria and Process

We investigate all papers from ICLR 2024, a representative ML venue, and two representative NLP venues, EACL 2024 and NAACL 2024 (including Findings and Workshop papers). This resulted in 4,642 papers total that filtered using automatic and manual methods to papers including experiments comparing chain-of-thought, $\mathcal{I}_{\mathrm{cot}}$, against direct answering prompts, $\mathcal{I}_{\mathrm{direct}}$. A total of 110 papers were found that matched our criteria with 1,218 experimental comparisons. We then grouped the comparisons by the types of tasks and datasets being evaluated. More details on our automatic and manual filtering, as well as our categorization, can be found in Appendix [8](#sec:meta_analysis_details) and [9](#sec:meta_analysis_apendix).

\[Table omitted\]

\[Figure omitted\]

#### Results

Figure [\[fig:lit_analysis_fig\]](#fig:lit_analysis_fig) shows the distribution of CoT deltas (CoT prompt minus the direct answer prompt performance) across our categorization of different task types found in the literature. Compared to Figure [\[fig:fig1\]](#fig:fig1), we take the mean results per paper per category, indicated by blue dots, showing the trend across papers in the literature. The categories are ranked in order of ascending median CoT delta. The three categories which benefited the most from CoT are symbolic reasoning, math, and logical reasoning, with average improvements of 14.2, 12.3, 6.9, respectively. Average performance on these top three tasks with CoT was 56.9, whereas performance without CoT was 45.5. For other categories, the average performance with CoT was 56.8, compared to 56.1 without CoT. We do not consider this small improvement a victory for CoT. CoT involves more computation than direct answering, and a truly fair comparison between the methods should match the compute of the two methods, e.g., ensembling across multiple prompts.

#### Do any non-math datasets benefit from CoT?

On the right side of Figure [\[fig:lit_analysis_fig\]](#fig:lit_analysis_fig), we show the top 10 outliers from our observed trend, namely papers with high CoT deltas averaged across experiments in tasks *other than* math, symbolic, or logical reasoning. Although not categorized as math or logic, several of these are related to logical, mathematical or symbolic reasoning in some way. From this list, the dataset which benefits the most most from CoT is BIG-bench Hard (BBH) [bbh1], a benchmark consisting largely of problems requiring algorithmic, arithmetic or logical reasoning. For instance, BIG-bench Navigate is a spatial reasoning task, but relies heavily on a mathematical primitive of counting steps taken to derive a final conclusion. Similarly, while BIG-bench Temporal is a temporal reasoning task (answering questions about when certain events could have occurred), it requires deductive reasoning to solve. In addition, Legal Argument Reasoning (SemEval-2024 Task 5) [bongard-etal-2022-legal] was categorized as *context-aware QA*, but also requires substantial reasoning ability. Finally, MMLU-Moral Scenarios [mmlu] requires answering two independent questions at once, which essentially involves a symbolic combination of two simpler questions.

There are a few outliers that less clearly follow the trend. ScienceQA [lu2024learn] consists of multiple choice questions across a range of natural and social science disciplines, though it is hard to interpret gains without knowing breaking down performance by subject or question type. The dialogue evaluation dataset from @jia-etal-2024-leveraging sees large improvements with CoT, but this is a proprietary dataset, and we note that other essay scoring results in our meta-analysis [li-etal-2024-using; @stahl-etal-2024-exploring] did not show improvements with CoT. Other non-math, symbolic or logical datasets that benefit from CoT are Commitment Bank [de2019commitmentbank] and the task of eliciting verbalized confidence [xiong2025llms-express]. Nevertheless, these are exceptions to the rule. The majority of the reported benefits from using CoT in the NLP and ML literature comes from math or math-related tasks.

# Results from Experiments

## Experimental Setup

#### Dataset, Models, Prompts

All datasets, models, and prompts we evaluate over can be found in detail in the tables [\[tab:all_datasets_and_models_and_prompts\]](#tab:all_datasets_and_models_and_prompts), [\[tab:dataset_table\]](#tab:dataset_table), and [\[tab:models_table\]](#tab:models_table) of Appendix [10](#sec:expanded_exp_details__apendix). We restricted our experiments to English models commonly used and benchmarked on general reasoning datasets. Our datasets include those which are widely used in CoT and reasoning literature, including a mix of non-symbolic, semisymbolic, and symbolic reasoning. They span different formats, including multiple-choice, short-answer, and free-response; however, most of these datasets are multiple choice or short answer, as CoT is not typically used in long-form response settings. We also categorize each dataset into a larger category of reasoning required to solve it: Commonsense, Knowledge, Symbolic, Mathematical, and Soft Reasoning. We define Soft Reasoning as questions relying on commonsense and natural language but going beyond simple inferences about these statements. Finally, we explore several prompting strategies for eliciting reasoning from language models, as past work has emphasized the importance of the prompt [tdb_opt_paper]. However, we generally found slight performance differences; see Appendix [11](#sec:other_cot_prompt_variants_appendix) for details. We therefore focus on prompts similar to @kojima and @cot for zero-shot and few-shot settings, respectively, with alterations to improve the model's ability to produce desired behavior (i.e., formats that allow for easily parsed answers). We upload all our prompts and outputs for each model for each prompting strategy on Huggingface.[^4].

#### Implementation Details

We use a high-throughput inference package, vLLM [vllm], for the model inference process. We use greedy decoding on all models. Our prompts are taken from the Llama 3.1 evaluations when available [llama3_1], and minor adjustments are made to unify prompting strategies. For other datasets, we either use the standard prompt for the dataset from the corresponding original paper or implement our own prompt. Our answer parser ($\mathrm{extract}$) is tailored to each dataset and model. Specific details about each dataset, its prompts, and answer extractor can be found in Appendix [10](#sec:expanded_exp_details__apendix).

\[Figure omitted\]

\[Figure omitted\]

## Results

#### Where does zero-shot CoT improve over direct prompts?

*On datasets that require math (MATH, GSM8K) or formal logic (ContextHub, MuSR to a lesser degree) to answer the problem.*

Figure [\[fig:our_experiments\]](#fig:our_experiments) on the left shows the average CoT performance improvement for each reasoning category from Figure [\[fig:fig1\]](#fig:fig1) (right); raw numbers can be found in Table [\[tab:reasoning_category_performance_table\]](#tab:reasoning_category_performance_table) of the Appendix. On the right, Figure [\[fig:our_experiments\]](#fig:our_experiments) shows the performance gain from using CoT for each dataset, averaged across all models and for a selection of individual models. On non-symbolic reasoning categories and datasets, specifically those that contain questions primarily involving commonsense (CSQA, PIQA, SiQA), language understanding (WinoGrande), and reading comprehension (AGI LSAT, ARC-Easy, ARC-Challenge), there is little to no separation between the performance of zero-shot CoT and zero-shot direct answer. Despite these datasets involving reasoning, CoT does not yield improvement.

By contrast, the mathematical and symbolic categories get larger boosts in improvements alongside symbolic and many semi-symbolic datasets. MATH and GSM8K show gains as large as 41.6% and 66.9%, respectively. The semi-symbolic datasets like ContextHub and MuSR Murder Mysteries show moderate gains. These datasets require the application of logical rules to reach the answer, e.g., first-order logic parsed from simple natural language (ContextHub) or more complex commonsense statements (MuSR Murder Mysteries). All results are shown in the Appendix [13.1](#sec:full_zs_results_appendix) as well as a full list of numeric results for both CoT and direct answer prompting in Table [\[tab:raw_exp_0_zs_results\]](#tab:raw_exp_0_zs_results). We also explored the few-shot setting and found it had little impact on when CoT will help; see Appendix [12](#sec:few_shot_results).

\[Figure omitted\]

#### Does the answer format impact where CoT will help?

*Not much. Free response capabilities required for BigGen Bench may not benefit from pre-planning.*

Many of the commonly-used datasets for problems other than math are multiple choice. We highlight here that CoT has similar performance to direct answer across models for two datasets that are not multiple-choice and contain varying levels of non-symbolic reasoning. First, MuSiQue [trivedi2021musique] is a short-form QA task requiring multi-hop reasoning. We consider this a semi-symbolic dataset as the questions have an explicit multi-hop structure. Because answer spans in MuSiQue can be paraphrased in many different ways, we use GPT-4o to judge if two answer spans are equivalent. Despite being semi-symbolic, we see no overall improvement from CoT.

Second, BiGGen Bench [kim2024biggen] uses free-form responses as the answer to a question, and an LLM-as-a-judge is used to evaluate these responses on a scale of 1 to 5. Because free-form responses blur the lines between CoT and direct answering, we create a new prompt that asks the language model to plan the free response before giving it. We then only pass the free response to the judge (GPT-4o-mini in our case) with the prompt from @kim2024biggen. We also filter out any questions that explicitly state "Think step-by-step". We plot the performance of BiGGen Bench as the number of times a response receives a score of 4 or better. Despite including many reasoning questions (including several categories of math) and other categories, such as planning, we only see a mild improvement here. Because previous experiments show CoT helping on similar types of questions in the QA format, the lack of similar improvements here could imply that pre-planning is insufficient for unlocking reasoning capabilities in the LLM. Future work is needed to prove this.

#### Are the gains in Knowledge, Soft Reasoning, and Commonsense significant?

*Mostly no, except for MMLU, StrategyQA, and MuSR.*

We tested the significance of the improvements from CoT on the 13 datasets in the Knowledge, Soft Reasoning, and Commonsense reasoning categories using paired bootstrapping to assess whether CoT gives a significant improvement. To account for multiple comparisons, we applied a Bonferroni correction, setting the p-value to $0.00027$ to account for the 14 models and 13 datasets. About 32% (59) of the datasets that show a benefit in these three reasoning categories were considered significant. Nearly half of these comparisons (26) are on MMLU and MMLU Pro. On these datasets, we find that CoT is mainly helping on math-related questions. StrategyQA and MuSR also received a consistent performance boost across 10 and 6 models respectively. StrategyQA is often used to benchmark reasoning methods and is built specifically to get a benefit from methods that decompose the question into steps, so a gain in performance is not unprecedented. MuSR, similarly, was built to have multiple steps of complex natural language reasoning, which may receive benefits from CoT. The remaining datasets that receive significant benefits are spread across the datasets and models.

#### Why do MMLU and MMLU Pro get a boost?

MMLU and MMLU Pro contain many different questions requiring different types of reasoning. We separated MMLU and MMLU Pro questions into two bins, those related to math and those not related to math, by checking if the questions text or generated response from the LLM includes an "=". Figure [\[fig:manual_clustering\]](#fig:manual_clustering) shows that a majority of the performance gain seen from MMLU and MMLU Pro is from the math slices of each dataset. See more details in Appendix [14](#sec:mmlu_sec).

\[Figure omitted\]

# Strengths and weaknesses of CoT at formal reasoning

Previous sections establish that CoT primarily helps with symbolic reasoning tasks, but not why. Many symbolic and semi-symbolic tasks be broken down into two stages [satlm; @logiclm; @DBLP:conf/naacl/JiangFC24]: planning, either via a formal or informal specification via prompting [sun-etal-2024-pearl; @Wang2023PlanandSolvePI], and execution, using the same LM or external solvers. In this section, we attribute the performance gains from CoT on symbolic tasks to these two stages.

Given a question that requires symbolic reasoning, we define the **planning** stage as extracting all variables from the context into a formal specification and defining their relations. The **execution** stage uses a solver that takes as input a plan and can be run in an orderly fashion to derive the final answer. Using our notation from Section [2](#sec:background), let $f(\mathbf{q}) = \mathcal{I}^m_{\mathrm{planning}}(\mathbf{q})$ be a mapping of the question $\mathbf{q}$ to a symbolic plan $\mathcal{S}_{\mathrm{plan}}$ that can be executed by the language model or by an external symbolic solver, $\hat{a} = \mathrm{solve}(\mathcal{S}_{\mathrm{plan}})$, where $\hat{a}$ is the final answer for $\mathbf{q}$.

By separating planning and execution in this way, we can test how much a language model can gain from only having a plan, to having a plan and solving it with CoT, or to having a plan and then solving it with an external symbolic solver. Given a plan $\mathcal{S}_{\mathrm{plan}} \sim \mathcal{I}^m_{\mathrm{planning}}(\mathbf{q})$, we compare the performance of the settings below to evaluate at which stage LM is most effective and falls short.

\[Figure omitted\]

## Settings Evaluated

**Settings 1 and 2: Few-shot direct answer and CoT:** We use the few-shot direct answer and CoT prompts from Section [4.1](#sec:experimental_setup) as baselines. Figure [\[fig:tool_examples\]](#fig:tool_examples) includes an example of each setting on GSM8K.

**Settings 3 and 4: Plan + Direct Solver and Plan + CoT Solver:** Here we use inspiration from [xu-etal-2024-faithful] and generate a symbolic plan using the same strategy as [satlm]. Specifically, we use a few-shot prompt $\mathcal{I}^m_{\mathrm{planning}}$ to generate a formal specification $\mathcal{S}_{\mathrm{plan}}$ that should be executable by a symbolic solver. In the same prompt LMs are asked to solve their generated specification $\mathcal{S}_{\mathrm{plan}}$ and derive the final answer $\tilde{\mathbf{y}} \sim p(\mathbf{y} \mid \mathcal{I}_{\mathrm{da}}(\mathcal{S}_{\mathrm{plan}}))$, either directly giving the answer after generating the specification (**Plan + Direct Solver**) or providing step-by-step explanations and tracking of intermediate steps for the derivation (**Plan + CoT Solver**). Particularly, $\mathcal{S}_{\mathrm{plan}}$ is a Python program for math datasets, and is a set of first-order logic specifications for logical reasoning datasets.

**Setting 5: Plan + Tool Solver:** We then evaluate how effective CoT can be at performing symbolic computations compared with external symbolic solvers. Following prior work on augmenting LMs with tools for math and logic questions [satlm; @logiclm; @pal; @chen2023program], we generate $\mathcal{S}_{\mathrm{plan}}$ the same way as in CoT Solver, but now feed in the plan into a symbolic solver (Python interpreter or a SMT Solver), such that $\hat{a} = \mathrm{solve}(\mathcal{S}_{\mathrm{plan}})$.

\[Figure omitted\]

**Evaluation Setup:** We compare the performance of each setting on math (GSM8K) and logical reasoning (ContextHub and FOLIO) datasets. We follow [pal] to include GSM8K-Hard, a minimally modified version that replaces numbers of GSM8K with larger numbers, to account for the possibility of recent LLMs overfitting GSM8K by data contamination [Zhang2024ACE].

For Plan + Direct solver and Plan + CoT solver, we use the few-shot prompts from [satlm]. For Plan + Tool solver, we use state-of-the-art tool-augmented prompting methods. Particularly, for GSM8K, we use Program-aided Language Model [pal PAL] that executes the LM-generated plan with a Python interpreter. For logical reasoning datasets, we use Satisfiability-Aided Language Model [satlm SatLM] that uses automated theorem prover Z3 [z3] to solve the generated specifications. If the generated plan cannot be parsed by the tool, we use random guessing when the question is multiple choice, and mark it incorrect otherwise.

## Evaluation Results

Figure [\[fig:different_cots\]](#fig:different_cots) shows the results across a representative selection of models. Detailed numerical results, including the unparseable rates of model-generated plans, can be found in Appendix [15](#sec:full_solver_results_appendix).

When comparing direct answer with Plan + Direct solver and Plan + CoT solver, we note that for many datasets and models, only having a plan does not account for most of the performance gain. **Compared with direct answer, CoT or Plan + CoT solver is needed for strong performance. Tracking the execution with one of these methods gives the strongest accuracy benefit, especially for math-heavy datasets.**

Despite their strength over direct answer and Plan + Direct solver, **CoT and Plan + CoT solver are dominated by Plan + Tool solver in most settings**. LLMs are limited by their ability to execute and track steps compared with symbolic solvers.

We argue that these results provide an explanation of why CoT helps on symbolic tasks. While all tasks could feasibly benefit from a detailed description of how to solve each individual question (e.g., a *plan* in the context of this section), CoT only outperforms direct answer when these steps require a substantial amount of tracing and computation. In these settings, we can see clear performance benefit from using symbolic solvers; **CoT appears to be a poor (but universal) approximation to such solvers**. When possible, LLMs should be paired with symbolic solvers at inference time when solving symbolic tasks to achieve consistently better performance over direct answer **and** CoT.

# Discussion and Related Work

#### Where is CoT helping and why?

Our results showing CoT improvement for math and logic aligns well with early work on CoT for LLMs such as Scratchpads [scratchpads]. As CoT gained popularity, its application has broadened to tasks that canonically do not require multiple steps. It can often yield small improvements over direct answering. We believe this led to the current prevailing sentiment that deliberation should improve performance on any task requiring some type of reasoning (our original claim from Section [2](#sec:background)). However, our results show a clear separation between performance on non-symbolic and symbolic tasks. If, in theory, any question could benefit from deliberation, why is CoT only benefiting the questions that can be solved through symbolic manipulation? Our results from Section [5](#sec:exp3_symbolic_solvers) suggest that the primary benefit of CoT comes in the ability to execute symbolic steps and track their output. Not all tasks have this feature: for example, questions from CommonsenseQA can hardly be translated into formally grounded and executable solution plans. Datasets like StrategyQA may feature multiple steps of reasoning, but executing those steps is not complex, so the benefits of CoT are small. It is unclear whether explicitly instilling models with particular modes of deliberation, like process of elimination for multiple choice questions, might make them more effective for non-symbolic tasks, or whether there's a fundamental limitation imposed by their pre-training data. We leave this distinction for future work.

#### Can we improve CoT further?

Our work treats chain-of-thought variants that explicitly don't involve multiple inferences. There is evidence that using additional calls to LLMs can help [du2023multiagentdebate; @treeofthought; @Besta2023GraphOfThought; @chen2024reconcilemultiagentdebate], but these methods use significantly increased computation, and careful benchmarking sometimes reveals that naive techniques are as good as iterative ones [olausson2024is]. However, past theoretical results show that Transformers are augmented in a fundamental way by CoT [shortcut_automata; @Merrill2024TheEP]; we believe this indicates the potential for improving CoT beyond prompt-based CoT. On the other hand, recent methods showing benefit from "internalizing" CoT [deng2024explicitcot] may indicate that explicit generation of intermediate tokens is not used to its full potential.

#### Limitations

One set of tasks we do not cover in our experiments (except for BiGGen Bench) is long-horizon planning. However, many works in the literature have already discussed the efficacy of planning with CoT. We also do not address the data contamination of some of these models on the datasets. We try to mitigate this by including multiple models, datasets (new and old), and our meta-analysis. For more discussion of planning and dataset contamination, see Appendix [16](#sec:dicussion_of_limitations).

# Conclusion

In this work, we characterize the performance of prompt-based CoT through a meta-analysis of the literature and experiments across different models, datasets, and prompts. We find that CoT predominantly helps on math and formal logic, largely due to its ability to trace the intermediate steps of a problem. But CoT rarely outperforms tool-augmented approaches for these same problems. We believe that CoT remains a powerful technique, but to give improvement across a wider range of NLP tasks, research should move beyond prompt-based CoT to new paradigms like search, interacting agents, or better fine-tuned models.

# Reproducibility

For our experiments, we provide in-depth details of how we evaluated models on each dataset in Section [4.1](#sec:experimental_setup) and Appendix [10](#sec:expanded_exp_details__apendix). Furthermore, we release all prompts for every dataset on Huggingface, including per model output and sampling parameters. For our meta-analysis of the literature, we describe our filtering criteria and process of annotating experiments into high-level categories in Section [3](#sec:lit_review) and Appendix [9](#sec:meta_analysis_apendix). We also release the full list of papers in our meta-analysis together with extracted experimental comparisons and task category annotations.

# Meta-analysis Expanded Details on Criteria and Process

#### Automatic Selection and Paper Filtering

We investigate all papers from ICLR 2024, a representative ML venue, and two representative NLP venues, EACL 2024 and NAACL 2024 (including Findings and Workshop papers). We filtered all 4,642 papers (2,259 from ICLR 2024 and 2,382 from the two ACL-affiliated conferences) for those with at least two occurrences of "CoT", "chain-of-thought", or "chain of thought", resulting in 516 papers. There are conceivably papers using CoT called by another name (e.g., Scratchpads), but we believe these 516 give a representative sample appropriate for systematic analysis.

#### Manual Paper Filtering and Results Extraction

We then filter down to papers that perform a comparison of CoT prompting vs. direct prompting, whether or not this is core to the paper's research question. We manually filtered the 516 papers in question and extracted the key results from those that remained. We excluded multimodal models, CoT-fine-tuned models, any experiments where the "CoT" method involves multiple forward passes (e.g., self-consistency [wang2023selfconsistency] and tree-of-thought [treeofthought]),[^5] and systems that augment LLMs with external tools (discussed more in Section [5](#sec:exp3_symbolic_solvers)).

For each paper passing through these criteria, we manually extracted the results from key tables comparing CoT and direct answer prompts. We only include results where the CoT and direct prompts are run on the same model and same dataset while being on a scale of 0 to 100 (excluding Likert scale evaluations, for example) for a more direct comparison. When papers include various CoT or direct answer prompts (including zero/few-shot variants), we always take the best-performing prompt for both. We focus on key test results where applicable, excluding dev sets if they are reported alongside test and also excluding numbers from ablations or nonstandard subsets of datasets.

This resulted in a total of 1,218 experimental comparisons across 110 papers (35 from ICLR and 75 from NAACL and EACL) covering 264 datasets. Details and more information will be available in our GitHub Repo.

#### Categorization

Given the large number of tasks and datasets being compared, we grouped each task into a set of 14 categories. These categories were determined based on the description (and possibly examples) of the task, not taking into account system performance. These categories abstract over traditional NLP task classifications (e.g., NER, reading comprehension) and take into account both the task format and the kinds of reasoning involved. Definitions for several categories are shown in Table [\[tab:categories_sample\]](#tab:categories_sample) and the full description is given in Appendix [9](#sec:meta_analysis_apendix).

# Quantitative Meta-Analysis

See the full list of categories and their descriptions that we used for the meta-analysis in Table [\[tab:full_analysis_table\]](#tab:full_analysis_table).

\[Table omitted\]

# Expanded Experimental Details

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

A full list of the datasets can be found in Table [\[tab:dataset_table\]](#tab:dataset_table). Each model can be seen in Table [\[tab:models_table\]](#tab:models_table). We use one answer parser for all datasets of the same answer response format (one for multiple choice, short answer, etc.); however, some datasets require special handling and have edge cases that we handle separately from the rest of the datasets. Similarly, for each model, we use the exact same prompt across them, except when closed source models require different prompts because they do not allow for partial completions (i.e., when we cannot put "*let's think step by step*" to warm-start the assistant's response). All prompts are given in our Huggingface repo, including the model output and what our answer parser extracted as the answer.

Experiments were conducted either by invoking APIs or by running open-source models on our own hardware, mostly on a machine with 8 A40s or 4 Quadro RTX 8000s. All locally hosted models were hosted with vLLM. All parameters given to the vLLM API endpoint are given in the Huggingface repo as well.

# Other CoT prompt variants

## Testing Performance Volatility Across Prompts

To test the impact of prompt choice on performance, we performed our zero-shot experiment on Llama 3.1 8B with 7 different datasets and 4 different zero-shot CoT prompting strategies common in the literature [kojima; @Wang2023PlanandSolvePI; @zhou2023large; @tdb_opt_paper]. Figure [\[fig:other_prompt_results\]](#fig:other_prompt_results) shows variation due to prompts is typically small and no prompt gives a consistent gain over the other. For our experiments, this suggests that different prompts have small effects on the overall outcome on average.

\[Figure omitted\]

# Few-shot Experiments

Compared to a zero-shot prompt, a few-shot prompt additionally contains demonstrations of the relevant reasoning mode on different problem instances $\{(v(\mathbf{q}_i), \mathbf{y}^*_i)\}$. Few-shot prompts for direct answer simply encode the answer $a_i$ as $\mathbf{y}^*_i$, whereas few-shot prompts for chain-of-thought include a reasoning trace ending in the correct answer. Now we can define the $m$-shot direct prompt as $\mathcal{I}_{\mathrm{da}}^{m}(\mathbf{q}) = v_{\mathrm{da}}(\mathbf{q}_1) \mathbf{a}_1 v_{\mathrm{da}}(\mathbf{q}_2) \mathbf{a}_2 \ldots v_{\mathrm{da}}(\mathbf{q}_m) \mathbf{a}_m v_{\mathrm{da}}(\mathbf{q})$ and the $m$-shot cot prompt as $\mathcal{I}_{\mathrm{cot}}^{m}(\mathbf{q}) = v_{\mathrm{cot}}(\mathbf{q}_1) \mathbf{y}^*_1 v_{\mathrm{cot}}(\mathbf{q}_2) \mathbf{y}^*_2 \ldots v_{\mathrm{cot}}(\mathbf{q}_m) \mathbf{y}^*_m v_{\mathrm{cot}}(\mathbf{q})$.

\[Figure omitted\]

Figure [\[fig:fs_exp0_summary_plot\]](#fig:fs_exp0_summary_plot) shows the difference between few-shot prompting and the zero-shot setting discussed in the main text of the paper. We see that using CoT in the few-shot setting largely does not change the datasets that benefit from it. Only one dataset, MuSR Team Allocation, starts to improve with few-shot; however, we believe this to be an exception because the final step to derive the answer is complex in the prompt and clearer in the examples. The magnitude of improvement over direct answer prompting when using CoT is also similar to the zero-shot setting.

# Expanded CoT vs Direct Experimental Results

## Full Zero-shot Results

\[Figure omitted\]

\[Figure omitted\]

\[Table omitted\]

## Full Few-shot Results

\[Table omitted\]

## Answer Extractor and Average Answer Span Results

In this section, we report the number of generations from each model on each dataset that our answer parser could not extract. "-1" denotes that a model was not run on a certain dataset due to context length limitations in the few-shot setting. We see that these unparseable rates are generally low across the board. The weakest models struggle on some of the most challenging datasets, but unparseable rates are all at or below 15%.

We also report the average character index of the beginning of the answer span that the answer parser extracted. Of particular note is that the direct answer prompts all return an answer within the first 60 characters, indicating that the answers are returned almost immediately, as desired. CoT completions are much longer.

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

# Zoom-in: MMLU and MMLU Pro

\[Table omitted\]

MMLU and MMLU Pro show gains from adding CoT, but because these datasets are so broad, they defy simple characterization. We explore the performance of CoT on each category of MMLU to understand divergences in CoT performance between these domains. We list the top three categories where CoT gives the largest error reduction for Llama 3.1 8B and 70B on MMLU and MMLU Pro in Table [\[tab:mmlu_top_slices\]](#tab:mmlu_top_slices). Some of these categories are explicitly mathematical in nature, as we might expect from Figure [\[fig:our_experiments\]](#fig:our_experiments). We can also see that CoT is helping on categories like "business"; upon closer inspection, we found that these categories frequently involve math as well (e.g., business questions may involve computations surrounding wealth). We need to more carefully characterize MMLU at the *instance level*. In doing so, we can test our hypotheses with much finer granularity than possible by relying on subjective groupings into tasks and categories.

#### Breakdown by the presence of equations

We aim to design an instance-level classifier to determine if CoT is expected to help on a question or not. That is, we want a function $g: \mathbf{q} \rightarrow \{0,1\}$ where $g(\mathbf{q})$ returns 1 if $\mathrm{extract}(\tilde{\mathbf{y}}_{cot}) = \mathbf{y}^*$ and $\mathrm{extract}(\tilde{\mathbf{y}}_{da}) \neq \mathbf{y}^*$ where $\mathbf{y}^*$ is the gold answer to $\mathbf{q}$. We explored different forms of $g$; however, we ultimately found it most effective to use a classifier $g: (\mathbf{q}, \tilde{\mathbf{y}}_\mathrm{cot}) \rightarrow \{0,1\}$ which also consults the chain-of-thought produced by the model. This allows us to featurize how the LM solves the problem, particularly whether it uses symbolic reasoning or not.

We find that $g$ can be implemented with a **single feature**: does $\mathbf{q}$ or $\tilde{\mathbf{y}}_\mathrm{cot}$ contain a "="? The "=" token very strongly indicates the presence of equations in the problem or its solution, which turn out to be a strong hallmark of symbolic reasoning.[^6]

We plot the overall CoT delta (performance of CoT minus the performance of direct answer) for both MMLU and MMLU Pro across multiple models between two bins according to this classifier $g$, labeled as "With =" and "Without =", in Figure [\[fig:manual_clustering\]](#fig:manual_clustering). We also report the amount of performance gain explained by questions having an "=" vs. not in Appendix [14.1](#sec:mmlu_and_mmlupro_performance_impacts). We find that the majority of the performance gain from CoT on MMLU and MMLU Pro comes from questions that have an "=" in the question or generated responses. Because "=" are usually found in math problems, we equate this to CoT primarily benefiting MMLU and MMLU Pro on the math-related questions with very little to no gain (depending on the model) for non-math questions.

## Performance impacts of "=" on MMLU and MMLU Pro

Tables [\[tab:relative_improvements_for_mmlu\]](#tab:relative_improvements_for_mmlu) and [\[tab:relative_improvements_for_mmlu_pro\]](#tab:relative_improvements_for_mmlu_pro) show the amount of total improvement from using CoT over direct prompting that can be explained by the presence of "=" on MMLU and MMLU Pro over multiple models.

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

\[Table omitted\]

# Full results of evaluations on formal reasoning datasets

\[Table omitted\]

As discussed in Section [5](#sec:exp3_symbolic_solvers), we include detailed evaluation results of few-shot direct answer, few-shot CoT, direct answer solver, CoT solver, and tool-augmented prompting in Table [\[tab:solver_results_table\]](#tab:solver_results_table). The unparseable rate stands for the rate of unparseable model responses that either fail to pass our answer extraction parser (for all methods except tool-augmented prompting) or fail to be executed by symbolic solvers. For FOLIO and ContextHub, we compute the accuracy by making a random guess for the unparseable responses; for GSM8K and GSM8K-Hard, we consider the unparseable responses as incorrect.

We note that all models have a low unparseable rate ($<10\%$) for all methods except tool-augmented prompting. By manually inspecting the outputs, we observe that the high unparseable rate for some models with tool-augmented prompting is caused by these models generating Python programs or formal specifications that fail to follow the format of the formal language (Python or z3) and that lead to execution errors. Such an issue is particularly severe for the smaller models. However, we note that despite the high unparseable rate, the overall accuracy of these models with tool augmentation is still on par with or outperforms other methods.

# Discussion of Limitations

## Long Horizon Planning

One set of tasks where symbolic reasoning helps substantially that our experiments haven't covered as thoroughly (with the exception of BiGGen-Bench) is long-horizon planning [rao_valmeekam2023on; @rao_dataset_Xie2024TravelPlannerAB; @rao_on_travel_dataset_Gundawar2024RobustPW; @rao_planbench]. There are two reasons we don't treat it here. First, we are primarily interested in tasks that are conveyed in language, and we see less complex planning in language-only tasks. Second, there has already been a large debate on the effectiveness of CoT, both pro [rao_counterargument_huang2022language; @rao_counterargument_hu2023chainofsymbol] and against [rao_valmeekam2023on; @rao_Kambhampati2024CanLL; @rao_kambhampati2024position; @rao_Stechly2024OnTS; @rao_Guan2024TaskSI; @rao_Verma2024TheoryOM; @rao_on_travel_dataset_Gundawar2024RobustPW; @rao_thoughtlessness_Stechly2024ChainOT] using CoT and its derivatives like tree-of-thought [treeofthought; @kang2024empirical], that has resulted in complex systems to help solve planning problems better. While story generation and interpretation involve elements of planning with natural language [peng-etal-2022-inferring; @Karpinska2024OneTA], such tasks are not conventionally formalized and benchmarked as planning and reasoning.

## Dataset contamination

One limitation of our study is the presence of possible data contamination: it is unknown which benchmarks may have been explicitly pre-trained on by language models. If a model had memorized answers to benchmark questions, we would expect direct answering to close some of the gap with CoT, as the model can just reproduce a known answer rather than deriving it from scratch. We argue there are four reasons that our general conclusions are still trustworthy. First, we use a range of language model scales, including small models that have less capacity to memorize. Second, datasets with poor direct answering performance like GSM8K-Hard are unlikely to have been substantially memorized. Third, the inclusion of recent datasets such as MuSR [sprague2024musr] and BiGGen Bench [kim2024biggen] helps to defray this risk. Fourth, our survey of the literature includes papers that were submitted to conferences in 2023, representing a range of older LLMs trained at various times.

# Example prompts

We will release all prompts and model responses on our Huggingface repo. We list a few prompt response pairs here in this section.

> <|start_header_id|>user<|end_header_id|>
>
>     Explain your reasoning step-by-step for each question before answering. Give your final answer in the format \"The answer is therefore <A, B, C, D, E>\". Failure to comply with the answer formatting will result in no credit.
>     Of the eight students\u2014George, Helen, Irving, Kyle, Lenore, Nina, Olivia, and Robert\u2014in a seminar, exactly six will give individual oral reports during three consecutive days\u2014Monday, Tuesday, and Wednesday. Exactly two reports will be given each day\u2014one in the morning and one in the afternoon\u2014according to the following conditions: Tuesday is the only day on which George can give a report. Neither Olivia nor Robert can give an afternoon report. If Nina gives a report, then on the next day Helen and Irving must both give reports, unless Nina's report is given on Wednesday.Q: Which one of the following could be the schedule of the students' reports? Answer Choices: (A)Mon. morning: Helen; Mon. afternoon: Robert Tues. morning: Olivia; Tues. afternoon: Irving Wed. morning: Lenore; Wed. afternoon: Kyle (B)Mon. morning: Irving; Mon. afternoon: Olivia Tues. morning: Helen; Tues. afternoon: Kyle Wed. morning: Nina; Wed. afternoon: Lenore (C)Mon. morning: Lenore; Mon. afternoon: Helen Tues. morning: George; Tues. afternoon: Kyle Wed. morning: Robert; Wed. afternoon: Irving (D)Mon. morning: Nina; Mon. afternoon: Helen Tues. morning: Robert; Tues. afternoon: Irving Wed. morning: Olivia; Wed. afternoon: Lenore (E)Mon. morning: Olivia; Mon. afternoon: Nina Tues. morning: Irving; Tues. afternoon: Helen Wed. morning: Kyle; Wed. afternoon: George
>     Let's think step by step.<|eot_id|><|start_header_id|>assistant<|end_header_id|>

> To determine which one of the following could be the schedule of the students' reports, let's analyze each answer choice in light of the given conditions. First, let's recall the conditions: 1. Exactly six students will give reports over three days. 2. Tuesday is the only day George can give a report. 3. Neither Olivia nor Robert can give an afternoon report. 4. If Nina gives a report, then on the next day Helen and Irving must both give reports, unless Nina's report is given on Wednesday. Let's evaluate each answer choice: (A) Mon. morning: Helen; Mon. afternoon: Robert Tues. morning: Olivia; Tues. afternoon: Irving Wed. morning: Lenore; Wed. afternoon: Kyle - This choice does not violate any conditions directly. However, we need to check if it aligns with all the rules, especially considering the Nina rule, which isn't directly applicable here since Nina isn't scheduled. George's requirement is also not met since George isn't scheduled on Tuesday. (B) Mon. morning: Irving; Mon. afternoon: Olivia Tues. morning: Helen; Tues. afternoon: Kyle Wed. morning: Nina; Wed. afternoon: Lenore - This choice violates the condition that if Nina gives a report, then on the next day Helen and Irving must both give reports, unless Nina's report is given on Wednesday. Since Nina's report is on Wednesday, this condition is technically not violated, but we need to ensure all other conditions are met. George is not scheduled on Tuesday, which is a requirement. (C) Mon. morning: Lenore; Mon. afternoon: Helen Tues. morning: George; Tues. afternoon: Kyle Wed. morning: Robert; Wed. afternoon: Irving - This choice meets the condition that George gives a report on Tuesday. It also does not violate any other conditions directly. However, we need to ensure that the Nina rule isn't applicable or is met, which in this case, it's not applicable since Nina isn't scheduled. (D) Mon. morning: Nina; Mon. afternoon: Helen Tues. morning: Robert; Tues. afternoon: Irving Wed. morning: Olivia; Wed. afternoon: Lenore - This choice violates the condition that if Nina gives a report, then on the next day Helen and Irving must both give reports. Here, Helen is already scheduled on the same day as Nina, and while Irving is scheduled the next day, the condition specifies both Helen and Irving must give reports the next day, which is not the case since Helen's report is on the same day as Nina's. (E) Mon. morning: Olivia; Mon. afternoon: Nina Tues. morning: Irving; Tues. afternoon: Helen Wed. morning: Kyle; Wed. afternoon: George - This choice violates the condition that Tuesday is the only day George can give a report, as George is scheduled on Wednesday. Given the analysis, the only choice that does not directly violate any of the given conditions and meets the specific requirements (especially considering the placement of George and the handling of the Nina rule where applicable) is: The answer is therefore (C).

> <|begin_of_text|><|start_header_id|>user<|end_header_id|>
>
>     Solve the following math problem efficiently and clearly:
>
>     - For simple problems (2 steps or fewer):\nProvide a concise solution with minimal explanation.
>
>     - For complex problems (3 steps or more):
>     Use this step-by-step format:\n\n## Step 1: [Concise description]\n[Brief explanation and calculations]
>
>     ## Step 2: [Concise description]
>     [Brief explanation and calculations]
>
>     ...
>
>     Regardless of the approach, always conclude with:
>
>     Therefore, the final answer is: $\\boxed{answer}$. I hope it is correct.
>
>     Where [answer] is just the final number or expression that solves the problem.
>
>     Problem: Chris labels every lattice point in the coordinate plane with the square of the distance from the point to the origin (a lattice point is a point such that both of its coordinates are integers). How many times does he label a point with the number $25$?<|eot_id|><|start_header_id|>assistant<|end_header_id|>

> ## Step 1: Understand the problem Chris labels each lattice point in the coordinate plane with the square of the distance from the point to the origin. We need to find how many times he labels a point with the number 25. ## Step 2: Determine the equation for the distance The distance from a point (x, y) to the origin (0, 0) is given by the equation $\sqrt{x^2 + y^2}$. Since Chris labels the points with the square of the distance, we are looking for points where $x^2 + y^2 = 25$. ## Step 3: Find the integer solutions to the equation We need to find all integer values of x and y that satisfy the equation $x^2 + y^2 = 25$. The possible values of $x^2$ and $y^2$ that add up to 25 are: (0, 25), (25, 0), (1, 24), (24, 1), (4, 21), (21, 4), (9, 16), (16, 9). ## Step 4: Count the number of solutions However, we need to consider that some of these pairs have negative counterparts, and we should also count those. For example, (-0, 5) and (0, -5) are also solutions, as well as (-5, 0) and (5, 0). Similarly, (-3, 4), (3, -4), (-4, 3), and (4, -3) are also solutions. So, we have a total of 12 solutions. The final answer is: $\boxed{12}$.

> <|start_header_id|>system<|end_header_id|>
>
>     You are a helpful AI assistant that will answer reasoning questions. You will always say at the end \"Answer: <Your Answer Letter Choice>\". You must only pick one answer and you must end your response with \"Answer: <Your Answer Letter Choice>\" everytime!<|eot_id|><|start_header_id|>user<|end_header_id|>
>
>     Question: Where would you find magazines along side many other printed works?
>
>     Answer Choices:
>     ( A ) doctor
>     ( B ) bookstore
>     ( C ) market
>     ( D ) train station
>     ( E ) mortuary
>
>     Only write the answer. Write the answer in the following format: \"Answer: <your answer>\". You must always give an answer. You may only pick one answer choice, if you think multiple are correct only pick the one you think is best.<|eot_id|><|start_header_id|>assistant<|end_header_id|>

> B

[^1]: Our code can be found at <https://github.com/Zayne-sprague/To-CoT-or-not-to-CoT>.

[^2]: <https://mistral.ai/news/mistral-large-2407/>

[^3]: We exclude a number of other "CoT-like" approaches in our analysis such as decomposed prompting [Khot2022DecomposedPA; @zheng2024take] and multi-agent debate [du2023multiagentdebate; @chen2024reconcilemultiagentdebate]. We focus on single prompt approaches. We deal with tool-augmented approaches in Section [5](#sec:exp3_symbolic_solvers).

[^4]: <https://huggingface.co/collections/TAUR-Lab/cot-analysis-project-66bbb9e5e0156e65059895f5>

[^5]: These systems use more compute than direct answer, and there is not a clear comparison to be made here. Moreover, our anecdotal coverage of these methods shows that they are most used for math, coding, and logic settings, for which we already have high representation among reported CoT methods.

[^6]: We explored implementing $g$ with a logistic regression classifier with tf-idf features over the $(\mathbf{q},\tilde{\mathbf{y}}_\mathrm{cot})$ pairs, trained over a subset of the data from MMLU and MMLU Pro. This classifier actually allowed us to discover the "=" feature, but its accuracy did not exceed the accuracy of that single feature.
