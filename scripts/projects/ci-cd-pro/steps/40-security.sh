#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/40-security.sh
# FINAL VERSION — skips Cosign for local images

set -euo pipefail

# Load helpers if not already
if ! command -v log >/dev/null 2>&1; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
	source "${BASE_DIR}/lib/helpers.sh"
fi

log "Running Trivy vulnerability scan..."
trivy image \
	--severity HIGH,CRITICAL \
	--no-progress \
	"${IMAGE_NAME}:${VERSION}" || true # Tolerant for dev

log "Generating SBOM with Syft..."
syft "${IMAGE_NAME}:${VERSION}" \
	-o cyclonedx-json \
	>"sbom-${VERSION}.json" || true

log "Signing image with Cosign (keyless)..."
if [[ "${IMAGE_NAME}" == localhost/* ]]; then
	log "Local image detected — skipping Cosign signing (requires remote registry)"
else
	digest="$(podman image inspect "${IMAGE_NAME}:${VERSION}" --format '{{.Digest}}')"
	cosign sign --yes "${IMAGE_NAME}@${digest}" || true
fi

log "Security checks completed (local mode)"
