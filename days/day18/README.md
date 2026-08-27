# Day 18 — Zero-Trust Security Pipeline

Today's goal: wire yesterday's building blocks into a **fail-closed pipeline**.
Zero-trust means *never trust, always verify* — every stage is a gate, and the
first failure halts everything so bad code or tampered artifacts can never flow
downstream. You'll verify artifact integrity with checksums and guard a deploy
behind independently-checked preconditions.

---

## 📁 Scripts for today

| Script | Path | What it does | Try it |
|---|---|---|---|
| **Verify Artifact** | `days/day18/scripts/verify-artifact.sh` | SHA-256 manifest generation + verification | `bash days/day18/scripts/verify-artifact.sh manifest .` |
| **Zero-Trust Pipeline** | `days/day18/scripts/zero-trust-pipeline.sh` | Fail-closed gates: syntax → secrets → integrity | `bash days/day18/scripts/zero-trust-pipeline.sh .` |
| **Deploy Guard** | `days/day18/scripts/deploy-guard.sh` | Authorizes a deploy only when every check passes | see §4 |

---

## 1. The zero-trust principle

Traditional pipelines trust anything that got past the first step. Zero-trust
re-verifies at **every** boundary and denies by default:

- **Never trust input** — validate with allowlists (Day 17).
- **Verify artifacts** — check checksums before you deploy bytes.
- **Fail closed** — on any doubt, stop; don't "continue on error".
- **Least privilege** — each stage gets only what it needs.

## 2. Artifact integrity (checksums)

Build-time you record a manifest; before every downstream step you re-verify it.
A single changed byte fails the gate.

```bash
bash days/day18/scripts/verify-artifact.sh manifest ./build   # writes build/SHA256SUMS
bash days/day18/scripts/verify-artifact.sh verify   ./build   # exit 1 on any mismatch
```

## 3. The fail-closed pipeline

Stages run in order and **stop at the first failure**:

| # | Stage | Gate |
|---|---|---|
| 1 | `syntax` | every `*.sh` passes `bash -n` |
| 2 | `secrets` | Day 17's `secret-scanner.sh` finds nothing |
| 3 | `integrity` | `SHA256SUMS` verifies (skipped if absent) |

```bash
bash days/day18/scripts/zero-trust-pipeline.sh ./build
bash days/day18/scripts/zero-trust-pipeline.sh --list
```

Notice it **composes** yesterday's scanner rather than re-implementing it — one
tool, one responsibility.

## 4. The deploy guard

The last gate authorizes a deploy only when environment, target host, **and**
artifact integrity all check out. Every input is validated before use
(`lib/validator.sh`), and the host must be on an explicit allowlist.

```bash
DEPLOY_ENV=staging \
TARGET_HOST=web-01 \
ALLOWED_HOSTS=web-01,web-02 \
ARTIFACT_DIR=./build \
  bash days/day18/scripts/deploy-guard.sh          # -> "DEPLOY AUTHORIZED" (exit 0)
```

Drop any precondition (bad env, unknown host, tampered artifact) and it prints
the reason and exits 1 — **fail-closed**.

---

## ✅ Verify

```bash
bats days/day18/tests
bash days/day18/scripts/zero-trust-pipeline.sh --list
```

---

## Recap

| Concept | One-liner |
|---|---|
| Zero-trust | never trust, always verify, at every stage |
| Integrity | `sha256sum` manifest → verify before deploy |
| Fail-closed | first gate failure halts the pipeline |
| Compose | pipeline reuses the Day 17 scanner |
| Deploy guard | env + host allowlist + verified artifact |

Next up: **Day 19 — Performance & optimization.**
