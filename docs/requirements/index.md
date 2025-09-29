---
cache_control: {"type": "ephemeral"}
---
# [Project Name] Requirements Specification

## 1. Project Overview

### 1.1 Purpose
[Describe the purpose of the project]

### 1.2 Scope
- Users: [Describe target users]
- Environment: [Describe operating environment]
- Constraints: [Describe constraints]

### 1.3 Technology Stack
- **Frontend**: [Describe technologies to use]
- **Backend**: [Describe technologies to use]
- **Database**: [Describe database to use]
- **Others**: [Describe other technologies]

## 2. Functional Requirements

### 2.1 [Main Feature 1]
#### 2.1.1 [Detailed Feature]
- [Feature description]
- [Required elements]
- [Constraints]

#### 2.1.2 [Detailed Feature]
- [Feature description]
- [Required elements]
- [Constraints]

### 2.2 [Main Feature 2]
#### 2.2.1 [Detailed Feature]
- [Feature description]
- [Required elements]
- [Constraints]

## 3. Non-Functional Requirements

### 3.1 Performance Requirements
- [Response time requirements]
- [Concurrent connections]
- [Data processing volume]

### 3.2 Usability Requirements
- [UI/UX requirements]
- [Accessibility requirements]
- [Multi-language support]

### 3.3 Security Requirements

#### 3.3.1 Command Execution Security
- **Dangerous Command Blocking**: Automatic detection and blocking of system-destructive commands
- **Allow List Management**: Pre-approval of safe commands necessary for development
- **Real-time Monitoring**: Command execution monitoring using Claude Code hooks
- **Security Logging**: Recording and auditing of executed commands

For detailed implementation, blocked/allowed command lists, testing procedures, and configuration:
- **🔒 [Security Configuration Guide](.claude/security-README.md)**
- **🔧 [Security Test Suite](.claude/scripts/test-security.sh)**

#### 3.3.2 General Security Requirements
- [Authentication and authorization]
- [Data encryption]
- [Audit logs]
- [Access control policies]

### 3.4 Development and Operation Requirements
- Version control: [VCS to use]
- Development environment: [Development environment description]
- Testing: [Testing policy]
- Deployment: [Deployment method]

## 4. Database Design

### 4.1 Table Structure

#### [Table Name 1]
```sql
CREATE TABLE [table_name] (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    -- Column definitions
);
```

#### [Table Name 2]
```sql
CREATE TABLE [table_name] (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    -- Column definitions
);
```

## 5. API Design

### 5.1 Endpoint List

#### [Resource Name] Related
- `GET /api/[resource]` - Get list
- `GET /api/[resource]/:id` - Get details
- `POST /api/[resource]` - Create new
- `PUT /api/[resource]/:id` - Update
- `DELETE /api/[resource]/:id` - Delete

### 5.2 Request/Response Specifications
[Describe detailed API specifications]

## 6. Directory Structure

```
[project-name]/
├── .claude/           # Memory Bank
├── docs/              # Documentation
├── src/               # Source code
├── tests/             # Test code
├── config/            # Configuration files
├── CLAUDE.md          # Project configuration
├── .clauderules       # Project insights
└── README.md          # Project description
```

## 7. Development Schedule

### Phase 1: [Phase Name] (Period)
- [Task 1]
- [Task 2]
- [Task 3]

### Phase 2: [Phase Name] (Period)
- [Task 1]
- [Task 2]
- [Task 3]

## 8. Success Criteria

- [ ] [Success criterion 1]
- [ ] [Success criterion 2]
- [ ] [Success criterion 3]

## 9. Risks and Countermeasures

| Risk | Impact | Probability | Countermeasure |
|------|--------|-------------|----------------|
| [Risk 1] | High/Medium/Low | High/Medium/Low | [Countermeasure] |
| [Risk 2] | High/Medium/Low | High/Medium/Low | [Countermeasure] |

## 10. Notes

[Describe other important matters]

---

## 📋 Next Step: Design Phase

### Requirements are now complete! Time to move to the design phase.

1. **Use the Design Generation Template**
   - Location: `.claude/shared/templates/design/`
   - Purpose: Transform these requirements into technical design

2. **What to expect in Design Phase**
   - Architecture decisions
   - Component design
   - Interface definitions
   - Data models
   - Technical specifications

3. **Handover to Planner Agent**
   ```
   /agent:planner
   "Requirements are complete. Please proceed with design phase using the requirements above."
   ```

### Design Phase Checklist
- [ ] All functional requirements have been captured
- [ ] Non-functional requirements are clear
- [ ] Success criteria are measurable
- [ ] Stakeholders have reviewed and approved

---
*Good requirements lead to good design. Good design leads to good implementation.*
