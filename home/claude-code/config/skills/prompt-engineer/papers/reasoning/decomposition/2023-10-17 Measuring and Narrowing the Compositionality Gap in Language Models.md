# Measuring and Narrowing the Compositionality Gap in Language Models

- **arXiv ID**: 2210.03350
- **Authors**: Ofir Press, Muru Zhang, Sewon Min, Ludwig Schmidt, Noah A. Smith, Mike Lewis
- **Affiliations**: University of Washington, MosaicML, Meta AI Research, Allen Institute for AI
- **Published**: EMNLP 2023
- **Code**: https://github.com/ofirpress/self-ask

## Abstract

We investigate the ability of language models to perform compositional reasoning
tasks where the overall solution depends on correctly composing the answers to
sub-problems. We measure how often models can correctly answer all sub-problems
but not generate the overall solution, a ratio we call the **compositionality
gap**. We evaluate this ratio by asking multi-hop questions with answers that
require composing multiple facts unlikely to have been observed together during
pretraining.

In the GPT-3 family of models, as model size increases we show that the
single-hop question answering performance improves faster than the multi-hop
performance does, therefore the compositionality gap **does not** decrease. This
surprising result suggests that while more powerful models memorize and recall
more factual knowledge, they show no corresponding improvement in their ability
to perform this kind of compositional reasoning.

We then demonstrate how elicitive prompting (such as chain of thought) narrows
the compositionality gap by reasoning explicitly. We present a new method,
**self-ask**, that further improves on chain of thought. In our method, the
model explicitly asks itself (and answers) follow-up questions before answering
the initial question. We finally show that self-ask's structured prompting lets
us easily plug in a search engine to answer the follow-up questions, which
additionally improves accuracy.

## 1. Introduction

Compositional reasoning lets models go beyond rote memorization of directly
observed facts to deduce previously unseen knowledge. For example, a model
should be able to answer "How long was Queen Elizabeth's reign?" even if the
answer did not explicitly appear in the training data, by recalling her and her
father's death dates and reasoning over these facts. While language models (LMs)
have shown strong question answering performance, it remains unclear how much is
due to memorization of huge corpora vs. how much is due to reasoning.

### Key Contributions

1. **Compositionality Gap**: We introduce the term _compositionality gap_ to
   describe the fraction of compositional questions that the model answers
   incorrectly out of all the compositional questions for which the model
   answers the sub-questions correctly.

2. **Scale Does Not Help**: The compositionality gap remains at roughly constant
   40% between different model sizes and training techniques, with no apparent
   improvement from scale. This suggests that larger scale pretraining is highly
   effective at teaching models to memorize facts but not how to compose them.

3. **Self-Ask Method**: We present self-ask prompting, where the prompt has the
   LM decompose complex questions into easier sub-questions that it answers
   before answering the main question, improving performance over chain of
   thought.

4. **Search Engine Integration**: The structure of self-ask combines easily with
   an internet search engine to further improve results on compositional
   questions.

### Datasets

- **Compositional Celebrities (CC)**: 8.6k automatically generated 2-hop
  questions combining frequently stated facts in improbable ways (e.g., "Who won
  the Master's Tournament the year Justin Bieber was born?")

- **Bamboogle**: 125 manually constructed questions designed to be unanswerable
  by search engines but where both supporting facts can be found in Wikipedia

- **2WikiMultiHopQA** and **Musique**: Existing multi-hop QA datasets

## 2. Systematically Measuring the Compositionality Gap

### Method

Our method is based on 2-hop questions that are grammatical but unlikely to have
been previously uttered, e.g., "What is the calling code of the birthplace of
Frida Kahlo?"

The Compositional Celebrities (CC) dataset:

- Contains direct and unambiguous questions
- Each fact has likely appeared many times in training data
- The combination of both facts is sufficiently unnatural that it likely never
  appeared in training

### Example Questions from CC Dataset

| Question                                                                   | Category                   |
| -------------------------------------------------------------------------- | -------------------------- |
| What is the capital of the birthplace of Levy Mwanawasa?                   | Birthplace/Capital         |
| What is the top-level domain of the birthplace of Norodom Sihamoni?        | Birthplace/Domain Name     |
| What is the currency in the birthplace of Joel Campbell?                   | Birthplace/Currency        |
| Who was the champion of the Masters Tournament in the year Bob Dylan born? | Birth Year/Master's Champ  |
| Who won the Nobel Prize in Literature the year Matt Damon was born?        | Birth Year/Lit. Nobel      |
| Who was the President of the United States when Sting was born?            | Birth Date/US President    |
| What is the Japanese name of the birthplace of Hugh Jackman?               | Birthplace/Japanese Name   |
| What is the calling code of the birthplace of Milla Jovovich?              | Birthplace/Calling Code    |
| What is the (rounded down) latitude of the birthplace of Ferenc Puskas?    | Birthplace/Latitude        |
| What is the 3166-1 numeric code for the birthplace of Gilgamesh?           | Birthplace/3166-1 Code     |
| What is the currency symbol in the birthplace of Marek Hamsik?             | Birthplace/Currency Symbol |
| What is the Spanish name of the birthplace of Frederic Chopin?             | Birthplace/Spanish Name    |
| What is the Russian name of the birthplace of Confucius?                   | Birthplace/Russian Name    |
| What is the Estonian name of the birthplace of Kofi Annan?                 | Birthplace/Estonian Name   |
| What is the Urdu name of the birthplace of Nicki Minaj?                    | Birthplace/Urdu Name       |
| What is the (rounded down) longitude of the birthplace of Juliane Koepcke? | Birthplace/Longitude       |
| What is the currency abbreviation in the birthplace of Antonio Valencia?   | Birthplace/Currency Abbrv. |

### Key Finding: Compositionality Gap Does Not Shrink with Scale

GPT-3 (davinci-002) correctly answers 45.4% of the 2-hop questions. However:

- On hardest categories (Birth Year/Literature Nobel Prize Winner): only 1.2%
  correct
- But 80% of sub-questions answered correctly on same category
- Shows model has the facts but cannot compose them

**The compositionality gap surprisingly does NOT shrink as GPT-3 model size
increases** for both InstructGPT and non-Instruct model families.

### Accuracy by Category (davinci-002, direct prompting)

| Category                   | Both Sub-Q Right, 2-hop Right | Both Sub-Q Right, 2-hop Wrong | At Least One Sub-Q Wrong |
| -------------------------- | ----------------------------- | ----------------------------- | ------------------------ |
| Birthplace/Domain Name     | 80.3%                         | 8.6%                          | 11.2%                    |
| Birthplace/Calling Code    | 78.3%                         | 8.8%                          | 12.9%                    |
| Birthplace/Spanish Name    | 75.8%                         | 8.8%                          | 15.5%                    |
| Birthplace/Currency Abbrv. | 74.0%                         | 11.8%                         | 14.2%                    |
| Birthplace/Currency        | 59.7%                         | 9.2%                          | 31.1%                    |
| Birthplace/Capital         | 57.4%                         | 28.0%                         | 14.6%                    |
| Birthplace/Russian Name    | 57.7%                         | 5.6%                          | 36.7%                    |
| Birthplace/Japanese Name   | 57.3%                         | 21.5%                         | 21.2%                    |
| Birthplace/Currency Symbol | 54.1%                         | 15.0%                         | 30.9%                    |
| Birthplace/Estonian Name   | 53.9%                         | 21.9%                         | 24.2%                    |
| Birthplace/Latitude        | 28.1%                         | 49.8%                         | 22.1%                    |
| Birthplace/3166-1 Code     | 26.6%                         | 52.6%                         | 20.8%                    |
| Birth Date/US President    | 23.7%                         | 63.7%                         | 12.6%                    |
| Birthplace/Longitude       | 15.5%                         | 36.7%                         | 47.9%                    |
| Birthplace/Urdu Name       | 9.0%                          | 27.7%                         | 63.3%                    |
| Birth Year/Master's Champ  | 6.8%                          | 64.0%                         | 29.2%                    |
| Birth Year/Lit. Nobel      | 1.1%                          | 78.9%                         | 19.9%                    |
| **ALL**                    | **41.8%**                     | **33.4%**                     | **24.8%**                |

### Perplexity Correlation

As the perplexities assigned to correct sub-question answers decrease (i.e., the
model becomes more confident), the probability of answering the compositional
question correctly increases:

- Max perplexity 1.232-6.738: 42.6% compositional correct
- Max perplexity 1.000-1.002: 81.1% compositional correct

## 3. Elicitive Prompts Narrow the Compositionality Gap

### Prompting Categories

1. **Direct-answer prompting**: Naive method where each question is directly
   followed by its answer

2. **Elicitive prompts**: Let the model "talk things through" before answering
   - Chain of thought
   - Scratchpad
   - **Self-ask** (this paper)

### Self-Ask Method

Self-ask builds on chain of thought prompting, but:

- Model explicitly states the next follow-up question before answering it
- Inserts scaffolds like "Follow up:" to improve parseability
- Makes it easy to integrate with search engines

#### Self-Ask Process

1. Start with few-shot prompt demonstrating how to answer questions
2. Append the inference-time question
3. Insert "Are follow up questions needed here:" at the end
4. Model outputs "Yes." and generates first follow-up question
5. Model answers the follow-up question
6. Process repeats until model outputs "So the final answer is:"

#### Example: Self-Ask vs Direct Prompting vs Chain of Thought

**Question**: "Who lived longer, Theodor Haecker or Harry Vaughan Watkins?"

**Direct Prompting**:

```
Q: Who lived longer, Theodor Haecker or Harry Vaughan Watkins?
A: Harry Vaughan Watkins
```

**Chain of Thought**:

```
Q: Who lived longer, Theodor Haecker or Harry Vaughan Watkins?
A: Theodor Haecker was born in 1879 and died in 1945. Harry Vaughan Watkins
was born in 1885 and died in 1956. 1945 - 1879 = 66, 1956 - 1885 = 71.
So Harry Vaughan Watkins lived longer.
```

**Self-Ask**:

```
Q: Who lived longer, Theodor Haecker or Harry Vaughan Watkins?
Are follow up questions needed here: Yes.
Follow up: How old was Theodor Haecker when he died?
Intermediate answer: Theodor Haecker was 66 years old when he died.
Follow up: How old was Harry Vaughan Watkins when he died?
Intermediate answer: Harry Vaughan Watkins was 71 years old when he died.
So the final answer is: Harry Vaughan Watkins
```

### Advantages of Self-Ask over Chain of Thought

1. **Disentangles decomposition from answering**: Formulating sub-questions is
   separate from answering them
2. **Rigid scaffolding**: Makes it easier to state the final answer in a
   concise, parseable way
3. **Better final answer format**: In Bamboogle, 40% of CoT final answers were
   not in short form vs. 17% for self-ask

### Bamboogle Dataset

Manually constructed dataset of 125 questions:

- 2-hop questions from random Wikipedia articles
- Questions are sufficiently difficult to be unanswerable by search engines
- Both supporting pieces of evidence can be found in Wikipedia

**Example Bamboogle Questions**:

| Question                                                                          |
| --------------------------------------------------------------------------------- |
| In what year was the company founded as Sound of Music added to the S&P 500?      |
| Who was the first African American mayor of the most populous city in the US?     |
| When did the last king from Britain's House of Hanover die?                       |
| When did the president who set the precedent of a two term limit leave office?    |
| Can people who have celiac eat camel meat?                                        |
| Who is the largest aircraft carrier in the world named after?                     |
| Who built the fastest air-breathing manned aircraft?                              |
| The machine used to extract honey from honeycombs uses which physical force?      |
| In what year was the government department where the internet originated founded? |
| Who founded the city where the founder of geometry lived?                         |

### Self-Ask + Search Engine (SA+SE)

Unlike chain of thought, self-ask clearly demarcates the beginning and end of
every sub-question. Therefore:

1. When LM outputs "Follow up:", let it finish generating the question
2. When LM outputs "Intermediate answer:", stop the LM
3. Input the sub-question to a search engine API
4. Add the search engine's answer to the prompt
5. Let LM continue generating

**Key advantage**: Uses the same prompt as self-ask -- no modifications needed.
Implementable in only a few lines of code.

## 4. Experimental Results

### Main Results (Davinci-002)

| Method             | Bamboogle | 2WikiMultiHopQA | Musique   |
| ------------------ | --------- | --------------- | --------- |
| Direct prompting   | 17.6%     | 25.4%           | 5.6%      |
| Chain of Thought   | 46.4%     | 29.8%           | 12.6%     |
| Search             | 0.0%      | 2.2%            | 1.5%      |
| Search + postproc. | -         | 26.3%           | 6.5%      |
| Self-ask           | 57.6%     | 30.0%           | 13.8%     |
| Self-ask + Search  | **60.0%** | **40.1%**       | **15.2%** |

### Comparison with Least-to-Most Prompting

| Method        | 2Wiki Acc. | 2Wiki # Tokens | Musique Acc. | Musique # Tokens |
| ------------- | ---------- | -------------- | ------------ | ---------------- |
| Least-to-Most | 29.0%      | 844            | 16.8%        | 1020             |
| Self-ask      | **35.5%**  | **569**        | 16.3%        | **663**          |

Self-ask achieves similar or better performance while running more than 30%
faster (fewer tokens generated).

### Key Observations

1. Chain of thought shows notable improvements over direct prompting
2. Search engines struggle to answer compositional questions directly
3. Self-ask improves over chain of thought, especially on Bamboogle (+11%
   absolute) where questions are more varied
4. Integrating search engine into self-ask further improves performance (up to
   +10% absolute)

## 5. Related Work

### Prior Work on Question Decomposition

- Multiple papers trained supervised models to decompose compositional questions
  into sub-questions
- Self-ask does this _automatically_ without additional training

### Retrieval-Augmented Generation

- WebGPT, LaMDA require finetuning on new data
- Self-ask + Search Engine requires no modifications to the LM or its
  pretraining

### Concurrent Work

- Decomposed Prompting (Khot et al., 2023)
- ReAct (Yao et al., 2023)
- These methods are similar to self-ask but do not present findings on the
  compositionality gap, integrate with web search, or present new datasets

## 6. Conclusion

1. **Compositionality Gap**: LMs can answer many compositional questions that
   were probably not encountered during training, but cannot answer all
   questions composed of observed facts. This gap does not shrink as GPT-3 size
   increases.

2. **Self-Ask**: Improves over chain of thought by having the LM explicitly
   state and answer follow-up questions.

3. **Search Integration**: Self-ask can be easily combined with a search engine
   to further improve performance.

## 7. Limitations

- Experiments focus on models up to 175B parameters; larger models may behave
  differently
- Focus on 2-hop QA in English; other task types may show different patterns
- Limited manual experiments on semantic parsing, arithmetic, and logical
  puzzles showed self-ask also works, but more thorough evaluation needed

## Key Takeaways for Prompt Engineering

1. **The compositionality gap is real**: Models know facts individually but
   struggle to compose them -- this is a fundamental limitation worth designing
   around.

2. **Explicit decomposition helps**: Having models explicitly state sub-problems
   before solving them improves compositional reasoning.

3. **Structured output enables tool use**: The scaffolded format of self-ask
   ("Follow up:", "Intermediate answer:") makes it trivial to insert external
   tool results.

4. **Model confidence predicts composability**: Facts the model is more
   confident about (lower perplexity) are more likely to be successfully
   composed.

5. **Search engines fail on compositional questions**: Direct search cannot
   handle multi-hop reasoning, but search + LM decomposition works well.
