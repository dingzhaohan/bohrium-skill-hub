---
name: diagnose-agent
description: "Paper reproducibility diagnosis agent. Use when: user provides a paper (PDF/DOI/URL/title) and needs to assess reproducibility, feasibility, cost, and risks. Outputs a structured diagnosis report (Markdown + JSON). NOT for: planning reproduction steps, preparing environments, or scoring results."
---

# SKILL: 论文复现可行性诊断

对输入的论文（PDF/DOI/URL/标题）进行复现可行性诊断。先做前置筛选，通过后生成完整诊断报告（Markdown + JSON）；未通过则仅输出简短说明。聚焦"事实层"：客观梳理复现需要什么、可行性、成本、风险，每个判断证据驱动。

## 何时使用

- 用户提供论文（任意形式），需要评估可复现性或计划复现
- 需要人类可读的诊断报告与机器可读的 JSON

---

## 1. 输入解析

根据输入形式识别类型并选择工具，获取论文内容。

| 输入类型 | 首选工具 | 备选 | 说明 |
|---------|----------|------|------|
| PDF 文件 | `read` + `bohrium-pdf-parser` | - | 解析前检查是否已有解析结果 |
| DOI | `web_fetch` DOI resolver | `web_search` | 解析 DOI 获取元数据与全文链接 |
| arXiv URL | `web_fetch` arXiv API | 直接下载 PDF | 使用 arXiv API |
| 论文 URL | `web_fetch` | `web_search` | 抓取页面并提取信息 |
| 论文标题 | `bohrium-paper-search` | `web_search` | 搜索论文并取元数据 |

获取内容后，进行**信息提取**（元数据、研究问题、方法类型、结果形式）与**依赖分析**（六大类依赖及可用性）。

---

## 2. 前置筛选

**原则**：完整诊断前先做快速筛选。仅当筛选通过才生成完整诊断报告；未通过则只输出 `unreproducible_reason.md`。

### 筛选规则

- **5h 硬上限**：R0 累计耗时 >5h 则筛除
- **证据驱动**：耗时估算须有可引用证据或任务分解
- **置信度门控**：仅高/中置信度用于筛除；低置信度仅作风险提示

### R0 最小视图（筛选用）

| 任务 ID | 任务描述 | 耗时基准 | 关键依赖 |
|---------|----------|----------|----------|
| R0-1 | 搭建代码与环境 | 0.5-2h | Code, Environment |
| R0-2 | 端到端跑通（推理/预测） | 0.5-2h | Model, Code |
| R0-3 | 计算评估指标 | 0.2-0.5h | Evaluation |

总耗时上限：R0-1 + R0-2 + R0-3 <= 5h。

### 筛除判定（命中任一）

1. **数据未公开**：Data availability = `closed` 且无公开替代（高置信度）
2. **训练耗时 >5h**：需训练且无 checkpoint，预估 >5h（高/中置信度）
3. **R0 总耗时 >5h**：保守上界 >5h（至少一项高耗时任务置信度 >= 中）

### 置信度定义

| 级别 | 来源 | 筛除用途 |
|------|------|----------|
| 高 | 论文/代码/README 明确数字或描述 | 可用于筛除 |
| 中 | 基于方法类型、数据规模、领域常识的合理推断 | 可用于筛除 |
| 低 | 泛化猜测、无具体依据 | 仅风险提示 |

### 筛除输出

仅生成：`paper-diagnosis-reports/<paper_slug>/unreproducible_reason.md`

### 通过后

进入完整诊断：可行性评估、成本估算、风险识别，生成诊断报告（Markdown + JSON）。

---

## 3. 诊断报告内容

通过筛选后生成的诊断报告包含以下部分：

### 论文信息

标题、作者、发表年份与会议/期刊、DOI/arXiv/URL 等标识符。

### 研究概述

1-2 句概括研究问题；方法类型标签；主要结果形式。

### 依赖台账

六大类依赖：

| 类别 | 说明 |
|------|------|
| Data | 训练/测试数据集 |
| Code | 源代码、脚本 |
| Model | 预训练模型、超参数 |
| Evaluation | 评估指标、基准 |
| Environment | 框架、硬件 |
| ExternalConstraints | 商业软件、权限、仪器 |

每项标明可用性（`open` / `partial` / `closed` / `unknown`）及许可或约束。

### 可行性评估（R0 / R1 / R2）

| 级别 | 定义 |
|------|------|
| R0 | 能否跑通代码/基本验证（不要求结果一致） |
| R1 | 能否复现论文中报告的主要结果 |
| R2 | 能否深度复现或扩展 |

每级给出：可行性（yes/no/unknown）、难度、阻塞点、依据（证据编号）。

### 成本估算

计算资源（GPU*h）、工程工作量（人周）、数据处理工作量；标明置信度与不确定性。

### 关键风险

每条：影响、原因、引用证据。

### 证据清单

每条：证据编号、类型（paper/repo/web/inference）、来源、引用原文、获取时间。

### 分析元信息

报告生成时间、输入类型、使用工具、分析局限。

---

## 4. 诊断报告 Markdown 模板

```markdown
# 论文可复现性诊断报告

## 论文信息

- **标题**: [论文标题]
- **作者**: [作者列表]
- **发表**: [年份] - [会议/期刊]
- **标识符**:
  - DOI: [doi]
  - arXiv: [arxiv]
  - URL: [url]

---

## 研究概述

**研究问题**: [1-2句话总结]
**方法类型**: [标签1, 标签2, ...]
**主要结果**: [简要描述]

---

## 依赖台账

（按 Data / Code / Model / Evaluation / Environment / ExternalConstraints 六类列出）

---

## 可行性评估

（R0 / R1 / R2 各级：可行性、难度、阻塞点、依据）

---

## 成本估算

（计算资源、工程工作量、数据处理；置信度与不确定性说明）

---

## 关键风险

（每条：影响、原因、证据）

---

## 证据清单

（每条：类型、来源、引用内容、获取时间）

---

## 分析元信息

（生成时间、输入类型、使用工具、分析局限）

---

**免责声明**: 本报告基于公开信息和自动化分析生成，建议人工审核后使用。
```

---

## 5. JSON 格式定义

诊断报告的结构化等价形式，供自动化流程消费。

```json
{
  "paper": {
    "title": "",
    "year": null,
    "venue": "",
    "authors": [],
    "identifiers": { "doi": "", "arxiv": "", "url": "" }
  },
  "paper_card": {
    "research_question": "",
    "method_type": [],
    "primary_result_forms": []
  },
  "dependency_ledger": [
    {
      "category": "Data|Code|Model|Evaluation|Environment|ExternalConstraints",
      "item": "",
      "availability": "open|partial|closed|unknown",
      "license_or_constraint": "",
      "substitute": "",
      "evidence_ids": ["E1"]
    }
  ],
  "depth_feasibility": {
    "R0": { "feasible": "yes|no|unknown", "blocking": [], "difficulty": "low|medium|high|unknown", "evidence_ids": [] },
    "R1": {},
    "R2": {}
  },
  "budget_sketch": {
    "compute_range": "",
    "engineering_effort_range": "",
    "data_ops_range": "",
    "uncertainty_notes": ""
  },
  "top_risks": [
    { "risk": "", "impact": "", "why": "", "evidence_ids": [] }
  ],
  "evidence": [
    { "id": "E1", "type": "paper|repo|web|inference", "source": "", "quote": "", "retrieved_at": "" }
  ],
  "meta": {
    "generated_at": "",
    "input_type": "pdf|doi|url|title",
    "tooling": { "paper_retrieval": "", "web_fetch_used": true, "paper_search": "" },
    "limitations": []
  }
}
```

---

## 行为约束

### JSON 输出

- 所有判断必须有 `evidence_ids` 支撑
- 不确定就写 `unknown`，不编造信息
- `evidence_ids` 必须在 `evidence[]` 中存在

### Markdown 输出

- 与 JSON 一致，信息不矛盾
- 判断处引用证据编号（E1, E2, ...）

### 生成顺序

1. 先生成 Markdown
2. 再生成 JSON（与 Markdown 一致）
3. 验证一致性

---

## 错误处理

| 场景 | 处理 |
|------|------|
| 工具失败 | 记录到 `meta.limitations`，继续执行 |
| 内容不完整 | 标记为 `unknown`，说明原因 |
| 冲突信息 | 取最可靠来源，记录证据 |
| 无法获取论文 | 尝试多种方式，降级到搜索引擎，基于摘要分析 |
| 代码仓库搜索无结果 | 标记 Code 为 `unknown`，说明"未找到官方代码" |

---

## 依赖的 Skills

| Skill | 用途 | 是否必需 |
|-------|------|----------|
| `bohrium-paper-search` | 输入为标题时精确查询元数据 | 推荐 |
| `bohrium-pdf-parser` | 输入为 PDF 时解析为结构化文本 | 推荐 |
