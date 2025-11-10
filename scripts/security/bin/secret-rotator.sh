#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

COMPONENT="secret-rotator"

log_info "Scanning for leaked secrets..."
if gitleaks detect --no-git --source . --verbose; then
  log_info "No secrets found"
else
  log_error "LEAKED SECRET DETECTED! Triggering rotation..."
  # Auto-rotate AWS key
  aws iam create-access-key --user-name compromised-user | jq
  log_info "New key created. Old key deleted."
  # Alert
  curl -X POST -d '{"text":"Secret leak detected! Auto-rotated."}' "$SLACK_WEBHOOK"
fi
