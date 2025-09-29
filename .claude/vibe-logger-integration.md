# Vibe Logger Integration Guide

## 概要
このドキュメントは、Vibe Loggerの概念を取り入れた改良版AIロガーの実装ガイドです。

## Vibe Loggerとは
- **開発者**: @fladdict (Andrej Karpathyが提唱したVibeCodingに基づく)
- **目的**: AI駆動開発（VibeCoding）において、LLMが効果的にデバッグできるよう設計されたロギングシステム
- **特徴**: 構造化JSON、豊富なコンテキスト、相関ID追跡、AI用アノテーション

## 現在の実装との主な違い

### 1. ログフォーマット
| 項目 | 現在の実装 | Vibe Logger準拠 |
|------|------------|----------------|
| 形式 | Pretty-printed JSON | JSONL (1行1JSON) |
| 必須フィールド | timestamp, correlation_id | + level, operation, message |
| コンテキスト | 基本的な情報 | 豊富な環境・実行情報 |
| AI用フィールド | ai_hint, human_note | + ai_todo, source |

### 2. 改善点
- **JSONL形式**: 解析が容易で、大規模ログでも効率的
- **ログレベル**: DEBUG/INFO/WARNING/ERROR/CRITICALで分類
- **エラー追跡**: エラー時の詳細コンテキストを別エントリで記録
- **ログローテーション**: 10MB超過時に自動ローテーション

## 移行手順

### ステップ1: 新しいロガーのテスト
```bash
# 現在のロガーをバックアップ
cp .claude/scripts/ai-logger.sh .claude/scripts/ai-logger-original.sh

# 新しいロガーをテスト
.claude/scripts/ai-logger.sh
```

### ステップ2: 設定ファイルの更新
```json
// .claude/settings.json の該当部分を更新
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/activity-logger.sh"
          },
          {
            "type": "command",
            "command": ".claude/scripts/ai-logger.sh"  // ← ここを変更
          }
        ]
      }
    ]
  }
}
```

### ステップ3: ログの確認
```bash
# 新しいログファイルの確認
tail -f ~/.claude/ai-activity.jsonl

# 解析ツールの実行
.claude/scripts/analyze-ai-logs.py
```

## 使用例

### エラー解析
```bash
# エラーのみを表示
.claude/scripts/analyze-ai-logs.py --errors-only

# JSON形式で完全な分析
.claude/scripts/analyze-ai-logs.py --format json > analysis.json
```

### AIへの情報提供
```markdown
Claude, 以下のログ分析結果を確認して、エラーの原因を特定してください：

[analyze-ai-logs.py の出力をペースト]
```

## 互換性
- 既存の`activity.log`は引き続き生成される（後方互換性）
- 新旧両方のログが並行して動作可能
- 段階的な移行が可能

## 参考リンク
- [Vibe Logger GitHub](https://github.com/fladdict/vibe-logger)
- [VibeCoding概念](https://github.com/fladdict/vibe-logger/blob/main/docs/CONCEPT.md)
- [技術仕様](https://github.com/fladdict/vibe-logger/blob/main/docs/SPECIFICATION.md)
