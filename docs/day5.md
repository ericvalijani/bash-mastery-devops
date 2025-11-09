# Day 5: Arrays, Associative Arrays, JSON, Parallel Execution, Performance, jq/curl

> **هدف**: اسکریپت‌هایی که **۱۰٬۰۰۰ خط JSON** رو در **ثانیه** پردازش می‌کنن، **همزمان** ۱۰۰ تا کار انجام می‌دن، و با **APIهای واقعی** کار می‌کنن.

## 1. انواع آرایه در Bash
```bash
# Indexed Array
fruits=("apple" "banana" "cherry")

# Associative Array (Bash 4+)
declare -A config
config[db_host]="prod-db.example.com"
config[db_port]="5432"

## 2. JSON Handling with Industry Standards

# Installation: sudo apt install jq
echo '{"name":"ali","age":30}' | jq '.name'
curl -s https://api.github.com/repos/torvalds/linux | jq '.stargazers_count'

# wait with & and #
for i in {1..10}; do
  sleep 1 &   # executing parallel
done
wait        # wait to finish

## 4. Performance Tips
mapfile # To read files quickly
read -r # Without backslash escape
printf  # better than echo
[[]] better than []


## Some usefull scripts

| # | script | operation | speed | 
|---|--------|-------|------|
| 1 | k8s-pod-cleaner.sh | 1000 pod in 5 second | parallel + kubectl |
| 2 | github-repo-backup.sh | 200 simultaneous repos | GitHub API + parallel |
| 3 | docker-image-pruner.sh | 10.000 Image | docker + background |
| 4 | multi-host-pinger.sh | 1000 servers in 2 second | xargs -P 200 |
| 5 | json-log-parser.sh | 1 million HSON line | mapfile + jq |
| 6 | config-validator.sh | 1000 YAML File | parallel + yq |
| 7 | cloud-cost-analyzer.sh | 7-day AWS cost | aws cli + parallel |
