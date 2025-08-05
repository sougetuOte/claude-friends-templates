# Claude Friends v2.0.0 移行ガイド

🌐 **日本語** | **[English](MIGRATION_GUIDE.md)**

v1.xからv2.0.0への移行を支援するガイドです。

## 🎉 v2.0.0の主要な変更点

### Claude Friendsマルチエージェントシステムの導入
- **Plannerエージェント**: 戦略立案・設計書作成（Mermaid図付き）
- **Builderエージェント**: 実装・デバッグ・コードレビュー
- **スマートモード切り替え**: エージェントが文脈に応じて自動的に特殊モードに切り替え

### コマンドの大幅な簡素化
- **以前**: 7つ以上のコマンド
- **現在**: たった4つのコアコマンド
- **削減率**: 大幅なコマンド削減

## 🚨 破壊的変更

### 1. 削除されたコマンド

| 削除されたコマンド | 新しい方法 |
|-------------------|------------|
| `/project:plan` | `/agent:planner` を使用 |
| `/project:act` | `/agent:builder` を使用 |
| `/feature:plan` | Plannerの新機能設計モード（自動） |
| `/debug:start` | Builderのデバッグモード（自動） |
| `/review:check` | Builderのコードレビューモード |

### 2. 新しいエージェント構造
```
.claude/
├── agents/          # NEW!
│   └── active.md    # 現在アクティブなエージェント
├── planner/         # NEW!
│   ├── identity.md  # Plannerの役割定義
│   ├── notes.md     # 作業メモ
│   └── handover.md  # 引き継ぎ文書
├── builder/         # NEW!
│   ├── identity.md  # Builderの役割定義
│   ├── notes.md     # 実装メモ
│   └── handover.md  # 引き継ぎ文書
└── shared/          # NEW!
    ├── phase-todo.md    # Phase/ToDo管理
    └── constraints.md   # プロジェクト制約
```

### 3. ワークフローの変化
- **以前**: コマンドベースの開発
- **現在**: エージェントベースの開発
- **メリット**: より自然な対話形式、自動的な文脈理解

## 🔧 移行手順

### ステップ 1: バックアップ
```bash
# 現在の設定をバックアップ
cp -r .claude .claude_backup_v1
cp CLAUDE.md CLAUDE_backup_v1.md
```

### ステップ 2: 新しいエージェント構造の作成
```bash
# エージェントディレクトリの作成
mkdir -p .claude/agents
mkdir -p .claude/planner/archive
mkdir -p .claude/builder/archive
mkdir -p .claude/shared

# active.mdの初期化
echo "# Active Agent\n\n## Current Agent: none\n\nLast updated: $(date +%Y-%m-%d)" > .claude/agents/active.md
```

### ステップ 3: 最新版の適用
```bash
# 最新版を取得
git pull origin main

# または手動でv2.0.0ファイルをコピー

# 日本語環境で使用する場合
mv .clauderules .clauderules_en     # 英語版を保存
mv .clauderules_ja .clauderules     # 日本語版を使用
```

### ステップ 4: コマンドの移行

#### 日常のワークフロー移行
```bash
# 以前のワークフロー
/project:plan      # 計画立案
/project:act       # 実装実行
/debug:start       # デバッグ
/review:check      # レビュー

# 新しいワークフロー
/agent:planner     # 計画・設計（新機能モード自動切り替え）
/agent:builder     # 実装・デバッグ・レビュー（モード自動切り替え）
```

#### カスタムコマンドの更新
もしカスタムコマンドを作成していた場合：
1. `.claude/commands/` を確認
2. 削除されたコマンドへの参照を更新
3. 新しいエージェントベースのフローに適応

### ステップ 5: CLAUDE.mdの更新
```bash
# CLAUDE.mdの主要セクションを更新
# - カスタムコマンドセクション
# - Claude Friendsシステムの説明を追加
# - 削除されたコマンドの記述を削除
```

### ステップ 6: 検証
```bash
# エージェント構造の確認
ls -la .claude/agents/
ls -la .claude/planner/
ls -la .claude/builder/

# コマンドの動作確認
# Plannerモードをテスト
"Please switch to planner mode"

# Builderモードをテスト  
"Please switch to builder mode"
```

## 📋 移行チェックリスト

- [ ] バックアップを作成した
- [ ] エージェントディレクトリ構造を作成した
- [ ] CLAUDE.mdを更新した
- [ ] 削除されたコマンドへの参照を更新した
- [ ] `/agent:planner` が正常に動作する
- [ ] `/agent:builder` が正常に動作する
- [ ] 特殊モードの自動切り替えを確認した
- [ ] 引き継ぎ文書（handover.md）の作成を理解した

## 🆕 新機能の活用

### 1. スマートモード切り替え
```
Planner使用中：
「新しいユーザー認証機能を設計したい」
→ 自動的に新機能設計モードに切り替わり、Mermaid図を作成

Builder使用中：
エラーが発生
→ 自動的にデバッグモードに切り替わり、根本原因を分析
```

### 2. 引き継ぎシステム
```bash
# エージェント切り替え時
1. 現在のエージェントが handover.md を作成
2. 次のエージェントへの推奨事項を記載
3. スムーズな作業継続が可能
```

### 3. Phase/ToDo管理
```
# shared/phase-todo.md で一元管理
- 現在のPhase
- Phase内のToDo（優先順）
- 完了したPhase
- 次のPhase候補
```

## ❓ よくある質問

### Q: なぜコマンドが減ったのですか？
A: エージェントシステムが文脈を理解し、自動的に適切なモードに切り替わるため、個別のモードコマンドが不要になりました。

### Q: 以前の `/debug:start` の機能はどこへ？
A: Builderエージェントがエラーを検出すると自動的にデバッグモードに入ります。手動で起動したい場合は「デバッグモードで分析して」と伝えるだけです。

### Q: `/feature:plan` の詳細な設計書機能は？
A: Plannerエージェントに統合され、さらに強化されました。Mermaid図を自動的に含む、より視覚的な設計書を作成します。

### Q: 移行にどれくらい時間がかかりますか？
A: 通常のプロジェクトなら30分程度で完了します。カスタマイズが多い場合は1時間程度を見込んでください。

### Q: v1.xに戻すことはできますか？
A: バックアップから復元可能ですが、v2.0.0の利点（コスト削減、効率向上）を失うことになります。

## 🚀 移行後の新しいワークフロー例

```
朝の開始:
/agent:planner
「今日はユーザー管理機能を完成させたい」
→ Plannerが計画を立案、設計書を作成

実装開始:
/agent:builder  
「Plannerの設計に基づいて実装を開始」
→ Builderが実装、テスト、必要に応じてデバッグ

レビュー:
「実装したコードをレビューモードで確認して」
→ Builderが自動的にコードレビューモードに切り替え

日次振り返り:
/project:daily
→ どのエージェントからでも実行可能
```

## 📞 サポート

移行に関する質問や問題がある場合は、GitHubのIssueで報告してください。

---

**重要**: v2.0.0への移行により、開発体験が大幅に向上します。初期の学習曲線はありますが、すぐに新しいワークフローの効率性を実感できるでしょう。