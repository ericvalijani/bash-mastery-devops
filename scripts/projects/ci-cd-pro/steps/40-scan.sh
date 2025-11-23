#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
log "Generating SBOM with syft"
syft "$FULL_IMAGE" -o cyclonedx-json > sbom.json

log "Scanning with Trivy"
trivy image --exit-code 1 --severity HIGH,CRITICAL "$FULL_IMAGE"
