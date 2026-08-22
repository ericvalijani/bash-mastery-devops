#!/usr/bin/env bats

load '../../modular/tests/test_helper'

setup() {
  SEC_BIN="$(cd "$BATS_TEST_DIRNAME/../bin" && pwd)"
  export SEC_BIN
  export LOG_FILE="$BATS_TEST_TMPDIR/sec-test.log"
  export FAKEBIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$FAKEBIN" "$BATS_TEST_TMPDIR/scan"
  echo "harmless" >"$BATS_TEST_TMPDIR/scan/ok.txt"
}

# Build a stub `gitleaks` on PATH that exits with a chosen code.
stub_gitleaks() {
  local rc="$1"
  cat >"$FAKEBIN/gitleaks" <<EOF
#!/usr/bin/env bash
# emit a minimal report if a report path was requested
prev=""
for a in "\$@"; do
  [[ "\$prev" == "--report-path" ]] && printf '[{"RuleID":"aws-access-key"}]' > "\$a"
  prev="\$a"
done
exit $rc
EOF
  chmod +x "$FAKEBIN/gitleaks"
}

@test "the script is executable" {
  # Checked first and separately: zip extraction and some copy tools drop the
  # executable bit, which makes every later test fail with a confusing
  # "Permission denied" instead of naming the real cause.
  # Fix: chmod +x scripts/security/bin/secret-rotator.sh
  [ -x "$SEC_BIN/secret-rotator.sh" ]
}

@test "the script parses and its libraries resolve" {
  run bash -n "$SEC_BIN/secret-rotator.sh"
  assert_success
  run bash -c "source '$BATS_TEST_DIRNAME/../lib/logging.sh' && type -t log_info"
  assert_success
  assert_output "function"
}

@test "exits 2 with a clear error when gitleaks is missing" {
  # A security gate must never pass silently because its scanner isn't there.
  # bin_without builds a PATH that genuinely lacks gitleaks but still has
  # bash/date/tee, so this passes whether or not gitleaks is installed here.
  run env PATH="$(bin_without gitleaks)" "$SEC_BIN/secret-rotator.sh" "$BATS_TEST_TMPDIR/scan"
  [ "$status" -eq 2 ]
  assert_output --partial "gitleaks is not installed"
}

@test "exits 0 and reports clean when no secrets are found" {
  stub_gitleaks 0
  run env PATH="$FAKEBIN:$PATH" "$SEC_BIN/secret-rotator.sh" "$BATS_TEST_TMPDIR/scan"
  assert_success
  assert_output --partial "No secrets found"
}

@test "exits 1 and reports the finding when a secret is detected" {
  stub_gitleaks 1
  run env PATH="$FAKEBIN:$PATH" "$SEC_BIN/secret-rotator.sh" "$BATS_TEST_TMPDIR/scan"
  [ "$status" -eq 1 ]
  assert_output --partial "LEAKED SECRET DETECTED"
}

@test "defaults to DRY_RUN and takes no destructive action" {
  stub_gitleaks 1
  run env PATH="$FAKEBIN:$PATH" "$SEC_BIN/secret-rotator.sh" "$BATS_TEST_TMPDIR/scan"
  assert_output --partial "DRY_RUN=true"
  refute_output --partial "Created replacement access key"
}

@test "refuses to rotate when IAM_USER is unset" {
  stub_gitleaks 1
  run env PATH="$FAKEBIN:$PATH" DRY_RUN=false \
    "$SEC_BIN/secret-rotator.sh" "$BATS_TEST_TMPDIR/scan"
  [ "$status" -eq 2 ]
  assert_output --partial "refusing to guess"
}

@test "survives an unset SLACK_WEBHOOK instead of crashing on set -u" {
  # The original used a bare \$SLACK_WEBHOOK under `set -u`, which aborts the
  # script at the exact moment an alert matters most.
  stub_gitleaks 1
  cat >"$FAKEBIN/aws" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *create-access-key*) echo "AKIANEWKEY000000" ;;
  *list-access-keys*)  echo "" ;;
  *)                   exit 0 ;;
esac
EOF
  chmod +x "$FAKEBIN/aws"
  run env PATH="$FAKEBIN:$PATH" DRY_RUN=false IAM_USER=svc-deploy \
    "$SEC_BIN/secret-rotator.sh" "$BATS_TEST_TMPDIR/scan"
  [ "$status" -eq 1 ]
  assert_output --partial "Created replacement access key"
  assert_output --partial "SLACK_WEBHOOK not set"
}
