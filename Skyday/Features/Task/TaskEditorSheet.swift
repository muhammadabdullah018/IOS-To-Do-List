import SwiftUI
import SkydayKit

/// Add Task and Task Details/Edit share one native sheet. Create opens at medium height with
/// the keyboard up; everything else is a scroll away.
struct TaskEditorSheet: View {
    enum Mode: Equatable {
        case create(TaskPrefill)
        case edit(UUID)
    }

    let mode: Mode

    @Environment(SkydayStore.self) private var store
    @Environment(NotificationService.self) private var notifications
    @Environment(\.dismiss) private var dismiss

    @State private var draft = TaskDraft(listID: UUID())
    @State private var original = TaskDraft(listID: UUID())
    @State private var loaded = false
    @State private var detent: PresentationDetent = .large
    @State private var repeatChoice: RepeatChoice = .never
    @State private var newSubtask = ""
    @State private var showDiscard = false
    @State private var confirmDelete = false
    @FocusState private var titleFocused: Bool
    @FocusState private var subtaskFocused: Bool

    private var isCreate: Bool { if case .create = mode { return true } else { return false } }
    private var editingID: UUID? { if case .edit(let id) = mode { return id } else { return nil } }
    private var hasChanges: Bool { loaded && draft != original }
    private var detents: Set<PresentationDetent> { isCreate ? [.medium, .large] : [.large] }

    var body: some View {
        NavigationStack {
            Group {
                if let id = editingID, store.task(id) == nil {
                    EmptySkyState(title: "Task not found", message: "It may have been deleted.")
                        .padding(Space.gutter)
                } else {
                    form
                }
            }
            .navigationTitle(isCreate ? "New task" : "Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { showDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreate ? "Add" : "Done", action: save)
                        .fontWeight(.bold)
                        .disabled(!draft.isValid)
                        .accessibilityIdentifier("saveTaskButton")
                }
            }
        }
        .presentationDetents(detents, selection: $detent)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(hasChanges)
        .confirmationDialog("Discard changes?", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        }
        .confirmationDialog("Delete this task?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete task", role: .destructive) {
                if let id = editingID { store.deleteTask(id) }
                Haptics.warning()
                dismiss()
            }
        } message: {
            Text("You can undo right after deleting.")
        }
        .onAppear(perform: load)
    }

    // MARK: Form

    private var form: some View {
        Form {
            Section {
                TextField("What do you need to do?", text: $draft.title, axis: .vertical)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(SkyColor.ink)
                    .lineLimit(1...4)
                    .focused($titleFocused)
                    .submitLabel(.done)
                    .onSubmit { if isCreate { save() } }
                    .accessibilityIdentifier("taskTitleField")

                QuickDateChips(selected: draft.dueDay, today: store.today) { day in
                    Haptics.selection()
                    draft.dueDay = day
                    if day == nil {
                        draft.dueTime = nil
                        draft.reminderMinutesBefore = nil
                        draft.recurrence = nil
                        repeatChoice = .never
                    }
                }
                .listRowInsets(EdgeInsets(top: Space.xs, leading: 0, bottom: Space.xs, trailing: 0))

                if let id = editingID, let task = store.task(id) {
                    completionRow(task)
                }
            }

            whenSection
            reminderSection

            Section("Details") {
                Picker("List", selection: $draft.listID) {
                    ForEach(store.sortedLists) { list in
                        Label(list.name, systemImage: list.icon).tag(list.id)
                    }
                }
                Picker("Priority", selection: $draft.priority) {
                    ForEach(Priority.allCases) { p in Text(p.label).tag(p) }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Priority")
            }

            subtasksSection

            Section("Notes") {
                TextField("Add notes, links or details", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...10)
            }

            if editingID != nil {
                Section {
                    Button("Delete task", role: .destructive) { confirmDelete = true }
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: repeatChoice) { _, choice in applyRepeat(choice) }
    }

    private func completionRow(_ task: TaskItem) -> some View {
        Button {
            if hasChanges && draft.isValid { store.updateTask(task.id, with: draft) }
            let outcome = store.toggleCompletion(task.id)
            if outcome.didComplete { Haptics.success() } else { Haptics.tick() }
            dismiss()
        } label: {
            Label(task.isCompleted ? "Reopen task" : (task.isRecurring ? "Complete this occurrence" : "Mark as complete"),
                  systemImage: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle.fill")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(task.isCompleted ? SkyColor.deepSky : SkyColor.pinkText)
        }
        .accessibilityIdentifier("toggleCompleteButton")
    }

    private var whenSection: some View {
        Section {
            Toggle("Date", isOn: Binding(get: { draft.dueDay != nil }, set: { on in
                draft.dueDay = on ? (draft.dueDay ?? store.today) : nil
                if !on {
                    draft.dueTime = nil
                    draft.reminderMinutesBefore = nil
                    draft.recurrence = nil
                    repeatChoice = .never
                }
            }))
            if draft.dueDay != nil {
                DatePicker("Due", selection: dayBinding, displayedComponents: .date)
                Toggle("Time", isOn: Binding(get: { draft.dueTime != nil }, set: { on in
                    draft.dueTime = on ? (draft.dueTime ?? suggestedTime) : nil
                }))
                if draft.dueTime != nil {
                    DatePicker("At", selection: timeBinding, displayedComponents: .hourAndMinute)
                }
            }
            Picker("Repeat", selection: $repeatChoice) {
                ForEach(RepeatChoice.allCases, id: \.self) { choice in
                    Text(choice.label(for: draft.dueDay ?? store.today, calendar: store.calendar)).tag(choice)
                }
            }
            if repeatChoice == .custom {
                CustomRepeatEditor(rule: Binding(get: { draft.recurrence ?? .daily }, set: { draft.recurrence = $0 }))
            }
        } header: {
            Text("When")
        } footer: {
            if let rule = draft.recurrence {
                Text("\(rule.summary). Completing it moves it to the next date; missed days are skipped, not piled up.")
            }
        }
    }

    private var reminderSection: some View {
        Section {
            if draft.dueDay == nil {
                Text("Add a date to set a reminder.")
                    .foregroundStyle(SkyColor.inkSecondary)
            } else {
                Picker("Remind me", selection: reminderBinding) {
                    ForEach(reminderOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .accessibilityIdentifier("reminderPicker")
                if draft.reminderMinutesBefore != nil && notifications.permission == .denied {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Label("Notifications are off for Skyday", systemImage: "bell.slash.fill")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(SkyColor.pinkText)
                        Text("The task still saves. Turn notifications on to get this reminder.")
                            .font(SkyFont.meta)
                            .foregroundStyle(SkyColor.inkSecondary)
                        Button("Open Settings") { notifications.openSystemSettings() }
                            .font(.system(.subheadline, weight: .semibold))
                    }
                    .padding(.vertical, Space.xxs)
                }
            }
        } header: {
            Text("Reminder")
        } footer: {
            if draft.dueDay != nil && draft.dueTime == nil && draft.reminderMinutesBefore != nil {
                Text("No time set, so Skyday reminds you at \(Format.time(store.settings.defaultReminderTime)) on the day. Change this in Settings.")
            }
        }
    }

    private var subtasksSection: some View {
        Section {
            ForEach(draft.subtasks) { subtask in
                HStack(spacing: Space.xs) {
                    SkyCheckbox(isOn: subtask.isDone) {
                        Haptics.tick()
                        if let i = draft.subtasks.firstIndex(where: { $0.id == subtask.id }) { draft.subtasks[i].isDone.toggle() }
                    }
                    .padding(.leading, -Space.sm)
                    TextField("Subtask", text: subtaskTitle(subtask.id))
                        .strikethrough(subtask.isDone)
                        .foregroundStyle(subtask.isDone ? SkyColor.inkSecondary : SkyColor.ink)
                }
            }
            .onDelete { offsets in draft.subtasks.remove(atOffsets: offsets) }
            .onMove { from, to in draft.subtasks.move(fromOffsets: from, toOffset: to) }

            HStack(spacing: Space.xs) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(SkyColor.sky)
                    .font(.title3)
                    .frame(width: 32)
                TextField("Add a subtask", text: $newSubtask)
                    .focused($subtaskFocused)
                    .submitLabel(.next)
                    .onSubmit(addSubtask)
                    .accessibilityIdentifier("newSubtaskField")
            }
        } header: {
            HStack {
                Text("Subtasks")
                Spacer()
                if !draft.subtasks.isEmpty {
                    Text("\(draft.subtasks.filter(\.isDone).count)/\(draft.subtasks.count)")
                }
            }
        }
    }

    // MARK: Bindings

    private func subtaskTitle(_ id: UUID) -> Binding<String> {
        Binding(get: { draft.subtasks.first(where: { $0.id == id })?.title ?? "" },
                set: { value in
                    if let i = draft.subtasks.firstIndex(where: { $0.id == id }) { draft.subtasks[i].title = value }
                })
    }

    private var dayBinding: Binding<Date> {
        Binding(get: { (draft.dueDay ?? store.today).noonDate(in: store.calendar) },
                set: { draft.dueDay = DayKey($0, calendar: store.calendar) })
    }

    private var timeBinding: Binding<Date> {
        Binding(get: { (draft.dueDay ?? store.today).date(at: draft.dueTime ?? suggestedTime, in: store.calendar) },
                set: { draft.dueTime = TimeOfDay($0, calendar: store.calendar) })
    }

    /// -1 encodes "no reminder" so Picker tags stay non-optional.
    private var reminderBinding: Binding<Int> {
        Binding(get: { draft.reminderMinutesBefore ?? -1 },
                set: { value in
                    draft.reminderMinutesBefore = value < 0 ? nil : value
                    if value >= 0 {
                        // Contextual permission request: the moment the user asks for a reminder.
                        Task { @MainActor in await notifications.requestPermissionIfNeeded() }
                    }
                })
    }

    private struct ReminderOption {
        let label: String
        let value: Int
    }

    private var reminderOptions: [ReminderOption] {
        if draft.dueTime == nil {
            return [ReminderOption(label: "None", value: -1),
                    ReminderOption(label: "On the day at \(Format.time(store.settings.defaultReminderTime))", value: 0)]
        }
        return [ReminderOption(label: "None", value: -1),
                ReminderOption(label: "At time of task", value: 0),
                ReminderOption(label: "5 minutes before", value: 5),
                ReminderOption(label: "15 minutes before", value: 15),
                ReminderOption(label: "30 minutes before", value: 30),
                ReminderOption(label: "1 hour before", value: 60),
                ReminderOption(label: "1 day before", value: 1440)]
    }

    /// Next whole hour, used when a time is first switched on.
    private var suggestedTime: TimeOfDay {
        let hour = store.calendar.component(.hour, from: store.now)
        return TimeOfDay(hour: min(hour + 1, 23), minute: 0)
    }

    // MARK: Actions

    private func load() {
        guard !loaded else { return }
        switch mode {
        case .create(let prefill):
            let listID = prefill.listID.flatMap { store.list($0)?.id } ?? store.data.inbox.id
            draft = TaskDraft(listID: listID, dueDay: prefill.dueDay)
            detent = .medium
            titleFocused = true
        case .edit(let id):
            if let task = store.task(id) { draft = TaskDraft(task: task) }
            detent = .large
        }
        original = draft
        repeatChoice = RepeatChoice(rule: draft.recurrence)
        loaded = true
    }

    private func applyRepeat(_ choice: RepeatChoice) {
        guard loaded else { return }
        let day = draft.dueDay ?? store.today
        if choice == .custom {
            if draft.recurrence == nil { draft.recurrence = .daily }
        } else {
            draft.recurrence = choice.rule(for: day)
        }
        if draft.recurrence != nil && draft.dueDay == nil { draft.dueDay = store.today }
    }

    private func addSubtask() {
        let trimmed = newSubtask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft.subtasks.append(Subtask(title: trimmed))
        newSubtask = ""
        subtaskFocused = true
    }

    private func save() {
        guard draft.isValid else { return }
        switch mode {
        case .create:
            store.addTask(draft)
            Haptics.success()
        case .edit(let id):
            if hasChanges { store.updateTask(id, with: draft) }
        }
        dismiss()
    }
}

// MARK: - Quick date chips

struct QuickDateChips: View {
    let selected: DayKey?
    let today: DayKey
    let onPick: (DayKey?) -> Void

    private struct Option: Identifiable {
        let title: String
        let symbol: String
        let day: DayKey?
        var id: String { title }
    }

    private var options: [Option] {
        let saturday = (1...7).map { today.adding(days: $0) }.first { $0.weekday == 7 } ?? today.adding(days: 1)
        let monday = (1...7).map { today.adding(days: $0) }.first { $0.weekday == 2 } ?? today.adding(days: 7)
        return [Option(title: "Today", symbol: "sun.max", day: today),
                Option(title: "Tomorrow", symbol: "sunrise", day: today.adding(days: 1)),
                Option(title: "Weekend", symbol: "sofa", day: saturday),
                Option(title: "Next week", symbol: "calendar", day: monday),
                Option(title: "No date", symbol: "tray", day: nil)]
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.xs) {
                ForEach(options) { option in
                    Chip(title: option.title, systemImage: option.symbol, isSelected: selected == option.day) {
                        onPick(option.day)
                    }
                }
            }
            .padding(.horizontal, Space.md)
        }
    }
}

// MARK: - Repeat

enum RepeatChoice: Hashable, CaseIterable {
    case never, daily, weekdays, weekly, biweekly, monthly, yearly, custom

    init(rule: RecurrenceRule?) {
        guard let rule else { self = .never; return }
        switch (rule.frequency, rule.interval) {
        case (.daily, 1): self = .daily
        case (.weekly, 1) where rule.weekdays == [2, 3, 4, 5, 6]: self = .weekdays
        case (.weekly, 1) where rule.weekdays.count <= 1: self = .weekly
        case (.weekly, 2) where rule.weekdays.count <= 1: self = .biweekly
        case (.monthly, 1): self = .monthly
        case (.yearly, 1): self = .yearly
        default: self = .custom
        }
    }

    func rule(for day: DayKey) -> RecurrenceRule? {
        switch self {
        case .never: return nil
        case .daily: return .daily
        case .weekdays: return .weekdaysOnly
        case .weekly: return .weekly(on: [day.weekday])
        case .biweekly: return RecurrenceRule(frequency: .weekly, interval: 2, weekdays: [day.weekday])
        case .monthly: return .monthly
        case .yearly: return .yearly
        case .custom: return nil
        }
    }

    func label(for day: DayKey, calendar: Calendar) -> String {
        let weekday = day.noonDate(in: calendar).formatted(.dateTime.weekday(.wide))
        switch self {
        case .never: return "Never"
        case .daily: return "Every day"
        case .weekdays: return "Every weekday"
        case .weekly: return "Every week on \(weekday)"
        case .biweekly: return "Every 2 weeks on \(weekday)"
        case .monthly: return "Every month on the \(day.day)\(Self.ordinalSuffix(day.day))"
        case .yearly: return "Every year"
        case .custom: return "Custom…"
        }
    }

    static func ordinalSuffix(_ n: Int) -> String {
        if (11...13).contains(n % 100) { return "th" }
        switch n % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

struct CustomRepeatEditor: View {
    @Binding var rule: RecurrenceRule

    private var unit: String {
        switch rule.frequency {
        case .daily: return rule.interval == 1 ? "day" : "days"
        case .weekly: return rule.interval == 1 ? "week" : "weeks"
        case .monthly: return rule.interval == 1 ? "month" : "months"
        case .yearly: return rule.interval == 1 ? "year" : "years"
        }
    }

    var body: some View {
        Picker("Frequency", selection: Binding(get: { rule.frequency }, set: { f in
            rule = RecurrenceRule(frequency: f, interval: rule.interval, weekdays: f == .weekly ? rule.weekdays : [])
        })) {
            Text("Daily").tag(RecurrenceRule.Frequency.daily)
            Text("Weekly").tag(RecurrenceRule.Frequency.weekly)
            Text("Monthly").tag(RecurrenceRule.Frequency.monthly)
            Text("Yearly").tag(RecurrenceRule.Frequency.yearly)
        }
        .pickerStyle(.segmented)

        Stepper("Every \(rule.interval) \(unit)",
                value: Binding(get: { rule.interval }, set: { rule = RecurrenceRule(frequency: rule.frequency, interval: $0, weekdays: rule.weekdays) }),
                in: 1...30)

        if rule.frequency == .weekly {
            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { weekday in
                    let isOn = rule.weekdays.contains(weekday)
                    Button {
                        var days = Set(rule.weekdays)
                        if isOn { days.remove(weekday) } else { days.insert(weekday) }
                        rule = RecurrenceRule(frequency: .weekly, interval: rule.interval, weekdays: Array(days))
                    } label: {
                        Text(String(RecurrenceRule.shortWeekdayNames[weekday - 1].prefix(2)))
                            .font(.system(.caption, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundStyle(isOn ? Color.white : SkyColor.deepSky)
                            .background(isOn ? SkyColor.deepSky : SkyColor.surfaceSunken,
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(RecurrenceRule.shortWeekdayNames[weekday - 1])
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
        }
    }
}
