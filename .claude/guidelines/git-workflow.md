# Git Workflow & ADR

🌐 **English** | **[日本語](git-workflow_ja.md)**

## Git/PR Conventions

### Commit Messages

#### Basic Format
`[prefix]: [change description]`

#### Prefix List
- `feat`: New feature addition
- `fix`: Bug fix
- `docs`: Documentation update
- `style`: Formatting, whitespace, etc. (no functional changes)
- `refactor`: Refactoring (no functional changes)
- `test`: Test addition/modification
- `chore`: Build, dependencies, configuration changes

#### Required Trailers
```bash
# Bug report-based fixes
git commit -m "fix: resolve memory leak in data processor" --trailer "Reported-by: Username"

# GitHub Issue related
git commit -m "feat: add user authentication" --trailer "Github-Issue: #123"
```

### Pull Request Conventions
- **Title**: Same format as commit messages
- **Description Requirements**:
  - **Background**: Why this change is needed
  - **Changes**: What was changed (high level)
  - **Impact**: Where it affects
  - **Testing**: How it was tested

### Review
- Assign appropriate reviewers
- Conduct self-review first
- Prohibition of tool mentions like `Co-authored-by`

## ADR (Architecture Decision Record)

### Basic Operations
- **Template**: @docs/adr/template.md
- **Create New ADR**: Generate template with `claude adr new "decision content"`
- **Numbering**: Manage with ADR-001, ADR-002...
- **Status**: Proposed → Accepted → Deprecated/Superseded

### Decisions to Record
- Technology stack selection (frameworks, libraries, etc.)
- Architecture design (database, API design, etc.)
- Security policies (authentication, encryption, etc.)
- Performance optimization techniques
- Deployment strategies

### Integration Systems
- **Debt Log**: Track technical impact in @.claude/context/debt.md
- **History Management**: Record decision history in @.claude/context/history.md
- **GitHub Integration**: Create PRs linked with Issue numbers
