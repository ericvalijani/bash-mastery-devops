# Day 27 — ArgoCD App-of-Apps

ArgoCD watches git and syncs each **Application** into the cluster. The
*app-of-apps* pattern takes it one level up: a single **root** Application
declares a directory of child apps, so your whole platform bootstraps from one
entry point — all declarative, all in git.

Today you build that in shell: leaf apps that sync a source dir → dest dir
(Day 24's engine), and a root app that fans out to its children (Day 26's
declarative model). No real ArgoCD needed.

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **Argo lib** | `days/day27/scripts/argo-lib.sh` | `app_get`, `diff_dirs`, hashing |
| **Sync app** | `days/day27/scripts/sync-app.sh` | Sync one leaf Application (source → dest) |
| **Sync root** | `days/day27/scripts/sync-root.sh` | App-of-apps: sync every child |

---

## 1. A leaf Application

```ini
kind   = Application
name   = frontend
source = days/day27/examples/desired/frontend   # git (desired)
dest   = /tmp/argo-demo/frontend                # live
```

```bash
bash days/day27/scripts/sync-app.sh --app days/day27/examples/apps/frontend.app --base "$PWD"
```

```
CREATE	deployment.yaml
----------------------------
app frontend: Synced (Healthy)
```

Sync status is honest: **Synced/OutOfSync** plus **Healthy/Degraded**, computed
by re-diffing after apply. Unmanaged extra files are left alone unless `--prune`.

## 2. The root: app-of-apps

```ini
kind = Application
name = platform-root
apps = days/day27/examples/apps      # a dir of child *.app manifests
```

```bash
bash days/day27/scripts/sync-root.sh --app days/day27/examples/root.app --base "$PWD"
```

```
>>> syncing api.app
app api: Synced (Healthy)
>>> syncing frontend.app
app frontend: Synced (Healthy)
============================
root platform-root: 2/2 apps synced
```

Add a new service by dropping one `*.app` file in the apps dir and committing —
the next root sync picks it up. That's the whole point of app-of-apps.

## 3. Dry-run as a fleet gate

`--dry-run` reports what *would* change and exits non-zero when anything is
OutOfSync — so `sync-root --dry-run` is a CI gate for your entire platform:

```bash
bash days/day27/scripts/sync-root.sh --app root.app --base "$PWD" --dry-run || echo "drift!"
```

| Flag | Effect |
|---|---|
| `--dry-run` | plan only; non-zero if OutOfSync |
| `--prune` | delete live files not declared in git |
| `--base DIR` | resolve manifest paths against DIR |

---

## ✅ Verify

```bash
bats days/day27/tests
```

---

## Recap

| Concept | One-liner |
|---|---|
| Application | maps a git source to a live dest |
| App-of-apps | one root declares many children |
| Sync status | Synced / OutOfSync, honestly re-diffed |
| Dry-run gate | non-zero on drift, for CI |
| Prune | remove undeclared live files |

Next up: **Day 28 — Chaos Engineering.**
