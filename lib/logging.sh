#!/usr/bin/env bash
# lib/logging.sh — Structured logging

log() {
  local level="$1"
  shift
  printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$level" "$*" # Print a structured log entry with timestamp, log level, and message using printf
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@" >&2; }
log_debug() { [[ "${DEBUG:-false}" == true ]] && log "DEBUG" "$@"; }
