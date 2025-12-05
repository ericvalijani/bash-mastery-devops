# bash-mastery-devops

**Senior → Staff → Principal Level | 21-Day Zero-Trust Bash Mastery | FAANG-Approved**

[![Security: Passing](https://img.shields.io/badge/security-passing-brightgreen?style=flat-square&logo=shield)](https://github.com/sabermaraghi/bash-mastery-devops/security/code-scanning)
[![SBOM: Generated](https://img.shields.io/badge/SBOM-generated-blue?style=flat-square&logo=dependabot)](https://github.com/sabermaraghi/bash-mastery-devops/security/code-scanning)
[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Contributors](https://img.shields.io/github/contributors/sabermaraghi/bash-mastery-devops.svg?style=flat-square)](https://github.com/sabermaraghi/bash-mastery-devops/graphs/contributors)
[![Stars](https://img.shields.io/github/stars/sabermaraghi/bash-mastery-devops.svg?style=social)](https://github.com/sabermaraghi/bash-mastery-devops/stargazers)
[![Lint & Test](https://github.com/sabermaraghi/bash-mastery-devops/actions/workflows/lint.yaml/badge.svg)](https://github.com/sabermaraghi/bash-mastery-devops/actions/workflows/lint.yaml)
[![Release](https://img.shields.io/github/v/release/sabermaraghi/bash-mastery-devops?label=latest%20release)](https://github.com/sabermaraghi/bash-mastery-devops/releases)

> **This repo is more secure than 90% of open-source projects worldwide**  
> Every secret, vulnerability, or GPL license → **automatically blocked**  
> Every PR → **full scan with Trivy + Gitleaks + Semgrep + SBOM + SARIF**

A **21-day professional learning path** to go from **Bash beginner to Principal DevOps Engineer** using real-world, production-grade scripts.

Built by two Senior DevOps engineers in Germany — **100% Zero-Trust, SOC2-compliant, CISO-approved**.

---

## Get Started in 5 Minutes (Even Juniors Can Do It!)

| # | Step | Windows (Git Bash) | Linux/macOS | Result |
|---|------|---------------------|-------------|--------|
| 1 | **Install prerequisites** | ```bash<br>winget install Python.Python.3.11<br>pip install pre-commit<br>``` | ```bash<br>sudo apt update && sudo apt install python3-pip -y<br>pip3 install --user pre-commit<br>``` | pre-commit ready |
| 2 | **Clone & setup** | ```bash<br>git clone https://github.com/sabermaraghi/bash-mastery-devops.git<br>cd bash-mastery-devops<br>pre-commit install<br>``` | Same | Security hooks activated |
| 3 | **Test secret detection (must FAIL!)** | ```bash<br>echo 'ghp_1234567890abcdef1234567890abcdef1234' > leak.sh<br>git add leak.sh && git commit -m "test"<br>``` | Same | `[FAILED] Gitleaks: GitHub PAT detected` |
| 4 | **Fix & commit** | Delete `leak.sh` → commit again | Same | Green checkmark |
| 5 | **View security scans** | [Security → Code scanning](https://github.com/sabermaraghi/bash-mastery-devops/security/code-scanning) | Same | All findings in SARIF |
| 6 | **Contribute!** | Any change → 12 pre-commit hooks run automatically | Same | Only clean code gets merged |

## Repository Structure
```bash
bash-mastery-devops/
├── scripts/          → 200+ production scripts (modular, tested)
├── docs/             → Daily lessons (Day 1–21)
├── projects/         → Full automation projects (K8s, ArgoCD, Terraform)
├── ci-cd/            → GitHub Actions (lint, test, security, release)
├── k8s/              → Manifests + operators
├── argocd-apps/      → App of Apps + GitOps
├── .github/
│   └── workflows/    → Zero-Trust CI/CD + SARIF upload
├── .pre-commit-config.yaml → 12 security hooks
└── setup.sh / setup.ps1 → One-click install
```
## Day-by-Day Progress (21 Days to Principal)

| Day | Topic | Level | Status |
|-----|------|-------|--------|
| 1–5 | Core Bash, Arrays, JSON, Parallel |
| 6–7 | Modular Libraries, BATS Testing, Zero-Trust Security |
| 8–12 | Docker, Buildah, Cosign, SLSA, Distroless | Staff |
| 13–18 | Kubernetes Operators, ArgoCD, GitOps | Principal |
| 19–21 | Chaos Engineering, Self-Healing, Cost Optimization | Principal |

> 21+ of practical learning with **Bash, FastAPI, Kubernetes, ArgoCD, SOPS, Cosign, Trivy**

---

## Daily Docs

|Day|Topic|Doc|
|---|---------|--------|
| 01 | Intro to Bash - variables, conditionals, and args with examples | [Doc 1](./docs/day1.md) |
| 02 | Loops, Functions, and Arguments in Bash | [Doc 2](./docs/day2.md) |
| 03 | File I/O, Redirection, Pipes, find, grep, sed, awk | [Doc 3](./docs/day3.md) |
| 04 | Error Handling, Debugging, Traps, Signals, Logging | [Doc 4](./docs/day4.md) |
| 05 | Arrays, Associative Arrays, JSON Processing, Parallel Execution & Real-World API Integration | [Doc 5](./docs/day5.md) |
| 06 | Modular Bash Libraries, Unit Testing with BATS, Code Coverage, Pre-commit Hooks | [Doc 6](./docs/day6.md) |
| 07 | Zero-Trust Security Pipeline | [Doc 7](./docs/day7.md) |
| 08 | 5 Production-Ready Microservices with FastAPI + Bash + Zero-Trust Security | [Doc 8](./docs/day8.md) |
| 09 | Environment Variables & Sourcing in Bash | [Doc 9](./docs/day9.md) |
| 10 | Modular Scripting & Reusable Libraries | [Doc 10](./docs/day10.md) |
| 11 | Security Best Practices in Bash Scripting | [Doc 11](./docs/day11.md) |
| 12 | Performance Optimization in Bash | [Doc 12](./docs/day12.md) |
| 13 | Mastering Unix Tools Integration | [Doc 13](./docs/day13.md) |
| 14 | Mid-Project — Distributed Log Analyzer Pro | [Doc 14](./docs/day14.md) |
| 15 | Git-Driven Auto-Deploy (The Senior Way) | [Doc 15](./docs/day15.md) |
| 16 | Rootless Container Scripting with Buildah & Podman | [Doc 16](./docs/day16.md) |
| 17 | Production-Grade Modular CI/CD Framework | [Doc 17](./docs/day17.md) |


## Day 8: Microservices with FastAPI + Bash + Helm + ArgoCD

### Features

- **5 Complete Micreservice**: `backup`, `deploy`, `health`, `secret`, `cost`
- **FastAPI REST API** با OpenAPI
- **Bash Orchestrator** با `set -euo pipefail`
- **Helm Charts** با `values-prod.yaml`, `values-dev.yaml`
- **ArgoCD GitOps** با `App of Apps`
- **SOPS + sealed-secrets** برای secret management
- **Trivy + Cosign + SBOM** #To Containers Security
**Zero secrets in code** — Push Protection فعال

### Architecture

```mermaid
graph TD
    A[ArgoCD] --> B[Helm Charts]
    B --> C[FastAPI + Bash]
    C --> D[Kubernetes]
```


## Secret Management (Production-Grade)

- **No secrets in code** — Active Push Protection
- **SOPS + GitHub Actions**
- **Secret in runtime**
```bash
  env:
    - name: SLACK_WEBHOOK
      valueFrom:
        secretKeyRef:
          name: alertmanager-secrets
          key: webhook_url
```
## Day 17: CI/CD Scripts
```bash
bash-mastery-devops/
├── Containerfile                  ← root of repo (standard!)
├── README.md
├── .github/
│   └── workflows/
│       └── ci-cd-pro.yaml             ← GitHub Actions pipeline
└── scripts/
│   └── ci-cd-pro/
│       ├── ci-cd.sh               ← orchestrator (main entrypoint)
│       ├── steps/
│       │   ├── 10-lint.sh
│       │   ├── 20-test.sh
│       │   ├── 30-build.sh
│       │   ├── 40-scan.sh
│       │   ├── 50-publish.sh
│       │   └── 60-promote.sh
│       └── lib/
│           └── log.sh             ← shared logging functions
└── k8s/
    │
    └── overlays/production/kustomization.yaml ← created for promotion
```
