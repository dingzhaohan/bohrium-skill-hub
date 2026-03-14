---
name: proposal-agent
description: "Paper reproduction proposal planning skill. Use when: user wants to plan a paper reproduction, create a step-by-step reproduction plan, or break down R0/R1/R2 reproduction tasks. Outputs a Markdown reproduction plan. NOT for: diagnosing reproducibility, preparing environments, or scoring results."
---

# SKILL: Paper Reproduction Proposal Planning

Interact with the user to understand the target paper, then break down an R0 / R1 / R2 three-level reproduction plan and output it as a Markdown file.

---

## When to Use

When the user mentions "reproduction plan", "reproduction proposal", "paper reproduction" or similar scenarios requiring step-by-step reproduction planning.

## PDF Parsing

If PDF parsing is needed, use `bohrium-pdf-parser`. Check the workspace for existing parsed results (`.md`, `.txt`, `.json`) before parsing to avoid duplication.

---

## Conversation Flow

```
1. Ask user for the paper to reproduce (title, link, or keywords)
2. Understand the paper's core content (method, dataset, main results)
3. Break down into R0 / R1 / R2 three-level reproduction plan
4. Save the plan as a Markdown file
5. Display the full plan to the user in the interface
```

---

## R0 / R1 / R2 Definitions

### R0 - Run the Code

Core goal: Get the code running, regardless of result accuracy.

1. **Obtain data** - Get data (sample or subset), confirm it loads correctly
2. **Build runnable code** - Set up environment, install dependencies, code runs
3. **Produce correct output format** - End-to-end run, output format matches expectations (values don't need to be correct)
4. **Compute evaluation metrics** - Evaluation script runs, metrics computed (don't need to meet targets)

Acceptance criteria: Data obtained, code runs, output format correct, metrics computed.

### R1 - Reproduce Paper Results

Core goal: Reproduce the experimental results reported in the paper (figures, values, performance metrics).

1. Prepare complete dataset
2. Configure hyperparameters per paper settings, full training or load pre-trained weights
3. Reproduce each reported experimental result
4. Compare with paper values, analyze error sources

Acceptance criteria: Main experimental results reproduced within reasonable error margins.

### R2 - Deep Reproduction

Core goal: Address remaining problems in the paper, implement unfinished improvements.

1. Identify Future Work from the paper
2. Analyze limitations of existing methods, design improvement plans
3. Implement algorithm improvements, attempt performance gains
4. Compare with R1 baseline, validate improvement effects

Acceptance criteria: At least one improvement direction has experimental results compared against R1 baseline.

---

## Information Requirements

| Information | Description | Required |
|------------|------------|----------|
| Paper title or link | Identify the target paper | Yes |
| Core method | Understand what the paper does | Yes |
| Code repository | Whether official code exists | Recommended |
| Dataset | What data is used | Recommended |
| Target depth | Which level: R0 / R1 / R2 | Optional |

---

## Output Requirements

### Save Path

- Default: `~/proposal-<paper-slug>.md`
- If paper-specific directory exists: `~/paper-diagnosis-reports/<PaperName>/proposal.md`

### Markdown Template

```markdown
# Paper Reproduction Plan

## Paper Info

- **Title**: <Paper title>
- **Link**: <Paper link>
- **Core Method**: <One-sentence summary>

---

## R0 - Run the Code

**Goal**: Get the code pipeline running, results don't need to be accurate

| # | Task | Description |
|---|------|------------|
| 1 | Obtain data | <Data source, acquisition method, format> |
| 2 | Build runnable code | <Environment setup, dependencies, framework versions> |
| 3 | Run pipeline and output | <Entry script, run command, expected output format> |
| 4 | Compute evaluation metrics | <Evaluation script, metric types, confirm metrics computed> |

**Acceptance**: Data obtained, code runs, output format correct, metrics computed

---

## R1 - Reproduce Paper Results

**Goal**: Reproduce experimental results from the paper
**Prerequisite**: R0 passed

| # | Task | Description |
|---|------|------------|
| 1 | Full data preparation | <Complete dataset acquisition and preprocessing> |
| 2 | Model training/loading | <Training config, hyperparameters, pre-trained weights> |
| 3 | Reproduce each result | <Specific Table/Figure/metric list to reproduce> |
| 4 | Error analysis | <Result comparison, error source analysis> |

**Acceptance**: Main experimental results match paper within reasonable error

---

## R2 - Deep Reproduction

**Goal**: Address remaining problems, attempt improvements
**Prerequisite**: R1 passed

| # | Task | Description |
|---|------|------------|
| 1 | Identify improvement directions | <Specific directions from Future Work / Limitations> |
| 2 | Design improvement plan | <Improvement approach and implementation plan> |
| 3 | Implement and experiment | <Code changes, experiment configuration> |
| 4 | Comparative analysis | <Compare with R1 baseline, quantify improvements> |

**Acceptance**: At least one improvement direction has experimental results compared to baseline
```

### Display

After saving the file, output the full Markdown content to the interactive interface.

---

## Constraints

- Planning only, no actual reproduction execution
- Do not expose user private data
