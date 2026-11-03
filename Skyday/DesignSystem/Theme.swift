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
    // Brand palette (exact, from the Skyday sheet)
    static let sky = Color(hex: 0x0593C6)        // Sky Blue
    static let white = Color(hex: 0xFCFFFF)      // White
    static let pink = Color(hex: 0xD83995)       // Hot Pink
    static let lightSky = Color(hex: 0xD7F2FF)   // Light Sky
    static let softPink = Color(hex: 0xFFE6F4)   // Soft Pink

    // Accessibility-derived shades (small text). Brand Sky Blue on white is 3.5:1 and
    // Hot Pink 4.2:1, both below AA for small text, so small text uses these instead.
    static let deepSky = Color(hex: 0x0479A5)    // 4.9:1 on white
    static let pinkText = Color(hex: 0xB8287C)   // 5.8:1 on white, 5.0:1 on softPink

    // Neutrals
    static let ink = Color(hex: 0x12364A)            // 12.6:1
    static let inkSecondary = Color(hex: 0x557385)   // 5.0:1
    static let page = Color(hex: 0xF2FAFE)           // canvas under the sky header
    static let surface = Color.white                 // cards and rows
    static let surfaceSunken = Color(hex: 0xEAF8FD)
    static let border = Color(hex: 0xDDECF4)
    static let track = Color(hex: 0xDDECF4)
    static let pinkSoft = softPink
    static let skySoft = lightSky

    // On-illustration text (white over the sky art; ≥ 3:1 for the large greeting, plus shadow)
    static let onSky = Color.white
    static let skyTextShadow = Color(hex: 0x03506F, alpha: 0.45)

    static let cloud = Color(hex: 0xFFFFFF)
    static let cloudShade = Color(hex: 0xC6E8F6)
    static let twinkle = Color(hex: 0x7FCBE8)
    static let flame = Color(hex: 0xF2913D)
    static let star = Color(hex: 0xF5B932)

    /// Light tint used at the trailing end of a list card's gradient.
    static func tint(_ c: ListColor) -> Color {
        switch c {
        case .sky: return lightSky
        case .pink: return softPink
        default:
            let mix = { (v: UInt32) -> Double in (255 + (Double(v) - 255) * 0.18) / 255 }
            return Color(.sRGB, red: mix((c.hex >> 16) & 0xFF), green: mix((c.hex >> 8) & 0xFF), blue: mix(c.hex & 0xFF), opacity: 1)
        }
    }

    static func list(_ color: ListColor) -> Color { Color(hex: color.hex) }

    /// Glyph colour on a solid list tile: ink on light hues, white on dark ones (≥ 3:1).
    static func glyph(on c: ListColor) -> Color {
        switch c {
        case .amber, .lagoon, .mint, .sky: return ink
        default: return Color.white
        }
    }
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
    static let row: CGFloat = 16
    static let tile: CGFloat = 14
    static let small: CGFloat = 10
}

enum SkyFont {
    /// "TUESDAY, NOV 3" overline.
    static let overline = Font.system(.footnote, design: .default, weight: .semibold)
    static let hero = Font.system(.largeTitle, design: .rounded, weight: .bold)
    /// Greeting / screen title drawn over the sky illustration.
    static let skyTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
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
            .shadow(color: Color(hex: 0x0593C6, alpha: 0.08), radius: 10, x: 0, y: 4)
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

    /// UI tests turn decorative motion off so taps never land on a half-faded element.
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
}

/// Cards rise into place one after another the first time a list appears.
/// Reduce Motion (and UI tests) show them immediately.
struct StaggeredAppear: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = Motion.isUITesting

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .scaleEffect(shown ? 1 : 0.98, anchor: .top)
            .onAppear {
                guard !shown else { return }
                if reduceMotion { shown = true; return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(Double(min(index, 8)) * 0.045)) {
                    shown = true
                }
            }
    }
}

extension View {
    func staggeredAppear(_ index: Int) -> some View { modifier(StaggeredAppear(index: index)) }
}

// MARK: - Haptics

enum Haptics {
    /// Mirrors `AppSettings.haptics`; set by AppEnvironment on launch and every commit.
    @MainActor static var isEnabled = true

    @MainActor static func tick() { if isEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() } }
    @MainActor static func soft() { if isEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7) } }
    @MainActor static func success() { if isEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) } }
    @MainActor static func warning() { if isEnabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) } }
    @MainActor static func selection() { if isEnabled { UISelectionFeedbackGenerator().selectionChanged() } }
}
