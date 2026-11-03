---
name: ios-motion-animation
description: Skyday motion and haptics - completion feedback, sheet and list transitions, progress animation, stepped pixel-cloud drift, goal celebration and Reduce Motion fallbacks. Use when adding or tuning any animation, transition or haptic.
---

# ios-motion-animation

## Purpose and scope
Motion that explains state changes and makes completing a task feel good, without slowing anyone down. Tokens live in `Motion` and `Haptics` (`Theme.swift`); art motion in `SkyBackground`/`PixelBurst` (`PixelArt.swift`).

## Use when
New or changed animation, transition, haptic, or celebration.

## Do not use when
Static visual changes (`pixel-art-design-system`) or layout (`premium-ios-uiux`).

## Motion inventory (as built)
| Trigger | Motion | Timing | Reduce Motion |
|---|---|---|---|
| Checkbox tap | fill + check `trim` | `Motion.check` spring 0.26s | 0.12s ease |
| Completed row (Today) | stays checked 650 ms ("lingering"), then fades/scales out while the next task slides in | `Motion.settle` 0.24s | opacity only |
| Progress card | number `.numericText()`, bar width | `Motion.progress` 0.28s | none |
| Daily goal reached | `PixelBurst` 18 square particles 1.1s + pink tile border + success haptic | once per day (`lastCelebratedDay`) | border glow only |
| Undo toast | slide up + fade | `Motion.settle` | fade |
| Sky clouds | whole-point **stepped** drift, 2 redraws/s (`TimelineView(.periodic)`) | ping-pong ±10–18pt | static; also paused when scene isn't active |
| Buttons | `PressableButtonStyle` scale 0.97 | spring 0.25 | no scale |

Haptics: `tick` (light) on complete/add, `selection` on pickers/day changes, `success` on goal reached and save, `warning` on delete/erase, `soft` on undo.

## Procedure
1. Name the state change the motion explains. If none, don't animate.
2. Pick an existing `Motion` token; add a new one only with a reason.
3. Implement with `withAnimation(reduceMotion ? nil : …)` or `.animation(_, value:)` scoped to the changing value.
4. Persistence is never delayed by animation: the store mutates first, visuals follow (see `TodayView.complete`).
5. Provide the Reduce Motion variant in the same change.

## Standards
- 180–280 ms for interaction feedback; celebrations ≤1.2 s.
- No perpetual animation except the sky drift, which is stepped, cheap (Canvas redraw twice a second) and paused when inactive or under Reduce Motion.
- Never animate on data recomputation alone (no bouncing cards on refresh).
- Haptics fire from user intents only, never from background syncs or notification actions.

## Common mistakes
- `.animation(_:)` without `value:` (deprecated, animates everything).
- Sub-pixel offsets on sprites (blurs them; use whole points).
- Repeating the celebration on every completion after the goal.
- Ignoring rapid double taps (guarded by the `lingering` check).

## Validation
Simulator with Reduce Motion on and off; rapid-tap the same checkbox 5×; complete then undo within 650 ms; background the app during the burst; Instruments → Animation Hitches on Today scroll (target: no hitches on iPhone 12-class hardware). Record what was and wasn't run.

## Output
The change, its Reduce Motion path and a validation note.

## Related
`pixel-art-design-system`, `ios-widgets-integration`. Agent: **skyday-motion-specialist**. Legacy overlap: `ios-motion-and-widgets` (motion half).
