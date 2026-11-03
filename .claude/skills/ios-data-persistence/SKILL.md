---
name: ios-data-persistence
description: Skyday offline-first storage - the AppData document, JSONFileStore atomic writes, schema versioning and migration, corrupt-file quarantine, App Group location, backup import and export, and the future SwiftData or iCloud path. Use when changing models, adding fields, or touching load, save, backup or erase.
---

# ios-data-persistence

## Purpose and scope
Never lose user data. Code: `Persistence/JSONFileStore.swift`, `Domain/Models.swift` (`AppData`), `Store/SkydayStore.swift` (load, commit, import/export), `Skyday/App/AppEnvironment.swift` (`StorageLocation`).

## Decision record: JSON document instead of SwiftData (v1)
Chosen deliberately, against the starter kit's "SwiftData where compatible", because:
- **Verifiable**: the whole persistence layer compiles and is tested here on Linux (relaunch, corruption, schema, 600 tasks). SwiftData can only be tested on Apple platforms.
- **Widget safety**: the widget reads a separate precomputed `widget-snapshot.json`; it never opens the main store, so there's no cross-process contention.
- **Scale**: one user's tasks (thousands at most) fit comfortably in one document; history is append-only events.
- **Swap-ability**: everything goes through `DataPersisting`. A SwiftData or CloudKit backend can replace `JSONFileStore` without touching views or engines.
Revisit if: data exceeds ~5 MB, saves exceed ~30 ms on target devices, or iCloud sync is approved.

## Guarantees (tested in `StoreTests`)
1. Every mutation saves synchronously before returning (`Data.write(.atomic)`: temp file + rename).
2. Unreadable file → moved aside to `skyday-unreadable-<ts>.json`, user told, fresh start. The original is never overwritten.
3. File from a newer schema → read-only mode; saves blocked; user told to update.
4. Missing fields decode with defaults (`decodeIfPresent` in `TaskItem`, `AppSettings`, `AppData`).
5. Orphaned tasks are repaired into Inbox; a missing Inbox is recreated.
6. Save failure → `lastSaveError` banner on Today; the next successful save includes all changes.
7. Import validates fully before replacing (and is undoable). Export is pretty-printed, sorted-key JSON.

## Location
`StorageLocation.dataDirectory()`: App Group container (`group.com.skyday.app`) when provisioned, else Application Support. One-time copy if the group appears later. UI tests use a temp dir via `-uiTesting` (+ `-resetData`).

## Adding a field (migration procedure)
1. Add it as optional or with a default, and decode it with `decodeIfPresent` (no version bump needed).
2. For breaking changes, bump `AppData.currentSchemaVersion`, add a migration step in `JSONFileStore.decode` keyed on the old version, and add a fixture test that decodes an old document.
3. Never rename a JSON key without a migration.

## Common mistakes
- Holding source-of-truth state in a view or in memory only.
- Non-atomic writes.
- Deleting the corrupt file "to recover".
- Claiming uninstall keeps data (it doesn't without an exported backup).

## Validation
`swift test` (relaunch persistence, corruption, schema, legacy decode, import/export, save failure, 600 tasks). Device: kill the app mid-edit and relaunch; delete and reinstall (data gone, which is expected); App Group provisioning check that the widget shows data.

## Output
Model/persistence change + migration note + tests.

## Related
`swiftui-engineering`, `task-management-engine`, `ios-widgets-integration`. Agents: **skyday-ios-architect** (owner), **skyday-qa-reviewer**.
