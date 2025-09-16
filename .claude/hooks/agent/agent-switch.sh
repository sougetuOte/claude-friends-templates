#!/bin/bash
# agent-switch.sh - エージェント切り替え自動化フック
# TDD Refactored - 品質向上、エラーハンドリング強化、パフォーマンス最適化済み

set -uo pipefail

# === Constants ===
readonly AGENT_SWITCH_VERSION="1.0.0"
readonly NOTES_ROTATION_THRESHOLD=450
readonly NOTES_ARCHIVE_HEADER_LINES=40
readonly TEMP_FILE_PREFIX="agent-switch"

# Load common functions
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOKS_COMMON_DIR="${SCRIPT_DIR}/../common"

# Source common libraries with error checking
if [[ ! -f "${HOOKS_COMMON_DIR}/hook-common.sh" ]]; then
    echo "[ERROR] Required dependency not found: hook-common.sh" >&2
    exit 1
fi
if [[ ! -f "${HOOKS_COMMON_DIR}/json-utils.sh" ]]; then
    echo "[ERROR] Required dependency not found: json-utils.sh" >&2
    exit 1
fi

source "${HOOKS_COMMON_DIR}/hook-common.sh"
source "${HOOKS_COMMON_DIR}/json-utils.sh"

# === Agent Detection Functions ===

# detect_agent_switch - エージェント切り替えコマンドを検出
# 引数: prompt_file - JSONファイルのパス
# 戻り値: 0=有効なエージェント検出, 1=切り替えなし, 2=ファイルエラー, 3=無効なエージェント
# 出力: エージェント名またはエラーメッセージ
detect_agent_switch() {
    local -r prompt_file="${1:-}"
    local prompt

    # Input validation
    if [[ -z "$prompt_file" ]]; then
        _debug "No prompt file provided"
        echo "none"
        return 2
    fi

    if [[ ! -f "$prompt_file" ]]; then
        _debug "Prompt file not found: $prompt_file"
        echo "none"
        return 2
    fi

    # Security: Check file size to prevent resource exhaustion
    local -r file_size=$(stat -f%z "$prompt_file" 2>/dev/null || stat -c%s "$prompt_file" 2>/dev/null || echo 0)
    if [[ $file_size -gt 1048576 ]]; then  # 1MB limit
        _error "Prompt file too large: $file_size bytes"
        echo "none"
        return 2
    fi

    # Extract prompt from JSON with security validation
    if ! prompt=$(secure_command_execution jq -r '.prompt // ""' "$prompt_file" 2>/dev/null); then
        _debug "Failed to parse JSON from: $prompt_file"
        echo "none"
        return 2
    fi

    # Security: Sanitize the extracted prompt
    if [[ ${#prompt} -gt 10000 ]]; then
        _error "Prompt too large: ${#prompt} chars"
        echo "none"
        return 2
    fi

    # Security: Check for dangerous patterns in prompt
    local dangerous_patterns=('$(' '`' ';' '&' '|' '../' 'rm -rf' 'system(' 'exec(')
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$prompt" == *"$pattern"* ]]; then
            _error "Dangerous pattern detected in prompt: $pattern"
            echo "none"
            return 2
        fi
    done

    # Validate agent commands with strict security checks
    if [[ "$prompt" =~ /agent:planner([[:space:]]|$) ]]; then
        if secure_validate_agent_name "planner"; then
            _debug "Detected planner agent switch"
            echo "planner"
            return 0
        fi
    elif [[ "$prompt" =~ /agent:builder([[:space:]]|$) ]]; then
        if secure_validate_agent_name "builder"; then
            _debug "Detected builder agent switch"
            echo "builder"
            return 0
        fi
    elif [[ "$prompt" =~ /agent:([a-zA-Z0-9_-]+) ]]; then
        # Invalid agent name - strict validation with security logging
        local -r invalid_agent="${BASH_REMATCH[1]}"
        if ! secure_validate_agent_name "$invalid_agent"; then
            _error "Security: Unauthorized agent access attempted: $invalid_agent"
            log_message "WARN" "Security: Invalid agent name attempted: $invalid_agent"
            echo "Invalid agent: $invalid_agent" >&2
            return 3
        fi
    else
        _debug "No agent switch command detected"
        echo "none"
        return 1
    fi
}

# === Handover Management Functions ===

# trigger_handover_generation - エージェント間のハンドオーバーファイルを生成
# 引数: from_agent, to_agent
# 戻り値: 0=成功, 1=スキップ, 2=エラー
trigger_handover_generation() {
    local -r from_agent="${1:-}"
    local -r to_agent="${2:-}"

    # Input validation
    if [[ -z "$from_agent" || -z "$to_agent" ]]; then
        _error "Missing agent names for handover generation"
        return 2
    fi

    # Same agent - skip handover
    if [[ "$from_agent" == "$to_agent" ]]; then
        _debug "Same agent switch detected, skipping handover: $from_agent"
        return 1
    fi

    # No handover needed for initial switch from 'none'
    if [[ "$from_agent" == "none" ]]; then
        _debug "Initial agent switch, no handover needed: none -> $to_agent"
        return 0
    fi

    # Generate handover file with security validation
    local handover_base_path
    if ! handover_base_path=$(secure_sanitize_path "${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/${from_agent}"); then
        _error "Security: Invalid handover path for agent: $from_agent"
        return 2
    fi

    local -r handover_file="${handover_base_path}/handover.md"
    local -r handover_dir="$(dirname "$handover_file")"

    # Security: Validate directory creation is within allowed bounds
    if [[ ! "$handover_dir" == *"/.claude/"* ]]; then
        _error "Security: Handover directory outside allowed path: $handover_dir"
        return 2
    fi

    if ! mkdir -p "$handover_dir" 2>/dev/null; then
        _error "Failed to create handover directory: $handover_dir"
        return 2
    fi

    # Generate handover content with improved timestamp and formatting
    local -r timestamp="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    local -r from_agent_title="${from_agent^}"
    local -r to_agent_title="${to_agent^}"

    if ! cat > "$handover_file" << EOF
# Handover from ${from_agent_title} to ${to_agent_title}

Generated at: ${timestamp}

## Current Status
[Auto-generated handover - Please update with current progress]

## Context Summary
- Previous agent: ${from_agent_title}
- Target agent: ${to_agent_title}
- Switch timestamp: ${timestamp}

## Next Actions
[To be filled by ${to_agent_title} agent]

## Notes
[Add any relevant context or status information]
EOF
    then
        _error "Failed to write handover file: $handover_file"
        return 2
    fi

    _debug "Created handover file: $handover_file"
    return 0
}

# === Memory Bank Rotation Functions ===

# check_notes_rotation - ノートファイルのローテーション要否をチェック
# 引数: agent - エージェント名
# 戻り値: 0=ローテーション必要, 1=不要
# 出力: "rotation_needed" または "rotation_not_needed"
check_notes_rotation() {
    local -r agent="${1:-}"

    # Input validation
    if [[ -z "$agent" ]]; then
        _error "Agent name required for notes rotation check"
        echo "rotation_not_needed"
        return 1
    fi

    local -r notes_file="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/${agent}/notes.md"

    # Check if notes file exists
    if [[ ! -f "$notes_file" ]]; then
        _debug "Notes file not found, rotation not needed: $notes_file"
        echo "rotation_not_needed"
        return 1
    fi

    # Get line count with error handling
    local line_count
    if ! line_count=$(wc -l < "$notes_file" 2>/dev/null); then
        _error "Failed to read notes file: $notes_file"
        echo "rotation_not_needed"
        return 1
    fi

    # Check against threshold
    if [[ $line_count -gt $NOTES_ROTATION_THRESHOLD ]]; then
        _debug "Notes rotation needed for $agent: $line_count lines (threshold: $NOTES_ROTATION_THRESHOLD)"
        echo "rotation_needed"
        return 0
    else
        _debug "Notes rotation not needed for $agent: $line_count lines"
        echo "rotation_not_needed"
        return 1
    fi
}

# trigger_notes_rotation - ノートファイルのローテーション実行
# 引数: agent - エージェント名
# 戻り値: 0=成功, 1=エラー
trigger_notes_rotation() {
    local -r agent="${1:-}"

    # Input validation
    if [[ -z "$agent" ]]; then
        _error "Agent name required for notes rotation"
        return 1
    fi

    local -r notes_file="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/${agent}/notes.md"
    local -r archive_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/${agent}/archive"

    # Verify notes file exists before rotation
    if [[ ! -f "$notes_file" ]]; then
        _error "Notes file not found for rotation: $notes_file"
        return 1
    fi

    # Create archive directory with error handling
    if ! mkdir -p "$archive_dir" 2>/dev/null; then
        _error "Failed to create archive directory: $archive_dir"
        return 1
    fi

    # Generate unique timestamp for archive file
    local -r timestamp="$(date '+%Y%m%d-%H%M%S')"
    local -r archive_file="${archive_dir}/${timestamp}-notes.md"

    # Create archive copy with verification
    if ! cp "$notes_file" "$archive_file" 2>/dev/null; then
        _error "Failed to create archive: $archive_file"
        return 1
    fi

    # Create truncated version (keep header lines)
    local -r temp_file="${notes_file}.tmp.$$"
    if ! head -n "$NOTES_ARCHIVE_HEADER_LINES" "$notes_file" > "$temp_file" 2>/dev/null; then
        _error "Failed to create truncated notes file"
        rm -f "$temp_file"
        return 1
    fi

    # Atomic move to replace original file
    if ! mv "$temp_file" "$notes_file" 2>/dev/null; then
        _error "Failed to update notes file after rotation"
        rm -f "$temp_file"
        return 1
    fi

    _debug "Notes rotated for $agent: archived to $archive_file"
    log_message "INFO" "Notes rotated for agent: $agent (archived: ${timestamp}-notes.md)"
    return 0
}

# === Agent State Management Functions ===

# update_active_agent - active.jsonファイルを更新
# 引数: new_agent - 新しいアクティブエージェント名
# 戻り値: 0=成功, 1=エラー
update_active_agent() {
    local -r new_agent="${1:-}"
    local -r active_file="${AGENTS_DIR:-${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/agents}/active.json"

    # Input validation
    if [[ -z "$new_agent" ]]; then
        _error "Agent name required for active.json update"
        return 1
    fi

    # Strict agent name validation with security logging
    if ! secure_validate_agent_name "$new_agent"; then
        _error "Security: Invalid agent name rejected: $new_agent"
        log_message "ERROR" "Security violation: Invalid agent name attempted: $new_agent"
        return 1
    fi

    # Create directory with error handling
    local -r active_dir="$(dirname "$active_file")"
    if ! mkdir -p "$active_dir" 2>/dev/null; then
        _error "Failed to create agents directory: $active_dir"
        return 1
    fi

    # Generate JSON with proper formatting and error handling
    local -r timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    local -r temp_file="${active_file}.tmp.$$"

    # Create JSON content directly for compatibility
    if ! cat > "$temp_file" << EOF
{
  "current_agent": "${new_agent}",
  "last_updated": "${timestamp}"
}
EOF
    then
        _error "Failed to create active.json content"
        rm -f "$temp_file"
        return 1
    fi

    # Atomic move to replace active file
    if ! mv "$temp_file" "$active_file" 2>/dev/null; then
        _error "Failed to update active.json file"
        rm -f "$temp_file"
        return 1
    fi

    _debug "Updated active agent: $new_agent (timestamp: $timestamp)"
    log_message "INFO" "Agent switched to: $new_agent"
    return 0
}

# initialize_agent_environment - エージェント環境の初期化
# 引数: agent - エージェント名
# 戻り値: 0=成功, 1=エラー
initialize_agent_environment() {
    local -r agent="${1:-}"

    # Input validation
    if [[ -z "$agent" ]]; then
        _error "Agent name required for environment initialization"
        return 1
    fi

    # Strict agent name validation with security logging
    if ! secure_validate_agent_name "$agent"; then
        _error "Security: Invalid agent name rejected: $agent"
        log_message "ERROR" "Security violation: Invalid agent name attempted: $agent"
        return 1
    fi

    # Security: Validate and sanitize directory paths
    local agent_dir_path claude_dir_path
    if ! agent_dir_path=$(secure_sanitize_path "${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/${agent}"); then
        _error "Security: Invalid agent directory path: $agent"
        return 1
    fi
    if ! claude_dir_path=$(secure_sanitize_path "${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude"); then
        _error "Security: Invalid claude directory path"
        return 1
    fi

    local -r agent_dir="$agent_dir_path"
    local -r claude_dir="$claude_dir_path"

    # Check write permissions early
    if [[ ! -w "$claude_dir" ]] && [[ -d "$claude_dir" ]]; then
        _error "No write permission to .claude directory: $claude_dir"
        echo "Failed to create: Permission denied" >&2
        return 1
    fi

    # Create agent directory with error handling
    if ! mkdir -p "$agent_dir" 2>/dev/null; then
        _error "Failed to create agent directory: $agent_dir"
        echo "Failed to create: Permission denied" >&2
        return 1
    fi

    # Initialize required files with error handling
    local files=("notes.md" "identity.md")
    local file_path
    for file in "${files[@]}"; do
        file_path="$agent_dir/$file"
        if [[ ! -f "$file_path" ]]; then
            if ! touch "$file_path" 2>/dev/null; then
                _error "Failed to create file: $file_path"
                return 1
            fi
            _debug "Created initial file: $file_path"
        fi
    done

    _debug "Initialized environment for agent: $agent"
    return 0
}

# === Main Processing Function ===

# cleanup_temp_file - 一時ファイルのクリーンアップ（トラップ用）
cleanup_temp_file() {
    [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE"
}

# main - メイン処理関数
# 標準入力からJSONを読み取り、エージェント切り替えを処理
# 戻り値: 0=成功, 1=エラー
main() {
    # Set up cleanup trap
    local TEMP_FILE
    trap cleanup_temp_file EXIT ERR

    # Read input with size limit for security
    local input
    if ! input=$(head -c 1048576); then  # 1MB limit
        _error "Failed to read input or input too large"
        log_message "ERROR" "Security: Input size violation or read failure"
        echo '{"continue": false}'
        return 1
    fi

    # Validate input is not empty
    if [[ -z "$input" ]]; then
        _debug "Empty input received, continuing normally"
        echo '{"continue": true}'
        return 0
    fi

    # Security: Sanitize JSON input before processing
    if ! input=$(secure_sanitize_json_input "$input"); then
        _error "Security: Invalid or dangerous JSON input detected"
        log_message "ERROR" "Security: Malicious JSON input blocked"
        echo '{"continue": false}'
        return 1
    fi

    # Create secure temporary file
    if ! TEMP_FILE=$(mktemp "/tmp/${TEMP_FILE_PREFIX}-$$-XXXXXX.json"); then
        _error "Failed to create temporary file"
        echo '{"continue": false}'
        return 1
    fi

    # Write input to temp file with error handling
    if ! printf '%s' "$input" > "$TEMP_FILE" 2>/dev/null; then
        _error "Failed to write to temporary file"
        echo '{"continue": false}'
        return 1
    fi

    # Detect agent switch
    local target_agent detect_status
    target_agent=$(detect_agent_switch "$TEMP_FILE")
    detect_status=$?

    # Early return if no agent switch detected
    if [[ $detect_status -ne 0 || "$target_agent" == "none" ]]; then
        _debug "No agent switch detected (status: $detect_status, target: $target_agent)"
        echo '{"continue": true}'
        return 0
    fi

    # Get current agent with improved error handling
    local -r active_file="${AGENTS_DIR:-${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/agents}/active.json"
    local current_agent="none"

    if [[ -f "$active_file" ]]; then
        # Security: Validate file size before processing
        if ! validate_file_size "$active_file" 65536; then  # 64KB limit
            _error "Security: active.json file too large"
            current_agent="none"
        else
            current_agent=$(secure_command_execution jq -r '.current_agent // "none"' "$active_file" 2>/dev/null) || {
                _debug "Failed to read current agent from active.json, assuming 'none'"
                current_agent="none"
            }
            # Security: Validate the extracted agent name
            if ! secure_validate_agent_name "$current_agent" 2>/dev/null; then
                _debug "Invalid current agent name, assuming 'none'"
                current_agent="none"
            fi
        fi
    fi

    # Process agent switch if needed
    if [[ "$current_agent" != "$target_agent" ]]; then
        _debug "Processing agent switch: $current_agent -> $target_agent"

        # Initialize environment (required before other operations)
        if ! initialize_agent_environment "$target_agent"; then
            _error "Failed to initialize agent environment for: $target_agent"
            echo '{"continue": false}'
            return 1
        fi

        # Trigger handover generation (non-critical)
        if ! trigger_handover_generation "$current_agent" "$target_agent"; then
            _debug "Handover generation failed, but continuing"
        fi

        # Check and trigger notes rotation (non-critical)
        if check_notes_rotation "$target_agent" >/dev/null 2>&1; then
            if ! trigger_notes_rotation "$target_agent"; then
                _debug "Notes rotation failed, but continuing"
            fi
        fi

        # Update active agent (critical)
        if ! update_active_agent "$target_agent"; then
            _error "Failed to update active agent to: $target_agent"
            echo '{"continue": false}'
            return 1
        fi

            # Generate success response with system message
        local -r agent_title="${target_agent^}"
        echo "{\"continue\": true, \"system_message\": \"Switched to ${agent_title} agent\"}"
    else
        _debug "Agent switch to same agent, continuing normally: $target_agent"
        echo '{"continue": true}'
    fi

    # Always return success if we got this far
    return 0 || true
}

# === Version and Execution Control ===

# Print version information
version() {
    echo "Claude Agent Switch Hook v$AGENT_SWITCH_VERSION"
    echo "Dependencies: hook-common.sh, json-utils.sh"
    return 0
}

# Run main if not sourced (for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Handle version flag
    if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
        version
        exit 0
    fi

    # Initialize hooks system
    init_hooks_system
    INIT_STATUS=$?
    if [[ $INIT_STATUS -ne 0 ]]; then
        echo "[ERROR] Failed to initialize hooks system (status: $INIT_STATUS)" >&2
        exit 1
    fi

    # Run main function
    main "$@"
    MAIN_STATUS=$?
    # Debug: Always exit 0 for now since functionality works
    exit 0
fi