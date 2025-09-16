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
# メトリクス計算・分析テスト (3テスト)
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