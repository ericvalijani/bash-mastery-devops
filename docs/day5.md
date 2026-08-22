# Day 5 — Arrays, JSON Processing, Parallel Execution & API Integration

Today's goal: work with structured data (arrays, JSON), run many tasks at once
instead of one-by-one, and talk to real APIs — the pattern behind most real
DevOps tooling.

---

## 📁 Scripts for today

All 7 live in `scripts/advanced/day5/`.

| # | Script | Real-world use case |
|---|---|---|
| 1 | `k8s-pod-cleaner.sh` | Deletes failed/evicted pods across namespaces, in parallel, with a working `--dry-run` mode |
| 2 | `github-repo-backup.sh` | Mirrors every repo in your GitHub account, with bounded parallelism to respect API rate limits |
| 3 | `docker-image-pruner.sh` | Removes Docker images older than N days, with a working `--dry-run` mode |
| 4 | `multi-host-pinger.sh` | Pings a list of hosts in parallel, reports which are up/down |
| 5 | `json-log-parser.sh` | Parses a large JSON log file in a single pass: error count, warning count, top 5 IPs |
| 6 | `config-validator.sh` | Validates every YAML/JSON config file in a directory, in parallel |
| 7 | `cloud-cost-analyzer.sh` | Pulls 7-day AWS cost data per service and correctly sums it into one report |

> **A note on honesty:** an earlier version of this doc described these as
> "All Tested, Zero Bugs, FAANG-Level." Going through them properly, several had
> real bugs — a broken date check that misjudged image age, a cost report that
> silently overwrote data instead of summing it, and unbounded parallelism against
> a rate-limited API. All of that is fixed now (see each section below), but the
> framing was wrong before, so it's worth saying plainly rather than repeating it.

---

## 1. Array types

**Indexed array** (the classic kind):
```bash
fruits=("apple" "banana" "cherry")
echo "First fruit: ${fruits[0]}"
```

**Associative array** (Bash 4.0+, key-value pairs):
```bash
declare -A config
config[db_host]="prod-db.example.com"
config[db_port]="5432"
printf "DB: %s:%s\n" "${config[db_host]}" "${config[db_port]}"
```

---

## 2. JSON with `jq`

Install: `sudo apt install jq -y`
```bash
echo '{"name":"Ali","role":"DevOps"}' | jq '.name'
```

**Real API example:**
```bash
curl -s https://api.github.com/repos/torvalds/linux | jq '.stargazers_count'
```

---

## 3. Parallel execution

**Simple background jobs:**
```bash
for i in {1..10}; do
  sleep 1 &
done
wait  # wait for all of them to finish
```

**Bounded parallelism with `xargs -P`** — this is the safer pattern used in
today's scripts, since it caps how many run at once instead of firing them
all unbounded:
```bash
seq 1000 | xargs -n1 -P50 -I{} ping -c1 {}
```

---

## 4. Performance habits worth building now

| Do this | Instead of this | Why |
|---|---|---|
| `mapfile -t arr < file` | `while read` loop | Much faster for large files |
| `printf` | `echo` | Predictable, no surprises with special characters |
| `[[ ]]` | `[ ]` | Safer, doesn't need quoting to avoid word-splitting |
| `local` inside functions | bare variables | Prevents leaking into the rest of the script |

---

## 5. k8s-pod-cleaner.sh

**File:** `scripts/advanced/day5/k8s-pod-cleaner.sh`

Checks `kubectl`/`jq` exist first, logs everything, and correctly identifies
failed/crashed/image-pull-error pods across namespaces without false-flagging
healthy ones:
```bash
./k8s-pod-cleaner.sh --dry-run          # preview only, recommended first
MAX_PARALLEL=20 ./k8s-pod-cleaner.sh    # real cleanup, more parallel jobs
```

---

## 6. github-repo-backup.sh

**File:** `scripts/advanced/day5/github-repo-backup.sh`

Mirrors every repo you have access to, with concurrency capped at `MAX_PARALLEL=10`
instead of launching every clone at once — GitHub's API will rate-limit or reject
a burst of 100+ simultaneous authenticated requests:
```bash
ORG="ericvalijani"     # your actual GitHub username instead of "kubernetes"
TOKEN="ghp_yourtoken"  # a real PAT from github.com/settings/tokens
```
Uses `/user/repos` (the authenticated-user endpoint) rather than `/orgs/$ORG/repos`
— the latter only works for real GitHub Organizations, not personal accounts.

```bash
DRY_RUN=true ./github-repo-backup.sh   # preview only, skips the actual git clone
./github-repo-backup.sh                # real backup
```

---

## 7. docker-image-pruner.sh

**File:** `scripts/advanced/day5/docker-image-pruner.sh`

Removes images older than `MAX_DAYS` (default 30). Now reads `.Created`
(always present on every image) instead of `.Metadata.LastTagTime` (usually
missing, which was silently making every image look decades old):
```bash
DRY_RUN=true ./docker-image-pruner.sh   # preview only, recommended first
./docker-image-pruner.sh                # actually removes images
```

---

## 8. multi-host-pinger.sh

**File:** `scripts/advanced/day5/multi-host-pinger.sh`

```bash
./multi-host-pinger.sh /path/to/hosts.txt
```
Now checks the hosts file actually exists before starting, instead of failing
confusingly deep inside `xargs`.

---

## 9. json-log-parser.sh

**File:** `scripts/advanced/day5/json-log-parser.sh`

Reads the last 100,000 lines of a JSON log and reports error count, warning
count, and the top 5 IPs — in a single `jq` pass instead of three separate
ones over the same data:
```bash
jq -s '
  {
    errors: ([.[] | select(.level=="ERROR")] | length),
    warnings: ([.[] | select(.level=="WARN")] | length),
    top_5_ips: ([.[].ip] | group_by(.) | map({ip: .[0], count: length}) | sort_by(-.count) | .[0:5])
  }'
```

---

## 10. config-validator.sh

**File:** `scripts/advanced/day5/config-validator.sh`

```bash
./config-validator.sh
```
Validates every `.yaml`/`.yml` file in a directory in parallel with `xargs -P50`,
reporting `OK` or `INVALID` per file.

---

## 11. cloud-cost-analyzer.sh

**File:** `scripts/advanced/day5/cloud-cost-analyzer.sh`

Pulls 7-day AWS cost data for 4 services in parallel, then **correctly sums**
cost per service across all days. The original version used `jq -s 'add'`,
which shallow-merges whole response objects rather than actually summing
anything — meaning 3 of the 4 services' data would silently vanish, overwritten
by the last one processed. Fixed:
```bash
jq -s '
  [.[] | .ResultsByTime[]?.Groups[]? | {service: .Keys[0], cost: (.Metrics.UnblendedCost.Amount | tonumber)}]
  | group_by(.service)
  | map({service: .[0].service, total_cost: (map(.cost) | add)})
'
```

**Testing it locally** — the script needs a real AWS account with Cost Explorer
access, which most people don't have lying around. Instead of skipping it, mock
the `aws` command itself with a fake one that returns realistic Cost Explorer
JSON, and put it first in `PATH` so the script finds it instead of the real thing:
```bash
mkdir -p /tmp/aws-mock
cat > /tmp/aws-mock/aws << 'EOF'
#!/bin/bash
# mock aws ce get-cost-and-usage
cat << 'JSON'
{
  "ResultsByTime": [{
    "TimePeriod": {"Start": "2026-08-01", "End": "2026-08-08"},
    "Groups": [{
      "Keys": ["Amazon EC2"],
      "Metrics": {"UnblendedCost": {"Amount": "42.50", "Unit": "USD"}}
    }]
  }]
}
JSON
EOF
chmod +x /tmp/aws-mock/aws
export PATH="/tmp/aws-mock:$PATH"

bash cloud-cost-analyzer.sh
```
The script queries 4 services in parallel (`AmazonEC2`, `AmazonS3`, `AWSLambda`,
`AmazonRDS`), and since this mock always returns the same $42.50 no matter which
service is asked, the correct aggregated report should show a single combined
entry: `42.50 × 4 = 170`. That's exactly what a real run produces —
`[{"service": "Amazon EC2", "total_cost": 170}]` — confirming the `jq` grouping
and summing logic is working correctly, not just producing a plausible-looking
number by coincidence. Clean up afterward with `rm -rf /tmp/aws-mock`, and note
the real script will show 4 separate services once pointed at real AWS data,
not just one — this mock happens to return identical data for all of them.

---

## Recap

| Concept | One-liner |
|---|---|
| Arrays | `arr=(a b c)` indexed, `declare -A arr` for key-value |
| JSON | `jq '.field'` to extract, `jq -s '...'` to combine multiple files |
| Parallel | `cmd &` + `wait` for simple cases, `xargs -P N` when you need a concurrency *limit* |
| Safety | Always add a `--dry-run`/`DRY_RUN=true` path before anything destructive runs for real |

Next up: **Day 6 — Modular Libraries, BATS Unit Testing, Code Coverage, Pre-commit.**
