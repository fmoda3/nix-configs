#!/bin/bash

# Catppuccin Frappe theme colors
readonly ROSEWATER="\033[38;2;242;213;207m"
readonly FLAMINGO="\033[38;2;238;190;190m"
readonly PINK="\033[38;2;244;184;228m"
readonly MAUVE="\033[38;2;202;158;230m"
readonly RED="\033[38;2;231;130;132m"
readonly MAROON="\033[38;2;234;153;156m"
readonly PEACH="\033[38;2;239;159;118m"
readonly YELLOW="\033[38;2;229;200;144m"
readonly GREEN="\033[38;2;166;209;137m"
readonly TEAL="\033[38;2;129;200;190m"
readonly SKY="\033[38;2;153;209;219m"
readonly SAPPHIRE="\033[38;2;133;193;220m"
readonly BLUE="\033[38;2;140;170;238m"
readonly LAVENDER="\033[38;2;186;187;241m"
readonly TEXT="\033[38;2;198;208;245m"
readonly SUBTEXT1="\033[38;2;181;191;226m"
readonly SUBTEXT0="\033[38;2;165;173;206m"
readonly OVERLAY2="\033[38;2;148;156;187m"
readonly OVERLAY1="\033[38;2;131;139;167m"
readonly OVERLAY0="\033[38;2;115;121;148m"
readonly SURFACE2="\033[38;2;98;104;128m"
readonly SURFACE1="\033[38;2;81;87;109m"
readonly SURFACE0="\033[38;2;65;69;89m"
readonly BASE="\033[38;2;48;52;70m"
readonly MANTLE="\033[38;2;41;44;60m"
readonly CRUST="\033[38;2;35;38;52m"
readonly RESET="\033[0m"

# Read JSON input once
# Will be of format:
# {
#   "cwd": "/current/working/directory",
#   "session_id": "abc123...",
#   "session_name": "my-session",
#   "transcript_path": "/path/to/transcript.jsonl",
#   "model": {
#     "id": "claude-opus-4-7",
#     "display_name": "Opus"
#   },
#   "workspace": {
#     "current_dir": "/current/working/directory",
#     "project_dir": "/original/project/directory",
#     "added_dirs": [],
#     "git_worktree": "feature-xyz"
#   },
#   "version": "2.1.90",
#   "output_style": {
#     "name": "default"
#   },
#   "cost": {
#     "total_cost_usd": 0.01234,
#     "total_duration_ms": 45000,
#     "total_api_duration_ms": 2300,
#     "total_lines_added": 156,
#     "total_lines_removed": 23
#   },
#   "context_window": {
#     "total_input_tokens": 15234,
#     "total_output_tokens": 4521,
#     "context_window_size": 200000,
#     "used_percentage": 8,
#     "remaining_percentage": 92,
#     "current_usage": {
#       "input_tokens": 8500,
#       "output_tokens": 1200,
#       "cache_creation_input_tokens": 5000,
#       "cache_read_input_tokens": 2000
#     }
#   },
#   "exceeds_200k_tokens": false,
#   "rate_limits": {
#     "five_hour": {
#       "used_percentage": 23.5,
#       "resets_at": 1738425600
#     },
#     "seven_day": {
#       "used_percentage": 41.2,
#       "resets_at": 1738857600
#     }
#   },
#   "vim": {
#     "mode": "NORMAL"
#   },
#   "agent": {
#     "name": "security-reviewer"
#   },
#   "worktree": {
#     "name": "my-feature",
#     "path": "/path/to/.claude/worktrees/my-feature",
#     "branch": "worktree-my-feature",
#     "original_cwd": "/path/to/project",
#     "original_branch": "main"
#   }
# }
INPUT=$(cat)

# Debug: Log the INPUT JSON to a file for inspection
echo "$INPUT" > /tmp/claude-code-input-debug.json

# Helper functions for common extractions
get_model_name() {
    local display_name=$(echo "$INPUT" | jq -r '.model.display_name')

    # Check if it's a Bedrock-style ID (contains "anthropic.claude")
    if [[ "$display_name" =~ anthropic\.claude-([a-z]+)-([0-9])-([0-9]) ]]; then
        local family="${BASH_REMATCH[1]}"
        local major="${BASH_REMATCH[2]}"
        local minor="${BASH_REMATCH[3]}"

        # Capitalize the first letter
        family="$(tr '[:lower:]' '[:upper:]' <<< ${family:0:1})${family:1}"

        echo "${family} ${major}.${minor}"
    else
        # Return as-is if not a Bedrock ID
        echo "$display_name"
    fi
}
get_output_style() { echo "$INPUT" | jq -r '.output_style.name'; }
get_session_cost() { echo "$INPUT" | jq -r '.cost.total_cost_usd // 0'; }
get_total_lines_added() { echo "$INPUT" | jq -r '.cost.total_lines_added // 0'; }
get_total_lines_removed() { echo "$INPUT" | jq -r '.cost.total_lines_removed // 0'; }
get_total_duration_ms() { echo "$INPUT" | jq -r '.cost.total_duration_ms // 0'; }
get_total_api_duration_ms() { echo "$INPUT" | jq -r '.cost.total_api_duration_ms // 0'; }
get_current_input_tokens() { echo "$INPUT" | jq -r '.context_window.current_usage.input_tokens // 0'; }
get_cache_creation_input_tokens() { echo "$INPUT" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0'; }
get_cache_read_input_tokens() { echo "$INPUT" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0'; }
get_context_window_size() { echo "$INPUT" | jq -r '.context_window.context_window_size // 0'; }
get_context_window_used_percentage() { echo "$INPUT" | jq -r '.context_window.used_percentage // 0'; }

get_agent_name() { echo "$INPUT" | jq -r '.agent.name // empty'; }
get_worktree_name() { echo "$INPUT" | jq -r '.worktree.name // empty'; }

get_five_hour_used_percentage() { echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // empty'; }
get_five_hour_resets_at() { echo "$INPUT" | jq -r '.rate_limits.five_hour.resets_at // empty'; }
get_seven_day_used_percentage() { echo "$INPUT" | jq -r '.rate_limits.seven_day.used_percentage // empty'; }
get_seven_day_resets_at() { echo "$INPUT" | jq -r '.rate_limits.seven_day.resets_at // empty'; }
get_remaining_seconds() {
    local resets_at=$1
    local now=$(date +%s)
    local remaining=$((resets_at - now))
    if [ "$remaining" -lt 0 ]; then
        remaining=0
    fi
    echo "$remaining"
}

# Build statusline components
STATUSLINE="${RESET}"

# Add Agent name (if in a subagent)
AGENT_NAME=$(get_agent_name)
if [[ -n "$AGENT_NAME" ]]; then
    STATUSLINE+="${LAVENDER} ${AGENT_NAME}${TEXT} | ${RESET}"
fi

# Add Model
MODEL=$(get_model_name)
STATUSLINE+="${BLUE}󱜙 ${MODEL}${TEXT} | ${RESET}"

# Add Output Style
OUTPUT_STYLE=$(get_output_style)
STATUSLINE+="${TEAL} ${OUTPUT_STYLE}${TEXT} | ${RESET}"

# Add Session Cost
format_decimal() {
    printf "%.2f" "$1"
}
SESSION_COST=$(get_session_cost)
FORMATTED_SESSION_COST=$(format_decimal $SESSION_COST)
STATUSLINE+="${GREEN} \$${FORMATTED_SESSION_COST}${TEXT} | ${RESET}"

# Add session duration and API duration
format_duration() {
    local ms=$1
    local total_secs=$((ms / 1000))
    local hours=$((total_secs / 3600))
    local mins=$(( (total_secs % 3600) / 60 ))
    local secs=$((total_secs % 60))
    if [ "$hours" -gt 0 ]; then
        printf "%dh %dm %ds" "$hours" "$mins" "$secs"
    elif [ "$mins" -gt 0 ]; then
        printf "%dm %ds" "$mins" "$secs"
    else
        printf "%ds" "$secs"
    fi
}
TOTAL_DURATION_MS=$(get_total_duration_ms)
TOTAL_API_DURATION_MS=$(get_total_api_duration_ms)
FORMATTED_TOTAL_DURATION=$(format_duration "$TOTAL_DURATION_MS")
FORMATTED_API_DURATION=$(format_duration "$TOTAL_API_DURATION_MS")
STATUSLINE+="${YELLOW}󱩷 ${FORMATTED_TOTAL_DURATION} 󱉊 ${FORMATTED_API_DURATION}${TEXT} | ${RESET}"

# Add context window information
CURRENT_INPUT_TOKENS=$(get_current_input_tokens)
CACHE_CREATION_INPUT_TOKENS=$(get_cache_creation_input_tokens)
CACHE_READ_INPUT_TOKENS=$(get_cache_read_input_tokens)
CONTEXT_WINDOW_SIZE=$(get_context_window_size)
CONTEXT_WINDOW_USAGE=$((CURRENT_INPUT_TOKENS + CACHE_CREATION_INPUT_TOKENS + CACHE_READ_INPUT_TOKENS))
CONTEXT_WINDOW_USED_PERCENTAGE=$(get_context_window_used_percentage)
STATUSLINE+="${PEACH} ${CONTEXT_WINDOW_USAGE}/${CONTEXT_WINDOW_SIZE} (${CONTEXT_WINDOW_USED_PERCENTAGE}%) | ${RESET}"

# Add added/removed lines and worktree
TOTAL_LINES_ADDED=$(get_total_lines_added)
TOTAL_LINES_REMOVED=$(get_total_lines_removed)
WORKTREE_NAME=$(get_worktree_name)
if [[ -n "$WORKTREE_NAME" ]]; then
    STATUSLINE+="${MAROON} ${WORKTREE_NAME}${TEXT}, "
fi
STATUSLINE+="${TEXT}(${GREEN} ${TOTAL_LINES_ADDED}${TEXT} ${RED} ${TOTAL_LINES_REMOVED}${TEXT}"
STATUSLINE+="${TEXT})${RESET}"

echo -e "$STATUSLINE"

# Add rate limit information on a second line (only if rate limits exist)
FIVE_HOUR_USED=$(get_five_hour_used_percentage)
SEVEN_DAY_USED=$(get_seven_day_used_percentage)

if [[ -n "$FIVE_HOUR_USED" || -n "$SEVEN_DAY_USED" ]]; then
    RATE_LIMIT_LINE="${RESET}"

    if [[ -n "$FIVE_HOUR_USED" ]]; then
        FIVE_HOUR_RESETS_AT=$(get_five_hour_resets_at)
        FIVE_HOUR_REMAINING_SECS=$(get_remaining_seconds "$FIVE_HOUR_RESETS_AT")
        FIVE_HOUR_HOURS=$((FIVE_HOUR_REMAINING_SECS / 3600))
        FIVE_HOUR_MINUTES=$(( (FIVE_HOUR_REMAINING_SECS % 3600) / 60 ))
        RATE_LIMIT_LINE+="${MAUVE} ${FIVE_HOUR_USED}% ${FIVE_HOUR_HOURS}h ${FIVE_HOUR_MINUTES}m${RESET}"
    fi

    if [[ -n "$SEVEN_DAY_USED" ]]; then
        if [[ -n "$FIVE_HOUR_USED" ]]; then
            RATE_LIMIT_LINE+="${TEXT} | ${RESET}"
        fi
        SEVEN_DAY_RESETS_AT=$(get_seven_day_resets_at)
        SEVEN_DAY_REMAINING_SECS=$(get_remaining_seconds "$SEVEN_DAY_RESETS_AT")
        SEVEN_DAY_DAYS=$((SEVEN_DAY_REMAINING_SECS / 86400))
        SEVEN_DAY_HOURS=$(( (SEVEN_DAY_REMAINING_SECS % 86400) / 3600 ))
        SEVEN_DAY_MINUTES=$(( (SEVEN_DAY_REMAINING_SECS % 3600) / 60 ))
        RATE_LIMIT_LINE+="${FLAMINGO}󰨳 ${SEVEN_DAY_USED}% ${SEVEN_DAY_DAYS}d ${SEVEN_DAY_HOURS}h ${SEVEN_DAY_MINUTES}m${RESET}"
    fi

    echo -e "$RATE_LIMIT_LINE"
fi
