# Claude Friends Migration Guide

🌐 **English** | **[日本語](MIGRATION_GUIDE_ja.md)**

A comprehensive guide for migrating to the latest version of Claude Friends Templates.

## 📌 Latest Version: v2.5.0 (September 2025)

### 🎯 Choose Your Migration Path

#### For New Users
Start with our **[Getting Started Guide](GETTING_STARTED.md)** - designed specifically for beginners.

#### For Existing Users
Choose your comfort level:
- **Conservative**: Try minimal features first (15 minutes)
- **Progressive**: Gradually adopt features over 1-2 weeks
- **Comprehensive**: Full migration with all features

---

## 🌟 What's New in v2.5.0 - Phase 2 Enhancements

### Intelligent Automation
- **Smart Memory Bank**: Automatic rotation with importance scoring (0-100)
- **Parallel Processing**: Up to 10 concurrent subagent execution
- **TDD Enforcement**: t-wada style Test-Driven Development validation
- **Advanced Monitoring**: Prometheus-format metrics and AI-optimized logging

### Gradual Learning Path
- **Minimal Configuration**: Start with just 2 commands using `settings-minimal.json`
- **Progressive Enhancement**: Unlock features as you grow comfortable
- **Full Power Mode**: Access everything with `settings-full.json`

---

## 🚀 Migration from v2.4.x to v2.5.0

### Option 1: Minimal Start (Recommended)

#### Step 1: Backup Current Configuration
```bash
# Always create a backup first
tar -czf claude-backup-$(date +%Y%m%d).tar.gz .claude/
```

#### Step 2: Get Minimal Configuration
```bash
# Download minimal settings (just agent switching + security)
curl -o .claude/settings-minimal.json \
  https://raw.githubusercontent.com/sougetuOte/claude-friends-templates/v2.5.0/.claude/settings-minimal.json

# Try it for a week
cp .claude/settings-minimal.json .claude/settings.json
```

#### Step 3: Use Core Features Only
```bash
/agent:planner  # Planning and design
/agent:builder  # Implementation
# That's it! Everything else runs automatically
```

### Option 2: Progressive Adoption (1-2 Weeks)

#### Week 1: Core Features
- Agent switching with auto-handover
- Security command blocking
- Minimal configuration

#### Week 2: Convenience Features
- Experience Memory Bank auto-rotation
- Try AI-powered error analysis
- Keep using the same 2 commands

#### Week 3+: Advanced Features (If Needed)
```bash
# Ready for everything?
cp .claude/settings-full.json .claude/settings.json
```

### Option 3: Full Migration (Advanced Users)

#### Prerequisites
- Comfortable with all v2.4.0 features
- Team needs parallel processing or TDD enforcement
- Production environment requiring metrics

#### Full Migration Steps
```bash
# 1. Get all v2.5.0 configurations
git pull origin main

# 2. Copy full settings
cp .claude/settings-full.json .claude/settings.json

# 3. Install all hook scripts
chmod +x .claude/hooks/**/*.sh
chmod +x .claude/scripts/*.sh

# 4. Verify installation
.claude/scripts/test-hooks.sh
```

---

## 📊 Feature Adoption Guide

### Essential Features (Start Here)
| Feature | Purpose | When to Use |
|---------|---------|-------------|
| Agent Switching | Automatic role management | Always |
| Auto Handover | Context preservation | Always |
| Security Blocking | Prevent dangerous commands | Always |

### Convenience Features (Week 2+)
| Feature | Purpose | When to Use |
|---------|---------|-------------|
| Memory Bank Rotation | Smart notes management | When notes.md > 500 lines |
| AI Log Analysis | Faster debugging | When errors occur |
| Importance Scoring | Preserve critical info | Automatic |

### Advanced Features (Optional)
| Feature | Purpose | When to Use |
|---------|---------|-------------|
| Parallel Execution | Multiple task processing | Large projects |
| TDD Enforcement | Quality gates | Team development |
| Metrics Monitoring | System observability | Production |

---

## 🔄 Migration from Older Versions

### From v2.4.0 → v2.5.0
See detailed steps above. Main additions:
- Phase 2 enhancement features
- Gradual learning path support
- Performance optimizations

### From v2.0.0 → v2.5.0
1. First migrate to v2.4.0 (see section below)
2. Then follow v2.5.0 migration steps above

### From v1.x → v2.5.0
1. Complete v2.0.0 migration first
2. Then follow progressive path to v2.5.0

---

## 📌 Previous Version: v2.4.0

### What Was New in v2.4.0

#### Agent-First Development System
- **Entry Point**: `/agent:first` - Development methodology guide
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

---

## 🎉 v2.0.0 Revolutionary Changes

### Introduction of Claude Friends Multi-Agent System
- **Planner Agent**: Strategic planning & design documentation
- **Builder Agent**: Implementation, debugging, and code review
- **Smart Mode Switching**: Automatic context-based mode changes

### Major Command Simplification
- **Before**: 7+ commands
- **Now**: Just 4 core commands
- **Reduction**: Significant command simplification

---

## 🚨 Breaking Changes History

### v2.0.0 Breaking Changes

| Deprecated Command | New Method |
|-------------------|------------|
| `/project:plan` | Use `/agent:planner` |
| `/project:act` | Use `/agent:builder` |
| `/feature:plan` | Planner's Feature Design Mode (automatic) |
| `/debug:start` | Builder's Debug Mode (automatic) |
| `/review:check` | Builder's Code Review Mode |

---

## ⚡ Quick Recovery Options

### Rollback to Previous Version
```bash
# Quick rollback to minimal configuration
cp .claude/settings-minimal.json .claude/settings.json

# Full rollback to backup
rm -rf .claude
tar -xzf claude-backup-*.tar.gz
```

### Selective Feature Disable
```json
// In .claude/settings.json, comment out unwanted features
{
  "hooks": {
    "UserPromptSubmit": [
      // Keep only what you need
      {
        "matcher": "/agent:",
        "command": ".claude/hooks/agent/agent-switch.sh"
      }
    ]
    // Comment out advanced features
    // "PostToolUse": [...]
  }
}
```

---

## 📋 Migration Checklist

### v2.5.0 Migration
- [ ] Created backup of current configuration
- [ ] Reviewed [Getting Started Guide](GETTING_STARTED.md)
- [ ] Chose migration approach (Minimal/Progressive/Full)
- [ ] Tested with settings-minimal.json
- [ ] Understood rollback procedures
- [ ] Read about new features in [README](README.md)

### Core Functionality Tests
- [ ] `/agent:planner` switches correctly
- [ ] `/agent:builder` switches correctly
- [ ] Handover.md generates automatically
- [ ] Security blocking works
- [ ] Basic workflow unchanged

### Progressive Feature Tests
- [ ] Memory Bank rotation triggers at 500 lines
- [ ] AI logs generate in JSONL format
- [ ] Error analysis provides insights
- [ ] Performance remains acceptable

---

## ❓ Frequently Asked Questions

### Q: Will v2.5.0 break my existing workflow?
**A:** No. With `settings-minimal.json`, you get the same workflow plus auto-handover and security. Other features are optional.

### Q: How long does migration take?
**A:**
- Minimal: 15 minutes
- Progressive: 1-2 weeks of gradual adoption
- Full: 1-2 hours for complete setup

### Q: Can I rollback if something goes wrong?
**A:** Yes. Simply restore from backup or use `settings-minimal.json` for instant simplification.

### Q: Do I need all the new features?
**A:** No. Most users only need 20% of features for 80% of the value. Start small.

### Q: Will my existing agents (Planner/Builder) still work?
**A:** Yes. v2.5.0 enhances them without changing their core behavior.

### Q: What about my custom hooks and scripts?
**A:** They remain compatible. New hooks are additive, not replacements.

### Q: Is the parallel execution feature stable?
**A:** Yes, but it's optional. Only enable if you have tasks that benefit from parallelization.

### Q: How do I know which features to adopt?
**A:** Start with minimal configuration. If you find yourself wanting more automation, gradually enable features.

---

## 🎯 Success Metrics

You'll know migration is successful when:
- ✅ Basic commands work (`/agent:planner`, `/agent:builder`)
- ✅ Handover documents generate automatically
- ✅ Dangerous commands are blocked
- ✅ Your workflow feels smoother, not more complex

---

## 📞 Support

- **Documentation**: [Getting Started](GETTING_STARTED.md) | [README](README.md) | [CHANGELOG](CHANGELOG.md)
- **Issues**: Report on [GitHub Issues](https://github.com/sougetuOte/claude-friends-templates/issues)
- **Best Practice**: Start small, grow naturally

---

**Remember**: You don't need to use every feature. The best migration is the one that enhances your workflow without overwhelming you. Start with `settings-minimal.json` and let your needs guide feature adoption. 🌱
