#!/usr/bin/env bats

load 'test_helper'

setup() {
  export COMPONENT="test"
  export LOG_FILE="$BATS_TEST_TMPDIR/bash-test.log"
  export LOCK_FILE="$BATS_TEST_TMPDIR/backup.lock"
  export SRC="$BATS_TEST_TMPDIR/src"
  export BACKUP_DIR="$BATS_TEST_TMPDIR/backup"
  mkdir -p "$SRC" "$BACKUP_DIR"
  echo "test" >"$SRC/index.html"
  echo "SECRET=abc" >"$SRC/.env"
}

@test "backup-manager runs end to end and copies content" {
  run "$MODULES_DIR/backup-manager.sh"
  assert_success
  assert_output --partial "Backup completed successfully"
  # exactly one timestamped snapshot dir was produced
  run bash -c "ls -d \"$BACKUP_DIR\"/*/ | wc -l"
  assert_output "1"
}

@test "backup-manager copies hidden files, not just visible ones" {
  run "$MODULES_DIR/backup-manager.sh"
  assert_success
  snapshot=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
  [ -f "$snapshot/index.html" ]
  [ -f "$snapshot/.env" ]
}

@test "backup-manager honours SRC/BACKUP_DIR overrides instead of hardcoded paths" {
  # The whole point of making these configurable: no write to /var/www or
  # /backup/data should ever be attempted during a test run.
  run "$MODULES_DIR/backup-manager.sh"
  assert_success
  [ ! -e "/backup/data" ]
}

@test "retry runs the intended command, not the attempt count" {
  # Regression test for the original bug: retry() never shifted its numeric
  # arguments, so it executed '3' as a command and could never succeed.
  run bash -c "source '$LIB_DIR/logging.sh'; source '$LIB_DIR/retry.sh'; retry 3 1 echo hello"
  assert_success
  assert_output --partial "hello"
}

@test "retry retries a failing command and eventually succeeds" {
  counter="$BATS_TEST_TMPDIR/attempts"
  echo 0 >"$counter"
  run bash -c "
    source '$LIB_DIR/logging.sh'
    source '$LIB_DIR/retry.sh'
    flaky() {
      n=\$(< '$counter'); n=\$((n + 1)); echo \"\$n\" > '$counter'
      (( n >= 3 ))
    }
    retry 3 1 flaky
  "
  assert_success
  [ "$(cat "$counter")" -eq 3 ]
}

@test "retry gives up and reports failure after max attempts" {
  run bash -c "source '$LIB_DIR/logging.sh'; source '$LIB_DIR/retry.sh'; retry 2 1 false"
  assert_failure
  assert_output --partial "All 2 attempts failed"
}
