#!/bin/bash

# Claude Code Session Completion Hook
# セッション完了時の状況記録とサマリー

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="${HOME}/.claude/session.log"
ACTIVITY_FILE="${HOME}/.claude/activity.log"

# ディレクトリが存在しない場合は作成
mkdir -p "$(dirname "$LOG_FILE")"

echo "=== Session Completed: $timestamp ===" >> "$LOG_FILE"

# Git状況の記録
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Git Status:" >> "$LOG_FILE"

    # 変更されたファイル数
    changed_files=$(git status --porcelain | wc -l)
    echo "  Changed files: $changed_files" >> "$LOG_FILE"

    # ブランチ情報
    current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
    echo "  Current branch: $current_branch" >> "$LOG_FILE"

    # 最新コミットの情報
    if [ "$changed_files" -gt 0 ]; then
        echo "  Status: Working directory has changes" >> "$LOG_FILE"
        git status --porcelain | head -5 >> "$LOG_FILE"
    else
        echo "  Status: Working directory clean" >> "$LOG_FILE"
    fi
else
    echo "Git Status: Not a git repository" >> "$LOG_FILE"
fi

# 今回のセッションでの活動サマリー
if [ -f "$ACTIVITY_FILE" ]; then
    echo "" >> "$LOG_FILE"
    echo "Session Activity Summary:" >> "$LOG_FILE"

    # 今日の活動を抽出（簡易版）
    today=$(date '+%Y-%m-%d')
    today_activities=$(grep "\\[$today" "$ACTIVITY_FILE" | tail -20)

    if [ -n "$today_activities" ]; then
        echo "  Recent activities (last 20):" >> "$LOG_FILE"
        echo "$today_activities" | sed 's/^/    /' >> "$LOG_FILE"

        # 簡単な統計
        tool_count=$(echo "$today_activities" | grep -o "Tool: [^]]*" | sort | uniq -c | sort -rn)
        echo "" >> "$LOG_FILE"
        echo "  Tool usage summary:" >> "$LOG_FILE"
        echo "$tool_count" | head -5 | sed 's/^/    /' >> "$LOG_FILE"
    else
        echo "  No activities recorded today" >> "$LOG_FILE"
    fi
fi

echo "" >> "$LOG_FILE"
echo "Session completed successfully" >> "$LOG_FILE"
echo "=================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# ユーザーに簡潔な完了メッセージを表示
echo "✅ Session completed: $timestamp"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    changed_files=$(git status --porcelain | wc -l)
    if [ "$changed_files" -gt 0 ]; then
        echo "📝 $changed_files files modified"
    else
        echo "🔄 No changes in working directory"
    fi
fi

exit 0
