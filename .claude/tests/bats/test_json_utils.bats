#!/usr/bin/env bats
# Test for json-utils.sh - TDD Red Phase
# JSONユーティリティ関数のテスト（必ず失敗する）

# テスト環境のセットアップ
setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"

    # テスト用のディレクトリ構造を作成
    mkdir -p "$TEST_DIR/.claude"

    # テスト用の一時ファイル
    export TEST_JSON_FILE="$TEST_DIR/test.json"
}

# テスト環境のクリーンアップ
teardown() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# =============================================================================
# validate_json 関数のテスト
# =============================================================================

@test "validate_json returns success for valid JSON" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"key": "value"}' | {
        run validate_json
        [ "$status" -eq 0 ]
    }
}

@test "validate_json returns error for invalid JSON" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"key": invalid}' | {
        run validate_json
        [ "$status" -ne 0 ]
    }
}

@test "validate_json handles empty input" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo "" | {
        run validate_json
        [ "$status" -ne 0 ]
    }
}

@test "validate_json works with complex nested JSON" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    cat <<'EOF' | {
{
  "users": [
    {"id": 1, "name": "Alice"},
    {"id": 2, "name": "Bob"}
  ],
  "settings": {
    "theme": "dark",
    "notifications": true
  }
}
EOF
        run validate_json
        [ "$status" -eq 0 ]
    }
}

# =============================================================================
# extract_json_value 関数のテスト
# =============================================================================

@test "extract_json_value extracts simple string value" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"name": "test"}' | {
        run extract_json_value "name"
        [ "$status" -eq 0 ]
        [ "$output" = "test" ]
    }
}

@test "extract_json_value extracts number value" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"count": 42}' | {
        run extract_json_value "count"
        [ "$status" -eq 0 ]
        [ "$output" = "42" ]
    }
}

@test "extract_json_value extracts boolean value" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"enabled": true}' | {
        run extract_json_value "enabled"
        [ "$status" -eq 0 ]
        [ "$output" = "true" ]
    }
}

@test "extract_json_value returns empty for missing key" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"name": "test"}' | {
        run extract_json_value "missing"
        [ "$status" -eq 0 ]
        [ "$output" = "" ]
    }
}

@test "extract_json_value handles nested path" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"user": {"name": "Alice"}}' | {
        run extract_json_value "user.name"
        [ "$status" -eq 0 ]
        [ "$output" = "Alice" ]
    }
}

# =============================================================================
# create_json_object 関数のテスト
# =============================================================================

@test "create_json_object creates simple object" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    run create_json_object "key" "value"
    [ "$status" -eq 0 ]

    # 出力されたJSONが有効か確認
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]

    # 値が正しいか確認
    local extracted=$(echo "$output" | jq -r '.key')
    [ "$extracted" = "value" ]
}

@test "create_json_object handles multiple key-value pairs" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    run create_json_object "name" "Alice" "age" "30" "active" "true"
    [ "$status" -eq 0 ]

    # JSONの妥当性確認
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]

    # 各値の確認
    local name=$(echo "$output" | jq -r '.name')
    local age=$(echo "$output" | jq -r '.age')
    local active=$(echo "$output" | jq -r '.active')

    [ "$name" = "Alice" ]
    [ "$age" = "30" ]
    [ "$active" = "true" ]
}

@test "create_json_object escapes special characters" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    run create_json_object "message" 'Hello "World"'
    [ "$status" -eq 0 ]

    # JSONが有効であることを確認
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]
}

# =============================================================================
# merge_json 関数のテスト
# =============================================================================

@test "merge_json merges two JSON objects" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    local json1='{"a": 1, "b": 2}'
    local json2='{"c": 3, "d": 4}'

    run merge_json "$json1" "$json2"
    [ "$status" -eq 0 ]

    # 結果が有効なJSONか確認
    echo "$output" | jq . > /dev/null
    [ $? -eq 0 ]

    # マージされた値を確認
    local a=$(echo "$output" | jq -r '.a')
    local c=$(echo "$output" | jq -r '.c')
    [ "$a" = "1" ]
    [ "$c" = "3" ]
}

@test "merge_json overwrites duplicate keys" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    local json1='{"key": "old"}'
    local json2='{"key": "new"}'

    run merge_json "$json1" "$json2"
    [ "$status" -eq 0 ]

    local value=$(echo "$output" | jq -r '.key')
    [ "$value" = "new" ]
}

# =============================================================================
# json_to_env 関数のテスト
# =============================================================================

@test "json_to_env exports JSON values as environment variables" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"APP_NAME": "test", "APP_VERSION": "1.0"}' > "$TEST_JSON_FILE"

    # 環境変数をエクスポート
    eval "$(json_to_env "$TEST_JSON_FILE")"

    [ "$APP_NAME" = "test" ]
    [ "$APP_VERSION" = "1.0" ]
}

@test "json_to_env handles nested JSON with prefix" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    echo '{"database": {"host": "localhost", "port": 5432}}' > "$TEST_JSON_FILE"

    # プレフィックス付きでエクスポート
    eval "$(json_to_env "$TEST_JSON_FILE" "DB_")"

    [ "$DB_DATABASE_HOST" = "localhost" ]
    [ "$DB_DATABASE_PORT" = "5432" ]
}

# =============================================================================
# 統合テスト
# =============================================================================

@test "all JSON functions work together in workflow" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    # 1. JSONオブジェクトを作成
    local json1=$(create_json_object "name" "Alice" "role" "admin")
    local json2=$(create_json_object "status" "active" "level" "5")

    # 2. JSONをマージ
    local merged=$(merge_json "$json1" "$json2")

    # 3. マージしたJSONが有効か検証
    echo "$merged" | validate_json
    [ $? -eq 0 ]

    # 4. 値を抽出
    local name=$(echo "$merged" | extract_json_value "name")
    local status=$(echo "$merged" | extract_json_value "status")

    [ "$name" = "Alice" ]
    [ "$status" = "active" ]
}

@test "error handling works across all JSON functions" {
    source "${BATS_TEST_DIRNAME}/../../hooks/common/json-utils.sh"

    # 不正なJSONでもクラッシュしない
    echo "invalid json" | {
        run validate_json
        [ "$status" -ne 0 ]
    }

    echo "invalid json" | {
        run extract_json_value "key"
        # エラーを返すか、空文字を返す
        [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    }
}
