#!/usr/bin/env bats

# test_parallel_executor.bats - Parallel execution and task queue system tests
# Using t-wada style TDD - Red Phase test creation
# Created: 2025-09-16
# Sprint 2.2 Task 2.2.1: 並列実行テスト作成【Red Phase】

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export QUEUE_DIR="$TEST_DIR/.claude/parallel/queue"
    export LOCK_DIR="$TEST_DIR/.claude/parallel/locks"
    export RESULT_DIR="$TEST_DIR/.claude/parallel/results"

    # Create necessary directories
    mkdir -p "$QUEUE_DIR"
    mkdir -p "$LOCK_DIR"
    mkdir -p "$RESULT_DIR"

    # Export test functions and variables
    export MAX_PARALLEL_JOBS=4
    export TASK_TIMEOUT=30
    export SEMAPHORE_NAME="test_semaphore"

    # Source the script under test (will fail in Red Phase - TDD)
    if [ -f "${BATS_TEST_DIRNAME}/../../hooks/parallel/parallel-executor.sh" ]; then
        source "${BATS_TEST_DIRNAME}/../../hooks/parallel/parallel-executor.sh"
    fi
}

teardown() {
    # Clean up all processes and temporary files
    pkill -P $$ 2>/dev/null || true
    rm -rf "$TEST_DIR"
    rm -f /tmp/sem_* 2>/dev/null || true
    rm -f /tmp/task_* 2>/dev/null || true
}

# ==============================================================================
# Task Queue Management Tests
# ==============================================================================

@test "enqueue_task should add task to queue with unique ID" {
    # Red Phase: Function doesn't exist yet - should fail
    run enqueue_task "echo 'test task 1'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+$ ]]

    # Verify task file was created
    task_id="$output"
    [ -f "$QUEUE_DIR/${task_id}.task" ]
}

@test "dequeue_task should retrieve tasks in FIFO order" {
    # Red Phase: Functions don't exist yet - should fail
    task_id1=$(enqueue_task "echo 'task 1'")
    task_id2=$(enqueue_task "echo 'task 2'")
    task_id3=$(enqueue_task "echo 'task 3'")

    # Should retrieve in FIFO order
    run dequeue_task
    [ "$status" -eq 0 ]
    [ "$output" = "echo 'task 1'" ]

    run dequeue_task
    [ "$status" -eq 0 ]
    [ "$output" = "echo 'task 2'" ]

    run dequeue_task
    [ "$status" -eq 0 ]
    [ "$output" = "echo 'task 3'" ]
}

@test "dequeue_task should return empty when queue is empty" {
    # Red Phase: Function doesn't exist yet - should fail
    run dequeue_task
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "queue should be thread-safe with concurrent access" {
    # Red Phase: Concurrent safety functions don't exist yet - should fail
    # Simulate concurrent enqueue operations
    for i in {1..10}; do
        enqueue_task "echo 'concurrent task $i'" &
    done
    wait

    # Count total queued tasks
    run ls -1 "$QUEUE_DIR"/*.task 2>/dev/null | wc -l
    [ "$status" -eq 0 ]
    [ "$output" -eq 10 ]
}

# ==============================================================================
# Parallel Execution Control Tests
# ==============================================================================

@test "setup_semaphore should create FIFO semaphore with correct capacity" {
    # Red Phase: Function doesn't exist yet - should fail
    run setup_semaphore "$SEMAPHORE_NAME" 4
    [ "$status" -eq 0 ]

    # Verify FIFO was created
    [ -p "/tmp/sem_$SEMAPHORE_NAME" ]

    # Verify semaphore has correct capacity (4 tokens)
    for i in {1..4}; do
        timeout 1s bash -c "read <&3" 3<"/tmp/sem_$SEMAPHORE_NAME" || fail "Semaphore should have 4 tokens"
    done

    # 5th read should timeout (no more tokens)
    ! timeout 0.1s bash -c "read <&3" 3<"/tmp/sem_$SEMAPHORE_NAME"
}

@test "acquire_token should block when semaphore is full" {
    # Red Phase: Functions don't exist yet - should fail
    setup_semaphore "$SEMAPHORE_NAME" 2

    # Acquire all tokens
    acquire_token &
    local pid1=$!
    acquire_token &
    local pid2=$!

    sleep 0.1

    # Third acquire should block
    timeout 0.5s acquire_token && fail "acquire_token should block when semaphore is full"

    # Release one token and verify third acquire proceeds
    release_token
    timeout 1s acquire_token || fail "acquire_token should proceed after token release"

    # Clean up
    kill $pid1 $pid2 2>/dev/null || true
}

@test "execute_parallel should respect max job limit" {
    # Red Phase: Function doesn't exist yet - should fail
    # Create tasks that will run for a measurable time
    for i in {1..8}; do
        enqueue_task "sleep 0.2; echo 'task $i done' > '$RESULT_DIR/task_$i.result'"
    done

    # Execute with max 3 parallel jobs
    run execute_parallel 3
    [ "$status" -eq 0 ]

    # Verify all tasks completed
    run ls -1 "$RESULT_DIR"/*.result 2>/dev/null | wc -l
    [ "$output" -eq 8 ]
}

@test "parallel execution should collect exit codes correctly" {
    # Red Phase: Function doesn't exist yet - should fail
    enqueue_task "exit 0"  # Success
    enqueue_task "exit 1"  # Failure
    enqueue_task "exit 0"  # Success

    run execute_parallel 2
    [ "$status" -eq 1 ]  # Should return failure due to one failed task

    # Check results collection
    run get_execution_results
    [[ "$output" =~ "failed: 1" ]]
    [[ "$output" =~ "succeeded: 2" ]]
}

# ==============================================================================
# Timeout Processing Tests
# ==============================================================================

@test "task execution should timeout after specified duration" {
    # Red Phase: Timeout functions don't exist yet - should fail
    enqueue_task "sleep 10"  # Long-running task

    # Execute with 1 second timeout
    run execute_parallel_with_timeout 1 1
    [ "$status" -eq 124 ]  # timeout exit code
}

@test "timeout should not affect tasks that complete quickly" {
    # Red Phase: Function doesn't exist yet - should fail
    enqueue_task "echo 'quick task'"

    run execute_parallel_with_timeout 5 1
    [ "$status" -eq 0 ]
}

@test "partial timeout should continue other tasks" {
    # Red Phase: Advanced timeout handling doesn't exist yet - should fail
    enqueue_task "sleep 10"  # Will timeout
    enqueue_task "echo 'fast task'"  # Will complete

    run execute_parallel_with_timeout 1 2
    [ "$status" -eq 1 ]  # Mixed success/failure

    # Verify fast task completed
    run get_completed_task_count
    [ "$output" -eq 1 ]
}

# ==============================================================================
# Result Aggregation Tests
# ==============================================================================

@test "collect_results should aggregate all task outputs" {
    # Red Phase: Function doesn't exist yet - should fail
    enqueue_task "echo 'result 1'"
    enqueue_task "echo 'result 2'"
    enqueue_task "echo 'result 3'"

    execute_parallel 2

    run collect_results
    [ "$status" -eq 0 ]
    [[ "$output" =~ "result 1" ]]
    [[ "$output" =~ "result 2" ]]
    [[ "$output" =~ "result 3" ]]
}

@test "get_execution_stats should provide performance metrics" {
    # Red Phase: Function doesn't exist yet - should fail
    for i in {1..5}; do
        enqueue_task "sleep 0.1; echo 'task $i'"
    done

    execute_parallel 2

    run get_execution_stats
    [ "$status" -eq 0 ]
    [[ "$output" =~ "total_tasks: 5" ]]
    [[ "$output" =~ "parallel_jobs: 2" ]]
    [[ "$output" =~ "execution_time:" ]]
}

@test "failed task results should be captured separately" {
    # Red Phase: Error handling functions don't exist yet - should fail
    enqueue_task "echo 'success'; exit 0"
    enqueue_task "echo 'failure'; exit 1"

    execute_parallel 1

    run get_failed_results
    [[ "$output" =~ "failure" ]]

    run get_successful_results
    [[ "$output" =~ "success" ]]
}

# ==============================================================================
# Error Propagation Tests
# ==============================================================================

@test "worker_process should handle task execution errors gracefully" {
    # Red Phase: Worker process functions don't exist yet - should fail
    enqueue_task "nonexistent_command"

    run worker_process
    [ "$status" -ne 0 ]

    # Error should be logged but worker should continue
    run get_error_log
    [[ "$output" =~ "command not found" ]]
}

@test "signal handling should terminate all workers cleanly" {
    # Red Phase: Signal handling doesn't exist yet - should fail
    # Start workers
    for i in {1..3}; do
        worker_process &
    done

    # Send TERM signal to parent process
    kill -TERM $$

    sleep 0.5

    # Verify all workers stopped
    run pgrep -f "worker_process"
    [ "$status" -ne 0 ]  # No worker processes should remain
}

@test "resource cleanup should remove temporary files on exit" {
    # Red Phase: Cleanup functions don't exist yet - should fail
    setup_semaphore "$SEMAPHORE_NAME" 4
    enqueue_task "echo 'test'"

    # Simulate cleanup
    run cleanup_parallel_resources
    [ "$status" -eq 0 ]

    # Verify cleanup
    [ ! -p "/tmp/sem_$SEMAPHORE_NAME" ]
    [ ! -f "$QUEUE_DIR"/*.task ]
}

@test "memory_monitor should detect resource exhaustion" {
    # Red Phase: Resource monitoring doesn't exist yet - should fail
    # Simulate high memory usage scenario
    export MEMORY_THRESHOLD=50  # 50% threshold

    run start_memory_monitor
    [ "$status" -eq 0 ]

    # Should detect when memory is high (mocked)
    export MOCK_MEMORY_USAGE=80
    run check_memory_status
    [ "$status" -eq 2 ]  # High memory warning
}

# ==============================================================================
# Advanced Concurrent Scenarios
# ==============================================================================

@test "system should handle mixed CPU and IO bound tasks" {
    # Red Phase: Task classification doesn't exist yet - should fail
    # CPU-bound tasks
    enqueue_task "bash -c 'for i in {1..1000}; do echo \$i > /dev/null; done'"
    enqueue_task "bash -c 'for i in {1..1000}; do echo \$i > /dev/null; done'"

    # IO-bound tasks
    enqueue_task "find /tmp -type f > /dev/null 2>&1"
    enqueue_task "find /tmp -type f > /dev/null 2>&1"

    run execute_parallel_optimized 4
    [ "$status" -eq 0 ]
}

@test "load balancing should distribute tasks evenly across workers" {
    # Red Phase: Load balancing doesn't exist yet - should fail
    # Create 12 quick tasks
    for i in {1..12}; do
        enqueue_task "echo 'worker task $i'; sleep 0.1"
    done

    run execute_parallel 3  # 3 workers

    # Check load distribution
    run analyze_worker_load
    [[ "$output" =~ "worker_0: 4" ]]
    [[ "$output" =~ "worker_1: 4" ]]
    [[ "$output" =~ "worker_2: 4" ]]
}

# Helper test to verify test environment is set up correctly
@test "test environment should be properly initialized" {
    [ -d "$TEST_DIR" ]
    [ -d "$QUEUE_DIR" ]
    [ -d "$LOCK_DIR" ]
    [ -d "$RESULT_DIR" ]
    [ "$MAX_PARALLEL_JOBS" -eq 4 ]
    [ "$TASK_TIMEOUT" -eq 30 ]
}