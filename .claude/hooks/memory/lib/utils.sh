#!/bin/bash
# utils.sh - Utility functions for notes rotation system
# Version: 2.0.0
# Modular component of notes-rotator.sh

# ==============================================================================
# Script Safety Settings
# ==============================================================================

set -o nounset    # Abort on unbound variable
set -o errtrace   # Inherit traps in functions
set -o pipefail   # Propagate pipe failures

# ==============================================================================
# Logging Functions
# ==============================================================================

# Log level configuration
readonly LOG_LEVEL="${LOG_LEVEL:-INFO}"
readonly LOG_FILE="${LOG_FILE:-/dev/stderr}"
readonly LOG_DATE_FORMAT="%Y-%m-%d %H:%M:%S"

# ANSI color codes for terminal output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Check if output supports colors
supports_color() {
    if [ -t 2 ] && [ -n "${TERM:-}" ] && [ "${TERM}" != "dumb" ]; then
        return 0
    fi
    return 1
}

# Log debug messages
log_debug() {
    local message="$1"
    if [[ "${LOG_LEVEL}" == "DEBUG" ]]; then
        local timestamp
        timestamp=$(date +"${LOG_DATE_FORMAT}")
        if supports_color; then
            echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} ${timestamp} ${message}" >&2
        else
            echo "[DEBUG] ${timestamp} ${message}" >&2
        fi
    fi
}

# Log info messages
log_info() {
    local message="$1"
    if [[ "${LOG_LEVEL}" =~ ^(DEBUG|INFO)$ ]]; then
        local timestamp
        timestamp=$(date +"${LOG_DATE_FORMAT}")
        if supports_color; then
            echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} ${timestamp} ${message}" >&2
        else
            echo "[INFO] ${timestamp} ${message}" >&2
        fi
    fi
}

# Log warning messages
log_warn() {
    local message="$1"
    local timestamp
    timestamp=$(date +"${LOG_DATE_FORMAT}")
    if supports_color; then
        echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} ${timestamp} ${message}" >&2
    else
        echo "[WARN] ${timestamp} ${message}" >&2
    fi
}

# Log error messages
log_error() {
    local message="$1"
    local timestamp
    timestamp=$(date +"${LOG_DATE_FORMAT}")
    if supports_color; then
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} ${timestamp} ${message}" >&2
    else
        echo "[ERROR] ${timestamp} ${message}" >&2
    fi
}

# ==============================================================================
# Validation Functions
# ==============================================================================

# Validate that a content file exists and is readable
validate_content_file() {
    local file="$1"

    if [[ -z "$file" ]]; then
        log_error "File path is empty"
        return 1
    fi

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

# Validate directory exists and is writable
validate_directory() {
    local dir="$1"

    if [[ -z "$dir" ]]; then
        log_error "Directory path is empty"
        return 1
    fi

    if [[ ! -d "$dir" ]]; then
        log_debug "Directory does not exist, creating: $dir"
        if ! mkdir -p "$dir"; then
            log_error "Failed to create directory: $dir"
            return 1
        fi
    fi

    if [[ ! -w "$dir" ]]; then
        log_error "Directory is not writable: $dir"
        return 1
    fi

    return 0
}

# Validate numeric value
validate_number() {
    local value="$1"
    local min="${2:-0}"
    local max="${3:-999999}"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "Value is not a number: $value"
        return 1
    fi

    if (( value < min )); then
        log_error "Value $value is less than minimum $min"
        return 1
    fi

    if (( value > max )); then
        log_error "Value $value is greater than maximum $max"
        return 1
    fi

    return 0
}

# ==============================================================================
# File Operation Functions
# ==============================================================================

# Safe file copy with backup
safe_copy() {
    local source="$1"
    local dest="$2"

    if ! validate_content_file "$source"; then
        return 1
    fi

    # Create backup if destination exists
    if [[ -f "$dest" ]]; then
        local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        log_debug "Creating backup: $backup"
        if ! cp "$dest" "$backup"; then
            log_error "Failed to create backup of $dest"
            return 1
        fi
    fi

    # Copy file
    if ! cp "$source" "$dest"; then
        log_error "Failed to copy $source to $dest"
        return 1
    fi

    log_debug "Successfully copied $source to $dest"
    return 0
}

# Safe file move with validation
safe_move() {
    local source="$1"
    local dest="$2"

    if ! validate_content_file "$source"; then
        return 1
    fi

    # Ensure destination directory exists
    local dest_dir
    dest_dir=$(dirname "$dest")
    if ! validate_directory "$dest_dir"; then
        return 1
    fi

    # Move file
    if ! mv "$source" "$dest"; then
        log_error "Failed to move $source to $dest"
        return 1
    fi

    log_debug "Successfully moved $source to $dest"
    return 0
}

# Create temporary file safely
create_temp_file() {
    local prefix="${1:-notes}"
    local temp_file

    if ! temp_file=$(mktemp -t "${prefix}-XXXXXX"); then
        log_error "Failed to create temporary file"
        return 1
    fi

    echo "$temp_file"
    return 0
}

# ==============================================================================
# String Processing Functions
# ==============================================================================

# Sanitize output for arithmetic operations
sanitize_number() {
    local input="$1"
    local default="${2:-0}"

    if [[ -z "$input" ]]; then
        echo "$default"
        return 0
    fi

    # Remove all non-numeric characters and ensure single line
    local clean
    clean=$(echo "$input" | tr -d '\n' | grep -o '[0-9]*' | head -1)

    if [[ -z "$clean" ]]; then
        echo "$default"
    else
        echo "$clean"
    fi
}

# Trim whitespace from string
trim_whitespace() {
    local string="$1"

    # Remove leading whitespace
    string="${string#"${string%%[![:space:]]*}"}"
    # Remove trailing whitespace
    string="${string%"${string##*[![:space:]]}"}"

    echo "$string"
}

# ==============================================================================
# Date and Time Functions
# ==============================================================================

# Get current timestamp in ISO format
get_timestamp() {
    date -Iseconds
}

# Get formatted date for filenames
get_file_date() {
    local format="${1:-%Y%m%d-%H%M%S}"
    date +"$format"
}

# Calculate elapsed time in nanoseconds
get_elapsed_ns() {
    local start_ns="$1"
    local end_ns
    end_ns=$(date +%s%N)

    echo $((end_ns - start_ns))
}

# ==============================================================================
# Pattern Matching Functions
# ==============================================================================

# Count pattern matches in a file
count_pattern_matches() {
    local file="$1"
    local pattern="$2"

    if ! validate_content_file "$file"; then
        echo "0"
        return 0
    fi

    local count
    count=$(grep -cE "$pattern" "$file" 2>/dev/null || echo "0")

    # Sanitize output to ensure single numeric value
    sanitize_number "$count" "0"
}

# Extract lines matching pattern
extract_matching_lines() {
    local file="$1"
    local pattern="$2"
    local limit="${3:-0}"

    if ! validate_content_file "$file"; then
        return 1
    fi

    if [[ "$limit" -gt 0 ]]; then
        grep -E "$pattern" "$file" 2>/dev/null | head -n "$limit"
    else
        grep -E "$pattern" "$file" 2>/dev/null
    fi
}

# ==============================================================================
# Resource Management Functions
# ==============================================================================

# Track temporary files for cleanup
declare -ga TEMP_FILES=()
declare -ga BACKUP_FILES=()

# Register temporary file for cleanup
register_temp_file() {
    local file="$1"
    TEMP_FILES+=("$file")
    log_debug "Registered temp file: $file"
}

# Register backup file for cleanup
register_backup_file() {
    local file="$1"
    BACKUP_FILES+=("$file")
    log_debug "Registered backup file: $file"
}

# Cleanup temporary files
cleanup_temp_files() {
    local exit_code="${1:-$?}"

    log_debug "Cleaning up temporary files (exit code: $exit_code)"

    # Clean up temporary files
    for temp_file in "${TEMP_FILES[@]:-}"; do
        if [[ -f "$temp_file" ]]; then
            log_debug "Removing temp file: $temp_file"
            rm -f "$temp_file"
        fi
    done

    # Handle backup files based on exit code
    for backup_file in "${BACKUP_FILES[@]:-}"; do
        if [[ -f "$backup_file" ]]; then
            if [[ $exit_code -ne 0 ]]; then
                # Restore on failure
                local original="${backup_file%.bak.*}"
                log_info "Restoring backup: $backup_file -> $original"
                mv "$backup_file" "$original"
            else
                # Remove on success
                log_debug "Removing backup: $backup_file"
                rm -f "$backup_file"
            fi
        fi
    done

    return $exit_code
}

# Set up cleanup trap
setup_cleanup_trap() {
    trap cleanup_temp_files EXIT
    trap 'cleanup_temp_files $?' ERR INT TERM
}

# ==============================================================================
# Performance Monitoring
# ==============================================================================

# Start performance timer
start_timer() {
    date +%s%N
}

# Check if elapsed time exceeds threshold
check_performance() {
    local start_ns="$1"
    local threshold_ns="${2:-1000000000}"  # Default 1 second

    local elapsed_ns
    elapsed_ns=$(get_elapsed_ns "$start_ns")

    if (( elapsed_ns > threshold_ns )); then
        log_warn "Performance threshold exceeded: $((elapsed_ns / 1000000))ms"
        return 1
    fi

    log_debug "Performance OK: $((elapsed_ns / 1000000))ms"
    return 0
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Export all utility functions for use by other modules
export -f log_debug log_info log_warn log_error
export -f validate_content_file validate_directory validate_number
export -f safe_copy safe_move create_temp_file
export -f sanitize_number trim_whitespace
export -f get_timestamp get_file_date get_elapsed_ns
export -f count_pattern_matches extract_matching_lines
export -f register_temp_file register_backup_file cleanup_temp_files
export -f setup_cleanup_trap
export -f start_timer check_performance
export -f supports_color

# Export arrays
export TEMP_FILES BACKUP_FILES