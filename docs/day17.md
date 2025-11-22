# Day 17 – Production-Grade Modular CI/CD Framework

```bash
bash-mastery-devops/
├── Containerfile                  ← root of repo (standard!)
├── README.md
├── .github/
│   └── workflows/
│       └── ci-cd-pro.yaml             ← GitHub Actions pipeline
└── scripts/
    └── ci-cd-pro/
        ├── ci-cd.sh               ← orchestrator (main entrypoint)
        ├── steps/
        │   ├── 10-lint.sh
        │   ├── 20-test.sh
        │   ├── 30-build.sh
        │   ├── 40-scan.sh
        │   ├── 50-publish.sh
        │   └── 60-promote.sh
        └── lib/
            └── log.sh             ← shared logging functions
```

## Features
- Fully modular steps (easy to extend)
- Zero external dependencies in runtime image
- Automatic container build & publish on every push
- SBOM generation, vulnerability scanning, image signing
- Auto-promotion via GitOps (day 15 deploy script)
- 100% reusable in any company

## Usage
```bash
# Local
export IMAGE_NAME=ghcr.io/sabermaraghi/bash-mastery-devops
bash scripts/projects/ci-cd-pro/ci-cd.sh all

# Container (after publish)
podman run --rm -v "$PWD":/workspace -w /workspace \
  ghcr.io/sabermaraghi/bash-mastery-devops all
```

## Also change your repo name in /k8s/overlays/production

Clean Up If an Existing Package Is Blocking:
Check if a package exists: Go to https://github.com/sabermaraghi/bash-mastery-devops/pkgs/container/bash-mastery-devops (or your GitHub profile > Packages tab).

Re-Authenticate to GHCR:
echo "YOUR_NEW_PAT" | podman login ghcr.io -u sabermaraghi --password-stdin

Regenerate a Classic PAT with Expanded Scopes:
Go to GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic) > Generate new token (classic).
Select these scopes (to cover all bases for personal repos and existing packages):
repo (full repo access, as packages are linked to repos).
read:packages (to read/download metadata during resolution).
write:packages (to upload/push images).
delete:packages (to delete existing packages if needed for cleanup).
