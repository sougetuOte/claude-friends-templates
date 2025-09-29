# AI-Friendly Logger System

🌐 **English** | **[日本語](ai-logger-README_ja.md)**

This project implements an AI-optimized logging system incorporating the Vibe Logger concept.

## 🌟 Overview

**Vibe Logger Philosophy**:
> "In VibeCoding (AI-driven development), debugging quality depends on how much context you can provide to the LLM"

This system realizes the transition from traditional human-oriented logs to **structured logs optimized for AI analysis**.

## 🚀 Key Features

### 1. Structured JSON Log Format
```json
{
  "timestamp": "2025-01-10T08:30:00.123Z",
  "correlation_id": "unique-id",
  "operation": {
    "tool": "Edit",
    "type": "CODE_MODIFICATION",
    "command": "edit file.py",
    "exit_code": 0,
    "files": [
      {
        "path": "/path/to/file.py",
        "size": 1024,
        "extension": "py",
        "lines": 42
      }
    ]
  },
  "context": {
    "project": {
      "name": "project-name",
      "root": "/project/root",
      "git_branch": "main",
      "git_commit": "abc123"
    },
    "environment": {
      "user": "username",
      "hostname": "host",
      "pwd": "/current/dir",
      "shell": "/bin/bash"
    }
  },
  "ai_metadata": {
    "hint": "Code was modified. Check for syntax errors, logical issues, or improvements.",
    "human_note": "File editing operation",
    "debug_priority": "normal",
    "suggested_action": "Continue monitoring"
  }
}
```

### 2. AI-Oriented Metadata
- **ai_hint**: Hints for AI when analyzing logs
- **human_note**: Supplementary explanation by humans
- **debug_priority**: Debug priority (high/normal)
- **suggested_action**: Recommended next action

### 3. Rich Context Information
- Project information (name, root, Git branch, commit)
- Environment information (user, host, working directory)
- File information (path, size, extension, lines)

## 📦 Implementation Method

### Integration with Existing System

Add the following to current configuration file (`.claude/settings.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/ai-logger.sh"
          },
          {
            "type": "command",
            "command": ".claude/scripts/activity-logger.sh"
          }
        ]
      }
    ]
  }
}
```

This generates AI logs in parallel with the existing log system.

## 🔍 Log Analysis

### Basic Usage

```bash
# Display summary
.claude/scripts/analyze-ai-logs.py

# Detailed display in JSON format
.claude/scripts/analyze-ai-logs.py --format json

# Display errors only
.claude/scripts/analyze-ai-logs.py --errors-only
```

### Analysis Report Contents

1. **Summary Information**
   - Total operations
   - Error count
   - Breakdown by operation type
   - Time range

2. **Error Analysis**
   - Error patterns
   - AI hints
   - Recommended actions

3. **Pattern Detection**
   - Frequent operations
   - High error rate operations
   - File activity

4. **AI Insights**
   - High error rate warnings
   - Optimization suggestions for repeated operations

5. **Debug Hints**
   - Error context
   - AI-oriented instructions
   - Human notes

## 🎯 Benefits

### Improved Development Efficiency
- **Context-rich debugging**: AI quickly identifies root causes
- **Pattern recognition**: Discovery of repeated errors and inefficient operations
- **Preventive analysis**: Detection before problems grow

### Maximizing AI Support
- **Structured data**: Format easy for AI to understand
- **Explicit instructions**: human_note and ai_todo fields
- **Prioritization**: Address important issues first

### Coexistence with Existing System
- Traditional activity.log continues to be generated
- Gradual migration possible
- Maintains backward compatibility

## 📊 Use Cases

### Debug Session
```bash
# When errors occur
.claude/scripts/analyze-ai-logs.py --errors-only > debug_report.json

# Request AI analysis
"Please analyze this debug_report.json and suggest causes and solutions for errors"
```

### Performance Analysis
```bash
# Check overall activity patterns
.claude/scripts/analyze-ai-logs.py --format json | jq '.patterns'

# Identify frequently edited files
.claude/scripts/analyze-ai-logs.py --format json | jq '.patterns.file_activity'
```

### Periodic Review
```bash
# Generate weekly report
.claude/scripts/analyze-ai-logs.py > weekly_report.txt

# Request improvement suggestions from AI
"Based on this weekly_report.txt, please suggest improvements to the development process"
```

## 🔧 Customization

### Adding New Operation Types
Add to case statement in `ai-logger.sh`:
```bash
"NewTool")
    operation_type="NEW_OPERATION"
    ai_hint="New operation detected. Analyze purpose and impact."
    human_note="Custom tool operation"
    ;;
```

### Custom Metadata
Project-specific information can be added to log entries

## 📈 Future Extensions

1. **Real-time alerts**: Notifications when error rate exceeds threshold
2. **Visualization dashboard**: Graphical display of log data
3. **AI auto-analysis**: Periodic automatic report generation
4. **Multi-language support**: TypeScript implementation

## 🤝 Migration Strategy

1. **Phase 1**: Parallel operation with existing system (current)
2. **Phase 2**: Gradually increase AI log utilization
3. **Phase 3**: Complete migration (optional)

This AI log system realizes the Vibe Coding concept, enabling efficient development through AI collaboration.

## 📚 References & Acknowledgments

### Vibe Logger - Inspiration for This System
- **Project**: [Vibe Logger](https://github.com/fladdict/vibe-logger) by @fladdict
- **Article**: [Proposal for AI Agent Logging System "Vibe Logger"](https://note.com/fladdict/n/n5046f72bdadd)

### Key Concepts Adopted from Vibe Logger
1. **Structured log format**: JSON structure optimized for AI analysis
2. **Context-rich metadata**: Automatic collection of project, environment, and Git information
3. **AI hint mechanism**: Explicit debug hints, priorities, and recommended actions
4. **VibeCoding philosophy**: Transition from "guessing and checking" to "analysis and resolution"

This system is implemented based on Vibe Logger's innovative ideas in a form that is easy to integrate with existing Claude Code projects.
