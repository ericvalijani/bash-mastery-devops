# Day 2 — Loops, Functions, and Argument Parsing

Today's goal: master the three loop types (`for`, `while`, `until`), write functions
the safe way (`local` variables, quoted arguments), and level up argument handling
with `getopts`.

---

## 📁 Scripts for today

| Script | Path | What it actually does | Try it |
|---|---|---|---|
| **Loops** | `scripts/basics/loops.sh` | Runs through every loop type: a simple list, a file glob, a C-style counter, a `while`, reading a file line-by-line, and an `until` timer | `bash scripts/basics/loops.sh` |
| **Functions** | `scripts/basics/functions.sh` | Defines and calls 4 functions: a greeting with a timestamp, an adder that returns a value, a backup helper with default arguments, and one that collects system info into a global array | `bash scripts/basics/functions.sh` |
| **Getopts Arguments** | `scripts/basics/args-getopts.sh` | Professional-style flag parsing — reads `-n NAME -a AGE` and an optional `-v` verbose flag | `bash scripts/basics/args-getopts.sh -n Ali -a 30 -v` |
| **Backup** (today's mini-project) | `scripts/projects/day2-backup.sh` | Takes a source folder and destination, and creates a timestamped `.tar.gz` backup of it | `bash scripts/projects/day2-backup.sh ~/documents /tmp/backups` |

---

## 1. For loops

**Simple list:**
```bash
for fruit in apple banana cherry date; do
  echo "I like $fruit"
done
```

**Loop over files** — matches every script in `scripts/basics/`:
```bash
for file in scripts/basics/*.sh; do
  echo "Found script: $file"
done
```

**C-style, when you need a counter:**
```bash
for ((i = 1; i <= 5; i++)); do
  echo "Count: $i"
done
```

---

## 2. While & Until loops

**While, with a counter:**
```bash
count=1
while [[ $count -le 5 ]]; do
  echo "While count: $count"
  ((count++))
done
```

**Read a file line by line** — the `IFS= read -r` pattern is the safe way to do this,
it stops Bash from trimming whitespace or mangling backslashes:
```bash
while IFS= read -r line; do
  echo "Line: $line"
done < README.md
```

**Until — the opposite of while, runs *until* a condition becomes true:**
```bash
seconds=0
until [[ $seconds -ge 3 ]]; do
  echo "Waiting... $seconds seconds"
  sleep 1
  ((seconds++))
done
```

---

## 3. Functions — the right way

- Always declare variables inside a function as `local` — otherwise they leak into the rest of your script and can silently overwrite something.
- To "return" a value from a function, `echo` it and capture it with `$(...)` — Bash's `return` keyword only returns numeric exit codes, not real data.

**Basic function:**
```bash
greet() {
  local name="$1"
  local timestamp
  timestamp=$(date +%F_%H:%M:%S)
  echo "[$timestamp] Hello, $name! Welcome to Bash mastery."
}
greet "DevOps Engineer"
```

**Returning a value:**
```bash
add() {
  local a=$1
  local b=$2
  echo $((a + b))
}
result=$(add 15 27)
echo "15 + 27 = $result"
```

**Default arguments** — `${1:-/home}` means "use arg 1, or `/home` if nothing was passed":
```bash
backup() {
  local src="${1:-/home}"
  local dest="${2:-/backup}"
  echo "Backing up $src → $dest at $(date)"
}
backup                  # uses defaults
backup /etc /var/backup # custom paths
```

**Returning multiple values** — Bash functions can't return arrays directly, so the
common pattern is to build the array inside the function and assign it to a global
variable at the end:
```bash
get_system_info() {
  local info=()
  info+=("user:$(whoami)")
  info+=("host:$(hostname)")
  info+=("uptime:$(uptime -p)")
  SYSTEM_INFO=("${info[@]}") # global array
}
get_system_info
echo "System info collected: ${SYSTEM_INFO[@]}"
```

---

## 4. Professional argument parsing with `getopts`

Positional arguments (`$1`, `$2`) get confusing fast once a script takes more than
one or two inputs. `getopts` lets people call your script with named flags instead,
in any order: `-n Ali -a 30` instead of just `Ali 30`.

**Script** (`scripts/basics/args-getopts.sh`):
```bash
#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 -n NAME -a AGE [-v]"
  echo "Example: $0 -n Ali -a 25 -v"
  exit 1
}

verbose=0
while getopts "n:a:v" opt; do
  case $opt in
    n) name="$OPTARG" ;;
    a) age="$OPTARG" ;;
    v) verbose=1 ;;
    *) usage ;;
  esac
done

[[ -z "${name:-}" || -z "${age:-}" ]] && usage

echo "Name: $name, Age: $age"
(( verbose )) && echo "Verbose mode enabled"
```
**Run it:**
```bash
./args-getopts.sh -n Ali -a 30
./args-getopts.sh -n Ali -a 30 -v
```

---

## 5. Today's mini-project — Backup

Put loops, functions, and default arguments together into something actually useful:
a script that backs up any folder into a timestamped `.tar.gz` file.

**File:** `scripts/projects/day2-backup.sh`
```bash
#!/bin/bash
set -euo pipefail

backup_dir() {
  local source="$1"
  local dest="$2"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_name
  backup_name="$(basename "$source")_$timestamp.tar.gz"

  echo "Backing up $source → $dest/$backup_name"
  tar -czf "$dest/$backup_name" "$source"
  echo "Done! Backup created."
}

# Default values
SRC="${1:-$HOME/documents}"
DEST="${2:-/tmp/backups}"

mkdir -p "$DEST"
backup_dir "$SRC" "$DEST"
```
**Run it:** `./day2-backup.sh ~/documents /tmp/backups`

---

## Recap

| Concept | One-liner |
|---|---|
| For loop | `for x in list; do ... done`, or `for ((i=1;i<=5;i++))` for a counter |
| While / Until | `while [[ cond ]]; do ... done` runs *while* true, `until` runs until true |
| Functions | Always use `local` inside them; `echo` + `$(...)` to "return" a value |
| Getopts | `while getopts "n:a:v" opt; do case $opt in ... esac; done` for named flags |

Next up: **Day 3 — File I/O, Redirection, Pipes, `find`, `grep`, `sed`, `awk`.**