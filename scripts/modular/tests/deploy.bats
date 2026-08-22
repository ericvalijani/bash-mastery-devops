#!/usr/bin/env bats

load 'test_helper'

setup() {
  export COMPONENT="test"
  export LOG_FILE="$BATS_TEST_TMPDIR/bash-test.log"
  export LOCK_FILE="$BATS_TEST_TMPDIR/deploy.lock"
  export RELEASE_SRC="$BATS_TEST_TMPDIR/new-release"
  export APP_DIR="$BATS_TEST_TMPDIR/myapp"
  mkdir -p "$RELEASE_SRC"
  echo "<h1>hello</h1>" >"$RELEASE_SRC/index.html"
  echo "SECRET=abc" >"$RELEASE_SRC/.env"
}

@test "deploy creates a release and points current at it" {
  run "$MODULES_DIR/deploy.sh"
  assert_success
  assert_output --partial "Deploy completed successfully"
  [ -L "$APP_DIR/current" ]
  [ -f "$APP_DIR/current/index.html" ]
}

@test "deploy includes hidden files, not just visible ones" {
  # Day 4's deploy-with-rollback.sh shipped a naive glob that silently dropped
  # dotfiles; this asserts the same class of bug isn't reintroduced here.
  run "$MODULES_DIR/deploy.sh"
  assert_success
  [ -f "$APP_DIR/current/.env" ]
}

@test "deploy is repeatable and repoints current at the newest release" {
  run "$MODULES_DIR/deploy.sh"
  assert_success
  first=$(readlink -f "$APP_DIR/current")
  sleep 1
  echo "<h1>v2</h1>" >"$RELEASE_SRC/index.html"
  run "$MODULES_DIR/deploy.sh"
  assert_success
  second=$(readlink -f "$APP_DIR/current")
  [ "$first" != "$second" ]
  run cat "$APP_DIR/current/index.html"
  assert_output --partial "v2"
  # the previous release is kept on disk for rollback
  [ -d "$first" ]
}

@test "deploy retries a transient failure via the shared retry lib" {
  counter="$BATS_TEST_TMPDIR/attempts"
  echo 0 >"$counter"
  run bash -c "
    source '$LIB_DIR/logging.sh'
    source '$LIB_DIR/retry.sh'
    flaky_deploy() {
      n=\$(< '$counter'); n=\$((n + 1)); echo \"\$n\" > '$counter'
      (( n >= 2 ))
    }
    retry 3 1 flaky_deploy
  "
  assert_success
  [ "$(cat "$counter")" -eq 2 ]
}
