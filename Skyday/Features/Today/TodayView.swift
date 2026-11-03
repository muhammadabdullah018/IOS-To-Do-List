import SwiftUI
import SkydayKit

/// The primary screen. In two seconds it answers: what's due, what's next, how far along
/// am I, what's coming, and is my streak safe. Each number appears once:
/// hero = tasks left + progress bar + next task; pills = this week / streak / done.
struct TodayView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Tasks just completed stay visible (checked) for a moment so the card can settle
    /// instead of vanishing under the finger. Persistence happens immediately regardless.
    @State private var lingering: [UUID: TaskItem] = [:]
    @State private var showDoneToday = false
    @State private var celebrationStart: Date?

    var body: some View {
        let overview = store.todayOverview
        let streak = store.streak
        let today = store.today
        let hasAnyTasks = !store.data.tasks.isEmpty

        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                if let error = store.lastSaveError {
                    SaveErrorBanner(message: error)
                }

                TimelineView(.periodic(from: .now, by: 300)) { context in
                    TodayHero(today: today, now: context.date, calendar: store.calendar, overview: overview,
                              hasAnyTasks: hasAnyTasks, name: store.settings.displayName,
                              onAvatar: { router.present(.settings) },
                              onCalendar: { router.todayPath.append(.plan(today)) })
                }

                if hasAnyTasks {
                    statusPills(overview: overview, streak: streak, today: today)
                }

                tasksSection(overview, today: today, hasAnyTasks: hasAnyTasks)

                if !overview.comingUp.isEmpty {
                    comingUpSection(overview, today: today)
                }

                if showDoneToday && overview.doneCount > 0 {
                    doneTodaySection(overview)
                }
            }
            .padding(.horizontal, Space.md)
            .padding(.top, Space.xs)
            .padding(.bottom, Space.lg)
        }
        .scrollIndicators(.hidden)
        .background(SkyColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Status pills

    private func statusPills(overview: TodayOverview, streak: StreakEngine.Summary, today: DayKey) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Space.xs))
            : AnyLayout(HStackLayout(spacing: Space.xs))
        return layout {
            StatusPill(value: "\(overview.comingUp.count)", caption: "This week", tint: SkyColor.skyPastel,
                       action: { router.todayPath.append(.plan(today.adding(days: 1))) }) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SkyColor.cardInk)
            }
            StatusPill(value: streak.current == 0 ? "0" : "\(streak.current)d",
                       caption: streak.todayQualified ? "Streak safe" : "Day streak",
                       tint: SkyColor.pinkPastel,
                       action: {
                           Haptics.selection()
                           router.tab = .progress
                       }) {
                PixelSprite(sprite: Sprite.streakStar, pixel: 3)
            }
            StatusPill(value: "\(overview.doneCount)", caption: "Done today", tint: SkyColor.cloudPastel,
                       action: {
                           withAnimation(reduceMotion ? nil : Motion.settle) { showDoneToday.toggle() }
                       }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(SkyColor.cardInk)
            }
        }
        .overlay {
            if let start = celebrationStart, !reduceMotion {
                PixelBurst(start: start).frame(width: 260, height: 200).allowsHitTesting(false)
            }
        }
    }

    // MARK: Sections

    @ViewBuilder
    private func tasksSection(_ overview: TodayOverview, today: DayKey, hasAnyTasks: Bool) -> some View {
        let visible = visibleUpNext(overview, today: today)
        let hiddenCount = max(0, overview.openCount - visible.filter { lingering[$0.id] == nil }.count)

        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Today tasks", trailing: hasAnyTasks ? "See all" : nil) {
                router.todayPath.append(.plan(today))
            }

            if !hasAnyTasks {
                EmptySkyState(title: "Start with one small thing",
                              message: "A class, a deadline, or a habit you want to keep.",
                              actionTitle: "Add your first task") {
                    router.present(.newTask(TaskPrefill(dueDay: today)))
                }
            } else if visible.isEmpty {
                ClearDayCard(allDone: overview.doneCount > 0) {
                    router.present(.newTask(TaskPrefill(dueDay: today)))
                }
            } else {
                ForEach(visible) { task in
                    TaskCard(model: TaskRowModel(task: task, list: store.list(task.listID), isOverdue: store.isOverdue(task),
                                                 today: today, completedOverride: lingering[task.id] != nil ? true : nil),
                             onToggle: { complete(task) },
                             onOpen: { router.present(.task(task.id)) })
                        .contextMenu { taskMenu(task, today: today) }
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))))
                }
                if hiddenCount > 0 {
                    Button {
                        router.todayPath.append(.plan(today))
                    } label: {
                        Text(hiddenCount == 1 ? "1 more today" : "\(hiddenCount) more today")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(SkyColor.onCanvas)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(SkyColor.raised, in: Capsule())
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
                TaskRow(model: TaskRowModel(task: task, list: store.list(task.listID), isOverdue: false,
                                            today: today, showDay: true),
                        compact: true,
                        onToggle: { complete(task) },
                        onOpen: { router.present(.task(task.id)) })
                    .contextMenu { taskMenu(task, today: today) }
            }
        }
    }

    private func doneTodaySection(_ overview: TodayOverview) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Done today", trailing: "Hide") {
                withAnimation(reduceMotion ? nil : Motion.settle) { showDoneToday = false }
            }
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

    private func visibleUpNext(_ overview: TodayOverview, today: DayKey) -> [TaskItem] {
        let live = overview.allActionable
        let liveIDs = Set(live.map(\.id))
        let extra = lingering.values.filter { !liveIDs.contains($0.id) }
        let merged = (live + extra).sorted { TaskQueries.actionOrder($0, $1, today: today) }
        return Array(merged.prefix(3 + extra.count))
    }

    private func complete(_ task: TaskItem) {
        guard lingering[task.id] == nil else { return } // ignore rapid re-taps
        let outcome = store.complete(task.id)
        guard outcome.didComplete else { return }
        Haptics.tick()
        lingering[task.id] = task
        if outcome.reachedDailyGoal { celebrate() }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            withAnimation(reduceMotion ? nil : Motion.settle) { lingering[task.id] = nil }
        }
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

// MARK: - Hero

struct TodayHero: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let today: DayKey
    let now: Date
    let calendar: Calendar
    let overview: TodayOverview
    let hasAnyTasks: Bool
    let name: String
    let onAvatar: () -> Void
    let onCalendar: () -> Void

    var body: some View {
        HeroCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Format.overlineDate(today, calendar: calendar))
                        .font(SkyFont.overline)
                        .textCase(.uppercase)
                        .tracking(1.1)
                        .foregroundStyle(SkyColor.cardInk)
                    Text(greeting)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(SkyColor.cardInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Keep the cloud strip free of text.
                .padding(.trailing, dynamicTypeSize.isAccessibilitySize ? 0 : HeroCard<EmptyView>.artStrip)
                Spacer(minLength: Space.sm)
                Button(action: onAvatar) { PixelAvatar(name: name) }
                    .buttonStyle(PressableButtonStyle(scale: 0.92))
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("todaySettingsButton")
            }

            Text(headline)
                .font(SkyFont.headline)
                .foregroundStyle(SkyColor.cardInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if overview.plannedCount > 0 {
                InkProgressBar(fraction: overview.fraction)
                    .accessibilityElement()
                    .accessibilityLabel("Today's progress")
                    .accessibilityValue("\(overview.doneCount) of \(overview.plannedCount) tasks done")
            }

            HStack(alignment: .center, spacing: Space.sm) {
                Text(footer)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(SkyColor.cardInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Space.xs)
                InkCircleButton(systemImage: "calendar", label: "Plan and calendar", action: onCalendar)
            }
        }
    }

    private var greeting: String {
        let hour = calendar.component(.hour, from: now)
        let base: String
        switch hour {
        case 5..<12: base = "Good morning"
        case 12..<17: base = "Good afternoon"
        case 17..<22: base = "Good evening"
        default: base = "Still up"
        }
        return name.isEmpty ? base : "\(base), \(name)"
    }

    private var headline: String {
        if !hasAnyTasks { return "Your sky is clear." }
        let open = overview.openCount
        if open == 0 && overview.doneCount > 0 { return "All clear. Nicely done." }
        if open == 0 { return "Nothing due today." }
        return open == 1 ? "You have 1 task left today" : "You have \(open) tasks left today"
    }

    /// One factual line: the next task, or what to do now.
    private var footer: String {
        if !hasAnyTasks { return "Add one small thing to start." }
        if let next = overview.upNext.first {
            var text = "Next: \(next.title)"
            if let time = next.dueTime { text += " · \(Format.time(time))" }
            if !overview.overdue.isEmpty { text += " · \(overview.overdue.count) carried over" }
            return text
        }
        return overview.comingUp.isEmpty ? "Plan ahead or enjoy the calm." : "Next up: \(overview.comingUp[0].title)"
    }
}

// MARK: - Small cards

struct ClearDayCard: View {
    let allDone: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: Space.md) {
            PixelSprite(sprite: Sprite.cloudSmall, pixel: 3)
            VStack(alignment: .leading, spacing: 3) {
                Text(allDone ? "Everything planned is done" : "Nothing due today")
                    .font(SkyFont.cardTitle)
                    .foregroundStyle(SkyColor.onCanvas)
                Text(allDone ? "Add something small or rest." : "Add something for today or plan ahead.")
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.onCanvasSecondary)
            }
            Spacer(minLength: 0)
            InkCircleButton(systemImage: "plus", label: "Add a task for today", action: onAdd)
        }
        .padding(Space.md)
        .background(SkyColor.raised, in: RoundedRectangle(cornerRadius: Radius.bigCard, style: .continuous))
    }
}

/// A completed task on Today or Plan. The row opens the task; the checkbox reopens it
/// (non-recurring only). Both are real buttons, so VoiceOver exposes each action.
struct DoneEventRow: View {
    let event: CompletionEvent
    let task: TaskItem?
    let list: TaskList?
    let onReopen: (TaskItem) -> Void
    let onOpen: (TaskItem) -> Void

    private var reopenable: TaskItem? {
        guard let task, task.isCompleted, !task.isRecurring else { return nil }
        return task
    }

    var body: some View {
        HStack(spacing: Space.xs) {
            SkyCheckbox(isOn: true, isEnabled: reopenable != nil, title: event.taskTitle) {
                if let t = reopenable { onReopen(t) }
            }
            .padding(.leading, Space.xs)

            Button {
                if let task { onOpen(task) }
            } label: {
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
            .background(SkyColor.pinkSoft, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
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
