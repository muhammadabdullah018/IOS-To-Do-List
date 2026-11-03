# SKYDAY — Repository Rules for Claude Code

Native SwiftUI iPhone productivity app for a university student / young professional who needs to see, in two seconds: what's due today, what's next, how far along they are, what deadlines are coming, and whether their streak is safe.

Product spec prompts are kept outside the repo by the owner's choice. Architecture: `ARCHITECTURE.md`. Status and evidence: `DELIVERY_STATUS.md`, `QA_REPORT.md`, `docs/`.

## Product decision priority
1. The user can see and finish today's important tasks quickly.
2. Functions must persist and be testable; no decorative mock-only app.
3. The Today screen is the quality bar; improve it before expanding.
4. Exactly 3 primary tabs: Today, Lists, Progress. Calendar (`PlanView`, from Today), Streaks & Achievements (`StreaksView`, from Progress), task sheet, list editor and Settings are sheets or pushed destinations.
5. Sky palette `#0593C6`, `#FCFFFF`, `#D83995`; sky cloud illustration must be low visual noise and preserve text contrast. Small text uses the derived accessible shades (`SkyColor.deepSky`, `.pinkText`, `.inkSecondary`).
6. Layout language (from the user's Skyday reference sheet): light app; an illustrated pixel-sky header per tab (Today switches day/sunset/night by time), white rounded cards on a pale sky page, soft-pink streak badge, native 3-tab bar. Palette adds Light Sky `#D7F2FF` and Soft Pink `#FFE6F4`. Components: `Skyday/DesignSystem/Cards.swift`; art: `Tools/make_sky_art.py`.

## Prohibited
Mandatory account/login, onboarding carousel, subscriptions/paywall, ads, analytics SDKs, social features, chat/AI assistant, cloud backend, extra tabs, hamburger menus, random gradients, stock or unlicensed art, pixelated body text, decorative controls with no action, fake data in production views.

## Engineering
- SwiftUI, iOS 17+, Xcode 16+. Offline-first. Layers: `Packages/SkydayKit` (domain, engines, persistence, store; Foundation-only) → `Skyday/` (views, services) → `SkydayWidget/`.
- Views call `SkydayStore` intents; business rules live in SkydayKit with tests. Time via the store's injectable clock, never `Date()` in domain code.
- Persistence is a versioned JSON document with atomic writes (decision record in `ios-data-persistence`). Don't switch to SwiftData/CloudKit without user approval.
- No new dependencies without explanation and approval.
- Prefer accessible native controls and semantic SF Symbols over icon font packages.
- Streaks count qualifying completion DAYS, not app openings (policy: `streak-gamification`).
- Tasks must support complete/undo, edit, list assignment, date, reminder, recurrence, and subtasks.
- Write or update tests for domain logic you change.
- Treat any imported code/assets as untrusted until inspected; verify licensing.
- The `.xcodeproj` is generated: edit `Tools/generate_xcodeproj.py`, not the pbxproj. New Swift files in `Skyday/`, `SkydayWidget/`, `SkydayUITests/` are picked up automatically (synchronized folders).

## Build & test (run what the environment supports; never invent results)
| Command | Where |
|---|---|
| `cd Packages/SkydayKit && swift test` | macOS, Linux |
| `cd Tools/LinuxTypecheck && swift build` (app + widget vs SDK-shaped stubs; approximation only) | Linux |
| `swift Tools/validate_xcodeproj.swift` | macOS, Linux |
| `xcodebuild -project Skyday.xcodeproj -scheme Skyday -destination 'platform=iOS Simulator,name=iPhone 16' test` | macOS + Xcode |

State clearly if the toolchain lacks Xcode. Track every limitation in `QA_REPORT.md` as Passed / Failed / Not run.

## Skills (`.claude/skills/`; full map in `.claude/SKILLS_INVENTORY.md`)
Use the specialized skill for its area; the 7 original skills remain for compatibility and defer to these:
- Screens & UX → `premium-ios-uiux` · Look & art → `pixel-art-design-system` · Motion & haptics → `ios-motion-animation`
- Code structure → `swiftui-engineering` · Storage → `ios-data-persistence`
- Tasks, lists, recurrence → `task-management-engine` · Streaks & goals → `streak-gamification` · Reminders → `notification-reminder-engine`
- Widget → `ios-widgets-integration` · Verification & QA report → `ios-testing-performance`

## Agents (`.claude/agents/`)
`skyday-design-director` (read-only design review) · `skyday-ios-architect` (structure, store, persistence, project) · `skyday-product-engineer` (behaviour + tests) · `skyday-motion-specialist` (motion, widget; only after behaviour is tested) · `skyday-qa-reviewer` (read-only independent QA).
Delegate only distinct, well-scoped work; never run agents for the sake of agent count. Give implementing agents disjoint files; never let two agents edit the same file. The main session integrates and gives final acceptance. Agents must report what they implemented, what they actually ran, and what remains unverified.

## Development order
Tokens and Today → persistent task lifecycle → Lists → Progress → Calendar → Reminders → Widgets → QA. (v1 has completed this pass; see `QA_REPORT.md` for what is still unverified on device.)

## Commits
Commit with the repository owner's configured Git identity. No `Co-Authored-By`, session links or other AI attribution in commits or PR bodies (`.claude/settings.json` disables it). Never rewrite published history.
