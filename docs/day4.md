# Day 4: Error Handling, Debugging, Traps, Signals, Logging

> Goal: Scripts that never crash, always log, and always are debuggable.

## 1. Best Bash settings (always at the beginning of the script)
```bash
#!/bin/bash
set -euo pipefail # error → exit, undefined variable → error, pipe fail → error
IFS=$'\n\t' # prevent incorrect word splitting
```
## 2. Trap
| Signal | Code | Usage|
|---|--------|---------|
| EXIT | 0 | always executes |
| ERR | - | executes on every error |
| INT | 2 | CTRL + C |
| TERM | 15 | KILL |

## 3. Logging
```bash
log() {
  local level="$1"
  shift
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a /var/log/bash-script.log
}

log "INFO" "Starting Script"
```
## 4. Debugging
```bash
set -x → display each command before execution
set +x → turn off
bash -x script.sh → run with debug
BASH_XTRACEFD=2 → debug to stderr
```

## 5. Real Projects (Production-Ready) 

| # | Script | Features|
|---|--------|---------|
| 1 | `robust-backup.sh` | lock + trap + rollback link |
| 2 | `deploy-with-rollback.sh` | zero-downtime + auto rollback |
| 3 | `health-check-monitor.sh` | alert + loop + logging |
| 4 | `secure-config-loader.sh` | validation + yq + safe defaults |
| 5 | `cleanup-with-lock.sh` | mkdir lock + prevent race |
| 6 | `database-backup-restore.sh` | verify + latest symlink |

## Day 4 Summary: Error Handling, Debugging, Traps, Signals, Logging

> Goal: Unbreakable scripts with logging & debug.

- __Settings__: `#!/bin/bash`; `set -euo pipefail` (err handling); `IFS=$'\n\t'` (safe splitting).

- __Trap__: Signals: EXIT (0, always), ERR (on err), INT (2, Ctrl+C), TERM (15, kill). For cleanup.

- __Logging__: log func with level, timestamp, tee to file (e.g., `log "INFO" "Msg"`).

- __Debugging__: `set -x` (trace on), `+x` (off); `bash -x script.sh`; `BASH_XTRACEFD=2` (to stderr).

- __Projects__: Production scripts like robust-backup.sh (lock+trap+rollback), deploy-with-rollback.sh (zero-downtime+rollback), health-check-monitor.sh (alert+loop+log), secure-config-loader.sh (validate+yq+defaults), cleanup-with-lock.sh (lock anti-race), database-backup-restore.sh (verify+symlink).
