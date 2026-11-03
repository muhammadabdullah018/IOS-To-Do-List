---
name: task-management-engine
description: Skyday task domain - tasks, lists, subtasks, priorities, due days and times, recurrence, Today/Upcoming/overdue queries, sorting, search, undo and completion history. Use when implementing or changing any task or list behaviour in SkydayKit or the views that call it.
---

# task-management-engine

## Purpose and scope
Correct, testable task behaviour. Code: `Packages/SkydayKit/Sources/SkydayKit/{Domain,Engine/RecurrenceEngine.swift,Engine/TaskQueries.swift,Store/SkydayStore.swift}`. Streak math is `streak-gamification`; reminders are `notification-reminder-engine`.

## Use when
Changing task/list fields, recurrence, completion/undo, queries (Today, agenda, coming up), sorting, search, reorder or list deletion.

## Do not use when
Pure visuals, or streak/goal rules.

## Invariants (enforced by tests in `StoreTests`, `RecurrenceTests`, `QueryAndSupportTests`)
1. **Dates are floating days.** `dueDay: DayKey` (+ optional `dueTime: TimeOfDay`). Day maths is integer ordinal maths, immune to DST. Instants are only computed at the edge (`DayKey.date(at:in:)`).
2. **Title required**: `TaskDraft.validationError` rejects whitespace-only; titles are trimmed and capped at 300 chars. Time, reminder and repeat require a date (`TaskDraft.normalized`).
3. **Inbox** always exists and can't be deleted. Deleting a list moves its tasks to Inbox (undoable). Orphaned tasks are repaired into Inbox on load.
4. **Recurrence = one record per series.** `recurrenceAnchor` is the series start; `dueDay` is the current occurrence. Completing writes a `CompletionEvent(occurrenceDay:)` and advances to `nextOccurrence(after:)`; subtasks reset. Occurrences are never stored as rows, so relaunches can't duplicate them.
5. **Missed occurrences roll forward** (`rolledForward`, idempotent) to the latest occurrence ≤ today; they are skipped, not counted.
6. **Calendar rules**: monthly on the 31st clamps per month without drifting (Jan 31 → Feb 28 → Mar 31); yearly Feb 29 → Feb 28 in non-leap years; weekly supports weekday sets and intervals (week phase by Monday weeks).
7. **Idempotent completion**: completing a completed task, or a stale `expectedOccurrence` from a notification action, is a no-op.
8. **Undo** restores the full pre-mutation snapshot of the most recent undoable mutation (complete, reopen, delete, move, list delete, import, erase).
9. **Reopen** (non-recurring) removes that task's completion events. **Delete** keeps events (history).
10. **Do-next order** (`TaskQueries.actionOrder`): overdue first (oldest first) → priority high→none → timed before untimed, by time → manual order → creation.
11. **Edits to a recurring task apply to the series** (there are no per-occurrence overrides in v1). Changing the rule or date resets the anchor to the new due day.

## Procedure
1. Write or extend a failing test in `Packages/SkydayKit/Tests` (use `StoreHarness`, `FixedClock`, `T.date/T.day`).
2. Implement in the engine/store, keeping views thin.
3. `swift test` must pass; then type-check the app (`Tools/LinuxTypecheck`) if store API changed.
4. Update `ARCHITECTURE.md` if an invariant changed.

## Common mistakes
- `addingTimeInterval(86400)` for "tomorrow" (DST bug). Use `DayKey.adding(days:)`.
- Materialising future recurring instances (duplicates, sync hell).
- Recomputing history from current task state instead of `CompletionEvent`s.
- Mutating `store.data` from a view.

## Validation
Required tests cover: CRUD persistence across relaunch, two lists + moves, sort orders, overdue by time, recurrence (daily interval, weekdays, biweekly, month-end, leap year, roll-forward, 10 relaunches without duplicates), undo, stale actions, 600 tasks.

## Output
Engine/store change + tests + note of any changed invariant.

## Related
`streak-gamification`, `notification-reminder-engine`, `ios-data-persistence`. Agents: **skyday-product-engineer** (owner), **skyday-ios-architect** (API shape). Legacy overlap: `task-domain-engine`.
