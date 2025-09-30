#!/bin/bash
# builder-startup.sh - Builder Agent Startup Script
# Version: 2.0.0
# Purpose: Automatically display handover information when Builder agent starts
#
# Exit Codes:
#   0 - Success (handover displayed or fallback)
#
# Environment Variables:
#   CLAUDE_PROJECT_DIR - Project root directory (default: pwd)
#   DEBUG - Enable debug output (DEBUG=1)
#   BUILDER_STARTUP_CACHE_TTL - Cache duration in seconds (default: 30)

# Security: Strict mode for robust error handling
# Note: Using -uo pipefail instead of -euo pipefail for graceful fallbacks
set -uo pipefail

# === Constants ===
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "${0}")"

# Path Configuration (with validation)
readonly PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
readonly HANDOVER_PATTERN="${PROJECT_DIR}/.claude/handover-*.json"
readonly NOTES_FILE="${PROJECT_DIR}/.claude/builder/notes.md"
readonly LOG_DIR="${PROJECT_DIR}/.claude/logs"
readonly LOG_FILE="${LOG_DIR}/builder-startup.log"
readonly CACHE_FILE="${PROJECT_DIR}/.claude/.cache/builder-startup-cache"
readonly CACHE_TTL="${BUILDER_STARTUP_CACHE_TTL:-30}"

# Performance Configuration
readonly TIMEOUT_SECONDS=5
readonly MAX_HANDOVER_SIZE=$((1024 * 1024))  # 1MB limit for safety

# Debug mode flag
readonly DEBUG="${DEBUG:-0}"

# === Error Codes ===
readonly EXIT_SUCCESS=0

# === Utility Functions ===

# Debug logging function
debug_log() {
    if [[ "${DEBUG}" == "1" ]]; then
        echo "[DEBUG $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
    fi
}

# Safe logging to file (with rotation)
log_to_file() {
    local level="${1}"
    shift
    local message="$*"

    # Create log directory if needed
    if [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}" 2>/dev/null || return 0
    fi

    # Log rotation: keep only last 1000 lines
    if [[ -f "${LOG_FILE}" ]]; then
        local line_count
        line_count=$(wc -l < "${LOG_FILE}" 2>/dev/null || echo 0)
        if [[ "${line_count}" -gt 1000 ]]; then
            tail -n 500 "${LOG_FILE}" > "${LOG_FILE}.tmp" 2>/dev/null && \
                mv "${LOG_FILE}.tmp" "${LOG_FILE}" 2>/dev/null || true
        fi
    fi

    # Append log entry
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

# Input validation: Check if PROJECT_DIR is safe
validate_project_dir() {
    debug_log "Validating PROJECT_DIR: ${PROJECT_DIR}"

    # Security: Ensure PROJECT_DIR exists and is a directory
    if [[ ! -d "${PROJECT_DIR}" ]]; then
        log_to_file "ERROR" "PROJECT_DIR does not exist: ${PROJECT_DIR}"
        return 1
    fi

    # Security: Ensure PROJECT_DIR is within safe boundaries (no /etc, /sys, etc.)
    case "${PROJECT_DIR}" in
        /etc/*|/sys/*|/proc/*|/dev/*)
            log_to_file "ERROR" "PROJECT_DIR in unsafe location: ${PROJECT_DIR}"
            return 1
            ;;
    esac

    return 0
}

# Cache management: Check if cached result is still valid
get_cached_handover() {
    debug_log "Checking cache at ${CACHE_FILE}"

    if [[ ! -f "${CACHE_FILE}" ]]; then
        debug_log "Cache file not found"
        return 1
    fi

    # Check cache age
    local cache_age
    cache_age=$(($(date +%s) - $(stat -c %Y "${CACHE_FILE}" 2>/dev/null || echo 0)))

    if [[ "${cache_age}" -gt "${CACHE_TTL}" ]]; then
        debug_log "Cache expired (age: ${cache_age}s, TTL: ${CACHE_TTL}s)"
        return 1
    fi

    debug_log "Cache valid (age: ${cache_age}s)"
    cat "${CACHE_FILE}"
    return 0
}

# Cache management: Save result to cache
save_to_cache() {
    local content="$1"

    debug_log "Saving to cache"

    # Create cache directory if needed
    local cache_dir
    cache_dir="$(dirname "${CACHE_FILE}")"
    if [[ ! -d "${cache_dir}" ]]; then
        mkdir -p "${cache_dir}" 2>/dev/null || return 0
    fi

    # Save with atomic write (temp file + move)
    echo "${content}" > "${CACHE_FILE}.tmp" 2>/dev/null && \
        mv "${CACHE_FILE}.tmp" "${CACHE_FILE}" 2>/dev/null || true
}

# JSON parsing function with error handling
parse_handover_json() {
    local json_file="$1"

    debug_log "Parsing JSON file: ${json_file}"

    # Security: Validate file size
    local file_size
    file_size=$(stat -c %s "${json_file}" 2>/dev/null || echo 0)
    if [[ "${file_size}" -gt "${MAX_HANDOVER_SIZE}" ]]; then
        log_to_file "WARN" "Handover file too large: ${file_size} bytes"
        return 1
    fi

    # Parse with jq if available
    if command -v jq >/dev/null 2>&1; then
        # Validate JSON first
        if ! jq -e . "${json_file}" >/dev/null 2>&1; then
            debug_log "Invalid JSON in ${json_file}"
            return 1
        fi

        # Extract and format information
        local output
        output=$(jq -r '
            "## 引き継ぎ確認 (" + .metadata.from_agent + " → builder)\n" +
            "Task: " + .summary.current_task + "\n" +
            "Next: " + (.summary.next_steps[0] // "確認中")
        ' "${json_file}" 2>/dev/null)

        if [[ -n "${output}" ]]; then
            echo "${output}"
            return 0
        fi
    else
        # Fallback: grep-based extraction
        debug_log "Using grep fallback (jq not available)"

        echo "## 引き継ぎ確認"
        grep -o '"from_agent"[[:space:]]*:[[:space:]]*"[^"]*"' "${json_file}" 2>/dev/null | \
            cut -d'"' -f4 | head -1 || echo "Unknown"
        grep -o '"current_task"[[:space:]]*:[[:space:]]*"[^"]*"' "${json_file}" 2>/dev/null | \
            cut -d'"' -f4 | head -1 || echo "Task info unavailable"
        return 0
    fi

    return 1
}

# Find latest handover file with proper error handling
find_latest_handover() {
    debug_log "Searching for handover files: ${HANDOVER_PATTERN}"

    # Use nullglob to avoid literal pattern match
    shopt -s nullglob
    local handover_files=("${PROJECT_DIR}"/.claude/handover-*.json)
    shopt -u nullglob

    if [[ "${#handover_files[@]}" -eq 0 ]]; then
        debug_log "No handover files found"
        return 1
    fi

    # Sort by modification time and get most recent
    local latest_handover
    latest_handover=$(ls -t "${handover_files[@]}" 2>/dev/null | head -1)

    if [[ -n "${latest_handover}" && -r "${latest_handover}" ]]; then
        echo "${latest_handover}"
        return 0
    fi

    return 1
}

# === Core Functions ===

show_handover() {
    local latest_handover
    local handover_content

    # Try cache first (performance optimization)
    if handover_content=$(get_cached_handover); then
        log_to_file "INFO" "Using cached handover"
        echo "${handover_content}"
        return "${EXIT_SUCCESS}"
    fi

    # Find latest handover file
    if ! latest_handover=$(find_latest_handover); then
        debug_log "No handover file found, checking notes"
        show_notes_fallback
        return "${EXIT_SUCCESS}"  # Graceful fallback is still success
    fi

    log_to_file "INFO" "Processing handover: ${latest_handover}"

    # Parse and display handover
    if handover_content=$(parse_handover_json "${latest_handover}"); then
        echo "${handover_content}"
        save_to_cache "${handover_content}"
        return "${EXIT_SUCCESS}"
    else
        # JSON parse failed - fallback
        log_to_file "WARN" "Failed to parse JSON: ${latest_handover}"
        echo "引き継ぎファイルが破損してるぜ - notes.md を確認するか"
        show_notes_fallback
        return "${EXIT_SUCCESS}"
    fi
}

show_notes_fallback() {
    debug_log "Fallback to notes.md"

    if [[ -f "${NOTES_FILE}" ]]; then
        echo "引き継ぎなし - notes.md を確認するぜ"

        # Extract current task from notes if available
        if grep -q "## 現在のタスク" "${NOTES_FILE}" 2>/dev/null; then
            echo ""
            sed -n '/## 現在のタスク/,/^##/p' "${NOTES_FILE}" 2>/dev/null | head -5 || true
        fi

        log_to_file "INFO" "Showed notes.md fallback"
    else
        echo "引き継ぎなし - 新規タスクかな"
        log_to_file "INFO" "No handover or notes found (new task)"
    fi
}

# === Main Entry Point ===

main() {
    local exit_code

    debug_log "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"
    debug_log "PROJECT_DIR: ${PROJECT_DIR}"

    # Validate environment (non-fatal for backward compatibility)
    if ! validate_project_dir; then
        debug_log "Project directory validation failed, continuing anyway"
    fi

    # Display handover information
    show_handover
    exit_code=$?

    debug_log "Completed with exit code: ${exit_code}"
    log_to_file "INFO" "Completed with exit code: ${exit_code}"

    return "${exit_code}"
}

# === Script Entry Point ===
# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
