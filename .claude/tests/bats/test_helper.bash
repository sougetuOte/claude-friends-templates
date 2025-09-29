#!/usr/bin/env bash
# Test helper functions for Bats tests
# Following t-wada style TDD: Refactor Phase - Improved implementation
#
# This module provides utilities for Bats testing including:
# - Test environment setup/teardown
# - Various assertion helpers
# - Temporary file/directory management
# - Mock command creation
# - Output capturing

# Mark that helper is loaded
TEST_HELPER_LOADED="true"

# Test temporary directory
TEST_TEMP_DIR=""

# Setup function for test environment
# Creates a temporary directory for test files
setup_test_environment() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    return 0
}

# Teardown function for test environment
# Cleans up temporary files and directories
teardown_test_environment() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    return 0
}

# Assert that two values are equal
# Usage: assert_equal "expected" "actual" ["message"]
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values are not equal}"

    if [ "$expected" != "$actual" ]; then
        echo "Assertion failed: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
    return 0
}

# Assert that two values are not equal
# Usage: assert_not_equal "value1" "value2" ["message"]
assert_not_equal() {
    local value1="$1"
    local value2="$2"
    local message="${3:-Values should not be equal}"

    if [ "$value1" = "$value2" ]; then
        echo "Assertion failed: $message"
        echo "  Both values are: '$value1'"
        return 1
    fi
    return 0
}

# Assert that a string contains a substring
# Usage: assert_contains "string" "substring" ["message"]
assert_contains() {
    local string="$1"
    local substring="$2"
    local message="${3:-String does not contain expected substring}"

    if [[ "$string" != *"$substring"* ]]; then
        echo "Assertion failed: $message"
        echo "  String:    '$string'"
        echo "  Substring: '$substring'"
        return 1
    fi
    return 0
}

# Assert that a file exists
# Usage: assert_file_exists "filepath" ["message"]
assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist}"

    if [ ! -f "$file" ]; then
        echo "Assertion failed: $message"
        echo "  File path: '$file'"
        return 1
    fi
    return 0
}

# Assert that a directory exists
# Usage: assert_dir_exists "dirpath" ["message"]
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory does not exist}"

    if [ ! -d "$dir" ]; then
        echo "Assertion failed: $message"
        echo "  Directory path: '$dir'"
        return 1
    fi
    return 0
}

# Assert that a command succeeds (returns 0)
# Usage: assert_success command [args...]
assert_success() {
    if ! "$@"; then
        echo "Assertion failed: Command did not succeed"
        echo "  Command: $*"
        echo "  Exit code: $?"
        return 1
    fi
    return 0
}

# Assert that a command fails (returns non-zero)
# Usage: assert_failure command [args...]
assert_failure() {
    if "$@"; then
        echo "Assertion failed: Command did not fail as expected"
        echo "  Command: $*"
        return 1
    fi
    return 0
}

# Create a temporary test file
# Usage: create_test_file "content" ["filename"]
create_test_file() {
    local content="$1"
    local filename="${2:-test_file_$$}"
    local filepath="${TEST_TEMP_DIR:-/tmp}/$filename"

    echo "$content" > "$filepath"
    echo "$filepath"
}

# Create a mock command
# Usage: mock_command "command_name" "output" ["exit_code"]
mock_command() {
    local cmd_name="$1"
    local output="$2"
    local exit_code="${3:-0}"
    local mock_path="${TEST_TEMP_DIR:-/tmp}/$cmd_name"

    cat > "$mock_path" << EOF
#!/usr/bin/env bash
echo '$output'
exit $exit_code
EOF
    chmod +x "$mock_path"
    export PATH="${TEST_TEMP_DIR:-/tmp}:$PATH"
    echo "$mock_path"
}

# Run command and capture output
# Usage: run_and_capture command [args...]
run_and_capture() {
    local output
    local exit_code

    output=$("$@" 2>&1)
    exit_code=$?

    echo "$output"
    return $exit_code
}