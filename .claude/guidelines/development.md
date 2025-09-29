# Development Guidelines

🌐 **English** | **[日本語](development_ja.md)**

> **📌 About this document**: Quick reference for daily development. For detailed rules and comprehensive information, see [Development Rules (Detailed)](../../docs/development-rules.md).

## Claude Friends Agent Operation Rules

### Agent Role Division
- **Planner**: Strategy, planning, Phase management
- **Builder**: Implementation, testing, technical solutions

### Agent Switching Timing
1. **Planner → Builder**
   - When planning is complete and ready for implementation
   - When specific ToDos are clarified

2. **Builder → Planner**
   - When implementation reaches a milestone
   - When major design changes are needed
   - When next Phase planning is required

### Handover Rules
- **Required**: Create handover.md before agent switching
- **Content**: Clearly state completed items, next tasks, and notes
- **Storage**: Move to archive after 1 week

### Interrupt Handling
- Create `handover-interrupt-[datetime].md` for emergencies
- Document detailed resumption instructions for interrupted work

## Package Management
- **Recommended Tools**: Unify per project (npm/yarn/pnpm, pip/poetry/uv, etc.)
- **Installation**: Recommend `[tool] add package` format
- **Execution**: Recommend `[tool] run command` format
- **Prohibited Practices**:
  - Mixed usage (using multiple package managers together)
  - Using `@latest` syntax (version pinning recommended)
  - Global installation (keep everything within project)

## Code Quality Standards
- **Type Annotations**: Add type information to all functions and variables
- **Documentation**: Required for public APIs and complex processes
  - Follow AI-friendly comment guidelines
  - Include business context and constraints
  - Document performance considerations
- **Function Design**: Aim for single responsibility and small functions
- **Existing Patterns**: Always follow existing code patterns
- **Line Length**: 80-120 characters (unified by language/team)

## Command List

### Basic Development Flow
```bash
# Project setup (first time only)
[tool] install                   # Install dependencies
[tool] run dev                   # Start development server

# Test execution
[tool] run test                  # Run all tests
[tool] run test:watch           # Watch mode

# Quality checks
[tool] run format               # Apply code formatting
[tool] run lint                 # Lint check and auto-fix
[tool] run typecheck            # Run type check (for applicable languages)

# Build and release
[tool] run build                # Production build
[tool] run check                # Comprehensive check (pre-CI confirmation)
```

### Package Management
```bash
[tool] add [package-name]       # Add dependency
[tool] remove [package-name]    # Remove dependency
[tool] update                   # Update all dependencies
```

**Note**: Replace `[tool]` with the package manager used in the project
- Node.js: `npm`, `yarn`, `pnpm`
- Python: `pip`, `poetry`, `uv`
- Rust: `cargo`
- Go: `go`
- Standard tools for other languages

## Error Handling Guide

### Standard Problem-Solving Order
1. **Format Errors** → `[tool] run format`
2. **Type Errors** → `[tool] run typecheck`
3. **Lint Errors** → `[tool] run lint:fix`
4. **Test Errors** → `[tool] run test`

### Common Problems and Solutions
- **Line length errors**: Break at appropriate places
- **Import order**: Use auto-fix
- **Type errors**: Add explicit type annotations

## Quality Gates

### Pre-commit Checks
- [ ] `[tool] run format` - Formatting applied
- [ ] `[tool] run lint` - Lint warnings resolved
- [ ] `[tool] run typecheck` - Type check passed
- [ ] `[tool] run test` - All tests passed

### CI/CD Automation
- Code formatting
- Lint checks
- Type checks
- Unit test execution
