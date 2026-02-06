# Abstract

Large language models (LMs) are able to in-context learn---perform a new task via inference alone by conditioning on a few input-label pairs (demonstrations) and making predictions for new inputs. However, there has been little understanding of *how* the model learns and *which* aspects of the demonstrations contribute to end task performance. In this paper, we show that ground truth demonstrations are in fact not required---randomly replacing labels in the demonstrations barely hurts performance on a range of classification and multi-choce tasks, consistently over 12 different models including GPT-3. Instead, we find that other aspects of the demonstrations are the key drivers of end task performance, including the fact that they provide a few examples of (1) the label space, (2) the distribution of the input text, and (3) the overall format of the sequence. Together, our analysis provides a new way of understanding how and why in-context learning works, while opening up new questions about how much can be learned from large language models through inference alone.

# Introduction

Large language models (LMs) have shown impressive performance on downstream tasks by simply conditioning on a few input-label pairs (demonstrations); this type of inference has been referred to as *in-context learning* [brown2020language]. Despite in-context learning consistently outperforming zero-shot inference on a wide range of tasks [zhao2021calibrate;  [liu2021makes]], there is little understanding of *how* it works and *which* aspects of the demonstrations contribute to end task performance.

[FIGURE: fig:intro] Results in classification (top) and multi-choice tasks (bottom), using three LMs with varying size. Reported on six datasets on which GPT-3 is evaluated; the channel method is used. See Section 4 for the full results. In-context learning performance drops only marginally when labels in the demonstrations are replaced by random labels.


In this paper, we show that ground truth demonstrations are in fact not required for effective in-context learning (Section [4](#sec:main)). Specifically, replacing the labels in demonstrations with random labels barely hurts performance in a range of classification and multi-choice tasks (Figure [1](#fig:intro)). The result is consistent over 12 different models including the GPT-3 family [radford2019language;  [min2021metaicl]; [wang2021gpt]; [artetxe2021efficient]; [brown2020language]]. This strongly suggests, counter-intuitively, that the model *does not* rely on the input-label mapping in the demonstrations to perform the task.

Further analysis investigates which parts of demonstrations actually *do* contribute to the performance. We identify possible aspects of demonstrations (e.g., the label space and the distribution of the input text) and evaluate a series of variants of the demonstrations to quantify the impact of each (Section [5](#sec:abl)). We find that: (1) the label space and the distribution of the input text *specified by* the demonstrations are both key to in-context learning (regardless of whether the labels are correct for individual inputs); (2) specifying the overall format is also crucial, e.g., when the label space is unknown, using random English words as labels is significantly better than using no labels; and (3) meta-training with an in-context learning objective [min2021metaicl] magnifies these effects---the models almost exclusively exploit simpler aspects of the demonstrations like the format rather than the input-label mapping.

In summary, our analysis provides a new way of understanding the role of the demonstrations in in-context learning. We empirically show that the model (1) counter-intuitively does not rely on the ground truth input-label mapping provided in the demonstrations as much as we thought (Section [4](#sec:main)), and (2) nonetheless still benefits from knowing the label space and the distribution of inputs specified by the demonstrations (Section [5](#sec:abl)). We also include a discussion of broader implications, e.g., what we can say about the model *learning at test time*, and avenues for future work (Section [6](#sec:discuss)).

# Related Work

Large language models have been key to strong performance in a wide range of downstream tasks [devlin2019bert;  [radford2019language]; [liu2019roberta]; [raffel2020exploring]; [lewis2020bart]]. While finetuning has been a popular approach to transfer to new tasks [devlin2019bert], it is often impractical to finetune a very large model (e.g. $\geq$10B parameters). [brown2020language] propose in-context learning as an alternative way to learn a new task. As depicted in Figure [2](#fig:icl), the LM learns a new task via inference alone by conditioning on a concatenation of the training data as demonstrations, without any gradient updates.

In-context learning has been the focus of significant study since its introduction. Prior work proposes better ways of formulating the problem [zhao2021calibrate;  [holtzman2021surface]; [min2021noisy]], better ways of choosing labeled examples for the demonstrations [liu2021makes;  [lu2021fantastically]; [rubin2021learning]], meta-training with an explicit in-context learning objective [chen2021meta;  [min2021metaicl]], and learning to follow instructions as a variant of in-context learning [mishra2021cross;  [efrat2020turking]; [wei2022finetuned]; [sanh2022multitask]]. At the same time, some work reports brittleness and over-sensitivity for in-context learning [lu2021fantastically;  [zhao2021calibrate]; [mishra2021reframing]].

Relatively less work has been done to understand why in-context learning works. [xie2022explanation] provide theoretical analysis that in-context learning can be formalized as Bayesian inference that uses the demonstrations to recover latent concepts. [razeghi2022impact] show that in-context learning performance is highly correlated with term frequencies in the pretraining data. To the best of our knowledge, this paper is the first that provides an empirical analysis that investigates why in-context learning achieves performance gains over zero-shot inference. We find that the ground truth input-label mapping in the demonstrations has only a marginal effect, and measure the impact of finer-grained aspects of the demonstrations.

[FIGURE: fig:icl] An overview of in-context learning. The demonstrations consist of k input-label pairs from the training data (k = 3 in the figure).


# Experimental Setup

[FIGURE: fig:main-results] Results when using no-demonstrations, demonstrations with gold labels, and demonstrations with random labels in classification (top) and multi-choice tasks (bottom). The first eight models are evaluated on 16 classification and 10 multi-choice datasets, and the last four models are evaluated on 3 classification and 3 multi-choice datasets. See Figure 12 for numbers comparable across all models. Model performance with random labels is very close to performance with gold labels (more discussion in Section 4.1).


We describe the experimental setup used in our analysis (Section [4](#sec:main) and [5](#sec:abl)).

#### Models.

We experiment with 12 models in total. We include 6 language models (Table [1](#tab:models)), all of which are decoder-only, dense LMs. We use each LM with two inference methods, direct and channel, following [min2021noisy]. The sizes of LMs vary from 774M to 175B. We include the largest dense LM (GPT-3) and the largest publicly released dense LM (fairseq 13B) at the time of conducting experiments. We also include MetaICL, which is initialized from GPT-2 Large and then meta-trained on a collection of supervised datasets with an in-context learning objective, and ensure that our evaluation datasets do not overlap with those used at meta-training time.

#### Evaluation Data.

We evaluate on 26 datasets, including sentiment analysis, paraphrase detection, natural language inference, hate speech detection, question answering, and sentence completion (full list and references provided in Appendix [7](#app:datasets)).[^1] All datasets are classification and multi-choice tasks.

We use these datasets because they (1) are true low-resource datasets with less than 10K training examples, (2) include well-studied benchmarks from GLUE [wang2018glue] and SuperGLUE [wang2019superglue], and (3) cover diverse domains including science, social media, finance, and more.

[FIGURE: fig:abl_accuracy] Results with varying number of correct labels in the demonstrations. Channel and Direct used for classification and multi-choice, respectively. Performance with no demonstrations (blue) is reported as a reference.


#### Other Details.

We use $k=16$ examples as demonstrations by default for all experiments in the paper, unless otherwise specified. Examples are sampled at uniform from the training data. We choose a set of $k$ training examples using 5 different random seeds and run experiments 5 times. For fairseq 13B and GPT-3, due to limited resources, we experiment with a subset of 6 datasets[^2] and 3 random seeds. We report Macro-F1[^3] for classification tasks and Accuracy for multi-choice tasks. We compute per-dataset average over seeds, and then report macro-average over datasets. We use the minimal templates in forming an input sequence from an example. We refer to Appendix [8](#app:exp-details) for more details. All experiments are reproducible from [`github.com/Alrope123/rethinking-demonstrations`](https://github.com/Alrope123/rethinking-demonstrations).

# Ground Truth Matters Little

## Gold labels vs. random labels

To see the impact of correctly-paired inputs and labels in the demonstrations---which we call the ground truth input-label mapping---we compare the following three methods.[^4]

### No demonstrations

is a typical zero-shot method that does not use any labeled data. A prediction is made via $\mathrm{argmax}_{y \in \mathcal{C}}P(y|x)$, where $x$ is the test input and $\mathcal{C}$ is a small discrete set of possible labels.

### Demonstrations w/ gold labels

are used in a typical in-context learning method with $k$ labeled examples $(x_1, y_1)...(x_k, y_k)$. A concatenation of $k$ input-label pairs is used to make a prediction via $\mathrm{argmax}_{y \in \mathcal{C}}P(y|x_1,y_1...x_k,y_k,x)$.

### Demonstrations w/ random labels

are formed with random labels, instead of gold labels from the labeled data. Each $x_i$ ($1 \leq i \leq k$) is paired with $\tilde{y}_i$ that is randomly sampled at uniform from $\mathcal{C}$. A concatenation of $(x_1, \tilde{y}_1)...(x_k, \tilde{y}_k)$ is then used to make a prediction via $\mathrm{argmax}_{y \in \mathcal{C}}P(y|x_1,\tilde{y}_1...x_k,\tilde{y}_k,x)$.

Results are reported in Figure [3](#fig:main-results). First, using the demonstrations with gold labels significantly improves the performance over no demonstrations,[^5] as it has been consistently found in much of prior work [brown2020language;  [zhao2021calibrate]; [liu2021makes]]. We then find that **replacing gold labels with random labels only marginally hurts performance**. The trend is consistent over nearly all models: models see performance drop in the range of 0--5% absolute. There is less impact in replacing labels in multi-choice tasks (1.7% on average) than in classification tasks (2.6% absolute).

This result indicates that the ground truth input-label pairs are not necessary to achieve performance gains. This is counter-intuitive, given that correctly paired training data is critical in typical supervised training---it informs the model of the expected input-label *correspondence* required to perform the downstream task. Nonetheless, the models *do* achieve non-trivial performance on the downstream tasks. This strongly suggests that the models are capable of recovering the expected input-label correspondence for the task; however, it is *not* directly from the pairings in the demonstrations.

It is also worth noting that there is particularly little performance drop in MetaICL: 0.1--0.9% absolute. This suggests that meta-training with an explicit in-context learning objective actually encourages the model to essentially ignore the input-label mapping and exploit other components of the demonstrations (more discussion in Section [5.4](#subsec:abl_metaicl)).

In Appendix [9.2](#app:task-breakdown), we provide additional results showing that (1) selecting random labels from a true distribution of labels (instead of a uniform distribution) reduces the gap even further, and (2) the trends may depend on the dataset, although the overall trend is consistent over most datasets.

## Ablations

For additional ablations, we experiment with 5 classification and 4 multi-choice datasets.[^6]

[FIGURE: fig:abl_k] Ablations on varying numbers of examples in the demonstrations (k). Models that are the best under 13B in each task category (Channel MetaICL and Direct GPT-J, respectively) are used.


[FIGURE: fig:abl_template] Results with minimal templates and manual templates. ‘+T’ indicates that manual templates are used. Channel and Direct used for classification and multi-choice, respectively.


#### Does the number of correct labels matter?

To further examine the impact of correctness of labels in the demonstrations, we conduct an ablation study by varying the number of correct labels in the demonstrations. We evaluate "Demonstrations w/ $a$% correct labels" ($0 \leq a \leq 100$) which consist of $k \times a/100$ correct pairs and $k \times (1-a/100)$ incorrect pairs (see Algorithm [\[alg:abl_accuracy\]](#alg:abl_accuracy) in Appendix [8](#app:exp-details)). Here, $a=100$ is the same as typical in-context learning, i.e., demonstrations w/ gold labels.

Results are reported in Figure [4](#fig:abl_accuracy). Model performance is fairly insensitive to the number of correct labels in the demonstrations. In fact, always using incorrect labels significantly outperforms no-demonstrations, e.g., preserving 92%, 100% and 97% of improvements from using the demonstrations with MetaICL in classification, MetaICL in multi-choice, and GPT-J in multi-choice, respectively. In contrast, GPT-J in classification sees relatively significant performance drop with more incorrect labels, e.g., nearly 10% drop in performance when always using incorrect labels. Still, always using incorrect labels is significantly better than no demonstrations.

#### Is the result consistent with varying $\boldsymbol{k}$?

We study the impact of the number of input-label pairs ($k$) in the demonstrations. Results are reported in Figure [5](#fig:abl_k). First, using the demonstrations significantly outperforms the no demonstrations method even with small $k$ ($k=4$), and performance drop from using gold labels to using random labels is consistently small across varying $k$, in the range of 0.8--1.6%.[^7] Interestingly, model performance does not increase much as $k$ increases when $k \geq 8$, both with gold labels and with random labels. This is in contrast with typical supervised training where model performance rapidly increases as $k$ increases, especially when $k$ is small. We hypothesize that larger labeled data is beneficial mainly for supervising the input-label correspondence, and other components of the data like the example inputs, example labels and the data format are easier to recover from the small data, which is potentially a reason for minimal performance gains from larger $k$ (more discussion in Section [5](#sec:abl)).

#### Is the result consistent with better templates?

While we use minimal templates by default, we also explore manual templates, i.e., templates that are manually written in a dataset-specific manner, taken from prior work (details in Appendix [8](#app:exp-details)). Figure [6](#fig:abl_template) shows that the trend---replacing gold labels with random labels barely hurting performance---holds with manual templates. It is worth noting that using manual templates does not always outperform using minimal templates.

# Why *does* In-Context Learning work?

Section [4](#sec:main) shows that the ground truth input-label mapping in the demonstrations has little impact to performance gains from in-context learning. This section further examines what other aspects of the demonstrations lead to good performance of in-context learning.

[FIGURE: fig:composition] Four different aspects in the demonstrations: the input-label mapping, the distribution of the input text, the label space, and the use of input-label pairing as the format of the demonstrations.


[FIGURE: fig:abl_input] Impact of the distribution of the inputs. Evaluated in classification (top) and multi-choice (bottom). The impact of the distribution of the input text can be measured by comparing ◼ and ◼. The gap is substantial, with an exception in Direct MetaICL (discussion in Section 5.1).


We identify four aspects of the demonstrations $(x_1, y_1)...(x_k, y_k)$ that potentially provide learning signal (depicted in Figure [7](#fig:composition)).

1.  **The input-label mapping**, i.e., whether each input $x_i$ is paired with a correct label $y_i$.

2.  **The distribution of the input text**, i.e., the underlying distribution that $x_1...x_k$ are from.

3.  **The label space**, i.e., the space covered by $y_1...y_k$.

4.  **The format**---specifically, the use of input-label pairing as the format.

As Section [4](#sec:main) does for the input-label mapping, we design a series of variants of the demonstrations that quantify the impact of each aspect in isolation (Section [5.1](#subsec:abl_input)--[5.3](#subsec:abl_format)). We then additionally discuss the trend of the models meta-trained with an in-context learning objective (Section [5.4](#subsec:abl_metaicl)). For all experiments, models are evaluated on five classification and four multi-choice datasets as in Section [4.2](#subsec:abl_main). See Appendix [8](#app:exp-details) and Table [\[tab:example_demons\]](#tab:example_demons) for implementation details and example demonstrations, respectively.

[FIGURE: fig:abl_label] Impact of the label space. Evaluated in classification (top) and multi-choice (bottom). The impact of the label space can be measured by comparing ◼ and ◼. The gap is significant in the direct models but not in the channel models (discussion in Section 5.2).


## Impact of the distribution of the input text

We experiment with **OOD demonstrations** which include out-of-distribution (OOD) text instead of the inputs from unlabeled training data. Specifically, a set of $k$ sentences $\{x_{i,\mathrm{rand}}\}_{i=1}^k$ are randomly sampled from an external corpus, and replace $x_1...x_k$ in the demonstrations. This variant assesses the impact of the distribution of the input text, while keeping the label space and the format of the demonstrations.

#### Results.

Figure [8](#fig:abl_input) shows that using out-of-distribution inputs instead of the inputs from the training data significantly drops the performance when Channel MetaICL, Direct GPT-J or Channel GPT-J are used, both in classification and multi-choice, by 3--16% in absolute. In the case of Direct GPT-J in multi-choice, it is even significantly worse than no demonstrations. Direct MetaICL is an exception, which we think is the effect of meta-training (discussion in Section [5.4](#subsec:abl_metaicl)).

This suggests that in-distribution inputs in the demonstrations substantially contribute to performance gains. This is likely because conditioning on the in-distribution text makes the task closer to language modeling, since the LM always conditioned on the in-distribution text during training.

## Impact of the label space

We also experiment with **demonstrations w/ random English words** that use random English words as labels for all $k$ pairs. Specifically, we sample a random subset of English words $\mathcal{C}_\mathrm{rand}$ where $|\mathcal{C}_\mathrm{rand}|=|\mathcal{C}|$, and randomly pair $\tilde{y}_i \in \mathcal{C}_\mathrm{rand}$ with $x_i$. This variant assesses the impact of the label space, while keeping the distribution of the input text and the format of the demonstrations.

[FIGURE: fig:abl_format] Impact of the format, i.e., the use of the input-label pairs. Evaluated in classification (top) and multi-choice (bottom). Variants of demonstrations without keeping the format (◼ and ◼) are overall not better than no demonstrations (◼). Keeping the format is especially significant when it is possible to achieve substantial gains with the label space but without the inputs (◼ vs. ◼ in Direct MetaICL), or with the input distribution but without the labels (◼ vs. ◼ in Channel MetaICL and Channel GPT-J). More discussion in Section 5.3.


#### Results.

Based on Figure [9](#fig:abl_label), direct models and channel models exhibit different patterns. With direct models, the performance gap between using random labels within the label space and using random English words is significant, ranging between 5--16% absolute. This indicates that conditioning on the label space significantly contributes to performance gains. This is true even for multi-choice tasks where there is no fixed set of labels---we hypothesize that multi-choice tasks still do have a particular distribution of the choices (e.g., objects like "Bolts" or "Screws" in the OpenBookQA dataset) that the model uses.

On the other hand, removing the output space does not lead to significant drop in the channel models: there is 0--2% drop in absolute, or sometimes even an increase. We hypothesize that this is because the channel models only condition on the labels, and thus are not benefiting from knowing the label space. This is in contrast to direct models which must *generate* the correct labels.

## Impact of input-label pairing

Section [5.1](#subsec:abl_input) and [5.2](#subsec:abl_label) focus on variants which keep the format of the demonstrations as much as possible. This section explores variants that change the format. While there are many aspects of the format, we make minimal modifications to remove the pairings of inputs to labels. Specifically, we evaluate **demonstrations with no labels** where the LM is conditioned on the concatenation of $x_1...x_k$, and **demonstrations with labels only** where the LM is conditioned on the concatenation of $y_1...y_k$. These ablations provide the no-format counterparts of the 'demonstrations with random English words' and 'demonstrations with OOD inputs', respectively.

#### Results.

Based on Figure [10](#fig:abl_format), removing the format is close to or worse than no demonstrations, indicating the importance of the format. This is likely because conditioning on a sequence of input-label pairs triggers the model to mimic the overall format and complete the new example as expected when the test input is given.

More interestingly, keeping the format plays a significant role in retaining a large portion of performance gains by only using the inputs or only using the labels. For instance, with Direct MetaICL, it is possible to retain 95% and 82% of improvements from in-context learning (demonstrations with gold labels) by simply sampling random sentences from a corpus and randomly pairing them with the label set ($\blacksquare$ in Figure [10](#fig:abl_format)) in classification and multi-choice, respectively. Similarly, with the channel models, it is possible to retain 82%, 87%, 86% and 75% of improvements from in-context learning by simply pairing each input from the unlabeled training data with a random English word ($\blacksquare$ in Figure [10](#fig:abl_format)) in MetaICL classification, GPT-J classification, MetaICL multi-choice and GPT-J multi-choice, respectively. For all of these cases, removing inputs instead of using OOD inputs, or removing labels instead of using random English words is significantly worse, indicating that **keeping the format of the input-label pairs is key**.

## Impact of meta-training

Different from other models, MetaICL is trained with an in-context learning objective, in line with recent work that uses multi-task training on a large collection of supervised datasets (called meta-training) for generalization to new tasks [aghajanyan2021muppet;  [khashabi2020unifiedqa]; [wei2022finetuned]; [sanh2022multitask]]. We aim to better understand the role of this meta-training in relation with our findings by closely examining the result of MetaICL. In particular, we observe that the patterns we see so far are significantly more evident with MetaICL than with other models. For instance, the ground truth input-label mapping matters even less, and keeping the format of the demonstrations matters even more. There is nearly zero influence of the input-label mapping and the input distribution in Direct MetaICL, and the input-label mapping and the output space in Channel MetaICL.

Based on this observation, we hypothesize that **meta-training encourages the model to exclusively exploit simpler aspects of the demonstrations and to ignore others**. This is based on our intuition that (1) the input-label mapping is likely harder to exploit, (2) the format is likely easier to exploit, and (3) the space of the text that the model is trained to generate is likely easier to exploit than the space of the text that the model conditions on.[^8]

Motivated by observations from previous sections, this section aims to build a better zero-shot method by leveraging the demonstration without labeled training data.

## Method

We start from **Random demonstration** in Section [4.1](#subsec:main), and additionally introduce Silver demonstration and IterSilver demonstration. All methods form the silver demonstration by using the LM to make a prediction on in-domain unlabeled data $x_i \in \mathcal{X}$ ($1 \leq i \leq k$), and then use the silver demonstration to make a prediction on the test input.


[FIGURE: fig:silver-result] Results of methods that do not use labeled data.


### Random demonstration

makes a random prediction for each $x_i \in \mathcal{X}$, as described in Section [4.1](#subsec:main).

### Silver demonstration

(the first in Algorithm [\[alg:silver\]](#alg:silver)) makes a prediction for each $x_i \in \mathcal{X}$ by using the no-demonstration method: $\tilde{y}_i = \mathrm{argmax}_{y \in \mathcal{C}}P(y|x_i)$. Then, $(x_1, \tilde{y}_1)...(x_k, \tilde{y}_k)$ is used as a silver demonstration that is fed when making a prediction to the test input.

### IterSilver demonstraction

(the second in Algorithm [\[alg:silver\]](#alg:silver)) sequentially makes a prediction for $x_1...x_k$. It first uses the no-demonstration method for $x_1$, and then uses $(x_1, \tilde{y}_1)...(x_{i-1}, \tilde{y}_{i-1})$ as the demonstration to make a prediction for $x_i$ ($i \geq 2$). Intuitively, this will lead to more accurate labels than SilverDemons for $i \geq 2$ given that using the demonstration is better than the no-demonstration method even if the demonstration is inaccurate.

We compare the above methods with (1) No-Demonstration, (2) Gold Demonstration, and (3) No-Demonstration with engineered templates. The last model is the only one in this paper that uses engineered templates instead of minimal templates, which we compare against to show that our methods outperform a competitive previous, engineered zero-shot method, despite not relying on such engineering. More details are provided in Appendix [8](#app:exp-details).

## Results

We experiment with the best ICL-trained model and the best non-ICL-trained model under 13B: Channel MetaICL and Channel GPT-J for classification tasks, and Channel MetaICL and Direct GPT-J for multi-choice tasks. We evaluate on 4 classification datasets and 4 multi-choice datasets as in Section [5](#sec:abl).

Results are reported in Figure [11](#fig:silver-result).

# Discussion & Conclusion

In this paper, we study the role of the demonstrations with respect to the success of in-context learning. We find that the ground truth input-label mapping in the demonstrations matters significantly less than one might think---replacing gold labels with random labels in the demonstrations only marginally lowers the performance. We then identify a series of aspects in the demonstrations and examine which aspect actually contributes to performance gains. Results reveal that (1) gains are mainly coming from *independent* specification of the input space and the label space, (2) the models can still retain up to 95% of performance gains by using either the inputs only or the label set only if the right format is used, and (3) meta-training with an in-context learning objective magnifies these trends. Together, our findings lead to a set of broader indications about in-context learning, as well as avenues for future work.

#### Does the model *learn* at test time?

If we take a strict definition of learning: capturing the input-label correspondence given in the training data, then our findings suggest that LMs do not learn new tasks at test time. Our analysis shows that the model may ignore the task defined by the demonstrations and instead use prior from pretraining.

However, *learning* a new task can be interpreted more broadly: it may include adapting to specific input and label distributions and the format suggested by the demonstrations, and ultimately getting to make a prediction more accurately. With this definition of learning, the model *does* learn the task from the demonstrations. Our experiments indicate that the model *does* make use of aspects of the demonstrations and achieve performance gains.

#### Capacity of LMs.

The model performs a downstream task without relying on the input-label correspondence from the demonstrations. This suggests that the model has learned the (implicit notion of) input-label correspondence from the language modeling objective alone, e.g., associating a positive review with the word 'positive'. This is in line with [reynolds2021prompt] who claim that the demonstrations are for *task location* and the intrinsic ability to perform the task is obtained at pretraining time.[^9]

On one hand, this suggests that the language modeling objective has led to great zero-shot *capacity*, even if it is not always evident from the naive zero-shot *accuracy*. On the other hand, this suggests that in-context learning may not work on a task whose input-label correspondence is not already captured in the LM. This leads to the research question of how to make progress in NLP problems that in-context learning does not solve: whether we need a better way of extracting the input-label mappings that are already stored in the LM, a better variant of the LM objective that learns a wider range of task semantics, or explicit supervision through fine-tuning on the labeled data.

#### Connection to instruction-following models.

Prior work has found it promising to train the model that reads the natural language description of the task (called instructions) and performs a new task at inference [mishra2021cross;  [efrat2020turking]; [wei2022finetuned]; [sanh2022multitask]]. We think the demonstrations and instructions largely have the same role to LMs, and hypothesize that our findings hold for instruction-following models: the instructions prompt the model to recover the capacity it already has, but do not supervise the model to learn novel task semantics. This has been partially verified by [webson2022prompt] who showed that the model performance does not degrade much with irrelevant or misleading instructions. We leave more analysis on instruction-following models for future work.

#### Significantly improved zero-shot performance.

One of our key findings is that it is possible to achieve nearly $k$-shot performance without using any labeled data, by simply pairing each unlabeled input with a random label and using it as the demonstrations. This means our zero-shot baseline level is significantly higher than previously thought.[^10] Future work can further improve the zero-shot performance with relaxed assumptions in access to the unlabeled training data.

# Limitation

#### Effect of types of tasks and datasets.

This paper focuses on the tasks from established NLP benchmarks that have *real* natural language inputs. Synthetic tasks with more limited inputs may actually use the ground truth labels more, as observed by [rong2021extrapolating].

We report macro-level analysis by examining the average performance over multiple NLP datasets, but different datasets may behave differently. Appendix [9.2](#app:task-breakdown) discusses this aspect, including findings that there are larger gaps between using the ground truth labels and using the random labels in some dataset-model pairs (e.g., in the most extreme case, nearly 14% absolute on the financial_phrasebank dataset with GPT-J). Since the first version of our paper, [kim2022ground] showed that using negated labels substantially lowers the performance in classification.[^11] We believe it is important to understand to what extend the model needs the ground truth labels to successfully perform in-context learning.

#### Extensions to generation.

Our experiments are limited to classification and multi-choice tasks. We hypothesize that ground truth output may not be necessary for in-context learning in the open-set tasks such as generation, but leave this to future work. Extending of our experiments to such tasks is not trivial, because it requires a variation of the output which has incorrect input-output correspondence while keeping the correct output distribution (which is important based on our analysis in Section [5](#sec:abl)).

Since the first version of our paper, [madaan2022text] conducted a similar analysis with the chain of thought prompting [wei2022chain] which generates a rationale to perform complex tasks such as math problems. [madaan2022text] show that, while simply using a random rationale in the demonstrations (e.g., pairing with a rationale from a different example) significantly degrades the performance, other types of counterfactual rationales (e.g., wrong equations) do not degrade the performance as much as we thought. We refer to [madaan2022text] for more discussions on what aspects of the rationale matter or do not matter.


# Full Datasets

We include 26 datasets as follows: financial_phrasebank [financial-phrasebank], poem_sentiment [sheng-uthus-2020-investigating], medical_questions_pairs [medical-qqp], glue-mrpc [dolan-brockett-2005-automatically], glue-wnli [levesque2012winograd], climate_fever [Diggelmann2020CLIMATEFEVERAD], glue-rte [dagan2005pascal;  [bar2006second]; [giampiccolo2007third]; [bentivogli2009fifth]], superglue-cb [Marneffe_Simons_Tonhauser_2019], sick [marelli-etal-2014-sick] , hate_speech18 [gibert2018hate], ethos-national_origin [Mollas2020ETHOSAO], ethos-race [Mollas2020ETHOSAO], ethos-religion [Mollas2020ETHOSAO], tweet_eval-hate [barbieri-etal-2020-tweeteval], tweet_eval-stance_atheism [barbieri-etal-2020-tweeteval], tweet_eval-stance_feminist [barbieri-etal-2020-tweeteval], quarel [Tafjord_Clark_Gardner_Yih_Sabharwal_2019], openbookqa [mihaylov-etal-2018-suit], qasc [Khot_Clark_Guerquin_Jansen_Sabharwal_2020], commonsense_qa [talmor-etal-2019-commonsenseqa], ai2_arc [Clark2018ThinkYH], codah [chen-etal-2019-codah], superglue-copa [gordon-etal-2012-semeval], dream [sun-etal-2019-dream], quartz-with_knowledge [tafjord-etal-2019-quartz], quartz-no_knowledge [tafjord-etal-2019-quartz]. The choice of datasets is made following low-resource datasets in [min2021metaicl], with the exact same set of $k$-shot train data using 5 random seeds. We use the HuggingFace version of the data [lhoest-etal-2021-datasets] and use the development data for evaluation, following [ye2021crossfit]. See Table [3](#tab:data) for statistics.


# Experimental Details

#### Example template

We follow [ye2021crossfit] [min2021metaicl;  [logan2021cutting]] in using the minimal format to transform the input to a sequence (e.g. a concatenation of multiple inputs) and using the label words from each dataset as it is. We also explore manual templates taken from prior work [holtzman2021surface;  [zhao2021calibrate]] as reported in Section [4.2](#subsec:abl_main), although we find that using these templates is not consistently better than using minimal templates. We thus run main experiments with minimal templates. Example templates are provided in Table [\[tab:template-examples\]](#tab:template-examples).

#### Format of the demonstrations

We follow the standard of each model for formatting the demonstrations, either from exploration in prior work or the example code provided in the official tutorial. For GPT-2, we separate the input and the label, and each demonstration example with a space. For MetaICL, GPT-J and GPT-3, we separate the input and the label with a newline (`\n`), and each demonstration example with three newlines. For fairseq models, we use a newline to separate the input and the label as well as each demonstration example.

\[Algorithm removed for conversion\]

[FIGURE: fig:app-main-results] Results of No-demonstration, Gold demonstration and Random demonstration on 3 classification datasets (top) and 3 multi-choice datasets (bottom). Details in Section 4.1. This figure is for providing numbers that are comparable across models—full results with more datasets are reported in Figure 3.


#### Details in variants of the demonstrations

For "demonstrations w/ $a$% accurate labels" ($0 \leq a \leq 100$), we use $k \times a/100$ correct pairs and $k \times (1-a/100)$ incorrect pairs in a random order, as described in Algorithm [\[alg:abl_accuracy\]](#alg:abl_accuracy). For "OOD demonstrations", we use CC-News [nagel2016cc] as an external corpus. We consider the length of the text during sampling, so that sampled sentences have similar length to the test input. For "demonstrations with random English words", we use [`pypi.org/project/english-words`](https://pypi.org/project/english-words) for the set of English words, which consists of 61,569 words.

Table [\[tab:example_demons\]](#tab:example_demons) provides a list of example demonstrations for each method used in Section [5](#sec:abl).

# More Experimental Results

## Gold labels vs. random labels

Figure [12](#fig:app-main-results) shares the same interface as Figure [3](#fig:main-results), but all models are evaluated on 3 classification and 3 multi-choice datasets and are thus comparable to each other.

## Random labels from true distribution of labels & Task breakdown

In Section [4](#sec:main), random labels are sampled from the label space from a uniform distribution. We experiment with another variant of demonstrations in the classification tasks, where labels are randomly sampled from the true distribution of labels on the training data. This may have large impact if labels are far from uniform on the training data. Results indicate that performance drop from using gold labels is further reduced compared to using uniformly random labels: with Channel MetaICL, the gap is reduced from 1.9% to 1.3% absolute, and with Channel GPT-J, the gap is reduced from 5.0% to 3.5% absolute.

Figure [13](#fig:task-breakdown) shows performance gap between using gold labels and using random labels per dataset. We find that the trend that the gap is smaller than previously thought is consistant across most datasets. Nonetheless, there are a few outlier datasets where performance gap is non-negligible, such as financial_phrasebank and a few hate speech detection datasets. Future work may investigate on which tasks the model makes more use of the correctly paired training data.

## More variants of the demonstrations

We explored **demonstrations with a constant label** where all labels in the demonstrations are replaced with a constant text, "`answer`". Specifically, a prediction is made via $\mathrm{argmax}_{y \in \mathcal{C}}P(y|x_1,\texttt{answer}...x_k,\texttt{answer},x)$. This can be viewed as another way to remove the impact of the label space while keeping the impact of the distribution of the input text. However, results are consistently worse than the results of demonstrations with random English labels. We think this is because constant labels actually change the format of the demonstrations, since they can be viewed as part of a separator between different demonstration examples.

We also explored **demonstrations with the test input** where all inputs in the demonstrations are replaced with the test input, each paired with a random label. Specifically, a prediction is made via $\mathrm{argmax}_{y \in \mathcal{C}}P(y|x,\tilde{y}_1...x,\tilde{y}_k,x)$, where $\tilde{y}_i$ ($1 \leq i \leq k$) is randomly sampled at uniform from $\mathcal{C}$. This variant is seemingly a reasonable choice given that it satisfies the condition that the inputs in the demonstrations come from the same distribution as the test input (since they are identical), and using random labels is as good as using gold labels. Nonetheless, we find that this variant is significantly worse than most other methods with demonstrations. We think this is because using the constant input for all demonstration example significantly changes the format of the sequence, since the input can be viewed as part of a separator between different demonstration examples.

[FIGURE: fig:task-breakdown] Performance gap from using the demonstrations with gold labels to using the demonstrations with random labels. Datasets are sorted in descending order. The top two figures use random labels that are sampled at uniform, with Channel MetaICL and Channel GPT-J, respectively. The bottom two figures use random labels that are sampled from a true distribution of labels on the training data, with Channel MetaICL and Channel GPT-J, respectively.


[^1]: For convenience, we use 'labels' to refer to the output for the task, though our datasets include non-classification tasks.

[^2]: Three classification and three multi-choice: MRPC, RTE, Tweet_eval-hate, OpenbookQA, CommonsenseQA, COPA.

[^3]: Known to be better for imbalanced classes.

[^4]: Without loss of generality, all methods in Section [4](#sec:main) and [5](#sec:abl) are described based on the direct method, but can be trivially converted to the channel method by flipping $x$ and $y$.

[^5]: There are some exceptions, e.g., in the classification tasks, Direct GPT-2, Direct GPT-J and Direct fairseq 6.7B models are not significantly better than random guessing on many datasets; Channel fairseq 13B has significantly better no-demonstrations performance compared to demonstrations with gold labels. We thus discuss the results from these models less significantly for the rest of analysis.

[^6]: Classification includes: MRPC, RTE, Tweet_eval-hate, SICK, poem-sentiment; Multi-choice includes OpenbookQA, CommonsenseQA, COPA and ARC.

[^7]: With an exception of 4.4% in classification with $k=4$, likely due to a high variance with a very small value of $k$.

[^8]: That is, the direct model exploits the label space better than the input distribution, and the channel model exploits the input distribution better than the label space.

[^9]: However, while [reynolds2021prompt] claims that the demonstrations are thus unnecessary, we think using the demonstrations is actually the most unambiguous and the easiest way to prompt the model to perform a task.

[^10]: We take the perspective that using the unlabeled training data is permitted [kodirov2015unsupervised;  [wang2019survey]; [schick2021s]].

[^11]: Note that [kim2022ground] estimate the random label performance by interpolating with the performance using negated labels, while our paper samples the random labels at uniform.
