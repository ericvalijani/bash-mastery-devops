#!/usr/bin/env bash
# lib/retry.sh — Correct retry with command as last args

retry() {
  local max_attempts=${1:-3}
  local delay=${2:-2}
  shift 2                    
  local attempt=1

  while (( attempt <= max_attempts )); do
    "$@" && return 0         
    log_warn "Attempt $attempt failed. Retrying in ${delay}s..."
    sleep "$delay"
    ((attempt++))
    delay=$((delay * 2))
  done

  log_error "All $max_attempts attempts failed"
  return 1
}
