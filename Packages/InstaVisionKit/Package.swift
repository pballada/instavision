// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "InstaVisionKit",
    platforms: [.visionOS(.v2), .macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "InstaVisionKit", targets: ["InstaVisionKit"]),
    ],
    targets: [
        .target(name: "InstaVisionKit"),
        .testTarget(name: "InstaVisionKitTests", dependencies: ["InstaVisionKit"]),
    ]
)
