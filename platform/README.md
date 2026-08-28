# platform/ — real-deployment shared foundation

This repo teaches every deploy-relevant concept **twice**:

- **Option 1 — Offline simulation (default).** Pure Bash, no external tools,
  fully BATS-tested. This is what CI runs and what every day ships by default.
- **Option 2 — Real deployment (opt-in).** The same concept run against the
  real tool it imitates (gitleaks, trivy, cosign, podman, kubectl, kind,
  ArgoCD, …). Requires those tools installed locally; it never runs in CI.

`platform/` holds the shared pieces the Option-2 scripts reuse, so each day
doesn't reinvent them.

## Contents

| Path | Purpose |
|---|---|
| `lib/realmode.sh` | Shared helpers for every Option-2 script: tool-presence checks with install hints (`rm_require_tools`), a consistent REAL-MODE banner (`rm_banner`), and a confirm guard (`rm_confirm`). |

More shared infrastructure lands here as later days gain their real option —
for example a single `kind` cluster bootstrap reused by the Kubernetes days
(25–30).

## The contract every real script follows

1. The offline script stays the untouched, tested default.
2. The real script is added alongside it as `real-*.sh` and sources
   `platform/lib/realmode.sh`.
3. If the required tools aren't installed, it prints exactly what's missing and
   exits **without pretending to have run** (exit code 3).
4. The day's README gains an **Option 2** section documenting the prerequisites.
5. BATS tests for the real path `skip` when the tools are absent, so
   `bats -r days` stays green everywhere.
