#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/ci-cd.sh
# Senior/Staff-level CI/CD orchestrator — runs steps in order
# Usage: ./ci-cd.sh [all|lint|test|...]

set -euo pipefail
IFS=$'\n\t'

readonly BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared helpers and config
source "${BASE_DIR}/lib/helpers.sh"
source "${BASE_DIR}/config.env" 2>/dev/null || true

# Default values
export IMAGE_NAME="${IMAGE_NAME:-ghcr.io/$(git config user.name)/myapp}"
export VERSION="${VERSION:-$(git rev-parse --short HEAD)}"

log "Starting CI/CD Pro Pipeline"
log "Target image: ${IMAGE_NAME}:${VERSION}"

# Run all steps in order (10-*.sh, 20-*.sh, etc.)
for step_script in "${BASE_DIR}/steps"/[0-9][0-9]-*.sh; do
	[[ -f "$step_script" ]] || continue
	step_name="$(basename "$step_script")"
	log "Executing step: $step_name"
	source "$step_script" || {
		log_error "Step failed: $step_name"
		exit 1
	}
done

log "CI/CD Pipeline completed successfully!"
log "Deployed version: ${VERSION}"
