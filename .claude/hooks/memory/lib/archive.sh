#!/bin/bash
# archive.sh - Archive management functions for notes rotation system
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

# ==============================================================================
# Archive Creation Functions
# ==============================================================================

# Create an archive of the current notes file
create_archive() {
    local notes_file="$1"
    local archive_dir="$2"

    if ! validate_content_file "$notes_file"; then
        log_error "Invalid notes file: $notes_file"
        return 1
    fi

    # Create archive directory if needed
    if ! validate_directory "$archive_dir"; then
        log_error "Failed to validate archive directory: $archive_dir"
        return 1
    fi

    # Generate archive filename
    local timestamp
    timestamp=$(get_file_date "$ARCHIVE_DATE_FORMAT")
    local archive_file="${archive_dir}/${timestamp}-notes.md"

    # Get file statistics
    local line_count
    line_count=$(wc -l < "$notes_file" 2>/dev/null || echo "0")
    local file_size
    file_size=$(stat -f%z "$notes_file" 2>/dev/null || stat -c%s "$notes_file" 2>/dev/null || echo "0")

    # Create archive with metadata header
    {
        echo "# Archived Notes"
        echo "Archive Date: $(get_timestamp)"
        echo "Original Size: ${line_count} lines (${file_size} bytes)"
        echo "Rotation Reason: Size threshold exceeded (>${NOTES_ROTATION_THRESHOLD} lines)"
        echo "Agent: ${CURRENT_AGENT:-unknown}"
        echo "---"
        echo
        cat "$notes_file"
    } > "$archive_file"

    # Preserve permissions
    chmod 644 "$archive_file"

    log_info "Archive created: $archive_file (${line_count} lines)"
    echo "$archive_file"
    return 0
}

# Extract important content for preservation
extract_important_content() {
    local notes_file="$1"
    local min_important_lines="${2:-100}"
    local config="${3:-}"

    if ! validate_content_file "$notes_file"; then
        log_error "Invalid notes file: $notes_file"
        return 1
    fi

    local temp_file
    if ! temp_file=$(create_temp_file "extract"); then
        return 1
    fi
    register_temp_file "$temp_file"

    {
        echo "# Agent Notes - Intelligent Rotation Applied"
        echo "Rotation Date: $(get_timestamp)"
        echo "Agent: ${CURRENT_AGENT:-unknown}"
        echo "---"
        echo

        # Preserve critical content (all)
        local critical_lines
        critical_lines=$(extract_matching_lines "$notes_file" "$CRITICAL_PATTERNS" 0)
        if [[ -n "$critical_lines" ]]; then
            echo "## Critical Content (Preserved)"
            echo "$critical_lines"
            echo
        fi

        # Preserve important content (with limit)
        local important_lines
        if [[ -n "$config" ]]; then
            # Parse custom configuration
            local custom_limit
            custom_limit=$(echo "$config" | grep -o '"min_important_lines": *[0-9]*' | grep -o '[0-9]*' || echo "$min_important_lines")
            important_lines=$(extract_matching_lines "$notes_file" "$IMPORTANT_PATTERNS" "$custom_limit")
        else
            important_lines=$(extract_matching_lines "$notes_file" "$IMPORTANT_PATTERNS" "$min_important_lines")
        fi

        if [[ -n "$important_lines" ]]; then
            echo "## Important Content (Limited to ${min_important_lines} lines)"
            echo "$important_lines"
            echo
        fi

        # Add summary section
        generate_rotation_summary "$archive_dir"

    } > "$temp_file"

    echo "$temp_file"
    return 0
}

# Generate rotation summary
generate_rotation_summary() {
    local archive_dir="${1:-archives}"

    cat <<EOF

=== Archived Content Summary ===
Older content has been archived for reference.
Archive location: ${archive_dir}
Archive count: $(get_archive_count "${archive_dir}/${ARCHIVE_INDEX_FILENAME}")
Last rotation: $(get_timestamp)
EOF
}

# ==============================================================================
# Archive Index Management
# ==============================================================================

# Initialize archive index if it doesn't exist
init_archive_index() {
    local index_file="$1"

    if [[ ! -f "$index_file" ]]; then
        local index_dir
        index_dir=$(dirname "$index_file")
        if ! validate_directory "$index_dir"; then
            return 1
        fi

        echo '{"archives": [], "metadata": {"version": "2.0.0", "created": "'"$(get_timestamp)"'"}}' > "$index_file"
        log_info "Archive index initialized: $index_file"
    fi

    return 0
}

# Update the archive index with metadata
update_archive_index() {
    local archive_dir="$1"
    local archive_file="$2"
    local agent="${3:-unknown}"
    local original_size="${4:-0}"
    local archived_size="${5:-0}"

    local index_file="${archive_dir}/${ARCHIVE_INDEX_FILENAME}"

    # Initialize index if needed
    if ! init_archive_index "$index_file"; then
        log_error "Failed to initialize archive index"
        return 1
    fi

    # Extract keywords from archive file
    local keywords=""
    if [[ -f "$archive_file" ]]; then
        keywords=$(grep -oE "(TODO|ERROR|CRITICAL|IMPORTANT|INFO|DEBUG|WARNING)" "$archive_file" 2>/dev/null | \
                  sort -u | head -10 | tr '\n' ',' | sed 's/,$//')
    fi

    # Calculate content statistics
    local critical_count important_count
    critical_count=$(count_pattern_matches "$archive_file" "$CRITICAL_PATTERNS")
    important_count=$(count_pattern_matches "$archive_file" "$IMPORTANT_PATTERNS")

    # Create new entry
    local timestamp
    timestamp=$(get_timestamp)
    local new_entry
    new_entry=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "agent": "$agent",
    "original_size": $original_size,
    "archived_size": $archived_size,
    "archive_file": "$(basename "$archive_file")",
    "content_summary": {
        "critical_items": $critical_count,
        "important_items": $important_count,
        "rotation_reason": "size_threshold"
    },
    "keywords": [$(echo "$keywords" | sed 's/\([^,]*\)/"\1"/g')]
}
EOF
    )

    # Append to index using safe method
    if command -v jq &>/dev/null; then
        local temp_index
        temp_index=$(create_temp_file "index")
        register_temp_file "$temp_index"

        if jq --argjson entry "$new_entry" '.archives += [$entry]' "$index_file" > "$temp_index"; then
            mv "$temp_index" "$index_file"
            log_info "Archive index updated with new entry"
        else
            log_error "Failed to update archive index with jq"
            return 1
        fi
    else
        # Fallback to safe append without jq
        if json_safe_append "$index_file" "$new_entry"; then
            log_info "Archive index updated (non-jq method)"
        else
            log_error "Failed to update archive index"
            return 1
        fi
    fi

    return 0
}

# Safe JSON append without jq
json_safe_append() {
    local index_file="$1"
    local new_entry="$2"

    local temp_file
    temp_file=$(create_temp_file "json")
    register_temp_file "$temp_file"

    if [[ ! -f "$index_file" ]]; then
        init_archive_index "$index_file"
    fi

    # Create backup
    local backup_file="${index_file}.bak"
    cp "$index_file" "$backup_file" 2>/dev/null || true
    register_backup_file "$backup_file"

    # Append new entry
    if grep -q '"archives": \[\]' "$index_file"; then
        # Empty array - add first entry
        sed 's/"archives": \[\]/"archives": ['"$new_entry"']/' "$index_file" > "$temp_file"
    else
        # Non-empty array - append to existing entries
        sed 's/\]\s*}$/,'"$new_entry"']}/' "$index_file" > "$temp_file"
    fi

    # Verify JSON structure
    if grep -q '"archives"' "$temp_file" && grep -q '^{' "$temp_file" && grep -q '}$' "$temp_file"; then
        mv "$temp_file" "$index_file"
        rm -f "$backup_file"
        return 0
    else
        # Restore backup on failure
        mv "$backup_file" "$index_file" 2>/dev/null || true
        log_error "JSON structure validation failed"
        return 1
    fi
}

# ==============================================================================
# Archive Query Functions
# ==============================================================================

# Get archive count
get_archive_count() {
    local index_file="${1:-${ARCHIVE_INDEX_FILENAME}}"

    if [[ ! -f "$index_file" ]]; then
        echo "0"
        return 0
    fi

    if command -v jq &>/dev/null; then
        jq '.archives | length' "$index_file" 2>/dev/null || echo "0"
    else
        # Fallback: count occurrences of archive_file
        grep -c '"archive_file"' "$index_file" 2>/dev/null || echo "0"
    fi
}

# Search archives by keywords
search_archives() {
    local index_file="$1"
    local search_term="$2"

    if [[ ! -f "$index_file" ]]; then
        echo "No archive index found"
        return 1
    fi

    log_debug "Searching archives for: $search_term"

    if command -v jq &>/dev/null; then
        # Use jq for accurate search
        local results
        results=$(jq -r ".archives[] | select(.keywords[] | contains(\"$search_term\")) | \"\(.timestamp) - \(.archive_file) - Keywords: \(.keywords | join(\",\"))\"" "$index_file" 2>/dev/null)

        if [[ -z "$results" ]]; then
            echo "No matches found for: $search_term"
        else
            echo "$results"
        fi
    else
        # Fallback to grep-based search
        local matches
        matches=$(grep -i "$search_term" "$index_file" 2>/dev/null | sed 's/.*"archive_file":"\([^"]*\)".*"timestamp":"\([^"]*\)".*/\2 - \1/')

        if [[ -z "$matches" ]]; then
            echo "No matches found for: $search_term"
        else
            echo "$matches"
        fi
    fi
}

# Get archive statistics
get_archive_stats() {
    local index_file="$1"

    if [[ ! -f "$index_file" ]]; then
        echo "No archive index found"
        return 1
    fi

    local count
    count=$(get_archive_count "$index_file")
    local size
    size=$(du -h "$index_file" 2>/dev/null | cut -f1)

    echo "Archive Statistics:"
    echo "  Total entries: $count"
    echo "  Index size: $size"

    if command -v jq &>/dev/null; then
        # Get date range
        local oldest newest
        oldest=$(jq -r '.archives[0].timestamp // "N/A"' "$index_file" 2>/dev/null)
        newest=$(jq -r '.archives[-1].timestamp // "N/A"' "$index_file" 2>/dev/null)
        echo "  Date range: $oldest to $newest"

        # Get keyword frequency
        echo "  Top keywords:"
        jq -r '.archives[].keywords[]' "$index_file" 2>/dev/null | \
            sort | uniq -c | sort -rn | head -5 | \
            while read -r count keyword; do
                echo "    - $keyword: $count occurrences"
            done
    fi
}

# ==============================================================================
# Archive Maintenance Functions
# ==============================================================================

# Clean up old archive entries (keep recent N entries)
cleanup_old_archives() {
    local index_file="$1"
    local max_entries="${2:-${MAX_ARCHIVE_ENTRIES}}"

    if [[ ! -f "$index_file" ]]; then
        log_debug "No archive index to clean"
        return 0
    fi

    local current_count
    current_count=$(get_archive_count "$index_file")

    if (( current_count <= max_entries )); then
        log_debug "Archive count ($current_count) within limit ($max_entries)"
        return 0
    fi

    if command -v jq &>/dev/null; then
        local temp_file
        temp_file=$(create_temp_file "cleanup")
        register_temp_file "$temp_file"

        # Keep only the latest N entries
        if jq ".archives |= .[-$max_entries:]" "$index_file" > "$temp_file"; then
            mv "$temp_file" "$index_file"
            log_info "Archive cleanup: kept latest $max_entries entries (removed $((current_count - max_entries)))"
        else
            log_error "Failed to cleanup archives"
            return 1
        fi
    else
        log_warn "Archive cleanup requires jq for reliable operation"
    fi

    return 0
}

# Optimize archive index (remove duplicates, sort by date)
optimize_archive_index() {
    local index_file="$1"

    if [[ ! -f "$index_file" ]]; then
        log_debug "No archive index to optimize"
        return 0
    fi

    if command -v jq &>/dev/null; then
        local temp_file
        temp_file=$(create_temp_file "optimize")
        register_temp_file "$temp_file"

        # Sort by timestamp and remove duplicates based on archive_file
        if jq '.archives |= (unique_by(.archive_file) | sort_by(.timestamp))' "$index_file" > "$temp_file"; then
            mv "$temp_file" "$index_file"
            log_info "Archive index optimized"
        else
            log_error "Failed to optimize archive index"
            return 1
        fi
    else
        log_debug "Archive optimization requires jq"
    fi

    return 0
}

# Verify archive integrity
verify_archive_integrity() {
    local archive_dir="$1"
    local index_file="${archive_dir}/${ARCHIVE_INDEX_FILENAME}"

    if [[ ! -f "$index_file" ]]; then
        log_warn "No archive index to verify"
        return 0
    fi

    local missing_count=0
    local total_count=0

    if command -v jq &>/dev/null; then
        while IFS= read -r archive_file; do
            ((total_count++))
            if [[ ! -f "${archive_dir}/${archive_file}" ]]; then
                log_warn "Missing archive file: $archive_file"
                ((missing_count++))
            fi
        done < <(jq -r '.archives[].archive_file' "$index_file" 2>/dev/null)
    fi

    if (( missing_count > 0 )); then
        log_warn "Archive integrity check: $missing_count/$total_count files missing"
        return 1
    else
        log_info "Archive integrity check: all $total_count files present"
        return 0
    fi
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Export all archive functions for use by other modules
export -f create_archive extract_important_content generate_rotation_summary
export -f init_archive_index update_archive_index json_safe_append
export -f get_archive_count search_archives get_archive_stats
export -f cleanup_old_archives optimize_archive_index verify_archive_integrity
