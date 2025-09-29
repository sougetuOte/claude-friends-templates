#!/bin/bash
# Mock Claude Code Environment Variables
# This script simulates the environment variables that Claude Code provides to hooks

# Set default values that can be overridden by tests
export CLAUDE_TOOL_NAME="${CLAUDE_TOOL_NAME:-Edit}"
export CLAUDE_FILE_PATHS="${CLAUDE_FILE_PATHS:-test.md}"
export CLAUDE_EXIT_CODE="${CLAUDE_EXIT_CODE:-0}"
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
export CLAUDE_COMMAND="${CLAUDE_COMMAND:-test command}"
export CLAUDE_OUTPUT="${CLAUDE_OUTPUT:-test output}"
export CLAUDE_PROMPT="${CLAUDE_PROMPT:-test prompt}"

# Mock additional environment variables
export CLAUDE_SESSION_ID="${CLAUDE_SESSION_ID:-test-session-$(date +%s)}"
export CLAUDE_USER_ID="${CLAUDE_USER_ID:-test-user}"
export CLAUDE_CACHE="${CLAUDE_CACHE:-./.ccache}"

# Function to reset environment to clean state
reset_claude_env() {
    unset CLAUDE_TOOL_NAME
    unset CLAUDE_FILE_PATHS
    unset CLAUDE_EXIT_CODE
    unset CLAUDE_PROJECT_DIR
    unset CLAUDE_COMMAND
    unset CLAUDE_OUTPUT
    unset CLAUDE_PROMPT
    unset CLAUDE_SESSION_ID
    unset CLAUDE_USER_ID
    unset CLAUDE_CACHE
}

# Function to set up specific test scenario
setup_test_scenario() {
    local scenario="$1"

    case "$scenario" in
        "edit_file")
            export CLAUDE_TOOL_NAME="Edit"
            export CLAUDE_FILE_PATHS="src/main.js"
            export CLAUDE_EXIT_CODE="0"
            ;;
        "bash_command")
            export CLAUDE_TOOL_NAME="Bash"
            export CLAUDE_COMMAND="ls -la"
            export CLAUDE_EXIT_CODE="0"
            ;;
        "failed_command")
            export CLAUDE_TOOL_NAME="Bash"
            export CLAUDE_COMMAND="invalid-command"
            export CLAUDE_EXIT_CODE="1"
            ;;
        "agent_switch")
            export CLAUDE_PROMPT="/agent:builder start implementation"
            export CLAUDE_TOOL_NAME="UserPromptSubmit"
            ;;
        *)
            echo "Unknown test scenario: $scenario" >&2
            return 1
            ;;
    esac
}

# Export functions for use in tests
export -f reset_claude_env
export -f setup_test_scenario

# Print current environment if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== Mock Claude Environment Setup ==="
    echo "CLAUDE_TOOL_NAME: $CLAUDE_TOOL_NAME"
    echo "CLAUDE_FILE_PATHS: $CLAUDE_FILE_PATHS"
    echo "CLAUDE_EXIT_CODE: $CLAUDE_EXIT_CODE"
    echo "CLAUDE_PROJECT_DIR: $CLAUDE_PROJECT_DIR"
    echo "CLAUDE_SESSION_ID: $CLAUDE_SESSION_ID"
    echo "=== Environment Ready ==="
fi
