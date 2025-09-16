# Claude Friends Templates - .claude Directory

🌐 **English** | **[日本語](README_ja.md)**

Welcome to the heart of the claude-friends-templates system! This directory contains all the configuration, agents, scripts, and templates that power our multi-agent AI development environment.

## 📁 Directory Structure

```
.claude/
├── 📋 Configuration & Settings
│   ├── settings.json           # Claude Code configuration
│   ├── hooks.yaml             # Alternative hooks configuration
│   └── *.config.json          # Feature-specific configurations
│
├── 🤖 Agent System
│   ├── agents/                # Agent definitions and configurations
│   ├── planner/               # Planner agent workspace
│   ├── builder/               # Builder agent workspace
│   └── sync-specialist/       # Synchronization agent workspace
│
├── 🔧 Scripts & Automation
│   ├── scripts/               # Automation scripts and utilities
│   ├── hooks/                 # Claude Code hooks implementation
│   └── patches/               # Security and functionality patches
│
├── 📚 Shared Resources
│   ├── shared/                # Common templates and utilities
│   ├── commands/              # Command definitions
│   └── guidelines/            # Development guidelines
│
├── 🧪 Testing Infrastructure
│   ├── tests/                 # Test suites and frameworks
│   └── archive/               # Archived components
│
└── 📖 Documentation
    ├── README.md              # This file
    ├── ARCHITECTURE.md        # System architecture
    ├── BEST_PRACTICES.md      # Development best practices
    └── *-README*.md           # Feature-specific documentation
```

## 🚀 Getting Started

### Quick Setup
1. **Clone the repository**: The .claude directory is automatically configured
2. **Install dependencies**: No additional installation required for basic features
3. **Start using**: Commands like `/agent:planner` and `/agent:builder` work immediately

### Basic Commands
```bash
# Switch to Planner agent
/agent:planner

# Switch to Builder agent
/agent:builder

# Focus on specific area
/project:focus

# Daily status check
/project:daily
```

## 🤖 Multi-Agent System

Our system features specialized agents that work together:

- **🎯 Planner Agent**: Strategic planning, architecture design, requirements analysis
- **🔨 Builder Agent**: Implementation, coding, testing, debugging
- **🔄 Sync Specialist**: State synchronization and handover management
- **🛡️ Security Auditor**: Security analysis and vulnerability detection
- **✅ Test Writer**: Test-driven development and quality assurance

### Agent Coordination
Agents automatically synchronize state through:
- Structured handover documents
- Shared memory banks in `/memo/`
- TDD phase tracking (🔴 Red → 🟢 Green → 🔵 Refactor)
- Real-time activity logging

## 🔧 Key Features

### 1. Automated Hooks System
- **Security Checks**: Pre-execution validation of dangerous commands
- **Auto-formatting**: Automatic code formatting for multiple languages
- **Activity Logging**: Comprehensive development activity tracking
- **Session Management**: Automatic session summaries and cleanup

### 2. Test-Driven Development (TDD)
- Integrated TDD workflow with strict phase tracking
- Automated test generation and execution
- Quality gates and compliance checking
- Refactoring scheduler and design drift detection

### 3. Documentation Sync
- Bilingual documentation (English/Japanese) synchronization
- Automatic README updates
- Architecture Decision Records (ADR) management
- Design change tracking

### 4. Memory Bank System
- Hierarchical project knowledge organization
- Automatic note rotation to prevent information overload
- Context preservation across agent switches
- Searchable project history

## 📋 Configuration Files

### Primary Configuration
- **`settings.json`**: Main Claude Code configuration including hooks
- **`hooks.yaml`**: Alternative hooks configuration format
- **`*-config.json`**: Feature-specific configurations (security, quality, refactoring)

### Agent Configuration
- **`agents/`**: Individual agent definitions and capabilities
- **`active.json`**: Current active agent tracking
- **`commands/`**: Available commands and their implementations

## 🛠️ Automation Scripts

The `scripts/` directory contains powerful automation tools:

| Script | Purpose | Trigger |
|--------|---------|---------|
| `ai-logger.sh` | AI-optimized activity logging | After any tool use |
| `auto-format.sh` | Code formatting | After file edits |
| `deny-check.sh` | Security validation | Before Bash execution |
| `session-complete.sh` | Session summaries | At session end |
| `notes-check-hook.sh` | Notes rotation | On agent switches |

## 🧪 Testing & Quality

### Test Framework
- **Unit Tests**: Individual component testing
- **Integration Tests**: Multi-component testing
- **E2E Tests**: Full workflow testing
- **Performance Tests**: System performance monitoring

### Quality Gates
- Automated code quality checks
- Security vulnerability scanning
- Design compliance validation
- Test coverage requirements

## 📖 Documentation

### Core Documentation
- **ARCHITECTURE.md**: System design and component relationships
- **BEST_PRACTICES.md**: Development guidelines and conventions
- **MIGRATION_GUIDE.md**: Upgrade and migration instructions

### Feature Documentation
- **hooks-README.md**: Hooks system detailed guide
- **security-README.md**: Security features and configuration
- **ai-logger-README.md**: AI logging system guide

## 🎯 Usage Patterns

### Typical Development Workflow
1. **Start with Planner**: `/agent:planner` for strategic planning
2. **Switch to Builder**: `/agent:builder` for implementation
3. **Use TDD Cycle**: Red → Green → Refactor with automatic tracking
4. **Quality Checks**: Automated hooks ensure code quality
5. **Documentation**: Bilingual docs updated automatically

### Memory Management
- Notes automatically rotate when they exceed 450 lines
- Project context preserved in `/memo/` hierarchy
- Session history maintained for retrospective analysis

## 🔧 Customization

### Adding New Features
1. Create feature-specific config in appropriate `*-config.json`
2. Add automation scripts to `scripts/` directory
3. Update hooks in `settings.json` if needed
4. Add documentation to appropriate README files

### Extending Agents
1. Create new agent definition in `agents/`
2. Add command definitions in `commands/`
3. Implement workspace setup if needed
4. Update coordination templates in `shared/agent-coordination/`

## 🚨 Troubleshooting

### Common Issues
- **Hooks not working**: Check script permissions with `chmod +x .claude/scripts/*.sh`
- **Agent switch failing**: Verify `agents/active.json` configuration
- **Formatting issues**: Ensure formatters (prettier, ruff, etc.) are installed
- **Permission errors**: Check file permissions and PATH environment

### Debug Commands
```bash
# Test all hooks
.claude/scripts/test-hooks.sh

# Check security features
.claude/scripts/test-security.sh

# Monitor activity logs
tail -f ~/.claude/activity.log

# Analyze AI logs
.claude/scripts/analyze-ai-logs.py --format summary
```

## 🤝 Contributing

### Development Guidelines
1. Follow TDD practices with proper phase tracking
2. Maintain bilingual documentation (English/Japanese)
3. Use structured handovers when switching agents
4. Test hooks and automation thoroughly
5. Update relevant README files for new features

### Code Standards
- Use AI-friendly comments and structure
- Follow established naming conventions
- Maintain backward compatibility
- Document design decisions in ADRs

## 🔗 Related Resources

- **Main Project README**: `../README.md`
- **Architecture Documentation**: `ARCHITECTURE.md`
- **Best Practices Guide**: `BEST_PRACTICES.md`
- **Hooks System Guide**: `hooks-README.md`
- **Agent System Guide**: `agents/README.md`

---

**Note**: This system is designed to evolve with your development needs. Feel free to customize configurations and add new features while maintaining the core multi-agent coordination principles.