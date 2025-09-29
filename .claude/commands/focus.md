---
description: "Focus on current task - 現在のタスクに集中"
---

# Focus Mode

To concentrate on the current task, display only the minimum necessary information.

**Note**: This command is available in both English and Japanese contexts. Use natural language appropriate to your environment.

## Execution Steps

1. **Load Core Information**
   - Load only the "3-line summary" section from `@.claude/core/current.md`
   - Load only the "Today's 3 goals" section from `@.claude/core/next.md`

2. **Current Task Analysis**
   - Narrow down to one ongoing task
   - Identify only technical information needed for that task
   - Do not load unnecessary background information

3. **Focused Work Suggestions**
   - Propose specific next steps for the identified task
   - Recommend 25-minute Pomodoro timer
   - Avoid mentioning other tasks

4. **Concise Response**
   - Keep responses within 3-5 sentences
   - Present only specific actions
   - Omit lengthy explanations or background information

## Focus Priority Order
1. 🔥 Urgent & Important (Respond immediately)
2. ⭐ Important & Not Urgent (Respond systematically)
3. Others are temporarily on hold

## Response Example
```
Current Focus: [Task name]
Next Action: [Specific work]
Time Estimate: [minutes]
Completion Criteria: [Clear criteria]
```

If detailed information is needed, explicitly request "detailed information needed".
