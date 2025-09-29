#!/bin/bash

# rotate-notes.sh - notes.mdファイルのローテーション処理
#
# 使用方法:
#   NOTES_DIR=/path/to/notes/dir ./rotate-notes.sh
#   または
#   ./rotate-notes.sh (デフォルトで.claude/builderとplannerを処理)

set -e

# 設定ファイルを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/rotation-config.sh" ]; then
    source "$SCRIPT_DIR/rotation-config.sh"
fi

# 設定値（設定ファイルがない場合のデフォルト）
MAX_LINES=${ROTATION_MAX_LINES:-500}
ARCHIVE_DIR_NAME=${ARCHIVE_DIR_NAME:-"archive"}
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

# デフォルトのディレクトリ
if [ -z "$NOTES_DIR" ]; then
    DIRS=(".claude/builder" ".claude/planner")
else
    DIRS=("$NOTES_DIR")
fi

# ログ出力関数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# notes.mdテンプレートを生成
create_notes_template() {
    local dir="$1"
    local agent_name=$(basename "$dir")

    cat > "$dir/notes.md" << EOF
# ${agent_name^} Notes

## 現在の作業
- [ ]

## メモ


---
*ローテーション日時: $(date '+%Y-%m-%d %H:%M:%S')*
EOF
}

# 要約を生成（改善版）
generate_summary() {
    local source_file="$1"
    local summary_file="$2"

    if [ ! -f "$source_file" ]; then
        return 1
    fi

    # 要約ファイルのヘッダー
    {
        echo "# Notes Summary - $(date '+%Y-%m-%d')"
        echo ""
        echo "## 📊 統計情報"
        echo "- 元ファイル行数: $(wc -l < "$source_file")"
        echo "- アーカイブ日時: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""

        # ヘッダーの抽出
        local headers=$(grep "^##\|^###" "$source_file" 2>/dev/null | head -20)
        if [ -n "$headers" ]; then
            echo "## 📝 セクション構造"
            echo "$headers"
            echo ""
        fi

        # 決定事項の抽出
        local decisions=$(grep -E "決定:|重要:|変更:|追加:|削除:" "$source_file" 2>/dev/null | head -20)
        if [ -n "$decisions" ]; then
            echo "## 🎯 重要な決定事項"
            echo "$decisions"
            echo ""
        fi

        # タスクの集計
        local completed=$(grep "^\- \[x\]" "$source_file" 2>/dev/null | wc -l)
        local pending=$(grep "^\- \[ \]" "$source_file" 2>/dev/null | wc -l)
        echo "## ✅ タスク状況"
        echo "- 完了タスク: $completed 件"
        echo "- 未完了タスク: $pending 件"

        if [ "$pending" -gt 0 ]; then
            echo ""
            echo "### 未完了タスク（最大10件）"
            grep "^\- \[ \]" "$source_file" 2>/dev/null | head -10
        fi

        # 問題と解決の抽出
        local issues=$(grep -E "問題:|課題:|エラー:|バグ:" "$source_file" 2>/dev/null | head -10)
        if [ -n "$issues" ]; then
            echo ""
            echo "## ⚠️ 記録された問題"
            echo "$issues"
        fi

        echo ""
        echo "---"
        echo "*アーカイブ元: $(basename "$source_file")*"
        echo "*生成日時: $(date '+%Y-%m-%d %H:%M:%S')*"
    } > "$summary_file"
}

# ローテーション処理
rotate_notes() {
    local dir="$1"
    local notes_file="$dir/notes.md"
    local archive_dir="$dir/archive"
    local summary_file="$dir/notes-summary.md"

    # ディレクトリが存在しない場合はスキップ
    if [ ! -d "$dir" ]; then
        log_info "Directory $dir does not exist, skipping"
        return 0
    fi

    # notes.mdが存在しない場合は作成
    if [ ! -f "$notes_file" ]; then
        log_info "Creating new notes.md in $dir"
        create_notes_template "$dir"
        return 0
    fi

    # 行数をカウント
    local line_count=$(wc -l < "$notes_file")

    # 閾値チェック
    if [ "$line_count" -le "$MAX_LINES" ]; then
        log_info "File $notes_file has $line_count lines (threshold: $MAX_LINES), no rotation needed"
        return 0
    fi

    log_info "File $notes_file has $line_count lines, rotating..."

    # アーカイブディレクトリを作成
    mkdir -p "$archive_dir"

    # アーカイブファイル名を生成
    local archive_file="$archive_dir/notes-${TIMESTAMP}.md"

    # 現在のnotes.mdをアーカイブ
    cp "$notes_file" "$archive_file"
    log_info "Archived to $archive_file"

    # 要約を生成
    generate_summary "$archive_file" "$summary_file"
    log_info "Generated summary at $summary_file"

    # 新しいnotes.mdを作成
    create_notes_template "$dir"
    log_info "Created new notes.md in $dir"

    return 0
}

# メイン処理
main() {
    log_info "Starting notes rotation check..."

    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            log_info "Processing directory: $dir"
            rotate_notes "$dir"
        else
            log_info "Directory $dir not found, skipping"
        fi
    done

    log_info "Notes rotation check completed"
}

# スクリプトが直接実行された場合のみmainを実行
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
