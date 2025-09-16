#!/bin/bash
# Simple E2E test without Bats

HOOKS_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_DIR="/tmp/test-e2e-simple-$$"

# Setup
mkdir -p "$TEST_DIR/.claude/agents"
echo '{"agent": "none"}' > "$TEST_DIR/.claude/agents/active.json"

# Test 1: Agent switch
echo "Test 1: Agent switch to planner"
echo '{"prompt": "/agent:planner test"}' > "$TEST_DIR/prompt.json"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
RESULT=$("$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$TEST_DIR/prompt.json")
EXIT_CODE=$?

echo "Result: $RESULT"
echo "Exit code: $EXIT_CODE"

# Check if active.json was updated
if [[ -f "$TEST_DIR/.claude/agents/active.json" ]]; then
    ACTIVE_AGENT=$(jq -r '.current_agent' "$TEST_DIR/.claude/agents/active.json")
    echo "Active agent: $ACTIVE_AGENT"
    if [[ "$ACTIVE_AGENT" == "planner" ]]; then
        echo "✅ Test 1 PASSED"
    else
        echo "❌ Test 1 FAILED: Agent not updated"
    fi
else
    echo "❌ Test 1 FAILED: active.json not found"
fi

# Cleanup
rm -rf "$TEST_DIR"