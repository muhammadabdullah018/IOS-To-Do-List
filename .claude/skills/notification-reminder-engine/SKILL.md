---
name: notification-reminder-engine
description: Reliable iOS local task reminders and notification permissions. Use for reminders, digest behavior and settings.
---

# notification-reminder-engine

Use UserNotifications with permission requested in context, after the user tries to enable a reminder. Support scheduled per-task reminders, cancellation on completion/deletion, reschedule on edits, recurring reminders and optional daily summaries.

Notification content should identify the task without disclosing unnecessary private details on lock screen if privacy settings require it. Respect platform limits, Focus modes, permission denial and app authorization states.

Do not promise continuous background checks or 'nag until done' when iOS background execution is restricted. For unfinished-task summaries, define a feasible local scheduling strategy, refresh when the app runs and clearly state any inherent limitations. Keep scheduling state consistent with persisted tasks.

Test notification request generation, rescheduling, cancellations, repeating rules, authorization denial, timezone changes and duplicate prevention. Report physical-device scenarios not tested.
