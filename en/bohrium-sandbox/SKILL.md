---
name: bohrium-sandbox
description: "Cloud sandbox for running shell commands / Python in an isolated E2B VM, exposed by bohrctl's SandboxTool. Use when: user wants to execute code, run quick scripts, test commands, read/write files in a throwaway environment WITHOUT polluting the host. NOT for: Bohrium compute jobs (use bohrium-job), dev machines (use bohrium-node)."
---

# SKILL: Bohrium Sandbox (E2B)

## Overview

bohrctl integrates [E2B](https://e2b.dev/) as a sandbox — an on-demand, ephemeral cloud VM supporting three actions:

- **exec** — run a shell command
- **write** — write a file
- **read** — read a file

The sandbox is lazy-initialized per session: created on first use, cleaned up on session exit.

**Use when**:

- Running a quick Python / Bash snippet to verify an idea
- Executing commands that might be dangerous or pollute the host
- Batch file operations (download, convert, extract)

**Don't use for**:

- Bohrium compute jobs → `bohrium-job`
- Long-lived dev machines → `bohrium-node`

**Different from other skills**: sandbox does **not** go through `open.bohrium.com`. It calls the E2B API (`api.e2b.dev`) directly.

## Configuration

**Required**: set `E2B_API_KEY` (get one at <https://e2b.dev/dashboard>).

```json
"bohrium-sandbox": {
  "enabled": true,
  "env": {
    "E2B_API_KEY": "YOUR_E2B_KEY",
    "E2B_SANDBOX_TEMPLATE": "openclaw"
  }
}
```

Optional: `E2B_SANDBOX_TEMPLATE` picks the template (default `openclaw`).

## Usage

Invoked through the `Sandbox` tool in the `bohr` CLI — not a raw HTTP endpoint. bohrctl handles the E2B session / auth / cleanup for you.

### 1. exec — run a command

```
action: exec
command: "pip install numpy && python -c 'import numpy; print(numpy.__version__)'"
timeout: 60000   # ms; default 60s, max 300s
```

Response:

```
stdout:
  <stdout; truncated from the tail if > 50K chars>
stderr:
  <stderr; truncated if > 10K chars>
exit code: 0
```

### 2. write — write a file

```
action: write
path: "/home/user/script.py"
content: "print('hello')\n"
```

### 3. read — read a file

```
action: read
path: "/home/user/script.py"
```

> If > 50K chars, only the last 50K are returned (good for log tails).

---

## Workflow examples

### Quick Python script verification

```
# 1. write file
action: write
path: /tmp/check_torch.py
content: |
    import torch
    print(torch.__version__, torch.cuda.is_available())

# 2. exec
action: exec
command: python /tmp/check_torch.py
```

### Download and convert data

```
action: exec
command: |
    curl -s -o data.csv https://example.com/data.csv
    python -c "
    import pandas as pd
    df = pd.read_csv('data.csv')
    df.to_parquet('data.parquet')
    print(df.shape)
    "
```

### Read the tail of a log file

```
action: read
path: /var/log/app.log
```

---

## Notes

- **Sandbox is ephemeral** — destroyed when the session ends; don't leave important artifacts inside. For durable results, download them or push to a Bohrium dataset.
- **exec timeout** — default 60s, max 300s. Split long tasks or use `bohrium-job`.
- **Network** — the sandbox has outbound network; you can install packages, clone repos, call APIs.
- **File paths** — prefer `/tmp` or `/home/user` to avoid permission issues.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `E2B_API_KEY environment variable is required` | No API key configured | Register at <https://e2b.dev/dashboard>, set `E2B_API_KEY` |
| Command times out | Task exceeds timeout | Raise `timeout` (max 300000 ms) or switch to `bohrium-job` |
| stdout truncated | Output > 50K chars | Write output to a file, then `action: read` in chunks |
| Can't find previously-created file | Sandbox was destroyed between sessions | Within one session the sandbox is shared; no persistence across sessions |

## Pairs well with

- **sandbox** to validate a script → **bohrium-job** to run at scale on Bohrium
- **sandbox** to download / preprocess / unpack data → upload via **bohrium-dataset**
- **sandbox** verification runs → persist results into **viking-memory**
