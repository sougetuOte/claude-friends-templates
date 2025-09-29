#!/bin/bash

# =============================================================================
# Shared Utilities for Claude Friends Templates
# 共通ユーティリティ関数ライブラリ
# =============================================================================

# Global variables
CLAUDE_LOG_DIR="${HOME}/.claude"
DEFAULT_LOG_FILE="${CLAUDE_LOG_DIR}/system.log"

# =============================================================================
# Logging Functions
# =============================================================================

# Initialize logging directory
init_logging() {
    local log_file="${1:-$DEFAULT_LOG_FILE}"
    local log_dir
    log_dir=$(dirname "$log_file")

    mkdir -p "$log_dir"
    touch "$log_file"
}

# Generate standardized timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get ISO timestamp for file naming
get_iso_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Standardized logging functions
log_debug() {
    local log_file="${CLAUDE_LOG_FILE:-$DEFAULT_LOG_FILE}"
    local timestamp
    timestamp=$(get_timestamp)

    if [[ "${CLAUDE_DEBUG:-false}" == "true" ]]; then
        echo "[DEBUG] $timestamp $*" >&2
        echo "[DEBUG] $timestamp $*" >> "$log_file"
    fi
}

log_info() {
    local log_file="${CLAUDE_LOG_FILE:-$DEFAULT_LOG_FILE}"
    local timestamp
    timestamp=$(get_timestamp)

    echo "[INFO] $timestamp $*" >&2
    echo "[INFO] $timestamp $*" >> "$log_file"
}

log_warn() {
    local log_file="${CLAUDE_LOG_FILE:-$DEFAULT_LOG_FILE}"
    local timestamp
    timestamp=$(get_timestamp)

    echo "[WARN] $timestamp $*" >&2
    echo "[WARN] $timestamp $*" >> "$log_file"
}

log_error() {
    local log_file="${CLAUDE_LOG_FILE:-$DEFAULT_LOG_FILE}"
    local timestamp
    timestamp=$(get_timestamp)

    echo "[ERROR] $timestamp $*" >&2
    echo "[ERROR] $timestamp $*" >> "$log_file"
}

# =============================================================================
# File Operations
# =============================================================================

# Safe file backup
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(get_iso_timestamp)}"

    if [[ -f "$file" ]]; then
        cp "$file" "${file}${backup_suffix}"
        log_info "Backed up $file to ${file}${backup_suffix}"
    fi
}

# Check if file exists and is readable
check_file_readable() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File does not exist: $file"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        log_error "File is not readable: $file"
        return 1
    fi

    return 0
}

# =============================================================================
# Process Management
# =============================================================================

# Check if process is running
is_process_running() {
    local process_name="$1"
    pgrep -f "$process_name" > /dev/null
}

# Wait for process to complete with timeout
wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    local count=0

    while kill -0 "$pid" 2>/dev/null && [[ $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done

    if [[ $count -ge $timeout ]]; then
        log_warn "Process $pid timed out after ${timeout}s"
        return 1
    fi

    return 0
}

# =============================================================================
# Configuration Management
# =============================================================================

# Load configuration from JSON file
load_config() {
    local config_file="$1"
    local key="$2"

    if ! check_file_readable "$config_file"; then
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        jq -r "$key // empty" "$config_file"
    else
        log_warn "jq not found, cannot parse JSON config"
        return 1
    fi
}

# =============================================================================
# Agent Management
# =============================================================================

# Extract agent from prompt pattern
extract_agent() {
    local prompt="$1"

    if [[ "$prompt" =~ /agent:([a-zA-Z]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    else
        return 1
    fi
}

# Validate agent name
is_valid_agent() {
    local agent="$1"
    local valid_agents=("first" "planner" "builder")

    for valid_agent in "${valid_agents[@]}"; do
        if [[ "$agent" == "$valid_agent" ]]; then
            return 0
        fi
    done

    return 1
}

# =============================================================================
# Initialization
# =============================================================================

# Initialize shared utilities
init_shared_utils() {
    init_logging
    log_debug "Shared utilities initialized"
}

# Call initialization if script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_shared_utils
fi
