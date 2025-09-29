# 重要：MEMOディレクトリの正しいパス

## ⚠️ 絶対的ルール
**MEMOディレクトリは以下の場所のみを使用すること**:
```
/home/ote/work3/claude-friends-templates-workspace_3/memo/
```

## ❌ 使用してはいけないパス
```
/home/ote/work3/claude-friends-templates-workspace_3/claude-friends-templates/memo/
```
このパスは**プロジェクト内**であり、誤りです。

## ✅ 正しいファイルパスの例
- タスクリスト: `/home/ote/work3/claude-friends-templates-workspace_3/memo/2025-09-29/01-tasklist-00.md`
- 実行結果: `/home/ote/work3/claude-friends-templates-workspace_3/memo/2025-09-29/01-task-result-00.md`

## 📝 作業前チェックリスト
1. pwdで現在地確認
2. memoディレクトリがプロジェクト外であることを確認
3. ファイル作成前にパスを二重チェック

## 🔧 統合履歴
- **2025-09-29**: プロジェクト内のmemoディレクトリからワークスペースmemoへ統合完了
  - プロジェクト内のmemoディレクトリは削除済み
  - 今後はワークスペースのmemoのみを使用

作成日: 2025-09-29
更新日: 2025-09-29
理由: パス混同による作業ミスの防止と統合管理