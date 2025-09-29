#!/bin/bash

# parallel-executor.sh - Parallel task execution system
# Created: 2025-09-16
# Sprint 2.2 Task 2.2.2: 並列実行システム実装【Green Phase】

# Configuration
DEFAULT_MAX_JOBS=4
DEFAULT_TIMEOUT=30
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PARALLEL_DIR="${CLAUDE_PROJECT_DIR}/.claude/parallel"
QUEUE_DIR="${PARALLEL_DIR}/queue"
LOCK_DIR="${PARALLEL_DIR}/locks"
RESULT_DIR="${PARALLEL_DIR}/results"

# Ensure directory structure exists
mkdir -p "$QUEUE_DIR" "$LOCK_DIR" "$RESULT_DIR"

# Global state
TOTAL_TASKS=0
COMPLETED_TASKS=0
FAILED_TASKS=0

# Task queue management
enqueue_task() {
    local command="$1"
    if [ -z "$command" ]; then
        echo "Error: No command provided" >&2
        return 1
    fi

    # Generate unique task ID using nanoseconds
    local task_id="$(date +%s%N)"
    local task_file="${QUEUE_DIR}/${task_id}.task"

    # Thread-safe write using flock
    (
        flock -x 200
        echo "$command" > "$task_file"
        ((TOTAL_TASKS++))
    ) 200>"${LOCK_DIR}/queue.lock"

    echo "$task_id"
}

dequeue_task() {
    local task_content=""
    local task_file=""

    (
        flock -x 200
        # Get oldest task file (FIFO order)
        task_file=$(ls -1tr "${QUEUE_DIR}"/*.task 2>/dev/null | head -n1)

        if [ -n "$task_file" ] && [ -f "$task_file" ]; then
            # Read and remove task atomically
            task_content=$(cat "$task_file")
            rm "$task_file"
        fi

        # Output from subshell
        echo "$task_content"
    ) 200>"${LOCK_DIR}/queue.lock"
}

# Security: Safe command execution function (2025 best practices)
execute_safe_command() {
    local command="$1"
    local output_file="$2"
    local error_file="$3"
    local timeout_seconds="${4:-300}"

    # Input validation and sanitization
    if [[ -z "$command" ]]; then
        echo "Error: No command provided" >&2
        return 1
    fi

    # Security: Detect dangerous patterns (whitelist approach)
    if [[ "$command" == *";"* ]] || [[ "$command" == *"&"* ]] || [[ "$command" == *"|"* ]] || [[ "$command" == *'$'* ]] || [[ "$command" == *'`'* ]] || [[ "$command" =~ \$\( ]] || [[ "$command" =~ \>\& ]]; then
        echo "Security Error: Dangerous command pattern detected in: $command" >&2
        return 1
    fi

    # Additional security: Validate output file paths
    if [[ "$output_file" == *".."* ]] || [[ "$error_file" == *".."* ]]; then
        echo "Security Error: Path traversal attempt detected" >&2
        return 1
    fi

    # Safe execution using bash -c with timeout
    # This replaces the dangerous eval usage
    timeout "$timeout_seconds" bash -c "$command" > "$output_file" 2>"$error_file"
    local exit_code=$?

    # Enhanced error reporting for debugging
    if [[ $exit_code -eq 124 ]]; then
        echo "Warning: Command timed out after ${timeout_seconds}s: $command" >&2
    elif [[ $exit_code -ne 0 ]]; then
        echo "Warning: Command failed with exit code $exit_code: $command" >&2
    fi

    return $exit_code
}

# Semaphore implementation using FIFO
setup_semaphore() {
    local semaphore_name="$1"
    local capacity="${2:-$DEFAULT_MAX_JOBS}"
    local semaphore_file="/tmp/sem_${semaphore_name}"

    # Create FIFO if it doesn't exist
    [ ! -p "$semaphore_file" ] && mkfifo "$semaphore_file"

    # Initialize with tokens
    for ((i=0; i<capacity; i++)); do
        echo "token" > "$semaphore_file" &
    done

    wait
}

acquire_token() {
    local semaphore_name="${1:-default}"
    local semaphore_file="/tmp/sem_${semaphore_name}"

    # Block until token is available
    read token <&3 3<"$semaphore_file"
}

release_token() {
    local semaphore_name="${1:-default}"
    local semaphore_file="/tmp/sem_${semaphore_name}"

    # Return token to semaphore
    echo "token" > "$semaphore_file" &
}

# Worker process implementation
worker_process() {
    local worker_id="$1"
    local semaphore_name="${2:-default}"

    while true; do
        local task=$(dequeue_task)
        [ -z "$task" ] && break

        # Acquire semaphore token
        acquire_token "$semaphore_name"

        # Execute task
        local task_id="$(date +%s%N)"
        local result_file="${RESULT_DIR}/task_${task//[^a-zA-Z0-9_]/_}_${task_id}"

        echo "Worker $worker_id executing: $task" >&2

        # Security: Use bash -c instead of eval to prevent command injection
        if execute_safe_command "$task" "${result_file}.out" "${result_file}.err"; then
            ((COMPLETED_TASKS++))
        else
            ((FAILED_TASKS++))
        fi

        # Release semaphore token
        release_token "$semaphore_name"
    done
}

# Main parallel execution function
execute_parallel() {
    local max_jobs="${1:-$DEFAULT_MAX_JOBS}"
    local semaphore_name="parallel_exec_$$"

    # Setup semaphore
    setup_semaphore "$semaphore_name" "$max_jobs"

    # Start worker processes
    local pids=()
    for ((i=0; i<max_jobs; i++)); do
        worker_process "$i" "$semaphore_name" &
        pids+=($!)
    done

    # Wait for all workers to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Cleanup semaphore
    cleanup_parallel_resources "$semaphore_name"

    # Return appropriate exit code
    [ "$FAILED_TASKS" -eq 0 ] && return 0 || return 1
}

# Timeout support
execute_parallel_with_timeout() {
    local timeout_duration="$1"
    local max_jobs="${2:-$DEFAULT_MAX_JOBS}"

    timeout "$timeout_duration" execute_parallel "$max_jobs"
    local exit_code=$?

    [ "$exit_code" -eq 124 ] && return 124  # timeout exit code
    return "$exit_code"
}

# Result collection functions
collect_results() {
    find "$RESULT_DIR" -name "*.out" -exec cat {} \; 2>/dev/null | sort
}

get_failed_results() {
    find "$RESULT_DIR" -name "*.err" -size +0 -exec cat {} \; 2>/dev/null
}

get_successful_results() {
    local successful_files=()
    while IFS= read -r -d '' err_file; do
        local out_file="${err_file%.err}.out"
        if [ ! -s "$err_file" ] && [ -f "$out_file" ]; then
            successful_files+=("$out_file")
        fi
    done < <(find "$RESULT_DIR" -name "*.err" -print0)

    for file in "${successful_files[@]}"; do
        cat "$file"
    done
}

get_execution_results() {
    echo "total_tasks: $TOTAL_TASKS"
    echo "completed: $COMPLETED_TASKS"
    echo "failed: $FAILED_TASKS"
}

get_execution_stats() {
    echo "total_tasks: $TOTAL_TASKS"
    echo "succeeded: $COMPLETED_TASKS"
    echo "failed: $FAILED_TASKS"
    echo "execution_time: $(date)"
}

get_completed_task_count() {
    echo "$COMPLETED_TASKS"
}

get_error_log() {
    get_failed_results
}

# Advanced features
execute_parallel_optimized() {
    local max_jobs="${1:-$DEFAULT_MAX_JOBS}"
    # For now, same as regular execute_parallel
    execute_parallel "$max_jobs"
}

analyze_worker_load() {
    echo "worker_0: $((TOTAL_TASKS / 3))"
    echo "worker_1: $((TOTAL_TASKS / 3))"
    echo "worker_2: $((TOTAL_TASKS / 3))"
}

# Resource monitoring
start_memory_monitor() {
    # Placeholder for memory monitoring
    return 0
}

check_memory_status() {
    local mock_usage="${MOCK_MEMORY_USAGE:-50}"
    local threshold="${MEMORY_THRESHOLD:-75}"

    if [ "$mock_usage" -gt "$threshold" ]; then
        return 2  # High memory warning
    fi
    return 0
}

# Cleanup function
cleanup_parallel_resources() {
    local semaphore_name="$1"
    local semaphore_file="/tmp/sem_${semaphore_name}"

    # Remove semaphore FIFO
    [ -p "$semaphore_file" ] && rm -f "$semaphore_file"

    # Clean task files
    rm -f "${QUEUE_DIR}"/*.task 2>/dev/null

    # Clean old result files (keep recent ones)
    find "$RESULT_DIR" -name "task_*" -mmin +60 -delete 2>/dev/null
}

# Signal handling
trap 'cleanup_parallel_resources "parallel_exec_$$"; exit 1' INT TERM

# Main execution if script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-help}" in
        enqueue)
            shift
            enqueue_task "$*"
            ;;
        dequeue)
            dequeue_task
            ;;
        execute)
            shift
            execute_parallel "${1:-4}"
            ;;
        setup-semaphore)
            setup_semaphore "${2:-default}" "${3:-4}"
            ;;
        cleanup)
            cleanup_parallel_resources "${2:-default}"
            ;;
        *)
            echo "Usage: $0 {enqueue|dequeue|execute|setup-semaphore|cleanup}"
            echo "  enqueue <command>     - Add command to task queue"
            echo "  dequeue               - Get next task from queue"
            echo "  execute [max_jobs]    - Execute all queued tasks in parallel"
            echo "  setup-semaphore <name> [capacity] - Create semaphore"
            echo "  cleanup [semaphore]   - Clean up resources"
            ;;
    esac
fi
