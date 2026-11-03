---
name: streak-gamification
description: Skyday streak and progress rules - daily goal, current and longest streak, rest days, goal changes, weekly and 5-week history, milestones and badges. Use when changing StreakEngine, AchievementEngine, the Progress tab, the streak tile or anything that rewards completions.
---

# streak-gamification

## Purpose and scope
Motivation that is honest and deterministic. Code: `Engine/StreakEngine.swift`, `Engine/Achievements.swift`; UI: `Features/Progress/ProgressScreen.swift`, `StreakTile`/`GoalPips` in `TodayView.swift`.

## Use when
Any change to how days qualify, streak counting, goal settings, milestones, badges or progress charts.

## Do not use when
Task CRUD/recurrence (`task-management-engine`).

## Policy (source of truth; also shown to users in Settings → How streaks work)
1. A day **qualifies** when distinct task occurrences credited to it ≥ the goal in force that day. Default goal 3, range 1–10.
2. Credit goes to the **local day of completion** (`CompletionEvent.creditedDay`, stored at completion time), not the due day. Late-night work counts for the day before midnight.
3. **Reopen/undo** removes the event, so credit is removed (honest correction). **Delete** keeps events.
4. **Goal changes are prospective** (`goalHistory` append). Past days keep their goal. On the change day the *lowest* goal in force that day applies, so raising the goal can't un-earn today.
5. **Rest day**: one missed day inside a streak is forgiven if no other rest day occurred in the previous 6 days. It keeps the chain but doesn't add to its length.
6. **Today never breaks** a streak; it's "in progress" until midnight.
7. **Time zones**: stored credited days are never recomputed. Travel can't shift history.
8. Duplicate events for the same (task, occurrence, day) count once.
9. Days with nothing planned and nothing done are missed days (rest rule may cover them).

Anti-gaming stance: we count distinct occurrences and never award points for app opens. We don't try to detect "meaningless" tasks (that would punish real users). No XP in v1: it adds noise without changing behaviour.

## Milestones and badges
`AchievementEngine.streakMilestones = [3, 7, 14, 30, 60, 100]`, then every 50. Badges: First step (1 task), Warming up (3), Consistency star (7), Clear skies (perfect calendar week), Steady climb (14), Fifty finished, Sky high (30), Century (100 tasks). All derived from history; they can relock if history is corrected.

## Procedure
1. Write the rule change in this file first, then a test in `StreakTests` (use `T.events(days, perDay:)`).
2. Implement in `StreakEngine` (pure, no `Date()`).
3. Update the copy in `StreakRulesView` (Settings) and `DailyGoalCard`.
4. `swift test`.

## Standards
- Pure functions over `[CompletionEvent]` + `AppSettings` + `today`. Deterministic, O(days in history).
- Pink only for streak/celebration. Copy is never guilt-based.
- `reachedDailyGoal` fires once per day (`settings.lastCelebratedDay`).

## Common mistakes
- Counting app opens or task creation.
- Timestamp subtraction for day gaps (use `DayKey.days(until:)`).
- Recomputing past goals from the current goal.
- Showing invented stats.

## Validation
Tests must cover: empty history, goal boundary, today in progress, duplicates, single rest day, consecutive misses, two rests within 7 days, rests exactly 7 apart, goal raise/lower same day, prospective goals, timezone travel, midnight boundary, perfect week, 2-year history performance.

## Output
Updated policy text + tests + engine/UI changes.

## Related
`task-management-engine`, `premium-ios-uiux`. Agent: **skyday-product-engineer**. Legacy overlap: streak parts of `task-domain-engine`.
