#!/bin/bash

# notes-rotator.sh - Memory Bank intelligent rotation system
# TDD Green Phase implementation - minimal code to pass tests
# Created: 2025-09-16

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/hook-common.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/json-utils.sh" 2>/dev/null || true

# ==============================================================================
# Configuration Constants
# ==============================================================================

# Default rotation threshold
readonly NOTES_ROTATION_THRESHOLD="${NOTES_ROTATION_THRESHOLD:-450}"
readonly NOTES_ARCHIVE_HEADER_LINES="${NOTES_ARCHIVE_HEADER_LINES:-40}"

# Importance scoring weights
readonly KEYWORD_WEIGHT="${KEYWORD_WEIGHT:-25}"
readonly RECENCY_WEIGHT="${RECENCY_WEIGHT:-20}"
readonly FORMAT_WEIGHT="${FORMAT_WEIGHT:-15}"
readonly CONTEXT_WEIGHT="${CONTEXT_WEIGHT:-20}"
readonly FREQUENCY_WEIGHT="${FREQUENCY_WEIGHT:-10}"
readonly AGENT_WEIGHT="${AGENT_WEIGHT:-10}"

# Content category patterns
readonly CRITICAL_PATTERNS="ERROR:|CRITICAL:|SECURITY:|🔴"
readonly IMPORTANT_PATTERNS="TODO:|DECISION:|ADR-|⚠️"
readonly NORMAL_PATTERNS="INFO:|DEBUG:|TRACE:"
readonly TEMPORARY_PATTERNS="TEMP:|TEST:|SCRATCH:"

# ==============================================================================
# Core Functions
# ==============================================================================

# Validate that a content file exists and is readable
validate_content_file() {
    local file="$1"

    if [[ -z "$file" ]]; then
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        return 1
    fi

    return 0
}

# Count pattern matches in a file - extracted for reusability
count_pattern_matches() {
    local file="$1"
    local pattern="$2"

    if ! validate_content_file "$file"; then
        echo "0"
        return 0
    fi

    local count
    count=$(grep -cE "$pattern" "$file" 2>/dev/null || echo 0)
    count=$(echo "$count" | tr -d '\n' | awk '{print $1}')
    echo "$count"
    return 0
}

# Calculate importance score based on pattern match counts
calculate_importance_score() {
    local critical_count="$1"
    local important_count="$2"
    local temp_count="$3"
    local normal_count="$4"
    local score=0

    # Critical content gets high base score
    if [ "$critical_count" -gt 0 ]; then
        score=$((score + 80))
    fi

    # Important content gets high score
    if [ "$important_count" -gt 0 ]; then
        score=$((score + 70))
    fi

    # Temporary content reduces score
    if [ "$temp_count" -gt 0 ]; then
        score=$((score - 10))
    fi

    # Normal content gets moderate score
    if [ "$normal_count" -gt 0 ]; then
        score=$((score + 30))
    fi

    # Ensure score is within bounds
    if [ "$score" -lt 0 ]; then
        score=0
    elif [ "$score" -gt 100 ]; then
        score=100
    fi

    echo "$score"
    return 0
}

# Check if rotation is needed based on line count
check_rotation_threshold() {
    local notes_file="$1"

    # Handle missing file
    if [[ ! -f "$notes_file" ]]; then
        echo "no_rotation_needed"
        return 0
    fi

    local line_count
    line_count=$(wc -l < "$notes_file" 2>/dev/null || echo "0")

    if [[ "$line_count" -gt "$NOTES_ROTATION_THRESHOLD" ]]; then
        echo "rotation_needed"
    else
        echo "no_rotation_needed"
    fi

    return 0
}

# Analyze content importance and return a score (0-100)
analyze_content_importance() {
    local file="$1"

    # Validate input file first
    if ! validate_content_file "$file"; then
        echo "0"
        return 0
    fi

    # Count different pattern types using the unified function
    local critical_count important_count temp_count normal_count
    critical_count=$(count_pattern_matches "$file" "$CRITICAL_PATTERNS")
    important_count=$(count_pattern_matches "$file" "$IMPORTANT_PATTERNS")
    temp_count=$(count_pattern_matches "$file" "$TEMPORARY_PATTERNS")
    normal_count=$(count_pattern_matches "$file" "$NORMAL_PATTERNS")

    # Calculate final importance score using the extracted function
    calculate_importance_score "$critical_count" "$important_count" "$temp_count" "$normal_count"
}

# Classify content into categories
classify_content() {
    local line
    IFS= read -r line

    # Check patterns in priority order
    if echo "$line" | grep -qE "$CRITICAL_PATTERNS"; then
        echo "CRITICAL"
    elif echo "$line" | grep -qE "$IMPORTANT_PATTERNS"; then
        echo "IMPORTANT"
    elif echo "$line" | grep -qE "$TEMPORARY_PATTERNS"; then
        echo "TEMPORARY"
    else
        echo "NORMAL"
    fi

    return 0
}

# Create an archive of the current notes file
create_archive() {
    local notes_file="$1"
    local archive_dir="$2"

    if [[ ! -f "$notes_file" ]]; then
        return 1
    fi

    # Create archive directory if needed
    mkdir -p "$archive_dir"

    # Generate timestamp
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local archive_file="${archive_dir}/${timestamp}-notes.md"

    # Create archive with metadata header
    {
        echo "# Archived Notes"
        echo "Archive Date: $(date -Iseconds)"
        echo "Original Size: $(wc -l < "$notes_file") lines"
        echo "Rotation Reason: Size threshold exceeded"
        echo "---"
        echo
        cat "$notes_file"
    } > "$archive_file"

    # Preserve permissions
    chmod 644 "$archive_file"

    return 0
}

# Update the archive index with metadata
update_archive_index() {
    local archive_dir="$1"
    local archive_file="$2"
    local agent="$3"
    local original_size="$4"
    local archived_size="$5"

    local index_file="${archive_dir}/archive_index.json"

    # Create initial index if it doesn't exist
    if [[ ! -f "$index_file" ]]; then
        echo '{"archives": []}' > "$index_file"
    fi

    # Extract keywords from archive file
    local keywords=""
    if [[ -f "$archive_file" ]]; then
        keywords=$(grep -oE "(TODO|ERROR|CRITICAL|INFO|DEBUG)" "$archive_file" 2>/dev/null | \
                  sort -u | tr '\n' ',' | sed 's/,$//')
    fi

    # Create new entry
    local timestamp
    timestamp=$(date -Iseconds)
    local new_entry=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "agent": "$agent",
    "original_size": $original_size,
    "archived_size": $archived_size,
    "archive_file": "$(basename "$archive_file")",
    "content_summary": "Archive created from rotation",
    "keywords": ["${keywords//,/\",\"}"]
}
EOF
    )

    # Use safe JSON append function
    if command -v jq &>/dev/null; then
        local temp_index
        temp_index=$(mktemp)
        jq --argjson entry "$new_entry" '.archives += [$entry]' "$index_file" > "$temp_index"
        mv "$temp_index" "$index_file"
    else
        # Use our safe append function for non-jq environments
        json_safe_append "$index_file" "$new_entry"
    fi

    return 0
}

# Perform intelligent rotation
perform_intelligent_rotation() {
    local notes_file="$1"
    local archive_dir="$2"

    # Validate inputs
    if [[ ! -f "$notes_file" ]]; then
        return 1
    fi

    # Create backup before any modifications
    local backup_file="${notes_file}.backup"
    cp "$notes_file" "$backup_file" 2>/dev/null || return 1

    # Check for forced failure (for testing)
    if [[ -n "${FORCE_ROTATION_FAILURE:-}" ]]; then
        rm -f "$backup_file"
        return 1
    fi

    # Create archive first
    create_archive "$notes_file" "$archive_dir" || {
        rm -f "$backup_file"
        return 1
    }

    # Check for custom configuration
    if [[ -n "${ROTATION_CONFIG:-}" ]]; then
        # Parse configuration from environment
        local min_important_lines=$(echo "$ROTATION_CONFIG" | grep -o '"min_important_lines": *[0-9]*' | grep -o '[0-9]*' || echo "100")
    else
        local min_important_lines=100
    fi

    # Analyze content and preserve important lines
    local temp_file
    temp_file=$(mktemp)

    # Extract and preserve critical and important content
    {
        echo "# Agent Notes - Intelligent Rotation Applied"
        echo "Rotation Date: $(date -Iseconds)"
        echo "---"
        echo

        # Preserve critical content
        grep -E "$CRITICAL_PATTERNS" "$notes_file" 2>/dev/null || true

        # Preserve important content with limit
        if [[ -n "${ROTATION_CONFIG:-}" ]]; then
            grep -E "$IMPORTANT_PATTERNS" "$notes_file" 2>/dev/null | head -n "$min_important_lines" || true
        else
            grep -E "$IMPORTANT_PATTERNS" "$notes_file" 2>/dev/null || true
        fi

        # Add summary section
        echo
        echo "=== Archived Content Summary ==="
        echo "Older content has been archived for reference."
        echo "Archive location: ${archive_dir}"

    } > "$temp_file"

    # Replace original file
    mv "$temp_file" "$notes_file" || {
        rm -f "$temp_file"
        rm -f "$backup_file"
        return 1
    }

    # Update index
    local original_lines
    original_lines=$(wc -l < "$backup_file" 2>/dev/null || echo "0")
    local new_lines
    new_lines=$(wc -l < "$notes_file" 2>/dev/null || echo "0")

    update_archive_index "$archive_dir" "$notes_file" "${CURRENT_AGENT:-unknown}" \
                         "$original_lines" "$new_lines"

    # Clean up backup
    rm -f "$backup_file"

    return 0
}

# Main rotation function to be called from agent-switch
rotate_notes_if_needed() {
    local notes_file="$1"
    local agent="${2:-unknown}"

    export CURRENT_AGENT="$agent"

    # Get archive directory
    local archive_dir
    archive_dir="$(dirname "$notes_file")/archives"

    # Check if rotation is needed
    local rotation_status
    rotation_status=$(check_rotation_threshold "$notes_file")

    if [[ "$rotation_status" == "rotation_needed" ]]; then
        # Perform intelligent rotation
        perform_intelligent_rotation "$notes_file" "$archive_dir"
        return $?
    fi

    return 0
}

# ==============================================================================
# Archive Search Functions
# ==============================================================================

# Search archives by keywords
search_archives() {
    local index_file="$1"
    local search_term="$2"

    if [[ ! -f "$index_file" ]]; then
        echo "No archive index found"
        return 1
    fi

    # Use jq if available for more accurate search
    if command -v jq &>/dev/null; then
        jq -r ".archives[] | select(.keywords[] | contains(\"$search_term\")) | \"\(.timestamp) - \(.archive_file) - Keywords: \(.keywords | join(\",\"))\"" "$index_file" 2>/dev/null || echo "No matches found"
    else
        # Fallback to grep-based search
        grep -i "$search_term" "$index_file" 2>/dev/null | sed 's/.*"archive_file":"\([^"]*\)".*"timestamp":"\([^"]*\)".*/\2 - \1/' || echo "No matches found"
    fi
}

# Get archive count
get_archive_count() {
    local index_file="$1"

    if [[ ! -f "$index_file" ]]; then
        echo "0"
        return 0
    fi

    if command -v jq &>/dev/null; then
        jq '.archives | length' "$index_file" 2>/dev/null || echo "0"
    else
        # Count occurrences of archive_file
        grep -c '"archive_file"' "$index_file" 2>/dev/null || echo "0"
    fi
}

# Safe JSON append without jq
json_safe_append() {
    local index_file="$1"
    local new_entry="$2"
    local temp_file
    temp_file=$(mktemp)

    if [[ ! -f "$index_file" ]]; then
        echo '{"archives": []}' > "$index_file"
    fi

    # Create backup before modification
    cp "$index_file" "${index_file}.bak" 2>/dev/null || true

    # Remove the closing }] and append new entry
    if grep -q '"archives": \[\]' "$index_file"; then
        # Empty array - add first entry
        sed 's/"archives": \[\]/"archives": ['"$new_entry"']/' "$index_file" > "$temp_file"
    else
        # Non-empty array - append to existing entries
        sed 's/\]\s*}$/,'"$new_entry"']}/' "$index_file" > "$temp_file"
    fi

    # Verify the JSON structure is not broken
    if grep -q '"archives"' "$temp_file" && grep -q '^{' "$temp_file" && grep -q '}$' "$temp_file"; then
        mv "$temp_file" "$index_file"
        rm -f "${index_file}.bak"
        return 0
    else
        # Restore backup if JSON is broken
        mv "${index_file}.bak" "$index_file" 2>/dev/null || true
        rm -f "$temp_file"
        return 1
    fi
}

# ==============================================================================
# Index Optimization Functions
# ==============================================================================

# Clean up old archive entries (keep recent N entries)
cleanup_old_archives() {
    local index_file="$1"
    local max_entries="${2:-100}"  # Keep latest 100 entries by default

    if [[ ! -f "$index_file" ]]; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        # Use jq to keep only the latest N entries
        local temp_file
        temp_file=$(mktemp)
        jq ".archives |= .[-$max_entries:]" "$index_file" > "$temp_file"
        mv "$temp_file" "$index_file"
    else
        # Fallback: Create new file with limited entries
        echo "WARNING: Archive cleanup requires jq for reliable operation" >&2
    fi
}

# Optimize index file (remove duplicates, sort by date)
optimize_archive_index() {
    local index_file="$1"

    if [[ ! -f "$index_file" ]]; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        local temp_file
        temp_file=$(mktemp)
        # Sort by timestamp and remove duplicates based on archive_file
        jq '.archives |= (unique_by(.archive_file) | sort_by(.timestamp))' "$index_file" > "$temp_file"
        mv "$temp_file" "$index_file"
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
            while read count keyword; do
                echo "    - $keyword: $count occurrences"
            done
    fi
}

# ==============================================================================
# Main Execution (for standalone testing)
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly (not sourced)
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <notes_file> [agent_name]"
        exit 1
    fi

    rotate_notes_if_needed "$1" "${2:-unknown}"
    exit $?
fi