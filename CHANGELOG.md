# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-07-21

### 🚀 Major Enhancement: TDD & Quality Engineering Integration

This release brings comprehensive enhancements from the claude-kiro-template integration, focusing on Test-Driven Development, design synchronization, error pattern learning, and automated quality management.

### Added

#### Phase 1: TDD Integration
- **Strict TDD Workflow**: Red-Green-Refactor cycle with visual task status tracking
- **Task Status System**: 🔴 Not Implemented → 🟢 Minimally Implemented → ✅ Refactored → ⚠️ Blocked
- **TDD Commands**: `/tdd:start` and `/tdd:status` for managing TDD cycles
- **TDD Enforcement Settings**: Configurable strictness levels (strict/recommended/off)
- **Comprehensive TDD Guide**: `.claude/builder/tdd-cycle.md` with t-wada style TDD practices
- **Task Status Documentation**: `.claude/shared/task-status.md` for visual progress tracking

#### Phase 2: Enhanced Design Synchronization
- **Design Sync Mechanism**: `.claude/shared/design-sync.md` for design-implementation alignment
- **Design Change Tracking**: Systematic recording of design decisions and impacts
- **Design Drift Detection**: Automated checks for design-code divergence
- **ADR Integration**: Enhanced Architecture Decision Records with templates
- **Design Conflict Resolution**: Framework for handling design gaps during implementation

#### Phase 3: Error Pattern Library
- **AI-Powered Error Recognition**: Learning from past debugging sessions
- **Pattern Matching**: Instant identification of similar errors from history
- **Root Cause Analysis**: AI-suggested causes and solutions
- **Searchable Debug History**: Quick access to past solutions
- **Error Pattern Templates**: Standardized error documentation format

#### Phase 4: Integrated Development Framework
- **Test Framework Integration**:
  - Pre-built test templates for common scenarios
  - Automatic mock generation for dependencies
  - Real-time coverage tracking and reporting
  - Quality gates enforcing 80%+ coverage
  
- **Agent Coordination Optimization**:
  - Smart handoff compression for efficient context transfer
  - Parallel task execution analysis
  - Shared memory bank synchronization
  - Performance monitoring and bottleneck detection
  
- **Automated Quality Management**:
  - Refactoring scheduler with priority scoring
  - Design change impact analyzer
  - Pre-commit quality gates
  - Continuous quality monitoring

### Enhanced
- **Builder Agent**: Now enforces strict TDD practices with visual status tracking
- **Planner Agent**: Enhanced with design synchronization and drift detection
- **Memory Bank**: Expanded with error patterns and test templates
- **Documentation**: Added comprehensive guides for TDD, design sync, and quality management

### Added Files
- `.claude/builder/tdd-cycle.md` - TDD practice guide
- `.claude/shared/task-status.md` - Task status management
- `.claude/shared/design-sync.md` - Design synchronization guide
- `.claude/shared/design-tracker/` - Design change tracking system
- `.claude/shared/refactoring-scheduler.md` - Automated refactoring suggestions
- `.claude/shared/quality-gates.md` - Quality automation system
- `.claude/shared/tdd-settings.md` - TDD configuration guide
- `.claude/refactoring-config.json` - Refactoring scheduler configuration
- `.claude/quality-config.json` - Quality gates configuration
- `BEST_PRACTICES.md` - Comprehensive best practices guide
- `ARCHITECTURE.md` - System architecture documentation

### Configuration
- **TDD Settings**: Added to `.claude/settings.json` with enforcement levels
- **Quality Thresholds**: Configurable complexity, coverage, and duplication limits
- **Refactoring Rules**: Automated priority calculation for technical debt

### Documentation
- Updated README.md with enhanced features section
- Updated CLAUDE.md with new commands and features
- Added links to new documentation files
- Enhanced existing guides with TDD and quality practices

## [2.0.0] - 2025-07-12

### 🎉 Major Release: Claude Friends Multi-Agent System

This is a major release introducing the revolutionary Claude Friends system, transforming solo development into an AI-powered team experience.

### Added
- **Claude Friends Multi-Agent System**: Sequential AI agents that simulate a development team
  - **Planner Agent**: Strategic planning, requirement gathering, design documentation with Mermaid diagrams
  - **Builder Agent**: Implementation, testing, debugging, and code review
  - **Smart Mode Switching**: Agents automatically switch to specialized modes based on context
- **Special Modes**: 
  - Planner: Feature Design Mode (auto-activates for new features)
  - Builder: Debug Mode (auto-activates on errors) & Code Review Mode
- **Intelligent Handoff System**: Smooth transitions between agents with mode recommendations
- **Agent Workspaces**: Dedicated directories for each agent with notes, identity, and handover files
- **Simplified Command System**: Just 4 core commands (`/agent:planner`, `/agent:builder`, `/project:focus`, `/project:daily`)
- **Mandatory TDD**: Test-Driven Development (t-wada style) is now strictly enforced

### Changed
- **Major Command Consolidation**: 
  - `/feature:plan` → Integrated into Planner's Feature Design Mode
  - `/debug:start` → Integrated into Builder's Debug Mode
  - `/review:check` → Integrated into Builder's Code Review Mode
- **Project Structure**: Evolved from Memory Bank only to Agent + Memory Bank hybrid
- **Development Workflow**: Shifted from command-based to agent-based development
- **Documentation**: Complete overhaul to reflect Claude Friends system

### Removed
- **Deprecated Commands**: 
  - `/project:plan` (replaced by `/agent:planner`)
  - `/project:act` (replaced by `/agent:builder`)
  - Individual mode commands (now integrated into agents)

### Breaking Changes
- Command structure completely redesigned - existing workflows need migration
- Memory Bank structure expanded with agent-specific directories
- `core/current.md` deprecated in favor of agent-specific notes

### Migration Guide
1. Start using `/agent:planner` instead of `/project:plan`
2. Use `/agent:builder` instead of `/project:act`
3. Special modes are now automatic - no need for separate commands
4. Handover documents required when switching agents

## [1.2.0] - 2025-07-10

### Added
- **AI-Friendly Logger V2**: [Vibe Logger](https://github.com/fladdict/vibe-logger)概念を採用した構造化JSONログシステム
  - @fladdict氏の[AIエージェント用ログシステム「Vibe Logger」提案](https://note.com/fladdict/n/n5046f72bdadd)に基づく実装
  - JSONL形式による効率的なAI解析
  - 相関ID追跡とログレベル管理
- **AIログ解析ツール**: `analyze-ai-logs.py`によるパターン分析・洞察生成機能
- **豊富なコンテキスト**: プロジェクト・環境・Git情報を自動収集
- **AIメタデータ**: デバッグヒント・優先度・推奨アクション・ai_todo フィールド
- **エラー分析機能**: エラーパターンの検出と改善提案
- **Vibe Logger統合ガイド**: `.claude/vibe-logger-integration.md`による段階的移行支援

### Enhanced
- 既存の活動ログシステムと並行動作による段階的移行サポート
- AI駆動開発（VibeCoding）の効率を大幅に向上
- デバッグプロセスの「推測と確認」から「分析と解決」への転換

### Documentation
- `.claude/ai-logger-README.md`: AI Logger システムの詳細説明
- `CLAUDE.md`: AI-Friendly Logger機能の統合

## [1.1.0] - 2025-07-09

### Added
- **セキュリティ機能**: Claude Code hooks による危険なコマンドブロック機能
- **Deny List**: システム破壊的コマンド・外部コード実行・権限昇格の自動ブロック
- **Allow List**: 開発に必要な安全なコマンドの事前許可システム
- **セキュリティスクリプト**: `.claude/scripts/deny-check.sh` と `.claude/scripts/allow-check.sh`
- **セキュリティテスト**: 自動テストスクリプト `.claude/scripts/test-security.sh`
- **セキュリティログ**: 実行コマンドの監査ログ機能
- **ドキュメント**: セキュリティ設定の詳細説明 `.claude/security-README.md`

### Security
- 危険なコマンドパターン（`rm -rf /`, `chmod 777`, `curl | sh`等）の自動検知・ブロック
- 開発用コマンド（`git`, `npm`, `python`, `eza`等）の安全な許可設定
- hooks設定による PreToolUse イベントでのリアルタイム監視
- セキュリティログによる実行履歴追跡

### Enhanced
- `.claude/settings.json` にセキュリティ設定を統合
- プロジェクトテンプレートのセキュリティ強化
- 開発効率を保ちながらセキュリティを向上

## [1.0.0] - 2025-06-22

### Added
- 汎用的開発テンプレート（言語・技術スタック非依存）
- Anthropicベストプラクティス統合
- 階層化Memory Bankシステム（core/context/archive構造）
- 軽量コマンドセット（基本4個+専門化3個）
- 開発規約（パッケージ管理・コード品質・Git/PR規約）
- 実行コマンド一覧（`[tool]`記法で言語非依存）
- エラー対応ガイド（問題解決順序・ベストプラクティス）
- 品質ゲート（段階別チェックリスト・自動化レベル分類）
- Git操作パターン・学習ログテンプレート
- タグ検索システム（#urgent #bug #feature #completed）

### Features
- 日次3分更新でMemory Bank維持
- コンテキスト使用量最小化
- 個人開発〜中規模プロジェクト対応
- AI主導開発フロー支援

### Initial Release
個人開発者向けの効率的なClaude Code開発テンプレートとして初回リリース