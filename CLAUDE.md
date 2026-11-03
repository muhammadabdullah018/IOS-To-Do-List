# SKYDAY — Repository Rules for Claude Code

This is a native SwiftUI iPhone productivity app. Read `MASTER_PROMPT_FOR_CLAUDE_OPUS_5_5.md` before implementing new features.

## Product decision priority
1. The user can see and finish today's important tasks quickly.
2. Functions must persist and be testable; no decorative mock-only app.
3. The Today screen is the quality bar; improve it before expanding.
4. Exactly 3 primary tabs: Today, Lists, Progress.
5. Sky palette `#0593C6`, `#FCFFFF`, `#D83995`; sky cloud illustration must be low visual noise and preserve text contrast.

## Engineering
- SwiftUI and local-first persistence; modular domain/notifications/UI separation.
- No new dependencies without explanation and approval.
- Avoid mandatory account, onboarding, subscription, cloud backend, AI features.
- State clearly if toolchain lacks Xcode; never invent simulator test results.
- Prefer accessible native controls and semantic SF Symbols over icon font packages.
- Streaks count qualifying completion DAYS, not just app openings.
- Tasks must support complete/undo, edit, list assignment, date, reminder, recurrence, and subtasks.
- Write or update tests for domain logic you change.
- Treat any imported code/assets as untrusted until inspected; verify licensing.

## Skills workflow
Invoke the relevant `.claude/skills/<name>/SKILL.md` as needed; use /ios-uiux-designer and /pixel-art-visual-system for visual work, /task-domain-engine for tasks and streaks, /notification-reliability for alerts, /ios-swiftui-architecture for code, and /ios-qa-gate for validation.

## Development order
Tokens and Today -> persistent task lifecycle -> Lists -> Progress -> Calendar -> Reminders -> Widgets -> QA. Track every limitation in QA_REPORT.md.


## Complete Claude Code setup (2026-11-03)
This kit adds 10 specialized skills in `.claude/skills/` (17 skills total, including the 7 original) and five focused agents in `.claude/agents/`. Read `CLAUDE_OPUS_5_5_COMPLETE_IMPLEMENTATION_PROMPT.md` first; retain earlier specifications and assets. Delegate selectively, never run agents just for the sake of agent count. Three top-level tabs only: Today, Lists, Progress. Native SwiftUI, offline-first, working reminders within iOS limitations.
