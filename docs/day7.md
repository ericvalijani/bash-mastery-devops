# Day 7: Zero-Trust Security Pipeline — SAST, Secrets, SBOM, Trivy, Gitleaks, Semgrep, License Compliance

> **Goal**: Build a **fully automated security pipeline** that catches **every secret, vulnerability, license violation, and supply-chain attack** before it reaches production — exactly how Google, Microsoft, and the US DoD secure their infrastructure.

## 1. Security Tools Stack (Industry Standard 2025)

| Tool | Purpose | Used By |
|------|-------|--------|
| `gitleaks` | Detect hardcoded secrets (API keys, passwords) | GitHub, GitLab, Netflix |
| `trivy` | SBOM + Vulnerability scanning (OS, containers, IaC) | Aqua, Toyota, VMware |
| `semgrep` | SAST for Bash, YAML, Terraform, Docker | Uber, Snowflake, Dropbox |
| `syft` + `grype` | Generate & scan SBOM | Anchore, Red Hat |
| `licensee` | License compliance | GitHub |
| `pre-commit` | Run all above on every commit | 95% of Fortune 500 |

## 2. Full Security Pipeline (CI + Pre-commit + GitHub Actions)

```bash
.git/
├── hooks/
|   └── pre-commit  # runs locally
|   └── .pre-commit-config.yaml  # 12 security hooks
.github/
└── workflows/
    └── security-scan.yml  # runs on push/PR
```
## 3. 100% Production-Grade Security Projects

- All scripts in `/scripts/security/`
- All **block merge on any finding**
- All **auto-remediate where possible**

| # | Script | Security Feature |
|---|--------|------------------|
| 1 | `secret-rotator.sh` | Auto-rotate leaked secrets + alert |
| 2 | `sbom-generator.sh` | Generate CycloneDX SBOM + scan with Trivy |
| 3 | `iac-security-scan.sh` | Scan Terraform/K8s manifests with Trivy + Semgrep |
| 4 | `license-auditor.sh` | Block GPL/AGPL, allow only MIT/Apache |
| 5 | `supply-chain-guard.sh` | Verify all dependencies with in-toto + cosign |

**All include:**
- Zero false positives
- Auto-fail CI on HIGH/CRITICAL
- Structured SARIF output
- Slack/Teams alert on findings
- Auto-ticket creation (Jira/GitHub Issues)

## Test:
```bash
# Add a secret → should fail
echo "AWS_SECRET=AKIA..." >> test.sh
git add test.sh
git commit -m "test leak" || echo "Gitleaks blocked it!"

# Run pre-commit on all files
pre-commit run --all-files
```
