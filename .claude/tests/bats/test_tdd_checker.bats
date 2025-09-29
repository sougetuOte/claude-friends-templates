#!/usr/bin/env bats

# test_tdd_checker.bats - TDD Design Check system tests
# Using t-wada style TDD - Red Phase test creation
# Created: 2025-09-16
# Sprint 2.3 Task 2.3.1: TDDチェッカーテスト作成【Red Phase】

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export TDD_CHECKER_LOG="$TEST_DIR/.claude/logs/tdd_checker.log"

    # Create necessary directories
    mkdir -p "$TEST_DIR/.claude/logs"
    mkdir -p "$TEST_DIR/src"
    mkdir -p "$TEST_DIR/tests"
    mkdir -p "$TEST_DIR/__tests__"
    mkdir -p "$TEST_DIR/docs"

    # Source the script under test (will fail in Red Phase - TDD)
    if [ -f "${BATS_TEST_DIRNAME}/../../hooks/tdd/tdd-checker.sh" ]; then
        source "${BATS_TEST_DIRNAME}/../../hooks/tdd/tdd-checker.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

# ==============================================================================
# Test File Discovery Tests
# ==============================================================================

@test "find_test_file should find Jest-style test file" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/calculator.js"
    touch "$TEST_DIR/__tests__/calculator.test.js"

    run find_test_file "$TEST_DIR/src/calculator.js"
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/__tests__/calculator.test.js" ]
}

@test "find_test_file should find spec-style test file" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/validator.ts"
    touch "$TEST_DIR/tests/validator.spec.ts"

    run find_test_file "$TEST_DIR/src/validator.ts"
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/tests/validator.spec.ts" ]
}

@test "find_test_file should find Python unittest file" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/parser.py"
    touch "$TEST_DIR/tests/test_parser.py"

    run find_test_file "$TEST_DIR/src/parser.py"
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/tests/test_parser.py" ]
}

@test "find_test_file should find Go test file" {
    # Red Phase: Function doesn't exist yet - should fail
    mkdir -p "$TEST_DIR/pkg"
    touch "$TEST_DIR/pkg/handler.go"
    touch "$TEST_DIR/pkg/handler_test.go"

    run find_test_file "$TEST_DIR/pkg/handler.go"
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/pkg/handler_test.go" ]
}

@test "find_test_file should return empty for non-existent test file" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/orphan.js"

    run find_test_file "$TEST_DIR/src/orphan.js"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "find_test_file should handle multiple test patterns" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/service.js"
    touch "$TEST_DIR/__tests__/service.test.js"
    touch "$TEST_DIR/tests/service.spec.js"

    run find_test_file "$TEST_DIR/src/service.js"
    [ "$status" -eq 0 ]
    # Should return the first match found
    [[ "$output" =~ service\.(test|spec)\.js$ ]]
}

# ==============================================================================
# TDD Compliance Check Tests
# ==============================================================================

@test "perform_tdd_check should pass when test file is newer" {
    # Red Phase: Function doesn't exist yet - should fail
    touch -t 202509160800 "$TEST_DIR/src/model.js"
    touch -t 202509160900 "$TEST_DIR/__tests__/model.test.js"

    run perform_tdd_check "$TEST_DIR/src/model.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TDD_COMPLIANT" ]]
}

@test "perform_tdd_check should fail when implementation is newer" {
    # Red Phase: Function doesn't exist yet - should fail
    touch -t 202509160900 "$TEST_DIR/src/controller.js"
    touch -t 202509160800 "$TEST_DIR/__tests__/controller.test.js"

    run perform_tdd_check "$TEST_DIR/src/controller.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "TDD_VIOLATION" ]]
}

@test "perform_tdd_check should handle missing test file gracefully" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/utils.js"

    run perform_tdd_check "$TEST_DIR/src/utils.js"
    [ "$status" -eq 2 ]  # Different exit code for missing test
    [[ "$output" =~ "NO_TEST_FILE" ]]
}

@test "perform_tdd_check should log violations to TDD checker log" {
    # Red Phase: Function doesn't exist yet - should fail
    touch -t 202509160900 "$TEST_DIR/src/api.js"
    touch -t 202509160800 "$TEST_DIR/__tests__/api.test.js"

    run perform_tdd_check "$TEST_DIR/src/api.js"
    [ "$status" -eq 1 ]
    [ -f "$TDD_CHECKER_LOG" ]
    grep -q "TDD_VIOLATION" "$TDD_CHECKER_LOG"
}

@test "perform_tdd_check should handle same timestamp as compliant" {
    # Red Phase: Function doesn't exist yet - should fail
    local timestamp="202509160900"
    touch -t "$timestamp" "$TEST_DIR/src/equal.js"
    touch -t "$timestamp" "$TEST_DIR/__tests__/equal.test.js"

    run perform_tdd_check "$TEST_DIR/src/equal.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TDD_COMPLIANT" ]]
}

# ==============================================================================
# Design Compliance Check Tests
# ==============================================================================

@test "check_design_compliance should find design document" {
    # Red Phase: Function doesn't exist yet - should fail
    echo "# API Design" > "$TEST_DIR/docs/api_design.md"
    echo "interface UserService {" >> "$TEST_DIR/docs/api_design.md"
    echo "  getUser(id: string): User" >> "$TEST_DIR/docs/api_design.md"
    echo "}" >> "$TEST_DIR/docs/api_design.md"

    run check_design_compliance "$TEST_DIR/src/user_service.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DESIGN_DOC_FOUND" ]]
}

@test "check_design_compliance should detect interface mismatch" {
    # Red Phase: Function doesn't exist yet - should fail
    echo "# User Service Design" > "$TEST_DIR/docs/user_design.md"
    echo "Expected methods: getUser, createUser" >> "$TEST_DIR/docs/user_design.md"

    echo "function getUser(id) { return null; }" > "$TEST_DIR/src/user_service.js"
    echo "function deleteUser(id) { }" >> "$TEST_DIR/src/user_service.js"

    run check_design_compliance "$TEST_DIR/src/user_service.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "DESIGN_MISMATCH" ]]
}

@test "check_design_compliance should handle missing design document" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/orphan_service.js"

    run check_design_compliance "$TEST_DIR/src/orphan_service.js"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "NO_DESIGN_DOC" ]]
}

@test "check_design_compliance should validate against ADR documents" {
    # Red Phase: Function doesn't exist yet - should fail
    mkdir -p "$TEST_DIR/docs/adr"
    echo "# ADR-001: Database Access Pattern" > "$TEST_DIR/docs/adr/001-database-pattern.md"
    echo "Decision: Use Repository pattern" >> "$TEST_DIR/docs/adr/001-database-pattern.md"

    echo "class UserRepository {}" > "$TEST_DIR/src/user_repository.js"

    run check_design_compliance "$TEST_DIR/src/user_repository.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ADR_COMPLIANT" ]]
}

# ==============================================================================
# Warning Generation Tests
# ==============================================================================

@test "generate_warning should create structured warning message" {
    # Red Phase: Function doesn't exist yet - should fail
    run generate_warning "TDD_VIOLATION" "$TEST_DIR/src/test.js" "Implementation modified after test"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "WARNING:" ]]
    [[ "$output" =~ "TDD_VIOLATION" ]]
    [[ "$output" =~ "$TEST_DIR/src/test.js" ]]
    [[ "$output" =~ "Implementation modified after test" ]]
}

@test "generate_warning should include timestamp in warning" {
    # Red Phase: Function doesn't exist yet - should fail
    run generate_warning "DESIGN_DRIFT" "$TEST_DIR/src/drift.js" "Design document outdated"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$(date +%Y-%m-%d)" ]]
}

@test "generate_warning should log to checker log file" {
    # Red Phase: Function doesn't exist yet - should fail
    run generate_warning "TEST_MISSING" "$TEST_DIR/src/missing.js" "No test file found"
    [ "$status" -eq 0 ]
    [ -f "$TDD_CHECKER_LOG" ]
    grep -q "TEST_MISSING" "$TDD_CHECKER_LOG"
}

# ==============================================================================
# Hook Integration Tests
# ==============================================================================

@test "tdd_checker_hook should process file modification event" {
    # Red Phase: Function doesn't exist yet - should fail
    export CLAUDE_TOOL="Edit"
    export CLAUDE_FILE_PATHS="$TEST_DIR/src/processor.js"

    touch -t 202509160800 "$TEST_DIR/__tests__/processor.test.js"
    touch -t 202509160900 "$TEST_DIR/src/processor.js"

    run tdd_checker_hook
    [ "$status" -eq 1 ]  # Should detect TDD violation
    [[ "$output" =~ "TDD_VIOLATION" ]]
}

@test "tdd_checker_hook should ignore non-source files" {
    # Red Phase: Function doesn't exist yet - should fail
    export CLAUDE_TOOL="Edit"
    export CLAUDE_FILE_PATHS="$TEST_DIR/README.md"

    run tdd_checker_hook
    [ "$status" -eq 0 ]  # Should be ignored
    [[ "$output" =~ "IGNORED" ]]
}

@test "tdd_checker_hook should handle multiple files" {
    # Red Phase: Function doesn't exist yet - should fail
    export CLAUDE_TOOL="MultiEdit"
    export CLAUDE_FILE_PATHS="$TEST_DIR/src/file1.js $TEST_DIR/src/file2.py"

    # Setup TDD violation for file1, compliance for file2
    touch -t 202509160800 "$TEST_DIR/__tests__/file1.test.js"
    touch -t 202509160900 "$TEST_DIR/src/file1.js"

    touch -t 202509160900 "$TEST_DIR/tests/test_file2.py"
    touch -t 202509160800 "$TEST_DIR/src/file2.py"

    run tdd_checker_hook
    [ "$status" -eq 1 ]  # Should have mixed results
    [[ "$output" =~ "TDD_VIOLATION.*file1.js" ]]
    [[ "$output" =~ "TDD_COMPLIANT.*file2.py" ]]
}

# ==============================================================================
# Configuration and Settings Tests
# ==============================================================================

@test "load_tdd_checker_config should read configuration file" {
    # Red Phase: Function doesn't exist yet - should fail
    cat > "$TEST_DIR/.claude/tdd_checker_config.json" << EOF
{
    "check_tdd_compliance": true,
    "check_design_compliance": false,
    "warning_threshold": "medium",
    "ignored_patterns": ["*.test.js", "*.spec.ts"]
}
EOF

    run load_tdd_checker_config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CONFIG_LOADED" ]]
}

@test "should_ignore_file should respect ignore patterns" {
    # Red Phase: Function doesn't exist yet - should fail
    export TDD_IGNORE_PATTERNS="*.test.js *.spec.ts __tests__/*"

    run should_ignore_file "$TEST_DIR/__tests__/sample.test.js"
    [ "$status" -eq 0 ]  # Should be ignored

    run should_ignore_file "$TEST_DIR/src/sample.js"
    [ "$status" -eq 1 ]  # Should not be ignored
}

# ==============================================================================
# Error Handling Tests
# ==============================================================================

@test "tdd_checker should handle file permission errors gracefully" {
    # Red Phase: Function doesn't exist yet - should fail
    touch "$TEST_DIR/src/restricted.js"
    chmod 000 "$TEST_DIR/src/restricted.js"

    run perform_tdd_check "$TEST_DIR/src/restricted.js"
    [ "$status" -eq 3 ]  # Error status
    [[ "$output" =~ "PERMISSION_ERROR" ]]

    # Cleanup
    chmod 644 "$TEST_DIR/src/restricted.js"
}

@test "tdd_checker should handle corrupted log file" {
    # Red Phase: Function doesn't exist yet - should fail
    echo "corrupted log content" > "$TDD_CHECKER_LOG"
    chmod 444 "$TDD_CHECKER_LOG"

    run generate_warning "TEST" "test.js" "test message"
    [ "$status" -eq 0 ]  # Should handle gracefully
    [[ "$output" =~ "LOG_ERROR" ]]

    # Cleanup
    chmod 644 "$TDD_CHECKER_LOG"
}

# Helper test to verify test environment is set up correctly
@test "test environment should be properly initialized" {
    [ -d "$TEST_DIR" ]
    [ -d "$TEST_DIR/.claude/logs" ]
    [ -d "$TEST_DIR/src" ]
    [ -d "$TEST_DIR/tests" ]
    [ -d "$TEST_DIR/__tests__" ]
    [ -d "$TEST_DIR/docs" ]
}
# ==============================================================================
# Extended Language Support Tests (Red Phase - Should Fail Initially)
# ==============================================================================

@test "find_test_file should find Rust test file with proper naming" {
    # Red Phase: Enhanced Rust support
    mkdir -p "$TEST_DIR/src/lib"
    mkdir -p "$TEST_DIR/tests/integration"
    touch "$TEST_DIR/src/lib/config.rs"
    touch "$TEST_DIR/tests/integration/config_test.rs"

    run find_test_file "$TEST_DIR/src/lib/config.rs"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "config_test.rs" ]]
}

@test "find_test_file should find Java test with Maven structure" {
    # Red Phase: Maven project structure support
    mkdir -p "$TEST_DIR/src/main/java/com/example"
    mkdir -p "$TEST_DIR/src/test/java/com/example"
    touch "$TEST_DIR/src/main/java/com/example/UserService.java"
    touch "$TEST_DIR/src/test/java/com/example/UserServiceTest.java"

    run find_test_file "$TEST_DIR/src/main/java/com/example/UserService.java"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "UserServiceTest.java" ]]
}

@test "find_test_file should find C++ test file" {
    # Red Phase: C++ support
    mkdir -p "$TEST_DIR/src" "$TEST_DIR/tests"
    touch "$TEST_DIR/src/calculator.cpp"
    touch "$TEST_DIR/tests/test_calculator.cpp"

    run find_test_file "$TEST_DIR/src/calculator.cpp"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_calculator.cpp" ]]
}

@test "find_test_file should find PHP unit test file" {
    # Red Phase: PHP support
    mkdir -p "$TEST_DIR/src" "$TEST_DIR/tests/Unit"
    touch "$TEST_DIR/src/UserModel.php"
    touch "$TEST_DIR/tests/Unit/UserModelTest.php"

    run find_test_file "$TEST_DIR/src/UserModel.php"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "UserModelTest.php" ]]
}

@test "find_test_file should prefer closest test file location" {
    # Red Phase: Priority-based test file discovery
    mkdir -p "$TEST_DIR/src" "$TEST_DIR/tests" "$TEST_DIR/__tests__"
    touch "$TEST_DIR/src/service.js"
    touch "$TEST_DIR/tests/service.test.js"
    touch "$TEST_DIR/__tests__/service.test.js"

    run find_test_file "$TEST_DIR/src/service.js"
    [ "$status" -eq 0 ]
    # Should prefer __tests__ over tests directory
    [[ "$output" =~ "__tests__/service.test.js" ]]
}

# ==============================================================================
# Advanced TDD Compliance Tests (Red Phase)
# ==============================================================================

@test "perform_tdd_check should handle symlinked files correctly" {
    # Red Phase: Symlink handling
    touch "$TEST_DIR/src/original.js"
    touch "$TEST_DIR/__tests__/original.test.js"
    ln -s "$TEST_DIR/src/original.js" "$TEST_DIR/src/symlink.js"

    run perform_tdd_check "$TEST_DIR/src/symlink.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TDD_COMPLIANT" ]]
}

@test "perform_tdd_check should handle files with spaces in names" {
    # Red Phase: Special characters in filenames
    touch "$TEST_DIR/src/my file.js"
    touch "$TEST_DIR/__tests__/my file.test.js"

    run perform_tdd_check "$TEST_DIR/src/my file.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TDD_COMPLIANT" ]]
}

@test "perform_tdd_check should detect microsecond-level timestamp differences" {
    # Red Phase: High precision timestamp checking
    touch "$TEST_DIR/src/precise.js"
    sleep 0.1
    touch "$TEST_DIR/__tests__/precise.test.js"

    run perform_tdd_check "$TEST_DIR/src/precise.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TDD_COMPLIANT" ]]
}

@test "perform_tdd_check should handle network-mounted filesystems" {
    # Red Phase: Network filesystem compatibility
    skip "Requires network filesystem setup"
    # This test would verify behavior on NFS, CIFS, etc.
}

# ==============================================================================
# Enhanced Design Compliance Tests (Red Phase)
# ==============================================================================

@test "check_design_compliance should find design in multiple formats" {
    # Red Phase: Support multiple documentation formats
    mkdir -p "$TEST_DIR/docs/design" "$TEST_DIR/docs/specs"
    echo "# User API" > "$TEST_DIR/docs/design/user_api.md"
    echo "openapi: 3.0.0" > "$TEST_DIR/docs/specs/user_api.yaml"
    echo "syntax proto3;" > "$TEST_DIR/docs/specs/user_api.proto"

    run check_design_compliance "$TEST_DIR/src/user_api.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DESIGN_DOC_FOUND" ]]
    [[ "$output" =~ "MULTIPLE_FORMATS_DETECTED" ]]
}

@test "check_design_compliance should validate API contract consistency" {
    # Red Phase: Deep API analysis
    mkdir -p "$TEST_DIR/docs/api"
    cat > "$TEST_DIR/docs/api/user_service.md" << 'DESIGN'
# User Service API

## Methods
- getUserById(id: string): Promise<User>
- createUser(data: UserData): Promise<User>
- deleteUser(id: string): Promise<void>
DESIGN

    cat > "$TEST_DIR/src/user_service.js" << 'IMPL'
class UserService {
    async getUserById(id) { return null; }
    async createUser(data) { return null; }
    // Missing: deleteUser method
}
IMPL

    run check_design_compliance "$TEST_DIR/src/user_service.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "MISSING_METHOD.*deleteUser" ]]
}

@test "check_design_compliance should detect design version mismatches" {
    # Red Phase: Version compatibility checking
    mkdir -p "$TEST_DIR/docs/versions"
    echo "version: 2.0.0" > "$TEST_DIR/docs/versions/api_v2.md"
    echo "// API version: 1.0.0" > "$TEST_DIR/src/api.js"

    run check_design_compliance "$TEST_DIR/src/api.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "VERSION_MISMATCH" ]]
}

@test "check_design_compliance should validate against OpenAPI specifications" {
    # Red Phase: OpenAPI integration
    mkdir -p "$TEST_DIR/docs/openapi"
    cat > "$TEST_DIR/docs/openapi/users.yaml" << 'OPENAPI'
openapi: 3.0.0
paths:
  /users/{id}:
    get:
      operationId: getUserById
OPENAPI

    echo "function getUserById() {}" > "$TEST_DIR/src/users_api.js"

    run check_design_compliance "$TEST_DIR/src/users_api.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OPENAPI_COMPLIANT" ]]
}

# ==============================================================================
# Complex Warning Generation Tests (Red Phase)
# ==============================================================================

@test "generate_warning should include contextual code snippets" {
    # Red Phase: Enhanced warning details
    echo "function badCode() { /* violation */ }" > "$TEST_DIR/src/bad.js"

    run generate_warning "CODE_QUALITY" "$TEST_DIR/src/bad.js" "Poor implementation detected"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CODE_SNIPPET:" ]]
    [[ "$output" =~ "function badCode" ]]
}

@test "generate_warning should suggest specific remediation actions" {
    # Red Phase: Actionable warnings
    run generate_warning "TDD_VIOLATION" "$TEST_DIR/src/test.js" "Test written after implementation"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SUGGESTED_ACTION:" ]]
    [[ "$output" =~ "Write test first" ]]
}

@test "generate_warning should categorize warnings by severity" {
    # Red Phase: Warning severity levels
    run generate_warning "CRITICAL" "$TEST_DIR/src/security.js" "Security vulnerability detected"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SEVERITY: CRITICAL" ]]
    [[ "$output" =~ "🚨" ]] # Critical emoji indicator
}

@test "generate_warning should aggregate related warnings" {
    # Red Phase: Warning aggregation
    generate_warning "TDD_VIOLATION" "$TEST_DIR/src/file1.js" "Issue 1" > /dev/null
    generate_warning "TDD_VIOLATION" "$TEST_DIR/src/file2.js" "Issue 2" > /dev/null

    run generate_warning "TDD_VIOLATION" "$TEST_DIR/src/file3.js" "Issue 3"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AGGREGATED_COUNT: 3" ]]
}

# ==============================================================================
# Advanced Hook Integration Tests (Red Phase)
# ==============================================================================

@test "tdd_checker_hook should handle concurrent file modifications" {
    # Red Phase: Concurrency handling
    export CLAUDE_TOOL="MultiEdit"
    export CLAUDE_FILE_PATHS="$TEST_DIR/src/concurrent1.js $TEST_DIR/src/concurrent2.js"

    # Create files concurrently (simulated)
    touch "$TEST_DIR/src/concurrent1.js" "$TEST_DIR/src/concurrent2.js"
    touch "$TEST_DIR/__tests__/concurrent1.test.js" "$TEST_DIR/__tests__/concurrent2.test.js"

    run tdd_checker_hook
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CONCURRENCY_HANDLED" ]]
}

@test "tdd_checker_hook should integrate with IDE notifications" {
    # Red Phase: IDE integration
    export CLAUDE_IDE="vscode"
    export CLAUDE_TOOL="Edit"
    export CLAUDE_FILE_PATHS="$TEST_DIR/src/ide_test.js"

    touch "$TEST_DIR/src/ide_test.js"

    run tdd_checker_hook
    [ "$status" -eq 0 ]
    [[ "$output" =~ "IDE_NOTIFICATION_SENT" ]]
}

@test "tdd_checker_hook should respect git hooks integration" {
    # Red Phase: Git hooks compatibility
    mkdir -p "$TEST_DIR/.git/hooks"
    echo '#!/bin/bash' > "$TEST_DIR/.git/hooks/pre-commit"
    chmod +x "$TEST_DIR/.git/hooks/pre-commit"

    export CLAUDE_TOOL="Edit"
    export CLAUDE_FILE_PATHS="$TEST_DIR/src/git_test.js"

    run tdd_checker_hook
    [ "$status" -eq 0 ]
    [[ "$output" =~ "GIT_HOOKS_COMPATIBLE" ]]
}

@test "tdd_checker_hook should handle batch operations efficiently" {
    # Red Phase: Performance with many files
    export CLAUDE_TOOL="BatchEdit"
    local files=""

    # Create 50 test files
    for i in {1..50}; do
        touch "$TEST_DIR/src/batch_$i.js"
        touch "$TEST_DIR/__tests__/batch_$i.test.js"
        files="$files $TEST_DIR/src/batch_$i.js"
    done

    export CLAUDE_FILE_PATHS="$files"

    local start_time=$(date +%s.%N)
    run tdd_checker_hook
    local end_time=$(date +%s.%N)

    [ "$status" -eq 0 ]
    # Should complete within reasonable time (< 2 seconds for 50 files)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1.0")
    [[ $(echo "$duration < 2.0" | bc -l 2>/dev/null || echo "1") -eq 1 ]]
    [[ "$output" =~ "BATCH_PROCESSING_OPTIMIZED" ]]
}

# ==============================================================================
# Configuration Management Tests (Red Phase)
# ==============================================================================

@test "load_tdd_checker_config should handle malformed JSON gracefully" {
    # Red Phase: Robust config parsing
    cat > "$TEST_DIR/.claude/tdd_checker_config.json" << 'MALFORMED'
{
    "check_tdd_compliance": true,
    "invalid_syntax": [missing_bracket,
    "warning_threshold": "medium"
MALFORMED

    run load_tdd_checker_config
    [ "$status" -eq 0 ]  # Should handle gracefully
    [[ "$output" =~ "CONFIG_PARSE_ERROR" ]]
    [[ "$output" =~ "USING_DEFAULTS" ]]
}

@test "load_tdd_checker_config should support environment variable overrides" {
    # Red Phase: Environment variable precedence
    export TDD_CHECK_ENABLED="false"
    export TDD_WARNING_THRESHOLD="strict"

    cat > "$TEST_DIR/.claude/tdd_checker_config.json" << 'CONFIG'
{
    "check_tdd_compliance": true,
    "warning_threshold": "medium"
}
CONFIG

    run load_tdd_checker_config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ENV_OVERRIDE_APPLIED" ]]
    # Environment should take precedence
    [ "$TDD_CHECK_ENABLED" = "false" ]
    [ "$TDD_WARNING_THRESHOLD" = "strict" ]
}

@test "load_tdd_checker_config should validate configuration values" {
    # Red Phase: Config validation
    cat > "$TEST_DIR/.claude/tdd_checker_config.json" << 'INVALID'
{
    "check_tdd_compliance": "invalid_boolean",
    "warning_threshold": "invalid_level",
    "ignored_patterns": "not_an_array"
}
INVALID

    run load_tdd_checker_config
    [ "$status" -eq 1 ]
    [[ "$output" =~ "CONFIG_VALIDATION_FAILED" ]]
    [[ "$output" =~ "invalid_boolean.*warning_threshold.*not_an_array" ]]
}

@test "should_ignore_file should handle complex glob patterns" {
    # Red Phase: Advanced pattern matching
    export TDD_IGNORE_PATTERNS="**/*.generated.* **/node_modules/** **/{build,dist}/**"

    run should_ignore_file "$TEST_DIR/src/auto.generated.js"
    [ "$status" -eq 0 ]  # Should be ignored

    run should_ignore_file "$TEST_DIR/node_modules/lib/index.js"
    [ "$status" -eq 0 ]  # Should be ignored

    run should_ignore_file "$TEST_DIR/dist/app.js"
    [ "$status" -eq 0 ]  # Should be ignored

    run should_ignore_file "$TEST_DIR/src/regular.js"
    [ "$status" -eq 1 ]  # Should not be ignored
}

# ==============================================================================
# Error Recovery and Resilience Tests (Red Phase)
# ==============================================================================

@test "tdd_checker should recover from temporary file system errors" {
    # Red Phase: Resilience testing
    touch "$TEST_DIR/src/temp_error.js"

    # Simulate temporary filesystem issue
    chmod 000 "$TEST_DIR/src"

    run perform_tdd_check "$TEST_DIR/src/temp_error.js"
    [ "$status" -eq 3 ]
    [[ "$output" =~ "TEMP_ERROR_DETECTED" ]]

    # Restore permissions and retry
    chmod 755 "$TEST_DIR/src"

    run perform_tdd_check "$TEST_DIR/src/temp_error.js"
    [ "$status" -eq 2 ]  # Should recover to normal operation
}

@test "tdd_checker should handle disk space exhaustion gracefully" {
    # Red Phase: Resource exhaustion handling
    skip "Requires special disk space simulation"
    # This would test behavior when disk is full
}

@test "tdd_checker should handle memory pressure conditions" {
    # Red Phase: Memory management
    # Simulate processing of very large files
    dd if=/dev/zero of="$TEST_DIR/src/large_file.js" bs=1M count=10 2>/dev/null
    echo "// Large JavaScript file" >> "$TEST_DIR/src/large_file.js"

    run perform_tdd_check "$TEST_DIR/src/large_file.js"
    [ "$status" -ne 137 ]  # Should not be killed by OOM
    [[ "$output" =~ "LARGE_FILE_HANDLED" ]]
}

# ==============================================================================
# Integration with External Tools Tests (Red Phase)
# ==============================================================================

@test "tdd_checker should integrate with ESLint for quality checks" {
    # Red Phase: External tool integration
    echo "function badCode ( ) { var unused = 1 }" > "$TEST_DIR/src/linting.js"

    # Simulate ESLint availability
    export PATH="$TEST_DIR/mock_tools:$PATH"
    mkdir -p "$TEST_DIR/mock_tools"
    echo '#!/bin/bash' > "$TEST_DIR/mock_tools/eslint"
    echo 'echo "1:1 error Unexpected token"' >> "$TEST_DIR/mock_tools/eslint"
    chmod +x "$TEST_DIR/mock_tools/eslint"

    run perform_tdd_check "$TEST_DIR/src/linting.js"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "LINTING_VIOLATIONS" ]]
}

@test "tdd_checker should integrate with test coverage tools" {
    # Red Phase: Coverage integration
    touch "$TEST_DIR/src/coverage.js"
    touch "$TEST_DIR/__tests__/coverage.test.js"

    # Mock coverage report
    mkdir -p "$TEST_DIR/coverage"
    echo '{"coverage": 85, "threshold": 80}' > "$TEST_DIR/coverage/coverage-summary.json"

    run perform_tdd_check "$TEST_DIR/src/coverage.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "COVERAGE_SUFFICIENT.*85%" ]]
}

@test "tdd_checker should work with monorepo structures" {
    # Red Phase: Monorepo support
    mkdir -p "$TEST_DIR/packages/"{frontend,backend}"/src"
    mkdir -p "$TEST_DIR/packages/"{frontend,backend}"/__tests__"

    echo "export const api = {}" > "$TEST_DIR/packages/frontend/src/api.js"
    echo "test('api exists', () => {})" > "$TEST_DIR/packages/frontend/__tests__/api.test.js"

    export CLAUDE_PROJECT_DIR="$TEST_DIR/packages/frontend"

    run perform_tdd_check "$TEST_DIR/packages/frontend/src/api.js"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "MONOREPO_CONTEXT_DETECTED" ]]
}

# ==============================================================================
# Performance and Scalability Tests (Red Phase)
# ==============================================================================

@test "tdd_checker should cache test file discovery results" {
    # Red Phase: Performance optimization
    touch "$TEST_DIR/src/cached.js"
    touch "$TEST_DIR/__tests__/cached.test.js"

    # First run - should populate cache
    local start1=$(date +%s.%N)
    run find_test_file "$TEST_DIR/src/cached.js"
    local end1=$(date +%s.%N)

    # Second run - should use cache
    local start2=$(date +%s.%N)
    run find_test_file "$TEST_DIR/src/cached.js"
    local end2=$(date +%s.%N)

    [ "$status" -eq 0 ]
    # Second run should be faster (cached)
    local duration1=$(echo "$end1 - $start1" | bc -l 2>/dev/null || echo "1.0")
    local duration2=$(echo "$end2 - $start2" | bc -l 2>/dev/null || echo "1.0")

    # Cache should provide speedup
    [[ $(echo "$duration2 < $duration1" | bc -l 2>/dev/null || echo "1") -eq 1 ]]
    [[ "$output" =~ "CACHE_HIT" ]]
}

@test "tdd_checker should handle deep directory structures efficiently" {
    # Red Phase: Deep nesting performance
    local deep_path="$TEST_DIR/very/deep/nested/directory/structure/that/goes/many/levels/down"
    mkdir -p "$deep_path/src" "$deep_path/__tests__"

    touch "$deep_path/src/deep.js"
    touch "$deep_path/__tests__/deep.test.js"

    local start_time=$(date +%s.%N)
    run find_test_file "$deep_path/src/deep.js"
    local end_time=$(date +%s.%N)

    [ "$status" -eq 0 ]
    # Should complete within reasonable time
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1.0")
    [[ $(echo "$duration < 0.1" | bc -l 2>/dev/null || echo "1") -eq 1 ]]
}

# Helper test to verify extended test environment
@test "extended test environment should support all languages" {
    [ -d "$TEST_DIR" ]

    # Verify we can create language-specific directory structures
    mkdir -p "$TEST_DIR/src/main/java/com/example"
    mkdir -p "$TEST_DIR/tests/integration"
    mkdir -p "$TEST_DIR/docs/openapi"

    [ -d "$TEST_DIR/src/main/java/com/example" ]
    [ -d "$TEST_DIR/tests/integration" ]
    [ -d "$TEST_DIR/docs/openapi" ]
}
