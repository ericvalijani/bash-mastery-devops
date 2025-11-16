#!/usr/bin/env bash
# File: scripts/advanced/day11/secure-deploy.sh
# Purpose: Secure deployment script with input validation, secret masking, and injection prevention

set -euo pipefail
IFS=$'\n\t'

# === Security: Fail on unset vars, pipe errors ===
shopt -s inherit_errexit 2>/dev/null || true

# === Paths ===
readonly SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"  # از روز ۱۰
source "$SCRIPT_DIR/../../.env" 2>/dev/null || true

# === Logging with Secret Masking ===
log() {
  local level="$1"
  shift
  local message="$*"
  # Mask known secrets
  for secret in "$API_KEY" "$DB_PASS" "$SSH_KEY"; do
    [[ -n "${secret:-}" ]] && message="${message//${secret}/***MASKED***}"
  done
  printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$level" "$message"
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@" >&2; }

# === Input Validation Functions ===
validate_env() {
  local env="$1"
  if [[ ! "$env" =~ ^(development|staging|production)$ ]]; then
    log_error "Invalid APP_ENV: $env (must be development/staging/production)"
    return 1
  fi
}

validate_host() {
  local host="$1"
  if ! [[ "$host" =~ ^[a-zA-Z0-9.-]+$ ]] || [[ "$host" == *..* ]]; then
    log_error "Invalid host: $host"
    return 1
  fi
}

validate_port() {
  local port="$1"
  if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    log_error "Invalid port: $port"
    return 1
  fi
}

# === Required Config ===
required_vars=(APP_ENV TARGET_HOST TARGET_PORT API_KEY)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    log_error "Required variable not set: $var"
    exit 1
  fi
done

# === Validate Inputs ===
validate_env "$APP_ENV"
validate_host "$TARGET_HOST"
validate_port "$TARGET_PORT"

# === Mask Secrets in Environment ===
export API_KEY  # Will be masked in logs

# === Secure Command Execution (No eval, No unquoted vars) ===
deploy() {
  local url="https://$TARGET_HOST:$TARGET_PORT/api/deploy"
  log_info "Deploying to $url in $APP_ENV mode..."

  # Use printf + curl with --fail
  if ! response=$(printf '{ "env": "%s", "key": "%s" }' "$APP_ENV" "$API_KEY" |
                  curl -sS -X POST -H "Content-Type: application/json" \
                       -d @- --fail "$url" 2>&1); then
    log_error "Deploy failed: $response"
    return 1
  fi

  log_info "Deploy successful: $response"
}

# === Run with retry (from lib/retry.sh) ===
source "$SCRIPT_DIR/../../lib/retry.sh"
retry 3 5 deploy

log_info "Secure deployment completed."
