#!/usr/bin/env bash
# scripts/modular/lib/validator.sh
#
# Precondition checks. Fail early with a clear message, instead of failing
# deep inside rsync/cp with something cryptic.
#
# Every function returns 1 on failure and logs via log_error, so under
# `set -e` a failed check aborts the script on the line that caused it.
# Requires lib/logging.sh to be sourced first.

# require_var NAME [NAME...] — variable is set and non-empty
require_var() {
  local name rc=0
  for name in "$@"; do
    if [[ -z "${!name:-}" ]]; then
      log_error "Required variable '$name' is unset or empty"
      rc=1
    fi
  done
  return $rc
}

# require_cmd CMD [CMD...] — executable exists on PATH
require_cmd() {
  local cmd rc=0
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_error "Required command '$cmd' not found on PATH"
      rc=1
    fi
  done
  return $rc
}

# require_dir PATH — exists and is a directory
require_dir() {
  local path="${1:-}"
  if [[ -z "$path" ]]; then
    log_error "require_dir called without a path"
    return 1
  fi
  if [[ ! -e "$path" ]]; then
    log_error "Directory does not exist: $path"
    return 1
  fi
  if [[ ! -d "$path" ]]; then
    log_error "Path exists but is not a directory: $path"
    return 1
  fi
}

# require_file PATH — exists and is a regular file
require_file() {
  local path="${1:-}"
  if [[ -z "$path" ]]; then
    log_error "require_file called without a path"
    return 1
  fi
  if [[ ! -e "$path" ]]; then
    log_error "File does not exist: $path"
    return 1
  fi
  if [[ ! -f "$path" ]]; then
    log_error "Path exists but is not a regular file: $path"
    return 1
  fi
}

# require_writable PATH — writable dir, or a file in a writable dir.
# Checks the nearest existing ancestor, so it also validates paths you're
# about to create.
require_writable() {
  local path="${1:-}"
  if [[ -z "$path" ]]; then
    log_error "require_writable called without a path"
    return 1
  fi
  local probe="$path"
  while [[ ! -e "$probe" && "$probe" != "/" && "$probe" != "." ]]; do
    probe="$(dirname "$probe")"
  done
  if [[ ! -w "$probe" ]]; then
    log_error "Not writable: $path (blocked at $probe)"
    return 1
  fi
}

# require_int NAME — variable holds a non-negative integer
require_int() {
  local name="${1:-}"
  require_var "$name" || return 1
  if [[ ! "${!name}" =~ ^[0-9]+$ ]]; then
    log_error "Variable '$name' must be a non-negative integer, got: ${!name}"
    return 1
  fi
}

# require_port NAME — variable holds a valid TCP port (1-65535)
require_port() {
  local name="${1:-}"
  require_int "$name" || return 1
  local v="${!name}"
  if ((v < 1 || v > 65535)); then
    log_error "Variable '$name' must be a port in 1-65535, got: $v"
    return 1
  fi
}

# require_safe_path PATH — reject empty, "/", and paths containing ".."
# Guards against a mistyped variable turning `rm -rf "$DIR"` into a disaster.
require_safe_path() {
  local path="${1:-}"
  if [[ -z "$path" ]]; then
    log_error "Refusing to operate on an empty path"
    return 1
  fi
  if [[ "$path" == "/" ]]; then
    log_error "Refusing to operate on filesystem root"
    return 1
  fi
  if [[ "$path" == *".."* ]]; then
    log_error "Refusing path containing '..': $path"
    return 1
  fi
}
