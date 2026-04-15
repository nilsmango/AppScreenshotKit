// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppScreenshotKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AppScreenshotKit",
            targets: ["AppScreenshotKit"]
        ),
        .library(
            name: "AppScreenshotKitTestTools",
            targets: ["AppScreenshotKitTestTools"]
        ),
        .executable(
            name: "AppScreenshotKitCLI",
            targets: ["AppScreenshotKitCLI"]
        ),
    ],
    targets: [
        .target(
            name: "AppScreenshotKit",
            dependencies: [
                "AppScreenshotCore"
            ]
        ),
        .target(
            name: "AppScreenshotCore"
        ),
        .target(
            name: "AppScreenshotKitTestTools",
            dependencies: [
                "AppScreenshotKit"
            ],
            resources: [
                .process("Resources")
            ],
            plugins: [
                "RegisterBezelsCommand",
            ]
        ),
        .executableTarget(
            name: "AppScreenshotKitCLI"
        ),
        .plugin(
            name: "RegisterBezelsCommand",
            capability: .buildTool()
        ),
        .testTarget(
            name: "AppScreenshotKitTests",
            dependencies: ["AppScreenshotKit", "AppScreenshotCore"]
        ),
        .testTarget(
            name: "AppScreenshotKitTestToolsTests",
            dependencies: ["AppScreenshotKitTestTools"]
        ),
        .testTarget(
            name: "AppScreenshotKitCLITests",
            dependencies: ["AppScreenshotKitCLI"]
        ),
    ]
)
