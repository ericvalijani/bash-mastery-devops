#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
log "Pushing image to GHCR"
podman push --digestfile /tmp/digest.txt "$FULL_IMAGE"
podman push "$IMAGE_NAME:latest"

export IMAGE_DIGEST
IMAGE_DIGEST=$(cat /tmp/digest.txt)
rm -f /tmp/digest.txt  # Clean up
log "Signing with Cosign (keyless)"
cosign sign --yes "$IMAGE_NAME@$IMAGE_DIGEST"
