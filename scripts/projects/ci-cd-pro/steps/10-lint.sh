#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
log "Running shellcheck & shfmt"
shellcheck scripts/**/*.sh
