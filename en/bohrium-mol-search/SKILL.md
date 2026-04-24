---
name: bohrium-mol-search
description: "Molecular structure and molecule-in-paper search via open.bohrium.com. Use when: user asks about finding papers that mention a specific molecule (by SMILES / InChI / formula / name), performing substructure or similarity molecule search, or querying molecular structure data. NOT for: general paper search (use bohrium-paper-search), crystal structures in knowledge base (use bohrium-knowledge-base)."
---

# SKILL: Bohrium Molecular Search

## Overview

Two groups of molecule-centric endpoints on `open.bohrium.com`:

- `/v1/mol-search/paper/search` — find **papers that reference a given molecule** (exact / similarity / substructure match)
- `/v1/molecular/search` — look up **molecular structure data**

**Use when**:

- You have a SMILES and want every paper that discusses it
- Substructure queries (family of molecules containing a functional group)
- Looking up structure data by molecule name / formula

**Don't use for**:

- General keyword paper search → `bohrium-paper-search`
- Crystal structure search → `bohrium-knowledge-base`

**No CLI support** — HTTP API only.

## Auth configuration

```json
"bohrium-mol-search": {
  "enabled": true,
  "apiKey": "YOUR_ACCESS_KEY",
  "env": {
    "ACCESS_KEY": "YOUR_ACCESS_KEY"
  }
}
```

## Common template

```python
import os, requests

AK = os.environ["ACCESS_KEY"]
BASE = "https://open.bohrium.com/openapi/v1"
H = {"accessKey": AK, "Content-Type": "application/json"}
```

---

## 1. Molecule-in-paper search — `mol-search/paper/search`

```python
r = requests.post(f"{BASE}/mol-search/paper/search", headers=H, json={
    "smiles": "c1ccccc1",          # input SMILES
    "search_type": "similarity",   # exact / similarity / substructure
    "limit": 10,
})
data = r.json()
print(data)
```

**Parameters:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `smiles` | string | required | SMILES string |
| `search_type` | enum | `similarity` | `exact` / `similarity` / `substructure` |
| `limit` | int | `10` | Max results |

**Match modes:**

- **exact** — identical molecule
- **similarity** — Tanimoto-ranked similar molecules plus their papers
- **substructure** — input appears as a substructure within larger molecules

---

## 2. Molecular structure lookup — `molecular/search`

```python
r = requests.post(f"{BASE}/molecular/search", headers=H, json={
    "query": "aspirin",           # name, SMILES, InChI, or formula
    "page": 1,
    "pageSize": 10,
})
print(r.json())
```

**Parameters:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `query` | string | required | Name / SMILES / InChI / formula |
| `page` | int | `1` | Page |
| `pageSize` | int | `10` | Page size |

---

## curl examples

```bash
AK="YOUR_ACCESS_KEY"

# Papers containing a benzene-like structure (similarity)
curl -s -X POST "https://open.bohrium.com/openapi/v1/mol-search/paper/search" \
  -H "accessKey: $AK" -H "Content-Type: application/json" \
  -d '{"smiles":"c1ccccc1","search_type":"similarity","limit":10}' | jq .

# Structure lookup for aspirin
curl -s -X POST "https://open.bohrium.com/openapi/v1/molecular/search" \
  -H "accessKey: $AK" -H "Content-Type: application/json" \
  -d '{"query":"aspirin","page":1,"pageSize":10}' | jq .
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| SMILES parse error | Malformed string | Canonicalize with rdkit first: `Chem.MolToSmiles(Chem.MolFromSmiles(s))` |
| Few similarity hits | Molecule rare in DB | Try `substructure` or `exact` search_type |
| `molecular/search` times out | Slow backend | Retry; make query more specific (SMILES > name) |

## Pairs well with

- **mol-search** to find papers referencing the molecule → **pdf-parser** to parse one or two in full
- **mol-search** to get a canonical molecule name → **paper-search** for synthesis route discussions
- Existing SMILES list → bulk literature mining via **mol-search**
