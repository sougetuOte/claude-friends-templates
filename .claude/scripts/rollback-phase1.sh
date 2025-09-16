#!/bin/bash
# Phase 1 Rollback Script
# 緊急時にPhase 1の変更を元に戻すためのスクリプト

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ロギング関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# プロジェクトルートの確認
if [ ! -d ".claude" ]; then
    log_error "This script must be run from the project root directory"
    exit 1
fi

# ロールバック確認
echo -e "${YELLOW}⚠️  WARNING: This will rollback all Phase 1 changes${NC}"
echo "This includes:"
echo "  - Settings.json hooks configuration"
echo "  - Hook script permissions"
echo "  - Activity logs"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Rollback cancelled"
    exit 0
fi

# 1. 現在のsettings.jsonをバックアップ
if [ -f ".claude/settings.json" ]; then
    backup_file=".claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    cp .claude/settings.json "$backup_file"
    log_info "Current settings backed up to: $backup_file"
fi

# 2. Phase 1前の設定に戻す（存在する場合）
if git rev-parse --is-inside-work-tree &>/dev/null; then
    # Git管理下の場合
    log_info "Attempting to restore settings.json from git history..."

    # Phase 1実装前のコミットを探す
    # "Phase 1" または "Hooks" を含まないコミットを探す
    last_safe_commit=$(git log --grep="Phase 1\|Hooks\|hooks" --invert-grep -n 1 --format="%H" .claude/settings.json 2>/dev/null || echo "")

    if [ -n "$last_safe_commit" ]; then
        git checkout "$last_safe_commit" -- .claude/settings.json
        log_info "Restored settings.json from commit: $last_safe_commit"
    else
        log_warn "Could not find pre-Phase 1 version in git history"
        # 最小限の設定にリセット
        cat > .claude/settings.json << 'EOF'
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  }
}
EOF
        log_info "Reset to minimal settings.json configuration"
    fi
else
    # Git管理外の場合：最小設定にリセット
    cat > .claude/settings.json << 'EOF'
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  }
}
EOF
    log_info "Reset to minimal settings.json configuration"
fi

# 3. 追加したフックスクリプトの実行権限を削除（無効化）
log_info "Disabling hook scripts..."
disabled_count=0
for script in .claude/hooks/**/*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        chmod -x "$script"
        disabled_count=$((disabled_count + 1))
    fi
done
log_info "Disabled $disabled_count hook scripts"

# 4. Phase 1で生成されたログファイルをクリア（オプション：アーカイブ）
if [ -d ".claude/logs" ]; then
    log_dir_backup=".claude/logs.backup.$(date +%Y%m%d_%H%M%S)"

    # ログのバックアップ（必要に応じて）
    if ls .claude/logs/*.log &>/dev/null; then
        mkdir -p "$log_dir_backup"
        mv .claude/logs/*.log "$log_dir_backup/"
        log_info "Logs backed up to: $log_dir_backup"
    fi

    # ログディレクトリをクリア
    rm -f .claude/logs/*.log
    log_info "Cleared log files"
fi

# 5. エージェント状態をリセット
if [ -f ".claude/agents/active.json" ]; then
    echo '{"agent": "none"}' > .claude/agents/active.json
    log_info "Reset agent state"
fi

# 6. 一時ファイルのクリーンアップ
rm -f .claude/agents/handover-*.md
rm -f .claude/planner/handover-*.md
rm -f .claude/builder/handover-*.md
log_info "Cleaned up temporary handover files"

# 7. ロールバック完了レポート
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Phase 1 Rollback Completed Successfully${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Summary:"
echo "  ✅ Settings.json restored/reset"
echo "  ✅ Hook scripts disabled"
echo "  ✅ Logs cleared"
echo "  ✅ Agent state reset"
echo "  ✅ Temporary files cleaned"
echo ""
echo "To re-enable Phase 1 features:"
echo "  1. Restore settings.json from backup"
echo "  2. Run: chmod +x .claude/hooks/**/*.sh"
echo "  3. Run: .claude/scripts/test-hooks.sh to verify"
echo ""
log_info "Rollback process completed"

# ロールバック成功を記録
echo "$(date): Phase 1 rollback executed" >> .claude/rollback.log