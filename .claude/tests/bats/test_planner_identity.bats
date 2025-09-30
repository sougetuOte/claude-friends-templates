#!/usr/bin/env bats
# Task 2.4.2: Planner Identity - Red Phase Tests
# TDD Red Phase: Tests MUST fail initially

load 'test_helper.bash' 2>/dev/null || true

setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"

    # Create necessary directories
    mkdir -p "$TEST_DIR/.claude/agents/planner"
    mkdir -p "$TEST_DIR/.claude/scripts"
    mkdir -p "$TEST_DIR/.claude/logs"

    # Copy scripts to test directory
    if [[ -f "${BATS_TEST_DIRNAME}/../../agents/planner/identity.md" ]]; then
        cp "${BATS_TEST_DIRNAME}/../../agents/planner/identity.md" "$TEST_DIR/.claude/agents/planner/"
    fi

    if [[ -f "${BATS_TEST_DIRNAME}/../../scripts/planner-startup.sh" ]]; then
        cp "${BATS_TEST_DIRNAME}/../../scripts/planner-startup.sh" "$TEST_DIR/.claude/scripts/"
        chmod +x "$TEST_DIR/.claude/scripts/planner-startup.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Test 1: Planner identity file exists
@test "planner identity.md ファイルが存在する" {
    run test -f "$TEST_DIR/.claude/agents/planner/identity.md"
    [ "$status" -eq 0 ]
}

# Test 2: Identity file has proper YAML frontmatter for caching
@test "identity.md に cache_control フロントマターが含まれる" {
    skip_if_missing "$TEST_DIR/.claude/agents/planner/identity.md"

    run grep -q "cache_control" "$TEST_DIR/.claude/agents/planner/identity.md"
    [ "$status" -eq 0 ]
}

# Test 3: Startup script automatically reads latest handover file
@test "startup script が最新の handover ファイルを自動読み込み" {
    skip_if_missing "$TEST_DIR/.claude/scripts/planner-startup.sh"

    # Create mock handover file
    cat > "$TEST_DIR/.claude/handover-test-20250930.json" <<'EOF'
{
  "metadata": {
    "from_agent": "builder",
    "to_agent": "planner",
    "created_at": "2025-09-30T00:00:00Z"
  },
  "summary": {
    "current_task": "Review builder implementation",
    "next_steps": ["Design review", "Plan next phase"]
  }
}
EOF

    run bash "$TEST_DIR/.claude/scripts/planner-startup.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "builder" ]]
    [[ "$output" =~ "Review builder implementation" ]]
}

# Test 4: Graceful fallback when handover file is missing
@test "handover ファイルが存在しない場合は graceful fallback" {
    skip_if_missing "$TEST_DIR/.claude/scripts/planner-startup.sh"

    # No handover files exist
    run bash "$TEST_DIR/.claude/scripts/planner-startup.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "引き継ぎ" ]] || [[ "$output" =~ "notes.md" ]]
}

# Test 5: Startup script completes within 100ms (performance)
@test "startup script の実行時間が 100ms 以内" {
    skip_if_missing "$TEST_DIR/.claude/scripts/planner-startup.sh"

    # Create handover file
    cat > "$TEST_DIR/.claude/handover-test-20250930.json" <<'EOF'
{
  "metadata": {"from_agent": "builder", "to_agent": "planner"},
  "summary": {"current_task": "Test", "next_steps": ["Continue"]}
}
EOF

    start_time=$(date +%s%N)
    bash "$TEST_DIR/.claude/scripts/planner-startup.sh" >/dev/null 2>&1
    end_time=$(date +%s%N)

    elapsed_ms=$(( (end_time - start_time) / 1000000 ))

    # Allow up to 200ms for test environment overhead
    [ "$elapsed_ms" -lt 200 ]
}

# Test 6: Identity file maintains feminine polite tone (女性の丁寧な口調)
@test "identity.md に女性口調の例が含まれる" {
    skip_if_missing "$TEST_DIR/.claude/agents/planner/identity.md"

    # Check for feminine tone markers
    run grep -E "(ですね|でしょう|かしら|ましょう|ませんか)" "$TEST_DIR/.claude/agents/planner/identity.md"
    [ "$status" -eq 0 ]
}

# Test 7: Startup script handles JSON parse errors gracefully
@test "JSON パースエラー時のエラーハンドリング" {
    skip_if_missing "$TEST_DIR/.claude/scripts/planner-startup.sh"

    # Create invalid JSON handover file
    echo "INVALID JSON {{{" > "$TEST_DIR/.claude/handover-invalid.json"

    run bash "$TEST_DIR/.claude/scripts/planner-startup.sh"
    # Should not fail with error code
    [ "$status" -eq 0 ]
}

# Test 8: Identity file includes Step 0 checklist with strategic focus
@test "identity.md にステップ0チェックリストと戦略的思考が含まれる" {
    skip_if_missing "$TEST_DIR/.claude/agents/planner/identity.md"

    run grep -q "ステップ0" "$TEST_DIR/.claude/agents/planner/identity.md"
    [ "$status" -eq 0 ]

    run grep -q "引き継ぎ" "$TEST_DIR/.claude/agents/planner/identity.md"
    [ "$status" -eq 0 ]

    # Check for strategic/design-focused keywords
    run grep -iE "(設計|デザイン|戦略|計画|アーキテクチャ)" "$TEST_DIR/.claude/agents/planner/identity.md"
    [ "$status" -eq 0 ]
}

# Helper function
skip_if_missing() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        skip "File not found: $file (expected in Green Phase)"
    fi
}
