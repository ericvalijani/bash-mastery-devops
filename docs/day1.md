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
- Example in `/scripts/basics/variables.sh`:
```bash
#!/bin/bash
set -euo pipefail  # Best practice: exit on error, undefined vars, pipe fail

name="Alice"
age=30
echo "Name: $name, Age: $age"
readonly pi=3.14
echo "Pi: $pi"
```
> Run: ./variables.sh → Output: Name: Alice, Age: 30 \n Pi: 3.14

## 3. Conditionals (if/else)
- Syntax: `if [ condition ]; then ... else ... fi`
- Operators: `-eq (equal), -ne (not equal), -gt (greater), == for strings`.
- Example: `scripts/basics/conditionals.sh`:
```bash
#!/bin/bash
set -euo pipefail

age=25
if [ $age -gt 18 ]; then
  echo "Adult"
elif [ $age -eq 18 ]; then
  echo "Just adult"
else
  echo "Minor"
fi
```
> Run: age=25: Adult

## 4. Arguments
- `$0`: Script name.
- `$1, $2, ...`: Arguments.
- `$@`: All arguments.
- Example: `scripts/basics/args.sh`:
```bash
#!/bin/bash
set -euo pipefail

echo "Script name: $0"
echo "First arg: $1"
echo "All args: $@"
```
> Run: ./args.sh hello world → Script name: ./args.sh \n First arg: hello \n All args: hello world

## 5. Simple Checker
Create a simple script: `scripts/projects/day1-simple-checker.sh` that takes name and age, checks if __>18__ then says "Welcome".

```bash
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
```

## Summary of Day 1: Introduction to Bash Scripting - Variables, Conditionals, Arguments

This day focuses on foundational Bash concepts, including variables, conditional statements, and handling script arguments. All examples are located in `/scripts/basics/` and can be tested directly.

### Key Topics Covered:

- __Bash Fundamentals__: Bash is a Unix shell and scripting language. Scripts begin with a shebang (`#!/bin/bash`) and should include `set -euo pipefail` for robust error handling (exits on errors, undefined variables, or pipe failures). Run scripts via `chmod +x script.sh && ./script.sh` or `bash script.sh`.

- __Variables__: Declared without spaces (e.g., `var="value"`). Accessed with `$var` or `${var}` for safety in strings. Strings are default; numbers behave as strings unless in arithmetic contexts. Use `readonly var="value"` for constants and `export VAR="value"` for environment variables visible to subprocesses. Example script (`variables.sh`) demonstrates basic usage and readonly variables.

- __Conditionals (if/else)__: Use `if [ condition ]; then ... else ... fi`. Common operators include `-eq` (equal), `-ne` (not equal), `-gt` (greater than) for numbers, and `==` for strings. Example script (`conditionals.sh`) checks age to determine if someone is an adult, just adult, or minor.

- __Arguments__: Access script name with `$0`, individual args with `$1`, `$2`, etc., and all args with `$@`. Example script (`args.sh`) echoes the script name, first argument, and all arguments.

- __Simple Project__: Create `day1-simple-checker.sh` that accepts a name and age as arguments, validates input (exactly 2 args), and outputs "Welcome, [name]!" if age > 18, or "Access denied." otherwise. It uses argument checks (`$#` for count) and conditionals.

This sets up core building blocks for scripting.

