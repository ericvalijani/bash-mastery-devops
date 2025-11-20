#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/20-test.sh
# Run all BATS tests

set -euo pipefail

log "Running BATS tests..."
if ! command -v bats >/dev/null; then
  log_error "BATS not installed"
  exit 1
fi

bats tests/ || {
  log_error "Tests failed"
  exit 1
}

log "All tests passed"
