# Migration Guide: Adopting Enhanced claude-friends-templates

## Overview

This guide helps existing users migrate to the enhanced version of claude-friends-templates, which now includes powerful features from claude-kiro-template.

## What's New

### Major Enhancements

1. **Test-Driven Development (TDD) Integration**
   - Red-Green-Refactor cycle support
   - Task status tracking (🔴 → 🟢 → ✅)
   - TDD commands and workflows

2. **Enhanced Design Synchronization**
   - Design-implementation alignment tools
   - ADR (Architecture Decision Records) templates
   - Design change tracking

3. **Error Pattern Library**
   - Common error patterns database
   - Quick error resolution
   - AI-learning from past errors

4. **Integrated Test Framework**
   - Unit, integration, and E2E test templates
   - Mock generation utilities
   - CI/CD integration guides

5. **Optimized Agent Coordination**
   - Compressed handover documents
   - Parallel task execution
   - Shared context management

## Migration Steps

### Step 1: Backup Current Project

```bash
# Create a backup of your current setup
cp -r /path/to/your/project /path/to/your/project.backup

# Or use git
git checkout -b pre-migration-backup
git commit -am "Backup before migration"
```

### Step 2: Update Templates

```bash
# Clone the enhanced templates
git clone https://github.com/yourusername/claude-friends-templates.git
cd claude-friends-templates

# Copy enhanced .claude directory to your project
cp -r .claude /path/to/your/project/
```

### Step 3: Merge Configuration

#### Update CLAUDE.md

Add the following sections to your existing CLAUDE.md:

```markdown
## TDD Workflow
- Follow Red-Green-Refactor cycle
- Use task status indicators
- Run `/tdd:start` to begin TDD session

## Error Handling
- Search error patterns: `python .claude/shared/error-patterns/search-patterns.py "error"`
- Add new patterns when discovering unique errors

## Testing Strategy
- Use provided test templates
- Aim for 80% code coverage
- Run tests before commits
```

#### Update settings.json

```json
{
  "project": {
    "tdd": {
      "enabled": true,
      "enforcement": "recommended",
      "coverage_target": 80
    },
    "error_patterns": {
      "auto_search": true,
      "contribute_new": true
    },
    "agent_coordination": {
      "handover_optimization": "high",
      "parallel_execution": true
    }
  }
}
```

### Step 4: Initialize New Features

```bash
# Initialize error patterns
python .claude/shared/error-patterns/search-patterns.py --stats

# Test the test framework
cp .claude/shared/test-framework/templates/unit/[language]/basic_test_template.[ext] tests/

# Verify agent coordination
python .claude/shared/agent-coordination/optimizers/parallel-analyzer.py --help
```

### Step 5: Update Agent Instructions

#### For Planner Agent

Add to `.claude/agents/planner/instructions.md`:

```markdown
## Enhanced Capabilities

### Design Synchronization
- Create ADRs for significant decisions
- Track design changes in design-tracker
- Use `/adr:create` for new decisions

### Task Planning
- Include TDD requirements in tasks
- Identify parallel execution opportunities
- Use optimized handover templates
```

#### For Builder Agent

Add to `.claude/agents/builder/instructions.md`:

```markdown
## Enhanced Capabilities

### TDD Implementation
- Start with failing tests (🔴)
- Implement minimal code (🟢)
- Refactor when working (✅)

### Error Resolution
- Search error patterns before debugging
- Document new error patterns
- Use mock generator for testing
```

## Feature-by-Feature Migration

### Adopting TDD

1. **Start Small**: Begin with new features
2. **Update Existing Tests**: Gradually convert to TDD style
3. **Use Status Tracking**: Mark tasks with appropriate status

Example workflow:
```bash
# Start TDD session
/tdd:start

# Check current status
/tdd:status

# Update task status in task.md
🔴 Implement user authentication
🟢 Implement user authentication (tests passing)
✅ Implement user authentication (refactored)
```

### Using Error Patterns

1. **Search First**: Before debugging, search patterns
2. **Learn Patterns**: Review common patterns for your language
3. **Contribute**: Add new patterns you discover

```bash
# Search for TypeError patterns
python .claude/shared/error-patterns/search-patterns.py TypeError

# View all Python patterns
python .claude/shared/error-patterns/search-patterns.py -l python
```

### Implementing Tests

1. **Copy Templates**: Start with provided templates
2. **Customize**: Adapt to your project structure
3. **Integrate CI/CD**: Use provided configurations

```bash
# Copy test template
cp .claude/shared/test-framework/templates/unit/python/basic_test_template.py tests/

# Generate mock data
python .claude/shared/test-framework/mocks/mock-generator.py
```

### Optimizing Handovers

1. **Use Templates**: Switch to optimized templates
2. **Enable Compression**: Set high compression for large projects
3. **Monitor Efficiency**: Track handover sizes

```bash
# Optimize existing handover
python .claude/shared/agent-coordination/optimizers/handover-optimizer.py \
  handover.md -o handover-optimized.md -c high
```

## Common Migration Issues

### Issue 1: Conflicting File Structure

**Problem**: Existing files conflict with new structure

**Solution**:
```bash
# Merge instead of replace
diff -r .claude.old .claude.new
# Manually merge conflicting files
```

### Issue 2: Command Conflicts

**Problem**: New commands conflict with existing ones

**Solution**:
```markdown
# In .claude/commands/, rename conflicting commands
mv tdd-commands.md tdd-commands-v2.md
# Update references in CLAUDE.md
```

### Issue 3: Large Existing Codebase

**Problem**: Too many files to update at once

**Solution**:
- Migrate incrementally
- Start with new modules
- Update during refactoring

## Rollback Plan

If issues arise:

```bash
# Restore from backup
cp -r /path/to/project.backup/* /path/to/project/

# Or use git
git checkout pre-migration-backup
```

## Best Practices

### 1. Gradual Adoption
- Don't force all features at once
- Let team adapt gradually
- Start with most beneficial features

### 2. Team Training
- Review new features with team
- Practice TDD together
- Share error patterns discovered

### 3. Customization
- Adapt templates to your style
- Create project-specific patterns
- Optimize for your workflow

### 4. Continuous Improvement
- Collect feedback
- Refine processes
- Contribute improvements back

## Verification Checklist

- [ ] All files copied successfully
- [ ] No conflicts in commands
- [ ] Settings properly merged
- [ ] Test framework operational
- [ ] Error patterns accessible
- [ ] Agent coordination working
- [ ] TDD workflow understood
- [ ] Team onboarded

## Support

### Getting Help

1. Check documentation in `.claude/shared/*/README.md`
2. Search error patterns for issues
3. Review example implementations
4. Submit issues to repository

### Contributing Back

Share your:
- New error patterns
- Test templates
- Integration examples
- Process improvements

## Next Steps

1. **Week 1**: Basic setup and familiarization
2. **Week 2**: Start using TDD for new features
3. **Week 3**: Integrate test framework
4. **Week 4**: Optimize agent coordination
5. **Month 2**: Full team adoption

Remember: The goal is to enhance your development process, not disrupt it. Adopt features that provide immediate value and gradually expand usage.
