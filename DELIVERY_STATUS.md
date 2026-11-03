# Skyday — Delivery Status

Date (UTC): 2026-11-03
Repository/branch/commit: https://github.com/SpideyAB/IOS-To-Do-List (fork of muhammadabdullah018/IOS-To-Do-List), branch `skyday-delivery`, see `git log` on the branch (latest pushed with this file). Builds on PR #1 branch `claude/skyday-v1` (7e2f173).
Environment: Windows 11 Pro (no Xcode, no Swift locally). iOS builds and tests ran on GitHub Actions `macos-15` with Xcode 16.4.

## Executive result
- Native iOS build: **DONE** — Xcode `BUILD SUCCEEDED` for app + widget (simulator, unsigned): run 41683623460 (Xcode 16.4, arm64) and run 41694283629 (Intel, includes month calendar, haptics, launch and motion code).
- iPhone-installable build: **PARTIAL** — workflow `ios-device-ipa.yml` builds an unsigned arm64 `Skyday-unsigned.ipa` on GitHub macOS; you sign and install it from Windows with Sideloadly and a free Apple ID (`docs/INSTALL_WITHOUT_MAC.md`, 7-day expiry, widget removed). No signed `.ipa` is stored anywhere; not yet installed on a device.
- Simulator build/run: **DONE** — 8 UI tests launch and drive the app on an iOS simulator; 9 real screenshots in `docs/screenshots/ios-simulator/`. Unsigned `Skyday-simulator.app.zip` is in the CI artifact `ios-results` (simulator only).
- Playable browser demo: **DONE** — https://spideyab.github.io/IOS-To-Do-List/ (verified live; redeployed automatically on each push). Local: `cd web-demo && npm install && npm run dev`.
- Upstream PR: https://github.com/muhammadabdullah018/IOS-To-Do-List/pull/2 (from `SpideyAB:skyday-delivery`).
- TestFlight/App Store: **BLOCKED** — needs paid Apple Developer account; checklist in `docs/RELEASE_CHECKLIST.md`.
- Security review: **DONE** (code + CI checks), device-level behaviour PARTIAL — `docs/SECURITY_REVIEW.md`.

## Feature matrix
| Feature | Status | Evidence (test, path, screenshot) | Known issue / next action |
|---|---|---|---|
| Today | DONE | `TodayView.swift`, `02_today.png`, UI tests | VoiceOver walk-through not recorded |
| Lists / CRUD | DONE | `ListsView.swift`, `testCreateListFromListsTab`, `03_lists.png` | — |
| Progress / streak | DONE | `StreakTests` (17), `testStreaksOpenFromProgress`, `04_progress.png`, `08_streaks.png` | — |
| Calendar | DONE | `PlanView.swift` `MonthGrid`, `testCalendarOpensFromToday`, `07_calendar.png` | — |
| Task editor/subtasks | DONE | `TaskEditorSheet.swift`, `StoreTests`, `05_add_task.png`, `06_task_detail.png` | — |
| Recurring tasks | DONE | `RecurrenceTests` (11), 10-relaunch no-duplicate test | — |
| Offline storage | DONE | relaunch UI test, corrupt-file + schema tests | no iCloud sync (by design) |
| iOS notifications | PARTIAL | `ReminderPlannerTests` (12), builds | delivery not observed on a device |
| Widgets | PARTIAL | widget target builds in Xcode | not observed on a Home Screen; App Group needs your team |
| Settings/export/delete | DONE | `09_settings.png`, `StoreTests` import/export/erase | share sheet not exercised on device |
| Accessibility | PARTIAL | labels/identifiers used by UI tests, 44pt targets, Reduce Motion code paths | no AX5 / VoiceOver evidence |
| Web demo parity | PARTIAL | `web-demo/`, 11 vitest tests, live smoke test | no notifications, widgets, search, rest day; fewer repeat rules (`docs/WEB_PREVIEW.md`) |

## Security controls
| Risk | Control | Status | Verification |
|---|---|---|---|
| Sensitive data on disk | sandbox + App Group, `.completeFileProtectionUntilFirstUserAuthentication`, export with `.completeFileProtection` | DONE (code) | build passes; not device-verified |
| Secrets in source/CI | none exist; `.gitignore` for keys/profiles/ipa; gitleaks on full history; unsigned CI | DONE | gitleaks: no leaks |
| Notification privacy | title + list name only, never notes; `hiddenPreviewsBodyPlaceholder` | DONE (code) | not device-verified |
| Dependency vulnerabilities | iOS: no packages. Web: pinned, `npm audit` 0 | DONE | CI + local audit |
| Preview hosting exposure | static HTTPS Pages, CSP self-only, DEMO label, no server, data in visitor's browser only | DONE | live check |

## Exact commands executed and outcomes
| Command | Where | Outcome |
|---|---|---|
| `swift test` (Packages/SkydayKit) | macOS CI | 95 tests, 0 failures |
| `xcodebuild -list -project Skyday.xcodeproj` | macOS CI | schemes Skyday, SkydayKit, SkydayWidgetExtension |
| `xcodebuild build ... CODE_SIGNING_ALLOWED=NO` | macOS CI | BUILD SUCCEEDED |
| `xcodebuild test ... -resultBundlePath build/Skyday.xcresult` | macOS CI | 8 tests, 0 failures, TEST SUCCEEDED |
| `xcrun xcresulttool export attachments` | macOS CI | 9 screenshots |
| `gitleaks detect --redact` | Ubuntu CI | no leaks found |
| `npm ci && npm run typecheck && npm test && npm run build && npm audit --audit-level=high` | Ubuntu CI + Windows | pass, 11 tests, 0 vulnerabilities |
| `curl -I https://spideyab.github.io/IOS-To-Do-List/` + browser smoke | Windows | 200, task create/complete works |
Details: `docs/TEST_RESULTS.md`.

## Git authorship
- Actual author/committer configuration verified: **Yes** (`git config` from the user's global `.gitconfig`, name SpideyAB; no `GIT_AUTHOR_*`/`GIT_COMMITTER_*` overrides set).
- Optional Claude attribution disabled: **Yes** — `.claude/settings.json` sets `attribution.commit = ""`, `attribution.pr = ""`, `sessionUrl = false` (Claude Code 2.1.302).
- Latest commits verified: all 7+ new commits authored and committed by SpideyAB with no trailers (`git log 7e2f173..HEAD --format="%an %(trailers)"`).
- Existing published history preserved: **Yes** — the 6 earlier commits (authored "Claude", with Co-Authored-By trailers) are untouched, by the owner's choice. PR #1 untouched.

## What works today
Everything in the feature matrix marked DONE, in the iOS simulator and in the live web demo: create/edit/complete/undo/delete tasks, subtasks, lists, due dates and times, priorities, repeats without duplicates, streaks and achievements, weekly progress, calendar, settings with export/import/erase, persistence across relaunch.

## What does not work yet
- Not installed or run on a physical iPhone; reminders and widget not observed on a device.
- No recorded VoiceOver pass; large-text screenshots come from the new `testLargeTextScreenshots` UI test (results in the CI artifact).
- The latest UI test run had not finished when this file was written; check run 41694283629.
- Web demo lacks notifications, widgets, search and rest days.
- The removed prompt `.md` files still exist in older commits (history kept on purpose).

## Blockers requiring user action
1. **Mac + Xcode 16** (or a borrowed Mac) to sign and install: `docs/RUN_ON_IPHONE.md`.
2. **Apple ID** (free = 7-day installs on your phone) or **paid Developer account** (TestFlight/App Store, long-lived App Group signing).
3. Choose your bundle prefix and Team ID, then run `python3 Tools/generate_xcodeproj.py --bundle-prefix com.yourname --team YOURTEAMID`.
4. Merge PR #2 on the original repo (needs the owner muhammadabdullah018, or write access for SpideyAB).

## How to run
- Browser now: https://spideyab.github.io/IOS-To-Do-List/
- Web locally: `cd web-demo && npm install && npm run dev` → http://localhost:5173
- Simulator: `xcodebuild -project Skyday.xcodeproj -scheme Skyday -destination 'platform=iOS Simulator,name=iPhone 16' test`
- iPhone: `docs/RUN_ON_IPHONE.md`

## Release recommendation
**READY FOR PRIVATE TEST** — the app builds in Xcode and passes unit and UI tests on the simulator, so it is ready for you to sign and install on your own iPhone. Not ready for TestFlight until it has run on a physical device (reminders, widget, file protection) and passed an accessibility pass; not ready for submission (no signing, metadata or store screenshots).
