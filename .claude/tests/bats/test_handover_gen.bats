#!/usr/bin/env bats
# Test for handover-gen.sh - TDD Red Phase
# handover生成機能のユニットテスト（必ず失敗する）
# t-wada式TDD: まだ実装が存在しないため、すべてのテストが失敗することを確認

# テスト環境のセットアップ
setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export LOG_DIR="$TEST_DIR/.claude/logs"
    export PLANNER_DIR="$TEST_DIR/.claude/planner"
    export BUILDER_DIR="$TEST_DIR/.claude/builder"
    export SHARED_DIR="$TEST_DIR/.claude/shared"

    # テスト用のディレクトリ構造を作成
    mkdir -p "$LOG_DIR"
    mkdir -p "$PLANNER_DIR"
    mkdir -p "$BUILDER_DIR"
    mkdir -p "$SHARED_DIR"
    mkdir -p "$TEST_DIR/.claude/agents"

    # テスト用データファイルの作成
    # notes.mdにテストデータを追加
    cat > "$PLANNER_DIR/notes.md" << 'EOF'
# Planner Notes

## 現在のPhase: Sprint 1.3
- 開始日: 2025-09-15
- 目的: Handover生成機能の実装

## Phase内のToDo（優先順）
- [x] Phase 1: 基礎構造の構築（完了）
- [ ] Phase 2: エージェントファイルの実装（進行中）
- [ ] Phase 3: 切り替えコマンドの実装

## 最近の活動
- 2025-09-15 10:00: Sprint 1.2を完了
- 2025-09-15 11:00: セキュリティレビューを実施
- 2025-09-15 12:00: Sprint 1.3を開始

## 決定事項
- エージェントは2つ（Planner/Builder）に限定
- Phase/ToDo の2階層管理を採用（SoWは不採用）
- 割り込み処理は専用handoverファイルで対応

## 課題・懸念
- 既存のcore/current.mdとの統合方法
- エージェント切り替えの使い勝手
EOF

    # phase-todo.mdの作成
    cat > "$SHARED_DIR/phase-todo.md" << 'EOF'
## Current Phase: Sprint 1.3

### Active Tasks
- [ ] Task 1.3.1: handover-gen.sh テスト作成
- [ ] Task 1.3.2: 抽出関数の実装
- [ ] Task 1.3.3: リファクタリング

### Completed Tasks
- [x] Sprint 1.1: 共通ライブラリ
- [x] Sprint 1.2: エージェント切り替え
EOF

    # active.jsonの作成
    cat > "$TEST_DIR/.claude/agents/active.json" << 'EOF'
{
  "current_agent": "planner",
  "last_updated": "2025-09-15T12:00:00Z"
}
EOF

    # Gitリポジトリの初期化とテストコミット
    cd "$TEST_DIR"
    git init >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > test.txt
    git add test.txt
    git commit -m "Initial commit" >/dev/null 2>&1
}

# テスト環境のクリーンアップ
teardown() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# =============================================================================
# テストグループ1: 最近の活動抽出テスト
# =============================================================================

@test "extract_recent_activities extracts recent activities from notes" {
    # 実装ファイルを読み込む（まだ存在しない）
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    # 最近の活動を抽出
    run extract_recent_activities "$PLANNER_DIR/notes.md"

    [ "$status" -eq 0 ]
    # 最近の活動が含まれているか確認
    [[ "$output" == *"Sprint 1.2を完了"* ]]
    [[ "$output" == *"セキュリティレビューを実施"* ]]
    [[ "$output" == *"Sprint 1.3を開始"* ]]
}

@test "extract_recent_activities handles empty notes file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    # 空のnotesファイルを作成
    touch "$TEST_DIR/empty-notes.md"

    run extract_recent_activities "$TEST_DIR/empty-notes.md"

    [ "$status" -eq 0 ]
    [ -z "$output" ] || [[ "$output" == *"No recent activities"* ]]
}

@test "extract_recent_activities handles missing file gracefully" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run extract_recent_activities "/nonexistent/file.md"

    [ "$status" -eq 1 ]
    [[ "$output" == *"File not found"* ]] || [[ "$output" == *"Error"* ]]
}

# =============================================================================
# テストグループ2: 現在のタスク抽出テスト
# =============================================================================

@test "extract_current_tasks extracts active tasks from phase-todo" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run extract_current_tasks "$SHARED_DIR/phase-todo.md"

    [ "$status" -eq 0 ]
    # アクティブなタスクが含まれているか
    [[ "$output" == *"Task 1.3.1"* ]]
    [[ "$output" == *"Task 1.3.2"* ]]
    [[ "$output" == *"Task 1.3.3"* ]]
}

@test "extract_current_tasks identifies task status correctly" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run extract_current_tasks "$SHARED_DIR/phase-todo.md"

    [ "$status" -eq 0 ]
    # 未完了タスクのみが抽出されているか
    [[ "$output" != *"Sprint 1.1"* ]]  # 完了済みは含まない
    [[ "$output" != *"Sprint 1.2"* ]]  # 完了済みは含まない
}

# =============================================================================
# テストグループ3: 重要な決定事項抽出テスト
# =============================================================================

@test "extract_key_decisions extracts decisions from notes" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run extract_key_decisions "$PLANNER_DIR/notes.md"

    [ "$status" -eq 0 ]
    # 決定事項が含まれているか
    [[ "$output" == *"エージェントは2つ"* ]]
    [[ "$output" == *"Phase/ToDo の2階層管理"* ]]
}

@test "extract_key_decisions handles no decisions section" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    # 決定事項セクションがないファイルを作成
    echo "# Notes without decisions" > "$TEST_DIR/no-decisions.md"

    run extract_key_decisions "$TEST_DIR/no-decisions.md"

    [ "$status" -eq 0 ]
    [ -z "$output" ] || [[ "$output" == *"No decisions"* ]]
}

# =============================================================================
# テストグループ4: 推奨事項生成テスト
# =============================================================================

@test "generate_recommendations creates recommendations based on context" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run generate_recommendations "planner" "builder"

    [ "$status" -eq 0 ]
    # 推奨事項が生成されているか
    [[ "$output" == *"実装"* ]] || [[ "$output" == *"開発"* ]]
    [ -n "$output" ]
}

@test "generate_recommendations handles same agent transition" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run generate_recommendations "planner" "planner"

    [ "$status" -eq 0 ]
    # 同じエージェントへの引き継ぎの場合
    [[ "$output" == *"継続"* ]] || [[ "$output" == *"Continue"* ]]
}

# =============================================================================
# テストグループ5: Git状態取得テスト
# =============================================================================

@test "get_git_status retrieves current git information" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    # テストファイルを変更
    echo "modified" >> "$TEST_DIR/test.txt"

    run get_git_status "$TEST_DIR"

    [ "$status" -eq 0 ]
    # Git情報が含まれているか
    [[ "$output" == *"modified"* ]] || [[ "$output" == *"test.txt"* ]]
}

@test "get_git_status handles non-git directory" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    # Git以外のディレクトリ
    local non_git_dir="$(mktemp -d)"

    run get_git_status "$non_git_dir"

    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    [[ "$output" == *"not a git repository"* ]] || [ -z "$output" ]

    rm -rf "$non_git_dir"
}

# =============================================================================
# テストグループ6: メイン処理（Handover生成）統合テスト
# =============================================================================

@test "generate_handover creates complete handover document" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run generate_handover "planner" "builder" "$TEST_DIR"

    [ "$status" -eq 0 ]
    # handoverファイルが作成されたか
    [ -f "$PLANNER_DIR/handover.md" ]

    # 必要なセクションが含まれているか
    local content=$(cat "$PLANNER_DIR/handover.md")
    [[ "$content" == *"From: Planner"* ]]
    [[ "$content" == *"To: Builder"* ]]
    [[ "$content" == *"完了した作業"* ]]
    [[ "$content" == *"次のエージェントへの申し送り"* ]]
}

@test "generate_handover includes timestamp" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run generate_handover "planner" "builder" "$TEST_DIR"

    [ "$status" -eq 0 ]
    [ -f "$PLANNER_DIR/handover.md" ]

    # タイムスタンプが含まれているか
    local content=$(cat "$PLANNER_DIR/handover.md")
    [[ "$content" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]
}

@test "generate_handover handles builder to planner transition" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run generate_handover "builder" "planner" "$TEST_DIR"

    [ "$status" -eq 0 ]
    [ -f "$BUILDER_DIR/handover.md" ]

    # Builder → Plannerの引き継ぎ内容
    local content=$(cat "$BUILDER_DIR/handover.md")
    [[ "$content" == *"From: Builder"* ]]
    [[ "$content" == *"To: Planner"* ]]
}

# =============================================================================
# テストグループ7: エラーハンドリングテスト
# =============================================================================

@test "error handling for invalid agent names" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run generate_handover "invalid" "builder" "$TEST_DIR"

    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid agent"* ]] || [[ "$output" == *"Error"* ]]
}

@test "error handling for missing project directory" {
    source "${BATS_TEST_DIRNAME}/../../hooks/handover/handover-gen.sh"

    run generate_handover "planner" "builder" "/nonexistent"

    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]] || [[ "$output" == *"Error"* ]]
}
