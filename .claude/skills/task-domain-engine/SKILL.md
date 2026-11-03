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
