---
name: ios-motion-and-widgets
description: Add restrained native haptics, pixel UI animations, launch experience, and iOS widgets after core app works.
---

# Motion and widgets
- Provide instant platform launch background matching branded app, no custom timed loading spinner.
- Animation communicates state: checkbox, progress card, badge unlock, list insert. Keep 180–280ms and respect accessibility reduced motion.
- No ambient infinite animation behind all content; battery and focus matter.
- Use WidgetKit for small/medium Today completion and upcoming tasks, with App Group shared storage/reads only when tested.
- Widgets have system-controlled refresh cadence: don't promise live updates. Support deep links with correct navigation.
- Gracefully handle widget and app data being stale/unavailable.
