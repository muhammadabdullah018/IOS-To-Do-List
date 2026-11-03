# Feature matrix

Legend: DONE = implemented and verified by the evidence named. PARTIAL = implemented, verification incomplete. BLOCKED = needs something outside this environment.

| Feature | iOS status | iOS evidence | Web demo |
|---|---|---|---|
| 3 tabs only (Today, Lists, Progress) | DONE | UI test `testFirstLaunchShowsEmptyStateAndThreeTabs`, `testCalendarOpensFromToday` | yes |
| Today: greeting, date, streak chip, progress ring, Today list, Coming up | DONE | `02_today.png`, UI tests | yes |
| Task create / edit / delete / complete / reopen / undo | DONE | `StoreTests`, UI test `testQuickAddCompleteUndoAndPersistAcrossRelaunch` | yes (vitest + browser smoke) |
| Blank title rejected | DONE | UI test `testEmptyTitleCannotBeSaved` | yes |
| Subtasks | DONE | `StoreTests`; editor in `06_task_detail.png` | yes |
| Priority, due date, due time | DONE | `StoreTests`, `QueryAndSupportTests` | yes |
| Recurring tasks, no duplicates, month-end/leap/DST | DONE | `RecurrenceTests`, 10-relaunch no-duplicate test | daily/weekly/monthly |
| Lists CRUD, icons, colours, counts | DONE | UI test `testCreateListFromListsTab`, `03_lists.png` | yes |
| Search | DONE | `QueryAndSupportTests` | no |
| Calendar (secondary, from Today) | DONE | `07_calendar.png`, UI test | month grid |
| Progress: stats, weekly chart, goal, 5-week grid | DONE | `StreakTests`, `04_progress.png` | yes (no grid) |
| Streak & Achievements (from Progress) | DONE | UI test `testStreaksOpenFromProgress`, `08_streaks.png` | yes |
| Streak rules: goal, rest day, goal changes, time zones | DONE | `StreakTests` (17) | goal only |
| Reminders: schedule, cancel, 64 cap, Complete/Snooze | PARTIAL | `ReminderPlannerTests` (12); delivery not observed on device | not delivered |
| Notification privacy (no notes, hidden-preview placeholder) | PARTIAL | code review; not device-verified | n/a |
| Offline persistence across relaunch | DONE | UI test relaunch, `StoreTests` | localStorage, browser reload verified |
| Corrupt file quarantine / newer schema read-only | DONE | `StoreTests` | invalid storage resets to empty |
| Settings: goal, reminders, digests, export, import, erase | DONE (UI), PARTIAL (share sheet on device) | `09_settings.png`, `StoreTests` | yes |
| Empty state (island, tree, cat) | DONE | `10_empty_state.png` | yes |
| Widgets (small, medium, deep links) | PARTIAL | builds in Xcode; not observed on a Home Screen | no |
| Accessibility labels, Dynamic Type, Reduce Motion | PARTIAL | labels exercised by UI tests; no AX5/VoiceOver pass recorded | partial |
| Launch screen | DONE | `UILaunchScreen` in Info.plist; builds | n/a |
