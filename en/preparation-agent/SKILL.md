---
name: preparation-agent
description: "Paper reproduction environment preparation skill. Use when: user needs to prepare reproduction environment, download code/data/models, install dependencies, or set up the workspace for a paper. NOT for: diagnosing reproducibility, planning reproduction steps, or scoring results."
---

# SKILL: Paper Reproduction Environment Preparation

Based on a paper PDF or diagnosis report (from Diagnose Agent), automatically download and prepare all resources needed for reproduction (code, data, model weights, dependencies), then report the preparation results and directory structure to the user.

> **Important**: This stage only handles **downloading and configuring existing resources** (open-source code, public datasets, pre-trained weights, dependency installation). If the paper has no open-source code, **do not write any reproduction code** - simply report the finding and record key implementation details from the paper for subsequent coding stages.

---

## When to Use

When the user mentions "prepare reproduction environment", "download paper resources", "prepare code and data", or similar scenarios.

## PDF Parsing

If PDF parsing is needed, use `bohrium-pdf-parser`. Check the workspace for existing parsed results (`.md`, `.txt`, `.json`) before parsing to avoid duplication.

---

## Input

Accepts any of the following:

1. **Paper PDF file path** - Extract code repo, dataset info directly from PDF
2. **Diagnosis report** - From Diagnose Agent (JSON or Markdown), with dependency ledger already listed
3. **User verbal description** - e.g., "Help me prepare the reproduction environment for paper xxx"

---

## Workflow

```
1. Parse paper/diagnosis report → Extract code repo, dataset, model weights, dependency info
       ↓
2. Download code → git clone or download archive
       ↓
3. Download dataset → From public links, Bohrium datasets, etc.
       ↓
4. Download model weights → Pre-trained models, checkpoints, etc.
       ↓
5. Install dependencies → pip install / conda install / system packages
       ↓
6. Report results → Inform user of preparation status and directory structure
```

### Step 1: Parse Paper Info

- If input is PDF: Use `bohrium-pdf-parser` or `read` to parse paper, extract code repo URL, dataset names/links, required frameworks and dependencies
- If input is diagnosis report: Read dependencies directly from `dependency_ledger`
- If info is insufficient: Use `web_search` to find the paper's official code repo and datasets

### Step 2: Download Code

- Prefer `git clone` of the official code repository
- If repo specifies a commit/tag/branch, switch to the corresponding version
- If no official repo, search for third-party implementations
- If no open-source code at all (no official or third-party): Skip download, note "no open-source code" in the report, extract key implementation info from paper (algorithm pseudocode, network architecture, hyperparameters, loss functions) for subsequent coding stages

### Step 3: Download Dataset

- Find dataset download links from paper or README
- Use `wget`/`curl` or Bohrium dataset API to download
- Extract and place in the directory expected by the code

### Step 4: Download Model Weights (if needed)

- Download pre-trained model weights (HuggingFace, Google Drive, official links, etc.)
- Place in the model directory expected by the code

### Step 5: Install Dependencies

- Check `requirements.txt`, `setup.py`, `environment.yml` and other dependency files
- Run `pip install -r requirements.txt` or equivalent
- Install system-level dependencies if needed

### Step 6: Report Results

After preparation, **must** report the following to the user:

1. **Preparation status** - Which resources downloaded successfully, which failed or skipped (with reasons)
2. **Directory structure** - Tree view of the workspace layout
3. **Next steps** - How to start running, any manual steps the user needs to complete

---

## Output Directory Structure

All resources placed in the working directory with recommended structure:

```
<paper-name>/
├── code/                # Paper code
│   ├── ...              # Cloned repository contents
│   └── requirements.txt
├── data/                # Datasets
│   └── ...
├── models/              # Pre-trained model weights (if any)
│   └── ...
└── README.md            # Preparation notes (optional)
```

If the code repository already has its own data/ or models/ directory conventions, follow the repository's structure.

---

## Report Template

```markdown
Reproduction environment ready!

Downloaded resources:
- Code: [repo name/source] (commit: xxx)
- Dataset: [dataset name] (size: xxx)
- Model weights: [model name] (size: xxx)
- Dependencies: Installed (pip install -r requirements.txt)

Directory structure:
<paper-name>/
├── code/
│   └── ...
├── data/
│   └── ...
└── models/
    └── ...

Notes:
- [Issues requiring user attention, e.g., a dataset requiring manual access request]
- [If no open-source code: note "No open-source code available, reproduction code needs to be written from scratch"]

Paper implementation details (only when no open-source code):
- Core algorithm/network architecture description
- Key hyperparameters
- Loss function/optimizer
- Other technical details needed for reproduction

Next steps:
- cd <paper-name>/code && python train.py  # Start training
- Or see code/README.md for specific instructions
```

---

## Dependent Skills

| Skill | Purpose | Required |
|-------|---------|----------|
| `bohrium-pdf-parser` | Parse paper content from PDF | Recommended |
| `bohrium-paper-search` | Search for paper code repos and datasets | Recommended |
| `bohrium-dataset` | Query and download Bohrium platform datasets | Optional |

---

## Error Handling

| Scenario | Handling |
|----------|---------|
| Code repo doesn't exist or is private | Search third-party implementations; if none available, report and extract paper implementation details |
| Dataset requires application/payment | Inform user of manual application needed, provide links |
| Model weights too large to download | Inform user of file size, provide download command for manual execution |
| Dependency installation failure | Record error, try alternative installation methods, report to user |
| PDF cannot be parsed | Fall back to web_search for paper information |

---

## Constraints

- Only download and configure existing resources, do not write reproduction code
- Do not expose user private data
