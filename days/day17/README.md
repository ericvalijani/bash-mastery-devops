# Day 17 — Security Fundamentals

Today's goal: write Bash that is safe to run on untrusted input and safe to
leave on disk. You'll validate with **allowlists**, avoid the classic injection
traps (`eval`, unquoted variables, predictable temp files), lock down file
permissions, and build a **dependency-free secret scanner** you can drop into CI.

---

## 📁 Scripts for today

| Script | Path | What it does | Try it |
|---|---|---|---|
| **Security Demo** | `days/day17/scripts/security-demo.sh` | Walks through validation, quoting, safe dispatch, and secure temp files | `bash days/day17/scripts/security-demo.sh` |
| **Secret Scanner** | `days/day17/scripts/secret-scanner.sh` | Scans a tree for hardcoded credentials; exits 1 on any hit | `bash days/day17/scripts/secret-scanner.sh .` |
| **Harden Permissions** | `days/day17/scripts/harden-permissions.sh` | Writes secrets `0600` and audits a tree for weak modes | `bash days/day17/scripts/harden-permissions.sh audit .` |

---

## 1. Validate with allowlists, not blocklists

Deny by default. Enumerate what's *allowed* and reject everything else — you can
never list every bad value, but you can list the good ones.

```bash
case "$env" in
  dev | staging | prod) : ;;          # ok
  *) echo "rejected: $env" >&2; exit 1 ;;
esac
```

Reuse `lib/validator.sh` for the common cases: `require_int`, `require_safe_path`
(rejects empty, `/`, and `..` traversal), `require_file`, `require_cmd`.

## 2. Never `eval` untrusted input

`eval "$user_input"` turns data into code. Dispatch by name through a `case`
instead, so input can only ever select a predefined action:

```bash
case "$action" in
  status)  show_status ;;
  version) show_version ;;
  *) echo "unknown action" >&2; exit 1 ;;
esac
```

## 3. Quote everything

An unquoted variable is word-split on `IFS` **and** glob-expanded. `rm $file`
with `file='* '` deletes your directory. Always `"$file"`, `"$@"`, `"${arr[@]}"`.
Tightening `IFS=$'\n\t'` removes space as a splitter for extra safety.

## 4. Secure temp files

Never hardcode `/tmp/mytool.$$` — it's predictable and enables symlink attacks.
Use `mktemp`, set a restrictive `umask`, and clean up with a trap:

```bash
tmp="$(mktemp "${TMPDIR:-/tmp}/tool.XXXXXXXX")"
trap 'rm -f "$tmp"' EXIT
umask 077
```

## 5. Least-privilege file permissions

Secrets should be **owner-only**. `umask 077` makes new files `0600`; set it
explicitly with `chmod 600`. `harden-permissions.sh audit` flags world-writable
paths and secret files (`*.pem`, `*.key`, `.env`) readable by group/other.

```bash
bash days/day17/scripts/harden-permissions.sh write ./secret.txt "s3cr3t"
bash days/day17/scripts/harden-permissions.sh audit .
```

## 6. Catch secrets before they land

`secret-scanner.sh` greps for AWS keys, GitHub/Slack tokens, private-key
headers, and generic `key=...` assignments, skipping `.git` and `*.example`
templates. Exit 1 on any hit makes it CI/pre-commit ready:

```bash
bash days/day17/scripts/secret-scanner.sh .
```

---

## ✅ Verify

```bash
bats days/day17/tests
bash days/day17/scripts/security-demo.sh
```

---

## Recap

| Concept | One-liner |
|---|---|
| Allowlist | `case "$x" in good) ;; *) reject ;; esac` |
| No eval | dispatch by name through `case` |
| Quote | `"$var"`, `"$@"`, `"${arr[@]}"` always |
| Temp files | `mktemp` + `trap rm EXIT` + `umask 077` |
| Permissions | secrets `0600`; audit for world-writable |
| Secret scan | `secret-scanner.sh` → exit 1 on any hit |

Next up: **Day 18 — Zero-trust security pipeline.**
