# Abstract

It remains an open question whether incorporating external knowledge benefits commonsense reasoning while maintaining the flexibility of pretrained sequence models. To investigate this question, we develop generated knowledge prompting, which consists of generating knowledge from a language model, then providing the knowledge as additional input when answering a question. Our method does not require task-specific supervision for knowledge integration, or access to a structured knowledge base, yet it improves performance of large-scale, state-of-the-art models on four commonsense reasoning tasks, achieving state-of-the-art results on numerical commonsense (NumerSense), general commonsense (CommonsenseQA 2.0), and scientific commonsense (QASC) benchmarks. Generated knowledge prompting highlights large-scale language models as flexible sources of external knowledge for improving commonsense reasoning. Our code is available at [github.com/liujch1998/GKP](github.com/liujch1998/GKP)

# Introduction

It remains an open research question whether external knowledge is needed for commonsense reasoning. On one hand, a substantial body of prior work has reported that integrating external knowledge can help improve task performance [mitra2019additional; bian2021benchmarking *inter alia*], especially if the knowledge is high quality (e.g. hand-crafted by experts). On the other hand, recent leaderboards are often dominated by large-scale pretrained models that are fine-tuned on a target benchmark [khashabi-etal-2020-unifiedqa; lourie2021unicorn], suggesting that the benefits of external knowledge may wash away as the underlying models increase in size and are pretrained on ever larger amounts of raw text.

Even if external knowledge is found to be effective on a particular task, _flexibility_ remains a fundamental hurdle to integrating external knowledge, as many benchmarks currently lack appropriate knowledge bases with sufficient coverage. Furthermore, prior methods often require task-specific, custom supervision for knowledge integration [mitra2019additional; chang-etal-2020-incorporating], introducing a burden for rapidly adapting new pretrained models to a wide variety of tasks.

In this paper, we investigate whether external knowledge can be helpful for commonsense reasoning, even on top of the largest state-of-the-art pretrained models (e.g. T5-11b [raffel2019exploring] and its variants), with a focus on four recent commonsense benchmarks. To facilitate easier adaptation with any zero-shot or finetuned models, we propose an approach that does not require access to a structured knowledge base or joint finetuning for knowledge integration.

The key insight behind our method, Generated Knowledge Prompting (sketched in [fig:diagram]), is that we can generate useful knowledge from a language model, then provide the knowledge as an input prompt that is concatenated with a question. To support a variety of settings without finetuning, the quality and flexibility of knowledge is crucial. We propose a simple, yet effective, method that elicits _knowledge statements_ (i.e. knowledge expressed as natural language statements) from generic language models in a few-shot setting. Compared to prior work that elicits knowledge via clarification questions [shwartz-etal-2020-unsupervised] or contrastive explanations [paranjape-etal-2021-prompting], our approach can generate knowledge flexibly, beyond the scope of pre-defined templates ([tab:examples]).

Experiments show that our method improves both zero-shot and finetuned models on numerical commonsense (NumerSense [lin-etal-2020-birds]), general commonsense (CommonsenseQA [talmor-etal-2019-commonsenseqa], CommonsenseQA 2.0 [talmor2021commonsenseqa]), and scientific commonsense (QASC [khot2020qasc]) benchmarks, setting a new state-of-the-art on three of these datasets. It outperforms the template-based knowledge generation method _self-talk_ [shwartz-etal-2020-unsupervised], while performing comparably to retrieval-based systems.

We find three factors contribute to the performance of generated knowledge prompting: (i) the _quality_ of knowledge, (ii) the _quantity_ of knowledge where the performance improves with more knowledge statements, and (iii) the strategy for integrating knowledge during inference. Our qualitative analysis suggests that the generated knowledge statements cover a variety of types, and can transform commonsense question answering to explicit reasoning procedures, e.g. deduction, that are supported by off-the-shelf and finetuned language models.

# Generated Knowledge Prompting

A multiple-choice commonsense reasoning task involves predicting an answer `latex $a\in A_q$ ` given a question `latex $q\in Q$ `, where the set of choices `latex $A_q$ ` is finite and can vary by question, and both questions and answers are variable-length text sequences. Our method answers commonsense questions in two steps.

The first step is _knowledge generation_, where we use a language model `latex $p_G(k|q)$ ` to generate knowledge statements conditioned on the question:

```latex
$$\begin{align*}
K_q &= \{ k_m : k_m \sim p_G(k|q), m = 1 \ldots M \},
\end{align*}$$
```

where each knowledge statement `latex $k_m$ ` is a variable-length text sequence. Intuitively, each statement contains information that is helpful for answering the question (e.g. [tab:examples]).

The second step is _knowledge integration_, where generated knowledge is integrated into the decision process of a language model used for inference:

```latex
$$\begin{align*}
\hat{a} &= \mathop{\mathrm{arg\,max}}_{a \in A_q}{p_I(a|q,K_q)}.
\end{align*}$$
```

In contrast, the _vanilla_ setting of using the inference model without knowledge is represented by `latex $\hat{a} = \mathop{\mathrm{arg\,max}}_{a \in A_q}{p_I(a|q)}$ `.

Next, we describe the knowledge generation and integration steps in detail.

## Knowledge Generation

We generate question-related knowledge statements by prompting a language model. The prompt consists of an instruction, a few demonstrations that are fixed for each task, and a new-question placeholder. The demonstrations are human-written, and each consists of a question in the style of the task and a knowledge statement that is helpful for answering this question. For a given task, we write five demonstrations using the format in [tab:prompt].

We write questions (or select them from the training set, when available) that are representative of challenges posed by the task (e.g. numerical commonsense, scientific commonsense). We pair each question with a knowledge statement that turns the commonsense problem posed by the question into an explicit reasoning procedure, without directly answering the question. For example, the knowledge statement _Birds have two wings. Penguin is a kind of bird._ is helpful for the question **Penguins have <mask> wings**, because it turns the problem into deductive reasoning. Meanwhile, _Penguins have two wings._ would be a poor knowledge statement to demonstrate according to our guideline.

When generating knowledge for a new question `latex $q$ `, we plug the question into the placeholder, and repeatedly sample generated continuations of this prompt to obtain a set of knowledge statements `latex $K_q = \{ k_1, k_2, \hdots, k_M \}$ `. For full prompts on all the tasks we evaluate on, see Appendix 7.2.

## Knowledge Integration via Prompting

In the knowledge integration step, we use a language model -- called the inference model -- to make predictions with each generated knowledge statement, then select the highest-confidence prediction. Specifically, we use each knowledge statement to prompt the model, forming `latex $M$ ` knowledge-augmented questions:

```latex
$$\begin{align*}
q_0 = q, q_1 = [k_1 || q], \hdots, q_M = [k_M || q],
\end{align*}$$
```

where `latex $[\cdot || \cdot]$ ` denotes text concatenation.

We compute an aggregated score for each answer choice `latex $a$ ` using the augmented question that best supports it under the inference model:

```latex
$$\begin{align}
p_I(a|q,K_q) &\propto \max_{0 \le m \le M}{p_I(a|q_m)}. \label{eqn:max_ensembling}
\end{align}$$
```

Intuitively, this favors knowledge statements that strongly support one of the choices.

The predicted answer is then:

```latex
$$\begin{align*}
\hat{a} &= \mathop{\mathrm{arg\,max}}_{a \in A_q}{\max_{0 \le m \le M}{p_I(a|q_m)}},
\end{align*}$$
```

which is the choice that gets most support from one of the knowledge statements. This prediction uses a single knowledge statement, which we refer to as the _selected knowledge_:

```latex
$$\begin{align*}
\hat{k} &= k_{\hat{m}} \text{ where } \hat{m} = \mathop{\mathrm{arg\,max}}_{0 \le m \le M}{\max_{a \in A_q}{p_I(a|q_m)}}.
\end{align*}$$
```

The inference model may be any existing language model taken off-the-shelf (i.e. zero-shot) or finetuned on the task. We do not do any further finetuning with knowledge prompting.

# Experimental Setup

Here, we describe the implementation details of our method and how they are adapted to each task.

For knowledge generation, we use GPT-3 [brown2020language] as the underlying language model, where our few-shot prompting method is most effective. We generate `latex $M=20$ ` knowledge statements for each question with nucleus sampling `latex $p=0.5$ ` [holtzman2019curious], and discard repetitions and empty strings. Generation is terminated when it exceeds 64 tokens or hits the newline token.

For inference, we use off-the-shelf T5 [raffel2019exploring] and GPT-3, as well as finetuned models that are state-of-the-art on each dataset, including UnifiedQA (UQA) [khashabi-etal-2020-unifiedqa] and Unicorn [lourie2021unicorn]. See details in the task setup below.

## Datasets and Task Setup

We evaluate our method on four commonsense reasoning datasets which cover a variety of challenges and problem formats.

### NumerSense

[lin-etal-2020-birds] consists of numerical statements about common objects and concepts where for each sentence we need to recover a masked number word. The choices are integers ranging from zero to ten, plus the word _no_, so the task can be framed as a multiple-choice problem. Since NumerSense is a diagnostic dataset, we only use zero-shot inference models, which is the current SOTA. We follow @stanford who uses the state-of-the-art zero-shot T5 with text-infilling setup and select the choice with highest likelihood on its token(s). We also implement zero-shot GPT-3 inference, where we plug in each choice to the question and compute the choice probability as the generative probability of the entire sentence, normalized over all the choices.

### CommonsenseQA (CSQA)

[talmor-etal-2019-commonsenseqa] is a 5-way multiple-choice QA dataset about common world scenarios. We do inference with the zero-shot and finetuned T5 models. For zero-shot T5, we format the question as text-infilling, and predict the choice with highest sequence-to-sequence language modeling probability. For finetuned T5 (including UnifiedQA which is SOTA), we use the same setup as @khashabi-etal-2020-unifiedqa.

### CommonsenseQA 2.0 (CSQA2)

[talmor2021commonsenseqa] is a binary classification dataset where we need to judge whether commonsense statements are true or false. We only do inference with the finetuned model, due to poor calibration of zero-shot models on this dataset. We use finetuned Unicorn [lourie2021unicorn], which is the current SOTA, following the setup in @talmor2021commonsenseqa.

### QASC

[khot2020qasc] is an 8-way multiple-choice QA dataset about grade school science. This dataset also includes two pieces of background knowledge per question, whose composition fully answers the question. We do inference with zero-shot T5 and finetuned T5 (including UnifiedQA which is SOTA), using the same setups as CSQA.

## Inference Model Setup

Since all the inference models we use (T5, UnifiedQA, Unicorn) are generative language models, the support to a choice by the inference model is:

```latex
$$\begin{align*}
& p_I(a | q) = \frac{\exp s_I(a | q)}{\sum_{a' \in A_q}{\exp s_I(a' | q)}}, \\
& \text{where } s_I(a | q) = \sum_{i=1}^{|a|}{\log{p(a_i | a_{<i}, q)}},
\end{align*}$$
```

and `latex $a_i$ ` is the `latex $i$ `-th token of choice `latex $a$ `.

## Knowledge Generation Baselines

We study the impact of our knowledge generation method (shorthanded as `latex $K$ `) by comparing with the following baselines:

#### No knowledge

We refer to inference without any knowledge statements as the _vanilla_ baseline.

#### Random sentences

Sampling random sentences from the language model without conditioning on the question. We use the same implementation setup as our knowledge generation method (i.e. also using GPT-3, with the same hyperparameters).

#### Context sentences

Sampling sentences from the context of the question. This is implemented by sampling text continuations of the question from the language model. We use the same implementation setup as our knowledge generation method.

#### Template-generated knowledge

Self-talk [shwartz-etal-2020-unsupervised] uses manually-designed templates to elicit knowledge statements from language models. For fair comparison, we use GPT-3 as the knowledge generator in self-talk, and bound the number of generations to `latex $M=20$ ` per question. Templates and other hyperparameters are kept the same as their original paper.

#### Retrieval-based knowledge

Instead of being generated, knowledge can be retrieved from appropriate sources. We consider the following retrieval-based methods. For NumerSense, knowledge is retrieved from sentences in Wikipedia and GenericsKB. For CSQA2, we use snippets returned by Google when querying the question. For QASC, we use the associated fact sentences that are used to create each question.

#### Answers

Instead of generating knowledge, GPT-3 can be prompted to generate direct answers to questions. In the prompts, we use the same input questions as those in knowledge generation, while replacing the knowledge statement with the ground truth answer. We consider two baselines: (1) Generate one answer per question and use this to measure the performance of the few-shot GPT-3 inference model; (2) Generate `latex $M = 20$ ` answers per question, and use these answers to prompt the SOTA inference models.

# Experimental Results

As we will show, our generated knowledge prompting method sets new state-of-the-art results on most datasets we evaluate on, and works well under both zero-shot and finetuned settings. In particular, our knowledge generation outperforms naive baselines as well as template-based knowledge generation, and is on-par with retrieval-based systems.

## Overall Performance

[tab:results] shows the results on zero-shot and finetuned models following our task setups.

#### New state-of-the-art.

We apply our method on top of the same inference model used in the previous state-of-the-art. On NumerSense, we achieve a 6% (66.18 -> 72.47) improvement over the previous best method based on the zero-shot T5 model. The previous state-of-the-art among non-retrieval methods on CSQA2 is based on the finetuned Unicorn model, upon which we improve by 2% (70.2 -> 73.03). For QASC, the previous best is based on the finetuned UnifiedQA model, upon which we improve by 3% (76.74 -> 80.33).

#### Zero-shot settings.

Columns A, B1, and D1 in [tab:results] show that our method substantially improves zero-shot inference models, by 7% to 10% across NumerSense (64.05 -> 72.47), CSQA (39.89 -> 47.26), and QASC (44.89 -> 55.00).

#### Finetuned settings.

Columns B2, C, and D2 in [tab:results] indicate that our method consistently improves upon the vanilla baseline set by finetuned inference models (though by smaller margins than in the zero-shot settings).

## Knowledge Generation Methods

[tab:results] reports the performance with different knowledge generation baselines. Generally, random sentences barely help and even hurt the inference model, whereas context sentences of the question provide some gain. In contrast, knowledge generated by our method consistently leads to substantial performance improvements, which implies that our knowledge is of high quality.

#### Knowledge is an essential factor.

The few-shot GPT-3 model is poorly calibrated to directly answer commonsense questions, underperforming our best models by 14% to 20% across all tasks. Even when we use answers generated by few-shot GPT-3 to prompt the SOTA inference models, this still significantly falls behind our method on almost all the tasks and models we consider (with one exception -- CSQA with T5 inference). Through the medium of _knowledge_, our method can effectively leverage useful information possessed by GPT-3 to help improve even the SOTA models on various commonsense reasoning tasks.

#### Our knowledge outperform template generated knowledge.

We compare our knowledge generation method with the template-based _self-talk_ on the CSQA dev set. (CSQA is the only task we experiment with that has self-talk templates available.) Our method leads to a larger improvement over the T5-11b baseline than self-talk (by 1.89%), showing that it is better at eliciting helpful knowledge from models.

#### Our knowledge is comparable with retrieval-based knowledge.

On NumerSense, the retrieved knowledge only improves inference performance by 0.18% on test-core and 1.02% on test-all, while our method further outperforms it by 8.83% and 7.37%, respectively. This shows that knowledge retrieved from a loosely-related knowledge base can be far less useful than our generated knowledge. On CSQA2, although we are not able to beat the web-retrieved knowledge, our method still bridges the performance gap without referring to Google search. For QASC, the "retrieved" knowledge is actually gold knowledge from a knowledge base that was used to construct the dataset. As a result, our generated knowledge falls significantly short of the retrieved knowledge. In summary, our generated knowledge is roughly comparable with retrieved knowledge in terms of downstream performance, and is most valuable when there is no appropriate in-domain knowledge base to retrieve from.

## Analysis

#### Better performance with more knowledge.

We analyze the impact of the number of generated knowledge statements, `latex $M$ `, and show the results in [fig:results_qasc_quantity]. Generally, the performance increases with the quantity of knowledge statements. It saturates at `latex $M=20$ ` and begins to decline when more knowledge statements are introduced, which may be because more noisy knowledge is generated.

#### The knowledge integration method.

In addition to the knowledge integration method described in Section 2.2, we experiment with two alternatives: Mixture-of-Experts (MoE) and Product-of-Experts (PoE) [hinton2002training]. These make the following modifications to [eqn:max_ensembling], respectively:

```latex
$$\begin{align}
\text{MoE: } p_I(a|q,K_q) &\propto \sum_{0 \le m \le M}{p_I(a|q_m)}, \\
\text{PoE: } p_I(a|q,K_q) &\propto \prod_{0 \le m \le M}{p_I(a|q_m)}.
\end{align}$$
```

The results in [tab:results_qasc_ensembling] indicate that our knowledge integration method -- i.e. adaptively choosing the best knowledge to rely on -- is best among the three.

#### Lightweight inference models and amplification.

We found that the size of inference model affects the magnitude of improvement. [fig:results_numersense_size] shows the NumerSense performance gain on top of different sizes of inference model. As we use smaller inference models, the performance gain increases drastically. In particular, with our method the smallest T5 model is as powerful as the T5-3b baseline, and T5-large outperforms the GPT-3 baseline. This indicates that model-generated knowledge can enable high performing, yet lightweight, inference models. Furthermore, the improvement does not diminish as the inference model becomes as big as the knowledge generation model, as the inference by GPT-3 can benefit by 9.0% from the knowledge elicited from itself. This indicates that our method can somewhat _amplify_ the useful knowledge already possessed by the model, leading to better predictions.

#### The size of knowledge generation model.

[fig:results_numersense_knowledge] shows the NumerSense performance gain when using different sizes of GPT-3 as the knowledge generation model. On top of the T5-11b inference model, The 6.7B knowledge model gives a 5.0% improvement, narrower than the 10.5% improvement given by the 175B knowledge model. The 1.3B and 0.4B knowledge models do not give a significant improvement. Therefore, we do not necessarily need the largest version of GPT-3 as the knowledge source, though we do need the model to be relatively large in order to generate useful and reliable knowledge.

## Human Evaluation

We conduct a human evaluation on NumerSense and QASC to study the quality of generated knowledge and the interpretability of its impact on task performance.

#### Evaluation.

We report the quality of knowledge statements along four axes: (1) _Grammaticality_: whether it is grammatical; (2) _Relevance_: whether it is relevant to the topic or concepts mentioned on the question; (3) _Factuality_: whether it is (mostly) factually correct; and (4) _Helpfulness_: whether it helps answering the question in an either direct or indirect way, and may fall into one of the three categories: helpful (i.e. supports the correct answer), harmful (i.e. negates the correct answer or supports an incorrect answer), or neutral (neither helpful nor harmful). These metrics are adapted from @shwartz-etal-2020-unsupervised and are defined in Appendix 7.3.

From each dataset, we sample up to 50 _selected knowledge_ (Section 2.2) that change the correctness of T5-11b's prediction (i.e. rectifies model prediction from wrong to right, or misleads model prediction from right to wrong). The knowledge are labeled by two NLP experts and a moderate level of agreement was reached (Fleiss Kappa `latex $\kappa = 0.57$ ` [landis1977measurement]). To ensure objectivity, it is not revealed to the annotators whether the knowledge rectifies or misleads the model prediction.

#### Results.

[fig:human] summarizes the results. The vast majority of selected knowledge are grammatical and relevant to the question, and 83% of them are factually correct. 72% are seen as being helpful for answering the question according the human evaluators, whereas 13% are harmful. Out of the knowledge statements that rectify the model predictions, 93% are labeled as helpful by the human evaluators; in contrast, when the knowledge statement misleads the model, only 21% are labeled as helpful, and 39% harmful. Of the knowledge deemed helpful by human _and_ rectifies model prediction, 95% are factual, while of those deemed harmful by human _and_ misleads model prediction, 86% are non-factual, suggesting that improving knowledge factuality is a promising path towards more helpful knowledge. We also analyzed the non-selected knowledge and found that these statements have slightly lower factuality and helpfulness than the selected knowledge.

## Qualitative Examples

[tab:qualitative] shows a few examples where the generated knowledge rectifies model prediction. Due to space constraints we only show the _selected knowledge_ (Section 2.2) for each question. In all examples, the model without prompted knowledge assigns a higher score to an incorrect answer than the correct answer, while with knowledge prompting, the correct answer is assigned a much higher score. Prompting with generated knowledge can transform commonsense reasoning into explicit reasoning procedures such as paraphrasing, induction, deduction, analogy, abductive reasoning, logical elimination, negation, and numerical reasoning.

# Related Work

#### Knowledge can be elicited from pretrained language models.

Numerous works have shown that pretrained language models implicitly contain a large amount of knowledge that can be queried via conditional generation [davison-etal-2019-commonsense; petroni-etal-2019-language; jiang-etal-2020-know]. Consequently, these models can directly perform inference on tasks like commonsense reasoning [trinh2018simple; yang-etal-2020-designing], text classification [shin-etal-2020-autoprompt; puri2019zero], and natural language inference [shin-etal-2020-autoprompt; schick-schutze-2021-exploiting]. Inspired by these observations, we elicit question-related knowledge in an explicit form from language models and use them to guide the inference.

#### Leveraging external knowledge for commonsense reasoning.

Some work uses external commonsense knowledge bases to make improvements on various NLP tasks, including commonsense reasoning. One approach is to inject commonsense knowledge into language models, either by pretraining on knowledge bases [ma2021knowledge; chang-etal-2020-incorporating; mitra2019additional; zhong2019improving] or finetuning the model so that it can reason with additional retrieved knowledge [chang-etal-2020-incorporating; mitra2019additional; bian2021benchmarking]. Another direction is to ground the question into a knowledge graph and do inference with graph-based reasoning [lin-etal-2019-kagnet; lv2020graph; yasunaga-etal-2021-qa].

A common prerequisite of these methods is a high-quality, high-coverage, in-domain commonsense knowledge base [ma-etal-2019-towards]. Some commonsense reasoning datasets are derived from existing knowledge bases; for example, CommonsenseQA [talmor-etal-2019-commonsenseqa] is derived from ConceptNet [speer2017conceptnet], and Social IQA [sap-etal-2019-social] is derived from ATOMIC [sap2019atomic]. For such datasets, it is natural to elicit related knowledge from the underlying knowledge base that derived them, and typically this would demonstrate considerable gains [mitra2019additional; chang-etal-2020-incorporating]. However, if there is a domain mismatch between the dataset and the knowledge base, such gains tend to diminish [mitra2019additional; ma-etal-2019-towards]. This becomes a bottleneck when encountering datasets that have no suitable knowledge base (e.g. NumerSense [lin-etal-2020-birds] and CommonsenseQA 2.0 [talmor2021commonsenseqa]), or when the system needs to handle commonsense queries that do not fit in any of the commonsense domains represented by an existing knowledge base. Our work overcomes this difficulty by leveraging pretrained language models as the source of commonsense knowledge.

#### Adding generated text during inference.

Recently, several works show that model performance on commonsense reasoning can be boosted by augmenting the question with model-generated text, such as clarifications, explanations, and implications. Self-talk [shwartz-etal-2020-unsupervised] elicits clarifications to concepts in the question and appends them to the inference model input. Contrastive explanations [paranjape-etal-2021-prompting] prompts inference models with generated explanations that contrast between two answer choices. The aforementioned methods depend on task-specific templates to inquire the generator, which means they are only capable of eliciting a limited variety of knowledge and require careful hand-crafting to transfer to new tasks. Other explanation-based methods [latcinnik2020explaining; rajani-etal-2019-explain] finetune the generator model so that it produces explanations that are used for question augmentation. DynaGen [bosselut2021dynamic] uses pretrained commonsense models to generate implications of a question and builds a dynamic graph of natural language statements on which reasoning is conducted. However, its usage of COMeT [bosselut-etal-2019-comet] as the generator confines its applicability to the social commonsense domain. Our work contributes to this general line of research, yet different from these previous methods that elicit knowledge with task-specific templates or from finetuned knowledge generators, our method requires only a few human-written demonstrations in the style of the task, making it much more flexible, easy-to-transfer, and engineering-efficient.

# Conclusion

We introduce generated knowledge prompting, a simple method to elicit and integrate knowledge from language models so as to improve performance on commonsense reasoning tasks. In particular, we generate knowledge statements by prompting a language model with task-specific, human-written, few-shot demonstrations of question-knowledge pairs. We show that knowledge can be integrated by simply plugging it in at inference time, with no need to finetune the model for knowledge integration. Our method shows effectiveness across multiple datasets, sets the new state-of-the-art on three commonsense reasoning tasks, and works under a variety of settings. The method's success highlights language models as sources of flexible, high-quality knowledge for commonsense reasoning.

# Appendix

## Comparison with Prior Methods

[tab:methods] summarizes the comparison between our generated knowledge prompting method and prior methods that add generated text to an inference model for commonsense reasoning tasks. Our method is unique because it uses few-shot demonstrations to prompt for knowledge generation, and can apply to finetuned inference models without joint finetuning with knowledge.

## Prompts for Knowledge Generation

[tab:prompt_numersense] through [tab:prompt_qasc] shows the full prompts for knowledge generation that we use for each evaluated task: NumerSense, CSQA, CSQA2, and QASC.

## Human Evaluation Guidelines

[tab:guidelines] and [tab:guidelines_2] shows the detailed guidelines we use for human evaluation of generated knowledge.

# Checklist

## Limitations and Risks

#### Limitations.

Our method is tested on a representative selection of commonsense reasoning tasks and datasets. Applying this method to other tasks may require people with moderate expertise to craft a task-specific prompt to feed into the method.

#### Risks.

It is possible that our proposed method may lower the performance of commonsense reasoning systems, if not implemented properly or using badly-designed prompts. Such risk can be mitigated by following the prompt design guidelines in this paper (Section 2.1).

## Computation

We do not train any new model in this paper. Inference is conducted on Quadro RTX 8000 GPUs and costs about 200 GPU hours in total. Knowledge generation is done with the OpenAI GPT-3 API, with an approximate cost of $500.

Our method is implemented with PyTorch and the Huggingface Transformers library.

Note: An exception is with the CSQA2 dataset, where for the best results we choose M=5 and allow for up to 128 tokens in each generation.
