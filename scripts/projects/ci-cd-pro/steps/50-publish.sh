#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/50-publish.sh
# Push image to registry — skips local

set -euo pipefail

# Load helpers if not already
if ! command -v log >/dev/null 2>&1; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
	source "${BASE_DIR}/lib/helpers.sh"
fi

log "Pushing image to registry..."

# Skip for local images
if [[ "${IMAGE_NAME}" == localhost/* ]]; then
	log "Local image detected — skipping registry push"
	exit 0
fi

retry 3 podman push "${IMAGE_NAME}:${VERSION}"
retry 3 podman push "${IMAGE_NAME}:latest"

log "Image published successfully"
