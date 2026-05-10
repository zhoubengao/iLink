# ilink-approve

Run the iLink Human-Gate advance: Coach reflection subprocess + Status advance.

## Usage

```
/ilink-approve <story>
```

## Preparation

The bash script `.qoder/commands/ilink-approve <story>` has already validated the STAGING document and reported which document will be advanced. Now in this slash invocation:

1. Read `iLink/iLink-root-spec.md` §4.7 (Coach role contract) and §6.4 (ilink-approve protocol)
2. Read `iLink/souls/coach.soul.md` (Coach role specification)

## Task

Execute the following steps in order. **Coach subprocess errors SHALL NOT block Status advance.**

### Step 1: Resolve target STAGING document

Re-confirm the STAGING document by checking, in priority order:

1. `iLink-doc/<story>/<story>-review.master.md` → if STAGING, target is QA review (no Status advance, only Coach)
2. `iLink-doc/<story>/<story>-design.master.md` → if STAGING, target advances to `PENDING_CODER`
3. `iLink-doc/<story>/<story>-pm.master.md` → if STAGING, target advances to `PENDING_DESIGNER`

If no STAGING document found, tell the user and stop.

### Step 2: Coach subprocess

#### 2.1 Excerpt conversation bracket

Identify in the **current Qoder chat session**:

- **Outer window start**: first human turn after the `ilink-pm <story>` / `/ilink-pm <story>` invocation
- **Outer window end**: last human turn before this `/ilink-approve <story>` invocation
- **Internal divider**: the `/ilink-design <story>` (or `ilink-design <story>`) slash invocation turn

Excerpt every turn verbatim with `[turn-N] (user|assistant)` labels. Mark the divider as `[--- /ilink-design 分界 ---]`. **SHALL NOT** rewrite, summarize, or selectively skip turns.

#### 2.2 Compute design diff (only when target is design)

- List `iLink-doc/<story>/.snapshots/design.master.*.md`
- Pick the latest by filename sort (descending)
- Run `diff -u <latest_snapshot> iLink-doc/<story>/<story>-design.master.md` to produce unified diff
- If no snapshot exists, record `"无法判定直接编辑（缺少 design 快照）"`

If target is PM or QA review, record `"本段无直接编辑（PM/review 文档不做编辑检测）"`.

#### 2.3 Invoke Coach subagent

Spawn a sub-conversation (use Qoder's subagent / fresh-context mechanism) with the following bundle. **SHALL NOT** include master doc, requirement.md, or source code.

Prompt template:
```
你是 iLink Coach 子流程。请严格按照下方 coach.soul.md 的执行步骤（§6）和输出格式（§7）评估对话与 diff，输出单轮反馈 Markdown 段落。

【时间戳】<TZ=Asia/Shanghai date +%Y-%m-%dT%H:%M:%S+08:00>

【coach.soul.md】
<full content>

【对话摘录】
<2.1 content>

【design diff】
<2.2 content>

请直接返回 §7.2 骨架对应的 Markdown 段落（不要包含其他解释）。
```

#### 2.4 Append to feedback.md

- Path: `iLink-doc/<story>/<story>-feedback.md`
- Create the file if missing. **SHALL NOT** add `ILINK-PROTOCOL-METADATA` stamp.
- **Append** the subagent's response (preceded by a blank line). **SHALL NOT** overwrite history.

#### 2.5 Error handling

If subagent call fails or returns empty, append this error block to feedback.md and continue:
```
## <timestamp> approve 复盘

> **Coach 子流程异常**：<原因>。本轮跳过协作复盘，Status 推进不受影响。
```

### Step 3: Advance Status

Only when target is `design` or `pm`:

Use Edit/Write to replace `Status: STAGING` with the target status (`PENDING_CODER` or `PENDING_DESIGNER`) in the STAGING document's `# ILINK-PROTOCOL-METADATA` block.

When target is `review` (QA STAGING — upstream root-cause), **skip Status advance**. Tell the user to discuss upstream root cause, then re-run.

### Step 4: Report

Output to the user:

1. ✅ Coach feedback appended to `iLink-doc/<story>/<story>-feedback.md`
2. Status advance result (or "not advanced" with reason)
3. Next command:
   - design → `/ilink-coder <story>`
   - pm → `/ilink-design <story>`
   - review → discuss upstream blockers, then modify design or requirement and re-run

> Coach feedback is **NOT** consumed by downstream AI (Coder/QA). It serves human collaboration retrospection only. Commit `<story>-feedback.md` to git for team trend review.
