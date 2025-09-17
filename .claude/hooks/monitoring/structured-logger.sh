#!/bin/bash

# structured-logger.sh - Advanced structured logging system (2025 standards)
# Created: 2025-09-17 (全体リファクタリング)
# Implements: JSON structured logging with jq, Event-driven monitoring patterns

set -euo pipefail

# Configuration (2025 best practices)
readonly LOGGER_VERSION="2.0.0"
readonly LOG_FORMAT_VERSION="1.0"
readonly DEFAULT_LOG_LEVEL="info"
readonly DEFAULT_LOG_FILE=".claude/logs/structured.jsonl"

# Global configuration
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_LEVEL="${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
LOG_FILE="${LOG_FILE:-$CLAUDE_PROJECT_DIR/$DEFAULT_LOG_FILE}"
COMPONENT_NAME="${COMPONENT_NAME:-unknown}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log level priorities (syslog standard)
declare -A LOG_LEVELS=(
    ["debug"]=7
    ["info"]=6
    ["notice"]=5
    ["warning"]=4
    ["error"]=3
    ["critical"]=2
    ["alert"]=1
    ["emergency"]=0
)

# Performance optimization: Cache frequently used values
declare -A CACHED_VALUES
CACHED_VALUES["hostname"]="$(hostname 2>/dev/null || echo 'unknown')"
CACHED_VALUES["user"]="$(whoami 2>/dev/null || echo 'unknown')"
CACHED_VALUES["pid"]="$$"

# Core structured logging function (2025 enhanced version)
log_structured() {
    local level="$1"
    local component="${2:-$COMPONENT_NAME}"
    local message="$3"
    local context="${4:-}"
    local extra_fields="${5:-}"

    # Performance: Check log level early to avoid unnecessary processing
    local current_level_priority="${LOG_LEVELS[$LOG_LEVEL]:-6}"
    local message_level_priority="${LOG_LEVELS[$level]:-6}"

    if [[ $message_level_priority -gt $current_level_priority ]]; then
        return 0  # Skip logging if level is too low
    fi

    # Create base log entry with enhanced metadata
    local log_entry
    log_entry=$(jq -n \
        --arg timestamp "$(date -Iseconds)" \
        --arg level "$level" \
        --arg component "$component" \
        --arg message "$message" \
        --arg context "$context" \
        --arg hostname "${CACHED_VALUES[hostname]}" \
        --arg user "${CACHED_VALUES[user]}" \
        --arg pid "${CACHED_VALUES[pid]}" \
        --arg pwd "$(pwd)" \
        --arg logger_version "$LOGGER_VERSION" \
        --arg format_version "$LOG_FORMAT_VERSION" \
        '{
            "@timestamp": $timestamp,
            "@version": $format_version,
            "level": $level,
            "component": $component,
            "message": $message,
            "context": $context,
            "system": {
                "hostname": $hostname,
                "user": $user,
                "pid": ($pid | tonumber),
                "pwd": $pwd
            },
            "logger": {
                "name": "structured-logger",
                "version": $logger_version
            }
        }')

    # Merge additional fields if provided
    if [[ -n "$extra_fields" ]]; then
        local merged_entry
        if merged_entry=$(echo "$log_entry" | jq ". + $extra_fields" 2>/dev/null); then
            log_entry="$merged_entry"
        else
            # Fallback: Add extra_fields as raw string if JSON merge fails
            log_entry=$(echo "$log_entry" | jq --arg extra "$extra_fields" '. + {"extra": $extra}')
        fi
    fi

    # Thread-safe atomic write to log file
    {
        flock -x 200
        echo "$log_entry" >> "$LOG_FILE"
    } 200>"${LOG_FILE}.lock"

    # Also output to stderr for real-time monitoring (with color coding)
    local color=""
    local reset="\033[0m"
    case "$level" in
        "emergency"|"alert"|"critical"|"error")
            color="\033[0;31m"  # Red
            ;;
        "warning")
            color="\033[1;33m"  # Yellow
            ;;
        "notice"|"info")
            color="\033[0;34m"  # Blue
            ;;
        "debug")
            color="\033[0;37m"  # Gray
            ;;
    esac

    printf "${color}[%s] %s: %s${reset}\n" \
           "$(date '+%H:%M:%S')" \
           "$component" \
           "$message" >&2

    return 0
}

# Convenience logging functions
log_debug() {
    log_structured "debug" "${COMPONENT_NAME}" "$@"
}

log_info() {
    log_structured "info" "${COMPONENT_NAME}" "$@"
}

log_notice() {
    log_structured "notice" "${COMPONENT_NAME}" "$@"
}

log_warning() {
    log_structured "warning" "${COMPONENT_NAME}" "$@"
}

log_error() {
    log_structured "error" "${COMPONENT_NAME}" "$@"
}

log_critical() {
    log_structured "critical" "${COMPONENT_NAME}" "$@"
}

# Performance monitoring integration
log_performance() {
    local operation="$1"
    local duration="$2"
    local status="${3:-success}"
    local details="${4:-}"

    local performance_data
    performance_data=$(jq -n \
        --arg operation "$operation" \
        --arg duration "$duration" \
        --arg status "$status" \
        --arg details "$details" \
        '{
            "performance": {
                "operation": $operation,
                "duration_seconds": ($duration | tonumber),
                "status": $status,
                "details": $details
            }
        }')

    log_structured "info" "performance" "Operation completed: $operation" "$details" "$performance_data"
}

# Error tracking with context
log_error_with_context() {
    local error_message="$1"
    local error_code="${2:-1}"
    local function_name="${3:-${FUNCNAME[1]:-unknown}}"
    local line_number="${4:-${BASH_LINENO[0]:-unknown}}"
    local file_name="${5:-${BASH_SOURCE[1]:-unknown}}"

    local error_context
    error_context=$(jq -n \
        --arg error_code "$error_code" \
        --arg function_name "$function_name" \
        --arg line_number "$line_number" \
        --arg file_name "$file_name" \
        --arg stack_trace "$(caller)" \
        '{
            "error": {
                "code": ($error_code | tonumber),
                "function": $function_name,
                "line": ($line_number | tonumber),
                "file": $file_name,
                "stack_trace": $stack_trace
            }
        }')

    log_structured "error" "${COMPONENT_NAME}" "$error_message" "error_context" "$error_context"
}

# Event-driven logging for monitoring patterns
log_event() {
    local event_type="$1"
    local event_data="$2"
    local correlation_id="${3:-$(date +%s%N)}"

    local event_metadata
    event_metadata=$(jq -n \
        --arg event_type "$event_type" \
        --arg correlation_id "$correlation_id" \
        --argjson event_data "$event_data" \
        '{
            "event": {
                "type": $event_type,
                "correlation_id": $correlation_id,
                "data": $event_data
            }
        }')

    log_structured "info" "event" "Event: $event_type" "correlation_id=$correlation_id" "$event_metadata"
}

# Hook-specific logging functions
log_hook_start() {
    local hook_name="$1"
    local trigger_event="${2:-unknown}"

    local hook_data
    hook_data=$(jq -n \
        --arg hook_name "$hook_name" \
        --arg trigger_event "$trigger_event" \
        '{
            "hook": {
                "name": $hook_name,
                "phase": "start",
                "trigger_event": $trigger_event
            }
        }')

    log_structured "info" "hook" "Hook started: $hook_name" "trigger=$trigger_event" "$hook_data"
}

log_hook_complete() {
    local hook_name="$1"
    local duration="$2"
    local status="${3:-success}"
    local details="${4:-}"

    local hook_data
    hook_data=$(jq -n \
        --arg hook_name "$hook_name" \
        --arg duration "$duration" \
        --arg status "$status" \
        --arg details "$details" \
        '{
            "hook": {
                "name": $hook_name,
                "phase": "complete",
                "duration_seconds": ($duration | tonumber),
                "status": $status,
                "details": $details
            }
        }')

    log_structured "info" "hook" "Hook completed: $hook_name" "status=$status duration=${duration}s" "$hook_data"
}

# Memory Bank specific logging
log_memory_bank_operation() {
    local operation="$1"       # rotate, archive, analyze
    local file_path="$2"
    local details="$3"
    local metrics="${4:-}"

    local mb_data
    mb_data=$(jq -n \
        --arg operation "$operation" \
        --arg file_path "$file_path" \
        --arg details "$details" \
        --argjson metrics "${metrics:-null}" \
        '{
            "memory_bank": {
                "operation": $operation,
                "file_path": $file_path,
                "details": $details,
                "metrics": $metrics
            }
        }')

    log_structured "info" "memory_bank" "Memory Bank $operation: $(basename "$file_path")" "$details" "$mb_data"
}

# Parallel execution logging
log_parallel_task() {
    local task_id="$1"
    local command="$2"
    local status="$3"        # queued, started, completed, failed
    local worker_id="${4:-}"
    local duration="${5:-}"

    local task_data
    task_data=$(jq -n \
        --arg task_id "$task_id" \
        --arg command "$command" \
        --arg status "$status" \
        --arg worker_id "$worker_id" \
        --arg duration "$duration" \
        '{
            "parallel_task": {
                "id": $task_id,
                "command": $command,
                "status": $status,
                "worker_id": $worker_id,
                "duration_seconds": (if $duration != "" then ($duration | tonumber) else null end)
            }
        }')

    log_structured "info" "parallel" "Task $status: $task_id" "worker=$worker_id" "$task_data"
}

# TDD compliance logging
log_tdd_check() {
    local file_path="$1"
    local check_type="$2"     # test_exists, coverage, compliance
    local result="$3"         # pass, fail, warning
    local details="$4"

    local tdd_data
    tdd_data=$(jq -n \
        --arg file_path "$file_path" \
        --arg check_type "$check_type" \
        --arg result "$result" \
        --arg details "$details" \
        '{
            "tdd_check": {
                "file_path": $file_path,
                "check_type": $check_type,
                "result": $result,
                "details": $details
            }
        }')

    local log_level="info"
    if [[ "$result" == "fail" ]]; then
        log_level="error"
    elif [[ "$result" == "warning" ]]; then
        log_level="warning"
    fi

    log_structured "$log_level" "tdd" "TDD $check_type: $result" "file=$(basename "$file_path")" "$tdd_data"
}

# Log analysis and query functions
query_logs() {
    local query="$1"
    local limit="${2:-100}"

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No log file found: $LOG_FILE" >&2
        return 1
    fi

    # Use jq to filter and format logs
    tail -n "$limit" "$LOG_FILE" | jq -s --arg query "$query" '
        map(select(.component == $query or .message | contains($query) or .level == $query))
        | sort_by(."@timestamp")
        | reverse
    ' 2>/dev/null || {
        echo "Error querying logs. Check jq syntax and log file format." >&2
        return 1
    }
}

# Get log statistics
get_log_stats() {
    local hours="${1:-24}"

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No log file found: $LOG_FILE" >&2
        return 1
    fi

    local since_timestamp
    since_timestamp=$(date -d "$hours hours ago" -Iseconds)

    jq -s --arg since "$since_timestamp" '
        map(select(."@timestamp" >= $since))
        | group_by(.level)
        | map({
            level: .[0].level,
            count: length,
            latest: map(."@timestamp") | max
        })
        | sort_by(.level)
    ' "$LOG_FILE" 2>/dev/null || {
        echo "Error analyzing logs." >&2
        return 1
    }
}

# Log rotation management
rotate_logs() {
    local max_size_mb="${1:-100}"
    local keep_files="${2:-5}"

    if [[ ! -f "$LOG_FILE" ]]; then
        return 0
    fi

    local file_size_mb
    file_size_mb=$(du -m "$LOG_FILE" | cut -f1)

    if [[ $file_size_mb -gt $max_size_mb ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d-%H%M%S)
        local rotated_file="${LOG_FILE}.${timestamp}"

        # Atomic rotation
        mv "$LOG_FILE" "$rotated_file"

        # Compress rotated file
        gzip "$rotated_file" &

        # Clean up old rotated files
        find "$(dirname "$LOG_FILE")" -name "$(basename "$LOG_FILE").*.gz" -type f | \
            sort -r | tail -n +$((keep_files + 1)) | xargs rm -f

        log_info "Log rotated to $(basename "$rotated_file").gz"
    fi
}

# Export functions for use in other scripts
export -f log_structured log_debug log_info log_notice log_warning log_error log_critical
export -f log_performance log_error_with_context log_event
export -f log_hook_start log_hook_complete
export -f log_memory_bank_operation log_parallel_task log_tdd_check
export -f query_logs get_log_stats rotate_logs

# Initialize logging if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    log_debug "Structured logger initialized (version $LOGGER_VERSION)"
fi

# Main function for direct execution
main() {
    case "${1:-info}" in
        test)
            COMPONENT_NAME="test"
            log_info "Testing structured logger" "test context" '{"test": true, "number": 42}'
            log_warning "This is a warning"
            log_error "This is an error"
            log_performance "test_operation" "1.23" "success" "All systems go"

            # Test hook logging
            log_hook_start "test-hook" "manual_test"
            sleep 0.1
            log_hook_complete "test-hook" "0.1" "success" "Manual test completed"

            # Test integration functions
            log_event "test_event" '{"source": "manual_test", "timestamp": "'$(date -Iseconds)'"}'
            log_tdd_check "test_file.js" "test_exists" "pass" "Manual test validation"
            ;;
        integration)
            COMPONENT_NAME="integration-test"
            log_info "Starting comprehensive integration test"

            # Test all logging functions
            log_event "integration_start" '{"test_suite": "comprehensive"}'
            log_error_with_context "Sample error for testing" "500" "test_function" "100" "test.sh"
            log_memory_bank_operation "test" "/tmp/test.md" "Integration test" '{"size": 512}'
            log_parallel_task "test-task-001" "echo hello" "completed" "worker-test" "0.05"

            log_info "Integration test completed successfully"
            ;;
        query)
            query_logs "${2:-}" "${3:-50}"
            ;;
        stats)
            get_log_stats "${2:-24}"
            ;;
        rotate)
            rotate_logs "${2:-100}" "${3:-5}"
            ;;
        *)
            echo "Usage: $0 {test|query [pattern] [limit]|stats [hours]|rotate [max_mb] [keep_files]}"
            echo "Or source this script to use logging functions in your scripts"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi