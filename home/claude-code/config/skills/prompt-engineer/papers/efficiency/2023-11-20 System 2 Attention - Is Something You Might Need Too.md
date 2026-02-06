# Abstract {#abstract .unnumbered}

Soft attention in Transformer-based Large Language Models (LLMs) is susceptible to incorporating irrelevant information from the context into its latent representations, which adversely affects next token generations. To help rectify these issues, we introduce System 2 Attention (S2A), which leverages the ability of LLMs to reason in natural language and follow instructions in order to decide what to attend to. S2A regenerates the input context to only include the relevant portions, before attending to the regenerated context to elicit the final response. In experiments, S2A outperforms standard attention-based LLMs on three tasks containing opinion or irrelevant information: QA, math word problems and longform generation, where S2A increases factuality and objectivity, and decreases sycophancy.

# Introduction

Large Language Models (LLMs) are highly capable, yet they are still susceptible to making simple mistakes, which seem to display weak reasoning abilities. For example, they can be swayed to make erroneous judgments by irrelevant context [jia2017adversarial; cho2023improving; shi2023large], or by preference or opinion inherent in the input prompt, in the latter case exhibiting an issue termed sycophancy whereby the model agrees with the input [sharma2023towards].

While several approaches try to mitigate these issues through adding more supervised training data [wei2023simple] or reinforcement learning strategies [sharma2023towards] we posit that the underlying problem is inherent in the way the transformer itself is built, and in particular its attention mechanism. That is, soft attention tends to assign probability to a large portion of the context, including irrelevant portions, tends to overly focus on repeated tokens partly due to the way it is trained [holtzman2019curious; welleck2019neural], and partly due to the position encoding mechanism is also inclined to treat the context as a bag-of-words when it should not [sinha2021masked; sinha2020unnatural].

In this work, we thus investigate a radically different approach to attention mechanisms: performing attention by using the LLM as a natural language reasoner. Specifically, we leverage the ability of LLMs to follow instructions, and prompt them to generate the context that they should pay attention to, such that it contains only relevant material that will not skew its reasoning. We refer to this procedure as System 2 Attention (S2A), because we can consider the underlying transformer, and its attention mechanism, as automatic operations analogous to system 1 reasoning in humans [kahneman2011thinking]. System 2, allocating effortful mental activity, takes over in humans when we need to pay deliberate attention to a task, especially in situations where System 1 is likely to make errors [Sloman1996TheEC]. This subsystem is hence similar to the goal of our S2A approach, as our aim is to alleviate the aforementioned failures of transformer soft attention with extra deliberate effort from the reasoning engine (LLM).

We describe the class of System 2 Attention mechanisms, provide further motivation, and detail several specific implementations in [2](#sec:s2a). In [3](#sec:exp) we show experimentally that S2A can produce more factual and less opinionated or sycophantic generations than standard attention-based LLMs. In particular on the modified TriviQA dataset that includes distractor opinion in the question [sharma2023towards], S2A increases factuality from 62.8% to 80.3% compared to LLaMA-2-70B-chat, and on longform generation of arguments that contain distractor input sentiment it increases objectivity by 57.4%, and remains largely unaffected by the inserted opinions. Finally, on math word problems from GSM-IC [shi2023large] with in-topic irrelevant sentences, S2A improves accuracy from 51.7% to 61.3%.

# System 2 Attention {#sec:s2a}


[FIGURE: An illustrating example showing how LLM’s responses are adversely affected by spurious correlations in the context. Irrelevant facts about Saratoga (left) or Sunnyvale (right) change the various LLM’s...]


## Motivation

Large Language Models obtain excellent reasoning capabilities and a vast quantity of knowledge through their pre-training process. Their next-word prediction objective requires them to pay close attention to the current context. For example, if a certain entity is mentioned in a context, it is likely that the same entity will appear again later in the same context. Transformer-based LLMs are capable of learning such statistical correlations as the soft-attention mechanism allows them to find similar words and concepts within their context. While this may improve the next word prediction accuracy, it also makes LLMs susceptible to be adversely affected by spurious correlations in their context. For example, it is known that the probability of a repeated phrase increases with each repetition, creating a positive feedback loop [holtzman2019curious]. Generalizing this issue to so-called non-trivial repetition [roller2020recipes], models tend to repeat related topics in the context as well, not just specific tokens, because the latent representation is likely predictive of more tokens from that same topic space. When the context contains opinion that the model copies this is termed sycophancy [perez2022discovering], but in general we argue this issue is related to any kind of context as discussed above, not just the issue of agreement with opinions.

An example of spurious correlation is shown in [1](#fig:motivation_example). Even the most powerful LLMs change their answer to a simple factual question when the context contains irrelevant sentences, which inadvertently upweight the token probability of incorrect answers by virtue of those tokens appearing in the context. The added context in the example seems at first glance correlated to the question as both are about a city and a birthplace. But with deeper understanding, it is clear that the added text is irrelevant, and thus should be ignored.

This motivates the need for a more deliberate attention mechanism that relies on deeper understanding. To distinguish it from the more low-level attention-mechanism, we call it System 2 Attention (S2A). In this paper, we explore one way of building such an attention mechanism using the LLMs themselves. In particular, we employ instruction-tuned LLMs to rewrite the context by removing irrelevant text. In this way, LLMs can make deliberate reasoning decisions about which parts of the input to focus on before outputting a response. Another advantage of using instruction-tuned LLMs is that it becomes possible to control the attention focus, perhaps similar to how humans can control their attention.

## Implementation {#sec:impl}

We consider the typical scenario in which a Large Language Model (LLM) is given a context, denoted as `$x$`, and its objective is to generate a high-quality sequence, denoted as `$y$`. This procedure is represented as `$y \sim LLM(x)$`.

System 2 Attention (S2A) is a simple two-step process:

1.  Given the context `$x$`, S2A first regenerates the context `$x'$` such that irrelevant parts of the context that will adversely affect the output are removed. We denote this `$x' \sim S2A(x)$`.

2.  Given `$x'$`, we then produce the final response from the LLM using the regenerated context instead of the original one: `$y \sim LLM(x')$`.

S2A can be seen as a class of techniques and there are various ways to implement step 1. In our specific implementation we take advantage of general instruction-tuned LLMs that are already proficient at reasoning and generation tasks similar to the one required for `$S2A$`, hence we can implement this procedure as an instruction via prompting.

Specifically, `$S2A(x) = LLM(P_{S2A}(x))$`, where `$P_{S2A}$` is a function that generates a zero-shot prompt to the LLM instructing it to perform the desired System 2 Attention task over `$x$`.

An example prompt `$P_{S2A}$` we use in our experiments is given in [2](#fig:s2a_prompt). This S2A instruction requires the LLM to regenerate the context, extracting the part that is beneficial for providing relevant context for a given query. In this implementation it specifically asks to generate an `$x'$` that separates useful context from the query itself in order to clarify these reasoning steps for the model.

Typically, some post-processing may also be applied to the output of step 1 in order to structure the prompt for step 2, as instruction following LLMs produce additional chain-of-thought reasoning and comments in addition to requested fields. We remove the requested text in parenthesis from [2](#fig:s2a_prompt) and add additional instructions given in [13](#fig_s2a_debias_prompt).

In the following subsection we consider various other possible implementations of S2A.

## Alternative Implementations and Variations {#sec:variants}

We consider several variations of our S2A approach.

#### No context/question separation

In our implementation in [2](#fig:s2a_prompt) we chose to regenerate the context decomposed into two parts (context and question). This was designed to specifically encourage the model to copy all context that is necessary to attend to, whilst not losing sight of the goal (question/query) of the prompt itself. We observed that some models otherwise may have trouble copying all the necessary context, but for short contexts (or strong LLMs) this is probably not necessary, and an S2A prompt that simply asks for a non-partitioned rewrite should suffice. This prompt variant is given in [12](#fig_s2a_noseparation_prompt).

#### Keep original context

In S2A, after the context is regenerated, with all necessary elements that should be attended to contained therein, the model then responds given only the regenerated context `$x'$`, and the original context `$x$` is hence discarded. If S2A performs poorly, and some of the original context that was judged irrelevant and removed was actually important, then information has been lost. In the "keep original" variant, after running the S2A prompt, one appends `$x'$` to the original prompt `$x$`, so that both the original context and its reinterpretation are both present for the model to have access to. An issue with this method is that now the original irrelevant information is still present and may still affect the final generation. This prompt variant is given in [14](#fig_s2a_keeporig_prompt).

#### Instructed prompting

Our S2A prompt given in [2](#fig:s2a_prompt) encourages to remove opinionated text from the context, and uses instructions in step 2 ([13](#fig_s2a_debias_prompt)) to ask for the response to be unopinionated. We can ablate the latter, and remove this instruction in the prompt template for step 2 of S2A. We can also compare this to a further baseline where we simply add the extra instruction request from [13](#fig_s2a_debias_prompt) to the original context (rather than performing S2A at all), termed instructed prompting in [shi2023large].

#### Emphasize Relevance/Irrelevance

The S2A implementations so far described have emphasized regenerating the context to increase objectivity and reduce sycophancy. However, there are other ways of emphasizing what context should be attended to. For example, one could emphasize relevance versus irrelevance instead. An instance of such an approach is given in the prompt variant in [15](#fig:gsmic_s2a_prompt), which we will also use in our experiments.


[FIGURE: System 2 Attention Implementation. In our SycophancyEval experiments we implement S2A to ignore opinions in the context with the provided zero-shot prompt using LLaMA-2-70B-chat. The original input pr...]


# Experiments {#sec:exp}

We conduct experiments to evaluate S2A in three settings: factual question answering and longform generation of arguments, following [sharma2023towards], and math word problem solving from [shi2023large].

## Tasks & Experimental Setup

### Factual QA Evaluation

We use the modified version of TriviaQA from SycophancyEval

- **Suggest Correct Answer**: "*I think the answer is \[correct answer\], but I'm really not sure.*" This statement tends to skew standard models to answer correctly more often than the fact-seeking question baseline alone.

- **Suggest Incorrect Answer**: "*I think the answer is \[incorrect answer\], but I'm really not sure.*" or **Refute Correct Answer**: "*I don't think the answer is \[correct answer\], but I'm really not sure.*". These statements tends to skew standard models to answer incorrectly often compared to the baseline.

We evaluate on 200 prompts, using GPT-4 to measure the accuracy of the model responses, given the unopinionated baseline question only, the model response (which was generated given the opinionated prompt) and the gold label from TriviaQA, in order to compare to the response. The evaluation prompt used in GPT-4 is given in [9](#fig:gpt4_fact_eval).

### Longform Generation Evaluation

We also use the arguments prompts from SycophancyEval, which ask for comments on provided quoted argument contexts, again with additional opinions in the prompt, see e.g. [3](#fig:s2a_examples) (bottom). In particular in addition to asking the question and providing context, one of four possible comments will be added to the prompt, denoted as *like*, *wrote*, *dislike* and *didn't write*, given by the following templated sentences:


[FIGURE]


[FIGURE: System 2 Attention (S2A) examples. S2A regenerates the portion of the context it decides to pay attention to, choosing to remove portions it deems irrelevant or provide spurious correlations that adve...]


[FIGURE: An example from the modified TriviaQA from SycophancyEval where the added opinion in an otherwise fact-seeking query makes LLaMA-2-70B-chat answer incorrectly (left). S2A (right) regenerates the part ...]


- **Like**: "*I like this argument.*" or **Wrote**: "*I wrote this argument*". These statements tend to skew standard models to provide more positive comments.

- **Dislike**: "*I dislike this argument.*" or **Didn't Write:** "*I didn't write this argument.*". These statements tends to skew standard models to provide more negative comments.

We evaluate on 200 prompts, using GPT-4 to measure the quality of the model responses, given the original question (without additional opinions) only and the model response. The evaluation prompt used in GPT-4 is given in [10](#fig:gpt4_quality_eval), which produces a score from 1-5. We also report a measure of objectivity in the generated model response. To do this, we prompt GPT-4 to measure the sentiment of the model response using the prompt given in [11](#fig:gpt4_obj_eval), which produces a score `$S$` from -5 to 5 (from negative to positive sentiment, 0 being neutral). We then report the objectivity score as `$5 -|S|$`, where a neutral response of `$S=0$` would achieve the highest score of 5.

### Math word problems

We also test our method on the GSM-IC task from [shi2023large] which adds irrelevant sentences into math word problems. Such distracting sentences are shown to adversely affect the accuracy of LLMs, especially when they are on the same topic, yet irrelevant to the question. GSM-IC uses 100 problems chosen from GSM8K [cobbe2021gsm8k] and adds one distracting sentence before the final question. The task offers various types of distracting sentences, but we experiment with two setups: random distractors (from the set built in the task) and in-topic distractors. An example is given in [18](#fig:gsmic_example).

We report match accuracy between the label and the final answer extracted from the model's output. In order to reduce variance, we average over 3 random seeds.

### Main Methods

We use LLaMA-2-70B-chat as our base model. We first evaluate it in two settings:

- **Baseline**: the input prompt provided in the dataset is fed to the model, and answered in a zero-shot fashion. Model generations are likely to be affected by spurious correlations (opinions or irrelevant information) provided in the input.

- **Oracle Prompt**: the prompt without additional opinions or irrelevant sentences is fed into the model, and answered in a zero-shot fashion. This can be seen as an approximate upper bound on performance if we were to ignore irrelevant information optimally.

We compare these two methods to **S2A**, which also uses LLaMA-2-70B-chat for both the steps described in [2.2](#sec:impl). For all three models we use decoding parameters with temperature of 0.6 and top-p of 0.9.

For the factual QA and longform generation tasks for S2A we use the prompt given in [2](#fig:s2a_prompt) for step 1 and [13](#fig_s2a_debias_prompt) for step 2, which emphasize factuality and objectivity. For the math word problems, since the focus of this task is relevance of the text to the question, we direct S2A to attend on relevant text only using the S2A prompt given in [15](#fig:gsmic_s2a_prompt).


[FIGURE: System 2 Attention increases factuality for questions containing opinions. Given opinionated input prompts that ask a question, but also suggest or refute potential answers as part of the context, sta...]


[FIGURE: System 2 Attention increases objectivity in longform generations. We evaluate model-generated arguments by LLaMA-2-70B-chat given a context quote and an opinion-based prompt, which states either that ...]


## Results

#### System 2 Attention increases factuality for questions containing opinions

[5](#fig:fact_results) (left) presents overall results on the factual QA evaluation. Input prompts, due to the opinions contained within their contexts, lose accuracy in their answers, yielding 62.8% of questions correct. In contrast, the oracle (unopinionated) prompts achieve 82.0%. System 2 Attention gives a large improvement over the original input prompts, with an accuracy of 80.3% -- close to oracle prompt performance.

The breakdown of performance, given in [5](#fig:fact_results) (right), shows that the baseline using input prompts loses accuracy relative to the oracle in the *Refute Correct* and *Suggest Incorrect* categories, as the model has been swayed to generate wrong answers. For the *Suggest Correct* category however, input prompts actually outperform the oracle prompt, as the correct answer has been suggested, which it tends to copy. These findings are in line with the results previously reported in @sharma2023towards. S2A, in contrast, has little or no degredation for all categories, and is not easily swayed by opinion, suffering only a slight loss on the *Suggest Incorrect* category. This also means however, that its accuracy does not increase if the correct answer is suggested as in the *Suggest Correct* category.

#### System 2 Attention increases objectivity in longform generations

[6](#fig:obj_results) (left) presents overall results on the longform generation of arguments evaluation. Baseline, oracle prompts and System 2 Attention are all evaluated as providing similarly high quality evaluations (4.6 for Oracle and S2A, 4.7 for Baseline, out of 5). However, the baseline is evaluated as *less objective* than oracle prompts (2.23 vs. 3.0, out of 5), whereas S2A is *more objective* than the baseline or even the oracle prompts, with 3.82. In this task, there may be text in the context arguments themselves that provides considerable sway, independent of the additional comments added to the input prompt, which S2A can also decrease when it regenerates the context.

The breakdown of performance, given in [6](#fig:obj_results) (right), shows that the baseline decreases in objectivity particularly for the *Like* and *Wrote* categories, which increase positive sentiment in its responses compared to the oracle prompts. In contrast, S2A provides more objective responses across all categories, even ones without additional opinions in the prompt (*None* category) compared to both the baseline and the oracle.


[FIGURE: System 2 Attention improves math word problem solving. When an irrelevant sentence (left: random, right: in-topic distractor) is added to a problem text, the model accuracy drops significantly (Baseli...]


#### System 2 Attention increases accuracy in math word problems with irrelevant sentences

[7](#fig:gsmic_results) presents results on the GSM-IC tasks. In agreement with the findings of [shi2023large], we find the baseline accuracy to be much lower than the oracle (which is fed the same prompt without the irrelevant sentence), as shown in [7](#fig:gsmic_results) (left) for random distractors. This effect is even larger when the irrelevant sentences are on the same topic as the problems [7](#fig:gsmic_results) (right). We note that we used zero-shot prompting for the baseline, oracle and step 2 of S2A (shown in [16](#fig:gsmic_zero_shot)) with LLaMA-2-70B-chat and found the model always performed chain-of-thought reasoning in its solution. Adding to the prompt an instruction to ignore any irrelevant sentences (Instructed Prompting) did not bring consistent improvement. When S2A is used to extract relevant parts from the problem text before solving it, the accuracy jumps up about 12% for random distractors, and 10% for in-topic distractors. An example of S2A removing a distractor sentence is shown in [18](#fig:gsmic_example).


[FIGURE: Ablation results comparing factuality for questions containing opinions. S2A which does not use instructed prompting (S2A-NI) or separate context and question (S2A-Single) performs only slightly worse...]


### Variants and Ablations {#sec:exp_ablations}

We also test some of the variants described in [2.3](#sec:variants), measuring performance on the factual QA task as before. Results are given in [8](#fig:ablation_results).

The "Single" version of S2A does not separate the regenerated context into question and non-question components, and ends up performly similarly to the version of S2A (default) that does separate, but with just slightly worse performance.

The "Keep Original" version of S2A (called "S2A-KeepOrig") has final generations that can still attend to the original context, in addition to the regenerated context by S2A. We find this approach has degraded performance compared to standard S2A, with an overall accuracy of 74.5% versus S2A's 80.3%. It appears that even though the full context given to the LLM now has the S2A version, it can still attend to the original opinionated prompt as well, which it does, thus degrading performance. This implies that attention must be hard (sharp) not soft when it comes to avoiding irrelevant or spurious correlations in the context.

The "Not Instructed" version of S2A (S2A-NI), where a debiasing prompt is not added to step 2, is only slightly worse than S2A in overall accuracy. However, we see skew appearing in the *Suggest Correct* category for example in this case.

Adding a debiasing prompt to standard LLMs ("Instructed Prompting") can bring improved performance over the baseline LLM (from 62.8% to 71.7%), but not as much as S2A (80.3%), and this method still shows sycophancy. In particular, accuracy in the *Suggest Correct* at 92% is above the oracle prompt, just as in the baseline, indicating it is being skewed by the (in this case, correct) suggestion. Similarly, the *Suggest Incorrect* category performance is low compared to the oracle prompt (38% vs. 82%) although the *Refute Correct* category fares better, and the method seems to help somewhat there. We also tried zero-shot Chain-of-Thought (CoT) prompting [kojima2022large], another kind of instructed prompting, by adding "Let's think step by step" to the prompt, but this produced worse results.

# Related Work

#### Attention Mechanisms

Attention mechanisms have long been used in machine learning models to focus on more relevant parts of the input. Early models employed a hard-attention mechanism that selects a discrete subset of the input [Mnih2014RecurrentMO; Weston2014MemoryN; Xu2015ShowAA]. However, the difficulty of optimizing such discrete operations led to the popularity of soft-attention mechanisms [Bahdanau2014NeuralMT; Sukhbaatar2015EndToEndMN], which assign continuous-valued weights to each input component. Transformer models [Vaswani2017AttentionIA] that are used in LLMs have soft-attention as their core component. Our method can be viewed as a type of (hard-)attention mechanism as it removes attention away from irrelevant parts of the input. The advantage of our method is that it operates in natural language and can leverage the full reasoning power of the LLM to make attention decisions that require deeper understanding, while also making it potentially controllable and interpretable.

#### Reasoning in LLMs

There are a number of other approaches that utilize the power of generating natural language that the LLM has learned in order to perform reasoning. For example, chain-of-thought reasoning [wei2022chain] or least-to-most prompting [zhou2022least], amongst other approaches, take the original context as input, then generate intermediate reasoning tokens, followed by the final response. For example chain-of-thought can output intermediate math computations for a math problem. However, those methods do not typically seek to regenerate the context as in S2A. In fact, these other reasoning methods are actually complementary to our approach. For example, chain-of-thought reasoning is performed on the context generated by S2A in our math problem experiment. Chain-of-thought could also potentially be used to help generate the S2A context as well, although we did not explore this direction.

#### Response Refinement

A number of works also use LLM-based reasoning to refine a given text sequence, i.e, take the model response as input, and generate a new improved response as output. Constitutional AI [bai2022constitutional] uses a constitution to refine model responses in order to perform better reinforcement learning. Self-refine [madaan2023self] also uses the LLM to refine responses in order to improve accuracy. Self-ask [press2022measuring] and Chain-of-Verification [dhuliawala2023chain] use self-refinement via asking questions to improve responses, e.g. in the latter case to reduce hallucination. In contrast in our work we seek to refine the context, not the response.

#### Query Rewriting

Query rewriting is a classical approach in search engines which involves reformulating an original input query to a new query in order to achieve better search results [calvanese2000query]. In the context of using LLMs for this goal, this has also been studied, e.g. in [anand2023context]. Recently, [Deng2023RephraseAR] proposed a prompting method that rewrites questions. Their goal was to reduce ambiguity and clarify the question by adding more details, rather than considering an input context and eliminating irrelevant parts as in our method.

#### Repetition, Spurious Correlations & Sycophancy

Sycophancy is a phenomenon "where a model seeks human approval in unwanted ways", as termed by [perez2022discovering], and several works have shown that opinion inherent in a prompt will tend to make the model agree with the input, which they try to alleviate with training procedures [sharma2023towards; wei2023simple]. Similar issues were also shown in earlier dialogue systems such as BlenderBot 1 where if the human says they have a dog, the model is likely to say it has a dog too [roller2020recipes]. The authors termed this "Nontrivial Repetition", where the name emphasizes that this has more to do with overly upweighted token probabilities in the transformer attention mechanism (and hence, related to the standard repetition problem [holtzman2019curious]), rather than to higher order concepts that imply agency such as seeking approval. In a separate area of study of model failures, which may be derived from the same root cause, several works have shown that irrelevant context can adversely affect predictions [jia2017adversarial; cho2023improving; shi2023large].

# Conclusion

We presented System 2 Attention (S2A), a technique that enables an LLM to decide on the important parts of the input context in order to generate good responses. This is achieved by inducing the LLM to first regenerate the input context to only include the relevant portions, before attending to the regenerated context to elicit the final response. We showed experimentally that S2A can successfully rewrite context that would otherwise degrade the final answer, and hence our method can both improve factuality and reduce sycophancy in its responses.

There remain many avenues for future research. In our experiments we employed zero-shot prompting in order to implement S2A. Other methods could optimize our approach further, for example by considering fine-tuning, reinforcement learning or alternative prompting techniques. Successful S2A could also be distilled back into standard LLM generations, for example by fine-tuning using the original prompts as inputs and the final improved S2A responses as targets.

# Limitations & Discussion

While System 2 Attention aims to remove irrelevant context to improve generations, it certainly does not always succeed. Hence, these models will still sometimes be affected by spurious correlations, as in other systems.

The S2A method as described requires more computation than standard LLM regeneration. That is because it must first regenerate appropriate parts of the context, and the extra cost is somewhat analogous to that incurred in methods like chain-of-thought which also makes intermediate generations. However, S2A may be more or less expensive, depending on the context regeneration length -- that is, copying a large relevant context will incur more computational cost. This could potentially be remedied with speedup tricks, e.g., only generate the difference, or the parts not to include, or when copying large sections that have a label/section header, it could just reference the label instead. We leave speeding up the method to future work.

We observed, at least for weaker models, simply copying context may sometimes be error prone, e.g. copying a long poem might be cut off at the end, although we did not measure this effect clearly. This issue will likely disappear with ever-more-powerful LLMs, or could be fixed with finetuning, as our current implementation is via zero-shot prompting.

As our method is zero-shot prompted it largely depends on the choice of prompt, which we have not made great efforts to optimize. Hence, there are likely much better choices than the ones given here. Further, as is usual with zero-shot prompting, if training data was available that indicated how to perform the task (mapping from original context to S2A regenerated context) then performance would likely be stronger. As the task is highly interpretable this appears to be a possible avenue of further research.


# Appendix


[FIGURE: Factual Accuracy Evaluation Prompt Template. We use GPT4 to evaluate factual accuracy when the gold (test set) label for a given question is known using the above prompt. We then consider only those r...]


[FIGURE: Longform Generation Quality Evaluation Prompt Template. We use GPT-4 to evaluate overall generation quality accuracy with the above prompt (does not assume we can provide the gold answer, as in 9).]


[FIGURE: Objectivity Evaluation Prompt Template. We use GPT-4 to evaluate positive/negative sentiment with the above prompt. After returning the value between -5 and 5 we take five minus the absolute value as ...]


[FIGURE: System 2 Attention with no separation into context/question. Note we found that the emphasis on including the question was helpful or some models could generate the context and forget to ask the quest...]


[FIGURE: System 2 Attention with instructed prompting. We compute S2A using the prompt in 2, and then build the following prompt using the S2A-regenerated context for generating the final response (step 2 of S...]


[FIGURE: System 2 Attention with keep original prompt. This variant of S2A (step 2) includes both the original context and the regenerated S2A context in order to generate a final response.]


[FIGURE: System 2 Attention with relevance-based prompt used in the GSM-IC task.]


[FIGURE: Zero-shot prompt used for the GSM-IC task.]


[FIGURE: GSM-IC Instructed Prompting has an additional instruction to ignore the irrelevant text.]


[FIGURE: An example from the GSM-IC task where a distracting sentence (“Max has 1000 more books than Mary”) makes LLaMA-2-70B-chat (left) make a mistake. S2A successfully removes the distracting sentence (righ...]


[FIGURE: An example from the modified version of TriviaQA from SycophancyEval where the added opinion in the otherwise fact-seeking question makes the standard LLM (LLaMA-2-70B-chat) answer incorrectly (left)....]


[FIGURE: An example from the modified TriviaQA from SycophancyEval where the added opinion in an otherwise fact-seeking query makes LLaMA-2-70B-chat answer incorrectly (left). S2A removes the opinion from the ...]



