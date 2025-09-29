#!/bin/bash

# TDD Check Script
# Purpose: テスト未作成時の警告とスキップ理由の記録

# Configuration
TDD_CONFIG_FILE=".claude/settings.json"
TDD_SKIP_LOG=".claude/tdd-skip-reasons.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Read TDD settings from JSON
if [ -f "$TDD_CONFIG_FILE" ]; then
    ENFORCEMENT=$(jq -r '.tdd.enforcement // "recommended"' "$TDD_CONFIG_FILE" 2>/dev/null)
    SKIP_REASON_REQUIRED=$(jq -r '.tdd.skipReasonRequired // true' "$TDD_CONFIG_FILE" 2>/dev/null)
    TEST_FIRST_WARNING=$(jq -r '.tdd.testFirstWarning // true' "$TDD_CONFIG_FILE" 2>/dev/null)
else
    ENFORCEMENT="recommended"
    SKIP_REASON_REQUIRED="true"
    TEST_FIRST_WARNING="true"
fi

# Function to check if test file exists
check_test_file() {
    local source_file="$1"
    local base_name=$(basename "$source_file" | sed 's/\.[^.]*$//')
    local dir_name=$(dirname "$source_file")

    # Common test file patterns
    local test_patterns=(
        "test_${base_name}.py"
        "${base_name}_test.py"
        "${base_name}.test.js"
        "${base_name}.test.ts"
        "${base_name}.spec.js"
        "${base_name}.spec.ts"
        "test${base_name}.java"
        "${base_name}Test.java"
    )

    # Check in common test directories
    local test_dirs=(
        "tests"
        "test"
        "__tests__"
        "spec"
        "../tests"
        "../test"
        "../__tests__"
    )

    for test_dir in "${test_dirs[@]}"; do
        for pattern in "${test_patterns[@]}"; do
            local test_path="${dir_name}/${test_dir}/${pattern}"
            if [ -f "$test_path" ]; then
                return 0
            fi
        done
    done

    return 1
}

# Function to log TDD skip reason
log_skip_reason() {
    local reason="$1"
    local file="$2"

    echo "[$TIMESTAMP] File: $file | Reason: $reason" >> "$TDD_SKIP_LOG"
}

# Function to display warning
show_warning() {
    local message="$1"
    echo "⚠️  TDD Warning: $message" >&2
}

# Main check logic
main() {
    local file_path="$1"
    local operation="$2"

    # Skip if not a source code file
    case "$file_path" in
        *.md|*.txt|*.json|*.yml|*.yaml|*.sh|*.log)
            return 0
            ;;
    esac

    # Check if test file exists
    if ! check_test_file "$file_path"; then
        if [ "$TEST_FIRST_WARNING" = "true" ]; then
            show_warning "No test found for $file_path"

            # If enforcement is strict, require a reason
            if [ "$ENFORCEMENT" = "strict" ]; then
                echo "TDD Enforcement: Please provide a reason for skipping test creation."
                echo "Options:"
                echo "  1) Prototype/Experimental code"
                echo "  2) Simple configuration change"
                echo "  3) Refactoring existing tested code"
                echo "  4) Documentation or non-functional change"
                echo "  5) Other (please specify)"
                echo ""
                echo -n "Select reason (1-5) or press Enter to cancel: "
                read -r reason_choice

                case "$reason_choice" in
                    1) log_skip_reason "Prototype/Experimental" "$file_path" ;;
                    2) log_skip_reason "Configuration change" "$file_path" ;;
                    3) log_skip_reason "Refactoring" "$file_path" ;;
                    4) log_skip_reason "Non-functional" "$file_path" ;;
                    5)
                        echo -n "Please specify reason: "
                        read -r custom_reason
                        log_skip_reason "$custom_reason" "$file_path"
                        ;;
                    *)
                        echo "Operation cancelled. Please create tests first."
                        return 1
                        ;;
                esac
            elif [ "$SKIP_REASON_REQUIRED" = "true" ]; then
                # Automatic logging for recommended mode
                log_skip_reason "Test not created (recommended mode)" "$file_path"
            fi
        fi
    fi

    return 0
}

# Execute if called with arguments
if [ $# -ge 1 ]; then
    main "$@"
fi
