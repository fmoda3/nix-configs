# Abstract

Generation of plausible yet incorrect factual information, termed hallucination, is an unsolved issue in large language models. We study the ability of language models to deliberate on the responses they give in order to correct their mistakes. We develop the Chain-of-Verification (CoVe) method whereby the model first (i) drafts an initial response; then (ii) plans verification questions to fact-check its draft; (iii) answers those questions independently so the answers are not biased by other responses; and (iv) generates its final verified response. In experiments, we show CoVe decreases hallucinations across a variety of tasks, from list-based questions from Wikidata, closed book MultiSpanQA and longform text generation.

# Introduction

Large Language Models (LLMs) are trained on huge corpora of text documents with billions of tokens of text. It has been shown that as the number of model parameters is increased, performance at tasks such as closed book QA improve in accuracy, and larger models can generate more correct factual statements [radford2019language; petroni2019language]. However, even the largest models can still fail, particularly on lesser known torso and tail distribution facts [sun2023head], i.e. those that occur relatively rarely in the training corpora. In those cases where the model is incorrect, they instead generate an alternative response which is typically plausible looking (e.g., a similar entity, but an incorrect one). These factually incorrect generations are referred to as hallucinations [maynez2020faithfulness]. Further, in longform tasks consisting of generating multiple sentences or paragraphs, the hallucination problem can be exacerbated due to the issue of exposure bias [wang2020exposure].

The current wave of language modeling research goes beyond next word prediction, and has focused on their ability to reason. Improved performance in reasoning tasks can be gained by encouraging language models to first generate internal thoughts or reasoning chains before responding [wei2022chain; adolphs2021reason; wang2022self; lanchantin2023learning], as well as updating their initial response through self-critique [press2022measuring; madaan2023self]. In this work we follow this line of research to study how and when language-model-based reasoning can be used to reduce hallucinations. We develop an approach, called Chain-of-Verification (CoVe) which, given an initial draft response, first plans verification questions to check its work, and then systematically answers those questions in order to finally produce an improved revised response. We find that independent verification questions tend to provide more accurate facts than those in the original longform answer, and hence improve the correctness of the overall response. We study variations on this recipe across a range of tasks: from list-based questions, closed booked QA and longform text generation. We first propose a joint approach for generating the entire verification chain left-to-right, which improves performance and decreases hallucinations compared to the baseline language model. However, models that attend to existing hallucinations in the context from their own generations tend to repeat the hallucinations. Hence we also introduce further improvements with factored variants which separate out the verification chain steps, in terms of which context is attended to. We show how these factored variants give further performance gains across all three tasks considered.

# Related Work

Hallucination is a general problem in language model generations that appears across many tasks, from summarization [maynez2020faithfulness] to open-domain dialogue [roller2020recipes], and has not been resolved by simply scaling up training data or model size [zhang2023language]. For a survey of the hallucination issue, see [ji2023survey]. A majority of the methods for reducing hallucination can be divided into roughly three categories: training-time correction, generation-time correction and via augmentation (tool-use).

[IMAGE: Figure 1 - Chain-of-Verification (CoVe) method. Given a user query, a large language model generates a baseline response that may contain inaccuracies, e.g. factual hallucinations. To improve this, CoVe first generates a plan of a set of verification questions to ask, and then executes that plan by answering them and hence checking for agreement. We find that individual verification questions are typically answered with higher accuracy than the original accuracy of the facts in the original longform generation. Finally, the revised response takes into account the verifications. The factored version of CoVe answers verification questions such that they cannot condition on the original response, avoiding repetition and improving performance.]

In training-time correction methods, an attempt is made to improve the raw left-to-right generations of an encoder-decoder or decoder-only language model by either training or otherwise adjusting the model weights to decrease the probability of hallucinated generations. This includes using reinforcement learning [roit2023factually; wu2023fine], contrastive learning [chern2023improving; sun2023contrastive] and other methods [li2023inference].

In generation-time correction, a common theme is to make reasoning decisions "on top of" the base LLM in order to make them more reliable. For example, by considering the probabilities of the generated tokens [mielke2022reducing; kadavath2022language]. In [manakul2023selfcheckgpt] multiple samples are drawn from the model to detect hallucinations. In [varshney2023stitch] hallucinations are identified using low confidence scores, and their correctness is checked through a validation procedure, mitigated, and then the generation is continued. An alternative to using the confidence scores is to leverage inconsistencies in the LLMs output to detect hallucination. [agrawal2023language] use both multiple samples and consistency detection by asking direct and indirect queries to check for hallucinated references. [cohen2023lm] introduce a method called LM vs LM which simulates an interactive setup between two LLMs where one LLM acts as an examiner and tests if the output is consistent via repeated cross-examination. [cohen2023lm] shows that using inconsistencies for QA tasks can outperform using confidence scores for hallucination detection. CoVe also uses a related self-consistency approach, but without the multi-agent (multi-LLM) debate concept.

A third approach is to use external tools to help mitigate hallucinations, rather than relying solely on the abilities of the language model itself. For example, retrieval-augmented generation can decrease hallucinations by using factual documents for grounding [shuster2021retrieval; jiang2023active; yu2023improving] or chain-of-thought verification [zhao2023verify]. Other approaches include using tools for fact-checking [chern2023factool; galitsky2023truth; peng2023check], or linking to external documents with attribution [menick2022teaching; rashkin2023measuring; gao2023rarr].

There are also a number of related works in improving reasoning for logical and mathematical tasks, even if they do not address reducing hallucination explicitly. Several approaches have been shown to improve results with extended reasoning steps by the system, such as chain-of-thought [wei2022chain], deductive verification [ling2023deductive], and self-verification [miao2023selfcheck; jiang2023backward; weng2022large]. The latter tries to predict the (masked) question given the answer for math problems, and use that as evidence that this is the correct solution.

# Chain-of-Verification

Our approach assumes access to a base LLM that -- despite potentially being prone to hallucination -- is capable of being prompted with general instructions in either a few-shot or zero-shot fashion. A **key assumption** of our method is that this language model, when suitably prompted, can both generate and execute a plan of how to verify itself in order to check its own work, and finally incorporate this analysis into an improved response.

Our overall process, which we call Chain-of-Verification (CoVe), thus performs four core steps:

1. _Generate Baseline Response_: Given a query, generate the response using the LLM.

2. _Plan Verifications_: Given both query and baseline response, generate a list of verification questions that could help to self-analyze if there are any mistakes in the original response.

3. _Execute Verifications_: Answer each verification question in turn, and hence check the answer against the original response to check for inconsistencies or mistakes.

4. _Generate Final Verified Response_: Given the discovered inconsistencies (if any), generate a revised response incorporating the verification results.

Each of these steps is performed by prompting the same LLM in different ways to obtain the desired response. While steps (1), (2) and (4) all can be invoked with a single prompt, we investigate variations of step (3) including joint, 2-step and factored versions. These variants either involve a single prompt, two prompts or else independent prompts per question, where more sophisticated decomposition can yield improved results.

We describe these steps in more detail below. An overview of the approach is illustrated in Figure 1, and in the Appendix in Figure 3.

## Baseline Response

Given a query, we generate left-to-right as usual using the LLM, with no special tricks. While this is the first step in the CoVe pipeline, it also serves as the baseline we wish to improve in our experiments (i.e., we will directly compare this baseline response with the final verified response from our overall method).

Given such baseline generations are typically prone to hallucination, CoVe attempts to identify these hallucinations, and correct them, in the following steps.

## Plan Verifications

Conditioned on the original query and the baseline response, the model is prompted to generate a series of verification questions that test the factual claims in the original baseline response. For example if part of a longform model response contains the statement _"The Mexican-American War was an armed conflict between the United States and Mexico from 1846 to 1848"_, then one possible verification question to check those dates could be _"When did the Mexican American war start and end?"_. We note that verification questions are not templated and the language model is free to phrase these in any form it wants, and they also do not have to closely match the phrasing of the original text.

In our experiments, we perform such verification planning by providing a few-shot prompt of (response, verification) demonstrations to our LLM. See Table 8 for the few-shot prompts we will use in our experiments. We note it is also possible with a sufficiently performant instruction-following LLM that this could be performed zero-shot.

## Execute Verifications

Given the planned verification questions, the next step is to answer them in order to assess if any hallucinations exist. While techniques such as retrieval-augmentation could be used in this process, such as verification via search engine, in this work we do not explore tool-use. Instead, we consider only using the LLM itself in all steps of CoVe, hence the model is used to check its own work. We investigate several variants of verification execution, called joint, 2-Step, factored and factor+revise.

### Joint

In the _joint_ method, the planning and execution (steps 2 and 3) are accomplished by using a single LLM prompt, whereby the few-shot demonstrations include both verification questions and their answers immediately after the questions. In this approach separate prompts are not needed.

### 2-Step

A potential disadvantage of the _joint_ method is that because the verification questions must condition on the baseline response in the LLM context, and the method is joint, the verification answers have to condition on the initial response as well. This may increase the likelihood of repetition, another known issue of modern LLMs [holtzman2019curious]. This means the verification questions might hallucinate similarly to the original baseline response, which defeats the purpose. We hence instead separate the planning and execution into separate steps, both with their own LLM prompt. The planning prompt conditions on the baseline response in the first step. The verification questions generated from planning are answered in the second step, where crucially the context given to the LLM prompt only contains the questions, and not the original baseline response and hence cannot repeat those answers directly.

### Factored

Another, more sophisticated approach, is to answer all questions independently as separate prompts. Again, crucially, those prompts do not contain the original baseline response and are hence not prone to simply copying or repeating it. The factored approach has the further advantage of removing any potential interference not only from the baseline response, but also between answer contexts, and is somewhat related to the recent (concurrent) work of [radhakrishnan2023question] for subquestion answering by factored decomposition, hence we adopt their naming. It can also potentially handle more verification questions by virtue of them not all having to fit with the same single context. While this is potentially more computationally expensive, requiring the execution of many more LLM prompts, they can be run in parallel, and hence be batched. In order to do this, we first have to take the set of generated questions from Section 3.2 and parse them into separate questions, which is a relatively easy task as the few-shot demonstrations we provide indicate they should be generated as a comma-separated list. We can then split them out into separate LLM prompts.

### Factor+Revise

After answering the verification questions, the overall CoVe pipeline then has to either implicitly or explicitly cross-check whether those answers indicate an inconsistency with the original responses. In the factor+revise approach, we execute this as a deliberate step via an extra LLM prompt, which may make it easier for the final system to reason about this step explicitly. Differently to answering the verification questions, the cross-checking phase needs to condition on both the baseline response and the verification question and answer. We thus execute this as separate LLM prompts, one "cross-check" prompt for each question, with again a set of few-shot demonstrations showing the desired output. For example if the original baseline response contained the phrase _"It followed in the wake of the 1845 U.S. annexation of Texas..."_ and CoVe generated a verification question _When did Texas secede from Mexico?_ which was answered with _1836_ then an inconsistency should be detected by this step.

## Final Verified Response

Finally, the improved response that takes verification into account is generated. This is executed by a final few-shot prompt where the context takes into account all of the previous reasoning steps, the baseline response and verification question answer pairs, so that the corrections can take place. If the Factor+Revise approach is used from Section 3.3 then the output of the cross-check inconsistency detection is provided as well.

# Experiments

We use various experimental benchmarks to measure the efficacy of CoVe in reducing hallucination, comparing against a number of baselines.

## Tasks

The benchmarks we use range from list-based questions where the required answer is a set of entities, to where the answer is a longform generation of multiple freeform sentences.

### Wikidata

We start by testing CoVe on a set of automatically generated questions using the Wikidata API (https://query.wikidata.org/). We create list questions of the form: "Who are some [Profession]s who were born in [City]?". For example, "Who are some politicians who were born in Boston?". The answer to these questions is a set of entities, where the gold list is obtained from the Wikidata knowledge base. This results in a dataset of 56 test questions, each typically containing ~600 known gold entities, but typically an LLM will produce a much shorter list. We then use the precision metric (micro-averaged) to measure performance, in addition to reporting the averaged number of positive and negative entities produced.

### Wiki-Category List

We then proceed to a harder set-generation task. We use the Quest [malaviya2023quest] dataset that was created using Wikipedia Category lists. We convert these category names to questions by simply prepending a "Name some". Owing to the varied questions such as _Name some Mexican animated horror films_ or _Name some Endemic orchids of Vietnam_ we believe this task can pose a greater challenge. We collate all examples in the dataset that _do not require_ logical operations to create a set of 55 test questions each having ~8 answers. Similar to the Wikidata task, we measure precision (micro-averaged) to measure performance, in addition to reporting the averaged number of positive and negative entities produced.

### MultiSpanQA

We next test our approach on an reading comprehension benchmark, MultiSpanQA [li2022multispanqa]. MultiSpanQA comprises of questions that have multiple independent answers (derived from a series of multiple discontiguous spans in the text, with questions originally from the Natural Questions dataset). We consider a closed-book setting, where we do not provide supporting documents, and hence consider a subset of questions which are factoid-based, so that our base LLM is more likely to be able to answer them. We thus use a test set of 418 questions with shorter answers per span (up to 3 tokens per item). For example, Q: Who invented the first printing press and in what year?, A: _Johannes Gutenberg, 1450_.

### Longform generation of Biographies

We next validate the performance of CoVe on longform text generation. In this setting, we evaluate our method on generating biographies, adopting the benchmark proposed in by [min2023factscore]. Here the model is simply prompted to generate a biography of a selected entity using the prompt: "Tell me a bio of <entity>". We evaluate the efficacy of our approach using the FactScore metric [min2023factscore] developed in that work, which uses a retrieval-augmented language model to fact-check the response (Instruct-Llama, "Llama + Retrieval + NP"), which they showed correlates well with human judgments.

## Baselines

We use Llama 65B, a strong open model as our base LLM [touvron2023llama], and use greedy decoding for all models. As Llama 65B is not instruction fine-tuned, we employ few-shot examples particular to each task for measuring performance on each of our benchmarks. This serves as our main baseline which CoVe tries to improve upon. CoVe uses the same Llama 65B base, but includes, for the same few-shot examples, demonstrations of verification questions and final verified responses, following Figure 1 and Section 3. Thus, we measure the ability to improve over the original baseline response for the same LLM. For CoVe, we compare different variants, particularly the joint and factored versions on all tasks.

We also compare to Llama instruction fine-tuned models, for which we use Llama 2 [llama2]. We measure both zero-shot performance on the task, or zero-shot with chain-of-thought by adding "Let's think step by step" to the zero-shot prompt. We find that the instruction fine-tuned models tend to generate extraneous content when queried. This can especially be a problem for the list-based tasks. To deal with this we add an extra line to our prompt: "List only the answers separated by a comma". We also add another layer of post-processing to extract the answers by using an off-the-shelf NER model to further avoid this issue as this helped. However, we still expect few-shot to improve over this, especially for tasks like Multi-Span-QA where the answers are not all named entities, and the few-shot examples effectively show the domain of the task.

For the longform generation of biographies we also compare to several existing model results reported in [min2023factscore], in particular InstructGPT [ouyang2022training], ChatGPT (https://openai.com/blog/chatgpt) and PerplexityAI (www.perplexity.ai).

[IMAGE: Figure 2 - FactScore performance distribution across head, torso and tail facts for CoVe variants and various baselines on longform generation of biographies.]

## Results

We are interested in empirically answering the following research questions:

**RQ1**: Can CoVe effectively reduce the rate of hallucinatory content produced by the LLM?

**RQ2**: Can CoVe be used to fix or remove incorrect generations without decreasing the amount of correct content?

Our main results across the four benchmark tasks are given in Table 1, Table 2 and Table 3, and our main findings are as follows.

### CoVe improves precision on list-based answer tasks

We find that CoVe provides large gains in precision on the list-based tasks, e.g. more than doubles the precision from the Llama 65B few-shot baseline for the Wikidata task (from 0.17 to 0.36). We find from the positive and negative breakdown that there is a large reduction in the number of hallucinated answers (negatives: 2.95 -> 0.68) while only a relatively small reduction in the number of non-hallucinations (positives: 0.59 -> 0.38).

### CoVe improves performance on closed book QA

We also find that CoVe brings improvements in general QA problems, as measured on MultiSpanQA. We observe a 23% improvement in F1 over the few-shot baseline (0.39 -> 0.48), where the improvements come from gains in both precision and recall.

### CoVe improves precision on longform generation

These results also extend to longform generation, where we actually see larger gains than in the QA setting. FactScore increases 28% (55.9 -> 71.4) from the few-shot baseline, with again only a relatively small reduction in average number of facts provided (16.6 -> 12.3). We also show the breakdown of improvements across facts in Figure 2, where one can see CoVe improves results for both rare and more frequent facts.

### Instruction-tuning and CoT do not reduce hallucinations

We find that the few-shot baseline that employs a pre-trained Llama model outperforms Llama 2 Chat, an instruction tuned model, across all the tasks. The few-shot examples lead the model to give outputs in line with those expected for the task, whereas general instruction tuning produces more hallucinations or incorrect outputs. Standard chain-of-thought (CoT) prompting also fails to improve the results for these tasks. While CoT has proven to help for reasoning tasks, it seems less appropriate for the issue of hallucination we measure in this work.

### Factored and 2-step CoVe improve performance

We observe a consistent performance improvement across all tasks from applying the factored CoVe approach compared to joint CoVe. For example improvement from 60.8 -> 63.7 in FactScore in longform generation. Similarly, the 2-step approach also outperforms the joint approach, as tested on the Wikidata and Wiki-Category list tasks, with 2-step giving the best results for Wikidata, and factored the best for Wiki-Category. All these results support our hypothesis that verifying questions should not attend to the original baseline response as they may be prone to repeating it (as the joint method can do).

### Further explicit reasoning helps remove hallucinations

In the longform generation task we also explore more sophisticated reasoning steps in the CoVe "factor+revise" method, which explicitly cross-checks whether verification answers indicate an inconsistency. We see large gains in the FactScore metric from this further explicit reasoning from 63.7 (factored) -> 71.4 (factor+revise). This gives further indication that appropriate and explicit reasoning in LLMs can bring improvements in mitigating hallucinations.

### CoVe-based Llama outperforms InstructGPT, ChatGPT and PerplexityAI

On the longform generation task, our baseline few-shot Llama 65B is outperformed by the ChatGPT and PerplexityAI models in terms of the FactScore metric. However, applying CoVe to the baseline Llama 65B lifts its performance above both ChatGPT and PerplexityAI, as well as outperforming InstructGPT. This is particularly impressive compared to PerplexityAI considering that is a model that can support its facts with retrieval-augmentation, whereas CoVe uses only the base language model itself with improved reasoning via deliberation (verification). However, we can see in Figure 2 PerplexityAI still outperforms CoVe for very rare facts where retrieval is essential, but CoVe outperforms PerplexityAI for more frequent facts. We note that some models produce less overall facts than others, however the FactScore metric is normalized and hence comparable across models. We verified this experimentally by clipping Llama 2 70B chat's output to present less facts (as it contains the largest number in its output out of all models), but this did not change its FactScore substantially, e.g. clipping to 10 sentences increased its score from 41.3 -> 42.7. We note the length of the generations of the few-shot-based models are essentially governed by the few-shot examples, which in-turn are constrained by the context length.

### Shortform verification questions are more accurately answered than longform queries

In a longform response, LLMs are prone to generate a number of hallucinations. However, it can often be the case that the LLM itself would know these hallucinations are wrong if queried specifically for that individual fact, independent of the rest of the longform generation, see Figure 1, Figure 3, and Section 9. This can be seen quantitatively on the Wikidata task, where only ~17% of the Llama few-shot baseline answer entities are correct in list-based questions. However, when querying each individual entity via a verification question, we find ~70% are correctly answered.

### LLM-based verification questions outperforms heuristics

In our method, CoVe, the verification questions are generated by the LLM dependent on the task. We compare the quality of these questions to heuristically constructed ones in order to measure their quality, by replacing the LLM questions with templated yes/no questions of the form "Does X answer the question" for list-based questions with elements X in the answer. Results on the Wiki-Category task, given in Table 4, show a reduced precision with rule-based verification questions. We believe this difference would be larger for longform generation where the types of required verification questions can be more diverse, and LLM-based verification becomes even more necessary.

### Open verification questions outperform yes/no-based questions

In our main experiments we use verification questions where the expected answers are true facts. An alternative setup is to include the fact as part of the verification question and ask it in a yes/no answer format. We evaluate this difference in Table 4, and find that yes/no type questions perform worse for the factored version of CoVe. Some anecdotal examples are included in Appendix Section 9 for ChatGPT where we find the model tends to agree with facts in a yes/no question format whether they are right or wrong.

# Conclusion

We introduced Chain-of-Verification (CoVe), an approach to reduce hallucinations in a large language model by deliberating on its own responses and self-correcting them. In particular, we showed that models are able to answer verification questions with higher accuracy than when answering the original query by breaking down the verification into a set of simpler questions. Secondly, when answering the set of verification questions, we showed that controlling the attention of the model so that it cannot attend to its previous answers (factored CoVe) helps alleviate copying the same hallucinations. Overall, our method provides substantial performance gains over the original language model response just by asking the same model to deliberate on (verify) its answer. An obvious extension to our work is to equip CoVe with tool-use, e.g., to use retrieval augmentation in the verification execution step which would likely bring further gains.

# Limitations

While our Chain-of-Verification (CoVe) method seeks to reduce hallucinations, it does not remove them completely from generations. This means that CoVe can still generate incorrect or misleading information for a given query, even if it improves over the baseline. We also note that in our experiments we have only addressed hallucinations in the form of directly stated factual inaccuracies. However, hallucinations could come in other forms, such as during incorrect reasoning steps, as part of opinions, etc. We also note that the generations CoVe produces come with verifications which, if viewed by the user, add more interpretability to its decisions, but come at the cost of increased computational expense due to generating more tokens in the output, similar to other reasoning methods such as Chain-of-Thought.

Our method seeks to make a large language model produce improved responses by spending more time deliberating to identify its own mistakes. While we have shown this gives clear improvements, the upper bound to the improvement is clearly limited by the overall capabilities of the model, e.g. in identifying and knowing what it knows. In this regard, an orthogonal line of research, as discussed in Section 2 is the use of external tools by language models, to gain further information beyond what is stored in its weights. While we do not explore that avenue in this work those techniques would likely be fruitful to combine with the findings here.

# Appendix: CoVe - Further details

[IMAGE: Figure 3 - For longform generation, the Chain-of-Verification (CoVe) Factor + Revise method is the most effective in our longform generation experiments. CoVe Factor + Revise has the model independently identify (cross-check) which facts are consistent with its executed verifications (indicated by tickmark and crosses in the figure). With this extra step we aim to disregard the inconsistent facts and use the consistent facts to regenerate the response.]

# Appendix: Prompt Templates

We provide prompt templates for the longform generation of biographies task below for the different steps and variants of CoVe (see Section 3). Templates for the other tasks are similar, but using few-shot examples from those tasks instead.

## Generate Baseline Response

```
Q: Tell me a bio of <person>
A: <bio of person>

Q: Tell me a bio of <person>
A: <bio of person>

Q: Tell me a bio of <person>
A: <bio of person>

Q: Tell me a bio of <person>
A:
```

Few-shot prompting with 3 few-shot examples for the longform generation of biographies task. Other tasks use the same standard few-shot setup as well (with 3 examples from that particular task).

## Plan Verifications

```
Context: Q: Tell me a bio of <person>.
A: <passage about person>
Response:
<fact in passage>, Verification Question
<fact in passage>, Verification Question

Context: Q: Tell me a bio of <person>.
A: <passage about person>
Response:
<fact in passage>, Verification Question
<fact in passage>, Verification Question

Context: Q: Tell me a bio of <person>.
A: <passage about person>
Response:
<fact in passage>, Verification Question
<fact in passage>, Verification Question

Context: Q: Tell me a bio of <person>.
A: <passage about person>
Response:
```

Step (2) of CoVe involves planning the verification questions. In the biography task case we split the longform generation into its individual passages (e.g. sentences in the biography case, this was done due to excessive context length, which we don't need to do for the other tasks). The model then generates a verification question for each fact it observes in each passage (a passage may have multiple facts).

## Execute Verifications

```
Q: Verification Question
A: Answer

Q: Verification Question
A: Answer

Q: Verification Question
A: Answer

Q: Verification Question
A:
```

In step (3) of CoVe, the model then generates an answer for each of the verification questions. Again we use 3 few-shot examples.

## Generate Final Verified Response

```
Context: <Original Passage>.
From another source,
<output of execute verification step: Q + A>
<output of execute verification step: Q + A>
Response: <revised and consistent Passage>


Context: <Original Passage>.
From another source,
<output of execute verification step: Q + A>
<output of execute verification step: Q + A>
Response: <revised and consistent Passage>

Context: <Original Passage>.
From another source,
<output of execute verification step: Q + A>
<output of execute verification step: Q + A>
Response: <revised and consistent Passage>

Context: <Original passage>.
From another source,
<output of execute verification step: Q + A>
Response:
```

In step (4) of CoVe (factored) the model is then presented with its original generation (split into passages, e.g. sentences, in the biography case, due to excessive context length which we do not need to do for the other tasks) along with its own verification step results. The model is told that this information comes from "another source". The model is required to synthesize a new final answer based on facts that are consistent between the two sources.

## Factor+Revise: Identify which facts are consistent

```
Context: <Original Fact>.
From another source,
<output of execute verification step: Q + A>
Response: CONSISTENT. <Consistent fact>

Context: <Original Fact>.
From another source,
<output of execute verification step: Q + A>
Response: INCONSISTENT.

Context: <Original Fact>.
From another source,
<output of execute verification step: Q + A>
Response: PARTIALLY CONSISTENT. <Consistent part>
```

In the CoVe (Factor + Revise) variant, as part of step (3) after Section 8.3, the model is made to explicitly identify which facts are consistent between the two sources. The consistent facts can then be spliced together.

# Appendix: ChatGPT example screenshots

[IMAGE: Figure 4 - ChatGPT generates several hallucinations for this question, e.g. Hillary Clinton and Michael Bloomberg.]

[IMAGE: Figure 5 - Even when the longform answer is provided for a rewritten query (see query from Figure 4), while giving a slightly different answer, ChatGPT still generates several hallucinations for this question, e.g. Hillary Clinton and Michael Bloomberg.]

[IMAGE: Figure 6 - Shortform questions (which could be verification questions) appear to be answered more factually than the longform answers in Figure 4 and Figure 5.]

[IMAGE: Figure 7 - Another example of hallucinations for a different query, e.g., John F. Kennedy Jr was born in Washington D.C.]

[IMAGE: Figure 8 - Examples where questions asking for a fact are answered correctly, but verifying via a yes/no question is incorrect (the model tends to agree with the way the question is stated, even if it was stated incorrectly).]
