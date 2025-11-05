#!/bin/bash
set -euo pipefail

echo "Script name: $0"
echo "Number of args: $#"
echo "First arg: ${1:-}"
echo "Second arg: ${2:-}"
echo "All args: $*"

# Loop over args
for arg in "$@"; do
  echo "Arg: $arg"
done
