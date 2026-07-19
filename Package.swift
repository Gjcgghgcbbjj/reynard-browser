// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ReynardStabilityCore",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "ReynardStabilityCore",
            targets: ["ReynardStabilityCore"]
        ),
        .library(
            name: "ReynardBrowserCore",
            targets: ["ReynardBrowserCore"]
        ),
    ],
    targets: [
        .target(
            name: "ReynardStabilityCore",
            path: "browser/Reynard/StabilityCore"
        ),
        .testTarget(
            name: "ReynardStabilityCoreTests",
            dependencies: ["ReynardStabilityCore"],
            path: "Tests/ReynardStabilityCoreTests"
        ),
        .target(
            name: "ReynardBrowserCore",
            path: "browser/Reynard/BrowserCore"
        ),
        .testTarget(
            name: "ReynardBrowserCoreTests",
            dependencies: ["ReynardBrowserCore"],
            path: "Tests/ReynardBrowserCoreTests"
        ),
    ]
)
