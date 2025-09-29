#!/bin/bash

# test-notes-rotation.sh - notes.mdローテーション機能のテストスイート

# set -e はテストでは使用しない（個別のテストが失敗しても続行するため）

# テスト用の一時ディレクトリ
TEST_DIR="/tmp/test-notes-rotation-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROTATION_SCRIPT="$SCRIPT_DIR/rotate-notes.sh"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# テスト結果カウンタ
PASSED=0
FAILED=0

# クリーンアップ関数
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# テスト開始
echo "========================================="
echo "Notes Rotation Test Suite"
echo "========================================="

# テスト環境の準備
setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR/.claude/builder"
    mkdir -p "$TEST_DIR/.claude/builder/archive"
    mkdir -p "$TEST_DIR/.claude/planner"
    mkdir -p "$TEST_DIR/.claude/planner/archive"
    cd "$TEST_DIR"
}

# テスト結果を表示
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((FAILED++))
    fi
}

# ファイル存在チェック
assert_file_exists() {
    local file="$1"
    local message="$2"

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File not found: $file"
        ((FAILED++))
    fi
}

# ファイル非存在チェック
assert_file_not_exists() {
    local file="$1"
    local message="$2"

    if [ ! -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File should not exist: $file"
        ((FAILED++))
    fi
}

# Test 1: 500行未満の場合はローテーションしない
test_no_rotation_under_threshold() {
    echo -e "\n${YELLOW}Test 1: ローテーション閾値未満（500行未満）${NC}"
    setup

    # 100行のファイルを作成
    for i in {1..100}; do
        echo "Line $i" >> .claude/builder/notes.md
    done

    # ローテーションスクリプトを実行（ログを抑制）
    NOTES_DIR="$TEST_DIR/.claude/builder" "$ROTATION_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_file_exists ".claude/builder/notes.md" "notes.mdは維持される"
    # バックアップファイルの確認（archiveディレクトリ内）
    local archive_count=$(ls .claude/builder/archive/notes-*.md 2>/dev/null | wc -l)
    assert_equals "0" "$archive_count" "アーカイブは作成されない"

    local line_count=$(wc -l < .claude/builder/notes.md)
    assert_equals "100" "$line_count" "行数は変更されない"
}

# Test 2: 500行以上の場合はローテーションする
test_rotation_over_threshold() {
    echo -e "\n${YELLOW}Test 2: ローテーション閾値超過（500行以上）${NC}"
    setup

    # 501行のファイルを作成
    for i in {1..501}; do
        echo "Line $i - Important content" >> .claude/builder/notes.md
    done

    # 元のファイルのハッシュを記録
    local original_hash=$(md5sum .claude/builder/notes.md | cut -d' ' -f1)

    # ローテーションスクリプトを実行（ログを抑制）
    NOTES_DIR="$TEST_DIR/.claude/builder" "$ROTATION_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_file_exists ".claude/builder/notes.md" "新しいnotes.mdが作成される"
    assert_file_exists ".claude/builder/archive/notes-"*".md" "アーカイブファイルが作成される"

    # 新しいnotes.mdが空または少ない行数であることを確認
    local new_line_count=$(wc -l < .claude/builder/notes.md 2>/dev/null || echo "0")
    if [ "$new_line_count" -lt "501" ]; then
        echo -e "${GREEN}✓${NC} 新しいnotes.mdは初期状態"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} 新しいnotes.mdが正しく初期化されていない"
        ((FAILED++))
    fi
}

# Test 3: 要約ファイルが生成される
test_summary_generation() {
    echo -e "\n${YELLOW}Test 3: 要約ファイルの生成${NC}"
    setup

    # 重要なコンテンツを含むファイルを作成
    cat > .claude/builder/notes.md << 'EOF'
# Builder Notes

## 重要な決定事項
- 決定: APIのエンドポイントを/api/v2に変更

### 実装済みタスク
- [x] ユーザー認証機能
- [ ] メール送信機能

## 技術的課題
重要: データベースのパフォーマンス改善が必要

普通の行1
普通の行2
EOF

    # 500行超にする
    for i in {1..500}; do
        echo "Filler line $i" >> .claude/builder/notes.md
    done

    # ローテーションスクリプトを実行（ログを抑制）
    NOTES_DIR="$TEST_DIR/.claude/builder" "$ROTATION_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_file_exists ".claude/builder/notes-summary.md" "要約ファイルが生成される"

    # 要約に重要な内容が含まれているか確認
    if [ -f ".claude/builder/notes-summary.md" ]; then
        if grep -q "決定:" .claude/builder/notes-summary.md 2>/dev/null; then
            echo -e "${GREEN}✓${NC} 要約に決定事項が含まれる"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} 要約に決定事項が含まれていない"
            ((FAILED++))
        fi
    fi
}

# Test 4: Plannerディレクトリでも動作する
test_planner_directory() {
    echo -e "\n${YELLOW}Test 4: Plannerディレクトリでの動作${NC}"
    setup

    # Planner用のファイルを作成
    for i in {1..501}; do
        echo "Planner note $i" >> .claude/planner/notes.md
    done

    # Planner用にローテーションスクリプトを実行
    NOTES_DIR="$TEST_DIR/.claude/planner" "$ROTATION_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_file_exists ".claude/planner/notes.md" "Planner: 新しいnotes.mdが作成される"
    assert_file_exists ".claude/planner/archive/notes-"*".md" "Planner: アーカイブが作成される"
}

# Test 5: 既存のバックアップがある場合の処理
test_existing_backup_handling() {
    echo -e "\n${YELLOW}Test 5: 既存バックアップの処理${NC}"
    setup

    # 既存のアーカイブを作成
    echo "Old archive" > ".claude/builder/archive/notes-2025-01-01.md"

    # 新しいローテーション対象を作成
    for i in {1..501}; do
        echo "New line $i" >> .claude/builder/notes.md
    done

    # ローテーションスクリプトを実行（ログを抑制）
    NOTES_DIR="$TEST_DIR/.claude/builder" "$ROTATION_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_file_exists ".claude/builder/archive/notes-2025-01-01.md" "既存のアーカイブは保持される"

    # 新しいアーカイブも作成されているか確認
    local archive_count=$(ls .claude/builder/archive/notes-*.md 2>/dev/null | wc -l)
    if [ "$archive_count" -ge "2" ]; then
        echo -e "${GREEN}✓${NC} 複数のアーカイブが共存できる"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} 新しいアーカイブが作成されていない"
        ((FAILED++))
    fi
}

# すべてのテストを実行
run_all_tests() {
    test_no_rotation_under_threshold
    test_rotation_over_threshold
    test_summary_generation
    test_planner_directory
    test_existing_backup_handling
}

# メイン実行
run_all_tests

# 結果サマリー
echo ""
echo "========================================="
echo "Test Results Summary"
echo "========================================="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"

if [ "$FAILED" -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC} ✨"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC} 💔"
    exit 1
fi
