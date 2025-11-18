#!/usr/bin/env bash
# scripts/projects/log-analyzer-pro/main.sh
set -euo pipefail

readonly BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/config.env" 2>/dev/null || true
source "$BASE_DIR/../../lib/logging.sh"
source "$BASE_DIR/parser.sh"
source "$BASE_DIR/reporter.sh"

LOG_SOURCES=("${@:-/var/log/*.log}")
REPORT_DIR="/tmp/log-analyzer-pro-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REPORT_DIR"

main() {
  local start=$(date +%s.%N)
  log_info "Starting distributed log analysis..."

  # Parallel collection and processing
  printf '%s\0' "${LOG_SOURCES[@]}" | xargs -0 -P 20 -I {} bash "$BASE_DIR/collector.sh" {}

  # Final conclusion
  generate_json_report > "$REPORT_DIR/report.json"
  generate_prometheus_metrics > "$REPORT_DIR/prometheus_metrics.txt"

  local end=$(date +%s.%N)
  local duration=$(printf '%.3f' "$(bc <<< "$end - $start")")

  log_info "Analysis completed in ${duration}s"
  log_info "Reports: $REPORT_DIR"
  echo "JSON Report: $REPORT_DIR/report.json"
  echo "Prometheus:  $REPORT_DIR/prometheus_metrics.txt"
}

main
