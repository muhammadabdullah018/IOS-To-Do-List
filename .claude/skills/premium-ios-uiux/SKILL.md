---
name: premium-ios-uiux
description: Skyday screen design and UX review - hierarchy, native navigation, typography, spacing, states, accessibility and responsive iPhone layouts. Use before building or changing any screen, sheet or interaction, and for design reviews of Today, Lists, Progress, Plan, the task sheet or Settings.
---

# premium-ios-uiux

## Purpose and scope
Own the user-facing quality of Skyday's screens: what each screen is for, its hierarchy, its actions and every state it can be in. Visual identity (palette, pixel art, backgrounds) lives in `pixel-art-design-system`; motion in `ios-motion-animation`. This skill decides *what goes where and why*.

The person: a university student or young professional who opens the app for seconds between classes. Within two seconds Today must answer: what's due, what's next, how far along am I, what's coming, is my streak safe.

## Use when
- Designing a new screen, sheet, row, card or empty state.
- Changing layout, copy, navigation or the order of sections.
- Reviewing screenshots or SwiftUI for usability, hierarchy or accessibility.

## Do not use when
- Pure domain logic (recurrence, streak math) → `task-management-engine`, `streak-gamification`.
- Colors/sprites/backgrounds only → `pixel-art-design-system`.

## Inputs to read first
1. `design/*.png` and `docs/FEATURE_MATRIX.md` (composition only; the mockups use placeholder glyphs and a hard colour band, do not copy those).
2. `Skyday/DesignSystem/Theme.swift` (tokens: `SkyColor`, `Space`, `Radius`, `SkyFont`) and `Components.swift`.
3. The current screen file under `Skyday/Features/`.

## Procedure
1. **State the job of the screen** in one sentence and the single primary action.
2. **Hierarchy pass**: list sections top to bottom with why each earns its place. Today's fixed order (reference sheet): pixel-sky header (date, "Good Afternoon, <name>" + sun/moon, calendar button, soft-pink streak badge) → progress ring card ("67% · 4 of 6 Tasks completed today", overlapping the art) → "Today" + blue square add button → task rows (open in do-next order, max 6 + "Show more"; completed today stay below, checked) → Coming up (max 3).
3. **Action map**: for every tappable element write what it does, its feedback (haptic/animation/toast) and its undo path. No element may be decorative-only if it looks tappable.
4. **States**: empty (no tasks ever), clear (nothing due), all done, overdue present, loading (none, data is local), error (save failure banner, recovery alert), permission denied (reminders).
5. **Accessibility**: Dynamic Type up to AX5 (use `dynamicTypeSize.isAccessibilitySize` to switch HStack→VStack, as `ProgressCard` does), VoiceOver labels/values/hints, 44pt hit targets, Reduce Motion, contrast (see tokens below).
6. **Responsive check**: iPhone SE (375×667) and Pro Max (440×956). Long titles wrap to 2 lines; meta lines truncate; nothing horizontally scrolls except chips.
7. Implement with existing components before creating new ones.

## Standards
- Exactly three tabs in the native tab bar: Today (house), Lists (stack), Progress (chart). Everything else is a sheet (`SheetRoute`) or a pushed destination (`TodayRoute`, `ListsRoute`). Calendar = `PlanView`, from the header calendar button and the progress card. Settings = sheet from the Progress header gear.
- Spacing: 8pt rhythm via `Space` (4/8/12/16/20/24/32); page gutter 20.
- Radii: cards 22, rows 16, tiles 14, small 10. Do not invent new radii.
- Type: system fonts only. Rounded design for hero titles and numbers (`SkyFont.hero`, `.bigNumber`), default design for body and rows. Always text styles (scale with Dynamic Type), never fixed sizes for text except the 64pt streak numeral, which has `minimumScaleFactor`.
- Contrast: small text never uses brand `#0593C6` (3.5:1) or `#D83995` (4.2:1) on white; use `SkyColor.deepSky` / `.pinkText`. Secondary text is `SkyColor.inkSecondary` (#557385, 5.0:1).
- Copy: short, warm, never guilt-based ("Rest day used. 1 more task keeps it going.", never "You failed").
- One primary action per screen; destructive actions confirm (`confirmationDialog`) and offer undo where the store supports it.

## Common mistakes
- Adding a fourth tab, a hamburger menu, or onboarding screens.
- Showing brand-blue small text or text on top of pixel art.
- Hiding a core action in a context menu only (context menus are shortcuts; every action must also exist in the task sheet).
- Fake data in production views. Previews and UI tests only (`-uiTesting`).
- Fixed heights on text containers (breaks at AX sizes).

## Validation
- Walk the action map on a simulator; every button does something real.
- Screenshot at SE + Pro Max, light + dark, default + AX3 text, Reduce Motion on.
- VoiceOver: swipe through Today; each card reads as one meaningful element.
- Record results in `QA_REPORT.md` as Passed / Failed / Not run.

## Output
A short screen spec (job, hierarchy, action map, states, a11y notes), then SwiftUI changes using shared components, then a QA note.

## Related
`pixel-art-design-system` (look), `ios-motion-animation` (feel), `ios-testing-performance` (verification). Agent: **skyday-design-director** reviews; implementation happens in the main session. Legacy overlap: `ios-uiux-designer` (same intent, shorter; this skill supersedes it for new work).
