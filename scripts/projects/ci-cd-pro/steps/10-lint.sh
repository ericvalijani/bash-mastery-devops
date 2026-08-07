#!/usr/bin/env bash
shopt -s globstar
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
log "Running shellcheck & shfmt"
shellcheck --severity=error -x -e SC1091 scripts/**/*.sh
