#!/bin/bash

# test-index-generation.sh - index.md自動生成機能のテストスイート

# テスト用の一時ディレクトリ
TEST_DIR="/tmp/test-index-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE_INDEX_SCRIPT="$SCRIPT_DIR/update-index.sh"

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
echo "Index Generation Test Suite"
echo "========================================="

# テスト環境の準備
setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR/.claude/builder/archive"
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

# ファイル内容チェック
assert_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"

    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Pattern not found: $pattern"
        ((FAILED++))
    fi
}

# Test 1: index.mdの基本生成
test_basic_index_generation() {
    echo -e "\n${YELLOW}Test 1: index.mdの基本生成${NC}"
    setup

    # ファイル構造を作成
    echo "# Builder Notes" > .claude/builder/notes.md
    echo "Content" >> .claude/builder/notes.md
    echo "# Summary" > .claude/builder/notes-summary.md
    echo "# Archive 1" > .claude/builder/archive/notes-2025-01-01.md

    echo "# Planner Notes" > .claude/planner/notes.md
    echo "# Archive 2" > .claude/planner/archive/notes-2025-01-02.md

    # index生成スクリプトを実行
    INDEX_DIR="$TEST_DIR/.claude" "$UPDATE_INDEX_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_file_exists ".claude/builder/index.md" "Builder: index.mdが生成される"
    assert_file_exists ".claude/planner/index.md" "Planner: index.mdが生成される"
}

# Test 2: index.mdの内容確認
test_index_content() {
    echo -e "\n${YELLOW}Test 2: index.mdの内容確認${NC}"
    setup

    # 複数のファイルを作成
    echo "# Current Work" > .claude/builder/notes.md
    echo "# Summary of important items" > .claude/builder/notes-summary.md
    echo "# Old notes 1" > .claude/builder/archive/notes-2025-01-01.md
    echo "# Old notes 2" > .claude/builder/archive/notes-2025-01-02.md

    # index生成スクリプトを実行
    INDEX_DIR="$TEST_DIR/.claude" "$UPDATE_INDEX_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_contains ".claude/builder/index.md" "## 現在のファイル" "現在のファイルセクションが含まれる"
    assert_contains ".claude/builder/index.md" "notes.md" "notes.mdがリストされる"
    assert_contains ".claude/builder/index.md" "notes-summary.md" "要約ファイルがリストされる"
    assert_contains ".claude/builder/index.md" "## アーカイブ" "アーカイブセクションが含まれる"
}

# Test 3: 統計情報の生成
test_statistics_generation() {
    echo -e "\n${YELLOW}Test 3: 統計情報の生成${NC}"
    setup

    # サイズの異なるファイルを作成
    for i in {1..100}; do
        echo "Line $i" >> .claude/builder/notes.md
    done

    for i in {1..50}; do
        echo "Summary line $i" >> .claude/builder/notes-summary.md
    done

    # index生成スクリプトを実行
    INDEX_DIR="$TEST_DIR/.claude" "$UPDATE_INDEX_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_contains ".claude/builder/index.md" "## 統計情報" "統計情報セクションが含まれる"
    assert_contains ".claude/builder/index.md" "総ファイル数:" "ファイル数が表示される"
    assert_contains ".claude/builder/index.md" "最終更新:" "最終更新日時が表示される"
}

# Test 4: 空ディレクトリでの動作
test_empty_directory() {
    echo -e "\n${YELLOW}Test 4: 空ディレクトリでの動作${NC}"
    setup

    # 空のディレクトリで実行
    INDEX_DIR="$TEST_DIR/.claude" "$UPDATE_INDEX_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_file_exists ".claude/builder/index.md" "空でもindex.mdが生成される"
    assert_contains ".claude/builder/index.md" "# Builder Index" "ヘッダーが含まれる"
}

# Test 5: 更新時の動作
test_index_update() {
    echo -e "\n${YELLOW}Test 5: index.md更新時の動作${NC}"
    setup

    # 初回生成
    echo "# Initial content" > .claude/builder/notes.md
    INDEX_DIR="$TEST_DIR/.claude" "$UPDATE_INDEX_SCRIPT" >/dev/null 2>&1 || true

    # ファイルを追加
    echo "# New archive" > .claude/builder/archive/notes-2025-03-01.md

    # 再度実行
    INDEX_DIR="$TEST_DIR/.claude" "$UPDATE_INDEX_SCRIPT" >/dev/null 2>&1 || true

    # アサーション
    assert_contains ".claude/builder/index.md" "notes-2025-03-01.md" "新しいファイルが追加される"
}

# すべてのテストを実行
run_all_tests() {
    test_basic_index_generation
    test_index_content
    test_statistics_generation
    test_empty_directory
    test_index_update
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
