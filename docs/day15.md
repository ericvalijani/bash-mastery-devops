# Day 15: Git-Driven Auto-Deploy (The Senior Way)

> **Goal**: Never run `kubectl apply` manually again.
> Every deployment is a git commit — 100% auditable, rollbackable, GitOps-ready.

## Features
- `deploy.sh app=v1.2.3 env=staging` → automatically commits + pushes
- Uses **deploy keys** (SSH) or **PAT** (HTTPS)
- Signs commits with GPG
- Triggers GitHub Actions
- Creates annotated tags
- Rollback with `git revert` or `git checkout`

## Real-World Use Case
```bash
# Senior DevOps does this:
./scripts/projects/auto-deploy.sh version=2.5.0 env=production
# → creates commit, tag v2.5.0, pushes → ArgoCD syncs automatically
```

---

## Just once in GitHub → Settings → Deploy keys
```bash
ssh-keygen -t ed25519 -C "auto-deploy@bot" -f ~/.ssh/auto_deploy
cat ~/.ssh/auto_deploy.pub  # → Add to repo repo

## In Script (Optional)
export GIT_SSH_COMMAND="ssh -i ~/.ssh/auto_deploy -o StrictHostKeyChecking=no"
```
## Actual Test
```bash
# Deploy to staging

./scripts/projects/auto-deploy/deploy.sh 2.1.0 staging

# Output:
# Updated staging to version 2.1.0
# Pushed commit + tag v2.1.0-staging
# ArgoCD will sync in <30s
```
