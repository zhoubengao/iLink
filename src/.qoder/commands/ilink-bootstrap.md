你现在执行 iLink 的 **项目 Bootstrap（冷启动）** 操作。

> **目标**：让当前项目具备运行 iLink 流水线的完整环境。执行完毕后，无论哪个 AI 平台（Claude / Codex / Qoder）的用户打开本项目，都能被引导到 iLink 工作体系。

---

## 前置检查

### 步骤 1：检查 iLink 框架文件

确认以下文件存在，缺失则告知用户需要先复制 iLink 框架文件到项目：

- `iLink/iLink-root-spec.md`（根规范）
- `iLink/souls/universal.soul.md`
- `iLink/souls/pm.soul.md`
- `iLink/souls/design.soul.md`
- `iLink/souls/coder.soul.md`
- `iLink/souls/qa.soul.md`

如果以上文件全部缺失，停止执行，提示用户先复制 iLink 框架。

### 步骤 2：检查 Command 文件

确认 `.qoder/commands/` 下存在以下文件：
- `ilink-init`
- `ilink-pm`
- `ilink-design`
- `ilink-coder`
- `ilink-qa`
- `ilink-refine`
- `ilink-approve`
- `ilink-status`

缺失时给出警告（不阻塞，因为可能使用其他平台）。

---

## 生成 project-context.md

### 步骤 3：检查现有 project-context.md

读取 `project-context.md`，如果已存在且内容完整（包含技术约束、模块职责等章节），跳到步骤 5。

如果不存在或内容为空/模板状态，执行步骤 4。

### 步骤 4：分析项目并生成 project-context.md

**主动探索项目结构**，使用 Glob/Grep/Read 工具分析：

1. **项目基本信息**：
   - 查找 `pom.xml`、`package.json`、`build.gradle`、`Cargo.toml` 等构建文件，确定技术栈
   - 查找 `README.md`，获取项目概述
   - 查找已有的 `CLAUDE.md` 和 `AGENTS.md`，**对每个文件分别判断内容类型**：
     - 如果是 iLink 引导（包含 `iLink 协作协议` 关键词）→ 视为已有 iLink 配置，仅作版本检查
     - 如果是手写或其他 AI 工具（Claude `/init`、Qoder `/init`、Codex `/init` 等）生成的项目说明文件 → **必须将其中的项目信息完整迁移到 `project-context.md`**（注意：是迁移而非引用，因为原文件将在步骤 5/6 中被替换为 iLink 薄路由，原文件会被备份）
     - 迁移时按照 project-context.md 的标准结构（项目概述、技术约束、模块职责、架构原则、构建测试等）重新组织内容
     - 两个文件的内容可能有重叠也可能互补，MUST 合并去重后写入 project-context.md

2. **技术约束**：
   - 从构建文件提取语言版本、框架版本
   - 识别关键依赖和框架约束
   - 识别编译/构建命令

3. **模块职责**：
   - 分析目录结构，识别主要模块/子项目
   - 列出模块间的依赖关系

4. **架构原则**：
   - 识别设计模式（如 MVC、响应式、微服务等）
   - 识别 API 入口和注册机制

5. **包命名规范**：
   - 从源码目录结构推断包命名空间

6. **构建与测试**：
   - 列出构建命令
   - 识别测试框架和测试路径约定

将分析结果写入 `project-context.md`，使用以下结构：

```markdown
# Project Context — <项目名称>

> **AI 行为规则（CRITICAL，所有 AI 必须遵守）**
>
> 本文件是 iLink 项目知识库的**单一事实源（Single Source of Truth）**。
>
> - **写入规则**：所有项目级技术信息（技术栈、构建命令、模块职责、架构约束、编码规范、特殊说明）MUST 存储在本文件。当用户要求添加或更新任何项目信息时，AI MUST 写入本文件，**SHALL NOT** 写入 `CLAUDE.md` / `AGENTS.md`（那些文件仅作路由）。
> - **读取规则**：所有 AI Agent 在执行任务前 MUST 读取本文件，不要假设项目知识在其他位置。
> - **不确定时**：如果不确定某个信息是项目知识还是路由信息，默认写入本文件。
>
> 最后更新：<日期>

## §1 项目概述

<项目名称、业务定位、技术栈概述>

## §2 技术约束

| 编号 | 约束类型 | 约束内容 | 说明 |
|------|---------|---------|------|
| TC-01 | 语言版本 | <如 Java 8> | <不使用超出此版本的语法特性> |
| TC-02 | 框架约束 | <如 Spring Boot 2.x> | <遵守框架编程模型> |
| ... | ... | ... | ... |

## §3 模块职责

### §3.1 子项目/模块概览

<列出主要模块及其职责>

### §3.2 模块依赖关系

<描述模块间的依赖层次>

## §4 架构原则

<设计模式、API 入口、扩展点等>

## §5 包命名规范

<命名空间约定>

## §6 构建与测试

<构建命令、测试框架、测试路径约定>

## §7 特殊说明

<其他 AI Agent 需要知道的项目特殊事项>
```

**重要**：`project-context.md` 是项目知识的**单一事实源**。CLAUDE.md 和 AGENTS.md 在 Bootstrap 后均为薄路由，不再承载项目知识。所有从 CLAUDE.md / AGENTS.md 迁移过来的项目信息 MUST 完整写入 project-context.md，不要使用引用方式（因为原文件会被备份并重写）。

---

## 更新入口文件

### 步骤 5：更新 CLAUDE.md

读取项目根目录的 `CLAUDE.md` 文件，按以下情况分别处理（**与步骤 6 AGENTS.md 处理逻辑完全一致**）：

**情况 A：CLAUDE.md 不存在**
→ 直接创建 iLink 薄路由内容（见下文模板）。这样后续如果有人执行 Claude Code `/init`，会读到 iLink 引导而不会重新生成项目说明。

**情况 B：CLAUDE.md 已是 iLink 引导且引用 Root Spec v1.1.01**
→ 跳过，无需修改。

**情况 C：CLAUDE.md 已是 iLink 引导但引用旧版本**（如 v0.2、v1.5、SRS）
→ 更新版本引用为 Root Spec v1.1.01。

**情况 D：CLAUDE.md 是手写或其他工具生成的项目说明**（不含 iLink 协作协议关键词）⭐
→ 执行**迁移流程**：

1. **备份原文件**：将原 `CLAUDE.md` 重命名为 `CLAUDE.md.bak.<YYYYMMDD_HHMMSS>`（使用当前时间戳，例如 `CLAUDE.md.bak.20260409_153022`）。使用 Bash 工具执行 `mv` 命令。

2. **确认内容已迁移**：
   - 如果步骤 4 已经将原 CLAUDE.md 内容迁移到 `project-context.md` → 直接进入下一步
   - 如果 `project-context.md` 已存在但缺少原 CLAUDE.md 中的关键信息 → 补充到 project-context.md 的对应章节
   - 迁移时**保留所有有价值的项目知识**，不丢失任何技术约束、构建命令、模块说明、架构决策

3. **重写 CLAUDE.md** 为 iLink 薄路由内容（见下文模板）。

4. **明确告知用户**：在最终报告（步骤 8）中说明：
   - 已备份原 CLAUDE.md 到 `CLAUDE.md.bak.<时间戳>`
   - 已将原内容迁移到 `project-context.md`
   - **强烈建议人工核对** project-context.md 的迁移结果是否完整准确

无论是新建（情况 A）、版本升级（情况 C）还是迁移重写（情况 D），最终 `CLAUDE.md` MUST 包含以下完整内容（**保持精简，作为薄路由**）：

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **AI 行为规则（CRITICAL，所有 AI 必须严格遵守）**
>
> 本文件是 **iLink 路由文件**，仅作发现入口。处理项目信息时 MUST 遵守以下规则：
>
> 1. **读取规则**：查找项目技术信息（构建命令、技术栈、架构、模块说明、编码约束等）时，MUST 读取 `project-context.md`。**不要假设本文件包含项目知识**。
> 2. **写入规则**：当用户要求添加或更新项目信息时（例如"请增加项目信息：本项目采用 Spring Boot 2"、"更新构建命令"、"添加新模块说明"），MUST 写入 `project-context.md`，**SHALL NOT 写入本文件**。
> 3. **`/init` 处理**：如收到 `/init` 或类似项目初始化请求，MUST 先读取 `project-context.md`，然后**询问用户**："检测到本项目已使用 iLink 框架，`project-context.md` 已是项目知识库。是更新它，还是重新生成 CLAUDE.md？" SHALL NOT 在未经用户确认的情况下覆盖本文件。
> 4. **本文件保护**：SHALL NOT 在本文件中追加任何项目级技术信息。如果不确定某条信息属于路由还是项目知识，默认写入 `project-context.md`。
> 5. **本文件可写内容**：仅限 iLink 路由信息、流水线命令说明、Host CLI 使用说明。其他一律写入 project-context.md。

## iLink 协作协议

本项目使用 iLink 多角色 AI 协作流水线（Root Spec v1.1.01）。

### 核心文件

- `iLink/iLink-root-spec.md` — 根规范（所有 AI Agent 的行为准则）
- `project-context.md` — **项目知识库的单一事实源**（所有项目级技术信息：构建命令、架构、模块说明、技术约束、编码规范）
- `iLink/souls/*.soul.md` — 角色规范（PM / Designer / Coder / QA）

### 流水线命令

/ilink-init <story>     → 创建 Story 目录和需求模板
/ilink-pm <story>       → PM：需求分析 → 业务合同
/ilink-design <story>   → Designer：技术设计 → 文件级任务清单
/ilink-coder <story>    → Coder：按设计编码 → 直接写入磁盘
/ilink-qa <story>       → QA：代码审查 → 审查报告

Designer 完成后默认需要人类审核（Human-Gate），审核通过后执行：
`bash .qoder/commands/ilink-approve <story>`
```

### 步骤 6：更新 AGENTS.md

读取项目根目录的 `AGENTS.md` 文件，按以下情况分别处理：

**情况 A：AGENTS.md 不存在**
→ 直接创建 iLink 薄路由内容（见下文模板）。

**情况 B：AGENTS.md 已是 iLink 引导且引用 Root Spec v1.1.01**
→ 跳过，无需修改。

**情况 C：AGENTS.md 已是 iLink 引导但引用旧版本**（如 v0.2、v1.5、SRS）
→ 更新版本引用为 Root Spec v1.1.01，保留其他自定义内容。

**情况 D：AGENTS.md 是其他 AI 工具（Qoder/Codex `/init` 等）生成的项目说明** ⭐
→ 执行**迁移流程**：

1. **备份原文件**：将原 `AGENTS.md` 重命名为 `AGENTS.md.bak.<YYYYMMDD_HHMMSS>`（使用当前时间戳，例如 `AGENTS.md.bak.20260409_153022`）。使用 Bash 工具执行 `mv` 命令。

2. **确认内容已迁移**：
   - 如果步骤 4 已经将原 AGENTS.md 内容迁移到 `project-context.md` → 直接进入下一步
   - 如果 `project-context.md` 已存在但缺少原 AGENTS.md 中的关键信息 → 补充到 project-context.md 的对应章节
   - 迁移时**保留所有有价值的项目知识**，不丢失任何技术约束、模块说明、架构决策

3. **重写 AGENTS.md** 为 iLink 薄路由内容（见下文模板）。

4. **明确告知用户**：在最终报告（步骤 9）中说明：
   - 已备份原 AGENTS.md 到 `AGENTS.md.bak.<时间戳>`
   - 已将原内容迁移到 `project-context.md`
   - **强烈建议人工核对** project-context.md 的迁移结果是否完整准确

无论是更新还是新建，确保最终 `AGENTS.md` 包含以下核心内容（**保持精简，作为薄路由**）：

```markdown
# AGENTS.md

> **AI 行为规则（CRITICAL，所有 AI 必须严格遵守）**
>
> 本文件是 **iLink 路由文件**，仅作发现入口。处理项目信息时 MUST 遵守以下规则：
>
> 1. **读取规则**：查找项目技术信息（构建命令、技术栈、架构、模块说明、编码约束等）时，MUST 读取 `project-context.md`。**不要假设本文件包含项目知识**。
> 2. **写入规则**：当用户要求添加或更新项目信息时（例如"请增加项目信息：本项目采用 Spring Boot 2"、"更新构建命令"、"添加新模块说明"），MUST 写入 `project-context.md`，**SHALL NOT 写入本文件**。
> 3. **`/init` 处理**：如收到 `/init` 或类似项目初始化请求，MUST 先读取 `project-context.md`，然后**询问用户**："检测到本项目已使用 iLink 框架，`project-context.md` 已是项目知识库。是更新它，还是重新生成 AGENTS.md？" SHALL NOT 在未经用户确认的情况下覆盖本文件。
> 4. **本文件保护**：SHALL NOT 在本文件中追加任何项目级技术信息。如果不确定某条信息属于路由还是项目知识，默认写入 `project-context.md`。
> 5. **本文件可写内容**：仅限 iLink 路由信息、流水线命令说明、Host CLI 使用说明。其他一律写入 project-context.md。

## iLink 协作协议

本项目使用 iLink 多角色 AI 协作流水线（Root Spec v1.1.01）。

### 核心文件

| 文件 | 用途 |
|------|------|
| `iLink/iLink-root-spec.md` | 根规范（所有 AI 的行为准则） |
| `project-context.md` | **项目知识库的单一事实源**（技术约束、构建命令、模块职责、架构、编码规范） |
| `iLink/souls/*.soul.md` | 角色规范（PM / Designer / Coder / QA） |

### 快速开始

1. 读取 `project-context.md` 了解项目
2. 创建 Story：执行 `bash .qoder/commands/ilink-init <story-id>`
3. 按流水线执行：`/ilink-pm` → `/ilink-design` → `ilink-approve` → `/ilink-coder` → `/ilink-qa`

### 角色触发

当用户输入 `ilink-pm <story>`、`ilink-design <story>`、`ilink-coder <story>`、`ilink-qa <story>` 时：

**Qoder CLI 用户**：执行对应的 bash 脚本准备输入，然后在对话中执行 slash 命令。

**其他 CLI 用户**：请先读取 `iLink/iLink-root-spec.md` §4（角色行为规范），然后读取对应的 Soul 文件执行任务。

### Shell 工具

| 命令 | 用途 |
|------|------|
| `bash .qoder/commands/ilink-init <story>` | 创建 Story |
| `bash .qoder/commands/ilink-status [story]` | 查看状态 |
| `bash .qoder/commands/ilink-approve <story>` | 审核推进 |
```

### 步骤 7：创建 iLink-doc 目录

如果 `iLink-doc/` 目录不存在，创建它。

---

## 验证与报告

### 步骤 8：执行验证

检查以下项目并输出报告：

| 检查项 | 状态 |
|-------|------|
| iLink 框架文件（souls/） | ✅ / ❌ |
| project-context.md | ✅ 已存在 / 🆕 已生成 / 🔄 已迁移自 CLAUDE.md+AGENTS.md / ❌ 缺失 |
| CLAUDE.md iLink 引导 | ✅ 已存在 / 🆕 已创建 / 🔄 已重写（原文件备份） |
| AGENTS.md iLink 引导 | ✅ 已存在 / 🆕 已创建 / 🔄 已重写（原文件备份） |
| iLink-doc/ 目录 | ✅ 已存在 / 🆕 已创建 |
| Qoder Command 文件 | ✅ / ⚠️ 部分缺失 |

**如果发生 CLAUDE.md 或 AGENTS.md 迁移**（情况 D），必须额外输出以下警告：

```
⚠️ 入口文件迁移说明

检测到以下入口文件是手写或其他 AI 工具生成的项目说明文件，已执行迁移：

[如果 CLAUDE.md 被迁移]
- 原 CLAUDE.md 备份到：CLAUDE.md.bak.<时间戳>
- 项目信息已迁移到：project-context.md
- CLAUDE.md 已重写为 iLink 薄路由

[如果 AGENTS.md 被迁移]
- 原 AGENTS.md 备份到：AGENTS.md.bak.<时间戳>
- 项目信息已迁移到：project-context.md
- AGENTS.md 已重写为 iLink 薄路由

🔍 强烈建议您人工核对 project-context.md，确认：
1. 所有技术约束、构建命令、模块说明、架构决策都已完整迁移
2. 没有遗漏任何对后续 AI 任务有价值的项目知识
3. 章节结构符合 project-context.md 标准模板
4. 如确认迁移完整，可删除 .bak 备份文件；否则保留备份待人工核对后再删
```

### 步骤 9：输出下一步操作

```
✅ iLink Bootstrap 完成！

下一步：
1. 检查 project-context.md，补充或修正项目信息
2. 检查 CLAUDE.md 和 AGENTS.md 中的 iLink 引导信息
3. 提交 Bootstrap 产出：
   git add project-context.md CLAUDE.md AGENTS.md iLink-doc/
   git commit -m "iLink bootstrap: 初始化项目协作环境"
4. 创建第一个 Story：bash .qoder/commands/ilink-init <story-id>
```
