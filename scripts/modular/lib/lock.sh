#!/usr/bin/env bash
# scripts/modular/lib/lock.sh
# Prevent concurrent execution using flock on a dedicated file descriptor.

_LOCK_HELD=0

acquire_lock() {
  local lockfile="${LOCK_FILE:-/var/run/$(basename "$0").lock}"
  exec 200>"$lockfile"
  if ! flock -n 200; then
    log_error "Another instance is running (lock: $lockfile)"
    exit 1
  fi
  _LOCK_HELD=1
  echo $$ >&200
  # Register the trap only once the lock is actually held. Registering it at
  # source time means release_lock also fires on failures that happen *before*
  # acquire_lock — closing FD 200 that was never opened.
  trap release_lock EXIT INT TERM
}

release_lock() {
  [[ "${_LOCK_HELD:-0}" == 1 ]] || return 0
  flock -u 200 2>/dev/null || true
  _LOCK_HELD=0
  # The lock file is deliberately NOT deleted. Removing it lets a waiting
  # process open a fresh inode while another still holds the old one, so both
  # believe they own the lock. A stale zero-byte file is harmless; flock's
  # state lives in the kernel, not in the file's existence.
}
