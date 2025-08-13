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
#   }
# }
INPUT=$(cat)

# Helper functions for common extractions
get_session_id() { echo "$INPUT" | jq -r '.session_id'; }
get_model_name() { echo "$INPUT" | jq -r '.model.display_name'; }

SESSION_ID=$(get_session_id)
CCUSAGE_TOTAL=$(ccusage session --id "$SESSION_ID" --json)
get_session_cost() { echo "$CCUSAGE_TOTAL" | jq -r '.totalCost // 0'; }
get_session_tokens() { echo "$CCUSAGE_TOTAL" | jq -r '.totalTokens // 0'; }

CCUSAGE_ACTIVE=$(ccusage blocks --active --json)
get_remaining_minutes() { echo "$CCUSAGE_ACTIVE" | jq -r '.blocks[0].projection.remainingMinutes // 0'; }

# Build statusline components
STATUSLINE="${RESET}"

# Add Model
MODEL=$(get_model_name)
STATUSLINE+="${TEXT}[${BLUE}󱜙 $MODEL${TEXT}]${RESET}"

# Add Session Cost
format_decimal() {
    printf "%.2f" "$1"
}
SESSION_COST=$(get_session_cost)
FORMATTED_SESSION_COST=$(format_decimal $SESSION_COST)
STATUSLINE+="${TEXT}[${GREEN} \$$FORMATTED_SESSION_COST${TEXT}]${RESET}"

# Add Session Tokens
format_tokens() {
  local t=$1
  if (( t < 1000 )); then
    printf "%s" "$t"
  elif (( t < 1000000 )); then
    printf "%.1fk" "$(echo "scale=1; $t / 1000" | bc)"
  else
    printf "%.1fM" "$(echo "scale=1; $t / 1000000" | bc)"
  fi
}
SESSION_TOKENS=$(get_session_tokens)
FORMATTED_TOKENS=$(format_tokens "$SESSION_TOKENS")
STATUSLINE+="${TEXT}[${MAUVE}󰠰 $FORMATTED_TOKENS tokens${TEXT}]${RESET}"

# Add remaining minutes in claude window
MINUTES=$(get_remaining_minutes)
HOURS=$((MINUTES / 60))
REMAINING_MINUTES=$((MINUTES % 60))
STATUSLINE+="${TEXT}[${TEAL} ${HOURS}h ${REMAINING_MINUTES}m${TEXT}]${RESET}"

echo -e "$STATUSLINE"
