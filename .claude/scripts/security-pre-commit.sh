#!/bin/bash

# =============================================================================
# Security Pre-commit Hook
# コミット前のセキュリティチェック
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔒 Running security audit before commit..."

# セキュリティ監査実行
if python3 "$SCRIPT_DIR/security-audit.py" > /tmp/security-audit.log 2>&1; then
    echo "✅ Security audit passed"
    exit 0
else
    echo "❌ Security issues detected!"
    echo ""
    cat /tmp/security-audit.log
    echo ""
    echo "Please fix the security issues before committing."
    echo "Check .claude/security-report.md for details."
    exit 1
fi
