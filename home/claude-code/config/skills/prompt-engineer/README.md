# Prompt Engineer

Prompts are code. They have bugs, edge cases, and failure modes. This skill
treats prompt optimization as a systematic discipline -- analyzing issues,
applying documented patterns, and proposing changes with explicit rationale.

I use this on my own workflow. The skill was optimized using itself -- of
course.

## When to Use

- A sub-agent definition that misbehaves (agents/developer.md)
- A Python script with embedded prompts that underperform
  (skills/planner/scripts/planner.py)
- A multi-prompt workflow that produces inconsistent results
- Any prompt that does not do what you intended

## How It Works

The skill:

1. Reads prompt engineering pattern references
2. Analyzes the target prompt for issues
3. Proposes changes with explicit pattern attribution
4. Waits for approval before applying changes
5. Presents optimized result with self-verification

I use recitation and careful output ordering to ground the skill in the
referenced patterns. This prevents the model from inventing techniques.

## Example Usage

Optimize a sub-agent:

```
Use your prompt engineer skill to optimize the system prompt for
the following claude code sub-agent: agents/developer.md
```

Optimize a multi-prompt workflow:

```
Consider @skills/planner/scripts/planner.py. Identify all prompts,
understand how they interact, then use your prompt engineer skill
to optimize each.
```

## Example Output

Each proposed change includes scope, problem, technique, before/after, and
rationale. A single invocation may propose many changes:

```
  +==============================================================================+
  |  CHANGE 1: Add STOP gate to Step 1 (Exploration)                             |
  +==============================================================================+
  |                                                                              |
  |  SCOPE                                                                       |
  |  -----                                                                       |
  |  Prompt:      analyze.py step 1                                              |
  |  Section:     Lines 41-49 (precondition check)                               |
  |  Downstream:  All subsequent steps depend on exploration results             |
  |                                                                              |
  +------------------------------------------------------------------------------+
  |                                                                              |
  |  PROBLEM                                                                     |
  |  -------                                                                     |
  |  Issue:    Hedging language allows model to skip precondition                |
  |                                                                              |
  |  Evidence: "PRECONDITION: You should have already delegated..."              |
  |            "If you have not, STOP and do that first"                         |
  |                                                                              |
  |  Runtime:  Model proceeds to "process exploration results" without having    |
  |            any results, produces empty/fabricated structure analysis         |
  |                                                                              |
  +------------------------------------------------------------------------------+
  |                                                                              |
  |  TECHNIQUE                                                                   |
  |  ---------                                                                   |
  |  Apply:    STOP Escalation Pattern (single-turn ref)                         |
  |                                                                              |
  |  Trigger:  "For behaviors you need to interrupt, not just discourage"        |
  |  Effect:   "Creates metacognitive checkpoint--the model must pause and       |
  |             re-evaluate before proceeding"                                   |
  |  Stacks:   Affirmative Directives                                            |
  |                                                                              |
  +------------------------------------------------------------------------------+
  |                                                                              |
  |  BEFORE                                                                      |
  |  ------                                                                      |
  |  +----------------------------------------------------------------------+    |
  |  | "PRECONDITION: You should have already delegated to the Explore      |    |
  |  |  sub-agent.",                                                        |    |
  |  | "If you have not, STOP and do that first:",                          |    |
  |  +----------------------------------------------------------------------+    |
  |                                                                              |
  |                                    |                                         |
  |                                    v                                         |
  |                                                                              |
  |  AFTER                                                                       |
  |  -----                                                                       |
  |  +----------------------------------------------------------------------+    |
  |  | "STOP. Before proceeding, verify you have Explore agent results.",   |    |
  |  | "",                                                                  |    |
  |  | "If your --thoughts do NOT contain Explore agent output, you MUST:", |    |
  |  | "  1. Use Task tool with subagent_type='Explore'                     |    |
  |  | "  2. Prompt: 'Explore this repository. Report directory structure,  |    |
  |  | "     tech stack, entry points, main components, observed patterns.' |    |
  |  | "  3. WAIT for results before invoking this step again               |    |
  |  | "",                                                                  |    |
  |  | "Only proceed below if you have concrete Explore output to process." |    |
  |  +----------------------------------------------------------------------+    |
  |                                                                              |
  +------------------------------------------------------------------------------+
  |                                                                              |
  |  WHY THIS IMPROVES QUALITY                                                   |
  |  -------------------------                                                   |
  |  Transforms soft precondition into hard gate. Model must explicitly verify   |
  |  it has Explore results before processing, preventing fabricated analysis.   |
  |                                                                              |
  +==============================================================================+

  ... many more


  ---
  Compatibility check:
  - STOP Escalation + Affirmative Directives: Compatible (STOP is for interrupting specific behaviors)
  - History Accumulation + Completeness Checkpoint Tags: Synergistic (both enforce state tracking)
  - Quote Extraction + Chain-of-Verification: Complementary (both prevent hallucination)
  - Progressive depth + Pre-Work Context Analysis: Sequential (planning enables deeper execution)

  Anti-patterns verified:
  - No hedging spiral (replaced "should have" with "STOP. Verify...")
  - No everything-is-critical (CRITICAL used only for state requirement)
  - Affirmative directives used (changed negatives to positives)
  - No implicit category trap (explicit checklists provided)

  ---
  Does this plan look reasonable? I'll apply these changes once you confirm.
```

## Caveat

When you tell an LLM "find problems and opportunities for optimization", it will
find problems. That is what you asked it to do. Some may not be real issues.

I recommend invoking the skill multiple times on challenging prompts, but
recognize when it is good enough and stop. Diminishing returns are real.
