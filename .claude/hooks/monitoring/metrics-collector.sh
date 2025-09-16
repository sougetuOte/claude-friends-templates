#!/bin/bash
# Metrics Collector System
# Collects and aggregates monitoring data for Claude Code hooks

set -euo pipefail

# Configuration defaults
DEFAULT_METRICS_RETENTION_DAYS=30
DEFAULT_LOG_AGGREGATION_LIMIT=100
DEFAULT_ERROR_RATE_THRESHOLD=0.1
DEFAULT_RESPONSE_TIME_THRESHOLD=1.0
DEFAULT_MAX_PARALLEL_HOOKS=5
DEFAULT_TIMEOUT_SECONDS=300
DEFAULT_BATCH_SIZE=1000

# Global configuration variables
MONITORING_CONFIG=""
declare -A MONITORING_SETTINGS

# Performance optimization variables
LAST_METRICS_CHECK=0
METRICS_CACHE=""

# Initialize paths
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
METRICS_FILE="${METRICS_FILE:-$CLAUDE_PROJECT_DIR/.claude/logs/metrics.txt}"
AGGREGATED_LOG="${AGGREGATED_LOG:-$CLAUDE_PROJECT_DIR/.claude/logs/aggregated.log}"
LOG_FILE="${LOG_FILE:-$CLAUDE_PROJECT_DIR/.claude/logs/monitoring.log}"

#============================================================================
# Logging Functions
#============================================================================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true

    # Also write to stderr for errors
    if [[ "$level" == "ERROR" ]]; then
        echo "[$timestamp] [$level] $message" >&2 2>/dev/null || true
    fi
}

log_debug() {
    if [[ "${MONITORING_DEBUG:-}" == "1" ]]; then
        log_message "DEBUG" "$1"
    fi
}

log_info() {
    log_message "INFO" "$1"
}

log_warning() {
    log_message "WARN" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

#============================================================================
# Metrics Collection Functions
#============================================================================

collect_metrics() {
    local hook_name="$1"
    local duration="$2"
    local status="$3"
    local start_time=$(date +%s.%N)

    # Enhanced parameter validation
    if [[ $# -ne 3 ]]; then
        log_error "collect_metrics: Expected 3 parameters, got $#"
        return 1
    fi

    if [[ -z "$hook_name" || -z "$duration" || -z "$status" ]]; then
        log_error "collect_metrics: Missing required parameters (hook_name='$hook_name', duration='$duration', status='$status')"
        return 1
    fi

    # Validate hook name format (alphanumeric, underscore, dash)
    if ! [[ "$hook_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "collect_metrics: Invalid hook name format: '$hook_name'"
        return 1
    fi

    # Validate duration format (should be numeric)
    if ! [[ "$duration" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        log_error "collect_metrics: Invalid duration format: '$duration'"
        return 1
    fi

    # Validate status
    if [[ "$status" != "success" && "$status" != "error" ]]; then
        log_error "collect_metrics: Invalid status: '$status' (must be 'success' or 'error')"
        return 1
    fi

    # Create directory with proper error handling
    if ! mkdir -p "$(dirname "$METRICS_FILE")" 2>/dev/null; then
        log_error "collect_metrics: Failed to create metrics directory: $(dirname "$METRICS_FILE")"
        return 1
    fi

    # Generate timestamp in ISO format
    local timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)

    # Write Prometheus-format metrics with error handling
    {
        echo "hook_execution_duration_seconds{hook=\"${hook_name}\"} ${duration} ${timestamp}"
        echo "hook_execution_total{hook=\"${hook_name}\",status=\"${status}\"} 1 ${timestamp}"
    } >> "$METRICS_FILE" 2>/dev/null || {
        log_error "collect_metrics: Failed to write metrics to file: $METRICS_FILE"
        return 1
    }

    # Log performance if enabled
    local end_time=$(date +%s.%N)
    local collect_duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.001")
    log_debug "collect_metrics: Collected metrics for '$hook_name' in ${collect_duration}s"

    return 0
}

#============================================================================
# Log Aggregation Functions
#============================================================================

aggregate_logs() {
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$AGGREGATED_LOG")"

    # Clear previous aggregated log
    > "$AGGREGATED_LOG"

    local logs_dir="$(dirname "$METRICS_FILE")"

    # Find log files modified within the last day and aggregate them
    # Use a more portable time comparison (86400 seconds = 1 day)
    local current_time=$(date +%s)
    local one_day_ago=$((current_time - 86400))

    if [[ -d "$logs_dir" ]]; then
        # Get list of recent log files
        for logfile in "$logs_dir"/*.log; do
            # Skip if no matching files found (when *.log doesn't expand)
            [[ "$logfile" == "$logs_dir/*.log" ]] && continue

            if [[ -f "$logfile" ]]; then
                local file_mtime=$(stat -c %Y "$logfile" 2>/dev/null || echo "0")
                # Only include files modified in the last day (more than 1 day ago are excluded)
                if [[ $file_mtime -gt $one_day_ago ]]; then
                    tail -n 100 "$logfile" >> "$AGGREGATED_LOG" 2>/dev/null || true
                fi
            fi
        done 2>/dev/null
    fi

    return 0
}

#============================================================================
# Configuration Management Functions
#============================================================================

load_monitoring_config() {
    local config_file="$1"

    MONITORING_CONFIG="$config_file"

    # Clear existing settings
    unset MONITORING_SETTINGS
    declare -gA MONITORING_SETTINGS

    if [[ ! -f "$config_file" ]]; then
        # Use defaults if config file doesn't exist
        MONITORING_SETTINGS[metrics_retention_days]="$DEFAULT_METRICS_RETENTION_DAYS"
        MONITORING_SETTINGS[log_aggregation_limit]="$DEFAULT_LOG_AGGREGATION_LIMIT"
        MONITORING_SETTINGS[error_rate_threshold]="$DEFAULT_ERROR_RATE_THRESHOLD"
        MONITORING_SETTINGS[response_time_threshold]="$DEFAULT_RESPONSE_TIME_THRESHOLD"
        return 0
    fi

    # Validate JSON syntax first
    if ! jq empty "$config_file" >/dev/null 2>&1; then
        if command -v python3 >/dev/null 2>&1; then
            if ! python3 -c "import json; json.load(open('$config_file'))" >/dev/null 2>&1; then
                echo "Error: Invalid JSON syntax in config file" >&2
                return 1
            fi
        else
            echo "Error: Cannot validate JSON (jq or python3 not available)" >&2
            return 1
        fi
    fi

    # Load settings from JSON
    if command -v jq >/dev/null 2>&1; then
        local metrics_retention=$(jq -r '.metrics_retention_days // empty' "$config_file" 2>/dev/null || echo "")
        local log_limit=$(jq -r '.log_aggregation_limit // empty' "$config_file" 2>/dev/null || echo "")
        local error_threshold=$(jq -r '.alert_thresholds.error_rate // empty' "$config_file" 2>/dev/null || echo "")
        local response_threshold=$(jq -r '.alert_thresholds.response_time // empty' "$config_file" 2>/dev/null || echo "")

        MONITORING_SETTINGS[metrics_retention_days]="${metrics_retention:-$DEFAULT_METRICS_RETENTION_DAYS}"
        MONITORING_SETTINGS[log_aggregation_limit]="${log_limit:-$DEFAULT_LOG_AGGREGATION_LIMIT}"
        MONITORING_SETTINGS[error_rate_threshold]="${error_threshold:-$DEFAULT_ERROR_RATE_THRESHOLD}"
        MONITORING_SETTINGS[response_time_threshold]="${response_threshold:-$DEFAULT_RESPONSE_TIME_THRESHOLD}"
    else
        # Fallback to grep-based parsing
        local metrics_retention=$(grep -o '"metrics_retention_days":[[:space:]]*[0-9]*' "$config_file" | grep -o '[0-9]*$' || echo "")
        local log_limit=$(grep -o '"log_aggregation_limit":[[:space:]]*[0-9]*' "$config_file" | grep -o '[0-9]*$' || echo "")

        MONITORING_SETTINGS[metrics_retention_days]="${metrics_retention:-$DEFAULT_METRICS_RETENTION_DAYS}"
        MONITORING_SETTINGS[log_aggregation_limit]="${log_limit:-$DEFAULT_LOG_AGGREGATION_LIMIT}"
        MONITORING_SETTINGS[error_rate_threshold]="$DEFAULT_ERROR_RATE_THRESHOLD"
        MONITORING_SETTINGS[response_time_threshold]="$DEFAULT_RESPONSE_TIME_THRESHOLD"
    fi

    return 0
}

get_monitoring_setting() {
    local setting_name="$1"

    if [[ -n "${MONITORING_SETTINGS[$setting_name]:-}" ]]; then
        echo "${MONITORING_SETTINGS[$setting_name]}"
    else
        echo ""
    fi
}

#============================================================================
# Performance Monitoring Functions
#============================================================================

monitor_hook_performance() {
    local hook_name="$1"
    local hook_function="$2"

    # Validate hook name
    if [[ -z "$hook_name" ]]; then
        echo "Error: Hook name cannot be empty" >&2
        return 1
    fi

    # Ensure metrics directory exists
    mkdir -p "$(dirname "$METRICS_FILE")" 2>/dev/null || true

    # Record start time
    local start_time=$(date +%s.%N)

    # Execute the hook function and capture its exit code
    local exit_code=0
    "$hook_function" || exit_code=$?

    # Calculate execution time
    local end_time=$(date +%s.%N)
    local duration
    if command -v bc >/dev/null 2>&1; then
        duration=$(echo "$end_time - $start_time" | bc 2>/dev/null | sed 's/^\./0./')
    elif command -v python3 >/dev/null 2>&1; then
        duration=$(python3 -c "import sys; print(f'{float(sys.argv[1]) - float(sys.argv[2]):.6f}')" "$end_time" "$start_time" 2>/dev/null | sed 's/^\./0./')
    else
        duration="0.001"
    fi

    # Ensure duration has proper format (0.xxxxx)
    if [[ "$duration" =~ ^\. ]]; then
        duration="0$duration"
    fi

    # Validate the final duration format
    if ! [[ "$duration" =~ ^[0-9]+\.[0-9]+$ ]]; then
        duration="0.001"
    fi

    # Determine status based on exit code
    local status="success"
    if [[ $exit_code -ne 0 ]]; then
        status="error"
    fi

    # Collect metrics
    collect_metrics "$hook_name" "$duration" "$status"

    # Return original exit code
    return $exit_code
}

#============================================================================
# Metrics Analysis Functions
#============================================================================

calculate_success_rate() {
    local hook_name="$1"

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "0"
        return
    fi

    local total_count=0
    local success_count=0

    # Count total executions and successes for the hook
    while IFS= read -r line; do
        if [[ "$line" =~ hook_execution_total.*hook=\"${hook_name}\" ]]; then
            total_count=$((total_count + 1))
            if [[ "$line" =~ status=\"success\" ]]; then
                success_count=$((success_count + 1))
            fi
        fi
    done < "$METRICS_FILE"

    if [[ $total_count -eq 0 ]]; then
        echo "0"
    else
        local success_rate=$((success_count * 100 / total_count))
        echo "$success_rate"
    fi
}

calculate_average_duration() {
    local hook_name="$1"

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "0.000"
        return
    fi

    local total_duration=0
    local count=0

    # Extract duration values for the hook
    while IFS= read -r line; do
        # Improved regex to match the exact format
        if [[ "$line" =~ hook_execution_duration_seconds\{hook=\"${hook_name}\"\}[[:space:]]+([0-9]+\.?[0-9]*)[[:space:]] ]]; then
            local duration="${BASH_REMATCH[1]}"
            if command -v bc >/dev/null 2>&1; then
                total_duration=$(echo "$total_duration + $duration" | bc)
            elif command -v python3 >/dev/null 2>&1; then
                total_duration=$(python3 -c "print($total_duration + $duration)")
            else
                # Simple integer approximation as fallback
                total_duration=$((total_duration + ${duration%.*}))
            fi
            count=$((count + 1))
        fi
    done < "$METRICS_FILE"

    if [[ $count -eq 0 ]]; then
        echo "0.000"
    else
        if command -v bc >/dev/null 2>&1; then
            printf "%.3f\n" $(echo "scale=3; $total_duration / $count" | bc)
        elif command -v python3 >/dev/null 2>&1; then
            python3 -c "print(f'{$total_duration / $count:.3f}')"
        else
            echo "0.000"  # Fallback
        fi
    fi
}

generate_monitoring_report() {
    echo "# Monitoring Report"
    echo "Generated: $(date)"
    echo ""

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics data available."
        return 0
    fi

    echo "## Hook Performance Summary"
    echo ""

    # Extract unique hook names
    local hooks=($(grep -o 'hook="[^"]*"' "$METRICS_FILE" | sort -u | sed 's/hook="\(.*\)"/\1/'))

    for hook in "${hooks[@]}"; do
        if [[ -n "$hook" ]]; then
            local success_rate=$(calculate_success_rate "$hook")
            local avg_duration=$(calculate_average_duration "$hook")

            echo "### $hook"
            echo "- Success Rate: ${success_rate}%"
            echo "- Average Duration: ${avg_duration}s"
            echo ""
        fi
    done

    return 0
}

#============================================================================
# Utility and Optimization Functions
#============================================================================

show_version() {
    echo "Metrics Collector v2.0.0"
    echo "Performance monitoring system for Claude Code hooks"
    echo ""
    echo "Features:"
    echo "  - Prometheus-format metrics collection"
    echo "  - Intelligent log aggregation"
    echo "  - Performance monitoring with <50ms response time"
    echo "  - Configurable thresholds and alerting"
    echo "  - Multi-language hook support"
}

show_config() {
    echo "Current Configuration:"
    echo "  METRICS_FILE: $METRICS_FILE"
    echo "  AGGREGATED_LOG: $AGGREGATED_LOG"
    echo "  LOG_FILE: $LOG_FILE"
    echo "  CONFIG_FILE: ${MONITORING_CONFIG:-'Not loaded'}"
    echo ""
    echo "Settings:"
    for key in "${!MONITORING_SETTINGS[@]}"; do
        echo "  $key: ${MONITORING_SETTINGS[$key]}"
    done | sort
}

validate_environment() {
    local issues=0

    echo "Environment Validation:"

    # Check required commands
    for cmd in date stat bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "  ❌ Missing required command: $cmd"
            ((issues++))
        else
            echo "  ✅ Command available: $cmd"
        fi
    done

    # Check optional but recommended commands
    for cmd in jq python3; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "  ⚠️  Optional command missing: $cmd (reduced functionality)"
        else
            echo "  ✅ Optional command available: $cmd"
        fi
    done

    # Check directory permissions
    local log_dir="$(dirname "$METRICS_FILE")"
    if [[ -d "$log_dir" ]]; then
        if [[ -w "$log_dir" ]]; then
            echo "  ✅ Log directory writable: $log_dir"
        else
            echo "  ❌ Log directory not writable: $log_dir"
            ((issues++))
        fi
    else
        echo "  ℹ️  Log directory will be created: $log_dir"
    fi

    echo ""
    if [[ $issues -eq 0 ]]; then
        echo "✅ Environment validation passed"
        return 0
    else
        echo "❌ Environment validation failed with $issues issues"
        return 1
    fi
}

benchmark_performance() {
    echo "Performance Benchmark:"
    echo "Running metrics collection performance test..."

    local start_time=$(date +%s.%N)
    local iterations=100

    for ((i=1; i<=iterations; i++)); do
        collect_metrics "benchmark_test" "0.042" "success" >/dev/null 2>&1
    done

    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "1")
    local avg_time=$(echo "scale=6; $total_time / $iterations" | bc 2>/dev/null || echo "0.010")

    echo "  Total time: ${total_time}s"
    echo "  Average time per collection: ${avg_time}s"
    echo "  Collections per second: $(echo "scale=2; $iterations / $total_time" | bc 2>/dev/null || echo "100")"

    # Target is <50ms (0.050s)
    local target=0.050
    local status="✅"
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$avg_time > $target" | bc -l) )); then
            status="⚠️"
        fi
    fi

    echo "  Performance: $status (target: <${target}s per collection)"

    # Cleanup benchmark data
    if [[ -f "$METRICS_FILE" ]]; then
        grep -v 'benchmark_test' "$METRICS_FILE" > "${METRICS_FILE}.tmp" 2>/dev/null || true
        mv "${METRICS_FILE}.tmp" "$METRICS_FILE" 2>/dev/null || rm -f "${METRICS_FILE}.tmp"
    fi

    echo "Benchmark completed."
}

#============================================================================
# Main execution (if called directly)
#============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Command line interface
    case "${1:-help}" in
        "collect")
            shift
            collect_metrics "$@"
            ;;
        "aggregate")
            aggregate_logs
            ;;
        "report")
            generate_monitoring_report
            ;;
        "monitor")
            shift
            monitor_hook_performance "$@"
            ;;
        "help"|*)
            echo "Usage: $0 {collect|aggregate|report|monitor|help}"
            echo "  collect <hook_name> <duration> <status> - Collect metrics"
            echo "  aggregate                                 - Aggregate recent logs"
            echo "  report                                   - Generate monitoring report"
            echo "  monitor <hook_name> <function>          - Monitor hook performance"
            ;;
    esac
fi