# pi-auto-router

Two [virtual models](https://pi.dev/docs/latest/virtual-models) for pi (1.0+). Select one and each session is routed to a model and thinking effort chosen for the work:

| Model | Available when | Routes on |
|---|---|---|
| `anthropic/auto-claude` — *Auto (Claude)* | you are signed in to `anthropic` | the [Claude ladder](#what-it-routes-to): Haiku 4.5, then Opus 5.5 from `low` to `max` effort |
| `openai-codex/auto-gpt` — *Auto (GPT)* | you are signed in to `openai-codex` | the [GPT ladder](#what-it-routes-to): GPT-6 Luna → Sol → Astra |

```bash
pi --model anthropic/auto-claude      # or pick it in /model, or set it as your default
```

Each auto model is listed under the provider that serves its ladder, so pi shows it exactly when that provider has credentials (`/login anthropic`, `/login openai-codex`). The router only classifies on, and dispatches to, models of that same provider: a prompt typed into `auto-gpt` never goes to Anthropic, or the other way round.

Selecting the model **is** the opt-in. There is nothing to enable, no family to choose, and no picker to answer: pick a physical model when you want to choose yourself, and an auto model when you want it chosen for you.

## What happens

On the first prompt of a session, a small fast model judges how demanding the request is and the matching route is applied straight away. Both steps are recorded in the conversation, right after your prompt:

```
 [Auto (Claude)] ⋯ Assessing route…
 [Auto (Claude)] Routed to Claude Opus 5.5 · high thinking (complex)
 Why: Touches auth and billing together, so a mistake is expensive.
```

The first block appears while the classifier runs (~1–2s); the second when the route is chosen.

### The routing record

Every routing event is kept as a block in the transcript, so anyone reading the session later can see how the model changed and why:

| Block | When |
|---|---|
| `⋯ Assessing route…` | the classifier starts (first prompt of a session) |
| `Reading context first: routed to …` | the prompt only points at its scope; scouting until it has been read (see [below](#prompts-that-point-elsewhere)) |
| `⋯ Assessing route with what was read…` | the classifier runs again, with what the agent read |
| `Routed to …` | the classification is applied, with the rationale and any adjustment |
| `Effort high: routed to …` | a later prompt moved because you changed the thinking level |
| `Route suggestion skipped — …` | classification failed or was cancelled, with the fallback used |

The blocks are **custom session entries** (`customType: "auto-router.route"`): saved on the session branch, so they reappear after a resume and follow forks and `/tree`, but never sent to the model, so they cost no context. They're shown in interactive mode; in print and JSON modes they're still written to the session file.

The decision holds for the rest of the session. Later prompts, tool follow-ups and retries all go to the same model, so the prompt cache stays warm and the classifier runs once, not once per message. **Your prompt is never modified**, and the classifier call is a side-channel: it sends only a truncated copy of your latest prompt, with no tools and no history, and does not touch your context window.

### Prompts that point elsewhere

A prompt like `implement PROJ-1234`, `fix the issue at <url>` or `do what docs/plan.md says` doesn't contain its own scope, so classifying it from the text alone would be a guess. The router **defers** the decision instead. It scouts when either:

- **the prompt names what defines the task** — a document (`.md`, `.txt`, `.pdf`, …), a URL, a ticket key like `PROJ-1234`, or an issue like `acme/api#812` or `issue #42`. This is a plain pattern match, so the same prompt always scouts, and there is no classifier call before the read; or
- **the classifier flags it** (`needs_context`) for pointers no pattern can see, like "the ticket we discussed".

Code files don't trigger it: a prompt that names `src/auth.ts` describes its own task, and reading code is the agent's normal work. Then:

1. The session starts on the **scout rung** — the `simple` level, Opus 5.5 · low or Luna · max — which is plenty for reading a ticket, an issue, a page or a file.
2. At the first request after the agent's first tool results, the classifier runs again with the prompt **and an excerpt of what was read** (each result capped at 3,000 characters, 8,000 in total), and the real level is stored.
3. The route switches there, mid-turn. That costs one prompt-cache miss; everything after it is sticky as usual.

```
 can you look at .pi/feature-ideas.md and see whats left to implement
 [Auto (Claude)] Reading context first: routed to Claude Opus 5.5 · low thinking (simple)
 The request names .pi/feature-ideas.md; classifying once it has been read.
 read .pi/feature-ideas.md
 [Auto (Claude)] ⋯ Assessing route with what was read…
 [Auto (Claude)] Routed to Claude Opus 5.5 · low thinking (simple)
 Why: Request asks to audit a feature-ideas document against code; document lists 4 numbered items…
 (classified after reading the context)
```

The router doesn't fetch anything itself — the agent does, with whatever tools it already has (Jira, `gh`, MCP servers, web fetch, `read`) — so it works for any source the agent can reach. The effort offset and the spend confirmation apply to the re-assessed level as usual; the scout rung is shifted by effort too, but never into a premium level. If the second classification fails, the rest of that turn stays put and the next prompt classifies afresh; if the agent answers without reading anything (a clarifying question, say), your reply is classified afresh. An incidental document reference ("follow the style in README.md") does scout — the pattern can't tell — which costs one step on the scout rung and one extra classification; prompts that describe their task in their own words don't.

pi's footer shows both halves — the selected auto model and the routed model — with the routed thinking level.

## Expensive routes still ask

The `hard` and `extreme` levels cost 2.6–4.6× a `moderate` route per task, so they need an explicit yes:

```
Use claude-opus-5-5 · max thinking?
The extreme route costs about 4.5× a moderate one per task. Route this session
to claude-opus-5-5 · max thinking? Declining routes to claude-opus-5-5 · high
thinking instead.
```

There is no "keep current" for a virtual model — the auto model *is* the current selection — so declining routes to the `complex` level instead. Without a UI to ask on (`pi -p`), the cheaper route is taken.

## What it routes to

The classifier never picks a model or an effort. It picks one of six **levels** — `trivial`, `simple`, `moderate`, `complex`, `hard`, `extreme` — and each level names one fixed **model + effort** pair on the family's ladder:

| Level | `auto-claude` | `auto-gpt` |
|---|---|---|
| `trivial` | `claude-haiku-4-5` · low | `gpt-6-luna` · medium |
| `simple` | `claude-opus-5-5` · low | `gpt-6-luna` · max |
| `moderate` | `claude-opus-5-5` · medium | `gpt-6-sol` · high |
| `complex` | `claude-opus-5-5` · high | `gpt-6-astra` · low |
| `hard` ⚠ | `claude-opus-5-5` · xhigh | `gpt-6-astra` · high |
| `extreme` ⚠ | `claude-opus-5-5` · max | `gpt-6-astra` · xhigh |

⚠ asks first — see [above](#expensive-routes-still-ask).

**Model and effort are chosen together because they overlap.** A bigger model at low effort is often both smarter *and* cheaper than a smaller one at high effort, since the smaller model burns far more reasoning tokens to get there. Every pair above is on the Pareto frontier of capability against measured cost per task; everything off it is never routed to. That is why Fable 5.1 does not appear (Opus 5.5 beats it at every effort for less), nor Sonnet 5 (beaten at every effort but `low`, where Opus 5.5 costs 8% more for 18 more points), and why thinking `off` is never used. Points are from the [Artificial Analysis Intelligence Index](https://artificialanalysis.ai/evaluations/artificial-analysis-intelligence-index) v4.3.2, cost per task at list price; the reasoning for each rung is in [`src/router/ladder.ts`](src/router/ladder.ts).

The ladders live in [`src/router/ladder.ts`](src/router/ladder.ts), with each rung's benchmark point alongside it. Each ladder strictly increases in both capability and cost, which is what "on the frontier" means.

Every rung of a ladder is served by one provider — `anthropic` for Claude, `openai-codex` for GPT — and the auto model is listed under it, so it is available exactly when you are signed in there. The router dispatches to any authenticated rung of that provider regardless of your `enabledModels` scope — the scope controls what you cycle between, and scoping down to `anthropic/auto-claude` alone should still reach the models behind it. The same model served by another provider (Bedrock, OpenRouter, …) is never used.

If a level's model is unavailable, the router uses another level's rung — cheaper levels first — and says so. A rung is always taken whole: a missing Opus sends `complex` to Haiku at Haiku's effort, never Haiku at `high`. If nothing on the ladder is available, the request fails with a message pointing at `/login anthropic` or `/login openai-codex`.

### How model ids are matched

Matching is **anchored equality on a normalized id**, not a substring test. `normalizeModelId` lower-cases the id and strips a date suffix, then compares exactly:

```
claude-haiku-4-5-20251001  ->  claude-haiku-4-5
gpt-6-sol                  ->  gpt-6-sol        (gpt-6.1-sol stays gpt-6.1-sol)
```

So `claude-opus-5-5` never matches a future `claude-opus-5-6`, and `gpt-6-sol` never matches `gpt-6.1-sol`: a new version is adopted by re-running the frontier analysis and bumping the ladder, not silently.

## The auto models' thinking level

The thinking level you pick on an auto model (`/thinking`, `--thinking`, Shift+Tab) doesn't set the answering model's effort directly. It moves the route along the ladder relative to what the classifier chose:

| Thinking level | Route |
|---|---|
| `minimal` | two levels below the classification |
| `low` | one level below |
| `medium` | as classified |
| `high` | one level above |
| `xhigh` | two levels above |

It is clamped to the ends of the ladder. `off` and `max` are not offered. The routing record says when effort moved the route:

```
 [Auto (Claude)] Routed to Claude Opus 5.5 · high thinking (complex)
 Why: Normal feature work across two files.
 (classified moderate; +1 for high effort → complex)
```

**It works mid-session.** The classified level is what gets stored, and the offset is re-applied on every user prompt. Turning effort up or down in a running session moves your *next prompt* along the ladder without a second classifier call (tool follow-ups in the current turn stay put), and a block says where it went:

```
 [Auto (Claude)] Effort xhigh: routed to Claude Opus 5.5 · medium thinking (moderate)
 (classified trivial; +2 for xhigh effort → moderate)
```

**The spend confirmation still applies** whenever effort pushes the route into `hard` or `extreme`. Each answer is remembered for the session: approving `hard` covers `hard`; declining it means later prompts at that level take the cheaper route without asking. Only a route *above* what you answered asks again. A classifier failure falls back to `moderate` shifted by effort, but never into a premium level.

> **Check your default thinking level.** When you switch to a model, pi applies your saved thinking level for that model, else your global `defaultThinkingLevel`, clamped to what the model offers. If your global default is `high`, every auto session starts one level up. To make auto models route as classified by default, select one, run `/thinking`, pick `medium`, and press Ctrl+S to save it for that model.

## Effort is clamped before it is announced

Each rung's effort is clamped to what its model declares before it is announced or recorded, so a catalog change can never make the routing record promise a level the request did not run at.

## Sessions, resume and forks

The classified level, and your answers to any spend confirmation, are stored as **router state on the session branch** (pi's virtual-model state), so they:

- **survives quitting and resuming** — a resumed session comes back on the same route with no second classifier call;
- **follows the session tree** — a fork inherits its parent's route, and `/tree` navigation sees each branch's own;
- **survives compaction**;
- **is per auto model** — switching between `auto-claude` and `auto-gpt` classifies afresh on the other ladder.

Switching to an auto model partway through a session classifies your next prompt; switching away and back reuses the branch's stored route.

| Request | Routed to |
|---|---|
| First prompt on a branch | Classified, confirmed if expensive, stored — or, if it only points at its scope, the scout rung until the agent has read it |
| First request after tool results, while scouting | Classified again with what was read, then stored |
| Any later prompt | The stored route |
| Tool follow-up | The model that handled the turn |
| Automatic retry | The model that failed |
| Compaction summary, extension call | The model that answered last (the `moderate` rung before any response) |

## When classification fails

A classifier outage, timeout (10s), malformed reply or missing tool call never costs you your prompt. The request goes to the `moderate` rung (`claude-opus-5-5` · medium / `gpt-6-sol` · high), a block says why, and **no route is stored**, so your next prompt tries again:

```
 [Auto (Claude)] Route suggestion skipped — classifier timed out after 10000ms
 Using Claude Opus 5.5 · medium thinking
```

If the classifier replies without calling its tool, the block includes the reply (up to 300 characters).

## Costs to be aware of

One small-model round-trip before the first response of each session, plus a spend confirmation when the classifier reaches for `hard` or `extreme`. The classifier is each family's cheapest rung on its own provider — Claude Haiku 4.5 for `auto-claude`, GPT-6 Luna at effort `none` for `auto-gpt` — so it never costs more than the turn it is optimising; the classifier only picks a level, and the family's ladder picks the model.
