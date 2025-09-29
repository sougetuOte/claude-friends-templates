#!/bin/bash

# Claude Code Activity Logger Hook (Enhanced with Structured Logging)
# 開発活動の自動ログ記録 - 2025年版

# 構造化ログシステムの統合
source "$(dirname "${BASH_SOURCE[0]}")/../hooks/monitoring/structured-logger.sh" 2>/dev/null || {
    echo "Warning: Structured logger not available, using fallback logging" >&2
}

# 環境変数から情報を取得
tool_name="${CLAUDE_TOOL_NAME:-unknown}"
file_paths="${CLAUDE_FILE_PATHS:-}"
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# ログファイルの設定（構造化ログと並行維持）
LOG_FILE="${HOME}/.claude/activity.log"
METRICS_FILE="${HOME}/.claude/metrics.log"

# ディレクトリが存在しない場合は作成
mkdir -p "$(dirname "$LOG_FILE")"

# コンポーネント名を設定
export COMPONENT_NAME="activity-logger"

# 構造化ログでツール使用を記録
if command -v log_info >/dev/null 2>&1; then
    # ファイル情報をJSON形式で準備
    file_context=""
    if [ -n "$file_paths" ]; then
        file_info=$(echo "$file_paths" | tr ',' '\n' | while IFS= read -r file; do
            if [ -f "$file" ]; then
                file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
                file_ext="${file##*.}"
                echo "{\"path\":\"$file\",\"size\":$file_size,\"extension\":\"$file_ext\"}"
            fi
        done | jq -s '.' 2>/dev/null)

        if [ -n "$file_info" ] && [ "$file_info" != "[]" ]; then
            file_context="{\"files\":$file_info,\"file_count\":$(echo "$file_paths" | tr ',' '\n' | wc -l)}"
        fi
    fi

    # 構造化ログエントリ
    log_info "Tool usage: $tool_name" "tool=$tool_name" "$file_context"
fi

# 基本的な活動ログ（互換性維持）
echo "[$timestamp] Tool: $tool_name" >> "$LOG_FILE"

# ファイル操作の詳細ログ（互換性維持）
if [ -n "$file_paths" ]; then
    IFS=',' read -ra FILES <<< "$file_paths"
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            file_ext="${file##*.}"
            echo "[$timestamp] File: $file (${file_size}B, .$file_ext)" >> "$LOG_FILE"
        fi
    done
fi

# 構造化メトリクス収集
operation_type="unknown"
performance_category="unknown"

case "$tool_name" in
    "Edit"|"Write"|"MultiEdit")
        operation_type="CODE_EDIT"
        performance_category="code_modification"
        echo "[$timestamp] CODE_EDIT" >> "$METRICS_FILE"
        ;;
    "Read")
        operation_type="FILE_READ"
        performance_category="file_access"
        echo "[$timestamp] FILE_READ" >> "$METRICS_FILE"
        ;;
    "Bash")
        operation_type="COMMAND_EXEC"
        performance_category="system_command"
        echo "[$timestamp] COMMAND_EXEC" >> "$METRICS_FILE"
        ;;
    "Glob"|"Grep")
        operation_type="FILE_SEARCH"
        performance_category="file_search"
        echo "[$timestamp] FILE_SEARCH" >> "$METRICS_FILE"
        ;;
    *)
        operation_type="OTHER_TOOL"
        performance_category="other"
        echo "[$timestamp] OTHER_TOOL" >> "$METRICS_FILE"
        ;;
esac

# 構造化パフォーマンスログ
if command -v log_performance >/dev/null 2>&1; then
    duration="0.001"  # 基本的な操作として最小値を設定
    log_performance "$performance_category" "$duration" "success" "tool=$tool_name operation=$operation_type"
fi

exit 0
