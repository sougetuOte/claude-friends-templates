# Architecture Overview

🌐 **[日本語版](ARCHITECTURE_ja.md)** | **English**

This document provides a comprehensive overview of the Claude Friends Templates architecture, based on analysis conducted in September 2025.

---

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Architecture Principles](#architecture-principles)
- [Module Organization](#module-organization)
- [Dependency Analysis](#dependency-analysis)
- [Design Patterns](#design-patterns)
- [Quality Metrics](#quality-metrics)

---

## 🏗️ System Overview

Claude Friends Templates is a multi-agent AI development system built on clean architecture principles with zero circular dependencies and 100% modular design.

### C4 Model - Context Level

```
┌─────────────────────────────────────────────────────┐
│           Claude Friends Templates System            │
│                                                       │
│  ┌─────────────────────────────────────────────┐   │
│  │         .claude/scripts/ (CLI Tools)         │   │
│  │                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐         │   │
│  │  │   Handover   │  │   Quality    │         │   │
│  │  │  Management  │  │  Assurance   │         │   │
│  │  └──────────────┘  └──────────────┘         │   │
│  │                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐         │   │
│  │  │   Security   │  │  Deployment  │         │   │
│  │  │   Analysis   │  │  Automation  │         │   │
│  │  └──────────────┘  └──────────────┘         │   │
│  └─────────────────────────────────────────────┘   │
│                                                       │
│  ┌─────────────────────────────────────────────┐   │
│  │        .claude/tests/ (Test Suites)          │   │
│  │   E2E Tests | Unit Tests | Integration       │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
           ↓ depends on (Standard Library only)
┌─────────────────────────────────────────────────────┐
│             Python 3.12 Standard Library             │
│   json | pathlib | typing | datetime | argparse     │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Architecture Principles

### 1. Zero Circular Dependencies

**Achievement**: ✅ **0 circular dependencies** across all 23 scripts

**Benefits**:
- Independent module development
- Isolated testing
- Clear change impact
- Flexible deployment

### 2. Complete Module Independence

**Achievement**: ✅ **No internal dependencies** between scripts

All scripts are completely independent - no script imports another script from `.claude/scripts/`.

### 3. Standard Library Only

**Achievement**: ✅ **100% Python standard library dependencies**

**External Dependencies**: None (for core functionality)

**Benefits**:
- Reduced security risks
- Lower maintenance burden
- Maximum compatibility
- No dependency conflicts

### 4. Clean Layer Separation

**Achievement**: ✅ **Zero layer violations**

```
Scripts Layer  →  Can use: Standard Library
                  Cannot use: Tests

Tests Layer   →  Can use: Scripts, Standard Library
                  Cannot use: Nothing (top layer)
```

---

## 📦 Module Organization

### Module Responsibility Matrix

| Category | Script | Primary Responsibility | Coupling |
|----------|--------|------------------------|----------|
| **Handover** | handover-generator.py | Context generation & compression | Medium (14) |
| | handover-generator-optimized.py | Optimized generation | Medium (14) |
| | state_synchronizer.py | State synchronization | Low (6) |
| **Quality** | quality-check.py | Comprehensive quality checks | Medium (9) |
| | quality-metrics.py | Metrics collection | Low (8) |
| | refactoring-analyzer.py | Refactoring analysis | Low (6) |
| | design-drift-detector.py | Design drift detection | Low (5) |
| **Security** | security-manager.py | Security management | Low (8) |
| | security-audit.py | Audit execution | Low (6) |
| | vulnerability-scanner.py | Vulnerability scanning | Medium (9) |
| | input-validator.py | Input validation | Medium (10) |
| | zero-trust-controller.py | Zero-trust control | Low (7) |
| **Deployment** | deploy.py | Deployment automation | Medium (11) |
| | sbom-generator.py | SBOM generation | Medium (9) |
| **Documentation** | api-docs-generator.py | API documentation | Medium (9) |
| **Logging** | ai_logger.py | AI-optimized logging | Medium (10) |
| | log_analysis_tool.py | Log analysis | Low (7) |
| | analyze-ai-logs.py | AI-driven analysis | Low (5) |
| | error_pattern_learning.py | Error pattern learning | Low (5) |
| | log_agent_event.py | Agent event logging | Low (3) |
| **Analysis** | task_parallelization_analyzer.py | Parallelization analysis | Medium (11) |
| **Utility** | python312_features.py | Python 3.12 features | Low (3) |
| | \_\_init\_\_.py | Package initialization | Low (0) |

**Total Modules**: 23 independent scripts

---

## 🔗 Dependency Analysis

### Coupling Distribution

Based on import count analysis (September 2025):

```
Low  Coupling (≤8 imports):   13/23 (56%) ✅ Excellent
Med  Coupling (9-15 imports):  10/23 (43%) ✅ Good
High Coupling (>15 imports):    0/23 (0%)  ✅ Perfect
```

### External Dependency Usage

Top 15 most-used standard library modules:

| Library | Usage Count | Category |
|---------|------------|----------|
| json | 19 scripts | Data serialization |
| pathlib | 19 scripts | File operations |
| typing | 17 scripts | Type hints |
| datetime | 16 scripts | Time operations |
| sys | 14 scripts | System operations |
| argparse | 12 scripts | CLI parsing |
| re | 10 scripts | Regular expressions |
| os | 10 scripts | OS operations |
| dataclasses | 9 scripts | Data structures |
| uuid | 6 scripts | Unique identifiers |
| subprocess | 5 scripts | Process management |
| collections | 4 scripts | Data structures |
| logging | 4 scripts | Logging |
| fnmatch | 3 scripts | Pattern matching |
| hashlib | 3 scripts | Hashing |

**Observation**: All dependencies are Python standard library - zero external packages required.

---

## 🎨 Design Patterns

### Applied Patterns

#### 1. Command Pattern
**Location**: [api-docs-generator.py](/.claude/scripts/api-docs-generator.py)

**Implementation**:
```python
def _handle_schema_generation(generator, args) -> int:
    """Command handler for schema generation"""
    if args.input and args.output:
        success = generator.generate_openapi_schema(...)
        return 0 if success else 1
    return -1  # Not handled
```

**Effect**: Reduced complexity from E (51+) → B (6-10)

#### 2. Strategy Pattern
**Location**: [handover-generator.py](/.claude/scripts/handover-generator.py)

**Implementation**: Compression strategy selection based on content size

```python
def compress_context(self, content: str, max_tokens: int) -> str:
    """Apply compression strategy based on size"""
    if len(content.split()) > max_tokens:
        return self._apply_compression(content)
    return content  # No compression needed
```

#### 3. Factory Method Pattern
**Location**: [ai_logger.py](/.claude/scripts/ai_logger.py)

**Implementation**: Logger instance creation and configuration

```python
def get_logger(name: str) -> AILogger:
    """Factory method for creating configured loggers"""
    logger = AILogger(name)
    logger.configure_handlers()
    return logger
```

#### 4. Singleton Pattern (Implicit)
**Location**: All CLI scripts

**Implementation**: Single entry point via `if __name__ == "__main__":`

**Effect**: Controlled concurrent execution

---

## 📊 Quality Metrics

### Architecture Quality Score

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Circular Dependencies | 0 | 0 | ✅ Perfect |
| Layer Violations | 0 | 0 | ✅ Perfect |
| Low Coupling Modules | >40% | 56% | ✅ Excellent |
| Medium Coupling Modules | <60% | 43% | ✅ Good |
| High Coupling Modules | 0 | 0 | ✅ Perfect |
| External Dependencies | Minimal | 0 external | ✅ Excellent |
| Module Independence | 100% | 100% | ✅ Perfect |

**Overall Architecture Grade**: ✅ **A+ (Exemplary)**

### Code Quality Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Average Complexity | Grade B | B (8.9) | ✅ Achieved |
| Maintainability Index | Grade A | 100% A | ✅ Perfect |
| Test Success Rate | ≥95% | 98.3% | ✅ Excellent |
| Security Issues | 0 High/Med | 0 | ✅ Perfect |

---

## 🔄 Data Flow

### Handover Generation Flow

```
User Request
    ↓
handover-generator.py
    ↓
1. get_current_task() → Read project files
    ↓
2. extract_recent_activities() → Parse git logs
    ↓
3. extract_blockers() → Analyze error logs
    ↓
4. compress_context() → Apply compression if needed
    ↓
5. create_handover_document() → Generate JSON
    ↓
Handover File (JSON)
```

### Quality Check Flow

```
User Request
    ↓
quality-check.py
    ↓
├─ check_code_complexity() → radon
├─ check_test_coverage() → pytest-cov
├─ check_security() → bandit
└─ check_duplication() → jscpd
    ↓
Aggregate Results
    ↓
generate_markdown_report()
    ↓
Quality Report (Markdown)
```

---

## 🚀 Performance Characteristics

### Execution Time (Production)

| Operation | Actual | Target | Status |
|-----------|--------|--------|--------|
| Handover Generation | 350-450ms | <500ms | ✅ |
| Quality Check | 500-800ms | <1000ms | ✅ |
| Security Scan | 400-600ms | <1000ms | ✅ |
| Deploy | 1-2s | <5s | ✅ |

### Memory Usage

- **Peak Memory**: 5.04 MB ✅ (Target: <50MB)
- **Average Memory**: 3-5 MB ✅
- **Memory Leaks**: 0 detected ✅

---

## 🎯 Future Architecture Considerations

### Phase 7+ Enhancements

1. **Adapter Pattern Introduction**
   - Purpose: Abstract external library integration
   - Priority: Low (only if external dependencies added)

2. **Architecture Testing**
   - Tool: pytest-archtest
   - Purpose: Automated layer violation detection
   - Priority: Medium

3. **Dependency Visualization**
   - Tool: pydeps with CI/CD integration
   - Purpose: Regular dependency graph generation
   - Priority: Low

### Maintenance Guidelines

**Keep**:
- ✅ Script independence (no mutual references)
- ✅ Standard library only usage
- ✅ Low-medium coupling levels
- ✅ Layer separation adherence

**Avoid**:
- ❌ Introducing circular dependencies
- ❌ Adding external dependencies without justification
- ❌ Creating high coupling (>15 imports)
- ❌ Layer violations (scripts importing tests)

---

## 📚 References

- **Quality Audit**: See `memo/2025-09-30/task-6-4-1-final-quality-report.md`
- **Architecture Analysis**: See `memo/2025-09-30/task-6-4-2-architecture-analysis.md`
- **Performance Profiling**: See `memo/2025-09-30/task-6-4-3-performance-profiling.md`

---

## 📞 Questions?

- **Architecture Discussion**: Use GitHub Discussions with `architecture` label
- **Design Proposals**: Create RFC (Request for Comments) issues
- **Technical Support**: Email dev@claude-friends-templates.local

**Last Updated**: September 30, 2025
**Version**: 2.0.0
