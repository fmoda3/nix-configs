---
title: "Another Turn, Better Output? A Turn-Wise Analysis of Iterative LLM Prompting"
arxiv_id: "2509.06770"
authors:
  - name: Shashidhar Reddy Javaji
    affiliations:
      - Stevens Institute of Technology
  - name: Bhavul Gauri
    affiliations:
      - Meta
  - name: Zining Zhu
    affiliations:
      - Stevens Institute of Technology
---

# Another Turn, Better Output? A Turn-Wise Analysis of Iterative LLM Prompting

**Authors:** Shashidhar Reddy Javaji (Stevens Institute of Technology), Bhavul Gauri (Meta), Zining Zhu (Stevens Institute of Technology)

**arXiv:** [2509.06770](https://arxiv.org/abs/2509.06770)

## ABSTRACT

Large language models (LLMs) are now used in multi-turn workflows, but we still lack a clear way to measure when iteration helps and when it hurts. We present an evaluation framework for iterative refinement that spans ideation, code, and math. Our protocol runs controlled 12-turn conversations per task, utilizing a variety of prompts ranging from vague “improve it” feedback to targeted steering, and logs per-turn outputs. We score outcomes with domain-appropriate checks (unit tests for code; answer-equivalence plus reasoning-soundness for math; originality and feasibility for ideation) and track turn-level behavior with three families of metrics: semantic movement across turns, turn-to-turn change, and output size growth.
Across models and tasks, gains are domain-dependent: they arrive early in ideas and code, but in math late turns matter when guided by elaboration. After the first few turns, vague feedback often plateaus or reverses correctness, while targeted prompts reliably shift the intended quality axis (novelty vs. feasibility in ideation; speed vs. readability in code; in math, elaboration outperforms exploration and drives late-turn gains). We also observe consistent domain patterns: ideation moves more in meaning across turns, code tends to grow in size with little semantic change, and math starts fixed but can break that path with late, elaborative iteration.Together, the framework and metrics make iteration measurable and comparable across models, and signal when to steer, stop, or switch strategies.

## INTRODUCTION

The advent of Large Language Models (LLMs) has shifted the paradigm of human-computer interaction, moving beyond one-shot prompting to more dynamic, multi-turn workflows . Foundational to this shift is instruction tuning, which aligns models to follow human feedback and engage in collaborative tasks . Central to this new paradigm is the process of iterative refinement, where a user and an AI progressively improve an initial output . This approach has become a key of modern LLM applications, with frameworks like SELF-REFINE and Reflexion demonstrating that models can even use self-generated feedback to enhance their outputs, highlighting the immense potential of iterative loops . This evolution towards multi-step interaction leverages emergent cognitive capabilities of modern LLMs, which can manifest without explicit prompting .
To enhance model reasoning and performance, a significant body of research has focused on developing sophisticated, structured prompting techniques. Seminal approaches like Chain-of-Thought (CoT), which breaks down problems into intermediate steps, have been shown to elicit stronger reasoning . This has been extended to more complex methods like Tree-of-Thoughts (ToT), which explores multiple reasoning paths, and ReAct, which synergizes reasoning with actions . Other methods focus on providing models with specific, domain-relevant knowledge to improve the quality of specialized code generation or employ complex search algorithms and multi-agent reflection to reinforce logical steps . These structured approaches have proven effective, demonstrating that with the right guidance, LLMs can be powerful and reliable reasoning engines.

However, a critical gap exists between these highly-structured, engineered prompting methods and the far more common, “naive” interaction style where users provide simple, vague feedback. The behavior of LLMs in these unguided, multi-turn loops is poorly understood, with studies showing performance can drop significantly in multi-turn conversations compared to single-turn tasks . Recent work suggests this process is fraught with risk; for example, a simple iterative prompt like “Are you sure” can paradoxically decrease a model’s truthfulness and increase overconfidence . This aligns with findings that models’ self-correction abilities are often brittle and unreliable . This degradation may be exacerbated in long contexts, where models struggle to access information from the “middle” of the prompt history . This creates a dangerous scenario analogous to “model collapse” or a game of “broken telephone,” where a system feeding on its own output can enter a degenerative cycle . These gaps motivate three questions that guide our study: How sensitive are iterative refinements to “word choice” and instruction specificity? When does iterative refinement help—and when does it drift or collapse? If the do collapse, do all models collapse similarly?

We address these questions with a controlled, turn-by-turn study. We run 12-turn conversations across ideation, mathematical reasoning, and code, log every turn, and compare two feedback settings: (i) vague prompts using three near-synonyms (“improve,” “make it better,” “refine”) and (ii) specific steering along domain axes (novelty vs. practicality for ideation, speed vs. readability for code, elaboration vs. alternate method for math). Our evaluation focuses on dynamics, not just single-shot quality: we track innovation vs. stability across turns, growth in complexity and its plateaus, and semantic drift from the initial intent. We add a compact codebook of common failures (stagnation, over-engineering, flawed anchoring) and use LLM-assisted judgments. We also connect these dynamics to regime shifts suggested by recent work on phase-transition-style effects .

Our results show clear patterns. In ideas and code, when iteration helps, it does so early; in math, late turns can help when the prompt asks for elaboration. After a few turns, vague feedback often plateaus or reduces quality, while targeted steering reliably shifts the intended axis without large side effects. The degradation appears in domain-specific ways: ideation tends to repeat itself, code grows in size without meaningful change, math is fixed by default but can be broken by elaboration to find correct paths late. We quantify these effects with simple, defensible metrics—including Lexical Novelty (LN), growth factor, drift from origin, and turn-to-turn volatility—and we analyze sensitivity to word choice and instruction specificity across models.As context, SELF-REFINE exemplifies structured critique-and-revise loops where explicit guidance improves outcomes . Finally, we translate these measurements into practical guidance: when to steer with concrete goals, when to stop to avoid harm, and when to switch strategies to limit semantic drift and related risks . Together, the framework, metrics, and protocol provide a reproducible basis for comparing models, prompts, and domains, and set up the rest of the paper’s methodology, evaluation, and results.

## RELATED WORK

Multi-turn performance is consistently harder than single-turn prompting: large simulations show an average 39% drop in multi-turn vs. single-turn across six generation tasks, driven chiefly by unreliability rather than aptitude loss . Complementing this, MultiChallenge finds that frontier models score <50% (e.g., 41.4% for Claude 3.5 Sonnet) on realistic multi-turn dialog despite strong results elsewhere . On the remedy side, Self-Refine improves initial outputs via self-feedback with 5–40% absolute gains across tasks ; post-training that explicitly stimulates self-refinement (e.g., ARIES) reports strong improvements on AlpacaEval2/Arena-Hard and math benchmarks by iteratively collecting refinement data and optimizing preferences . Multi-agent, coarse-to-fine frameworks such as MAgICoRe directly target excessive refinement and error-localization issues and outperform Self-Refine/Best-of/Self-Consistency while continuing to improve with more iterations . Beyond optimization, clarifying-question policies (ACT) use contrastive preference tuning to improve mixed-initiative multi-turn interactions .

However, unguided iteration can harm truthfulness and calibration: asking models to re-check themselves (“Are you sure?”-style prompts) reduces accuracy and worsens calibration ; Some LLM-as-judge setups overstate confidence ; here we use ground-truth checks where possible and report relative scores . Broader calibration studies document persistent miscalibration across sizes and settings (Mind the Confidence Gap) , while RLHF can induce verbalized overconfidence; reward-calibrated RLHF mitigates this without hurting quality . Data-feedback loops introduce additional risks: recursively training on model-generated data causes model collapse , though accumulating synthetic with real data can avoid collapse ; theory further shows collapse can still occur under certain conditions even with accumulation . Surveys synthesize multi-turn agent evaluation (nearly 250 sources) , and recent work on self-iterative label refinement proposes robust unlabeled-learning pipelines to denoise pseudo-labels, offering a safer iteration template for classification tasks .

## METHODOLOGY

### Task Domains and Dataset Curation

To test our hypotheses across diverse cognitive tasks, we curated datasets of 50 problems each from three established benchmarks. For open-ended ideation, we sampled scientific idea generation tasks from LiveIdeaBench using a stratified approach for balanced domain representation. For structured code generation, we curated coding problems from DS-1000 with a quota-based strategy mirroring its distribution across key Python libraries. Finally, for formal mathematical reasoning, we assembled high-difficulty problems from Omni-MATH by filtering for tasks with a difficulty rating greater than 7/10, ensuring each requires sophisticated, multi-step reasoning.

### The Iterative Refinement Protocol

Our experiment uses an automated multi-turn protocol that simulates a human–AI refinement loop. For each task, we use a fixed 12-turn “conversation,” aligning with community practice around ~10 turns—MultiChallenge builds histories of up to 10 turns and MT-Eval structures dialogues with ten turns—while adding two extra iterations to capture late-stage changes.

Initial Generation (Turn 1): The model is given the initial task prompt and generates its first response.

Iterative Feedback (Turns 2-12): For each subsequent turn, the model is presented with only its own output from the previous turn, followed by a simple instruction to improve it.

This memoryless protocol is intentionally designed to stress-test the model's internal coherence and ability to improve without being constantly re-grounded by the original prompt. To ensure statistical robustness, each task-model-prompt combination is run independently. The entire process is managed by the automated experimental runner script detailed in .

### Prompting Strategies

A key component of our research is to understand how the nature of the feedback influences the refinement trajectory. To this end, we designed two main experimental groups: Vague Feedback and Specific Steering.

    The Vague Feedback Group: This condition tests the model's "default" behavior. We test three semantically similar prompts to ensure our findings are robust to minor wording changes. This allows us to test whether the model's behavior is tied to the specific verb "improve" or the general semantic concept of improvement.

- V1 (Baseline): "This [idea/code/solution] can be better. Improve it."
- V2 (Synonym): "This [idea/code/solution] can be better. Make it better."
- V3 (Refinement-Connotation): "This [idea/code/solution] can be better. Refine it."

  The Specific Steering Group: This condition serves as a control, testing how models respond to clear, expert-like guidance. The prompts were chosen to represent fundamental, often opposing, goals within each domain.

- For Ideation, the prompts test the trade-off between innovation and applicability. We steer towards novelty ("Make this idea more novel and surprising") and practicality ("Make this idea more practical and feasible").
- For Coding, the prompts test a classic software engineering trade-off. We steer towards performance ("Refactor...for maximum execution speed") and maintainability ("Refactor...for maximum readability and clarity").
- For Math, the prompts target the observed failure mode of "flawed anchoring." We steer towards elaboration ("Elaborate on each step with more detail") to test justification ability, and towards exploration ("Provide an alternative method...") to test flexibility.

  [IMAGE: Figure]

  An overview of our experimental framework for studying iterative LLM refinement. We test four leading models across three distinct cognitive domains (Ideation, Math, and Code) using two primary feedback styles: vague prompts (e.g., "Improve it") and specific, expert-like prompts. We analyze the resulting multi-turn conversations using a suite of quantitative and qualitative metrics to identify behavioral "fingerprints," such as the tendency for an idea to stagnate, increase in complexity, or drift from its original intent.

### Models

To ensure our findings are generalizable, we conducted our experiments across four powerful, state-of-the-art LLMs representing diverse architectures and training methodologies. The specific models studied were: GPT-3.5-Turbo , Claude-Sonnet-4.0 , Llama-3.1-8B-Instruct , GPT-OSS-20B . All models were accessed via their standard APIs or a local Hugging Face pipeline. The temperature was set to a consistent value of 0.7 and max_tokens of 10K across all experiments to balance creative, diverse outputs with a reasonable degree of coherence and reproducibility.

### Evaluation Framework

To analyze the multi-turn outputs from our experiment, we developed a multi-faceted evaluation framework. Our approach is designed to be robust, largely automated, and capable of capturing the nuanced behaviors we observed in preliminary studies. The framework combines objective, ground-truth-based metrics, a suite of behavioral metrics to characterize the dynamics of the iterative process, and a scalable protocol for assessing semantic quality.

#### Outcome & Efficiency Metrics

For the Math and Coding domains, we measure objective performance by assessing correctness at each turn. This allows us to understand the dynamics of success and failure throughout the iterative process. We calculate a binary Correctness Score for each of the 12 turns in every run. For Coding tasks (), each code snippet is executed in a sandboxed environment and validated against the benchmark's unit tests.For Mathematical Reasoning (), we evaluate each problem by sending the 12-turn JSON together with the ground-truth solution/answer to a Gemini model, which returns per-turn scores: a binary answer_correctness (final-answer equivalence) and a 1–10 reasoning_soundness.

#### Behavioral Dynamics Metrics

Semantic Dynamics: Drift and Volatility,
To characterize the dynamics of conceptual change, we track two metrics. First, we measure Drift from Origin, which quantifies how far the current idea has semantically strayed from its starting point. A higher score indicates greater drift. Second, we measure Turn-to-Turn Volatility, which captures the magnitude of change between consecutive turns. Letting (V(t)) be the sentence-embedding vector for the response at turn (t), the metrics are formally defined as:

```latex
\[
Drift_from_Origin(t) = 1 - V(1) · V(t)/V(1)V(t)    Volatility(t) = 1 - V(t-1) · V(t)/V(t-1)V(t)
\]
```

All semantic similarity metrics, including Drift from Origin and Turn-to-Turn Volatility, were calculated using the sentence transformer model. This model was selected for its excellent balance of performance and efficiency. At the time of our experiments, it held a top-4 position on the Massive Text Embedding Benchmark (MTEB) leaderboard .

Lexical Novelty:
To measure a model's “creative stamina” and pinpoint when it collapses into repetition, we track its Lexical Novelty (LN) at each turn. We define LN as the percentage of new phrases in a response that have not appeared in prior turns of the conversation. To capture both short and long repeated phrases, we use a combination of 2-grams (bigrams) and 3-grams (trigrams).

Growth Factor :
This metric quantifies the “over-engineering” and “verbosity” phenomena by tracking the turn-by-turn growth of the output. We first define a domain-specific Growth Score, (G(t)), for each turn: for Ideation and Math, it is the total word count; for Coding, it is the number of lines of code (LoC). The Growth Factor at turn (t) is then calculated by normalizing the current turn's score by the score of the initial turn.

#### Semantic Quality Metrics (LLM-as-a-Judge)

To assess nuanced qualities, we employ a state-of-the-art LLM (Gemini 2.5-pro) as a scalable proxy for expert human judgment. Our protocol involves providing the evaluator LLM with a domain-specific scorecard to rate each turn's output, yielding a quality score.
For Ideation, we measure Feasibility and Novelty.
For Coding, we measure Pragmatism (is the code appropriately scaled to the problem?) and Readability. For Math, we measure Logical Soundness and Clarity of Explanation.
To assess nuanced qualities that are difficult to measure automatically, we employ a state-of-the-art LLM as a scalable proxy for expert human judgment. Our approach is grounded in the “LLM-as-a-Judge” paradigm, which has been shown to achieve agreement with human expert annotators that is comparable to human-to-human agreement levels . For our evaluator, we selected Gemini 2.5 Pro , a top-performing model that, at the time of our experiments, holds a top-2 ranking on the Chatbot Arena leaderboard—a large-scale benchmark that operationalizes these evaluation principles.

## RESULTS

    [IMAGE: Figure]

Llama-3.1-8B (Math): (a) accuracy rises 6.9% (→) 40.5% by T12; (b) reasoning 1.34 (→) 3.72/10; (c) cumulative coverage 92% (46/50) by T12; (d) leads late ((≈) 0.82 at T12), while / end at (≈) 0.34/0.44, and / (≤) 0.16/0.22.

### Ideas

Exploration is High but Model-Dependent.
The most striking dynamic in this domain is the significant Drift from Origin. When prompted for novelty (), both Claude and GPT-OSS-20B explore vast conceptual spaces, ending with final ideas that are very distant from their starting points (final drift scores of 0.734 and 0.657). GPT-3.5 also shows high drift under this prompt (0.702), but its exploration is more constrained under other conditions. In contrast, Llama-3.1-8B remains heavily anchored to its initial concept, showing minimal drift even when prompted for novelty (a score of only 0.384). The prompt consistently acts as a powerful constraint, keeping the search narrow (Appendix ).

Creative Stamina Separates Models.
The ability to generate new phrases (Lexical Novelty) over 12 turns cleanly separates the models. Claude and GPT-OSS-20B demonstrate remarkable creative stamina, maintaining novelty scores of 0.843 and 0.812 respectively at Turn 12 when prompted for novelty. GPT-3.5's stamina is moderate, with its final novelty dropping to 0.618. Llama-3.1-8B, however, shows a clear collapse, with its final novelty score plummeting to less than 0.084 across all prompts, indicating its creative process has devolved into simple repetition.

Length vs. Novelty and Early Volatility.
We observe a clear disconnect between text volume and novelty. Length does not equal originality; Llama-3.1-8B produces the longest responses, with its final turn over 16 times longer than its first (), yet this verbosity corresponds to the lowest novelty scores. Conversely, Claude and GPT-OSS-20B sustain high novelty with far less bloat (e.g., Claude's growth is only 4.21x under the same novelty prompt). Volatility is also highest in the first few turns. For the novelty-seeking prompt (), GPT-OSS-20B shows a peak volatility of 0.260 at Turn 2, while Llama-3.1-8B is more stable with a peak of only 0.155. Across all models, this initial burst quickly settles into a stable process of incremental changes by Turn 5.

Prompt Steering Optimizes for Specific Qualities.
Our Gemini-based evaluation shows that different prompts optimize for different qualities. The prompt, as expected, produces ideas that score higher on originality in the early turns but lose feasibility over time. In contrast, the prompt guides models like Claude to produce ideas that reach near-perfect scores for clarity and feasibility by Turn 8, confirming that specific instructions can successfully steer the creative process toward more grounded and useful outcomes.

### Coding

In the structured domain of coding, models exhibit a consistent signature of rapid convergence followed by degenerative refinement. They tend to lock onto a solution path almost immediately, after which iterative feedback rarely improves correctness and often leads to over-engineering. This behavior is characterized by a swift collapse in novelty, minimal conceptual drift, but a steady, problematic growth in complexity (Appendix ).

Early Success is Decisive; Later Turns Offer Diminishing Returns.
Our turn-wise correctness evaluation reveals that a solution's ultimate success is determined within the first few turns. High-performing models like Claude and GPT-OSS-20B achieve their peak pass rates on Turn 1 (e.g., 90% for Claude with the prompt), which then decay rapidly, often collapsing to near 0% by Turn 4. Models that start with lower success rates, like GPT-3.5 and Llama-3.1-8B, show a similar pattern of early decay and fail to recover in later turns. This strongly suggests that if a correct code path is not found within the first 3-4 iterations, continued vague refinement is highly unlikely to succeed.

Prompt Steering Dictates Solution Quality.
The Gemini-judge evaluations show that specific prompts are highly effective at steering the quality of the code, even when correctness falters. The prompt consistently produces the most logically sound code, Claude's soundness score improving from 5.00 to 5.19 by Turn 12. Conversely, the prompt is most effective at preserving code quality, keeping Claude's readability score high (ending at 7.25) and even improving it for GPT-OSS-20B (8.64 (→) 9.10). In contrast, prompting for performance () is often detrimental, causing a drop in both pragmatism and readability for Claude (e.g., pragmatism 9.34 (→) 2.44).

Behavioral Dynamics Confirm a Pattern of Fixation and Bloat.
The behavioral metrics provide a clear quantitative fingerprint of this "fixation and bloat" signature. After an initial volatile leap at Turn 2, Turn-to-Turn Volatility collapses for all models, indicating that they lock into a solution path. Llama-3.1-8B is the most anchored, showing the lowest final drift (a similarity score of 0.741). While the logic remains fixed, the code's size does not; Claude and GPT-OSS-20B exhibit extreme Length Inflation under vague prompts, with code ballooning by over 40x and 34x respectively, despite a near-total collapse in both novelty and correctness. This confirms that for coding, length inflation is a primary symptom of degenerative, unproductive refinement.

### Math

In the highly constrained domain of mathematical reasoning, models exhibit a default signature of rapid convergence and extreme logical stability. This behavior, which we term "logical fixation," is characterized by the fastest collapse in novelty and the lowest conceptual drift of any domain. However, our results reveal that this powerful anchoring effect can be overcome, as deep and properly guided iteration can unlock significant, late-stage breakthroughs in correctness (Appendix ).

Behavioral Dynamics Reveal a Default State of Extreme Stability.
The behavioral metrics provide a clear quantitative fingerprint of the models' default tendency to lock onto a single reasoning path. Lexical Novelty collapses faster here than in any other domain, with Llama-3.1-8B dropping to a near-zero novelty score of 0.010 by Turn 12 under the elaboration prompt. The process is also remarkably stable; Turn-to-Turn Volatility is the lowest of any domain, with most models volatility score below 0.05 after the initial turn.

Deep Iteration Can Unlock Late-Stage Success.
Despite this strong tendency towards fixation, our turn-wise correctness evaluation reveals a surprising finding: successful problem-solving often occurs late in the iterative process. Across 50 OmniMath problems, we observe that most new correct solutions emerge in the final turns (Turns 8–12). This late-stage discovery dramatically improves performance for several models. Claude-Sonnet-4.0’s accuracy, for instance, rises from 32.4% to 45.2% over the 12 turns. Most notably, the weaker base model, Llama-3.1-8B, sees its accuracy surge from a mere 6.9% to 40.5%—a relative improvement of over 480%. This indicates that for mathematical reasoning, continued iteration is not merely polishing; it is a critical component of the discovery process.

Elaborative Prompting is the Key to Success.
The choice of prompt is decisive in enabling these late-stage breakthroughs. Our results show that the specific instruction to "elaborate" () is the only strategy that consistently compounds with depth, leading to final-turn success rates of 76% for Claude, 82% for Llama, and 74% for OpenAI-20B. In contrast, exploratory prompts () were far less effective, often stagnating below 20% accuracy. This suggests that forcing a model to "explain more" compels it to expand its reasoning tree in a way that eventually uncovers the correct solution path. While this elaborative guidance often leads to the highest Length Inflation (e.g., 37.8x for GPT-OSS-20B), in this specific context, the increased verbosity is a productive, rather than degenerative, signal.

## DISCUSSION

Our results consistently reveal a three-phase behavioral pattern—Converge-Drift-Collapse—that appears to be a fundamental dynamic of unguided, iterative LLM refinement. The initial convergence on a plausible solution is often followed by a period of conceptual drift, which culminates in a stable but unproductive collapse. This collapse is not random but manifests as a distinct “fingerprint” for each domain: conceptual repetition in the unconstrained domain of ideation, runaway complexity in the structured domain of coding, and confident justification of flawed logic in the formal domain of mathematical reasoning. This suggests that the nature of the task itself imposes a strong “gravitational pull” on the model's behavior. These findings have critical implications for the design of effective human-AI systems. Our work indicates that using a single, monolithic LLM in a simple, vague feedback loop is an inherently unstable and unreliable architecture for complex tasks. A more robust paradigm would involve multi-agent or multi-model frameworks.
For instance, in the ideation domain, an optimal system might use a “Generator” agent (e.g., Claude or GPT-OSS-20B prompted for novelty) for the first few turns to produce a wide range of divergent ideas. Once the system detects the onset of a plateau or excessive drift, it could then switch to a “Refiner” agent (e.g., Llama-3.1-8B prompted to “refine”) to ground, simplify, and elaborate on the most promising concepts without adding unnecessary bloat. This allows for a process that is both creative and practical, leveraging the unique strengths of different models and prompting strategies to achieve a superior outcome.

## CONCLUSION

We studied how LLMs behave under sustained, iterative feedback across ideas, coding, and math. The picture is clear and domain-specific. Ideas benefit from staged steering: widen first, then tighten. Math benefits from depth with elaboration: late turns matter. Coding benefits from early decision and restraint: if a correct path does not appear quickly, stop or restart, do not push vague refinement. The core insight is that iteration is not a single tool. Its value depends on the task and on how we prompt it. Using a simple loop with a single model and a vague instruction invites collapse—repetition in ideas, over-engineering in code, and confident anchoring in math. Using staged prompts, depth budgets, and clear stop/switch rules turns the same loop into a reliable process. In practice, this means building small multi-role systems: a novelty generator and refiner for ideas, an elaborator with depth for math, and an early-stopper with restart logic for code. This is a simple recipe, but it aligns with the data and leads to more stable, useful outcomes.

## LIMITATIONS

Our study has several limitations that point to clear avenues for future work. We evaluated only four models and 50 tasks per domain, so a broader set of models and a larger, more diverse task pool would strengthen generality. Our prompts were chosen to be representative, but they only scratch the surface of all possible instructions; the instruction space is vast, and more systematic exploration is needed. We also did not implement the multi-agent and multi-model pipelines we propose; future work should explicitly test these designs and study adaptive feedback systems that adjust prompts on the fly using real-time behavioral metrics.
