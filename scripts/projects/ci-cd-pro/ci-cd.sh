#!/usr/bin/env bash
set -euo pipefail

readonly BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/lib/log.sh"

export IMAGE_NAME="${IMAGE_NAME:-ghcr.io/$(git config user.name)/bash-mastery-devops}"
export TAG="${TAG:-$(git rev-parse --short HEAD)}"
export FULL_IMAGE="$IMAGE_NAME:$TAG"

log "Starting CI/CD Framework – $FULL_IMAGE"

for step in "$BASE_DIR"/steps/[0-9][0-9]-*.sh; do
  [[ -f "$step" ]] || continue
  step_name="$(basename "$step")"
  log "Running $step_name"
  bash "$step" || die "Step $step_name failed"
done

log "Pipeline completed successfully!"
log "Published: $FULL_IMAGE"
