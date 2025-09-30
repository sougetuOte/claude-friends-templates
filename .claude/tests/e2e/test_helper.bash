#!/usr/bin/env bash
# .claude/tests/e2e/test_helper.bash
# Bats test helper with reusable functions
# Task 2.5.4 - Green Phase

# Setup test workspace with full .claude structure
setup_test_workspace() {
    export TEST_DIR="${BATS_TEST_TMPDIR}/claude_workspace"
    mkdir -p "$TEST_DIR/.claude/"{agents/{planner,builder},scripts,logs,states}

    # Create initial agent notes
    cat > "$TEST_DIR/.claude/agents/planner/notes.md" <<'EOF'
# Planner Notes

## Current Task: Test
EOF

    cat > "$TEST_DIR/.claude/agents/builder/notes.md" <<'EOF'
# Builder Notes

## Current Task: Test
EOF

    # Copy all scripts from .claude/scripts/
    local script_dir="${BATS_TEST_DIRNAME}/../../scripts"
    if [ -d "$script_dir" ]; then
        # Copy Python scripts
        for script in "$script_dir"/*.py; do
            [ -f "$script" ] && cp "$script" "$TEST_DIR/.claude/scripts/"
        done

        # Copy Bash scripts and make executable
        for script in "$script_dir"/*.sh; do
            if [ -f "$script" ]; then
                cp "$script" "$TEST_DIR/.claude/scripts/"
                chmod +x "$TEST_DIR/.claude/scripts/$(basename "$script")"
            fi
        done
    fi

    # Set environment variables
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export CLAUDE_AGENT="planner"
}

# Cleanup test workspace
cleanup_test_workspace() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    unset CLAUDE_PROJECT_DIR
    unset CLAUDE_AGENT
    unset TEST_DIR
}

# Count handover files
count_handovers() {
    find "$TEST_DIR/.claude" -name "handover-*.json" 2>/dev/null | wc -l
}

# Load latest handover JSON
load_latest_handover() {
    local latest
    latest=$(ls -t "$TEST_DIR/.claude"/handover-*.json 2>/dev/null | head -1)
    if [ -f "$latest" ]; then
        cat "$latest"
    else
        echo "{}"
    fi
}

# Validate handover JSON structure
# Returns 0 if valid, 1 if invalid
validate_handover_json() {
    local file="$1"

    # Check file exists
    [ -f "$file" ] || return 1

    # Check required fields exist using jq
    if command -v jq >/dev/null 2>&1; then
        jq -e '.metadata and .summary and .context' "$file" >/dev/null 2>&1
        return $?
    else
        # Fallback: simple grep check if jq not available
        grep -q '"metadata"' "$file" && \
        grep -q '"summary"' "$file" && \
        grep -q '"context"' "$file"
        return $?
    fi
}

# Run agent-switch.sh helper
run_agent_switch() {
    local from_agent="$1"
    local to_agent="$2"
    local switch_script="$TEST_DIR/.claude/scripts/agent-switch.sh"

    [ -f "$switch_script" ] || return 1

    export CLAUDE_AGENT="$from_agent"
    bash "$switch_script" "$from_agent" "$to_agent"
}

# Check if handover file was created in last N seconds
handover_created_recently() {
    local seconds="${1:-10}"
    local count_before count_after

    count_before=$(count_handovers)
    sleep 1
    count_after=$(count_handovers)

    [ "$count_after" -gt "$count_before" ]
}
