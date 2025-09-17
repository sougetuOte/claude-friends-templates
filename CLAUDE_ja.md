# Claude Friends Templates

## プロジェクト概要
このプロジェクトは、claude-kiro-templateのベストプラクティス（特にテスト駆動開発（TDD）と構造化された計画立案）を取り入れて、claude-friends-templatesプロジェクトを強化することに焦点を当てています。

## プロンプトキャッシュ最適化設定
- **CLAUDE_CACHE**: `./.ccache` - 同一プロンプトの再実行時にコスト削減・レスポンス時間短縮
- **cache_control**: 長期安定情報に適用済み
- **設定**: `.claude/settings.json`参照

## Claude Friendsシステム (NEW!)
**シーケンシャル・マルチエージェントシステム** - AI開発チームをシミュレート
- **Plannerエージェント**: 戦略立案・Phase/ToDo管理・ユーザーとの窓口・設計書作成
  - 特殊モード: 新機能設計モード
  - 強化機能: 設計同期・ドリフト検出・ADR管理
  - 口調: 冷静な女性口調（「〜ですね」「〜でしょう」「〜かしら」）
- **Builderエージェント**: 実装・テスト・デバッグ・技術的質問対応
  - 特殊モード: デバッグモード、コードレビューモード
  - 強化機能: 厳格なTDD実践・エラーパターン学習・テスト自動生成
  - 口調: ちょっとがさつな男性口調（「〜だぜ」「〜だな」「よし、やってみるか」）
- **スムーズな引き継ぎ**: エージェント間の引き継ぎシステム（モード情報含む）
  - コンテキスト圧縮による効率的な引き継ぎ
  - 並列実行可能なタスクの分析

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
  - 設計同期: @.claude/shared/design-sync.md (NEW!)
  - 設計トラッカー: @.claude/shared/design-tracker/ (NEW!)
  - テンプレート: @.claude/shared/templates/ (NEW!)
  - チェックリスト: @.claude/shared/checklists/ (NEW!)
  - エラーパターン: @.claude/shared/error-patterns/ (NEW!)
  - テストフレームワーク: @.claude/shared/test-framework/ (NEW!)

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
- Plannerノート: @.claude/planner/notes.md（500行で自動ローテーション）
- Builderノート: @.claude/builder/notes.md（500行で自動ローテーション）
- **エージェント切り替え時の自動実行**: `/agent:`コマンド使用時に450行超過で自動ローテーション
- ノートインデックス: @.claude/planner/index.md, @.claude/builder/index.md（自動生成）
- ノート要約: ローテーション時に自動生成
- Phase/ToDoトラッキング: @.claude/shared/phase-todo.md
- プロジェクト制約: @.claude/shared/constraints.md
- **ノートメンテナンス**: 週次で `bash .claude/scripts/notes-maintenance.sh` を実行（フックによる自動実行も可能）

### その他
- デバッグ情報: @.claude/debug/latest.md
- カスタムコマンド: @.claude/commands/
- セキュリティスクリプト: @.claude/scripts/
- Hooks設定: @.claude/hooks.yaml
- アーカイブ: @.claude/archive/

## カスタムコマンド

### コアコマンド（スタートはここから！）
| コマンド | 用途 | 詳細 |
|---------|------|------|
| `/agent:first` | **🌟 スタートはここから** - 開発ガイド | 適切な方法論を強制、適切なエージェントに誘導 |
| `/agent:planner` | 戦略計画＋設計 | Mermaid図付きで仕様書作成 |
| `/agent:builder` | 実装＋デバッグ＋レビュー | すべてのコーディング作業 |
| `/project:focus` | 現在のタスクに集中 | どのエージェントでも使用可 |
| `/project:daily` | 日次振り返り（3分） | どのエージェントでも使用可 |

### 強化コマンド (NEW!)
| コマンド | 用途 | 詳細 |
|---------|------|------|
| `/project:diagnose` | プロジェクト状況診断 | 包括的なプロジェクト状態分析 |
| `/project:quality-check` | 品質ゲートチェック | ステージ完了要件の確認 |
| `/project:next-step` | 次ステップガイダンス | 具体的な次のアクションを取得 |
| `/tdd:start` | TDDサイクル開始 | Red-Green-Refactorサイクル開始 |
| `/tdd:status` | TDDステータス確認 | 現在のタスクステータス確認（🔴🟢✅⚠️） |
| `/adr:create` | 新ADR作成 | アーキテクチャ決定を文書化 |
| `/adr:list` | ADR一覧 | ステータス別ADR表示 |

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

### AI-Friendly Logger V2 (Vibe Logger準拠)
- **構造化ログ**: AI分析に最適化されたJSONL形式（@~/.claude/ai-activity.jsonl）
- **豊富なコンテキスト**: プロジェクト・環境・ファイル情報を自動収集
- **AIメタデータ**: デバッグヒント・優先度・推奨アクション付与
- **解析ツール**: `.claude/scripts/analyze-ai-logs.py`でパターン分析・洞察生成
- **Vibe Logger概念**: @fladdict のVibeCoding哲学に基づく
- **詳細**: @.claude/ai-logger-README.md | @.claude/vibe-logger-integration.md

### エラーパターンライブラリ (NEW!)
- **AI駆動認識**: 過去のデバッグセッションから学習
- **パターンマッチング**: 類似エラーの即座の識別
- **根本原因分析**: AIによる原因と解決策の提案
- **検索可能履歴**: 過去の解決策への迅速なアクセス
- **自動記録**: デバッグモード時にエラーパターンを自動収集

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
- **テスト構造・組織化**: @.claude/shared/templates/test-structure-guide.md（NEW!）
- **TDDサイクル実践**: @.claude/builder/tdd-cycle.md
- **TDD設定システム**: @.claude/shared/tdd-settings.md
- **Phaseレビューテンプレート**: @.claude/shared/templates/tasks/phase-review-template.md
- **仕様フィードバックプロセス**: @.claude/shared/templates/tasks/specification-feedback-process.md

#### タスクステータス管理 (NEW!)
- 🔴 **Not Implemented**: 未実装（TDD Red Phase）
- 🟢 **Minimally Implemented**: 最小実装完了（TDD Green Phase）
- ✅ **Refactored**: リファクタリング完了
- ⚠️ **Blocked**: ブロック中（3回失敗後）

詳細: @.claude/shared/task-status.md

#### TDD実践原則（必須）
- **小さなステップ**: 一度に1つの機能のみ実装
- **仮実装**: テストを通すためにベタ書きでもOK（例：`return 42`）
- **三角測量**: 2つ目、3つ目のテストケースで一般化する
- **即座にコミット**: 各フェーズ完了後すぐにコミット

#### TDDコミットルール（必須）
- 🔴 テストを書いたら: `test: add failing test for [feature]`
- 🟢 テストを通したら: `feat: implement [feature] to pass test`
- 🔵 リファクタリングしたら: `refactor: [description]`

#### TDDサポートツール (NEW!)
- `/tdd:start` - TDDサイクル開始コマンド
- `/tdd:status` - 現在のTDDステータス確認
- **TDD強制設定**: settings.jsonで厳格度を調整可能（strict/recommended/off）
- **スキップ理由記録**: テスト未作成時の理由を自動記録
- 詳細なTDDガイド: @.claude/builder/tdd-cycle.md
- チェックリスト: @.claude/shared/checklists/
- TDD設定ガイド: @.claude/shared/tdd-settings.md

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

## テストフレームワーク統合 (NEW!)

### 📝 注意: Batsは必須ではありません
- **一般利用者**: Batsインストール不要。すべての機能は正常動作
- **開発者**: Batsインストール推奨（テスト実行用）
- **詳細**: [テストシステムガイド](.claude/tests/README.md)参照

### テストテンプレート
- **事前定義テンプレート**: 一般的なテストシナリオ用
- **モック自動生成**: 依存関係の自動モック作成
- **カバレッジ追跡**: リアルタイムのカバレッジ監視
- **品質ゲート**: 80%以上のカバレッジを強制

### テストファースト開発支援
- **テスト生成ガイド**: 失敗するテストの作成を支援
- **アサーション提案**: 適切なアサーションの推奨
- **テストケース分析**: エッジケースの検出

## エージェント協調最適化 (NEW!)

### スマートハンドオフ
- **コンテキスト圧縮**: 効率的なエージェント切り替え
- **重要情報の抽出**: 引き継ぎに必要な情報の自動選別
- **モード情報の伝達**: 特殊モードの状態を保持

### 並列実行分析
- **タスク依存関係**: 並列実行可能なタスクの特定
- **リソース競合検出**: 同時実行時の問題を事前に検出
- **最適実行順序**: 効率的なタスク順序の提案

### パフォーマンス監視
- **エージェント効率**: 各エージェントの処理時間追跡
- **ボトルネック検出**: 非効率な処理の特定
- **改善提案**: 最適化のための具体的な提案

## プロセス最適化システム

### リファクタリングスケジューラー
- **自動分析**: リファクタリングが必要な箇所を自動検出
- **優先度算出**: 影響度・頻度・複雑度から優先順位を計算
- **定期レポート**: 日次・週次でリファクタリング提案を生成
- **実行**: `python .claude/scripts/refactoring-analyzer.py`
- **設定**: @.claude/refactoring-config.json
- **詳細**: @.claude/shared/refactoring-scheduler.md

### 設計変更トラッキング
- **変更履歴管理**: すべての設計変更を体系的に記録
- **影響分析**: 設計変更がコードに与える影響を自動分析
- **ドリフト検出**: 設計と実装の乖離を定期的にチェック
- **実行**: `python .claude/scripts/design-drift-detector.py`
- **変更ログ**: @.claude/shared/design-tracker/change-log/
- **詳細**: @.claude/shared/design-tracker/design-tracker.md

### 品質ゲート
- **テストカバレッジ**: 80%以上を自動チェック
- **コード複雑度**: 循環的複雑度10以下を強制
- **セキュリティスキャン**: ハードコードされた秘密情報を検出
- **コード重複**: 5%以下を目標
- **実行**: `python .claude/scripts/quality-check.py`
- **設定**: @.claude/quality-config.json
- **詳細**: @.claude/shared/quality-gates.md

### 品質レベル
- 🟢 **Green**: すべての品質基準をクリア
- 🟡 **Yellow**: 軽微な問題あり（警告）
- 🔴 **Red**: 重大な問題あり（マージ不可）

### Pre-commit統合
```bash
# 自動品質チェック
.claude/scripts/quality-pre-commit.sh
```

## ドキュメント構造 (NEW!)
プロジェクトのすべてのドキュメントは `docs/` ディレクトリ以下に整理されています：

```
docs/
├── requirements/     # 要件定義（機能要件・非機能要件）
├── design/          # 設計書（アーキテクチャ・API・DB設計）
├── tasks/           # タスク管理（フェーズ別・優先順位管理）
├── adr/             # アーキテクチャ決定記録
├── specs/           # 実装仕様書（コンポーネント別）
├── test-specs/      # テスト仕様
└── operations/      # 運用ドキュメント
```

### エージェントの制約
- **Planner**: すべてのドキュメントを `docs/` 配下に作成
- **Builder**: 実装前に必ず `docs/tasks/` → `docs/specs/` の順で確認

## プロジェクトデータ
- 設定: `.claude/settings.json`
- 要件: @docs/requirements/index.md

## Memory Bank使用方針
- **通常時**: coreファイルのみ参照でコンテキスト最小化
- **詳細必要時**: contextファイルを明示的に指定
- **定期整理**: 古い情報をarchiveに移動

## プロジェクト固有の学習
`.clauderules`ファイルに自動記録されます。
日本語版は`.clauderules_ja`を使用できます。

## コードスタイル
- **AI-Friendlyコメント**: `.claude/shared/ai-friendly-comments.md`のガイドラインに従う
- **コメント哲学**: 「何を」ではなく「なぜ」を説明
- **必須コメント**: 複雑なアルゴリズム、ビジネスルール、パフォーマンス最適化
- **避けるべきコメント**: 自明なコメント、コード翻訳、古い仕様

## 関連ドキュメント
- 開発規約詳細: @docs/development-rules.md
- 開発ガイドライン: @.claude/guidelines/development.md
- Hooksシステム: @.claude/hooks-README.md
- セキュリティ設定: @.claude/security-README.md
- AIロガーシステム: @.claude/ai-logger-README.md | @.claude/vibe-logger-integration.md
- 要求仕様書: @docs/requirements.md
- ADRテンプレート: @docs/adr/template.md
- 段階的導入ガイド: @memo/gradual-adoption-guide.md
- 導入手順書: @memo/zero-to-memory-bank.md
- TDDガイド: @.claude/builder/tdd-cycle.md
- 設計同期ガイド: @.claude/shared/design-sync.md
- 品質ゲート: @.claude/shared/quality-gates.md
- リファクタリングスケジューラー: @.claude/shared/refactoring-scheduler.md
- ベストプラクティス: @BEST_PRACTICES.md
- アーキテクチャ: @ARCHITECTURE.md