// swift-tools-version:5.9
// SkydayKit: platform-independent domain, rules, persistence and store for Skyday.
// Foundation + Observation only, so it compiles and tests on macOS, iOS and Linux.
import PackageDescription

let package = Package(
    name: "SkydayKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SkydayKit", targets: ["SkydayKit"])
    ],
    targets: [
        .target(name: "SkydayKit"),
        .testTarget(name: "SkydayKitTests", dependencies: ["SkydayKit"])
    ]
)
