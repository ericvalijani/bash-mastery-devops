#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Finding the Absolute Path of the current script
source "$SCRIPT_DIR/../../../lib/logging.sh"
source "$SCRIPT_DIR/../../../lib/retry.sh"
source "$SCRIPT_DIR/../../../lib/utils.sh"

require_command curl jq

log_info "Starting deployment..."

deploy_function() {
  curl -f -X POST "https://api.example.com/deploy" -H "Authorization: Bearer $API_TOKEN" || return 1
}

retry 5 3 deploy_function

log_info "Deployment successful!"
