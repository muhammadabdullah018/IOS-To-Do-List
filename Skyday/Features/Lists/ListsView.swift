import SwiftUI
import SkydayKit

struct ListsView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @State private var query = ""
    @State private var pendingDelete: TaskList?
    @FocusState private var searchFocused: Bool

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SkyHeader(scene: .lists, height: 150, topInset: geo.safeAreaInsets.top) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                SkyTitle(text: "Lists")
                                Text(summaryLine)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(SkyColor.onSky)
                                    .shadow(color: SkyColor.skyTextShadow, radius: 2, x: 0, y: 1)
                            }
                            Spacer()
                            SkyCircleButton(systemImage: "plus", label: "Create a list") {
                                Haptics.tick()
                                router.present(.newList)
                            }
                            .accessibilityIdentifier("createListButton")
                        }
                    }

                    VStack(alignment: .leading, spacing: Space.md) {
                        SearchField(text: $query, focused: $searchFocused)
                        if query.trimmingCharacters(in: .whitespaces).isEmpty {
                            listsSection
                        } else {
                            SearchResultsView(results: store.search(query))
                        }
                    }
                    .padding(.horizontal, Space.md)
                    .padding(.top, -24)
                    .padding(.bottom, Space.xl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .background(SkyColor.page.ignoresSafeArea())
        }
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

    private var summaryLine: String {
        let open = store.data.tasks.filter { !$0.isCompleted }.count
        return "\(store.data.lists.count) lists · \(open) open \(open == 1 ? "task" : "tasks")"
    }

    private var deleteTitle: String { "Delete “\(pendingDelete?.name ?? "")”?" }

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            ForEach(Array(store.sortedLists.enumerated()), id: \.element.id) { index, list in
                NavigationLink(value: ListsRoute.list(list.id)) {
                    ListCard(list: list, openCount: store.openCount(listID: list.id))
                }
                .buttonStyle(PressableButtonStyle())
                .staggeredAppear(index)
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
                    .foregroundStyle(SkyColor.deepSky)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(SkyColor.lightSky, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, Space.xxs)
        }
    }
}

struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: Space.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SkyColor.inkSecondary)
            TextField("Search tasks and lists", text: $text)
                .focused(focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .foregroundStyle(SkyColor.ink)
                .accessibilityIdentifier("searchField")
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SkyColor.inkSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Space.md)
        .frame(minHeight: 52)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        .shadow(color: Color(hex: 0x0593C6, alpha: 0.08), radius: 8, x: 0, y: 4)
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
