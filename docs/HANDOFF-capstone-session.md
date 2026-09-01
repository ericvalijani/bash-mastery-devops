# Handoff — bash-mastery-devops (capstone + docs session)

> Portable context for importing this work into another chat. Covers the repo,
> the capstone project built this session, all conventions, constraints, and
> open items. Written to be self-contained.

---

## 0. TL;DR of this session

This session (after Days 1–30 were already complete) did four things:

1. **Built the capstone project** `projects/devops-platform/` — a real,
   GitOps-managed, self-healing, cost-observable Kubernetes platform that wires
   **each of Days 22–30 to a real command**. Offline-first + CI-safe.
2. **Wired it "just like the 30 days"**: its own BATS suite + pre-commit
   coverage (added `projects` to the repo bats hook).
3. **Documentation fixes**: root README capstone section + `.env` clarification;
   full Terraform walkthrough + "non-kind cluster" + "no Helm/Vagrant" notes in
   the capstone README; capstone entry in `docs/curriculum.md`.
4. **Answered infra questions** (Terraform install, Helm/Vagrant, non-kind K8s).

**Nothing was committed** — the user works on it themselves and commits per-day.

---

## 1. Repository overview

- **Repo:** `https://github.com/ericvalijani/bash-mastery-devops.git`, branch `fix/day27`.
- **Purpose:** "30 days from core Bash to Principal-level DevOps." One concept per
  day; each day = `README.md` + `scripts/` + BATS `tests/`. Shared code in `/lib`.
  Pre-commit + BATS gate from Day 1.
- **Top-level layout:**
  ```
  bash-mastery-devops/
  ├── lib/            shared libs (logging, retry, lock, validator, utils)
  ├── tests/          shared BATS helper (tests/test_helper)
  ├── days/dayNN/     one lesson each (README.md + scripts/ + tests/)
  ├── projects/       capstone projects (Phase 5+)  ← capstone built here
  ├── platform/       kind bootstrap / ArgoCD / realmode helpers (Phase 6)
  ├── docs/           curriculum.md + handoffs
  └── .github/        CI · Security · Release · capstone workflows
  ```

### The locked 30-day curriculum
- **P1 (1–5) Bash Foundations:** Shell/vars, Conditionals, Loops, Functions, Args/getopts.
- **P2 (6–10) Data/Files/Text:** File I/O, grep/sed/awk, Arrays, JSON+APIs, Env/config.
- **P3 (11–15) Robust/Concurrent:** Error+logging, Signals, Parallel, Modular libs, BATS.
- **P4 (16–20) Quality/Security/Perf:** Pre-commit, Security fundamentals, Zero-trust, Perf, Unix-at-scale.
- **P5 (21–25) DevOps Automation:** Log Analyzer Pro, Rootless containers, CI/CD, GitOps, kubectl.
- **P6 (26–30) Platform Eng (Principal):** K8s Operators/CRDs, ArgoCD App-of-Apps, Chaos, Self-Healing, Cost/FinOps.

Each Phase-5/6 day ships **Option 1 (offline simulation, the default, CI-green)**
and **Option 2 (real, against a live kind cluster, degrades to exit 3 without tools)**.

---

## 2. The capstone project — `projects/devops-platform/`

**Concept:** the graduation project. Ties the platform days into one runnable
system: ArgoCD-managed apps on a kind cluster, with operator/chaos/self-heal/
cost commands. Reuses the day scripts (no duplication). Offline `validate` keeps
it CI-green with no cluster.

### File tree (33 files packaged, incl. root docs)
```
projects/devops-platform/
├── README.md                     full guide (Requirements, provision paths,
│                                 Quickstart, Terraform walkthrough, non-kind,
│                                 9-day mapping, Verify)
├── capstone.sh                   driver (see subcommands below)
├── ops/widgetset.cr              Day 26 WidgetSet CR (kind=WidgetSet name=widgets
│                                 replicas=2 image=nginx:1.25-alpine)
├── infra/                        Terraform (optional provisioning)
│   ├── main.tf                   kind_cluster + null_resource argocd + metrics-server
│   ├── variables.tf              cluster_name(bash-mastery), argocd_manifest, metrics_manifest
│   ├── outputs.tf                context, next_steps
│   └── README.md                 Option A (scripts) vs Option B (terraform)
├── gitops/                       ArgoCD app-of-apps
│   ├── root.yaml                 Application "platform-root" (namespace argocd)
│   └── apps/{backend,frontend}.yaml  leaf Applications
├── services/
│   ├── backend/                  Bash HTTP server (busybox nc) on Alpine
│   │   ├── Dockerfile            non-root user (Day 18 habit)
│   │   ├── app/server.sh         printf HTTP/1.1 200 | nc -l -p 8080 loop
│   │   └── k8s/{deployment,service}.yaml
│   └── frontend/                 nginx + static index.html
│       ├── Dockerfile            nginx:1.27-alpine
│       ├── app/index.html
│       └── k8s/{deployment,service}.yaml
└── tests/capstone.bats           offline BATS (validate + arg guards + CR check)
```
Plus repo-level files touched: `.github/workflows/capstone.yml`, root `README.md`,
`docs/curriculum.md`, `.pre-commit-config.yaml`.

### capstone.sh subcommands (exit: 0 ok · 1 problem · 2 usage · 3 missing tool/cluster)
| Cmd | What it does | Reuses | Cluster? |
|---|---|---|---|
| `validate` | offline: every file/manifest present & sane; `bash -n` server.sh; every yaml has `kind:` | — | no (CI-safe) |
| `up --context CTX` | create cluster + metrics-server + install ArgoCD | `platform/bootstrap.sh up --metrics` + day27 `real-argo.sh install` | yes |
| `deploy --context CTX` | apply the app-of-apps root | `kubectl apply gitops/root.yaml` | yes |
| `operate --context CTX [--apply]` | reconcile WidgetSet CR (Day 26) | day26 `real-operator.sh reconcile` (ns `widgets`) | yes |
| `chaos --context CTX [--apply]` | controlled pod failure on backend (Day 28) | day28 `real-chaos.sh run` (selector app=backend, expect 2) | yes |
| `heal --context CTX [--apply]` | reconcile drift + surface crashloops (Day 29) | day29 `real-heal.sh heal` (deploy backend, replicas 2) | yes |
| `status --context CTX` | ArgoCD apps, pods, services | kubectl | yes |
| `cost --context CTX` | Day 30 FinOps report over services | day30 `real-cost.sh report` per ns | yes |
| `down --context CTX [--all]` | remove apps (`--all` also deletes cluster) | kubectl / bootstrap.sh down | yes |

- Internals: `REPO_ROOT=../..`; sources `lib/logging.sh` + `platform/lib/realmode.sh`;
  `KUBECTL=${KUBECTL:-kubectl}`; `SERVICE_NS=(backend frontend)`; `WIDGET_NS=widgets`.
- `_parse_ctx` handles `--context`/`--all`/`--apply`; `_apply_flags` echoes
  `--apply --confirm` only when `APPLY=1`. `_check_cluster` uses `kubectl version
  --request-timeout=10s` → exit 3 if unreachable. Mutating cmds preview by
  default; act only with `--apply`.

### The 9-day mapping (why it's a "9-day" capstone, not 5)
| Day | Skill | Where it runs |
|---|---|---|
| 22 | Containers & images | backend + frontend `Dockerfile` |
| 23 | CI/CD | `.github/workflows/capstone.yml` (validate + shellcheck + BATS) |
| 24 | GitOps foundations | `gitops/` app-of-apps model |
| 25 | kubectl plumbing | every real cmd (day25 `kubectl-lib.sh`) + `status` |
| 26 | Operators / reconcile | `capstone.sh operate` → day26 `real-operator.sh` + `ops/widgetset.cr` |
| 27 | ArgoCD | `capstone.sh up`/`deploy` → day27 `real-argo.sh` |
| 28 | Chaos engineering | `capstone.sh chaos` → day28 `real-chaos.sh` |
| 29 | Self-healing | `capstone.sh heal` → day29 `real-heal.sh` |
| 30 | Cost & FinOps | `capstone.sh cost` → day30 `real-cost.sh` |
Days 1–21 are the invisible foundation (strict mode, funcs, args, error
handling, BATS, pre-commit, security/zero-trust — e.g. non-root backend container).

### Provisioning: two interchangeable paths (same end state, context `kind-bash-mastery`)
- **Path A (default, scripts):** `capstone.sh up` → `bootstrap.sh` + ArgoCD + metrics-server. Needs only Docker + kind + kubectl.
- **Path B (optional, Terraform):** `cd infra && terraform init && terraform apply -var="cluster_name=bash-mastery"`. Creates the same cluster + ArgoCD + metrics-server declaratively; outputs `context` + `next_steps`. Tear down with `terraform destroy` (don't mix with `capstone.sh down --all`).
- **No Helm, no Vagrant.** kind runs K8s in Docker (no VMs). Apps are plain YAML via ArgoCD (no charts).
- **Non-kind clusters:** the app layer (plain YAML + ArgoCD) is portable to EKS/GKE/AKS/k3s/minikube — skip `up`/Terraform, install ArgoCD if absent, then `deploy --context <ctx>`. Only provisioning (`up`, Terraform kind provider, metrics-server `--kubelet-insecure-tls` patch) is kind-specific.

### Backend image note
Backend Deployment references `devops-platform/backend:1.0.0` → must `docker build`
+ `kind load docker-image ... --name bash-mastery` or pods sit in `ErrImagePull`.
Frontend uses stock `nginx:1.27-alpine` (comes up without a build).

### Quality gates ("just like 30 days")
- **BATS:** `projects/devops-platform/tests/capstone.bats` uses shared
  `tests/test_helper` + only `assert_success`/`assert_failure`/`assert_output_contains`.
- **Pre-commit:** repo hooks run repo-wide (hygiene, shfmt, shellcheck, gitleaks,
  trivy) so capstone shell is covered. The repo `bats` hook was changed from
  `bats -r days` → `bats -r days projects` so the capstone suite is gated too.
- **Per-day-style pre-commit for the capstone:**
  ```bash
  pre-commit run --files \
    projects/devops-platform/capstone.sh \
    projects/devops-platform/services/backend/app/server.sh \
    projects/devops-platform/tests/capstone.bats
  ```
- **Suggested capstone commit (not yet done):**
  ```
  feat(projects): devops-platform capstone (GitOps + self-heal + FinOps)

  - app-of-apps deploys a Bash backend + nginx frontend via ArgoCD
  - capstone.sh orchestrates bootstrap/argocd/cost day scripts; offline validate + BATS
  - infra as code via Terraform (kind + ArgoCD + metrics-server)
  ```

### Offline verification performed (sandbox)
- `bash -n` clean on `capstone.sh` + `server.sh`.
- `capstone.sh validate` → 22 checks ok, exit 0.
- Arg guards: `operate/chaos/heal/up/deploy` with no `--context` → exit 2; unknown subcmd → exit 2.
- `operate/chaos/heal --context kind-nope` (no cluster) → exit 3 (graceful degrade).

---

## 3. Documentation changes this session
- **Root `README.md`:** added "🏗️ Capstone project — devops-platform" section (link + quickstart); **removed `cp .env.example .env` from the global quickstart** and added a note that `.env` is **only for the Day 10 lesson** (no other day/test/CI needs it).
- **`docs/curriculum.md`:** added "Capstone project — devops-platform" section with the Day 22–30 → command table + "no Helm/Vagrant, Terraform optional" note.
- **Capstone `README.md`:** Requirements table; "Two ways to provision"; Quickstart (steps 0–8 incl. operate/chaos/heal); official Terraform install (HashiCorp apt repo, NOT snap) + apply/destroy walkthrough + "what apply does"; "Running on a cluster other than kind"; "no Helm/Vagrant" explanation; 9-day mapping; Verify.
- **`infra/README.md`:** Option A (scripts) vs Option B (Terraform).

### `.env` audit result (answered a user question)
- Only **Day 10** consumes `.env` (`config-loader.sh`, default `$REPO_ROOT/.env`, override via `CONFIG_FILE`; `app.sh` sources the loader). Day 10 BATS uses a temp `.env` so **tests/CI never need the real file**. Day 17 only references `.env` as a filename pattern to harden perms. Design is **correct**: `.env.example` committed, `.env` gitignored. Only the README quickstart was misleading (now fixed).

---

## 4. Key facts about reused day scripts (for wiring/debugging)
- **platform/bootstrap.sh:** `up [--name NAME] [--metrics]` / `down` / `status`; DEFAULT_NAME=bash-mastery → context `kind-bash-mastery`; `--metrics` installs+patches metrics-server; **stdout = context only** (logs → stderr); KUBECTL/KIND env overridable; missing tool → exit 3.
- **day27 real-argo.sh:** `install/render/render-children/apply/sync/status/ui/admin-password`; ARGOCD_MANIFEST default `https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`.
- **day26 real-operator.sh:** `reconcile|status|watch|delete --cr FILE --context CTX --namespace NS [--apply] [--confirm]`; reuses `operator-lib.sh` (`cr_get`) + day25 `kubectl-lib.sh`. CR format: `kind = WidgetSet / name = / replicas = / image =`.
- **day28 real-chaos.sh:** `kill|run --context CTX --namespace NS --selector SEL --expect E [--count N|--percent P] [--seed S] [--max-percent M] [--apply] [--confirm]`; steady-state + blast-radius + reproducible.
- **day29 real-heal.sh:** `heal|watch --context CTX --namespace NS --deployment NAME --replicas N [--selector SEL] [--max-restarts M] [--apply] [--confirm]`.
- **day30 real-cost.sh:** `report|rightsize --context --namespace [--selector] [--cpu-price 0.031] [--mem-price 0.004] [--hours 730] [--low 30] [--high 90] [--target 60]`; READ-ONLY; reuses offline `cost-lib.sh`; default selector `app=<deployment>`; **rightsize needs metrics-server**. Price model $0.031/core-hr CPU, $0.004/GiB-hr mem, 730h/mo; recommendation `ceil(usage/(target/100))`.
- **day25 kubectl-lib.sh:** `kubectl_bin ($KUBECTL)`, `current_context`, `is_protected_context ($PROTECTED_CONTEXTS default prod,production)`, `is_valid_namespace` (RFC1123).
- **platform/lib/realmode.sh:** `rm_banner <title>` ("REAL MODE · <title>" + "Offline simulation stays the default"), `rm_confirm` (REAL_ASSUME_YES=1), `rm_require_tools` (literal command -v — useless with stubs).
- **lib/logging.sh:** `log/log_info/log_warn` → stdout tee; `log_error` → stderr JSON; `log_debug` when DEBUG=true; LOG_FILE default → /dev/null fallback.

### metrics-server install on kind (correct — a past user error)
`--kubelet-insecure-tls` is a **container arg**, not a kubectl flag. Do:
```bash
kubectl --context CTX apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl --context CTX -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl --context CTX -n kube-system rollout status deploy/metrics-server
```
Or just `bash platform/bootstrap.sh up --metrics`. (metrics-server is now installed on the user's real cluster.)

---

## 5. Working conventions & constraints (persist these)
- **Delivery:** deliver ONLY changed files WITH folder structure (`zip /data/x.zip <paths>`). Working copy: `/data/newrepo/bash-mastery-devops/`.
- **Translate any non-English content in the repo → English.**
- **Per-day pre-commit:** `pre-commit run --files <that day's changed files>` — never `--all-files`, never include docs.
- **Commit messages:** file-summary/feature style, short — subject + 2–4 line body. NOT bug lists. User commits per-day themselves.
- **Sandbox facts:** `computer.writeFile` needs `overwrite:true` (creates parent dirs). `computer.editFile` = `file_path` + `edits:[{old_string,new_string,replace_all?}]` and must NOT carry `editDescriptionVariableName` inside an edit item. `downloadFile`/`readFile` take only `path`. **Sandbox reverts between turns — re-verify on-disk state before packaging.**
- **No tooling in sandbox:** no shfmt/shellcheck/bats/gitleaks/trivy/kubectl/kind/docker/terraform/network. Verify via `bash -n` + fake-binary harness + grep sweeps. `bash -n` on `.bats` gives false errors — use grep instead.
- **Bash portability gotchas:** default sandbox shell is `sh` (wrap in bash); safe arithmetic `x=$((x+1))`; avoid `< <(...)`; use `${var:-}` in traps; standalone `((expr))` under `set -e` aborts unless in condition/`&&`/`||`.
- **test_helper:** load `../../../tests/test_helper`; ONLY `assert_success`/`assert_failure`/`assert_output_contains` (NO bare `assert_output`).
- **Real-deploy philosophy:** offline stays the DEFAULT & CI-green; real degrades gracefully (exit 3); ship ONE day at a time then STOP for user confirmation.

---

## 6. Status of the 30 days (before this session)
- **Days 1–29:** DONE & confirmed. Day 27 committed (17 files). Days 28/29/30 delivered with commit messages (may still need committing by the user).
- **Day 30 (Cost/FinOps, real Option 2):** DELIVERED & verified on the user's real cluster (report + rightsize both worked after installing metrics-server). 3 files: `days/day30/scripts/real-cost.sh`, `days/day30/tests/real-cost.bats` (13 tests), `days/day30/README.md` (has "Installing metrics-server on kind" section). Commit msg: `feat(day30): real cost & FinOps analysis against a live cluster`.
- **No 🟢/🟡/🔴 legend exists** anywhere (verified by grep) — nothing to remove.

---

## 7. Open items / pending decisions
1. **Commits:** nothing in this session is committed. Owed by user when ready: Day 30, the capstone, possibly Days 28/29. Pre-commit + commit msgs provided above and in prior turns.
2. **Security scan for the 30 days:** user unsure if needed. Currently gitleaks/trivy/shellcheck run non-blocking / skip-if-absent. No blocker to proceed.
3. **Day 17 CI gitleaks history:** open choice — `--no-git` in `security.yml` OR allowlist 4 history SHAs (`5ff533a2`/`94208fa9`/`6f3b584c`/`4db36fb7`). Not blocking.
4. **Next phase requested by user:** a "reviews and analyzing again on projects and 30 days codes" pass, PLUS a mystery next thing ("something won't tell u now").
5. **Optional:** save curriculum + this handoff as Notion pages (offered, not yet done).
6. Root README "Repository layout" already lists `projects/` — fine.

---

## 8. Environment / people (do not put timezone in shared handoffs)
- User: gasscanproton (gasscanproton@proton.me); workspace "Geovanni Stoor's Space".
- Local machine: Linux `eric@eric-X556UQ`, 8GB RAM/i5, `~/Documents/Sonnet 5/bash-mastery-devops`.
- kind context `kind-bash-mastery` (control-plane `bash-mastery-control-plane`, kindest/node:v1.30.0).
- Installed on user machine: gitleaks, trivy, pre-commit, cosign v2.5+/v3, docker (NOT podman), kind, kubectl, argocd CLI (installed, NOT logged in), metrics-server (now installed on cluster).
- Repo: `https://github.com/ericvalijani/bash-mastery-devops.git`, branch `fix/day27`.
