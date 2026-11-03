// WidgetKit TYPE-CHECK STUB (iOS 17 signatures, subset).
import Foundation
import SwiftUI

public protocol TimelineEntry { var date: Date { get } }

public enum WidgetFamily: Hashable { case systemSmall, systemMedium, systemLarge, accessoryCircular, accessoryRectangular }

extension EnvironmentValues {
    public var widgetFamily: WidgetFamily { fatalError() }
}

public struct TimelineProviderContext { public var family: WidgetFamily { .systemSmall }; public var isPreview: Bool { false } }

public struct TimelineReloadPolicy {
    public static let atEnd = TimelineReloadPolicy(), never = TimelineReloadPolicy()
    public static func after(_ date: Date) -> TimelineReloadPolicy { TimelineReloadPolicy() }
}

public struct Timeline<EntryType: TimelineEntry> {
    public init(entries: [EntryType], policy: TimelineReloadPolicy) {}
}

public protocol TimelineProvider {
    associatedtype Entry: TimelineEntry
    typealias Context = TimelineProviderContext
    func placeholder(in context: Context) -> Entry
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void)
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void)
}

public protocol WidgetConfiguration {}
public struct StaticConfiguration<Content: View>: WidgetConfiguration {
    public init<P: TimelineProvider>(kind: String, provider: P, @ViewBuilder content: @escaping (P.Entry) -> Content) {}
    public func configurationDisplayName(_ s: String) -> StaticConfiguration { self }
    public func description(_ s: String) -> StaticConfiguration { self }
    public func supportedFamilies(_ families: [WidgetFamily]) -> StaticConfiguration { self }
}

@resultBuilder public enum WidgetConfigurationBuilder {
    public static func buildBlock<C: WidgetConfiguration>(_ c: C) -> C { c }
}

public protocol Widget {
    associatedtype Body: WidgetConfiguration
    init()
    @WidgetConfigurationBuilder var body: Body { get }
}

@resultBuilder public enum WidgetBundleBuilder {
    public static func buildBlock<each W: Widget>(_ w: repeat each W) -> _WidgetTuple { _WidgetTuple() }
}
public struct _WidgetTuple: Widget { public init() {}; public var body: StaticConfiguration<EmptyView> { let c: StaticConfiguration<EmptyView>? = nil; return c! } }

extension WidgetBundle { public static func main() {} }

public protocol WidgetBundle {
    associatedtype Body: Widget
    init()
    @WidgetBundleBuilder var body: Body { get }
}

public struct ContainerBackgroundPlacement { public static let widget = ContainerBackgroundPlacement() }

extension View {
    public func containerBackground<V: View>(for placement: ContainerBackgroundPlacement, alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View { _V() }
    public func widgetURL(_ url: URL?) -> some View { _V() }
}

public final class WidgetCenter {
    public static let shared = WidgetCenter()
    public func reloadTimelines(ofKind kind: String) {}
    public func reloadAllTimelines() {}
}
