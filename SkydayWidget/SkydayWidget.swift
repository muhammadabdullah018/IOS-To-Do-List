import WidgetKit
import SwiftUI
import SkydayKit

// Widgets are snapshots, not live views. The app rewrites `widget-snapshot.json` in the
// App Group and asks WidgetKit to reload after every change; WidgetKit decides when the
// reload actually happens. A second timeline entry at midnight switches to the snapshot's
// precomputed "tomorrow" so the date never shows stale after midnight.

struct SkydayEntry: TimelineEntry {
    let date: Date
    let day: WidgetSnapshot.Day
    let streak: Int
    let goal: Int
    let completions: Int
    let isPlaceholder: Bool
}

struct SkydayProvider: TimelineProvider {
    func placeholder(in context: Context) -> SkydayEntry {
        SkydayEntry(date: Date(), day: WidgetSnapshot.placeholder.today, streak: 3, goal: 3, completions: 1, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SkydayEntry) -> Void) {
        completion(entries(now: Date()).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SkydayEntry>) -> Void) {
        let now = Date()
        let list = entries(now: now)
        // Ask to be refreshed after midnight; the app also reloads on every change.
        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(for: now.addingTimeInterval(86_400))
        completion(Timeline(entries: list, policy: .after(nextMidnight.addingTimeInterval(60))))
    }

    private func entries(now: Date) -> [SkydayEntry] {
        let calendar = Calendar.current
        guard let snapshot = loadSnapshot() else {
            return [SkydayEntry(date: now, day: WidgetSnapshot.Day(day: DayKey(now, calendar: calendar), done: 0, planned: 0, upNext: []),
                                streak: 0, goal: AppSettings.defaultGoal, completions: 0, isPlaceholder: false)]
        }
        var result: [SkydayEntry] = []
        if let today = snapshot.day(for: now, calendar: calendar) {
            let isToday = today.day == snapshot.today.day
            result.append(SkydayEntry(date: now, day: today, streak: snapshot.streak, goal: snapshot.goal,
                                      completions: isToday ? snapshot.todayCompletions : 0, isPlaceholder: false))
        }
        let midnight = calendar.startOfDay(for: now.addingTimeInterval(86_400))
        if let tomorrow = snapshot.day(for: midnight, calendar: calendar), tomorrow.day != result.first?.day.day {
            // After midnight the streak shown is the carried-over streak (today not yet counted).
            result.append(SkydayEntry(date: midnight, day: tomorrow, streak: snapshot.streak, goal: snapshot.goal,
                                      completions: 0, isPlaceholder: false))
        }
        if result.isEmpty {
            result.append(SkydayEntry(date: now, day: WidgetSnapshot.Day(day: DayKey(now, calendar: calendar), done: 0, planned: 0, upNext: []),
                                      streak: snapshot.streak, goal: snapshot.goal, completions: 0, isPlaceholder: false))
        }
        return result
    }

    private func loadSnapshot() -> WidgetSnapshot? {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SkydayIdentifiers.appGroup),
              let raw = try? Data(contentsOf: dir.appendingPathComponent(WidgetSnapshot.fileName)) else { return nil }
        return try? JSONFileStore.decoder().decode(WidgetSnapshot.self, from: raw)
    }
}

// MARK: - Views

private enum WColor {
    static let sky = Color(red: 5 / 255, green: 147 / 255, blue: 198 / 255)
    static let deepSky = Color(red: 4 / 255, green: 121 / 255, blue: 165 / 255)
    static let pink = Color(red: 216 / 255, green: 57 / 255, blue: 149 / 255)
    static let ink = Color(red: 18 / 255, green: 54 / 255, blue: 74 / 255)
    static let inkSecondary = Color(red: 85 / 255, green: 115 / 255, blue: 133 / 255)
    static let page = Color(red: 252 / 255, green: 1, blue: 1)
    static let pale = Color(red: 234 / 255, green: 248 / 255, blue: 253 / 255)

    static func list(_ c: ListColor) -> Color {
        Color(red: Double((c.hex >> 16) & 0xFF) / 255, green: Double((c.hex >> 8) & 0xFF) / 255, blue: Double(c.hex & 0xFF) / 255)
    }
}

/// Tiny stepped cloud drawn with rectangles (same pixel language as the app).
private struct WidgetCloud: View {
    var body: some View {
        Canvas { context, _ in
            let rows = ["...WWWW...", ".WWWWWWWW.", "WWWWWWWWWW", ".SSSSSSSS."]
            let px: CGFloat = 3
            for (y, row) in rows.enumerated() {
                for (x, c) in row.enumerated() where c != "." {
                    let color: Color = c == "W" ? .white.opacity(0.9) : WColor.sky.opacity(0.25)
                    context.fill(Path(CGRect(x: CGFloat(x) * px, y: CGFloat(y) * px, width: px, height: px)), with: .color(color))
                }
            }
        }
        .frame(width: 30, height: 12)
    }
}

struct ProgressRing: View {
    let done: Int
    let planned: Int

    var body: some View {
        let fraction = planned == 0 ? 0 : Double(done) / Double(planned)
        ZStack {
            Circle().stroke(WColor.pale, lineWidth: 8)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(WColor.sky, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(done)").font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(WColor.ink)
                Text("of \(planned)").font(.caption2.weight(.semibold)).foregroundStyle(WColor.inkSecondary)
            }
        }
    }
}

struct SmallWidgetView: View {
    let entry: SkydayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TODAY").font(.caption2.weight(.bold)).tracking(1).foregroundStyle(WColor.inkSecondary)
                Spacer()
                WidgetCloud()
            }
            ProgressRing(done: entry.day.done, planned: entry.day.planned)
                .frame(width: 70, height: 70)
                .frame(maxWidth: .infinity)
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.caption2).foregroundStyle(WColor.pink)
                Text(entry.streak == 0 ? "Start a streak" : "\(entry.streak)-day streak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .widgetURL(DeepLink.today.url)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Skyday. \(entry.day.done) of \(entry.day.planned) tasks done today. \(entry.streak) day streak.")
    }
}

struct MediumWidgetView: View {
    let entry: SkydayEntry

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY").font(.caption2.weight(.bold)).tracking(1).foregroundStyle(WColor.inkSecondary)
                ProgressRing(done: entry.day.done, planned: entry.day.planned)
                    .frame(width: 64, height: 64)
                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(WColor.pink)
                    Text("\(entry.streak)d").font(.caption.weight(.bold)).foregroundStyle(WColor.ink)
                }
                .accessibilityLabel("\(entry.streak) day streak")
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Up next").font(.headline).foregroundStyle(WColor.ink)
                    Spacer()
                    Link(destination: DeepLink.newTask.url) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(WColor.pink, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .accessibilityLabel("New task")
                }
                if entry.day.upNext.isEmpty {
                    Spacer(minLength: 0)
                    Text(entry.day.planned == 0 ? "A clear sky today." : "All clear. Nicely done.")
                        .font(.subheadline)
                        .foregroundStyle(WColor.inkSecondary)
                    Spacer(minLength: 0)
                } else {
                    ForEach(entry.day.upNext) { item in
                        Link(destination: DeepLink.task(item.id).url) {
                            HStack(spacing: 6) {
                                Circle().strokeBorder(item.priority == .high ? WColor.pink : WColor.sky, lineWidth: 1.5)
                                    .frame(width: 13, height: 13)
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(WColor.ink)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                if item.isOverdue {
                                    Text("late").font(.caption2.weight(.bold)).foregroundStyle(WColor.pink)
                                } else if let time = item.dueTime {
                                    Text(String(format: "%d:%02d", time.hour, time.minute))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(WColor.inkSecondary)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .widgetURL(DeepLink.today.url)
    }
}

struct SkydayWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SkydayEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium: MediumWidgetView(entry: entry)
            default: SmallWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            ZStack(alignment: .top) {
                WColor.page
                WColor.pale.frame(height: 36).frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

struct SkydayTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SkydayIdentifiers.widgetKind, provider: SkydayProvider()) { entry in
            SkydayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Today's progress, your streak and what's up next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SkydayWidgetBundle: WidgetBundle {
    var body: some Widget {
        SkydayTodayWidget()
    }
}
