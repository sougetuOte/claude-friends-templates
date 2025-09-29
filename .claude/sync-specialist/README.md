# Sync Specialist - Pattern 2-1 Enhanced Hybrid

## 概要
Sync Specialistは、PlannerとBuilderエージェント間の切り替えを自動的に検知し、handoverドキュメントを生成するサブエージェントです。Pattern-2-1 Enhanced Hybridの実装として、既存システムへの影響を最小限に抑えながら、エージェント間の円滑な引き継ぎを実現します。

## 機能

### 1. 自動検知
- `/agent:planner`や`/agent:builder`コマンドを検知
- UserPromptSubmitフックを使用した非侵襲的な実装
- バックグラウンドでの非同期処理

### 2. Handover自動生成
- エージェント切り替え時に自動的にhandoverドキュメントを生成
- 最近の活動、Phase/ToDo状況、Git状態などを含む
- エージェント固有の推奨事項を提供

### 3. 最小限の影響
- 既存のエージェントシステムに変更を加えない
- 非同期処理によりユーザーの作業を妨げない
- フィーチャーフラグによる有効/無効の切り替え可能

## ファイル構成

```
.claude/sync-specialist/
├── sync-trigger.sh      # UserPromptSubmitフックから呼ばれるトリガー
├── sync-monitor.sh      # エージェント切り替えを監視
├── handover-gen.sh      # handoverドキュメントを生成
├── config.json          # 設定ファイル
└── README.md           # このファイル
```

## 動作フロー

1. ユーザーが`/agent:planner`または`/agent:builder`を実行
2. UserPromptSubmitフックが`sync-trigger.sh`を呼び出し
3. `sync-trigger.sh`がバックグラウンドで`sync-monitor.sh`を起動
4. `sync-monitor.sh`がエージェント切り替えを検知
5. `handover-gen.sh`が自動的にhandoverドキュメントを生成
6. 生成されたhandoverは`.claude/shared/handover/`に保存

## 設定

### config.json
```json
{
  "sync_specialist": {
    "enabled": true,          // 有効/無効の切り替え
    "mode": "monitor"         // 動作モード
  },
  "monitoring": {
    "trigger_on": ["/agent:planner", "/agent:builder"],
    "timeout_seconds": 30,
    "async_execution": true
  }
}
```

### 有効化/無効化
```bash
# 無効化
jq '.sync_specialist.enabled = false' config.json > tmp.json && mv tmp.json config.json

# 有効化
jq '.sync_specialist.enabled = true' config.json > tmp.json && mv tmp.json config.json
```

## ログファイル

- `~/.claude/logs/sync-trigger.log` - トリガーイベントのログ
- `~/.claude/logs/sync-monitor.log` - 監視処理のログ
- `~/.claude/logs/handover-gen.log` - handover生成のログ

## トラブルシューティング

### handoverが生成されない
1. config.jsonで`enabled`が`true`になっているか確認
2. ログファイルでエラーを確認
3. active.mdファイルが正しく更新されているか確認

### パフォーマンスの問題
1. config.jsonで`timeout_seconds`を調整
2. `activity_limit`や`notes_lines`を減らす

### デバッグモード
```bash
# デバッグモードを有効化
export DEBUG=true
.claude/sync-specialist/sync-monitor.sh
```

## 将来の拡張

- Sequential Thinking統合
- MCPサーバーモード
- 高度な分析機能
- コンテキスト圧縮

## 注意事項

- このシステムは実験的な実装です
- 手動でのhandover作成も引き続き可能です
- 重要な引き継ぎ事項は手動で追記することを推奨します

---
*Pattern 2-1 Enhanced Hybrid - Sync Specialist v1.0.0*
