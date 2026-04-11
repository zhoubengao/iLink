你现在执行 iLink 的 **审核通过（Human-Gate 推进）** 操作。

## 执行任务

在 Story `$ARGUMENTS` 中找到处于 STAGING 状态的文档，将其推进到下一阶段。

### 步骤 1：确认 Story 存在

检查 `iLink-doc/$ARGUMENTS/` 目录是否存在，不存在则提示用户先执行 `/ilink-init $ARGUMENTS`。

### 步骤 2：按优先级查找 STAGING 文档

依次读取以下文件末尾的 Metadata Status：

1. **QA 文档** `$ARGUMENTS-review.master.md`
   - 如果 Status 为 STAGING → **不能自动推进**（上游根因问题）
   - 告知用户：查看 [UPSTREAM_BLOCKERS] 区块，与 Designer 讨论修改设计或修改需求定义
   - 结束操作

2. **Designer 文档** `$ARGUMENTS-design.master.md`
   - 如果 Status 为 STAGING → 将 Status 更新为 `PENDING_CODER`
   - 提示下一步：`/ilink-coder $ARGUMENTS`

3. **PM 文档** `$ARGUMENTS-pm.master.md`
   - 如果 Status 为 STAGING → 将 Status 更新为 `PENDING_DESIGNER`
   - 提示下一步：`/ilink-design $ARGUMENTS`

### 步骤 3：更新 Status

使用 Edit 工具，在对应文档的 Metadata 区块中将 `Status: STAGING` 替换为目标状态值。

### 如果没有找到 STAGING 文档

告知用户当前没有需要审核的文档，建议执行 `/ilink-status $ARGUMENTS` 查看详细状态。
