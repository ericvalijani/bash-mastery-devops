#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/60-promote.sh
# Promote to production using GitOps auto-deploy (stub for local)

set -euo pipefail

# Load helpers if not already
if ! command -v log >/dev/null 2>&1; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
	source "${BASE_DIR}/lib/helpers.sh"
fi

log "Promoting version ${VERSION} to production..."

# Call stub deploy.sh
bash scripts/projects/auto-deploy/deploy.sh "${VERSION}" production

log "Promotion triggered — ArgoCD will sync automatically"
