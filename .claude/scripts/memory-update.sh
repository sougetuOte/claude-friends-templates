#!/bin/bash

# Memory Bank Auto-Update Hook
# Automatically updates memory bank with significant events

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Memory Bank Update Check ==="

# Project paths (adjusted for templates)
PROJECT_PATH="$(cd "$(dirname "$0")/../.." && pwd)"
MEMO_PATH="${PROJECT_PATH}/memo"
CLAUDE_PATH="${PROJECT_PATH}/.claude"

# Get tool and file from environment
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
FILE_PATH="${CLAUDE_FILE_PATHS:-}"

# Initialize update flag
SHOULD_UPDATE=false
UPDATE_REASON=""

# Check trigger conditions
case "$TOOL_NAME" in
    "Write"|"MultiEdit")
        # New file or significant edit
        if [[ "$FILE_PATH" == *.md ]] || [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.js ]]; then
            SHOULD_UPDATE=true
            UPDATE_REASON="Code/Documentation change"
        fi
        ;;
    "Bash")
        # Check for test execution or error
        if [[ "${CLAUDE_COMMAND:-}" == *"test"* ]] || [[ "${CLAUDE_EXIT_CODE:-0}" -ne 0 ]]; then
            SHOULD_UPDATE=true
            UPDATE_REASON="Test execution or error occurred"
        fi
        ;;
    "Task")
        # Subagent execution
        SHOULD_UPDATE=true
        UPDATE_REASON="Subagent task completed"
        ;;
esac

if [ "$SHOULD_UPDATE" = true ]; then
    echo -e "${BLUE}Memory update triggered: $UPDATE_REASON${NC}"
    
    # Create memo directories if needed
    mkdir -p "$MEMO_PATH/0_metadata"
    mkdir -p "$MEMO_PATH/1_specs"
    mkdir -p "$MEMO_PATH/2_decisions"
    mkdir -p "$MEMO_PATH/3_context"
    mkdir -p "$MEMO_PATH/4_learnings"
    
    # Generate memory entry ID
    ENTRY_ID="MEMO-$(date +%Y%m%d-%H%M%S)"
    
    # Determine category based on context
    if [[ "$UPDATE_REASON" == *"error"* ]]; then
        CATEGORY="4_learnings"
        SUBCATEGORY="errors"
    elif [[ "$UPDATE_REASON" == *"Test"* ]]; then
        CATEGORY="3_context"
        SUBCATEGORY="patterns"
    elif [[ "$UPDATE_REASON" == *"Documentation"* ]]; then
        CATEGORY="1_specs"
        SUBCATEGORY="requirements"
    else
        CATEGORY="3_context"
        SUBCATEGORY="snippets"
    fi
    
    # Create memory entry
    MEMORY_FILE="${MEMO_PATH}/${CATEGORY}/${ENTRY_ID}.md"
    
    {
        echo "---"
        echo "id: $ENTRY_ID"
        echo "tags: [auto-generated, $TOOL_NAME, ${CATEGORY}]"
        echo "priority: medium"
        echo "created: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "---"
        echo ""
        echo "## Summary"
        echo "$UPDATE_REASON"
        echo ""
        echo "## Context"
        echo "- Tool: $TOOL_NAME"
        echo "- File: $FILE_PATH"
        echo "- Time: $(date '+%H:%M:%S')"
        echo ""
        echo "## Content"
        
        # Add relevant content based on tool
        case "$TOOL_NAME" in
            "Write"|"MultiEdit")
                echo "File modified: \`$FILE_PATH\`"
                if [ -f "$FILE_PATH" ]; then
                    echo ""
                    echo "\`\`\`"
                    head -20 "$FILE_PATH" 2>/dev/null || echo "Unable to read file"
                    echo "\`\`\`"
                fi
                ;;
            "Bash")
                echo "Command executed: \`${CLAUDE_COMMAND:-unknown}\`"
                echo "Exit code: ${CLAUDE_EXIT_CODE:-0}"
                ;;
            "Task")
                echo "Subagent: ${CLAUDE_SUBAGENT:-unknown}"
                echo "Task description: ${CLAUDE_TASK_DESC:-none}"
                ;;
        esac
        
        echo ""
        echo "## Related"
        # Find related memories (simplified)
        echo "- Previous entries in ${CATEGORY}"
        
    } > "$MEMORY_FILE"
    
    # Update index
    INDEX_FILE="${MEMO_PATH}/0_metadata/index.md"
    if [ ! -f "$INDEX_FILE" ]; then
        echo "# Memory Bank Index" > "$INDEX_FILE"
        echo "" >> "$INDEX_FILE"
    fi
    
    echo "- [$ENTRY_ID]($CATEGORY/${ENTRY_ID}.md) - $UPDATE_REASON - $(date '+%Y-%m-%d %H:%M')" >> "$INDEX_FILE"
    
    echo -e "${GREEN}✅ Memory bank updated: $ENTRY_ID${NC}"
    
    # Check memory bank size
    MEMO_SIZE=$(du -sh "$MEMO_PATH" 2>/dev/null | cut -f1)
    echo "Memory bank size: $MEMO_SIZE"
    
    # Clean old entries if needed (keep last 100)
    ENTRY_COUNT=$(find "$MEMO_PATH" -name "MEMO-*.md" 2>/dev/null | wc -l)
    if [ $ENTRY_COUNT -gt 100 ]; then
        echo -e "${YELLOW}Cleaning old memory entries...${NC}"
        find "$MEMO_PATH" -name "MEMO-*.md" -mtime +30 -delete
    fi
else
    echo "No memory update needed for this event"
fi

exit 0