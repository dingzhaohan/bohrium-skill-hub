---
name: scoring-agent
description: "Paper reproduction scoring skill. Use when: user needs to evaluate reproduction quality, score an ARM package, or assess reproduction results with 4C dimensions. Orchestrates execution/rubric/grading subagents. NOT for: initial reproduction, diagnosis, environment preparation, or planning."
---

# SKILL: 论文复现评分

对已复现的文献（ARM 包）进行系统化评分。协调三个 subagent（execution / rubric / grading）完成执行评估、标准构建和打分流程。

---

## 何时使用

当用户提到"复现评分"、"评估复现质量"、"打分"、"评价复现结果"等需要对 ARM 包进行质量评估的场景。

---

## 输入要求

### 必需材料

1. **ARM 包路径** - 包含完整复现材料的目录
   - `notebook.ipynb` - 复现 Jupyter notebook
   - `paper.pdf` - 原始论文
   - `todolist.md` - 复现任务清单

2. **评分会话配置**
   - 会话目录名称（默认：`scoring_<timestamp>/`）
   - 输出路径（默认：当前工作目录）

### 可选材料

- 自定义评分 rubric（如不提供，由 rubric agent 自动生成）
- 特殊执行参数（超时时间、资源限制等）

---

## 评分维度（4C）

| 维度 | 说明 | 默认权重 |
|------|------|----------|
| Completeness | 复现任务的完整性，是否覆盖所有要求的实验 | 0.3 |
| Correctness | 结果的正确性，与论文数值的一致程度 | 0.4 |
| Clarity | 代码和文档的清晰度，可读性和可维护性 | 0.2 |
| Cost | 计算成本效率，资源使用的合理性 | 0.1 |

---

## 工作流程

### 阶段 1: 准备评分工作目录

创建结构化的评分会话目录：

```
scoring_<timestamp>/
├── inputs/
│   ├── arm/              # ARM 包的副本或软链接
│   ├── paper.pdf         # 论文 PDF
│   └── todolist.md       # 任务清单
├── outputs/
│   ├── execution_report.json    # execution agent 输出
│   ├── rubric.json              # rubric agent 输出
│   ├── grading_details.json     # grading agent 详细打分
│   └── final_score_card.json    # 最终评分卡
└── metadata.json         # 会话元信息
```

### 阶段 2: 并行调度 Execution 和 Rubric Agents

**Execution Agent** 和 **Rubric Agent** 可并行执行（无依赖关系）。

#### Execution Agent

执行 ARM notebook，记录每个 cell 的运行状态。

输出 `execution_report.json`：

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

根据论文和 todolist 构建评分标准（4C 维度）。

输出 `rubric.json`：

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

### 阶段 3: 等待并验证阶段 2 完成

- 监控两个 subagent 的执行状态
- 验证输出文件存在且格式正确

### 阶段 4: 调度 Grading Agent

Grading Agent **依赖** Execution 和 Rubric 的输出，必须在阶段 2 完成后执行。

基于执行报告和 rubric 逐项打分，输出 `final_score_card.json`：

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
    "R0 基本完成，7/10 cells 成功执行",
    "R1 结果部分复现，主要指标偏差 <5%",
    "R2 扩展实验缺失数据集 B 的测试"
  ],
  "improvement_suggestions": [
    "补充缺失依赖: torch, transformers",
    "修正数据预处理脚本中的路径错误",
    "添加数据集 B 的测试用例"
  ]
}
```

### 阶段 5: 汇总与呈现

读取 `final_score_card.json`，向用户呈现：

1. **总分和等级分数** - 直观展示整体质量
2. **维度分析** - 4C 各维度表现
3. **关键发现** - 具体成功和失败点
4. **改进建议** - 可操作的优化方向

呈现格式示例：

```markdown
## 复现评分结果

**总分**: 78.5 / 100

### 分级得分
- R0 (跑通代码): 85.0
- R1 (复现结果): 75.0
- R2 (深度扩展): 60.0

### 维度分析
- Completeness (完整性): 80
- Correctness (正确性): 85
- Clarity (清晰度): 70
- Cost (成本效率): 75

### 关键发现
- R0 基本完成，7/10 cells 成功执行
- R1 结果部分复现，主要指标偏差 <5%
- R2 扩展实验缺失数据集 B 的测试

### 改进建议
1. 补充缺失依赖: torch, transformers
2. 修正数据预处理脚本中的路径错误
3. 添加数据集 B 的测试用例
```

如用户有疑问，可追溯到 `grading_details.json` 查看每个 rubric 条目的打分依据和执行证据。

---

## 错误处理

| 场景 | 处理 |
|------|------|
| Subagent 调度失败 | 记录错误到 `metadata.json`，向用户报告失败原因 |
| Subagent 执行超时 | 检查 subagent 状态，读取部分输出（如有） |
| 输出文件缺失或格式错误 | 检查 subagent 日志，向用户报告并决定是否降级处理 |
| ARM 包材料不完整 | 明确告知缺少哪些材料，建议使用对应 skill 补全 |

---

## 前置要求

- ARM 包已组织完毕
- Notebook 已生成
- Todolist 已创建（可由 diagnose-agent 生成）

---

## 约束

- 只做评分，不修改 ARM 包内容
- 评分结果客观、可追溯，每项打分有证据支撑
- 不外泄用户私有数据
