# Notes Management System - 使用ガイド

## 📋 概要

このシステムは、`.claude/builder/notes.md`と`.claude/planner/notes.md`ファイルの肥大化を防ぎ、効率的に管理するための自動化ツールです。

### 主な機能
1. **🔄 自動ローテーション** - 500行を超えたら自動的にアーカイブ
2. **📊 要約生成** - ローテーション時に重要事項を自動抽出
3. **📚 インデックス管理** - 全ファイルの目次を自動生成

## 🆕 自動実行機能

### エージェント切り替え時の自動ローテーション
`/agent:` コマンド使用時に、notes.mdが450行を超えていると自動的にローテーションが実行されます。

- **閾値**: 450行（自動実行のトリガー）
- **実行タイミング**: `/agent:planner` または `/agent:builder` コマンド実行時
- **設定ファイル**: `.claude/settings.json` の UserPromptSubmit フック
- **実行スクリプト**: `.claude/scripts/notes-check-hook.sh`

この機能により、手動でのメンテナンスを忘れても自動的にnotes.mdが管理されます。

## 🚀 クイックスタート

### 基本的な使用方法

```bash
# 全機能を実行（推奨）
bash .claude/scripts/notes-maintenance.sh

# 状態確認のみ
bash .claude/scripts/notes-maintenance.sh check

# 個別実行
bash .claude/scripts/notes-maintenance.sh rotate  # ローテーションのみ
bash .claude/scripts/notes-maintenance.sh index   # インデックス更新のみ
```

## 🔧 設定

### 設定ファイル: `.claude/scripts/rotation-config.sh`

```bash
# ローテーション閾値（デフォルト: 500行）
export ROTATION_MAX_LINES=500

# アーカイブ保持日数（デフォルト: 90日）
export ROTATION_ARCHIVE_DAYS=90

# 要約抽出パターン（カスタマイズ可能）
export SUMMARY_PATTERNS=(
    "^##"         # 見出し
    "決定:"       # 決定事項
    "重要:"       # 重要事項
    # 追加可能...
)
```

## 📁 ファイル構造

```
.claude/
├── scripts/
│   ├── notes-maintenance.sh    # メインスクリプト
│   ├── rotate-notes.sh         # ローテーション処理
│   ├── update-index.sh         # インデックス生成
│   ├── rotation-config.sh      # 設定ファイル
│   └── tests/                  # テストスイート
│       ├── test-notes-rotation.sh
│       └── test-index-generation.sh
├── builder/
│   ├── notes.md                # 現在の作業メモ
│   ├── notes-summary.md        # 最新の要約
│   ├── index.md               # 自動生成される目次
│   └── archive/
│       └── notes-YYYY-MM-DD-HHMMSS.md
└── planner/
    └── (同様の構造)
```

## 🎯 動作の詳細

### ローテーション処理
1. `notes.md`の行数をチェック
2. 500行を超えている場合：
   - 現在のファイルを`archive/notes-[timestamp].md`として保存
   - 要約を`notes-summary.md`に生成
   - 新しい`notes.md`をテンプレートから作成

### 要約生成
- **抽出される情報**:
  - セクション構造（##, ###）
  - 決定事項（決定:, 重要:, 変更:）
  - タスク状況（完了/未完了の集計）
  - 記録された問題（問題:, エラー:, バグ:）

### インデックス生成
- **含まれる情報**:
  - 統計情報（ファイル数、最終更新、行数）
  - 現在のファイル一覧とプレビュー
  - アーカイブファイル一覧（最新5件）
  - 使用方法の説明

## 🔄 自動化設定

### 週次実行（cron）
```bash
# crontabに追加（毎週月曜日 AM 9:00）
0 9 * * 1 cd /path/to/project && bash .claude/scripts/notes-maintenance.sh
```

### Git Hook統合
```bash
# .git/hooks/pre-commit に追加
#!/bin/bash
# notes.mdが大きくなりすぎていないかチェック
bash .claude/scripts/notes-maintenance.sh check
```

### CI/CD統合
```yaml
# .github/workflows/notes-maintenance.yml
name: Notes Maintenance
on:
  schedule:
    - cron: '0 0 * * 0'  # 毎週日曜日
  workflow_dispatch:

jobs:
  maintain:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run maintenance
        run: bash .claude/scripts/notes-maintenance.sh
      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add .claude/
          git commit -m "chore: auto notes maintenance" || true
          git push
```

## 🧪 テスト

```bash
# 全テストを実行
bash .claude/scripts/tests/test-notes-rotation.sh
bash .claude/scripts/tests/test-index-generation.sh

# 統合テスト
bash .claude/scripts/notes-maintenance.sh check
```

## 🌟 ベストプラクティス

### 推奨される運用
1. **週次実行**: 定期的なメンテナンスを習慣化
2. **手動チェック**: 重要な作業の前後で`check`コマンドを実行
3. **要約確認**: ローテーション後は`notes-summary.md`を確認
4. **インデックス活用**: `index.md`で全体像を把握

### 注意事項
- ローテーション後、元のファイルはアーカイブに保存されます
- 要約は自動生成のため、重要な情報は手動で確認してください
- アーカイブは90日後に自動削除可能（設定による）

## 🆘 トラブルシューティング

### よくある問題

**Q: ローテーションが実行されない**
- A: ファイルが500行未満の可能性があります。`check`コマンドで確認してください

**Q: 要約が空になる**
- A: 抽出パターンに一致する内容がない可能性があります。`rotation-config.sh`でパターンを調整してください

**Q: index.mdが更新されない**
- A: 手動で`bash .claude/scripts/update-index.sh`を実行してください

## 📈 今後の改善案

- [ ] AI による要約の質向上
- [ ] カテゴリー別の自動分類
- [ ] 検索機能の追加
- [ ] Web UIの提供
- [ ] 複数プロジェクト対応

## 📝 ライセンス

MITライセンス

---

*このシステムは、claude-friends-templatesプロジェクトの一部として開発されました。*
*問題や提案がある場合は、GitHubのIssueでお知らせください。*
