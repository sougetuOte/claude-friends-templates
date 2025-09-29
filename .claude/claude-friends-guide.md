# Claude Friends User Guide

🌐 **English** | **[日本語](claude-friends-guide_ja.md)**

## 🎯 What is Claude Friends?
**Sequential Multi-Agent System** - Experience team development even when working solo with AI.

### Two AI Agents
- **Planner**: Determines project direction, user communication, creates design docs, organizes tasks
  - Speaks in calm female tone ("...ですね", "...でしょう", "...かしら")
- **Builder**: Writes code and tests based on the plan, handles technical questions
  - Speaks in casual male tone ("...だぜ", "...だな", "よし、やってみるか")

## 🚀 Basic Usage

### 1. First Launch
```bash
# Start in Planner mode (planning & design)
/agent:planner

# Switch to Builder once plan is ready (implementation)
/agent:builder
```

### Key Principle
- **All planning → Planner** (no `/project:plan` needed)
- **All implementation → Builder** (no `/project:act` needed)
- **Simple and clear role division**

### 2. Daily Development Flow
```
Morning: Plan today's work with Planner
  ↓
Morning: Implement with Builder
  ↓
Afternoon: Re-plan with Planner if stuck
  ↓
Evening: Finish up with Builder
  ↓
End: Create handover for next day
```

### 3. When to Switch Agents

#### When to Use Planner
- Starting a new project or feature
- Confirming requirements with users
- Creating design documents (with Mermaid diagrams)
- Determining project direction
- Organizing task priorities
- Re-planning when stuck

#### When to Use Builder
- Writing actual code
- Fixing bugs
- Creating tests
- Refactoring
- Handling technical implementation details
- Debugging technical issues

## 📝 Handover Tips

### Good Handover Example
```markdown
# Handover - 2025-01-11 15:30

## From: Planner
## To: Builder

## Completed Work
- Authentication design complete
- API endpoints defined
- Database schema decided

## For Next Agent

### Tasks:
1. Implement /api/auth/login endpoint
2. JWT token generation
3. Create user table

### Notes:
- Hash passwords with bcrypt
- Token expiry: 24 hours
- Use unified error response format
```

### When to Create Handovers
- Before switching agents (required)
- When interrupting work
- After important decisions
- End of day

## 🎭 Working with Agent Personalities

### Talking to Planner
- "What's the big picture?"
- "What are the priorities?"
- "Is this approach good?"
- "I want to add a new feature" → Automatically switches to feature design mode

### Talking to Builder
- "Fix this error" → Automatically switches to debug mode
- "Write tests for this"
- "Review this code" → Automatically switches to code review mode
- "Improve performance"

### Special Modes
Agents have special modes for specific tasks:
- **Planner's Feature Design Mode**: Activated when planning new features
- **Builder's Debug Mode**: Activated when investigating errors
- **Builder's Code Review Mode**: Activated when checking code quality

## 📁 Understanding File Structure

```
.claude/
├── agents/
│   └── active.md          # Current agent
├── planner/
│   ├── identity.md        # Planner role definition
│   ├── notes.md          # Planner work notes
│   └── handover.md       # Handover document
├── builder/
│   ├── identity.md        # Builder role definition
│   ├── notes.md          # Builder work notes
│   └── handover.md       # Handover document
└── shared/
    ├── constraints.md     # Project constraints
    └── phase-todo.md     # Phase/ToDo management
```

## 💡 Tips & Tricks

### 1. Leverage Phase Management
- Split large projects into 5-7 phases
- Each phase should complete in 1-2 weeks
- Review at phase completion

### 2. Handling Interruptions
```bash
# For urgent interruptions
# Create handover-interrupt-2025-01-11-1530.md
```

### 3. Using Archives
- Move handovers older than 1 week to archive folder
- Useful for referencing past decisions

### 4. Combining with Other Commands
- `/project:focus` to focus on current task (works with any agent)
- `/project:daily` for daily retrospective (works with any agent)
- `/debug:start` for debug mode
- Specialized modes work alongside the agent system

## ⚠️ Important Notes

### Don't Do This
- Switch agents without handover
- Go into implementation details as Planner
- Make major design changes as Builder

### Troubleshooting
- **Switching doesn't work**: Manually edit active.md
- **Unclear handover**: Re-read previous handover
- **Role confusion**: Check identity.md for role clarity

## 🎉 Tips for Success
- Treat agents as "colleagues"
- Give clear instructions and expectations
- Use feedback to improve
- Build small successes

---

Experience "team development" efficiency even when working alone with Claude Friends!
