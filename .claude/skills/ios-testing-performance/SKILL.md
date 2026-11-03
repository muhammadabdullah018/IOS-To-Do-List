---
name: ios-testing-performance
description: Skyday quality gate - test matrix, what runs on Linux vs macOS, the type-check harness, project validation, UI tests, accessibility and performance checks, and honest QA reporting. Use before declaring any feature done, before commits that change behaviour, and for reviews or releases.
---

# ios-testing-performance

## Purpose and scope
Evidence over claims. Owns `Packages/SkydayKit/Tests`, `SkydayUITests`, `Tools/LinuxTypecheck`, `Tools/validate_xcodeproj.swift` and `QA_REPORT.md`.

## Use when
Finishing a feature, reviewing a change, preparing a build, or reporting status.

## Do not use when
Exploratory design work with no code yet.

## What can run where
| Check | Linux/Windows (WSL) | macOS + Xcode 16+ |
|---|---|---|
| `cd Packages/SkydayKit && swift test` (89 domain tests) | ✅ | ✅ |
| `cd Tools/LinuxTypecheck && swift build` (app + widget vs SDK-shaped stubs) | ✅ | not needed |
| `swift Tools/validate_xcodeproj.swift` | ✅ | ✅ |
| `xcodebuild … build` / `test` (real SDK, UI tests) | ❌ | ✅ |
| Simulator screenshots, VoiceOver, Instruments | ❌ | ✅ |
| Notifications, widget refresh, App Group | ❌ | device preferred |

The type-check harness is an approximation. Passing it means "no errors against our stubs". Only `xcodebuild` proves the real SDK accepts the code.

## Test matrix (minimum before "done")
- Domain: CRUD + relaunch, lists + moves, sorting, overdue by time, recurrence edge cases, no duplicates after relaunches, undo, idempotent completion, streak policy (all 9 rules), goal changes, time zones, midnight, reminders (plan, diff, cap, DST), corrupt/new-schema files, import/export, 600-task performance.
- UI (`SkydayUITests`): first launch empty state + exactly 3 tabs; quick add → complete → undo → relaunch persists; empty title can't save; create list; settings opens.
- Manual on simulator: iPhone SE + Pro Max, light/dark, AX3 Dynamic Type, Reduce Motion, VoiceOver pass on Today, keyboard over the task sheet, 100+ tasks scroll, permission denied flow.
- Performance: Today scroll with 500 tasks shows no hitches (Instruments), cold launch < 1 s to interactive on a recent device, save < 16 ms at 1,000 tasks (measure on device; Linux debug numbers are not representative).

## Procedure
1. Run every check available in the current environment; copy the exact command and summary line into `QA_REPORT.md`.
2. List everything not run under **Not run**, with the reason and the command to run it.
3. Failures get a reproduction and a severity (blocker / major / minor).
4. Never write "production ready" without a green `xcodebuild test` and the device checklist.

## Common mistakes
- Reporting proposed tests as executed.
- Treating the stub type-check as a real build.
- Testing with the system clock (use `FixedClock`).
- Forgetting `async` on `@MainActor` XCTest methods (Linux XCTest discovery needs it).

## Output
`QA_REPORT.md` updated with Passed / Failed / Not run, plus commands.

## Related
All skills. Agent: **skyday-qa-reviewer** (independent review, read-only). Legacy overlap: `ios-qa-gate`.
