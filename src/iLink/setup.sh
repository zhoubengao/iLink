#!/usr/bin/env bash
set -euo pipefail

# iLink - 环境初始化脚本
# 设置权限、检查依赖、更新 AGENTS.md
# Usage: bash iLink/setup.sh
#
# 前置条件: 已复制 .claude/, .qoder/, .codex/, iLink/, iLink-doc/ 到项目

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "iLink — 环境初始化"
echo "========================"
echo ""

# 1. Fix executable permissions
echo "[1/5] 设置脚本执行权限..."
for dir in ".claude/commands" ".qoder/commands" ".codex/commands"; do
  if [[ -d "$PROJECT_ROOT/$dir" ]]; then
    chmod +x "$PROJECT_ROOT/$dir"/*  2>/dev/null || true
    echo "  ✓ $dir/*"
  fi
done

# 2. Fix line endings (convert CRLF to LF if needed)
echo "[2/5] 检查行尾符..."
crlf_fixed=0
sed_inplace() {
  local expr="$1"
  local file="$2"
  if sed -i '' -e "$expr" "$file" 2>/dev/null; then
    return 0
  fi
  sed -i -e "$expr" "$file"
}
for dir in ".claude/commands" ".qoder/commands" ".codex/commands"; do
  if [[ -d "$PROJECT_ROOT/$dir" ]]; then
    for f in "$PROJECT_ROOT/$dir"/*; do
      if [[ -f "$f" ]] && grep -q $'\r' "$f" 2>/dev/null; then
        sed_inplace 's/\r$//' "$f"
        echo "  ✓ 修复 CRLF: $f"
        crlf_fixed=$((crlf_fixed + 1))
      fi
    done
  fi
done
if [[ $crlf_fixed -eq 0 ]]; then
  echo "  ✓ 无 CRLF 问题"
fi

# 3. Check dependencies
echo "[3/5] 检查依赖..."
missing=0
for cmd in bash awk sed grep tr cut sort basename; do
  if command -v "$cmd" &>/dev/null; then
    echo "  ✓ $cmd"
  else
    echo "  ✗ $cmd 未找到"
    missing=$((missing + 1))
  fi
done
if command -v shasum &>/dev/null; then
  echo "  ✓ shasum"
else
  echo "  ✗ shasum 未找到"
  missing=$((missing + 1))
fi

# 4. Verify Soul files
echo "[4/5] 检查 Soul 文件..."
souls_dir="$PROJECT_ROOT/iLink/souls"
all_ok=true
for soul in universal.soul.md pm.soul.md design.soul.md coder.soul.md qa.soul.md; do
  if [[ -f "$souls_dir/$soul" ]]; then
    echo "  ✓ $soul"
  else
    echo "  ✗ $soul 缺失"
    all_ok=false
  fi
done

if [[ -f "$PROJECT_ROOT/iLink/project-context.md" ]]; then
  echo "  ✓ project-context.md"
else
  echo "  ⚠ project-context.md 缺失（可选，但建议创建）"
fi

# 4.5 Warn sample stories
if [[ -d "$PROJECT_ROOT/iLink-doc/jzjy-0000" || -d "$PROJECT_ROOT/iLink-doc/kcia-0000" ]]; then
  echo "  ⚠ 检测到示例 Story（jzjy-0000 / kcia-0000），建议新项目中删除"
fi

# 5. Update root AGENTS.md for Codex CLI (optional)
if [[ -d "$PROJECT_ROOT/.codex" ]]; then
  echo "[5/5] 检测到 Codex 配置，更新根目录 AGENTS.md..."
  agents_file="$PROJECT_ROOT/AGENTS.md"

  if [[ -f "$agents_file" ]] && grep -q "iLink" "$agents_file" 2>/dev/null; then
    echo "  ✓ AGENTS.md 已包含 iLink 引导，跳过"
  else
    {
      echo ""
      echo "---"
      echo ""
      echo "## iLink"
      echo ""
      echo "本项目使用 iLink 流水线开发（v1.1.00）。"
      echo ""
      echo "当用户输入 \`ilink-pm\`、\`ilink-design\`、\`ilink-coder\`、\`ilink-qa\` 加 Story ID 时，"
      echo "请先读取 \`.codex/codex-commands.md\` 并按其中的指令执行对应角色任务。"
      echo ""
      echo "Shell 工具（终端执行）："
      echo "- \`bash .codex/commands/ilink-init <story>\` — 创建 Story"
      echo "- \`bash .codex/commands/ilink-status [story]\` — 查看状态"
      echo "- \`bash .codex/commands/ilink-approve <story>\` — 审核推进"
    } >> "$agents_file"
    echo "  ✓ iLink 引导已追加到 AGENTS.md"
  fi
else
  echo "[5/5] 跳过 AGENTS.md 更新（未检测到 Codex 配置）"
fi

echo ""
if [[ $missing -eq 0 && "$all_ok" == true ]]; then
  echo "✅ 环境就绪！"
else
  echo "⚠ 存在问题，请检查上方输出"
fi
echo ""
echo "使用方式："
echo ""
echo "【Claude CLI 用户】（复制 .claude + iLink + iLink-doc 目录）"
echo "  所有操作均在 Claude CLI 对话中执行 slash command："
echo "  /ilink-init <story-id>    → /ilink-pm → /ilink-design → /ilink-approve → /ilink-coder → /ilink-qa"
echo ""
echo "【Qoder CLI 用户】（复制 .qoder + iLink + iLink-doc 目录）"
echo "  Shell:  ./.qoder/commands/ilink-init <story-id>"
echo "  对话:   /ilink-pm <story-id> → /ilink-design → ... → /ilink-qa"
echo "  Shell:  ./.qoder/commands/ilink-approve <story-id>"
echo ""
if [[ -d "$PROJECT_ROOT/.codex" ]]; then
  echo "【Codex CLI 用户】（复制 .codex + iLink + iLink-doc 目录）"
  echo "  Shell:  bash .codex/commands/ilink-init <story-id>"
  echo "  对话:   ilink-pm <story-id> → ilink-design → ... → ilink-qa"
  echo "  Shell:  bash .codex/commands/ilink-approve <story-id>"
  echo "  状态:   bash .codex/commands/ilink-status [story-id]"
fi
echo ""
