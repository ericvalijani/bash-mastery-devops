# Day 25 — kubectl Automation

`kubectl` is a loaded gun: one wrong `--context` and you've applied a change to
production. Today you build **safe wrappers** that make the dangerous defaults
safe — explicit targeting, dry-run first, and hard stops on protected clusters.

The client binary is resolved via `$KUBECTL` (default `kubectl`), so these
scripts are testable with a stub and work with `oc`, pinned versions, etc.

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **kubectl lib** | `days/day25/scripts/kubectl-lib.sh` | `current_context`, `is_protected_context`, `is_valid_namespace` |
| **Safe apply** | `days/day25/scripts/k-apply.sh` | `kubectl apply` with rails: dry-run default, prod guard |
| **Context guard** | `days/day25/scripts/context-guard.sh` | Assert the current cluster before risky ops |

---

## 1. Never trust the current context

The #1 kubectl footgun is running against whatever cluster happens to be
selected. `k-apply.sh` **requires** explicit targeting — no `--context`/
`--namespace`, no run:

```bash
bash days/day25/scripts/k-apply.sh --context staging --namespace web app.yaml
# kubectl --context staging --namespace web apply -f app.yaml --dry-run=server
```

## 2. Dry-run by default

Without `--apply`, nothing changes — it's a server-side dry-run. You opt *in* to
real mutations:

```bash
# preview (safe)
bash days/day25/scripts/k-apply.sh --context staging --namespace web app.yaml
# actually apply
bash days/day25/scripts/k-apply.sh --context staging --namespace web --apply app.yaml
```

## 3. Protected clusters need a password, basically

Contexts matching `$PROTECTED_CONTEXTS` (default `prod,production`) are refused
unless you add `--confirm`:

```bash
bash days/day25/scripts/k-apply.sh --context prod-eu --namespace web --apply app.yaml
# ERROR: refusing to target protected context 'prod-eu' without --confirm
bash days/day25/scripts/k-apply.sh --context prod-eu --namespace web --apply --confirm app.yaml
```

## 4. Guard risky automation

Gate any destructive script behind the current-context check:

```bash
context-guard.sh staging-cluster && ./rollout-restart.sh
```

```
context MISMATCH: current='prod-cluster' expected='staging-cluster'   # exit 1
```

---

## ✅ Verify

```bash
bats days/day25/tests
```

> The tests inject a **stub `kubectl`** via `$KUBECTL`, so they exercise every
> guard with no real cluster.

---

## Recap

| Concept | One-liner |
|---|---|
| Explicit targeting | `--context` + `--namespace` required |
| Safe default | server-side dry-run unless `--apply` |
| Prod guard | protected contexts need `--confirm` |
| Context guard | verify the cluster before acting |
| Swappable client | `$KUBECTL` for stubs/versions |

Next up: **Day 26 — Kubernetes Operators & CRDs.**
