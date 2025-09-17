# シェルスクリプトインターフェース定義

**バージョン**: 1.0.0  
**作成日**: 2025年9月17日  
**対象**: claude-friends-templates Shell Script System  
**準拠標準**: 2025年Shell Scripting Best Practices

## 概要

この文書は、claude-friends-templatesプロジェクトの全シェルスクリプトにおける入出力仕様、引数、戻り値、エラーハンドリングを包括的に定義します。

## 共通インターフェース仕様

### 標準引数形式

```bash
script_name [OPTIONS] [ARGUMENTS]

OPTIONS:
  -h, --help              ヘルプ情報を表示
  -v, --verbose           詳細な出力を有効化
  -q, --quiet             無音モード
  -d, --debug             デバッグモード
  --dry-run               ドライランモード（実際の変更なし）
  --config FILE           設定ファイルの指定
```

### 標準戻り値

| コード | 意味 | 説明 |
|-------|------|------|
| 0 | SUCCESS | 正常終了 |
| 1 | GENERAL_ERROR | 一般的なエラー |
| 2 | INVALID_ARGS | 不正な引数 |
| 3 | FILE_NOT_FOUND | ファイルが見つからない |
| 4 | PERMISSION_DENIED | 権限不足 |
| 5 | DEPENDENCY_ERROR | 依存関係エラー |
| 6 | CONFIG_ERROR | 設定エラー |
| 7 | TIMEOUT_ERROR | タイムアウト |
| 8 | RESOURCE_ERROR | リソースエラー |
| 9 | VALIDATION_ERROR | バリデーションエラー |
| 10 | NETWORK_ERROR | ネットワークエラー |

### 標準出力形式

```bash
# 標準出力 (stdout)
[INFO] 通常の情報メッセージ
[SUCCESS] 成功メッセージ

# 標準エラー出力 (stderr)
[ERROR] エラーメッセージ
[WARNING] 警告メッセージ
[DEBUG] デバッグ情報 (デバッグモード時のみ)
```

### 環境変数

```bash
# システム共通環境変数
CLAUDE_PROJECT_DIR="/path/to/project"     # プロジェクトルート
CLAUDE_CONFIG_DIR=".claude"              # 設定ディレクトリ
CLAUDE_LOG_LEVEL="info"                  # ログレベル
CLAUDE_DEBUG="false"                     # デバッグモード
CLAUDE_DRY_RUN="false"                   # ドライランモード
```

## カテゴリ別スクリプト仕様

### 1. メモリバンク管理スクリプト

#### ノートローテーションスクリプト

**ファイル**: `.claude/scripts/rotate-notes.sh`

```bash
Usage: rotate-notes.sh [OPTIONS] [DIRECTORY]

DESCRIPTION:
    Memory Bankファイルのローテーションとアーカイブを実行

OPTIONS:
    -t, --type TYPE         ローテーションタイプ (size|time|importance|manual)
    -s, --size-limit SIZE   ファイルサイズ制限 (MB)
    -a, --age-limit DAYS    ファイル年齢制限 (日)
    -i, --importance SCORE  重要度闾値
    --backup                ローテーション前にバックアップ作成
    --force                 確認プロンプトをスキップ

ARGUMENTS:
    DIRECTORY               ローテーション対象ディレクトリ (デフォルト: .claude/memory/active)

EXAMPLES:
    # サイズベースローテーション
    rotate-notes.sh --type size --size-limit 10
    
    # 時間ベースローテーション
    rotate-notes.sh --type time --age-limit 30
    
    # 重要度ベースローテーション
    rotate-notes.sh --type importance --importance 5.0
    
    # ドライランモード
    rotate-notes.sh --dry-run --type manual

OUTPUT:
    標準出力: ローテーション結果サマリ (JSON形式)
    標準エラー: エラーメッセージ、警告
```

**入力仕様**:
- コマンドライン引数
- 設定ファイル: `.claude/memory/config/rotation_config.json`
- 環境変数: `ROTATION_*`

**出力仕様**:
```json
{
  "rotation_summary": {
    "type": "size",
    "started_at": "2025-09-17T12:34:56.789Z",
    "completed_at": "2025-09-17T12:35:23.456Z",
    "files_processed": 156,
    "files_rotated": 23,
    "files_archived": 23,
    "total_size_reduced_mb": 45.2,
    "errors": 0,
    "warnings": 2
  },
  "details": [
    {
      "file": "old_notes.md",
      "action": "archived",
      "reason": "size_limit_exceeded",
      "original_size_mb": 12.5,
      "importance_score": 3.2
    }
  ]
}
```

#### インデックス更新スクリプト

**ファイル**: `.claude/scripts/update-index.sh`

```bash
Usage: update-index.sh [OPTIONS] [FILES...]

DESCRIPTION:
    Memory Bankインデックスの更新と再構築

OPTIONS:
    -m, --mode MODE         更新モード (full|incremental|selective)
    -t, --type TYPE         インデックスタイプ (content|keyword|importance|temporal|all)
    --optimize              インデックス最適化を実行
    --validate              インデックス整合性を検証
    --rebuild               インデックスを完全に再構築

ARGUMENTS:
    FILES                   更新対象ファイル (selectiveモード時のみ)

EXAMPLES:
    # フルインデックス更新
    update-index.sh --mode full
    
    # 特定ファイルのインデックシング
    update-index.sh --mode selective file1.md file2.md
    
    # キーワードインデックスのみ更新
    update-index.sh --mode incremental --type keyword

OUTPUT:
    標準出力: インデックシング結果統計
```

#### メモリメンテナンススクリプト

**ファイル**: `.claude/scripts/notes-maintenance.sh`

```bash
Usage: notes-maintenance.sh [OPTIONS] [OPERATION]

DESCRIPTION:
    Memory Bankの定期メンテナンスと最適化

OPTIONS:
    -s, --schedule CRON     cronスケジュールで実行
    --cleanup               不要ファイルのクリーンアップ
    --compress              アーカイブファイルの圧縮
    --analyze               コンテンツ分析と重要度更新
    --report                メンテナンスレポート生成

OPERATION:
    full                    全てのメンテナンス操作を実行
    quick                   基本的なメンテナンスのみ
    repair                  整合性チェックと修復

EXAMPLES:
    # フルメンテナンス
    notes-maintenance.sh full
    
    # 特定操作のみ
    notes-maintenance.sh --cleanup --compress
    
    # スケジュール実行設定
    notes-maintenance.sh --schedule "0 2 * * *" full
```

### 2. エージェント管理スクリプト

#### エージェント切り替えフック

**ファイル**: `.claude/scripts/agent-switch-hook.sh`

```bash
Usage: agent-switch-hook.sh [OPTIONS] FROM_AGENT TO_AGENT

DESCRIPTION:
    エージェント切り替え時のフック処理

OPTIONS:
    -r, --reason REASON     切り替え理由 (user|auto|error|complete)
    -s, --session-id ID     セッションID
    --handover              ハンドオーバーファイル生成
    --preserve-state        エージェント状態を保存

ARGUMENTS:
    FROM_AGENT              切り替え元エージェント (planner|builder|none)
    TO_AGENT                切り替え先エージェント (planner|builder|none)

EXAMPLES:
    # ユーザーによるエージェント切り替え
    agent-switch-hook.sh --reason user none planner
    
    # タスク完了による自動切り替え
    agent-switch-hook.sh --reason complete --handover planner builder

INPUT:
    標準入力: エージェントコンテキスト情報 (JSON)
    
    {
      "prompt": "string",
      "session_context": {},
      "agent_state": {},
      "user_preferences": {}
    }

OUTPUT:
    標準出力: フック処理結果 (JSON)
    
    {
      "continue": true,
      "message": "Agent switched successfully",
      "context": "planner -> builder",
      "suppressOutput": false,
      "handover_file": "/path/to/handover.md",
      "state_preserved": true
    }
```

#### セッション完了スクリプト

**ファイル**: `.claude/scripts/session-complete.sh`

```bash
Usage: session-complete.sh [OPTIONS] [SESSION_ID]

DESCRIPTION:
    セッション終了時のクリーンアップとサマリ生成

OPTIONS:
    -s, --summary           セッションサマリを生成
    -c, --cleanup           一時ファイルをクリーンアップ
    -a, --archive           セッションデータをアーカイブ
    --backup                セッションバックアップを作成
    --auto                  自動モード (プロンプトなし)

ARGUMENTS:
    SESSION_ID              セッションID (省略時は現在のセッション)

EXAMPLES:
    # 基本的なセッション終了
    session-complete.sh
    
    # サマリ付きセッション終了
    session-complete.sh --summary --archive
    
    # 特定セッションの終了
    session-complete.sh --auto session_12345

OUTPUT:
    標準出力: セッション終了結果サマリ
    ファイル出力: セッションサマリファイル (.claude/sessions/)
```

### 3. 品質管理スクリプト

#### TDDチェックスクリプト

**ファイル**: `.claude/scripts/tdd-check.sh`

```bash
Usage: tdd-check.sh [OPTIONS] [FILES...]

DESCRIPTION:
    TDDコンプライアンスチェックと品質検証

OPTIONS:
    -t, --type TYPE         チェックタイプ (existence|coverage|naming|structure|all)
    -l, --level LEVEL       严密レベル (strict|normal|lenient)
    -f, --format FORMAT     出力形式 (json|markdown|summary)
    --threshold PERCENT     カバレッジ闾値 (デフォルト: 80)
    --fix                   自動修正を試みる
    --baseline              ベースラインを作成/更新

ARGUMENTS:
    FILES                   チェック対象ファイル (省略時は全プロジェクト)

EXAMPLES:
    # 全TDDチェック
    tdd-check.sh --type all
    
    # テストカバレッジチェック
    tdd-check.sh --type coverage --threshold 90
    
    # 特定ファイルのチェック
    tdd-check.sh --type existence src/main.js src/utils.js

OUTPUT:
    標準出力: TDDチェック結果 (JSONまたはMarkdown)
    標準エラー: エラー、警告メッセージ
    終了コード: 0(成功), 1(失敗), 2(警告あり)
```

#### 品質ゲートスクリプト

**ファイル**: `.claude/scripts/quality-pre-commit.sh`

```bash
Usage: quality-pre-commit.sh [OPTIONS]

DESCRIPTION:
    コミット前の品質ゲートチェック

OPTIONS:
    --staged-only           ステージされたファイルのみチェック
    --skip-tests            テスト実行をスキップ
    --skip-lint             リントチェックをスキップ
    --skip-format           フォーマットチェックをスキップ
    --auto-fix              自動修正を有効化
    --strict                厳格モード

EXAMPLES:
    # 標準品質ゲート
    quality-pre-commit.sh
    
    # ステージされたファイルのみ
    quality-pre-commit.sh --staged-only
    
    # 自動修正付き
    quality-pre-commit.sh --auto-fix

OUTPUT:
    標準出力: 品質チェック結果サマリ
    終了コード: 0(合格), 1(不合格)
```

### 4. セキュリティスクリプト

#### セキュリティセットアップ

**ファイル**: `.claude/scripts/setup-security.sh`

```bash
Usage: setup-security.sh [OPTIONS]

DESCRIPTION:
    セキュリティシステムの初期設定と設定

OPTIONS:
    --component COMP        特定コンポーネントのみセットアップ
                           (zero-trust|sbom|sast|input-validation|devsecops)
    --reset                 既存設定をリセット
    --update                設定を更新のみ
    --validate              設定の検証のみ

EXAMPLES:
    # 全セキュリティシステムセットアップ
    setup-security.sh
    
    # Zero Trustのみセットアップ
    setup-security.sh --component zero-trust
    
    # 設定検証
    setup-security.sh --validate

OUTPUT:
    標準出力: セットアップ結果と次のステップ
    設定ファイル: .claude/security-config.json
```

#### セキュリティテスト

**ファイル**: `.claude/scripts/test-security.sh`

```bash
Usage: test-security.sh [OPTIONS] [TEST_SUITE]

DESCRIPTION:
    セキュリティシステムの統合テスト

OPTIONS:
    -t, --type TYPE         テストタイプ (unit|integration|penetration)
    -c, --coverage          カバレッジレポートを生成
    -r, --report            詳細レポートを生成
    --baseline              セキュリティベースラインを作成

TEST_SUITE:
    all                     全テストスイート
    auth                    認証テスト
    input-validation        入力検証テスト
    access-control          アクセス制御テスト

EXAMPLES:
    # 全テスト実行
    test-security.sh all
    
    # 入力検証テストのみ
    test-security.sh --type unit input-validation
    
    # カバレッジレポート付き
    test-security.sh --coverage --report all

OUTPUT:
    標準出力: テスト結果サマリ
    ファイル出力: テストレポート (.claude/security/test-reports/)
```

### 5. ユーティリティスクリプト

#### 設定検証スクリプト

**ファイル**: `.claude/scripts/validate-config.sh`

```bash
Usage: validate-config.sh [OPTIONS] [CONFIG_FILES...]

DESCRIPTION:
    設定ファイルの検証と整合性チェック

OPTIONS:
    --schema                JSONスキーマ検証を実行
    --syntax                構文チェックのみ
    --semantic              意味的検証を実行
    --fix                   自動修正を試みる
    --strict                厳格モード

ARGUMENTS:
    CONFIG_FILES            検証対象ファイル (省略時は全設定ファイル)

EXAMPLES:
    # 全設定ファイル検証
    validate-config.sh
    
    # 特定ファイルのみ
    validate-config.sh .claude/settings.json
    
    # スキーマ検証のみ
    validate-config.sh --schema --strict

OUTPUT:
    標準出力: 検証結果サマリ (JSON)
    標準エラー: 検証エラー詳細
```

#### ログ分析スクリプト

**ファイル**: `.claude/scripts/activity-logger.sh`

```bash
Usage: activity-logger.sh [OPTIONS] [COMMAND]

DESCRIPTION:
    システムアクティビティのログ記録と分析

OPTIONS:
    -l, --level LEVEL       ログレベル (debug|info|warn|error)
    -f, --format FORMAT     出力形式 (json|text|structured)
    -t, --tail              リアルタイムモード
    --rotate                ログローテーションを実行
    --analyze               ログ分析を実行

COMMAND:
    start                   ログ記録開始
    stop                    ログ記録停止
    status                  ログシステムの状態確認
    query                   ログ検索

EXAMPLES:
    # ログ記録開始
    activity-logger.sh start
    
    # エラーログのみ表示
    activity-logger.sh --level error --tail
    
    # ログ分析実行
    activity-logger.sh --analyze

OUTPUT:
    標準出力: ログエントリまたは分析結果
    ファイル出力: ログファイル (.claude/logs/)
```

## コマンドラインパーサー仕様

### 引数解析ライブラリ

**ファイル**: `.claude/scripts/shared-utils.sh`

```bash
# 引数解析関数
parse_arguments() {
    local script_name="$1"
    shift
    
    # デフォルト値
    VERBOSE=false
    QUIET=false
    DEBUG=false
    DRY_RUN=false
    HELP=false
    CONFIG_FILE=""
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                HELP=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                VERBOSE=true  # デバッグモードでは自動的にverboseも有効
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage "$script_name"
                exit 2
                ;;
            *)
                # 位置引数
                POSITIONAL_ARGS+=("$1")
                shift
                ;;
        esac
    done
    
    # 残りの引数を位置引数に追加
    POSITIONAL_ARGS+=("$@")
    
    # ヘルプ表示
    if [[ "$HELP" == "true" ]]; then
        print_usage "$script_name"
        exit 0
    fi
    
    # 矛盾するオプションのチェック
    if [[ "$VERBOSE" == "true" && "$QUIET" == "true" ]]; then
        log_error "--verbose and --quiet cannot be used together"
        exit 2
    fi
    
    # グローバル環境変数に設定
    export CLAUDE_VERBOSE="$VERBOSE"
    export CLAUDE_QUIET="$QUIET"
    export CLAUDE_DEBUG="$DEBUG"
    export CLAUDE_DRY_RUN="$DRY_RUN"
    
    if [[ -n "$CONFIG_FILE" ]]; then
        export CLAUDE_CONFIG_FILE="$CONFIG_FILE"
    fi
}
```

### ヘルプシステム

```bash
# ヘルプ情報表示関数
print_usage() {
    local script_name="$1"
    local script_path
    script_path=$(realpath "$0")
    
    # スクリプト内のヘルプテキストを抽出
    local help_text
    help_text=$(grep -A 50 "^# Usage:" "$script_path" | grep -B 50 "^# Examples:" | tail -n +2)
    
    if [[ -n "$help_text" ]]; then
        echo "$help_text"
    else
        # デフォルトヘルプ
        cat <<EOF
Usage: $script_name [OPTIONS] [ARGUMENTS]

DESCRIPTION:
    （ヘルプテキストが定義されていません）

OPTIONS:
    -h, --help              ヘルプ情報を表示
    -v, --verbose           詳細な出力を有効化
    -q, --quiet             無音モード
    -d, --debug             デバッグモード
    --dry-run               ドライランモード
    --config FILE           設定ファイルの指定
EOF
    fi
}
```

## エラーハンドリング仕様

### エラートラップとクリーンアップ

```bash
# エラートラップ設定
setup_error_handling() {
    set -euo pipefail  # 厳格モード
    
    # エラートラップ
    trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[*]}"' ERR
    
    # 終了シグナルトラップ
    trap 'cleanup_on_exit' EXIT
    trap 'handle_interrupt' INT TERM
}

# エラーハンドラー
handle_error() {
    local exit_code=$1
    local line_number=$2
    local bash_lineno=$3
    local command="$4"
    local function_stack="$5"
    
    log_error "Script failed with exit code $exit_code"
    log_error "  Line: $line_number"
    log_error "  Command: $command"
    log_error "  Function stack: $function_stack"
    
    # デバッグ情報をログに記録
    if [[ "$DEBUG" == "true" ]]; then
        log_debug "Environment variables:"
        env | grep "^CLAUDE_" | while read -r var; do
            log_debug "  $var"
        done
        
        log_debug "Call stack:"
        local i=0
        while caller $i 2>/dev/null; do
            ((i++))
        done | while read -r line func file; do
            log_debug "  $file:$line in $func()"
        done
    fi
    
    # クリーンアップを実行
    cleanup_on_error
    
    exit $exit_code
}

# クリーンアップ処理
cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_debug "Script completed successfully"
    else
        log_error "Script exited with code $exit_code"
    fi
    
    # 一時ファイルのクリーンアップ
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_debug "Cleaned up temporary directory: $TEMP_DIR"
    fi
    
    # ロックファイルのクリーンアップ
    if [[ -n "${LOCK_FILE:-}" && -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
        log_debug "Released lock file: $LOCK_FILE"
    fi
}
```

### バリデーション関数

```bash
# ファイル存在チェック
validate_file_exists() {
    local file_path="$1"
    local description="${2:-file}"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "Required $description not found: $file_path"
        return 3
    fi
    
    return 0
}

# ディレクトリ存在チェック
validate_directory_exists() {
    local dir_path="$1"
    local description="${2:-directory}"
    
    if [[ ! -d "$dir_path" ]]; then
        log_error "Required $description not found: $dir_path"
        return 3
    fi
    
    return 0
}

# 実行権限チェック
validate_executable() {
    local command="$1"
    local description="${2:-command}"
    
    if ! command -v "$command" >/dev/null 2>&1; then
        log_error "Required $description not found: $command"
        log_error "Please install $command or ensure it's in PATH"
        return 5
    fi
    
    return 0
}

# 数値範囲チェック
validate_number_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    local description="${4:-value}"
    
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "Invalid $description: '$value' is not a number"
        return 9
    fi
    
    if [[ $value -lt $min || $value -gt $max ]]; then
        log_error "Invalid $description: $value is out of range [$min, $max]"
        return 9
    fi
    
    return 0
}
```

## パフォーマンス最適化

### 並列実行サポート

```bash
# 並列処理関数
run_parallel() {
    local max_jobs="${1:-4}"
    local commands=("${@:2}")
    
    local pids=()
    local job_count=0
    
    for command in "${commands[@]}"; do
        # 最大ジョブ数を超える場合は待機
        while [[ ${#pids[@]} -ge $max_jobs ]]; do
            wait_for_job pids
        done
        
        # コマンドをバックグラウンドで実行
        eval "$command" &
        local pid=$!
        pids+=("$pid")
        
        log_debug "Started job $((++job_count)): PID $pid"
    done
    
    # 全ジョブの完了を待機
    for pid in "${pids[@]}"; do
        wait "$pid"
        local exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            log_warning "Job PID $pid failed with exit code $exit_code"
        fi
    done
}

# ジョブ完了待機
wait_for_job() {
    local -n pids_ref=$1
    local completed_pids=()
    
    for i in "${!pids_ref[@]}"; do
        local pid="${pids_ref[i]}"
        if ! kill -0 "$pid" 2>/dev/null; then
            wait "$pid" 2>/dev/null
            completed_pids+=("$i")
        fi
    done
    
    # 完了したPIDを配列から削除
    for i in "${completed_pids[@]}"; do
        unset "pids_ref[$i]"
    done
    
    # 配列を再構築
    pids_ref=("${pids_ref[@]}")
}
```

### キャッシュ機能

```bash
# キャッシュファイルパス生成
get_cache_path() {
    local key="$1"
    local cache_dir=".claude/cache"
    
    mkdir -p "$cache_dir"
    
    # キーをハッシュ化
    local hash
    hash=$(echo -n "$key" | sha256sum | cut -d' ' -f1)
    
    echo "$cache_dir/$hash.cache"
}

# キャッシュから値を取得
get_from_cache() {
    local key="$1"
    local max_age_seconds="${2:-3600}"  # デフォルトは1時間
    
    local cache_file
    cache_file=$(get_cache_path "$key")
    
    if [[ -f "$cache_file" ]]; then
        local file_age
        file_age=$(stat -c %Y "$cache_file")
        local current_time
        current_time=$(date +%s)
        
        if [[ $((current_time - file_age)) -le $max_age_seconds ]]; then
            cat "$cache_file"
            return 0
        else
            rm -f "$cache_file"
        fi
    fi
    
    return 1
}

# キャッシュに値を保存
set_to_cache() {
    local key="$1"
    local value="$2"
    
    local cache_file
    cache_file=$(get_cache_path "$key")
    
    echo "$value" > "$cache_file"
}
```

## テスト仕様

### スクリプトテストフレームワーク

**ファイル**: `.claude/scripts/test-hooks.sh`

```bash
Usage: test-hooks.sh [OPTIONS] [TEST_TARGETS...]

DESCRIPTION:
    シェルスクリプトの統合テストスイート

OPTIONS:
    -t, --type TYPE         テストタイプ (unit|integration|performance)
    -c, --coverage          カバレッジレポートを生成
    -p, --parallel          並列テスト実行
    --timeout SECONDS       テストタイムアウト
    --mock                  モックモードで実行

TEST_TARGETS:
    all                     全スクリプトテスト
    memory                  メモリバンク関連テスト
    security                セキュリティ関連テスト
    agent                   エージェント関連テスト
    quality                 品質関連テスト

EXAMPLES:
    # 全テスト実行
    test-hooks.sh all
    
    # メモリバンクテストのみ
    test-hooks.sh --type unit memory
    
    # カバレッジ付き並列テスト
    test-hooks.sh --parallel --coverage all

OUTPUT:
    標準出力: テスト結果サマリ (TAP形式)
    ファイル出力: テストレポート (.claude/test-reports/)
```

---

**最終更新**: 2025年9月17日  
**担当者**: Architecture Designer Agent  
**レビュー**: Phase 2.6.3 実装完了
