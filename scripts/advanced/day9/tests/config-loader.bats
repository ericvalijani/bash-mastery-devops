#!/usr/bin/env bats

# Reuses Day 6's helper purely for portable bats-support / bats-assert loading,
# exactly like Day 8's monitor.bats does.
load '../../../modular/tests/test_helper'

setup() {
  LOADER="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/config-loader.sh"
  APP="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/app.sh"
  export LOADER APP
  # Every test gets its own throwaway config, so nothing touches the repo .env.
  export CONFIG_FILE="$BATS_TEST_TMPDIR/.env"
}

# Write a valid .env for the happy-path tests to start from.
write_valid_env() {
  cat >"$CONFIG_FILE" <<'EOF'
APP_ENV=staging
TARGET_HOST=localhost
TARGET_PORT=443
API_KEY=sk-secure-test-1234567890
DB_PASS=supersecret
SSH_KEY=-----BEGIN-RSA-PRIVATE-KEY-----
EOF
}

@test "both scripts are executable" {
  [ -x "$LOADER" ]
  [ -x "$APP" ]
}

@test "loads a valid .env and reports success" {
  write_valid_env
  run bash "$LOADER"
  assert_success
  assert_output --partial "Config loaded successfully"
  assert_output --partial "Target: localhost:443"
}

@test "exits 1 with a clear error when the config file is missing" {
  export CONFIG_FILE="$BATS_TEST_TMPDIR/does-not-exist.env"
  run bash "$LOADER"
  assert_failure
  assert_output --partial "Config file not found"
}

@test "fails and names every missing required variable" {
  cat >"$CONFIG_FILE" <<'EOF'
APP_ENV=dev
EOF
  run bash "$LOADER"
  assert_failure
  assert_output --partial "Missing required variables"
  assert_output --partial "TARGET_HOST"
  assert_output --partial "API_KEY"
}

@test "uses TARGET_HOST, not the old DB_HOST name" {
  # Regression: the old loader required DB_HOST, which never existed in
  # .env.example. A file that matches the template must load cleanly.
  cat >"$CONFIG_FILE" <<'EOF'
APP_ENV=prod
TARGET_HOST=10.0.0.10
API_KEY=sk-live-abcdef
EOF
  run bash "$LOADER"
  assert_success
  assert_output --partial "Target: 10.0.0.10:443"
}

@test "applies defaults for optional variables" {
  cat >"$CONFIG_FILE" <<'EOF'
APP_ENV=dev
TARGET_HOST=localhost
API_KEY=sk-x
EOF
  run bash "$LOADER"
  assert_success
  # TARGET_PORT defaults to 443, DEBUG to false.
  assert_output --partial "localhost:443"
  assert_output --partial "Debug: false"
}

@test "rejects an invalid APP_ENV" {
  cat >"$CONFIG_FILE" <<'EOF'
APP_ENV=production
TARGET_HOST=localhost
API_KEY=sk-x
EOF
  run bash "$LOADER"
  assert_failure
  assert_output --partial "APP_ENV must be one of"
}

@test "rejects a non-numeric TARGET_PORT" {
  cat >"$CONFIG_FILE" <<'EOF'
APP_ENV=dev
TARGET_HOST=localhost
TARGET_PORT=https
API_KEY=sk-x
EOF
  run bash "$LOADER"
  assert_failure
  assert_output --partial "TARGET_PORT must be numeric"
}

@test "never sources the .env: a command in the file is not executed" {
  # The whole reason we parse instead of \`source\`. If the loader sourced the
  # file, the injected command would run and create this marker.
  cat >"$CONFIG_FILE" <<EOF
APP_ENV=dev
TARGET_HOST=localhost
API_KEY=sk-x
\$(touch "$BATS_TEST_TMPDIR/pwned")
EOF
  run bash "$LOADER"
  assert_success
  [ ! -f "$BATS_TEST_TMPDIR/pwned" ]
}

@test "masks the API key instead of printing it in the clear" {
  write_valid_env
  run bash "$LOADER"
  assert_success
  refute_output --partial "sk-secure-test-1234567890"
  assert_output --partial "API_KEY: sk"
}

@test "app.sh sources the loader and connects with the loaded config" {
  write_valid_env
  run bash "$APP"
  assert_success
  assert_output --partial "Connecting to localhost:443 as staging"
  assert_output --partial "key present: yes"
}

@test "app.sh works from any working directory (path resolved via BASH_SOURCE)" {
  # Regression: the old app.sh hardcoded a repo-root-relative source path.
  write_valid_env
  cd /tmp
  run bash "$APP"
  assert_success
  assert_output --partial "Connecting to localhost:443"
}
