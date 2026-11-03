---
name: ios-swiftui-architecture
description: Implement native SwiftUI navigation, presentation, state flow, SwiftData integration, and testable app modules.
---

# SwiftUI engineering standards
- Use an actual iOS project and modern supported deployment target; verify Xcode/toolchain first.
- 3 tabs only, native TabView. Subroutes use NavigationStack; detail/new task use sheets where appropriate.
- Separate Domain models, Persistence/Repositories, NotificationScheduling, Views, DesignSystem, Widgets, Tests.
- Avoid overengineering and unnecessary packages; use SwiftUI, SwiftData, UserNotifications, WidgetKit.
- Inject repository/services so previews and tests do not access production data.
- All task mutations must persist and visibly update list counts/progress.
- Handle app activation, permission changes, preview seeds, process relaunch, and accessibility.
- Never claim compilation if xcodebuild could not run. Include build commands and real logs in QA report.
