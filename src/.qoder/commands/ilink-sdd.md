# ilink-sdd

Trigger SDD Applicability Assessment for the project or a specific module.

## Usage

```
/ilink-sdd [scope]
```

- `scope`: optional, defaults to `project`. Can be a module name or any descriptive scope identifier.

## Preparation

The bash script `.qoder/commands/ilink-sdd` has already prepared the context. Now:

1. Read `project-context.md`
2. Read `iLink/souls/universal.soul.md`
3. Read `iLink/souls/sdd.soul.md`
4. Read `iLink-doc/sdd-analysis.md` (this is your assessment standard)

## Task

Follow the SDD Assessment Engineer Soul specification to:

1. Explore the project/module code using Glob, Grep, Read tools
2. **First check: Instance Scale (一票否决项)** — 统计通过 §2.4 三步过滤链后的真实业务实例数。1~4 个实例直接判定低适配度，无需继续评估
3. 对通过实例规模关的模块，按四维评估模型逐项分析（可提取性, 稳定性, 状态封闭性）
4. Apply the three-step governance boundary filter (§2.4)
5. Evaluate internal abstraction coverage (新增维度: 无/部分/深度)
6. Analyze four-layer comparison (硬编码 → 配置化 → 内部DSL → AI直接派生)
7. Generate a standardized SDD assessment report

## Output

Write to: `iLink-doc/sdd/sdd-assessment-<scope>.md`

Use the standard document header format with actual date (run `TZ=Asia/Shanghai date +%Y-%m-%d` to get it).

## After Completion

1. Inform the user the report has been generated
2. Ask them to review the assessment conclusions
3. Remind them to fill in 评估人 and 审核人, update status to "已审核"
4. Suggest `git add iLink-doc/sdd/` to version control the report
