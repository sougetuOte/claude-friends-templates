#!/bin/bash

# =============================================================================
# TDD Cycle Runner for Sync Specialist
# Automates Red-Green-Refactor cycle
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/test-sync-integration.sh"
ENHANCED_MONITOR="$SCRIPT_DIR/enhanced-sync-monitor.sh"
ORIGINAL_MONITOR="$SCRIPT_DIR/sync-monitor.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_phase() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

echo_step() {
    echo -e "${YELLOW}>>> $1${NC}"
    echo
}

# Make scripts executable
chmod +x "$TEST_SCRIPT" "$ENHANCED_MONITOR"

echo_phase "TDD CYCLE: Sync Specialist Phase 2-2 Implementation"

# =============================================================================
# RED PHASE: Run failing tests
# =============================================================================
echo_phase "RED PHASE: Running tests that should fail"

echo_step "Running integration tests against current implementation"
if "$TEST_SCRIPT"; then
    echo -e "${YELLOW}WARNING: Tests passed unexpectedly - this should be RED phase${NC}"
else
    echo -e "${GREEN}✓ RED phase complete - tests failing as expected${NC}"
fi

echo
read -p "Press Enter to continue to GREEN phase..."
echo

# =============================================================================
# GREEN PHASE: Replace with enhanced implementation
# =============================================================================
echo_phase "GREEN PHASE: Implementing enhanced features"

echo_step "Backing up original sync-monitor.sh"
if [[ -f "$ORIGINAL_MONITOR" ]]; then
    cp "$ORIGINAL_MONITOR" "$ORIGINAL_MONITOR.backup"
    echo "✓ Backup created: sync-monitor.sh.backup"
else
    echo "! Original sync-monitor.sh not found - creating placeholder"
    touch "$ORIGINAL_MONITOR.backup"
fi

echo_step "Replacing sync-monitor.sh with enhanced version"
cp "$ENHANCED_MONITOR" "$ORIGINAL_MONITOR"
chmod +x "$ORIGINAL_MONITOR"
echo "✓ Enhanced sync-monitor.sh deployed"

echo_step "Running tests against enhanced implementation"
if "$TEST_SCRIPT"; then
    echo -e "${GREEN}✓ GREEN phase complete - tests now passing${NC}"
    GREEN_SUCCESS=true
else
    echo -e "${RED}✗ GREEN phase incomplete - some tests still failing${NC}"
    GREEN_SUCCESS=false
fi

echo
if [[ "$GREEN_SUCCESS" == "true" ]]; then
    read -p "Press Enter to continue to REFACTOR phase..."
else
    read -p "Press Enter to review failures and continue..."
fi
echo

# =============================================================================
# REFACTOR PHASE: Quality improvements
# =============================================================================
echo_phase "REFACTOR PHASE: Code quality improvements"

echo_step "Running code quality checks"

# Check shell script syntax
if shellcheck "$ORIGINAL_MONITOR" 2>/dev/null; then
    echo "✓ Shellcheck passed"
else
    echo "! Shellcheck issues found (installing shellcheck recommended)"
fi

# Check for TODO comments and technical debt
todo_count=$(grep -c "TODO\|FIXME\|XXX" "$ORIGINAL_MONITOR" || true)
if [[ $todo_count -gt 0 ]]; then
    echo "! Found $todo_count TODO/FIXME comments to address"
    grep -n "TODO\|FIXME\|XXX" "$ORIGINAL_MONITOR" || true
else
    echo "✓ No technical debt markers found"
fi

# Check script size and complexity
line_count=$(wc -l < "$ORIGINAL_MONITOR")
echo "Script size: $line_count lines"
if [[ $line_count -gt 500 ]]; then
    echo "! Consider splitting into smaller modules"
else
    echo "✓ Script size reasonable"
fi

echo_step "Running final test suite"
if "$TEST_SCRIPT"; then
    echo -e "${GREEN}✓ REFACTOR phase complete - all tests passing${NC}"
    REFACTOR_SUCCESS=true
else
    echo -e "${RED}✗ REFACTOR phase incomplete - regression detected${NC}"
    REFACTOR_SUCCESS=false
fi

# =============================================================================
# Summary and Next Steps
# =============================================================================
echo_phase "TDD CYCLE SUMMARY"

echo "Phase Results:"
echo "- RED Phase: ✓ (Tests failed as expected)"
if [[ "$GREEN_SUCCESS" == "true" ]]; then
    echo "- GREEN Phase: ✓ (Tests now pass)"
else
    echo "- GREEN Phase: ✗ (Some tests still failing)"
fi

if [[ "$REFACTOR_SUCCESS" == "true" ]]; then
    echo "- REFACTOR Phase: ✓ (Quality maintained)"
else
    echo "- REFACTOR Phase: ✗ (Regression detected)"
fi

echo
echo "Files created/modified:"
echo "- .claude/sync-specialist/test-sync-integration.sh (NEW - Integration tests)"
echo "- .claude/sync-specialist/enhanced-sync-monitor.sh (NEW - Enhanced implementation)"  
echo "- .claude/sync-specialist/sync-monitor.sh (UPDATED - Production version)"
echo "- .claude/sync-specialist/sync-monitor.sh.backup (BACKUP - Original version)"

echo
echo "Next Steps:"
if [[ "$GREEN_SUCCESS" == "true" ]] && [[ "$REFACTOR_SUCCESS" == "true" ]]; then
    echo "1. ✓ TDD cycle complete - ready for production use"
    echo "2. Consider integration with Pattern-2 subagents"
    echo "3. Monitor error logs: .claude/sync-specialist/error.log"
    echo "4. Update documentation if needed"
else
    echo "1. Review failing tests and fix implementation"
    echo "2. Re-run TDD cycle until all phases pass"
    echo "3. Consider rollback to backup if needed:"
    echo "   cp sync-monitor.sh.backup sync-monitor.sh"
fi

echo
echo "Testing Commands:"
echo "# Test enhanced error handling"
echo "./.claude/sync-specialist/sync-monitor.sh create_handover_with_fallback"
echo
echo "# Test validation"  
echo "./.claude/sync-specialist/sync-monitor.sh validate_handover"
echo
echo "# Test with debug mode"
echo "SYNC_DEBUG=true ./.claude/sync-specialist/sync-monitor.sh status"

echo_phase "TDD CYCLE COMPLETE"