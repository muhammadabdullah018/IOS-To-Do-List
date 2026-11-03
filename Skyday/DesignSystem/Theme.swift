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
    // Brand
    static let sky = Color(hex: 0x0593C6)
    static let white = Color(hex: 0xFCFFFF)
    static let pink = Color(hex: 0xD83995)

    // Derived for accessibility
    static let deepSky = Color.dynamic(light: 0x0479A5, dark: 0x4CC3EE)
    static let pinkText = Color.dynamic(light: 0xB8287C, dark: 0xF07BBE)

    // Neutrals
    static let ink = Color.dynamic(light: 0x12364A, dark: 0xEAF6FC)
    static let inkSecondary = Color.dynamic(light: 0x557385, dark: 0x9DB9C9)
    static let page = Color.dynamic(light: 0xFCFFFF, dark: 0x0A1924)
    static let surface = Color.dynamic(light: 0xFFFFFF, dark: 0x11283A)
    static let surfaceSunken = Color.dynamic(light: 0xEAF8FD, dark: 0x0E2231)
    static let border = Color.dynamic(light: 0xDDECF4, dark: 0x1F3D51)
    static let pinkSoft = Color.dynamic(light: 0xFBE6F2, dark: 0x3A1730)
    static let skySoft = Color.dynamic(light: 0xDDF5FE, dark: 0x123A55)
    static let track = Color.dynamic(light: 0xDDECF4, dark: 0x22445A)

    /// Progress card fill. White small text on brand #0593C6 is only 3.5:1, so the card body
    /// uses deep sky (4.9:1) and the exact brand Sky Blue appears in its stepped pixel horizon.
    static let progressCard = Color.dynamic(light: 0x0479A5, dark: 0x0A5F82)

    // Sky bands (stepped pixel horizon), top to bottom.
    static let skyBands: [Color] = [
        .dynamic(light: 0xCDEFFC, dark: 0x0B2A40),
        .dynamic(light: 0xD8F3FD, dark: 0x0C2638),
        .dynamic(light: 0xE2F6FD, dark: 0x0C2233),
        .dynamic(light: 0xEBF9FE, dark: 0x0B1F2E),
        .dynamic(light: 0xF3FCFE, dark: 0x0B1C29),
        .dynamic(light: 0xFCFFFF, dark: 0x0A1924)
    ]

    static let cloud = Color.dynamic(light: 0xFFFFFF, dark: 0x2B4B62)
    static let cloudShade = Color.dynamic(light: 0xC6E8F6, dark: 0x1D3A4F)
    static let twinkle = Color.dynamic(light: 0x7FCBE8, dark: 0xF3FBFF)

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
    static let card: CGFloat = 22
    static let row: CGFloat = 18
    static let tile: CGFloat = 14
    static let small: CGFloat = 10
}

enum SkyFont {
    /// "TUESDAY, NOV 3" overline.
    static let overline = Font.system(.footnote, design: .default, weight: .semibold)
    static let hero = Font.system(.largeTitle, design: .rounded, weight: .bold)
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
            .shadow(color: Color(hex: 0x0593C6, alpha: 0.06), radius: 12, x: 0, y: 6)
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
