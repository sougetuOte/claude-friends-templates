# Claude Friends Project Template v2.0.0

🌐 **[日本語版](README_TEMPLATE_ja.md)** | **English**

**AI-Powered Multi-Agent Development System - Your AI Team in a Box**

## 🚀 Why This Template is Revolutionary

### 1. **90% Cost Reduction** - Prompt Cache Optimization
By applying `cache_control` to long-term stable information (project overview, technical specifications, etc.), this system significantly reduces Claude API usage costs. It helps address the cost problem in daily AI-powered development.

### 2. **AI Analyzes Problems Instantly** - AI-Friendly Logger (Vibe Logger Concept)
Transforms logging from "logs for humans to read" to "logs for AI to analyze". Structured JSON logs automatically collect context information, evolving debugging from "guessing and checking" to "instant root cause analysis by AI".

### 3. **Systematized Project Memory** - Memory Bank System
Hierarchically structures and stores your project's "memory". Significantly reduces onboarding time for new members and eliminates "what was that again?" moments. AI provides accurate answers quickly.

### 4. **Gradual Integration for Existing Projects**
No need to "change everything right now". The design allows gradual adoption of necessary features while minimizing risk.

---

An efficient project development template optimized for AI-native development.

## 🎯 Features

- **Lightweight Design**: Minimizes context usage
- **Hierarchical Memory Bank**: Loads only necessary information
- **Gradual Expansion**: Scales from small to large projects
- **Daily Operations**: Complete status updates in 3 minutes
- **Versatility**: Language and tech-stack agnostic design
- **Integrated Development Standards**: Incorporates Anthropic best practices
- **Quality Management**: Built-in error handling guide and quality gates
- **Enhanced Security**: Dangerous command blocking via Claude Code hooks
- **Project Memory**: Systematic management of history and decisions
- **Automated Workflow**: Quality checks automation with Hooks functionality
- **AI-Friendly Logger**: Vibe Logger concept adoption with structured JSON format optimized for AI analysis

## 📁 Template Structure

### Required Files
```
CLAUDE.md                    # Project configuration
.clauderules                 # Project insights
.gitignore                   # Cache file exclusion settings
.claude/settings.json        # Cache environment + security settings
.claude/hooks.yaml           # Hooks settings (new)
.claude/security-README.md   # Security settings documentation
.claude/ai-logger-README.md  # AI Logger settings documentation
docs/requirements.md         # Requirements specification
docs/adr/template.md         # ADR template
```

### Memory Bank (Hierarchical)
```
.claude/
├── core/                    # Always referenced (lightweight)
│   ├── current.md          # Current status (within 50 lines)
│   ├── next.md             # Next actions (within 30 lines)
│   ├── overview.md         # Project overview
│   └── templates.md        # Quick templates & pattern collection
├── context/                # Referenced as needed
│   ├── tech.md             # Technical details
│   ├── history.md          # History & decisions
│   └── debt.md             # Technical debt tracking
├── debug/                  # Debug information
│   └── latest.md           # Latest debug session (within 100 lines)
├── archive/                # Regular cleanup
├── commands/               # Core commands
│   ├── agent-planner.md    # Planner agent (includes feature design)
│   ├── agent-builder.md    # Builder agent (includes debug & review)
│   ├── daily.md            # Daily update
│   └── focus.md            # Focus mode
├── scripts/                # Security & logging scripts
│   ├── deny-check.sh       # Dangerous command blocking
│   ├── allow-check.sh      # Safe command allow
│   ├── test-security.sh    # Security tests
│   ├── ai-logger.sh        # AI-Friendly Logger
│   └── analyze-ai-logs.py  # AI log analysis tool
├── security-README.md      # Security settings documentation
└── settings.json           # Project settings (cache+security)
```

## 📋 Prerequisites

- **Claude Code v1.0+** installed and configured
- **Git** for version control
- **Python 3.7+** (optional, for advanced features):
  - Refactoring analyzer (`refactoring-analyzer.py`)
  - Design drift detector (`design-drift-detector.py`)
  - Quality checks (`quality-check.py`)
  - AI log analyzer (`analyze-ai-logs.py`)

## 🚀 Usage

### 1. Starting a Project
```bash
# Copy the template
cp -r claude_file_template/ your-project/
cd your-project/

# Customize project information
# - Replace [Project Name] in CLAUDE.md
# - Fill in docs/requirements.md
# - Update files in .claude/core/
```

### 2. Daily Development Flow

#### With Claude Friends (Recommended)
```
Morning: /agent:planner    # Plan today's work and design features
         ↓
         "I want to add user authentication"
         → Planner automatically creates detailed specs with diagrams
         ↓
Work:    /agent:builder    # Start implementation based on plan
         ↓
         Error occurs? → Builder automatically enters Debug Mode
         Implementation done? → Builder can switch to Review Mode
         ↓
Focus:   /project:focus    # When you need to concentrate
         ↓
Evening: /project:daily    # Daily retrospective (3 min)
```

#### Tag Search (As needed)
```
Tag search: #urgent #bug #feature #completed  # Fast search for related info
```

## 💡 Efficiency Points

### Context Minimization
- **Normal**: Reference only `@.claude/core/*`
- **When details needed**: Explicitly specify `@.claude/context/*`
- **Past reference**: Check history with `@.claude/archive/*`

### Memory Bank Operations
- **core/**: Maintain within 50 lines
- **context/**: Update only when necessary
- **archive/**: Organize monthly

### Time Management
- Planning: Within 5 minutes
- Daily updates: Within 3 minutes
- Memory Bank updates: Only when necessary

## 🤖 Claude Friends Multi-Agent System

Transform your solo development into a team experience with AI agents:

### Core Commands (Just 4!)
| Command | Purpose | Details |
|---------|---------|---------|
| `/agent:planner` | Strategic planning + Design | Creates specs with Mermaid diagrams |
| `/agent:builder` | Implementation + Debug + Review | Handles all coding tasks |
| `/project:focus` | Focus on current task | Works with any agent |
| `/project:daily` | Daily retrospective | Works with any agent |

### Smart Agent Features
- **Planner Special Mode**: Automatically switches to Feature Design Mode when planning new features
- **Builder Special Modes**: 
  - Debug Mode: Activates when errors occur
  - Code Review Mode: Ensures quality after implementation
  - TDD Enforcement: Red→Green→Refactor cycle mandatory
- **Smooth Handoffs**: Agents recommend the best mode for the next agent

**[→ Full Claude Friends Guide](.claude/claude-friends-guide.md)**

## 🛠 Command System Overview

The Claude Friends system simplifies development with just 4 core commands. All previous specialized modes are now integrated into the agent system:

### Quick Reference
- **Planning/Design** → `/agent:planner` (includes feature design mode)
- **Coding/Debug/Review** → `/agent:builder` (includes debug & review modes)
- **Focus Work** → `/project:focus`
- **Daily Review** → `/project:daily`

### Tag Search
- Tag format: Search within Memory Bank with `#tag_name`
- Major tags: #urgent #bug #feature #completed

## 📋 Built-in Features

### Core Development Rules
- Unified package management policy
- Code quality standards & mandatory TDD requirements
- Git/PR conventions (commit format, trailers, review rules)

### Command List
- Language-agnostic development flow (`[tool]` notation)
- Unified commands for setup, test, quality check, and build
- Support for major languages (Node.js/Python/Rust/Go)

### Error Handling Guide
- Standard problem-solving order (format → type → lint → test)
- Common problems and solutions by domain
- Best practices for development, error handling, and information gathering

### Quality Gates
- Stage-specific checklists (pre-commit, pre-PR, pre-deploy)
- Automation level classification (fully automated, semi-automated, manual check)
- Continuous quality management guidelines

### Security Features
- **Deny List**: Auto-block dangerous commands (`rm -rf /`, `chmod 777`, `curl | sh`, etc.)
- **Allow List**: Pre-allow safe commands needed for development (`git`, `npm`, `python`, etc.)
- **Security Log**: Command execution audit and recording
- **Test Suite**: Automated security settings verification
- **Documentation**: Complete setup guide and emergency response guide

### AI-Friendly Logger (v1.2.0 New Feature - Vibe Logger Concept)
- **Structured Logs**: JSON format optimized for AI analysis (`~/.claude/ai-activity.jsonl`)
- **Rich Context**: Automatically collects project, environment, and Git information
- **AI Metadata**: Automatically adds debug hints, priority, and recommended actions
- **Pattern Analysis**: Visualizes error detection, frequent operations, and file activity
- **Analysis Tool**: Generate AI insights with `analyze-ai-logs.py`
- **Reference**: Adopts [Vibe Logger](https://github.com/fladdict/vibe-logger) concept

## 🎯 Target Projects

### Optimal
- Personal development projects
- 1-3 month medium-term projects
- Web development, app development
- Prototype development

### Requires Adjustment
- Large team development
- Long-term projects (1+ years)
- Projects with advanced regulatory requirements

## 📈 Expected Benefits

### Token Usage
- **Significant Reduction**: Efficiency through hierarchical Memory Bank
- **Maintained Constant**: Lightweight regardless of project scale

### Development Efficiency
- **Fast Planning**: Gradual information loading
- **Focused Work**: Uninterrupted with focus mode
- **Continuous Operation**: Habit formation with lightweight updates

### Scalability
- **Gradual Growth**: Natural expansion from small to large scale
- **Knowledge Accumulation**: Continuous learning with `.clauderules`
- **Reusability**: Leverage templates and patterns

## ⚠️ Precautions

- Keep Memory Bank files concise (recommend within 50 lines each)
- Maintain performance with regular archiving
- Ensure replacement with project-specific content
- Always record important decisions

## 📋 Actual Operation Examples

### 🚀 First Day Flow

#### With Claude Friends System
```
09:00 Copy template & customize
09:15 /agent:planner - Plan project structure and first features
      → Planner creates project overview with Mermaid architecture diagrams
09:30 /agent:builder - Start implementing based on Planner's design
      → Builder follows the plan, writes code, and tests
12:00 Progress check & adjust priorities with Planner
16:00 /agent:builder - Review code quality (Review Mode)
17:00 /project:daily - First day retrospective
```

### 📅 Daily Operations (Day 2 onwards)

#### Claude Friends Workflow
```
09:00 /agent:planner    # Review progress and plan today's work
      → "Add user notifications feature"
      → Planner creates detailed spec with sequence diagrams
      
10:00 /agent:builder    # Start implementing new feature
      → Builder works on notification system
      → Error? Automatically switches to Debug Mode
      
14:00 /project:focus    # Deep focus on complex logic
      
16:00 /agent:builder    # Code review before wrapping up
      → "Review the notification implementation"
      → Builder analyzes code quality and suggests improvements
      
17:00 /project:daily    # Reflect and plan for tomorrow
```

### 👥 Human-AI Role Division

#### Human Responsibilities  
- **Strategic Decisions**: Work with Planner agent for high-level planning
- **Requirements Definition**: Explain needs to Planner for detailed specs
- **Quality Management**: Request Builder's Code Review Mode
- **Direction Control**: Guide agents through handoffs
- **Retrospective**: Progress management with `/project:daily`

#### AI Responsibilities
- **Implementation Work**: Code creation, modification, testing
- **Technical Research**: Library selection, implementation method investigation
- **Documentation**: Technical documents, comment creation
- **Problem Solving**: Bug fixes, performance improvements

### ⚡ Human Time Utilization During AI Work
```
Parallel work during AI implementation (30-90 min):
- Planning next phase
- UI/UX design consideration
- External API/service research
- Documentation maintenance
- Work on other projects
```

### 📊 Command Usage Frequency

| Frequency | Command | Timing |
|-----------|---------|--------|
| Daily | `/agent:planner` | Morning planning & design |
| Daily | `/agent:builder` | Implementation & debugging |
| Daily | `/project:daily` | Evening retrospective |
| As needed | `/project:focus` | Deep concentration |
| Automatic | Planner Feature Mode | When designing new features |
| Automatic | Builder Debug Mode | When errors occur |
| Automatic | Builder Review Mode | For code quality checks |
| Anytime | `#tag search` | Related info search |

## 🎉 Let's Start

1. Copy the template
2. Customize CLAUDE.md
3. Test security settings: Run `.claude/scripts/test-security.sh`
4. Start with `/agent:planner` to design your project
5. Switch to `/agent:builder` to start coding
6. Enjoy AI-powered team development!

Let's achieve efficient personal development with Claude Code using this template!

## 📚 Enhancement Details & Source Information

### v1.1.0 Enhanced Features
- **Prompt Cache Optimization**: Significant cost reduction, reduced latency
- **Gradual TDD Learning Path**: Learning system for beginners
- **ADR System**: Technical decision recording and management
- **Technical Debt Tracking**: Systematic debt management system
- **Security Features**: Dangerous command blocking via Claude Code hooks

### Sources & References

#### Claude Code Optimization Techniques
- **Anthropic Official**: [Prompt caching - Anthropic API](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- **Anthropic Official**: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- **AWS Official**: [Supercharge your development with Claude Code and Amazon Bedrock prompt caching](https://aws.amazon.com/blogs/machine-learning/supercharge-your-development-with-claude-code-and-amazon-bedrock-prompt-caching/)
- **Medium**: [Unlocking Efficiency: A Practical Guide to Claude Prompt Caching](https://medium.com/@mcraddock/unlocking-efficiency-a-practical-guide-to-claude-prompt-caching-3185805c0eef)

#### TDD & Test-Driven Development
- **Anthropic Official**: [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices)
- **Reddit**: [Claude Dev can now automatically fix linter, compiler, and build errors](https://www.reddit.com/r/ClaudeAI/comments/1fgzo87/claude_dev_can_now_automatically_fix_linter/)
- **Reddit**: [Generating unit tests with Claude](https://www.reddit.com/r/ClaudeAI/comments/1i17nwn/generating_unit_tests_with_claude/)

#### ADR (Architecture Decision Record)
- **GitHub**: [Architecture decision record (ADR) examples](https://github.com/joelparkerhenderson/architecture-decision-record)
- **MakerX Blog**: [Architecture Decision Records: How we make better technical choices](https://blog.makerx.com.au/architecture-decision-records-how-we-make-better-technical-choices-at-makerx/)
- **Medium**: [Why Every Software Team Should Embrace Architecture Decision Records](https://levelup.gitconnected.com/why-every-software-team-should-embrace-architecture-decision-records-18cd201cc179)

#### Memory Bank & Context Management
- **Anthropic Official**: [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)
- **Cloud Artisan**: [Claude Code Tips & Tricks: Maximising Memory](https://cloudartisan.com/posts/2025-04-16-claude-code-tips-memory/)
- **DEV Community**: [Introducing Claude Crew: Enhancing Claude Desktop's Coding Agent Capabilities](https://dev.to/kimuson/introducing-claude-crew-enhancing-claude-desktops-coding-agent-capabilities-36ah)

#### AI-Friendly Logging
- **Vibe Logger**: [GitHub - fladdict/vibe-logger](https://github.com/fladdict/vibe-logger)
- **Vibe Logger Article**: [note - Proposal for AI Agent Logging System "Vibe Logger"](https://note.com/fladdict/n/n5046f72bdadd)

#### Cache Technology Details
- **Anthropic Official**: [Long context prompting tips](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/long-context-tips)
- **LinkedIn**: [How to Use Anthropic Claude Prompt Caching (and RAG)](https://www.linkedin.com/posts/anantharamuavinash_how-to-use-claude-prompt-caching-and-ditch-activity-7230786805590061056-xupU)
- **Reddit**: [Claude Caching Is Fantastic For Iterating Over Code!](https://www.reddit.com/r/ClaudeAI/comments/1ewms42/claude_caching_is_fantastic_for_iterating_over/)

### Implementation Details

#### 1. CLAUDE_CACHE Configuration
```json
// .claude/settings.json
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  }
}
```

#### 2. cache_control Optimization
cache_control applied to the following files:
- `.claude/core/overview.md` - Project overview
- `.claude/core/templates.md` - Quick templates
- `.claude/context/tech.md` - Technology stack
- `.claude/context/debt.md` - Technical debt tracking
- `docs/requirements.md` - Requirements specification

#### 3. TDD Gradual Learning Path
- **Phase 1 (Week 1-2)**: Master Claude Code without TDD experience
- **Phase 2 (Week 3-4)**: TDD experience with small features
- **Phase 3 (Month 2-3)**: Full TDD application

#### 4. ADR System
- **Template**: `docs/adr/template.md`
- **Decision Records**: Technical choices, architecture, security policies, etc.
- **Integration**: GitHub Issues, debt log, history management

#### 5. Technical Debt Tracking
- **Priority Management**: High🔥/Medium⚠️/Low📝
- **Cost Estimation**: Estimate and record actual time
- **Cache Impact Analysis**: Deletion cost and optimization effect measurement

### Performance Effects
- **Cost Reduction**: Significant reduction through prompt caching
- **Latency Reduction**: Improved API response time
- **TDD Learning**: Beginners can master in 2-3 months
- **Knowledge Management**: Systematic management with ADR and debt logs
- **Enhanced Security**: Improved safety while maintaining development efficiency

### Notes
- `.ccache/` folder is already added to `.gitignore`
- Apply cache_control only to long-term stable information
- Gradual TDD introduction for gentle learning curve
- Record only important technical decisions in ADR to avoid excessive documentation
- **Security Settings**: Use in production after testing
- **Log Monitoring**: Regularly check `~/.claude/security.log` for unauthorized access

### v1.2.0 New Features (AI-Friendly Logger & Automation)

#### Hooks Automation System
- **Automated Quality Checks**: Auto lint and type check on code changes
- **Test Success Recording**: Automatically record successful tests to PROJECT_MEMORY
- **Evolution Auto-tracking**: Auto-log new features and commits

#### Project Health Check
- **Metrics Collection**: Code size, technical debt, dependency health
- **Overall Score Calculation**: Evaluate project health with A-F grades
- **Improvement Suggestions**: Automatically generate specific action plans

#### AI-Friendly Logger (Vibe Logger Concept)
- **Structured Log Format**: JSONL files optimized for AI analysis
- **Automatic Context Collection**: Auto-record project, environment, and Git state
- **AI Metadata**: Add debug hints, priority, and recommended actions
- **Pattern Analysis Tool**: Visualize error trends, operation frequency, and file activity
- **Coexistence with Existing System**: Gradual migration possible with continued generation of traditional logs
- **Inspiration**: [Vibe Logger](https://github.com/fladdict/vibe-logger) by @fladdict