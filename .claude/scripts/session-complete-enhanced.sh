#!/bin/bash

# =============================================================================
# Enhanced Session Complete Hook
# セッション完了時の詳細な状況記録とサマリー生成
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_DIR="${HOME}/.claude"
LOG_FILE="${CLAUDE_DIR}/session.log"
SUMMARY_FILE="${CLAUDE_DIR}/session-summary.md"
HANDOVER_FILE="${CLAUDE_DIR}/handover-next.md"
ACTIVITY_FILE="${CLAUDE_DIR}/activity.log"

# Session timing
SESSION_START="${CLAUDE_SESSION_START:-$(date '+%Y-%m-%d %H:%M:%S')}"
SESSION_END="$(date '+%Y-%m-%d %H:%M:%S')"

# Ensure directories exist
mkdir -p "$CLAUDE_DIR"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo "[INFO] $*" >&2
}

# Create session log
create_session_log() {
    cat > "$LOG_FILE" << EOF
=== Session Log ===
Generated: $SESSION_END

EOF

    # Git status section
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Git Status:" >> "$LOG_FILE"
        echo "  Current branch: $(git branch --show-current 2>/dev/null || echo 'detached')" >> "$LOG_FILE"

        local changed_files=$(git status --porcelain 2>/dev/null | wc -l)
        echo "  Changed files: $changed_files" >> "$LOG_FILE"

        if [[ $changed_files -gt 0 ]]; then
            echo "  Status: Working directory has changes" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"
            echo "Modified files:" >> "$LOG_FILE"
            git status --porcelain 2>/dev/null | head -10 | sed 's/^/  /' >> "$LOG_FILE"
        else
            echo "  Status: Working directory clean" >> "$LOG_FILE"
        fi
    else
        echo "Git Status: Not a git repository" >> "$LOG_FILE"
    fi

    echo "" >> "$LOG_FILE"
}

# Generate work summary
generate_work_summary() {
    cat > "$SUMMARY_FILE" << EOF
# Session Summary

## Work Summary

### Session Duration
- Start time: $SESSION_START
- End time: $SESSION_END

EOF

    # Files modified section
    if [[ -f "$ACTIVITY_FILE" ]]; then
        echo "### Files Modified" >> "$SUMMARY_FILE"

        # Extract file operations from activity log
        local file_ops=$(grep -E "Tool: (Edit|Write)" "$ACTIVITY_FILE" 2>/dev/null | tail -20 || echo "")
        if [[ -n "$file_ops" ]]; then
            echo "$file_ops" | sed 's/^/- /' >> "$SUMMARY_FILE"
        else
            echo "- No file modifications recorded" >> "$SUMMARY_FILE"
        fi
        echo "" >> "$SUMMARY_FILE"

        # Commands executed section
        echo "### Commands Executed" >> "$SUMMARY_FILE"
        local commands=$(grep "Tool: Bash" "$ACTIVITY_FILE" 2>/dev/null | tail -10 || echo "")
        if [[ -n "$commands" ]]; then
            echo "$commands" | sed 's/^/- /' >> "$SUMMARY_FILE"
        else
            echo "- No commands recorded" >> "$SUMMARY_FILE"
        fi
        echo "" >> "$SUMMARY_FILE"
    fi

    # Recent commits section (if in git repo)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "### Recent Commits" >> "$SUMMARY_FILE"

        # Get commits from today
        local today=$(date '+%Y-%m-%d')
        local recent_commits=$(git log --since="$today 00:00:00" --oneline 2>/dev/null || echo "")

        if [[ -n "$recent_commits" ]]; then
            echo "$recent_commits" | while IFS= read -r commit; do
                # Analyze commit patterns
                if [[ "$commit" =~ feat: ]]; then
                    echo "- $commit" >> "$SUMMARY_FILE"
                elif [[ "$commit" =~ fix: ]]; then
                    echo "- $commit" >> "$SUMMARY_FILE"
                else
                    echo "- $commit" >> "$SUMMARY_FILE"
                fi
            done
        else
            echo "- No commits today" >> "$SUMMARY_FILE"
        fi
        echo "" >> "$SUMMARY_FILE"
    fi

    # Task progress section
    local phase_todo="${CLAUDE_DIR}/shared/phase-todo.md"
    if [[ -f "$phase_todo" ]]; then
        echo "### Task Progress" >> "$SUMMARY_FILE"

        # Count task statuses
        local completed=$(grep -c "\[x\]" "$phase_todo" 2>/dev/null || echo "0")
        local in_progress=$(grep -c "🟡" "$phase_todo" 2>/dev/null || echo "0")
        local not_started=$(grep -c "🔴" "$phase_todo" 2>/dev/null || echo "0")

        echo "- Completed: $completed" >> "$SUMMARY_FILE"
        echo "- In Progress: $in_progress" >> "$SUMMARY_FILE"
        echo "- Not Started: $not_started" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi
}

# Create handover notes
create_handover_notes() {
    cat > "$HANDOVER_FILE" << EOF
# Handover Notes

## Next Session Handover

Generated: $SESSION_END

EOF

    # Uncommitted changes section
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "### Uncommitted Changes" >> "$HANDOVER_FILE"

        local changes=$(git status --porcelain 2>/dev/null || echo "")
        if [[ -n "$changes" ]]; then
            echo "The following files have uncommitted changes:" >> "$HANDOVER_FILE"
            echo "\`\`\`" >> "$HANDOVER_FILE"
            echo "$changes" >> "$HANDOVER_FILE"
            echo "\`\`\`" >> "$HANDOVER_FILE"
        else
            echo "No uncommitted changes" >> "$HANDOVER_FILE"
        fi
        echo "" >> "$HANDOVER_FILE"
    fi

    # Suggested next steps
    echo "### Suggested Next Steps" >> "$HANDOVER_FILE"

    # Check for incomplete tasks
    local phase_todo="${CLAUDE_DIR}/shared/phase-todo.md"
    if [[ -f "$phase_todo" ]]; then
        local incomplete_tasks=$(grep "- \[ \]" "$phase_todo" 2>/dev/null | head -5 || echo "")
        if [[ -n "$incomplete_tasks" ]]; then
            echo "Continue with these incomplete tasks:" >> "$HANDOVER_FILE"
            echo "$incomplete_tasks" >> "$HANDOVER_FILE"
        fi
    fi

    # Add recommendations based on git status
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local uncommitted=$(git status --porcelain 2>/dev/null | wc -l)
        if [[ $uncommitted -gt 0 ]]; then
            echo "" >> "$HANDOVER_FILE"
            echo "⚠️ **Important**: You have $uncommitted uncommitted changes. Consider:" >> "$HANDOVER_FILE"
            echo "1. Review and commit completed work" >> "$HANDOVER_FILE"
            echo "2. Stash or discard experimental changes" >> "$HANDOVER_FILE"
            echo "3. Push committed changes to remote" >> "$HANDOVER_FILE"
        fi
    fi

    echo "" >> "$HANDOVER_FILE"
}

# Display summary to user
display_summary() {
    echo "✅ Session completed: $SESSION_END"

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local changed_files=$(git status --porcelain 2>/dev/null | wc -l)
        if [[ $changed_files -gt 0 ]]; then
            echo "📝 $changed_files files modified"
        else
            echo "🔄 No changes in working directory"
        fi

        # Show recent commits
        local today=$(date '+%Y-%m-%d')
        local commit_count=$(git log --since="$today 00:00:00" --oneline 2>/dev/null | wc -l)
        if [[ $commit_count -gt 0 ]]; then
            echo "📌 $commit_count commits today"
        fi
    fi

    # Show task progress if available
    local phase_todo="${CLAUDE_DIR}/shared/phase-todo.md"
    if [[ -f "$phase_todo" ]]; then
        local completed=$(grep -c "\[x\]" "$phase_todo" 2>/dev/null || echo "0")
        local total=$(grep -c "- \[" "$phase_todo" 2>/dev/null || echo "0")
        if [[ $total -gt 0 ]]; then
            echo "✅ Tasks: $completed/$total completed"
        fi
    fi

    echo ""
    echo "📄 Session summary saved to: $SUMMARY_FILE"
    echo "📋 Handover notes saved to: $HANDOVER_FILE"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    log_info "Starting enhanced session complete hook"

    # Generate all outputs
    create_session_log
    generate_work_summary
    create_handover_notes

    # Display summary to user
    display_summary

    log_info "Session complete hook finished successfully"
    exit 0
}

# Error handling
trap 'log_info "Session complete hook error at line $LINENO"' ERR

# Run main
main "$@"
