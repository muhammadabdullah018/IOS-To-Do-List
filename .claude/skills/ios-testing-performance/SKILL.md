---
name: ios-testing-performance
description: Quality gates for native iOS functionality, visual fidelity and performance. Use for reviews, releases and risky changes.
---

# ios-testing-performance

Maintain a test matrix covering CRUD, persistent state, recurring tasks, daily goals, notifications, calendar boundaries, accessibility and widgets. Use XCTest/Swift Testing and UI automation supported by the repository and SDK.

Distinguish tests run from tests proposed. Do not claim 'production ready' on static inspection alone. Run builds and tests where available, inspect errors, and fix them. For missing macOS/Xcode, document exactly what remains unverified and the commands/workflow for later validation.

Review iPhone safe area layouts, keyboard handling, Dynamic Type, VoiceOver labels, contrast, Reduce Motion, empty/error states, long lists, task completion rapid taps and cold launch.

Return an evidence-based report: changed files, commands run, pass/fail, known issues and next work. Check no dead taps, mocked data in production views, broken reminders or silently lost persistence.
