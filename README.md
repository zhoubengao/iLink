# iLink — 让 AI 像团队一样协作开发

**CLI-native 的 AI 多角色软件开发协作框架**

iLink 将单一 AI 拆分为 4 个专职角色（PM、Designer、Coder、QA），通过文件状态机驱动端到端的软件交付流水线。关键节点人类审核，其余由 AI 完成。

```
人类写需求 → AI 分析需求 → AI 技术设计 → ⛔人类审核 → AI 编码 → AI 审查 → 人类提交
               PM            Designer    Human-Gate    Coder       QA
```

## 解决什么问题

当前主流 AI 编程工具（Copilot、Cursor、Claude Code 等）都是**"一个 AI 做所有事"**的模式，带来三个结构性问题：

| 问题 | 表现 | iLink 的解决方式 |
|------|------|-----------------|
| **上下文膨胀** | 任务复杂时 AI 的上下文越来越长，质量下降 | 每个角色只读取自己需要的上游文档，Context 精简 |
| **自我合理化** | AI 自审代码容易"看着都对"，难以发现自身错误 | 下游角色天然审查上游产出，链式交叉审查 |
| **控制粒度粗** | 只能全程手动或全程放手，缺少中间态 | Human-Gate 机制，人类可在任意节点精确介入 |

## 核心特性

- **角色分工流水线**：PM → Designer → Coder → QA，每个角色职责清晰、互不越权
- **文件状态机**：所有状态保存在 Markdown 文件中，不依赖内存，支持断点续跑和跨机器接力
- **Human-Gate**：设计阶段默认需要人类审核，审核通过后才能编码。团队建立信任后可逐步放开
- **QA 回流 + 熔断**：代码审查不通过时自动回流修复，连续 3 次不过强制熔断，要求人类介入
- **Story 隔离**：每个需求一个独立目录，完整文档链，互不干扰，天然适配 Jira/工单驱动的迭代开发
- **Metadata 印章**：每份文档记录角色、AI 模型、时间戳、语义 Hash，构成可追溯的决策链
- **模型无关**：核心资产全部是纯 Markdown，不绑定特定 LLM。Claude、GPT、Qwen 均可使用
- **多平台支持**：同一套协议可运行在 Claude CLI、Qoder CLI、Codex CLI 等不同 Host CLI 上
- **CLI-native**：不自建 LLM 调用层，充分利用 Host CLI 的原生能力

## 快速开始

### 前置条件

- 一个已有的项目（任何语言、任何框架）
- 已安装至少一个支持的 Host CLI（Claude CLI / Qoder CLI / Codex CLI）

### 第一步：复制 iLink 到你的项目

```bash
# 将 iLink 框架文件复制到项目根目录
cp -r iLink/ <your-project>/iLink/

# 根据你使用的 CLI，复制对应的 commands 目录
# Claude CLI 用户：
cp -r .claude/ <your-project>/.claude/

# Qoder CLI 用户：
cp -r .qoder/ <your-project>/.qoder/

# Codex CLI 用户：
cp -r .codex/ <your-project>/.codex/
```

### 第二步：项目冷启动（一次性）

```bash
# 初始化环境（权限、依赖检查）
bash iLink/setup.sh

# AI 分析项目 → 生成 project-context.md → 更新入口文件
/ilink-bootstrap
```

Bootstrap 会自动：
1. 分析项目的技术栈、模块结构、构建命令
2. 生成 `project-context.md`（项目知识库）
3. 配置入口文件（`CLAUDE.md` / `AGENTS.md`）

### 第三步：日常开发

```bash
# 创建 Story（对应你的 Jira 单号）
/ilink-init kcia-1520

# 编辑需求定义（你唯一需要手写的文件）
# 打开 iLink-doc/kcia-1520/kcia-1520-需求定义.md

# 启动 AI 流水线
/ilink-pm kcia-1520          # AI 需求分析 → 输出业务合同
/ilink-design kcia-1520      # AI 技术设计 → 输出文件清单

# 你审核设计（最重要的审核点）
ilink-approve kcia-1520      # 审核通过后推进

# AI 编码 + AI 审查
/ilink-coder kcia-1520       # AI 按设计写代码，直接写入磁盘
/ilink-qa kcia-1520          # AI 审查代码，输出审查报告

# 你最终确认后提交
git add iLink-doc/kcia-1520/ src/
git commit -m "kcia-1520: 功能描述（iLink 交付）"
```

## 架构概览

### 系统层次

```
┌──────────────────────────────────────────┐
│       人类（Dev / Tech Lead）              │
│  /ilink-init → /ilink-pm → /ilink-design │
│  → ilink-approve → /ilink-coder → /qa    │
└──────────────┬───────────────────────────┘
               │ 手动触发
┌──────────────▼───────────────────────────┐
│    Host CLI（Claude / Qoder / Codex）      │
│  原生能力：LLM 调用、代码搜索、文件读写     │
├──────────────────────────────────────────┤
│    Slash Command 层（声明式 Markdown）      │
│  /ilink-pm  /ilink-design  /ilink-coder   │
├──────────────────────────────────────────┤
│    Bash 辅助脚本层（轻量）                  │
│  ilink-init / ilink-status / ilink-approve │
│  _common.sh（Metadata 注入、回流计数）      │
└──────────────────────────────────────────┘
```

### 流水线状态流转

```
需求定义.md（人类编写）
    │ /ilink-pm
    ▼
pm.master.md [PENDING_DESIGNER]
    │ /ilink-design
    ▼
design.master.md [STAGING] ──→ ilink-approve ──→ [PENDING_CODER]
    │ /ilink-coder
    ▼
code.master.md + 源码文件 [PENDING_QA]
    │ /ilink-qa
    ▼
review.master.md
├── COMPLETED ──→ 人类审核 → git commit
├── FAIL_BACK_TO_CODER ──→ /ilink-coder（回流修复，≤3 次）
└── STAGING ──→ 人类介入（上游根因）
```

### 文档层级

```
Root Spec（根规范，所有 AI 的"宪法"）
    ↓ 派生
Soul 文件（角色规范，"岗位说明书"）
    ↓ 实现
Command 文件（平台实现，"操作手册"）
```

冲突解决：Root Spec > Soul 文件 > Command 文件

## 四个角色

| 角色 | 职责 | 输入 | 输出 |
|------|------|------|------|
| **PM** | 将需求定义转化为结构化的业务合同 | 需求定义.md | pm.master.md |
| **Designer** | 将业务合同转化为技术设计 + 文件级任务清单 | pm.master.md + 源码 | design.master.md |
| **Coder** | 严格按设计编写代码，直接写入磁盘 | design.master.md + 源码 | 代码文件 + code.master.md |
| **QA** | AI Code Review，对照设计和验收标准审查代码 | code + design + pm + 源码 | review.master.md |

每个角色的行为由对应的 Soul 文件（`iLink/souls/*.soul.md`）定义，所有角色共享 `universal.soul.md` 中的通用行为准则。

## 目录结构

```
<your-project>/
├── project-context.md                  ← 项目知识库（单一事实源）
├── CLAUDE.md / AGENTS.md               ← 入口路由文件（薄路由）
│
├── iLink/                              ← 框架资产（提交到 Git）
│   ├── iLink-root-spec-v1.0.00.md         ← 根规范
│   ├── iLink-implementation-guide-v1.0.00.md ← 实施手册
│   ├── setup.sh                           ← 环境初始化脚本
│   └── souls/                             ← 角色规范
│       ├── universal.soul.md
│       ├── pm.soul.md
│       ├── design.soul.md
│       ├── coder.soul.md
│       └── qa.soul.md
│
├── iLink-doc/                          ← Story 文档（提交到 Git）
│   └── <story-id>/
│       ├── <id>-需求定义.md                ← 人类编写
│       ├── <id>-pm.master.md              ← AI 输出
│       ├── <id>-design.master.md          ← AI 输出，人类审核
│       ├── <id>-code.master.md            ← AI 输出
│       └── <id>-review.master.md          ← AI 输出
│
├── .claude/commands/                   ← Claude CLI 命令
├── .qoder/commands/                    ← Qoder CLI 命令
├── .codex/commands/                    ← Codex CLI 命令
└── src/                                ← 你的源代码
```

## 支持的 Host CLI

| Host CLI | 命令目录 | 触发方式 |
|----------|---------|---------|
| **Claude CLI** | `.claude/commands/*.md` | `/ilink-pm <story>` |
| **Qoder CLI** | `.qoder/commands/*` | `/ilink-pm <story>` |
| **Codex CLI** | `.codex/commands/*` | 对话中输入 `ilink-pm <story>` |

同一个项目中，不同开发者可以使用不同的 CLI 工具——Master Doc 格式统一，跨平台无缝接力。

## 命令速查

| 命令 | 用途 | 频率 |
|------|------|------|
| `/ilink-bootstrap` | 项目冷启动（生成项目知识库） | 每个项目一次 |
| `/ilink-init <story>` | 创建 Story 目录和需求模板 | 每个需求一次 |
| `/ilink-pm <story>` | AI 需求分析 | 每个 Story |
| `/ilink-design <story>` | AI 技术设计 | 每个 Story |
| `ilink-approve <story>` | 人类审核推进 | 审核通过后 |
| `/ilink-coder <story>` | AI 编码 | 设计通过后 |
| `/ilink-qa <story>` | AI 代码审查 | 编码完成后 |
| `ilink-status [story]` | 查看流水线状态 | 随时 |

> `/ilink-*` 是 AI 执行的 Slash Command，`ilink-*`（无斜杠）是 Shell 脚本。

## 与 OpenSpec / OhMyOpenCode 的关系

**iLink 不是替代品，而是可叠加的协作增强层。**

| 维度 | OpenSpec | OhMyOpenCode | iLink |
|------|---------|-------------|-------|
| **核心理念** | 规格驱动开发 | 多智能体并行编排 | 角色分工流水线 |
| **工作粒度** | 单次变更 | 任务分解 | Story（需求单元） |
| **擅长场景** | 维护系统规格 | 快速探索、并行执行 | Jira 驱动迭代、合规审计 |
| **审查方式** | 规格 diff + 人工确认 | 智能体间协调 | 链式审查 + Human-Gate |
| **状态持久化** | spec 文件 | 内存/临时 | Master Doc 文件 |
| **审计追溯** | 通过 spec 历史 | 较弱 | Metadata 印章 + 文档链 |

### 叠加使用

iLink 可以与上述方案共存，为其提供补充能力：

- **Story 隔离**：为每个变更提供独立目录和完整追溯
- **角色流水线**：补充顺序审查链，弥补并行模式的质量控制缺口
- **Human-Gate**：增加关键节点的人类审核控制点
- **Metadata 印章**：让产出可追溯、可审计

### 非侵入性设计

- 所有 iLink 文件位于 `iLink/` 和 `iLink-doc/` 目录，与源码隔离
- 不修改源码、不修改构建配置
- 随时移除 `iLink/` 目录，零残留

## 适用场景

**推荐使用 iLink 的场景**：
- Jira/工单驱动的迭代开发
- 金融、政务等合规敏感领域（需要决策审计链）
- Legacy 系统维护（强约束技术栈、隐式架构规则多）
- 多人协作的中大型项目

**直接对话可能更合适的场景**：
- 快速探索和原型开发
- 简单的 bug 修复
- 一次性脚本编写

**两种模式可以共存**：走 iLink 流水线做正式需求，直接对话做日常修复。

## 文档导航

| 文档 | 内容 | 适合谁 |
|------|------|-------|
| [Root Spec](iLink-root-spec-v1.0.00.md) | 核心协议规范（状态机、角色契约、字段语义） | 想深入了解协议的人 |
| [Implementation Guide](iLink-implementation-guide-v1.0.00.md) | Bootstrap 协议、脚手架规范、推荐执行顺序 | 项目管理者、初次部署的人 |
| [Human Guide](iLink-human-guide-v1.0.00.md) | 日常使用实操手册（写需求、审设计、处理回流） | 所有开发者 |
| [Intro (简介)](iLink-intro-v1.0.00.md) | 面向团队的介绍材料 | 评估是否引入 iLink 的人 |

## 设计原则

1. **CLI-native**：不自建 LLM 调用层，利用 Host CLI 的原生能力
2. **文件状态机**：所有状态保存在文件中，不依赖内存
3. **模型无关**：纯 Markdown，不绑定特定 LLM
4. **平台可移植**：Soul 文件和 Master Doc 格式跨平台一致
5. **最小自研**：只在 Host CLI 无法覆盖的地方写 bash 脚本
6. **薄路由 + 单一事实源**：入口文件只做路由，项目知识集中在 `project-context.md`

## 接入成本

| 项目 | 成本 |
|------|------|
| 安装额外软件 | **零**（用现有的 CLI 工具） |
| 修改现有代码 | **零** |
| 修改构建配置 | **零** |
| 执行 Bootstrap | 一次，约 5 分钟 |
| 日常使用 | 记住 6 个命令 |
| 移除 | 删掉 `iLink/` 和 `iLink-doc/`，零残留 |

## 版本

当前版本：**v1.0.00**（正式版）

- Root Spec: `iLink-root-spec-v1.0.00.md`
- Implementation Guide: `iLink-implementation-guide-v1.0.00.md`

## 作者

周本高

## 许可证

[Apache-2.0 license]
