# Handover Lifecycle Management Guide

## Overview
The `handover-lifecycle.sh` script manages the complete lifecycle of handover files in the Claude Friends system, including archival, cleanup, restoration, and status monitoring.

## Version 2.0.0 New Features

### 1. Restore Command
Recover archived files back to their original JSON format.

**Usage:**
```bash
handover-lifecycle.sh restore <archive-file> [target-directory]
```

**Examples:**
```bash
# Restore to default location (.claude/)
handover-lifecycle.sh restore .claude/archive/handover/2025-09/handover-20250901.json.gz

# Restore to specific directory
handover-lifecycle.sh restore archive.json.gz /custom/path

# Quiet mode (for scripts)
handover-lifecycle.sh restore archive.json.gz --quiet
```

**Features:**
- JSON integrity validation before and after decompression
- Automatic corruption detection
- Disk space verification
- Prevents overwriting existing files

### 2. Configuration File Support
Define retention and compression settings in `.claude/lifecycle-config.json`.

**Configuration Format:**
```json
{
  "retention": {
    "active_days": 7,
    "archive_days": 30,
    "min_retention_days": 3
  },
  "archive": {
    "compression": "gzip",
    "compression_level": 6
  }
}
```

**Priority Order:**
1. Environment variables (highest)
2. Configuration file
3. Default values (lowest)

**Setup:**
```bash
# Copy example config
cp .claude/lifecycle-config.json.example .claude/lifecycle-config.json

# Edit as needed
vim .claude/lifecycle-config.json
```

### 3. Enhanced Status Command
View detailed statistics including disk usage and compression ratios.

**Usage:**
```bash
handover-lifecycle.sh status
```

**Output Example:**
```
=== Handover Lifecycle Status ===

Active handover files: 4
Active files disk usage: 12.45KB
Age range: 1-6 days

Age distribution:
  handover-20250930.json: 0 days old (3.21KB)
  handover-20250929.json: 1 days old (2.98KB)
  handover-20250925.json: 5 days old (3.15KB)
  handover-20250924.json: 6 days old (3.11KB)

Archived files: 8
Archive disk usage: 4.32KB
Oldest archive: 25 days
Estimated compression ratio: 65.30%
Total disk usage: 16.77KB

Configuration:
  Retention period: 7 days
  Archive retention: 30 days
  Minimum retention: 3 days
  Compression level: 6
  Config file: .claude/lifecycle-config.json
```

**New Metrics:**
- Per-file disk usage
- Total disk usage for active and archived files
- Compression ratio estimation
- Age range (oldest/newest files)
- Compression level display

### 4. Quiet Mode for Cron Jobs
Suppress normal output, only show errors.

**Usage:**
```bash
handover-lifecycle.sh archive --quiet --no-dry-run
handover-lifecycle.sh cleanup --quiet --no-dry-run
```

**Crontab Example:**
```cron
# Daily archive at 2 AM
0 2 * * * cd /path/to/project && .claude/scripts/handover-lifecycle.sh archive --quiet --no-dry-run

# Weekly cleanup on Sunday at 3 AM
0 3 * * 0 cd /path/to/project && .claude/scripts/handover-lifecycle.sh cleanup --quiet --no-dry-run
```

### 5. Improved Error Handling

**New Validation Functions:**
- `validate_json_file()` - Ensures JSON integrity before/after operations
- `validate_disk_space()` - Checks available disk space (10MB minimum)
- `validate_permissions()` - Verifies write permissions

**Error Recovery:**
- Failed compressions are cleaned up automatically
- Corrupted archives are detected and rejected
- JSON validation prevents restoring invalid data

### 6. Better Code Organization

**Function Categories:**
- **Utility Functions**: Common helpers (logging, file age, size formatting)
- **Validation Functions**: Pre-flight checks
- **Archive Functions**: File archival operations
- **Cleanup Functions**: Old archive deletion
- **Restore Functions**: Archive restoration
- **Status Functions**: Statistics and reporting

**Improvements:**
- Clear function decomposition (single responsibility)
- Consistent error handling patterns
- Portable Bash (works without jq)
- Comprehensive inline documentation

## Command Reference

### archive
Archive old handover files.

**Options:**
- `--dry-run` (default) - Preview actions
- `--no-dry-run` - Execute archival
- `--force` - Skip minimum retention check
- `--quiet` - Silent mode

**Process:**
1. Validates JSON integrity
2. Checks retention period (default: 7 days)
3. Compresses with gzip (level 6)
4. Verifies compressed file
5. Removes original
6. Logs operation

### cleanup
Delete old archived files.

**Options:**
- `--dry-run` (default) - Preview actions
- `--no-dry-run` - Execute cleanup
- `--quiet` - Silent mode

**Process:**
1. Finds archives older than archive retention (default: 30 days)
2. Deletes old archives
3. Logs operation

### restore
Restore archived file to JSON format.

**Arguments:**
- `<archive-file>` - Path to .json.gz file (required)
- `[target-directory]` - Destination directory (optional, default: .claude/)

**Options:**
- `--quiet` - Silent mode

**Process:**
1. Validates archive exists and has correct extension
2. Checks target directory permissions
3. Verifies sufficient disk space
4. Tests archive integrity
5. Decompresses to target
6. Validates restored JSON
7. Logs operation

### status
Display lifecycle statistics.

**Output:**
- Active file count and disk usage
- File age distribution
- Archive count and disk usage
- Compression ratio estimation
- Configuration settings

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_PROJECT_DIR` | `pwd` | Project root directory |
| `HANDOVER_RETENTION_DAYS` | 7 | Days before archival |
| `HANDOVER_ARCHIVE_DAYS` | 30 | Days before deletion |
| `HANDOVER_MIN_RETENTION_DAYS` | 3 | Minimum safety retention |
| `DEBUG` | 0 | Enable debug output (1=on) |

## Configuration Precedence

1. **Environment Variables** (Highest Priority)
   ```bash
   export HANDOVER_RETENTION_DAYS=14
   ```

2. **Configuration File**
   ```json
   {
     "retention": {
       "active_days": 10
     }
   }
   ```

3. **Default Values** (Lowest Priority)
   - Retention: 7 days
   - Archive: 30 days
   - Min retention: 3 days
   - Compression: level 6

## Performance Considerations

### Compression Levels
- **Level 1-3**: Fast compression, larger files
- **Level 6** (default): Balanced performance and size
- **Level 9**: Maximum compression, slower

**Recommendation:** Keep default level 6 unless you have specific needs.

### Status Command Performance
- Optimized for <100ms execution
- Efficient file size calculations
- Minimal disk I/O

## Best Practices

### Regular Maintenance
```bash
# Weekly status check
handover-lifecycle.sh status

# Monthly cleanup
handover-lifecycle.sh cleanup --no-dry-run
```

### Backup Before Operations
```bash
# Before major cleanup
tar czf handover-backup-$(date +%Y%m%d).tar.gz .claude/archive/
```

### Testing Restore
```bash
# Always test restore in dry-run first
handover-lifecycle.sh restore archive.json.gz /tmp/test
```

### Monitoring Disk Usage
```bash
# Check if archival is effective
handover-lifecycle.sh status | grep "disk usage"
```

## Troubleshooting

### "Invalid JSON in file"
**Cause:** Corrupted or malformed JSON
**Solution:** Manually inspect file, fix JSON syntax

### "Insufficient disk space"
**Cause:** Less than 10MB available
**Solution:** Free up disk space or change target directory

### "No write permission"
**Cause:** Directory not writable
**Solution:** Check permissions with `ls -la` and fix with `chmod`

### "Archive file is corrupted"
**Cause:** Damaged .gz file
**Solution:** Archive may be unrecoverable, restore from backup

### Compression ratio seems wrong
**Cause:** Estimation based on average active file size
**Solution:** This is normal, ratio is approximate

## Migration from Version 1.x

Version 2.0.0 is fully backward compatible. All existing features work identically.

**New features to adopt:**
1. Create configuration file for easier management
2. Use `--quiet` mode in cron jobs
3. Test `restore` command for disaster recovery
4. Monitor enhanced `status` output for disk usage

**No breaking changes** - all 10 existing tests pass without modification.

## Examples

### Daily Automated Archival
```bash
#!/bin/bash
# daily-handover-maintenance.sh

cd /path/to/project

# Archive old files
.claude/scripts/handover-lifecycle.sh archive --quiet --no-dry-run

# Log status
.claude/scripts/handover-lifecycle.sh status >> /var/log/handover-lifecycle.log
```

### Disaster Recovery
```bash
# List available archives
find .claude/archive/handover -name "*.json.gz" -type f

# Restore specific file
handover-lifecycle.sh restore .claude/archive/handover/2025-09/handover-20250915.json.gz

# Verify restored file
cat .claude/handover-20250915.json | jq .
```

### Custom Retention Policy
```bash
# Create custom config
cat > .claude/lifecycle-config.json <<EOF
{
  "retention": {
    "active_days": 14,
    "archive_days": 90,
    "min_retention_days": 7
  },
  "archive": {
    "compression_level": 9
  }
}
EOF

# Apply immediately
handover-lifecycle.sh status
```

## See Also

- Original documentation: `.claude/scripts/handover-lifecycle.sh` (header comments)
- Test suite: `.claude/tests/bats/test_handover_lifecycle.bats`
- Example config: `.claude/lifecycle-config.json.example`

---

**Version:** 2.0.0
**Last Updated:** 2025-09-30
**Maintainer:** Refactoring Specialist Agent
