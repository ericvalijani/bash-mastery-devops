# Day 1: Introduction to Bash Scripting - Variables, Conditionals, Arguments

## Overview
Today we cover Bash basics: variables, conditionals, and script arguments. All examples are in `/scripts/basics/` and testable.

## 1. Bash Fundamentals
- Bash is a Unix shell and command language.
- Scripts start with shebang: `#!/bin/bash`
- Best practice: Add `set -euo pipefail` to handle errors (exits on error, treats unset variables as error, fails on pipe errors).
- Run: `chmod +x script.sh && ./script.sh` or `bash script.sh`

## 2. Variables
- Declare: `var="value"` (no spaces around =).
- Access: `$var` or `${var}` (safer in strings).
- Types: Strings by default; numbers treated as strings unless in arithmetic.
- Readonly: `readonly var="value"`
- Environment vars: `export VAR="value"` to make available to subprocesses.

Example in `/scripts/basics/variables.sh`:
```bash
#!/bin/bash
set -euo pipefail

# Simple variable
name="Alice"
age=30

# Output
echo "Name: $name"
echo "Age: ${age} years"

# Readonly
readonly pi=3.14159
echo "Pi: $pi"

# Arithmetic (use (( )) for math)
((sum = age + 5))
echo "Age in 5 years: $sum"
