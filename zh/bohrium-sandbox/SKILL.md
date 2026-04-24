---
name: bohrium-sandbox
description: "Cloud sandbox for running shell commands / Python in an isolated E2B VM, exposed by bohrctl's SandboxTool. Use when: user wants to execute code, run quick scripts, test commands, read/write files in a throwaway environment WITHOUT polluting the host. NOT for: Bohrium compute jobs (use bohrium-job), dev machines (use bohrium-node)."
---

# SKILL: Bohrium Sandbox (E2B)

## 概述

bohrctl 集成了 [E2B](https://e2b.dev/) 沙箱：一个按需创建的临时云 VM，支持三种操作：

- **exec** — 执行 shell 命令
- **write** — 写文件
- **read** — 读文件

会话级别的沙箱懒加载，第一次调用时创建，会话结束时清理。

**典型场景**：

- 运行一段 Python / Bash 快速验证想法
- 执行可能危险或污染环境的命令
- 批处理文件（下载、转格式、提取）

**不适用**：

- Bohrium 上的计算任务 → `bohrium-job`
- 长期开发机 → `bohrium-node`

**与其他 skill 的不同**：Sandbox **不走 `open.bohrium.com`**，直接调用 E2B API (`api.e2b.dev`)。

## 配置

**必须**设置 `E2B_API_KEY`（注册：<https://e2b.dev/dashboard>）：

```json
"bohrium-sandbox": {
  "enabled": true,
  "env": {
    "E2B_API_KEY": "YOUR_E2B_KEY",
    "E2B_SANDBOX_TEMPLATE": "openclaw"
  }
}
```

可选：`E2B_SANDBOX_TEMPLATE` 指定模板（默认 `openclaw`）。

## 使用方式

通过 `bohr` CLI 的 `Sandbox` 工具调用——非 HTTP API 端点。bohrctl 内部帮你封装了 E2B 的会话 / 鉴权 / 清理。

### 1. exec — 执行命令

```
action: exec
command: "pip install numpy && python -c 'import numpy; print(numpy.__version__)'"
timeout: 60000   # 毫秒，默认 60s，最大 300s
```

返回：

```
stdout:
  <标准输出，超过 50K 字符会从尾部截断>
stderr:
  <标准错误，超过 10K 字符会截断>
exit code: 0
```

### 2. write — 写文件

```
action: write
path: "/home/user/script.py"
content: "print('hello')\n"
```

### 3. read — 读文件

```
action: read
path: "/home/user/script.py"
```

> 超过 50K 字符会只返回末尾 50K（便于查 log 文件末尾）。

---

## 工作流示例

### 快速验证 Python 脚本

```
# 1. 写文件
action: write
path: /tmp/check_torch.py
content: |
    import torch
    print(torch.__version__, torch.cuda.is_available())

# 2. 执行
action: exec
command: python /tmp/check_torch.py
```

### 下载并转换数据

```
action: exec
command: |
    curl -s -o data.csv https://example.com/data.csv
    python -c "
    import pandas as pd
    df = pd.read_csv('data.csv')
    df.to_parquet('data.parquet')
    print(df.shape)
    "
```

### 读文件尾部 log

```
action: read
path: /var/log/app.log
```

---

## 注意事项

- **沙箱是临时的** — 会话结束即销毁，不要把重要产物留在里面。需要持久化的结果应下载或传到 Bohrium dataset。
- **exec 超时** — 默认 60 秒，最大 300 秒。长任务请拆分或用 `bohrium-job`。
- **网络访问** — 沙箱有出站网络，能装包、拉仓库、请求 API。
- **文件路径** — 推荐放在 `/tmp` 或 `/home/user` 下，避免权限问题。

---

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| `E2B_API_KEY environment variable is required` | 未配置 API key | 到 <https://e2b.dev/dashboard> 注册获取，设置 `E2B_API_KEY` |
| 命令超时 | 任务超过 timeout | 增大 `timeout` 参数（最大 300000 ms）或改用 `bohrium-job` |
| stdout 被截断 | 输出 > 50K 字符 | 把输出写到文件，再用 `action: read` 分段读取 |
| 找不到先前创建的文件 | 会话重启后沙箱已销毁 | 同一会话内的操作共享沙箱，跨会话无持久化 |

## 搭配使用

- **sandbox** 先跑通一段脚本 → **bohrium-job** 提交到 Bohrium 做大规模计算
- **sandbox** 下载 / 预处理 / 解压数据 → 上传到 **bohrium-dataset**
- **sandbox** 跑 Python 验证 → 结果写入 **viking-memory** 长期保存
