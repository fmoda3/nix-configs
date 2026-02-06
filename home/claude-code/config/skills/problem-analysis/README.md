# Problem Analysis

Root cause identification skill. This skill identifies WHY a problem occurs. It
explicitly does NOT propose solutions -- that is a downstream concern for a
separate skill (solution-discovery).

## When to Use

Use this when you need to understand the cause of a problem:

- User reports "X happens when they do Y"
- Component A fails under condition B
- System exhibits unexpected behavior
- Bug needs investigation before fixing

Do NOT use this for:

- Choosing between known solutions (use decision-critic)
- Evaluating architectural options (use decision-critic)
- Problems where the cause is already known

## The Five Phases

| Phase       | Purpose                                           |
| ----------- | ------------------------------------------------- |
| Gate        | Validate input, establish single testable problem |
| Hypothesize | Generate 2-4 distinct candidate explanations      |
| Investigate | Iterative evidence gathering (up to 5 iterations) |
| Formulate   | Synthesize findings into validated root cause     |
| Output      | Structured report for downstream consumption      |

## Invisible Knowledge

This section captures design decisions that cannot be inferred from code.

### Why the Original Skill Was Wrong

The original skill was titled "problem-analysis" but was actually a solution
evaluation workflow. Its very first phase instructed the LLM to "GENERATE 2-4
DISTINCT solutions." This violates the fundamental purpose of root cause
analysis, which must understand the problem before considering solutions.

### The Problem/Solution Boundary

Root causes must be framed as conditions that exist, not as absences of
solutions. When you ask "why?" repeatedly during root cause analysis, you can
drift from describing observable states to describing what's missing. The moment
you frame something as "we don't have X" or "there's no Y," you've implicitly
proposed a solution (get X, add Y) rather than identified a cause.

| Wrong (Absence)            | Correct (Condition)                                   |
| -------------------------- | ----------------------------------------------------- |
| "We don't have validation" | "User input reaches processing without sanitization"  |
| "Missing retry logic"      | "Failed requests terminate immediately without retry" |
| "No rate limiting"         | "The API accepts unbounded requests per client"       |
| "Lack of monitoring"       | "Component failures propagate silently until impact"  |

The correct framing describes observable reality and leaves multiple solution
paths open. The wrong framing presupposes a specific solution.

### Why Self-Reported Confidence Doesn't Work

LLMs have no calibrated introspective access to their own certainty. Asking "how
confident are you?" produces unreliable answers because the model is pattern-
matching on what confident-sounding language looks like, not measuring actual
epistemic state.

The solution is to derive confidence from factual criteria: instead of "how sure
are you?", we ask "can you answer YES to these specific questions about your
analysis?"

### Why "Certain" Is Not a Valid Target

You can only truly confirm a root cause after implementing a fix and observing
that the symptom disappears. Before that, you're working with hypotheses of
varying confidence. Requiring "certainty" as an exit condition either blocks the
workflow indefinitely or encourages the LLM to falsely claim certainty.

The practical goal is "sufficient confidence to proceed to solution discovery,"
which we call HIGH confidence.

### Why Multiple Hypotheses Matter

Investigation with only one hypothesis produces confirmation bias. You find
supporting evidence whether or not the hypothesis is correct because you're only
looking for evidence that supports it. Generating multiple hypotheses before
investigating forces comparative evaluation and prevents tunnel vision.

The requirement is at least two hypotheses that differ on mechanism or location,
not just phrasing variations.

### The Iteration Cap Rationale

The investigation phase uses an iterative loop with a maximum of 5 iterations.
This cap exists because root cause analysis could theoretically continue forever
(you can always ask another "why?"). The cap forces eventual termination while
allowing enough depth for meaningful investigation.

Five iterations is a balance: enough to go beyond surface-level analysis, not so
many that the skill becomes unwieldy.

### Script-Managed Iteration

The iteration count is managed by the script, not the LLM. The LLM reports its
findings and confidence criteria; the script increments the iteration counter
and determines whether to continue or proceed to the next phase.

This prevents the LLM from miscounting or gaming the iteration limit.

### The Four Readiness Questions

Confidence is derived from four factual questions about the analysis:

| Question     | Criterion                                                |
| ------------ | -------------------------------------------------------- |
| Evidence     | Can you cite specific code/config/docs supporting cause? |
| Alternatives | Did you examine at least one alternative hypothesis?     |
| Explanation  | Does the root cause fully explain the symptom?           |
| Framing      | Is root cause a positive condition (not absence)?        |

Scoring:

- YES = 1 point, PARTIAL = 0.5 points, NO = 0 points
- 4 points = HIGH (ready to proceed)
- 3-3.5 = MEDIUM
- 2-2.5 = LOW
- <2 = INSUFFICIENT

Question 4 (Framing) has no partial credit. If framing is wrong, it must be
fixed before proceeding.

## Example Usage

```
A user reported that their session expires immediately after login on mobile
devices, but works fine on desktop. Figure out why this is happening.
```

The skill will:

1. Gate: Validate this is a single, well-defined problem
2. Hypothesize: Generate candidates (cookie handling, token storage, etc.)
3. Investigate: Examine code for each hypothesis
4. Formulate: Synthesize into root cause statement
5. Output: Structured report for solution discovery

## Implementation Notes

The workflow uses `skills.lib.workflow.formatters.text` for output formatting.
Phase 3 uses `build_invoke_command()` with dynamic `--iteration` parameter
computed by the script.
