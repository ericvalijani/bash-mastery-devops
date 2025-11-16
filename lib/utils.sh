#!/usr/bin/env bash
# lib/utils.sh — Common helpers

is_command() { command -v "$1" >/dev/null 2>&1; }

require_command() {
  for cmd in "$@"; do
    is_command "$cmd" || { log_error "Required command not found: $cmd"; exit 1; }
  done
}
