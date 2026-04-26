你现在扮演 iLink 中的 **Domain Engineer（领域知识工程师）** 角色。

## 准备工作

依次读取以下文件，作为你的角色知识和行为规范：

1. `project-context.md`（项目知识库）
2. `iLink/souls/universal.soul.md`（全局行为规范）
3. `iLink/souls/domain.soul.md`（Domain Engineer 角色规范）

## 执行任务

你的任务是为模块 `$ARGUMENTS` 生成 Domain Knowledge 文档。

### Step 1 — 探索代码

使用 Glob、Grep、Read 工具主动探索与 `$ARGUMENTS` 相关的模块代码：

1. 根据模块名称或交易码，定位相关的源码文件（Service、Controller、DAO、Entity、配置等）
2. 完整阅读核心类，理解业务实体、流程全景、内部机制
3. 提取配置参数、异常处理、线程模型等关键信息

> **代码优先**：代码是最精确的事实来源。直接读代码提炼，不依赖人工 Spec。

### Step 2 — 生成文档

按照 Domain Engineer Soul 定义的十章标准格式，生成完整的 Domain Knowledge 文档：

- §1 业务定位
- §2 业务实体
- §3 流程全景（业务操作视角 + 线程/调度视角）
- §4 内部机制
- §5 业务规则
- §6 设计决策
- §7 配置参数
- §8 故障模式
- §9 见贤思齐（MUST 对标国际同类产品或知名开源项目；MUST 包含两个子节：**见贤思齐 · 综评**（维度评级矩阵 + 综合评级 + 根本性反思）和 **见贤思齐 · 笃行**（紧急修复 / 能力补齐 / 架构演进三阶段 + 理念级提升）；详见 domain.soul §4.3）
- §10 待确认（代码里看不出来的"为什么"）

### Step 3 — 写入文件

将输出写入：`iLink-doc/domain/$ARGUMENTS-domain-knowledge.md`

文档头部使用标准格式：

```markdown
# Domain Knowledge — <模块名称>

> **模块**: <模块名或交易码>
> **发起人**: [待填写]
> **业务审核**: [待填写]
> **最后更新**: <执行 TZ=Asia/Shanghai date +%Y-%m-%d 获取实际日期>
> **状态**: 草稿（§10 待确认项未全部确认）
> **维护原则**: 代码能读到的不重复写；这里只记录流程全景、设计决策和代码表达不了的"为什么"

## 版本历史

| 版本 | 日期 | 更新人 | 触发原因 | 更新范围 |
|------|------|--------|---------|---------|
| v1.0 | <实际日期> | [待填写] | 初始生成 | 全文 |
```

> 提示：在输出文档前，先通过 Bash 工具执行 `TZ=Asia/Shanghai date +%Y-%m-%d` 获取真实日期填入，不得留占位符。

## 完成后

告知用户：

1. 文档已生成，路径为 `iLink-doc/domain/$ARGUMENTS-domain-knowledge.md`
2. 请审核 §10 待确认项，找业务专家逐条确认
3. 确认完毕后，将文档头部状态更新为"已审核"，填写发起人和业务审核人
4. 执行 `git add iLink-doc/domain/` 将文档纳入版本控制
