#!/usr/bin/env bash
# Alert System - Sprint 2.4 Task 2.4.2 (Refactored)
# Following t-wada style TDD Green Phase
# Refactored for better maintainability and performance

set -euo pipefail

#============================================================================
# CONSTANTS AND CONFIGURATION
#============================================================================

# Default file paths
readonly DEFAULT_ALERT_CONFIG="$HOME/.claude/monitoring-config.json"
readonly DEFAULT_METRICS_FILE="$HOME/.claude/logs/metrics.txt"
readonly DEFAULT_ALERT_LOG="$HOME/.claude/logs/alerts.log"
readonly DEFAULT_CLAUDE_PROJECT_DIR="."

# Configuration variables with fallbacks
ALERT_CONFIG="${ALERT_CONFIG:-$DEFAULT_ALERT_CONFIG}"
METRICS_FILE="${METRICS_FILE:-$DEFAULT_METRICS_FILE}"
ALERT_LOG="${ALERT_LOG:-$DEFAULT_ALERT_LOG}"
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$DEFAULT_CLAUDE_PROJECT_DIR}"

# Alert thresholds (defaults)
ERROR_RATE_THRESHOLD="${ERROR_RATE_THRESHOLD:-0.1}"
RESPONSE_TIME_THRESHOLD="${RESPONSE_TIME_THRESHOLD:-1.0}"
MEMORY_BANK_CAPACITY_THRESHOLD="${MEMORY_BANK_CAPACITY_THRESHOLD:-0.8}"
NOTIFICATION_ENABLED="${NOTIFICATION_ENABLED:-true}"

# System constants
readonly MEMORY_BANK_MAX_LINES=500
readonly DEFAULT_ALERT_RETENTION_DAYS=7
readonly NUMERIC_PRECISION="%.2f"
readonly DATE_FORMAT='%Y-%m-%d %H:%M:%S'
readonly DATE_ONLY_FORMAT='%Y-%m-%d'

# Alert severity levels
readonly SEVERITY_CRITICAL="CRITICAL"
readonly SEVERITY_HIGH="HIGH"
readonly SEVERITY_MEDIUM="MEDIUM"
readonly SEVERITY_LOW="LOW"

#============================================================================
# UTILITY FUNCTIONS
#============================================================================

# Check if a file exists and is readable
_file_exists_and_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Safely calculate floating point comparison
_float_greater_than() {
    local value="$1"
    local threshold="$2"
    (( $(awk "BEGIN {print ($value > $threshold)}") ))
}

# Format floating point number with standard precision
_format_float() {
    local value="$1"
    awk "BEGIN {printf \"$NUMERIC_PRECISION\", $value}"
}

# Extract metric count for hook and status
_extract_metric_count() {
    local hook_name="$1"
    local status="$2"
    local metrics_file="$3"

    grep "hook=\"$hook_name\",status=\"$status\"" "$metrics_file" 2>/dev/null | \
        awk '{sum+=$2} END {print sum+0}'
}

# Calculate error rate for a hook
_calculate_error_rate() {
    local hook_name="$1"
    local metrics_file="$2"

    local errors=$(_extract_metric_count "$hook_name" "error" "$metrics_file")
    local successes=$(_extract_metric_count "$hook_name" "success" "$metrics_file")
    local total=$((errors + successes))

    if [[ $total -eq 0 ]]; then
        echo "0"
        return 1  # No data available
    fi

    _format_float "$(awk "BEGIN {print $errors / $total}")"
    return 0
}

#============================================================================
# ERROR RATE MONITORING
#============================================================================

# Check if error rate exceeds threshold for a specific hook
# Parameters:
#   $1: hook_name - Name of the hook to check
#   $2: threshold - Error rate threshold (optional, defaults to ERROR_RATE_THRESHOLD)
# Returns:
#   0: Error rate is acceptable or no data available
#   1: Error rate exceeds threshold
check_error_rate() {
    local hook_name="$1"
    local threshold="${2:-$ERROR_RATE_THRESHOLD}"

    _file_exists_and_readable "$METRICS_FILE" || return 0

    local error_rate
    if ! error_rate=$(_calculate_error_rate "$hook_name" "$METRICS_FILE"); then
        return 0  # No data, don't alert
    fi

    if _float_greater_than "$error_rate" "$threshold"; then
        echo "ALERT: Error rate $error_rate exceeds threshold $threshold for hook $hook_name"
        return 1
    fi

    return 0
}

#============================================================================
# RESPONSE TIME MONITORING
#============================================================================

# Calculate average response time for a hook
# Parameters:
#   $1: hook_name - Name of the hook
#   $2: metrics_file - Path to metrics file
# Returns:
#   0: Success, prints average response time
#   1: No data available
_calculate_average_response_time() {
    local hook_name="$1"
    local metrics_file="$2"

    local response_times
    response_times=$(grep "hook=\"$hook_name\"" "$metrics_file" 2>/dev/null | \
                    grep 'hook_execution_duration_seconds' | \
                    awk '{print $2}' || true)

    if [[ -z "$response_times" ]]; then
        return 1  # No data available
    fi

    local sum=0
    local count=0
    while IFS= read -r time; do
        [[ -n "$time" ]] || continue
        sum=$(awk "BEGIN {printf \"$NUMERIC_PRECISION\", $sum + $time}")
        count=$((count + 1))
    done <<< "$response_times"

    if [[ $count -eq 0 ]]; then
        return 1
    fi

    _format_float "$(awk "BEGIN {print $sum / $count}")"
    return 0
}

# Check if response time exceeds threshold for a specific hook
# Parameters:
#   $1: hook_name - Name of the hook to check
#   $2: threshold - Response time threshold (optional, defaults to RESPONSE_TIME_THRESHOLD)
# Returns:
#   0: Response time is acceptable or no data available
#   1: Response time exceeds threshold
check_response_time() {
    local hook_name="$1"
    local threshold="${2:-$RESPONSE_TIME_THRESHOLD}"

    _file_exists_and_readable "$METRICS_FILE" || return 0

    local avg_response_time
    if ! avg_response_time=$(_calculate_average_response_time "$hook_name" "$METRICS_FILE"); then
        return 0  # No data, don't alert
    fi

    if _float_greater_than "$avg_response_time" "$threshold"; then
        echo "ALERT: Average response time $avg_response_time exceeds threshold $threshold for hook $hook_name"
        return 1
    fi

    return 0
}

#============================================================================
# MEMORY BANK CAPACITY MONITORING
#============================================================================

# Calculate capacity usage for a specific notes file
# Parameters:
#   $1: notes_file - Path to the notes file
# Returns:
#   Prints usage ratio (0.0 to 1.0+)
_calculate_file_capacity_usage() {
    local notes_file="$1"

    if [[ ! -f "$notes_file" ]]; then
        echo "0"
        return 0
    fi

    local lines
    lines=$(wc -l < "$notes_file" 2>/dev/null || echo "0")
    _format_float "$(awk "BEGIN {print $lines / $MEMORY_BANK_MAX_LINES}")"
}

# Get maximum capacity usage across all Memory Bank files
# Parameters:
#   $1: project_dir - Claude project directory
# Returns:
#   Prints maximum usage ratio
_get_max_memory_bank_usage() {
    local project_dir="$1"
    local planner_notes="$project_dir/.claude/planner/notes.md"
    local builder_notes="$project_dir/.claude/builder/notes.md"

    local planner_usage
    local builder_usage

    planner_usage=$(_calculate_file_capacity_usage "$planner_notes")
    builder_usage=$(_calculate_file_capacity_usage "$builder_notes")

    # Return the maximum of the two
    if _float_greater_than "$planner_usage" "$builder_usage"; then
        echo "$planner_usage"
    else
        echo "$builder_usage"
    fi
}

# Check if Memory Bank capacity exceeds threshold
# Parameters:
#   $1: threshold - Capacity threshold (optional, defaults to MEMORY_BANK_CAPACITY_THRESHOLD)
# Returns:
#   0: Capacity usage is acceptable
#   1: Capacity usage exceeds threshold
check_memory_bank_capacity() {
    local threshold="${1:-$MEMORY_BANK_CAPACITY_THRESHOLD}"

    local max_usage
    max_usage=$(_get_max_memory_bank_usage "$CLAUDE_PROJECT_DIR")

    if _float_greater_than "$max_usage" "$threshold"; then
        echo "ALERT: Memory Bank capacity usage $max_usage exceeds threshold $threshold"
        return 1
    fi

    return 0
}

#============================================================================
# ALERT NOTIFICATION SYSTEM
#============================================================================

# Check if notifications are enabled
# Returns:
#   0: Notifications are enabled
#   1: Notifications are disabled
_notifications_enabled() {
    [[ "$NOTIFICATION_ENABLED" == "true" ]]
}

# Ensure alert log directory exists
# Parameters:
#   $1: log_file_path - Path to the log file
_ensure_log_directory() {
    local log_file="$1"
    local log_dir
    log_dir=$(dirname "$log_file")

    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
}

# Format alert message with timestamp and severity
# Parameters:
#   $1: alert_type - Type of alert
#   $2: message - Alert message
#   $3: severity - Alert severity level
# Returns:
#   Formatted alert string
_format_alert_message() {
    local alert_type="$1"
    local message="$2"
    local severity="$3"
    local timestamp

    timestamp=$(date "+$DATE_FORMAT")
    echo "[$timestamp] [$severity] $alert_type: $message"
}

# Send alert notification and log it
# Parameters:
#   $1: alert_type - Type of alert (e.g., ERROR_RATE, RESPONSE_TIME)
#   $2: message - Alert message
#   $3: severity - Alert severity (optional, defaults to LOW)
# Returns:
#   0: Alert sent successfully or notifications disabled
send_alert() {
    local alert_type="$1"
    local message="$2"
    local severity="${3:-$SEVERITY_LOW}"

    # Exit early if notifications are disabled
    _notifications_enabled || return 0

    # Ensure log directory exists
    _ensure_log_directory "$ALERT_LOG"

    # Format and log alert
    local formatted_alert
    formatted_alert=$(_format_alert_message "$alert_type" "$message" "$severity")
    echo "$formatted_alert" >> "$ALERT_LOG"

    return 0
}

#============================================================================
# CONFIGURATION MANAGEMENT
#============================================================================

# Check if jq is available for JSON parsing
# Returns:
#   0: jq is available
#   1: jq is not available
_jq_available() {
    command -v jq >/dev/null 2>&1
}

# Load configuration value from JSON file with fallback
# Parameters:
#   $1: config_file - Path to JSON config file
#   $2: json_path - JSON path (e.g., '.alerts.error_rate_threshold')
#   $3: default_value - Default value if not found
# Returns:
#   Configuration value or default
_load_config_value() {
    local config_file="$1"
    local json_path="$2"
    local default_value="$3"

    if _jq_available; then
        jq -r "$json_path // \"$default_value\"" "$config_file" 2>/dev/null || echo "$default_value"
    else
        echo "$default_value"
    fi
}

# Load alert configuration from file
# Parameters:
#   $1: config_file - Path to config file (optional, defaults to ALERT_CONFIG)
# Returns:
#   0: Configuration loaded successfully
load_alert_config() {
    local config_file="${1:-$ALERT_CONFIG}"

    # Skip if config file doesn't exist
    _file_exists_and_readable "$config_file" || return 0

    # Load configuration values with fallbacks
    ERROR_RATE_THRESHOLD=$(_load_config_value "$config_file" '.alerts.error_rate_threshold' '0.1')
    RESPONSE_TIME_THRESHOLD=$(_load_config_value "$config_file" '.alerts.response_time_threshold' '1.0')
    MEMORY_BANK_CAPACITY_THRESHOLD=$(_load_config_value "$config_file" '.alerts.memory_bank_capacity_threshold' '0.8')

    # Handle notification_enabled as special case
    if _jq_available; then
        local notification
        notification=$(jq -r '.alerts.notification_enabled' "$config_file" 2>/dev/null || echo "null")
        if [[ "$notification" != "null" ]]; then
            NOTIFICATION_ENABLED="$notification"
        fi
    fi

    return 0
}

# Get specific alert threshold value by name
# Parameters:
#   $1: threshold_name - Name of the threshold to retrieve
# Returns:
#   Threshold value or 0 if not found
get_alert_threshold() {
    local threshold_name="$1"

    case "$threshold_name" in
        error_rate_threshold)
            echo "$ERROR_RATE_THRESHOLD"
            ;;
        response_time_threshold)
            echo "$RESPONSE_TIME_THRESHOLD"
            ;;
        memory_bank_capacity_threshold)
            echo "$MEMORY_BANK_CAPACITY_THRESHOLD"
            ;;
        *)
            echo "0"
            ;;
    esac

    return 0
}

#============================================================================
# ALERT SUMMARY AND REPORTING
#============================================================================

# Count alerts by severity level
# Parameters:
#   $1: severity_level - Severity level to count
#   $2: alert_log_file - Path to alert log file
# Returns:
#   Count of alerts for the specified severity
_count_alerts_by_severity() {
    local severity="$1"
    local log_file="$2"

    grep -c "\[$severity\]" "$log_file" 2>/dev/null || echo 0
}

# Generate comprehensive alert summary report
# Returns:
#   0: Summary generated successfully
generate_alert_summary() {
    if ! _file_exists_and_readable "$ALERT_LOG"; then
        echo "Alert Summary: No alerts logged"
        return 0
    fi

    echo "Alert Summary"
    echo "============="

    # Count alerts by severity using helper function
    local critical_count high_count medium_count low_count
    critical_count=$(_count_alerts_by_severity "$SEVERITY_CRITICAL" "$ALERT_LOG")
    high_count=$(_count_alerts_by_severity "$SEVERITY_HIGH" "$ALERT_LOG")
    medium_count=$(_count_alerts_by_severity "$SEVERITY_MEDIUM" "$ALERT_LOG")
    low_count=$(_count_alerts_by_severity "$SEVERITY_LOW" "$ALERT_LOG")

    echo "CRITICAL: $critical_count"
    echo "HIGH: $high_count"
    echo "MEDIUM: $medium_count"
    echo "LOW: $low_count"

    return 0
}

#============================================================================
# ALERT CLEANUP AND MAINTENANCE
#============================================================================

# Calculate cutoff date for alert retention
# Parameters:
#   $1: days_to_keep - Number of days to retain alerts
# Returns:
#   Cutoff date in YYYY-MM-DD format
_calculate_cutoff_date() {
    local days_to_keep="$1"

    # Try different date command syntaxes (GNU vs BSD)
    date -d "$days_to_keep days ago" "+$DATE_ONLY_FORMAT" 2>/dev/null || \
    date -v -"${days_to_keep}d" "+$DATE_ONLY_FORMAT" 2>/dev/null || \
    echo "2020-01-01"  # Fallback to old date
}

# Check if alert date is within retention period
# Parameters:
#   $1: alert_date - Date from alert log entry
#   $2: cutoff_date - Cutoff date for retention
# Returns:
#   0: Alert should be kept
#   1: Alert should be removed
_should_keep_alert() {
    local alert_date="$1"
    local cutoff_date="$2"

    [[ "$alert_date" > "$cutoff_date" ]] || [[ "$alert_date" == "$cutoff_date" ]]
}

# Filter and keep recent alerts
# Parameters:
#   $1: alert_log_file - Source alert log file
#   $2: temp_file - Temporary file for filtered alerts
#   $3: cutoff_date - Date cutoff for retention
# Returns:
#   0: Filtering completed successfully
_filter_recent_alerts() {
    local alert_log="$1"
    local temp_file="$2"
    local cutoff_date="$3"

    while IFS= read -r line; do
        if [[ "$line" =~ ^\[([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            local alert_date="${BASH_REMATCH[1]}"
            if _should_keep_alert "$alert_date" "$cutoff_date"; then
                echo "$line" >> "$temp_file"
            fi
        fi
    done < "$alert_log"

    return 0
}

# Clear old alerts beyond retention period
# Parameters:
#   $1: days_to_keep - Number of days to retain (optional, defaults to DEFAULT_ALERT_RETENTION_DAYS)
# Returns:
#   0: Cleanup completed successfully
clear_old_alerts() {
    local days_to_keep="${1:-$DEFAULT_ALERT_RETENTION_DAYS}"

    _file_exists_and_readable "$ALERT_LOG" || return 0

    # Create temp file for filtered alerts
    local temp_file
    temp_file=$(mktemp)

    # Calculate cutoff date and filter alerts
    local cutoff_date
    cutoff_date=$(_calculate_cutoff_date "$days_to_keep")

    # Filter alerts and handle cleanup
    if _filter_recent_alerts "$ALERT_LOG" "$temp_file" "$cutoff_date"; then
        # Replace old log with filtered version
        mv "$temp_file" "$ALERT_LOG"
    else
        # Clean up temp file on error
        rm -f "$temp_file"
        return 1
    fi

    return 0
}

#============================================================================
# MAIN MONITORING AND ALERTING
#============================================================================

# Extract unique hook names from metrics file
# Parameters:
#   $1: metrics_file - Path to metrics file
# Returns:
#   List of unique hook names
_extract_hook_names() {
    local metrics_file="$1"

    # Using sed instead of grep -P for better portability
    sed -n 's/.*hook="\([^"]*\)".*/\1/p' "$metrics_file" 2>/dev/null | \
        sort -u || true
}

# Monitor a single hook for all alert conditions
# Parameters:
#   $1: hook_name - Name of the hook to monitor
_monitor_single_hook() {
    local hook_name="$1"

    [[ -n "$hook_name" ]] || return 0

    # Check error rate
    if ! check_error_rate "$hook_name" "$ERROR_RATE_THRESHOLD"; then
        send_alert "ERROR_RATE" "Hook $hook_name error rate exceeded threshold" "$SEVERITY_HIGH"
    fi

    # Check response time
    if ! check_response_time "$hook_name" "$RESPONSE_TIME_THRESHOLD"; then
        send_alert "RESPONSE_TIME" "Hook $hook_name response time exceeded threshold" "$SEVERITY_MEDIUM"
    fi
}

# Monitor all hooks from metrics file
# Parameters:
#   $1: metrics_file - Path to metrics file
_monitor_all_hooks() {
    local metrics_file="$1"

    local hooks
    hooks=$(_extract_hook_names "$metrics_file")

    if [[ -n "$hooks" ]]; then
        while IFS= read -r hook; do
            _monitor_single_hook "$hook"
        done <<< "$hooks"
    fi
}

# Main monitoring function - performs full monitoring cycle
# Returns:
#   0: Monitoring completed successfully
monitor_and_alert() {
    # Load configuration first
    load_alert_config

    # Monitor hooks if metrics file exists
    if _file_exists_and_readable "$METRICS_FILE"; then
        _monitor_all_hooks "$METRICS_FILE"
    fi

    # Check Memory Bank capacity
    if ! check_memory_bank_capacity "$MEMORY_BANK_CAPACITY_THRESHOLD"; then
        send_alert "CAPACITY" "Memory Bank capacity exceeded threshold" "$SEVERITY_HIGH"
    fi

    return 0
}

#============================================================================
# ALERT RULE VALIDATION
#============================================================================

# Validate that a threshold is within specified range
# Parameters:
#   $1: threshold_value - Value to validate
#   $2: min_value - Minimum allowed value
#   $3: max_value - Maximum allowed value (optional)
# Returns:
#   0: Valid
#   1: Invalid
_validate_threshold_range() {
    local threshold="$1"
    local min_value="$2"
    local max_value="${3:-}"

    # Check minimum
    if _float_greater_than "$min_value" "$threshold"; then
        return 1
    fi

    # Check maximum if provided
    if [[ -n "$max_value" ]] && _float_greater_than "$threshold" "$max_value"; then
        return 1
    fi

    return 0
}

# Validate individual threshold values
# Returns:
#   0: All thresholds valid
#   1: One or more thresholds invalid
_validate_threshold_values() {
    # Validate error rate threshold (0-1)
    if ! _validate_threshold_range "$ERROR_RATE_THRESHOLD" "0" "1"; then
        echo "Invalid: error_rate_threshold must be between 0 and 1"
        return 1
    fi

    # Validate response time threshold (positive)
    if ! _validate_threshold_range "$RESPONSE_TIME_THRESHOLD" "0"; then
        echo "Invalid: response_time_threshold must be positive"
        return 1
    fi

    # Validate memory bank capacity threshold (0-1)
    if ! _validate_threshold_range "$MEMORY_BANK_CAPACITY_THRESHOLD" "0" "1"; then
        echo "Invalid: memory_bank_capacity_threshold must be between 0 and 1"
        return 1
    fi

    return 0
}

# Validate alert configuration rules
# Parameters:
#   $1: config_file - Path to config file (optional, defaults to ALERT_CONFIG)
# Returns:
#   0: Configuration is valid
#   1: Configuration is invalid
validate_alert_rules() {
    local config_file="${1:-$ALERT_CONFIG}"

    if ! _file_exists_and_readable "$config_file"; then
        echo "Invalid: Configuration file not found"
        return 1
    fi

    # Load configuration
    load_alert_config "$config_file"

    # Validate threshold values
    if ! _validate_threshold_values; then
        return 1
    fi

    echo "Valid configuration"
    return 0
}

#============================================================================
# INTEGRATION WITH EXTERNAL SYSTEMS
#============================================================================

# Placeholder for metrics collector integration
# This function would be imported from metrics-collector.sh
# Returns:
#   0: Metrics collection completed
collect_metrics() {
    # Placeholder for integration with metrics collector
    return 0
}

#============================================================================
# MAIN EXECUTION ENTRY POINT
#============================================================================

# Main entry point when script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Run full monitoring cycle
    monitor_and_alert
fi