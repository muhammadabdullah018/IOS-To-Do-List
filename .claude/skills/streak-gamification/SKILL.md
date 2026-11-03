---
name: streak-gamification
description: Streak rules, completion history, daily goals, achievements and progression. Use when designing or implementing Progress.
---

# streak-gamification

Default streak is achieved when the user completes their configurable daily goal (default three tasks). Make the goal adjustable and explain it in UI. Track current streak, best streak and a per-day record of actual completions; separate from task due date.

Define how reopening tasks, deleting tasks, changing goals, retroactive completion, skipping days and timezone travel affect streaks. Document policy before implementation; use Calendar calculations rather than timestamp subtraction. Do not silently fabricate streak continuity.

Make rewards restrained: pink milestone badges, progress rings, small pixel trophies and light haptic celebrations. No punishments, guilt-inducing copy, manipulative notifications or fake progress metrics.

Progress view: streak summary, seven-day completion overview, goal state and history. Avoid huge analytics dashboard with fabricated stats.

Tests: midnight boundaries, missed days, goal change, duplicates, same task completing twice, history accuracy, timezone changes.
