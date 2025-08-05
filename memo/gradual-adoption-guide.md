# Gradual Migration Guide for Existing Projects

A practical guide for gradually introducing new features from the previous generation memory bank system to projects already in operation.

## 🎯 Available Techniques Overview

### 🟢 Immediately Applicable (Risk: Very Low)
1. **Prompt Cache Optimization**
2. **Enhanced .gitignore**
3. **Typo and Consistency Fixes**
4. **Security Feature Implementation**
5. **AI-Friendly Logger (New Feature)**

### 🟡 Recommended for Gradual Introduction (Risk: Low)
6. **ADR System**
7. **Technical Debt Tracking**

### 🔴 Requires Careful Consideration (Risk: Medium)
8. **Memory Bank Structure Changes**

---

## 🚀 Phase 1: Immediately Applicable (Time Required: 20 minutes)

### 1.1 Prompt Cache Optimization

#### Philosophy
- Enjoy **90% cost reduction and 85% latency reduction** benefits in existing projects
- **Zero impact** on existing workflows
- Improve reuse efficiency of long-term stable information (overview, tech stack, etc.)

#### Implementation Steps

**Step 1: Create Environment Configuration File**
```bash
# Execute in project root
touch .claude/settings.json
```

**Step 2: Add Cache Settings**
```json
// .claude/settings.json
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  }
}
```

**Step 3: Apply cache_control**
Add `cache_control` to the following files (if they exist):

```yaml
---
cache_control: {"type": "ephemeral"}
---
```

**Target Files**:
- Project overview files (overview.md, README files)
- Technical specification files (tech.md, requirements.md)
- Template and pattern collections

**Step 4: Update .gitignore**
```gitignore
# Claude Code cache files
.ccache/
*.cache
```

#### Expected Benefits
- **Immediate**: Significant cost reduction with identical prompt re-execution
- **Cumulative**: Token usage optimization in long-term operation

### 1.2 Enhanced .gitignore

#### Philosophy
- Proper exclusion of cache files
- Development environment organization and unification

#### Implementation Steps
Add the following to existing `.gitignore`:

```gitignore
# Claude Code related
.ccache/
*.cache

# Common exclusion patterns (as needed)
.DS_Store
*.swp
*.tmp
.env
.vscode/settings.json
```

### 1.3 Typo and Consistency Fixes

#### Philosophy
- Improve document quality
- Enhance team communication

#### Implementation Steps
Unify the following terms:
- "連用" → "運用" (operation)
- "遵用" → "運用" (operation)
- Unify detail level of custom command descriptions

### 1.4 Security Feature Implementation

#### Philosophy
- Reduce security risks with **automatic blocking of dangerous commands**
- Improve safety while maintaining development efficiency
- Minimal impact on existing workflows

#### Implementation Steps

**Step 1: Create Security Script Directory**
```bash
mkdir -p .claude/scripts
```

**Step 2: Install Security Scripts**
[Copy security scripts - .claude/scripts/deny-check.sh, allow-check.sh]

**Step 3: Grant Execution Permissions**
```bash
chmod +x .claude/scripts/*.sh
```

**Step 4: Add Security Settings to settings.json**
```json
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/deny-check.sh"
          }
        ]
      }
    ]
  }
}
```

**Step 5: Run Security Tests**
```bash
.claude/scripts/test-security.sh
```

#### Expected Benefits
- **Immediate**: Automatic blocking of dangerous commands
- **Continuous**: Maintain safe development environment
- **Logging**: Trackable command execution history

### 1.5 AI-Friendly Logger Implementation (New Feature)

#### Philosophy
- Improve debugging efficiency with **log format optimized for AI analysis**
- Realize AI-driven development (VibeCoding) by adopting **Vibe Logger concept**
- Enable gradual migration with parallel operation alongside existing log system

#### Implementation Steps

**Step 1: Verify Script Directory**
```bash
mkdir -p .claude/scripts
```

**Step 2: Download AI Logger Scripts**
Copy the following files from the latest template:
- `.claude/scripts/ai-logger.sh`
- `.claude/scripts/analyze-ai-logs.py`
- `.claude/ai-logger-README.md`

**Step 3: Grant Execution Permissions**
```bash
chmod +x .claude/scripts/ai-logger.sh
chmod +x .claude/scripts/analyze-ai-logs.py
```

**Step 4: Add AI Logger to settings.json**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/activity-logger.sh"
          },
          {
            "type": "command",
            "command": ".claude/scripts/ai-logger.sh"
          }
        ]
      }
    ]
  }
}
```

**Step 5: Verify Operation**
```bash
# Test file creation and deletion
echo "test" > test.txt && rm test.txt

# Verify AI log generation
ls -la ~/.claude/ai-activity.jsonl

# Test log analysis
.claude/scripts/analyze-ai-logs.py --format summary
```

#### Expected Benefits
- **Immediate**: Enriched debug information through structured logs
- **Short-term**: Visualization and analysis of error patterns
- **Long-term**: Significantly improved debugging efficiency with AI support

#### References
- [Vibe Logger](https://github.com/fladdict/vibe-logger) by @fladdict
- [Proposal for AI Agent Logging System "Vibe Logger"](https://note.com/fladdict/n/n5046f72bdadd)

---

## 📈 Phase 2: Recommended for Gradual Introduction (Time Required: 30 minutes)

### 2.1 ADR System Implementation

#### Philosophy
- **Transparency of technical decision-making**
- Clarify "why that technology was chosen" for future changes and maintenance
- Team knowledge accumulation and inheritance

#### Implementation Steps

**Step 1: Create Directory**
```bash
mkdir -p docs/adr
```

**Step 2: Place Template**
[Copy ADR template content - docs/adr/template.md]

**Step 3: Retroactive Recording of Existing Decisions**
```bash
# Record past important decisions one by one
cp docs/adr/template.md docs/adr/0001-initial-tech-stack.md
# Edit content to match past decisions
```

#### Recommended Operations
- **When introducing new technology**: Always create ADR
- **When changing architecture**: Document background and reasons
- **Monthly**: Review ADRs to confirm decision validity

#### Expected Benefits
- **Immediate**: Clarify rationale for technical choices
- **Long-term**: Prevent technical debt

### 2.2 Technical Debt Tracking

#### Philosophy
- **Debt management through visualization**
- Efficient resolution through prioritization
- Cost management considering cache impact

#### Implementation Steps

**Step 1: Create Debt Log File**
```bash
touch .claude/context/debt.md
```

**Step 2: Inventory Existing Debt**
```markdown
# List currently recognized technical debt
### High Priority 🔥
| Debt Content | Estimated Cost | Deadline | Impact Range |
|--------------|----------------|----------|--------------|
| Old library dependencies | 4 hours | End of next month | Overall |
```

**Step 3: Establish Operating Rules**
- **During new feature development**: Pre-record potential debt
- **At sprint end**: Prioritize actually incurred debt
- **Monthly**: Review overall debt

#### Expected Benefits
- **Immediate**: Debt visualization and priority clarification
- **Medium-term**: Planned debt resolution
- **Long-term**: Debt occurrence prevention

---

## ⚠️ Phase 3: Requires Careful Consideration (Time Required: 1-2 hours)

### 3.1 Memory Bank Structure Changes

#### Philosophy
- **Efficiency through hierarchization**
- **Minimize context usage**

#### Cautions
- Major impact on existing workflows
- Requires team-wide consensus
- Gradual migration recommended

#### Implementation Criteria
Implement only when all conditions are met:
- [ ] Team-wide consensus obtained
- [ ] Experiencing inconvenience with current system
- [ ] Migration period (1-2 weeks) can be secured
- [ ] Rollback procedures prepared

#### Implementation Steps (After Consensus)
```bash
# Backup existing files
cp -r .claude .claude.backup

# Create new structure directories
mkdir -p .claude/context
mkdir -p .claude/debug  
mkdir -p .claude/commands

# Gradual migration
# Move one item per week
```

---

## 📋 Implementation Checklist

### Phase 1 (Immediate Implementation)
- [ ] Create .claude/settings.json
- [ ] Apply cache_control (identify and add to target files)
- [ ] Update .gitignore
- [ ] Unify terminology (fix typos)
- [ ] Implement security features (install scripts and run tests)
- [ ] Implement AI Logger (install scripts and verify operation)
- [ ] Verify cache effectiveness (experience cost reduction)

### Phase 2 (Gradual Implementation)
- [ ] Create ADR directory and template
- [ ] Document 1-2 past technical decisions as ADRs
- [ ] Create debt log file
- [ ] Complete existing debt inventory
- [ ] Set operating rules and share with team

### Phase 3 (Careful Consideration)
- [ ] Obtain team consensus
- [ ] Develop migration plan
- [ ] Take backups
- [ ] Implement gradual migration

---

## 🎯 Success Pattern Examples

### Case 1: Small Personal Project
**Applied**: Phase 1 + ADR System
**Result**: 30% cost reduction, technical choice documentation
**Duration**: 1 day

### Case 2: Medium-sized Team Project
**Applied**: Phase 1 + Complete Phase 2 implementation
**Result**: 50% cost reduction, planned debt resolution
**Duration**: 2 weeks (gradual introduction)

### Case 3: Large-scale Project
**Applied**: Phase 1 only
**Result**: Safe and certain cost reduction only
**Duration**: Half day

---

## ⚡ Troubleshooting

### Common Issues

**Q: Error occurs after adding cache_control**
A: Check YAML frontmatter format. Check for conflicts with existing content

**Q: Cannot feel cache effect**
A: Verify identical prompt re-execution. Check usage frequency of cache_control target files

**Q: ADR doesn't continue**
A: Start with important decisions only. Focus on continuation rather than perfection

**Q: Debt log becomes a formality**
A: Monthly review is essential. Regularly review priorities

---

## 📊 Effectiveness Measurement Metrics

### Quantitative Metrics
- **Cost reduction rate**: Billing comparison with cache hits
- **Response time reduction**: Identical prompt execution time comparison
- **Debt resolution rate**: Monthly debt completion count

### Qualitative Metrics
- **Technical choice transparency**: Decision quality through ADR utilization
- **Team knowledge sharing**: New member onboarding speed
- **Development efficiency**: Work interruption frequency due to debt

This gradual introduction allows existing projects to safely and certainly enjoy the benefits of the new template.