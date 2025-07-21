# Optimized Builder → Planner Handover Template

## Task Completion Summary
```yaml
task_id: "{original_task_id}"
status: completed|partial|blocked
completion_time: "{actual_time}"
variance_from_estimate: "{+/- time}"
```

## Implementation Summary
```yaml
# What was actually built
implemented:
  - feature: "{feature_name}"
    location: "{file:line}"
    type: "new|modified|refactored"
    
  - feature: "{feature_name}"
    location: "{file:line}"
    deviation: "{if_different_from_plan}"
    reason: "{why_deviated}"

test_coverage:
  unit: "{percentage}%"
  integration: "{percentage}%"
  files: ["{test_file_1}", "{test_file_2}"]
```

## Key Decisions Made
```yaml
# Only decisions that affect future planning
decisions:
  - id: "dec_{timestamp}"
    category: "architecture|design|implementation"
    decision: "{what_was_decided}"
    impact: "{how_it_affects_future_work}"
    alternatives_considered: ["{alt_1}", "{alt_2}"]
```

## Discovered Issues
```yaml
# Issues that Planner needs to address
issues:
  - id: "issue_{number}"
    severity: critical|high|medium|low
    type: "bug|design|performance|security"
    description: "{concise_description}"
    suggested_action: "{what_planner_should_consider}"
    affects_tasks: ["{task_id_1}", "{task_id_2}"]
```

## Updated Context
```yaml
# Only include what changed
context_updates:
  new_dependencies:
    - name: "{dependency}"
      reason: "{why_added}"
      
  modified_files:
    - path: "{file_path}"
      change_type: "structure|api|logic"
      
  learned_constraints:
    - "{new_constraint_discovered}"
```

## Next Steps Recommendation
```yaml
# Builder's input for planning
recommendations:
  immediate:
    - action: "{what_should_be_done_next}"
      reason: "{why_its_important}"
      estimated_effort: "{time_estimate}"
      
  future_considerations:
    - "{thing_to_keep_in_mind}"
```

## Parallel Work Opportunities
```yaml
# Identified during implementation
parallel_tasks:
  - task: "{task_description}"
    independent: true
    estimated_effort: "{time}"
    prerequisites: []
    
  - task: "{task_description}"
    independent: false
    depends_on: ["{task_id}"]
```

## Metrics
```yaml
# Performance and quality metrics
performance:
  build_time: "{seconds}"
  test_execution: "{seconds}"
  code_quality:
    lint_issues: {number}
    complexity: "{metric}"
    
lines_changed:
  added: {number}
  modified: {number}
  deleted: {number}
```

## Handover Metadata
```yaml
# Auto-generated metadata
generated_at: "{timestamp}"
builder_version: "{version}"
work_session_id: "{session_id}"
context_preserved: true|false
full_logs_available: true|false
```

---
<!-- Planner acknowledgment section -->
## Planner Acknowledgment
- [ ] Implementation reviewed
- [ ] Decisions understood
- [ ] Issues prioritized
- [ ] Next phase planned