# Day 9: Environment Variables & Sourcing in Bash

> **Goal**: Configure scripts via environment, share reusable configs, and validate required variables — foundation of production scripting.

## 1. Environment Variables

export APP_ENV="production"
export DB_HOST="10.0.0.10"
export DEBUG=false

## 2. Sourcing Files

bash# lib/config.sh
export DB_USER="admin"
export DB_PASS="s3cr3t"

# main.sh
source "./lib/config.sh"
echo "Connecting to $DB_USER@$DB_HOST"

## 3. Best Practices

Use .env files
Validate required vars
Use readonly for constants
Never hardcode secrets

4. Production Script: config-loader.sh

Loads .env
Validates required vars
Sets defaults
Logs config status

chmod +x scripts/advanced/day9/config-loader.sh

chmod +x scripts/advanced/day9/app.sh
./scripts/advanced/day9/app.sh
