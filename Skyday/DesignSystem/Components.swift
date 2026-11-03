import SwiftUI
import SkydayKit

// MARK: - Checkbox

/// Rounded-square completion control (44pt hit area): sky outline, fills sky with a white
/// check that draws itself. Cross-fade under Reduce Motion.
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
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isOn ? tint : Color.white)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(isOn ? tint : SkyColor.sky.opacity(isEnabled ? 0.75 : 0.35), lineWidth: 2)
                CheckShape()
                    .trim(from: 0, to: isOn ? 1 : 0)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 12, height: 9)
            }
            .frame(width: 24, height: 24)
            .scaleEffect(isOn && !reduceMotion ? 1.0 : (reduceMotion ? 1 : 0.94))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .animation(reduceMotion ? .easeInOut(duration: 0.12) : Motion.check, value: isOn)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title.isEmpty ? (isOn ? "Completed" : "Not completed") : (isOn ? "Reopen \(title)" : "Complete \(title)"))
        .accessibilityValue(isOn ? "Completed" : "Not completed")
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

/// High priority = pink flag (as in the reference). Medium/low = small sky dot / nothing.
struct PriorityMark: View {
    let priority: Priority

    var body: some View {
        switch priority {
        case .high:
            Image(systemName: "flag.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SkyColor.pink)
                .accessibilityLabel("High priority")
        case .medium:
            Image(systemName: "flag")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SkyColor.deepSky)
                .accessibilityLabel("Medium priority")
        case .low, .none:
            EmptyView()
        }
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

/// The shared task row (reference style): white rounded card, square checkbox, title,
/// one subtitle line ("Due Today" in pink, a time, or the day), trailing flag or chevron.
struct TaskRow: View {
    let model: TaskRowModel
    var compact = false
    let onToggle: () -> Void
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: Space.xxs) {
            SkyCheckbox(isOn: model.isDone, isEnabled: !model.isProjection, title: model.task.title, action: onToggle)
                .padding(.leading, Space.xxs)

            Button(action: onOpen) {
                HStack(spacing: Space.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.task.title)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(model.isDone ? SkyColor.inkSecondary : SkyColor.ink)
                            .strikethrough(model.isDone, color: SkyColor.inkSecondary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                            .multilineTextAlignment(.leading)
                        if let subtitle = subtitle, !model.isDone {
                            Text(subtitle.text)
                                .font(.system(.caption, weight: subtitle.urgent ? .semibold : .regular))
                                .foregroundStyle(subtitle.urgent ? SkyColor.pinkText : SkyColor.inkSecondary)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                        }
                    }
                    Spacer(minLength: 0)
                    if !model.isDone {
                        if model.task.priority == .high || model.task.priority == .medium {
                            PriorityMark(priority: model.task.priority)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(SkyColor.inkSecondary.opacity(0.7))
                                .accessibilityHidden(true)
                        }
                    }
                }
                .padding(.vertical, compact ? Space.xs : Space.sm)
                .padding(.trailing, Space.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the task")
        }
        .frame(minHeight: compact ? 52 : 58)
        .card(radius: Radius.row)
        .accessibilityElement(children: .contain)
    }

    private struct Subtitle { let text: String; let urgent: Bool }

    /// One line, most important first: overdue / due today, then time, list and extras.
    private var subtitle: Subtitle? {
        let day = model.displayDay ?? model.task.dueDay
        var parts: [String] = []
        var urgent = false
        if let day {
            if model.isOverdue && day < model.today {
                parts.append("Overdue · \(RelativeDayFormatter.string(for: day, today: model.today))")
                urgent = true
            } else if day == model.today && model.task.dueTime == nil && !model.showDay {
                parts.append("Due Today")
                urgent = true
            } else if model.showDay || day != model.today {
                parts.append(RelativeDayFormatter.string(for: day, today: model.today))
            }
        }
        if let time = model.task.dueTime {
            parts.append(Format.time(time))
            if model.isOverdue && day == model.today { urgent = true }
        }
        if let list = model.list, model.showDay { parts.append(list.name) }
        if model.task.isRecurring { parts.append("Repeats") }
        if !model.task.subtasks.isEmpty {
            let p = model.task.subtaskProgress
            parts.append("\(p.done)/\(p.total) subtasks")
        }
        return parts.isEmpty ? nil : Subtitle(text: parts.joined(separator: " · "), urgent: urgent)
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
            PixelSprite(sprite: Sprite.emptyIsland, pixel: 5, palette: .island)
                .accessibilityHidden(true)
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
                .foregroundStyle(SkyColor.lightSky)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("undoButton")
        }
        .padding(.leading, Space.md)
        .padding(.trailing, Space.xs)
        .background(SkyColor.ink, in: Capsule())
        .shadow(color: Color.black.opacity(0.2), radius: 14, x: 0, y: 8)
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
