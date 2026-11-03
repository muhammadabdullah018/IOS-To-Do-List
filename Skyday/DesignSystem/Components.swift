import SwiftUI
import SkydayKit

// MARK: - Checkbox

/// Large circular completion control (44pt hit area). Fills and draws its check with a
/// short spring; static cross-fade under Reduce Motion.
struct SkyCheckbox: View {
    let isOn: Bool
    var tint: Color = SkyColor.sky
    var isEnabled = true
    /// Task title, so VoiceOver says "Complete Finish lab report" rather than a bare state.
    var title: String = ""
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(isOn ? tint : SkyColor.inkSecondary.opacity(0.45), lineWidth: 2)
                    .background(Circle().fill(isOn ? tint : Color.clear))
                    .frame(width: 26, height: 26)
                CheckShape()
                    .trim(from: 0, to: isOn ? 1 : 0)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 12, height: 10)
            }
            .scaleEffect(isOn && !reduceMotion ? 1.0 : (reduceMotion ? 1 : 0.96))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .animation(reduceMotion ? .easeInOut(duration: 0.12) : Motion.check, value: isOn)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title.isEmpty ? (isOn ? "Completed" : "Not completed") : (isOn ? "Reopen \(title)" : "Complete \(title)"))
        .accessibilityValue(isOn ? "Completed" : "Not completed")
        .accessibilityAddTraits(.isButton)
    }
}

struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

// MARK: - Priority mark

/// Discreet stepped bars: 1–3 pixels high. High priority uses the pink accent.
struct PriorityMark: View {
    let priority: Priority
    /// On pastel cards the inactive steps use card ink so they stay visible.
    var onCard = false

    var body: some View {
        if priority != .none {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(1...3, id: \.self) { level in
                    Rectangle()
                        .fill(level <= priority.rawValue ? color : (onCard ? SkyColor.cardInk.opacity(0.15) : SkyColor.track))
                        .frame(width: 4, height: CGFloat(4 + level * 3))
                }
            }
            .accessibilityElement()
            .accessibilityLabel("\(priority.label) priority")
        }
    }

    private var color: Color {
        if priority == .high { return SkyColor.pink }
        return onCard ? SkyColor.cardInk : SkyColor.sky
    }
}

// MARK: - Task row

struct TaskRowModel {
    let task: TaskItem
    let list: TaskList?
    let isOverdue: Bool
    let today: DayKey
    var showDay = false
    var isProjection = false
    var displayDay: DayKey?
    var completedOverride: Bool?

    var isDone: Bool { completedOverride ?? task.isCompleted }
}

/// The shared task card used on Today, Plan and search results.
struct TaskRow: View {
    let model: TaskRowModel
    var compact = false
    let onToggle: () -> Void
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: Space.xs) {
            SkyCheckbox(isOn: model.isDone, isEnabled: !model.isProjection, title: model.task.title, action: onToggle)
                .padding(.leading, Space.xs)

            Button(action: onOpen) {
                HStack(spacing: Space.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.task.title)
                            .font(SkyFont.rowTitle)
                            .foregroundStyle(model.isDone ? SkyColor.inkSecondary : SkyColor.ink)
                            .strikethrough(model.isDone, color: SkyColor.inkSecondary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                            .multilineTextAlignment(.leading)
                        metaLine
                    }
                    Spacer(minLength: 0)
                    PriorityMark(priority: model.task.priority)
                }
                .padding(.vertical, compact ? Space.sm : Space.md)
                .padding(.trailing, Space.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: compact ? 60 : 72)
        .card(radius: Radius.row)
        .accessibilityElement(children: .contain)
    }

    private var metaLine: some View {
        // At accessibility sizes the pieces stack instead of truncating one by one.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 6))
        return layout {
            if let list = model.list {
                Circle().fill(SkyColor.list(list.color)).frame(width: 7, height: 7)
                Text(list.name)
            }
            if let when = whenText {
                Text("·")
                Text(when).foregroundStyle(model.isOverdue && !model.isDone ? SkyColor.pinkText : SkyColor.inkSecondary)
            }
            if model.task.isRecurring {
                Image(systemName: "repeat").imageScale(.small).accessibilityLabel("Repeats")
            }
            if model.task.hasReminder {
                Image(systemName: "bell.fill").imageScale(.small).accessibilityLabel("Reminder set")
            }
            if !model.task.subtasks.isEmpty {
                let p = model.task.subtaskProgress
                Label("\(p.done)/\(p.total)", systemImage: "checklist")
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel("\(p.done) of \(p.total) subtasks done")
            }
        }
        .font(SkyFont.meta)
        .foregroundStyle(SkyColor.inkSecondary)
        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
    }

    private var whenText: String? {
        let day = model.displayDay ?? model.task.dueDay
        var parts: [String] = []
        if let day {
            if model.isOverdue && day < model.today {
                parts.append(RelativeDayFormatter.string(for: day, today: model.today))
            } else if model.showDay || day != model.today {
                parts.append(RelativeDayFormatter.string(for: day, today: model.today))
            }
        }
        if let time = model.task.dueTime { parts.append(Format.time(time)) }
        if parts.isEmpty, day == model.today { parts.append("Today") }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

// MARK: - Formatting helpers

enum Format {
    static func time(_ t: TimeOfDay) -> String {
        var comps = DateComponents()
        comps.hour = t.hour
        comps.minute = t.minute
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    static func overlineDate(_ day: DayKey, calendar: Calendar) -> String {
        day.noonDate(in: calendar).formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    static func longDate(_ day: DayKey, calendar: Calendar) -> String {
        day.noonDate(in: calendar).formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    static func weekdayLetter(_ day: DayKey, calendar: Calendar) -> String {
        day.noonDate(in: calendar).formatted(.dateTime.weekday(.narrow))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailing: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(SkyFont.section)
                .foregroundStyle(SkyColor.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing, let trailingAction {
                Button(trailing, action: trailingAction)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(SkyColor.deepSky)
                    .frame(minHeight: 44)
            }
        }
    }
}

// MARK: - Chips

struct Chip: View {
    let title: String
    var systemImage: String?
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage).imageScale(.small) }
                Text(title)
            }
            .font(.system(.subheadline, weight: .semibold))
            .padding(.horizontal, Space.md)
            .frame(minHeight: 44)
            .foregroundStyle(isSelected ? Color.white : SkyColor.deepSky)
            .background(isSelected ? SkyColor.deepSky : SkyColor.surfaceSunken, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - List icon tile

struct ListIconTile: View {
    let list: TaskList
    var size: CGFloat = 48

    var body: some View {
        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
            .fill(SkyColor.list(list.color))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: list.icon)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(SkyColor.glyph(on: list.color))
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Empty state

struct EmptySkyState: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Space.md) {
            PixelSprite(sprite: Sprite.cloudCheck, pixel: 5, palette: PixelPalette.sky.with("W", SkyColor.skySoft).with("S", SkyColor.border))
                .padding(.top, Space.sm)
            VStack(spacing: 6) {
                Text(title)
                    .font(SkyFont.cardTitle)
                    .foregroundStyle(SkyColor.ink)
                Text(message)
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .padding(.horizontal, Space.lg)
                        .frame(minHeight: 48)
                        .foregroundStyle(Color.white)
                        .background(SkyColor.deepSky, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityIdentifier("emptyStateAddButton")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Space.xl)
        .card()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Undo toast

struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Space.sm) {
            Text(message)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Color.white)
                .lineLimit(2)
            Spacer(minLength: Space.xs)
            Button("Undo", action: onUndo)
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(SkyColor.skyPastel)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("undoButton")
        }
        .padding(.leading, Space.md)
        .padding(.trailing, Space.xs)
        .background(SkyColor.raisedHigh, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: SkyColor.shadow, radius: 14, x: 0, y: 8)
        .padding(.horizontal, Space.md)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Page header

struct PageHeader<Trailing: View>: View {
    let overline: String
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(overline).overlineStyle()
                Text(title)
                    .font(SkyFont.hero)
                    .foregroundStyle(SkyColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.system(.body))
                    .foregroundStyle(SkyColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Space.sm)
            trailing()
        }
    }
}

/// White circular header button (44pt).
struct HeaderIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(SkyColor.deepSky)
                .frame(width: 44, height: 44)
                .background(SkyColor.surface.opacity(0.92), in: Circle())
                .overlay(Circle().strokeBorder(SkyColor.border, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.92))
        .accessibilityLabel(label)
    }
}
