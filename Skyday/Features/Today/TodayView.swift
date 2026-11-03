import SwiftUI
import SkydayKit

/// The primary screen (reference layout): illustrated sky header with greeting and streak
/// badge → progress ring card → "Today" task rows (open first, completed at the bottom,
/// checked) → Coming up.
struct TodayView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var celebrationStart: Date?
    @State private var showAllOpen = false

    private let headerHeight: CGFloat = 236
    private let openLimit = 6

    var body: some View {
        let overview = store.todayOverview
        let streak = store.streak
        let today = store.today
        let hasAnyTasks = !store.data.tasks.isEmpty

        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TimelineView(.periodic(from: .now, by: 300)) { context in
                        let hour = store.calendar.component(.hour, from: context.date)
                        SkyHeader(scene: SkyScene.today(hour: hour), height: headerHeight, topInset: geo.safeAreaInsets.top) {
                            header(hour: hour, today: today, streak: streak, hasAnyTasks: hasAnyTasks)
                        }
                    }

                    VStack(alignment: .leading, spacing: Space.lg) {
                        if let error = store.lastSaveError {
                            SaveErrorBanner(message: error)
                        }

                        if hasAnyTasks {
                            ProgressSummaryCard(done: overview.doneCount, planned: overview.plannedCount) {
                                router.todayPath.append(.plan(today))
                            }
                            .overlay {
                                if let start = celebrationStart, !reduceMotion {
                                    PixelBurst(start: start).frame(width: 280, height: 200).allowsHitTesting(false)
                                }
                            }
                        }

                        todaySection(overview, today: today, hasAnyTasks: hasAnyTasks)

                        if !overview.comingUp.isEmpty {
                            comingUpSection(overview, today: today)
                        }
                    }
                    .padding(.horizontal, Space.md)
                    .padding(.top, hasAnyTasks ? -30 : Space.xs) // the progress card overlaps the art
                    .padding(.bottom, Space.xl)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .background(SkyColor.page.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private func header(hour: Int, today: DayKey, streak: StreakEngine.Summary, hasAnyTasks: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Format.overlineDate(today, calendar: store.calendar))
                        .font(SkyFont.overline)
                        .textCase(.uppercase)
                        .tracking(1.1)
                        .foregroundStyle(SkyColor.onSky)
                        .shadow(color: SkyColor.skyTextShadow, radius: 2, x: 0, y: 1)
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        SkyTitle(text: greeting(hour: hour), font: .system(.title, design: .rounded, weight: .bold))
                        Image(systemName: hour >= 20 || hour < 5 ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(SkyColor.star)
                            .shadow(color: SkyColor.skyTextShadow, radius: 2, x: 0, y: 1)
                            .accessibilityHidden(true)
                    }
                }
                Spacer(minLength: Space.sm)
                SkyCircleButton(systemImage: "calendar", label: "Plan and calendar") {
                    router.todayPath.append(.plan(today))
                }
            }
            Spacer(minLength: Space.sm)
            if hasAnyTasks {
                StreakBadge(summary: streak) {
                    Haptics.selection()
                    router.tab = .progress
                }
            }
        }
        // Fill the header so the badge sits on its lower edge, above the overlapping card.
        .frame(height: headerHeight - Space.sm - 44, alignment: .topLeading)
    }

    private func greeting(hour: Int) -> String {
        let base: String
        switch hour {
        case 5..<12: base = "Good Morning"
        case 12..<17: base = "Good Afternoon"
        case 17..<22: base = "Good Evening"
        default: base = "Still Up"
        }
        let name = store.settings.displayName
        return name.isEmpty ? base : "\(base),\n\(name)"
    }

    // MARK: Today list

    @ViewBuilder
    private func todaySection(_ overview: TodayOverview, today: DayKey, hasAnyTasks: Bool) -> some View {
        let open = overview.allActionable
        let shown = showAllOpen ? open : Array(open.prefix(openLimit))

        VStack(alignment: .leading, spacing: Space.xs) {
            SectionAddHeader(title: "Today", addLabel: "New task for today") {
                Haptics.tick()
                router.present(.newTask(TaskPrefill(dueDay: today)))
            }

            if !hasAnyTasks {
                EmptySkyState(title: "Your sky is clear",
                              message: "Add your first task: a class, a deadline, or one small habit.",
                              actionTitle: "Add your first task") {
                    router.present(.newTask(TaskPrefill(dueDay: today)))
                }
            } else if open.isEmpty && overview.completedToday.isEmpty {
                ClearDayCard {
                    router.present(.newTask(TaskPrefill(dueDay: today)))
                }
            }

            ForEach(shown) { task in
                TaskRow(model: TaskRowModel(task: task, list: store.list(task.listID), isOverdue: store.isOverdue(task), today: today),
                        onToggle: { complete(task) },
                        onOpen: { router.present(.task(task.id)) })
                    .contextMenu { taskMenu(task, today: today) }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }

            if open.count > openLimit {
                Button {
                    withAnimation(reduceMotion ? nil : Motion.settle) { showAllOpen.toggle() }
                } label: {
                    Text(showAllOpen ? "Show less" : "Show \(open.count - openLimit) more")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(SkyColor.deepSky)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }

            // Completed today stays visible, checked, like the reference.
            ForEach(overview.completedToday) { event in
                DoneEventRow(event: event, task: store.task(event.taskID)) { task in
                    Haptics.tick()
                    withAnimation(reduceMotion ? nil : Motion.settle) { store.reopen(task.id) }
                } onOpen: { task in
                    router.present(.task(task.id))
                }
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : Motion.settle, value: open.map(\.id))
        .animation(reduceMotion ? nil : Motion.settle, value: overview.completedToday.map(\.id))
    }

    private func comingUpSection(_ overview: TodayOverview, today: DayKey) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            SectionHeader(title: "Coming up")
            ForEach(overview.comingUp.prefix(3)) { task in
                TaskRow(model: TaskRowModel(task: task, list: store.list(task.listID), isOverdue: false, today: today, showDay: true),
                        compact: true,
                        onToggle: { complete(task) },
                        onOpen: { router.present(.task(task.id)) })
                    .contextMenu { taskMenu(task, today: today) }
            }
        }
    }

    @ViewBuilder
    private func taskMenu(_ task: TaskItem, today: DayKey) -> some View {
        Button { router.present(.task(task.id)) } label: { Label("Edit", systemImage: "pencil") }
        if task.isRecurring {
            Button { store.skipOccurrence(task.id) } label: { Label("Skip this time", systemImage: "forward.end") }
        } else {
            if task.dueDay != today {
                Button { store.reschedule(task.id, to: today) } label: { Label("Do today", systemImage: "sun.max") }
            }
            Button { store.reschedule(task.id, to: today.adding(days: 1)) } label: { Label("Move to tomorrow", systemImage: "arrow.right.circle") }
        }
        Button(role: .destructive) { store.deleteTask(task.id) } label: { Label("Delete", systemImage: "trash") }
    }

    private func complete(_ task: TaskItem) {
        let outcome = withAnimation(reduceMotion ? nil : Motion.settle) { store.complete(task.id) }
        guard outcome.didComplete else { return }
        Haptics.tick()
        if outcome.reachedDailyGoal { celebrate() }
    }

    private func celebrate() {
        Haptics.success()
        guard !reduceMotion else { return }
        celebrationStart = Date()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            celebrationStart = nil
        }
    }
}

// MARK: - Small cards

struct ClearDayCard: View {
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: Space.md) {
            PixelSprite(sprite: Sprite.cloudSmall, pixel: 3,
                        palette: PixelPalette.sky.with("W", SkyColor.lightSky).with("S", SkyColor.border))
            VStack(alignment: .leading, spacing: 3) {
                Text("Nothing due today")
                    .font(SkyFont.cardTitle)
                    .foregroundStyle(SkyColor.ink)
                Text("Add something for today or plan ahead.")
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.inkSecondary)
            }
            Spacer(minLength: 0)
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(.body, weight: .bold))
                    .foregroundStyle(SkyColor.deepSky)
                    .frame(width: 44, height: 44)
                    .background(SkyColor.lightSky, in: Circle())
            }
            .accessibilityLabel("Add a task for today")
        }
        .padding(Space.md)
        .card(radius: Radius.row)
    }
}

/// A completion from today (or a past day in Plan), drawn like a checked task row. The
/// checkbox reopens non-recurring tasks; the row opens the task. Both are real buttons.
struct DoneEventRow: View {
    let event: CompletionEvent
    let task: TaskItem?
    let onReopen: (TaskItem) -> Void
    let onOpen: (TaskItem) -> Void

    private var reopenable: TaskItem? {
        guard let task, task.isCompleted, !task.isRecurring else { return nil }
        return task
    }

    var body: some View {
        HStack(spacing: Space.xxs) {
            SkyCheckbox(isOn: true, isEnabled: reopenable != nil, title: event.taskTitle) {
                if let t = reopenable { onReopen(t) }
            }
            .padding(.leading, Space.xxs)

            Button {
                if let task { onOpen(task) }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.taskTitle)
                        .font(.system(.body, weight: .semibold))
                        .strikethrough(true, color: SkyColor.inkSecondary)
                        .foregroundStyle(SkyColor.inkSecondary)
                        .lineLimit(2)
                    Text(task?.isRecurring == true
                         ? "Done \(event.completedAt.formatted(date: .omitted, time: .shortened)) · repeats"
                         : "Done \(event.completedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.system(.caption))
                        .foregroundStyle(SkyColor.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Space.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(task == nil)
            .accessibilityLabel("\(event.taskTitle), completed")
            .accessibilityHint(task == nil ? "This task was deleted" : "Opens the task")
        }
        .padding(.trailing, Space.md)
        .frame(minHeight: 58)
        .card(radius: Radius.row)
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
            .background(SkyColor.softPink, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
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
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}
