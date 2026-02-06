# Claude Code History Analysis

Reference documentation for analyzing Claude Code conversation history files. This skill provides query patterns and structural knowledge for extracting insights from JSONL conversation logs.

## When to Use

- Analyzing token usage patterns in past conversations
- Finding conversations by date, content, or skill usage
- Understanding main-agent/sub-agent interaction patterns
- Debugging why a conversation grew large or behaved unexpectedly
- Extracting specific messages or tool invocations from history

## When NOT to Use

- Real-time conversation analysis (use current context instead)
- Modifying conversation history (files are append-only logs)
- Cross-project analysis (each project has separate history)

## Architecture

Claude Code stores conversation history in `~/.claude/projects/` with directories named after encoded working directory paths.

```
~/.claude/projects/
  |-- -Users-leon--claude/              # /Users/leon/.claude
  |   |-- {session-uuid}.jsonl          # Main conversation
  |   |-- {session-uuid}/
  |       |-- subagents/
  |       |   |-- agent-{hash}.jsonl    # Subagent conversations
  |       |-- tool-results/             # Large tool outputs
  |-- -Users-leon-git-myproject/        # /Users/leon/git/myproject
      |-- ...
```

### Path Encoding

Working directory paths are encoded:

| Original       | Encoded        | Rule                |
| -------------- | -------------- | ------------------- |
| `/Users/leon`  | `-Users-leon`  | Leading `/` -> `-`  |
| `/git/project` | `-git-project` | Internal `/` -> `-` |
| `/.claude`     | `--claude`     | `/.` -> `--`        |

### Message Format

Each line in a JSONL file is a self-contained message with:

- `type`: Message type (user, assistant, system, queue-operation)
- `uuid`: Unique identifier for this message
- `parentUuid`: Links to predecessor message (forms conversation chain)
- `timestamp`: ISO 8601 timestamp
- `message`: Payload containing role, content, and usage statistics

Assistant messages have structured content blocks:

- Thinking blocks: Internal reasoning (signature-protected)
- Tool use blocks: Tool invocations with name and input
- Text blocks: Response text shown to user

## Invisible Knowledge

### Why Documentation-Only (No Python Scripts)

Shell commands + jq compose better than custom tooling for this use case:

1. **Format is stable**: JSONL with consistent schema
2. **Queries are ad-hoc**: No two analyses are identical
3. **jq is powerful**: Handles all JSON transformations needed
4. **Maintenance burden**: Python code requires updates when format changes

The documentation approach lets the LLM compose queries on demand rather than learning a custom API.

### Skill Recognition Pattern

Skills are invoked via bash with pattern `python3 -m skills.{name}.{module}`. This pattern is general enough to capture all skills without enumeration:

```regex
python3 -m skills\.([a-z_]+)\.
```

Capture group 1 extracts the skill name. No need to maintain a list of valid skill names.

### Subagent Correlation Challenge

Subagent files are named `agent-{hash}.jsonl` but the hash is not stored in the parent conversation's Task tool call. Correlation requires:

1. List all subagent files for the session
2. Read each subagent's first user message (contains task description)
3. Match description text to Task tool_use inputs in parent

This is mildly inconvenient but not worth building tooling for -- it's a rare operation.

### Token Usage Fields

The `usage` object in assistant messages contains:

- `input_tokens`: Tokens in prompt (excluding cache)
- `output_tokens`: Tokens in response
- `cache_read_input_tokens`: Tokens read from cache
- `cache_creation_input_tokens`: Tokens written to cache

Total billable input = `input_tokens + cache_creation_input_tokens` (cache reads are cheaper).

## Example Usage

### Find Large Conversations

```bash
# Find conversations over 1MB
find "$PROJECT_DIR" -name "*.jsonl" -size +1M

# Get token totals for each
for f in "$PROJECT_DIR"/*.jsonl; do
  tokens=$(jq -s '[.[].message.usage? | select(.) | .input_tokens] | add' "$f")
  echo "$tokens $f"
done | sort -rn | head -10
```

### Analyze Skill Usage

```bash
# Which skills were used in a conversation?
grep -oE "python3 -m skills\.[a-z_]+" file.jsonl | \
  sed 's/python3 -m skills\.//' | \
  cut -d. -f1 | \
  sort -u

# Find all planner skill conversations
grep -l "python3 -m skills\.planner\." "$PROJECT_DIR"/*.jsonl
```

### Token Growth Analysis

```bash
# Show token progression (identify where context grew)
jq -c 'select(.type=="assistant" and .message.usage.input_tokens > 50000) |
  {ts: .timestamp[11:19], tokens: .message.usage.input_tokens}' file.jsonl
```

## Related Skills

This skill provides the structural knowledge for history analysis. For analyzing specific patterns:

- **refactor**: Use when analyzing code quality patterns in past sessions
- **problem-analysis**: Use when investigating root causes of issues found in history
