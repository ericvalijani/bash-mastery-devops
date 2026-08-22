#!/usr/bin/env bash
# scripts/security/lib/logging.sh
#
# Day 7 reuses Day 6's structured JSON logger rather than shipping a third
# divergent copy of log_info/log_warn/log_error. (The repo already has two
# incompatible pairs at lib/ and scripts/modular/lib/ — that's the exact
# maintainability problem Day 6 is about. Don't add a third.)

_SEC_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../modular/lib/logging.sh
source "$_SEC_LIB_DIR/../../modular/lib/logging.sh"
