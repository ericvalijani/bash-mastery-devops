#!/bin/bash
set -euo pipefail

ORG="kubernetes"
TOKEN="ghp_xxx"  # Replace it.
BACKUP_DIR="/backup/github/$ORG"

backup_repo() {
  local repo="$1"
  local url="https://api.github.com/repos/$ORG/$repo"
  local clone_url=$(curl -sH "Authorization: token $TOKEN" "$url" | jq -r .clone_url)
  local dir="$BACKUP_DIR/$repo"

  [[ -d "$dir" ]] && return
  echo "Backup $repo ..."
  git clone --mirror "$clone_url" "$dir" >/dev/null 2>&1 &
}

mkdir -p "$BACKUP_DIR"
repos=$(curl -sH "Authorization: token $TOKEN" "https://api.github.com/orgs/$ORG/repos?per_page=100" | jq -r '.[].name')

for repo in $repos; do
  backup_repo "$repo"
done
wait
echo "Completed the backup of all $ORG repos"
