#!/bin/bash
set -euo pipefail

prune_image() {
  local img="$1"
  local last_used=$(docker inspect "$img" | jq -r '.[0].Metadata.LastTagTime // "unknown"')
  local days_old=$(( ( $(date +%s) - $(date -d "$last_used" +%s 2>/dev/null || echo 0) ) / 86400 ))

  if [[ $days_old -gt 30 ]]; then
    echo "Remove old Image: $img ($days_old day)"
    docker rmi "$img" --force &
  fi
}

images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>")
for img in $images; do
  prune_image "$img"
done
wait
docker image prune -f >/dev/null
echo "Finished pruning Images. "
