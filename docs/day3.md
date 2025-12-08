# Day 3: File I/O, Redirection, Pipes, find, grep, sed, awk

> **Goal**: Complete mastery over working with files, search, filter, and text editing — daily DevOps tools

## 1. Redirection and Pipes
| Operator | Meaning | Example |
|----------|---------|---------|
| `>`      | Output → file (overwrite) | `echo "hello" > file.txt` |
| `>>`     | Output → file (append) | `date >> log.txt` |
| `<`      | Input ← file | `mail -s "Hi" admin < body.txt` |
| `2>`     | Error → file | `ls /root 2> error.log` |
| `&>`     | Output + error → file | `bash script.sh &> all.log` |
| `|`      | pipe | `ls -la \| grep ".sh"` |

## 2. Working with Files
```bash
[ -f "file" ] && echo "exists"
[ -d "dir" ] && echo "is directory"
[ -r "file" ] && echo "readable"
[ -w "file" ] && echo "writable"
[ -x "file" ] && echo "executable"
```

## Implemented Exercises (All Tested)

| Exercise | Script | Real Application |
|-------|--------|-------------|
| 1 | `log-analyzer.sh` | Quick analysis of system logs |
| 2 | `backup-cleaner.sh` | Backup space management |
| 3 | `user-report.sh` | User security report |
| 4 | `find-large-files.sh` | Finding large files |
| 6 | `nginx-access-top-ips.sh` | Detecting attacks or high-usage users |

All scripts are written with `set -euo pipefail` and appropriate error handling.

## Day 3 Summary: File I/O, Redirection, Pipes, find, grep, sed, awk

> Goal: Master file ops, search/filter/text editing for DevOps.

- __Redirection & Pipes__: Operators: `>` (overwrite file), `>>` (append), `<` (input from file), `2>` (error to file), `&>` (out+err to file), ` ` (pipe cmds). Examples: `echo "hello" > file.txt`, `ls -la | grep ".sh"`.

- __File Checks__: Test props: `[ -f "file" ]` (exists), `[ -d "dir" ]` (dir), `[ -r/-w/-x "file" ]` (readable/writable/executable).

- __Exercises (Tested Scripts)__: log-analyzer.sh (system logs), backup-cleaner.sh (backup mgmt), user-report.sh (user security), find-large-files.sh (large files), nginx-access-top-ips.sh (attack/high-usage detection). All use `set -euo pipefail` & error handling.
