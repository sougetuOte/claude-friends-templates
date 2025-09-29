# Project Management Commands

## `/project:diagnose`

**Purpose**: Comprehensive project status diagnosis

**Usage**:
```
/project:diagnose
```

**What It Does**:
- Analyzes all project documentation
- Checks requirements completeness (word count, functional/non-functional split)
- Verifies design documents (architecture.md, api.md, database.md)
- Evaluates task breakdown quality
- Provides scored assessment with specific recommendations

**Example Output**:
```
Project Diagnosis Report:
========================
Requirements: 🟢 Complete (Score: 4/5)
- docs/requirements/index.md found ✓
- Word count: 847 ✓
- Functional requirements: Present ✓
- Non-functional requirements: Present ✓
- Missing: Technical stack details

Design: 🟡 Partial (Score: 3/5)
- Architecture diagram: Present ✓
- API specification: Missing ❌
- Database design: Present ✓

Tasks: 🔴 Incomplete (Score: 1/5)
- Phase breakdown: Missing ❌
- Task details: Missing ❌

Recommendation: Complete API design, then generate detailed tasks
```

---

## `/project:quality-check`

**Purpose**: Verify completion of development stage requirements

**Usage**:
```
/project:quality-check
```

**What It Does**:
- Applies strict quality gates for each development phase
- Checks minimum completion criteria
- Validates against established quality standards
- Provides pass/fail assessment with specific missing items

**Example Output**:
```
Quality Gate Assessment:
=======================
Requirements Quality Gate: ✅ PASS
- Project overview: Clear ✓
- Functional requirements: 10+ items ✓
- Non-functional requirements: Complete ✓
- Technology stack: Decided ✓

Design Quality Gate: ❌ FAIL
- System architecture: Present ✓
- API design: Missing ❌
- Database schema: Missing ❌
- UI/UX wireframes: Missing ❌

Cannot proceed to implementation phase.
Missing items must be completed first.
```

---

## `/project:next-step`

**Purpose**: Provide specific, actionable next steps based on current project state

**Usage**:
```
/project:next-step
```

**What It Does**:
- Analyzes current project completion status
- Identifies the next logical development phase
- Provides specific, actionable recommendations
- Suggests appropriate specialist agent to continue work

**Example Output**:
```
Next Step Guidance:
==================
Current Phase: Requirements ✓ → Design (In Progress)

Immediate Next Actions:
1. Complete API specification (docs/design/api.md)
   - Define all endpoints with request/response schemas
   - Include authentication and error handling

2. Create database design (docs/design/database.md)
   - Entity relationship diagram
   - Table schemas with constraints

3. UI/UX wireframes (docs/design/ui-wireframes.md)
   - Key user flows
   - Component layout specifications

Recommended Approach:
→ Continue with /agent:planner to complete design phase
→ Estimated time: 2-3 hours for comprehensive design

Once design is complete, Agent First will approve progression to task generation phase.
```

## Integration Notes
- These commands work seamlessly with Agent First's guidance system
- Can be used independently by experienced users who want specific assessments
- Integrate with the stage-guard.sh system for consistent evaluation criteria
- Support both beginners (guided flow) and experts (direct access)
