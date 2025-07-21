# Shared Memory Bank Structure

## Overview

The shared memory bank provides a structured, efficient storage system for context that both Planner and Builder agents can access and update.

## Memory Bank Architecture

```
shared-memory/
├── active/                 # Currently relevant context
│   ├── project.yaml       # Project metadata
│   ├── tasks.yaml         # Task states and progress
│   ├── decisions.yaml     # Recent decisions
│   └── blockers.yaml      # Active blockers
├── cache/                 # Frequently accessed data
│   ├── tech-stack.yaml    # Technology choices
│   ├── patterns.yaml      # Established patterns
│   └── constraints.yaml   # Project constraints
├── history/               # Historical data (compressed)
│   ├── 2024-01/          # Monthly archives
│   ├── 2024-02/
│   └── index.yaml        # History index
└── temp/                  # Temporary working data
    ├── handovers/        # Recent handover docs
    └── conflicts/        # Conflict resolution
```

## Active Memory Schema

### project.yaml
```yaml
project:
  id: "proj-2024-001"
  name: "E-commerce Platform"
  version: "0.3.0"
  phase: "implementation"
  started: "2024-01-01"
  
  metadata:
    client: "ACME Corp"
    deadline: "2024-06-01"
    budget_hours: 500
    hours_used: 127
  
  team:
    planner:
      active: true
      last_active: "2024-01-20T10:00:00Z"
    builder:
      active: true
      last_active: "2024-01-20T10:30:00Z"
  
  checkpoints:
    last_checkpoint: "2024-01-20T09:00:00Z"
    next_checkpoint: "2024-01-20T12:00:00Z"
```

### tasks.yaml
```yaml
tasks:
  active:
    task-123:
      name: "Implement user authentication"
      status: "in_progress"
      owner: "builder"
      priority: "high"
      started: "2024-01-20T09:00:00Z"
      progress: 65
      subtasks:
        - "Create login endpoint" # completed
        - "Implement JWT tokens"  # in_progress
        - "Add OAuth support"     # pending
      context_refs:
        - "decisions.yaml#/auth-strategy"
        - "cache/tech-stack.yaml#/auth"
  
  queued:
    task-124:
      name: "Design API documentation"
      status: "queued"
      owner: "planner"
      priority: "medium"
      dependencies: ["task-123"]
      estimated_hours: 4
  
  completed:
    count: 45
    recent:
      - task_id: "task-122"
        name: "Database schema design"
        completed: "2024-01-19T17:00:00Z"
        outcome: "success"
```

### decisions.yaml
```yaml
decisions:
  auth-strategy:
    id: "dec-001"
    date: "2024-01-15"
    type: "technical"
    decision: "Use JWT with refresh tokens"
    rationale:
      - "Stateless authentication"
      - "Better scalability"
      - "Industry standard"
    alternatives_considered:
      - "Session-based auth"
      - "OAuth only"
    decided_by: "planner"
    approved_by: "builder"
    
  database-choice:
    id: "dec-002"
    date: "2024-01-10"
    type: "infrastructure"
    decision: "PostgreSQL for main data, Redis for cache"
    # ... more details
```

## Cache Layer Schema

### tech-stack.yaml
```yaml
tech_stack:
  frontend:
    framework: "React 18"
    language: "TypeScript"
    styling: "Tailwind CSS"
    state: "Redux Toolkit"
    
  backend:
    language: "Python 3.11"
    framework: "FastAPI"
    orm: "SQLAlchemy"
    
  infrastructure:
    database: "PostgreSQL 15"
    cache: "Redis 7"
    queue: "RabbitMQ"
    
  auth:
    strategy: "JWT"
    library: "python-jose"
    provider: "Auth0 (optional)"
```

### patterns.yaml
```yaml
patterns:
  api_design:
    style: "RESTful"
    versioning: "URL path (/api/v1)"
    pagination: "cursor-based"
    error_format:
      example:
        error: "validation_error"
        message: "Invalid input"
        details: {}
        
  code_structure:
    backend: "Clean Architecture"
    frontend: "Feature-based"
    testing: "TDD required"
    
  naming_conventions:
    files: "snake_case"
    classes: "PascalCase"
    functions: "snake_case"
    constants: "UPPER_SNAKE_CASE"
```

## Memory Operations

### Read Operation
```python
def read_memory(path: str) -> Any:
    """
    Read from shared memory with caching.
    
    Args:
        path: Memory path (e.g., "active/tasks.yaml#/active/task-123")
    
    Returns:
        Requested data or None
    """
    # Check cache first
    if in_cache(path):
        return get_from_cache(path)
    
    # Load from disk
    data = load_yaml(path)
    
    # Update cache if frequently accessed
    if is_frequently_accessed(path):
        add_to_cache(path, data)
    
    return data
```

### Write Operation
```python
def write_memory(path: str, data: Any, sync: bool = True) -> bool:
    """
    Write to shared memory with optional sync.
    
    Args:
        path: Memory path
        data: Data to write
        sync: Whether to trigger sync
    
    Returns:
        Success status
    """
    # Validate data
    if not validate_schema(path, data):
        return False
    
    # Create backup
    backup_current(path)
    
    # Write data
    success = save_yaml(path, data)
    
    # Trigger sync if requested
    if success and sync:
        trigger_sync(path, "write")
    
    return success
```

### Update Operation
```python
def update_memory(path: str, updates: Dict, merge: bool = True) -> bool:
    """
    Update specific fields in memory.
    
    Args:
        path: Memory path
        updates: Dictionary of updates
        merge: Whether to merge or replace
    
    Returns:
        Success status
    """
    # Lock for update
    with memory_lock(path):
        current = read_memory(path)
        
        if merge:
            updated = deep_merge(current, updates)
        else:
            updated = updates
        
        return write_memory(path, updated)
```

## Access Patterns

### Planner Access Pattern
```yaml
planner_access:
  frequent_reads:
    - "active/tasks.yaml"
    - "active/blockers.yaml"
    - "cache/constraints.yaml"
    
  frequent_writes:
    - "active/tasks.yaml#/queued"
    - "active/decisions.yaml"
    
  batch_operations:
    - Read all active tasks
    - Update multiple task priorities
    - Archive completed decisions
```

### Builder Access Pattern
```yaml
builder_access:
  frequent_reads:
    - "active/tasks.yaml#/active"
    - "cache/tech-stack.yaml"
    - "cache/patterns.yaml"
    
  frequent_writes:
    - "active/tasks.yaml#/active/*/progress"
    - "active/blockers.yaml"
    
  batch_operations:
    - Update task progress
    - Read all patterns
    - Check dependencies
```

## Memory Management

### Archival Rules
```yaml
archival:
  triggers:
    - condition: "task_completed"
      action: "move_to_history"
      delay: "7_days"
      
    - condition: "decision_age > 30_days"
      action: "compress_and_archive"
      
    - condition: "memory_size > 10MB"
      action: "archive_old_data"
      
  compression:
    algorithm: "gzip"
    level: 6
    
  retention:
    active: "90_days"
    archived: "1_year"
    compressed: "indefinite"
```

### Garbage Collection
```yaml
garbage_collection:
  schedule: "daily_02:00"
  
  operations:
    - Remove temporary files older than 7 days
    - Compress historical data
    - Clean orphaned references
    - Defragment memory structure
    
  thresholds:
    max_active_size: "50MB"
    max_cache_size: "20MB"
    max_temp_size: "100MB"
```

## Performance Optimization

### Caching Strategy
- **Hot Data**: Keep in memory (Redis)
- **Warm Data**: File system with quick access
- **Cold Data**: Compressed archives

### Index Structure
```yaml
indexes:
  task_by_status:
    in_progress: ["task-123", "task-125"]
    queued: ["task-124", "task-126"]
    blocked: ["task-127"]
    
  task_by_owner:
    planner: ["task-124", "task-126"]
    builder: ["task-123", "task-125", "task-127"]
    
  decisions_by_type:
    technical: ["dec-001", "dec-003"]
    infrastructure: ["dec-002"]
    business: ["dec-004"]
```

## Security & Integrity

### Access Control
```yaml
access_control:
  read_permissions:
    - path: "/**"
      agents: ["planner", "builder"]
      
  write_permissions:
    - path: "/active/tasks/*/owner:planner"
      agents: ["planner"]
      
    - path: "/active/tasks/*/owner:builder"
      agents: ["builder"]
      
    - path: "/cache/**"
      agents: ["planner"]  # Only planner updates cache
```

### Data Integrity
```yaml
integrity:
  checksums:
    enabled: true
    algorithm: "sha256"
    
  validation:
    schema_checking: true
    reference_validation: true
    
  backups:
    frequency: "hourly"
    retention: "7_days"
    location: ".claude/backups/"
```

## Usage Examples

### Reading Task Status
```python
# Get specific task
task = read_memory("active/tasks.yaml#/active/task-123")

# Get all active tasks
active_tasks = read_memory("active/tasks.yaml#/active")
```

### Updating Progress
```python
# Update single field
update_memory(
    "active/tasks.yaml#/active/task-123/progress",
    75,
    merge=False
)

# Update multiple fields
update_memory(
    "active/tasks.yaml#/active/task-123",
    {
        "progress": 100,
        "status": "completed",
        "completed": datetime.now().isoformat()
    }
)
```

### Creating New Decision
```python
new_decision = {
    "id": "dec-005",
    "date": datetime.now().date().isoformat(),
    "type": "technical",
    "decision": "Use Docker for containerization",
    "rationale": ["Consistency across environments", "Easy deployment"],
    "decided_by": "planner"
}

write_memory(
    f"active/decisions.yaml#/decisions/containerization",
    new_decision
)
```