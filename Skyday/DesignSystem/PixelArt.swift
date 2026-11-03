import SwiftUI
import SkydayKit

// MARK: - Sprites
//
// Original Skyday sprites, authored as character grids. One character = one art pixel.
// Rendered as merged rectangles snapped to the device pixel grid, so edges stay sharp at
// every scale (no interpolation, no image assets to license).

struct PixelSpriteData: Hashable {
    let rows: [String]
    var width: Int { rows.map(\.count).max() ?? 0 }
    var height: Int { rows.count }
}

enum Sprite {
    static let cloudLarge = PixelSpriteData(rows: [
        "...........WWWWWW...........",
        ".........WWWWWWWWWW.........",
        "....WWWW.WWWWWWWWWWW........",
        "...WWWWWWWWWWWWWWWWWW.WWW...",
        "..WWWWWWWWWWWWWWWWWWWWWWWW..",
        ".WWWWWWWWWWWWWWWWWWWWWWWWWW.",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        ".SSSSSSSSSSSSSSSSSSSSSSSSSS.",
        "...SSSSSSSSSSSSSSSSSSSSSS..."
    ])

    static let cloudSmall = PixelSpriteData(rows: [
        ".....WWWW.....",
        "...WWWWWWW....",
        ".WWWWWWWWWWWW.",
        "WWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWW",
        ".SSSSSSSSSSSS."
    ])

    static let cloudMini = PixelSpriteData(rows: [
        "...WWW...",
        ".WWWWWWW.",
        "WWWWWWWWW",
        ".SSSSSSS."
    ])

    static let twinkle = PixelSpriteData(rows: [
        ".T.",
        "TTT",
        ".T."
    ])

    static let streakStar = PixelSpriteData(rows: [
        "...P...",
        "...P...",
        "..PPP..",
        "PPPPPPP",
        "..PPP..",
        "...P...",
        "...P..."
    ])

    /// Empty-state motif: a cloud carrying a check mark.
    static let cloudCheck = PixelSpriteData(rows: [
        "..........WWWWWW..........",
        "........WWWWWWWWWW........",
        "...WWWW.WWWWWWWWWWW.......",
        "..WWWWWWWWWWWWWWWWWW.WWW..",
        ".WWWWWWWWWWWWWWWWBBWWWWWW.",
        "WWWWWWWWWWWWWWWWBBWWWWWWWW",
        "WWWWWWWBBWWWWWWBBWWWWWWWWW",
        "WWWWWWWWBBWWWWBBWWWWWWWWWW",
        "WWWWWWWWWBBWWBBWWWWWWWWWWW",
        ".WWWWWWWWWBBBBWWWWWWWWWWW.",
        "..WWWWWWWWWBBWWWWWWWWWWW..",
        "...SSSSSSSSSSSSSSSSSSSS..."
    ])

    static func badge(_ badge: Achievement.Badge) -> PixelSpriteData {
        switch badge {
        case .star: return streakStar
        case .check: return PixelSpriteData(rows: [
            "........B",
            ".......BB",
            "B.....BB.",
            "BB...BB..",
            ".BB.BB...",
            "..BBB....",
            "...B....."
        ])
        case .sun: return PixelSpriteData(rows: [
            "Y...Y...Y",
            ".Y.....Y.",
            "...YYY...",
            "..YYYYY..",
            "Y.YYYYY.Y",
            "..YYYYY..",
            "...YYY...",
            ".Y.....Y.",
            "Y...Y...Y"
        ])
        case .cloud: return PixelSpriteData(rows: [
            "...BBB...",
            "..BBBBB..",
            ".BBBBBBBB",
            "BBBBBBBBB",
            "BBBBBBBBB",
            ".DDDDDDD."
        ])
        case .moon: return PixelSpriteData(rows: [
            "..BBBB...",
            ".BBB.....",
            "BBB......",
            "BBB......",
            "BBB.....B",
            ".BBB..BB.",
            "..BBBBB.."
        ])
        case .heart: return PixelSpriteData(rows: [
            ".PP...PP.",
            "PPPP.PPPP",
            "PPPPPPPPP",
            "PPPPPPPPP",
            ".PPPPPPP.",
            "..PPPPP..",
            "...PPP...",
            "....P...."
        ])
        case .rocket: return PixelSpriteData(rows: [
            "....B....",
            "...BBB...",
            "...BWB...",
            "...BBB...",
            "..BBBBB..",
            ".B.BBB.B.",
            "...P.P...",
            "....P...."
        ])
        case .crown: return PixelSpriteData(rows: [
            "P...P...P",
            "PP.PPP.PP",
            "PPPPPPPPP",
            "PYPPYPPYP",
            "PPPPPPPPP"
        ])
        }
    }
}

/// Maps sprite characters to colors. Unknown characters and "." are transparent.
struct PixelPalette {
    var colors: [Character: Color]

    static let sky = PixelPalette(colors: [
        "W": SkyColor.cloud, "S": SkyColor.cloudShade, "T": SkyColor.twinkle,
        "B": SkyColor.sky, "D": SkyColor.deepSky, "P": SkyColor.pink, "Y": Color(hex: 0xE6A92E)
    ])

    /// Clouds drawn on top of the deep-sky progress card.
    static let onCard = PixelPalette(colors: [
        "W": Color.white.opacity(0.22), "S": Color.white.opacity(0.12), "T": Color.white.opacity(0.5),
        "B": SkyColor.sky, "P": SkyColor.pink
    ])

    static let locked = PixelPalette(colors: [
        "W": SkyColor.track, "S": SkyColor.track, "B": SkyColor.track, "D": SkyColor.track,
        "P": SkyColor.track, "Y": SkyColor.track, "T": SkyColor.track
    ])

    func with(_ char: Character, _ color: Color) -> PixelPalette {
        var copy = self
        copy.colors[char] = color
        return copy
    }
}

/// Draws a sprite crisply. `pixel` is the art-pixel size in points; it is snapped to whole
/// device pixels so adjacent pixels never show seams or blur.
struct PixelSprite: View {
    let sprite: PixelSpriteData
    var pixel: CGFloat = 3
    var palette: PixelPalette = .sky

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let px = max(1, (pixel * displayScale).rounded()) / displayScale
        Canvas(opaque: false, rendersAsynchronously: false) { context, _ in
            for (y, row) in sprite.rows.enumerated() {
                let chars = Array(row)
                var x = 0
                while x < chars.count {
                    let c = chars[x]
                    guard let color = palette.colors[c] else { x += 1; continue }
                    // Merge horizontal runs of the same character into one rect.
                    var end = x + 1
                    while end < chars.count && chars[end] == c { end += 1 }
                    let rect = CGRect(x: CGFloat(x) * px, y: CGFloat(y) * px, width: CGFloat(end - x) * px, height: px)
                    context.fill(Path(rect), with: .color(color))
                    x = end
                }
            }
        }
        .frame(width: CGFloat(sprite.width) * px, height: CGFloat(sprite.height) * px)
        .accessibilityHidden(true)
    }
}

// MARK: - Sky background

enum SkyVariant {
    case today, lists, progress

    var height: CGFloat {
        switch self {
        case .today: return 430
        case .lists: return 300
        case .progress: return 360
        }
    }
}

/// Reusable atmospheric header: stepped pixel horizon bands plus a few drifting clouds and
/// twinkles placed in the upper-right negative space, away from the title text.
/// Decorative only: never hit-testable, hidden from VoiceOver, static under Reduce Motion.
struct SkyBackground: View {
    let variant: SkyVariant
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private struct CloudPlacement: Identifiable {
        let id: Int
        let sprite: PixelSpriteData
        let pixel: CGFloat
        /// Fraction of width for the leading edge, and absolute top offset.
        let x: CGFloat
        let y: CGFloat
        /// Points moved per step; clouds move in whole steps like 8-bit sprites.
        let drift: CGFloat
        let range: CGFloat
    }

    private struct TwinklePlacement: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let phase: Int
    }

    private var clouds: [CloudPlacement] {
        switch variant {
        case .today:
            return [
                CloudPlacement(id: 0, sprite: Sprite.cloudLarge, pixel: 4, x: 0.58, y: 78, drift: 1, range: 18),
                CloudPlacement(id: 1, sprite: Sprite.cloudSmall, pixel: 3, x: 0.80, y: 150, drift: 1, range: 12),
                CloudPlacement(id: 2, sprite: Sprite.cloudMini, pixel: 3, x: 0.44, y: 36, drift: 1, range: 10)
            ]
        case .lists:
            return [CloudPlacement(id: 0, sprite: Sprite.cloudSmall, pixel: 4, x: 0.66, y: 66, drift: 0, range: 0)]
        case .progress:
            return [
                CloudPlacement(id: 0, sprite: Sprite.cloudSmall, pixel: 4, x: 0.62, y: 60, drift: 1, range: 10),
                CloudPlacement(id: 1, sprite: Sprite.cloudMini, pixel: 3, x: 0.86, y: 128, drift: 0, range: 0)
            ]
        }
    }

    private var twinkles: [TwinklePlacement] {
        switch variant {
        case .today:
            return [TwinklePlacement(id: 0, x: 0.90, y: 58, phase: 0), TwinklePlacement(id: 1, x: 0.52, y: 128, phase: 1),
                    TwinklePlacement(id: 2, x: 0.95, y: 200, phase: 2), TwinklePlacement(id: 3, x: 0.70, y: 24, phase: 1)]
        case .lists:
            return [TwinklePlacement(id: 0, x: 0.92, y: 40, phase: 0), TwinklePlacement(id: 1, x: 0.56, y: 110, phase: 1)]
        case .progress:
            return [TwinklePlacement(id: 0, x: 0.50, y: 40, phase: 0)]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .topLeading) {
                SteppedSkyBands(height: variant.height)

                if variant == .progress {
                    PixelSprite(sprite: Sprite.streakStar, pixel: 4, palette: .sky)
                        .opacity(0.35)
                        .offset(x: width - 64, y: 150)
                }

                if reduceMotion || scenePhase != .active {
                    decorations(width: width, step: 0)
                } else {
                    // Two redraws per second; offsets move in whole points (stepped motion).
                    TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                        let step = Int(timeline.date.timeIntervalSinceReferenceDate * 2)
                        decorations(width: width, step: step)
                    }
                }
            }
        }
        .frame(height: variant.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func decorations(width: CGFloat, step: Int) -> some View {
        ForEach(clouds) { cloud in
            PixelSprite(sprite: cloud.sprite, pixel: cloud.pixel)
                .offset(x: width * cloud.x + pingPong(step: step, range: cloud.range, speed: cloud.drift), y: cloud.y)
        }
        ForEach(twinkles) { t in
            PixelSprite(sprite: Sprite.twinkle, pixel: 2)
                .opacity((step / 3 + t.phase) % 3 == 0 ? 0.35 : 0.9)
                .offset(x: width * t.x, y: t.y)
        }
    }

    /// Back-and-forth whole-point offset.
    private func pingPong(step: Int, range: CGFloat, speed: CGFloat) -> CGFloat {
        guard range > 0, speed > 0 else { return 0 }
        let span = Int(range)
        let period = span * 2 * 3 // move one point every 3 ticks (1.5 s)
        let t = (step % period) / 3
        return CGFloat(t <= span ? t : span * 2 - t) * speed
    }
}

/// Horizontal bands of decreasing tint: a pixel-art horizon instead of a smooth gradient.
struct SteppedSkyBands: View {
    let height: CGFloat

    var body: some View {
        let bands = SkyColor.skyBands
        // Bands get taller toward the bottom so the fade feels atmospheric.
        let weights: [CGFloat] = [3.2, 1.4, 1.1, 0.9, 0.7, 0.7]
        let total = weights.reduce(0, +)
        VStack(spacing: 0) {
            ForEach(Array(bands.enumerated()), id: \.offset) { index, color in
                color.frame(height: height * weights[index] / total)
            }
        }
    }
}

// MARK: - Celebration

/// A one-shot burst of square pixels for meeting the daily goal. Under Reduce Motion the
/// caller shows a static glow instead.
struct PixelBurst: View {
    let start: Date
    var duration: TimeInterval = 1.1

    private struct Particle {
        let angle: Double
        let speed: Double
        let size: CGFloat
        let color: Color
    }

    private let particles: [Particle] = (0..<18).map { i in
        let colors = [SkyColor.pink, SkyColor.sky, SkyColor.pink, Color(hex: 0xFFFFFF), SkyColor.deepSky]
        return Particle(angle: Double(i) / 18 * 2 * .pi + Double(i % 3) * 0.2,
                        speed: 70 + Double((i * 37) % 50),
                        size: CGFloat(4 + (i % 3) * 2),
                        color: colors[i % colors.count])
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = min(1, timeline.date.timeIntervalSince(start) / duration)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for p in particles {
                    let dist = p.speed * t
                    let gravity = 60 * t * t
                    let x = center.x + cos(p.angle) * dist
                    let y = center.y + sin(p.angle) * dist + gravity
                    // Snap to whole points for a pixel look.
                    let rect = CGRect(x: x.rounded(), y: y.rounded(), width: p.size, height: p.size)
                    context.opacity = 1 - t
                    context.fill(Path(rect), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
