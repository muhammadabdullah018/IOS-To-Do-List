// swift-tools-version:5.9
// Linux-only TYPE-CHECK harness. Compiles the iOS app and widget sources against hand-written
// stubs of the Apple frameworks they use (signatures mirror the iOS 17 SDK). It catches
// mistakes in our own code (labels, types, missing members) and most API misuse.
// It is NOT a substitute for building in Xcode: stubs can be wrong or incomplete.
import PackageDescription

let package = Package(
    name: "LinuxTypecheck",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../Packages/SkydayKit")],
    targets: [
        .target(name: "Combine", path: "Stubs/Combine"),
        .target(name: "UniformTypeIdentifiers", path: "Stubs/UniformTypeIdentifiers"),
        .target(name: "UIKit", path: "Stubs/UIKit"),
        .target(name: "UserNotifications", path: "Stubs/UserNotifications"),
        .target(name: "SwiftUI", dependencies: ["UIKit", "Combine", "UniformTypeIdentifiers"], path: "Stubs/SwiftUI"),
        .target(name: "WidgetKit", dependencies: ["SwiftUI"], path: "Stubs/WidgetKit"),
        .target(name: "SkydayApp",
                dependencies: ["SwiftUI", "UIKit", "WidgetKit", "UserNotifications", "Combine", "UniformTypeIdentifiers",
                               .product(name: "SkydayKit", package: "SkydayKit")],
                path: "Sources/SkydayApp",
                exclude: ["Resources", "Skyday.entitlements"]),
        .target(name: "SkydayWidgetExtension",
                dependencies: ["SwiftUI", "WidgetKit", .product(name: "SkydayKit", package: "SkydayKit")],
                path: "Sources/SkydayWidgetExtension",
                exclude: ["Info.plist", "SkydayWidget.entitlements"])
    ]
)
