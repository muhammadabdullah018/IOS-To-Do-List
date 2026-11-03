import SwiftUI
import Combine
import UIKit
import SkydayKit

struct RootView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(NotificationService.self) private var notifications
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSplash = !Motion.isUITesting

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            NavigationStack(path: $router.todayPath) {
                TodayView()
                    .navigationDestination(for: TodayRoute.self) { route in
                        switch route {
                        case .plan(let day): PlanView(initialDay: day)
                        }
                    }
            }
            .tabItem { Label("Today", systemImage: "house") }
            .tag(AppTab.today)

            NavigationStack(path: $router.listsPath) {
                ListsView()
                    .navigationDestination(for: ListsRoute.self) { route in
                        switch route {
                        case .list(let id): ListDetailView(listID: id)
                        }
                    }
            }
            .tabItem { Label("Lists", systemImage: "square.stack.3d.up") }
            .tag(AppTab.lists)

            NavigationStack(path: $router.progressPath) {
                ProgressScreen()
                    .navigationDestination(for: ProgressRoute.self) { route in
                        switch route {
                        case .streaks: StreaksView()
                        }
                    }
            }
            .tabItem { Label("Progress", systemImage: "chart.bar") }
            .tag(AppTab.progress)
        }
        .tint(SkyColor.sky)
        // The reference design is a bright daytime sky; night is expressed by the Today
        // header art after 20:00, not by system dark mode.
        .preferredColorScheme(.light)
        .sheet(item: $router.sheet) { route in
            sheetContent(route)
        }
        .overlay(alignment: .bottom) { undoOverlay }
        .overlay {
            if showSplash && !reduceMotion {
                LaunchSplash(isVisible: $showSplash).transition(.opacity)
            }
        }
        .alert("Data recovery", isPresented: Binding(get: { store.recoveryNotice != nil },
                                                     set: { if !$0 { store.dismissRecoveryNotice() } })) {
            Button("OK", role: .cancel) { store.dismissRecoveryNotice() }
        } message: {
            Text(store.recoveryNotice ?? "")
        }
        .onOpenURL { url in
            if let link = DeepLink(url: url) { router.handle(link, store: store) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refreshForNewDay()
                Task { await notifications.refreshPermission() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            store.refreshForNewDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification).receive(on: RunLoop.main)) { _ in
            store.refreshForNewDay()
        }
    }

    @ViewBuilder
    private func sheetContent(_ route: SheetRoute) -> some View {
        switch route {
        case .newTask(let prefill):
            TaskEditorSheet(mode: .create(prefill))
        case .task(let id):
            TaskEditorSheet(mode: .edit(id))
        case .newList:
            ListEditorSheet(listID: nil)
        case .editList(let id):
            ListEditorSheet(listID: id)
        case .settings:
            SettingsView()
        }
    }

    private var undoOverlay: some View {
        ZStack {
            if let token = store.pendingUndo {
                UndoToast(message: token.message) {
                    Haptics.soft()
                    store.undo()
                }
                .padding(.bottom, 58) // above the tab bar (overlay sits in the safe area)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .id(token.id)
                .task(id: token.id) {
                    try? await Task.sleep(nanoseconds: 4_500_000_000)
                    if store.pendingUndo?.id == token.id { store.clearUndo() }
                }
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : Motion.settle, value: store.pendingUndo?.id)
    }
}
