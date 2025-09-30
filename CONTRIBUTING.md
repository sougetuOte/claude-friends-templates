# Contributing to Claude Friends Templates

🌐 **English** | **[日本語](CONTRIBUTING_ja.md)**

Thank you for your interest in contributing to Claude Friends Templates! This document provides guidelines and instructions for contributing to the project.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)
- [Submitting Changes](#submitting-changes)
- [Review Process](#review-process)

---

## 🤝 Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@claude-friends-templates.local.

---

## 🚀 Getting Started

### Prerequisites

- **Python**: 3.12 or higher
- **Git**: For version control
- **GitHub Account**: For submitting pull requests

### Setting Up Development Environment

```bash
# 1. Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/claude-friends-templates.git
cd claude-friends-templates

# 2. Create a feature branch
git checkout -b feature/your-feature-name

# 3. Install development dependencies (optional)
pip install -r requirements-dev.txt  # If you need testing tools

# 4. Verify installation
python .claude/scripts/quality-check.py --help
```

### Project Structure

```
claude-friends-templates/
├── .claude/
│   ├── agents/        # Agent identity files
│   ├── scripts/       # Automation scripts
│   ├── guidelines/    # Development guidelines
│   └── tests/         # Test suites
├── docs/              # Documentation
├── memo/              # Memory Bank system
└── README.md          # Project documentation
```

---

## 🔄 Development Workflow

### 1. Choose an Issue

- Browse [open issues](https://github.com/sougetuOte/claude-friends-templates/issues)
- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue to claim it

### 2. Create a Feature Branch

```bash
git checkout -b feature/issue-123-description
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or improvements

### 3. Make Changes

Follow the [TDD methodology](BEST_PRACTICES.md#tdd-methodology):

**Red Phase** (Write failing tests):
```python
# tests/test_new_feature.py
def test_new_feature():
    """Test 1: Feature should do X"""
    result = new_feature(input_data)
    assert result == expected_output
    # EXPECTED: FAIL
```

**Green Phase** (Implement minimal code):
```python
# .claude/scripts/new_feature.py
def new_feature(input_data):
    """Minimal implementation"""
    return expected_output
```

**Refactor Phase** (Improve code quality):
```python
# .claude/scripts/new_feature.py
def new_feature(input_data):
    """Production-ready implementation"""
    # Clean, maintainable code
    return process_data(input_data)
```

### 4. Run Quality Checks

```bash
# Run all quality checks
python .claude/scripts/quality-check.py --strict

# Individual checks
pytest tests/                    # Run tests
bandit -r .claude/scripts/       # Security scan
ruff check .                     # Linting
mypy .claude/scripts/            # Type checking
```

### 5. Commit Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: Add new feature X

- Implement feature X with Y
- Add tests for Z
- Update documentation

Fixes #123"
```

**Commit Message Format**:
```
<type>: <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build/tooling changes

---

## 💻 Coding Standards

### Python Code Quality

Based on our [Task 6.4 Quality Audit](memo/2025-09-30/task-6-4-1-final-quality-report.md):

**Metrics to Maintain**:
- **Test Coverage**: ≥90% (Project: 98.3%)
- **Cyclomatic Complexity**: Grade B (6-10) or better (Project: 8.9)
- **Maintainability Index**: Grade A (20-100) (Project: 100%)
- **Security**: 0 high/medium issues

### Code Style

```python
# ✅ Good: Clear, typed, documented
def generate_handover(
    from_agent: str,
    to_agent: str,
    max_tokens: int = 2000
) -> dict[str, Any]:
    """Generate handover document between agents.

    Args:
        from_agent: Source agent name
        to_agent: Target agent name
        max_tokens: Maximum tokens for context

    Returns:
        Handover document as dictionary

    Raises:
        ValueError: If agent names are invalid
    """
    # Implementation with error handling
    pass

# ❌ Bad: No types, no docs
def gen(a, b):
    return {}
```

### Architecture Principles

From [ARCHITECTURE.md](ARCHITECTURE.md):

1. **Zero Circular Dependencies**: ✅ Maintain 0 cycles
2. **Module Independence**: ✅ No internal script dependencies
3. **Standard Library Only**: ✅ Avoid external dependencies
4. **Clean Layer Separation**: ✅ Scripts → Tests (one-way)

---

## 🧪 Testing Guidelines

### Test Structure

```python
# tests/test_feature.py
import pytest

class TestFeature:
    """Test Suite: Feature functionality"""

    @pytest.fixture
    def setup_data(self):
        """Fixture: Test data setup"""
        return {"key": "value"}

    def test_basic_functionality(self, setup_data):
        """Test 1: Basic functionality works"""
        # Arrange
        input_data = setup_data

        # Act
        result = feature_function(input_data)

        # Assert
        assert result is not None
        assert "expected_key" in result
```

### Test Categories

- **Unit Tests**: Individual function testing
- **Integration Tests**: Component interaction
- **E2E Tests**: Complete workflow scenarios
- **Performance Tests**: Speed and memory benchmarks

### Running Tests

```bash
# All tests
pytest tests/ -v

# Specific test file
pytest tests/test_feature.py -v

# With coverage
pytest tests/ --cov=.claude/scripts --cov-report=html

# E2E tests only
pytest tests/e2e/ -v -m e2e
```

---

## 📚 Documentation Guidelines

### Bilingual Documentation

All root-level documents MUST be bilingual:

```
README.md         ← English (primary)
README_ja.md      ← Japanese (synchronized)
```

**Synchronization Requirements**:
- Identical section structure
- Equivalent content (not literal translation)
- Same links and references
- Updated together in same PR

### Documentation Types

1. **API Documentation**: Generated from docstrings
2. **User Guides**: Step-by-step instructions
3. **Architecture Docs**: System design and patterns
4. **ADRs**: Architecture Decision Records in `docs/adr/`

### Writing Style

- **Clear and concise**: Short sentences, active voice
- **Code examples**: Provide working examples
- **Visual aids**: Diagrams, tables, code blocks
- **Cross-references**: Link to related documents

---

## 📤 Submitting Changes

### Before Submitting

**Checklist**:
- [ ] All tests pass (pytest)
- [ ] Code passes linting (ruff)
- [ ] Security scan clean (bandit)
- [ ] Coverage ≥90% for new code
- [ ] Documentation updated (both EN/JA if applicable)
- [ ] Commit messages follow convention
- [ ] No debug code or comments

### Creating Pull Request

1. **Push to your fork**:
```bash
git push origin feature/your-feature-name
```

2. **Open Pull Request** on GitHub:
- Title: `feat: Add feature X` (follow commit convention)
- Description: Explain what, why, and how
- Reference: Link related issues (`Fixes #123`)
- Checklist: Include the checklist above

3. **PR Template**:
```markdown
## Description
Brief description of changes

## Motivation
Why is this change necessary?

## Changes
- Change 1
- Change 2

## Testing
How was this tested?

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Code reviewed
```

---

## 🔍 Review Process

### Review Timeline

- **Initial Review**: Within 48 hours
- **Follow-up**: Within 24 hours of updates
- **Approval**: Requires 1+ maintainer approval

### Review Criteria

Reviewers will check:

1. **Functionality**: Does it work as intended?
2. **Tests**: Are tests comprehensive?
3. **Code Quality**: Does it meet standards?
4. **Documentation**: Is it documented?
5. **Architecture**: Does it fit the design?

### Addressing Feedback

```bash
# Make requested changes
git add .
git commit -m "fix: Address review feedback"
git push origin feature/your-feature-name
```

### Merge Process

Once approved:
1. Maintainer merges PR
2. Feature branch deleted
3. Changes appear in `main`

---

## 🎯 Contribution Areas

### Priority Areas

1. **Testing**: Improve test coverage (current: 98.3%)
2. **Documentation**: Bilingual sync and examples
3. **Performance**: Optimization opportunities
4. **Security**: Enhanced security features

### Good First Issues

Look for issues with these labels:
- `good first issue`
- `documentation`
- `help wanted`
- `enhancement`

---

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Questions, ideas, general discussion
- **Email**: dev@claude-friends-templates.local

### Resources

- [Best Practices](BEST_PRACTICES.md) - Code quality guidelines
- [Architecture](ARCHITECTURE.md) - System design
- [Sample Projects](SAMPLE_PROJECTS.md) - Implementation examples
- [Security Policy](SECURITY.md) - Security guidelines

---

## 🏆 Recognition

Contributors are recognized in:
- [AUTHORS.md](AUTHORS.md) - All contributors
- Release notes - For each release
- GitHub contributors page

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

## 🙏 Thank You!

Your contributions make this project better for everyone. We appreciate your time and effort!

**Questions?** Open an issue or discussion - we're here to help!

---

**Last Updated**: 2025-09-30
**Version**: 2.0.0
