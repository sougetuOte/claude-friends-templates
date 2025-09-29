#!/bin/bash

# notes-maintenance.sh - notes.mdのメンテナンス処理（手動実行/cron/hook用）
#
# 使用方法:
#   ./notes-maintenance.sh             # 全機能を実行
#   ./notes-maintenance.sh rotate      # ローテーションのみ
#   ./notes-maintenance.sh index       # インデックス更新のみ
#   ./notes-maintenance.sh check       # チェックのみ（変更なし）

set -e

# スクリプトディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 設定ファイルを読み込み
if [ -f "$SCRIPT_DIR/rotation-config.sh" ]; then
    source "$SCRIPT_DIR/rotation-config.sh"
fi

# コマンドライン引数
COMMAND=${1:-"all"}

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# ヘッダー表示
show_header() {
    echo ""
    echo "========================================="
    echo "  Notes Maintenance System"
    echo "  Version 1.0.0"
    echo "========================================="
    echo ""
}

# 統計情報を表示
show_statistics() {
    log_info "現在の状態を確認中..."

    for agent in "builder" "planner"; do
        local notes_file=".claude/$agent/notes.md"
        if [ -f "$notes_file" ]; then
            local lines=$(wc -l < "$notes_file")
            local size=$(stat -c '%s' "$notes_file" 2>/dev/null || stat -f '%z' "$notes_file" 2>/dev/null || echo "0")
            local size_kb=$((size / 1024))

            echo -e "  ${GREEN}▸${NC} $agent/notes.md:"
            echo "    - 行数: $lines / $ROTATION_MAX_LINES ($(( lines * 100 / ROTATION_MAX_LINES ))%)"
            echo "    - サイズ: ${size_kb}KB"

            if [ "$lines" -gt "$ROTATION_MAX_LINES" ]; then
                log_warning "$agent/notes.md はローテーションが必要です"
            fi
        else
            echo -e "  ${YELLOW}▸${NC} $agent/notes.md: 未作成"
        fi

        # アーカイブ数
        local archive_count=$(ls -1 ".claude/$agent/archive"/*.md 2>/dev/null | wc -l)
        if [ "$archive_count" -gt 0 ]; then
            echo "    - アーカイブ: $archive_count 件"
        fi
    done
    echo ""
}

# チェックのみ実行
do_check() {
    show_header
    log_info "チェックモードで実行中..."
    show_statistics

    # 古いアーカイブのチェック
    if [ -n "$ROTATION_ARCHIVE_DAYS" ]; then
        log_info "${ROTATION_ARCHIVE_DAYS}日以上古いアーカイブをチェック中..."
        local old_count=0
        for agent in "builder" "planner"; do
            if [ -d ".claude/$agent/archive" ]; then
                old_count=$(find ".claude/$agent/archive" -name "*.md" -mtime +${ROTATION_ARCHIVE_DAYS} 2>/dev/null | wc -l)
                if [ "$old_count" -gt 0 ]; then
                    log_warning "$agent に $old_count 件の古いアーカイブがあります"
                fi
            fi
        done
    fi

    log_success "チェック完了"
}

# ローテーション実行
do_rotate() {
    log_info "ローテーション処理を開始..."

    if [ -f "$SCRIPT_DIR/rotate-notes.sh" ]; then
        bash "$SCRIPT_DIR/rotate-notes.sh"
        log_success "ローテーション完了"
    else
        log_error "rotate-notes.sh が見つかりません"
        return 1
    fi
}

# インデックス更新
do_index() {
    log_info "インデックス更新を開始..."

    if [ -f "$SCRIPT_DIR/update-index.sh" ]; then
        bash "$SCRIPT_DIR/update-index.sh"
        log_success "インデックス更新完了"
    else
        log_error "update-index.sh が見つかりません"
        return 1
    fi
}

# 古いアーカイブの削除（オプション）
cleanup_old_archives() {
    if [ -z "$ROTATION_ARCHIVE_DAYS" ]; then
        return 0
    fi

    log_info "${ROTATION_ARCHIVE_DAYS}日以上古いアーカイブを削除中..."

    local deleted_count=0
    for agent in "builder" "planner"; do
        if [ -d ".claude/$agent/archive" ]; then
            while IFS= read -r file; do
                if [ -f "$file" ]; then
                    log_info "削除: $file"
                    rm "$file"
                    ((deleted_count++))
                fi
            done < <(find ".claude/$agent/archive" -name "*.md" -mtime +${ROTATION_ARCHIVE_DAYS} 2>/dev/null)
        fi
    done

    if [ "$deleted_count" -gt 0 ]; then
        log_success "$deleted_count 件の古いアーカイブを削除しました"
    fi
}

# 全処理を実行
do_all() {
    show_header
    show_statistics

    # ローテーション
    do_rotate

    # インデックス更新
    do_index

    # 古いアーカイブのクリーンアップ（環境変数で有効化）
    if [ "${CLEANUP_OLD_ARCHIVES}" = "true" ]; then
        cleanup_old_archives
    fi

    echo ""
    log_success "すべてのメンテナンス処理が完了しました"
    echo ""

    # 完了後の状態を表示
    show_statistics
}

# メイン処理
main() {
    case "$COMMAND" in
        check)
            do_check
            ;;
        rotate)
            show_header
            do_rotate
            ;;
        index)
            show_header
            do_index
            ;;
        all|"")
            do_all
            ;;
        help|--help|-h)
            echo "使用方法: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  all     - 全機能を実行（デフォルト）"
            echo "  check   - 状態確認のみ"
            echo "  rotate  - ローテーションのみ"
            echo "  index   - インデックス更新のみ"
            echo "  help    - このヘルプを表示"
            echo ""
            echo "Environment Variables:"
            echo "  ROTATION_MAX_LINES       - ローテーション閾値（デフォルト: 500）"
            echo "  ROTATION_ARCHIVE_DAYS    - アーカイブ保持日数（デフォルト: 90）"
            echo "  CLEANUP_OLD_ARCHIVES     - 古いアーカイブを削除（true/false）"
            exit 0
            ;;
        *)
            log_error "不明なコマンド: $COMMAND"
            echo "使用方法: $0 [check|rotate|index|all|help]"
            exit 1
            ;;
    esac
}

# スクリプトが直接実行された場合のみmainを実行
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
