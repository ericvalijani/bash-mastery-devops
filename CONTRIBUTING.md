# Contributing to Bash Mastery DevOps

Thanks for your interest! This repo is designed for collaboration.

## Branching Strategy
- Use `feature/your-feature-name` for new additions.
- Base PRs on `develop`.
- Merge to `main` only after review and CI pass.

## Code Style
- Scripts: Start with `#!/bin/bash` and `set -euo pipefail`.
- Indent: 2-4 spaces.
- Lint: Run `shellcheck script.sh` before commit.
- Docs: Use Markdown, include examples and outputs.

## How to Contribute
1. Fork the repo.
2. Create feature branch: `git checkout -b feature/my-addition`
3. Commit changes: `git commit -m "Add my feature"`
4. Push: `git push origin feature/my-addition`
5. Open PR to `develop`.

For questions, open an issue.

# Contributing

## Branching
- `main`: Production
- `develop`: Integration
- `feature/dayX-*`: Daily work


## PR Flow
1. Fork → Create branch → PR to `develop`
