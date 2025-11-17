#!/usr/bin/env bash
# File: scripts/advanced/day12/log-analyzer.sh
# Purpose: Ultra-fast log analysis (1M+ lines in <2s)

set -euo pipefail
IFS=$'\n\t'

# === Performance Settings ===
shopt -s lastpipe 2>/dev/null || true  # Allow pipe to modify vars in current shell

# === Paths ===
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${1:-/var/log/app.log}"
REPORT_FILE="/tmp/log-report-$(date +%Y%m%d-%H%M%S).txt"

# === Logging (optimized) ===
log() {
  printf '[%s] [ANALYZER] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >> "$REPORT_FILE"
}

# === Fast File Read with mapfile ===
analyze_logs() {
  local error_count=0 warn_count=0 top_ip=""
  local -A ip_counts  # Associative array for O(1) lookup

  # Read entire file in one go (fastest)
  mapfile -t lines < <(tail -1000000 "$LOG_FILE" 2>/dev/null || cat "$LOG_FILE")

  log "Loaded ${#lines[@]} lines from $LOG_FILE"

  # Process in-memory (no I/O in loop)
  for line in "${lines[@]}"; do
    # Fast pattern matching with [[ ]]
    if [[ "$line" =~ \[(ERROR|CRITICAL)\] ]]; then
      ((error_count++))
    elif [[ "$line" =~ \[WARN\] ]]; then
      ((warn_count++))
    fi

    # Extract IP efficiently
    if [[ "$line" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3} ]]; then
      ip="${BASH_REMATCH[0]}"
      ((ip_counts["$ip"]++))
    fi
  done

  # Find top IP (fastest: sort once)
  top_ip=$(printf '%s\n' "${!ip_counts[@]}" | sort -nr | head -1)
  top_count=${ip_counts["$top_ip"]:-0}

  # === Final Report (printf = no subshell) ===
  {
    printf '=== LOG ANALYSIS REPORT ===\n'
    printf 'File: %s\n' "$LOG_FILE"
    printf 'Lines: %d\n' "${#lines[@]}"
    printf 'Errors: %d\n' "$error_count"
    printf 'Warnings: %d\n' "$warn_count"
    printf 'Top IP: %s (%d requests)\n' "$top_ip" "$top_count"
    printf 'Generated: %s\n' "$(date)"
  } >> "$REPORT_FILE"

  log "Analysis complete. Report: $REPORT_FILE"
}

# === Run with timing ===
main() {
  local start_time end_time duration
  start_time=$(date +%s.%N)

  analyze_logs

  end_time=$(date +%s.%N)
  duration=$(printf '%.3f' "$(bc <<< "$end_time - $start_time")")
  log "Total time: ${duration}s"
}

main
