# Claude Friends Templates Examples

This directory contains example projects built using Claude Friends Templates to demonstrate the multi-agent development workflow.

## Available Examples

### 1. Todo App (`todo-app/`)
A simple but complete todo application showing:
- 3-phase development process (Requirements → Design → Implementation)
- TDD with Red-Green-Refactor cycle
- Visual task status tracking (🔴🟢✅)
- Clean handoffs between Planner and Builder agents

**Key files to explore:**
- `requirements.md` - How requirements are captured
- `design.md` - Technical design with Mermaid diagrams
- `tasks.md` - TDD task breakdown with status tracking
- `tests/taskManager.test.js` - Test-first development example

## How to Use These Examples

1. **Study the Process**
   - Read through each phase to understand the workflow
   - Notice how Planner and Builder agents collaborate

2. **Try It Yourself**
   - Copy an example as a starting point
   - Modify requirements for your needs
   - Follow the same 3-phase process

3. **Learn Best Practices**
   - TDD: Tests always come first
   - Small steps: Each task is 15-30 minutes
   - Clear documentation: Every decision is recorded

## Creating Your Own Example

1. Start with `/agent:planner`
2. Describe what you want to build
3. Follow the agent's guidance through all phases
4. Share your example with the community!

## Future Examples (Coming Soon)
- 🌱 Digital Pet Game - State management and animations
- 📝 Markdown Blog - File processing and static generation
- 🎮 Simple Game - Canvas and game loop patterns

---
*These examples were created entirely using Claude Friends Templates' AI agents.*