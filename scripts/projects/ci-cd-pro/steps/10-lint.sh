#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/steps/10-lint.sh
#!/usr/bin/env bash
# If helpers are not loaded yet, load them
if ! command -v log >/dev/null 2>&1; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  # shellcheck source=../lib/helpers.sh
  source "${BASE_DIR}/lib/helpers.sh"
fi

set -euo pipefail
# ... rest of the script
