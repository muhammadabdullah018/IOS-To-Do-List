---
name: pixel-art-visual-system
description: Create consistent pixel-cloud backgrounds, color tokens, original 8-bit decoration, and tasteful iOS motion.
---

# Pixel sky design system
Palette: #0593C6 blue, #FCFFFF white, #D83995 hot pink. Supporting: #12364A deep navy, #EAF8FD pale blue, #DDF5FE cloud blue, #628092 muted.
- Sky header backgrounds can use layered pale blue gradients with small stepped cloud silhouettes rendered at whole-number pixel increments. Avoid interpolation blur on pixel graphics.
- Decorative pixel stars: 4–8px grid; at most 3–5 per viewport. Do not create repetitive background clutter.
- Text never overlaps high-frequency ornament. Place tappable content on stable opaque cards/surfaces.
- Functional card radii 16–24pt; illustrations squared off; avoid rounding individual pixels.
- Sky Blue is task/action brand; White is readability; Hot Pink is streak/celebration highlight.
- Motion: 180–280ms completion/checkmark transitions; subtle spring and haptics; respect Reduce Motion. No perpetual animated backgrounds on every screen.
- Iconography original small sprite/cloud/check illustrations; SF Symbols for functional controls.
- Dark appearance must have real contrast if enabled; never simply invert art backgrounds.
Deliver: semantic tokens, illustration components, background variants per screen, and screenshot reviews.

---
## Relationship to the specialized skills (added 2026-11-03, original text above unchanged)
This original skill is kept for backward compatibility. For new work prefer **pixel-art-design-system**, which carries the same intent with project-specific procedures, file paths and validation steps. If the two ever disagree, the specialized skill wins (it reflects the code as built). See `.claude/SKILLS_INVENTORY.md`.
