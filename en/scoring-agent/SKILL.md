---
name: scoring-agent
description: "Paper reproduction scoring skill. Use when: user needs to evaluate reproduction quality, score an ARM package, or assess reproduction results with 4C dimensions. Orchestrates execution/rubric/grading subagents. NOT for: initial reproduction, diagnosis, environment preparation, or planning."
---

# SKILL: Paper Reproduction Scoring

Systematically score reproduced literature (ARM packages). Orchestrate three subagents (execution / rubric / grading) to complete execution assessment, rubric construction, and grading.

---

## When to Use

When the user mentions "reproduction scoring", "evaluate reproduction quality", "score", "assess reproduction results", or needs quality evaluation of an ARM package.

---

## Input Requirements

### Required Materials

1. **ARM package path** - Directory containing complete reproduction materials
   - `notebook.ipynb` - Reproduction Jupyter notebook
   - `paper.pdf` - Original paper
   - `todolist.md` - Reproduction task checklist

2. **Scoring session configuration**
   - Session directory name (default: `scoring_<timestamp>/`)
   - Output path (default: current working directory)

### Optional Materials

- Custom scoring rubric (if not provided, rubric agent generates one automatically)
- Special execution parameters (timeout, resource limits, etc.)

---

## Scoring Dimensions (4C)

| Dimension | Description | Default Weight |
|-----------|------------|----------------|
| Completeness | Completeness of reproduction tasks, coverage of all required experiments | 0.3 |
| Correctness | Result accuracy, consistency with paper values | 0.4 |
| Clarity | Code and documentation clarity, readability and maintainability | 0.2 |
| Cost | Compute cost efficiency, reasonable resource usage | 0.1 |

---

## Workflow

### Phase 1: Prepare Scoring Workspace

Create a structured scoring session directory:

```
scoring_<timestamp>/
├── inputs/
│   ├── arm/              # ARM package copy or symlink
│   ├── paper.pdf         # Paper PDF
│   └── todolist.md       # Task checklist
├── outputs/
│   ├── execution_report.json    # execution agent output
│   ├── rubric.json              # rubric agent output
│   ├── grading_details.json     # grading agent detailed scores
│   └── final_score_card.json    # final score card
└── metadata.json         # Session metadata
```

### Phase 2: Parallel Dispatch of Execution and Rubric Agents

**Execution Agent** and **Rubric Agent** can run in parallel (no dependencies).

#### Execution Agent

Execute the ARM notebook, record each cell's run status.

Output `execution_report.json`:

```json
{
  "status": "completed",
  "cells": [
    {
      "cell_id": 1,
      "status": "success",
      "execution_time_ms": 1234,
      "output_preview": "..."
    },
    {
      "cell_id": 2,
      "status": "error",
      "error_message": "ModuleNotFoundError: No module named 'torch'",
      "traceback": "..."
    }
  ],
  "summary": {
    "total_cells": 10,
    "success": 7,
    "failed": 2,
    "timeout": 1
  }
}
```

#### Rubric Agent

Build scoring rubric from paper and todolist (4C dimensions).

Output `rubric.json`:

```json
{
  "levels": {
    "R0": {
      "completeness": ["..."],
      "correctness": ["..."],
      "clarity": ["..."],
      "cost": ["..."]
    },
    "R1": {},
    "R2": {}
  },
  "weights": {
    "completeness": 0.3,
    "correctness": 0.4,
    "clarity": 0.2,
    "cost": 0.1
  }
}
```

### Phase 3: Wait and Verify Phase 2 Completion

- Monitor both subagents' execution status
- Verify output files exist and have correct format

### Phase 4: Dispatch Grading Agent

Grading Agent **depends on** Execution and Rubric outputs, must run after Phase 2 completes.

Grade each item based on execution report and rubric, output `final_score_card.json`:

```json
{
  "overall_score": 78.5,
  "level_scores": {
    "R0": 85.0,
    "R1": 75.0,
    "R2": 60.0
  },
  "dimension_scores": {
    "completeness": 80,
    "correctness": 85,
    "clarity": 70,
    "cost": 75
  },
  "key_findings": [
    "R0 mostly complete, 7/10 cells executed successfully",
    "R1 results partially reproduced, main metric deviation <5%",
    "R2 extension experiments missing dataset B tests"
  ],
  "improvement_suggestions": [
    "Add missing dependencies: torch, transformers",
    "Fix path errors in data preprocessing script",
    "Add test cases for dataset B"
  ]
}
```

### Phase 5: Summary and Presentation

Read `final_score_card.json` and present to user:

1. **Overall and level scores** - Quick quality overview
2. **Dimension analysis** - 4C dimension performance
3. **Key findings** - Specific successes and failures
4. **Improvement suggestions** - Actionable optimization directions

Presentation format example:

```markdown
## Reproduction Scoring Results

**Overall Score**: 78.5 / 100

### Level Scores
- R0 (Run Code): 85.0
- R1 (Reproduce Results): 75.0
- R2 (Deep Extension): 60.0

### Dimension Analysis
- Completeness: 80
- Correctness: 85
- Clarity: 70
- Cost: 75

### Key Findings
- R0 mostly complete, 7/10 cells executed successfully
- R1 results partially reproduced, main metric deviation <5%
- R2 extension experiments missing dataset B tests

### Improvement Suggestions
1. Add missing dependencies: torch, transformers
2. Fix path errors in data preprocessing script
3. Add test cases for dataset B
```

For detailed evidence behind each rubric item's score, refer to `grading_details.json`.

---

## Error Handling

| Scenario | Handling |
|----------|---------|
| Subagent dispatch failure | Record error in `metadata.json`, report failure reason to user |
| Subagent execution timeout | Check subagent status, read partial output if available |
| Missing or malformed output files | Check subagent logs, report and decide whether to degrade gracefully |
| Incomplete ARM package materials | Clearly state which materials are missing, suggest corresponding skills to complete them |

---

## Prerequisites

- ARM package organized
- Notebook generated
- Todolist created (can be generated by diagnose-agent)

---

## Constraints

- Scoring only, do not modify ARM package contents
- Scoring results must be objective and traceable, each score backed by evidence
- Do not expose user private data
