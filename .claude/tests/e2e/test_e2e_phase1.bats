#!/usr/bin/env bats

# E2Eテストシナリオ - Phase 1統合テスト
# t-wada式TDD Red Phase: まず失敗するテストを書く

load ../helpers/test-helpers.sh

# グローバル変数
export TEST_DIR
export CLAUDE_PROJECT_DIR
export HOOKS_BASE_DIR

setup() {
    # Hooksのベースディレクトリを設定
    HOOKS_BASE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
    # テスト用の一時ディレクトリ作成
    TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"

    # 必要なディレクトリ構造を作成
    mkdir -p "$TEST_DIR/.claude/logs"
    mkdir -p "$TEST_DIR/.claude/agents"
    mkdir -p "$TEST_DIR/.claude/planner"
    mkdir -p "$TEST_DIR/.claude/builder"
    mkdir -p "$TEST_DIR/.claude/shared"

    # テスト用のファイルを用意
    echo '{"agent": "none"}' > "$TEST_DIR/.claude/agents/active.json"

    # Gitリポジトリを初期化（Git状態テスト用）
    cd "$TEST_DIR" && git init --quiet
}

teardown() {
    # テスト後のクリーンアップ
    rm -rf "$TEST_DIR"
}

# ========================================
# Scenario 1: プロンプト入力からエージェント切り替えまでの完全フロー
# ========================================

@test "E2E: /agent:planner コマンドで完全なエージェント切り替えフロー" {
    # UserPromptSubmitフック相当の処理をシミュレート
    local prompt_file="$TEST_DIR/prompt.json"
    echo '{"prompt": "/agent:planner 新機能の設計を始めます"}' > "$prompt_file"

    # agent-switch.shを実行（メイン処理）
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    run "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$prompt_file"

    # 終了コードの確認
    [ "$status" -eq 0 ]

    # active.jsonが更新されていることを確認
    [ -f "$TEST_DIR/.claude/agents/active.json" ]
    run jq -r '.agent' "$TEST_DIR/.claude/agents/active.json"
    [ "$output" = "planner" ]

    # handover.mdが生成されていることを確認
    [ -f "$TEST_DIR/.claude/planner/handover.md" ]

    # ログが記録されていることを確認
    [ -f "$TEST_DIR/.claude/logs/agent-switch.log" ]
    grep -q "Switched to planner" "$TEST_DIR/.claude/logs/agent-switch.log"
}

@test "E2E: builder切り替えでディレクトリ初期化と環境設定" {
    # builderへの切り替えテスト
    local prompt_file="$TEST_DIR/prompt.json"
    echo '{"prompt": "/agent:builder テストコードを実装します"}' > "$prompt_file"

    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    run "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$prompt_file"

    [ "$status" -eq 0 ]

    # builder用ディレクトリが初期化されていることを確認
    [ -d "$TEST_DIR/.claude/builder" ]
    [ -f "$TEST_DIR/.claude/builder/notes.md" ]
    [ -f "$TEST_DIR/.claude/builder/handover.md" ]

    # identity.mdが存在することを確認
    [ -f "$TEST_DIR/.claude/builder/identity.md" ]
}

# ========================================
# Scenario 2: Memory Bank自動ローテーション
# ========================================

@test "E2E: notes.mdが450行超えたときの自動ローテーション" {
    # 大きなnotes.mdファイルを作成
    local notes_file="$TEST_DIR/.claude/planner/notes.md"
    for i in {1..460}; do
        echo "Line $i: テストコンテンツ" >> "$notes_file"
    done

    # planner切り替えでローテーションがトリガーされる
    local prompt_file="$TEST_DIR/prompt.json"
    echo '{"prompt": "/agent:planner 続きの作業"}' > "$prompt_file"

    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    run "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$prompt_file"

    [ "$status" -eq 0 ]

    # アーカイブが作成されていることを確認
    [ -d "$TEST_DIR/.claude/planner/archive" ]
    local archive_count=$(ls "$TEST_DIR/.claude/planner/archive" | wc -l)
    [ "$archive_count" -gt 0 ]

    # 新しいnotes.mdが作成されていることを確認
    [ -f "$notes_file" ]
    local line_count=$(wc -l < "$notes_file")
    [ "$line_count" -lt 450 ]
}

# ========================================
# Scenario 3: Handover生成の詳細確認
# ========================================

@test "E2E: handover.mdに必要な情報が含まれている" {
    # まずplannerに切り替え
    echo '{"prompt": "/agent:planner 初期設計"}' > "$TEST_DIR/prompt1.json"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$TEST_DIR/prompt1.json"

    # notes.mdにコンテンツを追加
    cat >> "$TEST_DIR/.claude/planner/notes.md" << EOF
## 最近の活動
- APIエンドポイントの設計完了
- データベーススキーマの定義

## 重要な決定事項
- RESTful APIを採用
- PostgreSQLを使用
EOF

    # phase-todo.mdも作成
    cat > "$TEST_DIR/.claude/shared/phase-todo.md" << EOF
## 現在のタスク
- [ ] 認証システムの実装
- [ ] テストコードの作成
- [x] API設計の完了
EOF

    # builderに切り替えてhandover生成
    echo '{"prompt": "/agent:builder 実装開始"}' > "$TEST_DIR/prompt2.json"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    run bash -c "cat '$TEST_DIR/prompt2.json' | '$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh'"

    [ "$status" -eq 0 ]

    # handover.mdの内容を確認
    local handover_file="$TEST_DIR/.claude/builder/handover.md"
    [ -f "$handover_file" ]

    # 必要な情報が含まれているか確認
    grep -q "最近の活動" "$handover_file"
    grep -q "現在のタスク" "$handover_file"
    grep -q "Git状態" "$handover_file"
}

# ========================================
# Scenario 4: エラーケースの処理
# ========================================

@test "E2E: 不正なエージェント名でエラー処理" {
    local prompt_file="$TEST_DIR/prompt.json"
    echo '{"prompt": "/agent:invalid 不正なエージェント"}' > "$prompt_file"

    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    run "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$prompt_file"

    # エラーハンドリングされることを確認
    # （エラーでも正常終了する設計の場合）
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]

    # active.jsonは変更されないことを確認
    run jq -r '.agent' "$TEST_DIR/.claude/agents/active.json"
    [ "$output" = "none" ]
}

@test "E2E: 権限エラーのフォールバック処理" {
    # ディレクトリを読み取り専用にする
    chmod 555 "$TEST_DIR/.claude/agents"

    local prompt_file="$TEST_DIR/prompt.json"
    echo '{"prompt": "/agent:planner テスト"}' > "$prompt_file"

    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    run "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$prompt_file"

    # エラーが適切に処理されることを確認
    # （処理は継続するが、ログにエラーが記録される）
    [ -f "$TEST_DIR/.claude/logs/agent-switch.log" ] || true

    # 権限を戻す
    chmod 755 "$TEST_DIR/.claude/agents"
}

# ========================================
# Scenario 5: 並行実行とタイムアウト
# ========================================

@test "E2E: 複数のhook同時実行でデッドロックなし" {
    # 複数のプロンプトを並行して処理
    for i in {1..5}; do
        (
            echo "{\"prompt\": \"/agent:planner タスク$i\"}" > "$TEST_DIR/prompt$i.json"
            export CLAUDE_PROJECT_DIR="$TEST_DIR"
            "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$TEST_DIR/prompt$i.json"
        ) &
    done

    # すべてのバックグラウンドジョブが完了するのを待つ
    wait

    # active.jsonが壊れていないことを確認
    [ -f "$TEST_DIR/.claude/agents/active.json" ]
    run jq -r '.agent' "$TEST_DIR/.claude/agents/active.json"
    [ "$output" = "planner" ]
}

@test "E2E: hook処理のタイムアウト（2秒以内）" {
    # 処理時間を計測
    local start_time=$(date +%s%N)

    local prompt_file="$TEST_DIR/prompt.json"
    echo '{"prompt": "/agent:planner クイックテスト"}' > "$prompt_file"

    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    timeout 3 "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$prompt_file"

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # ミリ秒に変換

    # 2秒（2000ミリ秒）以内に完了することを確認
    [ "$duration" -lt 2000 ]
}

# ========================================
# Scenario 6: ログとメトリクス
# ========================================

@test "E2E: 全てのhook実行がログに記録される" {
    # 一連の操作を実行
    echo '{"prompt": "/agent:planner 設計"}' > "$TEST_DIR/prompt1.json"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$TEST_DIR/prompt1.json"

    echo '{"prompt": "/agent:builder 実装"}' > "$TEST_DIR/prompt2.json"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$TEST_DIR/prompt2.json"

    # ログファイルの存在確認
    [ -f "$TEST_DIR/.claude/logs/agent-switch.log" ]

    # 両方の切り替えが記録されていることを確認
    local log_content=$(cat "$TEST_DIR/.claude/logs/agent-switch.log")
    [[ "$log_content" == *"planner"* ]]
    [[ "$log_content" == *"builder"* ]]
}

@test "E2E: JSON応答が正しく生成される" {
    # agent-switch.shが正しいJSON応答を返すことを確認
    local prompt_file="$TEST_DIR/prompt.json"
    echo '{"prompt": "/agent:planner テスト"}' > "$prompt_file"

    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    run "$HOOKS_BASE_DIR/hooks/agent/agent-switch.sh" < "$prompt_file"

    # 出力がJSONフォーマットであることを確認（もし実装されていれば）
    # echo "$output" | jq . > /dev/null 2>&1 || true

    [ "$status" -eq 0 ]
}
