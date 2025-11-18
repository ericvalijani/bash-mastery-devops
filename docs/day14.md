# Day 14: Mid-Project — Distributed Log Analyzer Pro
> **Production-ready log analyzer** used by senior DevOps engineers at scale.

## Features
- Processes **10M+ lines in <5s**
- Supports local files, remote SSH, systemd journals
- Outputs **structured JSON** + **Prometheus metrics**
- Parallel processing with `xargs -P`
- Secure: no shell injection, secrets masked
- Modular: uses all previous days (lib/, security, performance)

## Usage
```bash
./scripts/projects/log-analyzer-pro.sh /var/log/*.log
# → Generates /tmp/log-report.json + prometheus_metrics.txt

Prometheus Dashboard Ready
Exposes metrics like:

log_errors_total{service="nginx"} 1243
log_warnings_total{service="app"} 567
log_lines_processed_total 10485760


---

## level 3: Final Project Structure: 

```bash
scripts/
└── projects/
    └── log-analyzer-pro/
        ├── main.sh                 ← Entry Point
        ├── collector.sh            ← Log Gathering (Local / Remote)
        ├── parser.sh               ← Quick Process
        ├── reporter.sh             ← JSON + Prometheus Output
        └── config.env              ← Settings (gitignored)


## Add env file to gitignore

echo "scripts/projects/log-analyzer-pro/config.env" >> .gitignore

# Finel Test:

# Test log generation
for i in {1..20}; do
  for j in {1..500000}; do
    echo "[$(shuf -i 0-2 -n1 | { read n; case $n in 0) echo ERROR;; 1) echo WARN;; *) echo INFO;; esac })] Test log $j from app$i" >> "/tmp/app$i.log"
  done
done

# Run
time ./scripts/projects/log-analyzer-pro/main.sh /tmp/*.log
# → Typically < 4.8 seconds

