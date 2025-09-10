#!/bin/bash

# =============================================================================
# Test Suite for Session Complete Hook
# TDD Phase: Red (failing tests first)
# =============================================================================

set -euo pipefail

# Test configuration
TEST_DIR="/tmp/test-session-complete-$$"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/session-complete-enhanced.sh"
LOG_FILE="$TEST_DIR/.claude/session.log"
SUMMARY_FILE="$TEST_DIR/.claude/session-summary.md"
HANDOVER_FILE="$TEST_DIR/.claude/handover-next.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# =============================================================================
# Test Helper Functions
# =============================================================================

setup_test_env() {
    mkdir -p "$TEST_DIR/.claude"
    mkdir -p "$TEST_DIR/project"
    cd "$TEST_DIR/project"
    
    # Initialize git repo for testing
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create some test files
    echo "test content" > file1.txt
    echo "more content" > file2.txt
    git add .
    git commit -m "Initial commit" --quiet
}

teardown_test_env() {
    cd /
    rm -rf "$TEST_DIR"
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${YELLOW}Running test: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    setup_test_env
    
    if $test_function; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    teardown_test_env
    echo
}

assert_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "  Expected file to exist: $file"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
        return 0
    else
        echo "  Expected file '$file' to contain: $pattern"
        return 1
    fi
}

# =============================================================================
# Test Cases
# =============================================================================

test_creates_session_log() {
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    assert_file_exists "$LOG_FILE"
}

test_records_git_status() {
    # Make changes to test
    echo "new content" > file3.txt
    git add file3.txt
    
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    
    assert_file_contains "$LOG_FILE" "Git Status:" &&
    assert_file_contains "$LOG_FILE" "Changed files:" &&
    assert_file_contains "$LOG_FILE" "Current branch:"
}

test_generates_work_summary() {
    # Simulate some activity
    mkdir -p "$TEST_DIR/.claude"
    cat > "$TEST_DIR/.claude/activity.log" << EOF
[$(date '+%Y-%m-%d %H:%M:%S')] Tool: Edit | File: test.js | Size: 1024
[$(date '+%Y-%m-%d %H:%M:%S')] Tool: Write | File: new.py | Size: 512
[$(date '+%Y-%m-%d %H:%M:%S')] Tool: Bash | Command: npm test
EOF
    
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    
    assert_file_exists "$SUMMARY_FILE" &&
    assert_file_contains "$SUMMARY_FILE" "## Work Summary" &&
    assert_file_contains "$SUMMARY_FILE" "### Files Modified" &&
    assert_file_contains "$SUMMARY_FILE" "### Commands Executed"
}

test_creates_handover_notes() {
    # Setup context
    echo "changed" >> file1.txt
    git add file1.txt
    
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    
    assert_file_exists "$HANDOVER_FILE" &&
    assert_file_contains "$HANDOVER_FILE" "## Next Session Handover" &&
    assert_file_contains "$HANDOVER_FILE" "### Uncommitted Changes" &&
    assert_file_contains "$HANDOVER_FILE" "### Suggested Next Steps"
}

test_handles_no_git_repo() {
    # Test in non-git directory
    cd "$TEST_DIR"
    rm -rf project
    mkdir plain_dir
    cd plain_dir
    
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    
    assert_file_exists "$LOG_FILE" &&
    assert_file_contains "$LOG_FILE" "Not a git repository"
}

test_analyzes_commit_patterns() {
    # Create multiple commits
    echo "feat: add feature" > feature.txt
    git add feature.txt
    git commit -m "feat: add new feature" --quiet
    
    echo "fix: bug fix" > bugfix.txt
    git add bugfix.txt
    git commit -m "fix: resolve issue #123" --quiet
    
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    
    assert_file_contains "$SUMMARY_FILE" "### Recent Commits" &&
    assert_file_contains "$SUMMARY_FILE" "feat:" &&
    assert_file_contains "$SUMMARY_FILE" "fix:"
}

test_tracks_task_progress() {
    # Simulate task tracking
    mkdir -p "$TEST_DIR/.claude/shared"
    cat > "$TEST_DIR/.claude/shared/phase-todo.md" << EOF
## Current Phase: Testing
- [x] Task 1 ✅
- [x] Task 2 ✅
- [ ] Task 3 🟡
- [ ] Task 4 🔴
EOF
    
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    
    assert_file_contains "$SUMMARY_FILE" "### Task Progress" &&
    assert_file_contains "$SUMMARY_FILE" "Completed: 2" &&
    assert_file_contains "$SUMMARY_FILE" "In Progress: 1"
}

test_generates_time_report() {
    # Test session duration tracking
    HOME="$TEST_DIR" bash "$SCRIPT_PATH"
    
    assert_file_contains "$SUMMARY_FILE" "### Session Duration" &&
    assert_file_contains "$SUMMARY_FILE" "Start time:" &&
    assert_file_contains "$SUMMARY_FILE" "End time:"
}

# =============================================================================
# Main Test Execution
# =============================================================================

main() {
    echo "==============================================================================="
    echo "Session Complete Hook Test Suite (TDD Red Phase)"
    echo "==============================================================================="
    echo
    
    # Run all tests
    run_test "Creates session log" test_creates_session_log
    run_test "Records git status" test_records_git_status
    run_test "Generates work summary" test_generates_work_summary
    run_test "Creates handover notes" test_creates_handover_notes
    run_test "Handles non-git repository" test_handles_no_git_repo
    run_test "Analyzes commit patterns" test_analyzes_commit_patterns
    run_test "Tracks task progress" test_tracks_task_progress
    run_test "Generates time report" test_generates_time_report
    
    # Test Summary
    echo "==============================================================================="
    echo "Test Results Summary"
    echo "==============================================================================="
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo -e "${RED}RED PHASE: Tests failing as expected - ready for implementation${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed - unexpected in RED phase${NC}"
        exit 0
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi