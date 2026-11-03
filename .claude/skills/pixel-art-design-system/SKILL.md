---
name: pixel-art-design-system
description: Skyday visual identity - exact brand colors, accessible derived shades, pixel sprites, stepped sky backgrounds per screen, dark variants and asset rules. Use when adding or changing colors, sprites, badges, backgrounds, the app icon or any decorative art.
---

# pixel-art-design-system

## Purpose and scope
Keep Skyday's look consistent: modern native iOS UI with *selective* 8-bit sky art. Owns tokens in `Skyday/DesignSystem/Theme.swift`, sprites and backgrounds in `PixelArt.swift`, the app icon generator, and widget colors.

## Use when
- Adding a color, sprite, badge, background variant or decorative element.
- Reviewing contrast of text over any tinted surface.
- Touching `Assets.xcassets` (AppIcon, AccentColor, LaunchBackground).

## Do not use when
- Layout/hierarchy decisions → `premium-ios-uiux`. Animation timing → `ios-motion-animation`.

## Inputs
`references/COLOR_PALETTE.md`, `Theme.swift`, `PixelArt.swift`, `Tools/make_app_icon.py` (32×32 art grid → 1024 px nearest-neighbour; edit the grid, rerun).

## Palette (exact, do not drift)
| Token | Value | Use |
|---|---|---|
| `SkyColor.sky` | **#0593C6** | fills, icons, progress, bars, cloud on card, large type |
| `SkyColor.white` | **#FCFFFF** | page and content surfaces |
| `SkyColor.pink` | **#D83995** | streak, celebration, FAB, high priority. Nowhere else |
| `deepSky` | #0479A5 (dark #4CC3EE) | small blue text, links, selected chips, progress card body |
| `pinkText` | #B8287C (dark #F07BBE) | small pink text (overdue, warnings) |
| `ink` / `inkSecondary` | #12364A / #557385 | text |
| `border`, `surfaceSunken`, `skySoft`, `pinkSoft`, `track` | derived tints | structure only |

Why derived shades exist: white text on #0593C6 is 3.5:1 and #D83995 on white is 4.2:1, which fails WCAG AA for small text. The brand hue stays on large or non-text elements.

## Pixel art rules
1. Sprites are character grids in `Sprite` (one char = one art pixel). Add new art there, never as random code.
2. Render only through `PixelSprite`: pixel size is snapped to whole device pixels and horizontal runs are merged into single rects, so there's no blur and no seams. Never `.scaleEffect` a sprite. Change `pixel:` instead.
3. One pixel scale per context: header clouds 3–4pt, badges 4pt, empty-state 5pt.
4. Square edges on art, rounded corners on UI. Never round a sprite.
5. Max 3 clouds + 4 twinkles per viewport (Today); Lists 1 cloud; Progress 2 clouds + one faint pink star.
6. Art sits in negative space (upper right). Text never overlaps sprites; text over tint must sit on an opaque card.

## Backgrounds
`SkyBackground(variant:)` = `SteppedSkyBands` (6 bands of decreasing tint, a pixel horizon rather than a smooth gradient) + placed clouds/twinkles. Screens attach it as `.background(alignment: .top)` on scroll content with a 600pt top band so the status bar and overscroll stay sky-coloured. It is `allowsHitTesting(false)` and `accessibilityHidden(true)`. Variants: `.today` strongest, `.lists` quiet and static, `.progress` with the pink star.

## Dark appearance
Every token has a night variant (`Color.dynamic(light:dark:)`). Night sky bands are deep navy; clouds dim (#2B4B62); twinkles brighten. Never invert art.

## Common mistakes
- Using `Color(hex: 0x0593C6)` inline instead of a token.
- Pink for generic emphasis (dilutes streak meaning).
- Smooth multi-colour gradients ("random gradients" are banned).
- Licensed/stock sprites. All art must be original grids in this repo.

## Validation
- Contrast: compute or use Xcode Accessibility Inspector for any new text/background pair (≥4.5:1 small, ≥3:1 large/graphics).
- Screenshot at 2x and 3x; zoom: edges must be hard.
- Dark mode screenshot of every changed screen.

## Output
Token or sprite changes + a contrast table for new pairs + before/after screenshots (or an explicit "not verified" note if no simulator).

## Related
`premium-ios-uiux`, `ios-motion-animation`, `ios-widgets-integration` (widget uses `WColor`, the same hexes). Agents: **skyday-design-director** (review), **skyday-motion-specialist** (animated art). Legacy overlap: `pixel-art-visual-system`.
