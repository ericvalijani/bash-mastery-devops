# Day 10: Modular Scripting & Reusable Libraries

> **Goal**: Break scripts into reusable modules — the foundation of maintainable, senior-level Bash code.

## 1. Library Structure

/lib/
├── logging.sh
├── retry.sh
└── utils.sh


## 2. Sourcing Libraries
# bash
readonly SCRIPT_DIR="$$ (cd " $$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

## 3. Production Libraries

logging.sh: Structured logs
retry.sh: Exponential backoff
utils.sh: Common helpers

---

## Libraries: Level 3 — `lib/`

mkdir -p lib

lib/logging.sh

vim lib/logging.sh
vim lib/retry.sh
vim lib/utils.sh

## Test Scripts:

# Set env
export API_TOKEN="fake"
export DEBUG=true

./scripts/advanced/day10/deploy.sh
