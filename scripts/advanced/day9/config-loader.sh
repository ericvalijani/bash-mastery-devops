#!/usr/bin/env bash
# File: scripts/advanced/day9/config-loader.sh
# Purpose: Load, validate, and export config from .env

set -euo pipefail

# === Paths ===
CONFIG_FILE="${CONFIG_FILE:-.env}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Logging ===
log() {
  local level="$1"
  shift
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
}

# === Load .env ===
if [[ ! -f "$CONFIG_FILE" ]]; then
  log "ERROR" "Config file not found: $CONFIG_FILE"
  exit 1
fi

log "INFO" "Loading config from $CONFIG_FILE"
# shellcheck source=.env
source "$CONFIG_FILE"

# === Required Variables ===
required_vars=(
  "APP_ENV"
  "DB_HOST"
  "API_KEY"
)

missing=()
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    missing+=("$var")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  log "ERROR" "Missing required variables: ${missing[*]}"
  exit 1
fi

# === Set Defaults ===
: "${DB_PORT:=5432}"
: "${DEBUG:=false}"
: "${LOG_LEVEL:=warn}"
: "${MAX_RETRIES:=5}"

# === Make readonly ===
readonly APP_ENV DB_HOST DB_PORT API_KEY DEBUG LOG_LEVEL MAX_RETRIES

# === Export all ===
export APP_ENV DB_HOST DB_PORT API_KEY DEBUG LOG_LEVEL MAX_RETRIES

log "SUCCESS" "Config loaded successfully"
log "INFO" "Environment: $APP_ENV | DB: $DB_HOST:$DB_PORT | Debug: $DEBUG"

# === Example usage ===
echo "Connecting to database at $DB_HOST:$DB_PORT..."
