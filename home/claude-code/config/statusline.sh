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
#   "hook_event_name": "Status",
#   "session_id": "b84192b5-5d67-425a-9569-36a10aa07f0e",
#   "transcript_path": "/path/to/transcript.json",
#   "cwd": "/current/working/directory",
#   "model": {
#     "id": "claude-opus-4-1",
#     "display_name": "Opus"
#   },
#   "workspace": {
#     "current_dir": "/current/working/directory",
#     "project_dir": "/original/project/directory"
#   },
#   "version": "1.0.85",
#   "output_style": {
#     "name": "default"
#   },
#   "cost": {
#     "total_cost_usd": 0.1082909,
#     "total_duration_ms": 37521,
#     "total_api_duration_ms": 20258,
#     "total_lines_added": 0,
#     "total_lines_removed": 0
#   },
#   "context_window": {
#     "total_input_tokens": 251080,
#     "total_output_tokens": 10896,
#     "context_window_size": 200000,
#     "current_usage": {
#       "input_tokens": 8,
#       "output_tokens": 163,
#       "cache_creation_input_tokens": 1008,
#       "cache_read_input_tokens": 36646
#     },
#     "used_percentage": 12,
#     "remaining_percentage": 88
#   },
#   "exceeds_200k_tokens": false
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
get_current_input_tokens() { echo "$INPUT" | jq -r '.context_window.current_usage.input_tokens // 0'; }
get_current_output_tokens() { echo "$INPUT" | jq -r '.context_window.current_usage.output_tokens // 0'; }
get_cache_creation_input_tokens() { echo "$INPUT" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0'; }
get_cache_read_input_tokens() { echo "$INPUT" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0'; }
get_context_window_size() { echo "$INPUT" | jq -r '.context_window.context_window_size // 0'; }
get_context_window_used_percentage() { echo "$INPUT" | jq -r '.context_window.used_percentage // 0'; }

CCUSAGE_ACTIVE=$(ccusage blocks --active --json)
get_remaining_minutes() { echo "$CCUSAGE_ACTIVE" | jq -r '.blocks[0].projection.remainingMinutes // 0'; }

# Build statusline components
STATUSLINE="${RESET}"

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
STATUSLINE+="${YELLOW} \$${FORMATTED_SESSION_COST}${TEXT} | ${RESET}"

# Add remaining minutes in claude window
MINUTES=$(get_remaining_minutes)
HOURS=$((MINUTES / 60))
REMAINING_MINUTES=$((MINUTES % 60))
STATUSLINE+="${MAROON} ${HOURS}h ${REMAINING_MINUTES}m${TEXT} | ${RESET}"

# Add context window information
CURRENT_INPUT_TOKENS=$(get_current_input_tokens)
CURRENT_OUTPUT_TOKENS=$(get_current_output_tokens)
CACHE_CREATION_INPUT_TOKENS=$(get_cache_creation_input_tokens)
CACHE_READ_INPUT_TOKENS=$(get_cache_read_input_tokens)
CONTEXT_WINDOW_SIZE=$(get_context_window_size)
CONTEXT_WINDOW_USAGE=$((CURRENT_INPUT_TOKENS + CURRENT_OUTPUT_TOKENS + CACHE_CREATION_INPUT_TOKENS + CACHE_READ_INPUT_TOKENS))
CONTEXT_WINDOW_USED_PERCENTAGE=$(get_context_window_used_percentage)
STATUSLINE+="${MAUVE} ${CONTEXT_WINDOW_USAGE}/${CONTEXT_WINDOW_SIZE} (${CONTEXT_WINDOW_USED_PERCENTAGE}%) | ${RESET}"

# Add added/removes lines
TOTAL_LINES_ADDED=$(get_total_lines_added)
TOTAL_LINES_REMOVED=$(get_total_lines_removed)
STATUSLINE+="${TEXT}(${GREEN} ${TOTAL_LINES_ADDED}${TEXT}, ${RED} ${TOTAL_LINES_REMOVED}${TEXT})${RESET}"

echo -e "$STATUSLINE"
