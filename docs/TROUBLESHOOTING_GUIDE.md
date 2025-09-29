# Phase 2 Troubleshooting Guide

🌐 **English** | **[日本語](TROUBLESHOOTING_GUIDE_ja.md)**

## Overview

This guide provides practical troubleshooting steps for common issues with Phase 2 Enhanced Capabilities. Use this guide when experiencing problems with Memory Bank, Parallel Execution, TDD Enforcement, or Monitoring features.

## Quick Diagnostic Steps

### 1. Initial System Check
```bash
# Check if Phase 2 is properly configured
ls -la .claude/settings-phase2.json

# Verify hook system is active
grep -q "hooks" .claude/settings.json 2>/dev/null && echo "Hooks configured" || echo "No hooks found"

# Check for recent errors
tail -20 .claude/logs/hooks.log 2>/dev/null || echo "No hook logs found"
```

### 2. Component Status Check
```bash
# Memory Bank status
ls -la .claude/planner/notes.md .claude/builder/notes.md 2>/dev/null

# Parallel execution status
ls -la .claude/parallel/queue/ 2>/dev/null && echo "Parallel system ready" || echo "Parallel system not initialized"

# TDD system status
find . -name "*.test.*" -o -name "*_test.*" | head -5

# Monitoring status
ls -la .claude/logs/metrics.txt 2>/dev/null && echo "Monitoring active" || echo "No metrics found"
```

## Common Issues by Feature

### Memory Bank Issues

#### Issue: Notes files not rotating automatically
**Symptoms:**
- Files exceed 1000 lines but no rotation occurs
- No archive files created
- Memory usage continues growing

**Quick Fix:**
```bash
# Check file line count
wc -l .claude/planner/notes.md .claude/builder/notes.md

# Manual rotation test
bash .claude/hooks/memory/notes-rotator.sh .claude/planner/notes.md planner

# Check permissions
ls -la .claude/hooks/memory/
chmod +x .claude/hooks/memory/notes-rotator.sh
```

**Root Causes & Solutions:**
1. **Missing execution permissions**
   ```bash
   chmod +x .claude/hooks/memory/*.sh
   ```

2. **Configuration issue**
   ```bash
   # Check threshold setting
   jq '.phase2.memory_bank.max_lines_per_file' .claude/settings-phase2.json
   ```

3. **Archive directory permissions**
   ```bash
   mkdir -p memo/archive
   chmod 755 memo/archive
   ```

#### Issue: Importance analysis not working
**Symptoms:**
- All content scored as low importance
- No categorization happening
- Archives lack summaries

**Quick Fix:**
```bash
# Test importance analysis
source .claude/hooks/memory/lib/analysis.sh
analyze_content_importance .claude/planner/notes.md
```

**Solutions:**
1. **Missing analysis library**
   ```bash
   ls -la .claude/hooks/memory/lib/analysis.sh
   # If missing, copy from template
   ```

2. **Configuration mismatch**
   ```bash
   # Check importance threshold
   jq '.phase2.memory_bank.importance_threshold' .claude/settings-phase2.json
   # Should be 7 or lower for most content
   ```

### Parallel Execution Issues

#### Issue: Tasks not executing in parallel
**Symptoms:**
- All tasks run sequentially
- Queue builds up without processing
- High response times

**Quick Fix:**
```bash
# Check queue status
ls -la .claude/parallel/queue/ 2>/dev/null

# Check for stale semaphores
ls -la /tmp/sem_parallel_exec_* 2>/dev/null

# Clean up stale locks
rm -f /tmp/sem_parallel_exec_*
```

**Root Causes & Solutions:**
1. **Semaphore conflicts**
   ```bash
   # Kill competing processes
   pkill -f "parallel-executor"

   # Remove stale semaphores
   rm -f /tmp/sem_parallel_exec_*

   # Restart parallel system
   bash .claude/hooks/parallel/parallel-executor.sh 4
   ```

2. **Queue directory missing**
   ```bash
   mkdir -p .claude/parallel/queue
   chmod 755 .claude/parallel/queue
   ```

3. **Worker configuration**
   ```bash
   # Check max workers setting
   jq '.phase2.parallel_execution.max_workers' .claude/settings-phase2.json
   # Should be 2-8 depending on system
   ```

#### Issue: Tasks timing out
**Symptoms:**
- Tasks fail with timeout errors
- System appears hung
- Partial task completion

**Quick Fix:**
```bash
# Check timeout configuration
jq '.phase2.parallel_execution.queue_management.timeout_per_task_seconds' .claude/settings-phase2.json

# Monitor active tasks
ps aux | grep -E "(test|lint|build)" | grep -v grep
```

**Solutions:**
1. **Increase timeout values**
   ```json
   {
     "queue_management": {
       "timeout_per_task_seconds": 600
     }
   }
   ```

2. **Optimize task complexity**
   - Break large tasks into smaller units
   - Use incremental processing
   - Add progress indicators

### TDD Enforcement Issues

#### Issue: Test files not detected
**Symptoms:**
- TDD warnings for files with existing tests
- False positive violations
- Incorrect test coverage reports

**Quick Fix:**
```bash
# Debug test detection
TDD_DEBUG=1 bash .claude/hooks/tdd/tdd-checker.sh src/example.js

# Check test patterns
find . -name "*test*" -type f | head -10
find . -name "*spec*" -type f | head -10
```

**Root Causes & Solutions:**
1. **Incorrect test patterns**
   ```bash
   # Check patterns in TDD checker
   grep -A 10 "TEST_PATTERNS" .claude/hooks/tdd/tdd-checker.sh
   ```

2. **Test file naming conventions**
   ```bash
   # Standard patterns:
   # - tests/test_filename.py
   # - __tests__/filename.test.js
   # - spec/filename_spec.rb
   ```

3. **Configuration adjustment**
   ```json
   {
     "tdd_checks": {
       "enforcement_level": "recommended"
     }
   }
   ```

#### Issue: Design compliance failures
**Symptoms:**
- Valid implementations marked as non-compliant
- Missing design files cause errors
- Excessive compliance warnings

**Quick Fix:**
```bash
# Check for design files
find docs/ -name "*design*" -type f
find . -name "*.md" | grep -i design

# Test design compliance
bash .claude/hooks/tdd/tdd-checker.sh src/example.js docs/design.md
```

**Solutions:**
1. **Create design documents**
   ```bash
   mkdir -p docs/design
   touch docs/design/component-design.md
   ```

2. **Adjust compliance settings**
   ```json
   {
     "design_compliance": {
       "require_design_doc": false,
       "allowed_deviation_percentage": 20
     }
   }
   ```

### Monitoring Issues

#### Issue: No metrics being collected
**Symptoms:**
- Empty metrics files
- No performance data
- Missing alerts

**Quick Fix:**
```bash
# Check metrics file
ls -la .claude/logs/metrics.txt

# Test metrics collection
source .claude/hooks/monitoring/metrics-collector.sh
collect_metrics "test_hook" 1.5 "success"
tail -5 .claude/logs/metrics.txt
```

**Root Causes & Solutions:**
1. **Logs directory missing**
   ```bash
   mkdir -p .claude/logs
   chmod 755 .claude/logs
   ```

2. **Metrics collector not executable**
   ```bash
   chmod +x .claude/hooks/monitoring/*.sh
   ```

3. **Configuration missing**
   ```json
   {
     "monitoring": {
       "metrics_collection": {
         "enabled": true,
         "detailed_logging": true
       }
     }
   }
   ```

#### Issue: Alerts not triggering
**Symptoms:**
- No alert notifications despite errors
- Alert files empty
- Console alerts not appearing

**Quick Fix:**
```bash
# Test alert system
source .claude/hooks/monitoring/alert-system.sh
check_error_rate "test_component" 15

# Check alert configuration
jq '.phase2.monitoring.alerts' .claude/settings-phase2.json
```

**Solutions:**
1. **Enable alert channels**
   ```json
   {
     "alerts": {
       "enabled": true,
       "channels": ["console", "file"]
     }
   }
   ```

2. **Adjust alert thresholds**
   ```json
   {
     "thresholds": {
       "error_rate": {
         "warning": 0.10,
         "critical": 0.25
       }
     }
   }
   ```

## System-Wide Issues

### Configuration Problems

#### Issue: Settings not loading
**Symptoms:**
- Components use default values
- Configuration changes ignored
- Inconsistent behavior

**Diagnostic Steps:**
```bash
# Validate JSON syntax
jq '.' .claude/settings-phase2.json

# Check file permissions
ls -la .claude/settings-phase2.json

# Test configuration loading
DEBUG=1 source .claude/hooks/memory/notes-rotator.sh
```

**Solutions:**
1. **Fix JSON syntax errors**
   ```bash
   # Use jq to format and validate
   jq '.' .claude/settings-phase2.json > .claude/settings-phase2.json.formatted
   mv .claude/settings-phase2.json.formatted .claude/settings-phase2.json
   ```

2. **Correct file permissions**
   ```bash
   chmod 644 .claude/settings-phase2.json
   ```

3. **Recreate from template**
   ```bash
   cp .claude/settings-phase2.json .claude/settings-phase2.json.backup
   # Copy fresh template from docs/PHASE2_CONFIGURATION_GUIDE.md
   ```

### Performance Issues

#### Issue: Hooks running slowly
**Symptoms:**
- Long delays during file operations
- System responsiveness degraded
- High CPU/memory usage

**Diagnostic Steps:**
```bash
# Monitor resource usage
top -p $(pgrep -f "claude/hooks")

# Check for large files
find .claude/ -type f -size +10M

# Analyze log sizes
du -sh .claude/logs/
```

**Solutions:**
1. **Clean up large files**
   ```bash
   # Rotate large logs
   find .claude/logs/ -name "*.log" -size +50M -exec gzip {} \;

   # Clean old archives
   find memo/archive/ -name "*.md" -mtime +90 -delete
   ```

2. **Optimize configuration**
   ```json
   {
     "memory_bank": {
       "max_lines_per_file": 500
     },
     "parallel_execution": {
       "max_workers": 2
     }
   }
   ```

3. **Disable intensive features temporarily**
   ```json
   {
     "monitoring": {
       "real_time": {
         "enabled": false
       }
     }
   }
   ```

### Integration Issues

#### Issue: Hooks not triggering
**Symptoms:**
- No automatic processing
- Manual operations work fine
- Events not recognized

**Diagnostic Steps:**
```bash
# Check Claude Code hooks configuration
grep -A 20 -B 5 '"hooks"' .claude/settings.json

# Verify hook scripts exist
ls -la .claude/hooks/*/

# Test manual execution
bash .claude/hooks/memory/notes-rotator.sh --test
```

**Solutions:**
1. **Fix hooks configuration in settings.json**
   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": ".claude/hooks/monitoring/metrics-collector.sh"
             }
           ]
         }
       ]
     }
   }
   ```

2. **Ensure proper script locations**
   ```bash
   # Verify all hook scripts are in correct locations
   find .claude/hooks/ -name "*.sh" -type f
   ```

## Emergency Procedures

### System Recovery

#### When hooks cause system instability:
```bash
# 1. Disable all hooks immediately
mv .claude/settings.json .claude/settings.json.disabled

# 2. Kill any running hook processes
pkill -f "claude/hooks"

# 3. Clean up temporary files
rm -f /tmp/sem_parallel_exec_*
rm -f /tmp/claude_lock_*

# 4. Restore minimal configuration
cat > .claude/settings.json << 'EOF'
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  }
}
EOF
```

#### When data corruption occurs:
```bash
# 1. Stop all hook processes
pkill -f "claude/hooks"

# 2. Backup current state
tar -czf claude_backup_$(date +%Y%m%d_%H%M%S).tar.gz .claude/

# 3. Restore from known good backup
# (Restore your most recent backup)

# 4. Gradually re-enable features
# Start with basic configuration only
```

### Data Recovery

#### Recover lost notes:
```bash
# Check for automatic backups
ls -la memo/archive/

# Look for rotation backups
find .claude/ -name "*backup*" -o -name "*archive*"

# Check git history
git log --oneline --grep="notes" --since="1 week ago"
```

#### Recover corrupted metrics:
```bash
# Backup corrupted files
mv .claude/logs/metrics.txt .claude/logs/metrics.txt.corrupted

# Restart metrics collection
touch .claude/logs/metrics.txt
chmod 644 .claude/logs/metrics.txt

# Re-initialize monitoring
source .claude/hooks/monitoring/metrics-collector.sh
```

## Prevention Strategies

### Regular Maintenance

#### Weekly tasks (5 minutes):
```bash
# Check system health
.claude/scripts/health-check.sh 2>/dev/null || echo "No health check script"

# Review error logs
grep -i error .claude/logs/*.log | tail -10

# Clean up temporary files
find /tmp -name "claude_*" -mtime +7 -delete 2>/dev/null
```

#### Monthly tasks (15 minutes):
```bash
# Archive old logs
find .claude/logs/ -name "*.log" -mtime +30 -exec gzip {} \;

# Update configuration if needed
cp .claude/settings-phase2.json .claude/settings-phase2.json.backup

# Review and clean archives
du -sh memo/archive/
```

### Monitoring Setup

#### Set up basic monitoring:
```bash
# Create monitoring script
cat > .claude/scripts/daily-health-check.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=== Phase 2 Health Check - $(date) ==="

# Check configuration
if ! jq '.' .claude/settings-phase2.json >/dev/null 2>&1; then
    echo "❌ Configuration file has syntax errors"
    exit 1
fi

# Check file sizes
NOTES_SIZE=$(wc -l .claude/planner/notes.md 2>/dev/null | awk '{print $1}' || echo 0)
if [[ $NOTES_SIZE -gt 1200 ]]; then
    echo "⚠️  Notes file large: $NOTES_SIZE lines"
fi

# Check for errors
ERROR_COUNT=$(grep -c "ERROR" .claude/logs/*.log 2>/dev/null || echo 0)
if [[ $ERROR_COUNT -gt 5 ]]; then
    echo "⚠️  High error count: $ERROR_COUNT errors"
fi

echo "✅ Health check completed"
EOF

chmod +x .claude/scripts/daily-health-check.sh
```

### Best Practices

1. **Regular Backups**
   ```bash
   # Weekly backup script
   tar -czf "phase2_backup_$(date +%Y%m%d).tar.gz" .claude/ memo/
   ```

2. **Gradual Changes**
   - Test configuration changes in development first
   - Make one change at a time
   - Keep backup of working configuration

3. **Documentation**
   - Document any custom configurations
   - Keep notes on performance impacts
   - Record resolution steps for team issues

4. **Monitoring**
   - Set up simple alerting for critical errors
   - Monitor disk space for logs and archives
   - Track performance trends over time

## Getting Help

### Before Asking for Help

1. **Gather Information**
   ```bash
   # System information
   echo "OS: $(uname -a)"
   echo "Bash: $BASH_VERSION"
   echo "Working directory: $(pwd)"

   # Configuration status
   echo "=== Configuration ==="
   jq -C '.' .claude/settings-phase2.json 2>/dev/null || echo "No configuration file"

   # Recent errors
   echo "=== Recent Errors ==="
   grep -i error .claude/logs/*.log 2>/dev/null | tail -5 || echo "No error logs"
   ```

2. **Try These Steps**
   - Check this troubleshooting guide
   - Review the [Configuration Guide](PHASE2_CONFIGURATION_GUIDE.md)
   - Check the [Hook Specification](HOOK_SPECIFICATION.md) for technical details

3. **Document Your Issue**
   - What were you trying to do?
   - What happened instead?
   - What error messages did you see?
   - What steps have you already tried?

### Support Resources

- **Configuration Guide**: [PHASE2_CONFIGURATION_GUIDE.md](PHASE2_CONFIGURATION_GUIDE.md)
- **Technical Specification**: [HOOK_SPECIFICATION.md](HOOK_SPECIFICATION.md)
- **Test Scripts**: `.claude/tests/` directory
- **Example Configurations**: Available in configuration guide

---

*Remember: Most issues can be resolved by checking configuration syntax, file permissions, and ensuring proper directory structure. When in doubt, start with the Quick Diagnostic Steps at the top of this guide.*

---

*Last Updated: 2025-09-17*
*Version: 2.5.3*
