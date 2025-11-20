#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/60-promote.sh
# Promote to production using GitOps auto-deploy (Day 15)

set -euo pipefail

log "Promoting version ${VERSION} to production..."

bash scripts/projects/auto-deploy/deploy.sh "${VERSION}" production

log "Promotion triggered — ArgoCD will sync automatically"
