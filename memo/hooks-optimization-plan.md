# Hooks System Performance Optimization Plan

## Implementation Roadmap

### Phase 1: Critical Path Optimizations (Week 1-2)

#### 1.1 JSON Command Caching
**Target**: 30% reduction in JSON operation time
**Files**: `.claude/hooks/common/json-utils.sh`

```bash
# Add to top of json-utils.sh
declare -g JQ_AVAILABLE=""
declare -gA JSON_PARSE_CACHE

# Implement cached jq check
cached_jq_check() {
    if [[ -z "$JQ_AVAILABLE" ]]; then
        JQ_AVAILABLE=$(command -v jq >/dev/null 2>&1 && echo "true" || echo "false")
    fi
    [[ "$JQ_AVAILABLE" == "true" ]]
}

# Replace all "command -v jq" calls with cached_jq_check
```

**Risk**: Low
**Test Coverage**: Unit tests for caching behavior
**Rollback**: Simple - remove caching, revert to original

#### 1.2 Agent Info Caching
**Target**: 60% reduction in get_agent_info time
**Files**: `.claude/hooks/common/hook-common.sh`

```bash
# Add agent info caching with 5-second TTL
declare -gA AGENT_INFO_CACHE
declare -gA AGENT_INFO_CACHE_TIME

get_agent_info_cached() {
    local cache_key="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local current_time=$(date +%s)
    local cache_time="${AGENT_INFO_CACHE_TIME[$cache_key]:-0}"

    # Return cached value if less than 5 seconds old
    if [[ $((current_time - cache_time)) -lt 5 ]]; then
        echo "${AGENT_INFO_CACHE[$cache_key]}"
        return 0
    fi

    # Refresh cache
    local result
    result=$(get_agent_info_original "$@")
    AGENT_INFO_CACHE[$cache_key]="$result"
    AGENT_INFO_CACHE_TIME[$cache_key]=$current_time
    echo "$result"
}
```

**Risk**: Medium (caching correctness)
**Test Coverage**: Cache invalidation tests
**Rollback**: Alias to original function

### Phase 2: I/O Optimizations (Week 3-4)

#### 2.1 Background Notes Rotation
**Target**: Eliminate blocking during agent switches
**Files**: `.claude/hooks/agent/agent-switch.sh`

```bash
# Asynchronous notes rotation
trigger_notes_rotation_async() {
    local agent="$1"

    # Check if rotation needed
    if check_notes_rotation "$agent" >/dev/null 2>&1; then
        # Trigger in background with proper error handling
        (
            trigger_notes_rotation "$agent" ||
            log_message "ERROR" "Background notes rotation failed for $agent"
        ) &

        # Store background job PID for monitoring
        echo $! > "/tmp/claude-rotation-${agent}.pid"
        log_message "INFO" "Background notes rotation started for $agent"
    fi
}
```

**Risk**: Medium (background job management)
**Test Coverage**: Background process tests
**Rollback**: Keep synchronous version as fallback

#### 2.2 Optimized File Locking
**Target**: 40% improvement in concurrent logging
**Files**: `.claude/hooks/common/hook-common.sh`

```bash
# Performance-optimized logging
log_message_optimized() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local log_file="${3:-${LOG_DIR}/hooks.log}"

    # Skip expensive locking for INFO in high-performance mode
    if [[ "$level" == "INFO" && "${CLAUDE_FAST_LOGGING:-false}" == "true" ]]; then
        printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" >> "$log_file"
        return 0
    fi

    # Use standard locking for ERROR/WARN
    log_message_original "$@"
}
```

**Risk**: Low (preserves safety for critical messages)
**Test Coverage**: Concurrent logging stress tests
**Rollback**: Environment variable control

### Phase 3: Advanced Optimizations (Week 5-6)

#### 3.1 Batch JSON Operations
**Target**: 50% improvement for multiple extractions
**Files**: `.claude/hooks/common/json-utils.sh`

```bash
# Batch extract multiple values in single jq call
extract_json_batch() {
    local json="$1"
    shift
    local keys=("$@")

    if cached_jq_check && [[ ${#keys[@]} -gt 1 ]]; then
        local jq_filter=""
        for key in "${keys[@]}"; do
            jq_filter+=".[\"${key}\"],"
        done
        echo "$json" | jq -r "[${jq_filter%,}] | @tsv"
    else
        # Fallback to individual extractions
        for key in "${keys[@]}"; do
            echo "$json" | extract_json_value "$key"
        done
    fi
}
```

**Risk**: Medium (output format changes)
**Test Coverage**: Batch operation tests
**Rollback**: Feature flag control

#### 3.2 Agent Switch Concurrency Protection
**Target**: Prevent race conditions
**Files**: `.claude/hooks/agent/agent-switch.sh`

```bash
# Add agent switch locking
main() {
    local AGENT_SWITCH_LOCK="/tmp/claude-agent-switch-${CLAUDE_PROJECT_DIR//\//_}.lock"

    # Use flock with timeout
    (
        if flock -x -w 10 200; then
            main_implementation "$@"
        else
            echo '{"continue": false, "error": "Agent switch timeout"}'
            return 1
        fi
    ) 200>"$AGENT_SWITCH_LOCK"
}
```

**Risk**: Low (adds safety)
**Test Coverage**: Concurrent agent switch tests
**Rollback**: Remove locking wrapper

### Phase 4: Memory and Scalability (Week 7-8)

#### 4.1 Streaming JSON Validation
**Target**: Better handling of large JSON files
**Files**: `.claude/hooks/common/json-utils.sh`

```bash
# Stream-based validation for large files
validate_json_stream() {
    local max_size="${JSON_MAX_SIZE:-1048576}"  # 1MB default

    # Check input size first
    local input_size=$(wc -c 2>/dev/null || echo "$max_size")

    if [[ $input_size -gt $max_size ]]; then
        # Use streaming validation
        if cached_jq_check; then
            jq -e . >/dev/null 2>&1  # Existence check only
        else
            _stream_validate_json_structure
        fi
    else
        # Use standard validation
        validate_json "$@"
    fi
}
```

**Risk**: Medium (changes validation behavior)
**Test Coverage**: Large file tests
**Rollback**: Size threshold control

#### 4.2 Function Memoization
**Target**: Cache expensive computations
**Files**: All hook files

```bash
# Generic memoization wrapper
declare -gA MEMO_CACHE
declare -gA MEMO_CACHE_TIME

memoize() {
    local func_name="$1"
    local cache_ttl="${2:-60}"  # 60 seconds default
    shift 2

    local cache_key="${func_name}_$(printf '%s_' "$@")"
    local current_time=$(date +%s)
    local cache_time="${MEMO_CACHE_TIME[$cache_key]:-0}"

    if [[ $((current_time - cache_time)) -lt $cache_ttl ]]; then
        echo "${MEMO_CACHE[$cache_key]}"
        return 0
    fi

    # Execute function and cache result
    local result
    result=$($func_name "$@")
    MEMO_CACHE[$cache_key]="$result"
    MEMO_CACHE_TIME[$cache_key]=$current_time
    echo "$result"
}
```

**Risk**: High (complex caching logic)
**Test Coverage**: Comprehensive memoization tests
**Rollback**: Function-by-function removal

## Testing Strategy

### Performance Regression Tests

```bash
# Create performance regression test suite
#!/bin/bash
# performance-regression-test.sh

# Baseline measurements (before optimization)
BASELINE_AGENT_INFO_TIME=13
BASELINE_JSON_VALIDATION_TIME=10
BASELINE_CONCURRENT_LOGGING_TIME=307

# Test current performance against baseline
test_performance_regression() {
    local current_time

    # Test agent info performance
    current_time=$(measure_agent_info_performance)
    if [[ $current_time -gt $((BASELINE_AGENT_INFO_TIME + 2)) ]]; then
        echo "REGRESSION: agent_info performance degraded: ${current_time}ms"
        return 1
    fi

    # Add more tests...
}
```

### Load Testing Scripts

```bash
# concurrent-load-test.sh
#!/bin/bash

# Test concurrent agent switches
test_concurrent_agent_switches() {
    local switch_count=50
    local pids=()

    for i in $(seq 1 $switch_count); do
        (echo '{"prompt": "/agent:planner test"}' |
         bash .claude/hooks/agent/agent-switch.sh >/dev/null 2>&1) &
        pids+=($!)
    done

    # Wait and measure
    local start_time=$(date +%s%N)
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    local end_time=$(date +%s%N)

    local total_time=$(( (end_time - start_time) / 1000000 ))
    echo "Concurrent switches: ${switch_count} in ${total_time}ms"
}
```

## Risk Assessment Matrix

| Optimization | Risk Level | Impact | Mitigation |
|-------------|------------|--------|------------|
| JSON Command Caching | Low | High | Feature flag + tests |
| Agent Info Caching | Medium | High | TTL + cache invalidation |
| Background Rotation | Medium | Medium | Error handling + monitoring |
| Optimized Logging | Low | Medium | Environment variable control |
| Batch JSON Ops | Medium | Medium | Backwards compatibility |
| Concurrency Protection | Low | High | Timeout mechanisms |
| Streaming Validation | Medium | Low | Size thresholds |
| Function Memoization | High | Low | Gradual implementation |

## Performance Monitoring

### Metrics Collection

```bash
# Add performance metrics collection
collect_performance_metrics() {
    local metrics_file="$LOG_DIR/performance-metrics.json"
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Collect current metrics
    local agent_info_time=$(measure_agent_info_time)
    local json_validation_time=$(measure_json_validation_time)
    local memory_usage=$(get_memory_usage)

    # Append to metrics file
    jq -n --arg timestamp "$timestamp" \
          --arg agent_info_time "$agent_info_time" \
          --arg json_validation_time "$json_validation_time" \
          --arg memory_usage "$memory_usage" \
          '{
              timestamp: $timestamp,
              agent_info_time: ($agent_info_time | tonumber),
              json_validation_time: ($json_validation_time | tonumber),
              memory_usage: ($memory_usage | tonumber)
          }' >> "$metrics_file"
}
```

### Performance Alerts

```bash
# performance-monitor.sh
#!/bin/bash

# Monitor performance and alert on regressions
monitor_performance() {
    local threshold_multiplier=1.5  # Alert if 50% slower than baseline

    while true; do
        collect_performance_metrics

        # Check for performance regressions
        if check_performance_regression "$threshold_multiplier"; then
            log_message "WARN" "Performance regression detected"
            # Send notification if configured
        fi

        sleep 300  # Check every 5 minutes
    done
}
```

## Rollback Plan

### Phase-by-Phase Rollback

1. **Immediate Rollback** (< 5 minutes)
   - Environment variables to disable optimizations
   - Keep original functions as `*_original`

2. **Partial Rollback** (< 30 minutes)
   - Git revert specific commits
   - Function-level rollback switches

3. **Complete Rollback** (< 1 hour)
   - Full branch revert
   - Restore from backup files

### Rollback Testing

```bash
# test-rollback-safety.sh
#!/bin/bash

# Test all rollback mechanisms
test_rollback_safety() {
    # Test environment variable rollbacks
    export CLAUDE_DISABLE_CACHING=true
    run_standard_tests || echo "Environment rollback failed"

    # Test function rollbacks
    alias get_agent_info=get_agent_info_original
    run_standard_tests || echo "Function rollback failed"
}
```

## Success Criteria

### Performance Targets
- [ ] 30% reduction in JSON operation time
- [ ] 60% reduction in agent info lookup time
- [ ] 40% improvement in concurrent logging
- [ ] No increase in memory usage
- [ ] No functional regressions

### Quality Gates
- [ ] All existing tests pass
- [ ] New performance tests pass
- [ ] Load tests complete successfully
- [ ] Memory usage within bounds
- [ ] Error rates remain unchanged

### Monitoring Requirements
- [ ] Performance metrics collection
- [ ] Regression detection
- [ ] Alert mechanisms
- [ ] Rollback procedures tested

---

*Optimization plan follows TDD principles - implement incrementally with comprehensive testing at each phase.*