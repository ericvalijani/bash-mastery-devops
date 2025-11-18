#!/usr/bin/env bash
# scripts/projects/auto-deploy/deploy.sh
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/logging.sh"

# === Config (From .env or argument) ===
VERSION="${1:-}"
ENV="${2:-staging}"
REPO_DIR="$(git rev-parse --show-toplevel)"
MANIFEST_DIR="$REPO_DIR/k8s/overlays/$ENV"

# === Validation ===
[[ -z "$VERSION" ]] && log_error "Usage: $0 <version> [env]" && exit 1
[[ ! -d "$MANIFEST_DIR" ]] && log_error "Env $ENV not found!" && exit 1

# === Git user config (To commit) ===
git config user.name "Auto Deploy Bot"
git config user.email "deploy@bot.example.com"

# === Update kustomization.yaml with new version ===
update_version() {
  local kustomization="$MANIFEST_DIR/kustomization.yaml"
  if grep -q "newTag:" "$kustomization"; then
    sed -i "s/newTag:.*/newTag: $VERSION/" "$kustomization"
  else
    yq e ".images += [{\"name\": \"myapp\", \"newTag\": \"$VERSION\"}]" -i "$kustomization"
  fi
  log_info "Updated $ENV to version $VERSION"
}

# === Commit & Tag ===
commit_and_push() {
  git add "$MANIFEST_DIR/kustomization.yaml"
  
  local commit_msg="chore(deploy): release $VERSION to $ENV"
  git commit -m "$commit_msg" --author="Auto Deploy Bot <deploy@bot.example.com>"

  # Sign commit (If you have GPG Key)
  if [[ -n "${GPG_KEY_ID:-}" ]]; then
    git commit --amend --gpg-sign="$GPG_KEY_ID" -m "$commit_msg"
  fi

  # Create annotated tag
  git tag -a "v$VERSION-$ENV" -m "Deploy $VERSION to $ENV at $(date)"
  
  # Push
  git push origin develop
  git push origin "v$VERSION-$ENV"

  log_info "Pushed commit + tag v$VERSION-$ENV"
  log_info "ArgoCD will sync in <30s"
}

# === Main ===
main() {
  log_info "Starting auto-deploy v$VERSION → $ENV"
  cd "$REPO_DIR"
  update_version
  commit_and_push
  echo "Deployment triggered: v$VERSION → $ENV"
  echo "Monitor: https://github.com/$(git remote get-url origin | sed 's|.git||' | sed 's|:*///*|://|')/actions"
}

main
