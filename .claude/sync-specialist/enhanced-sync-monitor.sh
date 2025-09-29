#!/bin/bash

# =============================================================================
# Enhanced Sync Specialist Monitor
# Handles automatic handover creation and state synchronization
# Version 2.2 - Enhanced Error Handling and Validation
# =============================================================================

set -euo pipefail

# Configuration
TIMEOUT_DURATION=${SYNC_TIMEOUT:-10}
LOCK_FILE="/tmp/sync-specialist-lock-$$"
ERROR_LOG=".claude/sync-specialist/error.log"
DEBUG_MODE=${SYNC_DEBUG:-false}

# Enhanced logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    [[ "$DEBUG_MODE" == "true" ]] && echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$ERROR_LOG"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$ERROR_LOG"
}

log_debug() {
    [[ "$DEBUG_MODE" == "true" ]] && echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    [[ "$DEBUG_MODE" == "true" ]] && echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$ERROR_LOG"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$ERROR_LOG"
}

# Enhanced error handling
handle_error() {
    local exit_code=$1
    local error_msg="$2"
    local context="${3:-unknown}"

    log_error "$error_msg (exit code: $exit_code, context: $context)"

    # Create emergency handover if main process fails
    create_emergency_handover "$error_msg" "$context"

    # Notify user if possible
    notify_user_of_error "$error_msg" "$context"

    # Clean up resources
    cleanup_on_error

    exit $exit_code
}

# Timeout handling
handle_timeout() {
    local operation="$1"
    local duration="$2"

    log_warn "Operation '$operation' timed out after ${duration}s"
    create_emergency_handover "Timeout during $operation" "timeout"

    return 124  # Timeout exit code
}

# User notification mechanism
notify_user_of_error() {
    local error_msg="$1"
    local context="$2"

    # Ensure memo directory exists
    mkdir -p memo

    # Create user-visible error notification
    cat > memo/sync-error.md << EOF
# Sync Specialist Error Notification

**Time**: $(date '+%Y-%m-%d %H:%M:%S')
**Context**: $context
**Error**: $error_msg

## What happened?
The Sync Specialist encountered an error during operation. An emergency handover has been created with available information.

## Next steps:
1. Review the emergency handover in \`memo/handover.md\`
2. Check the error log: \`.claude/sync-specialist/error.log\`
3. Consider restarting the sync process

## Recovery:
\`\`\`bash
.claude/sync-specialist/sync-monitor.sh create_handover
\`\`\`
EOF
}

# Cleanup on error
cleanup_on_error() {
    [[ -f "$LOCK_FILE" ]] && rm -f "$LOCK_FILE"
    log_debug "Cleaned up resources after error"
}

# File locking mechanism
acquire_lock() {
    local timeout=${1:-10}
    local count=0

    while [[ $count -lt $timeout ]]; do
        if (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
            log_debug "Lock acquired: $LOCK_FILE"
            return 0
        fi

        sleep 1
        count=$((count + 1))
        log_debug "Waiting for lock... ($count/$timeout)"
    done

    log_error "Failed to acquire lock after ${timeout}s"
    return 1
}

release_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
        log_debug "Lock released: $LOCK_FILE"
    fi
}

# Ensure memo directories exist
ensure_memo_dirs() {
    mkdir -p memo
    mkdir -p .claude/sync-specialist
}

create_emergency_handover() {
    local error_reason="${1:-Unknown error}"
    local context="${2:-unknown}"

    log_info "Creating emergency handover due to: $error_reason (context: $context)"

    # Acquire lock to prevent concurrent access
    if ! acquire_lock 5; then
        log_error "Could not acquire lock for emergency handover"
        return 1
    fi

    ensure_memo_dirs

    cat > memo/handover.md << EOF
# 🚨 EMERGENCY HANDOVER

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Reason**: $error_reason
**Context**: $context
**Agent**: Sync Specialist (Emergency Mode)
**Recovery Code**: SYNC-$(date +%s)

## ⚠️ Critical Status
- **Emergency handover created due to system error**
- **Limited information available - manual review required**
- **System may be in inconsistent state**

## 📋 Available Information
EOF

    # Try to extract any available information
    if [[ -f memo/active.md ]]; then
        echo "" >> memo/handover.md
        echo "### Current Active State" >> memo/handover.md
        echo "\`\`\`" >> memo/handover.md
        head -20 memo/active.md >> memo/handover.md 2>/dev/null || echo "Could not read active.md"
        echo "\`\`\`" >> memo/handover.md
    fi

    if [[ -f memo/phase-todo.md ]]; then
        echo "" >> memo/handover.md
        echo "### Phase TODO" >> memo/handover.md
        echo "\`\`\`" >> memo/handover.md
        head -20 memo/phase-todo.md >> memo/handover.md 2>/dev/null || echo "Could not read phase-todo.md"
        echo "\`\`\`" >> memo/handover.md
    fi

    cat >> memo/handover.md << EOF

## 🔧 Recovery Actions Required
1. **Immediate**: Review system logs and error details
2. **Investigate**: Determine root cause of failure
3. **Restore**: Recreate proper handover with current state
4. **Verify**: Ensure system consistency

## 📞 Support Information
- Error Log: \`.claude/sync-specialist/error.log\`
- Recovery Code: SYNC-$(date +%s)
- Emergency Contact: Check project documentation

---
*This emergency handover was generated automatically by the Sync Specialist*
EOF

    release_lock
    log_info "Emergency handover created successfully with recovery code SYNC-$(date +%s)"
}

# Enhanced create_handover with timeout and error handling
create_handover_with_fallback() {
    log_info "Creating handover with fallback protection"

    # Set up timeout
    (
        sleep $TIMEOUT_DURATION
        if [[ -f "$LOCK_FILE" ]]; then
            log_warn "Handover creation timed out after ${TIMEOUT_DURATION}s"
            kill -TERM "$$" 2>/dev/null || true
        fi
    ) &
    local timeout_pid=$!

    # Try to create normal handover
    if create_handover; then
        kill $timeout_pid 2>/dev/null || true
        wait $timeout_pid 2>/dev/null || true
        log_info "Handover created successfully"
        return 0
    else
        local exit_code=$?
        kill $timeout_pid 2>/dev/null || true
        wait $timeout_pid 2>/dev/null || true

        log_error "Normal handover creation failed (exit code: $exit_code)"
        create_emergency_handover "Normal handover creation failed" "fallback"
        return $exit_code
    fi
}

# Handover quality validation
validate_handover() {
    local handover_file="memo/handover.md"

    if [[ ! -f "$handover_file" ]]; then
        log_error "Handover file does not exist: $handover_file"
        return 1
    fi

    local validation_errors=0

    # Check for minimum required sections
    local required_sections=("Current Status" "Next Steps" "Tasks")
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$handover_file"; then
            log_warn "Missing required section: $section"
            validation_errors=$((validation_errors + 1))
        fi
    done

    # Check file size (should not be too small)
    local file_size=$(wc -c < "$handover_file")
    if [[ $file_size -lt 200 ]]; then
        log_warn "Handover file seems too small (${file_size} bytes)"
        validation_errors=$((validation_errors + 1))
    fi

    # Check for emergency handover markers
    if grep -q "EMERGENCY HANDOVER" "$handover_file"; then
        log_warn "Handover is an emergency handover - manual review required"
        validation_errors=$((validation_errors + 1))
    fi

    if [[ $validation_errors -eq 0 ]]; then
        log_info "Handover validation passed"
        return 0
    else
        log_error "Handover validation failed with $validation_errors errors"
        return 1
    fi
}

# Agent switch detection
detect_agent_switch() {
    local switch_file=".claude/last_agent_switch"

    if [[ ! -f "$switch_file" ]]; then
        log_debug "No agent switch file found"
        return 1
    fi

    local switch_timestamp
    switch_timestamp=$(grep "timestamp:" "$switch_file" 2>/dev/null | cut -d: -f2) || {
        log_warn "Could not read switch timestamp"
        return 1
    }

    local current_timestamp=$(date +%s)
    local time_diff=$((current_timestamp - switch_timestamp))

    # Consider switch recent if within last 30 seconds
    if [[ $time_diff -le 30 ]]; then
        log_info "Recent agent switch detected (${time_diff}s ago)"
        return 0
    else
        log_debug "No recent agent switch (last switch ${time_diff}s ago)"
        return 1
    fi
}

create_handover() {
    log_info "Creating handover document"

    # Acquire lock to prevent concurrent access
    if ! acquire_lock; then
        log_error "Could not acquire lock for handover creation"
        return 1
    fi

    ensure_memo_dirs

    # Extract current status from active.md with error handling
    local current_phase="unknown"
    local current_agent="unknown"
    local current_progress="unknown"

    if [[ -f memo/active.md ]]; then
        current_phase=$(grep -i "phase:" memo/active.md 2>/dev/null | head -1 | cut -d: -f2- | xargs) || {
            log_warn "Could not extract phase from active.md"
            current_phase="unknown"
        }
        current_agent=$(grep -i "agent:" memo/active.md 2>/dev/null | head -1 | cut -d: -f2- | xargs) || {
            log_warn "Could not extract agent from active.md"
            current_agent="unknown"
        }
        current_progress=$(grep -i "progress:" memo/active.md 2>/dev/null | head -1 | cut -d: -f2- | xargs) || {
            log_warn "Could not extract progress from active.md"
            current_progress="unknown"
        }
    else
        log_warn "active.md not found - using default values"
    fi

    # Create handover document
    cat > memo/handover.md << EOF
# 🎯 Project Handover

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**From**: $current_agent
**Phase**: $current_phase
**Progress**: $current_progress

## 📊 Current Status
- **Phase**: $current_phase
- **Agent**: $current_agent
- **Progress**: $current_progress
- **Last Update**: $(date '+%Y-%m-%d %H:%M:%S')

## 📋 Completed Tasks
EOF

    # Extract completed tasks from phase-todo.md
    if [[ -f memo/phase-todo.md ]]; then
        echo "" >> memo/handover.md
        grep "- \[x\]" memo/phase-todo.md >> memo/handover.md 2>/dev/null || echo "- No completed tasks found" >> memo/handover.md
    else
        echo "- No task information available" >> memo/handover.md
    fi

    # Add pending tasks
    cat >> memo/handover.md << EOF

## 🔄 Next Steps
EOF

    if [[ -f memo/phase-todo.md ]]; then
        echo "" >> memo/handover.md
        grep "- \[ \]" memo/phase-todo.md | head -5 >> memo/handover.md 2>/dev/null || echo "- No pending tasks found" >> memo/handover.md
    else
        echo "- Review project status and create task list" >> memo/handover.md
    fi

    # Add important notes
    cat >> memo/handover.md << EOF

## 💡 Important Notes
- Current phase requires attention to: $current_phase specific tasks
- Progress is at: $current_progress
- Next agent should review active.md for detailed status

## 📞 Context
- Memory Bank: Check \`memo/\` directory for detailed history
- Active State: See \`memo/active.md\` for current status
- Phase Tasks: Review \`memo/phase-todo.md\` for task details

---
*Generated by Sync Specialist - $(date '+%Y-%m-%d %H:%M:%S')*
EOF

    release_lock

    # Validate the created handover
    if validate_handover; then
        log_info "Handover created and validated successfully"
        return 0
    else
        log_warn "Handover created but validation failed"
        return 1
    fi
}

# Show help information
show_help() {
    cat << 'EOF'
Sync Specialist Monitor - Enhanced Version 2.2

Usage: sync-monitor.sh [command]

Commands:
  create_handover              Create standard handover document
  create_handover_with_fallback Create handover with timeout protection
  validate_handover            Validate existing handover quality
  detect_agent_switch          Check for recent agent switches
  cleanup                      Clean up temporary resources
  status                       Show sync specialist status
  help                         Show this help message

Environment Variables:
  SYNC_TIMEOUT    Timeout for operations (default: 10s)
  SYNC_DEBUG      Enable debug logging (default: false)

Examples:
  ./sync-monitor.sh create_handover
  SYNC_DEBUG=true ./sync-monitor.sh create_handover_with_fallback
  SYNC_TIMEOUT=30 ./sync-monitor.sh validate_handover
EOF
}

# Show status information
show_status() {
    echo "=== Sync Specialist Status ==="
    echo "Version: 2.2 (Enhanced Error Handling)"
    echo "Timeout: ${TIMEOUT_DURATION}s"
    echo "Debug Mode: $DEBUG_MODE"
    echo "Lock File: $LOCK_FILE"
    echo "Error Log: $ERROR_LOG"
    echo

    if [[ -f "$LOCK_FILE" ]]; then
        echo "Status: LOCKED (PID: $(cat "$LOCK_FILE" 2>/dev/null || echo "unknown"))"
    else
        echo "Status: Available"
    fi

    if [[ -f memo/handover.md ]]; then
        echo "Last Handover: $(stat -c %y memo/handover.md 2>/dev/null || echo "unknown")"
    else
        echo "Last Handover: None"
    fi

    if [[ -f "$ERROR_LOG" ]] && [[ -s "$ERROR_LOG" ]]; then
        echo
        echo "Recent Errors:"
        tail -3 "$ERROR_LOG"
    fi
}

# Main command dispatcher with enhanced error handling
main() {
    local command="${1:-help}"
    local exit_code=0

    # Ensure error log directory exists
    mkdir -p "$(dirname "$ERROR_LOG")"

    case "$command" in
        "create_handover")
            create_handover || exit_code=$?
            ;;
        "create_handover_with_fallback")
            create_handover_with_fallback || exit_code=$?
            ;;
        "validate_handover")
            validate_handover || exit_code=$?
            ;;
        "detect_agent_switch")
            detect_agent_switch || exit_code=$?
            ;;
        "cleanup")
            cleanup_on_error
            ;;
        "status")
            show_status || exit_code=$?
            ;;
        *)
            show_help
            ;;
    esac

    return $exit_code
}

# Trap signals for cleanup
trap cleanup_on_error EXIT
trap 'handle_timeout "sync-monitor" "$TIMEOUT_DURATION"' TERM

# Additional functions for TDD test compatibility

# Log rotation function
rotate_error_log_if_needed() {
    local max_size_mb=10
    local keep_files=5

    if [[ ! -f "$ERROR_LOG" ]]; then
        log_debug "Error log does not exist, no rotation needed"
        return 0
    fi

    local file_size_mb=$(( $(stat -c%s "$ERROR_LOG" 2>/dev/null || echo 0) / 1024 / 1024 ))

    if [[ $file_size_mb -gt $max_size_mb ]]; then
        log_info "Rotating error log (${file_size_mb}MB > ${max_size_mb}MB)"

        # Rotate existing logs
        for i in $(seq $((keep_files - 1)) -1 1); do
            if [[ -f "${ERROR_LOG}.$i" ]]; then
                mv "${ERROR_LOG}.$i" "${ERROR_LOG}.$((i + 1))"
            fi
        done

        # Move current log to .1
        mv "$ERROR_LOG" "${ERROR_LOG}.1"

        # Create new log file
        touch "$ERROR_LOG"
        log_info "Error log rotated successfully"
        return 0
    else
        log_debug "Error log size OK (${file_size_mb}MB < ${max_size_mb}MB)"
        return 0
    fi
}

# Fallback handover creation
create_fallback_handover() {
    local failure_reason="${1:-Unknown failure}"

    log_info "Creating fallback handover due to: $failure_reason"

    ensure_memo_dirs

    cat > memo/handover-fallback.md << EOF
# 🔄 FALLBACK HANDOVER

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Reason**: $failure_reason
**Mode**: Fallback Recovery
**Recovery Code**: FALLBACK-$(date +%s)

## ⚠️ Fallback Status
- **Primary handover creation failed**
- **Using simplified fallback procedure**
- **Limited information available**

## 📋 Basic Information
- **Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')
- **Working Directory**: $(pwd)
- **User**: $(whoami)

## 🔧 Recovery Instructions
1. **Immediate**: Review primary failure reason
2. **Investigate**: Check error logs for details
3. **Retry**: Attempt normal handover creation
4. **Manual**: Create proper handover manually if needed

## 📞 Support
- **Error Log**: $ERROR_LOG
- **Recovery Code**: FALLBACK-$(date +%s)
- **Contact**: Check project documentation

---
*This fallback handover was generated due to primary handover failure*
EOF

    log_info "Fallback handover created successfully"
    return 0
}

# Concurrent access protection
check_concurrent_access() {
    local lock_file="${1:-$LOCK_FILE}"

    if [[ -f "$lock_file" ]]; then
        local lock_pid
        lock_pid=$(cat "$lock_file" 2>/dev/null || echo "unknown")
        log_warn "Concurrent access detected: lock file exists (PID: $lock_pid)"
        return 1
    else
        log_debug "No concurrent access detected"
        return 0
    fi
}

# Recovery mechanism after error
attempt_recovery_after_error() {
    local error_context="${1:-unknown_context}"

    log_info "Attempting recovery after error in context: $error_context"

    # Try to clean up any stale resources
    cleanup_on_error

    # Try to create a basic handover if possible
    if create_fallback_handover "Recovery attempt from $error_context"; then
        log_info "Recovery handover created successfully"
    else
        log_error "Recovery handover creation also failed"
    fi

    # Log recovery attempt
    echo "[RECOVERY] $(date '+%Y-%m-%d %H:%M:%S') Attempted recovery from $error_context" >> "$ERROR_LOG"

    log_info "Recovery attempt completed for context: $error_context"
    return 0
}

# Dependency validation
validate_dependencies() {
    log_info "Validating system dependencies"

    local missing_deps=()
    local warnings=0

    # Check basic shell commands
    for cmd in "date" "cat" "grep" "head" "tail" "mkdir" "touch"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    # Check optional but recommended commands
    for cmd in "git" "jq"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_warn "Optional command not found: $cmd"
            warnings=$((warnings + 1))
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi

    if [[ $warnings -gt 0 ]]; then
        log_warn "Dependency validation completed with $warnings warnings"
    else
        log_info "All dependencies validated successfully"
    fi

    return 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
