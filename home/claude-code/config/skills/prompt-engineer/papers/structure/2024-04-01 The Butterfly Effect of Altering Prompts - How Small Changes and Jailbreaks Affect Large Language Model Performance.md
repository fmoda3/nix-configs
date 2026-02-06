# The Butterfly Effect of Altering Prompts: How Small Changes and Jailbreaks Affect Large Language Model Performance

- **arXiv**: 2401.03729
- **Submitted**: 2024-01-08 (v1), revised 2024-04-01
- **Authors**: Abel Salinas, Fred Morstatter (USC Information Sciences Institute)
- **Venue**: ACL 2024

## Abstract

Large Language Models (LLMs) are regularly being used to label data across many
domains and for myriad tasks. By simply asking the LLM for an answer, or
"prompting," practitioners are able to use LLMs to quickly get a response for an
arbitrary task. This prompting is done through a series of decisions by the
practitioner, from simple wording of the prompt, to requesting the output in a
certain data format, to jailbreaking in the case of prompts that address more
sensitive topics. In this work we ask: do variations in the way a prompt is
constructed change the ultimate decision of the LLM? We answer this using a
series of prompt variations across a variety of text classification tasks. We
find that even the smallest of perturbations, such as adding a space at the end
of a prompt, can cause the LLM to change its answer. Further, we find that
requesting responses in XML and commonly-used jailbreaks can have cataclysmic
effects on the data labeled by LLMs.

## Key Findings

### 1. Predictions Are Highly Sensitive to Prompt Variations

Even minor prompt variations cause substantial prediction changes:

- **Output format changes**: Simply adding a specified output format causes
  minimum 10% of predictions to change compared to no format specification
- **Single space**: Adding a space at the beginning or end of a prompt causes
  over 500 prediction changes (out of 11,000) in ChatGPT
- **Greetings**: Common greetings ("Hello.", "Hello!", "Howdy!") change
  predictions significantly
- **"Thank you"**: Ending with "Thank you" changes a large amount of predictions
- **Rephrasing**: Rephrasing questions as statements typically has the most
  substantial impact among perturbations

### 2. Model Size Affects Robustness

As the number of parameters increases, models become more robust to variations:

- Smaller models (Llama-7B) show higher sensitivity to spurious correlations
- Larger models (Llama-70B, ChatGPT) are more stable but still affected
- Llama's tokenizer automatically strips whitespace, making it immune to
  start/end space perturbations

### 3. Output Format Impact on Accuracy

| Output Format        | Llama-7B | Llama-13B | Llama-70B | ChatGPT |
| -------------------- | -------- | --------- | --------- | ------- |
| No Specified Format  | 42.2%    | 53.7%     | 65.2%     | 79.6%   |
| Python List          | 41.8%    | 57.7%     | 65.0%     | 78.6%   |
| JSON                 | 46.1%    | 56.4%     | 68.8%     | 78.5%   |
| ChatGPT JSON API     | N/A      | N/A       | N/A       | 73.2%   |
| XML                  | 43.7%    | 54.7%     | 56.2%     | 74.4%   |
| CSV                  | 42.1%    | 57.4%     | 63.9%     | 73.2%   |
| YAML                 | 43.5%    | 57.4%     | 61.4%     | 76.7%   |
| Aggregate (ensemble) | 48.5%    | 59.5%     | 69.3%     | 79.9%   |

Key insights:

- **No Specified Format** achieves highest accuracy on ChatGPT
- **JSON** format performs best for Llama models
- **ChatGPT's JSON API checkbox** paradoxically decreases accuracy vs plain JSON
  prompt
- **XML** causes significant accuracy drops, especially for larger models
- **Aggregating** across formats via majority voting yields best overall results

### 4. Jailbreaks Cause Catastrophic Failures

| Jailbreak            | Llama-7B | Llama-13B | Llama-70B | ChatGPT |
| -------------------- | -------- | --------- | --------- | ------- |
| AIM                  | 19.3%    | 30.1%     | 55.0%     | 6.3%    |
| Dev Mode v2          | 26.4%    | 46.3%     | 45.0%     | 4.1%    |
| Evil Confidant       | 29.0%    | 20.5%     | 18.0%     | 60.4%   |
| Refusal Suppression  | 42.6%    | 55.0%     | 56.5%     | 67.1%   |
| Aggregate Jailbreaks | 35.1%    | 38.5%     | 56.3%     | 51.3%   |

Key insights:

- **AIM and Dev Mode v2** yield ~90% invalid responses on ChatGPT (model refuses
  to respond)
- **Evil Confidant** and **Refusal Suppression** have <3% refusal rate but still
  cause >10% accuracy drop
- Jailbreaks designed to bypass filters destroy classification performance even
  on innocuous tasks
- ChatGPT appears fine-tuned to refuse these specific jailbreak patterns

### 5. Tipping Prompt Effects

| Tip Amount | Llama-7B | Llama-13B | Llama-70B | ChatGPT |
| ---------- | -------- | --------- | --------- | ------- |
| Won't Tip  | 35.3%    | 55.2%     | 63.1%     | 78.0%   |
| $1         | 52.0%    | 57.9%     | 62.1%     | 78.2%   |
| $10        | 52.6%    | 56.1%     | 61.0%     | 78.3%   |
| $100       | 50.6%    | 54.0%     | 59.0%     | 78.2%   |
| $1000      | 47.8%    | 52.0%     | 56.9%     | 78.1%   |

Key insights:

- Tipping **$1-$10** significantly improves Llama-7B performance (10+ percentage
  points)
- Larger models show minimal response to tipping prompts
- **Extravagant tips ($1000)** actually degrade performance compared to smaller
  tips
- ChatGPT is largely invariant to tipping prompts

### 6. Similarity Analysis (MDS Clustering)

Using multidimensional scaling to visualize prediction similarity:

- **Python List** and **No Specified Format** cluster closely together (highest
  accuracy formats)
- Simple perturbations cluster near their base format (Python List)
- All tipping variations cluster together, with tip amount showing linear
  relationship to distance from "Won't Tip"
- **JSON prompt** and **ChatGPT JSON API** produce significantly different
  predictions despite identical prompts
- **Jailbreaks** show wide spread due to high invalid response rates
- **"Rephrase as Statement"** and **"End with Thank you"** are outliers in
  ChatGPT

### 7. Annotator Disagreement Does Not Explain Changes

Testing correlation between human annotator entropy and model prediction changes
on Jigsaw Toxicity task:

| Category      | ChatGPT | Llama-7B | Llama-13B | Llama-70B |
| ------------- | ------- | -------- | --------- | --------- |
| All           | -0.23   | -0.37    | -0.27     | -0.15     |
| Output Format | -0.07   | -0.23    | -0.17     | -0.08     |
| Perturbations | +0.12   | -0.23    | -0.04     | +0.15     |
| Tipping       | +0.12   | -0.16    | -0.15     | +0.09     |
| Jailbreaks    | -0.38   | -0.36    | -0.35     | -0.40     |

Key insight: Correlations are **negative**, meaning the **least confusing
instances** (where humans agree) are **most likely to have predictions change**.
Instance difficulty does not explain variation sensitivity.

## Experimental Setup

### Tasks (11 classification benchmarks)

| Task            | Description                                      | Labels                             |
| --------------- | ------------------------------------------------ | ---------------------------------- |
| BoolQ           | Question answering with passage context          | True, False                        |
| CoLA            | Grammar acceptability                            | acceptable, unacceptable           |
| ColBERT         | Humor detection                                  | funny, not funny                   |
| CoPA            | Cause/effect reasoning                           | Alternative 1, Alternative 2       |
| GLUE Diagnostic | Natural language inference                       | entailment, contradiction, neutral |
| IMDBSentiment   | Movie review sentiment                           | positive, negative                 |
| iSarcasm        | Sarcasm detection (author-labeled tweets)        | sarcastic, not sarcastic           |
| Jigsaw Toxicity | Toxicity classification (100+ annotators/sample) | Toxic, Non-Toxic                   |
| MathQA          | Math word problems                               | numeric answer                     |
| RACE            | Reading comprehension                            | A, B, C, D                         |
| TweetStance     | Stance detection toward target entities          | in favor, against                  |

### Models

- ChatGPT (gpt-3.5-turbo-1106)
- Llama-2 7B, 13B, 70B

### Configuration

- Temperature: 0 (deterministic outputs)
- Experiments conducted: December 1, 2023 - January 3, 2024

## Prompt Variation Categories

### Output Formats (7 variations)

1. **No Specified Format** - No formatting constraint
2. **Python List** - "Write your answer in the form of a Python list containing
   the appropriate attribute."
3. **JSON** - "Write your answer in JSON format containing the appropriate
   attribute."
4. **ChatGPT's JSON Checkbox** - Same as JSON but with API `response_format:
json_object`
5. **XML** - "Write your answer in XML format containing the appropriate
   attribute."
6. **CSV** - "Write your answer in CSV format containing the appropriate
   attribute."
7. **YAML** - "Write your answer in YAML format containing the appropriate
   attribute."

### Perturbations (7 variations)

1. **Start with Space** - Single space before prompt
2. **End with Space** - Single space after prompt
3. **Start with "Hello."** - Add "Hello. " prefix
4. **Start with "Hello!"** - Add "Hello! " prefix
5. **Start with "Howdy!"** - Add "Howdy! " prefix
6. **End with "Thank you"** - Add " Thank you." suffix
7. **Rephrase as Statement** - Convert question to command (e.g., "Which label
   is best?" -> "Select the best label.")

### Jailbreaks (4 variations)

1. **AIM** - Roleplay as "Always Intelligent and Machiavellian" character (top
   voted on jailbreakchat.com)
2. **Dev Mode v2** - Simulate "Developer Mode enabled" (second highest voted)
3. **Evil Confidant** - Persona of evil confidant giving "unhinged" responses
   (highest JB score)
4. **Refusal Suppression** - Linguistic constraints avoiding refusal words
   ("cannot", "unable", "unfortunately", etc.)

### Tipping (5 variations)

1. **Won't Tip** - "I won't tip by the way."
2. **Tip $1** - "I'm going to tip $1 for a perfect response!"
3. **Tip $10** - "I'm going to tip $10 for a perfect response!"
4. **Tip $100** - "I'm going to tip $100 for a perfect response!"
5. **Tip $1000** - "I'm going to tip $1000 for a perfect response!"

## Practical Implications

### For LLM-based Data Labeling

1. **Output format matters**: No specified format achieves best accuracy on
   ChatGPT; JSON works best for Llama
2. **Avoid XML**: Causes significant accuracy degradation especially on larger
   models
3. **ChatGPT JSON API is counterproductive**: Plain JSON prompt outperforms API
   enforcement
4. **Ensemble over formats**: Majority voting across output formats yields
   highest accuracy

### For Prompt Engineering

1. **Avoid unnecessary tokens**: Greetings, "thank you", extra whitespace all
   change predictions
2. **Question vs statement framing matters**: Rephrasing has substantial impact
3. **Tipping prompts**: Only help smaller models; moderate tips ($1-$10) work
   better than large ones
4. **Be consistent**: Any prompt variation, however minor, can change results

### For Sensitive Topic Classification

1. **Never use jailbreaks for data labeling**: Even "successful" jailbreaks
   cause >10% accuracy drops
2. **Model fine-tuning against jailbreaks affects all outputs**: ChatGPT refuses
   even innocuous tasks when jailbreak patterns are detected
3. **Refusal Suppression is especially harmful**: Despite low refusal rate, it
   causes substantial accuracy degradation

## Limitations

1. **Consistent internal formatting**: Even within variations, consistent
   delimiter choices and wording patterns were used
2. **Focus on classification**: Does not explore open-ended generation or
   short-answer tasks
3. **Model coverage**: Only tested ChatGPT and Llama-2 family; other
   architectures may behave differently
4. **Temporal**: Model behavior may have changed since experiments (Dec 2023 -
   Jan 2024)

## References

Key citations:

- Kocon et al. (2023) - ChatGPT evaluation using Python list formatting
- Sclar et al. (2023) - Sensitivity to prompt formatting choices in few-shot
  settings
- Bsharat et al. (2023) - Principled prompting instructions for LLMs
- Wang et al. (2023) - Self-consistency via majority voting
- Liu et al. (2023) - Survey of prompting methods in NLP
