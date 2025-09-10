# Claude Friends Migration Guide

🌐 **[日本語](MIGRATION_GUIDE_ja.md)** | **English**

A comprehensive guide for migrating to the latest version of Claude Friends.

## 📌 Latest Version: v2.4.0

### 🚀 What's New in v2.4.0

#### Agent-First Development System
- **Entry Point**: `/agent:first` - Your development methodology guide
- **Enforced Flow**: Requirements → Design → Tasks → Implementation
- **Quality Gates**: Automatic validation at each stage
- **Stage Guard**: Checks completeness before progression

#### Enhanced Security System
- **100% Detection Rate**: All dangerous commands blocked
- **Expanded Patterns**: 10+ categories of dangerous commands
- **Security Audit**: Comprehensive scanning tools

#### Code Infrastructure
- **Shared Utilities**: `.claude/scripts/shared-utils.sh`
- **30% Code Reduction**: Demonstrated in refactored scripts
- **Standardized Operations**: Unified logging and utilities

## 🎉 Revolutionary Changes in v2.0.0

### Introduction of Claude Friends Multi-Agent System
- **Planner Agent**: Strategic planning & design documentation (with Mermaid diagrams)
- **Builder Agent**: Implementation, debugging, and code review
- **Smart Mode Switching**: Agents automatically switch to special modes based on context

### Major Command Simplification
- **Before**: 7+ commands
- **Now**: Just 4 core commands
- **Reduction**: Significant command reduction

## 🚨 Breaking Changes

### 1. Deprecated Commands

| Deprecated Command | New Method |
|-------------------|------------|
| `/project:plan` | Use `/agent:planner` |
| `/project:act` | Use `/agent:builder` |
| `/feature:plan` | Planner's Feature Design Mode (automatic) |
| `/debug:start` | Builder's Debug Mode (automatic) |
| `/review:check` | Builder's Code Review Mode |

### 2. New Agent Structure
```
.claude/
├── agents/          # NEW!
│   └── active.md    # Currently active agent
├── planner/         # NEW!
│   ├── identity.md  # Planner role definition
│   ├── notes.md     # Work notes
│   └── handover.md  # Handover document
├── builder/         # NEW!
│   ├── identity.md  # Builder role definition
│   ├── notes.md     # Implementation notes
│   └── handover.md  # Handover document
└── shared/          # NEW!
    ├── phase-todo.md    # Phase/ToDo management
    └── constraints.md   # Project constraints
```

### 3. Workflow Changes
- **Before**: Command-based development
- **Now**: Agent-based development
- **Benefits**: More natural dialogue, automatic context understanding

## 🔧 Migration Steps

### For v2.0.0 → v2.4.0 Migration

#### Step 1: Update Agent-First System
```bash
# Update settings.json with stage guard
# The system now automatically enforces proper development flow
```

#### Step 2: Apply Security Enhancements
```bash
# Test the enhanced security system
.claude/scripts/test-security.sh
# Should now block 100% of dangerous commands
```

#### Step 3: Leverage Shared Utilities
```bash
# Use shared-utils.sh for new scripts
source .claude/scripts/shared-utils.sh
# Reduces code duplication by ~30%
```

#### Step 4: Use Agent-First Entry Point
```bash
# Start all new development with:
/agent:first
# This ensures proper methodology from the start
```

### For v1.x → v2.0.0 Migration

#### Step 1: Backup
```bash
# Backup current configuration
cp -r .claude .claude_backup_v1
cp CLAUDE.md CLAUDE_backup_v1.md
```

### Step 2: Create New Agent Structure
```bash
# Create agent directories
mkdir -p .claude/agents
mkdir -p .claude/planner/archive
mkdir -p .claude/builder/archive
mkdir -p .claude/shared

# Initialize active.md
echo "# Active Agent\n\n## Current Agent: none\n\nLast updated: $(date +%Y-%m-%d)" > .claude/agents/active.md
```

### Step 3: Apply Latest Version
```bash
# Get latest version
git pull origin main

# Or manually copy v2.0.0 files
```

### Step 4: Migrate Commands

#### Daily Workflow Migration
```bash
# Previous workflow
/project:plan      # Planning
/project:act       # Implementation
/debug:start       # Debugging
/review:check      # Review

# New workflow
/agent:planner     # Planning & design (auto feature mode)
/agent:builder     # Implementation, debug, review (auto mode switching)
```

#### Update Custom Commands
If you have created custom commands:
1. Check `.claude/commands/`
2. Update references to deprecated commands
3. Adapt to new agent-based flow

### Step 5: Update CLAUDE.md
```bash
# Update major sections in CLAUDE.md
# - Custom commands section
# - Add Claude Friends system description
# - Remove deprecated command descriptions
```

### Step 6: Verification
```bash
# Check agent structure
ls -la .claude/agents/
ls -la .claude/planner/
ls -la .claude/builder/

# Test command operation
# Test Planner mode
"Please switch to planner mode"

# Test Builder mode  
"Please switch to builder mode"
```

## 📋 Migration Checklist

### For v2.4.0 Features
- [ ] `/agent:first` command works correctly
- [ ] Stage validation is active (try creating tasks without requirements)
- [ ] Security test shows 100% blocking rate
- [ ] Shared utilities library is accessible
- [ ] Documentation claims have been verified for accuracy

### For v2.0.0 Core Features
- [ ] Created backup
- [ ] Created agent directory structure
- [ ] Updated CLAUDE.md
- [ ] Updated references to deprecated commands
- [ ] `/agent:planner` works correctly
- [ ] `/agent:builder` works correctly
- [ ] Verified automatic special mode switching
- [ ] Understood handover.md creation process

## 🆕 Leveraging New Features

### 1. Smart Mode Switching
```
While using Planner:
"I want to design a new user authentication feature"
→ Automatically switches to Feature Design Mode and creates Mermaid diagrams

While using Builder:
Error occurs
→ Automatically switches to Debug Mode and analyzes root cause
```

### 2. Handover System
```bash
# When switching agents
1. Current agent creates handover.md
2. Includes recommendations for next agent
3. Enables smooth work continuation
```

### 3. Phase/ToDo Management
```
# Centralized management in shared/phase-todo.md
- Current Phase
- ToDos within Phase (priority order)
- Completed Phases
- Next Phase candidates
```

## ❓ Frequently Asked Questions

### Q: Why were commands reduced?
A: The agent system understands context and automatically switches to appropriate modes, eliminating the need for individual mode commands.

### Q: Where did the `/debug:start` functionality go?
A: Builder agent automatically enters Debug Mode when errors are detected. To manually activate, simply say "analyze this in debug mode".

### Q: What about `/feature:plan`'s detailed design documentation?
A: It's integrated into Planner agent and enhanced. It now creates more visual design documents that automatically include Mermaid diagrams.

### Q: How long does migration take?
A: About 30 minutes for typical projects. Allow 1 hour for heavily customized projects.

### Q: Can I revert to v1.x?
A: You can restore from backup, but you'll lose v2.0.0 benefits (cost reduction, efficiency improvements).

## 🚀 New Workflow Example After Migration

```
Morning start:
/agent:planner
"I want to complete the user management feature today"
→ Planner creates plan and design documents

Start implementation:
/agent:builder  
"Start implementation based on Planner's design"
→ Builder implements, tests, debugs as needed

Review:
"Review the implemented code in review mode"
→ Builder automatically switches to Code Review Mode

Daily retrospective:
/project:daily
→ Can be executed from any agent
```

## 📞 Support

If you have questions or issues about migration, please report them on GitHub Issues.

---

**Important**: Migration to v2.0.0 significantly improves the development experience. While there's an initial learning curve, you'll quickly appreciate the efficiency of the new workflow.