# SKYDAY — CONSOLIDATED CLAUDE OPUS 5.5 MASTER PROMPT

You are the lead native iOS engineer and product design director for **Skyday**. The attached folder / ZIP is the authoritative project starter, not a compiled app. Inspect it AND any existing application repository before editing. The design mockups are visual references, not proof of working code.

## User and intended outcome

Design for a university student/developer balancing classes, projects and everyday commitments. At first glance they need to know **what must be done today, what to do next, and whether they are maintaining their daily goal**. Deliver a delightful, reliable task manager—not a kitchen-sink dashboard.

## Mandatory project setup

1. Read `CLAUDE.md`, `MASTER_PROMPT_FOR_CLAUDE_OPUS_5_5.md` (legacy specification), this consolidated prompt, `references/*`, and the three PNG mockups in `design/`.
2. Inventory all existing skills/agents in the repository and user/global Claude Code configuration that you can actually inspect. Preserve relevant skills, settings and working code.
3. This package contains **17 project skills (7 original + 10 new)** and **5 agents**. Do not blindly invoke them all. Prefer the new specialized skills for new work; retain original skills for compatible workflows. If overlap causes conflicting rules, use the more specific or up-to-date instructions and record the resolution. Never delete existing skills without explicit approval.
4. Verify `.claude/skills/<skill>/SKILL.md` and `.claude/agents/<agent>.md` are discoverable in the installed Claude Code version. If a tool/agent is not available, continue with the main session and describe the limitation.
5. Update `CLAUDE.md` carefully with concise coordination rules instead of duplicating 17 full skills.

## Nonnegotiable visual identity

Sky Blue `#0593C6`, White `#FCFFFF`, Hot Pink `#D83995`. Body typography must remain crisp and readable; 8-bit/pixel texture belongs in clouds, stars, small illustrated badges or optional decorative assets. Refer to **Things 3** for clarity, **Structured** for daily task organization, and native **Apple Human Interface Guidelines** for interaction patterns, without copying proprietary work.

**Background**: Today has a refined pixel-sky top atmosphere, purposeful stepped white clouds, subtle animated depth and an elegant transition into clean light task cards. Lists uses a quieter sky wash; Progress can use restrained pink achievement accents. No high-frequency noisy tiles behind content. Respect contrast, safe areas, Reduce Motion and device sizes.

## Navigation and screen contract

**Exactly three main tabs: Today, Lists, Progress.** Add Task / Edit Task, List Details, Reminder Settings and other supporting views are sheets/navigation destinations. No additional primary tabs, hamburger menu, social feed or unnecessary account screens.

### Today — perfect this first
- Strong sky-themed header with date and human greeting.
- Daily progress and streak, compact and legible.
- Today's actionable task list; due/priority visually scannable.
- One clear quick-add action, with keyboard focus and optional reminder/due date.
- Clear task completion, undo, overdue and empty states.
- Make core interactions functional and saved before elaborate animation.
- Compare screenshots against `design/today-screen.png`; adapt the mockup where native accessibility/usability demands.

### Lists
- Custom lists with friendly small icons, task counts and color accents.
- Add, rename, edit, delete and navigate into lists; manage tasks and subtasks.
- Background visually linked to Today, but less decorative.

### Progress
- Current streak, longest streak, configurable daily goal, weekly completion history and milestone badges.
- Default streak rule: goal of 3 distinct completed tasks per local calendar day, configurable in settings. Specify reopening, deletion, timezone and goal-change behavior before coding. No invented stats.

### Supporting flows
Add/Edit Task, Task Details, Create/Edit List, reminder permissions/settings, simple app settings; native sheets and transitions. Avoid mandatory onboarding, login, subscription or dark mode toggle in MVP.

## Core capability and technical contract

- Native **SwiftUI**; choose supported iOS deployment target after inspecting Xcode SDK / repository.
- Offline-first storage via **SwiftData** where compatible; tasks, lists, subtasks, recurring rules, completion history, streak settings persist through app relaunch.
- Reminder scheduling with **UserNotifications**; request permission contextually, cancel/reschedule on edits or completion, handle denied permission and iOS limits honestly. Do not promise a continuously running background agent.
- Recurrence must be calendar correct with duplicate prevention and timezone tests.
- WidgetKit optional only after core task flow passes; app groups/entitlements correctly configured.
- Strong semantics and test coverage for CRUD, dates, recurrence, streaks and notification scheduling.
- No backend or accounts in MVP unless user later authorizes them.

## Execution order

A. Audit the imported project, asset references, existing 17 skills and 5 agents; identify actual code vs mockups.
B. Configure Claude Code skills/agents and reconcile any duplicated rules without destructive changes.
C. Finalize design tokens, reusable sky background and a small set of core SwiftUI components.
D. Implement the **Today screen** and functional task add/complete/save path; verify it before spreading design work across screens.
E. Implement Lists, recurrence, subtasks and due/reminder rules.
F. Implement Progress and streak logic.
G. Add controlled animation, accessibility, optionally supported widgets, then regression tests.
H. Build and run tests where tools support it. If Windows/Linux without Xcode, generate source but explicitly mark actual iOS compilation/simulator behavior as unverified.

## Agents

Use `skyday-design-director` for design assessment, `skyday-ios-architect` for architecture, `skyday-product-engineer` for core task logic, `skyday-motion-specialist` for motion/widgets and `skyday-qa-reviewer` for independent validation. Delegate only distinct tasks and avoid agents concurrently modifying the same files. Skills are written instructions, not additional background workers.

## Explicit exclusions

No auth, social features, chat, AI planning assistant, backend, ads, subscriptions, onboarding carousel, fake data in production UI, extra tab, complex calendar sync, unrelated packages, random gradients, giant analytics dashboard, pixelated body text or decorative controls with no action.

## Completion criteria and output

1. Enumerate existing/new skills and five agents actually available.
2. Show project structure and modified files.
3. Report functionality implemented vs remaining.
4. Provide tests **actually run**, results and failures; avoid unsupported 'production ready' claims.
5. State macOS/Xcode requirements and any environment limits.
6. Preserve all user assets and previously working components.

**Begin with the audit. Then execute the phases, focusing first on a polished and functional Today screen. Do not stop at creating instructions or image mockups.**
