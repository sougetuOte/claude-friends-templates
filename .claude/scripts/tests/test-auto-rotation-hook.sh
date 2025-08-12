#!/bin/bash

# Test script for auto-rotation hook
# Tests that the hook correctly triggers rotation at 450+ lines

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../notes-check-hook.sh"
TEST_DIR="/tmp/test-auto-rotation-$$"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

# Test helper functions
run_test() {
    local test_name="$1"
    echo -e "${YELLOW}Running: $test_name${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

pass_test() {
    echo -e "${GREEN}✓ Passed${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
    local reason="$1"
    echo -e "${RED}✗ Failed: $reason${NC}"
}

# Setup
setup() {
    mkdir -p "$TEST_DIR/.claude/planner"
    mkdir -p "$TEST_DIR/.claude/builder"
    mkdir -p "$TEST_DIR/.claude/scripts"
    
    # Copy necessary scripts
    cp "$SCRIPT_DIR/../rotate-notes.sh" "$TEST_DIR/.claude/scripts/"
    cp "$SCRIPT_DIR/../update-index.sh" "$TEST_DIR/.claude/scripts/"
    cp "$SCRIPT_DIR/../rotation-config.sh" "$TEST_DIR/.claude/scripts/"
    cp "$HOOK_SCRIPT" "$TEST_DIR/.claude/scripts/"
    
    cd "$TEST_DIR"
}

# Cleanup
cleanup() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test 1: No rotation when under 450 lines
test_no_rotation_under_threshold() {
    run_test "No rotation when under 450 lines"
    
    # Create notes with 400 lines
    for i in {1..400}; do
        echo "Line $i" >> .claude/planner/notes.md
    done
    
    # Run hook
    output=$(bash .claude/scripts/notes-check-hook.sh 2>&1)
    
    # Check no rotation happened
    if [[ ! "$output" =~ "Auto-rotating" ]]; then
        pass_test
    else
        fail_test "Should not rotate at 400 lines"
    fi
}

# Test 2: Auto rotation when over 450 lines
test_auto_rotation_over_threshold() {
    run_test "Auto rotation when over 450 lines"
    
    # Create notes with 451 lines
    for i in {1..451}; do
        echo "Line $i" >> .claude/builder/notes.md
    done
    
    # Run hook
    output=$(bash .claude/scripts/notes-check-hook.sh 2>&1)
    
    # Check rotation happened
    if [[ "$output" =~ "Auto-rotating" ]] && [[ "$output" =~ "Builder" ]]; then
        # Verify archive was created
        if [ -d ".claude/builder/archive" ] && [ -f ".claude/builder/notes.md" ]; then
            local new_lines=$(wc -l < .claude/builder/notes.md)
            if [ "$new_lines" -lt 451 ]; then
                pass_test
            else
                fail_test "Notes not rotated properly"
            fi
        else
            fail_test "Archive not created"
        fi
    else
        fail_test "Should rotate at 451 lines"
    fi
}

# Test 3: Both agents rotation
test_both_agents_rotation() {
    run_test "Both agents rotation when both exceed threshold"
    
    # Clean previous test files
    rm -rf .claude/planner/archive .claude/builder/archive
    rm -f .claude/planner/notes.md .claude/builder/notes.md
    
    # Create notes for both agents
    for i in {1..460}; do
        echo "Planner line $i" >> .claude/planner/notes.md
        echo "Builder line $i" >> .claude/builder/notes.md
    done
    
    # Run hook
    output=$(bash .claude/scripts/notes-check-hook.sh 2>&1)
    
    # Check both rotations happened
    if [[ "$output" =~ "Planner" ]] && [[ "$output" =~ "Builder" ]]; then
        if [ -d ".claude/planner/archive" ] && [ -d ".claude/builder/archive" ]; then
            pass_test
        else
            fail_test "Both archives not created"
        fi
    else
        fail_test "Should rotate both agents"
    fi
}

# Main test execution
main() {
    echo "=== Testing Auto-Rotation Hook ==="
    echo
    
    # Setup test environment
    setup
    
    # Run tests
    test_no_rotation_under_threshold
    test_auto_rotation_over_threshold
    test_both_agents_rotation
    
    # Cleanup
    cleanup
    
    # Summary
    echo
    echo "==================================="
    echo -e "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    
    if [ "$TESTS_PASSED" -eq "$TESTS_RUN" ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main