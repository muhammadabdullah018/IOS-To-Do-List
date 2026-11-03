import SwiftUI
import SkydayKit

// v2 layout language: night canvas, one bright hero card per tab, dark status pills,
// big pastel cards for tasks and lists, and a floating capsule tab bar.

// MARK: - Hero card

/// Large bright card at the top of each tab. Pixel clouds live in a reserved 96pt strip at
/// the top-right, left of the 46pt avatar/action. Text in that row must leave the strip free
/// (see `HeroCard.artStrip`), so art never sits under text.
struct HeroCard<Content: View>: View {
    var fill: Color = SkyColor.sky
    var clouds = true
    @ViewBuilder var content: () -> Content

    /// Width reserved for art in the top row (cloud strip); text in the first row should use
    /// `.padding(.trailing, HeroCard.artStrip)` when clouds are on.
    static var artStrip: CGFloat { 96 }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            content()
        }
        .padding(Space.lg)
        .padding(.top, Space.xxs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            ZStack(alignment: .topTrailing) {
                fill
                if clouds { HeroClouds().padding(.top, 22).padding(.trailing, Space.lg + 46 + Space.xs) }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
    }
}

/// Two small clouds and a twinkle that step sideways by whole points (8-bit motion).
/// Static under Reduce Motion or when the app isn't active.
struct HeroClouds: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                EmptyView() // large text needs the space; art is decorative
            } else if reduceMotion || scenePhase != .active {
                art(step: 0)
            } else {
                TimelineView(.periodic(from: .now, by: 0.5)) { context in
                    art(step: Int(context.date.timeIntervalSinceReferenceDate * 2))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func art(step: Int) -> some View {
        // One cloud drifting inside the strip, one twinkle. Strip width = HeroCard.artStrip - 8.
        let offset = CGFloat(pingPong(step: step, span: 6))
        return ZStack(alignment: .topTrailing) {
            PixelSprite(sprite: Sprite.cloudSmall, pixel: 3,
                        palette: PixelPalette(colors: ["W": Color.white.opacity(0.92), "S": Color.white.opacity(0.45)]))
                .offset(x: -offset, y: 6)
            PixelSprite(sprite: Sprite.twinkle, pixel: 2, palette: PixelPalette(colors: ["T": Color.white]))
                .opacity((step / 3) % 3 == 0 ? 0.35 : 0.9)
                .offset(x: -74, y: 0)
        }
        .frame(width: HeroCard<EmptyView>.artStrip - 8, height: 30, alignment: .topTrailing)
        .clipped()
    }

    private func pingPong(step: Int, span: Int) -> Int {
        let t = (step / 3) % (span * 2)
        return t <= span ? t : span * 2 - t
    }
}

// MARK: - Avatar

/// Local, account-free avatar: the first initial on a pixel-trimmed tile, or a pixel cloud.
struct PixelAvatar: View {
    let name: String
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle().fill(SkyColor.cardInk)
            if let initial = name.trimmingCharacters(in: .whitespaces).first {
                Text(String(initial).uppercased())
                    .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                    .foregroundStyle(SkyColor.skyPastel)
            } else {
                PixelSprite(sprite: Sprite.cloudMini, pixel: 2)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 2))
    }
}

/// Dark circular action button that sits on bright cards (44pt+).
struct InkCircleButton: View {
    let systemImage: String
    let label: String
    var size: CGFloat = 46
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(SkyColor.onCanvas)
                .frame(width: size, height: size)
                .background(SkyColor.cardInk, in: Circle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.92))
        .accessibilityLabel(label)
    }
}

/// Thin capsule progress bar drawn in card ink.
struct InkProgressBar: View {
    let fraction: Double
    var height: CGFloat = 10
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(SkyColor.cardInk.opacity(0.14))
                Capsule()
                    .fill(SkyColor.cardInk)
                    .frame(width: max(fraction > 0 ? height : 0, geo.size.width * min(1, fraction)))
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : Motion.progress, value: fraction)
    }
}

// MARK: - Status pills

/// Dark pill with a tinted icon circle, a value and a caption ("3 · To do").
struct StatusPill<Icon: View>: View {
    let value: String
    let caption: String
    let tint: Color
    let action: () -> Void
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.xs) {
                Circle()
                    .fill(tint)
                    .frame(width: 40, height: 40)
                    .overlay(icon())
                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(SkyColor.onCanvas)
                        .contentTransition(.numericText())
                    Text(caption)
                        .font(SkyFont.caption)
                        .foregroundStyle(SkyColor.onCanvasSecondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(Space.xxs + 2)
            .padding(.trailing, Space.xs)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(SkyColor.raised, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption), \(value)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Chips on cards

struct CardChip: View {
    let text: String
    var systemImage: String?
    /// Filled variant for overdue / warnings (white on deep pink, 5.8:1).
    var filled = false

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).imageScale(.small) }
            Text(text)
        }
        .font(.system(.caption, weight: .semibold))
        .lineLimit(1)
        .padding(.horizontal, Space.sm)
        .padding(.vertical, 6)
        .foregroundStyle(filled ? Color.white : SkyColor.cardInk)
        .background {
            if filled {
                Capsule().fill(Color(hex: 0xB8287C))
            } else {
                Capsule().strokeBorder(SkyColor.cardInk.opacity(0.55), lineWidth: 1)
            }
        }
    }
}

// MARK: - Big task card

/// The large pastel task card used for "Today tasks". Tapping the card opens the task;
/// the dark circle completes it. The two controls are siblings, never nested buttons.
struct TaskCard: View {
    let model: TaskRowModel
    let onToggle: () -> Void
    let onOpen: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var fill: Color { model.list.map { SkyColor.pastel($0.color) } ?? SkyColor.skyPastel }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Space.sm) {
                    HStack(spacing: Space.xs) {
                        CardChip(text: statusText, systemImage: model.isOverdue ? "exclamationmark" : nil,
                                 filled: model.isOverdue && !model.isDone)
                        if model.task.isRecurring { CardChip(text: "Repeats", systemImage: "repeat") }
                        Spacer(minLength: 0)
                        PriorityMark(priority: model.task.priority, onCard: true)
                    }

                    Text(model.task.title)
                        .font(SkyFont.cardTitle2)
                        .foregroundStyle(SkyColor.cardInk)
                        .strikethrough(model.isDone, color: SkyColor.cardInk)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(SkyFont.meta)
                            .foregroundStyle(SkyColor.cardInkSecondary)
                            .lineLimit(2)
                    }

                    if !model.task.subtasks.isEmpty {
                        let p = model.task.subtaskProgress
                        HStack(spacing: Space.xs) {
                            InkProgressBar(fraction: Double(p.done) / Double(max(p.total, 1)), height: 6)
                            Text("\(p.done)/\(p.total)")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(SkyColor.cardInk)
                        }
                        .padding(.trailing, 64)
                    }

                    HStack(spacing: Space.xs) {
                        if model.task.hasReminder { CardChip(text: "Reminder", systemImage: "bell.fill") }
                        if let list = model.list { CardChip(text: list.name, systemImage: list.icon) }
                    }
                    .padding(.trailing, 64)
                }
                .padding(Space.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.98))
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint("Opens the task")

            completeButton
                .padding(Space.md)
        }
        .background(fill, in: RoundedRectangle(cornerRadius: Radius.bigCard, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var completeButton: some View {
        Button(action: onToggle) {
            ZStack {
                Circle().fill(model.isDone ? SkyColor.sky : SkyColor.cardInk)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(model.isDone ? SkyColor.cardInk : SkyColor.onCanvas.opacity(0.9))
                    .scaleEffect(model.isDone && !reduceMotion ? 1.15 : 1)
            }
            .frame(width: 52, height: 52)
            .animation(reduceMotion ? .easeInOut(duration: 0.12) : Motion.check, value: model.isDone)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.9))
        .disabled(model.isProjection)
        .accessibilityLabel(model.isDone ? "Reopen \(model.task.title)" : "Complete \(model.task.title)")
    }

    private var statusText: String {
        let day = model.displayDay ?? model.task.dueDay
        var parts: [String] = []
        if let day {
            if model.isOverdue && day < model.today {
                parts.append("Overdue · \(RelativeDayFormatter.string(for: day, today: model.today))")
            } else {
                parts.append(RelativeDayFormatter.string(for: day, today: model.today))
            }
        } else {
            parts.append("No date")
        }
        if let time = model.task.dueTime { parts.append(Format.time(time)) }
        return parts.joined(separator: " · ")
    }

    private var subtitle: String? {
        let notes = model.task.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return notes.isEmpty ? nil : notes
    }

    private var accessibilitySummary: String {
        var parts = [model.task.title, statusText]
        if let list = model.list { parts.append(list.name) }
        if model.task.priority != .none { parts.append("\(model.task.priority.label) priority") }
        if !model.task.subtasks.isEmpty {
            let p = model.task.subtaskProgress
            parts.append("\(p.done) of \(p.total) subtasks")
        }
        if model.isDone { parts.append("completed") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Floating tab bar

/// Exactly three tabs in a floating capsule, plus the pink quick-add button.
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    let onAdd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Space.sm) {
            HStack(spacing: Space.xxs) {
                tab(.today, "Today", "sun.max.fill", id: "tabToday")
                tab(.lists, "Lists", "square.stack.fill", id: "tabLists")
                tab(.progress, "Progress", "chart.bar.fill", id: "tabProgress")
            }
            .padding(6)
            .background(SkyColor.raisedHigh.opacity(0.97), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.07), lineWidth: 1))

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 62, height: 62)
                    .background(SkyColor.pink, in: Circle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))
            .accessibilityLabel("New task")
            .accessibilityIdentifier("addTaskButton")
        }
        .shadow(color: SkyColor.shadow, radius: 18, x: 0, y: 10)
    }

    private func tab(_ tab: AppTab, _ title: String, _ symbol: String, id: String) -> some View {
        let isSelected = selection == tab
        return Button {
            if selection != tab { Haptics.selection() }
            withAnimation(reduceMotion ? nil : Motion.settle) { selection = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                if isSelected && !dynamicTypeSize.isAccessibilitySize {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .foregroundStyle(isSelected ? SkyColor.cardInk : SkyColor.onCanvasSecondary)
            .padding(.horizontal, isSelected ? Space.md : 0)
            .frame(minWidth: 50, minHeight: 50)
            .background {
                if isSelected { Capsule().fill(SkyColor.sky) }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(id)
    }
}
