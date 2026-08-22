# Day 6 — Modular Bash Libraries, Unit Testing with BATS, Pre-commit Hooks

Today's goal: stop copy-pasting the same logging / retry / locking code into
every script. Build small shared libraries once, source them everywhere, and
prove they work with automated tests that actually run — not "looks right."

---

## 📁 Scripts for today

All live in `scripts/modular/`.

| # | File | What it does | Try it |
|---|---|---|---|
| 1 | `lib/logging.sh` | Structured JSON logging — `log_info`/`log_warn`/`log_error`/`log_debug`, every line tagged with `$COMPONENT` | sourced, not run |
| 2 | `lib/retry.sh` | Retries a command with exponential backoff (5s → 10s → 20s) | sourced, not run |
| 3 | `lib/lock.sh` | `flock`-based mutex so two copies of a script can't run at once | sourced, not run |
| 4 | `lib/validator.sh` | Precondition checks — fails fast with a message naming the bad variable or path | sourced, not run |
| 5 | `modules/backup-manager.sh` | rsync snapshot backup, using all four libraries above | `SRC=/tmp/src BACKUP_DIR=/tmp/bk LOCK_FILE=/tmp/b.lock ./scripts/modular/modules/backup-manager.sh` |
| 6 | `modules/deploy.sh` | Release-directory deploy with an atomic `current` symlink swap | `RELEASE_SRC=/tmp/rel APP_DIR=/tmp/app LOCK_FILE=/tmp/d.lock ./scripts/modular/modules/deploy.sh` |
| 7 | `tests/*.bats` | 37 tests proving everything above actually works | `bats scripts/modular/tests/` |

> **The four `lib/` files are libraries, not scripts.** They only define
> functions, so running one directly does nothing visible — that's correct.
> They're meant to be `source`d, which is what the two modules do.

---

## 1. Layout

```
scripts/modular/
├── lib/
│   ├── logging.sh          # structured JSON logging
│   ├── retry.sh            # retry with exponential backoff
│   ├── lock.sh             # flock-based mutex, prevents overlapping runs
│   └── validator.sh        # precondition checks, fail fast with a clear message
├── modules/
│   ├── backup-manager.sh   # rsync snapshot backup
│   └── deploy.sh           # release-dir deploy with `current` symlink
└── tests/
    ├── test_helper.bash    # portable bats-support/bats-assert loader
    ├── backup-manager.bats
    ├── deploy.bats
    ├── validator.bats
    └── lock.bats
```

Four libraries, two modules, 37 tests.

The split matters: `lib/` holds functions and defines nothing that runs on its
own, `modules/` holds executable scripts that source those functions, and
`tests/` proves both. A file in `lib/` should be safe to `source` from anywhere
without side effects.

> **Note — two libraries share these filenames.** The repo root also has
> `lib/logging.sh`, `lib/retry.sh` and `lib/utils.sh`. That's **Day 10's**
> library, sourced by `day10/deploy.sh`, `day11/secure-deploy.sh`,
> `day16/container-builder.sh`, `projects/auto-deploy/deploy.sh` and
> `projects/log-analyzer-pro/main.sh`. It is not a duplicate to clean up, and
> the two are not interchangeable: root `lib/` emits plain text, routes
> `log_error` to stderr, and defaults `max_attempts` to 3, while
> `scripts/modular/lib/` emits JSON tagged with `$COMPONENT` and defaults to 5.
> This doc covers `scripts/modular/lib/` only.

---

## 2. The sourcing pattern

Every module starts the same way:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
shopt -s inherit_errexit 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/retry.sh"
source "$SCRIPT_DIR/../lib/lock.sh"
source "$SCRIPT_DIR/../lib/validator.sh"
```

Line by line:

- `set -e` exits on any unhandled failure, `-u` treats an unset variable as an
  error, and `-o pipefail` makes a pipeline fail if *any* stage fails, not just
  the last one.
- `IFS=$'\n\t'` drops space from the field separator, so unquoted expansion
  splits on newlines and tabs only — filenames with spaces stop breaking things.
- `inherit_errexit` propagates `set -e` into command substitutions. The
  `2>/dev/null || true` keeps it working on Bash 4.3 and older, where the option
  doesn't exist.
- `${BASH_SOURCE[0]}` is the path of *this file*, unlike `$0` which is whatever
  the caller invoked. That's what makes the relative `source` paths resolve no
  matter which directory you run from.

`SCRIPT_DIR` is assigned first and marked `readonly` on the next line. Combining
them into `readonly SCRIPT_DIR="$(...)"` hides the subshell's exit status from
`set -e`, because `readonly` returns success regardless. ShellCheck flags that
as SC2155.

---

## 3. `lib/retry.sh`

```bash
retry() {
  local max_attempts=${1:-5}
  local delay=${2:-2}
  local attempt=1
  shift 2

  while (( attempt <= max_attempts )); do
    "$@" && return 0
    log_error "Attempt $attempt failed. Retrying in ${delay}s..."
    sleep "$delay"
    ((attempt++))
    delay=$((delay * 2))
  done

  log_error "All $max_attempts attempts failed"
  return 1
}
```

Usage is `retry <max_attempts> <delay_seconds> <command> [args...]`:

```bash
retry 3 5 do_backup
retry 5 2 curl -fsS https://api.example.com/health
```

**The `shift 2` is the load-bearing line.** Reading `$1` and `$2` doesn't remove
them from the argument list — only `shift` does. Without it, `"$@"` still
expands to `3 5 do_backup` and Bash tries to run `3` as a command, so every
attempt fails identically and the function can never succeed. Any function that
reads leading arguments and then forwards the rest with `"$@"` needs the same
treatment.

`delay=$((delay * 2))` gives exponential backoff — `retry 3 5` waits 5s, then
10s, then 20s. Backing off matters when the thing you're retrying is rate
limited or still starting up; hammering it every second makes recovery slower.

`"$@" && return 0` succeeds on the *first* success and stops immediately.

---

## 4. `lib/logging.sh`

One JSON object per line, tagged with `$COMPONENT`:

```bash
log_info  "Starting backup"
log_warn  "Disk 80% full"
log_error "Backup failed"
log_debug "Payload: $body"     # only emitted when DEBUG=true
```

```json
{"timestamp":"2026-08-21T13:32:28Z","level":"INFO","component":"backup-manager","message":"Starting backup"}
```

Structured output means `jq 'select(.level=="ERROR")'` works, and a log shipper
can index the fields. Plain text forces everyone downstream to write a regex.

Two implementation details:

```bash
local timestamp
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

Split, not `local timestamp=$(...)` — same SC2155 reason as `SCRIPT_DIR`.

`LOG_FILE` defaults to `/var/log/bash-app.log` but is overridable, and if the
path isn't writable it falls back to `/dev/null` so the console output keeps
working instead of printing a `tee: Permission denied` beside every line. That
override is what lets the tests log into a temp dir without root.

---

## 5. `lib/validator.sh`

Check preconditions once at the top, instead of discovering them halfway
through the work:

```bash
require_var SRC BACKUP_DIR      # set and non-empty; reports ALL missing, not just the first
require_cmd rsync               # on PATH
require_dir "$SRC"              # exists AND is a directory
require_file "$CONF"            # exists AND is a regular file
require_writable "$BACKUP_DIR"  # writable — walks up to the nearest existing ancestor,
                                # so it validates paths you're about to create
require_int RETRIES             # non-negative integer
require_port TARGET_PORT        # 1-65535
require_safe_path "$SRC"        # rejects "", "/", and anything containing ".."
```

Each returns 1 and logs through `log_error`, so under `set -e` the script stops
on the offending line with a message naming the variable or path — rather than
failing three steps later inside `rsync` with something cryptic.

`require_var` collects every failure before returning. Aborting on the first
missing variable means the user fixes it, reruns, and hits the next one.

`require_safe_path` is a blast-radius guard. An empty or mistyped variable is
how `rm -rf "$DIR/"` becomes `rm -rf /`. Rejecting `""`, `/`, and `..` costs
three lines.

**Validate before you lock.** In both modules the checks run *before*
`acquire_lock`, so a misconfigured run doesn't take a lock it's about to
abandon, and doesn't make a legitimate concurrent run queue behind it.

---

## 6. `lib/lock.sh`

```bash
acquire_lock() {
  local lockfile="${LOCK_FILE:-/var/run/$(basename "$0").lock}"
  exec 200>"$lockfile"
  if ! flock -n 200; then
    log_error "Another instance is running (lock: $lockfile)"
    exit 1
  fi
  _LOCK_HELD=1
  echo $$ >&200
  trap release_lock EXIT INT TERM
}

release_lock() {
  [[ "${_LOCK_HELD:-0}" == 1 ]] || return 0
  flock -u 200 2>/dev/null || true
  _LOCK_HELD=0
}
```

`exec 200>"$lockfile"` opens the file on descriptor 200 for the life of the
process; `flock -n 200` takes an exclusive lock or fails immediately instead of
blocking. Locking through a descriptor is atomic in the kernel. Testing
`[[ -f lockfile ]]` and then creating it is not — two runs can both pass the
check before either writes.

Three rules this encodes:

**Register the trap after acquiring, never at source time.** A trap set while
`lock.sh` is being sourced also fires for failures that happen *before*
`acquire_lock` ran, releasing a lock the process never held.

**Guard `release_lock` with `_LOCK_HELD`.** It makes the function safe to call
unconditionally, which is what a trap does.

**Don't delete the lock file on release.** Removing it lets a waiting process
open a fresh inode while another still holds the old one, and both then believe
they own the lock. `flock`'s state lives in the kernel, not in the file's
existence — a stale zero-byte file is harmless.

`trap ... EXIT INT TERM` covers normal exit, Ctrl-C, and `kill`.

---

## 7. The modules

Both read their paths from the environment, with sensible defaults:

```bash
# backup-manager.sh
BACKUP_DIR="${BACKUP_DIR:-/backup/data}"
SRC="${SRC:-/var/www}"

# deploy.sh
RELEASE_SRC="${RELEASE_SRC:-/tmp/new-release}"
APP_DIR="${APP_DIR:-/var/www/myapp}"
```

**Configurable paths are what make a script testable.** A script that hardcodes
`/var/www` can only ever be tested against `/var/www`. With the override, the
suite points it at a temp dir and asserts on real results.

```bash
SRC=/tmp/src BACKUP_DIR=/tmp/backup LOCK_FILE=/tmp/b.lock \
  ./scripts/modular/modules/backup-manager.sh
```

`deploy.sh` writes each release into its own timestamped directory and then
repoints a `current` symlink:

```bash
do_deploy() {
  local release_dir
  release_dir="$APP_DIR/releases/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$release_dir"
  cp -r "$RELEASE_SRC/." "$release_dir/"
  ln -sfn "$release_dir" "$APP_DIR/current"
}
```

`ln -sfn` is atomic, so there's no moment where `current` points at nothing —
that's the zero-downtime part. Old releases stay on disk, so rolling back is
just repointing the symlink.

Note `cp -r "$RELEASE_SRC/."` — the trailing `/.` copies the directory's
*contents* including dotfiles. The obvious-looking `cp -r "$RELEASE_SRC"/*`
silently skips `.env` and anything else beginning with a dot, because the glob
never matches them.

Both modules define the real work as a function and hand it to `retry`, so a
transient failure gets three attempts with backoff instead of aborting the run.

---

## 8. Testing with BATS

Install:

```bash
# Debian / Ubuntu
sudo apt install bats bats-support bats-assert
# macOS
brew install bats-core bats-support bats-assert
```

Run from anywhere in the repo:

```bash
bats scripts/modular/tests/
```

A test runs the real script and asserts on what actually happened:

```bash
@test "deploy includes hidden files, not just visible ones" {
  run "$MODULES_DIR/deploy.sh"
  assert_success
  [ -f "$APP_DIR/current/.env" ]
}
```

`run` executes the command and captures its exit status into `$status` and its
output into `$output`, without letting a non-zero exit abort the test. Then
`assert_success`, `assert_output --partial`, or a plain `[ ... ]` check the
result.

### Two things the tests do on purpose

**Portable helper loading.** `bats-support` sits at `/usr/lib/bats/bats-support`
on Debian, `/usr/lib/bats-support` elsewhere, `/opt/homebrew/lib` on macOS.
Hardcoding one path makes the suite pass on exactly one machine, so
`test_helper.bash` searches the known locations and fails with a clear message
if it finds none.

**No dependence on the current directory.** BATS does not `cd` into the test
file's directory, so `run ../modules/deploy.sh` only works if you happen to be
standing in `tests/`. Derive paths from `$BATS_TEST_DIRNAME`:

```bash
MODULAR_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export MODULES_DIR="$MODULAR_DIR/modules"
export LIB_DIR="$MODULAR_DIR/lib"
```

Each test also gets `$BATS_TEST_TMPDIR`, a fresh directory created and removed
per test. Use it for fixtures instead of fixed `/tmp` paths — no `teardown()`
that `rm -rf`s a hardcoded location, and tests can't leak state into each other.

### Mocking an external command

Prepend a temp dir to `PATH` and drop a stub in it. That's how the security
tests drive every branch without installing the real tool:

```bash
stub_gitleaks() {
  cat > "$FAKEBIN/gitleaks" <<EOF
#!/usr/bin/env bash
exit $1
EOF
  chmod +x "$FAKEBIN/gitleaks"
}

run env PATH="$FAKEBIN:/usr/bin:/bin" "$SEC_BIN/secret-rotator.sh" "$SCAN"
```

---

## 9. Static analysis

```bash
shellcheck -x -P scripts/modular/lib:scripts/modular/modules \
  scripts/modular/lib/*.sh scripts/modular/modules/*.sh
```

Exits 0 with no output when everything is clean.

`-x` follows `source` directives so ShellCheck can see functions defined in
another file. `-P` gives it a search path to resolve those paths — without it
you get eight SC1091 "not following" notices, because ShellCheck can't evaluate
`$SCRIPT_DIR` statically.

Both flags run from the repo root; from elsewhere the relative paths miss.

Worth knowing about SC2034 ("appears unused"): it fires on `COMPONENT`, which
*is* used — by the `log_*` functions in the sourced library. ShellCheck can't
see across `source` boundaries for variable reads, so that one is annotated
rather than silenced globally.

---

## 10. Pre-commit

`.pre-commit-config.yaml` at the repo root defines 12 hooks. The
security-focused ones are Day 7's subject.

```bash
pip3 install --user pre-commit
pre-commit install
pre-commit run --all-files    # check everything without committing
```

### Two kinds of hook, and why it matters

**Upstream hooks** come from a repo that publishes a `.pre-commit-hooks.yaml`
declaring what it provides — `gitleaks`, `semgrep`, `shfmt`, and the five
`pre-commit-hooks` utilities. If a repo has no such file, pre-commit fails with
`InvalidManifestError: .pre-commit-hooks.yaml is not a file`, and no `rev` will
fix it: that project simply isn't distributed as a pre-commit hook.

That trips people up with Trivy, Syft and Grype. They're real, widely used
tools — but they ship as standalone binaries, not as pre-commit repos. Before
adding a hook, check the repo actually publishes a manifest:

```bash
curl -sI https://raw.githubusercontent.com/OWNER/REPO/REV/.pre-commit-hooks.yaml | head -1
```

Also note `shfmt`: the binary lives at `mvdan/sh`, but the *hook* is at
`scop/pre-commit-shfmt`. Pointing at the binary's repo gives the same error.

**Local hooks** (`repo: local`) run a command already on your machine. That's
how `shellcheck`, `trivy-fs`, `syft-sbom` and `grype-scan` are wired here. The
three scanners guard on the binary first:

```yaml
- id: trivy-fs
  entry: >-
    bash -c 'command -v trivy >/dev/null ||
    { echo "SKIP - trivy not installed"; exit 0; };
    trivy fs --quiet --exit-code 1 --no-progress --severity HIGH,CRITICAL .'
  language: system
  pass_filenames: false
```

The skip is deliberate and it prints a visible notice. A security hook that
silently passes because its scanner was never installed is worse than no hook —
you get a green tick that means nothing.

### One YAML gotcha

Every value in `args` must be a **string**. A bare number parses as an integer
and pre-commit rejects the config with `Expected string got int`:

```yaml
args: [-w, -i, 2, -ci]      # fails
args: [-w, -i, "2", -ci]    # works
```

Same for `--exit-code 1`, `--maxkb 500`, and anything else numeric.

And if an `entry:` contains a colon, quote it or use a `>-` block scalar —
otherwise YAML reads the colon as a key separator.

Validate without running anything:

```bash
pre-commit validate-config .pre-commit-config.yaml
```

Pre-commit is fast feedback, not enforcement — `git commit --no-verify` skips
it, and hooks aren't shared automatically on clone. The real gate is
`.github/workflows/security-scan.yml`, which runs server-side where nobody can
bypass it.

---

## 11. Code coverage

`kcov` is the usual tool for Bash line coverage:

```bash
kcov ./coverage bats scripts/modular/tests/
```

It wasn't installable in the environment this was written in, so treat it as a
pointer rather than a verified instruction, and no coverage figure is quoted
here. What is claimed is 37 named tests that pass, reproducible with the one
command in section 8.

---

## Recap

| Concept | One-liner |
|---|---|
| Sourcing | `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, assigned before `readonly` |
| Logging | JSON lines, `$COMPONENT`-tagged, `LOG_FILE` overridable |
| Retry | `retry <attempts> <delay> <cmd>` — `shift 2` is what forwards the command |
| Validation | Check preconditions up front, before locking or doing work |
| Locking | `flock` on a descriptor; register the release trap *after* acquiring |
| Testability | Env-overridable paths are the prerequisite, not a nicety |
| Testing | `$BATS_TEST_DIRNAME` for paths, `$BATS_TEST_TMPDIR` for fixtures |
| Lint | `shellcheck -x -P`, and fix SC2155 rather than suppress it |

**Verify the whole day, from the repo root:**

```bash
shellcheck -x -P scripts/modular/lib:scripts/modular/modules \
  scripts/modular/lib/*.sh scripts/modular/modules/*.sh
bats scripts/modular/tests/
```

Next up: **Day 7 — Zero-Trust Security Pipeline: Secret Scanning, Rotation, Pre-commit Gates.**
