# Day 1 — Bash Fundamentals: Variables, Conditionals, Arguments

Today's goal: get comfortable with the three building blocks every Bash script uses —
storing values in variables, making decisions with `if/else`, and reading input passed
in from the command line.

---

## 📁 Scripts for today

| Script | Path | What it actually does | Try it |
|---|---|---|---|
| **Variables** | `scripts/basics/variables.sh` | Sets a name and age, prints them, then locks a `pi` value with `readonly` so it can't be changed | `bash scripts/basics/variables.sh` |
| **Conditionals** | `scripts/basics/conditionals.sh` | Checks an age and prints whether that person is an adult, just turned 18, or a minor — then separately checks whether a `name` variable is actually set | `bash scripts/basics/conditionals.sh` |
| **Arguments** | `scripts/basics/arguments.sh` | Prints the script's own name, how many arguments you gave it, the 1st and 2nd one by position, all of them together, then loops through and prints each one individually | `bash scripts/basics/arguments.sh hello world` |
| **Simple Checker** (today's mini-project) | `scripts/projects/day1-simple-checker.sh` | Takes a name and age as input, then either welcomes them or denies access based on age | `bash scripts/projects/day1-simple-checker.sh Alice 25` |

---

## 1. The basics

- Bash is the shell/scripting language you're using right now in your terminal.
- Every script starts with a **shebang** — the first line, always: `#!/bin/bash`
- Right after that, add `set -euo pipefail`. This one line saves you hours of confusion later:
  - `-e` → stop immediately if any command fails
  - `-u` → error out if you reference a variable that was never set (catches typos)
  - `-o pipefail` → catch failures inside piped commands (`cmd1 | cmd2`), not just the last one
- To run a script: `chmod +x script.sh && ./script.sh`, or just `bash script.sh` (skips the permission step).

---

## 2. Variables

- **Set one:** `name="Alice"` — no spaces around the `=`, or Bash will misread it as a command.
- **Read one:** `$name` or `${name}`. Use the `{}` version when it's next to other text, e.g. `"${name}_backup"`.
- Everything is a string by default, even numbers — Bash only treats them as numbers inside arithmetic contexts like `(( ))`.
- **Lock a value so it can't change:** `readonly pi=3.14`
- **Share a value with other programs your script runs:** `export VAR="value"`

**Script** (`scripts/basics/variables.sh`):
```bash
#!/bin/bash
set -euo pipefail

name="Alice"
age=30
echo "Name: $name, Age: $age"

readonly pi=3.14
echo "Pi: $pi"
```
**Output:**
```
Name: Alice, Age: 30
Pi: 3.14
```

---

## 3. Conditionals — making decisions

- Basic shape: `if [[ condition ]]; then ... elif ... else ... fi`
- Common comparisons:
  - Numbers: `-eq` (equal), `-ne` (not equal), `-gt` (greater than)
  - Strings: `==`, or `-n "$var"` to check a string isn't empty

**Script** (`scripts/basics/conditionals.sh`) — this one actually does two separate checks:
```bash
#!/bin/bash
set -euo pipefail

age=25
if [[ $age -gt 18 ]]; then
  echo "You are an adult."
elif [[ $age -eq 18 ]]; then
  echo "You just became an adult."
else
  echo "You are a minor."
fi

# String check
name="Bob"
if [[ -n "$name" ]]; then
  echo "Name is set: $name"
fi
```
**Output** (with `age=25`, `name="Bob"`):
```
You are an adult.
Name is set: Bob
```

---

## 4. Arguments — reading input from the command line

- `$0` → the script's own name
- `$1`, `$2`, ... → the 1st, 2nd, etc. argument someone passed in
- `$#` → *how many* arguments were passed in
- `$@` → all arguments, kept as separate items (best for looping over them)
- `$*` → all arguments joined into a single string
- `${1:-}` → "give me arg 1, or nothing if it wasn't provided" — avoids errors from `set -u` when an argument is optional

**Script** (`scripts/basics/arguments.sh`) — this one covers all of the above, plus loops through each argument:
```bash
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
```
**Run it:** `./arguments.sh hello world`
**Output:**
```
Script name: ./arguments.sh
Number of args: 2
First arg: hello
Second arg: world
All args: hello world
Arg: hello
Arg: world
```

---

## 5. Today's mini-project — Simple Checker

Put the pieces together: a script that takes a **name** and an **age**, and decides
whether to welcome that person based on their age.

**File:** `scripts/projects/day1-simple-checker.sh`
```bash
#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 name age"
  exit 1
fi

name="$1"
age="$2"

if [[ $age -ge 18 ]]; then
  echo "Welcome, $name!"
else
  echo "Access denied."
fi
```
**Run it:** `./day1-simple-checker.sh Alice 18` → `Welcome, Alice!`

---

## Recap

| Concept | One-liner |
|---|---|
| Variables | `name="value"`, read with `$name`, lock with `readonly` |
| Conditionals | `if [[ condition ]]; then ... fi`, use `-eq`/`-gt`/`-n`/`==` |
| Arguments | `$0` = script name, `$1..$n` = args, `$#` = count, `$@`/`$*` = all of them, `${1:-}` = safe optional access |

Next up: **Day 2 — Loops & Functions.**
