#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/app/json.log"
REPORT="json-report-$(date +%Y%m%d).txt"

mapfile -t lines < <(tail -100000 "$LOG_FILE")

echo "Analysing 100,000 JSON log..." > "$REPORT"
{
  printf "Error: %s\n" "$(echo "${lines[@]}" | jq -r 'select(.level=="ERROR") | .message' | wc -l)"
  printf "Warning: %s\n" "$(echo "${lines[@]}" | jq -r 'select(.level=="WARN") | .message' | wc -l)"
  echo "Top 5 IPها:"
  echo "${lines[@]}" | jq -r '.ip' | sort | uniq -c | sort -nr | head -5
} >> "$REPORT"

echo "Report saved: $REPORT"
