你现在执行 iLink 的 **Story 初始化** 操作。

## 执行任务

### 步骤 1：检查

检查目录 `iLink-doc/$ARGUMENTS/` 是否已存在。如果已存在，告知用户该 Story 已初始化，并建议执行 `/ilink-status $ARGUMENTS` 查看当前状态。

### 步骤 2：创建 Story 目录和需求定义模板

1. 创建目录 `iLink-doc/$ARGUMENTS/`
2. 创建文件 `iLink-doc/$ARGUMENTS/$ARGUMENTS-需求定义.md`，内容如下：

```
# $ARGUMENTS：<请填写需求标题>

## 功能描述

<请描述本需求要解决的问题和预期效果>

## 功能范围

### In Scope（必须实现）

1. <功能点1>
2. <功能点2>

### Out of Scope（明确排除）

1. <排除项1>

## 验收标准

| AC-ID | 验收标准 | 验证方式 |
|-------|---------|---------|
| AC-01 | <Given... When... Then...> | 单元测试/代码审查 |
| AC-02 | <Given... When... Then...> | 单元测试/代码审查 |

## 约束备注

| 编号 | 约束类型 | 约束内容 |
|------|---------|---------|
| HC-01 | 技术 | <技术约束> |
| HC-02 | 业务 | <业务约束> |

## 假设与风险

| 编号 | 类型 | 内容 | 风险等级 |
|------|------|------|---------|
| AR-01 | 假设 | <假设条件> | M |

## 关联领域知识（可选）

<!-- 如果本需求涉及已有 Domain Knowledge 的模块，在此指定文件路径，PM 和 Designer 将纳入参考 -->
<!-- 示例：iLink-doc/domain/login-410301-domain-knowledge.md -->
<!-- 无关联时删除本节或留空 -->
```

## 完成后

告知用户：
1. 编辑 `iLink-doc/$ARGUMENTS/$ARGUMENTS-需求定义.md`，填写需求内容
2. 完成后执行 `/ilink-pm $ARGUMENTS` 继续流水线
