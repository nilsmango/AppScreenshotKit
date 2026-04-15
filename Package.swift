// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Project7IIIScreenshots",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Project7IIIScreenshots",
            targets: ["Project7IIIScreenshots"]
        ),
        .library(
            name: "Project7IIIScreenshotTestTools",
            targets: ["Project7IIIScreenshotTestTools"]
        ),
        .executable(
            name: "Project7IIIScreenshotsCLI",
            targets: ["Project7IIIScreenshotsCLI"]
        ),
    ],
    targets: [
        .target(
            name: "Project7IIIScreenshots",
            dependencies: [
                "Project7IIIScreenshotCore"
            ]
        ),
        .target(
            name: "Project7IIIScreenshotCore"
        ),
        .target(
            name: "Project7IIIScreenshotTestTools",
            dependencies: [
                "Project7IIIScreenshots"
            ],
            resources: [
                .process("Resources")
            ],
            plugins: [
                "RegisterBezelsCommand",
            ]
        ),
        .executableTarget(
            name: "Project7IIIScreenshotsCLI"
        ),
        .plugin(
            name: "RegisterBezelsCommand",
            capability: .buildTool()
        ),
        .testTarget(
            name: "Project7IIIScreenshotsTests",
            dependencies: ["Project7IIIScreenshots", "Project7IIIScreenshotCore"]
        ),
        .testTarget(
            name: "Project7IIIScreenshotTestToolsTests",
            dependencies: ["Project7IIIScreenshotTestTools"]
        ),
        .testTarget(
            name: "Project7IIIScreenshotsCLITests",
            dependencies: ["Project7IIIScreenshotsCLI"]
        ),
    ]
)
