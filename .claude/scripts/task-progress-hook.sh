#!/bin/bash

# =============================================================================
# Task Progress Hook Script
# タスク進展時の自動更新処理
# =============================================================================

set -euo pipefail

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PHASE_TODO="$PROJECT_ROOT/.claude/shared/phase-todo.md"
BUILDER_NOTES="$PROJECT_ROOT/.claude/builder/notes.md"
PLANNER_NOTES="$PROJECT_ROOT/.claude/planner/notes.md"
TASK_STATUS_LOG="$PROJECT_ROOT/.claude/task-status.log"

# 環境変数から情報取得
CURRENT_AGENT="${CLAUDE_CURRENT_AGENT:-unknown}"
TASK_ACTION="${CLAUDE_TASK_ACTION:-unknown}"
UPDATE_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

# タスクステータスマッピング
declare -A STATUS_EMOJI=(
    ["not_started"]="🔴"
    ["in_progress"]="🟡"
    ["testing"]="🟢"
    ["completed"]="✅"
    ["blocked"]="⚠️"
)

# ログ関数
log_info() {
    echo "[INFO] $*" >&2
}

log_debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo "[DEBUG] $*" >&2
}

# Phase-ToDoファイルの解析
parse_phase_todo() {
    if [[ ! -f "$PHASE_TODO" ]]; then
        log_info "Phase-todo.md not found"
        return 1
    fi
    
    # 現在のPhaseを取得
    local current_phase=$(grep -m1 "^## Current Phase:" "$PHASE_TODO" | cut -d: -f2- | xargs)
    echo "Current Phase: $current_phase"
}

# タスク状態の自動検出
detect_task_status() {
    local task_name="$1"
    local status="not_started"
    
    # Builderのnotes.mdから状態を推測
    if [[ -f "$BUILDER_NOTES" ]]; then
        if grep -q "現在のタスク.*$task_name.*🔴" "$BUILDER_NOTES"; then
            status="not_started"
        elif grep -q "現在のタスク.*$task_name.*🟡" "$BUILDER_NOTES"; then
            status="in_progress"
        elif grep -q "現在のタスク.*$task_name.*🟢" "$BUILDER_NOTES"; then
            status="testing"
        elif grep -q "現在のタスク.*$task_name.*✅" "$BUILDER_NOTES"; then
            status="completed"
        elif grep -q "現在のタスク.*$task_name.*⚠️" "$BUILDER_NOTES"; then
            status="blocked"
        fi
    fi
    
    echo "$status"
}

# Phase-ToDoの更新
update_phase_todo_status() {
    local task_pattern="$1"
    local new_status="$2"
    local emoji="${STATUS_EMOJI[$new_status]}"
    
    log_info "Updating task status: $task_pattern -> $emoji"
    
    # タスクステータスを更新
    if [[ -f "$PHASE_TODO" ]]; then
        # 既存の絵文字を新しいものに置換
        sed -i.bak "s/\(.*$task_pattern.*\)[🔴🟡🟢✅⚠️]/\1$emoji/" "$PHASE_TODO"
        
        # チェックボックスの更新
        if [[ "$new_status" == "completed" ]]; then
            sed -i "s/- \[ \] \(.*$task_pattern\)/- [x] \1/" "$PHASE_TODO"
        fi
        
        # 更新タイムスタンプを追加
        echo "" >> "$PHASE_TODO"
        echo "<!-- Last auto-update: $UPDATE_TIME by $CURRENT_AGENT -->" >> "$PHASE_TODO"
    fi
}

# テスト実行の検出と記録
detect_test_execution() {
    # Bashコマンドからテスト実行を検出
    local command="${CLAUDE_COMMAND:-}"
    
    if [[ "$command" =~ (test|spec|pytest|jest|mocha) ]]; then
        log_info "Test execution detected: $command"
        
        # テスト結果に基づいてタスク状態を更新
        local exit_code="${CLAUDE_EXIT_CODE:-1}"
        
        if [[ "$exit_code" -eq 0 ]]; then
            log_info "Tests passed - marking current task as testing phase"
            # 現在のタスクを取得して状態を更新
            update_current_task_status "testing"
        else
            log_info "Tests failed - task remains in progress"
        fi
    fi
}

# 現在のタスク状態を更新
update_current_task_status() {
    local new_status="$1"
    
    # Builder notes.mdから現在のタスクを取得
    if [[ -f "$BUILDER_NOTES" ]]; then
        local current_task=$(grep -m1 "現在のタスク:" "$BUILDER_NOTES" | cut -d: -f2- | sed 's/[🔴🟡🟢✅⚠️]//g' | xargs)
        
        if [[ -n "$current_task" ]]; then
            update_phase_todo_status "$current_task" "$new_status"
            record_task_progress "$current_task" "$new_status"
        fi
    fi
}

# タスク進捗の記録
record_task_progress() {
    local task_name="$1"
    local status="$2"
    
    # タスク状態ログに記録
    echo "[$UPDATE_TIME] $CURRENT_AGENT: $task_name -> $status" >> "$TASK_STATUS_LOG"
    
    # 統計情報の更新
    update_task_statistics "$status"
}

# タスク統計の更新
update_task_statistics() {
    local status="$1"
    local stats_file="$PROJECT_ROOT/.claude/task-stats.json"
    
    # 簡易的な統計（実際の実装ではjqを使用）
    if [[ ! -f "$stats_file" ]]; then
        cat > "$stats_file" << EOF
{
  "total_tasks": 0,
  "completed": 0,
  "in_progress": 0,
  "blocked": 0,
  "last_update": "$UPDATE_TIME"
}
EOF
    fi
}

# コミット時のタスク完了チェック
check_commit_completion() {
    local commit_message="${CLAUDE_COMMIT_MESSAGE:-}"
    
    # feat:, fix:, test: などのプレフィックスを検出
    if [[ "$commit_message" =~ ^(feat|fix|test|refactor): ]]; then
        log_info "Commit detected: $commit_message"
        
        # 関連タスクを完了としてマーク
        local task_from_commit=$(echo "$commit_message" | cut -d: -f2- | xargs)
        update_phase_todo_status "$task_from_commit" "completed"
    fi
}

# リファクタリング検出
detect_refactoring() {
    local file_path="${CLAUDE_FILE_PATHS:-}"
    
    if [[ "$TASK_ACTION" == "refactor" ]] || [[ "$file_path" =~ refactor ]]; then
        log_info "Refactoring detected"
        
        # リファクタリングタスクの自動作成
        add_refactoring_task "$file_path"
    fi
}

# リファクタリングタスクの追加
add_refactoring_task() {
    local file_path="$1"
    
    if [[ -f "$PHASE_TODO" ]]; then
        # リファクタリングセクションがなければ作成
        if ! grep -q "## Refactoring Tasks" "$PHASE_TODO"; then
            cat >> "$PHASE_TODO" << EOF

## Refactoring Tasks
<!-- Auto-generated refactoring tasks -->
EOF
        fi
        
        # タスクを追加
        echo "- [ ] Refactor: $file_path 🔴" >> "$PHASE_TODO"
        log_info "Added refactoring task for $file_path"
    fi
}

# ブロック状態の検出
detect_blocked_status() {
    # エラーログやBuilder notesからブロック状態を検出
    local error_pattern="error\|failed\|blocked\|waiting"
    
    if [[ -f "$BUILDER_NOTES" ]]; then
        if grep -qi "$error_pattern" "$BUILDER_NOTES"; then
            log_info "Blocked status detected"
            update_current_task_status "blocked"
            
            # ブロック理由を記録
            record_block_reason
        fi
    fi
}

# ブロック理由の記録
record_block_reason() {
    local block_log="$PROJECT_ROOT/.claude/blocked-tasks.md"
    
    cat >> "$block_log" << EOF

## Blocked Task: $UPDATE_TIME
- Agent: $CURRENT_AGENT
- Reason: [Auto-detected block]
- Check builder/notes.md for details

EOF
}

# Phase完了の検出
detect_phase_completion() {
    if [[ ! -f "$PHASE_TODO" ]]; then
        return
    fi
    
    # 未完了タスクをカウント
    local incomplete_tasks=$(grep -c "- \[ \]" "$PHASE_TODO" || true)
    
    if [[ "$incomplete_tasks" -eq 0 ]]; then
        log_info "All tasks in current phase completed!"
        
        # Phase完了を記録
        mark_phase_complete
    fi
}

# Phase完了マーク
mark_phase_complete() {
    local completion_file="$PROJECT_ROOT/.claude/phase-completions.log"
    local current_phase=$(parse_phase_todo | cut -d: -f2)
    
    echo "[$UPDATE_TIME] Phase completed: $current_phase" >> "$completion_file"
    
    # 次のPhaseへの準備を促す
    cat >> "$PHASE_TODO" << EOF

---
## Phase Complete! 🎉
All tasks in this phase have been completed.
Time to plan the next phase with Planner agent.

Completed at: $UPDATE_TIME
EOF
}

# メイン処理
main() {
    log_debug "=== Task Progress Hook Started ==="
    log_debug "Agent: $CURRENT_AGENT, Action: $TASK_ACTION"
    
    # 各種検出と更新処理
    detect_test_execution
    check_commit_completion
    detect_refactoring
    detect_blocked_status
    detect_phase_completion
    
    log_debug "=== Task Progress Hook Completed ==="
    
    exit 0
}

# エラーハンドリング
trap 'log_info "Task progress hook error at line $LINENO"' ERR

# 実行
main "$@"