# Day 24 — GitOps

GitOps flips deployment on its head: instead of *pushing* changes, you declare
the **desired state** in git and a **reconciler** continuously makes the live
world match it. Today you build that loop — reconcile + drift detection — as a
content-addressed, idempotent sync.

**Model:** `DESIRED/` (your git source of truth) → reconcile → `LIVE/` (reality).
Everything compares by SHA-256, so it's order-independent and safe to re-run.

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **GitOps lib** | `days/day24/scripts/gitops-lib.sh` | `list_files`, `file_hash`, `diff_state` |
| **Reconcile** | `days/day24/scripts/reconcile.sh` | Converge LIVE to DESIRED (idempotent) |
| **Drift detect** | `days/day24/scripts/drift-detect.sh` | Read-only guardrail; non-zero on drift |

---

## 1. Declare, then reconcile

```bash
# desired/ holds what SHOULD be live (rendered manifests, configs, ...)
bash days/day24/scripts/reconcile.sh desired/ live/
```

```
CREATE  app/deployment.yaml
CREATE  app/service.yaml
----------------------------
applied: 2 created, 0 updated, 0 pruned
```

Actions the reconciler takes:

| Action | When |
|---|---|
| **CREATE** | file declared in DESIRED, missing from LIVE |
| **UPDATE** | file exists in both but content drifted |
| **PRUNE** | file in LIVE not declared in DESIRED (only with `--prune`) |
| **IGNORE** | extra LIVE file, `--prune` not set |

## 2. Idempotency is the whole point

Run it again with no upstream change and nothing happens:

```
----------------------------
already in sync
```

Because state is compared by content hash — not timestamps — reconciling is safe
to run every minute, forever.

## 3. Plan before you apply

```bash
bash days/day24/scripts/reconcile.sh --dry-run --prune desired/ live/
# reports CREATE/UPDATE/PRUNE lines, then: "planned: ..." — touches nothing
```

## 4. Catch out-of-band changes

`drift-detect.sh` is read-only and exits non-zero when reality has diverged —
perfect for a cron alert or a CI gate:

```bash
bash days/day24/scripts/drift-detect.sh desired/ live/ || notify "drift!"
```

```
CHANGED	app/service.yaml
EXTRA	app/rogue.yaml
----------------------------
drift detected: 2 file(s) diverged
```

---

## ✅ Verify

```bash
bats days/day24/tests
```

---

## Recap

| Concept | One-liner |
|---|---|
| Desired state | git is the source of truth |
| Reconcile | make LIVE match DESIRED |
| Idempotent | content hashes, safe to re-run |
| Prune | remove undeclared drift |
| Drift detect | read-only guardrail, non-zero on divergence |

Next up: **Day 25 — kubectl automation.**
