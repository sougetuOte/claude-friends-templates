#!/bin/bash

# Make all sync specialist scripts executable
chmod +x .claude/sync-specialist/*.sh

echo "Made executable:"
ls -la .claude/sync-specialist/*.sh | grep -E '\-rwxr\-xr\-x'

echo
echo "Ready to run:"
echo "1. TDD Cycle: ./.claude/sync-specialist/run-tdd-cycle.sh"
echo "2. Integration Demo: ./.claude/sync-specialist/integration-demo.sh"
echo "3. Tests Only: ./.claude/sync-specialist/test-sync-integration.sh"
echo "4. Enhanced Monitor: ./.claude/sync-specialist/enhanced-sync-monitor.sh"
