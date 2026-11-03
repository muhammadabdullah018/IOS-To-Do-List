// Stub: only what Skyday uses.
import Foundation

public protocol Publisher {
    associatedtype Output
    associatedtype Failure: Error
}

public struct NotificationCenterPublisher: Publisher {
    public typealias Output = Notification
    public typealias Failure = Never
    public func receive<S>(on scheduler: S) -> NotificationCenterPublisher { self }
}

extension NotificationCenter {
    public func publisher(for name: Notification.Name, object: AnyObject? = nil) -> NotificationCenterPublisher { NotificationCenterPublisher() }
}
