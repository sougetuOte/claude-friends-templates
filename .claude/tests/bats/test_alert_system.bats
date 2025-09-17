#!/usr/bin/env bats
# Alert System Tests - Sprint 2.4 Task 2.4.2
# Following t-wada style TDD Red Phase

setup() {
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export METRICS_FILE="$TEST_DIR/.claude/logs/metrics.txt"
    export ALERT_LOG="$TEST_DIR/.claude/logs/alerts.log"
    export ALERT_CONFIG="$TEST_DIR/.claude/monitoring-config.json"

    # Create necessary directories
    mkdir -p "$TEST_DIR/.claude/logs"

    # Create default alert configuration
    cat > "$ALERT_CONFIG" << 'EOF'
{
  "alerts": {
    "error_rate_threshold": 0.1,
    "response_time_threshold": 1.0,
    "memory_bank_capacity_threshold": 0.8,
    "notification_enabled": true
  }
}
EOF
}

teardown() {
    rm -rf "$TEST_DIR"
}

#============================================================================
# Error Rate Threshold Monitoring
#============================================================================

@test "check_error_rate() detects high error rate" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create metrics with high error rate (60% errors)
    echo 'hook_execution_total{hook="test_hook",status="error"} 6' >> "$METRICS_FILE"
    echo 'hook_execution_total{hook="test_hook",status="success"} 4' >> "$METRICS_FILE"

    run check_error_rate "test_hook" "0.5"
    [ "$status" -eq 1 ]  # Should return error status for high error rate
    [[ "$output" =~ "ALERT" ]]
}

@test "check_error_rate() passes with low error rate" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create metrics with low error rate (5% errors)
    echo 'hook_execution_total{hook="test_hook",status="error"} 1' >> "$METRICS_FILE"
    echo 'hook_execution_total{hook="test_hook",status="success"} 19' >> "$METRICS_FILE"

    run check_error_rate "test_hook" "0.1"
    [ "$status" -eq 0 ]  # Should return success for low error rate
}

@test "check_error_rate() handles missing metrics gracefully" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    run check_error_rate "nonexistent_hook" "0.1"
    [ "$status" -eq 0 ]  # Should not alert when no data
}

#============================================================================
# Response Time Threshold Monitoring
#============================================================================

@test "check_response_time() detects slow responses" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create metrics with slow response times
    echo 'hook_execution_duration_seconds{hook="slow_hook"} 2.5' >> "$METRICS_FILE"
    echo 'hook_execution_duration_seconds{hook="slow_hook"} 3.0' >> "$METRICS_FILE"

    run check_response_time "slow_hook" "1.0"
    [ "$status" -eq 1 ]  # Should alert for slow response
    [[ "$output" =~ "ALERT" ]]
}

@test "check_response_time() passes with fast responses" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create metrics with fast response times
    echo 'hook_execution_duration_seconds{hook="fast_hook"} 0.05' >> "$METRICS_FILE"
    echo 'hook_execution_duration_seconds{hook="fast_hook"} 0.08' >> "$METRICS_FILE"

    run check_response_time "fast_hook" "1.0"
    [ "$status" -eq 0 ]  # Should pass for fast response
}

@test "check_response_time() calculates average correctly" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create metrics with mixed response times
    echo 'hook_execution_duration_seconds{hook="mixed_hook"} 0.5' >> "$METRICS_FILE"
    echo 'hook_execution_duration_seconds{hook="mixed_hook"} 1.5' >> "$METRICS_FILE"
    echo 'hook_execution_duration_seconds{hook="mixed_hook"} 1.0' >> "$METRICS_FILE"

    # Average should be 1.0, threshold is 0.8
    run check_response_time "mixed_hook" "0.8"
    [ "$status" -eq 1 ]  # Should alert (1.0 > 0.8)
}

#============================================================================
# Memory Bank Capacity Monitoring
#============================================================================

@test "check_memory_bank_capacity() detects high usage" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create large Memory Bank files
    mkdir -p "$TEST_DIR/.claude/planner" "$TEST_DIR/.claude/builder"

    # Create 450-line notes file (near rotation threshold)
    for i in {1..450}; do
        echo "Line $i of notes" >> "$TEST_DIR/.claude/planner/notes.md"
    done

    run check_memory_bank_capacity "0.8"
    [ "$status" -eq 1 ]  # Should alert for high capacity (450/500 = 0.9)
    [[ "$output" =~ "ALERT" ]]
}

@test "check_memory_bank_capacity() passes with low usage" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create small Memory Bank files
    mkdir -p "$TEST_DIR/.claude/planner" "$TEST_DIR/.claude/builder"

    # Create 100-line notes file (low usage)
    for i in {1..100}; do
        echo "Line $i of notes" >> "$TEST_DIR/.claude/planner/notes.md"
    done

    run check_memory_bank_capacity "0.8"
    [ "$status" -eq 0 ]  # Should pass for low capacity (100/500 = 0.2)
}

#============================================================================
# Alert Notification System
#============================================================================

@test "send_alert() creates alert log entry" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    run send_alert "ERROR_RATE" "Test hook error rate exceeded threshold" "HIGH"
    [ "$status" -eq 0 ]
    [ -f "$ALERT_LOG" ]
    grep -q "ERROR_RATE" "$ALERT_LOG"
}

@test "send_alert() includes severity level" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    send_alert "RESPONSE_TIME" "Response time too slow" "CRITICAL"

    grep -q "CRITICAL" "$ALERT_LOG"
}

@test "send_alert() handles concurrent alerts" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Send multiple alerts simultaneously
    for i in {1..5}; do
        send_alert "TEST_$i" "Test alert $i" "LOW" &
    done
    wait

    # All alerts should be recorded
    alert_count=$(wc -l < "$ALERT_LOG")
    [ "$alert_count" -eq 5 ]
}

#============================================================================
# Alert Configuration Management
#============================================================================

@test "load_alert_config() reads configuration" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    run load_alert_config "$ALERT_CONFIG"
    [ "$status" -eq 0 ]
}

@test "load_alert_config() uses defaults for missing config" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    rm -f "$ALERT_CONFIG"
    run load_alert_config "$ALERT_CONFIG"
    [ "$status" -eq 0 ]  # Should use defaults
}

@test "get_alert_threshold() retrieves correct values" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    load_alert_config "$ALERT_CONFIG"

    run get_alert_threshold "error_rate_threshold"
    [ "$status" -eq 0 ]
    [ "$output" = "0.1" ]
}

#============================================================================
# Alert Aggregation and Summary
#============================================================================

@test "generate_alert_summary() creates daily report" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create sample alerts
    send_alert "ERROR_RATE" "High error rate" "HIGH"
    send_alert "RESPONSE_TIME" "Slow response" "MEDIUM"
    send_alert "CAPACITY" "Memory Bank full" "CRITICAL"

    run generate_alert_summary
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Alert Summary" ]]
    [[ "$output" =~ "CRITICAL: 1" ]]
    [[ "$output" =~ "HIGH: 1" ]]
    [[ "$output" =~ "MEDIUM: 1" ]]
}

@test "clear_old_alerts() removes outdated alerts" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create old alert with past timestamp
    echo "[2020-01-01 00:00:00] [LOW] OLD_ALERT: Old alert message" >> "$ALERT_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HIGH] NEW_ALERT: New alert message" >> "$ALERT_LOG"

    run clear_old_alerts 7  # Keep alerts for 7 days
    [ "$status" -eq 0 ]

    # Old alert should be removed, new alert should remain
    ! grep -q "OLD_ALERT" "$ALERT_LOG"
    grep -q "NEW_ALERT" "$ALERT_LOG"
}

#============================================================================
# Integration with Monitoring System
#============================================================================

@test "monitor_and_alert() performs full check cycle" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Setup metrics that will trigger alerts
    echo 'hook_execution_total{hook="bad_hook",status="error"} 8' >> "$METRICS_FILE"
    echo 'hook_execution_total{hook="bad_hook",status="success"} 2' >> "$METRICS_FILE"
    echo 'hook_execution_duration_seconds{hook="bad_hook"} 2.0' >> "$METRICS_FILE"

    run monitor_and_alert
    [ "$status" -eq 0 ]
    [ -f "$ALERT_LOG" ]

    # Should have alerts for both error rate and response time
    grep -q "ERROR_RATE" "$ALERT_LOG"
    grep -q "RESPONSE_TIME" "$ALERT_LOG"
}

@test "Alert system integrates with metrics collector" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/metrics-collector.sh" || skip "metrics-collector.sh not found"
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Collect metrics
    collect_metrics "test_hook" "0.05" "success"
    collect_metrics "test_hook" "2.5" "error"  # Slow and failed

    # Check alerts
    run monitor_and_alert
    [ "$status" -eq 0 ]
}

#============================================================================
# Alert Rule Validation
#============================================================================

@test "validate_alert_rules() checks configuration sanity" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create invalid configuration
    cat > "$ALERT_CONFIG" << 'EOF'
{
  "alerts": {
    "error_rate_threshold": -0.5,
    "response_time_threshold": 0
  }
}
EOF

    run validate_alert_rules "$ALERT_CONFIG"
    [ "$status" -eq 1 ]  # Should fail validation
    [[ "$output" =~ "Invalid" ]]
}

@test "Alert system respects disable flag" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Disable notifications
    cat > "$ALERT_CONFIG" << 'EOF'
{
  "alerts": {
    "notification_enabled": false,
    "error_rate_threshold": 0.1
  }
}
EOF

    load_alert_config "$ALERT_CONFIG"

    # Should not send alert when disabled
    run send_alert "TEST" "Test message" "HIGH"
    [ "$status" -eq 0 ]
    [ ! -f "$ALERT_LOG" ]  # No log file should be created
}

#============================================================================
# Performance and Efficiency Tests
#============================================================================

@test "Alert checks complete within 100ms" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Create moderate amount of metrics
    for i in {1..100}; do
        echo "hook_execution_duration_seconds{hook=\"hook_$i\"} 0.05" >> "$METRICS_FILE"
    done

    start_time=$(date +%s%N)
    monitor_and_alert
    end_time=$(date +%s%N)

    duration=$((($end_time - $start_time) / 1000000))  # Convert to milliseconds
    [ "$duration" -lt 100 ]
}

@test "Alert system handles large alert volumes" {
    source "${BATS_TEST_DIRNAME}/../../hooks/monitoring/alert-system.sh" || skip "alert-system.sh not found"

    # Generate many alerts
    for i in {1..100}; do
        send_alert "BULK_$i" "Bulk alert $i" "LOW"
    done

    # Should handle all alerts
    alert_count=$(wc -l < "$ALERT_LOG")
    [ "$alert_count" -eq 100 ]
}