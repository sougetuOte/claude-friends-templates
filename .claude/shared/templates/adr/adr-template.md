# ADR-[Number]: [Decision Title]

Date: [YYYY-MM-DD]
Status: [Proposed | Accepted | Deprecated | Superseded]
Deciders: [Decision maker names]
Technical Lead: [Technical lead name]

## Context and Background

[Why was this decision needed? What situation or challenges existed?]

### Problem Statement
[Clear, concise statement of the problem being solved]

### Current State
[Description of the existing architecture/implementation]

## Decision Drivers

- [ ] **Functional Requirements**: [What must the solution do?]
- [ ] **Quality Attributes**: [Performance, Security, Maintainability, etc.]
- [ ] **Constraints**: [Technical, Time, Resource constraints]
- [ ] **Design Principles**: [Project's guiding principles]

## Options Considered

### Option 1: [Option Name]
- **Overview**: [Option description]
- **Pros**:
  - [Advantage 1]
  - [Advantage 2]
- **Cons**:
  - [Disadvantage 1]
  - [Disadvantage 2]
- **Estimated Effort**: [Time/Resources needed]
- **Risk Level**: [Low/Medium/High]

### Option 2: [Option Name]
- **Overview**: [Option description]
- **Pros**:
  - [Advantage 1]
  - [Advantage 2]
- **Cons**:
  - [Disadvantage 1]
  - [Disadvantage 2]
- **Estimated Effort**: [Time/Resources needed]
- **Risk Level**: [Low/Medium/High]

### Option 3: [Status Quo - Do Nothing]
- **Overview**: Keep the current implementation
- **Pros**: No immediate effort required
- **Cons**: Problem persists

## Decision

**Choice**: [Selected option]

**Reasons**:
- [Primary reason for selection]
- [Secondary reason]
- [Additional justification]

### Decision Matrix
| Criteria | Weight | Option 1 | Option 2 | Option 3 |
|----------|--------|----------|----------|----------|
| Performance | High | ⭐⭐⭐ | ⭐⭐ | ⭐ |
| Maintainability | High | ⭐⭐ | ⭐⭐⭐ | ⭐ |
| Implementation Cost | Medium | ⭐ | ⭐⭐ | ⭐⭐⭐ |
| Risk | Low | ⭐⭐⭐ | ⭐⭐ | ⭐ |

## Consequences

### Positive Consequences
- [Expected positive impact 1]
- [Expected positive impact 2]
- [Long-term benefits]

### Negative Consequences/Risks
- [Potential risk 1] → **Mitigation**: [How to handle]
- [Potential risk 2] → **Mitigation**: [How to handle]

### Technical Impact
- **Architecture Changes**: [Impact on system architecture]
- **Code Changes**: [Estimated LOC, affected components]
- **Performance Impact**: [Expected changes in performance]
- **Security Impact**: [Security implications]

### Technical Debt Impact
- **Debt Introduced**: [New technical debt, if any]
- **Debt Resolved**: [Technical debt addressed by this decision]
- **Debt Tracking**: [Link to debt.md entry]

## Implementation Plan

### Phase 1: Preparation
- [ ] Design detailed implementation
- [ ] Create test plan (TDD approach)
- [ ] Review with stakeholders

### Phase 2: Implementation
- [ ] Write failing tests (Red Phase)
- [ ] Implement solution (Green Phase)
- [ ] Refactor code (Refactor Phase)
- [ ] Update documentation

### Phase 3: Validation
- [ ] Run all tests
- [ ] Performance testing
- [ ] Security review
- [ ] Code review

### Rollback Plan
[How to revert this decision if needed]

## Design Sync Requirements

- [ ] Design documents updated
- [ ] Implementation matches design
- [ ] Design drift check completed
- [ ] Related ADRs reviewed

## Follow-up

- **Review Schedule**: [When to review the decision - e.g., 3 months]
- **Success Metrics**:
  - [Measurable metric 1]
  - [Measurable metric 2]
- **Monitoring**: [What to monitor after implementation]

## Related Information

### Related ADRs
- ADR-[Number]: [Title] - [Relationship]
- ADR-[Number]: [Title] - [Relationship]

### Related Issues/PRs
- Issue #[Number]: [Title]
- PR #[Number]: [Title]

### References
- [Technical reference 1]
- [Blog post or article]
- [Internal documentation link]

## Appendix

### Research Notes
[Any additional research, benchmarks, or proof of concepts]

### Example Code
```[language]
// Example implementation snippet if relevant
```

---

**Template Version**: 1.0
**Based on**: Michael Nygard's ADR template, enhanced with claude-kiro-template practices

**Note**: This ADR records an important decision that will affect future technical choices. When changing or deprecating, clearly state the reasons in a new ADR and link back to this one.
