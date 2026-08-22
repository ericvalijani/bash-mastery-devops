# Day 8 — Process Management, Signals, Job Control, and Graceful Shutdown

Today's goal: run work in the background, control it, and shut it down cleanly
when someone sends a signal — instead of leaving half-finished state and stale
lock files behind.

---

## 📁 Scripts for today

All live in `scripts/advanced/day8/`.

| # | File | What it does | Try it |
|---|---|---|---|
| 1 | `monitor.sh` | Watches a process by PID and logs its CPU and memory every N seconds, stopping when the process exits or when it receives a signal | `./scripts/advanced/day8/monitor.sh $$ 2` |
| 2 | `tests/monitor.bats` | 7 tests covering the PID check, the log override, and signal shutdown | `bats scripts/advanced/day8/tests/` |

> **⚠️ `monitor.sh` runs until its target exits.** Pointed at your own shell
> (`$$`) it will keep going until you `Ctrl+C` it — that's intentional, not a
> hang. Pass a short-lived PID to see it finish on its own.

---

## 1. Background execution

```bash
sleep 10 &          # run in the background
echo $!             # PID of the most recent background job
wait $!             # block until it finishes
```

`$!` is only valid immediately after launching the job — capture it into a
variable straight away, because the next `&` overwrites it:

```bash
long_task &
task_pid=$!         # do this now, not three lines later
```

`wait` with no arguments waits for *every* background job, which is how you fan
out work and then rejoin:

```bash
for host in web1 web2 web3; do
  ping -c1 "$host" &
done
wait                # all three pings run concurrently
```

---

## 2. Job control

```bash
sleep 100 &
jobs                # list this shell's jobs
fg %1               # bring job 1 to the foreground
bg %1               # resume job 1 in the background
kill %1             # kill by job spec instead of PID
```

Job specs (`%1`) are a feature of the *interactive* shell. Inside a script,
work with PIDs — job control is disabled by default in non-interactive shells.

---

## 3. Signals

| Signal | Number | Meaning | Catchable |
|---|---|---|---|
| `SIGINT` | 2 | Ctrl+C from the terminal | yes |
| `SIGQUIT` | 3 | Ctrl+\ , dumps core | yes |
| `SIGTERM` | 15 | polite "please stop" — what `kill` sends by default | yes |
| `SIGKILL` | 9 | immediate, from the kernel | **no** |

```bash
kill -TERM "$pid"    # ask nicely; the process can clean up
kill -KILL "$pid"    # last resort; no cleanup is possible
```

Always try `SIGTERM` first. `SIGKILL` cannot be trapped, so the process gets no
chance to remove its lock file, flush its log, or finish a write.

The shell's convention for a signal death is exit code **128 + signal number**:
130 for SIGINT, 143 for SIGTERM. Returning those from your own handler keeps
your script consistent with everything else.

---

## 4. Trap — and the mistake that makes it useless

```bash
cleanup() { rm -f /tmp/myapp.lock; }
trap cleanup EXIT
```

`EXIT` fires on every exit path — success, failure, or `set -e` abort — so it's
the right place for cleanup.

Signals are different, and this is the part that's easy to get wrong:

```bash
trap cleanup EXIT SIGINT SIGTERM     # looks correct, isn't
```

**A signal handler that only returns doesn't stop your script.** Bash runs the
handler and then resumes exactly where it was interrupted. Attached like that,
`monitor.sh` printed "Monitor stopped" on SIGTERM and then carried on
monitoring. Separate the two:

```bash
trap cleanup EXIT
trap 'log "Received SIGTERM — shutting down"; exit 143' SIGTERM
trap 'log "Received SIGINT — shutting down"; exit 130' SIGINT
```

The handler exits, that exit fires the `EXIT` trap, and cleanup runs exactly
once.

### A trap can overwrite your exit code

An `EXIT` trap returns the status of its own last command. So this quietly turns
a successful run into a failure whenever the log file happens to be absent:

```bash
cleanup() {
  log "Monitor stopped"
  [[ -f "$LOG_FILE" ]] && echo "Log saved: $LOG_FILE"   # returns 1 if no file
}
```

Capture the real status first and hand it back:

```bash
cleanup() {
  local rc=$?
  log "Monitor stopped"
  if [[ -f "$LOG_FILE" ]]; then echo "Log saved: $LOG_FILE"; fi
  return $rc
}
```

### Signal delivery has limits

There's a delay of up to one `sleep` interval before a handler runs — bash
finishes the current external command before servicing the trap.

And a background job started from a non-interactive shell inherits `SIGINT` as
*ignored*, per POSIX. Bash cannot trap a signal that was already `SIG_IGN` when
it started, so `kill -INT` on a backgrounded script does nothing. `SIGTERM` is
unaffected, which is why scripts should always handle `SIGTERM`, and why the
test suite below tests `SIGTERM` rather than `SIGINT`.

---

## 5. `monitor.sh`

```bash
./scripts/advanced/day8/monitor.sh [PID] [INTERVAL]
LOG_FILE=/tmp/my-run.log ./scripts/advanced/day8/monitor.sh 1234 2
```

Defaults to monitoring itself (`$$`) every 5 seconds, logging to
`/tmp/process-monitor.log`.

**Check the target exists before starting.** `kill -0` sends no signal — it only
tests whether the PID exists and is signalable:

```bash
if ! kill -0 "$TARGET_PID" 2>/dev/null; then
  echo "Error: PID $TARGET_PID not found or not accessible" >&2
  exit 1
fi
```

The same check drives the main loop, so the monitor exits by itself when the
target dies:

```bash
while kill -0 "$TARGET_PID" 2>/dev/null; do
  CPU=$(ps -p "$TARGET_PID" -o %cpu --no-headers | awk '{print $1}')
  ...
  sleep "$INTERVAL"
done
```

`LOG_FILE` is overridable, with the old hardcoded path as the default. That's
what lets the tests point it at a temp directory instead of every run sharing
one global file in `/tmp` — the same reason Day 6's modules take their paths
from the environment.

It also falls back to `/dev/null` if the path isn't writable. With
`set -euo pipefail`, a failing `tee` inside `log()` would otherwise kill the
monitor outright — losing the log is bad, stopping the monitor is worse.

---

## 6. Testing signal behaviour

```bash
bats scripts/advanced/day8/tests/
```

```
1..7
ok 1 the script is executable
ok 2 exits 1 with a clear error when the target PID does not exist
ok 3 monitors a live process and reports CPU and memory
ok 4 exits on its own once the target process terminates
ok 5 honours the LOG_FILE override instead of writing to /tmp/process-monitor.log
ok 6 the cleanup trap runs when the monitor is sent SIGTERM
ok 7 a successful run still exits 0 when the log path is unwritable
```

Two things worth copying when you test background processes.

**Redirect a background job's output.** BATS captures test output through a
pipe, and a background process inherits it and holds it open — so the test
blocks until that process exits on its own, however long that takes:

```bash
sleep 8 >/dev/null 2>&1 &      # without the redirect, the test waits the full 8s
```

**Capture an exit code without swallowing it.** `|| true` resets `$?` to 0
before you can read it:

```bash
wait "$mon" || true; rc=$?     # rc is always 0 — useless
local rc=0; wait "$mon" || rc=$?   # correct
```

Test 6 asserts `rc -eq 143` and that "Monitor stopped" appears exactly once.
Both matter: the exit code proves the handler actually terminated the script,
and the count proves cleanup didn't run twice.

---

## Recap

| Concept | One-liner |
|---|---|
| Background | `cmd &` then capture `$!` immediately; `wait` to rejoin |
| Liveness | `kill -0 "$pid"` tests existence without sending a signal |
| SIGTERM vs SIGKILL | Always try 15 first; 9 cannot be trapped, so no cleanup runs |
| Exit codes | 128 + signal number — 130 for SIGINT, 143 for SIGTERM |
| Trap EXIT | For cleanup; capture `$?` first or the trap overwrites your exit code |
| Trap signals | Must `exit`, or the script resumes where it was interrupted |
| Testability | Make `LOG_FILE` overridable, redirect background job output |

**Verify, from the repo root:**

```bash
shellcheck scripts/advanced/day8/monitor.sh
bats scripts/advanced/day8/tests/
```

Next up: **Day 9 — Environment Variables & Sourcing in Bash.**
