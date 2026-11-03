// Stub of the UIKit surface Skyday touches.
import Foundation

public typealias CGFloat = Foundation.CGFloat

public enum UIUserInterfaceStyle: Int { case unspecified, light, dark }

open class UITraitCollection: NSObject {
    open var userInterfaceStyle: UIUserInterfaceStyle { .light }
}

open class UIColor: NSObject {
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {}
    public init(dynamicProvider: @escaping (UITraitCollection) -> UIColor) {}
}

public enum UIImpactFeedbackStyle: Int { case light, medium, heavy, soft, rigid }

open class UIImpactFeedbackGenerator: NSObject {
    public init(style: UIImpactFeedbackStyle) {}
    open func impactOccurred() {}
    open func impactOccurred(intensity: CGFloat) {}
}

public enum UINotificationFeedbackType: Int { case success, warning, error }

open class UINotificationFeedbackGenerator: NSObject {
    public override init() {}
    open func notificationOccurred(_ type: UINotificationFeedbackType) {}
}

open class UISelectionFeedbackGenerator: NSObject {
    public override init() {}
    open func selectionChanged() {}
}

open class UIApplication: NSObject {
    public static var shared: UIApplication { UIApplication() }
    public static let openNotificationSettingsURLString = "app-settings:notifications"
    public static let significantTimeChangeNotification = Notification.Name("UIApplicationSignificantTimeChangeNotification")
    open func open(_ url: URL, options: [OpenExternalURLOptionsKey: Any] = [:], completionHandler: ((Bool) -> Void)? = nil) {}

    public struct OpenExternalURLOptionsKey: Hashable { public let rawValue: String }

    public struct LaunchOptionsKey: Hashable { public let rawValue: String }
}

public protocol UIApplicationDelegate: AnyObject {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
}

extension UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { true }
}

public struct UITextContentType: Hashable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let givenName = UITextContentType(rawValue: "givenName")
}
