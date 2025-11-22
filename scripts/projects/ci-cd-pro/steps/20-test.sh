#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
log "Running tests"
[[ -d tests ]] && bats tests/ || log "No tests found – skipping"
