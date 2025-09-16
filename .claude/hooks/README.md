# Claude Code Hooks System - Implementation

🌐 **English** | **[日本語](README_ja.md)**

This directory contains the core implementation of Claude Code hooks that provide automation, security, and quality assurance features for the claude-friends-templates system.

## 📁 Directory Structure

```
hooks/
├── common/                    # Shared utilities and libraries
│   ├── hook-common.sh        # Common functions and utilities
│   ├── json-utils.sh         # JSON parsing and manipulation
│   ├── hook-common.sh.orig   # Original backup (patch system)
│   └── hook-common.sh.rej    # Patch rejection file
├── agent/                    # Agent-specific hooks
│   └── agent-switch.sh       # Agent switching automation
└── handover/                 # Handover management hooks
    └── handover-gen.sh       # Handover document generation
```

## 🔧 Hook Components

### Common Utilities (`common/`)

#### `hook-common.sh`
**Purpose**: Core utility functions used across all hooks
**Functions**:
- `log_activity()`: Standardized logging function
- `get_timestamp()`: ISO 8601 timestamp generation
- `check_permissions()`: File permission validation
- `sanitize_input()`: Input sanitization for security
- `validate_json()`: JSON format validation

**Usage Example**:
```bash
#!/bin/bash
source .claude/hooks/common/hook-common.sh

# Log an activity
log_activity "INFO" "Hook executed successfully"

# Get current timestamp
timestamp=$(get_timestamp)
echo "Current time: $timestamp"
```

#### `json-utils.sh`
**Purpose**: JSON manipulation utilities for configuration and data handling
**Functions**:
- `parse_json()`: Extract values from JSON files
- `validate_json_file()`: Validate JSON file structure
- `merge_json()`: Merge JSON objects
- `format_json()`: Pretty-print JSON

**Usage Example**:
```bash
#!/bin/bash
source .claude/hooks/common/json-utils.sh

# Parse agent configuration
agent_name=$(parse_json ".claude/agents/active.json" ".current_agent")
echo "Current agent: $agent_name"
```

### Agent Hooks (`agent/`)

#### `agent-switch.sh`
**Purpose**: Handles agent switching automation and context preservation
**Functionality**:
- Validates agent switch requests
- Updates agent state in `active.json`
- Triggers handover generation
- Logs agent switch activities

**Hook Configuration**:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "/agent:(planner|builder|sync-specialist)",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/agent/agent-switch.sh"
          }
        ]
      }
    ]
  }
}
```

**Parameters**:
- `$1`: Command that triggered the hook
- `$2`: New agent name
- `$3`: Current working directory

**Example Usage**:
```bash
# Manually trigger agent switch
.claude/hooks/agent/agent-switch.sh "/agent:builder" "builder" "$(pwd)"
```

### Handover Hooks (`handover/`)

#### `handover-gen.sh`
**Purpose**: Generates comprehensive handover documents for agent transitions
**Functionality**:
- Captures current project state
- Documents recent changes and decisions
- Preserves TDD phase status
- Creates structured handover files

**Generated Handover Structure**:
```markdown
# Handover: [Previous Agent] → [New Agent]
Date: [ISO 8601 timestamp]
Project: [Project name]

## Current State
- **Phase**: [TDD phase]
- **Branch**: [Git branch]
- **Last Modified**: [File list]

## Context Summary
[Automatic summary of recent activities]

## Files Modified (Last 24h)
- path/to/file1.ext - [Change description]
- path/to/file2.ext - [Change description]

## Test Status
[Current test results and coverage]

## Next Actions
[Suggested next steps based on context]

## Debug Information
[Error contexts and debugging hints]
```

**Configuration Options**:
```bash
# Environment variables for customization
export HANDOVER_RETENTION_DAYS=7    # Keep handovers for 7 days
export HANDOVER_MAX_FILES=50        # Limit file list to 50 entries
export HANDOVER_INCLUDE_TESTS=true  # Include test status
```

## 🚀 Hook Implementation

### Security Features

All hooks implement security best practices:

1. **Input Validation**: All user inputs are sanitized
2. **Path Validation**: File paths are validated against directory traversal
3. **Permission Checks**: File permissions verified before operations
4. **Error Handling**: Graceful failure with detailed logging

### Performance Optimization

Hooks are optimized for minimal impact:

1. **Lazy Loading**: Utilities loaded only when needed
2. **Caching**: Repeated operations cached for efficiency
3. **Background Execution**: Non-critical operations run in background
4. **Resource Limits**: Memory and CPU usage constrained

### Error Handling

Robust error handling across all components:

```bash
# Example error handling pattern
if ! command_that_might_fail; then
    log_activity "ERROR" "Command failed: $?"
    # Attempt recovery
    if ! recovery_command; then
        log_activity "FATAL" "Recovery failed, aborting"
        exit 1
    fi
fi
```

## 🔧 Configuration

### Hook Registration

Hooks are registered in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/deny-check.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/common/hook-common.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "/agent:",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/agent/agent-switch.sh"
          }
        ]
      }
    ]
  }
}
```

### Environment Variables

| Variable | Purpose | Default | Example |
|----------|---------|---------|---------|
| `CLAUDE_HOOKS_DEBUG` | Enable debug logging | `false` | `true` |
| `CLAUDE_HOOKS_TIMEOUT` | Hook execution timeout | `30` | `60` |
| `CLAUDE_LOG_LEVEL` | Logging verbosity | `INFO` | `DEBUG` |
| `CLAUDE_HOOKS_DIR` | Hooks directory path | `.claude/hooks` | `/custom/path` |

## 🧪 Testing

### Unit Tests

Individual hook components can be tested:

```bash
# Test common utilities
.claude/tests/bats/test_hook_common.bats

# Test JSON utilities
.claude/tests/bats/test_json_utils.bats

# Test agent switch functionality
.claude/tests/bats/test_agent_switch.bats

# Test handover generation
.claude/tests/bats/test_handover_gen.bats
```

### Integration Tests

Full hook system testing:

```bash
# Test complete hook workflow
.claude/scripts/test-hooks.sh

# Test with specific scenarios
.claude/tests/e2e/test_e2e_phase1.bats
```

### Performance Tests

Hook performance monitoring:

```bash
# Benchmark hook execution times
.claude/tests/performance/benchmark-hooks.sh

# Monitor resource usage
.claude/tests/performance/comprehensive-performance-test.sh
```

## 🔍 Debugging

### Debug Mode

Enable debug mode for detailed logging:

```bash
export CLAUDE_HOOKS_DEBUG=true
export CLAUDE_LOG_LEVEL=DEBUG

# Run with debug output
.claude/hooks/agent/agent-switch.sh "/agent:planner" "planner" "$(pwd)"
```

### Log Files

Hook activities are logged to:

```
~/.claude/
├── hook-debug.log         # Debug information
├── hook-errors.log        # Error messages
├── agent-switch.log       # Agent switching activities
└── handover-gen.log       # Handover generation logs
```

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Permission denied | Hook execution fails | `chmod +x .claude/hooks/**/*.sh` |
| JSON parsing error | Invalid JSON format | Validate with `jq` or `validate_json()` |
| Agent switch timeout | Slow agent switching | Check `CLAUDE_HOOKS_TIMEOUT` setting |
| Missing dependencies | Hook components fail | Install required tools (jq, git, etc.) |

## 🛠️ Customization

### Adding New Hooks

1. **Create hook script** in appropriate subdirectory
2. **Register in settings.json** with appropriate matcher
3. **Add tests** in `.claude/tests/bats/`
4. **Update documentation** with usage examples

Example new hook:

```bash
#!/bin/bash
# .claude/hooks/quality/code-review.sh

source .claude/hooks/common/hook-common.sh

# Perform code review checks
log_activity "INFO" "Starting code review hook"

# Your custom logic here
if [ "$1" = "Write" ] || [ "$1" = "Edit" ]; then
    # Check code quality
    echo "Reviewing code quality..."
fi

log_activity "INFO" "Code review hook completed"
```

### Extending Common Utilities

Add new functions to `hook-common.sh`:

```bash
# New utility function
validate_file_extension() {
    local file="$1"
    local extension="${file##*.}"

    case "$extension" in
        py|js|ts|rs|go)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
```

### Custom Agent Hooks

Create specialized hooks for new agents:

```bash
# .claude/hooks/agent/custom-agent.sh
#!/bin/bash

source .claude/hooks/common/hook-common.sh

# Custom agent logic
handle_custom_agent_switch() {
    log_activity "INFO" "Switching to custom agent"
    # Custom implementation
}
```

## 📚 Best Practices

### Hook Development

1. **Use common utilities**: Leverage existing functions in `hook-common.sh`
2. **Error handling**: Always include comprehensive error handling
3. **Logging**: Use standardized logging functions
4. **Testing**: Write tests for new hook functionality
5. **Documentation**: Update this README for new hooks

### Performance Guidelines

1. **Minimize execution time**: Keep hooks lightweight
2. **Background processing**: Use background jobs for non-critical tasks
3. **Resource monitoring**: Monitor memory and CPU usage
4. **Caching**: Cache expensive operations when possible

### Security Considerations

1. **Input validation**: Always validate and sanitize inputs
2. **Path safety**: Prevent directory traversal attacks
3. **Permission checks**: Verify file permissions before operations
4. **Audit logging**: Log security-relevant activities

## 🔗 Integration Points

### With Scripts Directory

Hooks integrate with automation scripts:
- `scripts/ai-logger.sh`: Activity logging
- `scripts/auto-format.sh`: Code formatting
- `scripts/deny-check.sh`: Security validation

### With Agent System

Hooks support agent coordination:
- State synchronization between agents
- Handover document generation
- Context preservation across switches

### With Testing Framework

Hooks integrate with testing infrastructure:
- Automated test execution
- Quality gate enforcement
- TDD phase tracking

---

**Note**: This hooks system is designed to be extensible and maintainable. When adding new functionality, follow the established patterns and update both implementation and documentation.