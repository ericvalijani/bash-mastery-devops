#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"
log "Promoting to production via GitOps"
bash scripts/projects/auto-deploy/deploy.sh "$TAG" production
