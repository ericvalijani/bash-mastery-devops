# Day 9: Environment Variables & Sourcing in Bash

> **Goal**: Configure scripts via environment, share reusable configs, and validate required variables — foundation of production scripting.

## 1. Environment Variables
```bash
export APP_ENV="production"
export DB_HOST="10.0.0.10"
export DEBUG=false
```
## 2. Sourcing Files
```bash
# lib/config.sh
export DB_USER="admin"
export DB_PASS="s3cr3t"
```
### main.sh
```bash
source "./lib/config.sh"
echo "Connecting to $DB_USER@$DB_HOST"
```
## 3. Best Practices
```bash
Use .env files
Validate required vars
Use readonly for constants
Never hardcode secrets
```
## 4. Production Script: config-loader.sh
```bash
Loads .env
Validates required vars
Sets defaults
Logs config status
```
```bash
chmod +x scripts/advanced/day9/config-loader.sh

chmod +x scripts/advanced/day9/app.sh
./scripts/advanced/day9/app.sh
```

## Day 9 Summary: Env Vars & Sourcing in Bash

> Goal: Config via env, share configs, validate vars for prod scripting.

- __Env Vars__: `export APP_ENV="production"`, etc., for settings like DB_HOST, DEBUG.

- __Sourcing__: Source files (e.g., `source "./lib/config.sh"`) to load vars/secrets.

- __Best Practices__: Use .env files, validate required vars, readonly constants, avoid hardcoding secrets.

- __Prod Script__: config-loader.sh (loads .env, validates, sets defaults, logs); app.sh (uses it). Run: chmod +x & execute.
