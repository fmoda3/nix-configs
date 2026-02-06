# Abstract

Large Language Models prompting, such as using in-context demonstrations, is a mainstream technique for invoking LLMs to perform high-performance and solid complex reasoning (e.g., mathematical reasoning, commonsense reasoning), and has the potential for further human-machine collaborative scientific findings. However, current LLMs are delicate and elusive in prompt words and styles. And there is an unseen gap between LLM understanding and human-written prompts. This paper introduces `AlignedCoT`, an LLM-acquainted prompting technique that includes proficient "native-speaking" in in-context learning for the LLMs. Specifically, it achieves consistent and correct step-wise prompts in zero-shot scenarios by progressively probing, refining, and formatting the LLM chain of thoughts so that free from handcrafted few-shot demonstrations while maintaining the prompt quality. We conduct experiments on mathematical reasoning and commonsense reasoning. We find that LLMs with `AlignedCoT` perform significantly superior to them with human-crafted demonstrations. We further apply `AlignedCoT` for rewriting the GSM8K training set, resulting in a _GSM8K-Align_ dataset. We observe its benefits for retrieval augmented generation. The code and data can be found at https://github.com/yangzhch6/AlignedCoT.

# Introduction

Rapidly increasing capabilities of large language models (LLMs) lead to remarkable advances in various NLP tasks. However, as LLMs scale up, the computational load of fine-tuning LLMs becomes generally unaffordable. Meanwhile, in-context learning (ICL) methods exhibit competing performance with fine-tuning. ICL saves the high costs of training LLMs and enjoys high interpretability from the produced reasoning steps. These advantages make ICL emerge as a new popular paradigm for NLP, where LLMs make predictions based on in-context demonstrations.

[IMAGE: A human/machine (A) tends to accept words in her own style (A's own text style) rather than other people's (B's text style). In this work, we investigate efficient CoT demonstrations by resorting to LLM-learned text habits (an LLM-style).]

[IMAGE: **A**. Existing few-shot demonstrations are conventionally dataset samples or human crafts ("Manual-Style"). As a result, an LLM tends to copy the "Manual-Style" format mechanically. **B**. The proposed `AlignedCoT` prompt has zero-shot CoTs with correct and in LLM-acquainted format ("Native-Style''). The `AlignedCoT` is obtained via three steps: (1) Probing LLM's native style in zero-shot scenarios; (2) Refining the generated CoT to correct errors in the first step; (3) Formatting the generated CoTs in the first two steps.]

A core question in ICL is the selection of effective demonstrations. Chain-of-thought (CoT) prompting proposes a sequence of short sentences describing intermediate reasoning steps toward final answers. Originating from CoT, a line of ICL research composes few-shot prompts by selecting examples that are relevant to the input question. The other line of work improves LLMs by increasing prompt diversity by sampling reasoning paths multiple times. Furthermore, other works propose to mimic human cognitive processes. However, CoT's text style, specifically LLMs' familiarity and proficiency in language use while thinking, and its effect on LLM complex reasoning performances, remain underexplored.

An intuition is that it is more natural for humans to speak in their own style than to imitate others. A similar situation for LLMs as they may perform better when prompted with their native-style CoT rather than imitating other styles. However, current CoTs are often human-crafted or come from static dataset samples, resulting in LLMs mimicking the given demonstrations and without their own thinking process. Contrastively, LLMs can benefit from a zero-shot manner by generating CoTs in their own "native-style" thinking process, which elicits the stored knowledge learned from training (pre-training, SFT, RLHF).

To investigate such "native-style" thinking processes, this paper proposes Aligned Chain-of-Thought (`AlignedCoT`) Prompting. `AlignedCoT` aims to improve LLM reasoning by aligning the conventional few-shot CoTs to a "native-style" zero-shot CoT. From the perspective of generalization, the alignment mitigates the disparity between the training and inference; reduces the requirement for extensive model generalization capabilities; and results in performance enhancements.

The proposed `AlignedCoT` operates in steps. (1) Using each question in the few-shot prompt to query the LLM and generate its native-style CoT in a zero-shot scenario. (2) Refining the generated CoT to correct any errors. (3) Unifying the CoT text formats, including the format of the final answer and the format of the solution steps. We then construct the few-shot prompt using the native-style CoT obtained in the aforementioned three steps to query the LLM.

The contributions of this paper are as follows:

- We propose a novel and effective prompting method named `AlignedCoT`, which aligns the CoT text style in few-shot examples to the native style of Large Language Models to improve their reasoning capability.

- We evaluate `AlignedCoT` through extensive experiments, including baseline comparisons and ablation studies. The experimental results show that `AlignedCoT` achieves significant performance improvements and can be easily integrated with other in-context learning methods.

- We apply `AlignedCoT` to overwrite the GSM8K dataset and provide the _GSM8K-Align_ dataset. Empirical results show that _GSM8K-Align_ can effectively improve the performance of retrieving augmented methods.

# Related Work

As the amount of computation and data in language models continues to grow, advanced capabilities emerge. The ability of in-context learning (ICL), that is, to solve the corresponding tasks according to the given few-shot examples, is something that language models are particularly skilled at when scaled up to a certain size. Specifically, multi-step reasoning tasks such as math problem solving and Commonsense Reasoning witness significant performances growth from larger models, compared to plain tasks such as emotion classification. Moreover, few-shot prompting a language model could outperform itself fine-tuned with a full training set. In this work, we further investigate the leverage of prompting an LLM for eliciting advanced reasoning capabilities.

Chain-of-thought prompting shows that prompting LLMs with intermediate reasoning steps can greatly improve multi-step reasoning ability. Based on this prominent work, further works show that CoT can be improved by various approaches. Self-consistency proposes conducting majority voting by sampling different reasoning paths. Least-to-Most prompting guides the LLMs to first decompose the original question into small parts and then solve it. Tree-of-Thought further supports chain-of-thought by solving complex problems in a tree search process. Reasoning via Planning repositions LLM as both a world model and an inference model, and combines the Monte Carlo Tree Search algorithm to search in a huge inference space. It is further observed that LLMs are decent zero-shot reasoners and can generate intermediate reasoning steps by simply adding "Let's think step by step" before each answer. Our work sits in the context of CoT reasoning and proposes a new method to improve reasoning ability in LLMs by aligning CoT text style in few-shot examples to LLM's native style with correct reasoning steps in zero-shot scenarios.

Due to the sensitivity of LLMs to prompts, tasks, and datasets, designing prompts and the selection of good examples for in-context learning in few-shot scenarios is a fundamental question. The vanilla CoT prompts LLMs with 8 manually written examples. Based on this, PAL converts these examples into programming language statements. Complex CoT selects examples with the most complex reasoning steps from the training set, which improves multi-step reasoning. The other line of work uses retrieval-based methods to extract the most similar and relevant examples in the training set. Some work retrieves semantically similar examples with a test query to formulate its corresponding prompt. EPR uses an unsupervised retriever to obtain a set of candidate examples. CEIL leverages contrastive learning to obtain preferred examples. DQ-Lore leverages Dual Queries and Low-rank approximation Re-ranking for sample selection. The demonstrations in these works are either from the original training set or handcrafted by humans. In this paper, we propose `AlignedCoT`, which leverages LLM to generate correct and unified few-shot demonstrations on their own.

Additionally, Auto-CoT divides the training set into k categories and then selects k samples that are closest to the cluster center, and then allows the LLM to automate its own demonstrations. Some works generate self-explanations as in-context exemplars for medical QA. Others built a data-generation pipeline named SP-CoT for open-domain question-answering (OPQA) consisting of carefully constructed data generation and composition steps by hand, but is difficult to transfer to other data fields. The aforementioned works are limited to specific domains and only discuss generating demonstrations by LLMs themselves. This paper further delves into error handling in demonstrations and the impact of "native-style" CoTs on LLMs performance.

# `AlignedCoT` Prompting

The main purpose of `AlignedCoT` is to achieve LLM's native-style CoTs without following human-written few-shot demonstrations. Specifically, the native-style CoTs are preferred to be zero-shot CoTs and at the same time have consistent formats and correct steps as stronger substitutions to the few-shot handcrafts. To achieve this, `AlignedCoT` builds an effective alignment between the two with the following steps: Probing LLM's native style in zero-shot scenarios, refining the generated CoT to correct errors in the first step, and unifying the format of the generated CoTs in the first two steps. The obtained `AlignedCoT` is then applied by replacing the CoT demonstrations in the original few-shot prompt to query LLMs.

## Probing Native-Style of LLM

The chain-of-thought text in the few-shot examples is generally handcrafted. We consider the text style of handcrafted CoTs as a "manual-style". Compared with the few-shot scenarios in existing works (which directly use handcrafted examples), LLM does not need to imitate the CoT text that is inconsistent with its own language style in zero-shot scenarios. We refer to the CoT text style generated by LLM in zero-shot scenarios as "native-style". When prompting Large Language Models (LLMs) with "manual-style" CoTs, LLMs will follow the formatted demonstrations, which may not fully exploit the LLM's learning capabilities.

To bridge this gap, we introduce the first step of our `AlignedCoT` Prompting method, which involves Probing LLM's native-style Chain-of-Thought (CoT) in zero-shot scenarios. In order to acquire the CoT with native style, we use the magic phrase "Let's think step by step" to query LLMs for each example in a given few-shot prompt to generate a CoT that resembles the way it naturally responds to the input question.

However, the generated native-style CoTs are not always correct. To deal with the errors and inconsistency, we need to proofread the generated content against the ground truth answer in the dataset.

[IMAGE: The illustration of our refining process. The modifications in red are annotated manually. We modify the first error each time and then query the LLM to complete the text behind the last modified error.]

## Refining CoTs

The second critical phase of our `AlignedCoT` Prompting involves the process of refining the CoTs generated in the previous step. This phase is to rectify the inaccuracies in the initially generated content. The ultimate goal is to ensure that the CoTs adhere to the highest standards of accuracy, enabling more precise reasoning and response generation by Large Language Models.

The refining process is initiated by identifying and addressing the first encountered error or irrationality in the CoT text. Subsequently, we harness the capabilities of LLMs to iteratively correct the text, moving forward and completing the answer from the initially modified error position. This iterative approach is executed in the same zero-shot scenario, ensuring that the entire text is rectified while preserving the native style of the LLM's expression. Note that our approach to refinement is designed with a focus on minimalist text modification, which ensures that the generated CoTs are not only error-free but also in harmony with the inherent stylistic nuances of the LLM.

## Unifying the Format of CoTs

A crucial aspect that deserves meticulous attention is the consistency of the answer text format and punctuation marks across different examples. This consistency plays a pivotal role in ensuring optimal model performance, as it enables the model to understand and respond to the input queries.

To unify the format of each example, we undertake a manual examination of the generated CoTs from the previous steps. During this evaluation, we focus on two aspects: the format of the answer text and the punctuation marks of solution steps. By meticulously inspecting and revising these elements, we ensure that each CoT conforms to a standardized style, making them more interpretable and consistent in their presentation. This approach guarantees that the standardized CoTs maintain a natural and coherent flow, thus enhancing their utility in subsequent reasoning and response generation tasks.

# Experiments

In this section, we first discuss our experimental setting. We not only show `AlignedCoT`'s superior performance in multi-step reasoning but also demonstrate that `AlignedCoT` helps LLM find logical paradoxes better. Furthermore, we conduct ablation study, case study, and more in-depth analysis.

## Experimental Setup

We evaluate our `AlignedCoT` on GSM8K, AQUA, SVAMP, AddSub, SingleEQ, and Penguins. We choose these datasets because we focus on the multi-step reasoning ability of large language models. Specifically, there are 7.4k training instances and 1.3k test instances in GSM8K, all samples have manually labeled intermediate problem-solving steps. AQUA is a larger mathematical dataset with more difficult samples that are annotated with rationales by human annotators. AddSub and SingleEQ require the model to have basic computational capabilities. Penguins contain questions referring to different objects (e.g., Find the name of the oldest penguin).

SVAMP is a challenging dataset created by applying carefully chosen variations over examples sampled from existing datasets. However, some questions have logical incorrectness. For example: "A waiter had 12 customers. While 15 customers left he got 14 new customers", where the number of customers leaving is actually higher than the number of existing customers, which is impossible to happen. Specifically, we first manually go over and fix the logical paradoxes in the original SVAMP dataset. There are 7.1% of the entire dataset that have such logical paradoxes. We then have a fixed dataset, denoted as SVAMP*. We use the fixed SVAMP* for experiments. The dataset will be released later.

Our experiments are conducted on GPT-3.5-Turbo and GPT-4 (both use the 0613 version) via the OpenAI API key. Our `AlignedCoT` focuses on converting the CoT text style of examples in the given few-shot prompt, it neither requires special sample selection methods nor changes the processes of the prompting methods. In our experiments, we choose the original CoT prompt, the complex CoT prompt, and the prompt extracted by Efficient Prompt Retriever (EPR) as the baselines. Following prior work, we add "Let's think step by step" before the reasoning chains for all baselines to improve the performance. We show all the prompts we acquired in the Appendix.

We compare `AlignedCoT` with previous CoT methods. All methods use greedy decoding (i.e. temperature is set to 0). The Standard Prompt is human-crafted without intermediate reasoning steps, Auto-CoT constructs prompt from a sample pool, and the CoT Prompt includes manually designed intermediate steps. The Complex CoT as a strong baseline consists of the examples with the most complex intermediate reasoning steps. In Complex Prompt, intermediate steps are taken from the source dataset, if the source data does not have intermediate steps, they are manually annotated.

[IMAGE: In the case of sampling diverse reasoning paths on GSM8K, our `AlignedCoT` also outperforms Complex CoT.]

## Main Results

The results demonstrate that in general, the proposed `AlignedCoT` effectively improves reasoning abilities in LLMs. LLMs with CoT empowered by our `AlignedCoT` show an average of +3.2% and +1.7% performance improvements for GPT-3.5-turbo and GPT-4, respectively. Moreover, `AlignedCoT` can work with other CoT methods and have positive synergistic effects. For example, GPT-4 with Auto-CoT empowered by `AlignedCoT` results in an average improvement of 0.9%. GPT-3.5 with Complex CoT empowered by `AlignedCoT` improves on average 2.6%, and achieves 4.8% gain on the Penguins dataset.

We further follow the Self-Consistency method to compare Complex CoT with our proposed `AlignedCoT` in the case of sampling multiple reasoning paths with temperature set to 0.7. We evaluate the answer accuracy of gpt-3.5-turbo on GSM8K. According to the experimental results, the overall performance of our `AlignedCoT` significantly exceeds that of Complex CoT.

## `AlignedCoT` for Logical Pitfalls

To further investigate the capability of `AlignedCoT` for detecting intermediate logical errors, as a qualified counterpart of handcrafted demonstrations, we conduct experiments on the 7.1% flaw questions on the original SVAMP. The logical error recognition rate of GPT-3.5-Turbo with `AlignedCoT` is 18.3%, and the GPT-4 counterpart reaches 78.9%, significantly outperforming Complex CoT. The results suggest that `AlignedCoT` helps LLMs to better spot logical incorrectness in questions.

[IMAGE: Two cases of logical error detection. The text in brown is GPT-4's reasoning process for discovering logical incorrectness.]

## Ablation Study

A closer analysis of the impact of each step in `AlignedCoT`: Probing, Refining, and Formatting shows that the deletion of all probing, refining, and formatting results in the baseline Complex CoT, whereas the inclusion of all three is the full `AlignedCoT`. Experiments use GPT-3.5-Turbo as the backbone and are on GSM8K. The results show that solely the first step (Probing) leads to performance improvement of +0.7%. Adding the Refining or Formatting step on top of the Probing step, the performance further improves. When all three steps are deployed simultaneously, our `AlignedCoT` reaches 82.4%. Therefore, the Probing, Refining, and Formatting steps all contribute to `AlignedCoT` for multi-step reasoning, and they work best when deployed in combination. We include further ablation studies on a setting with CORRECT "native-style" prompts before the Refining step to find the pure impact of such "native-style" prompts without intervention of refinement.

[IMAGE: A case of the GSM8K dataset. We show one example in the few-show prompt and one test example from the test split. The "manual-style" CoT is colored in blue, while the "native-style" CoT is colored in green.]

## `AlignedCoT` with Smaller LMs

To investigate the generalizability and robustness of our approach, we further apply `AlignedCoT` to smaller language models. Specifically, we conduct experiments with the representative Llama-2-7b-chat. The results demonstrate the effectiveness of our `AlignedCoT` across different LLMs and Scales.

## `AlignedCoT` for RAG

We further explore the effectiveness of `AlignedCoT` for retrieval-augmented generation (RAG) with in-context learning. We use `AlignedCoT` to overwrite training data from the original GSM8K training set: (1) We first use few-shot demonstrations to query the LLM to output the native-style CoT for each sample in the training set. (2) For those samples that can not be answered correctly in the previous setting, we create a 4-shot prompt with a question, an answer in the original dataset (handcrafted), and a native-style answer from `AlignedCoT`. (_style conversion prompt_.) (3) For a very small proportion of examples (around 1%) that can not be answered correctly (1) and (2), we remove them from the example pool. Consequently, we obtain the overwritten data _GSM8K-Align_. Furthermore, we refer to the data generated based on _style conversion prompt_ as _GSM8K-Conv_.

We choose Random Selection, Efficient Prompt Retriever (EPR), and Complex CoT as baselines. Random Selection method randomly extracts 8 samples from the training set. Efficient Prompt Retriever (EPR) retrieves the most similar training instances as exemplars for a given test case. Complex CoT builds prompt by selecting the examples with the most complex reasoning steps in the training set, and therefore also serves as a strong baseline of the retrieve methods.

The results show that with our Aligned Data, we achieve +1.5%, +3.6%, and +2.8% improvement on Random Selection, EPR, and Complex CoT, respectively. Moreover, _GSM8K-Conv_ achieves +2.8% improvement with the EPR retriever, inferior to the _GSM8K-Align_ counterpart. The results suggest that `AlignedCoT` is consistently effective for generalized in-context learning settings. The _GSM8K-Align_ will be released later. We hope it provides a resource and support to the in-context RAG study.

## Case Study

A comparing case between LLM's "native style" by `AlignedCoT` and "manual style" CoT demonstrates that given the test question, compared to the "manual-style" Complex CoT deriving an incorrect answer, the "native-style" `AlignedCoT` CoT provides clear intermediate steps for deriving the correct answer. The `AlignedCoT` CoT is also a detailed expansion of the ground truth solution.

# Conclusion

This paper proposes a new zero-shot prompting approach Aligned Chain-of-Thought (`AlignedCoT`), which elicits LLMs' "native style" thinking process for leveraging their profound embedded knowledge for effective multi-step reasoning. `AlignedCoT` operates in proving, refining, and formatting to obtain competing "native-style" CoTs with handcrafted demonstrations. Experiments suggest multiple advantages of `AlignedCoT`: 1) `AlignedCoT` is demonstrated effective for multi-step reasoning tasks. Moreover, it can be easily combined with CoT, Complex CoT, and self-consistency and achieve further improvements. 2) `AlignedCoT` enhances LLMs' capability of detecting logical errors in reasoning questions. 3) `AlignedCoT` benefits generalized CoT scenarios including retrieval-augmentated generation.

# Limitations and Ethical Considerations

Due to resource limitations, we are unable to test the proposed approach on more benchmarks. Similarly, we can not test the performance based on self-consistency on each benchmark, because the number of samples is proportional to the cost. Moreover, future research endeavors can focus on probing more accurate native styles of LLM and combining the retrieve-based prompting method with native style data. Future studies can also try to combine `AlignedCoT` with other in-context learning approaches to further improve LLMs.

The data and annotations are collected without personal or confidential information. Therefore, we believe that there is no ethical concern.

# Appendix

# Performance Improvement of "Native-Style" Prompt

In order to further clarify whether the enhancements are mainly attributed to our "native-style" CoT or the refinement, we conducted the following experiments: For the original Complex CoT prompt of GSM8K, we delete the examples that can not be answered correctly by GPT-3.5-Turbo. We denote this prompt as "ComplexCoT*" and its Aligned Prompt is "ComplexCoT*-Align". Further, we also sampled two few-shot prompts, all of the examples can be answered correctly by GPT-3.5-Turbo. They are denoted as "Prompt-1" and "Prompt-2", respectively, and their Aligned Prompt is denoted as "Align-1" and "Align-2". Under such an experimental setup, we can ensure that our `AlignedCoT` does not involve the refinement step, thus being able to measure the impact of the "native-style" prompt on the performance of LLMs. The experimental results show that without refinement, the "native-style" prompt significantly improves model performance. We also believe that the improvement of `AlignedCoT` on model performance mainly comes from the "native-style" prompt, and refinement reduces the misleading of wrong examples to LLMs on this basis.

# Consistent Improvement of `AlignedCoT` across Random Selection Examples

Our approach has shown consistent performance improvements in the settings of different few-shot examples. In the Random Selection method, we randomly select 8 samples to construct a few-shot prompt. This procedure is repeated 3 times to ensure statistical robustness, following which we computed the average accuracy to accurately gauge the method's effectiveness.

# Examples of Refinement and Formatting in `AlignedCoT`

In this section, we show some examples of Refinement (Step 2) and Formatting (Step 3) in our `AlignedCoT`.

## Example of Refinement

[IMAGE: An example of our Refinement process. Human modification part is colored in brown.]

[IMAGE: An illustration of formatting answer text and solution steps on GSM8K.]

[IMAGE: An example of formatting answer text and solution steps on GSM8K.]

## Example of Formatting

For Formatting, we aim to unify the format of each examples in the few-shot prompt. This process focus on two aspects: the format of the answer text and the punctuation marks of solution steps. 'Refined CoT' is the prompt we acquired after Refinement (Step 2). 'Formatted CoT' is the prompt we acquired after Formatting (Step 3), which we use as the final `AlignedCoT`. More specifically, for the answer text, we unify it as "Answer:", which also facilitates the extraction of the answer text. For punctuation marks of solution steps, we unify according to the most common and reasonable form in Refined CoT. The form is "STEP N:". If there are no obvious punctuation marks, we don't make changes.

[IMAGE: A case of Refinement on Complex CoT for AQUA.]

# The Amount of Refinement in `AlignedCoT`

In our `AlignedCoT`, the proportion of refinement intervention is low, which demonstrates one of the superiorities of our approach. "Refined/All" indicates the ratio of the number of refined examples to the total number of examples. Overall, in our `AlignedCoT`, GPT-3.5-turbo only requires refinement for 11% of the examples in the prompts of the benchmarks we evaluated, whereas GPT-4 only needs 4% (two examples).

# Full Set of Prompts

We show all the prompts we used in this section. These prompts are also released in our github repo.

## CoT w/ `AlignedCoT` exemplars for GSM8K, SVAMP, AddSub, and SingleEQ

**[Question]:** There are 15 trees in the grove. Grove workers will plant trees in the grove today. After they are done, there will be 21 trees. How many trees did the grove workers plant today?
**[Solution]:**
Let's think step by step.
Step 1: We know that there are originally 15 trees in the grove, and after the grove workers plant trees, there will be 21 trees.
Step 2: The workers planted 21 - 15 = 6 trees today.
Step 3: Therefore, the grove workers planted 6 trees today.
Answer: 6

**[Question]:** If there are 3 cars in the parking lot and 2 more cars arrive, how many cars are in the parking lot?
**[Solution]:**
Let's think step by step.
Step 1: We know that there are originally 3 cars in the parking lot, and then 2 more cars arrive.
Step 2: Therefore, there are 3 + 2 = 5 cars in the parking lot.
Answer: 5

**[Question]:** Leah had 32 chocolates and her sister had 42. If they ate 35, how many pieces do they have left in total?
**[Solution]:**
Let's think step by step.
Step 1: We know that Leah had 32 chocolates and her sister had 42. They ate 35 pieces.
Step 2: Leah and her sister had 32 + 42 = 74 chocolates in total.
Step 3: After eating 35 chocolates, they have 74 - 35 = 39 chocolates left.
Step 4: Therefore, they have 39 chocolates left in total.
Answer: 39

**[Question]:** Jason had 20 lollipops. He gave Denny some lollipops. Now Jason has 12 lollipops. How many lollipops did Jason give to Denny?
**[Solution]:**
Let's think step by step.
Step 1: We know that Jason originally had 20 lollipops, and after giving some to Denny, he now has 12 lollipops.
Step 2: Therefore, Jason gave 20 - 12 = 8 lollipops to Denny.
Answer: 8

**[Question]:** Shawn has five toys. For Christmas, he got two toys each from his mom and dad. How many toys does he have now?
**[Solution]:**
Let's think step by step.
Step 1: We know that Shawn originally has 5 toys, and then he gets 2 toys each from his mom and dad for Christmas.
Step 2: The total number of toys he got for Christmas is 2 + 2 = 4.
Step 3: After Christmas, Shawn has 5 + 4 = 9 toys.
Step 4: Therefore, Shawn has 9 toys now.
Answer: 9

**[Question]:** There were nine computers in the server room. Five more computers were installed each day, from monday to thursday. How many computers are now in the server room?
**[Solution]:**
Let's think step by step.
Step 1: We know that there were originally 9 computers in the server room. Then, 5 more computers were installed each day, from monday to thursday.
Step 2: There are 4 days from Monday to Thursday.
Step 3: So, a total of 5 \* 4 = 20 more computers were installed.
Step 4: Therefore, there are now 9 + 20 = 29 computers in the server room.
Answer: 29

**[Question]:** Michael had 58 golf balls. On tuesday, he lost 23 golf balls. On wednesday, he lost 2 more. How many golf balls did he have at the end of wednesday?
**[Solution]:**
Let's think step by step.
Step 1: We know that Michael had 58 golf balls. On tuesday, he lost 23 golf balls. On wednesday, he lost 2 more.
Step 2: After he lost 23 golf balls, he had 58 - 23 = 35 golf balls left.
Step 3: After he lost 2 more, he had 35 - 2 = 33 golf balls left.
Step 4: Therefore, at the end of Wednesday, Michael had 33 golf balls.
Answer: 33

**[Question]:** Olivia has $23. She bought five bagels for $3 each. How much money does she have left?
**[Solution]:**
Let's think step by step.
Step 1: We know that Olivia has $23 and she bought five bagels for $3 each.
Step 2: The total cost of the bagels is 5 \* $3 = $15.
Step 3: After buying the bagels, Olivia has $23 - $15 = $8 left.
Step 4: Therefore, Olivia has $8 left.
Answer: 8

---

**[Question]**: There are 15 trees in the grove. Grove workers will plant trees in the grove today. After they are done, there will be 21 trees. How many trees did the grove workers plant today?
**[Solution]**:
Let's think step by step.
First, we know that there were originally 15 trees in the grove.
Then, the grove workers planted some trees.
After they finished, there were 21 trees in total.
So, to find out how many trees they planted, we subtract the original number of trees from the final number of trees.
That is, 21 - 15 = 6.
So, the grove workers planted 6 trees today.
Answer: 6.

**[Question]**: If there are 3 cars in the parking lot and 2 more cars arrive, how many cars are in the parking lot?
**[Solution]**:
Let's think step by step.
First, there were 3 cars in the parking lot.
Then, 2 more cars arrived.
So, we add the number of cars that were already there (3) to the number of cars that arrived (2).
3 + 2 = 5
So, there are 5 cars in the parking lot.
Answer: 5.

**[Question]**: Leah had 32 chocolates and her sister had 42. If they ate 35, how many pieces do they have left in total?
**[Solution]**:
Let's think step by step.
First, we add the number of chocolates Leah and her sister had together. That is 32 + 42 = 74 chocolates.
Then, we subtract the number of chocolates they ate from the total number of chocolates they had. That is 74 - 35 = 39 chocolates.
So, they have 39 pieces of chocolates left in total.
Answer: 39.

**[Question]**: Jason had 20 lollipops. He gave Denny some lollipops. Now Jason has 12 lollipops. How many lollipops did Jason give to Denny?
**[Solution]**:
Let's think step by step.
First, Jason had 20 lollipops. Then he gave some to Denny and now he has 12 lollipops.
So, to find out how many lollipops Jason gave to Denny, we need to subtract the number of lollipops Jason has now from the number he had at the beginning.
So, 20 - 12 = 8.
Therefore, Jason gave 8 lollipops to Denny.
Answer: 8.

**[Question]**: Shawn has five toys. For Christmas, he got two toys each from his mom and dad. How many toys does he have now?
**[Solution]**:
Let's think step by step.
First, Shawn had five toys.
Then, he got two toys from his mom, so he had 5 + 2 = 7 toys.
Finally, he got two more toys from his dad, so he now has 7 + 2 = 9 toys.
So, Shawn now has 9 toys.
Answer: 9.

**[Question]**: There were nine computers in the server room. Five more computers were installed each day, from monday to thursday. How many computers are now in the server room?
**[Solution]**:
Let's think step by step.
There were originally 9 computers.
Five more computers were installed each day from Monday to Thursday. That's 4 days. So, 5 computers \* 4 days = 20 computers were added.
So, the total number of computers now in the server room is 9 (original) + 20 (added) = 29 computers.
Answer: 29.

**[Question]**: Michael had 58 golf balls. On tuesday, he lost 23 golf balls. On wednesday, he lost 2 more. How many golf balls did he have at the end of wednesday?
**[Solution]**:
Let's think step by step.
First, Michael lost 23 golf balls on Tuesday. So, 58 - 23 = 35 golf balls remained.
Then, he lost 2 more golf balls on Wednesday. So, 35 - 2 = 33 golf balls remained.
Therefore, Michael had 33 golf balls at the end of Wednesday.
Answer: 33.

**[Question]**: Olivia has $23. She bought five bagels for $3 each. How much money does she have left?
**[Solution]**:
Let's think step by step.
First, we need to find out how much Olivia spent on bagels. She bought 5 bagels for $3 each, so she spent 5 \* $3 = $15.
Then, we subtract the amount she spent from the amount she had. She had $23 and spent $15, so she has $23 - $15 = $8 left.
Therefore, Olivia has left $8.
Answer: 8.

## Complex CoT w/ `AlignedCoT` exemplars for GSM8K

**[Question]**: Angelo and Melanie want to plan how many hours over the next week they should study together for their test next week. They have 2 chapters of their textbook to study and 4 worksheets to memorize. They figure out that they should dedicate 3 hours to each chapter of their textbook and 1.5 hours for each worksheet. If they plan to study no more than 4 hours each day, how many days should they plan to study total over the next week if they take a 10-minute break every hour, include 3 10-minute snack breaks each day, and 30 minutes for lunch each day?
**[Solution]**:
Let's think step by step.
STEP 1: Calculate the total time needed to study the textbook chapters.
They have 2 chapters of their textbook to study, and they plan to dedicate 3 hours to each chapter.
So, the total time needed to study the textbook chapters is 2 _ 3 = 6 hours.
STEP 2: Calculate the total time needed to memorize the worksheets.
They have 4 worksheets to memorize, and they plan to dedicate 1.5 hours for each worksheet.
So, the total time needed to memorize the worksheets is 4 _ 1.5 = 6 hours.
STEP 3: Calculate the total time needed for breaks and meals each day.
They take a 10-minute break every hour, so in a 4-hour study session, they will have 4 _ 10 = 40 minutes of breaks.
They also have 3 10-minute snack breaks each day, so they will have 3 _ 10 = 30 minutes of snack breaks.
They have 30 minutes for lunch each day.
So, the total time needed for breaks and meals each day is 40 + 30 + 30 = 100 minutes, which is equal to 100/60 = 1.67 hours.
STEP 4: Calculate the total time needed to study each day.
They plan to study no more than 4 hours each day, and they need to subtract the time needed for breaks and meals.
So, the total time they can study each day is 4 - 1.67 = 2.33 hours.
STEP 5: Calculate the total number of days needed to study.
They need a total of 6 hours to study the textbook chapters and 6 hours to memorize the worksheets.
So, the total time needed to study is 6 + 6 = 12 hours.
Since they can study 2.33 hours each day, they will need 12 / 2.33 = 5.15 days to complete their study.
Since they can't study for a fraction of a day, they should plan to study for 6 days.
Therefore, they should plan to study for a total of 6 days over the next week.
Answer: 6

**[Question]**: Mark's basketball team scores 25 2 pointers, 8 3 pointers and 10 free throws. Their opponents score double the 2 pointers but half the 3 pointers and free throws. What's the total number of points scored by both teams added together?
**[Solution]**:
Let's think step by step.
STEP 1: Calculate the number of points scored by Mark's team.
Mark's team scores 25 2 pointers, which means they score 25 _ 2 = 50 points from 2 pointers.
They also score 8 3 pointers, which means they score 8 _ 3 = 24 points from 3 pointers.
Finally, they score 10 free throws, which means they score 10 _ 1 = 10 points from free throws.
Therefore, the total number of points scored by Mark's team is 50 + 24 + 10 = 84 points.
STEP 2: Calculate the number of points scored by the opponents.
The opponents score double the 2 pointers, which means they score 2 _ 50 = 100 points from 2 pointers.
They also score half the 3 pointers, which means they score 0.5 _ 24 = 12 points from 3 pointers.
Finally, they score half the free throws, which means they score 0.5 _ 10 = 5 points from free throws.
Therefore, the total number of points scored by the opponents is 100 + 12 + 5 = 117 points.
STEP 3: Calculate the total number of points scored by both teams.
The total number of points scored by both teams is 84 + 117 = 201 points.
Answer: 201

**[Question]**: Bella has two times as many marbles as frisbees. She also has 20 more frisbees than deck cards. If she buys 2/5 times more of each item, what would be the total number of the items she will have if she currently has 60 marbles?
**[Solution]**:
Let's think step by step.
STEP 1: Calculate the number of marbles she currently has.
When Bella buys 2/5 times more marbles, she'll have increased the number of marbles by 2/5*60 = 24
The total number of marbles she'll have is 60+24 = 84
STEP 2: Calculate the number of frisbees she currently has.
If Bella currently has 60 marbles, and she has two times as many marbles as frisbees, she has 60/2 = 30 frisbees.
If Bella buys 2/5 times more frisbees, she'll have 2/5*30 = 12 more frisbees.
The total number of frisbees she'll have will increase to 30+12 = 42
STEP 3: Calculate the number of deck cards she currently has.
Bella also has 20 more frisbees than deck cards, meaning she has 30-20 = 10 deck cards
If she buys 2/5 times more deck cards, she'll have 2/5\*10 = 4 more deck cards.
The total number of deck cards she'll have is 10+4 = 14
STEP 4: Calculate the total number of items she'll have If she buys 2/5 times more of each item.
Together, Bella will have a total of 14+42+84 = 140 items
Answer: 140

**[Question]**: A group of 4 fruit baskets contains 9 apples, 15 oranges, and 14 bananas in the first three baskets and 2 less of each fruit in the fourth basket. How many fruits are there?
**[Solution]**:
Let's think step by step.
STEP 1: Figure out the total number of fruits in the first three baskets.
In each of the first three basket, there are 9 apples + 15 oranges + 14 bananas = 38 fruits.
So, in the first three baskets, there are a total of 38 fruits \* 3 = 114 fruits.
STEP 2: Figure out the number of fruits in the fourth basket.
In the fourth basket, there are 2 less of each fruit compared to the first three baskets.
So, there are 9 apples - 2 = 7 apples.
There are 15 oranges - 2 = 13 oranges.
There are 14 bananas - 2 = 12 bananas.
Therefore, in the fourth basket, there are a total of 7 apples + 13 oranges + 12 bananas = 32 fruits.
STEP 3: Figure out the total number of fruits in all four baskets.
The four baskets together have 114 (total fruits in the first three baskets) + 32 (fruits in the fourth basket) = 146 fruits.
Answer: 146

**[Question]**: You can buy 4 apples or 1 watermelon for the same price. You bought 36 fruits evenly split between oranges, apples and watermelons, and the price of 1 orange is $0.50. How much does 1 apple cost if your total bill was $66?
**[Solution]**:
Let's think step by step.
STEP 1: Calculate the number of each kind of fruit you bought.
We also know that you bought 36 fruits evenly split between oranges, apples, and watermelons. So, you bought 36/3 = 12 for each kind of fruit.
STEP 2: Calculate the total cost of the oranges.
We know that the price of 1 orange is $0.50. So, the total cost of all the oranges is 12 _ $0.50 = $6.
STEP 3: Define the variable.
Let's assume the cost of 1 apple is x dollars.
STEP 4: Establish an equation according to: the sum of the cost of each kind of fruit (apple, watermelon, and watermelon) equals to the total cost $66.
So, the total cost of all the apples is 12 _ x = 12x dollars.
We are given that you can buy 4 apples or 1 watermelon for the same price. So, the cost of 1 watermelon is also 4x dollars.
The total cost of all the watermelons is 12 \* 4x = 48x dollars.
We know that the total bill was $66.
Therefore, we can write the equation: $6 + 12x + 48x = $66.
STEP 5: Solve the equation and get the answer.
Simplifying the equation, we get $6 + 60x = $66.
Subtracting $6 from both sides, we get 60x = $60.
Dividing both sides by 60, we get x = $1.
So, the cost of 1 apple is $1.
Answer: 1

**[Question]**: Susy goes to a large school with 800 students, while Sarah goes to a smaller school with only 300 students. At the start of the school year, Susy had 100 social media followers. She gained 40 new followers in the first week of the school year, half that in the second week, and half of that in the third week. Sarah only had 50 social media followers at the start of the year, but she gained 90 new followers the first week, a third of that in the second week, and a third of that in the third week. After three weeks, how many social media followers did the girl with the most total followers have?
**[Solution]**:
Let's think step by step.
STEP 1: Figure out how many followers Susy has after three weeks.
After one week, Susy has 100+40 = 140 followers.
In the second week, Susy gains 40/2 = 20 new followers.
In the third week, Susy gains 20/2 = 10 new followers.
In total, Susy finishes the three weeks with 140+20+10 = 170 total followers.
STEP 2: Figure out how many followers Sarah has after three weeks.
After one week, Sarah has 50+90 = 140 followers.
After the second week, Sarah gains 90/3 = 30 followers.
After the third week, Sarah gains 30/3 = 10 followers.
So, Sarah finishes the three weeks with 140+30+10 = 180 total followers.
STEP 3: Figure out who has the most total followers.
Thus, Sarah is the girl with the most total followers with a total of 180.
Answer: 180

**[Question]**: Sam bought a dozen boxes, each with 30 highlighter pens inside, for $10 each box. He rearranged five of these boxes into packages of six highlighters each and sold them for $3 per package. He sold the rest of the highlighters separately at the rate of three pens for $2. How much profit did he make in total, in dollars?
**[Solution]**:
Let's think step by step.
STEP 1: Calculate the total cost of buying the boxes.
Sam bought a dozen boxes, which means he bought 12 boxes in total.
Each box cost $10, so the total cost of buying the boxes is 12 _ $10 = $120.
STEP 2: Calculate the total number of highlighters Sam bought.
Each box contains 30 highlighter pens, so the total number of highlighters Sam bought is 12 _ 30 = 360 highlighters.
STEP 3: Calculate the total revenue from selling the packages.
Sam rearranged five boxes into packages of six highlighters each, so he made 5 _ 30 / 6 = 25 packages.
He sold each package for $3, so the total revenue from selling the packages is 25 _ $3 = $75.
STEP 4: Calculate the total revenue from selling the highlighters separately.
Sam sold the rest of the highlighters, which is 360 - (5 _ 30) = 210 highlighters, separately.
He sold three highlighters for $2, so the total revenue from selling the highlighters separately is (210/3) _ $2 = $140.
STEP 5: Calculate the total revenue.
The total revenue is the sum of the revenue from selling the packages and the revenue from selling the highlighters separately, which is $75 + $140 = $215.
STEP 6: Calculate the profit.
The profit is the total revenue minus the total cost, which is $215 - $120 = $95.
Answer: $95

**[Question]**: In a certain school, 2/3 of the male students like to play basketball, but only 1/5 of the female students like to play basketball. What percent of the population of the school do not like to play basketball if the ratio of the male to female students is 3:2 and there are 1000 students?
**[Solution]**:
Let's think step by step.
STEP 1: Figure out the number of male and female students in the school.
The students are divided into 3 + 2 = 5 parts where 3 parts are for males and 2 parts are for females.
Each part represents 1000/5 = 200 students.
So, there are 3 x 200 = 600 males.
And there are 2 x 200 = 400 females.
STEP 2: Figure out the number of males and females who like to play basketball.
2/3 of the male students like to play basketball. Hence, 600 x 2/3 = 400 males play basketball.
1/5 of the female students like to play basketball. Hence, 400 x 1/5 = 80 females play basketball.
STEP 3: Figure out how many people do not like to play basketball.
A total of 400 + 80 = 480 students play basketball.
Therefore, 1000 - 480 = 520 do not like to play basketball.
STEP 4: Calculate the percentage of the population that do not like to play basketball.
The percentage of the school that do not like to play basketball is 520/1000 \* 100 = 52
Answer: 52

---

**[Question]**: Angelo and Melanie want to plan how many hours over the next week they should study together for their test next week. They have 2 chapters of their textbook to study and 4 worksheets to memorize. They figure out that they should dedicate 3 hours to each chapter of their textbook and 1.5 hours for each worksheet. If they plan to study no more than 4 hours each day, how many days should they plan to study total over the next week if they take a 10-minute break every hour, include 3 10-minute snack breaks each day, and 30 minutes for lunch each day?
**[Solution]**:
Let's think step by step.
First, calculate the total time they need to study the textbook and worksheets. They need 3 hours for each of the 2 chapters, which is 3*2=6 hours. They also need 1.5 hours for each of the 4 worksheets, which is 1.5*4=6 hours. So, they need a total of 6+6=12 hours to study.
Next, calculate the total break time each day. They take a 10-minute break every hour, which is 10*4=40 minutes. They also take 3 10-minute snack breaks, which is 3*10=30 minutes. Plus, they take 30 minutes for lunch. So, they take a total of 40+30+30=100 minutes of breaks each day. Convert this to hours by dividing by 60, which is 100/60=1.67 hours.
Subtract the break time from the total hours they can study each day to find out how many hours they can actually study each day. They can study 4 hours each day, but they take 1.67 hours of breaks, so they can actually study 4-1.67=2.33 hours each day.
Finally, divide the total hours they need to study by the hours they can actually study each day to find out how many days they need to study. They need to study 12 hours total and can study 2.33 hours each day, so they need to study 12/2.33=5.15 days. Since they can't study for a fraction of a day, they should plan to study for 6 days.
Answer: 6

**[Question]**: Mark's basketball team scores 25 2 pointers, 8 3 pointers and 10 free throws. Their opponents score double the 2 pointers but half the 3 pointers and free throws. What's the total number of points scored by both teams added together?
**[Solution]**:
Let's think step by step.
First, calculate the total points scored by Mark's team. A 2 pointer is worth 2 points, a 3 pointer is worth 3 points and a free throw is worth 1 point. So Mark's team scores 25 _ 2 + 8 _ 3 + 10 _ 1 = 50 + 24 + 10 = 84 points.
Next, calculate the total points scored by their opponents. They score double the 2 pointers, so that's 25 _ 2 _ 2 = 100 points. They score half the 3 pointers, so that's 8 _ 3 / 2 = 12 points. They also score half the free throws, so that's 10 \* 1 / 2 = 5 points. So their opponents score 100 + 12 + 5 = 117 points.
Finally, add the points scored by both teams to find the total: 84 + 117 = 201 points.
Answer: 201

**[Question]**: Bella has two times as many marbles as frisbees. She also has 20 more frisbees than deck cards. If she buys 2/5 times more of each item, what would be the total number of the items she will have if she currently has 60 marbles?
**[Solution]**:
Let's think step by step.
First, we know that Bella has two times as many marbles as frisbees. So if she has 60 marbles, she has 60/2 = 30 frisbees.
Next, we know that Bella has 20 more frisbees than deck cards. So she has 30 - 20 = 10 deck cards.
So currently, Bella has 60 marbles + 30 frisbees + 10 deck cards = 100 items.
If Bella buys 2/5 times more of each item, she will have 2/5 _ 60 = 24 more marbles, 2/5 _ 30 = 12 more frisbees, and 2/5 \* 10 = 4 more deck cards.
So in total, Bella will have 100 + 24 + 12 + 4 = 140 items.
Answer: 140

**[Question]**: A group of 4 fruit baskets contains 9 apples, 15 oranges, and 14 bananas in the first three baskets and 2 less of each fruit in the fourth basket. How many fruits are there?
**[Solution]**:
Let's think step by step.
First, we need to find out how many fruits are in the first three baskets. In each basket, there are 9 apples, 15 oranges, and 14 bananas. So, in total, there are 9+15+14 = 38 fruits in each basket. Since there are three such baskets, there are 3\*38 = 114 fruits in the first three baskets.
Next, we need to find out how many fruits are in the fourth basket. We know that there are 2 less of each fruit in the fourth basket. So, there are 9-2 = 7 apples, 15-2 = 13 oranges, and 14-2 = 12 bananas in the fourth basket. In total, there are 7+13+12 = 32 fruits in the fourth basket.
Finally, to find out how many fruits are there in total, we need to add the number of fruits in the first three baskets and the number of fruits in the fourth basket. So, there are 114+32 = 146 fruits in total.
Answer: 146

**[Question]**: You can buy 4 apples or 1 watermelon for the same price. You bought 36 fruits evenly split between oranges, apples and watermelons, and the price of 1 orange is $0.50. How much does 1 apple cost if your total bill was $66?
**[Solution]**:
Let's think step by step.
First, since the fruits are evenly split, it means you bought 12 of each fruit (12 oranges, 12 apples, and 12 watermelons).
Next, we know that the price of 1 orange is $0.50. So, the total cost for the oranges is 12 \* $0.50 = $6.
We also know that the total bill was $66. So, the cost for the apples and watermelons is $66 - $6 = $60.
Since 4 apples cost the same as 1 watermelon, it means that 12 apples cost the same as 3 watermelons. Therefore, the cost for 12 apples and 12 watermelons (which is 15 fruits in total) is $60.
So, the cost for 1 fruit (either an apple or a watermelon) is $60 / 15 = $4.
Therefore, since 4 apples cost $4, 1 apple costs $4 / 4 = $1
Answer: 1

**[Question]**: Susy goes to a large school with 800 students, while Sarah goes to a smaller school with only 300 students. At the start of the school year, Susy had 100 social media followers. She gained 40 new followers in the first week of the school year, half that in the second week, and half of that in the third week. Sarah only had 50 social media followers at the start of the year, but she gained 90 new followers the first week, a third of that in the second week, and a third of that in the third week. After three weeks, how many social media followers did the girl with the most total followers have?
**[Solution]**:
Let's think step by step.
In the first week, Susy gained 40 new followers, so she had 100 + 40 = 140 followers.
In the second week, she gained half of 40, which is 40 / 2 = 20 new followers, so she had 140 + 20 = 160 followers.
In the third week, she gained half of 20, which is 20 / 2 = 10 new followers, so she had 160 + 10 = 170 followers.
On the other hand, Sarah gained 90 new followers in the first week, so she had 50 + 90 = 140 followers.
In the second week, she gained a third of 90, which is 90 / 3 = 30 new followers, so she had 140 + 30 = 170 followers.
In the third week, she gained a third of 30, which is 30 / 3 = 10 new followers, so she had 170 + 10 = 180 followers.
Therefore, the girl with the most total followers after three weeks is Sarah, with 180 followers.
Answer: 180

**[Question]**: Sam bought a dozen boxes, each with 30 highlighter pens inside, for $10 each box. He rearranged five of these boxes into packages of six highlighters each and sold them for $3 per package. He sold the rest of the highlighters separately at the rate of three pens for $2. How much profit did he make in total, in dollars?
**[Solution]**:
Let's think step by step.
First, we calculate the total cost of the boxes. Sam bought a dozen boxes, which is 12 boxes, at $10 each. So, the total cost is 12 _ $10 = $20.
Next, we calculate how many highlighters Sam has in total. Each box has 30 highlighters, so 12 boxes have 12 _ 30 = 360 highlighters.
Then, we calculate how many packages of six highlighters Sam made. He rearranged five boxes into packages of six highlighters each. So, he made 5 _ 30 / 6 = 25 packages.
We calculate how much money Sam made from selling these packages. He sold them for $3 each, so he made 25 _ $3 = $75.
Next, we calculate how many highlighters Sam sold separately. He sold the rest of the highlighters separately, which is 360 - 5 _ 30 = 210 highlighters.
We calculate how much money Sam made from selling these highlighters. He sold them at the rate of three pens for $2, so he made 210 / 3 _ $2 = $140.
Finally, we calculate Sam's profit. His profit is the money he made minus the cost, which is $75 + $140 - $120 = $95. So, Sam made a profit of $95
Answer: 95

**[Question]**: In a certain school, 2/3 of the male students like to play basketball, but only 1/5 of the female students like to play basketball. What percent of the population of the school do not like to play basketball if the ratio of the male to female students is 3:2 and there are 1000 students?
**[Solution]**:
Let's think step by step.
First, let's find out how many male and female students there are in the school. The ratio of male to female students is 3:2, which means for every 3 male students, there are 2 female students.
So, out of 5 parts (3+2), 3 parts are male and 2 parts are female.
Therefore, the number of male students is (3/5)*1000 = 600 and the number of female students is (2/5)*1000 = 400.
Next, let's find out how many students like to play basketball.
2/3 of the male students like to play basketball, so (2/3)*600 = 400 male students like to play basketball.
1/5 of the female students like to play basketball, so (1/5)*400 = 80 female students like to play basketball.
So, a total of 400+80 = 480 students like to play basketball.
Therefore, the number of students who do not like to play basketball is 1000 - 480 = 520.
So, the percentage of students who do not like to play basketball is (520/1000)\*100 = 52%.
Answer: 52

## Complex CoT w/ `AlignedCoT` exemplars for SVAMP, AddSub, and SingleEQ

**[Question]**: Adam bought 9.0 packages of cat food and 7.0 packages of dog food. Each package of cat food contained 10.0 cans, and each package of dog food contained 5.0 cans. How many more cans of cat food than dog food did Adam buy?
**[Solution]**:
Let's think step by step.
Adam bought 9.0 packages of cat food, and each package contained 10.0 cans, so he bought a total of 9.0 _ 10.0 = 90.0 cans of cat food.
Adam also bought 7.0 packages of dog food, and each package contained 5.0 cans, so he bought a total of 7.0 _ 5.0 = 35.0 cans of dog food.
Therefore, Adam bought 90.0 - 35.0 = 55.0 more cans of cat food than dog food.
Answer: 55.0

**[Question]**: In a bag there are 13.0 red marbles, 5.0 blue marbles, and 7.0 green marbles. What percent of the marbles are green?
**[Solution]**:
Let's think step by step.
To find the percentage of green marbles, we need to divide the number of green marbles by the total number of marbles and then multiply by 100.
The total number of marbles is 13.0 + 5.0 + 7.0 = 25.0
The number of green marbles is 7.0
So, the percentage of green marbles is (7.0/25.0) \* 100 = 28%
Answer: 28

**[Question]**: Mika had 20.0 stickers. She bought 26.0 stickers from a store in the mall and got 20.0 stickers for her birthday. Then Mika gave 6.0 of the stickers to her sister and used 58.0 to decorate a greeting card. How many stickers does Mika have left?
**[Solution]**:
Let's think step by step.
Mika starts with 20.0 stickers.
She buys 26.0 stickers, so she now has 20.0 + 26.0 = 46.0 stickers.
She also receives 20.0 stickers for her birthday, so she now has 46.0 + 20.0 = 66.0 stickers.
Mika gives 6.0 stickers to her sister, so she now has 66.0 - 6.0 = 60.0 stickers.
She uses 58.0 stickers to decorate a greeting card, so she now has 60.0 - 58.0 = 2.0 stickers left.
Answer: 2.0

**[Question]**: Luke had 20.0 stickers. He bought 12.0 stickers from a store in the mall and got 20.0 stickers for his birthday. Then Luke gave 5.0 of the stickers to his sister and used 8.0 to decorate a greeting card. How many stickers does Luke have left?
**[Solution]**:
Let's think step by step.
Luke started with 20.0 stickers.
He bought 12.0 stickers, so he now has 20.0 + 12.0 = 32.0 stickers.
He also received 20.0 stickers for his birthday, so he now has 32.0 + 20.0 = 52.0 stickers.
He gave 5.0 stickers to his sister, so he now has 52.0 - 5.0 = 47.0 stickers.
He used 8.0 stickers to decorate a greeting card, so he now has 47.0 - 8.0 = 39.0 stickers left.
Answer: 39.0

**[Question]**: How many yards of material from a 24.0 yard length of cloth remains after 3.0 pieces each 3.5 yards long and 5.0 pieces each 2.25 long are removed?
**[Solution]**:
Let's think step by step.
The total length of cloth is 24.0 yards.
3 pieces of cloth, each 3.5 yards long, are removed. So, 3 x 3.5 = 10.5 yards of cloth are removed.
5 pieces of cloth, each 2.25 yards long, are removed. So, 5 x 2.25 = 11.25 yards of cloth are removed.
Therefore, a total of 10.5 + 11.25 = 21.75 yards of cloth are removed.
The remaining length of cloth is 24.0 - 21.75 = 2.25 yards.
Answer: 2.25

**[Question]**: If Bob can make 100.0 feet of rope in 2.0 hours and Tim can make 75.0 feet of rope in 2.0 hours, how many feet of rope can Bob and Tim working together make in 4.0 hours?
**[Solution]**:
Let's think step by step.
Bob can make 100.0 feet of rope in 2.0 hours, so his rate of production is 100.0 feet / 2.0 hours = 50.0 feet per hour.
Tim can make 75.0 feet of rope in 2.0 hours, so his rate of production is 75.0 feet / 2.0 hours = 37.5 feet per hour.
Working together, their combined rate of production is 50.0 feet per hour + 37.5 feet per hour = 87.5 feet per hour.
In 4.0 hours, they can make 87.5 feet per hour \* 4.0 hours = 350.0 feet of rope.
Answer: 350.0

**[Question]**: A neighborhood grocer sells a mix of chocolate and carob candy. The chocolate cost 2.7 dollars a pound and the carob costs 2.55 dollars a pound. If 20.0 pounds of the chocolate and 40.0 pounds of the carob candy are used, what is the cost per pound of the mixture in dollars?
**[Solution]**:
Let's think step by step.
To find the cost per pound of the mixture, we need to calculate the total cost of the chocolate and carob candy and then divide it by the total weight of the mixture.
The total cost of the chocolate candy is 20.0 pounds _ $2.7/pound = $54.
The total cost of the carob candy is 40.0 pounds _ $2.55/pound = $102.
The total weight of the mixture is 20.0 pounds + 40.0 pounds = 60.0 pounds.
Therefore, the cost per pound of the mixture is ($54 + $102) / 60.0 pounds = $156 / 60.0 pounds = $2.60/pound.
Answer: 2.60

**[Question]**: Tim got 3.0 nickels and 13.0 dimes for shining shoes, and in his tip jar found 7.0 dimes and 9.0 half - dollars. How much money did Tim get?
**[Solution]**:
Let's think step by step.
Tim got 3.0 nickels, which is equal to 3 _ $0.05 = $0.15.
Tim also got 13.0 dimes, which is equal to 13 _ $0.10 = $1.30.
In his tip jar, Tim found 7.0 dimes, which is equal to 7 _ $0.10 = $0.70.
Tim also found 9.0 half-dollars, which is equal to 9 _ $0.50 = $4.50.
Therefore, Tim got a total of $0.15 + $1.30 + $0.70 + $4.50 = $6.65.
Answer: 6.65

## CoT w/ `AlignedCoT` exemplars for AQUA

**[Question]**: John found that the average of 15 numbers is 40. If 10 is added to each number then the mean of the numbers is?
**[Options]**: A)50, B)45, C)65, D)78, E)64
**[Solution]**:
First, Let's find the sum of the 15 numbers.
Since the average of the 15 numbers is 40, the sum of the 15 numbers is 15 _ 40 = 600.
Next, let's add 10 to each number.
If we add 10 to each number, the sum of the numbers will increase by 10 _ 15 = 150.
Then, let's find the new average.
The new sum of the numbers is 600 + 150 = 750.
Since there are still 15 numbers, the new average is 750 / 15 = 50.
Therefore, the mean of the numbers after adding 10 to each number is 50.
Answer: A

**[Question]**: If a / b = 3/4 and 8a + 5b = 22,then find the value of a.
**[Options]**: A)1/2, B)3/2, C)5/2, D)4/2, E)7/2
**[Solution]**:
Let's think step by step.
First, let's solve the equation a/b = 3/4 for a. We can do this by cross-multiplying:
4a = 3b
Next, let's substitute this value of a into the second equation 8a + 5b = 22:
8(3b/4) + 5b = 22
Multiplying through by 4 to get rid of the fraction:
24b + 20b = 88
Combining like terms:
44b = 88
Dividing both sides by 44:
b = 2
Now, let's substitute this value of b back into the equation 4a = 3b:
4a = 3(2)
4a = 6
Dividing both sides by 4:
a = 6/4
Simplifying:
a = 3/2
Therefore, the value of a is 3/2.
Answer: B

## Style Conversion Prompt for GSM8K

The full set of prompts also includes prompts for AQUA (both CoT and Complex CoT variants), Penguins dataset (both CoT and Complex CoT variants), and the Style Conversion Prompt for GSM8K used in generating the GSM8K-Align dataset. These prompts follow similar patterns to the examples shown above, demonstrating the "native-style" formatting approach with clear step-by-step reasoning and consistent answer formatting.
