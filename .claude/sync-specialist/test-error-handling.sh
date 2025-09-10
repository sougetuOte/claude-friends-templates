#!/bin/bash

# =============================================================================
# Sync Specialist Error Handling TDD Test Suite
# Phase 2-2 Enhanced Error Handling Tests
# =============================================================================

set -euo pipefail

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG="$TEST_DIR/test-error-handling.log"
TEST_TEMP_DIR="/tmp/sync-test-$$"
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test framework functions
setup_test() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Error Handling Test Suite" > "$TEST_LOG"
    mkdir -p "$TEST_TEMP_DIR"
    mkdir -p memo
    rm -f memo/sync-error.md
    rm -f .claude/sync-specialist/error.log
}

teardown_test() {
    rm -rf "$TEST_TEMP_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Test suite completed" >> "$TEST_LOG"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Expected: $expected"
        echo -e "  Actual: $actual"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local message="${2:-File should exist: $file_path}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ -f "$file_path" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  File not found: $file_path"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

assert_file_contains() {
    local file_path="$1"
    local pattern="$2"
    local message="${3:-File should contain pattern: $pattern}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ -f "$file_path" ]] && grep -q "$pattern" "$file_path"; then
        echo -e "${GREEN}✓${NC} $message"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Pattern not found in $file_path: $pattern"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Test cases (Red phase - these should initially fail)

test_timeout_handling() {
    echo -e "\n${YELLOW}Test: Timeout Handling${NC}"
    
    # Set short timeout for testing
    export SYNC_TIMEOUT=2
    
    # Test timeout handling (this should create emergency handover)
    local result=0
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        handle_timeout 'test_operation' 2
    " 2>/dev/null || result=$?
    
    # Assert that timeout handling executed (any non-zero result acceptable)
    if [[ $result -ne 0 ]]; then
        echo -e "${GREEN}✓${NC} Timeout handling executed with exit code ($result)"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo -e "${RED}✗${NC} Timeout handling should return non-zero exit code"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # Assert error log contains timeout message
    assert_file_exists ".claude/sync-specialist/error.log" "Error log should be created"
    assert_file_contains ".claude/sync-specialist/error.log" "timed out" "Error log should contain timeout message"
}

test_error_notification() {
    echo -e "\n${YELLOW}Test: User Error Notification${NC}"
    
    # Test error notification creation
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        notify_user_of_error 'Test error message' 'test_context'
    " 2>/dev/null || true
    
    # Assert notification file is created
    assert_file_exists "memo/sync-error.md" "Error notification file should be created"
    assert_file_contains "memo/sync-error.md" "Test error message" "Notification should contain error message"
    assert_file_contains "memo/sync-error.md" "test_context" "Notification should contain context"
    assert_file_contains "memo/sync-error.md" "What happened?" "Notification should have user-friendly explanation"
}

test_emergency_handover_creation() {
    echo -e "\n${YELLOW}Test: Emergency Handover Creation${NC}"
    
    # This test will initially fail as emergency handover function needs to be implemented
    local result=0
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        create_emergency_handover 'Critical error' 'emergency_test' || exit 1
    " 2>/dev/null || result=$?
    
    # Assert handover file is created
    assert_file_exists "memo/handover.md" "Emergency handover file should be created"
    assert_file_contains "memo/handover.md" "Critical error" "Handover should contain error information"
}

test_error_log_rotation() {
    echo -e "\n${YELLOW}Test: Error Log Rotation${NC}"
    
    # Create a small error log for testing
    local test_log=".claude/sync-specialist/error.log"
    mkdir -p .claude/sync-specialist
    
    # Create test log content
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') Test error entry for rotation testing" > "$test_log"
    
    # Test log rotation function exists and runs
    local result=0
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        rotate_error_log_if_needed
    " 2>/dev/null || result=$?
    
    # Assert that rotation function executed successfully 
    assert_equals "0" "$result" "Log rotation function should exist and execute"
    
    # Clean up test log
    rm -f "$test_log" "${test_log}."*
}

test_fallback_mechanism() {
    echo -e "\n${YELLOW}Test: Fallback Mechanism${NC}"
    
    # Test fallback when primary handover generation fails
    local result=0
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        # Simulate primary handover failure
        export HANDOVER_PRIMARY_FAILED=true
        create_fallback_handover 'Primary handover failed' || exit 1
    " 2>/dev/null || result=$?
    
    # Assert fallback handover is created
    assert_file_exists "memo/handover-fallback.md" "Fallback handover file should be created"
    assert_file_contains "memo/handover-fallback.md" "Primary handover failed" "Fallback should contain failure reason"
}

test_concurrent_access_protection() {
    echo -e "\n${YELLOW}Test: Concurrent Access Protection${NC}"
    
    # Test lock file mechanism for concurrent access protection
    local lock_file="/tmp/sync-specialist-lock-test"
    
    # Create a lock file
    echo "test-pid" > "$lock_file"
    
    # Test that concurrent access is detected
    local result=0
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        check_concurrent_access '$lock_file'
    " 2>/dev/null || result=$?
    
    # Clean up
    rm -f "$lock_file"
    
    # Assert concurrent access detection works (should return 1 when lock exists)
    assert_equals "1" "$result" "Should detect concurrent access when lock exists"
}

test_recovery_mechanism() {
    echo -e "\n${YELLOW}Test: Recovery Mechanism${NC}"
    
    # Test automatic recovery after error
    local result=0
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        attempt_recovery_after_error 'test_error_context' || exit 1
    " 2>/dev/null || result=$?
    
    # Assert recovery attempt is made
    assert_equals "0" "$result" "Recovery mechanism should attempt to recover"
    assert_file_contains ".claude/sync-specialist/error.log" "recovery" "Error log should contain recovery attempt"
}

test_dependency_validation() {
    echo -e "\n${YELLOW}Test: Dependency Validation${NC}"
    
    # Test validation of required dependencies
    local result=0
    bash -c "
        source .claude/sync-specialist/enhanced-sync-monitor.sh
        validate_dependencies || exit 1
    " 2>/dev/null || result=$?
    
    # Assert dependency validation runs
    assert_equals "0" "$result" "Dependency validation should complete"
}

# Main test execution
run_tests() {
    echo -e "${YELLOW}=== Sync Specialist Error Handling TDD Test Suite ===${NC}"
    echo "Testing enhanced error handling features..."
    
    setup_test
    
    # Run all test cases (continue even if individual tests fail)
    test_timeout_handling || true
    test_error_notification || true
    test_emergency_handover_creation || true
    test_error_log_rotation || true
    test_fallback_mechanism || true
    test_concurrent_access_protection || true
    test_recovery_mechanism || true
    test_dependency_validation || true
    
    teardown_test
    
    # Print test summary
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo -e "Total tests: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASSED_COUNT${NC}"
    echo -e "${RED}Failed: $FAILED_COUNT${NC}"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed! ✓${NC}"
        return 0
    else
        echo -e "\n${RED}Some tests failed. This is expected in Red phase.${NC}"
        echo -e "${YELLOW}Next: Implement missing functions to make tests pass (Green phase)${NC}"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests "$@"
fi