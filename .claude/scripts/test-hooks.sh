#!/bin/bash

# Claude Code Hooks Test Script
# 設定されたhooksの動作を安全にテストします

echo "=== Claude Code Hooks テスト ==="
echo "設定されたhooksの動作確認を行います"
echo ""

# テストログファイル
TEST_LOG="test-hooks.log"
echo "テスト開始: $(date)" > "$TEST_LOG"

# 1. Activity Logger のテスト
echo "1. Activity Logger テスト"
echo "========================="

# 環境変数を設定してテスト実行
export CLAUDE_TOOL_NAME="Edit"
export CLAUDE_FILE_PATHS="test-file.py"

if .claude/scripts/activity-logger.sh; then
    echo "  ✓ PASS - Activity Logger正常動作"
    echo "ACTIVITY_LOGGER_TEST: PASS" >> "$TEST_LOG"
else
    echo "  ✗ FAIL - Activity Loggerエラー"
    echo "ACTIVITY_LOGGER_TEST: FAIL" >> "$TEST_LOG"
fi

# 2. Auto Format のテスト（安全なテスト）
echo ""
echo "2. Auto Format テスト"
echo "===================="

# テスト用の一時ファイルを作成
temp_file="test_format_temp.py"
echo "def hello():
    print('hello world')" > "$temp_file"

export CLAUDE_TOOL_NAME="Edit"
export CLAUDE_FILE_PATHS="$temp_file"

if .claude/scripts/auto-format.sh; then
    echo "  ✓ PASS - Auto Format正常動作"
    echo "AUTO_FORMAT_TEST: PASS" >> "$TEST_LOG"
else
    echo "  ✗ FAIL - Auto Formatエラー"
    echo "AUTO_FORMAT_TEST: FAIL" >> "$TEST_LOG"
fi

# テスト用ファイルを削除
rm -f "$temp_file"

# 3. Session Complete のテスト
echo ""
echo "3. Session Complete テスト"
echo "=========================="

if .claude/scripts/session-complete.sh; then
    echo "  ✓ PASS - Session Complete正常動作"
    echo "SESSION_COMPLETE_TEST: PASS" >> "$TEST_LOG"
else
    echo "  ✗ FAIL - Session Completeエラー"
    echo "SESSION_COMPLETE_TEST: FAIL" >> "$TEST_LOG"
fi

# 4. Security Check のテスト（既存）
echo ""
echo "4. Security Check テスト"
echo "======================="

# 安全なコマンドのテスト
echo "ls -la" | .claude/scripts/deny-check.sh >/dev/null 2>&1
safe_result=$?

# 危険なコマンドのテスト
echo "rm -rf /" | .claude/scripts/deny-check.sh >/dev/null 2>&1
danger_result=$?

if [ $safe_result -eq 0 ] && [ $danger_result -ne 0 ]; then
    echo "  ✓ PASS - Security Check正常動作（安全コマンド許可、危険コマンド拒否）"
    echo "SECURITY_CHECK_TEST: PASS" >> "$TEST_LOG"
else
    echo "  ✗ FAIL - Security Checkエラー"
    echo "SECURITY_CHECK_TEST: FAIL" >> "$TEST_LOG"
fi

# 5. ログファイルの確認
echo ""
echo "5. ログファイル確認"
echo "=================="

logs_created=0

if [ -f "${HOME}/.claude/activity.log" ]; then
    echo "  ✓ Activity log作成済み"
    logs_created=$((logs_created + 1))
fi

if [ -f "${HOME}/.claude/session.log" ]; then
    echo "  ✓ Session log作成済み"
    logs_created=$((logs_created + 1))
fi

if [ -f "${HOME}/.claude/format.log" ]; then
    echo "  ✓ Format log作成済み"
    logs_created=$((logs_created + 1))
fi

if [ $logs_created -gt 0 ]; then
    echo "  ✓ PASS - ログファイル作成確認（$logs_created個）"
    echo "LOG_FILES_TEST: PASS ($logs_created files)" >> "$TEST_LOG"
else
    echo "  ✗ FAIL - ログファイル作成されていません"
    echo "LOG_FILES_TEST: FAIL" >> "$TEST_LOG"
fi

# 結果サマリー
echo ""
echo "6. 結果サマリー"
echo "==============="

pass_count=$(grep "PASS" "$TEST_LOG" | wc -l)
fail_count=$(grep "FAIL" "$TEST_LOG" | wc -l)
total_tests=$((pass_count + fail_count))

echo "テスト完了: $pass_count/$total_tests passed"

if [ $fail_count -eq 0 ]; then
    echo "🎉 すべてのhooksが正常に動作しています"
    exit 0
else
    echo "⚠️  一部のhooksでエラーが発生しました"
    echo "詳細: $TEST_LOG を確認してください"
    exit 1
fi
