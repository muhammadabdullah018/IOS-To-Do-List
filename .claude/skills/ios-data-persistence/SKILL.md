---
name: ios-data-persistence
description: SwiftData offline-first storage, integrity, migrations and recoverability. Use on model or persistence changes.
---

# ios-data-persistence

Default to offline-first. Investigate project deployment target and SwiftData compatibility. Use stable IDs, explicit model relationships, sound deletion semantics and store completion history independently where needed.

Cover app termination, reinstall behavior, relaunch, migration, error handling, duplicate recurrence records and preview/in-memory stores. Data should survive app restarts; never rely on in-memory arrays for source-of-truth tasks.

No mandatory account, Firebase, Supabase or remote backend in MVP. Future iCloud sync is optional, a separate approved milestone and must not be claimed functional before tested.

Build small persistence adapters or testable repository interfaces where useful; avoid overengineering. Provide migration notes when changing schema.

Validate CRUD persistence, corrupt/failed saves behavior, app restart and large task counts. Be explicit that uninstall can delete local app data unless sync/backup covers it.
