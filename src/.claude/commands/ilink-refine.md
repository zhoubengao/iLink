你现在执行 iLink 的 **STAGING 修订对话（ilink-refine）** 操作。

## 准备工作

依次读取以下文件：
1. `project-context.md`
2. `iLink/souls/universal.soul.md`
3. `iLink/iLink-root-spec-v1.0.00.md` §6.3（ilink-refine 修订协议）

## 步骤 1：确认 Story 存在

检查 `iLink-doc/$ARGUMENTS/` 目录是否存在，不存在则提示用户先执行 `/ilink-init $ARGUMENTS`。

## 步骤 2：识别 STAGING 文档

按优先级依次检查以下文档的 Metadata Status：

1. `iLink-doc/$ARGUMENTS/$ARGUMENTS-review.master.md`
2. `iLink-doc/$ARGUMENTS/$ARGUMENTS-design.master.md`
3. `iLink-doc/$ARGUMENTS/$ARGUMENTS-pm.master.md`

找到第一个 Status 为 `STAGING` 的文档，即为本次修订目标。

如果没有找到 STAGING 文档，告知用户当前 Story 无需修订，建议执行 `/ilink-status $ARGUMENTS` 查看状态。

## 步骤 3：加载上下文，进入修订模式

根据 STAGING 文档的角色，读取对应 Soul 文件：
- pm.master.md → `iLink/souls/pm.soul.md`
- design.master.md → `iLink/souls/design.soul.md`
- review.master.md → `iLink/souls/qa.soul.md`

读取完整的 STAGING 文档内容。

**进入修订模式**：你的职责是"定点修改"，不是"重新生成"。

## 步骤 4：汇总阻塞项

根据文档类型，找到所有阻塞项：

| 文档 | 阻塞项位置 |
|------|-----------|
| pm.master.md | B5 中的 `[待确认]` 项 + C1 的 NOTIFY_ITEMS |
| design.master.md | [DESIGN_DECISIONS] 中高风险项的 `[待确认]` 标记 |
| review.master.md | [UPSTREAM_BLOCKERS] 中的所有条目 |

**以列表形式逐条呈现给用户**，格式示例：

```
检测到 STAGING 文档：$ARGUMENTS-pm.master.md
共 N 个阻塞项需要决策：

1. [B5-风险-1] 第三方支付回调超时处理方式未确认
   当前标记：[待确认]
   风险等级：H

2. [B5-风险-3] 并发场景下的幂等方案
   当前标记：[待确认]
   风险等级：M

请针对第 1 项给出决策：
```

## 步骤 5：逐条决策

每次只呈现一项，等待用户给出决策后：

1. 将 `[待确认]` 更新为 `[已确认 <YYYY-MM-DD>: <用户给出的决策依据>]`
2. 根据决策内容调整风险等级（H → M 或 M → L）
3. 使用 Edit 工具**就地更新文档**对应位置
4. 明确告知用户："已更新第 X 项"
5. 继续呈现下一项

**修订模式约束（MUST 严格遵守）**：
- MUST 保留文档所有已有内容，仅更新被讨论的阻塞项
- SHALL NOT 重新生成整个文档
- SHALL NOT 修改未被讨论的条目
- MUST 在每次修改后明确告知用户已更新的条目编号

## 步骤 6：清理 NOTIFY_ITEMS（仅限 pm.master.md）

每确认一项后，从 C1 的 NOTIFY_ITEMS 列表中移除对应条目。
所有 NOTIFY_ITEMS 条目均被确认后，写入 `NOTIFY_ITEMS: NONE`。

## 步骤 7：更新 Status

所有阻塞项处理完毕后：

- 若所有 H 级阻塞项已消解 → 将 Status 更新为对应 PENDING 状态：
  - pm.master.md STAGING → `PENDING_DESIGNER`
  - design.master.md STAGING → `PENDING_CODER`（此时仍需 ilink-approve 正式推进）
  - review.master.md STAGING → 维持 STAGING，提示用户按修订结论处理上游问题
- 若仍有未解决的 H 级项 → 维持 `STAGING`

使用 Edit 工具就地更新 Metadata 中的 Status 字段。

## 步骤 8：提示下一步

```
修订完成。

已确认：N 项  |  待处理：0 项
当前 Status：PENDING_DESIGNER

下一步：执行 `/ilink-approve $ARGUMENTS` 正式推进流水线。
```
