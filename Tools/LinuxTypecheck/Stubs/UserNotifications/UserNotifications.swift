// Stub of the UserNotifications API surface Skyday uses (iOS 17 signatures).
import Foundation

public enum UNAuthorizationStatus: Int { case notDetermined, denied, authorized, provisional, ephemeral }

public struct UNAuthorizationOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let badge = UNAuthorizationOptions(rawValue: 1)
    public static let sound = UNAuthorizationOptions(rawValue: 2)
    public static let alert = UNAuthorizationOptions(rawValue: 4)
}

public struct UNNotificationPresentationOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let badge = UNNotificationPresentationOptions(rawValue: 1)
    public static let sound = UNNotificationPresentationOptions(rawValue: 2)
    public static let list = UNNotificationPresentationOptions(rawValue: 8)
    public static let banner = UNNotificationPresentationOptions(rawValue: 16)
}

public struct UNNotificationActionOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let foreground = UNNotificationActionOptions(rawValue: 4)
}

public struct UNNotificationCategoryOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
}

open class UNNotificationSettings: NSObject {
    open var authorizationStatus: UNAuthorizationStatus { .notDetermined }
}

open class UNNotificationSound: NSObject {
    open class var `default`: UNNotificationSound { UNNotificationSound() }
}

open class UNNotificationContent: NSObject {
    open var title: String { "" }
    open var body: String { "" }
    open var userInfo: [AnyHashable: Any] { [:] }
}

open class UNMutableNotificationContent: UNNotificationContent {
    public var _title = "", _body = ""
    open override var title: String { get { _title } set { _title = newValue } }
    open override var body: String { get { _body } set { _body = newValue } }
    open var sound: UNNotificationSound?
    open var categoryIdentifier: String = ""
    open var threadIdentifier: String = ""
    public var _userInfo: [AnyHashable: Any] = [:]
    open override var userInfo: [AnyHashable: Any] { get { _userInfo } set { _userInfo = newValue } }
}

open class UNNotificationTrigger: NSObject {}

open class UNCalendarNotificationTrigger: UNNotificationTrigger {
    public init(dateMatching dateComponents: DateComponents, repeats: Bool) {}
}

open class UNNotificationRequest: NSObject {
    public init(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger?) {
        self.identifier = identifier
        self.content = content
    }
    public let identifier: String
    public let content: UNNotificationContent
}

open class UNNotification: NSObject {
    open var request: UNNotificationRequest { fatalError() }
}

public let UNNotificationDefaultActionIdentifier = "com.apple.UNNotificationDefaultActionIdentifier"

open class UNNotificationResponse: NSObject {
    open var notification: UNNotification { fatalError() }
    open var actionIdentifier: String { "" }
}

open class UNNotificationAction: NSObject {
    public init(identifier: String, title: String, options: UNNotificationActionOptions = []) {}
}

open class UNNotificationCategory: NSObject {
    public init(identifier: String, actions: [UNNotificationAction], intentIdentifiers: [String], options: UNNotificationCategoryOptions = []) {}
}

public protocol UNUserNotificationCenterDelegate: NSObjectProtocol {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
}

open class UNUserNotificationCenter: NSObject {
    open class func current() -> UNUserNotificationCenter { UNUserNotificationCenter() }
    open weak var delegate: UNUserNotificationCenterDelegate?
    open func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {}
    open func notificationSettings() async -> UNNotificationSettings { UNNotificationSettings() }
    open func requestAuthorization(options: UNAuthorizationOptions = []) async throws -> Bool { true }
    open func pendingNotificationRequests() async -> [UNNotificationRequest] { [] }
    open func deliveredNotifications() async -> [UNNotification] { [] }
    open func add(_ request: UNNotificationRequest) async throws {}
    open func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
    open func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
}
