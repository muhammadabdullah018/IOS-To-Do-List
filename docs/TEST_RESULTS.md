# Test results

All results below were actually run. Nothing here is simulated.

## GitHub Actions, macOS runner (`macos-15`, Xcode 16.4)
Workflow `.github/workflows/ci.yml` on https://github.com/SpideyAB/IOS-To-Do-List, branch `skyday-delivery`.

| Check | Command | Result | Run |
|---|---|---|---|
| SkydayKit unit tests | `cd Packages/SkydayKit && swift test` | **95 tests, 0 failures** | [41683623460](https://github.com/SpideyAB/IOS-To-Do-List/actions/runs/41683623460) |
| App + widget simulator build | `xcodebuild build -project Skyday.xcodeproj -scheme Skyday -destination id=<iPhone sim> CODE_SIGNING_ALLOWED=NO` | **BUILD SUCCEEDED** | 41683623460 |
| UI tests (8) | `xcodebuild test ... -resultBundlePath build/Skyday.xcresult` | **8 tests, 0 failures, TEST SUCCEEDED** (iPhone SE 3rd gen simulator, 750×1334) | 41683623460 |
| Screenshot tour | `testScreenshotTour` → `xcresulttool export attachments` | 9 screenshots, copied to `docs/screenshots/ios-simulator/` | 41683623460 |
| Re-run after security, month calendar, haptics, launch and motion changes (`macos-15-intel`, commit 168edd9) | `swift test` + `xcodebuild build` | **swift test passed; BUILD SUCCEEDED** | [41694283629](https://github.com/SpideyAB/IOS-To-Do-List/actions/runs/41694283629) |
| UI tests on that commit | `xcodebuild test` | still running when this was written; see the run link | [41694283629](https://github.com/SpideyAB/IOS-To-Do-List/actions/runs/41694283629) |
| Runs 41685554185, 41687831896, 41690884079, 41691674332 | — | iOS job **never started**: arm64 macOS pool had no capacity ("job was not acquired by Runner"); fixed by moving to `macos-15-intel` | — |
| Secret scan | gitleaks 8.21.2, full history | **no leaks** | 41683623460, 41694283629 |
| Web demo CI | `npm ci && npm run typecheck && npm test && npm run build && npm audit --audit-level=high` | **pass** | 41694283629 |

UI tests covered: first launch shows empty state and exactly 3 tabs; quick add → complete → undo → relaunch persistence; blank title cannot be saved; create list; Settings from Progress; Streaks from Progress; Calendar from Today; screenshot tour.

## Local (Windows 11, Node 24.19, npm 11.17)
| Check | Result |
|---|---|
| `npm test` (vitest 5.0.5) | 11 tests passed (re-run after redesign) (dates, month-end recurrence, no duplicate repeats, idempotent complete + undo, ordering, streak, longest streak, import rejection, import sanitising) |
| `npm run typecheck` | 0 errors |
| `npm run build` | built, 177 KB JS (56 KB gzip) |
| `npm audit` | 0 vulnerabilities |
| Browser smoke test (local dev server) | create 3 tasks incl. subtasks and High priority; complete; undo; reload keeps data; goal stepper; Streak, Settings, Calendar, Lists screens render with real data |
| Browser smoke test (live https://spideyab.github.io/IOS-To-Do-List/) | page 200 over HTTPS; created and completed a task; storage cleared after |

## Local audits (Windows)
| Check | Result |
|---|---|
| Pattern scan for keys, passwords, private keys in tracked files | only false positives (`id-token: write`, undo token) |
| Tracked signing/secret files (`.p12 .p8 .cer .mobileprovision .env .ipa`) | none |
| AI attribution in tracked non-doc files | none |
| New commits' author and trailers (`git log 7e2f173..HEAD`) | all SpideyAB, no trailers |
| Manual Swift review of new code | fixed duplicate `LazyVGrid` ids in the month grid header |

## Not run
| Check | Why |
|---|---|
| Physical iPhone install and launch | no Mac/device/Apple account in this environment |
| Notification delivery, Complete/Snooze from lock screen | needs device or interactive simulator session |
| Widget on Home Screen | needs interactive simulator or device |
| VoiceOver walk-through, AX5 Dynamic Type screenshots, Reduce Motion visual check | manual; not recorded |
| Release-mode performance profile (Instruments) | needs a Mac; SkydayKit has a 600-task save benchmark in unit tests |
