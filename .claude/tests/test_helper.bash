#!/usr/bin/env bash
# Bats Test Helper Functions
# Provides common utilities for Bats test suites
#
# Version: 1.0.0
# Compatible with: bats-core, bats-support, bats-assert

# Load bats libraries if available
if [[ -d "${BATS_TEST_DIRNAME}/../../node_modules" ]]; then
    load "../../node_modules/bats-support/load"
    load "../../node_modules/bats-assert/load"
elif command -v bats-support >/dev/null 2>&1; then
    # System-installed bats libraries
    :
fi

# ============================================================================
# Test Environment Setup
# ============================================================================

# setup_test_workspace - Create isolated test workspace
# Usage: setup_test_workspace
setup_test_workspace() {
    TEST_WORKSPACE="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_WORKSPACE"
    export TEST_DIR="$TEST_WORKSPACE"

    # Create standard .claude directory structure
    mkdir -p "$TEST_WORKSPACE/.claude/agents/planner"
    mkdir -p "$TEST_WORKSPACE/.claude/agents/builder"
    mkdir -p "$TEST_WORKSPACE/.claude/scripts"
    mkdir -p "$TEST_WORKSPACE/.claude/logs"
    mkdir -p "$TEST_WORKSPACE/.claude/shared"
    mkdir -p "$TEST_WORKSPACE/memo"

    # Initialize git repository (optional, for git-dependent tests)
    if command -v git >/dev/null 2>&1; then
        (
            cd "$TEST_WORKSPACE"
            git init >/dev/null 2>&1
            git config user.email "test@example.com"
            git config user.name "Test User"
        )
    fi
}

# teardown_test_workspace - Clean up test workspace
# Usage: teardown_test_workspace
teardown_test_workspace() {
    if [[ -n "$TEST_WORKSPACE" ]] && [[ -d "$TEST_WORKSPACE" ]]; then
        rm -rf "$TEST_WORKSPACE"
    fi
    unset CLAUDE_PROJECT_DIR
    unset TEST_DIR
    unset TEST_WORKSPACE
}

# ============================================================================
# File Creation Helpers
# ============================================================================

# create_mock_notes - Create mock notes.md files
# Usage: create_mock_notes <agent> [content]
create_mock_notes() {
    local agent="${1:-planner}"
    local content="${2:-# ${agent^} Notes\n\n## Current Task: Test Task\n}"

    local notes_file="$TEST_WORKSPACE/.claude/agents/$agent/notes.md"
    printf "%b" "$content" > "$notes_file"
}

# create_mock_handover - Create mock handover JSON file
# Usage: create_mock_handover <from_agent> <to_agent> [timestamp]
create_mock_handover() {
    local from_agent="${1:-planner}"
    local to_agent="${2:-builder}"
    local timestamp="${3:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

    local handover_file="$TEST_WORKSPACE/.claude/handover-$(date +%Y%m%d-%H%M%S).json"

    cat > "$handover_file" <<EOF
{
    "metadata": {
        "id": "test-$(uuidgen 2>/dev/null || echo 'test-id')",
        "createdAt": "$timestamp",
        "fromAgent": "$from_agent",
        "toAgent": "$to_agent",
        "schema_version": "2.0.0"
    },
    "summary": {
        "completed_tasks": ["Task 1", "Task 2"],
        "current_task": "Test task for $to_agent",
        "blockers": [],
        "next_steps": ["Step 1", "Step 2"]
    },
    "context": {
        "git_status": "clean",
        "modified_files": [],
        "test_status": "passing"
    }
}
EOF

    echo "$handover_file"
}

# create_phase_todo - Create mock phase-todo.md
# Usage: create_phase_todo
create_phase_todo() {
    local phase_todo="$TEST_WORKSPACE/.claude/shared/phase-todo.md"

    cat > "$phase_todo" <<'EOF'
# Phase Todo

## Current Phase: Testing

- [x] Task 1: Completed task
- [ ] Task 2: Pending task
- [ ] Task 3: Future task
EOF
}

# ============================================================================
# Assertion Helpers
# ============================================================================

# assert_file_exists - Assert that a file exists
# Usage: assert_file_exists <path>
assert_file_exists() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo "Expected file to exist: $file"
        return 1
    }
}

# assert_directory_exists - Assert that a directory exists
# Usage: assert_directory_exists <path>
assert_directory_exists() {
    local dir="$1"
    [[ -d "$dir" ]] || {
        echo "Expected directory to exist: $dir"
        return 1
    }
}

# assert_json_valid - Assert that a file contains valid JSON
# Usage: assert_json_valid <file>
assert_json_valid() {
    local file="$1"

    if command -v jq >/dev/null 2>&1; then
        jq empty "$file" 2>/dev/null || {
            echo "Invalid JSON in file: $file"
            return 1
        }
    else
        # Fallback: basic syntax check
        grep -qE '^\{.*\}$' "$file" || {
            echo "File does not appear to contain JSON: $file"
            return 1
        }
    fi
}

# assert_json_key_exists - Assert that a JSON key exists
# Usage: assert_json_key_exists <file> <key_path>
assert_json_key_exists() {
    local file="$1"
    local key_path="$2"

    if command -v jq >/dev/null 2>&1; then
        local value
        value=$(jq -r "$key_path" "$file" 2>/dev/null)
        [[ "$value" != "null" ]] || {
            echo "JSON key not found: $key_path in $file"
            return 1
        }
    else
        echo "Warning: jq not available, skipping key validation"
    fi
}

# assert_handover_schema - Assert handover file matches schema
# Usage: assert_handover_schema <handover_file>
assert_handover_schema() {
    local file="$1"

    # Check required top-level keys
    assert_json_key_exists "$file" ".metadata"
    assert_json_key_exists "$file" ".summary"
    assert_json_key_exists "$file" ".context"

    # Check metadata keys
    assert_json_key_exists "$file" ".metadata.id"
    assert_json_key_exists "$file" ".metadata.createdAt"
    assert_json_key_exists "$file" ".metadata.fromAgent"
    assert_json_key_exists "$file" ".metadata.toAgent"

    # Check summary keys
    assert_json_key_exists "$file" ".summary.current_task"
    assert_json_key_exists "$file" ".summary.next_steps"
}

# ============================================================================
# Script Execution Helpers
# ============================================================================

# run_script - Run a script with timeout
# Usage: run_script <script_path> [args...]
run_script() {
    local script="$1"
    shift

    if [[ ! -f "$script" ]]; then
        echo "Script not found: $script"
        return 127
    fi

    timeout 30 bash "$script" "$@"
}

# run_python_script - Run a Python script with timeout
# Usage: run_python_script <script_path> [args...]
run_python_script() {
    local script="$1"
    shift

    if [[ ! -f "$script" ]]; then
        echo "Script not found: $script"
        return 127
    fi

    timeout 30 python3 "$script" "$@"
}

# ============================================================================
# Utility Functions
# ============================================================================

# get_latest_handover - Get the path to the latest handover file
# Usage: get_latest_handover
get_latest_handover() {
    ls -t "$TEST_WORKSPACE/.claude"/handover-*.json 2>/dev/null | head -1
}

# count_handover_files - Count handover files
# Usage: count_handover_files
count_handover_files() {
    ls -1 "$TEST_WORKSPACE/.claude"/handover-*.json 2>/dev/null | wc -l
}

# wait_for_file - Wait for a file to be created
# Usage: wait_for_file <path> [timeout_seconds]
wait_for_file() {
    local file="$1"
    local timeout="${2:-10}"
    local elapsed=0

    while [[ ! -f "$file" ]] && [[ $elapsed -lt $timeout ]]; do
        sleep 0.5
        elapsed=$((elapsed + 1))
    done

    [[ -f "$file" ]]
}

# debug_print - Print debug information (only if DEBUG=1)
# Usage: debug_print <message>
debug_print() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# ============================================================================
# Git Helpers
# ============================================================================

# setup_git_repo - Initialize git repo with commits
# Usage: setup_git_repo
setup_git_repo() {
    (
        cd "$TEST_WORKSPACE" || return 1
        git init >/dev/null 2>&1
        git config user.email "test@example.com"
        git config user.name "Test User"

        # Create initial commit
        echo "# Test Project" > README.md
        git add README.md
        git commit -m "Initial commit" >/dev/null 2>&1
    )
}

# create_git_changes - Create uncommitted changes
# Usage: create_git_changes
create_git_changes() {
    (
        cd "$TEST_WORKSPACE" || return 1
        echo "Modified content" >> README.md
        echo "New file" > new_file.txt
    )
}

# ============================================================================
# Performance Testing Helpers
# ============================================================================

# measure_execution_time - Measure script execution time
# Usage: measure_execution_time <command> [args...]
# Returns: Execution time in milliseconds
measure_execution_time() {
    local start_time
    local end_time
    local elapsed_ms

    start_time=$(date +%s%N)
    "$@" >/dev/null 2>&1
    end_time=$(date +%s%N)

    elapsed_ms=$(( (end_time - start_time) / 1000000 ))
    echo "$elapsed_ms"
}

# assert_performance - Assert execution time is below threshold
# Usage: assert_performance <command> <max_time_ms> [args...]
assert_performance() {
    local max_time="$1"
    shift
    local elapsed

    elapsed=$(measure_execution_time "$@")

    if [[ $elapsed -gt $max_time ]]; then
        echo "Performance assertion failed: ${elapsed}ms > ${max_time}ms"
        return 1
    fi
}

# ============================================================================
# Cleanup on Exit
# ============================================================================

# Register cleanup function
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced
    trap 'teardown_test_workspace' EXIT
fi

# Export functions for subshells
export -f setup_test_workspace
export -f teardown_test_workspace
export -f create_mock_notes
export -f create_mock_handover
export -f create_phase_todo
export -f assert_file_exists
export -f assert_directory_exists
export -f assert_json_valid
export -f assert_json_key_exists
export -f assert_handover_schema
export -f run_script
export -f run_python_script
export -f get_latest_handover
export -f count_handover_files
export -f wait_for_file
export -f debug_print
export -f setup_git_repo
export -f create_git_changes
export -f measure_execution_time
export -f assert_performance
