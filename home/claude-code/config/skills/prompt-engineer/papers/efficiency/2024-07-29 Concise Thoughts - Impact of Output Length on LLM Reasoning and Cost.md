# Abstract {#abstract .unnumbered}

Today's large language models (LLMs) can solve challenging question-answering tasks, and prompt engineering techniques, such as chain-of-thought (CoT), have gained attention for enhancing the explanation and correctness of outputs. Nevertheless, models require significant time to generate answers augmented with lengthy reasoning details. To address this issue, this paper analyzes the impact of output lengths on LLM inference pipelines and proposes novel metrics to evaluate them in terms of _correct conciseness_. It also examines the impact of controlling output length through a refined prompt engineering strategy, Constrained-CoT (CCoT), which encourages the model to limit output length. Experiments on pre-trained LLMs demonstrated the benefit of the proposed metrics and the effectiveness of CCoT across different models. For instance, constraining the reasoning of LLaMA2-70b to 100 words improves the accuracy from 36.01% (CoT) to 41.07% (CCoT) on the GSM8K dataset, while reducing the average output length by 28 words.

# Introduction {#sec:intro}

In recent years, large language models (LLMs) have demonstrated remarkable capabilities in tackling complex question-answering tasks, making significant strides in natural language understanding and generative AI [@taori2023stanford; @chiang2023vicuna; @dolly2023introducing; @geng2023koala]. The continuous advancements made in architectures and training methods played a crucial role in enhancing the performance of these models. Alongside these developments, prompt techniques have also seen substantial evolution. One such technique that has attracted considerable attention is chain-of-thought (CoT) prompting [@wei2022chain; @fu2023chain]. This approach enhances the explanation and correctness of the output by encouraging the LLM to articulate its answer through intermediate reasoning steps.

Despite the mentioned advantages, the CoT prompting can lead to longer outputs, increasing the time required for the model to generate a response. This is due to the nature of autoregressive transformers, which decode text word by word, each time running a new inference pass of the decoder module [@vaswani2017attention; @shekhar2024towards]. This implies that the time required to generate a response is heavily influenced by the length of the reasoning provided, which can also vary depending on the prompt. Such long and variable delays in the responses are undesirable when the LLM has to relate with a user through an interactive conversation. This issue highlights the need to consider i) metrics for evaluating the conciseness of the outputs and ii) solutions to avoid excessively long chains of reasoning.

To this end, the first part of this work presents some motivational experiments to show the relation between output length and inference time of an LLM. Then, it proposes three novel metrics to account for the conciseness and correctness of a generated answer. The objective of the proposed metrics is to reweight the accuracy of a given model by considering aspects related to output lengths that affect the inference time of the model and its time predictability.

To address the significant increase in output length caused by CoT techniques, the second part of this work examines how to control the length of CoT reasoning with specific prompting requests. Specifically, we introduce a refined prompt engineering strategy called constrained-CoT (CCoT), designed to encourage an LLM to limit the output length and control the reasoning process. The main idea is to explicitly ask the model to provide an output with a length less than a given bound, thus pushing the LLM to produce concise reasoning. In this case, we must ensure that the model outputs remain accurate and time-bound.

The proposed technique is evaluated through experiments to explore the impact of CCoT on both generation times and the correctness of the responses while simultaneously demonstrating the benefits of measuring this trade-off through the proposed metrics. Experiments conducted on various pre-trained LLMs of different sizes in a zero-shot question-answering (QA) setting highlighted that the performance of the CCoT method strongly depends on the specific LLM and the type of task. For example, using Llama2-70b on the GSM8K benchmark, constraining the reasoning length to 100 words (CCoT-100) increases the accuracy from 36.01% (with a plain CoT) to 41.07%, while the average output length reduces from 99 to 71 words. Conversely, the accuracy reduces when CCoT is used on small and medium-size models (e.g., Falcon-7b and Vicuna-13b). We believe that emphasizing the importance of conciseness in reasoning for QA tasks could provide significant insights into the correct use of CoT and the future training of LLMs.

To summarize, this work provides the following main contributions:

- It proposes three novel metrics to evaluate the correctness of LLM outputs while accounting for the conciseness of the output reasoning, emphasizing the importance of brevity and efficiency.

- It presents the Constrained-Chain-of-Thought (CCoT), a novel prompt engineering strategy that encourages LLMs to limit the length of their reasoning, thereby improving their time-predictability.

- It reports several experiments on pre-trained LLMs, demonstrating the effectiveness of CCoT in improving both accuracy and response times for large models while highlighting limitations across different model sizes.

The rest of the paper is organized as follows: Section [2](#sec:rel){reference-type="ref" reference="sec:rel"} discusses the literature related to this work; Section [3](#sec:motivations){reference-type="ref" reference="sec:motivations"} motivates the addressed study; Section [4](#sec:metrics){reference-type="ref" reference="sec:metrics"} presents a set of metrics that account for conciseness; Section [5](#sec:method){reference-type="ref" reference="sec:method"} introduces the proposed CCoT approach; Section [6](#sec:exp){reference-type="ref" reference="sec:exp"} reports the results of a set of experiments carried out on different pre-trained models; and Section [7](#sec:conclusion){reference-type="ref" reference="sec:conclusion"} states the conclusions and discusses some future directions.

# Related Work {#sec:rel}

To the best of our knowledge, most recent works on LLMs focused on increasing their accuracy [@jiang2020can; @kaplan2020scaling; @zhu2023promptbench]. However, as models scale up, they tend to generate more extensive and articulated responses [@bhargava2023s], which can introduce other problems, such as hallucinations (where the model produces information that appears plausible but not grounded [@kadavath2022language], or unnecessarily long explanations [@qiu2024efficient; @azaria2023internal], which can obscure key information, making it difficult for users to extract relevant content efficiently [@khashabi2021gooaq; @wang2024beyond]. To filter out useless reasoning, Li et al. [@li2021addressing] proposed a multi-hop processing technique, where an extraction task on the encoder to obtain the rationale for an answer, which is the most relevant piece of text in an input prompt to a given question.

To further improve the accuracy of LLMs, several prompt engineering approaches have been presented in recent years [@qin2021learning]. Prompt engineering involves the strategic design of input patterns to guide the model toward generating more accurate and relevant responses [@reynolds2021prompt; @marvin2023prompt]. However, most of these approaches have been conceived to enhance model accuracy, increasing the output length. For instance, lo et al. [@lo2023clear] and strobelt et al. [@strobelt2022interactive] introduced prompt-based approaches by adding task-specific patterns to frame the input data. While these methods allow boosting accuracy, they can also produce longer outputs due to the additional context and detail introduced by the prompt, making it challenging to provide factual and concise answers [@shi2023large].

Another form of prompt engineering was proposed to improve reasoning within the conclusive answer. In this context, Chain-of-Thought (CoT) prompting [@wei2022chain] is one of the most notable methods, showing significant benefits in QA tasks by requiring the model to provide a step-by-step explanation along with the final response. However, as also highlighted in Section [3](#sec:motivations){reference-type="ref" reference="sec:motivations"}, answers generated with CoT tend to be lengthy, hence increasing the generation time [@liu2018controlling; @takase2019positional].

Given the substantial amount of work focused on improving the accuracy of LLMs, it is not surprising that most of the adopted metrics [@lin2004rouge; @stallings1971note] and benchmarks [@clark2018think; @lin2021truthfulqa] only address the correctness of the responses, without paying attention to conciseness and response times [@bhargava2023s]. As already mentioned in Section [1](#sec:intro){reference-type="ref" reference="sec:intro"}, these properties are instead desirable in applications that require an interactive conversation with the user.

#### This work.

To face these challenges, this work proposes novel metrics that account for both the conciseness and the correctness of the responses. Furthermore, to understand the capability of LLMs to control the length of reasoning in their outputs, this work proposes a revised version of the CoT prompting [@wei2022chain], Constrained Chain-of-Thought (CCoT), which explicitly asks the model to control the length of its reasoning. We support the analysis by evaluating the novel metrics and testing the proposed prompting approach, understanding how it affects the quality of the answers and, specifically, the response time of the LLMs.

# Motivational considerations {#sec:motivations}

The output generation time of an LLM depends on various factors, including the model architecture, the pre-and post-processing steps, the answer decoding process, and the question posed, also considering the use of prompt engineering approaches. While the computational cost due to the architecture is well understood, the influence of the other aspects on the overall generation time is less clear and requires further investigation. More formally, an LLM can be represented as a function $f$ that takes as input a prompt $x$ with $\mathcal{N}(x)$ tokens[^1] and generates an output $\hat{y} = f(x)$, having $\mathcal{N}(\hat{y})$ tokens, where $\mathcal{N}$ is a length operator that simply counts the number of tokens. The input $x$ can be considered as composed of the original user input $x_{\text{us}}$ and a prompt engineering text $x_p$, depending on the technique used. For instance, in a zero-shot CoT setting, the prompt can be computed as $x = \textit{concat}(x_{\text{us}}, x_p)$, where $x_p$ is an explicit request for providing reasoning steps in the answer and $\textit{concat}(a, b)$ is the concatenation operator that merges two vectors $a$ and $b$ into a single one.

In an encoder-decoder architecture, as the one used by Transformers [@vaswani2017attention], let $f_e(x)$ and $f_d(x)$ denote the functions associated with the encoder and the decoder, respectively. Then, the output $\hat{y}$ is a list of tokens $[a^{(1)}, \ldots, a^{(\mathcal{N}(\hat{y}))}]$, where each $a^{(i)}$ is computed based on the previously generated tokens and the encoder's embedding representation $f_e(x)$. That is, $$\begin{equation}
\label{eq:out_tokens}
a^{(i)} = f_d(f_e(x), [a^{(0)}, \ldots, a^{(i-1)}]), \quad i > 0.
\end{equation}$$ From Equation [\[eq:out_tokens\]](#eq:out_tokens){reference-type="eqref" reference="eq:out_tokens"}, it is clear that the larger the set of output tokens in the answer, the higher the time the model takes to generate the answer due to the increased number of times the decoder is invoked.

<figcaption>Analysis of the impact of CoT on Falcon-40b efficiency: (a) Relation between response time and output length, without CoT (blue dots) and with CoT (red dots), across 100 questions from the GSM8K test set. (b) Output words variation between output length with CoT and without CoT using 50 random samples from the GSM8K test set.</figcaption>
</figure>

To highlight such a dependency, we conducted a preliminary test on four models of different size, specifically Falcon-7b/40b and Llama2-7b/70b (details in Section [6](#sec:exp){reference-type="ref" reference="sec:exp"}), on different downstream tasks, such as summarization, QA, context-and-then-QA, and topic modeling, using a few samples of datasets as CNN/dailynews [@see-etal-2017-get], squad combination [@rajpurkar-etal-2018-know], FELM [@chen2023felm], and AG [@Zhang2015CharacterlevelCN]. The results of this test are reported in Figure [1](#f1:preliminary_results){reference-type="ref" reference="f1:preliminary_results"}. As shown in the plot, for each LLM, the total response time (generation time) is strongly related to the length of the answer across various tasks, which increases significantly as the output length increases.

Another test was also carried out on Falcon-40B to evaluate the impact of the CoT method in answering arithmetic questions, using a subset of 100 random questions from the GSM8K dataset [@cobbe2021training]. The results of this test are illustrated in Figure [2](#f2:preliminary_result_CoT){reference-type="ref" reference="f2:preliminary_result_CoT"}, where red and blue dots refer to answers given with and without CoT, respectively.

The scatter plot shows that CoT significantly increases the output length and generation time. This suggests that while CoT improves the correctness of responses (see Section [6](#sec:exp){reference-type="ref" reference="sec:exp"}), more attention should be given to the time cost it introduces. To better appreciate the impact of CoT on the output length, Figure [4](#f3:preliminary_results_increment){reference-type="ref" reference="f3:preliminary_results_increment"} reports the output length (in terms of number of generated words) produced by Falcon-40b on a set of 50 questions from GSM8K without CoT (blue bars) and with CoT (pink bars). Note that purple areas denote the areas where the two bars overlap.

# Metrics for concise correctness {#sec:metrics}

Motivated by the previous considerations, this section presents three novel metrics to evaluate the capability of an LLM to provide _correct_ as well as _concise_ responses. The idea is to redefine the classic accuracy metric to integrate conciseness aspects into the LLM output's correctness. Formally, an answer $\hat{y}$ is considered correct if the conclusion extracted through a post-processing function $\Gamma$ matches the given ground truth $y$. Thus, the accuracy of an LLM can be computed as $$\begin{equation}
\label{eq:accuracy}
\mathcal{A} =
    \frac{1}{N} \sum_{i=1}^N
        \mathbbm{1}(\Gamma(\hat{y}), y),
\end{equation}$$ where $N$ is the number of tested samples and $\mathbbm{1}(u,v)$ is the indicator function that returns 1 if $u = v$, 0 otherwise. Please note that $\Gamma$ represents a user-defined function that can be implemented based on a regular expression (e.g., by extracting specific patterns from the sentence [@fu2023chain]) or using pseudo-judge approaches (e.g., by using a secondary large model as a judge [@zheng2024judging]).

Starting from Equation [\[eq:accuracy\]](#eq:accuracy){reference-type="eqref" reference="eq:accuracy"}, the conciseness of an output $\hat{y}_i$ can be integrated with its correctness by multiplying the indicator function by a penalty term $p(\hat{y}_i) \in [0,1]$ that decreases its value for long outputs: $$\begin{equation}
\label{eq:CA}
\frac{1}{N}\sum_{i=1}^N
    \left[ \mathbbm{1}(\Gamma(\hat{y}_i), y_i) \cdot p(\hat{y}_i)\right].
\end{equation}$$

The following defines three specific metrics by setting a proper penalty function.

#### Hard-$k$ Concise Accuracy:

$\text{HCA}(k)$. It measures the fraction of correct outputs that do not exceed a user-specified length $k$: $$\begin{equation}
\label{eq:HCA}
\text{HCA}(k) = \frac{1}{N}\sum_{i=1}^N
    \left[ \mathbbm{1}(\Gamma(\hat{y}_i), y_i) \cdot p_{hard}(\hat{y}_i, k)\right],
\nonumber
\end{equation}$$ where $$\begin{equation}
\label{eq:phard}
  p_{hard}(\hat{y}_i, k) =
  \begin{cases}
    1 & \mbox{if} \;\; \mathcal{N}(\hat{y}_i) \leq k\\
    0 & \mbox{otherwise}.
  \end{cases}
\end{equation}$$ This metric does not account for responses that exceed the specified maximum length, thereby promoting conciseness. We believe it could be particularly useful in scenarios where strict adherence to length constraints is essential, such as in real-time systems or environments with limited computational resources.

#### Soft-$k$ Concise Accuracy:

$\text{SCA}(k, \alpha)$. It generalizes the previous metric by penalizing the correct answers that exceed the maximum length $k$ with a term that decreases exponentially with a decay factor $\alpha$: $$\begin{equation}
\label{eq:SCA}
\text{SCA}(k, \alpha) = \frac{1}{N}\sum_{i=1}^N
    \left[ \mathbbm{1}(\Gamma(\hat{y}_i), y_i) \cdot p_{soft}(\hat{y}_i, k, \alpha)\right],
\nonumber
\end{equation}$$ where $$\begin{equation}
\label{eq:psoft}
p_{soft}(\hat{y}_i, k, \alpha) =
    \min\left(1, e^\frac{k - \mathcal{N}(\hat{y}_i)}{\alpha}\right).
\end{equation}$$

In the formula, the user-defined decay $\alpha \geq 0$ can be considered a sort of tolerance that controls how much the length impacts the overall accuracy; the higher the value of $\alpha$, the higher the tolerance for answers exceeding the specified length $k$. Note that for $\alpha = 0$, SCA$(k,0)$ reduces to HCA$(k)$.

#### Consistent Concise Accuracy:

$\textit{CCA}(k, \alpha, \beta)$. It further generalizes the previous metrics by also accounting for the variation in the lengths among all the outputs obtained: $$\begin{equation}
\label{eq:CCA}
\textit{CCA}(k, \alpha, \beta) = \textit{SCA}(k,\alpha) \cdot p_{var}(\sigma, \beta)
\nonumber
\end{equation}$$ where $$\begin{equation}
\label{eq:pvar}
p_{var}(\sigma, \beta) =
    \min\left(1, e^\frac{\beta - \sigma}{\beta}\right).
\end{equation}$$

In Equation [\[eq:pvar\]](#eq:pvar){reference-type="eqref" reference="eq:pvar"}, $\sigma$ denotes the standard deviation of the output length distribution, whereas $\beta$ is a parameter that controls the tolerance for having large length variations; the higher the value of $\beta$, the higher the tolerance. Note that, given a tolerance $\beta$, $p_{var}(\sigma, \beta) = 1$ for $\sigma \leq \beta$, while it decreases exponentially for $\sigma > \beta$.

The CCA metric aims to promote consistency in the lengths of the responses. A low standard deviation $\sigma$ indicates that the model produces responses of uniform length. In contrast, a high value of $\sigma$ denotes a model with a large response variability, making predicting its timing response time difficult.

# CCoT Prompting {#sec:method}

From the results presented in Section [3](#sec:motivations){reference-type="ref" reference="sec:motivations"}, it is clear that the relationship between output length and inference time necessitates deeper awareness. To this end, this section focuses on improving the use of CoT, aiming to preserve the benefits of this technique while paying more attention to the length of the answers to achieve a better trade-off between efficiency and accuracy.

For this purpose, we introduce a constrained chain of thoughts (CCoT) prompt, which includes and explicit sentence to constrain the generated output to a maximum number of words, encouraging the model to compress its reasoning and produce a more concise answer in a reduced amount of time. As explained in Section [3](#sec:motivations){reference-type="ref" reference="sec:motivations"}, CoT-prompt can be computed as $x = \textit{concat}(x_{\text{us}}, x_p)$, where $x_p$ is an explicit request for providing reasoning steps in the generated answer (e.g., _"let's think step by step\"_). Technically, to encourage LLMs to return more concise reasoning, the CCoT-prompt is formalized as $x = \textit{concat}(x_{\text{us}}, x_p, x_l)$, where $x_l$ represents the sentence that specifies the constraint on the output length (e.g., _"and limit the length of the answer to 30 words\"_).

Figure [5](#ccot_ex){reference-type="ref" reference="ccot_ex"} shows an example that illustrates the difference between a CoT and a CCoT prompt. Note that the answer generated for that specific question using a CoT prompt consists of 67 words, while the answer generated on the same question provided with a CCoT prompt (specifying a constraint of 45 words) consists of 34 words, and it is still correct.

The experiments presented in the following section are aimed at providing a more detailed evaluation of the CCoT prompting technique under different metrics.

# Experiments {#sec:exp}

This section presents a set of experiments carried out to evaluate the effectiveness of the the proposed CCoT approach under classic metrics, as well as illustrate the benefits of the proposed metrics in evaluating a concise correctness. Specifically, the following research questions are investigated in the next experiments:

- RQ1. Is the CCoT approach beneficial in terms of efficiency and accuracy?

- RQ2. Which models benefit from CCoT, compared to classic CoT?

- RQ3. How capable is an LLM of controlling the output length based on an explicit prompt request?

- RQ4. Are the proposed metrics helpful in addressing both efficiency and accuracy aspects? Is the impact of CCoT reflected in the proposed metrics?

## Experimental Setup

All the experiments have been carried out with the Text Generation Inference (TGI) platform[^2] on 8 NVIDIA A100 GPUs. Specifically, we evaluated five publicly available pre-trained LLMs from Hugging Face[^3], such as Vicuna-13b-v1.5 [@zheng2024judging], instruction-tuned models Falcon-40b-instruct, Falcon-7b-instruct [@almazrouei2023falcon], and two models trained and reinforced by utilizing private data, namely Llama2-7b-chat-hf and Llama2-70b-chat-hf [@touvron2023llama].

All the experiments were performed on the GSM8k [@cobbe2021training] test set, which comprises approximately 1.3k out of 8,000 mathematical problems. This dataset is typically used to evaluate how well a model can handle mathematical inference and synthesize computational steps. To compare the effectiveness of CCoT, the selected LLMs have also been assessed with and without CoT (base mode).

## Cost and performance evaluation of CCoT {#ss:exp_cost}

This experiment was carried out to evaluate the impact of _CCoT_ on computation time and accuracy. Then, the results were used to provide insights on its suitability for various LLM architectures.

#### Impact of CCoT (RQ1).

Each of the selected LLM was evaluated on the GSM8K test dataset using plain prompt (base), _CoT_, and _CCoT_ with different length constraints (namely, 15, 30, 45, 60, 100). The obtained results are reported in Figure [8](#f:CCoT){reference-type="ref" reference="f:CCoT"}. In particular, Figure [6](#f:inf.time){reference-type="ref" reference="f:inf.time"} shows the impact of the different prompt settings in terms of generation time, while Figure [7](#f:acc){reference-type="ref" reference="f:acc"} shows the corresponding accuracy.

<figcaption>Generation time (a) and accuracy (b) of five LLMs (Llama2-7b, Llama2-70b, Falcon-7b, Falcon-40b, and Vicuna-13b) on the GSM8K test dataset. Each model is evaluated using plain promt (base), CoT, and CCoT with different length constraints.</figcaption>
</figure>

As shown in Figure [6](#f:inf.time){reference-type="ref" reference="f:inf.time"}, the CCoT prompting is able to reduce the generation time of all large models and most medium models, with respect to CoT, and in most cases also with respect to the plain prompting (base). For instance, for the Llama2-70b model with classic CoT, the average generation time is 30.09 s, while with a CCoT of length 15 the generation time almost halves, reaching a maximum of 23.86 s with a length constraint of 100.

While reducing the generation time is relevant in certain applications, it is also crucial for a model to maintain the correctness of its answers while reducing the output length. To evaluate this aspect, Figure [7](#f:acc){reference-type="ref" reference="f:acc"} reports the accuracy computed for the same LLMs for the different types of prompts. Note that in Llama2-70b and Vicuna-13b, the CCoT is able to improve the accuracy, even with respect to CoT. For instance, the accuracy of Llama2-70b varies from 37.07% (with CCoT-30) and 41.77% (with CCoT-100), compared to 36.01% with CoT. For others LLMs, as Falcon-40b and Llama2-7b, the accuracy achieved with CCoT increases with the length constraint, getting a score between the base and classic CoT scores. Finally, note that Falcon-7b, which is the smallest model, is not able to exploit CCoT prompting to reduce generation times and, with large length constraints, gets also to a lower accuracy than CoT and base.

<figcaption><span>Distribution (between the 5th and 95th percentiles) of the output lengths (y-axis) given by different models and prompting strategies with the GSM8K test set.</span></figcaption>
</figure>

#### On the effectiveness of CCoT prompting (RQ2).

The different effect of CCoT prompting on the output length and accuracy illustrated in Figure [8](#f:CCoT){reference-type="ref" reference="f:CCoT"} can be attributed to various factors, such as the training data, the approach used to train the model, the model size, and the technique adopted during training. For instance, Llama2-70b is an autoregressive large-scale language model fine-tuned with human feedback, trained on a diverse combination of generic and open-source datasets. Such technical measures contribute to making CCoT effective in controlling the output length while improving the model accuracy. The Falcon-40b model, in contrast, is smaller than Llama2-70b and trained on a different dataset (the dedicated RefinedWeb data [@penedo2023refinedweb]). While CCoT does not improve the accuracy of the model with respect to CoT, it still performs better than the base plain prompting, offering a trade-off by reducing generation times compared to CoT. Vicuna-13b also provides competitive results across different prompts, as it is a fine-tuned version of Llama2 and smaller than the previous Llama2-70b.

Conversely, small-scale LLMs, such as Falcon-7b and Llama2-7b, are not capable of properly handling the constrained prompting conditions in CCoT, resulting in higher generation times (as shown for Falcon-7b with large length values in CCoT) or incorrect answers with short CCoT values in Llama2-7b. This suggests that model size and training strategies severely impact the effectiveness of CCoT.

Considering the observations presented above, we focused the next experiments on the large models addressed able to benefit from CCoT, such as Llama2-70b and Falcon-40b.

## Ability to control the output length (RQ3)

The previous experiments looked at how CCoT strategies can affect the accuracy and generation time in the average. However, despite the discussed benefits, it is also crucial to understand how CCoT prompting can effectively limit the output length for each addressed sample. This can be useful for better tuning the length parameter in the CCoT prompt or identifying the conditions in which the proposed prompting strategy fails to compress the output.

To evaluate the ability of an LLM to produce concise answers in response to a given prompting approach, we analyzed the output length for each sample under different CCoT length constraints. Figure [12](#f:Olen_distribution){reference-type="ref" reference="f:Olen_distribution"} shows the statistics on the length of the answers provided by three models (Vicuna-13b, Falcon-40b, and Llama2-70b) that were feeded with all the inputs taken from the GSM8K test set, using different prompt strategies (base, CoT, and CCoT). As done in the previous experiment, the CCoT prompt was tested for different length constraints (15,30,45,60,100). Each box plot represents the output lengths between the 5th and the 95th percentiles of all tested samples, the blue line represents the provided CCoT length constraint, the red line denotes the median, while the greed dot the mean. Ideally, a model respecting the given length constraint for each tested sample should have the entire distribution below the blue line.

As clear from Figure [12](#f:Olen_distribution){reference-type="ref" reference="f:Olen_distribution"}, using CoT without an explicit length request produces lengthy answers that significantly impact the generation time. The imposed length constraint in the CCoT prompt significantly affects the output length, although in practice LLMs are not always able to respect the given limit, especially for smaller values, such as 15, 30, or 40, which are more challenging for an LLM.

To summarize, given the nature of the CCoT prompting, it is reasonable to consider a tolerance margin in respecting the requested length. To this end, in the following paragraphs we evaluate the considered models by the metrics proposed in Section [4](#sec:metrics){reference-type="ref" reference="sec:metrics"}, which extend the accuracy by also accounting for conciseness.

## Evaluation of the _correct conciseness_ (RQ4)

The metrics proposed in Section [4](#sec:metrics){reference-type="ref" reference="sec:metrics"} are applied to assess the benefit of CCoT from a new perspective, which considers both the capability of the model to reduce the output length while maintaining a certain level of correctness.

#### _HCA_ evaluation.

The _Hard-$k$ concise accuracy_ evaluates the accuracy considering only the correct answers whose length is less than a specified value $k$. Figure [15](#fig:hca){reference-type="ref" reference="fig:hca"} reports the value of this performance index achieved on Llama2-70b (Figure [13](#fig:hca1){reference-type="ref" reference="fig:hca1"}) and Falcon-40b (Figure [14](#fig:hca2){reference-type="ref" reference="fig:hca2"}), when using the different prompt approaches and for different values of $k$. Please note, $k = \infty$ is equivalent to the classic accuracy.

<figcaption><span>The bar plots in (a) and (b) show the <em>HCA</em><span class="math inline">(<em>k</em>)</span> scores obtained for Llama2-70b and Falcon-40b, respectively, for five values of <span class="math inline"><em>k</em></span> (<span class="math inline">∞</span>, 100, 80, 60, and 40) and for the prompting methods indicated on the <span class="math inline"><em>x</em></span>-axis.</span></figcaption>
</figure>

As expected, the _HCA_ values are always less than or equal to those related to the classic accuracy ($k = \infty$), but such a reduction is less pronounced under the application of CCoT prompting. Specifically, for Llama2-70b, the use of CCoT is beneficial with respect to base and CoT prompts, for all values of $k$, although the increase is more significant for values of $k$ equal to 100, 80, and 60. This suggests that, if the length constraint is not too stringent, the capability of the model to produce correct answers is higher with CCoT. Conversely, for lower values of $k$, there is a strong reduction in performance for CoT prompts, mainly because they push the model to produce a reasoning part in the output without paying attention to its length.

Similar considerations apply to Falcon-40b, where the application of CCoT yields a good trade-off between CoT and base prompting. Note that the HCA values under CCoT get higher than those achieved under CoT, also for small values of $k$ (e.g., 60 and 40), meaning that CCoT prompting is effective for this model.

#### _SCA_ evaluation.

We also evaluated the Llama2-70b model using the _Soft Conciseness Accuracy (SCA)_, across different $k$ and $\alpha$ values, where $\alpha$ represents a tolerance for accepting answers longer than the desired limit $k$. This metric is a generalization of the _HCA_, giving more flexibility in considering correct answers that are larger but still close to the desired length $k$.

The SCA values computed for Llama2-70b and Falcon-40b on the questions of the GSM8K test set are reported in Figure [20](#fig:sca){reference-type="ref" reference="fig:sca"} for different values of $k$ and two different tolerance values ($\alpha = 1$ and $\alpha = 10$). For both models, the SCA values in CCoT settings are often comparable to HCA values for high values of $k$, such as 80 or 100. This is because, as shown in Figure [12](#f:Olen_distribution){reference-type="ref" reference="f:Olen_distribution"}, for these lengths, the CCoT prompts are effective at returning outputs below the desired limit, making the tolerance less necessary.

Conversely, for smaller $k$ values, such as $k=40$, SCA starts exceeding HCA, indicating that some correct answers have a length greater than $k$. For these values of $k$, using a larger $\alpha$ results in more pronounced improvements for CCoT prompts compared to Base and CoT. This means that, although many correct outputs are longer than $k$, under CCoT the model is still encouraged to constrain them close to $k$, thus achieving a higher score. This effect is particularly noticeable on Llama2-70b, which is more capable of controlling the length and produce correct outputs than Falcon-40b.

<figcaption><span>The bar plots show the <em>SCA</em> scores comparison of Llama2-70b (top part) and Falcon-40b (bottom part) between base, CoT, and CCoTs, using <span class="math inline"><em>α</em> = 1</span> and <span class="math inline"><em>α</em> = 10</span>.</span></figcaption>
</figure>

#### _CCA_ evaluation.

The _Consistent Concise Accuracy_ measures the capability of a model to generate correct answers whose lengths do not vary significantly, and therefore are consistent with the specified constraint. The _CCA_ requires a third parameter $\beta$ (in addition to $k$ and $\alpha$), denoting a tolerance on the output length variability. In particular, if $\sigma$ is the standard deviation of the length distribution, we have that $CCA(k,\alpha,\beta) = SCA(k,\alpha)$, if $\sigma \leq \beta$, otherwise $CCA$ decreases exponentially for $\sigma > \beta$.

Figure [23](#fig:cca){reference-type="ref" reference="fig:cca"} plots the $CCA$ scores obtained on Llama2-70b and Falcon-40b for $\alpha = 10$, $\beta = 20$, and different values of $k$, for the various prompting methods. According to this metric, the CCoTs results in a significant improvement compared to CoT and base prompting, for both Llama2-70b and Falcon-40b, and for all values of $k$. However, for high CCoT length constraints (e.g., $100$), the CCA score tends to decrease, which does not happen with the other two metrics. This can be explained by considering that an increased length constraint gives the model more freedom to generate outputs with higher variations.

<figcaption><span><em>CCA</em> scores for Llama2-70b (a) and Falcon-40b (b) obtained with <span class="math inline"><em>α</em> = 10.0</span>, <span class="math inline"><em>β</em> = 20.0</span>, and different values of <span class="math inline"><em>k</em></span> and prompting methods.</span></figcaption>
</figure>

It is also worth observing that the results shown in Figure [23](#fig:cca){reference-type="ref" reference="fig:cca"} are consistent with the output length distributions reported in Figure [12](#f:Olen_distribution){reference-type="ref" reference="f:Olen_distribution"}, where the base and CoT prompting show a larger variance in the output length, for Falcon-40b and Llama2-70b. Overall, this experiment confirms that CCA can be a useful performance metric when the length variation of the output is of interest.

For completeness and fairness of the evaluation, additional results for other values of $\alpha$ and $\beta$ are reported in the supplementary material.

## Illustration of CCoT

To better illustrate the benefits of CCoT, Figure [26](#fig:ccot_right-example){reference-type="ref" reference="fig:ccot_right-example"} shows the answers produced by Llama2-70b when applying base, CoT, and CCoT prompts (with length constraint of 15, 45, and 100) for two different questions taken from GSM8K. In both questions, we observe that in the base case, the model automatically proposes a reasoning process due to the characteristics of the model used (specifically Llama2-70B-chat). However, under CoT, the reasoning process is extended, loosing control of its length.

In particular, in the first example (Figure [24](#fig:illustration_one){reference-type="ref" reference="fig:illustration_one"}), the response remains correct also with the use of CCoT across different settings, but providing also a better control of the output length. In the second example (Figure [25](#fig:illustration_two){reference-type="ref" reference="fig:illustration_two"}), the model's response using the base and CoT prompts provides a correct reasoning process, but results in an incorrect final calculation. In contrast, CCoT techniques allows us to control the output length while providing a correct response.

Additional examples, including the complete versions of those presented here with various CCoT settings, are provided in the supplementary material.

<figcaption><span>Examples of answers given by Llama2-70b to two questions, (a) and (b), from the GSM8K test set under base, CoT, and different CCoT setting (CCoT-15, CCoT-45, and CCoT-100). The correct answers are reported in the (a) and (b) sub-captions, respectively.</span></figcaption>
</figure>

# Discussion and Conclusions {#sec:conclusion}

This work discussed the importance of addressing the conciseness of the answers provided by LLMs in text-to-text generation tasks and investigated the possibility of controlling the output length through a suitable prompt engineering approach, called Constrained Chain-of-Thought (CCoT). Then, the impact of CCoT on the generation time and the correctness of the responses was evaluated considering question-answer benchmarks, with respect to plain prompting and CoT. To this end, three novel metrics have been proposed to account for both conciseness and correctness of the output as a function of user-specified parameters. Several experiments were conducted to evaluate how different LLMs are able to control conciseness while ensuring correctness, and how they could benefit from more conciseness in terms of generation time.

From the findings emerged by the conducted experiments, a first observation is that not all models are able to control the length of their outputs (RQ2). In particular, small models, as Falcon-7b, LLama2-7b, and Vicuna-13b, have more difficulty in respecting the length constraints given in the CCoT prompts, while larger models, as Falcon-40b and Llama2-70b, show a greater control capability (Section [6.2](#ss:exp_cost){reference-type="ref" reference="ss:exp_cost"}). Such a difficulty of smaller LLMs could be influenced by various factors, as the dataset used during training and the number of model parameters. Understanding these issues and evaluating a possible integration of the proposed metric in a fine-tuning process requires a deeper investigation, which is part of our future work.

On the other hand, for larger models, such as Falcon-40b and LLaMA2-70b, CCoT was able to improve both the accuracy and the efficiency of LLMs (RQ1), with respect to plain prompts and CoT. The improvement in accuracy for certain models (LLaMA2-70b and Vicuna-13b), while beyond the scope of this study, suggests interesting future research aimed at analyzing the effects of conciseness on potential hallucination phenomena or incorrect reasoning. Furthermore, another interesting future direction could involve extending the proposed metrics with more recent evaluation techniques using judge models to evaluate the correct conciseness of LLMs [@zheng2024judging; @huang2024empirical].

To conclude, the proposed work highlighted the need to pay more attention to the conciseness of LLMs, proposing novel performance indices that are able to evaluate both the correctness of the output in relation to its length. Furthermore, the proposed CCoT prompting offers a simple but interesting strategy to address conciseness, which could open new research directions to make LLMs more predictable and efficient. []{#submission label="submission"}

::::: @twocolumnfalse
::: center
**Appendix of the paper**
:::

::: center
**Anonymous Authors**
:::
:::::

\]

# Additional studies on CCoT Prompt {#Ablation_CCoT}

Considering the proposed constrained approach we further analysis its semantic and effectivness through two additional question: is the Chain-of-thought necessary to control the output length?

To answer to this question,

::: center
$P = LLM(q, LEN)$
:::

[]{#t1: base, CoT and CCoT label="t1: base, CoT and CCoT"}

[]{#t3:reasoningLEN label="t3:reasoningLEN"}

We provided the question from the benchmark and then asked the model to _\"Limit the length of the answer to LEN words_. We have observed an extreme drop in accuracy just after providing the two values as explicit LEN conditions as seen in the table [\[t1: base, CoT and CCoT\]](#t1: base, CoT and CCoT){reference-type="ref" reference="t1: base, CoT and CCoT"}. The accuracy with LEN 15 and LEN 30 decreased as compared to the base results. It makes sense as we are not asking the model to provide us with the reasoning, and ultimately, the answers to the GSM8K questions are within short lines, and the final answer is at the end. So when the model is prompted to answer within specified limits, the short steps are further expected to be more precise, and it gives the wrong answer at the end. That's why the accuracy is dropped, and as the model has to create a short output and in many questions, there is no output, it makes sense for the less inference time, which is not aligned with the accuracy scores. After testing the constrained prompt along with the base benchmark, it is also the motivation to test the models' capabilities when there is a need to generate more text as the reasoning when using CoT. With just two explicit LENs in the prompt, these results give a clear interpretation to use with the generated text as reasoning for the questions and to make further tests with CCoT.

The CoT is specifically for testing the reasoning capabilities of the LLMs. With this aim, we first tested the CCoT approach by using the phrase _\"Limit the length of the reasoning to LEN words\"_. We provided the final prompt to the LLMs as:

::: center
$P = LLM(q, CoT-zeroshot, reasoning-LEN)$
:::

In table [\[t3:reasoningLEN\]](#t3:reasoningLEN){reference-type="ref" reference="t3:reasoningLEN"}, there is an improvement in the accuracy with the vicuna-13b-v1.5 model with all ranges of LEN. However, the inference time and the olen words are not efficient as per the objective of this study. It can be observed that as the LEN increases, the Olen words distribution also increases, ultimately increasing the computation time. That's why we have tested this prompt with only two models and continue testing the CCoT prompting with the phrase, i.e., _\"Limit the length of the answer to LEN words\"_.

## Additional Studies of Metrics for concise correctness {#ablation_metrics}

SN: Giulio, I tried to add some explanation here with the tables. Please read it too.

::: {#table:sca}
+---------------------------------------------+
| **Llama2-70b** |
+:=======:+:=======+:=======+:=======+:======:+
| Alpha/K | 100 | 80 | 60 | 40 |
+---------+--------+--------+--------+--------+
| Base |
+---------+--------+--------+--------+--------+
| 1.0 | 0.30 | 0.22 | 0.13 | 0.05 |
+---------+--------+--------+--------+--------+
| 5.0 | 0.31 | 0.24 | 0.15 | 0.06 |
+---------+--------+--------+--------+--------+
| 10.0 | 0.31 | 0.26 | 0.17 | 0.08 |
+---------+--------+--------+--------+--------+
| CoT |
+---------+--------+--------+--------+--------+
| 1.0 | 0.23 | 0.16 | 0.06 | 0.01 |
+---------+--------+--------+--------+--------+
| 5.0 | 0.25 | 0.17 | 0.08 | 0.02 |
+---------+--------+--------+--------+--------+
| 10.0 | 0.27 | 0.19 | 0.11 | 0.03 |
+---------+--------+--------+--------+--------+
| CCoT-15 |
+---------+--------+--------+--------+--------+
| 1.0 | 0.31 | 0.29 | 0.25 | 0.13 |
+---------+--------+--------+--------+--------+
| 5.0 | 0.31 | 0.30 | 0.26 | 0.15 |
+---------+--------+--------+--------+--------+
| 10.0 | 0.32 | 0.30 | 0.27 | 0.18 |
+---------+--------+--------+--------+--------+
| CCoT-30 |
+---------+--------+--------+--------+--------+
| 1.0 | 0.35 | 0.32 | 0.25 | 0.11 |
+---------+--------+--------+--------+--------+
| 5.0 | 0.36 | 0.33 | 0.27 | 0.14 |
+---------+--------+--------+--------+--------+
| 10.0 | 0.36 | 0.34 | 0.28 | 0.17 |
+---------+--------+--------+--------+--------+
| CCoT-45 |
+---------+--------+--------+--------+--------+
| 1.0 | 0.38 | 0.33 | 0.24 | 0.08 |
+---------+--------+--------+--------+--------+
| 5.0 | 0.38 | 0.34 | 0.26 | 0.12 |
+---------+--------+--------+--------+--------+
| 10.0 | 0.38 | 0.35 | 0.28 | 0.15 |
+---------+--------+--------+--------+--------+
| CCoT-60 |
+---------+--------+--------+--------+--------+
| 1.0 | 0.39 | 0.35 | 0.26 | 0.09 |
+---------+--------+--------+--------+--------+
| 5.0 | 0.39 | 0.36 | 0.28 | 0.12 |
+---------+--------+--------+--------+--------+
| 10.0 | 0.39 | 0.37 | 0.30 | 0.16 |
+---------+--------+--------+--------+--------+
| CCoT-100 |
+---------+--------+--------+--------+--------+
| 1.0 | 0.39 | 0.32 | 0.20 | 0.05 |
+---------+--------+--------+--------+--------+
| 5.0 | 0.40 | 0.33 | 0.23 | 0.07 |
+---------+--------+--------+--------+--------+
| 10.0 | 0.40 | 0.35 | 0.26 | 0.11 |
+---------+--------+--------+--------+--------+

: CCoT SCA (k, $\alpha$)
:::

::: table\*
+------------------------------------------------------------------------------------------------------------------------------------------------+
| **Llama2-70b** |
+:==========:+:=========+:=========+:=========+:=========+:=========+:=========+:=========+:=========+:=========+:=========+:=========+:========:+
| K | 100 | 80 | 60 | 40 | 100 | 80 | 60 | 40 | 100 | 80 | 60 | 40 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| Beta/Alpha | 1.0 | 5.0 | 10.0 |
+------------+-------------------------------------------+-------------------------------------------+-------------------------------------------+
| Base |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 10.0 | 0.03 | 0.03 | 0.02 | 0.01 | 0.04 | 0.03 | 0.02 | 0.01 | 0.04 | 0.03 | 0.02 | 0.01 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 20.0 | 0.17 | 0.12 | 0.07 | 0.03 | 0.17 | 0.13 | 0.08 | 0.04 | 0.18 | 0.14 | 0.09 | 0.05 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 30.0 | 0.28 | 0.21 | 0.13 | 0.05 | 0.29 | 0.23 | 0.14 | 0.06 | 0.30 | 0.24 | 0.16 | 0.08 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 40.0 | 0.30 | 0.22 | 0.13 | 0.05 | 0.31 | 0.24 | 0.15 | 0.06 | 0.31 | 0.26 | 0.17 | 0.08 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| CoT |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 10.0 | 0.04 | 0.03 | 0.01 | 0.00 | 0.04 | 0.03 | 0.01 | 0.00 | 0.05 | 0.03 | 0.02 | 0.01 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 20.0 | 0.16 | 0.11 | 0.04 | 0.00 | 0.17 | 0.12 | 0.06 | 0.01 | 0.18 | 0.13 | 0.07 | 0.02 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 30.0 | 0.23 | 0.16 | 0.06 | 0.01 | 0.25 | 0.17 | 0.08 | 0.02 | 0.27 | 0.19 | 0.11 | 0.03 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 40.0 | 0.23 | 0.16 | 0.06 | 0.01 | 0.25 | 0.17 | 0.08 | 0.02 | 0.27 | 0.19 | 0.11 | 0.03 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| CCoT-15 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 10.0 | 0.06 | 0.06 | 0.05 | 0.03 | 0.06 | 0.06 | 0.05 | 0.03 | 0.06 | 0.06 | 0.05 | 0.04 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 20.0 | 0.23 | 0.22 | 0.18 | 0.10 | 0.23 | 0.22 | 0.19 | 0.11 | 0.23 | 0.22 | 0.20 | 0.13 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 30.0 | 0.31 | 0.29 | 0.25 | 0.13 | 0.31 | 0.30 | 0.26 | 0.15 | 0.32 | 0.30 | 0.27 | 0.18 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 40.0 | 0.31 | 0.29 | 0.25 | 0.13 | 0.31 | 0.30 | 0.26 | 0.15 | 0.32 | 0.30 | 0.27 | 0.18 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| CCoT-30 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 10.0 | 0.07 | 0.07 | 0.05 | 0.02 | 0.08 | 0.07 | 0.06 | 0.03 | 0.08 | 0.07 | 0.06 | 0.04 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 20.0 | 0.27 | 0.24 | 0.19 | 0.08 | 0.27 | 0.25 | 0.20 | 0.10 | 0.27 | 0.26 | 0.22 | 0.13 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 30.0 | 0.35 | 0.32 | 0.25 | 0.11 | 0.36 | 0.33 | 0.27 | 0.14 | 0.36 | 0.34 | 0.28 | 0.17 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 40.0 | 0.35 | 0.32 | 0.25 | 0.11 | 0.36 | 0.33 | 0.27 | 0.14 | 0.36 | 0.34 | 0.28 | 0.17 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| CCoT-45 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 10.0 | 0.10 | 0.09 | 0.07 | 0.02 | 0.10 | 0.09 | 0.07 | 0.03 | 0.10 | 0.10 | 0.08 | 0.04 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 20.0 | 0.32 | 0.29 | 0.21 | 0.07 | 0.33 | 0.30 | 0.23 | 0.10 | 0.33 | 0.30 | 0.25 | 0.13 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 30.0 | 0.38 | 0.33 | 0.24 | 0.08 | 0.38 | 0.34 | 0.27 | 0.12 | 0.38 | 0.35 | 0.29 | 0.15 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 40.0 | 0.38 | 0.33 | 0.24 | 0.08 | 0.38 | 0.34 | 0.27 | 0.12 | 0.38 | 0.35 | 0.29 | 0.15 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| CCoT-60 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 10.0 | 0.11 | 0.10 | 0.08 | 0.03 | 0.11 | 0.10 | 0.08 | 0.04 | 0.11 | 0.11 | 0.09 | 0.05 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 20.0 | 0.34 | 0.31 | 0.23 | 0.08 | 0.35 | 0.32 | 0.25 | 0.11 | 0.35 | 0.32 | 0.27 | 0.14 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 30.0 | 0.39 | 0.35 | 0.26 | 0.09 | 0.39 | 0.36 | 0.28 | 0.12 | 0.39 | 0.37 | 0.30 | 0.16 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 40.0 | 0.39 | 0.35 | 0.26 | 0.09 | 0.39 | 0.36 | 0.28 | 0.12 | 0.39 | 0.37 | 0.30 | 0.16 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| CCoT-100 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 10.0 | 0.09 | 0.08 | 0.05 | 0.01 | 0.10 | 0.08 | 0.05 | 0.02 | 0.10 | 0.08 | 0.06 | 0.03 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 20.0 | 0.32 | 0.26 | 0.16 | 0.04 | 0.32 | 0.27 | 0.18 | 0.06 | 0.32 | 0.28 | 0.21 | 0.09 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 30.0 | 0.39 | 0.32 | 0.20 | 0.05 | 0.40 | 0.33 | 0.23 | 0.07 | 0.40 | 0.35 | 0.26 | 0.11 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
| 40.0 | 0.39 | 0.32 | 0.20 | 0.05 | 0.40 | 0.33 | 0.23 | 0.07 | 0.40 | 0.35 | 0.26 | 0.11 |
+------------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+----------+
:::

For further support regarding our novel metrics for concise correctness, we see the impacts of all SCA and CCA scores for llama2-70b. In table [1](#table:sca){reference-type="ref" reference="table:sca"}, we illustrate all scores for all $\alpha$ values and k-values. Overall the scores with CCoTs are quite better than the CoT and base. More precisely, when the soft concise limit is increasing (as increasing the $\alpha$ values), the SCA is also improving. However, when we are checking the impact of lower k-values even with all $\alpha$ values, it is quite lower as compared with higher k-limits. It shows that even for soft concise accuracy, the model is quite adapted to explicit length requirements.

The same is done with CCA scores and all the results are presented in the table [\[table:cca\]](#table:cca){reference-type="ref" reference="table:cca"}. Here, we see the consistent length impact along with the correctness of the generated answer by providing the various $\alpha, \beta$ combinations with k-values. As we already explained it is the further generalization of the SCA scores and it is clear that when we applied the $\beta$ values more than the $\alpha$ and also with higher values of $\alpha$, the CCA scores are quite well and improved. Overall, the impact is effective for CCoTs as compared to the CoT and base. It express the model ability to compel with the length requirements and also be consistent within a range with correct answers to the questions.

[^1]: Even though 'tokens' and 'words' refer to different items in the sentence, for simplicity, in this work we will refer to both indistinguishably.

[^2]: <https://huggingface.co/docs/text-generation-inference>

[^3]: <https://huggingface.co/blog/os-llms>
