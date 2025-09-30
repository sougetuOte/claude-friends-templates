#!/bin/bash
# handover-lifecycle.sh - Handover File Lifecycle Management
# Version: 2.0.0
# Purpose: Automated archival, cleanup, and restoration of handover files
#
# Commands:
#   archive  - Archive handover files older than retention period
#   cleanup  - Delete archives older than archive retention period
#   restore  - Restore archived files from compressed format
#   status   - Show lifecycle statistics with disk usage
#
# Options:
#   --dry-run      - Show what would be done (default)
#   --no-dry-run   - Actually perform operations
#   --force        - Skip safety checks (use with caution)
#   --quiet        - Only output errors (for cron jobs)
#
# Environment Variables:
#   CLAUDE_PROJECT_DIR           - Project root directory (default: pwd)
#   HANDOVER_RETENTION_DAYS      - Days before archival (default: 7)
#   HANDOVER_ARCHIVE_DAYS        - Days before deletion (default: 30)
#   HANDOVER_MIN_RETENTION_DAYS  - Minimum retention safety (default: 3)
#   DEBUG                        - Enable debug output (DEBUG=1)

set -uo pipefail

# === Constants ===
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "${0}")"

# Path Configuration
readonly PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
readonly HANDOVER_DIR="${PROJECT_DIR}/.claude"
readonly ARCHIVE_DIR="${PROJECT_DIR}/.claude/archive/handover"
readonly LOG_DIR="${PROJECT_DIR}/.claude/logs"
readonly LOG_FILE="${LOG_DIR}/handover-lifecycle.log"
readonly CONFIG_FILE="${PROJECT_DIR}/.claude/lifecycle-config.json"

# Default Configuration (can be overridden by config file or environment)
DEFAULT_RETENTION_DAYS=7
DEFAULT_ARCHIVE_DAYS=30
DEFAULT_MIN_RETENTION_DAYS=3
DEFAULT_COMPRESSION_LEVEL=6

# Load configuration from file if exists
load_configuration() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        debug_log "Loading configuration from ${CONFIG_FILE}"

        # Parse JSON config using grep and sed (portable approach)
        if command -v jq >/dev/null 2>&1; then
            # Use jq if available (preferred)
            RETENTION_DAYS=$(jq -r '.retention.active_days // empty' "${CONFIG_FILE}" 2>/dev/null || echo "")
            ARCHIVE_DAYS=$(jq -r '.retention.archive_days // empty' "${CONFIG_FILE}" 2>/dev/null || echo "")
            MIN_RETENTION_DAYS=$(jq -r '.retention.min_retention_days // empty' "${CONFIG_FILE}" 2>/dev/null || echo "")
            COMPRESSION_LEVEL=$(jq -r '.archive.compression_level // empty' "${CONFIG_FILE}" 2>/dev/null || echo "")
        else
            # Fallback: simple grep-based parsing
            RETENTION_DAYS=$(grep -o '"active_days"[[:space:]]*:[[:space:]]*[0-9]*' "${CONFIG_FILE}" 2>/dev/null | grep -o '[0-9]*$' || echo "")
            ARCHIVE_DAYS=$(grep -o '"archive_days"[[:space:]]*:[[:space:]]*[0-9]*' "${CONFIG_FILE}" 2>/dev/null | grep -o '[0-9]*$' || echo "")
            MIN_RETENTION_DAYS=$(grep -o '"min_retention_days"[[:space:]]*:[[:space:]]*[0-9]*' "${CONFIG_FILE}" 2>/dev/null | grep -o '[0-9]*$' || echo "")
            COMPRESSION_LEVEL=$(grep -o '"compression_level"[[:space:]]*:[[:space:]]*[0-9]*' "${CONFIG_FILE}" 2>/dev/null | grep -o '[0-9]*$' || echo "")
        fi
    fi

    # Apply environment variable overrides, then config file, then defaults
    RETENTION_DAYS="${HANDOVER_RETENTION_DAYS:-${RETENTION_DAYS:-$DEFAULT_RETENTION_DAYS}}"
    ARCHIVE_DAYS="${HANDOVER_ARCHIVE_DAYS:-${ARCHIVE_DAYS:-$DEFAULT_ARCHIVE_DAYS}}"
    MIN_RETENTION_DAYS="${HANDOVER_MIN_RETENTION_DAYS:-${MIN_RETENTION_DAYS:-$DEFAULT_MIN_RETENTION_DAYS}}"
    COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-$DEFAULT_COMPRESSION_LEVEL}"

    readonly RETENTION_DAYS
    readonly ARCHIVE_DAYS
    readonly MIN_RETENTION_DAYS
    readonly COMPRESSION_LEVEL
}

# Debug mode
readonly DEBUG="${DEBUG:-0}"

# Quiet mode (for cron)
QUIET_MODE=false

# === Utility Functions ===

debug_log() {
    if [[ "${DEBUG}" == "1" ]]; then
        echo "[DEBUG $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
    fi
}

log_to_file() {
    local level="${1}"
    shift
    local message="$*"

    # Create log directory if needed
    mkdir -p "${LOG_DIR}" 2>/dev/null || true

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

output_message() {
    if [[ "${QUIET_MODE}" == "false" ]]; then
        echo "$@"
    fi
}

error_message() {
    echo "$@" >&2
}

# Get file age in days
get_file_age_days() {
    local file="$1"
    local file_time
    local current_time
    local age_seconds

    file_time=$(stat -c %Y "${file}" 2>/dev/null || echo 0)
    current_time=$(date +%s)
    age_seconds=$((current_time - file_time))

    echo $((age_seconds / 86400))  # Convert to days
}

# Get human-readable file size
get_file_size_human() {
    local file="$1"
    if [[ -f "${file}" ]]; then
        local size_bytes
        size_bytes=$(stat -c %s "${file}" 2>/dev/null || echo 0)

        if [[ ${size_bytes} -lt 1024 ]]; then
            echo "${size_bytes}B"
        elif [[ ${size_bytes} -lt 1048576 ]]; then
            echo "$((size_bytes / 1024))KB"
        else
            echo "$((size_bytes / 1048576))MB"
        fi
    else
        echo "0B"
    fi
}

# Calculate total directory size in bytes
get_directory_size_bytes() {
    local dir="$1"
    if [[ -d "${dir}" ]]; then
        du -sb "${dir}" 2>/dev/null | cut -f1 || echo 0
    else
        echo 0
    fi
}

# Format bytes to human-readable
format_bytes() {
    local bytes=$1

    if [[ ${bytes} -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ ${bytes} -lt 1048576 ]]; then
        printf "%.2fKB" "$(bc -l <<< "${bytes}/1024" 2>/dev/null || echo "${bytes}")"
    elif [[ ${bytes} -lt 1073741824 ]]; then
        printf "%.2fMB" "$(bc -l <<< "${bytes}/1048576" 2>/dev/null || echo "${bytes}")"
    else
        printf "%.2fGB" "$(bc -l <<< "${bytes}/1073741824" 2>/dev/null || echo "${bytes}")"
    fi
}

# === Validation Functions ===

validate_json_file() {
    local file="$1"

    if [[ ! -f "${file}" ]]; then
        error_message "Error: File does not exist: ${file}"
        return 1
    fi

    # Try to parse with jq if available
    if command -v jq >/dev/null 2>&1; then
        if ! jq empty "${file}" >/dev/null 2>&1; then
            error_message "Error: Invalid JSON in file: ${file}"
            return 1
        fi
    else
        # Basic JSON validation without jq
        if ! grep -q "^{" "${file}" || ! grep -q "}$" "${file}"; then
            error_message "Warning: Basic JSON validation failed for: ${file}"
            return 1
        fi
    fi

    debug_log "JSON validation passed: ${file}"
    return 0
}

validate_disk_space() {
    local required_mb=$1
    local target_dir="${2:-${PROJECT_DIR}}"

    # Get available space in MB
    local available_mb
    available_mb=$(df -BM "${target_dir}" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/M//')

    if [[ -z "${available_mb}" ]]; then
        debug_log "Could not determine disk space, assuming sufficient"
        return 0
    fi

    if [[ ${available_mb} -lt ${required_mb} ]]; then
        error_message "Error: Insufficient disk space. Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi

    debug_log "Disk space check passed: ${available_mb}MB available"
    return 0
}

validate_permissions() {
    local dir="$1"

    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}" 2>/dev/null || {
            error_message "Error: Cannot create directory: ${dir}"
            return 1
        }
    fi

    if [[ ! -w "${dir}" ]]; then
        error_message "Error: No write permission for directory: ${dir}"
        return 1
    fi

    debug_log "Permission check passed: ${dir}"
    return 0
}

# === Archive Functions ===

archive_handover_file() {
    local file="$1"
    local dry_run="${2:-true}"
    local force="${3:-false}"

    local filename
    filename="$(basename "${file}")"
    local file_age
    file_age=$(get_file_age_days "${file}")

    debug_log "Checking file: ${filename}, age: ${file_age} days"

    # Safety check: minimum retention period
    if [[ "${force}" != "true" ]] && [[ "${file_age}" -lt "${MIN_RETENTION_DAYS}" ]]; then
        debug_log "Skipping ${filename}: below minimum retention (${MIN_RETENTION_DAYS} days)"
        return 0
    fi

    # Check if file is old enough for archival
    if [[ "${file_age}" -lt "${RETENTION_DAYS}" ]]; then
        debug_log "Skipping ${filename}: not old enough (${RETENTION_DAYS} days required)"
        return 0
    fi

    # Determine archive subdirectory (YYYY-MM format)
    local file_date
    file_date=$(date -r "${file}" +%Y-%m 2>/dev/null || date +%Y-%m)
    local archive_subdir="${ARCHIVE_DIR}/${file_date}"

    if [[ "${dry_run}" == "true" ]]; then
        output_message "[DRY RUN] Would archive: ${filename} -> ${archive_subdir}/${filename}.gz"
        log_to_file "INFO" "DRY RUN: Would archive ${filename}"
    else
        # Validate before archiving
        validate_json_file "${file}" || {
            log_to_file "ERROR" "JSON validation failed for ${filename}, skipping"
            return 1
        }

        validate_permissions "${archive_subdir}" || return 1
        validate_disk_space 10 "${archive_subdir}" || return 1

        # Compress and move file
        if gzip -${COMPRESSION_LEVEL} -c "${file}" > "${archive_subdir}/${filename}.gz" 2>/dev/null; then
            # Verify compressed file integrity
            if gzip -t "${archive_subdir}/${filename}.gz" 2>/dev/null; then
                rm -f "${file}"
                output_message "[SUCCESS] Archived: ${filename} -> ${archive_subdir}/${filename}.gz"
                log_to_file "ARCHIVE" "Archived ${filename} to ${archive_subdir}"
            else
                rm -f "${archive_subdir}/${filename}.gz"
                error_message "[ERROR] Compression verification failed for ${filename}"
                log_to_file "ERROR" "Compression verification failed for ${filename}"
                return 1
            fi
        else
            log_to_file "ERROR" "Failed to compress ${filename}"
            return 1
        fi
    fi

    return 0
}

cmd_archive() {
    local dry_run=true
    local force=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-dry-run)
                dry_run=false
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --quiet)
                QUIET_MODE=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    output_message "=== Handover File Archival ==="
    output_message "Retention period: ${RETENTION_DAYS} days"
    output_message "Minimum retention: ${MIN_RETENTION_DAYS} days"
    output_message "Compression level: ${COMPRESSION_LEVEL}"
    if [[ "${dry_run}" == "true" ]]; then
        output_message "Mode: DRY RUN (use --no-dry-run to execute)"
    else
        output_message "Mode: EXECUTION"
    fi
    output_message ""

    log_to_file "INFO" "Starting archive operation (dry_run=${dry_run})"

    # Find handover files in main directory
    local archived_count=0
    local skipped_count=0

    shopt -s nullglob
    for file in "${HANDOVER_DIR}"/handover-*.json; do
        if [[ -f "${file}" ]]; then
            if archive_handover_file "${file}" "${dry_run}" "${force}"; then
                archived_count=$((archived_count + 1))
            else
                skipped_count=$((skipped_count + 1))
            fi
        fi
    done
    shopt -u nullglob

    output_message ""
    output_message "Summary: ${archived_count} files archived, ${skipped_count} skipped"
    log_to_file "INFO" "Archive operation completed: ${archived_count} archived, ${skipped_count} skipped"

    return 0
}

# === Cleanup Functions ===

cleanup_old_archives() {
    local dry_run="${1:-true}"

    output_message "=== Archive Cleanup ==="
    output_message "Archive retention: ${ARCHIVE_DAYS} days"
    if [[ "${dry_run}" == "true" ]]; then
        output_message "Mode: DRY RUN (use --no-dry-run to execute)"
    else
        output_message "Mode: EXECUTION"
    fi
    output_message ""

    log_to_file "INFO" "Starting cleanup operation (dry_run=${dry_run})"

    local deleted_count=0

    # Find old archives
    if [[ ! -d "${ARCHIVE_DIR}" ]]; then
        output_message "No archive directory found"
        return 0
    fi

    shopt -s nullglob
    for file in "${ARCHIVE_DIR}"/**/*.json.gz; do
        if [[ -f "${file}" ]]; then
            local file_age
            file_age=$(get_file_age_days "${file}")

            if [[ "${file_age}" -gt "${ARCHIVE_DAYS}" ]]; then
                local filename
                filename="$(basename "${file}")"

                if [[ "${dry_run}" == "true" ]]; then
                    output_message "[DRY RUN] Would delete: ${filename} (age: ${file_age} days)"
                    log_to_file "INFO" "DRY RUN: Would delete ${filename}"
                else
                    if rm -f "${file}"; then
                        output_message "[SUCCESS] Deleted: ${filename} (age: ${file_age} days)"
                        log_to_file "CLEANUP" "Deleted archive ${filename}"
                        deleted_count=$((deleted_count + 1))
                    else
                        error_message "[ERROR] Failed to delete ${filename}"
                        log_to_file "ERROR" "Failed to delete ${filename}"
                    fi
                fi
            fi
        fi
    done
    shopt -u nullglob

    output_message ""
    output_message "Summary: ${deleted_count} archives deleted"
    log_to_file "INFO" "Cleanup operation completed: ${deleted_count} deleted"

    return 0
}

cmd_cleanup() {
    local dry_run=true

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-dry-run)
                dry_run=false
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --quiet)
                QUIET_MODE=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    cleanup_old_archives "${dry_run}"
}

# === Restore Functions ===

cmd_restore() {
    local archive_file=""
    local target_dir=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet)
                QUIET_MODE=true
                shift
                ;;
            *)
                if [[ -z "${archive_file}" ]]; then
                    archive_file="$1"
                elif [[ -z "${target_dir}" ]]; then
                    target_dir="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate input
    if [[ -z "${archive_file}" ]]; then
        error_message "Error: Archive file path required"
        error_message "Usage: ${SCRIPT_NAME} restore <archive-file> [target-directory]"
        return 1
    fi

    if [[ ! -f "${archive_file}" ]]; then
        error_message "Error: Archive file not found: ${archive_file}"
        return 1
    fi

    if [[ ! "${archive_file}" =~ \.json\.gz$ ]]; then
        error_message "Error: Archive file must have .json.gz extension"
        return 1
    fi

    # Determine target directory
    if [[ -z "${target_dir}" ]]; then
        target_dir="${HANDOVER_DIR}"
    fi

    # Validate target directory
    validate_permissions "${target_dir}" || return 1
    validate_disk_space 10 "${target_dir}" || return 1

    # Extract filename
    local base_name
    base_name="$(basename "${archive_file}" .gz)"
    local target_file="${target_dir}/${base_name}"

    output_message "=== Archive Restoration ==="
    output_message "Source: ${archive_file}"
    output_message "Target: ${target_file}"
    output_message ""

    # Check if target already exists
    if [[ -f "${target_file}" ]]; then
        error_message "Error: Target file already exists: ${target_file}"
        error_message "Please remove or rename the existing file first"
        return 1
    fi

    # Verify archive integrity before decompression
    if ! gzip -t "${archive_file}" 2>/dev/null; then
        error_message "Error: Archive file is corrupted: ${archive_file}"
        log_to_file "ERROR" "Corrupted archive: ${archive_file}"
        return 1
    fi

    # Decompress file
    if gzip -dc "${archive_file}" > "${target_file}" 2>/dev/null; then
        # Validate restored JSON
        if validate_json_file "${target_file}"; then
            output_message "[SUCCESS] Restored: ${base_name} -> ${target_file}"
            log_to_file "RESTORE" "Restored ${base_name} from ${archive_file}"

            # Display file info
            local file_size
            file_size=$(get_file_size_human "${target_file}")
            output_message "Restored file size: ${file_size}"

            return 0
        else
            # JSON validation failed, clean up
            rm -f "${target_file}"
            error_message "Error: Restored file failed JSON validation"
            log_to_file "ERROR" "Restored file validation failed: ${base_name}"
            return 1
        fi
    else
        error_message "Error: Failed to decompress archive: ${archive_file}"
        log_to_file "ERROR" "Decompression failed: ${archive_file}"
        return 1
    fi
}

# === Status Functions ===

cmd_status() {
    output_message "=== Handover Lifecycle Status ==="
    output_message ""

    # Count active handover files and calculate sizes
    local active_count=0
    local active_total_size=0
    local oldest_age=0
    local newest_age=999999

    shopt -s nullglob
    for file in "${HANDOVER_DIR}"/handover-*.json; do
        if [[ -f "${file}" ]]; then
            active_count=$((active_count + 1))
            local file_size
            file_size=$(stat -c %s "${file}" 2>/dev/null || echo 0)
            active_total_size=$((active_total_size + file_size))

            local age
            age=$(get_file_age_days "${file}")
            if [[ ${age} -gt ${oldest_age} ]]; then
                oldest_age=${age}
            fi
            if [[ ${age} -lt ${newest_age} ]]; then
                newest_age=${age}
            fi
        fi
    done
    shopt -u nullglob

    output_message "Active handover files: ${active_count}"
    if [[ ${active_count} -gt 0 ]]; then
        output_message "Active files disk usage: $(format_bytes ${active_total_size})"
        output_message "Age range: ${newest_age}-${oldest_age} days"
    fi

    # Show age distribution
    if [[ "${active_count}" -gt 0 ]]; then
        output_message ""
        output_message "Age distribution:"
        shopt -s nullglob
        for file in "${HANDOVER_DIR}"/handover-*.json; do
            if [[ -f "${file}" ]]; then
                local filename
                filename="$(basename "${file}")"
                local age
                age=$(get_file_age_days "${file}")
                local size
                size=$(get_file_size_human "${file}")
                output_message "  ${filename}: ${age} days old (${size})"
            fi
        done
        shopt -u nullglob
    fi

    # Count archived files and calculate sizes
    local archive_count=0
    local archive_total_size=0
    local archive_oldest_age=0

    if [[ -d "${ARCHIVE_DIR}" ]]; then
        shopt -s nullglob
        for file in "${ARCHIVE_DIR}"/**/*.json.gz; do
            if [[ -f "${file}" ]]; then
                archive_count=$((archive_count + 1))
                local file_size
                file_size=$(stat -c %s "${file}" 2>/dev/null || echo 0)
                archive_total_size=$((archive_total_size + file_size))

                local age
                age=$(get_file_age_days "${file}")
                if [[ ${age} -gt ${archive_oldest_age} ]]; then
                    archive_oldest_age=${age}
                fi
            fi
        done
        shopt -u nullglob
    fi

    output_message ""
    output_message "Archived files: ${archive_count}"
    if [[ ${archive_count} -gt 0 ]]; then
        output_message "Archive disk usage: $(format_bytes ${archive_total_size})"
        output_message "Oldest archive: ${archive_oldest_age} days"

        # Calculate compression ratio if we have both active and archived data
        if [[ ${active_total_size} -gt 0 ]] && [[ ${archive_total_size} -gt 0 ]]; then
            # Estimate original size (compressed files are typically from similar active files)
            local avg_active_size=$((active_total_size / (active_count > 0 ? active_count : 1)))
            local estimated_original_size=$((archive_count * avg_active_size))
            if [[ ${estimated_original_size} -gt 0 ]]; then
                local compression_ratio
                compression_ratio=$(bc -l <<< "scale=2; (1 - ${archive_total_size}/${estimated_original_size}) * 100" 2>/dev/null || echo "N/A")
                if [[ "${compression_ratio}" != "N/A" ]]; then
                    output_message "Estimated compression ratio: ${compression_ratio}%"
                fi
            fi
        fi

        # Calculate disk space savings
        local total_size=$((active_total_size + archive_total_size))
        if [[ ${total_size} -gt 0 ]]; then
            output_message "Total disk usage: $(format_bytes ${total_size})"
        fi
    fi

    # Configuration
    output_message ""
    output_message "Configuration:"
    output_message "  Retention period: ${RETENTION_DAYS} days"
    output_message "  Archive retention: ${ARCHIVE_DAYS} days"
    output_message "  Minimum retention: ${MIN_RETENTION_DAYS} days"
    output_message "  Compression level: ${COMPRESSION_LEVEL}"
    if [[ -f "${CONFIG_FILE}" ]]; then
        output_message "  Config file: ${CONFIG_FILE}"
    fi

    return 0
}

# === Main Entry Point ===

show_usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} <command> [options]

Commands:
  archive   - Archive handover files older than retention period
  cleanup   - Delete archives older than archive retention period
  restore   - Restore archived file from compressed format
  status    - Show lifecycle statistics with disk usage

Options:
  --dry-run      - Show what would be done (default)
  --no-dry-run   - Actually perform operations
  --force        - Skip safety checks (use with caution)
  --quiet        - Only output errors (for cron jobs)

Environment Variables:
  HANDOVER_RETENTION_DAYS      - Days before archival (default: 7)
  HANDOVER_ARCHIVE_DAYS        - Days before deletion (default: 30)
  HANDOVER_MIN_RETENTION_DAYS  - Minimum retention safety (default: 3)
  DEBUG                        - Enable debug output (DEBUG=1)

Configuration File:
  ${CONFIG_FILE}

  Example config:
  {
    "retention": {
      "active_days": 7,
      "archive_days": 30,
      "min_retention_days": 3
    },
    "archive": {
      "compression": "gzip",
      "compression_level": 6
    }
  }

Examples:
  ${SCRIPT_NAME} status                           # Show statistics
  ${SCRIPT_NAME} archive                          # Dry-run archive
  ${SCRIPT_NAME} archive --no-dry-run             # Execute archive
  ${SCRIPT_NAME} cleanup --no-dry-run             # Execute cleanup
  ${SCRIPT_NAME} restore archive.json.gz          # Restore file
  ${SCRIPT_NAME} archive --quiet --no-dry-run     # Silent mode (cron)

Version: ${SCRIPT_VERSION}
EOF
}

main() {
    local command="${1:-}"

    if [[ -z "${command}" ]]; then
        show_usage
        return 1
    fi

    # Load configuration before processing commands
    load_configuration

    debug_log "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"
    debug_log "Command: ${command}"

    shift

    case "${command}" in
        archive)
            cmd_archive "$@"
            ;;
        cleanup)
            cmd_cleanup "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error_message "Error: Unknown command: ${command}"
            echo ""
            show_usage
            return 1
            ;;
    esac

    return 0
}

# Execute main if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
