# Abstract

GPT-3 can perform numerous tasks when provided a natural language prompt that contains a few training examples. We show that this type of few-shot learning can be unstable: the choice of prompt format, training examples, and even the order of the training examples can cause accuracy to vary from near chance to near state-of-the-art. We demonstrate that this instability arises from the bias of language models towards predicting certain answers, e.g., those that are placed near the end of the prompt or are common in the pre-training data. To mitigate this, we first estimate the model's bias towards each answer by asking for its prediction when given the training prompt and a content-free test input such as "`N/A`". We then fit calibration parameters that cause the prediction for this input to be uniform across answers. On a diverse set of tasks, this *contextual calibration* procedure substantially improves GPT-3 and GPT-2's average accuracy (up to 30.0% absolute) and reduces variance across different choices of the prompt.

[IMAGE: Few-shot learning curves showing mean accuracy +/- one standard deviation across different choices of training examples for three datasets (AGNews-davinci, MIT-director-curie, DBPedia-ada). Shows that contextual calibration improves accuracy, reduces variance, and makes tools like GPT-3 more effective for end users.]

# Introduction

Few-shot learning---the ability to learn tasks with limited examples---is an important aspect of intelligence [lake2015human; yogatama2019learning]. Recent work shows that large neural language models can perform few-shot learning without finetuning [radford2019gpt2; brown2020language]. Specifically, GPT-3 [brown2020language] can perform numerous tasks when provided a few examples in a natural language *prompt*. For example, to perform sentiment analysis one can condition GPT-3 on a prompt such as:

> Input: Subpar acting. Sentiment: Negative
>
> Input: Beautiful film. Sentiment: Positive
>
> Input: Amazing. Sentiment:

where the first two lines correspond to two training examples and the last line is a test example. To make predictions, the model predicts whether the subsequent token is more likely to be the word "Positive" or "Negative".

This style of few-shot "in-context" learning is interesting because it shows that the model can learn without parameter updates. And, more importantly, it has numerous practical advantages over the now-standard approach of finetuning [radford2018improving; devlin2018BERT]. First, it allows practitioners to "rapidly prototype" NLP models: changing the prompt *immediately* leads to a new model. Second, it provides a fully natural language interface to a machine learning model, which allows users---even those without technical expertise---to create NLP systems. Finally, since in-context learning reuses the same model for each task, it reduces memory requirements and system complexity when serving many different tasks.

However, despite these promises, we show that GPT-3's accuracy can be highly unstable across different prompts (Section 3). A prompt contains three components: a format, a set of training examples, and a permutation (ordering) for those examples. We show that different choices for these factors can lead to highly different accuracies, e.g., changing the permutation of the training examples in a sentiment analysis prompt can change accuracy from near chance (54%) to near state-of-the-art (93%). This instability implies that GPT-3 users, who typically design prompts manually, cannot expect to consistently obtain good accuracy.

We next analyze what causes this instability. We identify three pitfalls of language models that lead them to be biased toward certain answers during few-shot learning. In particular, they suffer from majority label bias, recency bias, and common token bias (Section 4). The majority label and recency biases lead the model to predict training answers that appear frequently or near the end of the prompt. For example, a prompt that ends with a Negative training example may cause a bias towards the Negative class. On the other hand, the common token bias leads the model to prefer answers that are frequent in its pre-training data, e.g., it prefers "United States" over "Saint Lucia", which is likely suboptimal for the task of interest.

We identify that these biases typically result in a shift in the output distribution of the model. We can thus counteract these biases by "calibrating" the output distribution. Concretely, we estimate the model's bias towards certain answers by feeding in a dummy test input that is *content-free*. In the prompt above for example, if we replace "Amazing." with the string "N/A", the model predicts 62% Positive. We then fit the calibration parameters so that the content-free input has uniform scores for each answer. This *contextual calibration* procedure provides a good setting of the calibration parameters without additional training data.

We test the effectiveness of contextual calibration on a range of tasks (Section 5). Contextual calibration consistently improves GPT-3 and GPT-2's accuracy (up to 30.0% absolute) across different choices of the prompt format and examples (e.g., Figure 1). It also makes the accuracy more stable across different prompts, thus mitigating the need for prompt engineering. Overall, contextual calibration is a simple method that makes language models better few-shot learners: it enables end users to obtain higher accuracy with considerably less effort.

# Background and Experimental Setup

Neural autoregressive language models (LMs) take as input a sequence of tokens and output a probability distribution over the next token. Large neural LMs can perform tasks in a zero- or few-shot manner using in-context learning [radford2019gpt2; brown2020language]. To do so, a natural language *prompt* is fed into the model. This prompt contains three components: a format, a set of training examples, and a permutation (ordering) of the training examples.

### Prompt Format

The prompt *format* is a template which consists of placeholders for the training and test example(s) and possibly a natural language description of the task. For example, the format of the prompt in Section 1 is a template with the style: "Input:" `input` "Sentiment:" `label`. Many alternate formats exist, e.g., one could frame the task as question answering.

### Prompt Training Examples

The prompt's *training examples* are used to teach the LM how to solve the task at hand. The prompt from Section 1 consists of two training examples; we refer to this as "two-shot" learning. We also consider "zero-shot" learning, where no training examples are present.

### Training Example Permutation

When training examples are used, they have a particular *permutation*, e.g., the "Subpar acting" example comes first in the prompt from Section 1. The permutation matters because neural language models update their hidden states in a left-to-right-fashion.

To make predictions on an input, we slot it into the test placeholder and generate from the LM. For example, see the "Amazing." test example in the prompt from Section 1. For generation tasks, we generate greedily from the LM until it produces a newline character. For classification tasks, the probability for each class is given by the probability assigned to its associated *label name*, e.g., the words "Negative" and "Positive" for sentiment classification.

[IMAGE: Figure 2 - High variance in GPT-3's accuracy as prompt format changes. Shows GPT-3 2.7B's accuracy for different sets of four training examples across ten different prompt formats for SST-2, along with the quartiles.]

## Datasets and Prompt Formats

We use datasets for three tasks: text classification, fact retrieval, and information extraction. We use a fixed prompt format for each dataset unless otherwise specified. We show the format and examples from each dataset in Appendix 10.

### Text Classification

We study text classification using six datasets: sentiment analysis using **SST-2** [socher2013recursive], 6-way question classification using **TREC** [voorhees200trec], textual entailment using 3-way **CB** [marneffe2019cb] and binary **RTE** [dagan2005pascal] from SuperGLUE [wang2019superglue], and topic classification using the 4-way **AGNews** [zhang2015character] and 14-way **DBPedia** [zhang2015character] datasets. The prompt in Section 1 shows an example of the sentiment analysis task.

### Fact Retrieval

We evaluate fact retrieval with **LAMA** [petroni2019language]. The dataset consists of knowledge base triples that are placed into templates with missing objects, e.g. "Obama was born in". We use these templates as our prompts, and remove the relations where the missing answer is not at the end of the template (left-to-right LMs cannot solve these). The answers are always single tokens, and we report average accuracy across all triples.

### Information Extraction

We consider information extraction using two slot filling datasets, **ATIS** [hemphill1990atis] and **MIT Movies** trivia10k13 [liu2012conversational]. We use two random slots for each dataset, *airline* and *departure date* for ATIS, and *director name* and *movie genre* for MIT Movies. The answer for both datasets is a span of text from the input, e.g., the ATIS airline task is to predict "american airlines" when given the sentence "list a flight on american airlines from toronto to san diego". We use Exact Match between the model's generated output and the ground-truth span as our evaluation metric.

## Model Details

We run our experiments on three sizes of GPT-3 (2.7B, 13B, and 175B parameters) as well as GPT-2 (1.5B parameters). We access GPT-3 using the OpenAI API. We release code to replicate our experiments.

# Accuracy Varies Highly Across Prompts

[IMAGE: Figure 3 - Majority label and recency biases cause GPT-3 to become biased towards certain answers and help explain the high variance across different examples and orderings. Uses 4-shot SST-2 with prompts that have different class balances and permutations, e.g., [P P N N] indicates two positive training examples and then two negative. Shows how often GPT-3 2.7B predicts Positive on the balanced validation set.]

This section studies how GPT-3's accuracy changes as we vary each aspect of the prompt (training examples, permutation, format). We focus on a subset of the datasets to simplify our analysis; in Section 5 we show that our findings hold across all of the datasets we study.

**GPT-3's accuracy depends highly on both selection and permutation of training examples.** Concretely, we use a fixed prompt format and choose different random sets of training examples. For each set of training examples, we evaluate the accuracy for all possible permutations.

Figure [variance_training_set] shows the results for SST-2 (4-shot, GPT-3 2.7B). Surprisingly, varying the permutation can be as important, or even more important, than which training examples are chosen. For example, varying the permutation of the training examples can cause accuracy to go from near chance (54.3%) to near state-of-the-art (93.4%). For a qualitative example of the sensitivity to permutations, see Table 1 in Appendix 9. This high importance on example order is in contrast to standard machine learning, where the ordering of examples during training is typically an afterthought.

**The variance persists with more data and larger models.** Adding more training examples into the prompt does not necessarily reduce the variance in accuracy. We sweep over the number of training examples for three different datasets in Figure 1 (red curves). The variance remains high even when we use 16 training examples. Moreover, adding more training examples can sometimes hurt accuracy (e.g., mean accuracy drops from 36.0% to 25.9% for DBPedia 0-shot to 1-shot). The variance in accuracy can also remain high when using larger models, e.g., the left of Figure 1.

**GPT-3's accuracy depends highly on prompt format.** We next keep the set of training examples and permutations fixed but vary the prompt format. We focus on SST-2, and we manually design an additional 14 prompt formats. The formats include question-answer templates, conversation-style templates, prompts that resemble Web pages, and variations on the label names (all formats available in Table [sst2_format_exploration] in Appendix 10). The accuracy for ten of the formats is shown in Figure 2. We find that some of the formats are better than others on average. However, all of the formats still suffer from high variance across different training sets.

# What Causes the High Variance?

We next analyze *why* GPT-3's accuracy varies across different training examples, permutations, and prompt formats. Concretely, we show that the variance arises because LMs are biased towards outputting answers that are (1) frequent in the prompt (majority label bias), (2) towards the end of the prompt (recency bias), and (3) common in the pre-training data (common token bias).

### Majority Label Bias

We find that GPT-3 is biased towards answers that are frequent in the prompt. A trivial case is when a text classification prompt has a class imbalance, e.g., more Positive than Negative sentiment examples. This is demonstrated in the "unbalanced" region of Figure 3: when one class is more common, GPT-3 2.7B is heavily biased towards predicting that class. Since the SST-2 sentiment analysis dataset is balanced, this bias causes large accuracy degradations. The majority label bias also explains why we frequently observe a drop in accuracy when moving from 0-shot to 1-shot---we found that the drop is due to the model frequently repeating the class of the one training example.

The majority label bias also occurs for generation tasks. On the validation set for 4-shot LAMA with GPT-3 2.7B, 50.2% of the model predictions are a repeat of one of the four training answers (the correct repeat rate is 24.7%). Overall, the majority label bias helps to explain why different choices for the training examples heavily influence GPT-3's accuracy---it shifts the distribution of model predictions.

### Recency Bias

The model's majority label bias is aggravated by its *recency bias*: the tendency to repeat answers that appear towards the end of the prompt. The "balanced" region of Figure 3 demonstrates this. For instance, when two Negative examples appear at the end (P P N N), the model will heavily prefer the Negative class. Moreover, the recency bias can outweigh the majority label bias, e.g., the "P P P N" training set leads to nearly 90% of predictions being Negative, despite 3/4 of the training examples being Positive.

Recency bias also affects generation tasks. For 4-shot LAMA, the training answers that are closer to the end of the prompt are more likely to be repeated by the model. Concretely, the model "overpredicts" the answer from the 1st, 2nd, 3rd, and 4th training example by 8.5%, 8.3%, 14.3%, and 16.1%, respectively. Overall, recency bias helps to explain why the *permutation* of the training examples is important---the ordering of the examples heavily influences the distribution of the model predictions.

### Common Token Bias

Finally, we find that GPT-3 is biased towards outputting tokens that are common in its *pre-training* distribution, which is likely suboptimal for the distribution of answers on the *downstream* task. A simple case of this occurs for the LAMA fact retrieval dataset, where the model often predicts common entities such as "America" when the ground-truth answer is instead a rare entity.

A more nuanced case of the common token bias occurs for text classification. Recall that the model makes predictions by generating the label name associated with each class. Because certain label names appear more frequently in the pre-training data, the model will be inherently biased towards predicting certain classes. For example, on DBPedia (a balanced 14-way topic classification dataset), GPT-3 predicts the "book" class 11x more often than the "artist" class. In fact, there is a moderate correlation (r=0.67) between the frequency of a DBPedia label name and the rate at which GPT-3 predicts its class. Overall, the common token bias helps to explain why the choice of label names is important, and why the model struggles on rare answers.

### The Impact of Biases on Model Predictions

We find that the end result of the above three biases is typically a simple shift in the model's output distribution. For example, Figure 4 visualizes this shift for a SST-2 sentiment prompt.

[IMAGE: Figure 4 - The Positive class probability for 25 random test inputs for a particular sentiment analysis prompt. Negative ground-truth examples are marked in red and Positive are marked in green.]

The prompt used in Figure 4 and the model's intrinsic biases cause it to frequently predict high confidence for the Positive class. Since the default 50% threshold is used to make predictions, this results in frequent false positives. Importantly, note that if we could optimally set the classification threshold (p(Positive) = 0.68 in this case), the classifier would be highly accurate (94% on the validation set).

# Contextual Calibration

Thus far, we have shown that GPT-3 is biased towards certain answers due to the prompt and the model's intrinsic biases. Here, we look to correct this by "calibrating" the model's output probabilities. A common technique for adjusting output probabilities is to apply an affine transformation [platt1999scaling; guo2017calibration]:

```latex
$$\boldsymbol{\mathbf{\hat{q}}} = \text{softmax}(\boldsymbol{\mathbf{W}}\boldsymbol{\mathbf{\hat{p}}} + \boldsymbol{\mathbf{b}})$$
```

where a weight matrix **W** and a bias vector **b** are applied to the original probabilities **p-hat** to get the new probabilities **q-hat**. For classification tasks, **p-hat** is the set of probabilities that are associated with each label name, renormalized to one. For generation tasks, **p-hat** is the entire set of probabilities for the first token. In this paper, we restrict the matrix **W** to be diagonal, known as vector scaling [guo2017calibration], to prevent the parameters from growing quadratically in the size of **p-hat** (which is approximately 50,000 for generation tasks).

The main challenge in the zero- or few-shot setting is that we do not have data to learn **W** and **b**. We thus propose a novel data-free procedure to infer a good setting of these parameters. The key idea is that the model's bias towards certain answers can be estimated by feeding in a *content-free* input such as the string "N/A". For example, consider the two-shot prompt:

> Input: Subpar acting. Sentiment: Negative
>
> Input: Beautiful film. Sentiment: Positive
>
> Input: N/A Sentiment:

where "N/A" serves as the test input. Ideally, GPT-3 would score this test input as 50% Positive and 50% Negative. However, the model's biases cause it to score this input as 61.8% Positive. Note that this error is *contextual*: a different choice of the training examples, permutation, and format will lead to different predictions for the content-free input.

We can correct this error by setting **W** and **b** so that the class scores for the content-free input are uniform. We first obtain **p-hat** for the content-free input, denoted **p-hat_cf**. We then set **W** = diag(**p-hat_cf**)^(-1) and **b** to the all-zero vector. To make test predictions, we compute **W** * **p-hat** + **b** and take the argmax.

### Implementation Details

This *contextual calibration* procedure adds trivial amounts of computational overhead and is implemented in a few lines of code (compute and save **p-hat_cf**, adjust output probabilities). For the content-free input, many good choices exist, including "N/A", the empty string, and gibberish tokens. In all our experiments, we average the probabilities from three content-free inputs: "N/A", "[MASK]", and the empty string. One could also craft the content-free input in a task-specific manner. We explore this for LAMA, where we replace the subject with the content-free input, e.g., we use "N/A was born in" as the input.

## Results for Contextual Calibration

Here, we evaluate the effectiveness of contextual calibration across all of our datasets and LMs. We first use a fixed prompt format and select five different random sets of training examples, placing them in an arbitrary order in the prompt. We do not artificially balance the labels of the training examples for the classification tasks. We use the same sets of training examples for the baseline (standard decoding without calibration) and contextual calibration. We use labeling budgets of 0--8 examples; using more than 8-shots causes the cost of querying the OpenAI API to become prohibitively expensive.

Table [main_results] shows the results and Figure 1 in Section 1 plots the same data for a subset of the tasks.

### Improves Mean And Worst-Case Accuracy

Contextual calibration dramatically improves GPT-3's average and worst-case accuracy, by up to 30.0% absolute. These gains hold for both classification and generation tasks. Contextual calibration also sometimes allows GPT-3 2.7B to outperform the GPT-3 175B baseline---by up to 19.3%---despite being over 50x smaller.

### Can Reduce Variance Across Training Sets

Figure 5 plots the difference in the standard deviation between the baseline and contextual calibration for all tasks from Table [main_results]. Contextual calibration reduces the variance considerably in a majority of cases, and it does not increase variance by much in the remaining cases.

### Reduces Drop from 0-shot to 1-shot

For the baseline, there are four cases where there is a drop in accuracy when moving from 0-shot to 1-shot (TREC, AGNews, DBpedia, SST-2). We attribute this drop to the majority label bias (see discussion in Section 4). Calibration removes this drop in three out of four cases.

### Improves GPT-2

We also test GPT-2 1.5B (see Table [main_results_gpt2] in Appendix 9). We find that like GPT-3, GPT-2's accuracy also highly varies across different prompts. This suggests that the variance that we observe for few-shot in-context learning is a general problem for LMs. Second, contextual calibration works out-of-the-box for GPT-2---it improves the mean accuracy and reduces variance for most tasks.

### Improves Accuracy Across Formats

In our next set of experiments, we use a fixed set of training examples and vary the prompt format. We use the 15 prompt formats for SST-2 discussed in Section 3. We also create 15 prompt formats for each of three random relations in LAMA (P20, P159, P19) by using the paraphrases of the original LAMA templates generated by Jiang et al. Figure 6 shows the results before and after calibration for SST-2, and Figure 8 in Appendix 9 show the results for LAMA. Contextual calibration improves the average and worst-case accuracy for both datasets, and reduces the variance for SST-2.

## Ablations on Contextual Calibration

We finally conduct two analyses/ablations on contextual calibration. We first analyze how effective contextual calibration is at inferring a good setting of **W**. To do so, we compare its accuracy to an "oracle calibration" method that uses the validation set to find the best possible diagonal **W**. We evaluate this oracle on AGNews, and find that contextual calibration is surprisingly close to it (Figure 7).

We also study how the choice of content-free input affects accuracy. In Table 2 in Appendix 9, we show the accuracy for SST-2 and AGNews for different choices of the content-free input. The choice of content-free input matters, however, many good choices exist.

[IMAGE: Figure 5 - Aside from improving mean accuracy, contextual calibration also reduces the standard deviation of accuracy across different choices of the training examples. Shows the difference in standard deviation between contextual calibration and the baseline.]

[IMAGE: Figure 6 - GPT-3 has high variance across different prompt formats; contextual calibration reduces this variance and improves mean accuracy. Shows the mean accuracy +/- standard deviation over 15 different prompt formats for SST-2.]

[IMAGE: Figure 7 - Contextual calibration, despite using no training data, achieves similar accuracy to an "oracle" calibration that finds the best W using the validation set. Shows GPT-3 175B's mean accuracy +/- standard deviation on AGNews over different choices of the training examples.]

# Discussion

**Does Calibration Eliminate the Need to Engineer Prompts?** The motivation behind "prompt engineering" is that not all prompts lead to the same accuracy. Thus, one should tune the prompt's format and examples to achieve the best possible performance [brown2020language; gao2020making]. Contextual calibration does not eliminate the need to engineer prompts, however, it does mitigate it: contextual calibration makes the accuracy of the best, average, and worst-case prompts more similar (and higher).

**Should You Finetune in the Few-shot Setting?** We use a fixed LM with no finetuning. As mentioned in Section 1, there are numerous reasons not to finetune: it enables rapid prototyping, provides a fully natural language interface, and is more efficient in terms of memory requirements and system complexity when serving many different tasks. Moreover, like in-context learning without contextual calibration, finetuning can be unstable in the few-shot setting [schick2020exploiting]. Nevertheless, if these disadvantages are acceptable or avoidable, finetuning can improve accuracy over in-context learning in some cases [schick2020size; gao2020making]. An interesting direction for future work is to study the interplay between contextual calibration and finetuning, e.g., does contextual calibration alleviate the need to finetune, or vice versa?

# Related Work

### Few-shot Learning with Language Models

Recent work uses LMs to solve NLP tasks, e.g., for story cloze prediction [schwartz2017effect], knowledge base completion [petroni2019language], and Winograd schemas [trinh2018simple]. Radford et al. (2019) and Brown et al. (2020) show that large LMs can be used to solve a myriad of tasks in a few-shot manner via in-context learning. Our paper provides a simple modification to their setting that improves performance. Asking LMs to complete natural language prompts is also used as a method to "probe" LMs, e.g., analyzing their factual [petroni2019language; jiang2019can; shin2020autoprompt] or commonsense knowledge [bosselut2019comet]. Our results suggest that these probing methods may underestimate model accuracy, and we recommend that future work take advantage of contextual calibration.

### Volatility of Few-shot Learning in NLP

Recent work shows that when using masked language models such as BERT for zero-shot learning, the prompt format can impact accuracy [petroni2019language; jiang2019can; shin2020autoprompt]. Independent and concurrent work also shows that when finetuning masked language models on few examples, the choice of training examples can impact results [schick2020size; gao2020making]. We show that similar instabilities occur for in-context learning (i.e., no finetuning) with left-to-right language models. We also show a surprising instability associated with example ordering. Moreover, unlike past work, we analyze why these instabilities occur, and we use insights from this analysis to mitigate the issues.

### Failures of Language Models

We identify failures when LMs are used for in-context learning (e.g., recency bias). Past work identifies similar failures when LMs are used for text generation. For example, neural LMs often repeat themselves [holtzman2019curious], suffer from overconfidence [braverman2020calibration; jiang2020know], suffer from recency bias [khandelwal2018lm; ravfogel2019studying], and prefer generic responses instead of rare text [li2016diversity; logan2019barack]. Past work mitigates these degeneracies by modifying the model's output probabilities or generation schemes, e.g., explicitly preventing repetitions [paulus2017deep] or using sampling instead of greedy decoding [holtzman2019curious].

# Conclusion and Future Work

We show that few-shot learning can be highly volatile across different choices of the prompt. Through a detailed analysis, we identify that this volatility arises from biases in LMs, e.g., their tendency to output recent or common tokens. We use these insights to develop contextual calibration---a simple procedure to adjust the model's output probabilities---which improves accuracy, reduces variance, and overall makes tools like GPT-3 more effective for end users.

Looking at the bigger picture, our results inspire two future research directions in few-shot learning for NLP. First, on the methods side, we show that good few-shot learning requires *attention to detail*: small but non-trivial decisions such as calibration can greatly influence results. This makes it difficult to correctly develop and compare new methods (e.g., pretraining schemes or model architectures). We thus hope to make other few-shot learning methods more robust, and also expand our techniques to cover a wider ranger of tasks (e.g., calibration for open-ended generation). Second, on the analysis side, our results highlight the need to understand *what* GPT-3 learns from the prompt. The model has an impressive ability to improve with more training examples, however, we show that the model learns some superficial patterns such as repetition of common answers. We hope to better understand and analyze the dynamics of in-context learning in future work.

# Appendix: Additional Results on Variance and Calibration

Table 1 shows an example of the sensitivity to ordering.

| **Prompt** (test input not shown) | **Acc.** |
|---|---|
| Review: the whole thing 's fairly lame , making it par for the course for disney sequels . Answer: Negative. Review: this quiet , introspective and entertaining independent is worth seeking . Answer: Positive | 88.5% |
| Review: this quiet , introspective and entertaining independent is worth seeking . Answer: Positive. Review: the whole thing 's fairly lame , making it par for the course for disney sequels . Answer: Negative | 51.3% |

**Table 1:** Top: a prompt consisting of two training examples (the test input is not shown) that leads to good test accuracy for GPT-3 2.7B (88.5%). Bottom: simply *reversing the order* of the two examples causes the accuracy to drop to near random chance (51.3%).

Table 2 demonstrates that the choice of content-free input does affect accuracy, however, many good choices exist.

| **Content-free Input** | **SST-2** | **AGNews** |
|---|---|---|
| Uncalibrated Baseline | 66.5 | 48.5 |
| N/A | 74.2 | 64.5 |
| [MASK] | 74.5 | 63.8 |
| '' | 72.9 | 64.7 |
| N/A, [MASK], '' | 79.0 | 66.5 |
| the | 69.1 | 59.0 |
| abc | 77.5 | 57.3 |
| the man. | 79.4 | 62.0 |
| dasjhasjkdhjskdhds | 79.3 | 64.5 |
| nfjkhdvy84tr9bpuirvwe | 78.4 | 65.5 |

**Table 2:** We show the accuracy for 1-shot SST-2 and 0-shot AGNews over different choices for the content-free input. The choice of content-free input matters, however, *many good choices exist*. The token '' indicates the empty string. Recall that in our experiments, we ensemble over N/A, [MASK], and the empty string.

[IMAGE: Figure 8 - Contextual calibration improves GPT-3's accuracy across various prompt formats for LAMA. Shows GPT-2 2.7B's mean accuracy over 15 different formats for the LAMA "place of death" relation (P20), "Headquarter Location" relation (P159), and "place of birth" relation (P19).]

# Appendix: Prompt Formats Used

Tables [format1] and [format2] show the default prompt format used for all tasks. Table [sst2_format_exploration] shows the 15 different formats used when studying the effect of prompt format for SST-2.

**Default Prompt Formats (Classification Tasks):**

| Task | Prompt | Label Names |
|---|---|---|
| SST-2 | Review: This movie is amazing! Sentiment: Positive. Review: Horrific movie, don't see it. Sentiment: | Positive, Negative |
| AGNews | Article: USATODAY.com - Retail sales bounced back a bit in July... Answer: Business. Article: New hard-drive based devices feature color screens... Answer: | World, Sports, Business, Technology |
| TREC | Classify the questions based on whether their answer type is a Number, Location, Person, Description, Entity, or Abbreviation. Question: How did serfdom develop in and then leave Russia? Answer Type: Description. Question: When was Ozzy Osbourne born? Answer Type: | Number, Location, Person, Description, Entity, Abbreviation |
| DBPedia | Classify the documents based on whether they are about a Company, School, Artist, Athlete, Politician, Transportation, Building, Nature, Village, Animal, Plant, Album, Film, or Book. Article: Geoffrey D. Falksen (born July 31 1982) is an American steampunk writer. Answer: Artist. Article: The Perrin River is a 1.3-mile-long (2.1 km) tidal river... Answer: | Company, School, Artist, Athlete, Politician, Transportation, Building, Nature, Village, Animal, Plant, Album, Film, Book |
| CB | But he ended up eating it himself... question: her life and spirit could stimulate her mother. True, False, or Neither? answer: Neither. Valence the void-brain... question: Valence was helping. True, False, or Neither? answer: | True, False, Neither |
| RTE | Others argue that Mr. Sharon should have negotiated... question: Mr. Abbas is a member of the Palestinian family. True or False? answer: False. The program will include Falla's "Night in the Gardens of Spain,"... question: Beatrice and Benedict is an overture by Berlioz. True or False? answer: | True, False |

**Default Prompt Formats (Generation Tasks):**

| Task | Prompt |
|---|---|
| LAMA | Alexander Berntsson was born in Sweden. Khalid Karami was born in |
| ATIS (Airline) | Sentence: what are the two american airlines flights that leave from dallas to san francisco in the evening. Airline name: american airlines. Sentence: list a flight on american airlines from toronto to san diego. Airline name: |
| ATIS (Depart Date) | Sentence: please list any flight available leaving oakland california tuesday arriving philadelphia wednesday. Depart date - Day name: tuesday. Sentence: show me all all flights from pittsburgh to atlanta on wednesday which leave before noon and serve breakfast. Depart date - Day name: |
| MIT Movies (Genre) | Sentence: last to a famous series of animated movies about a big green ogre and his donkey and cat friends. Genre: animated. Sentence: what is a great comedy featuring the talents of steve carell as a loser looking for a friend. Genre: |
| MIT Movies (Director) | Sentence: in 2005 director christopher nolan rebooted a legendary dc comics superhero with a darker grittier edge in which movie. Director: christopher nolan. Sentence: what 1967 mike nichols film features dustin hoffman in romantic interludes with anne bancroft as mrs robinson. Director: |

**SST-2 Format Exploration (15 Formats):**

| Format ID | Prompt Style | Label Names |
|---|---|---|
| 1 | Review: [text] Answer: [label] | Positive, Negative |
| 2 | Review: [text] Answer: [label] | good, bad |
| 3 | My review for last night's film: [text] The critics agreed that this movie was [label] | good, bad |
| 4 | Here is what our critics think... One of our critics wrote "[text]". Her sentiment towards the film was [label] | positive, negative |
| 5 | Critical reception [edit] In a contemporary review, Roger Ebert wrote "[text]"... the overall critical reception of the film was [label] | good, bad |
| 6 | Review: [text] Positive Review? [label] | Yes, No |
| 7 | Review: [text] Question: Is the sentiment of the above review Positive or Negative? Answer: [label] | Positive, Negative |
| 8 | Review: [text] Question: Did the author think that the movie was good or bad? Answer: [label] | good, bad |
| 9 | Question: Did the author of the following tweet think that the movie was good or bad? Tweet: [text] Answer: [label] | good, bad |
| 10 | [text] My overall feeling was that the movie was [label] | good, bad |
| 11 | [text] I [label] the movie. | liked, hated |
| 12 | [text] My friend asked me if I would give the movie 0 or 5 stars, I said [label] | 0, 5 |
| 13 | Input: [text] Sentiment: [label] | Positive, Negative |
| 14 | Review: [text] Positive: [label] | True, False |
| 15 | Review: [text] Stars: [label] | 5, 0 |
