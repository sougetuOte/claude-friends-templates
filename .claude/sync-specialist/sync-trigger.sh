#!/bin/bash

# Sync Specialist - Trigger Script for UserPromptSubmit Hook
# Purpose: UserPromptSubmitフックから呼び出され、エージェント切り替えを検知
# Version: 1.0.0
# Pattern-2-1 Enhanced Hybrid Implementation

# ============================
# Configuration
# ============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"
LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/sync-trigger.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# ============================
# Logging Functions
# ============================
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $1" >> "$LOG_FILE"
    fi
}

# ============================
# Configuration Check
# ============================
check_enabled() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Config file not found: $CONFIG_FILE"
        exit 0  # Exit gracefully to not block user
    fi

    # Check if sync specialist is enabled
    local enabled=$(jq -r '.sync_specialist.enabled' "$CONFIG_FILE" 2>/dev/null)
    if [ "$enabled" != "true" ]; then
        log_debug "Sync specialist is disabled"
        exit 0
    fi
}

# ============================
# Hook Input Processing
# ============================
process_hook_input() {
    # Read JSON input from stdin
    local input=""
    if [ -t 0 ]; then
        log_debug "No stdin input detected"
    else
        input=$(cat)
    fi

    # Extract prompt from JSON input
    local prompt=""
    if [ -n "$input" ]; then
        prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null)
        log_debug "Received prompt: $prompt"
    fi

    # Check environment variable as fallback
    if [ -z "$prompt" ] && [ -n "$CLAUDE_PROMPT" ]; then
        prompt="$CLAUDE_PROMPT"
        log_debug "Using CLAUDE_PROMPT: $prompt"
    fi

    echo "$prompt"
}

# ============================
# Agent Switch Detection
# ============================
is_agent_switch_command() {
    local prompt=$1

    # Check if prompt contains agent switch command
    if echo "$prompt" | grep -qE "^/agent:(planner|builder)"; then
        return 0
    else
        return 1
    fi
}

# ============================
# Async Sync Trigger
# ============================
trigger_sync_async() {
    log_info "Triggering sync monitor asynchronously"

    # Run sync-monitor in background with proper detachment
    (
        # Detach from parent process
        exec </dev/null
        exec >/dev/null 2>&1

        # Small delay to ensure agent switch completes
        sleep 2

        # Run sync monitor
        "$SCRIPT_DIR/sync-monitor.sh"
    ) &

    # Detach the background process
    disown

    log_info "Sync monitor triggered in background"
}

# ============================
# Main Logic
# ============================
main() {
    log_info "Sync trigger started"

    # Check if enabled
    check_enabled

    # Process hook input
    local prompt=$(process_hook_input)

    if [ -z "$prompt" ]; then
        log_debug "No prompt detected"
        exit 0
    fi

    # Check if this is an agent switch command
    if is_agent_switch_command "$prompt"; then
        log_info "Agent switch command detected: $prompt"

        # Trigger sync asynchronously
        trigger_sync_async

        # Output for hook (non-blocking)
        echo "Sync Specialist: エージェント切り替えを検知しました。バックグラウンドでhandover生成を開始します。"
    else
        log_debug "Not an agent switch command: $prompt"
    fi

    log_info "Sync trigger completed"

    # Always exit 0 to not block the user
    exit 0
}

# Execute
main "$@"
