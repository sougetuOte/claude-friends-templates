# セキュリティ監査レポート

日時: 2025-09-16 11:15:33
スキャン対象: /home/ote/work3/claude-friends-templates-workspace_3/claude-friends-templates

## 🟠 High（早急に対応）
- **.claude/scripts/security-audit.py**: 文字列連結によるSQL構築

## 🟡 Medium（計画的に対応）
- **.claude/sync-specialist/handover-gen.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/sync-specialist/sync-monitor.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/sync-specialist/ai-logger-integration.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/sync-specialist/sync-trigger.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/security-pre-commit.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/memory-update.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/tdd-check.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/notes-check-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/task-progress-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/agent-switch-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/session-complete-enhanced.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/shared/test-framework/templates/unit/javascript/basic_test_template.js**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/tests/helpers/test-helpers.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/tests/helpers/test-helpers-simple.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/tests/e2e/test_simple.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/tests/performance/benchmark-hooks.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/tests/performance/detailed-performance-test.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/tests/performance/comprehensive-performance-test.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/scripts/tests/test-auto-rotation-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/hooks/handover/handover-gen.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/hooks/agent/agent-switch.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/hooks/common/hook-common.sh**: 相対パスの使用（パストラバーサルの可能性）
- **.claude/hooks/common/json-utils.sh**: 相対パスの使用（パストラバーサルの可能性）

## 統計
- スキャンファイル数: 85
- 検出された問題: 24
  - Critical: 0
  - High: 1
  - Medium: 23
  - Low: 0