#!/usr/bin/env bash
# scripts/modular/lib/logging.sh
# Structured JSON logger for production.

LOG_FILE="${LOG_FILE:-/var/log/bash-app.log}"

# If the log file isn't writable (very common: the default lives under
# /var/log and the script isn't running as root), fall back to stdout-only
# rather than emitting "tee: Permission denied" alongside every log line.
if ! { [[ -w "$LOG_FILE" ]] ||
  { [[ ! -e "$LOG_FILE" ]] && [[ -w "$(dirname "$LOG_FILE")" ]]; }; }; then
  LOG_FILE="/dev/null"
fi
readonly LOG_FILE

log() {
  local level="$1" message="$2" component="${3:-main}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  printf '{"timestamp":"%s","level":"%s","component":"%s","message":"%s"}\n' \
    "$timestamp" "$level" "$component" "$message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$1" "${COMPONENT:-unknown}"; }
log_warn() { log "WARN" "$1" "${COMPONENT:-unknown}"; }
log_error() { log "ERROR" "$1" "${COMPONENT:-unknown}"; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && log "DEBUG" "$1" "${COMPONENT:-unknown}"; }
