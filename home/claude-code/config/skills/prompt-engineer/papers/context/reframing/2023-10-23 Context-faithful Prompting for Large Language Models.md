# Context-faithful Prompting for Large Language Models

**Authors:** Wenxuan Zhou, Sheng Zhang, Hoifung Poon, Muhao Chen

**Affiliations:** University of Southern California, Microsoft Research

**arXiv:** 2303.11315

---

## Abstract

Large language models (LLMs) encode parametric knowledge about world facts and have shown remarkable performance in knowledge-driven NLP tasks. However, their reliance on parametric knowledge may cause them to overlook contextual cues, leading to incorrect predictions in context-sensitive NLP tasks (e.g., knowledge acquisition tasks). In this paper, we seek to assess and enhance LLMs' contextual faithfulness in two aspects: knowledge conflict and prediction with abstention. We demonstrate that LLMs' faithfulness can be significantly improved using carefully designed prompting strategies. In particular, we identify opinion-based prompts and counterfactual demonstrations as the most effective methods. Opinion-based prompts reframe the context as a narrator's statement and inquire about the narrator's opinions, while counterfactual demonstrations use instances containing false facts to improve faithfulness in knowledge conflict situations. Neither technique requires additional training. We conduct experiments on three datasets of two standard NLP tasks, machine reading comprehension and relation extraction, and the results demonstrate significant improvement in faithfulness to contexts.

---

## Introduction

Large language models (LLMs) have made remarkable advances in solving various NLP problems, particularly in (context-free) knowledge-driven tasks such as question answering and commonsense reasoning. Without external context, LLMs can answer factual questions and achieve comparable results to supervised approaches, indicating that LLMs encode *parametric knowledge* about open-world facts.

[IMAGE: figures/intro.pdf - Examples of knowledge conflict and prediction with abstention. LLMs may ignore the provided context and make unfaithful predictions based on their parametric knowledge before Q4 2021.]

Although parametric knowledge can be beneficial for knowledge-driven tasks, overly relying on it can cause problems in context-specific NLP tasks. First, LLMs may encode misconceptions or obsolete facts, in which case we expect LLMs to update their predictions when provided with relevant context. Second, when using LLMs for knowledge acquisition tasks such as machine reading comprehension (MRC) and information extraction (IE), LLMs should always extract the *knowledge in context* instead of relying solely on their parametric knowledge. In such context-specific application scenarios, we expect LLMs to make decisions faithful to the context and avoid simply parroting answers from pretraining. However, studies have discovered that LLMs can overlook or ignore context, posing a significant challenge for their application in these scenarios.

In this paper, we aim to investigate techniques for improving the faithfulness of LLMs in context-specific NLP tasks. Conceptually, faithfulness is not simply about how much accuracy the model can offer. Instead, it should concern the validity and reliability of its extraction process. Specifically, when there is decision-related information (e.g., a concept or a relation) to extract, a faithful LLM should *genuinely* induce what is described in the context but not give *trivial guesses* based on parametric knowledge or statistical biases. Besides, when no known decision-related information is described in the context, the model should *selectively* abstain from predicting. Accordingly, to provide a realistic assessment of LLMs in terms of faithfulness, we narrow our focus to two sub-problems, namely entity-based knowledge conflict and prediction with abstention. In cases of knowledge conflict, where the given context contains facts different from the pretraining data, LLMs need to return the facts locally described in the context instead of the globally memorized ones. For example, text-davinci-003 identifies *Jack Dorsey* instead of *Elon Musk* as the CEO of Twitter, based on its pretrained data before Q4 2021. In cases of prediction with abstention, where the context does not provide information to answer the questions, LLMs should abstain from making predictions and notify the users, rather than answering the questions that become a trivial guess.

We present various prompting strategies to improve the faithfulness of LLMs, including designing effective prompts and choosing appropriate in-context demonstrations. We find that constraining the scope of questions to the context by adding phrases (e.g., based on the given context) or natural language instructions improve faithfulness in both facets. Particularly, we find that reformulating the context and questions to opinion-based question-answering problems, where the context is expressed in terms of a narrator's statement, and the question asks about this narrator's opinion, delivers the most gains. Additionally, we find that adding counterfactual demonstrations to prompts improves faithfulness in the aspect of knowledge conflict, while using the original (factual) demonstrations leads to limited or negative effects. Finally, combining both techniques delivers the largest gain than using each one independently.

We evaluate our methods based on three datasets, including Re-TACRED for relation extraction, and natural questions and RealTime QA for MRC. We find that the proposed strategies can largely improve faithfulness, e.g., reducing the memorization ratio (the percentage of times that LLMs return memorized answers versus answers in the context) of text-davinci-003 from 35.2% to 3.0% on natural questions. Additionally, we evaluate our methods across LLMs of different scales, finding that larger LLMs are more likely to update memorized answers than smaller ones, both with and without the application of our methods.

---

## Related Work

We discuss two topics of related work that are closely relevant to this work.

**Knowledge conflicts.** LLMs have shown promising results in closed-book QA tasks, indicating their ability to memorize facts about the world. However, as the world is constantly evolving, memorized facts may become outdated, emphasizing the need to update LLMs' predictions with new facts. To address this challenge, some studies have explored ways to identify and edit the facts stored in model parameters. However, it remains unclear whether memory editing methods allow sufficient capacity to encompass all new factual knowledge. Another promising direction is to augment LLM prompting with external context containing relevant knowledge. Coupled with retrieval systems, such methods have the potential to update LLMs with large amounts of new facts. However, such methods face the challenge that LLMs may persist with the memorized facts and ignore the provided context. To tackle this challenge, recent works finetune LLMs on counterfactual contexts, where the original facts are replaced with counterfactual ones. They find that such finetuning processes can effectively improve the LLMs' utilization of contexts. In this study, we propose a novel approach using prompting to improve context faithfulness in LLMs without additional finetuning, which offers a more general and cost-effective method for LLMs.

**Prediction with abstention.** Selective prediction with abstention is an important problem in trustworthy AI. When models are uncertain about their predictions, it is critical that they should admit the uncertainty instead of returning incorrect predictions. Selective prediction may be adopted in different scenarios, such as when instances are close to the decision boundary, or when instances are from different domains to training. In the scope of context-specific NLP, abstention is preferred when the context is irrelevant to the question. For example, SQuAD 2.0 introduces unanswerable questions to extractive MRC. CoQA and QuAC introduce unanswerable questions to conversational question answering. RealTime QA finds that GPT-3 still generates outdated answers when provided with irrelevant documents. To address the problem, some propose answerability augmentation where LLMs should predict *Unanswerable* when presented with an empty or randomly sampled document. Several other works employ variants of confidence calibration techniques to encourage the NLP model to avoid giving a high confidence on any decisions when encountering a case to abstain, which however request white-box accessibility of the incorporated models. We tackle this problem with a part of our prompting method, which we find to significantly enhance the LLMs' ability to make selective predictions without need re-calibration or white-box accessibility of the model.

---

## Method

We focus on context-specific NLP tasks. The input of these tasks is formulated as ```latex $(c, q)$ ``` for free-form generation tasks, where ```latex $c$ ``` is the context and ```latex $q$ ``` is the question, or ```latex $(c, q, o)$ ``` for tasks with close decision spaces (e.g., multi-choice tasks), where ```latex $o$ ``` is the set of decisions/choices. The desired output can be either a free-form text or a choice. We solve these tasks by prompting LLMs and study ways of designing prompting templates and demonstrations that are dedicated to improving the faithfulness of LLMs. Specifically, we find two proposed methods, opinion-based prompts and counterfactual demonstrations, to be the most effective ones. Our methods only change the prompts without finetuning the LLMs, targeting a more general and affordable solution.

### Opinion-based Prompting

Given an input ```latex $(c, q, o)$ ```, we begin with the following *base* prompting template (options only apply to multiple-choice tasks and are removed in free-form text generation tasks):

```
{c} Q: {q}? Options: {o} A:
```

Here, ```latex $\{.\}$ ``` serves as a placeholder to be filled with specific content during prompting. We investigate two types of prompting templates for context-specific NLP, namely *opinion-based* prompts and *instructed* prompts. Opinion-based prompts transform original questions into opinion-seeking questions, which naturally demand more attention to the context. Instructed prompts, on the other hand, explicitly instruct LLMs to read the context by natural language. Details of these templates are discussed in the remaining section.

**Opinion-based prompts.** We propose to transform the context to a narrator's statement and the question to enquire about the narrator's opinion in this statement. This approach is motivated by our own cognitive process for answering different types of questions. When answering questions that seek factual information, we can often rely on our own memory and answer without needing to refer to the context, as these questions typically have only one correct answer. However, when questions are seeking opinions from someone else (in this context, the narrator), it is important to comprehend the narrator's words before answering the questions, as opinions may vary from person to person. Besides, as opinions are inherently subjective and can be influenced by many factors such as personal experiences and beliefs, opinion-seeking questions are sometimes difficult to answer solely based on the narrator's statement compared to a fact-seeking question that typically has definite and verifiable answer(s). As a result, transforming factual questions into opinion-seeking questions can lead to more attention to the context, as memorized answers alone may not suffice. It also helps the model more selectively predict under cases where contexts do not describe answers. Both factors lead to improved faithfulness with LLMs. The *opinion*-based prompting template is as follows:

```
Bob said, "{c}" Q: {q} in Bob's opinion? Options: {o} A:
```

Throughout our experiments, we consistently use Bob to represent the narrator for the context, although other names could be utilized as well.

**Instructed prompts.** We also explicitly instruct LLMs to read context by natural language. We start by extending questions in prompts with attributive phrases such as "based on the given text", leading to the following *attributed* prompting template:

```
{c} Q: {q} based on the given text? Options: {o} A:
```

We also augment the prompts with natural language instructions. Since manually writing instructions can be laborious and often fails to account for the compatibility between instructions and LLMs, we leverage automatic prompt engineering (APE) to generate the prompts. Using a few instances and their desired outputs as demonstrations, APE uses LLMs to automatically generate candidate instructions and select the best one based on the results on a dev set. We then use the following *instruction*-based prompting template:

```
Instruction: {Instruction} {c} Q: {q}? Options: {o} A:
```

Experiments show that all prompting templates perform better than the base prompting template. Specifically, opinion-based prompts outperform instructed prompts in both knowledge conflict and prediction with abstention facets, and combining these two prompting methods results in the most significant improvements.

### Counterfactual Demonstration

Using demonstrations is a standard way to perform few-shot inference on LLMs. To enhance the faithfulness of language models in knowledge conflict scenarios, previous studies propose to finetune the models using counterfactual instances, where the facts in the context are substituted with false ones, and the model learns to update its predictions accordingly. Following this strategy, we propose to use counterfactual instances as demonstrations for LLMs. To do so, we start with a labeled set of counterfactual instances and a test instance and then use KATE to retrieve the most relevant counterfactual instances as demonstrations. We encode both the test instance and counterfactual instances with RoBERTa and select the top counterfactual instances based on cosine similarity. As a part of our analysis, we also experimented with using the original (factual) instances as demonstrations but found this approach to underperform counterfactual demonstrations and sometimes even zero-shot inference.

---

## Experiments

This section presents our experimental setups for the evaluation of the proposed methods concerning two aspects of faithfulness: knowledge conflict and prediction with abstention. We provide additional analysis on results across different model sizes and results on the original datasets. We also show examples of prompts and LLMs' outputs in the case study.

### Experimental Setup

Our experiments are conducted using the InstructGPT model (text-davinci-003, 175B parameters) and LLama-2-7B-chat. We use the base prompt as our baseline, and compare it against the proposed prompting templates, including attributed prompt (Attr), instruction-based prompt (Instr), opinion-based prompt (Opin), and the combination of opinion-based prompt and instruction-based prompt (Opin + Instr). We evaluate the effectiveness of these templates in both zero-shot and few-shot settings (with demonstrations).

### Knowledge Conflict

**Datasets.** We evaluate in the knowledge conflict setting using counterfactual datasets that contain incorrect facts, which can conflict with what the LLM has memorized. We use two datasets based on real-world texts: natural questions for MRC and Re-TACRED for relation extraction (RE). To create counterfactuals, we adopt the framework proposed by Longpre et al., which modifies the context to support a counterfactual answer. Specifically, for MRC, we replace the gold entity answer in the context with a randomly sampled entity of the same entity type from the corpus. For RE, we first randomly sample a context that has the entity mentions of the same type but different relations from the original one, and then insert the original entities into the sampled context. In this scenario, a faithful LLM should update its prediction to the new answer instead of returning the original one. Moreover, to measure LLMs' ability to update answers, we need to ensure that they have memorized the knowledge of the original answers in the first place. Therefore, we only evaluate LLMs on a subset of instances on which these models can correctly predict the original answers without additional contexts.

**Task setup.** We use the same set of evaluation metrics as Longpre et al. Specifically, we measure the frequency that the LLMs' predictions *contain* an exact match of the original answers (```latex $p_o$ ```) and the substituted answers (```latex $p_s$ ```), after both predictions and answers have been normalized by removing stop words and punctuation. To assess the model's reluctance to update its prediction, we use the memorization ratio (```latex $M_R$ ```), which is calculated as ```latex $M_R=\frac{p_o}{p_o + p_s}$ ```. A completely faithful LLM should have an ```latex $M_R$ ``` of 0. We also report task-specific metrics, including exact match (EM) for MRC and ```latex $F_1$ ``` for RE. For EM, we also use normalized predictions and answers, but the requirement is that the prediction and answer must be exactly the same, rather than just containing the answer. We conduct experiments in three different settings: zero-shot, demonstration using original instances, and demonstration using counterfactual instances. We retrieve demonstrations from the original/counterfactual training set, and evaluate LLMs on the counterfactual test set. In the few-shot setting, we utilize a maximum of 16 demonstration instances, up to the limit of the LLM's context window.

**Results and discussion.** The results demonstrate that the combination of Opin + Instr prompting and counterfactual demonstrations is generally the most effective. Compared to the zero-shot base prompts, there is a reduction of 32.2% in ```latex $M_R$ ``` for MRC and a 10.9% reduction for RE on GPT-3.5. Similarly, on LLaMA-2-7B-chat, there is a 39.4% reduction in ```latex $M_R$ ``` for MRC and a 57.3% reduction for RE. We also find that opinion-based prompts generally perform better than other templates, achieving the second-best results on 17 out of 24 metrics on GPT-3.5, and 9 out of 24 metrics on LLama-2, indicating that LLMs are more faithful to the context when answering opinion-seeking questions. Combining opinion-based prompts and instruction-based prompts further improves faithfulness, with the best results obtained in 23 out of 24 metrics on GPT-3.5, and 19 out of 24 metrics on LLama-2.

When it comes to few-shot settings, counterfactual demonstrations lead to further improved performance. Using the original (factual) instances as demonstrations, on the other hand, leads to limited effects or may even impair faithfulness in MRC. This finding suggests that demonstrations do not always improve the generalization of LLMs' inference, especially when they contain dataset bias. In the MRC experiments, the natural questions dataset used is constructed based on Wikipedia, which mainly consists of world facts. This potentially allows for a simplicity bias of LLMs where questions can be answered without contexts. Therefore, our study suggests the importance of using counterfactual demonstrations in knowledge conflict scenarios.

### Prediction with Abstention

**Datasets.** As for the second aspect of faithfulness, we evaluate LLMs' ability to selectively abstain from making uncertain predictions based on irrelevant context. Since existing datasets such as SQuAD 2.0 generally contain questions with confusion and are less related to our problem setting, we curate our own evaluation data based on RealTime QA, a dataset that inquires about novel information from June 2022 onwards. In this formulation, LLMs are presented with a question and multiple choices, and they need to choose the correct answer based on several retrieved documents. These documents were obtained using tools like Google custom search and may not contain the answer to the question. To adapt this dataset to our setting, we added a new "I don't know" choice and relabeled the dataset. Instances where the retrieved documents do not answer the question are relabeled to "I don't know". We used questions in the first six weeks of 2022 as the test set and randomly picked three questions of 2023 as demonstration instances. This process results in a total of 113 test instances, including 63 answerable questions and 50 unanswerable ones.

**Task setup.** We calculate the probability of a choice as ```latex $P(\text{choice}|\text{prompt})$ ``` followed by normalization across all choices. We tried three methods to calculate this: joint probability, per-token probability (joint probability normalized by length), and unconditional probability. We find that joint probability works the best for GPT-3.5, while per-token probability works the best for LLama-2. We report accuracy on the entire dataset (All), accuracy on the subset of questions that can be answered based on retrieved documents (HasAns), and accuracy on questions that cannot be answered based on retrieved documents (NoAns). The latter two metrics measure LLMs' ability to extract answers from context and their ability to abstain from making predictions when the context does not describe the answer, respectively. Besides, we use the probability of "I don't know" as LLM's probability estimation of whether the question can be answered. We use the Brier score to evaluate the accuracy of the estimation, which measures the mean squared difference between the estimation and the true binary outcome of answerability. We use three demonstrations for each instance in the few-shot setting, where some instances are filtered out during evaluation due to exceeding the context length of LLMs.

**Results and discussion.** The results reveal that the Opin + Instr prompt outperforms all others on GPT-3.5, both in the zero-shot and few-shot settings, surpassing base prompts by 57.2% and 16.3% in NoAns subset accuracy, respectively. For LLama-2, this approach similarly outperforms base prompts by 22.4% in both settings. Furthermore, the Brier score is reduced by 24.2% and 7.8% compared to base prompts for GPT-3.5 in the two settings, respectively, and by 2.6% and 1.9% on LLama-2. The Opin prompt is the second best in terms of these metrics. These findings demonstrate that opinion-based prompts can enhance the LLMs' ability to make selective predictions. In addition, the use of demonstrations consistently improves the LLMs' ability to make selective predictions, as evidenced by the lower Brier scores and higher NoAns accuracy in the few-shot setting compared to the zero-shot setting.

### Additional Analysis

**Memorization by different sizes of LLMs.** Overall, Opin + Instr consistently outperforms other prompts across different model sizes. Results are shown for filtered evaluation sets where the corresponding LLMs can correctly predict the original answers without additional contexts, thereof the size of evaluation sets varies across different LLMs. We observe that ```latex $M_R$ ``` generally decreases with increased model size, showing that larger LLMs are better at updating memorized answers based on given contexts in knowledge conflicts. However, larger LLMs have more severe memorization on the full (unfiltered) evaluation set. This is because larger LLMs can memorize more answers than smaller ones, as evidenced by the number of instances in the filtered evaluation set where larger LLMs have more instances. Our analysis suggests that while larger LLMs are better at updating memorized answers, they still tend to have more memorization due to the larger number of memorized answers. Therefore, we need to pay more attention when using larger LLMs in scenarios with new or potentially conflicting knowledge.

[IMAGE: figures/scaling.pdf - Memorization ratios across different sizes of InstructGPTs, evaluated in the zero-shot setting.]

**Selective prediction by different sizes of LLMs.** On smaller LLMs, opinion-based prompt achieves similar or even higher Brier score than base prompts, indicating it does not improve the selective prediction ability of LLMs. We hypothesize that this is because smaller LLMs have inferior reading comprehension ability, resulting in uncertainty in many instances. Opinion-based prompts change uncertain predictions of answerable questions to *I don't know*, which could lead to worse results. For other prompting templates, we do not observe a consistent improvement across different LLMs either. This analysis shows that while the selective prediction ability can be more easily activated by zero-shot prompting for LLMs such as text-davinci-003, smaller LLMs may require dedicated adaptations such as calibration and finetuning to activate this ability.

[IMAGE: figures/absention.pdf - Brier scores across different sizes of InstructGPTs in the zero-shot setting of RealTime QA.]

**Results on original datasets.** While our main experiments demonstrate the effectiveness of the proposed methods in resolving knowledge conflicts, LLMs in real-world applications may also see instances without knowledge conflicts. Therefore, we investigate how our methods affect inference when the memorized answers align with the given contexts. To do so, we evaluate LLMs on the same set of filtered evaluation set used in the main results section, but we use the original contexts and answers instead of counterfactual ones. The results show that opinion-based prompts yield similar or better results in all settings. Furthermore, using either counterfactual or original demonstrations does not significantly impact results on the original (factual) dataset. This analysis reveals that our methods do not impair performance on instances without knowledge conflicts.

### Case Study

The case study shows examples of prompts and the corresponding answers generated by text-davinci-003.

**Knowledge Conflict Example:**

- **Context (Counterfactual passage):** The Super Bowl LI Halftime show took place on February 5, 2017, at NRG Stadium in Houston, Texas as part of Super Bowl LI. The show was headlined by **Bosco**, who performed a medley of her songs, including newer material from her most recent studio album Joanne.

- **Question:** who performed the halftime show at Super Bowl 51

- **Results:**
  - Base: Lady Gaga (incorrect - uses memorized answer)
  - Attr: Lady Gaga (incorrect)
  - Instr: Lady Gaga (incorrect)
  - Opin: Bosco (correct - faithful to context)
  - Opin + Instr: Bosco (correct)
  - **Answer:** Bosco

**Prediction with Abstention Example:**

- **Context:** Tara Connolly is senior gas campaigner at Global Witness, an international NGO working towards a more sustainable, just and equal planet. She has over a decade of experience in EU energy policy. The views expressed in this commentary are her own.

- **Question:** Mo Farah made public that he was trafficked from which African country to the UK
- **Choices:** Somaliland; Djibouti; Ethiopia; Somalia; I don't know

- **Results:**
  - Base: Somalia (incorrect - guesses despite irrelevant context)
  - Attr: Somalia (incorrect)
  - Instr: Somaliland (incorrect)
  - Opin: I don't know (correct - abstains appropriately)
  - Opin + Instr: I don't know (correct)
  - **Answer:** I don't know

These examples demonstrate the effectiveness of proposed prompts in generating context-faithful responses.

---

## Conclusion

In this paper, we focus on addressing the faithfulness issue of LLMs in context-specific NLP tasks, particularly in scenarios with knowledge conflict and prediction with abstention. We propose that two methods, opinion-based prompts and counterfactual demonstrations, are effective in improving LLMs' faithfulness to contexts. We evaluate our methods on three datasets of two tasks, namely machine reading comprehension and relation extraction, and observed significant improvement in faithfulness to contexts. Future work includes evaluating the effectiveness of proposed methods on a broader range of NLP tasks such as open-domain QA and summarization, and studying other techniques to improve faithfulness further.

---

## Limitations

In this study, our main focus is on the utilization of context-augmented prompting, assuming the reliability of the provided context. However, real-world scenarios can be more complicated, which may involve retrieved contexts that contain erroneous or conflicting information. Assessing the factuality of the context solely based on the provided information becomes challenging, as it depends on additional factors such as trustworthiness and timeliness of the information source. Due to the complexity and challenges associated with verifying context reliability, we do not address this issue within the scope of this work. Furthermore, it is important to note that our paper primarily concentrates on the capability of LLMs to generate updated answers or decisions for given questions, rather than exploring more intricate tasks that require the model to apply the updated knowledge in multi-hop reasoning.

---

## Ethical Considerations

Due to the availability of test data, the experiments conducted in this work has been in English, while future work can consider extending the use of proposed techniques to tasks in other languages. The datasets used in this work are public datasets that may not be free of inherent biases. However, the introduced context-faithful prompting techniques in this work do not introduce additional biases beyond what the data have presented.

---

## Appendix: Settings of Automatic Prompt Engineering

We run APE using their official code and default hyperparameters. In the knowledge conflict setting, we use counterfactual datasets to generate instructions. While the APE paper recommends using instructions generated by the same model in inference, we find that smaller LLMs do not generate meaningful instructions for our datasets. Therefore, we use instructions generated by text-davinci-003 across different scales of LLMs in additional analysis. The top three instructions generated by APE on each dataset are listed below. We use the top one instruction in experiments.

**Natural questions:**
1. read the given information and answer the corresponding question.
2. read a piece of text and then use the information in the text to answer a question.
3. "Read the given information and answer the questions that follow."

**Re-TACRED:**
1. identify the relationship between two entities from a list of options.
2. identify the relationship between two entities based on the given input-output pairs.
3. identify the relationship between two entities given the input-output pairs.

**RealTime QA:**
1. answer a question based on the provided input-output pairs.
2. ask a question with a set of choices and ask the friend to provide the correct answer.
3. answer a question related to a news article.

---

**Code and data:** https://github.com/wzhouad/context-faithful-llm
