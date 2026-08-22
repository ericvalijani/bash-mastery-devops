#!/usr/bin/env bats

# Reuses Day 6's helper purely for portable bats-support / bats-assert loading.
load '../../../modular/tests/test_helper'

setup() {
  MONITOR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/monitor.sh"
  export MONITOR
  export LOG_FILE="$BATS_TEST_TMPDIR/monitor.log"
}

@test "the script is executable" {
  [ -x "$MONITOR" ]
}

@test "exits 1 with a clear error when the target PID does not exist" {
  # PID 4194304 is above the default pid_max on Linux, so it can never be live.
  run "$MONITOR" 4194304 1
  assert_failure
  assert_output --partial "not found or not accessible"
}

@test "monitors a live process and reports CPU and memory" {
  sleep 3 >/dev/null 2>&1 &
  local target=$!
  run timeout 20 "$MONITOR" "$target" 1
  assert_success
  assert_output --partial "Started monitoring PID $target"
  assert_output --partial "CPU="
  assert_output --partial "MEM="
}

@test "exits on its own once the target process terminates" {
  sleep 2 >/dev/null 2>&1 &
  local target=$!
  run timeout 20 "$MONITOR" "$target" 1
  assert_success
  assert_output --partial "Process $target has terminated"
}

@test "honours the LOG_FILE override instead of writing to /tmp/process-monitor.log" {
  # Configurable paths are what make the script testable at all — without this
  # every run would share one global file in /tmp.
  sleep 2 >/dev/null 2>&1 &
  local target=$!
  run timeout 20 "$MONITOR" "$target" 1
  assert_success
  [ -f "$LOG_FILE" ]
  run grep -c "MONITOR" "$LOG_FILE"
  [ "$output" -gt 0 ]
}

@test "the cleanup trap runs when the monitor is sent SIGTERM" {
  # Background jobs must have their stdout/stderr redirected. BATS captures test
  # output through a pipe, and a background process inheriting that pipe keeps
  # it open — so the test would block until the process exits on its own
  # (a `sleep 30` target made this single test take 30s instead of ~2s).
  sleep 8 >/dev/null 2>&1 &
  local target=$!
  "$MONITOR" "$target" 1 >"$BATS_TEST_TMPDIR/out.txt" 2>&1 &
  local mon=$!
  sleep 1.5
  kill -TERM "$mon" 2>/dev/null || true
  # `wait ... || true` would reset $? to 0 before it could be captured.
  local rc=0
  wait "$mon" 2>/dev/null || rc=$?
  kill "$target" 2>/dev/null || true
  wait "$target" 2>/dev/null || true

  # 143 = 128 + 15. A trap that only returns would leave the monitor running
  # until the target died on its own, and this test would take 8s not ~2s.
  [ "$rc" -eq 143 ]
  run cat "$BATS_TEST_TMPDIR/out.txt"
  assert_output --partial "Received SIGTERM"
  assert_output --partial "Monitor stopped"
  # cleanup must run exactly once, not twice
  run grep -c "Monitor stopped" "$BATS_TEST_TMPDIR/out.txt"
  assert_output "1"
}

# Note: SIGINT is deliberately not tested. A background job in a non-interactive
# shell inherits SIGINT as SIG_IGN (POSIX), and bash cannot trap a signal that
# was already ignored on entry — so it cannot be delivered from a test harness.
# The SIGINT handler is written identically to the SIGTERM one above and works
# for a real Ctrl+C on a foreground process.

@test "a successful run still exits 0 when the log path is unwritable" {
  # Regression: the EXIT trap used to end with `[[ -f "$LOG_FILE" ]] && echo ...`.
  # A trap returns the status of its last command, so a missing log file
  # silently replaced a successful exit code with 1.
  mkdir -p "$BATS_TEST_TMPDIR/ro"
  chmod 500 "$BATS_TEST_TMPDIR/ro"
  sleep 2 >/dev/null 2>&1 &
  local target=$!
  run env LOG_FILE="$BATS_TEST_TMPDIR/ro/nope.log" timeout 20 "$MONITOR" "$target" 1
  chmod 700 "$BATS_TEST_TMPDIR/ro"
  assert_success
  assert_output --partial "Process $target has terminated"
}
