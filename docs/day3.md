# Day 3 — File I/O, Redirection, Pipes, find, grep, sed, awk

Today's goal: work confidently with files, redirect output where you want it, and
filter/search text — the tools you'll reach for constantly in real DevOps work.

---

## 📁 Scripts for today

All 6 live in `scripts/advanced/day3/`.

| # | Script | Path | What it does | Try it |
|---|---|---|---|---|
| 1 | Log Analyzer | `log-analyzer.sh` | Pulls last 10 auth failures, top 10 error keywords from syslog, and disk usage of log files into one report | `bash log-analyzer.sh` |
| 2 | Backup Cleaner | `backup-cleaner.sh` | Deletes (or previews with `--dry-run`) backup archives older than N days | `bash backup-cleaner.sh --dry-run --days 30` |
| 3 | User Report | `user-report.sh` | Lists total users, which ones have a bash shell, and recent login times | `bash user-report.sh` |
| 4 | Find Large Files | `find-large-files.sh` | Finds every file over 100MB in a directory, sorted biggest first | `bash find-large-files.sh /home` |
| 5 | Nginx Top IPs | `nginx-access-top-ips.sh` | Counts and ranks the top 10 IPs hitting your nginx access log | `bash nginx-access-top-ips.sh` |
| 6 | Nginx Load Test | `loadtestnginx/loadtest.sh` | Fires real traffic at a URL with Apache Bench — useful for generating logs to feed into script #5 | `bash loadtestnginx/loadtest.sh http://localhost/ 100 10` |

> Script #6 pairs naturally with #5: run the load test against a local nginx, then
> point the Top IPs script at the access log it just generated.

---

## 1. Redirection and pipes

| Operator | Meaning | Example |
|---|---|---|
| `>` | Output → file (overwrite) | `echo "hello" > file.txt` |
| `>>` | Output → file (append) | `date >> log.txt` |
| `<` | Input ← file | `mail -s "Hi" admin < body.txt` |
| `2>` | Error → file | `ls /root 2> error.log` |
| `&>` | Output + error → file | `bash script.sh &> all.log` |
| `\|` | Pipe one command's output into the next | `ls -la \| grep ".sh"` |

---

## 2. Checking a file before you touch it

```bash
[[ -f "file" ]] && echo "exists"
[[ -d "dir"  ]] && echo "is a directory"
[[ -r "file" ]] && echo "readable"
[[ -w "file" ]] && echo "writable"
[[ -x "file" ]] && echo "executable"
```

---

## 3. Log Analyzer

**File:** `scripts/advanced/day3/log-analyzer.sh`
```bash
LOG_DIR="/var/log"
REPORT="log-report-$(date +%Y%m%d).txt"

grep "Failed password" "$LOG_DIR/auth.log" 2>/dev/null | tail -10 >> "$REPORT" \
  || echo "No auth.log found" >> "$REPORT"

grep -iE "(error|fail|warning|critical)" "$LOG_DIR/syslog" 2>/dev/null \
  | cut -d' ' -f5- | sort | uniq -c | sort -nr | head -10 >> "$REPORT" || true
```
Gracefully degrades if `auth.log`/`syslog` don't exist at those exact paths (common on
non-Debian systems) — it notes that in the report instead of crashing.

---

## 4. Backup Cleaner

**File:** `scripts/advanced/day3/backup-cleaner.sh`
```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --days) DAYS="$2"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

if $DRY_RUN; then
  find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime "+$DAYS" -print
else
  find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime "+$DAYS" -exec rm -v {} \;
fi
```
Always run with `--dry-run` first to see what *would* be deleted before actually
deleting anything.

---

## 5. User Report

**File:** `scripts/advanced/day3/user-report.sh`
```bash
grep "/bin/bash" /etc/passwd | awk -F: '{print $1, $6}' | column -t
journalctl _COMM=sshd | tail -20
```
`awk -F:` splits `/etc/passwd` on `:`, `$1` is the username, `$6` is the home directory.

---

## 6. Find Large Files

**File:** `scripts/advanced/day3/find-large-files.sh`
```bash
DIR="${1:-/home}"
find "$DIR" -type f -size "+100M" -exec du -h {} \; | sort -hr | head -20
```
Defaults to scanning `/home` if you don't pass a directory.

---

## 7. Nginx Top IPs

**File:** `scripts/advanced/day3/nginx-access-top-ips.sh`
```bash
awk '{print $1}' "$LOG" | sort | uniq -c | sort -nr | head -10 \
  | awk '{printf "%4d × %s\n", $1, $2}'
```
`$1` in an nginx access log line is always the client IP — `awk` grabs just that
column, then `sort | uniq -c | sort -nr` counts and ranks by frequency.

---

## 8. Nginx Load Test *(bonus)*

**File:** `scripts/advanced/day3/loadtestnginx/loadtest.sh`

Generates real traffic against a URL so you have something to analyze with script #7.
Requires `ab` (Apache Bench): `sudo apt install apache2-utils`
```bash
./loadtest.sh http://localhost/ 100 10
# 100 total requests, 10 at a time concurrently
```

---

## Recap

| Concept | One-liner |
|---|---|
| Redirection | `>` overwrite, `>>` append, `2>` errors, `&>` both, `\|` pipe to next command |
| File tests | `[[ -f ]]` exists, `[[ -d ]]` directory, `[[ -r/-w/-x ]]` readable/writable/executable |
| Today's scripts | Real, working DevOps tools — log analysis, backup cleanup, user auditing, disk scanning, nginx traffic analysis |

Next up: **Day 4 — Error Handling, Debugging, Traps, Signals, Logging.**
