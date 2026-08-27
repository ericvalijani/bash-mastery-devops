<div align="center">

# 🐚 bash-mastery-devops

### From core Bash to Principal-level DevOps automation — in 30 focused days

[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
![Days](https://img.shields.io/badge/curriculum-30%20days-blue?style=flat-square)
![Structure](https://img.shields.io/badge/every%20day-lesson%20%2B%20scripts%20%2B%20tests-orange?style=flat-square)
![Gates](https://img.shields.io/badge/quality-pre--commit%20%2B%20BATS%20%2B%20CI-brightgreen?style=flat-square)

</div>

---

Every day is **one focused lesson** with runnable scripts and a BATS test suite —
no filler, equal weight, identical structure. Shared logic lives once in `/lib`,
and pre-commit + BATS gate the repo from **Day 1**.

## 🚀 Get started in 2 minutes

```bash
git clone <this repo> && cd bash-mastery-devops
cp .env.example .env               # fill in your values (.env is gitignored)
pip install --user pre-commit && pre-commit install

bash days/day01/scripts/variables.sh   # run a lesson
bats days/day01/tests                  # test a lesson
bats -r days                           # test everything
```

## 🗺️ The 30-day path

Six phases, five days each. 🟢/🟡 = reworked from the original course · 🔴 = new.

| Phase | Days | Theme |
|:---:|:---:|:---|
| 1 | 01–05 | 🧱 **Bash Foundations** |
| 2 | 06–10 | 📦 **Data, Files & Text** |
| 3 | 11–15 | 🛡️ **Robust & Concurrent Scripting** |
| 4 | 16–20 | ✅ **Quality, Security & Performance** |
| 5 | 21–25 | ⚙️ **DevOps Automation** |
| 6 | 26–30 | 🏛️ **Platform Engineering (Principal)** |

## 📚 Daily lessons

Each day links straight to its lesson. Open any day to get the walkthrough,
runnable scripts, and its test suite.

### 🧱 Phase 1 — Bash Foundations
| Day | Topic | Lesson |
|:---:|:---|:---:|
| 01 | Shell basics & variables — shebang, strict mode, `readonly`, `export` | [open »](days/day01/README.md) |
| 02 | Conditionals & test expressions — `if/elif`, `[[ ]]`, regex validation | [open »](days/day02/README.md) |
| 03 | Loops — `for` / `while` / `until` and the safe `read` pattern | [open »](days/day03/README.md) |
| 04 | Functions & scope — `local`, echo-return, defaults, array returns | [open »](days/day04/README.md) |
| 05 | Arguments & getopts — positionals, `$@`, named flags with validation | [open »](days/day05/README.md) |

### 📦 Phase 2 — Data, Files & Text
| Day | Topic | Lesson |
|:---:|:---|:---:|
| 06 | File I/O & redirection — `>`/`>>`/`2>`/`&>`, here-docs, safe reads | [open »](days/day06/README.md) |
| 07 | Text processing — `grep` / `sed` / `awk` + the `cut\|sort\|uniq` combo | [open »](days/day07/README.md) |
| 08 | Arrays & associative arrays — indexed maps, keys, `mapfile` | [open »](days/day08/README.md) |
| 09 | JSON & API integration — `jq` read/filter/build, `curl` patterns | [open »](days/day09/README.md) |
| 10 | Environment variables & config — safe `.env` loading, validation, masking | [open »](days/day10/README.md) |

### 🛡️ Phase 3 — Robust & Concurrent Scripting
| Day | Topic | Lesson |
|:---:|:---|:---:|
| 11 | Error handling, logging & debugging — traps, shared logger, `bash -x` | [open »](days/day11/README.md) |
| 12 | Process management & signals — background jobs, PIDs, `wait`, traps | [open »](days/day12/README.md) |
| 13 | Parallel & concurrent execution — bounded worker pools, `wait -n` | [open »](days/day13/README.md) |
| 14 | Modular libraries — one shared `/lib`, sourcing, dual-use guard | [open »](days/day14/README.md) |
| 15 | Unit testing with BATS — `run`, lifecycle, failure paths | [open »](days/day15/README.md) |

### ✅ Phase 4 — Quality, Security & Performance
| Day | Topic | Lesson |
|:---:|:---|:---:|
| 16 | Pre-commit hooks & linting — the quality gate, per-day runs | [open »](days/day16/README.md) |
| 17 | Security fundamentals 🔴 | _coming next_ |
| 18 | Zero-trust security pipeline 🔴 | _planned_ |
| 19 | Performance optimization 🔴 | _planned_ |
| 20 | Unix tooling at scale 🔴 | _planned_ |

### ⚙️ Phase 5 — DevOps Automation
| Day | Topic | Lesson |
|:---:|:---|:---:|
| 21 | Capstone I — Distributed Log Analyzer Pro 🔴 | _planned_ |
| 22 | Rootless containers (Buildah/Podman/Cosign) 🔴 | _planned_ |
| 23 | Modular CI/CD framework 🔴 | _planned_ |
| 24 | Git-driven auto-deploy (GitOps) 🔴 | _planned_ |
| 25 | Kubernetes automation with kubectl 🔴 | _planned_ |

### 🏛️ Phase 6 — Platform Engineering (Principal)
| Day | Topic | Lesson |
|:---:|:---|:---:|
| 26 | Kubernetes Operators & CRDs 🔴 | _planned_ |
| 27 | ArgoCD App of Apps 🔴 | _planned_ |
| 28 | Chaos Engineering 🔴 | _planned_ |
| 29 | Self-Healing systems 🔴 | _planned_ |
| 30 | Cost Optimization / FinOps 🔴 | _planned_ |

> Full map with source legend: **[docs/curriculum.md](docs/curriculum.md)**

## 🗂️ Repository layout

```
bash-mastery-devops/
├── lib/            shared libraries (logging, retry, lock, validator, utils)
├── tests/          shared BATS helper
├── days/dayNN/     one self-contained lesson each (README.md + scripts/ + tests/)
├── projects/       capstone projects (Phase 5+)
├── platform/       Kubernetes / ArgoCD / policies / monitoring (Phase 6)
├── docs/           curriculum.md index + reference notes
└── .github/        CI · Security · Release workflows
```

## 🔒 Quality gates (active from Day 1)

- **pre-commit** — shfmt + shellcheck + gitleaks + hygiene hooks. Run per day on
  only that day's files:
  `pre-commit run --files days/dayNN/scripts/*.sh days/dayNN/tests/*.bats`
  (`--all-files` is reserved for the final pass once all days ship.)
- **BATS** — every day has a suite; `bats -r days` runs them all.
- **CI** — `.github/workflows/` runs lint + tests + security on every push.

## 🤝 Contributing

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the "day contract" every folder follows.

<div align="center"><sub>MIT licensed · one concept per day · test everything</sub></div>
