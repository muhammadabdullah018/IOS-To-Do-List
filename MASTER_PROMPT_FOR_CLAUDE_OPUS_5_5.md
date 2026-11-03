# CLAUDE OPUS 5.5 — MASTER BUILD PROMPT

You are the product designer, senior native iOS engineer, motion designer, and QA owner for **SKYDAY** (working title). Build an actually functional, carefully art-directed iPhone productivity app. Treat this repository's CLAUDE.md and `.claude/skills/**/SKILL.md` as binding project instructions. Inspect them before coding. Do not create a web-only demo and call it an iOS app.

## 1. Lead with the PERSON, not the feature
The primary user is a busy university student who also handles freelance/creative work and personal goals. They open the app briefly between classes and late in the evening. They tend to create more tasks than they can finish, forget deadlines when busy, and need a calm but motivating way to see what matters *today*. They want to add a task in under five seconds, get a timely reminder, complete it with one tap, and maintain a healthy consistency streak without being punished for taking a day off. The home screen must show the state of their day immediately. The product is for this person's behavior, NOT an inventory of productivity features.

**One-line design brief:** Things 3-style focus and restraint meets Structured's day-planning clarity, using a distinctive pixel-sky art direction and warm, rewarding interactions. These are *directional references only*: create original layouts, icons, illustrations, copy, and assets. Do not copy trademarks, screens, proprietary imagery, or assets.

## 2. Source of truth and fixed constraints
- Platform: native iPhone app, SwiftUI. Use SwiftData for local persistence subject to the verified deployment target. UserNotifications for local reminders. WidgetKit only after core app works. No backend in v1.
- Primary palette: Sky Blue `#0593C6`; White `#FCFFFF`; Hot Pink `#D83995`.
- Supporting colors MAY be derived: deep ink `#12364A`, pale blue `#EAF8FD`, soft blue `#DDF5FE`, cool gray `#628092`, border `#DDECF4`. Only use pink to emphasize streaks, celebrations, and a high-value action; avoid pink everywhere.
- Three fixed top-level tabs only: **Today**, **Lists**, **Progress**. A calendar is accessed from Today header, Settings from Progress header, Task Detail via sheet, New Task via sheet. NO fourth/fifth tab, hamburger menu, or nested bottom navigation.
- Native SwiftUI components, Apple SF Symbols where appropriate, custom small pixel assets for visual personality. Rounded functional UI; square-edged pixel art accents. Respect dynamic type, VoiceOver, reduced motion, contrast, safe areas, and tap targets.
- Create an excellent LIGHT appearance first. Follow the system color appearance behavior without building a theme toggle in v1; maintain legibility in dark system appearance if supported, but prioritize light design.
- Offline-first and zero account setup. Do not require login, onboarding slideshow, paywall, analytics SDK, cloud sync, subscriptions, AI chat, community feed, or social features.
- No fake working buttons, static fake tasks masquerading as stored tasks, unbounded repeated reminders, broken notification assumptions, or unnecessary third-party libraries.

## 3. FIRST SCREEN MUST BE EXCELLENT — TODAY
Allocate at least 50% of initial design effort to this one screen before building others. Use `design/today-screen.png` as approximate visual direction, NOT as pixel-perfect source. Improve layout based on actual iPhone safe areas and platform conventions.

### Hierarchy, from top to bottom
1. System-safe status area. No hand-painted fake iPhone status bar in app code.
2. Calm sky header with rich layered *pixel-cloud* background, precisely rendered at native pixel multiples to keep the edges crisp. Clouds occupy upper right/negative space, never obscure text. Light blue -> off-white atmospheric gradient. Restrained tiny 8-bit sparkle details; subtle parallax only if it does not compromise performance or accessibility. No stock photo backgrounds, noisy textures, or floating giant emoji.
3. Upper-left compact date overline e.g., `TUESDAY, NOV 3`, 11–12pt, uppercase, tracked. Hero title `Make today count.` 30–34pt semibold. One-line subtitle `Small wins make big days.`
4. A strong primary progress card: rich Sky Blue fill (not a generic gradient), big `3 of 5` count derived from today's tasks, label, slim progress indicator with a proper accessibility value, softly offset pixel-cloud motifs inside the card. Card 20–24pt corner radius, generous padding, no glass-on-glass layering.
5. A petite streak surface: pink 8-bit star in a pale pink tile, `7-day streak`, short non-guilt-inducing encouragement. Derived from real records; not hardcoded. Tap to open Progress. Consider gentle playful haptic for the milestone.
6. `Up next` title with `See all` secondary action. List at most three soonest relevant incomplete tasks, ordered by manually set priority/time. Each row: large checkbox, bold task name, muted list label and time, discreet optional priority cue. One-tap completion with reversible toast/undo. When no tasks: beautiful *custom pixel cloud* illustration and clear `Add your first task` CTA.
7. Floating primary `+` new task button above the tab bar, accessible hit area. Tap triggers a native sheet with keyboard autofocus. Do not use an unnecessarily persistent full-screen task editor.
8. Bottom native three-tab navigation. Ensure all content remains scrollable and readable on iPhone SE and iPhone Pro Max sizes.

### Feel and microinteractions
- On task complete: checkbox visually fills, task row settles, progress updates, light haptic; animation between 180–280ms. Respect Reduce Motion.
- Add task: sheet rises, keyboard focuses immediately, task title is first field, quick date and time chips; save works with one primary action.
- Never show static illustrations underneath dense text. Backgrounds must maintain WCAG-friendly contrast; if text overlays gradient, back it with a stable light surface.
- Aim for a premium friendly product, NOT a children's game or flashy crypto dashboard.

## 4. OTHER SCREENS: INFER THE SYSTEM BUT FOLLOW THESE BOUNDARIES
### Lists tab
Search field at top; list cards/rows with icon, name, task count, and muted list tint. Add custom list with name + optional icon/color. Tap -> List Detail: filtering, sort controls, task rows, add task. Delete list with a destructive confirmation and safe task behavior (default move tasks to Inbox; no accidental loss). Provide a sensible Inbox list created by default.

### Progress tab
Streak today and history, weekly task completion chart, daily goal selector (default 3 completions/day), milestone badges. Pink is the emotional accent. Calendar-like row of last seven days, distinguish completed goals, missed days, and future days. Link Settings from top-right. Streak policy: record a completed day once the daily goal is reached; user can change goal prospectively; never retroactively erase earned streaks on goal change. Explicitly document how days with zero planned tasks, late-night completions, and time zone changes are treated. Avoid guilt-based 'failed' copy.

### Calendar (Today header)
Week strip, date selection, corresponding task sections. Scheduled tasks, overdue tasks, and recurring instances. Calendar is a sub-screen, NOT a fourth tab. Support moving tasks to another day through a task editor first; drag-and-drop only if robust.

### Add/Edit Task sheet
Required title; optional notes, list, due date, due time, priority, reminder(s), subtasks, repeat rule. Allow rapid title-first entry. Validation: cannot save whitespace-only title; do not silently lose edits when dismissing. A task without due time cannot imply an exact alarm; provide a clear default reminder policy if date-only.

### Task Detail
Toggle completion, edit title/description, subtasks, change list, due date/time, repeat, priority, reminder, destructive delete with undo/confirmation. Recurring completion creates the next occurrence without duplicates and preserves history.

### Notification permissions and preferences
Ask permission contextually when user sets first reminder, not on launch. Local reminder scheduling/canceling/rescheduling on every relevant edit, delete, complete, and recurring rollover. The app can schedule a bounded morning/evening digest and task reminders; it cannot guarantee arbitrary continuous background intelligence on iOS. Provide settings for digest time, sound, and enabled states. Handle denied permissions with a route to Settings and still allow task saving. Prevent duplicate notifications and keep pending requests under platform limits.

### Settings
Daily goal, reminder defaults, optional digest, week-start preference, exported JSON backup/import if feasible, data deletion with confirmation, Help & Privacy information. No account controls in local-only version.

### Splash/loading
Use platform Launch Screen guidance: instant native launch screen with matching pale-blue background and original pixel cloud/app icon, with no fake multi-second progress bar. First-launch empty state should be illustrated but functional. Use authentic 8-bit stars and a stylized cloud checkmark as a motif; do not use purchased or unlicensed pixel packs.

### Widget (phase after core validation)
Small and medium widgets for today's completion and next three tasks; tappable deep links. Explain refresh constraints. App Intent actions only when compatible and reliable for target OS; do not promise exact real-time widget refresh.

## 5. DATA, NOT MOCKUP
Define stable identifiers and reasonable models for List, Task, Subtask, CompletionEvent, DailyGoalRecord, ReminderPreferences. Index/sort by task dates and list IDs where useful. Keep domain logic separate from SwiftUI. Use a clock/calendar abstraction for deterministic streak and recurrence tests. On task completion, write a completion event; on undo, reverse the appropriate event. Clearly define what happens if the due date moves and whether streak credit uses local completion day (default). Support task deletion and deduplicate scheduled notifications by stable IDs. Do not mix SwiftData query logic through every view.

## 6. IMPLEMENTATION PLAN (DO THE WORK, DON'T JUST WRITE A PLAN)
1. Inspect repo/toolchain. Confirm macOS + Xcode availability. If not available, create complete Swift source/project layout, mockups, and deterministic tests, and explicitly report that simulator compilation could not be verified. Never claim successful iOS build on Windows/Linux.
2. Build design tokens, font system, sky illustration components (pixel clouds as drawn vector rectangles with no interpolation), buttons, cards, tab shell, and Today with realistic seed data in DEBUG previews only.
3. Wire Today to persistent local TaskStore and completion logic. Make Add Task and complete/undo work before continuing.
4. Implement Lists and task detail/editor, recurrence, date/time planning, search, and persistence.
5. Implement streak rules, goal, Progress, Calendar, settings.
6. Implement UserNotifications permission flow, scheduler, cancellation, rescheduling, and notification action handling.
7. Implement widgets only if primary features and tests work.
8. Audit UI at small and large device sizes, increase touch target sizes, VoiceOver labels, Dynamic Type, reduce-motion, permission-denied states, empty states, and keyboard overlaps.
9. Run available build/tests and repair issues. Supply a truthful final report with exact verification and limitations.

## 7. REQUIRED TESTS
- Task create/edit/delete/complete/reopen persists across app restarts.
- Two lists can contain distinct tasks; moving tasks between lists works.
- Upcoming tasks are sorted predictably; overdue UI is clear.
- No duplicate recurring instances after repeated relaunches.
- Streak increments once per qualifying local day; no double count; unchanged by goal edits; survives persistence; handles midnight/time zones.
- Notification requests are added, updated, and cancelled idempotently; denied permission doesn't break save flow.
- Empty state, no reminder time, huge title, long notes, offline mode, small-screen layout, dark system appearance, reduced motion, and Dynamic Type tested.

## 8. DELIVERY
Output a REAL iOS SwiftUI project with source and assets, `README.md` (setup and build), `ARCHITECTURE.md`, `QA_REPORT.md`, annotated visual previews, all tests, and a list of accepted limitations. Do not claim shipping-ready without successful device/simulator build, test results, and notification checks. Use tools and skills in this repo. Finish the highest-value working vertical slice first; don't spread effort equally across all screens.

## 9. IDEAL REFERENCE FILES
- `design/today-screen.png`: TODAY art direction
- `design/lists-screen.png`: LISTS art direction
- `design/progress-screen.png`: PROGRESS art direction
- `references/COLOR_PALETTE.md`: color and background principles
- `.claude/skills`: domain work instructions

Begin by reading CLAUDE.md and relevant skills, then inspecting the development environment. Implement the first working Today screen and verify it before broadening the scope.
