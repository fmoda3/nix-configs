# Context Reframing Techniques

Context reframing restructures how the model perceives and processes input -- changing the frame of reference, perspective, or role through which the task is interpreted. Use these techniques when: (1) the model misinterprets ambiguous questions due to human-LLM frame disparity, (2) the model ignores provided context in favor of memorized facts, (3) you need to elicit implicit chain-of-thought reasoning without explicit CoT prompts, or (4) multiple perspectives would improve answer quality. These techniques operate at the understanding phase before reasoning begins, shaping attention patterns and knowledge retrieval.

---

## Rephrase and Respond (RaR)

**Mechanism:** Prompt the LLM to rephrase and expand the question before answering in a single query, aligning human-framed questions with LLM-preferred interpretations.

**Triggers:**

- Questions contain ambiguity that humans do not perceive but LLMs misinterpret
- Zero-shot setting where prompt quality significantly impacts response
- Human-LLM frame-of-thought disparity exists (e.g., "even month" interpreted as months with even days)
- Factual questions with semantic confusion

**Tradeoffs:** ~2x token overhead (rephrased question + answer). Single API call. More advanced models benefit more; weaker models show modest improvement. Less effective on well-designed unambiguous questions. Complementary to CoT -- can be combined.

---

## Role-Play Prompting

**Mechanism:** Assign LLM an expert role via two-stage dialogue (role-setting prompt + role-feedback response) to trigger implicit chain-of-thought reasoning through persona immersion.

**Triggers:**

- Zero-shot reasoning tasks requiring step-by-step thinking
- Arithmetic word problems requiring mathematical reasoning
- Domains where expert knowledge naturally provides reasoning advantage
- Tasks where explicit CoT trigger ("Let's think step by step") is insufficient
- Model fails to spontaneously generate CoT

**Tradeoffs:** Minimal token overhead -- single role-setting + role-feedback prompt prepended. 1 call per question after one-time role construction. Requires manual role selection per task. Performance saturates on simple tasks already near ceiling. Acts as implicit CoT trigger more effective than Zero-Shot-CoT.

---

## ExpertPrompting

**Mechanism:** Automatically synthesize detailed expert identity descriptions via ICL (3 instruction-expert exemplar pairs), then condition LLM responses on that specialized background.

**Triggers:**

- Instruction requires domain-specific expertise or specialized knowledge
- Response quality benefits from detailed, comprehensive, professional answers
- Task spans diverse domains requiring automatic adaptation
- User expects authoritative, thorough responses rather than generic answers

**Tradeoffs:** ~1.3x tokens (answers average 27% longer). 2 API calls per instruction (identity generation + answer). May generate unwanted self-referential statements about the expert identity requiring post-processing removal.

---

## Context-faithful Prompting (Opinion-based)

**Mechanism:** Reframe context as a narrator's opinion ("Bob said...") and questions as opinion-seeking ("in Bob's opinion?"), forcing the model to attend to context over memorized facts.

**Triggers:**

- Input contains facts conflicting with model parametric knowledge
- Knowledge acquisition tasks like MRC or information extraction
- Need to prevent model from parroting memorized answers
- Context may be irrelevant and model should abstain from answering
- Factual accuracy to provided context is critical

**Tradeoffs:** 1.2-1.5x tokens for opinion-based reframing. Single call. Optional counterfactual few-shot examples for knowledge conflict scenarios. May underperform on smaller models lacking reading comprehension ability.

---

## Step-Back Prompting

**Mechanism:** Ask an abstract "step-back question" first to retrieve high-level concepts and principles, then reason using that abstraction to answer the original detailed question.

**Triggers:**

- Question contains excessive detail obscuring underlying principles
- Physics and chemistry reasoning requiring domain concepts or first principles
- Knowledge-intensive QA with temporal or contextual constraints
- Multi-hop reasoning where high-level concepts enable better retrieval

**Tradeoffs:** 2x tokens, 2 API calls (abstraction + reasoning). Requires few-shot examples demonstrating the abstraction step (not zero-shot compatible). For knowledge-intensive QA, RAG is integral — the step-back question identifies what facts to retrieve, not an optional enhancement. Unnecessary for simple factual questions or when question already references first principles directly.

---

## Contrastive Prompting

**Mechanism:** Prompt LLM to generate both correct and wrong answers simultaneously, then extract the correct answer by explicit contrast.

**The trigger phrase:**

```
Let's give a correct and a wrong answer.
```

The process follows 2 steps: (1) Reasoning extraction — the model generates both a correct answer with reasoning and a wrong answer, forcing explicit awareness of potential errors; (2) Answer extraction — a follow-up prompt confirms and extracts the correct answer from the contrastive output.

**Triggers:**

- Arithmetic reasoning problems requiring accuracy over step-by-step decomposition
- Commonsense reasoning tasks requiring awareness of individual knowledge pieces
- Tasks where LLM needs self-awareness of potential errors
- Math problems with infinite possible answers where eliminating wrong patterns helps

**Tradeoffs:** 2x tokens, 2 calls (reasoning extraction + answer extraction). Performs worse than CoT on symbolic reasoning with limited action spaces requiring explicit step decomposition. Strong on arithmetic and commonsense.

---

## Contrastive In-Context Learning

**Mechanism:** Provide positive and negative example pairs with explicit labels, then elicit reasoning about their differences before generation.

**Why this works:** Models learn primarily from the label space, input distribution, and format shown in demonstrations — ground truth label correctness has only marginal effect on performance. This means negative examples function not by teaching "what not to do" through correct labeling, but by expanding the model's representation of the output space and sharpening attention to distinguishing features. Contrastive pairs leverage this by making the desired distinction explicit.

**Triggers:**

- User preference alignment needed (style, tone, format)
- Desired output characteristics hard to describe explicitly in instructions
- Multiple valid outputs exist with preference ordering
- Need to guide model away from default mechanical style
- Implicit stylistic constraints (concise vs detailed, formal vs casual)

**Tradeoffs:** 2x tokens (positive + negative examples vs positive only). Single call. Requires paired positive/negative examples. Optional reasoning step increases tokens by ~50-100.

---

## Multi-expert Prompting

**Mechanism:** Generate multiple expert identities, collect their independent responses, aggregate via 7-subtask process inspired by NGT (Nominal Group Technique, which has 4 steps), then select best answer. The 7 subtasks are: (1) identify agreed viewpoints, (2) identify conflicts, (3) resolve conflicts, (4) collect isolated viewpoints, (5) aggregate all viewpoints, (6) combine into unified response, (7) select best answer among individual and combined responses.

**Triggers:**

- Open-ended questions with multiple valid perspectives
- Questions requiring diverse domain expertise
- Tasks where truthfulness, factuality, and safety are critical
- Long-form generation requiring informativeness and usefulness
- Questions where single expert view introduces bias

**Tradeoffs:** 2x tokens (TruthfulQA), 1.5x (BOLD). Three distinct LLM operations: (1) generate n expert identities in one call, (2) n calls for expert responses, (3) one call executing all 7 aggregation subtasks in a single chain-of-thought. Requires good instruction-following capability. Less effective for short-form answers without CoT reasoning traces.

---

## Argument Generation

**Mechanism:** Generate arguments for and against each possible answer, then rank arguments to select the strongest one.

**Triggers:**

- Multiple choice questions with explicit answer candidates
- Smaller language models (< 8B parameters) where reasoning boost needed
- Tasks where counterarguments reveal the correct answer
- Bias mitigation in classification tasks
- When chain-of-thought reasoning produces insufficient performance

**Tradeoffs:** 2-3x tokens (generate arguments for all candidates + ranking). Single call. Requires predefined answer candidates. Most effective for small models; diminishing returns for models > 8B parameters. May force larger models to generate convincing arguments for incorrect options.

---

## EmotionPrompt

**Mechanism:** Append psychological emotional stimuli phrases to prompts to enhance performance and truthfulness. Stimuli derive from two psychological theory categories: (1) Self-monitoring theory — phrases like "This is very important to my career" or "Are you sure?" that invoke social accountability; (2) Social cognitive theory (self-efficacy) — phrases like "Believe in your abilities" or "Embrace challenges as opportunities" that invoke intrinsic motivation.

**Critical insight:** Few-shot settings show substantially larger gains than zero-shot. Prioritize this technique when using few-shot demonstrations.

**Triggers:**

- Few-shot learning scenarios where performance gains are valuable
- Tasks requiring truthfulness and factual accuracy
- Generative tasks where quality, truthfulness, and responsibility matter
- When robustness to temperature variations is desired

**Tradeoffs:** Minimal overhead (11-50 tokens per stimulus). Single call. May produce overly deterministic language. Models without RLHF training show larger response to emotional stimuli — consider this when selecting models.

---

## Code Prompting

**Mechanism:** Transform natural language input into code representation (without executing the code) to elicit conditional reasoning abilities. The code uses variables for entities, if-blocks for conditional statements, and preserves original natural language as comments. The LLM reads the code and generates a natural language answer — the code syntax triggers reasoning pathways trained on programming, improving state tracking and multi-hop reasoning.

**The transformation process:**

```
# Original NL preserved as comment
# If you are married and your spouse passed away, you are eligible for X
married = unknown
spouse_passed_away = unknown
if married and spouse_passed_away:
    eligible_for_x = true

# Question: Is the user eligible for X?
```

**Triggers:**

- Conditional reasoning tasks with multiple if-then rules
- Multi-hop reasoning problems requiring entity state tracking
- Tasks where variables or entities need tracking across reasoning steps
- When limited demonstrations are available (code prompts are more sample-efficient)
- Natural language rules with complex logical structure

**Tradeoffs:** Requires intermediate transformation step (can be automated by a smaller model). Only benefits text+code LLMs (models trained on both text and code) — pure text or pure code models do not show gains. Code must faithfully represent NL semantics; anonymous or random code hurts performance. Removing NL comments from code causes the largest performance drop — both code structure AND original NL text are required.

---

## Anticipatory Reflection

**Mechanism:** Before executing an action in a multi-step workflow, prompt the model to anticipate potential failures and generate alternative remedies. The model asks itself: "If this action fails, what should I do instead?" This creates a stack of backup actions to try if the primary action doesn't achieve the subtask objective.

**The process:**

```
1. Generate action for current subtask
2. Ask: "If your answer above is not correct, instead, the next action should be:"
3. Generate remedy action(s)
4. Execute primary action
5. Evaluate: does result align with subtask objective?
6. If misaligned: backtrack and try remedy action
7. Repeat until subtask complete or remedies exhausted
```

**Triggers:**

- Multi-step agentic workflows where actions can fail or produce unexpected results
- Tool-using agents (file operations, web navigation, API calls)
- Tasks where backtracking is cheaper than starting over
- Workflows where early errors compound into larger failures
- When reducing trial-and-error iterations matters

**Why this works:** Standard reflection operates sequentially — one error corrected per complete execution trajectory. Anticipatory reflection prepares alternatives *before* failure occurs, enabling immediate recovery without full replanning. The follow-up question ("If your answer above is not correct...") also mitigates position bias by forcing the model to consider alternatives to its first choice.

**Critical insight:** The goal is *consistency in plan execution*, not constant replanning. Execute the current plan with backup options rather than revising the plan at each obstacle. Plan revision happens only when all remedy actions are exhausted.

**CORRECT:**
```
Subtask: Find the order containing a picture frame from November 2022

Action: Click "View Order" on order #179
Remedy: If #179 doesn't contain picture frame, click "View Order" on order #175
Remedy: If #175 doesn't contain picture frame, click "View Order" on order #182

[Execute #179 → no picture frame → backtrack → execute #175 → found it]
```

**INCORRECT:**
```
Subtask: Find the order containing a picture frame from November 2022

Action: Click "View Order" on order #179
[Execute → no picture frame → revise entire plan → start over]
```

The incorrect version triggers full replanning after one failed action. The correct version prepared alternatives and recovers immediately.

**Tradeoffs:** Generates remedy actions that may never be used. Best when backtracking cost is low (e.g., URL navigation) and action space is constrained. Less valuable when actions are irreversible or remedy generation is expensive.

---

## Multi-Perspective Reasoning

**Mechanism:** Separate direction generation (Navigator role) from reasoning execution (Reasoner role). The Navigator generates multiple diverse framings or approaches to the problem; the Reasoner works through each independently. Final answer selection uses agreement scoring across perspectives rather than single-path confidence.

**The process:**

```
1. Navigator generates K diverse directions/framings for approaching the question
2. For each direction, Reasoner generates response with rationale
3. Compute intra-consistency (self-consistency within each path)
4. Compute inter-consistency (agreement across paths)
5. If consistency exceeds threshold: return highest-agreement answer
6. If not: Navigator generates new directions incorporating low-consistency signal
7. Repeat until convergence or max iterations
```

**Triggers:**

- Knowledge-intensive reasoning where getting stuck on one path is likely
- Tasks where self-assessment is unreliable without ground truth
- When diverse perspectives would surface different relevant knowledge
- Problems where the model confidently produces wrong answers (high confidence, low accuracy)
- Multi-hop reasoning requiring exploration of alternative inference chains

**Why this works:** LLMs often get trapped in reasoning loops — even with explicit "your answer is wrong" feedback, they frequently fail to revise predictions. Multiple perspectives bypass this by exploring parallel reasoning paths. Agreement among independently-generated responses serves as a proxy for correctness when ground truth is unavailable.

**Critical insight:** Diversity between reasoning paths matters more than depth within a single path. If all perspectives converge on the same answer through different routes, confidence is warranted. If they diverge, the question likely requires more careful analysis or the model lacks sufficient knowledge.

**CORRECT:**
```
Question: What factors contributed to the fall of the Roman Empire?

Navigator directions:
- Economic perspective: taxation, inflation, trade disruption
- Military perspective: overextension, barbarian pressure, army loyalty
- Political perspective: succession crises, division of empire, administrative decay

[Reasoner produces three analyses → all mention military overextension and economic strain → high inter-consistency → return synthesized answer]
```

**INCORRECT:**
```
Question: What factors contributed to the fall of the Roman Empire?

[Single reasoning chain → gets fixated on lead poisoning theory → high confidence, questionable accuracy]
```

**Tradeoffs:** K×N token overhead (K directions × N reasoning steps each). Multiple LLM calls. Most valuable when single-path reasoning produces confident but incorrect answers. Overkill for simple factual questions with clear answers.

---

## Conversational Prompt Refinement

**Mechanism:** Structured multi-turn workflow for creating personalized prompts through conversation. Uses unlabeled user data to generate data-driven questions, iteratively refines instructions based on feedback, and collects approved outputs as few-shot examples.

**The process:**

```
1. User provides unlabeled examples of their data
2. Model analyzes examples, generates data-driven questions about preferences
   ("Should summaries focus on plot or reviewer opinion?")
3. User responses shape initial instruction
4. Model generates outputs using instruction on user's data
5. User provides feedback on outputs
6. Model refines instruction based on feedback
7. Repeat 4-6 until user approves outputs
8. Approved outputs become few-shot examples in final prompt
```

**Triggers:**

- Repetitive tasks on similar data (summarizing emails, generating ad copy)
- When desired output characteristics are hard to specify upfront
- User knows good output when they see it but can't articulate requirements
- Need to create reusable prompts without labeled training data
- Personalizing style, tone, or format to specific preferences

**Why this works:** Users struggle to articulate task requirements in abstract terms, but easily judge concrete outputs. Data-driven questions surface relevant preference dimensions the user may not have considered. Iterative refinement captures implicit requirements that emerge only when seeing actual outputs. Approved outputs provide concrete few-shot examples aligned with demonstrated preferences.

**Critical insight:** The conversation produces two artifacts: (1) a refined instruction capturing explicit preferences, and (2) few-shot examples demonstrating implicit preferences. Both matter — the instruction alone may miss nuances that the examples capture.

**CORRECT:**
```
User uploads: 3 movie review snippets
Model: "Should summaries emphasize the plot, the reviewer's opinion, or both?"
User: "Both, but keep them brief"
Model generates summary → User: "Too formal, make it conversational"
Model refines instruction, regenerates → User approves
[Final prompt includes instruction + approved summaries as few-shot examples]
```

**INCORRECT:**
```
User: "Write me a prompt for summarizing movie reviews"
Model: [Generates generic summarization prompt without seeing user's data or preferences]
```

**Tradeoffs:** Requires interactive session (not single-turn). Best for tasks performed repeatedly where upfront investment pays off. The few-shot examples add tokens to every subsequent use of the prompt — balance example count against token budget.

---

## Principled Persona Prompting

**Mechanism:** Assign task-aligned expert personas while avoiding irrelevant attributes that degrade performance.

**Triggers:**

- Task requires specialized domain knowledge
- Expertise framing might improve task alignment
- Task benefits from specific perspective or knowledge level

**Anti-patterns (avoid):**

- Adding task-irrelevant attributes like names or preferences
- Using gendered roles when gender is irrelevant
- Simple "You are a helpful assistant" prompts for objective factual tasks

**Tradeoffs:** Minimal overhead (5-20 tokens). Single call. High sensitivity to irrelevant attributes -- irrelevant personas cause 14-59% negative effects across models.

---

## Persona Prompting Ineffectiveness (Anti-pattern)

**Mechanism:** Study finding that adding persona roles to system prompts does not improve and may harm LLM performance on objective tasks.

**Key findings:**

- Do NOT use persona prompting for objective factual questions
- Do NOT add roles like "You are a helpful assistant" expecting performance gains
- Do NOT use speaker-specific roles ("You are a lawyer") for factual accuracy
- Audience-specific prompts marginally better than speaker-specific
- Gender-neutral roles slightly better than gendered roles
- Effects are largely random and unpredictable across 162 roles, 9 LLMs

---

## Decision Guidance

**Question clarity issues:** Use Rephrase and Respond first -- zero-shot, training-free, minimal overhead.

**Need implicit reasoning without explicit CoT:** Use Role-Play Prompting with task-advantaged role.

**Context being ignored for memorized facts:** Use Context-faithful Prompting (opinion-based reframing) with counterfactual demonstrations.

**Multi-perspective synthesis needed:** Use Multi-expert Prompting for diverse expertise, or Argument Generation for smaller models.

**Detailed problem requiring principles:** Use Step-Back Prompting to abstract first, then reason.

**Conditional reasoning with if-then rules:** Use Code Prompting to transform rules into code representation for better state tracking.

**Style/preference alignment:** Use Contrastive In-Context Learning with positive/negative pairs.

**Simple domain expertise:** Use ExpertPrompting for automatic expert identity generation.

**Multi-step agentic workflows:** Use Anticipatory Reflection to prepare backup actions before execution, enabling recovery without full replanning.

**Getting stuck on single reasoning path:** Use Multi-Perspective Reasoning to explore diverse framings and select via agreement scoring.

**Creating reusable prompts for repetitive tasks:** Use Conversational Prompt Refinement to iteratively shape instructions and collect few-shot examples through feedback.

**Avoid:** Generic persona prompts on factual tasks -- they provide no benefit and may harm performance.

---

## Composability Notes

**Rephrase and Respond + CoT:** Explicitly complementary. RaR clarifies the question, CoT handles reasoning. Combine by adding "let's think step by step" to RaR prompt.

**Role-Play + Self-Consistency:** Can be combined. Role-play acts as implicit CoT trigger; self-consistency samples diverse reasoning paths.

**Context-faithful + Counterfactual Demonstrations:** Best used together. Opinion-based prompts + counterfactual examples yield largest faithfulness gains.

**ExpertPrompting + Multi-expert:** Multi-expert extends ExpertPrompting by generating multiple identities and aggregating their responses.

**Step-Back + CoT:** Sequential -- abstraction retrieves principles, then standard reasoning applies them.

**Code Prompting + CoT:** Complementary. Code transformation handles state tracking; CoT can be applied to the code-formatted input for additional reasoning structure.

**Code Prompting + Few-shot:** Code prompts are more sample-efficient than text prompts — achieves same performance with fewer demonstrations.

**Contrastive ICL + Standard Few-shot:** Contrastive replaces standard few-shot; uses same token budget more effectively with positive/negative pairs.

**Argument Generation + Larger Models:** Avoid -- may force convincing arguments for incorrect options. Best for models < 8B parameters.

**Anticipatory Reflection + Multi-step Agents:** Core pattern for agentic workflows. Pairs naturally with tool-use agents. Can wrap any action-generation approach with pre-execution remedy planning.

**Multi-Perspective Reasoning + Self-Consistency:** Related but distinct. Self-consistency samples the same reasoning multiple times; Multi-Perspective deliberately generates different framings. Multi-Perspective is more expensive but explores more diverse solution paths.

**Multi-Perspective Reasoning + Multi-expert:** Can be combined — experts provide perspectives, Navigator/Reasoner structure handles agreement scoring. Significant token overhead; use only when single-expert answers are unreliable.

**Conversational Prompt Refinement + Any Technique:** The output is a refined prompt that can incorporate any other technique. Use CPR to discover preferences, then embed techniques like CoT or Contrastive ICL into the final prompt.
