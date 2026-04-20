#!/usr/bin/env bash

set -euo pipefail

# Catppuccin Frappe theme colors
readonly ROSEWATER=$'\033[38;2;242;213;207m'
readonly FLAMINGO=$'\033[38;2;238;190;190m'
readonly PINK=$'\033[38;2;244;184;228m'
readonly MAUVE=$'\033[38;2;202;158;230m'
readonly RED=$'\033[38;2;231;130;132m'
readonly MAROON=$'\033[38;2;234;153;156m'
readonly PEACH=$'\033[38;2;239;159;118m'
readonly YELLOW=$'\033[38;2;229;200;144m'
readonly GREEN=$'\033[38;2;166;209;137m'
readonly TEAL=$'\033[38;2;129;200;190m'
readonly SKY=$'\033[38;2;153;209;219m'
readonly SAPPHIRE=$'\033[38;2;133;193;220m'
readonly BLUE=$'\033[38;2;140;170;238m'
readonly LAVENDER=$'\033[38;2;186;187;241m'
readonly TEXT=$'\033[38;2;198;208;245m'
readonly SUBTEXT0=$'\033[38;2;165;173;206m'
readonly RESET=$'\033[0m'

INPUT=$(cat)

echo "$INPUT" > /tmp/claude-code-input-debug.json

jq_get() {
  echo "$INPUT" | jq -r "$1"
}

strip_ansi() {
  perl -pe 's/\e\[[0-9;]*m//g'
}

unicode_width() {
  python3 - "$1" <<'PY'
import sys
import unicodedata
s = sys.argv[1]
width = 0
for ch in s:
    if unicodedata.combining(ch):
        continue
    width += 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
print(width)
PY
}

visible_width() {
  local plain
  plain=$(printf "%s" "$1" | strip_ansi)
  unicode_width "$plain"
}

repeat_char() {
  local char=$1
  local count=$2
  local out=""
  local i
  if (( count <= 0 )); then
    printf ""
    return
  fi
  for (( i=0; i<count; i++ )); do
    out+="$char"
  done
  printf "%s" "$out"
}

pad_right() {
  local text=$1
  local target=$2
  local width
  width=$(visible_width "$text")
  local pad=$(( target - width ))
  if (( pad < 0 )); then
    pad=0
  fi
  printf "%s%s" "$text" "$(repeat_char ' ' "$pad")"
}

panel_width() {
  local -n lines_ref=$1
  local max=0
  local line width
  for line in "${lines_ref[@]}"; do
    width=$(visible_width "$line")
    if (( width > max )); then
      max=$width
    fi
  done
  echo "$max"
}

render_panel_row() {
  local gap=$1
  shift
  local panel_names=("$@")
  local widths=()
  local heights=()
  local idx line_count panel_width_value i panel_name line

  for idx in "${!panel_names[@]}"; do
    panel_name=${panel_names[$idx]}
    local -n panel_ref="$panel_name"
    panel_width_value=$(panel_width "$panel_name")
    widths+=("$panel_width_value")
    line_count=${#panel_ref[@]}
    heights+=("$line_count")
  done

  local max_height=0
  for line_count in "${heights[@]}"; do
    if (( line_count > max_height )); then
      max_height=$line_count
    fi
  done

  for (( i=0; i<max_height; i++ )); do
    local parts=()
    for idx in "${!panel_names[@]}"; do
      panel_name=${panel_names[$idx]}
      local -n panel_ref="$panel_name"
      line="${panel_ref[$i]:-}"
      parts+=("$(pad_right "$line" "${widths[$idx]}")")
    done

    local joined="${parts[0]}"
    for (( idx=1; idx<${#parts[@]}; idx++ )); do
      joined+="$(repeat_char ' ' "$gap")${parts[$idx]}"
    done
    printf "%s\n" "$joined"
  done
}

total_panel_width() {
  local gap=$1
  shift
  local panel_names=("$@")
  local total=0
  local idx name panel_w
  for idx in "${!panel_names[@]}"; do
    name=${panel_names[$idx]}
    panel_w=$(panel_width "$name")
    if (( idx == 0 )); then
      total=$panel_w
    else
      total=$(( total + gap + panel_w ))
    fi
  done
  echo "$total"
}

render_panel_pack() {
  local width=$1
  local gap=$2
  shift 2
  local panel_names=("$@")
  local current_row=()
  local current_width=0
  local name panel_w next_width

  for name in "${panel_names[@]}"; do
    panel_w=$(panel_width "$name")
    if (( ${#current_row[@]} == 0 )); then
      current_row=("$name")
      current_width=$panel_w
      continue
    fi

    next_width=$(( current_width + gap + panel_w ))
    if (( next_width <= width )); then
      current_row+=("$name")
      current_width=$next_width
    else
      render_panel_row "$gap" "${current_row[@]}"
      echo
      current_row=("$name")
      current_width=$panel_w
    fi
  done

  if (( ${#current_row[@]} > 0 )); then
    render_panel_row "$gap" "${current_row[@]}"
  fi
}

truncate_plain() {
  local text=$1
  local width=$2
  if (( width <= 0 )); then
    printf ""
    return
  fi
  python3 - "$text" "$width" <<'PY'
import sys
import unicodedata
s = sys.argv[1]
limit = int(sys.argv[2])
out = []
used = 0
for ch in s:
    ch_width = 0 if unicodedata.combining(ch) else (2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1)
    if used + ch_width > limit:
        break
    out.append(ch)
    used += ch_width
print(''.join(out), end='')
PY
}

truncate_colored() {
  local text=$1
  local width=$2
  local plain
  plain=$(printf "%s" "$text" | strip_ansi)
  local plain_width
  plain_width=$(unicode_width "$plain")
  if (( plain_width <= width )); then
    printf "%s" "$text"
    return
  fi
  truncate_plain "$plain" "$width"
}

get_width() {
  local term_cols=""

  term_cols=$(stty size < /dev/tty 2>/dev/null | awk '{print $2}')
  if [[ -n "$term_cols" && "$term_cols" =~ ^[0-9]+$ && "$term_cols" -gt 20 ]]; then
    echo "$term_cols"
    return
  fi

  term_cols=$(tput cols 2>/dev/null || true)
  if [[ -n "$term_cols" && "$term_cols" =~ ^[0-9]+$ && "$term_cols" -gt 20 ]]; then
    echo "$term_cols"
    return
  fi

  echo 80
}

usage_color() {
  local percent=${1%.*}
  if (( percent >= 90 )); then echo "$RED"
  elif (( percent >= 75 )); then echo "$PEACH"
  elif (( percent >= 50 )); then echo "$YELLOW"
  else echo "$GREEN"; fi
}

bar5() {
  local percent=${1%.*}
  if (( percent < 0 )); then percent=0; fi
  if (( percent > 100 )); then percent=100; fi
  local filled=$(( (percent + 10) / 20 ))
  if (( filled > 5 )); then filled=5; fi
  printf "%s%s" "$(repeat_char '█' "$filled")" "$(repeat_char '░' "$((5 - filled))")"
}

format_decimal() {
  printf "%.2f" "${1:-0}"
}

format_count() {
  local value=${1:-0}
  python3 - "$value" <<'PY'
import sys
value = float(sys.argv[1])
abs_value = abs(value)
if abs_value < 1000:
    out = f"{int(value)}"
elif abs_value < 10000:
    out = f"{value/1000:.1f}k"
elif abs_value < 1000000:
    out = f"{round(value/1000):.0f}k"
elif abs_value < 10000000:
    out = f"{value/1000000:.1f}M"
else:
    out = f"{round(value/1000000):.0f}M"
print(out)
PY
}

format_duration() {
  local ms=${1:-0}
  local total_secs=$((ms / 1000))
  local hours=$((total_secs / 3600))
  local mins=$(((total_secs % 3600) / 60))
  local secs=$((total_secs % 60))
  if (( hours > 0 )); then
    printf "%dh %dm %ds" "$hours" "$mins" "$secs"
  elif (( mins > 0 )); then
    printf "%dm %ds" "$mins" "$secs"
  else
    printf "%ds" "$secs"
  fi
}

format_reset_from_epoch() {
  local resets_at=${1:-0}
  if [[ -z "$resets_at" || "$resets_at" == "null" ]]; then
    printf ""
    return
  fi
  local now remaining mins hours days rem_hours rem_mins
  now=$(date +%s)
  remaining=$((resets_at - now))
  if (( remaining < 0 )); then
    printf "now"
    return
  fi
  mins=$((remaining / 60))
  if (( mins < 60 )); then
    printf "%dm" "$mins"
    return
  fi
  hours=$((mins / 60))
  rem_mins=$((mins % 60))
  if (( hours < 24 )); then
    if (( rem_mins > 0 )); then printf "%dh%dm" "$hours" "$rem_mins"; else printf "%dh" "$hours"; fi
    return
  fi
  days=$((hours / 24))
  rem_hours=$((hours % 24))
  if (( rem_hours > 0 )); then printf "%dd%dh" "$days" "$rem_hours"; else printf "%dd" "$days"; fi
}

get_model_name() {
  local display_name
  display_name=$(jq_get '.model.display_name // .model.id // "n/a"')
  if [[ "$display_name" =~ anthropic\.claude-([a-z]+)-([0-9])-([0-9]) ]]; then
    local family="${BASH_REMATCH[1]}"
    local major="${BASH_REMATCH[2]}"
    local minor="${BASH_REMATCH[3]}"
    family="$(tr '[:lower:]' '[:upper:]' <<< "${family:0:1}")${family:1}"
    echo "${family} ${major}.${minor}"
  else
    echo "$display_name"
  fi
}

get_git_branch() {
  git branch --show-current 2>/dev/null || true
}

format_rows() {
  local width=0
  local row key value
  local rows=("$@")

  for row in "${rows[@]}"; do
    key=${row%%$'\t'*}
    if [[ "$key" == "$row" ]]; then
      continue
    fi
    local key_width
    key_width=$(visible_width "$key")
    if (( key_width > width )); then
      width=$key_width
    fi
  done

  for row in "${rows[@]}"; do
    key=${row%%$'\t'*}
    if [[ "$key" == "$row" ]]; then
      printf "%s\n" "$row"
      continue
    fi
    value=${row#*$'\t'}
    printf "%s %b│%b %s\n" "$(pad_right "${SUBTEXT0}${key}${RESET}" "$width")" "$TEXT" "$RESET" "$value"
  done
}

make_panel() {
  local title=$1
  local top_right=$2
  shift 2
  local lines=("$@")
  local inner=0
  local max_inner=${MAX_PANEL_INNER_WIDTH:-0}
  local line width header right_text fill content truncated

  for line in "${lines[@]}"; do
    width=$(visible_width "$line")
    if (( width + 2 > inner )); then inner=$((width + 2)); fi
  done

  header=" ${title} "
  width=$(visible_width "$header")
  if [[ -n "$top_right" ]]; then
    right_text=" ${top_right} "
    local header_width=$(( width + $(visible_width "$right_text") + 1 ))
    if (( header_width > inner )); then inner=$header_width; fi
  fi

  if (( max_inner > 0 && inner > max_inner )); then
    inner=$max_inner
  fi

  if [[ -n "$top_right" ]]; then
    right_text=" ${top_right} "
    fill=$(( inner - width - $(visible_width "$right_text") ))
    if (( fill < 1 )); then
      right_text=" $(truncate_colored "$top_right" $(( inner - width - 2 ))) "
      fill=1
    fi
    printf "%b╭%b%s%b%s%b%s%b╮%b\n" "$SUBTEXT0" "$SAPPHIRE" "$header" "$SUBTEXT0" "$(repeat_char '─' "$fill")" "$TEXT" "$right_text" "$SUBTEXT0" "$RESET"
  else
    fill=$(( inner - width ))
    if (( fill < 0 )); then fill=0; fi
    printf "%b╭%b%s%b%s%b╮%b\n" "$SUBTEXT0" "$SAPPHIRE" "$header" "$SUBTEXT0" "$(repeat_char '─' "$fill")" "$SUBTEXT0" "$RESET"
  fi

  for line in "${lines[@]}"; do
    truncated=$(truncate_colored "$line" $((inner - 2)))
    content=" $(pad_right "$truncated" $((inner - 2))) "
    printf "%b│%b%s%b│%b\n" "$SUBTEXT0" "$RESET" "$content" "$SUBTEXT0" "$RESET"
  done

  printf "%b╰%s╯%b\n" "$SUBTEXT0" "$(repeat_char '─' "$inner")" "$RESET"
}

build_model_panel() {
  local model thinking agent
  model=$(get_model_name)
  thinking=$(jq_get '.output_style.name // "default"')
  agent=$(jq_get '.agent.name // empty')
  local rows=(
    $'model\t'"${BLUE}${model}${RESET}"
    $'style\t'"${SKY}${thinking}${RESET}"
  )
  if [[ -n "$agent" ]]; then
    rows+=($'agent\t'"${LAVENDER}${agent}${RESET}")
  fi
  local lines=()
  mapfile -t lines < <(format_rows "${rows[@]}")
  make_panel "MODEL" "" "${lines[@]}"
}

build_usage_panel() {
  local total_in total_out cost used pct window current cache_create cache_read tokens_summary color bar
  total_in=$(format_count "$(jq_get '.context_window.total_input_tokens // 0')")
  total_out=$(format_count "$(jq_get '.context_window.total_output_tokens // 0')")
  cost=$(format_decimal "$(jq_get '.cost.total_cost_usd // 0')")
  pct=$(jq_get '.context_window.used_percentage // 0')
  window=$(format_count "$(jq_get '.context_window.context_window_size // 0')")
  current=$(jq_get '.context_window.current_usage.input_tokens // 0')
  cache_create=$(jq_get '.context_window.current_usage.cache_creation_input_tokens // 0')
  cache_read=$(jq_get '.context_window.current_usage.cache_read_input_tokens // 0')
  used=$(format_count "$((current + cache_create + cache_read))")
  color=$(usage_color "$pct")
  bar=$(bar5 "$pct")
  tokens_summary="${LAVENDER}↑${total_in} ↓${total_out}${RESET}"
  local lines=()
  mapfile -t lines < <(format_rows \
    $'cost\t'"${GREEN}\$${cost}${RESET}" \
    $'context\t'"${color}${pct}% ${bar}${TEXT} ${used}/${window}${RESET}")
  make_panel "USAGE" "$tokens_summary" "${lines[@]}"
}

build_runtime_panel() {
  local session api lines
  session=$(format_duration "$(jq_get '.cost.total_duration_ms // 0')")
  api=$(format_duration "$(jq_get '.cost.total_api_duration_ms // 0')")
  mapfile -t lines < <(format_rows \
    $'session\t'"${YELLOW}${session}${RESET}" \
    $'api\t'"${YELLOW}${api}${RESET}")
  make_panel "RUNTIME" "" "${lines[@]}"
}

build_rate_panel() {
  local five seven five_reset seven_reset rows=() lines=()
  local five_label="" seven_label="" percent_width=0
  five=$(jq_get '.rate_limits.five_hour.used_percentage // empty')
  seven=$(jq_get '.rate_limits.seven_day.used_percentage // empty')
  five_reset=$(format_reset_from_epoch "$(jq_get '.rate_limits.five_hour.resets_at // empty')")
  seven_reset=$(format_reset_from_epoch "$(jq_get '.rate_limits.seven_day.resets_at // empty')")

  if [[ -n "$five" ]]; then
    five_label="${five}%"
    if (( ${#five_label} > percent_width )); then
      percent_width=${#five_label}
    fi
  fi
  if [[ -n "$seven" ]]; then
    seven_label="${seven}%"
    if (( ${#seven_label} > percent_width )); then
      percent_width=${#seven_label}
    fi
  fi

  if [[ -n "$five" ]]; then
    printf -v five_label "%*s" "$percent_width" "$five_label"
    rows+=($'5h\t'"$(usage_color "$five")${five_label} $(bar5 "$five")${TEXT} • ${five_reset}${RESET}")
  fi
  if [[ -n "$seven" ]]; then
    printf -v seven_label "%*s" "$percent_width" "$seven_label"
    rows+=($'7d\t'"$(usage_color "$seven")${seven_label} $(bar5 "$seven")${TEXT} • ${seven_reset}${RESET}")
  fi
  if (( ${#rows[@]} == 0 )); then
    return 0
  fi

  mapfile -t lines < <(format_rows "${rows[@]}")
  make_panel "RATE LIMITS" "" "${lines[@]}"
}

build_git_panel() {
  local worktree branch added removed diff_summary lines
  worktree=$(jq_get '.worktree.name // .workspace.git_worktree // empty')
  branch=$(jq_get '.worktree.branch // empty')
  if [[ -z "$branch" ]]; then
    branch=$(get_git_branch)
  fi
  if [[ -z "$worktree" ]]; then
    worktree="N/A"
  fi
  if [[ -z "$branch" ]]; then
    branch="detached"
  fi
  added=$(jq_get '.cost.total_lines_added // 0')
  removed=$(jq_get '.cost.total_lines_removed // 0')
  diff_summary="${GREEN}+${added}${TEXT} ${RED}-${removed}${RESET}"
  mapfile -t lines < <(format_rows \
    $'branch\t'"${FLAMINGO}${branch}${RESET}" \
    $'worktree\t'"${FLAMINGO}${worktree}${RESET}")
  make_panel "GIT" "$diff_summary" "${lines[@]}"
}

render_compact() {
  local model style cost session api pct used window worktree five seven current cache_create cache_read
  model=$(get_model_name)
  style=$(jq_get '.output_style.name // "default"')
  cost=$(format_decimal "$(jq_get '.cost.total_cost_usd // 0')")
  session=$(format_duration "$(jq_get '.cost.total_duration_ms // 0')")
  api=$(format_duration "$(jq_get '.cost.total_api_duration_ms // 0')")
  pct=$(jq_get '.context_window.used_percentage // 0')
  current=$(jq_get '.context_window.current_usage.input_tokens // 0')
  cache_create=$(jq_get '.context_window.current_usage.cache_creation_input_tokens // 0')
  cache_read=$(jq_get '.context_window.current_usage.cache_read_input_tokens // 0')
  used=$(format_count "$((current + cache_create + cache_read))")
  window=$(format_count "$(jq_get '.context_window.context_window_size // 0')")
  worktree=$(jq_get '.worktree.name // .workspace.git_worktree // empty')
  five=$(jq_get '.rate_limits.five_hour.used_percentage // empty')
  seven=$(jq_get '.rate_limits.seven_day.used_percentage // empty')

  printf "%b󱜙 %s%b | %b %s%b | %b $%s%b | %b󱩷 %s%b | %b󱉊 %s%b\n" \
    "$BLUE" "$model" "$RESET" \
    "$TEAL" "$style" "$RESET" \
    "$GREEN" "$cost" "$RESET" \
    "$YELLOW" "$session" "$RESET" \
    "$YELLOW" "$api" "$RESET"

  printf "%b %s/%s (%s%%)%b" "$PEACH" "$used" "$window" "$pct" "$RESET"
  if [[ -n "$worktree" ]]; then
    printf " %b|  %s%b" "$MAROON" "$worktree" "$RESET"
  fi
  if [[ -n "$five" || -n "$seven" ]]; then
    printf " %b|%b" "$TEXT" "$RESET"
    [[ -n "$five" ]] && printf " %b5h %s%%%b" "$(usage_color "$five")" "$five" "$RESET"
    [[ -n "$seven" ]] && printf " %b7d %s%%%b" "$(usage_color "$seven")" "$seven" "$RESET"
  fi
  printf "\n"
}

render_panels() {
  local width=$1
  local gap=1
  local panels=(model usage runtime)
  local model usage runtime git rate

  MAX_PANEL_INNER_WIDTH=$(( width - 2 ))
  export MAX_PANEL_INNER_WIDTH
  mapfile -t model < <(build_model_panel)
  mapfile -t usage < <(build_usage_panel)
  mapfile -t runtime < <(build_runtime_panel)

  if [[ -n "$(jq_get '.rate_limits.five_hour.used_percentage // empty')" || -n "$(jq_get '.rate_limits.seven_day.used_percentage // empty')" ]]; then
    mapfile -t rate < <(build_rate_panel)
    panels+=(rate)
  fi

  mapfile -t git < <(build_git_panel)
  panels+=(git)

  local natural_total
  natural_total=$(total_panel_width "$gap" "${panels[@]}")

  if (( natural_total > width )); then
    local panel_count=${#panels[@]}
    local shared_inner=$(( (width - (gap * (panel_count - 1))) / panel_count - 2 ))
    if (( shared_inner >= 24 )); then
      MAX_PANEL_INNER_WIDTH=$shared_inner
      export MAX_PANEL_INNER_WIDTH
      mapfile -t model < <(build_model_panel)
      mapfile -t usage < <(build_usage_panel)
      mapfile -t runtime < <(build_runtime_panel)
      if [[ " ${panels[*]} " == *" rate "* ]]; then
        mapfile -t rate < <(build_rate_panel)
      fi
      mapfile -t git < <(build_git_panel)
      natural_total=$(total_panel_width "$gap" "${panels[@]}")
    fi
  fi

  if (( natural_total <= width )); then
    render_panel_row "$gap" "${panels[@]}"
  else
    render_panel_pack "$width" "$gap" "${panels[@]}"
  fi
}

WIDTH=$(get_width)
printf '%s\n' "WIDTH=$WIDTH" > /tmp/claude-code-statusline-width-debug.txt

if (( WIDTH < 80 )); then
  render_compact
else
  render_panels "$WIDTH"
fi
