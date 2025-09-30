#!/bin/bash
# handover-gen.sh - handover-generator.pyラッパースクリプト
# TDD Refactored - エラーハンドリング、ログ記録、タイムアウト処理強化
# 圧縮・状態同期機能との統合

set -uo pipefail

# === Constants ===
readonly HANDOVER_GEN_VERSION="1.0.0"
readonly DEFAULT_TIMEOUT=30
readonly MAX_CONTEXT_LINES=1000
readonly RETRY_MAX=2
readonly RETRY_DELAY=2

# Determine script directory with symlink resolution
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
readonly SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# Paths - Resolve to absolute paths
readonly CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
HANDOVER_GENERATOR_PY_RELATIVE="${HANDOVER_GENERATOR_PY:-${SCRIPT_DIR}/../../scripts/handover-generator.py}"
# Resolve relative path to absolute
if [[ -f "$HANDOVER_GENERATOR_PY_RELATIVE" ]]; then
    HANDOVER_GENERATOR_PY="$(cd "$(dirname "$HANDOVER_GENERATOR_PY_RELATIVE")" && pwd)/$(basename "$HANDOVER_GENERATOR_PY_RELATIVE")"
else
    HANDOVER_GENERATOR_PY="$HANDOVER_GENERATOR_PY_RELATIVE"
fi
readonly HANDOVER_GENERATOR_PY
readonly LOG_FILE="${CLAUDE_PROJECT_DIR}/.claude/logs/handover-gen.log"

# === Utility Functions ===

_debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    _log_to_file "ERROR" "$*"
}

_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    _log_to_file "INFO" "$*"
}

_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    _log_to_file "WARN" "$*"
}

_log_to_file() {
    local level="$1"
    shift
    local message="$*"

    # Ensure log directory exists
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || return
    fi

    # Write log entry
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true
}

# === Validation Functions ===

validate_agent_name() {
    local agent="$1"

    # Security: Only allow alphanumeric and hyphen/underscore
    if [[ ! "$agent" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        _error "Invalid agent name: $agent (only alphanumeric, hyphen, underscore allowed)"
        return 1
    fi

    # Length check
    if [[ ${#agent} -gt 50 ]]; then
        _error "Agent name too long: ${#agent} chars (max 50)"
        return 1
    fi

    return 0
}

# === Core Functions ===

# generate_handover - 引き継ぎファイル生成のメイン関数
# 引数: from_agent to_agent
# 戻り値: 0=成功, 1=スキップ, 2=エラー
generate_handover() {
    local -r from_agent="${1:-}"
    local -r to_agent="${2:-}"
    local -r timeout="${HANDOVER_TIMEOUT:-$DEFAULT_TIMEOUT}"
    local retry_count=0

    # === Input Validation ===
    if [[ -z "$from_agent" || -z "$to_agent" ]]; then
        _error "Both from_agent and to_agent are required"
        return 2
    fi

    # Validate agent names
    if ! validate_agent_name "$from_agent"; then
        return 2
    fi
    if ! validate_agent_name "$to_agent"; then
        return 2
    fi

    # Same agent check
    if [[ "$from_agent" == "$to_agent" ]]; then
        _debug "Same agent, skipping handover generation: $from_agent"
        return 1
    fi

    _info "Starting handover generation: $from_agent → $to_agent"

    # === Dependency Check ===
    if [[ ! -f "$HANDOVER_GENERATOR_PY" ]]; then
        _error "handover-generator.py not found: $HANDOVER_GENERATOR_PY"
        return 2
    fi

    # Check Python availability
    if ! command -v python3 >/dev/null 2>&1; then
        _error "python3 not found in PATH"
        return 2
    fi

    # === Prepare Paths ===
    local -r notes_file="${CLAUDE_PROJECT_DIR}/.claude/${from_agent}/notes.md"
    local -r state_file="${CLAUDE_PROJECT_DIR}/.claude/states/${from_agent}/current.json"
    local -r output_file="${CLAUDE_PROJECT_DIR}/.claude/handover-${from_agent}-to-${to_agent}-$(date +%Y-%m-%d).md"

    # === Notes File Check ===
    if [[ ! -f "$notes_file" ]]; then
        _error "Notes file not found: $notes_file"
        return 2
    fi

    # Check read permissions
    if [[ ! -r "$notes_file" ]]; then
        _error "Cannot read notes file (permission denied): $notes_file"
        return 2
    fi

    # === Compression Decision ===
    local line_count
    line_count=$(wc -l < "$notes_file" 2>/dev/null || echo 0)

    local use_compression=0
    if [[ $line_count -gt $MAX_CONTEXT_LINES ]]; then
        _info "Large context detected ($line_count lines > $MAX_CONTEXT_LINES), compression recommended"
        use_compression=1
    else
        _debug "Context size: $line_count lines (compression not needed)"
    fi

    # === Build Command Arguments ===
    local -a cmd_args=(
        "--from-agent" "$from_agent"
        "--to-agent" "$to_agent"
        "--output" "$output_file"
        "--include-provenance"
        "--capture-state"
        "--generate-ai-hints"
    )

    # Extract context from notes
    if [[ -f "$notes_file" ]]; then
        local current_task
        current_task=$(grep -i "current task" "$notes_file" | head -1 | sed 's/.*[:：]//' | xargs 2>/dev/null || echo "")
        if [[ -n "$current_task" ]]; then
            _debug "Extracted current task: $current_task"
            cmd_args+=("--context" "$current_task")
        else
            _debug "No current task found in notes, using default"
            cmd_args+=("--context" "Continue agent work")
        fi
    fi

    # === Execute with Retry Logic ===
    local execution_success=0

    while [[ $retry_count -lt $RETRY_MAX ]]; do
        _debug "Attempt $((retry_count + 1))/$RETRY_MAX: Executing handover generation"
        _debug "Command: python3 '$HANDOVER_GENERATOR_PY' ${cmd_args[*]}"

        local start_time
        start_time=$(date +%s)

        # Execute with timeout if available
        local exit_code=0
        if command -v timeout >/dev/null 2>&1; then
            timeout "$timeout" python3 "$HANDOVER_GENERATOR_PY" "${cmd_args[@]}" 2>&1 | tee -a "$LOG_FILE" 2>/dev/null
            exit_code=${PIPESTATUS[0]}
        else
            python3 "$HANDOVER_GENERATOR_PY" "${cmd_args[@]}" 2>&1 | tee -a "$LOG_FILE" 2>/dev/null
            exit_code=${PIPESTATUS[0]}
        fi

        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [[ $exit_code -eq 0 ]]; then
            _debug "Handover generation successful (duration: ${duration}s)"
            execution_success=1
            break
        elif [[ $exit_code -eq 124 ]]; then
            _error "Handover generation timed out after ${timeout}s (attempt $((retry_count + 1)))"
        else
            _error "Handover generation failed with exit code $exit_code (attempt $((retry_count + 1)))"
        fi

        retry_count=$((retry_count + 1))

        if [[ $retry_count -lt $RETRY_MAX ]]; then
            _warn "Retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi
    done

    # === Verify Results ===
    if [[ $execution_success -ne 1 ]]; then
        _error "Handover generation failed after $RETRY_MAX attempts"
        return 2
    fi

    # Verify output file was created
    if [[ ! -f "$output_file" ]]; then
        _error "Handover file was not created: $output_file"
        return 2
    fi

    # Check output file size
    local file_size
    file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo 0)
    if [[ $file_size -eq 0 ]]; then
        _error "Handover file is empty: $output_file"
        return 2
    fi

    # Validate JSON structure
    if ! python3 -m json.tool "$output_file" >/dev/null 2>&1; then
        _warn "Handover file may have invalid JSON structure (continuing anyway)"
    fi

    _info "Handover file generated successfully: $output_file (size: ${file_size} bytes)"
    return 0
}

# === Version and Main Entry Point ===

version() {
    echo "Handover Generator Wrapper v$HANDOVER_GEN_VERSION"
    echo "Features: Retry logic, timeout handling, comprehensive logging"
    echo "Dependencies: python3, handover-generator.py"
}

# If sourced, export functions for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f generate_handover
    export -f validate_agent_name
else
    # Direct execution
    if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
        version
        exit 0
    fi

    # Parse command line arguments
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <from_agent> <to_agent>" >&2
        echo "Environment variables:" >&2
        echo "  HANDOVER_TIMEOUT - Timeout in seconds (default: 30)" >&2
        echo "  DEBUG - Enable debug output (1/0)" >&2
        exit 1
    fi

    generate_handover "$1" "$2"
    exit $?
fi
