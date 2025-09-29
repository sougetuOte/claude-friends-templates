#!/usr/bin/env bats
# Test for Bats setup and basic functionality
# Following t-wada style TDD: Red Phase - Writing failing test first

@test "bats is available in the system" {
    command -v bats
}

@test "bats test directory exists" {
    [ -d ".claude/tests/bats" ]
}

@test "bats test helper file exists" {
    [ -f ".claude/tests/bats/test_helper.bash" ]
}

@test "can source test helper" {
    source .claude/tests/bats/test_helper.bash
    [ "$TEST_HELPER_LOADED" = "true" ]
}

@test "setup function is available" {
    source .claude/tests/bats/test_helper.bash
    type -t setup_test_environment | grep -q "function"
}

@test "teardown function is available" {
    source .claude/tests/bats/test_helper.bash
    type -t teardown_test_environment | grep -q "function"
}

@test "assert_equal helper works" {
    source .claude/tests/bats/test_helper.bash
    assert_equal "test" "test"
}

@test "assert_not_equal helper works" {
    source .claude/tests/bats/test_helper.bash
    assert_not_equal "test" "different"
}

@test "assert_contains helper works" {
    source .claude/tests/bats/test_helper.bash
    assert_contains "hello world" "world"
}

@test "assert_file_exists helper works" {
    source .claude/tests/bats/test_helper.bash
    touch /tmp/test_file_$$
    assert_file_exists "/tmp/test_file_$$"
    rm -f /tmp/test_file_$$
}