# [Project Name]

## Project Overview
[Write a concise description of the project here]

## Prompt Cache Optimization Settings
- **CLAUDE_CACHE**: `./.ccache` - Significant cost reduction, reduced latency
- **cache_control**: Applied to long-term stable information
- **Settings**: See `.claude/settings.json`

## Claude Friends System (NEW!)
**Sequential Multi-Agent System** - Simulates an AI development team
- **Planner Agent**: Strategic planning, Phase/ToDo management, user interface, design document creation
  - Special mode: New feature design mode
  - Enhanced features: Design synchronization, drift detection, ADR management
  - Speaking style: Calm, professional feminine tone (uses polite, thoughtful expressions)
- **Builder Agent**: Implementation, testing, debugging, technical question handling
  - Special mode: Debug mode, code review mode
  - Enhanced features: Strict TDD practice, error pattern learning, automated test generation
  - Speaking style: Casual, direct masculine tone (uses informal, confident expressions)
- **Smooth Handoff**: Inter-agent handoff system (including mode information)
  - Efficient handoff through context compression
  - Analysis of tasks that can be executed in parallel

### Basic Development Flow (3-Phase Process)

#### 1. **Requirements Definition Phase** → `/agent:planner`
   - Requirements confirmation, requirements.md creation
   - Success criteria definition, risk analysis
   - Upon completion: Guide to "Requirements → Design"

#### 2. **Design Phase** → Continue with `/agent:planner`
   - Architecture design, Mermaid diagram creation
   - Component/interface design
   - Upon completion: Guide to "Design → Tasks"

#### 3. **Task Generation & Implementation Phase**
   - **Task Generation** → `/agent:planner`
     - Generate TDD-applicable tasks
     - Phase division (MVP → Advanced)
     - Set review points
   - **Implementation** → `/agent:builder`
     - Strict adherence to Red-Green-Refactor cycle
     - Phase completion review
     - Immediate feedback on specification issues

#### 4. **Switch as Needed**
   - Specification changes → Switch to Planner
   - Technical challenges → Resolve with Builder
   - Review results → Switch to appropriate agent

### Agent Structure
- Active agent: @.claude/agents/active.md
- Planner workspace: @.claude/planner/
- Builder workspace: @.claude/builder/
- Shared resources: @.claude/shared/
  - Design Sync: @.claude/shared/design-sync.md (NEW!)
  - Design Tracker: @.claude/shared/design-tracker/ (NEW!)
  - Templates: @.claude/shared/templates/ (NEW!)
  - Checklists: @.claude/shared/checklists/ (NEW!)
  - Error Patterns: @.claude/shared/error-patterns/ (NEW!)
  - Test Framework: @.claude/shared/test-framework/ (NEW!)

## Memory Bank Structure
### Core (Always Referenced)
- Current status: @.claude/core/current.md (DEPRECATED - use agent notes)
- Next actions: @.claude/core/next.md
- Project overview: @.claude/core/overview.md
- Quick templates: @.claude/core/templates.md

### Context (Referenced as needed)
- Technical details: @.claude/context/tech.md
- History & decisions: @.claude/context/history.md
- Technical debt: @.claude/context/debt.md

### Agent Workspaces (Claude Friends)
- Planner notes: @.claude/planner/notes.md (auto-rotated at 500 lines)
- Builder notes: @.claude/builder/notes.md (auto-rotated at 500 lines)
- **Auto-rotation on agent switch**: Triggers at 450 lines when using `/agent:` commands
- Notes indexes: @.claude/planner/index.md, @.claude/builder/index.md (auto-generated)
- Notes summaries: Auto-generated during rotation
- Phase/ToDo tracking: @.claude/shared/phase-todo.md
- Project constraints: @.claude/shared/constraints.md
- **Notes Maintenance**: Run `bash .claude/scripts/notes-maintenance.sh` weekly (or automatic via hooks)

### Others
- Debug information: @.claude/debug/latest.md
- Custom commands: @.claude/commands/
- Security scripts: @.claude/scripts/
- Hooks settings: @.claude/hooks.yaml
- Archive: @.claude/archive/

## Custom Commands

### Core Commands (Start Here!)
| Command | Purpose | Details |
|---------|---------|---------|
| `/agent:first` | **🌟 START HERE** - Development guide | Enforces proper methodology, guides to right agent |
| `/agent:planner` | Strategic planning + Design | Creates specs with Mermaid diagrams |
| `/agent:builder` | Implementation + Debug + Review | Handles all coding tasks |
| `/project:focus` | Focus on current task | Works with any agent |
| `/project:daily` | Daily retrospective (3 min) | Works with any agent |

### Enhanced Commands (NEW!)
| Command | Purpose | Details |
|---------|---------|---------|
| `/project:diagnose` | Project status diagnosis | Comprehensive project state analysis |
| `/project:quality-check` | Quality gate check | Verify stage completion requirements |
| `/project:next-step` | Next step guidance | Get specific next actions |
| `/tdd:start` | Start TDD cycle | Begin Red-Green-Refactor cycle |
| `/tdd:status` | Check TDD status | View current task status (🔴🟢✅⚠️) |
| `/adr:create` | Create new ADR | Document architectural decisions |
| `/adr:list` | List all ADRs | View ADRs by status |

### Special Modes (Integrated into Agents)
The following modes are now integrated into the agent system:
- **New Feature Design** → Use Planner's special mode
- **Debug Mode** → Use Builder's special mode
- **Code Review** → Use Builder's special mode

Simply explain your needs to the active agent, and they will switch to the appropriate mode.

### Tag Search
- Tag format: Search within Memory Bank with `#tag_name`
- Major tags: #urgent #bug #feature #completed

## Hooks System

### Security, Quality Enhancement, and Activity Tracking Automation
- **Security**: Auto-block dangerous commands (`rm -rf /`, `chmod 777`, etc.)
- **Auto-formatting**: Code formatting after file edits (Python/JS/TS/Rust/Go/JSON supported)
- **Activity logging**: Automatic recording and metrics collection of development activities
- **AI logging**: Vibe Logger concept adoption with structured JSON format optimized for AI analysis
- **Session management**: Automatic summary and Git status recording at work end

### AI-Friendly Logger V2 (Vibe Logger Compliant)
- **Structured logs**: JSONL format optimized for AI analysis (@~/.claude/ai-activity.jsonl)
- **Rich context**: Automatically collects project, environment, and file information
- **AI metadata**: Adds debug hints, priority, and recommended actions
- **Analysis tool**: Pattern analysis and insight generation with `.claude/scripts/analyze-ai-logs.py`
- **Vibe Logger concept**: Based on @fladdict's VibeCoding philosophy
- **Details**: @.claude/ai-logger-README.md | @.claude/vibe-logger-integration.md

### Error Pattern Library (NEW!)
- **AI-Powered Recognition**: Learning from past debugging sessions
- **Pattern Matching**: Immediate identification of similar errors
- **Root Cause Analysis**: AI-powered suggestions for causes and solutions
- **Searchable History**: Quick access to past solutions
- **Automatic Recording**: Automatic collection of error patterns during debug mode

### Hooks Testing & Verification
```bash
# Test all hooks features
.claude/scripts/test-hooks.sh

# Test security features only
.claude/scripts/test-security.sh

# Check activity logs
tail -f ~/.claude/activity.log
```

Detailed settings: @.claude/hooks-README.md | @.claude/security-README.md

## Development Rules (Key Points)

### Package Management
- **Unification principle**: One tool per project (npm/yarn/pnpm, pip/poetry/uv, etc.)
- **Basic commands**: Use `[tool] add/remove/run` format
- **Prohibited**: Mixed usage, `@latest` syntax, global installation

### Code Quality
- **Type annotations**: Required for all functions and variables
- **Testing**: Strict adherence to TDD (Test-Driven Development)
- **Formatting**: Quality check with `[tool] run format/lint/typecheck`

### TDD Development Methodology (t-wada Style) - Required
- 🔴 **Red**: Write failing test (write test before implementation)
- 🟢 **Green**: Minimal implementation to pass test
- 🔵 **Refactor**: Refactoring (maintain passing test state)

#### Important TDD-Related Documents
- **TDD Strict Application Guide**: @.claude/shared/templates/tasks/tdd-strict-guide.md
- **Test Structure & Organization**: @.claude/shared/templates/test-structure-guide.md (NEW!)
- **TDD Cycle Practice**: @.claude/builder/tdd-cycle.md
- **TDD Configuration System**: @.claude/shared/tdd-settings.md
- **Phase Review Template**: @.claude/shared/templates/tasks/phase-review-template.md
- **Specification Feedback Process**: @.claude/shared/templates/tasks/specification-feedback-process.md

#### Task Status Management (NEW!)
- 🔴 **Not Implemented**: Not yet implemented (TDD Red Phase)
- 🟢 **Minimally Implemented**: Minimal implementation complete (TDD Green Phase)
- ✅ **Refactored**: Refactoring complete
- ⚠️ **Blocked**: Blocked (after 3 failures)

Details: @.claude/shared/task-status.md

#### TDD Practice Principles (Required)
- **Small Steps**: Implement only one feature at a time
- **Fake Implementation**: Hard-coding is OK to pass tests (e.g., `return 42`)
- **Triangulation**: Generalize with 2nd and 3rd test cases
- **Immediate Commit**: Commit immediately after each phase completion

#### TDD Commit Rules (Required)
- 🔴 After writing test: `test: add failing test for [feature]`
- 🟢 After passing test: `feat: implement [feature] to pass test`
- 🔵 After refactoring: `refactor: [description]`

#### TDD Support Tools (NEW!)
- `/tdd:start` - Start TDD cycle command
- `/tdd:status` - Check current TDD status
- **TDD Enforcement Settings**: Adjustable strictness in settings.json (strict/recommended/off)
- **Skip Reason Recording**: Automatic recording of reasons when tests aren't created
- Detailed TDD guide: @.claude/builder/tdd-cycle.md
- Checklists: @.claude/shared/checklists/
- TDD configuration guide: @.claude/shared/tdd-settings.md

Detailed TDD rules: @.claude/shared/constraints.md

### Git Conventions
- **Commit format**: `[prefix]: [change description]` (feat/fix/docs/test etc.)
- **Quality gate**: Must run `[tool] run check` before commit
- **PR**: Self-review → Assign reviewer → Merge

Detailed rules: @docs/development-rules.md

## Development Guidelines
- **General development**: @.claude/guidelines/development.md
- **Git workflow**: @.claude/guidelines/git-workflow.md
- **Testing & quality**: @.claude/guidelines/testing-quality.md

## Command List
```bash
# Basic development flow
[tool] install          # Install dependencies
[tool] run dev         # Start development server
[tool] run test        # Run tests
[tool] run check       # Comprehensive check

# See @.claude/guidelines/development.md for details
```

## ADR & Technical Debt System

### ADR (Architecture Decision Record)
- **Template**: @docs/adr/template.md
- **Operation**: Record when making technical choices or architecture decisions
- **Integration**: Integrated with debt log and history management

### Technical Debt Tracking
- **Debt log**: @.claude/context/debt.md
- **Priority management**: High🔥 / Medium⚠️ / Low📝
- **Operation**: Pre-prediction during new feature development, cleanup at sprint end

## Test Framework Integration (NEW!)

### 📝 Note: Bats is not required
- **General users**: No Bats installation needed. All features work normally
- **Developers**: Bats installation recommended (for test execution)
- **Details**: See [Test System Guide](.claude/tests/README.md)

### Test Templates
- **Pre-defined templates**: For common test scenarios
- **Automatic mock generation**: Automatic mock creation for dependencies
- **Coverage tracking**: Real-time coverage monitoring
- **Quality gates**: Enforce 80%+ coverage

### Test-First Development Support
- **Test generation guide**: Assists in creating failing tests
- **Assertion suggestions**: Recommends appropriate assertions
- **Test case analysis**: Edge case detection

## Agent Coordination Optimization (NEW!)

### Smart Handoff
- **Context compression**: Efficient agent switching
- **Important information extraction**: Automatic selection of information needed for handoff
- **Mode information transmission**: Preserve special mode states

### Parallel Execution Analysis
- **Task dependencies**: Identify tasks that can be executed in parallel
- **Resource conflict detection**: Pre-detect issues during concurrent execution
- **Optimal execution order**: Suggest efficient task ordering

### Performance Monitoring
- **Agent efficiency**: Track processing time for each agent
- **Bottleneck detection**: Identify inefficient processes
- **Improvement suggestions**: Specific suggestions for optimization

## Process Optimization System

### Refactoring Scheduler
- **Automatic analysis**: Automatically detect areas requiring refactoring
- **Priority calculation**: Calculate priorities based on impact, frequency, and complexity
- **Regular reports**: Generate daily/weekly refactoring suggestions
- **Execution**: `python .claude/scripts/refactoring-analyzer.py`
- **Configuration**: @.claude/refactoring-config.json
- **Details**: @.claude/shared/refactoring-scheduler.md

### Design Change Tracking
- **Change history management**: Systematically record all design changes
- **Impact analysis**: Automatically analyze the impact of design changes on code
- **Drift detection**: Regularly check for divergence between design and implementation
- **Execution**: `python .claude/scripts/design-drift-detector.py`
- **Change log**: @.claude/shared/design-tracker/change-log/
- **Details**: @.claude/shared/design-tracker/design-tracker.md

### Quality Gates
- **Test coverage**: Automatically check for 80%+ coverage
- **Code complexity**: Enforce cyclomatic complexity ≤10
- **Security scan**: Detect hardcoded secrets
- **Code duplication**: Target ≤5%
- **Execution**: `python .claude/scripts/quality-check.py`
- **Configuration**: @.claude/quality-config.json
- **Details**: @.claude/shared/quality-gates.md

### Quality Levels
- 🟢 **Green**: All quality standards met
- 🟡 **Yellow**: Minor issues present (warnings)
- 🔴 **Red**: Critical issues present (merge blocked)

### Pre-commit Integration
```bash
# Automatic quality check
.claude/scripts/quality-pre-commit.sh
```

## Documentation Structure (NEW!)
All project documents are organized under the `docs/` directory:

```
docs/
├── requirements/     # Requirements definition (functional & non-functional requirements)
├── design/          # Design documents (architecture, API, DB design)
├── tasks/           # Task management (phase-based, priority management)
├── adr/             # Architecture Decision Records
├── specs/           # Implementation specifications (by component)
├── test-specs/      # Test specifications
└── operations/      # Operations documentation
```

### Agent Constraints
- **Planner**: Create all documents under `docs/`
- **Builder**: Always check `docs/tasks/` → `docs/specs/` in order before implementation

## Project Data
- Settings: `.claude/settings.json`
- Requirements: @docs/requirements/index.md

## Memory Bank Usage Policy
- **Normal**: Reference only core files to minimize context
- **When details needed**: Explicitly specify context files
- **Regular cleanup**: Move old information to archive

## Project-Specific Learning
Automatically recorded in `.clauderules` file.

## Code Style
- **AI-Friendly Comments**: Follow guidelines at `.claude/shared/ai-friendly-comments.md`
- **Comment Philosophy**: Explain "Why" not "What"
- **Required Comments**: Complex algorithms, business rules, performance optimizations
- **Avoid**: Obvious comments, code translations, outdated specifications

## Related Documents
- Development rules details: @docs/development-rules.md
- Development guidelines: @.claude/guidelines/development.md
- Hooks system: @.claude/hooks-README.md
- Security settings: @.claude/security-README.md
- AI logger system: @.claude/ai-logger-README.md | @.claude/vibe-logger-integration.md
- Requirements specification: @docs/requirements.md
- ADR template: @docs/adr/template.md
- Gradual adoption guide: @memo/gradual-adoption-guide.md
- Implementation guide: @memo/zero-to-memory-bank.md
- TDD Guide: @.claude/builder/tdd-cycle.md
- Design Sync Guide: @.claude/shared/design-sync.md
- Quality Gates: @.claude/shared/quality-gates.md
- Refactoring Scheduler: @.claude/shared/refactoring-scheduler.md
- Best Practices: @BEST_PRACTICES.md
- Architecture: @ARCHITECTURE.md
