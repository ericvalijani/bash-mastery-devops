#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
shopt -s inherit_errexit 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/retry.sh"
source "$SCRIPT_DIR/../lib/lock.sh"
# shellcheck source=../lib/validator.sh
source "$SCRIPT_DIR/../lib/validator.sh"

# shellcheck disable=SC2034  # consumed by log_* in lib/logging.sh
export COMPONENT="deploy"

RELEASE_SRC="${RELEASE_SRC:-/tmp/new-release}"
APP_DIR="${APP_DIR:-/var/www/myapp}"

# Fail fast, before acquiring a lock or touching the filesystem.
require_var RELEASE_SRC APP_DIR
require_safe_path "$RELEASE_SRC"
require_safe_path "$APP_DIR"
require_dir "$RELEASE_SRC"
require_writable "$APP_DIR"

acquire_lock

log_info "Starting deploy from $RELEASE_SRC"

do_deploy() {
  local release_dir
  release_dir="$APP_DIR/releases/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$release_dir"
  cp -r "$RELEASE_SRC/." "$release_dir/"
  ln -sfn "$release_dir" "$APP_DIR/current"
}

retry 3 5 do_deploy

log_info "Deploy completed successfully"
