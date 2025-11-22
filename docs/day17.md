## 1. Add config.env to gitignore

# scripts/projects/ci-cd-pro/config.env
# Optional environment overrides
# IMAGE_NAME=ghcr.io/myorg/myapp
# VERSION=manual-override-123

echo "scripts/projects/ci-cd-pro/config.env" >> .gitignore

## 2. Run Test:

bash scripts/projects/ci-cd-pro/ci-cd.sh all

