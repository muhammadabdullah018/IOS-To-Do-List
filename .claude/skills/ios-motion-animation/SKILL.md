---
name: ios-motion-animation
description: Purposeful SwiftUI motion, pixel animation, haptics and reduced motion. Use when polishing screens and task interactions.
---

# ios-motion-animation

Map motion to user outcomes: completing a task (small checkbox transition, optimistic list state, optional haptic), opening quick add (focused sheet), updating daily progress, achieving a streak. Use native spring/ease transitions sparingly.

Keep background pixel clouds slow and subtle, and do not continuously animate complex off-screen views. Respect accessibility Reduce Motion; disable nonessential loops. Haptics must reinforce actions without firing during background state recomputation.

Test animation when rapid repeated taps, sheet dismissal, task undo, app backgrounding, low-power mode and Dynamic Type changes occur. Keep task interaction instant and never delay persistence on an animation callback.

Define animations with trigger, duration/style, cancellation and accessible fallback. Avoid bouncing cards on every refresh, constant sparkles, or gesture conflicts with iOS navigation.
