#!/bin/bash

# Sync Specialist - Agent Switch Monitor
# Purpose: エージェント切り替えを検知し、handover生成を管理する
# Version: 1.0.0
# Pattern-2-1 Enhanced Hybrid Implementation

# ============================
# Configuration
# ============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ACTIVE_FILE="$PROJECT_ROOT/.claude/agents/active.md"
CONFIG_FILE="$SCRIPT_DIR/config.json"
LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/sync-monitor.log"
HANDOVER_DIR="$PROJECT_ROOT/.claude/shared/handover"

# Ensure log directory exists
mkdir -p "$LOG_DIR"
mkdir -p "$HANDOVER_DIR"

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
# Agent State Functions
# ============================
get_current_agent() {
    if [ ! -f "$ACTIVE_FILE" ]; then
        echo "none"
        return
    fi
    
    # Extract current agent from active.md
    grep -E "^## Current Agent:" "$ACTIVE_FILE" | sed 's/^## Current Agent: *//' | tr -d ' '
}

get_previous_agent() {
    # Check log for previous agent state
    local last_entry=$(grep "Agent switch detected" "$LOG_FILE" 2>/dev/null | tail -1)
    if [ -n "$last_entry" ]; then
        echo "$last_entry" | sed 's/.*from \([^ ]*\) to.*/\1/'
    else
        echo "none"
    fi
}

# ============================
# Switch Detection
# ============================
detect_agent_switch() {
    local current_agent=$(get_current_agent)
    local previous_agent=$(get_previous_agent)
    
    log_debug "Current agent: $current_agent, Previous agent: $previous_agent"
    
    # Check if switch occurred
    if [ "$current_agent" != "$previous_agent" ] && [ "$current_agent" != "none" ]; then
        log_info "Agent switch detected: from $previous_agent to $current_agent"
        return 0
    else
        return 1
    fi
}

# ============================
# Handover Trigger
# ============================
trigger_handover_generation() {
    local from_agent=$1
    local to_agent=$2
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    
    log_info "Triggering handover generation: $from_agent -> $to_agent"
    
    # Call handover generator in background
    (
        "$SCRIPT_DIR/handover-gen.sh" "$from_agent" "$to_agent" "$timestamp" &
        local pid=$!
        
        # Monitor with timeout (30 seconds)
        local count=0
        while kill -0 $pid 2>/dev/null && [ $count -lt 30 ]; do
            sleep 1
            ((count++))
        done
        
        if kill -0 $pid 2>/dev/null; then
            log_error "Handover generation timeout, killing process"
            kill -9 $pid 2>/dev/null
        else
            log_info "Handover generation completed"
        fi
    ) &
}

# ============================
# Main Monitoring Logic
# ============================
monitor_agent_switch() {
    local current_agent=$(get_current_agent)
    local previous_agent=$(get_previous_agent)
    
    if detect_agent_switch; then
        # Trigger handover generation asynchronously
        trigger_handover_generation "$previous_agent" "$current_agent"
        
        # Update state for next detection
        log_info "Agent switch recorded: from $previous_agent to $current_agent"
    else
        log_debug "No agent switch detected"
    fi
}

# ============================
# Entry Point
# ============================
main() {
    log_info "Sync monitor started"
    
    # Check if active.md exists
    if [ ! -f "$ACTIVE_FILE" ]; then
        log_error "Active agent file not found: $ACTIVE_FILE"
        exit 1
    fi
    
    # Run monitoring
    monitor_agent_switch
    
    log_info "Sync monitor completed"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi