# Sample Projects

🌐 **English** | **[日本語](SAMPLE_PROJECTS_ja.md)**

This document showcases real-world implementations and sample projects built using Claude Friends Templates. These examples demonstrate best practices, patterns, and practical applications of the template system.

---

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Sample Project Gallery](#sample-project-gallery)
- [Use Case Examples](#use-case-examples)
- [Implementation Patterns](#implementation-patterns)
- [Community Projects](#community-projects)

---

## 🚀 Getting Started

### Quick Start Template

The fastest way to start is using the basic template structure:

```bash
# Clone the template
git clone https://github.com/sougetuOte/claude-friends-templates.git my-project
cd my-project

# Customize for your project
# 1. Update README.md with your project details
# 2. Configure .claude/agents/ for your workflow
# 3. Adapt scripts in .claude/scripts/ as needed
```

### Minimal Setup Example

A minimal project requires:
- `.claude/agents/planner/identity.md` - Strategic planning agent
- `.claude/agents/builder/identity.md` - Implementation agent
- `.claude/scripts/handover-generator.py` - Context handover
- `README.md` - Project documentation

---

## 🎨 Sample Project Gallery

### 1. Web Application Project

**Description**: Full-stack web application with API backend and React frontend

**Structure**:
```
my-web-app/
├── .claude/
│   ├── agents/
│   │   ├── planner/
│   │   │   └── identity.md (architecture focus)
│   │   └── builder/
│   │       └── identity.md (implementation focus)
│   ├── scripts/
│   │   ├── handover-generator.py
│   │   ├── quality-check.py
│   │   └── deploy.py
│   └── guidelines/
│       ├── api-design.md
│       └── frontend-patterns.md
├── backend/
│   ├── src/
│   ├── tests/
│   └── requirements.txt
├── frontend/
│   ├── src/
│   ├── tests/
│   └── package.json
└── docs/
    └── adr/
```

**Key Features**:
- Multi-agent coordination for frontend/backend
- Automated quality checks with pytest and jest
- Deployment automation with rollback capability
- ADR (Architecture Decision Records) tracking

**Agent Workflow**:
1. Planner: Designs API contracts and component structure
2. Builder: Implements backend endpoints and React components
3. Handover: Shares context via JSON handover files
4. Quality: Automated tests, security scans, performance checks

### 2. CLI Tool Project

**Description**: Command-line utility with rich features and comprehensive documentation

**Structure**:
```
my-cli-tool/
├── .claude/
│   ├── agents/
│   │   └── builder/ (single agent for CLI simplicity)
│   ├── scripts/
│   │   ├── quality-check.py
│   │   └── sbom-generator.py
│   └── guidelines/
│       └── cli-ux.md
├── src/
│   ├── commands/
│   ├── utils/
│   └── main.py
├── tests/
├── docs/
└── setup.py
```

**Key Features**:
- Single Builder agent (no planning complexity needed)
- Rich CLI with argparse/click
- SBOM generation for supply chain security
- Comprehensive test coverage (>90%)

**Development Workflow**:
1. Define command structure in `src/commands/`
2. Builder agent implements with tests
3. Quality checks: bandit (security), pytest (tests), ruff (style)
4. SBOM generation before release

### 3. Data Science Project

**Description**: Machine learning pipeline with experiment tracking and model deployment

**Structure**:
```
ml-pipeline/
├── .claude/
│   ├── agents/
│   │   ├── planner/ (experiment design)
│   │   └── builder/ (implementation)
│   ├── scripts/
│   │   ├── handover-generator.py
│   │   ├── experiment-tracker.py
│   │   └── model-validator.py
│   └── guidelines/
│       ├── data-quality.md
│       └── model-evaluation.md
├── data/
│   ├── raw/
│   ├── processed/
│   └── features/
├── notebooks/
├── models/
├── src/
│   ├── preprocessing/
│   ├── training/
│   └── evaluation/
└── experiments/
    └── logs/
```

**Key Features**:
- Planner designs experiments and evaluation metrics
- Builder implements preprocessing and training pipelines
- Custom scripts for experiment tracking and model validation
- ADR for model architecture decisions

**Agent Workflow**:
1. Planner: Designs experiment, defines metrics, creates ADR
2. Builder: Implements data pipeline, trains models
3. Validation: Automated model evaluation and performance checks
4. Handover: Shares experiment results and insights

### 4. Documentation Site Project

**Description**: Static documentation site with automated generation and deployment

**Structure**:
```
docs-site/
├── .claude/
│   ├── agents/
│   │   └── builder/
│   ├── scripts/
│   │   ├── api-docs-generator.py
│   │   └── deploy.py
│   └── guidelines/
│       └── documentation-standards.md
├── docs/
│   ├── api/
│   ├── guides/
│   └── tutorials/
├── src/ (source project for API docs)
└── build/
```

**Key Features**:
- Single Builder agent (documentation focus)
- Automated API documentation generation
- Markdown/MDX with static site generator
- Continuous deployment on commit

**Development Workflow**:
1. Write content in `docs/`
2. Builder agent reviews and suggests improvements
3. API docs auto-generated from source code
4. Deploy script publishes to hosting platform

---

## 💡 Use Case Examples

### Use Case 1: Microservices Architecture

**Scenario**: Building a microservices system with multiple independent services

**Template Adaptation**:
- One template instance per microservice
- Shared guidelines in parent directory
- Cross-service handover for API contract coordination
- Centralized quality checks via CI/CD

**Directory Structure**:
```
microservices-project/
├── .claude-shared/
│   └── guidelines/
│       ├── api-contracts.md
│       └── security-standards.md
├── service-auth/
│   └── .claude/ (independent template)
├── service-users/
│   └── .claude/ (independent template)
└── service-orders/
    └── .claude/ (independent template)
```

### Use Case 2: Open Source Library

**Scenario**: Maintaining an open-source Python library with community contributions

**Template Adaptation**:
- Enhanced documentation for contributors
- Strict quality checks (coverage >90%)
- Security scanning with bandit and pip-audit
- Automated release process

**Key Customizations**:
- `CONTRIBUTING.md` with contribution guidelines
- `.claude/scripts/release.py` for automated releases
- `.claude/guidelines/code-review.md` for PR reviews
- GitHub Actions integration for CI/CD

### Use Case 3: Enterprise Application

**Scenario**: Large-scale enterprise application with compliance requirements

**Template Adaptation**:
- Additional security auditing scripts
- Compliance documentation (SOC2, GDPR, etc.)
- Enhanced ADR process for audit trails
- SBOM generation for supply chain security

**Key Customizations**:
- `.claude/scripts/compliance-checker.py`
- `.claude/scripts/audit-logger.py`
- `docs/compliance/` for regulatory documentation
- Mandatory security reviews in handover process

---

## 🔧 Implementation Patterns

### Pattern 1: Test-Driven Development (TDD)

Based on claude-kiro-template integration and Task 6.4 quality audit:

**Red Phase**:
```python
# tests/test_feature.py
def test_new_feature():
    """Test 1: Feature should do X"""
    # Arrange
    input_data = create_test_data()

    # Act
    result = new_feature(input_data)

    # Assert
    assert result == expected_output
    # EXPECTED: FAIL (feature not implemented)
```

**Green Phase**:
```python
# src/feature.py
def new_feature(input_data):
    """Minimal implementation to pass test"""
    return expected_output
```

**Refactor Phase**:
```python
# src/feature.py
def new_feature(input_data):
    """Production-ready implementation"""
    # Improved algorithm, error handling, etc.
    return process_data(input_data)
```

**Quality Metrics** (based on Task 6.4.1 results):
- **Test Coverage**: ≥90% (Project achieved: 98.3%)
- **Complexity**: Keep Grade B (6-10) or better (Project: B/8.9)
- **Maintainability**: All files Grade A (Project: 100%)

### Pattern 2: Multi-Agent Handover

**Planner Agent** (Strategic):
```json
{
  "from_agent": "planner",
  "to_agent": "builder",
  "timestamp": "2025-09-30T10:00:00Z",
  "current_task": {
    "description": "Implement user authentication API",
    "requirements": [
      "JWT token generation",
      "Password hashing with bcrypt",
      "Rate limiting"
    ],
    "architecture_decisions": {
      "adr_id": "ADR-001",
      "decision": "Use FastAPI for async support"
    }
  },
  "blockers": []
}
```

**Builder Agent** (Implementation):
```json
{
  "from_agent": "builder",
  "to_agent": "planner",
  "timestamp": "2025-09-30T12:00:00Z",
  "completed_tasks": [
    "JWT token generation with PyJWT",
    "Password hashing with bcrypt",
    "Rate limiting middleware"
  ],
  "test_results": {
    "total": 15,
    "passed": 15,
    "coverage": "94%"
  },
  "next_recommendations": [
    "Add OAuth2 support",
    "Implement refresh token rotation"
  ]
}
```

### Pattern 3: Automated Quality Gates

**Pre-commit Checks**:
```bash
# .claude/scripts/pre-commit.sh
#!/bin/bash

# Run all quality checks
python .claude/scripts/quality-check.py --strict

if [ $? -ne 0 ]; then
    echo "❌ Quality checks failed. Commit rejected."
    exit 1
fi

echo "✅ All quality checks passed."
```

**Quality Check Configuration**:
```python
# .claude/scripts/quality-check.py
QUALITY_THRESHOLDS = {
    "test_coverage": 90.0,      # Minimum coverage %
    "complexity": 10,            # Max cyclomatic complexity
    "maintainability": 20,       # Minimum MI score (Grade A)
    "security_issues": 0,        # Max high/medium issues
    "duplication": 5.0,          # Max duplication %
}
```

**Enforcement**:
- Pre-commit hooks block low-quality commits
- CI/CD pipeline enforces on pull requests
- Automated reports in handover documents

---

## 🌟 Community Projects

### Submit Your Project

We welcome community projects built with Claude Friends Templates!

**Submission Guidelines**:
1. Create a showcase document in `community-projects/your-project-name.md`
2. Include:
   - Project description
   - GitHub repository link
   - Key features and customizations
   - Screenshots (optional)
   - Lessons learned
3. Submit a pull request

**Example Submission**:
```markdown
# Project Name: CloudSync Manager

**Author**: @username
**Repository**: https://github.com/username/cloudsync-manager
**Category**: CLI Tool

## Description
A command-line tool for synchronizing files across multiple cloud storage providers (AWS S3, Google Cloud Storage, Azure Blob Storage).

## Key Features
- Multi-cloud support with unified interface
- Differential sync with change detection
- Progress tracking and retry logic
- Comprehensive test coverage (96%)

## Template Customizations
- Single Builder agent (CLI focus)
- Custom quality-check.py with cloud API mocking
- SBOM generation for supply chain security
- Automated release workflow

## Lessons Learned
- TDD approach reduced bugs by 80%
- Handover system helped maintain focus during long sessions
- Quality gates prevented regressions
```

### Featured Projects

Coming soon! Submit your project to be featured here.

---

## 📚 Additional Resources

### Learning Path

1. **Beginner**: Start with CLI Tool template (single agent, simple workflow)
2. **Intermediate**: Try Web Application template (multi-agent, complex coordination)
3. **Advanced**: Adapt Microservices pattern (distributed system, cross-service handover)

### Best Practices

See [BEST_PRACTICES.md](BEST_PRACTICES.md) for:
- Code quality standards (Task 6.4 metrics)
- TDD methodology (Red-Green-Refactor)
- Security practices (zero-trust model)
- Performance optimization guidelines

### Architecture Guidance

See [ARCHITECTURE.md](ARCHITECTURE.md) for:
- System overview and C4 model
- Module organization (23 independent scripts)
- Dependency analysis (zero circular dependencies)
- Design patterns (Command, Strategy, Factory, Singleton)

### Quality Metrics

Based on Task 6.4 Final Quality Audit (September 2025):
- **Test Success**: 98.3% (295/300 tests)
- **Code Complexity**: Average B (8.9)
- **Architecture**: 0 circular dependencies, 100% modular
- **Performance**: 350-450ms handover generation
- **Security**: 0 high/medium vulnerabilities

---

## 🤝 Contributing

Have a sample project or use case to share?

1. **Fork** this repository
2. **Create** a new file in `community-projects/`
3. **Submit** a pull request with your showcase

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📞 Questions?

- **Discussion**: Use GitHub Discussions with `sample-projects` label
- **Issues**: Report problems with `documentation` label
- **Email**: Contact dev@claude-friends-templates.local

**Last Updated**: 2025-09-30
**Version**: 2.0.0
