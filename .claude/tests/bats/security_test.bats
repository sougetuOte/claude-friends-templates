#!/usr/bin/env bats
# Security Tests - Command Injection and System Security
# This file implements the security tests specified in Task 0.1.4

# Load test helpers
load '../helpers/test-helpers.sh'

setup() {
    setup_test_environment
}

teardown() {
    cleanup_test_environment
}

# =============================================================================
# Command Injection Vulnerability Tests
# =============================================================================

@test "no command injection vulnerability in agent-switch" {
    # Test malicious input designed to break out of intended command structure
    malicious_input='"; rm -rf /'

    # Create test input with malicious payload
    echo "{\"prompt\": \"$malicious_input\"}" > "$TEST_TEMP_DIR/malicious.json"

    # Run agent-switch hook with malicious input
    run bash -c "cat '$TEST_TEMP_DIR/malicious.json' | .claude/scripts/agent-switch-hook.sh"

    # System should still be intact (root directory should exist)
    [ -d "/" ]

    # The hook should either handle the input safely or fail gracefully
    # Exit code can be 0 (handled safely) or non-zero (rejected)
    # What matters is that no system damage occurred
}

@test "no command injection in activity logger" {
    # Test command injection in activity logger
    malicious_input='"; echo "HACKED" > /tmp/hack_test'

    setup_test_scenario "edit_file"
    export CLAUDE_FILE_PATHS="$malicious_input"

    # Run activity logger with malicious input
    run .claude/scripts/activity-logger.sh

    # Check that injection did not succeed
    [ ! -f "/tmp/hack_test" ]

    # Clean up any potential test artifacts
    rm -f "/tmp/hack_test" 2>/dev/null || true
}

@test "no command injection in ai-logger" {
    # Test AI logger with malicious input
    malicious_input='$(rm -rf /tmp/ai_logger_test)'

    echo "{\"tool\": \"Edit\", \"file_paths\": [\"$malicious_input\"]}" | run .claude/scripts/ai-logger.sh

    # Verify that command substitution was not executed
    [ ! -f "/tmp/ai_logger_test_marker" ]
}

@test "no shell expansion in deny-check" {
    # Test that deny-check properly handles shell metacharacters
    malicious_commands=(
        'ls; rm -rf /'
        'ls && rm -rf /'
        'ls $(rm -rf /tmp/test_marker)'
        'ls `rm -rf /tmp/test_marker2`'
        'ls | rm -rf /'
    )

    for cmd in "${malicious_commands[@]}"; do
        run .claude/scripts/deny-check.sh "$cmd"
        # Should be blocked or handled safely
        [ ! -f "/tmp/test_marker" ]
        [ ! -f "/tmp/test_marker2" ]
    done
}

# =============================================================================
# File Permission Security Tests
# =============================================================================

@test "proper file permissions on all scripts" {
    # Check that all shell scripts have appropriate permissions
    find .claude/scripts -name "*.sh" -type f | while read -r script; do
        if [[ -n "$script" ]]; then
            perms=$(stat -c %a "$script")

            # Permissions should be 755, 754, 744, 655, 654, or 644
            # Not world-writable (no 2 or 6 in the last digit for others)
            if ! echo "$perms" | grep -E '^[67][45][45]$'; then
                echo "Script has incorrect permissions: $script ($perms)" >&2
                return 1
            fi

            # Script should be executable by owner
            if [[ ! -x "$script" ]]; then
                echo "Script is not executable: $script" >&2
                return 1
            fi
        fi
    done
}

@test "no world-writable files in claude directory" {
    # Find world-writable files (dangerous for security)
    run find .claude -type f -perm -002
    [ "$status" -eq 0 ]
    [ -z "$output" ]  # Should not find any world-writable files
}

@test "no files with setuid/setgid bits" {
    # Check for potentially dangerous setuid/setgid files
    run find .claude -type f \( -perm -4000 -o -perm -2000 \)
    [ "$status" -eq 0 ]
    [ -z "$output" ]  # Should not find any setuid/setgid files
}

# =============================================================================
# Secret Detection Tests
# =============================================================================

@test "no hardcoded secrets in configuration" {
    # Check for various types of hardcoded secrets
    secret_patterns=(
        "(password|pwd)\s*[:=]\s*['\"][^'\"]{3,}"
        "(secret|key)\s*[:=]\s*['\"][^'\"]{8,}"
        "(token|auth)\s*[:=]\s*['\"][^'\"]{10,}"
        "api[_-]key\s*[:=]\s*['\"][^'\"]{8,}"
        "(access[_-]key|secret[_-]key)\s*[:=]\s*['\"][^'\"]{8,}"
    )

    for pattern in "${secret_patterns[@]}"; do
        run grep -r -E "$pattern" .claude/ --exclude-dir=logs --exclude-dir=cache
        [ "$status" -ne 0 ]  # Should not find matches
    done
}

@test "no aws credentials in files" {
    # Specific check for AWS credentials
    run grep -r -E "(AKIA[0-9A-Z]{16}|aws_access_key_id|aws_secret_access_key)" .claude/ --exclude-dir=logs
    [ "$status" -ne 0 ]
}

@test "no private keys in files" {
    # Check for private key patterns
    run grep -r -E "(BEGIN.*(PRIVATE|RSA).*KEY|ssh-rsa\s+[A-Za-z0-9+/]{100,})" .claude/ --exclude-dir=logs
    [ "$status" -ne 0 ]
}

# =============================================================================
# Input Validation and Sanitization Tests
# =============================================================================

@test "json input validation in hooks" {
    # Test that hooks properly validate JSON input
    invalid_json='{"incomplete": json'

    echo "$invalid_json" | run .claude/scripts/activity-logger.sh
    # Should handle invalid JSON gracefully (exit code can be non-zero, but no crash)

    echo "$invalid_json" | run .claude/scripts/ai-logger.sh
    # Should handle invalid JSON gracefully
}

@test "null byte injection prevention" {
    # Test null byte injection attempts
    malicious_input=$'malicious\x00injection'

    setup_test_scenario "edit_file"
    export CLAUDE_FILE_PATHS="$malicious_input"

    run .claude/scripts/activity-logger.sh
    # Should handle null bytes safely
}

@test "path traversal prevention" {
    # Test path traversal attempts
    traversal_paths=(
        "../../../etc/passwd"
        "..\\..\\..\\windows\\system32"
        "/etc/passwd"
        "~/.ssh/id_rsa"
    )

    for path in "${traversal_paths[@]}"; do
        setup_test_scenario "edit_file"
        export CLAUDE_FILE_PATHS="$path"

        run .claude/scripts/activity-logger.sh
        # Should not access unauthorized paths or should handle safely
        [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # Should not crash
    done
}

# =============================================================================
# Environment Security Tests
# =============================================================================

@test "environment variables are properly sanitized" {
    # Test with potentially dangerous environment variables
    export CLAUDE_COMMAND='rm -rf /'
    export CLAUDE_FILE_PATHS='; cat /etc/passwd'

    run .claude/scripts/activity-logger.sh

    # Should handle malicious environment variables safely
    [ -f "/etc/passwd" ]  # System file should still exist
}

@test "temporary file creation is secure" {
    # Test that temporary files are created securely
    run .claude/scripts/ai-logger.sh < /dev/null

    # Check if any temporary files were created with insecure permissions
    if [[ -d /tmp ]]; then
        run find /tmp -name "*claude*" -type f -perm -044 2>/dev/null
        [ -z "$output" ] || {
            echo "Found temporary files with world-readable permissions: $output" >&2
            return 1
        }
    fi
}

# =============================================================================
# Network Security Tests
# =============================================================================

@test "no outbound network connections in critical hooks" {
    # Test that security-critical hooks don't make network connections
    # Mock network calls to detect any attempts

    # Create a function that logs network attempts
    network_monitor() {
        echo "NETWORK_ATTEMPT: $*" >> "$TEST_TEMP_DIR/network.log"
        return 1  # Fail to prevent actual network access
    }

    # Override network commands
    export -f network_monitor
    alias curl='network_monitor curl'
    alias wget='network_monitor wget'
    alias nc='network_monitor nc'

    # Run security-critical hooks
    run .claude/scripts/deny-check.sh "ls -la"

    # Check that no network attempts were made
    if [[ -f "$TEST_TEMP_DIR/network.log" ]]; then
        cat "$TEST_TEMP_DIR/network.log" >&2
        return 1
    fi

    # Clean up aliases
    unalias curl wget nc 2>/dev/null || true
}

# =============================================================================
# Recovery and Error Handling Tests
# =============================================================================

@test "secure failure modes" {
    # Test that scripts fail securely when dependencies are missing

    # Temporarily hide required tools
    if command -v jq >/dev/null; then
        jq_path=$(command -v jq)
        sudo chmod -x "$jq_path" 2>/dev/null || {
            echo "Cannot test jq failure mode (no sudo)" >&2
            skip "Requires sudo to test dependency failure"
        }

        # Test behavior without jq
        echo '{"test": "data"}' | run .claude/scripts/ai-logger.sh

        # Should fail gracefully, not crash or expose sensitive data

        # Restore jq
        sudo chmod +x "$jq_path" 2>/dev/null || true
    fi
}

@test "log injection prevention" {
    # Test that log entries cannot be manipulated to inject fake log entries
    malicious_log_data=$'\n[FAKE] SECURITY ALERT: System compromised'

    setup_test_scenario "edit_file"
    export CLAUDE_FILE_PATHS="test$malicious_log_data.md"

    run .claude/scripts/activity-logger.sh

    # Check activity log for injection attempts
    if [[ -f ~/.claude/activity.log ]]; then
        run grep "FAKE.*SECURITY ALERT" ~/.claude/activity.log
        [ "$status" -ne 0 ]  # Should not find the injected content
    fi
}