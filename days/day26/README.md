# Day 26 — Kubernetes Operators & CRDs

An **operator** is just Day 24's reconcile loop pointed at a *custom resource*.
You declare a `spec` (desired), the controller observes reality, converges the
two, and writes back a `status`. It runs continuously and is **level-triggered**
— it always drives toward the current spec, no matter how it got out of sync.

Today you build a mini-operator for a `WidgetSet` CRD (think: a Deployment).
No real cluster needed — "pods" are files, so every reconcile is inspectable.

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **Operator lib** | `days/day26/scripts/operator-lib.sh` | `cr_get`, `is_uint`, `count_pods` |
| **Reconcile** | `days/day26/scripts/reconcile-cr.sh` | One reconcile pass for a single CR |
| **Control loop** | `days/day26/scripts/operator.sh` | Watch a dir of CRs; `--once` or `--interval` |

---

## 1. The custom resource

A CR is a declarative spec. Our `WidgetSet` has `replicas` and `image`:

```ini
kind = WidgetSet
name = frontend
replicas = 3
image = nginx:1.25
```

## 2. One reconcile pass

```bash
bash days/day26/scripts/reconcile-cr.sh \
  --cr days/day26/examples/frontend.cr --state-dir /tmp/cluster
```

```
CREATE frontend-0
CREATE frontend-1
CREATE frontend-2
----------------------------
reconciled: frontend (3 created, 0 updated, 0 deleted) phase=Ready
```

The controller now wrote a **status subresource** at
`/tmp/cluster/status/frontend.status`:

```ini
desiredReplicas=3
observedReplicas=3
readyReplicas=3
image=nginx:1.25
phase=Ready
```

## 3. Level-triggered convergence

Edit the spec and reconcile again — the controller does the minimum to converge:

| Change | Actions taken |
|---|---|
| `replicas: 3 → 5` | `CREATE frontend-3`, `CREATE frontend-4` |
| `replicas: 5 → 2` | `DELETE frontend-2..4` |
| `image: → nginx:1.26` | `UPDATE` every pod (rolling to new image) |
| no change | `already reconciled` (no-op) |

Because it's level-triggered, deleting a pod out-of-band and re-running simply
re-creates it — self-healing falls out for free (Day 29 builds on this).

## 4. The control loop

```bash
# single sweep over every *.cr (great for CI)
bash days/day26/scripts/operator.sh --cr-dir manifests/ --state-dir /tmp/cluster --once

# run continuously, resyncing every 10s (Ctrl-C to stop)
bash days/day26/scripts/operator.sh --cr-dir manifests/ --state-dir /tmp/cluster --interval 10
```

---

## ✅ Verify

```bash
bats days/day26/tests
```

---

## Recap

| Concept | One-liner |
|---|---|
| CRD / CR | a custom resource = a declarative spec |
| Reconcile | make observed match desired |
| Status subresource | the controller reports what it sees |
| Level-triggered | always drive toward current spec |
| Control loop | reconcile every CR, forever |

Next up: **Day 27 — ArgoCD App-of-Apps.**
