---
name: swiftui-engineering
description: Native SwiftUI app architecture and robust implementation. Use for any code change to views, models, lifecycle, services or navigation.
---

# swiftui-engineering

Inspect the existing Xcode project, Swift version, target iOS version and compile environment before implementation. Preserve existing working code. Prefer native SwiftUI, SwiftData when target permits, UserNotifications and WidgetKit. Do not add third-party packages without a clear need.

Choose modest architecture: feature views, small reusable components, domain models, persistence layer and testable services. Define data ownership and dependency injection. Keep data and scheduling logic out of large view bodies. Make Today fast with stable identifiers and appropriate query/filtering.

Implement the three-tab shell only: Today, Lists, Progress. Supporting flows are sheets/navigation destinations. Add task quick-entry, edit task and list actions through clear state transitions. Confirm every button actually performs its action.

Compile whenever tools permit; report when Swift compiler/Xcode unavailable. Never call source files a verified working app without building. Use supported APIs for the established deployment target; avoid hypothetical or undocumented calls.

Completion: code follows project conventions, builds where tooling exists, handles errors, has no placeholder dead ends, and includes relevant tests.
