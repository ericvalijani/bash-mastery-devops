# Day 9: Environment Variables & Sourcing in Bash

> **Goal**: Configure scripts via environment, share reusable configs, and validate required variables — foundation of production scripting.

## 1. Environment Variables

export APP_ENV="production"
export DB_HOST="10.0.0.10"
export DEBUG=false

## 2. Sourcing Files

# lib/config.sh
export DB_USER="admin"
export DB_PASS="s3cr3t"

# main.sh
source "./lib/config.sh"
echo "Connecting to $DB_USER@$DB_HOST"

## 3. Best Practices

Loads .env
Validates required vars
Sets defaults
Logs config status

---

## Files : Step 3

### 1. `.env` ( In the root of repo)


vim .env

# .env — Never commit secrets!
APP_ENV=development
DB_HOST=localhost
DB_PORT=5432
API_KEY=dev-key-123
DEBUG=true
LOG_LEVEL=info
MAX_RETRIES=3

## 4. Production Script: config-loader.sh

## Usage

# 1. Load config
./scripts/advanced/day9/config-loader.sh

# 2. Use in another script
cat > scripts/advanced/day9/app.sh << 'EOF'
#!/usr/bin/env bash
source ./scripts/advanced/day9/config-loader.sh
echo "API Call with key: $API_KEY"
EOF
chmod +x scripts/advanced/day9/app.sh
./scripts/advanced/day9/app.sh
