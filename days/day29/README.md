# Day 29 — Self-Healing Systems

Yesterday you broke the cluster on purpose and the experiment *failed* — nothing
put the dead pods back. Today you build the thing that does: a **watchdog** that
probes for liveness, restarts what died, and knows when to give up.

This is Kubernetes' core promise in shell: declare the desired state, then let a
control loop continuously drive reality back toward it.

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **Health lib** | `days/day29/scripts/health-lib.sh` | Liveness probe, healthy count, restart bookkeeping |
| **Heal** | `days/day29/scripts/heal.sh` | One remediation pass (restart policy + backoff) |
| **Watchdog** | `days/day29/scripts/watchdog.sh` | The control loop: heal until healthy or budget spent |

---

## Liveness probe

A pod (a file whose content is its image) is **dead** if it's missing, empty,
marked `CRASHED`, or running a `:bad` image that crashes on start. Everything
else is alive.

## 1. Heal a single time

Kill two pods, then run one heal pass:

```bash
rm /tmp/cluster/pods/frontend-1 /tmp/cluster/pods/frontend-3
bash days/day29/scripts/heal.sh \
  --state-dir /tmp/cluster --name frontend --replicas 5 --image nginx:1.25
```

```
RESTART frontend-1 (attempt 1/5, image=nginx:1.25)
RESTART frontend-3 (attempt 1/5, image=nginx:1.25)
----------------------------
healed: 2 restart(s), 0 crashloop — healthy 5/5
```

## 2. Restart policy

| Policy | Behavior |
|---|---|
| `Always` (default) | restart any dead pod |
| `OnFailure` | restart any dead pod (same here — liveness-driven) |
| `Never` | report only, never restart |

```bash
bash days/day29/scripts/heal.sh --state-dir /tmp/cluster --name frontend \
  --replicas 5 --image nginx:1.25 --restart-policy Never
# UNHEALTHY frontend-1 (policy=Never, not restarting)
```

## 3. The watchdog loop — turning yesterday's failure into a pass

```bash
# inject with Day 28, then let the watchdog converge the system
bash days/day28/scripts/chaos-kill.sh --state-dir /tmp/cluster --name frontend --expect 5 --count 2 --seed 7
bash days/day29/scripts/watchdog.sh \
  --state-dir /tmp/cluster --name frontend --replicas 5 --image nginx:1.25 --max-iterations 5
```

```
=== watchdog pass 1/5 ===
RESTART frontend-0 (attempt 1/5, image=nginx:1.25)
RESTART frontend-3 (attempt 1/5, image=nginx:1.25)
----------------------------
healed: 2 restart(s), 0 crashloop — healthy 5/5
watchdog: system healthy after 1 pass(es)
```

## 4. CrashLoopBackOff — knowing when to stop

A restart loop that never fixes anything is worse than none. Deploy a `:bad`
image and the watchdog restarts up to `--max-restarts`, then gives up:

```bash
bash days/day29/scripts/watchdog.sh --state-dir /tmp/cluster --name broken \
  --replicas 1 --image app:bad --max-restarts 2 --max-iterations 5
```

```
CRASHLOOP broken-0 (restarts=2, giving up)
watchdog: system still degraded after 5 pass(es)   # exit 1
```

Stable pods reset their restart counter, so transient blips don't count against
a pod forever — only sustained failure reaches CrashLoopBackOff.

---

## ✅ Verify

```bash
bats days/day29/tests
```

---

## Recap

| Concept | One-liner |
|---|---|
| Liveness probe | is this pod actually alive? |
| Restart policy | Always / OnFailure / Never |
| Backoff counter | resets when a pod goes stable |
| CrashLoopBackOff | stop restarting a hopeless pod |
| Control loop | continuously reconcile toward desired state |

Next up: **Day 30 — Cost & FinOps.**
