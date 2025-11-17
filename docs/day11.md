# Day 11: Security Best Practices in Bash Scripting

> **Goal**: Write **zero-vulnerability** Bash scripts that resist injection, protect secrets, and follow **least privilege** — mandatory for senior-level automation.

## 1. Core Principles
| Principle | Implementation |
|---------|----------------|
| **Fail Fast** | `set -euo pipefail` |
| **Validate Input** | Whitelists, regex, bounds |
| **No Secrets in Code** | Use env vars or files |
| **Least Privilege** | Run as non-root, `sudo` only when needed |
| **Quote Everything** | `"$VAR"`, `${VAR@Q}` |

## 2. Shell Injection Prevention
```bash
# DANGEROUS
eval "$USER_INPUT"

# SAFE
printf '%s' "$$ USER_INPUT" | grep -E '^[a-zA-Z0-9_-]+ $$'

## 3. Secret Management
- Never hardcode
- Use .env + source
- Mask in logs
- Use read -s for passwords

## 4. Production Script: secure-deploy.sh
- Validates all inputs
- Masks secrets in logs
- Prevents injection
- Runs with minimal privileges
- Uses sudo only for specific commands

never commit env file:

APP_ENV=staging
TARGET_HOST=api.example.com
TARGET_PORT=443
API_KEY=sk-secure-test-1234567890
DB_PASS=supersecret
SSH_KEY=-----BEGIN RSA PRIVATE KEY-----...

bash:
echo ".env" >> .gitignore
echo "*.secret" >> .gitignore

Then Test example below:

# 1. Normal test
export APP_ENV=production
export TARGET_HOST=deploy.prod.example.com
export TARGET_PORT=8443
export API_KEY=fake-key-123

./scripts/advanced/day11/secure-deploy.sh

# 2. Injection test
export TARGET_HOST="evil.com; rm -rf /"
./scripts/advanced/day11/secure-deploy.sh  # should fail

# 3. Missing var test
unset API_KEY
./scripts/advanced/day11/secure-deploy.sh  # should fail


