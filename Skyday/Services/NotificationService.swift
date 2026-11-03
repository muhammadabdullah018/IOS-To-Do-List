import Foundation
import Observation
import UIKit
import UserNotifications
import SkydayKit

/// Applies `ReminderPlanner` output to UNUserNotificationCenter.
///
/// - Permission is requested in context (first reminder or digest), never at launch.
/// - Sync is diff-based with stable IDs: unchanged requests are left alone, changed ones are
///   replaced, stale ones removed. Only `skyday.`-prefixed requests are ever touched.
/// - If permission is denied, tasks still save; the editor and Settings show how to enable it.
@MainActor
@Observable
final class NotificationService {
    enum Permission: Equatable {
        case unknown, notDetermined, denied, allowed
    }

    private(set) var permission: Permission = .unknown
    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private var syncTask: Task<Void, Never>?

    var canSchedule: Bool { permission == .allowed }

    func registerCategories() {
        let complete = UNNotificationAction(identifier: SkydayIdentifiers.completeAction, title: "Complete", options: [])
        let snooze = UNNotificationAction(identifier: SkydayIdentifiers.snoozeAction, title: "Remind me in 1 hour", options: [])
        let category = UNNotificationCategory(identifier: SkydayIdentifiers.reminderCategory,
                                              actions: [complete, snooze], intentIdentifiers: [],
                                              hiddenPreviewsBodyPlaceholder: "Skyday reminder",
                                              options: [])
        center.setNotificationCategories([category])
    }

    func refreshPermission() async {
        let settings = await center.notificationSettings()
        permission = Self.map(settings.authorizationStatus)
    }

    /// Asks for permission only if the user has never been asked. Returns whether alerts are allowed.
    @discardableResult
    func requestPermissionIfNeeded() async -> Bool {
        await refreshPermission()
        guard permission == .notDetermined else { return permission == .allowed }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permission = granted ? .allowed : .denied
        } catch {
            permission = .denied
        }
        return permission == .allowed
    }

    func openSystemSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    /// Debounced so a burst of edits produces one sync.
    func scheduleSync(_ data: AppData, calendar: Calendar) {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await self?.sync(data, calendar: calendar)
        }
    }

    func sync(_ data: AppData, calendar: Calendar) async {
        await refreshPermission()
        let pendingRequests = await center.pendingNotificationRequests()
        let pending = pendingRequests.map {
            PendingNotification(id: $0.identifier, fingerprint: ($0.content.userInfo[SkydayIdentifiers.fingerprintKey] as? String) ?? "")
        }
        // Without permission, desired = [] so stale requests are still cleaned up.
        // The sound setting is part of each request, so it is part of the fingerprint too.
        let sound = data.settings.reminderSound
        let desired = canSchedule ? ReminderPlanner.plan(data, now: Date(), calendar: calendar) : []
        let diff = ReminderPlanner.diff(pending: pending, desired: desired, fingerprintSuffix: sound ? "|s1" : "|s0")
        if !diff.remove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: diff.remove)
        }
        for planned in diff.add {
            let request = makeRequest(planned, sound: sound, calendar: calendar)
            do { try await center.add(request) } catch { /* System rejected; next sync retries. */ }
        }
        // Delivered reminders are stale once their task is completed or deleted, or (for
        // recurring tasks) once the series has moved past that occurrence.
        let byID = Dictionary(uniqueKeysWithValues: data.tasks.map { ($0.id.uuidString, $0) })
        let delivered = await center.deliveredNotifications()
        let staleDelivered = delivered.compactMap { note -> String? in
            let info = note.request.content.userInfo
            guard note.request.identifier.hasPrefix(ReminderPlanner.idPrefix),
                  let id = info[SkydayIdentifiers.taskIDKey] as? String else { return nil }
            guard let task = byID[id], !task.isCompleted else { return note.request.identifier }
            if let raw = info["occurrence"] as? String, let occurrence = DayKey(string: raw),
               let due = task.dueDay, occurrence < due {
                return note.request.identifier
            }
            return nil
        }
        if !staleDelivered.isEmpty { center.removeDeliveredNotifications(withIdentifiers: staleDelivered) }
    }

    private func makeRequest(_ planned: PlannedNotification, sound: Bool, calendar: Calendar) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = planned.title
        content.body = planned.body
        if sound { content.sound = .default }
        var info: [String: Any] = [SkydayIdentifiers.fingerprintKey: planned.fingerprint + (sound ? "|s1" : "|s0")]
        if let taskID = planned.taskID { info[SkydayIdentifiers.taskIDKey] = taskID.uuidString }
        // The occurrence day is the last ID component for task requests.
        if planned.kind == .task, let day = planned.id.split(separator: ".").last { info["occurrence"] = String(day) }
        content.userInfo = info
        switch planned.kind {
        case .task, .snooze:
            content.categoryIdentifier = SkydayIdentifiers.reminderCategory
            content.threadIdentifier = "skyday.tasks"
        case .morningDigest, .eveningDigest:
            content.threadIdentifier = "skyday.digest"
        }
        // Wall-clock components: a 9:00 reminder fires at 9:00 local even after travel,
        // matching Skyday's floating-day model. Re-planned on every time-zone change.
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: planned.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: planned.id, content: content, trigger: trigger)
    }

    private static func map(_ status: UNAuthorizationStatus) -> Permission {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .allowed
        @unknown default: return .denied
        }
    }
}

/// UNUserNotificationCenter delegate. Kept separate from the @MainActor service and hops to
/// the main actor before touching app state.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        let taskID = (info[SkydayIdentifiers.taskIDKey] as? String).flatMap(UUID.init(uuidString:))
        let occurrence = (info["occurrence"] as? String).flatMap(DayKey.init(string:))
        let action = response.actionIdentifier
        Task { @MainActor in
            let env = AppEnvironment.shared
            defer { completionHandler() }
            if let taskID {
                switch action {
                case SkydayIdentifiers.completeAction:
                    env.store.complete(taskID, expectedOccurrence: occurrence)
                    // The app may be suspended right after completionHandler, so re-plan now
                    // instead of relying on the debounced sync.
                    await env.notifications.sync(env.store.data, calendar: env.store.calendar)
                case SkydayIdentifiers.snoozeAction:
                    env.store.snooze(taskID, minutes: 60)
                    await env.notifications.sync(env.store.data, calendar: env.store.calendar)
                case UNNotificationDefaultActionIdentifier:
                    env.router.handle(.task(taskID), store: env.store)
                default:
                    break
                }
            } else if action == UNNotificationDefaultActionIdentifier {
                env.router.handle(.today, store: env.store)
            }
        }
    }
}
