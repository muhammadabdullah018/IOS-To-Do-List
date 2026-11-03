# Skyday architecture

## Layers
```
┌────────────────────────────── iOS app target: Skyday ─────────────────────────────┐
│ App/         SkydayApp ─ AppEnvironment (composition root) ─ AppRouter ─ RootView │
│ Features/    Today · Plan · Lists · ListDetail · Progress · TaskEditorSheet ·    │
│              ListEditorSheet · Settings                                          │
│ DesignSystem Theme (tokens) · Components · PixelArt (sprites, sky, burst)         │
│ Services/    NotificationService (+ NotificationDelegate) · WidgetBridge          │
└───────────────▲───────────────────────────────────────────────▲──────────────────┘
                │ intents / derived state                         │ snapshot file
┌───────────────┴──────────── Packages/SkydayKit (Foundation + Observation) ───────┐
│ Store/       SkydayStore  (@MainActor @Observable: the ONLY mutator; undo; commit) │
│ Engine/      RecurrenceEngine · StreakEngine · TaskQueries · ReminderPlanner ·    │
│              AchievementEngine     (pure, deterministic, clock-injected)          │
│ Domain/      DayKey · TimeOfDay · TaskItem · TaskList · Subtask · RecurrenceRule ·│
│              CompletionEvent · AppSettings · AppData                              │
│ Persistence/ DataPersisting · JSONFileStore · InMemoryStore                       │
│ Support/     SkydayClock · DeepLink · TaskDraft · WidgetSnapshot · identifiers    │
└──────────────────────────────────────────────────────────────────────────────────┘
┌──────────── Widget extension: SkydayWidget ────────────┐
│ reads App Group widget-snapshot.json → small + medium  │
└────────────────────────────────────────────────────────┘
```
SkydayKit has no Apple-only imports, so all business rules compile and are tested on Linux as well as macOS.

## Data flow for one tap
1. User taps a checkbox on Today → `TodayView.complete(task)`.
2. The row is kept visually "lingering" for 650 ms; `store.complete(id)` runs immediately.
3. The store validates (idempotent, stale-occurrence guard), appends a `CompletionEvent`, advances recurring tasks, takes an undo snapshot, **saves atomically**, then calls `onCommit`.
4. `AppEnvironment.didCommit` → `NotificationService.scheduleSync` (debounced 300 ms, diff-based) and `WidgetBridge.publish` (snapshot + `reloadTimelines`).
5. SwiftUI re-renders from `@Observable` state; the undo toast appears from `store.pendingUndo`.

## Key decisions

### Floating days
Due dates are `DayKey` (y-m-d) plus an optional `TimeOfDay`, the same model Apple Reminders uses for all-day items. A task due "Tuesday 4 PM" stays that way across time zones. Day arithmetic uses a proleptic-Gregorian ordinal (pure integers), so DST transitions can't shift days. Instants are computed only at the edges: reminders and "overdue by time".

### One record per recurring series
`recurrenceAnchor` = series start, `dueDay` = current occurrence. Completing records `CompletionEvent(occurrenceDay:)` and advances to the next calendar occurrence. Occurrences are never stored as rows, so relaunching can't create duplicates, and planning views *project* future occurrences read-only. Missed occurrences roll forward to the latest occurrence ≤ today (skipped, not counted). Edits apply to the whole series (no per-occurrence overrides in v1).

### Streaks from history
Streaks, weekly charts, the activity grid and badges are recomputed from `CompletionEvent`s each time. Never from task state, never from an incrementing counter. Each event stores its `creditedDay`, fixed at completion time. Full policy: `.claude/skills/streak-gamification/SKILL.md` and Settings → How streaks work.

### Persistence: JSON document, not SwiftData (v1)
The starter kit preferred SwiftData. I chose a versioned Codable document behind `DataPersisting` because it was fully testable in the authoring environment (no Apple SDK there), avoids cross-process store access from the widget, and is ample for one person's tasks. Guarantees: atomic writes, unreadable files quarantined (never overwritten), newer-schema files opened read-only, tolerant decoding, orphan repair, undoable import. Swapping to SwiftData/CloudKit later means implementing `DataPersisting`; engines and views don't change. Revisit at ~5 MB of data, saves above ~30 ms on device, or approved iCloud sync.

### Reminders: plan, then diff
`ReminderPlanner.plan` is a pure function from data + now → desired requests with stable IDs, sorted and capped at iOS's 64 pending limit. `diff` compares against pending requests (ID + content fingerprint in `userInfo`) and touches only `skyday.*` IDs. The same data always yields the same requests, so syncing is idempotent. Permission is asked in context (first reminder or digest).

### Navigation
`AppRouter`: `tab` (Today/Lists/Progress), `todayPath` ([`TodayRoute.plan(day)`]), `listsPath` ([`ListsRoute.list(id)`]), `sheet` (`SheetRoute`: newTask, task, newList, editList, settings). Deep links (`skyday://today|new|lists|progress|task/<uuid>`) and notification taps route through `router.handle`.

### Widget
Precomputed `WidgetSnapshot` (today + tomorrow views, streak, goal) written to the App Group on every commit; the timeline has a midnight entry that switches to "tomorrow". No App Intents check-off in v1, because that would make the widget a second writer of the main store.

## Project & tooling
- `Skyday.xcodeproj` is **generated** by `Tools/generate_xcodeproj.py` (Xcode 16 synchronized folders; app, widget extension, UI tests; local package). `Tools/validate_xcodeproj.swift` checks it structurally.
- `Tools/LinuxTypecheck` type-checks the app and widget against SDK-shaped stubs on Linux. It's useful but approximate; Xcode is the authority.
- `Tools/make_app_icon.py` regenerates the original pixel icon.

## Known trade-offs
- Saves are synchronous on the main actor (whole document). Fine for hundreds to low thousands of tasks; measure on device before scaling.
- Undo is single-level (most recent undoable action), matching the toast UX.
- Digest counts reflect data at the last sync; they can't react to changes made on another device (no sync in v1).
