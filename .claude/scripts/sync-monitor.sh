#!/bin/bash

# Sync Specialist Monitoring Hook
# Monitors agent switches and ensures proper handover generation

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Agent Sync Monitor ==="
echo ""

# Workspace paths
WORKSPACE_PATH="/home/ote/work3/claude-friends-templates-workspace_3"
SYNC_PATH="${WORKSPACE_PATH}/claude-friends-templates/.claude/sync-specialist"
HANDOVER_DIR="${SYNC_PATH}/handovers"

# Get current command from environment
COMMAND="${CLAUDE_COMMAND:-}"

# Check if this is an agent switch command
if [[ "$COMMAND" =~ ^/agent: ]]; then
    echo -e "${BLUE}Agent switch detected: $COMMAND${NC}"
    
    # Extract agent type
    AGENT_TYPE=$(echo "$COMMAND" | sed 's/^\/agent://')
    
    # Check current agent state
    if [ -f "${SYNC_PATH}/current-agent.txt" ]; then
        CURRENT_AGENT=$(cat "${SYNC_PATH}/current-agent.txt")
        echo "Switching from: $CURRENT_AGENT to: $AGENT_TYPE"
    else
        CURRENT_AGENT="unknown"
        echo "Initializing agent: $AGENT_TYPE"
    fi
    
    # Create handover directory if needed
    mkdir -p "$HANDOVER_DIR"
    
    # Generate handover filename
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    HANDOVER_FILE="${HANDOVER_DIR}/handover-${TIMESTAMP}.md"
    
    # Capture current context
    echo "Generating handover document..."
    {
        echo "# Handover: ${CURRENT_AGENT} → ${AGENT_TYPE}"
        echo ""
        echo "## Timestamp"
        echo "$(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "## Current Working Directory"
        echo "\`$(pwd)\`"
        echo ""
        echo "## Git Status"
        echo "\`\`\`"
        cd "${WORKSPACE_PATH}/claude-friends-templates" && git status --short
        echo "\`\`\`"
        echo ""
        echo "## Recent Files Modified"
        echo "\`\`\`"
        find "${WORKSPACE_PATH}/claude-friends-templates" -type f -mmin -30 2>/dev/null | head -10
        echo "\`\`\`"
        echo ""
        echo "## Active Tasks"
        if [ -f "${WORKSPACE_PATH}/PENDING_TASKS.md" ]; then
            grep -A 2 "^#### " "${WORKSPACE_PATH}/PENDING_TASKS.md" | head -20
        fi
        echo ""
    } > "$HANDOVER_FILE"
    
    # Update current agent
    echo "$AGENT_TYPE" > "${SYNC_PATH}/current-agent.txt"
    
    # Check handover quality
    HANDOVER_SIZE=$(wc -c < "$HANDOVER_FILE")
    if [ $HANDOVER_SIZE -lt 100 ]; then
        echo -e "${YELLOW}⚠️  Warning: Handover document is very small${NC}"
        EXIT_CODE=1
    else
        echo -e "${GREEN}✅ Handover document created: $(basename $HANDOVER_FILE)${NC}"
        EXIT_CODE=0
    fi
    
    # Maintain handover history (keep last 5)
    HANDOVER_COUNT=$(ls -1 "$HANDOVER_DIR"/handover-*.md 2>/dev/null | wc -l)
    if [ $HANDOVER_COUNT -gt 5 ]; then
        ls -t "$HANDOVER_DIR"/handover-*.md | tail -n +6 | xargs rm -f
        echo "Cleaned old handover documents"
    fi
    
    # Log the switch
    LOG_FILE="${SYNC_PATH}/switch.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Switch: ${CURRENT_AGENT} → ${AGENT_TYPE}" >> "$LOG_FILE"
    
    exit $EXIT_CODE
fi

# Not an agent switch, exit successfully
exit 0