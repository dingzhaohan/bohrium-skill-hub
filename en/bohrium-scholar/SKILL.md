---
name: bohrium-scholar
description: "Scholar profile lookup via open.bohrium.com. Use when: user asks about finding a researcher's profile, h-index, citations, education/work background, or searching scholars by name/affiliation/research tags. NOT for: paper content search (use bohrium-paper-search), knowledge base (use bohrium-knowledge-base)."
---

# SKILL: Bohrium Scholar Lookup

## Overview

Query scholar profiles through Bohrium OpenAPI (`open.bohrium.com`) via two endpoints:

| Endpoint | Method | Path | Purpose |
|----------|--------|------|---------|
| Scholar search | POST | `/openapi/v1/paper-server/scholar/search` | Find candidates by name / affiliation / research tag |
| Scholar info   | GET  | `/openapi/v1/paper-server/scholar/info?scholarId=xxx` | Fetch full profile by scholarId |

**Typical flow**: name input → search candidate list → pick `scholarId` → fetch full profile (publications, citations, h-index, research directions, education / work history).

**Not for**:

- Paper-content search → `bohrium-paper-search`
- PDF full-text reading → `bohrium-pdf-parser`

## Configuration

```json
"bohrium-scholar": {
  "enabled": true,
  "apiKey": "YOUR_ACCESS_KEY",
  "env": {
    "ACCESS_KEY": "YOUR_ACCESS_KEY"
  }
}
```

## Shared code template

```python
import os, requests

AK = os.environ["ACCESS_KEY"]
BASE = "https://open.bohrium.com/openapi/v1/paper-server"
HEADERS_JSON = {"accessKey": AK, "Content-Type": "application/json"}
HEADERS = {"accessKey": AK}
```

---

## Standard workflow

```
User question about a scholar
  ├─ scholarId known → call Scholar Info directly
  └─ scholarId unknown → call Scholar Search first
       └─ pick items[].scholarId → call Scholar Info
```

---

## 1. Scholar search — `POST /scholar/search`

### Basic

```python
r = requests.post(f"{BASE}/scholar/search", headers=HEADERS_JSON, json={
    "name": "Yann LeCun",
    "page": 1,
    "pageSize": 5,
})
for item in r.json()["data"]["items"]:
    print(f"[{item['scholarId']}] {item.get('nameEn','')} / {item.get('nameZh','')}")
    print(f"  Org: {item.get('scholarOrgNameEn','')}")
    print(f"  Papers: {item.get('paperNums',0)}, Citations: {item.get('citationNums',0)}, h-index: {item.get('hIndex',0)}")
```

### With filters

```python
r = requests.post(f"{BASE}/scholar/search", headers=HEADERS_JSON, json={
    "name": "Zhang",
    "school": "Tsinghua University",
    "affiliation": "Tsinghua University",
    "tags": "machine learning",
    "page": 1,
    "pageSize": 10,
})
```

### Parameters

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | yes | Scholar name (1–99 chars) |
| `school` | string | no | School / institution |
| `tags` | string | no | Research interest tag |
| `affiliation` | string | no | English affiliation name |
| `affiliationZh` | string | no | Chinese affiliation name |
| `page` | int | no | Default 1 |
| `pageSize` | int | no | Default 10 |

### Response key fields (`data.items[]`)

| Field | Meaning |
|-------|---------|
| `scholarId` | Unique id — required for info call |
| `nameEn` / `nameZh` | Names |
| `paperNums` | Publications count |
| `citationNums` | Citations total |
| `hIndex` | h-index |
| `scholarOrgNameEn` / `scholarOrgNameZh` | Affiliation |
| `isHighCited` | Highly-cited flag |

---

## 2. Scholar info — `GET /scholar/info`

```python
r = requests.get(
    f"{BASE}/scholar/info",
    headers=HEADERS,
    params={"scholarId": scholar_id},
)
info = r.json()["data"]
print(info.get("nameEn"), "|", info.get("nameZh"))
print("Research:", info.get("researchDirection"))
print("Education:", info.get("educationBackgroundEn") or info.get("educationBackground"))
print("Work:", info.get("workExperienceEn") or info.get("workExperience"))
```

### Extra fields (vs search)

| Field | Meaning |
|-------|---------|
| `researchDirection` | Research direction list |
| `educationBackground` / `educationBackgroundEn` / `educationBackgroundZh` | Education history |
| `workExperience` / `workExperienceEn` / `workExperienceZh` | Work history |

---

## Presentation tips

Format a concise scholar card:

- **Names**: `nameEn` / `nameZh`
- **Affiliation**: `scholarOrgNameEn` / `scholarOrgNameZh`
- **Metrics**: `paperNums` / `citationNums` / `hIndex`
- **Highly cited**: `isHighCited`
- **Research**: `researchDirection`
- **Education / work**: prefer localized variant (Zh / En) when present

When search returns multiple candidates, list them as a short table first, then fetch full info only after the user confirms the target.

---

## curl

```bash
AK="$ACCESS_KEY"
BASE="https://open.bohrium.com/openapi/v1/paper-server"

# Step 1: search
curl -s -X POST "$BASE/scholar/search" \
  -H "accessKey: $AK" -H "Content-Type: application/json" \
  -d '{"name":"Yann LeCun","page":1,"pageSize":3}'

# Step 2: info
curl -s -G "$BASE/scholar/info" \
  -H "accessKey: $AK" \
  --data-urlencode "scholarId=SCHOLAR_ID"
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `search` returns empty `items` | Spelling / no match | Try common English spelling; add `school` to narrow down |
| `401` / `AccessKey is required` | Wrong header name | Use `accessKey` (lowercase first letter), not `Authorization` |
| `info` missing fields | Scholar hasn't filled profile | Render only fields that exist; don't assume completeness |

## Pairs well with

- **scholar** to pick a target → **paper-search** to explore their publications and citation graph
- `researchDirection` from **scholar** → keyword queries for **paper-search** / **web-search**
- Paper DOIs from **scholar** → **pdf-parser** to extract full-text content
