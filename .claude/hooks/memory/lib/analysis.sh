#!/bin/bash
# analysis.sh - Content analysis and scoring functions for notes rotation system
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
# Content Analysis Functions
# ==============================================================================

# Check if rotation is needed based on line count
check_rotation_threshold() {
    local notes_file="$1"

    # Handle missing file
    if [[ ! -f "$notes_file" ]]; then
        log_debug "Notes file does not exist: $notes_file"
        echo "no_rotation_needed"
        return 0
    fi

    local line_count
    line_count=$(wc -l < "$notes_file" 2>/dev/null || echo "0")
    line_count=$(sanitize_number "$line_count" "0")

    log_debug "Current line count: $line_count, threshold: $NOTES_ROTATION_THRESHOLD"

    if [[ "$line_count" -gt "$NOTES_ROTATION_THRESHOLD" ]]; then
        log_info "Rotation needed: $line_count lines > $NOTES_ROTATION_THRESHOLD threshold"
        echo "rotation_needed"
    else
        log_debug "No rotation needed: $line_count lines <= $NOTES_ROTATION_THRESHOLD threshold"
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

    local start_ns
    start_ns=$(start_timer)

    # Count different pattern types using the unified function
    local critical_count important_count temp_count normal_count
    critical_count=$(count_pattern_matches "$file" "$CRITICAL_PATTERNS")
    important_count=$(count_pattern_matches "$file" "$IMPORTANT_PATTERNS")
    temp_count=$(count_pattern_matches "$file" "$TEMPORARY_PATTERNS")
    normal_count=$(count_pattern_matches "$file" "$NORMAL_PATTERNS")

    # Calculate final importance score
    local score
    score=$(calculate_importance_score "$critical_count" "$important_count" "$temp_count" "$normal_count")

    # Check performance
    check_performance "$start_ns" "$MAX_PROCESSING_TIME_NS"

    log_debug "Content importance score: $score (critical:$critical_count, important:$important_count, temp:$temp_count, normal:$normal_count)"
    echo "$score"
    return 0
}

# Calculate importance score based on pattern match counts
calculate_importance_score() {
    local critical_count="$1"
    local important_count="$2"
    local temp_count="$3"
    local normal_count="$4"
    local score=0

    # Sanitize inputs
    critical_count=$(sanitize_number "$critical_count" "0")
    important_count=$(sanitize_number "$important_count" "0")
    temp_count=$(sanitize_number "$temp_count" "0")
    normal_count=$(sanitize_number "$normal_count" "0")

    # Critical content gets high base score
    if [ "$critical_count" -gt 0 ]; then
        score=$((score + SCORE_CRITICAL))
        log_debug "Added critical score: +$SCORE_CRITICAL"
    fi

    # Important content gets high score
    if [ "$important_count" -gt 0 ]; then
        score=$((score + SCORE_IMPORTANT))
        log_debug "Added important score: +$SCORE_IMPORTANT"
    fi

    # Temporary content reduces score
    if [ "$temp_count" -gt 0 ]; then
        score=$((score - SCORE_TEMPORARY_PENALTY))
        log_debug "Applied temporary penalty: -$SCORE_TEMPORARY_PENALTY"
    fi

    # Normal content gets moderate score
    if [ "$normal_count" -gt 0 ]; then
        score=$((score + SCORE_NORMAL))
        log_debug "Added normal score: +$SCORE_NORMAL"
    fi

    # Ensure score is within bounds
    if [ "$score" -lt "$SCORE_MIN" ]; then
        score=$SCORE_MIN
        log_debug "Score clamped to minimum: $SCORE_MIN"
    elif [ "$score" -gt "$SCORE_MAX" ]; then
        score=$SCORE_MAX
        log_debug "Score clamped to maximum: $SCORE_MAX"
    fi

    echo "$score"
    return 0
}

# ==============================================================================
# Content Classification Functions
# ==============================================================================

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

# Classify entire file content and generate statistics
classify_file_content() {
    local file="$1"

    if ! validate_content_file "$file"; then
        echo "Unable to classify: file invalid"
        return 1
    fi

    local critical_count=0
    local important_count=0
    local temporary_count=0
    local normal_count=0
    local total_count=0

    while IFS= read -r line; do
        ((total_count++))
        local category
        category=$(echo "$line" | classify_content)

        case "$category" in
            CRITICAL)
                ((critical_count++))
                ;;
            IMPORTANT)
                ((important_count++))
                ;;
            TEMPORARY)
                ((temporary_count++))
                ;;
            NORMAL)
                ((normal_count++))
                ;;
        esac
    done < "$file"

    # Output statistics
    cat <<EOF
Content Classification Statistics:
  Total lines: $total_count
  Critical: $critical_count ($((critical_count * 100 / (total_count + 1)))%)
  Important: $important_count ($((important_count * 100 / (total_count + 1)))%)
  Temporary: $temporary_count ($((temporary_count * 100 / (total_count + 1)))%)
  Normal: $normal_count ($((normal_count * 100 / (total_count + 1)))%)
EOF

    return 0
}

# ==============================================================================
# Content Extraction Functions
# ==============================================================================

# Extract content by importance level
extract_by_importance() {
    local file="$1"
    local importance_level="$2"
    local limit="${3:-0}"

    if ! validate_content_file "$file"; then
        return 1
    fi

    local pattern
    case "$importance_level" in
        CRITICAL)
            pattern="$CRITICAL_PATTERNS"
            ;;
        IMPORTANT)
            pattern="$IMPORTANT_PATTERNS"
            ;;
        TEMPORARY)
            pattern="$TEMPORARY_PATTERNS"
            ;;
        NORMAL)
            pattern="$NORMAL_PATTERNS"
            ;;
        *)
            log_error "Unknown importance level: $importance_level"
            return 1
            ;;
    esac

    extract_matching_lines "$file" "$pattern" "$limit"
}

# Generate content summary
generate_content_summary() {
    local file="$1"
    local max_lines="${2:-10}"

    if ! validate_content_file "$file"; then
        echo "Unable to generate summary: file invalid"
        return 1
    fi

    local total_lines
    total_lines=$(wc -l < "$file" 2>/dev/null || echo "0")

    local critical_count important_count
    critical_count=$(count_pattern_matches "$file" "$CRITICAL_PATTERNS")
    important_count=$(count_pattern_matches "$file" "$IMPORTANT_PATTERNS")

    cat <<EOF
=== Content Summary ===
File: $(basename "$file")
Total Lines: $total_lines
Critical Items: $critical_count
Important Items: $important_count
Importance Score: $(analyze_content_importance "$file")

Recent Critical Content (max $max_lines lines):
$(extract_by_importance "$file" "CRITICAL" "$max_lines")

Recent Important Content (max $max_lines lines):
$(extract_by_importance "$file" "IMPORTANT" "$max_lines")
EOF

    return 0
}

# ==============================================================================
# Batch Analysis Functions
# ==============================================================================

# Analyze multiple files in batch
batch_analyze_files() {
    local -a files=("$@")
    local batch_start_ns
    batch_start_ns=$(start_timer)

    local results=()
    local file_count=0
    local processed_count=0

    for file in "${files[@]}"; do
        ((file_count++))

        if (( file_count % BATCH_SIZE == 0 )); then
            log_info "Processing batch: $file_count/$((${#files[@]}))"
            check_performance "$batch_start_ns" "$MAX_PROCESSING_TIME_NS"
        fi

        if validate_content_file "$file"; then
            local score
            score=$(analyze_content_importance "$file")
            results+=("$file:$score")
            ((processed_count++))
        else
            log_warn "Skipping invalid file: $file"
        fi
    done

    # Output results
    echo "Batch Analysis Results:"
    echo "  Files processed: $processed_count/$file_count"
    echo "  Results:"

    # Sort results by score (descending)
    printf '%s\n' "${results[@]}" | sort -t':' -k2 -rn | while IFS=':' read -r file score; do
        echo "    $(basename "$file"): Score $score"
    done

    return 0
}

# ==============================================================================
# Performance Analysis Functions
# ==============================================================================

# Analyze performance characteristics of content processing
analyze_performance() {
    local file="$1"

    if ! validate_content_file "$file"; then
        echo "Unable to analyze performance: file invalid"
        return 1
    fi

    local start_ns elapsed_ns
    local operations=()

    # Test pattern matching performance
    start_ns=$(start_timer)
    count_pattern_matches "$file" "$CRITICAL_PATTERNS" >/dev/null
    elapsed_ns=$(get_elapsed_ns "$start_ns")
    operations+=("Critical pattern scan: $((elapsed_ns / 1000000))ms")

    start_ns=$(start_timer)
    count_pattern_matches "$file" "$IMPORTANT_PATTERNS" >/dev/null
    elapsed_ns=$(get_elapsed_ns "$start_ns")
    operations+=("Important pattern scan: $((elapsed_ns / 1000000))ms")

    # Test full analysis
    start_ns=$(start_timer)
    analyze_content_importance "$file" >/dev/null
    elapsed_ns=$(get_elapsed_ns "$start_ns")
    operations+=("Full importance analysis: $((elapsed_ns / 1000000))ms")

    # Output performance report
    echo "Performance Analysis Report:"
    echo "  File: $(basename "$file")"
    echo "  Size: $(wc -l < "$file") lines"
    echo "  Operations:"
    printf '    %s\n' "${operations[@]}"

    return 0
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Export all analysis functions for use by other modules
export -f check_rotation_threshold
export -f analyze_content_importance calculate_importance_score
export -f classify_content classify_file_content
export -f extract_by_importance generate_content_summary
export -f batch_analyze_files analyze_performance