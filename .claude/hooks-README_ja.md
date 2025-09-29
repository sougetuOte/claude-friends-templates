# Claude Code Hooks システム

🌐 **[English](hooks-README.md)** | **日本語**

このプロジェクトには開発効率向上のため、Claude Code hooksが統合されています。

## 実装済みHooks機能

### 1. セキュリティHooks（PreToolUse）
**スクリプト**: `.claude/scripts/deny-check.sh`
- **目的**: 危険なBashコマンドの実行前チェック
- **対象**: `rm -rf /`, `chmod 777`, `curl | sh` 等の破壊的コマンド
- **動作**: 危険と判定されたコマンドは実行前に自動ブロック

### 2. 自動フォーマットHooks（PostToolUse）
**スクリプト**: `.claude/scripts/auto-format.sh`
- **目的**: ファイル編集後の自動コードフォーマット
- **対象**: `.py`, `.js`, `.ts`, `.rs`, `.go`, `.json` ファイル
- **動作**:
  - Python: `ruff format` または `black`
  - JavaScript/TypeScript: `prettier`
  - Rust: `rustfmt`
  - Go: `gofmt`
  - JSON: `jq`

### 3. 活動ログHooks（PostToolUse）
**スクリプト**: `.claude/scripts/activity-logger.sh`
- **目的**: 開発活動の自動記録・追跡
- **ログファイル**: `~/.claude/activity.log`, `~/.claude/metrics.log`
- **記録内容**:
  - 使用ツール名・実行時刻
  - 編集対象ファイル・サイズ・拡張子
  - 操作種別の分類（CODE_EDIT, FILE_READ, COMMAND_EXEC等）

### 4. AI-Friendly Logger V2 Hooks（PostToolUse）
**スクリプト**: `.claude/scripts/ai-logger.sh`
- **目的**: AI分析に最適化された構造化ログ（[Vibe Logger](https://github.com/fladdict/vibe-logger)概念採用）
- **ログファイル**: `~/.claude/ai-activity.jsonl`
- **機能**:
  - 効率的なAI解析のためのJSONL形式
  - 豊富なコンテキスト（プロジェクト、環境、Git情報）
  - AIメタデータ（デバッグヒント、優先度、推奨アクション）
  - 相関ID追跡
  - `analyze-ai-logs.py`によるエラーパターン分析

### 5. セッション完了Hooks（Stop）
**スクリプト**: `.claude/scripts/session-complete.sh`
- **目的**: 作業セッション終了時の状況サマリー
- **ログファイル**: `~/.claude/session.log`
- **記録内容**:
  - Git状況（変更ファイル数、ブランチ情報）
  - セッション中の活動サマリー
  - ツール使用統計

### 6. Notes自動ローテーションHooks（UserPromptSubmit）
**スクリプト**: `.claude/scripts/notes-check-hook.sh`
- **目的**: notes.mdファイルの肥大化を防ぐための自動ローテーション
- **トリガー**: `/agent:planner`または`/agent:builder`コマンド実行時
- **動作**:
  - notes.mdが450行を超えているかチェック
  - 閾値を超えていたら自動的にローテーション＆アーカイブ
  - ローテーション後にインデックスファイルを更新
  - カラー表示で通知

## ログファイル構成

```
~/.claude/
├── activity.log           # 詳細な活動ログ
├── metrics.log            # 操作種別メトリクス
├── session.log            # セッションサマリー
├── format.log             # フォーマット実行ログ
├── security.log           # セキュリティブロックログ
└── ai-activity.jsonl      # AI最適化構造化ログ（Vibe Logger形式）
```

## Hooks設定（.claude/settings.json）

```json
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  },
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
            "command": ".claude/scripts/auto-format.sh"
          }
        ]
      },
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/activity-logger.sh"
          },
          {
            "type": "command",
            "command": ".claude/scripts/ai-logger.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/session-complete.sh"
          }
        ]
      }
    ]
  }
}
```

## テスト・運用

### Hooksテスト実行
```bash
# 全hooks機能のテスト
.claude/scripts/test-hooks.sh

# セキュリティ機能のみテスト
.claude/scripts/test-security.sh
```

### ログ確認
```bash
# 活動ログの確認
tail -f ~/.claude/activity.log

# セッション履歴の確認
cat ~/.claude/session.log

# セキュリティログの確認
tail -f ~/.claude/security.log

# AI最適化ログの確認（リアルタイム）
tail -f ~/.claude/ai-activity.jsonl

# AIログのインサイト付き分析
.claude/scripts/analyze-ai-logs.py --format summary
```

### トラブルシューティング

#### 「Tool: unknown」がログに記録される場合
Claude Codeが環境変数`CLAUDE_TOOL_NAME`を正しく渡していない場合があります。これはClaude Code本体の動作に関わる問題で、ログ機能は正常に動作しています。将来のアップデートで改善される可能性があります。

#### Hooksが動作しない場合
1. スクリプトの実行権限確認: `chmod +x .claude/scripts/*.sh`
2. 設定ファイル確認: `.claude/settings.json` の構文チェック
3. テスト実行: `.claude/scripts/test-hooks.sh` でエラー特定

#### 自動フォーマットが動作しない場合
1. フォーマッター確認: `ruff`, `prettier`, `rustfmt` 等がインストール済みか
2. ファイル拡張子確認: サポート対象（.py, .js, .ts, .rs, .go, .json）か
3. ログ確認: `~/.claude/format.log` でエラー詳細確認

## カスタマイズ

### 新しい言語のフォーマット追加
`auto-format.sh` の case文に追加:
```bash
*.新拡張子)
    if command -v フォーマッター >/dev/null 2>&1; then
        フォーマッター "$file" && log_format "Formatted 言語: $file"
    fi
    ;;
```

### セキュリティルールの追加
`deny-check.sh` の `DANGEROUS_PATTERNS` 配列に追加:
```bash
"新しい危険パターン"
```

### 活動ログのカスタマイズ
`activity-logger.sh` でツール分類の追加・修正:
```bash
"新ツール名")
    echo "[$timestamp] CUSTOM_ACTION" >> "$METRICS_FILE"
    ;;
```

## メリット・効果

- **自動化**: 手動作業の削減（フォーマット、ログ記録等）
- **品質向上**: 一貫したコードフォーマット、セキュリティチェック
- **可視化**: 開発活動・進捗の自動追跡
- **効率化**: 作業終了時の自動サマリー生成
- **安全性**: 危険コマンドの事前ブロック

このhooksシステムにより、Claude Code使用時の開発効率・品質・安全性が大幅に向上します。
