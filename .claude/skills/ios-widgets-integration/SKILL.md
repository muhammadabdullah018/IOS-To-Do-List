---
name: ios-widgets-integration
description: WidgetKit, app groups, today tasks, progress and interactive widget feasibility. Use when implementing widgets.
---

# ios-widgets-integration

Build a limited widget scope after core app functions are stable. Recommended widgets: compact Today summary, next task and progress/streak. Determine which widget sizes and interactions are supported by the target OS.

Use WidgetKit with supported timeline policy; synchronize widget-relevant data through an appropriate App Group/shared container, or alternate supported sharing strategy. Make updates efficient. Widgets are snapshots, not continuously running views; do not claim real-time guarantees.

Preserve Skyday colors and readable contrast at small sizes; provide useful placeholder/empty views. Deep link to the correct screen when tapped; handle invalid or deleted task links.

Validate entitlement configuration, target membership, widget data flow and update strategy. On platforms without Xcode, generate code but mark entitlements and simulator tests as unverified.
