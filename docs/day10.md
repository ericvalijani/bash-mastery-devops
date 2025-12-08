# Day 10: Modular Scripting & Reusable Libraries

> **Goal**: Break scripts into reusable modules — the foundation of maintainable, senior-level Bash code.

## 1. Library Structure
```bash
/lib/
├── logging.sh
├── retry.sh
└── utils.sh
```

## 2. Sourcing Libraries
``` bash
readonly SCRIPT_DIR="$$ (cd " $$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"
```
## 3. Production Libraries
```bash
logging.sh: Structured logs
retry.sh: Exponential backoff
utils.sh: Common helpers
```
---

## Libraries: Level 3 — `lib/`
```bash
mkdir -p lib

lib/logging.sh

vim lib/logging.sh
vim lib/retry.sh
vim lib/utils.sh
```
## Test Scripts:

### Set .env
```bash
export API_TOKEN="fake"
export DEBUG=true

./scripts/advanced/day10/deploy.sh
```

## Day 10 Summary: Modular Scripting & Reusable Libraries

> Goal: Reusable modules for maintainable senior Bash code.

- __Lib Structure__: /lib/ (logging.sh, retry.sh, utils.sh).

- __Sourcing__: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`; source "$SCRIPT_DIR/../lib/logging.sh".

- __Prod Libs__: logging (structured), retry (exp backoff), utils (helpers).

- __Setup__: mkdir -p lib; edit lib/*.sh.

- __Test__: export API_TOKEN="fake" DEBUG=true; run deploy.sh.
