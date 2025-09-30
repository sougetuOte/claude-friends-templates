#!/bin/bash
# Agent Switch Wrapper for E2E Testing
# Simplified interface for test integration
#
# Usage: agent-switch.sh <from_agent> <to_agent>
#
# Version: 1.0.0

set -uo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Use optimized handover generator if available (1.5x faster)
if [[ -f "$SCRIPT_DIR/handover-generator-optimized.py" ]]; then
    readonly HANDOVER_GENERATOR="$SCRIPT_DIR/handover-generator-optimized.py"
else
    readonly HANDOVER_GENERATOR="$SCRIPT_DIR/handover-generator.py"
fi

# Arguments
FROM_AGENT="${1:-}"
TO_AGENT="${2:-}"

# Validation
if [[ -z "$FROM_AGENT" ]] || [[ -z "$TO_AGENT" ]]; then
    echo "[ERROR] Usage: agent-switch.sh <from_agent> <to_agent>" >&2
    exit 1
fi

# Validate agent names
case "$FROM_AGENT" in
    planner|builder|first) ;;
    *)
        echo "[ERROR] Invalid from_agent: $FROM_AGENT (must be planner, builder, or first)" >&2
        exit 1
        ;;
esac

case "$TO_AGENT" in
    planner|builder) ;;
    *)
        echo "[ERROR] Invalid to_agent: $TO_AGENT (must be planner or builder)" >&2
        exit 1
        ;;
esac

# Log the switch
echo "[INFO] Agent switch detected: $FROM_AGENT → $TO_AGENT"

# Log to AI logger if available
if command -v python3 &> /dev/null && [[ -f "$SCRIPT_DIR/log_agent_event.py" ]]; then
    python3 "$SCRIPT_DIR/log_agent_event.py" INFO "Agent switch initiated" \
        agent="$FROM_AGENT" \
        operation="agent_switch" \
        from_agent="$FROM_AGENT" \
        to_agent="$TO_AGENT" 2>/dev/null || true
fi

# Check for concurrent handover lock
LOCK_FILE="$PROJECT_DIR/.claude/.handover.lock"

if [[ -f "$LOCK_FILE" ]]; then
    # Lock file exists - check if it's stale (older than 5 minutes)
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_FILE") ))
    else
        # Linux
        lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE") ))
    fi

    if [[ $lock_age -lt 300 ]]; then
        # Lock is fresh - reject concurrent handover
        echo "[ERROR] Handover already in progress (lock file exists)" >&2
        echo "[ERROR] If this is a stale lock, remove $LOCK_FILE manually" >&2
        exit 1
    else
        # Stale lock - remove and continue
        echo "[WARN] Removing stale lock file (age: ${lock_age}s)" >&2
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo "locked_by=$FROM_AGENT" > "$LOCK_FILE"
echo "pid=$$" >> "$LOCK_FILE"
echo "timestamp=$(date +%s)" >> "$LOCK_FILE"

# Ensure lock is removed on exit
trap 'rm -f "$LOCK_FILE"' EXIT INT TERM

# Generate handover file
if [[ -f "$HANDOVER_GENERATOR" ]]; then
    # Set environment variable for handover-generator.py
    export CLAUDE_PROJECT_DIR="$PROJECT_DIR"

    # Use handover-generator.py
    python3 "$HANDOVER_GENERATOR" \
        --from-agent "$FROM_AGENT" \
        --to-agent "$TO_AGENT" \
        2>&1

    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "[INFO] Handover file generated successfully"

        # Find the latest handover file
        latest_handover=$(ls -t "$PROJECT_DIR/.claude"/handover-*.json 2>/dev/null | head -1)
        if [[ -n "$latest_handover" ]]; then
            echo "[INFO] Handover file: $latest_handover"
        fi

        # Log success to AI logger
        if command -v python3 &> /dev/null && [[ -f "$SCRIPT_DIR/log_agent_event.py" ]]; then
            python3 "$SCRIPT_DIR/log_agent_event.py" INFO "Agent switch completed successfully" \
                agent="$TO_AGENT" \
                operation="agent_switch" \
                from_agent="$FROM_AGENT" \
                to_agent="$TO_AGENT" \
                handover_file="$latest_handover" 2>/dev/null || true
        fi
    else
        echo "[ERROR] Handover generation failed with exit code $exit_code" >&2

        # Log error to AI logger
        if command -v python3 &> /dev/null && [[ -f "$SCRIPT_DIR/log_agent_event.py" ]]; then
            python3 "$SCRIPT_DIR/log_agent_event.py" ERROR "Agent switch failed" \
                agent="$FROM_AGENT" \
                operation="agent_switch" \
                from_agent="$FROM_AGENT" \
                to_agent="$TO_AGENT" \
                exit_code="$exit_code" \
                error="Handover generation failed" 2>/dev/null || true
        fi

        exit $exit_code
    fi
else
    echo "[ERROR] Handover generator not found: $HANDOVER_GENERATOR" >&2
    exit 127
fi

exit 0
