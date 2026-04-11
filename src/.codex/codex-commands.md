# iLink — Codex 角色命令指令

> 本文件定义了 iLink 流水线中 AI 角色的命令指令。
> 当用户在对话中输入对应命令加 Story ID 时，按对应角色或操作执行任务。

---

## 命令识别

当用户消息匹配以下模式时，执行对应角色任务：

| 用户输入模式 | 角色/操作 | 示例 |
|------------|---------|------|
| `ilink-bootstrap` | Bootstrap（项目初始化） | `ilink-bootstrap` |
| `ilink-pm <story>` | PM（产品经理） | `ilink-pm jzjy-0001` |
| `ilink-design <story>` | Designer（设计师） | `ilink-design jzjy-0001` |
| `ilink-coder <story>` | Coder（编码工程师） | `ilink-coder jzjy-0001` |
| `ilink-qa <story>` | QA（质量审查员） | `ilink-qa jzjy-0001` |
| `ilink-refine <story>` | 修订对话（STAGING 阻塞解除） | `ilink-refine jzjy-0001` |

> 匹配不区分大小写，`/ilink-pm`、`ilink-pm`、`ILINK-PM` 均视为同一命令。

---

## 通用准备工作

所有角色执行前，依次读取以下文件：

1. `project-context.md`（项目知识库）
2. `iLink/souls/universal.soul.md`（全局行为规范）
3. 对应角色的 Soul 文件（见各角色章节）

---

## ilink-pm <story> — PM 角色

### 准备
- 读取 `iLink/souls/pm.soul.md`

### 前置检查
- 读取 `iLink-doc/<story>/<story>-需求定义.md`
- 如果不存在，提示用户先执行 `bash .codex/commands/ilink-init <story>`

### 执行
1. 分析需求定义，理解业务目标和功能范围
2. 结合 project-context.md，识别与项目相关的技术约束
3. 输出 pm.master.md，严格按照 PM Soul 定义的三层结构（A 层概述 → B 层业务合同 → C 层调度通知 + Metadata）

### 输出
- 写入 `iLink-doc/<story>/<story>-pm.master.md`

### Metadata
```
---
# ILINK-PROTOCOL-METADATA
Protocol_Version: v1.0.00
Role: PM
AI_Vendor: Codex
AI_Model: <工具版本号>
Current_Timestamp: <执行 TZ=Asia/Shanghai date +%Y-%m-%dT%H:%M:%S+08:00>
Normalized_Source_Hash: <执行 shasum <story>-需求定义.md 取第一列>
Target_Files:
Status: PENDING_DESIGNER
---
```
> 存在 H 级风险或逻辑矛盾时，Status 设为 `STAGING`；Current_Timestamp 和 Normalized_Source_Hash 必须通过命令实际获取，不得留占位符

### 完成后
- Status=STAGING → 说明阻塞原因，建议用户审核
- Status=PENDING_DESIGNER → 提示用户执行 `ilink-design <story>`

---

## ilink-design <story> — Designer 角色

### 准备
- 读取 `iLink/souls/design.soul.md`

### 前置检查
- 读取 `iLink-doc/<story>/<story>-pm.master.md`
- 如果不存在，提示用户先执行 `ilink-pm <story>`
- 检查 pm.master.md 的 Metadata Status：
  - STAGING → 提示用户 PM 文档尚未审核通过
  - PENDING_DESIGNER → 继续执行

### 执行
1. 解析 PM 的 B 层业务合同，提取范围契约、硬约束、需求追踪表、验收标准、风险
2. 转化为系统逻辑行为模型：接口定义 → 逻辑流 → 异常分支 → 错误码 → 数据实体
3. 在项目中精确定位变更模块，结合 project-context.md 的模块依赖层次和代码结构
4. 主动探索相关源码：查看 [TASK_ALLOCATION] 涉及的现有代码，确保设计与现有代码兼容
5. 输出 design.master.md，严格按照 Designer Soul 定义的结构
6. [TASK_ALLOCATION] 是 Coder 的唯一工作授权，必须列出每一个文件（包括测试类、配置文件、SQL 脚本），路径精确到文件名，使用项目相对路径（参照 project-context.md）

### 输出
- 写入 `iLink-doc/<story>/<story>-design.master.md`

### Metadata
```
---
# ILINK-PROTOCOL-METADATA
Protocol_Version: v1.0.00
Role: DESIGNER
AI_Vendor: Codex
AI_Model: <工具版本号>
Current_Timestamp: <执行 TZ=Asia/Shanghai date +%Y-%m-%dT%H:%M:%S+08:00>
Normalized_Source_Hash: <执行 shasum <story>-pm.master.md 取第一列>
Target_Files:
Status: STAGING
---
```

### 完成后（Human-Gate）
- Designer 设计默认需要人类审核（Status = STAGING）
- 提示用户审阅 design.master.md，重点关注 [TASK_ALLOCATION] 和 [DESIGN_DECISIONS]
- 审核通过后执行 `bash .codex/commands/ilink-approve <story>` 推进状态
- 然后执行 `ilink-coder <story>` 继续流水线

---

## ilink-coder <story> — Coder 角色

### 准备
- 读取 `iLink/souls/coder.soul.md`

### 前置检查
- 读取 `iLink-doc/<story>/<story>-design.master.md`
- 如果不存在，提示用户先执行 `ilink-design <story>`

### 读取现有源码
- 从 design.master.md 的 [TASK_ALLOCATION] 中提取"修改文件"列表，逐一读取现有源码

### 检查回流
- 检查是否存在 `iLink-doc/<story>/<story>-review.master.md`
- 如果存在且 Status 为 FAIL_BACK_TO_CODER，读取 [FIX_REQUESTS] 和 [UPSTREAM_BLOCKERS]

### 执行

#### 首次编码
1. 严格按照 design.master.md 的类设计和方法签名编码
2. 直接使用文件写入工具将代码写入磁盘（不是在 markdown 中输出代码块）
3. 只写 [TASK_ALLOCATION] 授权的文件
4. 遵守 project-context.md 中定义的编码规范和技术约束
5. 修改现有文件时保持风格一致，不改动无关代码

#### 回流修复
1. 逐条处理 [FIX_REQUESTS] 中的 Issue-ID
2. [UPSTREAM_BLOCKERS] 不在职责范围内
3. 只改必要的代码

### 输出变更摘要
- 写入 `iLink-doc/<story>/<story>-code.master.md`
- 包含：变更清单、接口变更、数据库变更、事务策略、依赖变更、关键实现说明
- [REVIEW_HANDOFF]、[DEVIATIONS]、[FIX_RESPONSE]（回流时）

### Metadata
```
---
# ILINK-PROTOCOL-METADATA
Protocol_Version: v1.0.00
Role: CODER
AI_Vendor: Codex
AI_Model: <工具版本号>
Current_Timestamp: <执行 TZ=Asia/Shanghai date +%Y-%m-%dT%H:%M:%S+08:00>
Normalized_Source_Hash: <执行 shasum <story>-design.master.md 取第一列>
Target_Files: <修改的文件列表，逗号分隔>
Status: PENDING_QA
---
```

### 完成后
- 提示用户检查代码文件
- 执行 `ilink-qa <story>` 进入 QA 审查

---

## ilink-qa <story> — QA 角色

### 准备
- 读取 `iLink/souls/qa.soul.md`

### 前置检查
- 依次读取（任一缺失则提示用户先执行对应角色）：
  1. `iLink-doc/<story>/<story>-pm.master.md`
  2. `iLink-doc/<story>/<story>-design.master.md`
  3. `iLink-doc/<story>/<story>-code.master.md`

### 读取源码
- 从 code.master.md 变更清单中提取所有文件路径，逐一读取磁盘上的实际源码文件
- 文件不存在则记录为 HIGH severity Issue

### 执行五步审查

**第一步：消费 [REVIEW_HANDOFF]**
- 缺失则记录 MISSING_HANDOFF 高优先级 Issue

**第二步：设计符合性审查**
- 对照 design.master.md 逐项检查类结构、方法签名、接口实现、数据层

**第三步：AC 覆盖验收**
- 以 pm.master.md B4 验收标准为基准逐条核对

**第四步：代码质量审查**
- 对照 project-context.md 中的技术约束逐项检查
- 白名单验证、硬约束落地验证

**第五步：回流复核（仅回流时）**
- 逐条验证 [FIX_RESPONSE] 的修复是否有效

### 输出
- 写入 `iLink-doc/<story>/<story>-review.master.md`
- 包含：审查概述、设计符合性审查、AC 覆盖验收、结论
- [REVIEW_FINDINGS]、[FIX_REQUESTS]、[UPSTREAM_BLOCKERS]、[NON_BLOCKING_NOTES]、[RECHECK_SCOPE]

### Metadata
```
---
# ILINK-PROTOCOL-METADATA
Protocol_Version: v1.0.00
Role: QA
AI_Vendor: Codex
AI_Model: <工具版本号>
Current_Timestamp: <执行 TZ=Asia/Shanghai date +%Y-%m-%dT%H:%M:%S+08:00>
Normalized_Source_Hash: <执行 shasum <story>-code.master.md 取第一列>
Target_Files:
Status: <COMPLETED | FAIL_BACK_TO_CODER | STAGING>
---
```

### 完成后
- COMPLETED → Story 完成，建议 git commit
- FAIL_BACK_TO_CODER → 提示用户执行 `ilink-coder <story>` 回流修复
- STAGING → 展示 [UPSTREAM_BLOCKERS]，建议用户执行 `ilink-refine <story>` 讨论上游根因

---

## ilink-refine <story> — STAGING 修订对话

> **触发时机**：当前 Story 存在 STAGING 文档且文档中有 `[待确认]` 项或其他阻塞原因。

### 准备
依次读取以下文件：
1. `project-context.md`
2. `iLink/souls/universal.soul.md`
3. `iLink/iLink-root-spec-v1.0.00.md` §6.3（ilink-refine 修订协议）

### 前置检查
- 检查 `iLink-doc/<story>/` 目录是否存在，不存在则提示用户先执行 `bash .codex/commands/ilink-init <story>`

### 识别 STAGING 文档
按优先级依次检查以下文档的 Metadata Status：
1. `<story>-review.master.md`
2. `<story>-design.master.md`
3. `<story>-pm.master.md`

找到第一个 Status 为 `STAGING` 的文档，读取对应角色 Soul 文件：
- pm → `iLink/souls/pm.soul.md`
- design → `iLink/souls/design.soul.md`
- review → `iLink/souls/qa.soul.md`

如果没有 STAGING 文档，告知用户并建议执行 `bash .codex/commands/ilink-status <story>`。

### 执行（修订模式）

**进入修订模式**：职责是"定点修改"，不是"重新生成"。

根据文档类型找到阻塞项：

| 文档 | 阻塞项位置 |
|------|-----------|
| pm.master.md | B5 中的 `[待确认]` 项 + C1 的 NOTIFY_ITEMS |
| design.master.md | [DESIGN_DECISIONS] 中高风险项的 `[待确认]` 标记 |
| review.master.md | [UPSTREAM_BLOCKERS] 中的所有条目 |

逐条呈现给用户，等待决策后：
1. 将 `[待确认]` 更新为 `[已确认 YYYY-MM-DD: <决策依据>]`
2. 调整风险等级
3. 就地更新文档
4. 告知用户已更新的条目编号
5. 继续下一项

**修订约束**：
- MUST 保留文档所有已有内容，仅更新被讨论的阻塞项
- SHALL NOT 重新生成整个文档
- SHALL NOT 修改未被讨论的条目

### 完成后

所有 H 级阻塞项消解后，更新 Status：
- pm.master.md STAGING → `PENDING_DESIGNER`
- design.master.md STAGING → `PENDING_CODER`
- review.master.md STAGING → 维持 STAGING，提示用户处理上游

Status 更新后提示：
```
修订完成，Status 已更新为 PENDING_xxx。
下一步：执行 bash .codex/commands/ilink-approve <story> 正式推进流水线。
```

---

## ilink-bootstrap — 项目初始化（Bootstrap）

> **目标**：让当前项目具备运行 iLink 流水线的完整环境。执行完毕后，无论哪个 AI 平台（Claude / Codex / Qoder）的用户打开本项目，都能被引导到 iLink 工作体系。
>
> **何时执行**：新项目首次引入 iLink 框架时执行一次。详见 Root Spec §12.1.1 "何时执行 Bootstrap"。

### 前置准备

在终端执行 `bash .codex/commands/ilink-bootstrap` 进行预检查（检查框架文件是否齐备），然后在 Codex 对话中输入 `ilink-bootstrap` 触发本 AI 指令。

---

### 步骤 1：检查 iLink 框架文件

确认以下文件存在，缺失则告知用户需要先复制 iLink 框架文件到项目：

- `iLink/iLink-root-spec-v1.0.00.md`（根规范）
- `iLink/souls/universal.soul.md`
- `iLink/souls/pm.soul.md`
- `iLink/souls/design.soul.md`
- `iLink/souls/coder.soul.md`
- `iLink/souls/qa.soul.md`

如果以上文件全部缺失，停止执行，提示用户先复制 iLink 框架。

### 步骤 2：检查 Codex Command 文件

确认 `.codex/commands/` 下存在以下文件：
- `ilink-init`
- `ilink-approve`
- `ilink-status`

缺失时给出警告（不阻塞，因为可能使用其他平台）。

---

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
     - 如果是手写或其他 AI 工具（Claude `/init`、Qoder `/init`、Codex `/init` 等）生成的项目说明文件 → **MUST 将其中的项目信息完整迁移到 `project-context.md`**（注意：是迁移而非引用，因为原文件将在步骤 5/6 中被替换为 iLink 薄路由，原文件会被备份）
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

### 步骤 5：更新 CLAUDE.md

读取项目根目录的 `CLAUDE.md` 文件，按以下情况分别处理（**与步骤 6 AGENTS.md 处理逻辑完全一致**）：

**情况 A：CLAUDE.md 不存在**
→ 直接创建 iLink 薄路由内容（见下文模板）。这样后续如果有人执行 Claude Code `/init`，会读到 iLink 引导而不会重新生成项目说明。

**情况 B：CLAUDE.md 已是 iLink 引导且引用 Root Spec v1.0.00**
→ 跳过，无需修改。

**情况 C：CLAUDE.md 已是 iLink 引导但引用旧版本**（如 v0.2、v1.5、SRS）
→ 更新版本引用为 Root Spec v1.0.00。

**情况 D：CLAUDE.md 是手写或其他工具生成的项目说明**（不含 iLink 协作协议关键词）⭐
→ 执行**迁移流程**：

1. **备份原文件**：将原 `CLAUDE.md` 重命名为 `CLAUDE.md.bak.<YYYYMMDD_HHMMSS>`（使用当前时间戳，例如 `CLAUDE.md.bak.20260409_153022`）。使用 Bash 工具执行 `mv` 命令。

2. **确认内容已迁移**：
   - 如果步骤 4 已经将原 CLAUDE.md 内容迁移到 `project-context.md` → 直接进入下一步
   - 如果 `project-context.md` 已存在但缺少原 CLAUDE.md 中的关键信息 → 补充到 project-context.md 的对应章节
   - 迁移时**保留所有有价值的项目知识**，不丢失任何技术约束、构建命令、模块说明、架构决策

3. **重写 CLAUDE.md** 为 iLink 薄路由内容（见下文模板）。

4. **明确告知用户**：在最终报告（步骤 9）中说明：
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

本项目使用 iLink 多角色 AI 协作流水线（Root Spec v1.0.00）。

### 核心文件

- `iLink/iLink-root-spec-v1.0.00.md` — 根规范（所有 AI Agent 的行为准则）
- `project-context.md` — **项目知识库的单一事实源**（所有项目级技术信息：构建命令、架构、模块说明、技术约束、编码规范）
- `iLink/souls/*.soul.md` — 角色规范（PM / Designer / Coder / QA）

### 流水线命令

ilink-init <story>     → 创建 Story 目录和需求模板
ilink-pm <story>       → PM：需求分析 → 业务合同
ilink-design <story>   → Designer：技术设计 → 文件级任务清单
ilink-coder <story>    → Coder：按设计编码 → 直接写入磁盘
ilink-qa <story>       → QA：代码审查 → 审查报告

Designer 完成后默认需要人类审核（Human-Gate），审核通过后执行：
`bash .codex/commands/ilink-approve <story>`
```

---

### 步骤 6：更新 AGENTS.md

读取项目根目录的 `AGENTS.md` 文件，按以下情况分别处理：

**情况 A：AGENTS.md 不存在**
→ 直接创建 iLink 薄路由内容（见下文模板）。

**情况 B：AGENTS.md 已是 iLink 引导且引用 Root Spec v1.0.00**
→ 跳过，无需修改。

**情况 C：AGENTS.md 已是 iLink 引导但引用旧版本**（如 v0.2、v1.5、SRS）
→ 更新版本引用为 Root Spec v1.0.00，保留其他自定义内容。

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

本项目使用 iLink 多角色 AI 协作流水线（Root Spec v1.0.00）。

### 核心文件

| 文件 | 用途 |
|------|------|
| `iLink/iLink-root-spec-v1.0.00.md` | 根规范（所有 AI 的行为准则） |
| `project-context.md` | **项目知识库的单一事实源**（技术约束、构建命令、模块职责、架构、编码规范） |
| `iLink/souls/*.soul.md` | 角色规范（PM / Designer / Coder / QA） |

### 快速开始

1. 读取 `project-context.md` 了解项目
2. 创建 Story：执行 `bash .codex/commands/ilink-init <story-id>`
3. 按流水线执行：`ilink-pm` → `ilink-design` → `ilink-approve` → `ilink-coder` → `ilink-qa`

### 角色触发

当用户输入 `ilink-pm <story>`、`ilink-design <story>`、`ilink-coder <story>`、`ilink-qa <story>` 时：

**Codex CLI 用户**：AI 读取 `.codex/codex-commands.md` 中对应角色章节执行任务。Shell 脚本用于准备输入和流水线状态流转。

**其他 CLI 用户**：请先读取 `iLink/iLink-root-spec-v1.0.00.md` §4（角色行为规范），然后读取对应的 Soul 文件执行任务。

### Shell 工具

| 命令 | 用途 |
|------|------|
| `bash .codex/commands/ilink-init <story>` | 创建 Story |
| `bash .codex/commands/ilink-status [story]` | 查看状态 |
| `bash .codex/commands/ilink-approve <story>` | 审核推进 |
```

---

### 步骤 7：创建 iLink-doc 目录

如果 `iLink-doc/` 目录不存在，创建它。

---

### 步骤 8：执行验证

检查以下项目并输出报告：

| 检查项 | 状态 |
|-------|------|
| iLink 框架文件（souls/） | ✅ / ❌ |
| project-context.md | ✅ 已存在 / 🆕 已生成 / 🔄 已迁移自 CLAUDE.md+AGENTS.md / ❌ 缺失 |
| CLAUDE.md iLink 引导 | ✅ 已存在 / 🆕 已创建 / 🔄 已重写（原文件备份） |
| AGENTS.md iLink 引导 | ✅ 已存在 / 🆕 已创建 / 🔄 已重写（原文件备份） |
| iLink-doc/ 目录 | ✅ 已存在 / 🆕 已创建 |
| Codex Command 文件 | ✅ / ⚠️ 部分缺失 |

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
4. 创建第一个 Story：bash .codex/commands/ilink-init <story-id>
```

---

## Shell 工具命令

以下操作需在终端中执行（非 AI 角色任务）：

| 命令 | 用途 |
|------|------|
| `bash .codex/commands/ilink-bootstrap` | Bootstrap 预检查（然后执行 `ilink-bootstrap`） |
| `bash .codex/commands/ilink-init <story>` | 创建 Story 目录和需求模板 |
| `bash .codex/commands/ilink-status [story]` | 查看流水线状态 |
| `bash .codex/commands/ilink-approve <story>` | 审核通过，推进 STAGING/PENDING 状态 |

---

## 流水线状态机

```
ilink-init → 需求定义
    |
ilink-pm → pm.master.md
    ├─ PENDING_DESIGNER → ilink-design
    └─ STAGING → ilink-refine（逐条解除阻塞）→ ilink-approve → PENDING_DESIGNER
                                                               ↓
ilink-design → design.master.md (STAGING，Human-Gate)
    ├─ ilink-refine（有 [待确认] 项时可用）→ 解除后 ilink-approve → PENDING_CODER
    └─ ilink-approve（人类直接审核通过）→ PENDING_CODER
                                          ↓
ilink-coder → code.master.md + source files (PENDING_QA)
    |
ilink-qa → review.master.md
    ├─ COMPLETED → Done
    ├─ FAIL_BACK_TO_CODER → 回流 ilink-coder
    └─ STAGING → ilink-refine（讨论上游根因，明确修改路径）
```
