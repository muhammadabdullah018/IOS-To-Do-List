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
| `ink` / `inkSecondary` | #12364A / #557385 (night: #FCFFFF / #9DB4C3) | text on canvas/surfaces |
| `canvas`, `raised`, `raisedHigh` | #0B1620, #16252F, #1F313D | v2 night canvas, pills, tab bar |
| `cardInk` / `cardInkSecondary` | #0B1B26 / #34505F | text on bright cards. **cardInkSecondary only on pastels** (2.4:1 on the sky hero) |
| `skyPastel`, `pinkPastel`, `cloudPastel`, `pastel(listColor)` | derived | task and list card fills (list colour mixed 28% into white) |
| `border`, `surfaceSunken`, `skySoft`, `pinkSoft`, `track` | derived tints | structure only |

Why derived shades exist: white text on #0593C6 is 3.5:1 and #D83995 on white is 4.2:1, which fails WCAG AA for small text. The brand hue stays on large or non-text elements.

## Pixel art rules
1. Sprites are character grids in `Sprite` (one char = one art pixel). Add new art there, never as random code.
2. Render only through `PixelSprite`: pixel size is snapped to whole device pixels and horizontal runs are merged into single rects, so there's no blur and no seams. Never `.scaleEffect` a sprite. Change `pixel:` instead.
3. One pixel scale per context: header clouds 3–4pt, badges 4pt, empty-state 5pt.
4. Square edges on art, rounded corners on UI. Never round a sprite.
5. Max 3 clouds + 4 twinkles per viewport (Today); Lists 1 cloud; Progress 2 clouds + one faint pink star.
6. Art sits in negative space (upper right). Text never overlaps sprites; text over tint must sit on an opaque card.

## Layout language (v2, user-directed)
Night canvas + one bright `HeroCard` per tab + dark `StatusPill`s + big pastel `TaskCard`/`ListCard`s + `FloatingTabBar` (`Skyday/DesignSystem/Cards.swift`).
- Today hero = exact brand **Sky Blue** with cardInk text and drifting white pixel clouds. Lists hero = skyPastel, no clouds. Progress hero = pinkPastel (pink owns milestones).
- Clouds live only in the hero's reserved **96pt art strip** left of the avatar/action (`HeroCard.artStrip`). Text in that row pads by the strip, so art never sits under text. Clouds hide at accessibility text sizes.
- The app runs in its night appearance (`.preferredColorScheme(.dark)` in `RootView`). To bring back light mode, remove that line; every token still has a light value.
- Previews: `python3 Tools/render_today_preview.py` (approximate Pillow render) and `Tools/render_design_sheet.py` (tokens + contrast + sprites).

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
