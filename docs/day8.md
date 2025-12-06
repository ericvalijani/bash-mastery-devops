# Day 8: Process Management & Signals in Bash

> **Goal**: Master how Bash handles processes, background jobs, and signals — essential for reliable automation scripts.

## 1. Background Execution
```bash
sleep 10 &          # Run in background
echo $!             # PID of last background process
wait $!             # Wait for it
```
## 2. Job Control
```bash
sleep 100 &
jobs                # List jobs
fg %1               # Bring to foreground
bg %1               # Send to background
```
## 3. Signals
```bash
Signal	Code	Use
SIGTERM	15	Graceful shutdown
SIGKILL	9	Force kill
SIGINT	2	Ctrl+C
Bash
kill -15 $PID       # Graceful
kill -9 $PID        # Force
```
## 4. Trap — Handle Signals
```bash
cleanup() { echo "Cleaning up..."; rm -f /tmp/*.tmp; }
trap cleanup EXIT SIGTERM SIGINT
```
## 5. Production Script Example
```bash
#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date)] $*"; }

# Run cleanup on any exit
trap 'log "Script terminated. Running cleanup."; rm -f /tmp/myapp.lock' EXIT

log "Starting long-running task..."
sleep 3600 &
PID=$!
log "Background job PID: $PID"

wait $PID
log "Task completed."
```

## Test
```bash
# Run in background
./scripts/advanced/day8/monitor.sh $$ &
sleep 20
kill $!  # Send SIGTERM
```
