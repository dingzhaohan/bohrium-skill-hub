---
name: bohrium-mol-search
description: "Molecular structure and molecule-in-paper search via open.bohrium.com. Use when: user asks about finding papers that mention a specific molecule (by SMILES / InChI / formula / name), performing substructure or similarity molecule search, or querying molecular structure data. NOT for: general paper search (use bohrium-paper-search), crystal structures in knowledge base (use bohrium-knowledge-base)."
---

# SKILL: Bohrium 分子检索

## 概述

通过 `open.bohrium.com` 的两组端点做分子相关检索：

- `/v1/mol-search/paper/search` — 搜索**含特定分子**的论文（支持 exact / similarity / substructure 三种匹配模式）
- `/v1/molecular/search` — 查询**分子结构**数据

**典型场景**：

- 拿到一个 SMILES 想找所有讨论它的论文
- 做子结构检索（含某个官能团的分子家族）
- 拿分子名字/式子反查结构数据

**不适用**：

- 通用关键词论文搜索 → `bohrium-paper-search`
- 晶体结构检索 → `bohrium-knowledge-base`

**无 CLI 支持** — 通过 HTTP API 操作。

## 认证配置

```json
"bohrium-mol-search": {
  "enabled": true,
  "apiKey": "YOUR_ACCESS_KEY",
  "env": {
    "ACCESS_KEY": "YOUR_ACCESS_KEY"
  }
}
```

## 通用代码模板

```python
import os, requests

AK = os.environ["ACCESS_KEY"]
BASE = "https://open.bohrium.com/openapi/v1"
H = {"accessKey": AK, "Content-Type": "application/json"}
```

---

## 1. 分子论文检索 — `mol-search/paper/search`

```python
r = requests.post(f"{BASE}/mol-search/paper/search", headers=H, json={
    "smiles": "c1ccccc1",          # 输入 SMILES
    "search_type": "similarity",   # exact / similarity / substructure
    "limit": 10,                   # 返回数上限
})
data = r.json()
print(data)
```

**参数**：

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `smiles` | string | 必填 | SMILES 字符串 |
| `search_type` | enum | `similarity` | `exact`（精确）/ `similarity`（相似）/ `substructure`（子结构） |
| `limit` | int | `10` | 最大返回结果数 |

**三种匹配模式**：

- **exact** — 完全相同的分子
- **similarity** — Tanimoto 相似度，会返回排序后的相似分子及其论文
- **substructure** — 输入作为子结构出现在更大分子中

---

## 2. 分子结构查询 — `molecular/search`

```python
r = requests.post(f"{BASE}/molecular/search", headers=H, json={
    "query": "aspirin",           # 分子名、SMILES、InChI 或分子式均可
    "page": 1,
    "pageSize": 10,
})
print(r.json())
```

**参数**：

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `query` | string | 必填 | 分子名 / SMILES / InChI / 分子式 |
| `page` | int | `1` | 页码 |
| `pageSize` | int | `10` | 每页数量 |

---

## curl 示例

```bash
AK="YOUR_ACCESS_KEY"

# 含苯环的论文（相似度匹配）
curl -s -X POST "https://open.bohrium.com/openapi/v1/mol-search/paper/search" \
  -H "accessKey: $AK" -H "Content-Type: application/json" \
  -d '{"smiles":"c1ccccc1","search_type":"similarity","limit":10}' | jq .

# 查询 aspirin 的结构数据
curl -s -X POST "https://open.bohrium.com/openapi/v1/molecular/search" \
  -H "accessKey: $AK" -H "Content-Type: application/json" \
  -d '{"query":"aspirin","page":1,"pageSize":10}' | jq .
```

---

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| SMILES 解析失败 | 字符串格式错误 | 用 rdkit 预先规范化：`Chem.MolToSmiles(Chem.MolFromSmiles(s))` |
| 相似度结果太少 | 数据库中该分子少见 | 把 `search_type` 切换为 `substructure` 或 `exact` 试试 |
| `molecular/search` 超时 | 内部服务请求慢 | 稍等重试；query 写得更具体（SMILES > 分子名） |

## 搭配使用

- **mol-search** 找到提及该分子的论文 → **pdf-parser** 解析其中一两篇感兴趣的全文
- **mol-search** 拿到分子名 → **paper-search** 搜索对其合成路线的讨论
- 实验室已有一个 SMILES 数据库 → 用 **mol-search** 批量挖掘相关文献
