import SwiftUI
import SkydayKit

/// Named ProgressScreen to avoid clashing with SwiftUI.ProgressView.
struct ProgressScreen: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        let summary = store.streak
        let week = store.thisWeek
        let activity = store.activity(weeks: 5)

        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                PageHeader(overline: "Your momentum", title: "Progress", subtitle: "Keep showing up. It adds up.") {
                    HeaderIconButton(systemImage: "gearshape.fill", label: "Settings") {
                        router.present(.settings)
                    }
                    .accessibilityIdentifier("settingsButton")
                }

                StreakCard(summary: summary)
                DailyGoalCard(summary: summary) { newGoal in
                    Haptics.selection()
                    store.setDailyGoal(newGoal)
                }

                VStack(alignment: .leading, spacing: Space.sm) {
                    SectionHeader(title: "This week")
                    WeekChart(days: week, today: store.today, calendar: store.calendar)
                }

                VStack(alignment: .leading, spacing: Space.sm) {
                    SectionHeader(title: "Last 5 weeks")
                    ActivityGrid(days: activity, calendar: store.calendar)
                }

                StatsRow(summary: summary, weekTotal: week.reduce(0) { $0 + $1.completions })

                VStack(alignment: .leading, spacing: Space.sm) {
                    SectionHeader(title: "Little victories")
                    BadgeGrid(achievements: store.achievements)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.sm)
            .padding(.bottom, Space.xxl)
            .background(alignment: .top) {
                VStack(spacing: 0) {
                    SkyColor.skyBands[0].frame(height: 600)
                    SkyBackground(variant: .progress)
                }
                .offset(y: -600)
                .padding(.horizontal, -Space.gutter)
            }
        }
        .scrollIndicators(.hidden)
        .background(SkyColor.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct StreakCard: View {
    let summary: StreakEngine.Summary

    var body: some View {
        let next = AchievementEngine.nextMilestone(after: summary.current)
        let previous = AchievementEngine.streakMilestones.last { $0 <= summary.current } ?? 0
        let span = max(1, next - previous)
        let filled = summary.current - previous
        let segments = min(span, 14)
        let filledSegments = Int((Double(filled) / Double(span) * Double(segments)).rounded(.down))

        VStack(alignment: .leading, spacing: Space.md) {
            Text("Current streak").overlineStyle()
            HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                Text("\(summary.current)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(SkyColor.pink)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)
                Text(summary.current == 1 ? "day" : "days")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(SkyColor.ink)
                Spacer()
                PixelSprite(sprite: Sprite.streakStar, pixel: 5)
                    .opacity(summary.current > 0 ? 1 : 0.3)
            }

            // Stepped milestone track: one pixel block per day toward the next milestone.
            HStack(spacing: 4) {
                ForEach(0..<segments, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(i < filledSegments ? SkyColor.pink : SkyColor.pinkSoft)
                        .frame(height: 14)
                }
            }
            .accessibilityHidden(true)

            Text(milestoneText(next: next))
                .font(SkyFont.meta)
                .foregroundStyle(SkyColor.inkSecondary)
            if summary.restDayInUse {
                Label("Rest day used this week. Your streak is safe.", systemImage: "moon.zzz.fill")
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.deepSky)
            }
        }
        .padding(Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak \(summary.current) \(summary.current == 1 ? "day" : "days"). \(milestoneText(next: next))")
    }

    private func milestoneText(next: Int) -> String {
        let away = next - summary.current
        return "Next milestone: \(next) days (\(away) to go). Best: \(summary.longest)."
    }
}

struct DailyGoalCard: View {
    let summary: StreakEngine.Summary
    let onChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily goal").overlineStyle()
                    Text(summary.todayGoal == 1 ? "1 task a day" : "\(summary.todayGoal) tasks a day")
                        .font(SkyFont.cardTitle)
                        .foregroundStyle(SkyColor.ink)
                }
                Spacer()
                Stepper("Daily goal", value: Binding(get: { summary.todayGoal }, set: { onChange($0) }),
                        in: AppSettings.goalRange)
                    .labelsHidden()
                    .accessibilityLabel("Daily goal")
                    .accessibilityValue("\(summary.todayGoal) tasks")
            }
            HStack(spacing: Space.xs) {
                GoalPips(done: summary.todayCompletions, goal: summary.todayGoal)
                Text("\(min(summary.todayCompletions, summary.todayGoal)) of \(summary.todayGoal) today")
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.inkSecondary)
            }
            Text("A day counts when you finish your goal. Changes apply from today; past days keep the goal they had.")
                .font(SkyFont.caption)
                .foregroundStyle(SkyColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Space.lg)
        .card()
    }
}

struct WeekChart: View {
    let days: [StreakEngine.DayStatus]
    let today: DayKey
    let calendar: Calendar

    var body: some View {
        let maxValue = max(days.map(\.completions).max() ?? 0, days.map(\.goal).max() ?? 1, 1)
        let goal = days.first(where: { $0.day == today })?.goal ?? days.last?.goal ?? 3
        let chartHeight: CGFloat = 140

        VStack(spacing: Space.sm) {
            ZStack(alignment: .bottom) {
                // Goal line
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(SkyColor.pink.opacity(0.5))
                        .frame(height: 2)
                        .padding(.bottom, chartHeight * CGFloat(goal) / CGFloat(maxValue) - 1)
                }
                .accessibilityHidden(true)

                HStack(alignment: .bottom, spacing: Space.sm) {
                    ForEach(days) { status in
                        let h = max(6, chartHeight * CGFloat(status.completions) / CGFloat(maxValue))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(fill(for: status))
                            .frame(maxWidth: .infinity)
                            .frame(height: status.day > today ? 6 : h)
                            .accessibilityElement()
                            .accessibilityLabel(Format.longDate(status.day, calendar: calendar))
                            .accessibilityValue(status.day > today ? "Upcoming" :
                                                    "\(status.completions) done\(status.kind == .qualified ? ", goal met" : "")")
                    }
                }
            }
            .frame(height: chartHeight)

            HStack(spacing: Space.sm) {
                ForEach(days) { status in
                    Text(Format.weekdayLetter(status.day, calendar: calendar))
                        .font(SkyFont.caption)
                        .foregroundStyle(status.day == today ? SkyColor.deepSky : SkyColor.inkSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            HStack(spacing: Space.md) {
                LegendDot(color: SkyColor.deepSky, label: "Today")
                LegendDot(color: SkyColor.sky, label: "Goal met")
                LegendDot(color: SkyColor.pink.opacity(0.5), label: "Goal", isLine: true)
                Spacer()
            }
        }
        .padding(Space.lg)
        .card()
    }

    private func fill(for status: StreakEngine.DayStatus) -> Color {
        if status.day == today { return SkyColor.deepSky }
        if status.day > today { return SkyColor.track }
        return status.kind == .qualified ? SkyColor.sky : SkyColor.skySoft
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var isLine = false

    var body: some View {
        HStack(spacing: 5) {
            Rectangle()
                .fill(color)
                .frame(width: isLine ? 12 : 8, height: isLine ? 2 : 8)
            Text(label)
                .font(SkyFont.caption)
                .foregroundStyle(SkyColor.inkSecondary)
        }
    }
}

/// Five weeks of pixel tiles. Pink is reserved for qualified days (the meaningful milestone).
struct ActivityGrid: View {
    let days: [StreakEngine.DayStatus]
    let calendar: Calendar

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack(spacing: 6) {
                ForEach(days.prefix(7)) { status in
                    Text(Format.weekdayLetter(status.day, calendar: calendar))
                        .font(SkyFont.caption)
                        .foregroundStyle(SkyColor.inkSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days) { status in
                    tile(status)
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityElement()
                        .accessibilityLabel(Format.longDate(status.day, calendar: calendar))
                        .accessibilityValue(describe(status))
                }
            }
            HStack(spacing: Space.md) {
                LegendDot(color: SkyColor.pink, label: "Goal met")
                LegendDot(color: SkyColor.pinkSoft, label: "Some done")
                LegendDot(color: SkyColor.skySoft, label: "Rest day")
                Spacer()
            }
        }
        .padding(Space.lg)
        .card()
    }

    @ViewBuilder
    private func tile(_ status: StreakEngine.DayStatus) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        switch status.kind {
        case .qualified:
            shape.fill(SkyColor.pink)
        case .partial:
            shape.fill(SkyColor.pinkSoft)
        case .rest:
            shape.fill(SkyColor.skySoft).overlay(Image(systemName: "moon.fill").font(.system(size: 9)).foregroundStyle(SkyColor.deepSky))
        case .today:
            shape.fill(status.completions > 0 ? SkyColor.pinkSoft : SkyColor.surface)
                .overlay(shape.strokeBorder(SkyColor.deepSky, lineWidth: 2))
        case .missed:
            shape.strokeBorder(SkyColor.border, lineWidth: 1.5)
        case .future, .beforeHistory:
            shape.fill(SkyColor.surfaceSunken.opacity(0.6))
        }
    }

    private func describe(_ s: StreakEngine.DayStatus) -> String {
        switch s.kind {
        case .qualified: return "Goal met, \(s.completions) done"
        case .partial: return "\(s.completions) of \(s.goal) done"
        case .rest: return "Rest day"
        case .today: return "Today, \(s.completions) of \(s.goal) done"
        case .missed: return "No tasks completed"
        case .future: return "Upcoming"
        case .beforeHistory: return "Before you started"
        }
    }
}

struct StatsRow: View {
    let summary: StreakEngine.Summary
    let weekTotal: Int

    var body: some View {
        HStack(spacing: Space.sm) {
            stat(value: "\(summary.longest)", label: "Best streak")
            stat(value: "\(weekTotal)", label: "This week")
            stat(value: "\(summary.totalCompletions)", label: "All time")
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(SkyColor.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(SkyFont.caption)
                .foregroundStyle(SkyColor.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.md)
        .card(radius: Radius.row)
        .accessibilityElement(children: .combine)
    }
}

struct BadgeGrid: View {
    let achievements: [Achievement]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.sm), GridItem(.flexible(), spacing: Space.sm)], spacing: Space.sm) {
            ForEach(achievements) { a in
                VStack(alignment: .leading, spacing: Space.xs) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(a.isUnlocked ? SkyColor.pinkSoft : SkyColor.surfaceSunken)
                        .frame(width: 52, height: 52)
                        .overlay(PixelSprite(sprite: Sprite.badge(a.badge), pixel: 4, palette: a.isUnlocked ? .sky : .locked))
                    Text(a.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(a.isUnlocked ? SkyColor.ink : SkyColor.inkSecondary)
                    Text(a.detail)
                        .font(SkyFont.caption)
                        .foregroundStyle(SkyColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !a.isUnlocked {
                        Gauge(value: a.progress) { EmptyView() }
                            .gaugeStyle(.accessoryLinearCapacity)
                            .tint(SkyColor.sky)
                            .accessibilityHidden(true)
                        Text("\(a.current)/\(a.target)")
                            .font(SkyFont.caption)
                            .foregroundStyle(SkyColor.inkSecondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                .padding(Space.md)
                .card(radius: Radius.row)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(a.title). \(a.detail). \(a.isUnlocked ? "Unlocked" : "\(a.current) of \(a.target)")")
            }
        }
    }
}
