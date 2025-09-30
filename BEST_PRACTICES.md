# Best Practices for Claude Friends Templates

🌐 **[日本語版](BEST_PRACTICES_ja.md)** | **English**

This guide provides best practices for developing with Claude Friends Templates, based on real-world experience and quality metrics from production environments.

---

## 📋 Table of Contents

- [Code Quality Standards](#code-quality-standards)
- [Test-Driven Development (TDD)](#test-driven-development-tdd)
- [Architecture Principles](#architecture-principles)
- [Performance Guidelines](#performance-guidelines)
- [Security Best Practices](#security-best-practices)
- [Documentation Standards](#documentation-standards)
- [Git Workflow](#git-workflow)

---

## 🎯 Code Quality Standards

### Complexity Metrics

Based on our quality audit (September 2025), maintain these standards:

- **Cyclomatic Complexity**: Keep functions at **Grade B (6-10)** or better
- **Maintainability Index**: All files should achieve **Grade A (20-100)**
- **Average Project Complexity**: Target **B (8.9)** or lower

**Current Achievement**: ✅ 23/23 scripts maintain Grade A maintainability

### Code Style

Use **ruff** for consistent formatting:

```bash
# Format code
ruff format .claude/

# Check style
ruff check .claude/ --select I
```

**Standards**:
- Import sorting: stdlib → third-party → local
- Line length: 100 characters (relaxed from 88 for readability)
- Type hints: Use Python 3.12+ native types (`dict`, `list` instead of `Dict`, `List`)

### Static Analysis

Run comprehensive static analysis before commits:

```bash
# Type checking
mypy .claude/scripts/ --ignore-missing-imports

# Complexity analysis
radon cc .claude/scripts/ -a -nb

# Maintainability index
radon mi .claude/scripts/ -s
```

**Target Scores**:
- Radon CC: Average Grade B or better
- Radon MI: All files Grade A
- Mypy: Zero type errors in new code

---

## 🔴 Test-Driven Development (TDD)

### t-wada Style Red-Green-Refactor Cycle

Follow strict TDD discipline:

#### 🔴 Red Phase: Write Failing Tests First
```python
def test_handover_generation():
    """Test handover document generation"""
    generator = HandoverGenerator("planner", "builder")
    result = generator.create_handover_document()
    assert result is not None
    assert "current_task" in result
```

#### 🟢 Green Phase: Make Tests Pass
```python
def create_handover_document(self):
    return {
        "current_task": self.get_current_task(),
        "recent_activities": self.extract_recent_activities()
    }
```

#### 🔵 Refactor Phase: Improve Code Quality
- Extract methods for complexity < 10
- Apply design patterns (Command, Strategy, Factory)
- Ensure all tests still pass

### Test Coverage Standards

**Current Achievement** (September 2025):
- **Test Success Rate**: 98.3% (295/300 tests passing)
- **E2E Tests**: 56/56 passed (100%)
- **Unit Tests**: 239/244 passed (98%)

**Guidelines**:
- **Critical paths**: 90%+ coverage
- **New features**: 80%+ coverage
- **Edge cases**: Explicit test cases for error conditions

### Test Organization

```
.claude/tests/
├── e2e/              # End-to-end integration tests
│   ├── test_e2e_performance.py
│   └── test_e2e_bash_integration.bats
├── unit/             # Unit tests for individual modules
│   ├── test_ai_logger.py
│   └── test_handover_generator.py
└── bats/             # BATS tests for bash scripts
    └── test_hooks.bats
```

---

## 🏛️ Architecture Principles

### Modular Independence

**Achievement**: Zero circular dependencies, 100% modular design

**Principles**:
1. **Single Responsibility**: Each script has one clear purpose
2. **No Internal Dependencies**: Scripts don't import each other
3. **Standard Library Only**: Avoid external dependencies when possible

### Coupling Standards

Based on import count analysis:

- **Low Coupling (≤8 imports)**: ✅ Ideal (56% of codebase)
- **Medium Coupling (9-15 imports)**: ✅ Acceptable (43% of codebase)
- **High Coupling (>15 imports)**: ❌ Avoid (0% achieved)

### Layer Separation

```
┌─────────────────────────────────────┐
│   .claude/scripts/ (CLI Tools)      │  ← No dependencies on tests
├─────────────────────────────────────┤
│   .claude/tests/ (Test Suites)      │  ← Can import from scripts
├─────────────────────────────────────┤
│   Python Standard Library           │  ← Only external dependency
└─────────────────────────────────────┘
```

**Rule**: Scripts MUST NOT import from tests directory

---

## ⚡ Performance Guidelines

### Response Time Targets

Based on production benchmarks (September 2025):

| Operation | Target | Current |
|-----------|--------|---------|
| Hook Response | < 100ms | 86.368ms (p95) ✅ |
| Handover Generation | < 500ms | 350-450ms ✅ |
| State Synchronization | < 650ms | 400-600ms ✅ |
| All Operations | < 500ms | ✅ Achieved |

### Memory Efficiency

- **Peak Memory**: < 50MB target, **5MB achieved** ✅
- **Memory Leaks**: Zero tolerance, **0 detected** ✅

### Optimization Priorities

1. **Re.compile**: Pre-compile regex patterns at module level
2. **lru_cache**: Cache expensive computations
3. **Generator Expressions**: Use for large datasets
4. **String Join**: Use `"".join(list)` instead of `+=` concatenation

**Example**:
```python
import re
from functools import lru_cache

# Pre-compile regex (module level)
PATTERN = re.compile(r'[a-zA-Z0-9]+')

@lru_cache(maxsize=128)
def expensive_operation(param: str) -> str:
    """Cache results for repeated calls"""
    return PATTERN.search(param)
```

---

## 🔒 Security Best Practices

### Vulnerability Management

**Current Status** (September 2025):
- **High-Risk**: 0 vulnerabilities ✅
- **Medium-Risk**: 0 vulnerabilities ✅
- **Security Audit**: All scripts rated Grade A

### Input Validation

Always validate and sanitize user input:

```python
import tempfile
from pathlib import Path

# ✅ GOOD: Use secure temporary directories
temp_dir = tempfile.mkdtemp(prefix="validation_")

# ❌ BAD: Hardcoded paths
# temp_dir = "/tmp/validation"  # B108 vulnerability
```

### Security Scanning

Run before each release:

```bash
# Bandit security scan
bandit -r .claude/ -f json

# Dependency vulnerabilities
pip-audit --requirement requirements.txt

# SBOM generation
python .claude/scripts/sbom-generator.py --format cyclonedx
```

**Zero Tolerance**: Fix all High and Medium severity issues before merge

---

## 📝 Documentation Standards

### Bilingual Synchronization

Maintain English and Japanese versions in sync:

- `README.md` ↔ `README_ja.md`
- `SECURITY.md` ↔ `SECURITY_ja.md`
- All major documents should have `*_ja.md` pairs

**Synchronization Checklist**:
- [ ] Same section structure
- [ ] Same header hierarchy
- [ ] Content equivalence (not word-for-word translation)
- [ ] Links updated in both versions

### Docstring Standards

Use Google-style docstrings:

```python
def create_handover_document(
    self,
    from_agent: str,
    to_agent: str
) -> dict[str, Any]:
    """Create a handover document for agent transition.

    Args:
        from_agent: Source agent name (e.g., "planner")
        to_agent: Target agent name (e.g., "builder")

    Returns:
        Dictionary containing handover information with keys:
        - current_task: Current task description
        - recent_activities: List of recent actions
        - blockers: Known blockers or issues

    Raises:
        ValueError: If agent names are invalid
    """
```

### Code Comments

- **Why, not What**: Explain reasoning, not obvious operations
- **TODOs**: Use `# TODO(username): Description` format
- **Performance Notes**: Document optimization decisions

---

## 🌿 Git Workflow

### Commit Message Format

Follow Conventional Commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `test`: Test additions/modifications
- `docs`: Documentation changes
- `perf`: Performance improvements
- `chore`: Maintenance tasks

**Example**:
```
feat(handover): Add compression for large contexts

Implement context compression using zlib when content exceeds
max_tokens threshold. Reduces handover size by 40% on average.

Refs: #123
```

### Branch Strategy

- `main`: Production-ready code
- `develop`: Integration branch
- `feature/*`: New features
- `fix/*`: Bug fixes
- `refactor/*`: Code improvements

### Pull Request Checklist

- [ ] All tests pass (98%+ success rate)
- [ ] Code coverage maintained (80%+ for new code)
- [ ] Static analysis passes (mypy, ruff, bandit)
- [ ] Documentation updated (bilingual if applicable)
- [ ] CHANGELOG.md updated

---

## 📊 Quality Metrics Dashboard

Monitor these metrics continuously:

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Test Success Rate | ≥95% | 98.3% | ✅ |
| Code Complexity | Grade B | B (8.9) | ✅ |
| Maintainability | Grade A | 100% A | ✅ |
| Circular Dependencies | 0 | 0 | ✅ |
| Security Issues | 0 High/Med | 0 | ✅ |
| Performance | <500ms | 350-450ms | ✅ |

**Last Updated**: September 30, 2025

---

## 🎓 Learning Resources

- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) by Robert C. Martin
- [Test Driven Development](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530) by Kent Beck
- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- [Python Best Practices](https://docs.python-guide.org/)

---

## 📞 Questions?

- **General Discussion**: Use GitHub Discussions
- **Bug Reports**: Create an issue with `bug` label
- **Security Issues**: Email security@claude-friends-templates.local

**Remember**: Quality is not an act, it is a habit. - Aristotle
