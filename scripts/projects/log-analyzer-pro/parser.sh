#!/bin/bash
# scripts/projects/log-analyzer-pro/parser.sh
parse_log_file() {
  local file="$1"
  local -A counters=([error]=0 [warn]=0 [info]=0)
  local service="unknown"

  [[ "$file" =~ /([^/]+)\.log$ ]] && service="${BASH_REMATCH[1]}"

  mapfile -t lines < "$file"
  for line in "${lines[@]}"; do
    [[ "$line" =~ ERROR|CRITICAL ]] && ((counters[error]++))
    [[ "$line" =~ WARN|WARNING ]] && ((counters[warn]++))
    [[ "$line" =~ INFO ]] && ((counters[info]++))
  done

  printf '%s\t%d\t%d\t%d\n' "$service" "${counters[error]}" "${counters[warn]}" "${counters[info]}"
}
export -f parse_log_file
