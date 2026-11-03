import SwiftUI
import SkydayKit

/// Named ProgressScreen to avoid clashing with SwiftUI.ProgressView.
struct ProgressScreen: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router

    private let headerHeight: CGFloat = 262

    var body: some View {
        let summary = store.streak
        let week = store.thisWeek
        let activity = store.activity(weeks: 5)
        let unlocked = store.achievements.filter(\.isUnlocked).count

        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SkyHeader(scene: .progress, height: headerHeight, topInset: geo.safeAreaInsets.top) {
                        VStack(spacing: 0) {
                            HStack(alignment: .top) {
                                SkyTitle(text: "Progress")
                                Spacer()
                                SkyCircleButton(systemImage: "gearshape.fill", label: "Settings") {
                                    router.present(.settings)
                                }
                                .accessibilityIdentifier("settingsButton")
                            }
                            Spacer(minLength: Space.xs)
                            Button {
                                Haptics.selection()
                                router.progressPath.append(.streaks)
                            } label: {
                                StreakBubble(summary: summary)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .accessibilityHint("Opens streaks and achievements")
                            // Leaves the floating island in the art visible under the bubble.
                            Spacer(minLength: 76)
                        }
                        .frame(height: headerHeight - Space.sm)
                    }

                    VStack(alignment: .leading, spacing: Space.lg) {
                        HStack(spacing: Space.sm) {
                            StatCard(value: "\(summary.totalCompletions)", caption: "Tasks Done") {
                                Image(systemName: "checkmark.square.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(SkyColor.sky)
                            }
                            StatCard(value: store.weekCompletionRate.map { "\(Int(($0 * 100).rounded()))%" } ?? "–",
                                     caption: "This Week") {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(SkyColor.sky)
                            }
                            StatCard(value: "\(unlocked)", caption: unlocked == 1 ? "Milestone" : "Milestones") {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(SkyColor.star)
                            }
                        }

                        VStack(alignment: .leading, spacing: Space.sm) {
                            SectionHeader(title: "Weekly Activity")
                            WeekChart(days: week, today: store.today, calendar: store.calendar)
                        }

                        DailyGoalCard(summary: summary) { newGoal in
                            Haptics.selection()
                            store.setDailyGoal(newGoal)
                        }

                        VStack(alignment: .leading, spacing: Space.sm) {
                            SectionHeader(title: "Last 5 weeks")
                            ActivityGrid(days: activity, calendar: store.calendar)
                        }

                        Button {
                            Haptics.selection()
                            router.progressPath.append(.streaks)
                        } label: {
                            HStack(spacing: Space.sm) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(SkyColor.star)
                                    .frame(width: 44, height: 44)
                                    .background(SkyColor.pinkSoft, in: RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Streak & Achievements")
                                        .font(SkyFont.cardTitle)
                                        .foregroundStyle(SkyColor.ink)
                                    Text("\(unlocked) of \(store.achievements.count) unlocked")
                                        .font(SkyFont.meta)
                                        .foregroundStyle(SkyColor.inkSecondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(.footnote, weight: .bold))
                                    .foregroundStyle(SkyColor.inkSecondary)
                            }
                            .padding(Space.md)
                            .card(radius: Radius.row)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityIdentifier("streaksButton")
                    }
                    .padding(.horizontal, Space.md)
                    .padding(.top, -26)
                    .padding(.bottom, Space.xl)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .background(SkyColor.page.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// White cloud-like bubble sitting above the floating island: flame, big streak number,
/// "Day Streak", and the next milestone.
struct StreakBubble: View {
    let summary: StreakEngine.Summary

    var body: some View {
        let next = AchievementEngine.nextMilestone(after: summary.current)
        VStack(spacing: 2) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(SkyColor.flame)
                Text("\(summary.current)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(SkyColor.ink)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)
            }
            Text("Day Streak")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(SkyColor.ink)
            Text(summary.restDayInUse ? "Rest day used · streak safe" : "Next: \(next) days · Best \(summary.longest)")
                .font(SkyFont.caption)
                .foregroundStyle(SkyColor.inkSecondary)
        }
        .padding(.horizontal, Space.xl)
        .padding(.vertical, Space.sm)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .topTrailing) {
            PixelSprite(sprite: Sprite.twinkle, pixel: 2, palette: PixelPalette(colors: ["T": SkyColor.star]))
                .offset(x: -10, y: 10)
        }
        .shadow(color: Color(hex: 0x03506F, alpha: 0.18), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(summary.current) day streak. Next milestone \(next) days. Best \(summary.longest) days.")
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
                        .fill(SkyColor.inkSecondary.opacity(0.35))
                        .frame(height: 1.5)
                        .padding(.bottom, chartHeight * CGFloat(goal) / CGFloat(maxValue) - 1)
                }
                .accessibilityHidden(true)

                HStack(alignment: .bottom, spacing: Space.sm) {
                    ForEach(days) { status in
                        let h = max(6, chartHeight * CGFloat(status.completions) / CGFloat(maxValue))
                        RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
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
                LegendDot(color: SkyColor.sky, label: "Goal met")
                LegendDot(color: Color(hex: 0x9ED8F2), label: "Some done")
                LegendDot(color: SkyColor.pink, label: "Today")
                Spacer()
            }
        }
        .padding(Space.lg)
        .card()
    }

    private func fill(for status: StreakEngine.DayStatus) -> Color {
        if status.day == today { return SkyColor.pink }
        if status.day > today { return SkyColor.track }
        return status.kind == .qualified ? SkyColor.sky : Color(hex: 0x9ED8F2)
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
                LegendDot(color: SkyColor.sky, label: "Goal met")
                LegendDot(color: Color(hex: 0x9ED8F2), label: "Some done")
                LegendDot(color: SkyColor.lightSky, label: "Rest day")
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
            shape.fill(SkyColor.sky)
        case .partial:
            shape.fill(Color(hex: 0x9ED8F2))
        case .rest:
            shape.fill(SkyColor.skySoft).overlay(Image(systemName: "moon.fill").font(.system(size: 9)).foregroundStyle(SkyColor.deepSky))
        case .today:
            shape.fill(status.completions > 0 ? Color(hex: 0x9ED8F2) : SkyColor.surface)
                .overlay(shape.strokeBorder(SkyColor.pink, lineWidth: 2))
        case .missed:
            // Visible outline (≥ 3:1 against the card) so "missed" reads as a real state.
            shape.strokeBorder(SkyColor.inkSecondary.opacity(0.55), lineWidth: 1.5)
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
