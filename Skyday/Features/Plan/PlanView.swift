import SwiftUI
import SkydayKit

/// Calendar sub-screen reached from the Today header and "See all" (not a tab).
/// A week strip with busy-day dots, then the selected day's agenda.
struct PlanView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selected: DayKey
    @State private var weekStart: DayKey

    init(initialDay: DayKey) {
        _selected = State(initialValue: initialDay)
        _weekStart = State(initialValue: initialDay)
    }

    var body: some View {
        let today = store.today
        let firstWeekday = store.settings.firstWeekday
        let start = weekStart.startOfWeek(firstWeekday: firstWeekday)
        let days = (0..<7).map { start.adding(days: $0) }
        let busy = store.busyDays(from: start, through: start.adding(days: 6))

        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                WeekStrip(days: days, selected: selected, today: today, busy: busy, calendar: store.calendar,
                          onSelect: { day in
                              Haptics.selection()
                              selected = day
                          },
                          onShift: { weeks in
                              // Keep the same weekday selected when paging weeks.
                              withAnimation(reduceMotion ? nil : Motion.settle) {
                                  weekStart = start.adding(days: 7 * weeks)
                                  selected = selected.adding(days: 7 * weeks)
                              }
                          })

                DayAgenda(day: selected)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.md)
        }
        .background(SkyColor.page.ignoresSafeArea())
        .navigationTitle(Format.longDate(selected, calendar: store.calendar))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.present(.newTask(TaskPrefill(dueDay: selected)))
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New task on this day")
            }
            if selected != today {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        weekStart = today
                        selected = today
                    }
                }
            }
        }
    }
}

struct WeekStrip: View {
    let days: [DayKey]
    let selected: DayKey
    let today: DayKey
    let busy: Set<DayKey>
    let calendar: Calendar
    let onSelect: (DayKey) -> Void
    /// -1 previous week, +1 next week.
    let onShift: (Int) -> Void

    var body: some View {
        VStack(spacing: Space.sm) {
            HStack {
                Button { onShift(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous week")
                Spacer()
                Text(monthTitle)
                    .font(SkyFont.cardTitle)
                    .foregroundStyle(SkyColor.ink)
                Spacer()
                Button { onShift(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next week")
            }
            .foregroundStyle(SkyColor.deepSky)

            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let isSelected = day == selected
                    Button { onSelect(day) } label: {
                        VStack(spacing: 6) {
                            Text(Format.weekdayLetter(day, calendar: calendar))
                                .font(SkyFont.caption)
                                .foregroundStyle(isSelected ? Color.white.opacity(0.9) : SkyColor.inkSecondary)
                            Text("\(day.day)")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(isSelected ? Color.white : (day == today ? SkyColor.deepSky : SkyColor.ink))
                            Rectangle()
                                .fill(busy.contains(day) ? (isSelected ? Color.white : SkyColor.sky) : Color.clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(isSelected ? SkyColor.deepSky : SkyColor.surface,
                                    in: RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                                .strokeBorder(day == today && !isSelected ? SkyColor.sky : SkyColor.border, lineWidth: day == today ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel(accessibilityLabel(day))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var monthTitle: String {
        guard let first = days.first else { return "" }
        return first.noonDate(in: calendar).formatted(.dateTime.month(.wide).year())
    }

    private func accessibilityLabel(_ day: DayKey) -> String {
        var label = Format.longDate(day, calendar: calendar)
        if day == today { label += ", today" }
        if busy.contains(day) { label += ", has tasks" }
        return label
    }
}

/// The agenda for one day: overdue + scheduled (today), scheduled + repeating (future),
/// or what was completed (past).
struct DayAgenda: View {
    let day: DayKey
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        let today = store.today
        let items = store.agenda(on: day)
        let overdue = items.filter { day == today && $0.day < today }
        let scheduled = items.filter { !(day == today && $0.day < today) }
        let completed = store.completions(on: day)

        VStack(alignment: .leading, spacing: Space.lg) {
            if !overdue.isEmpty {
                section("Carried over", items: overdue, today: today)
            }
            if !scheduled.isEmpty {
                section(day == today ? "Today" : (day < today ? "Still open" : "Planned"), items: scheduled, today: today)
            }
            if overdue.isEmpty && scheduled.isEmpty && completed.isEmpty {
                EmptySkyState(title: day < today ? "Nothing recorded" : "Free day",
                              message: day < today ? "No tasks were completed on this day." : "Nothing is scheduled yet.",
                              actionTitle: day < today ? nil : "Add a task") {
                    router.present(.newTask(TaskPrefill(dueDay: day)))
                }
            }
            if !completed.isEmpty {
                VStack(alignment: .leading, spacing: Space.sm) {
                    SectionHeader(title: "Completed")
                    ForEach(completed) { event in
                        DoneEventRow(event: event, task: store.task(event.taskID), list: store.list(event.listID)) { task in
                            store.reopen(task.id)
                        } onOpen: { task in
                            router.present(.task(task.id))
                        }
                    }
                }
            }
        }
    }

    private func section(_ title: String, items: [AgendaItem], today: DayKey) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: title)
            ForEach(items) { item in
                TaskRow(model: TaskRowModel(task: item.task, list: store.list(item.task.listID),
                                            isOverdue: store.isOverdue(item.task), today: today,
                                            showDay: item.day != day, isProjection: item.isProjection,
                                            displayDay: item.day),
                        compact: true,
                        onToggle: {
                            Haptics.tick()
                            _ = store.complete(item.task.id)
                        },
                        onOpen: { router.present(.task(item.task.id)) })
                .accessibilityHint(item.isProjection ? "Future repeat of this task. Opens the task." : "")
            }
        }
    }
}
