---
name: notification-reminder-engine
description: Skyday local notifications - contextual permission, per-task and recurring reminders, morning and evening digests, Complete and Snooze actions, diff-based rescheduling, the 64-request limit and denied-permission handling. Use for any change touching reminders, UNUserNotificationCenter or notification settings.
---

# notification-reminder-engine

## Purpose and scope
Reminders that fire when promised, never duplicate, and degrade gracefully. Planning is pure and tested (`Engine/ReminderPlanner.swift`); delivery is a thin adapter (`Skyday/Services/NotificationService.swift`).

## Use when
Changing reminder options, digest content, notification actions, permission UX, or when tasks gain fields that affect reminders.

## Do not use when
Pure task/streak logic with no reminder impact.

## How it works
1. **Plan** (pure): `ReminderPlanner.plan(data, now:, calendar:)` returns every request Skyday wants: task reminders (current occurrence + up to 3 future occurrences of recurring tasks within 7 days), snoozes, digests (next 7 days, only days with planned tasks). Sorted soonest first, capped at **64** (the iOS pending limit; extra requests would be dropped silently).
2. **Stable IDs**: `skyday.task.<uuid>.<yyyy-mm-dd>`, `skyday.snooze.<uuid>`, `skyday.morningDigest.<day>`, `skyday.eveningDigest.<day>`.
3. **Diff**: `ReminderPlanner.diff(pending:desired:)` compares IDs + a fingerprint (title|body|fire time) stored in `userInfo`. It removes stale or changed requests and adds new or changed ones. It never touches non-`skyday.` IDs.
4. **Sync triggers**: every store commit (debounced 300 ms), app launch, foreground, day change, time-zone change.
5. **Fire time**: timed task = due time − offset; date-only task = `settings.defaultReminderTime` on the due day. Calendar-component triggers keep wall-clock time (floating, like due days).
6. **Permission** is requested only when the user picks a reminder or enables a digest (`requestPermissionIfNeeded`). Denied: the task still saves; the editor shows "Notifications are off" with an Open Settings button; Settings shows status.
7. **Actions** (category `SKYDAY_TASK_REMINDER`): Complete (uses `expectedOccurrence`, so a stale action is a no-op) and Remind me in 1 hour (`snoozedUntil`). The default tap opens the task sheet.
8. Delivered reminders of completed or deleted tasks are removed from Notification Centre on sync.

## Limits we state honestly
- iOS decides delivery. Focus, Scheduled Summary and Low Power can delay or hide alerts.
- Skyday doesn't run in the background. Digests are computed from data at the last sync; since data only changes when the app (or a notification action) runs, counts are accurate unless the device clock or time zone changes while the app is closed.
- Nothing nags repeatedly. One reminder per occurrence, plus explicit snoozes.

## Procedure
1. Change the planner first, with tests in `ReminderPlannerTests`.
2. Keep `NotificationService` a dumb adapter (map → request, add/remove).
3. Verify IDs stay stable for unchanged inputs (re-plan twice → identical).

## Common mistakes
- `removeAllPendingNotificationRequests()` (would also wipe requests that didn't change).
- Asking permission at launch.
- Interval triggers for wall-clock reminders (they drift across DST and travel).
- Static digest text that claims counts the app can't know.

## Validation
Unit (Linux OK): offsets, date-only default, past/completed skipped, recurring horizon, DST wall clock, 64 cap, determinism, diff semantics, edit→replace, complete→cancel, snooze, digests skip empty days.
Device-only (record as Not run unless done): permission prompt timing, denied flow, actions from the lock screen while the app is killed, delivery under Focus, time-zone change while closed.

## Output
Planner change + tests + a device test checklist result.

## Related
`task-management-engine`, `ios-testing-performance`. Agents: **skyday-product-engineer** (owner), **skyday-qa-reviewer** (verification). Legacy overlap: `notification-reliability`.
