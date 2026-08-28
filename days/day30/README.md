# Day 30 — Cost & FinOps

The final skill: making the cluster *cheap*. You reserve resources (requests),
but you're billed for what you reserve — not what you use. That gap is waste, and
FinOps is the practice of finding it, pricing it, and closing it.

Today you build a cost report and a right-sizing gate over the same workload
model you've used all along.

---

## 📁 Scripts for today

| Script | Path | What it does |
|---|---|---|
| **Cost lib** | `days/day30/scripts/cost-lib.sh` | Spec parsing + cost math |
| **Cost report** | `days/day30/scripts/cost-report.sh` | Monthly spend, per workload + total |
| **Right-size** | `days/day30/scripts/rightsize.sh` | Waste/risk detection + recommendations |

---

## The workload model

```ini
name        = frontend
replicas    = 5
cpu_request = 500    # millicores reserved (billed)
mem_request = 512    # MiB reserved (billed)
cpu_usage   = 100    # millicores actually used
mem_usage   = 200    # MiB actually used
```

Price model: **$0.031 / core-hour** CPU, **$0.004 / GiB-hour** memory, **730 h**
per month (all overridable).

## 1. What does it cost?

```bash
bash days/day30/scripts/cost-report.sh --dir days/day30/examples
```

```
WORKLOAD         REPLICAS   CPU(m)  MEM(Mi)   COST/MO($)
---------------- -------- ------ ------- ------------
api                     3      250      256        19.16
cache                   2      200      512        11.97
frontend                5      500      512        63.88
---------------- -------- ------ ------- ------------
TOTAL                                                95.01
```

## 2. Where's the waste?

```bash
bash days/day30/scripts/rightsize.sh --dir days/day30/examples
```

```
WORKLOAD       STATUS      CPU%      MEM%    REC_CPU    REC_MEM   SAVE/MO$
-------------- ------ -------- -------- --------- --------- ---------
api            RISK        92%      70%        384        300      -9.47
cache          OK          60%      59%        200        512       0.00
frontend       WASTE       20%      39%        167        334      40.22
-------------- ------ -------- -------- --------- --------- ---------
Potential monthly savings: $30.75
RESULT: workloads need right-sizing   # exit 1
```

- **WASTE** — utilization below `--low` (30%). `frontend` reserves 5× what it
  needs; cut requests and save ~$40/mo.
- **RISK** — utilization above `--high` (90%). `api` is one spike from throttling;
  the recommendation *raises* its request (negative saving = money well spent).
- **OK** — sits in the healthy band, leaving `--target` (60%) headroom.

Recommendations size each request so usage lands at the target headroom:
`recommended = ceil(usage / (target/100))`.

## 3. As a CI gate

`rightsize.sh` exits non-zero when any workload needs attention, so it drops
straight into a pipeline:

```bash
bash days/day30/scripts/rightsize.sh --dir k8s/ --low 25 --high 85 || {
  echo "::warning::workloads need right-sizing"; exit 1;
}
```

---

## ✅ Verify

```bash
bats days/day30/tests
```

---

## Recap

| Concept | One-liner |
|---|---|
| Requests vs usage | you pay for requests; the gap is waste |
| Cost report | price the whole cluster, monthly |
| WASTE | over-provisioned — cut it |
| RISK | under-provisioned — raise it |
| Right-size gate | fail CI until the fleet is efficient |

That's the course — from your first `#!/usr/bin/env bash` to running a
cost-optimized, self-healing platform, all in shell. 🎉
