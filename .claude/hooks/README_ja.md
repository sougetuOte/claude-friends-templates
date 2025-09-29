# Claude Code フックシステム - 実装

🌐 **[English](README.md)** | **日本語**

このディレクトリには、claude-friends-templatesシステムに自動化、セキュリティ、品質保証機能を提供するClaude Codeフックのコア実装が含まれています。

## 📁 ディレクトリ構造

```
hooks/
├── common/                    # 共有ユーティリティとライブラリ
│   ├── hook-common.sh        # 共通関数とユーティリティ
│   ├── json-utils.sh         # JSON解析と操作
│   ├── hook-common.sh.orig   # オリジナルバックアップ（パッチシステム）
│   └── hook-common.sh.rej    # パッチ拒否ファイル
├── agent/                    # エージェント固有フック
│   └── agent-switch.sh       # エージェント切り替え自動化
└── handover/                 # ハンドオーバー管理フック
    └── handover-gen.sh       # ハンドオーバードキュメント生成
```

## 🔧 フックコンポーネント

### 共通ユーティリティ (`common/`)

#### `hook-common.sh`
**目的**: 全フック間で使用されるコアユーティリティ関数
**関数**:
- `log_activity()`: 標準化されたログ関数
- `get_timestamp()`: ISO 8601タイムスタンプ生成
- `check_permissions()`: ファイル権限検証
- `sanitize_input()`: セキュリティのための入力無害化
- `validate_json()`: JSON形式検証

**使用例**:
```bash
#!/bin/bash
source .claude/hooks/common/hook-common.sh

# 活動をログ
log_activity "INFO" "フックが正常に実行されました"

# 現在のタイムスタンプを取得
timestamp=$(get_timestamp)
echo "現在時刻: $timestamp"
```

#### `json-utils.sh`
**目的**: 設定とデータ処理のためのJSON操作ユーティリティ
**関数**:
- `parse_json()`: JSONファイルから値を抽出
- `validate_json_file()`: JSONファイル構造を検証
- `merge_json()`: JSONオブジェクトをマージ
- `format_json()`: JSONを整形出力

**使用例**:
```bash
#!/bin/bash
source .claude/hooks/common/json-utils.sh

# エージェント設定を解析
agent_name=$(parse_json ".claude/agents/active.json" ".current_agent")
echo "現在のエージェント: $agent_name"
```

### エージェントフック (`agent/`)

#### `agent-switch.sh`
**目的**: エージェント切り替え自動化とコンテキスト保持を処理
**機能**:
- エージェント切り替えリクエストを検証
- `active.json`でエージェント状態を更新
- ハンドオーバー生成をトリガー
- エージェント切り替え活動をログ

**フック設定**:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "/agent:(planner|builder|sync-specialist)",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/agent/agent-switch.sh"
          }
        ]
      }
    ]
  }
}
```

**パラメータ**:
- `$1`: フックをトリガーしたコマンド
- `$2`: 新しいエージェント名
- `$3`: 現在の作業ディレクトリ

**使用例**:
```bash
# エージェント切り替えを手動でトリガー
.claude/hooks/agent/agent-switch.sh "/agent:builder" "builder" "$(pwd)"
```

### ハンドオーバーフック (`handover/`)

#### `handover-gen.sh`
**目的**: エージェント遷移のための包括的なハンドオーバードキュメントを生成
**機能**:
- 現在のプロジェクト状態をキャプチャ
- 最近の変更と決定を文書化
- TDDフェーズ状態を保持
- 構造化されたハンドオーバーファイルを作成

**生成されるハンドオーバー構造**:
```markdown
# ハンドオーバー: [前のエージェント] → [新しいエージェント]
日付: [ISO 8601タイムスタンプ]
プロジェクト: [プロジェクト名]

## 現在の状態
- **フェーズ**: [TDDフェーズ]
- **ブランチ**: [Gitブランチ]
- **最終変更**: [ファイルリスト]

## コンテキスト要約
[最近の活動の自動要約]

## 変更されたファイル（過去24時間）
- path/to/file1.ext - [変更説明]
- path/to/file2.ext - [変更説明]

## テスト状態
[現在のテスト結果とカバレッジ]

## 次のアクション
[コンテキストに基づく提案された次のステップ]

## デバッグ情報
[エラーコンテキストとデバッグヒント]
```

**設定オプション**:
```bash
# カスタマイズ用環境変数
export HANDOVER_RETENTION_DAYS=7    # ハンドオーバーを7日間保持
export HANDOVER_MAX_FILES=50        # ファイルリストを50エントリに制限
export HANDOVER_INCLUDE_TESTS=true  # テスト状態を含める
```

## 🚀 フック実装

### セキュリティ機能

すべてのフックはセキュリティのベストプラクティスを実装：

1. **入力検証**: すべてのユーザー入力を無害化
2. **パス検証**: ディレクトリトラバーサル攻撃に対してファイルパスを検証
3. **権限チェック**: 操作前にファイル権限を確認
4. **エラーハンドリング**: 詳細なログによる適切な失敗処理

### パフォーマンス最適化

フックは最小限の影響のために最適化：

1. **遅延読み込み**: 必要時のみユーティリティを読み込み
2. **キャッシング**: 繰り返し操作を効率のためキャッシュ
3. **バックグラウンド実行**: 非重要操作をバックグラウンドで実行
4. **リソース制限**: メモリとCPU使用量を制約

### エラーハンドリング

全コンポーネントにわたる堅牢なエラーハンドリング：

```bash
# エラーハンドリングパターンの例
if ! command_that_might_fail; then
    log_activity "ERROR" "コマンドが失敗しました: $?"
    # 復旧を試行
    if ! recovery_command; then
        log_activity "FATAL" "復旧に失敗、中断します"
        exit 1
    fi
fi
```

## 🔧 設定

### フック登録

フックは`.claude/settings.json`に登録：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/deny-check.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/common/hook-common.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "/agent:",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/agent/agent-switch.sh"
          }
        ]
      }
    ]
  }
}
```

### 環境変数

| 変数 | 目的 | デフォルト | 例 |
|------|------|------------|-----|
| `CLAUDE_HOOKS_DEBUG` | デバッグログを有効化 | `false` | `true` |
| `CLAUDE_HOOKS_TIMEOUT` | フック実行タイムアウト | `30` | `60` |
| `CLAUDE_LOG_LEVEL` | ログ詳細度 | `INFO` | `DEBUG` |
| `CLAUDE_HOOKS_DIR` | フックディレクトリパス | `.claude/hooks` | `/custom/path` |

## 🧪 テスト

### ユニットテスト

個別フックコンポーネントをテスト可能：

```bash
# 共通ユーティリティをテスト
.claude/tests/bats/test_hook_common.bats

# JSONユーティリティをテスト
.claude/tests/bats/test_json_utils.bats

# エージェント切り替え機能をテスト
.claude/tests/bats/test_agent_switch.bats

# ハンドオーバー生成をテスト
.claude/tests/bats/test_handover_gen.bats
```

### 統合テスト

完全なフックシステムテスト：

```bash
# 完全フックワークフローをテスト
.claude/scripts/test-hooks.sh

# 特定シナリオでテスト
.claude/tests/e2e/test_e2e_phase1.bats
```

### パフォーマンステスト

フックパフォーマンス監視：

```bash
# フック実行時間をベンチマーク
.claude/tests/performance/benchmark-hooks.sh

# リソース使用量を監視
.claude/tests/performance/comprehensive-performance-test.sh
```

## 🔍 デバッグ

### デバッグモード

詳細ログのためのデバッグモード有効化：

```bash
export CLAUDE_HOOKS_DEBUG=true
export CLAUDE_LOG_LEVEL=DEBUG

# デバッグ出力で実行
.claude/hooks/agent/agent-switch.sh "/agent:planner" "planner" "$(pwd)"
```

### ログファイル

フック活動は以下にログ：

```
~/.claude/
├── hook-debug.log         # デバッグ情報
├── hook-errors.log        # エラーメッセージ
├── agent-switch.log       # エージェント切り替え活動
└── handover-gen.log       # ハンドオーバー生成ログ
```

### よくある問題

| 問題 | 症状 | 解決方法 |
|------|------|----------|
| 権限拒否 | フック実行失敗 | `chmod +x .claude/hooks/**/*.sh` |
| JSON解析エラー | 無効なJSON形式 | `jq`または`validate_json()`で検証 |
| エージェント切り替えタイムアウト | エージェント切り替えが遅い | `CLAUDE_HOOKS_TIMEOUT`設定を確認 |
| 依存関係不足 | フックコンポーネント失敗 | 必要ツール（jq、gitなど）をインストール |

## 🛠️ カスタマイズ

### 新しいフックの追加

1. 適切なサブディレクトリに**フックスクリプトを作成**
2. 適切なマッチャーで**settings.jsonに登録**
3. `.claude/tests/bats/`に**テストを追加**
4. 使用例で**ドキュメントを更新**

新しいフックの例：

```bash
#!/bin/bash
# .claude/hooks/quality/code-review.sh

source .claude/hooks/common/hook-common.sh

# コードレビューチェックを実行
log_activity "INFO" "コードレビューフックを開始"

# カスタムロジックをここに
if [ "$1" = "Write" ] || [ "$1" = "Edit" ]; then
    # コード品質をチェック
    echo "コード品質をレビュー中..."
fi

log_activity "INFO" "コードレビューフックが完了"
```

### 共通ユーティリティの拡張

`hook-common.sh`に新しい関数を追加：

```bash
# 新しいユーティリティ関数
validate_file_extension() {
    local file="$1"
    local extension="${file##*.}"

    case "$extension" in
        py|js|ts|rs|go)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
```

### カスタムエージェントフック

新しいエージェント用の専用フックを作成：

```bash
# .claude/hooks/agent/custom-agent.sh
#!/bin/bash

source .claude/hooks/common/hook-common.sh

# カスタムエージェントロジック
handle_custom_agent_switch() {
    log_activity "INFO" "カスタムエージェントに切り替え中"
    # カスタム実装
}
```

## 📚 ベストプラクティス

### フック開発

1. **共通ユーティリティを使用**: `hook-common.sh`の既存関数を活用
2. **エラーハンドリング**: 常に包括的なエラーハンドリングを含める
3. **ログ**: 標準化されたログ関数を使用
4. **テスト**: 新しいフック機能のテストを書く
5. **ドキュメント**: 新しいフックについてこのREADMEを更新

### パフォーマンスガイドライン

1. **実行時間を最小化**: フックを軽量に保つ
2. **バックグラウンド処理**: 非重要タスクにはバックグラウンドジョブを使用
3. **リソース監視**: メモリとCPU使用量を監視
4. **キャッシング**: 可能な場合は高価な操作をキャッシュ

### セキュリティ考慮事項

1. **入力検証**: 常に入力を検証・無害化
2. **パス安全性**: ディレクトリトラバーサル攻撃を防止
3. **権限チェック**: 操作前にファイル権限を確認
4. **監査ログ**: セキュリティ関連活動をログ

## 🔗 統合ポイント

### scriptsディレクトリとの統合

フックは自動化スクリプトと統合：
- `scripts/ai-logger.sh`: 活動ログ
- `scripts/auto-format.sh`: コードフォーマット
- `scripts/deny-check.sh`: セキュリティ検証

### エージェントシステムとの統合

フックはエージェント連携をサポート：
- エージェント間の状態同期
- ハンドオーバードキュメント生成
- 切り替え間のコンテキスト保持

### テストフレームワークとの統合

フックはテストインフラと統合：
- 自動テスト実行
- 品質ゲート強制
- TDDフェーズ追跡

---

**注意**: このフックシステムは拡張性と保守性を考慮して設計されています。新機能を追加する際は、確立されたパターンに従い、実装とドキュメントの両方を更新してください。
