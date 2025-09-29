# エージェントへのログ活用指示（案）

## Builderのデバッグモード改善案

### 現在の記述（builder/identity.md）
```markdown
2. **デバッグモード**
   - エラーや問題の調査に特化
   - ログの確認とエラーメッセージの分析
```

### 改善案
```markdown
2. **デバッグモード**
   - エラーや問題の調査に特化
   - **必須ログ確認手順**：
     1. 最近のエラーを確認: `python3 .claude/scripts/analyze-ai-logs.py --errors-only`
     2. 活動履歴を確認: `tail -50 ~/.claude/activity.log | grep ERROR`
     3. AI用ログ解析: `python3 .claude/scripts/analyze-ai-logs.py --format json > debug-report.json`
   - エラーパターンの分析と解決策の提案
   - 実装前に必ずログでエラーコンテキストを確認すること
```

## Plannerの引き継ぎ手順改善案

### 追加すべき内容
```markdown
#### 引き継ぎ時のログ確認
Builderから引き継ぐ際は、必ず以下を確認：
1. 直近の活動サマリー: `python3 .claude/scripts/analyze-ai-logs.py`
2. エラーがあった場合: `python3 .claude/scripts/analyze-ai-logs.py --errors-only`
3. 作業履歴の把握: `tail -30 ~/.claude/activity.log`
```

## handover.mdテンプレートへの追加案

```markdown
## 参考ログ情報
- 最後のエラー: [analyze-ai-logs.py --errors-only の出力をペースト]
- 主な作業内容: [analyze-ai-logs.py のサマリーセクション]
- 要注意事項: [エラーパターンやAI TODOsから抽出]
```

## エージェント切り替えコマンドの改善案

`/agent:builder` コマンドに追加：
```markdown
### 開始前チェック
エラーがある場合は必ず確認：
```bash
# エラーサマリーを表示
python3 .claude/scripts/analyze-ai-logs.py --errors-only

# 詳細が必要な場合
python3 .claude/scripts/analyze-ai-logs.py --format json
```
```

## 実装優先順位

1. **最優先**: Builder のデバッグモードにログ確認手順を追加
2. **高**: handover.mdテンプレートにログ情報セクション追加
3. **中**: エージェント切り替えコマンドにログ確認促進
4. **低**: Plannerの通常モードにもログ活用を追加

## 効果予測

- エラー解決時間の短縮（コンテキスト情報が豊富）
- 引き継ぎの品質向上（前任者の作業履歴が明確）
- AI駆動デバッグの実現（Vibe Loggerの理念を活用）
