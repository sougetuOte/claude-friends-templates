# Todo App Example with Claude Friends

This is a simple example showing how to use Claude Friends Templates to build a Todo application following the 3-phase development process.

## Overview

This example demonstrates:
- 📋 Requirements definition phase
- 🎨 Design phase with Mermaid diagrams
- 🔨 Task generation with TDD
- ✅ Implementation with Red-Green-Refactor cycle

## How This Was Created

### Phase 1: Requirements
```
/agent:planner
"I want to create a simple todo app where users can add, complete, and delete tasks"
```

The Planner helped define:
- User stories
- Success criteria
- Non-functional requirements

### Phase 2: Design
```
/agent:planner
"Let's create the technical design for the todo app"
```

The Planner created:
- Architecture diagram
- Component design
- API specifications
- Data models

### Phase 3: Implementation
```
/agent:planner
"Generate implementation tasks with TDD"
```

Then switched to Builder:
```
/agent:builder
"Let's start implementing the first task"
```

## Files Created

- `requirements.md` - Complete requirements specification
- `design.md` - Technical design with diagrams
- `tasks.md` - TDD task list with status tracking
- `src/` - Implementation files
- `tests/` - Test files (written first!)

## Key Learnings

1. **Test-First Development**: Every feature started with a failing test
2. **Small Steps**: Each task was completable in 15-30 minutes
3. **Clear Handoffs**: Planner → Builder transitions were smooth
4. **Status Tracking**: Visual indicators (🔴🟢✅) helped track progress

## Try It Yourself

1. Copy this example to your project
2. Run `/agent:planner` to start your own requirements
3. Follow the 3-phase process
4. Let the AI agents guide you!

---
*This example was created entirely using Claude Friends Templates' multi-agent system.*