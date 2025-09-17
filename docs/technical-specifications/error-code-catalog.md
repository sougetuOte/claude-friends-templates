# エラーコード一覧

**バージョン**: 1.0.0  
**作成日**: 2025年9月17日  
**対象**: claude-friends-templates 全システム  
**準拠標準**: 2025年Error Handling Best Practices

## 概要

この文書は、claude-friends-templatesプロジェクトの全システムにおけるエラーコード体系、エラーカテゴリ、対応方法、修復手順を包括的に定義します。

## エラーコード体系

### コード形式

```
[COMPONENT]_[CATEGORY][NUMBER]

例:
- HOOK_E001: Hookシステムの一般エラー001
- MEM_W015:  Memory Bankシステムの警告015
- SEC_C005:  Securityシステムの致命的エラー005
```

### コンポーネントコード

| コード | コンポーネント | 説明 |
|-------|-----------|------|
| HOOK | Hook System | フックシステム全般 |
| MEM | Memory Bank | メモリバンクシステム |
| AGT | Agent System | エージェント管理システム |
| SEC | Security | セキュリティシステム |
| TDD | TDD System | TDD/品質管理システム |
| PAR | Parallel Execution | 並列実行システム |
| CFG | Configuration | 設定管理システム |
| LOG | Logging | ログシステム |
| SYS | System | システム全般 |
| NET | Network | ネットワーク関連 |

### カテゴリコード

| コード | カテゴリ | 重要度 | 説明 |
|-------|-------|------|---------|
| C | Critical | 致命的 | システム停止を引き起こす深刻なエラー |
| E | Error | エラー | 機能の実行を阻害するエラー |
| W | Warning | 警告 | 潜在的な問題や非推奨の使用方法 |
| I | Information | 情報 | 一般的な情報メッセージ |
| D | Debug | デバッグ | デバッグ用の詳細情報 |

## カテゴリ別エラーコード

### 1. Hookシステム (HOOK_)

#### 致命的エラー (HOOK_C###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| HOOK_C001 | Hook System Corruption | フックシステムの破損 | システム再起動、フックファイル再インストール |
| HOOK_C002 | Critical Hook Dependency Missing | 重要な依存関係の不足 | 依存関係のインストール、設定確認 |
| HOOK_C003 | Hook Infinite Loop | フックの無限ループ | プロセス強制終了、フック設定見直し |

#### 一般エラー (HOOK_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| HOOK_E001 | Invalid JSON Input | 入力JSON形式エラー | JSONフォーマットを確認、スキーマ検証 |
| HOOK_E002 | Missing Required Parameters | 必須パラメータ不足 | 入力パラメータを確認、ドキュメント参照 |
| HOOK_E003 | File Access Permission Error | ファイルアクセス権限エラー | ファイル権限を確認、chmodで修正 |
| HOOK_E004 | Hook Execution Timeout | フック実行タイムアウト | タイムアウト設定を増加、処理最適化 |
| HOOK_E005 | Insufficient System Resources | リソース不足エラー | システムリソースを確認、不要プロセス終了 |
| HOOK_E006 | Hook Dependency Error | 依存関係エラー | 依存コンポーネントの状態確認 |
| HOOK_E007 | Configuration File Error | 設定ファイルエラー | 設定ファイルの構文、値を確認 |
| HOOK_E008 | Hook State Corruption | フック状態破損 | フック状態をリセット、バックアップから復旧 |
| HOOK_E009 | Agent Communication Failure | エージェント通信失敗 | エージェント状態確認、ネットワーク確認 |
| HOOK_E010 | Hook Lock Timeout | フックロックタイムアウト | ロックファイルを手動削除、処理再実行 |

#### 警告 (HOOK_W###)

| コード | 警告名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| HOOK_W001 | Deprecated Hook Usage | 非推奨フックの使用 | 新しいAPIに移行、ドキュメント確認 |
| HOOK_W002 | Hook Performance Degradation | フックパフォーマンス低下 | 処理最適化、リソース監視 |
| HOOK_W003 | Large Input Data | 入力データサイズが大きい | データサイズを縮小、バッチ処理検討 |
| HOOK_W004 | Hook Chain Too Deep | フックチェーンが深すぎる | フック設計を見直し、循環参照確認 |
| HOOK_W005 | Memory Usage High | メモリ使用量が高い | メモリリーク確認、ガベージコレクション |

### 2. Memory Bankシステム (MEM_)

#### 致命的エラー (MEM_C###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| MEM_C001 | Memory Bank Corruption | メモリバンクの全体的破損 | バックアップから全体復旧、インデックス再構築 |
| MEM_C002 | Critical Memory Leak | 致命的メモリリーク | システム再起動、メモリプロファイリング |
| MEM_C003 | Index System Failure | インデックシングシステム全障 | インデックスを完全再構築、データ整合性確認 |

#### 一般エラー (MEM_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| MEM_E001 | File Not Found | メモリファイルが見つからない | ファイルパス確認、バックアップから復旧 |
| MEM_E002 | Rotation Process Failed | ローテーション処理失敗 | ローテーション設定確認、手動ローテーション |
| MEM_E003 | Index Update Failed | インデックス更新失敗 | インデックシング再実行、データ整合性確認 |
| MEM_E004 | Search Query Error | 検索クエリエラー | 検索クエリ構文確認、インデックス状態確認 |
| MEM_E005 | Importance Score Calculation Failed | 重要度スコア計算失敗 | スコアリングアルゴリズム確認、データ形式確認 |
| MEM_E006 | Archive Process Error | アーカイブ処理エラー | アーカイブ設定確認、ディスク容量確認 |
| MEM_E007 | Memory Bank Lock Error | メモリバンクロックエラー | ロックファイル削除、他プロセス確認 |
| MEM_E008 | Content Analysis Failed | コンテンツ分析失敗 | コンテンツ形式確認、エンコーディング確認 |
| MEM_E009 | Backup Creation Failed | バックアップ作成失敗 | ディスク容量確認、権限確認 |
| MEM_E010 | Duplicate Detection Error | 重複検出エラー | ハッシュアルゴリズム確認、ファイル整合性確認 |

#### 警告 (MEM_W###)

| コード | 警告名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| MEM_W001 | High Memory Usage | メモリ使用量が高い | メモリクリーンアップ、ローテーション実行 |
| MEM_W002 | Large File Detected | 大きなファイルが検出された | ファイル分割、ローテーション検討 |
| MEM_W003 | Index Size Growing | インデックスサイズが増大 | インデックス最適化、クリーンアップ実行 |
| MEM_W004 | Low Importance Files Accumulating | 低重要度ファイルの蓄積 | ローテーション闾値見直し、手動クリーンアップ |
| MEM_W005 | Search Performance Slow | 検索パフォーマンス低下 | インデックス最適化、キャッシュクリア |

### 3. エージェントシステム (AGT_)

#### 致命的エラー (AGT_C###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| AGT_C001 | Agent System Deadlock | エージェントシステムデッドロック | 全エージェント再起動、ステートリセット |
| AGT_C002 | Agent Communication Breakdown | エージェント間通信完全避断 | 通信システム再初期化、ネットワーク確認 |
| AGT_C003 | Multiple Active Agents Conflict | 複数アクティブエージェントの競合 | エージェント状態強制リセット、同期化 |

#### 一般エラー (AGT_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| AGT_E001 | Agent Startup Failed | エージェント起動失敗 | 設定ファイル確認、依存関係確認 |
| AGT_E002 | Agent Switch Failed | エージェント切り替え失敗 | 現在のエージェント状態確認、強制切り替え |
| AGT_E003 | Session State Corruption | セッション状態破損 | セッションリセット、バックアップから復旧 |
| AGT_E004 | Handover Generation Failed | ハンドオーバー生成失敗 | テンプレート確認、コンテキスト情報確認 |
| AGT_E005 | Agent Response Timeout | エージェント応答タイムアウト | タイムアウト設定確認、エージェント状態確認 |
| AGT_E006 | Invalid Agent Configuration | 不正なエージェント設定 | 設定ファイル検証、デフォルト設定復旧 |
| AGT_E007 | Memory Synchronization Failed | メモリ同期失敗 | メモリバンク状態確認、手動同期 |
| AGT_E008 | Agent Resource Limit Exceeded | エージェントリソース制限超過 | リソース制限設定見直し、メモリクリーンアップ |
| AGT_E009 | Agent Task Queue Overflow | エージェントタスクキューオーバーフロー | キューサイズ調整、优先度見直し |
| AGT_E010 | Agent Authentication Failed | エージェント認証失敗 | 認証情報確認、トークン更新 |

### 4. セキュリティシステム (SEC_)

#### 致命的エラー (SEC_C###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| SEC_C001 | Security System Compromise | セキュリティシステム侵害 | 緊急システム停止、セキュリティ監査 |
| SEC_C002 | Authentication System Breach | 認証システム侵害 | 全アクセス停止、認証システム再構築 |
| SEC_C003 | Critical Vulnerability Exploited | 致命的脆弱性の悪用 | システム隔離、緊急パッチ適用 |

#### 一般エラー (SEC_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| SEC_E001 | Input Validation Failed | 入力検証失敗 | 入力データをサニタイズ、バリデーションルール確認 |
| SEC_E002 | Access Control Violation | アクセス制御違反 | ユーザー権限確認、アクセスログ確認 |
| SEC_E003 | Encryption Process Failed | 暗号化処理失敗 | 暗号化キー確認、アルゴリズム設定確認 |
| SEC_E004 | Security Scan Failed | セキュリティスキャン失敗 | スキャンツール設定確認、手動スキャン |
| SEC_E005 | Certificate Validation Error | 証明書検証エラー | 証明書期限確認、証明書更新 |
| SEC_E006 | SBOM Generation Failed | SBOM生成失敗 | 依存関係情報確認、ツール設定確認 |
| SEC_E007 | Zero Trust Policy Violation | Zero Trustポリシー違反 | ポリシー設定確認、アクセス権限見直し |
| SEC_E008 | Vulnerability Database Update Failed | 脆弱性DB更新失敗 | ネットワーク接続確認、手動更新 |
| SEC_E009 | Security Audit Failed | セキュリティ監査失敗 | 監査ツール状態確認、監査スコープ見直し |
| SEC_E010 | Intrusion Detection Alert | 侵入検知アラート | アクセスログ調査、ネットワークトラフィック分析 |

### 5. TDD/品質管理システム (TDD_)

#### 一般エラー (TDD_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| TDD_E001 | Test File Not Found | テストファイルが見つからない | テストファイル作成、パス設定確認 |
| TDD_E002 | Coverage Below Threshold | カバレッジが闾値以下 | テストケース追加、カバレッジ分析 |
| TDD_E003 | Test Execution Failed | テスト実行失敗 | テストコード確認、テスト環境確認 |
| TDD_E004 | Code Quality Check Failed | コード品質チェック失敗 | リントエラー修正、コードスタイル確認 |
| TDD_E005 | Naming Convention Violation | 命名規則違反 | ファイル・関数名を規則に合わせて修正 |
| TDD_E006 | Test Structure Invalid | テスト構造が無効 | テストフレームワーク仕様確認、構造修正 |
| TDD_E007 | Mock Configuration Error | モック設定エラー | モックライブラリ設定確認 |
| TDD_E008 | Performance Test Failed | パフォーマンステスト失敗 | パフォーマンスボトルネック特定、最適化 |
| TDD_E009 | Integration Test Setup Failed | 結合テストセットアップ失敗 | テスト環境設定確認、依存関係確認 |
| TDD_E010 | Code Complexity Too High | コード複雑度が高すぎる | リファクタリング、関数分割 |

### 6. 並列実行システム (PAR_)

#### 一般エラー (PAR_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| PAR_E001 | Worker Process Failed | ワーカープロセス失敗 | ワーナーログ確認、プロセス再起動 |
| PAR_E002 | Task Queue Corruption | タスクキュー破損 | キューリセット、タスク再登録 |
| PAR_E003 | Load Balancer Error | ロードバランサーエラー | 負荷分散アルゴリズム確認、メトリクス確認 |
| PAR_E004 | Worker Pool Exhausted | ワーカープール果绊 | プールサイズ増加、タスク優先度調整 |
| PAR_E005 | Task Execution Timeout | タスク実行タイムアウト | タイムアウト設定見直し、タスク最適化 |
| PAR_E006 | Inter-Process Communication Failed | プロセス間通信失敗 | IPC機構確認、ネットワーク状態確認 |
| PAR_E007 | Resource Limit Exceeded | リソース制限超過 | リソース制限調整、タスク数調整 |
| PAR_E008 | Task Dependency Cycle | タスク依存関係循環 | 依存関係グラフ確認、タスク設計見直し |
| PAR_E009 | Worker Health Check Failed | ワーカーヘルスチェック失敗 | ワーカー状態確認、再起動または交換 |
| PAR_E010 | Parallel Execution Deadlock | 並列実行デッドロック | デッドロック検知、タスクスケジュール見直し |

### 7. 設定管理システム (CFG_)

#### 一般エラー (CFG_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| CFG_E001 | Configuration File Not Found | 設定ファイルが見つからない | デフォルト設定ファイル作成、パス確認 |
| CFG_E002 | Invalid JSON Format | 無効なJSON形式 | JSON構文エラー修正、バリデータ使用 |
| CFG_E003 | Schema Validation Failed | スキーマ検証失敗 | 設定値をスキーマに合わせて修正 |
| CFG_E004 | Required Setting Missing | 必須設定が不足 | 必須設定を追加、デフォルト値設定 |
| CFG_E005 | Configuration Conflict | 設定の矛盾 | 矛盾する設定を修正、優先度設定 |
| CFG_E006 | Environment Variable Error | 環境変数エラー | 環境変数設定確認、デフォルト値使用 |
| CFG_E007 | Configuration Update Failed | 設定更新失敗 | ファイル権限確認、バックアップから復旧 |
| CFG_E008 | Configuration Version Mismatch | 設定バージョン不一致 | 設定マイグレーション実行 |
| CFG_E009 | Configuration Backup Failed | 設定バックアップ失敗 | バックアップディレクトリ権限確認 |
| CFG_E010 | Configuration Lock Error | 設定ロックエラー | ロックファイル削除、他プロセス確認 |

### 8. ログシステム (LOG_)

#### 一般エラー (LOG_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| LOG_E001 | Log File Write Failed | ログファイル書き込み失敗 | ディスク容量確認、権限確認 |
| LOG_E002 | Log Rotation Failed | ログローテーション失敗 | ローテーション設定確認、手動ローテーション |
| LOG_E003 | Log Format Error | ログ形式エラー | ログフォーマット設定確認 |
| LOG_E004 | Log Level Configuration Error | ログレベル設定エラー | ログレベル設定を有効な値に修正 |
| LOG_E005 | Log Analysis Failed | ログ分析失敗 | ログファイルの整合性確認、ツール状態確認 |
| LOG_E006 | Structured Log Parsing Error | 構造化ログパーシングエラー | JSON形式確認、パーサー設定確認 |
| LOG_E007 | Log Buffer Overflow | ログバッファオーバーフロー | バッファサイズ増加、ログレベル調整 |
| LOG_E008 | Log Compression Failed | ログ圧縮失敗 | 圧縮ツール確認、ディスク容量確認 |
| LOG_E009 | Log Transport Error | ログ転送エラー | ネットワーク接続確認、転送先設定確認 |
| LOG_E010 | Log Aggregation Failed | ログ集約失敗 | 集約ルール確認、リソース確認 |

### 9. システム全般 (SYS_)

#### 致命的エラー (SYS_C###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| SYS_C001 | System Initialization Failed | システム初期化失敗 | システム再起動、初期化スクリプト確認 |
| SYS_C002 | Critical Resource Exhaustion | 致命的リソース果竺 | 緊急メンテナンス、リソース清理 |
| SYS_C003 | Core Component Failure | コアコンポーネント障害 | コンポーネント再起動、バックアップ系統へ切り替え |

#### 一般エラー (SYS_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| SYS_E001 | File System Error | ファイルシステムエラー | ファイルシステム整合性チェック、ディスク確認 |
| SYS_E002 | Permission Denied | 権限不足 | ファイル・ディレクトリ権限設定確認 |
| SYS_E003 | Process Spawn Failed | プロセス生成失敗 | システムリソース確認、プロセス制限確認 |
| SYS_E004 | Environment Setup Failed | 環境設定失敗 | 環境変数設定確認、パス設定確認 |
| SYS_E005 | Dependency Missing | 依存関係不足 | 必要なソフトウェア・ライブラリインストール |
| SYS_E006 | Command Execution Failed | コマンド実行失敗 | コマンドパス確認、実行権限確認 |
| SYS_E007 | Signal Handling Error | シグナル処理エラー | シグナルハンドラ設定確認 |
| SYS_E008 | Temporary Directory Error | 一時ディレクトリエラー | /tmp権限確認、ディスク容量確認 |
| SYS_E009 | Lock File Error | ロックファイルエラー | ロックファイル削除、権限確認 |
| SYS_E010 | System Monitoring Failed | システム監視失敗 | 監視システム設定確認、メトリクス収集確認 |

### 10. ネットワーク関連 (NET_)

#### 一般エラー (NET_E###)

| コード | エラー名 | 説明 | 対応方法 |
|-------|-------|------|---------|
| NET_E001 | Connection Timeout | 接続タイムアウト | ネットワーク接続確認、タイムアウト設定増加 |
| NET_E002 | DNS Resolution Failed | DNS解決失敗 | DNS設定確認、ネットワーク状態確認 |
| NET_E003 | SSL Certificate Error | SSL証明書エラー | 証明書期限確認、証明書更新 |
| NET_E004 | HTTP Response Error | HTTPレスポンスエラー | APIエンドポイント確認、レスポンスコード確認 |
| NET_E005 | Bandwidth Limit Exceeded | 帯域制限超過 | 帯域使用量確認、レートリミット設定 |
| NET_E006 | Proxy Configuration Error | プロキシ設定エラー | プロキシ設定確認、ネットワークポリシー確認 |
| NET_E007 | API Rate Limit Exceeded | APIレート制限超過 | APIコール頻度調整、レートリミット対応 |
| NET_E008 | Network Interface Error | ネットワークインターフェースエラー | ネットワークインターフェース状態確認 |
| NET_E009 | Firewall Blocking | ファイアウォールブロック | ファイアウォールルール確認、ポート開放 |
| NET_E010 | Load Balancing Error | 負荷分散エラー | ロードバランサー設定確認、ヘルスチェック |

## エラー対応マトリックス

### 緊急度別対応時間

| 緊急度 | 対応時間 | エスカレーション | 通知方法 |
|--------|----------|------------|----------|
| Critical | 15分以内 | 緊急連絡 | 電話、Slack、メール |
| High | 1時間以内 | チームリーダー | Slack、メール |
| Medium | 4時間以内 | 担当者 | メール、チケット |
| Low | 24時間以内 | 自動処理 | ログ記録のみ |

### 自動復旧ルール

| エラータイプ | リトライ回数 | リトライ間隔 | フェイルセーフ動作 |
|------------|----------|----------|----------|
| Timeout | 3 | 5, 15, 45秒 | タイムアウト値増加 |
| Network | 5 | 2, 4, 8, 16, 32秒 | オフラインモード |
| Resource | 2 | 10, 30秒 | リソースクリーンアップ |
| Permission | 1 | - | ユーザー通知 |
| Configuration | 0 | - | 設定ファイル確認要求 |

## エラーレポートフォーマット

### 標準エラーレポート

```json
{
  "@type": "ErrorReport",
  "@version": "1.0",
  "timestamp": "2025-09-17T12:34:56.789Z",
  "error_code": "HOOK_E001",
  "severity": "error",
  "component": "hook-system",
  "message": "Invalid JSON input format",
  "details": {
    "input_data": "malformed JSON string",
    "expected_format": "Valid JSON object",
    "file_location": "/path/to/file.json",
    "line_number": 15
  },
  "context": {
    "session_id": "session_12345",
    "user_id": "user_67890",
    "agent_type": "planner",
    "operation": "memory_rotation"
  },
  "system_info": {
    "hostname": "dev-machine",
    "os": "Linux 6.14.0-29-generic",
    "python_version": "3.11.2",
    "node_version": "18.17.0"
  },
  "stack_trace": [
    "File: hook-common.sh, Line: 125, Function: parse_json_input",
    "File: agent-switch.sh, Line: 45, Function: handle_agent_switch"
  ],
  "resolution_steps": [
    "1. Validate JSON syntax using jq or JSON validator",
    "2. Check input data format against schema",
    "3. Retry operation with corrected input"
  ],
  "related_errors": ["HOOK_W003"],
  "auto_recovery_attempted": true,
  "auto_recovery_success": false,
  "escalation_required": false
}
```

### エラーサマリレポート

```json
{
  "@type": "ErrorSummary",
  "@version": "1.0",
  "report_period": {
    "start": "2025-09-17T00:00:00.000Z",
    "end": "2025-09-17T23:59:59.999Z"
  },
  "error_statistics": {
    "total_errors": 156,
    "by_severity": {
      "critical": 2,
      "error": 23,
      "warning": 131
    },
    "by_component": {
      "hook-system": 45,
      "memory-bank": 67,
      "agent-system": 28,
      "security": 12,
      "other": 4
    },
    "resolution_rate": {
      "auto_resolved": 89.7,
      "manual_intervention": 7.1,
      "pending": 3.2
    }
  },
  "top_errors": [
    {
      "error_code": "MEM_W001",
      "count": 34,
      "trend": "increasing"
    },
    {
      "error_code": "HOOK_E001",
      "count": 18,
      "trend": "stable"
    }
  ],
  "recommendations": [
    "Increase memory rotation frequency to address MEM_W001",
    "Implement additional input validation for HOOK_E001",
    "Monitor SEC_E002 pattern for potential security concerns"
  ]
}
```

## モニタリングとアラート

### エラーメトリクス

```json
{
  "error_metrics": {
    "error_rate": "errors_per_minute",
    "error_resolution_time": "average_resolution_seconds",
    "escalation_rate": "escalated_errors_percentage",
    "auto_recovery_success_rate": "auto_recovery_success_percentage",
    "component_error_distribution": "errors_by_component",
    "severity_distribution": "errors_by_severity",
    "error_trend": "error_count_trend_7_days"
  },
  "alert_thresholds": {
    "critical_error_rate": 5,
    "error_spike_threshold": 200,
    "resolution_time_threshold": 3600,
    "auto_recovery_failure_rate": 30
  }
}
```

### アラートルール

1. **致命的エラー発生時**: 即座アラート
2. **エラー率急上昇**: 5分間で闾値の2倍超過
3. **同一エラーの連続発生**: 10回連続で発生
4. **自動復旧失敗率高騰**: 30%を超過
5. **新しいエラーコード発生**: 未知のエラーコード初回発生

## テスト仕様

### エラーシナリオテスト

```bash
# エラーシナリオテスト実行
.claude/scripts/test-error-scenarios.sh

# 特定エラーコードのテスト
.claude/scripts/test-error-scenarios.sh --error-code HOOK_E001

# 自動復旧テスト
.claude/scripts/test-error-scenarios.sh --test-recovery
```

### エラーハンドリングテスト

```bash
# エラーハンドリング機能テスト
.claude/scripts/test-error-handling.sh

# エラーレポート機能テスト
.claude/scripts/test-error-reporting.sh

# アラートシステムテスト
.claude/scripts/test-alert-system.sh
```

---

**最終更新**: 2025年9月17日  
**担当者**: Architecture Designer Agent  
**レビュー**: Phase 2.6.3 実装完了  
**バージョン**: 1.0.0
