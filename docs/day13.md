# Day 13: Mastering Unix Tools Integration

> **Goal**: Write **one-liner-killer** scripts that process millions of files in seconds using `find`, `xargs`, `awk`, `sed`, `jq`, and GNU Parallel.

## 1. Top 10 Senior-Level Patterns

| Task                        | One-liner / Pattern                                      |
|-----------------------------|----------------------------------------------------------|
| Find + exec                 | `find . -type f -name "*.log" -exec grep -H "ERROR" {} +` |
| Parallel execution          | `find . -name "*.yaml" | xargs -P 20 -I {} yamllint {}` |
| Count per directory         | `find . -type f -name "*.sh" | awk -F/ '{print $2}' | sort | uniq -c` |
| JSON aggregation            | `jq -s 'reduce .[] as $item ({}; . * $item)' *.json`     |
| Replace in 1000+ files      | `find . -name "*.conf" -exec sed -i 's/old/new/g' {} +`  |

## 2. Production Script: `cluster-auditor.sh`
- Scans 10٬000+ YAML/JSON files in <10s
- Validates with `kubeconform` + `jq`
- Finds secrets with regex
- Generates SARIF report
- Uses `xargs -P`, `find`, `parallel`

Test:

# Run in your repo root
./scripts/advanced/day13/cluster-auditor.sh

# Sample output:
# [AUDIT] Starting cluster audit...
# Found 342 manifest files
# [OK] ./k8s/deployment.yaml
# [INVALID] ./broken/config.yaml
# ./secrets.yaml:12: password: mySuperSecret123
# [
#   { "kind": "Deployment", "count": 45 },
#   { "kind": "Secret", "count": 12 }
# ]
# [SUCCESS] Audit completed in 7.842s
