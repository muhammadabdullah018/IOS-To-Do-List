---
name: task-management-engine
description: Tasks, custom lists, subtasks, priorities, recurrence and calendar logic. Use when implementing or modifying task behavior.
---

# task-management-engine

Define task entities with stable identifiers, title, details, list membership, priority, status, due date, optional reminder, creation/update timestamps and completion history. Define recurring series separately from occurrences when necessary.

Support add, edit, complete, reopen, delete, undo, reorder where appropriate, subtasks, and Today/Upcoming/Overdue filtering. Lists can be custom colored/icon-labeled groups. Clarify whether completing subtasks affects parent completion.

Recurrence must be anchored to calendar rules, not naive 24-hour addition. Check timezone and daylight saving transitions. Do not spawn duplicate occurrences when app relaunches. Edits to one occurrence vs future series must have defined behavior.

Completion history must survive edits and support streak calculations; avoid reconstructing historical truth solely from current task status.

Tests: add/edit/delete, due date boundaries, duplicate prevention, completion undo, subtask status, recurrence across month ends/timezones, empty state, many tasks.
