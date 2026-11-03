---
name: notification-reliability
description: Implement trustworthy local iOS notification permissions, reminder scheduling, updates, and failure handling.
---

# Notification engineering
- Use UserNotifications UNUserNotificationCenter. Ask authorization only at meaningful first reminder action.
- Distinguish exact timed reminders from date-only scheduled reminders; ensure user sees selected defaults.
- Compute stable notification IDs from task/occurrence/type; idempotent replace on edit, cancel on delete/complete/reopen, reschedule recurrence.
- Keep scheduled requests bounded; iOS delivery is subject to system settings/focus and OS scheduling. Never claim persistent background monitoring.
- Morning/evening digest can be scheduled from known data but cannot guarantee always-fresh counts without app refresh; avoid incorrect count copy in static notifications.
- Denied permissions: save tasks without alarms and show direct Settings guidance.
- Test scheduled request contents, duplicate cancellation, timezone, due dates in past, permission failures.

---
## Relationship to the specialized skills (added 2026-11-03, original text above unchanged)
This original skill is kept for backward compatibility. For new work prefer **notification-reminder-engine**, which carries the same intent with project-specific procedures, file paths and validation steps. If the two ever disagree, the specialized skill wins (it reflects the code as built). See `.claude/SKILLS_INVENTORY.md`.
