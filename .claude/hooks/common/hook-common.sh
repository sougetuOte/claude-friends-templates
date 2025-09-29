#!/bin/bash
# hook-common.sh - Claude Code Hooks共通ライブラリ
# TDD Refactored - セキュリティ、パフォーマンス、品質改善済み

set -euo pipefail

# Bash 4+ の機能を使用（アソシエイティブ配列など）
if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    echo "[WARNING] Bash 4.0+ recommended for optimal performance" >&2
fi

# ===== グローバル設定 =====
readonly HOOKS_VERSION="1.0.0"
readonly PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
readonly LOG_DIR="${PROJECT_ROOT}/.claude/logs"
readonly AGENTS_DIR="${PROJECT_ROOT}/.claude/agents"
readonly MEMORY_DIR="${PROJECT_ROOT}/.claude/memory"

# デバッグモード設定
readonly DEBUG="${HOOKS_DEBUG:-false}"

# ===== ヘルパー関数 =====

# デバッグログ出力
_debug() {
    [[ "$DEBUG" == "true" ]] && echo "[DEBUG] $*" >&2
    return 0
}

# エラーログ出力
_error() {
    echo "[ERROR] $*" >&2
    return 1
}

# ===== セキュリティ関数 =====

# validate_agent_name - エージェント名の厳格な検証
# 引数: agent_name - 検証するエージェント名
# 戻り値: 0=有効, 1=無効
secure_validate_agent_name() {
    local -r agent_name="${1:-}"

    # 空文字チェック
    if [[ -z "$agent_name" ]]; then
        _error "Empty agent name provided"
        return 1
    fi

    # 長さ制限（最大32文字）
    if [[ ${#agent_name} -gt 32 ]]; then
        _error "Agent name too long: ${#agent_name} chars (max: 32)"
        return 1
    fi

    # 厳格な文字種制限（英数字、ハイフン、アンダースコアのみ）
    if [[ ! "$agent_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        _error "Invalid agent name format: $agent_name"
        return 1
    fi

    # 許可されたエージェント名のホワイトリスト
    local -r allowed_agents=("planner" "builder" "none")
    local allowed_agent
    for allowed_agent in "${allowed_agents[@]}"; do
        if [[ "$agent_name" == "$allowed_agent" ]]; then
            _debug "Agent name validated: $agent_name"
            return 0
        fi
    done

    _error "Unauthorized agent name: $agent_name"
    return 1
}

# sanitize_path - パスの安全性を検証し、危険な文字列を除去
# 引数: path - 検証するパス
# 戻り値: 0=有効, 1=無効
# 出力: サニタイズされたパス
secure_sanitize_path() {
    local path="${1:-}"

    # 空文字チェック
    if [[ -z "$path" ]]; then
        _error "Empty path provided"
        return 1
    fi

    # パス長制限（最大4096文字）
    if [[ ${#path} -gt 4096 ]]; then
        _error "Path too long: ${#path} chars (max: 4096)"
        return 1
    fi

    # 危険なパターンをチェック
    local dangerous_patterns=(
        "../"          # ディレクトリトラバーサル
        "..\\\\"
        "~/.ssh"        # SSHキー
        "/etc/"         # システム設定
        "/proc/"        # プロセス情報
        "/dev/"         # デバイスファイル
        "\\x00"         # ヌルバイト
        ";"             # コマンド区切り
        "&"             # バックグラウンド実行
        "|"             # パイプ
        "\`"            # コマンド置換
        "\$("           # コマンド置換
    )

    local pattern
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$path" == *"$pattern"* ]]; then
            _error "Dangerous pattern detected in path: $pattern"
            return 1
        fi
    done

    # プロジェクトディレクトリ内に制限
    local -r safe_base="${PROJECT_ROOT}/.claude"
    local normalized_path
    normalized_path=$(readlink -f "$path" 2>/dev/null) || normalized_path="$path"

    if [[ "$normalized_path" != "$safe_base"* ]]; then
        _error "Path outside safe directory: $normalized_path"
        return 1
    fi

    echo "$normalized_path"
    return 0
}

# sanitize_json_input - JSON入力のサニタイズ
# 引数: json_input - サニタイズするJSON
# 戻り値: 0=有効, 1=無効
# 出力: サニタイズされたJSON
secure_sanitize_json_input() {
    local json_input="${1:-}"

    # 空文字チェック
    if [[ -z "$json_input" ]]; then
        echo "{}"
        return 0
    fi

    # サイズ制限（最大1MB）
    if [[ ${#json_input} -gt 1048576 ]]; then
        _error "JSON input too large: ${#json_input} bytes (max: 1MB)"
        return 1
    fi

    # 危険な文字列をチェック
    local dangerous_json_patterns=(
        "</script>"     # XSS攻撃
        "javascript:"   # JavaScript実行
        "eval("         # コード実行
        "system("       # システムコール
        "exec("         # コマンド実行
        "\\x00"         # ヌルバイト
        "\\u0000"       # ヌルバイト（Unicode）
    )

    local pattern
    for pattern in "${dangerous_json_patterns[@]}"; do
        if [[ "$json_input" == *"$pattern"* ]]; then
            _error "Dangerous pattern in JSON: $pattern"
            return 1
        fi
    done

    # JSON形式の基本的な検証
    if command -v jq >/dev/null 2>&1; then
        if ! echo "$json_input" | jq . >/dev/null 2>&1; then
            _error "Invalid JSON format"
            return 1
        fi
    fi

    # プリント可能文字とホワイトスペースのみ許可
    if [[ ! "$json_input" =~ ^[[:print:][:space:]]*$ ]]; then
        _error "Non-printable characters in JSON input"
        return 1
    fi

    echo "$json_input"
    return 0
}

# secure_command_execution - 安全なコマンド実行
# 引数: command, args...
# 戻り値: コマンドの戻り値
secure_command_execution() {
    local -r command="${1:-}"
    shift
    local -r args=("$@")

    if [[ -z "$command" ]]; then
        _error "Empty command provided"
        return 1
    fi

    # 許可されたコマンドのホワイトリスト
    local -r allowed_commands=("jq" "grep" "sed" "awk" "wc" "head" "tail" "cat" "mkdir" "touch" "mv" "cp" "rm" "date" "stat")

    local allowed_cmd
    local command_found=false
    for allowed_cmd in "${allowed_commands[@]}"; do
        if [[ "$command" == "$allowed_cmd" ]]; then
            command_found=true
            break
        fi
    done

    if [[ "$command_found" != "true" ]]; then
        _error "Command not allowed: $command"
        return 1
    fi

    # コマンドの存在確認
    if ! command -v "$command" >/dev/null 2>&1; then
        _error "Command not found: $command"
        return 1
    fi

    # 安全に実行
    "$command" "${args[@]}"
}

# validate_file_size - ファイルサイズの検証
# 引数: file_path, max_size_bytes
# 戻り値: 0=有効, 1=無効
validate_file_size() {
    local -r file_path="${1:-}"
    local -r max_size="${2:-1048576}"  # デフォルト1MB

    if [[ ! -f "$file_path" ]]; then
        _error "File not found: $file_path"
        return 1
    fi

    local file_size
    file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo 0)

    if [[ $file_size -gt $max_size ]]; then
        _error "File too large: $file_size bytes (max: $max_size)"
        return 1
    fi

    _debug "File size validated: $file_size bytes"
    return 0
}

# ===== 公開関数 =====

# init_hooks_system - Hooksシステムの初期化と必要なディレクトリの作成
# 戻り値: 0=成功, 1=失敗
init_hooks_system() {
    _debug "Initializing hooks system in $PROJECT_ROOT"

    # プロジェクトルートへの書き込み権限を確認
    if [[ ! -w "$PROJECT_ROOT" ]]; then
        _error "No write permission to project root: $PROJECT_ROOT"
        return 1
    fi

    # 必要なディレクトリを作成（最適化されたバッチ処理）
    local dirs=("$LOG_DIR" "$AGENTS_DIR" "$MEMORY_DIR")

    # 一度にmkdirで全て作成し、個別にエラーチェック
    if ! mkdir -p "${dirs[@]}" 2>/dev/null; then
        # 個別にチェックして詳細なエラー情報を提供
        for dir in "${dirs[@]}"; do
            if [[ ! -d "$dir" ]] && ! mkdir -p "$dir" 2>/dev/null; then
                _error "Failed to create directory: $dir"
                return 1
            fi
        done
    fi

    # デバッグ情報のログ
    for dir in "${dirs[@]}"; do
        _debug "Ensured directory exists: $dir"
    done

    _debug "Hooks system initialized successfully"
    return 0
}

# get_agent_info - 現在のエージェント情報を取得
# 入力: JSON (標準入力から)
# 出力: "source:agent_name" 形式の文字列
# 戻り値: 常に0 (エラーでもデフォルト値を返す)
get_agent_info() {
    local json_input=""
    local agent=""
    local source=""

    # 標準入力からJSONを読み取り
    if ! [[ -t 0 ]]; then
        json_input=$(cat)
        _debug "Read JSON input: ${json_input:0:100}..."  # 最初の100文字のみログ
    fi

    # Step 1: promptフィールドからエージェントを検出
    if [[ -n "$json_input" ]]; then
        # jqが使える場合
        if command -v jq >/dev/null 2>&1; then
            local prompt
            prompt=$(echo "$json_input" | jq -r '.prompt // ""' 2>/dev/null) || prompt=""
            if [[ "$prompt" =~ /agent:([a-z]+) ]]; then
                echo "prompt:${BASH_REMATCH[1]}"
                _debug "Found agent from prompt: ${BASH_REMATCH[1]}"
                return 0
            fi
        else
            # jqがない場合の簡易パース（sedとgrepを使用）
            local prompt
            # 入力をサニタイズしてコマンドインジェクションを防ぐ
            if [[ "$json_input" =~ ^[[:print:][:space:]]*$ ]] && [[ ${#json_input} -lt 10000 ]]; then
                prompt=$(printf '%s' "$json_input" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null) || prompt=""
            else
                prompt=""
            fi
            if [[ "$prompt" =~ /agent:([a-z]+) ]]; then
                echo "prompt:${BASH_REMATCH[1]}"
                _debug "Found agent from prompt (no jq): ${BASH_REMATCH[1]}"
                return 0
            fi
        fi
    fi

    # Step 2: active.jsonファイルから読み取り
    local active_file="$AGENTS_DIR/active.json"
    if [[ -f "$active_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            agent=$(jq -r '.current_agent // ""' "$active_file" 2>/dev/null) || agent=""
            if [[ -n "$agent" && "$agent" != "unknown" ]]; then
                echo "file:$agent"
                _debug "Found agent from active.json: $agent"
                return 0
            fi
        fi
    fi

    # Step 3: レガシーactive.mdファイルのサポート
    local legacy_file="$AGENTS_DIR/active.md"
    if [[ -f "$legacy_file" ]]; then
        agent=$(grep "^## Current Agent:" "$legacy_file" 2>/dev/null | awk '{print $4}') || agent=""
        if [[ -n "$agent" ]]; then
            echo "legacy:$agent"
            _debug "Found agent from legacy active.md: $agent"
            return 0
        fi
    fi

    # デフォルト値
    echo "unknown:none"
    _debug "No agent found, returning default"
    return 0
}

# generate_json_response - フック用のJSONレスポンスを生成
# 引数: continue_val, message, context, suppress_output
# 出力: 整形されたJSON
# 戻り値: 常に0
generate_json_response() {
    local continue_val="${1:-true}"
    local message="${2:-}"
    local context="${3:-}"
    local suppress="${4:-false}"

    # 引数の妥当性チェック（強化）
    [[ "$continue_val" =~ ^(true|false)$ ]] || continue_val="true"
    [[ "$suppress" =~ ^(true|false)$ ]] || suppress="false"

    # メッセージとコンテキストのサイズ制限
    if [[ ${#message} -gt 10000 ]]; then
        message="${message:0:9997}..."
    fi
    if [[ ${#context} -gt 5000 ]]; then
        context="${context:0:4997}..."
    fi

    # JSON文字列のエスケープ処理を改善
    # バックスラッシュ、ダブルクォート、改行、タブをエスケープ
    message="${message//\\/\\\\}"  # バックスラッシュ
    message="${message//\"/\\\"}"  # ダブルクォート
    message="${message//$'\n'/\\n}"  # 改行
    message="${message//$'\t'/\\t}"  # タブ
    message="${message//$'\r'/\\r}"  # キャリッジリターン

    context="${context//\\/\\\\}"
    context="${context//\"/\\\"}"
    context="${context//$'\n'/\\n}"
    context="${context//$'\t'/\\t}"
    context="${context//$'\r'/\\r}"

    # 整形されたJSONを出力
    cat <<EOF
{
  "continue": $continue_val,
  "message": "$message",
  "context": "$context",
  "suppressOutput": $suppress
}
EOF

    _debug "Generated JSON response: continue=$continue_val, message_length=${#message}"
    return 0
}

# log_message - 構造化ログメッセージを記録
# 引数: level, message, [log_file]
# 出力: ログファイルへの書き込み（ERRORレベルはstderrにも出力）
# 戻り値: 0=成功, 1=失敗
log_message() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local log_file="${3:-${LOG_DIR}/hooks.log}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S') || timestamp="$(date)"

    # 入力検証とサニタイズ
    if [[ -z "$message" ]]; then
        return 1  # 空のメッセージはログしない
    fi

    # メッセージサイズ制限
    if [[ ${#message} -gt 1000 ]]; then
        message="${message:0:997}..."
    fi

    # ログレベルの妥当性チェック
    case "$level" in
        DEBUG|INFO|WARN|WARNING|ERROR|CRITICAL)
            ;;
        *)
            level="INFO"
            ;;
    esac

    # ログファイルパスの検証
    if [[ ! "$log_file" =~ ^/ ]]; then
        log_file="${LOG_DIR}/hooks.log"  # 相対パスの場合はデフォルトにフォールバック
    fi

    # ログディレクトリを作成（必要に応じて）
    local log_dir
    log_dir=$(dirname "$log_file")
    if [[ ! -d "$log_dir" ]]; then
        if ! mkdir -p "$log_dir" 2>/dev/null; then
            _error "Failed to create log directory: $log_dir"
            return 1
        fi
    fi

    # ログメッセージをフォーマット
    local formatted_message="[$timestamp] [$level] $message"

    # ファイルに書き込み（シンプルで安全な追記）
    # flockが使える環境ではそれを使用、そうでなければ単純な追記
    if command -v flock >/dev/null 2>&1; then
        # flockで排他制御
        (
            flock -x 200
            printf '%s\n' "$formatted_message" >> "$log_file"
        ) 200>"${log_file}.lock" 2>/dev/null
        local write_result=$?
        rm -f "${log_file}.lock"
        if [[ $write_result -ne 0 ]]; then
            _error "Failed to write to log file: $log_file"
            return 1
        fi
    else
        # シンプルな追記（テスト環境用）
        if ! printf '%s\n' "$formatted_message" >> "$log_file" 2>/dev/null; then
            _error "Failed to write to log file: $log_file"
            return 1
        fi
    fi

    # ERRORレベル以上はstderrにも出力
    if [[ "$level" == "ERROR" || "$level" == "CRITICAL" ]]; then
        echo "$formatted_message" >&2
    fi

    _debug "Logged message: level=$level, file=$log_file"
    return 0
}

# ===== バージョン情報 =====
hook_common_version() {
    echo "Claude Code Hooks Common Library v$HOOKS_VERSION"
    return 0
}
