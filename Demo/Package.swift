// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Demo",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Demo",
            targets: ["Demo"]
        )
    ],
    dependencies: [
        .package(path: "../../Project7IIIScreenshots")
    ],
    targets: [
        .target(
            name: "Demo",
            dependencies: [
                .product(name: "Project7IIIScreenshots", package: "Project7IIIScreenshots")
            ]
        ),
        .testTarget(
            name: "DemoTests",
            dependencies: [
                "Demo",
                .product(name: "Project7IIIScreenshotTestTools", package: "Project7IIIScreenshots"),
            ]
        ),
    ]
)
