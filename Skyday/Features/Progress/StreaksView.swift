import SwiftUI
import SkydayKit

/// Streaks & Achievements, pushed from Progress: the streak number, the milestone track
/// (next three milestones), the qualification rule, and every badge with its progress.
struct StreaksView: View {
    @Environment(SkydayStore.self) private var store

    var body: some View {
        let summary = store.streak
        let achievements = store.achievements
        let unlocked = achievements.filter(\.isUnlocked).count

        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                StreakBubble(summary: summary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Space.sm)

                MilestoneTrack(current: summary.current)

                Text(summary.todayQualified
                     ? "Today counts. Come back tomorrow to keep it going."
                     : "Finish \(summary.remainingToday) more \(summary.remainingToday == 1 ? "task" : "tasks") today to count this day. One rest day a week keeps your streak safe.")
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: Space.sm) {
                    SectionHeader(title: "Achievements \(unlocked)/\(achievements.count)")
                    BadgeGrid(achievements: achievements)
                }
            }
            .padding(.horizontal, Space.md)
            .padding(.bottom, Space.xl)
        }
        .scrollIndicators(.hidden)
        .background(SkyColor.page.ignoresSafeArea())
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Three upcoming streak milestones on a line; reached ones are pink with a check.
struct MilestoneTrack: View {
    let current: Int

    private var milestones: [Int] {
        let all = AchievementEngine.streakMilestones
        let start = all.lastIndex { $0 <= current } ?? 0
        return Array(all[start...].prefix(3))
    }

    var body: some View {
        let points = milestones
        HStack(spacing: 0) {
            ForEach(Array(points.enumerated()), id: \.element) { index, m in
                if index > 0 {
                    Rectangle()
                        .fill(current >= m ? SkyColor.pink : SkyColor.track)
                        .frame(height: 4)
                }
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(current >= m ? SkyColor.pink : SkyColor.surface)
                            .overlay(Circle().stroke(current >= m ? SkyColor.pink : SkyColor.track, lineWidth: 3))
                        Image(systemName: current >= m ? "checkmark" : "flame")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(current >= m ? Color.white : SkyColor.inkSecondary)
                    }
                    .frame(width: 32, height: 32)
                    Text("\(m)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(SkyColor.ink)
                }
            }
        }
        .padding(Space.md)
        .card(radius: Radius.row)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milestones: " + points.map { "\($0) days\(current >= $0 ? ", reached" : "")" }.joined(separator: "; "))
    }
}
