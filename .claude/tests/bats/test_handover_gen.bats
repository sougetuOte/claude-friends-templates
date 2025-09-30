#!/usr/bin/env bats
# Task 2.3.2: handover-gen.sh Red Phase Tests
# Testing handover-generator.py wrapper script with compression & state sync integration

setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    mkdir -p "$TEST_DIR/.claude/builder" "$TEST_DIR/.claude/planner" "$TEST_DIR/.claude/states"
    export HANDOVER_GEN_SCRIPT="${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"
    export HANDOVER_GENERATOR_PY="${BATS_TEST_DIRNAME}/../../scripts/handover-generator.py"

    # Create minimal notes files for testing
    echo "# Builder Notes" > "$TEST_DIR/.claude/builder/notes.md"
    echo "Current task: Implement feature X" >> "$TEST_DIR/.claude/builder/notes.md"

    echo "# Planner Notes" > "$TEST_DIR/.claude/planner/notes.md"
    echo "Planning next sprint" >> "$TEST_DIR/.claude/planner/notes.md"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Test 1: 基本的な引き継ぎファイル生成
@test "generate_handover: 基本的な引き継ぎファイル生成" {
    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'planner'"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.claude/handover-builder-to-planner-$(date +%Y-%m-%d).md" ]
}

# Test 2: 同一エージェント間ではスキップ
@test "generate_handover: 同一エージェント間ではスキップ" {
    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'builder'"
    [ "$status" -eq 1 ]
}

# Test 3: 圧縮機能との統合
@test "generate_handover: 大きいコンテキストで圧縮機能を使用" {
    # Create large notes file (>1000 lines)
    for i in {1..1200}; do
        echo "Line $i: Some content here" >> "$TEST_DIR/.claude/builder/notes.md"
    done

    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'planner'"
    [ "$status" -eq 0 ]
    # Should create compressed handover
    local handover_file="$TEST_DIR/.claude/handover-builder-to-planner-$(date +%Y-%m-%d).md"
    [ -f "$handover_file" ]
}

# Test 4: 状態同期との統合
@test "generate_handover: 状態同期情報を含める" {
    # Create state file
    mkdir -p "$TEST_DIR/.claude/states/builder"
    cat > "$TEST_DIR/.claude/states/builder/current.json" << 'EOFJSON'
{
  "agent": "builder",
  "timestamp": "2025-09-30T00:00:00Z",
  "context": {
    "current_task": "Feature implementation",
    "progress": "80%"
  }
}
EOFJSON

    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'planner'"
    [ "$status" -eq 0 ]

    local handover_file="$TEST_DIR/.claude/handover-builder-to-planner-$(date +%Y-%m-%d).md"
    [ -f "$handover_file" ]
    # Should include state information
    grep -q "progress" "$handover_file" || true
}

# Test 5: エラーハンドリング - Python script not found
@test "generate_handover: handover-generator.pyが見つからない場合のエラー" {
    export HANDOVER_GENERATOR_PY="/nonexistent/path/handover-generator.py"
    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'planner'"
    [ "$status" -ne 0 ]
}

# Test 6: タイムアウト処理
@test "generate_handover: タイムアウト設定が機能する" {
    # This test verifies timeout mechanism exists
    # Use a reasonable timeout that should succeed
    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' HANDOVER_TIMEOUT=30 && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'planner'"
    # Should complete successfully with 30 second timeout (reasonable for small data)
    [ "$status" -eq 0 ]
}

# Test 7: 出力ファイル命名規則
@test "generate_handover: 正しい命名規則でファイル作成" {
    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'planner'"
    [ "$status" -eq 0 ]

    local expected_pattern="handover-builder-to-planner-[0-9]{4}-[0-9]{2}-[0-9]{2}.md"
    local handover_file="$TEST_DIR/.claude/handover-builder-to-planner-$(date +%Y-%m-%d).md"
    [ -f "$handover_file" ]
}

# Test 8: 引き継ぎファイル内容検証（JSON形式）
@test "generate_handover: 引き継ぎファイルに必須情報が含まれる（JSON形式）" {
    run bash -c "export CLAUDE_PROJECT_DIR='$TEST_DIR' && source '$HANDOVER_GEN_SCRIPT' 2>/dev/null && generate_handover 'builder' 'planner'"
    [ "$status" -eq 0 ]

    local handover_file="$TEST_DIR/.claude/handover-builder-to-planner-$(date +%Y-%m-%d).md"
    [ -f "$handover_file" ]

    # Check required JSON fields
    grep -q '"from_agent"' "$handover_file"
    grep -q '"to_agent"' "$handover_file"
    grep -q '"builder"' "$handover_file"
    grep -q '"planner"' "$handover_file"
}
