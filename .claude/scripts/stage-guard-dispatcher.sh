#!/bin/bash

# =============================================================================
# Stage Guard Dispatcher - Agent-First システムのエントリーポイント
# ユーザーの入力からエージェントを判定し、適切なチェックを実行
# =============================================================================

set -euo pipefail

# Configuration
DEBUG_MODE=${STAGE_GUARD_DEBUG:-false}
LOG_FILE=".claude/logs/stage-guard-dispatcher.log"

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi
}

# Log function
log_debug() {
    [[ "$DEBUG_MODE" == "true" ]] && echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    [[ "$DEBUG_MODE" == "true" ]] && echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

# Extract agent from user prompt
extract_agent_from_prompt() {
    # Get user prompt from CLAUDE_PROMPT or command line args
    local prompt="${CLAUDE_PROMPT:-$*}"

    log_debug "Analyzing prompt: $prompt"

    # Extract agent name from /agent:xxx pattern
    if [[ "$prompt" =~ /agent:([a-zA-Z]+) ]]; then
        local agent="${BASH_REMATCH[1]}"
        log_debug "Extracted agent: $agent"
        echo "$agent"
        return 0
    else
        log_debug "No agent pattern found in prompt"
        echo "unknown"
        return 1
    fi
}

# Main dispatcher logic
main() {
    init_logging
    log_debug "Stage Guard Dispatcher activated"

    # Extract agent from user input
    local agent
    agent=$(extract_agent_from_prompt "$@")
    local extract_result=$?

    if [[ $extract_result -eq 0 && -n "$agent" && "$agent" != "unknown" ]]; then
        log_info "Agent request detected: $agent"

        # Execute stage guard check
        if [[ -x ".claude/scripts/stage-guard.sh" ]]; then
            log_debug "Executing stage guard for agent: $agent"

            # Call stage-guard.sh with the detected agent
            if .claude/scripts/stage-guard.sh guard "$agent"; then
                log_info "Stage guard check passed for agent: $agent"
                return 0
            else
                log_info "Stage guard check failed for agent: $agent"
                return 1
            fi
        else
            log_debug "Stage guard script not found or not executable"
            return 0
        fi
    else
        log_debug "No specific agent detected or non-agent command - allowing"
        return 0
    fi
}

# Run main function
main "$@"
