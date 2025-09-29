#!/bin/bash
# Simplified Test Helper Functions for Hooks System Testing

# Source the mock environment
source "$(dirname "${BASH_SOURCE[0]}")/../mocks/mock-claude-env.sh"

# Global test utilities
TEST_TEMP_DIR=""

# Setup function called by bats before each test
setup_test_environment() {
    # Create temporary directory for test
    TEST_TEMP_DIR="$(mktemp -d)"

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
}

# Cleanup function called by bats after each test
cleanup_test_environment() {
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

# Security testing utilities
test_dangerous_command_blocked() {
    local dangerous_command="$1"

    if echo "$dangerous_command" | .claude/scripts/deny-check.sh >/dev/null 2>&1; then
        echo "SECURITY FAILURE: Dangerous command not blocked: $dangerous_command" >&2
        return 1
    fi
}

test_safe_command_allowed() {
    local safe_command="$1"

    if ! echo "$safe_command" | .claude/scripts/deny-check.sh >/dev/null 2>&1; then
        echo "SECURITY FAILURE: Safe command was blocked: $safe_command" >&2
        return 1
    fi
}
