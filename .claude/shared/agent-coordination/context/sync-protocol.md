# Context Synchronization Protocol

## Overview

This protocol ensures consistent context sharing between agents, minimizing redundancy while maintaining critical information availability.

## Synchronization Levels

### 1. Real-time Sync (Critical)
- **Frequency**: Immediate
- **Triggers**:
  - Blocking issues discovered
  - Critical decisions made
  - Security vulnerabilities found
  - Breaking changes implemented
- **Content**: Only the specific critical update

### 2. Checkpoint Sync (High Priority)
- **Frequency**: After each completed task
- **Triggers**:
  - Task completion
  - Significant progress milestone
  - Architecture decision
- **Content**: Task results, decisions, updated dependencies

### 3. Periodic Sync (Standard)
- **Frequency**: Every 30 minutes or 5 tasks
- **Triggers**:
  - Time interval
  - Task count threshold
  - Context size threshold
- **Content**: Accumulated changes, cleaned history

### 4. Session Sync (Complete)
- **Frequency**: Start/end of work session
- **Triggers**:
  - Agent initialization
  - Session completion
  - Major phase transition
- **Content**: Full context snapshot

## Context Structure

```yaml
shared_context:
  version: "2.0"
  last_sync: "2024-01-20T10:30:00Z"
  sync_level: "checkpoint"

  project_state:
    current_phase: "implementation"
    active_tasks:
      - id: "task-123"
        status: "in_progress"
        owner: "builder"
        started: "2024-01-20T09:00:00Z"

    completed_tasks:
      - id: "task-122"
        result: "success"
        summary: "Database schema created"

    blocked_tasks:
      - id: "task-124"
        reason: "Awaiting API specification"
        blocker_owner: "planner"

  technical_context:
    architecture:
      pattern: "microservices"
      last_modified: "2024-01-19T15:00:00Z"
      hash: "a3f5b8c9"

    dependencies:
      added:
        - name: "redis"
          version: "7.0"
          reason: "Caching layer"

      removed: []

      updated:
        - name: "postgres"
          from: "14"
          to: "15"
          reason: "Performance improvements"

    code_changes:
      summary:
        files_added: 5
        files_modified: 12
        files_deleted: 0
        lines_added: 450
        lines_removed: 120

      significant_changes:
        - file: "src/auth/auth.service.ts"
          type: "new_api"
          description: "Added OAuth2 support"

  decisions_log:
    recent:
      - id: "dec-2024-01-20-001"
        type: "architecture"
        decision: "Use Redis for session storage"
        rationale: "Better performance than DB"
        impact: ["auth", "session"]
        decided_by: "planner"
        timestamp: "2024-01-20T08:30:00Z"

    archived_count: 45
    archive_location: ".claude/context/decisions-archive.yaml"

  communication:
    last_handover:
      from: "planner"
      to: "builder"
      timestamp: "2024-01-20T09:00:00Z"
      document: "handover-2024-01-20-001.md"
      acknowledged: true

    pending_questions:
      - id: "q-001"
        from: "builder"
        to: "planner"
        question: "Should we implement rate limiting?"
        context: "Login endpoint security"
        priority: "high"

    notes:
      - "Performance testing scheduled for next phase"
      - "Client prefers PostgreSQL over MySQL"
```

## Sync Operations

### 1. Push Update

```yaml
sync_update:
  operation: "push"
  agent: "builder"
  timestamp: "2024-01-20T10:30:00Z"
  changes:
    - path: "project_state.active_tasks[0].status"
      from: "in_progress"
      to: "completed"
    - path: "technical_context.code_changes.summary.files_added"
      from: 5
      to: 7
```

### 2. Pull Request

```yaml
sync_request:
  operation: "pull"
  agent: "planner"
  timestamp: "2024-01-20T10:35:00Z"
  requested_sections:
    - "project_state"
    - "decisions_log.recent"
  since: "2024-01-20T09:00:00Z"
```

### 3. Conflict Resolution

```yaml
conflict_resolution:
  detected: "2024-01-20T10:40:00Z"
  type: "concurrent_update"
  field: "project_state.active_tasks"

  resolution_strategy: "merge"
  result:
    - Planner's task additions retained
    - Builder's status updates applied
    - Timestamp updated to latest
```

## Implementation Guidelines

### 1. Efficient Updates

- Use JSON Patch format for small updates
- Compress large context before transmission
- Send only changed sections, not full context
- Use checksums to verify sync state

### 2. Conflict Prevention

- Use optimistic locking with version numbers
- Implement field-level ownership
- Queue updates during active operations
- Merge non-conflicting changes automatically

### 3. Performance Optimization

- Cache frequently accessed sections
- Lazy-load historical data
- Archive old decisions and completed tasks
- Use efficient serialization formats

### 4. Reliability

- Implement retry logic for failed syncs
- Maintain sync operation log
- Support offline operation with queue
- Validate context integrity after sync

## Sync Commands

### Manual Sync Trigger
```bash
claude-sync --level checkpoint --agent builder
```

### Force Full Sync
```bash
claude-sync --full --resolve-conflicts
```

### View Sync Status
```bash
claude-sync --status
```

### Sync History
```bash
claude-sync --history --last 10
```

## Error Handling

### Common Sync Errors

1. **Version Mismatch**
   - Auto-resolve if non-conflicting
   - Prompt for manual resolution if critical

2. **Network Failure**
   - Queue updates locally
   - Retry with exponential backoff
   - Alert on persistent failure

3. **Context Corruption**
   - Revert to last known good state
   - Request full sync from source of truth
   - Log corruption details for debugging

4. **Size Limit Exceeded**
   - Trigger automatic archival
   - Compress context aggressively
   - Split sync into multiple operations

## Monitoring

### Sync Metrics

```yaml
sync_metrics:
  total_syncs_today: 45
  average_sync_time: "230ms"
  sync_failures: 2
  context_size: "2.3MB"
  compression_ratio: 0.65

  by_level:
    critical: 3
    checkpoint: 15
    periodic: 25
    session: 2

  performance:
    fastest_sync: "45ms"
    slowest_sync: "1.2s"
    p95_sync_time: "450ms"
```

### Health Checks

- Context integrity validation every hour
- Sync performance monitoring
- Storage usage alerts
- Conflict frequency tracking

## Future Enhancements

1. **Predictive Sync**: Anticipate needed context
2. **Differential Compression**: Smart context diffing
3. **Multi-Agent Mesh**: Beyond two-agent sync
4. **Context Streaming**: Real-time context updates
5. **AI-Optimized Storage**: Learn access patterns
