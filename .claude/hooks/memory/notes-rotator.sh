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
    local score=0

    if [[ ! -f "$file" ]]; then
        echo "0"
        return 0
    fi

    # Count critical keywords - very high priority
    local critical_count
    critical_count=$(grep -cE "$CRITICAL_PATTERNS" "$file" 2>/dev/null || echo 0)
    critical_count=$(echo "$critical_count" | tr -d '\n' | awk '{print $1}')
    if [ "$critical_count" -gt 0 ]; then
        # Critical content gets high base score
        score=$((score + 80))
    fi

    # Count important keywords - high priority
    local important_count
    important_count=$(grep -cE "$IMPORTANT_PATTERNS" "$file" 2>/dev/null || echo 0)
    important_count=$(echo "$important_count" | tr -d '\n' | awk '{print $1}')
    if [ "$important_count" -gt 0 ]; then
        # TODO and ADR patterns get high scores
        score=$((score + 70))
    fi

    # Count temporary keywords (reduce score)
    local temp_count
    temp_count=$(grep -cE "$TEMPORARY_PATTERNS" "$file" 2>/dev/null || echo 0)
    temp_count=$(echo "$temp_count" | tr -d '\n' | awk '{print $1}')
    if [ "$temp_count" -gt 0 ]; then
        score=$((score - 10))
    fi

    # Count normal keywords - moderate priority
    local normal_count
    normal_count=$(grep -cE "$NORMAL_PATTERNS" "$file" 2>/dev/null || echo 0)
    normal_count=$(echo "$normal_count" | tr -d '\n' | awk '{print $1}')
    if [ "$normal_count" -gt 0 ]; then
        # Normal content gets moderate score
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

    # Append to index using jq
    if command -v jq &>/dev/null; then
        local temp_index
        temp_index=$(mktemp)
        jq --argjson entry "$new_entry" '.archives += [$entry]' "$index_file" > "$temp_index"
        mv "$temp_index" "$index_file"
    else
        # Fallback: Simple append without jq
        sed -i 's/]$/,'"$new_entry"']/' "$index_file"
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