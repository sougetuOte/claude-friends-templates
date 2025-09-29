#!/bin/bash
#
# Comprehensive Performance Test Suite
# =====================================
#
# This script performs comprehensive performance testing of the Claude Code hooks system
# following TDD principles and generating detailed reports with bottleneck analysis.
#
# Author: Claude Code Refactoring Specialist
# Version: 2.0.0
# Last Modified: $(date '+%Y-%m-%d')
#
# Usage:
#   ./comprehensive-performance-test.sh [OPTIONS]
#
# Options:
#   -c, --config FILE    Use custom configuration file
#   -o, --output DIR     Output directory for reports (default: /tmp)
#   -f, --format FORMAT  Report format: json, markdown, both (default: both)
#   -v, --verbose        Enable verbose output
#   -h, --help          Show this help message
#
# Exit Codes:
#   0 - All tests passed
#   1 - Some tests failed
#   2 - Configuration error
#   3 - Environment error

set -euo pipefail

# ============================================================================
# GLOBAL CONFIGURATION AND CONSTANTS
# ============================================================================

# Script metadata
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color constants for output formatting
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_NC='\033[0m'  # No Color

# Default configuration
readonly DEFAULT_CONFIG_FILE="$SCRIPT_DIR/performance-test.conf"
readonly DEFAULT_OUTPUT_DIR="/tmp"
readonly DEFAULT_REPORT_FORMAT="both"

# Test environment setup
readonly HOOKS_BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR=""
CLAUDE_PROJECT_DIR=""

# Configuration variables (will be loaded from config file)
TARGET_RESPONSE_TIME_MS=100
TARGET_RESPONSE_TIME_P95_MS=100
TARGET_RESPONSE_TIME_WARMUP_RUNS=3
TARGET_RESPONSE_TIME_TEST_RUNS=10
TARGET_MEMORY_MB=50
TARGET_PARALLEL_COUNT=10
TARGET_PARALLEL_TIMEOUT_SECONDS=10
PROFILE_MIN_DURATION_MS=1.0
PROFILE_TOP_OPERATIONS=5
REPORT_FORMAT="both"
REPORT_INCLUDE_CHARTS=true
REPORT_SAVE_TIMESTAMPED=true
TEST_PROMPT='{"prompt": "/agent:planner test performance"}'

# Command line options
CONFIG_FILE="$DEFAULT_CONFIG_FILE"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
VERBOSE=false

# Test results storage
declare -A TEST_RESULTS
declare -a RESPONSE_TIMES
declare -a BOTTLENECKS
TIMESTAMP=""
REPORT_FILE=""
JSON_REPORT_FILE=""

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

#
# Print colored output message
# Arguments:
#   $1: Color constant (e.g., COLOR_RED)
#   $2: Message to print
# Returns: None
#
print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${COLOR_NC}"
}

#
# Print info message
# Arguments: $1: Message
# Returns: None
#
print_info() {
    print_colored "$COLOR_BLUE" "ℹ $1"
}

#
# Print success message
# Arguments: $1: Message
# Returns: None
#
print_success() {
    print_colored "$COLOR_GREEN" "✓ $1"
}

#
# Print warning message
# Arguments: $1: Message
# Returns: None
#
print_warning() {
    print_colored "$COLOR_YELLOW" "⚠ $1"
}

#
# Print error message
# Arguments: $1: Message
# Returns: None
#
print_error() {
    print_colored "$COLOR_RED" "✗ $1"
}

#
# Print verbose message (only if verbose mode is enabled)
# Arguments: $1: Message
# Returns: None
#
print_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        print_colored "$COLOR_CYAN" "🔍 $1"
    fi
}

#
# Print section header
# Arguments: $1: Section title
# Returns: None
#
print_section() {
    local title="$1"
    echo
    print_colored "$COLOR_PURPLE" "=== $title ==="
    echo
}

#
# Print test header
# Arguments:
#   $1: Test number
#   $2: Test name
#   $3: Test target/description
# Returns: None
#
print_test_header() {
    local test_num="$1"
    local test_name="$2"
    local test_target="$3"

    echo
    print_colored "$COLOR_YELLOW" "Test $test_num: $test_name"
    echo "Target: $test_target"
    echo "----------------------------------------"
}

#
# Convert nanoseconds to milliseconds with precision
# Arguments: $1: Nanoseconds value
# Returns: Milliseconds value (printed to stdout)
#
ns_to_ms() {
    local ns="$1"
    echo "scale=3; $ns / 1000000" | bc -l
}

#
# Calculate percentile from array of values
# Arguments:
#   $1: Percentile (e.g., 95 for P95)
#   $@: Array of values
# Returns: Percentile value (printed to stdout)
#
calculate_percentile() {
    local percentile="$1"
    shift
    local values=("$@")

    if [[ ${#values[@]} -eq 0 ]]; then
        echo "0"
        return
    fi

    local sorted=($(printf '%s\n' "${values[@]}" | sort -n))
    local count=${#sorted[@]}
    local index=$(( (count * percentile / 100) - 1 ))

    [[ $index -lt 0 ]] && index=0
    [[ $index -ge $count ]] && index=$((count - 1))

    echo "${sorted[$index]}"
}

#
# Calculate average from array of values
# Arguments: $@: Array of values
# Returns: Average value (printed to stdout)
#
calculate_average() {
    local values=("$@")
    local count=${#values[@]}

    if [[ $count -eq 0 ]]; then
        echo "0"
        return
    fi

    local sum=0
    for value in "${values[@]}"; do
        sum=$((sum + value))
    done

    echo $((sum / count))
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

#
# Load configuration from file
# Arguments: $1: Configuration file path
# Returns: 0 on success, 1 on error
#
load_configuration() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi

    print_verbose "Loading configuration from: $config_file"

    # Source the configuration file safely
    if ! source "$config_file" 2>/dev/null; then
        print_error "Failed to load configuration file: $config_file"
        return 1
    fi

    print_verbose "Configuration loaded successfully"
    return 0
}

#
# Validate configuration values
# Arguments: None
# Returns: 0 if valid, 1 if invalid
#
validate_configuration() {
    local errors=0

    # Validate numeric targets
    if ! [[ "$TARGET_RESPONSE_TIME_MS" =~ ^[0-9]+$ ]] || [[ "$TARGET_RESPONSE_TIME_MS" -le 0 ]]; then
        print_error "Invalid TARGET_RESPONSE_TIME_MS: $TARGET_RESPONSE_TIME_MS (must be positive integer)"
        ((errors++))
    fi

    if ! [[ "$TARGET_MEMORY_MB" =~ ^[0-9]+$ ]] || [[ "$TARGET_MEMORY_MB" -le 0 ]]; then
        print_error "Invalid TARGET_MEMORY_MB: $TARGET_MEMORY_MB (must be positive integer)"
        ((errors++))
    fi

    if ! [[ "$TARGET_PARALLEL_COUNT" =~ ^[0-9]+$ ]] || [[ "$TARGET_PARALLEL_COUNT" -le 0 ]]; then
        print_error "Invalid TARGET_PARALLEL_COUNT: $TARGET_PARALLEL_COUNT (must be positive integer)"
        ((errors++))
    fi

    # Validate report format
    if [[ ! "$REPORT_FORMAT" =~ ^(json|markdown|both)$ ]]; then
        print_error "Invalid REPORT_FORMAT: $REPORT_FORMAT (must be json, markdown, or both)"
        ((errors++))
    fi

    return $errors
}

# ============================================================================
# ENVIRONMENT SETUP AND CLEANUP
# ============================================================================

#
# Setup test environment
# Arguments: None
# Returns: 0 on success, 1 on error
#
setup_test_environment() {
    print_verbose "Setting up test environment..."

    # Create temporary test directory
    TEST_DIR=$(mktemp -d -t "claude-perf-test-XXXXXX")
    export CLAUDE_PROJECT_DIR="$TEST_DIR"

    # Create necessary directory structure
    mkdir -p "$TEST_DIR/.claude/agents"
    echo '{"agent": "none"}' > "$TEST_DIR/.claude/agents/active.json"

    # Set up report file paths
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

    if [[ "$REPORT_SAVE_TIMESTAMPED" == "true" ]]; then
        local base_name="performance_report_${TIMESTAMP}"
    else
        local base_name="performance_report"
    fi

    JSON_REPORT_FILE="$OUTPUT_DIR/${base_name}.json"
    REPORT_FILE="$OUTPUT_DIR/${base_name}.md"

    print_verbose "Test directory: $TEST_DIR"
    print_verbose "JSON report: $JSON_REPORT_FILE"
    print_verbose "Markdown report: $REPORT_FILE"

    return 0
}

#
# Cleanup test environment
# Arguments: None
# Returns: None
#
cleanup_test_environment() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        print_verbose "Cleaning up test directory: $TEST_DIR"
        rm -rf "$TEST_DIR"
    fi
}

# Set up cleanup trap
trap cleanup_test_environment EXIT

# ============================================================================
# TEST EXECUTION FUNCTIONS
# ============================================================================

#
# Execute response time performance test
# Arguments: None
# Returns: 0 if test passes, 1 if test fails
#
test_response_time() {
    print_test_header "1" "Response Time Measurement" "P95 < ${TARGET_RESPONSE_TIME_MS}ms"

    # Warm-up runs
    print_info "Performing $TARGET_RESPONSE_TIME_WARMUP_RUNS warm-up runs..."
    for i in $(seq 1 "$TARGET_RESPONSE_TIME_WARMUP_RUNS"); do
        print_verbose "Warm-up run $i"
        echo "$TEST_PROMPT" | "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" >/dev/null 2>&1 || true
    done

    # Measure response times
    print_info "Measuring response times ($TARGET_RESPONSE_TIME_TEST_RUNS runs)..."
    RESPONSE_TIMES=()

    for i in $(seq 1 "$TARGET_RESPONSE_TIME_TEST_RUNS"); do
        local start_time=$(date +%s%N)
        echo "$TEST_PROMPT" | "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" >/dev/null 2>&1 || true
        local end_time=$(date +%s%N)

        local duration_ns=$((end_time - start_time))
        local duration_ms=$(ns_to_ms "$duration_ns")
        RESPONSE_TIMES+=("$duration_ns")

        print_verbose "Run $i: ${duration_ms}ms"
    done

    # Calculate statistics
    local p95=$(calculate_percentile 95 "${RESPONSE_TIMES[@]}")
    local p95_ms=$(ns_to_ms "$p95")
    local avg=$(calculate_average "${RESPONSE_TIMES[@]}")
    local avg_ms=$(ns_to_ms "$avg")

    echo "Results:"
    echo "  Average: ${avg_ms}ms"
    echo "  P95: ${p95_ms}ms"

    # Store results
    TEST_RESULTS[response_time_avg_ms]="$avg_ms"
    TEST_RESULTS[response_time_p95_ms]="$p95_ms"
    TEST_RESULTS[response_time_target_ms]="$TARGET_RESPONSE_TIME_MS"

    # Evaluate test result
    if (( $(echo "$p95_ms > $TARGET_RESPONSE_TIME_MS" | bc -l) )); then
        print_error "FAIL: P95 (${p95_ms}ms) exceeds target (${TARGET_RESPONSE_TIME_MS}ms)"
        TEST_RESULTS[response_time_passed]="false"
        return 1
    else
        print_success "PASS: P95 (${p95_ms}ms) within target (${TARGET_RESPONSE_TIME_MS}ms)"
        TEST_RESULTS[response_time_passed]="true"
        return 0
    fi
}

#
# Execute parallel execution performance test
# Arguments: None
# Returns: 0 if test passes, 1 if test fails
#
test_parallel_execution() {
    print_test_header "2" "Parallel Execution Test" "Handle $TARGET_PARALLEL_COUNT parallel executions without deadlock"

    # Start parallel executions
    print_info "Starting $TARGET_PARALLEL_COUNT parallel executions..."
    local pids=()
    local parallel_start=$(date +%s%N)

    for i in $(seq 1 "$TARGET_PARALLEL_COUNT"); do
        (echo "$TEST_PROMPT" | "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" >/dev/null 2>&1 || true) &
        pids+=("$!")
        print_verbose "Started process $i (PID: $!)"
    done

    # Wait for all processes with timeout
    local elapsed=0
    local all_done=false

    while [[ $elapsed -lt $TARGET_PARALLEL_TIMEOUT_SECONDS ]]; do
        local running=0
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                ((running++))
            fi
        done

        if [[ $running -eq 0 ]]; then
            all_done=true
            break
        fi

        sleep 0.1
        ((elapsed++))
    done

    local parallel_end=$(date +%s%N)
    local parallel_duration_ns=$((parallel_end - parallel_start))
    local parallel_duration_ms=$(ns_to_ms "$parallel_duration_ns")

    # Store results
    TEST_RESULTS[parallel_target_count]="$TARGET_PARALLEL_COUNT"
    TEST_RESULTS[parallel_duration_ms]="$parallel_duration_ms"
    TEST_RESULTS[parallel_completed]="$all_done"

    # Evaluate test result
    if [[ "$all_done" == "true" ]]; then
        print_success "PASS: All $TARGET_PARALLEL_COUNT processes completed successfully"
        echo "  Total time: ${parallel_duration_ms}ms"
        TEST_RESULTS[parallel_passed]="true"
        return 0
    else
        print_error "FAIL: Some processes did not complete (possible deadlock)"
        # Kill remaining processes
        for pid in "${pids[@]}"; do
            kill -9 "$pid" 2>/dev/null || true
        done
        TEST_RESULTS[parallel_passed]="false"
        return 1
    fi
}

#
# Execute memory usage performance test
# Arguments: None
# Returns: 0 if test passes, 1 if test fails
#
test_memory_usage() {
    print_test_header "3" "Memory Usage Measurement" "< ${TARGET_MEMORY_MB}MB"

    # Measure memory usage
    local memory_file="$TEST_DIR/memory.txt"
    /usr/bin/time -v "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < <(echo "$TEST_PROMPT") 2>&1 | \
        grep "Maximum resident" > "$memory_file" || true

    local memory_mb=0
    local test_passed=false

    if [[ -s "$memory_file" ]]; then
        local memory_kb=$(cat "$memory_file" | awk '{print $NF}')
        memory_mb=$((memory_kb / 1024))
        echo "Memory usage: ${memory_mb}MB"

        if [[ $memory_mb -lt $TARGET_MEMORY_MB ]]; then
            print_success "PASS: Memory usage (${memory_mb}MB) within target (${TARGET_MEMORY_MB}MB)"
            test_passed=true
        else
            print_error "FAIL: Memory usage (${memory_mb}MB) exceeds target (${TARGET_MEMORY_MB}MB)"
            test_passed=false
        fi
    else
        print_warning "WARNING: Could not measure memory usage"
        test_passed=false
    fi

    # Store results
    TEST_RESULTS[memory_usage_mb]="$memory_mb"
    TEST_RESULTS[memory_target_mb]="$TARGET_MEMORY_MB"
    TEST_RESULTS[memory_passed]="$test_passed"

    [[ "$test_passed" == "true" ]] && return 0 || return 1
}

#
# Execute bottleneck identification test with enhanced analysis
# Arguments: None
# Returns: 0 if test passes, 1 if test fails
#
test_bottleneck_identification() {
    print_test_header "4" "Bottleneck Identification (Enhanced Profiling)" "Identify performance bottlenecks and categorize them"

    local profile_log="$TEST_DIR/profile.log"

    # Run with detailed profiling
    print_info "Running profiling analysis..."
    PS4='+ $(date "+%s.%N") ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }' \
        bash -x "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < <(echo "$TEST_PROMPT") 2> "$profile_log" || true

    if [[ ! -f "$profile_log" ]]; then
        print_error "FAIL: Could not generate profile log"
        TEST_RESULTS[profiling_passed]="false"
        return 1
    fi

    print_success "Profile log generated successfully"

    # Enhanced bottleneck analysis
    print_info "Analyzing performance bottlenecks..."
    local bottleneck_file="$TEST_DIR/bottlenecks.txt"

    # Extract and categorize bottlenecks
    awk -v min_duration="$PROFILE_MIN_DURATION_MS" '
    /^\+/ {
        split($2, time, ":")
        if (prev_time != "") {
            duration = time[1] - prev_time
            duration_ms = duration * 1000
            if (duration_ms > min_duration) {
                operation = substr($0, index($0, $3))

                # Categorize bottlenecks
                category = "OTHER"
                if (operation ~ /jq|grep|awk|sed/) category = "DATA_PROCESSING"
                else if (operation ~ /read|write|stat|ls|find/) category = "IO"
                else if (operation ~ /sort|bc/) category = "CPU"
                else if (operation ~ /curl|wget|ssh/) category = "NETWORK"
                else if (operation ~ /sleep|wait/) category = "BLOCKING"

                printf "%.3f|%s|%s\n", duration_ms, category, operation
            }
        }
        prev_time = time[1]
        prev_line = substr($0, index($0, $3))
    }' "$profile_log" | sort -rn > "$bottleneck_file"

    # Display top bottlenecks by category
    if [[ -s "$bottleneck_file" ]]; then
        print_info "Top $PROFILE_TOP_OPERATIONS slowest operations by category:"

        # Group by category and show top operations
        for category in "IO" "DATA_PROCESSING" "CPU" "NETWORK" "BLOCKING" "OTHER"; do
            local category_ops=$(grep "^[^|]*|$category|" "$bottleneck_file" | head -3)
            if [[ -n "$category_ops" ]]; then
                echo
                print_colored "$COLOR_CYAN" "  $category:"
                while IFS='|' read -r duration_ms cat operation; do
                    printf "    %.3fms: %s\n" "$duration_ms" "$operation"
                done <<< "$category_ops"
            fi
        done

        # Generate recommendations
        echo
        print_info "Performance Recommendations:"
        generate_performance_recommendations "$bottleneck_file"

    else
        print_warning "No significant bottlenecks detected (all operations < ${PROFILE_MIN_DURATION_MS}ms)"
    fi

    # Store results
    TEST_RESULTS[profiling_passed]="true"
    TEST_RESULTS[profiling_log_path]="$profile_log"
    TEST_RESULTS[bottleneck_analysis_path]="$bottleneck_file"

    return 0
}

#
# Generate performance recommendations based on bottleneck analysis
# Arguments: $1: Bottleneck analysis file path
# Returns: None
#
generate_performance_recommendations() {
    local bottleneck_file="$1"

    # Analyze bottlenecks and provide recommendations
    local io_operations=$(grep -c "|IO|" "$bottleneck_file" 2>/dev/null || echo "0")
    local data_operations=$(grep -c "|DATA_PROCESSING|" "$bottleneck_file" 2>/dev/null || echo "0")
    local cpu_operations=$(grep -c "|CPU|" "$bottleneck_file" 2>/dev/null || echo "0")

    if [[ $io_operations -gt 2 ]]; then
        echo "  • Consider caching file operations or reducing filesystem calls"
        echo "  • Batch file operations where possible"
    fi

    if [[ $data_operations -gt 2 ]]; then
        echo "  • Optimize JSON processing with faster tools (e.g., jaq instead of jq)"
        echo "  • Consider pre-processing data to reduce runtime parsing"
    fi

    if [[ $cpu_operations -gt 1 ]]; then
        echo "  • Consider using built-in bash operations instead of external tools"
        echo "  • Optimize mathematical calculations"
    fi

    # Check for specific slow operations
    if grep -q "jq" "$bottleneck_file"; then
        echo "  • JSON processing detected as bottleneck - consider optimizing queries"
    fi

    if grep -q "stat" "$bottleneck_file"; then
        echo "  • File stat operations detected - consider reducing file validation calls"
    fi
}

# ============================================================================
# REPORT GENERATION FUNCTIONS
# ============================================================================

#
# Generate ASCII chart for response times
# Arguments: None
# Returns: Chart content (printed to stdout)
#
generate_response_time_chart() {
    if [[ ${#RESPONSE_TIMES[@]} -eq 0 ]]; then
        echo "No data available for chart generation"
        return
    fi

    echo "Response Time Distribution:"
    echo "```"

    # Convert to milliseconds and create simple histogram
    local max_ms=0
    local -a ms_values=()

    for ns in "${RESPONSE_TIMES[@]}"; do
        local ms=$(ns_to_ms "$ns")
        local ms_int=${ms%.*}  # Remove decimal part for binning
        ms_values+=("$ms_int")
        [[ $ms_int -gt $max_ms ]] && max_ms=$ms_int
    done

    # Create bins
    local bin_size=$((max_ms / 10 + 1))
    declare -A bins

    for ms in "${ms_values[@]}"; do
        local bin=$((ms / bin_size))
        bins[$bin]=$((${bins[$bin]:-0} + 1))
    done

    # Generate ASCII histogram
    local max_count=0
    for count in "${bins[@]}"; do
        [[ $count -gt $max_count ]] && max_count=$count
    done

    for i in $(seq 0 9); do
        local range_start=$((i * bin_size))
        local range_end=$(((i + 1) * bin_size - 1))
        local count=${bins[$i]:-0}
        local bar_length=$((count * 50 / max_count))

        printf "%3d-%3dms |" "$range_start" "$range_end"
        for j in $(seq 1 "$bar_length"); do
            printf "█"
        done
        printf " (%d)\n" "$count"
    done

    echo "```"
}

#
# Generate JSON report
# Arguments: None
# Returns: 0 on success, 1 on error
#
generate_json_report() {
    print_verbose "Generating JSON report: $JSON_REPORT_FILE"

    cat > "$JSON_REPORT_FILE" << EOF
{
  "metadata": {
    "timestamp": "$(date -Iseconds)",
    "version": "$SCRIPT_VERSION",
    "system": "$(uname -a)",
    "bash_version": "$BASH_VERSION",
    "test_environment": "$TEST_DIR"
  },
  "configuration": {
    "target_response_time_ms": $TARGET_RESPONSE_TIME_MS,
    "target_memory_mb": $TARGET_MEMORY_MB,
    "target_parallel_count": $TARGET_PARALLEL_COUNT,
    "profile_min_duration_ms": $PROFILE_MIN_DURATION_MS
  },
  "results": {
    "response_time": {
      "average_ms": ${TEST_RESULTS[response_time_avg_ms]:-0},
      "p95_ms": ${TEST_RESULTS[response_time_p95_ms]:-0},
      "target_ms": ${TEST_RESULTS[response_time_target_ms]:-0},
      "passed": ${TEST_RESULTS[response_time_passed]:-false}
    },
    "parallel_execution": {
      "target_count": ${TEST_RESULTS[parallel_target_count]:-0},
      "duration_ms": ${TEST_RESULTS[parallel_duration_ms]:-0},
      "completed": ${TEST_RESULTS[parallel_completed]:-false},
      "passed": ${TEST_RESULTS[parallel_passed]:-false}
    },
    "memory_usage": {
      "usage_mb": ${TEST_RESULTS[memory_usage_mb]:-0},
      "target_mb": ${TEST_RESULTS[memory_target_mb]:-0},
      "passed": ${TEST_RESULTS[memory_passed]:-false}
    },
    "profiling": {
      "log_generated": ${TEST_RESULTS[profiling_passed]:-false},
      "log_path": "${TEST_RESULTS[profiling_log_path]:-}",
      "bottleneck_analysis_path": "${TEST_RESULTS[bottleneck_analysis_path]:-}"
    }
  },
  "summary": {
    "all_tests_passed": $(all_tests_passed && echo "true" || echo "false"),
    "total_tests": 4,
    "passed_tests": $(count_passed_tests)
  }
}
EOF

    return 0
}

#
# Generate Markdown report with charts
# Arguments: None
# Returns: 0 on success, 1 on error
#
generate_markdown_report() {
    print_verbose "Generating Markdown report: $REPORT_FILE"

    cat > "$REPORT_FILE" << EOF
# Comprehensive Performance Test Report

**Generated:** $(date)
**Version:** $SCRIPT_VERSION
**System:** $(uname -a)
**Bash Version:** $BASH_VERSION

## Executive Summary

| Test | Target | Result | Status |
|------|--------|--------|--------|
| Response Time | P95 < ${TARGET_RESPONSE_TIME_MS}ms | P95 = ${TEST_RESULTS[response_time_p95_ms]:-0}ms | $(test_status_icon "${TEST_RESULTS[response_time_passed]:-false}") |
| Parallel Execution | ${TARGET_PARALLEL_COUNT} concurrent | ${TEST_RESULTS[parallel_target_count]:-0} processes | $(test_status_icon "${TEST_RESULTS[parallel_passed]:-false}") |
| Memory Usage | < ${TARGET_MEMORY_MB}MB | ${TEST_RESULTS[memory_usage_mb]:-0}MB | $(test_status_icon "${TEST_RESULTS[memory_passed]:-false}") |
| Profiling | Bottleneck Analysis | Analysis Complete | $(test_status_icon "${TEST_RESULTS[profiling_passed]:-false}") |

**Overall Status:** $(all_tests_passed && echo "✅ ALL TESTS PASSED" || echo "❌ SOME TESTS FAILED")

## Detailed Results

### 1. Response Time Analysis

- **Average Response Time:** ${TEST_RESULTS[response_time_avg_ms]:-0}ms
- **95th Percentile:** ${TEST_RESULTS[response_time_p95_ms]:-0}ms
- **Target:** < ${TARGET_RESPONSE_TIME_MS}ms
- **Status:** $(test_status_icon "${TEST_RESULTS[response_time_passed]:-false}")

$(if [[ "$REPORT_INCLUDE_CHARTS" == "true" ]]; then generate_response_time_chart; fi)

### 2. Parallel Execution Performance

- **Target Concurrent Processes:** ${TARGET_PARALLEL_COUNT}
- **Execution Time:** ${TEST_RESULTS[parallel_duration_ms]:-0}ms
- **Completion Status:** ${TEST_RESULTS[parallel_completed]:-false}
- **Status:** $(test_status_icon "${TEST_RESULTS[parallel_passed]:-false}")

### 3. Memory Usage Analysis

- **Peak Memory Usage:** ${TEST_RESULTS[memory_usage_mb]:-0}MB
- **Target:** < ${TARGET_MEMORY_MB}MB
- **Status:** $(test_status_icon "${TEST_RESULTS[memory_passed]:-false}")

### 4. Bottleneck Analysis

**Profile Log:** \`${TEST_RESULTS[profiling_log_path]:-N/A}\`
**Analysis File:** \`${TEST_RESULTS[bottleneck_analysis_path]:-N/A}\`

$(if [[ -f "${TEST_RESULTS[bottleneck_analysis_path]:-}" ]]; then
    echo "#### Top Performance Bottlenecks by Category"
    echo
    for category in "IO" "DATA_PROCESSING" "CPU" "NETWORK" "BLOCKING" "OTHER"; do
        local category_ops=$(grep "^[^|]*|$category|" "${TEST_RESULTS[bottleneck_analysis_path]}" 2>/dev/null | head -3)
        if [[ -n "$category_ops" ]]; then
            echo "##### $category Operations"
            echo
            while IFS='|' read -r duration_ms cat operation; do
                echo "- **${duration_ms}ms:** \`${operation}\`"
            done <<< "$category_ops"
            echo
        fi
    done
fi)

## Configuration Used

\`\`\`
Target Response Time: ${TARGET_RESPONSE_TIME_MS}ms
Target Memory Usage: ${TARGET_MEMORY_MB}MB
Parallel Execution Count: ${TARGET_PARALLEL_COUNT}
Profile Minimum Duration: ${PROFILE_MIN_DURATION_MS}ms
Test Runs: ${TARGET_RESPONSE_TIME_TEST_RUNS}
Warmup Runs: ${TARGET_RESPONSE_TIME_WARMUP_RUNS}
\`\`\`

## Performance Recommendations

EOF

    # Add recommendations if bottleneck analysis exists
    if [[ -f "${TEST_RESULTS[bottleneck_analysis_path]:-}" ]]; then
        generate_performance_recommendations "${TEST_RESULTS[bottleneck_analysis_path]}" >> "$REPORT_FILE"
    else
        echo "No specific recommendations available - all tests performed well." >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---
*Report generated by Claude Code Comprehensive Performance Test Suite v$SCRIPT_VERSION*
EOF

    return 0
}

#
# Get status icon for test result
# Arguments: $1: Test result (true/false)
# Returns: Status icon (printed to stdout)
#
test_status_icon() {
    local passed="$1"
    [[ "$passed" == "true" ]] && echo "✅ PASS" || echo "❌ FAIL"
}

#
# Check if all tests passed
# Arguments: None
# Returns: 0 if all passed, 1 if any failed
#
all_tests_passed() {
    [[ "${TEST_RESULTS[response_time_passed]:-false}" == "true" ]] && \
    [[ "${TEST_RESULTS[parallel_passed]:-false}" == "true" ]] && \
    [[ "${TEST_RESULTS[memory_passed]:-false}" == "true" ]] && \
    [[ "${TEST_RESULTS[profiling_passed]:-false}" == "true" ]]
}

#
# Count number of passed tests
# Arguments: None
# Returns: Number of passed tests (printed to stdout)
#
count_passed_tests() {
    local passed=0
    [[ "${TEST_RESULTS[response_time_passed]:-false}" == "true" ]] && ((passed++))
    [[ "${TEST_RESULTS[parallel_passed]:-false}" == "true" ]] && ((passed++))
    [[ "${TEST_RESULTS[memory_passed]:-false}" == "true" ]] && ((passed++))
    [[ "${TEST_RESULTS[profiling_passed]:-false}" == "true" ]] && ((passed++))
    echo $passed
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

#
# Show help message
# Arguments: None
# Returns: None
#
show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION - Comprehensive Performance Test Suite

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Performs comprehensive performance testing of Claude Code hooks system
    following TDD principles with detailed bottleneck analysis and reporting.

OPTIONS:
    -c, --config FILE       Use custom configuration file
                           (default: $DEFAULT_CONFIG_FILE)

    -o, --output DIR        Output directory for reports
                           (default: $DEFAULT_OUTPUT_DIR)

    -f, --format FORMAT     Report format: json, markdown, both
                           (default: $DEFAULT_REPORT_FORMAT)

    -v, --verbose          Enable verbose output

    -h, --help             Show this help message

EXIT CODES:
    0    All tests passed
    1    Some tests failed
    2    Configuration error
    3    Environment error

EXAMPLES:
    # Run with default settings
    $SCRIPT_NAME

    # Use custom config and save to specific directory
    $SCRIPT_NAME -c custom.conf -o /tmp/reports

    # Generate only JSON report with verbose output
    $SCRIPT_NAME -f json -v

CONFIGURATION:
    Configuration is loaded from a file containing shell variable assignments.
    See $DEFAULT_CONFIG_FILE for available options.

REPORTS:
    - JSON reports contain structured data for programmatic analysis
    - Markdown reports include charts and human-readable analysis
    - Reports are timestamped when REPORT_SAVE_TIMESTAMPED=true

For more information, see the project documentation.
EOF
}

#
# Parse command line arguments
# Arguments: $@: All command line arguments
# Returns: 0 on success, 1 on error
#
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -f|--format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 2
                ;;
        esac
    done

    # Validate output directory
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        print_error "Output directory does not exist: $OUTPUT_DIR"
        return 1
    fi

    return 0
}

# ============================================================================
# MAIN EXECUTION FLOW
# ============================================================================

#
# Main function
# Arguments: $@: All command line arguments
# Returns: Exit code (0=success, 1=test failure, 2=config error, 3=env error)
#
main() {
    print_section "Claude Code Hooks Comprehensive Performance Test Suite v$SCRIPT_VERSION"

    # Parse command line arguments
    if ! parse_arguments "$@"; then
        exit 2
    fi

    # Load and validate configuration
    if ! load_configuration "$CONFIG_FILE"; then
        exit 2
    fi

    if ! validate_configuration; then
        exit 2
    fi

    # Setup test environment
    if ! setup_test_environment; then
        print_error "Failed to setup test environment"
        exit 3
    fi

    print_info "Test Configuration:"
    print_info "  Config File: $CONFIG_FILE"
    print_info "  Output Directory: $OUTPUT_DIR"
    print_info "  Report Format: $REPORT_FORMAT"
    print_info "  Verbose Mode: $VERBOSE"
    echo

    # Execute all tests
    local test_failures=0

    if ! test_response_time; then
        ((test_failures++))
    fi

    if ! test_parallel_execution; then
        ((test_failures++))
    fi

    if ! test_memory_usage; then
        ((test_failures++))
    fi

    if ! test_bottleneck_identification; then
        ((test_failures++))
    fi

    # Generate reports
    print_section "Report Generation"

    if [[ "$REPORT_FORMAT" == "json" || "$REPORT_FORMAT" == "both" ]]; then
        if generate_json_report; then
            print_success "JSON report generated: $JSON_REPORT_FILE"
        else
            print_error "Failed to generate JSON report"
        fi
    fi

    if [[ "$REPORT_FORMAT" == "markdown" || "$REPORT_FORMAT" == "both" ]]; then
        if generate_markdown_report; then
            print_success "Markdown report generated: $REPORT_FILE"
        else
            print_error "Failed to generate Markdown report"
        fi
    fi

    # Print summary
    print_section "Performance Test Summary"

    echo "Test 1 (Response Time): $(test_status_icon "${TEST_RESULTS[response_time_passed]:-false}")"
    echo "Test 2 (Parallel Exec): $(test_status_icon "${TEST_RESULTS[parallel_passed]:-false}")"
    echo "Test 3 (Memory Usage):  $(test_status_icon "${TEST_RESULTS[memory_passed]:-false}")"
    echo "Test 4 (Profiling):     $(test_status_icon "${TEST_RESULTS[profiling_passed]:-false}")"
    echo

    if all_tests_passed; then
        print_success "All performance tests PASSED"
        return 0
    else
        print_error "Some performance tests FAILED ($test_failures out of 4)"
        echo "Detailed reports available:"
        [[ -f "$JSON_REPORT_FILE" ]] && echo "  JSON: $JSON_REPORT_FILE"
        [[ -f "$REPORT_FILE" ]] && echo "  Markdown: $REPORT_FILE"
        return 1
    fi
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Ensure required tools are available
for tool in bc jq date; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        print_error "Required tool not found: $tool"
        exit 3
    fi
done

# Execute main function with all arguments
main "$@"
