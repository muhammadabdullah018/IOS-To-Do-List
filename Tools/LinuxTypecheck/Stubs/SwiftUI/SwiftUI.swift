// SwiftUI TYPE-CHECK STUB (Linux). Signatures mirror the iOS 17 SDK for the subset Skyday uses.
// Bodies are never executed. Keep signatures faithful: a stub that is looser than the real SDK
// hides real errors. When a real Xcode build disagrees with this file, Xcode wins.
@_exported import Foundation
@_exported import Observation
@_exported import UIKit
import Combine
import UniformTypeIdentifiers

// MARK: - Core protocols

// Since the iOS 18 SDK (Xcode 16) View, ViewModifier, ButtonStyle and App are @MainActor.
@MainActor @preconcurrency
public protocol View {
    associatedtype Body: View
    @ViewBuilder @MainActor var body: Body { get }
}

extension Never: View {
    public typealias Body = Never
    public var body: Never { fatalError() }
}

public struct _V: View {
    public init() {}
    public var body: Never { fatalError() }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<C: View>(_ c: C) -> C { c }
    public static func buildBlock<each C: View>(_ c: repeat each C) -> TupleView<(repeat each C)> { TupleView() }
    public static func buildExpression<C: View>(_ c: C) -> C { c }
    public static func buildIf<C: View>(_ c: C?) -> C? { c }
    public static func buildOptional<C: View>(_ c: C?) -> C? { c }
    public static func buildEither<T: View, F: View>(first: T) -> _ConditionalContent<T, F> { _ConditionalContent() }
    public static func buildEither<T: View, F: View>(second: F) -> _ConditionalContent<T, F> { _ConditionalContent() }
    public static func buildLimitedAvailability<C: View>(_ c: C) -> AnyView { AnyView(c) }
}

extension Optional: View where Wrapped: View {
    public var body: Never { fatalError() }
}

public struct TupleView<T>: View {
    public init() {}
    public var body: Never { fatalError() }
}

public struct _ConditionalContent<T, F>: View {
    public init() {}
    public var body: Never { fatalError() }
}

public struct AnyView: View {
    public init<V: View>(_ v: V) {}
    public var body: Never { fatalError() }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { fatalError() }
}

@MainActor @preconcurrency
public protocol ViewModifier {
    associatedtype Body: View
    typealias Content = _ViewModifier_Content<Self>
    @ViewBuilder @MainActor func body(content: Content) -> Body
}

public struct _ViewModifier_Content<M>: View {
    public var body: Never { fatalError() }
}

// MARK: - Property wrappers

@propertyWrapper
public struct State<Value>: DynamicProperty {
    public init(wrappedValue: Value) {}
    public init(initialValue: Value) {}
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: Binding<Value> { fatalError() }
}

public protocol DynamicProperty {}

@propertyWrapper @dynamicMemberLookup
public struct Binding<Value> {
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {}
    public static func constant(_ value: Value) -> Binding<Value> { fatalError() }
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: Binding<Value> { self }
    public init(projectedValue: Binding<Value>) {}
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Binding<Subject> { fatalError() }
}

extension Binding: Identifiable where Value: Identifiable {
    public var id: Value.ID { fatalError() }
}

extension Binding: Sequence where Value: MutableCollection {
    public typealias Element = Binding<Value.Element>
    public typealias Iterator = IndexingIterator<Binding<Value>>
    public func makeIterator() -> IndexingIterator<Binding<Value>> { fatalError() }
}

extension Binding: Collection where Value: MutableCollection {
    public typealias Index = Value.Index
    public typealias Indices = Value.Indices
    public var startIndex: Value.Index { fatalError() }
    public var endIndex: Value.Index { fatalError() }
    public var indices: Value.Indices { fatalError() }
    public func index(after i: Value.Index) -> Value.Index { fatalError() }
    public subscript(position: Value.Index) -> Binding<Value.Element> { fatalError() }
}

extension Binding: BidirectionalCollection where Value: BidirectionalCollection, Value: MutableCollection {
    public func index(before i: Value.Index) -> Value.Index { fatalError() }
}

extension Binding: RandomAccessCollection where Value: RandomAccessCollection, Value: MutableCollection {}

@propertyWrapper @dynamicMemberLookup
public struct Bindable<Value> {
    public init(wrappedValue: Value) where Value: AnyObject & Observable {}
    public var wrappedValue: Value { fatalError() }
    public var projectedValue: Bindable<Value> { self }
    public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>) -> Binding<Subject> { fatalError() }
}

@propertyWrapper
public struct Environment<Value>: DynamicProperty {
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {}
    public init(_ objectType: Value.Type) where Value: AnyObject & Observable {}
    public var wrappedValue: Value { fatalError() }
}

@propertyWrapper
public struct FocusState<Value: Hashable>: DynamicProperty {
    public init() where Value == Bool {}
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: FocusState<Value>.Binding { fatalError() }
    public struct Binding {
        public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    }
}

@propertyWrapper
public struct AppStorage<Value>: DynamicProperty {
    public init(wrappedValue: Value, _ key: String) where Value == String {}
    public init(wrappedValue: Value, _ key: String) where Value == Int {}
    public init(wrappedValue: Value, _ key: String) where Value == Bool {}
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: Binding<Value> { fatalError() }
}

@propertyWrapper
public struct UIApplicationDelegateAdaptor<DelegateType: NSObject & UIApplicationDelegate>: DynamicProperty {
    public init(_ delegateType: DelegateType.Type = DelegateType.self) {}
    public var wrappedValue: DelegateType { fatalError() }
}

// MARK: - Environment values

public struct EnvironmentValues {
    public var dismiss: DismissAction { fatalError() }
    public var scenePhase: ScenePhase { fatalError() }
    public var accessibilityReduceMotion: Bool { fatalError() }
    public var dynamicTypeSize: DynamicTypeSize { fatalError() }
    public var displayScale: CGFloat { fatalError() }
    public var colorScheme: ColorScheme { get { fatalError() } set {} }
}

public struct DismissAction {
    public func callAsFunction() {}
}

public enum ScenePhase: Hashable { case background, inactive, active }
public enum ColorScheme: Hashable { case light, dark }

public enum DynamicTypeSize: Hashable, Comparable, CaseIterable {
    case xSmall, small, medium, large, xLarge, xxLarge, xxxLarge, accessibility1, accessibility2, accessibility3, accessibility4, accessibility5
    public var isAccessibilitySize: Bool { false }
}

// MARK: - Geometry & layout types

public struct Alignment: Equatable {
    public static let center = Alignment(), leading = Alignment(), trailing = Alignment(), top = Alignment(), bottom = Alignment()
    public static let topLeading = Alignment(), topTrailing = Alignment(), bottomLeading = Alignment(), bottomTrailing = Alignment()
}

public struct HorizontalAlignment: Equatable {
    public static let leading = HorizontalAlignment(), center = HorizontalAlignment(), trailing = HorizontalAlignment()
}

public struct VerticalAlignment: Equatable {
    public static let top = VerticalAlignment(), center = VerticalAlignment(), bottom = VerticalAlignment()
    public static let firstTextBaseline = VerticalAlignment(), lastTextBaseline = VerticalAlignment()
}

public enum Edge: Int8, CaseIterable {
    case top, leading, bottom, trailing
    public struct Set: OptionSet {
        public let rawValue: Int8
        public init(rawValue: Int8) { self.rawValue = rawValue }
        public static let top = Set(rawValue: 1), leading = Set(rawValue: 2), bottom = Set(rawValue: 4), trailing = Set(rawValue: 8)
        public static let all = Set(rawValue: 15), horizontal = Set(rawValue: 10), vertical = Set(rawValue: 5)
    }
}

public struct EdgeInsets: Equatable {
    public var top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0
    public init() {}
    public init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {}
}

public enum ContentMode: Hashable { case fit, fill }

public struct UnitPoint: Hashable {
    public static let center = UnitPoint(), top = UnitPoint(), bottom = UnitPoint(), leading = UnitPoint(), trailing = UnitPoint()
}

public struct SafeAreaRegions: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let all = SafeAreaRegions(rawValue: 1), container = SafeAreaRegions(rawValue: 2), keyboard = SafeAreaRegions(rawValue: 4)
}

public struct Angle {
    public static func degrees(_ d: Double) -> Angle { Angle() }
    public static func radians(_ r: Double) -> Angle { Angle() }
}

// MARK: - Color, Font, styles

public protocol ShapeStyle {}

public struct Color: View, ShapeStyle, Hashable {
    public enum RGBColorSpace { case sRGB, sRGBLinear, displayP3 }
    public init(_ colorSpace: RGBColorSpace = .sRGB, red: Double, green: Double, blue: Double, opacity: Double = 1) {}
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {}
    public init(uiColor: UIColor) {}
    public init(_ name: String) {}
    public func opacity(_ o: Double) -> Color { self }
    public static let white = Color(red: 1, green: 1, blue: 1), black = Color(red: 0, green: 0, blue: 0)
    public static let clear = Color(red: 0, green: 0, blue: 0), primary = Color(red: 0, green: 0, blue: 0)
    public static let secondary = Color(red: 0, green: 0, blue: 0), accentColor = Color(red: 0, green: 0, blue: 0)
    public var body: Never { fatalError() }
}

extension ShapeStyle where Self == Color {
    public static var white: Color { .white }
    public static var clear: Color { .clear }
}

public struct LinearGradient: ShapeStyle, View {
    public init(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) {}
    public var body: Never { fatalError() }
}

public struct HierarchicalShapeStyle: ShapeStyle {
    public static let primary = HierarchicalShapeStyle(), secondary = HierarchicalShapeStyle()
}

extension ShapeStyle where Self == HierarchicalShapeStyle {
    public static var secondary: HierarchicalShapeStyle { .secondary }
}

public struct Font: Hashable {
    public enum TextStyle: CaseIterable { case largeTitle, title, title2, title3, headline, subheadline, body, callout, footnote, caption, caption2 }
    public struct Weight: Hashable {
        public static let ultraLight = Weight(), thin = Weight(), light = Weight(), regular = Weight(), medium = Weight()
        public static let semibold = Weight(), bold = Weight(), heavy = Weight(), black = Weight()
    }
    public enum Design: Hashable { case `default`, serif, rounded, monospaced }
    public static func system(_ style: TextStyle, design: Design? = nil, weight: Weight? = nil) -> Font { Font() }
    public static func system(size: CGFloat, weight: Weight? = nil, design: Design? = nil) -> Font { Font() }
    public static let largeTitle = Font(), title = Font(), title2 = Font(), title3 = Font(), headline = Font(), subheadline = Font()
    public static let body = Font(), callout = Font(), footnote = Font(), caption = Font(), caption2 = Font()
    public func weight(_ w: Weight) -> Font { self }
}

public enum TextAlignment: Hashable { case leading, center, trailing }

public struct ContentTransition {
    public static func numericText(countsDown: Bool = false) -> ContentTransition { ContentTransition() }
    public static let opacity = ContentTransition(), identity = ContentTransition()
}

public struct Visibility: Hashable { public static let automatic = Visibility(), visible = Visibility(), hidden = Visibility() }

// MARK: - Animation

public struct Animation: Equatable {
    public static func spring(response: Double = 0.5, dampingFraction: Double = 0.825, blendDuration: Double = 0) -> Animation { Animation() }
    public static func easeInOut(duration: Double) -> Animation { Animation() }
    public static func easeOut(duration: Double) -> Animation { Animation() }
    public static func linear(duration: Double) -> Animation { Animation() }
    public static let `default` = Animation(), easeInOut = Animation(), snappy = Animation(), smooth = Animation()
}

@discardableResult
public func withAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result { try body() }

public struct AnyTransition {
    public static let opacity = AnyTransition(), identity = AnyTransition()
    public static func move(edge: Edge) -> AnyTransition { AnyTransition() }
    public static func scale(scale: CGFloat, anchor: UnitPoint = .center) -> AnyTransition { AnyTransition() }
    public static func asymmetric(insertion: AnyTransition, removal: AnyTransition) -> AnyTransition { AnyTransition() }
    public func combined(with other: AnyTransition) -> AnyTransition { self }
}

// MARK: - Accessibility

public struct AccessibilityTraits: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let isButton = AccessibilityTraits(rawValue: 1), isHeader = AccessibilityTraits(rawValue: 2)
    public static let isSelected = AccessibilityTraits(rawValue: 4)
}

public enum AccessibilityChildBehavior { case ignore, contain, combine }

// MARK: - Text, Image, Label

public struct Text: View, Equatable {
    public init(_ content: String) {}
    public init<S: StringProtocol>(_ content: S) {}
    public init(verbatim: String) {}
    public var body: Never { fatalError() }
}

public struct Image: View {
    public init(systemName: String) {}
    public init(_ name: String) {}
    public enum Interpolation { case none, low, medium, high }
    public func resizable() -> Image { self }
    public func interpolation(_ i: Interpolation) -> Image { self }
    public enum Scale { case small, medium, large }
    public var body: Never { fatalError() }
}

public struct Label<Title: View, Icon: View>: View {
    public init(_ title: String, systemImage: String) where Title == Text, Icon == Image {}
    public init(@ViewBuilder title: () -> Title, @ViewBuilder icon: () -> Icon) {}
    public var body: Never { fatalError() }
}

public protocol LabelStyle {}
public struct TitleAndIconLabelStyle: LabelStyle {}
extension LabelStyle where Self == TitleAndIconLabelStyle { public static var titleAndIcon: TitleAndIconLabelStyle { .init() } }

// MARK: - Controls

public struct ButtonRole: Equatable { public static let destructive = ButtonRole(), cancel = ButtonRole() }

public struct Button<Label: View>: View {
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {}
    public init(role: ButtonRole?, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {}
    public init(_ title: String, action: @escaping () -> Void) where Label == Text {}
    public init(_ title: String, role: ButtonRole?, action: @escaping () -> Void) where Label == Text {}
    public var body: Never { fatalError() }
}

@MainActor @preconcurrency
public protocol ButtonStyle {
    associatedtype Body: View
    typealias Configuration = ButtonStyleConfiguration
    @ViewBuilder @MainActor func makeBody(configuration: Configuration) -> Body
}

public struct ButtonStyleConfiguration {
    public struct Label: View { public var body: Never { fatalError() } }
    public let label: Label
    public let isPressed: Bool
}

public protocol PrimitiveButtonStyle {}
public struct PlainButtonStyle: PrimitiveButtonStyle {}
extension PrimitiveButtonStyle where Self == PlainButtonStyle { public static var plain: PlainButtonStyle { .init() } }

public struct Toggle<Label: View>: View {
    public init(_ title: String, isOn: Binding<Bool>) where Label == Text {}
    public init(isOn: Binding<Bool>, @ViewBuilder label: () -> Label) {}
    public var body: Never { fatalError() }
}

public struct Picker<Label: View, SelectionValue: Hashable, Content: View>: View {
    public init(_ title: String, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) where Label == Text {}
    public var body: Never { fatalError() }
}

public protocol PickerStyle {}
public struct SegmentedPickerStyle: PickerStyle {}
public struct MenuPickerStyle: PickerStyle {}
extension PickerStyle where Self == SegmentedPickerStyle { public static var segmented: SegmentedPickerStyle { .init() } }
extension PickerStyle where Self == MenuPickerStyle { public static var menu: MenuPickerStyle { .init() } }

public struct Stepper<Label: View>: View {
    public init(_ title: String, value: Binding<Int>, in bounds: ClosedRange<Int>, step: Int = 1) where Label == Text {}
    public init(value: Binding<Int>, in bounds: ClosedRange<Int>, step: Int = 1, @ViewBuilder label: () -> Label) {}
    public var body: Never { fatalError() }
}

public struct DatePickerComponents: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let date = DatePickerComponents(rawValue: 1), hourAndMinute = DatePickerComponents(rawValue: 2)
}

public struct DatePicker<Label: View>: View {
    public init(_ title: String, selection: Binding<Date>, displayedComponents: DatePickerComponents = [.hourAndMinute, .date]) where Label == Text {}
    public var body: Never { fatalError() }
}

public enum Axis: Hashable {
    case horizontal, vertical
    public struct Set: OptionSet {
        public let rawValue: Int8
        public init(rawValue: Int8) { self.rawValue = rawValue }
        public static let horizontal = Set(rawValue: 1), vertical = Set(rawValue: 2)
    }
}

public struct TextField<Label: View>: View {
    public init(_ title: String, text: Binding<String>) where Label == Text {}
    public init(_ title: String, text: Binding<String>, axis: Axis) where Label == Text {}
    public var body: Never { fatalError() }
}

public struct SubmitLabel { public static let done = SubmitLabel(), search = SubmitLabel(), next = SubmitLabel(), go = SubmitLabel() }

public struct Gauge<Label: View, CurrentValueLabel: View, BoundsLabel: View, MarkedValueLabels: View>: View {
    public init(value: Double, in bounds: ClosedRange<Double> = 0...1, @ViewBuilder label: () -> Label)
        where CurrentValueLabel == EmptyView, BoundsLabel == EmptyView, MarkedValueLabels == EmptyView {}
    public var body: Never { fatalError() }
}

public protocol GaugeStyle {}
public struct LinearCapacityGaugeStyle: GaugeStyle {}
extension GaugeStyle where Self == LinearCapacityGaugeStyle { public static var accessoryLinearCapacity: LinearCapacityGaugeStyle { .init() } }

public struct ProgressView<Label: View, CurrentValueLabel: View>: View {
    public init() where Label == EmptyView, CurrentValueLabel == EmptyView {}
    public var body: Never { fatalError() }
}

public struct Menu<Label: View, Content: View>: View {
    public init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {}
    public var body: Never { fatalError() }
}

public struct EditButton: View {
    public init() {}
    public var body: Never { fatalError() }
}

public struct Link<Label: View>: View {
    public init(destination: URL, @ViewBuilder label: () -> Label) {}
    public var body: Never { fatalError() }
}

public struct ShareLink<Label: View>: View {
    public init(item: URL, @ViewBuilder label: () -> Label) {}
    public var body: Never { fatalError() }
}

public struct Divider: View { public init() {}; public var body: Never { fatalError() } }
public struct Spacer: View { public init(minLength: CGFloat? = nil) {}; public var body: Never { fatalError() } }

// MARK: - Containers

public struct VStack<Content: View>: View {
    public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}
public struct HStack<Content: View>: View {
    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}
public struct ZStack<Content: View>: View {
    public init(alignment: Alignment = .center, @ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}
public struct Group<Content: View>: View {
    public init(@ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}
public struct ScrollView<Content: View>: View {
    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}
public struct List<SelectionValue: Hashable, Content: View>: View {
    public init(@ViewBuilder content: () -> Content) where SelectionValue == Never {}
    public var body: Never { fatalError() }
}
public struct Form<Content: View>: View {
    public init(@ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}
public struct Section<Parent: View, Content: View, Footer: View>: View {
    public init(@ViewBuilder content: () -> Content) where Parent == EmptyView, Footer == EmptyView {}
    public init(_ title: String, @ViewBuilder content: () -> Content) where Parent == Text, Footer == EmptyView {}
    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent) where Footer == EmptyView {}
    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent, @ViewBuilder footer: () -> Footer) {}
    public var body: Never { fatalError() }
}

public struct GridItem {
    public enum Size { case fixed(CGFloat), flexible(minimum: CGFloat = 10, maximum: CGFloat = .infinity), adaptive(minimum: CGFloat, maximum: CGFloat = .infinity) }
    public init(_ size: Size = .flexible(), spacing: CGFloat? = nil, alignment: Alignment? = nil) {}
}

public struct LazyVGrid<Content: View>: View {
    public init(columns: [GridItem], alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}

public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    public var body: Never { fatalError() }
}
extension ForEach where ID == Data.Element.ID, Data.Element: Identifiable {
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {}
}
extension ForEach {
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {}
}
extension ForEach where Data == Range<Int>, ID == Int {
    public init(_ data: Range<Int>, @ViewBuilder content: @escaping (Int) -> Content) {}
}
extension ForEach {
    public init<C: MutableCollection & RandomAccessCollection>(_ data: Binding<C>, @ViewBuilder content: @escaping (Binding<C.Element>) -> Content)
        where Data == Binding<C>, C.Element: Identifiable, ID == C.Element.ID {}
}

/// Modifiers only available on ForEach / DynamicViewContent.
public protocol DynamicViewContent: View {}
extension ForEach: DynamicViewContent {}
extension DynamicViewContent {
    public func onDelete(perform action: ((IndexSet) -> Void)?) -> some DynamicViewContent { self }
    public func onMove(perform action: ((IndexSet, Int) -> Void)?) -> some DynamicViewContent { self }
}

public struct GeometryProxy { public var size: CGSize { .zero }; public var safeAreaInsets: EdgeInsets { EdgeInsets() } }
public struct ViewDimensions {
    public var width: CGFloat { 0 }
    public var height: CGFloat { 0 }
    public subscript(guide: VerticalAlignment) -> CGFloat { 0 }
    public subscript(guide: HorizontalAlignment) -> CGFloat { 0 }
}
public struct GeometryReader<Content: View>: View {
    public init(@ViewBuilder content: @escaping (GeometryProxy) -> Content) {}
    public var body: Never { fatalError() }
}

public protocol Layout {}
public struct VStackLayout: Layout { public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil) {} }
public struct HStackLayout: Layout { public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil) {} }
public struct AnyLayout: Layout {
    public init<L: Layout>(_ layout: L) {}
    public func callAsFunction<V: View>(@ViewBuilder _ content: () -> V) -> some View { _V() }
}

// MARK: - Shapes

public struct Path {
    public init() {}
    public init(_ rect: CGRect) {}
    public mutating func move(to p: CGPoint) {}
    public mutating func addLine(to p: CGPoint) {}
}

public enum RoundedCornerStyle { case circular, continuous }

public struct StrokeStyle {
    public init(lineWidth: CGFloat = 1, lineCap: CGLineCap = .butt, lineJoin: CGLineJoin = .miter) {}
}
public enum CGLineCap { case butt, round, square }
public enum CGLineJoin { case miter, round, bevel }

public protocol Shape: View {
    func path(in rect: CGRect) -> Path
}
extension Shape {
    public var body: _V { _V() }
    public func fill<S: ShapeStyle>(_ content: S) -> some View { _V() }
    public func stroke<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1) -> some View { _V() }
    public func stroke<S: ShapeStyle>(_ content: S, style: StrokeStyle) -> some View { _V() }
    public func trim(from: CGFloat = 0, to: CGFloat = 1) -> some Shape { self }
}
public protocol InsettableShape: Shape {}
extension InsettableShape {
    public func strokeBorder<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1) -> some View { _V() }
}
public struct Circle: InsettableShape { public init() {}; public func path(in rect: CGRect) -> Path { Path() } }
public struct Rectangle: InsettableShape { public init() {}; public func path(in rect: CGRect) -> Path { Path() } }
public struct Capsule: InsettableShape { public init() {}; public func path(in rect: CGRect) -> Path { Path() } }
public struct RoundedRectangle: InsettableShape {
    public init(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) {}
    public func path(in rect: CGRect) -> Path { Path() }
}

// MARK: - Canvas & Timeline

public struct GraphicsContext {
    public enum Shading { case color(Color) }
    public var opacity: Double = 1
    public func fill(_ path: Path, with shading: Shading) {}
}

public struct Canvas<Symbols: View>: View {
    public init(opaque: Bool = false, rendersAsynchronously: Bool = false, renderer: @escaping (inout GraphicsContext, CGSize) -> Void) where Symbols == EmptyView {}
    public var body: Never { fatalError() }
}

public protocol TimelineSchedule {}
public struct PeriodicTimelineSchedule: TimelineSchedule { public init(from: Date, by: TimeInterval) {} }
public struct AnimationTimelineSchedule: TimelineSchedule { public init(minimumInterval: Double? = nil, paused: Bool = false) {} }
extension TimelineSchedule where Self == PeriodicTimelineSchedule {
    public static func periodic(from startDate: Date, by interval: TimeInterval) -> PeriodicTimelineSchedule { .init(from: startDate, by: interval) }
}
extension TimelineSchedule where Self == AnimationTimelineSchedule {
    public static var animation: AnimationTimelineSchedule { .init() }
}
public struct TimelineViewDefaultContext { public let date: Date }
public struct TimelineView<Schedule: TimelineSchedule, Content: View>: View {
    public typealias Context = TimelineViewDefaultContext
    public init(_ schedule: Schedule, @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content) {}
    public var body: Never { fatalError() }
}

// MARK: - Navigation & presentation

public struct NavigationStack<Data, Root: View>: View {
    public init(@ViewBuilder root: () -> Root) where Data == NavigationPath {}
    public init(path: Binding<Data>, @ViewBuilder root: () -> Root) where Data: MutableCollection, Data: RandomAccessCollection, Data: RangeReplaceableCollection, Data.Element: Hashable {}
    public var body: Never { fatalError() }
}
public struct NavigationPath {}

public struct NavigationLink<Label: View, Destination: View>: View {
    public init<P: Hashable>(value: P?, @ViewBuilder label: () -> Label) where Destination == Never {}
    public init(_ title: String, @ViewBuilder destination: () -> Destination) where Label == Text {}
    public var body: Never { fatalError() }
}

public struct ToolbarItemPlacement {
    public static let topBarTrailing = ToolbarItemPlacement(), topBarLeading = ToolbarItemPlacement()
    public static let cancellationAction = ToolbarItemPlacement(), confirmationAction = ToolbarItemPlacement()
    public static let automatic = ToolbarItemPlacement()
}
public protocol ToolbarContent {}
@resultBuilder public enum ToolbarContentBuilder {
    public static func buildBlock<C: ToolbarContent>(_ c: C) -> C { c }
    public static func buildBlock<each C: ToolbarContent>(_ c: repeat each C) -> _ToolbarTuple { _ToolbarTuple() }
    public static func buildExpression<C: ToolbarContent>(_ c: C) -> C { c }
    public static func buildOptional<C: ToolbarContent>(_ c: C?) -> _ToolbarOptional<C> { _ToolbarOptional() }
}
public struct _ToolbarOptional<C: ToolbarContent>: ToolbarContent {}
public struct _ToolbarTuple: ToolbarContent {}
public struct ToolbarItem<ID, Content: View>: ToolbarContent {
    public init(placement: ToolbarItemPlacement = .automatic, @ViewBuilder content: () -> Content) where ID == () {}
}
public struct ToolbarItemGroup<Content: View>: ToolbarContent {
    public init(placement: ToolbarItemPlacement = .automatic, @ViewBuilder content: () -> Content) {}
}

public struct ToolbarPlacement { public static let navigationBar = ToolbarPlacement(), tabBar = ToolbarPlacement() }

public enum NavigationBarItem { public enum TitleDisplayMode { case automatic, inline, large } }

public struct PresentationDetent: Hashable {
    public static let medium = PresentationDetent(), large = PresentationDetent()
    public static func fraction(_ f: CGFloat) -> PresentationDetent { PresentationDetent() }
    public static func height(_ h: CGFloat) -> PresentationDetent { PresentationDetent() }
}

public struct ScrollDismissesKeyboardMode { public static let interactively = ScrollDismissesKeyboardMode(), immediately = ScrollDismissesKeyboardMode() }
public struct ScrollIndicatorVisibility { public static let hidden = ScrollIndicatorVisibility(), automatic = ScrollIndicatorVisibility() }

public protocol ListStyle {}
public struct InsetGroupedListStyle: ListStyle {}
public struct PlainListStyle: ListStyle {}
extension ListStyle where Self == InsetGroupedListStyle { public static var insetGrouped: InsetGroupedListStyle { .init() } }
extension ListStyle where Self == PlainListStyle { public static var plain: PlainListStyle { .init() } }

public struct ContextMenu {}

public struct TabView<SelectionValue: Hashable, Content: View>: View {
    public init(selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {}
    public var body: Never { fatalError() }
}

// MARK: - App & scenes

@MainActor @preconcurrency
public protocol App {
    associatedtype Body: Scene
    @SceneBuilder @MainActor var body: Body { get }
    @MainActor init()
}
extension App { public static func main() {} }
public protocol Scene {}

// Apple-only Foundation API.
extension URL {
    public func startAccessingSecurityScopedResource() -> Bool { false }
    public func stopAccessingSecurityScopedResource() {}
}
extension FileManager {
    public func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? { nil }
}
@resultBuilder public enum SceneBuilder {
    public static func buildBlock<S: Scene>(_ s: S) -> S { s }
}
public struct WindowGroup<Content: View>: Scene {
    public init(@ViewBuilder content: () -> Content) {}
}

// MARK: - View modifiers (subset)

extension View {
    // Layout
    public func padding(_ length: CGFloat? = nil) -> some View { _V() }
    public func padding(_ edges: Edge.Set, _ length: CGFloat? = nil) -> some View { _V() }
    public func padding(_ insets: EdgeInsets) -> some View { _V() }
    public func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View { _V() }
    public func frame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil,
                      minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil,
                      alignment: Alignment = .center) -> some View { _V() }
    public func fixedSize(horizontal: Bool, vertical: Bool) -> some View { _V() }
    public func fixedSize() -> some View { _V() }
    public func offset(x: CGFloat = 0, y: CGFloat = 0) -> some View { _V() }
    public func aspectRatio(_ ratio: CGFloat? = nil, contentMode: ContentMode) -> some View { _V() }
    public func scaledToFill() -> some View { _V() }
    public func scaledToFit() -> some View { _V() }
    public func layoutPriority(_ value: Double) -> some View { _V() }
    public func ignoresSafeArea(_ regions: SafeAreaRegions = .all, edges: Edge.Set = .all) -> some View { _V() }

    // Drawing
    public func background<V: View>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View { _V() }
    public func background<S: ShapeStyle>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View { _V() }
    public func background<V: View>(_ view: V) -> some View { _V() }
    public func background<S: ShapeStyle, T: Shape>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View { _V() }
    public func overlay<V: View>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View { _V() }
    public func overlay<V: View>(_ overlay: V, alignment: Alignment = .center) -> some View { _V() }
    public func clipShape<S: Shape>(_ shape: S, style: FillStyle = FillStyle()) -> some View { _V() }
    public func shadow(color: Color = Color(red: 0, green: 0, blue: 0), radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View { _V() }
    public func opacity(_ opacity: Double) -> some View { _V() }
    public func clipped(antialiased: Bool = false) -> some View { _V() }
    public func scaleEffect(_ s: CGFloat, anchor: UnitPoint = .center) -> some View { _V() }
    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some View { _V() }
    public func foregroundStyle<S: ShapeStyle>(_ style: S) -> some View { _V() }
    public func tint(_ color: Color?) -> some View { _V() }
    public func preferredColorScheme(_ colorScheme: ColorScheme?) -> some View { _V() }
    public func safeAreaInset<V: View>(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View { _V() }
    public func alignmentGuide(_ g: VerticalAlignment, computeValue: @escaping (ViewDimensions) -> CGFloat) -> some View { _V() }
    public func redacted(reason: RedactionReasons) -> some View { _V() }
    public func contentShape<S: Shape>(_ shape: S, eoFill: Bool = false) -> some View { _V() }

    // Text
    public func font(_ font: Font?) -> some View { _V() }
    public func fontWeight(_ weight: Font.Weight?) -> some View { _V() }
    public func lineLimit(_ number: Int?) -> some View { _V() }
    public func lineLimit(_ limit: ClosedRange<Int>) -> some View { _V() }
    public func multilineTextAlignment(_ alignment: TextAlignment) -> some View { _V() }
    public func textCase(_ textCase: Text.Case?) -> some View { _V() }
    public func tracking(_ tracking: CGFloat) -> some View { _V() }
    public func strikethrough(_ isActive: Bool = true, pattern: Text.LineStyle.Pattern = .solid, color: Color? = nil) -> some View { _V() }
    public func minimumScaleFactor(_ factor: CGFloat) -> some View { _V() }
    public func contentTransition(_ transition: ContentTransition) -> some View { _V() }
    public func imageScale(_ scale: Image.Scale) -> some View { _V() }
    public func labelStyle<S: LabelStyle>(_ style: S) -> some View { _V() }
    public func monospacedDigit() -> some View { _V() }

    // Interaction
    public func buttonStyle<S: ButtonStyle>(_ style: S) -> some View { _V() }
    public func buttonStyle<S: PrimitiveButtonStyle>(_ style: S) -> some View { _V() }
    public func pickerStyle<S: PickerStyle>(_ style: S) -> some View { _V() }
    public func gaugeStyle<S: GaugeStyle>(_ style: S) -> some View { _V() }
    public func listStyle<S: ListStyle>(_ style: S) -> some View { _V() }
    public func disabled(_ disabled: Bool) -> some View { _V() }
    public func allowsHitTesting(_ enabled: Bool) -> some View { _V() }
    public func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View { _V() }
    public func contextMenu<M: View>(@ViewBuilder menuItems: () -> M) -> some View { _V() }
    public func swipeActions<C: View>(edge: HorizontalEdge = .trailing, allowsFullSwipe: Bool = true, @ViewBuilder content: () -> C) -> some View { _V() }
    public func focused(_ binding: FocusState<Bool>.Binding) -> some View { _V() }
    public func submitLabel(_ label: SubmitLabel) -> some View { _V() }
    public func onSubmit(of triggers: SubmitTriggers = .text, _ action: @escaping () -> Void) -> some View { _V() }
    public func autocorrectionDisabled(_ disable: Bool = true) -> some View { _V() }
    public func textContentType(_ textContentType: UITextContentType?) -> some View { _V() }
    public func labelsHidden() -> some View { _V() }

    // Lifecycle
    public func onAppear(perform action: (() -> Void)? = nil) -> some View { _V() }
    public func onDisappear(perform action: (() -> Void)? = nil) -> some View { _V() }
    public func task(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View { _V() }
    public func task<T: Equatable>(id value: T, priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View { _V() }
    public func onChange<V: Equatable>(of value: V, initial: Bool = false, _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void) -> some View { _V() }
    public func onReceive<P: Publisher>(_ publisher: P, perform action: @escaping (P.Output) -> Void) -> some View where P.Failure == Never { _V() }
    public func onOpenURL(perform action: @escaping (URL) -> Void) -> some View { _V() }
    public func animation<V: Equatable>(_ animation: Animation?, value: V) -> some View { _V() }
    public func transition(_ t: AnyTransition) -> some View { _V() }
    public func id<ID: Hashable>(_ id: ID) -> some View { _V() }

    // Environment
    public func environment<T: AnyObject & Observable>(_ object: T?) -> some View { _V() }
    public func environment<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>, _ value: V) -> some View { _V() }
    public func modifier<M: ViewModifier>(_ modifier: M) -> some View { _V() }

    // Navigation & toolbars
    public func navigationTitle(_ title: String) -> some View { _V() }
    public func navigationBarTitleDisplayMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View { _V() }
    public func navigationDestination<D: Hashable, C: View>(for data: D.Type, @ViewBuilder destination: @escaping (D) -> C) -> some View { _V() }
    public func toolbar<C: ToolbarContent>(@ToolbarContentBuilder content: () -> C) -> some View { _V() }
    public func toolbar(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { _V() }
    public func tabItem<V: View>(@ViewBuilder _ label: () -> V) -> some View { _V() }
    public func tag<V: Hashable>(_ tag: V) -> some View { _V() }
    public func scrollContentBackground(_ visibility: Visibility) -> some View { _V() }
    public func scrollDismissesKeyboard(_ mode: ScrollDismissesKeyboardMode) -> some View { _V() }
    public func scrollIndicators(_ visibility: ScrollIndicatorVisibility, axes: Axis.Set = [.vertical, .horizontal]) -> some View { _V() }
    public func listRowBackground<V: View>(_ view: V?) -> some View { _V() }
    public func listRowInsets(_ insets: EdgeInsets?) -> some View { _V() }
    public func listRowSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View { _V() }

    // Presentation
    public func sheet<Item: Identifiable, Content: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View { _V() }
    public func presentationDetents(_ detents: Set<PresentationDetent>, selection: Binding<PresentationDetent>) -> some View { _V() }
    public func presentationDetents(_ detents: Set<PresentationDetent>) -> some View { _V() }
    public func presentationDragIndicator(_ visibility: Visibility) -> some View { _V() }
    public func interactiveDismissDisabled(_ isDisabled: Bool = true) -> some View { _V() }
    public func confirmationDialog<A: View, M: View>(_ title: String, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic,
                                                     @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View { _V() }
    public func confirmationDialog<A: View>(_ title: String, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic,
                                            @ViewBuilder actions: () -> A) -> some View { _V() }
    public func alert<A: View, M: View>(_ title: String, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View { _V() }
    public func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], onCompletion: @escaping (Result<URL, Error>) -> Void) -> some View { _V() }

    // Accessibility
    public func accessibilityLabel(_ label: String) -> some View { _V() }
    public func accessibilityLabel(_ label: Text) -> some View { _V() }
    public func accessibilityValue(_ value: String) -> some View { _V() }
    public func accessibilityHint(_ hint: String) -> some View { _V() }
    public func accessibilityIdentifier(_ identifier: String) -> some View { _V() }
    public func accessibilityAddTraits(_ traits: AccessibilityTraits) -> some View { _V() }
    public func accessibilityHidden(_ hidden: Bool) -> some View { _V() }
    public func accessibilityElement(children: AccessibilityChildBehavior = .ignore) -> some View { _V() }
    public func accessibilityAction(named name: String, _ handler: @escaping () -> Void) -> some View { _V() }
}

public struct FillStyle { public init(eoFill: Bool = false, antialiased: Bool = true) {} }
public struct RedactionReasons: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let placeholder = RedactionReasons(rawValue: 1)
}
public enum HorizontalEdge { case leading, trailing }
public enum VerticalEdge { case top, bottom; public struct Set: OptionSet { public let rawValue: Int8; public init(rawValue: Int8) { self.rawValue = rawValue }; public static let all = Set(rawValue: 3) } }
public struct SubmitTriggers: OptionSet { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }; public static let text = SubmitTriggers(rawValue: 1) }

extension Text {
    public enum Case { case uppercase, lowercase }
    public struct LineStyle { public enum Pattern { case solid, dot, dash } }
}

// Array/Collection helpers SwiftUI adds.
extension MutableCollection where Self: RangeReplaceableCollection {
    public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {}
}
extension RangeReplaceableCollection where Self: MutableCollection {
    public mutating func remove(atOffsets offsets: IndexSet) {}
}
