#!/bin/bash
set -euo pipefail

# Simple load test on an Nginx (or any HTTP) server using Apache Bench (ab).
# Requires 'ab': sudo apt install apache2-utils

if ! command -v ab &> /dev/null; then
  echo "Error: 'ab' (Apache Bench) is not installed. Install with: sudo apt install apache2-utils"
  exit 1
fi

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <url> <total_requests> <concurrent_requests>"
  echo "Example: $0 http://localhost/ 100 10"
  exit 1
fi

URL="$1"
REQUESTS="$2"
CONCURRENCY="$3"

echo "Starting load test on $URL with $REQUESTS requests and $CONCURRENCY concurrent users..."
ab -n "$REQUESTS" -c "$CONCURRENCY" "$URL"
echo "Load test completed."