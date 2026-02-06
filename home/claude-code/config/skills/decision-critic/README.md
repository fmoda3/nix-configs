# Decision Critic

Here's the problem: LLMs are sycophants. They agree with you. They validate your
reasoning. They tell you your architectural decision is sound and well-reasoned.
That's not what you need for important decisions -- you need stress-testing.

The decision-critic skill forces structured adversarial analysis:

| Phase         | Actions                                                                    |
| ------------- | -------------------------------------------------------------------------- |
| Decomposition | Extract claims, assumptions, constraints; assign IDs; classify each        |
| Verification  | Generate questions for verifiable items; answer independently; mark status |
| Challenge     | Steel-man argument against; explore alternative framings                   |
| Synthesis     | Verdict (STAND/REVISE/ESCALATE); summary and recommendation                |

## When to Use

Use this for decisions where you actually want criticism, not agreement:

- Architectural choices with long-term consequences
- Technology selection (language, framework, database)
- Tradeoffs between competing concerns (performance vs. maintainability)
- Decisions you're uncertain about and want stress-tested

## Example Usage

```
I'm considering using Redis for our session storage instead of PostgreSQL.
My reasoning:

- Redis is faster for key-value lookups
- Sessions are ephemeral, don't need ACID guarantees
- We already have Redis for caching

Use your decision critic skill to stress-test this decision.
```

So what happens? The skill:

1. **Decomposes** the decision into claims (C1: Redis is faster), assumptions
   (A1: sessions don't need durability), constraints (K1: Redis already
   deployed)
2. **Verifies** each claim -- is Redis actually faster for your access pattern?
   What's the actual latency difference?
3. **Challenges** -- what if sessions DO need durability (shopping carts)?
   What's the operational cost of Redis failures?
4. **Synthesizes** -- verdict with specific failed/uncertain items

## The Anti-Sycophancy Design

I grounded this skill in three techniques:

- **Chain-of-Verification** -- factored verification prevents confirmation bias
  by answering questions independently
- **Self-Consistency** -- multiple reasoning paths reveal disagreement
- **Multi-Expert Prompting** -- diverse perspectives catch blind spots

The structure forces the LLM through adversarial phases rather than allowing it
to immediately agree with your reasoning. That's the whole point.
