#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/40-security.sh
# Security scanning: Trivy + Syft SBOM + Cosign signing

set -euo pipefail

log "Running Trivy vulnerability scan..."
trivy image \
  --exit-code 1 \
  --severity HIGH,CRITICAL \
  --no-progress \
  "${IMAGE_NAME}:${VERSION}"

log "Generating SBOM with Syft..."
syft "${IMAGE_NAME}:${VERSION}" \
  -o cyclonedx-json \
  > "sbom-${VERSION}.json"

log "Signing image with Cosign (keyless)..."
cosign sign --yes "${IMAGE_NAME}:${VERSION}"

log "Security checks completed"
