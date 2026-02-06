# Metacognitive Prompting Improves Understanding in Large Language Models

**Authors:** Yuqing Wang (Stanford University), Yun Zhao (Meta Platforms, Inc.)

**arXiv:** 2308.05342

# Abstract

In Large Language Models (LLMs), there have been consistent advancements in task-specific performance, largely influenced by effective prompt design. Recent advancements in prompting have enhanced reasoning in logic-intensive tasks for LLMs, yet the nuanced understanding abilities of these models, crucial for processing and interpreting complex information, remain underexplored. In this study, we introduce *Metacognitive Prompting* (MP), a strategy inspired by human introspective reasoning processes. Using MP, LLMs undergo a systematic series of structured, self-aware evaluations, drawing on both their vast inherent knowledge and new insights. We conduct extensive experiments on four prevalent LLMs: Llama2, PaLM2, GPT-3.5, and GPT-4, across ten natural language understanding (NLU) datasets from GLUE, SuperGLUE, BLUE, and LexGLUE benchmarks. Additionally, we compare our method with chain-of-thought prompting and its advanced versions. The results show that GPT-4 consistently excels across all tasks, while other models have shown significant progress in some tasks when used in conjunction with MP. Furthermore, MP consistently outperforms existing prompting methods in both general and domain-specific NLU tasks. This study underscores the potential to amplify the understanding abilities of LLMs and highlights the benefits of mirroring human introspective reasoning in NLU tasks. Our data and code are available at https://github.com/EternityYW/Metacognitive-Prompting.

# Introduction

Large Language Models (LLMs) have made significant advancements in natural language processing (NLP) in recent years [min2021recent; zhao2023survey; wang2023large]. However, as these models progress, simply increasing their scale does not necessarily enhance their understanding and reasoning capabilities [rae2021scaling]. Delving into the intricacies of prompt design has emerged as a promising approach; it not only rivals the benefits of extensive fine-tuning but also offers clear advantages in sample efficiency [liu2023pre; kojima2022large].

Many research efforts have extensively explored prompt design, particularly emphasizing the use of Chain-of-Thought (CoT) [wei2022chain] approaches to advance intermediate reasoning steps. This led to variants such as Least-to-Most [zhou2022least], Self-consistency [wang2022self], and Tree-of-Thoughts (ToT) [yao2023tree] techniques. These strategies are effective in designated contexts where the main objective centers around enhancing explicit reasoning capacities in areas like arithmetic, commonsense, and symbolic reasoning, guiding LLMs through a logical progression of thought. However, their effectiveness in deepening understanding is limited, as reasoning involves methodically connecting concepts, whereas understanding requires grasping underlying semantics and broader contextual meanings.

[IMAGE: human_LLM_metacognition.pdf - Alignment between human metacognitive processes and the stages of MP in LLMs.]

To bridge the gap in enhancing LLMs' understanding abilities, crucial for solving complex tasks, we propose Metacognitive Prompting (MP). This method is informed by the concept of metacognition, often defined as 'thinking about thinking'. Derived from cognitive psychology, metacognition relates to an individual's awareness and self-reflection on their cognitive processes. Our approach integrates key aspects of human metacognitive processes into LLMs. Figure 1 shows the parallels between human metacognitive stages and the operational steps of our method in LLMs. Rather than concentrating solely on the mechanics of "how" a response is produced, this method delves deeper into the rationale or "why" behind it. The method proceeds as follows: 1) the LLM interprets the provided text, a phase reminiscent of human comprehension; 2) the model then forms an initial judgment, mirroring the stage in which humans generate judgments based on information; 3) the LLM subjects its preliminary inference to critical evaluation, a step aligned with the self-reflection that humans engage in during cognitive processes; 4) after this introspective assessment, the model finalizes its decision and elucidates its reasoning, similar to human decision-making and rationalization; 5) finally, the LLM gauges its confidence in the outcomes, reflecting how humans evaluate the credibility of their judgments and explanations. This paradigm elevates the model's function beyond simple systematic reasoning, compelling it to participate in introspective evaluations that determine the depth and relevance of its responses.

We conducted experiments on ten NLU datasets from GLUE [wang2019glue], SuperGLUE [wang2019superglue], BLUE [peng2019transfer], and LexGLUE [chalkidis2022lexglue] benchmarks using several leading LLMs, including Llama2 [touvron2023llama], PaLM2 [anil2023palm], GPT-3.5, and GPT-4 [openai2023gpt4]. Our empirical evaluations underscore the superiority of MP over existing prompting strategies, including CoT and its variants. This work emphasizes the importance of incorporating human-inspired introspective reasoning into LLMs, shedding light on an approach that deepens their understanding abilities.

In summary, our contributions are threefold:

1.  We introduce *metacognitive prompting*, a novel prompting strategy for LLMs, inspired by human introspective reasoning. This approach formalizes the self-aware evaluation process within LLMs, highlighting the shift from mere task execution to more profound comprehension.

2.  Our comprehensive experiments on ten NLU datasets reveal that MP outperforms CoT and its variants in both zero-shot and few-shot learning settings. This underscores MP's effectiveness in enhancing the understanding abilities of LLMs.

3.  Through manual error and confidence analysis, we highlight specific understanding challenges in LLMs. We also illustrate future directions for incorporating human-inspired introspection into LLM comprehension, thereby contributing to enhanced model reliability.

# Related Work

Our proposal for metacognitive prompting is informed by several foundational trajectories: the evolving paradigms of prompting within LLMs, advancements in NLU in the broader NLP domain, and the intricate interplay between cognitive processes and NLU dynamics.

## Prompting Techniques in LLMs

Prompts are crucial for harnessing the vast capabilities of LLMs, guiding them to generate accurate outputs or perform specific tasks. Current research primarily focuses on enhancing the reasoning abilities of LLMs. Representative approaches include CoT [wei2022chain] and its variants like self-consistency [wang2022self], Least-to-Most [zhou2022least], ToT [yao2023tree], and Plan-and-Solve prompting [wang2023plan]. Additional methods are detailed in [qiao2022reasoning]. However, there still exists a significant gap in developing effective prompts to enhance NLU within LLMs. Inspired by human cognitive processes, we introduce MP, an approach that not only aims to bridge the understanding gap but also enhances deeper comprehension and reliability in model outputs.

[IMAGE: MP_illustration.pdf - Our proposed method, metacognitive prompting, emulates critical steps of human metacognition, consisting of five stages: 1) understanding the input text, 2) making a preliminary judgment, 3) critically evaluating this preliminary analysis, 4) reaching a final decision accompanied by an explanation of the reasoning, and 5) evaluating the confidence level in the entire process. By reflecting on human self-assessment, these stages guide the LLM, aiding in more accurate text interpretation and facilitating better judgment formation. The diagram features three columns, from left to right, representing the high-level metacognitive stages, specific metacognitive prompts fed into the LLM, and the LLM's corresponding outputs. Prompts in the middle column are collectively fed into the LLM as a single input during the experiments. The figure illustrates a sample question chosen from the Quora Question Pair (QQP) dataset in the GLUE benchmark.]

## Natural Language Understanding in NLP

NLU is a fundamental aspect of NLP, emphasizing a model's capacity to grasp the semantics and nuances of human language. Its applications span diverse domains such as question answering (QA) [namazifar2021language], text classification [wang2022integrating; wang2023prominet], and natural language inference (NLI) [nie2020can], as well as commercial tools like chatbots [ait2020kbot], voice assistants [bellegarda2013spoken], and machine translation. While LLMs have gained remarkable attention recently, with increased efforts dedicated to expanding NLU boundaries, the primary research emphasis has been on their reasoning abilities [huang2022towards], ethical use [weidinger2021ethical; zhuo2023exploring], and broad applications [zhao2021empirical; surameery2023use; wang2023empirical]. However, the inherent NLU competencies of LLMs have remained relatively inadequately explored. To address this gap, our study delves into the understanding abilities of various LLMs, employing effective prompting techniques.

## Cognitive Processes in NLU

The interplay between cognitive processes and NLU has always been a central consideration in computational linguistics [perinan2007cognitive; hausser2001foundations]. Cognitive processes, which encompass areas like attention, memory, reasoning, and problem-solving, govern how humans understand, produce, and engage with language in diverse scenarios. These processes heavily influence our linguistic abilities [allen1995natural; cambria2014jumping]. In the domain of NLU, incorporating cognitive insights may offer improvements in model comprehension. Recognizing this intrinsic connection, our work is inspired to employ a metacognition-based prompting technique, a method rooted in higher-order cognition that reflects on thinking and decision-making, to bolster the understanding capabilities of LLMs, thereby harmonizing traditional modeling techniques with cognitive nuances.

# Metacognitive Prompting

In the complex terrain of human cognition, our ability to introspect and regulate our thinking processes stands as a keystone for intricate problem-solving and decision-making. This high-level cognition underlies our proficiency in breaking down abstract concepts, critically evaluating scenarios, and fine-tuning our reasoning. The primary aim of this work is to equip LLMs with a process that simulates the self-reflective cognitive process. In doing so, we aim to improve LLMs' capabilities in interpreting and responding to NLU tasks.

We propose MP, which instills critical elements of human metacognition into LLMs. This approach involves five distinct stages: 1) the LLM begins by deciphering the input text to comprehend its context and meaning, mirroring the initial comprehension stage in human thought; 2) it then forms a preliminary interpretation of the text, a step that reflects judgment formation in humans; 3) subsequently, the LLM critically evaluates this initial judgment for accuracy, akin to the self-scrutiny humans apply during problem-solving; 4) after this evaluation, the LLM finalizes its decision and offers an explanation for its reasoning, aligning with the decision-making and rationalization phase in human cognition; 5) ultimately, the LLM assesses its confidence in the outcome of the entire process, similar to how humans gauge the certainty of their decisions and explanations. Figure 2 provides a schematic representation of our MP. It outlines the five sequential metacognitive stages, the specific prompts directed at the LLM, and corresponding model outputs.

In essence, MP introduces a structured approach that enables LLMs to process tasks, enhancing their contextual awareness and introspection in responses. By systematically guiding models through stages that emulate human cognitive processes, this method offers a fresh perspective on addressing complex natural language tasks. It reshapes our perception and utilization of LLMs' capabilities, ushering in a paradigm where models not only grasp the intricacies of given tasks but also critically evaluate and adjust their responses. This approach establishes a foundation for more effective and reliable interactions between users and LLMs, particularly benefiting those with limited LLM expertise, as it simplifies complex linguistic and cognitive processes into more manageable forms. Sample MP templates and exemplars are shown in Appendix.

# Experiments

We conduct experiments on ten diverse NLU datasets selected from GLUE [wang2019glue], SuperGLUE [wang2019superglue], BLUE [peng2019transfer], and LexGLUE [chalkidis2022lexglue] benchmarks. We evaluate the impact of MP in comparison with CoT and its variants, across four leading LLMs. We report the best result after multiple experimental iterations.

## Datasets

For our experiments, we use a broad set of datasets from the GLUE, SuperGLUE, BLUE, and LexGLUE benchmarks, encompassing both general NLU and domain-specific datasets in biomedicine and law. In general NLU, our selections include question paraphrase (QQP [shankar2017first]), question-answer entailment (QNLI [rajpurkar2016squad]), QA (BoolQ [clark2019boolq]), and word sense disambiguation (WiC [pilehvar2019wic]). For biomedical NLU, we select named entity recognition (BC5CDR-chem [li2016biocreative]), relation extraction (DDI [segura2013semeval]), and NLI (MedNLI [romanov2018lessons]). For legal NLU, we opt for multi-label text classification (EUR-LEX [chalkidis2021multieurlex], UNFAIR-ToS [lippi2019claudette]) and multi-class text classification (LEDGAR [tuggener2020ledgar]). These datasets pose diverse challenges to the understanding abilities of LLMs. Given the constraints of API costs, we randomly select 600 examples from the validation set of each dataset.

## Prompts

Our proposed MP is adaptable to both zero-shot and 5-shot settings. For each setting, we consider the following prompting baselines: (1) Zero-shot CoT [kojima2022large], which adds "*Let's think step by step*" to a basic query, and Plan-and-Solve (PS) prompting [wang2023plan], which appends "*Let's first understand the problem and devise a plan to solve the problem. Then, let's carry out the plan and solve the problem step by step*" to the end of a question, are included as zero-shot baselines. (2) Manual-CoT [wei2022chain] and self-consistency with CoT (CoT-SC) [wang2022self], the latter of which takes majority vote from 10 CoT samples, are considered as few-shot baselines. Exemplars for each dataset are hand-crafted.

## Large Language Models

In our evaluation, we consider four popular LLMs: the open-source model Llama-2-13b-chat [touvron2023llama] and the closed-source models PaLM-bison-chat [anil2023palm], GPT-3.5-turbo, and GPT-4 [openai2023gpt4]. Each model is employed using its corresponding API key. For all methods, we apply greedy decoding (i.e., temperature = 0) for response generation, except when applying CoT-SC (temperature = 0.7). Furthermore, we utilize zero-shot and 5-shot settings for each model, with exemplars for the 5-shot setting randomly selected from the training set. Each dataset has its unique set of exemplars, and the answers for these exemplars are obtained through human annotation.

# Results

In our empirical evaluations, we compare performance across all datasets and models, considering the various prompting methods used. We also investigate the efficacy of different prompting strategies, analyze errors associated with MP, and examine the relationship between confidence scores and predictive performance when MP is applied.

## Overall Performance Comparison

Table 2 presents a comprehensive performance comparison of our method against established zero-shot and few-shot methods on four LLMs across ten varied NLU datasets. Generally, 5-shot learning outperforms zero-shot learning across models, except for EUR-LEX and LEDGAR. The latter's performance dip may be attributable to their high-class counts and the limited example demonstrations, which can skew the models toward a narrow label set. Particularly, zero-shot MP outperforms M-CoT in some instances, suggesting that reduced manual effort can still effectively elicit deep understanding in LLMs, potentially inspiring the development of more efficient prompting methods. Furthermore, GPT-4 stands out, consistently scoring highest on all datasets by a significant margin. For zero-shot prompting, LLMs exhibit notably improved performance with MP, particularly for legal NLU tasks like EUR-LEX. Specifically, MP boosts ```latex $\mu$-F1 ``` by 15.0% to 26.9% over CoT and by 9.2% to 16.9% over PS on the EHR-LEX dataset. A similar trend is seen with 5-shot methods; for instance, on the same dataset, M-MP enhances ```latex $\mu$-F1 ``` by 10.6% to 19.4% over M-CoT and by 5.9% to 13.0% over CoT-SC. Overall, integrating MP yields substantial benefits for domain-specific NLU datasets in the fields of biomedicine and law across all models. It also provides a moderate yet consistent improvement in general NLU tasks.

## Prompting Strategy Comparison

We evaluate the performance of different prompting strategies under zero-shot and 5-shot learning settings across all models and datasets.

[IMAGE: 0S_prompting_average_performance.pdf and 5S_prompting_average_performance.pdf - Comparison of average performance for all prompting methods in both zero-shot and 5-shot learning scenarios across four LLMs. Performance metrics are averaged over all datasets, treating each dataset and metric with equal significance and assuming direct comparability. MP consistently surpasses other methods.]

In the model-level comparison, Figure 3 presents an aggregated view of the performance of each prompting method across all datasets for each model (top for zero-shot and bottom for 5-shot), assuming that datasets and evaluation metrics are equally significant and directly comparable. For the zero-shot learning setting, MP emerges as superior, illustrating a relative performance boost ranging from 4.8% to 6.4% over CoT and 2.8% to 4.1% over PS. Similarly, M-MP shows an average performance improvement from 4.5% to 6.0% over M-CoT and 2.2% to 3.5% over CoT-SC in the 5-shot learning setting. This enhanced performance can be attributed to the unique introspective strategy of MP, which facilitates a deeper understanding of tasks by prompting the model to critically evaluate, revisit its initial judgments, and refine its responses. When we shift focus to a data-level comparison, considering zero-shot learning results as an example, Table 3 provides an average performance over four LLMs for each dataset. The critical reassessment capabilities of MP particularly stand out in datasets like MedNLI, UNFAIR-ToS, and EUR-LEX, leading to marked improvements of 4.3%, 9.6%, and 12.4% over PS (enhanced version of zero-shot CoT), respectively. The consistent outstanding performance of MP underscores its potential in tasks demanding precision, discernment, and a comprehensive semantic grasp. Meanwhile, the self-assessment and iterative refinement embedded in MP give it an advantage in tasks requiring nuanced understanding and contextual depth.

## Error Analysis

MP has consistently demonstrated proficiency across a range of NLU tasks. However, upon manual inspection of its incorrect predictions, we identify two primary error types across all tasks (10 datasets) specifically associated with MP. First, 'Overthinking errors' (68.3%) are notably evident in straightforward datasets like QQP and BoolQ. In these situations, MP tends to over-complicate the task, diverging from the correct solution. Conversely, 'Overcorrection errors' (31.7%) predominantly appear in tasks demanding nuanced interpretation, such as WiC and DDI. This type of error appears obvious in the critical reassessment stage of MP, which strays excessively from an initially accurate interpretation.

[IMAGE: error1.pdf - Overthinking error in model response with MP.]

[IMAGE: error2.pdf - Overcorrection error in model response with MP.]

Figure 4 shows examples of both error types from the WiC dataset. In addition, we observe distinct error patterns in domain-specific tasks. In biomedical NLU tasks (3 datasets), MP predominantly encounters errors including 'Terminological misalignments' (48.6%), where the model inaccurately interprets specialized medical terms, and 'Clinical inference discrepancies' (51.4%), where the depth and interconnections of clinical data are not fully comprehended or are misapplied. In legal NLU tasks (3 datasets), the errors are often characterized as 'Statutory interpretation errors' (52.2%), reflecting challenges in deciphering the complex language and context of legal documents, and 'Jurisprudential analysis deviations' (47.8%), where the model diverges from accepted legal reasoning or misinterprets legal principles and precedents. Numbers in parentheses represent the approximate distributions of major error types within the subgroup. These error types, unique to the specific demands of biomedicine and law, highlight the need for tailored adjustments in MP's further application to these fields.

## Confidence Analysis

Assessing confidence and uncertainty within the MP framework is instrumental in gauging the reliability of predictions, particularly when models articulate their confidence levels. In our analysis, each model operating with MP is evaluated based on its verbalized confidence for every prediction across the datasets. Scores above 75% are classified as high confidence; any value below this threshold is considered low confidence. To illuminate this correlation, we employ a tailored confusion matrix uniquely adapted for this study. Within this matrix, the standard terminologies of 'True Positive', 'False Positive', 'True Negative', and 'False Negative' are redefined as follows:

**True Positive (TP):** Represents instances where the model, using MP, expressed high confidence and produced a correct answer. These account for 55.6%.

**False Positives (FP):** Denotes cases where the model exhibited high confidence but gave an incorrect prediction. These amount to 32.5%.

**True Negatives (TN):** Refers to instances where the model signaled low confidence and its response was indeed incorrect. These stand at 6.8%.

**False Negatives (FN):** Highlights cases where the model indicated low confidence but, surprisingly, delivered a correct answer. These tally to 5.1%.

[IMAGE: mp_confidence_analysis.pdf - The relationship between correctness and confidence levels under MP, averaged over all datasets and models.]

These metrics are aggregated across all models and datasets and then averaged to provide a holistic overview of the interplay between model confidence using MP and prediction accuracy. As depicted in Figure 5, MP typically offers an accurate reflection of its own performance, as evidenced by the high TP rate. The relatively low TN rate underscores its reliable self-assessment, suggesting that when MP has low confidence, it is predominantly correct about its inaccuracy. However, the considerable FP rate indicates that, while MP is usually right when confident, it sometimes makes mistakes despite its high confidence. Moreover, the FN rate identifies areas where MP might improve its self-awareness, as there are moments when it might underestimate its accuracy. In summary, the high TP rate and low FN values underscore MP's self-awareness, but the FP and TN values point to potential improvements. Addressing these areas by emphasizing confidence calibration in future iterations of MP could better align its introspective evaluations with its actual performance abilities.

# Limitations

While our proposed MP demonstrates potential by integrating introspective features reminiscent of human cognition into LLMs to enhance their understanding capacities, our study does have its limitations. First, designing the prompts requires manual effort to guide the LLMs through metacognitive processes. Second, we evaluate the effectiveness of MP using a selection of datasets and models, which may limit the broader applicability of our findings. Furthermore, although the verbalized confidence of LLMs offers a window into their perceived certainty levels, it might not serve as the definitive method for comprehensively gauging their true confidence. A hybrid approach, such as combining verbalization with self-consistency checks, could offer a more robust method for confidence calibration. Additionally, our study does not extensively address vital ethical and legal concerns, such as potential biases, privacy implications, and fairness challenges. Future research on MP will address these dimensions to ensure the responsible and holistic application of LLMs in different areas.

# Discussion

In this study, we present MP to infuse introspective features that mirror human cognition into LLMs. The MP process involves five distinct stages: it starts by comprehending the input text, then moves to formulate an initial judgment. Next, it critically reevaluates this initial impression, settles on a decision while explaining its rationale, and finally gauges its confidence in the decisions made. We conduct experiments on a broad range of datasets from several popular NLU benchmarks and evaluate several prominent LLMs with different prompting methods. The results underscore the potential of our method, demonstrating advantages over existing prompting methods. Through our analysis, specific error patterns associated with MP are identified, highlighting nuances in comprehension and judgment stages that warrant further refinement. While MP provides a structured pathway for models to introspect, it follows predefined stages, lacking adaptability based on real-time feedback. The five-stage design of MP, although foundational, suggests room for more intricate frameworks that might emulate human-like cognitive feedback loops more authentically.

Looking forward, several areas warrant further exploration. First, we plan to apply MP more broadly, particularly to detail-oriented areas such as mental health support, as well as to complex reasoning tasks like arithmetic and commonsense reasoning. Refining MP could elicit more detailed introspective responses from LLMs. Moreover, reliance on verbalized confidence can be augmented by integrating other methods for a more comprehensive assessment. Additionally, the broader implications of introducing introspective LLMs, particularly regarding biases and the reliability of outputs, require in-depth examination. In essence, our initial venture with MP lays a solid foundation, but significant opportunities remain to draw closer parallels between introspection in LLMs and natural human introspection, which can lead to more explainable and accountable AI systems.

# Ethics Statement

There are no ethics-related issues in this paper. The data and resources utilized in this work are open-source and widely used in many existing studies.

# Sample Prompts

This section includes some examples of MP under zero-shot and few-shot settings.

### Example 1: WiC

- *Zero-shot MP Template*: In two sentences, sentence 1: "[sentence_1]" and sentence 2: "[sentence_2]", both contain the target word "[word]". Determine if the target word is used with the same meaning in both sentences. As you perform this task, follow these steps:

  1.  Understand the context and meaning of the target word in both sentences.

  2.  Make a preliminary judgment on whether the target word has the same meaning in both sentences.

  3.  Critically assess your preliminary analysis. If you are unsure about your initial judgment, reassess it.

  4.  Confirm your final answer and explain the reasoning behind your decision.

  5.  Evaluate your confidence (0-100%) in your analysis and provide an explanation for this confidence level.

  Provide the answer in your final response as "The target word has the same meaning in both sentences: {} (True / False)".

- *Few-shot MP Demonstration*:
  **Q:** In two sentences, sentence 1: "The washing machine won't go unless it's plugged in." and sentence 2: "The day went well until I got your call.", both contain the target word "go". Determine if the target word is used with the same meaning in both sentences.
  **A:**

  1.  In sentence 1, "go" refers to the operation of the washing machine. In sentence 2, "went" (a form of "go") refers to the progression of the day.

  2.  Initially, "go" in the first sentence seems to be about mechanical operation, while in the second, it's about the passage of time or events.

  3.  Reflecting further, the contexts clearly differentiate the meanings: one deals with machinery and its function, the other deals with the experience of a day.

  4.  The target word "go" does not have the same meaning in both sentences. In the first, it pertains to operation, and in the second, to the progression of events.

  5.  I am 83% confident in this analysis. The term "go" is used in different contexts in the two sentences, leading to different meanings.

  The target word has the same meaning in both sentences: False.

### Example 2: QNLI

- *Zero-shot MP Template*: For the question: "[question]" and statement: "[sentence]", determine if the statement provides the answer to the question. If the statement contains the answer to the question, the status is entailment. If it does not, the status is not_entailment. As you perform this task, follow these steps:

  1.  Clarify your understanding of the question and the context sentence.

  2.  Make a preliminary identification of whether the context sentence contains the answer to the question.

  3.  Critically assess your preliminary analysis. If you feel unsure about your initial entailment classification, try to reassess it.

  4.  Confirm your final answer and explain the reasoning behind your choice.

  5.  Evaluate your confidence (0-100%) in your analysis and provide an explanation for this confidence level.

  Provide the answer in your final response as "The status is (entailment / not_entailment)".

- *Few-shot MP Demonstration*:
  **Q:** For the question: "Who was the first President to address the NAACP?" and statement: "In front of 10,000 people at the Lincoln Memorial, the president left no doubt where he stood on civil rights.", determine if the statement provides the answer to the question. If the statement contains the answer to the question, the status is entailment. If it does not, the status is not_entailment.
  **A:**

  1.  The question is asking about the identity of the first President to address the NAACP. The statement describes a scenario where a president addressed a large audience at the Lincoln Memorial and took a clear stance on civil rights.

  2.  The initial assessment is that the status is not_entailment.

  3.  Upon reassessment, the statement does not specifically mention the NAACP or provide information about which president is being referred to. While the context does pertain to civil rights, it does not necessarily correlate with the specific act of addressing the NAACP.

  4.  The statement does not provide a clear answer to the question. The context discusses a president's stance on civil rights in front of a large audience at the Lincoln Memorial, but it does not specify which president this was or confirm that this president was the first to address the NAACP.

  5.  I am 85% confident in this analysis. The context lacks specifics about which president is being discussed and does not directly address the NAACP aspect of the question.

  The status is not_entailment.

### Example 3: DDI

- *Zero-shot MP Template*: Given the context sentence "[sentence]", identify the relationship between the pharmacological substances "[item_1]" and "[item_2]" within the sentence. Classify the relationship under one of these categories: Advice, Effect, Mechanism, or Int. As you perform this task, follow these steps:

  1.  Understand the context and the meanings of the two substances, along with their potential interactions.

  2.  Make a preliminary identification of the relationship between two substances.

  3.  Critically assess your preliminary analysis. If you feel unsure about your initial relationship, try to reassess it.

  4.  Confirm your final answer and explain the reasoning behind your decision.

  5.  Evaluate your confidence (0-100%) in your analysis and provide an explanation for this confidence level.

  Provide the answer in your final response as "The relationship between two substances is (Advice / Effect / Mechanism / Int)".

- *Few-shot MP Demonstration*:
  **Q:** Given the context sentence "Impaired renal function has been described in bone marrow transplant patients who were conditioned with high-dose intravenous melphalan and who subsequently received cyclosporin to prevent graft-versus-host disease.", identify the relationship between the pharmacological substances "melphalan" and "cyclosporin" within the sentence. Classify the relationship under one of these categories: Advice, Effect, Mechanism, or Int.
  **A:**

  1.  The sentence involves bone marrow transplant patients who were treated with high-dose intravenous melphalan and subsequently received cyclosporin. Melphalan is a chemotherapy drug, and cyclosporin is an immunosuppressive agent. The potential interaction seems related to the effects these drugs have when used together.

  2.  The relationship between melphalan and cyclosporin appears to be one of a combined effect where their concurrent use impacts renal function. This suggests the category "Effect".

  3.  Upon reassessment, the relationship still aligns best with the "Effect" category, as the sentence directly connects impaired renal function to the use of both drugs in a sequential treatment regime.

  4.  The relationship is classified as "Effect". The sentence describes a specific medical consequence (impaired renal function) resulting from the combined use of melphalan and cyclosporin in a specific patient group (bone marrow transplant patients), indicating a direct effect relationship between the two substances.

  5.  I am 90% confident in this analysis. The context provides a clear connection between the two drugs and a specific health outcome, making "Effect" the most suitable category.

  The relationship between two substances is Effect.
