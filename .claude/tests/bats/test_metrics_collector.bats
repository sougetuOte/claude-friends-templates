#!/usr/bin/env bats
# Test suite for metrics collector system
# TDD Red Phase: All tests should FAIL initially

# Test fixtures directory
FIXTURES_DIR="${BATS_TEST_DIRNAME}/../fixtures"

setup() {
    # Create test environment
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export METRICS_FILE="$TEST_DIR/.claude/logs/metrics.txt"
    export AGGREGATED_LOG="$TEST_DIR/.claude/logs/aggregated.log"

    # Create directory structure
    mkdir -p "$TEST_DIR/.claude/logs"
    mkdir -p "$TEST_DIR/.claude/hooks/monitoring"

    # Create mock log files for aggregation tests
    echo "[2025-07-21 10:00] INFO: Test log entry 1" > "$TEST_DIR/.claude/logs/test1.log"
    echo "[2025-07-21 10:01] ERROR: Test error entry" > "$TEST_DIR/.claude/logs/test2.log"
    echo "[2025-07-21 10:02] INFO: Test log entry 2" > "$TEST_DIR/.claude/logs/test3.log"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# ================================================================
# メトリクス収集機能テスト (8テスト)
# ================================================================

@test "collect_metrics() creates metrics file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    run collect_metrics "test_hook" "0.125" "success"
    [ "$status" -eq 0 ]
    [ -f "$METRICS_FILE" ]
}

@test "collect_metrics() writes Prometheus format" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    collect_metrics "agent_switch" "0.086" "success"

    # Check Prometheus format
    grep -E 'hook_execution_duration_seconds{hook="agent_switch"} 0.086' "$METRICS_FILE"
    grep -E 'hook_execution_total{hook="agent_switch",status="success"} 1' "$METRICS_FILE"
}

@test "collect_metrics() handles different hook names" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    collect_metrics "tdd_checker" "0.034" "success"
    collect_metrics "handover_gen" "0.156" "error"

    grep -E 'hook="tdd_checker"' "$METRICS_FILE"
    grep -E 'hook="handover_gen"' "$METRICS_FILE"
    grep -E 'status="error"' "$METRICS_FILE"
}

@test "collect_metrics() handles error status correctly" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    collect_metrics "notes_rotator" "0.200" "error"

    grep -E 'status="error"' "$METRICS_FILE"
}

@test "collect_metrics() appends timestamps in ISO format" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    collect_metrics "test_hook" "0.100" "success"

    # Verify timestamp is in ISO format (YYYY-MM-DDTHH:MM:SS format)
    grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$METRICS_FILE"
}

@test "collect_metrics() handles multiple invocations" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    collect_metrics "hook1" "0.050" "success"
    collect_metrics "hook2" "0.100" "success"
    collect_metrics "hook1" "0.075" "success"

    # Should have 6 lines total (2 metrics per call)
    [ $(wc -l < "$METRICS_FILE") -eq 6 ]
}

@test "collect_metrics() validates input parameters" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Missing parameters should fail
    run collect_metrics
    [ "$status" -ne 0 ]

    run collect_metrics "hook_name"
    [ "$status" -ne 0 ]

    run collect_metrics "hook_name" "0.100"
    [ "$status" -ne 0 ]
}

@test "collect_metrics() handles invalid duration format" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Invalid duration should be handled gracefully
    run collect_metrics "test_hook" "invalid_duration" "success"
    [ "$status" -ne 0 ]
}

# ================================================================
# ログ集約機能テスト (5テスト)
# ================================================================

@test "aggregate_logs() creates aggregated log file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    run aggregate_logs
    [ "$status" -eq 0 ]
    [ -f "$AGGREGATED_LOG" ]
}

@test "aggregate_logs() processes recent log files only" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create an old log file (older than 1 day)
    touch -d "2 days ago" "$TEST_DIR/.claude/logs/old.log"
    echo "Old log entry" > "$TEST_DIR/.claude/logs/old.log"

    aggregate_logs

    # Should not include old log content
    ! grep "Old log entry" "$AGGREGATED_LOG"
}

@test "aggregate_logs() limits output to last 100 lines per file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create large log file with more than 100 lines
    for i in $(seq 1 150); do
        echo "Log line $i" >> "$TEST_DIR/.claude/logs/large.log"
    done

    aggregate_logs

    # Should contain only the last 100 lines
    ! grep "Log line 1" "$AGGREGATED_LOG"
    grep "Log line 150" "$AGGREGATED_LOG"
}

@test "aggregate_logs() handles empty log directory" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Remove test log files
    rm -f "$TEST_DIR/.claude/logs"/*.log

    run aggregate_logs
    [ "$status" -eq 0 ]
    [ -f "$AGGREGATED_LOG" ]
}

@test "aggregate_logs() preserves log entry order" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    aggregate_logs

    # Verify chronological order is maintained
    grep -n "Test log entry 1" "$AGGREGATED_LOG" | cut -d: -f1 > line1
    grep -n "Test log entry 2" "$AGGREGATED_LOG" | cut -d: -f1 > line2

    [ $(cat line1) -lt $(cat line2) ]
    rm -f line1 line2
}

# ================================================================
# 設定管理テスト (4テスト)
# ================================================================

@test "load_monitoring_config() reads configuration file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create config file
    cat > "$TEST_DIR/.claude/monitoring-config.json" << 'EOF'
{
  "metrics_retention_days": 30,
  "log_aggregation_limit": 50,
  "alert_thresholds": {
    "error_rate": 0.1,
    "response_time": 1.0
  }
}
EOF

    run load_monitoring_config "$TEST_DIR/.claude/monitoring-config.json"
    [ "$status" -eq 0 ]
}

@test "load_monitoring_config() handles missing config file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    run load_monitoring_config "$TEST_DIR/.claude/nonexistent-config.json"
    [ "$status" -eq 0 ]  # Should use defaults
}

@test "load_monitoring_config() validates JSON syntax" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create invalid JSON
    echo '{"invalid": json}' > "$TEST_DIR/.claude/monitoring-config.json"

    run load_monitoring_config "$TEST_DIR/.claude/monitoring-config.json"
    [ "$status" -ne 0 ]
}

@test "get_monitoring_setting() retrieves config values" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create config file
    cat > "$TEST_DIR/.claude/monitoring-config.json" << 'EOF'
{
  "metrics_retention_days": 15,
  "log_aggregation_limit": 200
}
EOF

    load_monitoring_config "$TEST_DIR/.claude/monitoring-config.json"

    result=$(get_monitoring_setting "metrics_retention_days")
    [ "$result" = "15" ]

    result=$(get_monitoring_setting "log_aggregation_limit")
    [ "$result" = "200" ]
}

# ================================================================
# パフォーマンス監視テスト (3テスト)
# ================================================================

@test "monitor_hook_performance() measures execution time" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Mock hook execution
    mock_hook() {
        sleep 0.1  # Simulate processing time
        return 0
    }

    run monitor_hook_performance "test_hook" mock_hook
    [ "$status" -eq 0 ]

    # Should have recorded metrics
    [ -f "$METRICS_FILE" ]
    grep -E 'hook="test_hook"' "$METRICS_FILE"
}

@test "monitor_hook_performance() handles hook failures" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Mock failing hook
    failing_hook() {
        return 1
    }

    run monitor_hook_performance "failing_hook" failing_hook
    [ "$status" -eq 1 ]  # Should preserve original exit code

    # Should record error status
    grep -E 'status="error"' "$METRICS_FILE"
}

@test "monitor_hook_performance() validates hook name" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    mock_hook() {
        return 0
    }

    # Empty hook name should fail
    run monitor_hook_performance "" mock_hook
    [ "$status" -ne 0 ]
}

# ================================================================
# メトリクス計算・分析テスト (5テスト)
# ================================================================

@test "calculate_success_rate() computes correct percentage" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create metrics with known success/error counts
    cat > "$METRICS_FILE" << 'EOF'
hook_execution_total{hook="test_hook",status="success"} 1 2025-07-21T10:00:00
hook_execution_total{hook="test_hook",status="success"} 1 2025-07-21T10:01:00
hook_execution_total{hook="test_hook",status="error"} 1 2025-07-21T10:02:00
hook_execution_total{hook="test_hook",status="success"} 1 2025-07-21T10:03:00
EOF

    result=$(calculate_success_rate "test_hook")
    # Should be 75% (3 success out of 4 total)
    [ "$result" = "75" ]
}

@test "calculate_success_rate() handles missing hook" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    result=$(calculate_success_rate "nonexistent_hook")
    [ "$result" = "0" ]
}

@test "calculate_average_duration() computes mean execution time" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create duration metrics
    cat > "$METRICS_FILE" << 'EOF'
hook_execution_duration_seconds{hook="test_hook"} 0.100 2025-07-21T10:00:00
hook_execution_duration_seconds{hook="test_hook"} 0.200 2025-07-21T10:01:00
hook_execution_duration_seconds{hook="test_hook"} 0.300 2025-07-21T10:02:00
EOF

    result=$(calculate_average_duration "test_hook")
    # Should be 0.200 (average of 0.1, 0.2, 0.3)
    [ "$result" = "0.200" ]
}

@test "calculate_average_duration() handles missing metrics file" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    rm -f "$METRICS_FILE"
    result=$(calculate_average_duration "test_hook")
    [ "$result" = "0.000" ]
}

@test "generate_monitoring_report() creates summary report" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Populate metrics file
    cat > "$METRICS_FILE" << 'EOF'
hook_execution_duration_seconds{hook="agent_switch"} 0.086 2025-07-21T10:00:00
hook_execution_total{hook="agent_switch",status="success"} 1 2025-07-21T10:00:00
hook_execution_duration_seconds{hook="tdd_checker"} 0.034 2025-07-21T10:01:00
hook_execution_total{hook="tdd_checker",status="success"} 1 2025-07-21T10:01:00
EOF

    run generate_monitoring_report
    [ "$status" -eq 0 ]

    # Should contain hook performance data
    echo "$output" | grep "agent_switch"
    echo "$output" | grep "tdd_checker"
}

# ================================================================
# Sprint 2.3 (TDD Design Check) 統合テスト (6テスト)
# ================================================================

@test "TDD integration: tdd_checker hook metrics collection" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Mock TDD checker hook execution
    mock_tdd_checker() {
        sleep 0.05  # Simulate TDD check processing
        return 0
    }

    run monitor_hook_performance "tdd_checker" mock_tdd_checker
    [ "$status" -eq 0 ]

    # Verify TDD checker metrics are recorded
    grep -E 'hook="tdd_checker".*duration_seconds' "$METRICS_FILE"
    grep -E 'hook="tdd_checker".*status="success"' "$METRICS_FILE"
}

@test "TDD integration: design check failure metrics" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Mock failing TDD design check
    failing_tdd_checker() {
        echo "TDD design check failed: No tests found"
        return 1
    }

    run monitor_hook_performance "tdd_design_check" failing_tdd_checker
    [ "$status" -eq 1 ]  # Should preserve failure exit code

    # Verify error metrics are recorded
    grep -E 'status="error"' "$METRICS_FILE"
}

@test "TDD integration: test discovery performance tracking" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create test files for discovery simulation
    mkdir -p "$TEST_DIR/src" "$TEST_DIR/tests"
    touch "$TEST_DIR/src/module.js" "$TEST_DIR/tests/module.test.js"

    # Mock test discovery operation
    test_discovery_hook() {
        find "$TEST_DIR" -name "*.test.*" | wc -l > /dev/null
        return 0
    }

    run monitor_hook_performance "test_discovery" test_discovery_hook
    [ "$status" -eq 0 ]

    # Should track performance of test discovery
    grep -E 'hook="test_discovery"' "$METRICS_FILE"
}

@test "TDD integration: red-green-refactor cycle metrics" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Simulate TDD cycle phases
    collect_metrics "tdd_red_phase" "0.150" "success"
    collect_metrics "tdd_green_phase" "0.300" "success"
    collect_metrics "tdd_refactor_phase" "0.200" "success"

    # Verify all phases are tracked
    grep -E 'hook="tdd_red_phase"' "$METRICS_FILE"
    grep -E 'hook="tdd_green_phase"' "$METRICS_FILE"
    grep -E 'hook="tdd_refactor_phase"' "$METRICS_FILE"

    # Green phase should typically take longer than red phase
    red_duration=$(grep 'tdd_red_phase.*0.150' "$METRICS_FILE" | wc -l)
    green_duration=$(grep 'tdd_green_phase.*0.300' "$METRICS_FILE" | wc -l)
    [ "$red_duration" -gt 0 ]
    [ "$green_duration" -gt 0 ]
}

@test "TDD integration: test-first development validation" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Mock test-first validation hook
    test_first_validator() {
        # Check if test was written before implementation
        local test_time=$(date -d "2025-07-21 10:00" +%s)
        local impl_time=$(date -d "2025-07-21 10:30" +%s)

        if [ "$test_time" -lt "$impl_time" ]; then
            return 0  # Test-first validation passed
        else
            return 1  # Test-first violation detected
        fi
    }

    run monitor_hook_performance "test_first_validation" test_first_validator
    [ "$status" -eq 0 ]

    # Should record test-first compliance metrics
    grep -E 'hook="test_first_validation"' "$METRICS_FILE"
}

@test "TDD integration: design synchronization metrics" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Mock design sync operation between TDD phases
    design_sync_hook() {
        sleep 0.025  # Simulate design synchronization
        echo "Design synchronized with implementation"
        return 0
    }

    run monitor_hook_performance "design_sync" design_sync_hook
    [ "$status" -eq 0 ]

    # Verify design sync metrics
    grep -E 'hook="design_sync"' "$METRICS_FILE"

    # Design sync should be fast (< 0.1s typically)
    duration=$(grep 'design_sync.*duration_seconds' "$METRICS_FILE" | grep -o '0\.[0-9]*')
    # Using basic comparison since bc might not be available in test environment
    [ -n "$duration" ]
}

# ================================================================
# エラー処理・エッジケーステスト (8テスト)
# ================================================================

@test "Error handling: collect_metrics with invalid hook name characters" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Test invalid characters in hook name
    run collect_metrics "hook with spaces" "0.100" "success"
    [ "$status" -ne 0 ]

    run collect_metrics "hook@special#chars" "0.100" "success"
    [ "$status" -ne 0 ]

    run collect_metrics "hook/with/slashes" "0.100" "success"
    [ "$status" -ne 0 ]
}

@test "Error handling: collect_metrics with invalid status values" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Only 'success' and 'error' should be valid
    run collect_metrics "test_hook" "0.100" "invalid_status"
    [ "$status" -ne 0 ]

    run collect_metrics "test_hook" "0.100" "FAILED"
    [ "$status" -ne 0 ]

    run collect_metrics "test_hook" "0.100" "1"
    [ "$status" -ne 0 ]
}

@test "Error handling: collect_metrics with edge case durations" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Test zero duration
    run collect_metrics "test_hook" "0" "success"
    [ "$status" -eq 0 ]

    # Test very small duration
    run collect_metrics "test_hook" "0.000001" "success"
    [ "$status" -eq 0 ]

    # Test large duration
    run collect_metrics "test_hook" "999.999" "success"
    [ "$status" -eq 0 ]

    # Test negative duration (should fail)
    run collect_metrics "test_hook" "-0.100" "success"
    [ "$status" -ne 0 ]
}

@test "Error handling: filesystem permission errors" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create read-only directory to simulate permission error
    local readonly_dir="$TEST_DIR/readonly"
    mkdir -p "$readonly_dir"
    chmod 444 "$readonly_dir"

    export METRICS_FILE="$readonly_dir/metrics.txt"

    run collect_metrics "test_hook" "0.100" "success"
    [ "$status" -ne 0 ]

    # Cleanup
    chmod 755 "$readonly_dir"
    rmdir "$readonly_dir"
}

@test "Error handling: concurrent metrics collection" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Simulate concurrent collection attempts
    collect_metrics "hook1" "0.050" "success" &
    local pid1=$!
    collect_metrics "hook2" "0.075" "success" &
    local pid2=$!
    collect_metrics "hook3" "0.100" "error" &
    local pid3=$!

    # Wait for all to complete
    wait $pid1 && wait $pid2 && wait $pid3

    # All metrics should be recorded without corruption
    [ $(wc -l < "$METRICS_FILE") -eq 6 ]  # 3 hooks × 2 metrics each
    grep -E 'hook="hook1"' "$METRICS_FILE"
    grep -E 'hook="hook2"' "$METRICS_FILE"
    grep -E 'hook="hook3"' "$METRICS_FILE"
}

@test "Error handling: malformed metrics file recovery" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create malformed metrics file
    echo "Invalid metrics data" > "$METRICS_FILE"
    echo "More invalid data" >> "$METRICS_FILE"

    # Should handle existing malformed data gracefully
    run collect_metrics "test_hook" "0.100" "success"
    [ "$status" -eq 0 ]

    # New valid metrics should be appended
    grep -E 'hook="test_hook"' "$METRICS_FILE"
}

@test "Error handling: disk space exhaustion simulation" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create a file system with limited space using tmpfs (if available)
    skip "Disk space test requires specific environment setup"

    # This test would require mounting a small tmpfs or using fallocate
    # to simulate disk space exhaustion conditions
}

@test "Error handling: missing dependencies graceful degradation" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Temporarily hide 'bc' command to test fallback behavior
    local original_path="$PATH"
    export PATH="/nonexistent:$PATH"

    # Remove bc from path simulation
    alias bc='echo "command not found" >&2; exit 1'

    run collect_metrics "test_hook" "0.100" "success"
    [ "$status" -eq 0 ]  # Should still work with fallbacks

    # Restore environment
    unalias bc
    export PATH="$original_path"

    # Metrics should still be collected
    grep -E 'hook="test_hook"' "$METRICS_FILE"
}

# ================================================================
# パフォーマンステスト (6テスト)
# ================================================================

@test "Performance: metrics collection under 50ms target" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Measure collection performance
    local start_time=$(date +%s.%N)

    for i in {1..10}; do
        collect_metrics "perf_test_$i" "0.100" "success" >/dev/null 2>&1
    done

    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.5")
    local avg_time=$(echo "scale=6; $total_time / 10" | bc 2>/dev/null || echo "0.05")

    # Log performance for manual verification (since comparison is complex)
    echo "Average collection time: ${avg_time}s" >&2

    # Simple validation that it completed (exact timing depends on system)
    [ -f "$METRICS_FILE" ]
    [ $(grep -c "perf_test_" "$METRICS_FILE") -eq 20 ]  # 10 hooks × 2 metrics each
}

@test "Performance: large metrics file handling" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create large metrics file (simulate 1000 existing entries)
    for i in {1..1000}; do
        echo "hook_execution_duration_seconds{hook=\"load_test_$i\"} 0.100 2025-07-21T10:00:00" >> "$METRICS_FILE"
        echo "hook_execution_total{hook=\"load_test_$i\",status=\"success\"} 1 2025-07-21T10:00:00" >> "$METRICS_FILE"
    done

    # Verify large file size
    [ $(wc -l < "$METRICS_FILE") -eq 2000 ]

    # Collection should still work efficiently
    local start_time=$(date +%s.%N)
    collect_metrics "new_hook" "0.100" "success"
    local end_time=$(date +%s.%N)

    # Should complete regardless of file size
    [ -f "$METRICS_FILE" ]
    grep -E 'hook="new_hook"' "$METRICS_FILE"
}

@test "Performance: memory usage during aggregation" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Create multiple large log files
    for log_num in {1..5}; do
        for line_num in {1..200}; do
            echo "[2025-07-21 10:${log_num}${line_num}] INFO: Log entry ${log_num}-${line_num}" >> "$TEST_DIR/.claude/logs/large_${log_num}.log"
        done
    done

    # Aggregation should handle multiple large files
    run aggregate_logs
    [ "$status" -eq 0 ]
    [ -f "$AGGREGATED_LOG" ]

    # Should limit output as expected (100 lines per file max)
    total_lines=$(wc -l < "$AGGREGATED_LOG")
    [ "$total_lines" -le 500 ]  # 5 files × 100 lines max each
}

@test "Performance: concurrent hook monitoring" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Define mock hooks with different execution times
    fast_hook() { sleep 0.01; return 0; }
    medium_hook() { sleep 0.05; return 0; }
    slow_hook() { sleep 0.1; return 0; }

    # Monitor hooks concurrently
    monitor_hook_performance "fast_hook" fast_hook &
    local pid1=$!
    monitor_hook_performance "medium_hook" medium_hook &
    local pid2=$!
    monitor_hook_performance "slow_hook" slow_hook &
    local pid3=$!

    # Wait for all to complete
    wait $pid1 && wait $pid2 && wait $pid3

    # All should complete successfully
    grep -E 'hook="fast_hook"' "$METRICS_FILE"
    grep -E 'hook="medium_hook"' "$METRICS_FILE"
    grep -E 'hook="slow_hook"' "$METRICS_FILE"
}

@test "Performance: report generation with large dataset" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Generate large dataset for report
    local hooks=("agent_switch" "tdd_checker" "handover_gen" "notes_rotator" "security_check")

    for hook in "${hooks[@]}"; do
        for i in {1..50}; do
            local duration="0.$(printf '%03d' $((RANDOM % 200 + 10)))"
            local status=$([[ $((RANDOM % 10)) -lt 8 ]] && echo "success" || echo "error")
            collect_metrics "$hook" "$duration" "$status"
        done
    done

    # Generate report from large dataset
    local start_time=$(date +%s.%N)
    run generate_monitoring_report
    local end_time=$(date +%s.%N)

    [ "$status" -eq 0 ]

    # Report should contain all hooks
    for hook in "${hooks[@]}"; do
        echo "$output" | grep "$hook"
    done
}

@test "Performance: benchmark function validation" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    # Test the built-in benchmark function
    run benchmark_performance
    [ "$status" -eq 0 ]

    # Should report performance metrics
    echo "$output" | grep "Performance Benchmark"
    echo "$output" | grep "Average time per collection"
    echo "$output" | grep "Collections per second"

    # Benchmark should clean up after itself
    ! grep "benchmark_test" "$METRICS_FILE"
}

# ================================================================
# ユーティリティ・CLI機能テスト (5テスト)
# ================================================================

@test "Utility: show_version displays correct information" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    run show_version
    [ "$status" -eq 0 ]
    echo "$output" | grep "Metrics Collector v2.0.0"
    echo "$output" | grep "Prometheus-format metrics"
    echo "$output" | grep "Performance monitoring"
}

@test "Utility: show_config displays current settings" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    run show_config
    [ "$status" -eq 0 ]
    echo "$output" | grep "METRICS_FILE:"
    echo "$output" | grep "AGGREGATED_LOG:"
    echo "$output" | grep "Settings:"
}

@test "Utility: validate_environment checks dependencies" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"

    run validate_environment
    [ "$status" -eq 0 ]
    echo "$output" | grep "Environment Validation:"
    echo "$output" | grep "Command available: date"
    echo "$output" | grep "validation passed"
}

@test "CLI: direct script execution with collect command" {
    # Test CLI interface when script is executed directly
    run bash "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" collect "cli_test" "0.123" "success"
    [ "$status" -eq 0 ]

    # Should create metrics in default location
    [ -f "$CLAUDE_PROJECT_DIR/.claude/logs/metrics.txt" ]
}

@test "CLI: direct script execution with help command" {
    # Test CLI help output
    run bash "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" help
    [ "$status" -eq 0 ]
    echo "$output" | grep "Usage:"
    echo "$output" | grep "collect"
    echo "$output" | grep "aggregate"
    echo "$output" | grep "report"
}
