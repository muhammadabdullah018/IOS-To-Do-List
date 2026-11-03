import SwiftUI
import SkydayKit

struct ListDetailView: View {
    let listID: UUID
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("listSort") private var sortRaw = TaskSort.smart.rawValue
    @State private var showCompleted = false
    @State private var confirmDelete = false

    private var sort: TaskSort { TaskSort(rawValue: sortRaw) ?? .smart }

    var body: some View {
        if let list = store.list(listID) {
            content(list)
        } else {
            // The list was deleted (possibly via undo/redo elsewhere).
            EmptySkyState(title: "List not found", message: "It may have been deleted.")
                .padding(Space.gutter)
        }
    }

    private func content(_ list: TaskList) -> some View {
        let today = store.today
        let all = store.tasks(in: list.id, sort: sort)
        let open = all.filter { !$0.isCompleted }
        let done = all.filter(\.isCompleted)
        let mover: ((IndexSet, Int) -> Void)? = sort == .manual ? { from, to in move(open, from: from, to: to) } : nil

        return List {
            Section {
                HStack(spacing: Space.md) {
                    ListIconTile(list: list, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(open.count == 1 ? "1 open task" : "\(open.count) open tasks")
                            .font(SkyFont.cardTitle)
                            .foregroundStyle(SkyColor.ink)
                        Text("Sorted by \(sort.label.lowercased())")
                            .font(SkyFont.meta)
                            .foregroundStyle(SkyColor.inkSecondary)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: Space.xs, leading: Space.xxs, bottom: Space.xs, trailing: Space.xxs))
            }

            Section {
                if open.isEmpty {
                    EmptySkyState(title: done.isEmpty ? "Nothing here yet" : "All done",
                                  message: done.isEmpty ? "Add the first task to \(list.name)." : "Every task in this list is complete.",
                                  actionTitle: "Add a task") {
                        router.present(.newTask(TaskPrefill(listID: list.id)))
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(open) { task in
                        listRow(task, today: today)
                    }
                    .onMove(perform: mover)
                }
            } header: {
                if !open.isEmpty { Text("Open") }
            }

            if !done.isEmpty {
                Section {
                    if showCompleted {
                        ForEach(done) { task in listRow(task, today: today) }
                    }
                } header: {
                    Button {
                        withAnimation(reduceMotion ? nil : Motion.settle) { showCompleted.toggle() }
                    } label: {
                        HStack {
                            Text("Completed (\(done.count))")
                            Spacer()
                            Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(showCompleted ? "Hides completed tasks" : "Shows completed tasks")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SkyColor.page.ignoresSafeArea())
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if sort == .manual && open.count > 1 {
                    EditButton()
                }
                Menu {
                    Picker("Sort", selection: $sortRaw) {
                        ForEach(TaskSort.allCases) { option in
                            Text(option.label).tag(option.rawValue)
                        }
                    }
                    Divider()
                    Button { router.present(.editList(list.id)) } label: { Label("Edit list", systemImage: "pencil") }
                    if !list.isInbox {
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Delete list", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("List options")

                Button {
                    router.present(.newTask(TaskPrefill(listID: list.id)))
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New task in \(list.name)")
            }
        }
        .confirmationDialog("Delete “\(list.name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete list", role: .destructive) {
                store.deleteList(list.id)
                dismiss()
            }
        } message: {
            Text("Its tasks move to Inbox. Nothing is lost.")
        }
    }

    private func listRow(_ task: TaskItem, today: DayKey) -> some View {
        TaskRow(model: TaskRowModel(task: task, list: nil, isOverdue: store.isOverdue(task), today: today, showDay: true),
                compact: true,
                onToggle: {
                    Haptics.tick()
                    withAnimation(reduceMotion ? nil : Motion.settle) { _ = store.toggleCompletion(task.id) }
                },
                onOpen: { router.present(.task(task.id)) })
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: Space.xxs, leading: 0, bottom: Space.xxs, trailing: 0))
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    Haptics.tick()
                    _ = store.toggleCompletion(task.id)
                } label: {
                    Label(task.isCompleted ? "Reopen" : "Complete", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                }
                .tint(SkyColor.sky)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) { store.deleteTask(task.id) } label: { Label("Delete", systemImage: "trash") }
                if !task.isCompleted && task.isRecurring {
                    Button { store.skipOccurrence(task.id) } label: { Label("Skip", systemImage: "forward.end") }
                        .tint(SkyColor.deepSky)
                } else if !task.isCompleted {
                    Button { store.reschedule(task.id, to: today.adding(days: 1)) } label: { Label("Tomorrow", systemImage: "arrow.right") }
                        .tint(SkyColor.deepSky)
                }
            }
    }

    private func move(_ open: [TaskItem], from: IndexSet, to: Int) {
        var ids = open.map(\.id)
        ids.move(fromOffsets: from, toOffset: to)
        store.reorder(taskIDs: ids)
    }
}

struct ListEditorSheet: View {
    let listID: UUID?
    @Environment(SkydayStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var color: ListColor = .sky
    @State private var loaded = false
    @FocusState private var nameFocused: Bool

    private var isNew: Bool { listID == nil }
    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: Space.md) {
                        ListIconTile(list: TaskList(name: name, icon: icon, color: color, sortOrder: 0, createdAt: Date()), size: 52)
                        TextField("List name", text: $name)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit(save)
                            .accessibilityIdentifier("listNameField")
                    }
                    .padding(.vertical, Space.xxs)
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: Space.xs)], spacing: Space.xs) {
                        ForEach(ListColor.allCases) { option in
                            Button {
                                Haptics.selection()
                                color = option
                            } label: {
                                Circle()
                                    .fill(SkyColor.list(option))
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().strokeBorder(Color.white, lineWidth: color == option ? 3 : 0))
                                    .overlay(Circle().strokeBorder(SkyColor.list(option), lineWidth: color == option ? 1.5 : 0).padding(-3))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option.name)
                            .accessibilityAddTraits(color == option ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, Space.xxs)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: Space.xs)], spacing: Space.xs) {
                        ForEach(TaskList.iconChoices, id: \.self) { symbol in
                            Button {
                                Haptics.selection()
                                icon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(icon == symbol ? Color.white : SkyColor.deepSky)
                                    .frame(width: 44, height: 44)
                                    .background(icon == symbol ? SkyColor.list(color) : SkyColor.surfaceSunken,
                                                in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbol.replacingOccurrences(of: ".fill", with: "").replacingOccurrences(of: ".", with: " "))
                            .accessibilityAddTraits(icon == symbol ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, Space.xxs)
                }
            }
            .navigationTitle(isNew ? "New list" : "Edit list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Create" : "Save", action: save)
                        .disabled(trimmed.isEmpty)
                        .accessibilityIdentifier("saveListButton")
                }
            }
            .onAppear(perform: load)
        }
        .presentationDetents([.large])
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let id = listID, let list = store.list(id) {
            name = list.name
            icon = list.icon
            color = list.color
        } else {
            nameFocused = true
        }
    }

    private func save() {
        guard !trimmed.isEmpty else { return }
        if let id = listID {
            store.updateList(id, name: trimmed, icon: icon, color: color)
        } else {
            store.addList(name: trimmed, icon: icon, color: color)
        }
        Haptics.success()
        dismiss()
    }
}
