#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
log "Building container image with buildah"
buildah bud -t "$FULL_IMAGE" -t "$IMAGE_NAME:latest" -f Containerfile .
