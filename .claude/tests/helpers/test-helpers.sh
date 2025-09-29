#!/bin/bash
# Test Helper Functions for Hooks System Testing

# Source the mock environment
source "$(dirname "${BASH_SOURCE[0]}")/../mocks/mock-claude-env.sh"

# Global test utilities
TEST_TEMP_DIR=""
TEST_LOG_FILE=""

# Setup function called by bats before each test
setup_test_environment() {
    # Create temporary directory for test
    TEST_TEMP_DIR="$(mktemp -d)"
    TEST_LOG_FILE="$TEST_TEMP_DIR/test.log"

    # Set up basic project structure in temp dir
    mkdir -p "$TEST_TEMP_DIR/.claude/logs"
    mkdir -p "$TEST_TEMP_DIR/.claude/agents"
    mkdir -p "$TEST_TEMP_DIR/.claude/scripts"

    # Copy necessary scripts to temp dir for isolated testing
    cp -r .claude/scripts/* "$TEST_TEMP_DIR/.claude/scripts/" 2>/dev/null || true

    # Set project directory to temp directory
    export CLAUDE_PROJECT_DIR="$TEST_TEMP_DIR"

    # Initialize basic files
    echo "none" > "$TEST_TEMP_DIR/.claude/agents/active.md"
    touch "$TEST_TEMP_DIR/.claude/logs/activity.log"

    # Redirect logs to test log file
    exec 3>&2
    exec 2>"$TEST_LOG_FILE"
}

# Cleanup function called by bats after each test
cleanup_test_environment() {
    # Restore stderr
    exec 2>&3
    exec 3>&-

    # Clean up temporary directory
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi

    # Reset environment
    reset_claude_env
}

# Assert functions for testing
assert_file_exists() {
    local file="$1"
    local message="${2:-File $file should exist}"

    if [[ ! -f "$file" ]]; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="${3:-File $file should contain pattern: $pattern}"

    if [[ ! -f "$file" ]]; then
        echo "ASSERTION FAILED: File $file does not exist" >&2
        return 1
    fi

    if ! grep -q "$pattern" "$file"; then
        echo "ASSERTION FAILED: $message" >&2
        echo "File contents:" >&2
        cat "$file" >&2
        return 1
    fi
}

assert_log_contains() {
    local pattern="$1"
    local message="${2:-Log should contain pattern: $pattern}"

    if [[ ! -f "$TEST_LOG_FILE" ]]; then
        echo "ASSERTION FAILED: Test log file does not exist" >&2
        return 1
    fi

    if ! grep -q "$pattern" "$TEST_LOG_FILE"; then
        echo "ASSERTION FAILED: $message" >&2
        echo "Log contents:" >&2
        cat "$TEST_LOG_FILE" >&2
        return 1
    fi
}

assert_command_success() {
    local command="$1"
    local message="${2:-Command should succeed: $command}"

    if ! eval "$command" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

assert_command_failure() {
    local command="$1"
    local message="${2:-Command should fail: $command}"

    if eval "$command" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

# JSON testing utilities
assert_json_valid() {
    local file="$1"
    local message="${2:-File $file should contain valid JSON}"

    if ! jq . "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

assert_json_contains() {
    local file="$1"
    local jq_query="$2"
    local expected="$3"
    local message="${4:-JSON query $jq_query should return $expected}"

    local actual
    actual=$(jq -r "$jq_query" "$file" 2>/dev/null)

    if [[ "$actual" != "$expected" ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "Expected: $expected" >&2
        echo "Actual: $actual" >&2
        return 1
    fi
}

# Hook testing utilities
run_hook_with_input() {
    local hook_script="$1"
    local input="$2"

    echo "$input" | "$hook_script"
}

simulate_tool_use() {
    local tool_name="$1"
    local file_paths="$2"
    local exit_code="${3:-0}"

    export CLAUDE_TOOL_NAME="$tool_name"
    export CLAUDE_FILE_PATHS="$file_paths"
    export CLAUDE_EXIT_CODE="$exit_code"
}

simulate_user_prompt() {
    local prompt="$1"

    export CLAUDE_PROMPT="$prompt"
    export CLAUDE_TOOL_NAME="UserPromptSubmit"
}

# Performance testing utilities
measure_execution_time() {
    local command="$1"
    local start_time end_time duration

    start_time=$(date +%s.%N)
    eval "$command"
    local exit_code=$?
    end_time=$(date +%s.%N)

    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0.0")
    echo "$duration"
    return $exit_code
}

assert_execution_time_under() {
    local command="$1"
    local max_time="$2"
    local message="${3:-Command should execute in under ${max_time}s}"

    local duration
    duration=$(measure_execution_time "$command")

    if (( $(echo "$duration > $max_time" | bc -l) )); then
        echo "ASSERTION FAILED: $message (took ${duration}s)" >&2
        return 1
    fi
}

# Security testing utilities
test_dangerous_command_blocked() {
    local dangerous_command="$1"

    if .claude/scripts/deny-check.sh "$dangerous_command" 2>/dev/null; then
        echo "SECURITY FAILURE: Dangerous command not blocked: $dangerous_command" >&2
        return 1
    fi
}

test_safe_command_allowed() {
    local safe_command="$1"

    if ! .claude/scripts/deny-check.sh "$safe_command" 2>/dev/null; then
        echo "SECURITY FAILURE: Safe command was blocked: $safe_command" >&2
        return 1
    fi
}

# Export all functions for use in tests
export -f setup_test_environment cleanup_test_environment
export -f assert_file_exists assert_file_contains assert_log_contains
export -f assert_command_success assert_command_failure
export -f assert_json_valid assert_json_contains
export -f run_hook_with_input simulate_tool_use simulate_user_prompt
export -f measure_execution_time assert_execution_time_under
export -f test_dangerous_command_blocked test_safe_command_allowed
