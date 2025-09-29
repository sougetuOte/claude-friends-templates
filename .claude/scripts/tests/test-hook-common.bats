#!/usr/bin/env bats

# =============================================================================
# Hook Common Library Tests
# TDD Red Phase - These tests MUST FAIL initially
# =============================================================================

setup() {
    # Test environment setup
    export TEST_TEMP_DIR=$(mktemp -d)
    export HOOK_COMMON_SH="${BATS_TEST_DIRNAME}/../hook-common.sh"
    export CLAUDE_PROJECT_ROOT="$TEST_TEMP_DIR"
    export CLAUDE_LOG_FILE="$TEST_TEMP_DIR/test.log"

    # Create test directories structure
    mkdir -p "$TEST_TEMP_DIR/memo"
    mkdir -p "$TEST_TEMP_DIR/.claude/logs"

    # Mock environment variables for testing
    export CLAUDE_CURRENT_AGENT="planner"
    export CLAUDE_JSON_PROMPT='{"agent": "planner", "task": "test", "context": "unit_test"}'
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_TEMP_DIR"
}

# =============================================================================
# 1. init_hooks_system Function Tests
# =============================================================================

@test "init_hooks_system creates required directories" {
    # RED PHASE: This test will FAIL because hook-common.sh doesn't exist yet

    # Source the library that doesn't exist yet
    source "$HOOK_COMMON_SH"

    # Act: Initialize hooks system
    init_hooks_system "$TEST_TEMP_DIR"

    # Assert: Required directories should be created
    [ -d "$TEST_TEMP_DIR/.claude/hooks" ]
    [ -d "$TEST_TEMP_DIR/.claude/logs" ]
    [ -d "$TEST_TEMP_DIR/memo" ]
    [ -d "$TEST_TEMP_DIR/.claude/shared" ]
}

@test "init_hooks_system creates log files with correct permissions" {
    # RED PHASE: This will fail - function doesn't exist

    source "$HOOK_COMMON_SH"

    # Act
    init_hooks_system "$TEST_TEMP_DIR"

    # Assert: Log files should be created with correct permissions
    [ -f "$TEST_TEMP_DIR/.claude/logs/hooks.log" ]
    [ -w "$TEST_TEMP_DIR/.claude/logs/hooks.log" ]
}

@test "init_hooks_system fails when given invalid path" {
    # RED PHASE: Testing error handling that doesn't exist yet

    source "$HOOK_COMMON_SH"

    # Act & Assert: Should fail for invalid path
    run init_hooks_system "/invalid/nonexistent/path"
    [ "$status" -eq 1 ]
}

# =============================================================================
# 2. get_agent_info Function Tests
# =============================================================================

@test "get_agent_info extracts agent name from JSON prompt" {
    # RED PHASE: Function doesn't exist yet - this MUST fail

    source "$HOOK_COMMON_SH"

    # Arrange
    local test_json='{"agent": "planner", "task": "create_spec", "priority": "high"}'

    # Act
    result=$(get_agent_info "$test_json" "agent")

    # Assert
    [ "$result" = "planner" ]
}

@test "get_agent_info extracts task from JSON prompt" {
    # RED PHASE: Will fail - no implementation exists

    source "$HOOK_COMMON_SH"

    # Arrange
    local test_json='{"agent": "builder", "task": "implement_feature", "files": ["test.js"]}'

    # Act
    result=$(get_agent_info "$test_json" "task")

    # Assert
    [ "$result" = "implement_feature" ]
}

@test "get_agent_info handles malformed JSON gracefully" {
    # RED PHASE: Error handling doesn't exist yet

    source "$HOOK_COMMON_SH"

    # Act & Assert: Should return empty or error for malformed JSON
    run get_agent_info '{"agent": "planner"' "agent"
    [ "$status" -eq 1 ]
}

@test "get_agent_info returns empty for missing key" {
    # RED PHASE: Will fail because function doesn't exist

    source "$HOOK_COMMON_SH"

    # Arrange
    local test_json='{"agent": "planner"}'

    # Act
    result=$(get_agent_info "$test_json" "nonexistent_key")

    # Assert: Should return empty string
    [ -z "$result" ]
}

# =============================================================================
# 3. generate_json_response Function Tests
# =============================================================================

@test "generate_json_response creates valid JSON with status and message" {
    # RED PHASE: Function doesn't exist - this will fail

    source "$HOOK_COMMON_SH"

    # Act
    result=$(generate_json_response "success" "Test completed" "test_data")

    # Assert: Should be valid JSON
    echo "$result" | jq . > /dev/null  # This validates JSON syntax

    # Assert: Should contain expected fields
    status=$(echo "$result" | jq -r '.status')
    [ "$status" = "success" ]

    message=$(echo "$result" | jq -r '.message')
    [ "$message" = "Test completed" ]
}

@test "generate_json_response includes timestamp" {
    # RED PHASE: Will fail - no implementation

    source "$HOOK_COMMON_SH"

    # Act
    result=$(generate_json_response "info" "Processing")

    # Assert: Should include timestamp field
    timestamp=$(echo "$result" | jq -r '.timestamp')
    [ -n "$timestamp" ]

    # Assert: Timestamp should be in ISO format (basic validation)
    [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]
}

@test "generate_json_response handles special characters in message" {
    # RED PHASE: Error handling doesn't exist

    source "$HOOK_COMMON_SH"

    # Arrange: Message with special characters that need JSON escaping
    local special_message='Test "quotes" and \backslashes and
newlines'

    # Act
    result=$(generate_json_response "info" "$special_message")

    # Assert: Should still be valid JSON
    echo "$result" | jq . > /dev/null
}

@test "generate_json_response includes optional data field" {
    # RED PHASE: Advanced functionality doesn't exist yet

    source "$HOOK_COMMON_SH"

    # Arrange
    local test_data='{"files": ["test1.js", "test2.js"], "count": 2}'

    # Act
    result=$(generate_json_response "completed" "Files processed" "$test_data")

    # Assert: Should include data field
    data=$(echo "$result" | jq -r '.data')
    [ "$data" = "$test_data" ]
}

# =============================================================================
# 4. log_message Function Tests
# =============================================================================

@test "log_message writes to specified log file with correct format" {
    # RED PHASE: Function doesn't exist - will fail

    source "$HOOK_COMMON_SH"

    # Arrange
    local test_log="$TEST_TEMP_DIR/test.log"

    # Act
    log_message "INFO" "Test message for logging" "$test_log"

    # Assert: Log file should be created
    [ -f "$test_log" ]

    # Assert: Should contain expected format: [LEVEL] TIMESTAMP MESSAGE
    grep -q "^\[INFO\]" "$test_log"
    grep -q "Test message for logging" "$test_log"
}

@test "log_message creates log file if it doesn't exist" {
    # RED PHASE: Will fail - no implementation

    source "$HOOK_COMMON_SH"

    # Arrange
    local new_log="$TEST_TEMP_DIR/new.log"

    # Act
    log_message "DEBUG" "Creating new log" "$new_log"

    # Assert: New log file should be created
    [ -f "$new_log" ]
}

@test "log_message includes timestamp in ISO format" {
    # RED PHASE: Timestamp formatting doesn't exist

    source "$HOOK_COMMON_SH"

    # Arrange
    local test_log="$TEST_TEMP_DIR/timestamp.log"

    # Act
    log_message "WARN" "Timestamp test" "$test_log"

    # Assert: Should include timestamp
    timestamp_line=$(cat "$test_log")

    # Extract timestamp (assume format: [LEVEL] YYYY-MM-DD HH:MM:SS MESSAGE)
    [[ "$timestamp_line" =~ \[WARN\]\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]
}

@test "log_message handles different log levels" {
    # RED PHASE: Level validation doesn't exist

    source "$HOOK_COMMON_SH"

    # Arrange
    local test_log="$TEST_TEMP_DIR/levels.log"

    # Act: Test different log levels
    log_message "DEBUG" "Debug message" "$test_log"
    log_message "INFO" "Info message" "$test_log"
    log_message "WARN" "Warning message" "$test_log"
    log_message "ERROR" "Error message" "$test_log"

    # Assert: All levels should be present
    grep -q "\[DEBUG\]" "$test_log"
    grep -q "\[INFO\]" "$test_log"
    grep -q "\[WARN\]" "$test_log"
    grep -q "\[ERROR\]" "$test_log"
}

@test "log_message also outputs to stderr for ERROR level" {
    # RED PHASE: stderr output feature doesn't exist

    source "$HOOK_COMMON_SH"

    # Act & Assert: ERROR should go to both file and stderr
    run log_message "ERROR" "Critical error" "$CLAUDE_LOG_FILE"

    # Should succeed but also produce stderr output
    [ "$status" -eq 0 ]
    [[ "$output" == *"Critical error"* ]]
}

# =============================================================================
# 5. Integration Tests
# =============================================================================

@test "hook-common library can be sourced multiple times safely" {
    # RED PHASE: Library doesn't exist to source

    # Act: Source multiple times
    source "$HOOK_COMMON_SH"
    source "$HOOK_COMMON_SH"

    # Assert: Should not cause errors
    [ "$?" -eq 0 ]
}

@test "all functions work together in realistic scenario" {
    # RED PHASE: Integration test will fail - no functions exist

    source "$HOOK_COMMON_SH"

    # Arrange: Realistic hook scenario
    local json_input='{"agent": "builder", "task": "run_tests", "files": ["test.js"]}'

    # Act: Use all functions together
    init_hooks_system "$TEST_TEMP_DIR"
    agent=$(get_agent_info "$json_input" "agent")
    task=$(get_agent_info "$json_input" "task")

    log_message "INFO" "Starting hook for $agent:$task" "$CLAUDE_LOG_FILE"

    response=$(generate_json_response "processing" "Hook executing for $agent")

    # Assert: Everything should work together
    [ "$agent" = "builder" ]
    [ "$task" = "run_tests" ]
    [ -f "$CLAUDE_LOG_FILE" ]
    echo "$response" | jq . > /dev/null  # Valid JSON
}

# =============================================================================
# 6. Error Handling Tests
# =============================================================================

@test "functions handle missing environment variables gracefully" {
    # RED PHASE: Error handling doesn't exist

    source "$HOOK_COMMON_SH"

    # Arrange: Unset environment variables
    unset CLAUDE_PROJECT_ROOT
    unset CLAUDE_LOG_FILE

    # Act & Assert: Should not crash
    run init_hooks_system ""
    [ "$status" -ne 0 ]  # Should fail gracefully, not crash
}

@test "functions validate input parameters" {
    # RED PHASE: Input validation doesn't exist

    source "$HOOK_COMMON_SH"

    # Act & Assert: Should handle empty/null inputs
    run get_agent_info "" "agent"
    [ "$status" -eq 1 ]

    run generate_json_response "" ""
    [ "$status" -eq 1 ]

    run log_message "" "" ""
    [ "$status" -eq 1 ]
}
