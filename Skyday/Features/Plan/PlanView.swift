import SwiftUI
import SkydayKit

/// Calendar sub-screen reached from the Today header and "See all" (not a tab).
/// A month grid with busy-day markers, then the selected day's agenda.
struct PlanView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selected: DayKey
    @State private var month: DayKey

    init(initialDay: DayKey) {
        _selected = State(initialValue: initialDay)
        _month = State(initialValue: initialDay)
    }

    var body: some View {
        let today = store.today
        let firstWeekday = store.settings.firstWeekday
        let cells = MonthGrid.cells(month: month, firstWeekday: firstWeekday)
        let busy = store.busyDays(from: cells[0], through: cells[41])

        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                MonthGrid(month: month, selected: selected, today: today, busy: busy,
                          firstWeekday: firstWeekday, calendar: store.calendar,
                          onSelect: { day in
                              Haptics.selection()
                              withAnimation(reduceMotion ? nil : Motion.settle) {
                                  selected = day
                                  if day.month != month.month { month = day }
                              }
                          },
                          onShift: { delta in
                              Haptics.selection()
                              withAnimation(reduceMotion ? nil : Motion.settle) { month = month.addingMonths(delta) }
                          })

                DayAgenda(day: selected)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.md)
        }
        .background(SkyColor.page.ignoresSafeArea())
        .navigationTitle("Calendar")
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
                        month = today
                        selected = today
                    }
                }
            }
        }
    }
}

/// Month calendar: weekday header in the user's week order, 6 rows, busy-day markers,
/// selected day in pink, today in bold blue. Days outside the month are dimmed but tappable.
struct MonthGrid: View {
    let month: DayKey          // any day in the displayed month
    let selected: DayKey
    let today: DayKey
    let busy: Set<DayKey>
    let firstWeekday: Int
    let calendar: Calendar
    let onSelect: (DayKey) -> Void
    /// -1 previous month, +1 next month.
    let onShift: (Int) -> Void

    static func cells(month: DayKey, firstWeekday: Int) -> [DayKey] {
        let first = DayKey(year: month.year, month: month.month, day: 1)
        let start = first.startOfWeek(firstWeekday: firstWeekday)
        return (0..<42).map { start.adding(days: $0) }
    }

    var body: some View {
        let cells = Self.cells(month: month, firstWeekday: firstWeekday)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        VStack(spacing: Space.xs) {
            HStack {
                Button { onShift(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Text(DayKey(year: month.year, month: month.month, day: 1).noonDate(in: calendar)
                        .formatted(.dateTime.month(.wide).year()))
                    .font(SkyFont.cardTitle)
                    .foregroundStyle(SkyColor.ink)
                    .contentTransition(.numericText())
                Spacer()
                Button { onShift(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next month")
            }
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(SkyColor.deepSky)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(cells.prefix(7), id: \.self) { day in
                    Text(Format.weekdayLetter(day, calendar: calendar))
                        .font(SkyFont.caption)
                        .foregroundStyle(day.weekday == 1 ? SkyColor.pinkText : SkyColor.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
                ForEach(cells, id: \.self) { day in
                    cell(day)
                }
            }
        }
        .padding(Space.sm)
        .card(radius: Radius.row)
    }

    private func cell(_ day: DayKey) -> some View {
        let isSelected = day == selected
        let inMonth = day.month == month.month
        return Button { onSelect(day) } label: {
            VStack(spacing: 2) {
                Text("\(day.day)")
                    .font(.system(.callout, design: .rounded, weight: day == today || isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.white : day == today ? SkyColor.deepSky : inMonth ? SkyColor.ink : SkyColor.inkSecondary.opacity(0.55))
                Rectangle()
                    .fill(busy.contains(day) ? (isSelected ? Color.white : SkyColor.sky) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? SkyColor.pink : Color.clear, in: Circle())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.noonDate(in: calendar).formatted(date: .complete, time: .omitted))
        .accessibilityValue(busy.contains(day) ? "Has tasks" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        DoneEventRow(event: event, task: store.task(event.taskID)) { task in
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
