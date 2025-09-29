# Agent First Command

**Command**: `/agent:first`

## Purpose
Development methodology guide and project entry point. Ensures proper software development flow by enforcing the Requirements → Design → Tasks → Implementation methodology.

## Usage
```
/agent:first
```

## What It Does

### 1. Project Status Diagnosis
- Analyzes current project state
- Checks for requirements.md existence and quality
- Verifies design documents completeness
- Evaluates task preparation status

### 2. Quality Gate Enforcement
- **Requirements Gate**: 200+ words, functional/non-functional requirements
- **Design Gate**: Architecture, API, database design documents
- **Tasks Gate**: 3+ phases, 5+ tasks with proper breakdown

### 3. Guided Navigation
Based on project status, guides to appropriate specialist:
- **Missing Requirements** → Requirements Agent for requirement gathering
- **Incomplete Design** → Planner Agent for technical design
- **Tasks Not Ready** → Planner Agent for task generation
- **Ready for Implementation** → Builder Agent activation approval

### 4. Specialized Commands
Provides access to diagnostic tools:
- `/project:diagnose` - Comprehensive project analysis
- `/project:quality-check` - Stage completion verification
- `/project:next-step` - Specific next action guidance

## Agent Personality
- **Tone**: Polite but strict about quality
- **Motto**: "Take time to do it right. Good design leads to good code"
- **Approach**: No shortcuts allowed - proper methodology enforcement

## Example Flow
```
User: /agent:first

Agent First: "Hello! Let me check your project status...

Current Analysis:
- Requirements: ❌ Not found
- Design: ❌ Not found
- Tasks: ❌ Not found

→ Starting with Requirements phase is essential.
   Please use /agent:requirements to begin proper project setup.

   I'll guide you through: Requirements → Design → Tasks → Implementation"
```

## Integration Notes
- Triggered by UserPromptSubmit hooks when `/agent:` pattern detected
- Integrates with stage-guard.sh for comprehensive checking
- Works with existing Planner/Builder agent handoff system
- Preserves all Memory Bank and existing workflow capabilities

## Quality Philosophy
Prevents the common anti-pattern of jumping directly to implementation without proper planning, design, and task breakdown. Enforces proven software development methodology for better outcomes.
