# AI Logger V2 統合チェックリスト

## 現状の問題点

### 1. 設定ファイル未更新
- [ ] `.claude/settings.json` - 87行目を `ai-logger-v2.sh` に変更

### 2. ドキュメントの不整合
- [ ] `.claude/agent-log-integration.md` - 全ての `analyze-ai-logs.py` を `analyze-ai-logs-v2.py` に変更
- [ ] `CLAUDE.md` - AI Logger V2の説明を追加、vibe-logger-integration.mdへのリンク追加

### 3. 旧ファイルとの共存
- 現在: `ai-logger.sh` と `ai-logger-v2.sh` が並存
- 現在: `analyze-ai-logs.py` と `analyze-ai-logs-v2.py` が並存
- 現在: `~/.claude/ai-activity.jsonl` と `~/.claude/ai-activity-v2.jsonl` が並存

## 推奨される移行手順

### Phase 1: テスト段階（現在）
- [x] AI Logger V2の作成とテスト
- [x] 解析ツールV2の作成とテスト
- [x] 統合ガイドの作成

### Phase 2: 部分統合
- [ ] settings.jsonを更新してV2を有効化
- [ ] ドキュメントをV2対応に更新
- [ ] 1週間程度の並行運用

### Phase 3: 完全移行
- [ ] 旧ログファイルのアーカイブ
- [ ] 旧スクリプトの削除または非推奨化
- [ ] 全ドキュメントの最終確認

## 即座に実行可能な修正

### settings.json の更新
```json
// 87行目を変更
"command": ".claude/scripts/ai-logger-v2.sh"
```

### agent-log-integration.md の更新
```bash
# 一括置換
sed -i 's/analyze-ai-logs.py/analyze-ai-logs-v2.py/g' .claude/agent-log-integration.md
```

### CLAUDE.md への追記
```markdown
## AI Logger System (V2)
- **Vibe Logger準拠**: 構造化されたJSONL形式
- **統合ガイド**: @.claude/vibe-logger-integration.md
- **解析ツール**: `.claude/scripts/analyze-ai-logs-v2.py`
```

## 互換性の考慮事項

1. **ログファイルの違い**
   - V1: Pretty-printed JSON (複数行)
   - V2: JSONL (1行1JSON)
   - 形式が異なるため、混在不可

2. **フィールドの違い**
   - V2は`level`フィールドが必須
   - V2は`operation`の命名規則が異なる

3. **移行時の注意**
   - 旧ログは別途保存推奨
   - 新旧の解析ツールは混在使用不可
