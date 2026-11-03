# Skyday QA report

> Update 2026-11-03: the "Not run" Xcode items below have since run on a GitHub Actions macOS runner (Xcode 16.4): simulator build and UI tests pass. Current status: [`DELIVERY_STATUS.md`](DELIVERY_STATUS.md), [`docs/TEST_RESULTS.md`](docs/TEST_RESULTS.md).

Environment: Linux (Ubuntu 24.04) cloud container, Swift 6.0.3 (swift-corelibs-foundation, XCTest). **No macOS, no Xcode, no iOS Simulator.** Nothing below was run on iOS. Date: 2026-11-03.

## Passed (actually run)
| Check | Command | Result |
|---|---|---|
| Domain, persistence, reminders, streaks | `cd Packages/SkydayKit && swift test` | **95 tests, 0 failures** (DayKey 8, Recurrence 11, Streak 17, ReminderPlanner 12, Store 37, Query & Support 10) |
| App + widget type-check vs SDK-shaped stubs | `cd Tools/LinuxTypecheck && swift build --build-tests` | **Build complete**, 0 errors (includes SkydayUITests vs XCUITest stubs) |
| Xcode project structure | `swift Tools/validate_xcodeproj.swift` | **OK: 46 objects, 3 targets, all references resolve** (also verified it fails on a deliberately broken reference) |
| Skill/agent frontmatter | Python YAML check | 17 skills + 5 agents valid; agent skill references resolve; 7 original skills byte-identical above their appended note |
| Asset/plist/scheme files | `json.tool`, `plistlib`, XML parse | Valid |
| Colour contrast (computed) | WCAG formula over token hexes | All text pairs ≥ 4.5:1; see `docs/design-system-sheet.png` |

Notable things these runs caught and fixed:
- Two real compile errors: a missing `import Observation`, and internal `WidgetSnapshot` initialisers used from the widget.
- `AppData` failed to decode documents that lack a `schemaVersion` field.
- Saves took ~85 ms each at 600 tasks because a date formatter was created per date. Now cached.
- Today didn't refresh at midnight when no data changed.

Key behaviours covered by tests:
- Create, edit, complete, reopen and delete persist across simulated relaunches.
- No duplicate recurring tasks after 10 relaunches.
- Recurrence edge cases: month-end, leap day, DST, missed days rolled forward.
- Repeating tasks: "skip this time", and never stranded on an already-completed occurrence.
- Idempotent completion; stale notification actions are ignored.
- Undo.
- Streak policy: rest days, prospective goal changes, time-zone travel, midnight boundary.
- Reminder planning: 64-request cap, stable IDs, diff, sound-toggle replacement, digests.
- Persistence safety: corrupt-file quarantine, newer-schema read-only mode, legacy decoding, import/export.
- 600-task performance.

## Independent review findings (agents, read-only)
**QA reviewer**
| Finding | Status |
|---|---|
| Weekly repeat kept the old weekday after the date changed | Fixed (repeat follows the due date in the editor) |
| "Move to tomorrow" re-anchored recurring series | Fixed (one-offs only; repeating tasks get "Skip this time"; tested) |
| Dead checkbox when a repeating task sat on a completed occurrence | Fixed (store advances past completed occurrences; tested) |
| Snooze/Complete from a notification could be lost to suspension | Fixed (delegate awaits the sync before `completionHandler`) |
| Return inserted a newline in the title | Fixed (single-line field; newlines collapsed in `TaskDraft`; tested) |
| UI tests used wrong element queries | Fixed (identifiers/labels updated; now type-checked) |
| Opening a task marked it as edited | Fixed (`settled` guard) |
| Sound toggle didn't update pending requests | Fixed (delivery-options fingerprint suffix; tested) |
| `EditButton` inside a `Menu` | Fixed (toolbar button, only in Manual sort) |
| Notification tap could replace an open editor | Fixed (`present` never replaces an open sheet) |
| Export stale after import | Fixed |
| Delivered reminders of done recurring occurrences not cleared | Fixed |
| Checkbox VoiceOver label had no task title | Fixed |
| Widget time ignored 12-hour locales | Fixed |

**Design director** (most items were absorbed by the v2 redesign)
| Finding | Status |
|---|---|
| Today failed the 2-second test on iPhone SE | Redesigned: hero → pills → first task card. Not verified on a device |
| Undo toast overlapped the FAB | Fixed (toast pinned above the floating bar; FAB removed) |
| Clouds under text | Fixed (reserved 96pt art strip; preview confirms) |
| List editor grids overflowed on SE | Fixed (adaptive grid) |
| Touch targets < 44pt (chips, weekday toggles, headers) | Fixed |
| Meta line truncation at AX sizes | Fixed (stacks at accessibility sizes) |
| Inconsistent goal-met colour; weak tile contrast | Fixed (pink = goal met everywhere; visible missed outline) |
| Done rows only reachable by tap gesture | Fixed (real buttons) |
| List glyph contrast on amber/lagoon | Fixed (ink glyph on light hues) |
| Filler subtitles | Fixed (live facts) |
| Pink allowed as a list colour | **Kept by decision**: in v2 lists are pastel cards; the user's own mockup uses a pink Personal list |
| Plan completion has no linger/celebration; no month jump | Not fixed (minor) |

## Design passes
1. **v1** pixel-sky light design. 2. **v2** night canvas (the user's first reference). 3. **v3 (current)** the user's Skyday reference sheet: light, illustrated pixel-sky headers, white cards, native tab bar. Behaviour fixes from the reviews carried through all passes. The v2-specific findings (toast overlapping the floating bar, hero cloud strip) no longer apply: v3 uses a native tab bar and fixed text zones in the art.

## Failed
None of the checks that could run here failed at the time of writing.

## Not run (needs macOS + Xcode 16+)
| Check | How to run |
|---|---|
| Real iOS SDK build of app + widget | `xcodebuild -project Skyday.xcodeproj -scheme Skyday -destination 'platform=iOS Simulator,name=iPhone 16' build` |
| Unit tests inside Xcode + UI tests | same with `test` |
| Visual check: SE, 16, Pro Max; AX3/AX5 text (sky title wrapping over the art); Reduce Motion; VoiceOver pass on Today | Simulator + Accessibility Inspector |
| Keyboard + medium-detent task sheet on SE | Simulator |
| Notification permission timing, denied flow, delivery, Complete/Snooze from Lock Screen with app killed | Physical device |
| Widget refresh after edits, midnight rollover, deep links; App Group provisioning | Device with a signed team |
| Save latency at 1,000 tasks; Today scroll hitches (Instruments) | Device |

## Known limitations / risks
- The stub type-check is not the real SDK. Expect a few signature mismatches on the first Xcode build; they should be small and local.
- In Swift 5 mode, Xcode may warn about main-actor UIKit calls from `Haptics` and non-Sendable notification types. These are warnings, not errors; they'd become errors under Swift 6 mode.
- The app is fixed to light appearance (the reference is a daytime design); system dark mode is not supported. Night is shown by the Today header art.
- `docs/screens-preview.png` composites the real header art, but fonts (DejaVu) and icons are stand-ins; it is not an iOS screenshot. Header art is cropped by `scaledToFill`, so on narrow phones (iPhone SE) the art edges crop more; check that text zones stay clear on device.
- Header art PNGs are small (~220 px wide) and depend on `.interpolation(.none)`. If they look blurry on device, that modifier was dropped.
- Persistence is JSON, not SwiftData (decision record in `ARCHITECTURE.md`). Saves are synchronous on the main actor; measure on device.
