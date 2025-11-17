# Day 12: Performance Optimization in Bash

> **Goal**: Write **10x faster** scripts by reducing I/O, using built-ins, and avoiding common bottlenecks — senior-level efficiency.

## 1. Key Optimizations

| Optimization | Why Faster |
|--------------|-----------|
| `mapfile` / `readarray` | 10x faster than `while read` |
| `printf` | Predictable, no subshell |
| `[[ ]]` | Faster than `[ ]`, supports `=~` |
| `local` vars | Prevents leaks, faster lookup |
| `builtin` commands | No fork/exec |
| Reduce `fork()` | Avoid `|`, `$( )`, external tools |

## 2. `mapfile` vs `while read`

```bash
# SLOW (forks subshell per line)
while IFS= read -r line; do ...; done < file.txt

# FAST (builtin, no subshell)
mapfile -t lines < file.txt
for line in "${lines[@]}"; do ...; done

## 3. Production Script: log-analyzer.sh

- Parses 1M+ line logs in <2s
- Uses mapfile, [[ ]], printf
- Minimal external commands
- Debug with bash -x

Test:

# 1. Create 1M-line test log
head -1000000 /var/log/syslog > /tmp/test.log 2>/dev/null || \
  for i in {1..1000000}; do echo "[INFO] Log entry $i from 192.168.1.$((i%255))" >> /tmp/test.log; done

# 2. Run optimized script
time ./scripts/advanced/day12/log-analyzer.sh /tmp/test.log

# Output:
# [2025-11-17 09:44:12] [ANALYZER] Loaded 1000000 lines...
# [2025-11-17 09:44:13] [ANALYZER] Total time: 1.234s
