---
name: ios-widgets-integration
description: Skyday WidgetKit extension - small and medium Today widgets, App Group snapshot data flow, timeline policy, midnight rollover, deep links and entitlements. Use when changing the widget, its data, or anything that affects what the widget shows.
---

# ios-widgets-integration

## Purpose and scope
A glanceable Home Screen view of today. Code: `SkydayWidget/SkydayWidget.swift`, `WidgetSnapshot` in `Support.swift`, `WidgetBridge` in `AppEnvironment.swift`.

## Use when
Widget UI, sizes, data fields, refresh behaviour, deep links, entitlements or bundle IDs.

## Do not use when
In-app screens only.

## Data flow (as built)
1. On every store commit the app writes `widget-snapshot.json` (atomic) into the App Group and calls `WidgetCenter.shared.reloadTimelines(ofKind: "SkydayTodayWidget")`.
2. The snapshot is precomputed: today's done/planned, up to 3 up-next items, streak, goal, and a **tomorrow** view (carry-overs + tomorrow's tasks).
3. The provider emits two entries: now, and local midnight (switching to `tomorrow`), with `.after(midnight + 60s)` policy. The date never looks stale after midnight even if the app isn't opened.
4. The widget never reads the main store (no contention, small memory).

## Sizes and links
- systemSmall: progress ring + streak; tap → `skyday://today`.
- systemMedium: ring + streak + up to 3 tasks (each `Link` → `skyday://task/<id>`) + pink + (`skyday://new`).
- `DeepLink` parses URLs; unknown or deleted task IDs fall back to Today.
- The URL scheme `skyday` is registered in `Skyday/Info.plist`.

## Honest limits
WidgetKit refreshes on its own budget; reloads requested while the app is foreground are generally honoured, background ones may be delayed. Widgets aren't live. Interactive check-off (App Intents) is deliberately **not** shipped: it would need the widget process to write the main store, which reintroduces cross-process write races. Revisit with a proper shared-store design.

## Entitlements
Both targets need the same App Group (`group.<bundle-prefix>.app`). Run `python3 Tools/generate_xcodeproj.py --bundle-prefix com.yourname --team TEAMID` to keep bundle IDs, entitlements and `SkydayIdentifiers.appGroup` in sync. Without the group the app still works (data in Application Support) and the widget shows an empty state.

## Common mistakes
- Reading the main JSON from the widget.
- Promising "live" counts.
- Forgetting `containerBackground(for: .widget)` (required on iOS 17).
- Hardcoding colours that drift from `SkyColor` (widget mirrors the hexes in `WColor`).

## Validation
Unit: `testWidgetSnapshotContentAndMidnightRollover`. Device/simulator only: add widget, complete a task in-app and watch it update, wait past midnight, tap each link, remove the App Group and confirm graceful empty state.

## Output
Widget change + snapshot test + device checklist result.

## Related
`ios-motion-animation`, `pixel-art-design-system`, `ios-data-persistence`. Agent: **skyday-motion-specialist**. Legacy overlap: widget half of `ios-motion-and-widgets`.
