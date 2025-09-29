# セキュリティ監査レポート

日時: 2025-09-17 12:44:45
スキャン対象: /home/ote/work3/claude-friends-templates-workspace_3/claude-friends-templates/.claude

## 🟠 High（早急に対応）
- **scripts/security-audit.py**: 文字列連結によるSQL構築

## 🟡 Medium（計画的に対応）
- **sync-specialist/handover-gen.sh**: 相対パスの使用（パストラバーサルの可能性）
- **sync-specialist/sync-monitor.sh**: 相対パスの使用（パストラバーサルの可能性）
- **sync-specialist/ai-logger-integration.sh**: 相対パスの使用（パストラバーサルの可能性）
- **sync-specialist/sync-trigger.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/security-pre-commit.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/memory-update.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/tdd-check.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/notes-check-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/task-progress-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/agent-switch-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/activity-logger.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/validate-config.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/session-complete-enhanced.sh**: 相対パスの使用（パストラバーサルの可能性）
- **shared/test-framework/templates/unit/javascript/basic_test_template.js**: 相対パスの使用（パストラバーサルの可能性）
- **tests/helpers/test-helpers.sh**: 相対パスの使用（パストラバーサルの可能性）
- **tests/helpers/test-helpers-simple.sh**: 相対パスの使用（パストラバーサルの可能性）
- **tests/e2e/test_simple.sh**: 相対パスの使用（パストラバーサルの可能性）
- **tests/performance/benchmark-hooks.sh**: 相対パスの使用（パストラバーサルの可能性）
- **tests/performance/detailed-performance-test.sh**: 相対パスの使用（パストラバーサルの可能性）
- **tests/performance/comprehensive-performance-test.sh**: 相対パスの使用（パストラバーサルの可能性）
- **scripts/tests/test-auto-rotation-hook.sh**: 相対パスの使用（パストラバーサルの可能性）
- **hooks/handover/handover-gen.sh**: 相対パスの使用（パストラバーサルの可能性）
- **hooks/tdd/tdd-checker.sh**: 相対パスの使用（パストラバーサルの可能性）
- **hooks/agent/agent-switch.sh**: 相対パスの使用（パストラバーサルの可能性）
- **hooks/common/hook-common.sh**: 相対パスの使用（パストラバーサルの可能性）
- **hooks/common/json-utils.sh**: 相対パスの使用（パストラバーサルの可能性）
- **hooks/memory/notes-rotator.sh**: 相対パスの使用（パストラバーサルの可能性）

## 統計
- スキャンファイル数: 115
- 検出された問題: 28
  - Critical: 0
  - High: 1
  - Medium: 27
  - Low: 0
