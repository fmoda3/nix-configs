# Abstract

Few-shot prompting is a surprisingly powerful way to use Large Language Models (LLMs) to solve various tasks. However, this approach struggles as the task complexity increases or when the individual reasoning steps of the task themselves are hard to learn, especially when embedded in more complex tasks. To address this, we propose Decomposed Prompting, a new approach to solve complex tasks by decomposing them (via prompting) into simpler sub-tasks that can be delegated to a shared library of prompting-based LLMs dedicated to these sub-tasks. This modular structure allows each prompt to be optimized for its specific sub-task, further decomposed if necessary, and even easily replaced with more effective prompts, trained models, or symbolic functions if desired.

We show that the flexibility and modularity of Decomposed Prompting allows it to outperform prior work on few-shot prompting using GPT-3. On symbolic reasoning tasks, we can further decompose sub-tasks that are hard for LLMs into even simpler solvable sub-tasks. When the complexity comes from the input length, we can recursively decompose the task into the same task but with smaller inputs. We also evaluate our approach on textual multi-step reasoning tasks: on long-context multi-hop QA, we can more effectively teach the sub-tasks via our separate sub-tasks prompts; and on open-domain multi-hop QA, we can easily incorporate a symbolic information retrieval module within our decomposition framework, leading to improved performance on both tasks.

# Introduction

Large Language Models (LLMs) such as GPT-3 [gpt3] have been shown to solve various tasks given only a few examples as prompts, also referred to as in-context learning. These models can even perform more complex reasoning tasks when shown the sequence of simple reasoning steps needed to perform the complex task as a prompt [Wei2022ChainOT; Nye2021ShowYW]. In essence, the sequence of reasoning steps, such as in Chains-of-Thought (CoT) prompting [Wei2022ChainOT], demonstrates how to decompose the complex task as well as how each reasoning step should be performed. However, as tasks become more complex, few demonstrations of the complex task aren't sufficient for current models to learn to perform all necessary reasoning steps. E.g., few-shot demonstrations of concatenating the `latex $k^{\mathrm{th}}$ ` letter of words in a string is insufficient for GPT-3 to learn to extract the `latex $k^{\mathrm{th}}$ ` letter, or learn to answer hard single-hop questions when only provided a few demonstrations of multi-hop questions. Additionally, it is unclear whether tasks such as document retrieval and integration, for knowledge-intensive tasks, can even be done by few-shot prompts.

[IMAGE: Figure 1 - decomp_intro_modified.pdf - While standard approaches only provide labeled examples (shown as a grey input box with green label box), Chain-of-Thought prompting also describes the reasoning steps to arrive at the answer for every example in the prompt. Decomposed Prompting, on the other hand, uses the decomposer prompt to only describe the procedure to solve the complex tasks using certain sub-tasks. Each sub-task, indicated here with A, B and C is handled by sub-task specific handlers which can vary from a standard prompt (sub-task A), a further decomposed prompt (sub-task B) or a symbolic function such as retrieval (sub-task C)]

To address these limitations, we propose **Decomposed Prompting** (DecomP), a new approach to solve complex tasks by instead decomposing them into simpler sub-tasks and delegating these to sub-task specific LLMs, with both the decomposer and the sub-task LLMs (henceforth, _sub-task handlers_) having their own few-shot prompts. Fig 1 illustrates our approach. The decomposer prompt only describes a sequence of sub-tasks (A, B, and C) needed to solve the complex tasks, indicated with the dashed lines. Each sub-task is then delegated to the corresponding sub-task handler shown on the right.

Using a software engineering analogy, the decomposer defines the top-level _program_ for the complex task using interfaces to simpler, sub-task functions. The sub-task handlers serve as modular, debuggable, and upgradable _implementations_ of these simpler functions, akin to a software library. If a particular sub-task handler, say the one for identifying the `latex $k^{\mathrm{th}}$ ` letter or retrieving a document, is not performing well enough, we can debug this handler in isolation, explore alternative prompts or implementations, and seamlessly plug the improved module back into the overall system, as a systematic way to try to improve performance on the complex end-task.

This approach has several advantages over prior work (as also shown in the figure). The sub-task handlers can be shown a broader and richer set of examples (of the simpler task) than the specific ones needed for the complex task prompt (task A). If a sub-task is too complex, it can be further decomposed into simpler sub-tasks (task B). Similar to software libraries, these sub-task handlers can be shared across multiple tasks; e.g., here tasks A and C are reused in the model for task B. As noted above, a sub-task handler can be easily swapped with an improved implementation without any change to the rest of the system. Few-shot prompt based LLMs can be even replaced with a symbolic system for tasks more suited for non-neural methods; e.g., task C uses a symbolic retrieval system such as Elasticsearch that can handle very large-scale corpora. Lastly, we can even improve upon prior work by simply adding an _error-correcting_ sub-task handler as a post-processing step.

To illustrate these advantages of DecomP, we empirically evaluate it against prior work on eight challenging datasets using GPT3 models: (1) On a task of concatenating the `latex $k^{\mathrm{th}}$ ` letter, we show that our approach of factoring out each sub-task allows us to more effectively teach the sub-problem of extracting the `latex $k^{\mathrm{th}}$ ` letter(specifically, by decomposing it into even easier sub-tasks). (2) On a task of reversing a list, we show that DecomP allows us to extend the capabilities of a weaker model and build a scale-invariant system by recursively decomposing the task into reversal of smaller and smaller lists. (3) On a task of long-context QA [Khot2022HeyAC], our approach allows each sub-task handler to accommodate more examples than feasible with CoT prompting leading to better QA performance. (4) On three multi-hop open-domain QA datasets [hotpotqa; xanh2020_2wikimultihop; musique], we can incorporate a symbolic retrieval (ElasticSearch) API as the handler for the retrieval sub-task leading to better results than CoT. (5) On two Math QA datasets [cobbe2021gsm8k; roy-roth-2015-solving], we can post-process CoT to easily fix frequent formatting errors, resulting in a surprisingly high improvement of 14-17 pts.

# Related Work

#### Few-shot Prompts for Multi-Step Reasoning

Large-scale Language models (LLMs) have been shown to learn various NLP tasks given just few examples as prompts [gpt3]. Recently, they have also been successfully applied to various multi-step reasoning tasks by providing the intermediate reasoning steps, i.e. Chain-of-Thought [Wei2022ChainOT; chowdhery2022palm], needed to arrive at the answer. An alternate approach has been to compose multiple LLMs or LLMs with symbolic functions to perform multi-step reasoning [jung2022maieutic; creswell2022selection; selfask; talm; pal; Schick2023ToolformerLM inter alia]. We view these prior works as specialized systems with a pre-defined decomposition structure.

The closest works to our approach are the ideas of least-to-most prompting [Zhou2022LeasttoMostPE] and successive prompting [succprompting] where one prompt/model is used to generate the sub-questions needed to answer a complex question and a second prompt/model sequentially answers these sub-questions. In contrast, our approach allows for diverse decomposition structures including recursion and other non-linear decomposition structures. E.g., by definition, least-to-most asks questions from easiest to the hardest and requires an LLM to eventually answer the complete question ("most" in least-to-most) whereas we have no such restriction. Additionally, we iteratively generate new questions based on previous answers (similar to successive prompting) and can explicitly assign different prompts or symbolic systems to answer each sub-question.

#### Modular Approaches for Multi-Step Reasoning

Our work follows a long literature in NLP on neural modular modeling architectures [andreas2016neural; talmor2018web; min-etal-2019-multi; jiang2019self; gupta2020neural; perez2020unsupervised; khot-etal-2021-text; levine2022standing] for question-answering and other tasks. We take particular inspiration from the _Text Modular Networks_ approach of khot-etal-2021-text, whereby problem decomposition consists of a learned _next question_ generator trained to generate questions in the language of a collection of textual and symbolic agents. Best-first search strategy was used to explore the space of possible decompositions during inference. In contrast to this work, which largely centered around supervised training of the next-question generator _given existing agents_, we leverage the power and recent successes of few-shot LLMs to build both the decomposer and the sub-task agents that best fit the ideal decomposition. This has the advantage of obviating the need for specialized supervised training data that may not always be available for all sub-tasks -- a key bottleneck of this prior work.

# Decomposed Prompting

As with conventional _few-shot_ prompting, the goal is to teach an LLM to find an answer `latex $A$ ` to a query `latex $Q$ ` using a small set of _in-context_ examples `latex $D = \{E_{1},...,E_{|D|}\}$ `. The answer `latex $A$ ` is obtained from the underlying distribution `latex $p(A \mid Q,D,\theta)$ ` [dohan2022language]. In the most basic few-shot setup, examples take the form `latex $E_j = (Q_j, A_j)$ `. In the case of CoT-style prompting, the goal is to obtain answers by first generating a sequence or chain of intermediate reasoning steps or "thoughts" `latex $T$ `, and then deriving the final answer based on `latex $T$ `. To teach this ability, one uses more sophisticated in-context examples that take the form `latex $E_{j} = (Q_{j},(T_{j,1},\ldots,T_{j,k}),A_{j})$ `.

In DecomP, the core is a _decomposer_ LLM that tries to solve a complex task by generating a **prompting program** `latex $P$ ` for it. Each step of `latex $P$ ` directs a simpler sub-query to a function in an auxiliary set of **sub-task functions** `latex $\mathcal{F}$ ` available to the system. Given a query `latex $Q$ ` whose answer is `latex $A$ `, the program `latex $P$ ` is a sequence of the form `latex $\big((f_1,Q_1,A_1),...,(f_k,Q_k,A_k)\big)$ ` where `latex $A_k$ ` is the final answer predicted by `latex $P$ ` and `latex $Q_i$ ` is a sub-query directed to the sub-task function `latex $f_i \in \mathcal{F}$ `. `latex $P$ ` is executed by a high-level imperative **controller**, which passes the inputs and outputs between the decomposer and sub-task handler until a stopping condition in `latex $P$ ` is met and the final output obtained.

To teach the decomposer LLM in a few-shot prompting manner, we use in-context examples that take the form `latex $E_j = \big( (Q_j, \big(f_{j,1},Q_{j,1},A_{j,1}),...,(f_{j,k_j},Q_{j,k_j},A_{j,k_j})\big) \big)$ ` where `latex $A_{j,k_j} = A_j$ ` is the final answer for `latex $Q_j$ ` and `latex $(Q_{j,1}, \ldots, Q_{j,k_j})$ ` is a decomposition of `latex $Q_j$ `. Each sub-task function `latex $f$ `, in turn, is operationalized via a sub-task handler as an in-context prompting LLM (e.g., a separate CoT-style prompt or a additional prompting program dedicated to that sub-task), or any other symbolic or learned function (e.g., a calculator or specialized supervised trained model).

## Decomposed Prompts

[IMAGE: Figure 2 - letter_cat_prompts.pdf - Prompts for the decomposer and the split and merge sub-tasks used by the decomposer. The decomposer specifies the sequence of questions and corresponding sub-tasks (within square braces). The sub-task prompts can be written independent of the complex task examples and can even capture generalizations, e.g., letters in word (split) and no delimiter (merge).]

To illustrate this with an example, consider a multi-step task such as "Concatenate the first letter of every word in $str$ using a space". We can solve this task by decomposing it into a sequence of three simple sub-tasks: 1) Collect the list of words in the $str$; 2) For each word, extract the third letter; 3) Concatenate the extracted letters using space as the separator. Fig. 2 shows an example decomposition prompt for this task. Much like a conventional structured program, the top-level `decomp` prompt provides an example program `latex $E_j$ ` using three sub-task functions: `latex $f_1:$ ` `split` that _splits words in an input string_, `latex $f_2:$ ` `str_pos` that _finds character positions in strings_ and `latex $f_3:$ ` `merge` that _concatenates characters_. In this case, we operationalize each sub-task function as a separate in-context prompt (e.g., using a standard prompting approach for `split` and `merge` on the right side), each containing a set of in-context examples that are independent of the original complex task.

In addition to the three functions described above, additional control structure is included, such as the symbolic function `foreach`, which iterates over arrays and references to previous answers such as #1. We note that such a helper function is not strictly necessary (e.g., we could directly generate "Q2': What is the first letter of Jack?" and "Q3': What is the first letter of Ryan?" instead of Q2 in the figure) and is added to reduce the manual effort needed to specify the decomposition and also reduce potential errors during decomposition. In our experiments we use two of the compositional operators defined by Khot2022HeyAC (see appendix for details), although it is capable of using all their operators (which also capture the QDMR operators from Wolfson2020Break).

[IMAGE: Figure 3 - letter_cat_exec.pdf - The inference procedure in DecomP iteratively calls the decomposer prompt to generate the next question and sub-task at each step, given the current history of question and answers. The generated question is then routed to the assigned sub-task handler (with some handling of special operators, when needed). When the special end-of-questions [EOQ] marker is generated, the previous answer is returned as the final prediction.]

## Prompt Execution and Inference

Given a new question and a set of background in-context examples `latex $D$ `, the inference (i.e., the program construction and execution) process is illustrated in Fig. 3. The new complex question is fed to the decomposer prompt to get the first sub-question to be asked to the `split` prompt. With the help of our symbolic controller, the answer generated from this prompt is then appended to the decomposer prompt to get the second sub-question, `latex $Q2$ `. Due to the `foreach` operator in the generated question, `latex $Q2$ ` results in two questions (one for each word in `latex $\#1$ `) to be fed to the `str_pos` prompt. The answers are combined into an array to get the answer `latex $\#2$ `. The entire decomposition history is used to generate `latex $Q3$ ` and passed to the `merge` prompt to get the final answer. Since the task has been solved, the decomposition prompt produces the special end-of-sequence marker([EOQ]) and the last answer is returned as the final answer. Formally, performing inference involves finding the best answer `latex $A$ ` to a new query `latex $Q$ `, which in the simplest form involves computing the MAP answer using the LLMs predictive distribution for `latex $A$ `, i.e., `latex $\hat{A} = \mathop{\mathrm{arg\,max}}_{A} p(A \mid D,Q,\theta)$ ` [dohan2022language]. For practicality, such computations are approximated using greedy search in our experiments.

## DecomP Capabilities

**Hierarchical Decomposition** Certain sub-tasks, even when given many examples, are not solvable with few-shot prompting. E.g., we found identifying the `latex $k^{\mathrm{th}}$ ` letter of a string to be challenging for the GPT3 `text-davinci-002` model. In such a scenario, we can decompose the sub-task prompt further, to first identify the letters and their position and then select the `latex $k^{\mathrm{th}}$ ` element of this array (see Fig. 4). We can also re-use existing sub-task prompts in our framework. E.g., the `split` prompt can be reused since it was developed for the general task of splitting strings.

[IMAGE: Figure 4 - str_pos_prompts.pdf - Since identifying the k-th character is challenging for GPT3 davinci-002 model, we further decompose it into two simpler sub-tasks: split the word into its letters (using the shared sub-task split) and then return the k-th item of this list using the arr_pos prompt.]

**Recursive Decomposition** Some problems can be naturally broken down into one or more smaller problems of the same form. Recursive algorithms such as merge sort use this idea to solve large problems efficiently, using a succinctly described method. We apply this same principle in DecomP by allowing the decomposer prompt to recursively call itself, as shown in Fig. 5 for the task of list reversal. By using recursion, we are able to generalize any base prompting approach (CoT in this figure) to much longer lists by breaking the input into smaller and smaller lists till we reach a list length where the model is highly accurate. Such recursive approaches can not be described by current methods such as CoT and standard prompting. Least-to-most prompting [Zhou2022LeasttoMostPE] also proposes a similar solution but differs in two key aspects (a) it has to identify all the sub-problems in one-shot instead of our iterative top-down decomposition (b) it has to learn to identify the relevant answers from the previous solutions which we get for free from our decomposition.

[IMAGE: Figure 5 - reverse_decompv2.pdf - Sample prompt for recursive decomposition for reversing lists. Each list is split into two halves and each half is reversed and concatenated in the reverse order. We can recursively split a list till we hit the base case (lists of length 3 here) where existing approaches such as CoT are accurate.]

#### External API Calls

In certain cases, the sub-tasks may not be feasible to solve using only a LLM. E.g., retrieving knowledge from a KB or large corpus. Such sub-tasks, however, can be easily solved using existing systems such as retrieving documents using an Elasticsearch index or webpages using Google search [Lazaridou2022InternetaugmentedLM]. Fig. 6 shows how DecomP can easily use such a system to retrieve the relevant documents and answer a single-hop open-domain question.

[IMAGE: Figure 6 - hotpotqa_prompt_intro.pdf - A Decomposed Prompt to answer open-domain questions using Elasticsearch-based retrieval. Full usage of this prompt for open-domain multihop questions is given in Fig. 9.]

# Case Studies

We showcase DecomP's strengths through four tasks; two symbolic manipulation tasks similar to those investigated by Wei2022ChainOT and two existing textual multi-hop reasoning tasks. Unless specified, we use `text-davinci-002` InstructGPT3 model [Ouyang2022TrainingLM] as the LLM and report the Exact Match (EM) numbers, following prior work. For order-independent list answers, we evaluate set equality as EM. We compare our approach to CoT rather than each specific decomposition structure used in prior work. See App. 12 for the complete prompts for all our tasks.

## k-th letter concatenation (Hierarchical Decomposition)

We compare DecomP to CoT prompting for concatenating letters at the `latex $k^{\mathrm{th}}$ ` position. All prompts contain examples of concatenating letters in position 1, 4, and last position of strings with 3 words. We create three different prompts for all our baselines and present the average to account for variance due to the choice of examples following Perez2021TrueFL. We use the `decomp`, `split`, `str_pos` (further decomposed as shown in Fig. 4), and `merge` prompts for decomposition prompting. We adapt the CoT for last letter concatenation from prior work [Wei2022ChainOT] for this task as shown below. In addition, we consider a _rolled out_ version of our decomposition prompts in terms of a CoT, i.e., we describe the entire decomposition process (identify words, split each word into letters, take `latex $k^{\mathrm{th}}$ ` letter and concatenate) as a single CoT. e.g, for the question "Take the letters at position 4 of the words in "Herbert Alexander Simon" and concatenate them using a space.", we use the CoT:

We similarly adapt the least-to-most prompt [Zhou2022LeasttoMostPE] to include rollout. (see App. 12). We compare these four prompting techniques on 4 datasets to evaluate generalization along 3 axes: (1) new letter position k=3; (2) longer inputs, #words=4 and 5; (3) new delimiter ";". The words in the test examples come from a list of most popular first and last names. All evaluation datasets have 100 examples. We present results on space as a delimiter averaged across three prompts in Fig. 7.

[IMAGE: Figure 7 - letter_cat_space.pdf and reverse_bar.pdf - EM results on reversing sequences. Incorporating CoT in DecomP greatly increases the ability of the model to generalize to new sequence lengths.]

**DecomP outperforms chain-of-thought and least-to-most prompting**, even when the prompt uses the same reasoning procedure as the rolled out decomposition. This shows that the separate prompts are more effective at teaching hard sub-tasks than a single CoT prompt.

**DecomP generalizes perfectly to longer sequences.** As the length of the input sequence increases, our approach continues to achieve close to 100% accuracy on this task. The CoT-based approaches drop noticeably in their scores with longer input lengths, widening the performance gap.

## List Reversal (Recursive Decomposition)

We use the task of reversing lists of words to show how recursive DecomP enables length generalization. We adapt the relevant CoT prompt from Wei2022ChainOT, and integrate it in a decomposed prompt. As a control, we also compare to a CoT version w/ rollout of our decomposed prompt. All prompts contain the same 3 examples of reversing word sequences with 3-5 items. We evaluate all prompts for generalization to 4, 6, 8, and 10-item sequences. Here we use `davinci-001` to show that DecomP enables a weaker model approach `davinci-002`'s performance (which does solve this task). We use the strategy from Fig. 5 and provide our prompts in App. 12. Fig. 7 shows the results of the prompting strategies on different input lengths.

**DecomP improves the length generalization of few-shot prompting.** While our base CoT prompt does not generalize at all to longer sequences, our approach can recursively decompose the problem and achieve better length generalization. Moreover, the CoT version of our decomposition strategy fails because the unrolled prompt becomes too long and convoluted without the ability to abstract away sub-modules.

## Long-Context Question Answering

We next evaluate on the CommaQA-E dataset [Khot2022HeyAC] under the reading comprehension setting. The dataset consists of synthetically generated entities (e.g. Erowid award), facts ("Wetherality was an actor in the movie Dewbar.") and multi-hop questions (e.g., "What awards have the actors of the Erowid winning movies received?"). Due to the presence of many distractors and, as a result, longer context, this dataset has been shown to be hard for standard LMs even when fine-tuned.

[IMAGE: Figure 8 - commaqa_decomp_only.pdf - Sample prompts used for the CommaQA dataset. On the left, the coarse-grained decomposition defines a single QA sub-task with all single-hop questions being delegated to a single sub-task handler. On the right, the fine-grained decomposition assigns questions to three different sub-tasks (see App. 12 for their prompts) depending on the question type. This allows us to provide more examples for each question type allowing the model to learn the sub-task more effectively.]

To fit these questions within GPT3's context limit (2049 tokens), we generate a smaller version of the CommaQA-E dataset and of the compositional generalization split such that we can fit at least four examples in the context for CoT prompts. The CoT prompts describe the sequence of facts needed to arrive at the answer (see App. 12 for all the prompts).

[IMAGE: commaqa_gpt3.pdf]

For DecomP, we can separate the task of decomposition (independent of the context) from the sub-tasks of single-hop question answering. As shown in Fig. 8, we provide examples of the context-independent decomposition in the decomposer prompt and use the separate sub-task prompts to teach the QA skill over the given context. Additionally, we can choose the granularity of decomposition to trade off human effort for increased accuracy. For example, we could have single QA prompt to handle all the questions or create QA prompts for different classes of questions. In our experiments, each sub-task prompt contains 8 QA examples (2 questions/para). We evaluate three different prompts and report the average results.

We make three observations on CommaQA. **DecomP is more accurate than CoT** irrespective of the granularity of decomposition or the evaluation split. **Finer grained decomposition can help improve task performance** by providing more examples for each class of questions, which in turn increases single-hop QA accuracy. **DecomP generalizes to new compositions** such as the compositional generalization split of CommaQA, which tests models on unseen compositions of relations observed in the training set. While CoT has a drop in score, both decomposition-based approaches actually get a small bump (the subset of relations used in this split are easier for our QA models).

## Open-Domain Question Answering

Next, we demonstrate the ability of our approach to integrate external API calls on the task of open-domain multihop question answering. We evaluate our approach on three datasets: (1) 2WikiMultihopQA [xanh2020_2wikimultihop] (2) MuSiQue [musique] (3) HotpotQA [hotpotqa]. We describe the open-domain versions of these datasets in more detail in App. 6. We use the Codex (code-davinci-002) model here since it can fit the much longer contexts needed. We also evaluate the impact of model scale on DecomP by using models from the Flan-T5 family: Flan-T5-Large (0.7B), Flan-T5-XL (3B), and Flan-T5-XXL (11B).

[IMAGE: Figure 9 - hotpotqa_prompt_detailed.pdf - The prompt used to answer open-domain multihop questions using Elasticsearch-based retrieval. The retrieve_odqa prompt is given in Fig. 6.]

Fig. 9 shows the decomposition prompt we use. The decomposer generates (singlehop) sub-questions and delegates them to `retrieve_odqa` (described in Fig. 6). As we showed earlier, this module retrieves relevant documents then uses an RC model to answer. `retrieve_odqa` returns both the answer and the documents, allowing subsequent sub-questions to use the answers (e.g. "Mack Rides") and the `multihop_rcqa` model to use the documents. The final `multihop_rcqa` model is prompted to produce the answer directly or using CoT given K paragraphs.

We compare our approach against two baselines: **A. No Context (No-Ctxt),** A closed-book setting baseline where the model must rely only on its parametric knowledge. **B. NoDecomp Context (NoDecomp-Ctxt),** A simple retrieval baseline where we retrieve K paragraphs using the multi-hop question as the input and use that as context. For both NoDecomp-Ctxt and Decomp-Ctxt, K is selected by hyperparameter tuning (App. 6). We manually annotate CoTs and decompositions for 20 training set questions, and sample 3 prompts of 15 questions each for all approaches. The detailed prompts are given in the Appendix 12. We evaluate on 300 held-out dev questions in each dataset.

[IMAGE: Figure 10 - odqa_codex_direct_bar.pdf and odqa_flanxxl_direct_bar.pdf - Answer F1 on three open-domain QA datasets using two base LMs: Codex (left) and Flan-T5-XXL (right) with direct prompting. Decomp-Ctxt models (ours) significantly outperforms the No-Ctxt models (no retrieval) in all settings and also outperforms our strong retrieval baseline (NoDecomp-Ctxt QA), with the exception of Codex on HotpotQA where it is comparable. See App. 6.3 for results on smaller Flan-T5 models and CoT prompting.]

We present results on all three datasets with direct QA prompts in Fig. 10 with other results in App. 6. The Decomp-Ctxt models performs significantly better than No-Ctxt models in all the settings showing that external knowledge can be leveraged to improve few-shot models on open-domain mulithop QA. Furthermore, we show that our Decomp-Ctxt models outperform the strong retrieval baseline (NoDecomp-Ctxt) in all settings except one (Codex with HotpotQA). Finally, we show that even with the much smaller Flan-T5-XXL model, Decomp-Ctxt outperforms all the baselines and can even achieve scores comparable to the Codex-only systems.

## Additional Results

**Post-processing CoT for error correction** DecomP also allows us to create a targeted sub-task handler to focus on the source of error in any system. For example, CoT for arithmetic reasoning often rely on patterns (`answer is .*`) to extract answers but the CoT does not always fit this pattern. Instead, we can assign the answer extraction to a better sub-task handler (GPT3) and reduce these types of errors. This results in a 17 pt improvement on MultiArith (78 -> 95) and 14 pt improvement on GSM8K (36 -> 50.6) compared to CoT prompting (details in App. 7).

While DecomP outperforms the baselines in aggregate, we also see the **gains of DecomP are consistent across prompt choices** (see App. 9) **and decomposition schemes** (see App. 10).

# Conclusion

We proposed a new approach, Decomposed Prompting, to solve complex tasks using few-shot prompts, by decomposing them into a prompting program built out of simpler sub-tasks. Drawing inspiration from software libraries, our decomposer and shared sub-tasks are designed in a modular fashion: they use their own few-shot prompts, allowing one to independently optimize each prompt, decompose a sub-task further if necessary, or even seamlessly replace it with a symbolic system. We show that Decomposed Prompting outperforms prior work on four different tasks and generalization settings, establishing it as an effective few-shot paradigm for solving complex tasks.

# Appendix: Open Domain QA Details

## Retrieval Corpuses for Open Domain QA

We use HotpotQA in the fullwiki setting where it comes with the associated Wikipedia corpus for open-domain QA. 2WikiMultihopQA and MuSiQue, however, are originally reading comprehension datasets. Questions in 2WikiMultihopQA and MuSiQue are associated with 10 and 20 paragraphs respectively. To turn these datasets into open-domain QA datasets, we create a corpora for each dataset by combining all the paragraphs in the train, dev and test questions. As a result we get a corpus size of 430,225 paragraphs for 2WikiMultihopQA and 139,416 for MuSiQue.

## Hyperparameter Tuning for Open Domain QA

We treat the number of paragraphs to retrieve (K) in NoDecomp-Ctxt and Decomp-Ctxt models as a hyperparameter. We select it based on a grid search on a set of values to maximize performance on a held out set of 100 questions for each dataset. For NoDecomp-Ctxt, we search K in {6, 8, 10} for GPT3 models and K in {2, 4, 6, 8} for Flan-T5-_ models. For Decomp-Ctxt, we search K in {2, 4, 6} for GPT3 and Flan-T5-_ models. Note that the ranges are different between GPT3 and Flan-T5-\* as GPT3 can fit in more number of tokens. The ranges are different for NoDecomp-Ctxt and Decomp-Ctxt as K refers to number of paragraphs retrieved in each round of retrieval, and NoDecomp-Ctxt has only one step of retrieval whereas Decomp-Ctxt usually has multiple retrieval steps.

## Additional Results

### MuSiQue

[IMAGE: Figure 11 - musique_cot_bar.pdf and musique_direct_bar.pdf - Results on MuSiQue dataset]

We present all the results on the MuSiQue dataset in Fig. 11. Across all settings, we can see that retrieval helps substantially (large gains over No-Ctxt QA) with further improvements achieved by our DecomP-based Decomp-Ctxt QA model.

### HotpotQA

[IMAGE: Figure 12 - hotpotqa_cot_bar.pdf and hotpotqa_direct_bar.pdf - Results on HotpotQA dataset]

We present all the results on the HotpotQA dataset in Fig. 12. On this dataset too, we can see large gains by incorporating retrieval but the gains from using DecomP are mostly seen in the smaller models.

### 2WikiMultihopQA

[IMAGE: Figure 13 - 2wiki_cot_bar.pdf and 2wiki_direct_bar.pdf - Results on 2WikiMultihopQA dataset]

We present all the results on the 2WikiMultihopQA dataset in Fig. 13. On this dataset, we can see large gains by incorporating retrieval and also observe substantial gains by incorporating DecomP (as compared to NoDecomp-Ctxt).

# Appendix: Math QA

We apply Decomposed Prompting to two math QA datasets: GSM8K [cobbe2021gsm8k] and MultiArith [roy-roth-2015-solving]. For Chain-of-thought, we used the original prompts for math reasoning [Wei2022ChainOT].

Most CoT systems [Wei2022ChainOT; Wang2022SelfConsistencyIC] rely on extracting the answer by finding the number following "answer is". However, this may not always be accurate.

Rather than relying on patterns with limited generalization, we can use a language model to extract the answer more reliably. Specifically, we use Decomposed Prompting to decompose the task into first identifying the chain-of-thought reasoning and then using a second GPT3-based sub-module to extract the answer from the CoT. We show examples of our prompts here (full prompt in App. 12):

[IMAGE: Figure 14 - math_results.pdf and commaqa_scale.pdf - As the models become weaker (davinci-001) and smaller (curie-001), the performance of all the models drop. DecomP still outperforms CoT till the performance reaches close to zero with curie.]

We present our results in Fig. 14. On the GSM8K data set, we outperform CoT by 14 points. On the MultiArith dataset, we achieve a 17 pt improvement compare to CoT. While this is a simple change, it illustrates the possibility of using DecomP for other complex answer types, e.g. non-extractive answer generation from chain-of-thoughts.

# Appendix: Effect of Scale on CommaQA

We evaluate text-curie-001, text-davinci-001 and text-davinci-002 on the CommAQA dataset. Since the curie-001 and davinci-001 have a smaller context window size, we further reduced our prompts to fit within their context windows (2048 tokens). As shown in Fig. 14, both CoT and DecomP are effected by the model size.

# Appendix: Results on all prompts

## Per-Prompt Result on Letter Concatenation

[IMAGE: Figure 15 - all_result_letter_cat_n3.pdf, all_result_letter_cat_n4.pdf, all_result_letter_cat_n5.pdf - Across all values of N and different prompts (P1, P2 and P3), DecomP outperform chain-of-thought reasoning and even least-to-most prompting.]

We present the results of the letter concatenation task (with space delimiter) for different values of N in Fig. 15. Our results are stable across the different prompts (P1, P2 and P3) and always outperform CoT and Least-to-Most prompting.

## Per-Prompt Results on CommaQA

[IMAGE: Figure 16 - all_result_commaqa_test.pdf and all_result_commaqa_compgen.pdf - Results of different prompts on the CommAQA dataset.]

We also present the results of all the prompts on the CommAQA dataset in Fig. 16. Here too, we can observe that DecomP outperforms CoT on each prompt set.

# Appendix: Effect of Decomposition Scheme

To evaluate the effect of the decomposition scheme, we experiment with two other simple decomposition structures for the letter concatenation and reversal tasks.

#### Letter Concatenation

For letter concatenation, we consider an alternate scheme where we use GPT3 to generate each question rather than loop over the answers.

By using the decomposer prompt model to generate the sub-questions, we can be more robust to formatting issues in the output answers, e.g., we can expect GPT3 to still generate the appropriate sub-questions even if the first answer is not a valid array. However, the generated sub-questions may not correctly use all the elements of the list (change in order, missed element, repeated elements, etc).

#### List Reversal

For list reversal, instead of splitting into halves, we take the tail of the list, reverse it and then concatenate it to the head. i.e. reverse(list) = reverse(list[1:]) + list[0]. This requires more GPT3 calls (O(n)) compared to the original approach of splitting the list into halves (O(log(n))).

[IMAGE: Figure 17 - letter_cat_schema.pdf and reverse_list_schema.pdf - Recursively reversing the tail of a list is more stable at longer lengths but comes at the cost of more calls to GPT3.]

In both these cases, we noticed that the performance did not drop as shown in Fig. 17. On the letter concatenation task, the results were exactly the same. The new reversal decomposition schema was actually stronger on longer inputs at the cost of more calls to GPT3 (O(ln(n)) using binary splits vs O(n) one element at a time). Both these decomposition schemes are still better than CoT.

[IMAGE: Figure 18 - letter_cat_semic.pdf - EM Results on the k-th letter concatenation task (k=3) using semi-colon as delimiter with different values for N, the number of words in the input. DecomP always outperforms and generalizes better than CoT.]

# Appendix: Error Analysis

## Letter Concatenation

### DecomP

We analyzed the errors in DecomP on the letter concatenation task and only found errors in the sub-task execution.

### CoT w/ rollout

We analyzed the errors in CoT on the letter concatenation task and found similar errors during the generation of CoT. But the frequency of these errors was higher than DecomP, as it is not possible to effectively teach each sub-task with CoT.

## CommaQA

Similarly in CommaQA, the errors are mostly due to sub-task errors, which in this dataset correspond to answering single-hop questions. CoT also makes the same types of errors but they are more frequent since this QA sub-task can not be delegated to a specialized prompt in CoT. Since all errors are of this type, we show only one example here.

# Appendix: Task Prompts

We have provided the task prompts for all the datasets for COT and our Decomposed Prompting approach.

#### CoT

Since CoT methods also perform 2-step reasoning: first generate the chain-of-thought and second extract the answer from the CoT, we use the same decomposition-based framework for COT baselines too. GPT3 generates the chain-of-thought during the "decomposition" step and a regex-based answer extractor `extract` (`'.* outputs "(.*)"\.'`) then takes this CoT and generates the answer. In some cases, the module name is skipped in the prompt (the CoT is sent to the extractor by default).

#### Operators

In this work, we use the same operators as defined by Khot2022HeyAC. Their `select` operator is just the basic operator that replaces references to an answer index with its answer. When not specified, `select` is assumed to be the default operator. In addition, we consider two operators in our experiments: `project_values` and `project_values_flat_unique`.

- `project_values`: This operator takes a list answer #i = X and iterates over it to generate new questions by replacing mentions of #i i.e. Q = [q.replace(#i, x) for x in X]. The answer to each question is simply concatenated to get the final answer i.e. A = [model(q) for q in Q]. We refer to this as `foreach` for simplicity in the main text.

- `project_values_flat_unique`: This operator performs the same steps as `project_values` but then additionally flattens the list and only returns the unique entities in the flattened list. We refer to this as `foreach_merge` in the main text for simplicity.

## Letter Concatenation

We show one of the prompts used for experiments here. The entire set of prompts is provided as supplementary material.

### Decomposed Prompting

Prompts: decomp, split, str_position, merge, arr_position

### COT with rollout

Prompt: COT w/ rollout

### COT

Prompt: COT

### Least-to-most w/ rollout

Prompts: Least-to-most Decomp, Least-to-most COT(l2m)

### Alt DecomP schema (Generate Each Sub-Question)

Prompt: decomp

## Sequence Reversal

### Split Reversal

The prompts in this section implement Algorithm for split-based reversal.

**Algorithm SplitReverse(x):**

```
n <- |x|/2
l <- x_1,...,x_n
l^R <- SplitReverse(l)
r <- x_{n+1},...,x_{|x|}
```

Prompts: reverse, remove_numbers, join, cot, unrolled_decomp, reverse (tail)

## Long-Document QA

We show one of the prompts used for CommaQA experiments here. The entire set of prompts is provided as supplementary material.

### Decomposed Prompting: (coarse)

Prompts: decomp, qa

### Decomposed Prompting: (fine)

Prompts: decomp, aw_qa, pos_qa, simp_qa

### COT

Prompt: COT

## Shorter Prompts for Smaller Context Windows

Prompts: qa(small), aw_qa(small), pos_qa(small), simp_qa(small), COT(small)

## Math QA

The decomposer here deterministically calls `cot` to generate the CoT and then calls `gpt_ans` to extract the answer.

Prompts: cot, gpt_ans

## Open Domain QA

The prompts in this section implement Decomposed Prompting approach to open-domain multihop QA. For brevity we've included prompts for 5 of 20 randomly sampled questions. The full prompts are attached with the submission and will also be released with the code. Note that we selected a set of 100 questions from the development set to tune the hyperparameter (number of paragraphs to retrieve for all of the retrieval-based approaches).

### HotpotQA

Prompts: decomp, retrieve_odqa, singlehop_titleqa, multihop_titleqa (direct), multihop_titleqa (cot)

### 2WikiMultihopQA

Prompts: decomp, retrieve_odqa, singlehop_titleqa, multihop_titleqa (direct), multihop_titleqa (cot)

### MuSiQue

Prompts: decomp, retrieve_odqa, singlehop_titleqa, multihop_titleqa (direct), multihop_titleqa (cot)
