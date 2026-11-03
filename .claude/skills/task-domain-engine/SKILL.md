---
name: task-domain-engine
description: Implement tasks, lists, subtasks, repeating schedules, completion events, streak rules, and domain tests.
---

# Task and streak logic
- Entities: TaskList, Task, Subtask, CompletionEvent, DailyGoalRecord, ReminderPreferences. Stable UUID keys.
- Default Inbox; custom lists, safe reassignment on list deletion; ordering and archived/completed behavior defined.
- Task title nonempty; due day optional; due time optional; priority optional; recurring rule explicit.
- Completion creates durable event. Undo reverses same event safely. No double completion credits.
- Streak uses number of qualifying local calendar days (default daily goal = 3 task completions). Changing future goal must not erase earned history.
- Persist day qualification status/snapshot; test midnight, DST and timezone changes, date changes, recurrence, skip days.
- Recurring task advancement idempotent: one next occurrence per completed instance.
- Core rules independent from Views, injected Clock/Calendar for tests.
Deliver: domain types, pure logic where possible, repository operations and unit tests.

---
## Relationship to the specialized skills (added 2026-11-03, original text above unchanged)
This original skill is kept for backward compatibility. For new work prefer **task-management-engine, streak-gamification**, which carries the same intent with project-specific procedures, file paths and validation steps. If the two ever disagree, the specialized skill wins (it reflects the code as built). See `.claude/SKILLS_INVENTORY.md`.
