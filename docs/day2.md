# Day 2: Loops, Functions, and Arguments in Bash

**Goal**: Master `for`, `while`, `until` loops and Bash functions with best practices.
**Senior DevOps Tips**: Always use `set -euo pipefail`, `local` variables in functions, and quote variables.

---

## 1. For Loop

### 1.1 Simple list

```bash
#!/bin/bash
set -euo pipefail

for fruit in apple banana cherry date; do
  echo "I like $fruit"
done
```
### 1.2 Loop over files
```bash
for file in scripts/basics/day2/*.sh; do
  echo "Found script: $file"
done
```
### 1.3 C-style for loop
```bash
for ((i=1; i<=5; i++)); do
  echo "Count: $i"
done
```
## 2. While & Until Loops
### 2.1 While loop with counter

```bash
count=1
while [ $count -le 5 ]; do
  echo "While count: $count"
  ((count++))
done
```
### 2.2 Read file line by line

```bash
while IFS= read -r line; do
  echo "Line: $line"
done < README.md
```
### 2.3 Until loop (runs until condition is true)

```bash
seconds=0
until [ $seconds -ge 3 ]; do
  echo "Waiting... $seconds seconds"
  sleep 1
  ((seconds++))
done
```
## 3. Functions – Best Practices
### 3.1 Basic function with local variables
```bash
greet() {
  local name="$1"           # local 
  local timestamp=$(date +%F_%H:%M:%S)
  echo "[$timestamp] Hello, $name! Welcome to Bash mastery."
}

greet "DevOps Engineer"
```



### 3.2 Function with return value (use echo, not return for strings)
```bash
add() {
  local a=$1
  local b=$2
  echo $((a + b))           
}

result=$(add 15 27)         
echo "15 + 27 = $result"
```


### 3.3 Function with default arguments
```bash
backup() {
  local src="${1:-/home}"   
  local dest="${2:-/backup}"
  echo "Backing up $src → $dest at $(date)"
}
backup                    # → uses default
backup /etc /var/backup   # → custom choice
```

### 3.4 Advanced: Return multiple values via global array
```bash
get_system_info() {
  local info=()
  info+=("user:$(whoami)")
  info+=("host:$(hostname)")
  info+=("uptime:$(uptime -p)")
  SYSTEM_INFO=("${info[@]}")  # global array
}
get_system_info
echo "System info collected: ${SYSTEM_INFO[@]}"
```
## 4. Advanced Argument Handling
### 4.1 getopts – Professional argument parsing
```bash
#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 -n NAME -a AGE [-v]"
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

[[ -z "$name" || -z "$age" ]] && usage

echo "Name: $name, Age: $age"
((verbose)) && echo "Verbose mode enabled"
```
### Run examples:
```bash
./args-getopts.sh -n Ali -a 30
./args-getopts.sh -n Ali -a 30 -v
```
## Day 2 Summary: Loops, Functions, Args in Bash

- __For Loops__: List iteration (e.g., fruits), file glob (e.g., `*.sh`), C-style (`((i=1; i<=5; i++))`).

- __While/Until__: Counter-based while, file reading (`IFS= read -r`), until condition true (e.g., timed wait with `sleep`).

- __Functions__: Basic with locals & args (e.g., greet with timestamp), return via `echo` (e.g., add), defaults (`${1:-val}`), multi-return via global array (e.g., system info).

- __Adv Args__: `getopts` for flags (e.g., `-n name -a age -v`), with usage & validation.

Examples: Run `args-getopts.sh` with options for output.




















