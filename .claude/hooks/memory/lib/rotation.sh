#!/bin/bash
# rotation.sh - Main rotation execution logic for notes rotation system
# Version: 2.0.0
# Modular component of notes-rotator.sh

# ==============================================================================
# Script Safety Settings
# ==============================================================================

set -o nounset    # Abort on unbound variable
set -o errtrace   # Inherit traps in functions
set -o pipefail   # Propagate pipe failures

# ==============================================================================
# Dependencies
# ==============================================================================

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/archive.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/analysis.sh" 2>/dev/null || true

# ==============================================================================
# Main Rotation Functions
# ==============================================================================

# Perform intelligent rotation
perform_intelligent_rotation() {
    local notes_file="$1"
    local archive_dir="$2"

    log_info "Starting intelligent rotation for: $notes_file"

    # Validate inputs
    if [[ ! -f "$notes_file" ]]; then
        log_error "Notes file does not exist: $notes_file"
        return 1
    fi

    # Check for forced failure (for testing)
    if [[ -n "${FORCE_ROTATION_FAILURE:-}" ]]; then
        log_error "Forced rotation failure for testing"
        return 1
    fi

    # Create backup before any modifications
    local backup_file="${notes_file}.backup.$(get_file_date)"
    if ! cp "$notes_file" "$backup_file" 2>/dev/null; then
        log_error "Failed to create backup: $backup_file"
        return 1
    fi
    register_backup_file "$backup_file"
    log_debug "Created backup: $backup_file"

    # Measure rotation performance
    local rotation_start_ns
    rotation_start_ns=$(start_timer)

    # Get original file metrics
    local original_lines
    original_lines=$(wc -l < "$notes_file" 2>/dev/null || echo "0")
    original_lines=$(sanitize_number "$original_lines" "0")

    # Create archive first
    log_info "Creating archive..."
    local archive_file
    if ! archive_file=$(create_archive "$notes_file" "$archive_dir"); then
        log_error "Failed to create archive"
        rm -f "$backup_file"
        return 1
    fi

    # Check for custom configuration
    local min_important_lines=100
    if [[ -n "${ROTATION_CONFIG:-}" ]]; then
        # Parse configuration from environment
        min_important_lines=$(echo "$ROTATION_CONFIG" | grep -o '"min_important_lines": *[0-9]*' | grep -o '[0-9]*' || echo "100")
        log_debug "Using custom min_important_lines: $min_important_lines"
    fi

    # Extract important content
    log_info "Extracting important content..."
    local temp_file
    if ! temp_file=$(extract_important_content "$notes_file" "$min_important_lines" "${ROTATION_CONFIG:-}"); then
        log_error "Failed to extract important content"
        rm -f "$backup_file"
        return 1
    fi
    register_temp_file "$temp_file"

    # Replace original file
    log_info "Applying rotation changes..."
    if ! mv "$temp_file" "$notes_file"; then
        log_error "Failed to replace notes file"
        rm -f "$temp_file"
        rm -f "$backup_file"
        return 1
    fi

    # Get new file metrics
    local new_lines
    new_lines=$(wc -l < "$notes_file" 2>/dev/null || echo "0")
    new_lines=$(sanitize_number "$new_lines" "0")

    # Update archive index
    log_info "Updating archive index..."
    if ! update_archive_index "$archive_dir" "$archive_file" "${CURRENT_AGENT:-unknown}" \
                             "$original_lines" "$new_lines"; then
        log_warn "Failed to update archive index (non-critical)"
    fi

    # Clean up old archives if needed
    local index_file="${archive_dir}/${ARCHIVE_INDEX_FILENAME}"
    if [[ -f "$index_file" ]]; then
        cleanup_old_archives "$index_file" "$MAX_ARCHIVE_ENTRIES"
        optimize_archive_index "$index_file"
    fi

    # Check rotation performance
    check_performance "$rotation_start_ns" "$MAX_PROCESSING_TIME_NS"

    # Clean up backup on success
    rm -f "$backup_file"

    # Report results
    local reduction=$((original_lines - new_lines))
    local reduction_pct=$((reduction * 100 / (original_lines + 1)))
    log_info "Rotation complete: $original_lines -> $new_lines lines (${reduction_pct}% reduction)"

    return 0
}

# Main rotation function to be called from agent-switch
rotate_notes_if_needed() {
    local notes_file="$1"
    local agent="${2:-unknown}"

    export CURRENT_AGENT="$agent"

    log_info "Checking rotation for agent: $agent"

    # Get archive directory
    local archive_dir
    archive_dir="$(dirname "$notes_file")/archives"

    # Check if rotation is needed
    local rotation_status
    rotation_status=$(check_rotation_threshold "$notes_file")

    if [[ "$rotation_status" == "rotation_needed" ]]; then
        log_info "Rotation threshold exceeded, starting rotation..."

        # Perform intelligent rotation
        if perform_intelligent_rotation "$notes_file" "$archive_dir"; then
            log_info "Rotation completed successfully"
            return 0
        else
            log_error "Rotation failed"
            return 1
        fi
    else
        log_debug "No rotation needed at this time"
    fi

    return 0
}

# ==============================================================================
# Batch Rotation Functions
# ==============================================================================

# Rotate multiple agent notes files
batch_rotate_notes() {
    local -a notes_files=("$@")
    local success_count=0
    local failure_count=0

    log_info "Starting batch rotation for ${#notes_files[@]} files"

    for notes_file in "${notes_files[@]}"; do
        local agent_name
        agent_name=$(basename "$(dirname "$notes_file")")

        if rotate_notes_if_needed "$notes_file" "$agent_name"; then
            ((success_count++))
            log_info "Successfully rotated: $notes_file"
        else
            ((failure_count++))
            log_error "Failed to rotate: $notes_file"
        fi
    done

    log_info "Batch rotation complete: $success_count succeeded, $failure_count failed"
    return $failure_count
}

# ==============================================================================
# Recovery Functions
# ==============================================================================

# Recover from failed rotation
recover_from_failed_rotation() {
    local notes_file="$1"
    local backup_pattern="${notes_file}.backup.*"

    log_info "Attempting to recover from failed rotation"

    # Find most recent backup
    local latest_backup
    latest_backup=$(ls -t $backup_pattern 2>/dev/null | head -1)

    if [[ -z "$latest_backup" ]]; then
        log_error "No backup file found for recovery"
        return 1
    fi

    if [[ ! -f "$latest_backup" ]]; then
        log_error "Backup file does not exist: $latest_backup"
        return 1
    fi

    # Restore from backup
    if cp "$latest_backup" "$notes_file"; then
        log_info "Successfully restored from backup: $latest_backup"
        return 0
    else
        log_error "Failed to restore from backup"
        return 1
    fi
}

# Verify rotation integrity
verify_rotation_integrity() {
    local notes_file="$1"
    local archive_dir="$2"

    log_info "Verifying rotation integrity"

    local issues=0

    # Check notes file exists and is readable
    if ! validate_content_file "$notes_file"; then
        log_error "Notes file validation failed"
        ((issues++))
    fi

    # Check archive directory
    if ! validate_directory "$archive_dir"; then
        log_error "Archive directory validation failed"
        ((issues++))
    fi

    # Check archive index
    local index_file="${archive_dir}/${ARCHIVE_INDEX_FILENAME}"
    if [[ -f "$index_file" ]]; then
        if ! verify_archive_integrity "$archive_dir"; then
            log_warn "Archive integrity check failed"
            ((issues++))
        fi
    fi

    if (( issues > 0 )); then
        log_error "Integrity verification found $issues issues"
        return 1
    else
        log_info "Integrity verification passed"
        return 0
    fi
}

# ==============================================================================
# Reporting Functions
# ==============================================================================

# Generate rotation report
generate_rotation_report() {
    local notes_file="$1"
    local archive_dir="$2"

    local index_file="${archive_dir}/${ARCHIVE_INDEX_FILENAME}"

    cat <<EOF
=== Notes Rotation Report ===
Date: $(get_timestamp)
Agent: ${CURRENT_AGENT:-unknown}

Current Status:
  Notes file: $(basename "$notes_file")
  Current size: $(wc -l < "$notes_file" 2>/dev/null || echo "0") lines
  Rotation threshold: $NOTES_ROTATION_THRESHOLD lines
  Status: $(check_rotation_threshold "$notes_file")

Archive Status:
$(get_archive_stats "$index_file" | sed 's/^/  /')

Recent Rotations:
$(if command -v jq &>/dev/null && [[ -f "$index_file" ]]; then
    jq -r '.archives[-5:] | reverse | .[] | "  - \(.timestamp): \(.original_size) -> \(.archived_size) lines (\(.agent))"' "$index_file" 2>/dev/null
else
    echo "  (Archive history not available)"
fi)

Configuration:
  Max archive entries: $MAX_ARCHIVE_ENTRIES
  Archive header lines: $NOTES_ARCHIVE_HEADER_LINES
  Score thresholds:
    - Critical: $SCORE_CRITICAL
    - Important: $SCORE_IMPORTANT
    - Normal: $SCORE_NORMAL
    - Temporary penalty: $SCORE_TEMPORARY_PENALTY
EOF

    return 0
}

# ==============================================================================
# Interactive Functions
# ==============================================================================

# Interactive rotation with confirmation
interactive_rotation() {
    local notes_file="$1"
    local agent="${2:-unknown}"

    export CURRENT_AGENT="$agent"

    # Generate and display report
    local archive_dir
    archive_dir="$(dirname "$notes_file")/archives"
    generate_rotation_report "$notes_file" "$archive_dir"

    # Check if rotation is needed
    local rotation_status
    rotation_status=$(check_rotation_threshold "$notes_file")

    if [[ "$rotation_status" == "rotation_needed" ]]; then
        echo
        echo "Rotation is recommended. Proceed? (y/n)"
        read -r response

        if [[ "$response" =~ ^[Yy]$ ]]; then
            rotate_notes_if_needed "$notes_file" "$agent"
        else
            log_info "Rotation cancelled by user"
            return 0
        fi
    else
        echo
        echo "No rotation needed at this time."
    fi

    return 0
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Export all rotation functions for use by other modules
export -f perform_intelligent_rotation rotate_notes_if_needed
export -f batch_rotate_notes
export -f recover_from_failed_rotation verify_rotation_integrity
export -f generate_rotation_report interactive_rotation