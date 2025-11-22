#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/10-lint.sh
# Lint all bash scripts using shellcheck and shfmt — scoped & relative paths fixed

set -euo pipefail

# If helpers not loaded, load them
if ! command -v log >/dev/null 2>&1; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
	source "${BASE_DIR}/lib/helpers.sh"
fi

log "Running ShellCheck on ci-cd-pro scripts..."

# CRUCIAL: cd to ci-cd-pro so relative sources (e.g., ./lib/helpers.sh) resolve correctly
cd scripts/projects/ci-cd-pro

# Find relative .sh files from current dir
mapfile -t files < <(find . -type f -name "*.sh" -print 2>/dev/null)

if ((${#files[@]} == 0)); then
	log_error "No .sh files found in ci-cd-pro — this should not happen"
	exit 1
fi

# Run ShellCheck: -x follows sources (now resolvable), exclude SC2155 & SC1090
shellcheck -x --exclude=SC2155,SC1090 "${files[@]}" || {
	log_error "ShellCheck found critical issues"
	exit 1
}

log "Checking formatting with shfmt..."
shfmt -d . >/dev/null || {
	log_error "Code is not properly formatted. Run 'shfmt -w .' from ci-cd-pro dir to fix"
	exit 1
}

log "Linting passed successfully!"
