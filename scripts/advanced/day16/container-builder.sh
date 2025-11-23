#!/usr/bin/env bash
# File: scripts/advanced/day16/container-builder.sh
# Senior-level rootless container workflow

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/logging.sh"

# === Config (From .env or argument) ===
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/$(git config user.name)/myapp}"
IMAGE_TAG="${IMAGE_TAG:-$(date +%Y%m%d)-$(git rev-parse --short HEAD)}"
FULL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"
CONTAINERFILE="${1:-Containerfile}"

# === Validate tools ===
for cmd in buildah podman cosign; do
  command -v "$cmd" >/dev/null || { log_error "Required: $cmd" && exit 1; }
done

# === Build with Buildah (rootless) ===
build_image() {
  log_info "Building $FULL_IMAGE using Buildah (rootless)..."

  # ← NOW we are in repo root → "." = whole project
  cd "$(git rev-parse --show-toplevel)"

  local ctr=$(buildah from registry.hub.docker.com/library/alpine:latest)
  buildah run "$ctr" -- apk --update add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.20/main --repository http://dl-cdn.alpinelinux.org/alpine/v3.20/community bash curl jq git

  # Copy only what we need from wherever it lives
  buildah copy "$ctr" scripts/advanced/day16/entrypoint.sh      /app/entrypoint.sh
  buildah copy "$ctr" scripts/advanced/day16/healthcheck.sh   /app/healthcheck.sh
  # or copy whole scripts if you want
  # buildah copy "$ctr" scripts /app/scripts

  buildah run "$ctr" -- apk add --no-cache bash curl jq git
  buildah config --entrypoint '["/app/entrypoint.sh"]' "$ctr"
  buildah config --healthcheck 'CMD /app/healthcheck.sh' "$ctr"
  buildah commit "$ctr" "$FULL_IMAGE"
  buildah rm "$ctr"
}


# === Push with Podman ===
push_image() {
  log_info "Pushing to $FULL_IMAGE..."
  podman push "$FULL_IMAGE"
}

# === Sign with Cosign (keyless) ===
sign_image() {
  log_info "Signing image with Cosign (keyless)..."
  cosign sign --yes "$FULL_IMAGE"
}

# === Run test ===
run_test() {
  log_info "Running container test..."
  podman run --rm "$FULL_IMAGE" /app/healthcheck.sh || {
    log_error "Container failed healthcheck"
    exit 1
  }
}

# === Cleanup ===
cleanup() {
  log_info "Cleaning up local images..."
  podman rmi "$FULL_IMAGE" || true
}

trap cleanup EXIT

# === Main ===
main() {
  log_info "Starting rootless container workflow → $FULL_IMAGE"
  build_image
  run_test
  push_image
  sign_image
  log_info "SUCCESS: Secure container pipeline completed"
  echo "$FULL_IMAGE"
}

main "$@"
