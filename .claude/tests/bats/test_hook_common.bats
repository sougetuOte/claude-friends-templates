#!/usr/bin/env bats
# Test for hook-common.sh - TDD Red Phase
# このテストは必ず失敗します（関数がまだ実装されていないため）

# テスト環境のセットアップ
setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export LOG_DIR="$TEST_DIR/.claude/logs"

    # テスト用のディレクトリ構造を作成
    mkdir -p "$TEST_DIR/.claude"
}

# テスト環境のクリーンアップ
teardown() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# =============================================================================
# init_hooks_system 関数のテスト
# =============================================================================

@test "init_hooks_system creates required directories" {
    # まだ実装されていない関数を呼び出す（必ず失敗）
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"
    run init_hooks_system

    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.claude/logs" ]
    [ -d "$TEST_DIR/.claude/agents" ]
    [ -d "$TEST_DIR/.claude/memory" ]
}

@test "init_hooks_system is idempotent" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # 2回実行してもエラーにならない
    run init_hooks_system
    [ "$status" -eq 0 ]

    run init_hooks_system
    [ "$status" -eq 0 ]
}

@test "init_hooks_system handles permission errors gracefully" {
    # 書き込み不可能なディレクトリでテスト
    chmod 555 "$TEST_DIR"

    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"
    run init_hooks_system

    # エラーを適切に処理（クラッシュしない）
    [ "$status" -ne 0 ]

    chmod 755 "$TEST_DIR"
}

# =============================================================================
# get_agent_info 関数のテスト
# =============================================================================

@test "get_agent_info returns correct agent from JSON prompt" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # /agent:planner コマンドを含むJSONを入力
    echo '{"prompt": "/agent:planner test command"}' | {
        run get_agent_info
        [ "$status" -eq 0 ]
        [ "$output" = "prompt:planner" ]
    }
}

@test "get_agent_info returns builder agent from prompt" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    echo '{"prompt": "/agent:builder implement feature"}' | {
        run get_agent_info
        [ "$status" -eq 0 ]
        [ "$output" = "prompt:builder" ]
    }
}

@test "get_agent_info falls back to active.json file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # active.jsonファイルを作成
    mkdir -p "$TEST_DIR/.claude/agents"
    echo '{"current_agent": "planner"}' > "$TEST_DIR/.claude/agents/active.json"

    # 空のJSONを入力（promptフィールドなし）
    echo '{}' | {
        run get_agent_info
        [ "$status" -eq 0 ]
        [ "$output" = "file:planner" ]
    }
}

@test "get_agent_info supports legacy active.md file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # レガシーファイルを作成
    mkdir -p "$TEST_DIR/.claude/agents"
    echo "## Current Agent: builder" > "$TEST_DIR/.claude/agents/active.md"

    echo '{}' | {
        run get_agent_info
        [ "$status" -eq 0 ]
        [ "$output" = "legacy:builder" ]
    }
}

# =============================================================================
# generate_json_response 関数のテスト
# =============================================================================

@test "generate_json_response creates valid JSON with all fields" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    run generate_json_response "true" "test message" "test context" "false"
    [ "$status" -eq 0 ]

    # JSONの妥当性を検証
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]

    # フィールドの存在確認
    local continue_val=$(echo "$output" | jq -r '.continue')
    local message_val=$(echo "$output" | jq -r '.message')
    local context_val=$(echo "$output" | jq -r '.context')
    local suppress_val=$(echo "$output" | jq -r '.suppressOutput')

    [ "$continue_val" = "true" ]
    [ "$message_val" = "test message" ]
    [ "$context_val" = "test context" ]
    [ "$suppress_val" = "false" ]
}

@test "generate_json_response handles empty strings" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    run generate_json_response "true" "" "" "true"
    [ "$status" -eq 0 ]

    # 空文字列でも有効なJSONを生成
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]
}

@test "generate_json_response escapes special characters" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # 特殊文字を含むメッセージ
    local message='Message with "quotes" and \backslash'
    run generate_json_response "false" "$message" "context" "false"
    [ "$status" -eq 0 ]

    # JSONとして有効
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]
}

# =============================================================================
# log_message 関数のテスト
# =============================================================================

@test "log_message writes to log file with timestamp" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # ログディレクトリを作成
    mkdir -p "$LOG_DIR"

    run log_message "INFO" "Test log message"
    [ "$status" -eq 0 ]

    # ログファイルが作成されているか確認
    [ -f "$LOG_DIR/hooks.log" ]

    # ログエントリが記録されているか確認
    grep "Test log message" "$LOG_DIR/hooks.log"
    [ $? -eq 0 ]
}

@test "log_message handles different log levels" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    mkdir -p "$LOG_DIR"

    run log_message "DEBUG" "Debug message"
    [ "$status" -eq 0 ]

    run log_message "INFO" "Info message"
    [ "$status" -eq 0 ]

    run log_message "WARN" "Warning message"
    [ "$status" -eq 0 ]

    run log_message "ERROR" "Error message"
    [ "$status" -eq 0 ]

    # すべてのログレベルが記録されているか確認
    grep "DEBUG" "$LOG_DIR/hooks.log"
    grep "INFO" "$LOG_DIR/hooks.log"
    grep "WARN" "$LOG_DIR/hooks.log"
    grep "ERROR" "$LOG_DIR/hooks.log"
}

@test "log_message appends to existing log file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    mkdir -p "$LOG_DIR"

    run log_message "INFO" "First message"
    [ "$status" -eq 0 ]

    run log_message "INFO" "Second message"
    [ "$status" -eq 0 ]

    # 両方のメッセージが記録されているか
    local line_count=$(wc -l < "$LOG_DIR/hooks.log")
    [ "$line_count" -eq 2 ]
}

@test "log_message creates log directory if not exists" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # ログディレクトリが存在しない状態でテスト
    [ ! -d "$LOG_DIR" ]

    run log_message "INFO" "Test message"
    [ "$status" -eq 0 ]

    # ログディレクトリが作成されたか
    [ -d "$LOG_DIR" ]
    [ -f "$LOG_DIR/hooks.log" ]
}

@test "log_message handles concurrent writes safely" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    mkdir -p "$LOG_DIR"

    # 複数のプロセスから同時にログを書き込む
    for i in {1..10}; do
        log_message "INFO" "Concurrent message $i" &
    done

    wait

    # すべてのメッセージが記録されているか確認
    local line_count=$(wc -l < "$LOG_DIR/hooks.log")
    [ "$line_count" -eq 10 ]
}

# =============================================================================
# 統合テスト
# =============================================================================

@test "all functions work together in typical workflow" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # 1. システム初期化
    run init_hooks_system
    [ "$status" -eq 0 ]

    # 2. エージェント情報取得
    echo '{"prompt": "/agent:planner design feature"}' | {
        run get_agent_info
        [ "$status" -eq 0 ]
        [ "$output" = "prompt:planner" ]
    }

    # 3. ログ記録
    run log_message "INFO" "Agent switched to planner"
    [ "$status" -eq 0 ]

    # 4. JSON レスポンス生成
    run generate_json_response "true" "Agent switch successful" "planner" "false"
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]
}

@test "error handling works across all functions" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/hook-common.sh"

    # 不正な入力でもクラッシュしない
    echo "invalid json" | {
        run get_agent_info
        # エラーを返すか、デフォルト値を返す
        [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    }

    # nullや未定義の引数でもクラッシュしない
    run generate_json_response "" "" "" ""
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}