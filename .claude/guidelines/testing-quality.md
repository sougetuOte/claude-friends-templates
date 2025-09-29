# Testing, Quality & Technical Debt Management

🌐 **English** | **[日本語](testing-quality_ja.md)**

## Test Requirements (Gradual TDD Learning Path)

### TDD Learning Steps
#### Phase 1 (Week 1-2): No TDD Experience
- Focus on understanding and modifying existing code
- Adding tests after implementation is OK
- Master basic Claude Code operations

#### Phase 2 (Week 3-4): Start TDD Experience
- Experience TDD with small features (Claude supports test creation)
- "Write failing test first" → Implementation → Refactoring
- Experience Red-Green-Refactor cycle

#### Phase 3 (Month 2-3): Master TDD
- Apply TDD for new feature development
- Utilize self-debugging group (`claude test --fix`)
- TDD patterns become natural

### Test Standards
- **Test Framework**: Use unified framework for the project
- **Coverage Target**: 80%+ for important features (improve gradually)
- **Recommended Test Cases**:
  - Edge cases (boundary values, abnormal values)
  - Error handling
  - Corresponding tests for new features (create first after TDD mastery)
  - Regression tests for bug fixes

## Technical Debt Tracking

### Basic Operations
- **Debt Log**: @.claude/context/debt.md
- **Priority Classification**: High🔥 / Medium⚠️ / Low📝
- **Cost Estimation**: Estimate in hours, record actuals
- **Impact Range**: Record at file/feature level

### Cache Impact Analysis
- **Changes Requiring Deletion**: Calculate estimated additional cost
- **Optimization Improvements**: Measure cost reduction effect
- **TTL Management**: Plan considering 5-minute expiration

### Operation Rules
- **During New Feature Development**: Pre-predict and record potential debt
- **At Sprint End**: Prioritize incurred debt
- **Monthly**: Review and archive overall debt

### Continuous Improvement
- **Automatic Detection**: Monitor debt occurrence in CI/CD
- **Metrics**: Weekly debt increase/decrease check
- **Prevention**: Habituation of code review and refactoring
