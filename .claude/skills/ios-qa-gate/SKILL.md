---
name: ios-qa-gate
description: Audit iOS build, functional state, pixel-background readability, accessibility, notifications, and device sizes before delivery.
---

# Quality gate
- Test app compiles in Xcode with available SDK; if unavailable mark NOT VERIFIED. Never fabricate simulator success.
- Verify all Today controls, persistence across relaunch, list management, recurring task stability, streak rules, notification request scheduling, edit/cancel, and permission denial.
- Screenshot inspect iPhone small / standard / large, keyboard up, huge text, empty tasks, 100+ tasks, Reduce Motion, light/dark appearance.
- Check tappable areas 44pt+, sufficient contrast, text truncation, date localization, voice labels, safe areas and clipped cards.
- No lorem ipsum, dead navigation, fake 'AI' service, or unusable onboarding.
- Output QA_REPORT.md with Passed, Failed, Not Run separately and honest reproduction instructions.
