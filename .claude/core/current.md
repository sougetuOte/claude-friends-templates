# Current Status - DEPRECATED
tags: #deprecated #migration #claude-friends

## ⚠️ このファイルは廃止されました

### Claude Friendsシステムへ移行しました

現在の状態管理は、以下のファイルで行われています：

- **Plannerの作業状態**: @.claude/planner/notes.md
- **Builderの作業状態**: @.claude/builder/notes.md
- **Phase/ToDo管理**: @.claude/shared/phase-todo.md
- **アクティブなエージェント**: @.claude/agents/active.md

### 移行方法

1. **現在の作業状態を確認**
   ```
   /agent:planner  # Plannerモードで計画を確認
   /agent:builder  # Builderモードで実装を確認
   ```

2. **従来の情報の参照先**
   - Git Status → 各エージェントのnotes.mdに記録
   - This Week's Work → shared/phase-todo.mdで管理
   - Ongoing Issues → 各エージェントのhandover.mdで引き継ぎ
   - Learnings → 各エージェントのnotes.mdに記録

### Quick Links (変更なし)
- Technical details → @.claude/context/tech.md
- Past history → @.claude/context/history.md
- Project overview → @.claude/core/overview.md

---
*このファイルは互換性のために残されていますが、新しい情報は更新されません。*
