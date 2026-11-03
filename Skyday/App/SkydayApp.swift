import SwiftUI
import UIKit
import UserNotifications
import SkydayKit

final class SkydayAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Must be set before launch finishes so notification actions that launch the app are delivered.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        return true
    }
}

@main
struct SkydayApp: App {
    @UIApplicationDelegateAdaptor(SkydayAppDelegate.self) private var appDelegate
    private let env = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env.store)
                .environment(env.router)
                .environment(env.notifications)
                .onAppear { env.start() }
        }
    }
}
