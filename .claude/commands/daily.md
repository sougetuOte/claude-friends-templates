---
description: "Daily retrospective - 日次振り返り"
---

# Daily Update

Complete daily lightweight status updates within 3 minutes.

**Note**: This command is available in both English and Japanese contexts. Use natural language appropriate to your environment.

## Health Check Feature (Optional)

Check the following metrics weekly:
- **Code size**: `du -sh . | grep -v .git`
- **TODO/FIXME**: `grep -r "TODO\|FIXME" --include="*.{js,ts,py}" . | wc -l`
- **Technical debt**: Number of high priority items in `@.claude/context/debt.md`
- **Memory Bank status**: Check files exceeding 100 lines

## Execution Steps

1. **Update Current Status**
   - Update only the following sections in `@.claude/core/current.md`:
     - Progress on "Today/This week's work"
     - Results in "Time tracking"
     - New learnings in "This week's learnings" (if any)

2. **Prepare for Tomorrow**
   - Update "Today's 3 goals" in `@.claude/core/next.md` for tomorrow
   - If there are blockers, record them in the "Blockers" section

3. **Brief Reflection**
   - Tasks completed today (1-2 items)
   - Tomorrow's highest priority task (1 item)
   - Issues if any (up to 1)

## Template
```
## [Date] Daily Update
### Completed Today
- [Task 1]
- [Task 2]

### Tomorrow's Top Priority
- [Task name] - [Reason]

### Issues/Insights
- [Up to 1 if any]

### Time Results
- Actual work time: [hours]
- Efficiency: High/Medium/Low
```

## Information Not Requiring Updates
- Project overview
- Technology stack
- Long-term plans
- Detailed technical information

If you cannot complete within 3 minutes, narrow down the information.
Updates to non-critical information should be done weekly in batch.
