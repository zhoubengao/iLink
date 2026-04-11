# iLink Implementation Guide

> **文档编号**: ILINK-IMPL-GUIDE
> **版本**: v1.0.00
> **作者**: 周本高
> **日期**: 2026-04-09
> **文档类型**: 实施手册（Implementation Guide）
> **状态**: 草案
>
> **配套文档**：本文档是 `iLink-root-spec-v1.0.00.md` 的配套实施手册。核心协议规范请参阅 Root Spec。
>
> **文档定位**：Root Spec 定义了"AI 必须遵守什么协议"——状态机、角色契约、字段语义、冲突规则。本文档说明"如何落地这些协议"——产品定位、脚手架规范、Bootstrap 协议、执行顺序。**Root Spec 是目标，本文档是实现路径。**

---

## 目录

0. [执行摘要](#0-执行摘要)
1. [脚手架规范](#1-脚手架规范)
2. [Bootstrap 协议](#2-bootstrap-协议)
3. [推荐执行顺序](#3-推荐执行顺序)

---

## 0. 执行摘要

### 这是什么

iLink 是一套 **CLI-native 的 AI 多角色软件开发协作系统**，可运行在 macOS、Windows、Linux 等主流操作系统上。它利用成熟的 Host CLI 工具（Claude CLI / Qoder CLI / Codex CLI）的原生 LLM 能力，通过 Slash Command 编排 4 个专职 AI Agent（PM、Designer、Coder、QA），以**文件状态机**驱动端到端的软件交付流水线——从需求分析到技术设计、代码编写再到质量审查，关键节点人类审核，其余由 AI 完成。

系统不自建 LLM 调用层、不自建代码搜索引擎、不自建 Prompt 拼接模块，而是将这些能力完全交给 Host CLI。自研部分收敛为：**Soul 文件**（角色行为规范）+ **Slash Command**（执行编排）+ **轻量 bash 辅助脚本**（状态流转与流水线编排）。整套系统的核心资产全部是纯 Markdown 文件，模型无关、平台可移植。

### 为什么要做

当前主流的 AI 编程工具（Copilot、Cursor、Claude Code 等）都是**"一个 AI 做所有事"**的模式。这带来三个结构性问题：

1. **上下文膨胀**：随着任务复杂度增加，单一 AI 的上下文越来越长，导致质量下降和成本上升。
2. **自我合理化**：没有角色间的交叉审查，AI 的错误容易被自己"合理化"而无法发现。
3. **控制粒度粗**：人类无法精确介入某个环节——只能全程手动或全程放手，缺少中间态。

iLink 用**人类软件团队的分工模式**解决这些问题：

- **Context 精简**：每个角色只读取自己需要的上游文档和源码，避免上下文爆炸。
- **交叉审查**：下游角色天然 review 上游的产出——QA 审查 Coder 的代码是否符合 Designer 的设计，Designer 审查 PM 的业务合同是否可实现。
- **精确控制**：人类可以在任意节点通过 Human-Gate 介入（审核设计、修改需求、锁定流水线），而不影响其他环节的自动运转。

除了解决上述三个共性问题，iLink 在企业级软件交付场景下还有以下结构性优势：

- **Story 隔离（最重要的工程属性）**：每个 Story 拥有独立的目录、独立的 Master Doc 集合、独立的 `.retry_count` 信号文件。多个开发者可以并行处理不同 Story 互不污染；同一开发者按"完成一个再开发下一个"的节奏顺序交付时，每个 Story 的状态、历史、回流次数完全自包含。Story 之间没有共享内存、没有全局状态、没有隐式依赖——这让 iLink 天然适配 Jira/工单驱动的迭代开发模式。**注意**：Story 隔离是文档级隔离，不是工程级隔离；如果多个 Story 修改同一文件，仍需串行处理。
- **可追溯的决策链**：每个 Story 完成后留下完整的文档链——`<id>-需求定义.md` → `pm.master.md` → `design.master.md` → `code.master.md` → `review.master.md`。每份文档末尾的 Metadata 印章记录了角色、AI 模型、时间戳、Normalized_Source_Hash，构成天然的审计材料，适配金融、政务、医疗等合规敏感领域。
- **稳定的项目护栏**：`project-context.md` 是项目级的稳定知识库（技术栈、模块职责、编码规范、架构约束）。所有角色每次执行任务前都读它，避免 AI 产出不符合项目实际的方案——尤其适合 legacy 系统、强约束技术栈、隐式架构规则多的项目。
- **QA 回流 + 熔断**：QA 审查不通过时输出结构化的 `[FIX_REQUESTS]`，由 Coder 拿着具体反馈自动修复后再审；连续 3 次仍未通过则强制熔断，要求人类介入。这比"让 AI 反复重试"更可控，也比"出错就放弃"更高效。
- **多平台兼容**：同一套协议（Soul + Master Doc + Metadata）可以在 Claude / Codex / Qoder 等不同 Host CLI 上运行。团队可以根据预算和场景选择不同的工具，但流程保持一致，AI 产出的中间文档可以无缝接力。

### iLink 与 OpenSpec、OhMyOpenCode 的关系

**iLink 不是 OpenSpec 或 OhMyOpenCode 的替代品，而是可叠加的增强层。**

当前 AI 编程领域出现了多种协作范式，其中最具代表性的是 **OpenSpec**（Spec-Driven Development）和 **OhMyOpenCode**（Multi-Agent Orchestration）。它们各自解决了不同层面的核心问题：

| 方案 | 核心贡献 | 典型场景 |
|------|---------|---------|
| **OpenSpec** | 规格驱动开发，让 AI 按规格编码 | 需要长期维护系统规格的项目 |
| **OhMyOpenCode** | 多智能体并行编排，高效处理复杂任务 | 快速交付、探索性开发 |

**iLink 的定位**：为上述方案（或独立使用）提供**协作增强层**，补充以下能力：

| 增强能力 | 对 OpenSpec 的价值 | 对 OhMyOpenCode 的价值 |
|---------|-------------------|----------------------|
| **Story 隔离** | 为每个变更规格提供独立目录和完整追溯，避免 archive 后上下文丢失 | 为并行任务提供独立空间，避免智能体间状态污染 |
| **角色流水线** | 补充 PM → Designer → Coder → QA 的顺序审查链 | 增加顺序审查机制，弥补纯并行模式的质量控制缺口 |
| **Human-Gate** | 增加关键节点的人类审核控制点 | 增加精确的人机切换点，而非全程自动或全程手动 |
| **Metadata 印章** | 为规格和代码增加可追溯的决策链 | 让并行智能体的产出可追溯、可审计 |

#### 叠加使用示例

**场景 A：在 OpenSpec 项目中叠加 iLink**

```
OpenSpec 流程：/opsx:propose → /opsx:apply → /opsx:archive
                    ↓
        iLink 增强：每个 opsx:propose 对应一个 iLink Story
                    ↓
              Story 独立目录保留完整上下文
              Metadata 印章记录决策链
              Human-Gate 确保关键变更经审核
```

**场景 B：在 OhMyOpenCode 项目中叠加 iLink**

```
OhMyOpenCode 流程：Sisyphus → 分解任务 → 分配智能体 → 并行执行
                            ↓
                  iLink 增强：每个任务对应一个 Story 目录
                            ↓
                      顺序审查链（PM → Designer → Coder → QA）
                      Human-Gate 确保关键节点可控
                      Metadata 印章支持审计
```

**场景 C：独立使用 iLink**

对于 **Jira/工单驱动的迭代开发** 场景，iLink 可以独立运行，无需依赖其他框架。

#### 非侵入性设计

iLink 的设计原则是**"可选增强、零侵入"**：

- 所有 iLink 文件位于 `iLink/` 和 `iLink-doc/` 目录，与用户源码隔离
- 不修改用户源码、不修改项目构建配置
- 可以随时移除 `iLink/` 目录，不影响原有项目
- 与 OpenSpec 或 OhMyOpenCode 的文件结构不冲突

**我们的建议**：继续使用您熟悉的 OpenSpec 或 OhMyOpenCode，iLink 作为可选增强层，在需要更强追溯性、人机控制或审计合规时叠加使用。

### 怎么运作

**前置步骤（一次性）**：如果是新项目首次使用 iLink，需先执行 Bootstrap：

```
/ilink-bootstrap（项目冷启动 → 生成 project-context.md → 更新入口文件）
```

**正常流水线**：

```
人类写需求 → /ilink-init kcia-0001 → 编辑需求定义
    ↓
/ilink-pm（理解需求 → 输出业务合同）
    ↓
├─ STAGING → /ilink-refine（逐条决策 → 解除阻塞）→ ilink-approve 推进
└─ PENDING_DESIGNER →
/ilink-design（技术设计 → 输出设计方案 + 文件级任务清单）
    ↓
├─ STAGING → /ilink-refine（逐条决策 → 解除阻塞）→ ilink-approve 推进
└─ PENDING_CODER（经 Human-Gate：人类审核 → ilink-approve 推进）→
/ilink-coder（按设计方案写代码 → 直接写入磁盘）
    ↓
/ilink-qa（AI Code Review → 输出审查报告）
    ↓
├─ COMPLETED → Story 完成，人类审核后 git/svn commit
├─ FAIL_BACK_TO_CODER → 回流修复（最多 3 次，超出熔断，人类介入）
└─ STAGING → /ilink-refine（讨论上游根因，明确修改路径）
```

每一步由人类在 CLI 中手动触发对应的 Slash Command，AI Agent 在 Host CLI 的对话上下文中执行任务，产出结构化的 Master Doc 并写入磁盘。整个流水线的状态完全由文件承载——Master Doc 末尾的 Metadata 印章（Status + Normalized_Source_Hash）+ 信号文件（`.retry_count`），不依赖任何内存状态。

### 核心设计

| 设计要素 | 说明 |
|---------|------|
| **CLI-native** | 不自建 LLM 调用层，充分利用 Host CLI 的原生能力（模型调用、代码搜索、文件读写、上下文管理） |
| **文件状态机** | 所有状态保存在文件中（Metadata 印章 + `.retry_count`），无内存依赖，支持断点续跑和跨机器接力 |
| **模型无关** | Soul 文件、Master Doc、project-context.md 全部为纯 Markdown，不绑定特定 LLM。每个角色可运行在不同的 Host CLI 和模型上 |
| **Soul 文件** | 定义每个 AI Agent 的角色身份、行为规范和产出格式。相当于"岗位说明书"，所有 Agent 必须严格遵守 |
| **project-context.md** | 模型无关的项目知识库——技术栈、模块职责、编码规范、架构约束。相当于团队的"公司 Wiki"，所有 Agent 共享 |
| **Human-Gate** | "离合器"式的人机切换——Designer 节点默认需要人类审核设计方案，审核通过后推进到 Coder。团队建立信任后可逐步放开 |
| **Metadata 协议** | 每个 Master Doc 末尾标准化的 ILINK-PROTOCOL-METADATA 区块，记录角色、版本、AI 标识、状态、RFC3339 时间戳、规范化内容 Hash，实现可追溯的决策链 |
| **版本控制集成** | `iLink/` 和 `iLink-doc/` 与 `src/` 同级，AI 文档与源码统一纳入 Git / SVN，支持多人跨机器协作 |

### 版本控制与团队协作

iLink 的设计天然支持**多人跨机器协作**。因为整个系统的状态完全由文件承载，不依赖内存状态或特定机器：

**核心原则**：`iLink/` 目录（框架资产）和 `iLink-doc/` 目录（Story 文档）与 `src/` 目录处于同一层级，共同构成项目的完整交付物。AI 产出的所有文档和 AI 生成的代码，都必须纳入版本控制系统，与人类编写的代码享有同等的版本管理待遇。

**Story 完成后的提交流程**：

1. **Review**：查看 Coder 修改的源码文件和 `code.master.md` 中的变更摘要。
2. **提交**：将 AI 产出的代码和文档一起提交。

```bash
git add iLink-doc/kcia-0001/ src/
git commit -m "kcia-0001: 新增 Hello World 接口（iLink 交付）"
```

**跨人员协作场景**：

- **接力完善**：开发者 A 完成 Story 并提交后，开发者 B 在代码评审中发现问题，可以 `git pull` → 修改需求定义 → 重新触发 `/ilink-pm` 开始增量流水线。
- **并行开发**：不同开发者同时处理不同 Story，各自目录互不干扰，完成后各自提交。
- **知识沉淀**：Story 完成后新增的模块或接口，开发者应更新 `project-context.md` 并提交，其他人 `git pull` 后 AI Team 自动获得最新的项目上下文。

---

## 1. 脚手架规范

本章定义 Slash Command 文件、Bash 脚本和 Soul 文件的结构规范，使 AI 能据此生成完整的脚手架。

### 1.1 Slash Command 文件规范

Slash Command 是声明式 Markdown 文件，由 Host CLI 解析执行。每个角色的 Command 文件 MUST 包含以下结构：

```markdown
你现在扮演 iLink 中的 **<角色名>** 角色。

## 准备工作
依次读取以下文件：
1. `project-context.md`
2. `iLink/souls/universal.soul.md`
3. `iLink/souls/<role>.soul.md`

## 前置检查
读取上游文档：`iLink-doc/$ARGUMENTS/$ARGUMENTS-<upstream>.master.md`
如不存在，提示用户先执行对应上游命令。

## 执行任务
<角色特定的执行指令，参照 Root Spec §4 角色行为规范>

## 输出
将输出写入：`iLink-doc/$ARGUMENTS/$ARGUMENTS-<role>.master.md`

## Metadata 印章
<Metadata 模板，参照 Root Spec §5>

## 完成后
<根据 Status 值提示用户下一步操作>
```

**平台差异**：
- Claude CLI：`$ARGUMENTS` 为内置变量，自动替换为用户输入的参数
- Codex CLI：无 Slash Command 机制，改用 `codex-commands.md` 指令文件 + bash 脚本
- Qoder CLI：bash 脚本准备输入 bundle + 调用 slash command

### 1.2 Bash 辅助脚本规范

`_common.sh` 提供所有 bash 脚本共享的函数库。MUST 包含以下函数：

| 函数 | 用途 |
|------|------|
| `story_required()` | 校验 story 参数是否提供 |
| `story_dir()` | 返回 story 目录路径：`iLink-doc/$1` |
| `require_file()` | 校验文件存在性 |
| `extract_metadata()` | 从文件中提取指定 Metadata 字段值 |
| `check_status()` | 返回文件的 Status 值（文件不存在返回 `MISSING`） |
| `update_status()` | 就地更新 Metadata 中的 Status 字段 |
| `get_retry_count()` | 读取回流次数 |
| `increment_retry_count()` | 递增回流次数 |
| `reset_retry_count()` | 重置回流次数 |
| `is_reflux_mode()` | 检测是否为回流模式 |
| `is_path_safe()` | 路径安全校验（禁止 `../`、绝对路径、`~`） |
| `extract_task_allocation_paths()` | 从 [TASK_ALLOCATION] 提取文件路径 |
| `log_info()` / `log_error()` / `log_warn()` | 日志输出 |

**辅助脚本命令**：

| 命令 | 用途 |
|------|------|
| `ilink-init <story>` | 创建 story 目录 + 需求定义模板 |
| `ilink-status [story]` | 显示流水线状态与下一步建议 |
| `ilink-refine <story>` | 与 AI 逐条决策解除 STAGING 阻塞项（修订模式，不重新生成文档） |
| `ilink-approve <story>` | 将 STAGING/PENDING 推进到下一个状态 |

### 1.3 Soul 文件规范

每个 Soul 文件 MUST 包含以下结构：

```markdown
# <Role> Soul — <角色中文名>角色规范

> 一句话描述角色定位

## 1. 你的职责
<职责描述 + "你不做的事"列表>

## 2. 输入
<输入文档表格>

## 3. 输出格式
<完整的输出模板>

## 4. 编写规则
<角色特定的编写规范>

## 5. Status 决策规则
<Status 判定表>
```

Soul 文件 MUST 遵守 Root Spec，MAY 增加角色特有细节。

`universal.soul.md` 是特殊的 Soul 文件，定义所有角色的共同行为准则，其内容 SHOULD 与 Root Spec §7 保持一致。当两者冲突时，以 Root Spec 为准。

### 1.4 平台适配规范

| 平台 | Command 位置 | 格式 | 角色触发方式 |
|------|-------------|------|------------|
| Claude CLI | `.claude/commands/*.md` | 纯 Markdown（`$ARGUMENTS` 变量） | `/ilink-pm <story>` |
| Codex CLI | `.codex/commands/*` + `codex-commands.md` | bash 脚本 + 指令文件 | `ilink-pm <story>`（对话中输入） |
| Qoder CLI | `.qoder/commands/*` | bash 脚本（准备 bundle + 调 slash） | `/ilink-pm <story>` |

**跨平台一致性**：
- Soul 文件和 Master Doc 格式 MUST 在所有平台上完全一致
- 新增 Host CLI 平台时，只需在对应目录创建命令文件，SHALL NOT 修改 Soul 文件
- `_common.sh` 函数库 SHOULD 在 .codex 和 .qoder 之间共享

---

## 2. Bootstrap 协议

Bootstrap 是 iLink 在新项目中的**一次性冷启动**过程，目的是让项目具备运行 iLink 流水线的完整环境，并使**任意 AI 平台**的用户打开本项目时都能被自动引导到 iLink 工作体系。

### 2.1 Bootstrap 的两种模式

iLink 支持两种 Bootstrap 模式：

| 模式 | 工具 | 适用场景 |
|------|------|---------|
| **脚本模式** | `bash iLink/setup.sh` | 仅做环境初始化（权限、依赖、行尾符），不分析项目 |
| **AI 命令模式** | `/ilink-bootstrap` | AI 主动分析项目 → 生成 project-context.md → 更新入口文件 |

**SHOULD**：新项目首次部署时优先使用 AI 命令模式，因为它能自动生成项目知识库。

### 2.2 何时执行 Bootstrap

Bootstrap 是项目级的**一次性冷启动**，不是每次开发 Story 都需要执行。以下是必须或建议执行 Bootstrap 的场景：

| 场景 | 是否必须 | 说明 |
|------|---------|------|
| **新项目首次引入 iLink 框架** | MUST | 生成 `project-context.md`、更新入口文件、创建 `iLink-doc/` 目录 |
| **项目结构发生重大变化** | SHOULD | 如新增顶层模块、技术栈升级（Java 8 → 17）、框架迁移（Spring MVC → WebFlux） |
| **入口文件被意外修改或覆盖** | SHOULD | 如执行了 Host CLI 的 `/init` 命令导致 CLAUDE.md / AGENTS.md 被重写 |
| **project-context.md 需要重新生成** | SHOULD | 如原文件内容过时、大量模块职责变更、架构约束不再准确 |
| **跨平台迁移** | MAY | 如从 Claude CLI 迁移到 Qoder CLI，可执行 Bootstrap 补充新平台命令文件 |

**不需要执行 Bootstrap 的场景**：

- 开始开发新的 Story（只需执行 `/ilink-init <story>`）
- 日常代码修改或需求迭代
- 多人协作中的 `git pull`（只需确保 `iLink/` 目录已提交）

**判断依据**：如果 `project-context.md` 不存在或内容严重过时，或入口文件（CLAUDE.md / AGENTS.md）不包含 iLink 协作协议引导，就应该执行 Bootstrap。

### 2.3 ilink-bootstrap 命令规范

`/ilink-bootstrap` 是 iLink 提供的 Slash Command，由 AI 在 Host CLI 中执行。命令定义 MUST 在所支持的每个 Host CLI 平台中对应落地：

| 平台 | 命令定义位置 | 预检查脚本 | 触发方式 |
|------|------------|------------|---------|
| Claude CLI | `.claude/commands/ilink-bootstrap.md` | — | `/ilink-bootstrap` |
| Codex CLI | `.codex/codex-commands.md` 中 `ilink-bootstrap` 章节 | `bash .codex/commands/ilink-bootstrap` | 对话中输入 `ilink-bootstrap` |
| Qoder CLI | `.qoder/commands/ilink-bootstrap.md` | `bash .qoder/commands/ilink-bootstrap` | `/ilink-bootstrap` |

三个平台的 Bootstrap 命令定义 MUST 在执行步骤、状态判定逻辑（A/B/C/D 四种情况）、入口文件模板（5 条 AI 行为规则）、project-context.md 结构上保持**完全一致**，仅在 Shell 脚本路径和平台特定引用上有差异。

#### 2.3.1 执行步骤

执行 `/ilink-bootstrap` 时，AI MUST 按以下顺序完成：

**步骤 1 — 框架文件检查**：
- 校验 `iLink/iLink-root-spec-v1.0.00.md` 与 `iLink/souls/{universal,pm,design,coder,qa}.soul.md` 是否存在
- 全部缺失时 MUST 停止执行，提示用户先复制 iLink 框架到项目

**步骤 2 — Command 文件检查**：
- 校验当前平台的 Command 文件（如 `.claude/commands/ilink-{pm,design,coder,qa,init,refine,approve,status}.md`）
- 缺失时 SHOULD 给出警告但不阻塞（用户可能使用其他平台）

**步骤 3 — project-context.md 处理**：
- 若 `project-context.md` 已存在且内容完整 → 跳到步骤 5
- 若不存在或为空模板 → 进入步骤 4

**步骤 4 — 项目分析与生成 project-context.md**：

AI MUST 主动使用 Host CLI 的 Glob/Grep/Read 能力探索项目，提取以下信息：

| 分析项 | 来源 |
|-------|------|
| 技术栈 | `pom.xml` / `package.json` / `build.gradle` / `Cargo.toml` 等构建文件 |
| 项目概述 | `README.md` |
| 既有项目知识 | 已存在的 `CLAUDE.md` 和 `AGENTS.md`（**MUST 完整迁移而非引用**，见下方关键规则） |
| 模块职责 | 顶层目录结构 + 子项目布局 |
| 包命名规范 | 源码目录结构 |
| 构建/测试命令 | 构建文件中的脚本/profile |

**关键规则——CLAUDE.md / AGENTS.md 内容迁移**：

如果 `CLAUDE.md` 或 `AGENTS.md` 已存在且**不包含 iLink 协作协议引导**（即手写或由其他 AI 工具如 Claude/Qoder/Codex 的 `/init` 生成的项目说明），AI MUST 对**每个文件**分别执行：

1. 将原文件中的项目知识（技术约束、模块说明、架构决策、构建命令等）**完整迁移**到 `project-context.md`，按 project-context.md 的标准章节结构重新组织
2. 在步骤 5 / 6 中备份原文件并将其重写为 iLink 薄路由
3. SHALL NOT 在 project-context.md 中以"引用"方式指向原文件，因为原文件将被重写
4. 如果两个文件都有项目说明，MUST 合并去重后写入 project-context.md

**设计理由**：`project-context.md` 是项目知识的**单一事实源**。CLAUDE.md 和 AGENTS.md 作为入口路由文件，仅应承担"指向 Root Spec 与 project-context.md"的职责，不应承载项目知识。统一处理两个入口文件可以避免知识在多处重复或漂移。

生成的 `project-context.md` MUST 至少包含以下章节：

```
§1 项目概述
§2 技术约束
§3 模块职责
§4 架构原则
§5 包命名规范
§6 构建与测试
§7 特殊说明
```

`project-context.md` 文件顶部 MUST 包含**单一事实源声明 + AI 行为规则**：

```markdown
> **AI 行为规则（CRITICAL，所有 AI 必须遵守）**
>
> 本文件是 iLink 项目知识库的**单一事实源（Single Source of Truth）**。
>
> - **写入规则**：所有项目级技术信息 MUST 存储在本文件。当用户要求添加或更新项目信息时，AI MUST 写入本文件，**SHALL NOT** 写入 CLAUDE.md / AGENTS.md。
> - **读取规则**：所有 AI Agent 在执行任务前 MUST 读取本文件。
> - **不确定时**：如果不确定某个信息是项目知识还是路由信息，默认写入本文件。
```

**步骤 5 — 更新 CLAUDE.md（Claude CLI 入口文件）**：

按以下四种情况分别处理：

| 情况 | 判定条件 | 处理动作 |
|------|---------|---------|
| **A — 不存在** | 文件缺失 | 创建包含 iLink 薄路由的最小文件（防止后续 `/init` 重新生成项目说明） |
| **B — 已是 iLink v1.0.00** | 包含 `iLink 协作协议` 关键词且引用 Root Spec v1.0.00 | 跳过，无需修改 |
| **C — 已是 iLink 旧版本** | 包含 iLink 关键词但引用 v0.2 / v1.5 / SRS 等 | 更新版本引用为 Root Spec v1.0.00 |
| **D — 手写或其他工具生成** | 不含 iLink 关键词，但有项目说明 | 执行**迁移流程**（见下） |

**情况 D 的迁移流程**（MUST 严格遵守）：

1. **备份原文件**：MUST 将原 `CLAUDE.md` 重命名为 `CLAUDE.md.bak.<YYYYMMDD_HHMMSS>`（使用 Bash 工具执行 `mv`），SHALL NOT 直接覆盖删除
2. **确认内容已迁移**：核对步骤 4 是否已将原 CLAUDE.md 中的项目知识完整迁移到 `project-context.md`；若有遗漏 MUST 补充
3. **重写 CLAUDE.md** 为 iLink 薄路由内容
4. **告知用户**：MUST 在步骤 9 的下一步指引中明确说明备份文件名，并 SHOULD 提示用户人工核对迁移结果

**步骤 6 — 更新 AGENTS.md（Codex CLI 及通用入口文件）**：

处理逻辑**与步骤 5 完全一致**——按 A/B/C/D 四种情况判断，情况 D 执行同样的迁移流程：

| 情况 | 判定条件 | 处理动作 |
|------|---------|---------|
| **A — 不存在** | 文件缺失 | 创建包含 iLink 薄路由的最小文件 |
| **B — 已是 iLink v1.0.00** | 包含 `iLink 协作协议` 关键词且引用 Root Spec v1.0.00 | 跳过，无需修改 |
| **C — 已是 iLink 旧版本** | 包含 iLink 关键词但引用 v0.2 / v1.5 / SRS 等 | 更新版本引用为 Root Spec v1.0.00 |
| **D — 手写或其他工具生成** | 不含 iLink 关键词，但有项目说明 | 执行迁移流程：备份为 `AGENTS.md.bak.<YYYYMMDD_HHMMSS>` → 确认内容已迁移到 project-context.md → 重写为薄路由 → 告知用户 |

**步骤 7 — 创建 iLink-doc/ 目录**：
- 若不存在则创建空目录

**步骤 8 — 验证报告**：
- 输出每项检查的状态表（✅ 已存在 / 🆕 已创建 / ⚠️ 部分缺失 / ❌ 错误）

**步骤 9 — 下一步指引**：
- 提示用户审核 `project-context.md`、提交 Bootstrap 产出、创建第一个 Story

#### 2.3.2 幂等性要求

`/ilink-bootstrap` MUST 是幂等的——重复执行不应破坏已有内容：

- SHALL NOT 覆盖已有的 `project-context.md`（除非内容为空模板）
- SHALL NOT 重复修改 CLAUDE.md / AGENTS.md 中已存在的 iLink 引导（情况 B 必须跳过）
- SHALL NOT 直接删除任何已有内容；任何破坏性操作（情况 D 重写）MUST 先创建 `.bak.<时间戳>` 备份
- SHOULD 检测并升级旧版本的引导信息（情况 C）

#### 2.3.3 内容保护原则

`/ilink-bootstrap` MUST 遵守"**内容只迁移、不丢失**"原则：

- 任何已存在的项目知识（无论在 CLAUDE.md、AGENTS.md 还是其他位置）MUST 在 Bootstrap 后仍可访问——要么保留在原文件、要么迁移到 `project-context.md`、要么作为 `.bak` 备份
- 如果 AI 不确定某些内容是否应该迁移，SHOULD 选择保守策略：保留备份并在报告中提醒用户

### 2.4 入口文件规范（路由模式）

不同 Host CLI 使用不同的入口文件发现 iLink：

| Host CLI | 入口文件 | 作用 |
|---------|---------|------|
| Claude CLI | `CLAUDE.md` | 项目级指令文件，MUST 包含指向 Root Spec 的引导 |
| Codex CLI | `AGENTS.md` | Codex 的 Agent 指令文件，MUST 包含指向 Root Spec 和 `codex-commands.md` 的引导 |
| Qoder CLI | — | 通过 `.qoder/commands/` 目录自动发现 |
| 其他 AI CLI | `AGENTS.md` | 作为通用入口，大多数 AI 工具默认会读取 |

#### 2.4.1 薄路由原则

入口文件（CLAUDE.md / AGENTS.md）MUST 作为**薄路由（thin router）**，CLAUDE.md 与 AGENTS.md 遵守完全相同的规则：

- MUST 指向 `iLink/iLink-root-spec-v1.0.00.md` 和 `project-context.md`
- SHALL NOT 复制 Root Spec 或 project-context.md 的内容
- SHALL NOT 承载任何项目级技术信息（构建命令、架构说明、技术约束等）——这些信息 MUST 全部位于 `project-context.md`
- SHOULD 列出流水线核心命令（`/ilink-init` ~ `/ilink-qa`）作为快速参考
- 如 Bootstrap 时发现入口文件包含项目级说明（情况 D）MUST 先迁移到 project-context.md 再重写（不允许保留）
- **MUST 在文件顶部包含"双向显式 AI 行为规则"**（5 条规则，见 §2.4.2/§2.4.3 模板），包含读取规则、写入规则、`/init` 处理规则、本文件保护规则

**理由**：薄路由 + 单一事实源是 iLink 的核心设计。`project-context.md` 是项目知识的唯一存储位置，所有 AI 角色每次执行都读它，避免知识在多个入口文件中漂移。CLAUDE.md 和 AGENTS.md 仅负责"路由发现"——告诉新进入项目的 AI 工具去哪里找 iLink 体系。

#### 2.4.2 CLAUDE.md 引导内容模板

CLAUDE.md 在 Bootstrap 后是一份**完整的薄路由文件**（不是追加片段）。模板顶部 MUST 包含**双向显式 AI 行为规则**——这是确保 AI 在自然语言交互和 `/init` 等内置命令中都遵守"项目知识写入 project-context.md"的关键。

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **AI 行为规则（CRITICAL，所有 AI 必须严格遵守）**
>
> 本文件是 **iLink 路由文件**，仅作发现入口。处理项目信息时 MUST 遵守：
>
> 1. **读取规则**：查找项目技术信息（构建命令、技术栈、架构、模块说明、编码约束等）时，MUST 读取 `project-context.md`。**不要假设本文件包含项目知识**。
> 2. **写入规则**：当用户要求添加或更新项目信息（例如"请增加项目信息：本项目采用 Spring Boot 2"），MUST 写入 `project-context.md`，**SHALL NOT 写入本文件**。
> 3. **`/init` 处理**：如收到 `/init` 或类似初始化请求，MUST 先读取 `project-context.md`，然后**询问用户**确认是更新 project-context.md 还是重新生成 CLAUDE.md。SHALL NOT 在未经用户确认的情况下覆盖本文件。
> 4. **本文件保护**：SHALL NOT 在本文件中追加任何项目级技术信息。不确定时默认写入 `project-context.md`。
> 5. **本文件可写内容**：仅限 iLink 路由信息、流水线命令说明、Host CLI 使用说明。

## iLink 协作协议

本项目使用 iLink 多角色 AI 协作流水线（Root Spec v1.0.00）。

### 核心文件

- `iLink/iLink-root-spec-v1.0.00.md` — 根规范
- `project-context.md` — **项目知识库的单一事实源**
- `iLink/souls/*.soul.md` — 角色规范

### 流水线命令

/ilink-init <story>     → 创建 Story 目录和需求模板
/ilink-pm <story>       → PM：需求分析 → 业务合同
/ilink-design <story>   → Designer：技术设计 → 文件级任务清单
/ilink-coder <story>    → Coder：按设计编码 → 直接写入磁盘
/ilink-qa <story>       → QA：代码审查 → 审查报告
/ilink-refine <story>   → 修订对话：逐条解除 STAGING 阻塞项（修订模式）
/ilink-approve <story>  → Human-Gate 推进：STAGING/PENDING → 下一状态
/ilink-status [story]   → 查看当前流水线状态与下一步建议
```

#### 2.4.3 AGENTS.md 引导内容模板

AGENTS.md 与 CLAUDE.md 遵守完全一致的"双向显式 AI 行为规则"——模板顶部 MUST 包含同样的 5 条规则。

```markdown
# AGENTS.md

> **AI 行为规则（CRITICAL，所有 AI 必须严格遵守）**
>
> 本文件是 **iLink 路由文件**，仅作发现入口。处理项目信息时 MUST 遵守：
>
> 1. **读取规则**：查找项目技术信息（构建命令、技术栈、架构、模块说明、编码约束等）时，MUST 读取 `project-context.md`。**不要假设本文件包含项目知识**。
> 2. **写入规则**：当用户要求添加或更新项目信息（例如"请增加项目信息：本项目采用 Spring Boot 2"），MUST 写入 `project-context.md`，**SHALL NOT 写入本文件**。
> 3. **`/init` 处理**：如收到 `/init` 或类似初始化请求，MUST 先读取 `project-context.md`，然后**询问用户**确认是更新 project-context.md 还是重新生成 AGENTS.md。SHALL NOT 在未经用户确认的情况下覆盖本文件。
> 4. **本文件保护**：SHALL NOT 在本文件中追加任何项目级技术信息。不确定时默认写入 `project-context.md`。
> 5. **本文件可写内容**：仅限 iLink 路由信息、流水线命令说明、Host CLI 使用说明。

## iLink 协作协议

本项目使用 iLink 多角色 AI 协作流水线（Root Spec v1.0.00）。

### 核心文件

- `iLink/iLink-root-spec-v1.0.00.md` — 根规范
- `project-context.md` — **项目知识库的单一事实源**
- `iLink/souls/*.soul.md` — 角色规范

### 角色触发

当用户输入 `ilink-pm <story>` / `ilink-design <story>` / `ilink-coder <story>` / `ilink-qa <story>` / `ilink-refine <story>` 时：

- **Codex CLI 用户**：先读取 `.codex/codex-commands.md`，按其中指令执行
- **其他 CLI 用户**：先读取 `iLink/iLink-root-spec-v1.0.00.md` §4/§6.3，再读对应 Soul 文件执行

### Shell 工具

- `bash .codex/commands/ilink-init <story>` — 创建 Story
- `bash .codex/commands/ilink-status [story]` — 查看状态
- `bash .codex/commands/ilink-refine <story>` — 修订对话，解除 STAGING 阻塞
- `bash .codex/commands/ilink-approve <story>` — 审核推进
```

### 2.5 前置条件

- 项目已有版本控制（Git / SVN）
- 已复制 iLink 框架文件到项目（`iLink/`、至少一个平台的 `commands/` 目录）
- 至少一个 Host CLI 已安装

### 2.6 最小文件集

冷启动后，项目中 MUST 存在以下文件才能运行流水线：

| 文件 | 必要性 | 说明 |
|------|-------|------|
| `iLink/iLink-root-spec-v1.0.00.md` | MUST | 根规范 |
| `iLink/iLink-implementation-guide-v1.0.00.md` | SHOULD | 实施手册 |
| `iLink/souls/universal.soul.md` | MUST | 全局行为规范 |
| `iLink/souls/pm.soul.md` | MUST | PM 角色规范 |
| `iLink/souls/design.soul.md` | MUST | Designer 角色规范 |
| `iLink/souls/coder.soul.md` | MUST | Coder 角色规范 |
| `iLink/souls/qa.soul.md` | MUST | QA 角色规范 |
| `project-context.md` | MUST | 项目知识库（Bootstrap 必须生成，是所有角色的前置依赖） |
| 至少一个平台的 Command 文件集 | MUST | 如 `.claude/commands/ilink-{pm,design,coder,qa,refine,approve,status,init}.md` |
| `CLAUDE.md` 或 `AGENTS.md` | SHOULD | 入口路由文件 |

---

## 3. 推荐执行顺序

iLink Bootstrap 与 Host CLI 的 `/init` 命令不冲突，两者可以串行使用：

| 命令 | 来源 | 作用 |
|------|------|------|
| `/init` | Host CLI 自带 | 生成 CLAUDE.md / AGENTS.md，写入项目级说明 |
| `bash iLink/setup.sh` | iLink 脚本 | 框架级初始化（权限、依赖、行尾符） |
| `/ilink-bootstrap` | iLink Slash Command | 项目分析 → 生成 project-context.md → 更新入口文件 |
| `/ilink-init <story>` | iLink Slash Command | 每个 Story 的初始化 |

**推荐执行顺序**：

```
（可选）/init                 — Host CLI 生成入口文件骨架
    ↓
（可选）bash iLink/setup.sh   — 修复权限和依赖
    ↓
/ilink-bootstrap              — AI 分析项目 + 更新入口路由（一次性）
    ↓
/ilink-init <story>           — 每个 Story 都需要
    ↓
/ilink-pm → /ilink-design → ...（正常流水线）
```

`/ilink-bootstrap` MUST 兼容用户已执行过 `/init` 的情况——此时入口文件属于"情况 D（手写或其他工具生成）"，MUST 按迁移流程处理：备份原文件 → 迁移项目知识到 `project-context.md` → 重写为 thin router。
