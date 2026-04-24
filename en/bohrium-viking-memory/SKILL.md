---
name: bohrium-viking-memory
description: "Long-term memory for agents via OpenViking REST API. Use when: user wants to save notes/facts/context that should persist across bohr sessions, recall prior memories by semantic query or keyword, or explicitly delete saved memories. NOT for: short-term conversation state, file storage (use bohrium-dataset), Bohrium knowledge base (use bohrium-knowledge-base)."
---

# SKILL: Bohrium Viking Memory (long-term memory)

## Overview

bohrctl provides **cross-session long-term memory** via OpenViking:

- **find** — semantic retrieval (meaning-similar)
- **search** — keyword retrieval (literal match)
- **read** — read full content of one memory
- **save** — write a memory (URI auto-generated if omitted)
- **delete** — remove a memory

Memories live at `viking://user/{tenant}-{userId}/memories/...`. Tenant (default `bohrctl`) and `BOHR_USER_ID` together isolate users.

**Use when**:

- Persisting user preferences / project context / important decisions across sessions
- Referring back to experiment results from a previous session
- Storing key takeaways extracted from papers

**Don't use for**:

- Ephemeral state within the current session → keep it in the conversation
- Large files → `bohrium-dataset`
- Paper / knowledge-base files → `bohrium-knowledge-base`

**Different from other skills**: Viking does **not** go through `open.bohrium.com`. It talks directly to OpenViking (default `https://openviking.test.dp.tech`).

## Configuration

```json
"bohrium-viking-memory": {
  "enabled": true,
  "env": {
    "OPENVIKING_URL": "https://openviking.test.dp.tech",
    "OPENVIKING_API_KEY": "YOUR_KEY",
    "OPENVIKING_ACCOUNT": "bohrctl",
    "BOHR_USER_ID": "your-app-user-id"
  }
}
```

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENVIKING_URL` | `https://openviking.test.dp.tech` | OpenViking service base URL |
| `OPENVIKING_API_KEY` | (required) | Service auth |
| `OPENVIKING_ACCOUNT` | `bohrctl` | Tenant identifier |
| `BOHR_USER_ID` | `anonymous` | Application-level user id; mapped to `{tenant}-{uid}` |

## Usage

Invoked through the `Memory` tool in the `bohr` CLI — not a raw HTTP endpoint. bohrctl handles:

- Injecting `X-OpenViking-Account` / `X-OpenViking-User` / `X-API-Key` headers
- URI namespace isolation
- Response parsing and truncation

---

## Action reference

### 1. find — semantic retrieval

The most common recall path. Finds memories with similar meaning (even if phrased differently).

```
action: find
query: "user's preferred Python coding style"
```

Returns Top-10, score > 0.25. Output has URI / title / score / abstract — use them to decide whether to `read` full content.

### 2. search — keyword retrieval

Literal match; use when you know an exact term appears in the memory.

```
action: search
query: "DeePMD training hyperparameters"
```

### 3. read — full content of a memory

After `find` / `search` returns a URI, fetch the full body with `read`.

```
action: read
uri: viking://user/bohrctl-alice/memories/preferences/python-style
```

> Truncated if > 30K chars.

### 4. save — store a memory

```
action: save
content: |
    User prefers:
    - Python: type hints on all public functions
    - Formatting: ruff with line-length 100
    - Docstrings: Google style
path: preferences/python-style    # optional; auto-generated if omitted
tags: ["preference", "python"]    # optional; helps later search
```

### 5. delete — remove a memory

```
action: delete
uri: viking://user/bohrctl-alice/memories/preferences/python-style
```

---

## Recommended workflow

### Recall history when a session starts

```
# session start
action: find
query: "prior work on this project"
```

### Record an important decision

```
action: save
content: "Decided on Adam optimizer with lr=1e-3 for DPA-2 finetune. Batch size 32 OOM'd on A100 40G."
tags: ["decision", "dpa2", "finetune"]
```

### Cross-session reference

```
# Next session
action: find
query: "DPA-2 finetune setup"
# → returns the URI + score
action: read
uri: <URI from find>
```

---

## Notes

- **Strict user isolation**: memories for different `BOHR_USER_ID`s are invisible to each other. Switching users shows a different memory set.
- **find vs search**: semantic recall is high-recall but can be imprecise; keyword recall is precise but may miss. Start with `find`; fall back to `search`.
- **save granularity**: one memory = one topic (a paragraph or two). Don't dump raw logs; OpenViking's embeddings work better on short focused content.
- **tags role**: currently mostly for human readers and future filtering; `find` still matches primarily on `content`.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `isVikingEnabled() == false` | `OPENVIKING_API_KEY` not set | Provide the key; bohrctl enables Memory only when it's present |
| `find` always empty | Memories under a different user; or all scores < 0.25 | Check `BOHR_USER_ID`; try `search` with a literal keyword |
| `read` returns `No content found` | Wrong URI / already deleted | Re-fetch the URI via `find` or `search` |
| Just-saved memory not `find`-able | Indexing lag | Retry after a few seconds; indexing is async |

## Pairs well with

- Start a session with **viking find** → then begin work
- After finishing a unit of work, **viking save** key conclusions
- Takeaways from **paper-search / pdf-parser** → **viking save** to accumulate across sessions
