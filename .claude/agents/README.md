# Agent System - Multi-Agent AI Development

🌐 **English** | **[日本語](README_ja.md)**

This directory contains the agent definitions and configuration for the claude-friends-templates multi-agent system. Our agents work collaboratively to provide strategic planning, implementation, testing, and quality assurance capabilities.

## 📁 Directory Structure

```
agents/
├── Configuration Files
│   ├── active.json           # Current active agent tracking
│   └── active.md             # Human-readable active agent status
│
├── Core Agents
│   ├── first.md              # Entry point agent (deprecated)
│   ├── sync-specialist.md    # State synchronization specialist
│   ├── test-writer.md        # Test-driven development specialist
│   └── security-auditor.md   # Security analysis specialist
│
└── Agent Workspaces (Located in parent directories)
    ├── ../planner/           # Planner agent workspace
    └── ../builder/           # Builder agent workspace
```

## 🤖 Agent Ecosystem

### Core Agent Roles

#### 🎯 Planner Agent (`../planner/`)
**Specialty**: Strategic thinking and architectural design
**Capabilities**:
- Requirements analysis and clarification
- System architecture design
- Project planning and task breakdown
- Risk assessment and mitigation strategies
- Technology stack recommendations

**Personality**: Thoughtful, methodical, big-picture oriented
**Usage**: Use when you need strategic planning, design decisions, or project structuring

#### 🔨 Builder Agent (`../builder/`)
**Specialty**: Implementation and hands-on development
**Capabilities**:
- Code implementation and debugging
- Test-driven development execution
- Refactoring and optimization
- Integration and deployment
- Troubleshooting technical issues

**Personality**: Practical, detail-oriented, action-focused
**Usage**: Use when you need coding, testing, or technical implementation

#### 🔄 Sync Specialist (`sync-specialist.md`)
**Specialty**: Inter-agent communication and state management
**Capabilities**:
- Handover document generation
- Context preservation between agent switches
- State synchronization validation
- TDD phase tracking and management
- Quality assurance for agent transitions

**Personality**: Meticulous, systematic, coordination-focused
**Usage**: Automatically activated during agent switches

#### ✅ Test Writer (`test-writer.md`)
**Specialty**: Test-driven development and quality assurance
**Capabilities**:
- Test strategy design and implementation
- TDD Red-Green-Refactor cycle management
- Quality gate enforcement
- Test coverage analysis
- Automated testing framework setup

**Personality**: Quality-focused, systematic, thorough
**Usage**: Use when implementing TDD or needing quality assurance

#### 🛡️ Security Auditor (`security-auditor.md`)
**Specialty**: Security analysis and vulnerability assessment
**Capabilities**:
- Security vulnerability scanning
- Code security review
- Compliance checking
- Security best practices implementation
- Threat modeling and risk assessment

**Personality**: Cautious, thorough, security-conscious
**Usage**: Use when security analysis or compliance checking is needed

## 🔄 Agent Coordination

### Agent Switching

Agents are switched using commands:

```bash
# Switch to Planner for strategic work
/agent:planner

# Switch to Builder for implementation
/agent:builder

# Manual sync specialist activation (usually automatic)
/agent:sync-specialist

# Activate test writer for TDD focus
/agent:test-writer

# Activate security auditor for security review
/agent:security-auditor
```

### State Management

#### Current Agent Tracking
- **`active.json`**: Machine-readable current agent state
- **`active.md`**: Human-readable current agent status
- **Automatic updates**: Updated on every agent switch

#### Handover Process
1. **Pre-switch**: Current agent summarizes work and decisions
2. **State capture**: Sync specialist captures current context
3. **Handover generation**: Comprehensive handover document created
4. **Post-switch**: New agent receives complete context
5. **Validation**: Sync specialist validates successful transition

### Context Preservation

#### What Gets Preserved
- **Current TDD phase** (🔴 Red → 🟢 Green → 🔵 Refactor)
- **Recent file changes** and their purposes
- **Design decisions** and reasoning
- **Test status** and coverage
- **Known issues** and blockers
- **Next steps** and priorities

#### Memory Bank Integration
- **Shared knowledge**: All agents access `/memo/` hierarchy
- **Agent-specific notes**: Each agent maintains specialized notes
- **Cross-agent learning**: Insights shared across agent switches

## 📋 Agent Configuration

### Agent Definition Format

Each agent is defined using frontmatter and markdown:

```markdown
---
name: agent-name
description: Brief description of agent capabilities
tools: Read, Write, MultiEdit, Grep, Bash
personality: Personality traits and working style
specialties: [list, of, specialties]
---

# Agent Name

## Role
Detailed description of the agent's role and responsibilities.

## Core Responsibilities
- Responsibility 1
- Responsibility 2

## Working Style
Description of how the agent approaches problems.
```

### Active Agent Configuration (`active.json`)

```json
{
  "current_agent": "none",
  "last_switch": "2025-07-27T10:30:00Z",
  "switch_count": 0,
  "session_start": "2025-07-27T10:00:00Z",
  "handover_status": "complete"
}
```

## 🚀 Usage Patterns

### Typical Development Workflow

#### 1. Project Initiation
```bash
/agent:planner
# Strategic planning, requirements analysis, architecture design
```

#### 2. Implementation Phase
```bash
/agent:builder
# Coding, testing, debugging, technical implementation
```

#### 3. Quality Assurance
```bash
/agent:test-writer
# TDD implementation, test coverage improvement
```

#### 4. Security Review
```bash
/agent:security-auditor
# Security analysis, vulnerability assessment
```

#### 5. Iterative Development
Agents switch back and forth as needed, with automatic state synchronization.

### Specialized Workflows

#### TDD-Focused Development
1. **Planner**: Design test strategy
2. **Test Writer**: Implement test framework
3. **Builder**: Red-Green-Refactor cycle
4. **Sync Specialist**: Track TDD phase transitions

#### Security-First Development
1. **Security Auditor**: Initial threat modeling
2. **Planner**: Security-aware architecture
3. **Builder**: Secure implementation
4. **Security Auditor**: Ongoing security validation

## 🔧 Customization

### Adding New Agents

1. **Create agent definition** in `agents/new-agent.md`:
```markdown
---
name: new-agent
description: Agent description
tools: Required tools
---

# New Agent

## Role
Agent's role and responsibilities
```

2. **Add command definition** in `../commands/`:
```markdown
# /agent:new-agent

Activates the new agent for specialized tasks.
```

3. **Update active agent tracking** in automation scripts

4. **Create workspace** if needed (e.g., `../new-agent/`)

### Extending Existing Agents

#### Adding Capabilities
Modify agent definition files to include new responsibilities and tools.

#### Personality Adjustments
Update personality descriptions to reflect evolving working styles.

#### Tool Integration
Add new tools to agent definitions as capabilities expand.

## 🧪 Testing Agent System

### Agent Switch Testing
```bash
# Test agent switching functionality
.claude/tests/bats/test_agent_switch.bats

# Test handover generation
.claude/tests/bats/test_handover_gen.bats
```

### Integration Testing
```bash
# Test multi-agent workflows
.claude/tests/e2e/test_e2e_phase1.bats

# Test state preservation
.claude/tests/integration/test_agent_coordination.bats
```

### Performance Testing
```bash
# Benchmark agent switching performance
.claude/tests/performance/benchmark-agent-switches.sh
```

## 📊 Monitoring and Analytics

### Agent Usage Metrics
- **Switch frequency**: How often agents are switched
- **Session duration**: Time spent with each agent
- **Handover quality**: Success rate of context preservation
- **TDD compliance**: Adherence to TDD principles

### Quality Metrics
- **Context preservation score**: How well context is maintained
- **Decision traceability**: Tracking of design decisions
- **Test coverage**: Coverage maintained across switches
- **Error rate**: Frequency of agent coordination issues

## 🔍 Debugging

### Common Issues

#### Agent Switch Failures
**Symptoms**: Agent switch commands don't work
**Debugging**:
```bash
# Check active agent status
cat .claude/agents/active.json

# Check recent handovers
ls -la .claude/shared/handover/

# Verify agent definitions
ls -la .claude/agents/
```

#### Context Loss
**Symptoms**: New agent lacks context from previous agent
**Debugging**:
```bash
# Check handover generation logs
tail -f ~/.claude/handover-gen.log

# Verify handover content
cat .claude/shared/handover/handover-latest.md

# Check sync specialist logs
tail -f ~/.claude/sync-specialist.log
```

#### TDD Phase Misalignment
**Symptoms**: TDD phase tracking is inconsistent
**Debugging**:
```bash
# Check TDD phase status
grep "TDD Phase" .claude/shared/handover/handover-*.md

# Verify test status
.claude/scripts/tdd-check.sh
```

### Debug Commands
```bash
# Show current agent status
cat .claude/agents/active.md

# List recent handovers
ls -lt .claude/shared/handover/ | head -10

# Check agent coordination logs
tail -f ~/.claude/agent-coordination.log
```

## 📚 Best Practices

### Agent Usage Guidelines

1. **Right agent for the task**: Choose agents based on the type of work needed
2. **Clear handovers**: Ensure comprehensive context when switching
3. **TDD adherence**: Maintain TDD phase integrity across switches
4. **Regular sync**: Use sync specialist for complex transitions
5. **Quality gates**: Leverage quality-focused agents for reviews

### Development Workflow

1. **Start strategic**: Begin with Planner for big-picture thinking
2. **Implement incrementally**: Use Builder for focused implementation
3. **Test continuously**: Integrate Test Writer for quality assurance
4. **Review regularly**: Use Security Auditor for periodic reviews
5. **Document decisions**: Maintain clear decision trails

### State Management

1. **Preserve context**: Ensure all relevant context is captured
2. **Track decisions**: Document why decisions were made
3. **Maintain continuity**: Keep work flowing smoothly between agents
4. **Validate transitions**: Use sync specialist for complex handovers

## 🔗 Integration Points

### With Hooks System
- **Agent switch hooks**: Automatic handover generation
- **State validation hooks**: Context preservation verification
- **Quality gates**: Automated quality checks during switches

### With Memory Bank
- **Shared knowledge**: All agents access common memory
- **Specialized notes**: Agent-specific knowledge areas
- **Historical context**: Previous agent decisions and rationale

### With Testing Framework
- **TDD tracking**: Phase-aware testing across agents
- **Quality metrics**: Test coverage and quality maintenance
- **Automated validation**: Continuous quality assurance

---

**Note**: The agent system is designed to evolve and adapt to your development needs. Agents can be customized, extended, and new agents can be added as requirements change. The key is maintaining effective coordination and context preservation across all agent interactions.
