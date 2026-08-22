#!/usr/bin/env bats

load 'test_helper'

setup() {
  export COMPONENT="test"
  export LOG_FILE="$BATS_TEST_TMPDIR/bash-test.log"
  export LOCK_FILE="$BATS_TEST_TMPDIR/test.lock"
  L="source '$LIB_DIR/logging.sh'; source '$LIB_DIR/lock.sh';"
}

@test "acquire_lock succeeds when nothing else holds the lock" {
  run bash -c "$L acquire_lock; echo ACQUIRED"
  assert_success
  assert_output --partial "ACQUIRED"
}

@test "acquire_lock writes the holder's PID into the lock file" {
  run bash -c "$L acquire_lock; echo \$\$"
  assert_success
  pid="$(tail -1 <<<"$output")"
  [ "$(cat "$LOCK_FILE")" = "$pid" ]
}

@test "a second instance is refused while the first holds the lock" {
  bash -c "$L acquire_lock; sleep 3" &
  holder=$!
  sleep 0.5
  run bash -c "$L acquire_lock; echo SHOULD_NOT_GET_HERE"
  assert_failure
  assert_output --partial "Another instance is running"
  refute_output --partial "SHOULD_NOT_GET_HERE"
  kill "$holder" 2>/dev/null || true
  wait "$holder" 2>/dev/null || true
}

@test "the lock is released when the holder exits, so the next run succeeds" {
  bash -c "$L acquire_lock"
  run bash -c "$L acquire_lock; echo ACQUIRED"
  assert_success
  assert_output --partial "ACQUIRED"
}

@test "the lock is released even when the holder is killed" {
  bash -c "$L acquire_lock; sleep 30" &
  holder=$!
  sleep 0.5
  kill -TERM "$holder" 2>/dev/null || true
  wait "$holder" 2>/dev/null || true
  run bash -c "$L acquire_lock; echo ACQUIRED"
  assert_success
  assert_output --partial "ACQUIRED"
}

@test "release_lock is a no-op when the lock was never acquired" {
  # Regression: the trap used to be registered at source time, so a failure
  # before acquire_lock ran release_lock against an unopened FD 200 and
  # printed 'flock: 200: Bad file descriptor' to stderr.
  run bash -c "$L release_lock 2>&1"
  assert_success
  refute_output --partial "Bad file descriptor"
}

@test "an early failure before acquire_lock produces no lock noise on stderr" {
  export SRC="$BATS_TEST_TMPDIR/missing"
  export BACKUP_DIR="$BATS_TEST_TMPDIR/bk"
  mkdir -p "$BACKUP_DIR"
  run bash -c "'$MODULES_DIR/backup-manager.sh' 2>&1 1>/dev/null"
  assert_output ""
}

@test "the lock file is not deleted on release" {
  # Deleting it would let a waiting process open a different inode while
  # another still holds the old one — both would think they own the lock.
  bash -c "$L acquire_lock"
  [ -f "$LOCK_FILE" ]
}
