#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/30-build.sh
# Build with podman — guaranteed visible to Trivy/Syft/Cosign

set -euo pipefail

# Load helpers if not already
if ! command -v log >/dev/null 2>&1; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
	source "${BASE_DIR}/lib/helpers.sh"
fi

log "Building container image: ${IMAGE_NAME}:${VERSION}"

# Go to repo root where Containerfile lives (reliable git method)
readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Force shared storage (silver bullet for "image not found")
podman system migrate 2>/dev/null || true

# Build with podman — explicit error check
podman build \
	--tag "${IMAGE_NAME}:${VERSION}" \
	--tag "${IMAGE_NAME}:latest" \
	-f Containerfile . || {
	log_error "Build failed — check Containerfile path and Podman setup"
	exit 1
}

log "Image built successfully with podman"
log "Verify: podman images | grep myapp"
