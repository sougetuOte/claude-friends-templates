#!/bin/bash

# Claude Code Auto-Format Hook
# ファイル編集後の自動フォーマット実行

# 編集されたファイルパスを取得
file_paths="${CLAUDE_FILE_PATHS:-}"

if [ -z "$file_paths" ]; then
    exit 0
fi

# ログファイルの設定
LOG_FILE="${HOME}/.claude/format.log"
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# ログ記録関数
log_format() {
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# ファイルごとに適切なフォーマッターを実行
IFS=',' read -ra FILES <<< "$file_paths"
for file in "${FILES[@]}"; do
    # ファイルが存在しない場合はスキップ
    if [ ! -f "$file" ]; then
        continue
    fi

    case "$file" in
        *.py)
            if command -v ruff >/dev/null 2>&1; then
                ruff format "$file" 2>/dev/null && log_format "Formatted Python: $file"
            elif command -v black >/dev/null 2>&1; then
                black "$file" 2>/dev/null && log_format "Formatted Python (black): $file"
            fi
            ;;
        *.js|*.jsx|*.ts|*.tsx)
            if command -v prettier >/dev/null 2>&1; then
                prettier --write "$file" 2>/dev/null && log_format "Formatted JS/TS: $file"
            elif command -v npx >/dev/null 2>&1; then
                npx prettier --write "$file" 2>/dev/null && log_format "Formatted JS/TS (npx): $file"
            fi
            ;;
        *.rs)
            if command -v rustfmt >/dev/null 2>&1; then
                rustfmt "$file" 2>/dev/null && log_format "Formatted Rust: $file"
            fi
            ;;
        *.go)
            if command -v gofmt >/dev/null 2>&1; then
                gofmt -w "$file" 2>/dev/null && log_format "Formatted Go: $file"
            fi
            ;;
        *.json)
            if command -v jq >/dev/null 2>&1; then
                temp_file=$(mktemp)
                jq '.' "$file" > "$temp_file" 2>/dev/null && mv "$temp_file" "$file" && log_format "Formatted JSON: $file"
            fi
            ;;
        *)
            # その他のファイル形式は何もしない
            ;;
    esac
done

exit 0
