#!/usr/bin/env bats

# Sprint 1.5: README.md更新のテスト【Red Phase】
# t-wada式TDD: 失敗するテストを先に書く

setup() {
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
    export README_MD="$PROJECT_ROOT/README.md"
    export README_JA_MD="$PROJECT_ROOT/README_ja.md"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# =============================================================================
# 1. Hooksシステムの説明が含まれているか
# =============================================================================

@test "README.md contains Hooks system section" {
    # Hooksシステムのセクションが存在することを確認
    run grep -q "## 🔗 Enhanced Hooks System" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md describes agent switching automation" {
    # エージェント切り替え自動化の説明が含まれている
    run grep -q "Automatic agent switching" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md describes handover generation feature" {
    # Handover生成機能の説明が含まれている
    run grep -q "Automatic handover generation" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md describes Memory Bank rotation feature" {
    # Memory Bank自動ローテーション機能の説明が含まれている
    run grep -q "Automatic Memory Bank rotation" "$README_MD"
    [ "$status" -eq 0 ]
}

# =============================================================================
# 2. パフォーマンス実績が記載されているか
# =============================================================================

@test "README.md contains performance metrics section" {
    # パフォーマンス実績のセクションが存在
    run grep -q "## ⚡ Performance Achievements" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md includes response time achievement" {
    # 応答時間の実績が記載されている（< 100ms, p95: 86.368ms）
    run grep -E "response time.*<.*100ms" "$README_MD"
    [ "$status" -eq 0 ]

    # 具体的なp95値も記載されている
    run grep -E "p95.*86" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md includes security detection rate" {
    # セキュリティ検出率が記載されている
    run grep -E "100%.*dangerous command" "$README_MD"
    [ "$status" -eq 0 ]
}

# =============================================================================
# 3. インストール手順が更新されているか
# =============================================================================

@test "README.md contains updated installation steps" {
    # 新しいセットアップスクリプトへの言及
    run grep -q "./setup.sh" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md includes hooks setup instructions" {
    # Hooksシステムのセットアップ手順
    run grep -q ".claude/scripts/test-hooks.sh" "$README_MD"
    [ "$status" -eq 0 ]
}

# =============================================================================
# 4. 設定例（settings.json）が含まれているか
# =============================================================================

@test "README.md contains settings.json example" {
    # settings.jsonの設定例が含まれている
    run grep -q ".claude/settings.json" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md includes UserPromptSubmit hook example" {
    # UserPromptSubmitフックの例が含まれている
    run grep -q "UserPromptSubmit" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md includes PostToolUse hook example" {
    # PostToolUseフックの例が含まれている
    run grep -q "PostToolUse" "$README_MD"
    [ "$status" -eq 0 ]
}

# =============================================================================
# 5. クイックスタートガイドが更新されているか
# =============================================================================

@test "README.md contains hooks quickstart section" {
    # Hooksシステムのクイックスタートセクション
    run grep -q "### 🔗 Hooks System Quick Start" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README.md includes hooks verification commands" {
    # Hooksの動作確認コマンド
    run grep -q "test-hooks.sh" "$README_MD"
    [ "$status" -eq 0 ]
}

# =============================================================================
# 6. バイリンガル対応（日本語版も同様に更新）
# =============================================================================

@test "README_ja.md contains Hooks system section" {
    # 日本語版にもHooksシステムのセクションが存在
    run grep -q "## 🔗 強化されたHooksシステム" "$README_JA_MD"
    [ "$status" -eq 0 ]
}

@test "README_ja.md describes agent switching automation in Japanese" {
    # 日本語版にエージェント切り替え自動化の説明
    run grep -q "エージェント切り替えの自動化" "$README_JA_MD"
    [ "$status" -eq 0 ]
}

@test "README_ja.md contains performance metrics in Japanese" {
    # 日本語版にもパフォーマンス実績が記載
    run grep -q "## ⚡ 性能実績" "$README_JA_MD"
    [ "$status" -eq 0 ]
}

@test "README_ja.md includes response time achievement in Japanese" {
    # 日本語版にも応答時間の実績が記載
    run grep -E "応答時間.*<.*100ms" "$README_JA_MD"
    [ "$status" -eq 0 ]
}

# =============================================================================
# 7. バージョン情報の更新
# =============================================================================

@test "README.md contains version 1.0.0 release info" {
    # バージョン1.0.0のリリース情報
    run grep -E "Version.*1\.0\.0|v1\.0\.0" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README_ja.md contains version 1.0.0 release info" {
    # 日本語版にもバージョン1.0.0の情報
    run grep -E "バージョン.*1\.0\.0|v1\.0\.0" "$README_JA_MD"
    [ "$status" -eq 0 ]
}

# =============================================================================
# 8. トラブルシューティングセクション
# =============================================================================

@test "README.md contains troubleshooting section for hooks" {
    # Hooksのトラブルシューティングセクション
    run grep -q "### 🔧 Troubleshooting Hooks" "$README_MD"
    [ "$status" -eq 0 ]
}

@test "README_ja.md contains troubleshooting section for hooks" {
    # 日本語版のトラブルシューティング
    run grep -q "### 🔧 Hooksのトラブルシューティング" "$README_JA_MD"
    [ "$status" -eq 0 ]
}
