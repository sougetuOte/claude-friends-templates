#!/bin/bash

# Claude Code AI-Friendly Activity Logger V2
# Vibe Logger仕様に準拠したAI最適化ログシステム

# 環境変数から情報を取得
tool_name="${CLAUDE_TOOL_NAME:-unknown}"
file_paths="${CLAUDE_FILE_PATHS:-}"
command="${CLAUDE_COMMAND:-}"
exit_code="${CLAUDE_EXIT_CODE:-0}"
output="${CLAUDE_OUTPUT:-}"
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
correlation_id=$(uuidgen 2>/dev/null || echo "$(date +%s)-$$")

# ログファイルの設定
AI_LOG_FILE="${HOME}/.claude/ai-activity.jsonl"
mkdir -p "$(dirname "$AI_LOG_FILE")"

# プロジェクト情報の取得
project_root="${CLAUDE_PROJECT_ROOT:-$(pwd)}"
project_name=$(basename "$project_root")
git_branch=$(cd "$project_root" && git branch --show-current 2>/dev/null || echo "none")
git_commit=$(cd "$project_root" && git rev-parse --short HEAD 2>/dev/null || echo "none")

# 操作タイプとログレベルの判定
operation="UNKNOWN"
level="INFO"
ai_hint=""
human_note=""
ai_todo=""

case "$tool_name" in
    "Edit"|"Write"|"MultiEdit")
        operation="modifyCode"
        level="INFO"
        ai_hint="Code modification detected. Analyze changes for syntax, logic, and best practices."
        human_note="AI-TODO: Check if modifications follow project conventions"
        ;;
    "Read"|"NotebookRead")
        operation="inspectFile"
        level="DEBUG"
        ai_hint="File inspection for understanding codebase structure."
        human_note="Context gathering operation"
        ;;
    "Bash")
        operation="executeCommand"
        if [ "$exit_code" != "0" ]; then
            level="ERROR"
            ai_todo="Analyze command failure and suggest fixes"
        fi
        ai_hint="System command execution. Check exit code and output."
        human_note="Command: $command"
        ;;
    "Glob"|"Grep"|"LS")
        operation="searchFiles"
        level="DEBUG"
        ai_hint="File search operation. Analyze search patterns and results."
        human_note="Search pattern: ${command:-pattern}"
        ;;
    "Task")
        operation="delegateToAgent"
        level="INFO"
        ai_hint="AI agent task delegation. Review task completion status."
        human_note="Autonomous agent operation"
        ;;
    "TodoWrite")
        operation="manageProject"
        level="INFO"
        ai_hint="Project management activity. Check task priorities and dependencies."
        human_note="Todo list modification"
        ;;
    "WebFetch"|"WebSearch")
        operation="fetchWebContent"
        level="INFO"
        ai_hint="Web content retrieval. Analyze fetched information relevance."
        human_note="External data gathering"
        ;;
    *)
        operation="unknownOperation"
        level="WARNING"
        ai_hint="Unrecognized operation type. Infer from context and output."
        ;;
esac

# メッセージの生成
message="$tool_name operation"
if [ -n "$command" ]; then
    message="$message: $command"
fi
if [ "$exit_code" != "0" ]; then
    message="$message (failed with exit code $exit_code)"
else
    message="$message completed successfully"
fi

# ファイル情報の収集（配列として）
files_context="{}"
if [ -n "$file_paths" ]; then
    # ファイル情報を収集してコンテキストに含める
    file_count=$(echo "$file_paths" | tr ',' '\n' | wc -l)
    first_file=$(echo "$file_paths" | cut -d',' -f1)
    files_context="{\"file_count\":$file_count,\"primary_file\":\"$first_file\"}"
fi

# ソース情報（呼び出し元）の推定
source_info="claude-code:unknown"
if [ -n "$CLAUDE_HOOK_TYPE" ]; then
    source_info="claude-code:hook:$CLAUDE_HOOK_TYPE"
fi

# 環境情報の収集
environment_info=$(jq -n \
    --arg os "$(uname -s)" \
    --arg arch "$(uname -m)" \
    --arg shell "$SHELL" \
    --arg lang "${LANG:-en_US.UTF-8}" \
    '{
        "language": "bash",
        "language_version": ($shell | split("/")[-1]),
        "os": $os,
        "platform": ($os + "-" + $arch),
        "locale": $lang
    }')

# コンテキスト情報の構築
context_info=$(jq -n \
    --arg project_name "$project_name" \
    --arg project_root "$project_root" \
    --arg git_branch "$git_branch" \
    --arg git_commit "$git_commit" \
    --arg user "$USER" \
    --arg pwd "$PWD" \
    --arg command "$command" \
    --argjson files "$files_context" \
    '{
        "project_name": $project_name,
        "project_root": $project_root,
        "git_branch": $git_branch,
        "git_commit": $git_commit,
        "user": $user,
        "working_directory": $pwd,
        "command": $command,
        "files": $files
    }')

# 単一行のJSONエントリを作成（Vibe Logger仕様準拠）
log_entry=$(jq -nc \
    --arg timestamp "$timestamp" \
    --arg level "$level" \
    --arg correlation_id "$correlation_id" \
    --arg operation "$operation" \
    --arg message "$message" \
    --argjson context "$context_info" \
    --argjson environment "$environment_info" \
    --arg source "$source_info" \
    --arg human_note "$human_note" \
    --arg ai_hint "$ai_hint" \
    --arg ai_todo "$ai_todo" \
    '{
        "timestamp": $timestamp,
        "level": $level,
        "correlation_id": $correlation_id,
        "operation": $operation,
        "message": $message,
        "context": $context,
        "environment": $environment,
        "source": $source,
        "human_note": (if $human_note != "" then $human_note else null end),
        "ai_hint": (if $ai_hint != "" then $ai_hint else null end),
        "ai_todo": (if $ai_todo != "" then $ai_todo else null end)
    } | with_entries(select(.value != null))')

# JSONLファイルに追記（単一行）
if [ -n "$log_entry" ]; then
    echo "$log_entry" >> "$AI_LOG_FILE"
fi

# エラー時の詳細情報（別エントリとして記録）
if [ "$exit_code" != "0" ] && [ -n "$output" ]; then
    # エラー出力を最初の1000文字に制限
    truncated_output=$(echo "$output" | head -c 1000)
    if [ ${#output} -gt 1000 ]; then
        truncated_output="${truncated_output}... (truncated)"
    fi

    error_entry=$(jq -nc \
        --arg timestamp "$timestamp" \
        --arg correlation_id "$correlation_id" \
        --arg operation "${operation}_error_details" \
        --arg message "Error output for $operation" \
        --arg output "$truncated_output" \
        --arg exit_code "$exit_code" \
        '{
            "timestamp": $timestamp,
            "level": "ERROR",
            "correlation_id": $correlation_id,
            "operation": $operation,
            "message": $message,
            "context": {
                "error_output": $output,
                "exit_code": ($exit_code | tonumber)
            },
            "environment": {},
            "ai_todo": "Analyze this error and suggest resolution"
        }')

    echo "$error_entry" >> "$AI_LOG_FILE"
fi

# 既存のシンプルログも継続（互換性のため）
echo "[$timestamp] Tool: $tool_name ($operation)" >> "${HOME}/.claude/activity.log"

# ログローテーション（10MBを超えたら）
log_size=$(stat -f%z "$AI_LOG_FILE" 2>/dev/null || stat -c%s "$AI_LOG_FILE" 2>/dev/null || echo 0)
if [ "$log_size" -gt 10485760 ]; then
    rotation_timestamp=$(date +"%Y%m%d_%H%M%S")
    mv "$AI_LOG_FILE" "${AI_LOG_FILE}.${rotation_timestamp}"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")] Log rotated at size $log_size" >> "$AI_LOG_FILE"
fi

exit 0
