#!/usr/bin/env bash
# File: scripts/advanced/day13/cluster-auditor.sh
# Purpose: Ultra-fast K8s manifest audit across thousands of files

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="/tmp/cluster-audit-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REPORT_DIR"

# === Install tools if missing ===
install_tools() {
  command -v kubeconform >/dev/null || { echo "Installing kubeconform..."; curl -sSL https://git.io/kubeconform | sh; }
  command -v parallel >/dev/null || sudo apt-get install -y parallel
}

# === Find all manifests ===
find_manifests() {
  find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
  ! -path "*/.git/*" \
  ! -path "./.github/workflows/*" \
  ! -path "./charts/*/Chart.yaml" \
  ! -path "./charts/*/values*.yaml" \
  ! -path "./argocd/overlays/*/values*.yaml" \
  ! -path "./*/kustomization.yaml" \
  ! -name ".pre-commit-config.yaml"
}

# === Validate with kubeconform (parallel) ===
validate_manifest() {
  local file="$1"
  if kubeconform -ignore-missing-schemas -exit-on-error "$file" >/dev/null 2>&1; then
    echo "[OK] $file"
  else
    echo "[INVALID] $file" >&2
    echo "$file" >> "$REPORT_DIR/invalid.txt"
  fi
}

export REPORT_DIR
export -f validate_manifest

# === Find potential secrets ===
find_secrets() {
  grep -rEI \
    -e "password|passwd|secret|token|key|private" \
    -e "AKIA[0-9A-Z]{16}" \
    -e "ghp_[A-Za-z0-9]{36}" \
    . --include="*.yaml" --include="*.yml" --include="*.env" | \
    tee "$REPORT_DIR/secrets-found.txt"
}

# === JSON aggregation with jq ===
aggregate_resources() {
  find . -name "*.json" -exec cat {} + | \
    jq -s 'group_by(.kind) | map({kind: .[0].kind, count: length})'
}

# === Main execution ===
main() {
  echo "[AUDIT] Starting cluster audit at $(date)"
  local start=$(date +%s.%N)

  echo "[1/4] Finding manifests..."
  mapfile -t files < <(find_manifests)
  echo "Found ${#files[@]} manifest files"

  echo "[2/4] Validating with kubeconform (parallel)..."
  printf '%s\0' "${files[@]}" | xargs -0 -P 20 -I {} bash -c 'validate_manifest "{}"'

  echo "[3/4] Scanning for secrets..."
  find_secrets || true

  echo "[4/4] Aggregating resource counts..."
  aggregate_resources | tee "$REPORT_DIR/resource-summary.json"

  local end=$(date +%s.%N)
  printf '[SUCCESS] Audit completed in %.3fs\n' "$(bc <<< "$end - $start")"
  echo "Reports in: $REPORT_DIR"
}

main
