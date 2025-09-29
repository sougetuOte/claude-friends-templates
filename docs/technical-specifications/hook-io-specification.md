# Hook Input/Output仕様書

**バージョン**: 1.0.0
**作成日**: 2025年9月17日
**対象**: claude-friends-templates Phase 2 Hook System
**準拠標準**: 2025年Hook Architecture Standards

## 概要

この文書は、claude-friends-templatesプロジェクトのHookシステムにおける入出力仕様、トリガー条件、環境変数を包括的に定義します。

## Hook入出力共通仕様

### 入力形式

```json
{
  "@type": "HookInput",
  "@version": "1.0",
  "timestamp": "2025-09-17T12:34:56.789Z",
  "hook_name": "string",
  "trigger_event": "string",
  "context": {
    "current_agent": "planner|builder|none",
    "previous_agent": "planner|builder|none|null",
    "session_id": "string",
    "project_root": "string",
    "working_directory": "string"
  },
  "payload": {},
  "metadata": {
    "user": "string",
    "hostname": "string",
    "pid": 0
  }
}
```

### 出力形式

```json
{
  "@type": "HookOutput",
  "@version": "1.0",
  "timestamp": "2025-09-17T12:34:56.789Z",
  "hook_name": "string",
  "status": "success|warning|error",
  "continue": true,
  "message": "string",
  "context": "string",
  "suppressOutput": false,
  "execution_time_ms": 0,
  "error_code": "string|null",
  "data": {}
}
```

## Hook別詳細仕様

### 1. Agent Switch Hook

**ファイル**: `.claude/hooks/agent/agent-switch.sh`

#### 入力仕様

```json
{
  "trigger_event": "agent_switch",
  "payload": {
    "from_agent": "planner|builder|none",
    "to_agent": "planner|builder|none",
    "reason": "user_request|automatic|session_complete",
    "prompt_content": "string"
  }
}
```

#### 出力仕様

```json
{
  "status": "success|error",
  "data": {
    "switch_completed": true,
    "previous_state_saved": true,
    "new_agent_initialized": true,
    "handover_generated": true,
    "memory_updated": true
  }
}
```

#### トリガー条件

- プロンプトに `/agent:` コマンドが含まれる
- セッション完了時の自動切り替え
- エラー状態からの復旧時
- タスク完了による自動エージェント切り替え

#### 環境変数

```bash
CLAUDE_PROJECT_DIR="/path/to/project"     # プロジェクトルートディレクトリ
CURRENT_AGENT="planner|builder|none"      # 現在のアクティブエージェント
SWITCH_TIMEOUT="30"                       # 切り替えタイムアウト（秒）
ENABLE_HANDOVER="true"                    # ハンドオーバー生成を有効化
LOG_LEVEL="info"                         # ログレベル
```

### 2. Memory Bank Rotation Hook

**ファイル**: `.claude/hooks/memory/notes-rotator.sh`

#### 入力仕様

```json
{
  "trigger_event": "memory_rotation",
  "payload": {
    "rotation_type": "size_based|time_based|manual",
    "target_files": ["string"],
    "rotation_config": {
      "max_size_mb": 10,
      "max_age_days": 30,
      "importance_threshold": 7.0
    }
  }
}
```

#### 出力仕様

```json
{
  "status": "success|warning|error",
  "data": {
    "files_rotated": 0,
    "files_archived": 0,
    "files_analyzed": 0,
    "total_size_reduced_mb": 0.0,
    "index_updated": true,
    "rotation_summary": {
      "high_importance_preserved": 0,
      "low_importance_archived": 0,
      "duplicates_removed": 0
    }
  }
}
```

#### トリガー条件

- メモリバンクファイルサイズが閾値を超過
- 定期実行（日次・週次）
- プロジェクト変更時
- ユーザーによる明示的な実行

#### 環境変数

```bash
MEMORY_DIR=".claude/memory"               # メモリバンクディレクトリ
ARCHIVE_DIR=".claude/memory/archive"      # アーカイブディレクトリ
MAX_FILE_SIZE_MB="10"                     # ファイル最大サイズ
IMP_THRESHOLD="7.0"                       # 重要度閾値
ROTATION_ENABLED="true"                   # ローテーション有効化
BACKUP_BEFORE_ROTATION="true"             # ローテーション前バックアップ
```

### 3. TDD Compliance Hook

**ファイル**: `.claude/hooks/tdd/tdd-checker.sh`

#### 入力仕様

```json
{
  "trigger_event": "tdd_check",
  "payload": {
    "check_type": "pre_commit|post_commit|manual",
    "target_files": ["string"],
    "check_scope": "test_existence|coverage|naming|structure"
  }
}
```

#### 出力仕様

```json
{
  "status": "pass|fail|warning",
  "data": {
    "checks_performed": 0,
    "passed_checks": 0,
    "failed_checks": 0,
    "warnings": 0,
    "compliance_score": 0.0,
    "detailed_results": [
      {
        "file": "string",
        "check": "string",
        "result": "pass|fail|warning",
        "message": "string"
      }
    ]
  }
}
```

#### トリガー条件

- コミット前のPre-commitフック
- ファイル変更検知
- プロジェクト設定変更
- 品質ゲート実行時

#### 環境変数

```bash
TDD_CONFIG_FILE=".claude/tdd_checker_config.json"  # TDD設定ファイル
TEST_DIR="tests"                                   # テストディレクトリ
COVERAGE_THRESHOLD="80"                            # カバレッジ閾値
STRICT_NAMING="true"                               # 厳格な命名規則
AUTO_FIX="false"                                   # 自動修正機能
```

### 4. Monitoring & Alert Hook

**ファイル**: `.claude/hooks/monitoring/alert-system.sh`

#### 入力仕様

```json
{
  "trigger_event": "monitoring_alert",
  "payload": {
    "alert_type": "performance|error|security|resource",
    "severity": "critical|high|medium|low",
    "metrics": {
      "cpu_usage_percent": 0.0,
      "memory_usage_mb": 0,
      "disk_usage_percent": 0.0,
      "error_rate": 0.0
    },
    "threshold_exceeded": "string"
  }
}
```

#### 出力仕様

```json
{
  "status": "success|error",
  "data": {
    "alert_sent": true,
    "recipients_notified": 0,
    "escalation_triggered": false,
    "remediation_actions": ["string"],
    "alert_id": "string",
    "suppression_until": "2025-09-17T12:34:56.789Z"
  }
}
```

#### トリガー条件

- メトリクス閾値超過
- エラー率増加
- リソース不足警告
- セキュリティイベント検知

#### 環境変数

```bash
MONITORING_CONFIG=".claude/monitoring-config.json"  # 監視設定ファイル
ALERT_WEBHOOK_URL=""                               # アラート通知URL
SUPPRESSION_PERIOD="300"                           # アラート抑制期間（秒）
EMAIL_NOTIFICATIONS="false"                        # Email通知有効化
SLACK_NOTIFICATIONS="false"                        # Slack通知有効化
```

### 5. Parallel Execution Hook

**ファイル**: `.claude/hooks/parallel/parallel-executor.sh`

#### 入力仕様

```json
{
  "trigger_event": "parallel_execution",
  "payload": {
    "execution_plan": {
      "max_workers": 4,
      "timeout_seconds": 300,
      "retry_attempts": 3
    },
    "tasks": [
      {
        "id": "string",
        "command": "string",
        "args": ["string"],
        "working_dir": "string",
        "priority": 1,
        "dependencies": ["string"]
      }
    ]
  }
}
```

#### 出力仕様

```json
{
  "status": "success|partial|error",
  "data": {
    "total_tasks": 0,
    "completed_tasks": 0,
    "failed_tasks": 0,
    "execution_time_seconds": 0.0,
    "worker_stats": {
      "workers_used": 0,
      "average_task_time": 0.0,
      "peak_concurrency": 0
    },
    "task_results": [
      {
        "task_id": "string",
        "status": "completed|failed|timeout",
        "exit_code": 0,
        "execution_time": 0.0,
        "output": "string",
        "error": "string"
      }
    ]
  }
}
```

#### トリガー条件

- バッチ処理実行要求
- 並列テスト実行
- 大量ファイル処理
- システムメンテナンス

#### 環境変数

```bash
PARALLEL_MAX_WORKERS="4"                    # 最大ワーカー数
PARALLEL_TIMEOUT="300"                      # タスクタイムアウト（秒）
PARALLEL_RETRY="3"                          # リトライ回数
WORKER_MEMORY_LIMIT="512M"                  # ワーカーメモリ制限
TASK_QUEUE_SIZE="100"                       # タスクキューサイズ
```

## セキュリティ要件

### 入力検証

1. **JSONスキーマ検証**: 全Hook入力はJSONスキーマに準拠
2. **サイズ制限**: 入力データは最大1MBまで
3. **文字種制限**: プリント可能文字のみ許可
4. **パス検証**: ファイルパスはプロジェクト内に制限

### 出力サニタイゼーション

1. **HTMLエスケープ**: Web出力時のXSS対策
2. **SQLエスケープ**: データベース操作時のインジェクション対策
3. **シェルエスケープ**: コマンド実行時のインジェクション対策

### アクセス制御

1. **ファイル権限**: Hook実行用の最小権限
2. **ディレクトリ制限**: プロジェクト外アクセス禁止
3. **コマンド制限**: 許可コマンドのホワイトリスト

## エラーハンドリング

### エラーコード体系

| エラーコード | 説明 | 対応方法 |
|-------------|------|----------|
| HOOK_E001 | 入力JSON形式エラー | JSONフォーマットを確認 |
| HOOK_E002 | 必須パラメータ不足 | 入力パラメータを確認 |
| HOOK_E003 | ファイルアクセス権限エラー | ファイル権限を確認 |
| HOOK_E004 | タイムアウトエラー | 処理時間を最適化 |
| HOOK_E005 | リソース不足エラー | システムリソースを確認 |
| HOOK_E006 | 依存関係エラー | 必要なツールを確認 |
| HOOK_E007 | 設定ファイルエラー | 設定ファイルを確認 |

### エラー回復手順

1. **自動リトライ**: 一時的なエラーは3回まで自動リトライ
2. **フェイルセーフ**: エラー時はデフォルト動作に戻る
3. **ログ記録**: 全エラーは構造化ログに記録
4. **アラート送信**: 重要なエラーはアラートシステムに通知

## パフォーマンス要件

### 応答時間

- **軽量Hook**: 1秒以内
- **中程度Hook**: 10秒以内
- **重量Hook**: 60秒以内

### リソース使用量

- **CPU使用率**: 80%以下
- **メモリ使用量**: 512MB以下
- **ディスクI/O**: 100MB/s以下

### 並行実行

- **最大同時Hook数**: 10個
- **キューサイズ**: 100個
- **優先度制御**: 有効

## テスト仕様

### 単体テスト

```bash
# Hook単体テスト実行
.claude/scripts/test-hooks.sh --hook agent-switch
.claude/scripts/test-hooks.sh --hook memory-rotation
.claude/scripts/test-hooks.sh --hook tdd-checker
```

### 統合テスト

```bash
# Hook統合テスト実行
.claude/scripts/test-hooks.sh --integration
```

### 性能テスト

```bash
# Hook性能テスト実行
.claude/scripts/test-hooks.sh --performance
```

## 監視とメトリクス

### 収集メトリクス

1. **実行回数**: Hook種別ごとの実行回数
2. **実行時間**: Hook実行時間の分布
3. **成功率**: Hook成功・失敗率
4. **エラー率**: エラー種別ごとの発生率

### アラート閾値

- **エラー率**: 10%を超過
- **実行時間**: 通常の3倍を超過
- **リソース使用量**: 制限値の90%を超過

---

**最終更新**: 2025年9月17日
**担当者**: Architecture Designer Agent
**レビュー**: Phase 2.6.3 実装完了
