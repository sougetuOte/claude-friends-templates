# Phase 2 Configuration Guide

🌐 **English** | **[日本語](PHASE2_CONFIGURATION_GUIDE_ja.md)**

## Overview

This guide explains how to configure the Phase 2 enhanced features implemented in Sprint 2.1-2.4. All configurations are managed through the centralized `settings-phase2.json` file.

## Table of Contents

- [Quick Start](#quick-start)
- [Memory Bank Configuration](#memory-bank-configuration)
- [Parallel Execution Settings](#parallel-execution-settings)
- [TDD Enforcement Configuration](#tdd-enforcement-configuration)
- [Monitoring & Alerts Setup](#monitoring--alerts-setup)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Copy the Phase 2 Configuration

```bash
# Navigate to your project root
cd your-project

# Copy the Phase 2 settings template
cp .claude/settings-phase2.json.template .claude/settings-phase2.json

# Or create from scratch
cat > .claude/settings-phase2.json << 'EOF'
{
  "phase2": {
    "memory_bank": {
      "max_lines": 1000,
      "importance_threshold": 7
    },
    "parallel": {
      "max_workers": 4,
      "timeout": 300
    },
    "tdd": {
      "enforcement": "strict"
    },
    "monitoring": {
      "alerts": {
        "enabled": true
      }
    }
  }
}
EOF
```

### 2. Verify Installation

```bash
# Check if all Phase 2 components are installed
bash .claude/scripts/verify-phase2.sh

# Expected output:
# ✅ Memory Bank: Installed
# ✅ Parallel Executor: Installed
# ✅ TDD Checker: Installed
# ✅ Monitoring System: Installed
```

## Memory Bank Configuration

### Basic Settings

```json
{
  "phase2": {
    "memory_bank": {
      "max_lines": 1000,              // Maximum lines before rotation
      "importance_threshold": 7,       // Minimum score for important content
      "rotation_threshold": 500,       // Lines to trigger rotation
      "summary_retention_days": 30,    // Days to keep summaries
      "archive": {
        "enabled": true,
        "retention_days": 90,
        "compression": true,
        "auto_categorize": true
      }
    }
  }
}
```

### Usage Example

```bash
# Manual rotation
bash .claude/hooks/memory/notes-rotator.sh .claude/planner/notes.md planner

# Check importance score
source .claude/hooks/memory/lib/analysis.sh
analyze_content_importance "path/to/file.md"
```

### Performance Tuning

- **Small Projects** (< 1000 lines/week): `max_lines: 500`
- **Medium Projects** (1000-5000 lines/week): `max_lines: 1000` (default)
- **Large Projects** (> 5000 lines/week): `max_lines: 2000`

## Parallel Execution Settings

### Basic Configuration

```json
{
  "phase2": {
    "parallel": {
      "max_workers": 4,               // Maximum concurrent workers
      "timeout": 300,                 // Global timeout in seconds
      "queue": {
        "max_size": 100,
        "priority_levels": 5,
        "persistence": true
      },
      "pool_configuration": {
        "test_runner": 2,             // Dedicated workers for tests
        "linter": 1,                  // Dedicated worker for linting
        "builder": 1                  // Dedicated worker for builds
      }
    }
  }
}
```

### Task Queue Management

```bash
# Add tasks to queue
source .claude/hooks/parallel/parallel-executor.sh
enqueue_task "npm test"
enqueue_task "npm run lint"
enqueue_task "npm run build"

# Execute with 3 workers
execute_parallel 3

# Execute with timeout
execute_parallel_with_timeout 60 3
```

### Performance Optimization

| CPU Cores | Recommended Workers | Queue Size |
|-----------|-------------------|------------|
| 2 | 2 | 50 |
| 4 | 4 | 100 |
| 8 | 6-8 | 200 |
| 16+ | 10-12 | 500 |

## TDD Enforcement Configuration

### Enforcement Levels

```json
{
  "phase2": {
    "tdd": {
      "enforcement": "strict",        // strict | recommended | off
      "design_compliance": true,
      "test_first_required": true,
      "skip_reason_required": true,
      "quality_gates": {
        "test_coverage": 80,          // Minimum coverage percentage
        "complexity": 10,             // Maximum cyclomatic complexity
        "max_function_length": 50    // Maximum lines per function
      }
    }
  }
}
```

### Enforcement Modes

| Mode | Test Required | Design Check | Skip Allowed |
|------|--------------|--------------|--------------|
| `strict` | Always | Always | With reason |
| `recommended` | Warning | Optional | Yes |
| `off` | No | No | Always |

### Usage Examples

```bash
# Run TDD check manually
source .claude/hooks/tdd/tdd-checker.sh
perform_tdd_check "src/feature.js"

# Check design compliance
check_design_compliance "src/feature.js" "docs/design.md"

# Skip with reason (strict mode)
export TDD_SKIP_REASON="Legacy code refactoring"
perform_tdd_check "src/legacy.js"
```

## Monitoring & Alerts Setup

### Basic Configuration

```json
{
  "phase2": {
    "monitoring": {
      "metrics": {
        "retention_days": 30,
        "collection_interval": 60,    // seconds
        "aggregation_interval": 300   // seconds
      },
      "thresholds": {
        "error_rate_warning": 5,      // percentage
        "error_rate_critical": 10,
        "response_time_warning": 500, // milliseconds
        "response_time_critical": 1000,
        "memory_bank_warning": 80,    // percentage of max_lines
        "memory_bank_critical": 90
      },
      "alerts": {
        "enabled": true,
        "channels": ["console", "file", "webhook"],
        "rate_limiting": {
          "enabled": true,
          "window": 300,               // seconds
          "max_alerts": 10
        }
      }
    }
  }
}
```

### Alert Channels

#### Console Alerts
```json
{
  "channels": ["console"],
  "console_config": {
    "color": true,
    "verbose": false
  }
}
```

#### File Alerts
```json
{
  "channels": ["file"],
  "file_config": {
    "path": ".claude/logs/alerts.log",
    "rotation": "daily",
    "max_size": "10MB"
  }
}
```

#### Webhook Alerts
```json
{
  "channels": ["webhook"],
  "webhook_config": {
    "url": "https://your-webhook-endpoint",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    }
  }
}
```

### Metrics Collection

```bash
# Collect metrics manually
source .claude/hooks/monitoring/metrics-collector.sh
collect_metrics "my-hook" 0.5 "success"

# Aggregate logs
aggregate_logs

# Check alerts
source .claude/hooks/monitoring/alert-system.sh
check_error_rate "my-hook" 10
check_response_time "my-hook" 1.0
```

## Advanced Configuration

### Feature Integration

```json
{
  "phase2": {
    "integration": {
      "event_bus": {
        "enabled": true,
        "async": true
      },
      "shared_resources": {
        "cache": {
          "size": "100MB",
          "ttl": 3600
        },
        "locks": {
          "timeout": 30
        }
      },
      "health_check": {
        "enabled": true,
        "interval": 60,
        "components": [
          "memory_bank",
          "parallel_executor",
          "tdd_checker",
          "monitoring"
        ]
      }
    }
  }
}
```

### Performance Optimization

```json
{
  "phase2": {
    "performance": {
      "lazy_loading": true,
      "resource_limits": {
        "memory": "2GB",
        "cpu": 80                    // percentage
      },
      "profiling": {
        "enabled": false,             // Enable for debugging
        "output": ".claude/profiles/"
      }
    }
  }
}
```

### Security Settings

```json
{
  "phase2": {
    "security": {
      "input_validation": "strict",
      "audit_logging": true,
      "audit_retention_days": 90,
      "access_control": {
        "enabled": false,            // For multi-user setups
        "default_role": "developer"
      }
    }
  }
}
```

## Troubleshooting

### Common Issues and Solutions

#### Memory Bank Not Rotating

**Symptom**: Files exceed max_lines but don't rotate

**Solution**:
```bash
# Check file permissions
ls -la .claude/hooks/memory/

# Verify configuration
grep max_lines .claude/settings-phase2.json

# Run manual rotation with debug
DEBUG=1 bash .claude/hooks/memory/notes-rotator.sh path/to/notes.md
```

#### Parallel Tasks Failing

**Symptom**: Tasks timeout or fail to execute

**Solution**:
```bash
# Check semaphore files
ls /tmp/sem_parallel_exec_*

# Clean up stale locks
rm -f /tmp/sem_parallel_exec_*

# Test with single worker
source .claude/hooks/parallel/parallel-executor.sh
execute_parallel 1
```

#### TDD Checks Not Running

**Symptom**: TDD checks are bypassed

**Solution**:
```bash
# Verify TDD configuration
grep enforcement .claude/settings-phase2.json

# Check TDD hook installation
ls -la .claude/hooks/tdd/

# Test TDD check manually
TDD_DEBUG=1 source .claude/hooks/tdd/tdd-checker.sh
perform_tdd_check "test-file.js"
```

#### Missing Metrics

**Symptom**: Metrics not being collected

**Solution**:
```bash
# Check metrics directory
ls -la .claude/logs/

# Verify metrics file
cat .claude/logs/metrics.txt

# Test metrics collection
source .claude/hooks/monitoring/metrics-collector.sh
collect_metrics "test" 1.0 "success"
cat .claude/logs/metrics.txt | tail -5
```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Global debug
export PHASE2_DEBUG=1

# Component-specific debug
export MEMORY_BANK_DEBUG=1
export PARALLEL_DEBUG=1
export TDD_DEBUG=1
export MONITORING_DEBUG=1
```

### Performance Monitoring

```bash
# Check hook execution times
grep "hook_execution_duration" .claude/logs/metrics.txt | \
  awk '{sum+=$2; count++} END {print "Average:", sum/count, "ms"}'

# Monitor resource usage
watch -n 1 'ps aux | grep -E "(parallel|rotator|checker|collector)" | grep -v grep'

# Check queue sizes
ls .claude/parallel/queue/ | wc -l
```

## Migration from Default Settings

If you have existing Claude Friends settings, merge them with Phase 2:

```bash
# Backup existing settings
cp .claude/settings.json .claude/settings.json.backup

# Merge configurations
jq -s '.[0] * .[1]' .claude/settings.json .claude/settings-phase2.json > .claude/settings-merged.json

# Review and activate
mv .claude/settings-merged.json .claude/settings.json
```

## Best Practices

1. **Start Conservative**: Begin with default settings and adjust based on needs
2. **Monitor Metrics**: Regularly check performance metrics and logs
3. **Incremental Changes**: Adjust one setting at a time and measure impact
4. **Document Changes**: Keep notes on configuration changes and their effects
5. **Regular Maintenance**: Clean up old logs and archives monthly

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs in `.claude/logs/`
3. Enable debug mode for detailed diagnostics
4. Consult the [Hook Specification Document](HOOK_SPECIFICATION.md)

---
*Last Updated: 2025-09-17*
*Version: 2.5.3*