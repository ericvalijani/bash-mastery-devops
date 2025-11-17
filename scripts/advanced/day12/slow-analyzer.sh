#!/usr/bin/env bash
# SLOW version for comparison
error_count=0
while IFS= read -r line; do
  if echo "$line" | grep -q "ERROR"; then
    ((error_count++))
  fi
done < /tmp/test.log
echo "Errors: $error_count"
