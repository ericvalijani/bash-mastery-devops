#!/usr/bin/env bats

load 'test_helper'

setup() {
  export COMPONENT="test"
  export LOG_FILE="$BATS_TEST_TMPDIR/bash-test.log"
  V="source '$LIB_DIR/logging.sh'; source '$LIB_DIR/validator.sh';"
}

# --- require_var --------------------------------------------------------------

@test "require_var accepts a set, non-empty variable" {
  run bash -c "$V FOO=bar; require_var FOO"
  assert_success
}

@test "require_var rejects an unset variable" {
  run bash -c "$V require_var NOPE"
  assert_failure
  assert_output --partial "Required variable 'NOPE' is unset or empty"
}

@test "require_var rejects a set-but-empty variable" {
  run bash -c "$V EMPTY=''; require_var EMPTY"
  assert_failure
}

@test "require_var reports every missing variable, not just the first" {
  run bash -c "$V require_var ONE TWO"
  assert_failure
  assert_output --partial "'ONE'"
  assert_output --partial "'TWO'"
}

# --- require_cmd --------------------------------------------------------------

@test "require_cmd accepts a command that exists" {
  run bash -c "$V require_cmd bash"
  assert_success
}

@test "require_cmd rejects a missing command" {
  run bash -c "$V require_cmd definitely-not-a-real-binary-xyz"
  assert_failure
  assert_output --partial "not found on PATH"
}

# --- require_dir / require_file -----------------------------------------------

@test "require_dir accepts an existing directory" {
  run bash -c "$V require_dir '$BATS_TEST_TMPDIR'"
  assert_success
}

@test "require_dir rejects a missing path" {
  run bash -c "$V require_dir '$BATS_TEST_TMPDIR/nope'"
  assert_failure
  assert_output --partial "Directory does not exist"
}

@test "require_dir distinguishes a file from a directory" {
  touch "$BATS_TEST_TMPDIR/afile"
  run bash -c "$V require_dir '$BATS_TEST_TMPDIR/afile'"
  assert_failure
  assert_output --partial "is not a directory"
}

@test "require_file accepts a regular file and rejects a directory" {
  touch "$BATS_TEST_TMPDIR/afile"
  run bash -c "$V require_file '$BATS_TEST_TMPDIR/afile'"
  assert_success
  run bash -c "$V require_file '$BATS_TEST_TMPDIR'"
  assert_failure
  assert_output --partial "is not a regular file"
}

# --- require_writable ---------------------------------------------------------

@test "require_writable accepts a writable existing directory" {
  run bash -c "$V require_writable '$BATS_TEST_TMPDIR'"
  assert_success
}

@test "require_writable accepts a path that does not exist yet but could be created" {
  run bash -c "$V require_writable '$BATS_TEST_TMPDIR/new/deeper/file.txt'"
  assert_success
}

@test "require_writable rejects a path under a read-only directory" {
  mkdir -p "$BATS_TEST_TMPDIR/ro"
  chmod 500 "$BATS_TEST_TMPDIR/ro"
  run bash -c "$V require_writable '$BATS_TEST_TMPDIR/ro/sub/x'"
  chmod 700 "$BATS_TEST_TMPDIR/ro"
  assert_failure
  assert_output --partial "Not writable"
}

# --- require_int / require_port -----------------------------------------------

@test "require_int accepts digits and rejects non-numeric" {
  run bash -c "$V N=42; require_int N"
  assert_success
  run bash -c "$V N=4x2; require_int N"
  assert_failure
  assert_output --partial "non-negative integer"
}

@test "require_port accepts a valid port and rejects out-of-range" {
  run bash -c "$V P=443; require_port P"
  assert_success
  run bash -c "$V P=70000; require_port P"
  assert_failure
  assert_output --partial "1-65535"
  run bash -c "$V P=0; require_port P"
  assert_failure
}

# --- require_safe_path --------------------------------------------------------

@test "require_safe_path refuses root, empty, and traversal" {
  run bash -c "$V require_safe_path /"
  assert_failure
  assert_output --partial "filesystem root"
  run bash -c "$V require_safe_path ''"
  assert_failure
  run bash -c "$V require_safe_path '/var/www/../../etc'"
  assert_failure
  assert_output --partial "'..'"
}

@test "require_safe_path accepts an ordinary path" {
  run bash -c "$V require_safe_path '/var/www/myapp'"
  assert_success
}

# --- integration: the modules actually use it ---------------------------------

@test "backup-manager fails fast with a clear message when SRC is missing" {
  export SRC="$BATS_TEST_TMPDIR/does-not-exist"
  export BACKUP_DIR="$BATS_TEST_TMPDIR/backup"
  export LOCK_FILE="$BATS_TEST_TMPDIR/b.lock"
  mkdir -p "$BACKUP_DIR"
  run "$MODULES_DIR/backup-manager.sh"
  assert_failure
  assert_output --partial "Directory does not exist"
  # and it stopped before doing any work
  run bash -c "ls -A '$BACKUP_DIR' | wc -l"
  assert_output "0"
}

@test "deploy fails fast with a clear message when RELEASE_SRC is missing" {
  export RELEASE_SRC="$BATS_TEST_TMPDIR/nothing-here"
  export APP_DIR="$BATS_TEST_TMPDIR/myapp"
  export LOCK_FILE="$BATS_TEST_TMPDIR/d.lock"
  run "$MODULES_DIR/deploy.sh"
  assert_failure
  assert_output --partial "Directory does not exist"
  [ ! -e "$APP_DIR/current" ]
}
