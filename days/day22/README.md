# Day 22 — Rootless Containers

Phase 5 goes container-native. The goal today: run workloads **without root**,
drop every capability by default, and catch privilege anti-patterns *before*
they ship. Everything here is runtime-optional — the scripts detect podman/docker
and fall back to dry-run/static analysis, so they work (and test) even with no
engine installed.

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **Container lib** | `days/day22/scripts/container-lib.sh` | Sourced helpers: runtime detection, rootless check, tag pinning |
| **Run rootless** | `days/day22/scripts/run-rootless.sh` | Launch with hardened defaults (`--dry-run` prints the command) |
| **Containerfile audit** | `days/day22/scripts/containerfile-audit.sh` | Static linter for rootless/security anti-patterns |

---

## 1. Why rootless?

A container that runs as root *is* root on the host if it escapes. Rootless
flips the default: the process maps to an unprivileged host user via **user
namespaces**, so a breakout lands as nobody. Podman is rootless by design;
Docker needs rootless mode.

## 2. Secure-by-default launch

`run-rootless.sh` never trusts defaults — it *enforces* them:

```bash
bash days/day22/scripts/run-rootless.sh --dry-run nginx:1.25
# podman run --rm --read-only --cap-drop=ALL --security-opt=no-new-privileges \
#   --pids-limit=256 --memory=256m --network=none --user 1000 nginx:1.25
```

| Flag | Why |
|---|---|
| `--read-only` | immutable rootfs; writes go to explicit tmpfs/volumes |
| `--cap-drop=ALL` | start from zero Linux capabilities |
| `--security-opt=no-new-privileges` | block setuid escalation |
| `--user <uid>` (never 0) | non-root process; refuses uid 0 |
| `--network=none` (default) | deny network unless you opt in |
| `--pids-limit` / `--memory` | contain fork bombs and OOM blast radius |

Images **must be pinned** to an explicit tag — `:latest` earns a warning, no tag
is a hard error.

## 3. Catch it in review, not prod

`containerfile-audit.sh` statically flags the classics:

```bash
bash days/day22/scripts/containerfile-audit.sh Containerfile
```

| Finding | Severity |
|---|---|
| No non-root `USER` (or `USER root`) | VIOLATION |
| `FROM` without a tag / `:latest` | VIOLATION |
| Secret baked into an `ENV` layer | VIOLATION |
| `ADD https://...` remote fetch | WARN |
| `sudo` inside the image | WARN |

Exit code is non-zero if any VIOLATION is found — wire it straight into CI.

---

## ✅ Verify

```bash
bats days/day22/tests
bash days/day22/scripts/run-rootless.sh --dry-run alpine:3.19 -- sh -c 'echo hi'
```

---

## Recap

| Concept | One-liner |
|---|---|
| Rootless | breakout lands as an unprivileged host user |
| Drop caps | `--cap-drop=ALL`, add back only what's needed |
| No new privs | `--security-opt=no-new-privileges` |
| Pin tags | reproducible builds, no `:latest` |
| Shift left | audit the Containerfile in CI |

Next up: **Day 23 — CI/CD framework.**
