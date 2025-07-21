# 🚀 Claude Friends Templates

🌐 **[日本語版](README_ja.md)** | **English**

> **Transform your solo development into a powerful AI-powered team experience**

## 💡 What if you had AI teammates who never sleep?

Imagine having a **Project Planner** who organizes your ideas and a **Code Builder** who implements them flawlessly. That's **Claude Friends** - your AI development team in a box.

### ✨ See the Magic in Action

```bash
# Morning: Your AI Planner organizes the day
$ /agent:planner
"Let's tackle the authentication system today. I've broken it down into 3 phases..."

# Planning a new feature? Planner automatically switches to design mode
"I want to add user notifications"
"Switching to Feature Design Mode. Let me create a detailed spec with diagrams..."

# Seamless handoff to your AI Builder  
$ /agent:builder
"Got it! Starting with the login API. I'll follow the plan and implement JWT..."

# Hit an error? Builder automatically switches to debug mode
"TypeError: Cannot read property 'id' of undefined"
"Entering Debug Mode. Let me analyze this error and trace its root cause..."

# Your code gets written, tested, debugged, and reviewed automatically
```

## 🎯 Why Developers Love Claude Friends

### 📉 **90% Cost Reduction**
Our revolutionary prompt caching means you can use AI all day without breaking the bank.

### 🧠 **AI That Remembers Everything**
No more "what was I working on?" - Your AI team maintains perfect project memory.

### 🔍 **Instant Problem Analysis**
AI-Friendly Logger V2 (powered by [Vibe Logger](https://github.com/fladdict/vibe-logger) concepts) turns cryptic errors into clear solutions in seconds.

### 🎭 **Smart Agents with Special Modes**
- **Planner**: Strategic thinking + automatic Feature Design Mode with Mermaid diagrams
  - Design synchronization and drift detection
  - ADR (Architecture Decision Record) management
- **Builder**: Coding expert + automatic Debug Mode and Code Review Mode + strict TDD enforcement
  - Red-Green-Refactor cycle with visual status tracking
  - Error pattern learning and recognition
  - Automated test generation and quality gates
- Just 4 simple commands, but infinite possibilities!

## 🏃‍♂️ Quick Start (5 minutes to your first AI-powered development)

### 1. Get the Template
```bash
# Clone the template
git clone https://github.com/yourusername/claude-friends-templates.git
cd claude-friends-templates

# Copy to your project
cp -r . ../my-awesome-project/ && cd ../my-awesome-project/

# For Japanese users (optional)
# mv README_ja.md README.md        # Use Japanese version as main
# mv CLAUDE_ja.md CLAUDE.md        # Use Japanese version as main

# Remove template's git history
rm -rf .git && git init
```

### 2. Tell AI About Your Project (30 seconds)
Edit the first 2 lines in `CLAUDE.md`:
```markdown
# [Project Name]                 ← Replace with: My Todo App
## Project Overview
[Write a concise description...] ← Replace with: A simple todo list application
```

(Don't worry about the rest of CLAUDE.md - it contains useful settings that help the AI understand your project better)

### 3. Start Planning with AI Planner
```bash
# In Claude Code, start the Planner agent:
/agent:planner

# Planner will greet you:
"Hello! Let's plan your project. What kind of application do you want to create?"

# Just tell what you want:
"I want to make a todo app where users can add, complete, and delete tasks"

# Planner will help you:
"I see, a task management app. Let me help you organize the requirements..."
```

### 4. Let Planner Create Your Requirements
The Planner will:
- Ask clarifying questions
- Create design documents with diagrams
- Fill out requirements.md for you
- Break down work into phases

### 5. Start Building
```bash
# When planning is done, switch to Builder:
/agent:builder

# Builder will start implementing:
"Alright, I've reviewed the requirements. Let's start with the first task!"
```

### That's It! 🎉
Your AI team is now working for you. The Planner organized everything, and the Builder is implementing it with TDD best practices.

### Want Something Different?
- **Need it simpler?** Tell Planner: "Make it as simple as possible"
- **Want more features?** Tell Planner: "I'd like to add user authentication"
- **Different approach?** Tell Planner: "Should we use a different architecture?"
- **Not sure what you need?** Just ask Planner: "What would you recommend?"

The AI agents are here to help - just have a conversation!

### Next Steps
- Keep chatting naturally - agents understand context
- Use `/project:focus` when you get distracted  
- Use `/project:daily` for quick retrospectives
- Read the [full guide](.claude/claude-friends-guide.md) when ready

> 💡 **Language versions**: This template includes both English and Japanese versions of documentation files (*_ja suffix for Japanese). Choose the version that suits your needs.

## 🎪 Choose Your Starting Template

### 🌟 **Claude Friends Multi-Agent System** *(Now Available!)*
Perfect for complex projects that need both planning and execution.
- **Smart AI Agents with Special Modes**:
  - Planner: Planning + Feature Design (with Mermaid diagrams)
  - Builder: Coding + Debug Mode + Code Review
- **Just 4 Commands**: `/agent:planner`, `/agent:builder`, `/project:focus`, `/project:daily`
- **Automatic Mode Switching**: Agents adapt to your current needs
- **Intelligent Handoffs**: Smooth transitions with mode recommendations

**[→ Learn More](README_TEMPLATE.md#claude-friends)** | **[→ User Guide](.claude/claude-friends-guide.md)**

### 📦 **Classic Memory Bank Template** *(Available Now)*
The foundation for AI-powered development.
- Hierarchical knowledge management
- 90% cost savings with cache optimization (based on Anthropic's prompt caching)
- Ready for immediate use

**[→ Full Documentation](README_TEMPLATE.md)**

## 🎯 Built for Real Development Challenges

### What This Template Helps You Do:
- **Plan Better**: AI Planner creates detailed specs with Mermaid diagrams automatically
- **Code Faster**: AI Builder handles implementation with mandatory TDD (test-first approach)
- **Debug Instantly**: Builder's Debug Mode analyzes errors and finds root causes automatically
- **Review Automatically**: Builder's Code Review Mode ensures quality without manual effort
- **Remember Everything**: Memory Bank and handoff system maintain perfect project context

## 🚀 Enhanced Features (NEW!)

### 🔴🟢✅ Test-Driven Development (TDD) Integration
- **Strict TDD Workflow**: Red-Green-Refactor cycle with task status tracking
- **Visual Status Indicators**: 
  - 🔴 Not Implemented (Red phase)
  - 🟢 Minimally Implemented (Green phase)  
  - ✅ Refactored (Refactor phase)
  - ⚠️ Blocked (After 3 failed attempts)
- **TDD Commands**: `/tdd:start` to begin cycle, `/tdd:status` to check progress
- **Automated Test Generation**: Templates and mock support for faster testing

### 🎯 Enhanced Design Synchronization
- **Design-First Development**: All implementations align with design specs
- **Bidirectional Sync**: Design ↔ Implementation feedback loop
- **Design Drift Detection**: Automatic checks for design-code divergence
- **ADR System**: Architecture Decision Records for tracking design choices

### 🔍 AI-Powered Error Pattern Library
- **Smart Error Recognition**: Learns from past debugging sessions
- **Pattern Matching**: Instantly identifies similar errors from history
- **Root Cause Analysis**: AI suggests likely causes and solutions
- **Searchable Debug History**: Quick access to past solutions

### 🧪 Integrated Test Framework
- **Test Templates**: Pre-built templates for common test scenarios
- **Mock Generation**: Automatic mock creation for dependencies
- **Coverage Tracking**: Real-time test coverage monitoring
- **Quality Gates**: Enforces 80%+ coverage, complexity limits

### ⚡ Optimized Agent Coordination
- **Smart Handoffs**: Context compression for efficient agent switching
- **Parallel Task Analysis**: Identifies tasks that can run concurrently
- **Shared Memory Bank**: Synchronized knowledge between agents
- **Performance Monitoring**: Track agent efficiency and bottlenecks

## 🛠 What's Inside

```
Your AI-Powered Workspace:
├── 🧠 Memory Bank/          # Your project's perfect memory
├── 🤖 AI Agents/           # Your tireless teammates
├── 🛡️ Security/            # Automatic safety checks
├── 📊 AI Logger/           # Debugging on steroids
└── 🎯 Custom Commands/      # Your productivity shortcuts
```

## 📚 Documentation That Actually Helps

- **[Quick Start Guide](README_TEMPLATE.md)** - Get started with clear, step-by-step instructions
- **[Claude Friends User Guide](.claude/claude-friends-guide.md)** - Master the AI agent system
- **[Migration Guide](MIGRATION_GUIDE.md)** - Upgrade existing projects smoothly
- **[Best Practices](BEST_PRACTICES.md)** - Learn proven development patterns
- **[Architecture Overview](ARCHITECTURE.md)** - Understand the system design
- **[TDD Guide](.claude/builder/tdd-cycle.md)** - Master Test-Driven Development
- **[Design Sync Guide](.claude/shared/design-sync.md)** - Keep design and code aligned

## 🤝 Join the Community

A growing community of developers exploring the future of AI-powered development.

### Get Involved
- 🌟 Star us on GitHub to stay updated
- 🐛 Report issues and share feedback
- 🔧 Contribute improvements and ideas
- 💬 Share your experience

## 🚀 Try It Out!

Want to see Claude Friends in action? Check out our **[Sample Projects](SAMPLE_PROJECTS.md)** for hands-on examples:
- 📝 Markdown-driven task manager
- 🌱 Digital pet ecosystem
- 🎮 Roguelike game
- ...and more!

## 🚦 Ready to Start?

### 🛡️ Safe Environment (Recommended)
Open in VS Code or GitHub Codespaces and select "Reopen in Container" for a secure sandbox environment where you can experiment safely.

### Standard Setup
Don't just code. **Orchestrate**.

**[→ Get Your AI Team Now](README_TEMPLATE.md)**

---

<p align="center">
  <strong>Claude Friends</strong> - Because the best developers work smarter, not harder.
</p>

<p align="center">
  <sub>Built with ❤️ for developers who dare to dream bigger</sub>
</p>