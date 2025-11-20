#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/30-build.sh
# Build container image using Buildah (rootless)

set -euo pipefail

log "Building container image: ${IMAGE_NAME}:${VERSION}"

buildah bud \
  --tag "${IMAGE_NAME}:${VERSION}" \
  --tag "${IMAGE_NAME}:latest" \
  -f Containerfile .

log "Image built successfully"
