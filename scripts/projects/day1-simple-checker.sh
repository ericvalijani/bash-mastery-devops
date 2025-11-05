#!/bin/bash
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 name age"
  exit 1
fi

name=$1
age=$2

if [[ $age -gt 18 ]]; then
  echo "Welcome, $name!"
else
  echo "Access denied."
fi
