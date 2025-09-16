#!/bin/bash
# config.sh - Configuration management for notes rotation system
# Version: 2.0.0
# Modular component of notes-rotator.sh

# ==============================================================================
# Script Safety Settings
# ==============================================================================

set -o nounset    # Abort on unbound variable
set -o errtrace   # Inherit traps in functions
set -o pipefail   # Propagate pipe failures

# ==============================================================================
# Configuration Constants
# ==============================================================================

# Rotation thresholds
readonly NOTES_ROTATION_THRESHOLD="${NOTES_ROTATION_THRESHOLD:-450}"
readonly NOTES_ARCHIVE_HEADER_LINES="${NOTES_ARCHIVE_HEADER_LINES:-40}"
readonly MAX_ARCHIVE_ENTRIES="${MAX_ARCHIVE_ENTRIES:-100}"

# Importance scoring configuration
readonly SCORE_CRITICAL=80
readonly SCORE_IMPORTANT=70
readonly SCORE_NORMAL=30
readonly SCORE_TEMPORARY_PENALTY=10
readonly SCORE_MIN=0
readonly SCORE_MAX=100

# Content pattern definitions
readonly CRITICAL_PATTERNS="ERROR:|CRITICAL:|SECURITY:|🔴"
readonly IMPORTANT_PATTERNS="TODO:|DECISION:|ADR-|⚠️"
readonly NORMAL_PATTERNS="INFO:|DEBUG:|TRACE:"
readonly TEMPORARY_PATTERNS="TEMP:|TEST:|SCRATCH:"

# Archive configuration
readonly ARCHIVE_INDEX_FILENAME="archive_index.json"
readonly ARCHIVE_DATE_FORMAT="%Y%m%d-%H%M%S"

# Performance settings
readonly MAX_PROCESSING_TIME_NS=1000000000  # 1 second in nanoseconds
readonly BATCH_SIZE=100  # Process files in batches

# ==============================================================================
# Configuration Loading
# ==============================================================================

# Load configuration from file if exists
load_config_file() {
    local config_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.config/claude}"
    local config_file="${config_dir}/rotation.conf"

    if [[ -f "${config_file}" ]]; then
        # shellcheck source=/dev/null
        source "${config_file}"
        return 0
    fi
    return 1
}

# Validate configuration values
validate_config() {
    # Validate numeric thresholds
    if ! [[ "${NOTES_ROTATION_THRESHOLD}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: NOTES_ROTATION_THRESHOLD must be a positive integer" >&2
        return 1
    fi

    if ! [[ "${MAX_ARCHIVE_ENTRIES}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: MAX_ARCHIVE_ENTRIES must be a positive integer" >&2
        return 1
    fi

    # Validate scores are within reasonable range
    if (( SCORE_CRITICAL < 0 || SCORE_CRITICAL > 100 )); then
        echo "ERROR: SCORE_CRITICAL must be between 0 and 100" >&2
        return 1
    fi

    return 0
}

# Initialize configuration
init_config() {
    load_config_file || true
    validate_config || return 1
}

# Export configuration for use by other modules
export NOTES_ROTATION_THRESHOLD
export MAX_ARCHIVE_ENTRIES
export SCORE_CRITICAL SCORE_IMPORTANT SCORE_NORMAL SCORE_TEMPORARY_PENALTY
export SCORE_MIN SCORE_MAX
export CRITICAL_PATTERNS IMPORTANT_PATTERNS NORMAL_PATTERNS TEMPORARY_PATTERNS
export ARCHIVE_INDEX_FILENAME ARCHIVE_DATE_FORMAT
export MAX_PROCESSING_TIME_NS BATCH_SIZE