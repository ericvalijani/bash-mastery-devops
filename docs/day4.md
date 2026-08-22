# Day 4 — Error Handling, Debugging, Traps, Signals, Logging

Today's goal: scripts that never crash silently, always log what happened, and are
easy to debug when something does go wrong.

---

## 📁 Scripts for today

All 6 live in `scripts/advanced/day4/`.

| # | Script | Path | What it does |
|---|---|---|---|
| 1 | Robust Backup | `robust-backup.sh` | Backs up `/home`, with a lock file to prevent overlapping runs and a rollback symlink to the last good backup |
| 2 | Deploy with Rollback | `deploy-with-rollback.sh` | Zero-downtime deploy via symlink swap — auto-rolls-back if anything fails partway through |
| 3 | Health Check Monitor | `health-check-monitor.sh` | ⚠️ Runs forever by default — checks a service every 30s, emails an alert if it's down. Use `--once` to test without waiting |
| 4 | Secure Config Loader | `secure-config-loader.sh` | Validates a YAML config exists and parses before trusting any value from it |
| 5 | Cleanup with Lock | `cleanup-with-lock.sh` | Deletes old temp files, using `mkdir` as an atomic lock to prevent two copies running at once |
| 6 | Database Backup & Restore | `database-backup-restore.sh` | Dumps a Postgres DB, verifies the backup isn't corrupted before trusting it, symlinks `-latest` |

> ⚠️ **Script #3 defaults to running forever, as a daemon.** Run it plain and it'll
> look "stuck" until you `Ctrl+C` it — that's intentional, not a bug. Use
> `./health-check-monitor.sh --once` to test it and get an immediate result instead.
> For real background use, see Section 7 for `nohup`/systemd options.

---

## 1. The settings every script here starts with

```bash
#!/bin/bash
set -euo pipefail   # exit on error, exit on unset variable, catch pipe failures
IFS=$'\n\t'         # prevents Bash from word-splitting on spaces unexpectedly
```

---

## 2. Trap — running code when your script exits

| Signal | Number | Fires when |
|---|---|---|
| `EXIT` | 0 | Always — success, failure, or `Ctrl+C`. The one you'll use most, for cleanup. |
| `ERR` | – | Any command fails (with `set -e` active) |
| `INT` | 2 | Someone hits `Ctrl+C` |
| `TERM` | 15 | Someone/something sends a kill signal |

```bash
trap cleanup EXIT
trap 'log "ERROR" "Failed at line $LINENO"; exit 1' ERR
```

---

## 3. Logging

```bash
log() {
  local level="$1"
  shift
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a /var/log/bash-script.log
}

log "INFO" "Starting Script"
```

> The 6 scripts below each write their own simpler version of this — some hardcode
> a fixed tag like `[DEPLOY]` instead of a dynamic level. Both are valid patterns;
> just don't expect every script to match this exact function.

---

## 4. Debugging — actual commands, not pseudo-code

| Command | What it does |
|---|---|
| `set -x` | Print every command before it runs |
| `set +x` | Turn that back off |
| `bash -x script.sh` | Run a whole script with debug tracing on, without editing it |
| `BASH_XTRACEFD=2` | Send that debug trace to stderr instead of stdout, so it doesn't mix with real output |

---

## 5. Robust Backup

**File:** `scripts/advanced/day4/robust-backup.sh`
- Lock file at `/tmp/robust-backup.lock` — refuses to run if one already exists (prevents two backups running at once)
- `trap cleanup EXIT` removes the lock no matter how the script ends
- After a successful backup, symlinks `/backup/last-successful` → the new backup — an easy, always-current rollback target
```bash
if [[ -f "$LOCK" ]]; then
  log "ERROR" "Script is already running (lock file exists)"
  exit 1
fi
touch "$LOCK"
trap cleanup EXIT

rsync -av --delete "$SRC/" "$DEST/"
```

---

## 6. Deploy with Rollback

**File:** `scripts/advanced/day4/deploy-with-rollback.sh`
- Deploys into a fresh timestamped release folder, then switches a `current` symlink to point at it
- An `EXIT` trap automatically rolls back to the previous release **unless** the deploy succeeds — the last line disarms that trap on success:
```bash
log "SUCCESS" "Deployment successful: $RELEASE_DIR"
trap - EXIT  # cancel automatic rollback — we succeeded, don't undo it
```

Before deploying, it snapshots the current release into `$BACKUP` (clearing out
anything left over from an older snapshot first, so it always reflects exactly
the one release right before this deploy — not a stale mix of several past ones):
```bash
if [[ -d "$CURRENT" ]]; then
  rm -rf "$BACKUP"
  mkdir -p "$BACKUP"
  cp -r "$CURRENT/." "$BACKUP/"
fi
```

If a deploy fails, the rollback trap checks whether a real backup actually exists
before restoring it — on a script's very first-ever run there's nothing to roll
back to yet, so it says that plainly instead of pointing `$CURRENT` at an empty
directory:
```bash
if [[ -d "$BACKUP" ]]; then
  ln -sf "$BACKUP" "$CURRENT"
else
  log "INFO" "No previous release to roll back to"
fi
```

**Testing it locally** — the script expects a real release to deploy from
`/tmp/new-release/` into `/var/www/myapp/`, neither of which exist by default:
```bash
mkdir -p /tmp/new-release
echo "<h1>hello world</h1>" > /tmp/new-release/index.html

sudo mkdir -p /var/www/myapp
sudo bash deploy-with-rollback.sh
```
Expect `[SUCCESS] Deployment successful: /var/www/myapp/releases/<timestamp>`.
Check `/var/www/myapp/current` afterward — it'll be a symlink pointing at that
release. Clean up:
```bash
sudo rm -rf /var/www/myapp /var/log/deploy.log
rm -rf /tmp/new-release
```

---

## 7. Health Check Monitor

**File:** `scripts/advanced/day4/health-check-monitor.sh`

Checks `nginx` every 30 seconds, forever, and emails `$ALERT_EMAIL` if it goes down:
```bash
while true; do
  check_service || true
  sleep 30
done
```
The `|| true` matters here — without it, one failed check under `set -e` would kill
the entire monitor instead of just logging and continuing to the next check.

**Testing it without waiting or backgrounding anything:**
```bash
./health-check-monitor.sh --once
```

**Running it for real, as an actual background monitor:**
```bash
nohup ./health-check-monitor.sh > /dev/null 2>&1 &
```

> The log function prints to your terminal *and* tries to write `/var/log/health-check.log`
> — if that file isn't writable (needs root), you'll see a visible warning instead of
> the script going completely silent. On startup it also announces itself, so you
> always know it's actually running before it drops into the 30-second loop.

---

## 8. Secure Config Loader

**File:** `scripts/advanced/day4/secure-config-loader.sh`

Never trusts a config file blindly — checks the parser (`yq`) exists, then checks the
file actually parses, *before* reading any real value out of it:
```bash
validate_config() {
  command -v yq &> /dev/null || { log "ERROR" "yq is not installed"; exit 1; }
  yq eval '.database.host' "$CONFIG" > /dev/null 2>&1 || { log "ERROR" "config file invalid"; exit 1; }
}
```

**Testing it locally** — the script expects a real file at `/etc/myapp/config.yaml`,
which doesn't exist by default. Create a fake one to see it succeed instead of
erroring out:
```bash
sudo mkdir -p /etc/myapp
echo "database:" | sudo tee /etc/myapp/config.yaml > /dev/null
echo "  host: localhost" | sudo tee -a /etc/myapp/config.yaml > /dev/null
echo "  port: 5432" | sudo tee -a /etc/myapp/config.yaml > /dev/null

bash secure-config-loader.sh
```
Expect `[SUCCESS] config loaded successfully`. Clean up afterward:
```bash
sudo rm -rf /etc/myapp
```

---

## 9. Cleanup with Lock

**File:** `scripts/advanced/day4/cleanup-with-lock.sh`

Uses `mkdir` instead of a plain lock *file* — `mkdir` is atomic in a way `touch` isn't,
so two copies of this script racing to start at the same instant can't both succeed:
```bash
acquire_lock() {
  if ! mkdir "$LOCK" 2>/dev/null; then
    echo "ERROR: Script is already running" >&2
    exit 1
  fi
}
release_lock() { rmdir "$LOCK"; }

acquire_lock
trap release_lock EXIT
```

---

## 10. Database Backup & Restore

**File:** `scripts/advanced/day4/database-backup-restore.sh`

Doesn't just trust that `pg_dump` succeeded — actually verifies the backup by reading
it back before pointing the `-latest` symlink at it:
```bash
command -v pg_dump &> /dev/null || { log "ERROR" "pg_dump is not installed"; exit 1; }

pg_dump -U "$DB_USER" "$DB" | gzip > "$BACKUP_FILE"

if zcat "$BACKUP_FILE" | head -10 >/dev/null; then
  ln -sf "$BACKUP_FILE" "$BACKUP_DIR/${DB}-latest.sql.gz"
else
  log "ERROR" "Backup is corrupted"
  rm -f "$BACKUP_FILE"
  exit 1
fi
```
Named `DB_USER`, not `USER` — the latter would silently shadow the system's own
built-in `$USER` environment variable, which is exactly the kind of subtle
naming collision worth avoiding on purpose.

---

## Recap

| Concept | One-liner |
|---|---|
| Settings | `set -euo pipefail` + `IFS=$'\n\t'` at the top of every serious script |
| Trap | `trap cmd EXIT` for cleanup, `trap cmd ERR` to react to failures, both fire automatically |
| Logging | Timestamp + level + message, piped through `tee -a` so it prints *and* saves |
| Debugging | `set -x` / `bash -x script.sh` to see every command as it runs |

Next up: **Day 5 — Arrays, JSON Processing, Parallel Execution, API Integration.**
