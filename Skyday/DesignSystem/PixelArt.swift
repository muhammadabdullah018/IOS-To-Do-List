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
            "....BBB..",
            "..BBB....",
            ".BBB.....",
            ".BBB.....",
            "BBBB.....",
            ".BBB.....",
            ".BBBB....",
            "..BBBBB..",
            "....BBB.."
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
