#!/bin/bash

# update-index.sh - index.mdファイルの自動生成・更新
#
# 使用方法:
#   INDEX_DIR=/path/to/.claude ./update-index.sh
#   または
#   ./update-index.sh (デフォルトで.claudeディレクトリを処理)

set -e

# デフォルトディレクトリ
INDEX_DIR=${INDEX_DIR:-".claude"}

# インデックスを生成する対象ディレクトリ
AGENT_DIRS=("builder" "planner")

# ログ出力関数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ファイルサイズをヒューマンリーダブルに変換
human_readable_size() {
    local size=$1
    if [ "$size" -lt 1024 ]; then
        echo "${size}B"
    elif [ "$size" -lt 1048576 ]; then
        echo "$((size / 1024))KB"
    else
        echo "$((size / 1048576))MB"
    fi
}

# インデックスを生成
generate_index() {
    local dir="$1"
    local agent_name=$(basename "$dir")
    local index_file="$dir/index.md"

    # ディレクトリが存在しない場合は作成
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        mkdir -p "$dir/archive"
    fi

    # インデックスファイルを生成
    {
        echo "# ${agent_name^} Index"
        echo ""
        echo "*自動生成: $(date '+%Y-%m-%d %H:%M:%S')*"
        echo ""

        # 統計情報
        echo "## 統計情報"

        # ファイル数をカウント
        local current_files=$(ls -1 "$dir"/*.md 2>/dev/null | grep -v index.md | wc -l)
        local archive_files=$(ls -1 "$dir/archive"/*.md 2>/dev/null | wc -l)
        local total_files=$((current_files + archive_files))

        echo "- 総ファイル数: $total_files"
        echo "  - 現在: $current_files"
        echo "  - アーカイブ: $archive_files"

        # 最終更新日時
        if [ -f "$dir/notes.md" ]; then
            local last_modified=$(stat -c '%Y' "$dir/notes.md" 2>/dev/null || stat -f '%m' "$dir/notes.md" 2>/dev/null || echo "0")
            if [ "$last_modified" != "0" ]; then
                echo "- 最終更新: $(date -d "@$last_modified" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$last_modified" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "不明")"
            fi
        fi

        # notes.mdの行数
        if [ -f "$dir/notes.md" ]; then
            echo "- notes.md行数: $(wc -l < "$dir/notes.md")"
        fi

        echo ""

        # 現在のファイル
        echo "## 現在のファイル"
        echo ""

        if [ -f "$dir/notes.md" ]; then
            local size=$(stat -c '%s' "$dir/notes.md" 2>/dev/null || stat -f '%z' "$dir/notes.md" 2>/dev/null || echo "0")
            local lines=$(wc -l < "$dir/notes.md")
            echo "### 📝 notes.md"
            echo "- サイズ: $(human_readable_size $size)"
            echo "- 行数: $lines"

            # 最初の数行を抽出（プレビュー）
            local preview=$(head -5 "$dir/notes.md" | sed 's/^/  /')
            if [ -n "$preview" ]; then
                echo "- プレビュー:"
                echo "\`\`\`markdown"
                echo "$preview"
                echo "\`\`\`"
            fi
            echo ""
        fi

        if [ -f "$dir/notes-summary.md" ]; then
            local size=$(stat -c '%s' "$dir/notes-summary.md" 2>/dev/null || stat -f '%z' "$dir/notes-summary.md" 2>/dev/null || echo "0")
            echo "### 📊 notes-summary.md"
            echo "- サイズ: $(human_readable_size $size)"
            echo "- 説明: ローテーション時の要約"
            echo ""
        fi

        # その他のファイル
        for file in "$dir"/*.md; do
            if [ -f "$file" ]; then
                local filename=$(basename "$file")
                if [ "$filename" != "notes.md" ] && [ "$filename" != "notes-summary.md" ] && [ "$filename" != "index.md" ]; then
                    echo "### 📄 $filename"
                    local size=$(stat -c '%s' "$file" 2>/dev/null || stat -f '%z' "$file" 2>/dev/null || echo "0")
                    echo "- サイズ: $(human_readable_size $size)"
                    echo ""
                fi
            fi
        done

        # アーカイブファイル
        echo "## アーカイブ"
        echo ""

        if [ -d "$dir/archive" ]; then
            local archive_count=$(ls -1 "$dir/archive"/*.md 2>/dev/null | wc -l)
            if [ "$archive_count" -gt 0 ]; then
                echo "### 📦 アーカイブ済みファイル ($archive_count 件)"
                echo ""

                # 最新5件のアーカイブを表示
                ls -1t "$dir/archive"/*.md 2>/dev/null | head -5 | while read archive_file; do
                    if [ -f "$archive_file" ]; then
                        local filename=$(basename "$archive_file")
                        local size=$(stat -c '%s' "$archive_file" 2>/dev/null || stat -f '%z' "$archive_file" 2>/dev/null || echo "0")
                        echo "- \`$filename\` ($(human_readable_size $size))"
                    fi
                done

                if [ "$archive_count" -gt 5 ]; then
                    echo "- ... 他 $((archive_count - 5)) 件"
                fi
            else
                echo "*アーカイブファイルはまだありません*"
            fi
        fi

        echo ""
        echo "## 使用方法"
        echo ""
        echo "### ファイルローテーション"
        echo "\`\`\`bash"
        echo "# notes.mdが500行を超えたら自動的にアーカイブ"
        echo "bash .claude/scripts/rotate-notes.sh"
        echo "\`\`\`"
        echo ""
        echo "### インデックス更新"
        echo "\`\`\`bash"
        echo "# このファイルを最新状態に更新"
        echo "bash .claude/scripts/update-index.sh"
        echo "\`\`\`"
        echo ""
        echo "---"
        echo "*このファイルは自動生成されています。手動で編集しないでください。*"
    } > "$index_file"

    log_info "Generated index for $agent_name: $index_file"
}

# メイン処理
main() {
    log_info "Starting index generation..."

    for agent in "${AGENT_DIRS[@]}"; do
        local agent_dir="$INDEX_DIR/$agent"
        if [ -d "$agent_dir" ] || [ "$INDEX_DIR" = "." ]; then
            generate_index "$agent_dir"
        else
            log_info "Directory $agent_dir not found, creating..."
            mkdir -p "$agent_dir/archive"
            generate_index "$agent_dir"
        fi
    done

    log_info "Index generation completed"
}

# スクリプトが直接実行された場合のみmainを実行
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
