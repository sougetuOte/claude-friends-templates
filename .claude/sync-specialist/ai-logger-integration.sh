#!/bin/bash

# AI Logger Integration for Sync Specialist
# Purpose: エージェント切り替えイベントをAI Loggerに記録する

# 引数
from_agent=$1
to_agent=$2
handover_file=$3

# AI Loggerファイル
AI_LOG_FILE="${HOME}/.claude/ai-activity.jsonl"
mkdir -p "$(dirname "$AI_LOG_FILE")"

# タイムスタンプとIDの生成
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
correlation_id=$(uuidgen 2>/dev/null || echo "$(date +%s)-$$")

# プロジェクト情報の取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
project_name=$(basename "$PROJECT_ROOT")
git_branch=$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo "none")
git_commit=$(cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "none")

# エージェント切り替えイベントの記録
agent_switch_entry=$(jq -nc \
    --arg timestamp "$timestamp" \
    --arg correlation_id "$correlation_id" \
    --arg from_agent "$from_agent" \
    --arg to_agent "$to_agent" \
    --arg handover_file "$handover_file" \
    --arg project_name "$project_name" \
    --arg project_root "$PROJECT_ROOT" \
    --arg git_branch "$git_branch" \
    --arg git_commit "$git_commit" \
    --arg user "$USER" \
    --arg pwd "$PWD" \
    '{
        "timestamp": $timestamp,
        "level": "INFO",
        "correlation_id": $correlation_id,
        "operation": "agentSwitch",
        "message": "Agent switch detected: \($from_agent) -> \($to_agent)",
        "context": {
            "project_name": $project_name,
            "project_root": $project_root,
            "git_branch": $git_branch,
            "git_commit": $git_commit,
            "user": $user,
            "working_directory": $pwd,
            "agent_transition": {
                "from": $from_agent,
                "to": $to_agent,
                "handover_file": $handover_file
            }
        },
        "environment": {
            "language": "bash",
            "os": "'"$(uname -s)"'",
            "platform": "'"$(uname -s)-$(uname -m)"'",
            "locale": "'"${LANG:-en_US.UTF-8}"'"
        },
        "source": "sync-specialist",
        "ai_hint": "Agent switch event. Check handover file for context and transition details.",
        "ai_metadata": {
            "hint": "Agent transition occurred. Review handover for continuity.",
            "debug_priority": "normal",
            "suggested_action": "Verify handover completeness"
        }
    }')

# JSONLファイルに追記
echo "$agent_switch_entry" >> "$AI_LOG_FILE"

# 成功を報告
echo "Agent switch event logged to AI Logger"
