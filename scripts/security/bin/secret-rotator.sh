#!/usr/bin/env bash
#
# secret-rotator.sh — detect leaked secrets, then rotate + alert.
#
# Usage:
#   ./secret-rotator.sh [path]
#
# Environment:
#   DRY_RUN=true        report findings, take no rotation/alert action (default)
#   DRY_RUN=false       actually rotate the key and post the Slack alert
#   IAM_USER            AWS IAM user whose key gets rotated (required if !DRY_RUN)
#   SLACK_WEBHOOK       webhook for alerts (optional; skipped with a warning)
#   SCAN_PATH           path to scan (default: repo root, or $1)
#
# Exit codes:
#   0  no secrets found
#   1  secrets found (and handled per DRY_RUN)
#   2  prerequisite missing (e.g. gitleaks not installed)

set -euo pipefail
IFS=$'\n\t'
shopt -s inherit_errexit 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

# shellcheck disable=SC2034  # consumed by log_* in the sourced logging library
export COMPONENT="secret-rotator"

DRY_RUN="${DRY_RUN:-true}"
SCAN_PATH="${1:-${SCAN_PATH:-$SCRIPT_DIR/../../..}}"
REPORT="${REPORT:-$(mktemp -t gitleaks-report.XXXXXX.json)}"

# --- preflight ---------------------------------------------------------------
# Fail loudly on a missing scanner. A security gate that silently passes because
# its scanner isn't installed is worse than no gate at all.
if ! command -v gitleaks >/dev/null 2>&1; then
  log_error "gitleaks is not installed — cannot scan. Install: https://github.com/gitleaks/gitleaks"
  exit 2
fi

log_info "Scanning $SCAN_PATH for leaked secrets (dry_run=$DRY_RUN)"

# --- scan --------------------------------------------------------------------
# gitleaks exits 1 when it finds something. That is not an error for us, so the
# call is guarded: under `set -e` an unguarded non-zero exit would abort here
# and the rotation branch below could never run.
scan_rc=0
gitleaks detect \
  --no-git \
  --source "$SCAN_PATH" \
  --report-format json \
  --report-path "$REPORT" \
  --redact \
  --exit-code 1 || scan_rc=$?

if ((scan_rc == 0)); then
  log_info "No secrets found"
  rm -f "$REPORT"
  exit 0
fi

if ((scan_rc != 1)); then
  log_error "gitleaks failed to run (exit $scan_rc)"
  exit 2
fi

finding_count=$(grep -c '"RuleID"' "$REPORT" 2>/dev/null || echo 0)
log_error "LEAKED SECRET DETECTED — $finding_count finding(s). Report: $REPORT"

# --- respond -----------------------------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
  log_warn "DRY_RUN=true — skipping key rotation and alerting. Set DRY_RUN=false to act."
  exit 1
fi

if [[ -z "${IAM_USER:-}" ]]; then
  log_error "IAM_USER is not set — refusing to guess which key to rotate"
  exit 2
fi

# rotate_key is called as `retry 3 5 rotate_key`, i.e. via "$@" inside retry().
# ShellCheck can't see indirect invocation, so it reports the body as
# unreachable (SC2317) and the function as unused (SC2329). Both are false
# positives here. SC2329 only exists in ShellCheck >= 0.11.
# shellcheck disable=SC2317,SC2329
rotate_key() {
  # Create the replacement BEFORE deactivating the old one, or you lock
  # yourself out between the two calls.
  local new_key old_keys
  new_key=$(aws iam create-access-key --user-name "$IAM_USER" \
    --query 'AccessKey.AccessKeyId' --output text)
  log_info "Created replacement access key $new_key for $IAM_USER"

  old_keys=$(aws iam list-access-keys --user-name "$IAM_USER" \
    --query "AccessKeyMetadata[?AccessKeyId!='$new_key'].AccessKeyId" \
    --output text)
  local k
  for k in $old_keys; do
    aws iam update-access-key --user-name "$IAM_USER" \
      --access-key-id "$k" --status Inactive
    log_info "Deactivated old access key $k"
  done
}

if command -v aws >/dev/null 2>&1; then
  # Retry: IAM is eventually consistent and rate-limited.
  # shellcheck source=../../modular/lib/retry.sh
  source "$SCRIPT_DIR/../../modular/lib/retry.sh"
  retry 3 5 rotate_key
else
  log_error "aws CLI not installed — cannot rotate. Manual action required."
fi

if [[ -n "${SLACK_WEBHOOK:-}" ]]; then
  if curl -fsS -X POST -H 'Content-Type: application/json' \
    -d "{\"text\":\"Secret leak detected in ${SCAN_PATH} ($finding_count finding(s)). Key for ${IAM_USER} auto-rotated.\"}" \
    "$SLACK_WEBHOOK" >/dev/null; then
    log_info "Slack alert sent"
  else
    log_warn "Slack alert failed to send"
  fi
else
  log_warn "SLACK_WEBHOOK not set — no alert sent"
fi

exit 1
