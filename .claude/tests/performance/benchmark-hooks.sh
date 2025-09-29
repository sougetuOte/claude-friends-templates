#!/bin/bash
# Performance benchmark for hook-common.sh and json-utils.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Claude Code Hooks Performance Benchmark ===${NC}"
echo "Date: $(date)"
echo "System: $(uname -a)"
echo ""

# Prepare test environment
TEST_DIR=$(mktemp -d)
export CLAUDE_PROJECT_DIR="$TEST_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/../../hooks/common"

# Load libraries
source "$HOOKS_DIR/hook-common.sh"
source "$HOOKS_DIR/json-utils.sh"

# Test data
SIMPLE_JSON='{"key": "value"}'
COMPLEX_JSON='{"users": [{"id": 1, "name": "Alice", "email": "alice@example.com"}, {"id": 2, "name": "Bob", "email": "bob@example.com"}], "settings": {"theme": "dark", "notifications": true, "language": "en"}}'
LARGE_JSON=$(printf '{"data": [%s]}' "$(for i in {1..100}; do echo '{"id": '$i', "value": "test data '$i'"}'; done | paste -sd ',')")

echo -e "${YELLOW}1. Testing init_hooks_system (Directory Creation)${NC}"
echo "----------------------------------------"
time_start=$(date +%s%N)
for i in {1..100}; do
    rm -rf "$TEST_DIR/.claude" 2>/dev/null || true
    init_hooks_system >/dev/null 2>&1
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 100000000 ))
echo "Average time for init_hooks_system: ${avg_time}ms"
echo ""

echo -e "${YELLOW}2. Testing get_agent_info (JSON Parsing)${NC}"
echo "----------------------------------------"
time_start=$(date +%s%N)
for i in {1..1000}; do
    echo '{"prompt": "/agent:planner test command"}' | get_agent_info >/dev/null 2>&1
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 1000000000 ))
echo "Average time for get_agent_info: ${avg_time}ms"
echo ""

echo -e "${YELLOW}3. Testing generate_json_response (JSON Generation)${NC}"
echo "----------------------------------------"
time_start=$(date +%s%N)
for i in {1..1000}; do
    generate_json_response "true" "Test message with special chars: \"quotes\" and \\backslash" "context" "false" >/dev/null 2>&1
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 1000000000 ))
echo "Average time for generate_json_response: ${avg_time}ms"
echo ""

echo -e "${YELLOW}4. Testing log_message (Concurrent Writes)${NC}"
echo "----------------------------------------"
LOG_FILE="$TEST_DIR/.claude/logs/benchmark.log"
time_start=$(date +%s%N)

# Test concurrent writes
pids=()
for i in {1..100}; do
    (
        for j in {1..10}; do
            log_message "INFO" "Benchmark message $i-$j" "$LOG_FILE"
        done
    ) &
    pids+=($!)
done

# Wait for all processes
for pid in "${pids[@]}"; do
    wait "$pid"
done

time_end=$(date +%s%N)
total_time=$(( (time_end - time_start) / 1000000 ))
line_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
echo "Total time for 1000 concurrent log writes: ${total_time}ms"
echo "Lines written: $line_count (expected: 1000)"
if [ "$line_count" -eq 1000 ]; then
    echo -e "${GREEN}✓ All log messages written successfully${NC}"
else
    echo -e "${RED}✗ Log message count mismatch${NC}"
fi
echo ""

echo -e "${YELLOW}5. Testing validate_json (JSON Validation)${NC}"
echo "----------------------------------------"

# Simple JSON validation
time_start=$(date +%s%N)
for i in {1..1000}; do
    echo "$SIMPLE_JSON" | validate_json 2>/dev/null
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 1000000000 ))
echo "Simple JSON validation: ${avg_time}ms"

# Complex JSON validation
time_start=$(date +%s%N)
for i in {1..1000}; do
    echo "$COMPLEX_JSON" | validate_json 2>/dev/null
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 1000000000 ))
echo "Complex JSON validation: ${avg_time}ms"

# Large JSON validation
time_start=$(date +%s%N)
for i in {1..100}; do
    echo "$LARGE_JSON" | validate_json 2>/dev/null
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 100000000 ))
echo "Large JSON validation (100 items): ${avg_time}ms"
echo ""

echo -e "${YELLOW}6. Testing extract_json_value (Value Extraction)${NC}"
echo "----------------------------------------"
time_start=$(date +%s%N)
for i in {1..1000}; do
    echo "$COMPLEX_JSON" | extract_json_value "settings.theme" >/dev/null 2>&1
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 1000000000 ))
echo "Nested value extraction: ${avg_time}ms"
echo ""

echo -e "${YELLOW}7. Testing create_json_object (Object Creation)${NC}"
echo "----------------------------------------"
time_start=$(date +%s%N)
for i in {1..1000}; do
    create_json_object "name" "Alice" "age" "30" "email" "alice@example.com" "active" "true" >/dev/null 2>&1
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 1000000000 ))
echo "JSON object creation (4 fields): ${avg_time}ms"
echo ""

echo -e "${YELLOW}8. Testing merge_json (JSON Merging)${NC}"
echo "----------------------------------------"
JSON1='{"a": 1, "b": 2}'
JSON2='{"c": 3, "d": 4}'
time_start=$(date +%s%N)
for i in {1..1000}; do
    merge_json "$JSON1" "$JSON2" >/dev/null 2>&1
done
time_end=$(date +%s%N)
avg_time=$(( (time_end - time_start) / 1000000000 ))
echo "JSON merge operation: ${avg_time}ms"
echo ""

echo -e "${GREEN}=== Benchmark Summary ===${NC}"
echo "----------------------------------------"
echo "All performance tests completed."
echo ""

# Memory usage check
echo -e "${YELLOW}Memory Usage Analysis${NC}"
echo "----------------------------------------"
if command -v /usr/bin/time >/dev/null 2>&1; then
    echo "Testing memory usage for large JSON processing..."
    /usr/bin/time -v bash -c "
        source '$HOOKS_DIR/json-utils.sh'
        for i in {1..100}; do
            echo '$LARGE_JSON' | validate_json >/dev/null 2>&1
        done
    " 2>&1 | grep -E "(Maximum resident set size|Elapsed)"
else
    echo "Time command not available for memory analysis"
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo -e "${GREEN}✓ Performance benchmark completed successfully${NC}"
