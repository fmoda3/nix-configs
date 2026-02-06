---
name: cc-history
description: Reference documentation for analyzing Claude Code conversation history files
---

# Claude Code History Analysis

Reference documentation for querying and analyzing Claude Code's conversation history. Use shell commands and jq to extract information from JSONL conversation files.

## Directory Structure

```
~/.claude/projects/{encoded-path}/
  |-- {session-uuid}.jsonl          # Main conversation
  |-- {session-uuid}/
      |-- subagents/
      |   |-- agent-{hash}.jsonl    # Subagent conversations
      |-- tool-results/             # Large tool outputs
```

## Project Path Resolution

Convert working directory to project directory:

```bash
PROJECT_DIR="~/.claude/projects/$(echo "$PWD" | sed 's|^/|-|; s|/\.|--|g; s|/|-|g')"
```

Encoding rules:

- Leading `/` becomes `-`
- Regular `/` becomes `-`
- `/.` (hidden directory) becomes `--`

Examples:

- `/Users/bill/.claude` -> `-Users-bill--claude`
- `/Users/bill/git/myproject` -> `-Users-bill-git-myproject`

## Message Types

| Type              | Description                                   |
| ----------------- | --------------------------------------------- |
| `user`            | User input messages                           |
| `assistant`       | Model responses (thinking, tool_use, text)    |
| `system`          | System messages                               |
| `queue-operation` | Background task notifications (subagent done) |

## Message Structure

Each line in a JSONL file is a message object:

```json
{
  "type": "assistant",
  "uuid": "abc123",
  "parentUuid": "xyz789",
  "timestamp": "2025-01-15T19:39:16.000Z",
  "sessionId": "session-uuid",
  "message": {
    "role": "assistant",
    "content": [...],
    "usage": {
      "input_tokens": 20000,
      "output_tokens": 500,
      "cache_read_input_tokens": 15000,
      "cache_creation_input_tokens": 5000
    }
  }
}
```

Assistant message content blocks:

- `type: "thinking"` - Model thinking (has `thinking` field)
- `type: "tool_use"` - Tool invocation (has `name`, `input` fields)
- `type: "text"` - Text response (has `text` field)

## Common Queries

### Find Conversations

```bash
# List by modification time (most recent first)
ls -lt "$PROJECT_DIR"/*.jsonl

# Find by date
ls -la "$PROJECT_DIR"/*.jsonl | grep "Jan 15"

# Find by content
grep -l "search term" "$PROJECT_DIR"/*.jsonl
```

### Extract Messages

```bash
# Get message by line number (1-indexed)
sed -n '42p' file.jsonl | jq .

# Get message by uuid
jq -c 'select(.uuid=="abc123")' file.jsonl

# All user messages
jq -c 'select(.type=="user")' file.jsonl

# All assistant messages
jq -c 'select(.type=="assistant")' file.jsonl
```

### Tool Call Analysis

```bash
# List all tool calls
jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | {name, input}' file.jsonl

# Count tool calls by name
jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' file.jsonl | sort | uniq -c | sort -rn

# Find specific tool calls
jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Bash")' file.jsonl
```

### Skill Invocation Detection

Pattern: `python3 -m skills\.([a-z_]+)\.`

```bash
# Find all skill invocations
grep -oE "python3 -m skills\.[a-z_]+" file.jsonl | sort -u

# Find conversations using a specific skill
grep -l "python3 -m skills\.planner\." "$PROJECT_DIR"/*.jsonl
```

### Token Usage

```bash
# Total tokens in conversation
jq -s '[.[].message.usage? | select(.) | .input_tokens + .output_tokens] | add' file.jsonl

# Token breakdown
jq -s '[.[].message.usage? | select(.)] | {
  input: (map(.input_tokens) | add),
  output: (map(.output_tokens) | add),
  cached: (map(.cache_read_input_tokens // 0) | add)
}' file.jsonl

# Token progression over time
jq -c 'select(.type=="assistant") | {ts: .timestamp[11:19], inp: .message.usage.input_tokens, out: .message.usage.output_tokens}' file.jsonl
```

### Taxonomy Aggregation

```bash
# Count messages by type
jq -s 'group_by(.type) | map({type: .[0].type, count: length})' file.jsonl

# Character count in user messages
jq -s '[.[] | select(.type=="user") | .message.content | length] | add' file.jsonl

# Thinking block character count
jq -s '[.[] | select(.type=="assistant") | .message.content[]? | select(.type=="thinking") | .thinking | length] | add' file.jsonl
```

### Subagent Analysis

```bash
# List subagents for a session
ls "${SESSION_DIR}/subagents/"

# Get subagent task description (first user message)
jq -c 'select(.type=="user") | .message.content' agent-*.jsonl | head -1

# Find Task tool calls in parent (these spawn subagents)
jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Task") | .input' file.jsonl
```

## Conversation Branching

Each `.jsonl` file contains the **entire conversation tree** (all branches), not separate files per branch. Branching is tracked via `parentUuid`:

- When user goes back in history and issues a new command, the new message gets the same `parentUuid` as where they branched from
- Multiple messages sharing the same `parentUuid` = sibling branches (fork point)

### Detecting Branch Points

```bash
# Find all fork points (messages with multiple children)
jq -s 'group_by(.parentUuid) | map(select(length > 1)) | .[] | {
  parentUuid: .[0].parentUuid,
  branches: length,
  timestamps: [.[].timestamp]
}' file.jsonl

# Show siblings at a known fork point
FORK_POINT="parent-uuid-here"
jq -c --arg fp "$FORK_POINT" 'select(.parentUuid==$fp) | {uuid, ts: .timestamp, preview: (.message.content | tostring)[:100]}' file.jsonl
```

### Extracting a Single Branch

To filter for exactly one branch, find a unique identifier in that branch, then walk the ancestor chain back to root.

**Step 1: Find target message uuid**

```bash
# By unique content
TARGET=$(jq -r 'select(.message.content | tostring | contains("unique-identifier")) | .uuid' file.jsonl | tail -1)

# By timestamp prefix
TARGET=$(jq -r 'select(.timestamp | startswith("2026-01-28T11:23")) | .uuid' file.jsonl | head -1)
```

**Step 2: Extract branch as JSONL stream**

```bash
# Outputs one message per line (JSONL), oldest first
extract_branch() {
  jq -c -s --arg target "$1" '
    (map({(.uuid): .}) | add) as $lookup |
    {chain: [], current: $target} |
    until(.current == null or ($lookup[.current] | not);
      ($lookup[.current]) as $msg |
      .chain += [$msg] |
      .current = $msg.parentUuid
    ) |
    .chain | reverse | .[]
  ' "$2"
}

# Usage: extract_branch <target-uuid> <file>
extract_branch "$TARGET" file.jsonl | jq -s 'length'
extract_branch "$TARGET" file.jsonl | jq 'select(.type=="user")'
```

**Step 3: Common branch queries**

```bash
# Message count
extract_branch "$TARGET" file.jsonl | jq -s 'length'

# User messages only
extract_branch "$TARGET" file.jsonl | jq 'select(.type=="user")'

# Tool calls
extract_branch "$TARGET" file.jsonl | jq 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | {name}'

# First and last messages (verify correct branch)
extract_branch "$TARGET" file.jsonl | jq -s '[.[0], .[-1]] | .[] | {type, ts: .timestamp}'
```

### Workflow: Pinpoint and Explore

```bash
# 1. Find conversation file
FILE=$(grep -l "unique-identifier" "$PROJECT_DIR"/*.jsonl)

# 2. Find matching messages (may show multiple branches)
jq -c 'select(.message.content | tostring | contains("unique-identifier")) | {uuid, ts: .timestamp, parentUuid}' "$FILE"

# 3. Pick target uuid from desired branch, then query
TARGET="uuid-from-step-2"
extract_branch "$TARGET" "$FILE" | jq 'select(.type=="user") | .message.content'
```

## Correlation

Subagent files (`agent-{hash}.jsonl`) don't link directly to parent Task calls. To correlate:

1. List all subagent files under `{session}/subagents/`
2. Read first user message of each for task description
3. Match description to Task tool_use blocks in parent conversation
