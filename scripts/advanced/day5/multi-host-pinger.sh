#!/bin/bash
set -euo pipefail

HOSTS_FILE="${1:-/etc/hosts-list.txt}"
THREADS=200

ping_host() {
  local host="$1"
  if ping -c 1 -W 1 "$host" &>/dev/null; then
    echo "UP: $host"
  else
    echo "DOWN: $host" >&2
  fi
}

export -f ping_host
xargs -P "$THREADS" -I {} bash -c 'ping_host "{}"' < "$HOSTS_FILE"
