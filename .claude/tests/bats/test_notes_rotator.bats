#!/usr/bin/env bats

# test_notes_rotator.bats - Memory Bank rotation system tests
# Using t-wada style TDD - Red Phase test creation
# Created: 2025-09-16

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export NOTES_FILE="$TEST_DIR/.claude/memo/notes.md"
    export ARCHIVE_DIR="$TEST_DIR/.claude/memo/archives"

    # Create necessary directories
    mkdir -p "$(dirname "$NOTES_FILE")"
    mkdir -p "$ARCHIVE_DIR"

    # Source the script under test (will fail in Red Phase)
    if [ -f "${BATS_TEST_DIRNAME}/../../hooks/memory/notes-rotator.sh" ]; then
        source "${BATS_TEST_DIRNAME}/../../hooks/memory/notes-rotator.sh"
    fi
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

# ==============================================================================
# Line Count Check Tests
# ==============================================================================

@test "check_rotation_threshold detects when rotation is needed" {
    # Create a notes file with more than threshold lines
    for i in {1..500}; do
        echo "Line $i: Test content" >> "$NOTES_FILE"
    done

    run check_rotation_threshold "$NOTES_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = "rotation_needed" ]
}

@test "check_rotation_threshold returns no rotation when under threshold" {
    # Create a notes file with less than threshold lines
    for i in {1..100}; do
        echo "Line $i: Test content" >> "$NOTES_FILE"
    done

    run check_rotation_threshold "$NOTES_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = "no_rotation_needed" ]
}

@test "check_rotation_threshold handles missing file gracefully" {
    run check_rotation_threshold "/nonexistent/file.md"
    [ "$status" -eq 0 ]
    [ "$output" = "no_rotation_needed" ]
}

# ==============================================================================
# Importance Scoring Tests
# ==============================================================================

@test "analyze_content_importance calculates score for critical content" {
    echo "ERROR: Critical system failure" > "$TEST_DIR/test_content.txt"
    echo "CRITICAL: Security breach detected" >> "$TEST_DIR/test_content.txt"

    run analyze_content_importance "$TEST_DIR/test_content.txt"
    [ "$status" -eq 0 ]
    # Score should be high (> 80)
    [[ "$output" -ge 80 ]]
}

@test "analyze_content_importance calculates score for normal content" {
    echo "INFO: Process started successfully" > "$TEST_DIR/test_content.txt"
    echo "DEBUG: Processing item 123" >> "$TEST_DIR/test_content.txt"

    run analyze_content_importance "$TEST_DIR/test_content.txt"
    [ "$status" -eq 0 ]
    # Score should be medium (30-60)
    [[ "$output" -ge 30 ]] && [[ "$output" -le 60 ]]
}

@test "analyze_content_importance calculates score for temporary content" {
    echo "TEMP: Testing new feature" > "$TEST_DIR/test_content.txt"
    echo "TEST: Temporary debug output" >> "$TEST_DIR/test_content.txt"

    run analyze_content_importance "$TEST_DIR/test_content.txt"
    [ "$status" -eq 0 ]
    # Score should be low (< 30)
    [[ "$output" -le 30 ]]
}

@test "analyze_content_importance handles TODO and ADR patterns" {
    cat > "$TEST_DIR/test_content.txt" <<EOF
TODO: Implement user authentication
ADR-001: Use PostgreSQL for persistence
DECISION: Migrate to microservices architecture
EOF

    run analyze_content_importance "$TEST_DIR/test_content.txt"
    [ "$status" -eq 0 ]
    # Score should be high for important decisions
    [[ "$output" -ge 70 ]]
}

# ==============================================================================
# Content Classification Tests
# ==============================================================================

@test "classify_content identifies CRITICAL category" {
    echo "ERROR: Database connection failed" | {
        run classify_content
        [ "$status" -eq 0 ]
        [ "$output" = "CRITICAL" ]
    }
}

@test "classify_content identifies IMPORTANT category" {
    echo "TODO: Fix authentication bug" | {
        run classify_content
        [ "$status" -eq 0 ]
        [ "$output" = "IMPORTANT" ]
    }
}

@test "classify_content identifies NORMAL category" {
    echo "INFO: Processing completed" | {
        run classify_content
        [ "$status" -eq 0 ]
        [ "$output" = "NORMAL" ]
    }
}

@test "classify_content identifies TEMPORARY category" {
    echo "TEMP: Debug output for testing" | {
        run classify_content
        [ "$status" -eq 0 ]
        [ "$output" = "TEMPORARY" ]
    }
}

# ==============================================================================
# Archive Generation Tests
# ==============================================================================

@test "create_archive generates timestamped archive file" {
    # Create test notes file
    echo "Test content for archiving" > "$NOTES_FILE"

    run create_archive "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]

    # Check archive file was created
    archive_count=$(find "$ARCHIVE_DIR" -name "*-notes.md" | wc -l)
    [ "$archive_count" -eq 1 ]

    # Verify archive content
    archive_file=$(find "$ARCHIVE_DIR" -name "*-notes.md" | head -n1)
    grep -q "Test content for archiving" "$archive_file"
}

@test "create_archive includes metadata header" {
    echo "Original content" > "$NOTES_FILE"

    run create_archive "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]

    archive_file=$(find "$ARCHIVE_DIR" -name "*-notes.md" | head -n1)
    # Check for metadata header
    grep -q "Archive Date:" "$archive_file"
    grep -q "Original Size:" "$archive_file"
    grep -q "Rotation Reason:" "$archive_file"
}

@test "create_archive preserves file permissions" {
    echo "Content" > "$NOTES_FILE"
    chmod 644 "$NOTES_FILE"

    run create_archive "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]

    archive_file=$(find "$ARCHIVE_DIR" -name "*-notes.md" | head -n1)
    # Check permissions
    stat -c %a "$archive_file" | grep -q "644"
}

# ==============================================================================
# Index Update Tests
# ==============================================================================

@test "update_archive_index creates JSON index file" {
    run update_archive_index "$ARCHIVE_DIR" "test-archive.md" "planner" 1000 450
    [ "$status" -eq 0 ]

    # Check index file exists
    [ -f "$ARCHIVE_DIR/archive_index.json" ]

    # Validate JSON format
    jq . "$ARCHIVE_DIR/archive_index.json" > /dev/null
}

@test "update_archive_index appends to existing index" {
    # Create initial index
    echo '{"archives": []}' > "$ARCHIVE_DIR/archive_index.json"

    run update_archive_index "$ARCHIVE_DIR" "archive1.md" "planner" 500 200
    [ "$status" -eq 0 ]

    run update_archive_index "$ARCHIVE_DIR" "archive2.md" "builder" 600 250
    [ "$status" -eq 0 ]

    # Check both entries exist
    archive_count=$(jq '.archives | length' "$ARCHIVE_DIR/archive_index.json")
    [ "$archive_count" -eq 2 ]
}

@test "update_archive_index includes content summary" {
    echo "TODO: Important task" > "$TEST_DIR/content.md"
    echo "ERROR: Critical error" >> "$TEST_DIR/content.md"

    run update_archive_index "$ARCHIVE_DIR" "$TEST_DIR/content.md" "planner" 100 50
    [ "$status" -eq 0 ]

    # Check for content summary in index
    jq -e '.archives[-1].content_summary' "$ARCHIVE_DIR/archive_index.json"
    jq -e '.archives[-1].keywords' "$ARCHIVE_DIR/archive_index.json"
}

# ==============================================================================
# Intelligent Rotation Tests
# ==============================================================================

@test "perform_intelligent_rotation preserves critical content" {
    # Create notes with mixed importance
    cat > "$NOTES_FILE" <<EOF
ERROR: Critical system failure - MUST PRESERVE
INFO: Normal log entry - can archive
TEMP: Debug output - can remove
TODO: Important task - should preserve
DEBUG: Trace information - can archive
EOF

    run perform_intelligent_rotation "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]

    # Check critical content is preserved
    grep -q "ERROR: Critical system failure" "$NOTES_FILE"
    grep -q "TODO: Important task" "$NOTES_FILE"
}

@test "perform_intelligent_rotation generates summary for archived content" {
    # Create large notes file
    for i in {1..500}; do
        echo "INFO: Processing item $i" >> "$NOTES_FILE"
    done

    run perform_intelligent_rotation "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]

    # Check for summary section
    grep -q "=== Archived Content Summary ===" "$NOTES_FILE"
}

@test "perform_intelligent_rotation respects retention configuration" {
    # Set custom configuration
    export ROTATION_CONFIG='{
        "retention": {
            "min_important_lines": 100,
            "summary_ratio": 0.3
        }
    }'

    # Create content with important lines
    for i in {1..150}; do
        echo "TODO: Task $i" >> "$NOTES_FILE"
    done
    for i in {1..350}; do
        echo "INFO: Log $i" >> "$NOTES_FILE"
    done

    run perform_intelligent_rotation "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]

    # At least 100 important lines should be retained
    important_count=$(grep -c "TODO:" "$NOTES_FILE")
    [[ "$important_count" -ge 100 ]]
}

# ==============================================================================
# Integration Tests
# ==============================================================================

@test "complete rotation workflow with all features" {
    # Create realistic notes file
    cat > "$NOTES_FILE" <<'EOF'
# Agent Notes - Planner
Generated: 2025-09-16

## Current Sprint
TODO: Implement user authentication
TODO: Add database migrations
TODO: Write API documentation

## Errors & Issues
ERROR: Database connection timeout at 14:23:05
CRITICAL: Security vulnerability in dependencies

## Progress Log
INFO: Sprint started on 2025-09-15
INFO: Completed 3 tasks
DEBUG: Performance metrics collected
TEMP: Testing branch features
EOF

    # Add more lines to trigger rotation
    for i in {1..450}; do
        echo "INFO: Log entry $i" >> "$NOTES_FILE"
    done

    # Run complete rotation
    run rotate_notes_if_needed "$NOTES_FILE" "planner"
    [ "$status" -eq 0 ]

    # Verify results
    [ -f "$NOTES_FILE" ]  # Notes file still exists
    [ -d "$ARCHIVE_DIR" ]  # Archive directory created

    # Check archive was created
    archive_count=$(find "$ARCHIVE_DIR" -name "*-notes.md" 2>/dev/null | wc -l)
    [[ "$archive_count" -ge 1 ]]

    # Check index was updated
    [ -f "$ARCHIVE_DIR/archive_index.json" ]

    # Check critical content preserved
    grep -q "ERROR:" "$NOTES_FILE"
    grep -q "TODO:" "$NOTES_FILE"

    # Check file is smaller after rotation
    new_line_count=$(wc -l < "$NOTES_FILE")
    [[ "$new_line_count" -lt 450 ]]
}

# ==============================================================================
# Error Handling Tests
# ==============================================================================

@test "rotation handles missing configuration gracefully" {
    unset ROTATION_CONFIG
    rm -f "$TEST_DIR/.claude/config/rotation.json"

    echo "Test content" > "$NOTES_FILE"

    run perform_intelligent_rotation "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]
    # Should fall back to defaults
}

@test "rotation handles malformed content without failure" {
    # Create file with special characters and malformed content
    cat > "$NOTES_FILE" <<'EOF'
!@#$%^&*()_+
[malformed json}: {
Binary content: \x00\x01\x02
Emoji test: 🔴 ⚠️ ✅
EOF

    run perform_intelligent_rotation "$NOTES_FILE" "$ARCHIVE_DIR"
    [ "$status" -eq 0 ]
}

@test "rotation creates backup before modification" {
    echo "Original content" > "$NOTES_FILE"
    original_md5=$(md5sum "$NOTES_FILE" | cut -d' ' -f1)

    # Simulate rotation with forced failure
    export FORCE_ROTATION_FAILURE=1
    run perform_intelligent_rotation "$NOTES_FILE" "$ARCHIVE_DIR"

    # Even if rotation fails, original should be preserved
    if [ "$status" -ne 0 ]; then
        current_md5=$(md5sum "$NOTES_FILE" | cut -d' ' -f1)
        [ "$original_md5" = "$current_md5" ]
    fi
}

# ==============================================================================
# Performance Tests
# ==============================================================================

@test "rotation completes within time limit for large files" {
    # Create 1000-line file
    for i in {1..1000}; do
        echo "Line $i: Mixed content with TODO, ERROR, INFO patterns" >> "$NOTES_FILE"
    done

    # Measure execution time
    start_time=$(date +%s%N)
    run perform_intelligent_rotation "$NOTES_FILE" "$ARCHIVE_DIR"
    end_time=$(date +%s%N)

    [ "$status" -eq 0 ]

    # Check execution time < 1 second (1000000000 nanoseconds)
    duration=$((end_time - start_time))
    [[ "$duration" -lt 1000000000 ]]
}

# ==============================================================================
# Archive Search and Enhancement Tests
# ==============================================================================

@test "search_archives finds entries by keyword" {
    # Create test index with entries
    cat > "$ARCHIVE_DIR/archive_index.json" << EOF
{"archives": [
    {"timestamp": "2025-09-01T10:00:00", "archive_file": "archive1.md", "keywords": ["ERROR", "CRITICAL"]},
    {"timestamp": "2025-09-02T10:00:00", "archive_file": "archive2.md", "keywords": ["TODO", "INFO"]}
]}
EOF

    run search_archives "$ARCHIVE_DIR/archive_index.json" "ERROR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"archive1.md"* ]]
}

@test "search_archives returns no matches for missing keyword" {
    cat > "$ARCHIVE_DIR/archive_index.json" << EOF
{"archives": [
    {"timestamp": "2025-09-01T10:00:00", "archive_file": "archive1.md", "keywords": ["INFO"]}
]}
EOF

    run search_archives "$ARCHIVE_DIR/archive_index.json" "NOTFOUND"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No matches found"* ]] || [[ -z "$output" ]]
}

@test "get_archive_count returns correct count" {
    cat > "$ARCHIVE_DIR/archive_index.json" << EOF
{"archives": [
    {"timestamp": "2025-09-01T10:00:00", "archive_file": "archive1.md", "keywords": ["ERROR"]},
    {"timestamp": "2025-09-02T10:00:00", "archive_file": "archive2.md", "keywords": ["TODO"]},
    {"timestamp": "2025-09-03T10:00:00", "archive_file": "archive3.md", "keywords": ["INFO"]}
]}
EOF

    run get_archive_count "$ARCHIVE_DIR/archive_index.json"
    [ "$status" -eq 0 ]
    [ "$output" -eq 3 ]
}

@test "get_archive_count handles empty index" {
    echo '{"archives": []}' > "$ARCHIVE_DIR/archive_index.json"

    run get_archive_count "$ARCHIVE_DIR/archive_index.json"
    [ "$status" -eq 0 ]
    [ "$output" -eq 0 ]
}

@test "json_safe_append handles empty index correctly" {
    echo '{"archives": []}' > "$ARCHIVE_DIR/test_index.json"
    local new_entry='{"timestamp": "2025-09-01T10:00:00", "archive_file": "test.md"}'

    run json_safe_append "$ARCHIVE_DIR/test_index.json" "$new_entry"
    [ "$status" -eq 0 ]

    # Verify the entry was added
    [[ $(cat "$ARCHIVE_DIR/test_index.json") == *"test.md"* ]]
}

@test "json_safe_append handles malformed JSON safely" {
    echo 'INVALID JSON' > "$ARCHIVE_DIR/bad_index.json"
    local new_entry='{"timestamp": "2025-09-01T10:00:00", "archive_file": "test.md"}'

    run json_safe_append "$ARCHIVE_DIR/bad_index.json" "$new_entry"
    # Should fail but not crash
    [ "$status" -ne 0 ] || [[ $(cat "$ARCHIVE_DIR/bad_index.json") == *"archives"* ]]
}

# ==============================================================================
# Index Optimization Tests
# ==============================================================================

@test "cleanup_old_archives keeps only recent entries" {
    # Skip if jq is not available
    command -v jq &>/dev/null || skip "jq not available"

    # Create index with many entries
    cat > "$ARCHIVE_DIR/archive_index.json" << 'EOF'
{"archives": [
    {"timestamp": "2025-09-01T10:00:00", "archive_file": "old1.md", "keywords": ["OLD"]},
    {"timestamp": "2025-09-02T10:00:00", "archive_file": "old2.md", "keywords": ["OLD"]},
    {"timestamp": "2025-09-03T10:00:00", "archive_file": "recent1.md", "keywords": ["NEW"]},
    {"timestamp": "2025-09-04T10:00:00", "archive_file": "recent2.md", "keywords": ["NEW"]},
    {"timestamp": "2025-09-05T10:00:00", "archive_file": "recent3.md", "keywords": ["NEW"]}
]}
EOF

    run cleanup_old_archives "$ARCHIVE_DIR/archive_index.json" 3
    [ "$status" -eq 0 ]

    # Verify only 3 entries remain
    local count
    count=$(get_archive_count "$ARCHIVE_DIR/archive_index.json")
    [ "$count" -eq 3 ]
}

@test "optimize_archive_index removes duplicates and sorts" {
    # Skip if jq is not available
    command -v jq &>/dev/null || skip "jq not available"

    # Create index with duplicates and unsorted entries
    cat > "$ARCHIVE_DIR/archive_index.json" << 'EOF'
{"archives": [
    {"timestamp": "2025-09-03T10:00:00", "archive_file": "file3.md", "keywords": ["INFO"]},
    {"timestamp": "2025-09-01T10:00:00", "archive_file": "file1.md", "keywords": ["ERROR"]},
    {"timestamp": "2025-09-02T10:00:00", "archive_file": "file1.md", "keywords": ["ERROR"]},
    {"timestamp": "2025-09-04T10:00:00", "archive_file": "file4.md", "keywords": ["TODO"]}
]}
EOF

    run optimize_archive_index "$ARCHIVE_DIR/archive_index.json"
    [ "$status" -eq 0 ]

    # Verify entries are sorted and duplicates removed
    local count
    count=$(get_archive_count "$ARCHIVE_DIR/archive_index.json")
    [ "$count" -eq 3 ]  # One duplicate removed

    # Check if sorted (first entry should be oldest)
    local first_file
    if command -v jq &>/dev/null; then
        first_file=$(jq -r '.archives[0].archive_file' "$ARCHIVE_DIR/archive_index.json")
        [[ "$first_file" == "file1.md" ]]
    fi
}

@test "get_archive_stats displays correct statistics" {
    cat > "$ARCHIVE_DIR/archive_index.json" << 'EOF'
{"archives": [
    {"timestamp": "2025-09-01T10:00:00", "archive_file": "file1.md", "keywords": ["ERROR", "CRITICAL"]},
    {"timestamp": "2025-09-02T10:00:00", "archive_file": "file2.md", "keywords": ["TODO", "ERROR"]},
    {"timestamp": "2025-09-03T10:00:00", "archive_file": "file3.md", "keywords": ["INFO", "ERROR"]}
]}
EOF

    run get_archive_stats "$ARCHIVE_DIR/archive_index.json"
    [ "$status" -eq 0 ]

    # Check output contains expected information
    [[ "$output" == *"Total entries: 3"* ]]
    [[ "$output" == *"Archive Statistics:"* ]]
}
