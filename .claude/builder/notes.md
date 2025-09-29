# Builder Notes

## 現在の実装タスク
- [ ] Phase 2の残りファイル作成を継続
- [ ] shared/constraints.md の作成
- [ ] shared/phase-todo.md の作成

## 技術的メモ

### 実装済み
- ディレクトリ構造の作成（Phase 1完了）
- Planner用ファイル（identity, notes, handover）
- Builder用ファイル（identity, このnotes.md）

### 使用技術・ツール
- ファイル操作: Bash (mkdir)、Write tool
- テンプレート形式: Markdown with YAML frontmatter
- cache_control適用: identity.mdファイルに設定

### 実装上の工夫
- テンプレートは具体的かつ実用的に
- 日本語で分かりやすく記述
- 既存システムとの整合性を保つ

## 課題・TODO

### 技術的課題
- [ ] エージェント切り替えコマンドの実装方法検討
- [ ] active.md更新のタイミングと方法
- [ ] handover.md作成の強制メカニズム

### 改善アイデア
- アーカイブ処理の自動化（cron or hooks?）
- エージェント状態の可視化
- 切り替え履歴の記録

## コード片・参考実装

```bash
# エージェント切り替えの基本ロジック（案）
current_agent=$(cat .claude/agents/active.md | grep "Current Agent:" | cut -d' ' -f3)
if [ "$current_agent" != "none" ]; then
    echo "Please create handover.md first"
fi
```

## 参照リンク・ドキュメント
- Phase-Todo.md: 全体の実装計画
- pre-implementation-checklist.md: 事前準備内容
- command-templates.md: コマンド実装の詳細

---
*実装中の気づきや技術的な詳細はここに記録*
