# Optimized Planner → Builder Handover Template

## Task Summary
```yaml
task_id: "{task_id}"
priority: critical|high|medium|low
estimated_effort: "{time_estimate}"
dependencies: ["{dep_1}", "{dep_2}"]
parallel_capable: true|false
```

## Objectives
<!-- Concise bullet points, max 5 items -->
- [ ] Primary objective in 10 words or less
- [ ] Secondary objectives if critical

## Technical Context
```yaml
# Only include what's needed for this specific task
stack:
  language: "{primary_language}"
  framework: "{if_applicable}"
  database: "{if_applicable}"

constraints:
  - "{only_blocking_constraints}"

existing_code:
  relevant_files:
    - path: "{file_path}"
      purpose: "{why_builder_needs_this}"
```

## Implementation Plan
```yaml
# Structured plan for easy parsing
steps:
  - id: "step_1"
    action: "{verb} {what}"
    location: "{where}"
    details: "{only_if_complex}"
    test_first: true|false
    
  - id: "step_2"
    action: "{verb} {what}"
    depends_on: ["step_1"]
    parallel_with: ["step_3"]
```

## Success Criteria
```yaml
# Measurable outcomes
acceptance:
  - type: "test|feature|performance"
    criterion: "{specific_measurable_criterion}"
    verification: "{how_to_verify}"
```

## Critical Information
<!-- Only include if it would block or significantly impact implementation -->
⚠️ **{Category}**: {Critical information that could cause failure if missed}

## Resources
<!-- Only include if Builder needs to reference -->
- [{Resource Name}]({link}): {One-line description of why needed}

## Handover Metadata
```yaml
# Auto-generated metadata for optimization
generated_at: "{timestamp}"
planner_version: "{version}"
optimization_level: "high"
context_hash: "{hash_of_full_context}"
excluded_info:
  - "{what_was_intentionally_omitted}"
  - "{available_in_shared_context}"
```

---
<!-- Builder acknowledgment section -->
## Builder Acknowledgment
- [ ] Task understood
- [ ] Dependencies available
- [ ] Ready to proceed
- [ ] Blockers identified: _{list if any}_