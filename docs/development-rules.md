# Development Rules (Detailed)

> **📌 About this document**: Comprehensive development rules and standards. For a quick reference guide, see [Development Guidelines (Quick Reference)](.claude/guidelines/development.md).

## Package Management

### Recommended Tools
- **Unification Principle**: Unify per project (npm/yarn/pnpm, pip/poetry/uv, etc.)
- **Installation**: Recommend `[tool] add package` format
- **Execution**: Recommend `[tool] run command` format

### Prohibited Practices
- Mixed usage (using multiple package managers together)
- Using `@latest` syntax (recommend version pinning)
- Global installation (keep everything within project)

## Code Quality Standards

### Basic Principles
- **Type Annotations**: Add type information to all functions and variables
- **Documentation**: Required for public APIs and complex processes
- **Function Design**: Aim for single responsibility and small functions
- **Existing Patterns**: Always follow existing code patterns
- **Line Length**: 80-120 characters (unified by language/team)
- **Comments**: AI-friendly comments following the Why > What principle
  - See `.claude/guidelines/ai-friendly-development.md` for details

## Test Requirements

For detailed test requirements, TDD learning path, and test standards, please refer to:
- **📖 [Testing & Quality Guidelines](.claude/guidelines/testing-quality.md)**

Key highlights:
- **TDD Learning Path**: Gradual 3-phase approach for beginners
- **Coverage Target**: 80%+ for important features
- **Test Framework**: Use unified framework per project
- **Claude Code Support**: Test generation and self-debugging features

## Git/PR Conventions

For detailed Git workflow, commit message formats, PR conventions, and ADR practices, please refer to:
- **📖 [Git Workflow & ADR Guidelines](.claude/guidelines/git-workflow.md)**

Key conventions:
- **Commit Format**: `[prefix]: [change description]`
- **PR Title**: Same format as commit messages
- **Required Trailers**: Bug reports, GitHub issues
- **ADR System**: Architecture Decision Records for important technical choices

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
When errors occur, follow this order for efficient problem resolution:

1. **Format Errors** → `[tool] run format`
2. **Type Errors** → `[tool] run typecheck`
3. **Lint Errors** → `[tool] run lint:fix`
4. **Test Errors** → `[tool] run test`

### Common Problems and Solutions

#### Format/Lint Related
- **Line length errors**: Break at appropriate places, split strings with parentheses
- **Import order**: Use auto-fix `[tool] run lint:fix`
- **Unused imports**: Remove unnecessary imports

#### Type Check Related
- **Optional type errors**: Add null/undefined checks
- **Type inference errors**: Add explicit type annotations
- **Function signatures**: Verify argument and return types

#### Test Related
- **Test environment**: Verify necessary dependencies and settings
- **Async tests**: Ensure proper Promise handling
- **Mocks**: Appropriate mocking of external dependencies

### Best Practices

#### Development Mindset
- **Before commit**: Comprehensive check with `[tool] run check`
- **Minimal changes**: Avoid many changes at once
- **Existing patterns**: Match existing code style
- **Gradual fixes**: Split large changes into smaller ones

#### When Handling Errors
- **Read error messages carefully**: Identify specific causes
- **Check context**: Understand code around the error
- **Reference documentation**: Check official docs and team materials
- **Verify reproducibility**: Ensure same error doesn't occur after fix

#### Information Gathering and Questions
- **Environment info**: Specify OS, language, tool versions
- **Reproduction steps**: Record specific operation steps
- **Error logs**: Save complete error messages
- **Trial and error**: Record solutions already tried

## Quality Gates

### Required Check Items

#### Pre-commit Checks
- [ ] `[tool] run format` - Code formatting applied
- [ ] `[tool] run lint` - Lint warnings resolved
- [ ] `[tool] run typecheck` - Type check passed
- [ ] `[tool] run test` - All tests passed
- [ ] Git status check - No unintended file changes

#### Pre-PR Checks
- [ ] `[tool] run check` - Comprehensive check passed
- [ ] Self-review completed
- [ ] Related documentation updated
- [ ] Test cases added (new features/bug fixes)
- [ ] Breaking changes documented (if applicable)

#### Pre-deploy Checks
- [ ] `[tool] run build` - Build successful
- [ ] Integration tests passed
- [ ] Performance verified
- [ ] Security check
- [ ] Rollback procedure confirmed

### Automation Levels

#### Fully Automated (CI/CD)
- Code formatting
- Lint checks
- Type checks
- Unit test execution
- Build verification

#### Semi-automated (Human-initiated)
- Integration tests
- E2E tests
- Security scans
- Performance tests

#### Manual Verification Required
- Code review
- Architecture design confirmation
- Usability verification
- Business logic validity
- Data migration impact confirmation

### Checklist Operations
- **Daily**: Make pre-commit checks a habit
- **Weekly**: Review quality metrics
- **Monthly**: Review and improve check items