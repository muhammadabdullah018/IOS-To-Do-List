import SwiftUI
import SkydayKit

/// The primary screen. In two seconds it answers: what's due, what's next, how far along
/// am I, what's coming, and is my streak safe.
struct TodayView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Tasks just completed stay visible (checked) for a moment so the row can settle
    /// instead of vanishing under the finger. Persistence happens immediately regardless.
    @State private var lingering: [UUID: TaskItem] = [:]
    @State private var showDoneToday = false
    @State private var celebrationStart: Date?
    @State private var goalGlow = false

    var body: some View {
        let overview = store.todayOverview
        let streak = store.streak
        let today = store.today

        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    if let error = store.lastSaveError {
                        SaveErrorBanner(message: error)
                    }
                    TimelineView(.periodic(from: .now, by: 300)) { context in
                        TodayHeader(today: today, now: context.date, calendar: store.calendar, overview: overview,
                                    hasAnyTasks: !store.data.tasks.isEmpty) {
                            router.todayPath.append(.plan(today))
                        }
                    }
                    .padding(.bottom, Space.xs)

                    ProgressCard(done: overview.doneCount, planned: overview.plannedCount)

                    StreakTile(summary: streak, glow: goalGlow) {
                        Haptics.selection()
                        router.tab = .progress
                    }
                    .overlay {
                        if let start = celebrationStart, !reduceMotion {
                            PixelBurst(start: start)
                                .frame(width: 260, height: 220)
                        }
                    }

                    upNextSection(overview, today: today)

                    if !overview.comingUp.isEmpty {
                        comingUpSection(overview, today: today)
                    }

                    if overview.doneCount > 0 {
                        doneTodaySection(overview, today: today)
                    }
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.sm)
                .padding(.bottom, 112) // clearance for the floating button
                .background(alignment: .top) { skyBackdrop }
            }
            .scrollIndicators(.hidden)
            .background(SkyColor.page.ignoresSafeArea())

            FloatingAddButton {
                Haptics.tick()
                router.present(.newTask(TaskPrefill(dueDay: today)))
            }
            .padding(.trailing, Space.gutter)
            .padding(.bottom, Space.md)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Sky that also fills the status bar area and pull-down overscroll.
    private var skyBackdrop: some View {
        VStack(spacing: 0) {
            SkyColor.skyBands[0].frame(height: 600)
            SkyBackground(variant: .today)
        }
        .offset(y: -600)
        .padding(.horizontal, -Space.gutter)
    }

    // MARK: Sections

    @ViewBuilder
    private func upNextSection(_ overview: TodayOverview, today: DayKey) -> some View {
        let visible = visibleUpNext(overview, today: today)
        let hiddenCount = max(0, overview.openCount - visible.filter { lingering[$0.id] == nil }.count)

        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Up next", trailing: "See all") {
                router.todayPath.append(.plan(today))
            }

            if store.data.tasks.isEmpty {
                EmptySkyState(title: "Your sky is clear",
                              message: "Add your first task: a class, a deadline, or one small habit.",
                              actionTitle: "Add your first task") {
                    router.present(.newTask(TaskPrefill(dueDay: today)))
                }
            } else if visible.isEmpty {
                ClearDayCard(allDone: overview.doneCount > 0) {
                    router.present(.newTask(TaskPrefill(dueDay: today)))
                }
            } else {
                ForEach(visible) { task in
                    row(task, today: today, completedOverride: lingering[task.id] != nil ? true : nil)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))))
                }
                if hiddenCount > 0 {
                    Button {
                        router.todayPath.append(.plan(today))
                    } label: {
                        Text("\(hiddenCount) more today")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(SkyColor.deepSky)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .animation(reduceMotion ? nil : Motion.settle, value: visible.map(\.id))
    }

    private func comingUpSection(_ overview: TodayOverview, today: DayKey) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Coming up")
            ForEach(overview.comingUp.prefix(3)) { task in
                row(task, today: today, compact: true, showDay: true)
            }
        }
    }

    private func doneTodaySection(_ overview: TodayOverview, today: DayKey) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Button {
                withAnimation(reduceMotion ? nil : Motion.settle) { showDoneToday.toggle() }
            } label: {
                HStack {
                    Text("Done today")
                        .font(SkyFont.section)
                        .foregroundStyle(SkyColor.ink)
                    Text("\(overview.doneCount)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(SkyColor.deepSky)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(SkyColor.surfaceSunken, in: Capsule())
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showDoneToday ? 180 : 0))
                        .foregroundStyle(SkyColor.inkSecondary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Done today, \(overview.doneCount) tasks")
            .accessibilityHint(showDoneToday ? "Collapses the list" : "Shows completed tasks")

            if showDoneToday {
                ForEach(overview.completedToday) { event in
                    DoneEventRow(event: event, task: store.task(event.taskID), list: store.list(event.listID)) { task in
                        Haptics.tick()
                        store.reopen(task.id)
                    } onOpen: { task in
                        router.present(.task(task.id))
                    }
                }
            }
        }
    }

    // MARK: Rows

    private func row(_ task: TaskItem, today: DayKey, compact: Bool = false, showDay: Bool = false,
                     completedOverride: Bool? = nil) -> some View {
        TaskRow(model: TaskRowModel(task: task, list: store.list(task.listID), isOverdue: store.isOverdue(task),
                                    today: today, showDay: showDay, completedOverride: completedOverride),
                compact: compact,
                onToggle: { complete(task) },
                onOpen: { router.present(.task(task.id)) })
            .contextMenu { taskMenu(task, today: today) }
    }

    @ViewBuilder
    private func taskMenu(_ task: TaskItem, today: DayKey) -> some View {
        Button { router.present(.task(task.id)) } label: { Label("Edit", systemImage: "pencil") }
        if task.dueDay != today {
            Button { store.reschedule(task.id, to: today) } label: { Label("Do today", systemImage: "sun.max") }
        }
        Button { store.reschedule(task.id, to: today.adding(days: 1)) } label: { Label("Move to tomorrow", systemImage: "arrow.right.circle") }
        Button(role: .destructive) { store.deleteTask(task.id) } label: { Label("Delete", systemImage: "trash") }
    }

    private func visibleUpNext(_ overview: TodayOverview, today: DayKey) -> [TaskItem] {
        let live = overview.allActionable
        let liveIDs = Set(live.map(\.id))
        let extra = lingering.values.filter { !liveIDs.contains($0.id) }
        let merged = (live + extra).sorted { TaskQueries.actionOrder($0, $1, today: today) }
        return Array(merged.prefix(3 + extra.count))
    }

    private func complete(_ task: TaskItem) {
        guard lingering[task.id] == nil else { return } // ignore rapid re-taps
        Haptics.tick()
        lingering[task.id] = task
        let outcome = store.complete(task.id)
        if outcome.reachedDailyGoal { celebrate() }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            withAnimation(reduceMotion ? nil : Motion.settle) { lingering[task.id] = nil }
        }
    }

    private func celebrate() {
        Haptics.success()
        if reduceMotion {
            goalGlow = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                goalGlow = false
            }
        } else {
            celebrationStart = Date()
            goalGlow = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                celebrationStart = nil
                goalGlow = false
            }
        }
    }
}

// MARK: - Header

struct TodayHeader: View {
    let today: DayKey
    let now: Date
    let calendar: Calendar
    let overview: TodayOverview
    let hasAnyTasks: Bool
    let onCalendar: () -> Void

    var body: some View {
        PageHeader(overline: Format.overlineDate(today, calendar: calendar), title: title, subtitle: subtitle) {
            HeaderIconButton(systemImage: "calendar", label: "Plan and calendar", action: onCalendar)
        }
    }

    /// Time-aware headline.
    private var title: String {
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Make today count."
        case 12..<17: return "Keep it rolling."
        case 17..<22: return "Finish strong."
        default: return "Rest counts too."
        }
    }

    private var subtitle: String {
        if !hasAnyTasks { return "A clear sky. Add one small thing to start." }
        let open = overview.openCount
        if open == 0 && overview.doneCount > 0 { return "All clear for today. Nicely done." }
        if open == 0 { return "Nothing due today. Plan ahead or enjoy the calm." }
        let left = open == 1 ? "1 task left" : "\(open) tasks left"
        if !overview.overdue.isEmpty { return "\(left), \(overview.overdue.count) carried over." }
        return "\(left). Small wins make big days."
    }
}

// MARK: - Progress card

struct ProgressCard: View {
    let done: Int
    let planned: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double { planned == 0 ? 0 : Double(done) / Double(planned) }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 10))

        VStack(alignment: .leading, spacing: Space.md) {
            Text("Today's progress")
                .font(.system(.subheadline, weight: .bold))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.95))

            layout {
                Text(planned == 0 ? "0" : "\(done) of \(planned)")
                    .font(SkyFont.bigNumber)
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText())
                Text(caption)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(Color.white)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.28))
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(fraction > 0 ? 12 : 0, geo.size.width * fraction))
                }
            }
            .frame(height: 12)
            .animation(reduceMotion ? nil : Motion.progress, value: fraction)
        }
        .padding(Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                SkyColor.progressCard
                PixelSprite(sprite: Sprite.cloudLarge, pixel: 3,
                            palette: PixelPalette(colors: ["W": SkyColor.sky, "S": SkyColor.sky.opacity(0.55)]))
                    .offset(x: 18, y: 16)
                PixelSprite(sprite: Sprite.twinkle, pixel: 2, palette: .onCard)
                    .offset(x: -110, y: 22)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card + 2, style: .continuous))
        .shadow(color: SkyColor.sky.opacity(0.25), radius: 16, x: 0, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's progress")
        .accessibilityValue(planned == 0 ? "No tasks planned" : "\(done) of \(planned) tasks done")
        .animation(reduceMotion ? nil : Motion.progress, value: done)
    }

    private var caption: String {
        if planned == 0 { return "nothing planned yet" }
        if done == planned { return "all done" }
        return "tasks done"
    }
}

// MARK: - Streak tile

struct StreakTile: View {
    let summary: StreakEngine.Summary
    var glow = false
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.md) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SkyColor.pinkSoft)
                    .frame(width: 56, height: 56)
                    .overlay(PixelSprite(sprite: Sprite.streakStar, pixel: 4))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SkyFont.cardTitle)
                        .foregroundStyle(SkyColor.ink)
                    Text(subtitle)
                        .font(SkyFont.meta)
                        .foregroundStyle(SkyColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Space.xs)
                if !dynamicTypeSize.isAccessibilitySize {
                    GoalPips(done: summary.todayCompletions, goal: summary.todayGoal)
                }
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, weight: .bold))
                    .foregroundStyle(SkyColor.inkSecondary)
            }
            .padding(Space.md)
            .card(radius: Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(SkyColor.pink, lineWidth: glow ? 2 : 0)
                    .animation(.easeInOut(duration: 0.3), value: glow)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Opens Progress")
        .accessibilityAddTraits(.isButton)
    }

    private var title: String {
        summary.current > 0 ? "\(summary.current)-day streak" : "Start your streak"
    }

    private var subtitle: String {
        let remaining = summary.remainingToday
        let tasks = remaining == 1 ? "1 more task" : "\(remaining) more tasks"
        if summary.todayQualified { return "Today's goal reached. Streak safe." }
        if summary.restDayInUse { return "Rest day used. \(tasks) keeps it going." }
        if summary.current > 0 { return "\(tasks) keeps it going." }
        return "Finish \(summary.todayGoal) tasks today to begin."
    }
}

/// Daily goal as stepped pixel pips: filled pink for each completion toward today's goal.
struct GoalPips: View {
    let done: Int
    let goal: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(goal, 10), id: \.self) { i in
                Rectangle()
                    .fill(i < done ? SkyColor.pink : SkyColor.track)
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Small cards

struct ClearDayCard: View {
    let allDone: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: Space.md) {
            PixelSprite(sprite: Sprite.cloudSmall, pixel: 3,
                        palette: PixelPalette.sky.with("W", SkyColor.skySoft).with("S", SkyColor.border))
            VStack(alignment: .leading, spacing: 3) {
                Text(allDone ? "All clear for today" : "Nothing due today")
                    .font(SkyFont.cardTitle)
                    .foregroundStyle(SkyColor.ink)
                Text(allDone ? "Everything planned is done." : "Add something for today or plan ahead.")
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.inkSecondary)
            }
            Spacer(minLength: 0)
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(.body, weight: .bold))
                    .foregroundStyle(SkyColor.deepSky)
                    .frame(width: 44, height: 44)
                    .background(SkyColor.surfaceSunken, in: Circle())
            }
            .accessibilityLabel("Add a task for today")
        }
        .padding(Space.md)
        .card()
    }
}

struct DoneEventRow: View {
    let event: CompletionEvent
    let task: TaskItem?
    let list: TaskList?
    let onReopen: (TaskItem) -> Void
    let onOpen: (TaskItem) -> Void

    /// Only non-recurring tasks that are still completed can be reopened here; recurring
    /// completions are undone via the toast right after completing.
    private var reopenable: TaskItem? {
        guard let task, task.isCompleted, !task.isRecurring else { return nil }
        return task
    }

    var body: some View {
        HStack(spacing: Space.xs) {
            SkyCheckbox(isOn: true, isEnabled: reopenable != nil) {
                if let t = reopenable { onReopen(t) }
            }
            .padding(.leading, Space.xs)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.taskTitle)
                    .font(SkyFont.rowTitle)
                    .strikethrough(true, color: SkyColor.inkSecondary)
                    .foregroundStyle(SkyColor.inkSecondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let list {
                        Circle().fill(SkyColor.list(list.color)).frame(width: 7, height: 7)
                        Text(list.name)
                    }
                    Text("·")
                    Text(event.completedAt.formatted(date: .omitted, time: .shortened))
                    if task?.isRecurring == true { Image(systemName: "repeat").imageScale(.small) }
                }
                .font(SkyFont.meta)
                .foregroundStyle(SkyColor.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Space.sm)
        .padding(.trailing, Space.md)
        .card(radius: Radius.row, fill: SkyColor.surface.opacity(0.7))
        .contentShape(Rectangle())
        .onTapGesture { if let task { onOpen(task) } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.taskTitle), completed")
    }
}

struct SaveErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(SkyFont.meta)
            .foregroundStyle(SkyColor.pinkText)
            .padding(Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SkyColor.pinkSoft, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
    }
}
