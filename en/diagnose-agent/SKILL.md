---
name: diagnose-agent
description: "Paper reproducibility diagnosis agent. Use when: user provides a paper (PDF/DOI/URL/title) and needs to assess reproducibility, feasibility, cost, and risks. Outputs a structured diagnosis report (Markdown + JSON). NOT for: planning reproduction steps, preparing environments, or scoring results."
---

# SKILL: Paper Reproducibility Diagnosis

Diagnose reproducibility of a given paper (PDF/DOI/URL/title). Perform pre-screening first; if passed, generate a full diagnosis report (Markdown + JSON); if not, output only a brief explanation. Focus on the "fact layer": objectively identify what is needed for reproduction, feasibility, cost, and risks. Every judgment must be evidence-driven.

---

## When to Use

- User provides a paper (any form) and needs to assess reproducibility or plan reproduction
- Need both a human-readable diagnosis report and machine-readable JSON

---

## 1. Input Parsing

Identify input type and select tools to obtain paper content.

| Input Type | Primary Tool | Fallback | Notes |
|-----------|-------------|----------|-------|
| PDF file | `read` + `bohrium-pdf-parser` | - | Check for existing parsed results first |
| DOI | `web_fetch` DOI resolver | `web_search` | Resolve DOI for metadata and full text |
| arXiv URL | `web_fetch` arXiv API | Download PDF | Use arXiv API |
| Paper URL | `web_fetch` | `web_search` | Scrape page and extract info |
| Paper title | `bohrium-paper-search` | `web_search` | Search paper and get metadata |

After obtaining content, perform **information extraction** (metadata, research question, method type, result forms) and **dependency analysis** (six categories with availability).

---

## 2. Pre-screening

**Principle**: Quick screening before full diagnosis. Only generate a full report if screening passes; otherwise output only `unreproducible_reason.md`.

### Screening Rules

- **5h hard limit**: Screen out if R0 total time > 5h
- **Evidence-driven**: Time estimates must have citable evidence or task decomposition
- **Confidence gating**: Only high/medium confidence used for screening; low confidence is risk-flagged only

### R0 Minimum View (for screening)

| Task ID | Description | Time Baseline | Key Dependencies |
|---------|------------|---------------|------------------|
| R0-1 | Set up code and environment | 0.5-2h | Code, Environment |
| R0-2 | End-to-end run (inference/prediction) | 0.5-2h | Model, Code |
| R0-3 | Compute evaluation metrics | 0.2-0.5h | Evaluation |

Total time limit: R0-1 + R0-2 + R0-3 <= 5h.

### Screen-out Criteria (any match)

1. **Data not public**: Data availability = `closed` with no public substitute (high confidence)
2. **Training time > 5h**: Training required with no checkpoint, estimated > 5h (high/medium confidence)
3. **R0 total > 5h**: Conservative upper bound > 5h (at least one high-cost task with >= medium confidence)

### Confidence Levels

| Level | Source | Screening Use |
|-------|--------|---------------|
| High | Explicit numbers or descriptions in paper/code/README | Can be used for screening |
| Medium | Reasonable inference from method type, data scale, domain knowledge | Can be used for screening |
| Low | Generalized guesses, no specific basis | Risk flagging only |

### Screen-out Output

Generate only: `paper-diagnosis-reports/<paper_slug>/unreproducible_reason.md`

### After Passing

Proceed to full diagnosis: feasibility assessment, cost estimation, risk identification, generate report (Markdown + JSON).

---

## 3. Diagnosis Report Content

The full report includes:

### Paper Info

Title, authors, publication year and venue, DOI/arXiv/URL identifiers.

### Research Overview

1-2 sentence summary; method type tags; primary result forms.

### Dependency Ledger

Six categories:

| Category | Description |
|----------|------------|
| Data | Training/test datasets |
| Code | Source code, scripts |
| Model | Pre-trained models, hyperparameters |
| Evaluation | Metrics, benchmarks |
| Environment | Frameworks, hardware |
| ExternalConstraints | Commercial software, permissions, instruments |

Each item marked with availability (`open` / `partial` / `closed` / `unknown`) and license/constraints.

### Feasibility Assessment (R0 / R1 / R2)

| Level | Definition |
|-------|-----------|
| R0 | Can the code run / basic verification (results don't need to match) |
| R1 | Can the main results reported in the paper be reproduced |
| R2 | Can the work be deeply reproduced or extended |

Each level: feasibility (yes/no/unknown), difficulty, blockers, evidence IDs.

### Cost Estimate

Compute resources (GPU*h), engineering effort (person-weeks), data processing effort; with confidence and uncertainty notes.

### Key Risks

Each: impact, reason, evidence references.

### Evidence List

Each: evidence ID, type (paper/repo/web/inference), source, quoted text, retrieval time.

### Analysis Metadata

Report generation time, input type, tools used, analysis limitations.

---

## 4. Markdown Report Template

```markdown
# Paper Reproducibility Diagnosis Report

## Paper Info

- **Title**: [Paper title]
- **Authors**: [Author list]
- **Published**: [Year] - [Venue]
- **Identifiers**:
  - DOI: [doi]
  - arXiv: [arxiv]
  - URL: [url]

---

## Research Overview

**Research Question**: [1-2 sentence summary]
**Method Type**: [tag1, tag2, ...]
**Primary Results**: [Brief description]

---

## Dependency Ledger

(Listed by Data / Code / Model / Evaluation / Environment / ExternalConstraints)

---

## Feasibility Assessment

(R0 / R1 / R2: feasibility, difficulty, blockers, evidence)

---

## Cost Estimate

(Compute, engineering effort, data processing; confidence and uncertainty)

---

## Key Risks

(Each: impact, reason, evidence)

---

## Evidence List

(Each: type, source, quoted content, retrieval time)

---

## Analysis Metadata

(Generation time, input type, tools used, limitations)

---

**Disclaimer**: This report is generated based on public information and automated analysis. Manual review is recommended before use.
```

---

## 5. JSON Schema

Structured equivalent of the diagnosis report for automated pipelines.

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

## Behavioral Constraints

### JSON Output

- All judgments must have `evidence_ids` support
- Use `unknown` when uncertain; never fabricate information
- All `evidence_ids` must exist in `evidence[]`

### Markdown Output

- Consistent with JSON, no contradictions
- Reference evidence IDs (E1, E2, ...) at judgment points

### Generation Order

1. Generate Markdown first
2. Generate JSON (consistent with Markdown)
3. Verify consistency

---

## Error Handling

| Scenario | Handling |
|----------|---------|
| Tool failure | Record in `meta.limitations`, continue |
| Incomplete content | Mark as `unknown`, explain reason |
| Conflicting info | Use most reliable source, record evidence |
| Cannot obtain paper | Try multiple methods, fall back to search engine, analyze from abstract |
| No code repo found | Mark Code as `unknown`, note "no official code found" |

---

## Dependent Skills

| Skill | Purpose | Required |
|-------|---------|----------|
| `bohrium-paper-search` | Search paper metadata when input is title | Recommended |
| `bohrium-pdf-parser` | Parse PDF into structured text | Recommended |
