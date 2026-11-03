import SwiftUI
import SkydayKit

enum AppTab: Hashable {
    case today, lists, progress
}

/// Pre-filled values for the New Task sheet.
struct TaskPrefill: Hashable {
    var listID: UUID?
    var dueDay: DayKey?
}

enum SheetRoute: Identifiable, Hashable {
    case newTask(TaskPrefill)
    case task(UUID)
    case newList
    case editList(UUID)
    case settings

    var id: String {
        switch self {
        case .newTask(let p): return "new-\(p.listID?.uuidString ?? "-")-\(p.dueDay?.description ?? "-")"
        case .task(let id): return "task-\(id.uuidString)"
        case .newList: return "new-list"
        case .editList(let id): return "edit-list-\(id.uuidString)"
        case .settings: return "settings"
        }
    }
}

enum TodayRoute: Hashable {
    case plan(DayKey)
}

enum ListsRoute: Hashable {
    case list(UUID)
}

/// Navigation state for the three-tab shell. Exactly three tabs; everything else is a
/// sheet or a pushed destination.
@MainActor
@Observable
final class AppRouter {
    var tab: AppTab = .today
    var todayPath: [TodayRoute] = []
    var listsPath: [ListsRoute] = []
    var sheet: SheetRoute?
    /// Bumped when the user re-taps a tab or follows a deep link, so screens can scroll to top.
    var scrollToTopToken = 0

    /// Presents a sheet. If one is already open (for example the user is mid-edit when a
    /// notification is tapped) the open sheet wins: replacing it would discard unsaved edits.
    func present(_ route: SheetRoute) {
        guard sheet == nil else { return }
        sheet = route
    }

    func handle(_ link: DeepLink, store: SkydayStore) {
        switch link {
        case .today:
            tab = .today
            todayPath = []
        case .newTask:
            tab = .today
            present(.newTask(TaskPrefill(dueDay: store.today)))
        case .lists:
            tab = .lists
        case .progress:
            tab = .progress
        case .task(let id):
            guard store.task(id) != nil else { tab = .today; return }
            present(.task(id))
        }
    }
}
