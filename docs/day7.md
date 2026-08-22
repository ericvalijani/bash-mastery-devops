# Day 7 — Zero-Trust Security Pipeline: Secret Scanning, Rotation, and Pre-commit Gates

Goal: catch secrets and vulnerabilities *before* they reach a remote branch, and
make the response to a leak automatic rather than a fire drill.

---

## 📁 Scripts for today

All live in `scripts/security/`.

| # | File | What it does | Try it |
|---|---|---|---|
| 1 | `bin/secret-rotator.sh` | Scans a tree for leaked secrets with `gitleaks`; on a finding it can rotate the compromised AWS key and post a Slack alert. Report-only by default | `./scripts/security/bin/secret-rotator.sh .` |
| 2 | `lib/logging.sh` | Re-exports Day 6's JSON logger, so Day 7 doesn't ship a third copy of `log_info` | sourced, not run |
| 3 | `tests/secret-rotator.bats` | 8 tests covering every exit path, with `gitleaks` and `aws` stubbed onto `PATH` | `bats scripts/security/tests/` |

> **⚠️ Script #1 is safe to run as-is** — `DRY_RUN` defaults to `true`, so it
> reports findings and changes nothing. Rotation only happens with an explicit
> `DRY_RUN=false` *and* an `IAM_USER`. It needs `gitleaks` installed; without it
> the script exits `2` rather than pretending the scan was clean.

---

## 1. Layout

```
scripts/security/
├── lib/
│   └── logging.sh            # re-exports Day 6's JSON logger
├── bin/
│   └── secret-rotator.sh     # gitleaks scan -> rotate -> alert
└── tests/
    └── secret-rotator.bats   # 8 tests
```

Plus `.pre-commit-config.yaml` and `.github/workflows/security-scan.yml` at the
repo root.

**Day 7 builds on Day 6.** `scripts/security/lib/logging.sh` re-exports
`scripts/modular/lib/logging.sh`, `secret-rotator.sh` sources
`scripts/modular/lib/retry.sh`, and the test file loads
`scripts/modular/tests/test_helper.bash`. Rather than ship a third divergent
copy of `log_info`/`log_error`, this reuses the one Day 6 already built — which
is the entire point of a shared library. Day 6 must be in place for Day 7 to run.

---

## 2. The tool stack

| Tool | Purpose |
|------|---------|
| `gitleaks` | Detect hardcoded secrets (API keys, tokens, private keys) |
| `trivy` | Vulnerability + IaC misconfiguration scanning |
| `semgrep` | SAST across Bash, YAML, Dockerfiles, Terraform |
| `syft` + `grype` | Generate an SBOM, then scan it for known CVEs |
| `pre-commit` | Runs the above on every commit |

---

## 3. `secret-rotator.sh`

```bash
./secret-rotator.sh [path]
```

Scan a tree for leaked secrets; on a finding, optionally rotate the compromised
key and alert.

### Exit codes are the design

| Code | Meaning |
|------|---------|
| `0` | Clean |
| `1` | Secrets found |
| `2` | Could not run — missing tool or missing config. **Fail the build.** |

Separating `2` from `0` is the single most important decision in the script. A
scanner that isn't installed must never look like a clean scan:

```bash
command -v gitleaks >/dev/null || { log_error "gitleaks is not installed"; exit 2; }
```

A security gate that silently passes because its tool is absent is worse than no
gate — it produces a green tick that means nothing.

### Guarding the scanner call

`gitleaks` exits 1 when it *finds* something. Under `set -e` that would abort the
script before the response logic runs, so the call is guarded and the exit code
inspected deliberately:

```bash
scan_rc=0
gitleaks detect --no-git --source "$SCAN_PATH" \
  --report-format json --report-path "$REPORT" --redact --exit-code 1 || scan_rc=$?

case $scan_rc in
  0) log_info "No secrets found"; exit 0 ;;
  1) : ;;                                      # findings — handle below
  *) log_error "gitleaks failed (exit $scan_rc)"; exit 2 ;;
esac
```

The `|| scan_rc=$?` idiom is how you run a command that's *expected* to fail
sometimes without `set -e` killing the script. Note the `*)` branch: anything
other than 0 or 1 means gitleaks itself broke, which is a `2`, not a clean run.

`--redact` keeps the secret value out of the JSON report and CI logs. Writing
the plaintext secret into a build artifact during leak response is a common
self-inflicted second leak.

### Safe by default

```bash
./secret-rotator.sh                                    # scan + report only
DRY_RUN=false IAM_USER=svc-deploy ./secret-rotator.sh  # scan + rotate + alert
```

`DRY_RUN` defaults to `true`. With `DRY_RUN=false` the script still refuses to
act unless `IAM_USER` is set explicitly — guessing which credential to
invalidate is not a guess worth making.

Every optional variable is read as `${SLACK_WEBHOOK:-}`. Under `set -u` a bare
`$SLACK_WEBHOOK` aborts the script the moment the webhook isn't exported, which
is precisely when an alert matters most.

### Rotation order

```bash
rotate_key() {
  local new_key old_keys
  new_key=$(aws iam create-access-key --user-name "$IAM_USER" \
            --query 'AccessKey.AccessKeyId' --output text)
  old_keys=$(aws iam list-access-keys --user-name "$IAM_USER" \
             --query "AccessKeyMetadata[?AccessKeyId!='$new_key'].AccessKeyId" \
             --output text)
  for k in $old_keys; do
    aws iam update-access-key --user-name "$IAM_USER" --access-key-id "$k" --status Inactive
  done
}
```

**Create the replacement first, deactivate the old ones second.** Reverse it and
you lock yourself out in the gap between the two API calls.

Old keys are set to `Inactive`, not deleted. That preserves the audit trail and
lets you reactivate if the rotation broke a consumer you forgot about.

The whole function runs through Day 6's `retry 3 5 rotate_key`, because IAM is
eventually consistent and rate-limited.

---

## 4. Pre-commit

`.pre-commit-config.yaml` at the repo root defines **12 hooks**: `gitleaks`,
`semgrep`, `shfmt`, `check-added-large-files`, `detect-private-key`,
`trailing-whitespace`, `end-of-file-fixer`, `check-merge-conflict`,
`shellcheck`, `trivy-fs`, `syft-sbom`, `grype-scan`.

```bash
pip3 install --user pre-commit
pre-commit install
pre-commit run --all-files    # whole repo; rarely needed
```

After `pre-commit install`, a plain `git commit` runs the hooks on **staged
files only**. `--all-files` is for initial cleanup and CI, not routine use.

### Not every tool ships as a pre-commit hook

A hook repo must publish a `.pre-commit-hooks.yaml`. Without one you get
`InvalidManifestError: .pre-commit-hooks.yaml is not a file`, and no `rev` will
fix it. Trivy, Syft and Grype are all in that category — real tools, distributed
as binaries only. Check before adding:

```bash
curl -sI https://raw.githubusercontent.com/OWNER/REPO/REV/.pre-commit-hooks.yaml | head -1
```

They run here as `repo: local` hooks that check for the binary and skip loudly
if it's absent:

```yaml
- id: trivy-fs
  entry: >-
    bash -c 'command -v trivy >/dev/null ||
    { echo "SKIP - trivy not installed"; exit 0; };
    trivy fs --quiet --exit-code 1 --no-progress --severity HIGH,CRITICAL .'
  language: system
  pass_filenames: false
```

Same principle as exit code `2` above: skipping is fine, skipping *silently* is
not.

### Two config gotchas

Every value in `args` must be a **string**. A bare number parses as an integer
and pre-commit rejects the config with `Expected string got int`:

```yaml
args: [-w, -i, 2, -ci]      # fails
args: [-w, -i, "2", -ci]    # works
```

And ruleset names are validated remotely — `--config=p/bash` makes semgrep exit
`7` because no such ruleset exists. `p/ci` and `p/secrets` are real. Verify with
`curl -sI https://semgrep.dev/c/p/NAME`.

```bash
pre-commit validate-config .pre-commit-config.yaml
```

### Pre-commit is feedback, not enforcement

`git commit --no-verify` bypasses it, and hooks aren't installed automatically
on clone. The real gate is `.github/workflows/security-scan.yml`, which runs
server-side where nobody can skip it. Local hooks exist to be fast; CI exists to
say no.

---

## 5. Testing security tooling

Security scripts are awkward to test — you don't want to hit real AWS, and you
can't assume gitleaks is installed. The technique: prepend a temp dir to `PATH`
and drop a stub binary in it.

```bash
stub_gitleaks() {
  cat > "$FAKEBIN/gitleaks" <<EOF
#!/usr/bin/env bash
exit $1
EOF
  chmod +x "$FAKEBIN/gitleaks"
}

@test "exits 2 with a clear error when gitleaks is missing" {
  run env PATH="$FAKEBIN:/usr/bin:/bin" "$SEC_BIN/secret-rotator.sh" "$SCAN"
  [ "$status" -eq 2 ]
  assert_output --partial "gitleaks is not installed"
}
```

That drives every branch — clean scan, dirty scan, missing tool, missing
credentials, missing webhook — deterministically, offline, in about a second.
The `aws` CLI is stubbed the same way to test rotation without an AWS account.

```bash
bats scripts/security/tests/
```

```
1..8
ok 1 the script is executable
ok 2 the script parses and its libraries resolve
ok 3 exits 2 with a clear error when gitleaks is missing
ok 4 exits 0 and reports clean when no secrets are found
ok 5 exits 1 and reports the finding when a secret is detected
ok 6 defaults to DRY_RUN and takes no destructive action
ok 7 refuses to rotate when IAM_USER is unset
ok 8 survives an unset SLACK_WEBHOOK instead of crashing on set -u
```

Tests 1 and 2 look trivial — one checks the executable bit, the other that the
file parses and its libraries resolve. Keep tests like these. They're cheap, and
they isolate the two failures that otherwise disguise themselves as something
else: a missing `+x` bit makes every later test fail with `Permission denied`,
and a wrong `source` path kills the script on line 6 before any of your
interesting logic runs. Both look like six broken features until you check.

If test 1 fails after copying files around, that's all it is:

```bash
chmod +x scripts/security/bin/secret-rotator.sh
```

---

## 6. Two things to know about this repo

- **`.env` and `temp-remove-secret.txt` are committed at the repo root.** `.env`
  is listed in `.gitignore`, but ignore rules don't apply to files git already
  tracks. `git rm --cached .env` stops the tracking while keeping your local
  copy.
- **A second, unrelated `secret-rotator.sh`** lives at
  `microservice/secret/scripts/secret-rotator.sh` — same name, different job
  (scheduled rotation, not leak response). It belongs to the microservices work,
  not Day 7. Same "two files, one name" situation as the `lib/` note in Day 6.

---

## Recap

| Concept | One-liner |
|---|---|
| Exit codes | `0` clean / `1` found / `2` couldn't run — never conflate the last two |
| Guarding scanners | `tool ... \|\| rc=$?` so an expected non-zero doesn't trip `set -e` |
| Safe defaults | `DRY_RUN=true`; refuse to act on an unset `IAM_USER` |
| Rotation order | New key first, *then* deactivate old. Deactivate, don't delete |
| Redaction | `--redact` so leak response doesn't create a second leak |
| Unset vars | `${SLACK_WEBHOOK:-}` under `set -u`, always |
| Testing | Stub external binaries onto `PATH` in `$BATS_TEST_TMPDIR` |
| Enforcement | Pre-commit is feedback; CI is the control |

> **ShellCheck 0.11+** adds SC2329 ("function is never invoked"), which fires on
> `rotate_key` because `retry 3 5 rotate_key` invokes it indirectly through
> `"$@"`. That's a false positive, annotated in the script alongside SC2317.
> ShellCheck can't follow indirect invocation.

**Verify, from the repo root:**

```bash
shellcheck -x -P scripts/security/bin:scripts/security/lib \
  scripts/security/bin/*.sh scripts/security/lib/*.sh
bats scripts/security/tests/
```

Next up: **Day 8 — Process Management, Signals, and Job Control.**
