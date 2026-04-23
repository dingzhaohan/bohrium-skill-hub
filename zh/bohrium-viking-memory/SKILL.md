---
name: bohrium-viking-memory
description: "Long-term memory for agents via OpenViking REST API. Use when: user wants to save notes/facts/context that should persist across bohr sessions, recall prior memories by semantic query or keyword, or explicitly delete saved memories. NOT for: short-term conversation state, file storage (use bohrium-dataset), Bohrium knowledge base (use bohrium-knowledge-base)."
---

# SKILL: Bohrium Viking Memory (长期记忆)

## 概述

bohrctl 通过 OpenViking 提供**跨会话长期记忆**：

- **find** — 语义检索（按含义相近找）
- **search** — 关键词检索（按字面匹配找）
- **read** — 读取一条完整记忆
- **save** — 写入一条记忆（可选自动生成 URI）
- **delete** — 删除一条记忆

记忆存储在 `viking://user/{tenant}-{userId}/memories/...` URI 下，按 tenant (默认 `bohrctl`) 和 `BOHR_USER_ID` 做用户隔离。

**典型场景**：

- 把用户的偏好 / 项目上下文 / 重要决策保存下来，下次会话继续用
- 跨会话引用之前做过的实验结果
- 把从论文中提炼的关键结论存起来

**不适用**：

- 当前会话内的临时状态 → 直接在对话里保留
- 大文件 → `bohrium-dataset`
- 论文/知识库文件 → `bohrium-knowledge-base`

**与其他 skill 的不同**：Viking 不走 `open.bohrium.com`，直连 OpenViking 服务（默认 `https://openviking.test.dp.tech`）。

## 配置

```json
"bohrium-viking-memory": {
  "enabled": true,
  "env": {
    "OPENVIKING_URL": "https://openviking.test.dp.tech",
    "OPENVIKING_API_KEY": "YOUR_KEY",
    "OPENVIKING_ACCOUNT": "bohrctl",
    "BOHR_USER_ID": "your-app-user-id"
  }
}
```

| 变量 | 默认 | 说明 |
|------|------|------|
| `OPENVIKING_URL` | `https://openviking.test.dp.tech` | OpenViking 服务地址 |
| `OPENVIKING_API_KEY` | （必填） | 服务鉴权 |
| `OPENVIKING_ACCOUNT` | `bohrctl` | tenant 标识 |
| `BOHR_USER_ID` | `anonymous` | 应用层用户 ID；会被映射成 `{tenant}-{uid}` |

## 使用方式

通过 `bohr` CLI 的 `Memory` 工具调用，非 HTTP 直连。bohrctl 内部自动处理：

- 注入 `X-OpenViking-Account` / `X-OpenViking-User` / `X-API-Key` 头
- URI 命名空间隔离
- 结果解析和截断

---

## Action 参考

### 1. find — 语义检索

最常用的召回方式。按意思找近似的记忆（即便措辞不一样）。

```
action: find
query: "user's preferred Python coding style"
```

返回 Top-10，score > 0.25 的结果。输出含 URI / title / score / abstract，供你决定是否需要 `read` 完整内容。

### 2. search — 关键词检索

按字面命中，适合你知道记忆中明确出现过的术语。

```
action: search
query: "DeePMD training hyperparameters"
```

### 3. read — 读取完整记忆

拿到 `find` / `search` 返回的 URI 后，用 `read` 获取完整内容。

```
action: read
uri: viking://user/bohrctl-alice/memories/preferences/python-style
```

> 超过 30K 字符会截断。

### 4. save — 保存记忆

```
action: save
content: |
    User prefers:
    - Python: type hints on all public functions
    - Formatting: ruff with line-length 100
    - Docstrings: Google style
path: preferences/python-style    # 可选，省略则自动生成
tags: ["preference", "python"]    # 可选，便于后续 search
```

### 5. delete — 删除记忆

```
action: delete
uri: viking://user/bohrctl-alice/memories/preferences/python-style
```

---

## 推荐工作流

### 新会话开始时召回历史

```
# 会话开始
action: find
query: "prior work on this project"
```

### 记录一个重要决定

```
action: save
content: "Decided to use Adam optimizer with lr=1e-3 for the DPA-2 finetune. Batch size 32 hit OOM on A100 40G."
tags: ["decision", "dpa2", "finetune"]
```

### 跨会话引用

```
# 下次会话
action: find
query: "DPA-2 finetune setup"
# → 返回上条 memory 的 URI + score
action: read
uri: <URI from find>
```

---

## 注意事项

- **用户隔离严格**：不同 `BOHR_USER_ID` 互不可见。切换用户会看到不同的记忆集合。
- **find vs search**：语义检索召回率高但可能不精准；关键词检索精确但漏召。先 `find`，命中不理想再 `search`。
- **save 粒度**：每条记忆建议聚焦一个主题（一两段话），别把长日志原封不动塞进去；OpenViking 的 embedding 对短文本更友好。
- **tags 的作用**：目前主要用于人读和未来的检索过滤；`find` 的语义匹配主要看 content。

---

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| `isVikingEnabled() == false` | 没设 `OPENVIKING_API_KEY` | 补上 key；bohrctl 才会启用 Memory 工具 |
| `find` 始终返回空 | 记忆存在别的用户名下；或 score 都低于 0.25 | 检查 `BOHR_USER_ID`；用 `search` 字面查一下 |
| `read` 返回 `No content found` | URI 错 / 已删除 | 用 `find` 或 `search` 重新拿 URI |
| `save` 后 `find` 不到 | 索引延迟 | 等几秒再试；OpenViking 异步建索引 |

## 搭配使用

- 会话开始时先 **viking find** 历史 → 再开始工作
- 完成一段工作后 **viking save** 关键结论
- **paper-search / pdf-parser** 提取到的核心点 → **viking save** 跨会话累积
