# Abstract

While the emergence of powerful language models along with Chain-of-thought prompting has made automation more and more omnipresent, it sometimes demonstrates its weakness in long-term or multi-step logical reasoning. For example, users don't always get desirable answers for complex mathematical problems without human involvement. Against this background, we present the **Manual Correction System (MCS)** --- a human-in-the-loop system enhanced by Chain-of-Thought prompting, which explores how manual correction of sub-logics in rationales can improve LLM's reasoning performance. Moving one step forward, considering a system with human-in-the-loop involves more than having humans improve performance but also controlling the cost. Therefore, we post a **Cost-utility Analysis Model for Human-in-the-Loop systems (CAMLOP)** based on classical economics theory to analyze, quantify and balance the utility and the corresponding cost. We conduct experiments of MCS and CAMLOP with twelve datasets. A significant advantage w.r.t cost and utility proves its superiority over strong baselines.

# Introduction

Large language model-based Artificial Intelligence systems are augmenting humans in certain roles, and soon this trend will expand to the vast majority of the workforce. However, while the emergence of powerful language models [sanh2021multitask; ouyang2022training; zhang2022opt; shao2023compositional] has made automation omnipresent, it sometimes demonstrates its weakness in long-term or multi-step logical reasoning [hosseini2014learning; kushman2014learning; koncel2015parsing; roy2016solving]. For example, users don't always get desirable answers for a mathematical problem without human involvement. To make tangible progress in mitigating these errors is where we need humans, and a system with human-in-the-loop involves more than having humans improve performance but also controlling the cost. Against this background, there comes a timing question: how to get a human-in-the-loop system in the most effective (namely, high-utility) and low-cost way?

See Fig. 1 as an example. For humans, solving the whole problem in the leftmost box is often more difficult than solving one of the sub-logics (_e.g._, `latex $2*(16-3) =25)$ `). Correction of the erroneous sub-logic (_e.g._, `latex $2*(16-3) =25 \rightarrow 2*(16-3) =26$ `) helps LLM reach a correct final answer.

[IMAGE: MCS illustration - MCS comprises four stages: (1) **sampling stage** prompting the LLM using CoT prompting and replacing the greedy decoding by sampling from the LLM's decoder to generate a set of rationales (i.e., the complete logical chain of CoT output); (2) **filtering stage** filtering out the samples ranked high by Diversity Entropy; (3) **correction stage** manually adding, deleting and modifying erroneous sub-logics in the most likely rationale of the filtered sample, and (4) **answer stage** prompting the LLM using CoT prompting again with manually corrected sub-logics and using greedy decoding to obtain the final answer.]

In the last few years, thanks to explorations in Large Language Models (LLMs) and advances in in-context learning (ICL) technologies, giant breakthroughs have been obtained. Just by being fed an instruction, models can function very well on that task without manual finetuning [NEURIPS20201457c0d6]. This provides a chance for a human to change the predicted results via natural language instructions as a flexible and friendly interface. Furthermore, changing the rationale for chain-of-thought (CoT) prompting [wei2022chain] is even more user-friendly since short and simple sub-logics in the rationale are easy for humans to handle. Whereas manual correction helps, the labor of this additional correction stage brings a direct and indirect cost (See Sec. 3 for more details). When and how humans intervene will greatly affect the cost and utility. Until recently, few researchers had explored this balance in ICL.

We present the **M**anual **C**orrection **S**ystem (MCS; Sec. 2) --- a human-in-the-loop system, which explores when and how manual correction of rationales can efficiently improve LLM's reasoning ability. To our knowledge, MCS is the first human-in-the-loop system leveraging rationales. As shown in Fig. 1, MCS consists of four stages: prompting the LLM with CoT, automatically filtering out the incorrectly predicted samples, human correcting their rationales, and prompting the LLM using CoT again to obtain the final answer. Referring to the "when" problem, we consider a diversity-based method to get a cue to indicate when humans should be involved, so as to reduce human labor as much as possible (See. 2.1). The diversity-based method is inspired by the diversity of the rationales. We have found that even when the desired answer is fixed, introducing the diversity degree of the rationales can be highly beneficial; therefore we introduce Diversity Metrics, as commonly used in Active Learning field [brinker2003incorporating; yang2015multi; agarwal2020contextual], to find data points requiring manual intervention. Then it comes to the "how" problem (See. 2.2). We empirically prove the viability of paying attention to sub-logics instead of the whole problem. We define three operations (_i.e._, modifying, adding, and deleting) that a human can perform on the sub-logics of rationales for efficiency and simplification.

With the development of Artificial Intelligence (AI), some companies have started to explore the use of LLMs in practice (_e.g._, IBM implementing AI processes in HR [IBM]). Therefore, we propose a **C**ost-utility **A**nalysis **M**odel for Human-in-the-**LO**o**P** systems (CAMLOP; Sec. 3) to analyze and balance the cost and utility. CAMLOP describes the cost-utility ratio that is introduced from the economics theory into the AI field to quantify these two factors (_i.e._, cost and utility) and spread the two factors across various aspects (_e.g._, time and money as cost; accuracy and user satisfaction as utility) so that reliable scores of various aspects are achieved.

We instantiate MCS with twelve datasets across three classes of tasks --- arithmetic, commonsense, and symbolic reasoning (Sec. 4). MCS achieves new state-of-the-art levels of performance across most of the tasks. To show the applicability in real-world business, we apply CAMLOP to practice by posing an example to illustrate the balance between utility and cost in Sec. 4.5. Notably, a significant advantage w.r.t cost and utility proves our MCS's superior over strong baselines.

# Manual Correction System

MCS automatically finds the incorrectly predicted samples to indicate when humans should be involved (Sec. 2.1) and then provides efficient operations to indicate how to correct rationales (Sec. 2.2). Fig. 1 shows the whole four stages in MCS. The first and final stages are simple prompting. The intermediate filtering stage and correction stage are our focus, as detailed below.

## Filtering Stage

As shown in Fig. 1, after the first stage, the LLM samples three plausible rationales for a math problem that arrive at different answers. Just like humans, LLMs may make countless and various mistakes, but there are only a limited number of correct rationales for the right result. If most of the sampled rationales cannot make agreements, with a high probability this sample is wrongly predicted. To empirically prove that, we conduct quantitative experiments and discover that incorrectly predicted samples tend to have greater diversity in their final answer when solving difficult reasoning problems. (Please refer to Appendix 7 for more details).

Specifically, the LLM is prompted with a set of manually written CoT exemplars following wei2022chain in the first stage. (Please refer to Appendix for more details) Then, we sample a set of candidate outputs from the LLM's decoder to generate a set of rationales. Finally, we use the diversity degree to identify the most likely incorrect sample for humans to involve. Here, we adopt a widely-used method to select the samples: Diversity Entropy [brinker2003incorporating; yang2015multi; agarwal2020contextual]. A further study about Diversity Entropy in Sec. 4.4.0.2 quantitatively demonstrates its advantage.

Formally, given a manually written CoT prompt and a sample **s**, MCS decodes a set of N outputs, where each output **r**_i is a sequence of tokens representing the i-th rational, then the rational **r**\_i is used to obtain the answer **a**\_i. As previously demonstrated, a greater diversity of the set of answers indicates potential incorrect predictions and flags a sample for humans to involve. First, we obtain the predicted answer **a**\_i though argmax P(**r**\_i, **a**\_i | **s**). For example, in Fig. 1, **r**\_i is *She has $16-3=13$ eggs left. So she has $16*2-3=\$13$.\*, and **a**\_i is $13. Then we calculate the answer distribution for the answer set {**a**_{i, ..., N}} of **s**. For each distinct value **a** in {**a**\_{i, ..., N}}, the probability is as follows:

```latex
$$\begin{equation}
\mathbf{p}_{\mathbf{a}} = \frac{{\textstyle \sum_{i=1}^{ | N |}} \mathbf{1}  (\mathbf{a}_i = \mathbf{a})}{ | N | }
\label{equation:answer_probability}
\end{equation}$$
```

where |N| denotes the number of answers. For example, in Fig. 1, there are three answers as well as three rationales. We use the answer entropy as the Diversity Entropy (DE) score for the sample **s**:

```latex
$$\begin{equation}
\mathbf{DE} = \sum_{\mathbf{a}\in \{\mathbf{a}_i\}}^{} -\mathbf{p}_{\mathbf{a}} \log_{}{\mathbf{p}_{\mathbf{a}}}
\end{equation}$$
```

The higher the DE score, the more likely it needs manual correction. A threshold **alpha** is set for DE as the hyper-parameter.

## Correction Stage

Referring to how humans should involve in the loop, the most straight-forward idea is humans handling the filtered samples while the LLM processes the rest samples. However, humans handling the sample as a whole problem is still labor-consuming, especially for those difficult mathematical problems. Due to this, we claim that humans should pay local attention to simple sub-logics in the rationale. Here, a sub-logic is typically a group of words that can stand alone as a complete thought in a complex rationale. We denote a sentence as a sub-logic.

To support our claim, there exist some premises. Firstly, an incorrect rationale could output the correct final answer after correcting the erroneous sub-logic in the rationale. To empirically prove that, we conduct quantitative experiments for twelve datasets and discover that in general up to 50% of errors of CoT indeed are caused by incorrect intermediate rationales. After correcting these 50% incorrect rationales, the final answers turn out to be correct. Secondly, correcting sub-logics indeed solves the majority of incorrect rationales. We conduct the analytical experiment across multiple tasks in Sec. 4.3 and provide the evidence. Thirdly, the questionnaire survey shows that correcting each sub-logic independently is much easier and more user-friendly for humans than checking the entire rationale (Please refer to Appendix 8 for more details).

Specifically, in the correction stage, we ask humans to check the filtered sample and only correct the rationale with the highest probability. During the correction, to simplify, the operations that a human can perform on the sub-logics include "modifying", "adding", and "deleting". As shown in Tab. 1, the first cause displays the modifying operation. After the modifying operation, the corrected sub-logic "_$3 _ 100 + 8 _ 10 + 3 _ 1 = 383$\*" helps the LLM output the correct answer.

# Cost-utility Analysis Model for Human-in-the-Loop Systems

CAMLOP introduces the cost-utility relation that is introduced from the economics theory [intermediate_microeconomics] into the AI field to quantify these two factors (_i.e._, cost and utility). For human-in-the-loop systems like MCS, we divide the goods into two simple categories: human labor and LLM. Company strategic decision-makers always choose the best bundle of goods they can afford/cost. The costs include direct and indirect costs. The direct cost is the money the goods spent while indirect costs mainly include overhead costs from management and rent. Indirect costs also include intangible costs, such as the impact on customers, employees, or delivery times should be considered. Utilities include boosted accuracy, social prestige, and user satisfaction. For simplicity, we only consider money and time for cost while considering accuracy and user satisfaction for utility in our experiments.

[IMAGE: optimal_choice.pdf - Cost-utility analysis model diagram]

We draw Fig. 2 where the horizontal axis x_1 and vertical axis x_2 are the quantity of human labor and LLMs respectively. First, we introduce notations related to the cost. We define p_1 _ x_1 as the cost spent on human labor and p_2 _ x_2 as the cost spent on the LLMs. We indicate the bundle by (x_1, x_2) (a data point in Fig. 2). The corresponding unit price is p_1 and p_2. The total cost the company decision-maker has to spend is denoted as y. Therefore, the budget constraint can be represented as p_1 x_1 + p_2 x_2 <= m. The solid straight line is the set of data points that cost exactly y: p_1 x_1 + p_2 x_2 = m. To note, the cost contains various aspects as mentioned before. In Fig. 2, for simplicity, we express these different aspects as a unified value according to a unified standard. Then we introduce utilities. A utility function u(x_1, x_2) is a way to assign a utility value to the bundle (x_1, x_2). As shown in Fig. 2, the set of all data points (x_1, x_2) such that u(x_1, x_2) equals a constant is called a level set (solid curve). Those data points on higher indifference curves are getting larger utility. We adopted a commonly used utility function--- Cobb-Douglas utility function `latex $u(x_1, x_2) = x_1^c x_2^d$ `, where c and d are positive numbers that we need to learn. Given a model parameterized by c, d, and a fixed cost y, the model predicts the optimal choice (x_1*, x_2*) with the highest utility, which is desired by the company strategic decision-makers. Note an important feature of this optimal choice: at this data point the indifference curve is tangent to p_1 x_1 + p_2 x_2 = y.

To note, we introduce the modeling of CAMLOP in this section. More details about the inference and learning are shown in Appendix 9 and Appendix 10.

# Experiments

## Setup

#### Tasks and datasets.

For arithmetic reasoning tasks, we conducted a series of experiments on the Math Word Problem Repository [amini2019mathqa], including AddSub [hosseini2014learning], MultiArith [roy2016solving], SingleEq [koncel2015parsing] and SingleOp [kushman2014learning]. We also included ASDiv [miao2021diverse], AQUA-RAT [miao2021diverse], GSM8K [cobbe2021training], and ASDiV [patel2021nlp]. For commonsense reasoning tasks, we used CommonsensQA[talmor2018commonsenseqa] and StrategyQA[geva2021did]. For symbolic reasoning tasks, we used Last Letter Concatenation and Coinflip[wei2022chain]

#### Baselines.

We primarily compare MCS with the following baselines. It is noteworthy that all baselines use the same LLM as the decoder. For a fair comparison, we report the results of Self-consistency, MCS, and MCS + Self-consistency with the same 5 rationales sampled from the decoder. The details of the baselines are as follows:

1.  _CoT-prompting._ Chain-of-thought prompting with greedy decoding [wei2022chain].

2.  _Self-consistency._ Chain-of-thought prompting replacing the greedy decoding strategy used in CoT-prompting. Self-consistency generates a set of rationales by sampling from LLM's decoder and determines the optimal answer by taking a majority vote [wang2022self].

#### Models and scales.

We use GPT-3 [ouyang2022training; brown2020language] with 175-billion parameters as the LLM. More details are provided in Appendix 11. For our methods, we provide the following two variants:

1.  _MCS._ MCS is the result of manual correction for the top 40% CoT predictions ranked out using DE. A detailed analysis of the threshold of Diversity Entropy is shown in Sec. 4.4.0.1.

2.  _MCS +Self-consistency._ MCS + Self-consistency is the result of combining marginalizing out the sampled rationales with MCS. In practice, we use Self-consistency to get answers by majority vote, and then we use MCS to manually correct incorrect sub-logics of the first rationale out of decoded rationales with DE calculated based on the decoded rationales.

#### Sampling scheme.

To sample diverse rationales, we followed similar settings to those used in wang2022self for the open-text generation. We use T = 0.7 without top-k truncation. For a fair comparison, we use the same prompts as in wei2022chain. The threshold of DE is set to be top 40%

## Main Results

#### Arithmetic Reasoning

The results are shown in Tab. 2. MCS generally improves the arithmetic reasoning performance at a large margin (4.68 points on average) compared with CoT. MCS + Self-consistency further improves the arithmetic reasoning performance (6.39 points on average). Especially for SingleEq and SVAMP, compared with CoT, the accuracy increased by 9.05 and 12.10 points, respectively. MCS + Self-Consistency performs

| Model                  | AddSub    | MultiArith | SingleEq  | SingleOp  | ASDiv     | AQuA      | SVAMP     | GSM8K     |
| ---------------------- | --------- | ---------- | --------- | --------- | --------- | --------- | --------- | --------- |
| CoT-prompting          | 82.78     | 93.00      | 85.04     | 94.84     | 73.19     | 40.55     | 68.00     | 56.48     |
| Self-consistency       | 90.63     | 94.17      | 89.17     | 95.73     | 77.72     | 38.19     | 75.70     | 58.85     |
| MCS                    | 92.15     | **95.50**  | 92.51     | 96.62     | 75.52     | **44.09** | 74.60     | 61.56     |
| MCS + Self-consistency | **97.22** | **95.50**  | **94.09** | **98.75** | **79.63** | 41.34     | **80.10** | **62.92** |

#### Commonsense and Symbolic Reasoning

Tab. 1 shows the results on commonsense and symbolic reasoning tasks. Similarly, MCS improves the performance and MCS + Self-consistency further boosts it. For symbolic reasoning, we adopt the out-of-distribution (OOD) setting where the input prompt contains samples of 4-letters and 4-flips [wang2022self] because this setting is more challenging. We do not adopt the in-distribution setting because GPT-3 can already achieve 100% accuracy with the in-distribution setting as shown in wei2022chain. Even in difficult OOD setting, the gain of MCS +Self-consistency is significant compared to CoT-prompting and Self-consistency.

| Model                  | CSQA      | StraQA    | Letter    | Coinflip  |
| ---------------------- | --------- | --------- | --------- | --------- |
| CoT-prompting          | 72.32     | 60.13     | 49.20     | 81.40     |
| Self-consistency       | 76.09     | 61.40     | 54.40     | **93.20** |
| MCS                    | 73.71     | 60.88     | 75.40     | 81.40     |
| MCS + Self-consistency | **77.07** | **62.23** | **78.40** | **93.20** |

[IMAGE: error_case_study.pdf - Illustration of error analysis of Chain of Thought Prompting across twelve tasks. Each error type is represented by a color. The share in color indicates the share of the error type.]

## Analysis of Whether Correcting Sub-logics Solves the Majority of Incorrect Rationales

We conduct experiments on twelve datasets to check whether correcting sub-logics solves the majority of incorrect rationales. Each task is represented by a pie chart. For each task, we conduct the error analysis for CoT prompting and analyze the error types of rationales. We divided the error types into four categories: errors that are able to be corrected by the "modifying" operation, the "adding" operation, the "deleting" operation, and the rest of the errors that are unable to be manually corrected. The percentage of each type across datasets is shown in Fig. 2. More details are shown in Appendix 8.2.

The first three categories constituent the majority of incorrect rationales and can be solved by correcting independent sub-logics instead of the whole rationale. More specifically, CoT often makes mistakes when calculating polynomial calculations with decimal points, which account for a large part of manual correction and can be corrected by the "modifying" operation. For the "adding" operation, it functions when CoT often fails to convert the units, for example, from grams to kilograms. CoT often outputs redundant logic, leading to incorrect answers, which could be fixed by the "deleting" operation. Except for the error mentioned above, errors that are unable to be manually corrected include misinterpretation of the question, incorrect formula, whole incorrect composition of sub-logics and so on.

Additionally, we find that the advantage of Self-consistency often comes from fixing the errors that are unable to be manually corrected. Sampling a large set of rationales and taking a majority vote helps the fix of misinterpretation of the question while making little help in fixing calculation error. On the contrary, MCS is beneficial for other three categories of errors including "modifying", "adding" and "deleting". The difference between Self-consistency and MCS illustrates why MCS + Self-consistency achieves great performance as shown in Tab. 2. Obviously, MCS and Self-consistency play different roles and be mutually complementary.

## Additional Study

#### Validation of Diversity Entropy

[IMAGE: threshold.pdf - Results of different thresholds of DE. It shows the results of MCS with 5%, 10%, 20%, 30%, 40% and 50% DE for AddSub (Left), SingleEq (Medium) and SingleOp (Right). Results show that DE-based filtering is an efficient method to rank the possibility to be incorrect for the output of CoT predictions, and samples with incorrect output will be ranked higher than those without.]

[IMAGE: ROCAUC.pdf - ROC Curves for DE to filter out the incorrect CoT outputs. It shows the ROC Curve for AddSub (Left), Singleeq (Medium) and SingleOp (Right). The results indicate that DE is a reliable metrics that can determine the samples most likely to be incorrectly predicted for humans to involve.]

To validate the effectiveness of Diversity Entropy in determining whether the manual correction is necessary for each sample, we draw a ROC Curve in Fig. 4 to demonstrate its ability to rank the likelihood of incorrect outputs. The selection of the threshold involves a trade-off between performance and human labor. Fig. 3 shows that the performance stabilizes after reaching the threshold of top 20% to top 40% for most datasets. Therefore, we set the threshold to be top 40% across all our experiments. As the manual correction is labor-consuming and time-consuming, Diversity Entropy can help save time and labor by allowing humans to focus on checking only a small percentage.

#### Analysis of Aggregation Strategies

| Calculation Strategy                        | ASDiv     | AQuA      | SVAMP     | GSM8K     |
| ------------------------------------------- | --------- | --------- | --------- | --------- |
| Unnormalized Weighted Average               | 73.71     | 44.09     | 74.50     | 61.41     |
| Normalized Weighted Average                 | 73.71     | 40.94     | **74.60** | **61.56** |
| Unnormalized Weighted Sum                   | 73.80     | 42.52     | 74.50     | 60.20     |
| Normalized Weighted Sum                     | 73.37     | **44.88** | 71.30     | 59.21     |
| Unnormalized Unweighted Sum (Majority Vote) | **75.52** | 44.09     | **74.60** | **61.56** |

The majority vote method of calculating the answer probability over all sampled rationales can be regarded as taking an unnormalized unweighted sum. As described in wang2022self, other methods of computing answer probability include the unnormalized weighted average, normalized weighted average, unnormalized weighted sum,

[IMAGE: numbers.pdf - Analysis of the number of sampled rationales]

and normalized weighted sum. More details about the above calculation are provided in Appendix. Tab. 2 shows that unnormalized unweighted sum generally outperforms others. We use this setting in all experiments following wang2022self.

#### Analysis of the Number of Sampled Rationales

We test the accuracy with respect to varying the number of rationales (_i.e._, 5, 10, 15, 20, 25, 30, 35, 40) in Fig. 5. The results are arithmetic reasoning accuracy on SingleEq. For a fair comparison, both MCS and Self-consistency use the same prompts as in wei2022chain. Both MCS and Self-consistency use the same 5 rationales sampled from the decoder. In our experiments, the threshold of Diversity Metrics is set to be top 40%. The results show that MCS generally outperforms self-consistency and benefits from the increasing number of sampled rationales.

## Balancing Cost and Utility

| Plans                                           | Time  | Money   | Acc.  | Utility(User Satis.) |
| ----------------------------------------------- | ----- | ------- | ----- | -------------------- |
| Human                                           | 60s   | $0.125  | 93.20 | 86.40                |
| CoT Prompting                                   | 0.8s  | $0.080  | 85.04 | 81.60                |
| Self-Consistency (N_self = 10)                  | 8s    | $0.800  | 92.49 | 85.80                |
| MCS (N_MCS = 5, alpha = 20%)                    | 10.8s | $0.4925 | 91.00 | 84.20                |
| MCS + Self-consistency (N_MCS = 5, alpha = 20%) | 10.8s | $0.4925 | 93.50 | 88.80                |
| MCS (N_MCS = 5, alpha = 40%)                    | 16.8s | $0.505  | 92.51 | 85.60                |
| MCS + Self-consistency (N_MCS = 5, alpha = 40%) | 16.8s | $0.505  | 94.09 | 90.80                |

In this section, we conduct experiments on the SingleEq dataset to quantitatively calculate cost and utility for CAMLOP. For the cost, we consider money and time. We set the price of the LLM as p_llm and the time cost as t_llm. Since we use GPT-3, the price p_llm for a single math problem (decoding once) is $0.08 on average, and the time cost t_llm is 0.8 second based on empirical results. The price of solving a single math problem with only human labor is p_human and the time cost is t_human. We set p_human to be $0.125 and t_human to be 60 seconds based on our empirical results. The price of human labor for MCS to correct a single math problem p_MCS is $0.0625 and the time cost t_MCS is 30 seconds based on empirical results. Note the time required to inspect and correct is less than the time needed to fully solve the entire problem, therefore t_MCS < t_human.

For the utility, we consider user satisfaction as the comprehensive score. We ask five users to write down their satisfaction levels and calculate the average. We also perform regression analysis on user satisfaction based on LLM and Human and ultimately learn the utility function `latex $\mathbf{u}(\mathbf{x}_{llm}, \mathbf{x}_{human}) = \mathbf{x}_{llm}^{2.05}*\mathbf{x}_{human}^{1.94}$ `. For more details, please refer to Appendix 13.

We experiment on five candidate plans based on models from Sec. 4.2 and Sec. 4.4 (Fig. 3 and Fig. 5):

1.  _Human_: A plan that requires only human labor, which costs p_human and t_human seconds.

2.  _CoT-prompting_: A naive CoT plan that only requires GPT-3 for decoding only once, which costs p_llm and t_llm seconds.

3.  _Self-consistency_: A Self-consistency plan that requires only LLMs to sample from the decoder N_self times, which will cost N_self _ p_llm and N_self _ t_llm seconds.

4.  _MCS_: MCS samples from LLM decoder N_MCS times and uses top alpha as threshold, requiring (N_MCS+1) _ p_llm + alpha _ p_MCS and (N_MCS+1) _ t_llm + alpha _ t_MCS seconds.

5.  _MCS + Self-consistency_: A MCS + Self-consistency plan that requires to sample from the decoder N_MCS times, which costs the same as the MCS plan.

The results are shown in Tab. 3. The result shows that MCS +Self-consistency generally outperforms other methods with higher utility (_i.e._, better user satisfaction) as well as an acceptable cost.

# Related Work

The human-in-the-Loop system, aiming to achieve what neither humans nor machines can accomplish independently, is defined as a model requiring human interaction [karwowski2006international]. When the machine cannot solve the problem, or when cost or security considerations require humans to participate, manual intervention is necessary [bien2018deep; wu2022survey; zanzotto2019human; mosqueira2023human]. Previous human-in-the-loop systems focus either on adding appropriate tags to data or providing feedback on cases with a certain confidence interval to the machines and thus retrain the model afterward with the labeled data or rewarded cases [wu2022survey; zanzotto2019human].

Recently, LLM-based AI (Artificial Intelligence) systems are developing very quickly, and this trend is expected to expand to the majority of the workforce in the near future [ouyang2022training; zhang2022opt; sanh2021multitask]. However, these systems do not always provide satisfactory answers without human intervention. Additionally, in domains such as criminal fact identification and charge predictions, inference should be reasonable and controlled by humans [custers2022ai] while LLMs are not qualified. Therefore, it is essential to develop a human-in-the-loop prompting-based system that is designed with the ability to collaborate with humans. Until recently, few researchers have systematically and quantitatively explored human-in-the-loop prompting-based systems.

Different from ChatGPT's RLHF (_i.e._, Reinforcement Learning from Human Feedback), we take the first step to use human feedback in an online way without access to parameters. Even though it's a preliminary step, this online method could benefit from further refinement and combination with RLHF in future research.

# Conclusion

We propose the MCS to explore how manual correction of rationales can improve LLM's reasoning ability. Then, we propose CAMLOP to quantitatively and systematically analyze and balance the cost and the corresponding utility. Experiments demonstrate that our MCS significantly outperforms strong baselines including the CoT prompting approach and Self-consistency approach and obtains the optimal balance between cost and utility.

# Appendix: Experiments for Filtering Stage

After the first stage, the LLM samples plausible rationales for a problem that arrive at different answers. Just like humans, LLMs may make countless and various mistakes, but there are only a limited number of correct rationales for the right result. If most of the sampled rationales cannot make agreements, with a high probability this sample is wrongly predicted. To empirically prove that, we conduct quantitative experiments and discover that incorrectly predicted samples tend to have greater diversity in their final answer when solving difficult reasoning problems.

Specifically, the LLM is prompted with a set of manually written CoT exemplars following wei2022chain in the first stage. Then, we sample a set of 5 candidate outputs from the LLM's decoder to generate a set of rationales. Based on the sampled rationales, we divide the samples into two parts: **Part 1** has all sampled rationales pointing to the same final answer (_i.e._, the Diversity Entropy score of such samples should be equal to 0); **Part 2** has sampled rationales pointing to different final answers, which is the part outside the first part of samples (_i.e._, the Diversity Entropy score of such samples should be greater than 0). Next, we calculate the accuracy of **Part 1** and **Part 2** for each dataset separately. We use the first answer of each sample as the result of CoT-Prompting and use all five answers to calculate the Diversity Entropy score. The accuracy of **Part 1** is generally larger than **Part 2**. It demonstrates the superiority of Diversity Entropy and experimentally confirms the intuition that incorrectly predicted samples tend to have greater diversity in their final answer when solving difficult reasoning problems.

# Appendix: Experiments for Correction Stage

## Incorrect Rationale Could Output the Correct Final Answer after Manually Correcting the Erroneous Rationale.

An incorrect rationale could output the correct final answer after correcting the erroneous rationale. To empirically prove this, we conduct quantitative experiments for twelve datasets and discover that in general most of the errors of CoT indeed are caused by incorrect rationales. After correcting these incorrect rationales, the final answers turn out to be correct.

Specifically, we explored the limits of the CoT-based methods (namely CoT-Prompting, Self-Consistency, and MCS) when humans correct rationales while disregarding cost. Humans were instructed to thoroughly check all samples and ensure the correctness of all rationales. The upper bound of CoT-Prompting is denoted as CoT-Upperbound and the upper bound of Self-Consistency is denoted as SC-Upperbound. Self Consistency and MCS+Self Consistency have the same upper bound in extreme cases (_i.e._, the threshold of Diversity Entropy score is set to 100%) while CoT-Upperbound and MCS have the same upper bound in extreme cases (_i.e._, the threshold of Diversity Entropy score is set to 100%). The experimental results demonstrate that the upper bounds are quite high, indicating that an incorrect rationale could produce the correct final answer after correcting the errors. To note, this limitation represents only the upper bounds of our method, and its practical implementation would require significant time and resources.

## Correcting Erroneous Sub-logic Indeed Solves the Majority of Erroneous Rationale.

Correcting erroneous sub-logic indeed solves the majority of erroneous rationale. We conduct the analytical experiment across multiple tasks in Sec. 4.3 and provide the evidence.

We conduct experiments on twelve datasets to check whether correcting sub-logics solves the majority of incorrect rationales. Each task is represented by a pie chart. For each task, we conduct the error analysis for CoT prompting and analyze the error types of rationales. We divided the error types into four categories: errors that are able to be corrected by the "modifying" operation, the "adding" operation, the "deleting" operation, and the rest of the errors that are unable to be manually corrected.

Results show that correcting erroneous sub-logic indeed solves the majority of erroneous rationale (_i.e._, each erroneous rationale indeed can be corrected by only editing a single erroneous sub-logic).

## Correcting Each Sub-logics Independently is Much Easier and More User-friendly than Correcting the Entire Rationale

We conduct the human evaluation. The questionnaire survey shows that correcting each sub-logic independently (_i.e._, our approach) is much easier and more user-friendly than checking the entire rationale. The time humans need to check and correct the incorrect sub-logics is much less than the time needed to correct the entire rationale for each sample, proving that correcting each sub-logic independently is much easier and more user-friendly for humans than checking the entire rationale.

# Appendix: Inference for CAMLOP

Given a model parameterized by c, d, and a fixed cost y, the model predicts the optimal choice (x_1*, x_2*) with the highest utility, which is desired by the company strategic decision-makers. Note an important feature of this optimal choice: at this data point (namely, optimal choice point) the indifference curve is tangent to p_1 x_1 + p_2 x_2 = y. According to this feature, the inference is to get (x_1*, x_2*) that satisfied the following equation:

```latex
$$\begin{equation}
u'(x_1^{*}, x_2^{*})=-\frac{p_1}{p_2}
\end{equation}$$
```

which will derive the optimal choice (x_1*, x_2*):

```latex
$$\begin{equation}
x_1^{*} = \frac{c}{c+d} \frac{m}{p_1}, x_2^{*} = \frac{d}{c+d} \frac{m}{p_2}
\end{equation}$$
```

# Appendix: Learning for CAMLOP

We have seen how to make the best decision based on the inference of CAMLOP. But in real life we have to work the other way around: we observe some historical cost and utility datapoints, but our problem is to estimate what kind of utility function is induced from the observations.

Concretely, suppose that we observe a number of industries making choices between LLMs and human workers based on their considerations of commute times, money costs, accuracy, etc... There exists an analytic solution of c,d obtained by statistical techniques that best fit the observed data points. In this way, the historical datapoints give a way to estimate the utility function. More specifically, we use regression analysis to find the utility function that best describes the relation between x and utility. Mean square error is typically employed as the loss function for learning the utility function. The loss function is defined on J training datapoints X={(x_1^(1),x_2^(1)),(x_1^(2),x_2^(2)),..., (x_1^(J),x_2^(J))}:

```latex
$$\begin{equation}
L(c,d) =\frac{1}{J} \mathop{\sum_{i = 1}^{J}} \log u(x_1^{(i)},x_2^{(i)};c,d)
\end{equation}$$
```

where the model parameters are c,d. A normal equation or gradient descent can be used to optimize this loss function and obtain the final c,d.

# Appendix: Experiment Details

We choose GPT-3 because of its superior CoT reasoning performance, as reported in the work of wei2022chain and wang2022self. Due to the limited context window size (up to 4096 word-pieces for the GPT-3 series of models), we use an 8-shot setting for all datasets. Our experiments are based on access to the OpenAI GPT-3 API. We perform all experiments in the few-shot setting, without training or fine-tuning the LLM. For a fair comparison, we use the same prompts as in the work of wei2022chain. For arithmetic reasoning tasks, we use the same set of 8 manually written exemplars. For commonsense reasoning tasks, exemplars are randomly selected from the training set with manually written CoT prompts.

Example prompts for arithmetic reasoning:

**Q:** There are 15 trees in the grove. Grove workers will plant trees in the grove today. After they are done, there will be 21 trees. How many trees did the grove workers plant today?
**A:** We start with 15 trees. Later we have 21 trees. The difference must be the number of trees they planted. So, they must have planted 21 - 15 = 6 trees. The answer is 6.

**Q:** If there are 3 cars in the parking lot and 2 more cars arrive, how many cars are in the parking lot?
**A:** There are 3 cars in the parking lot already. 2 more arrive. Now there are 3 + 2 = 5 cars. The answer is 5.

**Q:** Leah had 32 chocolates and her sister had 42. If they ate 35, how many pieces do they have left in total?
**A:** Leah had 32 chocolates and Leah's sister had 42. That means there were originally 32 + 42 = 74 chocolates. 35 have been eaten. So in total they still have 74 - 35 = 39 chocolates. The answer is 39.

**Q:** Jason had 20 lollipops. He gave Denny some lollipops. Now Jason has 12 lollipops. How many lollipops did Jason give to Denny?
**A:** Jason had 20 lollipops. Since he only has 12 now, he must have given the rest to Denny. The number of lollipops he has given to Denny must have been 20 - 12 = 8 lollipops. The answer is 8.

**Q:** Shawn has five toys. For Christmas, he got two toys each from his mom and dad. How many toys does he have now?
**A:** He has 5 toys. He got 2 from mom, so after that he has 5 + 2 = 7 toys. Then he got 2 more from dad, so in total he has 7 + 2 = 9 toys. The answer is 9.

**Q:** There were nine computers in the server room. Five more computers were installed each day, from monday to thursday. How many computers are now in the server room?
**A:** There are 4 days from monday to thursday. 5 computers were added each day. That means in total 4 \* 5 = 20 computers were added. There were 9 computers in the beginning, so now there are 9 + 20 = 29 computers. The answer is 29.

**Q:** Michael had 58 golf balls. On tuesday, he lost 23 golf balls. On wednesday, he lost 2 more. How many golf balls did he have at the end of wednesday?
**A:** Michael initially had 58 balls. He lost 23 on Tuesday, so after that he has 58 - 23 = 35 balls. On Wednesday he lost 2 more so now he has 35 - 2 = 33 balls. The answer is 33.

**Q:** Olivia has $23. She bought five bagels for $3 each. How much money does she have left?
**A:** She bought 5 bagels for $3 each. This means she spent 5 \* $3 = $15 on the bagels. She had $23 in beginning, so now she has $23 - $15 = $8. The answer is 8.

# Appendix: Diversity Metrics Over Diverse Reasoning Paths

As described in Sec. 4.4.0.2, the majority vote method of calculating the answer probability over all sampled rationales can be regarded as taking an unnormalized unweighted sum. As described in wang2022self, other methods of computing answer probability of **a** include the unnormalized weighted average, normalized weighted average, unnormalized weighted sum, and normalized weighted sum. Tab. 2 shows that unnormalized unweighted sum generally outperforms others. We use this setting in all experiments following wang2022self.

In practice, the majority vote method of calculating the answer probability over all sampled rationales proposed at Eq. 1 is the same as taking the unweighted sum over **a**_i (*i.e.*, the sum over indicator function), where |N| denotes the number of answers (*i.e.*, the number of sampling times). As described in wang2022self, another selection of computing answer probability of **a** over all sampled rationales is to use unnormalized probability **p**_**a**\_i of the language model generating **a**\_i given the prompt of sample **s**:

```latex
$$\begin{equation}
\mathbf{p}_{\mathbf{a}_i} = P(\mathbf{r}_i, \mathbf{a}_i \mid \mathbf{s})
\end{equation}$$
```

Then we use all unnormalized probability **p**_**a**\_i given by the language model's decoder to calculate the probability **p**_**a** of the answer **a** for sample **s**:

```latex
$$\begin{equation}
\mathbf{p}_\mathbf{a} = \frac{{\textstyle \sum_{i=1}^{\left | N \right |}} \mathbf{1}  (\mathbf{a}_i = \mathbf{a}) \mathbf{p}_{\mathbf{a}_i} }{\left | N \right | }
\end{equation}$$
```

where |N| denotes the number of rationales decoded for the sample **s**. The result of using the calculation output of Eq. 2 as the probability of answer **a** is shown in Tab. 2 as **Unnormalized Weighted Sum**. Apart from computing **p**\_**a** by taking the unnormalized probability of the language model generating (**r**\_i, **a**\_i) given **s**, we can normalize the output probability for (**r**\_i, **a**\_i) by the output length of **r**\_i [brown2020language]:

```latex
$$\begin{equation}
\mathbf{p}_{\mathbf{a}_i} = \exp^{\frac{1}{K}\sum_{k=1}^K {\log p_{t_k}}}
\end{equation}$$
```

where p_t_k is the log probability of generating the k-th token t_k in (**r**\_i, **a**\_i) conditioned on the previous tokens, and K is the total number of tokens in (**r**\_i, **a**\_i):

```latex
$$\begin{equation}
p_{t_k} = P(t_k \mid \mathbf{s}, t_1, \ldots, t_{k-1})
\end{equation}$$
```

The result of using the calculation output of Eq. 3 as the normalized probability **p**\_i^**a** of the language model generating **a**\_i given prompt of sample **s** is shown in Tab. 2 as **Normalized Weighted Sum**.

In addition, in Tab. 2 we also report the results by taking a weighted average, which means calculating a score for each **a** of its weighted sum divided by the sum of indicator functions.

Tab. 2 shows that unnormalized unweighted sum generally outperforms others. We use this setting in all experiments following wang2022self.

# Appendix: Details of Balancing Cost and Utility

In Sec 3, we conduct experiments on the SingleEq dataset to quantitatively calculate cost and utility for CAMLOP. The trends on other datasets are consistent with SingleEq dataset. We randomly selected one dataset as an example to demonstrate the superiority of MCS in balancing cost and utility.

For the cost, we consider money and time. We set the price of the LLM as p_llm and the time cost as t_llm. Since we use GPT-3, the price p_llm for a single math problem (decoding once) is $0.08 on average, and the time cost t_llm is 0.8 second based on empirical results. The pricing of `text-davinci-002` is $0.02 per 1000 tokens. We set p_llm to be $0.08 because an input sample for few-shot CoT contains about 4000 tokens on average when decoding only once.

The price of solving a single math problem with only human labor is p_human and the time cost is t_human. We set p_human to be $0.125 and t_human to be 60 seconds based on our empirical results. Minimum hourly wage in the United States is $7.5. Solving a problem requires 60 seconds on average. Therefore, the price and time cost required to complete a problem are $0.125 and 60 seconds, respectively.

The price of human labor for MCS to correct a single math problem p_MCS is $0.0625 and the time cost t_MCS is 30 seconds based on empirical results. Note the time required to inspect and correct is less than the time needed to fully solve the entire problem, therefore t_MCS < t_human.

For the utility, we consider user satisfaction as the comprehensive score. We ask five users to write down their satisfaction levels and calculate the average. The human ratings are collected via Amazon Turk. In addition to the effective data collected from 5 users for each evaluation method, data from several users were excluded due to failures in the attention verification. The hourly salary is $10 per hour and per user. We randomly select a set of examples and the satisfaction level is rated from 1 to 5, with 1 as the worst satisfaction and 5 as the most user-friendly and best satisfaction. The human rating scores are then averaged.

We performed regression analysis on user satisfaction based on LLM and Human and ultimately learned the utility function `latex $\mathbf{u}(\mathbf{x}_{LLM}, \mathbf{x}_{Human}) = \mathbf{x}_{LLM}^{2.05}*(10 * \mathbf{x}_{Human})^{1.94}$ `, where x_LLM equals to 1 when using LLM to decode one time, and x_Human equals to 10 when solving the problem with only human.

The result shows that MCS +Self-consistency generally outperforms other methods with higher utility (_i.e._, better user satisfaction) as well as an acceptable cost.

# Appendix: Related Work (Extended)

## Human-In-the-Loop System

The human-in-the-Loop system, aiming to achieve what neither humans nor machines can accomplish independently, is defined as a model requiring human interaction [karwowski2006international]. When the machine cannot solve the problem, or when cost or security considerations require humans to participate, manual intervention is necessary [wu2022survey; zanzotto2019human; mosqueira2023human]. Previous human-in-the-loop systems focus either on adding appropriate tags to data or providing feedback on cases with a certain confidence interval to the machines and thus retrain the model afterward with the labeled data or rewarded cases [wu2022survey; zanzotto2019human]. The human-in-the-loop system outperforms both standalone AI and humans working alone [bien2018deep].

Recently, LLM-based AI (Artificial Intelligence) systems are developing very quickly, and this trend is expected to expand to the majority of the workforce in the near future [ouyang2022training; zhang2022opt; sanh2021multitask]. However, these systems do not always provide satisfactory answers without human intervention, especially mathematical problems. Additionally, in domains such as criminal fact identification and charge predictions, inference should be reasonable and controlled by humans [custers2022ai] while LLMs are not qualified. Therefore, it is essential to develop a human-in-the-loop prompting-based system that is designed with the ability to collaborate with people. Such a system would make work more efficient and effective. Until recently, few researchers have systematically and quantitatively explored human-in-the-loop prompting-based systems.

Different from ChatGPT's RLHF (Reinforcement Learning from Human Feedback), we take the first step to use human feedback in an online way without access to parameters. Even though it's a preliminary step, this online method could benefit from further refinement and combination with RLHF in future research.

## In-context Learning

Over the past decade, there have been significant advancements in Large Language Models (LLMs) [ouyang2022training; zhang2022opt; sanh2021multitask]. These developments have been further accelerated by the introduction of In-Context Learning (ICL) [kojima2022large]. Essentially, LLMs are capable of processing a few training examples and a test instance as its natural language instruction. It then directly decodes the output without requiring any updates to its parameters. LLMs can perform diverse tasks effectively when provided with corresponding instructions [ouyang2022training; srivastava2022beyond; wei2022chain]. This presents an opportunity for humans to modify predicted outcomes through natural language instructions, which serve as a flexible and user-friendly interface.

## Chain-of-Thought Prompting

Chain-of-Thought (CoT) prompting enables models to decompose multi-step problems into smaller steps. With CoT, LLMs can solve complex reasoning problems that cannot be solved with standard prompting methods [wei2022chain; wang2022self]. Despite its usefulness, CoT may be prone to errors, which can have a negative impact on the reasoning of the model. Fortunately, most mistakes can be easily interpreted. About half of these mistakes are related to incorrect calculations while the other half are mistakes from flawed reasoning where rationales lack the necessary knowledge [Minerva]. To address this issue, we limit users to modifying, deleting, or adding a single sub-logic as a means of resolving both types of errors. Additionally, we have found that most mistakes can be easily detected and corrected by humans through rationales. Against this background, CoT presents an opportunity for humans to efficiently modify predicted outcomes through sub-logics of rationales.
