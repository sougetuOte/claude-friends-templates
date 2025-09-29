# Document Structure Overview

🌐 **English** | **[日本語](DOCUMENT_STRUCTURE_ja.md)**

## 📁 Organization Principle

This project follows a **role-based document organization**:

### .claude/guidelines/
**Purpose**: Quick reference for daily development
**Audience**: Developers actively working on the project
**Characteristics**: Concise, practical, frequently referenced

### docs/
**Purpose**: Detailed specifications, rules, and formal documentation
**Audience**: New team members, reviewers, architects
**Characteristics**: Comprehensive, authoritative, versioned

### memo/
**Purpose**: Work notes, analysis results, temporary documentation
**Audience**: Project maintainers, specific task owners
**Characteristics**: Informal, evolving, task-specific

## 📋 Document Mapping

### Development Guidelines

| Topic | Quick Reference | Detailed Documentation |
|-------|----------------|----------------------|
| **Development Rules** | `.claude/guidelines/development.md` | `docs/development-rules.md` |
| **Git Workflow** | `.claude/guidelines/git-workflow.md` | Authoritative source |
| **Testing & Quality** | `.claude/guidelines/testing-quality.md` | Authoritative source |
| **AI-Friendly Dev** | `.claude/guidelines/ai-friendly-development.md` | Authoritative source |

### Security & Hooks

| Topic | Configuration | Documentation |
|-------|--------------|---------------|
| **Security** | `.claude/settings.json` | `.claude/security-README.md` |
| **Hooks** | `.claude/hooks.yaml` | `.claude/hooks-README.md` |
| **AI Logger** | `.claude/scripts/ai-logger.sh` | `.claude/ai-logger-README.md` |

### Project Documentation

| Document Type | Location | Purpose |
|--------------|----------|---------|
| **Requirements** | `docs/requirements/index.md` | Project specifications |
| **ADR Template** | `docs/adr/template.md` | Architecture decisions |
| **Getting Started** | `docs/GETTING_STARTED.md` | Onboarding guide |
| **Examples** | `examples/` | Sample implementations |

### Migration & Adoption

| Guide | Location | Target Audience |
|-------|----------|----------------|
| **v2.0 Migration** | `MIGRATION_GUIDE.md` | Existing Claude Friends users |
| **Gradual Adoption** | `memo/gradual-adoption-guide.md` | Projects new to Memory Bank |
| **Zero to Memory Bank** | `memo/zero-to-memory-bank.md` | Complete beginners |

## 🔍 How to Find Information

### "I need to..."

- **Quickly check commit format** → `.claude/guidelines/git-workflow.md`
- **Understand all development rules** → `docs/development-rules.md`
- **Set up a new project** → `docs/GETTING_STARTED.md`
- **Add security hooks** → `.claude/security-README.md`
- **Learn about TDD** → `.claude/guidelines/testing-quality.md`
- **Make architectural decisions** → `docs/adr/template.md`

### By Role

**New Developer**:
1. Start with `README.md`
2. Read `docs/GETTING_STARTED.md`
3. Reference `.claude/guidelines/` for daily work

**Architect/Lead**:
1. Review `docs/development-rules.md`
2. Check `docs/adr/` for past decisions
3. Use `CLAUDE.md` for project configuration

**Maintainer**:
1. Monitor `memo/` for ongoing work
2. Update `.claude/guidelines/` as needed
3. Manage `docs/` for formal changes

## 🚫 Anti-patterns to Avoid

1. **Don't duplicate content** - Use references instead
2. **Don't create similar filenames** - Be descriptive and unique
3. **Don't mix roles** - Keep quick references separate from detailed docs
4. **Don't forget to update** - Keep references in sync

## 📝 Maintenance Guidelines

### When Adding New Documentation

1. **Determine the role**: Is it a quick reference or detailed documentation?
2. **Check for existing content**: Avoid duplication
3. **Use clear naming**: Descriptive, not confusing
4. **Add to this mapping**: Update DOCUMENT_STRUCTURE.md
5. **Create cross-references**: Link related documents

### Regular Maintenance

- **Weekly**: Review `memo/` for outdated content
- **Monthly**: Check for broken references
- **Quarterly**: Audit for duplications
- **Yearly**: Major structure review

---

*Last updated: 2025-08-05*
*Maintainer: Claude Friends Template Team*
