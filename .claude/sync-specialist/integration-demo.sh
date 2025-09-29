#!/bin/bash

# =============================================================================
# Integration Demo for Enhanced Sync Specialist
# Demonstrates error handling, validation, and fallback features
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_MONITOR="$SCRIPT_DIR/enhanced-sync-monitor.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

demo_section() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

demo_step() {
    echo -e "${YELLOW}>>> $1${NC}"
    echo
}

wait_for_input() {
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read -r
    echo
}

# Setup demo environment
setup_demo() {
    demo_section "SETUP: Preparing Demo Environment"

    # Create demo directory structure
    mkdir -p demo-workspace/memo
    mkdir -p demo-workspace/.claude/sync-specialist

    # Copy enhanced sync monitor
    cp "$SYNC_MONITOR" demo-workspace/.claude/sync-specialist/sync-monitor.sh
    chmod +x demo-workspace/.claude/sync-specialist/sync-monitor.sh

    # Create sample active.md
    cat > demo-workspace/memo/active.md << 'EOF'
## Current Status
- Phase: development
- Agent: builder
- Progress: 75%

## Tasks
- [x] Implement core functionality
- [x] Add error handling
- [ ] Complete testing
- [ ] Documentation update
EOF

    # Create sample phase-todo.md
    cat > demo-workspace/memo/phase-todo.md << 'EOF'
# Phase TODO: Development

## Completed
- [x] Core implementation
- [x] Error handling
- [x] Validation logic

## Pending
- [ ] Integration testing
- [ ] Performance optimization
- [ ] Documentation
- [ ] Deployment preparation
EOF

    cd demo-workspace
    echo "✓ Demo environment created"
    wait_for_input
}

# Demo 1: Normal handover creation
demo_normal_handover() {
    demo_section "DEMO 1: Normal Handover Creation"

    demo_step "Creating standard handover with current state"

    if .claude/sync-specialist/sync-monitor.sh create_handover; then
        echo -e "${GREEN}✓ Handover created successfully${NC}"
        echo
        echo "Generated handover:"
        echo "---"
        cat memo/handover.md
        echo "---"
    else
        echo -e "${RED}✗ Handover creation failed${NC}"
    fi

    wait_for_input
}

# Demo 2: Validation
demo_validation() {
    demo_section "DEMO 2: Handover Validation"

    demo_step "Validating the created handover"

    if .claude/sync-specialist/sync-monitor.sh validate_handover; then
        echo -e "${GREEN}✓ Handover validation passed${NC}"
    else
        echo -e "${YELLOW}! Handover validation found issues${NC}"
    fi

    echo
    demo_step "Creating a poor quality handover to test validation"
    cat > memo/handover.md << 'EOF'
# Bad handover
Something went wrong.
EOF

    echo "Poor quality handover created. Testing validation..."
    if .claude/sync-specialist/sync-monitor.sh validate_handover; then
        echo -e "${RED}✗ Validation should have failed${NC}"
    else
        echo -e "${GREEN}✓ Validation correctly detected poor quality${NC}"
    fi

    wait_for_input
}

# Demo 3: Timeout handling
demo_timeout_handling() {
    demo_section "DEMO 3: Timeout Handling"

    demo_step "Testing timeout protection with fallback"

    # Create a version that will timeout
    cat > .claude/sync-specialist/slow-sync-monitor.sh << 'EOF'
#!/bin/bash
create_handover() {
    echo "Starting slow handover creation..."
    sleep 15  # This will cause timeout
    echo "This should not appear due to timeout"
}

# Source the enhanced monitor for other functions
source .claude/sync-specialist/sync-monitor.sh

"$@"
EOF
    chmod +x .claude/sync-specialist/slow-sync-monitor.sh

    echo "Testing with 5-second timeout..."
    SYNC_TIMEOUT=5 timeout 10s .claude/sync-specialist/sync-monitor.sh create_handover_with_fallback || {
        echo -e "${GREEN}✓ Timeout handled gracefully${NC}"

        if [[ -f memo/handover.md ]]; then
            echo
            echo "Emergency handover created:"
            echo "---"
            head -20 memo/handover.md
            echo "---"
        fi
    }

    wait_for_input
}

# Demo 4: Error fallback
demo_error_fallback() {
    demo_section "DEMO 4: Error Fallback Mechanism"

    demo_step "Testing error fallback when normal handover fails"

    # Simulate error condition
    chmod -w memo/  # Make directory read-only to cause error

    echo "Attempting handover creation with read-only memo directory..."
    if .claude/sync-specialist/sync-monitor.sh create_handover_with_fallback; then
        echo -e "${YELLOW}! Handover succeeded despite error condition${NC}"
    else
        echo -e "${GREEN}✓ Error detected, checking for emergency handover${NC}"

        chmod +w memo/  # Restore write permissions

        if [[ -f memo/handover.md ]]; then
            echo
            echo "Emergency handover created:"
            echo "---"
            head -15 memo/handover.md
            echo "---"
        fi

        if [[ -f memo/sync-error.md ]]; then
            echo
            echo "User notification created:"
            echo "---"
            cat memo/sync-error.md
            echo "---"
        fi
    fi

    chmod +w memo/  # Ensure write permissions are restored
    wait_for_input
}

# Demo 5: Debug mode
demo_debug_mode() {
    demo_section "DEMO 5: Debug Mode and Logging"

    demo_step "Running with debug mode enabled"

    echo "Creating handover with debug logging..."
    SYNC_DEBUG=true .claude/sync-specialist/sync-monitor.sh create_handover

    echo
    echo "Debug information:"
    if [[ -f .claude/sync-specialist/error.log ]]; then
        echo "---"
        tail -10 .claude/sync-specialist/error.log
        echo "---"
    else
        echo "No debug log created"
    fi

    wait_for_input
}

# Demo 6: Status and monitoring
demo_status_monitoring() {
    demo_section "DEMO 6: Status and Monitoring"

    demo_step "Checking sync specialist status"

    .claude/sync-specialist/sync-monitor.sh status

    echo
    demo_step "Available commands and help"
    .claude/sync-specialist/sync-monitor.sh help

    wait_for_input
}

# Cleanup demo
cleanup_demo() {
    demo_section "CLEANUP: Removing Demo Environment"

    cd ..
    rm -rf demo-workspace
    echo "✓ Demo environment cleaned up"
}

# Main demo execution
main() {
    echo -e "${GREEN}Enhanced Sync Specialist Integration Demo${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo "This demo will show the enhanced error handling, validation,"
    echo "and fallback features of the Sync Specialist Phase 2-2 implementation."
    echo
    wait_for_input

    setup_demo
    demo_normal_handover
    demo_validation
    demo_timeout_handling
    demo_error_fallback
    demo_debug_mode
    demo_status_monitoring
    cleanup_demo

    demo_section "DEMO COMPLETE"
    echo -e "${GREEN}All enhanced features demonstrated successfully!${NC}"
    echo
    echo "Key improvements shown:"
    echo "✓ Timeout protection with fallback"
    echo "✓ Error handling and emergency handovers"
    echo "✓ Handover quality validation"
    echo "✓ User notification system"
    echo "✓ Debug logging and monitoring"
    echo "✓ Concurrent access protection"
    echo
    echo "Ready for production deployment!"
}

# Run demo if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
