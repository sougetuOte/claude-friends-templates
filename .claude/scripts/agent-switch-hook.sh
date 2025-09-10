#!/bin/bash

# =============================================================================
# Agent Switch Hook Script
# エージェント切り替え時の自動処理
# =============================================================================

set -euo pipefail

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNC_MONITOR="$SCRIPT_DIR/../sync-specialist/sync-monitor.sh"
ACTIVE_FILE="$PROJECT_ROOT/.claude/agents/active.md"
HANDOVER_DIR="$PROJECT_ROOT/memo"
PHASE_TODO="$PROJECT_ROOT/.claude/shared/phase-todo.md"
ADR_DIR="$PROJECT_ROOT/docs/adr"

# 環境変数から情報取得
PREVIOUS_AGENT="${CLAUDE_PREVIOUS_AGENT:-none}"
CURRENT_AGENT="${CLAUDE_CURRENT_AGENT:-none}"
SWITCH_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

# ログ関数
log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# 1. Sync Specialistによる自動handover作成
create_automatic_handover() {
    log_info "Creating automatic handover from $PREVIOUS_AGENT to $CURRENT_AGENT"
    
    if [[ -x "$SYNC_MONITOR" ]]; then
        # Sync Specialistを呼び出して自動的にhandoverを作成
        "$SYNC_MONITOR" create_handover_with_fallback
        
        if [[ $? -eq 0 ]]; then
            log_info "Handover created successfully"
        else
            log_error "Failed to create handover, using emergency fallback"
        fi
    else
        log_error "Sync monitor not found: $SYNC_MONITOR"
        # 緊急フォールバック
        create_minimal_handover
    fi
}

# 最小限のhandover作成（フォールバック）
create_minimal_handover() {
    cat > "$HANDOVER_DIR/handover.md" << EOF
# Emergency Handover

**Time**: $SWITCH_TIME
**From**: $PREVIOUS_AGENT
**To**: $CURRENT_AGENT

## Status
- Agent switch occurred without proper handover
- Please check previous agent's notes for context

## Next Steps
- Review current phase-todo.md
- Check for any incomplete tasks
- Continue with planned work

---
*Auto-generated emergency handover*
EOF
}

# 2. Phase-ToDo自動更新
update_phase_todo() {
    log_info "Updating phase-todo.md with current task status"
    
    if [[ ! -f "$PHASE_TODO" ]]; then
        log_error "Phase-todo.md not found, creating new one"
        create_initial_phase_todo
        return
    }
    
    # タスクステータスの自動更新ロジック
    # Builderからの引き継ぎの場合、完了タスクをマーク
    if [[ "$PREVIOUS_AGENT" == "builder" ]]; then
        # 最後に作業していたタスクを完了としてマーク
        # ここでは実装の簡略化のため、タイムスタンプを追加
        echo "" >> "$PHASE_TODO"
        echo "## Last Update: $SWITCH_TIME by $PREVIOUS_AGENT" >> "$PHASE_TODO"
    fi
    
    log_info "Phase-todo.md updated"
}

# 初期phase-todo作成
create_initial_phase_todo() {
    cat > "$PHASE_TODO" << EOF
# Phase & ToDo Management

## Current Phase: Initial
Started: $SWITCH_TIME

## ToDo List
- [ ] Review project requirements
- [ ] Set up development environment
- [ ] Create initial implementation plan

## Notes
- Auto-created by agent switch hook
- Please update with actual tasks

---
*Last updated: $SWITCH_TIME*
EOF
}

# 3. ADR自動記録（重要な技術的決定があった場合）
check_and_create_adr() {
    log_info "Checking for technical decisions requiring ADR"
    
    # Builder's notes.mdから技術的決定を検出
    BUILDER_NOTES="$PROJECT_ROOT/.claude/builder/notes.md"
    
    if [[ -f "$BUILDER_NOTES" ]]; then
        # "Decision:", "Decided:", "選択:" などのキーワードを検索
        if grep -qi "decision:\|decided:\|選択:\|決定:" "$BUILDER_NOTES"; then
            log_info "Technical decision detected, creating ADR draft"
            create_adr_draft
        fi
    fi
}

# ADRドラフト作成
create_adr_draft() {
    mkdir -p "$ADR_DIR"
    
    # 次のADR番号を決定
    NEXT_NUM=$(find "$ADR_DIR" -name "ADR-*.md" | wc -l | xargs -I {} expr {} + 1)
    NEXT_NUM=$(printf "%03d" $NEXT_NUM)
    ADR_FILE="$ADR_DIR/ADR-${NEXT_NUM}-draft.md"
    
    cat > "$ADR_FILE" << EOF
# ADR-${NEXT_NUM}: [Decision Title - DRAFT]

Date: $(date '+%Y-%m-%d')
Status: Draft
Agent: $PREVIOUS_AGENT

## Context and Background
[Auto-detected technical decision from $PREVIOUS_AGENT's work]
[Please review and complete this ADR]

## Decision
[Extract from agent notes]

## Consequences
- To be determined

## Implementation
- Review handover.md for details
- Check builder/notes.md for technical context

---
*Draft ADR auto-generated during agent switch*
EOF
    
    log_info "ADR draft created: $ADR_FILE"
}

# 4. エージェント切り替え記録
record_agent_switch() {
    local switch_log="$PROJECT_ROOT/.claude/agent-switches.log"
    
    echo "[$SWITCH_TIME] $PREVIOUS_AGENT -> $CURRENT_AGENT" >> "$switch_log"
    
    # 統計情報の更新
    update_agent_statistics
}

# エージェント使用統計
update_agent_statistics() {
    local stats_file="$PROJECT_ROOT/.claude/agent-stats.json"
    
    # 簡易的な統計更新（実際にはjqなどを使用）
    if [[ ! -f "$stats_file" ]]; then
        cat > "$stats_file" << EOF
{
  "planner": {"count": 0, "total_time": 0},
  "builder": {"count": 0, "total_time": 0},
  "last_switch": "$SWITCH_TIME"
}
EOF
    fi
}

# 5. 割り込み処理の検出
check_for_interrupt() {
    # 短時間での頻繁な切り替えを検出
    local switch_log="$PROJECT_ROOT/.claude/agent-switches.log"
    
    if [[ -f "$switch_log" ]]; then
        # 最後の5分間の切り替え回数をカウント
        recent_switches=$(tail -10 "$switch_log" | grep "$(date '+%Y-%m-%d %H:')" | wc -l)
        
        if [[ $recent_switches -gt 3 ]]; then
            log_info "Frequent agent switches detected - possible interrupt scenario"
            create_interrupt_handover
        fi
    fi
}

# 割り込みhandover作成
create_interrupt_handover() {
    local interrupt_file="$HANDOVER_DIR/handover-interrupt-$(date '+%Y%m%d-%H%M%S').md"
    
    cat > "$interrupt_file" << EOF
# Interrupt Handover

**Time**: $SWITCH_TIME
**Reason**: Frequent agent switches detected
**From**: $PREVIOUS_AGENT
**To**: $CURRENT_AGENT

## Interrupt Context
- Multiple agent switches in short time
- Possible urgent issue or clarification needed
- Review recent handovers for context

## Recovery Steps
1. Check last stable handover
2. Review recent changes
3. Identify interrupt cause
4. Resume normal workflow

---
*Auto-generated interrupt handover*
EOF
    
    log_info "Interrupt handover created: $interrupt_file"
}

# メイン処理
main() {
    log_info "=== Agent Switch Hook Started ==="
    log_info "Previous: $PREVIOUS_AGENT, Current: $CURRENT_AGENT"
    
    # エージェント切り替えが実際に発生した場合のみ処理
    if [[ "$PREVIOUS_AGENT" != "none" ]] && [[ "$PREVIOUS_AGENT" != "$CURRENT_AGENT" ]]; then
        # 1. 自動handover作成
        create_automatic_handover
        
        # 2. Phase-ToDo更新
        update_phase_todo
        
        # 3. ADRチェック
        check_and_create_adr
        
        # 4. 切り替え記録
        record_agent_switch
        
        # 5. 割り込みチェック
        check_for_interrupt
        
        log_info "=== Agent Switch Hook Completed ==="
    else
        log_info "No actual agent switch detected, skipping automation"
    fi
    
    exit 0
}

# エラーハンドリング
trap 'log_error "Agent switch hook failed at line $LINENO"' ERR

# 実行
main "$@"