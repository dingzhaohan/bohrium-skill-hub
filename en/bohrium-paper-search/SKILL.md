---
name: bohrium-paper-search
description: "Search academic papers and patents via openapi.dp.tech RAG engine. Use when: user asks about searching/finding academic papers, literature review, patent search, or technical survey using keywords or natural language questions. NOT for: knowledge base management, file management, or dataset operations."
---

# SKILL: Bohrium Paper & Patent Search

## Overview

Search academic papers and patents using the Bohrium RAG search engine. Combines keyword matching with semantic understanding, supporting natural language queries, date range filtering, JCR zone/database filtering, and AI reranking.

**Supported Search Types:**

| Type | Endpoint | Corpus |
|------|----------|--------|
| English papers | `/paper/rag/pass/keyword` | English academic papers (title, abstract, corpus, figures) |
| Patents | `/paper/rag/pass/patent` | Global patents (with classification, assignee filtering) |

**Use cases:** Literature review, technical survey, method comparison, trend analysis.

**No CLI support** — all operations use the HTTP API.

## Authentication

ACCESS_KEY is read from the OpenClaw config `~/.openclaw/openclaw.json`:

```json
"bohrium-paper-search": {
  "enabled": true,
  "apiKey": "YOUR_ACCESS_KEY",
  "env": {
    "ACCESS_KEY": "YOUR_ACCESS_KEY"
  }
}
```

OpenClaw automatically injects `env.ACCESS_KEY` into the runtime.

## Common Code Template

```python
import os, requests

AK = os.environ.get("ACCESS_KEY", "")
BASE = "https://openapi.dp.tech/openapi/v1/paper"
HEADERS_JSON = {"accessKey": AK, "Content-Type": "application/json"}
```

---

## English Paper Search

### Basic Search

```python
r = requests.post(f"{BASE}/rag/pass/keyword", headers=HEADERS_JSON, json={
    "words": ["deep learning", "molecular dynamics"],
    "question": "How to use deep learning for molecular dynamics simulation?",
    "startTime": "",
    "endTime": "",
    "pageSize": 10
})
data = r.json()
print(f"Found {len(data['data'])} papers")
for p in data["data"]:
    print(f"  [{p['doi']}] {p['enName']}")
    print(f"    Journal: {p.get('publicationEnName', '')}, IF: {p.get('impactFactor', 0)}")
    print(f"    Date: {p['coverDateStart']}, Citations: {p['citationNums']}")
```

### Advanced Search (Date Range + JCR Zone + Database + Type)

```python
r = requests.post(f"{BASE}/rag/pass/keyword", headers=HEADERS_JSON, json={
    "words": ["deep learning", "protein structure"],
    "question": "deep learning protein structure prediction",
    "type": 5,                          # Search version (see below)
    "startTime": "2024-01-01",          # Start date YYYY-MM-DD
    "endTime": "2025-01-01",            # End date
    "jcrZones": ["Q1", "Q2"],           # JCR zone filter
    "includeDbs": ["SCI"],              # Database filter
    "areaIds": [],                      # Area IDs (optional)
    "publicationIds": [],               # Publication IDs (optional)
    "pageSize": 20
})
```

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `words` | string[] | Yes | Keyword list; recommend 3-8 English terms |
| `question` | string | Yes | Natural language research question |
| `type` | integer | No | Search version: 0=basic, 1=enhanced, 2=pro, 3=pro2.0, 4=image, 5=title+abstract+corpus+image+target |
| `startTime` | string | No | Start date `YYYY-MM-DD`, empty string for no limit |
| `endTime` | string | No | End date `YYYY-MM-DD` |
| `jcrZones` | string[] | No | JCR zone filter, e.g. `["Q1","Q2"]` |
| `includeDbs` | string[] | No | Database filter, e.g. `["SCI","SSCI"]` |
| `areaIds` | string[] | No | Area IDs |
| `publicationIds` | number[] | No | Publication IDs |
| `subjectIds` | number[] | No | Subject IDs |
| `pageSize` | integer | Yes | Result count, 1-100, default 50 |

### Response Fields

| Field | Description |
|-------|-------------|
| `code` | 0=success |
| `message` | Status message |
| `data[]` | Paper list |
| `data[].doi` | DOI |
| `data[].paperId` | Paper ID |
| `data[].enName` | English title |
| `data[].zhName` | Chinese title |
| `data[].enAbstract` | English abstract |
| `data[].zhAbstract` | Chinese abstract |
| `data[].authors` | Author list |
| `data[].coverDateStart` | Publication date |
| `data[].publicationEnName` | Journal name |
| `data[].publicationCover` | Journal cover URL |
| `data[].impactFactor` | Impact factor |
| `data[].citationNums` | Citation count |
| `data[].popularity` | Popularity score |
| `data[].pieces` | Related corpus snippet |
| `data[].figures[]` | Related figures (`figureId`, `imageUrl`, `enExplain`) |
| `data[].languageType` | 0=English |

---

## Patent Search

```python
r = requests.post(f"{BASE}/rag/pass/patent", headers=HEADERS_JSON, json={
    "words": ["neural network", "training"],
    "question": "neural network training optimization",
    "type": 3,                              # 0=basic, 1=enhanced, 2=pro, 3=premium
    "rerank": 1,                            # 0=no rerank, 1=rerank
    "assignees": [],                        # Assignees (multiple = AND)
    "examiners": [],                        # Examiners
    "publicationDateRange": {               # Publication date range
        "start": "2020-01-01",
        "end": "2025-01-01"
    },
    "pageSize": 10
})
data = r.json()
for p in data["data"]:
    title = p.get("title", {})
    print(f"  [{p['patentId']}] {title.get('enName', '')}")
    print(f"    Status: {p['status']}, Assignees: {p.get('assignees', [])}")
    print(f"    IPC: {p.get('ipcs', [])}, Year: {p.get('publicationYear')}")
```

### Patent Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `words` | string[] | Yes | Keywords |
| `question` | string | Yes | Search question |
| `type` | integer | No | 0=basic, 1=enhanced, 2=pro, 3=premium |
| `rerank` | integer | No | 0=no rerank, 1=rerank |
| `assignees` | string[] | No | Patent assignees (multiple = AND) |
| `currentAssignees` | string[] | No | Current assignees |
| `examiners` | string[] | No | Examiners |
| `uspcs` | string[] | No | US patent classification (multiple = OR) |
| `ipcs` | string[] | No | International patent classification (multiple = OR) |
| `cpcs` | string[] | No | Cooperative patent classification (multiple = OR) |
| `fis` | string[] | No | FI classification |
| `fterms` | string[] | No | F-term classification |
| `locarnos` | string[] | No | Locarno classification |
| `publicationDateRange` | object | No | Date range `{start, end}` (YYYY-MM-DD) |
| `publicationYearRange` | object | No | Year range `{start, end}` (integer) |
| `pageSize` | integer | Yes | Result count |

### Patent Response Fields

| Field | Description |
|-------|-------------|
| `data[].patentId` | Patent ID (e.g. `US2022327730A1`) |
| `data[].publicationNumber` | Publication number |
| `data[].publicationDate` | Publication date |
| `data[].language` | Language |
| `data[].assignees` | Assignee list |
| `data[].status` | Status (Active / Pending etc.) |
| `data[].title` | Title `{enName, zhName, originName}` |
| `data[].abstracts` | Abstract `{enName, zhName, originName}` |
| `data[].ipcs` | IPC classification list |
| `data[].publicationYear` | Publication year |
| `data[].filingYear` | Filing year |
| `data[].applicationKind` | Patent type (A=published app, B=granted, U=utility model, D=design etc.) |
| `data[].pieces` | Related corpus |

---

## Search Tips

### Keyword Selection

```python
# GOOD: 3-8 professional terms
words = ["molecular dynamics", "force field", "deep potential", "neural network"]

# BAD: Too generic
words = ["science", "research"]
```

### Combine question for Better Relevance

`words` is for exact keyword matching, `question` is for semantic understanding. Best results come from combining both:

```python
{
    "words": ["GNN", "molecular property", "prediction"],
    "question": "How do graph neural networks predict molecular properties?",
    "pageSize": 20
}
```

### Filter for High-Quality Journals

```python
{
    "words": ["..."],
    "question": "...",
    "jcrZones": ["Q1"],          # Q1 journals only
    "includeDbs": ["SCI"],       # SCI-indexed only
    "startTime": "2023-01-01",   # Recent 2 years
    "endTime": "2025-12-31"
}
```

---

## curl Examples

```bash
AK="YOUR_ACCESS_KEY"
BASE="https://openapi.dp.tech/openapi/v1/paper"

# English paper search
curl -s -X POST "$BASE/rag/pass/keyword" \
  -H "Content-Type: application/json" \
  -H "accessKey: $AK" \
  -d '{"words":["deep learning","protein"],"question":"deep learning protein structure prediction","type":5,"startTime":"2024-01-01","endTime":"2025-01-01","jcrZones":["Q1"],"pageSize":5}'

# Patent search
curl -s -X POST "$BASE/rag/pass/patent" \
  -H "Content-Type: application/json" \
  -H "accessKey: $AK" \
  -d '{"words":["neural network"],"question":"neural network training","type":3,"rerank":1,"pageSize":5}'
```

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `code` is non-zero | Request parameter error | Check `message` field for details |
| 401 Unauthorized | Invalid accessKey | Verify ACCESS_KEY is correct |
| Irrelevant results | Keywords too generic or vague question | Use 3-8 professional terms + clear question |
| Empty results | Date range too narrow or filters too strict | Widen startTime/endTime or remove jcrZones |
| Response has multiple JSON lines | Normal behavior (streaming) | Parse first line only: `json.loads(response.text.split('\n')[0])` |
| Patent pieces empty | Some patents lack corpus indexing | Normal; use `abstracts` for content instead |
