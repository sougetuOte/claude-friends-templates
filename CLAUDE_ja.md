# [プロジェクト名]

## プロジェクト概要
[プロジェクトの簡潔な説明をここに記載]

## プロンプトキャッシュ最適化設定
- **CLAUDE_CACHE**: `./.ccache` - 90%コスト削減・85%レイテンシ短縮
- **cache_control**: 長期安定情報に適用済み
- **設定**: `.claude/settings.json`参照

## Claude Friendsシステム (NEW!)
**シーケンシャル・マルチエージェントシステム** - AI開発チームをシミュレート
- **Plannerエージェント**: 戦略立案・Phase/ToDo管理・ユーザーとの窓口・設計書作成
  - 特殊モード: 新機能設計モード（Mermaid図付き）
  - 口調: 冷静な女性口調（「〜ですね」「〜でしょう」「〜かしら」）
- **Builderエージェント**: 実装・テスト・デバッグ・技術的質問対応
  - 特殊モード: デバッグモード、コードレビューモード
  - 口調: ちょっとがさつな男性口調（「〜だぜ」「〜だな」「よし、やってみるか」）
- **スムーズな引き継ぎ**: エージェント間の引き継ぎシステム（モード情報含む）

### 基本的な開発フロー（3フェーズプロセス）

#### 1. **要件定義フェーズ** → `/agent:planner`
   - 要件確認、requirements.md作成
   - 成功基準の定義、リスク分析
   - 完了後: "Requirements → Design"への誘導

#### 2. **設計フェーズ** → `/agent:planner` 続行
   - アーキテクチャ設計、Mermaid図作成
   - コンポーネント/インターフェース設計
   - 完了後: "Design → Tasks"への誘導

#### 3. **タスク生成・実装フェーズ** 
   - **タスク生成** → `/agent:planner`
     - TDD適用タスクの生成
     - Phase分割（MVP → Advanced）
     - レビューポイントの設定
   - **実装** → `/agent:builder`
     - Red-Green-Refactorサイクル厳守
     - Phase終了時レビュー実施
     - 仕様問題の即時フィードバック

#### 4. **必要に応じて切り替え**
   - 仕様変更 → Plannerへ
   - 技術的課題 → Builderで解決
   - レビュー結果 → 適切なエージェントへ

### エージェント構造
- アクティブエージェント: @.claude/agents/active.md
- Plannerワークスペース: @.claude/planner/
- Builderワークスペース: @.claude/builder/
- 共有リソース: @.claude/shared/

**[→ 運用ガイド](.claude/claude-friends-guide_ja.md)**

## Memory Bank構造
### コア（常時参照）
- 現在の状況: @.claude/core/current.md (DEPRECATED - エージェントnotesを使用)
- 次のアクション: @.claude/core/next.md
- プロジェクト概要: @.claude/core/overview.md
- クイックテンプレート: @.claude/core/templates.md

### コンテキスト（必要時参照）
- 技術詳細: @.claude/context/tech.md
- 履歴・決定事項: @.claude/context/history.md
- 技術負債: @.claude/context/debt.md

### エージェントワークスペース（Claude Friends）
- Plannerノート: @.claude/planner/notes.md
- Builderノート: @.claude/builder/notes.md
- Phase/ToDoトラッキング: @.claude/shared/phase-todo.md
- プロジェクト制約: @.claude/shared/constraints.md

### その他
- デバッグ情報: @.claude/debug/latest.md
- カスタムコマンド: @.claude/commands/
- セキュリティスクリプト: @.claude/scripts/
- Hooks設定: @.claude/hooks.yaml
- アーカイブ: @.claude/archive/

## カスタムコマンド

### コアコマンド（たった4つ！）
| コマンド | 用途 | 詳細 |
|---------|------|------|
| `/agent:planner` | 戦略計画＋設計 | Mermaid図付きで仕様書作成 |
| `/agent:builder` | 実装＋デバッグ＋レビュー | すべてのコーディング作業 |
| `/project:focus` | 現在のタスクに集中 | どのエージェントでも使用可 |
| `/project:daily` | 日次振り返り（3分） | どのエージェントでも使用可 |

### 特殊モード（エージェントに統合済み）
以下のモードはエージェントシステムに統合されました：
- **新機能設計** → Plannerの特殊モードを使用
- **デバッグモード** → Builderの特殊モードを使用  
- **コードレビュー** → Builderの特殊モードを使用

アクティブなエージェントに要望を説明するだけで、適切なモードに切り替わります。

### タグ検索
- タグ形式: `#tag_name` でMemory Bank内検索
- 主要タグ: #urgent #bug #feature #completed

## Hooks システム

### セキュリティ・品質向上・活動追跡の自動化
- **セキュリティ**: 危険コマンド（`rm -rf /`, `chmod 777`等）の自動ブロック
- **自動フォーマット**: ファイル編集後のコード整形（Python/JS/TS/Rust/Go/JSON対応）
- **活動ログ**: 開発活動の自動記録・メトリクス収集
- **AIログ**: Vibe Logger概念採用・構造化JSON形式でAI分析最適化
- **セッション管理**: 作業終了時の自動サマリー・Git状況記録

### AI-Friendly Logger (NEW)
- **構造化ログ**: AI分析に最適化されたJSON形式（@~/.claude/ai-activity.jsonl）
- **豊富なコンテキスト**: プロジェクト・環境・ファイル情報を自動収集
- **AIメタデータ**: デバッグヒント・優先度・推奨アクション付与
- **解析ツール**: `.claude/scripts/analyze-ai-logs.py`でパターン分析・洞察生成
- **詳細**: @.claude/ai-logger-README_ja.md

### Hooks確認・テスト
```bash
# 全hooks機能テスト
.claude/scripts/test-hooks.sh

# セキュリティ機能のみテスト
.claude/scripts/test-security.sh

# 活動ログ確認
tail -f ~/.claude/activity.log
```

詳細設定: @.claude/hooks-README_ja.md | @.claude/security-README_ja.md

## 開発規約（要点）

### パッケージ管理
- **統一原則**: プロジェクトごとに1つのツール（npm/yarn/pnpm, pip/poetry/uv等）
- **基本コマンド**: `[tool] add/remove/run` 形式を使用
- **禁止事項**: 混在使用、`@latest`構文、グローバルインストール

### コード品質
- **型注釈**: 全関数・変数に必須
- **テスト**: TDD（テスト駆動開発）を厳格に遵守
- **フォーマット**: `[tool] run format/lint/typecheck` で品質チェック

### TDD開発手法（t-wada流）- 必須要件
- 🔴 **Red**: 失敗するテストを書く（実装より先にテストを書く）
- 🟢 **Green**: テストを通す最小限の実装
- 🔵 **Refactor**: リファクタリング（テストが通る状態を維持）

#### 重要なTDD関連ドキュメント
- **TDD厳密適用ガイド**: @.claude/shared/templates/tasks/tdd-strict-guide.md
- **Phaseレビューテンプレート**: @.claude/shared/templates/tasks/phase-review-template.md
- **仕様フィードバックプロセス**: @.claude/shared/templates/tasks/specification-feedback-process.md

#### TDD実践原則（必須）
- **小さなステップ**: 一度に1つの機能のみ実装
- **仮実装**: テストを通すためにベタ書きでもOK（例：`return 42`）
- **三角測量**: 2つ目、3つ目のテストケースで一般化する
- **即座にコミット**: 各フェーズ完了後すぐにコミット

#### TDDコミットルール（必須）
- 🔴 テストを書いたら: `test: add failing test for [feature]`
- 🟢 テストを通したら: `feat: implement [feature] to pass test`
- 🔵 リファクタリングしたら: `refactor: [description]`

詳細なTDDルール: @.claude/shared/constraints.md

### Git規約
- **コミット形式**: `[prefix]: [変更内容]` （feat/fix/docs/test等）
- **品質ゲート**: コミット前に `[tool] run check` 実行必須
- **PR**: セルフレビュー→レビュアー指定→マージ

詳細規約: @docs/development-rules.md

## 開発ガイドライン
- **開発全般**: @.claude/guidelines/development.md
- **Gitワークフロー**: @.claude/guidelines/git-workflow.md
- **テスト・品質**: @.claude/guidelines/testing-quality.md

## 実行コマンド一覧
```bash
# 基本開発フロー
[tool] install          # 依存関係インストール
[tool] run dev         # 開発サーバー起動
[tool] run test        # テスト実行
[tool] run check       # 総合チェック

# 詳細は @.claude/guidelines/development.md 参照
```

## ADR・技術負債システム

### ADR（Architecture Decision Record）
- **テンプレート**: @docs/adr/template.md
- **運用**: 技術選択・アーキテクチャ決定時に記録
- **連携**: 負債ログ・履歴管理と統合

### 技術負債トラッキング
- **負債ログ**: @.claude/context/debt.md
- **優先度管理**: 高🔥 / 中⚠️ / 低📝
- **運用**: 新機能開発時の事前予測、スプリント終了時の整理

## プロジェクトデータ
- 設定: `config/settings.json`
- データ: `data/`
- 要求仕様: @docs/requirements.md

## Memory Bank使用方針
- **通常時**: coreファイルのみ参照でコンテキスト最小化
- **詳細必要時**: contextファイルを明示的に指定
- **定期整理**: 古い情報をarchiveに移動

## プロジェクト固有の学習
`.clauderules`ファイルに自動記録されます。
日本語版は`.clauderules_ja`を使用できます。

## 関連ドキュメント
- 開発規約詳細: @docs/development-rules.md
- 開発ガイドライン: @.claude/guidelines/development.md
- Hooksシステム: @.claude/hooks-README_ja.md
- セキュリティ設定: @.claude/security-README_ja.md
- AIロガーシステム: @.claude/ai-logger-README_ja.md
- 要求仕様書: @docs/requirements.md
- ADRテンプレート: @docs/adr/template.md
- 移行ガイド: @memo/migration-guide.md
- 導入手順書: @memo/zero-to-memory-bank.md
- タスク生成ガイド: @.claude/shared/templates/tasks/task-generation-intro.md
- TDD厳密適用ガイド: @.claude/shared/templates/tasks/tdd-strict-guide.md
- Phaseレビューテンプレート: @.claude/shared/templates/tasks/phase-review-template.md
- 仕様フィードバックプロセス: @.claude/shared/templates/tasks/specification-feedback-process.md