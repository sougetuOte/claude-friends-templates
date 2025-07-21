#!/bin/bash

# Quality Pre-commit Hook
# コミット前に品質チェックを実行

echo "🔍 Running quality checks before commit..."

# 設定ファイルのパス
QUALITY_CONFIG=".claude/quality-config.json"
QUALITY_SCRIPT=".claude/scripts/quality-check.py"

# Pythonが利用可能かチェック
if ! command -v python3 &> /dev/null; then
    echo "⚠️  Python3 is not installed. Skipping quality checks."
    exit 0
fi

# 品質チェックスクリプトが存在するかチェック
if [ ! -f "$QUALITY_SCRIPT" ]; then
    echo "⚠️  Quality check script not found. Skipping."
    exit 0
fi

# ステージングされたファイルを取得
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "No files staged for commit."
    exit 0
fi

# クイックチェックを実行（複雑度とセキュリティのみ）
echo "Running quick quality check..."
python3 "$QUALITY_SCRIPT" --quick --format markdown

# 終了コードを確認
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Quality check failed!"
    echo "Please fix the issues before committing."
    echo ""
    echo "To bypass this check (not recommended):"
    echo "  git commit --no-verify"
    echo ""
    exit 1
fi

echo "✅ Quality check passed!"
exit 0