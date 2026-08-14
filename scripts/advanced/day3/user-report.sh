#!/bin/bash
set -euo pipefail

echo "=== User Report - $(date) ==="
echo "Total users: $(wc -l < /etc/passwd)"
echo

echo "Users with /bin/bash:"
grep "/bin/bash" /etc/passwd | awk -F: '{print $1, $6}' | column -t

echo -e "\nLast login times:"
journalctl _COMM=sshd | tail -20
