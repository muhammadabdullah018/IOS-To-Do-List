import SwiftUI
import UIKit
import SkydayKit

// MARK: - Color tokens
//
// Brand (exact): Sky Blue #0593C6, White #FCFFFF, Hot Pink #D83995.
// Accessibility-derived shades are used ONLY where the brand hue fails WCAG AA for small text:
//   deepSky #0479A5 (4.9:1 on white) for small blue text and links,
//   pinkText #B8287C (5.8:1) for small pink text,
//   inkSecondary #557385 (5.0:1) replaces the kit's #628092 (4.2:1) for secondary text.
// Every token has a night variant so the app stays legible in system dark appearance.

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }

    /// A color that resolves differently in light and dark appearance.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

enum SkyColor {
    // Brand (exact)
    static let sky = Color(hex: 0x0593C6)
    static let white = Color(hex: 0xFCFFFF)
    static let pink = Color(hex: 0xD83995)

    // Night canvas (v2 layout: dark canvas, bright rounded cards). Contrast vs canvas:
    // onCanvas 17.6:1, onCanvasSecondary 8.4:1, deepSky(dark) 8.9:1.
    static let canvas = Color(hex: 0x0B1620)
    static let raised = Color(hex: 0x16252F)
    static let raisedHigh = Color(hex: 0x1F313D)
    static let onCanvas = Color(hex: 0xFCFFFF)
    static let onCanvasSecondary = Color(hex: 0x9DB4C3)

    // Text that sits on bright cards (hero, pastel task and list cards) in every appearance.
    // cardInk on brand Sky Blue #0593C6 is 5.0:1, so the hero keeps the exact brand fill.
    // cardInkSecondary is for PASTEL cards only (6-7:1); on the sky hero it drops to 2.4:1.
    static let cardInk = Color(hex: 0x0B1B26)
    static let cardInkSecondary = Color(hex: 0x34505F)

    // Pastel card fills derived from the brand hues.
    static let skyPastel = Color(hex: 0xCDEFFC)
    static let pinkPastel = Color(hex: 0xF9D7EA)
    static let cloudPastel = Color(hex: 0xEAF8FD)

    /// Card fill for a list: its colour mixed 28% into white (keeps cardInk ≥ 7:1).
    static func pastel(_ c: ListColor) -> Color {
        switch c {
        case .sky: return skyPastel
        case .pink: return pinkPastel
        default:
            let mix = { (v: UInt32) -> Double in (255 + (Double(v) - 255) * 0.28) / 255 }
            return Color(.sRGB, red: mix((c.hex >> 16) & 0xFF), green: mix((c.hex >> 8) & 0xFF), blue: mix(c.hex & 0xFF), opacity: 1)
        }
    }

    /// Glyph colour for a solid list tile: ink on light hues, white on dark ones (≥ 3:1 either way).
    static func glyph(on c: ListColor) -> Color {
        switch c {
        case .amber, .lagoon, .mint, .sky: return cardInk
        default: return Color.white
        }
    }

    // Derived for accessibility (small text). The app runs in its night appearance, so the
    // dark values are what users see; light values stay valid for previews and the widget.
    static let deepSky = Color.dynamic(light: 0x0479A5, dark: 0x4CC3EE)
    static let pinkText = Color.dynamic(light: 0xB8287C, dark: 0xF07BBE)
    /// Small pink text on pastel cards (5.3:1 on pinkPastel, 5.7:1 on skyPastel; 4.0 on the
    /// ink pastel, so overdue uses a filled chip instead of pink text).
    static let pinkOnCard = Color(hex: 0xA61E6E)

    // Neutrals (dark values match the canvas family)
    static let ink = Color.dynamic(light: 0x12364A, dark: 0xFCFFFF)
    static let inkSecondary = Color.dynamic(light: 0x557385, dark: 0x9DB4C3)
    static let page = Color.dynamic(light: 0xFCFFFF, dark: 0x0B1620)
    static let surface = Color.dynamic(light: 0xFFFFFF, dark: 0x16252F)
    static let surfaceSunken = Color.dynamic(light: 0xEAF8FD, dark: 0x1F313D)
    static let border = Color.dynamic(light: 0xDDECF4, dark: 0x22343F)
    static let pinkSoft = Color.dynamic(light: 0xFBE6F2, dark: 0x3A1730)
    static let skySoft = Color.dynamic(light: 0xDDF5FE, dark: 0x123A55)
    static let track = Color.dynamic(light: 0xDDECF4, dark: 0x2A3E4B)

    static let cloud = Color(hex: 0xFFFFFF)
    static let cloudShade = Color(hex: 0xC6E8F6)
    static let twinkle = Color(hex: 0xBFE9F9)
    static let shadow = Color(hex: 0x000000, alpha: 0.35)

    static func list(_ color: ListColor) -> Color { Color(hex: color.hex) }
}

// MARK: - Spacing, radii, type

enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    /// Horizontal page gutter.
    static let gutter: CGFloat = 20
}

enum Radius {
    static let hero: CGFloat = 34
    static let bigCard: CGFloat = 28
    static let card: CGFloat = 22
    static let row: CGFloat = 18
    static let tile: CGFloat = 14
    static let small: CGFloat = 10
}

enum SkyFont {
    /// "TUESDAY, NOV 3" overline.
    static let overline = Font.system(.footnote, design: .default, weight: .semibold)
    static let hero = Font.system(.largeTitle, design: .rounded, weight: .bold)
    /// Big hero headline on bright cards ("You have 3 tasks left today").
    static let headline = Font.system(.title, design: .rounded, weight: .heavy)
    static let cardTitle2 = Font.system(.title3, design: .rounded, weight: .bold)
    static let section = Font.system(.title2, design: .rounded, weight: .bold)
    static let cardTitle = Font.system(.headline, design: .rounded, weight: .semibold)
    static let rowTitle = Font.system(.body, design: .default, weight: .semibold)
    static let meta = Font.system(.subheadline)
    static let bigNumber = Font.system(.largeTitle, design: .rounded, weight: .heavy)
    static let caption = Font.system(.caption, design: .default, weight: .medium)
}

// MARK: - Shared modifiers

struct CardSurface: ViewModifier {
    var radius: CGFloat = Radius.card
    var fill: Color = SkyColor.surface

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(SkyColor.border, lineWidth: 1)
            )
            .shadow(color: SkyColor.shadow.opacity(0.4), radius: 10, x: 0, y: 6)
    }
}

extension View {
    func card(radius: CGFloat = Radius.card, fill: Color = SkyColor.surface) -> some View {
        modifier(CardSurface(radius: radius, fill: fill))
    }

    /// Uppercase tracked overline style.
    func overlineStyle(color: Color = SkyColor.inkSecondary) -> some View {
        self.font(SkyFont.overline)
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(color)
    }
}

/// Subtle press feedback for custom buttons (scale + dim), disabled under Reduce Motion.
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

enum Motion {
    /// Completion & checkbox: within the 180–280 ms band from the spec.
    static let check = Animation.spring(response: 0.26, dampingFraction: 0.72)
    static let settle = Animation.easeInOut(duration: 0.24)
    static let progress = Animation.easeOut(duration: 0.28)

    static func ifAllowed(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// MARK: - Haptics

enum Haptics {
    static func tick() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7) }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
