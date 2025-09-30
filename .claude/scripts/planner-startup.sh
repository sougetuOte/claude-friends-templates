#!/bin/bash
# planner-startup.sh - Planner Agent Startup Script
# Version: 2.1.0
# Purpose: Automatically display handover information when Planner agent starts
#          Focuses on strategic planning with feminine polite Japanese tone
#
# Exit Codes:
#   0 - Success (handover displayed or fallback)
#
# Environment Variables:
#   CLAUDE_PROJECT_DIR - Project root directory (default: pwd)
#   DEBUG - Enable debug output (DEBUG=1)
#   PLANNER_STARTUP_CACHE_TTL - Cache duration in seconds (default: 30)

# === Strict Mode ===
# Note: Using -uo pipefail instead of -euo pipefail for graceful fallbacks
set -uo pipefail

# === Constants ===
readonly SCRIPT_VERSION="2.1.0"
readonly SCRIPT_NAME="$(basename "${0}")"
readonly AGENT_NAME="planner"
readonly AGENT_ROLE="strategic planning and design"

# === Path Configuration ===
readonly PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
readonly HANDOVER_PATTERN="${PROJECT_DIR}/.claude/handover-*.json"
readonly NOTES_FILE="${PROJECT_DIR}/.claude/planner/notes.md"
readonly LOG_DIR="${PROJECT_DIR}/.claude/logs"
readonly LOG_FILE="${LOG_DIR}/planner-startup.log"
readonly CACHE_DIR="${PROJECT_DIR}/.claude/.cache"
readonly CACHE_FILE="${CACHE_DIR}/planner-startup-cache"

# === Configuration ===
readonly CACHE_TTL="${PLANNER_STARTUP_CACHE_TTL:-30}"
readonly TIMEOUT_SECONDS=5
readonly MAX_HANDOVER_SIZE=$((1024 * 1024))  # 1MB safety limit
readonly MAX_LOG_LINES=1000
readonly LOG_ROTATION_LINES=500

# === Debug Configuration ===
readonly DEBUG="${DEBUG:-0}"

# === Exit Codes ===
readonly EXIT_SUCCESS=0

# ============================================================================
# Utility Functions
# ============================================================================

# Log debug messages when DEBUG mode is enabled
# Globals:
#   DEBUG - Debug mode flag
# Arguments:
#   $* - Message to log
# Outputs:
#   Debug message to stderr if DEBUG=1
debug_log() {
    if [[ "${DEBUG}" == "1" ]]; then
        echo "[DEBUG $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
    fi
}

# Log messages to file with automatic rotation
# Globals:
#   LOG_DIR, LOG_FILE, MAX_LOG_LINES, LOG_ROTATION_LINES
# Arguments:
#   $1 - Log level (INFO, WARN, ERROR)
#   $@ - Message to log
# Returns:
#   0 - Always succeeds (logs are non-critical)
log_to_file() {
    local level="${1}"
    shift
    local message="$*"

    # Ensure log directory exists
    if [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}" 2>/dev/null || return 0
    fi

    # Rotate log if needed (strategic approach: prevent excessive growth)
    if [[ -f "${LOG_FILE}" ]]; then
        local line_count
        line_count=$(wc -l < "${LOG_FILE}" 2>/dev/null || echo 0)
        if [[ "${line_count}" -gt "${MAX_LOG_LINES}" ]]; then
            tail -n "${LOG_ROTATION_LINES}" "${LOG_FILE}" > "${LOG_FILE}.tmp" 2>/dev/null && \
                mv "${LOG_FILE}.tmp" "${LOG_FILE}" 2>/dev/null || true
        fi
    fi

    # Write log entry
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

# ============================================================================
# Security & Validation Functions
# ============================================================================

# Validate PROJECT_DIR for security and existence
# Globals:
#   PROJECT_DIR
# Returns:
#   0 - Valid directory
#   1 - Invalid or unsafe directory
validate_project_dir() {
    debug_log "Validating PROJECT_DIR: ${PROJECT_DIR}"

    # Security: Ensure directory exists
    if [[ ! -d "${PROJECT_DIR}" ]]; then
        log_to_file "ERROR" "PROJECT_DIR does not exist: ${PROJECT_DIR}"
        return 1
    fi

    # Security: Block dangerous system paths
    case "${PROJECT_DIR}" in
        /etc/*|/sys/*|/proc/*|/dev/*)
            log_to_file "ERROR" "Unsafe PROJECT_DIR location: ${PROJECT_DIR}"
            return 1
            ;;
    esac

    return 0
}

# Validate handover file size for security
# Arguments:
#   $1 - Path to handover file
# Returns:
#   0 - File size is safe
#   1 - File is too large
validate_file_size() {
    local file="${1}"
    local file_size

    file_size=$(stat -c %s "${file}" 2>/dev/null || echo 0)
    if [[ "${file_size}" -gt "${MAX_HANDOVER_SIZE}" ]]; then
        log_to_file "WARN" "Handover file too large: ${file_size} bytes"
        return 1
    fi

    return 0
}

# ============================================================================
# Cache Management Functions
# ============================================================================

# Retrieve cached handover if valid (performance optimization)
# Arguments:
#   $1 - Cache file path
#   $2 - Cache TTL in seconds
# Outputs:
#   Cached content if valid
# Returns:
#   0 - Cache hit and valid
#   1 - Cache miss or expired
get_cached_handover() {
    local cache_file="${1}"
    local cache_ttl="${2}"

    debug_log "Checking cache at ${cache_file}"

    # Check cache existence
    if [[ ! -f "${cache_file}" ]]; then
        debug_log "Cache file not found"
        return 1
    fi

    # Check cache freshness
    local cache_age
    cache_age=$(( $(date +%s) - $(stat -c %Y "${cache_file}" 2>/dev/null || echo 0) ))
    if [[ "${cache_age}" -gt "${cache_ttl}" ]]; then
        debug_log "Cache expired (age: ${cache_age}s, TTL: ${cache_ttl}s)"
        return 1
    fi

    debug_log "Cache hit (age: ${cache_age}s)"
    cat "${cache_file}"
    return 0
}

# Save content to cache atomically (strategic: ensure data integrity)
# Arguments:
#   $1 - Content to cache
#   $2 - Cache file path
# Returns:
#   0 - Successfully cached
#   1 - Cache write failed
save_to_cache() {
    local content="${1}"
    local cache_file="${2}"
    local cache_dir

    # Ensure cache directory exists
    cache_dir="$(dirname "${cache_file}")"
    mkdir -p "${cache_dir}" 2>/dev/null || return 1

    # Atomic write: temp file + move (prevents corruption)
    local temp_file="${cache_file}.tmp"
    echo "${content}" > "${temp_file}" 2>/dev/null && \
        mv "${temp_file}" "${cache_file}" 2>/dev/null
}

# ============================================================================
# Handover Processing Functions
# ============================================================================

# Parse handover JSON file with validation
# Arguments:
#   $1 - Path to handover file
# Outputs:
#   Formatted handover information with feminine polite tone
# Returns:
#   0 - Successfully parsed
#   1 - Parse error or invalid JSON
parse_handover_json() {
    local handover_file="${1}"

    debug_log "Parsing JSON file: ${handover_file}"

    # Security: Validate file size
    if ! validate_file_size "${handover_file}"; then
        echo "引き継ぎファイルが大きすぎますね - notes.md を確認しましょう"
        return 1
    fi

    # Parse with jq if available (preferred method)
    if command -v jq >/dev/null 2>&1; then
        if jq -e . "${handover_file}" >/dev/null 2>&1; then
            # Strategic formatting: clear and professional tone
            jq -r '
                "## 引き継ぎ確認 (" + .metadata.from_agent + " → planner)\n" +
                "Task: " + .summary.current_task + "\n" +
                "Next: " + (.summary.next_steps[0] // "確認中ですね")
            ' "${handover_file}" 2>/dev/null
            return 0
        else
            # Invalid JSON - feminine polite fallback message
            log_to_file "WARN" "Invalid JSON in handover file"
            echo "引き継ぎファイルが破損していますね - notes.md を確認しましょう"
            return 1
        fi
    else
        # Fallback: grep-based extraction (graceful degradation)
        debug_log "jq not available, using grep fallback"
        echo "## 引き継ぎ確認"
        grep -o '"from_agent"[[:space:]]*:[[:space:]]*"[^"]*"' "${handover_file}" 2>/dev/null | \
            cut -d'"' -f4 | head -1 || echo "Unknown"
        grep -o '"current_task"[[:space:]]*:[[:space:]]*"[^"]*"' "${handover_file}" 2>/dev/null | \
            cut -d'"' -f4 | head -1 || echo "Task情報が取得できませんでした"
        return 0
    fi
}

# Find the latest handover file (strategic: prioritize recent information)
# Globals:
#   HANDOVER_PATTERN
# Outputs:
#   Path to latest handover file
# Returns:
#   0 - File found
#   1 - No files found
find_latest_handover() {
    debug_log "Searching for handover files"

    # Use nullglob for safe pattern matching
    shopt -s nullglob
    local handover_files=($HANDOVER_PATTERN)
    shopt -u nullglob

    if [[ "${#handover_files[@]}" -eq 0 ]]; then
        debug_log "No handover files found"
        return 1
    fi

    # Get most recent file
    local latest_file
    latest_file=$(ls -t "${handover_files[@]}" 2>/dev/null | head -1)

    if [[ -n "${latest_file}" ]]; then
        debug_log "Found latest handover: ${latest_file}"
        echo "${latest_file}"
        return 0
    fi

    return 1
}

# ============================================================================
# Display Functions
# ============================================================================

# Display handover information with caching (main coordination function)
# Globals:
#   CACHE_FILE, CACHE_TTL
# Outputs:
#   Handover information or fallback message
# Returns:
#   0 - Always succeeds
show_handover() {
    debug_log "show_handover() called"

    # Strategy: Try cache first for performance
    local cached_output
    if cached_output=$(get_cached_handover "${CACHE_FILE}" "${CACHE_TTL}"); then
        echo "${cached_output}"
        log_to_file "INFO" "Used cached handover"
        return 0
    fi

    # Find and process latest handover
    local latest_handover
    if ! latest_handover=$(find_latest_handover); then
        show_notes_fallback
        return 0
    fi

    # Parse and display with caching
    local handover_content
    if handover_content=$(parse_handover_json "${latest_handover}"); then
        echo "${handover_content}"
        save_to_cache "${handover_content}" "${CACHE_FILE}"
        log_to_file "INFO" "Processed handover: ${latest_handover}"
        return 0
    else
        show_notes_fallback
        return 0
    fi
}

# Show notes.md fallback when handover is unavailable
# Feminine polite tone: collaborative and thoughtful
# Globals:
#   NOTES_FILE
# Outputs:
#   Fallback message with optional notes excerpt
# Returns:
#   0 - Always succeeds
show_notes_fallback() {
    debug_log "Using notes.md fallback"

    if [[ -f "${NOTES_FILE}" ]]; then
        # Feminine polite: "引き継ぎはありませんね" (no handover found)
        echo "引き継ぎはありませんね - notes.md を確認しましょう"

        # Extract current task if available (strategic focus)
        if grep -q "## 現在のタスク" "${NOTES_FILE}" 2>/dev/null; then
            echo ""
            sed -n '/## 現在のタスク/,/^##/p' "${NOTES_FILE}" 2>/dev/null | head -5 || true
        fi
    else
        # Feminine polite: "新しいフェーズから始めましょう" (let's start fresh)
        echo "引き継ぎはありませんね - 新しいフェーズから始めましょう"
    fi

    log_to_file "INFO" "Used notes.md fallback"
}

# ============================================================================
# Main Entry Point
# ============================================================================

# Main function: coordinates startup workflow
# Strategic approach: validate → retrieve → display
# Returns:
#   EXIT_SUCCESS - Always (non-blocking design)
main() {
    debug_log "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"
    debug_log "Agent: ${AGENT_NAME} (${AGENT_ROLE})"
    debug_log "PROJECT_DIR: ${PROJECT_DIR}"

    # Step 1: Validate environment (security first)
    if ! validate_project_dir; then
        # Feminine polite error message
        echo "引き継ぎの確認ができませんでした"
        return "${EXIT_SUCCESS}"  # Don't block agent startup
    fi

    # Step 2: Display handover information (main purpose)
    show_handover

    # Step 3: Log completion
    log_to_file "INFO" "Completed with exit code: ${EXIT_SUCCESS}"
    return "${EXIT_SUCCESS}"
}

# Execute main if run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
