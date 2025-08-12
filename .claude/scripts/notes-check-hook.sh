#!/bin/bash

# Notes Auto-Rotation Hook
# Automatically rotates notes.md when they exceed 450 lines
# Called on agent switching via Claude Code hooks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check line counts
check_and_rotate() {
    local agent_dir="$1"
    local agent_name="$2"
    local notes_file="$agent_dir/notes.md"
    
    if [ ! -f "$notes_file" ]; then
        return 0
    fi
    
    local line_count=$(wc -l < "$notes_file" 2>/dev/null || echo 0)
    
    if [ "$line_count" -gt 450 ]; then
        echo -e "${YELLOW}🔄 Auto-rotating ${agent_name} notes (${line_count} lines > 450)...${NC}"
        
        # Run rotation
        if bash "$SCRIPT_DIR/rotate-notes.sh" "$agent_dir"; then
            echo -e "${GREEN}✅ ${agent_name} notes rotated successfully${NC}"
            
            # Update index
            bash "$SCRIPT_DIR/update-index.sh" "$agent_dir" >/dev/null 2>&1
            echo -e "${GREEN}📑 Index updated${NC}"
        else
            echo -e "${RED}❌ Failed to rotate ${agent_name} notes${NC}"
        fi
        
        return 1  # Indicates rotation happened
    fi
    
    return 0  # No rotation needed
}

# Main execution
main() {
    local rotated=0
    
    # Check Planner notes
    if ! check_and_rotate "$PROJECT_ROOT/.claude/planner" "Planner"; then
        rotated=1
    fi
    
    # Check Builder notes
    if ! check_and_rotate "$PROJECT_ROOT/.claude/builder" "Builder"; then
        rotated=1
    fi
    
    # If any rotation happened, show summary
    if [ "$rotated" -eq 1 ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}Notes auto-rotation completed. Archives are available in:${NC}"
        echo "  • .claude/planner/archive/"
        echo "  • .claude/builder/archive/"
    fi
}

# Run main function
main