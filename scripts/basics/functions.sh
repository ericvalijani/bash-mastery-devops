#!/bin/bash
set -euo pipefail

greet() {
  local name="$1"
  local timestamp
  timestamp=$(date +%F_%H:%M:%S)
  echo "[$timestamp] Hello, $name! Welcome to Bash mastery."
}
greet "DevOps Engineer"

add() {
  local a=$1
  local b=$2
  echo $((a + b))
}
result=$(add 15 27)
echo "15 + 27 = $result"

backup() {
  local src="${1:-/home}"
  local dest="${2:-/backup}"
  echo "Backing up $src → $dest at $(date)"
}
backup                  # uses defaults
backup /etc /var/backup # custom paths

get_system_info() {
  local info=()
  info+=("user:$(whoami)")
  info+=("host:$(hostname)")
  info+=("uptime:$(uptime -p)")
  SYSTEM_INFO=("${info[@]}") # global array
}
get_system_info
echo "System info collected:" "${SYSTEM_INFO[@]}"