#!/usr/bin/env bats
# Task 2.4.3: Handover File Lifecycle Management - Red Phase Tests
# TDD Red Phase: Tests MUST fail initially

load 'test_helper.bash' 2>/dev/null || true

setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"

    # Create necessary directories
    mkdir -p "$TEST_DIR/.claude/handover"
    mkdir -p "$TEST_DIR/.claude/archive/handover"
    mkdir -p "$TEST_DIR/.claude/scripts"
    mkdir -p "$TEST_DIR/.claude/logs"

    # Copy script to test directory
    if [[ -f "${BATS_TEST_DIRNAME}/../../scripts/handover-lifecycle.sh" ]]; then
        cp "${BATS_TEST_DIRNAME}/../../scripts/handover-lifecycle.sh" "$TEST_DIR/.claude/scripts/"
        chmod +x "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"
    fi

    # Create mock handover files with different ages
    create_test_handover_files
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Helper: Create handover files with different ages
create_test_handover_files() {
    local base_dir="$TEST_DIR/.claude"

    # Current file (0 days old)
    echo '{"metadata":{"created_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}}' > "$base_dir/handover-current.json"

    # 3 days old file
    echo '{"metadata":{"created_at":"'$(date -u -d "3 days ago" +%Y-%m-%dT%H:%M:%SZ)'"}}' > "$base_dir/handover-3days.json"
    touch -d "3 days ago" "$base_dir/handover-3days.json"

    # 8 days old file (should be archived)
    echo '{"metadata":{"created_at":"'$(date -u -d "8 days ago" +%Y-%m-%dT%H:%M:%SZ)'"}}' > "$base_dir/handover-8days.json"
    touch -d "8 days ago" "$base_dir/handover-8days.json"

    # 15 days old file (should be archived)
    echo '{"metadata":{"created_at":"'$(date -u -d "15 days ago" +%Y-%m-%dT%H:%M:%SZ)'"}}' > "$base_dir/handover-15days.json"
    touch -d "15 days ago" "$base_dir/handover-15days.json"

    # Old archive file (35 days old, should be deleted)
    mkdir -p "$base_dir/archive/handover/$(date -d "35 days ago" +%Y-%m)"
    echo "compressed data" | gzip > "$base_dir/archive/handover/$(date -d "35 days ago" +%Y-%m)/handover-35days.json.gz"
    touch -d "35 days ago" "$base_dir/archive/handover/$(date -d "35 days ago" +%Y-%m)/handover-35days.json.gz"
}

# Test 1: Lifecycle script exists
@test "handover-lifecycle.sh スクリプトが存在する" {
    run test -f "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"
    [ "$status" -eq 0 ]
}

# Test 2: Archive old handover files (>7 days)
@test "7日以上前のファイルをアーカイブに移動する" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Run archival
    run bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" archive --no-dry-run
    [ "$status" -eq 0 ]

    # Check that old files are archived
    [ ! -f "$TEST_DIR/.claude/handover-8days.json" ]
    [ ! -f "$TEST_DIR/.claude/handover-15days.json" ]

    # Check that recent files remain
    [ -f "$TEST_DIR/.claude/handover-current.json" ]
    [ -f "$TEST_DIR/.claude/handover-3days.json" ]
}

# Test 3: Archived files are compressed
@test "アーカイブファイルが gzip 圧縮される" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Run archival
    bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" archive --no-dry-run

    # Check for .gz files in archive
    run find "$TEST_DIR/.claude/archive/handover" -name "*.json.gz"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".json.gz" ]]
}

# Test 4: Archive directory structure (monthly subdirectories)
@test "アーカイブが月別サブディレクトリに整理される" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Run archival
    bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" archive --no-dry-run

    # Check for YYYY-MM structure
    run find "$TEST_DIR/.claude/archive/handover" -type d -name "????-??"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "20" ]]  # Year prefix
}

# Test 5: Delete archives older than 30 days
@test "30日以上前のアーカイブを削除する" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Verify old archive exists before deletion
    old_archive_dir="$TEST_DIR/.claude/archive/handover/$(date -d "35 days ago" +%Y-%m)"
    [ -f "$old_archive_dir/handover-35days.json.gz" ]

    # Run cleanup
    run bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" cleanup --no-dry-run
    [ "$status" -eq 0 ]

    # Check that old archive is deleted
    [ ! -f "$old_archive_dir/handover-35days.json.gz" ]
}

# Test 6: Dry-run mode (default, no actual changes)
@test "dry-run モードがデフォルトで有効（実際の変更なし）" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Count files before
    file_count_before=$(find "$TEST_DIR/.claude" -name "handover-*.json" | wc -l)

    # Run in dry-run mode (default)
    run bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" archive
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]] || [[ "$output" =~ "dry-run" ]]

    # Count files after (should be unchanged)
    file_count_after=$(find "$TEST_DIR/.claude" -name "handover-*.json" | wc -l)
    [ "$file_count_before" -eq "$file_count_after" ]
}

# Test 7: Minimum retention period (3 days safety buffer)
@test "最小保持期間（3日）を下回るファイルは削除しない" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Create a 2-day-old file
    touch -d "2 days ago" "$TEST_DIR/.claude/handover-2days.json"
    echo '{"metadata":{"created_at":"'$(date -u -d "2 days ago" +%Y-%m-%dT%H:%M:%SZ)'"}}' > "$TEST_DIR/.claude/handover-2days.json"

    # Try to force archive (should be rejected by safety check)
    run bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" archive --no-dry-run --force

    # File should still exist (not archived)
    [ -f "$TEST_DIR/.claude/handover-2days.json" ]
}

# Test 8: Logging of operations
@test "すべての操作がログに記録される" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Run archival
    bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" archive --no-dry-run 2>/dev/null

    # Check log file exists and contains entries
    run test -f "$TEST_DIR/.claude/logs/handover-lifecycle.log"
    [ "$status" -eq 0 ]

    run grep -E "(ARCHIVE|INFO|SUCCESS)" "$TEST_DIR/.claude/logs/handover-lifecycle.log"
    [ "$status" -eq 0 ]
}

# Test 9: Configuration via environment variables
@test "環境変数で保持期間を設定できる" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Set custom retention period
    export HANDOVER_RETENTION_DAYS=14

    # Run archive command
    run bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" archive --dry-run
    [ "$status" -eq 0 ]

    # Output should mention custom retention
    [[ "$output" =~ "14" ]] || [[ "$output" =~ "retention" ]]
}

# Test 10: Status command shows lifecycle statistics
@test "status コマンドでライフサイクル統計を表示する" {
    skip_if_missing "$TEST_DIR/.claude/scripts/handover-lifecycle.sh"

    # Run status command
    run bash "$TEST_DIR/.claude/scripts/handover-lifecycle.sh" status
    [ "$status" -eq 0 ]

    # Should show file counts and age statistics
    [[ "$output" =~ "Active" ]] || [[ "$output" =~ "active" ]]
    [[ "$output" =~ "Archive" ]] || [[ "$output" =~ "archive" ]]
}

# Helper function
skip_if_missing() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        skip "File not found: $file (expected in Green Phase)"
    fi
}
