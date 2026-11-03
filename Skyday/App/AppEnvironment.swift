import Foundation
import SwiftUI
import WidgetKit
import SkydayKit

/// Composition root. Owns the store and services, and wires side effects:
/// every committed change re-plans notifications and refreshes the widget snapshot.
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let store: SkydayStore
    let notifications: NotificationService
    let router: AppRouter
    let storageDirectory: URL

    private init() {
        let args = ProcessInfo.processInfo.arguments
        let isUITest = args.contains("-uiTesting")
        if isUITest {
            // UI tests use an isolated folder; "-resetData" wipes it for a clean first launch.
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent("SkydayUITest", isDirectory: true)
            if args.contains("-resetData") { try? FileManager.default.removeItem(at: dir) }
            storageDirectory = dir
        } else {
            storageDirectory = StorageLocation.dataDirectory()
        }
        store = SkydayStore(persistence: JSONFileStore(directory: storageDirectory))
        notifications = NotificationService()
        router = AppRouter()
        store.onCommit = { [weak self] data in self?.didCommit(data) }
    }

    func start() {
        notifications.registerCategories()
        Task {
            await notifications.refreshPermission()
            notifications.scheduleSync(store.data, calendar: store.calendar)
        }
        WidgetBridge.publish(store.data, now: store.now, calendar: store.calendar)
    }

    private func didCommit(_ data: AppData) {
        notifications.scheduleSync(data, calendar: store.calendar)
        WidgetBridge.publish(data, now: store.now, calendar: store.calendar)
    }
}

/// Where Skyday keeps its data. Prefers the App Group container so the widget can read the
/// snapshot; falls back to Application Support if the group isn't provisioned (e.g. when
/// signing without the App Groups capability), in which case only the widget loses data.
enum StorageLocation {
    static func groupDirectory() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SkydayIdentifiers.appGroup)
    }

    static func localDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Skyday", isDirectory: true)
    }

    static func dataDirectory() -> URL {
        let local = localDirectory()
        guard let group = groupDirectory() else { return local }
        // One-time move if data was created before the App Group became available.
        let fm = FileManager.default
        let localFile = local.appendingPathComponent("skyday.json")
        let groupFile = group.appendingPathComponent("skyday.json")
        if fm.fileExists(atPath: localFile.path) && !fm.fileExists(atPath: groupFile.path) {
            try? fm.createDirectory(at: group, withIntermediateDirectories: true)
            try? fm.copyItem(at: localFile, to: groupFile)
        }
        return group
    }
}

enum WidgetBridge {
    static func publish(_ data: AppData, now: Date, calendar: Calendar) {
        guard let dir = StorageLocation.groupDirectory() else { return }
        let snapshot = WidgetSnapshot.make(from: data, now: now, calendar: calendar)
        do {
            let encoded = try JSONFileStore.encoder().encode(snapshot)
            try encoded.write(to: dir.appendingPathComponent(WidgetSnapshot.fileName), options: .atomic)
            WidgetCenter.shared.reloadTimelines(ofKind: SkydayIdentifiers.widgetKind)
        } catch {
            // Widget shows its last snapshot; the app is unaffected.
        }
    }
}
