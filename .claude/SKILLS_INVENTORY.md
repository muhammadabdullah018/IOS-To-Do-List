# Skyday skill & agent inventory

Verified on 2026-11-03: all 17 `SKILL.md` files have valid YAML frontmatter whose `name` matches the folder, and every skill an agent references exists.

## Project skills (`.claude/skills/<name>/SKILL.md`)

### Specialized skills (prefer these for new work)
| Skill | Main responsibility | Use when | Supersedes | Agents |
|---|---|---|---|---|
| premium-ios-uiux | Screen hierarchy, navigation, states, accessibility, responsive layout | Designing/reviewing any screen or sheet | ios-uiux-designer | design-director |
| pixel-art-design-system | Exact palette, derived accessible shades, sprites, sky backgrounds, icon | Colours, art, backgrounds, assets | pixel-art-visual-system | design-director, motion-specialist |
| swiftui-engineering | Module boundaries, store/router, navigation, concurrency, verification commands | Any Swift code change | ios-swiftui-architecture (code half) | ios-architect |
| ios-motion-animation | Motion inventory, haptics, Reduce Motion | Animations, transitions, haptics | ios-motion-and-widgets (motion half) | motion-specialist, design-director |
| task-management-engine | Task/list/subtask/recurrence invariants, queries, undo | Task or list behaviour | task-domain-engine (task half) | product-engineer, ios-architect |
| streak-gamification | Streak policy (9 rules), goals, milestones, badges | Progress, streaks, rewards | task-domain-engine (streak half) | product-engineer |
| notification-reminder-engine | Planning, stable IDs, diffing, 64-cap, permissions, actions | Reminders or digests | notification-reliability | product-engineer, qa-reviewer |
| ios-data-persistence | JSON document store, atomic writes, migration, quarantine, backup | Models, load/save, backup | ios-swiftui-architecture (persistence half) | ios-architect, qa-reviewer |
| ios-widgets-integration | Widget snapshot flow, timeline, deep links, App Group | Widget changes | ios-motion-and-widgets (widget half) | motion-specialist |
| ios-testing-performance | Test matrix, Linux vs macOS checks, QA reporting | Before "done", reviews, releases | ios-qa-gate | qa-reviewer |

### Original skills (preserved unchanged, plus an appended pointer note)
| Skill | Responsibility | Status |
|---|---|---|
| ios-uiux-designer | Native screen design principles | Kept; superseded by premium-ios-uiux |
| pixel-art-visual-system | Palette + pixel cloud rules | Kept; superseded by pixel-art-design-system |
| ios-swiftui-architecture | SwiftUI structure, SwiftData guidance | Kept; superseded by swiftui-engineering + ios-data-persistence. Note: its SwiftData guidance was deliberately not followed for v1; see the decision record in ios-data-persistence |
| task-domain-engine | Entities, completion, streak basics | Kept; superseded by task-management-engine + streak-gamification |
| notification-reliability | Notification principles | Kept; superseded by notification-reminder-engine |
| ios-motion-and-widgets | Motion + widget principles | Kept; superseded by ios-motion-animation + ios-widgets-integration |
| ios-qa-gate | QA checklist | Kept; superseded by ios-testing-performance |

**Conflict rule:** where an original and a specialized skill disagree, the specialized skill wins, because it documents the code as built. The originals' principles were all carried forward. The only substantive divergence is persistence (SwiftData → JSON document for v1), with the reasoning recorded.

## Agents (`.claude/agents/*.md`)
| Agent | Role | Tools | Edits files? |
|---|---|---|---|
| skyday-design-director | Design review | Read, Grep, Glob | No (review only) |
| skyday-ios-architect | Structure, store API, persistence, project config | Read, Grep, Glob, Edit, Write, Bash | Yes (assigned files) |
| skyday-product-engineer | Behaviour rules + tests | Read, Grep, Glob, Edit, Write, Bash | Yes (Engine/ + Tests/) |
| skyday-motion-specialist | Motion, haptics, widget | Read, Grep, Glob, Edit, Write, Bash | Yes (PixelArt motion, SkydayWidget/) |
| skyday-qa-reviewer | Independent QA | Read, Grep, Glob, Bash | No (read + run tests) |

Read-only reviewers can't collide with implementers. Implementing agents get disjoint file ownership per task, assigned by the main session, which integrates and gives final acceptance.

## Environment skills observed in the authoring session (not part of this repo)
These were listed in the Claude Code cloud session that built Skyday. They come from installed plugins and **may not exist on your machine**. They complement, not replace, the project skills:
- `design:accessibility-review`: WCAG audit of a screen (pairs with premium-ios-uiux).
- `design:design-critique`: structured critique of screenshots.
- `design:ux-copy`: microcopy, empty states, error text.
- `anthropic-skills:ux-flow-states`: enumerating loading/empty/error states.
- `anthropic-skills:responsive-layout-qa`: layout QA across sizes.

No iOS-specific skills were found in the environment, so nothing was duplicated.
