#!/bin/bash

# Enhanced Hook Performance Tracking System
# Integrates with existing hook system to provide detailed performance metrics
# Follows 2025 observability best practices

# Performance tracking configuration
HOOK_METRICS_DIR="${HOME}/.claude/metrics"
HOOK_PERFORMANCE_LOG="${HOOK_METRICS_DIR}/hook-performance.jsonl"
HOOK_ALERTS_LOG="${HOOK_METRICS_DIR}/hook-alerts.jsonl"

# Ensure metrics directory exists
mkdir -p "$HOOK_METRICS_DIR"

# Green computing tracking
ENERGY_BASELINE_FILE="${HOOK_METRICS_DIR}/energy-baseline.json"

# Performance thresholds (configurable)
HOOK_DURATION_WARNING_MS=5000    # 5 seconds
HOOK_DURATION_CRITICAL_MS=15000  # 15 seconds
MEMORY_USAGE_WARNING_MB=100      # 100 MB
ENERGY_EFFICIENCY_THRESHOLD=0.7  # 70% efficiency minimum

# Enhanced hook execution wrapper with comprehensive tracking
track_hook_execution() {
    local hook_name="$1"
    local operation="$2"
    local hook_command="$3"
    shift 3
    local hook_args=("$@")

    # Generate unique execution ID
    local execution_id=$(uuidgen 2>/dev/null || echo "$(date +%s)-$$")

    # Start time and resource measurement
    local start_time=$(date +%s.%3N)
    local start_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Get initial resource snapshot
    local start_memory_kb=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
    local start_cpu_times=$(cat /proc/$$/stat 2>/dev/null | awk '{print $14+$15}' || echo 0)

    # System load before execution
    local load_before=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')

    # Execute the hook with error handling
    local exit_code=0
    local error_output=""
    local hook_output=""

    # Create temporary files for output capture
    local stdout_file=$(mktemp)
    local stderr_file=$(mktemp)

    # Execute hook command
    if [[ -n "$hook_command" ]]; then
        timeout 60 bash -c "$hook_command" "${hook_args[@]}" >"$stdout_file" 2>"$stderr_file"
        exit_code=$?
        hook_output=$(cat "$stdout_file" 2>/dev/null)
        error_output=$(cat "$stderr_file" 2>/dev/null)
    else
        echo "ERROR: No hook command provided" >&2
        exit_code=1
        error_output="No hook command provided"
    fi

    # End time and resource measurement
    local end_time=$(date +%s.%3N)
    local end_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Calculate duration
    local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
    local duration_ms=$(echo "$duration * 1000" | bc 2>/dev/null || echo "0")

    # Get final resource snapshot
    local end_memory_kb=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
    local end_cpu_times=$(cat /proc/$$/stat 2>/dev/null | awk '{print $14+$15}' || echo 0)

    # System load after execution
    local load_after=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')

    # Calculate resource deltas
    local memory_delta_kb=$((end_memory_kb - start_memory_kb))
    local memory_delta_mb=$(echo "$memory_delta_kb / 1024" | bc 2>/dev/null || echo "0")
    local cpu_time_delta=$((end_cpu_times - start_cpu_times))

    # Calculate CPU usage percentage (approximation)
    local cpu_usage_percent=0
    if [[ $(echo "$duration > 0" | bc 2>/dev/null) -eq 1 ]]; then
        cpu_usage_percent=$(echo "scale=2; $cpu_time_delta / $duration" | bc 2>/dev/null || echo "0")
    fi

    # Green computing metrics
    local energy_consumption_wh=$(calculate_energy_consumption "$duration" "$cpu_usage_percent" "$memory_delta_mb")
    local carbon_footprint_g=$(calculate_carbon_footprint "$energy_consumption_wh")
    local efficiency_score=$(calculate_efficiency_score "$hook_name" "$energy_consumption_wh")

    # Determine success status
    local success="true"
    local severity="info"
    if [[ $exit_code -ne 0 ]]; then
        success="false"
        severity="error"
    elif [[ $(echo "$duration_ms > $HOOK_DURATION_WARNING_MS" | bc 2>/dev/null) -eq 1 ]]; then
        severity="warning"
    fi

    # Create comprehensive metrics entry
    local metrics_entry=$(jq -nc \
        --arg execution_id "$execution_id" \
        --arg timestamp "$end_timestamp" \
        --arg hook_name "$hook_name" \
        --arg operation "$operation" \
        --arg duration_ms "$duration_ms" \
        --arg memory_delta_mb "$memory_delta_mb" \
        --arg cpu_usage_percent "$cpu_usage_percent" \
        --arg energy_wh "$energy_consumption_wh" \
        --arg carbon_g "$carbon_footprint_g" \
        --arg efficiency_score "$efficiency_score" \
        --arg success "$success" \
        --arg exit_code "$exit_code" \
        --arg severity "$severity" \
        --arg load_before "$load_before" \
        --arg load_after "$load_after" \
        --arg start_timestamp "$start_timestamp" \
        --arg hook_output "$hook_output" \
        --arg error_output "$error_output" \
        '{
            "timestamp": $timestamp,
            "execution_id": $execution_id,
            "metric_type": "hook_execution",
            "hook_name": $hook_name,
            "operation": $operation,
            "performance": {
                "duration_ms": ($duration_ms | tonumber),
                "memory_delta_mb": ($memory_delta_mb | tonumber),
                "cpu_usage_percent": ($cpu_usage_percent | tonumber),
                "load_before": ($load_before | tonumber),
                "load_after": ($load_after | tonumber)
            },
            "green_computing": {
                "energy_consumption_wh": ($energy_wh | tonumber),
                "carbon_footprint_g": ($carbon_g | tonumber),
                "efficiency_score": ($efficiency_score | tonumber)
            },
            "execution": {
                "success": ($success == "true"),
                "exit_code": ($exit_code | tonumber),
                "severity": $severity,
                "start_timestamp": $start_timestamp,
                "end_timestamp": $timestamp
            },
            "output": {
                "stdout_length": ($hook_output | length),
                "stderr_length": ($error_output | length),
                "has_errors": ($error_output | length > 0)
            },
            "context": {
                "pid": '$$',
                "project_root": "'$PWD'",
                "git_branch": "'$(git branch --show-current 2>/dev/null || echo "none")'",
                "git_commit": "'$(git rev-parse --short HEAD 2>/dev/null || echo "none")'"
            }
        }')

    # Write metrics to JSONL file
    if [[ -n "$metrics_entry" ]]; then
        echo "$metrics_entry" >> "$HOOK_PERFORMANCE_LOG"
    fi

    # Check for performance alerts
    check_performance_alerts "$hook_name" "$duration_ms" "$memory_delta_mb" "$efficiency_score" "$exit_code"

    # Update performance baselines
    update_performance_baseline "$hook_name" "$duration_ms" "$memory_delta_mb" "$efficiency_score"

    # Cleanup temporary files
    rm -f "$stdout_file" "$stderr_file"

    # Return original exit code
    return $exit_code
}

# Calculate energy consumption using simplified model
calculate_energy_consumption() {
    local duration="$1"
    local cpu_usage="$2"
    local memory_mb="$3"

    # Simplified energy model for development environment
    local base_power_w=20  # Base system power
    local cpu_power_w=$(echo "65 * ($cpu_usage / 100)" | bc -l 2>/dev/null || echo "10")
    local memory_power_w=$(echo "3 * ($memory_mb / 1024)" | bc -l 2>/dev/null || echo "1")

    local total_power_w=$(echo "$base_power_w + $cpu_power_w + $memory_power_w" | bc -l 2>/dev/null || echo "30")
    local energy_wh=$(echo "$total_power_w * ($duration / 3600)" | bc -l 2>/dev/null || echo "0.01")

    echo "$energy_wh"
}

# Calculate carbon footprint
calculate_carbon_footprint() {
    local energy_wh="$1"

    # Global average grid carbon intensity: ~475g CO2/kWh
    local grid_carbon_intensity=475
    local carbon_footprint_g=$(echo "$energy_wh * $grid_carbon_intensity / 1000" | bc -l 2>/dev/null || echo "0.01")

    echo "$carbon_footprint_g"
}

# Calculate efficiency score
calculate_efficiency_score() {
    local hook_name="$1"
    local energy_wh="$2"

    # Define baseline energy consumption for different hook types
    local baseline_energy="0.005"  # Default 5mWh

    case "$hook_name" in
        *"quality"*|*"lint"*)
            baseline_energy="0.010"  # Code quality checks
            ;;
        *"test"*)
            baseline_energy="0.015"  # Test execution
            ;;
        *"format"*)
            baseline_energy="0.003"  # Code formatting
            ;;
        *"security"*)
            baseline_energy="0.008"  # Security checks
            ;;
    esac

    local efficiency=$(echo "scale=4; $baseline_energy / ($energy_wh + 0.0001)" | bc -l 2>/dev/null || echo "1.0")
    local efficiency_capped=$(echo "if ($efficiency > 1.0) 1.0 else $efficiency" | bc -l 2>/dev/null || echo "1.0")

    echo "$efficiency_capped"
}

# Check for performance alerts
check_performance_alerts() {
    local hook_name="$1"
    local duration_ms="$2"
    local memory_mb="$3"
    local efficiency_score="$4"
    local exit_code="$5"

    local alert_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local alerts_generated=false

    # Duration-based alerts
    if [[ $(echo "$duration_ms > $HOOK_DURATION_CRITICAL_MS" | bc 2>/dev/null) -eq 1 ]]; then
        emit_alert "hook_performance_critical" "$hook_name" "critical" \
            "Hook execution time ($duration_ms ms) exceeds critical threshold ($HOOK_DURATION_CRITICAL_MS ms)" \
            '{"duration_ms": '"$duration_ms"', "threshold_ms": '"$HOOK_DURATION_CRITICAL_MS"'}'
        alerts_generated=true
    elif [[ $(echo "$duration_ms > $HOOK_DURATION_WARNING_MS" | bc 2>/dev/null) -eq 1 ]]; then
        emit_alert "hook_performance_warning" "$hook_name" "warning" \
            "Hook execution time ($duration_ms ms) exceeds warning threshold ($HOOK_DURATION_WARNING_MS ms)" \
            '{"duration_ms": '"$duration_ms"', "threshold_ms": '"$HOOK_DURATION_WARNING_MS"'}'
        alerts_generated=true
    fi

    # Memory-based alerts
    if [[ $(echo "$memory_mb > $MEMORY_USAGE_WARNING_MB" | bc 2>/dev/null) -eq 1 ]]; then
        emit_alert "hook_memory_usage_high" "$hook_name" "warning" \
            "Hook memory usage ($memory_mb MB) exceeds warning threshold ($MEMORY_USAGE_WARNING_MB MB)" \
            '{"memory_mb": '"$memory_mb"', "threshold_mb": '"$MEMORY_USAGE_WARNING_MB"'}'
        alerts_generated=true
    fi

    # Efficiency-based alerts
    if [[ $(echo "$efficiency_score < $ENERGY_EFFICIENCY_THRESHOLD" | bc 2>/dev/null) -eq 1 ]]; then
        emit_alert "hook_energy_efficiency_low" "$hook_name" "info" \
            "Hook energy efficiency ($efficiency_score) below threshold ($ENERGY_EFFICIENCY_THRESHOLD)" \
            '{"efficiency_score": '"$efficiency_score"', "threshold": '"$ENERGY_EFFICIENCY_THRESHOLD"'}'
        alerts_generated=true
    fi

    # Failure alerts
    if [[ $exit_code -ne 0 ]]; then
        emit_alert "hook_execution_failure" "$hook_name" "error" \
            "Hook execution failed with exit code $exit_code" \
            '{"exit_code": '"$exit_code"'}'
        alerts_generated=true
    fi

    return 0
}

# Emit alert to alerts log
emit_alert() {
    local alert_type="$1"
    local hook_name="$2"
    local severity="$3"
    local message="$4"
    local details="$5"

    local alert_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local alert_id=$(uuidgen 2>/dev/null || echo "$(date +%s)-$$")

    local alert_entry=$(jq -nc \
        --arg alert_id "$alert_id" \
        --arg timestamp "$alert_timestamp" \
        --arg alert_type "$alert_type" \
        --arg hook_name "$hook_name" \
        --arg severity "$severity" \
        --arg message "$message" \
        --argjson details "$details" \
        '{
            "alert_id": $alert_id,
            "timestamp": $timestamp,
            "alert_type": $alert_type,
            "hook_name": $hook_name,
            "severity": $severity,
            "message": $message,
            "details": $details,
            "source": "hook-performance-tracker",
            "context": {
                "project_root": "'$PWD'",
                "git_branch": "'$(git branch --show-current 2>/dev/null || echo "none")'",
                "git_commit": "'$(git rev-parse --short HEAD 2>/dev/null || echo "none")'"
            }
        }')

    echo "$alert_entry" >> "$HOOK_ALERTS_LOG"
}

# Update performance baseline for trend analysis
update_performance_baseline() {
    local hook_name="$1"
    local duration_ms="$2"
    local memory_mb="$3"
    local efficiency_score="$4"

    local baseline_file="${HOOK_METRICS_DIR}/baseline-${hook_name}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Load existing baseline or create new one
    local baseline_data="{}"
    if [[ -f "$baseline_file" ]]; then
        baseline_data=$(cat "$baseline_file" 2>/dev/null || echo "{}")
    fi

    # Update baseline with new data point
    local updated_baseline=$(echo "$baseline_data" | jq \
        --arg timestamp "$timestamp" \
        --arg duration_ms "$duration_ms" \
        --arg memory_mb "$memory_mb" \
        --arg efficiency_score "$efficiency_score" \
        '
        .hook_name = "'$hook_name'" |
        .last_updated = $timestamp |
        .execution_count = (.execution_count // 0) + 1 |
        .performance_history = (.performance_history // []) + [{
            "timestamp": $timestamp,
            "duration_ms": ($duration_ms | tonumber),
            "memory_mb": ($memory_mb | tonumber),
            "efficiency_score": ($efficiency_score | tonumber)
        }] |
        .performance_history = (.performance_history | sort_by(.timestamp) | .[-50:]) |
        .averages = {
            "duration_ms": (reduce .performance_history[] as $item (0; . + $item.duration_ms) / (.performance_history | length)),
            "memory_mb": (reduce .performance_history[] as $item (0; . + $item.memory_mb) / (.performance_history | length)),
            "efficiency_score": (reduce .performance_history[] as $item (0; . + $item.efficiency_score) / (.performance_history | length))
        }
        ')

    echo "$updated_baseline" > "$baseline_file"
}

# Analyze hook performance trends
analyze_hook_performance_trends() {
    local hook_name="$1"
    local baseline_file="${HOOK_METRICS_DIR}/baseline-${hook_name}.json"

    if [[ ! -f "$baseline_file" ]]; then
        echo "No baseline data available for hook: $hook_name"
        return 1
    fi

    local baseline_data=$(cat "$baseline_file")
    local execution_count=$(echo "$baseline_data" | jq -r '.execution_count // 0')

    if [[ $execution_count -lt 10 ]]; then
        echo "Insufficient data for trend analysis (need at least 10 executions, have $execution_count)"
        return 1
    fi

    echo "Performance Trend Analysis for Hook: $hook_name"
    echo "================================================"

    # Calculate trends
    local avg_duration=$(echo "$baseline_data" | jq -r '.averages.duration_ms // 0')
    local avg_memory=$(echo "$baseline_data" | jq -r '.averages.memory_mb // 0')
    local avg_efficiency=$(echo "$baseline_data" | jq -r '.averages.efficiency_score // 0')

    echo "Average Performance Metrics:"
    echo "  Duration: ${avg_duration} ms"
    echo "  Memory Usage: ${avg_memory} MB"
    echo "  Efficiency Score: ${avg_efficiency}"
    echo

    # Recent vs historical comparison
    local recent_data=$(echo "$baseline_data" | jq '.performance_history[-5:]')
    local recent_avg_duration=$(echo "$recent_data" | jq 'reduce .[] as $item (0; . + $item.duration_ms) / length')
    local recent_avg_efficiency=$(echo "$recent_data" | jq 'reduce .[] as $item (0; . + $item.efficiency_score) / length')

    echo "Recent Trend (last 5 executions):"
    echo "  Recent Duration: ${recent_avg_duration} ms"
    echo "  Recent Efficiency: ${recent_avg_efficiency}"

    # Performance change indicators
    local duration_change=$(echo "scale=2; ($recent_avg_duration - $avg_duration) / $avg_duration * 100" | bc -l 2>/dev/null || echo "0")
    local efficiency_change=$(echo "scale=2; ($recent_avg_efficiency - $avg_efficiency) / $avg_efficiency * 100" | bc -l 2>/dev/null || echo "0")

    echo "  Duration Change: ${duration_change}%"
    echo "  Efficiency Change: ${efficiency_change}%"

    # Recommendations based on trends
    if [[ $(echo "$duration_change > 20" | bc 2>/dev/null) -eq 1 ]]; then
        echo
        echo "⚠️  RECOMMENDATION: Hook performance has degraded significantly (+${duration_change}%)"
        echo "   Consider reviewing recent changes or optimizing hook implementation"
    elif [[ $(echo "$efficiency_change < -20" | bc 2>/dev/null) -eq 1 ]]; then
        echo
        echo "⚠️  RECOMMENDATION: Energy efficiency has decreased significantly (${efficiency_change}%)"
        echo "   Consider optimizing for resource usage"
    elif [[ $(echo "$duration_change < -10" | bc 2>/dev/null) -eq 1 ]]; then
        echo
        echo "✅ GOOD: Hook performance has improved (${duration_change}%)"
    fi
}

# Generate performance report
generate_hook_performance_report() {
    local output_file="${1:-${HOOK_METRICS_DIR}/performance-report-$(date +%Y%m%d).json}"
    local report_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    echo "Generating hook performance report..."

    # Collect data from all baseline files
    local all_hooks=()
    for baseline_file in "${HOOK_METRICS_DIR}"/baseline-*.json; do
        if [[ -f "$baseline_file" ]]; then
            local hook_name=$(basename "$baseline_file" .json | sed 's/baseline-//')
            all_hooks+=("$hook_name")
        fi
    done

    # Build report JSON
    local report_data=$(jq -n \
        --arg timestamp "$report_timestamp" \
        --argjson hooks "$(printf '%s\n' "${all_hooks[@]}" | jq -R . | jq -s .)" \
        '{
            "report_timestamp": $timestamp,
            "report_type": "hook_performance_summary",
            "hooks": [],
            "summary": {
                "total_hooks": ($hooks | length),
                "analysis_period": "last_50_executions"
            }
        }')

    # Add data for each hook
    for hook_name in "${all_hooks[@]}"; do
        local baseline_file="${HOOK_METRICS_DIR}/baseline-${hook_name}.json"
        local hook_data=$(cat "$baseline_file")

        report_data=$(echo "$report_data" | jq \
            --argjson hook_data "$hook_data" \
            '.hooks += [$hook_data]')
    done

    # Calculate overall statistics
    report_data=$(echo "$report_data" | jq '
        .summary.overall_stats = {
            "avg_duration_ms": (reduce .hooks[] as $hook (0; . + $hook.averages.duration_ms) / (.hooks | length)),
            "avg_efficiency": (reduce .hooks[] as $hook (0; . + $hook.averages.efficiency_score) / (.hooks | length)),
            "total_executions": (reduce .hooks[] as $hook (0; . + $hook.execution_count))
        }')

    echo "$report_data" > "$output_file"
    echo "Performance report generated: $output_file"

    # Print summary
    echo
    echo "Performance Report Summary"
    echo "========================="
    local avg_duration=$(echo "$report_data" | jq -r '.summary.overall_stats.avg_duration_ms')
    local avg_efficiency=$(echo "$report_data" | jq -r '.summary.overall_stats.avg_efficiency')
    local total_executions=$(echo "$report_data" | jq -r '.summary.overall_stats.total_executions')

    echo "Total Hooks Analyzed: ${#all_hooks[@]}"
    echo "Total Executions: $total_executions"
    echo "Average Duration: ${avg_duration} ms"
    echo "Average Efficiency: ${avg_efficiency}"
}

# Main execution when script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "track")
            track_hook_execution "$2" "$3" "$4" "${@:5}"
            ;;
        "analyze")
            analyze_hook_performance_trends "$2"
            ;;
        "report")
            generate_hook_performance_report "$2"
            ;;
        "help"|*)
            echo "Enhanced Hook Performance Tracking System"
            echo
            echo "Usage:"
            echo "  $0 track <hook_name> <operation> <command> [args...]"
            echo "  $0 analyze <hook_name>"
            echo "  $0 report [output_file]"
            echo
            echo "Examples:"
            echo "  $0 track pre-commit lint 'npm run lint'"
            echo "  $0 analyze pre-commit"
            echo "  $0 report /tmp/hook-report.json"
            ;;
    esac
fi
