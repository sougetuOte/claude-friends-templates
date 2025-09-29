#!/usr/bin/env bats
# Test for agent-switch.sh - TDD Red Phase
# エージェント切り替え機能の統合テスト（必ず失敗する）
# t-wada式TDD: まだ実装が存在しないため、すべてのテストが失敗することを確認

# テスト環境のセットアップ
setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export LOG_DIR="$TEST_DIR/.claude/logs"
    export AGENTS_DIR="$TEST_DIR/.claude/agents"
    export MEMORY_DIR="$TEST_DIR/.claude/memory"

    # テスト用のディレクトリ構造を作成
    mkdir -p "$LOG_DIR"
    mkdir -p "$AGENTS_DIR"
    mkdir -p "$MEMORY_DIR"
    mkdir -p "$TEST_DIR/.claude/planner"
    mkdir -p "$TEST_DIR/.claude/builder"

    # テスト用の一時ファイル
    export TEST_PROMPT_FILE="$TEST_DIR/test_prompt.json"
    export ACTIVE_FILE="$AGENTS_DIR/active.json"
    export PLANNER_NOTES="$TEST_DIR/.claude/planner/notes.md"
    export BUILDER_NOTES="$TEST_DIR/.claude/builder/notes.md"
}

# テスト環境のクリーンアップ
teardown() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# =============================================================================
# テストグループ1: エージェント切り替え検出テスト
# =============================================================================

@test "detect_agent_switch detects /agent:planner command" {
    # 実装ファイルを読み込む（まだ存在しない）
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # テスト入力JSONを作成
    echo '{"prompt": "/agent:planner Let us design the architecture"}' > "$TEST_PROMPT_FILE"

    # エージェント切り替えを検出
    run detect_agent_switch "$TEST_PROMPT_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "planner" ]
}

@test "detect_agent_switch detects /agent:builder command" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    echo '{"prompt": "/agent:builder Implement the feature"}' > "$TEST_PROMPT_FILE"

    run detect_agent_switch "$TEST_PROMPT_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "builder" ]
}

@test "detect_agent_switch returns none when no agent command" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    echo '{"prompt": "Just a normal prompt without agent command"}' > "$TEST_PROMPT_FILE"

    run detect_agent_switch "$TEST_PROMPT_FILE"

    [ "$status" -eq 1 ]
    [ "$output" = "none" ]
}

@test "detect_agent_switch handles malformed JSON gracefully" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    echo 'not a valid json' > "$TEST_PROMPT_FILE"

    run detect_agent_switch "$TEST_PROMPT_FILE"

    [ "$status" -eq 2 ]  # Error status for malformed JSON
}

# =============================================================================
# テストグループ2: Handover生成トリガーテスト
# =============================================================================

@test "trigger_handover_generation creates handover when switching agents" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 現在のエージェントを設定
    echo '{"current_agent": "planner"}' > "$ACTIVE_FILE"

    # Builderへの切り替えをトリガー
    run trigger_handover_generation "planner" "builder"

    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.claude/planner/handover.md" ]

    # handoverファイルの内容を確認
    grep -q "Handover from Planner to Builder" "$TEST_DIR/.claude/planner/handover.md"
}

@test "trigger_handover_generation skips when same agent" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 同じエージェントへの切り替え
    run trigger_handover_generation "planner" "planner"

    [ "$status" -eq 1 ]  # スキップを示すステータス
    [ ! -f "$TEST_DIR/.claude/planner/handover.md" ]
}

@test "trigger_handover_generation handles none to agent switch" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 初期状態（エージェントなし）から切り替え
    run trigger_handover_generation "none" "planner"

    [ "$status" -eq 0 ]
    # 初期化処理のみで、handoverは不要
    [ ! -f "$TEST_DIR/.claude/planner/handover.md" ]
}

# =============================================================================
# テストグループ3: Memory Bankローテーショントリガーテスト
# =============================================================================

@test "check_notes_rotation triggers rotation when notes exceed 450 lines" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 450行以上のnotesファイルを作成
    for i in {1..451}; do
        echo "Line $i: Test content for rotation check" >> "$PLANNER_NOTES"
    done

    run check_notes_rotation "planner"

    [ "$status" -eq 0 ]
    [ "$output" = "rotation_needed" ]
}

@test "check_notes_rotation skips when notes under 450 lines" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 100行のnotesファイルを作成
    for i in {1..100}; do
        echo "Line $i: Normal content" >> "$PLANNER_NOTES"
    done

    run check_notes_rotation "planner"

    [ "$status" -eq 1 ]
    [ "$output" = "rotation_not_needed" ]
}

@test "trigger_notes_rotation performs rotation and creates archive" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # ローテーション対象のファイルを作成
    for i in {1..500}; do
        echo "Line $i: Content to be rotated" >> "$PLANNER_NOTES"
    done

    run trigger_notes_rotation "planner"

    [ "$status" -eq 0 ]
    # アーカイブファイルが作成されたか確認
    [ -f "$TEST_DIR/.claude/planner/archive/"*"-notes.md" ]
    # 元のnotesファイルがリセットされたか確認
    [ $(wc -l < "$PLANNER_NOTES") -lt 50 ]
}

# =============================================================================
# テストグループ4: active.json更新テスト
# =============================================================================

@test "update_active_agent updates active.json correctly" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 初期状態を設定
    echo '{"current_agent": "none"}' > "$ACTIVE_FILE"

    run update_active_agent "planner"

    [ "$status" -eq 0 ]

    # active.jsonの内容を確認
    local current_agent=$(jq -r '.current_agent' "$ACTIVE_FILE")
    [ "$current_agent" = "planner" ]

    # タイムスタンプが追加されているか確認
    local timestamp=$(jq -r '.last_updated' "$ACTIVE_FILE")
    [ -n "$timestamp" ]
}

@test "update_active_agent creates active.json if not exists" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # active.jsonが存在しない状態
    rm -f "$ACTIVE_FILE"

    run update_active_agent "builder"

    [ "$status" -eq 0 ]
    [ -f "$ACTIVE_FILE" ]

    local current_agent=$(jq -r '.current_agent' "$ACTIVE_FILE")
    [ "$current_agent" = "builder" ]
}

# =============================================================================
# テストグループ5: 初期化処理テスト
# =============================================================================

@test "initialize_agent_environment creates required directories" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # ディレクトリを削除して初期状態に
    rm -rf "$TEST_DIR/.claude/planner"

    run initialize_agent_environment "planner"

    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.claude/planner" ]
    [ -f "$TEST_DIR/.claude/planner/notes.md" ]
    [ -f "$TEST_DIR/.claude/planner/identity.md" ]
}

@test "initialize_agent_environment handles builder agent" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    rm -rf "$TEST_DIR/.claude/builder"

    run initialize_agent_environment "builder"

    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.claude/builder" ]
    [ -f "$TEST_DIR/.claude/builder/notes.md" ]
    [ -f "$TEST_DIR/.claude/builder/identity.md" ]
}

# =============================================================================
# テストグループ6: メイン処理の統合テスト
# =============================================================================

@test "main function orchestrates agent switch correctly" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 初期状態を設定
    echo '{"current_agent": "none"}' > "$ACTIVE_FILE"
    echo '{"prompt": "/agent:planner Design the system"}' | {
        run main

        [ "$status" -eq 0 ]

        # JSONレスポンスが有効か確認
        echo "$output" | jq . > /dev/null
        [ $? -eq 0 ]

        # continueがtrueか確認
        local continue_val=$(echo "$output" | jq -r '.continue')
        [ "$continue_val" = "true" ]

        # システムメッセージが含まれているか確認
        local message=$(echo "$output" | jq -r '.system_message')
        [[ "$message" == *"Switched to Planner"* ]]
    }

    # active.jsonが更新されているか確認
    local current_agent=$(jq -r '.current_agent' "$ACTIVE_FILE")
    [ "$current_agent" = "planner" ]
}

@test "main function handles no agent switch gracefully" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    echo '{"current_agent": "planner"}' > "$ACTIVE_FILE"
    echo '{"prompt": "Normal prompt without agent command"}' | {
        run main

        [ "$status" -eq 0 ]

        # JSONレスポンスが有効か確認
        echo "$output" | jq . > /dev/null
        [ $? -eq 0 ]

        # continueがtrueか確認
        local continue_val=$(echo "$output" | jq -r '.continue')
        [ "$continue_val" = "true" ]

        # システムメッセージがnullか空か確認
        local message=$(echo "$output" | jq -r '.system_message')
        [ "$message" = "null" ] || [ -z "$message" ]
    }
}

# =============================================================================
# テストグループ7: エラーハンドリングテスト
# =============================================================================

@test "error handling for invalid agent name" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    echo '{"prompt": "/agent:invalid Some command"}' > "$TEST_PROMPT_FILE"

    run detect_agent_switch "$TEST_PROMPT_FILE"

    [ "$status" -eq 3 ]  # Invalid agent error
    [[ "$output" == *"Invalid agent"* ]]
}

@test "error handling for file system errors" {
    source "${BATS_TEST_DIRNAME}/../../hooks/agent/agent-switch.sh"

    # 書き込み権限を削除してエラーを発生させる
    chmod 555 "$TEST_DIR/.claude"

    run initialize_agent_environment "planner"

    [ "$status" -ne 0 ]
    [[ "$output" == *"Permission denied"* ]] || [[ "$output" == *"Failed to create"* ]]

    # 権限を戻す
    chmod 755 "$TEST_DIR/.claude"
}
