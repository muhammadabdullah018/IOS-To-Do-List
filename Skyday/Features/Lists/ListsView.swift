import SwiftUI
import SkydayKit

struct ListsView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @State private var query = ""
    @State private var pendingDelete: TaskList?
    @FocusState private var searchFocused: Bool

    var body: some View {
        let openTotal = store.data.tasks.filter { !$0.isCompleted }.count
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                HeroCard(fill: SkyColor.skyPastel, clouds: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your space")
                            .font(SkyFont.overline)
                            .textCase(.uppercase)
                            .tracking(1.1)
                            .foregroundStyle(SkyColor.cardInkSecondary)
                        Text("My lists")
                            .font(SkyFont.headline)
                            .foregroundStyle(SkyColor.cardInk)
                            .accessibilityAddTraits(.isHeader)
                        Text("\(store.data.lists.count) lists · \(openTotal) open \(openTotal == 1 ? "task" : "tasks")")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(SkyColor.cardInkSecondary)
                    }
                    SearchField(text: $query, focused: $searchFocused)
                }

                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    listsSection
                } else {
                    SearchResultsView(results: store.search(query))
                }
            }
            .padding(.horizontal, Space.md)
            .padding(.top, Space.xs)
            .padding(.bottom, Space.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .background(SkyColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(deleteTitle, isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete list", role: .destructive) {
                if let list = pendingDelete { store.deleteList(list.id) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Its tasks move to Inbox. Nothing is lost.")
        }
    }

    private var deleteTitle: String { "Delete “\(pendingDelete?.name ?? "")”?" }

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Lists")
            ForEach(store.sortedLists) { list in
                NavigationLink(value: ListsRoute.list(list.id)) {
                    ListCard(list: list, openCount: store.openCount(listID: list.id))
                }
                .buttonStyle(PressableButtonStyle())
                .contextMenu {
                    Button { router.present(.editList(list.id)) } label: { Label("Edit list", systemImage: "pencil") }
                    Button { router.present(.newTask(TaskPrefill(listID: list.id))) } label: { Label("Add task", systemImage: "plus") }
                    if !list.isInbox {
                        Button(role: .destructive) { pendingDelete = list } label: { Label("Delete list", systemImage: "trash") }
                    }
                }
            }

            Button {
                Haptics.tick()
                router.present(.newList)
            } label: {
                Label("Create a list", systemImage: "plus")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(SkyColor.onCanvas)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(SkyColor.raised, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityIdentifier("createListButton")
            .padding(.top, Space.xs)
        }
    }
}

struct ListCard: View {
    let list: TaskList
    let openCount: Int

    var body: some View {
        HStack(spacing: Space.md) {
            ListIconTile(list: list, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(list.name)
                    .font(SkyFont.cardTitle2)
                    .foregroundStyle(SkyColor.cardInk)
                    .lineLimit(1)
                Text(openCount == 0 ? "No open tasks" : (openCount == 1 ? "1 open task" : "\(openCount) open tasks"))
                    .font(SkyFont.meta)
                    .foregroundStyle(SkyColor.cardInkSecondary)
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(SkyColor.onCanvas)
                .frame(width: 40, height: 40)
                .background(SkyColor.cardInk, in: Circle())
                .accessibilityHidden(true)
        }
        .padding(Space.md)
        .background(SkyColor.pastel(list.color), in: RoundedRectangle(cornerRadius: Radius.bigCard, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: Space.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SkyColor.cardInkSecondary)
            TextField("Search tasks and lists", text: $text)
                .focused(focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .foregroundStyle(SkyColor.cardInk)
                .accessibilityIdentifier("searchField")
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SkyColor.cardInkSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Space.md)
        .frame(minHeight: 52)
        .background(Color.white, in: Capsule())
        // A white field on a light hero: render its placeholder/cursor in light appearance.
        .environment(\.colorScheme, .light)
    }
}

struct SearchResultsView: View {
    let results: TaskQueries.SearchResults
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            if results.isEmpty {
                EmptySkyState(title: "No matches", message: "Try a different word, or check the spelling.")
            }
            if !results.lists.isEmpty {
                SectionHeader(title: "Lists")
                ForEach(results.lists) { list in
                    NavigationLink(value: ListsRoute.list(list.id)) {
                        ListCard(list: list, openCount: store.openCount(listID: list.id))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            if !results.tasks.isEmpty {
                SectionHeader(title: "Tasks")
                ForEach(results.tasks.prefix(50)) { task in
                    TaskRow(model: TaskRowModel(task: task, list: store.list(task.listID), isOverdue: store.isOverdue(task),
                                                today: store.today, showDay: true),
                            compact: true,
                            onToggle: {
                                Haptics.tick()
                                store.toggleCompletion(task.id)
                            },
                            onOpen: { router.present(.task(task.id)) })
                }
            }
        }
    }
}
