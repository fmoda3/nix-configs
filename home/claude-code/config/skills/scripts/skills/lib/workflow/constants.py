"""Workflow constants shared across all skills.

QR-related constants are defined here in the lib layer so that
formatters can use them without creating a dependency on planner.
"""


# =============================================================================
# HITL Constants
# =============================================================================

HITL_BATCHING_GUIDANCE = """\
<hitl_efficiency>
BATCH RELATED QUESTIONS: When multiple clarifications are needed in the same
decision domain, combine into ONE AskUserQuestion call with multiple questions.

BATCH when:
  - Questions are about the same topic (testing, architecture, naming)
  - User can answer all without needing intermediate results
  - Questions don't depend on each other's answers

DO NOT BATCH when:
  - Answer to Q1 determines whether Q2 is needed
  - Questions span unrelated domains

EXAMPLE (batch these):
  - Unit test approach?
  - Integration test approach?
  - E2E test approach?
  -> ONE AskUserQuestion with questions array of 3 entries

EXAMPLE (don't batch):
  - Which database? -> User answers "PostgreSQL"
  - Which ORM? -> Depends on database choice
  -> TWO separate AskUserQuestion calls
</hitl_efficiency>
"""


# =============================================================================
# Subagent Return Constants
# =============================================================================

SUBAGENT_RETURN_BUDGET = """\
<return_budget>
TOKEN BUDGET (ENFORCED):
  - Total return: MAX 1500 tokens
  - Per section: MAX 500 tokens
  - Per finding/item: MAX 50 tokens

COMPRESSION STYLE:
  VERBOSE: 'The module implements a factory pattern that creates service
           instances, enabling dependency injection and testability...'
  DRAFT:   'Factory pattern -> DI + testability'

If findings exceed budget, OMIT low-relevance items.
Write detailed content to FILES, return only status + metadata.
</return_budget>
"""


# =============================================================================
# State File Constants (JSON migration)
# =============================================================================

PLAN_FILE = "plan.json"


# =============================================================================
# Question Relay Protocol
# =============================================================================

SUB_AGENT_QUESTION_FORMAT = """\
<question_protocol>
When you need user clarification to proceed:

BEFORE YIELDING:
  1. Save ALL current state to plan.json (context, findings, progress)
  2. State must be sufficient to continue after reinvocation

THEN emit this XML as your ENTIRE response:

<needs_user_input>
  <question header="SHORT_LABEL" multi_select="false">
    <text>Your question here?</text>
    <option label="Choice A">Description of what A means</option>
    <option label="Choice B">Description of what B means</option>
  </question>
</needs_user_input>

EXAMPLE (multiple questions):
<needs_user_input>
  <question header="Auth">
    <text>Which authentication method?</text>
    <option label="OAuth">Industry standard, supports refresh tokens</option>
    <option label="JWT">Self-contained, no session storage</option>
  </question>
  <question header="Storage">
    <text>Which storage backend for cache?</text>
    <option label="Redis">Fast, requires external service</option>
    <option label="SQLite">Simple, file-based, no dependencies</option>
  </question>
</needs_user_input>

CONSTRAINTS:
  - Max 3 <question> elements
  - Each question: 2-3 <option> elements
  - header attribute: max 12 characters
  - multi_select: "true" or "false" (default false)
  - This XML is your COMPLETE response -- emit nothing else

WHEN TO USE:
  - Critical design decisions with competing valid approaches
  - Missing requirements that cannot be reasonably inferred
  - Trade-offs where user preference determines outcome

DO NOT USE FOR:
  - Implementation details with obvious best practices
  - Questions answerable from context already provided
  - Stylistic choices within established codebase patterns

WHAT HAPPENS NEXT:
  After emitting this XML, STOP. The orchestrator will:
  1. Relay the question to the user
  2. REINVOKE you fresh (NOT resume) with the user's answer
  3. Pass the STATE_DIR so you can read plan.json

  When reinvoked, you will receive:
  - <user_response> with answers to your questions
  - STATE_DIR pointing to your saved state
  - Instructions to invoke your script with --step 1

  Your script's step 1 should detect this is a continuation (plan.json exists
  with your saved progress) and continue from where you left off.
</question_protocol>
"""


QUESTION_RELAY_HANDLER = """\
<question_relay_handler>
If sub-agent output contains <needs_user_input>:
  1. Parse XML and call AskUserQuestion with extracted fields
  2. Reinvoke sub-agent FRESH (not resume) with <user_response> and same STATE_DIR
     Sub-agent reads plan.json to restore state; invoke script --step 1
</question_relay_handler>
"""
