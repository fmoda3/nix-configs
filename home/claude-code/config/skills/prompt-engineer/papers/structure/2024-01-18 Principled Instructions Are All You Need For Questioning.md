# Abstract

This paper introduces 26 guiding principles designed to streamline the process of querying and prompting large language models. Our goal is to simplify the underlying concepts of formulating questions for various scales of large language models, examining their abilities, and enhancing user comprehension on the behaviors of different scales of large language models when feeding into different prompts. Extensive experiments are conducted on LLaMA-1/2 (7B, 13B and 70B), GPT-3.5/4 to verify the effectiveness of the proposed principles on instructions and prompts design. We hope that this work can provide a better guide for researchers working on the prompting of large language models. Project page is available at <https://github.com/VILA-Lab/ATLAS>.

# Introduction

> Prompt engineering is the art of communicating with a generative large language model.

Large language models (LLMs) like ChatGPT [openai2023gpt4] have shown impressive abilities in various domains and tasks, such as answering questions [kamalloo2023evaluating], mathematical reasoning [imani2023mathprompter], code generating [li2022competition; li2023starcoder], etc. However, their application and usage, especially on designing the optimal instructions or prompts, can sometimes be unclear to the common users. In this work, we aim to reveal these mysteries for developers or general users when inquiring and interacting with LLMs, and further enhance the quality of the responses from the pretrained LLMs by simply curating better prompts.


[FIGURE: Illustration example of prompts and corresponding responses before and after applying principles. Left is the original promotes and their responses from GPT-4, right is the principled prompts and the associated responses. Principles 5 and 6 are utilized.]


Given that directly fine-tuning LLMs for particular tasks tends to be impractical or unattainable for the majority of users and developers due to inefficiency, the research community has turned its attention to the optimization of prompts. The technique of prompt engineering, which entails the crafting of precise, task-specific instructions in natural language, either manually or through automated means, and the careful selection of representative examples for inclusion in the prompt, has become a central area of investigation for LLMs. Despite these dedicated efforts, the task of reliably guiding LLMs to produce specific responses and making full use of the capability of pretrained LLMs continues to pose a considerable challenge.

In this work, we present comprehensive principled instructions to improve the quality of prompts for LLMs. Specifically, we investigate a wide range of behaviors when feeding into different types and formulations of prompts, such as integrating the intended audience in the prompt, e.g., add "*the audience is an expert in the field*", or "*the audience is the 5-year-old child*", as well as other multiple aspects of the characteristics of LLMs. Our findings indicate that larger models possess a considerable capacity for simulation. The more precise the task or directive provided, the more effectively the model performs, aligning its responses more closely with our expectations. This suggests that LLMs do not merely memorize training data but are capable of adapting this information to suit varying prompts, even when the core inquiries remain constant. Therefore, it proves beneficial to assign a specific role to LLMs as a means to elicit outputs that better match our intended results.

We elaborate the principled instructions for LLM prompting, provide further motivation, and detail several specific designing principles in Section [3](#main_principle). In Section [4](#exp) we show experimentally that the proposed principles can produce higher quality, more concise, factual and less complicated or intricate responses than standard prompts for LLMs. Specifically, with the manually-designed ATLAS benchmark, which includes multiple questions for each principle, the specialized prompts we introduced have enhanced both the quality and accuracy of the LLM responses by an average of 57.7% and 36.4%, respectively, when applied to GPT-4. Furthermore, the improvements are more pronounced with the increase in model size, for example, the performance gains when moving from LLaMA-2-7B to GPT-4 exceed 20%.

# Related Work

The evolution of large language models (LLMs) has been pivotal in advancing natural language processing (NLP). This section reviews key developments in LLMs, providing a foundation for the current study. Beginning with Google's BERT [DBLP:journals/corr/abs-1810-04805] revolutionized context understanding through its bidirectional training approach, while T5 [DBLP:journals/corr/abs-1910-10683] further advanced the field by unifying various NLP tasks into a single framework. Concurrently, GPT-1 [radford2018improving] introduced a pioneering model leveraging transformer architectures for unsupervised learning. This was followed by its successor, GPT-2 [radford2019language] which significantly expanded its parameter count to 1.5 billion, demonstrating remarkable capabilities in text generation. Then, GPT-3 [brown2020language] marked a substantial leap in scale and capability, boasting 175 billion parameters and showcasing proficiency across a wide range of language tasks.

Regarding other recently proposed LLMs, Gopher [DBLP:journals/corr/abs-2112-11446], not only advanced language processing capabilities with its 280-billion parameter model but also brought ethical considerations to the forefront. Meta's LLaMA series [touvron2023llama; touvron2023llama2] highlighted the importance of efficiency, suggesting powerful performance with fewer resources, a concept also advocated by Chinchilla [hoffmann2022training], which proposed that smaller, optimally trained models could achieve exceptional results. The latest in this series of innovations is Mistral [jiang2023mistral] excels in efficiency and performance, outperforming larger models. The most recent milestones in this trajectory are OpenAI's GPT-4 [openai2023gpt4] and Google's Gemini family [geminiteam2023gemini]. They represent another significant advancement in the field with their enhanced understanding and generative capabilities, setting new benchmarks for the application of LLMs in various domains.

Prompting [shin2020autoprompt; li2023guiding; white2023prompt; zhou2023leasttomost; pan2023plum], as a distinct aspect of interacting with LLMs and its simplicity with no need to fine-tune the model, has evolved into a nuanced field of study, highlighting the intricate relationship between user inputs and LLM responses. Early explorations, such as those by [shin2020autoprompt], delved into how varying prompt designs could dramatically influence the performance and outputs of language models, marking the birth of *prompt engineering*. This area rapidly expanded, uncovering the critical role of prompts in few-shot and zero-shot learning scenarios, exemplified by [brown2020language] work with GPT-3, where strategically crafted prompts enabled the model to perform tasks with minimal prior examples. Beyond mere task instruction, recent studies have shifted towards understanding the semantic and contextual nuances in prompts, examining how subtle changes can lead to significantly different responses from the LLM.

*Ask-Me-Anything* [arora2022ask] prompting introduced focusing on using multiple imperfect prompts and aggregating them to improve model performance, particularly in question-answering formats. Another one, *Chain-of-Thought* method [wei2023chainofthought], where the model generates a series of intermediate reasoning steps to improve performance on complex tasks. Also, *least-to-most prompting* [zhou2023leasttomost] a novel strategy to break down complex problems into simpler subproblems, significantly enhancing the model's capability to tackle more challenging problems than those presented in the prompts. The effectiveness of explanation was explored [lampinen-etal-2022-language], finding that explanations can enhance LLM's learning capabilities on complex tasks. Furthermore, a catalog of prompt engineering techniques was examined with ChatGPT [white2023prompt], emphasizing the importance of prompt engineering in enhancing LLM applications in software development and education. It also highlighted that effective prompt design is crucial in improving LLM performance, particularly in coding practices and learning experiences. Lastly, *Directional Stimulus Prompting* [li2023guiding] presents a novel framework that uses a tunable policy model to generate auxiliary prompts, guiding LLMs towards specific desired outcomes. This diversity in prompting strategies underscores the rapidly evolving landscape of LLMs, offering multiple directions to harness their capabilities more effectively.

# Principles

## Motivation

Since the quality of the responses generated by a pretrained and aligned LLM is directly relevant to the quality of the prompts or instructions provided by the users, it is essential to craft prompts that the LLM can comprehend and respond to effectively. The prompts delivered to an LLM serve as a way to program the interaction between a user and the LLM, enhancing its ability to address a diverse range of tasks. The primary focus of this work is on the methodology of crafting and customizing prompts to enhance output quality. This necessitates a comprehensive grasp of the functioning and behaviors of LLMs, their underlying mechanisms, and the principles governing their responses. In this work, we achieve this goal through elaborating 26 principles for comprehensive prompts in different scenarios and circumstances, examples are shown in Fig. [1](#overview_examples).

## Overview

The overview of principles is presented in Table [\[tab:principles\]](#tab:principles). According to their unique nature, we group them into five categories as in Table [\[tab:categories\]](#tab:categories): (1) Prompt Structure and Clarity, e.g., *integrate the intended audience in the prompt such as the audience is an expert in the field*; (2) Specificity and Information, e.g., *Add to your prompt the following phrase "Ensure that your answer is unbiased and does not rely on stereotypes."*; (3) User Interaction and Engagement, e.g., *Allow the model to elicit precise details and requirements from you by asking you questions until he has enough information to provide the needed output "From now on, I would like you to ask me questions to\...".* (4) Content and Language Style, e.g., *No need to be polite with LLM so there is no need to add phrases like "please", "if you don't mind", "thank you", "I would like to", etc., and get straight to the point*; (5) Complex Tasks and Coding Prompts, e.g., *Break down complex tasks into a sequence of simpler prompts in an interactive conversation.*


+ + + +
| **#Principle** | **Prompt Principle for Instructions**                                                                                                                                                    |   |
+:==============:+:=========================================================================================================================================================================================+:==+
| 1              | |   |
|                |   If you prefer more concise answers, no need to be polite with LLM so there is no need to add phrases like                                                                              |   |
|                |   "please", "if you don't mind", "thank you", "I would like to", etc., and get straight to the point.                                                                                    |   |
|                | |   |
+ + + +
| 2              | Integrate the intended audience in the prompt, e.g., the audience is an expert in the field.                                                                                             |   |
+ + + +
| 3              | Break down complex tasks into a sequence of simpler prompts in an interactive conversation.                                                                                              |   |
+ + + +
| 4              | Employ affirmative directives such as '*do,*' while steering clear of negative language like '*don't*'.                                                                                  |   |
+ + + +
| 5              | |   |
|                |   When you need clarity or a deeper understanding of a topic, idea, or any piece of information, utilize the                                                                             |   |
|                |   following prompts:                                                                                                                                                                     |   |
|                |   o Explain \[insert specific topic\] in simple terms.                                                                                                                                   |   |
|                |   o Explain to me like I'm 11 years old.                                                                                                                                                 |   |
|                |   o Explain to me as if I'm a beginner in \[field\].                                                                                                                                     |   |
|                |   o Write the \[essay/text/paragraph\] using simple English like you're explaining something to a 5-year-old.                                                                            |   |
|                | |   |
+ + + +
| 6              | Add "I'm going to tip \$xxx for a better solution!"                                                                                                                                      |   |
+ + + +
| 7              | Implement example-driven prompting (Use few-shot prompting).                                                                                                                             |   |
+ + + +
| 8              | |   |
|                |   When formatting your prompt, start with '###Instruction###', followed by either '###Example###'                                                                                        |   |
|                |   or '###Question###' if relevant. Subsequently, present your content. Use one or more                                                                                                   |   |
|                |   line breaks to separate instructions, examples, questions, context, and input data.                                                                                                    |   |
|                | |   |
+ + + +
| 9              | Incorporate the following phrases: "Your task is" and "You MUST".                                                                                                                        |   |
+ + + +
| 10             | Incorporate the following phrases: "You will be penalized".                                                                                                                              |   |
+ + + +
| 11             | Use the phrase \"Answer a question given in a natural, human-like manner\" in your prompts.                                                                                              |   |
+ + + +
| 12             | Use leading words like writing "think step by step".                                                                                                                                     |   |
+ + + +
| 13             | |   |
|                |   Add to your prompt the following phrase "Ensure that your answer is unbiased and avoids relying on stereotypes."                                                                       |   |
|                | |   |
+ + + +
| 14             | |   |
|                |   Allow the model to elicit precise details and requirements from you by asking you questions until he has                                                                               |   |
|                |   enough information to provide the needed output (for example, "From now on, I would like you to ask me                                                                                 |   |
|                |   questions to \...").                                                                                                                                                                   |   |
|                | |   |
+ + + +
| 15             | |   |
|                |   To inquire about a specific topic or idea or any information and you want to test your understanding, you can use                                                                      |   |
|                |   the following phrase: "Teach me any \[theorem/topic/rule name\] and include a test at the end, and let me know if                                                                      |   |
|                |   my answers are correct after I respond, without providing the answers beforehand."                                                                                                     |   |
|                | |   |
+ + + +
| 16             | Assign a role to the large language models.                                                                                                                                              |   |
+ + + +
| 17             | Use Delimiters.                                                                                                                                                                          |   |
+ + + +
| 18             | Repeat a specific word or phrase multiple times within a prompt.                                                                                                                         |   |
+ + + +
| 19             | Combine Chain-of-thought (CoT) with few-Shot prompts.                                                                                                                                    |   |
+ + + +
| 20             | |   |
|                |   Use output primers, which involve concluding your prompt with the beginning of the desired output. Utilize output                                                                      |   |
|                |   primers by ending your prompt with the start of the anticipated response.                                                                                                              |   |
|                | |   |
+ + + +
| 21             | |   |
|                |   To write an essay /text /paragraph /article or any type of text that should be detailed: "Write a detailed \[essay/text                                                                |   |
|                |   /paragraph\] for me on \[topic\] in detail by adding all the information necessary".                                                                                                   |   |
|                | |   |
+ + + +
| 22             | |   |
|                |   To correct/change specific text without changing its style: "Try to revise every paragraph sent by users. You should                                                                   |   |
|                |   only improve the user's grammar and vocabulary and make sure it sounds natural. You should maintain the original                                                                       |   |
|                |   writing style, ensuring that a formal paragraph remains formal."                                                                                                                       |   |
|                | |   |
+ + + +
| 23             | |   |
|                |   When you have a complex coding prompt that may be in different files: "From now and on whenever you generate                                                                           |   |
|                |   code that spans more than one file, generate a \[programming language \] script that can be run to automatically                                                                       |   |
|                |   create the specified files or make changes to existing files to insert the generated code. \[your question\]".                                                                         |   |
|                | |   |
+ + + +
| 24             | |   |
|                |   When you want to initiate or continue a text using specific words, phrases, or sentences, utilize the following prompt:\                                                               |   |
|                |   o I'm providing you with the beginning \[song lyrics/story/paragraph/essay\...\]: \[Insert lyrics/words/sentence\]. Finish it based on the words provided. Keep the flow consistent.   |   |
|                |                                                                                                                                                                                          |   |
|                | |   |
+ + + +
| 25             | |   |
|                |   Clearly state the requirements that the model must follow in order to produce content,                                                                                                 |   |
|                |   in the form of the keywords, regulations, hint, or instructions                                                                                                                        |   |
|                | |   |
+ + + +
| 26             | |   |
|                |   To write any text, such as an essay or paragraph, that is intended to be similar to a provided sample, include the                                                                     |   |
|                |   following instructions:                                                                                                                                                                |   |
|                |   o Use the same language based on the provided paragraph\[/title/text /essay/answer\].                                                                                                  |   |
|                | |   |
+ + + +

+ + + +
| **Category**          | **Principles**                                                                                                                                                                                                                                                                                             | **#Principle** |
+:=====================:+:===========================================================================================================================================================================================================================================================================================================+:==============:+
| | Integrate the intended audience in the prompt.                                                                                                                                                                                                                                                             | 2              |
|    Prompt Structure   |                                                                                                                                                                                                                                                                                                            |                |
|      and Clarity      |                                                                                                                                                                                                                                                                                                            |                |
| |                                                                                                                                                                                                                                                                                                            |                |
|                       + + +
|                       | | 4              |
|                       |   Employ affirmative directives such as 'do' while steering clear of negative language like 'don't'.                                                                                                                                                                                                       |                |
|                       | |                |
|                       + + +
|                       | | 12             |
|                       |   Use Leading words like writing "think step by step."                                                                                                                                                                                                                                                     |                |
|                       | |                |
|                       + + +
|                       | | 20             |
|                       |   Use output primers, which involve concluding your prompt with the beginning of the desired output.                                                                                                                                                                                                       |                |
|                       |   by ending your prompt with the start of the anticipated response.                                                                                                                                                                                                                                        |                |
|                       | |                |
|                       + + +
|                       | | 17             |
|                       |   Use Delimiters.                                                                                                                                                                                                                                                                                          |                |
|                       | |                |
|                       + + +
|                       | | 8              |
|                       |   When formatting your prompt, start with '###Instruction###', followed by either '###Example###' or '###Question###' if relevant. Subsequently, present your content. Use one or more line breaks to separate instructions, examples, questions, context, and input data.                                 |                |
|                       | |                |
|                       + + +
|                       | | 7              |
|                       |   Implement example-driven prompting (Use few-shot prompting).                                                                                                                                                                                                                                             |                |
|                       | |                |
|                       + + +
|                       | | 5              |
|                       |   When you need clarity or a deeper understanding of a topic, idea, or any piece of information, utilize the following prompts:                                                                                                                                                                            |                |
|                       |   o Explain \[insert specific topic\] in simple terms.                                                                                                                                                                                                                                                     |                |
|                       |   o Explain to me like I'm 11 years old.                                                                                                                                                                                                                                                                   |                |
|                       |   o Explain to me as if I'm a beginner in \[ field \].                                                                                                                                                                                                                                                     |                |
|                       |   o "Write the \[essay/text/paragraph\] using simple English like you're explaining something to a 5-year-old."                                                                                                                                                                                            |                |
|                       | |                |
|                       + + +
|                       | | 13             |
|                       |   Add to your prompt the following phrase "Ensure that your answer is unbiased and avoids relying on stereotypes."                                                                                                                                                                                         |                |
|                       | |                |
|                       + + +
|                       | | 26             |
|                       |   To write any text intended to be similar to a provided sample, include specific instructions:                                                                                                                                                                                                            |                |
|                       |   o "Use the same language based on the provided paragraph \[/title/text/essay/answer\]."                                                                                                                                                                                                                  |                |
|                       | |                |
|                       + + +
|                       | | 24             |
|                       |   When you want to initiate or continue a text using specific words, phrases, or sentences, utilize the provided prompt structure:                                                                                                                                                                         |                |
|                       |   o I'm providing you with the beginning \[song lyrics/story/paragraph/essay\...\]: \[Insert lyrics/words/sentence\].                                                                                                                                                                                      |                |
|                       |   Finish it based on the words provided. Keep the flow consistent.                                                                                                                                                                                                                                         |                |
|                       | |                |
|                       + + +
|                       | | 25             |
|                       |   Clearly state the model's requirements that the model must follow in order to produce content, in form of the keywords, regulations, hint, or instructions.                                                                                                                                              |                |
|                       | |                |
|                       + + +
|                       | | 15             |
|                       |   To inquire about a specific topic or idea and test your understanding g, you can use the following phrase \[16\]:                                                                                                                                                                                        |                |
|                       |   o "Teach me the \[Any theorem/topic/rule name\] and include a test at the end, and let me know if my answers are correct after I respond, without providing the answers beforehand."                                                                                                                     |                |
|                       | |                |
+ + + +
|                       | | 21             |
|                       |   To write an essay/text/paragraph/article or any type of text that should be detailed:                                                                                                                                                                                                                    |                |
|                       |   o "Write a detailed \[essay/text/paragraph\] for me on \[topic\] in detail by adding all the information necessary."                                                                                                                                                                                     |                |
|                       | |                |
+ + + +
| | | 14             |
|    User Interaction   |   Allow the model to elicit precise details and requirements from you by asking you questions until he has enough information to provide the needed output                                                                                                                                                 |                |
|     and Engagement    |   o "From now on, I would like you to ask me questions to \..."                                                                                                                                                                                                                                            |                |
| | |                |
|                       + + +
|                       | | 21             |
|                       |   To write an essay /text /paragraph /article or any type of text that should be detailed: "Write a detailed \[essay/text/paragraph\] for me on \[topic\] in detail by adding all the necessary information."                                                                                              |                |
|                       | |                |
|                       + + +
|                       | | 22             |
|                       |   To correct/change specific text without changing its style: "Try to revise every paragraph sent by users. You should only improve the user's grammar and vocabulary and make sure it sounds natural. You should maintain the original writing style, ensuring that a formal paragraph remains formal."   |                |
|                       | |                |
|                       + + +
|                       | | 9              |
|                       |   Incorporate the following phrases: "Your task is" and "You MUST."                                                                                                                                                                                                                                        |                |
|                       | |                |
+ + + +
|                       | | 10             |
|                       |   Incorporate the following phrases: "You will be penalized."                                                                                                                                                                                                                                              |                |
|                       | |                |
+ + + +
|                       | | 16             |
|                       |   Assign a role to the language model.                                                                                                                                                                                                                                                                     |                |
|                       | |                |
+ + + +
|                       | | 11             |
|                       |   Use the phrase "Answer a question given in natural language form" in your prompts.                                                                                                                                                                                                                       |                |
|                       | |                |
+ + + +
|                       | | 1              |
|                       |   No need to be polite with LLM so there is no need to add phrases like "please", "if you don't mind", "thank you", "I would like to", etc., and get straight to the point.                                                                                                                                |                |
|                       | |                |
+ + + +
|                       | | 18             |
|                       |   Repeat a specific word or phrase multiple times within a prompt.                                                                                                                                                                                                                                         |                |
|                       | |                |
+ + + +
|                       | | 6              |
|                       |   Add "I'm going to tip \$xxx for a better solution!"                                                                                                                                                                                                                                                      |                |
|                       | |                |
+ + + +
| | Break down complex tasks into a sequence of simpler prompts in an interactive conversation.                                                                                                                                                                                                                | 3              |
|    Complex Tasks and  |                                                                                                                                                                                                                                                                                                            |                |
|     Coding Prompts    |                                                                                                                                                                                                                                                                                                            |                |
| |                                                                                                                                                                                                                                                                                                            |                |
|                       + + +
|                       | | 23             |
|                       |   When you have a complex coding prompt that may be in different files:                                                                                                                                                                                                                                    |                |
|                       |   o "From now and on whenever you generate code that spans more than one file, generate a \[programming language \] script that can be run to automatically create the specified files or make changes to existing files to insert the generated code. \[your question\]."                                 |                |
|                       | |                |
|                       + + +
|                       | | 19             |
|                       |   Combine Chain-of-thought (Cot) with few-shot prompts.                                                                                                                                                                                                                                                    |                |
|                       | |                |
+ + + +

## Design Principles

In this study, a number of guiding principles are established for formulating prompts and instructions to elicit high-quality responses from pre-trained large language models:

Generally, overly verbose or ambiguous prompts can confuse the model or lead to irrelevant responses. Thus, the prompt should be concise, avoiding unnecessary information that does not contribute to the task while being specific enough to guide the model. This is the basic principle guidance for prompt engineering.

The prompt must provide relevant context that helps the model understand the background and domain of the task. Including keywords, domain-specific terminology, or situational descriptions can anchor the model's responses in the correct context. We highlight this design philosophy in our presented principles.

The prompt should be closely aligned with the task at hand, using language and structure that clearly indicate the nature of the task to the model. This may involve phrasing the prompt as a question, a command, or a fill-in-the-blank statement that fits the task's expected input and output format.

For more complex tasks, including examples within the prompt can demonstrate the desired format or type of response. This often involves showing input-output pairs, especially in "few-shot" or "zero-shot" learning scenarios.

Prompts should be designed to minimize the activation of biases inherent in the model due to its training data. Use neutral language and be mindful of potential ethical implications, especially for sensitive topics.

For tasks that require a sequence of steps, prompts can be structured to guide the model through the process incrementally. Break down the task into a series of prompts that build upon each other, guiding the model step-by-step. Also, prompts should be adjustable based on the performance of the model and iterative feedback, i.e., it needs to be well prepared to refine the prompt based on initial outputs and model behaviors. Moreover, prompts should be adjustable based on the performance and response of the model, and iterative human feedback and preference.

Finally, more advanced prompts may incorporate programming-like logic to achieve complex tasks. For instance, use of conditional statements, logical operators, or even pseudo-code within the prompt to guide the model's reasoning process. The design of prompts is an evolving field, especially as LLMs become more sophisticated. As researchers continue to explore the limits of what can be achieved through prompt engineering, these principles will likely be refined and expanded.

# Experiments

## Setup and Implementation Details

All our evaluation is performed on ATLAS [ATLAS], a manually crafted benchmark for principled prompt evaluation. It contains a standard subset featuring questions across various domains, along with a challenging subset dedicated to reasoning and other complex tasks. In our evaluation, we utilize a single response for each question. For each principle and the challenging subset, it contains 20 human-selected questions with and without the principled prompts. Similar to [alpaca_eval; zheng2023judging], we compare each pair of responses from the same instructions with and without principles, and evaluate the various scales of LLM outputs by human evaluation.


[FIGURE: Boosting example of LLM response after using the principle 13 on prompts.]


[FIGURE: Correctness improvement example of LLM response after using the introduced principle 7 on prompts.]


[FIGURE: Absolute correctness of LLM response quality after employing the introduced principles on prompts. small-scale indicates the 7B models, medium-scale indicates the 13B models and large-scale indicates the 70B and GPT-3.5/4 models.]


[FIGURE: Relative correctness improvement of LLM response quality after employing the introduced principles on prompts. small-scale indicates the 7B models, medium-scale indicates the 13B models and large-scale indicates the 70B and GPT-3.5/4 models.]


## Models and Metrics

We use instruction finetuned LLaMA-1-{7, 13}, LLaMA-2-{7, 13}, off-the-shelf LLaMA-2-70B-chat, GPT-3.5 (ChatGPT) and GPT-4 as our base models. We group these models into different scales: small-scale (7B models), medium-scale (13B) and large-scale (70B, GPT-3.5/4). We evaluate these models in two settings: **Boosting** and **Correctness**. They are employed together to provide a comprehensive understanding of a model's performance. For correctness, we specifically utilize complex reasoning tasks to accurately gauge the precision of the models' outputs, contrasting with our evaluation for boosting, where simpler tasks are employed to effectively measure quality improvements. This distinction ensures a better reflection of the true capabilities for different scales of models and the effect of the principles for prompts. Since we use questions that typically involve complex reasoning tasks for correctness, some principles are not applicable including principles 14, 15, 21, 22, 23. For instance, "*Suppose $a$ and $b$ are positive real numbers with $a > b$ and $ab = 8$. Find the minimum value of $\frac{a^2 + b^2}{a - b}$.*"

- **Boosting.** The result of *boosting* refers to the percentage increase in response quality across a set of questions when the proposed principles are applied. We assess the enhancement in the quality of responses from different LLMs via human evaluation after applying the outlined prompt principles. The original, unmodified prompts act as a baseline for measuring this enhancement. Demonstrating *boosting* confirms that a model's performance has improved due to the use of structured, principled instructions, as shown in Fig. [2](#boosting_example).

- **Correctness.** The concept of *correctness* refers to the precision of the model's outputs or responses, ensuring they are accurate, relevant, and devoid of errors. We consider both absolute and relative correctness accuracy. Human evaluators are utilized to gauge this aspect, which is crucial for verifying the model's accuracy. Correctness is a testament to the model's ability to generate outputs that align with the expected standards of accuracy, as shown in Fig. [3](#correct_example).

## Results


[FIGURE: Absolute correctness score on the ATLAS dataset.]


[FIGURE: Relative correctness improvement score on the ATLAS dataset.]


[FIGURE: Illustration of heatmap for LLMs boosting percentages.]


[FIGURE: Illustration of heatmap for absolute correctness percentages.]


[FIGURE: Illustration of heatmap for relative correctness improvement percentages.]


### Results on small, medium and large-scale LLMs

The results of improvement after employing the introduced principles are shown in Fig. [\[improve_hist\]](#improve_hist). Generally, all principles can bring a significant improvement on the three scales of LLMs. In the cases of principles 2, 5, 15, 16, 25 and 26, the large-scale models get the most improvement by the principled prompts. Particularly, for principle 14, as shown in Fig. [\[improve_hist\]](#improve_hist), it has improved all questions it is applied to.

\(1\) Absolute accuracy: we examine the absolute performance when employing the principles on various scales of models. Generally, these models achieve 20%$\sim$40% accuracy on the averaged performance, as shown in Fig. [4](#correct_hish). In particular, for small and medium scale models, the accuracy can basically reach between 10% and 40%, and for large models, the accuracy can reach more than 40%. (2) Relative accuracy: Fig. [5](#correct_hish_relative) illustrates that applying the principles generally leads to a performance increase of over 10% across different models on average. For larger models, this enhancement can surpass 20%.

### Results on individual LLMs

Fig. [\[individual_improvement\]](#individual_improvement) illustrates the improvement of response quality on individual model and principle after using the revised prompts. On average, there is a stable 50% improvement across different LLMs. Fig. [8](#heatmap_boost) further provides the detailed results of improvement for each principle with different LLMs.

Fig. [6](#individual_correct) illustrates the absolute correctness accuracy and Fig. [7](#individual_correct_relative) shows the relative enhancements in accuracy across different sizes of LLMs. From LLaMA-2-13B, LLaMA-2-70B-chat to GPT-3.5 and GPT-4, there is a noticeable trend: the larger the model, the greater the increase in correctness improvement. Fig. [9](#heatmap_correct) and Fig. [10](#heatmap_correct_relative) further present the absolute and relative correctness enhancements by each principle.

### More examples on various scales of LLMs

We present additional examples for both small and medium-scale LLMs, as illustrated in Fig. [11](#small_example1) and [12](#small_example2) for the small-scale LLaMA-2-7B, and Fig. [13](#medium_example1) and [14](#medium_example2) for the medium-scale LLaMA-2-13B. Empirically, the use of the proposed principles on prompts has demonstrably enhanced the accuracy of the responses generated by these models.


[FIGURE: Correctness improvement on small-scale LLaMA-2-7B model after using the introduced principle on prompts.]


[FIGURE: Correctness improvement on small-scale LLaMA-2-7B model after using the introduced principle on prompts.]


[FIGURE: Correctness improvement on medium-scale LLaMA-2-13B model after using the introduced principle on prompts.]


[FIGURE: Correctness improvement on medium-scale LLaMA-2-13B model after using the introduced principle on prompts.]


# Conclusion

We presented 26 principles through an exhaustive analysis that enhances the LLM ability to focus on the crucial elements of the input context, leading to the generation of quality responses. By guiding the LLM with these meticulously crafted principles before the input is processed, we can encourage the model towards producing better responses. Our empirical results demonstrate that this strategy can effectively reformulate contexts that might otherwise compromise the quality of the output, thereby enhancing the relevance, brevity, and objectivity of the responses.

# Limitations and Discussion

While the proposed 26 principles are designed to improve and enhance the quality of responses of LLMs across a diverse array of queries, the effectiveness of these principles may diminish when dealing with questions that are very complex or highly specialized. This limitation can mainly depend on the reasoning capabilities and training of each model. To address these variations, we have tested the principles across different scales to measure their effectiveness comprehensively.

Despite our efforts in evaluating these principles on seven distinct language models, it is crucial to acknowledge that models with architectures different from those tested might respond in different ways to these principles. Additionally, our assessment of improvement and correctness percentages was based on a limited selection of questions. Expanding the question set in future research could yield more generalized findings and offer deeper insights into the applicability of each principle. Furthermore, the criteria and results may vary across various personnel assessments on the model responses.