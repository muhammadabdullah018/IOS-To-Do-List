---
name: swiftui-engineering
description: Skyday app architecture and SwiftUI implementation - module boundaries, store and router, navigation, sheets, lifecycle, dependency injection, concurrency and build verification. Use for any Swift code change in Skyday/, SkydayWidget/ or Packages/SkydayKit.
---

# swiftui-engineering

## Purpose and scope
Keep the codebase small, layered and verifiable. Owns structure and integration; domain rules belong to `task-management-engine` / `streak-gamification`, persistence details to `ios-data-persistence`.

## Use when
Adding or changing views, navigation, the store API, services, app lifecycle, the widget target, or project configuration.

## Do not use when
Only editing copy or tokens (`premium-ios-uiux`, `pixel-art-design-system`).

## Architecture (as built)
```
Packages/SkydayKit (Foundation + Observation only; compiles & tests on Linux)
  Domain/      DayKey, TimeOfDay, TaskItem, TaskList, Subtask, RecurrenceRule, CompletionEvent, AppSettings, AppData
  Engine/      RecurrenceEngine, StreakEngine, TaskQueries, ReminderPlanner, AchievementEngine
  Persistence/ DataPersisting, JSONFileStore, InMemoryStore
  Store/       SkydayStore (@MainActor @Observable, the only mutator), RelativeDayFormatter
  Support/     SkydayClock, DeepLink, TaskDraft (validation), WidgetSnapshot, SkydayIdentifiers
Skyday/ (iOS app target)
  App/         SkydayApp, AppEnvironment (composition root), AppRouter (tab, paths, sheet), RootView
  DesignSystem/ Theme, PixelArt, Components
  Features/    Today, Plan, Lists, Progress, Task, Settings
  Services/    NotificationService (+ NotificationDelegate)
SkydayWidget/  WidgetKit extension reading WidgetSnapshot from the App Group
```
Rules:
1. Views never mutate data directly. They call `SkydayStore` intents (`addTask`, `complete`, `reschedule`, …). The store persists synchronously, then fires `onCommit`, which `AppEnvironment` wires to notification sync and the widget snapshot.
2. Business rules live in SkydayKit and are unit-tested. A view may only compose queries the store exposes.
3. Navigation: `AppRouter` holds `tab`, `todayPath`, `listsPath`, `sheet`. Add new sheets as `SheetRoute` cases and present via `router.present(_:)`. Never add a tab.
4. Injection: `.environment(store)`, `.environment(router)`, `.environment(notifications)`; read with `@Environment(Type.self)`. Tests construct `SkydayStore(persistence: InMemoryStore() or JSONFileStore(tempDir), clock: FixedClock(...))`.
5. Time: always `store.today` / `store.now` / `store.calendar` (injectable clock). Never `Date()` in domain code.
6. Concurrency: store and router are `@MainActor`. Tasks spawned from views use `Task { @MainActor in … }`. The UN delegate hops to the main actor before touching state.
7. Keep files focused (one screen per file plus its private subviews). Split when a file passes ~400 lines.

## Procedure
1. Read the affected files and the store API before writing code.
2. If behaviour changes, add or adjust a SkydayKit test first.
3. Implement; reuse `TaskRow`, `SkyCheckbox`, `PageHeader`, `EmptySkyState`, `Chip`, `card()`.
4. Verify (below), then update `ARCHITECTURE.md` if a boundary changed.

## Standards
- Deployment target iOS 17.0 (Observation, `onChange(of:_:_)`, `containerBackground`). Project format needs Xcode 16+ (synchronized folders).
- No third-party packages without explicit user approval.
- Swift 5 language mode in the app target; SkydayKit compiles warning-free.
- Watch the memberwise-init trap: a plain `private var x = …` stored property makes a struct's initializer private (verified with the Swift 6.0 compiler). `@State private var` and `private let x = …` are fine.
- Every visible button performs a real action; no placeholder closures.

## Verification
- Linux/Windows (no Xcode): `cd Packages/SkydayKit && swift test`, then `cd Tools/LinuxTypecheck && swift build` (type-checks app + widget against SDK-shaped stubs; see its Package.swift). Then `swift Tools/validate_xcodeproj.swift`.
- macOS: `xcodebuild -project Skyday.xcodeproj -scheme Skyday -destination 'platform=iOS Simulator,name=iPhone 16' test`.
- Never claim a simulator build or run that did not happen.

## Common mistakes
- Using `@Observable` without `import Observation`/`SwiftUI` in that file (caught once already).
- Calling `@MainActor` store APIs from a non-isolated closure.
- Constructing package structs from the app without a `public init` (memberwise inits are internal).
- Adding files outside the synchronized folders (they won't be in any target).

## Output
Code + tests + a verification log listing the commands actually run and their results.

## Related
`ios-data-persistence`, `task-management-engine`, `ios-testing-performance`. Agent: **skyday-ios-architect**. Legacy overlap: `ios-swiftui-architecture`.
