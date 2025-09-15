# Claude Code Hooks System 調査結果

**作成日**: 2025年9月15日
**文書種別**: 技術調査メモ

## 1. Hooks System 概要

Claude Code Hooksは、Claude Codeのライフサイクルの各ポイントで実行されるユーザー定義のシェルコマンドです。
LLMの選択に依存せず、確実に特定のアクションが実行されることを保証します。

## 2. 主要なHookイベント

### 2.1 UserPromptSubmit
- **実行タイミング**: ユーザーがプロンプトを送信した時、Claudeが処理する前
- **用途**:
  - プロンプトの検証と拡張
  - コンテキストの追加
  - セキュリティフィルタリング
  - ユーザーインタラクションのログ記録

### 2.2 PreToolUse
- **実行タイミング**: ツール呼び出しの前（ブロック可能）
- **用途**:
  - 危険なコマンドの実行前検証
  - 機密ファイル・操作へのアクセスブロック
  - コマンドのログ記録
  - セキュリティポリシーの実施

### 2.3 PostToolUse
- **実行タイミング**: ツール呼び出し完了後
- **用途**:
  - ファイル編集後の自動フォーマット
  - コード変更後のテスト実行
  - クリーンアップ操作
  - 完了通知

### 2.4 その他のHooks
- **Notification**: 通知送信時
- **Stop**: Claude Codeの応答完了時
- **SubagentStop**: サブエージェントタスク完了時
- **SessionStart**: セッション開始時
- **SessionEnd**: セッション終了時

## 3. 設定構造

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "スクリプトパス"
          }
        ]
      }
    ],
    "PostToolUse": [...],
    "UserPromptSubmit": [...]
  }
}
```

## 4. Hook戻り値（JSON形式）

Hookスクリプトは以下のフィールドを含むJSONを標準出力に返すことができます：

```json
{
  "continue": true,          // 処理を続行するか
  "stopReason": "理由",      // continueがfalseの場合の理由
  "suppressOutput": false,   // トランスクリプトモードで出力を隠すか
  "systemMessage": "警告"    // ユーザーに表示する警告メッセージ
}
```

## 5. 環境変数

Hookスクリプトは以下の環境変数にアクセスできます：

- `CLAUDE_TOOL_NAME`: 使用されたツール名
- `CLAUDE_FILE_PATHS`: 操作されたファイルパス
- `CLAUDE_COMMAND`: 実行されたコマンド
- `CLAUDE_EXIT_CODE`: コマンドの終了コード
- `CLAUDE_PROJECT_DIR`: プロジェクトディレクトリ
- `CLAUDE_PROMPT`: ユーザーのプロンプト

## 6. 実装上の注意点

### 6.1 パフォーマンス
- Hookの実行は2秒以内に完了すべき
- 重い処理は非同期で実行

### 6.2 エラーハンドリング
- Hookの失敗がClaude Codeの動作を止めないように設計
- 適切なフォールバック処理の実装

### 6.3 セキュリティ
- 入力のサニタイゼーション
- 権限の適切な管理
- ログの安全な記録

## 7. プロジェクトでの活用方針

### 7.1 エージェント切り替え自動化
- UserPromptSubmitで`/agent:planner`や`/agent:builder`を検出
- 自動的にエージェント切り替えとhandover生成

### 7.2 Memory Bank管理
- PostToolUseでnotes.mdのサイズチェック
- 450行超過時の自動ローテーション

### 7.3 品質チェック
- PreToolUseでTDD遵守確認
- PostToolUseで設計同期チェック

### 7.4 セキュリティ強化
- PreToolUseで危険なコマンドのブロック
- 入力検証と権限チェック

## 8. 実装優先度

1. **Phase 1（即座に実装）**
   - 基本的なHook機能の実装
   - エージェント切り替え自動化
   - Memory Bank自動管理

2. **Phase 2（中期実装）**
   - Subagent統合
   - 並列処理対応
   - キャッシュ最適化

3. **Phase 3（長期実装）**
   - 機械学習による最適化
   - 高度な分析機能
   - エンタープライズ機能

## 9. 参考リンク

- [Claude Code Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks-guide)
- [Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery)