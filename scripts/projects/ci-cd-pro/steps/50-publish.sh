#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/50-publish.sh
# Push image to registry

set -euo pipefail

log "Pushing image to registry..."

retry 3 podman push "${IMAGE_NAME}:${VERSION}"
retry 3 podman push "${IMAGE_NAME}:latest"

log "Image published successfully"
