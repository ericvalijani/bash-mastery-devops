# Day 23 — CI/CD Framework

Today you build a small but real **pipeline engine** in pure Bash: define named
stages, run them in order, time each one, fail fast (or keep going), and print a
clean pass/fail summary. It's driven by a plain-text pipeline file — the same
shape as the YAML pipelines you already know, minus the vendor lock-in.

It reuses the course's habits: strict mode + logging (Day 11), input validation
(Day 17), and stdout-data / stderr-progress discipline (Day 20).

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **Pipeline lib** | `days/day23/scripts/pipeline-lib.sh` | The engine: `run_stage`, `pipeline_summary` |
| **CI runner** | `days/day23/scripts/ci-run.sh` | Executes a pipeline definition file |
| **Example** | `days/day23/examples/pipeline.ci` | A sample four-stage pipeline |

---

## 1. The pipeline file

One stage per line, `name = command`. Comments and blank lines are ignored:

```ini
lint    = shellcheck --severity=error days/**/scripts/*.sh
test    = bats days/**/tests
build   = echo building artifact...
publish = echo publishing...
```

## 2. Run it

```bash
bash days/day23/scripts/ci-run.sh days/day23/examples/pipeline.ci
```

```
▶ lint
  ✓ lint (0.01s)
▶ test
  ✓ test (0.01s)
...
===== pipeline summary =====
PASS  lint   0.01s
PASS  test   0.01s
PASS  build  0.01s
PASS  publish  0.01s
----------------------------
summary: 4 passed, 0 failed
```

Progress (`▶`, `✓`, `✗`) prints to **stderr**; the summary table prints to
**stdout**, so you can capture just the results: `ci-run.sh pipeline.ci >report.txt`.

## 3. Fail-fast vs keep-going

- **Default — fail-fast:** the first failing stage stops the run (exactly what
  you want gating a merge).
- **`--keep-going`:** run every stage anyway and report all failures at once
  (handy for a nightly "what's broken?" sweep).

```bash
bash days/day23/scripts/ci-run.sh --keep-going pipeline.ci
```

The runner exits non-zero if **any** stage failed — so CI blocks correctly.

## 4. Use the engine directly

`pipeline-lib.sh` is reusable on its own — no config file needed:

```bash
source days/day23/scripts/pipeline-lib.sh
run_stage "unit"  ./run-tests.sh
run_stage "smoke" curl -fsS http://localhost:8080/health
pipeline_summary
```

---

## ✅ Verify

```bash
bats days/day23/tests
bash days/day23/scripts/ci-run.sh days/day23/examples/pipeline.ci
```

---

## Recap

| Concept | One-liner |
|---|---|
| Stages | ordered `name = command` steps |
| Fail-fast | stop at first failure (default) |
| Keep-going | run all, report every failure |
| Honest exit | non-zero if any stage failed |
| Composable | summary to stdout, progress to stderr |

Next up: **Day 24 — GitOps.**
