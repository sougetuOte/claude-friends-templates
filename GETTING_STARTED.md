# 🚀 Claude Friends Templates - Get Up and Running in 5 Minutes

🌐 **English** | **[日本語](GETTING_STARTED_ja.md)**

> **For newcomers**: This guide helps you learn Claude Friends with a **progressive enhancement approach** - start minimal, scale as needed

## 🎯 Developer-First Experience

Claude Friends Templates is incredibly powerful, but **you don't need to use everything at once**.
Start with minimal setup and gradually add features as your project grows. Focus on reducing friction and boosting productivity from day one.

---

## 📱 Day 1: Start with Minimal Setup (5 minutes)

### 1. One-Command Minimal Setup

```bash
# Copy minimal configuration (this is all you need!)
cp .claude/settings-minimal.json .claude/settings.json
```

### 2. Just Two Commands to Remember

```bash
/agent:planner  # For planning & design work
/agent:builder  # For implementation & coding
```

**That's it!** Forget about other features for now.

### 3. Basic Workflow

```bash
# Morning: Starting your work session
/agent:planner
"Let's build a user authentication feature today"

# Moving to implementation
/agent:builder
"Implementing based on Planner's design"
# → Automatic handover.md is created for you
```

---

## 🎓 Progressive Enhancement Path

### 🥚 **Week 1: Master the Basics**

**Focus on**:
- Switch between `/agent:planner` and `/agent:builder` only
- Observe the auto-generated `handover.md` files
- Experience security blocks (automatic prevention of dangerous commands)

**Safely ignore**:
- Parallel execution, metrics, TDD enforcement - all advanced features
- Complex configuration files
- Testing frameworks

**Checkpoint**:
- [ ] Comfortable switching between agents
- [ ] Understand handover.md auto-generation
- [ ] Found your development rhythm

---

### 🐣 **Week 2-4: Add Convenience Features**

**Try these new things**:
```bash
# When notes.md exceeds 500 lines, automatic rotation happens
# → Important information is automatically preserved
```

```bash
# When errors occur, check AI-optimized logs
cat ~/.claude/ai-activity.jsonl | tail -20
python .claude/scripts/analyze-ai-logs.py --errors-only
```

**Still ignore**:
- Parallel execution
- Prometheus metrics
- specialists.yaml

**Checkpoint**:
- [ ] Experienced Memory Bank auto-rotation
- [ ] Used AI logs for error analysis
- [ ] Feel more productive than before

---

### 🦅 **Month 2+: Scale to Advanced Features**

**When you're ready**:
```bash
# Enable full features (only when you feel the need)
cp .claude/settings-full.json .claude/settings.json
```

**Advanced features include**:
- **Parallel execution**: Handle multiple tasks simultaneously (for large projects)
- **TDD enforcement**: Automatic test-first validation
- **Metrics monitoring**: Visualize system health

**Decision criteria**:
- Team of 3+ people → Consider parallel execution
- Quality-focused → Enable TDD enforcement
- Long-term project → Add metrics monitoring

---

## ⚠️ Common Misconceptions

### ❌ **Wrong mindset**
- "I must use all features or I'm wasting it"
- "I need to understand every setting before starting"
- "Start with full configuration from day one"

### ✅ **Right mindset**
- "Use only what you need"
- "Learn while doing"
- "Start minimal, enhance progressively"

---

## 🆘 Troubleshooting

### Q: Too many features, feeling overwhelmed
**A**: Return to minimal settings
```bash
cp .claude/settings-minimal.json .claude/settings.json
```

### Q: Errors with unclear causes
**A**: Use AI log analysis
```bash
python .claude/scripts/analyze-ai-logs.py --format summary
```

### Q: Don't know which features to use
**A**: Two basic commands are sufficient
- `/agent:planner` - Planning
- `/agent:builder` - Implementation

### Q: Want to revert to previous state
**A**: You can always rollback
```bash
# Revert to v2.4.0 (before current updates)
git checkout v2.4.0 .claude/
```

---

## 📊 Feature Necessity Checklist

Assess which features your project actually needs:

| Feature | When You Need It | Your Situation |
|---------|-----------------|----------------|
| **Agent switching** | Almost everyone | ☐ |
| **Auto handover** | Almost everyone | ☐ |
| **Security blocks** | Almost everyone | ☐ |
| **Memory Bank automation** | notes.md frequently exceeds 500 lines | ☐ |
| **AI log analysis** | Want to reduce debugging time | ☐ |
| **Parallel execution** | Large-scale projects | ☐ |
| **TDD enforcement** | Team development with quality control | ☐ |
| **Metrics** | Long-term operation & monitoring | ☐ |

---

## 🎯 First Week Goals

1. **Day 1-2**: Get comfortable with agent switching
2. **Day 3-4**: Understand handover.md content
3. **Day 5-7**: Find your personal workflow rhythm

**Remember**:
> 💡 Using just **20% of Claude Friends features gives you 80% of the value**

---

## 📚 Next Steps

Once you're comfortable, explore these documents:

1. **[README.md](README.md)** - Complete feature overview
2. **[Claude Friends Guide](.claude/claude-friends-guide.md)** - Agent details
3. **[Hooks README](.claude/hooks-README.md)** - Automation features

---

**Final note**: Don't rush. Use your own pace. Use only the features you need. That's the secret to maximizing Claude Friends! 🚀