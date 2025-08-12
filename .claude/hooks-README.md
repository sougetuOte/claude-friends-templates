# Claude Code Hooks System

🌐 **English** | **[日本語](hooks-README_ja.md)**

This project integrates Claude Code hooks to improve development efficiency.

## Implemented Hooks Features

### 1. Security Hooks (PreToolUse)
**Script**: `.claude/scripts/deny-check.sh`
- **Purpose**: Pre-execution check for dangerous Bash commands
- **Target**: Destructive commands like `rm -rf /`, `chmod 777`, `curl | sh`
- **Action**: Commands deemed dangerous are automatically blocked before execution

### 2. Auto-format Hooks (PostToolUse)
**Script**: `.claude/scripts/auto-format.sh`
- **Purpose**: Automatic code formatting after file edits
- **Target**: `.py`, `.js`, `.ts`, `.rs`, `.go`, `.json` files
- **Action**: 
  - Python: `ruff format` or `black`
  - JavaScript/TypeScript: `prettier`
  - Rust: `rustfmt`
  - Go: `gofmt`
  - JSON: `jq`

### 3. Activity Log Hooks (PostToolUse)
**Script**: `.claude/scripts/activity-logger.sh`
- **Purpose**: Automatic recording and tracking of development activities
- **Log files**: `~/.claude/activity.log`, `~/.claude/metrics.log`
- **Records**: 
  - Tool name and execution time
  - Edited files, sizes, and extensions
  - Operation type classification (CODE_EDIT, FILE_READ, COMMAND_EXEC, etc.)

### 4. AI-Friendly Logger V2 Hooks (PostToolUse)
**Script**: `.claude/scripts/ai-logger.sh`
- **Purpose**: Structured logging optimized for AI analysis (based on [Vibe Logger](https://github.com/fladdict/vibe-logger) concepts)
- **Log file**: `~/.claude/ai-activity.jsonl`
- **Features**:
  - JSONL format for efficient AI parsing
  - Rich context (project, environment, Git info)
  - AI metadata (debug hints, priority, suggested actions)
  - Correlation ID tracking
  - Error pattern analysis with `analyze-ai-logs.py`

### 5. Session Complete Hooks (Stop)
**Script**: `.claude/scripts/session-complete.sh`
- **Purpose**: Status summary at end of work session
- **Log file**: `~/.claude/session.log`
- **Records**:
  - Git status (changed files, branch info)
  - Session activity summary
  - Tool usage statistics

### 6. Notes Auto-Rotation Hooks (UserPromptSubmit)
**Script**: `.claude/scripts/notes-check-hook.sh`
- **Purpose**: Automatic rotation of notes.md files to prevent excessive growth
- **Trigger**: Executes on `/agent:planner` or `/agent:builder` commands
- **Action**:
  - Checks if notes.md exceeds 450 lines
  - Automatically rotates and archives if threshold is exceeded
  - Updates index files after rotation
  - Shows color-coded notifications

## Log File Structure

```
~/.claude/
├── activity.log           # Detailed activity log
├── metrics.log            # Operation type metrics
├── session.log            # Session summary
├── format.log             # Format execution log
├── security.log           # Security block log
└── ai-activity.jsonl      # AI-optimized structured logs (Vibe Logger format)
```

## Hooks Configuration (.claude/settings.json)

```json
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  },
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
            "command": ".claude/scripts/auto-format.sh"
          }
        ]
      },
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/activity-logger.sh"
          },
          {
            "type": "command",
            "command": ".claude/scripts/ai-logger.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/session-complete.sh"
          }
        ]
      }
    ]
  }
}
```

## Testing & Operations

### Hooks Test Execution
```bash
# Test all hooks features
.claude/scripts/test-hooks.sh

# Test security features only
.claude/scripts/test-security.sh
```

### Log Monitoring
```bash
# Monitor activity log
tail -f ~/.claude/activity.log

# View session history
cat ~/.claude/session.log

# Check security log
tail -f ~/.claude/security.log

# Monitor AI-optimized logs (real-time)
tail -f ~/.claude/ai-activity.jsonl

# Analyze AI logs with insights
.claude/scripts/analyze-ai-logs.py --format summary
```

### Troubleshooting

#### "Tool: unknown" is recorded in logs
Claude Code may not be correctly passing the `CLAUDE_TOOL_NAME` environment variable. This is related to Claude Code itself, and the logging feature is working normally. This may be improved in future updates.

#### Hooks not working
1. Check script permissions: `chmod +x .claude/scripts/*.sh`
2. Verify config file: Check `.claude/settings.json` syntax
3. Test execution: Identify errors with `.claude/scripts/test-hooks.sh`

#### Auto-format not working
1. Check formatter: Are `ruff`, `prettier`, `rustfmt` etc. installed?
2. Check file extension: Is it supported (.py, .js, .ts, .rs, .go, .json)?
3. Check logs: View error details in `~/.claude/format.log`

## Customization

### Adding new language formatting
Add to case statement in `auto-format.sh`:
```bash
*.new_ext)
    if command -v formatter >/dev/null 2>&1; then
        formatter "$file" && log_format "Formatted language: $file"
    fi
    ;;
```

### Adding security rules
Add to `DANGEROUS_PATTERNS` array in `deny-check.sh`:
```bash
"new dangerous pattern"
```

### Customizing activity logs
Add/modify tool classification in `activity-logger.sh`:
```bash
"NewToolName")
    echo "[$timestamp] CUSTOM_ACTION" >> "$METRICS_FILE"
    ;;
```

## Benefits & Effects

- **Automation**: Reduced manual work (formatting, logging, etc.)
- **Quality improvement**: Consistent code formatting, security checks
- **Visualization**: Automatic tracking of development activities and progress
- **Efficiency**: Automatic summary generation at work completion
- **Safety**: Pre-blocking of dangerous commands

This hooks system significantly improves development efficiency, quality, and safety when using Claude Code.