你现在执行 iLink 的 **流水线状态查看** 操作。

## 执行任务

### 无参数模式（$ARGUMENTS 为空）

扫描 `iLink-doc/` 下的所有子目录，列出所有 Story 的概览状态表格：

| Story | 当前阶段 | 状态 |
|-------|---------|------|

**阶段判断逻辑**（按优先级从高到低检查文件是否存在）：

1. 存在 `review.master.md` → 读取 Status：
   - COMPLETED → 已完成
   - FAIL_BACK_TO_CODER → QA 回流
   - STAGING → QA（上游问题）
   - 其他 → QA 审查中
2. 存在 `code.master.md` → 编码完成
3. 存在 `design.master.md` → 读取 Status：STAGING=设计待审核，其他=设计完成
4. 存在 `pm.master.md` → 读取 Status：STAGING=PM 待审核，其他=PM 完成
5. 存在 `requirement.md` → 需求已定义
6. 否则 → 未初始化

### 有参数模式

查看指定 Story `$ARGUMENTS` 的详细状态：

1. 确认 `iLink-doc/$ARGUMENTS/` 目录存在
2. 逐个检查以下文件，读取末尾 Metadata 中的 Status 字段：
   - `$ARGUMENTS-requirement.md`
   - `$ARGUMENTS-pm.master.md`
   - `$ARGUMENTS-design.master.md`
   - `$ARGUMENTS-code.master.md`
   - `$ARGUMENTS-review.master.md`
3. 以表格展示每个文档的状态（存在/不存在 + Status 值）
4. 检查 `.retry_count` 文件，如存在则显示回流次数
5. 如果回流次数 ≥ 3，显示**熔断警告**：Coder 已自动修复 3 次仍未通过 QA，请人类介入

## 下一步建议

根据当前阶段给出操作建议：

| 当前状态 | 建议操作 |
|---------|---------|
| 需求已定义 | `/ilink-pm $ARGUMENTS` |
| PM STAGING | 审核 pm.master.md → `/ilink-approve $ARGUMENTS` |
| PM PENDING_DESIGNER | `/ilink-design $ARGUMENTS` |
| 设计 STAGING | 审核 design.master.md → `/ilink-approve $ARGUMENTS` |
| 设计 PENDING_CODER | `/ilink-coder $ARGUMENTS` |
| 编码完成 | `/ilink-qa $ARGUMENTS` |
| QA COMPLETED | Story 完成，建议 git commit |
| QA FAIL_BACK_TO_CODER | `/ilink-coder $ARGUMENTS`（回流修复） |
| QA STAGING | 查看 [UPSTREAM_BLOCKERS]，人类介入 |

## Metadata 读取方法

在每个 master doc 文件末尾查找以下格式的区块，提取 `Status:` 的值：

```
---
# ILINK-PROTOCOL-METADATA
Role: ...
Status: <读取这个值>
---
```
